test_that("an unchanged failed pass preserves earlier success and all pass records", {
  i <- 0L
  local_mocked_bindings(nlminb = function(...) {
    i <<- i + 1L
    if (i == 3L) stop("restart failed")
    list(par = c(x = 1), objective = 2, convergence = if (i == 1L) 0L else 1L,
         message = if (i == 1L) "converged" else "false convergence (8)")
  }, .package = "stats")
  opt <- .acl_optimize(NULL, 1, -Inf, Inf, 3L, list())
  expect_equal(opt$convergence, 0L)
  expect_equal(opt$selected_pass, 1L)
  expect_length(opt$optimizer_history, 3)
  expect_match(opt$optimizer_history[[2]]$message, "false convergence")
  expect_match(opt$optimizer_history[[3]]$message, "restart failed")
})

test_that("refinement improves a quadratic and respects safety guards", {
  obj <- list(fn = function(x) sum((x - 2)^2), gr = function(x) 2*(x - 2))
  good <- .acl_polish(obj, c(x = 1), -10, 10)
  expect_equal(unname(good$par), 2, tolerance = 1e-8)
  expect_lt(good$final_max_gradient, good$initial_max_gradient)
  expect_lte(good$final_objective, good$initial_objective)
  expect_gt(good$steps, 0)
  disabled <- .acl_polish(obj, c(x = 1), -10, 10, FALSE)
  expect_identical(disabled$par, c(x = 1))
  expect_equal(disabled$status, "disabled")
  boundary <- .acl_polish(obj, c(x = 1), -10, 1)
  expect_equal(boundary$status, "parameter_boundary")
  expect_identical(boundary$par, c(x = 1))
  saddle <- .acl_polish(list(fn = function(x) -x^2, gr = function(x) -2*x), 1, -10, 10)
  expect_equal(saddle$status, "hessian_unusable")
  bad <- .acl_polish(list(fn = function(x) Inf, gr = function(x) NaN), 1, -10, 10)
  expect_equal(bad$status, "nonfinite_evaluation")
  # A misleading gradient must not allow a large objective increase.
  inconsistent <- .acl_polish(list(fn = function(x) -(x-2)^2,
    gr = function(x) 2*(x-2)), 1, -10, 10)
  expect_equal(inconsistent$steps, 0)
  expect_equal(inconsistent$par, 1)
})

test_that("natural-scale diagnostics detect boundaries beyond optimizer bounds", {
  p <- c(logit_log_F_a = 19.7, log_std_log_R = log(1e-6), log_vbk = -.5)
  fit <- list(opt = list(par = p), vcov = diag(3), convergence_code = 0L,
    max_abs_gradient = 1e-8, pdHess = TRUE, bound_hit = FALSE)
  d <- .acl_fit_diagnostics(fit)
  expect_true(d$natural_boundary)
  expect_false(d$numerical_ok)
  expect_true(all(d$natural_parameters$near_boundary))
  fit$opt$par <- c(logit_log_F_a = 0, log_std_log_R = log(.2), log_vbk = -.5)
  expect_true(.acl_fit_diagnostics(fit)$numerical_ok)
  fit$vcov[1,2] <- fit$vcov[2,1] <- .99
  expect_equal(nrow(.acl_fit_diagnostics(fit)$high_correlations), 1)
  expect_true(.acl_fit_diagnostics(fit)$numerical_ok)
})

test_that("shared F uses a one-dimensional normalized AR1 density in both templates", {
  for (model in c("ACL", "ALSCL")) {
    x <- cpp_fixture(model)
    p <- x$parameters
    p$dev_log_F <- array(c(.12, -.03, .2, -.1), c(1, x$data$Y))
    group <- if (model == "ACL") "logit_log_F_a" else "logit_log_F_l"
    sdname <- if (model == "ACL") "log_std_log_F" else "log_sigma_log_F"
    make <- function(p) TMB::MakeADFun(x$data, p, DLL = x$info$dll_name, silent = TRUE)
    obj <- make(p)
    y <- obj$report(obj$par)
    f <- y[[if (model == "ACL") "F" else "FL"]]
    expect_equal(apply(f, 2, function(v) diff(range(v))), rep(0, x$data$Y))
    # Group correlation is absent from likelihood; year correlation has exactly
    # the normalized 1D Gaussian contribution with marginal SD sigma.
    p2 <- p; p2[[group]] <- 0
    expect_equal(make(p2)$fn(), obj$fn(), tolerance = 1e-10)
    p2 <- p; p2$logit_log_F_y <- qlogis(.4)
    density <- function(rho) {
      v <- as.numeric(p$dev_log_F); sigma <- exp(p[[sdname]])
      -dnorm(v[1], 0, sigma, log = TRUE) -
        sum(dnorm(v[-1], rho*v[-length(v)], sigma*sqrt(1-rho^2), log = TRUE))
    }
    expect_equal(make(p2)$fn() - obj$fn(),
      density(.4) - density(plogis(p$logit_log_F_y)), tolerance = 1e-8)
  }
})

test_that("shared F fits, plots, direct calls and socket starts work for both models", {
  for (model in c("ACL", "ALSCL")) {
    f <- fit_fixture(model)
    args <- c(f$input, list(parameters = f$parameters, map = f$map, silent = TRUE,
      F_structure = "year"))
    fun <- if (model == "ACL") run_acl else run_alscl
    fit <- fun(args)
    legacy <- do.call(fun, args)
    expect_identical(fit$opt$par, legacy$opt$par)
    expect_identical(fit$report, legacy$report)
    expect_equal(dim(fit$report$dev_log_F), c(1, length(fit$year)))
    expect_false(any(grepl("logit_log_F_[al]", names(fit$opt$par))))
    expect_null(fit$report[[if (model == "ACL") "phi_log_F_a" else "phi_log_F_l"]])
    expect_true(isTRUE(fit$pdHess))
    expect_lt(fit$max_abs_gradient, 1e-3)
    expect_s3_class(plot_deviance(fit, type = "F"), "ggplot")
    expect_s3_class(plot_fishing_mortality(fit, se = TRUE), "ggplot")
    parallel <- fun(args, nstarts = 2, ncores = 2)
    serial <- fun(args, nstarts = 2, ncores = 1)
    expect_equal(parallel$opt$par, serial$opt$par, tolerance = 1e-8)
    expect_equal(parallel$report, serial$report, tolerance = 1e-8)
    expect_error(fun(args, polish = NA), "polish")
    expect_error(fun(args, F_structure = "bad"), "arg")
  }
})
