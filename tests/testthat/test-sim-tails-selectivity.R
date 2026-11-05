test_that("operating-model surveys retain positive indices in the length-at-age right tail", {
  directory <- tempfile("survey-right-tail-")
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  p <- initialize_params(species = "flatfish", nyear = 4, burn_in = 1,
    nage = 2, cv_L = 0.15, std_SN = 0)
  bio <- sim_cal(p)
  tail_bins <- which(p$len_mid >= 46)
  reference <- vapply(tail_bins, function(i) {
    upper_tail <- function(border)
      pnorm(border, bio$LatA, p$cv_L * bio$LatA, lower.tail = FALSE)
    upper_tail(p$len_border[i]) - upper_tail(p$len_border[i + 1L])
  }, numeric(p$nage))
  expect_true(all(reference > 0))
  expect_equal(bio$pla[, tail_bins] / reference, matrix(1, p$nage, length(tail_bins)))
  expect_equal(rowSums(bio$pla), rep(1, p$nage))
  capture.output(sm <- sim_data(bio, p, iter_range = 0, output_dir = directory))
  expected <- sweep(sm$N_at_age %*% reference, 2L, bio$q_surv[tail_bins], "*")
  expect_true(all(expected > 0))
  expect_equal(sm$SN_at_len[, tail_bins] / expected, matrix(1, nrow(expected), ncol(expected)))
  # Old precomputed tables can have the correct dimensions and age totals
  # while converting all observations in these bins to zero.
  stale <- bio
  stale$pla[, tail_bins] <- 0
  expect_error(sim_data(stale, p, iter_range = 0, output_dir = directory), "pla.*rerun sim_cal")
})

test_that("length-based growth retains positive right tails and its no-shrinkage boundary", {
  p <- initialize_params(species = "tuna", nyear = 3, burn_in = 1)
  bio <- sim_cal(p)
  j <- 1L
  delta_max <- (1 - exp(-p$vbk)) * p$Linf
  increment <- p$growth_step * delta_max *
    plogis(log(19) * (p$len_mid[j] - 0.5 * p$Linf) / (-0.45 * p$Linf))
  survival <- pnorm(p$len_border - p$len_mid[j], increment, increment * p$cv_inc,
    lower.tail = FALSE)
  reference <- -diff(survival)
  rare <- which(reference > 1e-250 & reference < 1e-17)
  expect_gt(length(rare), 1L)
  expect_true(bio$nlen %in% rare)
  expect_equal(bio$Gij[rare, j] / reference[rare], rep(1, length(rare)), tolerance = 1e-11)
  expect_true(all(bio$Gij[upper.tri(bio$Gij)] == 0))
  expect_equal(colSums(bio$Gij), rep(1, bio$nlen))
  stale <- bio
  stale$Gij[rare, j] <- 0
  directory <- tempfile("growth-right-tail-")
  expect_error(sim_data(stale, p, iter_range = 0, output_dir = directory), "Gij.*rerun sim_cal")
  expect_false(dir.exists(directory))
})

test_that("custom dome selectivity uses the correct age or length coordinates in simulation", {
  directory <- tempfile("fishery-selectivity-")
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  # Exercise both equal and unequal counts of age and length classes.
  for (nage in c(23L, 4L)) {
    p <- initialize_params(species = "flatfish", nyear = 3, burn_in = 1, nage = nage, F_sd = 0)
    expect_identical(sim_cal(p)$sel, rep(1, nage))
    p$sel_type <- "dome"
    p$sel_L50_asc <- 15
    p$sel_L95_asc <- 21
    p$sel_L50_desc <- 44
    p$sel_L95_desc <- 38
    bio <- sim_cal(p)
    selectivity_length <- ifelse(p$len_mid <= (21 + 44) / 2,
      mat_func(15, 21, p$len_mid), mat_func(44, 38, p$len_mid))
    expected <- drop(bio$pla %*% selectivity_length)
    expect_length(bio$sel, nage)
    expect_equal(bio$sel, expected)
    capture.output(sm <- sim_data(bio, p, iter_range = 0, output_dir = directory))
    expect_equal(sm$F_at_age[1L, ], p$F_mean * expected)
    expect_equal(sm$F_at_age[1L, 2L], 0.2427, tolerance = 0.0003)
  }
  p <- initialize_params(species = "tuna", nyear = 3, burn_in = 1, F_sd = 0)
  bio <- sim_cal(p)
  selectivity_length <- ifelse(p$len_mid <= (p$sel_L95_asc + p$sel_L50_desc) / 2,
    mat_func(p$sel_L50_asc, p$sel_L95_asc, p$len_mid),
    mat_func(p$sel_L50_desc, p$sel_L95_desc, p$len_mid))
  expect_equal(bio$sel, selectivity_length)
  capture.output(sm <- sim_data(bio, p, iter_range = 0, output_dir = directory))
  expect_equal(sm$F_at_len[1L, ], p$F_mean * selectivity_length)
})

test_that("simulation rejects unknown selectivity types and ill-defined dome limbs", {
  p <- initialize_params(species = "tuna", nyear = 3, burn_in = 1)
  bio <- sim_cal(p)
  directory <- tempfile("invalid-selectivity-")
  for (bad in list("dom", NA_character_, c("flat", "dome"), 1L)) {
    changed <- p
    changed$sel_type <- bad
    expect_error(sim_cal(changed), "sel_type")
    expect_error(sim_data(bio, changed, iter_range = 0, output_dir = directory), "sel_type")
  }
  expect_false(dir.exists(directory))
  changed <- p
  changed$sel_L50_asc <- changed$sel_L95_asc + 1
  expect_error(sim_cal(changed), "sel_L50_asc")
  changed <- p
  changed$sel_L95_desc <- changed$sel_L50_desc
  expect_error(sim_cal(changed), "sel_L95_desc")
  changed <- p
  changed$sel_L50_desc <- NULL
  expect_error(sim_cal(changed), "sel_L50_desc")
})
