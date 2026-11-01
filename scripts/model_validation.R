# Run from the repository root after loading the development package.
# Rscript -e 'pkgload::load_all(); source("scripts/model_validation.R"); run_model_validation_guide()'
run_model_validation_guide <- function(out = "docs", fits = NULL, ncores = 2) {
  source("scripts/plot_helpers.R", local = TRUE)
  x <- ALSCL::YTF_example
  if (is.null(fits)) {
    message("Fitting source assessments")
    fits <- list(acl = ALSCL::run_acl(x, silent = TRUE),
                 alscl = ALSCL::run_alscl(x, silent = TRUE))
  }
  stopifnot(isTRUE(fits$acl$diagnostics$numerical_ok),
            isTRUE(fits$alscl$diagnostics$numerical_ok))
  b <- fits$alscl
  figures <- file.path(out, "figures/workflows")
  results <- file.path(out, "results/model-validation")
  dir.create(figures, recursive = TRUE, showWarnings = FALSE)
  dir.create(results, recursive = TRUE, showWarnings = FALSE)
  message("Generating conditional and process simulations")
  conditional <- ALSCL::simulate_fit(b, nsim = 3, seed = 20261101,
    process = "conditional")
  resampled <- ALSCL::simulate_fit(b, nsim = 3, seed = 20261101,
    process = "resample")
  lengths <- unique(round(seq(1, length(b$len_mid), length.out = 3)))
  simulations <- list("Conditional observations" = conditional,
                      "Resampled processes" = resampled)
  simulated_series <- do.call(rbind, lapply(names(simulations), function(mode) {
    z <- simulations[[mode]]
    do.call(rbind, lapply(seq_along(z$simulations), function(i) {
      d <- z$simulations[[i]]
      data.frame(mode = mode, replicate = paste("Simulation", i),
        year = rep(b$year, each = length(lengths)),
        length_label = rep(paste("Length", b$len_mid[lengths]), length(b$year)),
        log_index = as.numeric(log(d$observations[lengths, , drop = FALSE])))
    }))
  }))
  reference <- do.call(rbind, lapply(names(simulations), function(mode) {
    data.frame(mode = mode, year = rep(b$year, each = length(lengths)),
      length_label = rep(paste("Length", b$len_mid[lengths]), length(b$year)),
      log_index = as.numeric(b$report$Elog_index[lengths, , drop = FALSE]))
  }))
  labels <- paste("Length", b$len_mid[lengths])
  simulated_series$length_label <- factor(simulated_series$length_label, levels = labels)
  reference$length_label <- factor(reference$length_label, levels = labels)
  p <- ggplot2::ggplot(simulated_series,
      ggplot2::aes(year, log_index, colour = replicate, group = replicate)) +
    ggplot2::geom_line(linewidth = .55, alpha = .8) +
    ggplot2::geom_line(data = reference, ggplot2::aes(year, log_index),
      inherit.aes = FALSE, colour = "grey20", linewidth = .65, linetype = "dashed") +
    ggplot2::facet_grid(mode ~ length_label, scales = "free_y") +
    ggsci::scale_color_npg() + ggplot2::theme_classic(base_family = "sans") +
    ggplot2::theme(legend.position = "bottom") +
    ggplot2::labs(x = "Year", y = "Log survey index", colour = NULL,
      title = "Survey observations simulated from a fitted ALSCL model",
      caption = "Scalar parameters fixed. Dashed line: original fitted log median. Curves are draws, not uncertainty bands.")
  save_grid_free_plot(file.path(figures, "fitted-simulation.png"), p,
    width = 10.5, height = 6.4, dpi = 160, bg = "white")
  utils::write.csv(simulated_series, file.path(results, "simulation-series.csv"), row.names = FALSE)
  message("Refitting process replicates with two independent starts")
  refits <- lapply(resampled$simulations, function(s) {
    tryCatch(ALSCL::run_alscl(s$x, nstarts = 2, ncores = 1, silent = TRUE),
      error = function(e) list(error = conditionMessage(e)))
  })
  truth <- lapply(resampled$simulations, function(s) s$truth)
  performance <- ALSCL::summarize_simulations(refits, truth, quantities = c("SSB", "Rec"))
  utils::write.csv(performance$summary, file.path(results, "simulation-performance.csv"), row.names = FALSE)
  message("Fitting time-held-out validation folds")
  validations <- lapply(c("acl", "alscl"), function(model)
    ALSCL::hindcast_model(x, model = model, horizon = 1, nfolds = 2,
      min_train = 8, nstarts = 1, ncores = ncores))
  names(validations) <- c("acl", "alscl")
  predictions <- do.call(rbind, lapply(names(validations), function(model)
    data.frame(model = toupper(model), validations[[model]]$predictions)))
  scores <- do.call(rbind, lapply(names(validations), function(model)
    data.frame(model = toupper(model), validations[[model]]$scores)))
  diagnostics <- do.call(rbind, lapply(names(validations), function(model)
    data.frame(model = toupper(model), validations[[model]]$diagnostics)))
  utils::write.csv(predictions, file.path(results, "hindcast-predictions.csv"), row.names = FALSE)
  utils::write.csv(scores, file.path(results, "hindcast-scores.csv"), row.names = FALSE)
  utils::write.csv(diagnostics, file.path(results, "hindcast-diagnostics.csv"), row.names = FALSE)
  d <- predictions[predictions$length %in% b$len_mid[lengths], , drop = FALSE]
  d$length_label <- factor(paste("Length", d$length), levels = labels)
  values <- c("Observed" = "observed_log", "Model" = "predicted_log", "Persistence" = "naive_log")
  d <- do.call(rbind, lapply(names(values), function(name)
    data.frame(d[c("model", "year", "length_label")], series = name, log_index = d[[values[[name]]]])))
  # Diagnostics retain every failure; a missing prediction is not plotted as zero.
  d <- d[is.finite(d$log_index), , drop = FALSE]
  p <- ggplot2::ggplot(d, ggplot2::aes(year, log_index, colour = series,
      shape = series, linetype = series)) +
    ggplot2::geom_line(linewidth = .7) + ggplot2::geom_point(size = 2.5) +
    ggplot2::facet_grid(model ~ length_label, scales = "free_y") +
    ggplot2::scale_color_manual(values = c(Observed = "grey20", Model = "#3C5488", Persistence = "#E64B35")) +
    ggplot2::scale_x_continuous(breaks = sort(unique(d$year))) +
    ggplot2::theme_classic(base_family = "sans") + ggplot2::theme(legend.position = "bottom") +
    ggplot2::labs(x = "Withheld year", y = "Log survey index", colour = NULL,
      shape = NULL, linetype = NULL, title = "One-step predictions of withheld survey observations",
      caption = "Separate training fit at each origin; two final periods of synthetic YTF data. No prediction intervals.")
  save_grid_free_plot(file.path(figures, "hindcast-predictions.png"), p,
    width = 10.5, height = 6.2, dpi = 160, bg = "white")
  archive <- tempfile(fileext = ".rds")
  on.exit(unlink(archive), add = TRUE)
  ALSCL::save_assessment(b, archive)
  saved <- ALSCL::read_assessment(archive)
  again <- ALSCL::simulate_fit(saved, nsim = 3, seed = 20261101, process = "conditional")
  stopifnot(identical(again$simulations, conditional$simulations), is.null(saved$obj))
  jsonlite::write_json(list(seed = 20261101, source_fit_numerical_ok =
    c(ACL = fits$acl$diagnostics$numerical_ok, ALSCL = b$diagnostics$numerical_ok),
    validation_diagnostics = diagnostics, validation_scores = scores,
    simulation_replicates = 3L, simulation_summary = performance$summary,
    archive_simulation_equal = TRUE, figures_grid_free = TRUE,
    parameter_uncertainty = "none"), file.path(results, "verification.json"),
    pretty = TRUE, auto_unbox = TRUE, na = "null")
  invisible(list(fits = fits, conditional = conditional, resampled = resampled,
    refits = refits, performance = performance, validation = validations))
}
