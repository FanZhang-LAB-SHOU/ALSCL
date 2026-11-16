# Time axes, layouts, line weights, titles and figure sizes of the package
# plots: one rule for every plot, and user settings win over automatic ones.

layout_build <- function(plot) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  ggplot2::ggplot_build(plot)
}

# Total recruitment, catch at age and SSB at length of a fit with `years`.
layout_fixture <- function(years = 2000:2019, ages = 15L, lengths = 23L) {
  Y <- length(years)
  list(model_type = "ACL", year = years, age = seq_len(ages), growth_step = 1,
       len_label = as.character(seq(6, by = 2, length.out = lengths)),
       report = list(Rec = 100 + 10 * sin(seq_len(Y)), SSB = 50 + seq_len(Y),
                     CNA = matrix(seq_len(Y * ages) / 7, ages, Y),
                     SBL = matrix(seq_len(Y * lengths) / 3, lengths, Y)))
}

x_labels <- function(plot, panel = 1L) {
  labels <- layout_build(plot)$layout$panel_params[[panel]]$x$get_labels()
  labels[!is.na(labels)]
}

png_size <- function(file) {
  header <- readBin(file, "raw", 24L)
  c(width = sum(as.integer(header[17:20]) * 256^(3:0)), height = sum(as.integer(header[21:24]) * 256^(3:0)))
}

test_that("one rule labels the years of a time axis that spans the figure", {
  step <- ALSCL:::.acl_time_label_step
  expect_identical(vapply(c(5, 12, 13, 30, 31, 60, 61, 120), step, numeric(1)), c(1, 1, 2, 2, 5, 5, 10, 10))
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  for (case in list(list(2008:2019, as.character(2008:2019)), list(2000:2019, as.character(seq(2000, 2018, 2))),
                    list(1971:2019, as.character(seq(1975, 2015, 5))), list(1930:2019, as.character(seq(1930, 2010, 10))))) {
    fit <- layout_fixture(case[[1L]])
    for (p in list(plot_recruitment(fit), plot_recruitment(fit, geom = "line"), plot_SSB(fit))) {
      expect_identical(x_labels(p), case[[2L]])
      # Unlabelled minor tick marks at every year, the first and last included.
      minor <- layout_build(p)$layout$panel_params[[1L]]$x$get_breaks_minor()
      expect_true(all(range(case[[1L]]) %in% round(minor, 8)))
      expect_true(isTRUE(p$scales$get_scales("x")$guide$params$minor.ticks))
      # Single panels keep horizontal labels.
      expect_null(p$theme$axis.text.x$angle)
    }
  }
  # Quarterly series: labels at the start of years, minor ticks at the quarters.
  quarterly <- list(model_type = "ACL", year = 2000 + (0:19) / 4, growth_step = 0.25,
                    report = list(Rec = 100 + sin(1:20)))
  p <- plot_recruitment(quarterly)
  expect_identical(x_labels(p), as.character(2000:2004))
  minor <- layout_build(p)$layout$panel_params[[1L]]$x$get_breaks_minor()
  expect_true(all(c(2000.25, 2000.5, 2004.75) %in% round(minor, 8)))
})

test_that("faceted time axes keep their density and slant labels that would touch", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- layout_fixture()
  # 15 age classes: five columns of narrow panels, every fifth year slanted.
  p <- plot_catch(fit, type = "CNA")
  expect_identical(p$facet$params$ncol, 5L)
  expect_identical(x_labels(p), c("2000", "2005", "2010", "2015"))
  expect_identical(p$theme$axis.text.x$angle, 45)
  expect_identical(c(p$theme$axis.text.x$hjust, p$theme$axis.text.x$vjust), c(1, 1))
  # Two columns: every second year, horizontal.
  two <- plot_catch(fit, type = "CNA", facet_ncol = 2)
  expect_identical(x_labels(two), as.character(seq(2000, 2018, 2)))
  expect_null(two$theme$axis.text.x$angle)
  # The theme key x_angle fixes the angle: 0 keeps the labels horizontal and
  # thins them, a number slants them.
  acl_theme_set(x_angle = 0)
  flat <- plot_catch(fit, type = "CNA")
  expect_null(flat$theme$axis.text.x$angle)
  expect_identical(x_labels(flat), c("2000", "2010"))
  acl_theme_set(x_angle = 90)
  expect_identical(plot_catch(fit, type = "CNA")$theme$axis.text.x$angle, 90)
  expect_identical(plot_recruitment(fit)$theme$axis.text.x$angle, 90)
  acl_theme_set(x_angle = NULL)
  expect_null(acl_theme("x_angle"))
  expect_error(acl_theme_set(x_angle = "steep"), "x_angle must be NULL")
  # A theme element added by the user wins over the automatic angle.
  own <- p + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 0, hjust = 0.5))
  expect_identical(ggplot2::calc_element("axis.text.x", ggplot2::complete_theme(own$theme))$angle, 0)
  # theme_acl() takes the angle too.
  expect_identical(theme_acl(x_angle = 45)[[3L]]$axis.text.x$angle, 45)
  # Breaks given in the call or the theme win everywhere.
  expect_identical(x_labels(plot_catch(fit, type = "CNA", x_breaks = c(2003, 2011))), c("2003", "2011"))
  acl_theme_set(x_breaks = c(2001, 2009, 2017))
  expect_identical(x_labels(plot_recruitment(fit)), c("2001", "2009", "2017"))
})

test_that("default columns give balanced grids and the call wins", {
  columns <- ALSCL:::.acl_facet_columns
  expect_identical(vapply(c(1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 16, 20, 23), columns, integer(1)),
                   c(1L, 2L, 3L, 2L, 3L, 3L, 4L, 3L, 5L, 4L, 5L, 4L, 5L, 6L))
  for (n in 4:40) {
    cols <- columns(n)
    rows <- ceiling(n / cols)
    expect_lte(cols, 6L)
    # No last row with a single panel under a fuller row.
    if (rows > 1L) expect_false(n %% cols == 1L, info = n)
  }
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- layout_fixture()
  expect_identical(plot_SSB(fit, type = "SBL")$facet$params$ncol, 6L)
  expect_identical(plot_SSB(fit, type = "SBL", facet_ncol = 3)$facet$params$ncol, 3)
  own <- ggplot2::ggplot(data.frame(x = 1:6, y = 1, g = letters[1:6]), ggplot2::aes(x, y)) +
    ggplot2::facet_wrap(~g, nrow = 3)
  expect_null(ALSCL:::.acl_default_columns(own)$facet$params$ncol)
  expect_identical(ALSCL:::.acl_facet_dims(own)[["cols"]], 2L)
})

test_that("dense facets draw thinner lines and reference lines are thin and under the data", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- layout_fixture()
  width <- function(p) p$layers[[1L]]$aes_params$linewidth
  expect_identical(as.numeric(width(plot_SSB(fit))), 1)
  expect_equal(width(plot_SSB(fit, type = "SBL")), 0.5)
  expect_equal(width(plot_catch(fit, type = "CNA", facet_ncol = 3)), 0.5)
  few <- layout_fixture(ages = 8L)
  expect_equal(width(plot_catch(few, type = "CNA")), 2 / 3)
  # A width in the call or in the theme is kept.
  expect_identical(width(plot_SSB(fit, type = "SBL", line_size = 1.5)), 1.5)
  acl_theme_set(line_size = 2)
  expect_identical(width(plot_SSB(fit, type = "SBL")), 2)
  options(acl.theme = NULL)
  expect_null(attributes(width(plot_SSB(fit, type = "SBL"))))
  # Reference lines.
  observations <- matrix(exp(seq(1, 3, length.out = 60)), 3, 20)
  survey <- list(model_type = "ACL", year = 2000:2019, len_mid = c(10, 20, 30),
                 len_label = c("10", "20", "30"), observations = observations,
                 report = list(Elog_index = log(observations) + 0.1, resid_index = matrix(0.1, 3, 20)))
  p <- plot_residuals(survey)
  expect_identical(class(p$layers[[1L]]$geom)[1L], "GeomHline")
  expect_identical(p$layers[[1L]]$aes_params$linewidth, 0.4)
})

test_that("titles are black by default and can be removed or replaced in every plot", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  for (style in c("standard", "classic")) {
    acl_theme_set(style = style)
    expect_identical(acl_theme("title_color"), "black")
    expect_true(acl_theme("show_title"))
  }
  options(acl.theme = NULL)
  fixture <- fit_fixture("ALSCL")
  m <- fixture$result
  d <- fixture$input$data.CatL
  retro_data <- expand.grid(Year = 2000:2002, RetrospectiveYear = c("2004", "2003"), Variable = "SSB")
  retro_data$Value <- seq_len(nrow(retro_data))
  retro <- list(results = retro_data, last_points = retro_data[retro_data$Year == 2002, ],
                rho_text = data.frame(Variable = "SSB", Rho = .01), model_type = "acl")
  title_of <- function(p) if (inherits(p, "patchwork")) p$patches$annotation$title else p$labels$title
  calls <- list(single = function(...) plot_SSB(m, ...), faceted = function(...) plot_SSB(m, type = "SBL", ...),
                comparison = function(...) plot_compare_residuals(m, m, d, ...),
                retro = function(...) plot_retro(retro, ...))
  for (name in names(calls)) {
    expect_true(is.character(title_of(calls[[name]]())) && nzchar(title_of(calls[[name]]())), info = name)
    for (none in list(FALSE, NA, "")) expect_null(title_of(calls[[name]](title = none)), info = name)
    expect_identical(title_of(calls[[name]](title = "My own title, verbatim")), "My own title, verbatim")
  }
  # Without a title the plot leaves no room for one.
  plain <- plot_SSB(m, title = FALSE)
  grob <- ggplot2::ggplotGrob(plain)
  expect_false("title" %in% grob$layout$name[!vapply(grob$grobs, inherits, logical(1), "zeroGrob")])
  expect_error(plot_SSB(m, title = 3), "title must be NULL, FALSE, NA or a character string")
  # show_title = FALSE removes the default titles of every plot and keeps
  # titles given in a call.
  acl_theme_set(show_title = FALSE)
  for (name in names(calls)) {
    expect_null(title_of(calls[[name]]()), info = name)
    expect_identical(title_of(calls[[name]](title = "Kept")), "Kept")
  }
  for (p in check_fit(m)$plots) expect_null(p$labels$title)
  acl_theme_set(show_title = TRUE)
  # A titles key set to "" or NA removes the title of that plot only.
  acl_theme_set(titles = list(SSB = "", SBL = NA))
  expect_null(title_of(plot_SSB(m)))
  expect_null(title_of(plot_SSB(m, type = "SBL")))
  expect_true(nzchar(title_of(plot_biomass(m))))
  expect_error(acl_theme_set(show_title = "no"), "show_title must be TRUE or FALSE")
})

test_that("acl_figure_size() follows the layout and acl_save_plot() saves at 300 dpi", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- layout_fixture()
  single <- acl_figure_size(plot_recruitment(fit))
  expect_named(single, c("width", "height"))
  expect_equal(single[["width"]], 8)
  expect_true(single[["height"]] > 3.8 && single[["height"]] < 5.2)
  # More rows of panels need more height; the width stays.
  # 3, 6, 12 and 16 panels: one to four rows.
  heights <- vapply(c(3L, 6L, 12L, 16L), function(n)
    acl_figure_size(plot_catch(layout_fixture(ages = n), type = "CNA"))[["height"]], numeric(1))
  expect_true(all(diff(heights) > 0))
  for (n in c(4L, 16L)) {
    size <- acl_figure_size(plot_catch(layout_fixture(ages = n), type = "CNA"))
    expect_equal(size[["width"]], 10)
    rows <- ceiling(n / ALSCL:::.acl_facet_columns(n))
    expect_true(size[["height"]] / rows > 1.2 && size[["height"]] / rows < 3, info = n)
  }
  # A fixed width gives the matching height; sizes stay between 3 and 14 inches.
  narrow <- acl_figure_size(plot_catch(fit, type = "CNA"), width = 5)
  expect_equal(narrow[["width"]], 5)
  huge <- acl_figure_size(plot_catch(layout_fixture(ages = 60L), type = "CNA"), width = 40)
  expect_true(all(huge >= 3 & huge <= 14))
  # Patchwork figures and square plots.
  observations <- matrix(exp(seq(1, 3, length.out = 60)), 3, 20)
  survey <- list(model_type = "ACL", year = 2000:2019, len_mid = c(10, 20, 30), len_label = c("10", "20", "30"),
                 observations = observations, report = list(Elog_index = log(observations) + 0.1))
  ridges <- acl_figure_size(plot_ridges(survey))
  expect_equal(ridges[["width"]], 10)
  expect_true(ridges[["height"]] >= 3 && ridges[["height"]] <= 14)
  square <- acl_figure_size(plot_SSB_Rec(list(year = 2000:2019, age = 1:5, growth_step = 1,
                                             report = list(SSB = 1:20, Rec = 21:40))))
  expect_lt(abs(square[["width"]] - square[["height"]]), 1.2)
  expect_error(acl_figure_size(1), "ggplot or patchwork")
  expect_error(acl_figure_size(plot_recruitment(fit), width = -1), "positive number")
  # Saving: the recommended size at 300 dpi, or the size and resolution given.
  p <- plot_recruitment(fit)
  file <- tempfile(fileext = ".png")
  expect_identical(acl_save_plot(p, file), file)
  expect_true(file.exists(file))
  expect_equal(png_size(file), round(300 * single), tolerance = 1)
  expect_identical(formals(acl_save_plot)$dpi, 300)
  acl_save_plot(p, file, width = 4, height = 3, dpi = 100)
  expect_equal(png_size(file), c(width = 400, height = 300))
  acl_save_plot(p, file, width = 6, dpi = 50)
  expect_equal(png_size(file)[["width"]], 300)
  expect_equal(png_size(file)[["height"]], round(50 * acl_figure_size(p, width = 6)[["height"]]), tolerance = 1)
  unlink(file)
  expect_error(acl_save_plot(p, file, dpi = 0), "dpi must be")
})
