random_fixture <- function(model) {
  x <- cpp_fixture(model)
  obj <- TMB::MakeADFun(x$data, x$parameters, random = c("dev_log_R", "dev_log_F", "dev_log_N0"),
                        DLL = x$info$dll_name, silent = TRUE)
  obj$fn(obj$par)  # sets last.par.best, as the final evaluation in .acl_fit() does
  obj
}

# Muffle only the "NaNs produced" warnings that negative variances give away
# from the optimum; any other warning, such as a fallback, still reaches the test.
quiet_nan <- function(expr) withCallingHandlers(expr, warning = function(w)
  if (grepl("NaNs produced", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning"))

# Each test uses the AD library given, restoring the previous setting.
with_framework <- function(framework, code) {
  old <- options(ALSCL.framework = framework); on.exit(options(old))
  code
}

# Every component of a parallel sdreport must be identical to TMB's.
expect_same_sdreport <- function(new, ref, label) {
  for (nm in setdiff(names(ref), "env")) expect_identical(new[[nm]], ref[[nm]], label = paste(label, nm))
  expect_identical(quiet_nan(summary(new)), quiet_nan(summary(ref)), label = label)
  expect_identical(as.list(new$env), as.list(ref$env), label = label)
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

test_that("standard errors fork where it is safe and use socket workers elsewhere", {
  safe <- ALSCL:::.acl_fork_safe
  reason <- ALSCL:::.acl_fork_reason
  expect_true(safe("unix", "X11", c("", ""), "/usr/lib/libRblas.so"))
  expect_false(safe("windows", "Rgui", c("", ""), ""))
  expect_false(safe("unix", "AQUA", c("", ""), ""))
  expect_false(safe("unix", "RStudio", c("", ""), ""))
  expect_false(safe("unix", "X11", c("1", ""), ""))
  expect_false(safe("unix", "X11", c("", "1"), ""))
  expect_false(safe("unix", "X11", c("", ""), "/System/Library/Frameworks/Accelerate.framework/libBLAS.dylib"))
  expect_match(reason("windows", "Rgui", c("", ""), ""), "Windows")
  expect_match(reason("unix", "RStudio", c("", ""), ""), "GUI")
  expect_match(reason("unix", "X11", c("", ""), "libRblas.so"), "safe")
  expect_identical(ALSCL:::.acl_sd_backend(fork_safe = TRUE), "fork")
  expect_identical(ALSCL:::.acl_sd_backend(fork_safe = FALSE), "socket")
  expect_identical(ALSCL:::.acl_sd_backend(TRUE, "socket"), "socket")
  expect_identical(ALSCL:::.acl_sd_backend(FALSE, "fork"),
                   if (.Platform$OS.type == "unix") "fork" else "socket")
  expect_identical(ALSCL:::.acl_cores(3), 3L)
  expect_true(ALSCL:::.acl_cores("auto") >= 1L)
  info <- alscl_speed_info()
  expect_s3_class(info, "data.frame")
  expect_identical(names(info), c("item", "value"))
  expect_true(all(c("cores for standard errors", "standard errors computed by", "reason") %in% info$item))
})

test_that("only checked TMB versions use the parallel delta method", {
  expect_identical(ALSCL:::.acl_tmb_checked, "1.9.21")
  expect_true(ALSCL:::.acl_tmb_supported(ALSCL:::.acl_tmb_checked[1]))
  expect_false(ALSCL:::.acl_tmb_supported("0.0.1"))
  expect_false(ALSCL:::.acl_tmb_supported("99.0.0"))
})

test_that("parallel optimHess is identical to stats::optimHess with random effects", {
  skip_on_os("windows")
  for (framework in c("CppAD", "TMBad")) with_framework(framework, {
    for (model in c("ACL", "ALSCL")) {
      obj <- random_fixture(model)
      ref <- stats::optimHess(obj$par, obj$fn, obj$gr)
      obj <- random_fixture(model)
      expect_identical(ALSCL:::.acl_optimhess(obj, obj$par, 2L), ref, label = paste(framework, model))
      obj <- random_fixture(model)
      expect_identical(ALSCL:::.acl_optimhess(obj, obj$par, 1L), ref, label = paste(framework, model, "1 core"))
    }
  })
})

test_that("forked processes give standard errors identical to TMB::sdreport", {
  skip_on_os("windows")
  # check_version = FALSE runs the parallel code with any installed TMB and
  # fallback = FALSE turns a parallel failure into an error, so a pass shows
  # that this TMB version can be added to .acl_tmb_checked.
  for (framework in c("CppAD", "TMBad")) with_framework(framework, {
    for (model in c("ACL", "ALSCL")) {
      obj <- random_fixture(model)
      ref <- quiet_nan(TMB::sdreport(obj, par.fixed = obj$par, getReportCovariance = FALSE))
      obj <- random_fixture(model)
      new <- quiet_nan(ALSCL:::.acl_sdreport(obj, obj$par, ncores = 2L, check_version = FALSE,
                                             fallback = FALSE, backend = "fork"))
      expect_same_sdreport(new, ref, paste(framework, model, "fork"))
      expect_identical(attr(new, "acl_sd_info")$method, "forked processes")
    }
  })
})

test_that("socket workers give standard errors identical to TMB::sdreport", {
  # Runs on every system, including Windows. min_seconds = 0 sends every
  # ADREPORT quantity to the workers.
  old <- options(ALSCL.sd_socket_min_seconds = 0); on.exit(options(old), add = TRUE)
  for (framework in c("CppAD", "TMBad")) with_framework(framework, {
    for (model in c("ACL", "ALSCL")) {
      obj <- random_fixture(model)
      ref <- quiet_nan(TMB::sdreport(obj, par.fixed = obj$par, getReportCovariance = FALSE))
      obj <- random_fixture(model)
      new <- quiet_nan(ALSCL:::.acl_sdreport(obj, obj$par, ncores = 2L, check_version = FALSE,
                                             fallback = FALSE, backend = "socket"))
      expect_same_sdreport(new, ref, paste(framework, model, "socket"))
      info <- attr(new, "acl_sd_info")
      expect_identical(info$method, "socket workers (delta method)")
      expect_identical(info$cores, 2L)
    }
  })
})

test_that("with little work the socket path computes standard errors in the main process", {
  old <- options(ALSCL.sd_socket_min_seconds = 1e6); on.exit(options(old), add = TRUE)
  testthat::local_mocked_bindings(makePSOCKcluster = function(...) stop("must not start workers"),
                                  .package = "parallel")
  obj <- random_fixture("ACL")
  ref <- quiet_nan(TMB::sdreport(obj, par.fixed = obj$par, getReportCovariance = FALSE))
  obj <- random_fixture("ACL")
  new <- quiet_nan(ALSCL:::.acl_sdreport(obj, obj$par, ncores = 2L, check_version = FALSE,
                                         fallback = FALSE, backend = "socket"))
  expect_same_sdreport(new, ref, "socket below threshold")
  expect_identical(attr(new, "acl_sd_info")$method, "sequential")
})

test_that("the identity test cannot pass through the fallback", {
  skip_on_os("windows")
  testthat::local_mocked_bindings(
    .acl_delta_sd = function(...) stop(ALSCL:::.acl_parallel_error("deliberate failure")))
  obj <- random_fixture("ACL")
  expect_error(quiet_nan(ALSCL:::.acl_sdreport(obj, obj$par, ncores = 2L, check_version = FALSE,
                                               fallback = FALSE, backend = "fork")), "deliberate failure")
  obj <- random_fixture("ACL")
  expect_warning(quiet_nan(ALSCL:::.acl_sdreport(obj, obj$par, ncores = 2L, check_version = FALSE,
                                                 backend = "fork")), "computing them sequentially")
})

test_that("a failure to fork falls back to sequential standard errors", {
  skip_on_os("windows")
  old <- c(alscl_speed(sd_cores = 1), options(ALSCL.sd_backend = "fork"))
  on.exit(options(old), add = TRUE)
  serial <- fit_fixture("ALSCL")$result
  alscl_speed(sd_cores = 2)
  # Treat the installed TMB as checked, so that the parallel path is taken.
  testthat::local_mocked_bindings(.acl_tmb_supported = function(...) TRUE)
  testthat::local_mocked_bindings(
    mclapply = function(...) stop("unable to fork, possible reason: Resource temporarily unavailable"),
    .package = "parallel")
  expect_warning(fallback <- fit_fixture("ALSCL")$result, "computing them sequentially")
  expect_identical(fallback$est_std, serial$est_std)
  expect_identical(fallback$vcov, serial$vcov)
  expect_identical(fallback$pdHess, serial$pdHess)
  expect_identical(fallback$sd_info$method, "sequential")
  expect_match(fallback$sd_info$note, "parallel calculation failed")
})

test_that("a failure to start socket workers falls back to sequential standard errors", {
  old <- c(alscl_speed(sd_cores = 1), options(ALSCL.sd_backend = "socket", ALSCL.sd_socket_min_seconds = 0))
  on.exit(options(old), add = TRUE)
  serial <- fit_fixture("ALSCL")$result
  alscl_speed(sd_cores = 2)
  testthat::local_mocked_bindings(.acl_tmb_supported = function(...) TRUE)
  testthat::local_mocked_bindings(makePSOCKcluster = function(...) stop("cannot open the connection"),
                                  .package = "parallel")
  expect_warning(fallback <- fit_fixture("ALSCL")$result, "computing them sequentially")
  expect_identical(fallback$est_std, serial$est_std)
  expect_identical(fallback$vcov, serial$vcov)
})

test_that("an unchecked TMB version computes standard errors sequentially without workers", {
  old <- alscl_speed(sd_cores = 1); on.exit(options(old), add = TRUE)
  serial <- fit_fixture("ALSCL")$result
  alscl_speed(sd_cores = 2)
  testthat::local_mocked_bindings(.acl_tmb_supported = function(...) FALSE)
  testthat::local_mocked_bindings(mclapply = function(...) stop("mclapply must not be called"),
                                  makePSOCKcluster = function(...) stop("workers must not start"),
                                  .package = "parallel")
  expect_no_warning(unchecked <- fit_fixture("ALSCL")$result)
  expect_identical(unchecked$est_std, serial$est_std)
  expect_identical(unchecked$vcov, serial$vcov)
  expect_identical(unchecked$sd_info$method, "sequential")
  expect_match(unchecked$sd_info$note, "not checked")
})

test_that("fits give identical standard errors with one and two cores, by either method", {
  old <- c(alscl_speed(sd_cores = 1), options(ALSCL.sd_socket_min_seconds = 0, ALSCL.sd_backend = NULL))
  on.exit(options(old), add = TRUE)
  serial <- fit_fixture("ALSCL")$result
  expect_identical(serial$sd_info$method, "sequential")
  expect_identical(serial$sd_info$cores, 1L)
  alscl_speed(sd_cores = 2)
  # Take the parallel path with any installed TMB, and fail on a fallback.
  testthat::local_mocked_bindings(.acl_tmb_supported = function(...) TRUE)
  backends <- if (.Platform$OS.type == "unix") c("fork", "socket") else "socket"
  for (backend in backends) {
    options(ALSCL.sd_backend = backend)
    expect_no_warning(parallel <- fit_fixture("ALSCL")$result)
    expect_identical(parallel$est_std, serial$est_std, label = backend)
    expect_identical(parallel$vcov, serial$vcov, label = backend)
    expect_identical(parallel$opt$par, serial$opt$par, label = backend)
    expect_identical(parallel$sd_info$method,
                     if (backend == "fork") "forked processes" else "socket workers (delta method)")
    expect_identical(parallel$sd_info$cores, 2L)
    expect_true(parallel$sd_info$seconds >= 0)
  }
})

test_that("fit messages say how standard errors were computed", {
  msg <- ALSCL:::.acl_sd_message
  expect_identical(msg(list(method = "forked processes", cores = 4L, seconds = 9.04)),
                   "Standard errors: forked processes on 4 cores, 9.0 s.")
  expect_identical(msg(list(method = "socket workers (delta method)", cores = 3L, seconds = 6.5)),
                   "Standard errors: 3 socket workers for the delta method, 6.5 s.")
  expect_identical(msg(list(method = "sequential", cores = 1L, seconds = 1.23, note = "one core")),
                   "Standard errors: sequential (one core), 1.2 s.")
  expect_null(msg(NULL))
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
