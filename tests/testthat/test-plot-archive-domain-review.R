plot_review_panels_242 <- function(plot) {
  panels <- if (inherits(plot, "plot_filler")) list() else list(plot)
  if (inherits(plot, "patchwork"))
    for (child in plot$patches$plots)
      panels <- c(panels, plot_review_panels_242(child))
  panels
}

expect_grid_free_242 <- function(plot) {
  for (panel in plot_review_panels_242(plot)) {
    theme <- ggplot2::ggplot_build(panel)$plot$theme
    for (grid in c("panel.grid.major.x", "panel.grid.major.y",
                   "panel.grid.minor.x", "panel.grid.minor.y"))
      expect_s3_class(ggplot2::calc_element(grid, theme), "element_blank")
  }
}

test_that("catchability comparisons work from portable ACL and ALSCL assessments", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fits <- lapply(c("ACL", "ALSCL"), function(model) fit_fixture(model)$result)
  saved <- lapply(fits, function(fit) {
    path <- tempfile(fileext = ".rds"); on.exit(unlink(path), add = TRUE)
    save_assessment(fit, path)
    read_assessment(path)
  })
  expect_true(all(vapply(saved, function(fit) is.null(fit$obj), logical(1))))
  expected <- unlist(lapply(fits, function(fit) exp(fit$obj$env$data$log_q)), use.names = FALSE)
  live <- plot_compare_selectivity(fits[[1]], fits[[2]])
  portable <- plot_compare_selectivity(saved[[1]], saved[[2]])
  expect_equal(portable$data$Selectivity, expected, tolerance = 0)
  expect_equal(portable$data, live$data, tolerance = 0)
  expect_equal(ggplot2::ggplot_build(portable)$data, ggplot2::ggplot_build(live)$data)
  expect_grid_free_242(portable)
  # Either input can independently be a portable assessment.
  expect_equal(plot_compare_selectivity(saved[[1]], fits[[2]])$data, portable$data)
  expect_equal(plot_compare_selectivity(fits[[1]], saved[[2]])$data, portable$data)
})

test_that("legacy catchability inputs retain exact endpoints and fail clearly when missing", {
  q <- c(0, .001, .5, 1)
  fit <- list(model_type = "ACL", len_mid = c(10, 20, 30, 40),
              obj = list(env = list(data = list(log_q = log(q)))))
  expect_equal(plot_compare_selectivity(fit, fit)$data$Selectivity, rep(q, 2))
  fit$obj <- NULL
  expect_error(plot_compare_selectivity(fit, fit), "complete saved recipe or fitted log_q")
  fit$recipe <- list(args = list(sel_L50 = 30, sel_L95 = 20))
  expect_error(plot_compare_selectivity(fit, fit), "sel_L95 greater than sel_L50")
  fit$recipe$args$sel_L95 <- 40
  fit$len_mid[1] <- NA_real_
  expect_error(plot_compare_selectivity(fit, fit), "finite fitted length midpoints")
})

growth_comparison_fixture_242 <- function(age = 2:5, t0 = 1.5) {
  list(model_type = "ACL", age = age,
       report = list(Linf = 60, vbk = .2, t0 = t0,
                     pla = matrix(1 / 3, 3, length(age))))
}

growth_comparison_data_242 <- function(plot) {
  panels <- plot_review_panels_242(plot)
  data <- lapply(panels, function(panel) panel$data)
  Filter(function(d) is.data.frame(d) && all(c("Age", "Length", "Model") %in% names(d)) &&
           !"Probability" %in% names(d), data)[[1L]]
}

test_that("growth comparisons use fitted ages and never default to pre-t0 lengths", {
  skip_if_not_installed("patchwork")
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  first <- growth_comparison_fixture_242()
  second <- growth_comparison_fixture_242(seq(2.25, 6, .25), 2.25)
  second$model_type <- "ALSCL"
  plot <- plot_compare_growth(first, second)
  data <- growth_comparison_data_242(plot)
  expect_equal(range(data$Age), c(2.25, 6))
  expect_true(all(data$Length >= 0))
  for (name in unique(data$Model)) {
    selected <- data[data$Model == name, ]
    fit <- if (name == "ACL") first else second
    expect_equal(selected$Length,
                 fit$report$Linf * (1 - exp(-fit$report$vbk * (selected$Age - fit$report$t0))))
  }
  expect_grid_free_242(plot)
  for (bounds in list(c(2.25, 2.3), c(3.13, 8.37), c(20, 25))) {
    data <- growth_comparison_data_242(plot_compare_growth(first, second, age_range = bounds))
    expect_equal(range(data$Age), bounds)
    expect_true(all(data$Length >= 0))
    expect_gte(length(unique(data$Age)), 2L)
  }
  expect_error(plot_compare_growth(first, second, age_range = c(2, 5)),
               "start at or after both t0")
  for (bad in list(c(3, 3), c(4, 3), numeric(), 3, c(3, 4, 5), c(NA, 5), c(3, Inf), "3"))
    expect_error(plot_compare_growth(first, second, age_range = bad), "finite increasing pair")
})

test_that("growth comparison ranges validate metadata and keep a legacy fallback", {
  skip_if_not_installed("patchwork")
  first <- growth_comparison_fixture_242()
  second <- first
  second$age <- NULL
  expect_equal(range(growth_comparison_data_242(plot_compare_growth(first, second))$Age), c(1.5, 20))
  second$age <- c(1, NA_real_)
  expect_error(plot_compare_growth(first, second), "finite numeric ages")
  expect_no_error(plot_compare_growth(first, second, age_range = c(2, 5)))
  second$age <- 1:2
  first$age <- 1:2
  second$report$t0 <- 3
  expect_error(plot_compare_growth(first, second), "positive span")
  for (parameter in c("Linf", "vbk", "t0")) {
    bad <- growth_comparison_fixture_242()
    bad$report[[parameter]] <- NA_real_
    expect_error(plot_compare_growth(first, bad, age_range = c(3, 5)), "Growth parameters")
  }
})

test_that("fitted reference growth curves respect their own growth origin", {
  skip_if_not_installed("patchwork")
  fit <- growth_comparison_fixture_242(age = 1:8, t0 = .1)
  observed <- data.frame(Age = 3:10)
  observed$Length <- 60 * (1 - exp(-.2 * (observed$Age - 2))) +
    c(.01, -.01, .015, -.01, .01, -.015, .01, -.01)
  start <- list(Linf = 60, k = .2, t0 = 2)
  estimate <- stats::coef(stats::nls(Length ~ Linf * (1 - exp(-k * (Age - t0))),
                                    data = observed, start = start))
  plot <- plot_compare_growth(fit, fit, ref_data = observed, nls_start = start)
  data <- growth_comparison_data_242(plot)
  reference <- data[data$Model == "Observed VB", ]
  expect_true(nrow(reference) > 1L)
  expect_true(all(reference$Length >= 0))
  expect_equal(range(reference$Age), c(unname(estimate["t0"]), 8))
  expect_equal(reference$Length[1L], 0)
  expect_equal(range(data$Age[data$Model != "Observed VB"]), c(1, 8))
  expect_grid_free_242(plot)

  expect_warning(plot <- plot_compare_growth(fit, fit, age_range = c(1, 1.5),
    ref_data = observed, nls_start = start), "no positive age span.*Skipping reference curve")
  data <- growth_comparison_data_242(plot)
  expect_false("Observed VB" %in% data$Model)
  expect_equal(range(data$Age), c(1, 1.5))
  panel <- Filter(function(panel) is.data.frame(panel$data) &&
    "Model" %in% names(panel$data) && !"Probability" %in% names(panel$data),
    plot_review_panels_242(plot))[[1L]]
  points <- which(vapply(panel$layers, function(layer) inherits(layer$geom, "GeomPoint"), logical(1)))
  expect_equal(panel$layers[[points]]$data, observed)
  expect_grid_free_242(plot)

  observed <- data.frame(Age = 1:6)
  observed$Length <- -60 * (1 - exp(.2 * observed$Age)) + sin(observed$Age)
  expect_warning(plot <- plot_compare_growth(fit, fit, ref_data = observed,
    nls_start = list(Linf = -60, k = -.2, t0 = 0)),
    "finite positive Linf and k.*Skipping reference curve")
  expect_false("Observed VB" %in% growth_comparison_data_242(plot)$Model)
})

test_that("retrospective and metric labels inherit fonts while keeping grids hidden", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  acl_theme_set(font_family = "mono")
  retro_data <- expand.grid(Year = 2000:2002,
    RetrospectiveYear = c("2004", "2003"), Variable = "SSB")
  retro_data$Value <- seq_len(nrow(retro_data))
  retro <- list(results = retro_data,
    last_points = retro_data[retro_data$Year == 2002, ],
    rho_text = data.frame(Variable = "SSB", Rho = .01))
  text_families <- function(plot) {
    unlist(lapply(plot_review_panels_242(plot), function(panel) {
      layers <- which(vapply(panel$layers, function(layer) inherits(layer$geom, "GeomText"), logical(1)))
      built <- ggplot2::ggplot_build(panel)
      unlist(lapply(layers, function(i) built$data[[i]]$family), use.names = FALSE)
    }), use.names = FALSE)
  }
  p <- plot_retro(retro)
  expect_equal(unique(text_families(p)), "mono")
  expect_grid_free_242(p)
  p <- plot_retro(retro, font_family = "serif")
  expect_equal(unique(text_families(p)), "serif")
  expect_grid_free_242(p)

  observations <- matrix(11:19, 3, 3)
  fit <- list(model_type = "ACL", year = 2000:2002, len_mid = c(10, 20, 30),
    len_label = c("10", "20", "30"), observations = observations,
    report = list(Elog_index = log(observations * 1.1)),
    opt = list(par = c(a = 1, b = 2), objective = 10))
  data <- data.frame(LengthBin = fit$len_label, observations, check.names = FALSE)
  names(data)[-1L] <- as.character(fit$year)
  p <- plot_compare_metrics(fit, fit, data)
  expect_equal(unique(text_families(p)), "mono")
  expect_grid_free_242(p)
})
