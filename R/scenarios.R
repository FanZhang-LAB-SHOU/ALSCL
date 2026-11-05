# Apply FUN over X on socket workers (or sequentially for one worker). Shared by
# the scenario, profile, hindcast, retrospective and simulation batches. The
# model is compiled in the parent so that workers never write the same cache.
.acl_cluster_lapply <- function(X, FUN, ncores, model, ...) {
  ncores <- .acl_workers(min(.acl_positive_integer(ncores, "ncores"), length(X)))
  if (ncores == 1L) return(lapply(X, FUN, ...))
  info <- .acl_compile(toupper(model))
  cl <- parallel::makeCluster(ncores)
  on.exit(parallel::stopCluster(cl), add = TRUE)
  .acl_initialize_workers(cl, cache = dirname(dirname(info$cpp_path)),
                          settings = .acl_worker_options())
  parallel::parLapply(cl, X, FUN, ...)
}

# Run independent assessment tasks with one parallel layer. Results are portable
# in both modes: a TMB external pointer cannot be sent back from a socket worker.
.acl_batch_fit <- function(args, model) {
  started <- proc.time()[["elapsed"]]
  warnings <- character()
  old <- options(ALSCL.sd_cores = 1L)
  on.exit(options(old), add = TRUE)
  result <- tryCatch(withCallingHandlers({
    value <- do.call(if (model == "acl") run_acl else run_alscl, args)
    value$obj <- NULL
    value
  }, warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  }), error = function(e) list(converge = "FAILED", error = conditionMessage(e)))
  list(fit = result, elapsed = unname(proc.time()[["elapsed"]] - started),
       pid = Sys.getpid(), warnings = unique(warnings))
}

.acl_batch_apply <- function(settings, model, ncores)
  .acl_cluster_lapply(settings, .acl_batch_fit, ncores, model, model = model)

.acl_batch_status <- function(results) {
  do.call(rbind, lapply(seq_along(results), function(i) {
    x <- results[[i]]
    cbind(data.frame(scenario = names(results)[i], elapsed = x$elapsed,
      pid = x$pid, error = x$fit$error %||% "",
      warnings = paste(x$warnings, collapse = "; "), stringsAsFactors = FALSE),
      .acl_fit_status(x$fit, error = x$fit$error))
  }))
}

.acl_scenario_estimates <- function(fits, status, F_summary) {
  rows <- lapply(seq_along(fits), function(i) {
    fit <- fits[[i]]
    if (!is.null(fit$error)) return(NULL)
    series <- fit$report[intersect(c("SSB", "Rec"), names(fit$report))]
    F <- fit$report$FL %||% fit$report[["F"]]
    if (is.matrix(F) && ncol(F) == length(fit$year))
      series$F <- if (F_summary == "mean") colMeans(F) else apply(F, 2L, max)
    out <- lapply(names(series), function(quantity) {
      value <- as.numeric(series[[quantity]])
      if (length(value) != length(fit$year)) return(NULL)
      data.frame(scenario = names(fits)[i], quantity = quantity, year = fit$year,
        estimate = value, summary = if (quantity == "F") F_summary else "total",
        numerical_ok = status$numerical_ok[i], stringsAsFactors = FALSE)
    })
    do.call(rbind, out)
  })
  out <- do.call(rbind, rows)
  if (is.null(out)) out <- data.frame(scenario = character(), quantity = character(),
    year = numeric(), estimate = numeric(), summary = character(), numerical_ok = logical())
  rownames(out) <- NULL
  out
}

#' Fit sensitivity scenarios on a common set of observations
#'
#' Apply explicitly named changes to an input bundle. This is sensitivity to
#' assumptions, not a profile likelihood or an automatic model ranking.
#' @param x A bundle accepted by run_acl() or run_alscl().
#' @param scenarios Nonempty named list of named argument lists. Each list
#'   overrides the common settings, including complete parameters/map lists.
#'   A named NULL is preserved. An empty list defines the reference scenario.
#'   Data tables cannot be changed: compare scenarios on the same observations.
#' @param model Model to fit, "acl" (default) or "alscl".
#' @param ncores Maximum number of independent socket workers.
#' @param F_summary Group summary for F at each model time step: "mean" is the
#'   unweighted mean over ages (ACL) or lengths (ALSCL); "apical" is the maximum.
#'   These are descriptive summaries, not abundance-weighted mortality, and
#'   subannual F remains per model step rather than being annualized.
#' @param ... Common overrides of the fitting arguments, applied before scenarios.
#' @return A list with named portable fits (including error records), resolved
#'   settings, status, batch elapsed time, estimates and model. The estimates
#'   table retains failed numerical screens rather than silently discarding them.
#' @details Inner fitting uses one worker and sequential standard errors. Each
#'   scenario runs the nstarts of the bundle or of the call; when neither sets
#'   it, one start is used, the rule of hindcast_model() and retro_model().
#'   Warnings are recorded in status.
#'   Results omit session-specific obj pointers in both serial and parallel modes;
#'   use refit_model() when a live TMB objective is needed. No ranking is applied.
#' @examples
#' \dontrun{
#' z <- fit_scenarios(YTF_example, list(reference = list(),
#'   low_M = list(M = 0.15), common_F = list(F_structure = "year")),
#'   model = "alscl", ncores = 2, F_summary = "mean", silent = TRUE)
#' z$status
#' z$estimates
#' }
#' @export
fit_scenarios <- function(x, scenarios, model = c("acl", "alscl"), ncores = 1,
                          F_summary = c("mean", "apical"), ...) {
  model <- match.arg(model)
  F_summary <- match.arg(F_summary)
  ncores <- .acl_positive_integer(ncores, "ncores")
  if (!is.list(scenarios) || is.data.frame(scenarios) || !length(scenarios) ||
      is.null(names(scenarios)) || anyNA(names(scenarios)) ||
      any(!nzchar(trimws(names(scenarios)))) || anyDuplicated(names(scenarios)))
    stop("scenarios must be a nonempty list with unique, nonempty names.", call. = FALSE)
  # One fitting worker per scenario, so a bundle without nstarts uses one
  # start, as in hindcast_model() and retro_model(); explicit nstarts is kept.
  overrides <- .acl_input_list(list(...), "Fitting overrides")
  overrides[c("ncores", "output")] <- list(1L, FALSE)
  common <- .acl_resolved_args(x, model, overrides)
  settings <- lapply(scenarios, function(changes) {
    if (any(c("data.CatL", "data.wgt", "data.mat") %in% names(changes)))
      stop("Scenarios must retain the common data tables.", call. = FALSE)
    args <- .acl_resolved_args(common, model, changes)
    args$ncores <- 1L
    args$output <- FALSE
    args
  })
  started <- proc.time()[["elapsed"]]
  results <- .acl_batch_apply(settings, model, ncores)
  names(results) <- names(scenarios)
  fits <- lapply(results, `[[`, "fit")
  status <- .acl_batch_status(results)
  rownames(status) <- NULL
  list(fits = fits, settings = settings, status = status,
    elapsed = unname(proc.time()[["elapsed"]] - started),
    estimates = .acl_scenario_estimates(fits, status, F_summary),
    model = model, F_summary = F_summary, workers = .acl_workers(min(ncores, length(settings))))
}
