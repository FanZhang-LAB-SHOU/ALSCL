projection_status_fixture <- function(model = "ACL") {
  report <- list(pla = matrix(rep(c(.25, .75), 3), 2, 3))
  if (model == "ACL") {
    report[["NA"]] <- matrix(c(10, 20, 30), 3, 1)
    report$F <- matrix(c(.1, .2, .3), 3, 1)
  } else {
    report$NLA <- array(seq_len(6) * 10, c(2, 3, 1))
    report$G <- matrix(c(.5, .5, 0, 1), 2, 2)
    report$FL <- matrix(c(.1, .3), 2, 1)
  }
  structure(list(report = report, model_type = model, len_mid = c(10, 20),
    len_label = c("5-15", "15-25"), age = 1:3, year = 2020,
    growth_step = 1, recipe = list(args = list(M = .2)),
    diagnostics = list(numerical_ok = TRUE)), class = c("alscl_fit", "list"))
}

project_status_fixture <- function(fit, ...) {
  project_model(fit, F = c(.1, .2), recruitment = c(5, 7),
    weight = matrix(2, 2, 2), maturity = matrix(.5, 2, 2), ...)
}

test_that("known failed fits require an explicit projection override", {
  for (model in c("ACL", "ALSCL")) {
    fit <- projection_status_fixture(model)
    reference <- project_status_fixture(fit)
    fit$diagnostics$numerical_ok <- FALSE
    expect_error(project_status_fixture(fit), "allow_failed_fit = TRUE", fixed = TRUE)
    expect_warning(exploratory <- project_status_fixture(fit, allow_failed_fit = TRUE),
      "source fit failed the numerical screen", fixed = TRUE)
    expect_false(exploratory$assumptions$source_fit_numerical_ok)
    expect_identical(exploratory$assumptions$source_fit_status, "failed")
    expect_true(exploratory$assumptions$failed_fit_override)
    expect_identical(exploratory$summary, reference$summary)
    expect_identical(exploratory$states, reference$states)
    expect_identical(exploratory$catch, reference$catch)
  }
})

test_that("passing numerical screens preserve projection calculations", {
  for (model in c("ACL", "ALSCL")) {
    fit <- projection_status_fixture(model)
    expect_no_warning(ordinary <- project_status_fixture(fit))
    expect_no_warning(permissive <- project_status_fixture(fit, allow_failed_fit = TRUE))
    expect_identical(ordinary, permissive)
    expect_true(ordinary$assumptions$source_fit_numerical_ok)
    expect_identical(ordinary$assumptions$source_fit_status, "passed")
    expect_false(ordinary$assumptions$failed_fit_override)
  }
})

test_that("legacy numerical status remains unknown rather than passing", {
  for (model in c("ACL", "ALSCL")) {
    fit <- projection_status_fixture(model)
    reference <- project_status_fixture(fit)
    fit$diagnostics <- NULL
    expect_no_warning(legacy <- project_status_fixture(fit))
    expect_null(legacy$assumptions$source_fit_numerical_ok)
    expect_identical(legacy$assumptions$source_fit_status, "unknown")
    expect_false(legacy$assumptions$failed_fit_override)
    expect_identical(legacy$summary, reference$summary)
    fit$diagnostics <- list(numerical_ok = NA)
    expect_no_warning(unknown <- project_status_fixture(fit))
    expect_identical(unknown$assumptions$source_fit_numerical_ok, NA)
    expect_identical(unknown$assumptions$source_fit_status, "unknown")
    expect_false(unknown$assumptions$failed_fit_override)
    expect_identical(unknown$summary, reference$summary)
  }
})

test_that("failed-fit protection survives saving and reloading report-only fits", {
  fit <- projection_status_fixture()
  fit$diagnostics$numerical_ok <- FALSE
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  restored <- readRDS(path)
  expect_error(project_status_fixture(restored), "source fit failed the numerical screen", fixed = TRUE)
  expect_warning(p <- project_status_fixture(restored, allow_failed_fit = TRUE),
    "allow_failed_fit = TRUE", fixed = TRUE)
  expect_true(p$assumptions$failed_fit_override)
})

test_that("projection override requires one nonmissing logical value", {
  fit <- projection_status_fixture()
  for (value in list(NULL, logical(), NA, c(TRUE, FALSE), 1, "TRUE")) {
    expect_error(project_status_fixture(fit, allow_failed_fit = value),
      "allow_failed_fit must be TRUE or FALSE", fixed = TRUE)
  }
})
