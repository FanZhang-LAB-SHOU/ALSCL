#' Plot recruitment over time
#'
#' Plot the estimated recruitment, the number of fish entering the youngest
#' age class, in each time step, as bars (default style) or a line. With
#' `se = TRUE` error bars on the bars, or a ribbon around the line, show the
#' 95% interval. The default interval is lognormal and cannot fall below zero;
#' see the `interval` argument.
#'
#' @param model_result A list that contains the model output. The list should have a "report" component which contains a "Rec" component representing Recruitment.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting
#'   (1 under the standard style, 1.5 under classic). While that setting keeps
#'   the value of the style, facets of more than
#'   four panels draw thinner lines.
#' @param line_color Character or NULL. Line or bar color. NULL inherits the
#'   global recruitment_color setting, or line_color when that is NULL.
#' @param line_type Character. Specifies the type of the line in the plot. Default is "solid".
#' @param se Logical. Determines whether to calculate and plot the standard error as confidence intervals. Default is FALSE.
#' @param se_color Character or NULL. Color of the interval. NULL takes the
#'   color of the line, or the global se_color when that differs from the
#'   global line_color or when recruitment_color is NULL. Error bars on bars
#'   are dark grey unless se_color is given.
#' @param se_alpha Numeric or NULL. Transparency of the interval ribbon. NULL
#'   inherits the global se_alpha setting (0.3 under the standard style, 0.2
#'   under classic). Error bars are opaque unless se_alpha is given.
#' @param interval Character or NULL. The 95% interval drawn when \code{se = TRUE}.
#'   \code{"lognormal"} is \code{exp(log(estimate) +/- 1.96 * SE / estimate)} and
#'   stays above zero (an estimate of exactly zero keeps the Wald upper bound
#'   with the lower bound at zero). \code{"wald"} is \code{estimate +/- 1.96 * SE} and can
#'   fall below zero. NULL inherits the global \code{interval} setting (default
#'   "lognormal"). Point estimates are the same for both.
#' @param se_type Character or NULL. Form of the interval: "ribbon" (shaded
#'   area) or "errorbar" (error bars). NULL (default) draws error bars on bars
#'   and a ribbon around a line.
#' @param return_data A logical indicating whether to return the processed data alongside the plot. Default is FALSE.
#' @param geom Character or NULL. Form of recruitment. "bar" draws bars 0.8
#'   of a time step wide, with error bars when \code{se = TRUE}. "line" draws
#'   a line, with a ribbon when \code{se = TRUE}. NULL (default) follows the
#'   global bars setting: bars under the "standard" style and a line under
#'   "classic". \code{se_type} changes the form of the interval.
#'
#' @param title Character, FALSE or NULL. NULL (default) draws the default
#'   title, FALSE (or NA or "") draws no title, and a character string is
#'   drawn as the title. The default titles and the show_title setting are
#'   described in \code{\link{acl_theme_set}()}.
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
#' @details With se = TRUE, the standard-error table must have one finite
#'   estimate and finite nonnegative standard error per model time step.
#'   Missing or invalid uncertainty produces an explicit error; use se = FALSE
#'   to plot reported estimates alone.
#' @details A group or panel with only one estimate is drawn as a point.
#'   When intervals are requested, its ribbon is replaced by an error bar.
#'   The point uses the global point_size setting and the estimate's line color.
#' @details With the global y_zero setting (TRUE under the default style) the
#'   y axis starts at zero.
#' @return A ggplot object representing the plot.
#'
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#'
#' # Recruitment without confidence intervals
#' plot_recruitment(fit)
#'
#' # Recruitment with 95% confidence intervals
#' plot_recruitment(fit, se = TRUE)
#'
#' # A line with a ribbon, and no title
#' plot_recruitment(fit, se = TRUE, geom = "line", title = FALSE)
#' }
#' @export

plot_recruitment <- function(model_result, line_size = NULL, line_color = NULL, line_type = "solid", se = FALSE, se_color = NULL, se_alpha = NULL, se_type = NULL, return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL, title_hjust = NULL, interval = NULL, geom = NULL){
  # NULL inherits the global palette.
  if (is.null(line_size)) line_size <- .acl_auto_size()
  bar_se_color <- se_color
  colors <- .acl_quantity_colors("recruitment", line_color, se_color)
  line_color <- colors$line
  se_color <- colors$se
  # Error bars are thin lines: draw them opaque unless the call sets se_alpha.
  errorbar_alpha <- if (is.null(se_alpha)) 1 else se_alpha
  if (is.null(se_alpha)) se_alpha <- acl_theme("se_alpha")

  interval <- .acl_interval_type(interval)
  form <- .acl_geom_form(geom)
  quantity <- .acl_plot_population_data(model_result, "Rec", "Rec", se)
  # A ribbon suits a line and error bars suit bars.
  se_type <- if (is.null(se_type)) (if (form == "bar") "errorbar" else "ribbon") else
    match.arg(se_type, c("ribbon", "errorbar"))
  # Extract the validated recruitment data.
  recruitment <- quantity$value

  # Make sure it's a data frame
  if(!is.data.frame(recruitment)){
    recruitment <- as.data.frame(recruitment)
  }

  # Add Year to the recruitment data
  recruitment$Year <- model_result[["year"]]
  current_theme <- .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size, strip_text_size, legend_text_size, base_theme = base_theme, title_hjust = title_hjust, quantity = "recruitment")
  if (!se){
    # Plot recruitment over the years using ggplot2
    p <- ggplot2::ggplot(recruitment, ggplot2::aes(x = Year, y = recruitment)) +
      (if (form == "bar") .acl_bar_layers("Year", "recruitment", line_color, model_result[["year"]]) else
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)) +
      ggplot2::labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", "year"), y = if (!is.null(ylab)) ylab else .acl_lab("y", "rec"), title = .acl_plot_title(title, "Rec")) +
      .acl_scale_x(x_breaks, n_breaks = 10, values = model_result[["year"]], time = TRUE) +
      .acl_y_zero() + current_theme

    data_out <-recruitment


  } else {

     # Filter rows that contain "Rec"
    ss_rec <- quantity$se

    # Calculate confidence intervals
    confidence_intervals_rec <- data.frame(
      estimate = ss_rec[, "Estimate"],
      lower = .acl_interval(ss_rec[, "Estimate"], ss_rec[, "Std. Error"], interval)$lower,
      upper = .acl_interval(ss_rec[, "Estimate"], ss_rec[, "Std. Error"], interval)$upper
    )

    confidence_intervals_rec$Year <-  model_result[["year"]]

    # The estimate as a line or bars, and its interval as a ribbon or error bars.
    estimate_layer <- if (form == "bar")
      .acl_bar_layers("Year", "estimate", line_color, model_result[["year"]]) else
      ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
    interval_layer <- if (se_type == "ribbon")
      ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) else
      if (form == "bar")
        .acl_bar_layers("Year", "estimate", line_color, model_result[["year"]], se = TRUE, se_color = bar_se_color,
                        se_alpha = errorbar_alpha)[-1L] else
        ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color, alpha = errorbar_alpha,
                               width = .acl_cap_width(model_result[["year"]]))
    # Plot recruitment over the years with confidence intervals using ggplot2
    p <- ggplot2::ggplot(confidence_intervals_rec, ggplot2::aes(x = Year, y = estimate)) +
      estimate_layer + interval_layer +
      ggplot2::labs(y = if (!is.null(ylab)) ylab else .acl_lab("y", "rec"), x = if (!is.null(xlab)) xlab else .acl_lab("x", "year"), title = .acl_plot_title(title, "Rec_se")) +
      .acl_scale_x(x_breaks, n_breaks = 10, values = model_result[["year"]], time = TRUE) +
      .acl_y_zero() + current_theme

    data_out <-confidence_intervals_rec

  }
  p <- .acl_show_singletons(p, intersect(c("AgeGroup", "LengthGroup"), names(p$data)))

  p <- .acl_tidy_axes(p)
  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}
