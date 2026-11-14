whiting_data <- function() {
  e <- new.env(parent = emptyenv())
  utils::data("whiting_example", package = "ALSCL", envir = e)
  e$whiting_example
}

test_that("the bundled whiting example has aligned positive survey input", {
  x <- whiting_data()
  expect_named(x, c("data.CatL", "data.wgt", "data.mat", "fit_args", "fit_config",
                    "age_readings", "ices", "survey_coverage", "provenance"))
  expect_equal(dim(x$data.CatL), c(18L, 45L))
  expect_identical(names(x$data.CatL), c("LengthBin", as.character(1983:2026)))
  expect_identical(names(x$data.CatL), names(x$data.wgt))
  expect_identical(names(x$data.CatL), names(x$data.mat))
  expect_identical(x$data.CatL[[1]], x$data.wgt[[1]])
  expect_identical(x$data.CatL[[1]], x$data.mat[[1]])
  index <- as.matrix(x$data.CatL[-1])
  expect_true(all(is.finite(index) & index > 0))
  weight <- as.matrix(x$data.wgt[-1]); maturity <- as.matrix(x$data.mat[-1])
  expect_true(all(weight > 0) && all(diff(weight[, 1]) > 0))
  expect_true(all(maturity >= 0 & maturity <= 1) && all(diff(maturity[, 1]) > 0))
  # one weight curve and one maturity curve for all years, as documented
  expect_true(all(weight == weight[, 1]) && all(maturity == maturity[, 1]))
  expect_equal(weight[, 1], 0.00440 * x$fit_args$len_mid^3.183 / 1000, tolerance = 0.01,
               ignore_attr = TRUE)
})

test_that("the settings of the whiting example are those of the documented fit", {
  x <- whiting_data()
  a <- x$fit_args
  expect_identical(a[c("rec.age", "nage", "M", "sel_L50", "sel_L95", "growth_step")],
                   list(rec.age = 1, nage = 10, M = 0.5, sel_L50 = 10, sel_L95 = 14, growth_step = 1))
  expect_equal(a$len_mid, as.numeric(x$data.CatL$LengthBin))
  expect_equal(a$len_mid, seq(9, 43, 2))
  expect_equal(a$len_border, seq(10, 42, 2))
  expect_named(x$fit_config, c("acl", "alscl"))
  expect_identical(x$fit_config$alscl$t0_lower, -2)
  expect_null(x$fit_config$acl$t0_lower)
  for (model in c("acl", "alscl")) {
    map <- x$fit_config[[model]]$map
    released <- if (model == "acl") "t0" else "log_t0"
    expect_true(released %in% names(map) && is.null(map[[released]]))
    expect_true(is.factor(map$log_cv_len) && is.na(map$log_cv_len))
    expect_equal(exp(x$fit_config[[model]]$parameters$log_cv_len), 0.15)
  }
  # t0 of ALSCL starts where the recruits have a mean length of 16.9 cm
  p <- x$fit_config$alscl$parameters
  t0 <- x$fit_config$alscl$t0_lower + exp(p$log_t0)
  expect_equal(exp(p$log_Linf) * (1 - exp(-exp(p$log_vbk) * (1 - t0))), 16.9)
})

test_that("the data checks accept the whiting example for both models", {
  x <- whiting_data()
  expect_silent(do.call(ALSCL:::.acl_prepare_data,
    c(x[c("data.CatL", "data.wgt", "data.mat")], x$fit_args)))
  free <- c(acl = 10L, alscl = 13L)
  for (model in names(free)) {
    check <- check_alscl_data(x, model)
    expect_true(check$valid)
    expect_length(check$errors, 0L)
    expect_length(check$warnings, 0L)
    expect_identical(check$summary$length_bins, 18L)
    expect_identical(check$summary$time_steps, 44L)
    expect_identical(check$summary$positive, 792L)
    expect_identical(check$summary$free_fixed, free[[model]])
    plan <- inspect_parameters(x, model)
    t0 <- if (model == "acl") "t0" else "log_t0"
    expect_identical(plan$status[plan$parameter == t0], "free")
    expect_identical(plan$status[plan$parameter == "log_cv_len"], "fixed")
    expect_identical(plan$map_source[plan$parameter == "log_cv_len"], "explicit")
  }
  # t0 of ALSCL can be negative: its upper limit is the recruitment age
  plan <- inspect_parameters(x, "alscl")
  expect_equal(plan$upper[plan$parameter == "log_t0"], log(3), tolerance = 1e-5)
  expect_equal(plan$natural_start[plan$parameter == "log_t0"],
               -2 + exp(x$fit_config$alscl$parameters$log_t0))
})

test_that("a shortened whiting series is a valid input", {
  x <- whiting_data()
  for (tab in c("data.CatL", "data.wgt", "data.mat")) x[[tab]] <- x[[tab]][, 1:21]
  check <- check_alscl_data(x, "alscl")
  expect_true(check$valid)
  expect_identical(check$summary$time_steps, 20L)
})

test_that("the check tables of the whiting example are complete and consistent", {
  x <- whiting_data()
  years <- 1983:2026
  la <- x$age_readings$length_at_age
  expect_named(la, c("period", "age", "mean_length", "sd_length", "years", "n_aged"))
  all_years <- la[la$period == "1983-2026", ]
  expect_identical(all_years$age, 1:10)
  expect_true(all(diff(all_years$mean_length[1:8]) > 0))
  expect_setequal(la$period, c("1983-2026", "1980s", "1990s", "2000s", "2010s", "2020s"))
  expect_true(all(la$sd_length > 0 & la$years >= 1 & la$n_aged >= 5))
  ia <- x$age_readings$index_at_age
  expect_identical(dim(ia), c(44L, 10L))
  expect_identical(rownames(ia), as.character(years))
  expect_true(all(is.finite(ia) & ia >= 0) && all(ia[, 1:5] > 0))
  # the index at age splits the index at length among ages: its total over the
  # ages kept (1 to 10) is at most the index, and nearly all of it
  share <- rowSums(ia) / colSums(as.matrix(x$data.CatL[-1]))
  expect_true(all(share <= 1 + 1e-8 & share > 0.99))

  expect_identical(dim(x$ices$M), c(6L, 40L))
  expect_identical(rownames(x$ices$M), c(1:5, "6+"))
  expect_identical(colnames(x$ices$M), as.character(1983:2022))
  expect_true(all(x$ices$M > 0.2 & x$ices$M < 2))
  expect_identical(dim(x$ices$maturity), c(6L, 31L))
  expect_true(all(x$ices$maturity >= 0 & x$ices$maturity <= 1))
  expect_named(x$ices$assessment, c("year", "ssb", "recruitment_age0", "f_ages_2_5", "catch"))
  expect_identical(x$ices$assessment$year, 1982:2026)
  expect_true(all(x$ices$assessment$ssb > 0))

  cover <- x$survey_coverage
  expect_identical(cover$year, years)
  expect_true(all(cover$hauls_with_whiting <= cover$hauls))
  expect_identical(cover$hauls_missing[cover$year == 2009], 63L)
  expect_identical(cover$hauls_missing[cover$year == 2012], 56L)
  expect_true(all(cover$hauls_missing[!cover$year %in% c(2009, 2012)] <= 2L))

  p <- x$provenance
  expect_identical(p$years, years)
  expect_match(p$citation[["datras"]], "DATRAS", fixed = TRUE)
  expect_match(p$citation[["sag"]], "Stock Assessment Database", fixed = TRUE)
  expect_match(p$citation[["wgnssk"]], "10.17895/ices.pub.32676345", fixed = TRUE)
  expect_match(p$licence, "CC BY 4.0", fixed = TRUE)
  expect_match(p$incomplete_years, "2009", fixed = TRUE)
  expect_match(p$incomplete_years, "2012", fixed = TRUE)
  expect_true(all(c("M", "survey_catchability", "cv_len", "nage") %in% names(p$settings)))
})

test_that("the whiting example is what its source script builds", {
  script <- testthat::test_path("..", "..", "data-raw", "whiting_example.R")
  skip_if_not(file.exists(script), "data-raw is not part of the built package")
  e <- new.env()
  sys.source(script, envir = e)
  rebuilt <- e$build_whiting_example(file.path(dirname(script), "whiting_example"))
  expect_identical(rebuilt, whiting_data())
})
