# Figures and records of the complete own-data example, the article
# website/content/{en,zh}/articles/case-fit-survey.md, from the folder that
# scripts/fit_own_data_example.R writes (output/own-data-example). Run that
# script first with the code of this checkout:
#   Rscript -e 'pkgload::load_all(); source("scripts/fit_own_data_example.R", encoding = "UTF-8")'
# Then, from the repository root:
#   Rscript scripts/refresh_manual_figures.R [folder]                 # figures and checks
#   Rscript scripts/refresh_manual_figures.R retrospective [folder]   # also the retrospective
# The two figures in docs/figures/own-data-example are redrawn from the saved
# ALSCL fit in the default style, as the example script draws them, and
# docs/results/own-data-example-checks.csv records the numerical checks of
# both fits. With "retrospective", the script also refits the retrospective
# analyses of section 7 of the article (the full series and three peels of each
# model) and writes their checks to docs/results/own-data-retrospective.csv.
# The four ALSCL fits take most of the time, several minutes each on one core;
# ALSCL_RETRO_CORES sets the number of worker processes (default 1).
# The figures and tables must come from the code of this checkout. The guard
# loads the checkout with pkgload, or stops when the installed package has
# different functions, templates or data. A version number cannot show that.
source("scripts/checkout_guard.R")
use_checkout_alscl()
source("scripts/plot_helpers.R")
args <- commandArgs(TRUE)
retrospective <- "retrospective" %in% args
args <- setdiff(args, "retrospective")
dir <- if (length(args)) args[1] else file.path("output", "own-data-example")
archive <- file.path(dir, "assessment_summary.rds")
if (!file.exists(archive))
  stop("Fit archive not found: ", archive, ". Run scripts/fit_own_data_example.R first, ",
       "or give the folder it wrote as an argument.", call. = FALSE)
fits <- readRDS(archive)
own <- fits$ALSCL
# The default style, which the example script uses.
suppressMessages(acl_theme_reset())
figures <- file.path("docs", "figures", "own-data-example")
dir.create(figures, recursive = TRUE, showWarnings = FALSE)
# 300 dpi in the size of acl_figure_size(), as in the example script.
save_grid_free_plot(file.path(figures, "residuals.png"),
                    plot_residuals(own, facet_by = "year", x_breaks = pretty(own$len_mid, n = 4)))
save_grid_free_plot(file.path(figures, "SSB.png"), plot_SSB(own, se = isTRUE(own$pdHess)))
# Numerical checks of both fits and how their standard errors were computed.
checks <- do.call(rbind, lapply(c("ACL", "ALSCL"), function(model) {
  f <- fits[[model]]
  data.frame(model = model, free_scalars = length(f$opt$par), convergence = f$convergence_code,
             max_gradient = f$max_abs_gradient, pdHess = isTRUE(f$pdHess),
             bound_hit = isTRUE(f$bound_hit), sd_method = f$sd_info$method,
             sd_cores = f$sd_info$cores)
}))
print(checks)
write_decimal_csv(checks, file.path("docs", "results", "own-data-example-checks.csv"), row.names = FALSE)
if (retrospective) {
  x <- readRDS(file.path(dir, "inputs_x.rds"))
  ncores <- as.integer(Sys.getenv("ALSCL_RETRO_CORES", "1"))
  # The calls of section 7 of the article; ncores changes only how the peels are run.
  ra <- retro_acl(x, nyear = 3, train_times = 2, silent = TRUE, ncores = ncores)
  rb <- retro_alscl(x, nyear = 3, train_times = 2, silent = TRUE, ncores = ncores)
  record <- rbind(data.frame(model = "ACL", ra$fit_diagnostics),
                  data.frame(model = "ALSCL", rb$fit_diagnostics))
  print(record[c("model", "Peel", "RetrospectiveYear", "convergence_code", "max_abs_gradient",
                 "numerical_ok", "optimizer_codes")])
  write_decimal_csv(record, file.path("docs", "results", "own-data-retrospective.csv"), row.names = FALSE)
}
cat("Wrote the own-data figures and checks", if (retrospective) "and the retrospective record", "\n")
