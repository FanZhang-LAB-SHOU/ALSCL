fishing_theme_fixture <- function(model = "ACL") {
  values <- matrix(seq_len(24) / 100 + .1, 4L, 6L)
  report <- if (model == "ACL") list(F = values) else
    list(FL = values, FA = values[1:3, 1:5, drop = FALSE])
  blocks <- lapply(report, function(x)
    cbind(Estimate = as.numeric(x), "Std. Error" = rep(.01, length(x))))
  estimates <- do.call(rbind, blocks)
  rownames(estimates) <- rep(names(blocks), vapply(blocks, nrow, integer(1)))
  list(model_type = model, year = 2000 + (0:5) / 4,
    len_mid = c(10, 20, 30, 40), len_label = c("10", "20", "30", "40"),
    report = report, est_std = estimates)
}

fishing_assert_no_grid <- function(p) {
  theme <- ggplot2::ggplot_build(p)$plot$theme
  for (name in c("panel.grid.major", "panel.grid.minor", "panel.grid.major.x",
                 "panel.grid.major.y", "panel.grid.minor.x", "panel.grid.minor.y"))
    expect_s3_class(ggplot2::calc_element(name, theme), "element_blank")
}

test_that("all F layouts inherit global labels and scales without changing plotting data", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  xlabels <- list(year = "Survey period", age = "Age class", length = "Length (cm)")
  for (model in c("ACL", "ALSCL")) {
    fit <- fishing_theme_fixture(model)
    types <- if (model == "ACL") c("year", "age") else c("year", "age", "length")
    for (type in types) for (interval in c("none", "ribbon", "errorbar")) {
      se <- interval != "none"
      se_type <- if (se) interval else "ribbon"
      options(acl.theme = NULL)
      baseline <- plot_fishing_mortality(fit, type = type, se = se,
        se_type = se_type, return_data = TRUE)
      key <- paste0("F_", type, if (se) "_se" else "")
      breaks <- switch(type, year = fit$year[c(1, 3, 6)], age = c(1, 3), length = c(10, 30, 40))
      title <- paste("Custom", key)
      acl_theme_set(titles = stats::setNames(list(title), key), xlab = xlabels,
        ylab = list(F = "Native F"), x_breaks = breaks, x_expand = c(0, 0))
      actual <- plot_fishing_mortality(fit, type = type, se = se,
        se_type = se_type, return_data = TRUE)
      expect_identical(actual$data, baseline$data)
      expect_identical(actual$plot$labels$title, title)
      expect_identical(actual$plot$labels$x, xlabels[[type]])
      expect_identical(actual$plot$labels$y, "Native F")
      built <- ggplot2::ggplot_build(actual$plot)
      coords <- unlist(lapply(built$data, function(d)
        unlist(d[intersect(c("x", "xmin", "xmax"), names(d))])))
      for (panel in built$layout$panel_params) {
        expect_equal(panel$x$breaks, breaks)
        expect_equal(panel$x.range, range(coords, finite = TRUE))
      }
      fishing_assert_no_grid(actual$plot)
    }
  }
})

test_that("F plots honor explicit labels breaks and styles before global settings", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- fishing_theme_fixture("ALSCL")
  acl_theme_set(titles = list(F_year_se = "Global"),
    xlab = list(year = "Global year"), ylab = list(F = "Global F"),
    x_breaks = fit$year[1:2], x_expand = c(.1, .2),
    line_size = 4, line_color = "orange", se_color = "pink", se_alpha = .7)
  p <- plot_fishing_mortality(fit, se = TRUE, title = "Chosen title",
    xlab = "Chosen time", ylab = "Chosen F", x_breaks = fit$year[c(2, 5)],
    line_size = .4, line_color = "blue", se_color = "green", se_alpha = .1,
    line_type = "dotted", font_family = "mono", title_size = 19)
  expect_equal(p$labels$title, "Chosen title")
  expect_equal(p$labels$x, "Chosen time")
  expect_equal(p$labels$y, "Chosen F")
  b <- ggplot2::ggplot_build(p)
  expect_equal(b$layout$panel_params[[1]]$x$breaks, fit$year[c(2, 5)])
  expect_equal(b$layout$panel_params[[1]]$x.range,
    range(fit$year) + diff(range(fit$year)) * c(-.1, .2))
  expect_equal(unique(b$data[[1]]$colour), "blue")
  expect_equal(unique(b$data[[1]]$linewidth), .4)
  expect_equal(unique(b$data[[1]]$linetype), "dotted")
  expect_equal(unique(b$data[[2]]$fill), "green")
  expect_equal(unique(b$data[[2]]$alpha), .1)
  expect_equal(ggplot2::calc_element("axis.text.x", b$plot$theme)$family, "mono")
  expect_equal(ggplot2::calc_element("plot.title", b$plot$theme)$size, 19)
})

test_that("F theme names and theme objects retain layout while staying grid free", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- fishing_theme_fixture()
  custom <- ggplot2::theme_minimal() + ggplot2::theme(
    panel.background = ggplot2::element_rect(fill = "ivory", colour = NA),
    legend.position = "top", axis.text.x = ggplot2::element_text(angle = 30, family = "serif"),
    plot.title = ggplot2::element_text(family = "serif"),
    panel.grid.major.x = ggplot2::element_line(colour = "red"),
    panel.grid.minor.y = ggplot2::element_line(colour = "red"))
  for (base in list(NULL, "bw", "theme_bw", "minimal", "theme_minimal", custom)) {
    p <- plot_fishing_mortality(fit, base_theme = base, font_family = "mono", title_size = 18)
    fishing_assert_no_grid(p)
    th <- ggplot2::ggplot_build(p)$plot$theme
    expect_equal(ggplot2::calc_element("axis.text.x", th)$family, "mono")
    expect_equal(ggplot2::calc_element("plot.title", th)$family, "mono")
    expect_equal(ggplot2::calc_element("plot.title", th)$size, 18)
    if (inherits(base, "theme")) {
      expect_equal(ggplot2::calc_element("panel.background", th)$fill, "ivory")
      expect_equal(ggplot2::calc_element("axis.text.x", th)$angle, 30)
      expect_equal(th$legend.position, "top")
    }
  }
  for (base in list(1, list(), NA_character_, c("bw", "minimal"), ""))
    expect_error(plot_fishing_mortality(fit, base_theme = base), "base_theme must be")
  acl_theme_set(base_theme = "theme_minimal", font_family = "mono", title_size = 17)
  p <- plot_fishing_mortality(fit)
  th <- ggplot2::ggplot_build(p)$plot$theme
  expect_null(ggplot2::calc_element("panel.background", th)$fill)
  expect_equal(ggplot2::calc_element("plot.title", th)$size, 17)
  expect_equal(ggplot2::calc_element("axis.text.x", th)$family, "mono")
})

test_that("F age coordinates remain group positions and the ACL alias remains supported", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- fishing_theme_fixture("ACL")
  a <- plot_fishing_mortality(fit, type = "age", return_data = TRUE)
  expect_equal(a$plot$labels$x, "Age Group")
  expect_warning(b <- plot_fishing_mortality(fit, type = "length", return_data = TRUE),
    "legacy alias")
  expect_equal(a$data, b$data)
  expect_equal(a$plot$labels, b$plot$labels)
  acl_theme_set(xlab = list(age = "My age classes"))
  expect_equal(plot_fishing_mortality(fit, type = "age")$labels$x, "My age classes")
})
