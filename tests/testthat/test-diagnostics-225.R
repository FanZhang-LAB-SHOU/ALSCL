diagnostic_fixture_225 <- function() {
  observed <- matrix(c(10, 20, 12, 22, 14, 24), 2, 3)
  errors <- matrix(c(1, -1, 2, -2, 3, -3), 2, 3)
  data <- data.frame(LengthBin = c("10", "20"), observed, check.names = FALSE)
  names(data)[-1L] <- as.character(2000:2002)
  fit <- list(model_type = "ACL", year = 2000:2002,
    len_label = data$LengthBin, observations = observed,
    report = list(Elog_index = log(observed - errors)),
    opt = list(par = c(mean_log_R = 1), objective = 10, convergence = 0L),
    convergence_code = 0L, converge = "converged", pdHess = TRUE,
    bound_hit = FALSE, gradient = 1e-8,
    diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE,
      covariance_condition = 1, high_correlations = data.frame(), issues = character()),
    refinement = list(status = "not needed"))
  list(data = data, fit = fit)
}

test_that("in-sample diagnostics reject known coordinate and observation mismatches", {
  f <- diagnostic_fixture_225()
  for (fun in list(diagnostic_metrics, diagnose_model)) {
    expect_error(fun(f$data[, c(1, 4, 3, 2)], f$fit), "time columns")
    expect_error(fun(f$data[2:1, ], f$fit), "length labels/order")
    changed <- f$data; changed[1, 2] <- NA_real_
    expect_error(fun(changed, f$fit), "observation mask")
    changed <- f$data; changed[1, 2] <- changed[1, 2] + 1
    expect_error(fun(changed, f$fit), "observation values")
    expect_error(fun(f$data[-1, ], f$fit), "dimensions differ")
  }
  # Character matrices and the normalization accepted by the fitting entry
  # points remain valid; no reordering is performed silently.
  normalized <- f$data
  normalized[[1L]] <- paste0(" ", normalized[[1L]], " ")
  names(normalized)[-1L] <- paste0("X", names(normalized)[-1L])
  expect_equal(diagnostic_metrics(as.matrix(normalized), f$fit),
               diagnostic_metrics(f$data, f$fit))
})

test_that("shared diagnostic arithmetic preserves metrics and excludes masked cells", {
  f <- diagnostic_fixture_225()
  measured <- diagnostic_metrics(f$data, f$fit)
  value <- setNames(measured$Value, measured$Metric)
  expected_names <- c("MSE", "MAE", "MAD", "MASE", "RMSE", "Rsquared", "MAPE",
    "SMAPE", "Explained Variance Score", "Max Error", "AIC", "BIC")
  expect_identical(measured$Metric, expected_names)
  expect_equal(value[["MSE"]], 28 / 6)
  expect_equal(value[["MAE"]], 2)
  expect_equal(value[["MASE"]], 1)
  expect_equal(value[["RMSE"]], sqrt(28 / 6))
  expect_equal(value[["Rsquared"]], 1 - 28 / sum((f$fit$observations - 17)^2))
  expect_equal(value[["AIC"]], 22)
  expect_equal(value[["BIC"]], log(6) + 20)

  f$data[1, 2] <- NA_real_; f$data[2, 3] <- 0
  f$fit$observations[1, 1] <- 0; f$fit$observations[2, 2] <- NA_real_
  # NA and zero are both excluded from the lognormal observation likelihood.
  f$fit$report$Elog_index[1, 1] <- Inf
  f$fit$report$Elog_index[2, 2] <- NA_real_
  expect_no_warning(measured <- diagnostic_metrics(f$data, f$fit))
  capture.output(compared <- compare_models(f$fit, f$fit, f$data, "A", "B"))
  expect_true(compared$comparison$data_verified)
  keys <- c(MSE = "MSE", RMSE = "RMSE", MAE = "MAE", R2 = "Rsquared",
            MAPE = "MAPE", SMAPE = "SMAPE")
  for (key in names(keys)) {
    expected <- measured$Value[measured$Metric == keys[[key]]]
    expect_equal(compared$fit_metrics$A[compared$fit_metrics$Metric == key],
                 round(expected, 4))
  }
})

test_that("comparison uses undefined R-squared and rejects response-scale overflow", {
  f <- diagnostic_fixture_225()
  f$data[-1L] <- 10; f$fit$observations[,] <- 10
  f$fit$report$Elog_index[,] <- log(11)
  measured <- diagnostic_metrics(f$data, f$fit)
  expect_true(is.na(measured$Value[measured$Metric == "Rsquared"]))
  expect_true(is.na(measured$Value[measured$Metric == "MASE"]))
  capture.output(compared <- compare_models(f$fit, f$fit, f$data, "A", "B"))
  expect_true(is.na(compared$fit_metrics$A[compared$fit_metrics$Metric == "R2"]))
  expect_true(is.na(compared$fit_metrics$B[compared$fit_metrics$Metric == "R2"]))
  expect_equal(compared$fit_metrics$A[compared$fit_metrics$Metric == "RMSE"], 1)

  for (bad in c(Inf, NA_real_, 1000)) {
    f$fit$report$Elog_index[1, 1] <- bad
    expect_error(diagnostic_metrics(f$data, f$fit), "Predictions are non-finite")
    expect_error(diagnose_model(f$data, f$fit), "Predictions are non-finite")
    expect_error(compare_models(f$fit, f$fit, f$data), "nonfinite predictions")
  }
})

test_that("finite log residuals survive response-scale underflow", {
  f <- diagnostic_fixture_225()
  f$fit$report$Elog_index[,] <- -1000 + seq_len(6)
  capture.output(compared <- compare_models(f$fit, f$fit, f$data, "A", "B"))
  expected <- stats::sd(log(f$fit$observations) - f$fit$report$Elog_index)
  expect_equal(compared$fit_metrics$A[compared$fit_metrics$Metric == "SD_log_resid"],
               round(expected, 4))
  expect_true(all(is.finite(compared$fit_metrics$A)))
})

test_that("legacy metadata is optional but cannot override known mismatches", {
  f <- diagnostic_fixture_225()
  original <- diagnostic_metrics(f$data, f$fit)
  f$fit$year <- f$fit$len_label <- f$fit$observations <- NULL
  expect_no_warning(measured <- diagnostic_metrics(f$data, f$fit))
  expect_equal(measured, original)
  expect_warning(capture.output(compared <- compare_models(f$fit, f$fit, f$data)),
                 "Automatic model preference withheld")
  expect_false(compared$comparison$data_verified)
  expect_false(compared$comparison$eligible)
  expect_null(compared$comparison$preferred)
  f$fit$year <- 1990:1992
  expect_error(diagnostic_metrics(f$data, f$fit), "time columns")
  f$fit$year <- NULL
  f$fit$opt$par <- f$fit$opt$objective <- NULL
  measured <- diagnostic_metrics(f$data, f$fit)
  expect_true(all(is.na(measured$Value[measured$Metric %in% c("AIC", "BIC")])))
  expect_identical(tail(measured$Metric, 2), c("AIC", "BIC"))
})

test_that("diagnostic observations reject invalid numeric cells before scoring", {
  f <- diagnostic_fixture_225()
  for (bad in list(-1, Inf, "not a number")) {
    changed <- f$data; changed[1, 2] <- bad
    expect_error(diagnostic_metrics(changed, f$fit), "numeric, nonnegative and finite")
    expect_error(compare_models(f$fit, f$fit, changed), "numeric, nonnegative and finite")
  }
})
