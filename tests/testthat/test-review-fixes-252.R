# Fixes of version 2.5.2 found by the reviews of release 2.5.1: compatibility
# (A), defects found by the code review (B) and what a newcomer reads in R,
# with three statements of the case review (C). Each test fails on 2.5.1.

# One small ACL fit and one small ALSCL fit for the whole file. Every
# parameter other than mean_log_R is fixed, so Linf, k and t0 are fixed too.
fixes_fit <- local({
  fits <- list()
  function(model = "ACL") {
    if (is.null(fits[[model]])) fits[[model]] <<- fit_fixture(model)
    fits[[model]]
  }
})
fixes_layers <- function(p, geom) which(vapply(p$layers, function(z) inherits(z$geom, geom), logical(1)))
fixes_theme <- function(p) ggplot2::ggplot_build(p)$plot$theme
fixes_rd <- function(name) gsub("\\s+", " ", paste(as.character(test_rd_database()[[name]]), collapse = ""))
# The plots of a patchwork that draw tiles (heat maps).
fixes_heat_maps <- function(p) Filter(function(q) inherits(q, "ggplot") && length(fixes_layers(q, "GeomTile")),
                                      ALSCL:::.acl_patches(p)$plots)
# A retrospective analysis of three peels, as retro_model() returns it.
fixes_retro <- function(times = 2000:2004, peels = 3L) {
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
  list(results = d, last_points = d[d$Year == terminal, ],
       rho_text = data.frame(Variable = c("B", "Rec", "SSB", "N"), Rho = .01, Year = times[2L],
                             Valid = TRUE, ValidPeels = peels, RequestedPeels = peels),
       model_type = "acl",
       fit_diagnostics = data.frame(Peel = 0:peels, RetrospectiveYear = times[Y - 0:peels],
                                    error = "", numerical_ok = TRUE))
}

test_that("DESCRIPTION declares the minimum versions that the code needs (A1)", {
  field <- function(name) gsub("\\s+", " ", utils::packageDescription("ALSCL")[[name]])
  for (entry in c("scales (>= 1.4.0)", "TMB (>= 1.9.17)", "dplyr (>= 1.1.4)", "tidyr (>= 1.3.0)",
                  "ggplot2 (>= 4.0.0)", "ggsci (>= 2.7)", "ggridges (>= 0.5.5)", "patchwork (>= 1.3.2)"))
    expect_match(field("Imports"), entry, fixed = TRUE)
  expect_match(field("Suggests"), "testthat (>= 3.1.8)", fixed = TRUE)
  expect_match(field("Depends"), "R (>= 4.1.0)", fixed = TRUE)
})

test_that("a transformed scale keeps the breaks of its transformation (A3)", {
  base <- ggplot2::ggplot(data.frame(x = 1:5, y = 10^(1:5)), ggplot2::aes(x, y)) + ggplot2::geom_line()
  log_y <- ALSCL:::.acl_tidy_axes(base + ggplot2::scale_y_log10())$scales$get_scales("y")
  expect_s3_class(log_y$breaks, "waiver")
  expect_identical(ALSCL:::.acl_scale_transformation(log_y), "log-10")
  # The labels of a log scale are those of the package (decimals here), not
  # the E notation of the transformation; a square root scale keeps its own.
  # get_labels() takes breaks on the transformed (log10) scale.
  expect_identical(log_y$get_labels(log10(c(10, 1000, 1e5))), c("10", "1,000", "100,000"))
  sqrt_y <- ALSCL:::.acl_tidy_axes(base + ggplot2::scale_y_sqrt())$scales$get_scales("y")
  expect_s3_class(sqrt_y$labels, "waiver")
  # A linear scale gets the breaks and labels of the package; a scale
  # without the method counts as linear.
  linear <- ALSCL:::.acl_tidy_axes(base + ggplot2::scale_y_continuous())$scales$get_scales("y")
  expect_true(is.function(linear$breaks))
  expect_true(is.function(linear$labels))
  expect_identical(ALSCL:::.acl_scale_transformation(list()), "identity")
})

test_that("the advice on a TMB and Matrix ABI mismatch updates both packages first (A4)", {
  starts <- list(list(message = "NaN gradient"))
  advice <- ALSCL:::.acl_starts_failed_message(starts, list(ok = FALSE, built = "1", current = "2"))
  expect_match(advice, paste0("This mismatch can make every start fail. Update both packages with ",
                              "install.packages(c(\"Matrix\", \"TMB\")) and restart R."), fixed = TRUE)
  expect_match(advice, paste0("If TMB still warns about the Matrix ABI version when it loads, reinstall TMB ",
                              "from source with install.packages(\"TMB\", type = \"source\"), restart R and ",
                              "fit again."), fixed = TRUE)
  expect_false(grepl("ABI", ALSCL:::.acl_starts_failed_message(starts, list(ok = TRUE))))
})

test_that("acl_theme_set() checks every key before it stores any (B1)", {
  withr::local_options(list(acl.theme = NULL))
  before <- acl_theme()
  expect_error(acl_theme_set(line_size = 2, title_size = "14pt"), "title_size must be one positive number")
  expect_error(acl_theme_set(point_size = 0), "point_size must be one positive number")
  expect_error(acl_theme_set(compare_line_size = -1), "compare_line_size must be one positive number")
  expect_error(acl_theme_set(se_alpha = 2), "se_alpha must be one number from 0 (transparent) to 1", fixed = TRUE)
  expect_error(acl_theme_set(compare_se_alpha = NA_real_), "compare_se_alpha must be one number from 0")
  expect_error(acl_theme_set(x_expand = 0.05), "x_expand must be two numbers of zero or more")
  expect_error(acl_theme_set(x_expand = c(-0.1, 0)), "x_expand must be two numbers of zero or more")
  expect_error(acl_theme_set(se_color = "darkgreen1"), "se_color must be one color name or code")
  expect_error(acl_theme_set(line_color = NA_character_), "line_color must be one color name or code")
  expect_error(acl_theme_set(compare_colors = c("red", "notacolor")), "not colors: \"notacolor\".", fixed = TRUE)
  expect_error(acl_theme_set(compare_linetypes = c("solid", "wiggly")), "not line types: \"wiggly\".",
               fixed = TRUE)
  # Positions of the comparison legend are checked like legend_position.
  expect_error(acl_theme_set(compare_legend_pos = "middle"),
               "compare_legend_pos must be one of \"bottom\", \"top\", \"left\", \"right\", \"none\"", fixed = TRUE)
  expect_error(acl_theme_set(legend_position = "middle"),
               "legend_position must be one of \"bottom\", \"top\", \"left\", \"right\", \"none\"", fixed = TRUE)
  expect_error(acl_theme_set(compare_facet_ncol = 1.5), "compare_facet_ncol must be NULL or one whole number")
  expect_error(acl_theme_set(compare_facet_ncol = 0), "compare_facet_ncol must be NULL or one whole number")
  key <- names(acl_theme("titles"))[1L]
  expect_error(do.call(acl_theme_set, list(titles = stats::setNames(list(3), key))),
               paste0("titles$", key, " must be one text"), fixed = TRUE)
  expect_error(acl_theme_set(xlab = list(nonsense = "x")), "xlab has unknown keys: nonsense")
  expect_error(acl_theme_set(font_family = ""), "font_family must be one font family name")
  # Nothing of a call that failed was stored.
  expect_identical(acl_theme(), before)
  acl_theme_set(compare_legend_pos = "TOP", compare_facet_ncol = 2, x_expand = c(0, 0.02), se_alpha = 0)
  expect_identical(acl_theme()[c("compare_legend_pos", "compare_facet_ncol", "x_expand", "se_alpha")],
                   list(compare_legend_pos = "top", compare_facet_ncol = 2, x_expand = c(0, 0.02), se_alpha = 0))
})

test_that("every quantity after the last observed time step is flagged as extrapolated (B2)", {
  full <- fixes_fit("ACL")$result
  expect_false(any(extract_estimates(full, "SSB")$extrapolated))
  expect_identical(extract_estimates(full, "CN")$extrapolated, full$year == max(full$year))
  # No survey observation in the last time step.
  fit <- full
  fit$observations[, ncol(fit$observations)] <- NA
  last <- fit$year[length(fit$year) - 1L]
  for (quantity in c("SSB", "Rec", "B", "N", "NA", "NL")) {
    x <- extract_estimates(fit, quantity)
    expect_identical(x$extrapolated, x$year > last, info = quantity)
  }
  # F and catch are predictions from the last observed time step on.
  for (quantity in c("F", "CN")) {
    x <- extract_estimates(fit, quantity)
    expect_identical(x$extrapolated, x$year >= last, info = quantity)
  }
})

test_that("plot_VB(se = TRUE) draws no band when Linf, k and t0 are all fixed (B3)", {
  acl <- fixes_fit("ACL")$result
  expect_warning(p <- plot_VB(acl, se = TRUE), "at least one estimated growth parameter (Linf, k or t0)",
                 fixed = TRUE)
  expect_length(fixes_layers(p, "GeomRibbon"), 0L)
  expect_null(ALSCL:::.acl_growth_interval(acl, 1:4))
  alscl <- fixes_fit("ALSCL")$result
  expect_warning(p <- plot_VB(alscl, parameter_curve = TRUE, se = TRUE), "at least one estimated growth parameter")
  expect_length(fixes_layers(p, "GeomRibbon"), 0L)
})

test_that("the theme key legend_position places the legend of every plot that names its series (B4)", {
  withr::local_options(list(acl.theme = NULL))
  acl <- fixes_fit("ACL")$result; alscl <- fixes_fit("ALSCL")$result
  readings <- data.frame(age = 1:4, mean_length = c(15, 24, 31, 36))
  survey_readings <- subset(length_at_age(acl, basis = "survey"), age %in% c(2, 4))
  reported <- data.frame(year = acl$year, catch = c(10, 12, 9, 11, 13))
  varying <- acl
  q <- stats::plogis(log(19) * (acl$len_mid - 20) / 10)
  varying$recipe$args$survey_q <- cbind(matrix(q, length(q), 3), matrix(q / 2, length(q), 2))
  plots <- list(
    CatL_length = function() plot_CatL(acl),
    CatL_year = function() plot_CatL(acl, facet_by = "year"),
    VB_observed = function() plot_VB(acl, observed = readings),
    VB_curve = function() plot_VB(alscl, parameter_curve = TRUE),
    length_at_age = function() plot_length_at_age(acl, observed = survey_readings, basis = "survey", ages = c(2, 4)),
    relative_catch = function() plot_relative_catch(acl, observed = reported),
    retro = function() plot_retro(fixes_retro()),
    SSB_maturity = function() plot_SSB(acl, maturity_at_age = c(0, .5, 1, 1)),
    catchability = function() plot_survey_catchability(varying))
  for (position in c("top", "none")) {
    acl_theme_set(legend_position = position)
    for (name in names(plots))
      expect_identical(fixes_theme(plots[[name]]())$legend.position, position, info = paste(name, position))
  }
  # Without the key, as under the classic style, the legend is below the panels.
  acl_theme_set(style = "classic")
  for (name in names(plots))
    expect_identical(fixes_theme(plots[[name]]())$legend.position, "bottom", info = name)
})

test_that("catchability curves name runs of consecutive time steps of the fit (B5)", {
  fit <- fixes_fit("ACL")$result
  L <- length(fit$len_mid); Y <- length(fit$year)
  q <- stats::plogis(log(19) * (fit$len_mid - 20) / 10)
  # Two survey vessels in alternate years.
  fit$recipe$args$survey_q <- matrix(rep(c(q, q / 2), length.out = L * Y), L, Y)
  expect_identical(levels(plot_survey_catchability(fit, return_data = TRUE)$data$Curve),
                   c("2000, 2002, 2004", "2001, 2003"))
  fit$recipe$args$survey_q <- cbind(matrix(q, L, 3), matrix(q / 2, L, 2))
  expect_identical(levels(plot_survey_catchability(fit, return_data = TRUE)$data$Curve),
                   c("2000-2002", "2003-2004"))
})

test_that("a global line_color does not change the color of the bands (B6)", {
  withr::local_options(list(acl.theme = NULL))
  fit <- fixes_fit("ACL")$result
  band <- function(p) unique(ggplot2::layer_data(p, fixes_layers(p, "GeomRibbon")[1L])$fill)
  draw <- list(SSB = function(...) plot_SSB(fit, se = TRUE, ...),
               F = function(...) plot_fishing_mortality(fit, se = TRUE, ...),
               recruitment = function(...) plot_recruitment(fit, se = TRUE, geom = "line", ...))
  defaults <- lapply(draw, function(f) band(f()))
  acl_theme_set(line_color = "red")
  for (name in names(draw)) {
    # The band keeps the color of its line, the color of the quantity.
    expect_identical(band(draw[[name]]()), defaults[[name]], info = name)
    # A line color in the call gives the band that color.
    expect_identical(band(draw[[name]](line_color = "darkgreen")), "darkgreen", info = name)
  }
  # A band color set apart from the palette is used.
  acl_theme_set(se_color = "orange")
  expect_identical(band(draw$SSB()), "orange")
  expect_identical(band(draw$SSB(se_color = "purple")), "purple")
})

test_that("compare_facet_ncol and compare_facet_scales reach every comparison plot with panels (B7)", {
  withr::local_options(list(acl.theme = NULL))
  acl <- fixes_fit("ACL")$result; alscl <- fixes_fit("ALSCL")$result
  d <- fixes_fit("ACL")$input$data.CatL
  acl_theme_set(compare_facet_ncol = 1, compare_facet_scales = "fixed")
  fixed <- list(x = FALSE, y = FALSE)
  expect_facets <- function(p, ncol, free) {
    expect_equal(p$facet$params$ncol, ncol)
    expect_identical(p$facet$params$free, free)
  }
  expect_facets(plot_compare_CatL(acl, acl, d), 1, fixed)
  expect_facets(suppressMessages(plot_compare_F(acl, alscl)), 1, fixed)
  heat <- fixes_heat_maps(plot_compare_growth(acl, alscl))
  expect_length(heat, 1L)
  expect_facets(heat[[1L]], 1, fixed)
  expect_equal(plot_compare_metrics(acl, acl, d)$patches$layout$ncol, 1)
  # Arguments of the call win.
  expect_facets(plot_compare_CatL(acl, acl, d, facet_ncol = 3, facet_scales = "free"), 3, list(x = TRUE, y = TRUE))
  expect_equal(plot_compare_metrics(acl, acl, d, facet_ncol = 2)$patches$layout$ncol, 2)
})

test_that("age_range of plot_compare_growth() selects the ages of the heat map too (B8)", {
  acl <- fixes_fit("ACL")$result; alscl <- fixes_fit("ALSCL")$result
  every <- fixes_heat_maps(plot_compare_growth(acl, alscl))[[1L]]$data
  some <- fixes_heat_maps(plot_compare_growth(acl, alscl, age_range = c(2, 3)))[[1L]]$data
  expect_identical(sort(unique(some$Age)), c(2, 3))
  expect_gt(length(unique(every$Age)), 2L)
})

test_that("x_angle applies to time axes with breaks given in the call or the theme (B9)", {
  withr::local_options(list(acl.theme = NULL))
  fit <- fixes_fit("ACL")$result
  angle <- function(p) ggplot2::calc_element("axis.text.x.bottom", fixes_theme(p))$angle
  acl_theme_set(x_angle = 45)
  expect_equal(angle(plot_SSB(fit, x_breaks = c(2000, 2002, 2004))), 45)
  acl_theme_set(x_breaks = c(2000, 2002, 2004))
  expect_equal(angle(plot_SSB(fit)), 45)
  expect_equal(angle(plot_fishing_mortality(fit)), 45)
  acl_theme_set(x_angle = 0)
  expect_equal(angle(plot_SSB(fit)), 0)
})

test_that("the help of acl_theme_set() says where x_breaks and x_angle are also arguments (B10)", {
  text <- fixes_rd("acl_theme_set.Rd")
  expect_false(grepl("also work as arguments of the plot functions and of", text, fixed = TRUE))
  expect_match(text, "\\code{x_breaks} is also an argument of the plot functions, and \\code{x_angle} an argument of \\code{theme_acl()}",
               fixed = TRUE)
})

test_that("a global x_breaks reaches the length axes of the comparison plots (B11)", {
  withr::local_options(list(acl.theme = NULL))
  acl <- fixes_fit("ACL")$result; alscl <- fixes_fit("ALSCL")$result
  d <- fixes_fit("ACL")$input$data.CatL
  acl_theme_set(x_breaks = c(20, 40))
  expect_equal(plot_compare_CatL(acl, acl, d)$scales$get_scales("x")$breaks, c(20, 40))
  expect_equal(plot_compare_selectivity(acl, alscl)$scales$get_scales("x")$breaks, c(20, 40))
})

test_that("plot_residuals() reports the cap it applies and the length bins it caps (B12)", {
  fit <- fixes_fit("ACL")$result
  fit$report$resid_index[1L, 1L] <- 2
  fit$report$resid_index[2L, 3L] <- -1
  for (layout in c("length", "year"))
    expect_message(plot_residuals(fit, resid_cap = 0.25, facet_by = layout),
                   "plot_residuals: 2 residuals capped at +/-0.25, in length bins 15 and 20.", fixed = TRUE)
  expect_message(plot_residuals(fit, resid_cap = 1.5), "1 residual capped at +/-1.5, in length bin 15.", fixed = TRUE)
  expect_no_message(plot_residuals(fit, resid_cap = 3))
})

test_that("the legend keys of plot_CatL(facet_by = \"year\") have the widths of its thinned lines (B13)", {
  withr::local_options(list(acl.theme = NULL))
  fit <- fixes_fit("ACL")$result
  widths <- function(p) list(
    lines = unname(vapply(p$layers[fixes_layers(p, "GeomLine")], function(l) as.numeric(l$aes_params$linewidth),
                          numeric(1))),
    keys = p$guides$guides$colour$params$override.aes$linewidth)
  # Five panels: the observed and the fitted line, 2/3 and 1.2 times the
  # theme line width, are drawn at two thirds of these widths.
  drawn <- widths(plot_CatL(fit, facet_by = "year"))
  expect_equal(drawn$lines, c(2 / 3, 1.2) * 2 / 3)
  expect_equal(drawn$keys, drawn$lines)
  # A width given in the call is not thinned.
  drawn <- widths(plot_CatL(fit, facet_by = "year", line_size1 = 2))
  expect_equal(drawn$lines, c(4 / 9, 2))
  expect_equal(drawn$keys, drawn$lines)
})

test_that("unknown entries of a selection are named in a warning, or an error when none is left (B14)", {
  acl <- fixes_fit("ACL")$result
  d <- fixes_fit("ACL")$input$data.CatL
  expect_warning(plot_compare_metrics(acl, acl, d, metrics = c("error", "aic", "R2")),
                 "Left out metrics that do not occur in the panels error, R2, MAPE, IC and npar: aic.", fixed = TRUE)
  expect_error(plot_compare_metrics(acl, acl, d, metrics = "aic"),
               "No requested metrics occur in the panels error, R2, MAPE, IC and npar (aic).", fixed = TRUE)
  expect_warning(p <- plot_compare_CatL(acl, acl, d, years = c(2001, 2030)),
                 "Left out years that do not occur in data.CatL: 2030.", fixed = TRUE)
  expect_identical(unique(p$data$Year), 2001)
  expect_error(plot_compare_CatL(acl, acl, d, years = 2030), "No requested years occur in data.CatL (2030).",
               fixed = TRUE)
})

test_that("acl_save_plot() takes the unit of width and height (B15)", {
  p <- plot_SSB(fixes_fit("ACL")$result)
  file <- withr::local_tempfile(fileext = ".png")
  pixels <- function() {
    con <- file(file, "rb")
    on.exit(close(con))
    bytes <- as.integer(readBin(con, "raw", 24L))
    c(sum(bytes[17:20] * 256^(3:0)), sum(bytes[21:24] * 256^(3:0)))
  }
  acl_save_plot(p, file, width = 16, height = 10, units = "cm")
  expect_equal(pixels(), c(16, 10) / 2.54 * 300, tolerance = 1e-3)
  acl_save_plot(p, file, width = 160, height = 100, units = "MM", dpi = 100)
  expect_equal(pixels(), c(160, 100) / 25.4 * 100, tolerance = 1e-2)
  acl_save_plot(p, file, width = 1200, height = 900, units = "px")
  expect_equal(pixels(), c(1200, 900), tolerance = 1e-3)
  expect_error(acl_save_plot(p, file, width = 16, units = "pt"),
               "units must be one of \"in\", \"cm\", \"mm\", \"px\"", fixed = TRUE)
})

test_that("run_acl(output = TRUE, silent = TRUE) saves its output without printing (B16)", {
  skip_on_cran()
  fixture <- fixes_fit("ACL")
  folder <- withr::local_tempdir()
  withr::local_dir(folder)
  args <- c(fixture$input, list(parameters = fixture$parameters, map = fixture$map, silent = TRUE, output = TRUE))
  expect_silent(do.call(run_acl, args))
  table <- utils::read.csv(file.path(folder, "output", "tables", "diagnostics.csv"))
  expect_true("Maximum absolute gradient" %in% table$Metric)
  expect_true(file.exists(file.path(folder, "output", "figures", "result", "plot_SSB.png")))
})

test_that("simulate_example_data() writes the files that read_survey_csv() reads (B17)", {
  folder <- withr::local_tempdir()
  sm <- suppressMessages(simulate_example_data(years = 2000:2004, seed = 1, save_csv = TRUE, output_dir = folder))
  files <- file.path(folder, c("data.CatL.csv", "data.wgt.csv", "data.mat.csv"))
  expect_true(all(file.exists(files)))
  # No scientific notation in the files.
  expect_false(any(grepl("[0-9][eE][-+]?[0-9]", unlist(lapply(files, readLines)))))
  back <- read_survey_csv(folder)
  for (table in c("data.CatL", "data.wgt", "data.mat"))
    expect_equal(unname(as.matrix(back[[table]][-1L])), unname(as.matrix(sm[[table]][-1L])), info = table)
})

test_that("the choice arguments named in the review accept any letter case (B18)", {
  withr::local_options(list(acl.theme = NULL))
  acl <- fixes_fit("ACL")$result; alscl <- fixes_fit("ALSCL")$result
  expect_identical(residuals(acl, type = "Standardized"), residuals(acl, type = "standardized"))
  expect_s3_class(plot_compare_F_ts(acl, alscl, method = "Mean", basis = "Age"), "ggplot")
  expect_s3_class(plot_compare_growth(acl, alscl, basis = "Survey"), "patchwork")
  acl_theme_set(style = "Classic")
  expect_identical(acl_theme("style"), "classic")
})

test_that("print(fit) is a short overview and summary(fit) the detailed view (C1)", {
  fit <- fixes_fit("ACL")$result
  overview <- capture.output(print(fit))
  expect_identical(overview[1:4], c("ACL fit", "Time steps 2000 to 2004 (annual), 5 time steps",
                                    "F structure: group_year (one F deviation per age class and time step)",
                                    "Numerical checks: passed"))
  expect_match(overview[5L], "^Objective \\(negative log-likelihood\\): -?[0-9.]+$")
  expect_identical(overview[6:7], c("Estimated parameters: 1",
                                    "Details: summary(fit); time series: extract_estimates(fit)"))
  expect_length(overview, 7L)
  # A fit that failed the numerical checks names the checks that failed.
  failed <- fit
  failed$diagnostics$numerical_ok <- FALSE
  failed$diagnostics$issues <- "Hessian not positive definite"
  expect_true("Numerical checks: failed (Hessian not positive definite)" %in% capture.output(print(failed)))
  # The summary keeps the elements and columns of earlier versions.
  s <- summary(fit)
  expect_named(s$parameters, c("parameter", "scale", "status", "estimate", "std_error", "conf_low", "conf_high",
                               "numerical_ok"))
  expect_named(s$diagnostics, c("convergence_code", "max_abs_gradient", "pdHess", "bound_hit", "natural_boundary",
                                "numerical_ok", "issues"))
  expect_identical(s$parameters$parameter[1L], "mean_log_R")
  expect_identical(unique(s$parameters$scale), "natural")
  detail <- capture.output(print(s))
  expect_true(all(c("Estimated parameters (natural scale, 95% confidence interval):",
                    "Fixed parameters (natural scale):") %in% detail))
  expect_match(detail, "^ Median recruitment +97\\.42 +11\\.07 +77\\.97 +121\\.7 +mean_log_R$", all = FALSE)
  expect_match(detail, "^ Median fishing mortality rate +0\\.3 +mean_log_F$", all = FALSE)
  expect_false(any(grepl("numerical_ok|natural +natural|TRUE +TRUE", detail)))
  expect_true(all(nchar(detail) <= 80))
  # Issues are a list of wrapped entries.
  s$diagnostics$numerical_ok <- FALSE
  s$diagnostics$issues <- paste(c(paste(rep("first issue", 15), collapse = " "), "second issue"), collapse = "; ")
  detail <- capture.output(print(s))
  expect_true(all(c("Issues:", "  - second issue") %in% detail))
  expect_true(all(nchar(detail) <= 80))
})

test_that("the table of diagnose_model() prints checks as TRUE or FALSE, with a legend (C2)", {
  fixture <- fixes_fit("ACL")
  invisible(capture.output(d <- diagnose_model(fixture$input$data.CatL, fixture$result)))
  expect_s3_class(d, "data.frame")
  expect_named(d, c("Metric", "Value"))
  expect_type(d$Value, "double")
  expect_true(all(c("Maximum absolute gradient", "Optimizer converged", "Positive-definite Hessian",
                    "Parameter boundary hit", "Numerical checks passed") %in% d$Metric))
  expect_false(any(c("Final Outer mgc", "Numerical Screen Passed", "Model Converged") %in% d$Metric))
  expect_identical(sum(grepl("gradient", d$Metric)), 1L)
  shown <- capture.output(print(d))
  expect_match(shown, "^ Optimizer converged +TRUE$", all = FALSE)
  expect_match(shown, "^ Parameter boundary hit +FALSE$", all = FALSE)
  expect_match(shown, "^ AIC +-46\\.83$", all = FALSE)
  expect_false(any(grepl("e\\+00", shown)))
  expect_match(paste(shown, collapse = " "), "MSE, RMSE: mean squared error and its square root", fixed = TRUE)
})

test_that("compare_models() prints the optimizer code with its message and stays within the console (C3)", {
  fixture <- fixes_fit("ACL")
  fit <- fixture$result
  fit$converge <- "relative convergence (4)"
  withr::local_options(list(width = 100))
  printed <- capture.output(cmp <- compare_models(fit, fit, fixture$input$data.CatL))
  expect_identical(unlist(cmp$summary[cmp$summary$Metric == "Convergence", -1L], use.names = FALSE),
                   rep("code 0, relative convergence", 2L))
  expect_false(any(grepl("(4)", printed, fixed = TRUE)))
  expect_true(all(nchar(printed) <= 100))
  # One line for each growth parameter, with its meaning beside it.
  linf <- grep("^ Linf ", printed, value = TRUE)
  expect_length(linf, 2L)
  expect_match(linf, "^ Linf +60 +asymptote of the von Bertalanffy curve of mean length at age \\(length unit\\)$")
  expect_match(printed, "^ACL \\(1\\): passed; optimizer code 0, maximum absolute gradient", all = FALSE)
})

test_that("check_alscl_data() names the cells that are not numbers (C4)", {
  x <- fixes_fit("ACL")$input
  x$data.CatL[[3]] <- as.character(x$data.CatL[[3]])
  x$data.CatL[2, 3] <- "12,5"
  result <- check_alscl_data(x)
  expect_false(result$valid)
  expect_identical(result$errors, paste0("data.CatL must hold numbers (NA marks a missing value). ",
                                         "Not a number in length bin 20, time step 2001: \"12,5\"."))
  x <- fixes_fit("ACL")$input
  x$data.wgt[-1] <- lapply(x$data.wgt[-1], as.character)
  x$data.wgt[1:5, 2] <- "n/a"
  expect_match(check_alscl_data(x)$errors,
               "data.wgt must hold numbers (NA marks a missing value). Not a number in length bin 15, time step 2000: \"n/a\"; length bin 20, time step 2000: \"n/a\"; length bin 25, time step 2000: \"n/a\"; and 2 more cells.",
               fixed = TRUE)
})

test_that("messages and notes say time step where they said period (C5)", {
  x <- fixes_fit("ACL")$input
  x$data.CatL[[3]] <- NA_real_
  expect_identical(check_alscl_data(x)$warnings, "No positive observations in time steps: 2001")
})

test_that("the package help page introduces the package and is not internal (C6)", {
  text <- fixes_rd("ALSCL-package.Rd")
  expect_false(grepl("\\keyword{internal}", text, fixed = TRUE))
  for (name in c("run_acl", "run_alscl", "diagnose_model", "plot_SSB", "extract_estimates"))
    expect_match(text, paste0("\\code{\\link[=", name, "]{", name, "()}}"), fixed = TRUE)
  expect_match(text, "\\donttest{", fixed = TRUE)
  expect_match(text, "YTF_example", fixed = TRUE)
  expect_match(text, "https://fanzhang-lab-shou.github.io/ALSCL/", fixed = TRUE)
  expect_match(utils::packageDescription("ALSCL")$URL, "https://fanzhang-lab-shou.github.io/ALSCL/", fixed = TRUE)
})

test_that("the note on an initial total mortality rate below M names recruitment that decreased (C7)", {
  par <- c(mean_log_R = 5, log_init_Z = log(.19))
  fit <- list(opt = list(par = par, objective = 100, convergence = 0L), vcov = diag(.01, 2),
              convergence_code = 0L, max_abs_gradient = 1e-8, pdHess = TRUE, bound_hit = FALSE,
              model_type = "ACL", par_low_up = cbind(estimate = par, lower = par - 5, upper = par + 5),
              age = 1:4, len_border = seq(17.5, 52.5, 5), report = list(Linf = 60, vbk = .4, t0 = 1 / 60),
              M = .29)
  note <- ALSCL:::.acl_fit_diagnostics(fit)$plausibility$note
  expect_match(note, "The numbers at age in the first time step then decline with age more slowly", fixed = TRUE)
  expect_match(note, "as they do when the older cohorts were large", fixed = TRUE)
  expect_match(note, "whether recruitment decreased before the first time step.", fixed = TRUE)
  expect_false(grepl("increased|period", note))
})

test_that("the help of self_test() says that the mean parameter is close to the weighted mean (C8)", {
  text <- fixes_rd("self_test.Rd")
  expect_match(text, "is close to the weighted mean of the fitted process", fixed = TRUE)
  expect_false(grepl("equals the weighted mean", text, fixed = TRUE))
})

test_that("exp(mean_log_R) and exp(mean_log_F) are named as medians (C9)", {
  expect_identical(ALSCL:::.acl_parameter_name(c("mean_log_R", "mean_log_F", "logit_log_R")),
                   c("Median recruitment", "Median fishing mortality rate",
                     "Correlation of log recruitment between time steps"))
  expect_false(any(grepl("^Mean ", ALSCL:::.acl_parameter_names)))
})
