# Review findings F44 (fitted ages and plus groups), F45 (global x_breaks),
# F46 (year ticks in facets), F101 (time labels) and F17 (recruitment lag).
review_axis_fit <- function(model = "ACL", ages = 1:4, years = 2000:2005, step = 1,
                            lengths = seq(10, 50, 10)) {
  A <- length(ages); Y <- length(years); L <- length(lengths)
  field <- function(n, scale = 1) matrix(seq_len(n * Y) * scale + 1, n, Y)
  observed <- field(L, 2)
  report <- list(N = seq_len(Y) * 10, SSB = seq_len(Y) * 2, Rec = seq_len(Y) * 3 + 100,
    "NA" = field(A), NL = field(L), CNA = field(A, .2), dev_log_R = seq_len(Y) / 20,
    pla = matrix(1 / L, L, A), Elog_index = log(observed) + 0.05,
    resid_index = matrix(-0.05, L, Y), Linf = 60, vbk = 0.2, t0 = -0.5)
  if (model == "ALSCL") {
    report <- c(report, list(BA = field(A, .5), SBA = field(A, .25), FL = field(L, .01),
      FA = field(A - 1L, .01)[, -Y, drop = FALSE], dev_log_F = field(L, .001),
      # Numbers by length, age and time step: the age-length key times numbers at age.
      NLA = array(vapply(seq_len(Y), function(y) sweep(matrix(1 / L, L, A), 2L, field(A)[, y], "*"),
                         matrix(0, L, A)), c(L, A, Y))))
  } else report <- c(report, list(F = field(A, .01), dev_log_F = field(A, .001)))
  blocks <- lapply(report[!names(report) %in% c("pla", "Elog_index", "resid_index", "Linf", "vbk", "t0", "NLA")],
    function(x) cbind(Estimate = as.numeric(x), "Std. Error" = 0.1 * abs(as.numeric(x))))
  est_std <- do.call(rbind, blocks)
  rownames(est_std) <- rep(names(blocks), vapply(blocks, nrow, integer(1)))
  list(model_type = model, F_structure = "group_year", year = years, age = ages,
       growth_step = step, len_mid = lengths, len_label = as.character(lengths),
       observations = observed, report = report, est_std = est_std)
}

review_axis_labels <- function(p, panel = 1L) {
  labels <- as.vector(ggplot2::ggplot_build(p)$layout$panel_params[[panel]]$x$get_labels())
  labels[!is.na(labels)]
}

test_that("age panels show fitted ages and mark the plus group", {
  withr::local_options(list(acl.theme = NULL))
  expected <- c("Age 2", "Age 3", "Age 4", "Age 5+")
  for (model in c("ACL", "ALSCL")) {
    fit <- review_axis_fit(model, ages = 2:5)
    plots <- list(plot_abundance(fit, type = "NA", return_data = TRUE)$data$AgeGroup,
                  plot_abundance(fit, type = "NA", se = TRUE, return_data = TRUE)$data$AgeGroup,
                  plot_catch(fit, type = "CNA", return_data = TRUE)$data$AgeGroup,
                  plot_pla(fit)$data$variable)
    if (model == "ALSCL") plots <- c(plots, list(
      plot_biomass(fit, type = "BA", return_data = TRUE)$data$AgeGroup,
      plot_SSB(fit, type = "SBA", se = TRUE, return_data = TRUE)$data$AgeGroup))
    else plots <- c(plots, list(
      plot_fishing_mortality(fit, return_data = TRUE)$data$AgeGroup,
      plot_fishing_mortality(fit, se = TRUE, return_data = TRUE)$data$AgeGroup,
      plot_deviance(fit, type = "F")$data$Group))
    for (groups in plots) expect_identical(levels(groups), expected)
    # Quarterly ages are labelled in years, not by position.
    quarterly <- review_axis_fit(model, ages = seq(.25, 1, .25), years = 2000 + (0:5) / 4, step = .25)
    expect_identical(levels(plot_abundance(quarterly, type = "NA", return_data = TRUE)$data$AgeGroup),
                     c("Age 0.25", "Age 0.5", "Age 0.75", "Age 1+"))
    # Results saved without age metadata keep position labels.
    legacy <- fit; legacy$age <- NULL
    expect_identical(levels(plot_abundance(legacy, type = "NA", return_data = TRUE)$data$AgeGroup),
                     paste("Age bin", 1:4))
    expect_identical(levels(plot_pla(legacy)$data$variable), paste("Age bin", 1:4))
    # Estimates do not depend on the labels.
    expect_identical(plot_abundance(legacy, type = "NA", return_data = TRUE)$data$number.age,
                     plot_abundance(fit, type = "NA", return_data = TRUE)$data$number.age)
  }
  pla <- plot_pla(review_axis_fit("ACL", ages = 2:5))
  expect_identical(review_axis_labels(pla), c("2", "3", "4", "5+"))
  expect_identical(pla$labels$x, "Age (years)")
})

test_that("F at age is plotted against fitted ages with a marked plus group", {
  withr::local_options(list(acl.theme = NULL))
  acl <- review_axis_fit("ACL", ages = c(.5, 1, 1.5, 2), years = 2000 + (0:5) / 2, step = .5)
  for (se in c(FALSE, TRUE)) {
    out <- plot_fishing_mortality(acl, type = "age", se = se, return_data = TRUE)
    expect_equal(out$data$Age, rep(acl$age, 6L))
    # The position column of earlier versions is kept.
    expect_equal(out$data$AgeGroup, rep(1:4, 6L))
    expect_equal(out$data[[if (se) "estimate" else "F"]], as.numeric(acl$report$F),
                 ignore_attr = TRUE)
    built <- ggplot2::ggplot_build(out$plot)
    expect_equal(built$data[[1L]]$x, rep(acl$age, 6L))
    expect_identical(out$plot$labels$x, "Age (years)")
    labels <- review_axis_labels(out$plot)
    expect_identical(labels[length(labels)], "2+")
    expect_false(any(grepl("+", labels[-length(labels)], fixed = TRUE)))
  }
  # ALSCL F at age has no plus-group row, so no tick is marked.
  alscl <- review_axis_fit("ALSCL", ages = 2:5)
  out <- plot_fishing_mortality(alscl, type = "age", return_data = TRUE)
  expect_equal(out$data$Age, rep(2:4, 5L))
  expect_false(any(grepl("+", review_axis_labels(out$plot), fixed = TRUE)))
  # Explicit breaks are kept and still carry the plus mark.
  chosen <- plot_fishing_mortality(acl, type = "age", x_breaks = c(1, 2))
  expect_identical(review_axis_labels(chosen), c("1", "2+"))
  # Without age metadata the coordinates are positions and the label says so.
  legacy <- acl; legacy$age <- NULL
  out <- plot_fishing_mortality(legacy, type = "age", return_data = TRUE)
  expect_false("Age" %in% names(out$data))
  expect_identical(out$plot$labels$x, "Age group")
})

test_that("comparison heatmaps use fitted ages and length midpoints", {
  withr::local_options(list(acl.theme = NULL))
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  acl <- review_axis_fit("ACL", ages = 2:5)
  alscl <- review_axis_fit("ALSCL", ages = 2:5)
  p <- plot_compare_growth(acl, alscl)
  pla <- p[[2L]]
  expect_equal(sort(unique(pla$data$Age)), 2:5)
  expect_equal(sort(unique(pla$data$Length)), acl$len_mid)
  expect_identical(pla$labels$x, "Age (years)")
  expect_identical(pla$labels$y, "Length")
  expect_equal(pla$data$Probability, rep(as.numeric(acl$report$pla), 2L))
  # The tiles cover the grid without gaps.
  expect_equal(unique(pla$data$Width), 1)
  expect_equal(unique(pla$data$Height), 10)
  expect_silent(patchwork::patchworkGrob(p))
  # Mean length at age needs the fitted ages: a result saved without age
  # metadata is an error, as in length_at_age().
  legacy <- acl; legacy$age <- NULL
  expect_error(plot_compare_growth(legacy, alscl, age_range = c(2, 5)), "model1 must contain finite age metadata")
  # ACL heatmap rows end in the plus group.
  heat <- suppressMessages(plot_compare_F(acl, alscl))
  expect_true("Age 5+" %in% levels(heat$data$Label))
  expect_false("Age 5" %in% levels(heat$data$Label))
  expect_identical(heat$labels$y, "Age class or length bin")
  expect_identical(plot_compare_F(acl, acl, model2_name = "Other")$labels$y, "Age class")
})

test_that("global year breaks leave age, length and biomass axes readable", {
  withr::local_options(list(acl.theme = NULL))
  acl <- review_axis_fit("ACL")
  alscl <- review_axis_fit("ALSCL")
  year_breaks <- c(2000, 2003, 2005)
  acl_theme_set(x_breaks = year_breaks)
  # plot_pla() used to stop on breaks that are not age positions.
  expect_no_error(pla <- plot_pla(acl))
  expect_identical(review_axis_labels(pla), c("1", "2", "3", "4+"))
  other_axes <- list(SSB_Rec = plot_SSB_Rec(acl), VB = plot_VB(acl),
    CatL_year = plot_CatL(acl, facet_by = "year"), resid_year = plot_residuals(acl, facet_by = "year"),
    F_age = plot_fishing_mortality(acl, type = "age"),
    F_length = plot_fishing_mortality(alscl, type = "length"),
    FA = plot_fishing_mortality(alscl, type = "age"))
  for (name in names(other_axes))
    expect_gt(length(review_axis_labels(other_axes[[name]])), 0L, label = name)
  # Time axes still take the global breaks.
  time_axes <- list(plot_SSB(acl), plot_recruitment(acl), plot_CatL(acl), plot_residuals(acl),
                    plot_fishing_mortality(acl), plot_deviance(acl))
  for (p in time_axes) expect_identical(review_axis_labels(p), as.character(year_breaks))
  # A call's own breaks are always used, even when none lies on the axis.
  expect_length(review_axis_labels(plot_VB(acl, x_breaks = c(100, 200))), 0L)
  # Global age breaks apply to age axes and do not blank time axes.
  acl_theme_set(x_breaks = c(1, 3))
  expect_identical(review_axis_labels(plot_fishing_mortality(acl, type = "age")), c("1", "3"))
  expect_identical(review_axis_labels(plot_pla(acl)), c("1", "3"))
  expect_gt(length(review_axis_labels(plot_SSB(acl))), 0L)
  # Explicit positions that are not age classes remain an error in plot_pla().
  expect_error(plot_pla(acl, x_breaks = c(2000, 2003)), "integer age-bin positions")
})

test_that("default faceted survey diagnostics keep year ticks apart", {
  withr::local_options(list(acl.theme = NULL))
  expect_identical(ALSCL:::.acl_facet_n_breaks(23L), 2L)
  expect_identical(ALSCL:::.acl_facet_n_breaks(23L, facet_ncol = 4), 3L)
  expect_identical(ALSCL:::.acl_facet_n_breaks(23L, facet_ncol = 1), 10L)
  expect_identical(ALSCL:::.acl_facet_n_breaks(4L, max_breaks = 8), 6L)
  fit <- review_axis_fit("ACL", years = 2000:2019, lengths = seq(6, 50, 2))
  for (p in list(plot_CatL(fit), plot_residuals(fit))) {
    built <- ggplot2::ggplot_build(p)
    expect_equal(nrow(built$layout$layout), 23L)
    for (panel in built$layout$panel_params) {
      labels <- panel$x$get_labels()
      # Ten labels per panel overprinted; two or three fit a five-column layout.
      expect_lte(sum(!is.na(labels)), 3L)
      expect_gte(sum(!is.na(labels)), 2L)
    }
    expect_true(isTRUE(p$scales$get_scales("x")$guide$params$check.overlap))
  }
  # Breaks chosen in the call are drawn as given.
  chosen <- plot_CatL(fit, x_breaks = seq(2000, 2018, 2))
  expect_identical(review_axis_labels(chosen), as.character(seq(2000, 2018, 2)))
  wide <- plot_residuals(fit, facet_ncol = 2)
  expect_gt(length(review_axis_labels(wide)), 3L)
})

test_that("quarter labels require a quarterly time step", {
  labels <- ALSCL:::.acl_time_labels
  expect_identical(labels(c(2000, 2000.25, 2000.5)), c("2000 Q1", "2000 Q2", "2000 Q3"))
  # Semiannual steps on a 0.25 grid are not quarters.
  expect_identical(labels(c(2000.25, 2000.75, 2001.25)), c("2000.25", "2000.75", "2001.25"))
  # Annual surveys recorded in the fourth quarter are not quarterly series.
  expect_identical(labels(c(2000.75, 2001.75)), c("2000.75", "2001.75"))
  # The fitted step decides when the spacing cannot.
  expect_identical(labels(2000.25, step = 0.25), "2000 Q2")
  expect_identical(labels(2000.25), "2000.25")
  expect_identical(labels(c(2000.25, 2001), step = 0.25), c("2000 Q2", "2001 Q1"))
  expect_identical(labels(c(2000.25, 2000.5), step = 0.5), c("2000.25", "2000.5"))
  expect_identical(labels(2000:2001), c("Year 2000", "Year 2001"))
  expect_identical(labels(2000:2001, prefix = FALSE), c("2000", "2001"))
  semiannual <- review_axis_fit("ACL", years = 2000.25 + (0:5) / 2, step = .5)
  expect_identical(levels(plot_CatL(semiannual, facet_by = "year", return_data = TRUE)$data1$year),
                   as.character(semiannual$year))
  expect_identical(levels(plot_fishing_mortality(semiannual, type = "age",
                                                 return_data = TRUE)$data$Period),
                   as.character(semiannual$year))
})

test_that("ridge axes label whole years and quarters", {
  withr::local_options(list(acl.theme = NULL))
  ridge_labels <- function(fit) {
    p <- plot_ridges(fit)
    lapply(list(p[[1L]], p[[2L]]), function(panel)
      ggplot2::ggplot_build(panel)$layout$panel_params[[1L]]$y$get_labels())
  }
  annual <- review_axis_fit("ACL", years = 2000:2003)
  for (labels in ridge_labels(annual)) expect_identical(labels, as.character(2000:2003))
  quarterly <- review_axis_fit("ACL", years = 2000 + (0:3) / 4, step = .25)
  for (labels in ridge_labels(quarterly))
    expect_identical(labels, c("2000 Q1", "2000 Q2", "2000 Q3", "2000 Q4"))
  semiannual <- review_axis_fit("ACL", years = 2000.25 + (0:3) / 2, step = .5)
  for (labels in ridge_labels(semiannual)) expect_identical(labels, as.character(semiannual$year))
})

test_that("SSB is paired with recruitment at the youngest fitted age", {
  fit <- list(report = list(SSB = seq_len(8L), Rec = 101:108), growth_step = .25,
              year = 2000 + (0:7) / 4, age = seq(.25, 2, .25))
  # Quarterly fit with recruitment at one quarter: a lag of one step, not four.
  quarterly <- plot_SSB_Rec(fit, return_data = TRUE)$data
  expect_equal(quarterly$SSB, 1:7)
  expect_equal(quarterly$Rec, 102:108)
  expect_identical(plot_SSB_Rec(fit, age_at_recruitment = .25, return_data = TRUE)$data, quarterly)
  # A supplied age still takes priority.
  expect_equal(plot_SSB_Rec(fit, age_at_recruitment = 1, return_data = TRUE)$data$Rec, 105:108)
  # Annual fit with recruitment at age 1: unchanged.
  annual <- list(report = fit$report, growth_step = 1, year = 2000:2007, age = 1:5)
  expect_equal(plot_SSB_Rec(annual, return_data = TRUE)$data$Rec, 102:108)
  expect_identical(plot_SSB_Rec(annual, return_data = TRUE)$data,
                   plot_SSB_Rec(annual, age_at_recruitment = 1, return_data = TRUE)$data)
  # Annual fit with recruitment at age 2: a lag of two years.
  annual$age <- 2:6
  expect_equal(plot_SSB_Rec(annual, return_data = TRUE)$data$Rec, 103:108)
  # Results without age metadata keep the lag of 1 year.
  annual$age <- NULL
  expect_equal(plot_SSB_Rec(annual, return_data = TRUE)$data$Rec, 102:108)
  # A youngest age between steps uses the nearest whole number of steps and says so.
  annual$age <- c(1.4, 2.4)
  expect_message(out <- plot_SSB_Rec(annual, return_data = TRUE), "not a whole number of time steps")
  expect_equal(out$data$Rec, 102:108)
  expect_error(plot_SSB_Rec(annual, age_at_recruitment = 1.4), "exact multiple of growth_step")
})
