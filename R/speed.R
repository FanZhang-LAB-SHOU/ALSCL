#' Speed settings for model fitting
#'
#' Sets how \code{\link{run_acl}}, \code{\link{run_alscl}} and the functions
#' built on them (\code{\link{retro_model}}, \code{\link{sim_acl}}) evaluate
#' the model and compute standard errors. Each setting changes only how the
#' same quantities are computed. Arguments left out keep their current value.
#'
#' @param sd_cores \code{"auto"} or a positive integer: the number of cores
#'   used within one fit to compute standard errors. The Hessian of the fixed
#'   effects (one column per task) and the delta-method variance of each
#'   ADREPORT quantity (independent of one another) are computed in parallel.
#'   The results are identical to those of the sequential calculation.
#'   \code{"auto"} uses up to four physical cores and keeps one free. This is
#'   separate from the \code{ncores} argument of \code{run_acl()} and
#'   \code{run_alscl()}, which sets the number of workers for multiple starts.
#'   Forked processes are used, so Windows computes standard errors
#'   sequentially. Fits that already run on parallel workers
#'   (\code{retro_model()}, \code{sim_acl()}) use one core each; set
#'   \code{sd_cores = 1} when you run fits in your own parallel loop.
#' @param framework Automatic-differentiation library that TMB compiles the
#'   model with. \code{"TMBad"} (default) evaluates the Laplace approximation
#'   and its gradient several times faster. \code{"CppAD"} is TMB's default
#'   library, used by ALSCL 2.0.0 and earlier; it reproduces earlier results
#'   bit for bit. The two give the same estimates and standard errors up to
#'   floating-point rounding (see the benchmark in \file{docs/SPEED.md}).
#'   A change takes effect at the next fit, which compiles the model once for
#'   each library.
#' @return The previous settings, invisibly, so that \code{options(old)}
#'   restores them.
#' @examples
#' old <- alscl_speed(sd_cores = 1)  # sequential standard errors
#' alscl_speed(framework = "CppAD")  # results of ALSCL 2.0.0, bit for bit
#' options(old)
#' @export
alscl_speed <- function(sd_cores = getOption("ALSCL.sd_cores", "auto"),
                        framework = getOption("ALSCL.framework", "TMBad")) {
  .acl_check_cores(sd_cores, "sd_cores")
  framework <- match.arg(framework, c("TMBad", "CppAD"))
  invisible(options(ALSCL.sd_cores = sd_cores, ALSCL.framework = framework))
}

.acl_framework <- function() match.arg(getOption("ALSCL.framework", "TMBad"), c("TMBad", "CppAD"))

# Settings for socket workers that fit models themselves: the same AD
# library as the main process, and sequential standard errors, because the
# workers already run in parallel.
.acl_worker_options <- function() list(ALSCL.framework = .acl_framework(), ALSCL.sd_cores = 1L)

.acl_check_cores <- function(x, name) {
  if (!identical(x, "auto") && (!is.numeric(x) || length(x) != 1L || is.na(x) ||
                                x < 1 || x != round(x)))
    stop(name, " must be \"auto\" or a positive integer.", call. = FALSE)
  invisible(x)
}

# Resolve a core request to an integer. "auto" uses up to four physical cores
# and keeps one free; fork-based parallelism is unavailable on Windows.
.acl_cores <- function(x = getOption("ALSCL.sd_cores", "auto")) {
  .acl_check_cores(x, "sd_cores")
  if (.Platform$OS.type != "unix") return(1L)
  if (!identical(x, "auto")) return(as.integer(x))
  n <- parallel::detectCores(logical = FALSE)
  if (is.na(n)) n <- parallel::detectCores()
  if (is.na(n)) return(1L)
  as.integer(max(1L, min(4L, n - 1L)))
}

# parallel::mclapply() that fails loudly: a worker error, or a worker killed
# by the system, becomes an R error of class "acl_parallel_error" instead of
# a silently missing element.
.acl_mclapply <- function(X, FUN, ncores) {
  out <- parallel::mclapply(X, FUN, mc.cores = ncores, mc.preschedule = TRUE)
  bad <- vapply(out, function(z) is.null(z) || inherits(z, "try-error"), logical(1))
  if (any(bad)) {
    z <- out[bad][[1]]
    msg <- if (inherits(z, "try-error")) conditionMessage(attr(z, "condition"))
           else "a worker returned no result"
    stop(structure(class = c("acl_parallel_error", "error", "condition"),
                   list(message = msg, call = NULL)))
  }
  out
}

# stats::optimHess(par, obj$fn, obj$gr) with its columns computed in
# parallel. R's C routine (optimhess) reuses one parameter vector: after
# column j it resets coordinate j to ((p + eps) - 2 eps) + eps, which can
# differ from p in the last bit, and later columns see that value. With
# random effects, every gradient call starts the inner optimisation from
# obj$env$last.par.best, which gradient calls do not change, so each column
# starts from the same point as in the sequential calculation. The result is
# identical to optimHess().
.acl_optimhess <- function(obj, par, ncores) {
  eps <- 1e-3
  drifted <- ((par + eps) - 2 * eps) + eps
  column <- function(i) {
    x <- par
    if (i > 1L) x[seq_len(i - 1L)] <- drifted[seq_len(i - 1L)]
    x[i] <- par[i] + eps; g1 <- as.numeric(obj$gr(x))
    x[i] <- x[i] - 2 * eps; g2 <- as.numeric(obj$gr(x))
    (g1 - g2) / (2 * eps)
  }
  H <- do.call(cbind, .acl_mclapply(seq_along(par), column, ncores))
  H <- 0.5 * (H + t(H))
  if (!is.null(names(par))) dimnames(H) <- list(names(par), names(par))
  H
}

# Delta-method standard errors of the ADREPORT quantities, one quantity per
# task, as TMB::sdreport(..., getReportCovariance = FALSE) computes them
# (TMB 1.9.x, doDeltaMethod(chunk = i)). Must be called right after
# TMB::sdreport(), which leaves the Cholesky factor of the random-effect
# Hessian at `par` in obj$env$L.created.by.newton.
.acl_delta_sd <- function(obj, par, Vtheta, ncores) {
  env <- obj$env
  r <- env$random
  obj2 <- TMB::MakeADFun(env$data, env$parameters, type = "ADFun", ADreport = TRUE,
                         DLL = env$DLL, silent = env$silent)
  phi <- try(obj2$fn(par), silent = TRUE)
  if (is.character(phi) || length(phi) == 0) return(list(value = numeric(0), sd = numeric(0)))
  if (!is.null(r)) {
    hessian.random <- env$spHess(par, random = TRUE)
    L <- env$L.created.by.newton
    if (!is.null(L)) hessian.random@factors <- list(SPdCholesky = L)
    # Forward sweep of the gradient tape once, before forking, so that each
    # worker runs only reverse sweeps (doforward = 0).
    env$f(par, order = 0, type = "ADGrad")
  }
  f <- env$f
  doDeltaMethod <- function(chunk) {
    simpleCase <- is.null(r)
    w <- rep(0, length(phi))
    phiDeriv <- function(i) {
      w[i] <- 1
      obj2$env$f(par, order = 1, rangeweight = w, doforward = 0)
    }
    Dphi <- t(sapply(chunk, phiDeriv))
    phi <- phi[chunk]
    if (!is.null(r)) {
      Dphi.random <- Dphi[, r, drop = FALSE]
      Dphi.fixed <- Dphi[, -r, drop = FALSE]
      if (all(Dphi.random == 0)) {
        simpleCase <- TRUE
        Dphi <- Dphi.fixed
      }
    }
    if (simpleCase) return(Dphi %*% Vtheta %*% t(Dphi))
    tmp <- Matrix::solve(hessian.random, t(Dphi.random))
    tmp <- as.matrix(tmp)
    term1 <- Dphi.random %*% tmp
    w <- rep(0, length(par))
    reverse.sweep <- function(i) {
      w[r] <- tmp[, i]
      -f(par, order = 1, type = "ADGrad", rangeweight = w, doforward = 0)[-r]
    }
    A <- t(do.call("cbind", lapply(seq_along(phi), reverse.sweep))) + Dphi.fixed
    term2 <- A %*% (Vtheta %*% t(A))
    term1 + term2
  }
  tmp <- .acl_mclapply(seq_along(phi), doDeltaMethod, ncores)
  list(value = phi, sd = sqrt(as.numeric(unlist(tmp))))
}

# TMB::sdreport(obj, par.fixed, getReportCovariance = FALSE) with the
# fixed-effect Hessian and the per-quantity delta method computed in
# parallel; the returned object is identical to the sequential one. TMB
# computes everything else (skip.delta.method = TRUE). Falls back to the
# sequential TMB::sdreport() for one core, for TMB versions other than 1.9.x
# (whose delta method this code reproduces), or if the parallel calculation
# fails.
.acl_sdreport <- function(obj, par.fixed, ncores = .acl_cores()) {
  sequential <- function() TMB::sdreport(obj, par.fixed = par.fixed, getReportCovariance = FALSE)
  tmb <- utils::packageVersion("TMB")
  if (ncores <= 1L || length(par.fixed) == 0L || tmb < "1.9.0" || tmb >= "1.10.0")
    return(sequential())
  tryCatch({
    hessian.fixed <- .acl_optimhess(obj, par.fixed, ncores)
    ans <- TMB::sdreport(obj, par.fixed = par.fixed, hessian.fixed = hessian.fixed,
                         getReportCovariance = FALSE, skip.delta.method = TRUE)
    # sdreport() left obj$env$last.par at the joint mode for par.fixed, the
    # point at which it evaluated everything; the checks below confirm it.
    par <- obj$env$last.par
    r <- obj$env$random
    same <- if (is.null(r)) identical(unname(par), unname(par.fixed))
            else identical(unname(par[-r]), unname(par.fixed)) &&
                 identical(unname(par[r]), unname(ans$par.random))
    delta <- if (same) .acl_delta_sd(obj, par, ans$cov.fixed, ncores)
    if (!same || !identical(unname(delta$value), unname(ans$value)))
      stop(structure(class = c("acl_parallel_error", "error", "condition"),
                     list(message = "state differs from sdreport()", call = NULL)))
    ans$sd <- delta$sd
    ans
  }, acl_parallel_error = function(e) {
    warning("Parallel standard errors failed (", conditionMessage(e),
            "); computing them sequentially.", call. = FALSE)
    sequential()
  })
}
