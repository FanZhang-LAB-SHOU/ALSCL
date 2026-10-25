comparison_plot_fixture_224 <- function(year = 2000:2003, structure = "group_year") {
  observed <- matrix(seq_len(3L * length(year)) + 10, 3L, length(year))
  predicted <- observed * rep(c(.9, 1, 1.1), length(year))
  F <- matrix(seq_len(length(observed)) / 100, 3L, length(year),
              dimnames = list(c("small", "medium", "large"), paste0("period", year)))
  ssb <- seq_along(year) * 100
  list(model_type = "ALSCL", F_structure = structure,
       year = year, len_mid = c(7.5, 15, 45),
       len_label = c("5-10", "10-20", "20-70"), observations = observed,
       report = list(FL = F, SSB = ssb, Elog_index = log(predicted),
                     resid_index = log(observed) - log(predicted),
                     Linf = 90, vbk = .2, t0 = .1, pla = matrix(1/3, 3L, 4L)),
       est_std = matrix(c(ssb, seq_along(ssb)), length(ssb), 2L,
                        dimnames = list(rep("SSB", length(ssb)), c("Estimate", "Std. Error"))),
       opt = list(par = c(a = 1, b = 2), objective = 10),
       obj = list(env = list(data = list(log_q = log(c(.2, .5, .9))))))
}

comparison_plot_data_224 <- function(model) {
  data <- data.frame(LengthBin = model$len_label, model$observations,
                    check.names = FALSE)
  names(data)[-1L] <- as.character(model$year)
  data
}

# Include the last panel stored at the top level and any nested patchwork panels.
comparison_panel_data_224 <- function(p) {
  out <- if (is.data.frame(p$data)) list(p$data) else list()
  if (inherits(p, "patchwork")) {
    for (child in p$patches$plots) out <- c(out, comparison_panel_data_224(child))
  }
  out
}

comparison_plot_calls_224 <- function(m1, m2, data, extra = list()) {
  functions <- list(plot_compare_ts, plot_compare_F, plot_compare_residuals,
                    plot_compare_growth, plot_compare_CatL, plot_compare_metrics,
                    plot_compare_selectivity, plot_compare_annual_F)
  lapply(seq_along(functions), function(i) {
    args <- c(list(model1 = m1, model2 = m2), extra)
    if (i %in% c(3L, 5L, 6L)) args$data.CatL <- data
    if (i == 1L) args$quantities <- "SSB"
    do.call(functions[[i]], args)
  })
}

test_that("all comparison plots keep same-model fits in distinct groups", {
  m1 <- comparison_plot_fixture_224()
  m2 <- comparison_plot_fixture_224(structure = "year")
  data <- comparison_plot_data_224(m1)
  checks <- list(
    list(extra = list(), expected = c("ALSCL (group_year)", "ALSCL (year)")),
    list(extra = list(model1_name = "Baseline", model2_name = "Common F"),
         expected = c("Baseline", "Common F")),
    list(extra = list(model1_name = "ALSCL"), expected = c("ALSCL", "ALSCL (2)")))
  for (check in checks) {
    plots <- comparison_plot_calls_224(m1, m2, data, check$extra)
    for (p in plots) {
      panels <- comparison_panel_data_224(p)
      labels <- unique(unlist(lapply(panels, function(d) {
        if ("Model" %in% names(d)) as.character(d$Model)
        else if ("Source" %in% names(d)) setdiff(d$Source, "Observed")
      })))
      expect_setequal(labels, check$expected)
    }
  }
  acl1 <- m1; acl2 <- m2
  acl1$model_type <- "ACL"; acl2$model_type <- "ACL"
  acl1$report$F <- acl1$report$FL; acl1$report$FL <- NULL
  acl2$report$F <- acl2$report$FL; acl2$report$FL <- NULL
  for (p in comparison_plot_calls_224(acl1, acl2, data)) {
    labels <- unique(unlist(lapply(comparison_panel_data_224(p), function(d) {
      if ("Model" %in% names(d)) as.character(d$Model)
      else if ("Source" %in% names(d)) setdiff(d$Source, "Observed")
    })))
    expect_setequal(labels, c("ACL (group_year)", "ACL (year)"))
  }
  ts <- plot_compare_ts(m1, m1, quantities = "SSB", return_data = TRUE)
  expect_setequal(ts$data$Model, c("ALSCL (1)", "ALSCL (2)"))
  expect_length(unique(ggplot2::ggplot_build(ts$plot)$data[[1L]]$group), 2L)
  heatmap <- plot_compare_F(m1, m2)
  expect_length(unique(ggplot2::ggplot_build(heatmap)$layout$layout$Model), 2L)
  for (fun in list(plot_compare_ts, plot_compare_F, plot_compare_annual_F)) {
    expect_error(fun(m1, m2, model1_name = "Same", model2_name = "Same"),
                 "must be distinct")
  }
})

test_that("time-series and F plots preserve each fit's calendar and dimensions", {
  m1 <- comparison_plot_fixture_224()
  m2 <- comparison_plot_fixture_224(year = 2010 + (0:4) / 4, structure = "year")
  ts <- plot_compare_ts(m1, m2, quantities = "SSB", se = TRUE, return_data = TRUE)
  expect_equal(ts$data$Year, c(m1$year, m2$year))
  expect_equal(ts$data$Value, c(m1$report$SSB, m2$report$SSB))
  ribbon <- ts$plot$layers[[2L]]$data
  expect_equal(ribbon$Year, c(m1$year, m2$year))
  expect_equal(ribbon$upper,
               c(m1$est_std[, 1L] + 1.96 * m1$est_std[, 2L],
                 m2$est_std[, 1L] + 1.96 * m2$est_std[, 2L]), ignore_attr = TRUE)
  expect_silent(ggplot2::ggplot_build(ts$plot))

  for (method in c("mean", "apical")) {
    p <- plot_compare_annual_F(m1, m2, method = method)
    expect_equal(p$labels$title, "Fishing Mortality by Time Step")
    expect_equal(p$data$Year, c(m1$year, m2$year))
    summary <- function(m) if (method == "mean") colMeans(m$report$FL)
                           else apply(m$report$FL, 2L, max)
    expect_equal(p$data$MeanF, unname(c(summary(m1), summary(m2))))
    expect_length(unique(ggplot2::ggplot_build(p)$data[[1L]]$group), 2L)
  }
  heatmap <- plot_compare_F(m1, m2)
  expect_equal(heatmap$data$Year, rep(c(m1$year, m2$year), each = 3L))
  expect_equal(heatmap$data$F_value, c(as.numeric(m1$report$FL), as.numeric(m2$report$FL)))
  expect_silent(ggplot2::ggplot_build(heatmap))

  m2$year <- m2$year[-1L]
  expect_error(plot_compare_annual_F(m1, m2), "dimensions do not match.*year")
  expect_error(plot_compare_F(m1, m2), "dimensions do not match.*year")
  m2$year[1L] <- NA_real_
  expect_error(plot_compare_ts(m1, m2), "finite, increasing year")
})

test_that("plots paired to one observed table reject calendar and length mismatches", {
  m1 <- comparison_plot_fixture_224()
  m2 <- comparison_plot_fixture_224(structure = "year")
  data <- comparison_plot_data_224(m1)
  paired <- list(plot_compare_residuals, plot_compare_CatL, plot_compare_metrics)
  m2$year <- m2$year + 10
  for (fun in paired) expect_error(fun(m1, m2, data), "Model 2.*time columns")
  m2 <- comparison_plot_fixture_224(structure = "year")
  m2$len_label <- rev(m2$len_label)
  for (fun in paired) expect_error(fun(m1, m2, data), "Model 2.*length labels/order")
  m2 <- comparison_plot_fixture_224(structure = "year")
  m2$len_mid <- m2$len_mid + 1
  expect_error(plot_compare_CatL(m1, m2, data), "different length midpoints")
  m2$len_mid <- NULL
  expect_error(plot_compare_CatL(m1, m2, data), "length midpoints")

  m2 <- comparison_plot_fixture_224(structure = "year")
  # R's automatic X prefix is accepted without changing the calendar.
  names(data)[-1L] <- paste0("X", m1$year)
  p <- plot_compare_CatL(m1, m2, data, years = c(2001, 2003))
  expect_setequal(p$data$Year, c(2001, 2003))
  predicted <- p$data[p$data$Source == "ALSCL (year)", ]
  expect_equal(predicted$Value, as.numeric(exp(m2$report$Elog_index[, c(2L, 4L)])))
  expect_error(plot_compare_CatL(m1, m2, data, years = 2100), "No requested years")
})

test_that("paired residual plots omit missing cells and entirely missing periods", {
  m1 <- comparison_plot_fixture_224()
  m2 <- comparison_plot_fixture_224(structure = "year")
  data <- comparison_plot_data_224(m1)
  data[1L, 2L] <- NA_real_
  data[2L, 3L] <- 0
  data[, 4L] <- NA_real_
  # Even extreme placeholder residuals must never enter the diagnostic plots.
  valid <- is.finite(as.matrix(data[, -1L])) & as.matrix(data[, -1L]) > 0
  m1$report$resid_index[!valid] <- 999
  m2$report$resid_index[!valid] <- -999
  p <- plot_compare_residuals(m1, m2, data)
  panels <- comparison_panel_data_224(p)
  raw <- Filter(function(d) "Residual" %in% names(d), panels)
  expect_true(length(raw) > 0L)
  for (d in raw) {
    expect_equal(nrow(d), 2L * sum(valid))
    expect_true(all(is.finite(d$Residual)))
    expect_true(all(abs(d$Residual) < 1))
    expect_false(2002 %in% d$Year)
    expect_setequal(d$Model, c("ALSCL (group_year)", "ALSCL (year)"))
  }
  m2$report$resid_index <- m2$report$resid_index[-1L, , drop = FALSE]
  expect_error(plot_compare_residuals(m1, m2, data), "residual dimensions")
})


test_that("metric plots do not label unavailable parameter counts as zero", {
  m1 <- comparison_plot_fixture_224()
  m2 <- comparison_plot_fixture_224(structure = "year")
  data <- comparison_plot_data_224(m1)
  m1$opt$par <- NULL
  m1$obj$par <- NULL
  for (metric in c("npar", "IC")) {
    p <- plot_compare_metrics(m1, m2, data, metrics = metric)
    d <- comparison_panel_data_224(p)[[1L]]
    unavailable <- d$Model == "ALSCL (group_year)" &
      d$Metric_Name %in% c("N. Parameters", "AIC", "BIC")
    expect_true(any(unavailable))
    expect_true(all(is.na(d$Metric_Value[unavailable])))
    known <- d$Model == "ALSCL (year)"
    expect_true(all(is.finite(d$Metric_Value[known])))
    if (metric == "npar") expect_equal(d$Metric_Value[known], 2)
  }
})
