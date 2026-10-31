comparison_review_fixture <- function() {
  observed <- matrix(c(0, 12:15, NA_real_, 17:22), 3L, 4L)
  predicted <- matrix(10, 3L, 4L)
  residual <- matrix(999, 3L, 4L)
  valid <- is.finite(observed) & observed > 0
  residual[valid] <- log(observed[valid]) - log(predicted[valid])
  model <- list(model_type = "ALSCL", year = 2000:2003,
    len_label = c("5-10", "10-20", "20-70"), len_mid = c(7.5, 15, 45),
    observations = observed,
    report = list(Elog_index = log(predicted), resid_index = residual))
  data <- data.frame(LengthBin = model$len_label, observed, check.names = FALSE)
  names(data)[-1L] <- as.character(model$year)
  list(model = model, data = data, valid = valid)
}

comparison_review_panels <- function(plot) {
  panels <- if (inherits(plot, "plot_filler")) list() else list(plot)
  if (inherits(plot, "patchwork"))
    for (child in plot$patches$plots)
      panels <- c(panels, comparison_review_panels(child))
  panels
}

comparison_review_residuals <- function(plot) {
  panels <- comparison_review_panels(plot)
  data <- lapply(panels, function(p) p$data)
  Filter(function(d) is.data.frame(d) && "Residual" %in% names(d), data)
}

test_that("paired plots reject changed fitted observations and missing masks", {
  fixture <- comparison_review_fixture()
  m <- fixture$model; data <- fixture$data
  for (fun in list(plot_compare_residuals, plot_compare_CatL)) {
    changed <- data; changed[2L, 2L] <- 12000
    expect_error(fun(m, m, changed), "Model 1.*observation values")
    for (cell in list(c(1L, 2L), c(3L, 3L))) {
      changed <- data; changed[cell[1L], cell[2L]] <- 10000
      expect_error(fun(m, m, changed), "Model 1.*observation mask")
    }
    for (missing in c(0, NA_real_)) {
      changed <- data; changed[2L, 2L] <- missing
      expect_error(fun(m, m, changed), "Model 1.*observation mask")
    }
    m2 <- m; m2$observations[2L, 1L] <- 12000
    expect_error(fun(m, m2, data), "Model 2.*observation values")
    m2 <- m; m2$observations[1L, 1L] <- 10000
    expect_error(fun(m, m2, data), "Model 2.*observation mask")
  }
})

test_that("paired plots share fitting's positive observation mask", {
  fixture <- comparison_review_fixture()
  m <- fixture$model; data <- fixture$data
  # NA and zero both denote absent observations; changing one to the other
  # must not reject an otherwise identical survey or create a plotted point.
  data[1L, 2L] <- NA_real_; data[3L, 3L] <- 0
  catl <- plot_compare_CatL(m, m, data)
  observed <- catl$data[catl$data$Source == "Observed", ]
  expect_equal(nrow(observed), sum(fixture$valid))
  expect_true(all(is.finite(observed$Value) & observed$Value > 0))
  expect_equal(observed$Value, as.numeric(m$observations[fixture$valid]))
  predicted <- catl$data[catl$data$Source != "Observed", ]
  expect_equal(nrow(predicted), 2L * length(m$observations))
  expect_equal(predicted$Value, rep(10, nrow(predicted)))
  expect_silent(ggplot2::ggplot_build(catl))

  residual_plot <- plot_compare_residuals(m, m, data)
  residuals <- comparison_review_residuals(residual_plot)
  expect_true(length(residuals) > 0L)
  for (d in residuals) {
    expect_equal(nrow(d), 2L * sum(fixture$valid))
    expect_equal(d$Residual,
      rep(as.numeric(m$report$resid_index[fixture$valid]), 2L))
    expect_true(all(is.finite(d$Residual) & d$Residual != 999))
  }
  # An entirely missing selected period retains predictions but no observations.
  m$observations[, 2L] <- 0
  data[, 3L] <- 0
  p <- plot_compare_CatL(m, m, data, years = 2001)
  expect_false(any(p$data$Source == "Observed"))
  expect_equal(nrow(p$data), 2L * nrow(m$observations))
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("paired plots normalize equivalent survey classes without factor codes", {
  fixture <- comparison_review_fixture()
  m <- fixture$model; data <- fixture$data
  factors <- data
  factors[] <- lapply(factors, function(x) factor(as.character(x)))
  inputs <- list(as.matrix(data), factors, dplyr::as_tibble(data),
                 dplyr::as_tibble(factors))
  expected_catl <- plot_compare_CatL(m, m, data)$data
  expected_resid <- comparison_review_residuals(plot_compare_residuals(m, m, data))
  for (input in inputs) {
    expect_equal(plot_compare_CatL(m, m, input)$data, expected_catl)
    expect_equal(comparison_review_residuals(plot_compare_residuals(m, m, input)),
                 expected_resid)
  }
})

test_that("legacy paired plots retain available checks without requiring new metadata", {
  fixture <- comparison_review_fixture()
  m <- fixture$model; data <- fixture$data
  old <- m; old$observations <- old$year <- old$len_label <- NULL
  expect_equal(plot_compare_CatL(old, old, data)$data,
               plot_compare_CatL(m, m, data)$data)
  expect_equal(comparison_review_residuals(plot_compare_residuals(old, old, data)),
               comparison_review_residuals(plot_compare_residuals(m, m, data)))
  old$report$Elog_index[2L, 1L] <- Inf
  for (fun in list(plot_compare_residuals, plot_compare_CatL))
    expect_error(fun(m, old, data), "Model 2.*nonfinite predictions")
})

test_that("catch comparison rejects nonfinite predictions at drawn missing cells", {
  fixture <- comparison_review_fixture()
  m <- fixture$model; data <- fixture$data
  for (value in c(Inf, NA_real_, 1000)) {
    bad <- m; bad$report$Elog_index[1L, 1L] <- value
    expect_error(plot_compare_CatL(m, bad, data),
                 "Predictions must be finite at every plotted length and period")
    # An omitted period is not drawn; the remaining positive cells are valid.
    expect_silent(ggplot2::ggplot_build(
      plot_compare_CatL(m, bad, data, years = 2001:2003)))
  }
})

test_that("validated comparison panels retain grid-free defaults", {
  fixture <- comparison_review_fixture()
  m <- fixture$model; data <- fixture$data
  old <- options(acl.theme = NULL); on.exit(options(old))
  for (plot in list(plot_compare_CatL(m, m, data),
                    plot_compare_residuals(m, m, data))) {
    for (panel in comparison_review_panels(plot)) {
      theme <- ggplot2::ggplot_build(panel)$plot$theme
      for (element in c("panel.grid.major.x", "panel.grid.major.y",
                        "panel.grid.minor.x", "panel.grid.minor.y"))
        expect_s3_class(ggplot2::calc_element(element, theme), "element_blank")
    }
  }
})
