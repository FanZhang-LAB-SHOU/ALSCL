# Fail before saving if any actual panel still has a major or minor grid.
assert_grid_free_plot <- function(p) {
  if (!inherits(p, c('plot_filler', 'spacer'))) {
    th <- ggplot2::ggplot_build(p)$plot$theme
    for (nm in c('panel.grid.major.x', 'panel.grid.major.y',
                 'panel.grid.minor.x', 'panel.grid.minor.y')) {
      if (!inherits(ggplot2::calc_element(nm, th), 'element_blank'))
        stop('Manual plot has a visible grid: ', nm, call. = FALSE)
    }
  }
  if (inherits(p, 'patchwork'))
    for (child in p$patches$plots) assert_grid_free_plot(child)
  invisible(p)
}

# Save through ALSCL::acl_save_plot() after the grid check: 300 dpi, white
# background, and the size of acl_figure_size() unless width or height is given.
save_grid_free_plot <- function(filename, plot, ..., dpi = 300) {
  assert_grid_free_plot(plot)
  ALSCL::acl_save_plot(plot, filename, ..., dpi = dpi)
}

# Time axis of a hand-built ggplot by the rule of the package plots: labelled
# years by the number of years and the panel width, unlabelled minor ticks at
# the other years, slanted labels in multi-panel figures when they would
# touch, and the tick-label rules of the package. `outer_cols` is the number
# of columns of a patchwork that holds the plot; `expand` (two numbers)
# widens the axis beyond the theme key x_expand, so that points and labels at
# both ends stay inside the panel. Uses internal helpers of ALSCL, so it needs
# the version of this checkout.
tidy_time_axis <- function(p, times, outer_cols = 1L, expand = NULL) {
  if (!is.null(expand)) {
    previous <- ALSCL::acl_theme()
    on.exit(do.call(ALSCL::acl_theme_set, previous), add = TRUE)
    ALSCL::acl_theme_set(x_expand = expand)
  }
  p <- p + ALSCL:::.acl_scale_x(values = times, time = TRUE)
  ALSCL:::.acl_tidy_axes(p, outer_cols = outer_cols)
}
