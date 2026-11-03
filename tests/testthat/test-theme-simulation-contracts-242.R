test_that("theme snapshots restore nullable axes and nested labels", {
  original <- options(acl.theme = NULL)
  on.exit(options(original), add = TRUE)
  defaults <- acl_theme()
  for (changed_first in c(FALSE, TRUE)) {
    options(acl.theme = NULL)
    if (changed_first) acl_theme_set(line_size = 3, palette = "aaas")
    old <- acl_theme()
    expect_true("x_breaks" %in% names(old))
    expect_true("survey" %in% names(old$ylab))
    expect_null(old$x_breaks)
    expect_null(old$ylab$survey)
    previous <- acl_theme_set(x_breaks = c(2000, 2002),
      ylab = list(survey = "Custom survey", biomass = "Custom biomass"),
      compare_point_size = 6)
    expect_identical(previous, old)
    acl_theme_set(font_family = "mono")
    expect_equal(acl_theme("x_breaks"), c(2000, 2002))
    expect_identical(acl_theme("ylab")$survey, "Custom survey")
    do.call(acl_theme_set, old)
    expect_identical(acl_theme(), old)
    expect_identical(ALSCL:::.acl_survey_label(), "Survey index")
  }
  acl_theme_set(x_breaks = 1:3, ylab = list(survey = "Other", biomass = "Other"))
  acl_theme_set(x_breaks = NULL, ylab = list(survey = NULL, biomass = NULL))
  expect_null(acl_theme("x_breaks"))
  expect_null(acl_theme("ylab")$survey)
  expect_identical(acl_theme("ylab")$biomass, defaults$ylab$biomass)
})

test_that("restored axes and survey labels are used in grid-free plots", {
  original <- options(acl.theme = NULL)
  on.exit(options(original), add = TRUE)
  model <- fit_fixture("ACL")$result
  old <- acl_theme_set(line_size = 3)
  before <- ggplot2::ggplot_build(plot_CatL(model))
  acl_theme_set(x_breaks = c(2000, 2004), ylab = list(survey = "Temporary"))
  customized <- ggplot2::ggplot_build(plot_CatL(model))
  expect_equal(customized$layout$panel_params[[1]]$x$breaks, c(2000, 2004))
  do.call(acl_theme_set, old)
  after <- ggplot2::ggplot_build(plot_CatL(model))
  expect_identical(after$plot$labels$y, before$plot$labels$y)
  expect_equal(after$layout$panel_params[[1]]$x$breaks,
               before$layout$panel_params[[1]]$x$breaks)
  for (grid in c("panel.grid.major.x", "panel.grid.major.y",
                 "panel.grid.minor.x", "panel.grid.minor.y")) {
    expect_s3_class(ggplot2::calc_element(grid, after$plot$theme), "element_blank")
  }
})

test_that("replicate zero passes from simulation through each fitting entry point", {
  directory <- tempfile("simulation-zero-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  p <- initialize_params(species = "flatfish", nyear = 5, burn_in = 0, nage = 4,
    len_mid = seq(15, 55, 5), len_border = seq(12.5, 57.5, 5))
  capture.output(sm <- sim_data(sim_cal(p), p, iter_range = 0, output_dir = directory))
  expect_equal(sm$iter, 0)
  expect_true(file.exists(file.path(directory, "sim_rep0")))
  saved <- new.env(parent = emptyenv())
  load(file.path(directory, "sim_rep0"), envir = saved)
  expect_equal(saved$sim.data$SN_at_len, sm$SN_at_len)
  for (model in c("ACL", "ALSCL")) {
    z <- fit_fixture(model)
    args <- list(iter_range = 0, sim_data_path = directory, output_dir = directory,
      parameters = z$parameters, map = z$map, M = p$M)
    direct <- do.call(sim_model, c(args, list(model = tolower(model))))
    wrapped <- do.call(if (model == "ACL") sim_acl else sim_alscl, args)
    expect_identical(names(direct), "result_rep_0")
    expect_identical(names(wrapped), "result_rep_0")
    for (result in list(direct[[1]], wrapped[[1]])) {
      expect_null(result$error)
      expect_equal(result$iter, 0)
      expect_identical(result$model_type, model)
      expect_true(is.finite(result$opt$objective))
      expect_equal(result$year, sm$years)
    }
    expect_equal(direct[[1]]$opt$objective, wrapped[[1]]$opt$objective, tolerance = 1e-10)
    load(file.path(directory, "result_rep_0"), envir = saved)
    expect_equal(saved$result$iter, 0)
    expect_identical(saved$result$model_type, model)
    expect_equal(saved$result$opt$objective, wrapped[[1]]$opt$objective)
  }
})

test_that("simulation seed collisions are rejected before files or RNG changes", {
  p <- initialize_params(species = "flatfish", nyear = 2, burn_in = 0, nage = 4)
  biology <- sim_cal(p)
  directory <- tempfile("duplicate-simulation-")
  set.seed(242)
  seed <- .Random.seed
  for (ids in list(c(0, 0), c(1, 1), c(0, 1, 0))) {
    expect_error(sim_data(biology, p, iter_range = ids, output_dir = directory),
                 "distinct.*integer seeds")
    expect_error(sim_model(ids, output_dir = directory), "distinct nonnegative integer")
  }
  expect_false(dir.exists(directory))
  expect_identical(.Random.seed, seed)
})
