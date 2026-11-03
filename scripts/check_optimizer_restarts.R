# Reproduce the two ALSCL retrospective fits from the maintained own-data example.
# Run from the repository root. This performs real optimization and can take
# several minutes; files for the requested peels are replaced in the output folder.
#
# Installed-package check:
#   Rscript scripts/check_optimizer_restarts.R output/optimizer-restarts
# Reproduce an older package without requiring optimizer code 0:
#   Rscript scripts/check_optimizer_restarts.R output/optimizer-baseline baseline
# Source-checkout check, without installing or changing optimization settings:
#   pkgload::load_all()
#   source("scripts/check_optimizer_restarts.R")
#   run_optimizer_restart_checks("output/optimizer-restarts")

.optimizer_restart_has_fit_call <- function(expr) {
  if (!is.call(expr)) return(FALSE)
  head <- expr[[1L]]
  name <- if (is.symbol(head)) as.character(head) else if (
    is.call(head) && as.character(head[[1L]]) %in% c("::", ":::") &&
    length(head) == 3L) as.character(head[[3L]]) else ""
  name %in% c("run_acl", "run_alscl") ||
    any(vapply(as.list(expr)[-1L], .optimizer_restart_has_fit_call, logical(1)))
}

# Use the current maintained preparation code, stopping before its first fit.
# No archived inputs, fitted estimates or temporary investigation files are used.
prepare_optimizer_restart_inputs <- function() {
  path <- "scripts/fit_own_data_example.R"
  if (!file.exists(path) || !file.exists("DESCRIPTION"))
    stop("Run this checker from the ALSCL repository root.", call. = FALSE)
  expressions <- parse(path, keep.source = FALSE)
  boundary <- which(vapply(as.list(expressions), .optimizer_restart_has_fit_call,
                           logical(1)))
  if (!length(boundary) || boundary[[1L]] <= 1L)
    stop("Cannot locate the first fitting call in the own-data example.", call. = FALSE)
  context <- new.env(parent = globalenv())
  for (expr in as.list(expressions)[seq_len(boundary[[1L]] - 1L)]) eval(expr, context)
  if (!exists("x", context, inherits = FALSE))
    stop("The own-data preparation did not create x.", call. = FALSE)
  x <- context$x
  .optimizer_restart_check_inputs(x, peel = 0L)
  x
}

.optimizer_restart_check_inputs <- function(x, peel) {
  expected <- ALSCL::YTF_example
  end <- ncol(expected$data.CatL) - peel
  for (name in c("data.CatL", "data.wgt", "data.mat")) {
    wanted <- expected[[name]][, seq_len(end), drop = FALSE]
    if (!isTRUE(all.equal(x[[name]], wanted)))
      stop("The own-data example's ", name, " has changed; review the reproduction inputs.",
           call. = FALSE)
  }
  settings <- list(rec.age = 1, nage = 15, M = 0.2,
    sel_L50 = 15, sel_L95 = 20, growth_step = 1,
    train_times = 2, nstarts = 1, ncores = 1,
    len_mid = seq(6, 50, 2), len_border = seq(7, 49, 2))
  for (name in names(settings)) if (!isTRUE(all.equal(x$fit_args[[name]], settings[[name]])))
    stop("The own-data example's ", name, " has changed; review the reproduction settings.",
         call. = FALSE)
  stopifnot(identical(x$fit_config$alscl$map, list()),
    is.null(x$fit_args$control), is.null(x$fit_config$alscl$control),
    is.null(x$fit_args$parameters.L), is.null(x$fit_args$parameters.U),
    is.null(x$fit_config$alscl$parameters.L), is.null(x$fit_config$alscl$parameters.U))
  check <- ALSCL::check_alscl_data(x, "alscl")
  plan <- ALSCL::inspect_parameters(x, "alscl")
  fixed <- plan[plan$status == "fixed", c("parameter", "natural_start")]
  stopifnot(isTRUE(check$valid), check$summary$length_bins == 23L,
    check$summary$time_steps == 20L - peel,
    check$summary$positive == 23L * (20L - peel),
    check$summary$zeros == 0L, check$summary$missing == 0L,
    check$summary$free_fixed == 13L,
    setequal(fixed$parameter, c("log_sigma_log_F", "log_t0")),
    abs(fixed$natural_start[fixed$parameter == "log_sigma_log_F"] - 0.2) < 1e-12,
    abs(fixed$natural_start[fixed$parameter == "log_t0"] - 1 / 60) < 1e-12)
  check
}

# Format recorded optimizer results only; never re-evaluate the live TMB object.
.optimizer_restart_records <- function(fit, peel, input_check) {
  scalar <- function(x, missing = NA_real_) if (length(x) == 1L) unname(x) else missing
  selected <- scalar(fit$raw_opt$selected_pass, NA_integer_)
  history <- fit$optimizer_history
  stopifnot(length(history) == 2L, selected %in% seq_along(history),
            identical(fit$F_structure, "group_year"), fit$nstarts == 1L)
  passes <- do.call(rbind, lapply(seq_along(history), function(i) {
    pass <- history[[i]]
    data.frame(peel = peel, pass = i, selected = i == selected,
      code = scalar(pass$convergence, NA_integer_),
      message = scalar(pass$message, NA_character_),
      objective = scalar(pass$objective), iterations = scalar(pass$iterations, NA_integer_),
      function_evaluations = scalar(pass$evaluations["function"], NA_integer_),
      gradient_evaluations = scalar(pass$evaluations["gradient"], NA_integer_))
  }))
  ref <- fit$refinement
  diagnostics <- data.frame(peel = peel, terminal_year = tail(fit$year, 1L),
    positive_observations = input_check$summary$positive,
    time_steps = input_check$summary$time_steps, free_scalars = input_check$summary$free_fixed,
    nstarts = fit$nstarts, optimizer_passes = length(history), selected_pass = selected,
    convergence_code = scalar(fit$convergence_code, NA_integer_),
    optimizer_message = scalar(fit$opt$message, NA_character_),
    selected_raw_objective = scalar(fit$raw_opt$objective), objective = scalar(fit$opt$objective),
    max_abs_gradient = scalar(fit$max_abs_gradient), pdHess = isTRUE(fit$pdHess),
    bound_hit = isTRUE(fit$bound_hit), natural_boundary = isTRUE(fit$diagnostics$natural_boundary),
    numerical_ok = isTRUE(fit$diagnostics$numerical_ok),
    covariance_condition = scalar(fit$diagnostics$covariance_condition),
    refinement_enabled = isTRUE(ref$enabled),
    refinement_status = scalar(ref$status, NA_character_), refinement_steps = scalar(ref$steps),
    refinement_initial_gradient = scalar(ref$initial_max_gradient),
    refinement_final_gradient = scalar(ref$final_max_gradient),
    refinement_initial_objective = scalar(ref$initial_objective),
    refinement_final_objective = scalar(ref$final_objective),
    issues = paste(fit$diagnostics$issues, collapse = "; "))
  stopifnot(length(fit$report$SSB) == length(fit$year),
    identical(dim(fit$report$FL), c(23L, length(fit$year))),
    all(is.finite(fit$report$SSB)), all(is.finite(fit$report$FL)))
  series <- data.frame(peel = peel, year = fit$year,
    SSB = as.numeric(fit$report$SSB), mean_F = colMeans(fit$report$FL))
  list(passes = passes, diagnostics = diagnostics, timeseries = series)
}

run_optimizer_restart_checks <- function(out, peels = c(1, 3), require_success = TRUE) {
  if (!is.character(out) || length(out) != 1L || is.na(out) || !nzchar(out))
    stop("out must be one nonempty directory path.", call. = FALSE)
  if (!is.logical(require_success) || length(require_success) != 1L || is.na(require_success))
    stop("require_success must be TRUE or FALSE.", call. = FALSE)
  if (!is.numeric(peels) || !length(peels) || anyNA(peels) || any(!is.finite(peels)) ||
      any(peels < 0 | peels > 18 | peels != floor(peels)) || anyDuplicated(peels))
    stop("peels must be distinct integers from 0 to 18, retaining at least two periods.",
         call. = FALSE)
  x <- prepare_optimizer_restart_inputs()
  peels <- as.integer(peels)
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(out)) stop("Cannot create output directory: ", out, call. = FALSE)
  saveRDS(x, file.path(out, "inputs.rds"))
  writeLines(capture.output(utils::sessionInfo()), file.path(out, "sessionInfo.txt"))
  records <- fits <- list()
  for (peel in peels) {
    name <- paste0("peel-", peel)
    path <- file.path(out, name)
    dir.create(path, showWarnings = FALSE)
    xp <- x
    for (field in c("data.CatL", "data.wgt", "data.mat"))
      xp[[field]] <- xp[[field]][, seq_len(ncol(xp[[field]]) - peel), drop = FALSE]
    checked <- .optimizer_restart_check_inputs(xp, peel)
    saveRDS(xp, file.path(path, "input.rds"))
    message("Fitting ALSCL peel ", peel, " with the unchanged own-data example settings.")
    fit <- ALSCL::run_alscl(xp)
    ALSCL::save_assessment(fit, file.path(path, "assessment.rds"), overwrite = TRUE)
    records[[name]] <- .optimizer_restart_records(fit, peel, checked)
    for (table in names(records[[name]])) utils::write.csv(records[[name]][[table]],
      file.path(path, paste0(table, ".csv")), row.names = FALSE)
    fit$obj <- NULL
    fits[[name]] <- fit
  }
  combined <- lapply(c("passes", "diagnostics", "timeseries"), function(table)
    do.call(rbind, lapply(records, `[[`, table)))
  names(combined) <- c("passes", "diagnostics", "timeseries")
  for (table in names(combined)) utils::write.csv(combined[[table]],
    file.path(out, paste0(table, ".csv")), row.names = FALSE)
  d <- combined$diagnostics
  if (any(!d$numerical_ok | !is.finite(d$max_abs_gradient) | d$max_abs_gradient >= 1e-6))
    stop("A fit failed the numerical/gradient checks; inspect the saved diagnostics.", call. = FALSE)
  if (require_success && any(is.na(d$convergence_code) | d$convergence_code != 0L))
    stop("A fit retained a nonzero optimizer code; inspect passes.csv. Use baseline mode only to reproduce older behavior.",
         call. = FALSE)
  message("Completed actual optimizer-restart checks; raw pass codes are retained in ", out, ".")
  invisible(c(list(inputs = x, fits = fits), combined))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (!length(args) || length(args) > 2L ||
      (length(args) == 2L && args[[2L]] != "baseline"))
    stop("Usage: Rscript scripts/check_optimizer_restarts.R OUTPUT_DIRECTORY [baseline]",
         call. = FALSE)
  run_optimizer_restart_checks(args[[1L]], require_success = length(args) == 1L)
}
