# One small replicate file in the format written by sim_data(), built from the
# fitted fixture so that the fit of the replicate is known.
review_sim_folder <- function(z, ids = 1, M = z$input$M) {
  path <- tempfile("review-sim-"); dir.create(path)
  f <- z$input; fit <- z$result
  sim.data <- list(SN_at_len = t(as.matrix(f$data.CatL[-1])), years = fit$year,
    nyear = length(fit$year), nage = f$nage, ages = fit$age, growth_step = 1,
    len_mid = fit$len_mid, len_border = fit$len_border,
    weight = as.matrix(f$data.wgt[-1]), mat = as.matrix(f$data.mat[-1]),
    q_surv_L50 = f$sel_L50, q_surv_L95 = f$sel_L95)
  if (!is.null(M)) sim.data$M_at_age <- matrix(M, length(fit$year), f$nage)
  for (id in ids) save(sim.data, file = file.path(path, paste0("sim_rep", id)))
  path
}
review_read_result <- function(path, id) {
  e <- new.env(parent = emptyenv())
  load(file.path(path, paste0("result_rep_", id)), envir = e)
  e$result
}

test_that("simulation fits use the recorded natural mortality and omit the TMB object (F07, GI1, F28)", {
  skip_on_cran()
  withr::local_options(list(ALSCL.sd_cores = 1L))
  z <- fit_fixture("ACL")
  path <- review_sim_folder(z)
  on.exit(unlink(path, recursive = TRUE), add = TRUE)
  expect_null(formals(sim_model)$M)
  expect_null(formals(sim_acl)$M)
  fits <- sim_acl(1, path, path, parameters = z$parameters, map = z$map)
  fit <- fits[[1]]
  expect_null(fit$error)
  expect_s3_class(fit, "alscl_fit")
  # No TMB object in memory or in the saved file; the recipe still gives a refit.
  expect_false("obj" %in% names(fit))
  saved <- review_read_result(path, 1)
  expect_false("obj" %in% names(saved))
  expect_identical(saved, fit)
  expect_equal(fit$opt$objective, z$result$opt$objective, tolerance = 1e-8)
  expect_identical(fit$est_std, z$result$est_std)
  # The recorded natural mortality rate was used and is reported.
  expect_identical(fit$simulation_M,
    list(used = z$input$M, recorded = z$input$M, source = "simulation file"))
  expect_identical(fit$recipe$args$M, z$input$M)
  refit <- refit_model(fit, silent = TRUE)
  expect_false(is.null(refit$obj))
  expect_equal(refit$opt$objective, fit$opt$objective, tolerance = 1e-8)

  # The same value supplied as M is accepted and gives the same fit.
  explicit <- sim_acl(1, path, path, parameters = z$parameters, map = z$map, M = z$input$M)[[1]]
  expect_identical(explicit$opt$par, fit$opt$par)
  expect_identical(explicit$simulation_M$source, "argument M")
})

test_that("a supplied M that differs from the recorded rate stops before any fit (F28)", {
  z <- fit_fixture("ACL")
  path <- review_sim_folder(z, ids = 1:2)
  out <- file.path(path, "fits")
  on.exit(unlink(path, recursive = TRUE), add = TRUE)
  called <- FALSE
  seen <- numeric()
  local_mocked_bindings(.acl_compile = function(...) { called <<- TRUE; NULL },
    run_acl = function(..., M) { seen <<- c(seen, M); stop("fit not needed") },
    run_alscl = function(..., M) { seen <<- c(seen, M); stop("fit not needed") },
    .package = "ALSCL")
  for (entry in list(sim_model, sim_acl, sim_alscl)) {
    expect_error(entry(1:2, path, out, M = z$input$M + .1),
      "differs from the natural mortality rate 0\\.2 recorded in sim_rep1.*allow_M_mismatch = TRUE")
    expect_error(entry(1:2, path, out, M = -1), "M must be finite")
    expect_error(entry(1:2, path, out, allow_M_mismatch = NA), "allow_M_mismatch must be TRUE or FALSE")
  }
  expect_false(called)
  expect_false(dir.exists(out))
  # A deliberate mismatch is fitted with the supplied rate and recorded.
  mismatch <- sim_model(1:2, path, out, M = z$input$M + .1, allow_M_mismatch = TRUE)
  expect_equal(seen, rep(z$input$M + .1, 2))
  expect_identical(mismatch[[1]]$simulation_M,
    list(used = z$input$M + .1, recorded = z$input$M, source = "argument M"))
  seen <- numeric()
  recorded <- sim_alscl(2, path, out)
  expect_equal(seen, z$input$M)
  expect_identical(recorded[[1]]$simulation_M$source, "simulation file")

  # Files written before natural mortality was recorded need M.
  legacy <- review_sim_folder(z, M = NULL)
  on.exit(unlink(legacy, recursive = TRUE), add = TRUE)
  expect_error(sim_model(1, legacy, out), "sim_rep1 does not record a natural mortality rate. Supply M")
  seen <- numeric()
  old <- sim_model(1, legacy, out, M = .25)
  expect_equal(seen, .25)
  expect_identical(old[[1]]$simulation_M, list(used = .25, recorded = NA_real_, source = "argument M"))
})

test_that("the natural mortality rate written by sim_data() is the one fitted (F28)", {
  directory <- tempfile("review-sim-M-")
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  p <- initialize_params(nyear = 3, burn_in = 1, nage = 4, M = 0.35)
  capture.output(sim.data <- sim_data(sim_cal(p), p, iter_range = 0, output_dir = directory))
  expect_identical(ALSCL:::.acl_simulation_recorded_M(sim.data, "0"), 0.35)
  expect_identical(ALSCL:::.acl_simulation_M(sim.data, NULL, FALSE, "0")$used, 0.35)
  varying <- sim.data; varying$M_at_age[1, 1] <- 0.5
  expect_error(ALSCL:::.acl_simulation_M(varying, NULL, FALSE, "0"), "varies by time step")
  expect_identical(ALSCL:::.acl_simulation_M(varying, 0.3, TRUE, "0")$used, 0.3)
  seen <- NULL
  local_mocked_bindings(.acl_compile = function(...) NULL,
    run_acl = function(..., M) { seen <<- M; stop("fit not needed") }, .package = "ALSCL")
  result <- sim_acl(0, directory, directory)[[1]]
  expect_identical(seen, 0.35)
  expect_identical(result$simulation_M$used, 0.35)
})

test_that("replicate file names use the integer form of the ID (F83)", {
  id <- ALSCL:::.acl_replicate_id
  expect_identical(id(1e5), "100000")
  expect_identical(id(100000L), "100000")
  expect_identical(id(c(0, 7, 2e5)), c("0", "7", "200000"))
  withr::with_options(list(scipen = 100), expect_identical(id(1e5), "100000"))
  withr::with_options(list(scipen = -9), expect_identical(id(123456), "123456"))
  z <- fit_fixture("ACL")
  path <- review_sim_folder(z, ids = "100000")
  on.exit(unlink(path, recursive = TRUE), add = TRUE)
  local_mocked_bindings(.acl_compile = function(...) NULL,
    run_acl = function(...) stop("fit not needed"), .package = "ALSCL")
  for (scipen in c(0, 100)) withr::with_options(list(scipen = scipen), {
    result <- sim_acl(1e5, path, path)
    expect_identical(names(result), "result_rep_100000")
    expect_match(result[[1]]$error, "fit not needed")  # the file was found and read
    expect_true(file.exists(file.path(path, "result_rep_100000")))
    expect_false(file.exists(file.path(path, "result_rep_1e+05")))
  })
})

test_that("failure records of batch fits have class alscl_fit_error and keep their fields (GS9)", {
  z <- fit_fixture("ACL")
  path <- review_sim_folder(z)
  on.exit(unlink(path, recursive = TRUE), add = TRUE)
  failed <- sim_acl(1, path, path, parameters = z$parameters,
                    map = list(no_such_parameter = factor(NA)))[[1]]
  expect_s3_class(failed, "alscl_fit_error")
  expect_true(is.list(failed))
  expect_identical(failed$converge, "FAILED")
  expect_match(failed$error, "Unknown map parameter")
  expect_identical(failed$iter, 1)
  expect_null(failed$opt)
  expect_identical(review_read_result(path, 1), failed)
  args <- c(z$input, list(parameters = z$parameters, map = z$map, silent = TRUE))
  scenarios <- fit_scenarios(args, list(broken = list(map = list(no_such_parameter = factor(NA)))))
  expect_s3_class(scenarios$fits$broken, "alscl_fit_error")
  expect_identical(scenarios$fits$broken$converge, "FAILED")
  expect_match(scenarios$status$error, "Unknown map parameter")
  expect_false(scenarios$status$numerical_ok)
  # Existing consumers keep working on the classed record.
  target <- list(year = z$result$year, SSB = rep(1, length(z$result$year)))
  summary <- summarize_simulations(list(one = failed), list(one = target), quantities = "SSB")
  expect_identical(summary$replicates$failure_reasons, "fit error")
})

test_that("sequential batches keep the session's standard-error cores and give identical results (F32)", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_not(ALSCL:::.acl_tmb_supported())
  z <- fit_fixture("ACL")
  path <- review_sim_folder(z)
  on.exit(unlink(path, recursive = TRUE), add = TRUE)
  args <- c(z$input, list(parameters = z$parameters, map = z$map, silent = TRUE))
  withr::local_options(list(ALSCL.sd_backend = "fork"))
  run <- function(cores) withr::with_options(list(ALSCL.sd_cores = cores), list(
    sim = sim_acl(1, path, path, parameters = z$parameters, map = z$map)[[1]],
    scenario = fit_scenarios(args, list(reference = list()))$fits$reference))
  one <- run(1L); two <- run(2L)
  for (kind in c("sim", "scenario")) {
    expect_identical(one[[kind]]$sd_info$method, "sequential", label = kind)
    expect_identical(two[[kind]]$sd_info$method, "forked processes", label = kind)
    expect_identical(two[[kind]]$sd_info$cores, 2L, label = kind)
    expect_identical(two[[kind]]$recipe$settings$ALSCL.sd_cores, 2L, label = kind)
    for (part in c("est_std", "vcov", "pdHess", "report", "gradient"))
      expect_identical(two[[kind]][[part]], one[[kind]][[part]], label = paste(kind, part))
    expect_identical(two[[kind]]$opt$par, one[[kind]]$opt$par, label = kind)
    expect_identical(two[[kind]]$opt$objective, one[[kind]]$opt$objective, label = kind)
  }
})
