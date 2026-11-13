review_comparison_fixture <- function() {
  d <- fixture_frames()$data.CatL
  observed <- as.matrix(d[-1L])
  m <- list(model_type = "ACL", year = 2000:2004,
    len_label = as.character(d[[1L]]), observations = observed,
    report = list(Elog_index = log(observed)),
    opt = list(par = c(mean_log_R = 1), objective = 10, convergence = 0L),
    convergence_code = 0L, converge = "converged", pdHess = TRUE,
    bound_hit = FALSE, gradient = 1e-8, max_abs_gradient = 1e-8,
    diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE,
                       issues = character()))
  list(data = d, model = m)
}

test_that("compare_models records why a preference is withheld (F55)", {
  f <- review_comparison_fixture(); a <- f$model; b <- a
  # Equal AIC: both fits are eligible, no preference, and the reason is recorded.
  output <- capture.output(x <- compare_models(a, b, f$data, "first", "second"))
  expect_true(x$comparison$eligible)
  expect_null(x$comparison$preferred)
  expect_identical(x$comparison$issues, character())
  expect_identical(x$comparison$delta_aic, 0)
  expect_identical(x$comparison$aic_threshold, 2)
  expect_identical(x$comparison$reason, "absolute AIC difference below 2")
  expect_true(any(grepl("little separation in AIC", output)))

  # The rule itself is unchanged: a difference of 2 or more names the lower AIC.
  b$opt$objective <- 10.999
  capture.output(x <- compare_models(a, b, f$data, "first", "second"))
  expect_null(x$comparison$preferred)
  expect_equal(x$comparison$delta_aic, 1.998)
  b$opt$objective <- 11
  capture.output(x <- compare_models(a, b, f$data, "first", "second"))
  expect_identical(x$comparison$preferred, "first")
  expect_identical(x$comparison$delta_aic, 2)
  expect_identical(x$comparison$reason, NA_character_)
  b$opt$objective <- 5
  capture.output(x <- compare_models(a, b, f$data, "first", "second"))
  expect_identical(x$comparison$preferred, "second")
  expect_identical(x$comparison$delta_aic, -10)

  # A failed screen keeps its explanation in issues.
  a$pdHess <- FALSE
  expect_warning(capture.output(x <- compare_models(a, b, f$data, "first", "second")), "withheld")
  expect_null(x$comparison$preferred)
  expect_match(x$comparison$issues, "numerical screen failed: first")
  expect_match(x$comparison$reason, "see issues")
})

test_that("a failure record is reported as a failed fit, not as a data mismatch (F91)", {
  f <- review_comparison_fixture()
  failed <- list(converge = "FAILED", error = "t0 must be below the recruitment age.")
  expect_error(compare_models(f$model, failed, f$data),
               "Model 2 is a failed fit without estimates.*Fit error: t0 must be below")
  expect_error(compare_models(failed, f$model, f$data), "Model 1 is a failed fit")
  classed <- structure(failed, class = c("alscl_fit_error", "list"))
  expect_error(compare_models(f$model, classed, f$data), "Model 2 is a failed fit")
  expect_error(diagnostic_metrics(f$data, failed), "model_result is a failed fit")
  # A genuine dimension mismatch keeps its message.
  expect_error(compare_models(f$model, f$model, f$data[-1L, ]), "prediction dimensions")
  expect_error(diagnostic_metrics(f$data[-1L, ], f$model), "dimensions differ")
})
