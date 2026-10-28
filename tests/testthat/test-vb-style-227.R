vb_style_fixture_227 <- function() {
  covariance <- diag(c(.01, .02, .005))
  dimnames(covariance) <- list(c("log_Linf", "log_vbk", "t0"),
                              c("log_Linf", "log_vbk", "t0"))
  list(report = list(Linf = 70, vbk = .2, t0 = -.1),
       vcov = covariance, pdHess = TRUE)
}

test_that("plain growth curves honor custom and empty y-axis labels", {
  model <- vb_style_fixture_227()
  expect_identical(plot_VB(model, se = FALSE, ylab = "Length (cm)")$labels$y,
                   "Length (cm)")
  expect_identical(plot_VB(model, se = FALSE, ylab = "")$labels$y, "")
  expect_identical(plot_VB(model, se = FALSE)$labels$y, "Length")
})

test_that("unavailable growth intervals preserve all estimate-only styling", {
  old <- options(acl.theme = NULL); on.exit(options(old))
  model <- vb_style_fixture_227()
  style <- list(age_range = c(2, 7), line_size = 2.3, line_color = "navy",
    line_type = "dashed", text_size = 8, text_color = "orange",
    title = "Growth example", xlab = "Age in years", ylab = "Length (cm)",
    font_family = "mono", title_size = 21, axis_title_size = 18,
    axis_text_size = 23, strip_text_size = 16, legend_text_size = 15,
    x_breaks = c(2, 4, 6), base_theme = "theme_classic", title_hjust = .1)
  plain <- do.call(plot_VB, c(list(model_result = model, se = FALSE), style))
  plain_built <- ggplot2::ggplot_build(plain)
  cases <- list(missing = model, nonfinite = model, hessian = model)
  cases$missing$vcov <- NULL
  cases$nonfinite$vcov[1, 1] <- NA_real_
  cases$hessian$pdHess <- FALSE
  for (name in names(cases)) {
    expect_warning(fallback <- do.call(plot_VB,
      c(list(model_result = cases[[name]], se = TRUE), style)),
      "drawing the estimate only")
    built <- ggplot2::ggplot_build(fallback)
    expect_equal(built$data, plain_built$data, info = name)
    expect_equal(fallback$labels, plain$labels, info = name)
    expect_equal(fallback$data, plain$data, info = name)
    expect_equal(fallback$scales$get_scales("x")$breaks, c(2, 4, 6), info = name)
    th <- built$plot$theme
    element <- function(key) ggplot2::calc_element(key, th)
    expect_equal(element("axis.text.x")$size, 23, info = name)
    expect_equal(element("axis.title.y")$size, 18, info = name)
    expect_equal(element("plot.title")$size, 21, info = name)
    expect_equal(element("plot.title")$hjust, .1, info = name)
    expect_equal(element("strip.text")$size, 16, info = name)
    expect_equal(element("legend.text")$size, 15, info = name)
    expect_identical(element("axis.text.x")$family, "mono", info = name)
    expect_equal(th, plain_built$plot$theme, info = name)
    for (grid in c("panel.grid.major.x", "panel.grid.major.y",
                   "panel.grid.minor.x", "panel.grid.minor.y"))
      expect_s3_class(element(grid), "element_blank")
    expect_equal(built$data[[1]]$linewidth, rep(2.3, nrow(plain$data)), info = name)
    expect_true(all(built$data[[1]]$colour == "navy"), info = name)
    expect_true(all(built$data[[1]]$linetype == "dashed"), info = name)
    expect_identical(built$data[[2]]$colour, "orange", info = name)
    expect_equal(built$data[[2]]$size, 8, info = name)
    expect_match(built$data[[2]]$label, "Linf = 70", info = name)
  }
})

test_that("valid growth intervals retain numerical values and styling", {
  model <- vb_style_fixture_227()
  for (kind in c("ribbon", "errorbar")) {
    expect_no_warning(p <- plot_VB(model, se = TRUE, se_type = kind,
      age_range = c(1, 3), ylab = "Length (cm)", se_color = "orange",
      se_alpha = .4, line_color = "navy", x_breaks = c(1, 2, 3),
      axis_text_size = 23))
    built <- ggplot2::ggplot_build(p)
    expected <- ALSCL:::.acl_growth_interval(model, p$data$age)
    expect_equal(p$data$lower, expected$lower)
    expect_equal(p$data$upper, expected$upper)
    expect_equal(built$data[[1]]$ymin, expected$lower)
    expect_equal(built$data[[1]]$ymax, expected$upper)
    expect_identical(p$labels$y, "Length (cm)")
    expect_equal(p$scales$get_scales("x")$breaks, c(1, 2, 3))
    expect_equal(ggplot2::calc_element("axis.text.x", built$plot$theme)$size, 23)
    if (kind == "ribbon") {
      expect_true(all(built$data[[1]]$fill == "orange"))
      expect_true(all(built$data[[1]]$alpha == .4))
    } else expect_true(all(built$data[[1]]$colour == "orange"))
    expect_true(all(built$data[[2]]$colour == "navy"))
  }
})
