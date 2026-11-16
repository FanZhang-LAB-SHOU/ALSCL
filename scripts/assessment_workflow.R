# Rebuild the assessment-workflow figures from the repository root.
# Rscript -e 'pkgload::load_all(); source("scripts/assessment_workflow.R"); run_assessment_guide()'
# An explicitly supplied fits list may reuse fresh fits made with this source.
run_assessment_guide <- function(out = "docs", fits = NULL) {
  source("scripts/plot_helpers.R", local = TRUE)
  x <- ALSCL::YTF_example
  if (is.null(fits)) fits <- list(acl = ALSCL::run_acl(x, silent = TRUE),
                                alscl = ALSCL::run_alscl(x, silent = TRUE))
  a <- fits$acl; b <- fits$alscl
  stopifnot(isTRUE(a$diagnostics$numerical_ok), isTRUE(b$diagnostics$numerical_ok))
  figures <- file.path(out, "figures/workflows")
  results <- file.path(out, "results/workflows")
  dir.create(figures, recursive = TRUE, showWarnings = FALSE)
  dir.create(results, recursive = TRUE, showWarnings = FALSE)
  old <- ALSCL::acl_theme()
  on.exit(do.call(ALSCL::acl_theme_set, old), add = TRUE)
  ALSCL::acl_theme_set(font_family = "sans")
  checks <- ALSCL::check_fit(b, max_lag = 4)
  for (nm in names(checks$plots)) save_grid_free_plot(
    file.path(figures, paste0("residual-", nm, ".png")), checks$plots[[nm]])
  utils::write.csv(checks$lag_correlations, file.path(results, "residual-lags.csv"), row.names = FALSE)
  utils::write.csv(ALSCL::extract_parameters(b), file.path(results, "parameters.csv"), row.names = FALSE)
  utils::write.csv(ALSCL::extract_estimates(b), file.path(results, "estimates.csv"), row.names = FALSE)
  cases <- ALSCL::fit_scenarios(x, list(reference = list(), low_M = list(M = .15),
    shared_F = list(F_structure = "year")), model = "acl", ncores = 2,
    F_summary = "mean", silent = TRUE)
  utils::write.csv(cases$status, file.path(results, "scenario-status.csv"), row.names = FALSE)
  utils::write.csv(cases$estimates, file.path(results, "scenario-estimates.csv"), row.names = FALSE)
  # Retain every scenario and label its numerical status, rather than filtering it away.
  d <- cases$estimates[cases$estimates$quantity == "SSB", ]
  # Readable scenario names in the legend; the tables keep the scenario identifiers.
  scenario_names <- c(reference = "Reference",
    low_M = "Natural mortality rate 0.15 per year",
    shared_F = "Fishing mortality by year only")
  d$label <- paste0(scenario_names[d$scenario], ifelse(d$numerical_ok, "", " (check the fit)"))
  d$label <- factor(d$label, levels = unique(d$label[order(match(d$scenario, names(scenario_names)))]))
  p <- ggplot2::ggplot(d, ggplot2::aes(year, estimate, colour = label)) +
    ggplot2::geom_line(linewidth = .8) + ALSCL::theme_acl(quantity = "stock") +
    ggplot2::scale_colour_manual(values = ALSCL::acl_palette(length(unique(d$label)))) +
    ggplot2::expand_limits(y = 0) +
    ggplot2::labs(x = "Year", y = "Spawning stock biomass (SSB)", colour = "Scenario",
      title = "ACL spawning stock biomass under three model settings")
  p <- tidy_time_axis(p, d$year)
  save_grid_free_plot(file.path(figures, "scenario-SSB.png"), p)
  values <- exp(a$opt$par[["mean_log_F"]]) * c(.9, 1, 1.1)
  profile <- ALSCL::profile_model(a, "mean_log_F", values, scale = "natural", ncores = 2)
  utils::write.csv(profile$grid, file.path(results, "profile-F.csv"), row.names = FALSE)
  pd <- profile$grid
  # The three supplied points illustrate the interface, not a confidence limit.
  primary <- ALSCL::acl_palette(role = "primary")
  p <- ggplot2::ggplot(pd, ggplot2::aes(value, delta_nll)) +
    ggplot2::geom_line(linewidth = .8, colour = primary) +
    ggplot2::geom_point(size = 2.5, colour = primary) + ALSCL::theme_acl() +
    ggplot2::labs(x = "Baseline fishing mortality rate (per year)",
      y = "Change in negative log likelihood",
      title = "ACL likelihood profile of the baseline fishing mortality rate",
      caption = "Other parameters are refitted at each point; no interval is inferred.")
  save_grid_free_plot(file.path(figures, "profile-F.png"), p)
  h <- 4L
  w <- as.matrix(x$data.wgt[-1L]); mat <- as.matrix(x$data.mat[-1L])
  future_w <- matrix(w[, ncol(w)], nrow(w), h)
  future_mat <- matrix(mat[, ncol(mat)], nrow(mat), h)
  scenarios <- lapply(c(.10, .25), function(f) ALSCL::project_model(b, F = rep(f, h),
    recruitment = rep(tail(b$report$Rec, 1), h), weight = future_w, maturity = future_mat))
  projections <- do.call(rbind, lapply(seq_along(scenarios), function(i)
    data.frame(scenario = c("F = 0.10", "F = 0.25")[i], scenarios[[i]]$summary)))
  utils::write.csv(projections, file.path(results, "projections.csv"), row.names = FALSE)
  p <- ggplot2::ggplot(projections, ggplot2::aes(year, SSB, colour = scenario)) +
    ggplot2::geom_line(linewidth = .8) + ggplot2::geom_point(size = 2) +
    ALSCL::theme_acl(quantity = "stock") +
    ggplot2::scale_colour_manual(values = ALSCL::acl_palette(2),
      labels = function(x) sub("^F = ", "", x)) + ggplot2::expand_limits(y = 0) +
    ggplot2::labs(x = "Year", y = "Spawning stock biomass (SSB)",
      colour = "Future fishing mortality rate (per year)",
      title = "ALSCL projection of spawning stock biomass",
      caption = paste("Biomass at the start of each year. Recruitment, weight and maturity are held",
        "at their last values by assumption; no uncertainty bands are shown."))
  p <- tidy_time_axis(p, projections$year)
  save_grid_free_plot(file.path(figures, "projection-SSB.png"), p)
  archive <- tempfile(fileext = ".rds"); on.exit(unlink(archive), add = TRUE)
  ALSCL::save_assessment(b, archive)
  saved <- ALSCL::read_assessment(archive)
  stopifnot(is.null(saved$obj), identical(ALSCL::extract_estimates(saved), ALSCL::extract_estimates(b)))
  jsonlite::write_json(list(scenario_status = cases$status, profile = profile$grid,
    figures = list.files(figures, "\\.png$"), archive_roundtrip = TRUE,
    base_numerical_ok = c(ACL = a$diagnostics$numerical_ok, ALSCL = b$diagnostics$numerical_ok)),
    file.path(results, "verification.json"), auto_unbox = TRUE, pretty = TRUE, na = "null")
  invisible(list(fits = fits, checks = checks, scenarios = cases, profile = profile, projections = scenarios))
}
