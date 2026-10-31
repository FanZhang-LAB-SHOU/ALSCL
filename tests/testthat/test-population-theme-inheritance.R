population_theme_fixture <- function() {
  values <- matrix(seq_len(12) + 10, 3L, 4L)
  report <- list(SSB = colSums(values / 2), SBL = values / 2, SBA = values / 2,
    B = colSums(values * 2), BL = values * 2, BA = values * 2,
    N = colSums(values), "NA" = values, NL = values,
    CN = colSums(values / 4), CNA = values / 4, CNL = values / 4)
  blocks <- lapply(report, function(x)
    cbind(Estimate = as.numeric(x), "Std. Error" = rep(.1, length(x))))
  errors <- do.call(rbind, blocks)
  rownames(errors) <- rep(names(blocks), vapply(blocks, nrow, integer(1)))
  list(model_type = "ALSCL", year = 2000 + c(.25, .5, .75, 1),
    len_label = c("10", "20", "30"), report = report, est_std = errors)
}

population_theme_specs <- function() list(
  list(fun = plot_SSB, types = c("SSB", "SBL", "SBA"), label = "ssb"),
  list(fun = plot_biomass, types = c("B", "BL", "BA"), label = "biomass"),
  list(fun = plot_abundance, types = c("N", "NA", "NL"), label = "abundance"),
  list(fun = plot_catch, types = c("CN", "CNA", "CNL"), label = "catch"))

test_that("population plots inherit titles, labels and time scales in every mode", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  m <- population_theme_fixture()
  labels <- list(ssb = "Mature biomass", biomass = "Total mass",
                 abundance = "Population count", catch = "Catch count")
  breaks <- m$year[c(1, 3, 4)]
  for (spec in population_theme_specs()) for (type in spec$types) {
    for (se in c(FALSE, TRUE)) {
      options(acl.theme = NULL)
      baseline <- spec$fun(m, type = type, se = se, return_data = TRUE)
      key <- if (se) paste0(type, "_se") else if (type == "NA") "NA_" else type
      wanted_title <- paste("Custom title for", key)
      acl_theme_set(titles = stats::setNames(list(wanted_title), key),
        xlab = list(year = "Survey time"), ylab = labels,
        x_breaks = breaks, x_expand = c(0, 0))
      actual <- spec$fun(m, type = type, se = se, return_data = TRUE)
      expect_identical(actual$data, baseline$data)
      expect_identical(actual$plot$labels$title, wanted_title)
      expect_identical(actual$plot$labels$x, "Survey time")
      expect_identical(actual$plot$labels$y, labels[[spec$label]])
      built <- ggplot2::ggplot_build(actual$plot)
      for (panel in built$layout$panel_params) {
        expect_equal(panel$x$breaks, breaks)
        expect_equal(panel$x.range, range(m$year))
      }
      theme <- built$plot$theme
      expect_s3_class(ggplot2::calc_element("panel.grid.major", theme), "element_blank")
      expect_s3_class(ggplot2::calc_element("panel.grid.minor", theme), "element_blank")
    }
  }
})

test_that("population plots have meaningful default titles for every quantity", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  m <- population_theme_fixture()
  for (spec in population_theme_specs()) for (type in spec$types) {
    for (se in c(FALSE, TRUE)) {
      key <- if (se) paste0(type, "_se") else if (type == "NA") "NA_" else type
      title <- spec$fun(m, type = type, se = se)$labels$title
      expect_type(title, "character")
      expect_length(title, 1L)
      expect_false(identical(title, key))
      if (se) expect_match(title, "95% CI", fixed = TRUE)
    }
  }
})

test_that("population plot scales apply asymmetric expansion without changing style overrides", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  m <- population_theme_fixture()
  acl_theme_set(x_expand = c(.1, .2), line_size = 3, se_alpha = .8)
  expected_range <- range(m$year) + diff(range(m$year)) * c(-.1, .2)
  for (spec in population_theme_specs()) {
    p <- spec$fun(m, se = TRUE, line_size = .4, line_color = "black",
                  line_type = "dotted", se_color = "orange", se_alpha = .15)
    built <- ggplot2::ggplot_build(p)
    expect_equal(built$layout$panel_params[[1]]$x.range, expected_range)
    expect_equal(unique(built$data[[1]]$linewidth), .4)
    expect_equal(unique(built$data[[1]]$colour), "black")
    expect_equal(unique(built$data[[1]]$linetype), "dotted")
    expect_equal(unique(built$data[[2]]$fill), "orange")
    expect_equal(unique(built$data[[2]]$alpha), .15)
  }
})

test_that("default population facets retain a readable time-axis tick density", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  m <- population_theme_fixture()
  m$year <- c(2000, 2005, 2010, 2019)
  for (spec in population_theme_specs()) for (se in c(FALSE, TRUE)) {
    p <- spec$fun(m, type = spec$types[2], se = se)
    panels <- ggplot2::ggplot_build(p)$layout$panel_params
    for (panel in panels) expect_lte(sum(is.finite(panel$x$breaks)), 6L)
  }
})
