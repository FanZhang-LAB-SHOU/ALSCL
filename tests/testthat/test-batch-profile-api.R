batch_recipe_fixture <- function(model = "ACL", profile = FALSE) {
  z <- fit_fixture(model)
  args <- c(z$input, list(parameters = z$parameters, map = z$map, silent = TRUE))
  if (profile) {
    args$map["log_Linf"] <- list(NULL)
    fit <- do.call(if (model == "ACL") run_acl else run_alscl, args)
  } else fit <- z$result
  # Explicit recipe also exercises portable fits without a live TMB objective.
  fit$recipe <- list(schema_version = 1L, model = tolower(model), args = args)
  list(args = args, fit = fit)
}

test_that("scenarios preserve settings and failures and use actual socket workers", {
  for (model in c("ACL", "ALSCL")) {
    z <- batch_recipe_fixture(model)
    scenarios <- list(reference = list(), common_F = list(F_structure = "year"),
      broken = list(map = list(no_parameter = factor(NA))))
    old <- options(ALSCL.sd_cores = 2L)
    on.exit(options(old), add = TRUE)
    sequential <- fit_scenarios(z$args, scenarios, model = tolower(model), ncores = 1)
    parallel <- fit_scenarios(z$args, scenarios, model = tolower(model), ncores = 2)
    expect_identical(getOption("ALSCL.sd_cores"), 2L)
    expect_identical(names(sequential$fits), names(scenarios))
    expect_identical(names(parallel$fits), names(scenarios))
    expect_length(unique(parallel$status$pid), 2L)
    expect_false(Sys.getpid() %in% parallel$status$pid)
    expect_true(all(sequential$status$pid == Sys.getpid()))
    expect_match(sequential$fits$broken$error, "Unknown map parameter")
    expect_false(sequential$status$numerical_ok[3])
    expect_equal(parallel$estimates, sequential$estimates, tolerance = 1e-8)
    for (nm in names(scenarios)[1:2]) {
      expect_null(sequential$fits[[nm]]$obj)
      expect_null(parallel$fits[[nm]]$obj)
      expect_equal(parallel$fits[[nm]]$opt$par, sequential$fits[[nm]]$opt$par, tolerance = 1e-8)
      expect_equal(parallel$fits[[nm]]$report$SSB, sequential$fits[[nm]]$report$SSB, tolerance = 1e-8)
      expect_identical(parallel$fits[[nm]]$workers, 1L)
      expect_equal(parallel$fits[[nm]]$sd_info$cores, 1L)
    }
    expect_equal(sequential$fits$reference$opt$objective, z$fit$opt$objective, tolerance = 1e-8)
    expect_true(all(c("SSB", "Rec", "F") %in% sequential$estimates$quantity))
    expect_true(all(sequential$estimates$summary[sequential$estimates$quantity == "F"] == "mean"))
  }
})

test_that("scenarios use the bundle's nstarts or one start, and default to ACL", {
  z <- batch_recipe_fixture()
  seen <- list()
  local_mocked_bindings(.acl_batch_apply = function(settings, model, ncores) {
    seen <<- c(seen, list(list(settings = settings, model = model)))
    lapply(settings, function(s) list(fit = list(converge = "FAILED", error = "mock"),
      elapsed = 0, pid = Sys.getpid(), warnings = character()))
  }, .package = "ALSCL")
  x <- z$args[setdiff(names(z$args), "nstarts")]
  x$ncores <- 3L
  default <- fit_scenarios(x, list(reference = list()))
  expect_identical(seen[[1]]$model, "acl")
  expect_identical(default$settings$reference$nstarts, 1L)
  expect_identical(default$settings$reference$ncores, 1L)
  x$nstarts <- 2L
  bundled <- fit_scenarios(x, list(reference = list(), more = list(nstarts = 4L)))
  expect_identical(bundled$settings$reference$nstarts, 2L)
  expect_identical(bundled$settings$more$nstarts, 4L)
  explicit <- fit_scenarios(x, list(reference = list()), nstarts = 3L, ncores = 2)
  expect_identical(explicit$settings$reference$nstarts, 3L)
  expect_identical(explicit$settings$reference$ncores, 1L)
})

test_that("scenario input checks retain named NULL and reject changed tables", {
  z <- batch_recipe_fixture()
  expect_error(fit_scenarios(z$args, list(list())), "unique, nonempty")
  expect_error(fit_scenarios(z$args, list(a = list(), a = list())), "unique, nonempty")
  expect_error(fit_scenarios(z$args, list(a = list(data.CatL = z$args$data.CatL))), "common data")
  expect_error(fit_scenarios(z$args, list(a = list(no_such_argument = 1))), "unknown")
  expect_error(fit_scenarios(z$args, list(a = list()), ncores = Inf), "integer")
  mapped <- z$args$map
  mapped["log_Linf"] <- list(NULL)
  result <- fit_scenarios(z$args, list(released = list(map = mapped)), model = "acl",
                          F_summary = "apical")
  expect_true("log_Linf" %in% names(result$settings$released$map))
  expect_null(result$settings$released$map$log_Linf)
  expect_true("log_Linf" %in% names(result$fits$released$opt$par))
  F <- result$fits$released$report$F
  expect_equal(result$estimates$estimate[result$estimates$quantity == "F"],
               as.numeric(apply(F, 2L, max)))
})

test_that("profiles fix the target, refit nuisance parameters and preserve parallel results", {
  for (model in c("ACL", "ALSCL")) {
    z <- batch_recipe_fixture(model, profile = TRUE)
    fit <- z$fit
    fit$obj <- NULL
    values <- c(58, 60, 62)
    a <- profile_model(fit, "log_Linf", values, ncores = 1)
    b <- profile_model(fit, "log_Linf", values, ncores = 2)
    expect_equal(a$grid$internal_value, log(values))
    expect_equal(a$grid$objective, b$grid$objective, tolerance = 1e-8)
    expect_length(unique(b$grid$pid), 2L)
    expect_false(Sys.getpid() %in% b$grid$pid)
    expect_equal(a$grid$delta_nll, a$grid$objective - as.numeric(fit$opt$objective))
    expect_identical(a$parameter, "log_Linf")
    expect_equal(a$settings[[1]]$parameters$mean_log_R, unname(fit$opt$par[["mean_log_R"]]))
    for (i in seq_along(values)) {
      expect_equal(a$fits[[i]]$report$Linf, values[i], tolerance = 1e-12)
      expect_false("log_Linf" %in% names(a$fits[[i]]$opt$par))
      direct <- do.call(if (model == "ACL") run_acl else run_alscl, a$settings[[i]])
      expect_equal(a$grid$objective[i], as.numeric(direct$opt$objective), tolerance = 1e-8)
      expect_null(b$fits[[i]]$obj)
    }
    internal <- profile_model(fit, "log_Linf", log(values[2]), scale = "internal")
    expect_equal(internal$grid$objective, a$grid$objective[2], tolerance = 1e-8)
    expect_error(profile_model(fit, "M", .2), "free scalar")
    expect_error(profile_model(fit, "log_vbk", .2), "free scalar")
    expect_error(profile_model(fit, "log_Linf", c(60, 60)), "distinct finite")
    expect_error(profile_model(fit, "log_Linf", -1), "strictly positive")
    expect_error(profile_model(fit, "log_Linf", 1e9), "optimizer bounds")
    expect_error(profile_model(list(), "log_Linf", 60), "recipe")
  }
  one <- batch_recipe_fixture()$fit
  expect_error(profile_model(one, "mean_log_R", 100), "other free scalar")
})

test_that("comparison timing ratio uses valid elapsed seconds only", {
  z <- batch_recipe_fixture()
  a <- b <- z$fit
  a$elapsed <- 2
  b$elapsed <- 5
  cmp <- compare_models(a, b, z$args$data.CatL)
  row <- cmp$summary[cmp$summary$Metric == "Run Time Ratio", ]
  expect_identical(row[[2]], "1.0 (ref)")
  expect_identical(row[[3]], "2.5")
  for (bad in list(NULL, NA_real_, 0, Inf, -1, c(1, 2))) {
    b$elapsed <- bad
    cmp <- compare_models(a, b, z$args$data.CatL)
    expect_true(is.na(cmp$summary[cmp$summary$Metric == "Run Time Ratio", 3]))
  }
})
