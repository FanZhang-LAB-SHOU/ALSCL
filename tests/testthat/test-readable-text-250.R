# Text in the package plots is readable under both styles: tick labels do not
# overlap, titles contrast with white, in-plot text is at least 8 points and
# sits outside the bars it labels, and long legends wrap into rows.

readable_build <- function(plot) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  ggplot2::ggplot_build(plot)
}

# Catch at age with 16 age classes: four rows of four panels.
readable_fixture <- function(ages = 16L) {
  list(model_type = "ACL", year = 2000:2005, age = seq_len(ages),
       report = list(CNA = matrix(seq_len(6L * ages) / 7, ages, 6L)))
}

test_that("the number of y breaks follows the number of panel rows", {
  expect_identical(vapply(c(1L, 2L, 3L, 4L, 6L, 10L), ALSCL:::.acl_y_n_breaks, integer(1)),
                   c(5L, 5L, 4L, 3L, 3L, 3L))
  # Evenly spaced round labels, at least three, that bracket the data, with
  # zero and a label on each side for ranges around zero.
  for (n in 3:5) for (limits in list(c(0, 1), c(-0.16, 0.13), c(-0.22, 0.21), c(-0.21, 0.16), c(6.2, 7.3),
                                     c(13.92, 13.93), c(0, 25000), c(0, 0.08), c(2.2, 3.1), c(-1, 1), c(-1.7, 0.85))) {
    b <- ALSCL:::.acl_breaks(n)(limits)
    span <- diff(limits)
    info <- paste(n, paste(limits, collapse = " "))
    # A very narrow range gets fewer, rounder labels of at most 4
    # significant digits ("13.92", "13.93") rather than "13.9225".
    expect_gte(length(b), if (identical(limits, c(13.92, 13.93))) 2L else 3L)
    expect_true(all(ALSCL:::.acl_short_number(b)), info = info)
    expect_lte(length(b), n + 2L)
    expect_true(all(b >= limits[1L] - 1e-8 & b <= limits[2L] + 1e-8), info = info)
    expect_equal(diff(b), rep(diff(b)[1L], length(b) - 1L), tolerance = 1e-8, info = info)
    expect_lte(min(b), limits[1L] + 0.25 * span + 1e-8)
    expect_gte(max(b), limits[2L] - 0.25 * span - 1e-8)
    if (limits[1L] < 0 && limits[2L] > 0) {
      expect_true(0 %in% b, info = info)
      expect_true(min(b) < 0 && max(b) > 0, info = info)
    }
  }
  # Short labels with the package label function.
  expect_identical(ALSCL:::.acl_number_labels(ALSCL:::.acl_breaks(3)(c(-0.16, 0.13))), c("-0.1", "0", "0.1"))
  # A single panel keeps the usual breaks of ggplot2 unless a label would
  # need more than 4 significant digits.
  single <- plot_recruitment(list(report = list(Rec = c(4, 6, 5, 9, 7)), year = 2000:2004))
  y_breaks <- single$scales$get_scales("y")$breaks
  expect_identical(y_breaks(c(0, 9.9)), scales::breaks_extended()(c(0, 9.9)))
  expect_gte(sum(is.finite(readable_build(single)$layout$panel_params[[1L]]$y$breaks)), 4L)
  for (style in c("default", "classic")) {
    old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
    acl_theme_set(style = style)
    p <- plot_catch(readable_fixture(), type = "CNA")
    built <- readable_build(p)
    expect_identical(max(built$layout$layout$ROW), 4L)
    counts <- vapply(built$layout$panel_params, function(x) sum(is.finite(x$y$breaks)), integer(1))
    expect_true(all(counts >= 3L & counts <= 4L), info = style)
    # Narrow columns: at most three year labels, whole years only.
    years <- built$layout$panel_params[[1L]]$x$breaks
    years <- years[is.finite(years)]
    expect_lte(length(years), 3L)
    expect_true(all(years == round(years)))
  }
  # Breaks given in the call still win.
  p <- plot_catch(readable_fixture(), type = "CNA", x_breaks = c(2001, 2003, 2005))
  expect_equal(readable_build(p)$layout$panel_params[[1L]]$x$breaks, c(2001, 2003, 2005))
})

test_that("tick labels are short numbers", {
  labels <- ALSCL:::.acl_number_labels
  expect_identical(labels(c(0, 2.5, 5, 7.5)), c("0", "2.5", "5", "7.5"))
  expect_identical(labels(c(0.1, 0.2, 0.3)), c("0.1", "0.2", "0.3"))
  expect_identical(labels(c(-1e-17, 0.05, 0.1)), c("0", "0.05", "0.1"))
  expect_identical(labels(c(0, 25000, 50000)), c("0", "25,000", "50,000"))
  expect_identical(labels(c(2000, 2010), big.mark = ""), c("2000", "2010"))
  expect_identical(labels(c(0, 1e-9, 2e-9)), c("0", "1e-09", "2e-09"))
  expect_identical(labels(c(NA, 1)), c(NA, "1"))
  p <- plot_catch(readable_fixture(), type = "CNA")
  y <- p$scales$get_scales("y")
  expect_identical(y$get_labels(c(0, 0.5, 1)), c("0", "0.5", "1"))
})

test_that("quantity titles are darkened to a contrast of at least 4.5 to 1 with white", {
  contrast <- ALSCL:::.acl_contrast_white
  expect_equal(contrast("#ffffff"), 1)
  expect_equal(contrast("#000000"), 21)
  expect_lt(contrast("#28b3e8"), 4.5)
  expect_lt(contrast("#ed5f26"), 4.5)
  for (colour in c("#28b3e8", "#ed5f26", "#00b29d", "#fda500")) {
    readable <- ALSCL:::.acl_readable_color(colour)
    expect_gte(contrast(readable), 4.5)
    # Darker than the colour itself in every channel.
    rgb <- grDevices::col2rgb(readable)[, 1L]
    expect_true(all(rgb <= grDevices::col2rgb(colour)[, 1L]))
  }
  expect_identical(ALSCL:::.acl_readable_color("#047c6c"), "#047c6c")
  expect_identical(ALSCL:::.acl_readable_color("#002b5f"), "#002b5f")
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  # Titles are black by default; title_color = "quantity" colours them.
  p <- plot_recruitment(list(report = list(Rec = c(4, 6, 5)), year = 2000:2002))
  expect_identical(ggplot2::calc_element("plot.title", ggplot2::complete_theme(readable_build(p)$plot$theme))$colour,
                   "black")
  acl_theme_set(title_color = "quantity")
  p <- plot_recruitment(list(report = list(Rec = c(4, 6, 5)), year = 2000:2002))
  built <- readable_build(p)
  title <- ggplot2::calc_element("plot.title", ggplot2::complete_theme(built$plot$theme))$colour
  expect_identical(title, ALSCL:::.acl_readable_color("#28b3e8"))
  expect_gte(contrast(title), 4.5)
  # The bars keep the exact colour.
  expect_identical(unique(built$data[[1L]]$fill), "#28b3e8")
  # A title colour given as a colour is used as given.
  acl_theme_set(title_color = "#28b3e8")
  built <- readable_build(plot_recruitment(list(report = list(Rec = c(4, 6, 5)), year = 2000:2002)))
  expect_identical(ggplot2::calc_element("plot.title", ggplot2::complete_theme(built$plot$theme))$colour, "#28b3e8")
})

test_that("text drawn in plots is at least 8 points", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  minimum <- 8 / ggplot2::.pt
  d <- expand.grid(Year = 2000:2002, RetrospectiveYear = c("2004", "2003"), Variable = "SSB")
  d$Value <- seq_len(nrow(d))
  retro <- list(results = d, last_points = d[d$Year == 2002, ],
                rho_text = data.frame(Variable = "SSB", Rho = .01))
  observations <- matrix(11:19, 3, 3)
  fit <- list(model_type = "ACL", year = 2000:2002, len_mid = c(10, 20, 30),
    len_label = c("10", "20", "30"), observations = observations,
    report = list(Elog_index = log(observations * 1.1)),
    opt = list(par = c(a = 1, b = 2), objective = 10))
  data <- data.frame(LengthBin = fit$len_label, observations, check.names = FALSE)
  names(data)[-1L] <- as.character(fit$year)
  for (style in c("default", "classic")) {
    acl_theme_set(style = style)
    metrics <- plot_compare_metrics(fit, fit, data, label_size = 1)
    plots <- c(list(plot_retro(retro)), metrics$patches$plots, list(metrics))
    for (p in plots) {
      if (!inherits(p, "ggplot") || !length(p$layers)) next
      built <- readable_build(p)
      for (i in seq_along(p$layers))
        if (inherits(p$layers[[i]]$geom, "GeomText"))
          expect_true(all(built$data[[i]]$size >= minimum - 1e-8), info = style)
    }
  }
})

test_that("bar values sit outside the end of their bars", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  observations <- matrix(11:19, 3, 3)
  fit <- list(model_type = "ACL", year = 2000:2002, len_mid = c(10, 20, 30),
    len_label = c("10", "20", "30"), observations = observations,
    report = list(Elog_index = log(observations * 1.1)),
    opt = list(par = c(a = 1, b = 2), objective = 10))
  data <- data.frame(LengthBin = fit$len_label, observations, check.names = FALSE)
  names(data)[-1L] <- as.character(fit$year)
  p <- plot_compare_metrics(fit, fit, data, metrics = c("error", "IC"))
  for (panel in p$patches$plots) {
    if (!inherits(panel, "ggplot") || !length(panel$layers)) next
    built <- readable_build(panel)
    text <- built$data[[2L]]
    bars <- built$data[[1L]]
    # Horizontal bars: each value is horizontal, in the row of its bar, and
    # runs away from the end of the bar (left of a negative bar end).
    expect_equal(sort(text$y), sort(bars$y))
    expect_equal(sort(text$x), sort(bars$x))
    expect_true(all(text$angle == 0))
    negative <- text$x < 0
    expect_true(all(text$hjust[negative] == 1) && all(text$hjust[!negative] == 0))
    # The axis leaves room beyond the longest bar.
    range <- built$layout$panel_params[[1L]]$x.range
    expect_gt(range[2L], max(0, bars$x) + 0.1 * diff(range(c(0, bars$x))))
    if (any(negative)) expect_lt(range[1L], min(bars$x) - 0.1 * diff(range(c(0, bars$x))))
  }
})

test_that("long bottom legends wrap into rows and long facet labels are kept whole", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  periods <- as.character(2010:2003)
  d <- expand.grid(Year = 2000:2002, RetrospectiveYear = periods, Variable = "SSB",
                   stringsAsFactors = FALSE)
  d$Value <- seq_len(nrow(d))
  d$RetrospectiveYear <- factor(d$RetrospectiveYear, levels = periods)
  retro <- list(results = d, last_points = d[d$Year == 2002, ],
                rho_text = data.frame(Variable = "SSB", Rho = .01))
  guide <- plot_retro(retro)$scales$get_scales("colour")$guide
  expect_equal(guide$params$nrow, 2)
  expect_equal(ALSCL:::.acl_legend_rows(4L)$params$nrow, 1)
  # Strip labels longer than a narrow panel holds are wrapped under the
  # classic style; plain strips may run past their panel and keep one line.
  m <- list(model_type = "ALSCL", year = 2000:2002,
            len_label = paste0(seq(100.5, by = 5, length.out = 25)),
            report = list(CNL = matrix(seq_len(75), 25, 3)))
  plain <- plot_catch(m, type = "CNL")
  expect_identical(ggplot2::calc_element("strip.clip", ggplot2::complete_theme(plain$theme)), "off")
  expect_identical(plain$facet$params$labeller, ggplot2::label_value)
  acl_theme_set(style = "classic")
  # Boxed strips: the default layout takes fewer columns so that the labels
  # stay on one line; six columns given in the call wrap them.
  boxed <- plot_catch(m, type = "CNL")
  expect_identical(boxed$facet$params$labeller, ggplot2::label_value)
  expect_lt(boxed$facet$params$ncol, 5L)
  boxed <- plot_catch(m, type = "CNL", facet_ncol = 6)
  expect_false(identical(boxed$facet$params$labeller, ggplot2::label_value))
  expect_match(boxed$facet$params$labeller(data.frame(LengthGroup = "Length bin 120.5"))[[1L]], "\n")
})
