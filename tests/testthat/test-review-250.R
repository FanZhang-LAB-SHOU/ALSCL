# Fixes of the review before release 2.5.0: extract_estimates() and
# summarize_simulations() use the interval form of the plots and of
# self_test(), and the note on a supplied log_t0 under t0_lower is given only
# when t0_lower and log_t0 come from different places (the call and the
# bundle or a saved recipe).

review_250_acl <- local({
  fit <- NULL
  function() {
    if (is.null(fit)) fit <<- run_acl(YTF_example, silent = TRUE)
    fit
  }
})

test_that("extract_estimates() gives lognormal intervals by default and Wald intervals on request", {
  skip_on_cran()
  fit <- review_250_acl()
  z <- qnorm(.975)
  ssb <- extract_estimates(fit, "SSB")
  usable <- is.finite(ssb$std_error)
  expect_true(any(usable))
  expect_equal(ssb$conf_low[usable], exp(log(ssb$estimate[usable]) - z * ssb$std_error[usable] / ssb$estimate[usable]))
  expect_equal(ssb$conf_high[usable], exp(log(ssb$estimate[usable]) + z * ssb$std_error[usable] / ssb$estimate[usable]))
  expect_true(all(ssb$conf_low[usable] > 0))
  expect_true(all(is.na(ssb$conf_low[!usable]) & is.na(ssb$conf_high[!usable])))
  wald <- extract_estimates(fit, "SSB", interval = "wald")
  expect_equal(wald$conf_low, wald$estimate - z * wald$std_error)
  expect_equal(wald$conf_high, wald$estimate + z * wald$std_error)
  expect_identical(wald$estimate, ssb$estimate)
  expect_identical(wald$std_error, ssb$std_error)
  # The level is that of conf_level in both forms.
  z90 <- qnorm(.95)
  narrow <- extract_estimates(fit, "SSB", conf_level = .9)
  expect_equal(narrow$conf_high[usable], ssb$estimate[usable] * exp(z90 * ssb$std_error[usable] / ssb$estimate[usable]))
  expect_error(extract_estimates(fit, "SSB", interval = "normal"), "should be one of")
  # Rows without a standard error keep NA bounds.
  fit$est_std <- NULL
  none <- extract_estimates(fit, "SSB")
  expect_true(all(is.na(none$conf_low) & is.na(none$conf_high)))
})

test_that("summarize_simulations() reports the coverage of the chosen interval form", {
  fit <- list(year = c(2000, 2001), report = list(SSB = c(11, 18)),
    est_std = cbind(Estimate = c(11, 18), `Std. Error` = c(1, 1)),
    opt = list(par = c(mean_log_R = 1), objective = 1), elapsed = 2,
    convergence_code = 0L, pdHess = TRUE, bound_hit = FALSE, max_abs_gradient = 0,
    diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE))
  rownames(fit$est_std) <- c("SSB", "SSB")
  target <- list(year = c(2000, 2001), SSB = c(10, 20))
  z <- qnorm(.975)
  # The former computation: 18 +/- 1.96 does not contain 20.
  wald <- summarize_simulations(list(one = fit), list(one = target), quantities = "SSB", interval = "wald")
  expect_equal(wald$estimates$conf_low, c(11, 18) - z)
  expect_equal(wald$estimates$conf_high, c(11, 18) + z)
  expect_identical(wald$estimates$covered, c(TRUE, FALSE))
  expect_equal(wald$summary$coverage, .5)
  # The lognormal interval 18 * exp(+/- 1.96 / 18) contains 20.
  lognormal <- summarize_simulations(list(one = fit), list(one = target), quantities = "SSB")
  expect_equal(lognormal$estimates$conf_low, c(11, 18) * exp(-z / c(11, 18)))
  expect_equal(lognormal$estimates$conf_high, c(11, 18) * exp(z / c(11, 18)))
  expect_identical(lognormal$estimates$covered, c(TRUE, TRUE))
  expect_equal(lognormal$summary$coverage, 1)
  expect_equal(lognormal$summary_converged$coverage, 1)
  # The bounds are those of the plots and of self_test().
  bounds <- ALSCL:::.acl_interval(c(11, 18), c(1, 1), "lognormal", z)
  expect_identical(lognormal$estimates$conf_low, bounds$lower)
  expect_identical(lognormal$estimates$conf_high, bounds$upper)
  expect_error(summarize_simulations(list(one = fit), list(one = target), quantities = "SSB",
                                     interval = "normal"), "should be one of")
})

# A small ALSCL bundle in the form of YTF_example: tables and settings in
# fit_args, parameters and map in fit_config$alscl. Only mean_log_R is
# estimated, so a fit is fast.
review_250_bundle <- function() {
  fx <- fit_fixture("ALSCL")
  tables <- c("data.CatL", "data.wgt", "data.mat")
  c(fx$input[tables], list(fit_args = fx$input[setdiff(names(fx$input), tables)],
    fit_config = list(alscl = list(parameters = fx$parameters, map = fx$map, nstarts = 1L))))
}

t0_note <- function(messages) sum(grepl("the supplied start log_t0", messages, fixed = TRUE))

test_that("the sources of t0_lower and log_t0 travel with the resolved arguments", {
  x <- YTF_example
  differ <- function(overrides) ALSCL:::.acl_t0_sources(ALSCL:::.acl_bundle_args(x, "alscl", overrides))
  # t0_lower in the call, log_t0 stored in the bundle.
  expect_true(differ(list(t0_lower = -1)))
  # log_t0 in the call, t0_lower stored in the bundle.
  x$fit_args$t0_lower <- -1
  expect_true(differ(list(parameters = list(log_t0 = 0))))
  # Both stored, or both in the call.
  expect_false(differ(list()))
  expect_false(differ(list(t0_lower = -2, parameters = list(log_t0 = 0))))
  # A list resolved earlier keeps its sources: a scenario that sets t0_lower
  # alone is the call, the parameters list stays stored.
  common <- ALSCL:::.acl_resolved_args(YTF_example, "alscl", list(M = 0.2))
  expect_false(ALSCL:::.acl_t0_sources(common))
  expect_true(ALSCL:::.acl_t0_sources(ALSCL:::.acl_resolved_args(common, "alscl", list(t0_lower = -1))))
  # A saved recipe is a flat list: both values are stored.
  recipe <- ALSCL:::.acl_bundle_args(YTF_example, "alscl")
  attr(recipe, "acl_t0_sources") <- NULL
  expect_false(ALSCL:::.acl_t0_sources(ALSCL:::.acl_bundle_args(recipe, "alscl")))
  expect_true(ALSCL:::.acl_t0_sources(ALSCL:::.acl_bundle_args(recipe, "alscl", list(t0_lower = -1))))
  # Arguments without sources (the form with data tables) do not differ.
  expect_false(ALSCL:::.acl_t0_sources(list(t0_lower = -1, parameters = list(log_t0 = 0))))
  # The supplied start is reported only when the sources differ; the
  # default start that cannot be converted is reported in both cases.
  expect_null(ALSCL:::.acl_t0_lower_start(-1, list(log_t0 = 0), "alscl", FALSE))
  expect_equal(ALSCL:::.acl_t0_lower_start(-1, list(log_t0 = 0), "alscl", TRUE), c(t0_lower = -1, log_t0 = 0))
  expect_identical(unname(ALSCL:::.acl_t0_lower_start(0.5, list(), "alscl", FALSE)[["log_t0"]]), NA_real_)
})

test_that("the note on log_t0 is given only when t0_lower and log_t0 come from different places", {
  skip_on_cran()
  x <- review_250_bundle()
  fit_messages <- function(...) testthat::capture_messages(suppressWarnings(run_alscl(...)))
  # t0_lower in the call, log_t0 = log(1/60) stored for t0_lower = 0.
  messages <- fit_messages(x, t0_lower = -1, silent = FALSE)
  expect_equal(t0_note(messages), 1L)
  expect_true(any(grepl("t0 = t0_lower + exp(log_t0) = -0.9833 years", messages, fixed = TRUE)))
  expect_silent(suppressWarnings(run_alscl(x, t0_lower = -1, silent = TRUE)))
  # Both stored, as in whiting_example.
  stored <- x
  stored$fit_args$t0_lower <- -1
  stored$fit_config$alscl$parameters$log_t0 <- log(1 + 1 / 60)
  expect_equal(t0_note(fit_messages(stored, silent = FALSE)), 0L)
  # log_t0 in the call and t0_lower stored.
  expect_equal(t0_note(fit_messages(stored, parameters = x$fit_config$alscl$parameters, silent = FALSE)), 1L)
  # Both in the call of a bundle, and both in the call with data tables.
  expect_equal(t0_note(fit_messages(x, t0_lower = -1, parameters = stored$fit_config$alscl$parameters,
                                    silent = FALSE)), 0L)
  direct <- c(x[c("data.CatL", "data.wgt", "data.mat")], x$fit_args,
              list(map = x$fit_config$alscl$map, parameters = stored$fit_config$alscl$parameters,
                   t0_lower = -1, nstarts = 1L, silent = FALSE))
  expect_equal(t0_note(testthat::capture_messages(suppressWarnings(do.call(run_alscl, direct)))), 0L)
  # A replayed recipe holds both values; a new t0_lower in refit_model() is the call.
  fit <- suppressWarnings(run_alscl(x, t0_lower = -1, silent = TRUE))
  expect_equal(t0_note(testthat::capture_messages(suppressWarnings(refit_model(fit, silent = FALSE)))), 0L)
  expect_equal(t0_note(testthat::capture_messages(suppressWarnings(
    refit_model(fit, t0_lower = -0.5, silent = FALSE)))), 1L)
  # A scenario that sets t0_lower alone is the call; one note for the batch.
  messages <- testthat::capture_messages(suppressWarnings(fit_scenarios(x,
    list(a = list(t0_lower = -1), b = list(t0_lower = -0.5)), model = "alscl", silent = FALSE)))
  expect_equal(t0_note(messages), 1L)
  messages <- testthat::capture_messages(suppressWarnings(fit_scenarios(stored,
    list(reference = list()), model = "alscl", silent = FALSE)))
  expect_equal(t0_note(messages), 0L)
  # The sources are internal: the returned settings do not carry them.
  z <- suppressWarnings(fit_scenarios(x, list(a = list(t0_lower = -1)), model = "alscl",
                                         silent = TRUE))
  expect_null(attr(z$settings$a, "acl_t0_sources"))
  expect_null(attr(z$fits$a$recipe$args, "acl_t0_sources"))
})

test_that("the note on a default log_t0 start that cannot be converted is unchanged", {
  skip_on_cran()
  x <- review_250_bundle()
  x$fit_config$alscl$parameters$log_t0 <- NULL
  default_note <- function(messages)
    sum(grepl("the default start of log_t0 means t0 = t0_lower + 1/60", messages, fixed = TRUE))
  messages <- testthat::capture_messages(suppressWarnings(run_alscl(x, t0_lower = 0.5, silent = FALSE)))
  expect_equal(default_note(messages), 1L)
  stored <- x
  stored$fit_args$t0_lower <- 0.5
  expect_equal(default_note(testthat::capture_messages(suppressWarnings(run_alscl(stored, silent = FALSE)))), 1L)
  expect_silent(suppressWarnings(run_alscl(stored, silent = TRUE)))
})

test_that("self_test() uses the interval of extract_estimates() and summarize_simulations()", {
  skip_on_cran()
  fit <- fit_fixture("ACL")$result
  z <- qnorm(.975)
  # Every refit returns the source fit with an SSB of zero in the first time
  # step and one whose lognormal upper bound overflows in the second.
  refit <- fit
  refit$obj <- NULL
  refit$report$SSB[1:2] <- c(0, 1e-300)
  ssb_rows <- which(rownames(refit$est_std) == "SSB")
  refit$est_std[ssb_rows[1:2], "Estimate"] <- c(0, 1e-300)
  refit$est_std[ssb_rows[1:2], "Std. Error"] <- c(2, 1)
  testthat::local_mocked_bindings(.acl_batch_apply = function(settings, model, ncores)
    lapply(settings, function(args) list(fit = refit, elapsed = 0, pid = 1L, warnings = character())),
    .package = "ALSCL")
  st <- self_test(fit, nsim = 1, seed = 1, quantities = "SSB")
  ssb <- st$series
  se <- unname(refit$est_std[ssb_rows, "Std. Error"])
  bounds <- ALSCL:::.acl_interval(refit$report$SSB, se, "lognormal", z)
  expect_identical(ssb$conf_low, bounds$lower)
  expect_identical(ssb$conf_high, bounds$upper)
  # The Wald bounds are kept, the lower bound stopped at zero, as in
  # extract_estimates() and summarize_simulations().
  expect_equal(ssb$conf_low[1:2], c(0, 0))
  expect_equal(ssb$conf_high[1:2], c(2 * z, 1e-300 + z))
  summary <- summarize_simulations(list(r = refit), list(r = list(year = fit$year,
    SSB = as.numeric(fit$report$SSB))), quantities = "SSB")
  expect_identical(summary$estimates$conf_low, ssb$conf_low)
  expect_identical(summary$estimates$conf_high, ssb$conf_high)
  # Positive estimates keep the lognormal bounds.
  rest <- -(1:2)
  expect_equal(ssb$conf_low[rest], refit$report$SSB[rest] * exp(-z * se[rest] / refit$report$SSB[rest]))
})
