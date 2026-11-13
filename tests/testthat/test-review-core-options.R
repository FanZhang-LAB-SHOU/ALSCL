# Optional parameterizations and outputs added after the review: AR(1)
# correlations between -1 and 1 (GL4), a lower limit for the ALSCL t0 (F10),
# F at age for every age and period (GQ2), the N_at_age alias (F58) and
# random numbers by process in the operating models (F81).

options_fixture <- function(model, flags = list(), logits = c(R = .4, y = -.8, g = 1.1), log_t0 = NULL) {
  f <- cpp_fixture(model, quarterly = FALSE)
  d <- c(f$data, flags); p <- f$parameters
  p$logit_log_R <- logits[["R"]]; p$logit_log_F_y <- logits[["y"]]
  p[[if (model == "ACL") "logit_log_F_a" else "logit_log_F_l"]] <- logits[["g"]]
  if (!is.null(log_t0)) p$log_t0 <- log_t0
  set.seed(3)
  p$dev_log_R[] <- rnorm(length(p$dev_log_R), 0, .3); p$dev_log_F[] <- rnorm(length(p$dev_log_F), 0, .3)
  obj <- TMB::MakeADFun(d, p, DLL = f$info$dll_name, silent = TRUE)
  list(obj = obj, report = obj$report(), parameters = p, data = d)
}

test_that("symmetric correlations use 2 * logistic - 1 and the matching AR(1) density", {
  skip_on_cran()
  for (model in c("ACL", "ALSCL")) {
    group <- if (model == "ACL") "phi_log_F_a" else "phi_log_F_l"
    positive <- options_fixture(model)
    symmetric <- options_fixture(model, list(correlation_range = 1))
    expect_equal(unlist(positive$report[c("phi_log_R", "phi_log_F_y", group)], use.names = FALSE),
                 stats::plogis(c(.4, -.8, 1.1)), tolerance = 1e-14)
    expect_equal(unlist(symmetric$report[c("phi_log_R", "phi_log_F_y", group)], use.names = FALSE),
                 2 * stats::plogis(c(.4, -.8, 1.1)) - 1, tolerance = 1e-14)
    # The same natural correlations give the same objective under either range.
    rho <- stats::plogis(c(R = .4, y = .3, g = 1.1))
    a <- options_fixture(model, logits = stats::qlogis(rho))
    b <- options_fixture(model, list(correlation_range = 1), logits = stats::qlogis((rho + 1) / 2))
    expect_equal(b$obj$fn(), a$obj$fn(), tolerance = 1e-10)
    # A negative correlation: compare the recruitment term with a direct AR(1) density.
    dev <- symmetric$parameters$dev_log_R
    for (shift in c(-1.5, 0.7)) {
      one <- options_fixture(model, list(correlation_range = 1), logits = c(R = shift, y = -.8, g = 1.1))
      two <- options_fixture(model, list(correlation_range = 1), logits = c(R = 0, y = -.8, g = 1.1))
      ar1 <- function(phi, sd) {
        n <- length(dev)
        -(stats::dnorm(dev[1], 0, sd, log = TRUE) +
          sum(stats::dnorm(dev[-1], phi * dev[-n], sd * sqrt(1 - phi^2), log = TRUE)))
      }
      sd <- exp(one$parameters[[if (model == "ACL") "log_std_log_R" else "log_sigma_log_R"]])
      # The objective is about 4e4, so its difference is known to about 1e-7.
      expect_equal(one$obj$fn() - two$obj$fn(), ar1(2 * stats::plogis(shift) - 1, sd) - ar1(0, sd), tolerance = 1e-4)
    }
  }
})

test_that("fits with symmetric correlations transform, screen and start consistently", {
  skip_on_cran()
  settings <- ALSCL:::.acl_scale_settings(list(structure = list(correlation_range = "symmetric")))
  expect_equal(ALSCL:::.acl_parameter_transform("logit_log_R", 0, settings = settings), 0)
  expect_equal(ALSCL:::.acl_parameter_transform("logit_log_R", -.4, inverse = TRUE, settings = settings),
               stats::qlogis(.3))
  expect_equal(ALSCL:::.acl_parameter_transform("logit_log_R", .5, derivative = TRUE, settings = settings),
               2 * stats::dlogis(.5))
  expect_equal(ALSCL:::.acl_parameter_transform("logit_log_R", .5), stats::plogis(.5))
  f <- fixture_frames()
  for (model in c("ACL", "ALSCL")) {
    prepared <- do.call(ALSCL:::.acl_prepare_data, c(f, list(structure = list(correlation_range = "symmetric"))))
    setup <- ALSCL:::.acl_model_setup(model, prepared)
    default <- ALSCL:::.acl_model_setup(model, do.call(ALSCL:::.acl_prepare_data, f))
    expect_identical(setup$data$correlation_range, 1L)
    # Default starts keep their natural correlation; a supplied start is used as given.
    for (nm in grep("^logit_", names(setup$parameters), value = TRUE))
      expect_equal(2 * stats::plogis(setup$parameters[[nm]]) - 1, stats::plogis(default$parameters[[nm]]),
                   tolerance = 1e-12)
    supplied <- ALSCL:::.acl_model_setup(model, prepared, parameters = list(logit_log_R = 0))
    expect_identical(supplied$parameters$logit_log_R, 0)
  }
  # A correlation of zero is a boundary under the positive range and interior under the symmetric one.
  fit <- list(opt = list(par = c(logit_log_R = stats::qlogis(1e-6), log_std_log_R = log(.5))),
              vcov = NULL, structure = list(correlation_range = "positive"),
              max_abs_gradient = 1e-8, convergence_code = 0L, pdHess = TRUE)
  expect_true(ALSCL:::.acl_fit_diagnostics(fit)$natural_boundary)
  fit$opt$par[["logit_log_R"]] <- 0; fit$structure$correlation_range <- "symmetric"
  diagnostics <- ALSCL:::.acl_fit_diagnostics(fit)
  expect_false(diagnostics$natural_boundary)
  expect_equal(diagnostics$natural_parameters$estimate[1], 0)
  fit$opt$par[["logit_log_R"]] <- -12
  expect_true(ALSCL:::.acl_fit_diagnostics(fit)$natural_boundary)
})

test_that("t0_lower shifts the ALSCL t0 and leaves the default untouched", {
  skip_on_cran()
  default <- options_fixture("ALSCL", log_t0 = log(.2))
  expect_equal(default$report$t0, .2, tolerance = 1e-14)
  shifted <- options_fixture("ALSCL", list(t0_lower = -1), log_t0 = log(1.2))
  expect_equal(shifted$report$t0, .2, tolerance = 1e-14)
  expect_equal(shifted$report$pla, default$report$pla, tolerance = 1e-12)
  expect_equal(shifted$obj$fn(), default$obj$fn(), tolerance = 1e-10)
  negative <- options_fixture("ALSCL", list(t0_lower = -1), log_t0 = log(.79))
  expect_equal(negative$report$t0, -.21, tolerance = 1e-14)
  ages <- negative$data$age
  mean_length <- negative$report$Linf * (1 - exp(-negative$report$vbk * (ages - (-.21))))
  expect_equal(colSums(negative$report$pla * negative$data$len_mid)[1] > 0, TRUE, ignore_attr = TRUE)
  expect_true(all(diff(mean_length) > 0))
  f <- fixture_frames()
  prepared <- do.call(ALSCL:::.acl_prepare_data, c(f, list(t0_lower = -1)))
  setup <- ALSCL:::.acl_model_setup("ALSCL", prepared, parameters = list(log_t0 = log(.79)))
  expect_identical(setup$data$t0_lower, -1)
  expect_equal(setup$config$parameters.U$log_t0, log(f$rec.age + 1) + log1p(-1e-6))
  expect_null(ALSCL:::.acl_model_setup("ALSCL", do.call(ALSCL:::.acl_prepare_data, f))$data$t0_lower)
  expect_error(ALSCL:::.acl_model_setup("ACL", prepared), "applies to ALSCL only")
  expect_error(ALSCL:::.acl_model_setup("ALSCL", do.call(ALSCL:::.acl_prepare_data, c(f, list(t0_lower = 2)))),
               "below the recruitment age")
  settings <- list(symmetric = FALSE, t0_lower = -1)
  expect_equal(ALSCL:::.acl_parameter_transform("log_t0", log(.79), settings = settings), -.21)
  expect_equal(ALSCL:::.acl_parameter_transform("log_t0", -.21, inverse = TRUE, settings = settings), log(.79))
  expect_equal(ALSCL:::.acl_parameter_transform("log_vbk", log(.3), settings = settings), .3)
})

test_that("ALSCL reports F at age for every age and period", {
  skip_on_cran()
  f <- options_fixture("ALSCL")
  r <- f$report; A <- f$data$A; Y <- f$data$Y
  expect_identical(dim(r$FA), c(A, Y))
  expect_identical(dim(r$ZA), c(A, Y))
  for (a in c(1L, A)) for (y in c(1L, Y)) {
    cohort <- r$NLA[, a, y]
    expect_equal(r$ZA[a, y], log(sum(cohort)) - log(sum(cohort * exp(-r$ZL[, y]))), tolerance = 1e-12)
  }
  expect_equal(r$FA, r$ZA - f$data$M, tolerance = 1e-14)
  # Survivors of the last two age classes form the next plus group.
  expect_equal(sum(r$NLA[, A, 2]), sum(r$NLA[, A - 1L, 1]) * exp(-r$ZA[A - 1L, 1]) +
                 sum(r$NLA[, A, 1]) * exp(-r$ZA[A, 1]), tolerance = 1e-10)
})

test_that("numbers at age can be requested as N_at_age", {
  skip_on_cran()
  fit <- fit_fixture("ACL")$result
  by_alias <- extract_estimates(fit, "N_at_age"); by_name <- extract_estimates(fit, "NA")
  expect_identical(by_alias$estimate, by_name$estimate)
  expect_identical(by_alias$std_error, by_name$std_error)
  expect_identical(unique(by_alias$quantity), "N_at_age")
  expect_identical(unique(by_alias$report_name), "N_at_age")
  file <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(by_alias, file, row.names = FALSE)
  expect_false(anyNA(utils::read.csv(file)$quantity))
})

test_that("random numbers by process keep the draws of unchanged processes", {
  base <- initialize_params(species = "flatfish", nyear = 30, burn_in = 20, random_numbers = "by_process")
  changed <- initialize_params(species = "flatfish", nyear = 30, burn_in = 20, random_numbers = "by_process",
                               R_ar = .6, std_logN0 = 0)
  expect_identical(base$random_numbers, "by_process")
  expect_null(initialize_params(species = "flatfish")$random_numbers)
  out <- withr::local_tempdir()
  utils::capture.output(a <- sim_data(sim_cal(base), base, output_dir = out, iter_range = 7))
  utils::capture.output(b <- sim_data(sim_cal(changed), changed, output_dir = out, iter_range = 7))
  expect_identical(a$provenance$random_numbers, "by_process")
  # F depends only on its own stream, so it is unchanged; recruitment differs.
  expect_identical(a$F_at_age, b$F_at_age)
  expect_false(identical(a$Rec, b$Rec))
  # Survey errors are the same draws: observed / expected is unchanged.
  q <- matrix(a$q_surv, nrow(a$N_at_len), ncol(a$N_at_len), byrow = TRUE)
  expect_equal(a$SN_at_len / (a$N_at_len * q), b$SN_at_len / (b$N_at_len * q), tolerance = 1e-10)
  # The default scheme is unchanged and differs from the by-process scheme.
  default <- initialize_params(species = "flatfish", nyear = 30, burn_in = 20)
  utils::capture.output(d <- sim_data(sim_cal(default), default, output_dir = out, iter_range = 7))
  expect_identical(d$provenance$random_numbers, "sequential")
  expect_false(identical(d$F_at_age, a$F_at_age))
  bad <- default; bad$random_numbers <- "paired"
  expect_error(sim_data(sim_cal(default), bad, output_dir = out, iter_range = 7), "random_numbers must be")
  # The AR(1) series is stationary with the requested correlation.
  x <- ALSCL:::.acl_simulation_normal(20000, c(11L, 12L, 13L, 14L), 1L, ar = .6)
  expect_equal(stats::cor(x[-1], x[-length(x)]), .6, tolerance = .03)
  expect_equal(stats::var(x), 1 / (1 - .6^2), tolerance = .08)
})

test_that("extrapolated F starts at the last period with a positive observation", {
  skip_on_cran()
  fit <- fit_fixture("ACL")$result
  flagged <- function(x) sort(unique(extract_estimates(x, "F")$year[extract_estimates(x, "F")$extrapolated]))
  expect_equal(flagged(fit), max(fit$year))
  trailing <- fit
  trailing$observations[, ncol(trailing$observations)] <- NA_real_
  expect_equal(flagged(trailing), utils::tail(fit$year, 2L))
  no_observations <- fit; no_observations$observations <- NULL
  expect_equal(flagged(no_observations), max(fit$year))
  expect_false(any(extract_estimates(trailing, "SSB")$extrapolated))
})

test_that("plot_retro labels quarterly terminal periods when peels remove whole years", {
  # Quarterly series whose peels end one year apart (peel_step = 4).
  times <- seq(2000, 2004.75, by = .25)
  ends <- c(2004.75, 2003.75, 2002.75)
  d <- expand.grid(Year = times, Peel = 0:2, Variable = c("B", "Rec", "SSB", "N"), stringsAsFactors = FALSE)
  d <- d[d$Year <= ends[d$Peel + 1L], ]
  d$Value <- 100 + d$Year - 2000 + d$Peel
  d$NumericalOK <- TRUE
  d$RetrospectiveYear <- factor(ends[d$Peel + 1L], levels = ends)
  retro <- list(results = d, last_points = d[d$Year == ends[d$Peel + 1L], ],
    rho_text = data.frame(Variable = c("B", "Rec", "SSB", "N"), Rho = .01, Year = times[2L],
                          Valid = TRUE, ValidPeels = 2L, RequestedPeels = 2L),
    model_type = "acl",
    fit_diagnostics = data.frame(Peel = 0:2, RetrospectiveYear = ends, error = "", numerical_ok = TRUE))
  p <- plot_retro(retro)
  expect_identical(p$labels$colour, "Terminal period")
  labels <- ggplot2::ggplot_build(p)$plot$scales$get_scales("colour")$get_labels()
  expect_identical(as.character(labels), c("2004 Q4", "2003 Q4", "2002 Q4"))
})
