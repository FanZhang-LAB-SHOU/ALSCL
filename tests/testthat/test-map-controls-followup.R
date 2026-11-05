test_that("unknown releases are rejected before removing named NULL map entries", {
  local_mocked_bindings(.acl_compile = function(...) stop("unexpected compilation"))
  expect_error(generate_map(list(log_sd_log_F = NULL)), "Unknown map parameter: log_sd_log_F")
  expect_false("log_std_log_F" %in% names(generate_map(list(log_std_log_F = NULL))))
  expect_identical(generate_map(list(dev_log_R = factor(1:3)))$dev_log_R, factor(1:3))
  for (model in c("acl", "alscl")) {
    run <- if (model == "acl") run_acl else run_alscl
    x <- fixture_frames()
    x$map <- list(log_sd_log_F = NULL)
    check <- check_alscl_data(x, model)
    expect_false(check$valid)
    expect_identical(check$errors, "Unknown map parameter: log_sd_log_F")
    expect_error(run(x), "Unknown map parameter: log_sd_log_F")
    key <- if (model == "acl") "log_std_log_F" else "log_sigma_log_F"
    names(x$map) <- key
    params <- inspect_parameters(x, model)
    expect_identical(params$status[params$parameter == key], "free")
  }
})

test_that("unused map levels preserve fixed entries, groups and fitted estimates", {
  withr::local_options(list(ALSCL.sd_cores = 1L, ALSCL.framework = "CppAD"))
  for (model in c("acl", "alscl")) {
    example <- fit_fixture(toupper(model))
    x <- c(example$input, list(parameters = example$parameters, map = example$map,
      control = list(maxiter = 200L, eval.max = 400L), silent = TRUE))
    # One of the two free groups is labelled NA. The third period has a
    # genuinely missing factor code, which fixes it at zero in every peel.
    x$map$dev_log_R <- factor(c("early", "early", "early", NA, NA),
      levels = c("unused", "early", NA), exclude = NULL)
    is.na(x$map$dev_log_R)[3] <- TRUE
    x$map$mean_log_R <- factor(3, levels = 1:3)
    run <- if (model == "acl") run_acl else run_alscl
    checked <- check_alscl_data(x, model)
    expect_true(checked$valid)
    fit <- run(x)
    expect_identical(fit$recipe$args$map, x$map)
    expect_true(fit$diagnostics$numerical_ok)
    expect_equal(length(fit$obj$env$random), checked$summary$free_random)
    expect_identical(names(fit$opt$par), "mean_log_R")
    dev <- fit$report$dev_log_R
    expect_equal(as.numeric(dev), c(dev[1], dev[1], 0, dev[4], dev[4]))
    expected <- x
    expected$map$dev_log_R <- factor(c(1, 1, NA, 2, 2))
    expected$map$mean_log_R <- factor(1)
    expected$control <- list(iter.max = 200L, eval.max = 400L)
    other <- run(expected)
    expect_identical(fit$opt$par, other$opt$par)
    expect_identical(fit$report$SSB, other$report$SSB)
    expect_identical(extract_parameters(fit), extract_parameters(other))
    retro <- retro_model(data.CatL = x, nyear = 1, model = model, silent = TRUE)
    expect_true(all(retro$fit_diagnostics$error == ""))
    expect_true(all(retro$fit_diagnostics$numerical_ok))
    expected_retro <- retro_model(data.CatL = expected, nyear = 1, model = model,
                                  silent = TRUE)
    expect_identical(retro$results, expected_retro$results)
    expect_error(hindcast_model(x, model, nfolds = 1), "fixed or tied")
    # Each period in this map is free and distinct, including its NA-labelled
    # group; the hindcast fold should retain exactly four groups after slicing.
    x$map$dev_log_R <- factor(c(NA, "b", "c", "d", "e"),
      levels = c("unused", NA, "b", "c", "d", "e"), exclude = NULL)
    fold <- hindcast_model(x, model, nfolds = 1)
    expect_true(fold$diagnostics$prediction_ok)
    training_map <- fold$settings[[1L]]$map$dev_log_R
    expect_equal(nlevels(training_map), 4L)
    expect_identical(as.integer(training_map), 1:4)
  }
})

test_that("preflight and both fitting entry points reject malformed optimizer controls", {
  local_mocked_bindings(.acl_compile = function(...) stop("unexpected compilation"))
  bad_controls <- list(list(100), list(iter.max = 3, iter.max = 20),
    list(itre.max = 2), list(step = 1), list(maxiter = 10, iter.max = 20),
    list(iter.max = NA_real_), list(eval.max = -1), list(iter.max = 1.1),
    list(iter.max = 2^31), list(rel.tol = c(1, 2)), list(x.tol = "small"))
  for (model in c("acl", "alscl")) {
    run <- if (model == "acl") run_acl else run_alscl
    x <- fixture_frames()
    for (control in bad_controls) {
      x$control <- control
      check <- check_alscl_data(x, model)
      expect_false(check$valid)
      expect_match(check$errors, "control")
      expect_error(run(x), check$errors, fixed = TRUE)
    }
  }
  expect_identical(.acl_fit_control(list(iter = 20L, trace = FALSE)),
    list(iter.max = 20L, eval.max = 10000L, trace = FALSE))
  expect_identical(.acl_fit_control(list(eval.max = NULL)), list(iter.max = 2000L))
})
