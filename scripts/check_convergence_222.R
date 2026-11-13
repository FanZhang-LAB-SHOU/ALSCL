# Check the t0-only alternatives of the own-data example under both F structures.
# Run from the repository root with ALSCL >= 2.4.0 installed, or after
# pkgload::load_all():
#   Rscript scripts/check_convergence_222.R [output_dir]
# The inputs come from the preparation steps of scripts/fit_own_data_example.R,
# evaluated up to its first fit: the example's own models are not fitted and its
# saved outputs are not replaced. The inputs must still equal YTF_example,
# because the expectations below concern these synthetic data only.
if (!"ALSCL" %in% loadedNamespaces()) library(ALSCL)
source("scripts/check_optimizer_restarts.R")

run_convergence_checks <- function(out = "output/release-222", models = c("ACL", "ALSCL"),
                                   structures = c("group_year", "year")) {
  x <- prepare_optimizer_restart_inputs()
  x$fit_config$acl$map <- list(t0 = factor(NA), log_std_log_F = NULL,
    logit_log_F_y = NULL, logit_log_F_a = NULL)
  x$fit_config$alscl$map <- list(log_t0 = factor(NA), log_sigma_log_F = NULL)
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  rows <- list()
  for (model in models) for (structure in structures) {
    fun <- if (model == "ACL") run_acl else run_alscl
    fit <- fun(x, F_structure = structure, train_times = 2, silent = TRUE)
    row <- data.frame(model = model, F_structure = structure,
      n_free = length(fit$opt$par), n_F = length(fit$report$dev_log_F),
      raw_code = fit$convergence_code,
      gradient_before = fit$refinement$initial_max_gradient,
      gradient_after = fit$max_abs_gradient, polish_steps = fit$refinement$steps,
      pdHess = fit$pdHess, natural_boundary = fit$diagnostics$natural_boundary,
      numerical_ok = fit$diagnostics$numerical_ok, nll = fit$opt$objective)
    print(row)
    rows[[length(rows) + 1L]] <- row
    saveRDS(fit[setdiff(names(fit), "obj")],
      file.path(out, paste0(model, "-", structure, ".rds")))
    # Expectations concern these synthetic inputs, not arbitrary stock data.
    if (structure == "year" || model == "ALSCL")
      stopifnot(fit$diagnostics$numerical_ok, fit$max_abs_gradient < 1e-6)
    if (model == "ACL" && structure == "group_year")
      stopifnot(fit$diagnostics$natural_boundary)
  }
  checks <- do.call(rbind, rows)
  write.csv(checks, file.path(out, "convergence-checks.csv"), row.names = FALSE)
  writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
  invisible(checks)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  run_convergence_checks(if (length(args)) args[[1L]] else "output/release-222")
}
