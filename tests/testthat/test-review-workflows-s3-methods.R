test_that("vcov returns NULL for a nonfinite or indefinite covariance (GS5)", {
  skip_on_cran()
  fit <- fit_fixture("ACL")$result
  expect_identical(vcov(fit), fit$vcov)
  singular <- fit
  singular$vcov[] <- NaN
  singular$pdHess <- FALSE
  expect_null(vcov(singular))
  indefinite <- fit
  indefinite$vcov[] <- -abs(fit$vcov)
  expect_null(vcov(indefinite))
  absent <- fit
  absent["vcov"] <- list(NULL)
  expect_null(vcov(absent))
  # The stored matrix stays available for inspection.
  expect_true(all(is.nan(singular$vcov)))
  # extract_parameters keeps reporting missing uncertainty, never zero.
  expect_true(all(is.na(extract_parameters(singular)$std_error)))
})

test_that("fitted, logLik and nobs agree with residuals and the diagnostic metrics (GS9)", {
  skip_on_cran()
  fx <- fit_fixture("ACL")
  fit <- fx$result
  fitted_values <- ALSCL:::fitted.alscl_fit(fit)
  residual <- residuals(fit)
  expect_identical(fitted_values[c("year", "length", "length_label")],
                   residual[c("year", "length", "length_label")])
  expect_identical(fitted_values$fitted_log, residual$fitted_log)
  expect_error(ALSCL:::fitted.alscl_fit(fit, 1), "Unused")

  n <- ALSCL:::nobs.alscl_fit(fit)
  expect_identical(n, sum(residual$included))
  ll <- ALSCL:::logLik.alscl_fit(fit)
  expect_s3_class(ll, "logLik")
  expect_identical(as.numeric(ll), -as.numeric(fit$opt$objective))
  expect_identical(attr(ll, "df"), length(fit$opt$par))
  expect_identical(attr(ll, "nobs"), n)
  metrics <- diagnostic_metrics(fx$input$data.CatL, fit)
  expect_equal(stats::AIC(ll), metrics$Value[metrics$Metric == "AIC"], tolerance = 1e-12)
  expect_equal(stats::BIC(ll), metrics$Value[metrics$Metric == "BIC"], tolerance = 1e-12)

  # A portable result without observations still has a log-likelihood.
  bare <- fit
  bare$obj <- NULL
  bare$observations <- NULL
  expect_identical(attr(ALSCL:::logLik.alscl_fit(bare), "nobs"), NA_integer_)
  bare$opt$objective <- NA_real_
  expect_error(ALSCL:::logLik.alscl_fit(bare), "finite objective")
})

test_that("print passes digits to the tables (GS9)", {
  skip_on_cran()
  fit <- fit_fixture("ACL")$result
  full <- capture.output(print(fit))
  short <- capture.output(print(fit, digits = 3))
  expect_false(identical(full, short))
  expect_true(any(grepl("97.42387", full, fixed = TRUE)))
  expect_false(any(grepl("97.42387", short, fixed = TRUE)))
  expect_true(any(grepl("97.4", short, fixed = TRUE)))
})

test_that("failure records print the error and return NULL coefficients (GS9)", {
  record <- structure(list(converge = "FAILED", error = "t0 must be below the recruitment age.",
                           iter = 7L), class = c("alscl_fit_error", "list"))
  s <- ALSCL:::summary.alscl_fit_error(record)
  expect_s3_class(s, "summary.alscl_fit_error")
  expect_identical(s$error, record$error)
  expect_false(s$diagnostics$numerical_ok)
  expect_match(s$diagnostics$issues, "fit error: t0 must be below")
  expect_output(ALSCL:::print.alscl_fit_error(record), "Failed fit \\(replicate 7\\)")
  expect_output(ALSCL:::print.alscl_fit_error(record), "Error: t0 must be below")
  expect_null(ALSCL:::coef.alscl_fit_error(record))
  expect_null(ALSCL:::vcov.alscl_fit_error(record))
  no_message <- structure(list(converge = "FAILED"), class = c("alscl_fit_error", "list"))
  expect_output(ALSCL:::print.alscl_fit_error(no_message), "no error message was recorded")
})

test_that("extract_estimates marks terminal-period F and catch (F11)", {
  skip_on_cran()
  for (model in c("ACL", "ALSCL")) {
    fit <- fit_fixture(model)$result
    estimates <- extract_estimates(fit, c("SSB", "Rec", "B", "N", "CN", "F"))
    expect_identical(names(estimates)[1:11], c("quantity", "report_name", "year", "age",
      "length", "length_label", "estimate", "std_error", "conf_low", "conf_high", "numerical_ok"))
    expect_identical(names(estimates)[12L], "extrapolated")
    terminal <- estimates$year == max(fit$year)
    expect_true(all(estimates$extrapolated[terminal & estimates$quantity %in% c("CN", "F")]))
    expect_false(any(estimates$extrapolated[!terminal]))
    expect_false(any(estimates$extrapolated[estimates$quantity %in% c("SSB", "Rec", "B", "N")]))
    # The marked F is the AR(1) prediction from the preceding period.
    deviations <- fit$report$dev_log_F
    Y <- ncol(deviations)
    expect_equal(deviations[, Y], fit$report$phi_log_F_y * deviations[, Y - 1L], tolerance = 1e-8)
  }
  alscl <- fit_fixture("ALSCL")$result
  expect_false(any(extract_estimates(alscl, "FA")$extrapolated))
})
