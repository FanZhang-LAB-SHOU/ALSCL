theme_panels_225 <- function(plot) {
  # A nested patchwork can use an empty layout container; only actual panels
  # are drawn, while its children still need individual theme checks.
  panels <- if (inherits(plot, "plot_filler")) list() else list(plot)
  if (inherits(plot, "patchwork")) {
    for (child in plot$patches$plots)
      panels <- c(panels, theme_panels_225(child))
  }
  panels
}

theme_grid_elements_225 <- function(plot) {
  theme <- ggplot2::ggplot_build(plot)$plot$theme
  elements <- c("panel.grid.major.x", "panel.grid.major.y",
                "panel.grid.minor.x", "panel.grid.minor.y")
  lapply(elements, ggplot2::calc_element, theme = theme)
}

test_that("every exported plot family and comparison panel defaults to no grid", {
  old <- options(acl.theme = NULL); on.exit(options(old))
  fixture <- fit_fixture("ALSCL")
  m <- fixture$result
  d <- fixture$input$data.CatL
  retro_data <- expand.grid(Year = 2000:2002,
    RetrospectiveYear = c("2004", "2003"), Variable = "SSB")
  retro_data$Value <- seq_len(nrow(retro_data))
  retro <- list(results = retro_data,
    last_points = retro_data[retro_data$Year == 2002, ],
    rho_text = data.frame(Variable = "SSB", Rho = .01))
  calls <- list(
    plot_abundance = list(m), plot_biomass = list(m), plot_SSB = list(m),
    plot_recruitment = list(m), plot_SSB_Rec = list(m), plot_catch = list(m),
    plot_fishing_mortality = list(m), plot_deviance = list(m),
    plot_VB = list(m), plot_CatL = list(m), plot_residuals = list(m),
    plot_ridges = list(m), plot_pla = list(m), plot_retro = list(retro),
    plot_compare_ts = list(m, m), plot_compare_F = list(m, m),
    plot_compare_residuals = list(m, m, d), plot_compare_growth = list(m, m),
    plot_compare_CatL = list(m, m, d), plot_compare_metrics = list(m, m, d),
    plot_compare_selectivity = list(m, m), plot_compare_annual_F = list(m, m))
  exported_plots <- grep("^plot_", getNamespaceExports("ALSCL"), value = TRUE)
  expect_setequal(names(calls), exported_plots)
  for (name in names(calls)) {
    plot <- do.call(getExportedValue("ALSCL", name), calls[[name]])
    for (panel in theme_panels_225(plot)) {
      grid <- theme_grid_elements_225(panel)
      expect_true(all(vapply(grid, inherits, logical(1), "element_blank")),
                  info = paste(name, "must suppress major/minor grids on both axes"))
    }
  }
})

test_that("grid-free defaults apply to every base theme and can be overridden", {
  old <- options(acl.theme = NULL); on.exit(options(old))
  fixture <- list(report = list(Rec = 1:4), year = 2000:2003)
  themes <- c("theme_bw", "theme_minimal", "theme_classic", "theme_gray",
              "theme_grey", "theme_light", "theme_linedraw", "theme_dark", "theme_void")
  for (base in themes) {
    acl_theme_set(base_theme = base)
    plot <- plot_recruitment(fixture)
    grid <- theme_grid_elements_225(plot)
    expect_true(all(vapply(grid, inherits, logical(1), "element_blank")), info = base)
    restored <- plot + ggplot2::theme(
      panel.grid.major = ggplot2::element_line(colour = "grey80"),
      panel.grid.minor = ggplot2::element_line(colour = "grey90"))
    grid <- theme_grid_elements_225(restored)
    expect_true(all(vapply(grid, inherits, logical(1), "element_line")), info = base)
    expect_equal(vapply(grid, function(x) x$colour, character(1)),
                 c("grey80", "grey80", "grey90", "grey90"))
  }
  acl_theme_set(base_theme = "theme_dark")
  acl_theme_reset()
  expect_identical(acl_theme("base_theme"), "theme_bw")
  expect_true(all(vapply(theme_grid_elements_225(plot_recruitment(fixture)),
                         inherits, logical(1), "element_blank")))
})
