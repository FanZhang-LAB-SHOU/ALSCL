# Review finding F36: estimation tests with a realistic number of free
# parameters. The other fits in the suite estimate one or two fixed effects on
# data that the template generated without noise.
#
# The data are the bundled YTF_example survey, which sim_data() generated from
# the age-based operating model with observation error, and the fit uses the
# example's own configuration (five free fixed effects: log_init_Z,
# mean_log_R, log_std_log_R, mean_log_F and log_std_index, plus the random
# recruitment, F and first-period deviations). Only ACL is fitted here because
# it takes seconds; a comparable ALSCL fit takes minutes.

review_ytf_free <- c("log_init_Z", "mean_log_R", "log_std_log_R", "mean_log_F", "log_std_index")

test_that("ACL recovers the YTF_example truth within stated tolerances (F36)", {
  skip_on_cran()
  x <- YTF_example
  fit <- run_acl(x, silent = TRUE)
  truth <- x$truth

  expect_identical(names(fit$opt$par), review_ytf_free)
  expect_identical(fit$convergence_code, 0L)
  expect_true(fit$pdHess)
  expect_lt(fit$max_abs_gradient, 1e-4)
  expect_true(fit$diagnostics$numerical_ok)
  expect_length(fit$diagnostics$issues, 0L)

  # Tolerances are at least about twice the errors of this fit at base commit
  # 6b072b9 (given in the comments), so they allow optimizer and platform
  # differences but not a biased model.
  within <- function(estimate, true, lower, upper, label) {
    ratio <- as.numeric(estimate) / as.numeric(true)
    expect_true(all(is.finite(ratio)), label = paste(label, "finite"))
    expect_gt(min(ratio), lower, label = paste(label, "smallest estimate/truth ratio"))
    expect_lt(max(ratio), upper, label = paste(label, "largest estimate/truth ratio"))
  }
  within(fit$report$SSB, truth$SSB, .90, 1.15, "SSB")                 # 0.960 to 1.076
  within(fit$report$B, truth$TB, .90, 1.15, "total biomass")          # 0.955 to 1.070
  within(fit$report$N, truth$TN, .90, 1.16, "total numbers")          # 0.950 to 1.081
  within(fit$report$Rec, truth$Rec, .80, 1.30, "recruitment")         # 0.899 to 1.151
  within(fit$report$CN, truth$CN, .75, 1.45, "catch numbers")         # 0.865 to 1.221
  expect_lt(mean(abs(fit$report$SSB / truth$SSB - 1)), .05)           # 0.021
  expect_lt(mean(abs(fit$report$Rec / truth$Rec - 1)), .10)           # 0.040
  # Mean fishing mortality rate over ages and years.
  within(mean(fit$report$F), mean(truth$F_at_age), .90, 1.10, "mean F")              # 1.001
  # Standard deviation of the log survey index and initial total mortality.
  within(fit$report$std_index, x$parameters$std_SN, .90, 1.10, "survey index SD")     # 0.999
  within(exp(fit$opt$par[["log_init_Z"]]), x$parameters$init_Z, .80, 1.25, "init_Z")  # 0.981
  # Reported standard errors are finite and positive.
  ssb <- fit$est_std[rownames(fit$est_std) == "SSB", , drop = FALSE]
  expect_equal(nrow(ssb), length(truth$SSB))
  expect_true(all(is.finite(ssb[, "Std. Error"]) & ssb[, "Std. Error"] > 0))
  # Most true SSB values lie within two standard errors of the estimates
  # (19 of 20 at the base commit).
  covered <- abs(ssb[, "Estimate"] - truth$SSB) <= 2 * ssb[, "Std. Error"]
  expect_gte(mean(covered), .75)
})

test_that("multistart with five free parameters is identical on one and two workers (F36)", {
  skip_on_cran()
  # The first eight years keep each start under about one second.
  x <- YTF_example
  for (name in c("data.CatL", "data.wgt", "data.mat")) x[[name]] <- x[[name]][, 1:9]
  sequential <- run_acl(x, silent = TRUE, nstarts = 3, ncores = 1)
  concurrent <- run_acl(x, silent = TRUE, nstarts = 3, ncores = 2)

  # Jittered starts: start 1 is the configured start; the others move every
  # free parameter.
  initial <- lapply(sequential$starts, `[[`, "initial")
  expect_length(initial, 3L)
  expect_true(all(vapply(initial, function(v) identical(names(v), review_ytf_free), logical(1))))
  expect_true(all(initial[[2L]] != initial[[1L]]))
  expect_true(all(initial[[3L]] != initial[[1L]]))
  expect_true(all(initial[[3L]] != initial[[2L]]))

  # All starts converge to the same optimum, and the result passes the
  # numerical screen.
  objectives <- sequential$start_diagnostics$objective
  expect_identical(sequential$start_diagnostics$convergence, rep(0L, 3L))
  expect_lt(diff(range(objectives)), 1e-6)
  estimates <- do.call(rbind, lapply(sequential$starts, `[[`, "par"))
  expect_lt(max(apply(estimates, 2L, function(v) diff(range(v)))), 1e-4)
  expect_identical(sequential$opt$start_id, which.min(objectives))
  expect_true(sequential$diagnostics$numerical_ok)
  expect_identical(names(sequential$opt$par), review_ytf_free)
  truth <- YTF_example$truth$SSB[1:8]
  expect_gt(min(sequential$report$SSB / truth), .9)
  expect_lt(max(sequential$report$SSB / truth), 1.15)

  # Worker count must not change any number.
  expect_identical(sequential$workers, 1L)
  expect_identical(concurrent$workers, 2L)
  expect_length(unique(concurrent$start_diagnostics$pid), 2L)
  expect_false(Sys.getpid() %in% concurrent$start_diagnostics$pid)
  expect_identical(lapply(concurrent$starts, `[[`, "initial"), initial)
  expect_identical(lapply(concurrent$starts, `[[`, "par"),
                   lapply(sequential$starts, `[[`, "par"))
  expect_identical(concurrent$start_diagnostics$objective, objectives)
  expect_identical(concurrent$opt$par, sequential$opt$par)
  expect_identical(concurrent$opt$objective, sequential$opt$objective)
  expect_identical(concurrent$report, sequential$report)
  expect_identical(concurrent$est_std, sequential$est_std)
  expect_identical(concurrent$vcov, sequential$vcov)
  expect_identical(concurrent$gradient, sequential$gradient)
})
