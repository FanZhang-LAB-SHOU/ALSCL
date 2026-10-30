test_that("survey plots align named and unnamed matrices to the fitted calendar", {
  for (model in c("ACL", "ALSCL")) {
    fit <- fit_fixture(model)$result
    for (type in c("length", "year")) for (original_scale in c(FALSE, TRUE)) {
      reference <- plot_CatL(fit, type = type, exp_transform = original_scale,
                             return_data = TRUE)
      named <- fit
      dimnames(named$report$Elog_index) <- list(fit$len_label, as.character(fit$year))
      dimnames(named$observations) <- list(paste0("row_", seq_along(fit$len_label)),
                                         paste0("period_", seq_along(fit$year)))
      result <- plot_CatL(named, type = type, exp_transform = original_scale,
                          return_data = TRUE)
      expect_equal(result$data1, reference$data1)
      expect_equal(result$data2, reference$data2)
      named$report$Elog_index <- as.data.frame(named$report$Elog_index)
      dimnames(named$observations) <- NULL
      result <- plot_CatL(named, type = type, exp_transform = original_scale,
                          return_data = TRUE)
      expect_equal(result$data1, reference$data1)
      expect_equal(result$data2, reference$data2)
      expect_no_warning(ggplot2::ggplot_build(result$plot))
      if (type == "length") {
        expect_equal(sort(unique(result$data1$Year)), fit$year)
        expect_equal(sort(unique(result$data2$Year)), fit$year)
        expected <- if (original_scale) exp(fit$report$Elog_index) else fit$report$Elog_index
        expect_equal(result$data1$Count, as.numeric(expected))
      } else {
        expected <- if (original_scale) exp(fit$report$Elog_index) else fit$report$Elog_index
        expect_equal(result$data1$Abundance, as.numeric(t(expected)))
      }
    }
  }
})

test_that("survey plots preserve missing observations and decimal calendar metadata", {
  fit <- list(observations = matrix(c(1, NA, 0, 2, 4, 8), 2L, 3L),
    report = list(Elog_index = matrix(log(1:6), 2L, 3L)),
    year = 1990 + (0:2)/4, len_mid = c(10, 20), len_label = c("5-15", "15-25"))
  for (type in c("length", "year")) {
    result <- plot_CatL(fit, type = type, exp_transform = TRUE, return_data = TRUE)
    values <- if (type == "length") result$data2$Count else result$data2$Abundance
    expect_equal(sum(is.na(values)), 2L)
    expect_equal(sort(values[!is.na(values)]), c(1, 2, 4, 8))
    if (type == "length") expect_equal(unique(result$data2$Year), fit$year)
    else expect_equal(levels(result$data2$year), paste("Year", fit$year))
    # The fallback for old results uses their explicit observation mask.
    legacy <- fit
    legacy$observations <- NULL
    legacy$obj <- list(env = list(.data = list(logN_at_len = log(fit$observations),
      na_matrix = is.finite(fit$observations) & fit$observations > 0)))
    expect_equal(plot_CatL(legacy, type = type, exp_transform = TRUE,
                           return_data = TRUE)$data2, result$data2)
  }
  single <- fit
  single$year <- fit$year[1L]
  single$observations <- fit$observations[, 1L, drop = FALSE]
  single$report$Elog_index <- fit$report$Elog_index[, 1L, drop = FALSE]
  expect_equal(plot_CatL(single, return_data = TRUE)$data1$Year, rep(fit$year[1L], 2L))
})

test_that("survey plotting validates alignment and finite transformed predictions", {
  fit <- list(observations = matrix(10, 2L, 3L),
    report = list(Elog_index = matrix(log(10), 2L, 3L)),
    year = 2000:2002, len_mid = c(10, 20), len_label = c("5-15", "15-25"))
  for (type in c("length", "year")) {
    for (bad in list(NA, numeric(), c(TRUE, FALSE), 1))
      expect_error(plot_CatL(fit, type = type, exp_transform = bad), "exp_transform")
    changed <- fit; changed$report$Elog_index <- matrix(0, 2L, 2L)
    expect_error(plot_CatL(changed, type = type), "matching dimensions")
    changed <- fit; changed$report$Elog_index[1L] <- Inf
    expect_error(plot_CatL(changed, type = type), "finite values")
    changed <- fit; changed$year <- 1:2
    expect_error(plot_CatL(changed, type = type), "year metadata")
    changed <- fit; changed$report$Elog_index[1L] <- 1000
    expect_error(plot_CatL(changed, type = type, exp_transform = TRUE), "Exponential transformation")
    expect_s3_class(plot_CatL(changed, type = type), "ggplot")
  }
  changed <- fit; changed$len_label <- c("same", "same")
  expect_error(plot_CatL(changed), "Length labels")
  changed <- fit; changed$len_mid <- c(20, 10)
  expect_error(plot_CatL(changed, type = "year"), "Length midpoints")
})

test_that("residual caps cannot reverse or erase the diagnostic", {
  fit <- list(observations = matrix(10, 2L, 3L),
    report = list(resid_index = matrix(c(-2, -1, 0, .1, 1, 2), 2L, 3L)),
    year = 2000:2002, len_mid = c(10, 20), len_label = c("5-15", "15-25"))
  for (type in c("length", "year")) {
    for (bad in list(-1, 0, NA_real_, Inf, numeric(), c(.1, .2), "0.1"))
      expect_error(plot_residuals(fit, type = type, resid_cap = bad), "resid_cap")
    reference <- plot_residuals(fit, type = type, return_data = TRUE)$data
    expect_message(result <- plot_residuals(fit, type = type, resid_cap = .5,
      return_data = TRUE), "4 residual")
    expect_equal(result$data$residual, pmax(-.5, pmin(.5, reference$residual)))
  }
})
