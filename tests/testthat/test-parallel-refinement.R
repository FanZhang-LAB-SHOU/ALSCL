refinement_objective <- function() list(
  fn = function(x) sum((x - c(.3, -.2))^2) / 2,
  gr = function(x) x - c(.3, -.2))

test_that("refinement agrees with TMB random effects in both assessment models", {
  skip_on_os("windows")
  old <- options(ALSCL.sd_cores = 1L, ALSCL.sd_backend = "fork")
  on.exit(options(old), add = TRUE)
  local_mocked_bindings(.acl_tmb_supported = function(...) TRUE)
  for (model in c("ACL", "ALSCL")) {
    fixture <- fit_fixture(model)
    mapping <- fixture$map
    mapping["mean_log_F"] <- list(NULL)
    x <- c(fixture$input, list(parameters = fixture$parameters, map = mapping))
    setup <- .acl_preflight(x, tolower(model))$setup
    info <- .acl_compile(model)
    evaluate <- function(cores) {
      options(ALSCL.sd_cores = cores)
      obj <- TMB::MakeADFun(setup$data, setup$parameters, map = setup$map,
        random = setup$random, DLL = info$dll_name, silent = TRUE)
      p <- obj$par + c(.1, -.1)
      .acl_polish(obj, p, rep(-10, 2), rep(10, 2))
    }
    reference <- evaluate(1L)
    parallel <- evaluate(2L)
    expect_identical(parallel[names(parallel) != "hessian_calculations"],
      reference[names(reference) != "hessian_calculations"])
    expect_true(nrow(parallel$hessian_calculations) > 0L)
    expect_true(all(parallel$hessian_calculations$method == "forked processes"))
  }
})

test_that("parallel refinement retains the sequential numerical result", {
  skip_on_os("windows")
  old <- options(ALSCL.sd_cores = 1L, ALSCL.sd_backend = "fork")
  on.exit(options(old), add = TRUE)
  local_mocked_bindings(.acl_tmb_supported = function(...) TRUE)
  obj <- refinement_objective(); p <- c(x = 3.1, y = 1.3)
  reference <- .acl_polish(obj, p, c(-10, -10), c(10, 10))
  options(ALSCL.sd_cores = 4L)
  parallel <- .acl_polish(obj, p, c(-10, -10), c(10, 10))
  expect_identical(parallel[names(parallel) != "hessian_calculations"],
    reference[names(reference) != "hessian_calculations"])
  expect_true(nrow(parallel$hessian_calculations) > 0L)
  expect_true(all(reference$hessian_calculations$method == "sequential"))
  expect_true(all(parallel$hessian_calculations$method == "forked processes"))
  expect_true(all(parallel$hessian_calculations$cores == 2L))
})

test_that("refinement keeps unsafe backends and unchecked TMB versions sequential", {
  old <- options(ALSCL.sd_cores = 4L)
  on.exit(options(old), add = TRUE)
  obj <- refinement_objective(); p <- c(x = 3.1, y = 1.3)
  reference <- stats::optimHess(p, obj$fn, obj$gr)
  checked <- FALSE; backend <- "fork"
  local_mocked_bindings(.acl_tmb_supported = function(...) checked,
    .acl_sd_backend = function(...) backend,
    .acl_optimhess = function(...) stop("must not start parallel work"))
  answer <- .acl_refinement_hessian(obj, p)
  expect_identical(answer$value, reference)
  expect_identical(answer$method, "sequential")
  expect_match(answer$note, "not checked")
  checked <- TRUE; backend <- "socket"
  answer <- .acl_refinement_hessian(obj, p)
  expect_identical(answer$value, reference)
  expect_match(answer$note, "not selected")
  backend <- "fork"; options(ALSCL.sd_cores = 1L)
  expect_identical(.acl_refinement_hessian(obj, p)$value, reference)
  options(ALSCL.sd_cores = 4L)
  scalar <- list(fn = function(x) x^2, gr = function(x) 2 * x)
  expect_identical(.acl_refinement_hessian(scalar, c(x = 2))$method, "sequential")
})

test_that("failed parallel refinement falls back without losing the finishing step", {
  old <- options(ALSCL.sd_cores = 1L)
  on.exit(options(old), add = TRUE)
  obj <- refinement_objective(); p <- c(x = 3.1, y = 1.3)
  reference <- .acl_polish(obj, p, c(-10, -10), c(10, 10))
  options(ALSCL.sd_cores = 2L)
  local_mocked_bindings(.acl_tmb_supported = function(...) TRUE,
    .acl_sd_backend = function(...) "fork",
    .acl_optimhess = function(...) stop(.acl_parallel_error("unable to fork")))
  expect_warning(answer <- .acl_polish(obj, p, c(-10, -10), c(10, 10)),
    "Parallel refinement Hessian failed.*unable to fork.*sequentially")
  expect_identical(answer[names(answer) != "hessian_calculations"],
    reference[names(reference) != "hessian_calculations"])
  expect_true(all(answer$hessian_calculations$method == "sequential"))
  expect_true(all(answer$hessian_calculations$cores == 1L))
  expect_true(all(grepl("unable to fork", answer$hessian_calculations$note)))
})

test_that("disabled or already stationary refinement creates no Hessian tasks", {
  local_mocked_bindings(.acl_refinement_hessian = function(...) stop("unneeded Hessian"))
  obj <- refinement_objective()
  disabled <- .acl_polish(obj, c(x = 3.1, y = 1.3), c(-10, -10), c(10, 10), enabled = FALSE)
  stationary <- .acl_polish(obj, c(x = .3, y = -.2), c(-10, -10), c(10, 10))
  expect_identical(disabled$status, "disabled")
  expect_identical(stationary$status, "gradient_tolerance")
  expect_equal(nrow(disabled$hessian_calculations), 0L)
  expect_equal(nrow(stationary$hessian_calculations), 0L)
})
