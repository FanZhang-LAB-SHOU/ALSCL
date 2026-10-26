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

save_grid_free_plot <- function(filename, plot, ...) {
  assert_grid_free_plot(plot)
  ggplot2::ggsave(filename = filename, plot = plot, ...)
}
