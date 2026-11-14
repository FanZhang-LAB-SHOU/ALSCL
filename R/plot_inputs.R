utils::globalVariables(c("Value", "AgeClass", "Curve", "Year", "Age", "Length"))

# Plots of the fixed inputs of a fit: the natural mortality rate and survey
# catchability. Both are assumptions supplied by the user, not estimates.

# Natural mortality rate of a fit in the form in which the model used it:
# "scalar" (one number), "age_time" (an A x Y matrix) or "length" (one value
# per length bin, ALSCL only). The stored recipe is read first; a fit without
# a recipe is read from its live TMB object.
.acl_fit_natural_mortality <- function(fit, info) {
  A <- length(info$ages); Y <- length(info$years); L <- length(fit$len_mid)
  M <- fit$recipe$args$M
  if (is.numeric(M) && length(M)) return(.acl_M_input(M, A, L, Y))
  data <- tryCatch(fit$obj$env$data, error = function(e) NULL)
  by_age <- data[["M_AY"]]
  if (is.matrix(by_age) && identical(dim(by_age), c(A, Y)) && all(is.finite(by_age)))
    return(list(form = "age_time", M = unname(by_age)))
  by_length_age <- data[["M_LAY"]]
  if (is.null(by_length_age)) by_length_age <- fit$report[["M_LAY"]]
  if (is.array(by_length_age) && length(dim(by_length_age)) == 3L &&
      identical(dim(by_length_age)[2:3], c(A, Y)) && all(is.finite(by_length_age))) {
    by_length <- by_length_age[, 1L, 1L]
    if (all(by_length_age == array(by_length, dim(by_length_age))))
      return(list(form = "length", M = as.numeric(by_length)))
    return(list(form = "age_time", M = unname(matrix(by_length_age[1L, , ], A, Y))))
  }
  single <- data[["M"]]
  if (is.null(single)) single <- fit[["M"]]
  if (is.numeric(single) && length(single) == 1L && is.finite(single))
    return(list(form = "scalar", M = as.numeric(single)))
  stop("The natural mortality rate of fit is unavailable: fit has neither a stored recipe nor a live TMB object.",
       call. = FALSE)
}

# Time steps written as ranges, for example "2000-2004, 2010".
.acl_time_ranges <- function(times, step = NULL) {
  labels <- .acl_time_labels(times, step, prefix = FALSE)
  if (length(times) == 1L) return(labels)
  spacing <- min(diff(times))
  run <- cumsum(c(TRUE, abs(diff(times) - spacing) > 1e-8 * max(1, spacing)))
  paste(vapply(split(labels, run), function(x)
    if (length(x) == 1L) x else paste0(x[1L], "-", x[length(x)]), character(1)), collapse = ", ")
}

#' Plot the natural mortality rate used in a fit
#'
#' Plots the natural mortality rate (M) that a fitted ACL or ALSCL model
#' used. M is an input supplied by the user and is not estimated. The figure
#' follows the form of the input: a single value, a rate by age class (and
#' time step), or, for ALSCL, a rate by length.
#'
#' @param fit A fitted ACL or ALSCL result, including a saved assessment read
#'   with [read_assessment()].
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting.
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. Line type. Default is "solid".
#' @param point_size Numeric or NULL. Size of the points at the age classes or
#'   length bins; NULL inherits the global point_size setting.
#' @param facet_ncol Numeric. Columns in facet wrap, for M by age class and
#'   time step. Default is NULL.
#' @param facet_scales Character. Scales for facet wrap. Default is "free".
#' @param return_data Logical. Whether to return the plotted data with the
#'   plot. Default is FALSE.
#' @inheritParams plot_SSB
#' @return A ggplot object, or a list with `plot` and `data` when
#'   `return_data = TRUE`.
#' @details The figure depends on the form of M (see `M` in [run_alscl()]):
#'   \describe{
#'   \item{A single value}{A horizontal line against the time step.}
#'   \item{By age class, the same in every time step}{M against age, with a
#'     point at each age class.}
#'   \item{By age class and time step}{M against the time step, one panel per
#'     age class.}
#'   \item{By length (ALSCL)}{M against the midpoints of the length bins, with
#'     a point at each length bin.}
#'   }
#'   The subtitle names the form. M is an instantaneous rate per model time
#'   step, and the default y-axis label states this time basis, for example
#'   "Natural mortality rate (per year)". The oldest age class is a plus
#'   group and is marked with a plus sign.
#'
#'   The rate is read from the recipe stored in the fit, or from the live TMB
#'   object of a fit without a recipe. The survey index does not inform the
#'   split of total mortality into fishing and natural mortality, so the
#'   level of the estimated fishing mortality rate and of the model catch
#'   depends on this input.
#'
#'   The title uses the theme key `natural_mortality`; the axis labels use
#'   `xlab$year`, `xlab$age` or `xlab$length`, and `ylab$M`.
#' @seealso [plot_survey_catchability()], [lorenzen_M()], [run_alscl()].
#' @examples
#' \donttest{
#' # A natural mortality rate that is higher for the two youngest age classes,
#' # fitted to the last ten years of the example data
#' x <- YTF_example
#' tables <- c("data.CatL", "data.wgt", "data.mat")
#' x[tables] <- lapply(x[tables], function(tab) tab[, c(1, 12:21)])
#' M_at_age <- c(0.5, 0.3, rep(0.2, 13))
#' fit <- run_acl(x, M = matrix(M_at_age, ncol = 1), silent = TRUE)
#' plot_natural_mortality(fit)
#' }
#' @export
plot_natural_mortality <- function(fit, line_size = NULL, line_color = NULL, line_type = "solid",
                                   point_size = NULL, facet_ncol = NULL, facet_scales = "free",
                                   return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL,
                                   font_family = NULL, title_size = NULL, axis_title_size = NULL,
                                   axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL,
                                   x_breaks = NULL, base_theme = NULL, title_hjust = NULL) {
  .acl_check_flag(return_data, "return_data")
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(point_size)) point_size <- acl_theme("point_size")
  info <- .acl_derived_fit(fit)
  input <- .acl_fit_natural_mortality(fit, info)
  ages <- info$ages; times <- info$years
  constant <- input$form == "age_time" && all(input$M == input$M[, 1L])
  line <- ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
  points <- ggplot2::geom_point(size = point_size, color = line_color)
  scale_x <- NULL
  if (input$form == "scalar") {
    data <- data.frame(Year = times, Value = input$M)
    p <- ggplot2::ggplot(data, ggplot2::aes(x = Year, y = Value)) + line
    x_key <- "year"; form <- "One value for all age classes and time steps"
    scale_x <- .acl_scale_x(x_breaks, n_breaks = 10, values = times)
  } else if (input$form == "length") {
    mid <- fit$len_mid
    if (!is.numeric(mid) || length(mid) != length(input$M) || any(!is.finite(mid)))
      stop("fit must contain finite length-bin midpoints that match its natural mortality rate by length.",
           call. = FALSE)
    data <- data.frame(Length = mid, Value = input$M)
    p <- ggplot2::ggplot(data, ggplot2::aes(x = Length, y = Value)) + line + points
    x_key <- "length"; form <- "By length, the same in every time step"
    scale_x <- .acl_scale_x(x_breaks, n_breaks = 10, values = mid)
  } else if (constant) {
    data <- data.frame(Age = ages, Value = input$M[, 1L])
    p <- ggplot2::ggplot(data, ggplot2::aes(x = Age, y = Value)) + line + points
    x_key <- "age"; form <- "By age class, the same in every time step"
    scale_x <- .acl_scale_x(x_breaks, n_breaks = 10, values = ages, auto_breaks = .acl_age_breaks(ages, 10),
                            labels = .acl_age_axis_labels(ages[length(ages)]), check_overlap = TRUE)
  } else {
    labels <- .acl_age_labels(fit, length(ages))
    data <- data.frame(Year = rep(times, each = length(ages)), Age = rep(ages, times = length(times)),
                       AgeClass = factor(rep(labels, times = length(times)), levels = labels),
                       Value = as.numeric(input$M))
    p <- ggplot2::ggplot(data, ggplot2::aes(x = Year, y = Value)) + line +
      ggplot2::facet_wrap(~AgeClass, ncol = facet_ncol, scales = facet_scales)
    x_key <- "year"; form <- "By age class and time step"
    scale_x <- .acl_scale_x(x_breaks, n_breaks = .acl_facet_n_breaks(length(ages), facet_ncol, 5),
                            values = times, check_overlap = TRUE)
  }
  p <- p +
    ggplot2::labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", x_key),
                  y = if (!is.null(ylab)) ylab else .acl_M_label(.acl_rate_basis(fit)),
                  title = if (!is.null(title)) title else .acl_title("natural_mortality"),
                  subtitle = form) +
    scale_x +
    .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size, strip_text_size,
                    legend_text_size, base_theme = base_theme, title_hjust = title_hjust)
  p <- .acl_show_singletons(p, intersect("AgeClass", names(data)), point_size = point_size)
  if (return_data) list(plot = p, data = data) else p
}

#' Plot the survey catchability used in a fit
#'
#' Plots the survey catchability that a fitted ACL or ALSCL model used:
#' catchability at length, by time step when it changes over time, or the
#' catchability multiplier by age class when one was supplied. Survey
#' catchability is an input and is not estimated.
#'
#' @param fit A fitted ACL or ALSCL result, including a saved assessment read
#'   with [read_assessment()].
#' @param type `"length"` (default): survey catchability at length, against
#'   the midpoints of the length bins. `"age"`: the survey catchability
#'   multiplier by age class (`survey_q_age`), against age; an error for a
#'   fit without this input.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting.
#' @param line_color Character or NULL. NULL inherits the global line_color
#'   setting. When catchability at length changes over time, the lines take
#'   the colours of the global palette.
#' @param line_type Character. Line type. Default is "solid".
#' @param point_size Numeric or NULL. Size of the points at the length bins
#'   or age classes; NULL inherits the global point_size setting.
#' @param return_data Logical. Whether to return the plotted data with the
#'   plot. Default is FALSE.
#' @inheritParams plot_SSB
#' @return A ggplot object, or a list with `plot` and `data` when
#'   `return_data = TRUE`.
#' @details Catchability at length is the logistic curve from `sel_L50` and
#'   `sel_L95`, or the values supplied as `survey_q` (see [run_alscl()]). The
#'   supplied values are connected directly. When `survey_q` was supplied by
#'   length and time step and differs among time steps, one line is drawn
#'   for each distinct curve, and the legend gives the time steps of each
#'   curve. A fit without a recipe is read from its live TMB object.
#'
#'   The survey index at length is survey catchability at length multiplied
#'   by the sum over age classes of the multiplier by age and numbers at
#'   length and age. Survey catchability at length is therefore one input for
#'   all age classes. Its level and its descending part are assumptions: the
#'   survey index does not inform them, and the level of the estimated
#'   abundance depends on them.
#'
#'   [plot_compare_selectivity()] draws survey catchability at length of two
#'   fits in one panel. The titles use the theme keys `survey_q` and
#'   `survey_q_age`; the axis labels use `xlab$length` or `xlab$age`, and
#'   `ylab$survey_q` or `ylab$survey_q_age`.
#' @seealso [plot_natural_mortality()], [plot_compare_selectivity()],
#'   [survey_catchability()].
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' plot_survey_catchability(fit)
#' }
#' @export
plot_survey_catchability <- function(fit, type = c("length", "age"),
                                     line_size = NULL, line_color = NULL, line_type = "solid",
                                     point_size = NULL, return_data = FALSE,
                                     title = NULL, xlab = NULL, ylab = NULL,
                                     font_family = NULL, title_size = NULL, axis_title_size = NULL,
                                     axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL,
                                     x_breaks = NULL, base_theme = NULL, title_hjust = NULL) {
  type <- match.arg(type)
  .acl_check_flag(return_data, "return_data")
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(point_size)) point_size <- acl_theme("point_size")
  if (!is.list(fit)) stop("fit must be a fitted ACL or ALSCL result.", call. = FALSE)
  subtitle <- NULL
  if (type == "age") {
    info <- .acl_derived_fit(fit)
    multiplier <- fit$recipe$args$survey_q_age
    if (is.null(multiplier)) multiplier <- tryCatch(fit$obj$env$data$q_age, error = function(e) NULL)
    if (is.null(multiplier))
      stop("fit has no survey catchability multiplier by age (survey_q_age). Use type = \"length\".",
           call. = FALSE)
    if (!is.numeric(multiplier) || length(multiplier) != length(info$ages) || any(!is.finite(multiplier)))
      stop("The survey catchability multiplier by age of fit must have one finite value per age class.",
           call. = FALSE)
    data <- data.frame(Age = info$ages, Value = as.numeric(multiplier))
    p <- ggplot2::ggplot(data, ggplot2::aes(x = Age, y = Value)) +
      ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
      ggplot2::geom_point(size = point_size, color = line_color)
    scale_x <- .acl_scale_x(x_breaks, n_breaks = 10, values = info$ages,
                            auto_breaks = .acl_age_breaks(info$ages, 10),
                            labels = .acl_age_axis_labels(info$ages[length(info$ages)]), check_overlap = TRUE)
    x_key <- "age"; y_key <- "survey_q_age"; title_key <- "survey_q_age"
  } else {
    q <- .acl_plot_catchability(fit)
    mid <- fit$len_mid
    x_key <- "length"; y_key <- "survey_q"; title_key <- "survey_q"
    scale_x <- .acl_scale_x(x_breaks, n_breaks = 10, values = mid)
    if (!is.matrix(q)) {
      data <- data.frame(Length = mid, Value = q)
      p <- ggplot2::ggplot(data, ggplot2::aes(x = Length, y = Value)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_point(size = point_size, color = line_color)
    } else {
      # One line for each distinct curve, named by the time steps it applies to.
      times <- .acl_plot_year(fit, name = "fit")
      curve <- attr(q, "curve")
      if (length(curve) != length(times))
        stop("Survey catchability by time step does not match the time steps of fit.", call. = FALSE)
      labels <- vapply(seq_len(ncol(q)), function(i)
        .acl_time_ranges(times[curve == i], fit$growth_step), character(1))
      data <- data.frame(Length = rep(mid, ncol(q)), Value = as.vector(q),
                         Curve = factor(rep(labels, each = nrow(q)), levels = labels))
      palette <- stats::setNames(.acl_palette(acl_theme("palette") %||% "npg", ncol(q)), labels)
      p <- ggplot2::ggplot(data, ggplot2::aes(x = Length, y = Value, color = Curve)) +
        ggplot2::geom_line(linewidth = line_size, linetype = line_type) +
        ggplot2::geom_point(size = point_size) +
        ggplot2::scale_color_manual(name = "Time steps", values = palette)
      subtitle <- "By length and time step: one line for each distinct curve"
    }
  }
  p <- p +
    ggplot2::labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", x_key),
                  y = if (!is.null(ylab)) ylab else .acl_lab("y", y_key),
                  title = if (!is.null(title)) title else .acl_title(title_key),
                  subtitle = subtitle) +
    scale_x +
    .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size, strip_text_size,
                    legend_text_size, base_theme = base_theme, title_hjust = title_hjust)
  if (!is.null(subtitle)) p <- p + ggplot2::theme(legend.position = "bottom")
  if (return_data) list(plot = p, data = data) else p
}
