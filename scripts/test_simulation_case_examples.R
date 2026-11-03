# Check that both translations and the figure script fit the same conditional
# models. This resolves effective starts/maps without compiling or optimizing.
check_simulation_case_examples <- function() {
  library(ALSCL)
  script <- new.env(parent = as.environment("package:ALSCL"))
  sys.source("scripts/case_studies.R", envir = script)
  blocks <- function(path) {
    text <- paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
    raw <- regmatches(text, gregexpr("(?s)```r\\n.*?\\n```", text, perl = TRUE))[[1L]]
    lapply(raw, function(x) sub("^```r\\n", "", sub("\\n```$", "", x)))
  }
  # Evaluate preparation through the first fitting call, so mistakes in an
  # example's parameter conversion, map or fitting controls are exercised.
  prepare <- function(code, e) {
    for (expr in parse(text = code)) {
      if (any(all.names(expr) %in% c("run_acl", "run_alscl", "sim_acl"))) break
      eval(expr, e)
    }
  }
  verify <- function(x, sp, context) {
    pa <- initialize_params(species = sp, first.year = 2000,
                            observation_error = "independent")
    inputs <- read_survey_csv(file.path("docs/data/cases", sp))
    expected <- script$case_fit_bundle(inputs, pa)
    stopifnot(identical(x$fit_args$train_times, expected$fit_args$train_times),
              identical(x$fit_args$ncores, expected$fit_args$ncores),
              identical(x$fit_args$growth_step, expected$fit_args$growth_step))
    for (model in c("acl", "alscl")) {
      check <- check_alscl_data(x, model)
      stopifnot(isTRUE(check$valid), check$summary$free_fixed == 5L,
                check$summary$positive == 460L)
      actual <- inspect_parameters(x, model)
      wanted <- inspect_parameters(expected, model)
      stopifnot(isTRUE(all.equal(actual, wanted)))
      sd_name <- if (model == "acl") "log_std_log_F" else "log_sigma_log_F"
      sd_row <- actual[actual$parameter == sd_name, ]
      stopifnot(sd_row$status == "fixed",
                abs(sd_row$natural_start - 0.3023715784073818) < 1e-12,
                abs(sd_row$natural_start - pa$F_sd) > 0.1)
    }
    cat("PASS simulation example parameters/maps/time step:", context, sp, "\n")
  }
  for (lang in c("en", "zh")) {
    folder <- paste0("website/content/", lang, "/articles/")
    case_blocks <- blocks(paste0(folder, "case-studies.md"))
    e <- new.env(parent = as.environment("package:ALSCL"))
    eval(parse(text = case_blocks[[1L]]), e)
    prepare(case_blocks[[2L]], e)
    verify(e$x, "flatfish", paste(lang, "case-studies"))
    prepare(case_blocks[[3L]], e)
    verify(e$xq, "tuna", paste(lang, "case-studies"))
    simulation_blocks <- blocks(paste0(folder, "case-simulate-survey.md"))
    e <- new.env(parent = as.environment("package:ALSCL"))
    e$pa <- initialize_params(species = "flatfish", first.year = 2000,
                              observation_error = "independent")
    e$inputs <- read_survey_csv("docs/data/cases/flatfish")
    prepare(simulation_blocks[[4L]], e)
    verify(e$x, "flatfish", paste(lang, "case-simulate-survey"))
    batch_blocks <- blocks(paste0(folder, "simulation.md"))
    prepare(batch_blocks[[4L]], e)
    expected_sd <- e$pa$F_sd / sqrt(1 - e$pa$F_ar^2)
    stopifnot(abs(exp(e$cfg$parameters$log_std_log_F) - expected_sd) < 1e-12,
              is.factor(e$cfg$map$log_std_log_F), all(is.na(e$cfg$map$log_std_log_F)))
    cat("PASS batch simulation example marginal F SD:", lang, "\n")
  }
  invisible(TRUE)
}
