plot_workflow_fixture <- function() {
  F <- matrix(c(.1, .2, .4, .3, .5, .8), 3L, 2L)
  list(model_type = "ALSCL", year = c(2001, 2002),
       len_mid = c(7.5, 15, 45), len_label = c("5-10", "10-20", "20-70"),
       report = list(FL = F),
       est_std = matrix(c(as.numeric(F), seq_len(6L) / 100), 6L, 2L,
                        dimnames = list(rep("FL", 6L), c("Estimate", "Std. Error"))))
}

test_that("comparison plots use the diagnostic observation mask and metrics", {
  observed <- matrix(c(10, NA, 0, 20, 30, 40), 3L, 2L)
  data <- data.frame(LengthBin = c("5-10", "10-20", "20-70"), observed)
  predicted <- matrix(c(8, 999, 999, 22, 27, 44), 3L, 2L)
  model <- list(report = list(Elog_index = log(predicted)),
                opt = list(par = c(a = 1, b = 2), objective = 10))
  expected <- diagnostic_metrics(data, model)
  display_names <- c(RMSE = "RMSE", MAE = "MAE", Rsquared = "R2",
                     MAPE = "MAPE", AIC = "AIC", BIC = "BIC")
  panels <- list(error = c("RMSE", "MAE"), R2 = "Rsquared", MAPE = "MAPE",
                 IC = c("AIC", "BIC"), npar = character())
  for (panel_name in names(panels)) {
    p <- plot_compare_metrics(model, model, data, metrics = panel_name,
                               model1_name = "Original", model2_name = "Shared F")
    panel <- if (inherits(p, "patchwork")) p[[1L]] else p
    plot_data <- panel$data
    expect_setequal(unique(plot_data$Model), c("Original", "Shared F"))
    expect_true(all(is.finite(plot_data$Metric_Value)))
    for (metric in panels[[panel_name]]) {
      expect_equal(plot_data$Metric_Value[plot_data$Metric_Name == display_names[[metric]]],
                   rep(expected$Value[expected$Metric == metric], 2L))
    }
    if (panel_name == "IC") {
      expect_equal(plot_data$Metric_Value[plot_data$Metric_Name == "Neg. Log-Likelihood"], c(10, 10))
    }
    if (panel_name == "npar") {
      expect_equal(plot_data$Metric_Value, c(2, 2))
    }
  }
  expect_error(plot_compare_metrics(model, model, data[1:2, ]), "dimensions differ")
  model$report$Elog_index[1L, 1L] <- Inf
  expect_error(plot_compare_metrics(model, model, data), "Predictions are non-finite")
})

test_that("length fishing-mortality plots use actual midpoints and facet by year", {
  model <- plot_workflow_fixture()
  out <- plot_fishing_mortality(model, type = "length", return_data = TRUE)
  expect_equal(out$data$Length, rep(model$len_mid, 2L))
  expect_equal(out$data$Year, rep(model$year, each = 3L))
  expect_equal(out$data$F, as.numeric(model$report$FL))
  built <- ggplot2::ggplot_build(out$plot)
  expect_equal(built$layout$layout$Year, model$year)
  expect_equal(built$data[[1L]]$x, rep(model$len_mid, 2L))
  expect_equal(built$data[[1L]]$y, as.numeric(model$report$FL))
  expect_equal(out$plot$labels$x, "Length")

  for (se_type in c("ribbon", "errorbar")) {
    out <- plot_fishing_mortality(model, type = "length", se = TRUE,
                                  se_type = se_type, return_data = TRUE)
    expect_equal(out$data$Length, rep(model$len_mid, 2L))
    expect_equal(out$data$estimate, as.numeric(model$report$FL))
    expect_equal(out$data$lower, model$est_std[, "Estimate"] - 1.96 * model$est_std[, "Std. Error"],
                 ignore_attr = TRUE)
    expect_equal(out$data$upper, model$est_std[, "Estimate"] + 1.96 * model$est_std[, "Std. Error"],
                 ignore_attr = TRUE)
    built <- ggplot2::ggplot_build(out$plot)
    expect_equal(built$layout$layout$Year, model$year)
    expect_equal(built$data[[2L]]$x, rep(model$len_mid, 2L))
    expect_equal(built$data[[2L]]$ymin, out$data$lower)
    expect_equal(built$data[[2L]]$ymax, out$data$upper)
  }
})

test_that("year fishing-mortality plots preserve time axes and length facets", {
  model <- plot_workflow_fixture()
  for (se in c(FALSE, TRUE)) {
    out <- plot_fishing_mortality(model, type = "year", se = se, return_data = TRUE)
    built <- ggplot2::ggplot_build(out$plot)
    expect_equal(length(unique(built$layout$layout$Group)), 3L)
    expect_equal(built$data[[1L]]$x, rep(model$year, 3L))
    expect_equal(built$data[[1L]]$y, as.numeric(t(model$report$FL)))
    expect_equal(out$plot$labels$x, "Year")
  }
})

test_that("length plots reject incomplete outputs and identify the legacy ACL alias", {
  model <- plot_workflow_fixture()
  model$len_mid <- NULL
  expect_error(plot_fishing_mortality(model, type = "length"), "finite numeric len_mid")
  model <- plot_workflow_fixture()
  model$est_std <- model$est_std[-1L, , drop = FALSE]
  expect_error(plot_fishing_mortality(model, type = "length", se = TRUE), "one FL estimate")
  model$report$F <- model$report$FL
  model$report$FL <- NULL
  expect_warning(out <- plot_fishing_mortality(model, type = "length", return_data = TRUE),
                 "ACL has no length-specific F")
  expected <- plot_fishing_mortality(model, type = "age", return_data = TRUE)
  expect_equal(out$data, expected$data)
  expect_equal(out$plot$labels$x, "Age Group")
})
