test_that("simulation starts are validated before compilation or result writes", {
  path <- tempfile("simulation-start-validation-")
  on.exit(unlink(path, recursive = TRUE), add = TRUE)
  invalid <- list(0, -1, 1.5, NA_real_, Inf, c(1, 2), "2", TRUE, NULL, 2^31)
  old <- options(ALSCL.sd_cores = 2L)
  on.exit(options(old), add = TRUE)
  for (entry in list(sim_model, sim_acl, sim_alscl)) {
    for (nstarts in invalid) {
      expect_error(entry(iter_range = 1, sim_data_path = path,
        output_dir = path, nstarts = nstarts), "nstarts must be an integer >= 1")
      expect_false(dir.exists(path))
      expect_identical(getOption("ALSCL.sd_cores"), 2L)
    }
  }
})

test_that("simulation multistart fits use one worker per replicate and preserve results", {
  old <- options(ALSCL.sd_cores = 1L)
  on.exit(options(old), add = TRUE)
  for (model in c("ACL", "ALSCL")) {
    z <- fit_fixture(model)
    path <- tempfile("simulation-multistart-")
    dir.create(path)
    on.exit(unlink(path, recursive = TRUE), add = TRUE)
    f <- z$input
    sim.data <- list(SN_at_len = t(as.matrix(f$data.CatL[-1])),
      years = z$result$year, nyear = length(z$result$year), nage = f$nage,
      ages = z$result$age, growth_step = 1, len_mid = z$result$len_mid,
      len_border = z$result$len_border, weight = as.matrix(f$data.wgt[-1]),
      mat = as.matrix(f$data.mat[-1]), q_surv_L50 = f$sel_L50,
      q_surv_L95 = f$sel_L95)
    for (i in 1:2) save(sim.data, file = file.path(path, paste0("sim_rep", i)))
    args <- list(iter_range = 1:2, sim_data_path = path, output_dir = path,
      parameters = z$parameters, map = z$map, M = f$M)
    set.seed(229)
    seed <- .Random.seed
    serial <- do.call(sim_model, c(args, list(model = tolower(model), nstarts = 3)))
    expect_identical(.Random.seed, seed)
    batch <- do.call(if (model == "ACL") sim_acl else sim_alscl,
      c(args, list(ncores = 2, nstarts = 3)))
    expect_length(unique(vapply(batch,
      function(fit) fit$start_diagnostics$pid[1], integer(1))), 2L)
    for (i in 1:2) {
      a <- serial[[i]]; b <- batch[[i]]
      expect_null(a$error)
      expect_null(b$error)
      for (fit in list(a, b)) {
        expect_identical(fit$nstarts, 3L)
        expect_identical(fit$workers, 1L)
        expect_identical(fit$recipe$args$nstarts, 3L)
        expect_identical(fit$recipe$args$ncores, 1L)
        expect_identical(fit$start_diagnostics$start_id, 1:3)
        expect_length(unique(fit$start_diagnostics$pid), 1L)
        expect_true(all(diff(fit$start_diagnostics$started_at) >= 0))
        expect_true(all(fit$start_diagnostics$started_at[-1] >=
          head(fit$start_diagnostics$finished_at, -1)))
        expect_false(identical(fit$starts[[1]]$initial, fit$starts[[2]]$initial))
        expect_true(all(is.finite(fit$start_diagnostics$objective)))
        expect_equal(fit$raw_opt$objective,
          min(fit$start_diagnostics$objective), tolerance = 1e-8)
      }
      expect_equal(a$opt$objective, b$opt$objective, tolerance = 1e-8)
      expect_equal(a$opt$par, b$opt$par, tolerance = 1e-8)
      expect_equal(a$report$SSB, b$report$SSB, tolerance = 1e-8)
      expect_equal(a$start_diagnostics$objective,
        b$start_diagnostics$objective, tolerance = 1e-8)
      saved <- new.env(parent = emptyenv())
      load(file.path(path, paste0("result_rep_", i)), envir = saved)
      expect_identical(saved$result$start_diagnostics, b$start_diagnostics)
      expect_identical(saved$result$nstarts, b$nstarts)
    }
    # The default remains one start and is independent of outer worker count.
    original <- do.call(if (model == "ACL") sim_acl else sim_alscl,
      c(args, list(ncores = 2)))
    for (fit in original) {
      expect_identical(fit$nstarts, 1L)
      expect_identical(fit$workers, 1L)
      expect_equal(fit$opt$objective, z$result$opt$objective, tolerance = 1e-8)
    }
  }
})
