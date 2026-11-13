test_that("simulation summaries also report all converged fits and failure reasons (GL4)", {
  fit <- list(year = c(2000, 2001), report = list(SSB = c(11, 18), Rec = c(2, 4)),
    est_std = cbind(Estimate = c(11, 18, 2, 4), `Std. Error` = c(1, 1, NA, 0)),
    opt = list(par = c(mean_log_R = 1), objective = 1), elapsed = 2,
    convergence_code = 0L, pdHess = TRUE, bound_hit = FALSE, max_abs_gradient = 0,
    diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE))
  rownames(fit$est_std) <- c("SSB", "SSB", "Rec", "Rec")
  # Converged, but an estimated correlation sits at its natural-scale boundary.
  boundary <- fit
  boundary$report$SSB <- c(12, 23)
  boundary$diagnostics <- list(numerical_ok = FALSE, natural_boundary = TRUE)
  # Not converged: large gradient and a Hessian that is not positive definite.
  unconverged <- fit
  unconverged$max_abs_gradient <- 5
  unconverged$pdHess <- FALSE
  unconverged$diagnostics <- list(numerical_ok = FALSE, natural_boundary = FALSE)
  failed <- structure(list(converge = "FAILED", error = "fit failed", elapsed = 6),
                      class = c("alscl_fit_error", "list"))
  fits <- list(one = fit, two = boundary, three = unconverged, four = failed)
  target <- list(year = c(2000, 2001), SSB = c(10, 20), Rec = c(0, 4))
  truth <- list(one = target, two = target, three = target, four = target)
  z <- summarize_simulations(fits, truth)

  # The existing summary keeps its columns and values: one valid fit of four.
  expect_identical(names(z$summary), c("quantity", "n_replicates", "n_valid_fits", "failure_rate",
    "n_points", "n_valid_pairs", "n_relative_pairs", "n_intervals", "bias", "relative_bias",
    "rmse", "coverage", "mean_elapsed"))
  expect_equal(z$summary$n_valid_fits, c(1, 1))
  expect_equal(z$summary$failure_rate, c(.75, .75))
  expect_equal(z$summary$bias, c(-.5, 1))
  expect_equal(z$summary$coverage, c(.5, 1))

  # Converged fits: replicates one and two.
  expect_identical(z$replicates$converged, c(TRUE, TRUE, FALSE, FALSE))
  expect_identical(z$summary_converged$quantity, c("SSB", "Rec"))
  expect_equal(z$summary_converged$n_converged_fits, c(2, 2))
  expect_equal(z$summary_converged$n_valid_pairs, c(4, 4))
  expect_equal(z$summary_converged$bias, c(mean(c(1, -2, 2, 3)), 1))
  expect_equal(z$summary_converged$rmse, c(sqrt(mean(c(1, 4, 4, 9))), sqrt(2)))
  expect_equal(z$summary_converged$n_intervals, c(4, 2))
  expect_equal(z$summary_converged$coverage, c(.25, 1))
  expect_identical(z$estimates$converged, rep(c(TRUE, TRUE, FALSE, FALSE), each = 4))
  expect_true(all(is.na(z$estimates$covered_converged[!z$estimates$converged])))
  # Coverage of valid fits is unchanged by the new columns.
  expect_identical(z$estimates$covered[z$estimates$replicate == "one"],
                   z$estimates$covered_converged[z$estimates$replicate == "one"])

  # Failure reasons: every failed replicate is counted under each of its reasons.
  expect_identical(z$replicates$failure_reasons, c("", "natural-scale boundary",
    "large or nonfinite gradient; Hessian unavailable or not positive definite", "fit error"))
  counts <- stats::setNames(z$failures$n_replicates, z$failures$reason)
  sole <- stats::setNames(z$failures$n_sole, z$failures$reason)
  expect_identical(unname(counts[c("fit error", "large or nonfinite gradient",
    "Hessian unavailable or not positive definite", "optimizer-scale boundary",
    "natural-scale boundary", "other")]), c(1L, 1L, 1L, 0L, 1L, 0L))
  expect_identical(unname(sole[c("fit error", "large or nonfinite gradient",
    "natural-scale boundary")]), c(1L, 0L, 1L))
  expect_equal(sum(z$replicates$failure_reasons != ""), sum(!z$replicates$numerical_ok))
})
