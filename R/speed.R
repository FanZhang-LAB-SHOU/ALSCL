#' Speed settings for model fitting
#'
#' Sets how \code{\link{run_acl}}, \code{\link{run_alscl}} and the functions
#' built on them (\code{\link{retro_model}}, \code{\link{sim_acl}}) evaluate
#' the model and compute standard errors. Arguments left out keep their
#' current value.
#'
#' @param sd_cores \code{"auto"} or a positive integer: the number of cores
#'   used within one fit to compute standard errors. The Hessian of the fixed
#'   effects (one column per task) and the delta-method variance of each
#'   ADREPORT quantity (independent of one another) are computed in forked
#'   processes. The results are identical to those of the sequential
#'   calculation. \code{"auto"} uses up to four physical cores and keeps one
#'   free, but uses one core where forked processes are unavailable or
#'   discouraged (see \code{\link[parallel]{mclapply}}): on Windows, in GUI or
#'   embedded front-ends (R.app, RGui, RStudio, Positron) and with Apple's
#'   Accelerate BLAS. A number of cores is used as given, except on Windows.
#'   This setting is separate from the \code{ncores} argument of
#'   \code{run_acl()} and \code{run_alscl()}, which sets the number of workers
#'   for multiple starts. Fits that already run on parallel workers
#'   (\code{retro_model()}, \code{sim_acl()}) use one core each; set
#'   \code{sd_cores = 1} when you run fits in your own parallel loop.
#' @param framework Automatic-differentiation library that TMB compiles the
#'   model with. \code{"CppAD"} (default) is TMB's default library, used by
#'   ALSCL 2.0.0 and earlier; results are identical to those of ALSCL 2.0.0.
#'   \code{"TMBad"} evaluates the Laplace approximation and its gradient
#'   several times faster, but results are not identical: in the tests in
#'   \file{docs/SPEED.md}, estimates differed by up to 2e-11 (relative) when
#'   5 fixed effects were estimated and by up to 3e-8 when 10 were estimated.
#'   A change takes effect at the next fit, which compiles the model once for
#'   each library.
#' @return The previous settings, invisibly, so that \code{options(old)}
#'   restores them.
#' @examples
#' old <- alscl_speed(sd_cores = 1)  # sequential standard errors
#' alscl_speed(framework = "TMBad")  # faster, results not identical
#' options(old)
#' @export
alscl_speed <- function(sd_cores = getOption("ALSCL.sd_cores", "auto"),
                        framework = getOption("ALSCL.framework", "CppAD")) {
  .acl_check_cores(sd_cores, "sd_cores")
  framework <- match.arg(framework, c("CppAD", "TMBad"))
  invisible(options(ALSCL.sd_cores = sd_cores, ALSCL.framework = framework))
}

.acl_framework <- function() match.arg(getOption("ALSCL.framework", "CppAD"), c("CppAD", "TMBad"))

# Settings for socket workers that fit models themselves: the same AD
# library as the main process, and sequential standard errors, because the
# workers already run in parallel.
.acl_worker_options <- function() list(ALSCL.framework = .acl_framework(), ALSCL.sd_cores = 1L)

.acl_check_cores <- function(x, name) {
  ok <- identical(x, "auto") ||
    (is.numeric(x) && length(x) == 1L && is.finite(x) && x >= 1 &&
     x <= .Machine$integer.max && x == round(x))
  if (!ok) stop(name, " must be \"auto\" or a positive integer.", call. = FALSE)
  invisible(x)
}

# Whether "auto" may fork. ?parallel::mclapply discourages forking in GUI
# and embedded front-ends and with multithreaded libraries in the parent
# process; Apple's Accelerate BLAS is multithreaded.
.acl_fork_safe <- function(os = .Platform$OS.type, gui = .Platform$GUI,
                           front_ends = Sys.getenv(c("RSTUDIO", "POSITRON")),
                           blas = tryCatch(extSoftVersion()[["BLAS"]], error = function(e) "")) {
  identical(os, "unix") && !gui %in% c("AQUA", "Rgui", "RStudio") &&
    !any(front_ends == "1") && !isTRUE(grepl("Accelerate|vecLib", blas))
}

# Resolve a core request to an integer. "auto" uses up to four physical cores
# and keeps one free, or one core where forking is unsafe; fork-based
# parallelism is unavailable on Windows.
.acl_cores <- function(x = getOption("ALSCL.sd_cores", "auto"), fork_safe = .acl_fork_safe()) {
  .acl_check_cores(x, "sd_cores")
  if (.Platform$OS.type != "unix") return(1L)
  if (!identical(x, "auto")) return(as.integer(x))
  if (!fork_safe) return(1L)
  n <- parallel::detectCores(logical = FALSE)
  if (is.na(n)) n <- parallel::detectCores()
  if (is.na(n)) return(1L)
  as.integer(max(1L, min(4L, n - 1L)))
}

# TMB versions whose sdreport() the parallel delta method was checked
# against; tests/testthat/test-speed.R compares the two with identical().
# Other versions use TMB::sdreport() itself. To add a version, run the tests
# with it installed.
.acl_tmb_checked <- "1.9.21"
.acl_tmb_supported <- function(version = utils::packageVersion("TMB"))
  as.character(version) %in% .acl_tmb_checked

.acl_parallel_error <- function(message)
  structure(class = c("acl_parallel_error", "error", "condition"),
            list(message = message, call = NULL))

# parallel::mclapply() that fails loudly: a failure to fork, a worker error
# or a worker killed by the system becomes an error of class
# "acl_parallel_error" instead of a silently missing element.
.acl_mclapply <- function(X, FUN, ncores) {
  out <- tryCatch(parallel::mclapply(X, FUN, mc.cores = ncores, mc.preschedule = TRUE),
                  error = function(e) stop(.acl_parallel_error(conditionMessage(e))))
  bad <- vapply(out, function(z) is.null(z) || inherits(z, "try-error"), logical(1))
  if (any(bad)) {
    z <- out[bad][[1]]
    stop(.acl_parallel_error(if (inherits(z, "try-error")) conditionMessage(attr(z, "condition"))
                             else "a worker returned no result"))
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
# (TMB 1.9.21, doDeltaMethod(chunk = i)). Must be called right after
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
# sequential TMB::sdreport() for one core, for TMB versions not in
# .acl_tmb_checked, or, with a warning, if the parallel calculation fails.
# The tests use check_version = FALSE to run the parallel code with any TMB
# version, and fallback = FALSE so that a parallel failure is an error rather
# than a silent comparison of TMB with itself.
.acl_sdreport <- function(obj, par.fixed, ncores = .acl_cores(), check_version = TRUE,
                          fallback = TRUE) {
  sequential <- function() TMB::sdreport(obj, par.fixed = par.fixed, getReportCovariance = FALSE)
  if (ncores <= 1L || length(par.fixed) == 0L || (check_version && !.acl_tmb_supported()))
    return(sequential())
  in_parallel <- function() {
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
      stop(.acl_parallel_error("state differs from sdreport()"))
    ans$sd <- delta$sd
    ans
  }
  if (!fallback) return(in_parallel())
  tryCatch(in_parallel(), acl_parallel_error = function(e) {
    warning("Parallel standard errors failed (", conditionMessage(e),
            "); computing them sequentially.", call. = FALSE)
    sequential()
  })
}
