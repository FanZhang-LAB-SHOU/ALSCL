# Axis labels of the documentation figures of version 2.5.2: the first and
# the last time step of a discrete time axis carry a label, the last label
# of an age or a length axis and the end labels of facet_grid() time axes
# have room, tick labels are decimal numbers from 0.0001 up to below 1e9
# and powers of ten with a raised exponent outside that range, never in E
# notation, and the message for a selection lists the unused entries
# without padding.

axis_build <- function(plot) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  ggplot2::ggplot_build(plot)
}
axis_theme <- function(p) ggplot2::complete_theme(p$theme)
# Labels as text: a plotmath expression deparsed, such as "1 %*% 10^-9".
# A built plot holds expression labels as a list of calls.
axis_text <- function(labels) {
  if (is.character(labels)) return(labels)
  vapply(seq_along(labels), function(i) paste(deparse(labels[[i]]), collapse = ""), character(1))
}
# TRUE when the labels are plotmath expressions.
axis_math <- function(labels) !is.character(labels) && any(vapply(labels, is.call, logical(1)))
axis_right_margin <- function(p) as.numeric(ggplot2::calc_element("plot.margin", axis_theme(p)))[2L]
# The last tick label of the x axis of the first panel.
axis_last_x <- function(p) {
  labels <- axis_build(p)$layout$panel_params[[1L]]$x$get_labels()
  utils::tail(labels[!is.na(labels)], 1L)
}
# A result with 20 years, 15 age classes (the oldest a plus group) and 23
# length bins, as in the YTF example.
axis_fixture <- function(years = 2000:2019, ages = 15L, lengths = 23L) {
  Y <- length(years)
  mid <- seq(6, by = 2, length.out = lengths)
  list(model_type = "ACL", year = years, age = seq_len(ages), growth_step = 1,
       len_mid = mid, len_label = as.character(mid),
       report = list(F = matrix(0.2 + seq_len(Y * ages) / 1000, ages, Y),
                     SBL = matrix(seq_len(Y * lengths) / 3, lengths, Y)))
}

test_that("a discrete time axis labels its first and its last time step", {
  breaks <- ALSCL:::.acl_discrete_breaks(16L)
  years <- as.character(2000:2019)
  expect_identical(breaks(years), as.character(c(seq(2000, 2016, by = 2), 2019)))
  quarters <- sprintf("%d Q%d", rep(2000:2004, each = 4L), rep(1:4, 5L))
  expect_identical(breaks(quarters), c(quarters[seq(1L, 17L, by = 2L)], "2004 Q4"))
  expect_identical(breaks(paste("Year", 2000:2016)), paste("Year", seq(2000, 2016, by = 2)))
  expect_identical(breaks(years[1:16]), years[1:16])
  # Other categories keep every k-th one from the first.
  expect_identical(breaks(paste("Length bin", 1:20)), paste("Length bin", seq(1, 19, by = 2)))
  # The year axis of the ridges of a 20-year series.
  observations <- matrix(exp(seq(1, 3, length.out = 60)), 3, 20)
  survey <- list(model_type = "ACL", year = 2000:2019, len_mid = c(10, 20, 30), len_label = c("10", "20", "30"),
                 observations = observations, report = list(Elog_index = log(observations) + 0.1))
  panels <- ALSCL:::.acl_patches(plot_ridges(survey))$plots
  expect_length(panels, 2L)
  for (panel in panels) {
    labels <- axis_build(panel)$layout$panel_params[[1L]]$y$get_labels()
    labels <- labels[!is.na(labels)]
    expect_identical(labels[c(1L, length(labels))], c("2000", "2019"))
    expect_false("2018" %in% labels)
  }
})

test_that("the last label of an age or a length axis has room at the right edge, in both styles", {
  withr::local_options(list(acl.theme = NULL))
  fit <- axis_fixture()
  lengths <- data.frame(length = fit$len_mid, value = seq_along(fit$len_mid))
  for (style in c("default", "classic")) {
    acl_theme_set(style = style)
    # "15+" at the plus group: 3 characters of 6 points, half beyond the panel.
    p <- plot_fishing_mortality(fit, type = "age")
    expect_identical(axis_last_x(p), "15+")
    expect_gte(axis_right_margin(p), 3 / 2 * 6 + 1)
    # A length axis whose last label, "50", is at the end of the panel.
    q <- ALSCL:::.acl_tidy_axes(ggplot2::ggplot(lengths, ggplot2::aes(length, value)) + ggplot2::geom_line() +
                                  ALSCL:::.acl_scale_x(NULL, n_breaks = 10, values = fit$len_mid) + theme_acl())
    expect_identical(axis_last_x(q), "50")
    expect_gte(axis_right_margin(q), 2 / 2 * 6 + 1)
    # A last label well inside the panel needs no room.
    r <- ALSCL:::.acl_tidy_axes(ggplot2::ggplot(data.frame(x = c(1, 9.5), y = 1:2), ggplot2::aes(x, y)) +
                                  ggplot2::geom_line() + ALSCL:::.acl_scale_x(NULL, auto_breaks = c(2, 4, 6, 8)))
    expect_null(r$theme$plot.margin)
  }
})

test_that("time axes of facet_grid() layouts get the room of facet_wrap() layouts between columns", {
  withr::local_options(list(acl.theme = NULL))
  d <- expand.grid(year = 2000:2019, mode = c("A", "B"), bin = c("small", "large"))
  d$value <- seq_len(nrow(d))
  base <- ggplot2::ggplot(d, ggplot2::aes(year, value)) + ggplot2::geom_line() +
    ALSCL:::.acl_scale_x(values = d$year, time = TRUE)
  grid <- base + ggplot2::facet_grid(bin ~ mode, scales = "free_y")
  expect_identical(ALSCL:::.acl_facet_dims(grid), c(rows = 2L, cols = 2L, panels = 4L))
  spacing <- function(p) grid::convertWidth(ggplot2::calc_element("panel.spacing.x", axis_theme(p)), "pt",
                                           valueOnly = TRUE)
  tidy_grid <- ALSCL:::.acl_tidy_axes(grid)
  # The rows of facet_grid() share one y axis at the left, as panels of
  # facet_wrap() with fixed scales do.
  tidy_wrap <- ALSCL:::.acl_tidy_axes(base + ggplot2::facet_wrap(~mode))
  expect_gt(spacing(tidy_grid), 5.5)
  expect_equal(spacing(tidy_grid), spacing(tidy_wrap))
  expect_equal(axis_right_margin(tidy_grid), axis_right_margin(tidy_wrap))
})

test_that("tick labels are decimals from 0.0001 up to below 1e9 and powers of ten outside, never in E notation", {
  labels <- function(x, ...) axis_text(ALSCL:::.acl_number_labels(x, ...))
  # Decimal numbers without trailing zeros, with thousands separators.
  expect_identical(labels(c(0, 0.00025, 0.0005, 0.00075)), c("0", "0.00025", "0.0005", "0.00075"))
  expect_identical(labels(c(0, 2.5e8, 5e8, 7.5e8)), c("0", "250,000,000", "500,000,000", "750,000,000"))
  expect_identical(labels(c(2000, 2010), big.mark = ""), c("2000", "2010"))
  expect_type(ALSCL:::.acl_number_labels(c(0, 0.5, 1)), "character")
  # Outside that range every label of the axis is a power of ten; zero stays 0.
  expect_true(is.expression(ALSCL:::.acl_number_labels(c(0, 5e-10, 1e-9))))
  expect_identical(labels(c(0, 5e-10, 1e-9, 1.5e-9)), c("0", "5 %*% 10^-10", "1 %*% 10^-9", "1.5 %*% 10^-9"))
  expect_identical(labels(c(0, 5e-5, 1e-4, 1.5e-4)), c("0", "5 %*% 10^-5", "1 %*% 10^-4", "1.5 %*% 10^-4"))
  expect_identical(labels(c(5e8, 1e9, 1.5e9)), c("5 %*% 10^8", "1 %*% 10^9", "1.5 %*% 10^9"))
  expect_identical(labels(c(-2.5e9, 0, 2.5e9)), c("-2.5 %*% 10^9", "0", "2.5 %*% 10^9"))
  expect_identical(labels(c(NA, 1e-12, 2e-12)), c("NA", "1 %*% 10^-12", "2 %*% 10^-12"))
  # Rounding error next to zero reads 0; a small value of a log axis does not.
  expect_identical(labels(c(-1e-17, 0.05, 0.1)), c("0", "0.05", "0.1"))
  expect_identical(labels(c(1e-9, 1e-5, 0.1, 1000)), c("1 %*% 10^-9", "1 %*% 10^-5", "1 %*% 10^-1", "1 %*% 10^3"))
  # Breaks of very small and very large ranges have at most 4 significant digits.
  for (limits in list(c(0, 1.4e-9), c(2e-9, 7e-9), c(-2.2e-8, 4.1e-8), c(0, 3.7e12)))
    for (b in list(ALSCL:::.acl_breaks(4L)(limits), ALSCL:::.acl_short_breaks()(limits))) {
      b <- b[is.finite(b)]
      expect_gte(length(b), 2L)
      expect_true(all(ALSCL:::.acl_short_number(b)), info = paste(limits, collapse = " "))
      expect_false(any(grepl("e", labels(b))))
    }
  # Spawning stock biomass at length: decimal panels and power-of-ten panels.
  fit <- axis_fixture()
  fit$report$SBL[1:3, ] <- fit$report$SBL[1:3, ] * 1e-9
  fit$report$SBL[7, ] <- fit$report$SBL[7, ] * 1e10
  p <- plot_SSB(fit, type = "SBL")
  built <- axis_build(p)
  shown <- lapply(built$layout$panel_params, function(x) x$y$get_labels())
  powers <- vapply(shown, axis_math, logical(1))
  expect_identical(which(powers), c(1L, 2L, 3L, 7L))
  for (panel in shown) {
    text <- axis_text(panel)
    expect_false(any(grepl("e", text[!is.na(text)])))
    if (axis_math(panel)) expect_true(all(grepl("^(0|[-0-9.]+ %[*]% 10\\^-?[0-9]+)$", text[!is.na(text)])))
  }
  # Expression labels draw with check.overlap and give a figure size.
  expect_true(isTRUE(p$scales$get_scales("y")$guide$params$check.overlap))
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_no_error(ggplot2::ggplotGrob(p))
  size <- acl_figure_size(p)
  expect_true(all(is.finite(size)) && size[["width"]] == 10)
})

test_that("log axes passed through the package keep their breaks and get no E notation", {
  d <- data.frame(original = 10^seq(-12, 3, length.out = 30), new = 10^seq(-12, 3, length.out = 30) * 1.01)
  base <- ggplot2::ggplot(d, ggplot2::aes(original, new)) + ggplot2::geom_point() + theme_acl()
  # Labels of the call (scales::label_log(), as in the speed figure) are kept.
  given <- ALSCL:::.acl_tidy_axes(base + ggplot2::scale_x_log10(labels = scales::label_log()) +
                                    ggplot2::scale_y_log10(labels = scales::label_log()))
  built <- axis_build(given)$layout$panel_params[[1L]]
  expect_true(axis_math(built$y$get_labels()))
  shown <- axis_text(built$y$get_labels())
  expect_identical(shown[shown != "NA"], c("10^-9", "10^-5", "10^-1", "10^3"))
  # Without labels in the call: powers of ten of the package.
  plain <- ALSCL:::.acl_tidy_axes(base + ggplot2::scale_x_log10() + ggplot2::scale_y_log10())
  labels <- axis_text(axis_build(plain)$layout$panel_params[[1L]]$x$get_labels())
  # 1e-9 keeps its value next to 1000: no label of a log axis reads 0.
  expect_identical(labels[labels != "NA"], c("1 %*% 10^-9", "1 %*% 10^-5", "1 %*% 10^-1", "1 %*% 10^3"))
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_no_error(ggplot2::ggplotGrob(given))
  expect_no_error(ggplot2::ggplotGrob(plain))
})

test_that("a selection with no available entry is named without padding", {
  expect_error(ALSCL:::.acl_select_available(c("RMSE", "R3"), c("error", "R2"), "metrics", "the panels"),
               "No requested metrics occur in the panels (RMSE, R3).", fixed = TRUE)
  expect_warning(ALSCL:::.acl_select_available(c(2001, 2030.5), c(2000, 2001), "years", "data.CatL"),
                 "Left out years that do not occur in data.CatL: 2030.5.", fixed = TRUE)
})
