drop_timing <- function(st) {
  st$replicates$elapsed <- NULL
  st$settings$elapsed <- NULL
  st$settings$workers <- NULL
  st
}

test_that("self_test computes relative errors against the simulated truth of each replicate", {
  for (model in c("ACL", "ALSCL")) {
    fit <- fit_fixture(model)$result
    st <- self_test(fit, nsim = 3, seed = 11, process = "resample", save_fits = TRUE)
    expect_s3_class(st, "alscl_self_test")
    expect_equal(nrow(st$replicates), 3L)
    expect_equal(nrow(st$series), 3L * 3L * length(fit$year))
    expect_equal(st$screen$n_passed, sum(st$replicates$numerical_ok))

    # Independent calculation: the same simulation, ordinary refits and the
    # relative errors written out by hand.
    sims <- simulate_fit(fit, nsim = 3, seed = 11, process = "resample")
    refit_fun <- if (model == "ACL") run_acl else run_alscl
    F_name <- if (model == "ACL") "F" else "FL"
    for (i in seq_along(sims$simulations)) {
      s <- sims$simulations[[i]]
      id <- names(sims$simulations)[i]
      refit <- refit_fun(s$x, silent = TRUE)
      expect_equal(unname(refit$opt$par), unname(st$fits[[id]]$opt$par))
      expected <- list(SSB = (refit$report$SSB - s$truth$SSB) / s$truth$SSB,
                       Rec = (refit$report$Rec - s$truth$Rec) / s$truth$Rec,
                       F = (colMeans(refit$report[[F_name]]) - colMeans(s$truth$F)) / colMeans(s$truth$F))
      for (q in names(expected)) {
        rows <- st$series[st$series$replicate == id & st$series$quantity == q, ]
        expect_equal(rows$relative_error, as.numeric(expected[[q]]), tolerance = 1e-10)
        expect_equal(rows$truth, as.numeric(if (q == "F") colMeans(s$truth$F) else s$truth[[q]]))
      }
      true_R <- exp(s$truth$parameters$mean_log_R)
      row <- st$parameters[st$parameters$replicate == id & st$parameters$parameter == "mean_log_R", ]
      expect_equal(row$truth, true_R)
      expect_equal(row$relative_error, (exp(refit$opt$par[["mean_log_R"]]) - true_R) / true_R,
                   tolerance = 1e-10)
    }
    # Resampled populations differ between replicates; the scalar truth does not.
    ssb <- split(st$series$truth[st$series$quantity == "SSB"],
                 st$series$replicate[st$series$quantity == "SSB"])
    expect_false(isTRUE(all.equal(ssb[[1]], ssb[[2]])))
    expect_equal(length(unique(st$parameters$truth)), 1L)
  }
})

test_that("conditional truth is the fitted population and summaries use passing refits", {
  fit <- fit_fixture("ACL")$result
  st <- self_test(fit, nsim = 3, seed = 3, quantities = c("SSB", "F"), F_summary = "apical")
  ssb <- st$series[st$series$quantity == "SSB", ]
  expect_equal(ssb$truth, rep(as.numeric(fit$report$SSB), 3))
  F_truth <- st$series$truth[st$series$quantity == "F"]
  expect_equal(F_truth, rep(apply(fit$report[["F"]], 2, max), 3))
  expect_setequal(unique(st$series$quantity), c("SSB", "F"))
  # Lognormal intervals and coverage
  ok <- is.finite(ssb$std_error)
  expect_true(any(ok))
  z <- stats::qnorm(.975)
  expect_equal(ssb$conf_low[ok], ssb$estimate[ok] * exp(-z * ssb$std_error[ok] / ssb$estimate[ok]))
  expect_equal(ssb$covered[ok], ssb$truth[ok] >= ssb$conf_low[ok] & ssb$truth[ok] <= ssb$conf_high[ok])
  expect_true(all(is.na(st$series$covered[st$series$quantity == "F"])))
  # Summaries by year and pooled over years
  y1 <- ssb[ssb$year == fit$year[1] & ssb$numerical_ok, ]
  row <- st$by_year[st$by_year$quantity == "SSB" & st$by_year$year == fit$year[1], ]
  expect_equal(row$median_relative_error, stats::median(y1$relative_error))
  expect_equal(row$q90_relative_error, unname(stats::quantile(y1$relative_error, .9)))
  pooled <- st$series_summary[st$series_summary$quantity == "SSB", ]
  expect_equal(pooled$median_absolute_relative_error, stats::median(abs(ssb$relative_error[ssb$numerical_ok])))
  expect_equal(pooled$coverage, mean(ssb$covered[ssb$numerical_ok & !is.na(ssb$covered)]))
  wald <- self_test(fit, nsim = 1, seed = 3, quantities = "SSB", interval = "wald")
  w <- wald$series
  expect_equal(w$conf_high, w$estimate + z * w$std_error)
})

test_that("self_test is reproducible with a seed and the same with one and two workers", {
  fit <- fit_fixture("ALSCL")$result
  a <- self_test(fit, nsim = 3, seed = 5, process = "resample")
  b <- self_test(fit, nsim = 3, seed = 5, process = "resample")
  expect_identical(drop_timing(a), drop_timing(b))
  parallel <- self_test(fit, nsim = 3, seed = 5, process = "resample", ncores = 2)
  expect_equal(parallel$settings$workers, 2L)
  expect_identical(drop_timing(parallel), drop_timing(a))
  other <- self_test(fit, nsim = 3, seed = 6, process = "resample")
  expect_false(identical(other$series$truth, a$series$truth))
})

test_that("start chooses the starting values of the refits", {
  fixture <- fit_fixture("ACL")
  fit <- fixture$result
  original <- self_test(fit, nsim = 1, seed = 2, save_fits = TRUE)
  estimates <- self_test(fit, nsim = 1, seed = 2, start = "estimates", nstarts = 2,
                         save_fits = TRUE)
  expect_equal(original$fits[[1]]$recipe$args$parameters$mean_log_R, fixture$parameters$mean_log_R)
  expect_equal(estimates$fits[[1]]$recipe$args$parameters$mean_log_R, unname(fit$opt$par[["mean_log_R"]]))
  expect_equal(original$settings$nstarts, 1L)
  expect_equal(estimates$settings$nstarts, 2L)
  expect_equal(estimates$fits[[1]]$nstarts, 2)
  expect_null(original$fits[[1]]$obj)
  expect_null(self_test(fit, nsim = 1, seed = 2)$fits)
})

test_that("legacy, failed and unscreened fits give clear errors", {
  fit <- fit_fixture("ACL")$result
  legacy <- fit; legacy$recipe <- NULL
  expect_error(self_test(legacy, nsim = 1), "no recipe")
  expect_error(self_test(ALSCL:::.acl_fit_error("optimizer stopped"), nsim = 1),
               "failed fit \\(optimizer stopped\\)")
  failed <- fit; failed$diagnostics$numerical_ok <- FALSE
  expect_error(self_test(failed, nsim = 1), "fails the numerical checks")
  expect_error(self_test(fit, nsim = 1, quantities = "Z"), "quantities must contain")
  expect_error(self_test(fit, nsim = 0), "nsim must be an integer")
  expect_error(self_test(fit, nsim = 1, conf_level = 1), "conf_level")
})

test_that("print, summary and plot_self_test describe the self-test", {
  fit <- fit_fixture("ALSCL")$result
  st <- self_test(fit, nsim = 3, seed = 4)
  expect_output(print(st), "Self-test of ALSCL: 3 data sets")
  expect_output(print(st), "mean over length bins")
  s <- summary(st)
  expect_s3_class(s, "summary.alscl_self_test")
  expect_named(s, c("settings", "screen", "series_summary", "parameter_summary", "failures"))

  p <- plot_self_test(st)
  expect_s3_class(p, "patchwork")
  expect_silent(ggplot2::ggplot_build(p[[1]]))
  out <- plot_self_test(st, what = "series", probs = c(.25, .75), return_data = TRUE)
  expect_s3_class(out$plot, "ggplot")
  expect_null(out$parameters)
  d <- st$series[st$series$quantity == "SSB" & st$series$year == fit$year[2] & st$series$numerical_ok, ]
  row <- out$series[out$series$quantity == "SSB" & out$series$year == fit$year[2], ]
  expect_equal(row$median_re, 100 * stats::median(d$relative_error))
  expect_equal(row$low_re, 100 * unname(stats::quantile(d$relative_error, .25)))
  expect_match(gsub("\\s+", " ", out$plot$labels$subtitle), "25th to 75th percentiles")
  expect_identical(out$plot$labels$y, "Relative error (%)")
  pars <- plot_self_test(st, what = "parameters")
  expect_s3_class(pars, "ggplot")
  expect_error(plot_self_test(fit), "result of self_test")
  expect_error(plot_self_test(st, probs = c(.9, .1)), "probs must be")
  none <- st; none$replicates$numerical_ok <- FALSE
  expect_error(plot_self_test(none), "No refit passes")
  expect_equal(ALSCL:::.acl_percentile_label(c(.1)), "10th")
  expect_equal(ALSCL:::.acl_percentile_label(.01), "1st")
  expect_equal(ALSCL:::.acl_percentile_label(.025), "2.5th")
})
