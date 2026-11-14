# Prepare a genuine training fold without fitting to the complete observations.
.acl_hindcast_args <- function(args, origin, model) {
  periods <- ncol(args$data.CatL) - 1L
  args["map"] <- list(.acl_retro_map(args, periods - origin, model))
  # A natural mortality rate by age and time step and a survey catchability
  # by length and time step keep the training time steps.
  for (nm in c("M", "survey_q"))
    if (!is.null(args[[nm]])) args[[nm]] <- .acl_truncate_time(args[[nm]], periods, origin)
  for (nm in c("data.CatL", "data.wgt", "data.mat"))
    args[[nm]] <- args[[nm]][, seq_len(origin + 1L), drop = FALSE]
  args$ncores <- 1L
  args$output <- FALSE
  args
}

# Conditional means on the log-process scale; these are not marginal means
# after exponentiation or nonlinear population transitions.
# future_M is the natural mortality rate of the held-out time steps (age by
# time step) when the supplied rate varies over time; NULL uses the fitted rate.
# future_q is the survey catchability of the held-out time steps (length by
# time step) when it was supplied by time step; NULL uses the fitted vector.
.acl_hindcast_predict <- function(fit, horizon, future_M = NULL, future_q = NULL) {
  r <- fit$report
  scalar <- function(x, name, correlation = FALSE) {
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x) ||
        (correlation && (x < 0 || x > 1)))
      stop("Invalid fitted ", name, " for the conditional process path.", call. = FALSE)
    as.numeric(x)
  }
  phi_R <- scalar(r$phi_log_R, "recruitment correlation", TRUE)
  phi_F <- scalar(r$phi_log_F_y, "F time correlation", TRUE)
  mean_R <- scalar(r$mean_log_R, "mean_log_R")
  mean_F <- scalar(r$mean_log_F, "mean_log_F")
  Y <- length(fit$year)
  if (!is.numeric(r$dev_log_R) || length(r$dev_log_R) != Y ||
      any(!is.finite(r$dev_log_R)))
    stop("Fitted recruitment deviations do not match training periods.", call. = FALSE)
  groups <- if (fit$model_type == "ACL") length(fit$age) else length(fit$len_mid)
  deviations <- r$dev_log_F
  if (!is.matrix(deviations) || !is.numeric(deviations) ||
      ncol(deviations) != Y || !nrow(deviations) %in% c(1L, groups) ||
      any(!is.finite(deviations)))
    stop("Fitted F deviations do not match training groups and periods.", call. = FALSE)
  powers <- seq_len(horizon)
  recruitment <- exp(mean_R + tail(r$dev_log_R, 1L) * phi_R^powers)
  F <- exp(mean_F + outer(deviations[, Y], phi_F^powers))
  if (nrow(F) == 1L) F <- matrix(rep(as.numeric(F), each = groups), groups, horizon)
  args <- fit$recipe$args
  if (!is.list(args)) stop("Training fit recipe is unavailable.", call. = FALSE)
  prep_args <- args[intersect(names(args), names(formals(.acl_prepare_data)))]
  prepared <- do.call(.acl_prepare_data, prep_args)
  L <- length(fit$len_mid)
  weight <- matrix(rep(prepared$data$weight[, Y], horizon), L, horizon)
  maturity <- matrix(rep(prepared$data$mat[, Y], horizon), L, horizon)
  projection <- project_model(fit, F = F, recruitment = recruitment,
    weight = weight, maturity = maturity, M = future_M)
  NL <- projection$states$NL
  # With a survey catchability multiplier by age, the survey sees the sum
  # over ages of the multiplier times numbers at length and age.
  q_age <- prepared$data$q_age
  if (!is.null(q_age)) NL <- if (fit$model_type == "ACL")
    fit$report$pla %*% (q_age * projection$states[["NA"]]) else
    apply(sweep(projection$states$NLA, 2L, q_age, "*"), c(1L, 3L), sum)
  log_NL <- if (fit$model_type == "ACL") log(NL + 1e-300) else log(pmax(NL, 1e-300))
  log_q <- if (is.null(future_q)) prepared$data$log_q else log(future_q)
  prediction <- if (is.null(future_q)) sweep(log_NL, 1L, log_q, "+") else log_NL + log_q
  if (any(!is.finite(prediction))) stop("Nonfinite survey predictions.", call. = FALSE)
  list(predicted_log = prediction, F = F, recruitment = recruitment,
    log_q = log_q)
}

.acl_hindcast_baseline <- function(observed) {
  L <- nrow(observed)
  out <- data.frame(naive_log = rep(NA_real_, L), scale_log = rep(NA_real_, L),
    scale_pairs = integer(L))
  for (i in seq_len(L)) {
    values <- rep(NA_real_, ncol(observed))
    positive <- is.finite(observed[i, ]) & observed[i, ] > 0
    values[positive] <- log(observed[i, positive])
    if (any(positive)) out$naive_log[i] <- tail(values[positive], 1L)
    # diff() retains the full grid: missing/zero periods cannot become neighbours.
    changes <- abs(diff(values))
    usable <- is.finite(changes)
    out$scale_pairs[i] <- sum(usable)
    if (any(usable)) out$scale_log[i] <- mean(changes[usable])
  }
  out
}

.acl_hindcast_scores <- function(predictions, horizon) {
  do.call(rbind, lapply(seq_len(horizon), function(h) {
    x <- predictions[predictions$horizon == h, , drop = FALSE]
    paired <- x$included
    scaled <- paired & is.finite(x$scale_log) & x$scale_log > 0
    average <- function(z) if (length(z)) mean(z) else NA_real_
    data.frame(horizon = h, n_positive = sum(x$positive_observation),
      n_prediction = sum(x$positive_observation & is.finite(x$predicted_log)),
      n = sum(paired), log_RMSE = sqrt(average(x$error_log[paired]^2)),
      log_MAE = average(abs(x$error_log[paired])),
      naive_log_RMSE = sqrt(average(x$naive_error_log[paired]^2)),
      naive_log_MAE = average(abs(x$naive_error_log[paired])),
      n_scaled = sum(scaled),
      log_MASE = average(abs(x$error_log[scaled]) / x$scale_log[scaled]),
      naive_log_MASE = average(abs(x$naive_error_log[scaled]) / x$scale_log[scaled]))
  }))
}

#' Validate survey-index predictions by leaving out future periods
#'
#' Fit expanding training windows and predict the next periods without using
#' their observations in fitting. This evaluates conditional point predictions
#' of log survey indices, separately from retrospective stability.
#' @param x An input bundle accepted by run_acl() or run_alscl().
#' @param model Model to fit, "acl" (default) or "alscl".
#' @param horizon Positive integer; number of future model periods predicted
#'   from each forecast origin (the last training time step). A period is a
#'   quarter for quarterly inputs.
#' @param nfolds Positive integer; number of most recent eligible forecast
#'   origins. Each origin must retain min_train periods and horizon future periods.
#' @param min_train Minimum training periods, at least two; default three.
#' @param ncores Maximum independent socket workers for training folds.
#' @param nstarts Independent starts per fold. NULL retains an explicit bundle
#'   setting, otherwise uses one. Starts run sequentially within each fold.
#' @param silent Suppress fitting progress messages; default TRUE. Warnings are
#'   captured in diagnostics for each fold.
#' @param save_fits Retain portable training fits when TRUE. Default FALSE;
#'   recipes, training settings and start diagnostics are retained either way.
#' @param ... Overrides of run_acl() or run_alscl() fitting arguments. Supplied
#'   starting values and assumptions must be chosen without held-out data.
#' @return A list with predictions, scores by horizon, diagnostics for all folds,
#'   training settings and recipes, start_diagnostics, conditional process paths,
#'   optional portable fits, and explicit assumptions. predictions includes every
#'   held-out length-period cell, including missing/zero observations and failed
#'   folds, with an inclusion flag and status. n_positive counts positive held-out
#'   observations, n_prediction those with valid model predictions, n the common
#'   model/naive scoring cells, and n_scaled the cells used for log-scale MASE.
#' @details Each fold uses only data through its forecast origin. No full-data
#'   fit is used to initialize the folds. Recruitment and F deviations follow
#'   the fitted AR(1) conditional means on the log-process scale: the last fitted
#'   deviation times phi to the power of the forecast horizon. Projections retain
#'   the scalar parameter values from the training fit and the specified survey catchability.
#'   A natural mortality rate by age and time step is supplied for the
#'   complete time grid. Each training fit uses the columns up to its forecast
#'   origin, and the prediction uses the columns of the held-out time steps.
#'   The same holds for survey catchability supplied by length and time step.
#'   project_model() advances
#'   the population; training-terminal weights and maturity are repeated only
#'   for this calculation and do not affect survey-number predictions. These are
#'   plug-in predictions along a conditional log-process path, not marginal
#'   predictive means. No predictive intervals or probability scores are provided.
#'
#'   Training fits must pass the numerical screen; failures and prediction errors
#'   remain in diagnostics and are not scored. Time-varying dev_log_R and
#'   dev_log_F maps must be absent, NULL, or identity factors. Fixed/tied time
#'   deviations are rejected because their future constraints are unspecified.
#'   Identity maps are truncated to each training window. Static initial-state
#'   constraints remain supported. Supplied map/scalar choices and starting values
#'   can still leak future information if the user tuned them using held-out data.
#'
#'   The naive forecast holds the latest positive training observation at each
#'   length constant. Model and naive log RMSE/MAE use the same positive held-out
#'   cells with both predictions available. log_MASE divides each absolute log
#'   error by that length's mean absolute adjacent-period log change within the
#'   training window. Only pairs of consecutive positive observations contribute;
#'   missing/zero periods are not compressed. A zero scale or no eligible pair
#'   gives no scaled score for that cell. Overlapping folds are retained and
#'   scored as distinct origin-horizon predictions, not independent observations.
#' @examples
#' \donttest{
#' validation <- hindcast_model(YTF_example, model = "acl", horizon = 1,
#'   nfolds = 2)
#' validation$diagnostics[, c("fold", "origin", "numerical_ok", "prediction_ok")]
#' validation$scores
#' }
#' @export
hindcast_model <- function(x, model = c("acl", "alscl"), horizon = 1,
                           nfolds = 3, min_train = 3, ncores = 1,
                           nstarts = NULL, silent = TRUE, save_fits = FALSE, ...) {
  model <- match.arg(model)
  horizon <- .acl_positive_integer(horizon, "horizon")
  nfolds <- .acl_positive_integer(nfolds, "nfolds")
  min_train <- .acl_positive_integer(min_train, "min_train", 2L)
  ncores <- .acl_positive_integer(ncores, "ncores")
  for (nm in c("silent", "save_fits")) {
    value <- get(nm)
    if (!is.logical(value) || length(value) != 1L || is.na(value))
      stop(nm, " must be TRUE or FALSE.", call. = FALSE)
  }
  overrides <- .acl_input_list(list(...), "Fitting overrides")
  overrides[c("ncores", "output", "silent")] <- list(1L, FALSE, silent)
  if (!is.null(nstarts)) overrides$nstarts <- .acl_positive_integer(nstarts, "nstarts")
  args <- .acl_resolved_args(x, model, overrides)
  args$nstarts <- .acl_positive_integer(args$nstarts, "nstarts")
  prepared <- do.call(.acl_prepare_data,
    args[intersect(names(args), names(formals(.acl_prepare_data)))])
  Y <- length(prepared$year)
  available <- as.double(Y) - horizon - min_train + 1L
  if (available < nfolds)
    stop("Requested ", nfolds, " folds, but only ", max(0L, available),
      " origins retain min_train periods and the complete horizon.", call. = FALSE)
  # Validate full-grid maps before clipping, then reject constraints whose
  # extension beyond each forecast origin has not been specified.
  mapping <- .acl_retro_map(args, 0L, model)
  for (nm in c("dev_log_R", "dev_log_F")) {
    value <- mapping[[nm]]
    if (!is.null(value) && (anyNA(value) || anyDuplicated(as.integer(value))))
      stop("hindcast_model() does not support fixed or tied ", nm,
        " maps: the future constrained process is unspecified. Use an identity factor or no map.",
        call. = FALSE)
  }
  origins <- seq.int(Y - horizon - nfolds + 1L, Y - horizon)
  settings <- lapply(origins, function(origin) .acl_hindcast_args(args, origin, model))
  names(settings) <- paste0("fold_", seq_along(settings))
  started <- proc.time()[["elapsed"]]
  # Forecast scores use point estimates and the numerical screen only; skip
  # the delta-method standard errors unless the fits are returned.
  if (!save_fits && is.null(getOption("ALSCL.se_level"))) {
    old_se <- options(ALSCL.se_level = "hessian")
    on.exit(options(old_se), add = TRUE)
  }
  results <- .acl_batch_apply(settings, model, ncores)
  names(results) <- names(settings)
  diagnostics <- .acl_batch_status(results)
  known_screen <- vapply(results, function(z) isTRUE(z$fit$diagnostics$numerical_ok), logical(1))
  unavailable <- !vapply(results, function(z) isTRUE(z$fit$diagnostics$numerical_ok) ||
    isFALSE(z$fit$diagnostics$numerical_ok), logical(1))
  diagnostics$numerical_ok <- diagnostics$numerical_ok & known_screen
  diagnostics$issues[unavailable] <- vapply(diagnostics$issues[unavailable], function(z)
    paste(c(if (nzchar(z)) z, "numerical screen unavailable"), collapse = "; "), character(1))
  names(diagnostics)[names(diagnostics) == "scenario"] <- "fold"
  diagnostics$fold <- seq_along(results)
  diagnostics$origin_index <- origins
  diagnostics$origin <- prepared$year[origins]
  diagnostics$nstarts <- rep(args$nstarts, length(results))
  diagnostics$prediction_ok <- FALSE
  diagnostics$prediction_error <- ""
  paths <- vector("list", length(results))
  predictions <- vector("list", length(results))
  L <- nrow(prepared$observations)
  for (i in seq_along(results)) {
    origin <- origins[i]
    extra_warnings <- character()
    prediction_error <- NULL
    prediction <- if (isTRUE(diagnostics$numerical_ok[i])) tryCatch(withCallingHandlers(
      .acl_hindcast_predict(results[[i]]$fit, horizon,
        future_M = .acl_future_time(args$M, Y, origin, horizon),
        future_q = .acl_future_time(args$survey_q, Y, origin, horizon)), warning = function(w) {
        extra_warnings <<- c(extra_warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }), error = function(e) {
        prediction_error <<- conditionMessage(e)
        NULL
      }) else NULL
    if (length(extra_warnings)) diagnostics$warnings[i] <- paste(
      c(results[[i]]$warnings, extra_warnings), collapse = "; ")
    if (!is.null(prediction_error)) diagnostics$prediction_error[i] <- prediction_error
    diagnostics$prediction_ok[i] <- !is.null(prediction)
    paths[i] <- list(if (is.null(prediction)) NULL else prediction[c("F", "recruitment", "log_q")])
    baseline <- .acl_hindcast_baseline(prepared$observations[, seq_len(origin), drop = FALSE])
    observed <- as.numeric(prepared$observations[, origin + seq_len(horizon), drop = FALSE])
    positive <- is.finite(observed) & observed > 0
    observed_log <- rep(NA_real_, length(observed))
    observed_log[positive] <- log(observed[positive])
    predicted_log <- if (is.null(prediction)) rep(NA_real_, length(observed)) else
      as.numeric(prediction$predicted_log)
    naive_log <- rep(baseline$naive_log, horizon)
    included <- positive & is.finite(predicted_log) & is.finite(naive_log)
    status <- ifelse(is.na(observed), "missing_observation", ifelse(observed == 0,
      "zero_observation", if (!diagnostics$numerical_ok[i]) "fit_failed" else
      if (!diagnostics$prediction_ok[i]) "prediction_failed" else
      ifelse(!is.finite(naive_log), "no_training_baseline", "included")))
    predictions[[i]] <- data.frame(fold = i, origin_index = origin,
      origin = prepared$year[origin], year = rep(prepared$year[origin + seq_len(horizon)], each = L),
      horizon = rep(seq_len(horizon), each = L), length = rep(prepared$bins$mid, horizon),
      length_label = rep(prepared$bins$labels, horizon), observed = observed,
      observed_log = observed_log, predicted_log = predicted_log, naive_log = naive_log,
      scale_log = rep(baseline$scale_log, horizon), scale_pairs = rep(baseline$scale_pairs, horizon),
      error_log = observed_log - predicted_log, naive_error_log = observed_log - naive_log,
      positive_observation = positive, included = included, status = status,
      stringsAsFactors = FALSE)
  }
  predictions <- do.call(rbind, predictions)
  rownames(predictions) <- rownames(diagnostics) <- NULL
  names(paths) <- names(settings)
  fits <- lapply(results, `[[`, "fit")
  list(predictions = predictions, scores = .acl_hindcast_scores(predictions, horizon),
    diagnostics = diagnostics, settings = settings,
    recipes = lapply(fits, `[[`, "recipe"),
    start_diagnostics = lapply(fits, `[[`, "start_diagnostics"),
    process_paths = paths, fits = if (save_fits) fits else NULL, model = model,
    horizon = horizon, time_step = prepared$growth_step,
    workers = .acl_workers(min(ncores, length(settings))), elapsed = unname(proc.time()[["elapsed"]] - started),
    assumptions = list(prediction = "plug-in conditional mean log-process path; not a marginal predictive mean",
      future_process = "last fitted log deviations times AR(1) correlation^horizon; no future innovations",
      future_biology = "weights and maturity from the final training step; growth from the training fit; specified survey catchability",
      uncertainty = "none; no intervals or probability scores",
      training = "expanding windows; no full-data fit or full-data fitted starting values",
      supplied_settings = "user-supplied assumptions and starts must not be tuned with held-out observations",
      scoring = "paired positive finite model/naive cells, on the natural-log survey-index scale",
      scaling = "mean absolute adjacent-period training log change separately for each length; zero/undefined scale omitted",
      numerical_screen = "failed or unavailable training screens withhold predictions",
      overlap = "origin-horizon forecasts may share held-out observations; counts are prediction cases"))
}
