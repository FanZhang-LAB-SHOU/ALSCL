utils::globalVariables(c("Biomass", "AgeGroup", "LengthGroup", "Count", "SBA"))
#' @title Plot Biomass Over Years from ACL or ALSCL Model
#'
#' @description Plots biomass over years. Supports total biomass ("B"),
#' biomass at length ("BL"), and biomass at age ("BA").
#'
#' @param model_result A list from \code{run_acl} or \code{run_alscl}.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting (default 1.5).
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. Line type. Default is "solid".
#' @param se Logical. Whether to plot confidence intervals. Default is FALSE.
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_alpha Numeric or NULL. NULL inherits the global se_alpha setting (default 0.2).
#' @param interval Character or NULL. The 95% interval drawn when \code{se = TRUE}.
#'   \code{"lognormal"} is \code{exp(log(estimate) +/- 1.96 * SE / estimate)} and
#'   stays above zero. \code{"wald"} is \code{estimate +/- 1.96 * SE} and can
#'   fall below zero. NULL inherits the global \code{interval} setting (default
#'   "lognormal"). Point estimates are the same for both.
#' @param type Character. "B" (total), "BL" (at length), or "BA" (at age). Default is "B".
#' @param facet_ncol Integer. Columns in facet_wrap. Default is NULL.
#' @param facet_scales Character. Scales for facet_wrap. Default is "free".
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
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks (e.g. \code{seq(1, 20, by = 2)}).
#'   NULL inherits the global x_breaks setting when at least one of its values
#'   lies on this axis; otherwise the breaks are chosen automatically.
#' @param base_theme Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting.
#' @param title_hjust Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting.
#'
#' @details ALSCL reports B, BL and BA with standard errors. ACL reports B with
#'   standard errors and BL estimates only; BA is unavailable. A missing quantity
#'   or requested standard error produces an explicit error. With \code{se = TRUE}
#'   the default interval is lognormal:
#'   \code{exp(log(estimate) +/- 1.96 * SE / estimate)}, where the estimate and
#'   its standard error (SE) are those stored in \code{model_result$est_std}.
#'   It cannot fall below zero. \code{interval = "wald"}, or
#'   \code{acl_theme_set(interval = "wald")}, restores the symmetric interval
#'   \code{estimate +/- 1.96 * SE} used by earlier versions. An estimate that is
#'   exactly zero, such as spawning stock biomass in a length bin with no
#'   mature fish, keeps the Wald bounds. Inspect fit diagnostics before using
#'   uncertainty intervals.
#'
#' @details Age panels are labelled with the fitted ages in \code{model_result$age}.
#'   The oldest age class is a plus group and is marked with a plus sign, for
#'   example "Age 15+". Results saved without age metadata keep the position
#'   labels "Age bin 1", "Age bin 2" and so on.
#'
#' @details Titles, axis labels, time-axis breaks and expansion inherit
#'   \code{acl_theme_set()}. Title keys are B, BL and BA;
#'   append \code{_se} for interval plots.
#'   Axis labels use \code{xlab$year} and \code{ylab$biomass}.
#'
#' @details A \code{title}, \code{xlab} or \code{ylab} given in the call replaces the
#'   theme label, and the typography arguments replace the corresponding theme settings.
#' @details A group or panel with only one estimate is drawn as a point.
#'   When intervals are requested, its ribbon is replaced by an error bar.
#'   The point uses the global point_size setting and the estimate's line colour.
#' @return A ggplot object or a list with plot and data.
#' @export
plot_biomass <- function(model_result, line_size = NULL, line_color = NULL, line_type = "solid",
                         se = FALSE, se_color = NULL, se_alpha = NULL,
                         type = c("B", "BL", "BA"), facet_ncol = NULL, facet_scales = "free",
                         return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL,
                         font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
                         strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
                         title_hjust = NULL, interval = NULL) {
  # NULL inherits the global palette.
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")
  if (is.null(se_alpha)) se_alpha <- acl_theme("se_alpha")


  type <- match.arg(type)
  interval <- .acl_interval_type(interval)
  quantity <- .acl_plot_population_data(model_result, type, c("B", "BL", "BA"), se)
  len_label <- model_result[["len_label"]]
  Year <- model_result[["year"]]
  current_theme <- .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size,
                                   strip_text_size, legend_text_size, base_theme = base_theme,
                                   title_hjust = title_hjust)

  # ==========================
  # Type = "B": Total biomass
  # ==========================
  if (type == "B") {
    biomass <- quantity$value
    if (!is.data.frame(biomass)) biomass <- as.data.frame(biomass)
    biomass$Year <- Year

    if (!se) {
      p <- ggplot2::ggplot(biomass, ggplot2::aes(x = Year, y = biomass)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
      data_out <- biomass
    } else {
      # Use exact match ^B$ to avoid matching BA, BL, BLA
      ss_bio <- quantity$se
      ci <- data.frame(
        Year     = Year,
        estimate = ss_bio[, "Estimate"],
        lower    = .acl_interval(ss_bio[, "Estimate"], ss_bio[, "Std. Error"], interval)$lower,
        upper    = .acl_interval(ss_bio[, "Estimate"], ss_bio[, "Std. Error"], interval)$upper
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
      data_out <- ci
    }
  }

  # ==========================
  # Type = "BL": Biomass at length
  # ==========================
  if (type == "BL") {
    BL <- quantity$value
    if (!is.matrix(BL)) BL <- as.matrix(BL)

    LengthLabels <- .acl_fix_len_labels(len_label)

    BL_long <- .acl_matrix_long(BL, c("LengthGroup", "Year", "Count"))
    BL_long$Year <- Year[as.numeric(BL_long$Year)]
    BL_long$LengthGroup <- factor(LengthLabels[as.numeric(BL_long$LengthGroup)],
                                  levels = LengthLabels)

    if (!se) {
      p <- ggplot2::ggplot(BL_long, ggplot2::aes(x = Year, y = Count)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
      data_out <- BL_long
    } else {
      ss_bl <- quantity$se
      ci <- data.frame(
        LengthGroup = BL_long$LengthGroup,
        Year = BL_long$Year,
        estimate = ss_bl[, "Estimate"],
        lower = .acl_interval(ss_bl[, "Estimate"], ss_bl[, "Std. Error"], interval)$lower,
        upper = .acl_interval(ss_bl[, "Estimate"], ss_bl[, "Std. Error"], interval)$upper
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
      data_out <- ci
    }
    p <- p + ggplot2::facet_wrap(~LengthGroup, ncol = facet_ncol, scales = facet_scales)
  }

  # ==========================
  # Type = "BA": Biomass at age
  # ==========================
  if (type == "BA") {
    BA <- quantity$value
    if (!is.matrix(BA)) BA <- as.matrix(BA)

    age_labels <- .acl_age_labels(model_result, nrow(BA))
    AgeLabels <- factor(age_labels, levels = age_labels)

    BA_long <- .acl_matrix_long(BA, c("AgeGroup", "Year", "Biomass"))
    BA_long$Year <- Year[as.numeric(BA_long$Year)]
    BA_long$AgeGroup <- AgeLabels[as.numeric(BA_long$AgeGroup)]

    if (!se) {
      p <- ggplot2::ggplot(BA_long, ggplot2::aes(x = Year, y = Biomass)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- BA_long
    } else {
      ss_ba <- quantity$se
      ss_ba <- as.data.frame(ss_ba)
      ci <- data.frame(
        AgeGroup = rep(AgeLabels, times = ncol(BA)),
        Year     = rep(Year, each = nrow(BA)),
        estimate = ss_ba[, "Estimate"],
        lower    = .acl_interval(ss_ba[, "Estimate"], ss_ba[, "Std. Error"], interval)$lower,
        upper    = .acl_interval(ss_ba[, "Estimate"], ss_ba[, "Std. Error"], interval)$upper
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
                         y = if (!is.null(ylab)) ylab else .acl_lab("y", "biomass"),
                         title = if (!is.null(title)) title else .acl_title(title_key)) +
    .acl_scale_x(x_breaks, n_breaks = 5, values = Year) + current_theme

  p <- .acl_show_singletons(p, intersect(c("AgeGroup", "LengthGroup"), names(p$data)))

  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}
