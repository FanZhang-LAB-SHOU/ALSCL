# Fitting safeguards from the review: random-effect maps (F01), default starts
# and bounds (F02), multistart behaviour (F34 and the local-optimum findings).

test_that("tied or fixed deviations are rejected when their process parameters are estimated", {
  skip_on_cran()
  for (model in c("ACL", "ALSCL")) {
    x <- fixture_frames()
    sd_name <- function(block) paste0(if (model == "ACL") "log_std_log_" else "log_sigma_log_", block)
    run <- if (model == "ACL") run_acl else run_alscl
    setup <- function(map, ...) ALSCL:::.acl_model_setup(model, do.call(ALSCL:::.acl_prepare_data, x), map = map, ...)
    expect_error(setup(list(dev_log_R = factor(c(1, 1, 2, 3, 4)))), "dev_log_R ties deviations")
    expect_error(setup(list(dev_log_R = factor(c(NA, 1, 2, 3, 4)))), "dev_log_R fixes deviations")
    expect_error(setup(list(dev_log_N0 = factor(c(1, 1, 2)))), sd_name("N0"))
    groups <- if (model == "ACL") x$nage else nrow(x$data.CatL)
    tied_F <- factor(rep(1:5, each = groups))
    released <- stats::setNames(list(NULL), sd_name("F"))
    expect_error(setup(c(list(dev_log_F = tied_F), released)), "F_structure = \"year\"")
    # The default map fixes the F standard deviation but not every correlation.
    expect_error(setup(list(dev_log_R = factor(rep(NA, 5)), logit_log_R = factor(NA))), sd_name("R"))
    fixed_R <- stats::setNames(list(factor(rep(NA, 5)), factor(NA), factor(NA)),
                               c("dev_log_R", sd_name("R"), "logit_log_R"))
    expect_identical(setup(fixed_R)$restricted_random, "dev_log_R")
    expect_identical(setup(NULL)$restricted_random, character())
    expect_error(run(c(x, list(map = list(dev_log_R = factor(c(1, 1, 2, 3, 4))), silent = TRUE))), "ties deviations")
    expect_false(check_alscl_data(c(x, list(map = list(dev_log_R = factor(c(1, 1, 2, 3, 4))))), tolower(model))$valid)
  }
})

test_that("default Linf start and bounds follow the data when the ACL defaults do not suit them", {
  frames <- function(mid) {
    f <- fixture_frames()
    for (nm in c("data.CatL", "data.wgt", "data.mat")) f[[nm]][[1]] <- as.character(mid)
    f
  }
  setup <- function(mid, ...) ALSCL:::.acl_model_setup("ACL", do.call(ALSCL:::.acl_prepare_data, frames(mid)), ...)
  linf <- function(s) exp(c(start = s$parameters$log_Linf, lower = s$config$parameters.L$log_Linf,
                            upper = s$config$parameters.U$log_Linf))
  # Lengths on the scale of the yellowtail flounder example keep the published defaults.
  expect_equal(linf(setup(seq(15, 55, 5))), c(start = 60, lower = 10, upper = 100))
  # Tuna lengths in cm and lengths in mm use the data-based rule.
  expect_equal(linf(setup(seq(40, 120, 10))), c(start = 132, lower = 84, upper = 240))
  expect_equal(linf(setup(seq(150, 550, 50))), c(start = 605, lower = 385, upper = 1100))
  expect_equal(linf(setup(seq(1, 5, .5))), c(start = 5.5, lower = 3.5, upper = 10))
  # Supplied values are kept.
  kept <- linf(setup(seq(40, 120, 10), parameters = list(log_Linf = log(150)), parameters.U = list(log_Linf = log(300))))
  expect_equal(kept, c(start = 150, lower = 84, upper = 300))
  expect_null(setup(seq(40, 120, 10))$clamped_starts)
})

test_that("starts moved into the bounds are reported", {
  f <- fixture_frames()
  prepared <- do.call(ALSCL:::.acl_prepare_data, f)
  moved <- ALSCL:::.acl_model_setup("ACL", prepared, parameters = list(log_vbk = log(5)))
  expect_identical(moved$clamped_starts$parameter, "log_vbk")
  expect_true(moved$clamped_starts$supplied)
  expect_equal(moved$parameters$log_vbk, log(1))
  expect_warning(ALSCL:::.acl_report_clamped(moved$clamped_starts), "log_vbk.*moved to")
  narrowed <- ALSCL:::.acl_model_setup("ACL", prepared, parameters.U = list(log_cv_len = log(.2)))
  expect_false(narrowed$clamped_starts$supplied)
  expect_message(ALSCL:::.acl_report_clamped(narrowed$clamped_starts), "Default starting values")
  expect_silent(ALSCL:::.acl_report_clamped(narrowed$clamped_starts, silent = TRUE))
  expect_silent(ALSCL:::.acl_report_clamped(NULL))
  # A large natural mortality no longer pushes the default init_Z start onto its bound.
  f$M <- 1.2
  large_M <- ALSCL:::.acl_model_setup("ACL", do.call(ALSCL:::.acl_prepare_data, f))
  expect_null(large_M$clamped_starts)
  expect_equal(large_M$parameters$log_init_Z, log(1.5))
  expect_gt(large_M$config$parameters.U$log_init_Z, log(1.5))
})

test_that("sequential starts on one reused object equal starts on new objects", {
  skip_on_cran()
  withr::local_options(list(ALSCL.sd_cores = 1L, ALSCL.framework = "CppAD"))
  for (model in c("ACL", "ALSCL")) {
    example <- fit_fixture(model)
    mapping <- example$map; mapping$log_init_Z <- NULL
    mapping[[if (model == "ACL") "log_std_index" else "log_sigma_index"]] <- NULL
    args <- c(example$input, list(parameters = example$parameters, map = mapping, silent = TRUE))
    run <- if (model == "ACL") run_acl else run_alscl
    reused <- do.call(run, c(args, list(nstarts = 3)))
    expect_length(reused$opt$par, 3L)
    prepared <- do.call(ALSCL:::.acl_prepare_data, example$input)
    setup <- ALSCL:::.acl_model_setup(model, prepared, example$parameters, map = mapping)
    dll <- ALSCL:::.acl_compile(model)$dll_name
    probe <- TMB::MakeADFun(setup$data, setup$parameters, random = setup$random, map = setup$map,
                            DLL = dll, silent = TRUE)
    bounds <- ALSCL:::.acl_bounds(probe$par, setup$config)
    fresh <- lapply(1:3, function(i) ALSCL:::.acl_fit_start(i, setup$data, setup$parameters, setup$map,
      setup$random, dll, bounds, 1L, ALSCL:::.acl_fit_control(list())))
    for (i in 1:3) {
      expect_identical(reused$starts[[i]]$par, fresh[[i]]$par)
      expect_identical(reused$starts[[i]]$objective, fresh[[i]]$objective)
      expect_identical(reused$starts[[i]]$initial, fresh[[i]]$initial)
    }
    single <- do.call(run, c(args, list(nstarts = 1)))
    expect_identical(reused$starts[[1]]$par, single$starts[[1]]$par)
    expect_identical(reused$start_summary$nstarts, 3L)
    expect_true(reused$start_summary$converged >= 1L)
    expect_identical(reused$start_spread, .15)
    wide <- do.call(run, c(args, list(nstarts = 2, start_spread = .5)))
    expect_equal((wide$starts[[2]]$initial - wide$starts[[1]]$initial) /
                 (reused$starts[[2]]$initial - reused$starts[[1]]$initial), rep(.5 / .15, 3), tolerance = 1e-8,
                 ignore_attr = TRUE)
    expect_identical(wide$recipe$args$start_spread, .5)
  }
  expect_error(run_acl(c(fixture_frames(), list(start_spread = 0))), "start_spread must be one positive number")
})

test_that("the start summary reports disagreement between converged starts", {
  starts <- list(list(objective = 10, convergence = 0L), list(objective = 10 + 1e-6, convergence = 0L),
                 list(objective = 14, convergence = 0L), list(objective = 2, convergence = 1L),
                 list(objective = Inf, convergence = 1L))
  s <- ALSCL:::.acl_start_summary(starts)
  expect_identical(s$nstarts, 5L)
  expect_identical(s$converged, 3L)
  expect_equal(s$objective_range, 4)
  expect_equal(s$best_objective, 2)
  expect_true(is.na(ALSCL:::.acl_start_summary(starts[1])$objective_range))
})

test_that("zero observations treated as missing are counted and reported", {
  f <- fixture_frames()
  f$data.CatL[2, 3] <- 0; f$data.CatL[4, 5] <- 0
  prepared <- do.call(ALSCL:::.acl_prepare_data, f)
  expect_identical(prepared$zero_observations, 2L)
  expect_identical(do.call(ALSCL:::.acl_prepare_data, fixture_frames())$zero_observations, 0L)
})

test_that("input checks name the problem", {
  expect_error(create_parameters("acl", parameters = list(log_t0 = -2)),
    "parameters has parameter\\(s\\) that the ACL model does not have: log_t0.*The ACL name is t0 \\(not log_t0\\)")
  expect_error(create_parameters("alscl", parameters.U = list(log_std_index = 0)),
    "parameters.U has parameter.*log_sigma_index \\(not log_std_index\\)")
  expect_error(create_parameters("acl", parameters = list(log_vbk = c(1, 2))), "check log_vbk")
  f <- fixture_frames()
  f$data.mat[[2]] <- rep(TRUE, nrow(f$data.mat))
  expect_error(do.call(ALSCL:::.acl_prepare_data, f), "data.mat contains nonnumeric")
  expect_warning(ALSCL:::.acl_length_bins(c("5", "15", "30", "60")), "unequal spacing")
  expect_silent(ALSCL:::.acl_length_bins(c("5", "15", "30", "60"), len_border = c(10, 20, 40)))
  expect_silent(ALSCL:::.acl_length_bins(c("5", "15", "25", "35")))
})
