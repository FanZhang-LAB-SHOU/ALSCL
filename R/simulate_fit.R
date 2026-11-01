# Draw the separable stationary Gaussian field used by the fitted TMB models.
# The scale is a marginal SD, not the SD of innovations in either direction.
.acl_simulate_ar1_field <- function(nrow, ntime, phi_group, phi_time, sd) {
  if (any(!is.finite(c(phi_group, phi_time, sd))) ||
      abs(phi_group) >= 1 || abs(phi_time) >= 1 || sd <= 0)
    stop("Process correlations must be strictly between -1 and 1, and marginal SDs must be positive and finite.",
      call. = FALSE)
  z <- matrix(stats::rnorm(nrow * ntime), nrow, ntime)
  if (nrow > 1L) for (g in seq.int(2L, nrow))
    z[g, ] <- phi_group * z[g - 1L, ] + sqrt(1 - phi_group^2) * z[g, ]
  if (ntime > 1L) for (t in seq.int(2L, ntime))
    z[, t] <- phi_time * z[, t - 1L] + sqrt(1 - phi_time^2) * z[, t]
  sd * z
}

.acl_fit_simulation_setup <- function(fit, process) {
  if (!is.list(fit) || !is.list(fit$report))
    stop("fit must contain a fitted population report and a complete recipe.", call. = FALSE)
  recipe <- .acl_recipe(fit)
  model <- toupper(recipe$model)
  if (!identical(fit$model_type, model))
    stop("fit$model_type must match the saved recipe.", call. = FALSE)
  preflight <- .acl_preflight(recipe$args, recipe$model)
  setup <- preflight$setup
  .acl_validate_survey_fit(fit, .acl_survey_data(recipe$args$data.CatL))
  if (!isTRUE(all.equal(as.numeric(fit$age), as.numeric(setup$data$age))) ||
      !isTRUE(all.equal(as.numeric(fit$len_mid), as.numeric(preflight$prepared$bins$mid))))
    stop("Fitted age and length coordinates must match the saved recipe.", call. = FALSE)
  estimated <- extract_parameters(fit, scale = "internal")
  scalar_names <- names(setup$config$parameters)
  if (!all(scalar_names %in% estimated$parameter))
    stop("The fit must retain all scalar parameter estimates and fixed values.", call. = FALSE)
  parameters <- setup$parameters
  scalars <- stats::setNames(as.list(estimated$estimate[match(scalar_names, estimated$parameter)]), scalar_names)
  if (any(!is.finite(unlist(scalars))))
    stop("Fitted scalar parameters must be finite.", call. = FALSE)
  parameters[scalar_names] <- scalars
  if (process == "resample") {
    restricted <- setup$random[vapply(setup$random, function(nm) {
      mapping <- setup$map[[nm]]
      !is.null(mapping) && (anyNA(mapping) || anyDuplicated(mapping) > 0L)
    }, logical(1))]
    if (length(restricted))
      stop("process = 'resample' does not support fixed or tied random-effect maps: ",
        paste(restricted, collapse = ", "), ". Use process = 'conditional' or fit unrestricted random effects.",
        call. = FALSE)
  }
  list(recipe = recipe, model = model, preflight = preflight,
    parameters = parameters, scalar_parameters = scalars)
}

.acl_simulation_truth <- function(report, parameters, random_effects, model, sigma, year) {
  f_name <- if (model == "ACL") "F" else "FL"
  required <- c("SSB", "Rec", "NL", "Elog_index", f_name)
  if (any(!vapply(required, function(nm) is.numeric(report[[nm]]) &&
      length(report[[nm]]) > 0L && all(is.finite(report[[nm]])), logical(1))))
    stop("Population reports must contain finite SSB, recruitment, abundance, F and expected log indices.",
      call. = FALSE)
  expected <- exp(report$Elog_index + sigma^2 / 2)
  if (any(!is.finite(expected) | expected <= 0))
    stop("The lognormal expected index overflows or underflows the numeric range; simulation is not truncated or floored.",
      call. = FALSE)
  quantities <- intersect(c("N", "B", "SSB", "Rec", "CN", "CB", "NL", "NA", "NLA"), names(report))
  truth <- report[quantities]
  truth$year <- year
  truth$F <- report[[f_name]]
  truth$F_group <- if (model == "ACL") "age" else "length"
  truth$Elog_index <- report$Elog_index
  truth$expected_index <- expected
  truth$observation_sd <- sigma
  truth$parameters <- parameters
  truth$random_effects <- random_effects
  truth
}

#' Simulate survey datasets from a fitted ACL or ALSCL model
#'
#' Generate observations under the fitted lognormal observation model, either
#' conditional on the fitted population or after drawing new process deviations.
#' This uses the fitted model's recruitment and fishing-mortality processes;
#' it does not use the stock-recruitment relationship in [sim_data()].
#' @param fit A fitted ACL or ALSCL result with its report and complete recipe.
#'   A saved assessment without a live TMB object is supported.
#' @param nsim Positive integer number of simulated datasets.
#' @param seed Optional nonnegative integer seed. An explicit seed uses the
#'   Mersenne-Twister generator and Inversion normal sampler, then restores the
#'   caller's RNG kind and random-number state. NULL consumes the current stream.
#' @param process "conditional" retains the fitted population and adds only
#'   observation error. "resample" draws new recruitment, fishing-mortality and
#'   initial-population deviations at the fitted scalar parameter values.
#' @param preserve_missing Logical. If TRUE, original NA observations remain NA
#'   and excluded zeros remain zero. If FALSE, all cells receive positive draws.
#' @param allow_failed_fit Logical; default FALSE. Reject a fit known to have
#'   failed its numerical screen unless explicitly overridden. An override
#'   produces a warning; missing numerical diagnostics are recorded as unknown.
#' @details Both modes hold scalar parameters, biology and survey catchability
#'   fixed. Neither includes parameter-estimation uncertainty. In resample mode,
#'   recruitment follows a stationary AR(1), fishing mortality follows the
#'   fitted stationary separable group-by-time AR(1) (or one time series for
#'   F_structure = "year"), and initial-age deviations are independent normal
#'   draws. The process scales are marginal SDs; AR(1) innovation SDs are the
#'   marginal SD multiplied by sqrt(1 - phi^2). Recruitment and F use
#'   exp(mean_log + deviation), without a lognormal mean correction.
#'
#'   Resampling evaluates the package's C++ population model without optimization.
#'   Fixed or tied random-effect maps are rejected in this mode because their
#'   conditional process distribution is not implemented; ordinary scalar maps
#'   remain supported. Conditional simulation supports either map type.
#'   Observations are exp(Elog_index + normal error), so exp(Elog_index) is their
#'   conditional median, and expected_index = exp(Elog_index + sigma^2 / 2)
#'   is their conditional arithmetic mean. Numeric overflow or underflow to zero
#'   raises an error rather than changing the generating distribution or mask.
#'
#'   Each returned x retains the fitting configuration of the same model,
#'   except the session settings output, ncores and silent, which are chosen
#'   when the bundle is fitted. It can be passed to run_acl(x) or run_alscl(x),
#'   as appropriate, to conduct simulation-estimation experiments. This
#'   function does not refit models or compute bootstrap intervals. Passing a
#'   numerical screen does not establish model adequacy or parameter
#'   identifiability.
#' @return A list with simulations and metadata. Each simulations element has
#'   replicate, x (a complete input bundle), observations (length by time) and
#'   truth (population quantities including year, SSB, Rec, NL and group-specific
#'   F; expected log and arithmetic-mean indices; scalar parameters and random
#'   effects). Conditional truth retains available fitted deviations; an older
#'   report may omit dev_log_N0, which is then NULL. Resampled truth retains all
#'   three generated deviation arrays. Metadata records the model, process,
#'   seed, RNG kind, coordinates, original observation mask, source fit status and the
#'   explicit parameter_uncertainty = "none" assumption.
#' @examples
#' \dontrun{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' simulated <- simulate_fit(fit, nsim = 3, seed = 42, process = "resample")
#' refit <- run_acl(simulated$simulations[[1]]$x, silent = TRUE)
#' simulated$simulations[[1]]$truth$SSB
#' }
#' @export
simulate_fit <- function(fit, nsim = 1, seed = NULL,
                         process = c("conditional", "resample"),
                         preserve_missing = TRUE, allow_failed_fit = FALSE) {
  nsim <- .acl_positive_integer(nsim, "nsim")
  if (!is.null(seed)) seed <- .acl_positive_integer(seed, "seed", minimum = 0L)
  process <- match.arg(process)
  for (name in c("preserve_missing", "allow_failed_fit")) {
    value <- get(name)
    if (!is.logical(value) || length(value) != 1L || is.na(value))
      stop(name, " must be TRUE or FALSE.", call. = FALSE)
  }
  setup <- .acl_fit_simulation_setup(fit, process)
  failed <- isFALSE(fit$diagnostics$numerical_ok)
  if (failed) {
    if (!allow_failed_fit)
      stop("The source fit failed the numerical screen. Review fit$diagnostics; ",
        "set allow_failed_fit = TRUE only for exploratory simulation.", call. = FALSE)
    warning("The source fit failed the numerical screen; this exploratory simulation uses that failed fit ",
      "because allow_failed_fit = TRUE.", call. = FALSE)
  }
  parameters <- setup$parameters
  model <- setup$model
  sigma <- exp(parameters[[if (model == "ACL") "log_std_index" else "log_sigma_index"]])
  if (!is.finite(sigma) || sigma <= 0)
    stop("The observation SD must be positive and finite.", call. = FALSE)
  original <- setup$preflight$prepared$observations
  d <- setup$preflight$setup$data
  if (!is.matrix(fit$report$Elog_index) || !identical(dim(fit$report$Elog_index), dim(original)))
    stop("Expected log indices must match the saved observation dimensions.", call. = FALSE)
  if (process == "resample") {
    .acl_check_implementation(setup$recipe)
    info <- .acl_compile(model)
    evaluator <- TMB::MakeADFun(d, parameters, random = NULL, map = NULL,
      DLL = info$dll_name, silent = TRUE)
    parameter_order <- names(evaluator$env$parList(evaluator$par))
    scale_prefix <- if (model == "ACL") "log_std_" else "log_sigma_"
    scales <- exp(unlist(parameters[paste0(scale_prefix, c("log_R", "log_F", "log_N0"))]))
    if (any(!is.finite(scales) | scales <= 0))
      stop("Process marginal SDs must be positive and finite.", call. = FALSE)
    phi_r <- stats::plogis(parameters$logit_log_R)
    phi_t <- stats::plogis(parameters$logit_log_F_y)
    phi_g <- if (nrow(parameters$dev_log_F) == 1L) 0 else
      stats::plogis(parameters[[if (model == "ACL") "logit_log_F_a" else "logit_log_F_l"]])
  }
  if (!is.null(seed)) {
    restore_rng <- .acl_preserve_rng()
    on.exit(restore_rng(), add = TRUE)
    set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
  }
  rng_kind <- RNGkind()
  random_names <- c("dev_log_R", "dev_log_F", "dev_log_N0")
  table_names <- c("data.CatL", "data.wgt", "data.mat")
  simulations <- lapply(seq_len(nsim), function(i) {
    report <- fit$report
    random_effects <- stats::setNames(lapply(random_names, function(nm) report[[nm]]), random_names)
    if (process == "resample") {
      parameters$dev_log_R <- as.numeric(.acl_simulate_ar1_field(1L, d$Y, 0, phi_r, scales[1L]))
      parameters$dev_log_F <- .acl_simulate_ar1_field(nrow(parameters$dev_log_F), d$Y,
        phi_g, phi_t, scales[2L])
      parameters$dev_log_N0 <- stats::rnorm(d$A - 1L, 0, scales[3L])
      report <- evaluator$report(unlist(parameters[parameter_order], use.names = FALSE))
      random_effects <- parameters[random_names]
    }
    truth <- .acl_simulation_truth(report, setup$scalar_parameters,
      random_effects, model, sigma, fit$year)
    observations <- exp(report$Elog_index + matrix(stats::rnorm(d$L * d$Y, 0, sigma), d$L, d$Y))
    if (any(!is.finite(observations) | observations <= 0))
      stop("A simulated observation overflows or underflows to zero; simulation is not truncated or floored.",
        call. = FALSE)
    if (preserve_missing) {
      observations[is.na(original)] <- NA_real_
      observations[!is.na(original) & original == 0] <- 0
    }
    dimnames(observations) <- dimnames(original)
    tables <- setup$recipe$args[table_names]
    tables$data.CatL <- as.data.frame(tables$data.CatL, stringsAsFactors = FALSE, check.names = FALSE)
    tables$data.CatL[-1L] <- as.data.frame(observations, check.names = FALSE)
    # Session settings are not part of the model: output, ncores and silent
    # are chosen when the simulated bundle is fitted.
    kept <- setdiff(names(setup$recipe$args), c(table_names, "output", "ncores", "silent"))
    tables$fit_config <- stats::setNames(list(setup$recipe$args[kept]), setup$recipe$model)
    list(replicate = i, x = tables, observations = observations, truth = truth)
  })
  names(simulations) <- paste0("sim_", seq_len(nsim))
  list(simulations = simulations, metadata = list(model = model, nsim = nsim,
    process = process, seed = seed, RNGkind = rng_kind, preserve_missing = preserve_missing,
    parameter_uncertainty = "none", F_structure = setup$preflight$setup$F_structure,
    year = fit$year, age = fit$age, len_mid = fit$len_mid, len_label = fit$len_label,
    observation_mask = is.finite(original) & original > 0,
    source_fit_status = if (failed) "failed" else if (isTRUE(fit$diagnostics$numerical_ok)) "passed" else "unknown",
    source_fit_numerical_ok = if (failed) FALSE else if (isTRUE(fit$diagnostics$numerical_ok)) TRUE else NA,
    failed_fit_override = failed && allow_failed_fit,
    source_implementation = setup$recipe$implementation))
}
