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
    SSB     = "Estimated spawning biomass (SSB)",
    SSB_se  = "Estimated spawning biomass (SSB) with 95% CI",
    SBL     = "Estimated spawning biomass at length",
    SBL_se  = "Estimated spawning biomass at length with 95% CI",
    SBA     = "Estimated spawning biomass at age",
    SBA_se  = "Estimated spawning biomass at age with 95% CI",

    # plot_recruitment
    Rec     = "Estimated recruitment (R)",
    Rec_se  = "Estimated recruitment (R) with 95% CI",

    # plot_SSB_Rec
    SSB_Rec = "Spawning biomass and recruitment",

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

    # plot_VB
    VB      = "Von Bertalanffy growth curve",

    # plot_ridges
    CatL_obs_length = "Observed survey length composition over time",
    CatL_est_length = "Fitted survey length composition over time",
    ridges   = "Observed and fitted survey length compositions",

    # plot_CatL: one panel per length bin, or one panel per time step
    CatL_by_length = "Fitted (line) and observed (point) survey indices over time",
    CatL_by_year   = "Fitted and observed survey indices at length",

    # plot_residuals
    resid_length = "Residuals by length bin",
    resid_year   = "Residuals by year",

    # plot_retro; the model type is appended in parentheses
    retro    = "Retrospective analysis",

    # plot_pla
    pla      = "Age-length probability matrix",

    # Comparison plot titles
    compare_ts      = "{m1} vs {m2}",
    compare_F       = "Fishing mortality comparison",
    compare_resid   = "Residual diagnostics: {m1} vs {m2}",
    compare_growth  = "Growth comparison",
    compare_CatL    = "Observed and fitted survey indices at length",
    compare_metrics = "Model fit comparison: {m1} vs {m2}",
    compare_sel     = "Survey catchability at length",
    compare_F_ts    = "Fishing mortality by time step"
  ),

  # --- Axis labels ---------------------------------------------------------
  xlab = list(
    year   = "Year",
    age    = "Age",
    length = "Length",
    ssb    = "SSB"
  ),

  ylab = list(
    year      = "Year",
    abundance = "Abundance",
    biomass   = "Biomass",
    ssb       = "SSB",
    rec       = "Recruitment",
    catch     = "Catch numbers",
    survey    = NULL, # NULL preserves legacy custom abundance labels for survey plots.
    F         = "Fishing mortality",
    dev_R     = "Log recruitment deviation",
    dev_F     = "Log fishing mortality deviation",
    dev_R_multiplier = "Recruitment multiplier",
    dev_F_multiplier = "Fishing mortality multiplier",
    residual  = "Residual",
    growth    = "Length",
    length    = "Length"
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
#' @param base_theme Character. Base ggplot2 theme name.
#' @param font_family Character. Font family for all text.
#' @param title_size Numeric. Plot title size in pt.
#' @param title_hjust Numeric. Title alignment (0=left, 0.5=center, 1=right).
#' @param axis_title_size Numeric. Axis title size.
#' @param axis_text_size Numeric. Axis tick label size.
#' @param strip_text_size Numeric. Facet label size.
#' @param legend_text_size Numeric. Legend text size.
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks. Pass NULL
#'   explicitly to restore automatically selected breaks; omitting the argument
#'   leaves the current setting unchanged.
#' @param x_expand Numeric vector of length 2. X-axis expansion.
#' @param line_color Character. Default line color for single-model plots.
#' @param line_size Numeric. Default line width for single-model plots (1.5).
#'   Plot arguments set to NULL inherit this value; explicit widths take priority.
#' @param point_size Numeric. Default point size for all point plots (2.5).
#'   Plot arguments set to NULL inherit this value unless a comparison-specific
#'   override is set. Explicit per-call sizes take priority.
#' @param se_color Character. Default CI color.
#' @param se_alpha Numeric. Default CI transparency (0.2).
#'   Plot arguments set to NULL inherit this value; explicit alpha takes priority.
#' @param compare_colors Character vector of 2 colors. Can be unnamed (positional)
#'   or named. The first color is always model1, second is model2.
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
#' @param ylab Named list. Override specific y-axis labels. The survey key
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
#' acl_theme_set(base_theme = "theme_classic")
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
                          low_col = NULL, high_col = NULL, ...) {

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

  if (!is.null(base_theme))           current$base_theme           <- base_theme
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
#' @export
#' @examples
#' acl_theme_reset()
acl_theme_reset <- function() {
  options(acl.theme = .acl_defaults)
  cat("ALSCL plot theme reset to defaults.\n")
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

  if (!startsWith(bt, "theme_")) bt <- paste0("theme_", bt)
  theme_fn <- switch(bt,
                     "theme_bw"        = ggplot2::theme_bw,
                     "theme_minimal"   = ggplot2::theme_minimal,
                     "theme_classic"   = ggplot2::theme_classic,
                     "theme_gray"      = ggplot2::theme_gray,
                     "theme_grey"      = ggplot2::theme_grey,
                     "theme_light"     = ggplot2::theme_light,
                     "theme_linedraw"  = ggplot2::theme_linedraw,
                     "theme_dark"      = ggplot2::theme_dark,
                     "theme_void"      = ggplot2::theme_void,
                     ggplot2::theme_bw
  )

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


#' Build x-axis scale with breaks and expand
#' @keywords internal
.acl_scale_x <- function(x_breaks = NULL, n_breaks = 10) {
  brks <- if (!is.null(x_breaks)) x_breaks else acl_theme("x_breaks")
  expd <- acl_theme("x_expand")
  if (is.null(expd)) expd <- c(0.01, 0.01)

  if (is.null(brks)) {
    ggplot2::scale_x_continuous(
      breaks = scales::pretty_breaks(n = n_breaks),
      expand = ggplot2::expansion(mult = expd)
    )
  } else {
    ggplot2::scale_x_continuous(
      breaks = brks,
      expand = ggplot2::expansion(mult = expd)
    )
  }
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
    # Priority 1: per-call argument
    val <- user_val
    # Priority 2: global theme
    if (is.null(val)) val <- acl_theme(theme_key)
    # Priority 3: fallback
    if (is.null(val) || length(val) < 2) val <- fallback

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
  LengthGroup <- len_label
  n_bins <- length(LengthGroup)
  if (n_bins >= 2) {
    first_parts <- strsplit(as.character(LengthGroup[1]), "-")[[1]]
    last_parts  <- strsplit(as.character(LengthGroup[n_bins]), "-")[[1]]
    if (length(first_parts) == 2) LengthGroup[1] <- paste0("<", first_parts[2])
    if (length(last_parts)  == 2) LengthGroup[n_bins] <- paste0(">", last_parts[1])
  }
  paste(prefix, LengthGroup)
}


# Facet strips for time steps: "Year 2000" for annual labels, "2000 Q2" for
# quarterly labels, otherwise the time label itself.
.acl_time_labels <- function(times) {
  times <- as.numeric(times)
  if (all(abs(times - round(times)) < 1e-8))
    return(paste("Year", format(round(times), trim = TRUE)))
  quarters <- (times - floor(times + 1e-8)) / 0.25
  on_grid <- all(abs(quarters - round(quarters)) < 1e-6)
  if (on_grid && any(abs(round(quarters) - 1) < 1e-6 | abs(round(quarters) - 3) < 1e-6))
    return(sprintf("%d Q%d", as.integer(floor(times + 1e-8)), as.integer(round(quarters)) + 1L))
  as.character(times)
}

# Factor of time-step labels in time order, for facet_wrap().
.acl_period_factor <- function(values, times = sort(unique(values))) {
  labels <- .acl_time_labels(times)
  factor(labels[match(values, times)], levels = labels)
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
