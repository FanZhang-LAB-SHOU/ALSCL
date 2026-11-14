#' ALSCL Plot Theme Configuration
#'
#' Global settings for all ALSCL plot functions, including model comparison plots.
#' Change titles, axis labels, font family, colors, line sizes, and
#' comparison plot styles in one place.
#'
#' @section Usage:
#' \preformatted{
#' # View current settings
#' acl_theme()
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
# Default configuration (internal)
# ---------------------------------------------------------------------------
# ggsci palettes and semantic roles.
.acl_palette <- function(palette = "npg", n = NULL) {
  palette <- match.arg(tolower(palette), c("npg", "aaas", "nejm", "lancet", "jama"))
  cols <- switch(palette,
    npg = ggsci::pal_npg("nrc")(10),
    aaas = ggsci::pal_aaas("default")(10),
    nejm = ggsci::pal_nejm("default")(8),
    lancet = ggsci::pal_lancet("lanonc")(9),
    jama = ggsci::pal_jama("default")(7))
  if (is.null(n)) return(cols)
  # Interpolate beyond the native palette size instead of recycling.
  if (n <= length(cols)) cols[seq_len(n)] else grDevices::colorRampPalette(cols)(n)
}

.acl_palette_roles <- function(palette) {
  cols <- .acl_palette(palette)
  primary <- if (palette == "npg") cols[4] else cols[1]
  accent <- if (palette == "npg") cols[1] else cols[2]
  list(palette = palette, line_color = primary, se_color = primary,
       compare_colors = c(primary, accent), point_color = primary,
       observed_color = accent, smooth_color = cols[3],
       hline_color = "grey55", low_col = "#F7F9FC", high_col = primary)
}

# Continuous values use a light-to-dark gradient.
.acl_fill_continuous <- function(palette = NULL, name = ggplot2::waiver()) {
  if (is.null(palette)) return(ggplot2::scale_fill_gradient(
    low = acl_theme("low_col"), high = acl_theme("high_col"), name = name))
  if (length(palette) == 1 && tolower(palette) %in% c("npg", "aaas", "nejm", "lancet", "jama")) {
    roles <- .acl_palette_roles(tolower(palette))
    return(ggplot2::scale_fill_gradient(low = roles$low_col, high = roles$high_col, name = name))
  }
  ggplot2::scale_fill_viridis_c(option = palette, name = name)
}

.acl_defaults <- list(

  palette = "npg",
  point_color = .acl_palette_roles("npg")$point_color,
  observed_color = .acl_palette_roles("npg")$observed_color,
  smooth_color = .acl_palette_roles("npg")$smooth_color,
  hline_color = "grey55",
  low_col = "#F7F9FC",
  high_col = .acl_palette_roles("npg")$high_col,

  # --- Base ggplot2 theme --------------------------------------------------
  base_theme = "theme_bw",

  # --- Font ----------------------------------------------------------------
  font_family = "sans",

  # --- Text sizes (in pt) -------------------------------------------------
  title_size      = 14,
  title_hjust     = 0.5,
  axis_title_size = 12,
  axis_text_size  = 10,
  strip_text_size = 10,
  legend_text_size = 10,

  # --- Axis settings -------------------------------------------------------
  x_breaks = NULL,
  x_expand = c(0.01, 0.01),

  # --- Default colors and line sizes (single-model plots) ------------------
  line_color  = .acl_palette_roles("npg")$line_color,
  line_size   = 1.5,
  point_size  = 2.5,
  se_color    = .acl_palette_roles("npg")$se_color,
  se_alpha    = 0.2,

  # --- Interval for positive quantities: "lognormal" or "wald" -------------
  interval    = "lognormal",

  # --- Comparison plot settings (plot_compare_* functions) ------------------
  # Colors/linetypes: positional (1st = model1, 2nd = model2).
  # Names are optional; if provided they override positional matching.
  # Examples:
  #   c("#2166AC", "#B2182B")                       positional
  #   c(ACL = "#2166AC", ALSCL = "#B2182B")         named
  #   c("M=0" = "steelblue", "M=0.5" = "tomato")   custom names
  compare_colors     = .acl_palette_roles("npg")$compare_colors,
  compare_linetypes  = c("solid", "dashed"),
  compare_line_size  = 1.2,
  compare_point_size = NULL,
  compare_se_alpha   = 0.15,
  compare_legend_pos = "bottom",
  compare_facet_ncol = 2,
  compare_facet_scales = "free_y",

  # --- Titles --------------------------------------------------------------
  titles = list(
    # plot_abundance
    N       = "Estimated total abundance (N)",
    N_se    = "Estimated total abundance (N) with 95% CI",
    NA_     = "Estimated abundance at age",
    NA_se   = "Estimated abundance at age with 95% CI",
    NL      = "Estimated abundance at length",
    NL_se   = "Estimated abundance at length with 95% CI",

    # plot_biomass
    B       = "Estimated total biomass (B)",
    B_se    = "Estimated total biomass (B) with 95% CI",
    BL      = "Estimated biomass at length",
    BL_se   = "Estimated biomass at length with 95% CI",
    BA      = "Estimated biomass at age",
    BA_se   = "Estimated biomass at age with 95% CI",

    # plot_SSB
    SSB     = "Estimated spawning stock biomass (SSB)",
    SSB_se  = "Estimated spawning stock biomass (SSB) with 95% CI",
    SBL     = "Estimated spawning stock biomass at length",
    SBL_se  = "Estimated spawning stock biomass at length with 95% CI",
    SBA     = "Estimated spawning stock biomass at age",
    SBA_se  = "Estimated spawning stock biomass at age with 95% CI",

    # plot_recruitment
    Rec     = "Estimated recruitment (R)",
    Rec_se  = "Estimated recruitment (R) with 95% CI",

    # plot_SSB_Rec
    SSB_Rec = "Spawning stock biomass and recruitment",

    # plot_catch
    CN      = "Estimated catch numbers (CN)",
    CN_se   = "Estimated catch numbers (CN) with 95% CI",
    CNA     = "Estimated catch numbers at age",
    CNA_se  = "Estimated catch numbers at age with 95% CI",
    CNL     = "Estimated catch numbers at length",
    CNL_se  = "Estimated catch numbers at length with 95% CI",

    # plot_fishing_mortality
    F_year     = "Estimated fishing mortality (F) over time",
    F_year_se  = "Estimated fishing mortality (F) over time with 95% CI",
    F_age      = "Estimated fishing mortality (F) at age",
    F_age_se   = "Estimated fishing mortality (F) at age with 95% CI",
    F_length   = "Estimated fishing mortality (F) at length",
    F_length_se = "Estimated fishing mortality (F) at length with 95% CI",

    # plot_deviance
    dev_R   = "Log recruitment deviations over time",
    dev_F   = "Log fishing mortality deviations over time",
    dev_R_multiplier = "Recruitment multipliers over time",
    dev_F_multiplier = "Fishing mortality multipliers over time",

    # plot_VB: the von Bertalanffy curve of an ACL fit, and mean length at
    # age from the fitted numbers of an ALSCL fit
    VB      = "Von Bertalanffy growth curve",
    length_at_age = "Mean length at age",

    # plot_length_at_age
    length_at_age_time = "Mean length at age by time step",

    # plot_relative_catch
    relative_catch = "Relative catch",

    # plot_natural_mortality and plot_survey_catchability: inputs of a fit
    natural_mortality = "Natural mortality rate (M) used in the fit",
    survey_q     = "Survey catchability at length used in the fit",
    survey_q_age = "Survey catchability multiplier by age used in the fit",

    # plot_ridges
    CatL_obs_length = "Observed survey length composition over time",
    CatL_est_length = "Fitted survey length composition over time",
    ridges   = "Observed and fitted survey length compositions",

    # plot_CatL: one panel per length bin, or one panel per time step
    CatL_by_length = "Fitted (line) and observed (point) survey indices over time",
    CatL_by_year   = "Fitted and observed survey indices at length",

    # plot_residuals
    resid_length = "Log residuals of the survey index by length bin",
    resid_year   = "Log residuals of the survey index by time step",

    # plot_retro; the model type is appended in parentheses
    retro    = "Retrospective analysis",

    # plot_pla
    pla      = "Probability of length given age",

    # Comparison plot titles
    compare_ts      = "{m1} vs {m2}",
    compare_F       = "Fishing mortality comparison",
    compare_resid   = "Residual diagnostics: {m1} vs {m2}",
    compare_growth  = "Mean length at age",
    compare_CatL    = "Observed and fitted survey indices at length",
    compare_metrics = "Model fit comparison: {m1} vs {m2}",
    compare_sel     = "Survey catchability at length",
    compare_F_ts    = "Fishing mortality by time step"
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
    catch     = "Catch numbers",
    survey    = NULL, # NULL preserves legacy custom abundance labels for survey plots.
    # The time basis, such as "(per year)", is appended from the fit.
    F         = "Fishing mortality rate",
    dev_R     = "Log recruitment deviation",
    dev_F     = "Log fishing mortality deviation",
    dev_R_multiplier = "Recruitment multiplier",
    dev_F_multiplier = "Fishing mortality multiplier",
    residual  = "Log residual",
    growth    = "Length",
    length    = "Length",
    # The time basis, such as "(per year)", is appended from the fit.
    M         = "Natural mortality rate",
    survey_q  = "Survey catchability (q)",
    survey_q_age = "Survey catchability multiplier",
    relative_catch_number = "Catch in numbers divided by its mean",
    relative_catch_weight = "Catch in weight divided by its mean"
  )
)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Get Current ALSCL Plot Theme
#'
#' Returns the current global theme settings used by all ALSCL plot functions.
#'
#' @param what Optional character. Retrieve a specific element, e.g.
#'   \code{"titles"}, \code{"font_family"}, \code{"compare_colors"}.
#' @return A list of current settings, or a single element if \code{what}
#'   is specified.
#' @export
#' @examples
#' acl_theme()
#' acl_theme("font_family")
#' acl_theme("compare_colors")
acl_theme <- function(what = NULL) {
  # Snapshots retain every setting, including nested nullable label defaults.
  current <- utils::modifyList(.acl_defaults, getOption("acl.theme", list()), keep.null = TRUE)
  if (is.null(what)) return(current)
  if (identical(what, "compare_linewidth")) {
    .acl_deprecated_message("theme.compare_linewidth",
      "Theme setting 'compare_linewidth' is deprecated and will be removed; use 'compare_line_size' instead.")
    what <- "compare_line_size"
  }
  current[[what]]
}


#' Set ALSCL Plot Theme Options
#'
#' Modify one or more global theme settings. Partial updates are supported:
#' only the fields you specify will be changed; all others keep their
#' current values.
#'
#' @param base_theme Character. Base ggplot2 theme name: "bw", "minimal",
#'   "classic", "gray", "grey", "light", "linedraw", "dark" or "void", with or
#'   without the "theme_" prefix. Any other value is an error.
#' @param font_family Character. Font family for all text.
#' @param title_size Numeric. Plot title size in pt.
#' @param title_hjust Numeric. Title alignment (0=left, 0.5=center, 1=right).
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
#' @param line_size Numeric. Default line width for single-model plots (1.5).
#'   Plot arguments set to NULL inherit this value; explicit widths take priority.
#' @param point_size Numeric. Default point size for all point plots (2.5).
#'   Plot arguments set to NULL inherit this value unless a comparison-specific
#'   override is set. Explicit per-call sizes take priority.
#' @param se_color Character. Default CI color.
#' @param se_alpha Numeric. Default transparency of interval ribbons (0.2).
#'   Plot arguments set to NULL inherit this value; explicit alpha takes priority.
#'   Error bars are drawn opaque unless a plot call supplies se_alpha.
#' @param interval Character. Default 95% interval for positive quantities
#'   (abundance, biomass, spawning stock biomass, recruitment, catch and
#'   fishing mortality): \code{"lognormal"} (default) or \code{"wald"}. See
#'   \code{\link{plot_abundance}} for the formulas.
#' @param compare_colors Character vector of 2 colors. Can be unnamed (positional)
#'   or named. The first color is always model1, second is model2. A vector
#'   with fewer than two colors is an error.
#'   Examples: \code{c("blue", "red")}, \code{c(ACL = "blue", ALSCL = "red")},
#'   \code{c("M=0" = "steelblue", "M=0.5" = "tomato")}.
#' @param compare_linetypes Character vector of 2 linetypes. Same rules as colors.
#' @param compare_line_size Numeric. Line width for comparison plots (1.2).
#' @param compare_point_size Numeric or NULL. Optional point-size override for
#'   comparison plots. The default NULL inherits point_size. Existing explicit
#'   values remain supported; a plot's point_size argument takes priority.
#'   Pass NULL explicitly to clear a comparison-specific override.
#' @param compare_se_alpha Numeric. CI ribbon alpha for comparison plots.
#' @param compare_legend_pos Character. Legend position for comparison plots.
#' @param compare_facet_ncol Integer. Default facet columns in comparison plots.
#' @param compare_facet_scales Character. Facet scales for comparison plots.
#' @param palette Character or NULL. ggsci palette: "npg" (default), "aaas",
#'   "nejm", "lancet", or "jama". Changing it resets palette-derived colors;
#'   explicit color arguments in the same call take precedence. No arguments
#'   leaves settings unchanged; use acl_theme_reset() to reset.
#' @param point_color,observed_color,smooth_color,hline_color Character or NULL.
#'   Default point, observation, smoother and reference-line colors.
#' @param low_col,high_col Character or NULL. Continuous heatmap endpoints.
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
#' @param ... The former argument name compare_linewidth, accepted with a warning.
#' @return Invisible previous settings. Save these or the result of acl_theme(),
#'   then restore them with \code{do.call(acl_theme_set, old)}.
#' @export
#' @examples
#' # --- Set just one thing ---
#' # The first call returns the previous settings, which are restored at the end.
#' old <- acl_theme_set(base_theme = "theme_classic")
#' acl_theme_set(font_family = "Times New Roman")
#' acl_theme_set(compare_line_size = 2)
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
                          low_col = NULL, high_col = NULL, ..., interval = NULL) {

  current <- acl_theme()
  old <- current
  renamed <- .acl_renamed(list(...), "acl_theme_set")
  if (is.null(compare_line_size)) compare_line_size <- renamed$compare_line_size
  if (!is.null(titles)) titles <- .acl_renamed_titles(titles)
  if (!is.null(palette)) {
    palette <- match.arg(tolower(palette), c("npg", "aaas", "nejm", "lancet", "jama"))
    current <- utils::modifyList(current, .acl_palette_roles(palette))
  }
  for (key in c("point_color", "observed_color", "smooth_color", "hline_color", "low_col", "high_col")) {
    value <- get(key)
    if (!is.null(value)) current[[key]] <- value
  }

  # Reject settings that no plot could use, before any of them is stored.
  if (!is.null(base_theme)) .acl_theme_name(base_theme, "base_theme")
  if (!is.null(interval)) interval <- .acl_interval_type(interval)
  for (key in c("compare_colors", "compare_linetypes")) {
    value <- get(key)
    if (!is.null(value) && length(value) < 2L)
      stop(key, " must contain two values, one per model; it has ", length(value),
           ". Supply both, for example c(\"", if (key == "compare_colors")
             "steelblue\", \"tomato" else "solid\", \"dashed", "\").", call. = FALSE)
  }

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
  if (!is.null(compare_facet_ncol))   current$compare_facet_ncol   <- compare_facet_ncol
  if (!is.null(compare_facet_scales)) current$compare_facet_scales <- compare_facet_scales
  if (!is.null(titles))               current$titles               <- modifyList(current$titles, titles)
  if (!is.null(xlab))                 current$xlab                 <- modifyList(current$xlab, xlab)
  if (!is.null(ylab))                 current$ylab                 <- modifyList(current$ylab, ylab)

  options(acl.theme = current)
  invisible(old)
}


#' Reset ALSCL Plot Theme to Defaults
#'
#' Restores every theme setting to the package default and reports this with
#' a message, which \code{suppressMessages()} silences.
#'
#' @return \code{NULL}, invisibly.
#' @export
#' @examples
#' acl_theme_reset()
acl_theme_reset <- function() {
  options(acl.theme = .acl_defaults)
  message("ALSCL plot theme reset to defaults.")
  invisible(NULL)
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

#' Build the standard ALSCL ggplot theme layer
#' @keywords internal
.acl_base_theme <- function(font_family = NULL, title_size = NULL,
                            axis_title_size = NULL, axis_text_size = NULL,
                            strip_text_size = NULL, legend_text_size = NULL,
                            base_theme = NULL, title_hjust = NULL) {
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

  list(
    theme_fn(),
    ggplot2::theme(
      # All plot families share these defaults, including helpers that call
      # acl_get_theme(). Later user-supplied theme layers can restore grids.
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      text             = ggplot2::element_text(family = ff),
      plot.title       = ggplot2::element_text(size = ts, hjust = th),
      axis.title       = ggplot2::element_text(size = ats),
      axis.text        = ggplot2::element_text(size = atx),
      strip.text       = ggplot2::element_text(size = sts),
      legend.text      = ggplot2::element_text(size = lts),
      legend.title     = ggplot2::element_text(size = lts)
    )
  )
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
    name <- if (startsWith(x, "theme_")) x else paste0("theme_", x)
    if (name %in% .acl_theme_names) return(name)
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
#' \code{auto_breaks}, or pretty breaks when that is NULL.
#' @param x_breaks Breaks given in the plot call, or NULL.
#' @param n_breaks Target number of automatic breaks.
#' @param values Numeric x coordinates of the plot, or NULL when unknown.
#' @param auto_breaks Numeric vector of automatic breaks, or NULL.
#' @param labels Labels or labelling function passed to the scale.
#' @param check_overlap Logical. Omit automatic tick labels that would
#'   overprint in narrow facets.
#' @keywords internal
.acl_scale_x <- function(x_breaks = NULL, n_breaks = 10, values = NULL,
                         auto_breaks = NULL, labels = ggplot2::waiver(),
                         check_overlap = FALSE) {
  brks <- if (!is.null(x_breaks)) x_breaks else
    .acl_global_breaks(values)
  expd <- acl_theme("x_expand")
  if (is.null(expd)) expd <- c(0.01, 0.01)
  automatic <- is.null(brks)
  if (automatic)
    brks <- if (is.null(auto_breaks)) scales::pretty_breaks(n = n_breaks) else auto_breaks
  ggplot2::scale_x_continuous(
    breaks = brks, labels = labels,
    expand = ggplot2::expansion(mult = expd),
    guide = if (automatic && check_overlap)
      ggplot2::guide_axis(check.overlap = TRUE) else ggplot2::waiver()
  )
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
  columns <- if (is.null(facet_ncol)) ggplot2::wrap_dims(max(1L, n_panels))[2L] else facet_ncol
  if (!is.numeric(columns) || length(columns) != 1L || !is.finite(columns) || columns < 1)
    return(max_breaks)
  as.integer(max(2, min(max_breaks, floor(budget / columns))))
}


# Apply the same typography to a patchwork's outer title and panel titles.
.acl_annotation_theme <- function(legend_pos) {
  ggplot2::theme(
    text = ggplot2::element_text(family = acl_theme("font_family")),
    plot.title = ggplot2::element_text(size = acl_theme("title_size"),
                                     hjust = acl_theme("title_hjust")),
    legend.position = legend_pos)
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
    line_size  = if (!is.null(line_size))  line_size  else (acl_theme("compare_line_size")  %||% 1.2),
    point_size = point_size %||% acl_theme("compare_point_size") %||% acl_theme("point_size") %||% 2.5,
    se_alpha   = if (!is.null(se_alpha))   se_alpha   else (acl_theme("compare_se_alpha")   %||% 0.15),
    legend_pos = if (!is.null(legend_pos)) legend_pos else (acl_theme("compare_legend_pos") %||% "bottom"),
    facet_ncol = if (!is.null(facet_ncol)) facet_ncol else (acl_theme("compare_facet_ncol") %||% 2),
    facet_scales = if (!is.null(facet_scales)) facet_scales else (acl_theme("compare_facet_scales") %||% "free_y")
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
# drops "Year" for axes whose title already names the unit.
.acl_time_labels <- function(times, step = NULL, prefix = TRUE) {
  times <- as.numeric(times)
  if (all(abs(times - round(times)) < 1e-8)) {
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

# Keep error recovery consistent with the normal grid-free plot defaults.
.acl_plot_theme <- function() {
  tryCatch(acl_get_theme(), error = function(e) {
    ggplot2::theme_bw() + ggplot2::theme(
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank())
  })
}
