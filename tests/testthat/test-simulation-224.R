test_that("quick simulations realize the requested arithmetic mean F including zero", {
  for (n in c(2L, 3L, 20L)) {
    for (mean_F in c(0, 0.01, 0.3)) {
      sm <- simulate_example_data(years = 2000 + seq_len(n) - 1L,
        mean_F = mean_F, seed = 224)
      expect_equal(mean(sm$true_params$F_trend), mean_F, tolerance = 1e-14)
      expect_true(all(is.finite(sm$true_params$F_trend)))
      expect_true(all(sm$true_params$F_trend >= 0))
      if (mean_F == 0) expect_identical(sm$true_params$F_trend, rep(0, n))
    }
  }
  for (bad in list(2000 + (0:7) / 4, c(2000, 2002, 2003), c(2000, 2000), "2000")) {
    expect_error(simulate_example_data(years = bad), "consecutive annual")
  }
  for (bad in list(-0.1, NA_real_, Inf, numeric(), c(0.1, 0.2), "0.3")) {
    expect_error(simulate_example_data(mean_F = bad), "mean_F")
  }
})

test_that("annual and quarterly simulators retain calendar years and one-period matrices", {
  folder <- tempfile("simulation-timing-")
  dir.create(folder)
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  for (species in c("flatfish", "tuna")) {
    step <- if (species == "tuna") 0.25 else 1
    p <- initialize_params(species = species, nyear = 2, burn_in = 2 - step,
      first.year = 1985.25)
    sm <- sim_data(sim_cal(p), p, iter_range = 1, output_dir = folder)
    expect_equal(sm$years, 1985.25)
    expect_identical(sm$years, p$observation_years)
    expect_equal(sm$growth_step, step)
    expect_equal(sm$first.year, 1985.25)
    expect_equal(sm$nyear, 1L)
    for (name in c("SN_at_len", "N_at_len", "N_at_age", "B_at_len", "SB_at_len",
                   "CN_at_len", "CN_at_age", "CB_at_len", "RVN_at_len", "RVB_at_len",
                   if (species == "tuna") c("F_at_len", "M_at_len") else c("F_at_age", "M_at_age"))) {
      expect_true(is.matrix(sm[[name]]), info = name)
      expect_equal(nrow(sm[[name]]), 1L, info = name)
    }
    expect_equal(dim(sm$weight), c(sm$nlen, 1L))
    expect_equal(dim(sm$mat), c(sm$nlen, 1L))
    e <- new.env(parent = emptyenv())
    load(file.path(folder, "sim_rep1"), envir = e)
    expect_equal(e$sim.data$years, sm$years)
    expect_equal(e$sim.data$SN_at_len, sm$SN_at_len)

    p <- initialize_params(species = species, nyear = 4, burn_in = 2,
      first.year = 1985.25)
    sm <- sim_data(sim_cal(p), p, iter_range = 1, output_dir = folder)
    expect_equal(sm$years, 1985.25 + (seq_len(sm$nyear) - 1L) * step)
    expect_equal(sm$years, p$observation_years)
    expect_equal(length(sm$years), nrow(sm$SN_at_len))
  }
})

test_that("simulation timing rejects fractional subscripts and invalid seeds", {
  expect_error(initialize_params(nyear = 3, burn_in = 0.5), "multiple of growth_step")
  expect_error(initialize_params(species = "tuna", nyear = 3, burn_in = 0.1),
    "multiple of growth_step")
  expect_error(initialize_params(growth_step = 0.3), "divides one year")
  expect_error(initialize_params(first.year = Inf), "first.year")
  p <- initialize_params(species = "tuna", nyear = 3, burn_in = 1)
  b <- sim_cal(p)
  for (bad in list(NA_real_, Inf, -1, c(1, 2))) {
    changed <- p
    changed$burn_in <- bad
    expect_error(sim_data(b, changed, iter_range = 1), "burn_in")
  }
  changed <- p
  changed$burn_in <- 1.1
  expect_error(sim_data(b, changed, iter_range = 1), "multiple of growth_step")
  for (bad in list(Inf, NA_real_, 2^31, 0.5, numeric())) {
    expect_error(sim_data(b, p, iter_range = bad), "integer seeds")
  }
  for (bad in list(NA_real_, c(1, 2), 5)) {
    expect_error(sim_data(b, p, iter_range = 1:2, return_iter = bad), "return_iter")
  }
})

test_that("simulation time metadata has a defined legacy fallback and is validated", {
  time <- ALSCL:::.acl_simulation_years
  sm <- list(nyear = 4L)
  expect_equal(time(sm, 0.25), 2000 + (0:3) / 4)
  sm$first.year <- 1990.5
  expect_equal(time(sm, 0.25), 1990.5 + (0:3) / 4)
  sm$years <- 1980 + (0:3) / 4
  expect_equal(time(sm, 0.25), sm$years)
  for (bad in list(1:3, c(1980, NA, 1980.5, 1980.75), 1980:1983)) {
    sm$years <- bad
    expect_error(time(sm, 0.25), "years must match")
  }
})

test_that("global-script batch arguments work on actual socket workers", {
  x <- fit_fixture("ACL")
  f <- x$input
  m <- x$result
  folder <- tempfile("simulation-global-script-")
  dir.create(folder)
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  sim.data <- list(SN_at_len = t(as.matrix(f$data.CatL[-1])),
    nyear = length(m$year), nage = length(m$age), ages = m$age,
    growth_step = 1, first.year = 1985, years = 1985:1989,
    len_mid = m$len_mid, len_border = m$len_border,
    weight = as.matrix(f$data.wgt[-1]), mat = as.matrix(f$data.mat[-1]),
    q_surv_L50 = f$sel_L50, q_surv_L95 = f$sel_L95)
  for (i in 1:2) save(sim.data, file = file.path(folder, paste0("sim_rep", i)))
  setup <- file.path(folder, "setup.rds")
  saveRDS(list(paths = .libPaths(), folder = folder, parameters = x$parameters,
    map = x$map, M = f$M, cache = getOption("ALSCL.tmb.cache")), setup)
  script <- file.path(folder, "batch.R")
  writeLines(c(
    "cfg <- readRDS(commandArgs(TRUE)[1])",
    ".libPaths(cfg$paths)",
    "library(ALSCL)",
    "options(ALSCL.tmb.cache = cfg$cache, ALSCL.sd_cores = 1L)",
    "inpath <- cfg$folder; outpath <- file.path(cfg$folder, 'fits')",
    "p <- cfg$parameters; lower <- list(mean_log_R = 0); upper <- list(mean_log_R = 20)",
    "mapping <- cfg$map; mortality <- cfg$M; passes <- 1L",
    "control <- list(iter.max = 1000L, eval.max = 1500L)",
    "structure <- 'group_year'; polish <- TRUE; seeds <- 1:2",
    "sequential <- sim_acl(seeds, inpath, outpath, parameters = p,",
    "  parameters.L = lower, parameters.U = upper, map = mapping, M = mortality,",
    "  ncores = 1L, train_times = passes, control = control, F_structure = structure, polish = polish)",
    "workers <- 2L",
    "concurrent <- sim_acl(seeds, inpath, outpath, parameters = p,",
    "  parameters.L = lower, parameters.U = upper, map = mapping, M = mortality,",
    "  ncores = workers, train_times = passes, control = control, F_structure = structure, polish = polish)",
    "compact <- function(z) list(error = z$error, objective = z$opt$objective,",
    "  parameters = z$opt$par, SSB = z$report$SSB, years = z$year, pid = z$start_diagnostics$pid)",
    "saveRDS(list(sequential = lapply(sequential, compact),",
    "  concurrent = lapply(concurrent, compact), parent_pid = Sys.getpid()),",
    "  file.path(cfg$folder, 'results.rds'))"
  ), script)
  log <- file.path(folder, "batch.log")
  status <- system2(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", shQuote(script), shQuote(setup)), stdout = log, stderr = log)
  expect_equal(status, 0L, info = paste(readLines(log, warn = FALSE), collapse = "\n"))
  if (status != 0L || !file.exists(file.path(folder, "results.rds"))) return(invisible(NULL))
  results <- readRDS(file.path(folder, "results.rds"))
  for (i in 1:2) {
    serial <- results$sequential[[i]]
    parallel <- results$concurrent[[i]]
    expect_null(serial$error)
    expect_null(parallel$error)
    expect_equal(parallel$objective, serial$objective, tolerance = 1e-10)
    expect_equal(parallel$parameters, serial$parameters, tolerance = 1e-10)
    expect_equal(parallel$SSB, serial$SSB, tolerance = 1e-10)
    expect_equal(parallel$years, 1985:1989)
    expect_equal(serial$pid, results$parent_pid)
    expect_false(results$parent_pid %in% parallel$pid)
  }
  expect_length(unique(unlist(lapply(results$concurrent, `[[`, "pid"))), 2L)
})
