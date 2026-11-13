# Review findings F42 (F summaries on a common basis), F100 (ridge titles),
# F104 (theme validation), F107 (shared F), F103 (labels), F43 (ridge scale)
# and F127 (base R reshaping).
review_compare_fit <- function(model = "ACL", ages = 1:4, years = 2000:2004, step = 1,
                               shared = FALSE) {
  A <- length(ages); Y <- length(years); lengths <- c(10, 20, 30)
  field <- function(n) matrix(seq_len(n * Y) / 100 + .1, n, Y)
  if (shared) field <- function(n) matrix(seq_len(Y) / 100 + .1, n, Y, byrow = TRUE)
  observed <- matrix(seq_len(3L * Y) + 5, 3L, Y)
  report <- list(SSB = seq_len(Y) * 2, Rec = seq_len(Y) * 3, B = seq_len(Y) * 4,
    N = seq_len(Y) * 10, CN = seq_len(Y) * 1.5, Elog_index = log(observed),
    resid_index = matrix(0.1, 3L, Y), Linf = 60, vbk = .2, t0 = -.5,
    pla = matrix(1 / 3, 3L, A))
  if (model == "ALSCL") {
    report$FL <- field(3L)
    report$FA <- (field(A) * 2)[-A, -Y, drop = FALSE]
  } else report[["F"]] <- field(A)
  rate <- report[c("SSB", "Rec", "B", "N", "CN", if (model == "ALSCL") c("FL", "FA") else "F")]
  blocks <- lapply(rate, function(x) cbind(Estimate = as.numeric(x), "Std. Error" = .1 * as.numeric(x)))
  est_std <- do.call(rbind, blocks)
  rownames(est_std) <- rep(names(blocks), vapply(blocks, nrow, integer(1)))
  list(model_type = model, F_structure = if (shared) "year" else "group_year", year = years,
       age = ages, growth_step = step, len_mid = lengths, len_label = as.character(lengths),
       observations = observed, report = report, est_std = est_std)
}

test_that("native F summaries are unchanged and state their groups", {
  withr::local_options(list(acl.theme = NULL))
  acl <- review_compare_fit("ACL"); alscl <- review_compare_fit("ALSCL")
  for (method in c("apical", "mean")) {
    summarize <- function(x) if (method == "apical") apply(x, 2, max) else colMeans(x)
    p <- plot_compare_F_ts(acl, alscl, method = method)
    expect_identical(p$data, plot_compare_F_ts(acl, alscl, method = method, basis = "native")$data)
    expect_equal(p$data$MeanF, c(summarize(acl$report$F), summarize(alscl$report$FL)))
    expect_equal(p$data$Year, c(acl$year, alscl$year))
    expect_match(p$labels$caption, "ACL: .* across 4 ages")
    expect_match(p$labels$caption, "ALSCL: .* across 3 length bins")
    expect_match(p$labels$y, if (method == "apical") "^Apical fishing mortality rate \\(per year\\)$"
                 else "^Mean fishing mortality rate \\(per year\\)$")
  }
  expect_identical(eval(formals(plot_compare_F_ts)$basis), c("native", "age"))
})

test_that("the age basis summarizes both fits over shared ages and time steps", {
  withr::local_options(list(acl.theme = NULL))
  acl <- review_compare_fit("ACL"); alscl <- review_compare_fit("ALSCL")
  for (method in c("apical", "mean")) {
    summarize <- function(x) if (method == "apical") apply(x, 2, max) else colMeans(x)
    p <- plot_compare_F_ts(acl, alscl, method = method, basis = "age")
    # ALSCL F at age has no plus group and no last time step; ACL is cut to match.
    expect_equal(p$data$Year, rep(2000:2003, 2L))
    expect_equal(p$data$MeanF, c(summarize(acl$report$F[1:3, 1:4]), summarize(alscl$report$FA)))
    expect_identical(as.character(p$data$Model), rep(c("ACL", "ALSCL"), each = 4L))
    expect_match(p$labels$caption, "Both fits: .* across 3 ages \\(1 to 3\\), in the 4 time steps")
  }
  # Two ACL fits keep the plus group, which means the same fish in both.
  same <- plot_compare_F_ts(acl, acl, model2_name = "Other", method = "mean", basis = "age")
  expect_equal(same$data$MeanF, rep(colMeans(acl$report$F), 2L))
  expect_match(same$labels$caption, "4 ages \\(1 to 4\\+\\)")
  # Ages are matched by value, not by row.
  older <- review_compare_fit("ACL", ages = 3:6)
  shifted <- plot_compare_F_ts(older, alscl, method = "mean", basis = "age")
  expect_equal(shifted$data$MeanF, c(older$report$F[1L, 1:4], alscl$report$FA[3L, ]))
  expect_match(shifted$labels$caption, "1 age \\(3\\)")
  # An ACL plus group at an age that is an ordinary age class in the other fit is left out.
  short <- review_compare_fit("ACL", ages = 1:2)
  cut <- plot_compare_F_ts(short, alscl, method = "mean", basis = "age")
  expect_equal(cut$data$MeanF, c(short$report$F[1L, 1:4], alscl$report$FA[1L, ]))
  # Missing ingredients are explicit errors that point to the native basis.
  no_fa <- alscl; no_fa$report$FA <- NULL
  expect_error(plot_compare_F_ts(acl, no_fa, basis = "age"), "report\\$FA.*basis = \"native\"")
  no_age <- acl; no_age$age <- NULL
  expect_error(plot_compare_F_ts(no_age, alscl, basis = "age"), "no age metadata")
  disjoint <- review_compare_fit("ACL", ages = 10:12)
  expect_error(plot_compare_F_ts(disjoint, alscl, basis = "age"), "share 0 age")
  # Fits with different time steps cannot share a rate basis in the label.
  quarterly <- review_compare_fit("ACL", years = 2000 + (0:4) / 4, step = .25)
  expect_match(plot_compare_F_ts(acl, quarterly, model2_name = "Quarterly")$labels$y, "per time step")
  expect_match(plot_compare_F_ts(quarterly, quarterly, model2_name = "Other")$labels$y, "per quarter")
})

test_that("the heatmap note no longer calls the native summary comparable", {
  withr::local_options(list(acl.theme = NULL))
  acl <- review_compare_fit("ACL"); alscl <- review_compare_fit("ALSCL")
  note <- NULL
  withCallingHandlers(plot_compare_F(acl, alscl), message = function(m) {
    note <<- conditionMessage(m); invokeRestart("muffleMessage")
  })
  expect_match(note, "not directly comparable")
  expect_match(note, "basis = \"age\"", fixed = TRUE)
  expect_false(grepl("comparable summary", note))
  expect_silent(p <- plot_compare_F(acl, acl, model2_name = "Other"))
  expect_identical(p$scales$get_scales("fill")$name, "F (per year)")
})

test_that("shared F is drawn once and the returned data keep every group", {
  withr::local_options(list(acl.theme = NULL))
  for (model in c("ACL", "ALSCL")) {
    fit <- review_compare_fit(model, shared = TRUE)
    series <- (if (model == "ACL") fit$report$F else fit$report$FL)[1L, ]
    groups <- if (model == "ACL") 4L else 3L
    for (se in c(FALSE, TRUE)) {
      out <- plot_fishing_mortality(fit, se = se, return_data = TRUE)
      built <- ggplot2::ggplot_build(out$plot)
      expect_equal(nrow(built$layout$layout), 1L)
      expect_identical(as.character(built$layout$layout[[if (model == "ACL") "AgeGroup" else "Group"]]),
                       "Shared F")
      expect_equal(built$data[[1L]]$y, series, ignore_attr = TRUE)
      expect_equal(nrow(out$data), groups * length(fit$year))
      # Layouts with one panel per time step keep the flat profile across groups.
      profile <- plot_fishing_mortality(fit, type = "age", se = se)
      expect_equal(nrow(ggplot2::ggplot_build(profile)$layout$layout),
                   length(fit$year) - (model == "ALSCL"))
    }
    # A fit that is labelled shared but reports different rows is not collapsed.
    mixed <- fit
    name <- if (model == "ACL") "F" else "FL"
    mixed$report[[name]][2L, ] <- mixed$report[[name]][2L, ] * 2
    expect_equal(nrow(ggplot2::ggplot_build(plot_fishing_mortality(mixed))$layout$layout), groups)
    separate <- review_compare_fit(model)
    expect_equal(nrow(ggplot2::ggplot_build(plot_fishing_mortality(separate))$layout$layout), groups)
  }
})

test_that("ridge plots have one figure title and keep their panel titles", {
  withr::local_options(list(acl.theme = NULL))
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  fit <- review_compare_fit("ACL")
  panel_titles <- c("Observed survey length composition over time",
                    "Fitted survey length composition over time")
  titles <- function(p) c(p[[1L]]$labels$title, p[[2L]]$labels$title)
  default <- plot_ridges(fit)
  expect_s3_class(default, "patchwork")
  expect_identical(default$patches$annotation$title, "Observed and fitted survey length compositions")
  expect_identical(titles(default), panel_titles)
  custom <- plot_ridges(fit, title = "Survey compositions, stock A")
  expect_identical(custom$patches$annotation$title, "Survey compositions, stock A")
  expect_identical(titles(custom), panel_titles)
  expect_null(plot_ridges(fit, title = "")$patches$annotation$title)
  # The ridges theme key is now read.
  acl_theme_set(titles = list(ridges = "Global ridge title", CatL_obs_length = "Seen"))
  themed <- plot_ridges(fit)
  expect_identical(themed$patches$annotation$title, "Global ridge title")
  expect_identical(titles(themed), c("Seen", panel_titles[2L]))
  expect_silent(patchwork::patchworkGrob(themed))
})

test_that("a single-bin period does not flatten automatically scaled ridges", {
  withr::local_options(list(acl.theme = NULL))
  years <- 2000:2004; lengths <- seq(10, 100, 10)
  fitted <- sapply(seq_along(years), function(j) 8 - 0.5 * ((lengths - (40 + 3 * j)) / 15)^2)
  fit <- list(model_type = "ACL", year = years, growth_step = 1, len_mid = lengths,
              len_label = as.character(lengths), observations = exp(fitted),
              report = list(Elog_index = fitted))
  peaks <- function(p, panel) {
    data <- p[[panel]]$data
    as.numeric(tapply(data$Abundance, data$year, max, na.rm = TRUE))
  }
  full <- plot_ridges(fit)
  expect_equal(max(peaks(full, 2L)), 0.8)
  sparse <- fit
  sparse$observations[-5L, 3L] <- NA_real_
  p <- plot_ridges(sparse)
  # Fitted ridges and the other observed ridges keep their heights.
  expect_equal(peaks(p, 2L), peaks(full, 2L))
  expect_equal(peaks(p, 1L)[-3L], peaks(full, 1L)[-3L])
  # The lone observed bin is drawn at the height of the tallest ridge.
  expect_equal(peaks(p, 1L)[3L], 0.8)
  points <- ggplot2::ggplot_build(p[[1L]])$data[[2L]]
  expect_equal(points$x, 50)
  expect_equal(points$y, 3.8)
  # An explicit scale is applied as given.
  fixed <- plot_ridges(sparse, ridges_scale = 2)
  expect_equal(peaks(fixed, 1L)[3L], 2)
})

test_that("theme settings that no plot can use are reported", {
  withr::local_options(list(acl.theme = NULL))
  before <- acl_theme()
  expect_error(acl_theme_set(base_theme = "theme_economist"), "not a supported theme name")
  expect_error(acl_theme_set(base_theme = "theme_mnimal"), "bw, minimal, classic")
  expect_error(acl_theme_set(base_theme = ggplot2::theme_minimal()), "not a supported theme name")
  expect_error(acl_theme_set(compare_colors = "red"), "compare_colors must contain two values")
  expect_error(acl_theme_set(compare_linetypes = "dotted"), "compare_linetypes must contain two values")
  expect_identical(acl_theme(), before)
  for (name in c("bw", "theme_minimal", "classic", "void")) expect_silent(acl_theme_set(base_theme = name))
  options(acl.theme = NULL)

  fit <- review_compare_fit("ACL"); other <- review_compare_fit("ALSCL")
  acl_theme_set(compare_colors = c("steelblue", "tomato"))
  # One colour cannot describe two models: warn and keep the active colours.
  expect_warning(p <- plot_compare_ts(fit, other, quantities = "SSB", colors = "red"),
                 "colors must contain two values.*global compare_colors")
  expect_identical(unique(ggplot2::ggplot_build(p)$data[[1L]]$colour), c("steelblue", "tomato"))
  expect_warning(plot_compare_ts(fit, other, quantities = "SSB", linetypes = "dotted"),
                 "linetypes must contain two values")
  # A broken global value set through options() falls back to the defaults with a warning.
  options(acl.theme = list(compare_colors = "red"))
  expect_warning(p <- plot_compare_ts(fit, other, quantities = "SSB"), "package defaults")
  expect_identical(unique(ggplot2::ggplot_build(p)$data[[1L]]$colour),
                   unname(ALSCL:::.acl_defaults$compare_colors))
  options(acl.theme = NULL)

  # An unknown theme name in a call warns and uses the active theme.
  acl_theme_set(base_theme = "theme_classic")
  expect_warning(p <- plot_SSB(fit, base_theme = "theme_mnimal"), "not a supported theme name; using \"theme_classic\"")
  classic <- plot_SSB(fit)
  expect_equal(ggplot2::ggplot_build(p)$plot$theme, ggplot2::ggplot_build(classic)$plot$theme)
  expect_silent(plot_SSB(fit, base_theme = "minimal"))
})

test_that("acl_theme_reset reports with a message that can be suppressed", {
  withr::local_options(list(acl.theme = NULL))
  acl_theme_set(line_size = 3)
  expect_message(acl_theme_reset(), "reset to defaults")
  expect_equal(acl_theme("line_size"), 1.5)
  expect_silent(suppressMessages(acl_theme_reset()))
  expect_identical(capture.output(result <- suppressMessages(acl_theme_reset())), character())
  expect_null(result)
})

test_that("default labels spell out terms and state the time basis of rates", {
  withr::local_options(list(acl.theme = NULL))
  annual <- review_compare_fit("ACL")
  quarterly <- review_compare_fit("ACL", years = 2000 + (0:4) / 4, step = .25)
  monthly <- review_compare_fit("ACL", years = 2000 + (0:4) / 10, step = .1)
  expect_identical(plot_fishing_mortality(annual)$labels$y, "Fishing mortality rate (per year)")
  expect_identical(plot_fishing_mortality(quarterly)$labels$y, "Fishing mortality rate (per quarter)")
  expect_identical(plot_fishing_mortality(monthly)$labels$y, "Fishing mortality rate (per time step)")
  legacy <- annual; legacy$growth_step <- NULL
  expect_identical(plot_fishing_mortality(legacy)$labels$y, "Fishing mortality rate (per year)")
  expect_identical(ALSCL:::.acl_rate_basis(list()), "per time step")
  expect_identical(ALSCL:::.acl_rate_basis(list(growth_step = 0.5)), "per half year")
  # A customized label is used verbatim.
  acl_theme_set(ylab = list(F = "F"))
  expect_identical(plot_fishing_mortality(quarterly)$labels$y, "F")
  options(acl.theme = NULL)
  expect_identical(plot_SSB(annual)$labels$y, "Spawning stock biomass (SSB)")
  expect_identical(plot_SSB_Rec(annual)$labels$x, "Spawning stock biomass (SSB)")
  expect_identical(plot_VB(annual)$labels$x, "Age (years)")
  expect_identical(plot_residuals(annual)$labels$y, "Log residual")
  expect_identical(plot_compare_ts(annual, quarterly, model2_name = "Quarterly")$labels$y, "Estimate")
  label <- ggplot2::ggplot_build(plot_VB(annual))$data[[2L]]$label
  expect_identical(label, "  Linf = 60\n  k = 0.2 per year")
  expect_equal(ggplot2::ggplot_build(plot_VB(annual))$data[[2L]]$hjust, 0)
})

test_that("the survey index caption follows the line styles in use", {
  withr::local_options(list(acl.theme = NULL))
  fit <- review_compare_fit("ACL")
  caption <- function(...) plot_CatL(fit, facet_by = "year", ...)$labels$caption
  expect_identical(caption(), "Thicker line: fitted; thinner line: observed")
  expect_identical(caption(line_size1 = 1, line_size2 = 3), "Thinner line: fitted; thicker line: observed")
  expect_identical(caption(line_size1 = 1, line_size2 = 1),
                   "Opaque line: fitted; more transparent line: observed")
  expect_identical(caption(line_size1 = 1, line_size2 = 1, line_alpha1 = .3, line_alpha2 = 1),
                   "More transparent line: fitted; opaque line: observed")
  expect_null(caption(line_size1 = 1, line_size2 = 1, line_alpha2 = 1))
  expect_null(plot_CatL(fit)$labels$caption)
})

test_that("matrices are reshaped as reshape2::melt did", {
  x <- matrix(c(1.5, 2, 3, 4, 5, 6), 2L, 3L)
  long <- ALSCL:::.acl_matrix_long(x, c("Group", "Period", "Value"))
  expect_identical(long, data.frame(Group = rep(1:2, 3L), Period = rep(1:3, each = 2L),
                                    Value = as.numeric(x)))
  expect_identical(names(ALSCL:::.acl_matrix_long(x)), c("Var1", "Var2", "value"))
  skip_if_not_installed("reshape2")
  expect_identical(ALSCL:::.acl_matrix_long(x), reshape2::melt(x))
})
