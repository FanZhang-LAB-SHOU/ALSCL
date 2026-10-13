test_that("structured bundles select the correct model and preserve explicit overrides", {
  for (model in c("acl", "alscl")) {
    x <- YTF_example
    legacy <- c(x[c("data.CatL", "data.wgt", "data.mat")], x$fit_args, x$fit_config[[model]])
    expect_identical(.acl_bundle_args(x, model), legacy)
    x$fit_args$control <- list(iter.max = 50, eval.max = 100)
    x$fit_config[[model]]$M <- .3
    x$fit_config[[model]]$control <- list(iter.max = 60)
    resolved <- .acl_bundle_args(x, model, list(M = .4, map = NULL, control = list(eval.max = 200)))
    expect_identical(resolved$M, .4)
    expect_true("map" %in% names(resolved))
    expect_null(resolved$map)
    expect_identical(resolved$control, list(eval.max = 200))
    expect_identical(resolved$parameters, x$fit_config[[model]]$parameters)
  }
})

test_that("bundles reject malformed or incomplete settings before fitting", {
  f <- fixture_frames()
  expect_error(.acl_bundle_args(unname(f), "acl"), "unique, non-empty names")
  expect_error(.acl_bundle_args(c(f, f[1]), "acl"), "unique, non-empty names")
  expect_error(.acl_bundle_args(c(f, list(ncore = 2)), "acl"), "unknown arguments: ncore")
  expect_error(run_acl(list()), "Missing required bundle arguments")
  expect_error(run_alscl(f[setdiff(names(f), "M")]), "Missing required bundle arguments: M")
  f$data.CatL <- list(a = 1)
  expect_error(run_acl(f), "data frame or matrix")
  x <- YTF_example
  x$fit_args$ncore <- 2
  expect_error(run_alscl(x), "x\\$fit_args contains unknown arguments: ncore")
  x <- YTF_example
  x$fit_config$acl <- NULL
  expect_error(run_acl(x), "must contain a 'acl' configuration")
  x$fit_config$alscl <- 1
  expect_error(run_alscl(x), "unique, non-empty names")
  x <- YTF_example
  x$fit_args <- NULL
  x["fit_args"] <- list(NULL)
  expect_error(run_acl(x), "x\\$fit_args must be a list")
})

test_that("call overrides reach the core and defaults follow the final ncores", {
  local_mocked_bindings(.acl_fit = function(model, prepared, parameters, parameters.L,
      parameters.U, map, train_times, ncores, silent, output, control, nstarts) {
    list(model = model, ncores = ncores, nstarts = nstarts, parameters = parameters,
         map = map, control = control, prepared = prepared)
  })
  for (fun in list(run_acl, run_alscl)) {
    f <- fixture_frames()
    f$ncores <- 3
    result <- fun(f, ncores = 2)
    expect_identical(result$ncores, 2)
    expect_identical(result$nstarts, 2)
    expect_identical(fun(f, ncores = 2, nstarts = 4)$nstarts, 4)
    f$nstarts <- 5
    expect_identical(fun(f, ncores = 2)$nstarts, 5)
    expect_null(fun(YTF_example, parameters = NULL)$parameters)
    expect_identical(fun(f, control = list(iter.max = 20))$control, list(iter.max = 20))
    # A positional data.wgt override still follows the original signature.
    w <- f$data.wgt; w[-1] <- 2
    expect_identical(fun(f, w)$prepared, do.call(.acl_prepare_data,
      c(f[setdiff(names(f), c("ncores", "nstarts", "data.wgt"))], list(data.wgt = w))))
  }
})

test_that("both bundle forms produce the same fitted results as the legacy interface", {
  old <- options(ALSCL.sd_cores = 1, ALSCL.framework = "CppAD")
  on.exit(options(old), add = TRUE)
  for (model in c("ACL", "ALSCL")) {
    baseline <- fit_fixture(model)
    fun <- if (model == "ACL") run_acl else run_alscl
    args <- c(baseline$input, list(parameters = baseline$parameters, map = baseline$map,
                                  silent = TRUE))
    x <- baseline$input[c("data.CatL", "data.wgt", "data.mat")]
    x$fit_args <- baseline$input[setdiff(names(baseline$input), names(x))]
    x$fit_config <- setNames(list(list(parameters = baseline$parameters,
                                       map = baseline$map)), tolower(model))
    # Unrelated simulation settings must not affect fitting.
    x$parameters <- list(not_a_fitting_parameter = 999)
    for (fit in list(fun(args), fun(x, silent = TRUE))) {
      for (field in c("est_std", "vcov", "pdHess", "report"))
        expect_identical(fit[[field]], baseline$result[[field]], info = paste(model, field))
      expect_identical(fit$opt$par, baseline$result$opt$par)
      expect_identical(fit$opt$objective, baseline$result$opt$objective)
    }
  }
})
