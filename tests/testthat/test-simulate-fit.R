test_that("fitted-model simulation preserves conditional reports and refittable inputs", {
  old <- options(ALSCL.sd_cores = 1L)
  on.exit(options(old), add = TRUE)
  for (model in c("ACL", "ALSCL")) {
    z <- fit_fixture(model)
    for (structure in c("group_year", "year")) {
      fit <- if (structure == "year") refit_model(z$result, F_structure = "year") else z$result
      fit$obj <- NULL
      original <- fit
      simulated <- simulate_fit(fit, nsim = 2, seed = 30)
      expect_identical(fit, original)
      expect_identical(simulated$metadata$parameter_uncertainty, "none")
      expect_identical(simulated$metadata$source_fit_status, "passed")
      expect_identical(simulated$metadata$F_structure, structure)
      expect_length(simulated$simulations, 2L)
      for (one in simulated$simulations) {
        expect_equal(one$truth$Elog_index, fit$report$Elog_index)
        expect_equal(one$truth$SSB, fit$report$SSB)
        expect_equal(one$truth$F, fit$report[[if (model == "ACL") "F" else "FL"]])
        expect_equal(one$truth$expected_index,
          exp(fit$report$Elog_index + one$truth$observation_sd^2 / 2))
        expect_identical(one$truth$year, fit$year)
        expect_identical(names(one$x$data.CatL), names(fit$recipe$args$data.CatL))
        expect_identical(one$x$data.CatL[[1]], fit$recipe$args$data.CatL[[1]])
        expect_identical(one$x$data.wgt, fit$recipe$args$data.wgt)
        expect_identical(one$x$data.mat, fit$recipe$args$data.mat)
        expect_true(check_alscl_data(one$x, tolower(model))$valid)
        expect_false(any(c("output", "ncores", "silent") %in%
          names(one$x$fit_config[[tolower(model)]])))
        expect_identical(one$x$fit_config[[tolower(model)]]$nstarts, fit$recipe$args$nstarts)
        expect_true(all(one$observations > 0))
      }
      expect_false(identical(simulated$simulations[[1]]$observations,
        simulated$simulations[[2]]$observations))
      refit <- if (model == "ACL") run_acl(simulated$simulations[[1]]$x) else
        run_alscl(simulated$simulations[[1]]$x)
      expect_true(is.finite(refit$opt$objective))
      expect_identical(refit$F_structure, structure)
      expect_equal(refit$observations, simulated$simulations[[1]]$observations)
    }
  }
})

test_that("resampled processes agree with both fitted C++ population models", {
  old <- options(ALSCL.sd_cores = 1L)
  on.exit(options(old), add = TRUE)
  for (model in c("ACL", "ALSCL")) {
    z <- fit_fixture(model)
    for (structure in c("group_year", "year")) {
      fit <- if (structure == "year") refit_model(z$result, F_structure = "year") else z$result
      fit$obj <- NULL
      a <- simulate_fit(fit, nsim = 2, seed = 921, process = "resample")
      b <- simulate_fit(fit, nsim = 2, seed = 921, process = "resample")
      expect_identical(a, b)
      truth <- a$simulations[[1]]$truth
      expect_equal(length(truth$random_effects$dev_log_R), length(fit$year))
      expect_equal(length(truth$random_effects$dev_log_N0), length(fit$age) - 1L)
      expect_equal(nrow(truth$random_effects$dev_log_F),
        if (structure == "year") 1L else if (model == "ACL") length(fit$age) else length(fit$len_mid))
      expect_false(identical(truth$Rec, a$simulations[[2]]$truth$Rec))
      expect_false(identical(truth$SSB, a$simulations[[2]]$truth$SSB))
      expect_equal(as.numeric(truth$Rec),
        exp(truth$parameters$mean_log_R + truth$random_effects$dev_log_R))
      generated_F <- exp(truth$parameters$mean_log_F + truth$random_effects$dev_log_F)
      if (structure == "year") generated_F <- generated_F[rep(1L, nrow(truth$F)), , drop = FALSE]
      expect_equal(truth$F, generated_F)
      preflight <- ALSCL:::.acl_preflight(fit$recipe$args, tolower(model))
      info <- ALSCL:::.acl_compile(model)
      core <- TMB::MakeADFun(preflight$setup$data,
        c(truth$parameters, truth$random_effects), random = NULL, map = NULL,
        DLL = info$dll_name, silent = TRUE)
      report <- core$report(core$par)
      for (name in c("N", "B", "SSB", "Rec", "CN", "NL", "NA", "Elog_index"))
        expect_equal(truth[[name]], report[[name]], tolerance = 1e-12)
      expect_true(check_alscl_data(a$simulations[[1]]$x, tolower(model))$valid)
      refit <- if (model == "ACL") run_acl(a$simulations[[1]]$x) else
        run_alscl(a$simulations[[1]]$x)
      expect_true(is.finite(refit$opt$objective))
      expect_equal(refit$observations, a$simulations[[1]]$observations)
    }
  }
})

test_that("simulation retains excluded zeros and missing observations without changing bins", {
  z <- fit_fixture("ACL")
  args <- z$result$recipe$args
  args$data.CatL[2, 2] <- 0
  args$data.CatL[3, 4] <- NA_real_
  fit <- do.call(run_acl, args)
  fit$obj <- NULL
  for (process in c("conditional", "resample")) {
    kept <- simulate_fit(fit, seed = 11, process = process)
    filled <- simulate_fit(fit, seed = 11, process = process, preserve_missing = FALSE)
    obs <- kept$simulations[[1]]$observations
    expect_identical(unname(obs[2, 1]), 0)
    expect_true(is.na(obs[3, 3]))
    mask <- is.finite(fit$observations) & fit$observations > 0
    expect_equal(obs[mask], filled$simulations[[1]]$observations[mask])
    expect_true(all(is.finite(filled$simulations[[1]]$observations)))
    expect_true(all(filled$simulations[[1]]$observations > 0))
    expect_identical(kept$metadata$observation_mask, mask)
    expect_identical(kept$metadata$len_mid, fit$len_mid)
    expect_identical(kept$metadata$year, fit$year)
  }
})

test_that("explicit simulation seeds restore the caller RNG and NULL consumes it", {
  fit <- fit_fixture("ACL")$result
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- .Random.seed
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  RNGkind("L'Ecuyer-CMRG")
  set.seed(920)
  before <- .Random.seed
  kind <- RNGkind()
  a <- simulate_fit(fit, nsim = 2, seed = 0, process = "resample")
  expect_identical(.Random.seed, before)
  expect_identical(RNGkind(), kind)
  expect_identical(a$metadata$RNGkind[1:2], c("Mersenne-Twister", "Inversion"))
  expect_identical(a, simulate_fit(fit, nsim = 2, seed = 0, process = "resample"))
  simulate_fit(fit, seed = NULL)
  expect_false(identical(.Random.seed, before))
  rm(".Random.seed", envir = .GlobalEnv)
  simulate_fit(fit, seed = 25)
  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
  expect_identical(RNGkind(), kind)
})

test_that("drawn AR1 fields have stationary marginal scale and separable correlations", {
  set.seed(629)
  fields <- replicate(2500, ALSCL:::.acl_simulate_ar1_field(3L, 4L, .6, .45, .7))
  expect_equal(mean(fields), 0, tolerance = .04)
  expect_equal(stats::sd(as.numeric(fields)), .7, tolerance = .035)
  expect_equal(stats::sd(fields[1, 1, ]), .7, tolerance = .04)
  expect_equal(stats::sd(fields[3, 4, ]), .7, tolerance = .04)
  expect_equal(stats::cor(fields[1, 1, ], fields[2, 1, ]), .6, tolerance = .06)
  expect_equal(stats::cor(fields[1, 1, ], fields[1, 2, ]), .45, tolerance = .06)
  expect_equal(stats::cor(fields[1, 1, ], fields[2, 2, ]), .6 * .45, tolerance = .06)
  single <- replicate(2500, ALSCL:::.acl_simulate_ar1_field(1L, 4L, 0, .7, .5))
  expect_equal(stats::sd(single[1, 1, ]), .5, tolerance = .03)
  expect_equal(stats::cor(single[1, 1, ], single[1, 2, ]), .7, tolerance = .05)
})

test_that("conditional observation draws use the fitted lognormal distribution", {
  fit <- fit_fixture("ACL")$result
  simulated <- simulate_fit(fit, nsim = 120, seed = 702)
  residuals <- unlist(lapply(simulated$simulations, function(s)
    log(s$observations) - fit$report$Elog_index))
  sigma <- simulated$simulations[[1]]$truth$observation_sd
  expect_equal(mean(residuals), 0, tolerance = .015)
  expect_equal(stats::sd(residuals), sigma, tolerance = .015)
  expect_equal(mean(exp(residuals)), exp(sigma^2 / 2), tolerance = .02)
})

test_that("simulation rejects unsupported maps and invalid or failed fits explicitly", {
  z <- fit_fixture("ACL")
  fit <- z$result
  for (value in list(0, -1, 1.1, Inf, NA_real_, "2", c(1, 2)))
    expect_error(simulate_fit(fit, nsim = value), "nsim must be an integer")
  for (value in list(-1, 1.1, Inf, NA_real_, "2", c(1, 2)))
    expect_error(simulate_fit(fit, seed = value), "seed must be an integer")
  for (name in c("preserve_missing", "allow_failed_fit"))
    for (value in list(1, NA, NULL, c(TRUE, FALSE)))
      expect_error(do.call(simulate_fit, c(list(fit), stats::setNames(list(value), name))),
        paste0(name, " must be TRUE or FALSE"))
  expect_error(simulate_fit(fit, process = "other"), "arg")
  failed <- fit; failed$diagnostics$numerical_ok <- FALSE
  expect_error(simulate_fit(failed), "failed the numerical screen")
  expect_warning(allowed <- simulate_fit(failed, seed = 10, allow_failed_fit = TRUE),
    "failed the numerical screen")
  expect_identical(allowed$metadata$source_fit_status, "failed")
  expect_true(allowed$metadata$failed_fit_override)
  unknown <- fit; unknown$diagnostics <- NULL
  expect_no_warning(unverified <- simulate_fit(unknown, seed = 10))
  expect_identical(unverified$metadata$source_fit_status, "unknown")
  for (name in c("dev_log_R", "dev_log_F", "dev_log_N0")) {
    args <- fit$recipe$args
    n <- if (name == "dev_log_R") length(fit$year) else if (name == "dev_log_F")
      length(fit$age) * length(fit$year) else length(fit$age) - 1L
    for (mapping in list(factor(rep(NA, n)), factor(rep(1L, n)))) {
      args$map[[name]] <- mapping
      mapped <- do.call(run_acl, args)
      expect_error(simulate_fit(mapped, process = "resample"), "fixed or tied random-effect maps")
      expect_no_warning(simulate_fit(mapped, seed = 10))
    }
  }
  invalid <- fit; invalid$recipe <- NULL
  expect_error(simulate_fit(invalid), "complete fit recipe")
  invalid <- fit; invalid$year <- rev(fit$year)
  expect_error(simulate_fit(invalid), "time columns")
  invalid <- fit; invalid$report$Elog_index[] <- -1000
  expect_error(simulate_fit(invalid, seed = 10), "underflows")
  invalid <- fit; invalid$report$Elog_index[] <- 708
  invalid$recipe$args$parameters$log_std_index <- log(10)
  expect_error(simulate_fit(invalid, seed = 10), "overflows")
})
