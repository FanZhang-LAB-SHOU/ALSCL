# North Sea whiting case study: fits of the article
# website/content/{en,zh}/articles/case-north-sea-whiting.md.
# Run from the repository root:
#   Rscript scripts/whiting_case.R              # fit, then write numbers and figures
#   Rscript scripts/whiting_case.R fit quick    # one fit only (see whiting_case_fits)
#   Rscript scripts/whiting_case.R report       # numbers and figures from saved fits
# One start on the complete series takes about 10 minutes, and the six fits
# together about 45 minutes on five cores (ALSCL_WHITING_CORES sets the number
# of cores). The fits are therefore saved in output/whiting-case, which is not
# under version control (ALSCL_WHITING_CASE names another folder), and a fit
# with a saved file is not repeated. scripts/whiting_case_report.R holds the
# second stage.
# The numbers and figures must come from the code of this checkout. The guard
# loads the checkout with pkgload, or stops when the installed package differs.
source("scripts/checkout_guard.R")
use_checkout_alscl()

# Inputs of the case, all built from the bundled data set.
whiting_case_inputs <- function() {
  x <- whiting_example
  # Quick example: the first 20 years, same settings.
  short <- x
  for (tab in c("data.CatL", "data.wgt", "data.mat")) short[[tab]] <- x[[tab]][, 1:21]
  # Natural mortality rate by age and year of the ICES assessment. The model has
  # 10 age classes and the ICES table has ages 1 to 5 and a plus group (6+), so
  # ages 6 to 10 take the value of the plus group. The table ends in 2022, so
  # 2023 to 2026 take the values of 2022.
  M_age <- x$ices$M[c(1:6, 6, 6, 6, 6), ]
  M_ices <- cbind(M_age, M_age[, rep("2022", 4)])
  dimnames(M_ices) <- list(age = 1:10, year = 1983:2026)
  # Survey catchability that declines for large fish, after the curve of
  # Fraser et al. (2007) for whiting and the GOV trawl in quarter 3 (shape only).
  q_dome <- survey_catchability(x$fit_args$len_mid, "dome", L50 = 10, L95 = 14,
                                L50_desc = 29.5, L95_desc = 22, minimum = 0.22)
  list(x = x, short = short, M_ices = M_ices, q_dome = q_dome)
}

# The fits of the case: name, and the call that produces it.
whiting_case_fits <- function(inputs, ncores = 5) {
  x <- inputs$x
  few <- min(3, ncores)
  list(
    quick = function() run_alscl(inputs$short, nstarts = 3, ncores = few, start_spread = 0.5),
    alscl = function() run_alscl(x, nstarts = 5, ncores = ncores, start_spread = 0.5),
    acl = function() run_acl(x, nstarts = 5, ncores = ncores, start_spread = 0.5),
    # The ACL fit estimates the standard deviation of the initial numbers at age
    # at zero. It is fixed here at exp(-3) = 0.05, as the advice of that fit says.
    acl_fixed = function() run_acl(x,
      parameters = c(x$fit_config$acl$parameters, list(log_std_log_N0 = -3)),
      map = c(x$fit_config$acl$map, list(log_std_log_N0 = factor(NA))),
      nstarts = 5, ncores = ncores, start_spread = 0.5),
    alscl_M = function() run_alscl(x, M = inputs$M_ices, nstarts = 3, ncores = few, start_spread = 0.5),
    alscl_q = function() run_alscl(x, survey_q = inputs$q_dome, sel_L50 = NULL, sel_L95 = NULL,
                                   nstarts = 3, ncores = few, start_spread = 0.5))
}

whiting_case_dir <- function() {
  dir <- Sys.getenv("ALSCL_WHITING_CASE", file.path("output", "whiting-case"))
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  dir
}

# Run the fits that have no saved file yet. The wall-clock time of each fit is
# stored in the saved fit as case_elapsed (seconds).
fit_whiting_case <- function(which = NULL, dir = whiting_case_dir(), ncores = 5) {
  cache <- Sys.getenv("ALSCL_MANUAL_CACHE")
  if (nzchar(cache)) options(ALSCL.tmb.cache = cache)
  fits <- whiting_case_fits(whiting_case_inputs(), ncores)
  if (is.null(which)) which <- names(fits)
  stopifnot(all(which %in% names(fits)))
  for (name in which) {
    file <- file.path(dir, paste0(name, ".rds"))
    if (file.exists(file)) { message(name, ": saved fit found, not refitted"); next }
    message(name, ": fitting")
    started <- Sys.time()
    fit <- fits[[name]]()
    fit$case_elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
    save_assessment(fit, file)
    message(sprintf("%s: objective %.6f, %.0f s", name, fit$opt$objective, fit$case_elapsed))
  }
  invisible(dir)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(TRUE)
  stage <- if (length(args)) args[1L] else "all"
  if (stage %in% c("all", "fit"))
    fit_whiting_case(if (length(args) > 1L) args[-1L] else NULL,
                     ncores = as.integer(Sys.getenv("ALSCL_WHITING_CORES", "5")))
  if (stage %in% c("all", "report")) {
    source("scripts/whiting_case_report.R", encoding = "UTF-8")
    report_whiting_case(whiting_case_dir())
  }
}
