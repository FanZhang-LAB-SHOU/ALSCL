test_that("ALSCL accounts for varying mortality in cohorts and catches", {
  old <- options(ALSCL.sd_cores = 1L, ALSCL.framework = "CppAD")
  on.exit(options(old), add = TRUE)
  for (framework in c("CppAD", "TMBad")) {
    options(ALSCL.framework = framework)
    x <- cpp_fixture("ALSCL")
    for (shared in c(FALSE, TRUE)) for (near_zero in c(FALSE, TRUE)) {
      p <- x$parameters; d <- x$data
      p$dev_log_R <- .1 * sin(seq_len(d$Y))
      p$dev_log_N0 <- .1 * cos(seq_len(d$A - 1L))
      groups <- if (shared) 1L else d$L
      p$dev_log_F <- array(.15 * sin(seq_len(groups * d$Y)), c(groups, d$Y))
      if (near_zero) { d$M <- 1e-10; p$mean_log_F <- log(1e-9) }
      obj <- TMB::MakeADFun(d, p, DLL = x$info$dll_name, silent = TRUE)
      r <- obj$report(obj$par)
      expected <- array(0, c(d$L, d$A, d$Y))
      log_n0 <- c(p$mean_log_R + p$dev_log_R[1L], rep(0, d$A - 1L))
      for (a in 2:d$A) log_n0[a] <- log_n0[a - 1L] - exp(p$log_init_Z) + p$dev_log_N0[a - 1L]
      expected[, , 1L] <- sweep(r$pla, 2L, exp(log_n0), "*")
      for (t in 2:d$Y) {
        survived <- sweep(expected[, , t - 1L], 1L, exp(-r$ZL[, t - 1L]), "*")
        expected[, 1L, t] <- r$pla[, 1L] * r$Rec[t]
        expected[, 2:(d$A - 1L), t] <- r$G %*% survived[, 1:(d$A - 2L)]
        expected[, d$A, t] <- r$G %*% (survived[, d$A - 1L] + survived[, d$A])
      }
      expect_equal(r$NLA, expected, tolerance = 1e-12)
      expected_catch <- expected
      for (t in seq_len(d$Y)) {
        fraction <- r$FL[, t] * (-expm1(-r$ZL[, t]) / r$ZL[, t])
        expected_catch[, , t] <- sweep(expected[, , t], 1L, fraction, "*")
      }
      expect_equal(r$CNLA, expected_catch, tolerance = 1e-12)
      expect_equal(r$CN, apply(expected_catch, 3L, sum), tolerance = 1e-12)
      expect_equal(r$CNL, apply(expected_catch, c(1L, 3L), sum), tolerance = 1e-12)
      expect_equal(r$CNA, apply(expected_catch, c(2L, 3L), sum), tolerance = 1e-12)
      # Check growth and fishing-mortality derivatives against finite differences.
      selected <- which(names(obj$par) %in% c("mean_log_F", "log_vbk", "log_Linf", "log_cv_grow"))
      analytic <- as.numeric(obj$gr(obj$par))[selected]
      numerical <- vapply(selected, function(i) {
        upper <- lower <- obj$par
        upper[i] <- upper[i] + 1e-5; lower[i] <- lower[i] - 1e-5
        (obj$fn(upper) - obj$fn(lower)) / 2e-5
      }, numeric(1))
      expect_equal(analytic, numerical, tolerance = 2e-5)
    }
  }
})

test_that("process simulation uses a double evaluator with correctly ordered parameters", {
  old <- options(ALSCL.sd_cores = 1L, ALSCL.framework = "CppAD")
  on.exit(options(old), add = TRUE)
  original_make <- TMB::MakeADFun
  evaluators <- list()
  # Reverse the caller's parameter order to test that the C++ order is used.
  tracked_make <- function(data, parameters, ...) {
    value <- original_make(data, rev(parameters), ...)
    evaluators[[length(evaluators) + 1L]] <<- value
    value
  }
  for (framework in c("CppAD", "TMBad")) {
    options(ALSCL.framework = framework)
    for (model in c("ACL", "ALSCL")) {
      fit <- fit_fixture(model)$result
      for (structure in c("group_year", "year")) {
        if (structure == "year") fit <- refit_model(fit, F_structure = "year")
        fit$obj <- NULL
        simulate_tracked <- function() {
          local_mocked_bindings(MakeADFun = tracked_make, .package = "TMB")
          simulate_fit(fit, nsim = 2, seed = 921, process = "resample")
        }
        evaluators <- list()
        simulated <- simulate_tracked()
        expect_length(evaluators, 1L)
        expect_null(evaluators[[1L]]$env$ADFun)
        expect_null(evaluators[[1L]]$env$ADGrad)
        setup <- .acl_preflight(fit$recipe$args, tolower(model))$setup
        info <- .acl_compile(model)
        for (one in simulated$simulations) {
          p <- c(one$truth$parameters, one$truth$random_effects)
          reference <- original_make(setup$data, p, DLL = info$dll_name, silent = TRUE)
          report <- reference$report(reference$par)
          for (name in c("N", "B", "SSB", "Rec", "CN", "NL", "NA", "Elog_index"))
            expect_identical(one$truth[[name]], report[[name]])
        }
      }
    }
  }
})
