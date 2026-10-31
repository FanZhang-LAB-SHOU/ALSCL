test_that("parameter extraction distinguishes estimates, fixed values and scales", {
  for (model in c("ACL", "ALSCL")) {
    fit <- fit_fixture(model)$result
    expect_s3_class(fit, "alscl_fit")
    expect_identical(stats::coef(fit), fit$opt$par)
    expect_identical(stats::vcov(fit), fit$vcov)
    raw <- extract_parameters(fit, "internal")
    natural <- extract_parameters(fit)
    rec <- raw$parameter == "mean_log_R"
    expect_equal(raw$estimate[rec], unname(fit$opt$par["mean_log_R"]))
    expect_equal(raw$std_error[rec], sqrt(fit$vcov["mean_log_R", "mean_log_R"]))
    expect_equal(natural$estimate[rec], exp(raw$estimate[rec]))
    expect_equal(natural$conf_low[rec], exp(raw$conf_low[rec]))
    expect_equal(natural$std_error[rec], exp(raw$estimate[rec]) * raw$std_error[rec])
    expect_equal(natural$estimate[natural$parameter == "log_Linf"], 60)
    fixed <- natural$status == "fixed"
    expect_true(any(fixed))
    expect_true(all(is.na(natural$std_error[fixed])))
    expect_true(all(is.na(natural$conf_low[fixed])))
    expect_equal(nrow(natural), length(create_parameters(tolower(model))$parameters))
    expect_s3_class(summary(fit), "summary.alscl_fit")
    expect_output(print(fit), "assessment")
    fit$recipe <- NULL
    expect_equal(nrow(extract_parameters(fit)), length(fit$opt$par))
    fit$vcov <- NULL
    expect_true(all(is.na(extract_parameters(fit)$std_error)))
  }
  expect_error(extract_parameters(list(opt = list(par = c(a = 1))), conf_level = 1), "conf_level")
})

test_that("population extraction preserves physical coordinates and available uncertainty", {
  for (model in c("ACL", "ALSCL")) {
    fit <- fit_fixture(model)$result
    data <- extract_estimates(fit, c("SSB", "NA", "NL", "F"))
    ssb <- data[data$quantity == "SSB", ]
    expect_identical(ssb$year, fit$year)
    expect_equal(ssb$estimate, as.numeric(fit$report$SSB))
    expect_equal(ssb$std_error, unname(fit$est_std[rownames(fit$est_std) == "SSB", "Std. Error"]))
    expect_equal(ssb$conf_low, ssb$estimate - qnorm(.975) * ssb$std_error)
    ages <- data[data$quantity == "NA", ]
    expect_identical(ages$age, rep(fit$age, length(fit$year)))
    expect_equal(ages$estimate, as.numeric(fit$report[["NA"]]))
    lengths <- data[data$quantity == "NL", ]
    expect_identical(lengths$length, rep(fit$len_mid, length(fit$year)))
    fishing <- data[data$quantity == "F", ]
    report_name <- if (model == "ACL") "F" else "FL"
    expect_true(all(fishing$report_name == report_name))
    expect_equal(fishing$estimate, as.numeric(fit$report[[report_name]]))
    if (model == "ALSCL") {
      joint <- extract_estimates(fit, "NLA")
      expect_equal(joint$estimate, as.numeric(fit$report$NLA))
      expect_equal(joint$length[1:9], fit$len_mid)
      expect_equal(joint$age[1:9], rep(fit$age[1], 9))
      expect_true(all(is.na(joint$std_error)))
      fa <- extract_estimates(fit, "FA")
      expect_equal(unique(fa$year), head(fit$year, -1))
      expect_equal(unique(fa$age), head(fit$age, -1))
    }
    fit$obj <- NULL
    expect_identical(extract_estimates(fit, c("SSB", "NA", "NL", "F")), data)
    fit$est_std <- NULL
    expect_true(all(is.na(extract_estimates(fit)$conf_high)))
    expect_error(extract_estimates(fit, "fish"), "Unsupported")
    fit$len_mid <- numeric()
    expect_error(extract_estimates(fit, "NL"), "length coordinates|Length/time")
  }
})

test_that("archives preserve recipes, refit settings and leave live inputs unchanged", {
  for (model in c("ACL", "ALSCL")) {
    fit <- fit_fixture(model)$result
    path <- tempfile(fileext = ".rds"); on.exit(unlink(path), add = TRUE)
    save_assessment(fit, path)
    expect_false(is.null(fit$obj))
    saved <- read_assessment(path)
    expect_s3_class(saved, "alscl_fit")
    expect_null(saved$obj)
    expect_identical(saved$recipe, fit$recipe)
    expect_identical(saved$report, fit$report)
    expect_identical(extract_estimates(saved), extract_estimates(fit))
    expect_identical(extract_parameters(saved), extract_parameters(fit))
    expect_error(save_assessment(fit, path), "already exists")
    expect_invisible(save_assessment(fit, path, overwrite = TRUE))
    replay <- refit_model(saved, silent = TRUE)
    expect_equal(replay$report$SSB, fit$report$SSB, tolerance = 1e-10)
    expect_equal(replay$opt$par, fit$opt$par, tolerance = 1e-10)
    expect_false(is.null(replay$obj))
    expect_false(replay$recipe$args$output)
    changed <- refit_model(saved, M = .25, silent = TRUE)
    expect_equal(changed$recipe$args$M, .25)
    expect_equal(saved$recipe$args$M, .2)
    expect_error(save_assessment(fit, path, x = fit$recipe$args, overwrite = TRUE), "older fits")
    legacy <- fit; legacy$recipe <- NULL
    expect_error(save_assessment(legacy, path, overwrite = TRUE), "complete fit recipe")
    save_assessment(legacy, path, x = fit$recipe$args, overwrite = TRUE)
    expect_match(read_assessment(path)$recipe$provenance, "unverified")
  }
  path <- tempfile(); on.exit(unlink(path), add = TRUE)
  saveRDS(list(schema_version = 999L), path)
  expect_error(read_assessment(path), "Unsupported")
})
