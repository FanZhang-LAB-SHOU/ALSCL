#' Summarize simulation bias, uncertainty coverage and fitting failures
#' @param fits Named list of fitted results or error records, such as sim_model output.
#' @param truth Named list with exactly the same replicate names as fits. Each
#'   element supplies year and a finite vector for every requested quantity.
#'   Coordinates must match the fitted periods; values are never recycled.
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
#' @details Numerical failures remain in the output but do not enter bias, RMSE
#'   or coverage. This conditional summary must be interpreted together with the
#'   reported failure rate. Missing uncertainty is not treated as a failed interval.
#'   Relative bias excludes zero truth values. F and grouped arrays are excluded
#'   because aggregation requires an explicit definition and its uncertainty.
#'   Operating-model simulations are not automatically a fitted parametric bootstrap.
#' @export
summarize_simulations <- function(fits, truth, quantities = c("SSB", "Rec"), conf_level = .95) {
  z <- .acl_conf_level(conf_level)
  named <- function(x) is.list(x) && !is.data.frame(x) && length(x) &&
    !is.null(names(x)) && !anyNA(names(x)) && all(nzchar(names(x))) && !anyDuplicated(names(x))
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
    if (!is.list(target) || !is.numeric(year) || !length(year) ||
        any(!is.finite(year)) || any(diff(year) <= 0))
      stop("Truth year must contain finite increasing coordinates for ", id, call. = FALSE)
    for (q in quantities) if (!is.numeric(target[[q]]) || length(target[[q]]) != length(year) ||
                             any(!is.finite(target[[q]])))
      stop("Truth quantity ", q, " must match the time coordinates for ", id, call. = FALSE)
    if (!is.list(fit)) stop("Every fit must be a fitted result or error list.", call. = FALSE)
    status <- .acl_fit_status(fit, error = fit$error)
    elapsed <- fit$elapsed
    if (!is.numeric(elapsed) || length(elapsed) != 1L || !is.finite(elapsed) || elapsed < 0) elapsed <- NA_real_
    statuses[[i]] <- cbind(data.frame(replicate = id, elapsed = elapsed,
      error = fit$error %||% "", stringsAsFactors = FALSE), status)
    if (!is.null(fit$report) && is.null(fit$year))
      stop("Fit time coordinates are unavailable for ", id, call. = FALSE)
    if (!is.null(fit$year) && (!is.numeric(fit$year) || length(fit$year) != length(year) ||
        any(!is.finite(fit$year)) || any(abs(fit$year - year) > 1e-8)))
      stop("Fit and truth time coordinates differ for ", id, call. = FALSE)
    rows[[i]] <- do.call(rbind, lapply(quantities, function(q) {
      value <- fit$report[[q]]
      if (is.null(value)) value <- rep(NA_real_, length(year))
      else if (!is.numeric(value) || length(value) != length(year))
        stop("Fit quantity ", q, " does not match truth coordinates for ", id, call. = FALSE)
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
      data.frame(replicate = id, quantity = q, year = year, truth = target[[q]],
        estimate = as.numeric(value), std_error = se, conf_low = low, conf_high = high,
        numerical_ok = isTRUE(status$numerical_ok), valid_pair = valid, covered = covered,
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
  rownames(replicates) <- rownames(estimates) <- rownames(summary) <- NULL
  list(summary = summary, replicates = replicates, estimates = estimates,
       conf_level = conf_level)
}
