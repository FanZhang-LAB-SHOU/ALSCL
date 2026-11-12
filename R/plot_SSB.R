utils::globalVariables(c("LengthGroup", "Count"))
#' @title Plot spawning biomass (SSB), SBL or SBA over time
#'
#' @description Plots SSB, spawning biomass at length (SBL), or spawning biomass
#' at age (SBA) from ACL or ALSCL model results.
#'
#' @param model_result A list from \code{run_acl} or \code{run_alscl}.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting (default 1.5).
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. Line type. Default is "solid".
#' @param se Logical. Whether to plot confidence intervals. Default is FALSE.
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_alpha Numeric or NULL. NULL inherits the global se_alpha setting (default 0.2).
#' @param type Character. "SSB" (total), "SBL" (at length), or "SBA" (at age). Default is "SSB".
#' @param facet_ncol Numeric. Columns in facet wrap. Default is NULL.
#' @param facet_scales Character. Scales for facet wrap. Default is "free".
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
#'
#' @details ALSCL reports SSB, SBL and SBA with standard errors. ACL reports SSB
#'   with standard errors and SBL estimates only; SBA is unavailable. A missing
#'   quantity or requested standard error produces an explicit error. With
#'   \code{se = TRUE}, intervals are the estimate plus or minus 1.96 standard errors
#'   on the reported scale. They are not truncated at zero. Inspect fit
#'   diagnostics before using uncertainty intervals.
#'
#' @details Titles, axis labels, time-axis breaks and expansion inherit
#'   \code{acl_theme_set()}. Title keys are SSB, SBL and SBA;
#'   append \code{_se} for interval plots.
#'   Axis labels use \code{xlab$year} and \code{ylab$ssb}.
#'
#' @details A \code{title}, \code{xlab} or \code{ylab} given in the call replaces the
#'   theme label, and the typography arguments replace the corresponding theme settings.
#' @details A group or panel with only one estimate is drawn as a point.
#'   When intervals are requested, its ribbon is replaced by an error bar.
#'   The point uses the global point_size setting and the estimate's line colour.
#' @return A ggplot object or a list with plot and data.
#' @export
plot_SSB <- function(model_result, line_size = NULL, line_color = NULL, line_type = "solid",
                     se = FALSE, se_color = NULL, se_alpha = NULL,
                     type = c("SSB", "SBL", "SBA"), facet_ncol = NULL, facet_scales = "free",
                     return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL,
                     font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
                     strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
                     title_hjust = NULL) {
  # NULL inherits the global palette.
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")
  if (is.null(se_alpha)) se_alpha <- acl_theme("se_alpha")


  type <- match.arg(type)
  quantity <- .acl_plot_population_data(model_result, type, c("SSB", "SBL", "SBA"), se)
  len_label <- model_result[["len_label"]]
  Year <- model_result[["year"]]
  current_theme <- .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size,
                                   strip_text_size, legend_text_size, base_theme = base_theme,
                                   title_hjust = title_hjust)

  # ==========================
  # Type = "SSB": Total SSB
  # ==========================
  if (type == "SSB") {
    SSB <- quantity$value
    if (!is.data.frame(SSB)) SSB <- as.data.frame(SSB)
    SSB$Year <- Year

    if (!se) {
      p <- ggplot2::ggplot(SSB, ggplot2::aes(x = Year, y = SSB)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
      data_out <- SSB
    } else {
      ss_ssb <- quantity$se
      ci <- data.frame(
        Year     = Year,
        estimate = ss_ssb[, "Estimate"],
        lower    = ss_ssb[, "Estimate"] - 1.96 * ss_ssb[, "Std. Error"],
        upper    = ss_ssb[, "Estimate"] + 1.96 * ss_ssb[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
      data_out <- ci
    }
  }

  # ==========================
  # Type = "SBL": SSB at length
  # ==========================
  if (type == "SBL") {
    SBL <- quantity$value
    if (!is.matrix(SBL)) SBL <- as.matrix(SBL)

    LengthLabels <- .acl_fix_len_labels(len_label)

    SBL_long <- reshape2::melt(SBL)
    colnames(SBL_long) <- c("LengthGroup", "Year", "Count")
    SBL_long$Year <- Year[as.numeric(SBL_long$Year)]
    SBL_long$LengthGroup <- factor(LengthLabels[as.numeric(SBL_long$LengthGroup)],
                                   levels = LengthLabels)

    if (!se) {
      p <- ggplot2::ggplot(SBL_long, ggplot2::aes(x = Year, y = Count)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
      data_out <- SBL_long
    } else {
      ss_sbl <- quantity$se
      ci <- data.frame(
        LengthGroup = SBL_long$LengthGroup,
        Year = SBL_long$Year,
        estimate = ss_sbl[, "Estimate"],
        lower = ss_sbl[, "Estimate"] - 1.96 * ss_sbl[, "Std. Error"],
        upper = ss_sbl[, "Estimate"] + 1.96 * ss_sbl[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
      data_out <- ci
    }
    p <- p + ggplot2::facet_wrap(~LengthGroup, ncol = facet_ncol, scales = facet_scales)
  }

  # ==========================
  # Type = "SBA": SSB at age
  # ==========================
  if (type == "SBA") {
    SBA <- quantity$value
    if (!is.matrix(SBA)) SBA <- as.matrix(SBA)

    AgeLabels <- factor(paste("Age bin", seq_len(nrow(SBA))),
                        levels = paste("Age bin", seq_len(nrow(SBA))))

    SBA_long <- reshape2::melt(SBA)
    colnames(SBA_long) <- c("AgeGroup", "Year", "SBA")
    SBA_long$Year <- Year[as.numeric(SBA_long$Year)]
    SBA_long$AgeGroup <- AgeLabels[as.numeric(SBA_long$AgeGroup)]

    if (!se) {
      p <- ggplot2::ggplot(SBA_long, ggplot2::aes(x = Year, y = SBA)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- SBA_long
    } else {
      ss_sba <- quantity$se
      ss_sba <- as.data.frame(ss_sba)
      ci <- data.frame(
        AgeGroup = rep(AgeLabels, times = ncol(SBA)),
        Year     = rep(Year, each = nrow(SBA)),
        estimate = ss_sba[, "Estimate"],
        lower    = ss_sba[, "Estimate"] - 1.96 * ss_sba[, "Std. Error"],
        upper    = ss_sba[, "Estimate"] + 1.96 * ss_sba[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- ci
    }
  }

  title_key <- if (se) paste0(type, "_se") else type
  p <- p + ggplot2::labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", "year"),
                         y = if (!is.null(ylab)) ylab else .acl_lab("y", "ssb"),
                         title = if (!is.null(title)) title else .acl_title(title_key)) +
    .acl_scale_x(x_breaks, n_breaks = 5) + current_theme

  p <- .acl_show_singletons(p, intersect(c("AgeGroup", "LengthGroup"), names(p$data)))

  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}
