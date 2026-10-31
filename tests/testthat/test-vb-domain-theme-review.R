vb_domain_fixture <- function(model = "ACL", fixed = FALSE) {
  keys <- c("log_Linf", "log_vbk", if (model == "ACL") "t0" else "log_t0")
  covariance <- diag(c(.001, .002, .0005))
  dimnames(covariance) <- list(keys, keys)
  if (fixed) covariance <- matrix(.01, 1, 1, dimnames = list("log_N0", "log_N0"))
  # Shifting rec.age and t0 together preserves every fitted age-minus-t0 distance.
  list(model_type = model, age = seq(3, 17, by = if (model == "ACL") 1 else .25),
    report = list(Linf = 60, vbk = .2, t0 = 2 + 1 / 60),
    vcov = covariance, pdHess = TRUE)
}

test_that("default growth ages follow the fit without invalid negative-length intervals", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  for (model in c("ACL", "ALSCL")) for (fixed in c(FALSE, TRUE)) {
    fit <- vb_domain_fixture(model, fixed)
    for (se in c(FALSE, TRUE)) {
      p <- plot_VB(fit, se = se)
      expect_equal(range(p$data$age), range(fit$age))
      expected <- fit$report$Linf * (1 - exp(-fit$report$vbk * (p$data$age - fit$report$t0)))
      expect_equal(p$data$length, expected)
      expect_true(all(p$data$length >= 0))
      if (se) {
        expect_true(all(p$data$lower <= p$data$length))
        expect_true(all(p$data$upper >= p$data$length))
        expect_true(all(p$data$lower <= p$data$upper))
        if (fixed) {
          expect_equal(p$data$lower, expected)
          expect_equal(p$data$upper, expected)
        }
      }
      expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
    }
  }
})

test_that("growth ranges retain valid explicit endpoints and reject pre-t0 extrapolation", {
  fit <- vb_domain_fixture(fixed = TRUE)
  for (se in c(FALSE, TRUE)) {
    expect_error(plot_VB(fit, age_range = c(1, 25), se = se), "start at or after t0")
    for (bounds in list(c(fit$report$t0, 3), c(3.01, 3.04), c(3.13, 8.37), c(20, 25))) {
      p <- plot_VB(fit, age_range = bounds, se = se)
      expect_equal(range(p$data$age), bounds)
      expect_gte(nrow(p$data), 2L)
      expect_true(all(diff(p$data$age) > 0))
      expect_true(all(p$data$length >= 0))
      if (se) expect_true(all(p$data$lower <= p$data$upper))
    }
  }
  p <- plot_VB(fit, age_range = c(fit$report$t0, 3), se = TRUE)
  expect_equal(p$data$length[1], 0)
  expect_equal(p$data$lower[1], 0)
  expect_equal(p$data$upper[1], 0)
  for (bad in list(c(3, 3), c(4, 3), numeric(), 3, c(3, 4, 5), c(NA, 5), c(3, Inf), "3"))
    expect_error(plot_VB(fit, age_range = bad), "finite increasing pair")
  for (bad in list(NA, 1, c(TRUE, FALSE), "TRUE"))
    expect_error(plot_VB(fit, se = bad), "se must be TRUE or FALSE")
  expect_error(plot_VB(fit, se_type = "band"), "arg")
})

test_that("automatic ranges have a safe documented fallback and validate age metadata", {
  fit <- vb_domain_fixture(fixed = TRUE)
  fit$report$t0 <- -.1
  fit$age <- NULL
  expect_equal(range(plot_VB(fit)$data$age), c(1, 25))
  fit$report$t0 <- 2.5
  p <- plot_VB(fit, se = TRUE)
  expect_equal(range(p$data$age), c(2.5, 25))
  expect_true(all(p$data$lower <= p$data$upper))
  fit$age <- c(1, 2, 3, 4)
  expect_equal(range(plot_VB(fit)$data$age), c(2.5, 4))
  fit$age <- c(1, 2)
  expect_error(plot_VB(fit), "positive span")
  fit$age <- c(3, NA)
  expect_error(plot_VB(fit), "finite numeric ages")
  expect_no_error(plot_VB(fit, age_range = c(3, 5)))
})

test_that("growth annotations and axis labels respect global and per-call styles in every mode", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- vb_domain_fixture()
  acl_theme_set(font_family = "mono", ylab = list(growth = "Length (cm)"))
  for (kind in c("plain", "ribbon", "errorbar")) {
    args <- list(model_result = fit, se = kind != "plain", text_size = 4.1, text_color = "orange")
    if (kind != "plain") args$se_type <- kind
    p <- do.call(plot_VB, args)
    b <- ggplot2::ggplot_build(p)
    text_layer <- which(vapply(p$layers, function(z) inherits(z$geom, "GeomText"), logical(1)))
    expect_length(text_layer, 1L)
    expect_equal(b$data[[text_layer]]$family, "mono")
    expect_equal(b$data[[text_layer]]$size, 4.1)
    expect_equal(b$data[[text_layer]]$colour, "orange")
    expect_match(b$data[[text_layer]]$label, "Linf = 60")
    expect_equal(p$labels$y, "Length (cm)")
    for (grid in c("panel.grid.major.x", "panel.grid.major.y", "panel.grid.minor.x", "panel.grid.minor.y"))
      expect_s3_class(ggplot2::calc_element(grid, b$plot$theme), "element_blank")
    args$font_family <- "serif"; args$ylab <- "Body length"
    p <- do.call(plot_VB, args)
    b <- ggplot2::ggplot_build(p)
    expect_equal(b$data[[text_layer]]$family, "serif")
    expect_equal(p$labels$y, "Body length")
  }
  fit$vcov <- NULL
  expect_warning(p <- plot_VB(fit, se = TRUE, font_family = "serif", text_color = "purple"),
                 "drawing the estimate only")
  b <- ggplot2::ggplot_build(p)
  expect_equal(b$data[[2]]$family, "serif")
  expect_equal(b$data[[2]]$colour, "purple")
  expect_equal(p$labels$y, "Length (cm)")
})
