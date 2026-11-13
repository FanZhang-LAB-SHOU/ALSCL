plot_semantics_fixture_229 <- function() {
  deviations <- matrix(seq_len(45) / 100, 15L, 3L)
  list(model_type = "ACL", F_structure = "group_year", year = 2000:2002,
    len_mid = c(10, 20, 30), len_label = c("5-15", "15-25", "25-35"),
    observations = matrix(c(1, 2, 3, NA, 0, NA, 4, 8, 12), 3L, 3L),
    report = list(F = matrix(.2, 15L, 3L), dev_log_F = deviations,
      pla = matrix(1 / 3, 3L, 15L), Elog_index = matrix(log(1:9), 3L, 3L)),
    est_std = matrix(c(as.numeric(deviations), rep(.05, 45)), 45L, 2L,
      dimnames = list(rep("dev_log_F", 45), c("Estimate", "Std. Error"))))
}

test_that("ACL deviation facets retain numeric age order with and without intervals", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- plot_semantics_fixture_229()
  for (se in c(FALSE, TRUE)) {
    p <- plot_deviance(fit, type = "F", se = se)
    built <- ggplot2::ggplot_build(p)
    expect_equal(as.character(built$layout$layout$Group), paste("Age bin", 1:15))
    expect_equal(p$data$estimate, as.numeric(fit$report$dev_log_F))
    expect_equal(p$data$Year, rep(fit$year, each = 15L))
  }
  acl_theme_set(line_size = 3)
  expect_equal(unique(ggplot2::ggplot_build(plot_deviance(fit, type = "F"))$data[[1]]$linewidth), 3)
  expect_equal(unique(ggplot2::ggplot_build(plot_deviance(fit, type = "F", line_size = .7))$data[[1]]$linewidth), .7)
})

test_that("PLA age breaks change labels without dropping heatmap cells", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- plot_semantics_fixture_229()
  baseline <- ggplot2::ggplot_build(plot_pla(fit))
  chosen <- ggplot2::ggplot_build(plot_pla(fit, x_breaks = c(1, 5, 10, 15)))
  expect_equal(chosen$layout$panel_params[[1]]$x$get_labels(), paste("Age bin", c(1, 5, 10, 15)))
  expect_equal(chosen$data[[1]], baseline$data[[1]])
  expect_equal(nrow(chosen$data[[1]]), length(fit$report$pla))
  acl_theme_set(x_breaks = c(1, 5, 15))
  global <- ggplot2::ggplot_build(plot_pla(fit))
  expect_equal(global$layout$panel_params[[1]]$x$get_labels(), paste("Age bin", c(1, 5, 15)))
  explicit <- ggplot2::ggplot_build(plot_pla(fit, x_breaks = c(2, 4)))
  expect_equal(explicit$layout$panel_params[[1]]$x$get_labels(), paste("Age bin", c(2, 4)))
  for (bad in list(NA_real_, Inf, .5, 0, 16, c(1, 1), "1"))
    expect_error(plot_pla(fit, x_breaks = bad), "integer age-bin positions")
})

test_that("survey plot labels identify the data scale and honor user settings", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- plot_semantics_fixture_229()
  for (type in c("year", "length")) {
    log_plot <- plot_CatL(fit, facet_by = type, return_data = TRUE)
    raw_plot <- plot_CatL(fit, facet_by = type, exp_transform = TRUE, return_data = TRUE)
    expect_equal(log_plot$plot$labels$y, "Log survey index")
    expect_equal(raw_plot$plot$labels$y, "Survey index")
    field <- if (type == "year") "Abundance" else "Count"
    expect_equal(raw_plot$data1[[field]], exp(log_plot$data1[[field]]))
    expect_equal(raw_plot$data2[[field]], exp(log_plot$data2[[field]]))
    for (exp_transform in c(FALSE, TRUE)) {
      p <- plot_CatL(fit, facet_by = type, exp_transform = exp_transform, ylab = "My units")
      expect_equal(p$labels$y, "My units")
    }
  }
  acl_theme_set(ylab = list(abundance = "Index (numbers)"))
  expect_equal(plot_CatL(fit)$labels$y, "Log Index (numbers)")
  expect_equal(plot_CatL(fit, exp_transform = TRUE)$labels$y, "Index (numbers)")
  acl_theme_set(line_size = 3)
  expect_equal(unique(ggplot2::ggplot_build(plot_CatL(fit))$data[[2]]$linewidth), 3)
  expect_equal(unique(ggplot2::ggplot_build(plot_CatL(fit, line_size = .8))$data[[2]]$linewidth), .8)
  yearly <- ggplot2::ggplot_build(plot_CatL(fit, facet_by = "year"))
  expect_equal(unique(yearly$data[[1]]$linewidth), 2)
  expect_equal(unique(yearly$data[[2]]$linewidth), 3.6)
  yearly <- ggplot2::ggplot_build(plot_CatL(fit, facet_by = "year", line_size1 = .9, line_size2 = .4))
  expect_equal(unique(yearly$data[[1]]$linewidth), .4)
  expect_equal(unique(yearly$data[[2]]$linewidth), .9)
})

test_that("ridge compositions remain normalized under extreme finite log offsets", {
  old <- options(acl.theme = NULL); on.exit(options(old), add = TRUE)
  fit <- plot_semantics_fixture_229()
  fit$report$Elog_index <- matrix(rep(c(0, -1, -2), 3), 3L, 3L)
  baseline <- plot_ridges(fit, ridges_scale = 1)
  fit$report$Elog_index <- sweep(fit$report$Elog_index, 2L, c(1000, -1000, 0), "+")
  actual <- plot_ridges(fit, ridges_scale = 1)
  expect_equal(actual[[2]]$data, baseline[[2]]$data)
  expect_true(all(is.finite(actual[[2]]$data$Abundance)))
  expect_equal(as.numeric(tapply(actual[[2]]$data$Abundance, actual[[2]]$data$year, sum)), rep(1, 3))
  expect_true(all(is.na(actual[[1]]$data$Abundance[actual[[1]]$data$year == "2001"])))
  # Large original-scale observations must not overflow their column sum.
  fit$observations[, 1] <- 1e308
  actual <- plot_ridges(fit, ridges_scale = 1)
  expect_equal(actual[[1]]$data$Abundance[actual[[1]]$data$year == "2000"], rep(1 / 3, 3))
  fit$observations[,] <- NA_real_
  actual <- plot_ridges(fit)
  expect_true(all(is.na(actual[[1]]$data$Abundance)))
  expect_true(all(is.finite(actual[[2]]$data$Abundance)))
  for (bad in c(NA_real_, NaN, Inf, -Inf)) {
    fit$report$Elog_index[1] <- bad
    expect_error(plot_ridges(fit), "Predicted log abundance must contain finite values")
  }
})
