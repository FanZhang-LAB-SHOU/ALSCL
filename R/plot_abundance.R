utils::globalVariables(c("AgeGroup", "LengthGroup", "Count", "number.age"))
#' Plot Abundance over the Years in ACL or ALSCL model
#'
#' This function visualizes fish abundance data from ACL or ALSCL assessments.
#' It handles three types: total number ("N"), number at age ("NA"), and number at length ("NL").
#'
#' @param model_result A list from \code{run_acl} or \code{run_alscl}.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting (default 1.5).
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. Line type. Default is "solid".
#' @param se Logical. Whether to plot confidence intervals. Default is FALSE.
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_alpha Numeric or NULL. NULL inherits the global se_alpha setting (default 0.2).
#' @param type Character. "N" (total), "NA" (at age), or "NL" (at length). Default is "N".
#' @param facet_ncol Number of columns in facet wrap. Default is NULL.
#' @param facet_scales Scales for facet wrap. Default is "free".
#' @param return_data Logical. Whether to return processed data. Default is FALSE.
#' @param title Character or NULL. Custom plot title. If NULL, uses global theme setting. See \code{acl_theme_set()}.
#' @param xlab Character or NULL. Custom x-axis label. If NULL, uses global theme setting.
#' @param ylab Character or NULL. Custom y-axis label. If NULL, uses global theme setting.
#' @param font_family Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans").
#' @param title_size Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14).
#' @param axis_title_size Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12).
#' @param axis_text_size Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10).
#' @param strip_text_size Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10).
#' @param legend_text_size Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10).
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks (e.g. \code{seq(1, 20, by = 2)}). NULL = auto.
#' @param base_theme Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting.
#' @param title_hjust Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting.
#' @details Group-by-time matrices are read by position. Matrix row and column
#'   names are display metadata; model_result$year and model_result$len_label
#'   supply the plotted coordinates. With se = TRUE, the standard-error table
#'   must have one finite estimate and finite nonnegative standard error per
#'   plotted value. Missing or invalid uncertainty produces an explicit error;
#'   use se = FALSE to plot reported estimates alone.
#' @details Titles, axis labels, time-axis breaks and expansion inherit
#'   \code{acl_theme_set()}. Title keys are N, NA_ and NL;
#'   append \code{_se} for interval plots (use \code{NA_se} for NA).
#'   Axis labels use \code{xlab$year} and \code{ylab$abundance}.
#'
#' @details A \code{title}, \code{xlab} or \code{ylab} given in the call replaces the
#'   theme label, and the typography arguments replace the corresponding theme settings.
#' @details A group or panel with only one estimate is drawn as a point.
#'   When intervals are requested, its ribbon is replaced by an error bar.
#'   The point uses the global point_size setting and the estimate's line colour.
#' @return A ggplot object or a list with plot and data.
#' @export
plot_abundance <- function(model_result, line_size = NULL, line_color = NULL, line_type = "solid",
                           se = FALSE, se_color = NULL, se_alpha = NULL,
                           type = c("N", "NA", "NL"), facet_ncol = NULL, facet_scales = "free",
                           return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL,
                           font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
                           strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
                           title_hjust = NULL) {
  # NULL 继承全局色板 / NULL inherits the global palette.
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")
  if (is.null(se_alpha)) se_alpha <- acl_theme("se_alpha")


  type <- match.arg(type)
  quantity <- .acl_plot_population_data(model_result, type, c("N", "NA", "NL"), se)
  len_label <- model_result[["len_label"]]
  Year <- model_result[["year"]]
  current_theme <- .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size,
                                   strip_text_size, legend_text_size, base_theme = base_theme,
                                   title_hjust = title_hjust)

  # ==========================
  # Type = "N": Total abundance
  # ==========================
  if (type == "N") {
    number <- quantity$value
    if (!is.data.frame(number)) number <- as.data.frame(number)
    number$Year <- Year

    if (!se) {
      p <- ggplot2::ggplot(number, ggplot2::aes(x = Year, y = number)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
      data_out <- number
    } else {
      # Use exact match ^N$ to avoid matching NA, NL, NLA
      ss_n <- quantity$se
      ci <- data.frame(
        Year     = Year,
        estimate = ss_n[, "Estimate"],
        lower    = ss_n[, "Estimate"] - 1.96 * ss_n[, "Std. Error"],
        upper    = ss_n[, "Estimate"] + 1.96 * ss_n[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
      data_out <- ci
    }
  }

  # ==========================
  # Type = "NA": Abundance at age
  # ==========================
  if (type == "NA") {
    na <- quantity$value

    AgeGroup <- factor(paste("Age bin", seq_len(nrow(na))),
                       levels = paste("Age bin", seq_len(nrow(na))))

    na_long <- reshape2::melt(na)
    colnames(na_long) <- c("AgeGroup", "Year", "number.age")
    na_long$Year <- Year[as.numeric(na_long$Year)]
    na_long$AgeGroup <- AgeGroup[as.numeric(na_long$AgeGroup)]

    if (!se) {
      p <- ggplot2::ggplot(na_long, ggplot2::aes(x = Year, y = number.age)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- na_long
    } else {
      # Use exact match ^NA$ to avoid matching NLA
      ss_na <- quantity$se
      ss_na <- as.data.frame(ss_na)

      ci <- data.frame(
        AgeGroup = factor(rep(levels(AgeGroup), times = ncol(na)),
                          levels = levels(AgeGroup)),
        Year     = rep(Year, each = nrow(na)),
        estimate = ss_na[, "Estimate"],
        lower    = ss_na[, "Estimate"] - 1.96 * ss_na[, "Std. Error"],
        upper    = ss_na[, "Estimate"] + 1.96 * ss_na[, "Std. Error"]
      )

      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- ci
    }
  }

  # ==========================
  # Type = "NL": Abundance at length
  # ==========================
  if (type == "NL") {
    NL <- quantity$value
    if (!is.matrix(NL)) NL <- as.matrix(NL)

    LengthLabels <- .acl_fix_len_labels(len_label)

    NL_long <- reshape2::melt(NL)
    colnames(NL_long) <- c("LengthGroup", "Year", "Count")
    NL_long$Year <- Year[as.numeric(NL_long$Year)]
    NL_long$LengthGroup <- factor(LengthLabels[as.numeric(NL_long$LengthGroup)],
                                  levels = LengthLabels)

    if (!se) {
      p <- ggplot2::ggplot(NL_long, ggplot2::aes(x = Year, y = Count)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::facet_wrap(~LengthGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- NL_long
    } else {
      # Use exact match ^NL$ to avoid matching NLA
      ss_NL <- quantity$se
      ss_NL <- as.data.frame(ss_NL)

      ci <- data.frame(
        LengthGroup = factor(rep(LengthLabels, times = ncol(NL)), levels = LengthLabels),
        Year        = rep(Year, each = nrow(NL)),
        estimate    = ss_NL[, "Estimate"],
        lower       = ss_NL[, "Estimate"] - 1.96 * ss_NL[, "Std. Error"],
        upper       = ss_NL[, "Estimate"] + 1.96 * ss_NL[, "Std. Error"]
      )

      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) +
        ggplot2::facet_wrap(~LengthGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- ci
    }
  }

  title_key <- if (se) paste0(type, "_se") else if (type == "NA") "NA_" else type
  p <- p + ggplot2::labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", "year"),
                         y = if (!is.null(ylab)) ylab else .acl_lab("y", "abundance"),
                         title = if (!is.null(title)) title else .acl_title(title_key)) +
    .acl_scale_x(x_breaks, n_breaks = 5) + current_theme

  p <- .acl_show_singletons(p, intersect(c("AgeGroup", "LengthGroup"), names(p$data)))

  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}
