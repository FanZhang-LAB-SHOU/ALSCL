#' ALSCL plot theme configuration
#'
#' Global settings for all ALSCL plot functions, including model comparison plots.
#' Change titles, axis labels, font family, colors, line sizes, and
#' comparison plot styles in one place. The default style, \code{style = "default"},
#' draws stock size, fishing mortality, recruitment and catch each in its own
#' color, draws total recruitment and total catch as bars, starts the y axis
#' of these plots at zero, and uses bold left-aligned titles and facet labels
#' without boxes. \code{style = "classic"} restores the colors and forms of
#' ALSCL 2.4.5 (see \code{\link{acl_theme_set}()}). \code{\link{theme_acl}()}
#' and \code{\link{acl_palette}()} give your own ggplots the same look.
#'
#' @section Usage:
#' \preformatted{
#' # View current settings
#' acl_theme()
#'
#' # The colors and forms of ALSCL 2.4.5, then back to the default style
#' acl_theme_set(style = "classic")
#' acl_theme_set(style = "default")
#'
#' # Change just one thing
#' acl_theme_set(font_family = "Times New Roman")
#' acl_theme_set(base_theme = "theme_classic")
#' acl_theme_set(compare_line_size = 2)
#'
#' # ACL vs ALSCL comparison style
#' acl_theme_set(
#'   compare_colors = c("steelblue", "tomato"),
#'   compare_linetypes = c("solid", "dashed")
#' )
#'
#' # Same model, different parameters
#' acl_theme_set(
#'   compare_colors = c("M=0" = "blue", "M=0.3" = "red")
#' )
#' plot_compare_ts(result1, result2,
#'   model1_name = "M=0", model2_name = "M=0.3")
#'
#' # Or just override per-call (no global setting needed)
#' plot_compare_ts(result1, result2,
#'   model1_name = "Run A", model2_name = "Run B",
#'   colors = c("darkgreen", "purple"))
#'
#' # All plots return ggplot objects, so you can layer:
#' plot_compare_ts(result1, result2) +
#'   ggplot2::theme(legend.position = "top") +
#'   ggplot2::labs(title = "My Title")
#'
#' # Reset to defaults
#' acl_theme_reset()
#' }
#'
#' @name acl_theme
NULL

# ---------------------------------------------------------------------------
# Choice arguments: values out of a fixed set, in any letter case. Defined
# first, because the palette defaults below use them when the package loads.
# ---------------------------------------------------------------------------

# Positions in `choices` of the values `x`, 0 where a value matches none.
# Letter case does not matter, unless two choices differ only by case: such
# a set is matched with case. With `partial = TRUE` the start of a choice
# matches too when it is the start of no other choice, as in match.arg(); a
# complete match comes first.
.acl_choice_position <- function(x, choices, partial = FALSE) {
  if (!is.character(x)) return(integer(length(x)))
  if (!anyDuplicated(tolower(choices))) {
    x <- tolower(x)
    choices <- tolower(choices)
  }
  if (partial) pmatch(x, choices, nomatch = 0L, duplicates.ok = TRUE) else match(x, choices, nomatch = 0L)
}

# One value out of a fixed set of character strings, or with `several =
# TRUE` one or more values, matched by .acl_choice_position(): "sbl" gives
# "SBL". The result holds the values of `choices`, as the functions use and
# store them. As in match.arg(), `choices` can be left out to take the
# default of the argument `x` of the calling function; a value identical to
# the choices (an argument left at its default) gives the first choice, or
# all of them with several = TRUE, and NULL gives the first choice. Anything
# else is an error that lists the choices.
.acl_match_choice <- function(x, choices, arg = NULL, several = FALSE, partial = FALSE) {
  if (is.null(arg)) arg <- deparse1(substitute(x))
  if (missing(choices)) {
    caller <- sys.parent()
    choices <- eval(formals(sys.function(caller))[[as.character(substitute(x))]],
                    envir = sys.frame(caller))
  }
  if (is.null(x)) return(choices[1L])
  if (identical(x, choices)) return(if (several) choices else choices[1L])
  usable <- is.character(x) && length(x) >= 1L && (several || length(x) == 1L)
  position <- if (usable) .acl_choice_position(x, choices, partial) else 0L
  if (usable && all(position > 0L)) return(choices[position])
  unknown <- if (usable) unique(x[position == 0L & !is.na(x)]) else character()
  stop(arg, " must be ", if (several) "one or more of " else "one of ",
       paste0("\"", choices, "\"", collapse = ", "),
       if (!anyDuplicated(tolower(choices))) " in any letter case",
       if (length(unknown)) paste0(", not ", paste0("\"", unknown, "\"", collapse = ", ")), ".",
       call. = FALSE)
}

# The values of `x` that match a choice (.acl_choice_position()) replaced
# by that choice. Other values, and values that are not text, are returned
# unchanged, for arguments that also take other values or that the caller
# checks with a message of its own.
.acl_canonical <- function(x, choices, partial = FALSE) {
  if (!is.character(x) || !length(x)) return(x)
  position <- .acl_choice_position(x, choices, partial)
  x[position > 0L] <- choices[position[position > 0L]]
  x
}

# A legend position given as text, in any letter case. Other values, such as
# a position inside the panel given as two numbers, are left to ggplot2.
.acl_legend_positions <- c("bottom", "top", "left", "right", "none", "inside")
.acl_legend_position <- function(x) .acl_canonical(x, .acl_legend_positions)

# The entries of a selection (`requested`) that occur among the `available`
# values, as those values, in the order requested and without repeats;
# numbers match within rounding error. Entries that do not occur are named
# in a warning, and a selection of which none occurs is an error. `what`
# names the selection and `where` what it selects from.
.acl_select_available <- function(requested, available, what, where) {
  position <- if (is.numeric(requested) && is.numeric(available))
    vapply(requested, function(x) {
      hit <- which(abs(available - x) <= 1e-8 * max(1, abs(x)))
      if (length(hit)) hit[1L] else NA_integer_
    }, integer(1)) else match(requested, available)
  unused <- unique(requested[is.na(position)])
  shown <- paste(vapply(unused, function(x) format(x, digits = 15), character(1)), collapse = ", ")
  if (all(is.na(position)))
    stop("No requested ", what, " occur in ", where, " (", shown, ").", call. = FALSE)
  if (length(unused))
    warning("Left out ", what, " that do not occur in ", where, ": ", shown, ".", call. = FALSE)
  available[unique(position[!is.na(position)])]
}

# The scales argument of facet_wrap(), in any letter case.
.acl_facet_scale_names <- c("fixed", "free_x", "free_y", "free")
.acl_facet_scales <- function(x, arg = "facet_scales") .acl_match_choice(x, .acl_facet_scale_names, arg)

# ---------------------------------------------------------------------------
# Default configuration (internal)
# ---------------------------------------------------------------------------
# Categorical palettes: "default", the colors of the default style, and
# the ggsci palettes. Semantic roles follow from the palette.
.acl_palette_names <- c("default", "npg", "aaas", "nejm", "lancet", "jama")

# Colors of the default style: one per quantity family, a neutral primary
# color, an accent for observations, and the categorical palette.
.acl_default_colors <- list(
  stock = "#047c6c", F = "#ed5f26", recruitment = "#28b3e8", catch = "#002b5f",
  palette = c("#002b5f", "#eb5c24", "#00b29d", "#fda500", "#6eb5d2", "#6eb200",
              "#28b3e8", "#047c6c"),
  retro_peels = c("#252525", "#525252", "#737373", "#969696", "#bdbbbb"),
  ramp = c("#d6ecf5", "#002b5f"))

.acl_palette <- function(palette = "default", n = NULL) {
  palette <- .acl_palette_name(palette)
  cols <- switch(palette,
    default = .acl_default_colors$palette,
    npg = ggsci::pal_npg("nrc")(10),
    aaas = ggsci::pal_aaas("default")(10),
    nejm = ggsci::pal_nejm("default")(8),
    lancet = ggsci::pal_lancet("lanonc")(9),
    jama = ggsci::pal_jama("default")(7))
  if (is.null(n)) return(cols)
  # Interpolate beyond the native palette size instead of recycling.
  if (n <= length(cols)) cols[seq_len(n)] else grDevices::colorRampPalette(cols)(n)
}

# ALSCL 2.5.0 named the default style and its palette "standard". The former
# name is mapped to "default" with the once-per-session warning of
# deprecations.R; palette names are matched without regard to case.
.acl_former_default <- function(value, arg) {
  if (!is.character(value) || length(value) != 1L || is.na(value) || tolower(value) != "standard")
    return(value)
  .acl_deprecated_message(paste0("theme.", arg, "_standard"), sprintf(
    "%s = \"standard\" is the name used in ALSCL 2.5.0; use %s = \"default\".", arg, arg))
  "default"
}

# Name of a supported palette, in any letter case; partial names are
# accepted as before. NULL is not a palette name.
.acl_palette_name <- function(palette) {
  palette <- .acl_former_default(palette, "palette")
  if (is.null(palette)) palette <- NA_character_
  .acl_match_choice(palette, .acl_palette_names, "palette", partial = TRUE)
}

.acl_palette_roles <- function(palette) {
  cols <- .acl_palette(palette)
  primary <- if (palette == "npg") cols[4] else cols[1]
  accent <- if (palette == "npg") cols[1] else cols[2]
  list(palette = palette, line_color = primary, se_color = primary,
       compare_colors = c(primary, accent), point_color = primary,
       observed_color = accent, smooth_color = cols[3],
       hline_color = "grey55", low_col = if (palette == "default") "#ffffff" else "#F7F9FC",
       high_col = primary)
}

# Settings of the two styles: "default", and "classic", which is the look
# of ALSCL 2.4.5. A style sets these keys and
# the colors of its palette (.acl_palette_roles()).
.acl_style_presets <- list(
  default = c(list(style = "default", grid = "none", title_face = "bold", title_hjust = 0,
                title_color = "black",
                stock_color = .acl_default_colors$stock, F_color = .acl_default_colors$F,
                recruitment_color = .acl_default_colors$recruitment,
                catch_color = .acl_default_colors$catch,
                bars = TRUE, y_zero = TRUE, se_alpha = 0.3, compare_se_alpha = 0.25,
                strip = "plain", legend_position = "bottom", axis_color = "black",
                line_size = 1, compare_line_size = 0.9),
           .acl_palette_roles("default")),
  classic = c(list(style = "classic", grid = "none", title_face = "plain", title_hjust = 0.5,
                   title_color = "black",
                   stock_color = NULL, F_color = NULL, recruitment_color = NULL,
                   catch_color = NULL,
                   bars = FALSE, y_zero = FALSE, se_alpha = 0.2, compare_se_alpha = 0.15,
                   strip = "box", legend_position = NULL, axis_color = NULL,
                   line_size = 1.5, compare_line_size = 1.2),
              .acl_palette_roles("npg")))

# Continuous values use a light-to-dark gradient.
.acl_fill_continuous <- function(palette = NULL, name = ggplot2::waiver()) {
  if (is.null(palette)) return(ggplot2::scale_fill_gradient(
    low = acl_theme("low_col"), high = acl_theme("high_col"), name = name))
  palette <- .acl_former_default(palette, "palette")
  palette <- .acl_canonical(palette, .acl_palette_names)
  if (length(palette) == 1L && palette %in% .acl_palette_names) {
    roles <- .acl_palette_roles(palette)
    return(ggplot2::scale_fill_gradient(low = roles$low_col, high = roles$high_col, name = name))
  }
  # The options of the viridis palettes, in any letter case; other values
  # are left to ggplot2.
  palette <- .acl_canonical(palette, c("magma", "inferno", "plasma", "viridis", "cividis", "rocket",
                                       "mako", "turbo", LETTERS[1:8]))
  ggplot2::scale_fill_viridis_c(option = palette, name = name)
}

.acl_defaults <- list(

  # --- Style: "default" or "classic"; see acl_theme_set() ---------------------
  style = "default",
  palette = "default",
  point_color = .acl_palette_roles("default")$point_color,
  observed_color = .acl_palette_roles("default")$observed_color,
  smooth_color = .acl_palette_roles("default")$smooth_color,
  hline_color = "grey55",
  low_col = .acl_palette_roles("default")$low_col,
  high_col = .acl_palette_roles("default")$high_col,

  # --- Panel look set by the style ------------------------------------------
  grid = "none",
  title_face = "bold",
  title_color = "black",
  show_title = TRUE,
  strip = "plain",
  legend_position = "bottom",
  axis_color = "black",

  # --- Colours and forms of the quantity families ---------------------------
  stock_color = .acl_default_colors$stock,
  F_color = .acl_default_colors$F,
  recruitment_color = .acl_default_colors$recruitment,
  catch_color = .acl_default_colors$catch,
  bars = TRUE,
  y_zero = TRUE,

  # --- Base ggplot2 theme --------------------------------------------------
  base_theme = "theme_bw",

  # --- Font ----------------------------------------------------------------
  font_family = "sans",

  # --- Text sizes (in pt) -------------------------------------------------
  title_size      = 14,
  title_hjust     = 0,
  axis_title_size = 12,
  axis_text_size  = 10,
  strip_text_size = 10,
  legend_text_size = 10,

  # --- Axis settings -------------------------------------------------------
  x_breaks = NULL,
  x_expand = c(0.01, 0.01),
  # Angle of the year labels of multi-panel figures: NULL chooses 0 or 45
  # degrees from the width of the panels.
  x_angle = NULL,

  # --- Default colors and line sizes (single-model plots) ------------------
  line_color  = .acl_palette_roles("default")$line_color,
  line_size   = 1,
  point_size  = 2.5,
  se_color    = .acl_palette_roles("default")$se_color,
  se_alpha    = 0.3,

  # --- Interval for positive quantities: "lognormal" or "wald" -------------
  interval    = "lognormal",

  # --- Comparison plot settings (plot_compare_* functions) ------------------
  # Colors/linetypes: positional (1st = model1, 2nd = model2).
  # Names are optional; if provided they override positional matching.
  # Examples:
  #   c("#2166AC", "#B2182B")                       positional
  #   c(ACL = "#2166AC", ALSCL = "#B2182B")         named
  #   c("M=0" = "steelblue", "M=0.5" = "tomato")   custom names
  compare_colors     = .acl_palette_roles("default")$compare_colors,
  compare_linetypes  = c("solid", "dashed"),
  compare_line_size  = 0.9,
  compare_point_size = NULL,
  compare_se_alpha   = 0.25,
  compare_legend_pos = "bottom",
  compare_facet_ncol = NULL,
  compare_facet_scales = "free_y",

  # --- Titles --------------------------------------------------------------
  titles = list(
    # Every title names the quantity drawn, in sentence case and with the
    # names of the axis labels; "with 95% confidence intervals" marks the
    # plots that draw intervals.
    # plot_abundance
    N       = "Total abundance",
    N_se    = "Total abundance with 95% confidence intervals",
    NA_     = "Abundance at age",
    NA_se   = "Abundance at age with 95% confidence intervals",
    NL      = "Abundance at length",
    NL_se   = "Abundance at length with 95% confidence intervals",

    # plot_biomass
    B       = "Total biomass",
    B_se    = "Total biomass with 95% confidence intervals",
    BL      = "Biomass at length",
    BL_se   = "Biomass at length with 95% confidence intervals",
    BA      = "Biomass at age",
    BA_se   = "Biomass at age with 95% confidence intervals",

    # plot_SSB
    SSB     = "Spawning stock biomass",
    SSB_se  = "Spawning stock biomass with 95% confidence intervals",
    SBL     = "Spawning stock biomass at length",
    SBL_se  = "Spawning stock biomass at length with 95% confidence intervals",
    SBA     = "Spawning stock biomass at age",
    SBA_se  = "Spawning stock biomass at age with 95% confidence intervals",

    # plot_recruitment
    Rec     = "Recruitment",
    Rec_se  = "Recruitment with 95% confidence intervals",

    # plot_SSB_Rec
    SSB_Rec = "Spawning stock biomass and recruitment",

    # plot_catch
    CN      = "Catch in numbers",
    CN_se   = "Catch in numbers with 95% confidence intervals",
    CNA     = "Catch in numbers at age",
    CNA_se  = "Catch in numbers at age with 95% confidence intervals",
    CNL     = "Catch in numbers at length",
    CNL_se  = "Catch in numbers at length with 95% confidence intervals",

    # plot_fishing_mortality
    F_year     = "Fishing mortality rate over time",
    F_year_se  = "Fishing mortality rate over time with 95% confidence intervals",
    F_age      = "Fishing mortality rate at age",
    F_age_se   = "Fishing mortality rate at age with 95% confidence intervals",
    F_length   = "Fishing mortality rate at length",
    F_length_se = "Fishing mortality rate at length with 95% confidence intervals",

    # plot_deviance
    dev_R   = "Log recruitment deviations",
    dev_F   = "Log fishing mortality deviations",
    dev_R_multiplier = "Recruitment multipliers",
    dev_F_multiplier = "Fishing mortality multipliers",

    # plot_VB: the von Bertalanffy curve of an ACL fit, and mean length at
    # age from the fitted numbers of an ALSCL fit
    VB      = "Von Bertalanffy growth curve",
    length_at_age = "Mean length at age",

    # plot_length_at_age
    length_at_age_time = "Mean length at age by time step",

    # plot_relative_catch
    relative_catch = "Catch relative to its mean",

    # plot_self_test
    self_test = "Relative error of the estimates in a self-test",

    # plot_natural_mortality and plot_survey_catchability: inputs of a fit
    natural_mortality = "Natural mortality rate used in the fit",
    survey_q     = "Survey catchability at length used in the fit",
    survey_q_age = "Survey catchability multiplier at age used in the fit",

    # plot_ridges: the titles of its two panels and of the figure
    CatL_obs_length = "Observed survey length composition over time",
    CatL_est_length = "Fitted survey length composition over time",
    ridges   = "Observed and fitted survey length compositions",

    # plot_CatL: one panel per length bin, or one panel per time step
    CatL_by_length = "Observed and fitted survey indices over time",
    CatL_by_year   = "Observed and fitted survey indices at length",

    # plot_residuals
    resid_length = "Log residuals of the survey index by length bin",
    resid_year   = "Log residuals of the survey index by time step",

    # plot_retro; the model type is appended in parentheses
    retro    = "Retrospective analysis",

    # plot_pla
    pla      = "Probability of length given age",

    # check_fit(): the plots of its result
    check_residuals = "Conditional residuals of the survey index",
    check_lag       = "Correlation of residuals between time steps",
    check_qq        = "Normal quantile-quantile plot of the conditional residuals",

    # Comparison plot titles; {m1} and {m2} are the model names
    compare_ts      = "Time series of {m1} and {m2}",
    compare_F       = "Fishing mortality rate of {m1} and {m2}",
    compare_resid   = "Residuals of {m1} and {m2}",
    compare_growth  = "Mean length at age of {m1} and {m2}",
    compare_CatL    = "Fits of {m1} and {m2} to the survey indices at length",
    compare_metrics = "Fit statistics of {m1} and {m2}",
    compare_sel     = "Survey catchability at length of {m1} and {m2}",
    compare_F_ts    = "Fishing mortality rate of {m1} and {m2} over time"
  ),

  # --- Axis labels ---------------------------------------------------------
  # Ages are in years because the fitted time step is in years. The package
  # holds no unit metadata for length, weight or the survey index, so those
  # labels carry no unit; set them with acl_theme_set(xlab = , ylab = ).
  xlab = list(
    year   = "Year",
    age    = "Age (years)",
    length = "Length",
    ssb    = "Spawning stock biomass (SSB)"
  ),

  ylab = list(
    year      = "Year",
    abundance = "Abundance",
    biomass   = "Biomass",
    ssb       = "Spawning stock biomass (SSB)",
    rec       = "Recruitment",
    catch     = "Catch in numbers",
    survey    = NULL, # NULL preserves legacy custom abundance labels for survey plots.
    # The time basis, such as "(per year)", is appended from the fit.
    F         = "Fishing mortality rate",
    dev_R     = "Log recruitment deviation",
    dev_F     = "Log fishing mortality deviation",
    dev_R_multiplier = "Recruitment multiplier",
    dev_F_multiplier = "Fishing mortality multiplier",
    residual  = "Log residual",
    growth    = "Mean length",
    length    = "Length",
    # The time basis, such as "(per year)", is appended from the fit.
    M         = "Natural mortality rate",
    survey_q  = "Survey catchability (q)",
    survey_q_age = "Survey catchability multiplier",
    relative_catch_number = "Catch in numbers divided by its mean",
    relative_catch_weight = "Catch in weight divided by its mean",
    relative_error = "Relative error (%)"
  )
)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Get the current ALSCL plot theme
#'
#' Returns the current global theme settings used by all ALSCL plot functions.
#'
#' @param what Optional character. Retrieve a specific element, e.g.
#'   \code{"titles"}, \code{"font_family"}, \code{"compare_colors"}.
#'   Letter case does not matter.
#' @return A list of current settings, or a single element if \code{what}
#'   is specified.
#' @family acl_theme
#' @export
#' @examples
#' acl_theme()
#' acl_theme("font_family")
#' acl_theme("compare_colors")
#' acl_theme("style")
acl_theme <- function(what = NULL) {
  # Snapshots retain every setting, including nested nullable label defaults.
  current <- utils::modifyList(.acl_defaults, getOption("acl.theme", list()), keep.null = TRUE)
  if (is.null(what)) return(current)
  # Setting names in any letter case.
  if (is.character(what) && length(what) == 1L && !what %in% names(current))
    what <- .acl_canonical(what, names(current))
  if (identical(what, "compare_linewidth")) {
    .acl_deprecated_message("theme.compare_linewidth",
      "Theme setting 'compare_linewidth' is deprecated and will be removed; use 'compare_line_size' instead.")
    what <- "compare_line_size"
  }
  current[[what]]
}


#' Set ALSCL plot theme options
#'
#' Modify one or more global theme settings. Partial updates are supported:
#' only the fields you specify will be changed; all others keep their
#' current values.
#'
#' @param base_theme Character. Base ggplot2 theme name: "bw", "minimal",
#'   "classic", "gray", "grey", "light", "linedraw", "dark" or "void", with or
#'   without the "theme_" prefix. Any other value is an error.
#'   Letter case does not matter.
#' @param font_family Character. Font family for all text.
#' @param title_size Numeric. Plot title size in pt.
#' @param title_hjust Numeric. Title alignment (0=left, 0.5=center, 1=right).
#'   Set by the style: 0 under "default", 0.5 under "classic".
#' @param axis_title_size Numeric. Axis title size.
#' @param axis_text_size Numeric. Axis tick label size.
#' @param strip_text_size Numeric. Facet label size.
#' @param legend_text_size Numeric. Legend text size.
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks. One setting
#'   serves time, age and length axes. A plot uses it only when at least one
#'   break lies within the range of its x axis; otherwise that plot chooses its
#'   breaks automatically. Calendar-year breaks therefore do not blank age or
#'   length axes. Pass NULL explicitly to restore automatically selected breaks;
#'   omitting the argument leaves the current setting unchanged.
#' @param x_expand Numeric vector of length 2. X-axis expansion.
#' @param line_color Character. Default line color for single-model plots.
#' @param line_size Numeric. Default line width for single-model plots: 1
#'   under the default style, 1.5 under "classic".
#'   Plot arguments set to NULL inherit this value; explicit widths take priority.
#'   While it keeps the value of the style, facets of 5 to 12 panels draw their
#'   lines at two thirds of it and facets of more panels at half of it; another
#'   value set here is used as given. The same holds for compare_line_size.
#' @param point_size Numeric. Default point size for all point plots (2.5).
#'   Plot arguments set to NULL inherit this value unless a comparison-specific
#'   override is set. Explicit per-call sizes take priority.
#' @param se_color Character. Default CI color.
#' @param se_alpha Numeric. Default transparency of interval ribbons (0.3
#'   under the default style, 0.2 under "classic").
#'   Plot arguments set to NULL inherit this value; explicit alpha takes priority.
#'   Error bars are drawn opaque unless a plot call supplies se_alpha.
#' @param interval Character. Default 95% interval for positive quantities
#'   (abundance, biomass, spawning stock biomass, recruitment, catch and
#'   fishing mortality): \code{"lognormal"} (default) or \code{"wald"}. See
#'   \code{\link{plot_abundance}} for the formulas.
#'   Letter case does not matter.
#' @param compare_colors Character vector of 2 colors. Can be unnamed (positional)
#'   or named. The first color is always model1, second is model2. A vector
#'   with fewer than two colors is an error.
#'   Examples: \code{c("blue", "red")}, \code{c(ACL = "blue", ALSCL = "red")},
#'   \code{c("M=0" = "steelblue", "M=0.5" = "tomato")}.
#' @param compare_linetypes Character vector of 2 linetypes. Same rules as colors.
#' @param compare_line_size Numeric. Line width for comparison plots: 0.9
#'   under the default style, 1.2 under "classic".
#' @param compare_point_size Numeric or NULL. Optional point-size override for
#'   comparison plots. The default NULL inherits point_size. Existing explicit
#'   values remain supported; a plot's point_size argument takes priority.
#'   Pass NULL explicitly to clear a comparison-specific override.
#' @param compare_se_alpha Numeric. CI ribbon alpha for comparison plots
#'   (0.25 under the default style, 0.15 under "classic").
#' @param compare_legend_pos Character. Legend position for comparison plots.
#'   Letter case does not matter.
#' @param compare_facet_ncol Integer or NULL. Facet columns of comparison
#'   plots. NULL (default) chooses the columns from the number of panels, as
#'   the single-model plots do; pass NULL explicitly to restore it.
#' @param compare_facet_scales Character. Facet scales for comparison plots.
#'   Letter case does not matter.
#' @param palette Character or NULL. Categorical palette: "default", the
#'   colors of the default style (dark blue, orange, teal, yellow, light
#'   blue, green, sky blue, dark green), or the ggsci palettes "npg",
#'   "aaas", "nejm", "lancet" and "jama". Changing it resets palette-derived colors
#'   (line, interval, point, observation, smoother, comparison and heat map colors);
#'   explicit color arguments in the same call take precedence. No arguments
#'   leaves settings unchanged; use acl_theme_reset() to reset.
#'   Letter case does not matter.
#' @param point_color,observed_color,smooth_color,hline_color Character or NULL.
#'   Default point, observation, smoother and reference-line colors.
#' @param low_col,high_col Character or NULL. Colors at the low and high ends
#'   of heat maps.
#' @param titles Named list. Override specific titles. The keys are listed in
#'   \code{acl_theme("titles")}; the former keys CatL_year, CatL_year_dist and
#'   compare_annualF are accepted with a warning.
#' @param xlab Named list. Override specific x-axis labels.
#' @param ylab Named list. Override specific y-axis labels. The default
#'   fishing mortality label gains the time basis of the fit, for example
#'   "(per year)" or "(per quarter)"; a customized \code{F} label is used verbatim.
#'   The survey key
#'   labels survey indices independently of catch abundance; when unset,
#'   survey plots retain a legacy customized abundance label or use Survey index.
#'   Set a named label to NULL to restore its default, for example
#'   \code{ylab = list(survey = NULL)}.
#' @param style Character or NULL. A preset of the colors and forms of all
#'   plots. \code{"default"}, used when no style is set, draws stock size,
#'   fishing mortality, recruitment and catch each in its own color, draws
#'   total recruitment and total catch as bars, starts the y axis of these plots at zero, puts the
#'   legend below the plot, and uses bold left-aligned titles, plain facet
#'   labels and a black panel border, without grid lines.
#'   \code{"classic"} restores the colors and forms of ALSCL 2.4.5 (the npg
#'   palette, centered plain titles, lines for every series, y axes not forced
#'   to zero and grey boxed facet labels, without grid lines). Under both
#'   styles the default texts in the figures, the number of facet columns and
#'   the tick labels follow the rules of version 2.5.0. Setting a style
#'   replaces palette, grid, title_face, title_hjust, title_color, the four
#'   quantity colors (stock_color, F_color, recruitment_color, catch_color),
#'   bars, y_zero, se_alpha, compare_se_alpha, strip, legend_position,
#'   axis_color, line_size, compare_line_size and the palette-derived colors
#'   with the values of the
#'   preset. Other arguments of the same call are applied after the preset
#'   and win. Setting a single key changes only that key, so styles can be
#'   mixed. The name "standard", which ALSCL 2.5.0 used for the default style
#'   and its palette, is still accepted with a warning.
#'   Letter case does not matter.
#' @param grid Character or NULL. Grid lines: \code{"none"} (no grid lines,
#'   the default of both styles) or \code{"y"} (horizontal major lines only,
#'   in light grey). Heat maps never show grid lines.
#'   Letter case does not matter.
#' @param title_face Character or NULL. Face of plot titles: "bold" ("default"),
#'   "plain" ("classic"), "italic" or "bold.italic".
#'   Letter case does not matter.
#' @param title_color Character or NULL. Color of plot titles: "black" in
#'   both styles. \code{"quantity"} gives the title the theme color of the
#'   quantity that the plot shows (stock size, fishing mortality, recruitment or
#'   catch) and black for other plots, darkened where needed for a contrast
#'   ratio of at least 4.5 to 1 with white so that the title reads well (lines
#'   and bars keep the exact color); any other color name or code is used as
#'   given.
#'   Letter case does not matter.
#' @param show_title Logical or NULL. Draw the default titles of the plots
#'   (TRUE, the default of both styles). FALSE removes them from every plot;
#'   a title given as a character string in a plot call is still drawn, and
#'   the titles of the panels of multi-panel figures stay because they name
#'   the panels. A key of \code{titles} set to \code{""} or \code{NA} removes
#'   the title of that plot only.
#' @param x_angle Numeric or NULL. Angle in degrees of the tick labels of
#'   time axes in multi-panel figures. NULL (default) draws them horizontal
#'   when they fit the width of the panels with a clear gap and at 45 degrees
#'   when they do not; 0 keeps them horizontal and thins them instead; another
#'   number uses that angle. Single-panel figures keep horizontal labels
#'   unless a number other than 0 is set. A \code{axis.text.x} element added
#'   with \code{+ ggplot2::theme()} wins.
#' @param stock_color,F_color,recruitment_color,catch_color Character or NULL.
#'   Line or bar colors of stock size (plot_SSB(), plot_biomass(),
#'   plot_abundance()), fishing mortality (plot_fishing_mortality(), the F
#'   deviations of plot_deviance()), recruitment (plot_recruitment(), the
#'   recruitment deviations of plot_deviance()) and catch (plot_catch(), the
#'   fitted series of plot_relative_catch()). The default style uses
#'   "#047c6c", "#ed5f26", "#28b3e8" and "#002b5f"; NULL ("classic") uses
#'   line_color. Interval bands of these plots take the color of their line
#'   unless se_color is set to a color other than the band color of the
#'   palette. Pass NULL explicitly to clear a color.
#' @param bars Logical or NULL. Draw total recruitment and total catch as
#'   bars (TRUE, "default") or lines (FALSE, "classic"). The geom argument of
#'   plot_recruitment() and plot_catch() chooses per call.
#' @param y_zero Logical or NULL. Start the y axis of stock size,
#'   recruitment, catch and fishing mortality plots, and of
#'   plot_compare_ts() and plot_compare_F_ts(), at zero with no gap below it
#'   (TRUE, "default"), or let it follow the data (FALSE, "classic").
#' @param strip Character or NULL. Facet strips: \code{"plain"} (bold, left
#'   aligned black text without a box, "default") or \code{"box"} (the strips of
#'   the base theme, "classic").
#'   Letter case does not matter.
#' @param legend_position Character or NULL. Position of the legend of
#'   plots that have one: "bottom" ("default"), "top", "left", "right" or "none".
#'   NULL ("classic") keeps the position of each plot. Comparison plots use
#'   compare_legend_pos.
#'   Letter case does not matter.
#' @param axis_color Character or NULL. With the default base theme
#'   ("theme_bw"), the color of the panel border, axis text and ticks, on a
#'   white panel ("black" under "default"). NULL ("classic") keeps the base theme.
#' @param ... The former argument name compare_linewidth, accepted with a warning.
#' @return Invisible previous settings. Save these or the result of acl_theme(),
#'   then restore them with \code{do.call(acl_theme_set, old)}.
#' @section Plots combined in a figure of your own:
#'   A single-panel plot such as \code{plot_SSB()} chooses its year labels for
#'   a figure of its own, and the package cannot know the width it gets when
#'   you place it next to other plots, for example in a patchwork of three
#'   columns, where the labels may touch. Before making the plots, set
#'   \code{acl_theme_set(x_angle = 45)} to slant the labels, or set fewer
#'   labels with \code{x_breaks}, for example
#'   \code{acl_theme_set(x_breaks = seq(2000, 2020, by = 5))}.
#'   \code{x_breaks} is also an argument of the plot functions, and
#'   \code{x_angle} an argument of \code{theme_acl()}.
#' @family acl_theme
#' @export
#' @examples
#' # --- Set just one thing ---
#' # The first call returns the previous settings, which are restored at the end.
#' old <- acl_theme_set(base_theme = "theme_classic")
#' acl_theme_set(font_family = "Times New Roman")
#' acl_theme_set(compare_line_size = 2)
#'
#' # --- The colors and forms of ALSCL 2.4.5 ---
#' acl_theme_set(style = "classic")
#' acl_theme("style")
#'
#' # --- The default style with another palette and horizontal grid lines ---
#' acl_theme_set(style = "default", palette = "npg")
#' acl_theme_set(grid = "y")
#'
#' # --- No default titles; a title given in a plot call is still drawn ---
#' acl_theme_set(show_title = FALSE)
#'
#' # --- Slanted year labels for plots placed side by side ---
#' acl_theme_set(x_angle = 45)
#'
#' # --- Compare ACL vs ALSCL (default) ---
#' acl_theme_set(
#'   compare_colors = c("steelblue", "tomato"),
#'   compare_linetypes = c("solid", "longdash")
#' )
#'
#' # --- Compare same model, different parameters ---
#' acl_theme_set(
#'   compare_colors    = c("M=0" = "#2166AC", "M=0.3" = "#B2182B"),
#'   compare_linetypes = c("M=0" = "solid",   "M=0.3" = "dotted")
#' )
#' # plot_compare_ts(result_M0, result_M03,
#' #   model1_name = "M=0", model2_name = "M=0.3")
#'
#' # --- Or just override per-call, no global setting needed ---
#' # plot_compare_ts(result1, result2,
#' #   model1_name = "Run A", model2_name = "Run B",
#' #   colors = c("darkgreen", "purple"))
#'
#' # --- Restore the previous settings ---
#' do.call(acl_theme_set, old)
acl_theme_set <- function(base_theme = NULL, font_family = NULL, title_size = NULL,
                          title_hjust = NULL,
                          axis_title_size = NULL, axis_text_size = NULL,
                          strip_text_size = NULL, legend_text_size = NULL,
                          x_breaks = NULL, x_expand = NULL,
                          line_color = NULL, line_size = NULL, point_size = NULL,
                          se_color = NULL, se_alpha = NULL,
                          compare_colors = NULL, compare_linetypes = NULL,
                          compare_line_size = NULL, compare_point_size = NULL,
                          compare_se_alpha = NULL, compare_legend_pos = NULL,
                          compare_facet_ncol = NULL, compare_facet_scales = NULL,
                          titles = NULL, xlab = NULL, ylab = NULL,
                          palette = NULL, point_color = NULL, observed_color = NULL,
                          smooth_color = NULL, hline_color = NULL,
                          low_col = NULL, high_col = NULL,
                          style = NULL, grid = NULL, title_face = NULL, title_color = NULL,
                          stock_color = NULL, F_color = NULL, recruitment_color = NULL,
                          catch_color = NULL, bars = NULL, y_zero = NULL, strip = NULL,
                          legend_position = NULL, axis_color = NULL,
                          ..., interval = NULL, show_title = NULL, x_angle = NULL) {

  current <- acl_theme()
  old <- current
  renamed <- .acl_renamed(list(...), "acl_theme_set")
  if (is.null(compare_line_size)) compare_line_size <- renamed$compare_line_size
  if (!is.null(titles)) titles <- .acl_renamed_titles(titles)

  # Reject settings that no plot could use, before any of them is stored.
  # Choices are matched in any letter case and stored as the package
  # names them.
  if (!is.null(style))
    style <- .acl_match_choice(.acl_former_default(style, "style"), names(.acl_style_presets), "style")
  if (!is.null(palette)) palette <- .acl_palette_name(palette)
  if (!is.null(grid)) grid <- .acl_match_choice(grid, c("none", "y"), "grid")
  if (!is.null(title_face))
    title_face <- .acl_match_choice(title_face, c("plain", "bold", "italic", "bold.italic"), "title_face")
  if (!is.null(strip)) strip <- .acl_match_choice(strip, c("plain", "box"), "strip")
  if (!is.null(legend_position))
    legend_position <- .acl_match_choice(legend_position, .acl_legend_positions[1:5], "legend_position")
  if (!is.null(compare_legend_pos))
    compare_legend_pos <- .acl_match_choice(compare_legend_pos, .acl_legend_positions[1:5], "compare_legend_pos")
  if (!is.null(compare_facet_scales))
    compare_facet_scales <- .acl_facet_scales(compare_facet_scales, "compare_facet_scales")
  if (!is.null(base_theme)) {
    # Stored with or without the prefix, as given.
    full <- .acl_theme_name(base_theme, "base_theme")
    base_theme <- if (startsWith(tolower(base_theme), "theme_")) full else sub("^theme_", "", full)
  }
  title_color <- .acl_canonical(title_color, "quantity")
  if (!is.null(title_color) && !identical(title_color, "quantity"))
    .acl_check_color(title_color, "title_color", "or \"quantity\"")
  for (key in c("stock_color", "F_color", "recruitment_color", "catch_color", "axis_color"))
    if (!is.null(get(key))) .acl_check_color(get(key), key)
  if (!missing(x_angle)) .acl_check_x_angle(x_angle)
  if (!missing(compare_facet_ncol) && !is.null(compare_facet_ncol) &&
      (!is.numeric(compare_facet_ncol) || length(compare_facet_ncol) != 1L ||
       !is.finite(compare_facet_ncol) || compare_facet_ncol < 1 ||
       compare_facet_ncol != round(compare_facet_ncol)))
    stop("compare_facet_ncol must be NULL or one whole number of 1 or more, for example 2.", call. = FALSE)
  # Sizes, transparencies, axis settings, colors, line types and label lists.
  if (!is.null(font_family) && (!is.character(font_family) || length(font_family) != 1L ||
                                is.na(font_family) || !nzchar(font_family)))
    stop("font_family must be one font family name, for example \"sans\" or \"serif\".", call. = FALSE)
  for (key in c("title_size", "axis_title_size", "axis_text_size", "strip_text_size", "legend_text_size",
                "line_size", "point_size", "compare_line_size", "compare_point_size"))
    .acl_check_size(get(key), key)
  for (key in c("se_alpha", "compare_se_alpha")) {
    value <- get(key)
    if (!is.null(value) && (!is.numeric(value) || length(value) != 1L || !is.finite(value) || value < 0 || value > 1))
      stop(key, " must be one number from 0 (transparent) to 1 (opaque), for example 0.3.", call. = FALSE)
  }
  if (!is.null(title_hjust) && (!is.numeric(title_hjust) || length(title_hjust) != 1L ||
                                !is.finite(title_hjust) || title_hjust < 0 || title_hjust > 1))
    stop("title_hjust must be one number from 0 (left) to 1 (right), for example 0.5 for a centered title.",
         call. = FALSE)
  if (!is.null(x_expand) && (!is.numeric(x_expand) || length(x_expand) != 2L ||
                             any(!is.finite(x_expand)) || any(x_expand < 0)))
    stop("x_expand must be two numbers of zero or more, the share of the axis range added at each end, ",
         "for example c(0.01, 0.01).", call. = FALSE)
  if (!is.null(x_breaks) && (!is.numeric(x_breaks) || !length(x_breaks) || any(!is.finite(x_breaks))))
    stop("x_breaks must be NULL or a vector of finite numbers, for example seq(2000, 2020, by = 5).",
         call. = FALSE)
  for (key in c("line_color", "se_color", "point_color", "observed_color", "smooth_color", "hline_color",
                "low_col", "high_col"))
    if (!is.null(get(key))) .acl_check_color(get(key), key)
  if (!is.null(compare_colors)) {
    bad <- compare_colors[!vapply(compare_colors, .acl_is_color, logical(1))]
    if (length(bad))
      stop("compare_colors must hold color names or codes, for example c(\"steelblue\", \"tomato\"); ",
           "not colors: ", paste0("\"", bad, "\"", collapse = ", "), ".", call. = FALSE)
  }
  if (!is.null(compare_linetypes)) {
    bad <- compare_linetypes[!vapply(compare_linetypes, .acl_is_linetype, logical(1))]
    if (length(bad))
      stop("compare_linetypes must hold line types: \"solid\", \"dashed\", \"dotted\", \"dotdash\", ",
           "\"longdash\", \"twodash\", \"blank\" or a string of 2, 4, 6 or 8 hexadecimal digits such as ",
           "\"44\"; not line types: ", paste0("\"", bad, "\"", collapse = ", "), ".", call. = FALSE)
  }
  for (key in c("titles", "xlab", "ylab")) .acl_check_label_list(get(key), key)
  for (key in c("bars", "y_zero", "show_title")) {
    value <- get(key)
    if (!is.null(value) && (!is.logical(value) || length(value) != 1L || is.na(value)))
      stop(key, " must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.null(interval)) interval <- .acl_interval_type(interval)
  for (key in c("compare_colors", "compare_linetypes")) {
    value <- get(key)
    if (!is.null(value) && length(value) < 2L)
      stop(key, " must contain two values, one per model; it has ", length(value),
           ". Supply both, for example c(\"", if (key == "compare_colors")
             "steelblue\", \"tomato" else "solid\", \"dashed", "\").", call. = FALSE)
  }

  # A style first, then a palette, then the single keys of this call.
  if (!is.null(style))
    current <- utils::modifyList(current, .acl_style_presets[[style]], keep.null = TRUE)
  if (!is.null(palette))
    current <- utils::modifyList(current, .acl_palette_roles(palette))
  for (key in c("point_color", "observed_color", "smooth_color", "hline_color", "low_col", "high_col",
                "grid", "title_face", "title_color", "bars", "y_zero", "strip", "show_title")) {
    value <- get(key)
    if (!is.null(value)) current[[key]] <- value
  }
  # Keys whose NULL value means something: an explicit NULL clears them.
  for (key in c("stock_color", "F_color", "recruitment_color", "catch_color",
                "legend_position", "axis_color", "x_angle", "compare_facet_ncol"))
    if (!eval(call("missing", as.name(key)))) current[key] <- list(get(key))

  if (!is.null(base_theme))           current$base_theme           <- base_theme
  if (!is.null(interval))             current$interval             <- interval
  if (!is.null(font_family))          current$font_family          <- font_family
  if (!is.null(title_size))           current$title_size           <- title_size
  if (!is.null(title_hjust))          current$title_hjust          <- title_hjust
  if (!is.null(axis_title_size))      current$axis_title_size      <- axis_title_size
  if (!is.null(axis_text_size))       current$axis_text_size       <- axis_text_size
  if (!is.null(strip_text_size))      current$strip_text_size      <- strip_text_size
  if (!is.null(legend_text_size))     current$legend_text_size     <- legend_text_size
  if (!missing(x_breaks))            current["x_breaks"]           <- list(x_breaks)
  if (!is.null(x_expand))            current$x_expand             <- x_expand
  if (!is.null(line_color))           current$line_color           <- line_color
  if (!is.null(line_size))            current$line_size            <- line_size
  if (!is.null(point_size))           current$point_size           <- point_size
  if (!is.null(se_color))             current$se_color             <- se_color
  if (!is.null(se_alpha))             current$se_alpha             <- se_alpha
  if (!is.null(compare_colors))       current$compare_colors       <- compare_colors
  if (!is.null(compare_linetypes))    current$compare_linetypes    <- compare_linetypes
  if (!is.null(compare_line_size))    current$compare_line_size    <- compare_line_size
  if (!missing(compare_point_size))  current["compare_point_size"] <- list(compare_point_size)
  if (!is.null(compare_se_alpha))     current$compare_se_alpha     <- compare_se_alpha
  if (!is.null(compare_legend_pos))   current$compare_legend_pos   <- compare_legend_pos
  if (!is.null(compare_facet_scales)) current$compare_facet_scales <- compare_facet_scales
  if (!is.null(titles))               current$titles               <- modifyList(current$titles, titles)
  if (!is.null(xlab))                 current$xlab                 <- modifyList(current$xlab, xlab)
  if (!is.null(ylab))                 current$ylab                 <- modifyList(current$ylab, ylab)

  options(acl.theme = current)
  invisible(old)
}



#' Reset the ALSCL plot theme to its defaults
#'
#' Restores every theme setting to the package default, the default style
#' (\code{style = "default"}), and reports this with a message, which \code{suppressMessages()}
#' silences. Use \code{acl_theme_set(style = "classic")} for the colors and
#' forms of ALSCL 2.4.5.
#'
#' @return \code{NULL}, invisibly.
#' @family acl_theme
#' @export
#' @examples
#' old <- acl_theme_set(style = "classic")
#' acl_theme_reset()
#' acl_theme("style")
#'
#' # Restore the settings in use before this example
#' do.call(acl_theme_set, old)
acl_theme_reset <- function() {
  options(acl.theme = .acl_defaults)
  message("ALSCL plot theme reset to defaults.")
  invisible(NULL)
}


#' Theme of the ALSCL plots for your own ggplots
#'
#' Returns the theme layers that the ALSCL plot functions add, under the
#' current \code{\link{acl_theme_set}()} settings: the base theme, font and
#' text sizes, grid lines, title, facet strips and legend position of the
#' active style. Add it to any ggplot to give a figure of your own the look
#' of the package plots. It follows later calls to \code{acl_theme_set()}
#' when it is called again.
#'
#' @param font_family,title_size,axis_title_size,axis_text_size,strip_text_size,legend_text_size
#'   Character or numeric, or NULL for the global setting, as in the plot
#'   functions.
#' @param base_theme Character or NULL. Base ggplot2 theme name; NULL uses
#'   the global setting.
#'   Letter case does not matter.
#' @param title_hjust Numeric or NULL. Title alignment; NULL uses the global
#'   setting.
#' @param quantity Character or NULL. With \code{title_color = "quantity"}, the
#'   title takes the color of this quantity: "stock" (stock size), "F"
#'   (fishing mortality), "recruitment" or "catch". NULL gives a black title.
#'   Letter case does not matter, so \code{"f"} gives the same as \code{"F"}.
#' @param x_angle Numeric or NULL. Angle in degrees of the x tick labels,
#'   from -90 to 90; slanted labels end at their tick mark. NULL uses the
#'   global x_angle setting and leaves the labels of the base theme when that
#'   is NULL too.
#' @return A list of ggplot2 theme layers, to be added to a ggplot with \code{+}.
#' @family acl_theme
#' @export
#' @examples
#' d <- data.frame(year = 2001:2010, value = c(3, 5, 4, 6, 8, 7, 9, 8, 10, 11))
#' ggplot2::ggplot(d, ggplot2::aes(year, value)) +
#'   ggplot2::geom_line(color = acl_palette(role = "primary")) +
#'   ggplot2::labs(title = "My series") +
#'   theme_acl()
theme_acl <- function(font_family = NULL, title_size = NULL, axis_title_size = NULL,
                      axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL,
                      base_theme = NULL, title_hjust = NULL, quantity = NULL, x_angle = NULL) {
  if (!is.null(quantity)) quantity <- .acl_match_choice(quantity, names(.acl_role_keys)[1:4], "quantity")
  .acl_check_x_angle(x_angle)
  layers <- .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size, strip_text_size,
                            legend_text_size, base_theme = base_theme, title_hjust = title_hjust,
                            quantity = quantity)
  angle <- x_angle %||% acl_theme("x_angle")
  if (!is.null(angle)) layers <- c(layers, list(.acl_x_angle_theme(angle)))
  layers
}

# Theme keys of the color roles of acl_palette().
.acl_role_keys <- c(stock = "stock_color", F = "F_color", recruitment = "recruitment_color",
                    catch = "catch_color", primary = "line_color", accent = "observed_color",
                    smooth = "smooth_color", reference = "hline_color")

#' Colors of the ALSCL plots
#'
#' Returns the categorical colors of the active palette, or of a named one,
#' or the colors that the plots use for each role, so that figures of your
#' own match the package plots.
#'
#' @param n Integer or NULL. Number of colors. NULL returns the native
#'   colors of the palette; more colors than the palette holds are
#'   interpolated between its colors.
#' @param palette Character or NULL. "default", "npg", "aaas", "nejm",
#'   "lancet" or "jama"; NULL uses the palette set with
#'   \code{\link{acl_theme_set}()}.
#'   Letter case does not matter.
#' @param role Character vector or NULL. Names of color roles: "stock",
#'   "F", "recruitment", "catch" (stock size, fishing mortality,
#'   recruitment and catch), "primary" (lines
#'   and points), "accent" (observations), "smooth" (smoothers) and
#'   "reference" (reference lines). With \code{palette = NULL} the colors
#'   are those of the current settings; a quantity without its own color
#'   uses the primary color. With a palette name they are the defaults of
#'   that palette. \code{n} is ignored.
#'   Letter case does not matter, so \code{"f"} gives the same as \code{"F"}.
#' @return A character vector of colors, named by role when \code{role} is
#'   given.
#' @family acl_theme
#' @export
#' @examples
#' acl_palette()
#' acl_palette(3)
#' acl_palette(12, palette = "npg")
#' acl_palette(role = c("stock", "F", "recruitment", "catch", "primary", "accent"))
acl_palette <- function(n = NULL, palette = NULL, role = NULL) {
  if (!is.null(palette)) palette <- .acl_palette_name(palette)
  if (!is.null(role)) {
    role <- .acl_canonical(role, names(.acl_role_keys))
    if (!is.character(role) || !length(role) || anyNA(role) || !all(role %in% names(.acl_role_keys)))
      stop("role must name color roles out of ", paste0("\"", names(.acl_role_keys), "\"", collapse = ", "),
           ", in any letter case.", call. = FALSE)
    settings <- if (is.null(palette)) acl_theme() else {
      roles <- .acl_palette_roles(palette)
      quantities <- if (palette == "default") .acl_default_colors[c("stock", "F", "recruitment", "catch")] else
        list(NULL, NULL, NULL, NULL)
      c(roles, stats::setNames(quantities, .acl_role_keys[1:4]))
    }
    colors <- vapply(role, function(r)
      settings[[.acl_role_keys[[r]]]] %||% settings$line_color, character(1))
    return(stats::setNames(colors, role))
  }
  if (!is.null(n) && (!is.numeric(n) || length(n) != 1L || !is.finite(n) || n < 1 || n != round(n)))
    stop("n must be a positive whole number or NULL.", call. = FALSE)
  .acl_palette(palette %||% acl_theme("palette") %||% "default", n)
}


# ---------------------------------------------------------------------------
# Internal helpers (used by plot functions)
# ---------------------------------------------------------------------------

#' Get a title from the theme, with model name substitution
#' @param key Character. Title key.
#' @param m1 Optional model 1 name for substitution.
#' @param m2 Optional model 2 name for substitution.
#' @return Character string.
#' @keywords internal
.acl_title <- function(key, m1 = NULL, m2 = NULL) {
  result <- acl_theme("titles")[[key]]
  if (is.null(result)) return(key)
  if (!is.null(m1)) result <- gsub("\\{m1\\}", m1, result)
  if (!is.null(m2)) result <- gsub("\\{m2\\}", m2, result)
  result
}

# Title drawn by a plot. `title` is the argument of the call: NULL draws the
# default title, FALSE, NA or "" draws none, and a character string (or a
# plotmath expression) is drawn verbatim. The default title is `default`, or
# the `key` of the titles setting with the model names put in; it is not
# drawn when show_title is FALSE or when the key is set to "" or NA.
.acl_plot_title <- function(title = NULL, key = NULL, m1 = NULL, m2 = NULL, default = NULL) {
  if (!is.null(title) && !isTRUE(title)) {
    if (isFALSE(title) || (length(title) == 1L && !is.language(title) && is.na(title)) ||
        identical(title, "")) return(NULL)
    if ((is.character(title) && length(title) >= 1L) || is.language(title) || is.expression(title))
      return(title)
    stop("title must be NULL, FALSE, NA or a character string.", call. = FALSE)
  }
  if (!isTRUE(acl_theme("show_title") %||% TRUE)) return(NULL)
  text <- default %||% (if (!is.null(key)) .acl_title(key, m1, m2))
  .acl_title_text(text)
}

# A title text, or NULL when it is empty or missing.
.acl_title_text <- function(text) {
  if (is.null(text) || !length(text) || (length(text) == 1L && is.na(text)) || identical(text, ""))
    return(NULL)
  text
}

#' @keywords internal
.acl_lab <- function(axis = "x", key) {
  labs <- if (axis == "x") acl_theme("xlab") else acl_theme("ylab")
  result <- labs[[key]]
  if (!is.null(result)) result else key
}

# Survey indices are distinct from fishery catch. Keep older custom abundance
# labels as a fallback, while an explicit survey label takes priority.
.acl_survey_label <- function(log = FALSE) {
  labels <- acl_theme("ylab")
  label <- labels$survey
  if (is.null(label) && !identical(labels$abundance, .acl_defaults$ylab$abundance))
    label <- labels$abundance
  if (is.null(label)) return(if (log) "Log survey index" else "Survey index")
  if (log) paste("Log", label) else label
}

# Names of the assessment quantities in panel strips and legends of every
# plot: one name per quantity, the same as on the axes and in the titles.
# Codes without a name are drawn as they are.
.acl_quantity_names <- c(SSB = "Spawning stock biomass (SSB)", Rec = "Recruitment",
                         B = "Total biomass", N = "Total abundance",
                         CN = "Catch in numbers", CB = "Catch in weight",
                         F = "Fishing mortality rate")

.acl_quantity_name <- function(code) {
  code <- as.character(code)
  out <- unname(.acl_quantity_names[code])
  out[is.na(out)] <- code[is.na(out)]
  out
}

# Names of the scalar parameters of ACL and ALSCL on the natural scale, as
# extract_parameters(scale = "natural") reports them, for figures and printed
# tables that show them. Rates are per model time step. exp(mean_log_R) and
# exp(mean_log_F) are the medians (geometric means) of the processes, not
# their means; the correlations and standard deviations are those of the
# log-scale deviations.
.acl_parameter_names <- c(
  log_init_Z = "Initial total mortality rate",
  mean_log_R = "Median recruitment",
  mean_log_F = "Median fishing mortality rate",
  log_std_log_R = "Standard deviation of log recruitment",
  log_sigma_log_R = "Standard deviation of log recruitment",
  log_std_log_F = "Standard deviation of log fishing mortality rate",
  log_sigma_log_F = "Standard deviation of log fishing mortality rate",
  log_std_log_N0 = "Standard deviation of log initial numbers at age",
  log_sigma_log_N0 = "Standard deviation of log initial numbers at age",
  log_std_index = "Standard deviation of the log survey index",
  log_sigma_index = "Standard deviation of the log survey index",
  logit_log_R = "Correlation of log recruitment between time steps",
  logit_log_F_y = "Correlation of log fishing mortality rate between time steps",
  logit_log_F_a = "Correlation of log fishing mortality rate between ages",
  logit_log_F_l = "Correlation of log fishing mortality rate between length bins",
  log_Linf = "Asymptotic length (Linf)",
  log_vbk = "Growth rate (k, per year)",
  t0 = "Age at length zero (t0)",
  log_t0 = "Age at length zero (t0)",
  log_cv_len = "Coefficient of variation of length at age",
  log_cv_grow = "Coefficient of variation of the growth increment")

# Display name of a scalar parameter; a name without one is drawn with
# spaces in place of underscores.
.acl_parameter_name <- function(name) {
  name <- as.character(name)
  out <- unname(.acl_parameter_names[name])
  out[is.na(out)] <- gsub("_", " ", name[is.na(out)], fixed = TRUE)
  out
}

#' Build the ALSCL ggplot theme layers
#'
#' `quantity` is the quantity of the plot ("stock", "F",
#' "recruitment" or "catch"), which gives the title its color under
#' `title_color = "quantity"`; NULL for other plots.
#' @keywords internal
.acl_base_theme <- function(font_family = NULL, title_size = NULL,
                            axis_title_size = NULL, axis_text_size = NULL,
                            strip_text_size = NULL, legend_text_size = NULL,
                            base_theme = NULL, title_hjust = NULL, quantity = NULL) {
  bt  <- if (!is.null(base_theme))        base_theme       else acl_theme("base_theme")
  ff  <- if (!is.null(font_family))       font_family      else acl_theme("font_family")
  ts  <- if (!is.null(title_size))        title_size       else acl_theme("title_size")
  th  <- if (!is.null(title_hjust))       title_hjust      else acl_theme("title_hjust")
  ats <- if (!is.null(axis_title_size))   axis_title_size  else acl_theme("axis_title_size")
  atx <- if (!is.null(axis_text_size))    axis_text_size   else acl_theme("axis_text_size")
  sts <- if (!is.null(strip_text_size))   strip_text_size  else acl_theme("strip_text_size")
  lts <- if (!is.null(legend_text_size))  legend_text_size else acl_theme("legend_text_size")

  # An unsupported name in the call falls back to the active global theme,
  # and an unsupported global value (set through options()) to theme_bw.
  # Both are reported instead of being replaced without notice.
  resolved <- .acl_theme_name(bt, "base_theme", error = FALSE)
  if (is.null(resolved)) {
    active <- if (is.null(base_theme)) NULL else
      .acl_theme_name(acl_theme("base_theme"), "base_theme", error = FALSE)
    fallback <- active %||% "theme_bw"
    warning("base_theme ", .acl_describe_value(bt), " is not a supported theme name; using \"",
            fallback, "\". Supported names: ",
            paste(sub("^theme_", "", .acl_theme_names), collapse = ", "), ".", call. = FALSE)
    resolved <- fallback
  }
  theme_fn <- getExportedValue("ggplot2", resolved)

  # The title, strip and panel rules of the style. Under the "classic"
  # style these add nothing, so the layers are those of ALSCL 2.4.5.
  title_args <- list(size = ts, hjust = th)
  face <- acl_theme("title_face") %||% "plain"
  if (!identical(face, "plain")) title_args$face <- face
  colour <- .acl_title_color(quantity)
  if (!is.null(colour)) title_args$colour <- colour
  plain_strip <- identical(acl_theme("strip"), "plain")
  strip_text <- if (plain_strip)
    ggplot2::element_text(size = sts, face = "bold", hjust = 0, colour = "black") else
    ggplot2::element_text(size = sts)
  axis_colour <- if (resolved == "theme_bw") acl_theme("axis_color")
  axis_text <- if (is.null(axis_colour)) ggplot2::element_text(size = atx) else
    ggplot2::element_text(size = atx, colour = axis_colour)

  style <- c(.acl_grid_elements(), list(
    text             = ggplot2::element_text(family = ff),
    plot.title       = do.call(ggplot2::element_text, title_args),
    axis.title       = ggplot2::element_text(size = ats),
    axis.text        = axis_text,
    strip.text       = strip_text,
    legend.text      = ggplot2::element_text(size = lts),
    legend.title     = ggplot2::element_text(size = lts)))
  # A plain strip label may run past its narrow panel into the free space
  # above the axis of the next panel instead of being cut.
  if (plain_strip) {
    style$strip.background <- ggplot2::element_blank()
    style$strip.clip <- "off"
  }
  if (!is.null(acl_theme("legend_position"))) style$legend.position <- acl_theme("legend_position")
  if (!is.null(axis_colour)) style <- c(style, list(
    panel.border = ggplot2::element_rect(fill = NA, colour = axis_colour, linewidth = 0.5),
    axis.ticks = ggplot2::element_line(colour = axis_colour),
    panel.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)))

  list(theme_fn(), do.call(ggplot2::theme, style))
}

# Grid elements of the current style: horizontal major lines only, or none.
# All plot families share them, including helpers that call acl_get_theme().
# Later user-supplied theme layers can restore other grid lines.
.acl_grid_elements <- function() {
  if (identical(acl_theme("grid"), "y"))
    list(panel.grid.major.x = ggplot2::element_blank(),
         panel.grid.major.y = ggplot2::element_line(colour = "grey80", linewidth = 0.4),
         panel.grid.minor = ggplot2::element_blank()) else
    list(panel.grid.major = ggplot2::element_blank(),
         panel.grid.minor = ggplot2::element_blank())
}

# Theme layer that removes every grid line, for heat maps and tiles. The
# children are named because a child set in the base layer, such as
# panel.grid.major.y, is not removed by a blank parent.
.acl_no_grid <- function() {
  blank <- ggplot2::element_blank()
  ggplot2::theme(panel.grid = blank, panel.grid.major = blank, panel.grid.minor = blank,
                 panel.grid.major.x = blank, panel.grid.major.y = blank,
                 panel.grid.minor.x = blank, panel.grid.minor.y = blank)
}

# Titles of the panels of a figure made of several plots. Under a title face
# other than plain they are `scale` times the title size and start at the
# left edge of the plot (`position = "plot"`), so that they fit half or a
# third of the figure width; "panel" keeps them clear of long axis titles. NULL under a plain face, which keeps the look of ALSCL 2.4.5.
.acl_panel_title_theme <- function(title_size = NULL, scale = 0.8, position = "plot") {
  if (identical(acl_theme("title_face") %||% "plain", "plain")) return(NULL)
  ggplot2::theme(plot.title = ggplot2::element_text(size = scale * (title_size %||% acl_theme("title_size"))),
                 plot.title.position = position)
}

# Title color: the theme color of the quantity family under "quantity"
# (black for other plots), or the color given. NULL means black, which the
# base themes already use.
.acl_title_color <- function(quantity = NULL) {
  setting <- acl_theme("title_color") %||% "black"
  colour <- if (identical(setting, "quantity"))
    (if (!is.null(quantity)) acl_theme(paste0(quantity, "_color"))) else setting
  if (is.null(colour) || identical(colour, "black")) return(NULL)
  # A quantity color is darkened as far as needed to read on white.
  if (identical(setting, "quantity")) .acl_readable_color(colour) else colour
}

# Line and interval colors of a plot of one quantity family ("stock", "F",
# "recruitment", "catch"). A color in the call wins; otherwise the theme
# color of the quantity, then line_color. The interval takes the color of
# its line, unless the global se_color was set to a color other than the
# band color of the active palette (.acl_band_color_set()); a global
# line_color therefore does not recolor the bands.
.acl_quantity_colors <- function(quantity = NULL, line_color = NULL, se_color = NULL) {
  theme_colour <- if (!is.null(quantity)) acl_theme(paste0(quantity, "_color"))
  line <- line_color %||% theme_colour %||% acl_theme("line_color")
  if (is.null(se_color)) se_color <- if (.acl_band_color_set()) acl_theme("se_color") else line
  list(line = line, se = se_color)
}

# TRUE when the global se_color differs from the band color of the active
# palette, that is, when it was set on its own.
.acl_band_color_set <- function() {
  band <- acl_theme("se_color")
  palette <- tryCatch(.acl_palette_name(acl_theme("palette") %||% "default"), error = function(e) "default")
  !is.null(band) && !identical(band, .acl_palette_roles(palette)$se_color)
}

# A y axis that includes zero without a gap below it, when y_zero is TRUE.
# The limits are a function, so that each panel of a facet with free scales
# includes zero, and the plot keeps its layers.
.acl_y_zero <- function(enabled = isTRUE(acl_theme("y_zero"))) {
  if (!enabled) return(NULL)
  ggplot2::scale_y_continuous(
    limits = function(range) if (length(range) == 2L && all(is.finite(range)))
      c(min(0, range[1L]), max(0, range[2L])) else range,
    expand = ggplot2::expansion(mult = c(0, 0.1)))
}

# Form of a total recruitment or catch series: "bar" or "line". NULL takes
# the bars setting of the theme.
.acl_geom_form <- function(geom = NULL) {
  if (is.null(geom)) return(if (isTRUE(acl_theme("bars"))) "bar" else "line")
  .acl_match_choice(geom, c("bar", "line"), "geom")
}

# Bars of a time series: 0.8 of the time step wide, so quarterly series work.
# Interval bars on them are thin and dark, with caps a third of the bar
# width for any number of bars and any time step (.acl_errorbar_layers()).
# `x` and `y` name the columns; `times` are the time steps of the series.
.acl_bar_width <- 0.8
.acl_bar_layers <- function(x, y, fill, times, se = FALSE, se_color = NULL, se_alpha = 1) {
  times <- sort(unique(as.numeric(times)))
  step <- if (length(times) > 1L) min(diff(times)) else 1
  layers <- list(ggplot2::geom_col(ggplot2::aes(x = !!as.name(x), y = !!as.name(y)),
                                   fill = fill, width = .acl_bar_width * step))
  if (se) layers <- c(layers, .acl_errorbar_layers(
    ggplot2::aes(x = !!as.name(x), ymin = lower, ymax = upper),
    colour = se_color %||% "grey20", alpha = se_alpha, width = .acl_bar_width * step / 3))
  layers
}

# Error bars that can be seen on any fill: a white error bar with a wider
# line is drawn under the dark one, so that the part inside a dark bar has a
# light outline and the part on a white panel looks as before. `width` is
# the cap width in data units.
.acl_errorbar_layers <- function(mapping, colour = "grey20", alpha = 1, linewidth = 0.4,
                                 width = 0.3, ...) {
  list(ggplot2::geom_errorbar(mapping, colour = "white", alpha = alpha, linewidth = linewidth + 0.6,
                              width = width, ...),
       ggplot2::geom_errorbar(mapping, colour = colour, alpha = alpha, linewidth = linewidth,
                              width = width, ...))
}

# An angle of tick labels: NULL or one number of degrees from -90 to 90.
# acl_theme_set() and theme_acl() share this check.
.acl_check_x_angle <- function(x_angle) {
  if (!is.null(x_angle) &&
      (!is.numeric(x_angle) || length(x_angle) != 1L || !is.finite(x_angle) || abs(x_angle) > 90))
    stop("x_angle must be NULL or one number of degrees between -90 and 90.", call. = FALSE)
  invisible(x_angle)
}

# TRUE for one color name or code that R can draw.
.acl_is_color <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x) &&
    !inherits(try(grDevices::col2rgb(x), silent = TRUE), "try-error")
}

# TRUE for one line type that ggplot2 and grid can draw.
.acl_is_linetype <- function(x) {
  if (is.numeric(x)) return(length(x) == 1L && is.finite(x) && x == round(x) && x >= 0 && x <= 6)
  is.character(x) && length(x) == 1L && !is.na(x) &&
    (x %in% c("blank", "solid", "dashed", "dotted", "dotdash", "longdash", "twodash") ||
       (grepl("^[0-9A-Fa-f]+$", x) && nchar(x) %in% c(2L, 4L, 6L, 8L)))
}

# A size setting: NULL or one positive number.
.acl_check_size <- function(x, key) {
  if (!is.null(x) && (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0))
    stop(key, " must be one positive number, for example ", format(.acl_defaults[[key]] %||% 2.5), ".",
         call. = FALSE)
  invisible(x)
}

# The lists titles, xlab and ylab of acl_theme_set(): the keys that the
# plots read, each with a text, "" or NA (no title), or NULL (the default).
.acl_check_label_list <- function(x, key) {
  if (is.null(x)) return(invisible(x))
  if (!is.list(x) || is.null(names(x)) || anyNA(names(x)) || any(!nzchar(names(x))))
    stop(key, " must be a named list, for example ", key, " = list(",
         c(titles = "SSB = \"My title\"", xlab = "year = \"Survey year\"", ylab = "ssb = \"SSB (t)\"")[[key]],
         ").", call. = FALSE)
  unknown <- setdiff(names(x), names(.acl_defaults[[key]]))
  if (length(unknown))
    stop(key, " has unknown keys: ", paste(unknown, collapse = ", "), ". The keys are the names of acl_theme(\"",
         key, "\").", call. = FALSE)
  for (nm in names(x)) {
    value <- x[[nm]]
    ok <- is.null(value) || is.expression(value) || is.language(value) ||
      (length(value) == 1L && (is.character(value) || is.na(value)))
    if (!ok) stop(key, "$", nm, " must be one text, \"\" or NA (none), or NULL (the default).", call. = FALSE)
  }
  invisible(x)
}

.acl_check_color <- function(x, arg, extra = NULL) {
  valid <- is.character(x) && length(x) == 1L && !is.na(x) &&
    !inherits(try(grDevices::col2rgb(x), silent = TRUE), "try-error")
  if (!valid) stop(arg, " must be one color name or code", if (!is.null(extra)) paste0(" ", extra),
                   ", for example \"#002b5f\".", call. = FALSE)
  invisible(x)
}

# Supported base themes. Names are accepted with or without the prefix.
.acl_theme_names <- paste0("theme_", c("bw", "minimal", "classic", "gray", "grey",
                                        "light", "linedraw", "dark", "void"))

.acl_describe_value <- function(x) {
  if (is.character(x) && length(x) == 1L && !is.na(x)) paste0("\"", x, "\"") else
    paste0("of class ", class(x)[1L])
}

# Full name of a supported ggplot2 theme; an error or NULL for anything else.
.acl_theme_name <- function(x, arg = "base_theme", error = TRUE) {
  if (is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)) {
    # In any letter case, with or without the prefix.
    name <- if (startsWith(tolower(x), "theme_")) x else paste0("theme_", x)
    position <- .acl_choice_position(name, .acl_theme_names)
    if (position > 0L) return(.acl_theme_names[position])
  }
  if (!error) return(NULL)
  stop(arg, " ", .acl_describe_value(x), " is not a supported theme name. Use one of: ",
       paste(sub("^theme_", "", .acl_theme_names), collapse = ", "),
       ". Add other themes to a plot with + ggplot2::theme().", call. = FALSE)
}

#' Build x-axis scale with breaks and expand
#'
#' Explicit breaks from the plot call are always used. The global x_breaks
#' setting is used only when at least one of its values lies within the range
#' of \code{values}, the x coordinates of the plot; one global setting cannot
#' fit time, age and length axes at once. Otherwise the breaks are
#' \code{auto_breaks}, or pretty breaks when that is NULL, or the breaks of
#' a time axis when \code{time = TRUE}.
#' @param x_breaks Breaks given in the plot call, or NULL.
#' @param n_breaks Target number of automatic breaks.
#' @param values Numeric x coordinates of the plot, or NULL when unknown.
#' @param auto_breaks Numeric vector of automatic breaks, or NULL.
#' @param labels Labels or labelling function passed to the scale.
#' @param check_overlap Logical. Omit automatic tick labels that would
#'   overprint in narrow facets.
#' @param time Logical. The axis is a time axis in years: labels at whole
#'   years by the rule of \code{.acl_time_axis()}, the first and the last
#'   year always among them, and unlabelled minor tick marks between them.
#'   \code{.acl_tidy_axes()} adapts both to the layout.
#' @keywords internal
.acl_scale_x <- function(x_breaks = NULL, n_breaks = 10, values = NULL,
                         auto_breaks = NULL, labels = ggplot2::waiver(),
                         check_overlap = FALSE, time = FALSE) {
  brks <- if (!is.null(x_breaks)) x_breaks else
    .acl_global_breaks(values)
  expd <- acl_theme("x_expand")
  if (is.null(expd)) expd <- c(0.01, 0.01)
  automatic <- is.null(brks)
  minor <- ggplot2::waiver()
  guide <- ggplot2::waiver()
  times <- if (time) .acl_finite_values(values) else numeric()
  if (automatic && length(times)) {
    info <- list(range = range(times), step = .acl_series_step(times))
    axis <- .acl_time_axis(info$range, info$step)
    brks <- .acl_time_breaks(axis$step, info, axis$gap)
    minor <- .acl_time_minor(axis$minor, info$range)
    guide <- ggplot2::guide_axis(minor.ticks = TRUE)
  } else if (automatic) {
    brks <- if (is.null(auto_breaks)) .acl_whole_breaks(n_breaks) else auto_breaks
    if (check_overlap) guide <- ggplot2::guide_axis(check.overlap = TRUE)
  }
  scale <- ggplot2::scale_x_continuous(
    breaks = brks, minor_breaks = minor, labels = labels,
    expand = ggplot2::expansion(mult = expd),
    guide = guide
  )
  # A time axis with breaks given in the call or the theme: .acl_tidy_axes()
  # gives its labels the angle of the theme key x_angle.
  if (time && !automatic) scale$acl_time_axis <- TRUE
  scale
}

.acl_finite_values <- function(values) {
  values <- suppressWarnings(as.numeric(values))
  values[is.finite(values)]
}

# ---------------------------------------------------------------------------
# Time axes: one rule for every plot with years on the x axis
# ---------------------------------------------------------------------------

# Width in inches at which the automatic layouts and year labels are chosen.
# acl_figure_size() recommends this width for multi-panel figures.
.acl_reference_width <- 10

# Width in inches that acl_figure_size() recommends for a plot with one
# column of panels, such as a single time series.
.acl_single_width <- 8

# Spacing of the time steps of a series in years: 1 for annual series, 0.25
# for quarterly ones.
.acl_series_step <- function(times) {
  spacing <- diff(sort(unique(times)))
  spacing <- spacing[spacing > 1e-8]
  if (!length(spacing)) 1 else min(1, min(spacing))
}

# Years between labels when the axis spans the figure: every year up to 12
# years, every 2nd up to 30, every 5th up to 60 and every 10th beyond.
.acl_time_label_step <- function(n_years) {
  if (n_years <= 12) 1 else if (n_years <= 30) 2 else if (n_years <= 60) 5 else 10
}

# Steps that labelled years may take, in increasing order.
.acl_label_steps <- c(1, 2, 5, 10, 20, 50, 100, 200, 500, 1000)

# Width in inches of one panel in a figure of `width` inches with `cols`
# columns of panels: the room of the axis title and margins is taken from
# the figure and the room of the y tick labels from each panel.
.acl_panel_width <- function(cols = 1, width = .acl_reference_width) {
  max(0.4, (width - 0.6) / max(1, cols) - 0.45)
}

# Label step, minor tick step, label angle and label gap of a time axis that
# covers `range` (in years) with time steps of `series_step` years, in a
# panel of a figure with `cols` columns of panels in all. Labels of 4-digit
# years take about (4 + 1) characters at the axis text size, a gap of one
# character included; slanted labels at 45 degrees need about 1.7 text
# heights between them. Single-panel figures keep horizontal labels and take
# a larger step when the labels would touch. In multi-panel figures the
# labels keep the wanted density (the step of the single-panel rule with one
# or two columns, the next step with more) and are slanted when they would
# touch; a larger step comes only when slanted labels would touch too.
# `angle` (the theme key x_angle) fixes the angle: 0 keeps the labels
# horizontal.
#
# The first and the last year are always labelled (.acl_time_positions()),
# and a multiple of the step closer to them than `gap` years is not: `gap`
# is the distance at which two labels at the chosen angle do not touch, for
# a single panel at the width that acl_figure_size() recommends for it (8
# inches) and for multi-panel figures at the reference width. In
# multi-panel figures the labels are slanted when horizontal labels would
# lose such a multiple and slanted ones would keep it.
.acl_time_axis <- function(range, series_step = 1, cols = 1, width = .acl_reference_width,
                           angle = acl_theme("x_angle"), size = acl_theme("axis_text_size"),
                           nchar = 4L) {
  size <- size %||% 10
  span <- diff(range)
  years <- floor(range[2L] + 1e-8) - ceiling(range[1L] - 1e-8) + 1
  base <- .acl_time_label_step(max(1, years))
  steps <- .acl_label_steps[.acl_label_steps >= base]
  if (!is.finite(span) || span <= 0)
    return(list(step = base, minor = series_step, angle = if (is.null(angle) || cols <= 1) 0 else angle,
                gap = NULL))
  expansion <- acl_theme("x_expand") %||% c(0.01, 0.01)
  per_year <- .acl_panel_width(cols, width) / (span * (1 + sum(expansion)))
  char <- 0.6 * size / 72
  # Distance in inches between the centres of two labels that do not touch.
  room <- function(a) if (a == 0) (nchar + 1) * char else 1.2 * size / 72 / sin(abs(a) * pi / 180)
  flat <- function(step) per_year * step >= room(0)
  slanted <- function(step, a = 45) per_year * step >= room(a)
  first <- function(ok) { hit <- which(vapply(steps, ok, logical(1))); if (length(hit)) steps[hit[1L]] else NA }
  if (!is.null(angle) && angle != 0) {
    step <- first(function(s) slanted(s, angle)); chosen <- angle
  } else if (!is.null(angle) || cols <= 1) {
    step <- first(flat); chosen <- 0
  } else {
    wanted <- if (cols <= 2) base else steps[min(2L, length(steps))]
    step <- first(flat); chosen <- 0
    if (is.na(step) || step > wanted) {
      step <- NA
      for (s in steps[steps >= wanted]) {
        if (flat(s)) { step <- s; chosen <- 0; break }
        if (slanted(s)) { step <- s; chosen <- 45; break }
      }
    }
  }
  if (is.na(step)) step <- steps[length(steps)]
  # Years between the centres of two labels at angle `a` that do not touch,
  # at most the label step.
  saved <- .acl_panel_width(cols, if (cols <= 1) min(width, .acl_single_width) else width) /
    (span * (1 + sum(expansion)))
  gap <- function(a) min(step, room(a) / saved)
  if (is.null(angle) && cols > 1 && chosen == 0 &&
      length(.acl_time_positions(range, step, gap(45))) > length(.acl_time_positions(range, step, gap(0))))
    chosen <- 45
  # Minor ticks at the time steps, or at whole years, or at a fifth or a half
  # of the label step, whichever is the first to leave 0.03 inch between them.
  candidates <- unique(c(if (series_step < 1) series_step, 1, step / 5, step / 2, step))
  candidates <- candidates[candidates <= step & abs(step / candidates - round(step / candidates)) < 1e-8]
  minor <- candidates[which(per_year * candidates >= 0.03)[1L]]
  if (is.na(minor)) minor <- step
  list(step = step, minor = minor, angle = chosen, gap = gap(chosen))
}

# Label positions of a time axis that shows the years `range` (from the
# first to the last time step in a panel): the year of the first and of the
# last time step, and the multiples of `step` between them. On an axis with
# several time steps per year the labels stay at year starts: the start of
# the first and of the last year, within `range`, that holds a time step. A
# multiple of the step closer than `gap` years to the first or the last
# label is left out; the first and the last label never are. A range within
# one year that holds no year start is labelled at its first time step.
.acl_time_positions <- function(range, step, gap = step / 2) {
  lower <- min(range); upper <- max(range)
  first <- ceiling(lower - 1e-8); last <- floor(upper + 1e-8)
  if (last < first) return(lower)
  from <- ceiling(lower / step - 1e-8) * step
  to <- floor(upper / step + 1e-8) * step
  regular <- if (to >= from) seq(from, to, by = step) else numeric()
  near <- function(end) abs(regular - end) > 1e-8 & abs(regular - end) < gap - 1e-8
  regular <- regular[!near(first) & !near(last)]
  sort(unique(round(c(first, regular, last), 8)))
}

# Breaks of a time axis: the labels of .acl_time_positions() for the years
# of each panel, with `gap` from .acl_time_axis() (half a step when NULL).
# `info` (the range and time step of the series) lets .acl_tidy_axes()
# choose the step again for the layout of the figure. ggplot2 passes the
# scale of the panel as `self`, whose range is the range of the data in
# that panel when the facets have free x scales; without it the limits are
# those of the panel, within the series.
.acl_time_breaks <- function(step, info = NULL, gap = NULL) {
  force(step); force(gap)
  structure(function(limits, self = NULL) {
    if (length(limits) != 2L || !all(is.finite(limits))) return(numeric())
    shown <- range(limits)
    # No label beyond the first or the last time step of the series, or of
    # the data of the panel.
    if (!is.null(info$range)) {
      data <- .acl_scale_range(self)
      shown <- c(max(c(shown[1L], info$range[1L], data[1L])), min(c(shown[2L], info$range[2L], data[2L])))
      # A panel that shows none of the series (no data at all) has no labels.
      if (shown[1L] > shown[2L] + 1e-8) return(numeric())
    }
    .acl_time_positions(shown, step, gap %||% (step / 2))
  }, acl_time = info, acl_step = step)
}

# Range of the data on which a continuous scale was trained (for free
# facet scales, the data of one panel), or NULL.
.acl_scale_range <- function(scale) {
  if (!inherits(scale, "ScaleContinuous")) return(NULL)
  limits <- tryCatch(if (scale$is_empty()) NULL else scale$get_limits(), error = function(e) NULL)
  if (is.numeric(limits) && length(limits) == 2L && all(is.finite(limits))) sort(limits) else NULL
}

# Minor breaks of a time axis: every `minor` years, plus the first and the
# last time step of the series, so that both ends are marked.
.acl_time_minor <- function(minor, range) {
  force(minor); force(range)
  function(limits) {
    if (length(limits) != 2L || !all(is.finite(limits)) ||
        max(limits) < range[1L] - 1e-8 || min(limits) > range[2L] + 1e-8) return(numeric())
    from <- ceiling(min(limits) / minor - 1e-8) * minor
    to <- floor(max(limits) / minor + 1e-8) * minor
    ticks <- if (to >= from) seq(from, to, by = minor) else numeric()
    ends <- range[range >= min(limits) - 1e-8 & range <= max(limits) + 1e-8]
    sort(unique(round(c(ticks, ends), 8)))
  }
}

# Theme layer of tick labels at `angle` degrees: slanted labels end at their
# tick mark (right and top aligned).
.acl_x_angle_theme <- function(angle) {
  if (is.null(angle)) return(NULL)
  ggplot2::theme(axis.text.x = if (angle == 0) ggplot2::element_text(angle = 0, hjust = 0.5, vjust = 1) else
    ggplot2::element_text(angle = angle, hjust = 1, vjust = 1))
}

# Pretty breaks that are whole numbers when the axis spans four units or
# more, so that a quarterly time axis is labelled by year ("2002", not
# "2002.5").
.acl_whole_breaks <- function(n) {
  force(n)
  structure(function(limits) {
    breaks <- scales::pretty_breaks(n = n)(limits)
    if (length(limits) == 2L && all(is.finite(limits)) && diff(range(limits)) >= 4) {
      whole <- breaks[abs(breaks - round(breaks)) < 1e-8]
      if (length(whole) >= 2L) breaks <- whole
    }
    # Narrow facet panels: no more than n labels, every k-th break.
    if (n <= 3L && length(limits) == 2L && all(is.finite(limits))) {
      breaks <- breaks[breaks >= min(limits) - 1e-8 & breaks <= max(limits) + 1e-8]
      if (length(breaks) > n)
        breaks <- breaks[seq.int(1L, length(breaks), by = ceiling((length(breaks) - 1L) / (n - 1L)))]
    }
    breaks
  }, acl_n_breaks = n)
}

# The global x_breaks setting, or NULL when none of its values lies on an
# axis with these coordinates.
.acl_global_breaks <- function(values = NULL) {
  breaks <- acl_theme("x_breaks")
  if (is.null(breaks) || is.null(values)) return(breaks)
  values <- suppressWarnings(as.numeric(values))
  values <- values[is.finite(values)]
  if (!length(values) || !is.numeric(breaks)) return(breaks)
  limits <- range(values)
  tolerance <- 1e-8 * max(1, abs(limits))
  if (any(breaks >= limits[1L] - tolerance & breaks <= limits[2L] + tolerance, na.rm = TRUE))
    breaks else NULL
}

# Number of automatic axis breaks that fit one panel of a facet_wrap() layout
# with this many panels. `budget` is the number of tick labels that fit across
# the whole figure: about 12 four-digit years, or 20 shorter age or length labels.
.acl_facet_n_breaks <- function(n_panels, facet_ncol = NULL, max_breaks = 10, budget = 12) {
  columns <- if (is.null(facet_ncol)) .acl_facet_columns(n_panels) else facet_ncol
  if (!is.numeric(columns) || length(columns) != 1L || !is.finite(columns) || columns < 1)
    return(max_breaks)
  as.integer(max(2, min(max_breaks, floor(budget / columns))))
}


# Default number of columns for `n` facet panels: panels clearly wider than
# tall at a figure width of about 10 inches (at most 6 columns), as few empty
# cells as possible and no last row with a single panel where a better grid
# exists. 4 panels give 2 x 2, 15 give 5 x 3, 20 give 5 x 4 and 23 give
# 6 x 4. A facet_ncol or facet_nrow given in the call wins. `chars` is the
# number of characters of the longest facet label: when the labels would
# wrap onto two lines in that layout (.acl_strip_wraps()), the layout takes
# the most columns that keep them on one line, avoiding a last row with a
# single panel where it can, so that 23 panels labelled "Length bin 122.5"
# give 5 x 5.
.acl_facet_columns <- function(n, chars = 0L) {
  n <- max(1L, as.integer(n))
  if (n <= 3L) return(n)
  options <- 2:min(6L, n)
  cost <- vapply(options, function(cols) {
    rows <- ceiling(n / cols)
    (cols * rows - n) + 3 * (rows > 1L && n %% cols == 1L) + 2 * abs(log(cols / rows / 1.4))
  }, numeric(1))
  best <- options[which.min(cost)]
  if (!.acl_strip_wraps(chars, best)) return(best)
  fewer <- options[options < best]
  fewer <- fewer[!vapply(fewer, function(cols) .acl_strip_wraps(chars, cols), logical(1))]
  if (!length(fewer)) return(best)
  whole <- fewer[n %% fewer != 1L]
  max(if (length(whole)) whole else fewer)
}

# Characters of a facet label that fit one line of a panel in a figure of
# the reference width with `cols` columns, at the strip text size.
.acl_strip_room <- function(cols) {
  size <- acl_theme("strip_text_size") %||% 10
  max(6L, floor(.acl_panel_width(cols) / (0.68 * size / 72)))
}

# TRUE when a facet label of `chars` characters is wrapped onto two lines
# by .acl_wrap_strips() in a layout of `cols` columns. Plain strips hold a
# third more in a smaller font on one line.
.acl_strip_wraps <- function(chars, cols) {
  if (cols < 2L || !length(chars) || chars <= 0) return(FALSE)
  width <- .acl_strip_room(cols)
  if (chars <= width) return(FALSE)
  !(identical(acl_theme("strip"), "plain") && chars <= floor(width * 4 / 3))
}

# Labels of the panels of a facet_wrap() plot with the default labeller, or
# an empty vector.
.acl_strip_labels <- function(p) {
  facet <- p$facet
  if (!inherits(facet, "FacetWrap") || !identical(facet$params$labeller, ggplot2::label_value))
    return(character())
  vars <- names(facet$params$facets)
  frames <- c(list(p$data), lapply(p$layers, function(layer) layer$data))
  unlist(lapply(frames, function(d)
    if (is.data.frame(d) && all(vars %in% names(d))) as.character(unlist(d[vars])) else NULL))
}

# Characters of the longest facet label of a plot, 0 without labels.
.acl_strip_chars <- function(p) {
  labels <- .acl_strip_labels(p)
  if (length(labels)) max(nchar(labels), na.rm = TRUE) else 0L
}

# Apply the same typography to a patchwork's outer title and panel titles.
.acl_annotation_theme <- function(legend_pos, font_family = NULL, title_size = NULL,
                                  title_hjust = NULL) {
  title_args <- list(size = title_size %||% acl_theme("title_size"),
                     hjust = title_hjust %||% acl_theme("title_hjust"))
  face <- acl_theme("title_face") %||% "plain"
  if (!identical(face, "plain")) title_args$face <- face
  do.call(ggplot2::theme, c(list(
    text = ggplot2::element_text(family = font_family %||% acl_theme("font_family")),
    plot.title = do.call(ggplot2::element_text, title_args)),
    if (!is.null(legend_pos)) list(legend.position = legend_pos)))
}


#' Get comparison plot defaults, merging global settings with per-call overrides
#'
#' Resolves colors/linetypes with this priority:
#' \enumerate{
#'   \item Per-call argument (e.g. \code{colors = c("blue","red")})
#'   \item Global theme with matching names (e.g. \code{compare_colors = c(ACL = "blue", ...)})
#'   \item Global theme positional (first value -> model1, second -> model2)
#'   \item Hard-coded fallback
#' }
#'
#' @param colors Per-call override. Named or unnamed vector of 2.
#' @param linetypes Per-call override.
#' @param line_size Per-call override.
#' @param point_size Per-call override.
#' @param se_alpha Per-call override.
#' @param legend_pos Per-call override.
#' @param facet_ncol Per-call override.
#' @param facet_scales Per-call override.
#' @param m1 Model 1 name.
#' @param m2 Model 2 name.
#' @return A named list of resolved settings.
#' @keywords internal
.acl_compare_defaults <- function(colors = NULL, linetypes = NULL,
                                  line_size = NULL, point_size = NULL,
                                  se_alpha = NULL, legend_pos = NULL,
                                  facet_ncol = NULL, facet_scales = NULL,
                                  m1 = "Model 1", m2 = "Model 2") {

  # Helper: resolve a 2-element vector (color or linetype) to named c(m1=..., m2=...)
  resolve_pair <- function(user_val, theme_key, fallback) {
    argument <- sub("^compare_", "", theme_key)
    # Priority 1: per-call argument. A value that cannot describe two models
    # is reported and replaced by the active theme, not by package defaults.
    val <- user_val
    if (!is.null(val) && length(val) < 2L) {
      warning(argument, " must contain two values, one per model; it has ", length(val),
              ". Using the global ", theme_key, " setting.", call. = FALSE)
      val <- NULL
    }
    # Priority 2: global theme
    if (is.null(val)) {
      val <- acl_theme(theme_key)
      if (!is.null(val) && length(val) < 2L) {
        warning("The global ", theme_key, " setting must contain two values, one per model; it has ",
                length(val), ". Using the package defaults.", call. = FALSE)
        val <- NULL
      }
    }
    # Priority 3: fallback
    if (is.null(val)) val <- fallback

    # If named and both model names match, use by name
    if (!is.null(names(val)) && m1 %in% names(val) && m2 %in% names(val)) {
      return(stats::setNames(val[c(m1, m2)], c(m1, m2)))
    }
    # Otherwise use positionally: first = model1, second = model2
    stats::setNames(val[1:2], c(m1, m2))
  }

  list(
    colors     = resolve_pair(colors,    "compare_colors",    .acl_defaults$compare_colors),
    linetypes  = resolve_pair(linetypes, "compare_linetypes", c("solid", "dashed")),
    line_size  = line_size %||% .acl_auto_size("compare_line_size"),
    point_size = point_size %||% acl_theme("compare_point_size") %||% acl_theme("point_size") %||% 2.5,
    se_alpha   = if (!is.null(se_alpha))   se_alpha   else (acl_theme("compare_se_alpha")   %||% 0.25),
    legend_pos = .acl_legend_position(if (!is.null(legend_pos)) legend_pos else
      (acl_theme("compare_legend_pos") %||% "bottom")),
    facet_ncol = facet_ncol %||% acl_theme("compare_facet_ncol"),
    facet_scales = .acl_facet_scales(if (!is.null(facet_scales)) facet_scales else
      (acl_theme("compare_facet_scales") %||% "free_y"))
  )
}

# base R fallback for %||% (available in R >= 4.0 but define for safety)
`%||%` <- function(x, y) if (is.null(x)) y else x


#' Fix length bin labels
#' @keywords internal
.acl_fix_len_labels <- function(len_label, prefix = "Length bin") {
  labels <- as.character(len_label)
  if (length(labels) >= 2L) {
    edges <- c(1L, length(labels))
    text <- trimws(labels[edges])
    parts <- regmatches(text, regexec(.acl_length_interval_pattern, text, perl = TRUE))
    if (length(parts[[1L]]) == 3L) labels[edges[1L]] <- paste0("<", parts[[1L]][3L])
    if (length(parts[[2L]]) == 3L) labels[edges[2L]] <- paste0(">", parts[[2L]][2L])
    if (anyDuplicated(labels)) labels <- as.character(len_label)
  }
  paste(prefix, labels)
}


# Labels for time steps: "Year 2000" for annual labels, "2000 Q2" for
# quarterly labels, otherwise the time label itself. Quarter labels require a
# quarterly time step: `step` when the caller knows it (the fitted
# growth_step), otherwise the spacing of the labels. Semiannual or annual
# series recorded at .25 or .75 keep their decimal labels. `prefix = FALSE`
# drops "Year" for axes whose title already names the unit. Whole-number
# times are years unless `step` is quarterly: then they are first quarters,
# so a quarterly retrospective that ends in a first quarter reads "2004 Q1".
.acl_time_labels <- function(times, step = NULL, prefix = TRUE) {
  times <- as.numeric(times)
  quarterly_step <- is.numeric(step) && length(step) == 1L && is.finite(step) &&
    abs(step - 0.25) < 1e-6
  if (!quarterly_step && all(abs(times - round(times)) < 1e-8)) {
    years <- format(round(times), trim = TRUE)
    return(if (prefix) paste("Year", years) else years)
  }
  quarters <- (times - floor(times + 1e-8)) / 0.25
  on_grid <- all(abs(quarters - round(quarters)) < 1e-6)
  if (!is.numeric(step) || length(step) != 1L || !is.finite(step)) {
    spacing <- diff(sort(unique(times)))
    step <- if (length(spacing)) min(spacing) else NA_real_
  }
  quarterly <- is.finite(step) && abs(step - 0.25) < 1e-6
  if (on_grid && quarterly)
    return(sprintf("%d Q%d", as.integer(floor(times + 1e-8)), as.integer(round(quarters)) + 1L))
  as.character(times)
}

# Factor of time-step labels in time order, for facet_wrap().
.acl_period_factor <- function(values, times = sort(unique(values)), step = NULL) {
  labels <- .acl_time_labels(times, step = step)
  factor(labels[match(values, times)], levels = labels)
}

# Fitted ages of the first n age classes. `plus_group = FALSE` is for
# matrices without the last age class (ALSCL FA). NULL when the fit has no
# usable age metadata, as in results saved by older versions.
.acl_fitted_ages <- function(model_result, n, plus_group = TRUE) {
  age <- model_result$age
  if (!is.numeric(age) || !is.null(dim(age)) || n < 1L ||
      length(age) != n + !plus_group || any(!is.finite(age)) || any(diff(age) <= 0))
    return(NULL)
  as.numeric(age[seq_len(n)])
}

# Labels for age classes: "Age 1", ..., "Age 15+". The last age class of both
# models accumulates older fish, so it is marked as a plus group. Fits
# without age metadata keep the position labels "Age bin 1", ...
.acl_age_labels <- function(model_result, n, plus_group = TRUE, prefix = "Age") {
  age <- .acl_fitted_ages(model_result, n, plus_group)
  if (is.null(age)) return(paste("Age bin", seq_len(n)))
  labels <- as.character(age)
  if (plus_group) labels[n] <- paste0(labels[n], "+")
  if (nzchar(prefix)) paste(prefix, labels) else labels
}

# Automatic breaks on a numeric age axis: at most n_breaks fitted ages,
# evenly spaced and always including the oldest age class, which carries
# the plus-group mark.
.acl_age_breaks <- function(age, n_breaks = 8) {
  step <- max(1L, ceiling(length(age) / n_breaks))
  rev(rev(age)[seq.int(1L, length(age), by = step)])
}

# Tick labels for a numeric age axis, marking the plus-group age.
.acl_age_axis_labels <- function(plus_age = NULL) {
  function(breaks) {
    labels <- as.character(breaks)
    if (!is.null(plus_age)) {
      plus <- !is.na(breaks) & abs(breaks - plus_age) < 1e-8
      labels[plus] <- paste0(labels[plus], "+")
    }
    labels[is.na(breaks)] <- NA_character_
    labels
  }
}

# Time basis of the instantaneous rates, which the models define per time
# step. The step length in years comes from the fit.
.acl_rate_basis <- function(model_result) {
  step <- model_result$growth_step
  if (is.null(step)) {
    years <- model_result$year
    step <- if (is.numeric(years) && length(years) > 1L) diff(years)[1L] else NA_real_
  }
  if (!is.numeric(step) || length(step) != 1L || !is.finite(step)) return("per time step")
  if (abs(step - 1) < 1e-8) "per year" else if (abs(step - 0.5) < 1e-8) "per half year" else
    if (abs(step - 0.25) < 1e-8) "per quarter" else if (abs(step - 1 / 12) < 1e-6) "per month" else
      "per time step"
}

# Default fishing mortality label with its time basis. A customized label
# is used verbatim.
.acl_F_label <- function(basis, label = .acl_lab("y", "F")) {
  if (identical(label, .acl_defaults$ylab$F)) paste0(label, " (", basis, ")") else label
}

# Default natural mortality label with its time basis. A customized label is
# used verbatim.
.acl_M_label <- function(basis, label = .acl_lab("y", "M")) {
  if (identical(label, .acl_defaults$ylab$M)) paste0(label, " (", basis, ")") else label
}


#' Internal: Build ggplot2 theme object from acl_theme()
#'
#' This is the function called by plot functions via
#' \code{get("acl_get_theme", envir = asNamespace("ALSCL"))()}.
#'
#' @return A list of ggplot2 theme layers.
#' @keywords internal
acl_get_theme <- function() {
  .acl_base_theme()
}

# Keep error recovery consistent with the grid of the current style.
.acl_plot_theme <- function() {
  tryCatch(acl_get_theme(), error = function(e) {
    ggplot2::theme_bw() + do.call(ggplot2::theme, .acl_grid_elements())
  })
}


# ---------------------------------------------------------------------------
# Readable text in every plot, under both styles
# ---------------------------------------------------------------------------

# Tick labels of one axis, never in E notation. The labels of an axis whose
# values (other than zero) all lie from 0.0001 up to below 1,000,000,000 in
# absolute value are decimal numbers (.acl_decimal_labels()). Otherwise
# every label of the axis is a power of ten with a raised exponent, such as
# 1.5 x 10^-9, as a plotmath expression (the form of scales::label_math());
# zero reads "0". The x axes (often years) use no thousands separator.
.acl_number_labels <- function(x, big.mark = ",") {
  ok <- is.finite(x)
  values <- .acl_snap_zero(x[ok])
  size <- abs(values[values != 0])
  if (!length(size) || (min(size) >= 1e-4 && max(size) < 1e9)) return(.acl_decimal_labels(x, big.mark))
  text <- rep(NA_character_, length(x))
  text[ok] <- vapply(values, .acl_power_of_ten, character(1))
  as.expression(lapply(text, function(t) if (is.na(t)) NA else str2lang(t)))
}

# Decimal numbers without trailing zeros ("0", "2.5" and "0.1" rather than
# "0.0", "2.5" and "0.10"), with thousands separators ("25,000"). Values
# within rounding error of zero read "0"; NA stays NA.
.acl_decimal_labels <- function(x, big.mark = ",") {
  out <- rep(NA_character_, length(x))
  ok <- is.finite(x)
  if (!any(ok)) return(out)
  values <- .acl_snap_zero(x[ok])
  out[ok] <- format(values, trim = TRUE, drop0trailing = TRUE, scientific = FALSE, big.mark = big.mark)
  out
}

# Breaks within rounding error of zero set to zero: smaller than 1e-10 of
# the smallest distance between two breaks (of the largest break when there
# is one), so that 1e-17 on an axis of steps of 0.05 reads "0" while 1e-9 on
# a log axis up to 1000 keeps its value.
.acl_snap_zero <- function(values) {
  if (!length(values)) return(values)
  distinct <- sort(unique(values))
  scale <- if (length(distinct) > 1L) min(diff(distinct)) else max(abs(values))
  values[abs(values) < 1e-10 * scale] <- 0
  values
}

# A number as the text of a plotmath power of ten: "1.5 %*% 10^-9" for
# 1.5e-9, "0" for zero.
.acl_power_of_ten <- function(v) {
  if (v == 0) return("0")
  exponent <- floor(log10(abs(v)) + 1e-9)
  mantissa <- signif(v / 10^exponent, 6)
  if (abs(mantissa) >= 10) {
    mantissa <- mantissa / 10
    exponent <- exponent + 1
  }
  paste0(format(mantissa, trim = TRUE, drop0trailing = TRUE, scientific = FALSE), " %*% 10^", exponent)
}

# Width of a tick label in characters of the axis text: the characters of a
# text label; for a power of ten the mantissa, the multiplication sign with
# its spaces, "10", and the exponent in the smaller type of a superscript.
.acl_label_chars <- function(label) {
  if (is.character(label)) return(nchar(label))
  text <- paste(deparse(label), collapse = "")
  parts <- regmatches(text, regexec("^(.*) %\\*% 10\\^(.*)$", text))[[1L]]
  if (length(parts) == 3L) return(nchar(parts[2L]) + 5 + 0.7 * nchar(gsub("[()]", "", parts[3L])))
  nchar(text)
}

# Breaks of the y axis of a facet panel (applied to each panel with free
# scales): evenly spaced multiples of a round step (1, 2, 2.5 or 5 times a
# power of ten, or 3 or 4 when those fail), at least `min_n` and at most
# `n` of them inside the limits.
# The labels bracket the data: the lowest at or below the lower quarter of
# the range and the highest at or above the upper quarter. A range that
# reaches clearly both sides of zero has zero labelled and a label on each
# side. The densest step that meets these rules is used; when none does,
# one label more is allowed, then the brackets are dropped. Labels need at
# most 4 significant digits: a very narrow range gets fewer, rounder breaks
# instead of labels such as "13.9225".
.acl_breaks <- function(n, min_n = min(3L, n)) {
  force(n); force(min_n)
  function(limits) {
    if (length(limits) != 2L || !all(is.finite(limits))) return(numeric())
    lo <- min(limits); hi <- max(limits); span <- hi - lo
    if (span <= 0) return(lo)
    # Rounding error relative to the values, for very small values too.
    tolerance <- 1e-10 * max(abs(limits))
    exponent <- floor(log10(span))
    multiples <- function(mantissa) lapply(sort(as.vector(outer(mantissa, 10^(exponent + (-3:2))))),
      function(step) {
        b <- seq(ceiling(lo / step - 1e-9), floor(hi / step + 1e-9)) * step
        b[abs(b) < tolerance] <- 0
        b[b >= lo - tolerance & b <= hi + tolerance]
      })
    two_sided <- lo < 0 && hi > 0 && min(-lo, hi) >= 0.15 * span
    choose <- function(digits) {
      short <- function(b) length(b) > 0L && all(.acl_short_number(b, digits))
      nice <- Filter(short, multiples(c(1, 2, 2.5, 5)))
      candidates <- c(nice, Filter(short, multiples(c(3, 4))))
      good <- function(b, n) length(b) >= min_n && length(b) <= n &&
        min(b) <= lo + 0.25 * span + tolerance && max(b) >= hi - 0.25 * span - tolerance &&
        (!two_sided || (any(b == 0) && min(b) < 0 && max(b) > 0))
      # Steps of 1, 2, 2.5 and 5 first, with one label more if needed; steps
      # of 3 and 4 only when those fail, then two labels more; then the rule
      # without the brackets; last, fewer labels, down to one.
      for (b in nice) if (good(b, n)) return(b)
      for (b in nice) if (good(b, n + 1L)) return(b)
      for (b in candidates) if (good(b, n + 1L)) return(b)
      for (b in candidates) if (good(b, n + 2L)) return(b)
      for (b in candidates) if (length(b) >= min_n && length(b) <= n + 1L) return(b)
      for (b in candidates) if (length(b) >= 2L && length(b) <= n + 1L) return(b)
      for (b in candidates) if (length(b) == 1L) return(b)
      NULL
    }
    # Labels of at most 4 significant digits; more only for a range that
    # holds no such value.
    for (digits in 4:15) {
      b <- choose(digits)
      if (!is.null(b)) return(b)
    }
    scales::breaks_extended(n = n)(limits)
  }
}

# Number of y labels for a facet panel in a layout with `rows` rows of
# panels, for a figure saved at about the size of acl_figure_size() (1.5 to
# 1.9 inches per row): 5 with one or two rows, 4 with three, 3 with more.
.acl_y_n_breaks <- function(rows) if (rows <= 2L) 5L else if (rows == 3L) 4L else 3L

# Rows, columns and number of panels of a plot: facet_wrap() layouts are
# computed from the facet values in the plot and layer data, with the default
# columns of .acl_facet_columns(); facet_grid() layouts have one row for
# each value of the row variables and one column for each value of the
# column variables; other plots have one panel.
.acl_facet_dims <- function(p) {
  facet <- p$facet
  if (inherits(facet, "FacetGrid")) {
    rows <- .acl_facet_count(p, names(facet$params$rows))
    cols <- .acl_facet_count(p, names(facet$params$cols))
    return(c(rows = rows, cols = cols, panels = rows * cols))
  }
  if (!inherits(facet, "FacetWrap")) return(c(rows = 1L, cols = 1L, panels = 1L))
  params <- facet$params
  n <- .acl_facet_count(p)
  ncol <- params$ncol
  if (is.null(ncol) && is.null(params$nrow)) ncol <- .acl_facet_columns(n, .acl_strip_chars(p))
  dims <- ggplot2::wrap_dims(max(1L, n), params$nrow, ncol)
  c(rows = as.integer(dims[1L]), cols = as.integer(dims[2L]), panels = as.integer(n))
}

# Number of panels of a facet_wrap() plot, or of combinations of the facet
# variables `vars` (the rows or the columns of a facet_grid() plot).
.acl_facet_count <- function(p, vars = names(p$facet$params$facets)) {
  if (!length(vars)) return(1L)
  frames <- c(list(p$data), lapply(p$layers, function(layer) layer$data))
  values <- lapply(frames, function(d)
    if (is.data.frame(d) && all(vars %in% names(d))) unique(d[vars]) else NULL)
  values <- do.call(rbind, values[!vapply(values, is.null, logical(1))])
  if (is.null(values)) 1L else as.integer(nrow(unique(values)))
}

# A facet_wrap() plot with the default columns of .acl_facet_columns() when
# the call gave neither facet_ncol nor facet_nrow.
.acl_default_columns <- function(p) {
  facet <- p$facet
  if (!inherits(facet, "FacetWrap") || !is.null(facet$params$ncol) || !is.null(facet$params$nrow))
    return(p)
  chosen <- ggplot2::ggproto(NULL, facet)
  params <- facet$params
  params$ncol <- .acl_facet_columns(.acl_facet_count(p), .acl_strip_chars(p))
  chosen$params <- params
  p$facet <- chosen
  p
}

# TRUE when an aesthetic of the plot is a factor or character in its data.
.acl_discrete_aes <- function(p, aes) {
  value <- .acl_aes_value(p, aes)
  is.factor(value) || is.character(value)
}

# TRUE when the y aesthetic of the plot is numeric in its data.
.acl_numeric_aes <- function(p, aes = "y") is.numeric(.acl_aes_value(p, aes))

# Values of an aesthetic in the plot data or the data of the first layer
# that maps it; NULL when they cannot be found.
.acl_aes_value <- function(p, aes) {
  mapping <- p$mapping[[aes]]
  data <- p$data
  if (is.null(mapping) || !is.data.frame(data) || !nrow(data)) {
    for (layer in p$layers) {
      if (!is.null(layer$mapping[[aes]])) {
        mapping <- layer$mapping[[aes]]
        if (is.data.frame(layer$data) && nrow(layer$data)) data <- layer$data
        break
      }
    }
  }
  if (is.null(mapping) || !is.data.frame(data) || !nrow(data)) return(NULL)
  # A mapping is a quosure: a one-sided formula with its environment.
  # unclass() reads it without the quosure methods of rlang.
  tryCatch(eval(unclass(mapping)[[2L]], data, attr(mapping, ".Environment")),
           error = function(e) NULL)
}

# Tick labels of every package plot: short numbers on continuous axes, a
# number of y breaks that suits the number of panel rows, and x labels as
# dense as the width of a panel allows. A time axis follows .acl_time_axis()
# for the columns of the figure: `outer_cols` is the number of columns of a
# multi-panel figure (patchwork) that holds the plot. The default columns of
# a facet come from .acl_facet_columns(), line widths that come from the
# theme default are thinner in dense facets (.acl_line_weights()), and
# reference lines are drawn under the data. Breaks, labels and guides that a
# plot or the user set are kept. `legend_hole` moves a bottom legend into the
# empty cells of the last row of a facet.
.acl_tidy_axes <- function(p, outer_cols = 1L, legend_hole = FALSE) {
  if (!inherits(p, "ggplot") || inherits(p, "patchwork")) return(p)
  p <- .acl_default_columns(p)
  dims <- .acl_facet_dims(p)
  cols <- dims[["cols"]] * max(1L, as.integer(outer_cols))
  # Facet panels get the y rule of .acl_breaks(); a single panel keeps the
  # usual breaks of ggplot2.
  n_y <- if (dims[["panels"]] > 1L) .acl_y_n_breaks(dims[["rows"]]) else NULL
  scales <- p$scales$clone()
  find <- function(aes) which(vapply(scales$scales, function(s) aes %in% s$aesthetics, logical(1)))
  tidy <- function(s, n = NULL, overlap = FALSE, labels = .acl_number_labels) {
    if (s$is_discrete()) {
      # Long lists of categories (length bins, ages, time steps on a heat map
      # axis): every second or third label, so that labels do not touch.
      if (inherits(s$breaks, "waiver")) {
        s <- s$clone()
        s$breaks <- .acl_discrete_breaks(max_labels)
      }
      return(s)
    }
    s <- s$clone()
    # Breaks of a transformed scale (log, square root) are left to its
    # transformation, and so are its labels, except on a log scale, whose
    # labels are those of the package: decimals or powers of ten, not the
    # E notation of the transformation.
    transformation <- .acl_scale_transformation(s)
    identity <- identical(transformation, "identity")
    if (identity && inherits(s$breaks, "waiver")) s$breaks <- if (!is.null(n)) .acl_breaks(n) else .acl_short_breaks()
    if ((identity || startsWith(transformation, "log")) && inherits(s$labels, "waiver")) s$labels <- labels
    if (overlap && inherits(s$guide, "waiver")) s$guide <- ggplot2::guide_axis(check.overlap = TRUE)
    s
  }
  added <- NULL
  iy <- find("y")
  if (!length(iy) && .acl_discrete_aes(p, "y")) {
    scales$add(ggplot2::scale_y_discrete())
    iy <- find("y")
  }
  max_labels <- max(6L, floor(16 / dims[["rows"]]))
  if (length(iy)) {
    scales$scales[[iy[1L]]] <- tidy(scales$scales[[iy[1L]]], n_y, dims[["rows"]] > 1L)
    scales$scales[[iy[1L]]] <- .acl_point_room(p, scales$scales[[iy[1L]]], axis = "y", rows = dims[["rows"]])
  } else if (.acl_numeric_aes(p, "y"))
    added <- .acl_point_room(p, ggplot2::scale_y_continuous(
      breaks = if (is.null(n_y)) .acl_short_breaks() else .acl_breaks(n_y),
      labels = .acl_number_labels,
      guide = if (dims[["rows"]] > 1L) ggplot2::guide_axis(check.overlap = TRUE) else ggplot2::waiver()),
      axis = "y", rows = dims[["rows"]])
  ix <- find("x")
  # A discrete x axis without a scale of its own gets one for its breaks.
  if (!length(ix) && .acl_discrete_aes(p, "x")) {
    scales$add(ggplot2::scale_x_discrete())
    ix <- find("x")
  }
  # A continuous x axis without a scale of its own (lags, quantiles) gets
  # one when the plot draws points, so that .acl_point_room() can widen it.
  if (!length(ix) && .acl_numeric_aes(p, "x") &&
      any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomPoint"), logical(1)))) {
    scales$add(ggplot2::scale_x_continuous())
    ix <- find("x")
  }
  angle_layer <- edge_layer <- NULL
  # Labels at an angle end at their tick mark and need no room at the right.
  own_room <- FALSE
  if (length(ix)) {
    breaks <- scales$scales[[ix[1L]]]$breaks
    time_info <- .acl_breaks_attr(breaks, "acl_time")
    if (!is.null(time_info)) {
      own_room <- TRUE
      # A time axis: label step, minor ticks and angle for this layout.
      axis <- .acl_time_axis(time_info$range, time_info$step, cols = cols)
      s <- scales$scales[[ix[1L]]]$clone()
      s$breaks <- .acl_time_breaks(axis$step, time_info, axis$gap)
      s$minor_breaks <- .acl_time_minor(axis$minor, time_info$range)
      s$guide <- ggplot2::guide_axis(minor.ticks = TRUE, check.overlap = cols > 1L)
      scales$scales[[ix[1L]]] <- s
      if (axis$angle != 0) angle_layer <- .acl_x_angle_theme(axis$angle)
      edge_layer <- .acl_time_edge_theme(p, axis$angle, dims[["cols"]])
    } else if (isTRUE(scales$scales[[ix[1L]]]$acl_time_axis) && !is.null(acl_theme("x_angle"))) {
      # Breaks given for a time axis keep the angle of the theme key x_angle.
      angle_layer <- .acl_x_angle_theme(acl_theme("x_angle"))
      own_room <- acl_theme("x_angle") != 0
    } else if (cols > 1L) {
      # Other automatic x breaks of a facet: as many 3-character labels as
      # the width of a panel holds with a gap of one character.
      automatic <- .acl_breaks_attr(breaks, "acl_n_breaks")
      if (!is.null(automatic)) {
        size <- acl_theme("axis_text_size") %||% 10
        fit <- floor(.acl_panel_width(cols) / (4 * 0.6 * size / 72))
        s <- scales$scales[[ix[1L]]]$clone()
        s$breaks <- .acl_whole_breaks(min(automatic, max(2L, fit)))
        scales$scales[[ix[1L]]] <- s
      }
    }
  }
  max_labels <- max(4L, floor(20 / cols))
  if (length(ix)) {
    scales$scales[[ix[1L]]] <- tidy(scales$scales[[ix[1L]]], NULL, cols > 1L,
                                    function(x) .acl_number_labels(x, big.mark = ""))
    scales$scales[[ix[1L]]] <- .acl_point_room(p, scales$scales[[ix[1L]]], cols)
    # Room at the right for the last label of other x axes (ages, lengths,
    # time axes with breaks given in the call or the theme); the room of the
    # automatic time axes comes from .acl_time_axis().
    if (!own_room) {
      chars <- .acl_end_label_chars(p, scales$scales[[ix[1L]]], cols)
      if (chars > 0L) edge_layer <- .acl_time_edge_theme(p, 0, 1L, nchar = chars)
    }
  }
  p$scales <- scales
  if (!is.null(added)) p <- p + added
  if (!is.null(angle_layer)) p <- p + angle_layer
  if (!is.null(edge_layer)) p <- p + edge_layer
  p <- .acl_wrap_strips(p, cols)
  p <- .acl_line_weights(p, dims[["panels"]])
  p <- .acl_reference_first(p)
  if (legend_hole) p <- .acl_legend_in_hole(p, dims)
  p
}

# Room for the first and the last label of a time axis, which sit at the
# ends of the panels (.acl_time_positions()), in points, with the width
# estimate of .acl_time_axis() at the size of the tick labels of the plot. A
# horizontal label of `nchar` characters is centred on its tick, so the last
# one reaches half a label beyond the last panel: the right plot margin is
# widened to hold it. The same room is given to the last label of any other
# x axis that ends at the right end of the panels, such as "15+" on an age
# axis (.acl_end_label_chars()). Slanted labels end at their tick mark. In
# facet_wrap() and facet_grid() layouts the last label of a column and the
# first label of the next column are neighbours. Without a y axis between
# the panels (fixed or free_x scales of facet_wrap(), and facet_grid(),
# whose rows share one y axis at the left) the panels are spaced by the room
# of two neighbouring labels; a y axis between them holds at least about
# two characters, and horizontal labels get the rest of the room as spacing.
.acl_time_edge_theme <- function(p, angle, facet_cols, nchar = 4L) {
  theme <- tryCatch(ggplot2::complete_theme(p$theme), error = function(e) NULL)
  text <- tryCatch(ggplot2::calc_element("axis.text.x", theme), error = function(e) NULL)
  size <- if (is.numeric(text$size) && length(text$size) == 1L) text$size else
    acl_theme("axis_text_size") %||% 10
  char <- 0.6 * size
  elements <- list()
  if (angle == 0) {
    margin <- tryCatch(ggplot2::calc_element("plot.margin", theme), error = function(e) NULL)
    if (inherits(margin, "unit") && length(margin) == 4L && all(grid::unitType(margin) == "points")) {
      values <- as.numeric(margin)
      needed <- nchar / 2 * char + 1
      if (values[2L] < needed) elements$plot.margin <- ggplot2::margin(values[1L], needed, values[3L], values[4L])
    }
  }
  facet <- p$facet
  if (facet_cols > 1L && inherits(facet, c("FacetWrap", "FacetGrid"))) {
    y_axes <- isTRUE(facet$params$draw_axes$y) ||
      (inherits(facet, "FacetWrap") && isTRUE(facet$params$free$y))
    room <- if (angle == 0) (nchar + 1) * char else 1.2 * size / sin(abs(angle) * pi / 180)
    spacing <- room - if (y_axes) 2 * char + 5.5 else 0
    if (spacing > 5.5) elements$panel.spacing.x <- grid::unit(spacing, "pt")
  }
  if (length(elements)) do.call(ggplot2::theme, elements)
}

# Number of characters of the last tick label of a continuous x axis when
# that label reaches beyond the right end of the panels, as "15+" does at
# the plus group of an age axis or the last length on a length axis; 0
# otherwise. The breaks and labels are those of the scale for the range of
# the x values in the plot, with its expansion, and the panels are as wide
# as at the size that acl_figure_size() recommends.
.acl_end_label_chars <- function(p, s, cols = 1L) {
  if (s$is_discrete() || !identical(.acl_scale_transformation(s), "identity")) return(0L)
  values <- .acl_aes_numbers(p, c("x", "xmin", "xmax", "xend"))
  if (!length(values)) return(0L)
  limits <- range(values)
  given <- suppressWarnings(as.numeric(s$limits))
  if (length(given) == 2L) limits <- ifelse(is.finite(given), given, limits)
  span <- diff(limits)
  if (!is.finite(span) || span <= 0) return(0L)
  expand <- if (inherits(s$expand, "waiver")) c(0.05, 0, 0.05, 0) else rep_len(as.numeric(s$expand), 4L)
  ends <- c(limits[1L] - expand[1L] * span - expand[2L], limits[2L] + expand[3L] * span + expand[4L])
  trained <- s$clone()
  trained$train(limits)
  breaks <- tryCatch(trained$get_breaks(ends), error = function(e) NULL)
  breaks <- breaks[is.finite(breaks) & breaks >= ends[1L] - 1e-8 * span & breaks <= ends[2L] + 1e-8 * span]
  if (!length(breaks)) return(0L)
  last <- which.max(breaks)
  labels <- tryCatch(trained$get_labels(breaks), error = function(e) NULL)
  label <- if (length(labels) == length(breaks)) labels[[last]] else .acl_number_labels(breaks[last], "")[[1L]]
  if (is.null(label) || (is.atomic(label) && (length(label) != 1L || is.na(label)))) return(0L)
  chars <- ceiling(.acl_label_chars(if (is.atomic(label)) as.character(label) else label))
  if (chars < 1) return(0L)
  size <- acl_theme("axis_text_size") %||% 10
  width <- .acl_panel_width(cols, if (cols > 1L) .acl_reference_width else .acl_single_width)
  room <- (ends[2L] - breaks[last]) / diff(ends) * width
  if (room >= chars / 2 * 0.6 * size / 72) 0L else as.integer(chars)
}

# Finite numbers that the aesthetics `aes` (such as "x" and "xmax") take in
# the plot and in each of its layers.
.acl_aes_numbers <- function(p, aes) {
  evaluate <- function(mapping, data) {
    if (is.null(mapping) || !is.data.frame(data) || !nrow(data)) return(numeric())
    value <- tryCatch(eval(unclass(mapping)[[2L]], data, attr(mapping, ".Environment")),
                      error = function(e) NULL)
    if (is.numeric(value)) value[is.finite(value)] else numeric()
  }
  out <- numeric()
  for (a in aes) {
    out <- c(out, evaluate(p$mapping[[a]], p$data))
    for (layer in p$layers) {
      data <- if (is.data.frame(layer$data) && nrow(layer$data)) layer$data else p$data
      mapping <- layer$mapping[[a]] %||% (if (isTRUE(layer$inherit.aes)) p$mapping[[a]])
      out <- c(out, evaluate(mapping, data))
    }
  }
  out
}

# Room for whole points at the ends of a continuous x axis. When the plot
# draws points and its x scale keeps the expansion of the default x_expand
# setting, or the default expansion of ggplot2 (5%), the axis is widened on
# each side to about 3% of its range at least, or to the radius of the points
# in a narrow panel, so that points at the first and last x value are not
# cut by the panel border. Bars and error bars need no more room: the scale
# already holds their half width. An x_expand set by the user, and an
# expansion that a plot sets itself, are kept. On the y axis (`axis = "y"`)
# only the default expansion of ggplot2 is widened, for points at the top
# and bottom of short facet panels; `rows` is the number of panel rows.
.acl_point_room <- function(p, s, cols = 1L, axis = "x", rows = 1L) {
  default <- .acl_defaults$x_expand
  if (s$is_discrete()) return(s)
  current <- if (inherits(s$expand, "waiver")) 0.05 else if (axis == "x" &&
    identical(acl_theme("x_expand"), default) &&
      identical(as.numeric(s$expand), as.numeric(ggplot2::expansion(mult = default)))) default[1L] else
    return(s)
  points <- Filter(function(layer) inherits(layer$geom, "GeomPoint"), p$layers)
  if (!length(points)) return(s)
  sizes <- unlist(lapply(points, function(layer) layer$aes_params$size))
  size <- max(c(acl_theme("point_size") %||% 2.5, sizes[is.numeric(sizes) & is.finite(sizes)]))
  # Radius in inches of a point of this size, with a margin of about a
  # point radius between the point and the panel border.
  radius <- size * ggplot2::.pt / 72 / 2 + 0.06
  # Width, or height, of a panel at the recommended figure size.
  width <- if (axis == "x") .acl_panel_width(cols, if (cols > 1L) .acl_reference_width else .acl_single_width) else
    if (rows > 1L) 1.1 else 3
  mult <- max(0.03, radius / width)
  if (mult <= current) return(s)
  s <- s$clone()
  s$expand <- ggplot2::expansion(mult = mult)
  s
}

# Cap width of error bars on points or lines, in units of x: a quarter of
# the spacing of the x values (the time step, or one year of age), about the
# size of the caps on bars. With a single x value there is no spacing: the
# cap is 0.06 of a unit, and .acl_show_singletons() keeps such an axis at
# least one unit wide, so that the cap stays short.
.acl_cap_width <- function(x) {
  x <- sort(unique(.acl_finite_values(x)))
  spacing <- diff(x)
  spacing <- spacing[spacing > 1e-8]
  if (!length(spacing)) return(0.06)
  0.25 * min(spacing)
}

# Breaks of a single panel: the usual breaks of ggplot2, unless one of their
# labels would need more than 4 significant digits, as on an axis with a
# very narrow range. Then the breaks of .acl_breaks(), which keeps to such
# labels.
.acl_short_breaks <- function() {
  function(limits) {
    breaks <- scales::breaks_extended()(limits)
    inside <- breaks[is.finite(breaks)]
    if (all(.acl_short_number(inside))) breaks else .acl_breaks(5L)(limits)
  }
}

# TRUE for values whose label needs at most `digits` significant digits,
# within rounding error relative to the value, so that very small values
# are judged as well as large ones.
.acl_short_number <- function(x, digits = 4L) {
  ok <- is.finite(x)
  out <- rep(TRUE, length(x))
  out[ok] <- abs(x[ok] - signif(x[ok], digits)) <= 1e-9 * abs(x[ok])
  out
}

# Name of the transformation of a continuous scale, such as "identity" or
# "log-10"; "identity" when the scale does not say.
.acl_scale_transformation <- function(s) {
  transformation <- tryCatch(s$get_transformation(), error = function(e) NULL)
  name <- transformation$name
  if (is.character(name) && length(name) == 1L && !is.na(name)) name else "identity"
}

# An attribute of a breaks function; a function stored in a scale is wrapped
# as a ggproto method.
.acl_breaks_attr <- function(breaks, which) {
  attr(breaks, which) %||% (if (is.function(breaks)) attr(environment(breaks)$f, which))
}

# Line width of the data lines of a plot when the call gives none: the theme
# value, marked as automatic while it is the value of the active style (1 and
# 0.9 under "default", 1.5 and 1.2 under "classic"), so that
# .acl_line_weights() can thin it in dense facets. `key` is "line_size" or
# "compare_line_size".
.acl_auto_size <- function(key = "line_size", fallback = .acl_defaults[[key]]) {
  value <- acl_theme(key) %||% fallback
  preset <- .acl_style_presets[[acl_theme("style") %||% "default"]][[key]] %||% .acl_defaults[[key]]
  if (identical(value, preset)) structure(value, acl_auto = TRUE) else value
}

# Data lines of dense facets: lines whose width comes from the theme default
# are drawn at full width up to 4 panels, at two thirds for 5 to 12 panels
# and at half beyond. Widths given in the call or set in the theme are kept.
.acl_line_factor <- function(panels) if (panels <= 4L) 1 else if (panels <= 12L) 2 / 3 else 1 / 2
.acl_line_weights <- function(p, panels = 1L) {
  factor <- .acl_line_factor(panels)
  for (i in seq_along(p$layers)) {
    layer <- p$layers[[i]]
    width <- layer$aes_params$linewidth
    if (is.null(width) || is.null(attributes(width))) next
    params <- layer$aes_params
    params$linewidth <- as.numeric(width) * if (isTRUE(attr(width, "acl_auto"))) factor else 1
    p$layers[[i]] <- do.call(ggplot2::ggproto, list(NULL, layer, aes_params = params))
  }
  p
}

# Width of reference lines (zero, one, the line of equality): thin, so that
# they do not hide the data in small panels.
.acl_reference_linewidth <- 0.4

# Reference lines (horizontal, vertical and sloped lines) are drawn first,
# under the data.
.acl_reference_first <- function(p) {
  reference <- vapply(p$layers, function(layer)
    inherits(layer$geom, c("GeomHline", "GeomVline", "GeomAbline")) &&
      inherits(layer$stat, "StatIdentity"), logical(1))
  if (any(reference) && !all(reference)) p$layers <- c(p$layers[reference], p$layers[!reference])
  p
}

# A bottom legend placed in the empty cells at the end of the last row of a
# facet, so that the figure has no hole and needs no room below.
.acl_legend_in_hole <- function(p, dims) {
  empty <- dims[["rows"]] * dims[["cols"]] - dims[["panels"]]
  if (empty < 1L || dims[["rows"]] < 2L) return(p)
  filled <- dims[["cols"]] - empty
  p + ggplot2::theme(legend.position = "inside",
    legend.position.inside = c((filled + dims[["cols"]]) / (2 * dims[["cols"]]), 0.5 / dims[["rows"]]),
    legend.justification.inside = c(0.5, 0.5), legend.direction = "vertical")
}

# Facet labels of narrow panels on two lines: with two or more columns,
# labels longer than a panel holds at the reference width (about the panel
# width divided by the width of one character of strip text) are wrapped at
# a space so that they are not cut at the edge. Plain strips up to a third
# longer stay on one line in 90% of the strip size (at least 8 points) and
# may run into the free space above the next axis.
.acl_wrap_strips <- function(p, cols) {
  facet <- p$facet
  if (cols < 2L || !inherits(facet, "FacetWrap") ||
      !identical(facet$params$labeller, ggplot2::label_value)) return(p)
  labels <- .acl_strip_labels(p)
  size <- acl_theme("strip_text_size") %||% 10
  width <- .acl_strip_room(cols)
  if (!length(labels) || max(nchar(labels)) <= width) return(p)
  if (identical(acl_theme("strip"), "plain") && max(nchar(labels)) <= floor(width * 4 / 3)) {
    # Room at the right edge of the figure for the last column.
    return(p + ggplot2::theme(strip.text = ggplot2::element_text(size = max(8, 0.9 * size)),
                              plot.margin = ggplot2::margin(5.5, 24, 5.5, 5.5)))
  }
  wrapped <- ggplot2::ggproto(NULL, facet)
  params <- facet$params
  params$labeller <- ggplot2::label_wrap_gen(width = width)
  wrapped$params <- params
  p$facet <- wrapped
  p
}

# .acl_tidy_axes() for a plot or for the plot of a list(plot = , ...) result.
.acl_tidy_axes_result <- function(x) {
  if (is.list(x) && !inherits(x, "ggplot") && inherits(x$plot, "ggplot")) {
    x$plot <- .acl_tidy_axes(x$plot)
    return(x)
  }
  .acl_tidy_axes(x)
}

# Breaks of a discrete axis: all categories up to `max_labels`, otherwise
# every k-th one, so that at most `max_labels` labels are drawn. On a time
# axis (categories that are years or quarters, .acl_discrete_time()) the
# first and the last time step always carry a label, as on the continuous
# time axes, and a label closer to the last one than the room of one label
# (the number of categories divided by `max_labels`) is left out.
.acl_discrete_breaks <- function(max_labels) {
  force(max_labels)
  function(limits) {
    n <- length(limits)
    if (n <= max_labels) return(limits)
    keep <- seq.int(1L, n, by = ceiling(n / max_labels))
    if (.acl_discrete_time(limits)) keep <- c(keep[n - keep >= n / max_labels - 1e-8], n)
    limits[sort(unique(keep))]
  }
}

# TRUE for categories that are time steps: years ("2000", "Year 2000"),
# quarters ("2000 Q1") or decimal years ("2000.5").
.acl_discrete_time <- function(levels) {
  levels <- as.character(levels)
  length(levels) > 1L && !anyNA(levels) &&
    all(grepl("^(Year )?[12][0-9]{3}( Q[1-4]|[.][0-9]+)?$", levels))
}

# Relative luminance of a color (WCAG 2), and its contrast ratio with white.
.acl_contrast_white <- function(colour) {
  rgb <- grDevices::col2rgb(colour)[, 1L] / 255
  linear <- ifelse(rgb <= 0.03928, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
  luminance <- sum(c(0.2126, 0.7152, 0.0722) * linear)
  1.05 / (luminance + 0.05)
}

# A color mixed toward black in steps of 5% until its contrast ratio with a
# white background reaches `ratio` (4.5 to 1 for normal text). Colors that
# already pass are returned unchanged.
.acl_readable_color <- function(colour, ratio = 4.5) {
  if (.acl_contrast_white(colour) >= ratio) return(colour)
  rgb <- grDevices::col2rgb(colour)[, 1L]
  for (share in seq(0.05, 1, by = 0.05)) {
    mixed <- grDevices::rgb(t(rgb * (1 - share)), maxColorValue = 255)
    if (.acl_contrast_white(mixed) >= ratio) return(tolower(mixed))
  }
  "#000000"
}

# Wrap a title, subtitle or caption line by line at `width` characters.
.acl_wrap_text <- function(text, width) {
  if (!is.character(text) || length(text) != 1L || is.na(text)) return(text)
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  paste(vapply(lines, function(line)
    if (nchar(line) > width) paste(strwrap(line, width), collapse = "\n") else line, character(1)),
    collapse = "\n")
}

# A bottom legend of many keys in rows of at most `per_row` keys.
.acl_legend_rows <- function(n, per_row = 6L) ggplot2::guide_legend(nrow = max(1L, ceiling(n / per_row)), byrow = TRUE)


# ---------------------------------------------------------------------------
# Figure sizes and saving
# ---------------------------------------------------------------------------

#' Recommended size of a saved figure
#'
#' Returns the width and height in inches at which a plot reads well when
#' saved. The plot functions return ggplot or patchwork objects whose saved
#' size is the caller's choice; this function computes a size from the
#' layout of the plot: the rows and columns of panels, the title, subtitle
#' and caption, slanted year labels, and a legend below the panels. A single
#' time series gets about 8 x 4.5 inches; faceted plots and multi-panel
#' figures about 10 inches of width and 1.5 to 1.9 inches of height per row
#' of panels; plots of one quantity against another, such as
#' \code{plot_SSB_Rec()} and quantile-quantile plots, a near-square shape;
#' and heat maps a shape whose cells are neither very flat nor very tall.
#'
#' @param plot A ggplot or patchwork object, such as the result of a plot
#'   function of the package.
#' @param width Numeric or NULL. Width in inches. NULL chooses the width from
#'   the layout; a number fixes the width and returns the matching height.
#' @return A named numeric vector \code{c(width = , height = )} in inches,
#'   each between 3 and 14.
#' @seealso \code{\link{acl_save_plot}()}, which saves a plot at this size.
#' @family acl_theme
#' @export
#' @examples
#' fit <- list(year = 2001:2020, report = list(Rec = 100 + 30 * sin(1:20)))
#' p <- plot_recruitment(fit)
#' size <- acl_figure_size(p)
#' size
#' file <- tempfile(fileext = ".png")
#' ggplot2::ggsave(file, p, width = size[["width"]], height = size[["height"]], dpi = 300)
#' acl_figure_size(p, width = 6)
acl_figure_size <- function(plot, width = NULL) {
  if (!inherits(plot, "ggplot"))
    stop("plot must be a ggplot or patchwork object.", call. = FALSE)
  if (!is.null(width) && (!is.numeric(width) || length(width) != 1L || !is.finite(width) || width <= 0))
    stop("width must be NULL or one positive number of inches.", call. = FALSE)
  # Text is measured on a device that draws nothing.
  previous <- grDevices::dev.cur()
  grDevices::pdf(NULL)
  on.exit({
    grDevices::dev.off()
    if (previous > 1L) grDevices::dev.set(previous)
  }, add = TRUE)
  bounded <- function(x) min(14, max(3, x))
  width <- bounded(width %||% .acl_figure_width(plot))
  height <- bounded(.acl_figure_height(plot, width))
  c(width = round(width, 2), height = round(height, 2))
}

#' Save a plot at its recommended size
#'
#' Saves a plot with \code{ggplot2::ggsave()}. A width or height that is not
#' given comes from \code{\link{acl_figure_size}()}: with both missing the
#' recommended size is used, and a given width gets the matching height.
#' The default resolution is 300 dots per inch and the background is white.
#'
#' @param plot A ggplot or patchwork object.
#' @param filename Character. File to write; the extension chooses the
#'   format, as in \code{ggplot2::ggsave()}.
#' @param width,height Numeric or NULL. Size in \code{units}. NULL takes the
#'   value of \code{acl_figure_size()}.
#' @param dpi Numeric. Resolution of raster formats in dots per inch, 300 by
#'   default.
#' @param units Unit of width and height: \code{"in"} (inches, the default),
#'   \code{"cm"}, \code{"mm"} or \code{"px"} (pixels at \code{dpi}).
#'   Letter case does not matter.
#' @param ... Further arguments of \code{ggplot2::ggsave()}, such as
#'   \code{device} or \code{bg} (default \code{"white"}).
#' @return The file name, invisibly.
#' @family acl_theme
#' @export
#' @examples
#' fit <- list(year = 2001:2020, report = list(Rec = 100 + 30 * sin(1:20)))
#' file <- tempfile(fileext = ".png")
#' acl_save_plot(plot_recruitment(fit), file)
#' file.exists(file)
#'
#' # A width in centimetres, with the matching height
#' acl_save_plot(plot_recruitment(fit), file, width = 16, units = "cm")
acl_save_plot <- function(plot, filename, width = NULL, height = NULL, dpi = 300, units = "in", ...) {
  if (!inherits(plot, "ggplot"))
    stop("plot must be a ggplot or patchwork object.", call. = FALSE)
  if (!is.character(filename) || length(filename) != 1L || is.na(filename) || !nzchar(filename))
    stop("filename must be one file name.", call. = FALSE)
  for (arg in c("width", "height")) {
    value <- get(arg)
    if (!is.null(value) && (!is.numeric(value) || length(value) != 1L || !is.finite(value) || value <= 0))
      stop(arg, " must be NULL or one positive number, in the unit set by units (inches by default).",
           call. = FALSE)
  }
  if (!is.numeric(dpi) || length(dpi) != 1L || !is.finite(dpi) || dpi <= 0)
    stop("dpi must be one positive number.", call. = FALSE)
  units <- .acl_match_choice(units, c("in", "cm", "mm", "px"), "units")
  args <- list(...)
  # Sizes in inches: those given are converted, the others come from
  # acl_figure_size().
  per_inch <- switch(units, `in` = 1, cm = 2.54, mm = 25.4, px = dpi)
  if (!is.null(width)) width <- width / per_inch
  if (!is.null(height)) height <- height / per_inch
  if (is.null(width) || is.null(height)) {
    size <- acl_figure_size(plot, width = width)
    width <- width %||% size[["width"]]
    height <- height %||% size[["height"]]
  }
  if (is.null(args$bg)) args$bg <- "white"
  do.call(ggplot2::ggsave, c(list(filename = filename, plot = plot, width = width, height = height,
                                  units = "in", dpi = dpi), args))
  invisible(filename)
}

# Plots of a patchwork and its layout, as patchwork arranges them.
.acl_patches <- function(p) {
  patches <- p$patches
  self <- p
  self$patches <- NULL
  class(self) <- setdiff(class(self), "patchwork")
  plots <- patches$plots
  if (!inherits(self, "plot_filler")) plots <- c(plots, list(self))
  list(plots = plots, layout = patches$layout, annotation = patches$annotation)
}

# Kind of a single ggplot for its size: "square" (fixed aspect ratio or a
# quantile-quantile plot), "heat" (tiles), "facet" or "single".
.acl_figure_kind <- function(p) {
  if (!is.null(p$theme$aspect.ratio)) return("square")
  stats <- vapply(p$layers, function(layer) class(layer$stat)[1L], character(1))
  geoms <- vapply(p$layers, function(layer) class(layer$geom)[1L], character(1))
  if (any(stats %in% c("StatQq", "StatQqLine"))) return("square")
  if (any(geoms %in% c("GeomTile", "GeomRaster"))) return("heat")
  if (inherits(p$facet, "FacetWrap") || inherits(p$facet, "FacetGrid")) return("facet")
  "single"
}

# Default width: 10 inches for figures with two or more columns of panels,
# 6.5 for square plots and 8 otherwise.
.acl_figure_width <- function(p) {
  if (inherits(p, "patchwork")) {
    parts <- .acl_patches(p)
    n <- length(parts$plots)
    dims <- ggplot2::wrap_dims(max(1L, n), parts$layout$nrow, parts$layout$ncol)
    if (dims[2L] >= 2L) return(.acl_reference_width)
    return(max(vapply(parts$plots, function(x)
      if (inherits(x, "ggplot")) .acl_figure_width(x) else .acl_single_width, numeric(1))))
  }
  kind <- .acl_figure_kind(p)
  if (kind == "square") return(6.5)
  if (.acl_facet_dims(.acl_default_columns(p))[["cols"]] >= 2L) .acl_reference_width else .acl_single_width
}

# Height in inches of a plot drawn `width` inches wide: the fixed heights of
# its title, axes, strips and legend, measured on the gtable, plus panels of
# a height chosen from their width and kind. `cell` marks a plot that is one
# cell of a multi-panel figure, whose panels may be shorter.
.acl_figure_height <- function(p, width, cell = FALSE) {
  if (inherits(p, "patchwork")) return(.acl_patchwork_height(p, width))
  if (!inherits(p, "ggplot") || inherits(p, "plot_filler") || inherits(p, "guide_area") ||
      !length(p$layers)) return(0)
  built <- ggplot2::ggplot_build(p)
  gt <- ggplot2::ggplot_gtable(built)
  measure <- function(u, convert) {
    null <- grid::unitType(u) == "null"
    list(null = as.numeric(u[null]), fixed = sum(convert(u[!null], "in", valueOnly = TRUE)))
  }
  h <- measure(gt$heights, grid::convertHeight)
  w <- measure(gt$widths, grid::convertWidth)
  panel_w <- max(0.5, (width - w$fixed) / max(1, sum(w$null)))
  if (isTRUE(gt$respect)) return(h$fixed + sum(h$null) * panel_w)
  kind <- .acl_figure_kind(p)
  # A quantile-quantile panel inside a multi-panel figure takes the height
  # of the other panels of its row.
  if (cell && kind == "square") kind <- "single"
  bounded <- function(x, lo, hi) min(hi, max(lo, x))
  rows <- length(h$null)
  panel_h <- switch(kind,
    square = panel_w,
    heat = {
      tiles <- built$data[vapply(p$layers, function(layer)
        inherits(layer$geom, c("GeomTile", "GeomRaster")), logical(1))][[1L]]
      counts <- vapply(split(tiles, tiles$PANEL), function(d)
        c(length(unique(d$x)), length(unique(d$y))), numeric(2))
      cells <- apply(matrix(counts, nrow = 2L), 1L, max)
      bounded(0.6 * panel_w * cells[2L] / max(1, cells[1L]), if (rows > 1L) 1.05 else 2.4, 9)
    },
    facet = bounded(0.62 * panel_w, 1.05, 1.5),
    {
      # One panel: half as tall as wide, or about a quarter inch per
      # category of a discrete y axis.
      y <- built$layout$panel_params[[1L]]$y
      levels <- if (!is.null(y) && inherits(y, "ViewScale") && y$is_discrete()) length(y$get_limits()) else 0L
      if (levels > 0L) bounded(0.28 * levels, 1.2, 8) else
        if (cell) bounded(0.55 * panel_w, 1.6, 4) else bounded(0.5 * panel_w, 2.4, 5)
    })
  h$fixed + sum(h$null) * panel_h
}

# Height of a patchwork: the rows of its layout, each as tall as its tallest
# plot at the width of its column, plus the overall title, subtitle and
# caption.
.acl_patchwork_height <- function(p, width) {
  parts <- .acl_patches(p)
  n <- length(parts$plots)
  if (!n) return(0)
  dims <- ggplot2::wrap_dims(n, parts$layout$nrow, parts$layout$ncol)
  shares <- parts$layout$widths
  shares <- if (is.numeric(shares) && length(shares) == dims[2L]) shares / sum(shares) else rep(1 / dims[2L], dims[2L])
  byrow <- !identical(parts$layout$byrow, FALSE)
  rows <- numeric(dims[1L])
  for (i in seq_len(n)) {
    row <- if (byrow) (i - 1L) %/% dims[2L] + 1L else (i - 1L) %% dims[1L] + 1L
    col <- if (byrow) (i - 1L) %% dims[2L] + 1L else (i - 1L) %/% dims[1L] + 1L
    rows[row] <- max(rows[row], .acl_figure_height(parts$plots[[i]], width * shares[col], cell = TRUE))
  }
  annotation <- parts$annotation
  lines <- function(x) if (is.null(x) || !is.character(x)) 0 else length(strsplit(paste(x, collapse = "\n"), "\n")[[1L]])
  size <- acl_theme("title_size") %||% 14
  sum(rows) + (if (lines(annotation$title)) lines(annotation$title) * 1.4 * size / 72 + 0.1 else 0) +
    lines(annotation$subtitle) * 0.2 + lines(annotation$caption) * 0.2
}
