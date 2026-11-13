# Reuse the checked Hessian implementation where forked processes are supported.
# Socket workers would rebuild the sparse derivative tape, so remain sequential.
.acl_refinement_hessian <- function(obj, par) {
  cores <- min(.acl_cores(), length(par))
  sequential <- function(note) list(value = stats::optimHess(par, obj$fn, obj$gr),
    method = "sequential", cores = 1L, note = note)
  if (cores <= 1L) return(sequential("one Hessian column or one core"))
  if (!.acl_tmb_supported()) return(sequential("TMB version not checked"))
  if (.acl_sd_backend() != "fork") return(sequential("forked processes not selected"))
  tryCatch(list(value = .acl_optimhess(obj, par, cores),
    method = "forked processes", cores = as.integer(cores), note = ""),
    acl_parallel_error = function(e) {
      warning("Parallel refinement Hessian failed (", conditionMessage(e),
        "); computing it sequentially.", call. = FALSE)
      sequential(paste("parallel calculation failed:", conditionMessage(e)))
    })
}

# Conservative finishing step; the original optimizer result is kept separately.
.acl_polish <- function(obj, par, lower, upper, enabled = TRUE) {
  history <- data.frame(iteration = integer(), objective = numeric(),
    max_gradient = numeric(), step_scale = numeric())
  hessians <- data.frame(iteration = integer(), method = character(),
    cores = integer(), note = character())
  status <- if (enabled) "not_started" else "disabled"
  # A malformed speed option is an input error. Report it as such here: inside
  # the loop below it would be caught with the numerical failures of the
  # Hessian step and reported as "hessian_unusable".
  if (enabled) .acl_check_speed_options()
  hessian_message <- ""
  evaluate <- function(x) tryCatch({
    value <- obj$fn(x); gradient <- as.numeric(obj$gr(x))
    if (length(value) != 1L || !is.finite(value) ||
        length(gradient) != length(x) || any(!is.finite(gradient))) return(NULL)
    list(value = value, gradient = gradient, mgc = max(abs(gradient)))
  }, error = function(e) NULL)
  initial <- evaluate(par); current <- initial
  if (enabled && is.null(current)) status <- "nonfinite_evaluation"
  if (enabled && !is.null(current)) for (i in seq_len(5L)) {
    if (current$mgc < 1e-6) {status <- "gradient_tolerance"; break}
    if (any(par - lower <= 1e-7 | upper - par <= 1e-7)) {
      status <- "parameter_boundary"; break
    }
    step <- tryCatch({
      calculation <- .acl_refinement_hessian(obj, par)
      hessians <- rbind(hessians, data.frame(iteration = i,
        method = calculation$method, cores = calculation$cores,
        note = calculation$note))
      h <- calculation$value
      h <- (h + t(h))/2
      if (any(!is.finite(h))) stop("nonfinite Hessian")
      # chol both checks positive definiteness and avoids an unstable inverse.
      r <- chol(h)
      as.numeric(backsolve(r, forwardsolve(t(r), current$gradient)))
    }, error = function(e) {
      hessian_message <<- conditionMessage(e)
      NULL
    })
    if (is.null(step) || any(!is.finite(step))) {
      status <- "hessian_unusable"; break
    }
    accepted <- FALSE
    for (scale in 2^-(0:15)) {
      trial <- par - scale * step
      if (any(!is.finite(trial)) || any(trial <= lower | trial >= upper)) next
      candidate <- evaluate(trial)
      if (!is.null(candidate) && candidate$value <= current$value + 1e-8 &&
          candidate$mgc < current$mgc) {
        par <- trial; current <- candidate; accepted <- TRUE
        history <- rbind(history, data.frame(iteration = i,
          objective = current$value, max_gradient = current$mgc, step_scale = scale))
        break
      }
    }
    if (!accepted) {status <- "no_acceptable_step"; break}
    status <- if (current$mgc < 1e-6) "gradient_tolerance" else "iteration_limit"
  }
  # Restore the objective's random-effect mode after Hessian/trial evaluations.
  final <- evaluate(par)
  list(par = par, enabled = enabled, status = status, steps = nrow(history),
    initial_objective = if (is.null(initial)) NA_real_ else initial$value,
    final_objective = if (is.null(final)) NA_real_ else final$value,
    initial_max_gradient = if (is.null(initial)) NA_real_ else initial$mgc,
    final_max_gradient = if (is.null(final)) NA_real_ else final$mgc,
    history = history, hessian_calculations = hessians,
    hessian_message = hessian_message)
}

.acl_fit_diagnostics <- function(fit) {
  par <- fit$opt$par
  rho <- grepl("^logit_", names(par))
  sd <- grepl("^log_(std|sigma)", names(par))
  natural <- data.frame(parameter = names(par)[rho | sd],
    estimate = c(par)[rho | sd], scale = ifelse(rho[rho | sd], "correlation", "SD"),
    near_boundary = rep(FALSE, sum(rho | sd)), row.names = NULL)
  if (nrow(natural)) {
    irho <- natural$scale == "correlation"
    natural$estimate[irho] <- stats::plogis(natural$estimate[irho])
    natural$estimate[!irho] <- exp(natural$estimate[!irho])
    natural$near_boundary <- ifelse(irho,
      natural$estimate <= 1e-4 | natural$estimate >= 1 - 1e-4,
      natural$estimate <= 1e-4)
  }
  correlations <- data.frame(parameter1 = character(), parameter2 = character(), correlation = numeric())
  cov <- fit$vcov; condition <- NA_real_; covariance_ok <- FALSE
  sd_near_zero <- character()
  if (is.matrix(cov) && nrow(cov) == length(par) && all(is.finite(cov)) && all(diag(cov) > 0)) {
    # An SD whose likelihood is flat toward zero stops wherever the optimizer
    # tolerance leaves it, just above or below the natural-boundary threshold.
    # Report an SD estimate within a factor of ten of that threshold when one
    # standard error on the log scale reaches the threshold.
    if (nrow(natural)) {
      log_se <- sqrt(diag(cov))[rho | sd]
      sd_near_zero <- natural$parameter[natural$scale == "SD" & !natural$near_boundary &
        natural$estimate <= 1e-3 & natural$estimate * exp(-log_se) <= 1e-4]
    }
    eig <- eigen((cov + t(cov))/2, symmetric = TRUE, only.values = TRUE)$values
    covariance_ok <- all(eig > 0)
    if (covariance_ok) condition <- max(eig)/min(eig)
    cor <- stats::cov2cor(cov)
    pairs <- which(upper.tri(cor) & abs(cor) >= .95, arr.ind = TRUE)
    if (nrow(pairs)) correlations <- data.frame(parameter1 = names(par)[pairs[,1]],
      parameter2 = names(par)[pairs[,2]], correlation = cor[pairs])
  }
  issues <- character()
  if (!isTRUE(fit$convergence_code == 0L)) issues <- c(issues, "nonzero raw optimizer code")
  stationary <- is.finite(fit$max_abs_gradient) && fit$max_abs_gradient < 1e-3
  if (!stationary) issues <- c(issues, "large or nonfinite gradient")
  if (!isTRUE(fit$pdHess) || !covariance_ok) issues <- c(issues, "Hessian or covariance unavailable or not positive definite")
  if (isTRUE(fit$bound_hit)) issues <- c(issues, "optimizer-scale boundary")
  if (any(natural$near_boundary)) issues <- c(issues, "natural-scale boundary")
  if (nrow(correlations)) issues <- c(issues, "strong parameter correlation (review identifiability)")
  if (length(sd_near_zero)) issues <- c(issues, paste0(
    "SD estimate close to zero with a flat likelihood (", paste(sd_near_zero, collapse = ", "), ")"))
  # Refinement that stopped early leaves estimates that depend on where the
  # optimizer stopped. The 1e-6 tolerance is that of .acl_polish().
  refinement_status <- fit$refinement$status
  refinement_unfinished <- isTRUE(fit$refinement$enabled) &&
    is.character(refinement_status) && length(refinement_status) == 1L &&
    refinement_status %in% c("iteration_limit", "no_acceptable_step", "hessian_unusable",
                             "nonfinite_evaluation") &&
    !(is.finite(fit$max_abs_gradient) && fit$max_abs_gradient < 1e-6)
  if (refinement_unfinished) issues <- c(issues, paste0(
    "optimizer refinement stopped before its gradient tolerance (", refinement_status, ")"))
  # This numerical screen is not a claim of model adequacy or identifiability.
  list(stationary = stationary, numerical_ok = stationary && isTRUE(fit$pdHess) &&
      covariance_ok && !isTRUE(fit$bound_hit) && !any(natural$near_boundary),
    natural_parameters = natural, natural_boundary = any(natural$near_boundary),
    covariance_condition = condition, high_correlations = correlations, issues = issues,
    sd_near_zero = sd_near_zero, refinement_unfinished = refinement_unfinished,
    thresholds = list(gradient = 1e-3, natural_boundary = 1e-4, correlation = .95,
                      sd_near_zero = 1e-3, refinement_gradient = 1e-6))
}
