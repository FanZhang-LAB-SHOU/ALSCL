#' Plot Deviation of Recruitment (R) and Fishing Mortality (F) Over Years
#'
#' This function calculates the deviations of R and F in the ACL or ALSCL model results.
#' For ACL, F deviations are at the age level (A x Y).
#' For ALSCL, F deviations are at the length level (L x Y).
#'
#' @param model_result A list from \code{run_acl} or \code{run_alscl}.
#' @param se Logical. Whether to draw 95% intervals from the standard errors. Default is FALSE.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting.
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character, the line type.
#' @param point_color Character. The color of the point. Default is "white".
#' @param point_size Numeric or NULL. NULL inherits the global point_size setting (default 2.5).
#' @param point_shape Numeric. The shape of the point. Default is 21.
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_width Numeric. Width of the error-bar caps; does not change the
#'   standard errors or interval lengths.
#' @param log Logical. TRUE plots log process deviations; FALSE plots the corresponding
#'   ratios to the process median, obtained by exponentiating the deviations.
#' @param facet_ncol Number of columns in facet wrap. Default is NULL.
#' @param facet_scales Scales for facet wrap. Default is "free".
#' @param type Character. "R" for recruitment deviation, "F" for fishing mortality deviation.
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
#' @details With se = FALSE, estimates come from report$dev_log_R or
#'   report$dev_log_F without requiring a standard-error table. Older saved
#'   objects without these reported quantities may use the finite Estimate
#'   column in est_std. With se = TRUE, a complete table of finite estimates
#'   and finite nonnegative standard errors is required. Groups and periods
#'   must match the model metadata, including the single group for shared F.
#'   ACL age panels are labelled with the fitted ages in \code{model_result$age};
#'   the oldest age class is a plus group and is marked with a plus sign, for
#'   example "Age 15+". Results saved without age metadata keep the position
#'   labels "Age bin 1", "Age bin 2" and so on.
#'   Titles and y-axis labels use the global dev_R/dev_F keys on the log
#'   scale, and dev_R_multiplier/dev_F_multiplier keys after exponentiation.
#'   A \code{title}, \code{xlab} or \code{ylab} given in the call replaces the
#'   theme label, and the typography arguments replace the corresponding theme settings.
#' @return A ggplot2 object.
#' @export
plot_deviance <- function(model_result, se = FALSE, point_size = NULL, point_color = "white",
                          point_shape = 21, line_size = NULL, line_color = NULL,
                          line_type = "solid", se_color = NULL, se_width = 0.5,
                          facet_ncol = NULL, facet_scales = "free", log = TRUE,
                          type = c("R", "F"), title = NULL, xlab = NULL, ylab = NULL,
                          font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
                          strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
                          title_hjust = NULL) {
  if (is.null(point_size)) point_size <- acl_theme("point_size")
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")
  type <- match.arg(type)
  .acl_check_flag(se, "se")
  .acl_check_flag(log, "log")
  years <- model_result$year
  if (!is.numeric(years) || !length(years) || any(!is.finite(years)) || any(diff(years) <= 0))
    stop("model_result$year must contain finite increasing time labels.", call. = FALSE)
  quantity <- paste0("dev_log_", type)
  values <- model_result$report[[quantity]]
  shared <- type == "F" && identical(model_result$F_structure, "year")
  is_alscl <- identical(model_result$model_type, "ALSCL") ||
    (is.null(model_result$report[["F"]]) && !is.null(model_result$report$FL))
  n_groups <- 1L
  if (type == "F" && !shared) {
    field <- model_result$report[[if (is_alscl) "FL" else "F"]]
    if (is.null(field)) field <- values
    if (!is.matrix(field) || nrow(field) < 1L || ncol(field) != length(years))
      stop("Fishing mortality must be a group-by-time matrix matching model_result$year.", call. = FALSE)
    n_groups <- nrow(field)
  }
  expected <- n_groups * length(years)
  if (!is.null(values)) {
    if (is.data.frame(values)) values <- as.matrix(values)
    if (!is.numeric(values) || length(values) != expected || any(!is.finite(values)) ||
        (type == "F" && (!is.matrix(values) ||
         !identical(dim(values), c(n_groups, length(years))))))
      stop("Quantity '", quantity, "' must contain finite estimates matching the model groups and time steps.",
           call. = FALSE)
    values <- as.numeric(values)
  }
  # An estimates-only plot uses reported random-effect modes even when sdreport
  # failed. Older portable objects may instead retain just the estimate table.
  estimates <- if (se || is.null(values))
    .acl_plot_estimates(model_result, quantity, expected, require_se = se) else NULL
  if (se || is.null(values)) values <- estimates[, "Estimate"]
  errors <- if (se) estimates[, "Std. Error"] else rep(NA_real_, expected)
  ci <- data.frame(Year = rep(years, each = n_groups), estimate = values,
                   lower = values - 1.96 * errors, upper = values + 1.96 * errors)
  if (type == "F") {
    if (shared) {
      ci$Group <- "Shared F"
    } else if (is_alscl) {
      labels <- model_result$len_label
      if (is.null(labels)) labels <- paste0("L", seq_len(n_groups))
      if (length(labels) != n_groups || anyNA(labels) ||
          any(!nzchar(as.character(labels))) || anyDuplicated(labels))
        stop("model_result$len_label must identify every length group uniquely.", call. = FALSE)
      labels <- .acl_fix_len_labels(labels, prefix = "Length")
      ci$Group <- factor(rep(labels, times = length(years)), levels = labels)
    } else {
      labels <- .acl_age_labels(model_result, n_groups)
      ci$Group <- factor(rep(labels, times = length(years)), levels = labels)
    }
    ci <- ci[c("Group", "Year", "estimate", "lower", "upper")]
  }
  if (!log) {
    ci[, c("estimate", "lower", "upper")] <- exp(ci[, c("estimate", "lower", "upper")])
    if (any(!is.finite(ci$estimate)) || (se && any(!is.finite(as.matrix(ci[c("lower", "upper")])))))
      stop("Deviation estimates or intervals overflow on the response scale; use log = TRUE.", call. = FALSE)
  }
  label_key <- paste0("dev_", type, if (!log) "_multiplier" else "")
  plot <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
    ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
    ggplot2::geom_point(size = point_size, fill = point_color, shape = point_shape) +
    ggplot2::labs(y = if (!is.null(ylab)) ylab else .acl_lab("y", label_key),
      x = if (!is.null(xlab)) xlab else .acl_lab("x", "year"),
      title = if (!is.null(title)) title else .acl_title(label_key)) +
    .acl_scale_x(x_breaks, n_breaks = 5, values = years) +
    .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size, strip_text_size,
                    legend_text_size, base_theme = base_theme, title_hjust = title_hjust)
  if (type == "F") plot <- plot + ggplot2::facet_wrap(~Group, ncol = facet_ncol, scales = facet_scales)
  if (se) plot <- plot +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color, width = se_width) +
    ggplot2::geom_point(size = point_size, fill = point_color, shape = point_shape)
  plot
}
