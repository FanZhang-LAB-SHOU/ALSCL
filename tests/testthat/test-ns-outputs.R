# Outputs for comparison with age readings and external assessments:
# length_at_age(), ssb_at_age(), relative_catch() and the growth and catch
# parts of compare_models().

# An ACL fit and an ALSCL fit to the same survey table. Weight and maturity
# increase with length and weight changes over time, so that quantities by
# age differ from quantities by length.
ns_output_fits <- local({
  cache <- NULL
  function() {
    if (!is.null(cache)) return(cache)
    f <- fixture_frames(); mid <- seq(15, 55, 5)
    f$data.CatL[[1]] <- f$data.wgt[[1]] <- f$data.mat[[1]] <- as.character(mid)
    f$data.wgt[-1] <- outer(1e-5 * mid^3, 1 + .02 * (0:4))
    f$data.mat[-1] <- stats::plogis((mid - 30) / 4)
    start <- function(model) {
      p <- create_parameters(model_type = tolower(model))$parameters
      p$log_Linf <- log(60); p$log_vbk <- log(.2); p$mean_log_R <- log(100); p$log_init_Z <- log(.5)
      sd_names <- if (model == "ACL") c("log_std_index", "log_std_log_N0", "log_std_log_R") else
        c("log_sigma_index", "log_sigma_log_N0", "log_sigma_log_R")
      p[sd_names] <- log(c(.2, .1, .1))
      p
    }
    p <- start("ALSCL")
    prep <- do.call(ALSCL:::.acl_prepare_data, f); d <- prep$data
    d$len_mid <- prep$bins$mid; d$len_lower <- prep$bins$lower; d$len_upper <- prep$bins$upper
    d$growth_step <- 1
    p$dev_log_R <- rep(0, d$Y); p$dev_log_F <- array(0, c(d$L, d$Y)); p$dev_log_N0 <- rep(0, d$A - 1L)
    truth <- TMB::MakeADFun(d, p, DLL = ALSCL:::.acl_compile("ALSCL")$dll_name, silent = TRUE)
    f$data.CatL[-1] <- exp(truth$report(truth$par)$Elog_index)
    fit <- function(model) {
      p <- start(model); mapping <- lapply(p, function(x) factor(NA)); mapping$mean_log_R <- NULL
      do.call(if (model == "ACL") run_acl else run_alscl,
              c(f, list(parameters = p, map = mapping, silent = TRUE)))
    }
    cache <<- list(acl = fit("ACL"), alscl = fit("ALSCL"), input = f, mid = mid,
      q = stats::plogis(log(19) * (mid - f$sel_L50) / (f$sel_L95 - f$sel_L50)),
      weight = as.matrix(f$data.wgt[-1]), maturity = as.matrix(f$data.mat[-1]))
    cache
  }
})

# Independent calculation: one age class and time step at a time.
ns_moments <- function(numbers, mid) {
  A <- dim(numbers)[2]; Y <- dim(numbers)[3]
  average <- spread <- matrix(NA_real_, A, Y)
  for (a in seq_len(A)) for (y in seq_len(Y)) {
    n <- numbers[, a, y]
    average[a, y] <- sum(mid * n) / sum(n)
    spread[a, y] <- sqrt(sum(n * (mid - average[a, y])^2) / sum(n))
  }
  list(mean = average, sd = spread)
}

test_that("length_at_age of an ALSCL fit equals a direct calculation from NLA", {
  z <- ns_output_fits(); fit <- z$alscl; nla <- fit$report$NLA
  out <- length_at_age(fit)
  expect_named(out, c("basis", "year", "age", "mean_length", "sd_length", "numerical_ok"))
  expect_identical(nrow(out), 2L * 4L * 5L)
  expect_identical(unique(out$basis), c("survey", "population"))
  expect_identical(out$year[out$basis == "survey"], rep(as.numeric(2000:2004), each = 4L))
  expect_identical(out$age[out$basis == "survey"], rep(as.numeric(1:4), 5L))
  expect_true(all(out$numerical_ok))
  population <- ns_moments(nla, z$mid)
  survey <- ns_moments(sweep(nla, 1, z$q, "*"), z$mid)
  expect_equal(out$mean_length[out$basis == "population"], as.numeric(population$mean), tolerance = 1e-12)
  expect_equal(out$sd_length[out$basis == "population"], as.numeric(population$sd), tolerance = 1e-10)
  expect_equal(out$mean_length[out$basis == "survey"], as.numeric(survey$mean), tolerance = 1e-12)
  expect_equal(out$sd_length[out$basis == "survey"], as.numeric(survey$sd), tolerance = 1e-10)
  # Survey catchability recovered from the report, as in the North Sea scripts.
  q_report <- exp(fit$report$Elog_index[, 1] - log(fit$report$NL[, 1]))
  expect_equal(ALSCL:::.acl_survey_catchability(fit)$length, q_report, tolerance = 1e-10)
  # Catchability rises with length here, so the survey sees larger fish at age.
  expect_true(all(survey$mean >= population$mean))
  expect_gt(max(survey$mean - population$mean), .1)
  # Lengths at age change with time in ALSCL.
  expect_gt(diff(range(population$mean[3, ])), .1)
  one <- length_at_age(fit, basis = "population")
  expect_equal(one, out[out$basis == "population", ], ignore_attr = TRUE)
})

test_that("length_at_age of an ACL fit comes from its age-length key", {
  z <- ns_output_fits(); fit <- z$acl; key <- fit$report$pla
  out <- length_at_age(fit)
  mean_population <- colSums(key * z$mid)
  sd_population <- sqrt(colSums(key * outer(z$mid, mean_population, "-")^2))
  seen <- key * z$q
  mean_survey <- colSums(seen * z$mid) / colSums(seen)
  sd_survey <- sqrt(colSums(seen * outer(z$mid, mean_survey, "-")^2) / colSums(seen))
  expect_equal(out$mean_length[out$basis == "population"], rep(mean_population, 5L), tolerance = 1e-12)
  expect_equal(out$sd_length[out$basis == "population"], rep(sd_population, 5L), tolerance = 1e-10)
  expect_equal(out$mean_length[out$basis == "survey"], rep(mean_survey, 5L), tolerance = 1e-12)
  expect_equal(out$sd_length[out$basis == "survey"], rep(sd_survey, 5L), tolerance = 1e-10)
})

test_that("length_at_age reads catchability from a saved assessment and through one accessor", {
  z <- ns_output_fits()
  for (fit in list(z$acl, z$alscl)) {
    path <- tempfile(fileext = ".rds"); save_assessment(fit, path)
    saved <- read_assessment(path); unlink(path)
    expect_null(saved$obj)
    expect_equal(length_at_age(saved), length_at_age(fit), tolerance = 1e-14)
  }
  fit <- z$alscl
  q <- ALSCL:::.acl_survey_catchability(fit)
  expect_equal(q$length, z$q, tolerance = 1e-14)
  expect_null(q$age)
  # A catchability multiplier by age class is returned by the accessor. It
  # scales all lengths of an age class equally and cancels in the moments.
  with_age <- fit
  with_age$obj <- list(env = list(data = c(fit$obj$env$data, list(q_age = c(.1, .5, 1, 1)))))
  expect_identical(ALSCL:::.acl_survey_catchability(with_age)$age, c(.1, .5, 1, 1))
  expect_equal(length_at_age(with_age), length_at_age(fit), tolerance = 1e-12)
  # Catchability by length and time step: each time step uses its own column.
  data <- fit$obj$env$data; L <- length(data$log_q); Y <- dim(fit$report$NLA)[3L]
  by_time <- matrix(data$log_q, L, Y); by_time[, Y] <- by_time[, Y] + log(seq(1, .2, length.out = L))
  with_time <- fit; with_time$obj <- list(env = list(data = c(data, list(log_q_LY = by_time))))
  varying <- length_at_age(with_time, "survey"); constant <- length_at_age(fit, "survey")
  last <- varying$year == max(varying$year)
  expect_equal(varying$mean_length[!last], constant$mean_length[!last], tolerance = 1e-12)
  weights <- fit$report$NLA[, , Y] * exp(by_time[, Y])
  expect_equal(varying$mean_length[last], as.numeric(colSums(weights * fit$len_mid) / colSums(weights)), tolerance = 1e-12)
  expect_true(all(varying$mean_length[last] < constant$mean_length[last]))
  # Without a TMB object or a recipe the population basis remains available.
  bare <- fit; bare$obj <- NULL; bare$recipe <- NULL
  expect_error(length_at_age(bare), "Survey catchability at length is unavailable")
  expect_equal(length_at_age(bare, "population"), length_at_age(fit, "population"))
})

test_that("length_at_age rejects unusable input", {
  z <- ns_output_fits(); fit <- z$alscl
  expect_error(length_at_age(fit, basis = "catch"), "should be")
  expect_error(length_at_age(fit, basis = c("survey", "survey")), "must not repeat")
  failed <- list(converge = "FAILED", error = "t0 must be below the recruitment age.")
  expect_error(length_at_age(failed), "failed fit without estimates.*t0 must be below")
  expect_error(length_at_age(1), "fitted ACL or ALSCL result")
  broken <- fit; broken$age <- NULL
  expect_error(length_at_age(broken), "finite age metadata")
  broken <- fit; broken$report$NLA <- broken$report$NLA[, -1, ]
  expect_error(length_at_age(broken), "do not match the ages and time steps")
  broken <- fit; broken$len_mid <- broken$len_mid[-1]
  expect_error(length_at_age(broken, "population"), "length-bin midpoints")
})

test_that("ssb_at_age equals the model SSB for the biomass-weighted maturity at age", {
  z <- ns_output_fits(); fit <- z$alscl; r <- fit$report
  same <- ssb_at_age(fit, maturity = r$SBA / r$BA)
  expect_named(same, c("year", "SSB", "SSB_model", "numerical_ok"))
  expect_identical(same$year, as.numeric(2000:2004))
  expect_equal(same$SSB_model, as.numeric(r$SSB))
  expect_equal(same$SSB, same$SSB_model, tolerance = 1e-12)
  # Maturity at length converted to age with numbers as weights: the difference
  # is the within-age covariance of weight and maturity, summed over numbers.
  nla <- r$NLA; A <- 4L; Y <- 5L
  by_numbers <- expected <- matrix(NA_real_, A, Y)
  for (a in seq_len(A)) for (y in seq_len(Y)) {
    n <- nla[, a, y]; w <- z$weight[, y]; m <- z$maturity[, y]
    by_numbers[a, y] <- sum(n * m) / sum(n)
    expected[a, y] <- sum(n * (w - sum(n * w) / sum(n)) * (m - by_numbers[a, y]))
  }
  lower <- ssb_at_age(fit, maturity = by_numbers)
  expect_equal(lower$SSB_model - lower$SSB, colSums(expected), tolerance = 1e-10)
  # Weight and maturity both increase with length, so this SSB is the lower one.
  expect_true(all(lower$SSB < lower$SSB_model))
  # A vector applies to every time step; weight at age replaces model biomass.
  ogive <- c(0, .5, 1, 1)
  expect_equal(ssb_at_age(fit, ogive)$SSB, colSums(ogive * r$BA), tolerance = 1e-12)
  expect_equal(ssb_at_age(fit, matrix(ogive, A, Y))$SSB, ssb_at_age(fit, ogive)$SSB)
  expect_equal(ssb_at_age(fit, ogive, weight = r$BA / r[["NA"]])$SSB, ssb_at_age(fit, ogive)$SSB,
               tolerance = 1e-12)
  expect_equal(ssb_at_age(fit, ogive, weight = c(1, 2, 3, 4))$SSB,
               colSums(ogive * c(1, 2, 3, 4) * r[["NA"]]), tolerance = 1e-12)
})

test_that("ssb_at_age computes ACL biomass at age from the age-length key", {
  z <- ns_output_fits(); fit <- z$acl; r <- fit$report
  mean_weight <- t(r$pla) %*% z$weight
  biomass <- r[["NA"]] * mean_weight
  expect_equal(colSums(biomass), as.numeric(r$B), tolerance = 1e-10, ignore_attr = TRUE)
  ogive <- c(0, .5, 1, 1)
  expect_equal(ssb_at_age(fit, ogive)$SSB, as.numeric(colSums(ogive * biomass)), tolerance = 1e-12)
  implied <- (t(r$pla) %*% (z$weight * z$maturity)) / mean_weight
  same <- ssb_at_age(fit, implied)
  expect_equal(same$SSB, same$SSB_model, tolerance = 1e-10)
  path <- tempfile(fileext = ".rds"); save_assessment(fit, path)
  saved <- read_assessment(path); unlink(path)
  expect_equal(ssb_at_age(saved, ogive), ssb_at_age(fit, ogive), tolerance = 1e-14)
  bare <- fit; bare$obj <- NULL; bare$recipe <- NULL
  expect_error(ssb_at_age(bare, ogive), "Supply weight at age in weight")
  expect_equal(ssb_at_age(bare, ogive, weight = mean_weight)$SSB, ssb_at_age(fit, ogive)$SSB,
               tolerance = 1e-12)
})

test_that("ssb_at_age validates maturity and weight", {
  fit <- ns_output_fits()$alscl
  expect_error(ssb_at_age(fit), "maturity .* is required")
  expect_error(ssb_at_age(fit, c(0, .5, 1)), "one value per age class \\(4\\)")
  expect_error(ssb_at_age(fit, matrix(.5, 4, 4)), "4 x 5")
  expect_error(ssb_at_age(fit, c(0, .5, 1, 1.2)), "between 0 and 1")
  expect_error(ssb_at_age(fit, c(0, .5, NA, 1)), "between 0 and 1")
  expect_error(ssb_at_age(fit, "mature"), "numeric vector")
  expect_error(ssb_at_age(fit, rep(1, 4), weight = c(1, 2, -1, 3)), "weight must be finite and nonnegative")
  expect_error(ssb_at_age(fit, rep(1, 4), weight = 1:3), "weight must be a numeric vector")
})

test_that("relative_catch divides catch by its mean over the time steps", {
  z <- ns_output_fits(); fit <- z$alscl; r <- fit$report
  out <- relative_catch(fit)
  expect_named(out, c("year", "catch_number", "catch_weight", "extrapolated", "numerical_ok"))
  expect_equal(mean(out$catch_number), 1, tolerance = 1e-14)
  expect_equal(mean(out$catch_weight), 1, tolerance = 1e-14)
  expect_equal(out$catch_number, as.numeric(r$CN / mean(r$CN)), tolerance = 1e-14)
  expect_equal(out$catch_weight, as.numeric(r$CB / mean(r$CB)), tolerance = 1e-14)
  # F of the terminal time step is a prediction, and so is its catch.
  expect_identical(out$extrapolated, c(FALSE, FALSE, FALSE, FALSE, TRUE))
  part <- relative_catch(fit, years = 2001:2003)
  expect_equal(mean(part$catch_number[2:4]), 1, tolerance = 1e-14)
  expect_equal(part$catch_weight, as.numeric(r$CB / mean(r$CB[2:4])), tolerance = 1e-14)
  expect_error(relative_catch(fit, years = c(2001, 2010)), "not found: 2010")
  expect_error(relative_catch(fit, years = "2001"), "finite numeric time steps")
  # Later time steps without a positive observation are predictions as well.
  gap <- fit; gap$observations[, 4:5] <- NA
  expect_identical(relative_catch(gap)$extrapolated, c(FALSE, FALSE, TRUE, TRUE, TRUE))
})

test_that("relative_catch computes ACL catch in weight from catch at age", {
  z <- ns_output_fits(); fit <- z$acl; r <- fit$report
  expect_null(r$CB)
  weight <- colSums(r$CNA * (t(r$pla) %*% z$weight))
  out <- relative_catch(fit)
  expect_equal(out$catch_number, as.numeric(r$CN / mean(r$CN)), tolerance = 1e-14)
  expect_equal(out$catch_weight, as.numeric(weight / mean(weight)), tolerance = 1e-12)
  path <- tempfile(fileext = ".rds"); save_assessment(fit, path)
  saved <- read_assessment(path); unlink(path)
  expect_equal(relative_catch(saved), out, tolerance = 1e-14)
  bare <- fit; bare$obj <- NULL; bare$recipe <- NULL
  expect_true(all(is.na(relative_catch(bare)$catch_weight)))
  expect_equal(relative_catch(bare)$catch_number, out$catch_number)
})

test_that("compare_models lists growth parameters by model and compares mean length at age", {
  z <- ns_output_fits()
  output <- capture.output(x <- compare_models(z$acl, z$alscl, z$input$data.CatL))
  # One block of rows per model; no column places the two models side by side.
  expect_named(x$growth, c("Model", "Parameter", "Estimate", "Meaning"))
  expect_identical(x$growth$Parameter[x$growth$Model == "ACL"],
                   c("Linf", "k (vbk)", "t0", "cv_len", "sigma_index"))
  expect_identical(x$growth$Parameter[x$growth$Model == "ALSCL"],
                   c("Linf", "k (vbk)", "t0", "cv_len", "cv_grow", "sigma_index"))
  expect_equal(x$growth$Estimate[x$growth$Model == "ALSCL" & x$growth$Parameter == "Linf"],
               round(z$alscl$report$Linf, 3))
  expect_equal(x$growth$Estimate[x$growth$Model == "ACL" & x$growth$Parameter == "sigma_index"],
               round(z$acl$report$std_index, 4))
  expect_match(x$growth$Meaning[x$growth$Model == "ACL"][1], "von Bertalanffy curve of mean length at age")
  expect_match(x$growth$Meaning[x$growth$Model == "ALSCL"][1], "growth increment at length")
  # Mean length at age, as the survey sees it, averaged over the time steps.
  expect_named(x$length_at_age, c("Age", "Basis", "ACL", "ALSCL"))
  expect_identical(x$length_at_age$Age, as.numeric(1:4))
  expect_identical(unique(x$length_at_age$Basis), "survey")
  by_age <- function(fit) {
    tab <- length_at_age(fit, "survey")
    as.numeric(tapply(tab$mean_length, tab$age, mean))
  }
  expect_equal(x$length_at_age$ACL, by_age(z$acl), tolerance = 1e-12)
  expect_equal(x$length_at_age$ALSCL, by_age(z$alscl), tolerance = 1e-12)
  expect_true(any(grepl("Growth and observation error parameters, by model", output, fixed = TRUE)))
  expect_true(any(grepl("different quantities in ACL and ALSCL", output, fixed = TRUE)))
  expect_true(any(grepl("--- Mean length at age ---", output, fixed = TRUE)))
  expect_true(any(grepl("As the survey sees it", output, fixed = TRUE)))
  expect_false(any(grepl("--- Growth Parameters ---", output, fixed = TRUE)))
  # Two fits of the same model type: the note says the parameters are comparable.
  same <- capture.output(compare_models(z$acl, z$acl, z$input$data.CatL))
  expect_true(any(grepl("Both fits are ACL", same, fixed = TRUE)))
})

test_that("compare_models compares catch as relative catch", {
  z <- ns_output_fits()
  output <- capture.output(x <- compare_models(z$acl, z$alscl, z$input$data.CatL))
  expect_identical(x$correlation$Quantity,
                   c("SSB", "Rec", "B", "N", "CN (relative)", "CB (relative)"))
  catch <- x$correlation$Quantity %in% c("CN (relative)", "CB (relative)")
  expect_true(all(is.na(x$correlation$Ratio_Mean[catch])))
  expect_true(all(is.finite(x$correlation$Ratio_Mean[!catch])))
  expect_equal(x$correlation$Correlation[5],
               round(stats::cor(z$acl$report$CN, z$alscl$report$CN), 4))
  # The correlation of relative series equals that of the series themselves;
  # ACL catch in weight comes from catch at age and mean weight at age.
  expect_equal(x$correlation$Correlation[6],
               round(stats::cor(relative_catch(z$acl)$catch_weight,
                                relative_catch(z$alscl)$catch_weight), 4))
  expect_equal(x$correlation$Ratio_Mean[1],
               round(mean(z$alscl$report$SSB) / mean(z$acl$report$SSB), 4))
  expect_true(any(grepl("compared as relative catch", output, fixed = TRUE)))
})

test_that("compare_models keeps its tables for results without growth or catch reports", {
  d <- fixture_frames()$data.CatL; observed <- as.matrix(d[-1L])
  m <- list(model_type = "ACL", year = 2000:2004, len_label = as.character(d[[1L]]),
    observations = observed, report = list(Elog_index = log(observed)),
    opt = list(par = c(mean_log_R = 1), objective = 10, convergence = 0L),
    convergence_code = 0L, converge = "converged", pdHess = TRUE, bound_hit = FALSE,
    gradient = 1e-8, max_abs_gradient = 1e-8,
    diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE, issues = character()))
  output <- capture.output(x <- compare_models(m, m, d, "first", "second"))
  expect_null(x$length_at_age)
  expect_identical(unique(x$growth$Model), c("first", "second"))
  expect_true(all(is.na(x$growth$Estimate)))
  expect_true(all(is.na(x$correlation$Correlation)))
  expect_true(any(grepl("Not available", output, fixed = TRUE)))
  # Population basis when survey catchability is unavailable for one fit.
  z <- ns_output_fits(); bare <- z$alscl; bare$obj <- NULL; bare$recipe <- NULL
  capture.output(x <- compare_models(z$acl, bare, z$input$data.CatL))
  expect_identical(unique(x$length_at_age$Basis), "population")
  expect_equal(x$length_at_age$ACL, as.numeric(colSums(z$acl$report$pla * z$mid)), tolerance = 1e-12)
})
