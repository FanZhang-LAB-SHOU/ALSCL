# Run from the repository root after installing ALSCL >= 2.2.2.
# Rebuilds the complete CSV example, then checks the t0-only alternatives.
library(ALSCL)
stopifnot(packageVersion("ALSCL") >= "2.2.2")
source("scripts/fit_own_data_example.R", encoding = "UTF-8")
x <- readRDS("output/own-data-example/inputs_x.rds")
x$fit_config$acl$map <- list(t0 = factor(NA), log_std_log_F = NULL,
  logit_log_F_y = NULL, logit_log_F_a = NULL)
x$fit_config$alscl$map <- list(log_t0 = factor(NA), log_sigma_log_F = NULL)
dir.create("output/release-222", recursive = TRUE, showWarnings = FALSE)
rows <- list()
for (model in c("ACL", "ALSCL")) for (structure in c("group_year", "year")) {
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
    file.path("output/release-222", paste0(model, "-", structure, ".rds")))
  # Expectations concern these synthetic inputs, not arbitrary stock data.
  if (structure == "year" || model == "ALSCL")
    stopifnot(fit$diagnostics$numerical_ok, fit$max_abs_gradient < 1e-6)
  if (model == "ACL" && structure == "group_year")
    stopifnot(fit$diagnostics$natural_boundary)
}
write.csv(do.call(rbind, rows), "output/release-222/convergence-checks.csv", row.names = FALSE)
writeLines(capture.output(sessionInfo()), "output/release-222/sessionInfo.txt")
