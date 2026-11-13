#' @title Plot Fishing Mortality from ACL or ALSCL Model
#'
#' @description This function takes the output from \code{run_acl} or \code{run_alscl}
#' and plots the fishing mortality rate (F) over time steps, ages, or length-bin
#' midpoints using ggplot2. F is an instantaneous rate per model time step:
#' per year for annual fits and per quarter for quarterly fits. The default
#' y-axis label states this time basis.
#' For ACL models, F is at the age level (A x Y).
#' For ALSCL models, F is at the length level (FL: L x Y) and
#' F at age (FA: A x Y) is the negative log of the proportion
#' surviving within each age class over the time step, minus natural mortality.
#' Fits made by earlier versions hold FA without the plus group and without
#' the last period; both forms are drawn. F in the last period is predicted
#' by the F process and is not informed by observations.
#'
#' @param model_result A list obtained from \code{run_acl} or \code{run_alscl}.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting (default 1.5).
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. The type of the line. Default is "solid".
#' @param se Logical. Whether to plot confidence intervals. Default is FALSE.
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_alpha Numeric or NULL. Transparency of the interval ribbon; NULL inherits the
#'   global se_alpha setting (default 0.2). Error bars are opaque unless se_alpha is given.
#' @param se_type Character. "ribbon" or "errorbar". Default is "ribbon".
#' @param interval Character or NULL. The 95% interval drawn when \code{se = TRUE}.
#'   \code{"lognormal"} is \code{exp(log(estimate) +/- 1.96 * SE / estimate)} and
#'   stays above zero (an estimate of exactly zero keeps the Wald upper bound
#'   with the lower bound at zero). \code{"wald"} is \code{estimate +/- 1.96 * SE} and can
#'   fall below zero. NULL inherits the global \code{interval} setting (default
#'   "lognormal"). Point estimates are the same for both. An estimate that is
#'   not positive, which can occur for ALSCL F at age because it is derived as
#'   total mortality minus natural mortality, keeps the Wald bounds.
#' @param facet_ncol Integer. The number of columns in facet_wrap.
#' @param facet_scales Character. Scales for facet_wrap. Default is "free".
#' @param type Character. Which dimension of F runs along the x axis: "year"
#'   (one panel per age or length group), "age" (one panel per time step) or
#'   "length" (ALSCL only: one panel per time step with the numeric length-bin
#'   midpoints in \code{model_result$len_mid} on the x axis; for ACL a legacy
#'   alias for "age", with a warning). Default is "year". Time-step panels are
#'   labelled "Year 2000", or "2000 Q2" for quarterly fits.
#' @param return_data Logical. Whether to return data alongside the plot. Default is FALSE.
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks. NULL inherits
#'   the global x_breaks setting when at least one of its values lies on this
#'   axis; otherwise the breaks are chosen automatically. Expansion follows
#'   global x_expand.
#' @param title Character or NULL. Custom plot title; NULL inherits the global
#'   F_year, F_age or F_length title, with _se appended for interval plots.
#' @param xlab Character or NULL. Custom x-axis label; NULL inherits the global
#'   year, age or length label. Results saved without age metadata are plotted
#'   against group positions, and their uncustomized age axis is labeled Age group.
#' @param ylab Character or NULL. Custom y-axis label; NULL inherits global ylab$F.
#'   The default label gains the time basis of the fit, for example
#'   "Fishing mortality rate (per year)".
#' @param font_family Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans").
#' @param title_size Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14).
#' @param axis_title_size Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12).
#' @param axis_text_size Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10).
#' @param strip_text_size Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10).
#' @param legend_text_size Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10).
#' @param title_hjust Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting.
#' @param base_theme A ggplot2 theme object, a supported theme name such as
#'   "bw" or "theme_bw", or NULL to use the global theme. Non-grid layout
#'   settings in theme objects are retained; typography follows the global
#'   settings and the explicit typography arguments. Major and minor
#'   grids are removed for every base theme.
#'
#' @details A group or panel with only one estimate is drawn as a point.
#'   When intervals are requested, its ribbon is replaced by an error bar.
#'   The point uses the global point_size setting and the estimate's line colour.
#' @details Age axes and age panels use the fitted ages in \code{model_result$age}.
#'   The oldest age class of an ACL fit is a plus group and is marked with a
#'   plus sign, for example "Age 15+" or the tick label "15+". ALSCL F at age
#'   includes the plus group, except in fits made by earlier versions. With \code{return_data = TRUE} and \code{type = "age"}, the
#'   data keep the group position in \code{AgeGroup} and add the fitted age in
#'   \code{Age}.
#' @details When F is shared across groups (\code{F_structure = "year"}), every
#'   group has the same series. \code{type = "year"} then draws one panel
#'   labelled "Shared F" instead of one identical panel per group. The returned
#'   data still hold every group.
#' @return A ggplot object, or a list with plot and data if return_data = TRUE.
#' @details Matrix positions are matched to fitted time and group metadata;
#'   optional matrix dimnames do not replace these coordinates. Intervals require
#'   one finite estimate and finite nonnegative standard error per plotted cell.
#'   Use se = FALSE for saved fits without a complete uncertainty table.
#'
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#'
#' # Fishing mortality rate over time, one panel per age
#' plot_fishing_mortality(fit)
#'
#' # Fishing mortality rate at age, one panel per year
#' plot_fishing_mortality(fit, type = "age")
#' }
#' @export
plot_fishing_mortality <- function(model_result, line_size = NULL, line_color = NULL, line_type = "solid", facet_ncol = NULL,
                                   facet_scales = "free", se = FALSE, se_color = NULL, se_alpha = NULL, se_type = "ribbon",
                                   type = c("year", "age", "length"), return_data = FALSE,
                                   x_breaks = NULL, title = NULL, xlab = NULL, ylab = NULL,
                                   font_family = NULL, title_size = NULL, base_theme = NULL,
                                   axis_title_size = NULL, axis_text_size = NULL,
                                   strip_text_size = NULL, legend_text_size = NULL,
                                   title_hjust = NULL, interval = NULL) {
  # NULL inherits the global palette.
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")
  # Error bars are thin lines: draw them opaque unless the call sets se_alpha.
  errorbar_alpha <- if (is.null(se_alpha)) 1 else se_alpha
  if (is.null(se_alpha)) se_alpha <- acl_theme("se_alpha")


  type <- match.arg(type)
  se_type <- match.arg(se_type, c("ribbon", "errorbar"))
  .acl_check_flag(se, "se")
  interval <- .acl_interval_type(interval)
  time_step <- model_result$growth_step

  # Detect model type: ACL has report$F, ALSCL has report$FL
  is_alscl <- is.null(model_result[["report"]][["F"]]) && !is.null(model_result[["report"]][["FL"]])
  if (!is_alscl && type == "length") {
    warning("ACL has no length-specific F; type = 'length' is a legacy alias for 'age'.",
            call. = FALSE)
    type <- "age"
  }

  Year <- .acl_plot_year(model_result)
  # Plot coordinates come from matrix positions, not optional row/column names.
  checked_matrix <- function(name, periods) {
    value <- model_result$report[[name]]
    if (!is.matrix(value) || !is.numeric(value) || !nrow(value) ||
        ncol(value) != periods || !length(value) || any(!is.finite(value)))
      stop("report$", name, " must be a finite numeric group-by-time matrix with ",
           periods, " time columns.", call. = FALSE)
    dimnames(value) <- NULL
    value
  }

  # Retain the existing theme-object interface and also accept the theme names
  # used by the other plot functions. Resolve typography through the shared layer.
  theme_object <- inherits(base_theme, "theme")
  if (!is.null(base_theme) && !theme_object &&
      (!is.character(base_theme) || length(base_theme) != 1L ||
       is.na(base_theme) || !nzchar(base_theme)))
    stop("base_theme must be a ggplot2 theme object, a theme name, or NULL.", call. = FALSE)
  common_theme <- .acl_base_theme(font_family = font_family, title_size = title_size,
    axis_title_size = axis_title_size, axis_text_size = axis_text_size,
    strip_text_size = strip_text_size, legend_text_size = legend_text_size,
    base_theme = if (theme_object) "bw" else base_theme, title_hjust = title_hjust)
  current_theme <- if (theme_object) list(base_theme, common_theme[[2L]]) else common_theme
  if (theme_object) {
    text_elements <- names(base_theme)[vapply(base_theme, inherits, logical(1), "element_text")]
    family <- if (is.null(font_family)) acl_theme("font_family") else font_family
    if (length(text_elements)) current_theme <- c(current_theme, list(do.call(ggplot2::theme,
      stats::setNames(lapply(text_elements, function(x) ggplot2::element_text(family = family)),
                      text_elements))))
  }
  current_theme <- c(current_theme, list(ggplot2::theme(
    panel.grid.major = ggplot2::element_blank(), panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major.x = ggplot2::element_blank(), panel.grid.major.y = ggplot2::element_blank(),
    panel.grid.minor.x = ggplot2::element_blank(), panel.grid.minor.y = ggplot2::element_blank())))

  # One panel is enough when F is shared across groups (F_structure = "year"):
  # every row of the reported matrix then holds the same time series.
  shared_rows <- function(value) {
    identical(model_result$F_structure, "year") && nrow(value) > 1L &&
      isTRUE(all.equal(value, matrix(value[1L, ], nrow(value), ncol(value), byrow = TRUE),
                       tolerance = 1e-10))
  }
  one_shared_panel <- function(data, group) {
    data <- data[data[[group]] == levels(data[[group]])[1L], , drop = FALSE]
    data[[group]] <- factor("Shared F")
    data
  }
  # Estimate line, optional interval and facets. The returned data keep
  # every group; plot_data may hold the single shared series.
  draw <- function(plot_data, x, y, facet) {
    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = !!as.name(x), y = !!as.name(y))) +
      ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
    if (se) p <- p + if (se_type == "ribbon")
      ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) else
      ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color,
                             alpha = errorbar_alpha, width = 0.3)
    p + ggplot2::facet_wrap(facet, ncol = facet_ncol, scales = facet_scales)
  }
  interval_table <- function(name, n) {
    ss <- .acl_plot_estimates(model_result, name, n)
    bounds <- .acl_interval(ss[, "Estimate"], ss[, "Std. Error"], interval)
    list(estimate = ss[, "Estimate"], lower = bounds$lower, upper = bounds$upper)
  }
  ages <- NULL       # fitted ages on a numeric age axis
  plus_age <- NULL   # age of the plus group when the axis includes it

  # ===================================================================
  # ALSCL model: FL (L x Y) and FA (A x Y; (A-1) x (Y-1) in older fits)
  # ===================================================================
  if (is_alscl) {

    if (type == "year" || type == "length") {
      # --- F at length, faceted by length bin or year ---
      FL <- checked_matrix("FL", length(Year))
      len_label <- model_result[["len_label"]]
      if (is.null(len_label)) len_label <- paste0("L", seq_len(nrow(FL)))
      if (length(len_label) != nrow(FL) || anyNA(len_label) ||
          any(!nzchar(as.character(len_label))) || anyDuplicated(len_label))
        stop("len_label must identify the rows of report$FL uniquely.")

      if (type == "length") {
        len_mid <- model_result[["len_mid"]]
        if (!is.numeric(len_mid) || length(len_mid) != nrow(FL) || any(!is.finite(len_mid))) {
          stop("type = 'length' requires finite numeric len_mid values matching the rows of report$FL.")
        }
      }

      GroupLabels <- .acl_fix_len_labels(len_label, prefix = "Length")
      GroupLabels <- factor(GroupLabels, levels = GroupLabels)

      if (!se) {
        FL_long <- .acl_matrix_long(FL, c("Group", "YearIdx", "F"))
        FL_long$Year <- Year[FL_long$YearIdx]
        FL_long$Period <- .acl_period_factor(FL_long$Year, Year, time_step)
        if (type == "length") FL_long$Length <- len_mid[FL_long$Group]
        FL_long$Group <- GroupLabels[FL_long$Group]
        data_out <- FL_long
      } else {
        est_std <- model_result[["est_std"]]
        rows <- which(rownames(est_std) == "FL")
        if (length(rows) != length(FL) || !all(c("Estimate", "Std. Error") %in% colnames(est_std))) {
          stop("se = TRUE requires one FL estimate and standard error for every length-by-time cell in est_std.")
        }
        ss_fl <- interval_table("FL", length(FL))

        ci <- data.frame(
          Group    = rep(GroupLabels, times = ncol(FL)),
          Year     = rep(Year, each = nrow(FL)),
          estimate = ss_fl$estimate,
          lower    = ss_fl$lower,
          upper    = ss_fl$upper
        )
        if (type == "length") ci$Length <- rep(len_mid, times = ncol(FL))
        ci$Period <- .acl_period_factor(ci$Year, Year, time_step)
        data_out <- ci
      }
      plot_data <- if (type == "year" && shared_rows(FL)) one_shared_panel(data_out, "Group") else data_out
      x_name <- if (type == "length") "Length" else "Year"
      p <- draw(plot_data, x_name, if (se) "estimate" else "F",
                if (type == "length") ~Period else ~Group)

    } else if (type == "age") {
      # --- Emergent F at age (FA), faceted by year ---
      # Current fits report F at age for every age and period. Fits made by
      # earlier versions have no plus-group row and no last period.
      fa_full <- is.matrix(model_result$report$FA) && ncol(model_result$report$FA) == length(Year)
      FA <- checked_matrix("FA", length(Year) - !fa_full)
      fa_years <- if (fa_full) Year else head(Year, -1L)
      ages <- .acl_fitted_ages(model_result, nrow(FA), plus_group = fa_full)

      if (!se) {
        FA_long <- .acl_matrix_long(FA, c("AgeGroup", "YearIdx", "F"))
        FA_long$Year <- fa_years[FA_long$YearIdx]
        FA_long$Period <- .acl_period_factor(FA_long$Year, fa_years, time_step)
        data_out <- FA_long
      } else {
        ss_fa <- interval_table("FA", length(FA))

        ci <- data.frame(
          AgeGroup = rep(seq_len(nrow(FA)), times = ncol(FA)),
          Year     = rep(fa_years, each = nrow(FA)),
          estimate = ss_fa$estimate,
          lower    = ss_fa$lower,
          upper    = ss_fa$upper
        )
        ci$AgeGroup <- as.numeric(ci$AgeGroup)
        ci$Period <- .acl_period_factor(ci$Year, step = time_step)
        data_out <- ci
      }
      if (!is.null(ages)) data_out$Age <- ages[data_out$AgeGroup]
      if (fa_full && !is.null(ages)) plus_age <- ages[length(ages)]
      x_name <- if (is.null(ages)) "AgeGroup" else "Age"
      p <- draw(data_out, x_name, if (se) "estimate" else "F", ~Period)
    }

  # ===================================================================
  # ACL model: F (A x Y)
  # ===================================================================
  } else {

    Fmat <- checked_matrix("F", length(Year))

    if (type == "year") {
      age_labels <- .acl_age_labels(model_result, nrow(Fmat))
      AgeGroup <- factor(age_labels, levels = age_labels)

      if (!se) {
        F_long <- .acl_matrix_long(Fmat, c("AgeGroup", "Year", "F"))
        F_long$Year <- Year[as.numeric(F_long$Year)]
        F_long$Period <- .acl_period_factor(F_long$Year, Year, time_step)
        F_long$AgeGroup <- AgeGroup[as.numeric(F_long$AgeGroup)]
        data_out <- F_long
      } else {
        ss_f <- interval_table("F", length(Fmat))

        ci <- data.frame(
          AgeGroup = rep(AgeGroup, times = ncol(Fmat)),
          Year     = rep(Year, each = nrow(Fmat)),
          estimate = ss_f$estimate,
          lower    = ss_f$lower,
          upper    = ss_f$upper
        )
        data_out <- ci
      }
      plot_data <- if (shared_rows(Fmat)) one_shared_panel(data_out, "AgeGroup") else data_out
      x_name <- "Year"
      p <- draw(plot_data, x_name, if (se) "estimate" else "F", ~AgeGroup)

    } else {
      # type == "age" for ACL: faceted by year. The last age is the plus group.
      ages <- .acl_fitted_ages(model_result, nrow(Fmat))
      if (!is.null(ages)) plus_age <- ages[length(ages)]

      if (!se) {
        F_long <- .acl_matrix_long(Fmat, c("AgeGroup", "Year", "F"))
        F_long$Year <- Year[as.numeric(F_long$Year)]
        F_long$Period <- .acl_period_factor(F_long$Year, Year, time_step)
        data_out <- F_long
      } else {
        ss_f <- interval_table("F", length(Fmat))

        ci <- data.frame(
          AgeGroup = rep(seq_len(nrow(Fmat)), times = ncol(Fmat)),
          Year     = rep(Year, each = nrow(Fmat)),
          estimate = ss_f$estimate,
          lower    = ss_f$lower,
          upper    = ss_f$upper
        )
        ci$AgeGroup <- as.numeric(ci$AgeGroup)
        ci$Period <- .acl_period_factor(ci$Year, step = time_step)
        data_out <- ci
      }
      if (!is.null(ages)) data_out$Age <- ages[data_out$AgeGroup]
      x_name <- if (is.null(ages)) "AgeGroup" else "Age"
      p <- draw(data_out, x_name, if (se) "estimate" else "F", ~Period)
    }
  }

  # ===== Apply labels and theme =====
  title_key <- paste0("F_", type, if (se) "_se" else "")
  axis_label <- .acl_lab("x", type)
  # Without age metadata the coordinates are positions, not ages.
  if (type == "age" && is.null(ages) && identical(axis_label, .acl_defaults$xlab$age))
    axis_label <- "Age group"
  p <- p +
    ggplot2::labs(
      title = if (!is.null(title)) title else .acl_title(title_key),
      x     = if (!is.null(xlab)) xlab else axis_label,
      y     = if (!is.null(ylab)) ylab else .acl_F_label(.acl_rate_basis(model_result))
    ) +
    .acl_scale_x(x_breaks, n_breaks = 5, values = p$data[[x_name]],
      # One panel per time step: fewer age ticks as the columns get narrower.
      auto_breaks = if (is.null(ages)) NULL else .acl_age_breaks(ages,
        .acl_facet_n_breaks(nlevels(p$data$Period), facet_ncol, 5, budget = 20)),
      labels = if (is.null(plus_age)) ggplot2::waiver() else .acl_age_axis_labels(plus_age),
      check_overlap = !is.null(ages)) +
    current_theme

  groups <- if (type == "year")
    if (is_alscl) "Group" else "AgeGroup" else "Period"
  p <- .acl_show_singletons(p, groups)

  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}
