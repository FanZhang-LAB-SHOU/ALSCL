test_that("simulation summaries count failures and only use available valid uncertainty", {
  fit <- list(year = c(2000, 2001), report = list(SSB = c(11, 18), Rec = c(2, 4)),
    est_std = cbind(Estimate = c(11, 18, 2, 4), `Std. Error` = c(1, 1, NA, 0)),
    opt = list(par = c(mean_log_R = 1), objective = 1), elapsed = 2,
    convergence_code = 0L, pdHess = TRUE, bound_hit = FALSE, max_abs_gradient = 0,
    diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE))
  rownames(fit$est_std) <- c("SSB", "SSB", "Rec", "Rec")
  invalid <- fit
  invalid$diagnostics$numerical_ok <- FALSE
  invalid$elapsed <- 4
  fits <- list(one = fit, two = invalid, three = list(error = "fit failed", elapsed = 6))
  target <- list(year = c(2000, 2001), SSB = c(10, 20), Rec = c(0, 4))
  truth <- list(three = target, one = target, two = target)
  z <- summarize_simulations(fits, truth)
  expect_equal(z$summary$n_replicates, c(3, 3))
  expect_equal(z$summary$n_valid_fits, c(1, 1))
  expect_equal(z$summary$n_points, c(6, 6))
  expect_equal(z$summary$n_valid_pairs, c(2, 2))
  expect_equal(z$summary$n_relative_pairs, c(2, 1))
  expect_equal(z$summary$bias, c(-.5, 1))
  expect_equal(z$summary$rmse, c(sqrt(2.5), sqrt(2)))
  expect_equal(z$summary$n_intervals, c(2, 1))
  expect_equal(z$summary$coverage, c(.5, 1))
  expect_equal(z$summary$failure_rate, c(2/3, 2/3))
  expect_equal(z$summary$mean_elapsed, c(4, 4))
  expect_identical(z$replicates$replicate, names(fits))
  expect_true(all(is.na(z$estimates$covered[z$estimates$replicate != "one"])))
  expect_true(all(is.na(z$estimates$estimate[z$estimates$replicate == "three"])))
  failed <- summarize_simulations(fits[3], truth["three"])
  expect_true(all(is.na(failed$summary$coverage)))
  expect_true(all(is.na(failed$summary$bias)))
  expect_error(summarize_simulations(fits, truth[-1]), "replicate names")
  wrong <- truth; wrong$one$year <- 2001:2002
  expect_error(summarize_simulations(fits, wrong), "time coordinates differ")
  wrong <- truth; wrong$one$SSB <- 1
  expect_error(summarize_simulations(fits, wrong), "match the time")
  expect_error(summarize_simulations(fits, truth, quantities = "F"), "time-series names")
})

test_that("simulation summaries require vector coordinates and time series", {
  fit <- list(year = 2000:2003, report = list(SSB = c(11, 18, 30, 40)),
    opt = list(par = c(mean_log_R = 1), objective = 1),
    convergence_code = 0L, pdHess = TRUE, bound_hit = FALSE, max_abs_gradient = 0,
    diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE))
  target <- list(year = 2000:2003, SSB = c(10, 20, 30, 40))
  summarize <- function(f = fit, t = target)
    summarize_simulations(list(one = f), list(one = t), quantities = "SSB")

  # Equal total length does not make a grouped array a time series. Previously
  # a 2-by-2 truth matrix silently created truth.1/truth.2 and recycled rows,
  # leaving all valid_pair flags TRUE but reporting zero usable pairs and NA bias.
  for (shape in list(c(2L, 2L), c(4L, 1L), c(1L, 4L), c(2L, 1L, 2L), 4L)) {
    wrong <- target; wrong$SSB <- array(target$SSB, dim = shape)
    expect_error(summarize(t = wrong), "Truth quantity SSB.*numeric vector")
    wrong <- target; wrong$year <- array(target$year, dim = shape)
    expect_error(summarize(t = wrong), "Truth year.*numeric vector")
    wrong <- fit; wrong$report$SSB <- array(fit$report$SSB, dim = shape)
    expect_error(summarize(f = wrong), "Fit quantity SSB.*numeric vector")
    wrong <- fit; wrong$year <- array(fit$year, dim = shape)
    expect_error(summarize(f = wrong), "time coordinates.*numeric vectors")
  }
  # Complex numbers are numeric in R but cannot define real-valued coordinates,
  # population quantities or coverage comparisons.
  wrong <- target; wrong$SSB <- as.complex(target$SSB)
  expect_error(summarize(t = wrong), "Truth quantity SSB.*numeric vector")
  wrong <- target; wrong$year <- as.complex(target$year)
  expect_error(summarize(t = wrong), "Truth year.*numeric vector")
  wrong <- fit; wrong$report$SSB <- as.complex(fit$report$SSB)
  expect_error(summarize(f = wrong), "Fit quantity SSB.*numeric vector")
  wrong <- fit; wrong$year <- as.complex(fit$year)
  expect_error(summarize(f = wrong), "time coordinates.*numeric vectors")

  out <- summarize()
  expect_identical(out$estimates$year, target$year)
  expect_equal(out$estimates$truth, target$SSB)
  expect_equal(out$estimates$estimate, fit$report$SSB)
  expect_equal(out$summary$n_points, 4)
  expect_equal(out$summary$n_valid_pairs, sum(out$estimates$valid_pair))
  expect_equal(out$summary$n_valid_pairs, 4)
  expect_equal(out$summary$bias, -.25)
  expect_equal(out$summary$rmse, sqrt(1.25))

  # Invalid estimates from a failed numerical run remain explicit and unscored;
  # the shape guard must not reject these ordinary diagnostic vectors.
  partial <- fit; partial$report$SSB[2] <- NA_real_
  partial$report$SSB[3] <- Inf
  out <- summarize(f = partial)
  expect_identical(out$estimates$valid_pair, c(TRUE, FALSE, FALSE, TRUE))
  expect_equal(out$summary$n_valid_pairs, 2)
  expect_equal(out$summary$bias, .5)
})
