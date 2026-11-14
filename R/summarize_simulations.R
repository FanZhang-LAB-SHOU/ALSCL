#' Summarize simulation bias, uncertainty coverage and fitting failures
#' @param fits Named list of fitted results or error records, such as sim_model output.
#' @param truth Named list with exactly the same replicate names as fits. Each
#'   element supplies year and a finite vector for every requested quantity.
#'   Coordinates must match the fitted periods; values are never recycled.
#'   Time coordinates and quantity values must be numeric vectors, not matrices
#'   or arrays; grouped quantities must be aggregated explicitly before calling.
#' @param quantities Time-series quantities to assess, from SSB, Rec, B, N, CN, CB.
#' @param conf_level Nominal confidence level of normal intervals based on
#'   reported standard errors, strictly between zero and one. The returned
#'   coverage is the observed fraction of usable intervals containing truth.
#' @return A list with summary (pooled over replicates and time by quantity),
#'   replicates (numerical status, elapsed seconds and errors), and estimates
#'   (every replicate/time/truth/estimate pair, including failed or invalid fits).
#'   Summary denominators distinguish attempted replicates, valid fits, valid
#'   estimate pairs and usable intervals. Bias and RMSE use valid estimate pairs;
#'   coverage uses only valid fits with available finite standard errors.
#'   summary_converged repeats the statistics of summary for all converged
#'   fits, whether or not they pass the numerical screen. failures counts the
#'   replicates that fail the screen by reason: n_replicates is the number of
#'   replicates with that reason and n_sole the number for which it is the only
#'   reason. In replicates, converged marks converged fits and failure_reasons
#'   lists the reasons of each replicate. In estimates, converged and
#'   covered_converged give the same information for each estimate pair.
#' @details Numerical failures remain in the output but do not enter bias, RMSE
#'   or coverage. This conditional summary must be interpreted together with the
#'   reported failure rate. Missing uncertainty is not treated as a failed interval.
#'   A converged fit returned no error and has a finite objective and a maximum
#'   absolute gradient below 1e-3, the gradient threshold of the numerical
#'   screen. Such a fit can still fail the screen, for example because an
#'   estimated correlation or SD lies at a natural-scale boundary or the
#'   Hessian is not positive definite. Compare summary with summary_converged
#'   to see whether the fits excluded by the screen change bias, RMSE or
#'   coverage, and read failures before treating the failure rate as a
#'   convergence rate.
#'   Relative bias excludes zero truth values. F and grouped arrays are excluded
#'   because aggregation requires an explicit definition and its uncertainty.
#'   Operating-model simulations are not automatically a fitted parametric bootstrap.
#' @examples
#' \donttest{
#' # Simulate two replicates of a ten-year survey and fit ACL to each
#' pa <- initialize_params(species = "flatfish", nyear = 12, burn_in = 2)
#' folder <- tempfile("simulation")
#' bio <- sim_cal(pa)
#' sims <- lapply(1:2, function(i)
#'   sim_data(bio, pa, iter_range = i, output_dir = folder))
#' cfg <- YTF_example$fit_config$acl
#' fits <- sim_acl(iter_range = 1:2, sim_data_path = folder, output_dir = folder,
#'   parameters = cfg$parameters, map = cfg$map)
#'
#' # Simulated spawning stock biomass (SSB) and recruitment of each replicate,
#' # named like the fits
#' truth <- lapply(sims, function(sm)
#'   list(year = sm$years, SSB = as.numeric(sm$SSB), Rec = as.numeric(sm$Rec)))
#' names(truth) <- names(fits)
#' performance <- summarize_simulations(fits, truth, quantities = c("SSB", "Rec"))
#' performance$summary
#' unlink(folder, recursive = TRUE)
#' }
#' @export
summarize_simulations <- function(fits, truth, quantities = c("SSB", "Rec"), conf_level = .95) {
  z <- .acl_conf_level(conf_level)
  named <- function(x) is.list(x) && !is.data.frame(x) && length(x) &&
    !is.null(names(x)) && !anyNA(names(x)) && all(nzchar(names(x))) && !anyDuplicated(names(x))
  numeric_vector <- function(x) is.numeric(x) && !is.complex(x) && is.null(dim(x))
  if (!named(fits) || !named(truth) || !setequal(names(fits), names(truth)))
    stop("fits and truth must be nonempty lists with identical unique replicate names.", call. = FALSE)
  if (!is.character(quantities) || !length(quantities) || anyNA(quantities) ||
      anyDuplicated(quantities) || any(!quantities %in% c("SSB", "Rec", "B", "N", "CN", "CB")))
    stop("quantities must contain distinct time-series names: SSB, Rec, B, N, CN or CB.", call. = FALSE)
  truth <- truth[names(fits)]
  statuses <- rows <- vector("list", length(fits))
  for (i in seq_along(fits)) {
    fit <- fits[[i]]; target <- truth[[i]]; id <- names(fits)[i]
    if (!is.list(target)) stop("Each truth entry must be a list.", call. = FALSE)
    year <- target$year
    if (!numeric_vector(year) || !length(year) ||
        any(!is.finite(year)) || any(diff(year) <= 0))
      stop("Truth year must be a finite increasing numeric vector for ", id, call. = FALSE)
    for (q in quantities) if (!numeric_vector(target[[q]]) || length(target[[q]]) != length(year) ||
                             any(!is.finite(target[[q]])))
      stop("Truth quantity ", q, " must match the time coordinates as a finite numeric vector for ",
        id, call. = FALSE)
    if (!is.list(fit)) stop("Every fit must be a fitted result or error list.", call. = FALSE)
    status <- .acl_fit_status(fit, error = fit$error)
    elapsed <- fit$elapsed
    if (!is.numeric(elapsed) || length(elapsed) != 1L || !is.finite(elapsed) || elapsed < 0) elapsed <- NA_real_
    objective <- fit$opt$objective
    stationary <- is.finite(status$max_abs_gradient) && status$max_abs_gradient < 1e-3
    converged <- is.null(fit$error) && stationary &&
      is.numeric(objective) && length(objective) == 1L && is.finite(objective)
    reasons <- if (isTRUE(status$numerical_ok)) character() else if (!is.null(fit$error)) "fit error" else c(
      if (!stationary) "large or nonfinite gradient",
      if (!isTRUE(status$pdHess)) "Hessian unavailable or not positive definite",
      if (isTRUE(status$bound_hit)) "optimizer-scale boundary",
      if (isTRUE(status$natural_boundary)) "natural-scale boundary",
      if (grepl("limit in practice", status$issues, fixed = TRUE)) "parameter at its limit in practice")
    if (!isTRUE(status$numerical_ok) && !length(reasons)) reasons <- "other"
    statuses[[i]] <- cbind(data.frame(replicate = id, elapsed = elapsed,
      error = fit$error %||% "", stringsAsFactors = FALSE), status,
      data.frame(converged = converged, failure_reasons = paste(reasons, collapse = "; "),
                 stringsAsFactors = FALSE))
    if (!is.null(fit$report) && is.null(fit$year))
      stop("Fit time coordinates are unavailable for ", id, call. = FALSE)
    if (!is.null(fit$year) && (!numeric_vector(fit$year) || length(fit$year) != length(year) ||
        any(!is.finite(fit$year)) || any(abs(fit$year - year) > 1e-8)))
      stop("Fit and truth time coordinates differ for ", id,
        "; both must be numeric vectors.", call. = FALSE)
    rows[[i]] <- do.call(rbind, lapply(quantities, function(q) {
      value <- fit$report[[q]]
      if (is.null(value)) value <- rep(NA_real_, length(year))
      else if (!numeric_vector(value) || length(value) != length(year))
        stop("Fit quantity ", q, " does not match truth coordinates as a numeric vector for ",
          id, call. = FALSE)
      se <- rep(NA_real_, length(year)); tab <- fit$est_std
      if (length(dim(tab)) == 2L && !is.null(rownames(tab)) && "Std. Error" %in% colnames(tab)) {
        candidate <- tab[which(rownames(tab) == q), "Std. Error"]
        if (is.numeric(candidate) && length(candidate) == length(year))
          se[is.finite(candidate) & candidate >= 0] <- candidate[is.finite(candidate) & candidate >= 0]
      }
      low <- value - z * se; high <- value + z * se
      valid <- isTRUE(status$numerical_ok) & is.finite(value)
      interval <- valid & is.finite(low) & is.finite(high)
      covered <- rep(NA, length(year))
      covered[interval] <- target[[q]][interval] >= low[interval] & target[[q]][interval] <= high[interval]
      interval_converged <- converged & is.finite(value) & is.finite(low) & is.finite(high)
      covered_converged <- rep(NA, length(year))
      covered_converged[interval_converged] <- target[[q]][interval_converged] >= low[interval_converged] &
        target[[q]][interval_converged] <= high[interval_converged]
      data.frame(replicate = id, quantity = q, year = year, truth = target[[q]],
        estimate = as.numeric(value), std_error = se, conf_low = low, conf_high = high,
        numerical_ok = isTRUE(status$numerical_ok), valid_pair = valid, covered = covered,
        converged = converged, covered_converged = covered_converged,
        stringsAsFactors = FALSE)
    }))
  }
  replicates <- do.call(rbind, statuses)
  estimates <- do.call(rbind, rows)
  summary <- do.call(rbind, lapply(quantities, function(q) {
    d <- estimates[estimates$quantity == q, , drop = FALSE]
    error <- d$estimate[d$valid_pair] - d$truth[d$valid_pair]
    relative <- d$valid_pair & d$truth != 0
    mean_or_na <- function(value) if (length(value)) mean(value) else NA_real_
    data.frame(quantity = q, n_replicates = length(fits), n_valid_fits = sum(replicates$numerical_ok),
      failure_rate = mean(!replicates$numerical_ok), n_points = nrow(d),
      n_valid_pairs = length(error), n_relative_pairs = sum(relative),
      n_intervals = sum(!is.na(d$covered)), bias = mean_or_na(error),
      relative_bias = mean_or_na((d$estimate[relative] - d$truth[relative]) / d$truth[relative]),
      rmse = sqrt(mean_or_na(error^2)), coverage = mean_or_na(d$covered[!is.na(d$covered)]),
      mean_elapsed = mean_or_na(replicates$elapsed[is.finite(replicates$elapsed)]))
  }))
  mean_or_na <- function(value) if (length(value)) mean(value) else NA_real_
  summary_converged <- do.call(rbind, lapply(quantities, function(q) {
    d <- estimates[estimates$quantity == q, , drop = FALSE]
    pair <- d$converged & is.finite(d$estimate)
    error <- d$estimate[pair] - d$truth[pair]
    relative <- pair & d$truth != 0
    data.frame(quantity = q, n_replicates = length(fits),
      n_converged_fits = sum(replicates$converged), n_valid_pairs = length(error),
      n_relative_pairs = sum(relative), n_intervals = sum(!is.na(d$covered_converged)),
      bias = mean_or_na(error),
      relative_bias = mean_or_na((d$estimate[relative] - d$truth[relative]) / d$truth[relative]),
      rmse = sqrt(mean_or_na(error^2)),
      coverage = mean_or_na(d$covered_converged[!is.na(d$covered_converged)]))
  }))
  reason_levels <- c("fit error", "large or nonfinite gradient",
    "Hessian unavailable or not positive definite", "optimizer-scale boundary",
    "natural-scale boundary", "parameter at its limit in practice", "other")
  reason_list <- strsplit(replicates$failure_reasons, "; ", fixed = TRUE)
  failures <- data.frame(reason = reason_levels,
    n_replicates = vapply(reason_levels, function(reason)
      sum(vapply(reason_list, function(x) reason %in% x, logical(1))), integer(1)),
    n_sole = vapply(reason_levels, function(reason)
      sum(vapply(reason_list, function(x) identical(x, reason), logical(1))), integer(1)),
    stringsAsFactors = FALSE)
  rownames(replicates) <- rownames(estimates) <- rownames(summary) <- NULL
  rownames(summary_converged) <- rownames(failures) <- NULL
  list(summary = summary, replicates = replicates, estimates = estimates,
       conf_level = conf_level, summary_converged = summary_converged, failures = failures)
}
