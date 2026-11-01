#' Fit simulated datasets with either assessment model
#'
#' This function runs a stock assessment model using the specified iteration range.
#' Supports parallel execution on multiple CPU cores for faster computation.
#'
#' @param iter_range A numeric vector specifying the range of iterations to run the stock assessment model for (default is 4:100).
#' @param sim_data_path A character string specifying the path to the folder containing the simulation data files (default is the current working directory).
#'   Recorded observation years are retained. Older files without time metadata
#'   use a first observation year of 2000.
#' @param output_dir Character, the directory where simulation results will be saved.(default is the current working directory).
#' @param parameters A list containing the custom initial values for the parameters (default is NULL).
#' @param parameters.L A list containing the custom lower bounds for the parameters (default is NULL).
#' @param parameters.U A list containing the custom upper bounds for the parameters (default is NULL).
#' @param map A list containing the custom values for the map elements (default is NULL).
#' @param M Numeric, natural mortality (default: 0.2)
#' @param ncores Integer. Number of CPU cores to use. 1 = sequential (default).
#'   Uses socket workers on all platforms.
#'   Use \code{parallel::detectCores()} to see available cores.
#'
#' @inheritParams run_acl
#' @return A list containing the results of the stock assessment model. Failed
#'   fits contain converge = "FAILED", error and iter. Each result, including
#'   failures, replaces its result_rep_<iter> file in output_dir. Storage errors
#'   stop the batch rather than leave an old success file as the current result.
#' @export
#' @param train_times Number of optimization passes per independent start.
#' @param control Named nlminb control settings.
#' @param model Model fitted to each simulation, "acl" (default) or "alscl".
#' @param nstarts Positive integer; number of independent optimization starts
#'   per simulated dataset. Defaults to 1, independently of ncores. Starts run
#'   sequentially within each replicate; ncores controls parallel replicates.
#' @details M and F are per model time step, including quarterly simulations.
#'   Each replicate uses one fitting worker and sequential standard errors to
#'   avoid nested parallelism, including when nstarts is greater than 1. Each
#'   successful result retains nstarts, workers and start_diagnostics from the
#'   core fit. train_times controls successive optimization passes from each
#'   start, whereas nstarts controls independent initial values. Model-specific
#'   parameters and maps must match the selected model. sim_acl() retains the
#'   original ACL interface; sim_alscl()
#'   provides the corresponding ALSCL convenience interface.
sim_model <- function(iter_range = 4:100, sim_data_path = ".", output_dir = ".",
                    parameters = NULL, parameters.L = NULL, parameters.U = NULL,
                    map = NULL, M = 0.2, ncores = 1, train_times = 1, control = list(),
                    F_structure = c("group_year", "year"), polish = TRUE,
                    model = c("acl", "alscl"), nstarts = 1) {
  model <- match.arg(model)
  F_structure <- match.arg(F_structure)
  ncores <- .acl_positive_integer(ncores, "ncores")
  nstarts <- .acl_positive_integer(nstarts, "nstarts")
  if (!is.numeric(iter_range) || !length(iter_range) || any(!is.finite(iter_range)) ||
      any(iter_range < 1 | iter_range != floor(iter_range) | iter_range > .Machine$integer.max) ||
      anyDuplicated(iter_range))
    stop("iter_range must contain distinct positive integer replicate IDs.", call. = FALSE)
  old <- options(ALSCL.sd_cores = 1L)
  on.exit(options(old), add = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  info <- .acl_compile(toupper(model))
  cache <- dirname(dirname(info$cpp_path))
  # Force caller expressions before serializing the closure to socket workers.
  # Global variables referenced by promises are not exported by parLapply().
  force(sim_data_path)
  force(output_dir)
  fit_args <- list(parameters = parameters, parameters.L = parameters.L,
    parameters.U = parameters.U, map = map, M = M, train_times = train_times,
    control = control, silent = TRUE, F_structure = F_structure, polish = polish,
    ncores = 1L, nstarts = nstarts)
  fit_one <- function(iter) {
    started <- proc.time()[["elapsed"]]
    result <- tryCatch({
      e <- new.env(parent = emptyenv())
      load(file.path(sim_data_path, paste0("sim_rep", iter)), envir = e)
      s <- e$sim.data
      if (is.null(s)) stop("Simulation file does not contain sim.data.")
      step <- if (!is.null(s$growth_step)) s$growth_step else if(length(s$ages)>1) diff(s$ages)[1] else 1
      tables <- .acl_simulation_to_tables(s)
      L50 <- s$q_surv_L50; L95 <- s$q_surv_L95
      if (is.null(L50) || is.null(L95)) {
        valid <- is.finite(s$q_surv) & s$q_surv > 0 & s$q_surv < 1
        if (sum(valid)<2L) stop("Simulation requires logistic survey catchability metadata.")
        coefficients <- stats::coef(stats::lm(stats::qlogis(s$q_surv[valid]) ~ s$len_mid[valid]))
        L50 <- -coefficients[1]/coefficients[2]; L95 <- L50+log(19)/coefficients[2]
      }
      do.call(if (model == "acl") run_acl else run_alscl,
        c(tables, list(rec.age = s$ages[1], nage = s$nage, sel_L50 = unname(L50), sel_L95 = unname(L95),
        len_mid = s$len_mid, len_border = s$len_border, growth_step = step), fit_args))
    }, error = function(e) list(converge = "FAILED", error = conditionMessage(e), iter = iter))
    result$iter <- iter
    if (is.null(result$elapsed)) result$elapsed <- unname(proc.time()[["elapsed"]] - started)
    .acl_save_simulation_result(result, file.path(output_dir, paste0("result_rep_", iter)))
    result
  }
  ncores <- min(ncores, length(iter_range))
  if (ncores == 1L) results <- lapply(iter_range, fit_one) else {
    cl <- parallel::makeCluster(ncores); on.exit(parallel::stopCluster(cl), add = TRUE)
    .acl_initialize_workers(cl, cache = cache, settings = .acl_worker_options())
    results <- parallel::parLapply(cl, iter_range, fit_one)
  }
  names(results) <- paste0("result_rep_", iter_range)
  results
}

#' Fit simulation replicates with ACL
#' @inheritParams sim_model
#' @return The named list of replicate fits or error records returned by sim_model().
#' @export
sim_acl <- function(iter_range = 4:100, sim_data_path = ".", output_dir = ".",
                    parameters = NULL, parameters.L = NULL, parameters.U = NULL,
                    map = NULL, M = 0.2, ncores = 1, train_times = 1, control = list(),
                    F_structure = c("group_year", "year"), polish = TRUE,
                    nstarts = 1) {
  sim_model(iter_range, sim_data_path, output_dir, parameters, parameters.L,
    parameters.U, map, M, ncores, train_times, control, F_structure, polish,
    model = "acl", nstarts = nstarts)
}

#' Fit simulation replicates with ALSCL
#' @param ... Arguments passed to sim_model(), excluding model and nstarts.
#' @inheritParams sim_model
#' @return The named list of replicate fits or error records returned by sim_model().
#' @export
sim_alscl <- function(..., nstarts = 1) sim_model(..., model = "alscl", nstarts = nstarts)

# Shared by the repository tutorial and batch fitting; validate coordinates
# before converting matrices to tables so rows can never be silently recycled.
.acl_simulation_to_tables <- function(sm, pa = NULL, first_year = NULL) {
  if (!is.list(sm) || (!is.null(pa) && !is.list(pa)))
    stop("Simulation and parameters must be lists.", call. = FALSE)
  step <- sm$growth_step
  if (is.null(step)) step <- pa$growth_step
  if (is.null(step)) step <- if (length(sm$ages) > 1L) diff(sm$ages)[1L] else 1
  if (!is.null(first_year)) {
    sm$years <- NULL
    sm$first.year <- first_year
  } else if (is.null(sm$first.year)) sm$first.year <- pa$first.year
  years <- .acl_simulation_years(sm, step)
  valid_mid <- function(x) is.numeric(x) && length(x) > 0L &&
    all(is.finite(x)) && all(x > 0) && all(diff(x) > 0)
  if (!is.null(sm$len_mid) && !valid_mid(sm$len_mid))
    stop("Simulation len_mid must be finite, positive and increasing.", call. = FALSE)
  if (!is.null(pa$len_mid) && !valid_mid(pa$len_mid))
    stop("Parameter len_mid must be finite, positive and increasing.", call. = FALSE)
  if (!is.null(sm$len_mid) && !is.null(pa$len_mid) &&
      (length(sm$len_mid) != length(pa$len_mid) ||
       any(abs(sm$len_mid - pa$len_mid) > 1e-8 * pmax(1, abs(sm$len_mid)))))
    stop("Parameter len_mid must match the recorded simulation length coordinates.", call. = FALSE)
  mid <- sm$len_mid
  if (is.null(mid)) mid <- pa$len_mid
  if (is.null(mid)) stop("Simulation length coordinates are required.", call. = FALSE)
  matrices <- list(SN_at_len = sm$SN_at_len, weight = sm$weight, mat = sm$mat)
  expected <- list(c(length(years), length(mid)), c(length(mid), length(years)),
                   c(length(mid), length(years)))
  for (i in seq_along(matrices)) {
    if (!is.matrix(matrices[[i]]) || !is.numeric(matrices[[i]]) ||
        !identical(dim(matrices[[i]]), as.integer(expected[[i]])))
      stop("Simulation ", names(matrices)[i], " dimensions must match its time and length coordinates.", call. = FALSE)
  }
  frame <- function(m) {
    out <- data.frame(LengthBin = as.character(mid), m, check.names = FALSE)
    names(out) <- c("LengthBin", as.character(years))
    out
  }
  list(data.CatL = frame(t(sm$SN_at_len)), data.wgt = frame(sm$weight),
       data.mat = frame(sm$mat))
}

.acl_save_simulation_result <- function(result, path) {
  if (dir.exists(path))
    stop("Cannot save simulation result over a directory: ", path, call. = FALSE)
  temporary <- tempfile(".alscl-result-", tmpdir = dirname(path))
  on.exit(unlink(temporary), add = TRUE)
  invalidate <- function() {
    if (file.exists(path) && unlink(path) != 0L)
      stop("Could not remove the previous simulation result: ", path, call. = FALSE)
  }
  tryCatch(save(result, file = temporary), error = function(e) {
    invalidate()
    stop("Could not save current simulation result: ", conditionMessage(e), call. = FALSE)
  })
  # Remove the previous file only after the new serialization is complete.
  # This also permits replacement on Windows, where rename will not overwrite.
  invalidate()
  if (!file.rename(temporary, path))
    stop("Could not install current simulation result: ", path, call. = FALSE)
  invisible(path)
}
