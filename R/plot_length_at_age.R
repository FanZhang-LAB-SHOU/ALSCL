utils::globalVariables(c("age", "mean_length", "year", "AgeClass", "Series", "Period"))

# Shared parts of the growth plots: plot_length_at_age(), plot_VB() and
# plot_compare_growth() read mean length at age and draw observed mean length
# at age through the functions below.

# Mean length at age of one fit on one basis: the values by age class and
# time step for the selected time steps, and their mean over those time steps
# (an unweighted mean, as in compare_models()).
.acl_growth_series <- function(fit, basis, years = NULL, name = "fit") {
  info <- .acl_derived_fit(fit, name)
  keep <- .acl_year_positions(years, info$years)
  moments <- .acl_length_at_age(fit, basis, info)
  by_time <- moments$mean[, keep, drop = FALSE]
  list(model = info$model, ages = info$ages, years = info$years[keep], all_years = info$years,
       by_time = by_time, sd = moments$sd[, keep, drop = FALSE], mean = rowMeans(by_time))
}

# Observed mean length at age from age readings in a standard form: age,
# mean_length, lower and upper (NA where no spread was supplied) and year (NA
# without a time step). NULL stays NULL.
.acl_observed_length <- function(observed, arg = "observed") {
  if (is.null(observed)) return(NULL)
  if (!is.data.frame(observed) || !all(c("age", "mean_length") %in% names(observed)) || !nrow(observed))
    stop(arg, " must be a data frame with the numeric columns age and mean_length: the observed mean ",
         "length at age from age readings, one row per age class (and time step).", call. = FALSE)
  column <- function(nm, required = FALSE) {
    x <- observed[[nm]]
    if (is.null(x)) return(NULL)
    if (!is.numeric(x) || (required && any(!is.finite(x))))
      stop("Column ", nm, " of ", arg, " must be numeric", if (required) " and finite" else "", ".", call. = FALSE)
    as.numeric(x)
  }
  out <- data.frame(age = column("age", TRUE), mean_length = column("mean_length", TRUE),
                    lower = NA_real_, upper = NA_real_, year = NA_real_)
  spread <- "none"
  has_bounds <- c("lower", "upper") %in% names(observed)
  if (any(has_bounds)) {
    if (!all(has_bounds))
      stop(arg, " must have both lower and upper, or neither.", call. = FALSE)
    out$lower <- column("lower"); out$upper <- column("upper")
    if (any(out$lower > out$mean_length | out$upper < out$mean_length, na.rm = TRUE))
      stop("In ", arg, ", lower must not exceed mean_length and upper must not be below it.", call. = FALSE)
    spread <- "interval"
  } else {
    sd_name <- intersect(c("sd_length", "sd"), names(observed))
    if (length(sd_name)) {
      sd <- column(sd_name[1L])
      if (any(sd < 0, na.rm = TRUE))
        stop("Column ", sd_name[1L], " of ", arg, " must be nonnegative.", call. = FALSE)
      out$lower <- out$mean_length - sd; out$upper <- out$mean_length + sd
      spread <- "sd"
    }
  }
  if ("year" %in% names(observed)) out$year <- column("year", TRUE)
  attr(out, "spread") <- spread
  attr(out, "by_time") <- "year" %in% names(observed)
  out
}

# Observed rows of the selected time steps. Observations without a time step
# are always kept.
.acl_observed_years <- function(obs, years) {
  if (is.null(obs) || is.null(years) || !isTRUE(attr(obs, "by_time"))) return(obs)
  keep <- vapply(obs$year, function(y) any(abs(years - y) <= 1e-8 * max(1, abs(y))), logical(1))
  out <- obs[keep, , drop = FALSE]
  attr(out, "spread") <- attr(obs, "spread"); attr(out, "by_time") <- TRUE
  out
}

# Point layers for observed mean length at age: bars for the supplied spread
# below the points. `mapping` positions the points; `label` names them in a
# colour legend, or is NULL for a fixed colour without a legend entry.
.acl_observed_layers <- function(obs, mapping, color, point_size, label = NULL, bar_width = 0) {
  bars <- obs[is.finite(obs$lower) & is.finite(obs$upper), , drop = FALSE]
  bar_mapping <- utils::modifyList(mapping, ggplot2::aes(ymin = lower, ymax = upper))
  bar_mapping$y <- NULL
  out <- list()
  if (is.null(label)) {
    if (nrow(bars)) out <- list(ggplot2::geom_errorbar(data = bars, mapping = bar_mapping, color = color,
      width = bar_width, inherit.aes = FALSE))
    return(c(out, list(ggplot2::geom_point(data = obs, mapping = mapping, color = color,
      size = point_size, inherit.aes = FALSE))))
  }
  obs$Series <- label
  bars$Series <- rep(label, nrow(bars))
  point_mapping <- utils::modifyList(mapping, ggplot2::aes(color = Series))
  if (nrow(bars)) out <- list(ggplot2::geom_errorbar(data = bars,
    mapping = utils::modifyList(bar_mapping, ggplot2::aes(color = Series)),
    width = bar_width, inherit.aes = FALSE, show.legend = FALSE))
  c(out, list(ggplot2::geom_point(data = obs, mapping = point_mapping, size = point_size,
                                  inherit.aes = FALSE)))
}

# One colour legend for series drawn in separate layers, some as lines and
# some as points. `linetypes` is "blank" and `shapes` is NA where a series
# has no line or no points.
.acl_series_legend <- function(labels, colors, linetypes, shapes) {
  list(ggplot2::scale_color_manual(name = NULL, values = stats::setNames(colors, labels), breaks = labels),
       ggplot2::guides(color = ggplot2::guide_legend(
         override.aes = list(linetype = linetypes, shape = shapes))))
}

# Theme for a plot with a legend of series and a caption of full sentences:
# the legend below the panel and the caption left-aligned. Add it after the
# base theme, which is a complete theme and would replace it.
.acl_series_theme <- function(legend = TRUE) {
  ggplot2::theme(legend.position = if (legend) "bottom" else "none",
                 plot.caption = ggplot2::element_text(hjust = 0))
}

# Caption sentences, each wrapped to the width of a figure.
.acl_caption <- function(sentences, width = 100) {
  if (!length(sentences)) return(NULL)
  paste(vapply(sentences, function(x) paste(strwrap(x, width), collapse = "\n"), character(1)),
        collapse = "\n")
}

# Subtitle of a growth plot: the basis and the time steps of the mean.
.acl_growth_subtitle <- function(basis, years = NULL, all_years = years, step = NULL, by_time = FALSE) {
  where <- if (basis == "survey") "In the survey catch" else "In the population"
  if (by_time || is.null(years)) return(where)
  if (length(years) == 1L)
    return(paste0(where, ", time step ", .acl_time_labels(years, step, prefix = FALSE)))
  contiguous <- identical(match(years, all_years), seq.int(match(years[1L], all_years), length.out = length(years)))
  if (!contiguous) return(paste0(where, ", mean of ", length(years), " selected time steps"))
  ends <- .acl_time_labels(range(years), step, prefix = FALSE)
  paste0(where, ", mean of the time steps ", ends[1L], "-", ends[2L])
}

# Caption for the meaning of the bars of observed mean length at age.
.acl_observed_caption <- function(obs) {
  if (is.null(obs) || !nrow(obs)) return(NULL)
  switch(attr(obs, "spread"), sd = "Bars: one standard deviation on each side of the observed mean.",
         interval = "Bars: the supplied interval of the observed mean.", NULL)
}

#' Plot mean length at age by time step
#'
#' Plots the mean length of each age class of a fitted ACL or ALSCL model
#' against the time step, from [length_at_age()], and optionally the observed
#' mean length at age from age readings. Use it to see how the lengths at age
#' of the model change over time and to compare them with age readings.
#' [plot_VB()] shows the mean of the same values over the time steps against
#' age.
#'
#' @param fit A fitted ACL or ALSCL result, including a saved assessment read
#'   with [read_assessment()].
#' @param observed NULL or a data frame of observed mean length at age from
#'   age readings, drawn as points. Required columns: `age` (an age class of
#'   the fit, as in `fit$age`), `mean_length` and `year` (the time step, on
#'   the scale of `fit$year`). Optional columns: `sd_length` (or `sd`), drawn
#'   as bars of one standard deviation on each side of the mean, or `lower`
#'   and `upper`, drawn as the bars of an interval. The output of
#'   [length_at_age()] has these columns.
#' @param basis `"population"` (default): mean length at age in the
#'   population. `"survey"`: mean length at age in the survey catch, that is,
#'   with numbers at length multiplied by the survey catchability at length
#'   used in the fit. Use `"survey"` to compare with age readings of fish
#'   caught in the survey.
#' @param years NULL (all time steps) or the time steps to draw, as values of
#'   `fit$year`.
#' @param ages NULL (all age classes) or the age classes to draw, as values of
#'   `fit$age`.
#' @param facet_by `"age"` (default): one panel per age class. `"none"`: one
#'   panel with one line per age class, coloured by age class.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting.
#' @param line_color Character or NULL. Line colour with `facet_by = "age"`;
#'   NULL inherits the global line_color setting. With `facet_by = "none"` the
#'   lines take the colours of the global palette.
#' @param line_type Character. Line type. Default is "solid".
#' @param point_size Numeric or NULL. Size of the observed points; NULL
#'   inherits the global point_size setting.
#' @param observed_color Character or NULL. Colour of the observed points with
#'   `facet_by = "age"`; NULL inherits the global observed_color setting. With
#'   `facet_by = "none"` the points take the colour of their age class.
#' @param observed_name Character. Name of the observed points in the legend
#'   and the caption. Default is "Age readings".
#' @param facet_ncol Numeric. Columns in facet wrap. Default is NULL.
#' @param facet_scales Character. Scales for facet wrap. Default is "free".
#' @param return_data Logical. Whether to return the plotted data with the
#'   plot. Default is FALSE.
#' @inheritParams plot_SSB
#' @return A ggplot object, or a list with `plot` and `data` when
#'   `return_data = TRUE`. `data` has one row per age class and time step:
#'   Year, Age, AgeClass (the panel label), mean_length and sd_length.
#' @details The values are those of [length_at_age()]. For an ALSCL fit they
#'   come from the estimated numbers by length bin, age class and time step,
#'   so they change over time with growth, recruitment and mortality at
#'   length. For an ACL fit they come from the age-length key, which is the
#'   same in every time step: the lines are then horizontal on the population
#'   basis, and on the survey basis they change only when the supplied survey
#'   catchability changes over time. Each length bin is represented by its
#'   midpoint, so the mean of an age class with a large share of its fish in
#'   the first or the last length bin is drawn toward the midpoint of that bin.
#'
#'   The oldest age class is a plus group and is marked with a plus sign.
#'   The title uses the theme key `length_at_age_time`, and the axis labels
#'   use `xlab$year` and `ylab$growth`. The package holds no unit for length;
#'   give it in `ylab`, for example `ylab = "Length (cm)"`.
#' @seealso [length_at_age()], [plot_VB()], [plot_compare_growth()].
#' @examples
#' \donttest{
#' # Fit ALSCL to the last ten years of the example data. The shorter series
#' # and one fishing mortality rate (F) shared by all lengths in each year
#' # keep the fit short.
#' x <- YTF_example
#' tables <- c("data.CatL", "data.wgt", "data.mat")
#' x[tables] <- lapply(x[tables], function(tab) tab[, c(1, 12:21)])
#' fit <- run_alscl(x, F_structure = "year", silent = TRUE)
#'
#' # Mean length of four age classes in the survey catch
#' plot_length_at_age(fit, basis = "survey", ages = c(2, 4, 6, 8))
#'
#' # With observed mean length at age by time step. These values are made up
#' # for the example; use the means of your age readings.
#' readings <- subset(length_at_age(fit, basis = "survey"), age %in% c(2, 4))
#' readings$mean_length <- readings$mean_length + rep(c(-1, 1), length.out = nrow(readings))
#' plot_length_at_age(fit, observed = readings, basis = "survey", ages = c(2, 4),
#'                    ylab = "Length (cm)")
#' }
#' @export
plot_length_at_age <- function(fit, observed = NULL, basis = c("population", "survey"),
                               years = NULL, ages = NULL, facet_by = c("age", "none"),
                               line_size = NULL, line_color = NULL, line_type = "solid",
                               point_size = NULL, observed_color = NULL,
                               observed_name = "Age readings",
                               facet_ncol = NULL, facet_scales = "free", return_data = FALSE,
                               title = NULL, xlab = NULL, ylab = NULL,
                               font_family = NULL, title_size = NULL, axis_title_size = NULL,
                               axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL,
                               x_breaks = NULL, base_theme = NULL, title_hjust = NULL) {
  basis <- match.arg(basis)
  facet_by <- match.arg(facet_by)
  .acl_check_flag(return_data, "return_data")
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(point_size)) point_size <- acl_theme("point_size")
  if (is.null(observed_color)) observed_color <- acl_theme("observed_color")
  .acl_check_series_name(observed_name, "observed_name")

  series <- .acl_growth_series(fit, basis, years)
  shown <- .acl_age_positions(ages, series$ages)
  labels <- .acl_age_labels(fit, length(series$ages))
  long <- data.frame(
    Year = rep(series$years, each = length(shown)),
    Age = rep(series$ages[shown], times = length(series$years)),
    AgeClass = factor(rep(labels[shown], times = length(series$years)), levels = labels[shown]),
    mean_length = as.numeric(series$by_time[shown, , drop = FALSE]),
    sd_length = as.numeric(series$sd[shown, , drop = FALSE]))

  obs <- .acl_observed_length(observed)
  if (!is.null(obs)) {
    if (!isTRUE(attr(obs, "by_time")))
      stop("observed must have the column year (the time step of each mean) for plot_length_at_age(). ",
           "Use plot_VB() to compare with observed mean length at age that is not by time step.",
           call. = FALSE)
    if (identical(observed_name, "Model")) stop("observed_name must differ from \"Model\".", call. = FALSE)
    class_of <- vapply(obs$age, function(a) {
      hit <- which(abs(series$ages - a) <= 1e-8 * max(1, abs(a)))
      if (length(hit)) hit[1L] else NA_integer_
    }, integer(1))
    if (anyNA(class_of))
      stop("observed contains ages that are not age classes of fit (fit$age): ",
           paste(format(sort(unique(obs$age[is.na(class_of)]))), collapse = ", "),
           ". The oldest age class of fit is a plus group; combine the older ages before plotting.",
           call. = FALSE)
    spread <- attr(obs, "spread")
    obs$AgeClass <- factor(labels[class_of], levels = labels[shown])
    obs <- .acl_observed_years(obs, years)
    obs <- obs[!is.na(obs$AgeClass), , drop = FALSE]
    names(obs)[names(obs) == "year"] <- "Year"
    attr(obs, "spread") <- spread
  }
  has_observed <- !is.null(obs) && nrow(obs) > 0L
  bars_text <- if (has_observed) .acl_observed_caption(obs) else NULL

  if (facet_by == "age") {
    p <- ggplot2::ggplot(long, ggplot2::aes(x = Year, y = mean_length))
    if (has_observed) {
      long$Series <- "Model"
      p <- ggplot2::ggplot(long, ggplot2::aes(x = Year, y = mean_length)) +
        ggplot2::geom_line(ggplot2::aes(color = Series), linewidth = line_size, linetype = line_type) +
        .acl_observed_layers(obs, ggplot2::aes(x = Year, y = mean_length), observed_color,
                             point_size, label = observed_name) +
        .acl_series_legend(c("Model", observed_name), c(line_color, observed_color),
                           c(line_type, "blank"), c(NA, 16))
    } else {
      p <- p + ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
    }
    p <- p + ggplot2::facet_wrap(~AgeClass, ncol = facet_ncol, scales = facet_scales)
    n_breaks <- .acl_facet_n_breaks(length(shown), facet_ncol, 5)
    caption <- .acl_caption(bars_text)
  } else {
    palette <- stats::setNames(.acl_palette(acl_theme("palette") %||% "npg", length(shown)),
                               levels(long$AgeClass))
    p <- ggplot2::ggplot(long, ggplot2::aes(x = Year, y = mean_length, color = AgeClass)) +
      ggplot2::geom_line(linewidth = line_size, linetype = line_type)
    if (has_observed) {
      bars <- obs[is.finite(obs$lower) & is.finite(obs$upper), , drop = FALSE]
      if (nrow(bars)) p <- p + ggplot2::geom_errorbar(data = bars,
        ggplot2::aes(x = Year, ymin = lower, ymax = upper, color = AgeClass), width = 0,
        inherit.aes = FALSE, show.legend = FALSE)
      p <- p + ggplot2::geom_point(data = obs, ggplot2::aes(x = Year, y = mean_length, color = AgeClass),
                                   size = point_size, inherit.aes = FALSE, show.legend = FALSE)
    }
    p <- p + ggplot2::scale_color_manual(name = "Age class", values = palette,
                                         labels = sub("^Age ", "", names(palette)))
    n_breaks <- 10
    caption <- if (has_observed)
      .acl_caption(paste(c(paste0("Lines: model. Points: ", observed_name, "."), bars_text), collapse = " "))
  }
  p <- p +
    ggplot2::labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", "year"),
                  y = if (!is.null(ylab)) ylab else .acl_lab("y", "growth"),
                  title = if (!is.null(title)) title else .acl_title("length_at_age_time"),
                  subtitle = .acl_growth_subtitle(basis, by_time = TRUE), caption = caption) +
    .acl_scale_x(x_breaks, n_breaks = n_breaks, values = long$Year, check_overlap = TRUE) +
    .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size, strip_text_size,
                    legend_text_size, base_theme = base_theme, title_hjust = title_hjust)
  if (has_observed) p <- p + if (facet_by == "age") .acl_series_theme() else
    ggplot2::theme(plot.caption = ggplot2::element_text(hjust = 0))
  p <- .acl_show_singletons(p, "AgeClass", point_size = point_size)
  if (return_data) list(plot = p, data = long) else p
}

# Positions of the age classes `ages` among the fitted ages. NULL selects all.
.acl_age_positions <- function(ages, fitted) {
  if (is.null(ages)) return(seq_along(fitted))
  if (!is.numeric(ages) || !length(ages) || any(!is.finite(ages)))
    stop("ages must be finite numeric age classes of fit.", call. = FALSE)
  position <- vapply(ages, function(a) {
    hit <- which(abs(fitted - a) <= 1e-8 * max(1, abs(a)))
    if (length(hit)) hit[1L] else NA_integer_
  }, integer(1))
  if (anyNA(position))
    stop("ages must be age classes of fit (fit$age); not found: ",
         paste(format(ages[is.na(position)]), collapse = ", "), ".", call. = FALSE)
  sort(unique(position))
}

# A legend name supplied by the user.
.acl_check_series_name <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x)))
    stop(arg, " must be a nonempty character string.", call. = FALSE)
  invisible(x)
}
