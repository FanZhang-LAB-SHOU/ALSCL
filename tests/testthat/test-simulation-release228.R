test_that("full simulators validate process inputs before drawing or saving", {
  for (species in c("flatfish", "tuna")) {
    p <- initialize_params(species = species, nyear = 4, burn_in = 2)
    bio <- sim_cal(p)
    folder <- tempfile("simulation-process-inputs-")
    on.exit(unlink(folder, recursive = TRUE), add = TRUE)
    set.seed(228)
    before <- .Random.seed
    invalid <- list(init_Z = -1, std_logR = -0.3, std_logN0 = -0.2,
      std_SN = -0.1, F_sd = -0.2, M = -1, F_mean = -0.1,
      alpha = -400, beta = 0, R_init = -1, F_ar = 1, R_ar = -1)
    for (name in names(invalid)) {
      bad <- p; bad[name] <- invalid[name]
      expect_error(sim_data(bio, bad, iter_range = 1, output_dir = folder), name)
      expect_false(dir.exists(folder))
      expect_identical(.Random.seed, before)
    }
    for (name in names(invalid)) {
      for (value in list(NA_real_, Inf, c(0.1, 0.2), "0.2")) {
        bad <- p; bad[name] <- list(value)
        expect_error(sim_data(bio, bad, iter_range = 1, output_dir = folder), name)
      }
    }
    dir.create(folder)
    marker <- file.path(folder, "sim_rep1")
    writeLines("existing simulation", marker)
    original <- tools::md5sum(marker)
    bad <- p; bad$F_sd <- -0.2
    expect_error(sim_data(bio, bad, iter_range = 1, output_dir = folder), "F_sd")
    expect_identical(tools::md5sum(marker), original)
  }
})

test_that("valid zero process scales and negative stationary AR coefficients remain supported", {
  folder <- tempfile("simulation-process-boundaries-")
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  for (species in c("flatfish", "tuna")) {
    p <- initialize_params(species = species, nyear = 4, burn_in = 2,
      M = 0, F_mean = 0, init_Z = 0, std_logR = 0, std_logN0 = 0,
      std_SN = 0, F_sd = 0, F_ar = -0.5, R_ar = -0.2)
    bio <- sim_cal(p)
    expect_silent(ALSCL:::.acl_simulation_process(p, bio$model_type))
    capture.output(sm <- sim_data(bio, p, iter_range = 1, output_dir = folder))
    expect_true(all(is.finite(sm$N_at_age)))
    expect_true(all(sm$CN == 0))
    expect_true(all(sm$CB == 0))
    # Zero recruitment is a valid extinction scenario when beta stays positive.
    p$R_init <- 0; p$alpha <- 0
    capture.output(empty <- sim_data(bio, p, iter_range = 1, output_dir = folder))
    expect_true(all(empty$N_at_age == 0))
    expect_true(all(empty$SSB == 0))
    expect_true(all(is.finite(empty$SN_at_len)))
    # Legacy optional fields still use the engine's documented defaults.
    p[c("R_init", "F_mean", "F_sd", "F_ar", "R_ar")] <- NULL
    expect_silent(ALSCL:::.acl_simulation_process(p, bio$model_type))
  }
})
