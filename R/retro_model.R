utils::globalVariables(c("Variable", "RetrospectiveYear", "Screen", "Label"))

# Time-dependent maps describe the complete input grid. Truncate their
# column-major entries with each peel, retaining ties and fixed (NA) entries.
.acl_retro_map <- function(fit_args, peel, model_type) {
  mapping <- fit_args$map
  if (is.null(mapping) || !is.list(mapping)) return(mapping)
  periods <- ncol(fit_args$data.CatL) - 1L
  kept <- periods - peel
  for (name in c("dev_log_R", "dev_log_F")) {
    value <- mapping[[name]]
    if (is.null(value)) next
    groups <- 1L
    if (name == "dev_log_F") {
      structure <- match.arg(fit_args$F_structure %||% "group_year",
                             c("group_year", "year"))
      if (structure == "group_year")
        groups <- if (model_type == "acl")
          .acl_positive_integer(fit_args$nage, "nage", 2L) else nrow(fit_args$data.CatL)
    }
    if (length(value) != groups * periods)
      stop("Map length does not match parameter ", name,
           " on the complete input time grid.", call. = FALSE)
    if (!is.factor(value))
      stop("map entries must be factors (factor(NA) fixes a parameter), or NULL to unfix.",
           call. = FALSE)
    if (peel > 0L) {
      # Unused levels would create parameters with no retained observations
      # in TMB. Dropping them preserves all equality relationships that remain.
      mapping[[name]] <- .acl_drop_map_levels(value[seq_len(groups * kept)])
    }
  }
  mapping
}

# Retain the optimizer's explanation and finishing record without a live object.
# Unknown fields in legacy or failed fits stay missing, not invented successes.
.acl_retro_optimizer_details <- function(fit) {
  scalar <- function(x, missing) {
    if (length(x) == 1L && !is.na(x)) x else missing
  }
  history <- fit$optimizer_history %||% fit$raw_opt$optimizer_history
  codes <- messages <- NA_character_
  if (is.list(history) && length(history)) {
    codes <- paste(vapply(history, function(x)
      as.character(scalar(x$convergence, NA_integer_)), character(1)), collapse = "; ")
    messages <- paste(vapply(history, function(x)
      as.character(scalar(x$message, NA_character_)), character(1)), collapse = "; ")
  }
  data.frame(
    optimizer_message = scalar(fit[["converge"]] %||% fit$opt$message, NA_character_),
    selected_pass = scalar(fit$raw_opt$selected_pass %||% fit$opt$selected_pass, NA_integer_),
    optimizer_codes = codes, optimizer_messages = messages,
    refinement_status = scalar(fit$refinement$status, NA_character_),
    refinement_steps = scalar(fit$refinement$steps, NA_integer_),
    pre_refinement_max_gradient = scalar(fit$refinement$initial_max_gradient, NA_real_),
    stringsAsFactors = FALSE)
}

# A scalar that the map fixes must have one value in the full fit and in every
# peel. Without an explicit value, mean_log_R starts at a value derived from
# the observations, which each peel would otherwise derive from its own
# truncated data. Resolve it once from the complete data.
.acl_retro_fixed_scalars <- function(fit_args) {
  mapping <- fit_args$map
  if (!is.list(mapping) || is.data.frame(mapping)) return(fit_args)
  entry <- mapping[["mean_log_R"]]
  fixed <- length(entry) == 1L && is.na(entry)
  if (!fixed || !is.null(fit_args$parameters[["mean_log_R"]])) return(fit_args)
  survey <- tryCatch(.acl_survey_data(fit_args$data.CatL), error = function(e) NULL)
  if (is.null(survey)) return(fit_args)
  # The same rule as the fitting setup, applied to all periods.
  totals <- colSums(survey$observed, na.rm = TRUE)
  value <- log(mean(totals[totals > 0]))
  if (!is.finite(value)) return(fit_args)
  parameters <- fit_args$parameters
  if (is.null(parameters)) parameters <- list()
  parameters$mean_log_R <- value
  fit_args["parameters"] <- list(parameters)
  fit_args
}

# Retain compact results rather than serializing a live TMB objective between
# processes. A failed fit still contributes a diagnostic row and a missing rho.
# Peel k removes the last k * peel_step time steps. Warnings are recorded with
# the fit that raised them: a socket worker cannot pass them to the caller.
.acl_retro_fit <- function(peel, fit_args, model_type, silent, peel_step = 1L) {
  started <- proc.time()
  removed <- peel * peel_step
  end_col <- ncol(fit_args$data.CatL) - removed
  years <- suppressWarnings(as.numeric(sub("^X", "",
    colnames(fit_args$data.CatL)[seq.int(2L, end_col)])))
  error <- NULL
  warnings <- character()
  fit <- tryCatch(withCallingHandlers({
    if ("map" %in% names(fit_args))
      fit_args["map"] <- list(.acl_retro_map(fit_args, removed, model_type))
    for (name in c("data.CatL", "data.wgt", "data.mat"))
      fit_args[[name]] <- fit_args[[name]][, seq_len(end_col), drop = FALSE]
    do.call(if (model_type == "acl") run_acl else run_alscl, fit_args)
  }, warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  }), error = function(e) {
    error <<- conditionMessage(e)
    NULL
  })
  if (!is.null(fit$year)) years <- fit$year
  elapsed <- (proc.time() - started)[["elapsed"]]
  diagnostics <- cbind(data.frame(Peel = peel,
    RetrospectiveYear = tail(years, 1L), elapsed = elapsed,
    error = if (is.null(error)) "" else error), .acl_fit_status(fit, error),
    .acl_retro_optimizer_details(fit),
    data.frame(warnings = paste(unique(warnings), collapse = "; "), stringsAsFactors = FALSE))
  if (!silent) message(.acl_retro_progress(peel, elapsed, error))
  list(peel = peel, year = years, diagnostics = diagnostics,
       variables = list(B = fit$report$B, Rec = fit$report$Rec,
                        SSB = fit$report$SSB, N = fit$report$N))
}

.acl_retro_progress <- function(peel, elapsed, error = NULL) {
  failed <- !is.null(error) && nzchar(error)
  sprintf("  %s: %.1f sec%s", if (peel == 0L) "Full model" else paste("Peel", peel),
          elapsed, if (failed) paste0(" (failed: ", error, ")") else "")
}

.acl_retro_wrapper <- function(call, frame, model) {
  explicit <- setdiff(names(as.list(call)[-1L]), "...")
  args <- mget(explicit, envir = frame, inherits = FALSE)
  extra <- eval(quote(list(...)), envir = frame)
  extra_names <- names(extra) %||% rep("", length(extra))
  named <- nzchar(extra_names)
  if (anyNA(extra_names) || anyDuplicated(extra_names[named]))
    stop("Named additional retrospective arguments must be unique.", call. = FALSE)
  args[extra_names[named]] <- extra[named]
  args$model_type <- model
  do.call(retro_model, c(args, unname(extra[!named])))
}

#' Retrospective Analysis for ACL or ALSCL Models
#'
#' Conduct a retrospective analysis by sequentially removing the most recent
#' time steps of data and re-fitting the model. Computes Mohn's rho for SSB,
#' Recruitment, Biomass, and Abundance to quantify retrospective bias.
#' Supports both ACL and ALSCL model types via the `model_type` argument.
#'
#' @param nyear Integer. Number of retrospective peels. Default is 5. Each
#'   successive peel removes peel_step further model time steps. With the
#'   default peel_step = 1, one peel removes one model time step (one quarter
#'   for quarterly data).
#' @param data.CatL Survey abundance indices at length or the same named input bundle used
#'   by [run_acl()] or [run_alscl()]. For example, `retro_acl(x, nyear = 3)`.
#' @param data.wgt The weight data.
#' @param data.mat The maturity data.
#' @param rec.age The recruitment age.
#' @param nage The number of age classes.
#' @param M Natural mortality per model time step.
#' @param sel_L50 Length at 50 percent survey catchability.
#' @param sel_L95 Length at 95 percent survey catchability.
#' @param model_type Character. Model to use: `"acl"` (default) or `"alscl"`.
#' @param model Same as model_type, accepted for consistency with the other
#'   workflow functions. Supply one of the two.
#' @param growth_step Time step in years. NULL uses recruitment age when below 1, otherwise 1.
#' @param parameters Optional custom starting parameter list.
#' @param parameters.L Optional lower bounds for parameters.
#' @param parameters.U Optional upper bounds for parameters.
#' @param map Optional TMB map argument for fixing or tying parameters.
#'   Maps for dev_log_R and dev_log_F must match the complete input time grid.
#'   Each peel retains the corresponding earliest periods, preserving fixed
#'   entries and ties and dropping unused factor levels. F maps use group-by-time
#'   column-major order (one group with F_structure = "year"). Other maps,
#'   including dev_log_N0 and named NULL releases, are unchanged.
#' @param len_mid Optional numeric vector of length bin midpoints.
#' @param len_border Optional numeric vector of length bin borders.
#' @param len_lower Deprecated. Optional lower bin boundaries (ALSCL only). The
#'   first entry must be -Inf and the remaining entries must match len_border,
#'   so the argument cannot change a fit. It will be removed.
#' @param len_upper Deprecated. Optional upper bin boundaries (ALSCL only). The
#'   final entry must be Inf and the preceding entries must match len_border,
#'   so the argument cannot change a fit. It will be removed.
#' @param train_times Positive integer. Number of consecutive optimization passes
#'   per start. Default is 1; nstarts controls the number of independent starts.
#' @param nstarts Positive integer. Number of independent starts per full/peel
#'   fit, run sequentially within each fit. Defaults to 1 or the bundle's nstarts.
#' @param ncores Integer. Number of socket workers for the full fit and the
#'   peels. Default is 1. With more than one worker, the full fit and the peels
#'   run in one batch; estimates are the same as with one worker. A bundle's
#'   fitting ncores is ignored: specify this argument explicitly. Each fit runs
#'   its nstarts sequentially with ncores = 1, avoiding nested fitting workers.
#' @param silent Logical. Suppress progress messages when TRUE. Numerical-screen
#'   warnings are still reported. Default is FALSE.
#' @param peel_step Positive integer. Number of model time steps that each
#'   successive peel removes. Default is 1. For quarterly data, peel_step = 4
#'   gives annual peels: peel k then ends k years before the terminal period.
#' @param structure,start_spread,t0_lower Passed to every full and peel fit; see
#'   \code{\link{run_alscl}}. A bundle's own settings are used unless these are
#'   supplied explicitly.
#' @param bounds Passed to every full and peel fit of ACL; see
#'   \code{\link{run_acl}}. A bundle's own setting is used unless this is
#'   supplied explicitly. ALSCL has no such argument.
#' @param plot Logical. If TRUE, include plot in return value. Default is FALSE.
#'   When no finite estimates are available, return plot = NULL with a warning;
#'   fit_diagnostics and errors remain available.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting (default 1.5).
#' @param point_size Numeric or NULL. Point size for endpoints; NULL inherits the global point_size setting (default 2.5).
#' @param point_shape Numeric. Point shape for endpoints. Default is 21.
#' @param facet_scales Character. Facet scales argument. Default is "free".
#' @param facet_ncol Integer or NULL. Number of facet columns.
#' @param facet_nrow Integer or NULL. Number of facet rows.
#' @param title Character or NULL. Custom plot title.
#' @param xlab Character or NULL. Custom x-axis label.
#' @param ylab Character or NULL. Custom y-axis label.
#' @param font_family Character or NULL. Font family.
#' @param title_size Numeric or NULL. Title size in pt.
#' @param axis_title_size Numeric or NULL. Axis title size in pt.
#' @param axis_text_size Numeric or NULL. Axis tick label size in pt.
#' @param strip_text_size Numeric or NULL. Facet label size in pt.
#' @param legend_text_size Numeric or NULL. Legend text size in pt.
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks.
#' @param base_theme Character or NULL. Base ggplot2 theme name.
#' @param title_hjust Numeric or NULL. Title horizontal alignment.
#' @param rho_digits Integer. Decimal places for Mohn's rho display. Default is 4.
#' @param rho_position Character. Position of rho text. Default is "top_right".
#' @param rho_size Numeric. Font size of rho text. Default is 3.5.
#' @param ... The former argument names facet_col and facet_row, accepted with a warning.
#' @inheritParams run_acl
#' @details Bundle settings use the same precedence as [run_acl()]: shared
#'   fit_args, selected fit_config, then explicit call arguments. Explicit map,
#'   parameters and control replace the complete corresponding list, including
#'   NULL. zero_action, control and nstarts are forwarded to every full/peel fit.
#'   The full fit and every requested peel must pass the numerical screen, and
#'   have finite terminal estimates with a nonzero reference, before a quantity's
#'   Mohn's rho is reported. Invalid or failed fits are not silently dropped.
#'
#'   A parameter that the map fixes has the same value in the full fit and in
#'   every peel. When map fixes mean_log_R and parameters gives no value for
#'   it, the value is derived once from the complete observations (the log of
#'   the mean total survey index over periods) and used in every fit. Earlier
#'   versions derived it again from the truncated data of each peel.
#'
#'   Warnings raised while fitting are recorded in fit_diagnostics$warnings for
#'   the fit that raised them, including fits on socket workers, and one
#'   summary warning names these fits.
#'
#'   Mohn's rho is the mean over peels of the relative difference between the
#'   terminal estimate of a peel and the estimate of the full fit for the same
#'   period. With peel_step = 1 on quarterly data this is a mean over quarterly
#'   peels. Use peel_step = 4 for a rho based on annual peels.
#' @return A list containing `results`, `rho_text`, `last_points`, `model_type`,
#'   and optionally `plot`. `fit_diagnostics` records the full fit (Peel = 0)
#'   and every requested peel, including errors and numerical status.
#'   It also retains the selected optimizer message and pass, all pass codes
#'   and messages, the refinement status, steps and pre-refinement gradient,
#'   and the warnings raised by each fit.
#'   Missing records from older or failed fits remain NA. A successful pass can
#'   coexist with a failed restart in the history; read the selected pass and
#'   final numerical screen together.
#'   `rho_by_peel` contains screened Rho, diagnostic RawRho and Valid for each
#'   quantity and peel. `rho_text$Rho` is NA when any required fit or endpoint
#'   is invalid. `raw_rho_text` retains an unscreened mean for diagnosis only;
#'   it is NA if any terminal comparison is missing. `errors` lists fit errors.
#'   `results` retains available estimates, with NumericalOK and RawRho flags.
#'   `peel_step` records the number of time steps removed per peel and
#'   `workers` the number of workers used.
#' @export
#' @examples
#' \donttest{
#' # Two retrospective peels of the ACL model
#' retro <- retro_model(nyear = 2, data.CatL = YTF_example, model_type = "acl",
#'                      silent = TRUE)
#' retro$rho_text
#' retro$fit_diagnostics[, c("Peel", "RetrospectiveYear", "numerical_ok")]
#' plot_retro(retro)
#' }
retro_model <- function(nyear = 5, data.CatL, data.wgt, data.mat,
                        rec.age, nage, M, sel_L50, sel_L95,
                        model_type = c("acl", "alscl"),
                        growth_step = NULL,
                        parameters = NULL, parameters.L = NULL, parameters.U = NULL,
                        map = NULL, len_mid = NULL, len_border = NULL,
                        len_lower = NULL, len_upper = NULL,
                        train_times = 1, ncores = 1, silent = FALSE,
                        plot = FALSE,
                        line_size = NULL, point_size = NULL, point_shape = 21,
                        facet_scales = "free", facet_ncol = NULL, facet_nrow = NULL,
                        title = NULL, xlab = NULL, ylab = NULL,
                        font_family = NULL, title_size = NULL,
                        axis_title_size = NULL, axis_text_size = NULL,
                        strip_text_size = NULL, legend_text_size = NULL,
                        x_breaks = NULL, base_theme = NULL, title_hjust = NULL,
                        rho_digits = 4, rho_position = "top_right", rho_size = 3.5,
                        F_structure = c("group_year", "year"), polish = TRUE,
                        zero_action = c("missing", "error"), control = list(), nstarts = 1,
                        model = NULL, peel_step = 1, structure = list(), start_spread = 0.15, t0_lower = 0,
                        bounds = c("default", "wide"), ...) {
  .acl_check_flag(plot, "plot")
  .acl_check_flag(silent, "silent")
  renamed <- .acl_renamed(list(...), "retro_model")
  if (is.null(facet_ncol)) facet_ncol <- renamed$facet_ncol
  if (is.null(facet_nrow)) facet_nrow <- renamed$facet_nrow
  if (!is.null(model)) {
    if (!missing(model_type))
      stop("Supply either model or model_type, not both.", call. = FALSE)
    model_type <- model
  }
  model_type <- match.arg(model_type)
  supplied <- names(as.list(match.call())[-1L])
  if (is.list(nyear) && !is.data.frame(nyear)) {
    # A bundle in the first position. A number that follows it positionally
    # is the number of peels, as in retro_acl(x, 3).
    peels <- 5L
    if (!missing(data.CatL)) {
      if (!is.numeric(data.CatL) || length(data.CatL) != 1L)
        stop("The first argument is an input bundle, so data.CatL must not be supplied as well. ",
             "Give the number of peels by name, for example retro_model(x, nyear = 3).",
             call. = FALSE)
      peels <- data.CatL
    }
    data.CatL <- nyear
    nyear <- peels
    supplied <- union(setdiff(supplied, "nyear"), "data.CatL")
  }
  nyear <- .acl_positive_integer(nyear, "nyear")
  ncores <- .acl_positive_integer(ncores, "ncores")
  peel_step <- .acl_positive_integer(peel_step, "peel_step")
  if (!is.null(len_lower) || !is.null(len_upper)) .acl_deprecated_bin_bounds("retro_model")
  fit_fun <- if (model_type == "acl") run_acl else run_alscl
  fit_names <- intersect(names(formals(fit_fun)), names(formals(retro_model)))
  # Peel workers and within-fit starts are separate controls. Only explicit
  # settings override a bundle, and single-bracket assignment preserves NULL.
  fit_names <- setdiff(fit_names, c("ncores", "silent", "output"))
  if (is.list(data.CatL) && !is.data.frame(data.CatL)) {
    explicit <- intersect(setdiff(supplied, "data.CatL"), fit_names)
    fit_args <- .acl_bundle_args(data.CatL, model_type,
                                mget(explicit, envir = environment()))
  } else {
    fit_args <- mget(fit_names, envir = environment())
  }
  fit_args[c("ncores", "silent", "output")] <- list(1L, TRUE, FALSE)
  if (!"nstarts" %in% names(fit_args)) fit_args$nstarts <- 1L
  if (!is.data.frame(fit_args$data.CatL) && !is.matrix(fit_args$data.CatL))
    stop("data.CatL must be a data frame, matrix or input bundle.", call. = FALSE)
  labels <- colnames(fit_args$data.CatL)
  years <- suppressWarnings(as.numeric(sub("^X", "", labels[-1L])))
  if (length(labels) != ncol(fit_args$data.CatL) || any(!is.finite(years)) ||
      any(diff(years) <= 0))
    stop("Time columns must have increasing numeric labels before retrospective fitting.", call. = FALSE)
  if (as.double(nyear) * peel_step > ncol(fit_args$data.CatL) - 3L)
    stop("Every retrospective peel must retain at least two time steps. ",
         "nyear * peel_step is ", as.double(nyear) * peel_step, " and the data have ",
         ncol(fit_args$data.CatL) - 1L, " time steps.", call. = FALSE)
  fit_args <- .acl_retro_fixed_scalars(fit_args)

  progress <- function(...) if (!silent) message(...)
  t_grand <- proc.time()
  # The full fit is one task of the batch, so no worker waits for it.
  ncores_use <- .acl_workers(min(ncores, nyear + 1L))
  # Retrospective results use point estimates and the numerical screen only,
  # so skip the delta-method standard errors of derived quantities.
  if (is.null(getOption("ALSCL.se_level"))) {
    old_se <- options(ALSCL.se_level = "hessian")
    on.exit(options(old_se), add = TRUE)
  }
  if (ncores_use == 1L) {
    progress(sprintf("Fitting full %s model...", toupper(model_type)))
    full <- .acl_retro_fit(0L, fit_args, model_type, silent, peel_step)
    progress(sprintf("Running %d retrospective peels sequentially...", nyear))
    peels <- lapply(seq_len(nyear), .acl_retro_fit, fit_args = fit_args,
                    model_type = model_type, silent = silent, peel_step = peel_step)
  } else {
    progress(sprintf("Fitting the full %s model and %d retrospective peels on %d socket workers...",
                     toupper(model_type), nyear, ncores_use))
    batch <- .acl_cluster_lapply(seq.int(0L, nyear), .acl_retro_fit, ncores_use, model_type,
                                 fit_args = fit_args, model_type = model_type,
                                 silent = TRUE, peel_step = peel_step)
    full <- batch[[1L]]
    peels <- batch[-1L]
    # Messages from socket workers do not reach this session.
    for (fit in batch)
      progress(.acl_retro_progress(fit$peel, fit$diagnostics$elapsed, fit$diagnostics$error))
  }
  fits <- c(list(full), peels)
  fit_diagnostics <- do.call(rbind, lapply(fits, `[[`, "diagnostics"))
  rownames(fit_diagnostics) <- NULL
  warned <- fit_diagnostics$Peel[nzchar(fit_diagnostics$warnings)]
  if (length(warned))
    warning("Warnings were raised while fitting ",
            paste(ifelse(warned == 0L, "the full model", paste("peel", warned)), collapse = ", "),
            ". See the warnings column of fit_diagnostics.", call. = FALSE)
  variables <- c("B", "Rec", "SSB", "N")
  rho_by_peel <- do.call(rbind, lapply(peels, function(peel) {
    do.call(rbind, lapply(variables, function(variable) {
      values <- peel$variables[[variable]]
      full_values <- full$variables[[variable]]
      full_index <- match(tail(peel$year, 1L), full$year)
      reference <- if (length(full_values) == length(full$year) &&
                       !is.na(full_index)) full_values[full_index] else NA_real_
      endpoint <- if (length(values) == length(peel$year)) tail(values, 1L) else NA_real_
      raw_rho <- if (length(endpoint) == 1L && is.finite(endpoint) &&
                    length(reference) == 1L && is.finite(reference) && reference != 0)
        (endpoint - reference) / reference else NA_real_
      valid <- isTRUE(full$diagnostics$numerical_ok) &&
        isTRUE(peel$diagnostics$numerical_ok) && is.finite(raw_rho)
      data.frame(Peel = peel$peel, RetrospectiveYear = tail(peel$year, 1L),
                 Variable = variable, RawRho = raw_rho,
                 Rho = if (valid) raw_rho else NA_real_, Valid = valid)
    }))
  }))
  results <- do.call(rbind, lapply(fits, function(fit) {
    do.call(rbind, lapply(variables, function(variable) {
      values <- fit$variables[[variable]]
      if (is.null(values) || length(values) != length(fit$year)) return(NULL)
      rho_row <- rho_by_peel[rho_by_peel$Peel == fit$peel &
                              rho_by_peel$Variable == variable, , drop = FALSE]
      data.frame(Year = fit$year, Variable = variable, Value = as.numeric(values),
                 RetrospectiveYear = tail(fit$year, 1L),
                 Rho = if (nrow(rho_row)) rho_row$Rho else NA_real_,
                 RawRho = if (nrow(rho_row)) rho_row$RawRho else NA_real_,
                 Peel = fit$peel, NumericalOK = isTRUE(fit$diagnostics$numerical_ok))
    }))
  }))
  if (is.null(results))
    results <- data.frame(Year = numeric(), Variable = character(), Value = numeric(),
      RetrospectiveYear = numeric(), Rho = numeric(), RawRho = numeric(),
      Peel = integer(), NumericalOK = logical())
  results$RetrospectiveYear <- factor(results$RetrospectiveYear,
    levels = sort(unique(results$RetrospectiveYear), decreasing = TRUE))
  xpos <- min(full$year) + diff(range(full$year)) / 5
  rho_text <- do.call(rbind, lapply(variables, function(variable) {
    rows <- rho_by_peel[rho_by_peel$Variable == variable, , drop = FALSE]
    valid <- nrow(rows) == nyear && all(rows$Valid)
    data.frame(Variable = variable, Rho = if (valid) mean(rows$Rho) else NA_real_,
               Year = xpos, Valid = valid, ValidPeels = sum(rows$Valid),
               RequestedPeels = nyear)
  }))
  raw_rho_text <- do.call(rbind, lapply(variables, function(variable) {
    rows <- rho_by_peel[rho_by_peel$Variable == variable, , drop = FALSE]
    # Retain the diagnostic raw mean, but never silently drop missing peels.
    data.frame(Variable = variable,
               Rho = if (all(is.finite(rows$RawRho))) mean(rows$RawRho) else NA_real_,
               Year = xpos)
  }))
  last_points <- if (nrow(results)) results %>%
    dplyr::group_by(Variable, RetrospectiveYear) %>%
    dplyr::filter(Year == max(Year)) %>%
    dplyr::ungroup() else results
  if (any(!rho_text$Valid))
    warning("Mohn's rho is unavailable for one or more quantities: a full/peel fit failed the numerical screen or a terminal estimate is missing. Inspect fit_diagnostics, errors and rho_by_peel; raw_rho_text is descriptive only.",
            call. = FALSE)
  progress(sprintf("Retrospective analysis complete: %.1f sec.",
                   (proc.time() - t_grand)[["elapsed"]]))
  output <- list(results = results, rho_text = rho_text, last_points = last_points,
                 model_type = model_type, fit_diagnostics = fit_diagnostics,
                 rho_by_peel = rho_by_peel, raw_rho_text = raw_rho_text,
                 errors = fit_diagnostics[nzchar(fit_diagnostics$error),
                                          c("Peel", "RetrospectiveYear", "error"), drop = FALSE],
                 workers = ncores_use, nstarts = fit_args$nstarts, peel_step = peel_step)
  if (plot) {
    if (!nrow(results) || !any(is.finite(results$Value))) {
      output["plot"] <- list(NULL)
      warning("Retrospective plot skipped: no finite estimates are available. Inspect the returned fit_diagnostics and errors.",
              call. = FALSE)
    } else {
      p <- plot_retro(output,
                    rho_digits = rho_digits, rho_position = rho_position, rho_size = rho_size,
                    line_size = line_size, point_size = point_size,
                    point_shape = point_shape, facet_scales = facet_scales,
                    facet_ncol = facet_ncol, facet_nrow = facet_nrow,
                    title = title, xlab = xlab, ylab = ylab, font_family = font_family,
                    title_size = title_size, axis_title_size = axis_title_size,
                    axis_text_size = axis_text_size, strip_text_size = strip_text_size,
                    legend_text_size = legend_text_size, x_breaks = x_breaks,
                    base_theme = base_theme, title_hjust = title_hjust)
      output$plot <- p
    }
  }

  return(output)
}


#' Retrospective Analysis for ACL Model
#'
#' Convenience wrapper that calls `retro_model(..., model_type = "acl")`.
#' See [retro_model()] for full documentation of all parameters.
#'
#' @param nyear Integer. Number of retrospective peels. Default is 5.
#' @param data.CatL Survey abundance indices at length or a named input bundle, as in
#'   `retro_acl(x, nyear = 3)`.
#' @param data.wgt The weight data.
#' @param data.mat The maturity data.
#' @param rec.age The recruitment age.
#' @param nage The number of age classes.
#' @param M Natural mortality per model time step.
#' @param sel_L50 Length at 50 percent survey catchability.
#' @param sel_L95 Length at 95 percent survey catchability.
#' @param ... Additional arguments passed to [retro_model()].
#' @return A list. See [retro_model()].
#' @inheritParams retro_model
#' @seealso [retro_model()], [retro_alscl()], [plot_retro()]
#' @examples
#' \donttest{
#' retro <- retro_acl(YTF_example, nyear = 2, silent = TRUE)
#' retro$rho_text
#' retro$rho_by_peel
#' }
#' @export
retro_acl <- function(nyear = 5, data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95,
                      parameters = NULL, parameters.L = NULL, parameters.U = NULL,
                      map = NULL, len_mid = NULL, len_border = NULL, plot = FALSE,
                      line_size = NULL, point_size = NULL, point_shape = 21, facet_scales = "free", facet_ncol = NULL, facet_nrow = NULL, train_times = 1, title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL, title_hjust = NULL, rho_digits = 4, rho_position = "top_right", rho_size = 3.5, ncores = 1, ...) {
  .acl_retro_wrapper(match.call(expand.dots = FALSE), environment(), "acl")
}


#' Retrospective Analysis for ALSCL Model
#'
#' Convenience wrapper that calls `retro_model(..., model_type = "alscl")`.
#' See [retro_model()] for full documentation of all parameters.
#'
#' @param nyear Integer. Number of retrospective peels. Default is 5.
#' @param data.CatL Survey abundance indices at length or a named input bundle, as in
#'   `retro_alscl(x, nyear = 3)`.
#' @param data.wgt The weight data.
#' @param data.mat The maturity data.
#' @param rec.age The recruitment age.
#' @param nage The number of age classes.
#' @param M Natural mortality per model time step.
#' @param sel_L50 Length at 50 percent survey catchability.
#' @param sel_L95 Length at 95 percent survey catchability.
#' @param growth_step Time step in years. NULL uses rec.age when it is below
#'   one, otherwise one, as in [run_alscl()]; a bundle supplies its own value.
#' @param ... Additional arguments passed to [retro_model()].
#' @return A list. See [retro_model()].
#' @seealso [retro_model()], [retro_acl()], [plot_retro()]
#' @examples
#' \donttest{
#' # The last ten years of the example data and one fishing mortality rate
#' # shared by all lengths in each year keep the three ALSCL fits short.
#' x <- YTF_example
#' tables <- c("data.CatL", "data.wgt", "data.mat")
#' x[tables] <- lapply(x[tables], function(tab) tab[, c(1, 12:21)])
#' retro <- retro_alscl(x, nyear = 2, F_structure = "year", silent = TRUE)
#' retro$rho_text
#' retro$fit_diagnostics[, c("Peel", "RetrospectiveYear", "numerical_ok")]
#' }
#' @export
retro_alscl <- function(nyear = 5, data.CatL, data.wgt, data.mat,
                        rec.age, nage, M, sel_L50, sel_L95,
                        growth_step = NULL, ...) {
  .acl_retro_wrapper(match.call(expand.dots = FALSE), environment(), "alscl")
}


#' Plot Retrospective Analysis Results
#'
#' Generate or re-generate the retrospective plot from stored results.
#' This allows changing display options without re-running the computation.
#'
#' @param retro_result A list returned by `retro_model()`, `retro_acl()`, or `retro_alscl()`.
#' @param rho_digits Integer. Decimal places for Mohn's rho. Default is 4.
#' @param rho_position Character. Position of rho text. Default is "top_right".
#' @param rho_size Numeric. Font size of rho text. Default is 3.5.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting (default 1.5).
#' @param point_size Numeric or NULL. Point size; NULL inherits the global point_size setting (default 2.5).
#' @param point_shape Numeric. Point shape. Default is 21.
#' @param facet_scales Character. Facet scales. Default is "free".
#' @param facet_ncol Integer or NULL. Number of facet columns.
#' @param facet_nrow Integer or NULL. Number of facet rows.
#' @param title Character or NULL. Custom plot title.
#' @param xlab Character or NULL. Custom x-axis label.
#' @param ylab Character or NULL. Custom y-axis label.
#' @param font_family Character or NULL. Font family.
#' @param title_size Numeric or NULL. Title size in pt.
#' @param axis_title_size Numeric or NULL. Axis title size in pt.
#' @param axis_text_size Numeric or NULL. Axis tick label size in pt.
#' @param strip_text_size Numeric or NULL. Facet label size in pt.
#' @param legend_text_size Numeric or NULL. Legend text size in pt.
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks.
#' @param base_theme Character or NULL. Base ggplot2 theme name.
#' @param title_hjust Numeric or NULL. Title horizontal alignment.
#' @return A ggplot object.
#' @param palette Character or NULL. ggsci palette name; NULL inherits acl_theme().
#'   Native colors are interpolated when there are more peels than colors.
#' @param colors Character vector or NULL. Explicit period colors, ordered by
#'   descending terminal period or named by terminal period. Overrides palette.
#'   Names are the numeric terminal periods, for example "2019" or "2019.75".
#' @details Each line is one fit and is identified by the terminal period of
#'   its data. The legend is titled "Terminal year" for annual steps and
#'   "Terminal period" for shorter steps, where quarterly periods are labelled
#'   as in "2019 Q4". Default colors follow the retrospective peel, so the fit
#'   with a given terminal period has the same color whether or not another
#'   fit returned estimates. A fit that failed the numerical screen is drawn
#'   with a dashed line and a "Numerical screen" legend is added. A requested
#'   fit without estimates, for example after a fit error, stays in the legend
#'   and is marked "(no estimates)". The subtitle names both kinds of fit, and
#'   each panel states how many requested peels are valid when Mohn's rho is
#'   withheld.
#' @param ... The former argument names facet_col and facet_row, accepted with a warning.
#' @export
#' @examples
#' \donttest{
#' retro <- retro_acl(YTF_example, nyear = 2, silent = TRUE)
#' plot_retro(retro)
#'
#' # Change the display without fitting again
#' plot_retro(retro, rho_digits = 2, facet_ncol = 2)
#' }
plot_retro <- function(retro_result,
                       rho_digits = 4,
                       rho_position = "top_right",
                       rho_size = 3.5,
                       line_size = NULL, point_size = NULL, point_shape = 21,
                       facet_scales = "free", facet_ncol = NULL, facet_nrow = NULL,
                       title = NULL, xlab = NULL, ylab = NULL,
                       font_family = NULL, title_size = NULL,
                       axis_title_size = NULL, axis_text_size = NULL,
                       strip_text_size = NULL, legend_text_size = NULL,
                       x_breaks = NULL, base_theme = NULL, title_hjust = NULL, palette = NULL, colors = NULL, ...) {

  renamed <- .acl_renamed(list(...), "plot_retro")
  if (is.null(facet_ncol)) facet_ncol <- renamed$facet_ncol
  if (is.null(facet_nrow)) facet_nrow <- renamed$facet_nrow
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(point_size)) point_size <- acl_theme("point_size")
  if (is.null(font_family)) font_family <- acl_theme("font_family")
  results     <- retro_result$results
  rho_text    <- retro_result$rho_text
  last_points <- retro_result$last_points
  if (!nrow(results) || !any(is.finite(results$Year) & is.finite(results$Value)))
    stop("No retrospective estimates are available to plot; inspect fit_diagnostics and errors.",
         call. = FALSE)

  # Colors are keyed to the peel index when it is recorded, so a terminal
  # period keeps its color when another peel has no estimates. Periods of
  # requested fits without estimates stay in the legend.
  as_period <- function(x) as.character(x)
  periods <- unique(as_period(results$RetrospectiveYear))
  peel_of <- stats::setNames(rep(NA_integer_, length(periods)), periods)
  if (!is.null(results$Peel))
    peel_of[periods] <- as.integer(results$Peel[match(periods, as_period(results$RetrospectiveYear))])
  requested <- retro_result$fit_diagnostics
  if (is.data.frame(requested) && all(c("Peel", "RetrospectiveYear") %in% names(requested))) {
    listed <- as_period(requested$RetrospectiveYear)
    keep <- !is.na(listed) & !duplicated(listed)
    peel_of[listed[keep]] <- as.integer(requested$Peel[keep])
  }
  periods <- sort(names(peel_of), decreasing = TRUE)
  numeric_periods <- suppressWarnings(as.numeric(periods))
  if (all(is.finite(numeric_periods))) periods <- periods[order(numeric_periods, decreasing = TRUE)]
  peel_of <- peel_of[periods]
  present <- periods %in% as_period(results$RetrospectiveYear[is.finite(results$Value)])
  if (is.null(colors)) {
    index <- if (anyNA(peel_of) || anyDuplicated(peel_of)) seq_along(periods) else peel_of + 1L
    requested_peels <- suppressWarnings(max(rho_text$RequestedPeels, na.rm = TRUE))
    n_colors <- max(index, if (is.finite(requested_peels)) requested_peels + 1L else 1L)
    colors <- stats::setNames(.acl_palette(palette %||% acl_theme("palette"), n_colors)[index], periods)
  } else {
    if (length(colors) < length(periods)) stop("colors must cover every retrospective period.")
    if (!is.null(names(colors))) {
      if (!all(periods %in% names(colors))) stop("Named colors must include every retrospective period.")
      colors <- colors[periods]
    } else colors <- stats::setNames(colors[seq_along(periods)], periods)
    if (anyNA(colors)) stop("colors must not contain missing values.")
    grDevices::col2rgb(colors)
  }
  results$RetrospectiveYear <- factor(as_period(results$RetrospectiveYear), levels = periods)
  last_points$RetrospectiveYear <- factor(as_period(last_points$RetrospectiveYear), levels = periods)

  # Legend text: quarter labels for quarterly steps, and a statement for a
  # requested fit that returned no estimates.
  all_times <- c(numeric_periods, results$Year)
  annual <- all(is.finite(numeric_periods)) &&
    all(abs(all_times - round(all_times)) < 1e-8, na.rm = TRUE)
  # The model time step comes from the fitted series, not from the spacing of
  # the terminal periods, which is peel_step times the model step.
  model_step <- suppressWarnings(min(diff(sort(unique(results$Year[is.finite(results$Year)])))))
  period_labels <- if (annual || !all(is.finite(numeric_periods))) periods else
    .acl_time_labels(numeric_periods, step = if (is.finite(model_step)) model_step else NULL)
  legend_title <- if (annual) "Terminal year" else "Terminal period"
  screen_ok <- if (is.null(results$NumericalOK)) rep(TRUE, nrow(results)) else
    results$NumericalOK %in% TRUE
  failed_periods <- period_labels[periods %in% as_period(results$RetrospectiveYear[!screen_ok])]
  absent_periods <- period_labels[!present]
  period_labels[!present] <- paste(period_labels[!present], "(no estimates)")
  mark_screen <- any(!screen_ok)
  results$Screen <- factor(ifelse(screen_ok, "Passed", "Failed"), levels = c("Passed", "Failed"))
  last_points$Screen <- factor("Passed", levels = c("Passed", "Failed"))

  x_min <- min(results$Year, na.rm = TRUE)
  x_max <- max(results$Year, na.rm = TRUE)
  x_range <- x_max - x_min

  pos <- match.arg(rho_position, c("top_right", "top_left", "bottom_right", "bottom_left"))
  if (pos %in% c("top_right", "bottom_right")) {
    rho_text$Year <- x_max - x_range * 0.02
    rho_hjust <- 1
  } else {
    rho_text$Year <- x_min + x_range * 0.02
    rho_hjust <- 0
  }
  if (pos %in% c("top_right", "top_left")) {
    rho_y <- Inf
    rho_vjust <- 1.5
  } else {
    rho_y <- -Inf
    rho_vjust <- -0.5
  }

  auto_title <- if (!is.null(retro_result$model_type)) {
    paste0(.acl_title("retro"), " (", toupper(retro_result$model_type), ")")
  } else {
    .acl_title("retro")
  }

  # A fit that failed the numerical screen is drawn with a dashed line.
  line_layer <- if (mark_screen)
    ggplot2::geom_line(ggplot2::aes(linetype = Screen), linewidth = line_size,
                       show.legend = TRUE) else
    ggplot2::geom_line(linewidth = line_size, show.legend = TRUE)
  p <- ggplot2::ggplot(results, ggplot2::aes(x = Year, y = Value,
                                              color = RetrospectiveYear,
                                              group = RetrospectiveYear)) +
    line_layer +
    ggplot2::scale_color_manual(values = colors, breaks = periods,
                                labels = period_labels, drop = FALSE) +
    ggplot2::geom_point(data = last_points, size = point_size, shape = point_shape) +
    ggplot2::facet_wrap(~Variable, scales = facet_scales, ncol = facet_ncol, nrow = facet_nrow) +
    .acl_scale_x(x_breaks, n_breaks = 10) +
    .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size,
                    strip_text_size, legend_text_size,
                    base_theme = base_theme, title_hjust = title_hjust) +
    ggplot2::theme(legend.position = "bottom") +
    ggplot2::labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", "year"),
                  y = if (!is.null(ylab)) ylab else "Value", color = legend_title,
                  title = if (!is.null(title)) title else auto_title)
  if (mark_screen)
    p <- p + ggplot2::scale_linetype_manual(name = "Numerical screen",
      values = c(Passed = "solid", Failed = "dashed"), drop = FALSE) +
      ggplot2::theme(legend.box = "vertical")

  # State how many requested peels are valid when Mohn's rho is withheld.
  counts <- if (all(c("ValidPeels", "RequestedPeels") %in% names(rho_text)))
    paste0(" (", rho_text$ValidPeels, " of ", rho_text$RequestedPeels, " peels valid)") else ""
  rho_text$Label <- ifelse(is.finite(rho_text$Rho),
    paste0("rho = ", sprintf(paste0("%.", rho_digits, "f"), rho_text$Rho)),
    paste0("rho unavailable", counts, ": check diagnostics"))
  p <- p + ggplot2::geom_text(
    data = rho_text,
    ggplot2::aes(x = Year, label = Label),
    y = rho_y, hjust = rho_hjust, vjust = rho_vjust,
    size = rho_size, family = font_family,
    inherit.aes = FALSE
  )
  if (any(!is.finite(rho_text$Rho)) || mark_screen || length(absent_periods)) {
    unit <- if (annual) "terminal year" else "terminal period"
    p <- p + ggplot2::labs(subtitle = paste(c(
      "Available estimates shown; numerical checks or terminal estimates are incomplete.",
      if (length(failed_periods)) paste0("Failed the numerical screen: ", unit, " ",
        paste(failed_periods, collapse = ", "), "."),
      if (length(absent_periods)) paste0("No estimates: ", unit, " ",
        paste(absent_periods, collapse = ", "), ".")), collapse = "\n"))
  }

  return(p)
}
