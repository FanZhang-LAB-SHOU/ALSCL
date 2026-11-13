test_that("a malformed speed option stops refinement with its own message (F65)", {
  obj <- list(fn = function(x) sum((x - 2)^2), gr = function(x) 2 * (x - 2))
  withr::local_options(list(ALSCL.sd_cores = 1L, ALSCL.sd_backend = NULL,
                            ALSCL.se_level = NULL, ALSCL.delta_method = NULL))
  good <- ALSCL:::.acl_polish(obj, c(x = 1), -10, 10)
  expect_identical(good$status, "gradient_tolerance")
  expect_identical(good$hessian_message, "")
  withr::with_options(list(ALSCL.sd_cores = "4"),
    expect_error(ALSCL:::.acl_polish(obj, c(x = 1), -10, 10), "sd_cores must be"))
  withr::with_options(list(ALSCL.sd_cores = 0),
    expect_error(ALSCL:::.acl_polish(obj, c(x = 1), -10, 10), "sd_cores must be"))
  withr::with_options(list(ALSCL.sd_backend = "forks"),
    expect_error(ALSCL:::.acl_polish(obj, c(x = 1), -10, 10), "ALSCL.sd_backend"))
  withr::with_options(list(ALSCL.se_level = "hess"),
    expect_error(ALSCL:::.acl_polish(obj, c(x = 1), -10, 10), "ALSCL.se_level"))
  # Without refinement nothing is computed, so nothing is checked.
  withr::with_options(list(ALSCL.sd_cores = "4"),
    expect_identical(ALSCL:::.acl_polish(obj, c(x = 1), -10, 10, FALSE)$status, "disabled"))
  # A numerical failure of the Hessian step keeps its status and gains the reason.
  saddle <- ALSCL:::.acl_polish(list(fn = function(x) -x^2, gr = function(x) -2 * x), 1, -10, 10)
  expect_identical(saddle$status, "hessian_unusable")
  expect_true(nzchar(saddle$hessian_message))
})

test_that("diagnostics report unfinished refinement and an SD driven toward zero (F70)", {
  fit <- list(opt = list(par = c(mean_log_R = 5, log_std_log_N0 = log(2.15e-4), log_std_index = log(.2))),
    vcov = diag(c(.01, 337^2, .01)), convergence_code = 0L, max_abs_gradient = 2.17e-5,
    pdHess = TRUE, bound_hit = FALSE, refinement = list(enabled = TRUE, status = "iteration_limit"))
  d <- ALSCL:::.acl_fit_diagnostics(fit)
  # The verdict of the numerical screen is unchanged; the issues are new.
  expect_true(d$numerical_ok)
  expect_false(d$natural_boundary)
  expect_identical(d$sd_near_zero, "log_std_log_N0")
  expect_true(d$refinement_unfinished)
  expect_true(any(grepl("SD estimate close to zero.*log_std_log_N0", d$issues)))
  expect_true(any(grepl("refinement stopped before its gradient tolerance \\(iteration_limit\\)", d$issues)))
  expect_identical(d$thresholds$sd_near_zero, 1e-3)

  # A well-determined small SD, and an SD that is not small, are not reported.
  precise <- fit; precise$vcov <- diag(c(.01, .01, .01))
  expect_length(ALSCL:::.acl_fit_diagnostics(precise)$sd_near_zero, 0L)
  interior <- fit; interior$opt$par[["log_std_log_N0"]] <- log(.3)
  expect_length(ALSCL:::.acl_fit_diagnostics(interior)$sd_near_zero, 0L)
  # An SD already at the natural-scale boundary keeps its existing issue only.
  collapsed <- fit; collapsed$opt$par[["log_std_log_N0"]] <- log(7.6e-6)
  dc <- ALSCL:::.acl_fit_diagnostics(collapsed)
  expect_false(dc$numerical_ok)
  expect_length(dc$sd_near_zero, 0L)
  expect_true("natural-scale boundary" %in% dc$issues)

  # Finished refinement, disabled refinement and old fits raise no issue.
  for (refinement in list(list(enabled = TRUE, status = "gradient_tolerance"),
                          list(enabled = FALSE, status = "disabled"), NULL)) {
    clean <- precise; clean$refinement <- refinement; clean$max_abs_gradient <- 3e-8
    dd <- ALSCL:::.acl_fit_diagnostics(clean)
    expect_false(dd$refinement_unfinished)
    expect_length(dd$issues, 0L)
    expect_true(dd$numerical_ok)
  }
  # An early stop at a gradient below the refinement tolerance is finished.
  small <- precise; small$max_abs_gradient <- 5e-7
  small$refinement <- list(enabled = TRUE, status = "no_acceptable_step")
  expect_false(ALSCL:::.acl_fit_diagnostics(small)$refinement_unfinished)
})
