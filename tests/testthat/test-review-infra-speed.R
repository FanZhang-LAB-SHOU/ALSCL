review_random_fixture <- function(model) {
  x <- cpp_fixture(model)
  obj <- TMB::MakeADFun(x$data, x$parameters, random = c("dev_log_R", "dev_log_F", "dev_log_N0"),
                        DLL = x$info$dll_name, silent = TRUE)
  obj$fn(obj$par)  # sets last.par.best, as the final evaluation in .acl_fit() does
  obj
}
review_quiet_nan <- function(expr) withCallingHandlers(expr, warning = function(w)
  if (grepl("NaNs produced", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning"))

test_that("the standard-error level is validated and defaults to the full calculation (F31)", {
  withr::local_options(list(ALSCL.se_level = NULL))
  expect_identical(ALSCL:::.acl_se_level(), "full")
  for (level in c("full", "hessian", "none"))
    withr::with_options(list(ALSCL.se_level = level), expect_identical(ALSCL:::.acl_se_level(), level))
  for (bad in list("hess", NA_character_, 1, c("full", "none"), TRUE))
    withr::with_options(list(ALSCL.se_level = bad),
      expect_error(ALSCL:::.acl_se_level(), "ALSCL.se_level"))
  withr::with_options(list(ALSCL.se_level = "hess"),
    expect_error(ALSCL:::.acl_check_speed_options(), "ALSCL.se_level"))
  expect_true(ALSCL:::.acl_check_speed_options())
})

test_that("the hessian level equals sdreport without the delta method and the full level is unchanged (F31)", {
  skip_on_cran()
  for (model in c("ACL", "ALSCL")) {
    obj <- review_random_fixture(model)
    reference <- review_quiet_nan(TMB::sdreport(obj, par.fixed = obj$par, getReportCovariance = FALSE,
                                                skip.delta.method = TRUE))
    obj <- review_random_fixture(model)
    full <- review_quiet_nan(TMB::sdreport(obj, par.fixed = obj$par, getReportCovariance = FALSE))
    cores <- if (.Platform$OS.type == "unix") c(1L, 2L) else 1L
    for (ncores in cores) {
      obj <- review_random_fixture(model)
      reduced <- review_quiet_nan(ALSCL:::.acl_sdreport(obj, obj$par, ncores = ncores, check_version = FALSE,
        fallback = FALSE, backend = "fork", level = "hessian"))
      for (nm in setdiff(names(reference), "env"))
        expect_identical(reduced[[nm]], reference[[nm]], label = paste(model, ncores, nm))
      expect_true(all(is.na(reduced$sd)))
      expect_identical(reduced$cov.fixed, full$cov.fixed)
      expect_identical(reduced$pdHess, full$pdHess)
      info <- attr(reduced, "acl_sd_info")
      expect_identical(info$level, "hessian")
      expect_identical(info$method, if (ncores > 1L) "forked processes" else "sequential")
      expect_match(ALSCL:::.acl_sd_message(info), "Covariance of the fixed effects only")
    }
    obj <- review_random_fixture(model)
    socket <- review_quiet_nan(ALSCL:::.acl_sdreport(obj, obj$par, ncores = 2L, check_version = FALSE,
      fallback = FALSE, backend = "socket", level = "hessian"))
    expect_identical(socket$cov.fixed, reference$cov.fixed)
    expect_identical(attr(socket, "acl_sd_info")$method, "sequential")
    obj <- review_random_fixture(model)
    expect_null(ALSCL:::.acl_sdreport(obj, obj$par, level = "none"))
    # The default level returns the same object as before, with the same record.
    obj <- review_random_fixture(model)
    default <- review_quiet_nan(ALSCL:::.acl_sdreport(obj, obj$par, ncores = 1L))
    for (nm in setdiff(names(full), "env"))
      expect_identical(default[[nm]], full[[nm]], label = paste(model, "full", nm))
    expect_named(attr(default, "acl_sd_info"), c("method", "cores", "seconds", "note"))
    expect_match(ALSCL:::.acl_sd_message(attr(default, "acl_sd_info")), "^Standard errors: sequential")
  }
})

test_that("fits made with a reduced standard-error level are coherent (F31)", {
  skip_on_cran()
  z <- fit_fixture("ACL")
  args <- c(z$input, list(parameters = z$parameters, map = z$map, silent = TRUE))
  withr::local_options(list(ALSCL.sd_cores = 1L))
  full <- z$result
  hessian <- withr::with_options(list(ALSCL.se_level = "hessian"), do.call(run_acl, args))
  none <- expect_no_warning(withr::with_options(list(ALSCL.se_level = "none"), do.call(run_acl, args)))
  for (fit in list(hessian, none)) {
    expect_identical(fit$opt$par, full$opt$par)
    expect_identical(fit$opt$objective, full$opt$objective)
    expect_identical(fit$report, full$report)
    expect_identical(fit$gradient, full$gradient)
  }
  # "hessian": same covariance, Hessian check and numerical screen; no derived SEs.
  expect_identical(hessian$vcov, full$vcov)
  expect_identical(hessian$pdHess, full$pdHess)
  expect_identical(hessian$diagnostics, full$diagnostics)
  expect_identical(dimnames(hessian$est_std), dimnames(full$est_std))
  expect_identical(hessian$est_std[, "Estimate"], full$est_std[, "Estimate"])
  fixed <- rownames(full$est_std) %in% names(full$opt$par)
  expect_identical(hessian$est_std[fixed, "Std. Error"], full$est_std[fixed, "Std. Error"])
  derived <- rownames(full$est_std) %in% c("SSB", "Rec", "B", "N")
  expect_true(any(derived))
  expect_true(all(is.na(hessian$est_std[derived, "Std. Error"])))
  expect_identical(hessian$sd_info$level, "hessian")
  expect_identical(ALSCL:::.acl_fit_status(hessian)[c("pdHess", "numerical_ok", "issues")],
                   ALSCL:::.acl_fit_status(full)[c("pdHess", "numerical_ok", "issues")])
  # "none": the shape of a fit whose standard errors are not available.
  expect_null(none$est_std)
  expect_null(none$vcov)
  expect_identical(none$pdHess, NA)
  expect_null(none$sd_info)
  expect_false(none$diagnostics$numerical_ok)
  expect_true(any(grepl("Hessian or covariance unavailable", none$diagnostics$issues)))
  # The level is a session setting, not part of the recipe: a refit is complete.
  expect_null(hessian$recipe$settings$ALSCL.se_level)
  expect_identical(refit_model(hessian, silent = TRUE)$est_std, full$est_std)
})

test_that("socket workers of a batch receive the caller's standard-error level (F31, F32)", {
  skip_on_cran()
  ask <- function(i) list(level = getOption("ALSCL.se_level"), cores = getOption("ALSCL.sd_cores"),
                          pid = Sys.getpid())
  environment(ask) <- globalenv()
  withr::local_options(list(ALSCL.se_level = "hessian", ALSCL.sd_cores = 2L))
  workers <- ALSCL:::.acl_cluster_lapply(1:2, ask, 2L, "acl")
  expect_identical(vapply(workers, `[[`, "", "level"), c("hessian", "hessian"))
  expect_identical(vapply(workers, `[[`, 1L, "cores"), c(1L, 1L))
  expect_false(Sys.getpid() %in% vapply(workers, `[[`, 1L, "pid"))
  # One worker means this process: the session's settings apply unchanged.
  here <- ALSCL:::.acl_cluster_lapply(1, ask, 1L, "acl")[[1]]
  expect_identical(here, list(level = "hessian", cores = 2L, pid = Sys.getpid()))
})

test_that("the blocked delta method agrees with TMB::sdreport to rounding error (F33)", {
  skip_on_cran()
  withr::local_options(list(ALSCL.delta_method = NULL))
  expect_identical(ALSCL:::.acl_delta_method(), "exact")
  withr::with_options(list(ALSCL.delta_method = "fast"),
    expect_error(ALSCL:::.acl_delta_method(), "ALSCL.delta_method"))
  for (model in c("ACL", "ALSCL")) {
    z <- fit_fixture(model)
    obj <- z$result$obj; par <- z$result$opt$par
    obj$fn(par)
    reference <- TMB::sdreport(obj, par.fixed = par, getReportCovariance = FALSE)
    expect_identical(summary(reference), z$result$est_std)
    cores <- if (.Platform$OS.type == "unix") c(1L, 2L) else 1L
    for (ncores in cores) for (chunk in c(500L, 7L)) {
      obj$fn(par)
      blocked <- if (chunk == 500L)
        ALSCL:::.acl_sdreport(obj, par, ncores = ncores, check_version = FALSE, fallback = FALSE,
                              backend = "fork", delta = "blocked")
      else {
        # Small chunks exercise the chunk boundaries of the same calculation.
        hessian <- ALSCL:::.acl_optimhess(obj, par, 1L)
        ans <- TMB::sdreport(obj, par.fixed = par, hessian.fixed = hessian,
                             getReportCovariance = FALSE, skip.delta.method = TRUE)
        ans$sd <- ALSCL:::.acl_delta_blocked(obj, obj$env$last.par, ans$cov.fixed, ncores, chunk)$sd
        ans
      }
      label <- paste(model, ncores, chunk)
      expect_identical(is.finite(blocked$sd), is.finite(reference$sd), label = label)
      positive <- is.finite(reference$sd) & reference$sd > 0
      expect_true(any(positive), label = label)
      expect_lt(max(abs(blocked$sd[positive] - reference$sd[positive]) / reference$sd[positive]), 1e-12,
                label = label)
      expect_equal(blocked$sd[!positive], reference$sd[!positive], tolerance = 1e-12, label = label)
      for (nm in setdiff(names(reference), c("sd", "env")))
        expect_identical(blocked[[nm]], reference[[nm]], label = paste(label, nm))
      if (chunk == 500L) {
        info <- attr(blocked, "acl_sd_info")
        expect_identical(info$delta_method, "blocked")
        expect_match(ALSCL:::.acl_sd_message(info), "blocked delta method")
      }
    }
    # The default stays the exact calculation, identical to TMB::sdreport().
    obj$fn(par)
    exact <- ALSCL:::.acl_sdreport(obj, par, ncores = 1L)
    expect_identical(exact$sd, reference$sd)
    expect_null(attr(exact, "acl_sd_info")$delta_method)
  }
})

test_that("the blocked delta method agrees away from the optimum with several fixed effects (F33)", {
  skip_on_cran()
  for (model in c("ACL", "ALSCL")) {
    obj <- review_random_fixture(model)
    reference <- review_quiet_nan(TMB::sdreport(obj, par.fixed = obj$par, getReportCovariance = FALSE))
    obj <- review_random_fixture(model)
    hessian <- ALSCL:::.acl_optimhess(obj, obj$par, 1L)
    ans <- TMB::sdreport(obj, par.fixed = obj$par, hessian.fixed = hessian,
                         getReportCovariance = FALSE, skip.delta.method = TRUE)
    blocked <- review_quiet_nan(ALSCL:::.acl_delta_blocked(obj, obj$env$last.par, ans$cov.fixed, 1L))
    expect_identical(blocked$value, reference$value)
    expect_identical(is.nan(blocked$sd), is.nan(reference$sd), label = model)
    ok <- is.finite(reference$sd) & reference$sd > 0
    # Variances, so that cancellation near zero does not inflate the comparison.
    scale <- max(reference$sd[ok]^2)
    expect_lt(max(abs(blocked$sd[ok]^2 - reference$sd[ok]^2)) / scale, 1e-12, label = model)
  }
})
