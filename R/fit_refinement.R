# Conservative finishing step; the original optimizer result is kept separately.
.acl_polish <- function(obj, par, lower, upper, enabled = TRUE) {
  history <- data.frame(iteration = integer(), objective = numeric(),
    max_gradient = numeric(), step_scale = numeric())
  status <- if (enabled) "not_started" else "disabled"
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
      h <- stats::optimHess(par, obj$fn, obj$gr)
      h <- (h + t(h))/2
      if (any(!is.finite(h))) stop("nonfinite Hessian")
      # chol both checks positive definiteness and avoids an unstable inverse.
      r <- chol(h)
      as.numeric(backsolve(r, forwardsolve(t(r), current$gradient)))
    }, error = function(e) NULL)
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
    history = history)
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
  if (is.matrix(cov) && nrow(cov) == length(par) && all(is.finite(cov)) && all(diag(cov) > 0)) {
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
  if (!isTRUE(fit$pdHess) || !covariance_ok) issues <- c(issues, "Hessian/covariance unavailable or not positive definite")
  if (isTRUE(fit$bound_hit)) issues <- c(issues, "optimizer-scale boundary")
  if (any(natural$near_boundary)) issues <- c(issues, "natural-scale boundary")
  if (nrow(correlations)) issues <- c(issues, "strong parameter correlation (review identifiability)")
  # This numerical screen is not a claim of model adequacy or identifiability.
  list(stationary = stationary, numerical_ok = stationary && isTRUE(fit$pdHess) &&
      covariance_ok && !isTRUE(fit$bound_hit) && !any(natural$near_boundary),
    natural_parameters = natural, natural_boundary = any(natural$near_boundary),
    covariance_condition = condition, high_correlations = correlations, issues = issues,
    thresholds = list(gradient = 1e-3, natural_boundary = 1e-4, correlation = .95))
}
