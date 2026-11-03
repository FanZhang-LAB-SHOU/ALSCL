test_that("mixed time-column types retain native numeric precision and masks", {
  withr::local_options(digits = 3L)
  x <- fixture_frames()
  x$data.CatL[[2L]] <- seq_len(nrow(x$data.CatL)) + .123456789012345
  x$data.CatL[[2L]][1:2] <- c(NA_real_, 0)
  x$data.wgt[[2L]] <- seq_len(nrow(x$data.wgt)) + .123456789012345
  x$data.mat[[2L]] <- seq_len(nrow(x$data.mat)) / 10 + .0123456789012345
  expected <- do.call(.acl_prepare_data, x)
  for (field in c("data.CatL", "data.wgt", "data.mat")) {
    x[[field]][[3L]] <- sprintf("%.17g", x[[field]][[3L]])
    values <- sprintf("%.17g", x[[field]][[4L]])
    x[[field]][[4L]] <- factor(values, levels = rev(unique(values)))
  }
  prepared <- do.call(.acl_prepare_data, x)
  expect_identical(prepared$observations, expected$observations)
  expect_identical(prepared$data, expected$data)
  survey <- .acl_survey_data(x$data.CatL)
  expect_identical(survey$observed, unname(expected$observations))
  expect_identical(survey$mask, unname(expected$data$na_matrix == 1))
  tables <- c("data.CatL", "data.wgt", "data.mat")
  bundle <- prepare_alscl_data(x[tables], fit_args = x[setdiff(names(x), tables)])
  for (model in c("acl", "alscl")) {
    direct <- .acl_preflight(x, model)
    normalized <- .acl_preflight(bundle, model)
    expect_identical(direct$prepared$data, normalized$prepared$data)
    expect_identical(direct$setup$parameters, normalized$setup$parameters)
  }
})

test_that("mixed numeric text does not change actual fits or their diagnostics", {
  for (model in c("ACL", "ALSCL")) {
    fixture <- fit_fixture(model)
    input <- fixture$input
    input$data.CatL[[3L]] <- sprintf("%.17g", input$data.CatL[[3L]])
    values <- sprintf("%.17g", input$data.CatL[[4L]])
    input$data.CatL[[4L]] <- factor(values, levels = rev(unique(values)))
    fit <- do.call(if (model == "ACL") run_acl else run_alscl,
      c(input, list(parameters = fixture$parameters, map = fixture$map, silent = TRUE)))
    # Native columns must stay exact. Decimal text may differ by one binary
    # rounding unit after parsing, so compare those columns at machine scale.
    expect_identical(fit$observations[, c(1L, 4L, 5L)],
      fixture$result$observations[, c(1L, 4L, 5L)])
    expect_equal(fit$observations, fixture$result$observations, tolerance = 1e-14)
    expect_equal(fit$report$SSB, fixture$result$report$SSB, tolerance = 1e-12)
    expect_equal(fit$report$FL, fixture$result$report$FL, tolerance = 1e-12)
    expect_equal(diagnostic_metrics(input$data.CatL, fixture$result),
      diagnostic_metrics(fixture$input$data.CatL, fixture$result), tolerance = 1e-12)
    expect_no_error(capture.output(compared <- compare_models(fixture$result, fit,
      input$data.CatL, "Numeric", "Mixed")))
    expect_true(compared$comparison$data_verified)
  }
})

test_that("complex cells are rejected before fitting or diagnostic conversion", {
  local_mocked_bindings(.acl_compile = function(...) stop("must not compile"))
  for (field in c("data.CatL", "data.wgt", "data.mat")) {
    input <- fixture_frames()
    input[[field]][[2L]] <- input[[field]][[2L]] + 5i
    for (fun in list(run_acl, run_alscl))
      expect_error(fun(input), "real values are required")
    if (field == "data.CatL")
      expect_error(.acl_survey_data(input$data.CatL), "real values are required")
  }
})
