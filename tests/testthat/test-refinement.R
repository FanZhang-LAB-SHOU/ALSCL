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

test_that("near-identical failed restarts preserve an actual successful pass", {
  # These differences reproduce the two own-data ALSCL retrospective failures:
  # the second pass reported false convergence after a sub-nanounit NLL gain.
  cases <- list(
    list(objective = -224.5458052179776, change = -7.78e-10, delta = 3.27e-7),
    list(objective = -201.02331936590565, change = -2.91e-10, delta = 1.64e-8))
  for (case in cases) {
    i <- 0L
    first <- list(par = c(log_sigma_index = -2.2), objective = case$objective,
      convergence = 0L, message = "relative convergence (4)")
    second <- list(par = first$par + case$delta,
      objective = first$objective + case$change, convergence = 1L,
      message = "false convergence (8)")
    local_mocked_bindings(nlminb = function(...) {
      i <<- i + 1L
      if (i == 1L) first else second
    }, .package = "stats")
    opt <- .acl_optimize(NULL, first$par, -Inf, Inf, 2L, list())
    expect_identical(opt$par, first$par)
    expect_identical(opt$objective, first$objective)
    expect_identical(opt$convergence, 0L)
    expect_identical(opt$selected_pass, 1L)
    expect_identical(opt$optimizer_history, list(first, second))
  }
})

test_that("optimizer selection uses both parameter and objective agreement", {
  first <- list(par = c(x = 1, y = 10000), objective = -200,
                convergence = 0L, message = "relative convergence (4)")
  second <- first
  choose <- function(a, b) {
    i <- 0L
    local_mocked_bindings(nlminb = function(...) {
      i <<- i + 1L
      if (i == 1L) a else b
    }, .package = "stats")
    .acl_optimize(NULL, a$par, -Inf, Inf, 2L, list())
  }
  # A later, genuinely successful pass can win a numerical tie even when its
  # reported objective is slightly higher; its original code is never changed.
  failed <- first; failed$convergence <- 1L; failed$message <- "false convergence (8)"
  second$par["x"] <- 1 + 1e-7
  second$objective <- first$objective + 5e-9
  opt <- choose(failed, second)
  expect_identical(opt$convergence, 0L)
  expect_identical(opt$selected_pass, 2L)
  expect_identical(opt$optimizer_history, list(failed, second))

  # A material likelihood improvement remains selected even with a nonzero code.
  second <- failed; second$par["x"] <- 1 + 1e-9
  second$objective <- first$objective - 1e-5
  opt <- choose(first, second)
  expect_identical(opt$convergence, 1L)
  expect_identical(opt$selected_pass, 2L)
  expect_identical(opt$par, second$par)

  # Compare each coordinate on its own scale: a large unrelated coordinate
  # must not make a meaningful change in x count as the same solution.
  second$par["x"] <- 1 + 1e-4
  second$objective <- first$objective - 5e-10
  opt <- choose(first, second)
  expect_identical(opt$convergence, 1L)
  expect_identical(opt$selected_pass, 2L)
  expect_identical(opt$par, second$par)

  # Large coordinates use relative agreement, not an absolute-only cutoff.
  first$par <- c(x = 100)
  second <- first; second$par <- c(x = 100 + 5e-5)
  second$objective <- first$objective - 5e-10
  second$convergence <- 1L; second$message <- "false convergence (8)"
  opt <- choose(first, second)
  expect_identical(opt$convergence, 0L)
  expect_identical(opt$selected_pass, 1L)
  expect_identical(opt$par, first$par)

  # Different parameter identities are not equivalent merely because their
  # numeric positions are close.
  second$par <- c(z = 100 + 5e-5)
  opt <- choose(first, second)
  expect_identical(opt$selected_pass, 2L)
  expect_identical(opt$par, second$par)
})

test_that("passes with the same success status retain the lower objective", {
  for (code in c(0L, 1L)) for (delta in c(0, 1e-8)) {
    first <- list(par = c(x = 1), objective = -200, convergence = code,
                  message = if (code == 0L) "relative convergence (4)" else "false convergence (8)")
    for (change in c(-5e-10, 5e-10)) {
      second <- first; second$par <- first$par + delta
      second$objective <- first$objective + change
      i <- 0L
      local_mocked_bindings(nlminb = function(...) {
        i <<- i + 1L
        if (i == 1L) first else second
      }, .package = "stats")
      opt <- .acl_optimize(NULL, first$par, -Inf, Inf, 2L, list())
      expected <- if (change < 0) second else first
      expect_identical(opt$convergence, code)
      expect_identical(opt$selected_pass, if (change < 0) 2L else 1L)
      expect_identical(opt$objective, expected$objective)
      expect_identical(opt$par, expected$par)
      expect_identical(opt$optimizer_history, list(first, second))
    }
  }
})

test_that("nonfinite and errored passes remain recorded without replacing a finite fit", {
  for (bad_value in c(Inf, -Inf, NaN, NA_real_)) {
    i <- 0L
    first <- list(par = c(x = 1), objective = -200, convergence = 0L,
                  message = "relative convergence (4)")
    local_mocked_bindings(nlminb = function(...) {
      i <<- i + 1L
      if (i == 1L) return(first)
      if (i == 3L) stop("restart evaluation failed")
      list(par = c(x = 2), objective = bad_value, convergence = 1L,
           message = "nonfinite objective")
    }, .package = "stats")
    opt <- .acl_optimize(NULL, first$par, -Inf, Inf, 3L, list())
    expect_identical(opt$selected_pass, 1L)
    expect_identical(opt$convergence, 0L)
    expect_identical(opt$par, first$par)
    expect_identical(opt$optimizer_history[[2]]$objective, bad_value)
    expect_identical(opt$optimizer_history[[3]]$par, first$par)
    expect_match(opt$optimizer_history[[3]]$message, "restart evaluation failed")
  }
  i <- 0L
  local_mocked_bindings(nlminb = function(...) {
    i <<- i + 1L
    stop(paste("failed pass", i))
  }, .package = "stats")
  opt <- .acl_optimize(NULL, c(x = 1), -Inf, Inf, 2L, list())
  expect_true(is.na(opt$selected_pass))
  expect_identical(opt$convergence, 1L)
  expect_identical(opt$objective, Inf)
  expect_length(opt$optimizer_history, 2L)
  expect_match(opt$optimizer_history[[1]]$message, "failed pass 1")
  expect_match(opt$optimizer_history[[2]]$message, "failed pass 2")
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
