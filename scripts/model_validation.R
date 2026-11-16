# Run from the repository root after loading the development package.
# Rscript -e 'pkgload::load_all(); source("scripts/model_validation.R"); run_model_validation_guide()'
# The self-test figure alone (about one minute):
# Rscript -e 'pkgload::load_all(); source("scripts/model_validation.R"); run_self_test_guide()'
run_self_test_guide <- function(out = "docs", fit = NULL) {
  source("scripts/plot_helpers.R", local = TRUE)
  if (is.null(fit)) fit <- ALSCL::run_acl(ALSCL::YTF_example, silent = TRUE)
  stopifnot(isTRUE(fit$diagnostics$numerical_ok))
  figures <- file.path(out, "figures/workflows")
  results <- file.path(out, "results/model-validation")
  dir.create(figures, recursive = TRUE, showWarnings = FALSE)
  dir.create(results, recursive = TRUE, showWarnings = FALSE)
  message("Self-test of the ACL fit")
  st <- ALSCL::self_test(fit, nsim = 5, seed = 20261101, process = "conditional")
  print(st)
  p <- ALSCL::plot_self_test(st)
  save_grid_free_plot(file.path(figures, "self-test.png"), p)
  summary_table <- rbind(
    data.frame(type = "series", name = st$series_summary$quantity, truth = NA_real_,
      st$series_summary[-1L]),
    data.frame(type = "parameter", name = st$parameter_summary$parameter,
      st$parameter_summary[-1L]))
  utils::write.csv(summary_table, file.path(results, "self-test-summary.csv"), row.names = FALSE)
  utils::write.csv(st$replicates[c("replicate", "elapsed", "numerical_ok", "converged",
    "failure_reasons")], file.path(results, "self-test-replicates.csv"), row.names = FALSE)
  invisible(st)
}

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
  # Panel names: "Length 6" in the tables, "Length bin 6 cm" in the figures.
  length_strip <- ggplot2::labeller(length_label = function(x) paste(sub("^Length", "Length bin", x), "cm"))
  p <- ggplot2::ggplot(simulated_series,
      ggplot2::aes(year, log_index, colour = replicate, group = replicate)) +
    ggplot2::geom_line(linewidth = .55, alpha = .8) +
    ggplot2::geom_line(data = reference, ggplot2::aes(year, log_index),
      inherit.aes = FALSE, colour = "black", linewidth = .65, linetype = "dashed") +
    ggplot2::facet_grid(length_label ~ mode, scales = "free_y", labeller = length_strip) +
    ggplot2::scale_colour_manual(values = ALSCL::acl_palette(3)) + ALSCL::theme_acl() +
    ggplot2::labs(x = "Year", y = "Log survey index", colour = NULL,
      title = "Survey observations simulated from a fitted ALSCL model",
      caption = paste0("Scalar parameters are fixed at their estimates. The black dashed line is the fitted log median;\n",
        "each solid line is one simulation, not an uncertainty band."))
  # Two columns of simulation modes, one row per length bin.
  p <- tidy_time_axis(p, b$year, outer_cols = 2L, expand = c(.03, .03))
  save_grid_free_plot(file.path(figures, "fitted-simulation.png"), p, width = 10, height = 7)
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
  values <- c("Observed" = "observed_log", "Model prediction" = "predicted_log",
              "Last observed value" = "naive_log")
  d <- do.call(rbind, lapply(names(values), function(name)
    data.frame(d[c("model", "year", "length_label")], series = name, log_index = d[[values[[name]]]])))
  # Diagnostics retain every failure; a missing prediction is not plotted as zero.
  d <- d[is.finite(d$log_index), , drop = FALSE]
  d$series <- factor(d$series, levels = names(values))
  p <- ggplot2::ggplot(d, ggplot2::aes(year, log_index, colour = series,
      shape = series, linetype = series)) +
    ggplot2::geom_line(linewidth = .7) + ggplot2::geom_point(size = 2.5) +
    ggplot2::facet_grid(length_label ~ model, scales = "free_y", labeller = length_strip) +
    ggplot2::scale_color_manual(values = c(Observed = "black",
      "Model prediction" = ALSCL::acl_palette(role = "primary")[[1]],
      "Last observed value" = ALSCL::acl_palette(role = "accent")[[1]])) +
    ggplot2::scale_x_continuous(breaks = sort(unique(d$year)), expand = ggplot2::expansion(mult = .15)) +
    # Room for the point symbols at the top and bottom of each short panel.
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = .1)) +
    ALSCL::theme_acl() +
    ggplot2::labs(x = "Withheld year", y = "Log survey index", colour = NULL,
      shape = NULL, linetype = NULL, title = "One-step predictions of withheld survey observations",
      caption = paste0("Each prediction comes from a separate fit to the years before it.\n",
        "The last two years of the synthetic YTF data are withheld. No prediction intervals are shown."))
  # One row per length bin, so each bin keeps its own y scale; three rows need more
  # height than acl_figure_size() gives.
  save_grid_free_plot(file.path(figures, "hindcast-predictions.png"), p, width = 10, height = 7)
  archive <- tempfile(fileext = ".rds")
  on.exit(unlink(archive), add = TRUE)
  ALSCL::save_assessment(b, archive)
  saved <- ALSCL::read_assessment(archive)
  again <- ALSCL::simulate_fit(saved, nsim = 3, seed = 20261101, process = "conditional")
  stopifnot(identical(again$simulations, conditional$simulations), is.null(saved$obj))
  self_test_result <- run_self_test_guide(out, fit = fits$acl)
  jsonlite::write_json(list(seed = 20261101, source_fit_numerical_ok =
    c(ACL = fits$acl$diagnostics$numerical_ok, ALSCL = b$diagnostics$numerical_ok),
    validation_diagnostics = diagnostics, validation_scores = scores,
    simulation_replicates = 3L, simulation_summary = performance$summary,
    archive_simulation_equal = TRUE, figures_grid_free = TRUE,
    parameter_uncertainty = "none"), file.path(results, "verification.json"),
    pretty = TRUE, auto_unbox = TRUE, na = "null")
  invisible(list(fits = fits, conditional = conditional, resampled = resampled,
    refits = refits, performance = performance, validation = validations,
    self_test = self_test_result))
}
