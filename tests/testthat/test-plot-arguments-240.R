fixture_240 <- function(years = 2000:2002) {
  n <- length(years)
  dev_f <- matrix(seq(-.3, .3, length.out = 3 * n), 3, n)
  list(model_type = "ACL", F_structure = "group_year", year = years, growth_step = years[2] - years[1],
    len_mid = c(10, 20, 30), len_label = c("5-15", "15-25", "25-35"),
    observations = matrix(seq_len(3 * n), 3, n),
    report = list(F = matrix(.2, 3, n), dev_log_F = dev_f, dev_log_R = rep(0, n),
      Elog_index = matrix(log(seq_len(3 * n)), 3, n), resid_index = matrix(.1, 3, n),
      SSB = seq_len(n) * 10, Rec = seq_len(n)),
    est_std = cbind(Estimate = c(rep(0, n), dev_f), "Std. Error" = rep(.05, n + 3 * n),
                    deparse.level = 0)[, , drop = FALSE] |> (\(m) {rownames(m) <- c(rep("dev_log_R", n), rep("dev_log_F", 3 * n)); m})())
}

# The survey table that a fixture was fitted to, with time labels as column names.
catl_240 <- function(fit) {
  table <- data.frame(LengthBin = fit$len_label, fit$observations, check.names = FALSE)
  names(table)[-1] <- as.character(fit$year)
  table
}

retro_fixture_240 <- function() {
  d <- expand.grid(Year = 2000:2002, RetrospectiveYear = c("2019", "2018"), Variable = c("SSB", "Rec"))
  d$Value <- seq_len(nrow(d))
  list(results = d, last_points = d[d$Year == 2002, ],
       rho_text = data.frame(Variable = c("SSB", "Rec"), Rho = c(.01, -.02)), model_type = "acl")
}

test_that("former argument names are mapped onto the new names with one warning per session", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  ALSCL:::.acl_reset_deprecations(); on.exit(ALSCL:::.acl_reset_deprecations(), add = TRUE)
  fit <- fixture_240()
  expect_warning(old_layout <- plot_CatL(fit, type = "year", return_data = TRUE),
                 "plot_CatL\\(\\): argument 'type' is deprecated")
  expect_no_warning(plot_CatL(fit, type = "year"))
  new_layout <- plot_CatL(fit, facet_by = "year", return_data = TRUE)
  expect_equal(old_layout$data1, new_layout$data1)
  expect_identical(old_layout$plot$labels$title, new_layout$plot$labels$title)
  expect_warning(old_resid <- plot_residuals(fit, type = "length", return_data = TRUE), "'type' is deprecated")
  expect_equal(old_resid$data, plot_residuals(fit, facet_by = "length", return_data = TRUE)$data)
  expect_error(plot_CatL(fit, colour = "red"), "plot_CatL\\(\\): unused argument colour")
  expect_error(plot_compare_F_ts(fit, fit, "a", "b", "mean", NULL, NULL, NULL, 99), "unused argument <unnamed>")

  warnings <- capture_warnings(ts_old <- plot_compare_ts(fit, fit, quantities = "SSB", linewidth = 2, ncol = 1,
                                                         scales = "fixed", return_data = TRUE))
  expect_length(warnings, 3L)
  expect_match(warnings, "is deprecated and will be removed", all = TRUE)
  ts_new <- plot_compare_ts(fit, fit, quantities = "SSB", line_size = 2, facet_ncol = 1,
                            facet_scales = "fixed", return_data = TRUE)
  expect_equal(ts_old$data, ts_new$data)
  expect_equal(unique(ggplot2::ggplot_build(ts_old$plot)$data[[1]]$linewidth), 2)
  expect_equal(ggplot2::ggplot_build(ts_old$plot)$layout$facet$params$ncol, 1L)
  expect_warning(old_catl <- plot_compare_CatL(fit, fit, catl_240(fit), ncol = 1, facet_scales = "free"), "'ncol' is deprecated")
  expect_equal(old_catl$facet$params$ncol,
               plot_compare_CatL(fit, fit, catl_240(fit), facet_ncol = 1, facet_scales = "free")$facet$params$ncol)

  retro <- retro_fixture_240()
  warnings <- capture_warnings(p <- plot_retro(retro, facet_col = 1, facet_row = 2))
  expect_match(warnings, "'facet_(col|row)' is deprecated", all = TRUE)
  expect_length(warnings, 2L)
  expect_equal(p$facet$params$ncol, plot_retro(retro, facet_ncol = 1, facet_nrow = 2)$facet$params$ncol)
  expect_equal(p$facet$params$nrow, 2L)
})

test_that("the renamed theme keys and the renamed function keep working", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  ALSCL:::.acl_reset_deprecations(); on.exit(ALSCL:::.acl_reset_deprecations(), add = TRUE)
  expect_warning(acl_theme_set(compare_linewidth = 3), "'compare_linewidth' is deprecated")
  expect_equal(acl_theme("compare_line_size"), 3)
  expect_warning(expect_equal(acl_theme("compare_linewidth"), 3), "compare_linewidth")
  warnings <- capture_warnings(acl_theme_set(titles = list(CatL_year_dist = "Per period", CatL_year = "Per bin")))
  expect_match(warnings, "Title key 'CatL_year(_dist)?' is deprecated", all = TRUE)
  expect_length(warnings, 2L)
  expect_equal(acl_theme("titles")$CatL_by_year, "Per period")
  expect_equal(acl_theme("titles")$CatL_by_length, "Per bin")
  fit <- fixture_240()
  expect_equal(plot_CatL(fit, facet_by = "year")$labels$title, "Per period")
  expect_equal(plot_CatL(fit)$labels$title, "Per bin")
  expect_null(acl_theme("ylab")$deviance)
  expect_equal(plot_pla(list(report = list(pla = matrix(1 / 3, 3, 4)), len_label = fit$len_label))$labels$y, "Length")
  acl_theme_set(ylab = list(length = "Length class"))
  expect_equal(plot_pla(list(report = list(pla = matrix(1 / 3, 3, 4)), len_label = fit$len_label))$labels$y, "Length class")

  expect_warning(p <- plot_compare_annual_F(fit, fit, method = "mean"), "plot_compare_annual_F\\(\\) is deprecated")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "Fishing mortality by time step")
  expect_equal(p$data, plot_compare_F_ts(fit, fit, method = "mean")$data)
  acl_theme_set(titles = list(compare_F_ts = "F summary"))
  expect_equal(plot_compare_F_ts(fit, fit)$labels$title, "F summary")
})

test_that("point sizes inherit one theme setting and intervals are off by default", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- fixture_240()
  retro <- retro_fixture_240()
  expect_equal(acl_theme("point_size"), 2.5)
  size_of <- function(p, layer) unique(ggplot2::ggplot_build(p)$data[[layer]]$size)
  expect_equal(size_of(plot_CatL(fit), 1L), 2.5)
  expect_equal(size_of(plot_deviance(fit, type = "R"), 2L), 2.5)
  expect_equal(size_of(plot_SSB_Rec(fit, age_at_recruitment = 0), 1L), 2.5)
  expect_equal(size_of(plot_retro(retro), 2L), 2.5)
  acl_theme_set(point_size = 4)
  expect_equal(size_of(plot_CatL(fit), 1L), 4)
  expect_equal(size_of(plot_deviance(fit, type = "R"), 2L), 4)
  expect_equal(size_of(plot_SSB_Rec(fit, age_at_recruitment = 0), 1L), 4)
  expect_equal(size_of(plot_retro(retro), 2L), 4)
  expect_equal(size_of(plot_CatL(fit, point_size = 1), 1L), 1)
  expect_equal(size_of(plot_retro(retro, point_size = 1), 2L), 1)
  expect_length(plot_deviance(fit, type = "R")$layers, 2L)
  expect_length(plot_deviance(fit, type = "R", se = TRUE)$layers, 4L)
  expect_equal(as.character(unique(plot_deviance(fit, type = "F")$data$Group)), paste("Age bin", 1:3))
})

test_that("time-step panels are labelled by year or quarter in every plot", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  expect_equal(ALSCL:::.acl_time_labels(2000:2002), paste("Year", 2000:2002))
  expect_equal(ALSCL:::.acl_time_labels(c(2000, 2000.25, 2000.5, 2000.75, 2001)),
               c("2000 Q1", "2000 Q2", "2000 Q3", "2000 Q4", "2001 Q1"))
  expect_equal(ALSCL:::.acl_time_labels(c(2000, 2000.5, 2001)), c("2000", "2000.5", "2001"))
  annual <- fixture_240()
  quarterly <- fixture_240(c(2000, 2000.25, 2000.5))
  expect_equal(levels(plot_CatL(annual, facet_by = "year", return_data = TRUE)$data1$year), paste("Year", 2000:2002))
  expect_equal(levels(plot_CatL(quarterly, facet_by = "year", return_data = TRUE)$data1$year), c("2000 Q1", "2000 Q2", "2000 Q3"))
  expect_equal(levels(plot_residuals(quarterly, facet_by = "year", return_data = TRUE)$data$Year), c("2000 Q1", "2000 Q2", "2000 Q3"))
  f_plot <- plot_fishing_mortality(quarterly, type = "age", return_data = TRUE)
  expect_equal(levels(f_plot$data$Period), c("2000 Q1", "2000 Q2", "2000 Q3"))
  expect_equal(as.character(f_plot$data$Period), rep(c("2000 Q1", "2000 Q2", "2000 Q3"), each = 3))
  expect_equal(names(f_plot$plot$facet$params$facets), "Period")
  expect_equal(plot_fishing_mortality(annual, type = "year", return_data = TRUE)$data$Year, rep(2000:2002, each = 3))
  compare <- plot_compare_CatL(quarterly, quarterly, catl_240(quarterly))
  expect_equal(levels(compare$data$year_fct), c("2000 Q1", "2000 Q2", "2000 Q3"))
})

test_that("every single-model plot takes the same label and typography arguments", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  style_args <- c("title", "xlab", "ylab", "font_family", "title_size", "axis_title_size", "axis_text_size",
                  "strip_text_size", "legend_text_size", "x_breaks", "base_theme", "title_hjust")
  singles <- c("plot_SSB", "plot_biomass", "plot_abundance", "plot_catch", "plot_deviance", "plot_fishing_mortality",
               "plot_recruitment", "plot_VB", "plot_CatL", "plot_residuals", "plot_ridges", "plot_pla",
               "plot_SSB_Rec", "plot_retro")
  for (name in singles)
    expect_true(all(style_args %in% names(formals(get(name, asNamespace("ALSCL"))))), label = name)
  fit <- fixture_240()
  fit$report$B <- fit$report$SSB * 2
  fit$report$N <- fit$report$SSB * 3
  fit$report$CN <- fit$report$SSB / 2
  draw <- list(plot_SSB = function(...) plot_SSB(fit, ...), plot_biomass = function(...) plot_biomass(fit, ...),
               plot_abundance = function(...) plot_abundance(fit, ...), plot_catch = function(...) plot_catch(fit, ...),
               plot_deviance = function(...) plot_deviance(fit, type = "R", ...),
               plot_fishing_mortality = function(...) plot_fishing_mortality(fit, ...))
  for (name in names(draw)) {
    p <- draw[[name]](title = "Custom title", xlab = "Custom x", ylab = "Custom y", title_size = 21, title_hjust = 0,
                      axis_text_size = 7, x_breaks = c(2000, 2002), base_theme = "minimal")
    expect_identical(p$labels$title, "Custom title", label = name)
    expect_identical(p$labels$x, "Custom x", label = name)
    expect_identical(p$labels$y, "Custom y", label = name)
    built <- ggplot2::ggplot_build(p)
    expect_equal(ggplot2::calc_element("plot.title", built$plot$theme)$size, 21, label = name)
    expect_equal(ggplot2::calc_element("plot.title", built$plot$theme)$hjust, 0, label = name)
    expect_equal(ggplot2::calc_element("axis.text", built$plot$theme)$size, 7, label = name)
    breaks <- built$layout$panel_params[[1]]$x$breaks
    expect_equal(breaks[is.finite(breaks)], c(2000, 2002), label = name)
    defaults <- ggplot2::ggplot_build(draw[[name]]())
    expect_false(identical(defaults$plot$labels$title, "Custom title"), label = name)
    expect_equal(ggplot2::calc_element("plot.title", defaults$plot$theme)$size, 14, label = name)
  }
})


test_that("comparison point plots inherit the shared point size and keep legacy overrides", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- fixture_240()
  fit$obj <- list(env = list(data = list(log_q = log(c(.2, .6, .9)))))
  draws <- list(
    F = function(...) plot_compare_F_ts(fit, fit, ...),
    selectivity = function(...) plot_compare_selectivity(fit, fit, ...),
    survey = function(...) plot_compare_CatL(fit, fit, catl_240(fit), ...))
  layer <- c(F = 2L, selectivity = 2L, survey = 1L)
  size_of <- function(p, layer) unique(ggplot2::ggplot_build(p)$data[[layer]]$size)
  expect_null(acl_theme("compare_point_size"))
  for (nm in names(draws)) {
    expect_equal(size_of(draws[[nm]](), layer[[nm]]), 2.5, label = nm)
    expect_equal(size_of(draws[[nm]](point_size = 4), layer[[nm]]), 4, label = nm)
  }
  acl_theme_set(point_size = 7)
  for (nm in names(draws))
    expect_equal(size_of(draws[[nm]](), layer[[nm]]), 7, label = nm)
  acl_theme_set(compare_point_size = 3)
  for (nm in names(draws)) {
    expect_equal(size_of(draws[[nm]](), layer[[nm]]), 3, label = nm)
    expect_equal(size_of(draws[[nm]](point_size = 4), layer[[nm]]), 4, label = nm)
    p <- ggplot2::ggplot_build(draws[[nm]](point_size = 4))$plot
    for (grid in c("panel.grid.major.x", "panel.grid.major.y", "panel.grid.minor.x", "panel.grid.minor.y"))
      expect_true(inherits(ggplot2::calc_element(grid, p$theme), "element_blank"), info = nm)
  }
  expect_equal(size_of(plot_CatL(fit), 1L), 7)
  expect_equal(size_of(draws$survey(obs_size = 1), 1L), 1)
  expect_equal(size_of(draws$survey(point_size = 4, obs_size = 1), 1L), 4)
  # obs_size retains its original positional slot, and new options require names.
  positional <- list(fit, fit, catl_240(fit), NULL, NULL, NULL, NULL, NULL, NULL,
                     4, "free_y", "grey40", 1)
  expect_equal(size_of(do.call(plot_compare_CatL, positional), 1L), 1)
  expect_error(plot_compare_F_ts(fit, fit, NULL, NULL, "mean", NULL, NULL, NULL, 9),
               "unused argument <unnamed>")
})

test_that("the residual comparison uses point_size for QQ and mean-residual points", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- fixture_240()
  p <- plot_compare_residuals(fit, fit, catl_240(fit), point_size = 4)
  qq <- p[[1L]][[2L]]
  means <- p[[2L]][[1L]]
  expect_equal(unique(ggplot2::ggplot_build(qq)$data[[1L]]$size), 4)
  expect_equal(unique(ggplot2::ggplot_build(means)$data[[3L]]$size), 4)
})

test_that("fishing mortality retains the former positional base_theme argument", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- fixture_240()
  args <- list(fit, NULL, NULL, "solid", NULL, "free", FALSE, NULL, NULL, "ribbon",
               "year", FALSE, NULL, NULL, NULL, NULL, NULL, NULL, "minimal")
  positional <- do.call(plot_fishing_mortality, args)
  named <- plot_fishing_mortality(fit, base_theme = "minimal")
  expect_equal(ggplot2::ggplot_build(positional)$data, ggplot2::ggplot_build(named)$data)
  expect_equal(positional$theme, named$theme)
  args$axis_title_size <- 19
  styled <- ggplot2::ggplot_build(do.call(plot_fishing_mortality, args))$plot
  expect_equal(ggplot2::calc_element("axis.title", styled$theme)$size, 19)
  for (grid in c("panel.grid.major.x", "panel.grid.major.y", "panel.grid.minor.x", "panel.grid.minor.y"))
    expect_s3_class(ggplot2::calc_element(grid, styled$theme), "element_blank")
})


test_that("nullable comparison point overrides can be cleared and restored from snapshots", {
  old_options <- options(acl.theme = NULL); on.exit(options(old_options), add = TRUE)
  acl_theme_set(point_size = 7, line_size = 2)
  snapshot <- acl_theme_set(compare_point_size = 4)
  expect_true("compare_point_size" %in% names(snapshot))
  expect_null(snapshot$compare_point_size)
  expect_equal(ALSCL:::.acl_compare_defaults()$point_size, 4)
  do.call(acl_theme_set, snapshot)
  expect_null(acl_theme("compare_point_size"))
  expect_equal(ALSCL:::.acl_compare_defaults()$point_size, 7)
  expect_equal(acl_theme(), snapshot)
  acl_theme_set(compare_point_size = 4)
  acl_theme_set(line_size = 3)
  expect_equal(acl_theme("compare_point_size"), 4)
  acl_theme_set(compare_point_size = NULL)
  expect_null(acl_theme("compare_point_size"))
  expect_equal(ALSCL:::.acl_compare_defaults()$point_size, 7)
  expect_true("compare_point_size" %in% names(acl_theme()))
})
