test_that("sim_cal records biological inputs through serialization", {
  file <- tempfile("biology-provenance-", fileext = ".rds")
  on.exit(unlink(file), add = TRUE)
  for (species in c("flatfish", "tuna")) {
    p <- initialize_params(species = species, nyear = 3, burn_in = 1, nage = 4)
    bio <- sim_cal(p)
    expect_equal(bio$biology_inputs$ages, p$ages)
    expect_equal(bio$biology_inputs$growth_step, p$growth_step)
    expect_equal(bio$biology_inputs$q_surv_L50, p$q_surv_L50)
    expect_false(any(c("M", "F_mean", "nyear", "burn_in", "std_SN") %in%
      names(bio$biology_inputs)))
    saveRDS(bio, file)
    restored <- readRDS(file)
    expect_identical(restored, bio)
    expect_silent(ALSCL:::.acl_simulation_biology_matches(restored, p))
  }
})

test_that("stale biological parameters fail before RNG, directories or overwrites", {
  directory <- tempfile("stale-biology-")
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  for (species in c("flatfish", "tuna")) {
    p <- initialize_params(species = species, nyear = 3, burn_in = 1, nage = 4)
    bio <- sim_cal(p)
    fields <- c("Linf", "vbk", "t0", "cv_L", "q_surv_L50", "q_surv_L95",
      "a", "b", "mat_L50", "mat_L95")
    if (species == "tuna")
      fields <- c(fields, "cv_inc", "sel_L50_asc", "sel_L95_asc",
                  "sel_L50_desc", "sel_L95_desc")
    set.seed(243)
    before <- .Random.seed
    for (name in fields) {
      changed <- p
      changed[[name]] <- p[[name]] + max(abs(p[[name]]) * 0.01, 0.001)
      expect_error(sim_data(bio, changed, iter_range = 0, output_dir = directory),
        paste0(name, ".*rerun sim_cal"))
      expect_identical(.Random.seed, before)
      expect_false(dir.exists(directory))
    }
    # Equally sized age grids can describe different biological/time scales.
    changed <- initialize_params(species = species, nyear = 3, burn_in = 1,
      nage = 4, rec.age = if (species == "flatfish") 0.25 else 1,
      growth_step = if (species == "flatfish") 0.25 else 1)
    expect_error(sim_data(bio, changed, iter_range = 0, output_dir = directory),
      "ages.*growth_step.*rerun sim_cal")
    expect_identical(.Random.seed, before)
    expect_false(dir.exists(directory))
    # Changing a time step without rebuilding the age grid is invalid itself.
    changed <- p; changed$growth_step <- p$growth_step / 2
    expect_error(sim_cal(changed), "ages.*growth_step")
    expect_error(sim_data(bio, changed, iter_range = 0, output_dir = directory),
      "ages.*growth_step")
    changed <- p; changed$model_type <- "unknown"
    expect_error(sim_data(bio, changed, iter_range = 0, output_dir = directory), "model_type")
    changed <- p; changed$len_border[3] <- changed$len_border[3] + 0.1
    expect_error(sim_data(bio, changed, iter_range = 0, output_dir = directory), "length bins")
    dir.create(directory)
    target <- file.path(directory, "sim_rep0")
    writeLines("previous replicate", target)
    checksum <- tools::md5sum(target)
    changed <- p; changed$q_surv_L50 <- p$q_surv_L50 + 1
    expect_error(sim_data(bio, changed, iter_range = 0, output_dir = directory), "q_surv_L50")
    expect_identical(tools::md5sum(target), checksum)
    expect_identical(.Random.seed, before)
    unlink(directory, recursive = TRUE)
  }
})

test_that("legacy and manually edited biological arrays cannot bypass consistency", {
  directory <- tempfile("legacy-biology-")
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  for (species in c("flatfish", "tuna")) {
    p <- initialize_params(species = species, nyear = 3, burn_in = 1, nage = 4)
    bio <- sim_cal(p)
    legacy <- bio
    legacy[c("biology_inputs", "len_mid", "len_lower", "len_upper", "LatA")] <- NULL
    expect_silent(ALSCL:::.acl_simulation_biology_matches(legacy, p))
    capture.output(current <- sim_data(bio, p, iter_range = 0, output_dir = directory))
    capture.output(old <- sim_data(legacy, p, iter_range = 0, output_dir = directory))
    expect_identical(old, current)
    changed <- p; changed$q_surv_L50 <- p$q_surv_L50 + 1
    expect_error(sim_data(legacy, changed, iter_range = 0, output_dir = directory),
      "q_surv.*rerun sim_cal")
    changed <- initialize_params(species = species, nyear = 3, burn_in = 1,
      nage = 4, rec.age = if (species == "flatfish") 0.25 else 1,
      growth_step = if (species == "flatfish") 0.25 else 1)
    expect_error(sim_data(legacy, changed, iter_range = 0, output_dir = directory),
      "pla.*rerun sim_cal")
    fields <- c("W_at_len", "mat", "q_surv", "sel", "pla")
    if (species == "tuna") fields <- c(fields, "Gij")
    for (name in fields) {
      altered <- bio
      if (name == "pla") {
        altered$pla <- if (species == "flatfish") bio$pla[, ncol(bio$pla):1] else
          bio$pla[nrow(bio$pla):1, ]
      } else if (name == "Gij") {
        altered$Gij <- bio$Gij[nrow(bio$Gij):1, ]
      } else altered[[name]] <- bio[[name]] * 0.9
      expect_error(sim_data(altered, p, iter_range = 0, output_dir = directory),
        paste0(name, ".*rerun sim_cal"))
    }
  }
})

test_that("equal dimensions do not hide a changed operating model", {
  p <- initialize_params(nyear = 3, burn_in = 1, nage = 4,
    len_mid = c(6, 12, 18, 24), len_border = c(3, 9, 15, 21, 27))
  bio <- sim_cal(p)
  p$model_type <- "length_based"
  directory <- tempfile("changed-operating-model-")
  expect_error(sim_data(bio, p, iter_range = 0, output_dir = directory),
    "model_type.*rerun sim_cal")
  expect_false(dir.exists(directory))
})

test_that("legacy omitted time-step defaults match the operating model", {
  for (species in c("flatfish", "tuna")) {
    p <- initialize_params(species = species, nyear = 3, burn_in = 1, nage = 4)
    bio <- sim_cal(p)
    p$growth_step <- NULL
    expect_identical(sim_cal(p), bio)
    expect_silent(ALSCL:::.acl_simulation_biology_matches(bio, p))
  }
})

test_that("process and output changes keep valid biology reusable with seed zero", {
  directory <- tempfile("reused-biology-")
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  for (species in c("flatfish", "tuna")) {
    p <- initialize_params(species = species, nyear = 3, burn_in = 1, nage = 4)
    bio <- sim_cal(p)
    changed <- p
    changed[c("M", "init_Z", "F_mean", "F_sd", "std_logR", "std_logN0", "std_SN")] <-
      list(0.1, 0.3, 0.1, 0.15, 0.25, 0.15, 0.05)
    changed[c("R_init", "alpha", "beta", "F_ar", "R_ar")] <- list(600, 500, 15, -0.2, 0.2)
    changed$nyear <- 4; changed$burn_in <- 2; changed$first.year <- 1990
    changed$observation_error <- "shared_time"
    # cv_inc is unused by the age-based engine; flat selectivity ignores dome inputs.
    if (species == "flatfish") {
      changed$cv_inc <- 0.9
      changed$sel_L50_asc <- 999
    }
    capture.output(reused <- sim_data(bio, changed, iter_range = 0, output_dir = directory))
    capture.output(rebuilt <- sim_data(sim_cal(changed), changed,
      iter_range = 0, output_dir = directory))
    expect_identical(reused, rebuilt)
    expect_equal(reused$iter, 0)
    expect_equal(reused$years[1], 1990)
    expect_true(all(is.finite(reused$SSB)))
    expect_equal(reused$q_surv, mat_func(reused$q_surv_L50,
      reused$q_surv_L95, reused$len_mid))
    restored <- new.env(parent = emptyenv())
    load(file.path(directory, "sim_rep0"), envir = restored)
    expect_identical(restored$sim.data$SN_at_len, reused$SN_at_len)
  }
})

test_that("saved survey catchability is verified including legacy curve recovery", {
  p <- initialize_params(nyear = 3, burn_in = 1, nage = 4)
  s <- list(len_mid = p$len_mid, q_surv_L50 = p$q_surv_L50,
    q_surv_L95 = p$q_surv_L95, q_surv = sim_cal(p)$q_surv)
  check <- ALSCL:::.acl_simulation_catchability
  expected <- list(L50 = p$q_surv_L50, L95 = p$q_surv_L95)
  expect_equal(check(s), expected)
  legacy <- s; legacy$q_surv <- NULL
  expect_equal(check(legacy), expected)
  legacy <- s; legacy[c("q_surv_L50", "q_surv_L95")] <- NULL
  expect_equal(check(legacy), expected, tolerance = 1e-10)
  changed <- s; changed$q_surv_L50 <- p$q_surv_L50 + 1
  expect_error(check(changed), "does not match.*metadata")
  legacy$q_surv[7] <- legacy$q_surv[7] * 0.8
  expect_error(check(legacy), "does not match.*metadata")
  changed <- s; changed$q_surv <- 0.5
  expect_error(check(changed), "one probability per length bin")
})

test_that("batch fitting rejects inconsistent saved catchability before invoking either fit", {
  directory <- tempfile("saved-catchability-")
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  p <- initialize_params(nyear = 3, burn_in = 1, nage = 4)
  capture.output(sim.data <- sim_data(sim_cal(p), p, iter_range = 0, output_dir = directory))
  sim.data$q_surv_L50 <- p$q_surv_L50 + 1
  save(sim.data, file = file.path(directory, "sim_rep0"))
  called <- FALSE
  fit <- function(...) { called <<- TRUE; stop("fit must not start") }
  local_mocked_bindings(.acl_compile = function(...) NULL,
    run_acl = fit, run_alscl = fit, .package = "ALSCL")
  for (model in c("acl", "alscl")) {
    result <- sim_model(0, sim_data_path = directory, output_dir = directory, model = model)[[1]]
    expect_identical(result$converge, "FAILED")
    expect_match(result$error, "q_surv does not match.*metadata")
    expect_false(called)
  }
})

test_that("tiny positive catchability retains relative consistency checks", {
  directory <- tempfile("tiny-catchability-")
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  p <- initialize_params(nyear = 3, burn_in = 1, nage = 4,
    q_surv_L50 = 100, q_surv_L95 = 105)
  bio <- sim_cal(p)
  bio$biology_inputs <- NULL
  changed <- p
  changed$q_surv_L50 <- 99
  changed$q_surv_L95 <- 104
  expected_q <- mat_func(changed$q_surv_L50, changed$q_surv_L95, p$len_mid)
  expect_lt(max(abs(bio$q_surv - expected_q)), 1e-12)
  expect_gt(min(expected_q / bio$q_surv), 1.8)
  set.seed(243)
  before <- .Random.seed
  expect_error(sim_data(bio, changed, iter_range = 0, output_dir = directory),
    "q_surv.*rerun sim_cal")
  expect_false(dir.exists(directory))
  expect_identical(.Random.seed, before)
  s <- list(len_mid = p$len_mid, q_surv = bio$q_surv,
    q_surv_L50 = changed$q_surv_L50, q_surv_L95 = changed$q_surv_L95)
  expect_error(ALSCL:::.acl_simulation_catchability(s), "q_surv does not match")
  # Retain legitimate tiny surveys, including small cell-wise rounding and
  # named vectors saved by legacy tools. The row-to-bin mapping is unchanged.
  bio$q_surv <- setNames(bio$q_surv * (1 + 1e-12), as.character(p$len_mid))
  expect_silent(ALSCL:::.acl_simulation_biology_matches(bio, p))
  capture.output(sm <- sim_data(bio, p, iter_range = 0, output_dir = directory))
  expect_true(any(sm$SN_at_len > 0))
  expect_equal(ALSCL:::.acl_simulation_catchability(sm),
    list(L50 = p$q_surv_L50, L95 = p$q_surv_L95))
  sm[c("q_surv_L50", "q_surv_L95")] <- NULL
  expect_equal(ALSCL:::.acl_simulation_catchability(sm),
    list(L50 = p$q_surv_L50, L95 = p$q_surv_L95), tolerance = 1e-10)
})

test_that("catchability comparison tolerates floating-point rounding at both tails", {
  same <- ALSCL:::.acl_simulation_probabilities_match
  values <- c(0, 1e-300, 1e-20, 0.1, 0.5, 1)
  expect_true(same(values, pmin(1, values * (1 + 1e-12))))
  expect_true(same(values, values))
  expect_false(same(c(1e-300, 1), c(0, 1)))
  expect_false(same(c(1e-20, 1), c(2e-20, 1)))
  # A few subnormal representable steps can differ between numerical libraries.
  smallest <- .Machine$double.xmin * .Machine$double.eps
  expect_true(same(c(0, smallest, 1), c(smallest, 2 * smallest, 1 - .Machine$double.eps)))
  for (invalid in list(NA_real_, Inf, -0.1, 1.1, "0.5"))
    expect_false(same(invalid, 0.5))
  expect_false(same(c(0.5, 1), 0.5))
})

test_that("tiny legacy weights and maturity retain their biomass scale", {
  directory <- tempfile("tiny-biomass-inputs-")
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  for (species in c("flatfish", "tuna")) {
    p <- initialize_params(species = species, nyear = 3, burn_in = 1, nage = 4)
    p$a <- 1e-22
    p$mat_L50 <- max(p$len_mid) + 50
    p$mat_L95 <- p$mat_L50 + 5
    bio <- sim_cal(p)
    bio$biology_inputs <- NULL
    expect_lt(max(bio$W_at_len), 1e-12)
    expect_lt(max(bio$mat), 1e-12)
    set.seed(243)
    before <- .Random.seed
    changed <- p; changed$a <- 2 * p$a
    expect_error(sim_data(bio, changed, iter_range = 0, output_dir = directory),
      "W_at_len.*rerun sim_cal")
    changed <- p
    changed$mat_L50 <- p$mat_L50 - 1
    changed$mat_L95 <- p$mat_L95 - 1
    expect_gt(min(sim_cal(changed)$mat / bio$mat), 1.8)
    expect_error(sim_data(bio, changed, iter_range = 0, output_dir = directory),
      "mat.*rerun sim_cal")
    expect_identical(.Random.seed, before)
    expect_false(dir.exists(directory))
    # Relative roundoff in saved vectors must not prevent valid legacy reuse.
    bio$W_at_len <- bio$W_at_len * (1 + 1e-12)
    bio$mat <- bio$mat * (1 + 1e-12)
    expect_silent(ALSCL:::.acl_simulation_biology_matches(bio, p))
    capture.output(sm <- sim_data(bio, p, iter_range = 0, output_dir = directory))
    expect_true(all(is.finite(sm$SSB)))
    expect_true(any(sm$SSB > 0))
    expect_identical(as.numeric(sm$weight[, 1]), as.numeric(bio$W_at_len))
    expect_identical(as.numeric(sm$mat[, 1]), as.numeric(bio$mat))
    unlink(directory, recursive = TRUE)
  }
})

test_that("weight consistency permits weights above one without relaxing probabilities", {
  p <- initialize_params(nyear = 3, burn_in = 1, nage = 4)
  p$a <- 0.01
  bio <- sim_cal(p)
  bio$biology_inputs <- NULL
  expect_true(all(bio$W_at_len > 1))
  expect_silent(ALSCL:::.acl_simulation_biology_matches(bio, p))
  same <- ALSCL:::.acl_simulation_nonnegative_match
  expect_true(same(c(0, 10, 1e5), c(0, 10, 1e5) * (1 + 1e-12)))
  expect_false(same(c(0, 1e-20), c(0, 2e-20)))
  expect_false(same(0, 1e-20))
  smallest <- .Machine$double.xmin * .Machine$double.eps
  expect_true(same(c(0, smallest), c(smallest, 2 * smallest)))
  expect_false(ALSCL:::.acl_simulation_probabilities_match(10, 10))
  expect_false(ALSCL:::.acl_simulation_probabilities_match(-0.1, -0.1))
})

test_that("tiny legacy selectivity retains its fishing-mortality scale", {
  directory <- tempfile("tiny-selectivity-")
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  p <- initialize_params(species = "tuna", nyear = 3, burn_in = 1, nage = 4)
  p$sel_L50_asc <- max(p$len_mid) + 50
  p$sel_L95_asc <- p$sel_L50_asc + 5
  p$sel_L50_desc <- p$sel_L95_asc + 50
  p$sel_L95_desc <- p$sel_L50_desc - 10
  bio <- sim_cal(p)
  bio$biology_inputs <- NULL
  expect_lt(max(bio$sel), 1e-12)
  changed <- p
  changed$sel_L50_asc <- p$sel_L50_asc - 1
  changed$sel_L95_asc <- p$sel_L95_asc - 1
  expect_gt(min(sim_cal(changed)$sel / bio$sel), 1.8)
  set.seed(243)
  before <- .Random.seed
  expect_error(sim_data(bio, changed, iter_range = 0, output_dir = directory),
    "sel.*rerun sim_cal")
  expect_identical(.Random.seed, before)
  expect_false(dir.exists(directory))
  bio$sel <- bio$sel * (1 + 1e-12)
  expect_silent(ALSCL:::.acl_simulation_biology_matches(bio, p))
  capture.output(sm <- sim_data(bio, p, iter_range = 0, output_dir = directory))
  expect_identical(sm$sel, bio$sel)
  expect_true(all(is.finite(sm$F_at_len)))
  expect_true(all(sm$F_at_len > 0))
})
