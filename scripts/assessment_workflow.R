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
  ALSCL::acl_theme_set(base_theme = "bw", font_family = "sans", palette = "npg")
  checks <- ALSCL::check_fit(b, max_lag = 4)
  for (nm in names(checks$plots)) save_grid_free_plot(
    file.path(figures, paste0("residual-", nm, ".png")), checks$plots[[nm]],
    width = 8, height = if (nm == "qq") 5 else 6, dpi = 160, bg = "white")
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
  d$label <- paste(d$scenario, ifelse(d$numerical_ok, "", "(review fit)"))
  p <- ggplot2::ggplot(d, ggplot2::aes(year, estimate, colour = label)) +
    ggplot2::geom_line(linewidth = .8) + ggplot2::theme_classic(base_family = "sans") +
    ggsci::scale_color_npg() + ggplot2::labs(x = "Year", y = "SSB", colour = "Scenario",
      title = "ACL sensitivity to M and F structure")
  save_grid_free_plot(file.path(figures, "scenario-SSB.png"), p, width = 8, height = 5, dpi = 160, bg = "white")
  values <- exp(a$opt$par[["mean_log_F"]]) * c(.9, 1, 1.1)
  profile <- ALSCL::profile_model(a, "mean_log_F", values, scale = "natural", ncores = 2)
  utils::write.csv(profile$grid, file.path(results, "profile-F.csv"), row.names = FALSE)
  pd <- profile$grid
  # The three supplied points illustrate the interface, not a confidence limit.
  p <- ggplot2::ggplot(pd, ggplot2::aes(value, delta_nll)) +
    ggplot2::geom_line(linewidth = .8) + ggplot2::geom_point(size = 2.5) +
    ggplot2::theme_classic(base_family = "sans") +
    ggplot2::labs(x = "Baseline F (natural scale)", y = "Change in negative log likelihood",
      title = "ACL parameter profile", caption = "Other parameters are refitted at each point; no interval is inferred.")
  save_grid_free_plot(file.path(figures, "profile-F.png"), p, width = 8, height = 5, dpi = 160, bg = "white")
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
    ggplot2::theme_classic(base_family = "sans") + ggsci::scale_color_npg() +
    ggplot2::labs(x = "Year", y = "Start-of-period SSB", colour = "Future scenario",
      title = "ALSCL conditional projection",
      caption = "Recruitment and biology held at terminal values by assumption; no uncertainty bands.")
  save_grid_free_plot(file.path(figures, "projection-SSB.png"), p, width = 8, height = 5, dpi = 160, bg = "white")
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
