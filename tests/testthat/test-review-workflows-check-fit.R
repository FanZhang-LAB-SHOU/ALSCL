test_that("the QQ plot states that its reference is not calibrated (GR1)", {
  skip_on_cran()
  fit <- fit_fixture("ACL")$result
  checks <- check_fit(fit, max_lag = 2)
  qq <- checks$plots$qq
  expect_identical(qq$labels$x, "Standard normal quantile")
  expect_identical(qq$labels$y, "Conditional log residual / fitted SD")
  expect_match(qq$labels$subtitle, "slope below 1")
  expect_length(checks$notes, 3L)
  expect_match(checks$notes[3L], "standard deviation below one")
  # The data and the reference line are unchanged.
  expect_identical(checks$qq_data$residual,
                   sort(residuals(fit, type = "standardized")$residual))
  built <- ggplot2::ggplot_build(qq)
  expect_identical(built$data[[1L]]$slope, 1)
  expect_identical(built$data[[1L]]$intercept, 0)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_no_warning(ggplot2::ggplotGrob(qq))
})
