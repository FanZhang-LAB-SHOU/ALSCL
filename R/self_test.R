# Time series of a fitted report used by self_test(). F is summarized over
# ages (ACL) or length bins (ALSCL) at each time step, as in fit_scenarios().
.acl_self_test_series <- function(report, quantity, F_summary, F_name = "F") {
  if (quantity != "F") {
    value <- report[[quantity]]
    if (!is.numeric(value)) return(NULL)
    return(as.numeric(value))
  }
  value <- report[[F_name]]
  if (!is.matrix(value) || !is.numeric(value)) return(NULL)
  if (F_summary == "mean") colMeans(value) else apply(value, 2L, max)
}

# Approximate interval of a positive or signed quantity from its standard
# error, with the two forms used by the plots of the package.
.acl_self_test_interval <- function(estimate, se, z, interval) {
  low <- high <- rep(NA_real_, length(estimate))
  usable <- is.finite(estimate) & is.finite(se) & se >= 0
  if (interval == "lognormal") {
    usable <- usable & estimate > 0
    width <- z * se[usable] / estimate[usable]
    low[usable] <- estimate[usable] * exp(-width)
    high[usable] <- estimate[usable] * exp(width)
  } else {
    low[usable] <- estimate[usable] - z * se[usable]
    high[usable] <- estimate[usable] + z * se[usable]
  }
  list(low = low, high = high)
}

.acl_self_test_quantile <- function(x, p) {
  x <- x[is.finite(x)]
  if (length(x)) unname(stats::quantile(x, p, names = FALSE)) else NA_real_
}

.acl_self_test_rows <- function(d, key) {
  mean_or_na <- function(x) if (length(x)) mean(x) else NA_real_
  groups <- split(d, d[key], drop = TRUE, lex.order = TRUE)
  rows <- lapply(groups, function(g) {
    valid <- g$numerical_ok & is.finite(g$relative_error)
    re <- g$relative_error[valid]
    covered <- g$covered[g$numerical_ok & !is.na(g$covered)]
    out <- g[1L, key, drop = FALSE]
    cbind(out, data.frame(n_values = length(re),
      median_relative_error = .acl_self_test_quantile(re, .5),
      q10_relative_error = .acl_self_test_quantile(re, .1),
      q90_relative_error = .acl_self_test_quantile(re, .9),
      median_absolute_relative_error = .acl_self_test_quantile(abs(re), .5),
      n_intervals = length(covered), coverage = mean_or_na(covered)))
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Self-test a fitted model by refitting it to data simulated from the fit
#'
#' Simulate survey data sets from a fitted ACL or ALSCL model with
#' [simulate_fit()], refit the same model with the same settings to each data
#' set, and compare the estimates with the values used to simulate them. A
#' self-test shows whether the model can estimate its parameters and the
#' population from data like the observed ones when its assumptions hold.
#'
#' @param fit A fitted ACL or ALSCL result with its recipe, including a saved
#'   assessment read with [read_assessment()]. It must pass the numerical
#'   checks (`fit$diagnostics$numerical_ok`).
#' @param nsim Positive integer; number of simulated data sets. Default 20.
#' @param seed Optional nonnegative integer seed for the simulation; see
#'   [simulate_fit()]. The refits are deterministic, so a seed makes the whole
#'   self-test repeatable.
#' @param process `"conditional"` (default) or `"resample"`; see Details.
#' @param start `"original"` (default) starts each refit from the starting
#'   values of the source fit, with the same number of starts. `"estimates"`
#'   starts it from the estimates of the source fit, the values used to
#'   simulate. See Details.
#' @param nstarts NULL (default) uses the number of starts of the source fit.
#'   A positive integer sets the number of starts of every refit.
#' @param ncores Maximum number of socket workers. Each worker fits one
#'   simulated data set at a time; the starts of a refit run one after another.
#' @param quantities Time series to compare, from `"SSB"` (spawning stock
#'   biomass), `"Rec"` (recruitment), `"F"` (fishing mortality rate), `"B"`
#'   (total biomass) and `"N"` (total abundance). Default `c("SSB", "Rec", "F")`.
#' @param F_summary Summary of F over ages (ACL) or length bins (ALSCL) at each
#'   time step: `"mean"` (default), the unweighted mean, or `"apical"`, the
#'   maximum, as in [fit_scenarios()].
#' @param conf_level Nominal confidence level of the intervals whose coverage
#'   is reported, strictly between zero and one. Default 0.95.
#' @param interval Form of the interval of a time series: `"lognormal"`
#'   (default), `exp(log(estimate) +/- z * SE / estimate)`, or `"wald"`,
#'   `estimate +/- z * SE`, as in the plots of the package.
#' @param preserve_missing Logical; passed to [simulate_fit()]. Default TRUE
#'   keeps missing and zero survey cells as they are in the observations.
#' @param silent Suppress fitting progress messages; default TRUE.
#' @param save_fits Logical; keep the refits (without the TMB object) in the
#'   result. Default FALSE.
#' @return An object of class `alscl_self_test`, a list with:
#'   \describe{
#'     \item{replicates}{One row per simulated data set: `replicate`,
#'       `elapsed` (seconds), `error`, the numerical checks of the refit
#'       (`convergence_code`, `max_abs_gradient`, `pdHess`, `bound_hit`,
#'       `natural_boundary`, `numerical_ok`, `issues`), `converged`,
#'       `failure_reasons` and `warnings`, as in [summarize_simulations()].}
#'     \item{series}{One row per replicate, quantity and time step: `truth`,
#'       `estimate`, `std_error`, `conf_low`, `conf_high`, `error` (estimate
#'       minus truth), `relative_error` (error divided by truth), `covered`
#'       and `numerical_ok`.}
#'     \item{parameters}{One row per replicate and estimated scalar parameter,
#'       on the natural scale of [extract_parameters()], with the same
#'       columns.}
#'     \item{by_year}{Summaries of `series` over the replicates that pass the
#'       numerical checks, by quantity and time step: `n_values`,
#'       `median_relative_error`, `q10_relative_error`, `q90_relative_error`
#'       (10th and 90th percentiles), `median_absolute_relative_error`,
#'       `n_intervals` and `coverage`.}
#'     \item{series_summary, parameter_summary}{The same summaries pooled over
#'       the time steps of each quantity, and for each scalar parameter (with
#'       its `truth`).}
#'     \item{screen}{`n_replicates`, `n_errors` (refits that stopped with an
#'       error), `n_converged`, `n_passed` and `pass_rate`, the share of
#'       replicates that pass the numerical checks.}
#'     \item{failures}{Reasons of the replicates that fail the numerical
#'       checks, as in [summarize_simulations()].}
#'     \item{settings}{The arguments used, the model, the number of workers
#'       and the elapsed time in seconds.}
#'     \item{simulation}{The `metadata` of [simulate_fit()].}
#'     \item{fits}{The refits when `save_fits = TRUE`, otherwise NULL.}
#'   }
#'   `summary()` returns the settings, `screen`, `series_summary`,
#'   `parameter_summary` and `failures`; `print()` prints that summary.
#'   [plot_self_test()] draws the relative errors.
#' @details **What is simulated.** With `process = "conditional"` every data
#'   set keeps the fitted population (the estimated recruitment, fishing
#'   mortality and initial deviations) and only the observation error is drawn
#'   again, so the truth is the same population in every replicate: the
#'   estimates of the source fit. This tests the observation model and the
#'   numerical behaviour of the estimation for that one population. With
#'   `process = "resample"` new recruitment, F and initial deviations are drawn
#'   from their estimated distribution (variances and correlations) before the
#'   observations are drawn, so each replicate has its own population, computed
#'   by the model, and the truth of a time series differs between replicates.
#'   This also tests whether the variances of the process deviations can be
#'   estimated. In conditional mode the deviations are the fitted values, not
#'   a draw from their distribution: their mean need not be zero, so the
#'   refits can move the level of a process between its mean parameter (for
#'   example mean_log_F) and the deviations. The relative errors of the time
#'   series are then a better measure than those of the process parameters.
#'   In both cases the truth of a scalar parameter is its estimate
#'   in the source fit, and fixed parameters, the natural mortality rate,
#'   survey catchability, growth and maturity stay as in the source fit.
#'   Relative errors are computed against the truth of each replicate.
#'
#'   **Refits.** Each refit uses the model, structure, map, bounds, fixed
#'   values and fixed inputs of the source fit, from its recipe. With
#'   `start = "original"` it also uses the starting values and the number of
#'   starts of the source fit, so that the refits search for the optimum as
#'   the source fit did; a refit that stops at a local optimum then counts as
#'   an error of the estimates, as it would with real data. With
#'   `start = "estimates"` each refit starts at the values used to simulate.
#'   This is the usual setting of a self-test and is faster, but it can hide
#'   local optima and parameters that the data do not determine, because the
#'   optimizer starts near the answer. Comparing the two shows whether the
#'   starting values matter.
#'
#'   **Summaries.** Bias is the median relative error over the replicates
#'   that pass the numerical checks, as in Stock and Miller (2021), and the
#'   median absolute relative error measures the size of the errors. Refits that
#'   fail the checks stay in `replicates`, `series` and `parameters` but not in
#'   the summaries; read `screen` and `failures` with them. Coverage is the
#'   share of the intervals that contain the truth, for the series with
#'   standard errors (SSB, recruitment, total biomass and abundance; not the
#'   summary of F) and for the scalar parameters, whose interval is that of
#'   [extract_parameters()]. A relative error is not defined when the truth is
#'   zero and is large when the truth is near zero, as for t0 or a correlation
#'   near zero; `error` gives the absolute error.
#'
#'   **Interpretation.** A self-test in which the estimates recover the truth
#'   shows that the model can estimate its parameters from data like these
#'   when its assumptions hold (Deroba et al. 2015). It says nothing about the
#'   bias from a wrong natural mortality rate, survey catchability or growth
#'   form, which for fits to a survey index alone are the main sources of
#'   error; testing those needs simulations from an operating model with
#'   different assumptions ([sim_model()]).
#'
#'   Replicates run on socket workers when `ncores` is greater than 1, as in
#'   [fit_scenarios()]; the results are the same for any number of workers.
#'   Reported studies commonly use 100 data sets (Deroba et al. 2015).
#' @references Deroba, J.J., et al. (2015).
#'   Simulation testing the robustness of stock assessment models to error:
#'   some results from the ICES strategic initiative on stock assessment
#'   methods. ICES Journal of Marine Science 72, 19-30.
#'   \doi{10.1093/icesjms/fst237}
#'
#'   Stock, B.C., Miller, T.J. (2021). The Woods Hole Assessment Model (WHAM):
#'   a general state-space assessment framework that incorporates time- and
#'   age-varying processes via random effects and links to environmental
#'   covariates. Fisheries Research 240, 105967.
#'   \doi{10.1016/j.fishres.2021.105967}
#' @seealso [simulate_fit()], [summarize_simulations()], [plot_self_test()].
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' st <- self_test(fit, nsim = 5, seed = 1)
#' st
#' head(st$by_year)
#' plot_self_test(st)
#' }
#' @export
self_test <- function(fit, nsim = 20, seed = NULL, process = c("conditional", "resample"),
                      start = c("original", "estimates"), nstarts = NULL, ncores = 1,
                      quantities = c("SSB", "Rec", "F"), F_summary = c("mean", "apical"),
                      conf_level = .95, interval = c("lognormal", "wald"),
                      preserve_missing = TRUE, silent = TRUE, save_fits = FALSE) {
  process <- match.arg(process)
  start <- match.arg(start)
  F_summary <- match.arg(F_summary)
  interval <- match.arg(interval)
  nsim <- .acl_positive_integer(nsim, "nsim")
  ncores <- .acl_positive_integer(ncores, "ncores")
  if (!is.null(nstarts)) nstarts <- .acl_positive_integer(nstarts, "nstarts")
  z <- .acl_conf_level(conf_level)
  for (nm in c("preserve_missing", "silent", "save_fits")) .acl_check_flag(get(nm), nm)
  allowed <- c("SSB", "Rec", "F", "B", "N")
  if (!is.character(quantities) || !length(quantities) || anyNA(quantities) ||
      anyDuplicated(quantities) || any(!quantities %in% allowed))
    stop("quantities must contain distinct names from SSB, Rec, F, B and N.", call. = FALSE)
  if (is.list(fit) && (inherits(fit, "alscl_fit_error") || !is.null(fit$error)))
    stop("fit is a failed fit (", .acl_error_text(fit), "); a self-test needs a fitted model.",
         call. = FALSE)
  if (!is.list(fit) || is.null(fit$recipe))
    stop("self_test() refits the model with the settings of fit, but fit has no recipe. ",
         "Refit it with the current package, or attach its inputs with save_assessment(fit, file, x = ) ",
         "and read it with read_assessment().", call. = FALSE)
  recipe <- .acl_recipe(fit)
  model <- recipe$model
  if (!.acl_numerical_ok(fit))
    stop("The source fit fails the numerical checks (fit$diagnostics$numerical_ok is not TRUE); ",
         "a self-test of that fit would not show what the model can estimate. ",
         "See fit$diagnostics$issues and refit first.", call. = FALSE)
  missing_q <- setdiff(quantities, "F")[!vapply(setdiff(quantities, "F"), function(q)
    is.numeric(fit$report[[q]]) && length(fit$report[[q]]) == length(fit$year), logical(1))]
  if (length(missing_q))
    stop("The report of fit has no time series ", paste(missing_q, collapse = ", "), ".", call. = FALSE)
  .acl_check_implementation(recipe)
  started <- proc.time()[["elapsed"]]
  simulated <- simulate_fit(fit, nsim = nsim, seed = seed, process = process,
                            preserve_missing = preserve_missing)
  # Natural-scale truth of the estimated scalar parameters: the estimates of
  # the source fit, which simulate_fit() uses in every replicate.
  settings <- .acl_scale_settings(fit)
  free <- names(fit$opt$par)
  natural <- function(values) vapply(free, function(nm)
    .acl_parameter_transform(nm, values[[nm]], settings = settings), numeric(1))
  overrides <- list(ncores = 1L, output = FALSE, silent = silent)
  if (!is.null(nstarts)) overrides$nstarts <- nstarts
  fit_settings <- lapply(simulated$simulations, function(s) {
    x <- s$x
    if (start == "estimates") {
      config <- x$fit_config[[model]]
      starts <- config$parameters
      if (is.null(starts)) starts <- list()
      starts[free] <- s$truth$parameters[free]
      config["parameters"] <- list(starts)
      x$fit_config[[model]] <- config
    }
    .acl_resolved_args(x, model, overrides)
  })
  previous <- options(recipe$settings)
  on.exit(options(previous), add = TRUE)
  results <- .acl_batch_apply(fit_settings, model, ncores)
  names(results) <- names(simulated$simulations)
  fits <- lapply(results, `[[`, "fit")
  truth <- lapply(simulated$simulations, function(s)
    list(year = as.numeric(fit$year), SSB = as.numeric(s$truth$SSB)))
  status <- summarize_simulations(fits, truth, quantities = "SSB")
  replicates <- status$replicates
  replicates$warnings <- vapply(results, function(r) paste(r$warnings, collapse = "; "), character(1))
  replicates$elapsed <- vapply(results, function(r) r$elapsed, numeric(1))
  ok <- stats::setNames(replicates$numerical_ok, replicates$replicate)

  series <- do.call(rbind, lapply(names(fits), function(id) {
    refit <- fits[[id]]
    target <- simulated$simulations[[id]]$truth
    tab <- refit$est_std
    do.call(rbind, lapply(quantities, function(q) {
      true_value <- .acl_self_test_series(target, q, F_summary)
      estimate <- if (is.null(refit$report)) NULL else
        .acl_self_test_series(refit$report, q, F_summary, if (model == "acl") "F" else "FL")
      Y <- length(fit$year)
      if (is.null(estimate) || length(estimate) != Y) estimate <- rep(NA_real_, Y)
      se <- rep(NA_real_, Y)
      if (q != "F" && length(dim(tab)) == 2L && "Std. Error" %in% colnames(tab)) {
        candidate <- tab[which(rownames(tab) == q), "Std. Error"]
        if (is.numeric(candidate) && length(candidate) == Y) se <- as.numeric(candidate)
      }
      bounds <- .acl_self_test_interval(estimate, se, z, interval)
      error <- estimate - true_value
      covered <- ifelse(is.finite(bounds$low) & is.finite(bounds$high),
                        true_value >= bounds$low & true_value <= bounds$high, NA)
      data.frame(replicate = id, quantity = q, year = as.numeric(fit$year), truth = true_value,
        estimate = estimate, std_error = se, conf_low = bounds$low, conf_high = bounds$high,
        error = error, relative_error = ifelse(true_value != 0, error / true_value, NA_real_),
        covered = covered, numerical_ok = unname(ok[id]), stringsAsFactors = FALSE)
    }))
  }))
  parameters <- do.call(rbind, lapply(names(fits), function(id) {
    refit <- fits[[id]]
    true_value <- natural(simulated$simulations[[id]]$truth$parameters)
    table <- if (is.null(refit$error)) tryCatch(
      .acl_extract_parameters(refit, "natural", z), error = function(e) NULL) else NULL
    row <- if (is.null(table)) rep(NA_integer_, length(free)) else match(free, table$parameter)
    pick <- function(column) if (is.null(table)) rep(NA_real_, length(free)) else table[[column]][row]
    estimate <- pick("estimate"); low <- pick("conf_low"); high <- pick("conf_high")
    error <- estimate - true_value
    data.frame(replicate = id, parameter = free, truth = unname(true_value), estimate = estimate,
      std_error = pick("std_error"), conf_low = low, conf_high = high, error = error,
      relative_error = ifelse(true_value != 0, error / true_value, NA_real_),
      covered = ifelse(is.finite(low) & is.finite(high),
                       true_value >= low & true_value <= high, NA),
      numerical_ok = unname(ok[id]), stringsAsFactors = FALSE)
  }))
  rownames(series) <- rownames(parameters) <- NULL
  by_year <- .acl_self_test_rows(series, c("quantity", "year"))
  by_year <- by_year[order(match(by_year$quantity, quantities), by_year$year), , drop = FALSE]
  series_summary <- .acl_self_test_rows(series, "quantity")
  series_summary <- series_summary[match(quantities, series_summary$quantity), , drop = FALSE]
  parameter_summary <- .acl_self_test_rows(parameters, "parameter")
  parameter_summary <- parameter_summary[match(free, parameter_summary$parameter), , drop = FALSE]
  parameter_summary <- cbind(parameter_summary["parameter"],
    truth = unname(natural(simulated$simulations[[1L]]$truth$parameters)), parameter_summary[-1L])
  rownames(by_year) <- rownames(series_summary) <- rownames(parameter_summary) <- NULL
  screen <- data.frame(n_replicates = nsim, n_errors = sum(nzchar(replicates$error)),
    n_converged = sum(replicates$converged), n_passed = sum(replicates$numerical_ok),
    pass_rate = mean(replicates$numerical_ok))
  structure(list(replicates = replicates, series = series, parameters = parameters,
    by_year = by_year, series_summary = series_summary, parameter_summary = parameter_summary,
    screen = screen, failures = status$failures,
    settings = list(model = toupper(model), nsim = nsim, seed = seed, process = process,
      start = start, nstarts = as.integer(fit_settings[[1L]]$nstarts), quantities = quantities,
      F_summary = F_summary, F_group = if (model == "acl") "age" else "length",
      conf_level = conf_level, interval = interval, preserve_missing = preserve_missing,
      workers = .acl_workers(min(ncores, nsim)),
      elapsed = unname(proc.time()[["elapsed"]] - started), growth_step = fit$growth_step),
    simulation = simulated$metadata, fits = if (save_fits) fits else NULL),
    class = c("alscl_self_test", "list"))
}

#' @rdname self_test
#' @param object,x An `alscl_self_test` object, or its summary for `print()`.
#' @param digits Number of significant digits to print. Default 3.
#' @param ... Not used.
#' @export
summary.alscl_self_test <- function(object, ...) {
  failures <- object$failures
  if (is.data.frame(failures)) failures <- failures[failures$n_replicates > 0L, , drop = FALSE]
  structure(list(settings = object$settings, screen = object$screen,
    series_summary = object$series_summary, parameter_summary = object$parameter_summary,
    failures = failures), class = "summary.alscl_self_test")
}

#' @rdname self_test
#' @export
print.summary.alscl_self_test <- function(x, digits = 3, ...) {
  s <- x$settings
  cat("Self-test of ", s$model, ": ", s$nsim, " data sets simulated with process = \"", s$process,
      "\"; refits with start = \"", s$start, "\" and ", s$nstarts,
      if (isTRUE(s$nstarts == 1)) " start" else " starts", "\n", sep = "")
  cat("Refits that pass the numerical checks: ", x$screen$n_passed, " of ", x$screen$n_replicates,
      " (", x$screen$n_errors, " stopped with an error)\n", sep = "")
  if (is.data.frame(x$failures) && nrow(x$failures)) {
    cat("\nReasons for failing the checks:\n")
    print(x$failures, row.names = FALSE)
  }
  cat("\nRelative error of the time series, refits that pass the checks:\n")
  print(x$series_summary, row.names = FALSE, digits = digits)
  if ("F" %in% x$series_summary$quantity)
    cat("F is the ", if (s$F_summary == "mean") "mean" else "maximum", " over ",
        if (s$F_group == "age") "ages" else "length bins", " at each time step.\n", sep = "")
  cat("\nRelative error of the estimated parameters (natural scale), refits that pass the checks:\n")
  print(x$parameter_summary, row.names = FALSE, digits = digits)
  cat("\nCoverage is the share of ", 100 * s$conf_level,
      "% intervals that contain the truth.\n", sep = "")
  invisible(x)
}

#' @rdname self_test
#' @export
print.alscl_self_test <- function(x, ...) {
  print(summary(x), ...)
  invisible(x)
}
