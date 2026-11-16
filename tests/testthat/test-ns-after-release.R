# Fixes after release 2.4.4: truth of the process means in a self-test, the
# rule for the last informed time step, the note on the start
# of mean_log_R with survey_q_age, the growth table of compare_models() and
# the warning of plot_VB(se = TRUE) for ALSCL.

after_count <- function(messages, pattern) sum(grepl(pattern, messages, fixed = TRUE))

test_that("self_test() compares mean_log_R with the source estimate in both modes", {
  skip_on_cran()
  fit <- fit_fixture("ACL")$result
  source <- exp(fit$opt$par[["mean_log_R"]])
  for (process in c("conditional", "resample")) {
    st <- self_test(fit, nsim = 2, seed = 3, quantities = "SSB", process = process)
    expect_null(st$settings$process_mean_truth)
    rows <- st$parameters[st$parameters$parameter == "mean_log_R", ]
    expect_equal(rows$truth, rep(source, 2))
    expect_equal(rows$relative_error, (rows$estimate - source) / source)
    expect_equal(st$parameter_summary$truth[st$parameter_summary$parameter == "mean_log_R"], source)
  }
})

test_that("extract_estimates() and relative_catch() use one rule for the last informed time step", {
  skip_on_cran()
  fit <- fit_fixture("ACL")$result
  years <- fit$year
  expect_identical(ALSCL:::.acl_last_informed(fit, years), max(years))
  fit$observations[, ncol(fit$observations)] <- NA
  fit$observations[1L, ncol(fit$observations) - 1L] <- 0
  last <- years[length(years) - 1L]
  expect_identical(ALSCL:::.acl_last_informed(fit, years), last)
  F_rows <- extract_estimates(fit, "F")
  expect_identical(F_rows$extrapolated, F_rows$year >= last)
  expect_identical(relative_catch(fit)$extrapolated, years >= last)
  none <- fit; none$observations[] <- NA
  expect_identical(ALSCL:::.acl_last_informed(none, years), max(years))
  legacy <- fit; legacy$observations <- NULL
  expect_identical(ALSCL:::.acl_last_informed(legacy, years), max(years))
})

test_that("a default start of mean_log_R moved by survey_q_age gives one message", {
  skip_on_cran()
  note <- "The default start of mean_log_R was changed by -log(survey_q_age[1])"
  base <- fit_fixture("ACL")
  args <- c(base$input, list(map = base$map, silent = FALSE, survey_q_age = rep(.5, base$input$nage)))
  start <- base$parameters; start$mean_log_R <- NULL
  args$parameters <- start
  messages <- testthat::capture_messages(fit <- do.call(run_acl, args))
  expect_identical(after_count(messages, note), 1L)
  expect_identical(after_count(messages, "-log(survey_q_age[1]) = 0.6931 (survey_q_age[1] = 0.5)"), 1L)
  expect_identical(after_count(messages, "supply it as parameters$mean_log_R"), 1L)
  # Silent fits, a supplied start and survey_q_age[1] = 1 give no message.
  expect_identical(after_count(testthat::capture_messages(do.call(run_acl, modifyList(args, list(silent = TRUE)))),
                               note), 0L)
  supplied <- args; supplied$parameters <- base$parameters
  expect_identical(after_count(testthat::capture_messages(do.call(run_acl, supplied)), note), 0L)
  ones <- args; ones$survey_q_age <- rep(1, base$input$nage)
  expect_identical(after_count(testthat::capture_messages(do.call(run_acl, ones)), note), 0L)
  # The shift itself is unchanged: the start is raised by -log(0.5).
  setup <- ALSCL:::.acl_model_setup("ACL", do.call(ALSCL:::.acl_prepare_data, c(base$input,
    list(survey_q_age = rep(.5, base$input$nage)))))
  expect_equal(setup$mean_log_R_shift, -log(.5))
  expect_null(ALSCL:::.acl_model_setup("ACL", do.call(ALSCL:::.acl_prepare_data, base$input))$mean_log_R_shift)
  # Once per call of a function that runs several fits.
  scenarios <- list(base = list(), high_M = list(M = .25))
  batch <- testthat::capture_messages(fit_scenarios(args, scenarios, model = "acl"))
  expect_identical(after_count(batch, note), 1L)
  retro <- testthat::capture_messages(do.call(retro_model, c(list(nyear = 1, model_type = "acl"),
    args[setdiff(names(args), "silent")])))
  expect_identical(after_count(retro, note), 1L)
  quiet <- testthat::capture_messages(do.call(retro_model, c(list(nyear = 1, model_type = "acl", silent = TRUE),
    args[setdiff(names(args), "silent")])))
  expect_identical(after_count(quiet, note), 0L)
  expect_identical(ALSCL:::.acl_q_age_start_shift(list(survey_q_age = c(.25, 1))), -log(.25))
  expect_null(ALSCL:::.acl_q_age_start_shift(list(survey_q_age = c(.25, 1), parameters = list(mean_log_R = 3))))
  expect_null(ALSCL:::.acl_q_age_start_shift(list()))
})

test_that("the note on the start of mean_log_R reaches the user once when fits run on socket workers", {
  note <- "The default start of mean_log_R was changed"
  settings <- list(list(silent = FALSE, nstarts = 2L, survey_q_age = c(.5, 1)),
                   list(silent = FALSE, nstarts = 2L, survey_q_age = c(.5, 1)))
  testthat::local_mocked_bindings(
    .acl_cluster_lapply = function(X, FUN, ncores, model, ...) vector("list", length(X)),
    .acl_workers = function(n) as.integer(n), .package = "ALSCL")
  expect_identical(after_count(testthat::capture_messages(ALSCL:::.acl_batch_apply(settings, "acl", 2L)), note), 1L)
  expect_identical(after_count(testthat::capture_messages(ALSCL:::.acl_batch_apply(settings, "acl", 1L)), note), 0L)
  quiet <- lapply(settings, function(s) modifyList(s, list(silent = TRUE)))
  expect_identical(after_count(testthat::capture_messages(ALSCL:::.acl_batch_apply(quiet, "acl", 2L)), note), 0L)
})

test_that("old code that reads a model column of compare_models()$growth fails with a clear error", {
  skip_on_cran()
  base <- fit_fixture("ACL")
  a <- base$result
  other <- fit_fixture("ALSCL")
  b <- do.call(run_alscl, c(base$input, list(parameters = other$parameters, map = other$map, silent = TRUE)))
  invisible(capture.output(cmp <- compare_models(a, b, base$input$data.CatL)))
  g <- cmp$growth
  expect_s3_class(g, "data.frame")
  expect_s3_class(g, "alscl_growth_table")
  expect_named(g, c("Model", "Parameter", "Estimate", "Meaning"))
  pattern <- "has columns Model, Parameter, Estimate and Meaning since version 2.4.4"
  expect_error(g$ALSCL, pattern)
  expect_error(g$ACL, "subset\\(cmp\\$growth, Model == \"ACL\"\\)")
  expect_error(g[["ALSCL"]], pattern)
  # Columns and other names work as for a data frame.
  expect_identical(g$Model, as.data.frame(g)$Model)
  expect_identical(g[["Estimate"]], as.data.frame(g)$Estimate)
  expect_identical(g[[2]], as.data.frame(g)[[2]])
  expect_null(g$Other)
  expect_identical(g[[3, "Estimate"]], as.data.frame(g)[[3, "Estimate"]])
  alscl <- subset(g, Model == "ALSCL")
  expect_identical(nrow(alscl), 6L)
  expect_identical(alscl$Parameter[1L], "Linf")
  expect_identical(g[g$Model == "ACL", "Parameter"], as.data.frame(g)[g$Model == "ACL", "Parameter"])
  # Printing and write.csv() work as for the plain table.
  expect_identical(capture.output(print(g)), capture.output(print(as.data.frame(g))))
  file <- tempfile(fileext = ".csv")
  on.exit(unlink(file), add = TRUE)
  utils::write.csv(g, file, row.names = FALSE)
  back <- utils::read.csv(file, stringsAsFactors = FALSE)
  expect_identical(back$Parameter, g$Parameter)
  expect_equal(back$Estimate, g$Estimate)
})

test_that("plot_VB(se = TRUE) for an ALSCL fit says how to draw the earlier interval", {
  skip_on_cran()
  fit <- fit_fixture("ALSCL")$result
  expect_warning(plot_VB(fit, se = TRUE), "add parameter_curve = TRUE")
  expect_warning(plot_VB(fit, se = TRUE), "curve computed from Linf, k and t0 with its interval")
})
