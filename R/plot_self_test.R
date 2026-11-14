utils::globalVariables(c("median_re", "low_re", "high_re", "Quantity", "Parameter"))

# "10th", "90th", "2.5th": the percentile of a probability.
.acl_percentile_label <- function(p) {
  value <- 100 * p
  text <- format(value, trim = TRUE, drop0trailing = TRUE)
  whole <- abs(value - round(value)) < 1e-8
  last <- round(value) %% 10; teen <- round(value) %% 100 %in% 11:13
  suffix <- if (whole && !teen && last == 1) "st" else if (whole && !teen && last == 2) "nd" else
    if (whole && !teen && last == 3) "rd" else "th"
  paste0(text, suffix)
}

.acl_self_test_band <- function(d, key, probs) {
  d <- d[d$numerical_ok & is.finite(d$relative_error), , drop = FALSE]
  if (!nrow(d)) return(NULL)
  groups <- split(d, d[key], drop = TRUE, lex.order = TRUE)
  out <- do.call(rbind, lapply(groups, function(g) {
    re <- 100 * g$relative_error
    cbind(g[1L, key, drop = FALSE], data.frame(n = length(re),
      median_re = stats::median(re),
      low_re = unname(stats::quantile(re, probs[1L], names = FALSE)),
      high_re = unname(stats::quantile(re, probs[2L], names = FALSE))))
  }))
  rownames(out) <- NULL
  out
}

#' Plot the relative errors of a self-test
#'
#' Draws the relative errors of a [self_test()]: for each time series, the
#' median over the refits that pass the numerical checks by time step, with a
#' band between two percentiles, and for each estimated scalar parameter the
#' median and the same percentiles. A line at zero marks no error.
#'
#' @param x An `alscl_self_test` object from [self_test()].
#' @param what `"both"` (default) draws the time series above the
#'   parameters; `"series"` or `"parameters"` draws one part.
#' @param probs Two probabilities, the lower and upper percentiles of the
#'   band. Default `c(0.1, 0.9)`, the 10th and 90th percentiles across
#'   replicates.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting.
#' @param line_color Character or NULL. Colour of the median line and points;
#'   NULL inherits the global line_color setting.
#' @param se_color Character or NULL. Colour of the band; NULL inherits the
#'   global se_color setting.
#' @param se_alpha Numeric or NULL. Opacity of the band; NULL inherits the
#'   global se_alpha setting.
#' @param point_size Numeric or NULL. Size of the median of a parameter; NULL
#'   inherits the global point_size setting.
#' @param facet_ncol Numeric or NULL. Columns of the time-series panels; NULL
#'   puts up to three panels in a row.
#' @param return_data Logical. Whether to return the plotted data with the
#'   plot. Default is FALSE.
#' @inheritParams plot_SSB
#' @return A ggplot object (a patchwork for `what = "both"`), or a list with
#'   `plot`, `series` and `parameters` (the plotted medians and percentiles,
#'   in percent) when `return_data = TRUE`.
#' @details The relative error is (estimate - truth) / truth, shown in
#'   percent; the truth of each replicate is described in [self_test()].
#'   Refits that fail the numerical checks are not drawn; the subtitle gives
#'   the number of refits drawn. Parameters are on the natural scale of
#'   [extract_parameters()] and keep its names. A parameter whose truth is zero
#'   has no relative error and is not drawn.
#'
#'   The title uses the theme key `self_test`; the axis labels use
#'   `xlab$year` and `ylab$relative_error`.
#' @seealso [self_test()].
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' st <- self_test(fit, nsim = 5, seed = 1)
#' plot_self_test(st)
#' plot_self_test(st, what = "series", probs = c(0.05, 0.95))
#' }
#' @export
plot_self_test <- function(x, what = c("both", "series", "parameters"), probs = c(0.1, 0.9),
                           line_size = NULL, line_color = NULL, se_color = NULL, se_alpha = NULL,
                           point_size = NULL, facet_ncol = NULL, return_data = FALSE,
                           title = NULL, xlab = NULL, ylab = NULL, font_family = NULL,
                           title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
                           strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL,
                           base_theme = NULL, title_hjust = NULL) {
  if (!inherits(x, "alscl_self_test"))
    stop("x must be the result of self_test().", call. = FALSE)
  what <- match.arg(what)
  .acl_check_flag(return_data, "return_data")
  if (!is.numeric(probs) || length(probs) != 2L || any(!is.finite(probs)) ||
      any(probs < 0 | probs > 1) || probs[1L] >= probs[2L])
    stop("probs must be two increasing probabilities between 0 and 1.", call. = FALSE)
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")
  if (is.null(se_alpha)) se_alpha <- acl_theme("se_alpha")
  if (is.null(point_size)) point_size <- acl_theme("point_size")
  s <- x$settings
  passed <- sum(x$replicates$numerical_ok)
  if (!passed)
    stop("No refit passes the numerical checks, so there is nothing to plot. See x$replicates.",
         call. = FALSE)
  y_label <- if (!is.null(ylab)) ylab else .acl_lab("y", "relative_error")
  theme_layers <- .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size,
                                  strip_text_size, legend_text_size, base_theme = base_theme,
                                  title_hjust = title_hjust)
  zero <- acl_theme("hline_color") %||% "grey55"

  series <- if (what == "parameters") NULL else
    .acl_self_test_band(x$series, c("quantity", "year"), probs)
  F_label <- paste(if (s$F_summary == "mean") "Mean F over" else "Apical F over",
                   if (s$F_group == "age") "ages" else "length bins")
  names_q <- c(SSB = "Spawning stock biomass (SSB)", Rec = "Recruitment (R)", F = F_label,
               B = "Total biomass (B)", N = "Total abundance (N)")
  p_series <- NULL
  if (!is.null(series)) {
    series$Quantity <- factor(names_q[series$quantity], levels = names_q[s$quantities])
    ncol <- if (is.null(facet_ncol)) min(3L, length(unique(series$quantity))) else facet_ncol
    p_series <- ggplot2::ggplot(series, ggplot2::aes(x = year, y = median_re)) +
      ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = zero) +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = low_re, ymax = high_re), fill = se_color,
                           alpha = se_alpha) +
      ggplot2::geom_line(linewidth = line_size, color = line_color) +
      ggplot2::facet_wrap(~Quantity, ncol = ncol, scales = "free_y") +
      ggplot2::labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", "year"), y = y_label) +
      .acl_scale_x(x_breaks, n_breaks = .acl_facet_n_breaks(length(unique(series$quantity)), ncol),
                   values = series$year) +
      theme_layers
  }
  parameters <- if (what == "series") NULL else .acl_self_test_band(x$parameters, "parameter", probs)
  p_parameters <- NULL
  if (!is.null(parameters)) {
    order <- unique(x$parameters$parameter)
    parameters$Parameter <- factor(parameters$parameter, levels = rev(order[order %in% parameters$parameter]))
    p_parameters <- ggplot2::ggplot(parameters, ggplot2::aes(y = Parameter, x = median_re)) +
      ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = zero) +
      ggplot2::geom_linerange(ggplot2::aes(xmin = low_re, xmax = high_re), color = line_color,
                              linewidth = line_size) +
      ggplot2::geom_point(color = line_color, size = point_size) +
      ggplot2::labs(x = y_label, y = "Parameter (natural scale)") +
      theme_layers
  }
  if (is.null(p_series) && is.null(p_parameters))
    stop("x has no relative errors to plot.", call. = FALSE)
  band <- paste0("median (line) and ", .acl_percentile_label(probs[1L]), " to ",
                 .acl_percentile_label(probs[2L]), " percentiles (", if (what == "parameters")
                 "range" else "band", ")")
  subtitle <- paste0(s$model, ", process = \"", s$process, "\", start = \"", s$start, "\": ",
                     band, " of ", passed, " of ", s$nsim, " refits that pass the numerical checks")
  main <- if (!is.null(title)) title else .acl_title("self_test")
  if (what == "both" && !is.null(p_series) && !is.null(p_parameters)) {
    p_parameters <- p_parameters + ggplot2::labs(title = NULL)
    p <- patchwork::wrap_plots(p_series, p_parameters, ncol = 1,
                               heights = c(1, max(0.5, 0.12 * nrow(parameters)))) +
      patchwork::plot_annotation(title = main, subtitle = paste(strwrap(subtitle, 110), collapse = "\n"),
                                 theme = .acl_annotation_theme("none"))
  } else {
    p <- (if (is.null(p_series)) p_parameters else p_series) +
      ggplot2::labs(title = main, subtitle = paste(strwrap(subtitle, 90), collapse = "\n"))
  }
  if (return_data) list(plot = p, series = series, parameters = parameters) else p
}
