survey_axis_fixture <- function() {
  observations <- matrix(1:9, 3, 3)
  m <- list(model_type = "ACL", year = 2000:2002,
    len_mid = c(10, 20, 30), len_label = c("5-15", "15-25", "25-35"),
    observations = observations,
    report = list(Elog_index = log(observations * 1.2), CN = c(3, 4, 5)))
  d <- data.frame(LengthBin = m$len_label, observations, check.names = FALSE)
  names(d)[-1] <- as.character(m$year)
  list(model = m, data = d)
}

test_that("survey and catch labels identify different quantities without changing plotted values", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  x <- survey_axis_fixture(); m <- x$model
  acl_theme_set(ylab = list(catch = "Fishery catch (numbers)"))
  comparison <- plot_compare_CatL(m, m, x$data)
  expect_identical(comparison$labels$y, "Survey index")
  expect_identical(plot_CatL(m, exp_transform = TRUE)$labels$y, "Survey index")
  expect_identical(plot_CatL(m)$labels$y, "Log survey index")
  expect_identical(plot_catch(m)$labels$y, "Fishery catch (numbers)")
  built <- ggplot2::ggplot_build(comparison)
  fitted <- built$data[[2]]
  for (curve in split(fitted, interaction(fitted$PANEL, fitted$group), drop = TRUE)) {
    y <- as.integer(curve$PANEL[1])
    expect_equal(curve$y, exp(m$report$Elog_index[, y]))
  }
  for (element in c("panel.grid.major.x", "panel.grid.major.y",
                    "panel.grid.minor.x", "panel.grid.minor.y"))
    expect_s3_class(ggplot2::calc_element(element, built$plot$theme), "element_blank")
})

test_that("survey labels have independent global control and preserve legacy abundance settings", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  x <- survey_axis_fixture(); m <- x$model
  acl_theme_set(ylab = list(abundance = "Legacy index"))
  expect_identical(plot_compare_CatL(m, m, x$data)$labels$y, "Legacy index")
  expect_identical(plot_CatL(m)$labels$y, "Log Legacy index")
  acl_theme_set(ylab = list(survey = "Survey index (per tow)", catch = "Catch count"))
  p <- plot_compare_CatL(m, m, x$data)
  expect_identical(p$labels$y, "Survey index (per tow)")
  for (type in c("year", "length")) {
    expect_identical(plot_CatL(m, type = type)$labels$y, "Log Survey index (per tow)")
    expect_identical(plot_CatL(m, type = type, exp_transform = TRUE)$labels$y,
                     "Survey index (per tow)")
    expect_identical(plot_CatL(m, type = type, ylab = "Explicit units")$labels$y,
                     "Explicit units")
  }
  expect_identical(plot_catch(m)$labels$y, "Catch count")
  # Even an explicit label equal to the default wins over the legacy fallback.
  acl_theme_set(ylab = list(survey = "Survey index"))
  expect_identical(plot_compare_CatL(m, m, x$data)$labels$y, "Survey index")
  acl_theme_set(ylab = list(survey = NULL))
  expect_identical(plot_compare_CatL(m, m, x$data)$labels$y, "Legacy index")
})
