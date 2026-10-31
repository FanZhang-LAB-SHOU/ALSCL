science_residual_fixture <- function() {
  z <- rbind(c(1, 2, NA, 4, 5, 6), c(2, 2, 2, 2, 2, 2))
  observed <- exp(z * .5)
  observed[1, 3] <- 0
  structure(list(observations = observed, year = 2000 + (0:5) * .25,
    len_mid = c(10, 20), len_label = c("5-15", "15-25"), growth_step = .25,
    report = list(Elog_index = matrix(0, 2, 6), std_index = .5)),
    class = c("alscl_fit", "list"))
}

test_that("conditional residuals use saved observations, fitted log index and observation SD", {
  f <- science_residual_fixture()
  out <- residuals.alscl_fit(f, type = "standardized")
  expect_equal(out$residual, as.vector(rbind(c(1, 2, NA, 4, 5, 6), rep(2, 6))))
  expect_equal(out$observed, as.vector(f$observations))
  expect_false(out$included[5])
  expect_equal(residuals.alscl_fit(f)$residual, out$residual * .5)
  f$report$sigma_index <- f$report$std_index
  f$report$std_index <- NULL
  expect_equal(residuals.alscl_fit(f, "standardized"), out)
  f$obj <- list(env = list(.data = list(logN_at_len = matrix(999, 2, 6))))
  expect_equal(residuals.alscl_fit(f, "standardized"), out)
  f$obj <- NULL
  expect_equal(residuals.alscl_fit(f, "standardized"), out)
  f$report$sigma_index <- 0
  expect_error(residuals.alscl_fit(f, "standardized"), "positive fitted observation SD")
  expect_true(all(is.na(residuals.alscl_fit(f)$sd_log)))
  expect_error(residuals.alscl_fit(f, extra = TRUE), "Unused")
  f$report$Elog_index[1, 1] <- Inf
  expect_error(residuals.alscl_fit(f), "finite at observed")
})

test_that("lag correlations preserve missing periods and report sparse or constant support", {
  f <- science_residual_fixture()
  checks <- check_fit(f, max_lag = 2)
  first <- checks$lag_correlations[checks$lag_correlations$length == 10, ]
  expect_equal(first$n_pairs, c(3L, 2L))
  expect_equal(first$correlation[1], 1)
  expect_equal(first$status, c("ok", "insufficient_pairs"))
  second <- checks$lag_correlations[checks$lag_correlations$length == 20, ]
  expect_true(all(second$status == "constant_pairs"))
  expect_true(all(is.na(second$correlation)))
  expect_equal(first$elapsed_time, c(.25, .5))
  # Removing an entirely missing period must not turn lag two into lag one.
  f$year <- f$year[-3]
  f$observations <- f$observations[, -3]
  f$report$Elog_index <- f$report$Elog_index[, -3]
  gap <- check_fit(f, 2)$lag_correlations
  expect_equal(gap[gap$length == 10, ], first)
  f$year[3] <- f$year[3] + .02
  expect_error(check_fit(f), "time-step grid")
  expect_error(check_fit(science_residual_fixture(), 1.5), "integer")
})

test_that("residual check plots retain grid-free global styles and empty support", {
  old <- acl_theme()
  on.exit(do.call(acl_theme_set, old), add = TRUE)
  acl_theme_set(font_family = "serif", base_theme = "theme_minimal", point_color = "purple")
  checks <- check_fit(science_residual_fixture(), 3)
  for (p in checks$plots) {
    expect_no_warning(ggplot2::ggplot_build(p))
    expect_s3_class(p$theme$panel.grid.major, "element_blank")
    expect_s3_class(p$theme$panel.grid.minor, "element_blank")
    expect_equal(p$theme$text$family, "serif")
  }
  expect_equal(length(unique(ggplot2::ggplot_build(checks$plots$lag)$layout$layout$length_label)), 2L)
  f <- science_residual_fixture(); f$observations[,] <- NA_real_
  empty <- check_fit(f, 1)
  expect_equal(nrow(empty$qq_data), 0L)
  expect_true(all(empty$lag_correlations$n_pairs == 0))
  for (p in empty$plots) expect_no_warning(ggplot2::ggplot_build(p))
})

test_that("residual-lag facets retain physical length order for multiple uneven bins", {
  f <- science_residual_fixture()
  f$len_mid <- c(6, 8, 10, 12, 16, 21, 28, 37, 49, 65, 86)
  f$len_label <- c("6", "8", "10", "12", "14-18", "18-24", "24-32",
    "32-42", "42-56", "56-74", ">74")
  f$observations <- exp(matrix(seq_len(length(f$len_mid) * 6) / 100,
    length(f$len_mid), 6))
  f$observations[5L, ] <- NA_real_
  f$report$Elog_index <- matrix(0, length(f$len_mid), 6)
  result <- check_fit(f, 2)
  layout <- ggplot2::ggplot_build(result$plots$lag)$layout$layout
  expect_identical(as.character(layout$length_label[order(as.integer(layout$PANEL))]),
    f$len_label)
  expect_identical(levels(result$plots$heatmap$data$length_label), f$len_label)
  expect_type(result$lag_correlations$length_label, "character")
  expect_identical(unique(result$lag_correlations$length_label), f$len_label)
  expect_s3_class(result$plots$lag$theme$panel.grid.major, "element_blank")
  expect_s3_class(result$plots$lag$theme$panel.grid.minor, "element_blank")
})

science_projection_fixture <- function(model = "ACL", A = 3L) {
  pla <- matrix(rep(c(.25, .75), A), 2, A)
  report <- list(pla = pla)
  if (model == "ACL") {
    report[["NA"]] <- matrix(seq_len(A) * 10, A, 1)
    report$F <- matrix(seq_len(A) / 10, A, 1)
  } else {
    report$NLA <- array(seq_len(2 * A) * 10, c(2, A, 1))
    report$G <- matrix(c(.5, .5, 0, 1), 2, 2)
    report$FL <- matrix(c(.1, .3), 2, 1)
  }
  structure(list(report = report, model_type = model, len_mid = c(10, 20),
    len_label = c("5-15", "15-25"), age = seq_len(A) * .25,
    year = 2020.75, growth_step = .25, recipe = list(args = list(M = .2))),
    class = c("alscl_fit", "list"))
}

test_that("ACL projections follow source-period mortality and retain the plus group", {
  f <- science_projection_fixture()
  p <- project_model(f, F = c(0, .4), recruitment = c(5, 7),
    weight = matrix(2, 2, 2), maturity = matrix(.5, 2, 2), M = .6)
  first <- c(5, 10 * exp(-.3), 20 * exp(-.4) + 30 * exp(-.5))
  second <- c(7, first[1] * exp(-.6), sum(first[2:3]) * exp(-.6))
  expect_equal(unname(p$states[["NA"]]), cbind(first, second), ignore_attr = TRUE)
  expect_equal(p$year, c(2021, 2021.25))
  expect_equal(p$summary$N, c(sum(first), sum(second)))
  expect_equal(p$summary$B, p$summary$N * 2)
  expect_equal(p$summary$SSB, p$summary$N)
  expect_equal(p$summary$CN[1], 0)
  expect_equal(p$summary$CN[2], sum(second) * .4 * (1 - exp(-1)))
  expect_equal(p$summary$CB, p$summary$CN * 2)
  expect_equal(p$assumptions$terminal_M, .2)
  expect_equal(p$assumptions$uncertainty, "none")
  expect_equal(p$summary$F_mean, c(0, .4))
  expect_equal(p$summary$F_apical, c(0, .4))
  expect_equal(p$trajectories$value[p$trajectories$quantity == "SSB"], p$summary$SSB)
  # Future F changes catches immediately, population only in the next period.
  alt <- project_model(f, F = c(.8, .4), recruitment = c(5, 7),
    weight = matrix(2, 2, 2), maturity = matrix(.5, 2, 2), M = .6)
  expect_equal(alt$summary$SSB[1], p$summary$SSB[1])
  expect_lt(alt$summary$SSB[2], p$summary$SSB[2])
})

test_that("ALSCL projections survive before growth and conserve plus-group survivors", {
  f <- science_projection_fixture("ALSCL")
  p <- project_model(f, F = matrix(c(0, .1, .2, .3), 2, 2), recruitment = c(5, 7),
    weight = matrix(c(1, 2), 2, 2), maturity = matrix(.5, 2, 2))
  original <- f$report$NLA[, , 1]
  survived <- original * exp(-c(.3, .5))
  expected <- cbind(c(.25, .75) * 5, f$report$G %*% survived[, 1],
    f$report$G %*% rowSums(survived[, 2:3]))
  expect_equal(unname(p$states$NLA[, , 1]), expected, ignore_attr = TRUE)
  expect_equal(p$summary$N[1], sum(survived) + 5)
  expect_equal(unname(p$states[["NA"]]), apply(p$states$NLA, c(2, 3), sum), ignore_attr = TRUE)
  expect_equal(unname(p$states$NL), apply(p$states$NLA, c(1, 3), sum), ignore_attr = TRUE)
  expect_equal(p$summary$CN, colSums(p$catch$CNL), ignore_attr = TRUE)
  expect_equal(p$summary$CN, colSums(p$catch$CNA), ignore_attr = TRUE)
  expect_equal(p$summary$CB, colSums(p$catch$CNL * matrix(c(1, 2), 2, 2)), ignore_attr = TRUE)
  for (model in c("ACL", "ALSCL")) {
    two <- science_projection_fixture(model, A = 2L)
    zero <- project_model(two, 0, 0, matrix(1, 2, 1), matrix(1, 2, 1), M = 0)
    expect_equal(zero$summary$CN, 0)
    expect_equal(zero$summary$Rec, 0)
    expect_equal(sum(zero$states[["NA"]][1, ]), 0)
    expect_true(all(is.finite(zero$summary$SSB)))
  }
})

test_that("projection input dimensions, coordinate labels and portable M are explicit", {
  f <- science_projection_fixture()
  run <- function(x = f, F = c(.1, .2), rec = c(5, 7), w = matrix(1, 2, 2),
      mat = matrix(.5, 2, 2), M = NULL) project_model(x, F, rec, w, mat, M)
  f$obj <- NULL
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(f, path)
  expect_equal(run()$summary, run(readRDS(path))$summary)
  legacy <- f; legacy$recipe <- NULL
  expect_error(run(legacy), "supply M explicitly")
  expect_equal(run(legacy, M = .2)$summary, run()$summary)
  expect_error(run(F = .1), "F must")
  expect_error(run(F = c(.1, -1)), "F must")
  expect_error(run(rec = c(5, NA)), "recruitment")
  expect_error(run(w = matrix(1, 1, 2)), "weight must")
  expect_error(run(mat = matrix(1.1, 2, 2)), "maturity must")
  expect_error(run(M = c(.2, .3, .4)), "M must")
  named <- matrix(1, 2, 2, dimnames = list(f$len_label, c("2021", "2021.25")))
  expect_equal(run(w = named)$summary, run()$summary)
  rownames(named) <- rev(rownames(named))
  expect_error(run(w = named), "row names")
  rownames(named) <- f$len_label; colnames(named) <- c("2021", "2022")
  expect_error(run(w = named), "column names")
  corrupt <- f; corrupt$report$pla[1, 1] <- 1
  expect_error(run(corrupt), "sum to one")
})

test_that("conditional projection reproduces later C++ states for both models", {
  for (model in c("ACL", "ALSCL")) {
    fixture <- cpp_fixture(model)
    params <- fixture$parameters
    params$dev_log_R <- c(-.2, .1, .3, -.1)
    params$dev_log_F[] <- seq(-.1, .2, length.out = length(params$dev_log_F))
    obj <- TMB::MakeADFun(fixture$data, params, DLL = fixture$info$dll_name, silent = TRUE)
    report <- obj$report(obj$par)
    d <- fixture$data
    Fname <- if (model == "ACL") "F" else "FL"
    prefix <- report
    prefix[[Fname]] <- report[[Fname]][, 1:2, drop = FALSE]
    prefix[["NA"]] <- report[["NA"]][, 1:2, drop = FALSE]
    if (model == "ALSCL") prefix$NLA <- report$NLA[, , 1:2, drop = FALSE]
    fit <- list(model_type = model, report = prefix, year = c(2020, 2020.25),
      age = d$age, len_mid = d$len_mid, growth_step = .25,
      len_label = as.character(d$len_mid), recipe = list(args = list(M = d$M)))
    projection <- project_model(fit, report[[Fname]][, 3:4, drop = FALSE], report$Rec[3:4],
      d$weight[, 3:4, drop = FALSE], d$mat[, 3:4, drop = FALSE])
    expect_equal(unname(projection$states[["NA"]]), report[["NA"]][, 3:4], tolerance = 1e-12)
    expect_equal(unname(projection$states$NL), report$NL[, 3:4], tolerance = 1e-12)
    expect_equal(projection$summary$B, as.numeric(report$B[3:4]), tolerance = 1e-12)
    expect_equal(projection$summary$SSB, as.numeric(report$SSB[3:4]), tolerance = 1e-12)
    expect_equal(projection$summary$CN, as.numeric(report$CN[3:4]), tolerance = 1e-12)
    if (model == "ALSCL") {
      expect_equal(unname(projection$states$NLA), report$NLA[, , 3:4], tolerance = 1e-12)
      expect_equal(projection$summary$CB, as.numeric(report$CB[3:4]), tolerance = 1e-12)
    }
  }
})
