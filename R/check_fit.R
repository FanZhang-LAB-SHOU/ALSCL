#' Extract observation residuals from an assessment fit
#'
#' @param object A fitted ACL or ALSCL result, including a portable saved result.
#' @param type `"log"` returns observed minus fitted log index; `"standardized"`
#'   divides this difference by the fitted observation standard deviation.
#' @param ... Reserved for future extensions; unused arguments are rejected.
#' @return A data frame with year, length, length_label, observed, fitted_log,
#'   sd_log, included and residual. Zero and missing observations are excluded
#'   from the likelihood and have NA residuals. Rows are ordered by time, then
#'   length. The original observations are retained, including zeros.
#' @details These are conditional residuals evaluated at the fitted latent
#'   effects. Standardizing does not make them independent or provide calibrated
#'   model tests. Observation SD is on the log scale. A live TMB object is not
#'   required when observations and reports were retained in the saved result.
#'
#'   Standardized conditional residuals do not have unit standard deviation
#'   when the model is correct. The fitted random effects absorb part of the
#'   observation error, so the residuals are smaller than the observation
#'   errors. In simulation tests with the package examples, where data were
#'   simulated from a fitted model and the same model was refitted, their
#'   standard deviation was 0.91 to 0.96. A standard deviation close to one
#'   is therefore not evidence of a good fit, and a value below one is not
#'   evidence of overestimated observation error.
#' @examples
#' \dontrun{
#' fit <- run_acl(YTF_example)
#' residuals(fit, type = "standardized")
#' }
#' @export
residuals.alscl_fit <- function(object, type = c("log", "standardized"), ...) {
  if (length(list(...))) stop("Unused residual arguments.", call. = FALSE)
  type <- match.arg(type)
  if (!is.list(object)) stop("object must be an assessment fit.", call. = FALSE)
  obs_log <- .acl_observed_log(object)
  expected <- object$report$Elog_index
  if (!is.numeric(expected) || !is.matrix(expected) ||
      !identical(dim(expected), dim(obs_log)))
    stop("Fitted and observation matrix dimensions differ.", call. = FALSE)
  included <- is.finite(obs_log)
  if (any(!is.finite(expected[included])))
    stop("Fitted log index must be finite at observed cells.", call. = FALSE)
  coordinates <- .acl_check_coordinates(object, nrow(obs_log), ncol(obs_log))
  sigma <- object$report$std_index
  if (is.null(sigma)) sigma <- object$report$sigma_index
  valid_sigma <- is.numeric(sigma) && length(sigma) == 1L &&
    is.finite(sigma) && sigma > 0
  if (type == "standardized" && !valid_sigma)
    stop("A finite positive fitted observation SD is required for standardized residuals.", call. = FALSE)
  if (!valid_sigma) sigma <- NA_real_
  values <- obs_log - expected
  values[!included] <- NA_real_
  if (type == "standardized") values <- values / sigma
  observed <- object$observations
  if (is.null(observed)) observed <- exp(obs_log)
  data.frame(year = rep(coordinates$year, each = nrow(obs_log)),
    length = rep(coordinates$length, times = ncol(obs_log)),
    length_label = rep(coordinates$labels, times = ncol(obs_log)),
    observed = as.vector(observed), fitted_log = as.vector(expected),
    sd_log = sigma, included = as.vector(included), residual = as.vector(values),
    stringsAsFactors = FALSE)
}

.acl_check_coordinates <- function(fit, nlength, ntime) {
  years <- fit$year
  lens <- fit$len_mid
  valid <- function(x, n) is.numeric(x) && length(x) == n &&
    all(is.finite(x)) && !anyDuplicated(x) && all(diff(x) > 0)
  if (!valid(years, ntime)) stop("Fit years must be finite, increasing and match its matrices.", call. = FALSE)
  if (!valid(lens, nlength)) stop("Fit length coordinates must be finite, increasing and match its matrices.", call. = FALSE)
  labels <- fit$len_label
  if (is.null(labels)) labels <- as.character(lens)
  if (length(labels) != nlength || anyNA(labels) || anyDuplicated(labels))
    stop("Fit length labels must be unique and match its matrices.", call. = FALSE)
  list(year = years, length = lens, labels = as.character(labels))
}

.acl_check_time_step <- function(fit) {
  step <- fit$growth_step
  if (is.null(step)) step <- fit$recipe$args$growth_step
  if (is.null(step) && length(fit$year) > 1L) step <- min(diff(fit$year))
  .acl_scalar(step, "fit growth_step", 0, TRUE)
  positions <- (fit$year - fit$year[1L]) / step
  if (any(abs(positions - round(positions)) > 1e-7))
    stop("Fit years must fall on its model time-step grid.", call. = FALSE)
  step
}

#' Check conditional observation residual patterns
#'
#' @param fit A fitted ACL or ALSCL result.
#' @param max_lag Positive integer. Maximum lag in model time steps.
#' @return A list containing standardized `residuals`, `lag_correlations`,
#'   pooled `qq_data`, `plots` (heatmap, lag, qq), `time_step` and interpretation
#'   notes. Each length/lag pair reports the number of available observed pairs,
#'   correlation and status. Fewer than three pairs or constant paired values
#'   yield NA, not an artificial zero correlation.
#' @details Missing periods are never compressed: lag one means one model step,
#'   including for quarterly data. Correlations use observations separated by
#'   the requested actual time lag. These descriptive checks use fitted latent
#'   effects and are not independent residual tests, simulation envelopes or
#'   evidence of model adequacy. All plots inherit the package's grid-free theme.
#'
#'   The quantile-quantile (QQ) plot shows the pooled conditional log
#'   residuals divided by the fitted observation standard deviation (SD)
#'   against standard normal quantiles, with the line of equality as the
#'   reference. This reference is not the distribution of the residuals under
#'   a correct model: the fitted random effects absorb part of the observation
#'   error, so the points of a correctly specified model have a slope below
#'   one (0.91 to 0.96 in simulation tests with the package examples) and lie
#'   inside the line at both tails. Read curvature and asymmetry of the
#'   points, not their distance from the line, as signs of skewness or heavy
#'   tails. No simulation envelope is drawn.
#' @examples
#' \dontrun{
#' fit <- run_alscl(YTF_example)
#' checks <- check_fit(fit, max_lag = 4)
#' checks$lag_correlations
#' checks$plots$heatmap
#' }
#' @export
check_fit <- function(fit, max_lag = 5) {
  max_lag <- .acl_positive_integer(max_lag, "max_lag")
  residual <- residuals.alscl_fit(fit, type = "standardized")
  step <- .acl_check_time_step(fit)
  coordinates <- .acl_check_coordinates(fit, length(fit$len_mid), length(fit$year))
  positions <- round((fit$year - fit$year[1L]) / step)
  lags <- lapply(seq_along(coordinates$length), function(i) {
    values <- residual$residual[residual$length == coordinates$length[i]]
    do.call(rbind, lapply(seq_len(max_lag), function(lag) {
      target <- match(positions + lag, positions)
      usable <- !is.na(target) & is.finite(values) & is.finite(values[target])
      x <- values[usable]; y <- values[target[usable]]
      status <- if (length(x) < 3L) "insufficient_pairs" else if (
        stats::sd(x) == 0 || stats::sd(y) == 0) "constant_pairs" else "ok"
      data.frame(length = coordinates$length[i], length_label = coordinates$labels[i],
        lag = lag, elapsed_time = lag * step, n_pairs = length(x),
        correlation = if (status == "ok") stats::cor(x, y) else NA_real_, status = status)
    }))
  })
  correlations <- do.call(rbind, lags)
  values <- sort(residual$residual[is.finite(residual$residual)])
  qq <- data.frame(theoretical = stats::qnorm(stats::ppoints(length(values))), residual = values)
  heat <- residual
  heat$length_label <- factor(heat$length_label, levels = coordinates$labels)
  lag_data <- correlations
  lag_data$length_label <- factor(lag_data$length_label, levels = coordinates$labels)
  heatmap <- ggplot2::ggplot(heat, ggplot2::aes(x = year, y = length_label, fill = residual)) +
    ggplot2::geom_tile(width = step * .95) +
    ggplot2::scale_fill_gradient2(low = acl_theme("line_color"), mid = "white",
      high = acl_theme("observed_color"), midpoint = 0, na.value = "grey92") +
    ggplot2::labs(x = "Time", y = "Length group", fill = "Standardized\nlog residual",
      title = "Conditional observation residuals") + .acl_plot_theme()
  lag_plot <- ggplot2::ggplot(lag_data,
      ggplot2::aes(x = lag, y = correlation, group = length_label)) +
    ggplot2::geom_hline(yintercept = 0, color = acl_theme("hline_color")) +
    ggplot2::geom_point(na.rm = TRUE, color = acl_theme("point_color"),
                        size = acl_theme("point_size")) +
    ggplot2::facet_wrap(~length_label) + ggplot2::scale_y_continuous(limits = c(-1, 1)) +
    ggplot2::labs(x = "Lag (model time steps)", y = "Paired residual correlation",
      title = "Residual time dependence") + .acl_plot_theme()
  qq_plot <- ggplot2::ggplot(qq, ggplot2::aes(x = theoretical, y = residual)) +
    ggplot2::geom_abline(intercept = 0, slope = 1, color = acl_theme("hline_color")) +
    ggplot2::geom_point(color = acl_theme("point_color"), size = acl_theme("point_size")) +
    ggplot2::labs(x = "Standard normal quantile",
      y = "Conditional log residual / fitted SD",
      title = "Conditional residual QQ plot",
      subtitle = "Line of equality. A correctly specified model gives a slope below 1.") +
    .acl_plot_theme()
  list(residuals = residual, lag_correlations = correlations, qq_data = qq,
    plots = list(heatmap = heatmap, lag = lag_plot, qq = qq_plot), time_step = step,
    notes = c("Conditional residuals use fitted latent effects; no independence or calibrated-test claim.",
      "Lag correlations require at least three nonconstant pairs separated by the actual model-time lag.",
      "Standardized conditional residuals of a correctly specified model have a standard deviation below one, so their QQ points lie inside the line of equality at both tails."))
}

utils::globalVariables(c("year", "length_label", "lag", "correlation", "theoretical", "residual"))
