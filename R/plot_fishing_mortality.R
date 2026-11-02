#' @title Plot Fishing Mortality from ACL or ALSCL Model
#'
#' @description This function takes the output from \code{run_acl} or \code{run_alscl}
#' and plots fishing mortality over years, ages, or length-bin midpoints using ggplot2.
#' For ACL models, F is at the age level (A x Y).
#' For ALSCL models, F is at the length level (FL: L x Y) and
#' F-at-age (FA: (A-1) x (Y-1)) is derived from F at length.
#'
#' @param model_result A list obtained from \code{run_acl} or \code{run_alscl}.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting (default 1.5).
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. The type of the line. Default is "solid".
#' @param se Logical. Whether to plot confidence intervals. Default is FALSE.
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_alpha Numeric or NULL. NULL inherits the global se_alpha setting (default 0.2).
#' @param se_type Character. "ribbon" or "errorbar". Default is "ribbon".
#' @param facet_ncol Integer. The number of columns in facet_wrap.
#' @param facet_scales Character. Scales for facet_wrap. Default is "free".
#' @param type Character. Which dimension of F runs along the x axis: "year"
#'   (one panel per age or length group), "age" (one panel per time step) or
#'   "length" (ALSCL only: one panel per time step with the numeric length-bin
#'   midpoints in \code{model_result$len_mid} on the x axis; for ACL a legacy
#'   alias for "age", with a warning). Default is "year". Time-step panels are
#'   labelled "Year 2000", or "2000 Q2" for quarterly fits.
#' @param return_data Logical. Whether to return data alongside the plot. Default is FALSE.
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks; NULL inherits
#'   the global x_breaks setting. Expansion follows global x_expand.
#' @param title Character or NULL. Custom plot title; NULL inherits the global
#'   F_year, F_age or F_length title, with _se appended for interval plots.
#' @param xlab Character or NULL. Custom x-axis label; NULL inherits the global
#'   year, age or length label. Uncustomized age axes are labeled Age group
#'   because the plotted coordinates are group positions.
#' @param ylab Character or NULL. Custom y-axis label; NULL inherits global ylab$F.
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
#' @return A ggplot object, or a list with plot and data if return_data = TRUE.
#' @details Matrix positions are matched to fitted time and group metadata;
#'   optional matrix dimnames do not replace these coordinates. Intervals require
#'   one finite estimate and finite nonnegative standard error per plotted cell.
#'   Use se = FALSE for saved fits without a complete uncertainty table.
#'
#' @export
plot_fishing_mortality <- function(model_result, line_size = NULL, line_color = NULL, line_type = "solid", facet_ncol = NULL,
                                   facet_scales = "free", se = FALSE, se_color = NULL, se_alpha = NULL, se_type = "ribbon",
                                   type = c("year", "age", "length"), return_data = FALSE,
                                   x_breaks = NULL, title = NULL, xlab = NULL, ylab = NULL,
                                   font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
                                   strip_text_size = NULL, legend_text_size = NULL, base_theme = NULL,
                                   title_hjust = NULL) {
  # NULL inherits the global palette.
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")
  if (is.null(se_alpha)) se_alpha <- acl_theme("se_alpha")


  type <- match.arg(type)
  se_type <- match.arg(se_type, c("ribbon", "errorbar"))
  .acl_check_flag(se, "se")

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

  # ===================================================================
  # ALSCL model: FL (L x Y) and FA ((A-1) x (Y-1))
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

      FL_long <- reshape2::melt(FL)
      colnames(FL_long) <- c("Group", "YearIdx", "F")
      FL_long$Year <- Year[FL_long$YearIdx]
      FL_long$Period <- .acl_period_factor(FL_long$Year, Year)
      if (type == "length") FL_long$Length <- len_mid[FL_long$Group]
      FL_long$Group <- GroupLabels[FL_long$Group]

      facet_by <- if (type == "length") ~Period else ~Group

      if (!se) {
        mapping <- if (type == "length") ggplot2::aes(x = Length, y = F) else ggplot2::aes(x = Year, y = F)
        p <- ggplot2::ggplot(FL_long, mapping) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
          ggplot2::facet_wrap(facet_by, ncol = facet_ncol, scales = facet_scales)
        data_out <- FL_long
      } else {
        est_std <- model_result[["est_std"]]
        rows <- which(rownames(est_std) == "FL")
        if (length(rows) != length(FL) || !all(c("Estimate", "Std. Error") %in% colnames(est_std))) {
          stop("se = TRUE requires one FL estimate and standard error for every length-by-time cell in est_std.")
        }
        ss_fl <- .acl_plot_estimates(model_result, "FL", length(FL))

        ci <- data.frame(
          Group    = rep(GroupLabels, times = ncol(FL)),
          Year     = rep(Year, each = nrow(FL)),
          estimate = ss_fl[, "Estimate"],
          lower    = ss_fl[, "Estimate"] - 1.96 * ss_fl[, "Std. Error"],
          upper    = ss_fl[, "Estimate"] + 1.96 * ss_fl[, "Std. Error"]
        )
        if (type == "length") ci$Length <- rep(len_mid, times = ncol(FL))
        ci$Period <- .acl_period_factor(ci$Year, Year)

        mapping <- if (type == "length") ggplot2::aes(x = Length, y = estimate) else ggplot2::aes(x = Year, y = estimate)
        p <- ggplot2::ggplot(ci, mapping) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)

        if (se_type == "ribbon") {
          p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
        } else {
          p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color, alpha = se_alpha, width = 0.3)
        }
        p <- p + ggplot2::facet_wrap(facet_by, ncol = facet_ncol, scales = facet_scales)
        data_out <- ci
      }

    } else if (type == "age") {
      # --- Emergent F at age (FA), faceted by year ---
      FA <- checked_matrix("FA", length(Year) - 1L)
      fa_years <- head(Year, -1L)

      FA_long <- reshape2::melt(FA)
      colnames(FA_long) <- c("AgeGroup", "YearIdx", "F")
      FA_long$Year <- fa_years[FA_long$YearIdx]
      FA_long$Period <- .acl_period_factor(FA_long$Year, fa_years)


      if (!se) {
        p <- ggplot2::ggplot(FA_long, ggplot2::aes(x = AgeGroup, y = F)) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
          ggplot2::facet_wrap(~Period, ncol = facet_ncol, scales = facet_scales)
        data_out <- FA_long
      } else {
        ss_fa <- .acl_plot_estimates(model_result, "FA", length(FA))

        ci <- data.frame(
          AgeGroup = rep(seq_len(nrow(FA)), times = ncol(FA)),
          Year     = rep(fa_years, each = nrow(FA)),
          estimate = ss_fa[, "Estimate"],
          lower    = ss_fa[, "Estimate"] - 1.96 * ss_fa[, "Std. Error"],
          upper    = ss_fa[, "Estimate"] + 1.96 * ss_fa[, "Std. Error"]
        )
        ci$AgeGroup <- as.numeric(ci$AgeGroup)
        ci$Period <- .acl_period_factor(ci$Year)

        p <- ggplot2::ggplot(ci, ggplot2::aes(x = AgeGroup, y = estimate)) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)

        if (se_type == "ribbon") {
          p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
        } else {
          p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color, alpha = se_alpha, width = 0.3)
        }
        p <- p + ggplot2::facet_wrap(~Period, ncol = facet_ncol, scales = facet_scales)
        data_out <- ci
      }
    }

  # ===================================================================
  # ACL model: F (A x Y)
  # ===================================================================
  } else {

    Fmat <- checked_matrix("F", length(Year))

    if (type == "year") {
      AgeGroup <- factor(paste("Age bin", seq_len(nrow(Fmat))), levels = paste("Age bin", seq_len(nrow(Fmat))))

      F_long <- reshape2::melt(Fmat)
      colnames(F_long) <- c("AgeGroup", "Year", "F")
      F_long$Year <- Year[as.numeric(F_long$Year)]
      F_long$Period <- .acl_period_factor(F_long$Year, Year)
      F_long$AgeGroup <- AgeGroup[as.numeric(F_long$AgeGroup)]


      if (!se) {
        p <- ggplot2::ggplot(F_long, ggplot2::aes(x = Year, y = F)) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
          ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
        data_out <- F_long
      } else {
        ss_f <- .acl_plot_estimates(model_result, "F", length(Fmat))

        ci <- data.frame(
          AgeGroup = rep(AgeGroup, times = ncol(Fmat)),
          Year     = rep(Year, each = nrow(Fmat)),
          estimate = ss_f[, "Estimate"],
          lower    = ss_f[, "Estimate"] - 1.96 * ss_f[, "Std. Error"],
          upper    = ss_f[, "Estimate"] + 1.96 * ss_f[, "Std. Error"]
        )

        p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)

        if (se_type == "ribbon") {
          p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
        } else {
          p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color, alpha = se_alpha, width = 0.3)
        }
        p <- p + ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
        data_out <- ci
      }

    } else {
      # type == "age" for ACL: faceted by year
      F_long <- reshape2::melt(Fmat)
      colnames(F_long) <- c("AgeGroup", "Year", "F")
      F_long$Year <- Year[as.numeric(F_long$Year)]
      F_long$Period <- .acl_period_factor(F_long$Year, Year)


      if (!se) {
        p <- ggplot2::ggplot(F_long, ggplot2::aes(x = AgeGroup, y = F)) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
          ggplot2::facet_wrap(~Period, ncol = facet_ncol, scales = facet_scales)
        data_out <- F_long
      } else {
        ss_f <- .acl_plot_estimates(model_result, "F", length(Fmat))

        ci <- data.frame(
          AgeGroup = rep(seq_len(nrow(Fmat)), times = ncol(Fmat)),
          Year     = rep(Year, each = nrow(Fmat)),
          estimate = ss_f[, "Estimate"],
          lower    = ss_f[, "Estimate"] - 1.96 * ss_f[, "Std. Error"],
          upper    = ss_f[, "Estimate"] + 1.96 * ss_f[, "Std. Error"]
        )
        ci$AgeGroup <- as.numeric(ci$AgeGroup)
        ci$Period <- .acl_period_factor(ci$Year)

        p <- ggplot2::ggplot(ci, ggplot2::aes(x = AgeGroup, y = estimate)) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)

        if (se_type == "ribbon") {
          p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
        } else {
          p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color, alpha = se_alpha, width = 0.3)
        }
        p <- p + ggplot2::facet_wrap(~Period, ncol = facet_ncol, scales = facet_scales)
        data_out <- ci
      }
    }
  }

  # ===== Apply labels and theme =====
  title_key <- paste0("F_", type, if (se) "_se" else "")
  axis_label <- .acl_lab("x", type)
  if (type == "age" && identical(axis_label, .acl_defaults$xlab$age))
    axis_label <- "Age group"
  p <- p +
    ggplot2::labs(
      title = if (!is.null(title)) title else .acl_title(title_key),
      x     = if (!is.null(xlab)) xlab else axis_label,
      y     = if (!is.null(ylab)) ylab else .acl_lab("y", "F")
    ) +
    .acl_scale_x(x_breaks, n_breaks = 5) + current_theme

  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}
