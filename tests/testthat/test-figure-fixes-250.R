# Corrections found when every documentation figure of 2.5.0 was opened:
# error bars on dark bars, caps, value labels of plot_compare_metrics(),
# points at the panel border, the growth annotation, line weights, long tick
# labels, wrapped strips, x_angle checks, palette names and year labels of
# single panels.

fix_build <- function(plot) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  ggplot2::ggplot_build(plot)
}

# A fit with total catch and recruitment and their standard errors.
fix_series <- function(years) {
  n <- length(years)
  est <- 1000 * (1 + 0.3 * sin(seq_len(n)))
  std <- rbind(cbind(Estimate = est, `Std. Error` = est / 5),
               cbind(Estimate = est / 2, `Std. Error` = est / 10))
  rownames(std) <- c(rep("CN", n), rep("Rec", n))
  list(model_type = "ACL", year = years, growth_step = if (n > 1L) min(diff(years)) else 1,
       report = list(CN = est, Rec = est / 2), est_std = std)
}

layer_index <- function(p, geom) which(vapply(p$layers, function(l) inherits(l$geom, geom), logical(1)))

test_that("error bars on bars have a white underlay and caps a third of the bar width", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  cases <- list(2001, 2001:2002, 2001.25, c(2001, 2001.25), 2001:2020, seq(2001, 2005.75, by = 0.25))
  for (years in cases) {
    fit <- fix_series(years)
    for (p in list(plot_catch(fit, se = TRUE), plot_recruitment(fit, se = TRUE))) {
      bars <- layer_index(p, "GeomErrorbar")
      expect_length(bars, 2L)
      # The white bar comes first, under the dark one, with a wider line.
      under <- p$layers[[bars[1L]]]$aes_params
      over <- p$layers[[bars[2L]]]$aes_params
      expect_identical(under$colour, "white")
      expect_false(identical(over$colour, "white"))
      expect_gt(under$linewidth, over$linewidth)
      built <- fix_build(p)
      col <- built$data[[layer_index(p, "GeomCol")]]
      cap <- built$data[[bars[2L]]]
      ratio <- (cap$xmax - cap$xmin) / (col$xmax - col$xmin)
      expect_equal(ratio, rep(1 / 3, length(years)), tolerance = 1e-8, info = paste(years, collapse = " "))
      # The cap of the underlay is not wider than the dark cap.
      white <- built$data[[bars[1L]]]
      expect_equal(white$xmax - white$xmin, cap$xmax - cap$xmin)
    }
  }
  # Error bars of a recruitment line: a quarter of the time step.
  quarterly <- fix_series(seq(2001, 2005.75, by = 0.25))
  p <- plot_recruitment(quarterly, se = TRUE, geom = "line", se_type = "errorbar")
  cap <- fix_build(p)$data[[layer_index(p, "GeomErrorbar")[1L]]]
  expect_equal(unique(round(cap$xmax - cap$xmin, 8)), round(0.25 * 0.25, 8))
  # A colour and alpha given in the call reach the dark bar.
  p <- plot_catch(fix_series(2001:2005), se = TRUE, se_color = "red", se_alpha = 0.5)
  over <- p$layers[[layer_index(p, "GeomErrorbar")[2L]]]$aes_params
  expect_identical(over$colour, "red")
  expect_identical(over$alpha, 0.5)
})

metrics_fixture <- function() {
  observations <- matrix(c(11:19, 25:33), 3, 6)
  fit <- list(model_type = "ACL", year = 2000:2005, len_mid = c(10, 20, 30),
              len_label = c("10", "20", "30"), observations = observations,
              report = list(Elog_index = log(observations * 1.1)),
              opt = list(par = c(a = 1, b = 2), objective = 660.4))
  other <- fit
  other$report$Elog_index <- log(observations * 0.97)
  other$opt$objective <- -28.61
  data <- data.frame(LengthBin = fit$len_label, observations, check.names = FALSE)
  names(data)[-1L] <- as.character(fit$year)
  list(fit = fit, other = other, data = data)
}

test_that("values of plot_compare_metrics() are horizontal and just beyond the end of their bars", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  m <- metrics_fixture()
  for (style in c("default", "classic")) {
    acl_theme_set(style = style)
    p <- plot_compare_metrics(m$fit, m$other, m$data)
    for (panel in p$patches$plots) {
      if (!inherits(panel, "ggplot") || !length(panel$layers)) next
      built <- fix_build(panel)
      bars <- built$data[[layer_index(panel, "GeomCol")]]
      text <- built$data[[layer_index(panel, "GeomText")]]
      # No turned labels; each label sits in the row of its bar.
      expect_true(all(text$angle == 0))
      expect_equal(sort(text$y), sort(bars$y))
      value <- text$x
      negative <- value < 0
      expect_true(all(text$hjust[negative] == 1) && all(text$hjust[!negative] == 0))
      # At most three significant digits.
      shown <- as.numeric(trimws(text$label))
      expect_equal(shown, signif(shown, 3))
      # The axis leaves room for the label beyond the longest bar on each
      # side used: at least one character more than the label.
      range <- built$layout$panel_params[[1L]]$x.range
      room <- function(label) (nchar(label) + 1) * 0.6 * text$size[1L] * ggplot2::.pt / 72 / 2.6 * diff(range)
      if (any(!negative)) expect_gt(range[2L], max(value) + 0.9 * room(trimws(text$label[which.max(value)])))
      if (any(negative)) expect_lt(range[1L], min(value) - 0.9 * room(trimws(text$label[which.min(value)])))
      # The bars of one statistic do not overlap.
      for (row in split(bars, round(bars$y))) if (nrow(row) == 2L)
        expect_true(max(row$ymin) >= min(row$ymax) - 1e-8)
    }
  }
  # R-squared runs from 0 to 1 plus the room of the labels, not to 1.5.
  options(acl.theme = NULL)
  r2 <- plot_compare_metrics(m$fit, m$other, m$data, metrics = "R2")
  r2 <- if (inherits(r2, "patchwork")) r2[[1L]] else r2
  range <- fix_build(r2)$layout$panel_params[[1L]]$x.range
  expect_equal(range[1L], 0)
  expect_gt(range[2L], 1)
  expect_lt(range[2L], 1.4)
})

test_that("points at the ends of the x axis are inside the panel and x_expand wins", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- list(model_type = "ACL", year = 2000:2019, report = list(SSB = 50 + sin(1:20) * 10,
                                                                    Rec = 100 + cos(1:20) * 20))
  mult <- function(p) as.numeric(p$scales$get_scales("x")$expand)[c(1L, 3L)]
  p <- plot_SSB_Rec(fit)
  expect_true(all(mult(p) >= 0.03))
  # Lines without points keep the default expansion.
  expect_equal(mult(plot_SSB(list(model_type = "ACL", year = 2000:2019, report = list(SSB = 1:20)))),
               c(0.01, 0.01))
  # Narrow facet panels get the radius of a point.
  room <- ALSCL:::.acl_point_room
  scale <- ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.01, 0.01)))
  wide <- as.numeric(room(p, scale, 1L)$expand)[1L]
  narrow <- as.numeric(room(p, scale, 6L)$expand)[1L]
  expect_gt(narrow, wide)
  acl_theme_set(x_expand = c(0, 0))
  expect_equal(mult(plot_SSB_Rec(fit)), c(0, 0))
})

test_that("the growth annotation is smaller, at least 8 pt, and clear of the data", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- list(model_type = "ACL", age = 1:15, report = list(Linf = 60, vbk = 0.2, t0 = -0.5))
  text_layer <- function(p) p$layers[[layer_index(p, "GeomText")]]
  p <- plot_VB(fit)
  expect_equal(text_layer(p)$aes_params$size, 3.5)
  expect_identical(text_layer(p)$aes_params$hjust, 0)
  expect_equal(text_layer(plot_VB(fit, text_size = 1))$aes_params$size, 8 / ggplot2::.pt)
  expect_equal(text_layer(plot_VB(fit, text_size = 5))$aes_params$size, 5)
  # Observations in the upper left corner move the text to the lower right.
  readings <- data.frame(age = 1:3, mean_length = c(58, 59, 60))
  moved <- text_layer(plot_VB(fit, observed = readings))
  expect_identical(moved$aes_params$hjust, 1)
  expect_identical(moved$data$x, Inf)
  expect_identical(moved$data$y, -Inf)
  corner <- ALSCL:::.acl_annotation_corner
  expect_identical(corner(data.frame(x = 1:10, y = 1:10), 30, 2, 3.5), "top_left")
  expect_identical(corner(data.frame(x = 1:10, y = 10:1), 30, 2, 3.5), "bottom_right")
})

test_that("line widths follow the style and explicit values win", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- list(model_type = "ACL", year = 2000:2019, report = list(SSB = 1:20 + 10))
  width <- function(p) as.numeric(p$layers[[1L]]$aes_params$linewidth)
  expect_identical(acl_theme("line_size"), 1)
  expect_identical(acl_theme("compare_line_size"), 0.9)
  expect_identical(width(plot_SSB(fit)), 1)
  expect_identical(ALSCL:::.acl_compare_defaults()$line_size, structure(0.9, acl_auto = TRUE))
  acl_theme_set(style = "classic")
  expect_identical(acl_theme("line_size"), 1.5)
  expect_identical(acl_theme("compare_line_size"), 1.2)
  expect_identical(width(plot_SSB(fit)), 1.5)
  # The classic width is still thinned in dense facets.
  expect_true(isTRUE(attr(ALSCL:::.acl_auto_size(), "acl_auto")))
  acl_theme_set(style = "default", line_size = 2)
  expect_identical(acl_theme("line_size"), 2)
  expect_null(attributes(ALSCL:::.acl_auto_size()))
  expect_identical(width(plot_SSB(fit, line_size = 0.4)), 0.4)
})

test_that("tick labels have at most 4 significant digits", {
  breaks <- ALSCL:::.acl_breaks
  short <- ALSCL:::.acl_short_number
  for (limits in list(c(13.9, 13.95), c(13.92, 13.93), c(13.915, 13.935), c(0.12335, 0.1236),
                      c(1000.6, 1002.4), c(-0.5, 2.5), c(0, 1e6))) {
    for (n in 3:5) {
      b <- breaks(n)(limits)
      expect_true(length(b) >= 1L, info = paste(limits, collapse = " "))
      expect_true(all(short(b)), info = paste(limits, collapse = " "))
      expect_true(all(b >= min(limits) - 1e-9 & b <= max(limits) + 1e-9))
    }
  }
  expect_false(any(short(c(13.9225, 0.12345))))
  # A range that holds no value of 4 significant digits gets the fewest
  # digits that label it.
  expect_true(all(short(breaks(5)(c(13.9201, 13.9299)), 5L)))
  # Single panels keep the breaks of ggplot2 unless a label would be long.
  single <- ALSCL:::.acl_short_breaks()
  expect_identical(single(c(0, 1234)), scales::breaks_extended()(c(0, 1234)))
  expect_true(all(short(single(c(13.921, 13.929)), 5L)))
  expect_true(all(short(single(c(13.9, 13.95)))))
})

test_that("facet columns keep strip labels on one line", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  columns <- ALSCL:::.acl_facet_columns
  expect_identical(columns(23), 6L)
  expect_identical(columns(23, nchar("Length bin 122.5")), 5L)
  expect_identical(columns(20, nchar("Length bin 12.5")), 5L)
  expect_false(ALSCL:::.acl_strip_wraps(nchar("Length bin 122.5"), 5L))
  expect_true(ALSCL:::.acl_strip_wraps(nchar("Length bin 122.5"), 6L))
  # Labels too long for any grid keep the usual layout.
  expect_identical(columns(23, 200), 6L)
  fit <- list(model_type = "ACL", year = 2000:2019,
              len_label = as.character(seq(12.5, by = 5, length.out = 23)),
              report = list(SBL = matrix(seq_len(23 * 20), 23, 20)))
  p <- plot_SSB(fit, type = "SBL")
  expect_identical(p$facet$params$ncol, 5L)
  expect_identical(p$facet$params$labeller, ggplot2::label_value)
  # facet_ncol in the call wins.
  expect_identical(plot_SSB(fit, type = "SBL", facet_ncol = 6)$facet$params$ncol, 6)
})

test_that("acl_theme_set() and theme_acl() check x_angle the same way", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  message <- "x_angle must be NULL or one number of degrees between -90 and 90."
  for (bad in list(120, -91, "steep", c(10, 20), NA_real_, Inf)) {
    expect_error(acl_theme_set(x_angle = bad), message, fixed = TRUE)
    expect_error(theme_acl(x_angle = bad), message, fixed = TRUE)
  }
  expect_no_error(theme_acl(x_angle = -90))
  expect_no_error(acl_theme_set(x_angle = 90))
})

test_that("plot_ridges() matches every palette name without regard to case", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  ridges <- ALSCL:::.acl_ridges_palette
  expect_identical(ridges("Default", 3L)$palette(3L), ridges("default", 3L)$palette(3L))
  expect_identical(ridges("NPG", 3L)$palette(3L), ridges("npg", 3L)$palette(3L))
  expect_identical(ridges("RDBU", 3L)$palette(3L), ridges("RdBu", 3L)$palette(3L))
  expect_identical(ridges("prgn", 3L)$palette(3L), ridges("PRGn", 3L)$palette(3L))
  expect_message(ridges("nonsense", 3L), "default")
})

test_that("single-panel plots follow x_angle and x_breaks from the call or the theme", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- list(model_type = "ACL", year = 2000:2019,
              report = list(SSB = 1:20 + 10, Rec = 1:20 + 5, CN = 1:20 + 2))
  labels <- function(p) {
    labels <- fix_build(p)$layout$panel_params[[1L]]$x$get_labels()
    labels[!is.na(labels)]
  }
  acl_theme_set(x_angle = 45)
  for (p in list(plot_SSB(fit), plot_recruitment(fit), plot_catch(fit)))
    expect_identical(p$theme$axis.text.x$angle, 45)
  acl_theme_set(x_angle = NULL, x_breaks = c(2000, 2010))
  for (p in list(plot_SSB(fit), plot_recruitment(fit), plot_catch(fit)))
    expect_identical(labels(p), c("2000", "2010"))
  options(acl.theme = NULL)
  expect_identical(labels(plot_SSB(fit, x_breaks = c(2005, 2015))), c("2005", "2015"))
})

test_that("help titles name the quantity as the figure does", {
  db <- tools::Rd_db("ALSCL")
  title <- function(name) {
    rd <- db[[paste0(name, ".Rd")]]
    tag <- vapply(rd, function(x) attr(x, "Rd_tag"), character(1))
    paste(unlist(rd[[which(tag == "\\title")]]), collapse = "")
  }
  expect_match(title("plot_relative_catch"), "Catch relative to its mean", ignore.case = TRUE)
  expect_match(title("relative_catch"), "Catch relative to its mean", ignore.case = TRUE)
  expect_false(grepl("relative catch", title("plot_relative_catch"), fixed = TRUE))
  expect_match(title("plot_deviance"), "log recruitment", fixed = TRUE)
  expect_false(grepl("SBL|SBA", title("plot_SSB")))
})

test_that("error bars on points and lines have short caps, also for a single x value", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  cap <- ALSCL:::.acl_cap_width
  expect_equal(cap(2000:2010), 0.25)
  expect_equal(cap(seq(2000, 2002, by = 0.25)), 0.0625)
  expect_equal(cap(2005), 0.06)
  panel_share <- function(p) {
    built <- fix_build(p)
    bar <- built$data[[layer_index(p, "GeomErrorbar")[1L]]]
    range <- built$layout$panel_params[[1L]]$x.range
    unique(round((bar$xmax - bar$xmin) / diff(range), 6))
  }
  # One time step: a point with an error bar whose cap stays short.
  one <- list(model_type = "ACL", year = 2019, report = list(SSB = 50),
              est_std = matrix(c(50, 5), 1L, dimnames = list("SSB", c("Estimate", "Std. Error"))))
  p <- plot_SSB(one, se = TRUE)
  expect_lt(panel_share(p), 0.1)
  expect_lt(panel_share(p + ggplot2::coord_cartesian(xlim = 2019 + c(-0.5, 0.5))), 0.1)
  # Lines with error bars: a quarter of the time step.
  fit <- fix_series(2001:2020)
  p <- plot_recruitment(fit, se = TRUE, geom = "line", se_type = "errorbar")
  bar <- fix_build(p)$data[[layer_index(p, "GeomErrorbar")[1L]]]
  expect_equal(unique(round(bar$xmax - bar$xmin, 8)), 0.25)
  # plot_deviance(): a quarter of the time step unless se_width is given.
  years <- 2001:2010
  dev <- list(model_type = "ACL", year = years, report = list(dev_log_R = sin(seq_along(years)) / 3),
              est_std = matrix(c(sin(seq_along(years)) / 3, rep(0.1, 10)), 10L,
                               dimnames = list(rep("dev_log_R", 10), c("Estimate", "Std. Error"))))
  deviance <- plot_deviance(dev, se = TRUE)
  bar <- fix_build(deviance)$data[[layer_index(deviance, "GeomErrorbar")[1L]]]
  expect_equal(unique(round(bar$xmax - bar$xmin, 8)), 0.25)
  given <- plot_deviance(dev, se = TRUE, se_width = 0.5)
  bar <- fix_build(given)$data[[layer_index(given, "GeomErrorbar")[1L]]]
  expect_equal(unique(round(bar$xmax - bar$xmin, 8)), 0.5)
})

test_that("points get room at the panel border on axes without a scale of their own", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  d <- expand.grid(lag = 1:4, bin = paste("Length bin", 1:23))
  d$correlation <- sin(seq_len(nrow(d)))
  p <- ggplot2::ggplot(d, ggplot2::aes(lag, correlation)) + ggplot2::geom_point() +
    ggplot2::facet_wrap(~bin)
  tidy <- ALSCL:::.acl_tidy_axes(p)
  x <- as.numeric(tidy$scales$get_scales("x")$expand)
  expect_gt(x[1L], 0.05)
  # Room on y too, in short facet panels.
  y <- tidy$scales$get_scales("y")$expand
  expect_gt(as.numeric(y)[1L], 0.05)
  # Lines alone keep the default of ggplot2, and a plot's own expansion stays.
  lines <- ALSCL:::.acl_tidy_axes(ggplot2::ggplot(d, ggplot2::aes(lag, correlation)) + ggplot2::geom_line())
  expect_null(lines$scales$get_scales("x"))
  own <- ALSCL:::.acl_tidy_axes(p + ggplot2::scale_x_continuous(expand = ggplot2::expansion(0)))
  expect_equal(as.numeric(own$scales$get_scales("x")$expand), c(0, 0, 0, 0))
})
