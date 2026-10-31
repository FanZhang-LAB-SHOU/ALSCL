# Check the live objective before evaluating it again: calling fn first would
# conceal a perturbed state left by a numerical Hessian calculation.
expect_final_tmb_state <- function(fit) {
  joint <- fit$obj$env$last.par
  random <- fit$obj$env$random
  fixed <- if (length(random)) joint[-random] else joint
  expect_identical(unname(fixed), unname(fit$opt$par))
  live <- fit$obj$report()
  expect_equal(live[names(fit$report)], fit$report, tolerance = 1e-10)
  expect_equal(fit$obj$fn(fit$opt$par), fit$opt$objective, tolerance = 1e-10)
}

test_that("sequential uncertainty leaves the live objective at the fitted mode", {
  old <- options(ALSCL.sd_cores = 1, ALSCL.framework = "CppAD")
  on.exit(options(old), add = TRUE)
  for (framework in c("CppAD", "TMBad")) {
    options(ALSCL.framework = framework)
    for (model in c("ACL", "ALSCL")) {
      example <- fit_fixture(model)
      shared_f <- do.call(if (model == "ACL") run_acl else run_alscl,
        c(example$input, list(parameters = example$parameters, map = example$map,
                             F_structure = "year", silent = TRUE)))
      for (fit in list(example$result, shared_f)) {
        expect_true(fit$diagnostics$numerical_ok)
        expect_identical(fit$sd_info$method, "sequential")
        expect_final_tmb_state(fit)
      }
    }
  }
})

test_that("unchecked versions restore the final objective without starting workers", {
  old <- options(ALSCL.sd_cores = 2, ALSCL.framework = "CppAD")
  on.exit(options(old), add = TRUE)
  testthat::local_mocked_bindings(.acl_tmb_supported = function(...) FALSE)
  testthat::local_mocked_bindings(
    mclapply = function(...) stop("must not start fork workers"),
    makePSOCKcluster = function(...) stop("must not start socket workers"),
    .package = "parallel")
  for (model in c("ACL", "ALSCL")) {
    expect_no_warning(fit <- fit_fixture(model)$result)
    expect_identical(fit$sd_info$method, "sequential")
    expect_match(fit$sd_info$note, "not checked")
    expect_final_tmb_state(fit)
  }
})

test_that("a failed parallel calculation restores the fitted state after fallback", {
  old <- options(ALSCL.sd_cores = 2, ALSCL.sd_backend = "socket",
                 ALSCL.sd_socket_min_seconds = 0, ALSCL.framework = "CppAD")
  on.exit(options(old), add = TRUE)
  testthat::local_mocked_bindings(.acl_tmb_supported = function(...) TRUE)
  testthat::local_mocked_bindings(
    makePSOCKcluster = function(...) stop("deliberate worker startup failure"),
    .package = "parallel")
  for (model in c("ACL", "ALSCL")) {
    expect_warning(fit <- fit_fixture(model)$result,
                   "Parallel standard errors failed.*computing them sequentially")
    expect_identical(fit$sd_info$method, "sequential")
    expect_match(fit$sd_info$note, "deliberate worker startup failure")
    expect_true(fit$pdHess)
    expect_final_tmb_state(fit)
  }
})

test_that("unavailable uncertainty does not leave a perturbed live objective", {
  old <- options(ALSCL.sd_cores = 1, ALSCL.framework = "CppAD")
  on.exit(options(old), add = TRUE)
  testthat::local_mocked_bindings(.acl_sdreport = function(obj, par.fixed, ...) {
    obj$fn(par.fixed + 0.1)
    stop("deliberate standard-error failure")
  })
  for (model in c("ACL", "ALSCL")) {
    expect_warning(fit <- fit_fixture(model)$result,
                   "Standard errors unavailable: deliberate standard-error failure")
    expect_null(fit$est_std)
    expect_null(fit$vcov)
    expect_true(is.na(fit$pdHess))
    expect_final_tmb_state(fit)
  }
})

test_that("failure to restore the fitted objective is not swallowed as an SE error", {
  old <- options(ALSCL.sd_cores = 1, ALSCL.framework = "CppAD")
  on.exit(options(old), add = TRUE)
  make_ad_fun <- TMB::MakeADFun
  testthat::local_mocked_bindings(MakeADFun = function(...) {
    obj <- make_ad_fun(...)
    evaluate <- obj$fn
    env <- obj$env
    obj$fn <- function(...) {
      if (isTRUE(env$fail_restore)) stop("deliberate objective restoration failure")
      evaluate(...)
    }
    obj
  }, .package = "TMB")
  testthat::local_mocked_bindings(.acl_sdreport = function(obj, par.fixed, ...) {
    obj$env$fail_restore <- TRUE
    NULL
  })
  expect_error(fit_fixture("ACL"), "deliberate objective restoration failure")
})
