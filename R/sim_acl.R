#' Fit simulated datasets with either assessment model
#'
#' This function runs a stock assessment model using the specified iteration range.
#' Supports parallel execution on multiple CPU cores for faster computation.
#'
#' @param iter_range A numeric vector of distinct nonnegative integer replicate
#'   IDs to fit (default 4:100). Zero is valid, matching the seeds accepted by
#'   sim_data(). File names use the integer form of each ID, for example
#'   sim_rep100000 for 1e5, whatever the number formatting options are.
#' @param sim_data_path A character string specifying the path to the folder containing the simulation data files (default is the current working directory).
#'   Recorded observation years are retained. Older files without time metadata
#'   use a first observation year of 2000.
#' @param output_dir Character, the directory where simulation results will be saved.(default is the current working directory).
#' @param parameters A list containing the custom initial values for the parameters (default is NULL).
#' @param parameters.L A list containing the custom lower bounds for the parameters (default is NULL).
#' @param parameters.U A list containing the custom upper bounds for the parameters (default is NULL).
#' @param map A list containing the custom values for the map elements (default is NULL).
#' @param M Natural mortality rate per model time step used in every fit. The
#'   default, NULL, uses the natural mortality rate recorded in each replicate
#'   file by sim_data(). A supplied value must equal the recorded rate unless
#'   allow_M_mismatch is TRUE. Files without a recorded rate require M.
#' @param ncores Integer. Number of CPU cores to use. 1 = sequential (default).
#'   Uses socket workers on all platforms.
#'   Use \code{parallel::detectCores()} to see available cores.
#' @param allow_M_mismatch Logical. FALSE (default) stops when a supplied M
#'   differs from the natural mortality rate recorded in a replicate file.
#'   TRUE fits the supplied M, for a study of misspecified natural mortality.
#'
#' @inheritParams run_acl
#' @return A list containing the results of the stock assessment model. Failed
#'   fits have class "alscl_fit_error" and contain converge = "FAILED", error
#'   and iter. Each result, including
#'   failures, replaces its result_rep_<iter> file in output_dir. Storage errors
#'   stop the batch rather than leave an old success file as the current result.
#'   Results do not contain the TMB object obj, in memory or in the saved
#'   files; use refit_model() on a result when a TMB object is needed. Each
#'   result records the natural mortality rate in simulation_M: the rate used
#'   (used), the rate recorded in the replicate file (recorded, NA when
#'   absent) and where the rate used came from (source).
#' @examples
#' \donttest{
#' # Simulate one replicate of a ten-year survey and fit ACL to it, with the
#' # growth parameters fixed as in the YTF_example settings.
#' pa <- initialize_params(species = "flatfish", nyear = 12, burn_in = 2)
#' folder <- tempfile("simulation")
#' sm <- sim_data(sim_cal(pa), pa, iter_range = 1, output_dir = folder)
#' cfg <- YTF_example$fit_config$acl
#' fits <- sim_model(iter_range = 1, sim_data_path = folder, output_dir = folder,
#'   parameters = cfg$parameters, map = cfg$map, model = "acl")
#' summary(fits$result_rep_1)$diagnostics
#'
#' # The fit is also saved next to the simulated replicate
#' list.files(folder)
#' unlink(folder, recursive = TRUE)
#' }
#' @export
#' @param train_times Number of optimization passes per independent start.
#' @param control Named nlminb control settings.
#' @param model Model fitted to each simulation, "acl" (default) or "alscl".
#' @param nstarts Positive integer; number of independent optimization starts
#'   per simulated dataset. Defaults to 1, independently of ncores. Starts run
#'   sequentially within each replicate; ncores controls parallel replicates.
#' @details M and F are per model time step, including quarterly simulations.
#'   Each replicate uses one fitting worker, including when nstarts is greater
#'   than 1. When replicates run on parallel workers (ncores greater than 1),
#'   each worker computes standard errors on one core to avoid nested
#'   parallelism. With ncores = 1 the standard errors use the session setting
#'   of alscl_speed(); the results are identical. Each
#'   successful result retains nstarts, workers and start_diagnostics from the
#'   core fit. train_times controls successive optimization passes from each
#'   start, whereas nstarts controls independent initial values. Model-specific
#'   parameters and maps must match the selected model. sim_acl() retains the
#'   original ACL interface; sim_alscl()
#'   provides the corresponding ALSCL convenience interface.
#'   Recorded survey catchability must agree with its logistic metadata before
#'   fitting. Older files with only valid logistic metadata remain supported;
#'   if metadata are absent, a logistic curve is recovered from q_surv and
#'   checked against the complete recorded vector.
#'   Standard errors are computed for every replicate because
#'   summarize_simulations() uses them for interval coverage.
sim_model <- function(iter_range = 4:100, sim_data_path = ".", output_dir = ".",
                    parameters = NULL, parameters.L = NULL, parameters.U = NULL,
                    map = NULL, M = NULL, ncores = 1, train_times = 1, control = list(),
                    F_structure = c("group_year", "year"), polish = TRUE,
                    model = c("acl", "alscl"), nstarts = 1, allow_M_mismatch = FALSE) {
  model <- match.arg(model)
  F_structure <- match.arg(F_structure)
  ncores <- .acl_positive_integer(ncores, "ncores")
  nstarts <- .acl_positive_integer(nstarts, "nstarts")
  if (!is.numeric(iter_range) || !length(iter_range) || any(!is.finite(iter_range)) ||
      any(iter_range < 0 | iter_range != floor(iter_range) | iter_range > .Machine$integer.max) ||
      anyDuplicated(iter_range))
    stop("iter_range must contain distinct nonnegative integer replicate IDs.", call. = FALSE)
  .acl_single_M(M, "sim_model()")
  if (!is.null(M)) .acl_scalar(M, "M", 0)
  if (!is.logical(allow_M_mismatch) || length(allow_M_mismatch) != 1L || is.na(allow_M_mismatch))
    stop("allow_M_mismatch must be TRUE or FALSE.", call. = FALSE)
  # Force caller expressions before serializing the closure to socket workers.
  # Global variables referenced by promises are not exported by parLapply().
  force(sim_data_path)
  force(output_dir)
  # Resolve natural mortality for every readable replicate before any fit, so
  # that a wrong M stops the call instead of producing one failure per file.
  # Unreadable files are left to fit_one(), which records them as failures.
  for (iter in iter_range) {
    s <- tryCatch(.acl_read_simulation(sim_data_path, iter), error = function(e) NULL)
    if (!is.null(s)) .acl_simulation_M(s, M, allow_M_mismatch, .acl_replicate_id(iter))
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  .acl_compile(toupper(model)) # compile once in the parent before any worker starts
  fit_args <- list(parameters = parameters, parameters.L = parameters.L,
    parameters.U = parameters.U, map = map, train_times = train_times,
    control = control, silent = TRUE, F_structure = F_structure, polish = polish,
    ncores = 1L, nstarts = nstarts)
  fit_one <- function(iter) {
    started <- proc.time()[["elapsed"]]
    id <- .acl_replicate_id(iter)
    mortality <- NULL
    result <- tryCatch({
      s <- .acl_read_simulation(sim_data_path, iter)
      step <- if (!is.null(s$growth_step)) s$growth_step else if(length(s$ages)>1) diff(s$ages)[1] else 1
      tables <- .acl_simulation_to_tables(s)
      catchability <- .acl_simulation_catchability(s)
      mortality <- .acl_simulation_M(s, M, allow_M_mismatch, id)
      do.call(if (model == "acl") run_acl else run_alscl,
        c(tables, list(rec.age = s$ages[1], nage = s$nage, M = mortality$used,
        sel_L50 = catchability$L50, sel_L95 = catchability$L95,
        len_mid = s$len_mid, len_border = s$len_border, growth_step = step), fit_args))
    }, error = function(e) .acl_fit_error(conditionMessage(e), iter = iter))
    # A TMB object holds session-specific pointers and large derivative tapes.
    # It cannot be used after save() or transfer from a socket worker, so the
    # result stays portable, as in .acl_batch_fit().
    result$obj <- NULL
    result$iter <- iter
    if (!is.null(mortality)) result$simulation_M <- mortality
    if (is.null(result$elapsed)) result$elapsed <- unname(proc.time()[["elapsed"]] - started)
    .acl_save_simulation_result(result, file.path(output_dir, paste0("result_rep_", id)))
    result
  }
  results <- .acl_cluster_lapply(iter_range, fit_one, ncores, model)
  names(results) <- paste0("result_rep_", .acl_replicate_id(iter_range))
  results
}

#' Fit simulation replicates with ACL
#' @inheritParams sim_model
#' @return The named list of replicate fits or error records returned by sim_model().
#' @examples
#' \donttest{
#' # Simulate two replicates of a ten-year survey and fit ACL to each, with
#' # the growth parameters fixed as in the YTF_example settings.
#' pa <- initialize_params(species = "flatfish", nyear = 12, burn_in = 2)
#' folder <- tempfile("simulation")
#' sm <- sim_data(sim_cal(pa), pa, iter_range = 1:2, output_dir = folder)
#' cfg <- YTF_example$fit_config$acl
#' fits <- sim_acl(iter_range = 1:2, sim_data_path = folder, output_dir = folder,
#'   parameters = cfg$parameters, map = cfg$map)
#' sapply(fits, function(fit) fit$diagnostics$numerical_ok)
#' unlink(folder, recursive = TRUE)
#' }
#' @export
sim_acl <- function(iter_range = 4:100, sim_data_path = ".", output_dir = ".",
                    parameters = NULL, parameters.L = NULL, parameters.U = NULL,
                    map = NULL, M = NULL, ncores = 1, train_times = 1, control = list(),
                    F_structure = c("group_year", "year"), polish = TRUE,
                    nstarts = 1, allow_M_mismatch = FALSE) {
  sim_model(iter_range, sim_data_path, output_dir, parameters, parameters.L,
    parameters.U, map, M, ncores, train_times, control, F_structure, polish,
    model = "acl", nstarts = nstarts, allow_M_mismatch = allow_M_mismatch)
}

#' Fit simulation replicates with ALSCL
#' @param ... Arguments passed to sim_model(), excluding model and nstarts.
#' @inheritParams sim_model
#' @return The named list of replicate fits or error records returned by sim_model().
#' @examples
#' \donttest{
#' # Simulate one replicate of a ten-year survey and fit ALSCL to it, with the
#' # growth parameters fixed as in the YTF_example settings. One fishing
#' # mortality rate shared by all lengths in each year keeps the fit short.
#' pa <- initialize_params(species = "flatfish", nyear = 12, burn_in = 2)
#' folder <- tempfile("simulation")
#' sm <- sim_data(sim_cal(pa), pa, iter_range = 1, output_dir = folder)
#' cfg <- YTF_example$fit_config$alscl
#' fits <- sim_alscl(iter_range = 1, sim_data_path = folder, output_dir = folder,
#'   parameters = cfg$parameters, map = cfg$map, F_structure = "year")
#' summary(fits$result_rep_1)$diagnostics
#' unlink(folder, recursive = TRUE)
#' }
#' @export
sim_alscl <- function(..., nstarts = 1) sim_model(..., model = "alscl", nstarts = nstarts)

# Replicate IDs as file-name text. paste0() of a double depends on
# options(scipen) and gives "1e+05" for 100000; the integer form does not.
.acl_replicate_id <- function(iter) sprintf("%d", as.integer(iter))

.acl_read_simulation <- function(sim_data_path, iter) {
  e <- new.env(parent = emptyenv())
  file <- file.path(sim_data_path, paste0("sim_rep", .acl_replicate_id(iter)))
  # Earlier versions named files with the default number format (sim_rep1e+05).
  legacy <- file.path(sim_data_path, paste0("sim_rep", iter))
  if (!file.exists(file) && file.exists(legacy)) file <- legacy
  load(file, envir = e)
  if (is.null(e$sim.data)) stop("Simulation file does not contain sim.data.")
  e$sim.data
}

# Failure record of a batch or simulation fit. It stays a list with the same
# fields as before, so tests of x$error and x$converge keep working.
.acl_fit_error <- function(message, ...)
  structure(list(converge = "FAILED", error = message, ...),
            class = c("alscl_fit_error", "list"))

# Natural mortality rate per model time step recorded by sim_data(): a constant
# matrix M_at_age (age-based operating model) or M_at_len (length-based).
# Returns NULL for files that do not record it.
.acl_simulation_recorded_M <- function(simulation, id) {
  value <- simulation$M_at_age %||% simulation$M_at_len
  if (is.null(value)) return(NULL)
  value <- as.numeric(value)
  if (!length(value) || any(!is.finite(value)) || any(value < 0))
    stop("The natural mortality rate recorded in sim_rep", id,
         " must be finite and nonnegative.", call. = FALSE)
  if (diff(range(value)) > 1e-8 * max(1, max(value)))
    stop("The natural mortality rate recorded in sim_rep", id, " varies by time step, ",
         "age or length bin. The models assume one constant rate. Supply M and set ",
         "allow_M_mismatch = TRUE to fit a constant rate.", call. = FALSE)
  value[1L]
}

# The natural mortality rate to fit, with its origin. A supplied M that differs
# from the recorded rate is an error unless the caller allows the mismatch.
.acl_simulation_M <- function(simulation, M, allow_mismatch, id) {
  recorded <- if (!is.null(M) && allow_mismatch)
    tryCatch(.acl_simulation_recorded_M(simulation, id), error = function(e) NULL)
    else .acl_simulation_recorded_M(simulation, id)
  if (is.null(M)) {
    if (is.null(recorded))
      stop("sim_rep", id, " does not record a natural mortality rate. Supply M.", call. = FALSE)
    return(list(used = recorded, recorded = recorded, source = "simulation file"))
  }
  if (!is.null(recorded) && !allow_mismatch &&
      abs(M - recorded) > 1e-8 * max(1, abs(recorded)))
    stop("M = ", format(M), " differs from the natural mortality rate ", format(recorded),
         " recorded in sim_rep", id, ". Omit M to use the recorded rate, or set ",
         "allow_M_mismatch = TRUE to fit a different rate.", call. = FALSE)
  list(used = M, recorded = if (is.null(recorded)) NA_real_ else recorded, source = "argument M")
}

.acl_simulation_catchability <- function(simulation) {
  q <- simulation$q_surv
  mid <- simulation$len_mid
  if (!is.null(q) && (!is.numeric(q) || length(q) != length(mid) ||
      any(!is.finite(q)) || any(q < 0 | q > 1)))
    stop("Simulation q_surv must contain one probability per length bin.", call. = FALSE)
  L50 <- simulation$q_surv_L50
  L95 <- simulation$q_surv_L95
  if (is.null(L50) || is.null(L95)) {
    valid <- is.finite(q) & q > 0 & q < 1
    # Rounded probabilities near one have inaccurate logits. Prefer the
    # interior of the curve, then verify the recovered curve at every bin.
    interior <- is.finite(q) & q > 1e-6 & q < 1 - 1e-6
    if (sum(interior) >= 2L) valid <- interior
    if (sum(valid) < 2L)
      stop("Simulation requires logistic survey catchability metadata.", call. = FALSE)
    coefficients <- stats::coef(stats::lm(stats::qlogis(q[valid]) ~ mid[valid]))
    inferred50 <- unname(-coefficients[1] / coefficients[2])
    inferred95 <- unname(inferred50 + log(19) / coefficients[2])
    L50 <- L50 %||% inferred50
    L95 <- L95 %||% inferred95
  }
  .acl_scalar(L50, "simulation q_surv_L50")
  .acl_scalar(L95, "simulation q_surv_L95")
  if (L95 <= L50)
    stop("Simulation q_surv_L95 must exceed q_surv_L50.", call. = FALSE)
  if (!is.null(q) && !.acl_simulation_probabilities_match(q, mat_func(L50, L95, mid)))
    stop("Simulation q_surv does not match its logistic catchability metadata; ",
         "regenerate the simulation with matching biological inputs.", call. = FALSE)
  list(L50 = unname(L50), L95 = unname(L95))
}

#' Convert one simulated replicate to the tables used for fitting
#'
#' Converts the output of \code{\link{sim_data}} to the three tables that
#' \code{\link{run_acl}} and \code{\link{run_alscl}} take. Rows are length
#' bins, labelled by the length-bin midpoints. Columns are the model time
#' steps recorded in the replicate.
#'
#' @param sm A simulated replicate: the list returned by \code{sim_data()} or
#'   the \code{sim.data} object loaded from a \code{sim_rep<id>} file.
#' @param pa Optional parameter list from \code{\link{initialize_params}} that
#'   generated the replicate. It supplies \code{len_mid}, \code{growth_step}
#'   and \code{first.year} for older replicates that do not record them.
#'   Length-bin midpoints in \code{pa} must match those recorded in \code{sm}.
#' @param first_year Optional first observation year. It replaces the years
#'   recorded in \code{sm}.
#' @return A list with data frames \code{data.CatL} (survey catch at length),
#'   \code{data.wgt} (weight at length) and \code{data.mat} (proportion mature
#'   at length). Each has a \code{LengthBin} column followed by one column per
#'   model time step.
#' @details The function stops when the dimensions of \code{SN_at_len},
#'   \code{weight} or \code{mat} do not match the time and length coordinates,
#'   so rows are never recycled. \code{\link{sim_model}}, \code{\link{sim_acl}}
#'   and \code{\link{sim_alscl}} apply the same conversion to saved replicates.
#' @examples
#' pa <- initialize_params(species = "flatfish", nyear = 6, burn_in = 2)
#' folder <- tempfile("simulation")
#' sm <- sim_data(sim_cal(pa), pa, iter_range = 1, output_dir = folder)
#' tables <- simulation_to_tables(sm, pa)
#' names(tables)
#' dim(tables$data.CatL)
#' unlink(folder, recursive = TRUE)
#' @export
simulation_to_tables <- function(sm, pa = NULL, first_year = NULL)
  .acl_simulation_to_tables(sm, pa, first_year)

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
