random_fixture <- function(model) {
  x <- cpp_fixture(model)
  obj <- TMB::MakeADFun(x$data, x$parameters, random = c("dev_log_R", "dev_log_F", "dev_log_N0"),
                        DLL = x$info$dll_name, silent = TRUE)
  obj$fn(obj$par)  # sets last.par.best, as the final evaluation in .acl_fit() does
  obj
}

test_that("alscl_speed validates and restores settings", {
  old <- alscl_speed(sd_cores = 2, framework = "CppAD")
  on.exit(options(old), add = TRUE)
  expect_identical(getOption("ALSCL.sd_cores"), 2)
  expect_identical(getOption("ALSCL.framework"), "CppAD")
  alscl_speed(sd_cores = 1)  # other settings keep their value
  expect_identical(getOption("ALSCL.framework"), "CppAD")
  expect_error(alscl_speed(sd_cores = 0), "sd_cores")
  expect_error(alscl_speed(sd_cores = 1.5), "sd_cores")
  expect_error(alscl_speed(framework = "other"))
  expect_identical(ALSCL:::.acl_worker_options(), list(ALSCL.framework = "CppAD", ALSCL.sd_cores = 1L))
  options(old)
  expect_true(ALSCL:::.acl_cores("auto") >= 1L)
  expect_identical(ALSCL:::.acl_cores(3), if (.Platform$OS.type == "unix") 3L else 1L)
})

test_that("parallel optimHess is identical to stats::optimHess with random effects", {
  skip_on_os("windows")
  for (model in c("ACL", "ALSCL")) {
    obj <- random_fixture(model)
    ref <- stats::optimHess(obj$par, obj$fn, obj$gr)
    obj <- random_fixture(model)
    expect_identical(ALSCL:::.acl_optimhess(obj, obj$par, 2L), ref)
  }
})

test_that("parallel standard errors are identical to TMB::sdreport", {
  skip_on_os("windows")
  for (model in c("ACL", "ALSCL")) {
    # Away from the optimum some variances are negative, so both give NaN.
    obj <- random_fixture(model)
    ref <- suppressWarnings(TMB::sdreport(obj, par.fixed = obj$par, getReportCovariance = FALSE))
    obj <- random_fixture(model)
    new <- suppressWarnings(ALSCL:::.acl_sdreport(obj, obj$par, ncores = 2L))
    for (nm in setdiff(names(ref), "env")) expect_identical(new[[nm]], ref[[nm]], label = nm)
    expect_identical(suppressWarnings(summary(new)), suppressWarnings(summary(ref)))
    expect_identical(as.list(new$env), as.list(ref$env))
  }
})

test_that("fits give identical standard errors with one and two cores", {
  skip_on_os("windows")
  old <- alscl_speed(sd_cores = 1); on.exit(options(old), add = TRUE)
  serial <- fit_fixture("ALSCL")$result
  alscl_speed(sd_cores = 2)
  parallel <- fit_fixture("ALSCL")$result
  expect_identical(parallel$est_std, serial$est_std)
  expect_identical(parallel$vcov, serial$vcov)
  expect_identical(parallel$opt$par, serial$opt$par)
})

test_that("TMBad and CppAD fits agree to rounding", {
  skip_on_cran()
  old <- options(ALSCL.sd_cores = 1); on.exit(options(old), add = TRUE)
  for (model in c("ACL", "ALSCL")) {
    alscl_speed(framework = "CppAD"); a <- fit_fixture(model)$result
    alscl_speed(framework = "TMBad"); b <- fit_fixture(model)$result
    expect_false(identical(a$obj$env$DLL, b$obj$env$DLL))
    expect_equal(b$opt$objective, a$opt$objective, tolerance = 1e-10)
    expect_equal(b$opt$par, a$opt$par, tolerance = 1e-8)
    expect_equal(b$est_std, a$est_std, tolerance = 1e-8)
  }
})
