# The "standard" style is the default of 2.5.0 (colors by quantity, bars for
# total recruitment and catch, y axes from zero, bold left-aligned titles,
# no grid lines), and acl_theme_set(style = "classic") restores the look of
# 2.4.5. grid = "y" adds horizontal major grid lines.

style_fit <- local({
  fits <- list()
  function(model = c("ACL", "ALSCL")) {
    model <- match.arg(model)
    if (is.null(fits[[model]])) {
      fit <- if (model == "ACL") run_acl(YTF_example, silent = TRUE) else
        run_alscl(YTF_example, silent = TRUE)
      fit$obj <- NULL
      fits[[model]] <<- fit
    }
    fits[[model]]
  }
})

# Start from the package defaults and restore the caller's settings afterwards.
local_default_theme <- function(env = parent.frame()) {
  old <- options(acl.theme = NULL)
  withr::defer(options(old), envir = env)
}

# Draw without leaving an Rplots.pdf file in the test directory.
style_build <- function(plot) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  ggplot2::ggplot_build(plot)
}

# The look of a built plot: layer geoms and colours, grid, title, strips,
# legend, scales, panel border and y ranges of all panels.
style_look <- function(p) {
  b <- style_build(p)
  th <- ggplot2::complete_theme(b$plot$theme)
  el <- function(name) ggplot2::calc_element(name, th)
  grid <- vapply(c("panel.grid.major.x", "panel.grid.major.y", "panel.grid.minor.x", "panel.grid.minor.y"),
    function(e) { x <- el(e); if (is.null(x) || inherits(x, "element_blank")) "blank" else as.character(x$colour) }, "")
  title <- el("plot.title")
  strip_bg <- el("strip.background.x")
  strip_text <- el("strip.text.x.top")
  layers <- lapply(seq_along(p$layers), function(i) {
    d <- b$data[[i]]
    list(geom = class(p$layers[[i]]$geom)[1L],
         colour = if (!is.null(d$colour)) sort(unique(as.character(d$colour))),
         fill = if (!is.null(d$fill)) sort(unique(as.character(d$fill))),
         alpha = if (!is.null(d$alpha)) sort(unique(d$alpha)))
  })
  border <- el("panel.border")
  y <- b$plot$scales$get_scales("y")
  list(layers = layers, grid = grid,
       title = list(hjust = title$hjust, face = title$face %||% "plain", colour = title$colour),
       strip = list(background = if (inherits(strip_bg, "element_blank")) "blank" else as.character(strip_bg$fill),
                    face = strip_text$face %||% "plain", hjust = strip_text$hjust),
       legend = as.character(th$legend.position %||% "right"),
       scales = sort(vapply(b$plot$scales$scales, function(s) s$aesthetics[1L], "")),
       y_expand = if (is.null(y) || inherits(y$expand, "waiver")) "default" else y$expand,
       border = if (inherits(border, "element_blank")) "blank" else as.character(border$colour),
       axis_text = as.character(el("axis.text.x.bottom")$colour),
       y_ranges = lapply(b$layout$panel_params, function(x) x$y.range))
}

layer <- function(geom, colour = NULL, fill = NULL, alpha = logical(0))
  list(geom = geom, colour = colour, fill = fill, alpha = alpha)

# A small retrospective result: four fits whose terminal years are 2004 to 2001.
style_retro_fixture <- function(times = 2000:2004, peels = 3L) {
  Y <- length(times)
  d <- expand.grid(step = seq_len(Y), Peel = 0:peels, Variable = c("B", "Rec", "SSB", "N"),
                   stringsAsFactors = FALSE)
  d <- d[d$step <= Y - d$Peel, ]
  d$Year <- times[d$step]
  terminal <- times[Y - d$Peel]
  d$Value <- 100 + d$step + d$Peel
  d$NumericalOK <- TRUE
  d$RetrospectiveYear <- factor(terminal, levels = rev(times[seq.int(Y - peels, Y)]))
  d$step <- NULL
  diagnostics <- data.frame(Peel = 0:peels, RetrospectiveYear = times[Y - 0:peels],
                            error = "", numerical_ok = TRUE)
  list(results = d, last_points = d[d$Year == terminal, ],
       rho_text = data.frame(Variable = c("B", "Rec", "SSB", "N"), Rho = .01, Year = times[2L],
                             Valid = TRUE, ValidPeels = peels, RequestedPeels = peels),
       model_type = "acl", fit_diagnostics = diagnostics)
}

standard <- list(stock = "#047c6c", F = "#ed5f26", recruitment = "#28b3e8", catch = "#002b5f",
             primary = "#002b5f", accent = "#eb5c24", smooth = "#00b29d")
standard_palette <- c("#002b5f", "#eb5c24", "#00b29d", "#fda500", "#6eb5d2", "#6eb200", "#28b3e8", "#047c6c")
style_keys <- c("style", "palette", "grid", "title_face", "title_hjust", "title_color",
                "stock_color", "F_color", "recruitment_color", "catch_color", "bars", "y_zero",
                "se_alpha", "compare_se_alpha", "strip", "legend_position", "axis_color",
                "line_color", "se_color", "point_color", "observed_color", "smooth_color",
                "hline_color", "low_col", "high_col", "compare_colors")
standard_values <- list(style = "standard", palette = "standard", grid = "none", title_face = "bold", title_hjust = 0,
  title_color = "black", stock_color = standard$stock, F_color = standard$F,
  recruitment_color = standard$recruitment, catch_color = standard$catch, bars = TRUE, y_zero = TRUE,
  se_alpha = 0.3, compare_se_alpha = 0.25, strip = "plain", legend_position = "bottom",
  axis_color = "black", line_color = standard$primary, se_color = standard$primary,
  point_color = standard$primary, observed_color = standard$accent, smooth_color = standard$smooth,
  hline_color = "grey55", low_col = "#ffffff", high_col = standard$primary,
  compare_colors = c(standard$primary, standard$accent))
npg <- ggsci::pal_npg("nrc")(10)
classic_values <- list(style = "classic", palette = "npg", grid = "none", title_face = "plain",
  title_hjust = 0.5, title_color = "black", stock_color = NULL, F_color = NULL,
  recruitment_color = NULL, catch_color = NULL, bars = FALSE, y_zero = FALSE, se_alpha = 0.2,
  compare_se_alpha = 0.15, strip = "box", legend_position = NULL, axis_color = NULL,
  line_color = npg[4], se_color = npg[4], point_color = npg[4], observed_color = npg[1],
  smooth_color = npg[3], hline_color = "grey55", low_col = "#F7F9FC", high_col = npg[4],
  compare_colors = npg[c(4, 1)])
theme_values <- function() stats::setNames(lapply(style_keys, acl_theme), style_keys)

test_that("the standard style is the default and each style sets its keys", {
  local_default_theme()
  expect_identical(theme_values(), standard_values)
  acl_theme_set(style = "classic")
  expect_identical(acl_theme("style"), "classic")
  expect_identical(theme_values(), classic_values)
  acl_theme_set(style = "standard")
  expect_identical(theme_values(), standard_values)
  acl_theme_set(style = "classic")
  expect_message(acl_theme_reset(), "reset to defaults")
  expect_identical(theme_values(), standard_values)
  # Settings that a style does not own are kept.
  acl_theme_set(font_family = "serif", title_size = 18, point_size = 3)
  acl_theme_set(style = "classic")
  expect_identical(acl_theme("font_family"), "serif")
  expect_identical(acl_theme("title_size"), 18)
  expect_identical(acl_theme("point_size"), 3)
  # Line widths belong to the style: 1.5 and 1.2 under classic, 1 and 0.9
  # under standard.
  expect_identical(c(acl_theme("line_size"), acl_theme("compare_line_size")), c(1.5, 1.2))
  acl_theme_set(style = "standard")
  expect_identical(c(acl_theme("line_size"), acl_theme("compare_line_size")), c(1, 0.9))
})

test_that("single keys change only themselves and win over a style in the same call", {
  local_default_theme()
  before <- acl_theme()
  acl_theme_set(grid = "y")
  after <- acl_theme()
  expect_identical(after$grid, "y")
  after$grid <- before$grid
  expect_identical(after, before)
  acl_theme_set(style = "standard", palette = "npg", title_hjust = 0.5)
  expect_identical(acl_theme("style"), "standard")
  expect_identical(acl_theme("palette"), "npg")
  expect_identical(acl_theme("line_color"), npg[4])
  expect_identical(acl_theme("grid"), "none")
  expect_identical(acl_theme("title_hjust"), 0.5)
  # The quantity colours belong to the style, not to the palette.
  expect_identical(acl_theme("stock_color"), standard$stock)
  acl_theme_set(style = "classic", grid = "y", bars = TRUE, stock_color = "darkgreen")
  expect_identical(acl_theme("grid"), "y")
  expect_true(acl_theme("bars"))
  expect_identical(acl_theme("stock_color"), "darkgreen")
  expect_identical(acl_theme("title_face"), "plain")
  # An explicit NULL clears a quantity colour or the legend position.
  acl_theme_set(style = "standard", stock_color = NULL, legend_position = NULL)
  expect_null(acl_theme("stock_color"))
  expect_null(acl_theme("legend_position"))
  expect_identical(acl_theme("F_color"), standard$F)
  # Saved settings restore every key, including the cleared ones.
  acl_theme_set(style = "classic")
  saved <- acl_theme()
  acl_theme_set(style = "standard")
  do.call(acl_theme_set, saved)
  expect_identical(acl_theme(), saved)
})

test_that("invalid style settings are errors that name the accepted values", {
  local_default_theme()
  before <- acl_theme()
  expect_error(acl_theme_set(style = "modern"), "style must be one of \"standard\", \"classic\"")
  expect_error(acl_theme_set(grid = "x"), "grid must be one of \"none\", \"y\"")
  expect_error(acl_theme_set(title_face = "heavy"), "title_face must be one of")
  expect_error(acl_theme_set(title_color = "notacolor"), "title_color must be one color")
  expect_error(acl_theme_set(stock_color = 1), "stock_color must be one color")
  expect_error(acl_theme_set(F_color = c("red", "blue")), "F_color must be one color")
  expect_error(acl_theme_set(axis_color = "zz"), "axis_color must be one color")
  expect_error(acl_theme_set(bars = NA), "bars must be TRUE or FALSE")
  expect_error(acl_theme_set(y_zero = "yes"), "y_zero must be TRUE or FALSE")
  expect_error(acl_theme_set(strip = "grey"), "strip must be one of \"plain\", \"box\"")
  expect_error(acl_theme_set(legend_position = "middle"), "legend_position must be one of")
  expect_error(acl_theme_set(palette = "typo"), "arg")
  # A rejected call stores nothing, not even its valid arguments.
  expect_error(acl_theme_set(style = "classic", grid = "x"), "grid")
  expect_identical(acl_theme(), before)
  expect_silent(acl_theme_set(title_color = "quantity", palette = "standard"))
})

test_that("the classic style gives the base theme layers of 2.4.5", {
  local_default_theme()
  acl_theme_set(style = "classic")
  expected <- list(ggplot2::theme_bw(), ggplot2::theme(
    panel.grid.major = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    text = ggplot2::element_text(family = "sans"),
    plot.title = ggplot2::element_text(size = 14, hjust = 0.5),
    axis.title = ggplot2::element_text(size = 12),
    axis.text = ggplot2::element_text(size = 10),
    strip.text = ggplot2::element_text(size = 10),
    legend.text = ggplot2::element_text(size = 10),
    legend.title = ggplot2::element_text(size = 10)))
  expect_equal(ALSCL:::.acl_base_theme(), expected)
  expect_equal(theme_acl(), expected)
  expect_equal(ALSCL:::.acl_annotation_theme("bottom"), ggplot2::theme(
    text = ggplot2::element_text(family = "sans"),
    plot.title = ggplot2::element_text(size = 14, hjust = 0.5), legend.position = "bottom"))
})

test_that("theme_acl() gives the panel look of the current style to any ggplot", {
  local_default_theme()
  d <- data.frame(x = 1:5, y = c(2, 4, 3, 5, 6), g = rep(c("a", "b"), c(2, 3)))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_line() +
    ggplot2::facet_wrap(~g) + ggplot2::labs(title = "Own plot") + theme_acl()
  look <- style_look(p)
  expect_identical(unname(look$grid), rep("blank", 4))
  expect_identical(look$title, list(hjust = 0, face = "bold", colour = "black"))
  expect_identical(look$strip, list(background = "blank", face = "bold", hjust = 0))
  expect_identical(look$legend, "bottom")
  expect_identical(look$border, "black")
  expect_identical(look$axis_text, "black")
  # The title is black by default and takes the colour of a quantity family
  # with title_color = "quantity".
  expect_identical(style_look(p + theme_acl(quantity = "stock"))$title$colour, "black")
  acl_theme_set(title_color = "quantity")
  expect_identical(style_look(p + theme_acl(quantity = "stock"))$title$colour, standard$stock)
  acl_theme_set(title_color = "black")
  expect_error(theme_acl(quantity = "SSB"), "quantity must be one of")
  # Typography arguments and other base themes pass through.
  layers <- theme_acl(title_size = 20, font_family = "serif", base_theme = "minimal")
  expect_equal(layers[[1L]], ggplot2::theme_minimal())
  expect_equal(layers[[2L]]$plot.title$size, 20)
  expect_identical(layers[[2L]]$text$family, "serif")
  # The grid, title and strip rules apply on top of another base theme; the
  # panel border and axis colours belong to the default base theme.
  minimal <- style_look(p + theme_acl(base_theme = "classic"))
  expect_identical(unname(minimal$grid), rep("blank", 4))
  expect_identical(minimal$title$face, "bold")
  expect_identical(minimal$border, "blank")
  # It follows later settings: grid = "y" adds thin light grey horizontal
  # major lines, also on top of another base theme.
  acl_theme_set(grid = "y")
  expect_identical(unname(style_look(p + theme_acl())$grid), c("blank", "grey80", "blank", "blank"))
  expect_identical(unname(style_look(p + theme_acl(base_theme = "classic"))$grid),
                   c("blank", "grey80", "blank", "blank"))
  expect_identical(theme_acl()[[2L]]$panel.grid.major.y$linewidth, 0.4)
  acl_theme_set(style = "classic")
  expect_identical(unname(style_look(p + theme_acl())$grid), rep("blank", 4))
  acl_theme_set(grid = "y")
  expect_identical(unname(style_look(p + theme_acl())$grid), c("blank", "grey80", "blank", "blank"))
})

test_that("acl_palette() gives the colours of a palette and of each role", {
  local_default_theme()
  expect_identical(acl_palette(), standard_palette)
  expect_identical(acl_palette(3), standard_palette[1:3])
  twelve <- acl_palette(12)
  expect_length(twelve, 12L)
  expect_identical(toupper(twelve[c(1L, 12L)]), toupper(standard_palette[c(1L, 8L)]))
  expect_identical(acl_palette(4, palette = "npg"), npg[1:4])
  expect_identical(acl_palette(role = c("stock", "F", "recruitment", "catch", "primary", "accent", "smooth")),
    c(stock = standard$stock, F = standard$F, recruitment = standard$recruitment, catch = standard$catch,
      primary = standard$primary, accent = standard$accent, smooth = standard$smooth))
  expect_identical(acl_palette(role = "reference"), c(reference = "grey55"))
  # Under the classic style the quantities use the primary colour.
  acl_theme_set(style = "classic")
  expect_identical(acl_palette(), npg)
  expect_identical(acl_palette(role = c("stock", "primary", "accent")),
                   c(stock = npg[4], primary = npg[4], accent = npg[1]))
  # A palette name gives the defaults of that palette, whatever the settings.
  expect_identical(acl_palette(role = c("F", "accent"), palette = "standard"), c(F = standard$F, accent = standard$accent))
  acl_theme_set(line_color = "purple")
  expect_identical(acl_palette(role = "primary"), c(primary = "purple"))
  expect_error(acl_palette(role = "SSB"), "role must name color roles")
  expect_error(acl_palette(0), "positive whole number")
  expect_error(acl_palette(palette = "rainbow"), "arg")
})

test_that("the stock, recruitment, catch and F plots of an ACL fit have the forms and colours of the standard style", {
  skip_on_cran()
  local_default_theme()
  fit <- style_fit("ACL")
  standard_panel <- function(look, colour) {
    expect_identical(unname(look$grid), rep("blank", 4))
    # The title is black by default.
    expect_identical(look$title, list(hjust = 0, face = "bold", colour = "black"))
    expect_identical(look$strip, list(background = "blank", face = "bold", hjust = 0))
    expect_identical(look$border, "black")
    expect_equal(look$y_expand, c(0, 0, 0.1, 0))
    for (range in look$y_ranges) expect_identical(range[1L], 0)
  }
  # Stock size: a line and a band of the same colour.
  for (p in list(plot_SSB(fit, se = TRUE), plot_biomass(fit, se = TRUE), plot_abundance(fit, se = TRUE))) {
    look <- style_look(p)
    expect_identical(look$layers[1:2], list(layer("GeomLine", standard$stock), layer("GeomRibbon", character(0), standard$stock, 0.3)))
    standard_panel(look, standard$stock)
  }
  standard_panel(style_look(plot_abundance(fit, type = "NA")), standard$stock)
  # Recruitment: bars 0.8 of the time step wide with thin dark error bars
  # over a wider white bar.
  p <- plot_recruitment(fit, se = TRUE)
  look <- style_look(p)
  expect_identical(look$layers[1:3], list(layer("GeomCol", character(0), standard$recruitment, logical(0)),
                                          layer("GeomErrorbar", "white", NULL, 1),
                                          layer("GeomErrorbar", "grey20", NULL, 1)))
  standard_panel(look, standard$recruitment)
  bars <- style_build(p)$data[[1L]]
  expect_equal(bars$xmax - bars$xmin, rep(0.8, nrow(bars)))
  expect_identical(p$layers[[3L]]$aes_params$linewidth, 0.4)
  expect_gt(p$layers[[2L]]$aes_params$linewidth, 0.4)
  expect_identical(style_look(plot_recruitment(fit))$layers[[1L]]$geom, "GeomCol")
  # The geom argument and an explicit se_type choose per call.
  line <- style_look(plot_recruitment(fit, se = TRUE, geom = "line"))
  expect_identical(line$layers[1:2], list(layer("GeomLine", standard$recruitment),
                                          layer("GeomRibbon", character(0), standard$recruitment, 0.3)))
  expect_identical(style_look(plot_recruitment(fit, se = TRUE, se_type = "ribbon"))$layers[[2L]]$geom, "GeomRibbon")
  expect_identical(style_look(plot_recruitment(fit, se = TRUE, se_color = "red"))$layers[[3L]]$colour, "red")
  expect_error(plot_recruitment(fit, geom = "area"), "geom must be one of \"bar\", \"line\"")
  # Catch: bars for the total, lines at age in the catch colour.
  look <- style_look(plot_catch(fit, se = TRUE))
  expect_identical(look$layers[[1L]], layer("GeomCol", character(0), standard$catch, logical(0)))
  expect_identical(look$layers[[2L]]$geom, "GeomErrorbar")
  standard_panel(look, standard$catch)
  look <- style_look(plot_catch(fit, type = "CNA"))
  expect_identical(look$layers[[1L]], layer("GeomLine", standard$catch))
  standard_panel(look, standard$catch)
  expect_identical(style_look(plot_catch(fit, geom = "line"))$layers[[1L]]$geom, "GeomLine")
  # Fishing pressure, with free y scales in every panel.
  for (p in list(plot_fishing_mortality(fit, se = TRUE), plot_fishing_mortality(fit, type = "age"))) {
    look <- style_look(p)
    expect_identical(look$layers[[1L]], layer("GeomLine", standard$F))
    standard_panel(look, standard$F)
  }
  expect_identical(style_look(plot_fishing_mortality(fit, se = TRUE))$layers[[2L]],
                   layer("GeomRibbon", character(0), standard$F, 0.3))
  # Deviations take the colour of their quantity; their axis is not forced to zero.
  expect_identical(style_look(plot_deviance(fit))$layers[[1L]], layer("GeomLine", standard$recruitment))
  dev_F <- style_look(plot_deviance(fit, type = "F", se = TRUE))
  expect_identical(dev_F$title$colour, "black")
  expect_identical(dev_F$layers[[3L]]$colour, standard$F)
  expect_true(all(vapply(dev_F$y_ranges, function(r) r[1L] < 0, logical(1))))
  # A per-call colour wins, and the band follows it.
  look <- style_look(plot_SSB(fit, se = TRUE, line_color = "purple"))
  expect_identical(look$layers[[2L]]$fill, "purple")
  expect_identical(look$title$colour, "black")
  # With title_color = "quantity" the title takes the colour of the quantity,
  # darkened where needed to read on white.
  acl_theme_set(title_color = "quantity")
  for (case in list(list(plot_SSB(fit), standard$stock), list(plot_recruitment(fit), standard$recruitment),
                    list(plot_catch(fit), standard$catch), list(plot_deviance(fit, type = "F"), standard$F)))
    expect_identical(style_look(case[[1L]])$title$colour, ALSCL:::.acl_readable_color(case[[2L]]))
  acl_theme_set(title_color = "black")
  # Neutral plots use the primary colour and a black title.
  look <- style_look(plot_SSB_Rec(fit))
  expect_identical(look$layers[[1L]]$colour, standard$primary)
  expect_identical(look$title$colour, "black")
  look <- style_look(plot_CatL(fit))
  expect_identical(look$layers[[1L]]$colour, standard$accent)
  expect_identical(look$layers[[2L]]$colour, standard$primary)
  look <- style_look(plot_residuals(fit))
  # The zero line is drawn first, under the residuals and their trend.
  expect_identical(look$layers[[1L]]$geom, "GeomHline")
  expect_identical(look$layers[[3L]]$colour, standard$smooth)
  expect_identical(style_look(plot_relative_catch(fit))$layers[[2L]]$colour, standard$catch)
  # No y scale is added twice.
  for (p in list(plot_SSB(fit), plot_recruitment(fit), plot_catch(fit), plot_fishing_mortality(fit)))
    expect_no_message(style_build(p))
  # Heat maps show no grid lines, even with grid = "y".
  acl_theme_set(grid = "y")
  expect_identical(unname(style_look(plot_SSB(fit))$grid), c("blank", "grey80", "blank", "blank"))
  for (p in list(plot_pla(fit), check_fit(fit)$plots$heatmap))
    expect_identical(unname(style_look(p)$grid), rep("blank", 4))
})

test_that("the stock, catch and F plots of an ALSCL fit and the comparison plots follow the standard style", {
  skip_on_cran()
  local_default_theme()
  acl <- style_fit("ACL")
  alscl <- style_fit("ALSCL")
  zero <- function(look) for (range in look$y_ranges) expect_identical(range[1L], 0)
  look <- style_look(plot_SSB(alscl, type = "SBA", se = TRUE))
  expect_identical(look$layers[[1L]], layer("GeomLine", standard$stock))
  zero(look)
  look <- style_look(plot_catch(alscl, type = "CNL"))
  expect_identical(look$layers[[1L]], layer("GeomLine", standard$catch))
  zero(look)
  look <- style_look(plot_fishing_mortality(alscl))
  expect_identical(look$layers[[1L]], layer("GeomLine", standard$F))
  zero(look)
  look <- style_look(plot_catch(alscl, se = TRUE))
  expect_identical(look$layers[[1L]]$geom, "GeomCol")
  zero(look)
  # Comparisons: the two models in compare_colors, bands with compare_se_alpha.
  look <- style_look(plot_compare_ts(acl, alscl, se = TRUE))
  expect_identical(look$layers[[1L]], layer("GeomLine", c(standard$primary, standard$accent)))
  expect_identical(look$layers[[2L]], layer("GeomRibbon", character(0), c(standard$primary, standard$accent), 0.25))
  expect_identical(look$title, list(hjust = 0, face = "bold", colour = "black"))
  # Five quantities fill three columns; the legend sits in the empty cell.
  expect_identical(look$legend, "inside")
  expect_identical(style_look(plot_compare_ts(acl, alscl, quantities = c("SSB", "R")))$legend, "bottom")
  zero(look)
  look <- style_look(plot_compare_F_ts(acl, alscl))
  expect_identical(look$layers[[1L]]$colour, c(standard$primary, standard$accent))
  zero(look)
  acl_theme_set(grid = "y")
  expect_identical(unname(style_look(plot_compare_F(acl, alscl))$grid), rep("blank", 4))
  acl_theme_set(grid = "none")
  # Without y_zero the axes follow the data.
  acl_theme_set(y_zero = FALSE)
  expect_true(style_look(plot_compare_ts(acl, alscl))$y_ranges[[1L]][1L] > 0)
  expect_true(style_look(plot_SSB(alscl))$y_ranges[[1L]][1L] > 0)
})

test_that("retrospective fits are orange and grey under the standard palette", {
  local_default_theme()
  r <- style_retro_fixture()
  p <- plot_retro(r)
  scale <- style_build(p)$plot$scales$get_scales("colour")
  expect_identical(scale$map(c("2004", "2003", "2002", "2001")),
                   c("#ed5f26", "#252525", "#525252", "#737373"))
  # The full fit is drawn again on top of the peels, with its open point.
  geoms <- vapply(p$layers, function(l) class(l$geom)[1L], "")
  expect_identical(unname(geoms), c("GeomLine", "GeomPoint", "GeomText", "GeomLine", "GeomPoint"))
  expect_true(all(p$layers[[4L]]$data$RetrospectiveYear == "2004"))
  expect_identical(p$layers[[5L]]$aes_params$shape, 21)
  # A failed fit stays dashed.
  r$results$NumericalOK[r$results$Peel == 2L] <- FALSE
  lines <- style_build(plot_retro(r))$data[[1L]]
  expect_identical(unique(lines$linetype[lines$group == 3L]), "dashed")
  # More peels than greys are interpolated, darkest first.
  colors <- ALSCL:::.acl_retro_colors(8L)
  expect_length(colors, 8L)
  expect_identical(colors[1:2], c("#ed5f26", "#252525"))
  expect_identical(toupper(colors[8L]), "#BDBBBB")
  # A palette or explicit colours keep the former behaviour.
  r <- style_retro_fixture()
  npg_scale <- style_build(plot_retro(r, palette = "npg"))$plot$scales$get_scales("colour")
  expect_identical(npg_scale$map(c("2004", "2003")), npg[1:2])
  expect_length(plot_retro(r, palette = "npg")$layers, 3L)
  own <- style_build(plot_retro(r, colors = c("black", "red", "blue", "green")))$plot$scales$get_scales("colour")
  expect_identical(own$map(c("2004", "2001")), c("black", "green"))
  acl_theme_set(palette = "npg")
  expect_identical(style_build(plot_retro(r))$plot$scales$get_scales("colour")$map("2004"), npg[1])
})

test_that("ridgelines use a blue ramp under the standard palette and viridis under classic", {
  local_default_theme()
  expect_identical(ALSCL:::.acl_ridges_palette(NULL, 3L)$palette(3L),
                   grDevices::colorRampPalette(c("#d6ecf5", "#002b5f"))(3L))
  expect_identical(ALSCL:::.acl_ridges_palette("standard", 2L)$palette(2L), toupper(c("#d6ecf5", "#002b5f")))
  expect_s3_class(ALSCL:::.acl_ridges_palette("viridis", 3L), "ScaleDiscrete")
  acl_theme_set(style = "classic")
  viridis <- ALSCL:::.acl_ridges_palette(NULL, 3L)
  expect_identical(viridis$palette(3L), ggplot2::scale_fill_viridis_d()$palette(3L))
})

test_that("a recruitment series of one time step is drawn as one bar", {
  local_default_theme()
  fit <- list(report = list(Rec = 5), year = 2000)
  p <- plot_recruitment(fit)
  built <- style_build(p)
  expect_identical(class(p$layers[[1L]]$geom)[1L], "GeomCol")
  expect_identical(built$data[[1L]]$y, 5)
  expect_equal(built$data[[1L]]$xmax - built$data[[1L]]$xmin, 0.8)
  # Quarterly series get bars 0.8 of a quarter wide.
  quarterly <- list(report = list(Rec = c(4, 6, 5, 7)), year = 2000 + (0:3) / 4)
  bars <- style_build(plot_recruitment(quarterly))$data[[1L]]
  expect_equal(bars$xmax - bars$xmin, rep(0.2, 4))
})

# The look elements of 2.4.5: palette, geoms, grid, title, strips, legend
# and panel border. The rules for readable text (tick labels, room for the
# rho text of plot_retro()) apply to both styles and are tested in
# test-readable-text-250.R.
test_that("the classic style reproduces the look of 2.4.5", {
  skip_on_cran()
  local_default_theme()
  acl_theme_set(style = "classic")
  acl <- style_fit("ACL")
  alscl <- style_fit("ALSCL")
  primary <- "#3C5488FF"; accent <- "#E64B35FF"
  common <- list(grid = c(panel.grid.major.x = "blank", panel.grid.major.y = "blank",
                          panel.grid.minor.x = "blank", panel.grid.minor.y = "blank"),
                 title = list(hjust = 0.5, face = "plain", colour = "black"),
                 strip = list(background = "#D9D9D9FF", face = "plain", hjust = 0.5),
                 legend = "right", scales = c("x", "y"), y_expand = "default",
                 border = "#333333FF", axis_text = "#4D4D4DFF")
  expected <- function(layers, y_range, ...) {
    out <- utils::modifyList(common, list(...))
    c(list(layers = layers), out[names(common)], list(y_range = y_range))
  }
  line <- layer("GeomLine", primary, NULL, logical(0))
  band <- layer("GeomRibbon", character(0), primary, 0.2)
  retro_colours <- c("#00A087FF", "#3C5488FF", "#4DBBD5FF", "#E64B35FF")
  cases <- list(
    SSB = list(plot_SSB(acl, se = TRUE), expected(list(line, band), c(28.6644, 89.6711))),
    recruitment = list(plot_recruitment(acl, se = TRUE), expected(list(line, band), c(179.945, 697.349))),
    recruitment_line = list(plot_recruitment(acl), expected(list(line), c(201.093, 643.539))),
    catch = list(plot_catch(acl), expected(list(line), c(127.41, 259.225))),
    F = list(plot_fishing_mortality(acl), expected(list(line), c(0.247267, 0.508372))),
    compare_ts = list(plot_compare_ts(acl, alscl, se = TRUE), expected(list(
      layer("GeomLine", c(primary, accent), NULL, logical(0)),
      layer("GeomRibbon", character(0), c(primary, accent), 0.15)), c(28.6644, 89.6711),
      strip = list(background = "#D9D9D9FF", face = "bold", hjust = 0.5), legend = "inside",
      scales = c("colour", "fill", "linetype", "x", "y"))),
    retro = list(plot_retro(style_retro_fixture()), expected(list(
      layer("GeomLine", retro_colours, NULL, logical(0)),
      layer("GeomPoint", retro_colours, character(0), logical(0)),
      layer("GeomText", "black", NULL, logical(0))), c(100.8, 105.88),
      legend = "bottom", scales = c("colour", "x", "y"),
      # Room above the lines for the rho text, in both styles since 2.5.0.
      y_expand = c(0.05, 0, 0.22, 0))),
    # Reference lines are drawn under the data in both styles since 2.5.0.
    residuals = list(plot_residuals(acl), expected(list(layer("GeomHline", "grey55", NULL, logical(0)), line,
      layer("GeomSmooth", "#00A087FF", "#999999FF", 0.4)), c(-0.156013, 0.12955))),
    # Since 2.5.0 a legend names the observed and fitted series, and points
    # in short facet panels have room at the top and bottom of the panel.
    CatL = list(plot_CatL(acl), expected(list(layer("GeomPoint", accent, character(0), logical(0)), line),
                                         c(-3.2858, -1.8406), legend = "bottom", scales = c("colour", "x", "y"),
                                         y_expand = rep(c((2.5 * ggplot2::.pt / 72 / 2 + 0.06) / 1.1, 0), 2L))))
  for (name in names(cases)) {
    look <- style_look(cases[[name]][[1L]])
    want <- cases[[name]][[2L]]
    expect_identical(look[setdiff(names(want), "y_range")], want[setdiff(names(want), "y_range")],
                     label = paste("look of", name))
    expect_equal(look$y_ranges[[1L]], want$y_range, tolerance = 1e-4, label = paste("y range of", name))
  }
  # The ridgeline default is viridis, as in 2.4.5.
  ridges <- plot_ridges(acl)
  expect_identical(style_build(ridges[[1L]])$plot$scales$get_scales("fill")$palette(3L),
                   ggplot2::scale_fill_viridis_d()$palette(3L))
})
