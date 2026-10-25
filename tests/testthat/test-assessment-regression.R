# Exercise the parameter maps used by assessments, rather than fixing every
# scalar except recruitment. The small series deliberately has limited
# information about variance/correlation parameters: a returned fit must not be
# labelled numerically sound merely because its objective and predictions exist.
# These are numerical/API regressions, not a parameter-recovery experiment.
assessment_regression_input <- function(model, quarterly = FALSE) {
  withr::local_seed(223, .rng_kind = "Mersenne-Twister",
                   .rng_normal_kind = "Inversion")
  step <- if (quarterly) .25 else 1
  L <- 9L; Y <- 12L; A <- 8L
  mid <- seq(6, 54, 6)
  frames <- data.frame(LengthBin = as.character(mid), matrix(100, L, Y),
                       check.names = FALSE)
  names(frames) <- c("LengthBin", as.character(2000 + (seq_len(Y) - 1)*step))
  weight <- maturity <- frames
  weight[-1] <- (mid/30)^3
  maturity[-1] <- plogis((mid - 27)/6)
  x <- list(data.CatL = frames, data.wgt = weight, data.mat = maturity,
    rec.age = step, nage = A, M = .2*step, growth_step = step,
    sel_L50 = 12, sel_L95 = 24)

  p <- create_parameters(tolower(model))$parameters
  p$log_Linf <- log(60)
  p$log_vbk <- log(if (quarterly) .65 else .35)
  p$mean_log_R <- log(200)
  p$mean_log_F <- log(.3*step)
  p$log_init_Z <- log(.5*step)
  p$logit_log_R <- qlogis(.4)
  p$logit_log_F_y <- qlogis(.5)
  sd_prefix <- if (model == "ACL") "log_std" else "log_sigma"
  p[[paste0(sd_prefix, "_index")]] <- log(.12)
  p[[paste0(sd_prefix, "_log_N0")]] <- log(.5)
  p[[paste0(sd_prefix, "_log_R")]] <- log(.3)
  p[[paste0(sd_prefix, "_log_F")]] <- log(.3)
  p[[if (model == "ACL") "logit_log_F_a" else "logit_log_F_l"]] <- qlogis(.5)
  p$log_cv_len <- log(.2)
  if (model == "ALSCL") p$log_cv_grow <- log(.2)

  prepared <- do.call(.acl_prepare_data, x)
  d <- prepared$data
  if (model == "ALSCL") {
    d$len_mid <- prepared$bins$mid
    d$len_lower <- prepared$bins$lower
    d$len_upper <- prepared$bins$upper
    d$growth_step <- step
  }
  parameters <- p
  parameters$dev_log_R <- as.numeric(stats::arima.sim(list(ar = .4),
    n = Y, sd = .3*sqrt(1 - .4^2)))
  groups <- if (model == "ACL") A else L
  group_chol <- chol(.5^abs(outer(seq_len(groups), seq_len(groups), "-")))
  year_chol <- chol(.5^abs(outer(seq_len(Y), seq_len(Y), "-")))
  parameters$dev_log_F <- t(group_chol) %*%
    matrix(rnorm(groups*Y, 0, .3), groups, Y) %*% year_chol
  parameters$dev_log_N0 <- rnorm(A - 1, 0, .5)
  info <- .acl_compile(model)
  generating_model <- TMB::MakeADFun(d, parameters, DLL = info$dll_name,
                                    silent = TRUE)
  expected_log_index <- generating_model$report(generating_model$par)$Elog_index
  x$data.CatL[-1] <- exp(expected_log_index + matrix(rnorm(L*Y, 0, .12), L, Y))
  if (quarterly) {
    x$data.CatL[2, 3] <- NA_real_
    x$data.CatL[7, 6] <- NA_real_
    # Named NULL entries release the default fixes; only t0 stays fixed.
    x$map <- if (model == "ACL") {
      list(t0 = factor(NA), log_std_log_F = NULL,
           logit_log_F_y = NULL, logit_log_F_a = NULL)
    } else list(log_t0 = factor(NA), log_sigma_log_F = NULL)
  }
  x$parameters <- p
  x
}

for (model in c("ACL", "ALSCL")) {
  for (quarterly in c(FALSE, TRUE)) {
    for (structure in c("group_year", "year")) {
      test_that(paste(model, structure, "fits with",
        if (quarterly) "only t0 fixed, quarterly steps and missing observations"
        else "the default assessment map"), {
        withr::local_options(ALSCL.framework = "CppAD", ALSCL.sd_cores = 1L)
        x <- assessment_regression_input(model, quarterly)
        fit_fun <- if (model == "ACL") run_acl else run_alscl
        nan_warning <- FALSE
        fit <- withCallingHandlers(fit_fun(x, F_structure = structure, silent = TRUE),
          warning = function(w) {
            # A singular covariance may emit this warning on some BLAS/TMB
            # builds. Permit only this known warning and verify the failed
            # numerical screen below; all other warnings remain test failures.
            if (identical(conditionMessage(w), "NaNs produced")) {
              nan_warning <<- TRUE
              invokeRestart("muffleWarning")
            }
          })

        expected_free <- if (model == "ACL") {
          if (quarterly) 13L else 10L
        } else if (quarterly) 14L else 13L
        if (structure == "year" && (quarterly || model == "ALSCL"))
          expected_free <- expected_free - 1L
        expect_length(fit$opt$par, expected_free)
        expect_false(any(c("t0", "log_t0") %in% names(fit$opt$par)))
        expect_true(all(c("log_vbk", "log_Linf", "mean_log_F", "mean_log_R") %in%
                          names(fit$opt$par)))
        if (quarterly) expect_true(
          (if (model == "ACL") "log_std_log_F" else "log_sigma_log_F") %in%
            names(fit$opt$par))
        initial <- unlist(x$parameters[names(fit$opt$par)])
        expect_gte(sum(abs(fit$opt$par - initial) > 1e-4), 5L)
        expect_true(is.finite(fit$opt$objective))
        expect_true(all(is.finite(fit$gradient)))
        expect_lte(fit$refinement$final_objective,
                   fit$refinement$initial_objective + 1e-6)
        expect_equal(diff(fit$year), rep(x$growth_step, 11))
        expect_equal(diff(fit$age), rep(x$growth_step, 7))
        expect_equal(sum(is.na(fit$observations)), if (quarterly) 2L else 0L)
        expect_true(all(is.finite(fit$report$Elog_index)))

        ssb <- fit$report$SSB
        fishing <- fit$report[[if (model == "ACL") "F" else "FL"]]
        expect_true(all(is.finite(ssb) & ssb > 0))
        expect_true(all(is.finite(fishing) & fishing > 0))
        # Independently aggregate fitted abundance using the supplied biology.
        expect_equal(ssb, unname(colSums(fit$report$NL * as.matrix(x$data.wgt[-1]) *
          as.matrix(x$data.mat[-1]))), tolerance = 1e-10)
        expect_equal(dim(fishing), c(if (model == "ACL") 8L else 9L, 12L))
        expected_rows <- if (structure == "year") 1L else nrow(fishing)
        expect_equal(dim(fit$report$dev_log_F), c(expected_rows, 12L))
        if (structure == "year") expect_equal(
          apply(fishing, 2, function(v) diff(range(v))), rep(0, 12))

        # The public report must refer to the selected optimum, even after
        # standard errors have perturbed the TMB tape for Hessian evaluation.
        value <- fit$obj$fn(fit$opt$par)
        synchronized <- fit$obj$report()
        expect_equal(value, fit$opt$objective, tolerance = 1e-6)
        expect_equal(synchronized$SSB, ssb, tolerance = 1e-6)
        expect_equal(synchronized[[if (model == "ACL") "F" else "FL"]],
                     fishing, tolerance = 1e-6)

        # This short-series fixture has at least one poorly informed process
        # SD/correlation. Preserve that finding instead of certifying its fit.
        expect_true(fit$diagnostics$natural_boundary)
        expect_true(any(fit$diagnostics$natural_parameters$near_boundary))
        expect_false(fit$diagnostics$numerical_ok)
        expect_true("natural-scale boundary" %in% fit$diagnostics$issues)
        if (nan_warning) expect_false(fit$diagnostics$numerical_ok)
      })
    }
  }
}
