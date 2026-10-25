missing_lag_fixture <- function() {
  observed <- matrix(c(10, NA, 0, NA, NA, NA, 20, 40, 60), 3L, 3L)
  mask <- is.finite(observed) & observed > 0
  observed_log <- matrix(0, 3L, 3L)
  observed_log[mask] <- log(observed[mask])
  residual <- matrix(seq_len(9L) / 10, 3L, 3L)
  residual[!mask] <- 0
  list(observations = observed, year = c(2000, 2000.25, 2000.5),
       growth_step = .25, len_mid = c(10, 20, 30), len_label = c("5-15", "15-25", "25-35"),
       obj = list(env = list(.data = list(logN_at_len = observed_log, na_matrix = mask * 1))),
       report = list(Elog_index = matrix(log(seq_len(9L) + 10), 3L, 3L),
                     resid_index = residual))
}

test_that("ridge observations exclude missing periods and zero observations in portable fits", {
  testthat::local_mocked_bindings(plot_grid = function(...) list(...), .package = "cowplot")
  fit <- missing_lag_fixture()
  fit$obj <- NULL
  panels <- plot_ridges(fit, ridges_scale = 1)
  observed <- panels[[1L]]$data
  expected <- matrix(c(1, NA, NA, NA, NA, NA, 1/6, 1/3, 1/2), 3L, 3L)
  expect_equal(observed$Abundance, as.vector(t(expected)))
  expect_true(all(is.na(observed$Abundance[observed$year == "2000.25"])))
  expect_equal(levels(observed$year), as.character(fit$year))
  expect_false(panels[[1L]]$scales$get_scales("y")$drop)
  expect_true(all(is.finite(panels[[2L]]$data$Abundance)))
  expect_equal(as.numeric(tapply(panels[[2L]]$data$Abundance,
                                 panels[[2L]]$data$year, sum)), rep(1, 3L))

  # An older fit still uses its explicit mask, never exp(0) placeholders.
  legacy <- missing_lag_fixture()
  legacy$observations <- NULL
  legacy_panels <- plot_ridges(legacy, ridges_scale = 1)
  expect_equal(legacy_panels[[1L]]$data, observed)

  # The portable observations remain authoritative if the TMB data are stale.
  fit$obj <- legacy$obj
  fit$obj$env$.data$na_matrix[] <- 1
  expect_equal(plot_ridges(fit, ridges_scale = 1)[[1L]]$data, observed)
})

test_that("ridge auto scaling and rendering tolerate an entirely missing period", {
  fit <- missing_lag_fixture()
  fit$obj <- NULL
  expect_no_warning(ggplot2::ggplot_build(plot_ridges(fit)))
  fit$observations[,] <- NA_real_
  expect_no_warning(ggplot2::ggplot_build(plot_ridges(fit)))
  fit$observations <- NULL
  expect_error(plot_ridges(fit), "Observed data are unavailable")
})

test_that("residual plots apply the same missing mask after removing the live object", {
  fit <- missing_lag_fixture()
  original <- lapply(c("length", "year"), function(type) {
    plot_residuals(fit, type = type, return_data = TRUE)$data
  })
  fit$obj <- NULL
  for (i in seq_along(original)) {
    type <- c("length", "year")[[i]]
    out <- plot_residuals(fit, type = type, return_data = TRUE)
    expect_equal(out$data, original[[i]])
    expect_equal(sum(is.na(out$data$residual)), 5L)
    expect_equal(sort(out$data$residual[!is.na(out$data$residual)]), c(.1, .7, .8, .9))
  }
  length_data <- original[[1L]]
  expect_true(all(is.na(length_data$residual[length_data$year == 2000.25])))
  legacy <- missing_lag_fixture()
  legacy$observations <- NULL
  expect_equal(plot_residuals(legacy, return_data = TRUE)$data, original[[1L]])
  fit$report$resid_index <- fit$report$resid_index[-1L, , drop = FALSE]
  expect_error(plot_residuals(fit), "matrix dimensions differ")
})

test_that("observation extraction preserves genuine log-zero observations and rejects mismatches", {
  fit <- missing_lag_fixture()
  fit$observations[1L, 1L] <- 1
  expect_equal(ALSCL:::.acl_observed_log(fit)[1L, 1L], 0)
  expect_equal(sum(is.na(ALSCL:::.acl_observed_log(fit))), 5L)
  fit$report$resid_index[1L, 1L] <- 0
  fit$obj <- NULL
  expect_equal(plot_residuals(fit, return_data = TRUE)$data$residual[1L], 0)
  catl <- plot_CatL(fit, type = "year", exp_transform = TRUE, return_data = TRUE)
  expect_equal(sum(is.na(catl$data2$Abundance)), 5L)
  expect_equal(catl$data2$Abundance[1L], 1)
  fit <- missing_lag_fixture()
  fit$observations <- NULL
  fit$obj$env$.data$na_matrix <- matrix(1, 2L, 3L)
  expect_error(ALSCL:::.acl_observed_log(fit), "mask dimensions differ")
})

test_that("SSB recruitment alignment converts recruitment years to model periods", {
  fit <- list(report = list(SSB = seq_len(8L), Rec = 101:108),
              growth_step = .25, year = 2000 + (0:7) / 4)
  quarter <- plot_SSB_Rec(fit, age_at_recruitment = .25, return_data = TRUE)$data
  expect_equal(quarter$SSB, 1:7)
  expect_equal(quarter$Rec, 102:108)
  year <- plot_SSB_Rec(fit, return_data = TRUE)$data
  expect_equal(year$SSB, 1:4)
  expect_equal(year$Rec, 105:108)
  same_period <- plot_SSB_Rec(fit, age_at_recruitment = 0, return_data = TRUE)$data
  expect_equal(same_period$SSB, 1:8)
  expect_equal(same_period$Rec, 101:108)
  fit$growth_step <- NULL
  expect_equal(plot_SSB_Rec(fit, age_at_recruitment = .25, return_data = TRUE)$data, quarter)

  # Legacy annual results and positional calls retain the one-period default.
  fit$year <- 2000:2007
  expect_equal(plot_SSB_Rec(fit, 1, return_data = TRUE)$data, quarter)
  fit$year <- NULL
  expect_equal(plot_SSB_Rec(fit, return_data = TRUE)$data, quarter)
})

test_that("SSB recruitment alignment validates age, resolution, and metadata", {
  fit <- list(report = list(SSB = seq_len(8L), Rec = 101:108),
              growth_step = .25, year = 2000 + (0:7) / 4)
  for (age in list(-1, NA_real_, Inf, c(.25, .5), "1"))
    expect_error(plot_SSB_Rec(fit, age_at_recruitment = age), "finite, nonnegative")
  expect_error(plot_SSB_Rec(fit, .3), "exact multiple of growth_step")
  expect_error(plot_SSB_Rec(fit, 2), "too large")
  fit$growth_step <- 0
  expect_error(plot_SSB_Rec(fit), "finite, positive")
  fit$growth_step <- 1
  expect_error(plot_SSB_Rec(fit), "spacing must equal growth_step")
  fit$growth_step <- .25
  fit$year[3L] <- NA_real_
  expect_error(plot_SSB_Rec(fit), "increasing, finite year")
  fit$year <- NULL
  fit$report$Rec <- fit$report$Rec[-1L]
  expect_error(plot_SSB_Rec(fit), "equal, nonzero length")
})
