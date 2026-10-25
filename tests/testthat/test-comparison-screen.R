comparison_fixture <- function() {
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

test_that("comparison preference requires numerical screens and matching observations", {
  f <- comparison_fixture(); a <- f$model; b <- a
  b$opt$objective <- 20
  output <- capture.output(x <- compare_models(a, b, f$data, "first", "second"))
  expect_true(x$comparison$eligible)
  expect_identical(x$comparison$preferred, "first")
  expect_true(all(x$fit_diagnostics$numerical_ok))
  # Successful refinement may retain a nonzero raw optimizer code.
  a$convergence_code <- 1L
  capture.output(x <- compare_models(a, b, f$data))
  expect_true(x$comparison$eligible)
  # A lower objective never overrides a failed Hessian/gradient screen.
  a$pdHess <- FALSE; a$gradient <- .1
  expect_warning(output <- capture.output(x <- compare_models(a, b, f$data)),
                 "Automatic model preference withheld")
  expect_false(x$comparison$eligible)
  expect_null(x$comparison$preferred)
  expect_false(any(grepl("has lower AIC", output)))
  expect_true("AIC" %in% x$summary$Metric)
  expect_false(x$fit_diagnostics$numerical_ok[1])
  a <- f$model; a$diagnostics$natural_boundary <- TRUE
  expect_warning(capture.output(x <- compare_models(a, b, f$data)), "withheld")
  expect_false(x$comparison$eligible)
})

test_that("comparisons reject data, period, bin and mask mismatches", {
  f <- comparison_fixture(); m <- f$model
  d <- f$data; names(d)[-1L] <- as.character(1900:1904)
  expect_error(compare_models(m, m, d), "time columns")
  d <- f$data; d[[1L]] <- rev(d[[1L]])
  expect_error(compare_models(m, m, d), "length labels/order")
  d <- f$data; d[1, 2] <- NA_real_
  expect_error(compare_models(m, m, d), "observation mask")
  d <- f$data; d[1, 2] <- d[1, 2] + 1
  expect_error(compare_models(m, m, d), "observation values")
  expect_error(compare_models(m, m, d[-1, ]), "prediction dimensions")
  d <- f$data; d[1, 2] <- NA_real_
  m$observations[1, 1] <- 0
  # Zero and NA are the same excluded cell under the observation likelihood.
  capture.output(x <- compare_models(m, m, d))
  expect_true(x$comparison$data_verified)
})

test_that("legacy fits retain raw comparison tables without claiming verified comparability", {
  f <- comparison_fixture(); m <- f$model; m$observations <- NULL
  expect_warning(capture.output(x <- compare_models(m, m, f$data)),
                 "original observations unavailable")
  expect_false(x$comparison$data_verified)
  expect_null(x$comparison$preferred)
  expect_true("AIC" %in% x$summary$Metric)
  failed <- .acl_fit_status(NULL, "optimizer failed")
  expect_false(failed$numerical_ok)
  expect_match(failed$issues, "optimizer failed")
  m$diagnostics <- NULL; m$vcov <- matrix(1, 1, 1)
  expect_true(.acl_fit_status(m)$numerical_ok)
  m$vcov <- NULL
  expect_false(.acl_fit_status(m)$numerical_ok)
})

test_that("comparison accepts core-normalized labels and matrices with distinct default names", {
  f <- comparison_fixture(); a <- b <- f$model
  f$data[[1L]] <- paste0(" ", f$data[[1L]], " ")
  a$F_structure <- "group_year"; b$F_structure <- "year"
  capture.output(x <- compare_models(a, b, as.matrix(f$data)))
  expect_true(x$comparison$eligible)
  expect_identical(x$model1_name, "ACL (group_year)")
  expect_identical(x$model2_name, "ACL (year)")
  b$year[1L] <- NA_real_
  expect_error(compare_models(a, b, f$data), "time columns")
})

test_that("a missing parameter count cannot win a comparison as a zero-parameter model", {
  f <- comparison_fixture(); a <- b <- f$model
  a$opt$par <- NULL
  expect_warning(capture.output(x <- compare_models(a, b, f$data)), "withheld")
  expect_false(x$comparison$eligible)
  expect_null(x$comparison$preferred)
  expect_match(x$fit_diagnostics$issues[1L], "parameter count unavailable")
  expect_true(is.na(diagnostic_metrics(f$data, a)$Value[
    diagnostic_metrics(f$data, a)$Metric == "AIC"]))
  a$obj <- list(par = b$opt$par)
  capture.output(x <- compare_models(a, b, f$data))
  expect_true(x$comparison$eligible)
})
