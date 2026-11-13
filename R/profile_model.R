#' Profile one free scalar model parameter
#'
#' Fix one scalar at each grid value and refit the remaining free parameters and
#' random effects. External inputs such as M or survey catchability must instead
#' be investigated with fit_scenarios().
#' @param fit A fitted model retaining its recipe and final opt$par.
#' @param parameter One internal parameter name in names(fit$opt$par), for example
#'   "log_Linf". Fixed parameters and random-effect vectors are not supported.
#' @param values A nonempty vector of distinct finite grid values.
#' @param scale Scale of values. "natural" uses exp for log_* and mean_log_*,
#'   plogis for logit_* parameters and identity for t0. Parameter names always
#'   remain the internal names. "internal" uses optimizer coordinates directly.
#' @param ncores Maximum independent socket workers. Inner fitting and standard
#'   errors use one worker, retaining the original number of starts.
#' @return A list with parameter, scale, grid (including objective, delta_nll,
#'   numerical diagnostics, warnings and errors), named portable fits and settings.
#'   delta_nll is relative to the original fit; negative values are not clipped.
#'   workers is the number of socket workers that were used.
#' @details At least one other free scalar must remain, as required by the fitting
#'   core. Grid values must satisfy the original optimizer bounds. Other free
#'   scalar starts are initialized at the fitted optimum; fixed parameters and
#'   named NULL map releases are preserved. A delta_nll below -1e-6 triggers a
#'   warning to recheck the original fit; tiny negative differences can reflect
#'   roundoff. Check the grid fit's numerical status as well. The profile is
#'   conditional on the model and fixed-parameter settings. No confidence intervals or chi-square
#'   cutoffs are inferred, and failed numerical screens remain visible.
#' @examples
#' \dontrun{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' grid <- exp(fit$opt$par[["mean_log_F"]]) * c(0.9, 1, 1.1)
#' p <- profile_model(fit, "mean_log_F", values = grid,
#'                    scale = "natural", ncores = 2)
#' p$grid
#' }
#' @export
profile_model <- function(fit, parameter, values, scale = c("natural", "internal"),
                          ncores = 1) {
  scale <- match.arg(scale)
  ncores <- .acl_positive_integer(ncores, "ncores")
  recipe <- fit$recipe
  if (!is.list(recipe) || !identical(recipe$schema_version, 1L) ||
      !is.list(recipe$args) || !is.character(recipe$model) || length(recipe$model) != 1L ||
      is.na(recipe$model) || !recipe$model %in% c("acl", "alscl"))
    stop("fit must retain a supported fitting recipe; refit with the current package.", call. = FALSE)
  free <- fit$opt$par
  if (!is.character(parameter) || length(parameter) != 1L || is.na(parameter) ||
      !is.numeric(free) || any(!is.finite(free)) ||
      anyNA(names(free)) || sum(names(free) == parameter) != 1L)
    stop("parameter must name one free scalar in fit$opt$par; use fit_scenarios() for external inputs.", call. = FALSE)
  scalars <- names(create_parameters(recipe$model)$parameters)
  if (!parameter %in% scalars)
    stop("Only scalar fixed-effect parameters can be profiled.", call. = FALSE)
  if (length(free) < 2L)
    stop("Profiling requires at least one other free scalar parameter.", call. = FALSE)
  if (!is.numeric(values) || !is.null(dim(values)) || !length(values) || any(!is.finite(values)) || anyDuplicated(values))
    stop("values must be a nonempty vector of distinct finite numbers.", call. = FALSE)
  internal <- values
  if (scale == "natural") {
    if (grepl("^logit_", parameter)) {
      if (any(values <= 0 | values >= 1)) stop("Natural correlation values must lie strictly between 0 and 1.", call. = FALSE)
      internal <- stats::qlogis(values)
    } else if (grepl("^(log_|mean_log_)", parameter)) {
      if (any(values <= 0)) stop("Natural values must be strictly positive for a log parameter.", call. = FALSE)
      internal <- log(values)
    }
  }
  bounds <- fit$par_low_up
  if (!is.matrix(bounds) || !all(c("lower", "upper") %in% colnames(bounds)) ||
      !parameter %in% rownames(bounds) || anyNA(bounds[parameter, c("lower", "upper")]))
    stop("Original optimizer bounds are unavailable.", call. = FALSE)
  if (any(internal < bounds[parameter, "lower"] | internal > bounds[parameter, "upper"]))
    stop("Profile values must lie within the original optimizer bounds.", call. = FALSE)
  reference <- fit$opt$objective
  if (!is.numeric(reference) || length(reference) != 1L || !is.finite(reference))
    stop("The reference fit must have a finite objective.", call. = FALSE)
  reference <- as.numeric(reference)
  if (!is.null(recipe$settings$ALSCL.framework)) {
    old <- options(ALSCL.framework = recipe$settings$ALSCL.framework)
    on.exit(options(old), add = TRUE)
  }
  args <- .acl_resolved_args(recipe$args, recipe$model)
  params <- args$parameters %||% list()
  for (nm in intersect(names(free), scalars)) params[nm] <- list(unname(free[[nm]]))
  mapping <- args$map %||% list()
  mapping[parameter] <- list(factor(NA))
  settings <- lapply(internal, function(value) {
    candidate <- args
    candidate$parameters <- params
    candidate$parameters[parameter] <- list(unname(value))
    candidate$map <- mapping
    candidate$ncores <- 1L
    candidate$output <- FALSE
    candidate$silent <- TRUE
    candidate
  })
  names(settings) <- paste0("point_", seq_along(values))
  started <- proc.time()[["elapsed"]]
  results <- .acl_batch_apply(settings, recipe$model, ncores)
  names(results) <- names(settings)
  fits <- lapply(results, `[[`, "fit")
  objective <- vapply(fits, function(x) {
    z <- x$opt$objective
    if (is.numeric(z) && length(z) == 1L && is.finite(z)) z else NA_real_
  }, numeric(1))
  grid <- cbind(data.frame(value = values, internal_value = internal,
    objective = unname(objective), delta_nll = unname(objective - reference)),
    .acl_batch_status(results))
  rownames(grid) <- NULL
  if (any(grid$delta_nll < -1e-6, na.rm = TRUE))
    warning("A profile grid fit has a lower objective than the original fit; recheck the original optimum before interpreting the profile.", call. = FALSE)
  list(parameter = parameter, scale = scale, grid = grid, fits = fits,
    settings = settings, reference_objective = reference,
    reference_numerical_ok = isTRUE(fit$diagnostics$numerical_ok),
    elapsed = unname(proc.time()[["elapsed"]] - started),
    model = recipe$model, workers = .acl_workers(min(ncores, length(settings))))
}
