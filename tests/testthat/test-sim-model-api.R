test_that("both simulation entry points preserve data coordinates and fit each model", {
  for (model in c("ACL", "ALSCL")) {
    z <- fit_fixture(model)
    path <- tempfile("simulation-api-")
    dir.create(path)
    on.exit(unlink(path, recursive = TRUE), add = TRUE)
    f <- z$input
    sim.data <- list(SN_at_len = t(as.matrix(f$data.CatL[-1])),
      years = z$result$year, nyear = length(z$result$year), nage = f$nage,
      ages = z$result$age, growth_step = 1, len_mid = z$result$len_mid,
      len_border = z$result$len_border, weight = as.matrix(f$data.wgt[-1]),
      mat = as.matrix(f$data.mat[-1]), q_surv_L50 = f$sel_L50, q_surv_L95 = f$sel_L95)
    for (i in 1:2) save(sim.data, file = file.path(path, paste0("sim_rep", i)))
    args <- list(iter_range = 1:2, sim_data_path = path, output_dir = path,
      parameters = z$parameters, map = z$map, M = f$M)
    a <- do.call(sim_model, c(args, list(model = tolower(model))))
    b <- do.call(if (model == "ACL") sim_acl else sim_alscl, c(args, list(ncores = 2)))
    expect_length(unique(vapply(b, function(fit) fit$start_diagnostics$pid, integer(1))), 2)
    for (i in 1:2) {
      expect_null(a[[i]]$error)
      expect_null(b[[i]]$error)
      expect_equal(a[[i]]$opt$objective, z$result$opt$objective, tolerance = 1e-8)
      expect_equal(a[[i]]$opt$objective, b[[i]]$opt$objective, tolerance = 1e-8)
      expect_identical(a[[i]]$model_type, model)
      expect_equal(a[[i]]$year, sim.data$years)
    }
    failed_args <- args
    failed_args$map <- list(unknown = factor(NA))
    failed <- do.call(sim_model, c(failed_args, list(model = tolower(model), ncores = 2)))
    e <- new.env(parent = emptyenv())
    load(file.path(path, "result_rep_1"), envir = e)
    expect_match(e$result$error, "Unknown map parameter")
    expect_null(e$result$opt)
    expect_identical(e$result, failed[[1]])
  }
})

test_that("simulation replicate IDs reject collisions before writing files", {
  for (ids in list(numeric(), c(1, 1), 1.5, -1, NA_real_, Inf, "1"))
    expect_error(sim_model(ids), "distinct positive integer")
})
