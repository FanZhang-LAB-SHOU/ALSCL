singleton_plot_fixture <- function(model = "ALSCL", periods = 1L) {
  series <- seq_len(periods) + 10
  field <- matrix(seq_len(3L * periods) / 10, 3L, periods)
  report <- list(N = series, B = series * 2, SSB = series / 2,
    CN = series / 4, Rec = series / 3, NL = field, "NA" = field, CNA = field)
  if (model == "ALSCL") report <- c(report,
    list(BA = field, BL = field, SBA = field, SBL = field, CNL = field, FL = field))
  else report$F <- field
  estimates <- do.call(rbind, lapply(report, function(x)
    cbind(Estimate = as.numeric(x), "Std. Error" = rep(.05, length(x)))))
  rownames(estimates) <- rep(names(report), lengths(report))
  list(model_type = model, year = 2000 + seq_len(periods) - 1,
    len_mid = c(10, 20, 30), len_label = c("10", "20", "30"), age = 1:3,
    report = report, est_std = estimates)
}

# Inspect drawn panels, excluding legends, axes and strip labels. A populated
# layer data frame is not sufficient: a one-point line/ribbon draws no estimate.
singleton_panel_grobs <- function(plot, kind) {
  grob <- ggplot2::ggplotGrob(plot)
  collect <- function(x) {
    out <- if (inherits(x, kind)) list(x) else list()
    for (child in c(as.list(x$children), x$grobs)) out <- c(out, collect(child))
    out
  }
  unlist(lapply(grob$grobs[grepl("^panel", grob$layout$name)], collect), recursive = FALSE)
}

singleton_assert_grid_free <- function(plot) {
  theme <- ggplot2::ggplot_build(plot)$plot$theme
  for (axis in c("major.x", "major.y", "minor.x", "minor.y"))
    expect_s3_class(ggplot2::calc_element(paste0("panel.grid.", axis), theme), "element_blank")
}

test_that("single-period population panels draw estimates and intervals", {
  withr::local_options(list(acl.theme = NULL))
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  acl_theme_set(point_size = 3.5, line_color = "navy", se_color = "orange")
  for (model in c("ACL", "ALSCL")) {
    fit <- singleton_plot_fixture(model)
    specs <- list(plot_abundance = c("N", "NA", "NL"),
      plot_biomass = if (model == "ACL") "B" else c("B", "BA", "BL"),
      plot_SSB = if (model == "ACL") "SSB" else c("SSB", "SBA", "SBL"),
      plot_catch = if (model == "ACL") c("CN", "CNA") else c("CN", "CNA", "CNL"),
      plot_recruitment = "Rec", plot_fishing_mortality = "year")
    for (fun in names(specs)) for (quantity in specs[[fun]]) for (se in c(FALSE, TRUE)) {
      args <- list(model_result = fit, se = se, return_data = TRUE)
      if (fun != "plot_recruitment") args$type <- quantity
      result <- do.call(get(fun), args)
      p <- result$plot
      expect_silent(ggplot2::ggplotGrob(p))
      points <- singleton_panel_grobs(p, "points")
      expect_equal(sum(vapply(points, function(x) length(x$x), integer(1))), nrow(result$data))
      built <- ggplot2::ggplot_build(p)
      point_layer <- which(vapply(p$layers, function(x) inherits(x$geom, "GeomPoint"), logical(1)))
      expect_equal(unique(built$data[[point_layer]]$size), 3.5)
      expect_equal(unique(built$data[[point_layer]]$colour), "navy")
      if (se) {
        bars <- which(vapply(p$layers, function(x) inherits(x$geom, "GeomErrorbar"), logical(1)))
        expect_length(bars, 1L)
        # Lognormal interval: log(upper / lower) = 3.92 SE / estimate, with SE = .05.
        expect_equal(log(built$data[[bars]]$ymax / built$data[[bars]]$ymin) * built$data[[bars]]$y,
          rep(.196, nrow(result$data)))
        expect_true(all(built$data[[bars]]$ymin > 0))
        expect_equal(unique(built$data[[bars]]$colour), "orange")
        expect_true(length(singleton_panel_grobs(p, "polyline")) >= 1L)
      }
      singleton_assert_grid_free(p)
    }
  }
})

test_that("a real two-age ALSCL fit draws its one-age F panels", {
  withr::local_options(list(acl.theme = NULL, ALSCL.sd_cores = 1L))
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  x <- fixture_frames(); x$nage <- 2L
  x$data.CatL[[1]] <- x$data.wgt[[1]] <- x$data.mat[[1]] <- as.character(seq(15, 55, 5))
  p <- create_parameters("alscl")$parameters
  p$log_Linf <- log(60); p$log_vbk <- log(.2); p$mean_log_R <- log(100)
  p$log_init_Z <- log(.5); p$log_sigma_index <- log(.2)
  p$log_sigma_log_N0 <- p$log_sigma_log_R <- log(.1)
  mapping <- lapply(p, function(x) factor(NA)); mapping$mean_log_R <- NULL
  setup <- ALSCL:::.acl_model_setup("ALSCL", do.call(ALSCL:::.acl_prepare_data, x), p, map = mapping)
  info <- ALSCL:::.acl_compile("ALSCL")
  obj <- TMB::MakeADFun(setup$data, setup$parameters, DLL = info$dll_name, silent = TRUE)
  x$data.CatL[-1L] <- exp(obj$report(obj$par)$Elog_index)
  fit <- run_alscl(c(x, list(parameters = p, map = mapping)), silent = TRUE)
  expect_true(fit$diagnostics$numerical_ok)
  expect_equal(dim(fit$report$FA), c(1L, 4L))
  fit$obj <- NULL
  # Without intervals the plot is completed with the plus group and the last
  # period, so each panel has both ages.
  completed <- plot_fishing_mortality(fit, type = "age", return_data = TRUE)$data
  expect_equal(completed$F, as.numeric(ALSCL:::.acl_F_at_age(fit)$FA))
  expect_equal(nrow(completed), 10L)
  # A result without numbers at length and age, and every plot with
  # intervals, shows the reported cells: one age in each of four panels.
  reported <- fit; reported$report$NLA <- NULL
  for (interval in c("none", "ribbon", "errorbar")) {
    p <- plot_fishing_mortality(if (interval == "none") reported else fit, type = "age", se = interval != "none",
      se_type = if (interval == "none") "ribbon" else interval)
    expect_silent(ggplot2::ggplotGrob(p))
    expect_length(singleton_panel_grobs(p, "points"), 4L)
    b <- ggplot2::ggplot_build(p)
    point <- which(vapply(p$layers, function(x) inherits(x$geom, "GeomPoint"), logical(1)))
    expect_equal(b$data[[point]]$y, as.numeric(fit$report$FA))
    if (interval != "none") {
      bar <- which(vapply(p$layers, function(x) inherits(x$geom, "GeomErrorbar"), logical(1)))
      expect_length(bar, 1L)
      expect_equal(nrow(b$data[[bar]]), 4L)
      expect_true(all(b$data[[bar]]$ymax > b$data[[bar]]$ymin))
      expect_true(length(singleton_panel_grobs(p, "polyline")) >= 4L)
    }
    singleton_assert_grid_free(p)
  }
})

test_that("singletons are identified separately for each comparison model", {
  withr::local_options(list(acl.theme = NULL))
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  single <- singleton_plot_fixture(periods = 1L)
  multi <- singleton_plot_fixture(periods = 3L)
  for (other in list(single, multi)) for (se in c(FALSE, TRUE)) {
    p <- plot_compare_ts(single, other, quantities = "SSB", se = se,
      model1_name = "Short", model2_name = "Long")
    expect_silent(ggplot2::ggplotGrob(p))
    points <- singleton_panel_grobs(p, "points")
    expect_equal(sum(vapply(points, function(x) length(x$x), integer(1))),
      if (length(other$year) == 1L) 2L else 1L)
    b <- ggplot2::ggplot_build(p)
    expect_equal(nrow(b$data[[1L]]), if (length(other$year) == 1L) 0L else 3L)
    if (se) {
      bars <- which(vapply(p$layers, function(x) inherits(x$geom, "GeomErrorbar"), logical(1)))
      expect_length(bars, 1L)
      # Lognormal interval around the single SSB estimate of 5.5, with SE = .05.
      expect_equal(log(b$data[[bars]]$ymax / b$data[[bars]]$ymin) * single$report$SSB[1L],
        rep(.196, if (length(other$year) == 1L) 2L else 1L))
    }
    singleton_assert_grid_free(p)
  }
  # No extra layers or changes to the data for ordinary multi-period curves.
  p <- plot_compare_ts(multi, multi, quantities = "SSB", se = TRUE)
  expect_length(p$layers, 2L)
  expect_equal(nrow(ggplot2::ggplot_build(p)$data[[1L]]), 6L)
})
