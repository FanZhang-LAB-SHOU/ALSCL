facet_reference_fixture <- function() {
  years <- 2000:2011
  lengths <- seq(5, 60, 5)
  residuals <- outer(seq_along(lengths), seq_along(years),
                     function(l, y) sin(l / 2) + cos(y / 3) + l * y / 100)
  list(model_type = "ALSCL", year = years, len_mid = lengths,
    len_label = paste0(lengths - 2.5, "-", lengths + 2.5),
    observations = exp(residuals),
    report = list(resid_index = residuals, Elog_index = residuals * 0,
      Linf = 80, vbk = .2, t0 = -.1, pla = matrix(1 / 12, 12, 5)))
}

# Extract rendered trend values by facet, independent of the number of layers.
facet_reference_trends <- function(plot, facet) {
  built <- ggplot2::ggplot_build(plot)
  smooth <- which(vapply(plot$layers, function(layer)
    inherits(layer$stat, "StatSmooth"), logical(1)))
  result <- lapply(smooth, function(i) {
    data <- built$data[[i]]
    if (!nrow(data)) return(NULL)
    data$facet <- as.character(built$layout$layout[[facet]][
      match(data$PANEL, built$layout$layout$PANEL)])
    data[c("facet", "x", "y")]
  })
  if (!length(result)) return(data.frame(facet = character(), x = numeric(), y = numeric()))
  result <- do.call(rbind, result)
  result[order(result$facet, result$x), , drop = FALSE]
}

test_that("sparse residual facets cannot change another facet's trend", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  for (type in c("length", "year")) {
    fit <- facet_reference_fixture()
    facet <- if (type == "length") "LengthGroup" else "Year"
    baseline <- plot_residuals(fit, type = type)
    baseline_trend <- facet_reference_trends(baseline, facet)
    if (type == "length") {
      fit$observations[1, ] <- NA_real_
      fit$observations[2, -1] <- NA_real_
      fit$observations[3, -(1:3)] <- NA_real_
      fit$observations[4, -(1:6)] <- NA_real_
    } else {
      fit$observations[, 1] <- NA_real_
      fit$observations[-1, 2] <- NA_real_
      fit$observations[-(1:3), 3] <- NA_real_
      fit$observations[-(1:6), 4] <- NA_real_
    }
    plot <- plot_residuals(fit, type = type)
    expect_silent(actual <- facet_reference_trends(plot, facet))
    labels <- levels(plot$data[[facet]])
    expect_false(any(actual$facet %in% labels[1:2]))
    expect_setequal(unique(actual$facet), labels[-c(1, 2)])
    # Fully observed facets keep the exact same loess curves after other facets
    # lose observations, rather than switching to lm or changing their spans.
    dense <- actual$facet %in% labels[5:12]
    expected_dense <- baseline_trend[baseline_trend$facet %in% labels[5:12], ]
    expect_equal(unname(as.matrix(actual[dense, ])), unname(as.matrix(expected_dense)))

    x <- if (type == "length") "year" else "length"
    for (i in c(3L, 4L)) {
      observed <- plot$data[plot$data[[facet]] == labels[i] & is.finite(plot$data$residual), ]
      data <- data.frame(x = observed[[x]], y = observed$residual)
      trend <- actual[actual$facet == labels[i], ]
      model <- if (i == 3L) stats::lm(y ~ x, data) else
        stats::loess(y ~ x, data, degree = 1, span = 5 / 6)
      expect_equal(trend$y, as.numeric(stats::predict(model, data.frame(x = trend$x))),
                   tolerance = 1e-10)
    }
    # return_data still returns the masked residual observations, not smoothed values.
    returned <- plot_residuals(fit, type = type, return_data = TRUE)
    expect_equal(returned$data, plot$data)
    expect_equal(sum(is.finite(returned$data$residual)), 8 * 12 + 1 + 3 + 6)
  }
})

test_that("entirely missing residual facets yield no smoothing errors", {
  fit <- facet_reference_fixture()
  fit$observations[,] <- NA_real_
  for (type in c("length", "year")) {
    p <- plot_residuals(fit, type = type)
    facet <- if (type == "length") "LengthGroup" else "Year"
    expect_silent(trends <- facet_reference_trends(p, facet))
    expect_equal(nrow(trends), 0L)
    expect_equal(nrow(ggplot2::ggplot_build(p)$layout$layout), 12L)
  }
})

test_that("growth references require a valid label distinct from resolved model names", {
  fit <- facet_reference_fixture()
  ref <- data.frame(Age = rep(1:15, each = 3))
  ref$Length <- 55 * (1 - exp(-.25 * (ref$Age - .01))) + sin(seq_len(nrow(ref))) / 10
  for (bad in list(NULL, character(), "", "  ", NA_character_, 1, factor("Observed"), c("A", "B")))
    expect_error(plot_compare_growth(fit, fit, ref_data = ref, ref_name = bad),
                 "ref_name must be a nonempty character string")
  for (bad in c("Baseline", "Alternative"))
    expect_error(plot_compare_growth(fit, fit, model1_name = "Baseline",
      model2_name = "Alternative", ref_data = ref, ref_name = bad),
      "ref_name must be distinct")
  expect_error(plot_compare_growth(fit, fit, ref_data = ref, ref_name = "ALSCL (1)"),
               "ref_name must be distinct")
  # An unused reference label does not break calls without reference data.
  expect_silent(plot_compare_growth(fit, fit, ref_name = NA_character_))

  p <- plot_compare_growth(fit, fit, model1_name = "Baseline", model2_name = "Alternative",
    ref_data = ref, ref_name = "Otolith measurements", nls_start = list(Linf = 55, k = .25, t0 = .01))
  panel <- if (inherits(p, "patchwork")) p[[1L]] else p
  rendered <- ggplot2::ggplot_build(panel)$data[[1L]]
  expect_equal(length(unique(rendered$group)), 3L)
  expect_equal(as.integer(table(rendered$group)), rep(39L, 3))
  expect_true(all(vapply(split(rendered$x, rendered$group), function(x) !anyDuplicated(x), logical(1))))
  expect_equal(length(unique(rendered$colour)), 3L)
  expect_equal(length(unique(rendered$linetype)), 3L)
})
