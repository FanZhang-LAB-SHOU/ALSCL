test_that("simulation summaries count failures and only use available valid uncertainty", {
  fit <- list(year = c(2000, 2001), report = list(SSB = c(11, 18), Rec = c(2, 4)),
    est_std = cbind(Estimate = c(11, 18, 2, 4), `Std. Error` = c(1, 1, NA, 0)),
    opt = list(par = c(mean_log_R = 1), objective = 1), elapsed = 2,
    convergence_code = 0L, pdHess = TRUE, bound_hit = FALSE, max_abs_gradient = 0,
    diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE))
  rownames(fit$est_std) <- c("SSB", "SSB", "Rec", "Rec")
  invalid <- fit
  invalid$diagnostics$numerical_ok <- FALSE
  invalid$elapsed <- 4
  fits <- list(one = fit, two = invalid, three = list(error = "fit failed", elapsed = 6))
  target <- list(year = c(2000, 2001), SSB = c(10, 20), Rec = c(0, 4))
  truth <- list(three = target, one = target, two = target)
  z <- summarize_simulations(fits, truth)
  expect_equal(z$summary$n_replicates, c(3, 3))
  expect_equal(z$summary$n_valid_fits, c(1, 1))
  expect_equal(z$summary$n_points, c(6, 6))
  expect_equal(z$summary$n_valid_pairs, c(2, 2))
  expect_equal(z$summary$n_relative_pairs, c(2, 1))
  expect_equal(z$summary$bias, c(-.5, 1))
  expect_equal(z$summary$rmse, c(sqrt(2.5), sqrt(2)))
  expect_equal(z$summary$n_intervals, c(2, 1))
  expect_equal(z$summary$coverage, c(.5, 1))
  expect_equal(z$summary$failure_rate, c(2/3, 2/3))
  expect_equal(z$summary$mean_elapsed, c(4, 4))
  expect_identical(z$replicates$replicate, names(fits))
  expect_true(all(is.na(z$estimates$covered[z$estimates$replicate != "one"])))
  expect_true(all(is.na(z$estimates$estimate[z$estimates$replicate == "three"])))
  failed <- summarize_simulations(fits[3], truth["three"])
  expect_true(all(is.na(failed$summary$coverage)))
  expect_true(all(is.na(failed$summary$bias)))
  expect_error(summarize_simulations(fits, truth[-1]), "replicate names")
  wrong <- truth; wrong$one$year <- 2001:2002
  expect_error(summarize_simulations(fits, wrong), "time coordinates differ")
  wrong <- truth; wrong$one$SSB <- 1
  expect_error(summarize_simulations(fits, wrong), "match the time")
  expect_error(summarize_simulations(fits, truth, quantities = "F"), "time-series names")
})
