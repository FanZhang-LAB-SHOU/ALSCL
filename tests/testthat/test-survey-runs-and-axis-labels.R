sparse_plot_fit <- function() {
  x <- list(model_type = "ACL", year = 2011:2020, age = c(.25, .5, .75, 1),
    len_mid = seq(5, 50, 5), len_label = as.character(seq(5, 50, 5)))
  values <- matrix(seq(0.01, 1, .01), 10, 10)
  x$observations <- exp(values)
  # The first panel has two runs of two, two isolated observations and gaps.
  mask <- c(1, NA, 1, 1, 0, 1, 1, NA, NA, 1)
  x$observations[, 1] <- x$observations[, 1] * mask
  x$observations[1, ] <- x$observations[1, ] * mask
  x$report <- list(resid_index = values, Elog_index = values * 0,
    F = matrix(seq_len(40) / 100, 4, 10))
  x
}

test_that("rendered survey and residual panels retain isolated observations and gaps", {
  fit <- sparse_plot_fit()
  withr::local_options(list(acl.theme = NULL))
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  for (by in c("year", "length")) {
    for (residual in c(FALSE, TRUE)) {
      plot <- if (residual) plot_residuals(fit, facet_by = by, line_color = "red") else
        plot_CatL(fit, facet_by = by, line_color2 = "red", point_color = "red")
      built <- ggplot2::ggplot_build(plot)
      panel <- function(layer) {
        data <- built$data[[layer]]
        data[data$PANEL == 1, , drop = FALSE]
      }
      x <- if (by == "year") fit$len_mid else fit$year
      layers <- function(type) which(vapply(plot$layers, function(layer)
        inherits(layer$geom, type), logical(1)))
      points <- panel(layers("GeomPoint"))
      expected <- if (!residual && by == "length") c(1, 3, 4, 6, 7, 10) else c(1, 10)
      points <- points[is.finite(points$y), ]
      expect_equal(points$x, x[expected])
      expect_equal(unique(points$colour), "red")
      if (residual || by == "year") {
        line <- panel(layers("GeomLine")[1L])
        bounds <- function(line) unname(lapply(split(line$x, line$group), range))
        expected_bounds <- list(x[3:4], x[6:7])
        expect_equal(bounds(line), expected_bounds)
        if (residual) {
          trends <- do.call(rbind, lapply(layers("GeomSmooth"), panel))
          expect_equal(bounds(trends), expected_bounds)
        }
      }
      expect_silent(rendered <- ggplot2::ggplotGrob(plot))
      # A layer row alone does not establish that ggplot draws the point.
      children <- rendered$grobs[[match("panel-1-1", rendered$layout$name)]]$children
      drawn <- Filter(function(grob) inherits(grob, "points"), as.list(children))
      expect_length(drawn, 1L)
      expect_length(drawn[[1L]]$x, length(expected))
      for (axis in c("major.x", "major.y", "minor.x", "minor.y"))
        expect_s3_class(ggplot2::calc_element(paste0("panel.grid.", axis),
                                              built$plot$theme), "element_blank")
    }
  }
})

test_that("only numerical length intervals are shortened at plot boundaries", {
  fit <- sparse_plot_fit()
  labels <- fit$len_label
  plot_labels <- function(first, last) {
    fit$len_label <- factor(c(first, labels[2:9], last))
    levels(plot_CatL(fit, return_data = TRUE)$data1$LengthGroup)[c(1, 10)]
  }
  expect_equal(plot_labels("50e-1", "500e-1"), paste("Length bin", c("50e-1", "500e-1")))
  expect_equal(plot_labels("small-fish", "adult-fish"), paste("Length bin", c("small-fish", "adult-fish")))
  expect_equal(plot_labels(" -1e-2 - 7.5 ", "47.5-52.5"), paste("Length bin", c("<7.5", ">47.5")))
  expect_equal(plot_labels("0-10", "45-55"), paste("Length bin", c("<10", ">45")))
})

test_that("F heatmaps use fitted ages and order overlapping age grids independently", {
  q <- sparse_plot_fit()
  a <- q
  a$age <- c(1, 2, 3, 4)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  for (fits in list(list(q, a), list(a, q))) {
    plot <- plot_compare_F(fits[[1L]], fits[[2L]])
    expect_silent(ggplot2::ggplotGrob(plot))
    built <- ggplot2::ggplot_build(plot)
    for (model in seq_along(fits)) {
      original <- fits[[model]]
      breaks <- built$layout$panel_params[[model]]$y$get_labels()
      # The oldest age class is a plus group and carries a plus sign.
      age_labels <- paste("Age", original$age)
      age_labels[length(age_labels)] <- paste0(age_labels[length(age_labels)], "+")
      expect_equal(breaks, rev(age_labels))
      model_data <- plot$data[as.integer(plot$data$Model) == model, ]
      expect_equal(as.character(model_data$Label), rep(age_labels, length(original$year)))
      expect_equal(model_data$F_value, as.numeric(original$report$F))
    }
  }
  a$age <- NULL
  labels <- ggplot2::ggplot_build(plot_compare_F(q, a))$layout$panel_params[[2L]]$y$get_labels()
  expect_equal(labels, paste("Age group", 4:1))
  for (bad in list(c(1, 2), c(1, 2, 2, 4), c(1, 2, NA, 4))) {
    a$age <- bad
    expect_error(plot_compare_F(q, a), "ages must")
  }
})

test_that("a compact ALSCL report with just FL retains its length coordinates", {
  model <- sparse_plot_fit()
  model$model_type <- "ALSCL"
  model$report <- list(FL = matrix(seq_len(100) / 100, 10L, 10L))
  fit_plot <- plot_compare_F(model, model)
  expect_identical(as.character(fit_plot$data$Label),
                   rep(model$len_label, 2L * length(model$year)))
  extracted <- extract_estimates(model, "F")
  expect_identical(unique(extracted$report_name), "FL")
  expect_identical(extracted$estimate, as.numeric(model$report$FL))
  expect_true(all(is.na(extracted$age)))
  expect_identical(extracted$length, rep(model$len_mid, length(model$year)))
})
