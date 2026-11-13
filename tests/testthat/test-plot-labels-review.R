plot_label_fixture <- function() {
  dev_r <- c(-.2, 0, .3)
  dev_f <- matrix(seq(-.3, .3, length.out = 9), 3, 3)
  list(model_type = "ACL", F_structure = "group_year", year = 2000:2002,
    len_mid = c(10, 20, 30), len_label = c("5-15", "15-25", "25-35"),
    observations = matrix(1:9, 3, 3),
    report = list(F = matrix(.2, 3, 3), dev_log_F = dev_f,
      dev_log_R = dev_r, Elog_index = matrix(log(1:9), 3, 3)),
    est_std = cbind(Estimate = c(dev_r, dev_f), "Std. Error" = rep(.05, 12)))
}

test_that("process labels distinguish log deviations from multipliers without changing estimates", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- plot_label_fixture()
  # Repeated report names represent the flattened TMB summary blocks.
  fit$est_std <- fit$est_std[, c("Estimate", "Std. Error"), drop = FALSE]
  rownames(fit$est_std) <- c(rep("dev_log_R", 3), rep("dev_log_F", 9))
  for (model in c("ACL", "ALSCL", "shared")) {
    m <- fit
    if (model == "ALSCL") {
      m$model_type <- "ALSCL"
      m$report$FL <- m$report$F
      m$report$F <- NULL
    } else if (model == "shared") {
      m$F_structure <- "year"
      m$report$dev_log_F <- m$report$dev_log_F[1, , drop = FALSE]
      m$est_std <- m$est_std[c(1:3, 4, 7, 10), , drop = FALSE]
    }
    for (type in c("R", "F")) for (se in c(FALSE, TRUE)) {
      a <- plot_deviance(m, type = type, se = se, log = TRUE)
      b <- plot_deviance(m, type = type, se = se, log = FALSE)
      expect_match(a$labels$y, "^Log .* deviation$")
      expect_match(b$labels$y, "multiplier$")
      expect_false(identical(a$labels$title, b$labels$title))
      expect_equal(b$data$estimate, exp(a$data$estimate))
      if (se) {
        expect_equal(b$data$lower, exp(a$data$lower))
        expect_equal(b$data$upper, exp(a$data$upper))
      }
      expect_equal(a$data$Year, b$data$Year)
      expect_s3_class(ggplot2::ggplot_build(b), "ggplot_built")
      for (panel in ggplot2::ggplot_build(b)$layout$panel_params)
        expect_lte(sum(is.finite(panel$x$breaks)), 6L)
      expect_s3_class(b$theme$panel.grid.major, "element_blank")
      expect_s3_class(b$theme$panel.grid.minor, "element_blank")
    }
  }
  acl_theme_set(titles = list(dev_R_multiplier = "Recruitment factors"),
    ylab = list(dev_R_multiplier = "Factor"), xlab = list(year = "Survey year"),
    x_breaks = c(2000, 2002), x_expand = c(0, 0))
  p <- plot_deviance(fit, type = "R", se = FALSE, log = FALSE)
  expect_equal(p$labels$title, "Recruitment factors")
  expect_equal(p$labels$y, "Factor")
  expect_equal(p$labels$x, "Survey year")
  expect_equal(ggplot2::ggplot_build(p)$layout$panel_params[[1]]$x$breaks, c(2000, 2002))
})

test_that("survey titles identify indices and normalized compositions and honor overrides", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- plot_label_fixture()
  for (type in c("year", "length")) for (raw in c(FALSE, TRUE)) {
    p <- plot_CatL(fit, facet_by = type, exp_transform = raw)
    expect_match(p$labels$title, "survey indices")
    expect_false(grepl("Catch", p$labels$title))
    expect_equal(plot_CatL(fit, facet_by = type, title = "My survey")$labels$title, "My survey")
  }
  acl_theme_set(titles = list(CatL_by_year = "By survey period"))
  expect_equal(plot_CatL(fit, facet_by = "year")$labels$title, "By survey period")
  p <- plot_ridges(fit, ridges_scale = 1)
  for (panel in list(p[[1L]], p[[2L]])) {
    expect_match(panel$labels$title, "survey length composition")
    expect_equal(as.numeric(tapply(panel$data$Abundance, panel$data$year, sum)), rep(1, 3))
    expect_s3_class(panel$theme$panel.grid.major, "element_blank")
    expect_s3_class(panel$theme$panel.grid.minor, "element_blank")
  }
})
