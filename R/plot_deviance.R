#' Plot Deviation of Recruitment (R) and Fishing Mortality (F) Over Years
#'
#' This function calculates the deviations of R and F in the ACL or ALSCL model results.
#' For ACL, F deviations are at the age level (A x Y).
#' For ALSCL, F deviations are at the length level (L x Y).
#'
#' @param model_result A list from \code{run_acl} or \code{run_alscl}.
#' @param se Logical, whether to draw the standard error bar.
#' @param line_size Numeric, the line size.
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character, the line type.
#' @param point_color Character. The color of the point. Default is "white".
#' @param point_size Numeric. The size of the point. Default is 3.
#' @param point_shape Numeric. The shape of the point. Default is 21.
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_width Numeric, the width of the standard error.
#' @param log Logical, whether to keep log scale (TRUE) or apply exp transform (FALSE).
#' @param facet_ncol Number of columns in facet wrap. Default is NULL.
#' @param facet_scales Scales for facet wrap. Default is "free".
#' @param type Character. "R" for recruitment deviation, "F" for fishing mortality deviation.
#'
#' @details With se = FALSE, estimates come from report$dev_log_R or
#'   report$dev_log_F without requiring a standard-error table. Older saved
#'   objects without these reported quantities may use the finite Estimate
#'   column in est_std. With se = TRUE, a complete table of finite estimates
#'   and finite nonnegative standard errors is required. Groups and periods
#'   must match the model metadata, including the single group for shared F.
#' @return A ggplot2 object.
#' @export
plot_deviance <- function(model_result, se = TRUE, point_size = 3, point_color = "white",
                          point_shape = 21, line_size = 1, line_color = NULL,
                          line_type = "solid", se_color = NULL, se_width = 0.5,
                          facet_ncol = NULL, facet_scales = "free", log = TRUE,
                          type = c("R", "F")) {
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")
  type <- match.arg(type)
  if (!is.logical(se) || length(se) != 1L || is.na(se))
    stop("se must be TRUE or FALSE.", call. = FALSE)
  if (!is.logical(log) || length(log) != 1L || is.na(log))
    stop("log must be TRUE or FALSE.", call. = FALSE)
  years <- model_result$year
  if (!is.numeric(years) || !length(years) || any(!is.finite(years)) || any(diff(years) <= 0))
    stop("model_result$year must contain finite increasing time labels.", call. = FALSE)
  quantity <- paste0("dev_log_", type)
  values <- model_result$report[[quantity]]
  shared <- type == "F" && identical(model_result$F_structure, "year")
  is_alscl <- identical(model_result$model_type, "ALSCL") ||
    (is.null(model_result$report$F) && !is.null(model_result$report$FL))
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
      facet_title <- "Shared F Deviance Over Time"
    } else if (is_alscl) {
      labels <- model_result$len_label
      if (is.null(labels)) labels <- paste0("L", seq_len(n_groups))
      if (length(labels) != n_groups || anyNA(labels) ||
          any(!nzchar(as.character(labels))) || anyDuplicated(labels))
        stop("model_result$len_label must identify every length group uniquely.", call. = FALSE)
      labels <- .acl_fix_len_labels(labels, prefix = "Length")
      ci$Group <- factor(rep(labels, times = length(years)), levels = labels)
      facet_title <- "F Deviance at Length (ALSCL)"
    } else {
      ci$Group <- rep(paste0("Age group ", seq_len(n_groups)), times = length(years))
      facet_title <- "F Deviance Over Years"
    }
    ci <- ci[c("Group", "Year", "estimate", "lower", "upper")]
  }
  if (!log) {
    ci[, c("estimate", "lower", "upper")] <- exp(ci[, c("estimate", "lower", "upper")])
    if (any(!is.finite(ci$estimate)) || (se && any(!is.finite(as.matrix(ci[c("lower", "upper")])))))
      stop("Deviation estimates or intervals overflow on the response scale; use log = TRUE.", call. = FALSE)
  }
  plot <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
    ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
    ggplot2::geom_point(size = point_size, fill = point_color, shape = point_shape) +
    ggplot2::labs(y = if (type == "R") "Recruitment Deviance" else "F Deviance", x = "Year",
      title = if (type == "R") "Recruitment Deviance Over Years" else facet_title) +
    .acl_plot_theme()
  if (type == "F") plot <- plot + ggplot2::facet_wrap(~Group, ncol = facet_ncol, scales = facet_scales)
  if (se) plot <- plot +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color, width = se_width) +
    ggplot2::geom_point(size = point_size, fill = point_color, shape = point_shape)
  plot
}
