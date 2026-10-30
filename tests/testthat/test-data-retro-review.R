test_that("fitting and diagnostics agree for matrices, tibbles and numeric factors", {
  for (model in c("ACL", "ALSCL")) {
    fixture <- fit_fixture(model)
    numeric_data <- fixture$input$data.CatL
    # A character matrix formats numeric columns; use decimal observations
    # that represent the same values in every tested storage class.
    numeric_data[-1L] <- lapply(numeric_data[-1L], round, digits = 3L)
    fixture$input$data.CatL <- numeric_data
    fixture$result <- do.call(if (model == "ACL") run_acl else run_alscl,
      c(fixture$input, list(parameters = fixture$parameters,
        map = fixture$map, silent = TRUE)))
    factors <- numeric_data
    for (i in seq_along(factors)) {
      values <- as.character(factors[[i]])
      factors[[i]] <- factor(values, levels = rev(unique(values)))
    }
    variants <- list(numeric_data, as.matrix(numeric_data),
      dplyr::as_tibble(numeric_data), factors, dplyr::as_tibble(factors))
    expected <- diagnostic_metrics(numeric_data, fixture$result)
    capture.output(reference <- compare_models(fixture$result, fixture$result,
      numeric_data, "Reference", "Alternative"))
    for (data in variants) {
      args <- c(fixture$input, list(parameters = fixture$parameters,
        map = fixture$map, silent = TRUE))
      args$data.CatL <- data
      fit <- do.call(if (model == "ACL") run_acl else run_alscl, args)
      expect_equal(fit$report$SSB, fixture$result$report$SSB, tolerance = 1e-10)
      expect_equal(diagnostic_metrics(data, fixture$result), expected)
      capture.output(compared <- compare_models(fixture$result, fixture$result,
        data, "Reference", "Alternative"))
      expect_identical(compared$comparison$data_verified, TRUE)
      expect_equal(compared$fit_metrics, reference$fit_metrics)
      expect_equal(compared$summary, reference$summary)
    }
  }
})

test_that("survey conversion preserves missing cells without decoding factor levels", {
  data <- data.frame(LengthBin = factor(c("10", "20")),
    `2000` = factor(c("12", NA), levels = c("12", "7")),
    `2001` = factor(c("0", "7"), levels = c("7", "0")), check.names = FALSE)
  expected <- matrix(c(12, NA, 0, 7), 2, 2)
  for (variant in list(data, as.matrix(data), dplyr::as_tibble(data))) {
    got <- ALSCL:::.acl_survey_data(variant)
    expect_identical(got$labels, c("10", "20"))
    expect_equal(got$observed, expected)
    expect_equal(got$mask, matrix(c(TRUE, FALSE, FALSE, TRUE), 2, 2))
  }
  data[[2L]] <- factor(c("invalid", "7"))
  expect_error(ALSCL:::.acl_survey_data(dplyr::as_tibble(data)),
    "numeric, nonnegative and finite")
})

test_that("retrospective maps retain time order, equality groups and named releases", {
  for (model in c("acl", "alscl")) {
    for (structure in c("group_year", "year")) {
      args <- fixture_frames()
      args$F_structure <- structure
      groups <- if (structure == "year") 1L else if (model == "acl")
        args$nage else nrow(args$data.CatL)
      rmap <- factor(c("early", NA, "shared", "early", "last"),
        levels = c("last", "shared", "early"))
      fmap <- factor(rep(c("same", NA, "same", "late", "last"), each = groups),
        levels = c("last", "late", "same"))
      args$map <- list(dev_log_R = rmap, dev_log_F = fmap,
        dev_log_N0 = factor(c("a", NA, "a")), log_std_log_F = NULL)
      original <- args$map
      expect_identical(ALSCL:::.acl_retro_map(args, 0L, model), original)
      truncated <- ALSCL:::.acl_retro_map(args, 1L, model)
      expect_identical(as.character(truncated$dev_log_R), as.character(rmap[1:4]))
      expect_identical(levels(truncated$dev_log_R), c("shared", "early"))
      expect_identical(truncated$dev_log_R[1], truncated$dev_log_R[4])
      expect_identical(as.character(truncated$dev_log_F),
        as.character(fmap[seq_len(groups * 4L)]))
      expect_identical(levels(truncated$dev_log_F), c("late", "same"))
      expect_identical(truncated$dev_log_N0, original$dev_log_N0)
      expect_identical(truncated["log_std_log_F"], list(log_std_log_F = NULL))
      expect_identical(args$map, original)
      args$map["dev_log_R"] <- list(NULL)
      expect_identical(ALSCL:::.acl_retro_map(args, 2L, model)["dev_log_R"],
        list(dev_log_R = NULL))
      args$map <- NULL
      expect_null(ALSCL:::.acl_retro_map(args, 2L, model))
    }
  }
})

test_that("retrospective maps must describe the complete original time grid", {
  args <- fixture_frames()
  for (peel in 0:2) {
    args$map <- list(dev_log_R = factor(rep(NA, 4)))
    expect_error(ALSCL:::.acl_retro_map(args, peel, "acl"),
      "dev_log_R.*complete input time grid")
    args$map <- list(dev_log_F = factor(rep(NA, 4 * args$nage)))
    expect_error(ALSCL:::.acl_retro_map(args, peel, "acl"),
      "dev_log_F.*complete input time grid")
    args$map <- list(dev_log_R = 1:5)
    expect_error(ALSCL:::.acl_retro_map(args, peel, "acl"), "must be factors")
  }
  args$map <- list(dev_log_R = factor(rep(NA, 4)))
  for (fun in list(retro_acl, retro_alscl)) {
    expect_warning(result <- fun(args, nyear = 2, silent = TRUE),
      "Mohn's rho is unavailable")
    expect_equal(result$errors$Peel, 0:2)
    expect_true(all(grepl("complete input time grid", result$errors$error)))
    expect_equal(nrow(result$results), 0L)
  }
})

test_that("time-dependent maps work in actual sequential and socket retrospectives", {
  for (model in c("ACL", "ALSCL")) {
    fixture <- fit_fixture(model)
    for (structure in c("group_year", "year")) {
      groups <- if (structure == "year") 1L else if (model == "ACL")
        fixture$input$nage else nrow(fixture$input$data.CatL)
      mapping <- fixture$map
      mapping$dev_log_R <- factor(c("shared", NA, "shared", "late", "last"))
      mapping$dev_log_F <- factor(rep(NA, groups * 5L))
      args <- c(fixture$input, list(parameters = fixture$parameters, map = mapping,
        F_structure = structure, silent = TRUE))
      fn <- if (model == "ACL") retro_acl else retro_alscl
      serial <- fn(args, nyear = 2, silent = TRUE)
      concurrent <- fn(args, nyear = 2, ncores = 2, silent = TRUE)
      expect_equal(nrow(serial$errors), 0L)
      expect_equal(nrow(concurrent$errors), 0L)
      expect_true(all(serial$fit_diagnostics$numerical_ok))
      expect_true(all(concurrent$fit_diagnostics$numerical_ok))
      expect_equal(concurrent$results, serial$results, tolerance = 1e-8)
      expect_equal(concurrent$rho_text, serial$rho_text, tolerance = 1e-8)
      expect_equal(concurrent$workers, 2L)
      # An independently sliced map gives the same terminal population values.
      manual <- args
      for (nm in c("data.CatL", "data.wgt", "data.mat"))
        manual[[nm]] <- manual[[nm]][, 1:4, drop = FALSE]
      manual$map$dev_log_R <- droplevels(mapping$dev_log_R[1:3])
      manual$map$dev_log_F <- droplevels(mapping$dev_log_F[seq_len(groups * 3L)])
      fitted <- if (model == "ACL") run_acl(manual) else run_alscl(manual)
      expected <- serial$results[serial$results$Peel == 2L &
        serial$results$Variable == "SSB", "Value"]
      expect_equal(expected, fitted$report$SSB, tolerance = 1e-8)
    }
  }
})
