test_that("quick simulated length abundance agrees with the compiled ACL tail convention", {
  for (breaks in list(c(20, 22, 25, 30, 40, 60), c(0, 20, 40), c(0, 15, 25, 35, 45, 60), c(-10, 20, 30, 40, 60))) {
    sm <- simulate_example_data(years = 2000:2004, bin_breaks = breaks,
      Linf = if (length(breaks) == 3L) 500 else 55,
      cv_catch = 0, rec_sigma = 0, seed = 1)
    truth <- sm$true_params
    prepared <- do.call(ALSCL:::.acl_prepare_data,
      c(sm[c("data.CatL", "data.wgt", "data.mat")], list(rec.age = 1,
        nage = truth$nage, M = truth$M, sel_L50 = truth$L50_sel, sel_L95 = truth$L95_sel)))
    d <- prepared$data
    p <- create_parameters("acl")$parameters
    p$log_Linf <- log(truth$Linf)
    p$log_vbk <- log(truth$vbk)
    p$t0 <- truth$t0
    p$log_cv_len <- log(truth$cv_len)
    p$dev_log_R <- rep(0, d$Y)
    p$dev_log_F <- array(0, c(d$A, d$Y))
    p$dev_log_N0 <- rep(0, d$A - 1L)
    compiled <- ALSCL:::.acl_compile("ACL")
    obj <- TMB::MakeADFun(d, p, DLL = compiled$dll_name, silent = TRUE)
    expected <- obj$report(obj$par)$pla %*% truth$N_at_age
    expect_equal(truth$N_at_len, expected, tolerance = 1e-12)
    expect_equal(colSums(truth$N_at_len), colSums(truth$N_at_age), tolerance = 1e-12)
    q <- mat_func(truth$L50_sel, truth$L95_sel, prepared$bins$mid)
    expect_equal(unname(as.matrix(sm$data.CatL[-1L])),
      unname(round(sweep(expected, 1L, q, "*"), 2)), tolerance = 1e-12)
  }
})

test_that("quick simulations reject invalid biology before creating CSV output", {
  output <- tempfile("quick-invalid-")
  on.exit(unlink(output, recursive = TRUE), add = TRUE)
  defaults <- list(years = 2000:2004, save_csv = TRUE, output_dir = output, seed = 1)
  invalid <- list(Linf = 0, vbk = -0.1, t0 = 1, M = -1,
    rec_sigma = -0.1, wgt_a = -1, wgt_b = Inf,
    L50_sel = NA_real_, L95_sel = 28, L50_mat = Inf, L95_mat = 33,
    bin_breaks = c(0, 20, Inf), cv_catch = Inf, mean_F = NA_real_)
  for (name in names(invalid)) {
    args <- defaults
    args[name] <- invalid[name]
    expect_error(do.call(simulate_example_data, args), name)
    expect_false(dir.exists(output))
  }
  for (name in c("Linf", "vbk", "t0", "M", "rec_sigma", "wgt_a", "wgt_b",
                 "L50_sel", "L95_sel", "L50_mat", "L95_mat")) {
    for (bad in list(numeric(), c(1, 2), NA_real_, "1")) {
      args <- defaults
      args[name] <- list(bad)
      expect_error(do.call(simulate_example_data, args), name)
    }
  }
  for (bad in list(c(-20, -10, 0), c(0, NA, 20), c(0, 20), c(0, 0, 20), "0,20,40")) {
    args <- defaults; args$bin_breaks <- bad
    expect_error(do.call(simulate_example_data, args), "bin_breaks")
  }
  args <- defaults; args$L50_sel <- args$L95_sel <- 22.5
  expect_error(do.call(simulate_example_data, args), "L95_sel")
  expect_false(dir.exists(output))
  for (bad in list(NA_integer_, Inf, -1, 1.5, c(1, 2), "1")) {
    args <- defaults; args$seed <- bad
    expect_error(do.call(simulate_example_data, args), "seed")
  }
  args <- defaults; args$save_csv <- NA
  expect_error(do.call(simulate_example_data, args), "save_csv")
  args <- defaults; args$output_dir <- character()
  expect_error(do.call(simulate_example_data, args), "output_dir")
})

test_that("quick simulations preserve valid boundaries and reject overflow before overwriting files", {
  folder <- tempfile("quick-valid-")
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  sm <- simulate_example_data(years = 2000.25 + 0:4, M = 0, mean_F = 0,
    t0 = -1, cv_catch = 0, rec_sigma = 0, seed = 0,
    L50_sel = 20, L95_sel = 20.1, L50_mat = 20, L95_mat = 20.1,
    bin_breaks = c(60, 20, 0, 40, 20), save_csv = TRUE, output_dir = folder)
  expect_equal(sm$true_params$bin_breaks, c(0, 20, 40, 60))
  expect_equal(sm$true_params$F_trend, rep(0, 5))
  expect_equal(names(sm$data.CatL)[-1L], as.character(2000.25 + 0:4))
  expect_equal(sm$true_params$N_at_age[2L, 2L], sm$true_params$N_at_age[1L, 1L])
  expect_true(all(is.finite(as.matrix(sm$data.CatL[-1L]))))
  expect_true(all(as.matrix(sm$data.mat[-1L]) >= 0 & as.matrix(sm$data.mat[-1L]) <= 1))
  files <- file.path(folder, c("sim_CatL.csv", "sim_wgt.csv", "sim_mat.csv"))
  before <- tools::md5sum(files)
  for (bad in list(list(rec_sigma = 1000), list(wgt_b = 1000), list(cv_catch = 1e300))) {
    expect_error(do.call(simulate_example_data, c(list(years = 2000:2004,
      seed = 1, save_csv = TRUE, output_dir = folder), bad)), "nonfinite.*no CSV")
    expect_identical(tools::md5sum(files), before)
  }
})

test_that("simulation probability arrays must conserve abundance before output is created", {
  folder <- tempfile("invalid-probabilities-")
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  for (species in c("flatfish", "tuna")) {
    params <- initialize_params(species = species, nyear = 4, burn_in = 2)
    bio <- sim_cal(params)
    expect_silent(ALSCL:::.acl_simulation_biology(bio, params, bio$model_type))
    bad <- bio
    bad$pla <- bad$pla / 2
    expect_error(sim_data(bad, params, iter_range = 1, output_dir = folder),
      "pla probabilities must sum to one")
    expect_false(dir.exists(folder))
    if (species == "tuna") {
      bad <- bio
      bad$Gij <- bad$Gij / 2
      expect_error(sim_data(bad, params, iter_range = 1, output_dir = folder),
        "Gij probabilities must sum to one")
      expect_false(dir.exists(folder))
    }
  }
})
