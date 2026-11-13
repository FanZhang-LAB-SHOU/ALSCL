.acl_map <- function(parameters, map, model) {
  defaults <- .acl_merge_map(map, model, names(parameters))
  for (nm in names(defaults)) {
    value <- defaults[[nm]]
    if (length(value) == 1L && is.na(value)) defaults[[nm]] <- value <- factor(NA)
    if (!is.factor(value)) stop("map entries must be factors (factor(NA) fixes a parameter), or NULL to unfix.", call. = FALSE)
    if (length(value) != length(parameters[[nm]])) stop("Map length does not match parameter ", nm, call. = FALSE)
    defaults[[nm]] <- .acl_drop_map_levels(value)
  }
  defaults
}

# The process densities in the templates are evaluated on the complete arrays
# of deviations, whatever the map. When cells are tied to one value or fixed,
# that density is no longer the density of the remaining free values: it keeps
# factors that depend on the process standard deviation and correlations.
# Estimating those parameters with such a map gives a biased or degenerate fit
# (the standard deviation can run to its lower bound), so it is rejected.
# With the standard deviation and correlations fixed the extra factors are
# constants, and the map is allowed.
.acl_check_random_map <- function(mapping, model, F_structure = "group_year") {
  sd_prefix <- if (model == "ACL") "log_std_log_" else "log_sigma_log_"
  group <- if (model == "ACL") "logit_log_F_a" else "logit_log_F_l"
  scale_names <- list(
    dev_log_R = c(paste0(sd_prefix, "R"), "logit_log_R"),
    dev_log_F = c(paste0(sd_prefix, "F"), "logit_log_F_y", if (F_structure != "year") group),
    dev_log_N0 = paste0(sd_prefix, "N0"))
  fixed <- function(nm) !is.null(mapping[[nm]]) && all(is.na(mapping[[nm]]))
  restricted <- character()
  for (block in names(scale_names)) {
    value <- mapping[[block]]
    if (is.null(value)) next
    codes <- as.integer(value)
    tied <- anyDuplicated(codes[!is.na(codes)]) > 0L
    if (!tied && !anyNA(codes)) next
    restricted <- c(restricted, block)
    free <- scale_names[[block]][!vapply(scale_names[[block]], fixed, logical(1))]
    if (length(free))
      stop("map$", block, if (tied) " ties deviations to shared values" else " fixes deviations",
           " while ", paste(free, collapse = ", "), if (length(free) > 1L) " are" else " is", " estimated. ",
           "The process density is evaluated on the complete array of deviations, so these estimates would be biased ",
           "(the standard deviation can run to its lower bound). ",
           "Fix ", paste(free, collapse = ", "), " with factor(NA) as well, or use separate free deviations. ",
           if (block == "dev_log_F") "For one F deviation per time step shared by all groups, use F_structure = \"year\"." else "",
           call. = FALSE)
  }
  restricted
}

.acl_fit_control <- function(control) {
  .acl_input_list(control, "control")
  # nlminb accepts unambiguous prefixes and maxiter as an alias for iter.max.
  supported <- c("eval.max", "iter.max", "trace", "maxiter", "abs.tol", "rel.tol",
                 "x.tol", "xf.tol", "step.min", "step.max", "sing.tol", "scale.init", "diff.g")
  keys <- supported[pmatch(names(control), supported, duplicates.ok = TRUE)]
  if (anyNA(keys))
    stop("Unknown or ambiguous nlminb control: ", paste(names(control)[is.na(keys)], collapse = ", "), call. = FALSE)
  keys[keys == "maxiter"] <- "iter.max"
  if (anyDuplicated(keys))
    stop("Each nlminb control may be supplied only once, including aliases.", call. = FALSE)
  names(control) <- keys
  for (key in keys) {
    value <- control[[key]]
    if (is.null(value)) next  # Restore the nlminb default for this setting.
    if (!(is.numeric(value) || (key == "trace" && is.logical(value))) ||
        !is.null(dim(value)) || length(value) != 1L || !is.finite(value))
      stop("control$", key, " must be a finite numeric scalar.", call. = FALSE)
    if (key %in% c("eval.max", "iter.max", "trace") &&
        (value != trunc(value) || abs(value) > .Machine$integer.max ||
         (key != "trace" && value < 0)))
      stop("Invalid integer for control$", key, ".", call. = FALSE)
  }
  utils::modifyList(list(iter.max = 2000L, eval.max = 10000L), control)
}
.acl_bounds <- function(par, config) {
  lower <- upper <- par
  for (nm in names(par)) {
    lo <- config$parameters.L[[nm]]; hi <- config$parameters.U[[nm]]
    if (is.null(lo)) lo <- -Inf
    if (is.null(hi)) hi <- Inf
    if (length(lo) != 1L || length(hi) != 1L || is.na(lo) || is.na(hi) || lo >= hi) stop("Invalid bounds for ", nm, call. = FALSE)
    lower[nm] <- lo; upper[nm] <- hi
  }
  if (any(!is.finite(par))) stop("Initial free parameters must be finite.", call. = FALSE)
  list(lower = lower, upper = upper, start = pmax(lower, pmin(upper, par)))
}
.acl_optimize <- function(obj, start, lower, upper, train_times, control) {
  history <- vector("list", train_times)
  best <- NULL; selected <- NA_integer_
  for (i in seq_len(train_times)) {
    candidate <- tryCatch(stats::nlminb(start, obj$fn, obj$gr,
      lower = lower, upper = upper, control = control),
      error = function(e) list(par = start, objective = Inf,
        convergence = 1L, message = conditionMessage(e)))
    history[[i]] <- candidate
    if (is.finite(candidate$objective)) {
      # Restarts can differ by numerical roundoff without leaving the same
      # solution. Prefer an actual successful pass only when both its objective
      # and every parameter agree within these tolerances. Otherwise, including
      # when both passes have the same success status, retain the lower value.
      equivalent <- !is.null(best) &&
        abs(candidate$objective - best$objective) <= 1e-8 &&
        length(candidate$par) == length(best$par) &&
        identical(names(candidate$par), names(best$par)) &&
        all(is.finite(candidate$par)) && all(is.finite(best$par)) &&
        all(abs(candidate$par - best$par) <=
              1e-6 * pmax(1, abs(candidate$par), abs(best$par)))
      candidate_ok <- isTRUE(candidate$convergence == 0L)
      best_ok <- !is.null(best) && isTRUE(best$convergence == 0L)
      prefer <- if (equivalent && candidate_ok != best_ok) candidate_ok else
        is.null(best) || candidate$objective < best$objective
      if (prefer) {
        best <- candidate; selected <- i
      }
      start <- candidate$par
    }
  }
  if (is.null(best)) best <- history[[1L]]
  best$optimizer_history <- history
  best$selected_pass <- selected
  best
}

# Return a TMB object to the state of a newly built one, so that a start run
# on a reused object follows exactly the path it would follow on a new object.
.acl_reset_obj <- function(obj) {
  env <- obj$env
  env$last.par <- env$last.par1 <- env$last.par2 <- env$last.par.best <- env$par
  env$value.best <- Inf
  invisible(obj)
}

.acl_start_spread <- function(start_spread) {
  if (!is.numeric(start_spread) || length(start_spread) != 1L || !is.finite(start_spread) || start_spread <= 0)
    stop("start_spread must be one positive number.", call. = FALSE)
  start_spread
}

.acl_fit_start <- function(i, data, params, mapping, random, dll, bounds,
                           train_times, control, obj = NULL, start_spread = .15) {
  started_at <- as.numeric(Sys.time())
  clock <- proc.time()
  # Identical starting points regardless of worker count, without changing the
  # caller's random-number stream during sequential multistart fits.
  if (i > 1L) {
    restore_rng <- .acl_preserve_rng()
    on.exit(restore_rng(), add = TRUE)
  }
  start <- bounds$start
  if (i > 1L) {
    set.seed(137L * i, kind = "Mersenne-Twister", normal.kind = "Inversion")
    start <- start + stats::rnorm(length(start), 0, start_spread)
  }
  start <- pmax(bounds$lower, pmin(bounds$upper, start))
  opt <- tryCatch({
    if (is.null(obj)) obj <- TMB::MakeADFun(data, params, random = random,
      map = mapping, DLL = dll, inner.control = list(trace = FALSE, maxit = 500), silent = TRUE)
    else .acl_reset_obj(obj)
    .acl_optimize(obj, start, bounds$lower, bounds$upper, train_times, control)
  }, error = function(e) list(objective = Inf, message = conditionMessage(e), convergence = 1L))
  elapsed <- proc.time() - clock
  opt$start_id <- i
  opt$initial <- start
  opt$pid <- Sys.getpid()
  opt$started_at <- started_at
  opt$finished_at <- as.numeric(Sys.time())
  opt$elapsed <- unname(elapsed[["elapsed"]])
  opt$cpu_seconds <- unname(sum(elapsed[c("user.self", "sys.self")]))
  opt
}
# Build the exact data, starts, bounds and maps used by both preflight and fitting.
# This stage never compiles a template or creates a live TMB objective.
.acl_model_setup <- function(model, prepared, parameters = NULL,
                             parameters.L = NULL, parameters.U = NULL, map = NULL,
                             F_structure = c("group_year", "year")) {
  F_structure <- match.arg(F_structure)
  config <- create_parameters(model_type = tolower(model), parameters = parameters,
                              parameters.L = parameters.L, parameters.U = parameters.U)
  p <- config$parameters; d <- prepared$data
  structure <- .acl_structure(prepared$structure, model)
  d[names(structure$data)] <- structure$data
  # ALSCL: t0 = t0_lower + exp(log_t0). Zero is the published positive t0.
  t0_lower <- if (is.null(prepared$t0_lower)) 0 else prepared$t0_lower
  if (!is.numeric(t0_lower) || length(t0_lower) != 1L || !is.finite(t0_lower) || t0_lower >= min(d$age))
    stop("t0_lower must be one finite number below the recruitment age.", call. = FALSE)
  if (model == "ACL" && t0_lower != 0)
    stop("t0_lower applies to ALSCL only; the ACL parameter t0 is on the natural scale and can be negative.", call. = FALSE)
  if (t0_lower != 0) d$t0_lower <- t0_lower
  # Default correlation starts keep their natural value under either range.
  if (identical(structure$choices$correlation_range, "symmetric"))
    for (nm in grep("^logit_", names(p), value = TRUE))
      if (is.null(parameters[[nm]])) p[[nm]] <- stats::qlogis((stats::plogis(p[[nm]]) + 1) / 2)
  max_len <- max(prepared$bins$mid)
  if (model == "ALSCL") {
    d$len_mid <- prepared$bins$mid; d$len_lower <- prepared$bins$lower
    d$len_upper <- prepared$bins$upper; d$growth_step <- prepared$growth_step
    if (is.null(parameters$log_Linf)) p$log_Linf <- log(1.1 * max_len)
    if (is.null(parameters.L$log_Linf)) config$parameters.L$log_Linf <- log(.7 * max_len)
    if (is.null(parameters.U$log_Linf)) config$parameters.U$log_Linf <- log(2 * max_len)
  } else if (exp(config$parameters.U$log_Linf) < 1.2 * max_len ||
             exp(p$log_Linf) < .7 * max_len || exp(p$log_Linf) > 2 * max_len) {
    # The ACL defaults (start 60, bounds 10 to 100 length units) suit the
    # yellowtail flounder example. When they do not suit the length bins of
    # the data, use the data-based rule of ALSCL for the values the user did
    # not supply.
    if (is.null(parameters$log_Linf)) p$log_Linf <- log(1.1 * max_len)
    if (is.null(parameters.L$log_Linf)) config$parameters.L$log_Linf <- log(.7 * max_len)
    if (is.null(parameters.U$log_Linf)) config$parameters.U$log_Linf <- log(2 * max_len)
  }
  if (is.null(parameters$mean_log_R)) {
    totals <- colSums(prepared$observations, na.rm = TRUE)
    p$mean_log_R <- log(mean(totals[totals > 0]))
  }
  if (is.null(parameters$log_init_Z)) {
    p$log_init_Z <- log(d$M + .3)
    # Keep the default start inside the default upper bound for large M.
    if (is.null(parameters.U$log_init_Z) && p$log_init_Z >= config$parameters.U$log_init_Z)
      config$parameters.U$log_init_Z <- log(2 * (d$M + .3))
  }
  # Length-at-age standard deviations must stay positive during optimization.
  t0_name <- if (model == "ACL") "t0" else "log_t0"
  t0_upper <- if (model == "ACL") min(d$age)*(1-1e-6) else if (t0_lower == 0) log(min(d$age)*(1-1e-6)) else
    log(min(d$age) - t0_lower) + log1p(-1e-6)
  config$parameters.U[[t0_name]] <- min(config$parameters.U[[t0_name]], t0_upper)
  if ((if (model == "ACL") p$t0 else t0_lower + exp(p$log_t0)) >= min(d$age)) stop("t0 must be below the recruitment age.", call. = FALSE)
  p$dev_log_R <- rep(0, d$Y)
  p$dev_log_F <- array(0, c(if (F_structure == "year") 1L else if (model == "ACL") d$A else d$L, d$Y))
  p$dev_log_N0 <- rep(0, d$A-1L)
  mapping <- .acl_map(p, map, model)
  if (F_structure == "year") {
    group_parameter <- if (model == "ACL") "logit_log_F_a" else "logit_log_F_l"
    mapping[[group_parameter]] <- factor(NA)
  }
  restricted_random <- .acl_check_random_map(mapping, model, F_structure)
  random <- c("dev_log_R", "dev_log_F", "dev_log_N0")
  # Clamp all starting values to the valid named bounds before building the tape,
  # and record every start that was moved.
  clamped <- NULL
  for (nm in names(config$parameters)) {
    if (is.null(mapping[[nm]]) || any(!is.na(mapping[[nm]]))) {
      inside <- max(config$parameters.L[[nm]], min(config$parameters.U[[nm]], p[[nm]]))
      if (!isTRUE(inside == p[[nm]]))
        clamped <- rbind(clamped, data.frame(parameter = nm, start = p[[nm]], used = inside,
          lower = config$parameters.L[[nm]], upper = config$parameters.U[[nm]],
          supplied = !is.null(parameters[[nm]])))
      p[[nm]] <- inside
    }
  }
  list(data = d, parameters = p, config = config, map = mapping,
       random = random, F_structure = F_structure, structure = structure$choices,
       clamped_starts = clamped, restricted_random = restricted_random, t0_lower = t0_lower)
}

# Tell the user about starting values that were moved into the bounds. A start
# the user supplied gives a warning; a default start gives a message.
.acl_report_clamped <- function(clamped, silent = FALSE) {
  if (is.null(clamped) || !nrow(clamped)) return(invisible(NULL))
  describe <- function(x) paste(sprintf("%s (%.6g moved to %.6g; bounds %.6g to %.6g)",
    x$parameter, x$start, x$used, x$lower, x$upper), collapse = "; ")
  user <- clamped[clamped$supplied, , drop = FALSE]
  if (nrow(user))
    warning("Supplied starting values outside their bounds were moved to the nearest bound: ",
            describe(user), ". Supply parameters.L and parameters.U that contain the start.", call. = FALSE)
  other <- clamped[!clamped$supplied, , drop = FALSE]
  if (nrow(other) && !silent)
    message("Default starting values outside the bounds were moved to the nearest bound: ", describe(other), ".")
  invisible(NULL)
}

# Compare the objectives of the starts that converged. Different values mean
# that the likelihood has several local optima for these data.
.acl_start_summary <- function(starts) {
  objective <- vapply(starts, function(x) if (is.finite(x$objective)) x$objective else NA_real_, numeric(1))
  converged <- vapply(starts, function(x) isTRUE(x$convergence == 0L), logical(1)) & is.finite(objective)
  best <- suppressWarnings(min(objective, na.rm = TRUE))
  usable <- objective[converged]
  list(nstarts = length(starts), converged = sum(converged), best_objective = best,
       objective_range = if (length(usable) > 1L) diff(range(usable)) else NA_real_,
       agree_with_best = sum(converged & objective - best <= 1e-3))
}

.acl_check_fit_flags <- function(polish, silent, output) {
  flags <- list(polish = polish, silent = silent, output = output)
  for (nm in names(flags)) {
    value <- flags[[nm]]
    if (!is.logical(value) || length(value) != 1L || is.na(value))
      stop(nm, " must be TRUE or FALSE.", call. = FALSE)
  }
  invisible(TRUE)
}

.acl_fit <- function(model, prepared, parameters, parameters.L, parameters.U, map,
                     train_times, ncores, silent, output, control, nstarts = ncores,
                     F_structure = c("group_year", "year"), polish = TRUE) {
  F_structure <- match.arg(F_structure)
  start_spread <- .acl_start_spread(if (is.null(prepared$start_spread)) .15 else prepared$start_spread)
  .acl_check_fit_flags(polish, silent, output)
  .acl_check_speed_options()
  control <- .acl_fit_control(control)
  train_times <- .acl_positive_integer(train_times, "train_times")
  ncores <- .acl_positive_integer(ncores, "ncores")
  nstarts <- .acl_positive_integer(nstarts, "nstarts")
  workers <- .acl_workers(min(ncores, nstarts))
  started <- proc.time()[["elapsed"]]
  setup <- .acl_model_setup(model, prepared, parameters, parameters.L,
                            parameters.U, map, F_structure)
  config <- setup$config; p <- setup$parameters; d <- setup$data
  mapping <- setup$map; random <- setup$random
  .acl_report_clamped(setup$clamped_starts, silent)
  if (!silent && length(setup$restricted_random))
    message("The map ties or fixes entries of ", paste(setup$restricted_random, collapse = ", "),
            ". The objective keeps the density of the complete array, so it (and AIC) cannot be compared ",
            "with fits that use a different map for these deviations.")
  if (!silent && isTRUE(prepared$zero_observations > 0))
    message(prepared$zero_observations, " zero survey observation(s) are treated as missing (zero_action = \"missing\"). ",
            "Length bins with many zeros are then informed only by their positive values.")
  if (silent) {
    invisible(utils::capture.output(info <- .acl_compile(model)))
  } else info <- .acl_compile(model)
  make_obj <- function() TMB::MakeADFun(d, p, random = random, map = mapping,
    DLL = info$dll_name, inner.control = list(trace = FALSE, maxit = 500), silent = TRUE)
  obj <- make_obj(); bounds <- .acl_bounds(obj$par, config)
  if (!length(obj$par)) stop("At least one fixed-effect parameter must remain free.", call. = FALSE)
  if (!silent) message("Fitting ", model, " with ", nstarts, " start(s) on ", workers, " worker(s).")
  if (workers == 1L) {
    # One TMB object serves every sequential start; it is reset before each.
    starts <- lapply(seq_len(nstarts), function(i) .acl_fit_start(i, d, p,
      mapping, random, info$dll_name, bounds, train_times, control,
      obj = obj, start_spread = start_spread))
    if (nstarts > 1L) .acl_reset_obj(obj)
  } else {
    cl <- parallel::makeCluster(workers)
    on.exit(if (!is.null(cl)) parallel::stopCluster(cl), add = TRUE)
    .acl_initialize_workers(cl, dll_path = info$dll_path)
    starts <- parallel::parLapply(cl, seq_len(nstarts), .acl_fit_start,
       data = d, params = p, mapping = mapping, random = random, dll = info$dll_name,
       bounds = bounds, train_times = train_times, control = control,
       start_spread = start_spread)
    parallel::stopCluster(cl)
    cl <- NULL
  }
  values <- vapply(starts, function(x) if (is.finite(x$objective)) x$objective else Inf, numeric(1))
  if (all(!is.finite(values))) stop("All optimization starts failed: ", paste(vapply(starts, `[[`, character(1), "message"), collapse = "; "), call. = FALSE)
  opt <- starts[[which.min(values)]]
  start_diagnostics <- do.call(rbind, lapply(starts, function(s) data.frame(
    start_id = s$start_id, pid = s$pid, started_at = s$started_at, finished_at = s$finished_at,
    elapsed = s$elapsed, cpu_seconds = s$cpu_seconds, objective = s$objective,
    convergence = s$convergence)))
  raw_opt <- opt
  refined <- .acl_polish(obj, opt$par, bounds$lower, bounds$upper, enabled = polish)
  opt$par <- refined$par
  # Re-evaluate in this process to synchronize random effects, reports and gradients.
  opt$objective <- obj$fn(opt$par)
  gradient <- as.numeric(obj$gr(opt$par)); names(gradient) <- names(opt$par)
  report <- obj$report()
  if (F_structure == "year")
    report[[if (model == "ACL") "phi_log_F_a" else "phi_log_F_l"]] <- NULL
  sdresult <- tryCatch(.acl_sdreport(obj, opt$par),
    error = function(e) {warning("Standard errors unavailable: ", conditionMessage(e)); NULL})
  # Numerical Hessian evaluations can leave the live TMB object at a perturbed
  # parameter, including after a failed standard-error calculation. Restore the
  # fitted joint mode before returning it for downstream report/evaluation use.
  # Keep this outside the uncertainty handler: failure to restore the fitted
  # objective must not be mistaken for merely unavailable standard errors.
  restored_objective <- obj$fn(opt$par)
  if (!is.finite(restored_objective))
    stop("Could not restore the fitted TMB objective after standard-error calculation.",
         call. = FALSE)
  sd_info <- if (is.null(sdresult)) NULL else attr(sdresult, "acl_sd_info")
  if (!silent && !is.null(sd_info)) message(.acl_sd_message(sd_info))
  est_std <- if (is.null(sdresult)) NULL else summary(sdresult)
  covariance <- if (is.null(sdresult)) NULL else sdresult$cov.fixed
  if (!is.null(covariance)) dimnames(covariance) <- list(names(opt$par), names(opt$par))
  distances <- c(opt$par - bounds$lower, bounds$upper - opt$par)
  mgc <- max(abs(gradient))
  result <- list(obj = obj, opt = opt, report = report, est_std = est_std,
    vcov = covariance, pdHess = if (is.null(sdresult)) NA else isTRUE(sdresult$pdHess),
    sd_info = sd_info, gradient = gradient, max_abs_gradient = mgc, final_outer_mgc = mgc,
    bound_hit = any(distances <= 1e-7), bound_check = distances,
    converge = opt$message, convergence_code = opt$convergence,
    par_low_up = cbind(estimate = opt$par, lower = bounds$lower, upper = bounds$upper),
    model_type = model, year = prepared$year, age = d$age,
    len_mid = prepared$bins$mid, len_label = prepared$bins$labels,
    len_border = prepared$bins$border, len_lower = prepared$bins$lower, len_upper = prepared$bins$upper,
    growth_step = prepared$growth_step, elapsed = proc.time()[["elapsed"]]-started,
    starts = starts, start_diagnostics = start_diagnostics,
    nstarts = nstarts, workers = workers, observations = prepared$observations,
    F_structure = F_structure, optimizer_history = raw_opt$optimizer_history,
    raw_opt = raw_opt, refinement = refined[setdiff(names(refined), "par")],
    structure = setup$structure, t0_lower = setup$t0_lower, start_summary = .acl_start_summary(starts),
    start_spread = start_spread, clamped_starts = setup$clamped_starts,
    zero_observations = prepared$zero_observations,
    restricted_random = setup$restricted_random)
  result$diagnostics <- .acl_fit_diagnostics(result)
  if (isTRUE(result$start_summary$objective_range > 2))
    result$diagnostics$issues <- c(result$diagnostics$issues, sprintf(
      "starts converged to different optima (objective range %.3g over %d converged starts; the lowest is reported)",
      result$start_summary$objective_range, result$start_summary$converged))
  if (!silent && length(result$diagnostics$issues))
    message("Fit diagnostics: ", paste(result$diagnostics$issues, collapse = "; "))
  if (output) .acl_save_output(result, prepared$data.CatL)
  result
}
.acl_save_output <- function(result, data.CatL) {
  dir.create("output/figures/result", recursive = TRUE, showWarnings = FALSE)
  dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
  plots <- list(recruitment = function() plot_recruitment(result), SSB = function() plot_SSB(result),
                biomass = function() plot_biomass(result), abundance = function() plot_abundance(result),
                catch = function() plot_catch(result), CatL = function() plot_CatL(result),
                fishing_mortality = function() plot_fishing_mortality(result),
                residuals = function() plot_residuals(result), VB = function() plot_VB(result))
  for (nm in names(plots)) tryCatch({
    ggplot2::ggsave(file.path("output/figures/result", paste0("plot_", nm, ".png")),
                   plot = plots[[nm]](), width = 12, height = 7, dpi = 300)
  }, error = function(e) warning("Could not save ", nm, ": ", conditionMessage(e)))
  utils::write.csv(diagnose_model(data.CatL, result), "output/tables/diagnostics.csv", row.names = FALSE)
  invisible(NULL)
}
