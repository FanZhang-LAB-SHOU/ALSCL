utils::globalVariables(c("LengthGroup", "Count", "SSB_at_age"))
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
#' @param interval Character or NULL. The 95% interval drawn when \code{se = TRUE}.
#'   \code{"lognormal"} is \code{exp(log(estimate) +/- 1.96 * SE / estimate)} and
#'   stays above zero (an estimate of exactly zero keeps the Wald upper bound
#'   with the lower bound at zero). \code{"wald"} is \code{estimate +/- 1.96 * SE} and can
#'   fall below zero. NULL inherits the global \code{interval} setting (default
#'   "lognormal"). Point estimates are the same for both.
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
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks (e.g. \code{seq(1, 20, by = 2)}).
#'   NULL inherits the global x_breaks setting when at least one of its values
#'   lies on this axis; otherwise the breaks are chosen automatically.
#' @param base_theme Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting.
#' @param title_hjust Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting.
#' @param maturity_at_age NULL (default) or the proportion mature at age, as
#'   `maturity` in [ssb_at_age()]: a vector with one value per age class or a
#'   matrix by age class and time step. With `type = "SSB"`, the SSB from this
#'   maturity ogive by age is added as a dashed line, and a legend names the
#'   two series. It is an error with the other types.
#' @param weight_at_age NULL or mean weight at age, as `weight` in
#'   [ssb_at_age()], used with `maturity_at_age`.
#'
#' @details ALSCL reports SSB, SBL and SBA with standard errors. ACL reports SSB
#'   with standard errors and SBL estimates only; SBA is unavailable. A missing
#'   quantity or requested standard error produces an explicit error. With \code{se = TRUE}
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
#' @details The models calculate SSB from the proportion mature at length.
#'   With `maturity_at_age`, the figure adds the SSB calculated by
#'   [ssb_at_age()] as the sum over age classes of biomass at age multiplied
#'   by the proportion mature at age, for comparison with an age-based
#'   assessment that uses a maturity ogive by age. The confidence interval of
#'   `se = TRUE` belongs to the SSB of the model; the added series has no
#'   standard error. Both series are in the unit of model biomass, whose
#'   level depends on the assumed survey catchability.
#'
#' @details Age panels are labelled with the fitted ages in \code{model_result$age}.
#'   The oldest age class is a plus group and is marked with a plus sign, for
#'   example "Age 15+". Results saved without age metadata keep the position
#'   labels "Age bin 1", "Age bin 2" and so on.
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
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#'
#' # Spawning stock biomass (SSB) with 95% confidence intervals
#' plot_SSB(fit, se = TRUE)
#'
#' # Spawning stock biomass at length, one panel per length bin
#' plot_SSB(fit, type = "SBL")
#' }
#' @export
plot_SSB <- function(model_result, line_size = NULL, line_color = NULL, line_type = "solid",
                     se = FALSE, se_color = NULL, se_alpha = NULL,
                     type = c("SSB", "SBL", "SBA"), facet_ncol = NULL, facet_scales = "free",
                     return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL,
                     font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
                     strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
                     title_hjust = NULL, interval = NULL,
                     maturity_at_age = NULL, weight_at_age = NULL) {
  # NULL inherits the global palette.
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")
  if (is.null(se_alpha)) se_alpha <- acl_theme("se_alpha")


  type <- match.arg(type)
  interval <- .acl_interval_type(interval)
  if (type != "SSB" && (!is.null(maturity_at_age) || !is.null(weight_at_age)))
    stop("maturity_at_age and weight_at_age apply to type = \"SSB\" only.", call. = FALSE)
  if (is.null(maturity_at_age) && !is.null(weight_at_age))
    stop("weight_at_age is used with maturity_at_age; supply both.", call. = FALSE)
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
        lower    = .acl_interval(ss_ssb[, "Estimate"], ss_ssb[, "Std. Error"], interval)$lower,
        upper    = .acl_interval(ss_ssb[, "Estimate"], ss_ssb[, "Std. Error"], interval)$upper
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
      data_out <- ci
    }
    if (!is.null(maturity_at_age)) {
      # SSB from a maturity ogive by age, next to the SSB of the model.
      by_age <- ssb_at_age(model_result, maturity = maturity_at_age, weight = weight_at_age)
      series <- c("Maturity at length (model)", "Maturity at age")
      added <- data.frame(Year = by_age$year, SSB_at_age = by_age$SSB)
      model_line <- which(vapply(p$layers, function(layer) inherits(layer$geom, "GeomLine"), logical(1)))[1L]
      p$layers[[model_line]] <- ggplot2::geom_line(ggplot2::aes(linetype = series[1L]),
        linewidth = line_size, color = line_color)
      p <- p + ggplot2::geom_line(data = added, ggplot2::aes(x = Year, y = SSB_at_age, linetype = series[2L]),
                                  linewidth = line_size, color = line_color, inherit.aes = FALSE) +
        ggplot2::scale_linetype_manual(name = "SSB from", breaks = series,
          values = stats::setNames(c(line_type, if (identical(line_type, "dashed")) "solid" else "dashed"), series)) +
        ggplot2::guides(linetype = ggplot2::guide_legend(keywidth = ggplot2::unit(1.2, "cm")))
      data_out$SSB_at_age <- by_age$SSB
    }
  }

  # ==========================
  # Type = "SBL": SSB at length
  # ==========================
  if (type == "SBL") {
    SBL <- quantity$value
    if (!is.matrix(SBL)) SBL <- as.matrix(SBL)

    LengthLabels <- .acl_fix_len_labels(len_label)

    SBL_long <- .acl_matrix_long(SBL, c("LengthGroup", "Year", "Count"))
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
        lower = .acl_interval(ss_sbl[, "Estimate"], ss_sbl[, "Std. Error"], interval)$lower,
        upper = .acl_interval(ss_sbl[, "Estimate"], ss_sbl[, "Std. Error"], interval)$upper
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

    age_labels <- .acl_age_labels(model_result, nrow(SBA))
    AgeLabels <- factor(age_labels, levels = age_labels)

    SBA_long <- .acl_matrix_long(SBA, c("AgeGroup", "Year", "SBA"))
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
        lower    = .acl_interval(ss_sba[, "Estimate"], ss_sba[, "Std. Error"], interval)$lower,
        upper    = .acl_interval(ss_sba[, "Estimate"], ss_sba[, "Std. Error"], interval)$upper
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
    .acl_scale_x(x_breaks, n_breaks = 5, values = Year) + current_theme

  p <- .acl_show_singletons(p, intersect(c("AgeGroup", "LengthGroup"), names(p$data)))
  if (!is.null(maturity_at_age)) p <- p + ggplot2::theme(legend.position = "bottom")

  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}
