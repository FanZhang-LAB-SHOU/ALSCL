test_that("steep and descending logistic curves remain valid probabilities", {
  expect_equal(mat_func(20, 20.1, c(20, 30, 50)), c(0.5, 1, 1), tolerance = 1e-12)
  expect_equal(mat_func(20, 19.9, c(-20, 10, 20, 50)), c(1, 1, 0.5, 0),
               tolerance = 1e-12)
  x <- seq(0, 100, length.out = 101)
  old_logit <- -15 * log(19) / 5 + log(19) / 5 * x
  expect_equal(mat_func(15, 20, x), exp(old_logit) / (1 + exp(old_logit)),
               tolerance = 1e-14)
  expect_error(mat_func(20, 20, 30), "distinct")
  expect_error(mat_func(NA_real_, 20, 30), "L50")
  expect_error(mat_func(20, Inf, 30), "L95")
  expect_error(mat_func(20, 25, c(30, NA_real_)), "finite numeric")
  expect_error(mat_func(20, 25, "30"), "finite numeric")
})

test_that("steep maturity curves generate finite annual and quarterly observations", {
  folder <- tempfile("steep-simulation-")
  dir.create(folder)
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  for (species in c("flatfish", "tuna")) {
    p <- initialize_params(species = species, nyear = 4, burn_in = 2,
      mat_L50 = 20, mat_L95 = 20.1)
    bio <- sim_cal(p)
    expect_true(all(is.finite(bio$mat)))
    expect_true(all(bio$mat >= 0 & bio$mat <= 1))
    sm <- sim_data(bio, p, iter_range = 4, output_dir = folder)
    expect_true(all(is.finite(sm$SN_at_len)))
    expect_true(all(is.finite(sm$SSB)))
    expect_true(all(sm$SN_at_len > 0))
  }
})

test_that("Baranov catches have a stable zero-mortality limit", {
  N <- c(100, 100, 100, 100)
  F <- c(0, 0, 1e-18, 0.3)
  Z <- c(0, 0.2, 1e-18, 0.5)
  got <- ALSCL:::.acl_baranov_catch(N, F, Z)
  expect_equal(got[1:2], c(0, 0))
  expect_equal(got[3] / (N[3] * F[3]), 1, tolerance = 1e-14)
  expect_equal(got[4], N[4] * (1 - exp(-Z[4])) * F[4] / Z[4],
               tolerance = 1e-14)
  folder <- tempfile("zero-mortality-simulation-")
  dir.create(folder)
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  for (species in c("flatfish", "krill", "tuna")) {
    p <- initialize_params(species = species, nyear = 4, burn_in = 2,
                           M = 0, F_mean = 0)
    sm <- sim_data(sim_cal(p), p, iter_range = 4, output_dir = folder)
    for (name in c("CN", "CB", "CN_at_age", "CN_at_len", "CB_at_len"))
      expect_true(all(is.finite(sm[[name]]) & sm[[name]] == 0), info = name)
    expect_true(all(is.finite(sm$N_at_age)))
    expect_true(all(is.finite(sm$SSB)))
    expect_true(all(is.finite(sm$SN_at_len)))
  }
})

test_that("invalid simulation biology cannot silently produce saved results", {
  folder <- tempfile("invalid-simulation-")
  dir.create(folder)
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  p <- initialize_params(nyear = 4, burn_in = 2)
  b <- sim_cal(p)
  for (name in c("mat", "q_surv", "W_at_len", "sel", "pla")) {
    bad <- b
    bad[[name]][1] <- NaN
    expect_error(sim_data(bad, p, iter_range = 4, output_dir = folder), name)
  }
  p$F_mean <- -0.1
  expect_error(sim_data(b, p, iter_range = 4, output_dir = folder), "F_mean")
  p$F_mean <- 0
  p$M <- -0.1
  expect_error(sim_data(b, p, iter_range = 4, output_dir = folder), "M")
  expect_false(file.exists(file.path(folder, "sim_rep4")))
  # Catch finite inputs whose numerical scale nevertheless overflows dynamics.
  p <- initialize_params(nyear = 4, burn_in = 2, std_SN = 1000)
  expect_error(sim_data(sim_cal(p), p, iter_range = 4, output_dir = folder),
               "replicate 4.*nonfinite.*no file was saved")
  expect_false(file.exists(file.path(folder, "sim_rep4")))
})

test_that("actual multistart and retrospective workers use the loaded installation", {
  f <- fit_fixture("ACL")
  folder <- tempfile("socket-library-regression-")
  dir.create(folder)
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  custom <- file.path(folder, "library")
  dir.create(custom)
  installed <- getNamespaceInfo(asNamespace("ALSCL"), "path")
  if (file.exists(file.path(installed, "Meta", "package.rds"))) {
    expect_true(file.copy(installed, custom, recursive = TRUE))
  } else {
    # test_local() loads a source checkout, which cannot be copied as an
    # installed library. Still exercise the isolated-installation regression.
    install_log <- file.path(folder, "install.log")
    status <- system2(file.path(R.home("bin"), "R"),
      c("CMD", "INSTALL", shQuote(paste0("--library=", custom)), shQuote(installed)),
      stdout = install_log, stderr = install_log)
    expect_equal(status, 0L, info = paste(readLines(install_log, warn = FALSE), collapse = "\n"))
    if (status != 0L) return(invisible(NULL))
  }
  config <- file.path(folder, "config.rds")
  saveRDS(list(paths = .libPaths(), custom = custom, folder = folder,
    cache = getOption("ALSCL.tmb.cache"),
    args = c(f$input, list(parameters = f$parameters, map = f$map, silent = TRUE))), config)
  script <- file.path(folder, "workers.R")
  writeLines(c(
    "cfg <- readRDS(commandArgs(TRUE)[1])",
    ".libPaths(c(cfg$custom, cfg$paths))",
    "library(ALSCL)",
    "options(ALSCL.tmb.cache = cfg$cache, ALSCL.sd_cores = 1L)",
    # Source-file environments can refer to their package namespace. Inject
    # retained references explicitly so ordinary installs also exercise the
    # R_KEEP_PKG_SOURCE path used by package-check builds.
    "retain_source <- function(name) {",
    "  ns <- asNamespace('ALSCL')",
    "  lines <- deparse(utils::removeSource(get(name, ns)))",
    "  source <- srcfilecopy(paste0(name, '.R'), lines)",
    "  source$namespace <- ns",
    "  fun <- eval(parse(text=lines, srcfile=source, keep.source=TRUE), envir=ns)",
    "  stopifnot(!is.null(attr(fun, 'srcref')))",
    "  unlockBinding(name, ns); assign(name, fun, ns); lockBinding(name, ns)",
    "}",
    "for (name in c('.acl_initialize_workers', '.acl_delta_socket', '.acl_delta_one')) retain_source(name)",
    "expected <- normalizePath(file.path(cfg$custom, 'ALSCL'), winslash='/')",
    "stopifnot(identical(normalizePath(getNamespaceInfo(asNamespace('ALSCL'),'path'), winslash='/'), expected))",
    "probes <- list()",
    "trace('clusterCall', where=asNamespace('parallel'), print=FALSE, exit=quote({",
    "  if (is.function(fun) && any(grepl('.libPaths', deparse(body(fun)), fixed=TRUE))) {",
    "    probe <- function() c(path=if ('ALSCL' %in% loadedNamespaces()) normalizePath(getNamespaceInfo(asNamespace('ALSCL'),'path'), winslash='/') else NA_character_, pid=Sys.getpid())",
    "    environment(probe) <- baseenv()",
    "    .GlobalEnv$probes <- c(.GlobalEnv$probes, list(parallel::clusterCall(cl, probe)))",
    "  }",
    "}))",
    "serial <- run_acl(cfg$args, nstarts=2, ncores=1)",
    "fit <- run_acl(cfg$args, nstarts=2, ncores=2)",
    "serial_retro <- retro_acl(cfg$args, nyear=2, ncores=1)",
    "retro <- retro_acl(cfg$args, nyear=2, ncores=2)",
    "options(ALSCL.sd_socket_min_seconds=0)",
    "socket_sd <- ALSCL:::.acl_sdreport(fit$obj, fit$opt$par, ncores=2, check_version=FALSE, fallback=FALSE, backend='socket')",
    "reference_sd <- TMB::sdreport(fit$obj, par.fixed=fit$opt$par, getReportCovariance=FALSE)",
    "untrace('clusterCall', where=asNamespace('parallel'))",
    "saveRDS(list(probes=probes, expected=expected,",
    "  fit=list(objective=fit$opt$objective, serial_objective=serial$opt$objective,",
    "    par=fit$opt$par, serial_par=serial$opt$par, workers=fit$workers),",
    "  retro=retro$results, serial_retro=serial_retro$results,",
    "  retro_errors=retro$fit_diagnostics$error, sd=summary(socket_sd), reference_sd=summary(reference_sd),",
    "  sd_info=attr(socket_sd,'acl_sd_info')), file.path(cfg$folder,'results.rds'))"
  ), script)
  log <- file.path(folder, "workers.log")
  status <- system2(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", shQuote(script), shQuote(config)), stdout = log, stderr = log)
  expect_equal(status, 0L, info = paste(readLines(log, warn = FALSE), collapse = "\n"))
  result_file <- file.path(folder, "results.rds")
  if (status != 0L || !file.exists(result_file)) return(invisible(NULL))
  result <- readRDS(result_file)
  expect_length(result$probes, 3L)
  for (probe in result$probes[1:2]) {
    expect_length(probe, 2L)
    expect_identical(unname(vapply(probe, `[[`, character(1), "path")),
                     rep(result$expected, 2L))
    expect_length(unique(vapply(probe, `[[`, character(1), "pid")), 2L)
  }
  expect_equal(result$fit$workers, 2L)
  expect_equal(result$fit$objective, result$fit$serial_objective, tolerance = 1e-10)
  expect_equal(result$fit$par, result$fit$serial_par, tolerance = 1e-10)
  expect_equal(result$retro, result$serial_retro, tolerance = 1e-10)
  expect_true(all(result$retro_errors == ""))
  # Delta-method workers need TMB/Matrix only. Source attributes must not load
  # an unintended ALSCL installation as a side effect of deserialization.
  expect_length(result$probes[[3L]], 2L)
  expect_true(all(is.na(vapply(result$probes[[3L]], `[[`, character(1), "path"))))
  expect_identical(result$sd_info$method, "socket workers (delta method)")
  expect_equal(result$sd_info$cores, 2L)
  expect_equal(result$sd, result$reference_sd, tolerance = 1e-10)
})
