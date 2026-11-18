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
  # The first and the last year always carry a label; a multiple of the step
  # that would touch the last label at the saved width (2018 next to 2019)
  # is left out.
  for (case in list(list(2008:2019, as.character(2008:2019)),
                    list(2000:2019, as.character(c(seq(2000, 2016, 2), 2019))),
                    list(1971:2019, as.character(c(1971, seq(1975, 2015, 5), 2019))),
                    list(1930:2019, as.character(c(seq(1930, 2010, 10), 2019))))) {
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
  expect_identical(x_labels(p), c("2000", "2005", "2010", "2015", "2019"))
  expect_identical(p$theme$axis.text.x$angle, 45)
  expect_identical(c(p$theme$axis.text.x$hjust, p$theme$axis.text.x$vjust), c(1, 1))
  # Two columns: every second year, horizontal; 2018 would touch 2019 even
  # when slanted and is left out.
  two <- plot_catch(fit, type = "CNA", facet_ncol = 2)
  expect_identical(x_labels(two), as.character(c(seq(2000, 2016, 2), 2019)))
  expect_null(two$theme$axis.text.x$angle)
  # The theme key x_angle fixes the angle: 0 keeps the labels horizontal and
  # thins them, a number slants them.
  acl_theme_set(x_angle = 0)
  flat <- plot_catch(fit, type = "CNA")
  expect_null(flat$theme$axis.text.x$angle)
  expect_identical(x_labels(flat), c("2000", "2010", "2019"))
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

test_that("the first and the last year carry a label and a regular label next to them gives way", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  positions <- ALSCL:::.acl_time_positions
  # A step of five years: the multiple of the step next to the first or the
  # last label is left out when it is closer than the gap, never the first
  # or the last label itself.
  expect_identical(positions(c(2000, 2019), 5, gap = 3), c(2000, 2005, 2010, 2015, 2019))
  expect_identical(positions(c(2000, 2016), 5, gap = 3), c(2000, 2005, 2010, 2016))
  expect_identical(positions(c(2003, 2019), 5, gap = 3), c(2003, 2010, 2015, 2019))
  expect_identical(positions(c(2003, 2019), 5, gap = 1.5), c(2003, 2005, 2010, 2015, 2019))
  # Without a width the gap is half a step.
  expect_identical(positions(c(2000, 2016), 5), c(2000, 2005, 2010, 2016))
  expect_identical(positions(c(2003, 2019), 5), c(2003, 2010, 2015, 2019))
  expect_identical(positions(c(2001, 2019), 5), c(2001, 2005, 2010, 2015, 2019))
  # Several time steps per year: the start of the first and of the last year
  # that hold a time step within the range.
  expect_identical(positions(c(2000, 2004.75), 1), as.numeric(2000:2004))
  expect_identical(positions(c(2000.25, 2004.75), 1), as.numeric(2001:2004))
  # One year.
  expect_identical(positions(c(2000, 2000), 1), 2000)
  expect_identical(positions(c(2000, 2000.75), 1), 2000)
  expect_identical(positions(c(2000.25, 2000.75), 1), 2000.25)
  # Labels at the chosen angle do not touch: neighbouring labels are at least
  # the gap of .acl_time_axis() apart, except a first and a last label that
  # are the only labels.
  for (start in c(1990, 1993, 2000, 2003)) for (n in c(2, 5, 9, 13, 17, 20, 26, 31, 45, 61, 90)) for (cols in 1:6) {
    range <- c(start, start + n - 1)
    axis <- ALSCL:::.acl_time_axis(range, 1, cols = cols)
    at <- positions(range, axis$step, axis$gap)
    info <- paste(range[1L], range[2L], cols)
    expect_true(all(range %in% at), info = info)
    if (length(at) > 2L) expect_true(all(diff(at) >= axis$gap - 1e-8), info = info)
  }

  minor <- function(p, panel = 1L) round(layout_build(p)$layout$panel_params[[panel]]$x$get_breaks_minor(), 8)
  angle <- function(p) p$theme$axis.text.x$angle
  # Annual series of 20 and 17 years and a series that does not start on a
  # multiple of the step: one panel, and facets in three and four columns.
  cases <- list(
    list(years = 2000:2019, single = c(seq(2000, 2016, 2), 2019), three = c(2000, 2005, 2010, 2015, 2019),
         four = c(2000, 2005, 2010, 2015, 2019)),
    list(years = 2000:2016, single = seq(2000, 2016, 2), three = c(2000, 2005, 2010, 2016),
         four = c(2000, 2005, 2010, 2016)),
    list(years = 2003:2019, single = c(2003, seq(2004, 2018, 2), 2019), three = c(2003, 2005, 2010, 2015, 2019),
         four = c(2003, 2010, 2015, 2019)))
  for (case in cases) {
    fit <- layout_fixture(case$years)
    single <- plot_SSB(fit)
    expect_identical(x_labels(single), as.character(case$single))
    expect_null(angle(single))
    # Unlabelled years keep their minor tick marks.
    expect_true(all(setdiff(case$years, case$single) %in% minor(single)))
    three <- plot_catch(fit, type = "CNA", facet_ncol = 3)
    four <- plot_catch(fit, type = "CNA", facet_ncol = 4)
    for (panel in c(1L, 7L, 15L)) {
      expect_identical(x_labels(three, panel), as.character(case$three))
      expect_identical(x_labels(four, panel), as.character(case$four))
    }
  }
  # The added labels take part in the decision to slant: in three columns,
  # 2005 is kept next to 2003 by slanting the labels; in four columns it
  # would touch 2003 even when slanted, so it is left out and the labels
  # stay horizontal. 2015 is kept next to 2019 by slanting in four columns.
  expect_identical(angle(plot_catch(layout_fixture(2003:2019), type = "CNA", facet_ncol = 3)), 45)
  expect_null(angle(plot_catch(layout_fixture(2003:2019), type = "CNA", facet_ncol = 4)))
  expect_null(angle(plot_catch(layout_fixture(2000:2019), type = "CNA", facet_ncol = 3)))
  expect_identical(angle(plot_catch(layout_fixture(2000:2019), type = "CNA", facet_ncol = 4)), 45)
  # Quarterly series of 5 and 20 years: labels at the start of the years,
  # the first and the last year among them, in one panel and in facets.
  for (n in c(5L, 20L)) {
    quarterly <- layout_fixture(2000 + (seq_len(4L * n) - 1L) / 4)
    expected <- if (n == 5L) 2000:2004 else c(seq(2000, 2016, 2), 2019)
    expect_identical(x_labels(plot_recruitment(quarterly)), as.character(expected))
    faceted <- plot_catch(quarterly, type = "CNA")
    labels <- as.numeric(x_labels(faceted))
    expect_identical(range(labels), c(2000, 1999 + n))
    expect_true(all(labels == round(labels)))
    # Minor tick marks at the quarters where they leave room, otherwise at
    # the unlabelled years.
    expected_minor <- if (n == 5L) c(2000.25, 2000.5, 2000.75) else setdiff(2000:2019, labels)
    expect_true(all(expected_minor %in% minor(faceted)))
  }
  expect_identical(x_labels(plot_catch(layout_fixture(2000 + (0:19) / 4), type = "CNA")),
                   c("2000", "2002", "2004"))
  # A single year, annual or quarterly.
  expect_identical(x_labels(plot_recruitment(list(year = 2000, report = list(Rec = 100)))), "2000")
  expect_identical(x_labels(plot_recruitment(list(year = 2000 + (0:3) / 4, growth_step = 0.25,
                                                  report = list(Rec = c(1, 3, 2, 4))))), "2000")
  # Facets with free x scales: each panel labels the first and the last year
  # of its own data.
  d <- rbind(data.frame(year = 2000:2019, y = 1, g = "a"), data.frame(year = 2005:2019, y = 1, g = "b"),
             data.frame(year = 1990:2012, y = 1, g = "c"))
  free <- ALSCL:::.acl_tidy_axes(ggplot2::ggplot(d, ggplot2::aes(year, y)) + ggplot2::geom_line() +
    ggplot2::facet_wrap(~g, scales = "free") + ALSCL:::.acl_scale_x(values = d$year, time = TRUE))
  for (panel in 1:3) {
    labels <- as.numeric(x_labels(free, panel))
    shown <- range(d$year[d$g == letters[panel]])
    expect_identical(range(labels), as.numeric(shown), info = panel)
  }
  # Room for the labels at the ends of the panels: a horizontal last label
  # reaches half a label beyond the last panel, so the right margin holds
  # it; without y axes between the panels, the last label of one column and
  # the first label of the next are spaced like two neighbouring labels.
  fit <- layout_fixture()
  margin <- function(p) as.numeric(ggplot2::calc_element("plot.margin", ggplot2::complete_theme(p$theme)))
  spacing <- function(p) as.numeric(ggplot2::calc_element("panel.spacing.x", ggplot2::complete_theme(p$theme)))
  expect_equal(margin(plot_SSB(fit)), c(5.5, 13, 5.5, 5.5))
  expect_equal(margin(plot_catch(fit, type = "CNA")), rep(5.5, 4L))
  expect_equal(spacing(plot_catch(fit, type = "CNA")), 5.5)
  expect_equal(spacing(plot_catch(fit, type = "CNA", facet_ncol = 3)), 12.5)
  expect_equal(spacing(plot_catch(fit, type = "CNA", facet_scales = "fixed")), 1.2 * 10 / sin(pi / 4))
  expect_equal(spacing(plot_catch(fit, type = "CNA", facet_ncol = 3, facet_scales = "fixed")), 30)
  # A multi-panel comparison figure labels the first and the last year in
  # each panel.
  compared <- plot_compare_ts(fit, fit, quantities = c("SSB", "R"))
  for (panel in 1:2) expect_identical(range(as.numeric(x_labels(compared, panel))), c(2000, 2019))
  # Breaks given in the call or in the theme are used as given.
  expect_identical(x_labels(plot_SSB(fit, x_breaks = c(2003, 2011))), c("2003", "2011"))
  acl_theme_set(x_breaks = c(2001, 2009))
  expect_identical(x_labels(plot_SSB(fit)), c("2001", "2009"))
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
  for (style in c("default", "classic")) {
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
