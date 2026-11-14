plot_style_fixture_243 <- function() {
  residual <- rbind(c(.1, .3, -.2, .2, -.1, .4), c(-.2, .1, .4, -.1, .2, .3))
  structure(growth_plot_fixture(list(model_type = "ALSCL", year = 2000:2005, age = 1:4,
    len_mid = c(10, 20), len_label = c("5-15", "15-25"), growth_step = 1,
    observations = exp(residual), report = list(Elog_index = matrix(0, 2, 6),
      sigma_index = .5, FL = matrix(seq_len(12) / 100, 2, 6),
      Linf = 50, vbk = .2, t0 = 0, pla = matrix(.5, 2, 4)))),
    class = c("alscl_fit", "list"))
}

plot_style_panels_243 <- function(plot) {
  panels <- if (inherits(plot, "plot_filler")) list() else list(plot)
  if (inherits(plot, "patchwork"))
    for (child in plot$patches$plots)
      panels <- c(panels, plot_style_panels_243(child))
  panels
}

expect_grid_free_style_243 <- function(plot) {
  theme <- ggplot2::ggplot_build(plot)$plot$theme
  for (grid in c("panel.grid.major.x", "panel.grid.major.y",
                 "panel.grid.minor.x", "panel.grid.minor.y"))
    expect_s3_class(ggplot2::calc_element(grid, theme), "element_blank")
}

test_that("F and both growth comparison panels obey global legend position", {
  skip_if_not_installed("patchwork")
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- plot_style_fixture_243()
  file <- tempfile(fileext = ".pdf")
  grDevices::pdf(file)
  on.exit({ grDevices::dev.off(); unlink(file) }, add = TRUE)
  for (position in c("bottom", "right", "none")) {
    acl_theme_set(compare_legend_pos = position, base_theme = "theme_minimal")
    heatmap <- plot_compare_F(fit, fit)
    growth <- plot_style_panels_243(plot_compare_growth(fit, fit))
    expect_length(growth, 2L)
    for (panel in c(list(heatmap), growth)) {
      expect_identical(ggplot2::ggplot_build(panel)$plot$theme$legend.position, position)
      rendered <- ggplot2::ggplotGrob(panel)
      boxes <- which(grepl("^guide-box", rendered$layout$name))
      visible <- vapply(rendered$grobs[boxes], function(grob)
        !inherits(grob, "zeroGrob"), logical(1))
      expect_identical(any(visible), position != "none")
      if (position != "none") {
        guide <- rendered$layout[boxes[visible], ]
        panels <- rendered$layout[grepl("^panel($|-)", rendered$layout$name), ]
        if (position == "bottom") expect_gt(guide$t, max(panels$b))
        else expect_gt(guide$l, max(panels$r))
      }
      expect_grid_free_style_243(panel)
    }
  }
})

test_that("conditional residual diagnostic points inherit the global point size", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- plot_style_fixture_243()
  for (size in c(acl_theme("point_size"), 7)) {
    acl_theme_set(point_size = size, point_color = "purple", base_theme = "theme_bw")
    checks <- check_fit(fit, max_lag = 2)
    for (name in c("lag", "qq")) {
      plot <- checks$plots[[name]]
      points <- which(vapply(plot$layers, function(layer)
        inherits(layer$geom, "GeomPoint"), logical(1)))
      expect_length(points, 1L)
      data <- ggplot2::ggplot_build(plot)$data[[points]]
      expect_true(nrow(data) > 0L)
      expect_equal(unique(data$size), size)
      expect_identical(unique(data$colour), "purple")
    }
    for (plot in checks$plots) expect_grid_free_style_243(plot)
  }
})
