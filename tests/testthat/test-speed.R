random_fixture <- function(model) {
  x <- cpp_fixture(model)
  obj <- TMB::MakeADFun(x$data, x$parameters, random = c("dev_log_R", "dev_log_F", "dev_log_N0"),
                        DLL = x$info$dll_name, silent = TRUE)
  obj$fn(obj$par)  # sets last.par.best, as the final evaluation in .acl_fit() does
  obj
}

test_that("alscl_speed validates and restores settings", {
  old <- options(ALSCL.sd_cores = NULL, ALSCL.framework = NULL)
  on.exit(options(old), add = TRUE)
  expect_identical(ALSCL:::.acl_framework(), "CppAD")  # default: results of ALSCL 2.0.0
  alscl_speed(sd_cores = 2, framework = "TMBad")
  expect_identical(getOption("ALSCL.sd_cores"), 2)
  expect_identical(getOption("ALSCL.framework"), "TMBad")
  alscl_speed(sd_cores = 1)  # other settings keep their value
  expect_identical(getOption("ALSCL.framework"), "TMBad")
  for (bad in list(0, 1.5, -1, Inf, NA_real_, 2^31, c(1, 2), "4"))
    expect_error(alscl_speed(sd_cores = bad), "sd_cores")
  expect_error(alscl_speed(framework = "other"))
  expect_identical(ALSCL:::.acl_worker_options(), list(ALSCL.framework = "TMBad", ALSCL.sd_cores = 1L))
})

test_that("auto cores fork only where forking is safe", {
  safe <- ALSCL:::.acl_fork_safe
  expect_true(safe("unix", "X11", c("", ""), "/usr/lib/libRblas.so"))
  expect_false(safe("windows", "Rgui", c("", ""), ""))
  expect_false(safe("unix", "AQUA", c("", ""), ""))
  expect_false(safe("unix", "RStudio", c("", ""), ""))
  expect_false(safe("unix", "X11", c("1", ""), ""))
  expect_false(safe("unix", "X11", c("", "1"), ""))
  expect_false(safe("unix", "X11", c("", ""), "/System/Library/Frameworks/Accelerate.framework/libBLAS.dylib"))
  expect_identical(ALSCL:::.acl_cores("auto", fork_safe = FALSE), 1L)
  expect_identical(ALSCL:::.acl_cores(3, fork_safe = FALSE),
                   if (.Platform$OS.type == "unix") 3L else 1L)
  expect_true(ALSCL:::.acl_cores("auto") >= 1L)
})

test_that("only checked TMB versions use the parallel delta method", {
  expect_true(ALSCL:::.acl_tmb_supported("1.9.21"))
  expect_false(ALSCL:::.acl_tmb_supported("1.9.22"))
  expect_false(ALSCL:::.acl_tmb_supported("1.10.0"))
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
    # check_version = FALSE runs the parallel code with any installed TMB, so
    # this test shows whether a new TMB version can be added to .acl_tmb_checked.
    new <- suppressWarnings(ALSCL:::.acl_sdreport(obj, obj$par, ncores = 2L, check_version = FALSE))
    for (nm in setdiff(names(ref), "env")) expect_identical(new[[nm]], ref[[nm]], label = nm)
    expect_identical(suppressWarnings(summary(new)), suppressWarnings(summary(ref)))
    expect_identical(as.list(new$env), as.list(ref$env))
  }
})

test_that("a failure to fork falls back to sequential standard errors", {
  skip_on_os("windows")
  old <- alscl_speed(sd_cores = 1); on.exit(options(old), add = TRUE)
  serial <- fit_fixture("ALSCL")$result
  alscl_speed(sd_cores = 2)
  testthat::local_mocked_bindings(
    mclapply = function(...) stop("unable to fork, possible reason: Resource temporarily unavailable"),
    .package = "parallel")
  expect_warning(fallback <- fit_fixture("ALSCL")$result, "computing them sequentially")
  expect_identical(fallback$est_std, serial$est_std)
  expect_identical(fallback$vcov, serial$vcov)
  expect_identical(fallback$pdHess, serial$pdHess)
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
  old <- options(ALSCL.sd_cores = 1, ALSCL.framework = getOption("ALSCL.framework"))
  on.exit(options(old), add = TRUE)
  for (model in c("ACL", "ALSCL")) {
    alscl_speed(framework = "CppAD"); a <- fit_fixture(model)$result
    alscl_speed(framework = "TMBad"); b <- fit_fixture(model)$result
    expect_false(identical(a$obj$env$DLL, b$obj$env$DLL))
    expect_equal(b$opt$objective, a$opt$objective, tolerance = 1e-10)
    expect_equal(b$opt$par, a$opt$par, tolerance = 1e-8)
    expect_equal(b$est_std, a$est_std, tolerance = 1e-8)
  }
})
