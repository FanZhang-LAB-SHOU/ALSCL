#' Run stock assessment model (with optional parallel processing)
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
#' @return A list containing the results of the stock assessment model.
#' @export
#' @param train_times Number of optimization passes per replicate.
#' @param control Named nlminb control settings.
sim_acl <- function(iter_range = 4:100, sim_data_path = ".", output_dir = ".",
                    parameters = NULL, parameters.L = NULL, parameters.U = NULL,
                    map = NULL, M = 0.2, ncores = 1, train_times = 1, control = list(),
                    F_structure = c("group_year", "year"), polish = TRUE) {
  F_structure <- match.arg(F_structure)
  ncores <- .acl_positive_integer(ncores, "ncores")
  if (!length(iter_range)) stop("iter_range must not be empty.")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  info <- .acl_compile("ACL")
  cache <- dirname(dirname(info$cpp_path))
  # Force caller expressions before serializing the closure to socket workers.
  # Global variables referenced by promises are not exported by parLapply().
  force(sim_data_path)
  force(output_dir)
  fit_args <- list(parameters = parameters, parameters.L = parameters.L,
    parameters.U = parameters.U, map = map, M = M, train_times = train_times,
    control = control, silent = TRUE, F_structure = F_structure, polish = polish)
  fit_one <- function(iter) {
    tryCatch({
      e <- new.env(parent = emptyenv())
      load(file.path(sim_data_path, paste0("sim_rep", iter)), envir = e)
      s <- e$sim.data
      if (is.null(s)) stop("Simulation file does not contain sim.data.")
      step <- if (!is.null(s$growth_step)) s$growth_step else if(length(s$ages)>1) diff(s$ages)[1] else 1
      years <- .acl_simulation_years(s, step)
      to_frame <- function(x) {
        out <- data.frame(LengthBin = as.character(s$len_mid), x, check.names = FALSE)
        names(out) <- c("LengthBin", as.character(years))
        out
      }
      L50 <- s$q_surv_L50; L95 <- s$q_surv_L95
      if (is.null(L50) || is.null(L95)) {
        valid <- is.finite(s$q_surv) & s$q_surv > 0 & s$q_surv < 1
        if (sum(valid)<2L) stop("Simulation requires logistic survey catchability metadata.")
        coefficients <- stats::coef(stats::lm(stats::qlogis(s$q_surv[valid]) ~ s$len_mid[valid]))
        L50 <- -coefficients[1]/coefficients[2]; L95 <- L50+log(19)/coefficients[2]
      }
      result <- do.call(run_acl, c(list(data.CatL = to_frame(t(s$SN_at_len)),
        data.wgt = to_frame(s$weight), data.mat = to_frame(s$mat),
        rec.age = s$ages[1], nage = s$nage, sel_L50 = unname(L50), sel_L95 = unname(L95),
        len_mid = s$len_mid, len_border = s$len_border, growth_step = step), fit_args))
      save(result, file = file.path(output_dir, paste0("result_rep_", iter)))
      result
    }, error = function(e) list(converge = "FAILED", error = conditionMessage(e), iter = iter))
  }
  ncores <- min(ncores, length(iter_range))
  if (ncores == 1L) results <- lapply(iter_range, fit_one) else {
    cl <- parallel::makeCluster(ncores); on.exit(parallel::stopCluster(cl), add = TRUE)
    initialize_worker <- function(paths, cache, settings) {
      .libPaths(paths); loadNamespace("ALSCL"); options(ALSCL.tmb.cache = cache); options(settings); NULL
    }
    # Set library paths before deserialization can load an older ALSCL namespace.
    environment(initialize_worker) <- baseenv()
    parallel::clusterCall(cl, initialize_worker, .libPaths(), cache, .acl_worker_options())
    results <- parallel::parLapply(cl, iter_range, fit_one)
  }
  names(results) <- paste0("result_rep_", iter_range)
  results
}
