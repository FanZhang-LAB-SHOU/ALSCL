test_that("simulation length geometry matches fitted-model bins at every entry point", {
  invalid <- list(
    list(len_mid = c(10, 20), len_border = c(0, 1, 30)),
    list(len_mid = c(10, 20), len_border = c(0, 25, 30)),
    list(len_mid = c(10, 20), len_border = c(0, 10, 30)),
    list(len_mid = c(10, 20), len_border = c(0, 20, 30)),
    list(len_mid = c(0, 20), len_border = c(-10, 10, 30)),
    list(len_mid = c(-1, 20), len_border = c(-10, 10, 30)),
    list(len_mid = c(10, Inf), len_border = c(0, 15, 30)),
    list(len_mid = c(10, 20), len_border = c(-Inf, Inf, Inf)),
    list(len_mid = c(10, 20), len_border = c(-Inf, NA, Inf)),
    list(len_mid = c(10, 20), len_border = c(-Inf, -Inf, Inf)),
    list(len_mid = c(20, 10), len_border = c(0, 15, 30)),
    list(len_mid = c(10, 20), len_border = c(0, 15)),
    list(len_mid = "10,20", len_border = c(0, 15, 30)))
  for (args in invalid)
    expect_error(do.call(initialize_params,
      c(list(nyear = 3, burn_in = 1), args)), "len_mid|len_border|midpoints")

  folder <- tempfile("simulation-geometry-")
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  for (species in c("flatfish", "tuna")) {
    p <- initialize_params(species = species, nyear = 3, burn_in = 1)
    bio <- sim_cal(p)
    bad <- p
    # The first midpoint is now above its upper boundary.
    bad$len_border[2] <- p$len_mid[1] / 2
    set.seed(229)
    before <- .Random.seed
    expect_error(sim_cal(bad), "midpoints")
    expect_error(sim_data(bio, bad, iter_range = 1, output_dir = folder), "midpoints")
    expect_identical(.Random.seed, before)
    expect_false(dir.exists(folder))
    dir.create(folder)
    saved <- file.path(folder, "sim_rep1")
    writeLines("existing simulation", saved)
    checksum <- tools::md5sum(saved)
    expect_error(sim_data(bio, bad, iter_range = 1, output_dir = folder), "midpoints")
    expect_identical(tools::md5sum(saved), checksum)
    unlink(folder, recursive = TRUE)

    # The shapes remain valid, but the arrays belong to another bin grid.
    for (name in c("len_mid", "len_lower", "len_upper")) {
      wrong <- bio
      index <- which(is.finite(wrong[[name]]))[1L]
      wrong[[name]][index] <- wrong[[name]][index] + 0.1
      expect_error(sim_data(wrong, p, iter_range = 1, output_dir = folder),
                   paste0("bio_vars\\$", name))
      expect_identical(.Random.seed, before)
      expect_false(dir.exists(folder))
    }
  }
})

test_that("valid irregular bins and legacy biological lists retain open tails", {
  for (outer in list(c(-10, 15, 30, 90), c(-Inf, 15, 30, Inf))) {
    p <- initialize_params(nyear = 3, burn_in = 1,
      len_mid = c(10, 20, 45), len_border = outer)
    expect_equal(p$len_border, c(-Inf, 15, 30, Inf))
    bio <- sim_cal(p)
    expect_equal(bio$len_mid, p$len_mid)
    expect_equal(bio$len_lower, c(-Inf, 15, 30))
    expect_equal(bio$len_upper, c(15, 30, Inf))
    expect_silent(ALSCL:::.acl_length_bins(as.character(p$len_mid),
      len_mid = p$len_mid, len_border = p$len_border[-c(1, 4)]))
    # Old biological objects without coordinate metadata are still accepted.
    legacy <- bio
    legacy[c("len_mid", "len_lower", "len_upper")] <- NULL
    expect_silent(ALSCL:::.acl_simulation_biology(legacy, p, "age_based"))
    finite_outer <- p; finite_outer$len_border[c(1, 4)] <- c(-10, 90)
    expect_error(sim_cal(finite_outer), "Finite outer length bounds")
  }
})

test_that("full simulators preserve extinct and tiny surveys without an artificial floor", {
  folder <- tempfile("simulation-survey-values-")
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  for (species in c("flatfish", "tuna")) {
    p <- initialize_params(species = species, nyear = 3, burn_in = 1,
      R_init = 0, alpha = 0, std_SN = 0)
    capture.output(empty <- sim_data(sim_cal(p), p, iter_range = 4, output_dir = folder))
    for (name in c("SN_at_len", "RVN_at_len", "RVB_at_len", "N_at_len", "SSB"))
      expect_true(all(empty[[name]] == 0), info = paste(species, name))
    expect_identical(empty$SN_at_len, empty$RVN_at_len)
    to_frame <- function(x) {
      out <- data.frame(LengthBin = as.character(empty$len_mid), x,
                        check.names = FALSE)
      names(out)[-1L] <- as.character(empty$years)
      out
    }
    x <- list(data.CatL = to_frame(t(empty$SN_at_len)),
      data.wgt = to_frame(empty$weight), data.mat = to_frame(empty$mat),
      rec.age = empty$rec.age, nage = empty$nage, M = p$M,
      sel_L50 = p$q_surv_L50, sel_L95 = p$q_surv_L95,
      growth_step = empty$growth_step, len_mid = empty$len_mid,
      len_border = empty$len_border)
    for (fit in list(run_acl, run_alscl)) {
      expect_error(fit(x), "At least one positive survey observation")
      expect_error(fit(x, zero_action = "error"), "Zero observations")
    }

    p$R_init <- 1e-12; p$alpha <- 1e-12
    p$std_logR <- p$std_logN0 <- p$F_sd <- 0
    capture.output(small <- sim_data(sim_cal(p), p, iter_range = 4, output_dir = folder))
    expected <- sweep(small$N_at_len, 2L, small$q_surv, "*")
    expect_true(any(small$SN_at_len > 0 & small$SN_at_len < 1e-6))
    expect_true(all(small$SN_at_len < 1e-6))
    expect_lte(max(abs(small$SN_at_len - expected)), max(expected) * 1e-14)
    expect_identical(small$SN_at_len, small$RVN_at_len)
    expect_equal(small$RVB_at_len, small$RVN_at_len * t(small$weight), tolerance = 0)
    restored <- new.env(parent = emptyenv())
    load(file.path(folder, "sim_rep4"), envir = restored)
    expect_identical(restored$sim.data$SN_at_len, small$SN_at_len)
    expect_identical(restored$sim.data$RVB_at_len, small$RVB_at_len)
  }
})
