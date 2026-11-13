test_that("an ACL-only fit_config leaves ALSCL on the shared settings (F73)", {
  f <- fixture_frames()
  x <- prepare_alscl_data(f[c("data.CatL", "data.wgt", "data.mat")], fit_args = f[-(1:3)])
  x$fit_config$acl$map <- list(log_Linf = factor(NA))
  expect_identical(names(x$fit_config), "acl")
  checked <- check_alscl_data(x, "alscl")
  expect_true(checked$valid)
  expect_identical(checked$errors, character())
  expect_null(ALSCL:::.acl_bundle_args(x, "alscl")$map)
  expect_identical(ALSCL:::.acl_bundle_args(x, "acl")$map, list(log_Linf = factor(NA)))
  expect_identical(ALSCL:::.acl_bundle_args(x, "alscl"),
                   c(x[c("data.CatL", "data.wgt", "data.mat")], x$fit_args))
  # An entry of the wrong type is still rejected.
  x$fit_config$alscl <- 1
  expect_error(ALSCL:::.acl_bundle_args(x, "alscl"), "unique, non-empty names")
})

test_that("misplaced top-level fitting arguments of a structured bundle are reported (F38)", {
  f <- fixture_frames()
  x <- prepare_alscl_data(f[c("data.CatL", "data.wgt", "data.mat")], fit_args = f[-(1:3)])
  reference <- expect_no_warning(ALSCL:::.acl_bundle_args(x, "acl"))
  x$M <- 5
  x$map <- list(log_Linf = factor(NA))
  expect_warning(resolved <- ALSCL:::.acl_bundle_args(x, "acl"),
                 "top-level entries are not used in fitting: M, map. Move them into x\\$fit_args or x\\$fit_config\\$acl")
  # The documented rule is unchanged: the entries are not used.
  expect_identical(resolved, reference)
  expect_warning(checked <- check_alscl_data(x, "alscl"), "not used in fitting: M, map")
  expect_true(checked$valid)
  # Simulation settings and other metadata are not fitting arguments.
  y <- YTF_example
  expect_true("parameters" %in% names(y))
  expect_no_warning(ALSCL:::.acl_bundle_args(y, "acl"))
  expect_no_warning(ALSCL:::.acl_bundle_args(y, "alscl"))
  # A flat bundle has no fit_args, so every entry is a fitting argument.
  expect_no_warning(ALSCL:::.acl_bundle_args(c(f, list(map = NULL)), "acl"))
})

test_that("len_lower and len_upper are deprecated and do not block ACL (F72)", {
  ALSCL:::.acl_reset_deprecations()
  on.exit(ALSCL:::.acl_reset_deprecations(), add = TRUE)
  f <- fixture_frames()
  bins <- do.call(ALSCL:::.acl_prepare_data, f)$bins
  tables <- f[c("data.CatL", "data.wgt", "data.mat")]
  shared <- c(f[-(1:3)], list(len_lower = bins$lower, len_upper = bins$upper))
  expect_warning(x <- prepare_alscl_data(tables, fit_args = shared),
                 "'len_lower' and 'len_upper' are deprecated")
  # Once per session.
  expect_no_warning(prepare_alscl_data(tables, fit_args = shared))

  ALSCL:::.acl_reset_deprecations()
  expect_warning(acl <- ALSCL:::.acl_bundle_args(x, "acl"), "deprecated")
  expect_false(any(c("len_lower", "len_upper") %in% names(acl)))
  expect_true(check_alscl_data(x, "acl")$valid)
  alscl <- expect_no_warning(ALSCL:::.acl_bundle_args(x, "alscl"))
  expect_identical(alscl$len_lower, bins$lower)
  expect_true(check_alscl_data(x, "alscl")$valid)

  ALSCL:::.acl_reset_deprecations()
  expect_warning(prepare_alscl_data(tables, fit_args = f[-(1:3)],
    fit_config = list(alscl = list(len_upper = bins$upper))), "deprecated")
  expect_error(prepare_alscl_data(tables, fit_args = f[-(1:3)],
    fit_config = list(acl = list(len_upper = bins$upper))), "unknown arguments: len_upper")

  ALSCL:::.acl_reset_deprecations()
  mock <- run_alscl
  body(mock) <- quote(stop("fit reached"))
  local_mocked_bindings(run_alscl = mock, .package = "ALSCL")
  messages <- character()
  out <- withCallingHandlers(
    retro_model(nyear = 1, f$data.CatL, f$data.wgt, f$data.mat, f$rec.age, f$nage, f$M,
                f$sel_L50, f$sel_L95, model_type = "alscl", len_lower = bins$lower, silent = TRUE),
    warning = function(w) {
      messages <<- c(messages, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  expect_true(any(grepl("retro_model\\(\\): arguments 'len_lower' and 'len_upper' are deprecated", messages)))
})

test_that("profile_model reports the capped number of workers (F96)", {
  skip_on_cran()
  # Profiling needs a second free scalar: free one more parameter of the fixture.
  fx <- fit_fixture("ACL")
  mapping <- fx$map
  mapping$mean_log_F <- NULL
  two <- do.call(run_acl, c(fx$input, list(parameters = fx$parameters, map = mapping, silent = TRUE)))
  grid <- two$opt$par[["mean_log_R"]] + c(-.01, 0, .01)
  withr::local_envvar(`_R_CHECK_LIMIT_CORES_` = "TRUE")
  profile <- profile_model(two, "mean_log_R", grid, scale = "internal", ncores = 3)
  expect_identical(profile$workers, 2L)
  expect_lte(length(unique(profile$grid$pid)), 2L)
})
