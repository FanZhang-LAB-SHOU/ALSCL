utils::globalVariables(c("relative", "Series"))

#' Plot relative catch by time step
#'
#' Plots the model catch in numbers or in weight divided by its mean, from
#' [relative_catch()], and optionally a reported catch series divided by its
#' mean over the same time steps. Use it to compare the trend of the model
#' catch with reported catch.
#'
#' @param fit A fitted ACL or ALSCL result, including a saved assessment read
#'   with [read_assessment()].
#' @param observed NULL or a data frame of reported catch, drawn as points.
#'   Required columns: `year` (the time step, as in `fit$year`) and `catch`
#'   (reported catch in numbers or in weight, to match `type`, in any unit).
#'   Rows of time steps that are not in the fit and rows with a missing catch
#'   are not drawn.
#' @param type `"number"` (default): catch in numbers. `"weight"`: catch in
#'   weight.
#' @param years NULL or the time steps over which the mean is calculated, as
#'   values of `fit$year`. NULL uses all time steps of the fit, or, with
#'   `observed`, the time steps of the fit that have a reported catch. With
#'   `observed`, time steps without a reported catch are left out of `years`.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting.
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. Line type. Default is "solid".
#' @param point_size Numeric or NULL. Size of the points of `observed`; NULL
#'   inherits the global point_size setting.
#' @param observed_color Character or NULL. Colour of the points of
#'   `observed`; NULL inherits the global observed_color setting.
#' @param observed_name Character. Name of the reported series in the legend.
#'   Default is "Reported catch".
#' @param return_data Logical. Whether to return the plotted data with the
#'   plot. Default is FALSE.
#' @inheritParams plot_SSB
#' @return A ggplot object, or a list with `plot`, `data` (the model series:
#'   Year, relative and extrapolated) and `observed` (the reported series:
#'   Year and relative, or NULL) when `return_data = TRUE`.
#' @details ACL and ALSCL are fitted to a survey index alone. Such a fit has
#'   no information on the absolute level of catch or of the fishing mortality
#'   rate, which depend on the assumed natural mortality rate and the assumed
#'   survey catchability (see [relative_catch()]). Only the trend of the model
#'   catch should be compared with reported catch. Both series are therefore
#'   divided by their mean over the same time steps, and the y-axis label
#'   states that the values are relative. The subtitle gives the time steps of
#'   the mean. A dotted horizontal line marks the value 1, the mean of each
#'   series over those time steps.
#'
#'   No observation informs the fishing mortality rate in the terminal time
#'   step, so the model catch in that time step is a prediction;
#'   `return_data = TRUE` marks it in the column `extrapolated`.
#'
#'   For an ACL result with neither a live TMB object nor a stored recipe,
#'   catch in weight is unavailable and `type = "weight"` is an error.
#'
#'   The title uses the theme key `relative_catch`; the axis labels use
#'   `xlab$year` and `ylab$relative_catch_number` or
#'   `ylab$relative_catch_weight`.
#' @seealso [relative_catch()], [plot_catch()].
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' plot_relative_catch(fit)
#'
#' # With a reported catch series. These values are made up for the example;
#' # the unit does not matter, because both series are divided by their mean.
#' reported <- data.frame(year = fit$year[1:15],
#'                        catch = 1000 * (1 + 0.5 * sin(seq_len(15) / 3)))
#' plot_relative_catch(fit, observed = reported, type = "weight")
#' }
#' @export
plot_relative_catch <- function(fit, observed = NULL, type = c("number", "weight"), years = NULL,
                                line_size = NULL, line_color = NULL, line_type = "solid",
                                point_size = NULL, observed_color = NULL,
                                observed_name = "Reported catch", return_data = FALSE,
                                title = NULL, xlab = NULL, ylab = NULL,
                                font_family = NULL, title_size = NULL, axis_title_size = NULL,
                                axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL,
                                x_breaks = NULL, base_theme = NULL, title_hjust = NULL) {
  type <- match.arg(type)
  .acl_check_flag(return_data, "return_data")
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(point_size)) point_size <- acl_theme("point_size")
  if (is.null(observed_color)) observed_color <- acl_theme("observed_color")

  info <- .acl_derived_fit(fit)
  times <- info$years
  reference <- .acl_year_positions(years, times)
  reported <- NULL
  if (!is.null(observed)) {
    .acl_check_series_name(observed_name, "observed_name")
    if (identical(observed_name, "Model")) stop("observed_name must differ from \"Model\".", call. = FALSE)
    if (!is.data.frame(observed) || !all(c("year", "catch") %in% names(observed)) ||
        !is.numeric(observed$year) || !is.numeric(observed$catch))
      stop("observed must be a data frame with the numeric columns year (time step) and catch (reported catch).",
           call. = FALSE)
    if (any(observed$catch < 0, na.rm = TRUE)) stop("Reported catch in observed must be nonnegative.", call. = FALSE)
    position <- vapply(observed$year, function(y) {
      hit <- if (is.finite(y)) which(abs(times - y) <= 1e-8 * max(1, abs(y))) else integer()
      if (length(hit)) hit[1L] else NA_integer_
    }, integer(1))
    keep <- !is.na(position) & is.finite(observed$catch)
    if (anyDuplicated(position[keep]))
      stop("observed must have one reported catch per time step.", call. = FALSE)
    reference <- intersect(reference, position[keep])
    if (!length(reference))
      stop("observed has no reported catch in the time steps of fit",
           if (is.null(years)) "" else " selected by years", ".", call. = FALSE)
    scale <- mean(observed$catch[keep][position[keep] %in% reference])
    if (!is.finite(scale) || scale <= 0)
      stop("Mean reported catch over the reference time steps must be positive.", call. = FALSE)
    reported <- data.frame(Year = times[position[keep]], relative = observed$catch[keep] / scale,
                           Series = observed_name)
    reported <- reported[order(reported$Year), , drop = FALSE]
  }
  model <- relative_catch(fit, years = times[reference])
  value <- model[[if (type == "number") "catch_number" else "catch_weight"]]
  if (anyNA(value))
    stop("Catch in weight of this ACL fit is unavailable: it needs the weight at length used in the fit ",
         "(a live TMB object or a stored recipe). Use type = \"number\".", call. = FALSE)
  data <- data.frame(Year = times, relative = value, extrapolated = model$extrapolated)

  p <- ggplot2::ggplot(data, ggplot2::aes(x = Year, y = relative)) +
    ggplot2::geom_hline(yintercept = 1, linetype = "dotted", color = acl_theme("hline_color") %||% "grey55")
  if (is.null(reported)) {
    p <- p + ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
  } else {
    p <- p + ggplot2::geom_line(ggplot2::aes(color = "Model"), linewidth = line_size, linetype = line_type) +
      ggplot2::geom_point(data = reported, ggplot2::aes(x = Year, y = relative, color = Series),
                          size = point_size, inherit.aes = FALSE) +
      .acl_series_legend(c("Model", observed_name), c(line_color, observed_color),
                         c(line_type, "blank"), c(NA, 16))
  }
  mean_years <- times[reference]
  contiguous <- length(reference) == diff(range(reference)) + 1L
  ends <- .acl_time_labels(range(mean_years), fit$growth_step, prefix = FALSE)
  subtitle <- if (length(mean_years) == 1L) paste0("Divided by the value in time step ", ends[1L]) else
    if (contiguous) paste0("Divided by the mean of the time steps ", ends[1L], "-", ends[2L]) else
      paste0("Divided by the mean of ", length(mean_years), " time steps between ", ends[1L], " and ", ends[2L])
  p <- p +
    ggplot2::labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", "year"),
                  y = if (!is.null(ylab)) ylab else .acl_lab("y", paste0("relative_catch_", type)),
                  title = if (!is.null(title)) title else .acl_title("relative_catch"),
                  subtitle = subtitle) +
    .acl_scale_x(x_breaks, n_breaks = 10, values = times) +
    .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size, strip_text_size,
                    legend_text_size, base_theme = base_theme, title_hjust = title_hjust)
  if (!is.null(reported)) p <- p + .acl_series_theme()
  p <- .acl_show_singletons(p, point_size = point_size)
  if (return_data) list(plot = p, data = data, observed = reported[c("Year", "relative")]) else p
}
