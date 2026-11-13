utils::globalVariables(c("AgeGroup", "LengthGroup", "CNL", "CNA"))
#' Plot Catch Number (CN), Catch by Age (CNA), or Catch by Length (CNL) Over Years
#'
#' Plots expected fishery catch in numbers. The Baranov catch equation
#' uses abundance at the start of the time step and the instantaneous rates
#' of fishing and natural mortality during the step.
#' Supports total catch ("CN"), catch at age ("CNA"), and catch at length ("CNL").
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
#' @param facet_ncol Numeric. Columns in facet wrap. Default is NULL.
#' @param facet_scales Character. Scales for facet wrap. Default is "free".
#' @param type Character. "CN" (total), "CNA" (at age), or "CNL" (at length). Default is "CN".
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
#' @details ALSCL reports CN, CNA and CNL with standard errors. ACL reports CN
#'   with standard errors and CNA estimates only; CNL is unavailable. A missing
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
#' @details Age panels are labelled with the fitted ages in \code{model_result$age}.
#'   The oldest age class is a plus group and is marked with a plus sign, for
#'   example "Age 15+". Results saved without age metadata keep the position
#'   labels "Age bin 1", "Age bin 2" and so on.
#'
#' @details Titles, axis labels, time-axis breaks and expansion inherit
#'   \code{acl_theme_set()}. Title keys are CN, CNA and CNL;
#'   append \code{_se} for interval plots.
#'   Axis labels use \code{xlab$year} and \code{ylab$catch}.
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
#' # Total catch in numbers with 95% confidence intervals
#' plot_catch(fit, se = TRUE)
#'
#' # Catch in numbers at age, one panel per age
#' plot_catch(fit, type = "CNA")
#' }
#' @export
plot_catch <- function(model_result, line_size = NULL, line_color = NULL, line_type = "solid",
                       se = FALSE, se_color = NULL, se_alpha = NULL,
                       facet_ncol = NULL, facet_scales = "free",
                       type = c("CN", "CNA", "CNL"), return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL,
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
  quantity <- .acl_plot_population_data(model_result, type, c("CN", "CNA", "CNL"), se)
  Year <- model_result[["year"]]
  len_label <- model_result[["len_label"]]
  current_theme <- .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size,
                                   strip_text_size, legend_text_size, base_theme = base_theme,
                                   title_hjust = title_hjust)

  # ==========================
  # Type = "CN": Total catch
  # ==========================
  if (type == "CN") {
    CN <- quantity$value
    if (!is.data.frame(CN)) CN <- as.data.frame(CN)
    CN$Year <- Year

    if (!se) {
      p <- ggplot2::ggplot(CN, ggplot2::aes(x = Year, y = CN)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
      data_out <- CN
    } else {
      # Use exact match ^CN$ to avoid matching CNA, CNL
      ss_CN <- quantity$se
      ci <- data.frame(
        Year     = Year,
        estimate = ss_CN[, "Estimate"],
        lower    = .acl_interval(ss_CN[, "Estimate"], ss_CN[, "Std. Error"], interval)$lower,
        upper    = .acl_interval(ss_CN[, "Estimate"], ss_CN[, "Std. Error"], interval)$upper
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
      data_out <- ci
    }
  }

  # ==========================
  # Type = "CNA": Catch at age
  # ==========================
  if (type == "CNA") {
    CNA <- quantity$value

    age_labels <- .acl_age_labels(model_result, nrow(CNA))
    AgeLabels <- factor(age_labels, levels = age_labels)

    CNA_long <- .acl_matrix_long(CNA, c("AgeGroup", "Year", "CNA"))
    CNA_long$Year <- Year[as.numeric(CNA_long$Year)]
    CNA_long$AgeGroup <- AgeLabels[as.numeric(CNA_long$AgeGroup)]

    if (!se) {
      p <- ggplot2::ggplot(CNA_long, ggplot2::aes(x = Year, y = CNA)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- CNA_long
    } else {
      ss_cna <- quantity$se
      ss_cna <- as.data.frame(ss_cna)
      ci <- data.frame(
        AgeGroup = rep(AgeLabels, times = ncol(CNA)),
        Year     = rep(Year, each = nrow(CNA)),
        estimate = ss_cna[, "Estimate"],
        lower    = .acl_interval(ss_cna[, "Estimate"], ss_cna[, "Std. Error"], interval)$lower,
        upper    = .acl_interval(ss_cna[, "Estimate"], ss_cna[, "Std. Error"], interval)$upper
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- ci
    }
  }

  # ==========================
  # Type = "CNL": Catch at length
  # ==========================
  if (type == "CNL") {
    CNL <- quantity$value
    if (!is.matrix(CNL)) CNL <- as.matrix(CNL)

    LengthLabels <- .acl_fix_len_labels(len_label)

    CNL_long <- .acl_matrix_long(CNL, c("LengthGroup", "Year", "CNL"))
    CNL_long$Year <- Year[as.numeric(CNL_long$Year)]
    CNL_long$LengthGroup <- factor(LengthLabels[as.numeric(CNL_long$LengthGroup)],
                                   levels = LengthLabels)

    if (!se) {
      p <- ggplot2::ggplot(CNL_long, ggplot2::aes(x = Year, y = CNL)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::facet_wrap(~LengthGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- CNL_long
    } else {
      ss_cnl <- quantity$se
      ss_cnl <- as.data.frame(ss_cnl)
      ci <- data.frame(
        LengthGroup = factor(rep(LengthLabels, times = ncol(CNL)), levels = LengthLabels),
        Year        = rep(Year, each = nrow(CNL)),
        estimate    = ss_cnl[, "Estimate"],
        lower       = .acl_interval(ss_cnl[, "Estimate"], ss_cnl[, "Std. Error"], interval)$lower,
        upper       = .acl_interval(ss_cnl[, "Estimate"], ss_cnl[, "Std. Error"], interval)$upper
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) +
        ggplot2::facet_wrap(~LengthGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- ci
    }
  }

  title_key <- if (se) paste0(type, "_se") else type
  p <- p + ggplot2::labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", "year"),
                         y = if (!is.null(ylab)) ylab else .acl_lab("y", "catch"),
                         title = if (!is.null(title)) title else .acl_title(title_key)) +
    .acl_scale_x(x_breaks, n_breaks = 5, values = Year) + current_theme

  p <- .acl_show_singletons(p, intersect(c("AgeGroup", "LengthGroup"), names(p$data)))

  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}
