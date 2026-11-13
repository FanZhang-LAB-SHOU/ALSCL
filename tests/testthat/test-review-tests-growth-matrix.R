# Review finding F48: the ALSCL growth transition matrix G reported by the
# template is compared with its formula (ref_growth_matrix() in
# helper-review-reference.R restates inst/extdata/ALSCL.cpp lines 104-121) and
# with Gij from sim_cal(), which the operating model uses.

review_growth_report <- function(len_mid, len_border, growth_step, Linf, vbk, cv_grow,
                                 nage = 6L) {
  L <- length(len_mid); Y <- 3L
  x <- ref_model_inputs("ALSCL", matrix(1, L, Y), len_mid, len_border,
    rec.age = growth_step, nage = nage, M = .2, growth_step = growth_step,
    weight = matrix(1, L, Y), maturity = matrix(.5, L, Y),
    sel_L50 = len_mid[2L], sel_L95 = len_mid[3L],
    parameters = list(log_Linf = log(Linf), log_vbk = log(vbk), log_cv_grow = log(cv_grow)))
  ref_tmb_joint("ALSCL", x$data, x$parameters)$report
}

test_that("reported G equals the growth increment formula for annual and quarterly steps (F48)", {
  bins <- list(
    equal = list(mid = seq(12.5, 122.5, 5), border = seq(15, 120, 5)),
    unequal = list(mid = c(8, 15, 21.5, 29, 36.5, 46, 56, 67.5, 82, 100, 125),
                   border = c(12, 18, 25, 33, 40, 52, 60, 75, 90, 110)))
  growth <- list(c(Linf = 152, vbk = .38, cv_grow = .3), c(Linf = 95, vbk = .3, cv_grow = .25),
                 c(Linf = 60, vbk = .2, cv_grow = .1))
  for (name in names(bins)) for (growth_step in c(1, .25)) for (g in growth) {
    label <- paste(name, "bins, growth_step", growth_step, "Linf", g[["Linf"]])
    mid <- bins[[name]]$mid; border <- bins[[name]]$border
    r <- review_growth_report(mid, border, growth_step, g[["Linf"]], g[["vbk"]], g[["cv_grow"]])
    expected <- ref_growth_matrix(mid, border, g[["Linf"]], g[["vbk"]], g[["cv_grow"]], growth_step)
    expect_lt(max(abs(r$G - expected)), 1e-12, label = paste(label, "max |G - formula|"))
    expect_equal(colSums(expected), rep(1, length(mid)), tolerance = 1e-14)
    expect_true(all(expected[upper.tri(expected)] == 0))
    expect_identical(expected[length(mid), length(mid)], 1)
  }
})

test_that("the reference growth matrix follows the stated increment distribution (F48)", {
  # Written out for one column without the helper: a fish at the midpoint of
  # bin j grows by a normal increment with the mean given below and standard
  # deviation cv_grow times that mean, and the last bin takes the right tail.
  mid <- c(8, 15, 21.5, 29, 36.5, 46, 56, 67.5, 82)
  border <- c(12, 18, 25, 33, 40, 52, 60, 75)
  Linf <- 95; vbk <- .3; cv_grow <- .25; growth_step <- .25; j <- 3L
  mean_increment <- growth_step * (1 - exp(-vbk)) * Linf /
    (1 + exp(-log(19) * (mid[j] - .5 * Linf) / (.05 * Linf - .5 * Linf)))
  expect_equal(ref_growth_increment(mid, Linf, vbk, growth_step)[j], mean_increment,
               tolerance = 1e-14)
  # The increment is 95% of its maximum at 0.05 Linf and 50% at 0.5 Linf.
  expect_equal(ref_growth_increment(c(.05, .5) * Linf, Linf, vbk, 1) / ((1 - exp(-vbk)) * Linf),
               c(.95, .5), tolerance = 1e-14)
  cdf <- stats::pnorm(c(-Inf, border, Inf), mid[j] + mean_increment, mean_increment * cv_grow)
  column <- diff(cdf)
  column[seq_len(j - 1L)] <- 0
  column[j] <- cdf[j + 1L]
  column <- column / sum(column)
  G <- ref_growth_matrix(mid, border, Linf, vbk, cv_grow, growth_step)
  expect_lt(max(abs(G[, j] - column)), 1e-14)
  r <- review_growth_report(mid, border, growth_step, Linf, vbk, cv_grow)
  expect_lt(max(abs(r$G[, j] - column)), 1e-12)
})

test_that("reported G equals Gij from sim_cal for the same biology (F48)", {
  for (settings in list(list(species = "tuna"),
                        list(species = "tuna", growth_step = 1, rec.age = 1),
                        list(species = "tuna", Linf = 120, vbk = .25, cv_inc = .15))) {
    params <- do.call(initialize_params, settings)
    bio <- sim_cal(params)
    bins <- ALSCL:::.acl_simulation_bins(params$len_mid, params$len_border)
    label <- paste(names(settings), unlist(settings), collapse = " ")
    r <- review_growth_report(bins$mid, bins$border, params$growth_step, params$Linf,
                              params$vbk, params$cv_inc)
    expected <- ref_growth_matrix(bins$mid, bins$border, params$Linf, params$vbk,
                                  params$cv_inc, params$growth_step)
    expect_lt(max(abs(r$G - bio$Gij)), 1e-12, label = paste(label, "max |G - Gij|"))
    expect_lt(max(abs(bio$Gij - expected)), 1e-12, label = paste(label, "max |Gij - formula|"))
  }
})
