# Fail before saving if any actual panel still has a major or minor grid.
assert_grid_free_plot <- function(p) {
  if (!inherits(p,'plot_filler')) {
    th <- ggplot_build(p)$plot$theme
    for (nm in c('panel.grid.major.x','panel.grid.major.y','panel.grid.minor.x','panel.grid.minor.y'))
      stopifnot(inherits(calc_element(nm,th),'element_blank'))
  }
  if (inherits(p,'patchwork')) for (child in p$patches$plots) assert_grid_free_plot(child)
  invisible(p)
}
