# Review findings F12 (intervals of positive quantities) and F98 (error-bar
# transparency). The fixture is a hand-built result, so no model is fitted.
review_interval_fit <- function(model = "ALSCL", cv = 0.6) {
  ages <- 1:4; years <- 2000:2004; lengths <- c(10, 20, 30)
  field <- function(n, scale = 1) matrix(seq_len(n * length(years)) * scale, n, length(years))
  report <- list(N = seq_along(years) * 10, B = seq_along(years) * 4, SSB = seq_along(years) * 2,
    CN = seq_along(years) * 1.5, Rec = seq_along(years) * 3,
    "NA" = field(4), NL = field(3), CNA = field(4, .2))
  if (model == "ALSCL") {
    report <- c(report, list(BA = field(4, .5), BL = field(3, .5), SBA = field(4, .25),
      SBL = field(3, .25), CNL = field(3, .2), FL = field(3, .01),
      FA = field(3, .01)[, -1L, drop = FALSE]))
    # No mature fish in the smallest length bin: spawning biomass is exactly zero.
    report$SBL[1L, ] <- 0
  } else report$F <- field(4, .01)
  blocks <- lapply(report, function(x) cbind(Estimate = as.numeric(x),
                                             "Std. Error" = cv * as.numeric(x)))
  est_std <- do.call(rbind, blocks)
  rownames(est_std) <- rep(names(blocks), vapply(blocks, nrow, integer(1)))
  list(model_type = model, F_structure = "group_year", year = years, age = ages,
       growth_step = 1, len_mid = lengths, len_label = as.character(lengths),
       report = report, est_std = est_std)
}

review_interval_calls <- function(fit) {
  alscl <- identical(fit$model_type, "ALSCL")
  calls <- list(
    N = function(...) plot_abundance(fit, type = "N", return_data = TRUE, ...),
    "NA" = function(...) plot_abundance(fit, type = "NA", return_data = TRUE, ...),
    NL = function(...) plot_abundance(fit, type = "NL", return_data = TRUE, ...),
    B = function(...) plot_biomass(fit, type = "B", return_data = TRUE, ...),
    SSB = function(...) plot_SSB(fit, type = "SSB", return_data = TRUE, ...),
    CN = function(...) plot_catch(fit, type = "CN", return_data = TRUE, ...),
    CNA = function(...) plot_catch(fit, type = "CNA", return_data = TRUE, ...),
    Rec = function(...) plot_recruitment(fit, return_data = TRUE, ...))
  if (alscl) calls <- c(calls, list(
    BA = function(...) plot_biomass(fit, type = "BA", return_data = TRUE, ...),
    BL = function(...) plot_biomass(fit, type = "BL", return_data = TRUE, ...),
    SBA = function(...) plot_SSB(fit, type = "SBA", return_data = TRUE, ...),
    SBL = function(...) plot_SSB(fit, type = "SBL", return_data = TRUE, ...),
    CNL = function(...) plot_catch(fit, type = "CNL", return_data = TRUE, ...),
    FL = function(...) plot_fishing_mortality(fit, type = "year", return_data = TRUE, ...),
    FA = function(...) plot_fishing_mortality(fit, type = "age", return_data = TRUE, ...)))
  else calls$F <- function(...) plot_fishing_mortality(fit, type = "year", return_data = TRUE, ...)
  calls
}

test_that("positive quantities use lognormal intervals by default and keep their estimates", {
  withr::local_options(list(acl.theme = NULL))
  for (model in c("ACL", "ALSCL")) {
    fit <- review_interval_fit(model)
    calls <- review_interval_calls(fit)
    for (name in names(calls)) {
      rows <- fit$est_std[rownames(fit$est_std) == name, , drop = FALSE]
      estimate <- rows[, "Estimate"]; se <- rows[, "Std. Error"]
      default <- calls[[name]](se = TRUE)$data
      wald <- calls[[name]](se = TRUE, interval = "wald")$data
      # The interval type never changes a point estimate.
      expect_equal(default$estimate, estimate, ignore_attr = TRUE, info = name)
      expect_identical(default$estimate, wald$estimate, info = name)
      positive <- estimate > 0
      expect_equal(default$lower[positive],
        exp(log(estimate[positive]) - 1.96 * se[positive] / estimate[positive]),
        ignore_attr = TRUE, info = name)
      expect_equal(default$upper[positive],
        exp(log(estimate[positive]) + 1.96 * se[positive] / estimate[positive]),
        ignore_attr = TRUE, info = name)
      expect_true(all(default$lower[positive] > 0), info = name)
      # A coefficient of variation of 0.6 puts the Wald lower bound below zero.
      expect_equal(wald$lower, estimate - 1.96 * se, ignore_attr = TRUE, info = name)
      expect_equal(wald$upper, estimate + 1.96 * se, ignore_attr = TRUE, info = name)
      expect_true(all(wald$lower[positive] < 0), info = name)
      # The ribbon is drawn from the same bounds.
      built <- ggplot2::ggplot_build(calls[[name]](se = TRUE)$plot)
      expect_true(all(built$data[[2L]]$ymin >= 0), info = name)
    }
  }
})

test_that("zero and negative estimates keep Wald bounds without missing values", {
  withr::local_options(list(acl.theme = NULL))
  fit <- review_interval_fit("ALSCL")
  sbl <- plot_SSB(fit, type = "SBL", se = TRUE, return_data = TRUE)$data
  zero <- sbl$estimate == 0
  expect_true(any(zero))
  expect_equal(sbl$lower[zero], rep(0, sum(zero)))
  expect_equal(sbl$upper[zero], rep(0, sum(zero)))
  expect_false(anyNA(sbl[c("lower", "upper")]))
  # ALSCL F at age is total mortality minus natural mortality and can be negative.
  rows <- which(rownames(fit$est_std) == "FA")
  fit$report$FA[1L, 1L] <- -0.05
  fit$est_std[rows[1L], ] <- c(-0.05, 0.02)
  fa <- plot_fishing_mortality(fit, type = "age", se = TRUE, return_data = TRUE)$data
  expect_equal(fa$lower[1L], -0.05 - 1.96 * 0.02)
  expect_equal(fa$upper[1L], -0.05 + 1.96 * 0.02)
  expect_true(all(fa$lower[-1L] > 0))
  expect_false(anyNA(fa[c("lower", "upper")]))
  # An overflowing lognormal bound falls back to the Wald bound for that cell.
  bounds <- ALSCL:::.acl_interval(c(1e-300, 2), c(1, 0.2))
  expect_equal(bounds$upper[1L], 1e-300 + 1.96)
  expect_equal(bounds$upper[2L], 2 * exp(1.96 * 0.1))
  expect_true(all(is.finite(unlist(bounds))))
})

test_that("the interval type follows the call, then the theme, and rejects other values", {
  withr::local_options(list(acl.theme = NULL))
  fit <- review_interval_fit("ACL")
  expect_identical(acl_theme("interval"), "lognormal")
  lognormal <- plot_recruitment(fit, se = TRUE, return_data = TRUE)$data
  old <- acl_theme_set(interval = "wald")
  expect_identical(acl_theme("interval"), "wald")
  wald <- plot_recruitment(fit, se = TRUE, return_data = TRUE)$data
  expect_equal(wald$lower, fit$report$Rec * (1 - 1.96 * 0.6), ignore_attr = TRUE)
  expect_identical(plot_recruitment(fit, se = TRUE, interval = "lognormal",
                                    return_data = TRUE)$data, lognormal)
  # A saved theme restores the setting.
  do.call(acl_theme_set, old)
  expect_identical(acl_theme("interval"), "lognormal")
  for (bad in list("normal", NA_character_, c("wald", "lognormal"), 1)) {
    expect_error(plot_abundance(fit, se = TRUE, interval = bad), "interval must be")
    expect_error(acl_theme_set(interval = bad), "interval must be")
  }
  expect_identical(acl_theme("interval"), "lognormal")
})

test_that("comparison ribbons use the same interval types", {
  withr::local_options(list(acl.theme = NULL))
  fit <- review_interval_fit("ACL")
  other <- review_interval_fit("ALSCL")
  rows <- function(m) m$est_std[rownames(m$est_std) == "SSB", , drop = FALSE]
  expected <- function(sign, m) rows(m)[, 1L] * exp(sign * 1.96 * rows(m)[, 2L] / rows(m)[, 1L])
  ribbon <- plot_compare_ts(fit, other, quantities = "SSB", se = TRUE)$layers[[2L]]$data
  expect_equal(ribbon$lower, c(expected(-1, fit), expected(-1, other)), ignore_attr = TRUE)
  expect_equal(ribbon$upper, c(expected(1, fit), expected(1, other)), ignore_attr = TRUE)
  expect_equal(ribbon$estimate, c(fit$report$SSB, other$report$SSB), ignore_attr = TRUE)
  wald <- plot_compare_ts(fit, other, quantities = "SSB", se = TRUE,
                          interval = "wald")$layers[[2L]]$data
  expect_equal(wald$lower, c(rows(fit)[, 1L] - 1.96 * rows(fit)[, 2L],
                             rows(other)[, 1L] - 1.96 * rows(other)[, 2L]), ignore_attr = TRUE)
  expect_error(plot_compare_ts(fit, other, se = TRUE, interval = "t"), "interval must be")
})

test_that("error bars are opaque unless the call sets se_alpha", {
  withr::local_options(list(acl.theme = NULL))
  fit <- review_interval_fit("ACL")
  layer_alpha <- function(p, geom) {
    built <- ggplot2::ggplot_build(p)
    index <- which(vapply(p$layers, function(x) inherits(x$geom, geom), logical(1)))
    expect_length(index, 1L)
    unique(built$data[[index]]$alpha)
  }
  plots <- list(
    function(...) plot_recruitment(fit, se = TRUE, ...),
    function(...) plot_fishing_mortality(fit, se = TRUE, ...),
    function(...) plot_fishing_mortality(fit, type = "age", se = TRUE, ...))
  for (draw in plots) {
    expect_equal(layer_alpha(draw(se_type = "errorbar"), "GeomErrorbar"), 1)
    expect_equal(layer_alpha(draw(se_type = "errorbar", se_alpha = .4), "GeomErrorbar"), .4)
    # The ribbon keeps the global transparency of a filled area.
    expect_equal(layer_alpha(draw(se_type = "ribbon"), "GeomRibbon"), .2)
  }
  # A single estimate replaces its ribbon by a bar, which must not inherit 0.2.
  one <- fit
  one$year <- fit$year[1L]
  one$report$SSB <- fit$report$SSB[1L]
  one$est_std <- fit$est_std[rownames(fit$est_std) == "SSB", , drop = FALSE][1L, , drop = FALSE]
  bar <- layer_alpha(plot_SSB(one, se = TRUE), "GeomErrorbar")
  expect_true(is.na(bar) || bar == 1)
})

test_that("growth error bars sit at the fitted ages and are opaque by default", {
  withr::local_options(list(acl.theme = NULL))
  covariance <- diag(c(.01, .02, .005))
  dimnames(covariance) <- rep(list(c("log_Linf", "log_vbk", "t0")), 2L)
  fit <- list(report = list(Linf = 70, vbk = .2, t0 = -.1), vcov = covariance,
              pdHess = TRUE, age = 1:8)
  p <- plot_VB(fit, se = TRUE, se_type = "errorbar")
  bars <- ggplot2::ggplot_build(p)$data[[1L]]
  expect_equal(bars$x, 1:8)
  expected <- ALSCL:::.acl_growth_interval(fit, 1:8)
  expect_equal(bars$ymin, expected$lower)
  expect_equal(bars$ymax, expected$upper)
  expect_equal(unique(bars$alpha), 1)
  # The curve itself keeps its fine age grid.
  expect_gt(nrow(p$data), 8L)
  expect_equal(unique(ggplot2::ggplot_build(plot_VB(fit, se = TRUE, se_type = "errorbar",
    se_alpha = .3))$data[[1L]]$alpha), .3)
  # Only fitted ages inside the requested range carry a bar.
  ranged <- plot_VB(fit, se = TRUE, se_type = "errorbar", age_range = c(2.5, 6))
  expect_equal(ggplot2::ggplot_build(ranged)$data[[1L]]$x, 3:6)
})
