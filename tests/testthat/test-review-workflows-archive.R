legacy_bundle <- function(fx) c(fx$input, list(parameters = fx$parameters, map = fx$map))

test_that("print and summary work when the stored inputs fail the current input checks (GS1)", {
  skip_on_cran()
  fit <- fit_fixture("ALSCL")$result
  reference <- summary(fit)
  # Release 2.4.3 accepted a named NULL release for a parameter of the other model.
  old <- fit
  old$recipe$args$map["t0"] <- list(NULL)
  expect_error(inspect_parameters(old$recipe$args, "alscl"), "Unknown map parameter")
  expect_output(print(old), "ALSCL assessment")
  expect_identical(summary(old)$parameters, reference$parameters)
  expect_identical(extract_parameters(old), extract_parameters(fit))
  # A named NULL release of a parameter that the model has still changes the status.
  expect_identical(nrow(extract_parameters(old)), 15L)

  # refit_model() drops the ignored entry, so the stored recipe still refits.
  seen <- NULL
  mock <- run_alscl
  body(mock) <- quote({
    seen <<- map
    "refitted"
  })
  environment(mock) <- environment()
  local_mocked_bindings(run_alscl = mock, .package = "ALSCL")
  expect_identical(refit_model(old), "refitted")
  expect_identical(seen, fit$recipe$args$map)
  expect_false("t0" %in% names(seen))

  # Any other rejected input gives the estimated parameters and states the reason.
  broken <- fit
  broken$recipe$args$rec.age <- -1
  expect_warning(table <- extract_parameters(broken), "rec.age")
  expect_identical(table$parameter, names(fit$opt$par))
  expect_identical(table$status, rep("estimated", length(fit$opt$par)))
  expect_match(attr(table, "inspection_error"), "rec.age")
  summary_broken <- expect_no_warning(summary(broken))
  expect_match(summary_broken$notes, "rec.age")
  expect_output(print(broken), "Fixed parameters are not listed")
  expect_null(reference$notes)
})

test_that("a fit without stored diagnostics has one numerical-screen verdict (GS2)", {
  skip_on_cran()
  fx <- fit_fixture("ACL")
  legacy <- unclass(fx$result)
  legacy[c("recipe", "diagnostics")] <- NULL
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  save_assessment(legacy, path, x = legacy_bundle(fx))
  old <- read_assessment(path)
  s <- summary(old)
  expect_true(s$diagnostics$numerical_ok)
  expect_identical(unique(s$parameters$numerical_ok), s$diagnostics$numerical_ok)
  expect_identical(unique(extract_parameters(old)$numerical_ok), s$diagnostics$numerical_ok)
  expect_identical(unique(extract_estimates(old, "SSB")$numerical_ok), s$diagnostics$numerical_ok)

  # A stored failed screen stays failed everywhere.
  failed <- fx$result
  failed$diagnostics$numerical_ok <- FALSE
  expect_false(summary(failed)$diagnostics$numerical_ok)
  expect_false(any(extract_parameters(failed)$numerical_ok))
  expect_false(any(extract_estimates(failed, "SSB")$numerical_ok))

  # The Hessian failure is named once.
  bad <- fx$result
  bad$pdHess <- FALSE
  bad$diagnostics <- ALSCL:::.acl_fit_diagnostics(bad)
  issues <- strsplit(ALSCL:::.acl_fit_status(bad)$issues, "; ", fixed = TRUE)[[1L]]
  expect_identical(sum(grepl("Hessian", issues)), 1L)
  legacy_bad <- unclass(fx$result)
  legacy_bad$diagnostics <- NULL
  legacy_bad$pdHess <- NA
  expect_identical(sum(grepl("Hessian",
    strsplit(ALSCL:::.acl_fit_status(legacy_bad)$issues, "; ", fixed = TRUE)[[1L]])), 1L)
})

test_that("save_assessment(x = ) keeps observations and time metadata of an older fit (GS3)", {
  skip_on_cran()
  fx <- fit_fixture("ACL")
  legacy <- unclass(fx$result)
  legacy[c("recipe", "diagnostics", "observations", "year", "F_structure")] <- NULL
  # The live TMB object is the only copy of the observations.
  expect_no_error(residuals.alscl_fit(c(legacy, list(year = fx$result$year))))
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  save_assessment(legacy, path, x = legacy_bundle(fx))
  old <- read_assessment(path)
  expect_null(old$obj)
  expect_identical(old$observations, fx$result$observations)
  expect_identical(old$year, fx$result$year)
  expect_identical(old$F_structure, "group_year")
  expect_match(old$recipe$provenance, "unverified")
  expect_match(old$recipe$provenance, "matched the data in the fitted TMB object")
  expect_match(old$recipe$provenance, "Fields taken from x: year, F_structure")
  out <- expect_no_warning(capture.output(print(old)))
  expect_false(any(grepl("Inf", out, fixed = TRUE)))
  expect_equal(residuals(old)$residual, residuals(fx$result)$residual, tolerance = 1e-12)
  expect_identical(extract_estimates(old, "SSB")$estimate,
                   extract_estimates(fx$result, "SSB")$estimate)
  expect_s3_class(check_fit(old)$plots$qq, "ggplot")

  # Observations that differ from the data in the live object are rejected.
  other <- legacy_bundle(fx)
  other$data.CatL[2L, 2L] <- other$data.CatL[2L, 2L] * 1.01
  expect_error(save_assessment(legacy, tempfile(fileext = ".rds"), x = other),
               "does not match the observations in the fitted TMB object")

  # Without a live object the observations come from x and this is recorded.
  detached <- legacy
  detached$obj <- NULL
  path2 <- tempfile(fileext = ".rds")
  on.exit(unlink(path2), add = TRUE)
  save_assessment(detached, path2, x = legacy_bundle(fx))
  expect_match(read_assessment(path2)$recipe$provenance, "could not be compared")
  expect_identical(read_assessment(path2)$observations, fx$result$observations)

  # A stored field is never replaced, and a current fit is saved unchanged.
  path3 <- tempfile(fileext = ".rds")
  on.exit(unlink(path3), add = TRUE)
  save_assessment(fx$result, path3)
  current <- read_assessment(path3)
  reference <- fx$result
  reference$obj <- NULL
  expect_identical(unclass(current), unclass(reference))
})

test_that("summary reports missing time labels as NA", {
  skip_on_cran()
  fit <- fit_fixture("ACL")$result
  fit$year <- NULL
  fit$F_structure <- NULL
  s <- expect_no_warning(summary(fit))
  expect_identical(s$periods, c(NA_real_, NA_real_))
  expect_output(print(s), "F structure: not recorded")
})

test_that("archives use serialization version 3 and keep non-ASCII labels (F93)", {
  skip_on_cran()
  fit <- fit_fixture("ACL")$result
  fit$note <- "café 体长"
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  save_assessment(fit, path)
  expect_identical(infoRDS(path)$version, 3L)
  saved <- read_assessment(path)
  expect_identical(saved$note, fit$note)
  expect_true(validUTF8(saved$note))
})
