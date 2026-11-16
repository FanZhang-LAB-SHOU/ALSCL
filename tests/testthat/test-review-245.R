# Fixes of the review before release 2.4.5: negative correlations in hindcast
# predictions, map compatibility of profiles, the projection screen of older
# fits, quarterly time labels, per-call title settings of plot_self_test(),
# methods and messages for failure records, the default t0 start under
# t0_lower, the note on supplied correlation starts under the symmetric range,
# relative errors of negative truths, random-number settings and t0_lower in
# sim_model().

failure_record <- function()
  structure(list(converge = "FAILED", error = "M must be positive"), class = "alscl_fit_error")

test_that("hindcast predictions accept a negative fitted correlation", {
  skip_on_cran()
  fit <- fit_fixture("ACL")$result
  fit$report$phi_log_R <- -0.3
  prediction <- ALSCL:::.acl_hindcast_predict(fit, 2)
  expect_true(is.list(prediction))
  fit$report$phi_log_R <- -1.2
  expect_error(ALSCL:::.acl_hindcast_predict(fit, 2), "recruitment correlation")
})

test_that("profile_model() accepts an archived map entry for a parameter the model lacks", {
  skip_on_cran()
  fit <- run_acl(YTF_example, silent = TRUE)
  fit$recipe$args$map <- c(fit$recipe$args$map, list(log_t0 = NULL))
  start <- exp(fit$opt$par[["log_init_Z"]])
  profile <- profile_model(fit, "log_init_Z", values = start * c(0.95, 1.05))
  expect_true(all(is.finite(profile$grid$objective)))
})

test_that("project_model() and simulate_fit() reject an older fit whose stored fields show a failure", {
  skip_on_cran()
  fit <- fit_fixture("ACL")$result
  expect_true(ALSCL:::.acl_source_screen(fit))
  old <- fit
  old$diagnostics <- NULL
  expect_true(is.na(ALSCL:::.acl_source_screen(old)))
  old$pdHess <- FALSE
  expect_false(ALSCL:::.acl_source_screen(old))
  L <- length(fit$len_mid)
  args <- list(F = matrix(0.1, length(fit$age), 2), recruitment = c(100, 100),
               weight = matrix(1, L, 2), maturity = matrix(1, L, 2))
  expect_error(do.call(project_model, c(list(old), args)), "failed the numerical screen")
  expect_warning(projection <- do.call(project_model, c(list(old, allow_failed_fit = TRUE), args)),
                 "failed the numerical screen")
  expect_identical(projection$assumptions$source_fit_status, "failed")
  expect_error(simulate_fit(old), "failed the numerical screen")
})

test_that("whole-number times of a quarterly fit are first quarters", {
  labels <- ALSCL:::.acl_time_labels
  expect_identical(labels(c(2003, 2004), step = 0.25), c("2003 Q1", "2004 Q1"))
  expect_identical(labels(c(2003, 2004), step = 0.25, prefix = FALSE), c("2003 Q1", "2004 Q1"))
  expect_identical(labels(c(2003, 2004)), c("Year 2003", "Year 2004"))
  expect_identical(labels(c(2003, 2004), step = 1), c("Year 2003", "Year 2004"))
  expect_identical(labels(c(2003.75, 2004), step = 0.25), c("2003 Q4", "2004 Q1"))
})

test_that("the figure title of plot_self_test() follows the per-call settings", {
  skip_on_cran()
  st <- self_test(fit_fixture("ACL")$result, nsim = 2, seed = 3, quantities = c("SSB", "Rec"))
  p <- plot_self_test(st, title_size = 21, font_family = "serif", title_hjust = 0,
                      facet_scales = "fixed")
  title <- p$patches$annotation$theme$plot.title
  expect_equal(title$size, 21)
  expect_equal(title$hjust, 0)
  expect_identical(p$patches$annotation$theme$text$family, "serif")
  series <- plot_self_test(st, what = "series", facet_scales = "fixed")
  expect_false(series$facet$params$free$y)
  expect_true(plot_self_test(st, what = "series")$facet$params$free$y)
})

test_that("failure records give NA model statistics and one message", {
  err <- failure_record()
  expect_true(is.na(AIC(err)))
  expect_true(is.na(BIC(err)))
  expect_true(is.na(nobs(err)))
  expect_null(fitted(err))
  expect_null(coef(err))
  for (f in list(extract_estimates, extract_parameters, plot_SSB, plot_VB, plot_pla, plot_deviance,
                 plot_SSB_Rec, plot_fishing_mortality, plot_residuals, plot_survey_catchability,
                 plot_natural_mortality, refit_model, simulate_fit))
    expect_error(f(err), "failed fit without estimates.*M must be positive")
  expect_error(project_model(err, F = 0, recruitment = 1, weight = 1, maturity = 1),
               "failed fit without estimates")
})

test_that("a default t0 start keeps its natural value under t0_lower", {
  x <- YTF_example
  x$fit_config$alscl$parameters$log_t0 <- NULL
  x$fit_config$alscl$map$log_t0 <- NULL
  x$fit_config$alscl$t0_lower <- -1
  plan <- inspect_parameters(x, "alscl")
  expect_equal(plan$natural_start[plan$parameter == "log_t0"], 1 / 60)
  x$fit_config$alscl$parameters$log_t0 <- log(0.5 + 1)
  plan <- inspect_parameters(x, "alscl")
  expect_equal(plan$natural_start[plan$parameter == "log_t0"], 0.5)
})

test_that("supplied correlation starts under the symmetric range are named", {
  supplied <- ALSCL:::.acl_symmetric_supplied(list(correlation_range = "symmetric"),
                                              YTF_example$fit_config$acl$parameters, "ACL")
  expect_equal(names(supplied), "logit_log_R")
  expect_null(ALSCL:::.acl_symmetric_supplied(list(), YTF_example$fit_config$acl$parameters, "ACL"))
  expect_message(ALSCL:::.acl_symmetric_start_note(supplied, FALSE), "correlation of -0.8")
  expect_silent(ALSCL:::.acl_symmetric_start_note(supplied, TRUE))
})

test_that("a relative error is positive for an overestimate of a negative truth", {
  expect_equal(ALSCL:::.acl_relative_error(c(0.1, -0.1, 0.1), c(-0.3, 2, 0)), c(1 / 3, -0.05, NA))
})

test_that("random-number settings do not depend on the session", {
  previous <- RNGkind()
  on.exit(suppressWarnings(do.call(RNGkind, as.list(previous))), add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  first <- simulate_example_data(seed = 42)$data.CatL
  RNGkind("L'Ecuyer-CMRG", "Box-Muller", "Rejection")
  second <- simulate_example_data(seed = 42)$data.CatL
  expect_identical(first, second)
  expect_identical(RNGkind()[1:2], c("L'Ecuyer-CMRG", "Box-Muller"))
  suppressWarnings(RNGkind("Mersenne-Twister", "Inversion", "Rounding"))
  restore <- ALSCL:::.acl_preserve_rng()
  set.seed(1, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  expect_no_warning(restore())
  expect_identical(RNGkind()[3], "Rounding")
})

test_that("sim_model() takes t0_lower for ALSCL only", {
  expect_true("t0_lower" %in% names(formals(sim_model)))
  expect_error(sim_model(iter_range = 1, sim_data_path = tempdir(), model = "acl", t0_lower = -1),
               "ALSCL only")
})

test_that("the error of failed starts names a TMB and Matrix mismatch and its remedy", {
  starts <- list(list(message = "NA/NaN function evaluation"),
                 list(message = "NA/NaN gradient evaluation"))
  mismatch <- ALSCL:::.acl_starts_failed_message(starts,
    abi = list(built = "1", current = "2", ok = FALSE))
  expect_match(mismatch, "^All optimization starts failed: NA/NaN function evaluation; NA/NaN gradient evaluation")
  expect_match(mismatch, "built with Matrix ABI version 1, but the installed Matrix package has ABI version 2", fixed = TRUE)
  expect_match(mismatch, 'install.packages("TMB", type = "source")', fixed = TRUE)
  for (abi in list(list(built = "2", current = "2", ok = TRUE), list(built = "2", current = "2", ok = NA), NULL))
    expect_identical(ALSCL:::.acl_starts_failed_message(starts, abi = abi),
                     "All optimization starts failed: NA/NaN function evaluation; NA/NaN gradient evaluation")

  abi <- ALSCL:::.acl_tmb_matrix_abi()
  skip_if(is.null(abi), "This TMB version has no Matrix ABI check")
  check <- utils::getFromNamespace("checkMatrixPackageVersion", "TMB")
  expect_identical(abi$ok, suppressWarnings(as.logical(check())))
})

test_that("DESCRIPTION requires a TMB version that the checks have used", {
  imports <- utils::packageDescription("ALSCL")$Imports
  expect_match(imports, "TMB \\(>= 1\\.9\\.21\\)")
  expect_true(utils::packageVersion("TMB") >= "1.9.21")
  expect_true("1.9.21" %in% ALSCL:::.acl_tmb_checked)
})
