# Operating-model fixes from the review: random-number handling (F29), file
# names and writing (F83, F85), zero autocorrelation (F82), time labels (F74),
# dome selectivity (F86) and messages (GD2).

test_that("sim_data leaves the caller's random numbers unchanged and records the seed", {
  params <- initialize_params(species = "flatfish", nyear = 30, burn_in = 20)
  bio <- sim_cal(params)
  out <- withr::local_tempdir()
  withr::local_seed(99)
  before <- .Random.seed; kind <- RNGkind()
  utils::capture.output(first <- sim_data(bio, params, output_dir = out, iter_range = 4:5))
  expect_identical(.Random.seed, before)
  expect_identical(RNGkind(), kind)
  expect_identical(first$provenance$seed, 5L)
  expect_identical(first$provenance$RNGkind, c("Mersenne-Twister", "Inversion", "Rejection"))
  expect_identical(first$provenance$ALSCL_version, as.character(utils::packageVersion("ALSCL")))
  # The same replicate ID gives the same data under another generator.
  withr::local_rng_version("3.5.0")
  utils::capture.output(second <- sim_data(bio, params, output_dir = out, iter_range = 5))
  expect_identical(second$SN_at_len, first$SN_at_len)
})

test_that("replicate files have integer names and are written only when every replicate is valid", {
  params <- initialize_params(species = "flatfish", nyear = 30, burn_in = 20)
  bio <- sim_cal(params)
  out <- withr::local_tempdir()
  withr::local_options(scipen = -10)
  utils::capture.output(sim_data(bio, params, output_dir = out, iter_range = c(4, 100000)))
  expect_setequal(list.files(out), c("sim_rep4", "sim_rep100000"))
  expect_identical(basename(ALSCL:::.acl_simulation_file(out, 1e5)), "sim_rep100000")
  stamp <- tools::md5sum(file.path(out, "sim_rep4"))
  bad <- params; bad$R_init <- Inf
  expect_error(utils::capture.output(sim_data(bio, bad, output_dir = out, iter_range = 4:6)),
               "files already in output_dir are unchanged")
  expect_setequal(list.files(out), c("sim_rep4", "sim_rep100000"))
  expect_identical(tools::md5sum(file.path(out, "sim_rep4")), stamp)
})

test_that("zero autocorrelation runs without warnings", {
  for (species in c("flatfish", "tuna")) {
    params <- initialize_params(species = species, nyear = 30, burn_in = 20, R_ar = 0, F_ar = 0)
    out <- withr::local_tempdir()
    expect_no_warning(utils::capture.output(sim <- sim_data(sim_cal(params), params, output_dir = out, iter_range = 4)))
    expect_true(all(is.finite(sim$SSB)))
  }
})

test_that("the full-run time labels end at the last observation period", {
  for (species in c("flatfish", "tuna")) {
    params <- initialize_params(species = species)
    burn_steps <- round(params$burn_in / params$growth_step)
    expect_equal(params$years[burn_steps + 1L], params$observation_years[1L])
    expect_equal(utils::tail(params$years, 1L), utils::tail(params$observation_years, 1L))
  }
})

test_that("a discontinuous dome selectivity gives a warning", {
  params <- initialize_params(species = "tuna")
  expect_no_warning(sim_cal(params))
  params$sel_L50_asc <- 60; params$sel_L95_asc <- 70; params$sel_L50_desc <- 65; params$sel_L95_desc <- 55
  expect_warning(sim_cal(params), "Dome selectivity is discontinuous")
})

test_that("simulate_example_data reports with messages and keeps the caller's random numbers", {
  withr::local_seed(5)
  before <- .Random.seed
  expect_message(sim <- simulate_example_data(years = 2000:2004, seed = 1), "Simulated data")
  expect_identical(.Random.seed, before)
  expect_silent(suppressMessages(again <- simulate_example_data(years = 2000:2004, seed = 1)))
  expect_identical(sim$data.CatL, again$data.CatL)
  # Without a seed the caller's stream is used, as before.
  suppressMessages(simulate_example_data(years = 2000:2004))
  expect_false(identical(.Random.seed, before))
})
