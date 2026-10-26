grid_elements_226 <- function(p) {
  th <- ggplot2::ggplot_build(p)$plot$theme
  lapply(c("panel.grid.major.x", "panel.grid.major.y",
           "panel.grid.minor.x", "panel.grid.minor.y"),
         ggplot2::calc_element, theme = th)
}

test_that("all six theme recovery paths keep panel grids hidden", {
  old <- options(acl.theme = NULL); on.exit(options(old))
  m <- fit_fixture("ALSCL")$result
  local_mocked_bindings(acl_get_theme = function() stop("theme unavailable"),
                        .package = "ALSCL")
  calls <- list(plot_abundance = list(m), plot_biomass = list(m),
                plot_SSB = list(m), plot_catch = list(m),
                plot_deviance = list(m), plot_fishing_mortality = list(m))
  for (name in names(calls)) {
    p <- do.call(getExportedValue("ALSCL", name), calls[[name]])
    expect_true(all(vapply(grid_elements_226(p), inherits,
                           logical(1), "element_blank")), info = name)
  }
  # An explicit per-call theme remains the user's choice even during recovery.
  custom <- plot_fishing_mortality(m, base_theme = ggplot2::theme_minimal())
  expect_true(all(vapply(grid_elements_226(custom), inherits,
                         logical(1), "element_line")))
})

test_that("theme recovery retains a valid configured theme", {
  old <- options(acl.theme = NULL); on.exit(options(old))
  acl_theme_set(base_theme = "theme_classic", axis_text_size = 17)
  expect_equal(ALSCL:::.acl_plot_theme(), ALSCL:::acl_get_theme())
})
