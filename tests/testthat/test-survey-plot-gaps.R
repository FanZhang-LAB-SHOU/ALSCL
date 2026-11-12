survey_gap_fixture <- function(step = 1, periods = 7L) {
  value <- matrix(seq_len(9L * periods) / 100, 9L, periods)
  list(model_type = "ACL", year = 2000 + seq.int(0L, periods - 1L) * step,
    len_mid = seq(10, 90, 10), len_label = as.character(seq(10, 90, 10)),
    observations = exp(value), report = list(resid_index = value, Elog_index = value))
}

survey_gap_panels <- function(p) {
  ans <- list(p)
  if (inherits(p, "patchwork")) for (child in p$patches$plots)
    ans <- c(ans, survey_gap_panels(child))
  ans
}

survey_ridge_panels <- function(fit, ...) {
  testthat::local_mocked_bindings(plot_grid = function(...) list(...), .package = "cowplot")
  Filter(function(x) inherits(x, "ggplot"), plot_ridges(fit, ...))
}

test_that("residual comparison lines break at missing annual and quarterly periods", {
  withr::local_options(list(acl.theme = NULL))
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  for (step in c(1, .25)) {
    fit <- survey_gap_fixture(step)
    fit$observations[, 3] <- NA_real_
    fit$observations[, 5] <- 0
    fit$observations[-1, 4] <- NA_real_
    dat <- data.frame(LengthBin = fit$len_label, fit$observations, check.names = FALSE)
    names(dat)[-1] <- as.character(fit$year)
    p <- plot_compare_residuals(fit, fit, dat)
    mean_panel <- Filter(function(x) is.data.frame(x$data) &&
      "mean_r" %in% names(x$data), survey_gap_panels(p))[[1L]]
    b <- ggplot2::ggplot_build(mean_panel)
    expect_equal(nrow(mean_panel$data), 2L * length(fit$year))
    expect_true(all(is.na(mean_panel$data$mean_r[mean_panel$data$Year %in% fit$year[c(3, 5)]])))
    for (colour in unique(b$data[[2L]]$colour)) {
      lines <- b$data[[2L]][b$data[[2L]]$colour == colour, ]
      expect_equal(unname(lapply(split(lines$x, lines$group), range)),
                   list(fit$year[1:2], fit$year[6:7]))
    }
    expect_equal(sort(unique(b$data[[3L]]$x)), fit$year[c(1, 2, 4, 6, 7)])
    expect_false(fit$year[4] %in% b$data[[4L]]$x)
    expect_silent(patchwork::patchworkGrob(p))
  }
  # No line segment exists when every observed period is isolated; the model
  # legend and individual points must still be drawn.
  fit$observations[, c(2, 6)] <- NA_real_
  dat[-1] <- fit$observations
  p <- plot_compare_residuals(fit, fit, dat, model1_name = "Z fit", model2_name = "A fit")
  expect_silent(grob <- patchwork::patchworkGrob(p))
  expect_true(any(grob$layout$name == "guide-box"))
  guide <- grob$grobs[[match("guide-box", grob$layout$name)]]
  expect_equal(sum(guide$layout$name == "guides"), 1L)
})

test_that("observed ridge polygons stop at gaps and isolated bins remain visible", {
  withr::local_options(list(acl.theme = NULL))
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  fit <- survey_gap_fixture(periods = 3L)
  fit$observations[c(3, 8), 1] <- NA_real_
  fit$observations[5, 1] <- 0
  fit$observations[, 2] <- NA_real_
  panels <- survey_ridge_panels(fit, ridges_scale = 1)
  b <- lapply(panels, ggplot2::ggplot_build)
  observed <- b[[1L]]$data[[1L]]
  lines <- observed[observed$y == 1, ]
  expect_equal(unname(lapply(split(lines$x, lines$group), range)), list(c(10, 20), c(60, 70)))
  expect_false(any(observed$y == 2))
  points <- b[[1L]]$data[[2L]]
  expect_equal(points$x, c(40, 90))
  expect_equal(points$y, 1 + fit$observations[c(4, 9), 1] /
                 sum(fit$observations[, 1], na.rm = TRUE))
  expected <- b[[2L]]$data[[1L]]
  expect_equal(nrow(expected), 27L)
  for (year in c(1, 3)) expect_equal(unique(observed$fill[observed$y == year]),
                                     unique(expected$fill[expected$y == year]))
  expect_equal(b[[1L]]$layout$panel_params[[1L]]$y$get_labels(), as.character(fit$year))
  expect_equal(sum(panels[[1L]]$data$Abundance[panels[[1L]]$data$year == fit$year[1]],
                   na.rm = TRUE), 1)
  expect_silent(grob <- ggplot2::ggplotGrob(panels[[1L]]))
  children <- grob$grobs[[match("panel", grob$layout$name)]]$children
  drawn <- Filter(function(x) inherits(x, "points"), as.list(children))
  expect_length(drawn, 1L)
  expect_length(drawn[[1L]]$x, 2L)
  expect_silent(ggplot2::ggplotGrob(plot_ridges(fit)))
})

test_that("ridge panels share limits, time colors and grid-free axes with sparse observations", {
  withr::local_options(list(acl.theme = NULL))
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  for (all_missing in c(FALSE, TRUE)) for (scale in list(NULL, 3)) {
    fit <- survey_gap_fixture(periods = 3L)
    fit$observations[, 3] <- c(1000, 10, 9, 8, 7, 6, 5, 4, 3)
    if (all_missing) fit$observations[,] <- NA_real_
    panels <- survey_ridge_panels(fit, ridges_scale = scale)
    b <- lapply(panels, ggplot2::ggplot_build)
    axes <- lapply(b, function(x) x$layout$panel_params[[1L]])
    expect_equal(axes[[1L]]$y.range, axes[[2L]]$y.range)
    expect_equal(axes[[1L]]$y$get_labels(), axes[[2L]]$y$get_labels())
    expect_equal(axes[[1L]]$y$get_labels(), as.character(fit$year))
    for (i in 1:2) {
      tops <- as.numeric(panels[[i]]$data$year) + panels[[i]]$data$Abundance
      expect_true(all(tops[is.finite(tops)] < max(axes[[i]]$y.range)))
      for (axis in c("major.x", "major.y", "minor.x", "minor.y"))
        expect_s3_class(ggplot2::calc_element(paste0("panel.grid.", axis),
                                              b[[i]]$plot$theme), "element_blank")
    }
    expect_silent(ggplot2::ggplotGrob(plot_ridges(fit, ridges_scale = scale)))
  }
})

test_that("Brewer ridge palettes support two periods without warnings", {
  withr::local_options(list(acl.theme = NULL))
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  fit <- survey_gap_fixture(periods = 2L)
  for (palette in c("spectral", "BrBG", "RdYlBu", "RdYlGn", "PiYG", "PRGn", "RdBu")) {
    expect_silent(p <- plot_ridges(fit, palette = palette))
    expect_silent(ggplot2::ggplotGrob(p))
  }
})
