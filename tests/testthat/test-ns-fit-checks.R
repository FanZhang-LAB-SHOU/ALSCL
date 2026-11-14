# Checks for fits that pass the gradient, Hessian and bound checks but are not
# usable (parameters at their limit in practice, plausibility notes), the note
# on single starts, and the wide bounds of ACL.

# A fit object with the fields that the diagnostics read. Nothing is fitted.
ns_synthetic_fit <- function(par, model = "ALSCL", ...) {
  fit <- list(opt = list(par = par, objective = 100, convergence = 0L),
    vcov = diag(.01, length(par)), convergence_code = 0L, max_abs_gradient = 1e-8,
    pdHess = TRUE, bound_hit = FALSE, model_type = model,
    par_low_up = cbind(estimate = par, lower = par - 5, upper = par + 5),
    age = 1:4, len_border = seq(17.5, 52.5, 5),
    report = list(Linf = 60, vbk = .4, t0 = 1 / 60))
  extra <- list(...)
  fit[names(extra)] <- extra
  fit
}

# A fit of the five-year fixture. The survey index is the model prediction at
# `truth`, so the fit takes well under a second. `free` names the estimated
# parameters; `start` replaces starting values.
ns_small_fit <- function(model, free = "mean_log_R", truth = list(), start = list(),
                         t0_lower_truth = 0, silent = TRUE, ...) {
  f <- fixture_frames()
  f$data.CatL[[1]] <- as.character(seq(15, 55, 5)); f$data.wgt[[1]] <- f$data.mat[[1]] <- f$data.CatL[[1]]
  p <- create_parameters(model_type = tolower(model))$parameters
  p$log_Linf <- log(60); p$log_vbk <- log(.4); p$mean_log_R <- log(100); p$log_init_Z <- log(.5)
  prefix <- if (model == "ACL") "log_std_" else "log_sigma_"
  p[[paste0(prefix, "index")]] <- log(.2); p[[paste0(prefix, "log_N0")]] <- log(.1)
  p[[paste0(prefix, "log_R")]] <- log(.1)
  true_p <- p; true_p[names(truth)] <- truth
  prep <- do.call(ALSCL:::.acl_prepare_data, f); d <- prep$data
  if (model == "ALSCL") {
    d$len_mid <- prep$bins$mid; d$len_lower <- prep$bins$lower; d$len_upper <- prep$bins$upper
    d$growth_step <- 1
    if (t0_lower_truth != 0) d$t0_lower <- t0_lower_truth
  }
  true_p$dev_log_R <- rep(0, d$Y)
  true_p$dev_log_F <- array(0, c(if (model == "ACL") d$A else d$L, d$Y))
  true_p$dev_log_N0 <- rep(0, d$A - 1L)
  info <- ALSCL:::.acl_compile(model)
  generator <- TMB::MakeADFun(d, true_p, DLL = info$dll_name, silent = TRUE)
  f$data.CatL[-1] <- exp(generator$report(generator$par)$Elog_index)
  p[names(start)] <- start
  mapping <- lapply(p, function(x) factor(NA))
  mapping <- mapping[setdiff(names(mapping), free)]
  for (nm in free) mapping[nm] <- list(NULL)
  args <- c(f, list(parameters = p, map = mapping, silent = silent), list(...))
  list(fit = do.call(if (model == "ACL") run_acl else run_alscl, args), args = args)
}

ns_count <- function(messages, pattern) sum(grepl(pattern, messages, fixed = TRUE))
ns_new_elements <- c("limit_parameters", "at_limit", "advice", "plausibility", "check_thresholds")

test_that("the thresholds of the checks are constants in one place", {
  th <- ALSCL:::.acl_check_thresholds
  expect_identical(th$log_t0, -10)
  expect_identical(th$log_sd, -9)
  expect_identical(th$logit_correlation, 15)
  expect_identical(th$recruit_length_bins, 2)
  expect_identical(th$observation_sd, 0.9)
  expect_identical(th$growth_cv, 0.3)
  expect_identical(th$growth_cv_reference, c(0.10, 0.25))
  d <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5)))
  expect_identical(d$check_thresholds, th)
  # The thresholds of the earlier checks keep their element.
  expect_named(d$thresholds, c("gradient", "natural_boundary", "correlation", "sd_near_zero",
                               "refinement_gradient"))
})

test_that("a clean fit has no finding and keeps the earlier diagnostic elements", {
  fit <- ns_synthetic_fit(c(mean_log_R = 5, log_sigma_log_R = log(.4), logit_log_R = 1,
    log_t0 = -3, log_sigma_index = log(.3), log_cv_len = log(.2), log_cv_grow = log(.3),
    log_init_Z = log(.5)), M = .2)
  d <- ALSCL:::.acl_fit_diagnostics(fit)
  expect_true(d$numerical_ok)
  expect_length(d$issues, 0L)
  expect_false(d$at_limit)
  expect_identical(nrow(d$limit_parameters), 0L)
  expect_named(d$limit_parameters, c("parameter", "estimate", "natural", "description", "advice"))
  expect_identical(d$advice, character())
  expect_identical(nrow(d$plausibility), 0L)
  expect_named(d$plausibility, c("check", "parameter", "value", "threshold", "note"))
  expect_true(all(c("stationary", "numerical_ok", "natural_parameters", "natural_boundary",
    "covariance_condition", "high_correlations", "issues", "sd_near_zero",
    "refinement_unfinished", "thresholds", ns_new_elements) %in% names(d)))
})

test_that("log_t0 far below zero is reported as t0 at its lower limit", {
  fit <- ns_synthetic_fit(c(mean_log_R = 5, log_t0 = -19.9))
  d <- ALSCL:::.acl_fit_diagnostics(fit)
  expect_false(d$numerical_ok)
  expect_true(d$at_limit)
  expect_false(d$natural_boundary)
  expect_identical(d$limit_parameters$parameter, "log_t0")
  expect_equal(d$limit_parameters$natural, exp(-19.9))
  expect_match(d$issues, "parameter at its limit in practice: log_t0 = -19.9 \\(t0 = t0_lower \\+ 2.28e-09 years\\)")
  expect_match(d$advice, "t0_lower = 0", fixed = TRUE)
  expect_match(d$advice, "map = list(log_t0 = factor(NA))", fixed = TRUE)
  expect_match(d$advice, "allow a smaller t0 with t0_lower", fixed = TRUE)
  # The natural value follows t0_lower.
  shifted <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5, log_t0 = -12), t0_lower = -1))
  expect_equal(shifted$limit_parameters$natural, -1 + exp(-12))
  expect_match(shifted$advice, "t0_lower = -1", fixed = TRUE)
  # Just above the threshold, and the natural-scale t0 of ACL, give no finding.
  for (par in list(c(mean_log_R = 5, log_t0 = -9.99), c(mean_log_R = 5, t0 = -19.9))) {
    clean <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(par))
    expect_true(clean$numerical_ok)
    expect_false(clean$at_limit)
  }
})

test_that("a standard deviation run to zero is named with its natural value", {
  for (nm in c("log_sigma_log_N0", "log_std_log_N0", "log_sigma_log_R", "log_std_index")) {
    par <- c(mean_log_R = 5, x = -9.1); names(par)[2] <- nm
    d <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(par))
    # exp(-9.1) is above 1e-4, the threshold of the natural-scale boundary check.
    expect_false(d$natural_boundary)
    expect_false(d$numerical_ok)
    expect_identical(d$limit_parameters$parameter, nm)
    expect_equal(d$limit_parameters$natural, exp(-9.1))
    expect_match(d$issues, paste0(nm, " = -9.1 (standard deviation 0.000112)"), fixed = TRUE)
    expect_match(d$advice, "the variance is estimated at zero", fixed = TRUE)
    expect_match(d$advice, paste0("map = list(", nm, " = factor(NA))"), fixed = TRUE)
    par[[2]] <- -8.9
    clean <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(par))
    expect_false(clean$at_limit)
    expect_true(clean$numerical_ok)
  }
  # A standard deviation at the natural-scale boundary keeps that issue and is named too.
  d <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5, log_sigma_log_N0 = -10.2)))
  expect_true(d$natural_boundary)
  expect_true("natural-scale boundary" %in% d$issues)
  expect_true(any(grepl("log_sigma_log_N0 = -10.2", d$issues, fixed = TRUE)))
})

test_that("a correlation at an end of its range is reported under either correlation range", {
  low <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5, logit_log_R = -15.5)))
  expect_false(low$numerical_ok)
  expect_identical(low$limit_parameters$parameter, "logit_log_R")
  expect_equal(low$limit_parameters$natural, stats::plogis(-15.5))
  expect_match(low$advice, "lower end of its range (0 to 1)", fixed = TRUE)
  expect_match(low$advice, "structure = list(correlation_range = \"symmetric\")", fixed = TRUE)
  expect_match(low$advice, "map = list(logit_log_R = factor(NA))", fixed = TRUE)

  high <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5, logit_log_F_y = 15.5)))
  expect_false(high$numerical_ok)
  expect_equal(high$limit_parameters$natural, 1 - stats::plogis(-15.5))
  expect_match(high$advice, "a correlation of 1 - 1.86e-07, at the upper end of its range (0 to 1)", fixed = TRUE)
  expect_no_match(high$advice, "symmetric", fixed = TRUE)

  symmetric <- list(correlation_range = "symmetric")
  lowest <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5, logit_log_R = -15.5),
                                                         structure = symmetric))
  expect_false(lowest$numerical_ok)
  expect_equal(lowest$limit_parameters$natural, -1 + 2 * stats::plogis(-15.5))
  expect_match(lowest$advice, "a correlation of -1 + 3.71e-07, at the lower end of its range (-1 to 1)", fixed = TRUE)
  expect_no_match(lowest$advice, "correlation_range", fixed = TRUE)
  # Zero is inside the symmetric range.
  zero <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5, logit_log_R = 0), structure = symmetric))
  expect_true(zero$numerical_ok)
  expect_false(zero$at_limit)

  # Inside the range under both checks.
  inside <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5, logit_log_R = -8, logit_log_F_y = 8)))
  expect_true(inside$numerical_ok)
  expect_false(inside$at_limit)
  # Between the two thresholds the natural-scale boundary check fails the fit,
  # as before, and the parameter is now named with advice.
  between <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5, logit_log_R = -12)))
  expect_true(between$natural_boundary)
  expect_identical(between$limit_parameters$parameter, "logit_log_R")
  expect_match(between$advice, "correlation_range = \"symmetric\"", fixed = TRUE)
})

test_that("several parameters at their limit are listed together and fixed parameters are not checked", {
  fit <- ns_synthetic_fit(c(mean_log_R = 5, log_t0 = -15, log_sigma_log_N0 = -11, logit_log_R = 16))
  d <- ALSCL:::.acl_fit_diagnostics(fit)
  expect_identical(d$limit_parameters$parameter, c("log_t0", "log_sigma_log_N0", "logit_log_R"))
  expect_length(d$advice, 3L)
  expect_identical(sum(grepl("^parameters at their limit in practice: ", d$issues)), 1L)
  status <- ALSCL:::.acl_fit_status(fit)
  expect_false(status$numerical_ok)
  expect_match(status$issues, "parameters at their limit in practice", fixed = TRUE)
  # Only estimated parameters are in opt$par; a fit without them has no finding.
  expect_false(ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5)))$at_limit)
})

test_that("the mean length of recruits far below the smallest length bins gives a note", {
  # Borders 17.5, 22.5, ...: the note is given below 17.5 - 2 * 5 = 7.5.
  recruit <- function(Linf, k, t0, age = 1) Linf * (1 - exp(-k * (age - t0)))
  small <- ns_synthetic_fit(c(mean_log_R = 5), report = list(Linf = 60, vbk = .1, t0 = 1 / 60))
  d <- ALSCL:::.acl_fit_diagnostics(small)
  expect_identical(d$plausibility$check, "recruit_length")
  expect_equal(d$plausibility$value, recruit(60, .1, 1 / 60))
  expect_equal(d$plausibility$threshold, 7.5)
  expect_match(d$plausibility$note, "The mean length of recruits (rec.age = 1) is 5.62, more than 2 length-bin widths", fixed = TRUE)
  expect_match(d$plausibility$note, "Linf = 60, k = 0.1 per year, t0 = 0.0167 years", fixed = TRUE)
  # A note does not fail the screen and is not an issue.
  expect_true(d$numerical_ok)
  expect_length(d$issues, 0L)
  expect_identical(d$advice, character())
  # Both models, and growth parameters that are fixed (not in opt$par).
  expect_identical(ALSCL:::.acl_fit_diagnostics(
    ns_synthetic_fit(c(mean_log_R = 5), model = "ACL", report = list(Linf = 60, vbk = .1, t0 = 1 / 60)))$plausibility$check,
    "recruit_length")
  # Not triggered: larger recruits, and a value just above the limit.
  expect_identical(nrow(ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5)))$plausibility), 0L)
  k <- -log(1 - 7.6 / 60) / (1 - 1 / 60)
  expect_identical(nrow(ALSCL:::.acl_fit_diagnostics(
    ns_synthetic_fit(c(mean_log_R = 5), report = list(Linf = 60, vbk = k, t0 = 1 / 60)))$plausibility), 0L)
  # Incomplete objects give no note and no error.
  for (missing in list(list(report = NULL), list(age = NULL), list(len_border = NULL), list(len_border = 17.5))) {
    fit <- ns_synthetic_fit(c(mean_log_R = 5), report = list(Linf = 60, vbk = .1, t0 = 1 / 60))
    fit[names(missing)] <- missing
    expect_identical(nrow(ALSCL:::.acl_fit_diagnostics(fit)$plausibility), 0L)
  }
})

test_that("large observation error and large growth variation give notes for estimated parameters", {
  for (nm in c("log_std_index", "log_sigma_index")) {
    par <- c(mean_log_R = 5, x = log(.98)); names(par)[2] <- nm
    d <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(par))
    expect_identical(d$plausibility$check, "observation_sd")
    expect_identical(d$plausibility$parameter, nm)
    expect_equal(d$plausibility$value, .98)
    expect_match(d$plausibility$note, paste0("is estimated at 0.98 (", nm, "), above 0.9"), fixed = TRUE)
    expect_true(d$numerical_ok)
    par[[2]] <- log(.9)
    expect_identical(nrow(ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(par))$plausibility), 0L)
  }
  d <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5, log_cv_len = log(.41), log_cv_grow = log(.6))))
  expect_identical(d$plausibility$check, c("growth_cv", "growth_cv"))
  expect_identical(d$plausibility$parameter, c("log_cv_len", "log_cv_grow"))
  expect_equal(d$plausibility$value, c(.41, .6))
  expect_match(d$plausibility$note[1], "cv_len, the coefficient of variation of length at age, is estimated at 0.41", fixed = TRUE)
  expect_match(d$plausibility$note[1], "The example range in the Stock Synthesis manual is 0.10 to 0.25.", fixed = TRUE)
  expect_match(d$plausibility$note[2], "cv_grow, the coefficient of variation of the growth increment, is estimated at 0.6", fixed = TRUE)
  expect_no_match(d$plausibility$note[2], "Stock Synthesis", fixed = TRUE)
  expect_true(d$numerical_ok)
  expect_identical(nrow(ALSCL:::.acl_fit_diagnostics(
    ns_synthetic_fit(c(mean_log_R = 5, log_cv_len = log(.3), log_cv_grow = log(.3))))$plausibility), 0L)
})

test_that("an initial total mortality rate below natural mortality gives a note for scalar, vector and matrix M", {
  par <- c(mean_log_R = 5, log_init_Z = log(.19))
  scalar <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(par, M = .29))
  expect_identical(scalar$plausibility$check, "initial_Z")
  expect_equal(scalar$plausibility$value, .19)
  expect_equal(scalar$plausibility$threshold, .29)
  expect_match(scalar$plausibility$note, "is estimated at 0.19 per time step (log_init_Z), below the natural mortality rate M = 0.29",
               fixed = TRUE)
  expect_true(scalar$numerical_ok)
  # The smallest value of a vector or a matrix is used.
  vector <- ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(par, M = c(.8, .4, .25)))
  expect_equal(vector$plausibility$threshold, .25)
  expect_match(vector$plausibility$note, "below the smallest natural mortality rate M = 0.25", fixed = TRUE)
  matrix_M <- matrix(c(.9, .5, .3, .22, .6, .4), 3, 2)
  expect_equal(ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(par, M = matrix_M))$plausibility$threshold, .22)
  # Not triggered when one value of M is below the estimate, or when Z is not below M.
  expect_identical(nrow(ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(par, M = c(.8, .1)))$plausibility), 0L)
  expect_identical(nrow(ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(par, M = .19))$plausibility), 0L)
  # M is read from the recipe or the TMB data when the fit has no M element,
  # and without M there is no note.
  expect_identical(ALSCL:::.acl_fit_M(ns_synthetic_fit(par, recipe = list(args = list(M = .3)))), .3)
  expect_identical(ALSCL:::.acl_fit_M(ns_synthetic_fit(par, obj = list(env = list(data = list(M = .4))))), .4)
  expect_identical(ALSCL:::.acl_fit_diagnostics(
    ns_synthetic_fit(par, recipe = list(args = list(M = .3))))$plausibility$check, "initial_Z")
  expect_null(ALSCL:::.acl_fit_M(ns_synthetic_fit(par)))
  # With M by age and time step or by length the single number M in the TMB
  # data is a summary; the check reads the full rates.
  by_age <- list(env = list(data = list(M = .6, M_AY = matrix(c(.05, .6, 1.2), 3, 2))))
  expect_identical(range(ALSCL:::.acl_fit_M(ns_synthetic_fit(par, obj = by_age))), c(.05, 1.2))
  by_length <- list(env = list(data = list(M = .6, M_LAY = array(c(.1, .9), c(2, 3, 2)))))
  expect_identical(range(ALSCL:::.acl_fit_M(ns_synthetic_fit(par, obj = by_length))), c(.1, .9))
  expect_identical(nrow(ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(par))$plausibility), 0L)
  # A fixed initial Z (not in opt$par) is not checked.
  expect_identical(nrow(ALSCL:::.acl_fit_diagnostics(ns_synthetic_fit(c(mean_log_R = 5), M = 5))$plausibility), 0L)
})

test_that("an ACL fit at an upper bound below that of ALSCL is told how to widen it", {
  par <- c(log_init_Z = 0, mean_log_F = 0, mean_log_R = 5)
  bounds <- cbind(estimate = par, lower = c(log(.01), log(.01), -20), upper = c(0, 0, 30))
  fit <- ns_synthetic_fit(par, model = "ACL", par_low_up = bounds, bound_hit = TRUE)
  d <- ALSCL:::.acl_fit_diagnostics(fit)
  expect_false(d$numerical_ok)
  expect_true("optimizer-scale boundary" %in% d$issues)
  expect_length(d$advice, 1L)
  expect_match(d$advice, "log_init_Z (1 on the natural scale), mean_log_F (1 on the natural scale) stopped at upper bounds of ACL",
               fixed = TRUE)
  expect_match(d$advice, "10 for log_init_Z, 2 for mean_log_F", fixed = TRUE)
  expect_match(d$advice, "run_acl(bounds = \"wide\")", fixed = TRUE)
  expect_match(d$advice, "parameters.U", fixed = TRUE)
  # Not at a bound, at the wide bound, at a lower bound, or an ALSCL fit: no advice.
  inside <- bounds; inside[, "estimate"] <- c(-.5, -.5, 5)
  wide <- bounds; wide[, "upper"] <- c(log(10), log(2), 30); wide[, "estimate"] <- c(log(10), log(2), 5)
  lower <- bounds; lower[, "estimate"] <- c(log(.01), log(.01), 5)
  for (b in list(inside, wide, lower))
    expect_identical(ALSCL:::.acl_bound_advice(ns_synthetic_fit(par, model = "ACL", par_low_up = b)), character())
  expect_identical(ALSCL:::.acl_bound_advice(ns_synthetic_fit(par, model = "ALSCL", par_low_up = bounds)), character())
  expect_identical(ALSCL:::.acl_bound_advice(ns_synthetic_fit(par, model = "ACL", par_low_up = NULL)), character())
})

test_that("t0 at its upper bound is explained", {
  # ALSCL: the bound that follows the first modelled age.
  par <- c(mean_log_R = 5, log_t0 = log(1 * (1 - 1e-6)))
  at_age <- cbind(estimate = par, lower = c(-20, -20), upper = c(30, log(1 * (1 - 1e-6))))
  advice <- ALSCL:::.acl_bound_advice(ns_synthetic_fit(par, par_low_up = at_age))
  expect_match(advice, "log_t0 stopped at its upper bound, where t0 equals the first modelled age (rec.age = 1)", fixed = TRUE)
  # ALSCL: a bound below the first modelled age (the default limit of 5 years above t0_lower).
  par <- c(mean_log_R = 5, log_t0 = log(5))
  capped <- cbind(estimate = par, lower = c(-20, -20), upper = c(30, log(5)))
  advice <- ALSCL:::.acl_bound_advice(ns_synthetic_fit(par, par_low_up = capped, age = 7:10))
  expect_match(advice, "log_t0 stopped at its upper bound (t0 = 5 years), which is below the first modelled age (rec.age = 7)",
               fixed = TRUE)
  expect_match(advice, "up to log(7), can be supplied in parameters.U", fixed = TRUE)
  # ACL: t0 on the natural scale.
  par <- c(mean_log_R = 5, t0 = 1 - 1e-6)
  acl <- cbind(estimate = par, lower = c(-20, -5), upper = c(30, 1 - 1e-6))
  expect_match(ALSCL:::.acl_bound_advice(ns_synthetic_fit(par, model = "ACL", par_low_up = acl)),
               "t0 stopped at its upper bound, where t0 equals the first modelled age", fixed = TRUE)
  # t0 inside its bounds: no advice.
  par <- c(mean_log_R = 5, log_t0 = -2)
  expect_identical(ALSCL:::.acl_bound_advice(ns_synthetic_fit(par, par_low_up = cbind(estimate = par,
    lower = c(-20, -20), upper = c(30, log(1 - 1e-6))))), character())
})

test_that("the default upper bound of log_t0 follows the first modelled age and t0_lower", {
  f <- fixture_frames()
  setup <- ALSCL:::.acl_model_setup("ALSCL", do.call(ALSCL:::.acl_prepare_data, f))
  expect_equal(setup$config$parameters.U$log_t0, log(1 * (1 - 1e-6)), tolerance = 1e-14)
  shifted <- ALSCL:::.acl_model_setup("ALSCL", do.call(ALSCL:::.acl_prepare_data, c(f, list(t0_lower = -1))))
  expect_equal(shifted$config$parameters.U$log_t0, log(2) + log1p(-1e-6), tolerance = 1e-14)
  # More than 5 years between t0_lower and the first modelled age: the default limit of 5 years stays.
  f$rec.age <- 7
  late <- ALSCL:::.acl_model_setup("ALSCL", do.call(ALSCL:::.acl_prepare_data, f))
  expect_identical(late$config$parameters.U$log_t0, log(5))
})

test_that("bounds = \"wide\" gives ACL the ALSCL bounds of five parameters and nothing else", {
  default <- create_parameters("acl")
  expect_identical(create_parameters("acl", bounds = "default"), default)
  five <- c("log_init_Z", "mean_log_F", "log_std_log_N0", "log_std_log_R", "log_vbk")
  # The defaults are those of earlier versions.
  expect_equal(unlist(default$parameters.U[five]), stats::setNames(rep(0, 5), five))
  expect_equal(default$parameters.L$log_vbk, log(.1))
  wide <- create_parameters("acl", bounds = "wide")
  alscl <- create_parameters("alscl")
  expect_equal(exp(unlist(wide$parameters.U[five])), c(log_init_Z = 10, mean_log_F = 2, log_std_log_N0 = 10,
    log_std_log_R = 10, log_vbk = 2))
  expect_identical(unname(wide$parameters.U[five]),
    unname(alscl$parameters.U[c("log_init_Z", "mean_log_F", "log_sigma_log_N0", "log_sigma_log_R", "log_vbk")]))
  expect_identical(unname(wide$parameters.L[five]),
    unname(alscl$parameters.L[c("log_init_Z", "mean_log_F", "log_sigma_log_N0", "log_sigma_log_R", "log_vbk")]))
  expect_equal(wide$parameters.L$log_vbk, log(.05))
  # Starting values and all other bounds are unchanged.
  expect_identical(wide$parameters, default$parameters)
  others <- setdiff(names(default$parameters.U), five)
  expect_identical(wide$parameters.U[others], default$parameters.U[others])
  expect_identical(wide$parameters.L[setdiff(names(default$parameters.L), "log_vbk")],
                   default$parameters.L[setdiff(names(default$parameters.L), "log_vbk")])
  # A supplied bound replaces the wide bound.
  expect_identical(create_parameters("acl", parameters.U = list(log_init_Z = log(3)), bounds = "wide")$parameters.U$log_init_Z,
                   log(3))
  # No effect for ALSCL or with a species preset, where the two models agree.
  expect_identical(create_parameters("alscl", bounds = "wide"), alscl)
  for (species in c("flatfish", "tuna", "krill"))
    expect_identical(create_parameters("acl", species = species, bounds = "wide"),
                     create_parameters("acl", species = species))
  # The earlier positional form still works.
  expect_identical(create_parameters("acl", list(log_vbk = log(.3)))$parameters$log_vbk, log(.3))
  expect_error(create_parameters("acl", bounds = "narrow"), "should be one of")
})

test_that("run_acl passes bounds to the fit and keeps the default bounds otherwise", {
  f <- fixture_frames()
  five <- c("log_init_Z", "mean_log_F", "log_std_log_N0", "log_std_log_R", "log_vbk")
  default <- ALSCL:::.acl_model_setup("ACL", do.call(ALSCL:::.acl_prepare_data, f))
  explicit <- ALSCL:::.acl_model_setup("ACL", do.call(ALSCL:::.acl_prepare_data, c(f, list(bounds = "default"))))
  expect_identical(explicit$config, default$config)
  expect_equal(unlist(default$config$parameters.U[five]), stats::setNames(rep(0, 5), five))
  wide <- ALSCL:::.acl_model_setup("ACL", do.call(ALSCL:::.acl_prepare_data, c(f, list(bounds = "wide"))))
  expect_equal(exp(unlist(wide$config$parameters.U[five])),
               c(log_init_Z = 10, mean_log_F = 2, log_std_log_N0 = 10, log_std_log_R = 10, log_vbk = 2))
  expect_identical(wide$parameters, default$parameters)
  expect_error(do.call(ALSCL:::.acl_prepare_data, c(f, list(bounds = "narrow"))), "should be one of")
  # The argument exists for ACL only; inspection and bundles accept it there.
  expect_true("bounds" %in% names(formals(run_acl)))
  expect_false("bounds" %in% names(formals(run_alscl)))
  expect_true("bounds" %in% names(formals(retro_model)))
  x <- prepare_alscl_data(f[c("data.CatL", "data.wgt", "data.mat")],
    fit_args = f[c("rec.age", "nage", "M", "sel_L50", "sel_L95")], fit_config = list(acl = list(bounds = "wide")))
  table <- inspect_parameters(x, "acl")
  expect_equal(table$upper[table$parameter == "log_init_Z"], log(10))
  expect_equal(inspect_parameters(x, "alscl")$upper[inspect_parameters(x, "alscl")$parameter == "log_init_Z"], log(10))
})

test_that("an ACL fit that stops at a default upper bound leaves it with bounds = \"wide\"", {
  skip_on_cran()
  # The survey index follows an initial total mortality rate of 1.5, above the default upper bound of 1.
  stopped <- ns_small_fit("ACL", c("mean_log_R", "log_init_Z"), truth = list(log_init_Z = log(1.5)))$fit
  expect_true(stopped$bound_hit)
  expect_identical(unname(stopped$par_low_up["log_init_Z", c("estimate", "upper")]), c(0, 0))
  expect_false(stopped$diagnostics$numerical_ok)
  expect_match(stopped$diagnostics$advice, "run_acl(bounds = \"wide\")", fixed = TRUE)
  expect_output(print(summary(stopped)), "Advice: log_init_Z (1 on the natural scale) stopped at an upper bound of ACL", fixed = TRUE)
  expect_identical(summary(stopped)$advice, stopped$diagnostics$advice)
  # Default bounds are what they were.
  expect_equal(stopped$par_low_up["log_init_Z", "lower"], log(.01))

  wide <- ns_small_fit("ACL", c("mean_log_R", "log_init_Z"), truth = list(log_init_Z = log(1.5)), bounds = "wide")
  fit <- wide$fit
  expect_false(fit$bound_hit)
  expect_equal(fit$par_low_up["log_init_Z", "upper"], log(10))
  expect_equal(exp(fit$opt$par[["log_init_Z"]]), 1.5, tolerance = .02)
  expect_true(fit$diagnostics$numerical_ok)
  expect_identical(fit$diagnostics$advice, character())
  expect_null(summary(fit)$advice)
  expect_identical(fit$recipe$args$bounds, "wide")
  # A refit from the recipe keeps the wide bounds.
  again <- refit_model(fit, silent = TRUE)
  expect_equal(again$par_low_up["log_init_Z", "upper"], log(10))
  expect_equal(again$opt$par, fit$opt$par, tolerance = 1e-8)
  # The message of the fit carries the advice in the diagnostics message.
  args <- ns_small_fit("ACL", c("mean_log_R", "log_init_Z"), truth = list(log_init_Z = log(1.5)))$args
  args$silent <- FALSE
  messages <- testthat::capture_messages(do.call(run_acl, args))
  line <- grep("^Fit diagnostics: ", messages, value = TRUE)
  expect_length(line, 1L)
  expect_match(line, "optimizer-scale boundary. log_init_Z (1 on the natural scale) stopped at an upper bound of ACL", fixed = TRUE)
})

test_that("fits report a standard deviation and a t0 that ran to their limits", {
  skip_on_cran()
  for (model in c("ACL", "ALSCL")) {
    nm <- if (model == "ACL") "log_std_log_N0" else "log_sigma_log_N0"
    # No deviations of the initial numbers at age in the data: their standard deviation runs to zero.
    x <- ns_small_fit(model, c("mean_log_R", nm))
    fit <- x$fit
    expect_false(fit$bound_hit)
    expect_lt(fit$opt$par[[nm]], -9)
    expect_true(fit$diagnostics$at_limit)
    expect_false(fit$diagnostics$numerical_ok)
    expect_identical(fit$diagnostics$limit_parameters$parameter, nm)
    expect_false(summary(fit)$diagnostics$numerical_ok)
    expect_match(summary(fit)$diagnostics$issues, paste0("parameter at its limit in practice: ", nm), fixed = TRUE)
    expect_output(print(fit), paste0("Advice: ", nm, " is estimated at "), fixed = TRUE)
    metrics <- suppressMessages(utils::capture.output(table <- diagnose_model(x$args$data.CatL, fit)))
    expect_equal(as.numeric(table$Value[table$Metric == "Parameters At Limit In Practice"]), 1)
    expect_equal(as.numeric(table$Value[table$Metric == "Plausibility Notes"]), 0)
    # The same fit with that standard deviation fixed has no finding.
    clean <- ns_small_fit(model)$fit
    expect_true(clean$diagnostics$numerical_ok)
    expect_false(clean$diagnostics$at_limit)
    expect_identical(nrow(clean$diagnostics$plausibility), 0L)
    expect_null(summary(clean)$advice)
    expect_null(summary(clean)$plausibility)
  }
  # The data follow a negative t0; with t0_lower = 0 the estimate runs to the limit.
  negative <- ns_small_fit("ALSCL", c("mean_log_R", "log_t0"), t0_lower_truth = -1)$fit
  expect_lt(negative$opt$par[["log_t0"]], -10)
  expect_identical(negative$diagnostics$limit_parameters$parameter, "log_t0")
  expect_false(negative$diagnostics$numerical_ok)
  expect_match(negative$diagnostics$advice, "allow a smaller t0 with t0_lower", fixed = TRUE)
  # Following the advice gives a fit without the finding.
  allowed <- ns_small_fit("ALSCL", c("mean_log_R", "log_t0"), t0_lower_truth = -1, t0_lower = -1)$fit
  expect_false(allowed$diagnostics$at_limit)
  expect_true(allowed$diagnostics$numerical_ok)
  expect_equal(allowed$report$t0, -1 + 1 / 60, tolerance = .1)
  # An interior t0 gives no finding.
  interior <- ns_small_fit("ALSCL", c("mean_log_R", "log_t0"))$fit
  expect_false(interior$diagnostics$at_limit)
})

test_that("fits give plausibility notes in messages and summaries without failing the screen", {
  skip_on_cran()
  # Initial total mortality rate of 0.1 with M = 0.2.
  low <- ns_small_fit("ACL", c("mean_log_R", "log_init_Z"), truth = list(log_init_Z = log(.1)))
  fit <- low$fit
  expect_true(fit$diagnostics$numerical_ok)
  expect_identical(fit$diagnostics$plausibility$check, "initial_Z")
  expect_equal(fit$diagnostics$plausibility$threshold, .2)
  expect_identical(summary(fit)$plausibility, fit$diagnostics$plausibility$note)
  expect_true(summary(fit)$diagnostics$numerical_ok)
  expect_output(print(fit), "Plausibility note: The initial total mortality rate is estimated at", fixed = TRUE)
  args <- low$args; args$silent <- FALSE
  messages <- testthat::capture_messages(do.call(run_acl, args))
  expect_identical(ns_count(messages, "Plausibility notes: The initial total mortality rate"), 1L)
  expect_identical(ns_count(messages, "Fit diagnostics"), 0L)
  # Slow growth puts the recruits far below the smallest length bins, in both models.
  for (model in c("ACL", "ALSCL")) {
    slow <- ns_small_fit(model, truth = list(log_vbk = log(.08)), start = list(log_vbk = log(.08)))$fit
    expect_identical(slow$diagnostics$plausibility$check, "recruit_length")
    expect_true(slow$diagnostics$numerical_ok)
  }
  # A silent fit gives no message.
  expect_no_message(do.call(run_acl, low$args))
})

test_that("objects of earlier versions without the new elements print and summarise", {
  skip_on_cran()
  fit <- ns_small_fit("ACL", c("mean_log_R", "log_std_log_N0"))$fit
  current <- summary(fit)
  # A fit stored by an earlier version: the stored verdict is kept.
  legacy <- fit
  legacy$diagnostics[ns_new_elements] <- NULL
  legacy$diagnostics$issues <- "natural-scale boundary"
  s <- summary(legacy)
  expect_null(s$advice)
  expect_null(s$plausibility)
  expect_identical(s$diagnostics$issues, "natural-scale boundary")
  expect_output(print(legacy), "ACL assessment")
  expect_identical(s$parameters, current$parameters)
  quiet <- utils::capture.output(table <- diagnose_model(fit$recipe$args$data.CatL, legacy))
  expect_false("Parameters At Limit In Practice" %in% table$Metric)
  expect_true("Natural Scale Boundary" %in% table$Metric)
  # A stored verdict that passed is not changed by the new checks.
  passed <- legacy
  passed$diagnostics$numerical_ok <- TRUE; passed$diagnostics$natural_boundary <- FALSE
  passed$diagnostics$issues <- character()
  expect_true(ALSCL:::.acl_fit_status(passed)$numerical_ok)
  # A fit without stored diagnostics is screened with the current checks.
  bare <- fit; bare$diagnostics <- NULL
  status <- ALSCL:::.acl_fit_status(bare)
  expect_false(status$numerical_ok)
  expect_match(status$issues, "parameter at its limit in practice: log_std_log_N0", fixed = TRUE)
  expect_output(print(summary(bare)), "ACL assessment")
  # A diagnostics list of a much earlier version.
  minimal <- fit; minimal$diagnostics <- list(numerical_ok = TRUE, natural_boundary = FALSE, issues = character())
  expect_output(print(summary(minimal)), "ACL assessment")
  expect_null(summary(minimal)$advice)
})

test_that("simulation summaries name a parameter at its limit as a failure reason", {
  fit <- list(year = c(2000, 2001), report = list(SSB = c(11, 18)),
    est_std = cbind(Estimate = c(11, 18), `Std. Error` = c(1, 1)),
    opt = list(par = c(mean_log_R = 1, log_t0 = -3), objective = 1), elapsed = 2,
    convergence_code = 0L, pdHess = TRUE, bound_hit = FALSE, max_abs_gradient = 0, vcov = diag(.01, 2))
  rownames(fit$est_std) <- c("SSB", "SSB")
  fit$diagnostics <- ALSCL:::.acl_fit_diagnostics(fit)
  limit <- fit; limit$opt$par[["log_t0"]] <- -15
  limit$diagnostics <- ALSCL:::.acl_fit_diagnostics(limit)
  target <- list(year = c(2000, 2001), SSB = c(10, 20))
  z <- summarize_simulations(list(one = fit, two = limit), list(one = target, two = target), quantities = "SSB")
  expect_identical(z$replicates$numerical_ok, c(TRUE, FALSE))
  expect_identical(z$replicates$failure_reasons, c("", "parameter at its limit in practice"))
  counts <- stats::setNames(z$failures$n_replicates, z$failures$reason)
  expect_identical(counts[["parameter at its limit in practice"]], 1L)
  expect_identical(counts[["other"]], 0L)
})

test_that("a fit with one start gives the note once, and a silent or multistart fit does not", {
  skip_on_cran()
  note <- "One start was used (nstarts = 1)"
  args <- ns_small_fit("ACL")$args
  expect_no_message(do.call(run_acl, args))
  args$silent <- FALSE
  messages <- testthat::capture_messages(fit <- do.call(run_acl, args))
  expect_identical(ns_count(messages, note), 1L)
  expect_identical(ns_count(messages, "at least three starts"), 1L)
  expect_identical(ns_count(messages, "nstarts = 3 and start_spread = 0.5"), 1L)
  expect_identical(fit$nstarts, 1L)
  # The default number of starts is unchanged.
  expect_identical(eval(formals(run_acl)$ncores), 1)
  expect_identical(formals(run_acl)$nstarts, quote(ncores))
  expect_identical(formals(run_alscl)$nstarts, quote(ncores))
  two <- testthat::capture_messages(do.call(run_acl, c(args, list(nstarts = 2))))
  expect_identical(ns_count(two, note), 0L)
  # A bundle and a refit are one fit each.
  bundle <- testthat::capture_messages(run_acl(args))
  expect_identical(ns_count(bundle, note), 1L)
  refit <- testthat::capture_messages(refit_model(fit))
  expect_identical(ns_count(refit, note), 1L)
  alscl <- ns_small_fit("ALSCL")$args; alscl$silent <- FALSE
  expect_identical(ns_count(testthat::capture_messages(do.call(run_alscl, alscl)), note), 1L)
})

test_that("functions that run several fits give the note on single starts once per call", {
  skip_on_cran()
  note <- "One start was used (nstarts = 1)"
  args <- ns_small_fit("ACL")$args
  args$silent <- FALSE
  scenarios <- list(base = list(), high_M = list(M = .25), low_M = list(M = .15))
  messages <- testthat::capture_messages(z <- fit_scenarios(args, scenarios, model = "acl"))
  expect_identical(ns_count(messages, "Fitting ACL with 1 start(s)"), 3L)
  expect_identical(ns_count(messages, note), 1L)
  # The next call gives the note again, and a single fit after a batch does too.
  again <- testthat::capture_messages(fit_scenarios(args, scenarios[1:2], model = "acl"))
  expect_identical(ns_count(again, note), 1L)
  expect_identical(ns_count(testthat::capture_messages(do.call(run_acl, args)), note), 1L)
  # Silent scenarios and scenarios with several starts give no note.
  expect_identical(ns_count(testthat::capture_messages(fit_scenarios(args, scenarios[1:2], model = "acl", silent = TRUE)),
                            note), 0L)
  expect_identical(ns_count(testthat::capture_messages(fit_scenarios(args, scenarios[1:2], model = "acl", nstarts = 2)),
                            note), 0L)
  # Hindcast folds: once when not silent, never when silent (the default).
  hind <- testthat::capture_messages(hindcast_model(args, model = "acl", nfolds = 2, min_train = 3, silent = FALSE))
  expect_identical(ns_count(hind, "Fitting ACL with 1 start(s)"), 2L)
  expect_identical(ns_count(hind, note), 1L)
  expect_identical(ns_count(testthat::capture_messages(hindcast_model(args, model = "acl", nfolds = 2, min_train = 3)),
                            note), 0L)
  # Retrospective peels and profile points are silent fits.
  retro <- testthat::capture_messages(do.call(retro_model, c(list(nyear = 1, model_type = "acl"),
    args[setdiff(names(args), "silent")])))
  expect_identical(ns_count(retro, note), 0L)
  # A batch that stops with an error closes itself: the next fit gives the note.
  expect_error(ALSCL:::.acl_cluster_lapply(1:2, function(i) stop("stopped"), 1L, "acl"), "stopped")
  expect_identical(ALSCL:::.acl_notes$depth, 0L)
  expect_identical(ns_count(testthat::capture_messages(do.call(run_acl, args)), note), 1L)
})

test_that("the note on single starts reaches the user once when scenarios run on socket workers", {
  skip_on_cran()
  note <- "One start was used (nstarts = 1)"
  settings <- list(list(silent = FALSE, nstarts = 1L), list(silent = FALSE, nstarts = 1L))
  # The decision is made before any worker starts; a stub replaces the fits.
  testthat::local_mocked_bindings(
    .acl_cluster_lapply = function(X, FUN, ncores, model, ...) vector("list", length(X)),
    .acl_workers = function(n) as.integer(n), .package = "ALSCL")
  expect_identical(ns_count(testthat::capture_messages(ALSCL:::.acl_batch_apply(settings, "acl", 2L)), note), 1L)
  # One worker: the fits give the note themselves.
  expect_identical(ns_count(testthat::capture_messages(ALSCL:::.acl_batch_apply(settings, "acl", 1L)), note), 0L)
  quiet <- list(list(silent = TRUE, nstarts = 1L), list(silent = FALSE, nstarts = 3L))
  expect_identical(ns_count(testthat::capture_messages(ALSCL:::.acl_batch_apply(quiet, "acl", 2L)), note), 0L)
})
