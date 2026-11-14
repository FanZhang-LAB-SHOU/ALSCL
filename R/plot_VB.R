#' Plot mean length at age: the von Bertalanffy curve or the fitted numbers
#'
#' Plots mean length at age of a fitted model against age. What is drawn
#' depends on the model, because the growth parameters have different
#' meanings in ACL and ALSCL.
#'
#' For an ACL fit, the asymptotic length (Linf), the growth rate (vbk, per
#' year) and t0 (the theoretical age at zero length, in years) are the
#' parameters of a von Bertalanffy curve of mean length at age in the
#' population. The figure shows this curve, and the annotation gives Linf in
#' the length unit of the data and k per year.
#'
#' For an ALSCL fit, Linf and k set the mean growth increment at length, and
#' Linf, k and t0 set the mean length of recruits (see [length_at_age()]).
#' They are not the parameters of a von Bertalanffy curve of mean length at
#' age. The figure therefore shows mean length at age calculated from the
#' fitted numbers by length bin and age class ([length_at_age()]), averaged
#' over the time steps, and has no annotation of Linf and k. The curve
#' computed from Linf, k and t0 can be added as a reference line with
#' `parameter_curve = TRUE`.
#' @param model_result A fitted ACL or ALSCL result. For the von Bertalanffy
#'   curve the list needs a "report" component with "Linf", "vbk" and "t0".
#'   Mean length at age from the fitted numbers needs a result of
#'   [run_alscl()] or [run_acl()], or a saved assessment.
#' @param age_range NULL or a finite increasing numeric pair in years. For the
#'   von Bertalanffy curve of an ACL fit, NULL uses the fitted age range in
#'   model_result$age, or c(1, 25) for saved fits without age metadata; the
#'   automatic lower endpoint is at least t0, and an explicit range must
#'   start at or after t0 to avoid negative-length extrapolation. For mean
#'   length at age from the fitted numbers, NULL uses all age classes and an
#'   explicit range selects the age classes within it; the curve from Linf,
#'   k and t0 is then drawn from t0 or the start of the range, whichever is
#'   later.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting (default 1.5).
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. The type of the line in the plot. Default is "solid".
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_alpha Numeric or NULL. Transparency of the interval ribbon; NULL inherits the
#'   global se_alpha setting (default 0.2). Error bars are opaque unless se_alpha is given.
#' @param se_type Character. Type of interval display: "ribbon" (shaded area) or
#'   "errorbar" (error bars). Error bars are drawn at the fitted ages in
#'   model_result$age that lie within age_range. Results saved without age
#'   metadata, and ranges that contain no fitted age, use every plotted age.
#'   Default is "ribbon".
#' @param se Logical. Whether to draw the 95% confidence interval of the curve
#'   computed from Linf, k and t0 (delta method with the covariance of the
#'   growth parameters). Default is FALSE. The interval belongs to that
#'   curve: for an ACL fit it is the interval of the figure, and for an ALSCL
#'   fit it is drawn around the reference line when `parameter_curve = TRUE`.
#'   The model reports no standard error for mean length at age from the
#'   fitted numbers; see Details.
#' @param text_size Numeric. Size of the growth-parameter annotation in all
#'   display modes. Default is 5.
#' @param text_color Character. Color of the growth-parameter annotation in all
#'   display modes. Default is "black".
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
#' @param observed NULL or a data frame of observed mean length at age from
#'   age readings, drawn as points. Required columns: `age` (years) and
#'   `mean_length`. Optional columns: `sd_length` (or `sd`), drawn as bars of
#'   one standard deviation on each side of the mean, or `lower` and `upper`,
#'   drawn as the bars of an interval; and `year` (the time step, on the
#'   scale of `model_result$year`). Every row is drawn as one point. With
#'   `years`, only the rows of those time steps are drawn; rows without a
#'   time step are always drawn.
#' @param basis `"population"` (default): mean length at age in the
#'   population. `"survey"`: mean length at age in the survey catch, that is,
#'   with numbers at length multiplied by the survey catchability at length
#'   used in the fit. Use `"survey"` to compare with age readings of fish
#'   caught in the survey. For an ACL fit, `"survey"` draws mean length at age
#'   from the age-length key in place of the von Bertalanffy curve, which
#'   describes the population.
#' @param years NULL (all time steps) or the time steps over which mean length
#'   at age from the fitted numbers is averaged, as values of
#'   `model_result$year`. It does not change the von Bertalanffy curve of an
#'   ACL fit, which is the same in every time step.
#' @param parameter_curve Logical. For an ALSCL fit, and for an ACL fit with
#'   `basis = "survey"`, whether to add the curve computed from Linf, k and
#'   t0 as a dashed reference line, named in the legend and explained in the
#'   caption. Default is FALSE. It has no effect on the von Bertalanffy curve
#'   of an ACL fit, which is that curve.
#' @param point_size Numeric or NULL. Size of the observed points; NULL
#'   inherits the global point_size setting.
#' @param observed_color Character or NULL. Colour of the observed points;
#'   NULL inherits the global observed_color setting.
#' @param observed_name Character. Name of the observed points in the legend.
#'   Default is "Age readings".
#' @details For an ALSCL fit, and for any fit with `basis = "survey"`, mean
#'   length at age is that of [length_at_age()]: for ALSCL from the estimated
#'   numbers by length bin, age class and time step, and for ACL from the
#'   age-length key. Each length bin is represented by its midpoint. The line
#'   connects the values of the age classes, and the oldest age class is a
#'   plus group, marked with a plus sign on the age axis. The subtitle states
#'   the basis and the time steps of the mean. [plot_length_at_age()] shows
#'   the values of each time step.
#'
#'   In an ALSCL fit with the original structure, the curve computed from
#'   Linf, k and t0 is the mean length at age in the first time step and the
#'   mean length of recruits in every time step. With
#'   `structure = list(initial_length = "growth")` (part of
#'   `structure = "von_bertalanffy"`), its value at the first age class is
#'   the mean length of recruits. In later time steps the lengths of a cohort
#'   follow from the growth increments and from mortality at length, so the
#'   curve is not the mean length at age of the fitted population. The
#'   caption of the figure states which of the two cases applies.
#'
#'   Changes from earlier versions for ALSCL fits: the default figure showed
#'   the curve computed from Linf, k and t0 with an annotation of Linf and k.
#'   The annotation is now drawn only with that curve, under the heading
#'   "Curve from Linf, k and t0". `se = TRUE` without `parameter_curve = TRUE` gives a
#'   warning and draws the estimate only, because the model reports no
#'   standard error for mean length at age from the fitted numbers. An
#'   explicit `age_range` that starts before t0 is no longer an error for
#'   these fits, because the fitted numbers are not extrapolated.
#'
#'   If the growth covariance is unavailable or unusable, a request for
#'   confidence intervals warns and draws the estimate only, preserving all
#'   supplied labels, axis settings, text styles and theme options. The parameter
#'   annotation is retained with and without intervals and inherits font_family.
#'   The y-axis inherits the global growth label unless ylab is supplied.
#'   The package holds no unit for length; give it in ylab, for example
#'   `ylab = "Length (cm)"`. The title uses the theme key `VB` for the von
#'   Bertalanffy curve of an ACL fit and `length_at_age` otherwise.
#'   An automatic age range with no positive span at or above t0 is rejected;
#'   supply an explicit biologically meaningful age_range in that case.
#' @return A ggplot object representing the plot.
#' @seealso [length_at_age()], [plot_length_at_age()], [plot_compare_growth()].
#' @export
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' plot_VB(fit)
#' plot_VB(fit, age_range = c(1, 25))
#'
#' # Observed mean length at age from age readings, drawn as points. These
#' # values are made up for the example.
#' readings <- data.frame(age = 1:8,
#'                        mean_length = c(12, 20, 27, 32, 37, 40, 43, 45),
#'                        sd_length = c(2, 2.5, 3, 3, 3.5, 3.5, 4, 4))
#' plot_VB(fit, observed = readings, ylab = "Length (cm)")
#'
#' # Mean length at age in the survey catch, the basis to use for age
#' # readings of fish caught in the survey
#' plot_VB(fit, observed = readings, basis = "survey", ylab = "Length (cm)")
#' }
plot_VB <- function(model_result, age_range = NULL, line_size = NULL, line_color = NULL, line_type = "solid", se = FALSE, se_color = NULL, se_alpha = NULL, se_type = c("ribbon", "errorbar"),text_color="black",text_size=5, title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL, title_hjust = NULL,
                    observed = NULL, basis = c("population", "survey"), years = NULL,
                    parameter_curve = FALSE, point_size = NULL, observed_color = NULL,
                    observed_name = "Age readings"){
  # NULL 继承全局色板 / NULL inherits the global palette.
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")
  # Error bars are thin lines: draw them opaque unless the call sets se_alpha.
  errorbar_alpha <- if (is.null(se_alpha)) 1 else se_alpha
  if (is.null(se_alpha)) se_alpha <- acl_theme("se_alpha")
  if (is.null(point_size)) point_size <- acl_theme("point_size")
  if (is.null(observed_color)) observed_color <- acl_theme("observed_color")

  .acl_check_flag(se, "se")
  .acl_check_flag(parameter_curve, "parameter_curve")
  se_type <- match.arg(se_type)
  basis <- match.arg(basis)
  obs <- .acl_observed_length(observed)
  if (!is.null(obs)) .acl_check_series_name(observed_name, "observed_name")

  # In ALSCL, Linf, k and t0 are not the parameters of a curve of mean length
  # at age, and on the survey basis no model has such a curve: both cases
  # draw mean length at age from numbers by length and age.
  if (identical(.detect_model_name(model_result, NA_character_), "ALSCL") || basis == "survey")
    return(.acl_plot_mean_length(model_result, obs, basis, years, age_range, parameter_curve,
      se, se_type, line_size, line_color, line_type, se_color, se_alpha, errorbar_alpha,
      text_color, text_size, point_size, observed_color, observed_name, title, xlab, ylab,
      font_family, x_breaks,
      .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size, strip_text_size,
                      legend_text_size, base_theme = base_theme, title_hjust = title_hjust)))
  if (!is.null(years)) {
    if (!is.numeric(years) || !length(years) || any(!is.finite(years)))
      stop("years must be finite numeric time steps of fit.", call. = FALSE)
    obs <- .acl_observed_years(obs, years)
  }

  growth <- .acl_growth_parameters(model_result)
  Linf <- growth$Linf; k <- growth$k; t0 <- growth$t0

  automatic_range <- is.null(age_range)
  if (automatic_range) {
    fitted_ages <- model_result$age
    if (is.null(fitted_ages)) {
      age_range <- c(1, 25)
    } else {
      if (!is.numeric(fitted_ages) || !length(fitted_ages) || any(!is.finite(fitted_ages)))
        stop("model_result$age must contain finite numeric ages; supply age_range for saved fits without usable age metadata.",
             call. = FALSE)
      age_range <- range(fitted_ages)
    }
    age_range[1L] <- max(age_range[1L], t0)
  }
  .acl_check_age_range(age_range, "; supply an explicit range at or above t0.")
  if (age_range[1L] < t0)
    stop("age_range must start at or after t0; earlier ages extrapolate to negative lengths.",
         call. = FALSE)

  data <- .acl_growth_curve(growth, age_range)

  # Resolve uncertainty before choosing the layers so that an estimate-only
  # fallback uses the same supplied styling arguments as a direct plain plot.
  interval <- if (se) .acl_growth_interval(model_result, data$age) else NULL
  if (se && is.null(interval)) {
    warning("Growth confidence interval requires a finite full parameter covariance matrix; drawing the estimate only.")
    se <- FALSE
  }

  p <- ggplot2::ggplot(data, ggplot2::aes(x = age, y = length))
  if (se) {
    data$lower <- interval$lower; data$upper <- interval$upper
    p <- ggplot2::ggplot(data, ggplot2::aes(x = age, y = length)) +
      .acl_growth_interval_layer(model_result, data, age_range, se_type, se_color, se_alpha, errorbar_alpha)
  }
  annotation_font <- if (is.null(font_family)) acl_theme("font_family") else font_family
  has_observed <- !is.null(obs) && nrow(obs) > 0L
  curve_name <- "Von Bertalanffy curve (model)"
  if (has_observed && identical(observed_name, curve_name))
    stop("observed_name must differ from \"", curve_name, "\".", call. = FALSE)
  p <- p +
    (if (has_observed) ggplot2::geom_line(ggplot2::aes(color = curve_name), linewidth = line_size,
                                          linetype = line_type) else
      ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)) +
    ggplot2::labs(x = if (is.null(xlab)) .acl_lab("x", "age") else xlab,
                  y = if (is.null(ylab)) .acl_lab("y", "growth") else ylab,
                  title = if (is.null(title)) .acl_title("VB") else title) +
    .acl_growth_annotation(growth, text_size, text_color, annotation_font) +
    .acl_scale_x(x_breaks, n_breaks = 10, values = c(data$age, obs$age)) +
    .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size,
                    strip_text_size, legend_text_size, base_theme = base_theme, title_hjust = title_hjust)
  if (has_observed)
    p <- p + .acl_observed_layers(obs, ggplot2::aes(x = age, y = mean_length), observed_color,
                                  point_size, label = observed_name) +
      .acl_series_legend(c(curve_name, observed_name), c(line_color, observed_color),
                         c(line_type, "blank"), c(NA, 16)) +
      ggplot2::labs(caption = .acl_caption(.acl_observed_caption(obs))) + .acl_series_theme()

  return(p)
}

# Growth parameters of a fit, checked.
.acl_growth_parameters <- function(model_result) {
  Linf <- model_result$report$Linf
  k <- model_result$report$vbk
  t0 <- model_result$report$t0
  valid_scalar <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)
  if (!valid_scalar(Linf) || Linf <= 0 || !valid_scalar(k) || k <= 0 || !valid_scalar(t0))
    stop("Growth parameters Linf and vbk must be finite positive scalars, and t0 must be finite.",
         call. = FALSE)
  list(Linf = Linf, k = k, t0 = t0)
}

.acl_check_age_range <- function(age_range, advice = ".") {
  if (!is.numeric(age_range) || length(age_range) != 2L || any(!is.finite(age_range)) ||
      age_range[2L] <= age_range[1L])
    stop("age_range must be a finite increasing pair with a positive span", advice, call. = FALSE)
  invisible(age_range)
}

# The curve Linf * (1 - exp(-k * (age - t0))) on a 0.1-year grid that
# includes both ends of the range, also for ranges narrower than one step.
.acl_growth_curve <- function(growth, age_range) {
  ages <- seq(age_range[1L], age_range[2L], by = 0.1)
  if (tail(ages, 1L) < age_range[2L]) ages <- c(ages, age_range[2L])
  data.frame(age = ages, length = growth$Linf * (1 - exp(-growth$k * (ages - growth$t0))))
}

# Interval of the curve computed from Linf, k and t0: a ribbon, or one error
# bar per fitted age. One bar per fitted age keeps the bars apart; the
# 0.1-year grid of the curve would merge them into a band.
.acl_growth_interval_layer <- function(model_result, data, age_range, se_type, se_color, se_alpha,
                                       errorbar_alpha) {
  if (se_type == "ribbon")
    return(ggplot2::geom_ribbon(data = data, ggplot2::aes(x = age, ymin = lower, ymax = upper),
                                alpha = se_alpha, fill = se_color, inherit.aes = FALSE))
  bars <- data
  fitted_ages <- model_result$age
  if (is.numeric(fitted_ages)) {
    fitted_ages <- fitted_ages[is.finite(fitted_ages) & fitted_ages >= age_range[1L] &
                                 fitted_ages <= age_range[2L]]
    at_ages <- if (length(fitted_ages)) .acl_growth_interval(model_result, fitted_ages) else NULL
    if (!is.null(at_ages))
      bars <- data.frame(age = fitted_ages, length = at_ages$estimate,
                         lower = at_ages$lower, upper = at_ages$upper)
  }
  bar_width <- if (!identical(bars, data) && nrow(bars) > 1L)
    min(.3, .4 * min(diff(bars$age))) else .1
  ggplot2::geom_errorbar(data = bars, ggplot2::aes(x = age, ymin = lower, ymax = upper),
                         color = se_color, alpha = errorbar_alpha, width = bar_width, inherit.aes = FALSE)
}

# Annotation of Linf and k in the upper left corner, both lines left-justified
# at the same position inside the panel.
.acl_growth_annotation <- function(growth, text_size, text_color, font, heading = NULL) {
  ggplot2::annotate("text", x = -Inf, y = Inf,
    label = paste0(if (!is.null(heading)) paste0("  ", heading, "\n"),
                   "  Linf = ", round(growth$Linf, 2), "\n  k = ", round(growth$k, 2), " per year"),
    hjust = 0, vjust = if (is.null(heading)) 1.5 else 1.3, size = text_size, color = text_color,
    family = font)
}

# Mean length at age from numbers by length and age, against age: the figure
# of plot_VB() for an ALSCL fit and for the survey basis.
.acl_plot_mean_length <- function(model_result, obs, basis, years, age_range, parameter_curve,
                                  se, se_type, line_size, line_color, line_type, se_color, se_alpha,
                                  errorbar_alpha, text_color, text_size, point_size, observed_color,
                                  observed_name, title, xlab, ylab, font_family, x_breaks, theme_layers) {
  series <- .acl_growth_series(model_result, basis, years, "model_result")
  obs <- .acl_observed_years(obs, years)
  shown <- seq_along(series$ages)
  if (!is.null(age_range)) {
    if (!is.numeric(age_range) || length(age_range) != 2L || any(!is.finite(age_range)) ||
        age_range[2L] < age_range[1L])
      stop("age_range must be a finite increasing pair.", call. = FALSE)
    shown <- which(series$ages >= age_range[1L] & series$ages <= age_range[2L])
    if (!length(shown))
      stop("age_range contains no age class of the fit (model_result$age).", call. = FALSE)
  } else age_range <- range(series$ages)
  data <- data.frame(age = series$ages[shown], length = series$mean[shown])
  main_name <- "Mean length at age (model)"
  is_acl <- series$model == "ACL"
  curve_name <- if (is_acl) "Von Bertalanffy curve (population)" else "Curve from Linf, k and t0"

  curve <- NULL; growth <- NULL
  if (parameter_curve) {
    growth <- .acl_growth_parameters(model_result)
    curve_range <- c(max(age_range[1L], growth$t0), age_range[2L])
    if (curve_range[2L] > curve_range[1L]) curve <- .acl_growth_curve(growth, curve_range) else
      warning("The curve computed from Linf, k and t0 has no positive age span at or above t0 within the plotted ages; it is not drawn.",
              call. = FALSE)
  }
  if (se && is.null(curve)) {
    warning("The model reports no standard error for mean length at age from the fitted numbers; drawing the estimate only. ",
            "se = TRUE applies to the curve computed from Linf, k and t0, which is drawn with parameter_curve = TRUE.",
            call. = FALSE)
    se <- FALSE
  }
  if (se) {
    interval <- .acl_growth_interval(model_result, curve$age)
    if (is.null(interval)) {
      warning("Growth confidence interval requires a finite full parameter covariance matrix; drawing the estimate only.")
      se <- FALSE
    } else { curve$lower <- interval$lower; curve$upper <- interval$upper }
  }
  has_observed <- !is.null(obs) && nrow(obs) > 0L
  names_used <- c(main_name, if (!is.null(curve)) curve_name)
  if (has_observed && observed_name %in% names_used)
    stop("observed_name must differ from the names of the model series: ",
         paste0("\"", names_used, "\"", collapse = ", "), ".", call. = FALSE)
  legend <- has_observed || !is.null(curve)

  p <- ggplot2::ggplot(data, ggplot2::aes(x = age, y = length))
  if (se) p <- p + .acl_growth_interval_layer(model_result, curve, range(curve$age), se_type,
                                              se_color, se_alpha, errorbar_alpha)
  p <- p + if (legend) ggplot2::geom_line(ggplot2::aes(color = main_name), linewidth = line_size,
                                          linetype = line_type) else
    ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
  if (!is.null(curve))
    p <- p + ggplot2::geom_line(data = curve, ggplot2::aes(x = age, y = length, color = curve_name),
                                linewidth = line_size * 0.6, linetype = "dashed", inherit.aes = FALSE)
  if (has_observed)
    p <- p + .acl_observed_layers(obs, ggplot2::aes(x = age, y = mean_length), observed_color,
                                  point_size, label = observed_name)
  if (legend) {
    reference_color <- acl_theme("hline_color") %||% "grey55"
    p <- p + .acl_series_legend(
      c(main_name, if (!is.null(curve)) curve_name, if (has_observed) observed_name),
      c(line_color, if (!is.null(curve)) reference_color, if (has_observed) observed_color),
      c(line_type, if (!is.null(curve)) "dashed", if (has_observed) "blank"),
      c(NA, if (!is.null(curve)) NA, if (has_observed) 16))
  }
  if (!is.null(curve))
    p <- p + .acl_growth_annotation(growth, text_size, text_color,
      if (is.null(font_family)) acl_theme("font_family") else font_family,
      heading = paste0(curve_name, ":"))
  curve_text <- if (is.null(curve) || is_acl) NULL else
    if (identical(model_result$structure$initial_length, "growth"))
      "Curve from Linf, k and t0: its value at the first age class is the mean length of recruits." else
      "Curve from Linf, k and t0: mean length at age in the first time step and mean length of recruits in every time step."
  caption <- c(curve_text, if (has_observed) .acl_observed_caption(obs))
  plus_age <- if (length(series$ages) %in% shown) series$ages[length(series$ages)] else NULL
  p <- p +
    ggplot2::labs(x = if (is.null(xlab)) .acl_lab("x", "age") else xlab,
                  y = if (is.null(ylab)) .acl_lab("y", "growth") else ylab,
                  title = if (is.null(title)) .acl_title("length_at_age") else title,
                  subtitle = .acl_growth_subtitle(basis, series$years, series$all_years,
                                                  model_result$growth_step),
                  caption = .acl_caption(caption)) +
    .acl_scale_x(x_breaks, n_breaks = 10, values = c(data$age, obs$age),
                 auto_breaks = if (has_observed && any(obs$age > max(data$age) | obs$age < min(data$age))) NULL else
                   .acl_age_breaks(data$age, 10),
                 labels = .acl_age_axis_labels(plus_age), check_overlap = TRUE) +
    theme_layers
  if (legend) p <- p + .acl_series_theme()
  .acl_show_singletons(p, point_size = point_size)
}

# Delta method using the full covariance, including correlations and t0.
.acl_growth_interval <- function(model_result, ages) {
  cov <- model_result$vcov
  if (is.null(cov) || is.null(rownames(cov)) || any(!is.finite(cov)) || identical(model_result$pdHess, FALSE)) return(NULL)
  r <- model_result$report; delta <- ages-r$t0; decay <- exp(-r$vbk*delta)
  mu <- r$Linf*(1-decay)
  jacobian <- cbind(log_Linf = mu, log_vbk = r$Linf*decay*r$vbk*delta,
                    t0 = -r$Linf*r$vbk*decay,
                    log_t0 = -r$Linf*r$vbk*decay*(r$t0 - .acl_scale_settings(model_result)$t0_lower))
  keys <- intersect(colnames(jacobian), rownames(cov))
  se <- rep(0, length(ages))
  if (length(keys)) {
    g <- jacobian[,keys,drop=FALSE]
    variance <- rowSums((g %*% cov[keys,keys,drop=FALSE])*g)
    if (any(variance < -1e-8)) return(NULL)
    se <- sqrt(pmax(0,variance))
  }
  data.frame(estimate=mu, se=se, lower=pmax(0,mu-1.96*se), upper=mu+1.96*se)
}
