#' Speed settings for model fitting
#'
#' Sets how \code{\link{run_acl}}, \code{\link{run_alscl}} and the functions
#' built on them (\code{\link{retro_model}}, \code{\link{sim_acl}}) evaluate
#' the model and compute standard errors. Arguments left out keep their
#' current value. \code{\link{alscl_speed_info}} shows what the current
#' settings mean on this computer.
#'
#' @param sd_cores \code{"auto"} or a positive integer: the number of cores
#'   used within one fit to compute standard errors. The results are
#'   identical to those of the sequential calculation. Where forked processes
#'   are safe (macOS and Linux outside GUI front-ends), the Hessian of the
#'   fixed effects (one column per task) and the delta-method variance of
#'   each ADREPORT quantity are computed in forked processes. Where forking
#'   is unavailable or discouraged (see \code{\link[parallel]{mclapply}}): on
#'   Windows, in GUI or embedded front-ends (R.app, RGui, RStudio, Positron)
#'   and with Apple's Accelerate BLAS, the delta method runs on socket workers
#'   when it would take more than about 3 seconds, and the Hessian is computed
#'   in the main process, because each new R process would first have to
#'   rebuild TMB's derivative tapes. \code{"auto"} uses up to four physical
#'   cores and keeps one free. This setting is separate from the
#'   \code{ncores} argument of \code{run_acl()} and \code{run_alscl()}, which
#'   sets the number of workers for multiple starts. Fits that already run on
#'   parallel workers (\code{retro_model()}, \code{sim_acl()}) use one core
#'   each; set \code{sd_cores = 1} when you run fits in your own parallel loop.
#' @param framework Automatic-differentiation library that TMB compiles the
#'   model with. \code{"CppAD"} (default) is TMB's default library, used by
#'   ALSCL 2.0.0 and earlier. Since 2.2.2, optimizer refinement can change
#'   estimates; parallel standard errors still match sequential calculations
#'   at the same parameters. This is not a cross-version identity guarantee.
#'   \code{"TMBad"} evaluates the Laplace approximation and its gradient
#'   several times faster, but results are not identical: in the tests in
#'   \file{docs/SPEED.md}, estimates differed by up to 2e-11 (relative) when
#'   5 fixed effects were estimated and by up to 3e-8 when 10 were estimated.
#'   A change takes effect at the next fit, which compiles the model once for
#'   each library.
#' @return The previous settings, invisibly, so that \code{options(old)}
#'   restores them.
#' @seealso \code{\link{alscl_speed_info}}; the user guide
#'   \file{docs/SPEED_GUIDE.md}.
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

#' Show how fits will use the speed settings
#'
#' Reports the speed settings of \code{\link{alscl_speed}} and what they mean
#' in this R session: how many cores the standard errors use, how the work is
#' shared out and why, and which automatic-differentiation library is used. Use
#' it to check that a session gets the expected speed-up, and to record the
#' settings together with results. After a fit, \code{fit$sd_info} records
#' what was actually done.
#'
#' @return A data frame with columns \code{item} and \code{value}, of class
#'   \code{"alscl_speed_info"}, which prints as a list of settings.
#' @examples
#' alscl_speed_info()
#' @export
alscl_speed_info <- function() {
  setting <- getOption("ALSCL.sd_cores", "auto")
  cores <- .acl_cores(setting)
  backend <- .acl_sd_backend()
  min_seconds <- getOption("ALSCL.sd_socket_min_seconds", 3)
  method <- if (cores <= 1L) "sequential (one core)"
    else if (!.acl_tmb_supported()) "sequential (this TMB version was not checked)"
    else if (backend == "fork") sprintf("forked processes on %d cores: Hessian and delta method", cores)
    else sprintf(paste("Hessian in the main process; delta method on %d socket workers",
                       "when it would take more than %s s"), cores, format(min_seconds))
  framework <- .acl_framework()
  info <- data.frame(stringsAsFactors = FALSE,
    item = c("sd_cores setting", "cores for standard errors", "standard errors computed by",
             "reason", "framework", "cross-version numerical identity", "TMB version"),
    value = c(format(setting), cores, method, .acl_fork_reason(), framework,
              "not guaranteed (2.2.2 adds optimizer refinement)",
              paste0(utils::packageVersion("TMB"),
                     if (.acl_tmb_supported()) " (checked)" else " (not checked: sequential standard errors)")))
  class(info) <- c("alscl_speed_info", class(info))
  info
}

#' @export
print.alscl_speed_info <- function(x, ...) {
  cat("ALSCL speed settings\n")
  cat(sprintf("  %-34s %s\n", paste0(x$item, ":"), x$value), sep = "")
  invisible(x)
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

# Whether forked processes are safe, and why not. ?parallel::mclapply
# discourages forking in GUI and embedded front-ends and with multithreaded
# libraries in the parent process; Apple's Accelerate BLAS is multithreaded.
.acl_fork_ok <- "forked processes are safe here (macOS or Linux outside a GUI front-end)"
.acl_fork_reason <- function(os = .Platform$OS.type, gui = .Platform$GUI,
                             front_ends = Sys.getenv(c("RSTUDIO", "POSITRON")),
                             blas = tryCatch(extSoftVersion()[["BLAS"]], error = function(e) "")) {
  if (!identical(os, "unix")) return("Windows: forked processes are not available, so socket workers are used")
  if (gui %in% c("AQUA", "Rgui", "RStudio") || any(front_ends == "1"))
    return("GUI front-end (R.app, RGui, RStudio or Positron): forking is discouraged, so socket workers are used")
  if (isTRUE(grepl("Accelerate|vecLib", blas)))
    return("Apple's Accelerate BLAS is multithreaded: forking is discouraged, so socket workers are used")
  .acl_fork_ok
}
.acl_fork_safe <- function(os = .Platform$OS.type, gui = .Platform$GUI,
                           front_ends = Sys.getenv(c("RSTUDIO", "POSITRON")),
                           blas = tryCatch(extSoftVersion()[["BLAS"]], error = function(e) ""))
  identical(.acl_fork_reason(os, gui, front_ends, blas), .acl_fork_ok)

# Resolve a core request to an integer. "auto" uses up to four physical cores
# and keeps one free.
.acl_cores <- function(x = getOption("ALSCL.sd_cores", "auto")) {
  .acl_check_cores(x, "sd_cores")
  if (!identical(x, "auto")) return(as.integer(x))
  n <- parallel::detectCores(logical = FALSE)
  if (is.na(n)) n <- parallel::detectCores()
  if (is.na(n)) return(1L)
  as.integer(max(1L, min(4L, n - 1L)))
}

# How standard errors run in parallel: "fork" (forked processes for the
# Hessian and the delta method) where forking is safe, otherwise "socket"
# (socket workers for the delta method only; see .acl_delta_socket()).
# options(ALSCL.sd_backend = "fork" or "socket") overrides the choice; fork
# is never used on Windows.
.acl_sd_backend <- function(fork_safe = .acl_fork_safe(),
                            choice = getOption("ALSCL.sd_backend", "auto")) {
  choice <- match.arg(choice, c("auto", "fork", "socket"))
  if (choice == "fork" && .Platform$OS.type != "unix") choice <- "socket"
  if (choice != "auto") return(choice)
  if (fork_safe) "fork" else "socket"
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
.acl_mclapply <- function(X, FUN, ncores, ...) {
  out <- tryCatch(parallel::mclapply(X, FUN, ..., mc.cores = ncores, mc.preschedule = TRUE),
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
  cols <- if (ncores > 1L) .acl_mclapply(seq_along(par), column, ncores) else lapply(seq_along(par), column)
  H <- do.call(cbind, cols)
  H <- 0.5 * (H + t(H))
  if (!is.null(names(par))) dimnames(H) <- list(names(par), names(par))
  H
}

# Delta-method variance of ADREPORT quantity `chunk`, step by step as
# TMB::sdreport(..., getReportCovariance = FALSE) computes it (TMB 1.9.21,
# doDeltaMethod(chunk = i)). `s` holds the ADREPORT object (obj2), the
# objective's evaluation function (f), the random-effect indices (r), the
# joint mode (par), the ADREPORT values (phi), the fixed-effect covariance
# (Vtheta) and the random-effect Hessian. It uses only its arguments, base R
# and Matrix, so socket workers can run it without ALSCL.
.acl_delta_one <- function(chunk, s) {
  phi <- s$phi; r <- s$r; par <- s$par; Vtheta <- s$Vtheta; obj2 <- s$obj2; f <- s$f
  hessian.random <- s$hessian.random
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

# Delta-method standard errors of the ADREPORT quantities, one quantity per
# task. Must be called right after TMB::sdreport(), which leaves the Cholesky
# factor of the random-effect Hessian at `par` in obj$env$L.created.by.newton.
# Returns the ADREPORT values, the standard errors and how they were computed.
.acl_delta_sd <- function(obj, par, Vtheta, ncores, backend = "fork",
                          min_seconds = getOption("ALSCL.sd_socket_min_seconds", 3)) {
  env <- obj$env
  r <- env$random
  obj2 <- TMB::MakeADFun(env$data, env$parameters, type = "ADFun", ADreport = TRUE,
                         DLL = env$DLL, silent = env$silent)
  phi <- try(obj2$fn(par), silent = TRUE)
  if (is.character(phi) || length(phi) == 0)
    return(list(value = numeric(0), sd = numeric(0), method = "sequential", cores = 1L))
  hessian.random <- NULL
  if (!is.null(r)) {
    hessian.random <- env$spHess(par, random = TRUE)
    L <- env$L.created.by.newton
    if (!is.null(L)) hessian.random@factors <- list(SPdCholesky = L)
    # Forward sweep of the gradient tape once, so that each quantity needs
    # only reverse sweeps (doforward = 0).
    env$f(par, order = 0, type = "ADGrad")
  }
  s <- list(obj2 = obj2, f = env$f, r = r, par = par, phi = phi, Vtheta = Vtheta,
            hessian.random = hessian.random)
  if (backend == "socket") {
    res <- .acl_delta_socket(obj, s, ncores, min_seconds)
    return(list(value = phi, sd = sqrt(as.numeric(unlist(res$variances))),
                method = res$method, cores = res$cores))
  }
  tmp <- if (ncores > 1L) .acl_mclapply(seq_along(phi), .acl_delta_one, ncores, s = s)
         else lapply(seq_along(phi), .acl_delta_one, s = s)
  list(value = phi, sd = sqrt(as.numeric(unlist(tmp))),
       method = if (ncores > 1L) "forked processes" else "sequential", cores = ncores)
}

# Delta method on socket workers, for sessions where forking is unsafe. The
# first quantities are computed here to measure the time per quantity; the
# rest go to socket workers only if computing them here would take longer
# than `min_seconds`. Each worker rebuilds the objective (MakeADFun) and the
# ADREPORT object from the same data and parameters and receives the joint
# mode, the fixed-effect covariance and the random-effect Hessian computed
# here, so it needs no sparse Hessian tape. The worker functions use only
# base R, TMB and Matrix (not ALSCL), and keep their state in options().
# min_seconds = 0 sends every quantity to the workers (used by the tests).
.acl_delta_socket <- function(obj, s, ncores, min_seconds) {
  m <- length(s$phi)
  out <- vector("list", m)
  started <- proc.time()[["elapsed"]]
  k <- 0L
  while (min_seconds > 0 && k < m && k < 200L && (k < 5L || proc.time()[["elapsed"]] - started < 0.5)) {
    k <- k + 1L
    out[[k]] <- .acl_delta_one(k, s)
  }
  rest <- if (k < m) seq.int(k + 1L, m) else integer(0)
  per_quantity <- if (k > 0L) (proc.time()[["elapsed"]] - started) / k else Inf
  if (length(rest) <= 1L || ncores <= 1L || per_quantity * length(rest) < min_seconds) {
    out[rest] <- lapply(rest, .acl_delta_one, s = s)
    return(list(variances = out, method = "sequential", cores = 1L))
  }
  env <- obj$env
  workers <- min(ncores, length(rest))
  path <- getLoadedDLLs()[[env$DLL]][["path"]]
  one <- .acl_delta_one; environment(one) <- globalenv()
  setup <- function(paths, path, dll, data, parameters, random, par, Vtheta, hessian.random, one) {
    .libPaths(paths)
    loadNamespace("TMB"); loadNamespace("Matrix")
    if (!dll %in% names(getLoadedDLLs())) dyn.load(path)
    obj <- TMB::MakeADFun(data, parameters, random = random, DLL = dll, silent = TRUE)
    obj2 <- TMB::MakeADFun(data, parameters, type = "ADFun", ADreport = TRUE, DLL = dll, silent = TRUE)
    phi <- obj2$fn(par)
    if (!is.null(random)) obj$env$f(par, order = 0, type = "ADGrad")
    options(ALSCL.delta_state = list(obj = obj, one = one, s = list(
      obj2 = obj2, f = obj$env$f, r = random, par = par, phi = phi, Vtheta = Vtheta,
      hessian.random = hessian.random)))
    phi
  }
  task <- function(chunk) {
    state <- getOption("ALSCL.delta_state")
    lapply(chunk, state$one, s = state$s)
  }
  environment(setup) <- globalenv(); environment(task) <- globalenv()
  cl <- tryCatch(parallel::makePSOCKcluster(workers),
                 error = function(e) stop(.acl_parallel_error(conditionMessage(e))))
  on.exit(parallel::stopCluster(cl), add = TRUE)
  tryCatch({
    phis <- parallel::clusterCall(cl, setup, .libPaths(), path, env$DLL, env$data, env$parameters,
                                  s$r, s$par, s$Vtheta, s$hessian.random, one)
    # The workers' ADREPORT values must be those of this session.
    if (!all(vapply(phis, identical, logical(1), s$phi)))
      stop("socket workers computed different ADREPORT values")
    chunks <- split(rest, cut(seq_along(rest), workers, labels = FALSE))
    out[rest] <- unlist(parallel::clusterApply(cl, chunks, task), recursive = FALSE)
  }, error = function(e) stop(.acl_parallel_error(conditionMessage(e))))
  list(variances = out, method = "socket workers", cores = workers)
}

# TMB::sdreport(obj, par.fixed, getReportCovariance = FALSE) with the
# fixed-effect Hessian and the per-quantity delta method computed in
# parallel; the returned object is identical to the sequential one. TMB
# computes everything else (skip.delta.method = TRUE). Falls back to the
# sequential TMB::sdreport() for one core, for TMB versions not in
# .acl_tmb_checked, or, with a warning, if the parallel calculation fails.
# The tests use check_version = FALSE to run the parallel code with any TMB
# version, and fallback = FALSE so that a parallel failure is an error rather
# than a silent comparison of TMB with itself. The attribute "acl_sd_info"
# records how the standard errors were computed and how long they took.
.acl_sdreport <- function(obj, par.fixed, ncores = .acl_cores(), check_version = TRUE,
                          fallback = TRUE, backend = .acl_sd_backend()) {
  started <- proc.time()[["elapsed"]]
  done <- function(ans, method, cores, note = NULL) {
    force(ans)  # evaluate sdreport() before the time is taken
    attr(ans, "acl_sd_info") <- list(method = method, cores = as.integer(cores),
                                     seconds = proc.time()[["elapsed"]] - started, note = note)
    ans
  }
  sequential <- function(note) done(TMB::sdreport(obj, par.fixed = par.fixed, getReportCovariance = FALSE),
                                    "sequential", 1L, note)
  if (ncores <= 1L) return(sequential("one core"))
  if (length(par.fixed) == 0L) return(sequential("no fixed effects"))
  if (check_version && !.acl_tmb_supported())
    return(sequential(paste("TMB", utils::packageVersion("TMB"), "was not checked")))
  in_parallel <- function() {
    # Socket workers would each have to rebuild TMB's sparse Hessian tape to
    # compute gradients, which costs more than the Hessian itself, so with
    # socket workers the Hessian is computed here.
    hessian.fixed <- .acl_optimhess(obj, par.fixed, if (backend == "fork") ncores else 1L)
    ans <- TMB::sdreport(obj, par.fixed = par.fixed, hessian.fixed = hessian.fixed,
                         getReportCovariance = FALSE, skip.delta.method = TRUE)
    # sdreport() left obj$env$last.par at the joint mode for par.fixed, the
    # point at which it evaluated everything; the checks below confirm it.
    par <- obj$env$last.par
    r <- obj$env$random
    same <- if (is.null(r)) identical(unname(par), unname(par.fixed))
            else identical(unname(par[-r]), unname(par.fixed)) &&
                 identical(unname(par[r]), unname(ans$par.random))
    delta <- if (same) .acl_delta_sd(obj, par, ans$cov.fixed, ncores, backend)
    if (!same || !identical(unname(delta$value), unname(ans$value)))
      stop(.acl_parallel_error("state differs from sdreport()"))
    ans$sd <- delta$sd
    method <- if (backend == "fork") "forked processes"
              else if (delta$method == "socket workers") "socket workers (delta method)"
              else "sequential"
    done(ans, method, if (method == "sequential") 1L else if (backend == "fork") ncores else delta$cores,
         if (method == "sequential") "too little work to start socket workers")
  }
  if (!fallback) return(in_parallel())
  tryCatch(in_parallel(), acl_parallel_error = function(e) {
    warning("Parallel standard errors failed (", conditionMessage(e),
            "); computing them sequentially.", call. = FALSE)
    sequential(paste("parallel calculation failed:", conditionMessage(e)))
  })
}

# One line describing how standard errors were computed, for fit messages.
.acl_sd_message <- function(info) {
  if (is.null(info)) return(NULL)
  how <- switch(info$method,
    "forked processes" = sprintf("forked processes on %d cores", info$cores),
    "socket workers (delta method)" = sprintf("%d socket workers for the delta method", info$cores),
    "sequential" = paste0("sequential", if (!is.null(info$note)) paste0(" (", info$note, ")")))
  sprintf("Standard errors: %s, %.1f s.", how, info$seconds)
}
