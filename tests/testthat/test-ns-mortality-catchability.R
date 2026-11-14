# Natural mortality rate (M) by age and time step or by length, survey
# catchability at length supplied directly (survey_q) and a survey
# catchability multiplier by age (survey_q_age).

ns_prepare <- function(...) {
  f <- fixture_frames()
  changes <- list(...)
  f[names(changes)] <- changes
  do.call(ALSCL:::.acl_prepare_data, f)
}

# Template evaluation at fixed parameter values, without optimization.
ns_template <- function(model, extra = list(), deviations = TRUE) {
  fixture <- cpp_fixture(model)
  p <- fixture$parameters
  if (deviations) {
    p$dev_log_R <- c(-.2, .1, .3, -.1)
    p$dev_log_F[] <- seq(-.4, .5, length.out = length(p$dev_log_F))
    p$dev_log_N0 <- seq(-.1, .2, length.out = length(p$dev_log_N0))
  }
  d <- fixture$data
  d[names(extra)] <- extra
  obj <- TMB::MakeADFun(d, p, DLL = fixture$info$dll_name, silent = TRUE)
  list(obj = obj, data = d, report = obj$report(obj$par), value = obj$fn(obj$par),
       gradient = as.numeric(obj$gr(obj$par)))
}

test_that("lorenzen_M returns the rate by length and checks its inputs", {
  mid <- c(10, 20, 40, 80)
  expect_equal(lorenzen_M(mid, M_ref = 0.2, L_ref = 40), 0.2 * 40 / mid)
  expect_equal(lorenzen_M(40, 0.2, 40), 0.2)
  expect_equal(lorenzen_M(mid, 0.3, 20, exponent = -1.5), 0.3 * (mid / 20)^-1.5)
  expect_equal(lorenzen_M(mid, 0.3, 20, exponent = 0), rep(0.3, 4))
  expect_identical(formals(lorenzen_M)$exponent, quote(-1))
  # The curve depends on M_ref and L_ref through their product only.
  expect_equal(lorenzen_M(mid, 0.2, 40), lorenzen_M(mid, 0.4, 20))
  expect_error(lorenzen_M(c(10, 0), 0.2, 40), "finite positive lengths")
  expect_error(lorenzen_M(c(10, NA), 0.2, 40), "finite positive lengths")
  expect_error(lorenzen_M(numeric(), 0.2, 40), "finite positive lengths")
  expect_error(lorenzen_M("a", 0.2, 40), "finite positive lengths")
  expect_error(lorenzen_M(mid, -0.1, 40), "M_ref")
  expect_error(lorenzen_M(mid, c(0.1, 0.2), 40), "M_ref")
  expect_error(lorenzen_M(mid, 0.2, 0), "L_ref")
  expect_error(lorenzen_M(mid, 0.2, 40, exponent = NA_real_), "exponent")
})

test_that("a single M prepares the same input as before", {
  default <- ns_prepare()
  expect_identical(names(default), c("data", "bins", "year", "growth_step", "observations", "data.CatL",
    "structure", "start_spread", "t0_lower", "zero_observations"))
  expect_identical(names(default$data), c("logN_at_len", "na_matrix", "log_q", "len_border", "age",
    "Y", "A", "L", "weight", "mat", "M"))
  expect_identical(default$data$M, .2)
  for (model in c("ACL", "ALSCL")) {
    setup <- ALSCL:::.acl_model_setup(model, default)
    expect_false(any(c("M_AY", "M_LAY", "q_age") %in% names(setup$data)))
  }
  expect_error(ns_prepare(M = -1), "M must be finite and >= 0")
  expect_error(ns_prepare(M = NA_real_), "M must be finite and >= 0")
  expect_error(ns_prepare(M = "a"), "M must be finite and >= 0")
  expect_error(ns_prepare(M = NULL), "M must be finite and >= 0")
})

test_that("M by age and time step and M by length are told apart by their dimensions", {
  # fixture: 9 length bins, 4 age classes, 5 time steps
  by_age_time <- matrix(seq(.1, .5, length.out = 20), 4, 5)
  x <- ns_prepare(M = by_age_time)
  expect_identical(x$natural_mortality$form, "age_time")
  expect_equal(x$natural_mortality$M, by_age_time)
  expect_equal(x$data$M, stats::median(by_age_time[, 1]))
  one_column <- ns_prepare(M = matrix(c(.4, .3, .2, .1), ncol = 1))
  expect_identical(one_column$natural_mortality$form, "age_time")
  expect_equal(one_column$natural_mortality$M, matrix(c(.4, .3, .2, .1), 4, 5))
  by_length <- ns_prepare(M = seq(.9, .1, by = -.1))
  expect_identical(by_length$natural_mortality$form, "length")
  expect_equal(by_length$natural_mortality$M, seq(.9, .1, by = -.1))
  expect_equal(by_length$data$M, .5)
  integer_matrix <- ns_prepare(M = matrix(1L, 4, 5))
  expect_type(integer_matrix$natural_mortality$M, "double")

  # Equal numbers of age classes and length bins: the dim attribute decides.
  square <- ns_prepare(nage = 9, M = matrix(seq(.1, .9, by = .1), ncol = 1))
  expect_identical(square$natural_mortality$form, "age_time")
  expect_identical(ns_prepare(nage = 9, M = seq(.1, .9, by = .1))$natural_mortality$form, "length")

  expect_error(ns_prepare(M = matrix(.2, 5, 4)),
    "4 rows \\(one per age class\\) and 5 columns \\(one per time step\\) or one column.*transpose")
  expect_error(ns_prepare(M = matrix(.2, 4, 3)), "matrix with 4 rows and 3 columns.*4 rows.*5 columns")
  expect_error(ns_prepare(M = matrix(.2, 9, 1)), "matrix with 9 rows and 1 columns.*4 rows")
  expect_error(ns_prepare(M = rep(.2, 4)),
    "vector with 4 values.*must have 9 values \\(one per length bin\\).*matrix\\(M, ncol = 1\\)")
  expect_error(ns_prepare(M = rep(.2, 5)), "must have 9 values")
  expect_error(ns_prepare(M = array(.2, c(9, 4, 5))), "array with 3 dimensions")
  expect_error(ns_prepare(M = as.data.frame(by_age_time)), "data frame")
  expect_error(ns_prepare(M = list(.2, .3)), "single number; a numeric matrix with 4 rows")
  expect_error(ns_prepare(M = replace(by_age_time, 3, -0.1)), "finite, nonnegative")
  expect_error(ns_prepare(M = replace(by_age_time, 3, NA)), "finite, nonnegative")
  expect_error(ns_prepare(M = replace(rep(.2, 9), 2, Inf)), "finite, nonnegative")

  # Column names that are numbers must be the time steps of the data.
  named <- by_age_time; colnames(named) <- 2000:2004
  expect_identical(ns_prepare(M = named)$natural_mortality$form, "age_time")
  colnames(named) <- 2001:2005
  expect_error(ns_prepare(M = named), "column 1 is named 2001 and the time step is 2000")
  colnames(named) <- paste0("V", 1:5)
  expect_identical(ns_prepare(M = named)$natural_mortality$form, "age_time")
})

test_that("non-scalar M is expanded to the arrays of the templates", {
  by_age_time <- matrix(seq(.1, .5, length.out = 20), 4, 5)
  x <- ns_prepare(M = by_age_time)
  acl <- ALSCL:::.acl_model_setup("ACL", x)$data
  expect_equal(acl$M_AY, by_age_time)
  expect_null(acl$M_LAY)
  alscl <- ALSCL:::.acl_model_setup("ALSCL", x)$data
  expect_identical(dim(alscl$M_LAY), c(9L, 4L, 5L))
  for (l in c(1, 5, 9)) expect_equal(alscl$M_LAY[l, , ], by_age_time)
  expect_null(alscl$M_AY)

  rate <- seq(.9, .1, by = -.1)
  by_length <- ALSCL:::.acl_model_setup("ALSCL", ns_prepare(M = rate))$data
  expect_identical(dim(by_length$M_LAY), c(9L, 4L, 5L))
  for (a in 1:4) for (y in c(1, 5)) expect_equal(by_length$M_LAY[, a, y], rate)

  expect_error(ALSCL:::.acl_model_setup("ACL", ns_prepare(M = rate)),
    "ACL does not accept this form, because it follows numbers at age only.*run_alscl\\(\\).*4 rows and one column")
  f <- fixture_frames(); f$M <- rate
  expect_error(do.call(run_acl, c(f, list(silent = TRUE))), "ACL does not accept this form")
  expect_false(check_alscl_data(f, "acl")$valid)
  expect_true(check_alscl_data(f, "alscl")$valid)

  # The default start of init_Z uses the median of M in the first time step.
  start <- ALSCL:::.acl_model_setup("ALSCL", x)$parameters$log_init_Z
  expect_equal(start, log(stats::median(by_age_time[, 1]) + .3))
})

test_that("survey_q replaces the logistic curve and cannot be combined with it", {
  default <- ns_prepare()
  mid <- default$bins$mid
  logistic <- stats::plogis(log(19) * (mid - 20) / 10)
  supplied <- ns_prepare(survey_q = logistic, sel_L50 = NULL, sel_L95 = NULL)
  expect_equal(supplied$data$log_q, default$data$log_q, tolerance = 1e-14)
  expect_identical(names(supplied$data), names(default$data))
  dome <- exp(-((mid - 30) / 15)^2)
  expect_equal(ns_prepare(survey_q = 2 * dome, sel_L50 = NULL, sel_L95 = NULL)$data$log_q, log(2 * dome))
  f <- fixture_frames()
  f$sel_L50 <- f$sel_L95 <- NULL
  expect_equal(do.call(ALSCL:::.acl_prepare_data, c(f, list(survey_q = dome)))$data$log_q, log(dome))

  expect_error(ns_prepare(survey_q = logistic), "cannot be combined with sel_L50 or sel_L95.*sel_L50 = NULL")
  expect_error(ns_prepare(survey_q = logistic, sel_L50 = NULL), "cannot be combined")
  expect_error(do.call(ALSCL:::.acl_prepare_data, f), "sel_L50 and sel_L95 are required unless")
  expect_error(ns_prepare(sel_L95 = NULL), "sel_L50 and sel_L95 are required unless")
  for (bad in list(logistic[-1], replace(logistic, 2, 0), replace(logistic, 2, -1), replace(logistic, 2, NA),
                   as.character(logistic), matrix(logistic, 3, 3)))
    expect_error(ns_prepare(survey_q = bad, sel_L50 = NULL, sel_L95 = NULL),
                 "survey_q must be a numeric vector with 9 finite positive values")
  expect_error(ns_prepare(sel_L50 = 30, sel_L95 = 20), "sel_L95 must be greater than sel_L50")
})

test_that("survey_q_age is validated, passed on and raises the start of mean_log_R", {
  default <- ns_prepare()
  q_age <- c(.1, .5, 1, .8)
  x <- ns_prepare(survey_q_age = q_age)
  expect_equal(x$data$q_age, q_age)
  expect_null(default$data$q_age)
  for (bad in list(q_age[-1], c(q_age, 1), replace(q_age, 1, 0), replace(q_age, 1, NA), matrix(q_age, 2, 2), "a"))
    expect_error(ns_prepare(survey_q_age = bad),
                 "survey_q_age must be a numeric vector with 4 finite positive values")
  for (model in c("ACL", "ALSCL")) {
    base <- ALSCL:::.acl_model_setup(model, default)
    shifted <- ALSCL:::.acl_model_setup(model, x)
    expect_equal(shifted$data$q_age, q_age)
    expect_equal(shifted$parameters$mean_log_R, base$parameters$mean_log_R - log(.1))
    # A supplied start is used as it is.
    kept <- ALSCL:::.acl_model_setup(model, x, parameters = list(mean_log_R = 3))
    expect_equal(kept$parameters$mean_log_R, 3)
    # Ones leave the default start unchanged.
    ones <- ALSCL:::.acl_model_setup(model, ns_prepare(survey_q_age = rep(1, 4)))
    expect_equal(ones$parameters$mean_log_R, base$parameters$mean_log_R)
  }
  f <- fixture_frames()
  table <- inspect_parameters(c(f, list(survey_q_age = q_age)), "acl")
  plain <- inspect_parameters(f, "acl")
  expect_equal(table$start[table$parameter == "mean_log_R"],
               plain$start[plain$parameter == "mean_log_R"] - log(.1))
})

test_that("input bundles and their model settings accept the new forms", {
  f <- fixture_frames()
  tables <- f[c("data.CatL", "data.wgt", "data.mat")]
  M_age <- matrix(c(.4, .3, .2, .2), 4, 5)
  q <- stats::plogis(log(19) * (seq(17.5, 57.5, 5) - 20) / 10)
  x <- prepare_alscl_data(tables, fit_args = list(rec.age = 1, nage = 4, M = M_age, survey_q = q,
                                                  survey_q_age = c(.5, 1, 1, 1)),
    fit_config = list(alscl = list(M = seq(.6, .2, length.out = 9))))
  for (model in c("acl", "alscl")) expect_true(check_alscl_data(x, model)$valid)
  acl <- ALSCL:::.acl_preflight(x, "acl")
  expect_equal(acl$setup$data$M_AY, M_age)
  expect_equal(acl$setup$data$q_age, c(.5, 1, 1, 1))
  alscl <- ALSCL:::.acl_preflight(x, "alscl")
  expect_equal(alscl$setup$data$M_LAY[, 2, 3], seq(.6, .2, length.out = 9))
  resolved <- ALSCL:::.acl_resolved_args(x, "acl")
  expect_null(resolved$sel_L50)
  expect_identical(names(resolved), names(formals(run_acl)))
  # A bundle with sel_L50 and sel_L95 needs both set to NULL next to survey_q.
  y <- prepare_alscl_data(tables, fit_args = f[-(1:3)])
  expect_true(check_alscl_data(y, "acl")$valid)
  args <- ALSCL:::.acl_bundle_args(y, "acl", list(survey_q = q))
  expect_error(do.call(ALSCL:::.acl_prepare_data, args[intersect(names(args), names(formals(ALSCL:::.acl_prepare_data)))]),
               "cannot be combined")
  args <- ALSCL:::.acl_bundle_args(y, "acl", list(survey_q = q, sel_L50 = NULL, sel_L95 = NULL))
  expect_silent(do.call(ALSCL:::.acl_prepare_data, args[intersect(names(args), names(formals(ALSCL:::.acl_prepare_data)))]))
})

test_that("constant inputs in the new forms give the scalar objective in both templates", {
  skip_on_cran()
  for (model in c("ACL", "ALSCL")) {
    base <- ns_template(model)
    d <- base$data
    constant <- if (model == "ACL") list(M_AY = matrix(d$M, d$A, d$Y)) else
      list(M_LAY = array(d$M, c(d$L, d$A, d$Y)))
    by_time <- list(log_q_LY = matrix(d$log_q, d$L, d$Y))
    forms <- list(M = constant, q_age = list(q_age = rep(1, d$A)), q_time = by_time,
                  all = c(constant, list(q_age = rep(1, d$A)), by_time))
    for (name in names(forms)) {
      other <- ns_template(model, forms[[name]])
      expect_equal(other$value, base$value, tolerance = 1e-12, info = paste(model, name))
      expect_equal(other$gradient, base$gradient, tolerance = 1e-9, info = paste(model, name))
      shared <- intersect(names(base$report), names(other$report))
      expect_setequal(setdiff(names(other$report), names(base$report)),
                      if (model == "ALSCL" && name %in% c("M", "all")) "M_LAY" else character())
      for (quantity in shared)
        expect_equal(other$report[[quantity]], base$report[[quantity]], tolerance = 1e-11,
                     info = paste(model, name, quantity))
    }
    # A wrong number of values is an error of the template, not a silent misread.
    wrong <- d; wrong$q_age <- rep(1, d$A + 1L)
    expect_error(TMB::MakeADFun(wrong, cpp_fixture(model)$parameters, DLL = cpp_fixture(model)$info$dll_name,
                                silent = TRUE), "q_age")
  }
})

test_that("the ACL template applies M by age and time step and the multiplier by age", {
  skip_on_cran()
  d0 <- cpp_fixture("ACL")$data
  A <- d0$A; Y <- d0$Y; L <- d0$L
  M <- matrix(seq(.05, .6, length.out = A * Y), A, Y)
  q_age <- seq(.2, 1.2, length.out = A)
  log_q_time <- matrix(log(seq(.3, 1.4, length.out = L * Y)), L, Y)
  r <- ns_template("ACL", list(M_AY = M, q_age = q_age))$report
  by_time <- ns_template("ACL", list(M_AY = M, q_age = q_age, log_q_LY = log_q_time))$report
  expect_equal(by_time$Elog_index, r$Elog_index - d0$log_q + log_q_time, tolerance = 1e-12)
  expect_equal(ns_template("ACL", list(log_q_LY = log_q_time))$report$Elog_index,
               ns_template("ACL")$report$Elog_index - d0$log_q + log_q_time, tolerance = 1e-12)
  expect_equal(by_time[["NA"]], r[["NA"]], tolerance = 0)
  expect_equal(r$Z, r$F + M, tolerance = 1e-14)
  numbers <- r[["NA"]]
  for (y in 2:Y) {
    expect_equal(numbers[2:(A - 1), y], numbers[1:(A - 2), y - 1] * exp(-r$Z[1:(A - 2), y - 1]), tolerance = 1e-12)
    expect_equal(numbers[A, y], sum(numbers[(A - 1):A, y - 1] * exp(-r$Z[(A - 1):A, y - 1])), tolerance = 1e-12)
  }
  expect_equal(r$CNA, numbers * r$F * (1 - exp(-r$Z)) / r$Z, tolerance = 1e-12)
  seen <- r$pla %*% (q_age * numbers)
  expect_equal(r$Elog_index, d0$log_q + log(seen), tolerance = 1e-12)
  # Numbers at length are the population, not what the survey sees.
  expect_equal(r$NL, r$pla %*% numbers, tolerance = 1e-12)
  # The rate differs from the scalar fit where M differs.
  expect_gt(max(abs(r$Z - ns_template("ACL")$report$Z)), .1)
})

test_that("the ALSCL template applies M by length, age and time step and the multiplier by age", {
  skip_on_cran()
  d0 <- cpp_fixture("ALSCL")$data
  A <- d0$A; Y <- d0$Y; L <- d0$L
  by_age_time <- matrix(seq(.05, .6, length.out = A * Y), A, Y)
  by_length <- lorenzen_M(d0$len_mid, M_ref = .2, L_ref = 60)
  cases <- list(age_time = aperm(array(by_age_time, c(A, Y, L)), c(3, 1, 2)),
                length = array(by_length, c(L, A, Y)),
                general = array(seq(.02, .7, length.out = L * A * Y), c(L, A, Y)))
  q_age <- seq(.2, 1.2, length.out = A)
  for (name in names(cases)) {
    M <- cases[[name]]
    r <- ns_template("ALSCL", list(M_LAY = M, q_age = q_age))$report
    expect_equal(r$M_LAY, M, tolerance = 0, info = name)
    N <- r$NLA; FL <- r$FL
    for (y in 2:Y) {
      for (a in 2:(A - 1))
        expect_equal(N[, a, y], as.numeric(r$G %*% (N[, a - 1, y - 1] * exp(-(FL[, y - 1] + M[, a - 1, y - 1])))),
                     tolerance = 1e-12, info = name)
      plus <- N[, A - 1, y - 1] * exp(-(FL[, y - 1] + M[, A - 1, y - 1])) +
        N[, A, y - 1] * exp(-(FL[, y - 1] + M[, A, y - 1]))
      expect_equal(N[, A, y], as.numeric(r$G %*% plus), tolerance = 1e-12, info = name)
    }
    F_array <- aperm(array(FL, c(L, Y, A)), c(1, 3, 2))
    Z <- F_array + M
    expect_equal(r$CNLA, N * F_array * (1 - exp(-Z)) / Z, tolerance = 1e-12, info = name)
    # Z and F at age: cohort decline, and Z minus the mean of M weighted by numbers at length.
    before <- apply(N, c(2, 3), sum)
    after <- apply(N * exp(-Z), c(2, 3), sum)
    Z_age <- log(before) - log(after)
    F_age <- Z_age - apply(N * M, c(2, 3), sum) / before
    expect_equal(r$ZA, Z_age[-A, -Y], tolerance = 1e-12, info = name)
    expect_equal(r$FA, F_age[-A, -Y], tolerance = 1e-10, info = name)
    # Z at length: F at length plus the mean of M weighted by numbers at age.
    expect_equal(r$ZL, FL + apply(N * M, c(1, 3), sum) / apply(N, c(1, 3), sum), tolerance = 1e-10, info = name)
    seen <- apply(sweep(N, 2, q_age, "*"), c(1, 3), sum)
    expect_equal(r$Elog_index, d0$log_q + log(seen), tolerance = 1e-12, info = name)
    expect_equal(r$NL, apply(N, c(1, 3), sum), tolerance = 1e-12, info = name)

    # F at age completed in R agrees with the template in the cells both compute.
    fit <- list(report = r, model_type = "ALSCL")
    completed <- ALSCL:::.acl_F_at_age(fit)
    expect_true(completed$complete)
    expect_identical(dim(completed$FA), c(A, Y))
    expect_equal(completed$FA, F_age, tolerance = 1e-10, info = name)
    expect_equal(completed$ZA, Z_age, tolerance = 1e-12, info = name)
    expect_identical(completed$FA[-A, -Y], r$FA)
  }
  # Survey catchability by length and time step replaces the vector.
  log_q_time <- matrix(log(seq(.3, 1.4, length.out = L * Y)), L, Y)
  plain <- ns_template("ALSCL")$report
  expect_equal(ns_template("ALSCL", list(log_q_LY = log_q_time))$report$Elog_index,
               plain$Elog_index - d0$log_q + log_q_time, tolerance = 1e-12)
  with_age <- ns_template("ALSCL", list(q_age = q_age))$report
  expect_equal(ns_template("ALSCL", list(q_age = q_age, log_q_LY = log_q_time))$report$Elog_index,
               with_age$Elog_index - d0$log_q + log_q_time, tolerance = 1e-12)
  # With M by age only, F at age is Z at age minus the M of that age.
  r <- ns_template("ALSCL", list(M_LAY = cases$age_time))$report
  expect_equal(r$ZA - r$FA, by_age_time[-A, -Y], tolerance = 1e-12)
  # With M by length only, Z at length is F at length plus that M.
  r <- ns_template("ALSCL", list(M_LAY = cases$length))$report
  expect_equal(r$ZL, r$FL + by_length, tolerance = 1e-12)
})

test_that("fits with constant inputs in the new forms reproduce the scalar fit", {
  skip_on_cran()
  for (model in c("ACL", "ALSCL")) {
    f <- fit_fixture(model)
    base <- f$result
    run <- if (model == "ACL") run_acl else run_alscl
    args <- c(f$input, list(parameters = f$parameters, map = f$map, silent = TRUE))
    mid <- base$len_mid
    forms <- list(
      matrix = list(M = matrix(.2, 4, 5)),
      one_column = list(M = matrix(.2, 4, 1)),
      survey_q = list(survey_q = stats::plogis(log(19) * (mid - 20) / 10), sel_L50 = NULL, sel_L95 = NULL),
      helper = list(survey_q = survey_catchability(mid, "logistic", L50 = 20, L95 = 30),
                    sel_L50 = NULL, sel_L95 = NULL),
      q_time = list(survey_q = matrix(stats::plogis(log(19) * (mid - 20) / 10), 9, 5),
                    sel_L50 = NULL, sel_L95 = NULL),
      q_age = list(survey_q_age = rep(1, 4)))
    if (model == "ALSCL") forms$length <- list(M = rep(.2, 9))
    for (name in names(forms)) {
      changed <- args
      changed[names(forms[[name]])] <- forms[[name]]
      fit <- do.call(run, changed)
      info <- paste(model, name)
      expect_equal(fit$opt$objective, base$opt$objective, tolerance = 1e-9, info = info)
      expect_equal(fit$opt$par, base$opt$par, tolerance = 1e-7, info = info)
      expect_equal(fit$report$SSB, base$report$SSB, tolerance = 1e-7, info = info)
      expect_equal(fit$report$Elog_index, base$report$Elog_index, tolerance = 1e-7, info = info)
      expect_true(isTRUE(fit$diagnostics$numerical_ok) == isTRUE(base$diagnostics$numerical_ok), info = info)
      if (model == "ALSCL") {
        expect_equal(fit$report$ZL, base$report$ZL, tolerance = 1e-7, info = info)
        expect_equal(ALSCL:::.acl_F_at_age(fit)$FA, ALSCL:::.acl_F_at_age(base)$FA, tolerance = 1e-6, info = info)
        expect_identical(is.null(fit$report$M_LAY), !name %in% c("matrix", "one_column", "length"))
      }
      # Stored inputs and summary name the form that was used.
      expect_identical(fit$recipe$args[names(forms[[name]])], forms[[name]])
      expect_length(summary(fit)$inputs, 1L)
      expect_output(print(fit), "Fixed inputs: ")
    }
    expect_null(summary(base)$inputs)
    expect_false(any(grepl("Fixed inputs", utils::capture.output(print(base)))))
  }
})

test_that("results of earlier versions without the new entries are still read", {
  skip_on_cran()
  for (model in c("ACL", "ALSCL")) {
    fit <- fit_fixture(model)$result
    legacy <- fit
    legacy$recipe$args$survey_q <- NULL
    legacy$recipe$args$survey_q_age <- NULL
    expect_false(any(c("survey_q", "survey_q_age") %in% names(legacy$recipe$args)))
    expect_null(summary(legacy)$inputs)
    expect_identical(extract_parameters(legacy), extract_parameters(fit))
    args <- ALSCL:::.acl_bundle_args(legacy$recipe$args, tolower(model))
    expect_false("survey_q" %in% names(args))
    expect_identical(ALSCL:::.acl_preflight(legacy$recipe$args, tolower(model))$setup$data,
                     ALSCL:::.acl_preflight(fit$recipe$args, tolower(model))$setup$data)
    expect_s3_class(plot_compare_selectivity(legacy, fit), "ggplot")
    projection <- function(x) project_model(x, F = c(.1, .2), recruitment = c(5, 7),
      weight = matrix(1, 9, 2), maturity = matrix(.5, 9, 2))
    expect_identical(projection(legacy), projection(fit))
    if (model == "ALSCL") expect_identical(ALSCL:::.acl_F_at_age(legacy), ALSCL:::.acl_F_at_age(fit))
    # A result without a recipe has no input forms to report.
    bare <- legacy; bare$recipe <- NULL
    expect_identical(ALSCL:::.acl_input_forms(bare), character())
    path <- tempfile(fileext = ".rds")
    save_assessment(legacy, path)
    stored <- read_assessment(path)
    expect_null(summary(stored)$inputs)
    unlink(path)
  }
})

test_that("assessment archives keep M by age and the survey catchability inputs", {
  skip_on_cran()
  f <- fit_fixture("ALSCL")
  M <- matrix(c(.3, .25, .2, .2), 4, 5) * rep(seq(1, 1.2, length.out = 5), each = 4)
  q <- exp(-((f$result$len_mid - 35) / 25)^2)
  args <- c(f$input, list(parameters = f$parameters, map = f$map, silent = TRUE))
  args$M <- M; args$sel_L50 <- args$sel_L95 <- NULL
  fit <- do.call(run_alscl, c(args, list(survey_q = q, survey_q_age = c(.4, .8, 1, 1))))
  expect_equal(fit$report$M_LAY[3, , ], M)
  expect_length(summary(fit)$inputs, 3L)
  path <- tempfile(fileext = ".rds")
  save_assessment(fit, path)
  stored <- read_assessment(path)
  unlink(path)
  expect_identical(stored$recipe$args$M, M)
  expect_identical(stored$recipe$args$survey_q, q)
  expect_identical(summary(stored)$inputs, summary(fit)$inputs)
  expect_identical(ALSCL:::.acl_F_at_age(stored), ALSCL:::.acl_F_at_age(fit))
  expect_identical(extract_estimates(stored, "FA")$estimate, as.numeric(ALSCL:::.acl_F_at_age(fit)$FA))
  again <- refit_model(stored, silent = TRUE)
  expect_equal(again$opt$objective, fit$opt$objective, tolerance = 1e-10)
  # The catchability plot shows the supplied curve.
  built <- ggplot2::ggplot_build(plot_compare_selectivity(stored, f$result, "a", "b"))$data[[1]]
  expect_equal(sort(built$y[built$group == 1]), sort(q))
  expect_error(refit_model(stored, sel_L50 = 20, sel_L95 = 30, silent = TRUE), "cannot be combined")

  # Simulation from the fit and sensitivity scenarios pass the inputs on.
  simulated <- simulate_fit(stored, nsim = 1, seed = 1, process = "resample")$simulations[[1]]
  expect_identical(simulated$x$fit_config$alscl$M, M)
  expect_identical(simulated$x$fit_config$alscl$survey_q_age, c(.4, .8, 1, 1))
  expect_true(check_alscl_data(simulated$x, "alscl")$valid)
  scenarios <- fit_scenarios(args, list(by_age = list(), single = list(M = .2),
    by_length = list(M = lorenzen_M(f$result$len_mid, .2, 40))), model = "alscl",
    survey_q = q, survey_q_age = c(.4, .8, 1, 1))
  expect_identical(scenarios$status$error, c("", "", ""))
  expect_equal(scenarios$fits$by_age$opt$objective, fit$opt$objective, tolerance = 1e-10)
  expect_identical(vapply(scenarios$fits, function(z) is.null(z$report$M_LAY), logical(1)),
                   c(by_age = FALSE, single = TRUE, by_length = FALSE))
})

test_that("retrospective peels and hindcast folds keep the time steps of M", {
  M <- matrix(seq(.1, .5, length.out = 20), 4, 5)
  expect_identical(ALSCL:::.acl_truncate_time(M, 5L, 3L), M[, 1:3])
  expect_identical(ALSCL:::.acl_truncate_time(M, 5L, 5L), M)
  expect_identical(ALSCL:::.acl_truncate_time(M[, 1, drop = FALSE], 5L, 3L), M[, 1, drop = FALSE])
  expect_identical(ALSCL:::.acl_truncate_time(.2, 5L, 3L), .2)
  expect_identical(ALSCL:::.acl_truncate_time(seq(.1, .9, by = .1), 5L, 3L), seq(.1, .9, by = .1))
  expect_identical(ALSCL:::.acl_truncate_time(M[, 1:4], 5L, 3L), M[, 1:4])  # wrong width: left for the fit to report
  expect_identical(ALSCL:::.acl_future_time(M, 5L, 3L, 2L), M[, 4:5])
  expect_null(ALSCL:::.acl_future_time(M[, 1, drop = FALSE], 5L, 3L, 2L))
  expect_null(ALSCL:::.acl_future_time(.2, 5L, 3L, 2L))

  f <- fixture_frames(); f$M <- M
  q_time <- matrix(seq(.2, 1, length.out = 45), 9, 5)
  fold <- ALSCL:::.acl_hindcast_args(c(f, list(map = NULL, survey_q = q_time)), 3L, "acl")
  expect_identical(fold$M, M[, 1:3])
  expect_identical(fold$survey_q, q_time[, 1:3])
  expect_identical(ncol(fold$data.CatL), 4L)

  seen <- list()
  handler <- function(args) {
    seen[[length(seen) + 1L]] <<- args
    list(year = as.numeric(colnames(args$data.CatL)[-1L]),
         report = list(B = 1, Rec = 1, SSB = 1, N = 1)[rep(1:4, 1)],
         opt = list(par = c(mean_log_R = 1), objective = 10, convergence = 0L),
         convergence_code = 0L, max_abs_gradient = 1e-8, pdHess = TRUE, bound_hit = FALSE,
         diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE, issues = character()))
  }
  mock <- function(model) {
    original <- if (model == "acl") run_acl else run_alscl
    arg_names <- names(formals(original))
    body(original) <- quote(handler(mget(arg_names, envir = environment())))
    environment(original) <- environment()
    original
  }
  local_mocked_bindings(run_acl = mock("acl"), run_alscl = mock("alscl"), .package = "ALSCL")
  x <- list(data.CatL = f$data.CatL, data.wgt = f$data.wgt, data.mat = f$data.mat,
            fit_args = list(rec.age = 1, nage = 4, M = M, sel_L50 = 20, sel_L95 = 30,
                            survey_q_age = c(.5, 1, 1, 1), map = list(mean_log_R = factor(NA))))
  for (model in c("acl", "alscl")) {
    seen <- list()
    suppressWarnings(retro_model(x, nyear = 2, model_type = model, silent = TRUE))
    expect_length(seen, 3L)
    expect_identical(lapply(seen, function(a) dim(a$M)), list(c(4L, 5L), c(4L, 4L), c(4L, 3L)))
    expect_identical(seen[[3]]$M, M[, 1:3])
    expect_identical(seen[[2]]$survey_q_age, c(.5, 1, 1, 1))
    # A fixed mean_log_R is derived once, with the shift for survey_q_age.
    totals <- colSums(as.matrix(f$data.CatL[-1]))
    for (a in seen) expect_equal(a$parameters$mean_log_R, log(mean(totals)) - log(.5))
    # Explicit arguments reach the fits as well.
    seen <- list()
    suppressWarnings(retro_model(x, nyear = 1, model_type = model, silent = TRUE,
                                 M = matrix(.3, 4, 1), survey_q = rep(.5, 9), sel_L50 = NULL, sel_L95 = NULL))
    expect_identical(seen[[2]]$M, matrix(.3, 4, 1))
    expect_identical(seen[[2]]$survey_q, rep(.5, 9))
    expect_null(seen[[2]]$sel_L50)
    # Survey catchability by length and time step is cut with the data.
    seen <- list()
    suppressWarnings(retro_model(x, nyear = 2, model_type = model, silent = TRUE,
                                 survey_q = q_time, sel_L50 = NULL, sel_L95 = NULL))
    expect_identical(lapply(seen, function(a) dim(a$survey_q)), list(c(9L, 5L), c(9L, 4L), c(9L, 3L)))
    expect_identical(seen[[3]]$survey_q, q_time[, 1:3])
  }
})

test_that("retrospective and hindcast fits run with M by age and time step", {
  skip_on_cran()
  M <- matrix(c(.3, .25, .2, .2), 4, 5) * rep(seq(1, 1.2, length.out = 5), each = 4)
  for (model in c("ACL", "ALSCL")) {
    f <- fit_fixture(model)
    x <- c(f$input, list(parameters = f$parameters, map = f$map))
    x$M <- M
    x$survey_q_age <- c(.6, 1, 1, .9)
    retro <- retro_model(x, nyear = 1, model_type = tolower(model), silent = TRUE)
    expect_identical(retro$fit_diagnostics$error, c("", ""))
    expect_true(all(retro$fit_diagnostics$numerical_ok))
    out <- hindcast_model(x, model = tolower(model), nfolds = 1, horizon = 2, save_fits = TRUE)
    expect_true(all(out$diagnostics$prediction_ok))
    expect_identical(out$recipes[[1]]$args$M, M[, 1:3])
    # The prediction uses M of the held-out time steps and the multiplier by age.
    fit <- out$fits[[1]]
    future <- project_model(fit, F = out$process_paths[[1]]$F, recruitment = out$process_paths[[1]]$recruitment,
      weight = matrix(1, 9, 2), maturity = matrix(.5, 9, 2), M = M[, 4:5])
    seen <- if (model == "ACL") fit$report$pla %*% (x$survey_q_age * future$states[["NA"]]) else
      apply(sweep(future$states$NLA, 2, x$survey_q_age, "*"), c(1, 3), sum)
    expect_equal(out$predictions$predicted_log, as.numeric(log(seen) + out$process_paths[[1]]$log_q),
                 tolerance = 1e-10)
    other <- x; other$M[, 4:5] <- other$M[, 4:5] * 2
    changed <- hindcast_model(other, model = tolower(model), nfolds = 1, horizon = 2)
    expect_identical(changed$predictions$predicted_log[1:9], out$predictions$predicted_log[1:9])
    expect_true(all(changed$predictions$predicted_log[10:18] < out$predictions$predicted_log[10:18]))
    # Survey catchability by time step: the training fit uses the training
    # columns and the prediction uses the columns of the held-out time steps.
    q <- stats::plogis(log(19) * (fit$len_mid - 20) / 10)
    by_time <- x; by_time$sel_L50 <- by_time$sel_L95 <- NULL
    by_time$survey_q <- cbind(matrix(q, 9, 3), 0.5 * q, 0.25 * q)
    shifted <- hindcast_model(by_time, model = tolower(model), nfolds = 1, horizon = 2)
    expect_identical(shifted$recipes[[1]]$args$survey_q, matrix(q, 9, 3))
    expect_equal(shifted$predictions$predicted_log - out$predictions$predicted_log,
                 rep(log(c(.5, .25)), each = 9), tolerance = 1e-6)
  }
})

test_that("projections use M by age or by length and reproduce the template", {
  skip_on_cran()
  for (model in c("ACL", "ALSCL")) {
    fixture <- cpp_fixture(model)
    d <- fixture$data
    A <- d$A; L <- d$L
    M <- matrix(seq(.05, .6, length.out = A * 4), A, 4)
    forms <- list(age_time = list(recipe = M[, 1:2], future = M[, 3:4],
      data = if (model == "ACL") list(M_AY = M) else list(M_LAY = aperm(array(M, c(A, 4, L)), c(3, 1, 2)))))
    if (model == "ALSCL") {
      rate <- lorenzen_M(d$len_mid, .2, 60)
      forms$length <- list(recipe = rate, future = NULL, data = list(M_LAY = array(rate, c(L, A, 4))))
    }
    for (name in names(forms)) {
      form <- forms[[name]]
      report <- ns_template(model, form$data)$report
      Fname <- if (model == "ACL") "F" else "FL"
      prefix <- report
      prefix[[Fname]] <- report[[Fname]][, 1:2, drop = FALSE]
      prefix[["NA"]] <- report[["NA"]][, 1:2, drop = FALSE]
      if (model == "ALSCL") prefix$NLA <- report$NLA[, , 1:2, drop = FALSE]
      fit <- list(model_type = model, report = prefix, year = c(2020, 2020.25), age = d$age,
        len_mid = d$len_mid, growth_step = .25, len_label = as.character(d$len_mid),
        recipe = list(args = list(M = form$recipe)))
      projection <- project_model(fit, report[[Fname]][, 3:4, drop = FALSE], report$Rec[3:4],
        d$weight[, 3:4, drop = FALSE], d$mat[, 3:4, drop = FALSE], M = form$future)
      info <- paste(model, name)
      expect_equal(unname(projection$states[["NA"]]), report[["NA"]][, 3:4], tolerance = 1e-12, info = info)
      expect_equal(unname(projection$states$NL), report$NL[, 3:4], tolerance = 1e-12, info = info)
      expect_equal(projection$summary$SSB, as.numeric(report$SSB[3:4]), tolerance = 1e-12, info = info)
      expect_equal(projection$summary$CN, as.numeric(report$CN[3:4]), tolerance = 1e-12, info = info)
      if (model == "ALSCL") {
        expect_equal(unname(projection$states$NLA), report$NLA[, , 3:4], tolerance = 1e-12, info = info)
        expect_equal(projection$summary$CB, as.numeric(report$CB[3:4]), tolerance = 1e-12, info = info)
      }
      if (name == "age_time") {
        expect_equal(unname(projection$biology$M), M[, 3:4])
        expect_equal(projection$assumptions$terminal_M, M[, 2])
        # A fitted rate that varies over time is not carried forward.
        expect_error(project_model(fit, report[[Fname]][, 3:4, drop = FALSE], report$Rec[3:4],
          d$weight[, 3:4, drop = FALSE], d$mat[, 3:4, drop = FALSE]),
          "varies over time, and no value is carried forward.*one per age class")
        expect_error(project_model(fit, report[[Fname]][, 3:4, drop = FALSE], report$Rec[3:4],
          d$weight[, 3:4, drop = FALSE], d$mat[, 3:4, drop = FALSE], M = matrix(.2, A + 1, 2)),
          "matrix with .* rows and 2 columns")
      } else {
        expect_equal(projection$biology$M, form$recipe)
      }
    }
    # A constant rate given by age gives the projection of the single rate.
    report <- ns_template(model)$report
    Fname <- if (model == "ACL") "F" else "FL"
    fit <- list(model_type = model, report = report, year = 2020 + (0:3) / 4, age = d$age,
      len_mid = d$len_mid, growth_step = .25, len_label = as.character(d$len_mid),
      recipe = list(args = list(M = d$M)))
    run <- function(M, fit_M = d$M) {
      fit$recipe$args$M <- fit_M
      project_model(fit, F = c(.1, .3), recruitment = c(50, 70), weight = d$weight[, 1:2], maturity = d$mat[, 1:2], M = M)
    }
    single <- run(NULL)
    for (other in list(run(matrix(d$M, A, 2)), run(matrix(d$M, A, 1)), run(NULL, matrix(d$M, A, 1)),
                       run(c(d$M, d$M), matrix(d$M, A, 4)))) {
      expect_equal(other$summary, single$summary, tolerance = 1e-13)
      expect_equal(other$states, single$states, tolerance = 1e-13)
      expect_equal(other$catch, single$catch, tolerance = 1e-13)
    }
  }
})

test_that("simulation functions state that they use a single natural mortality rate", {
  expect_error(sim_model(1, M = c(.2, .3)), "sim_model\\(\\) uses a single natural mortality rate")
  expect_error(sim_acl(1, M = matrix(.2, 2, 2)), "single natural mortality rate")
  expect_error(initialize_params(species = "flatfish", M = c(.2, .3)), "single natural mortality rate")
  expect_error(simulate_example_data(M = c(.2, .3)), "single natural mortality rate")
  p <- initialize_params(species = "flatfish", nyear = 5, burn_in = 1)
  bio <- sim_cal(p)
  p$M <- rep(.2, 3)
  expect_error(sim_data(bio, p, iter_range = 1, output_dir = tempfile()), "single natural mortality rate")
})

test_that("survey_catchability gives the logistic curve of sel_L50 and sel_L95 and a dome", {
  default <- ns_prepare()
  mid <- default$bins$mid
  logistic <- survey_catchability(mid, "logistic", L50 = 20, L95 = 30)
  expect_identical(logistic, stats::plogis(log(19) * (mid - 20) / (30 - 20)))
  expect_identical(survey_catchability(mid, L50 = 20, L95 = 30), logistic)
  expect_equal(survey_catchability(c(20, 30), "logistic", 20, 30), c(.5, .95))
  expect_equal(log(logistic), default$data$log_q, tolerance = 1e-14)
  expect_equal(ns_prepare(survey_q = logistic, sel_L50 = NULL, sel_L95 = NULL)$data$log_q,
               default$data$log_q, tolerance = 1e-14)

  dome <- function(x, minimum = 0) survey_catchability(x, "dome", L50 = 20, L95 = 30,
    L50_desc = 50, L95_desc = 40, minimum = minimum)
  fine <- seq(0, 200, by = .001)
  expect_equal(max(dome(fine)), 1, tolerance = 1e-8)
  expect_true(all(dome(fine) > 0 & dome(fine) <= 1))
  peak <- fine[which.max(dome(fine))]
  expect_true(peak > 30 && peak < 40)
  expect_true(all(diff(dome(fine[fine < peak])) > 0))
  expect_true(all(diff(dome(fine[fine > peak & fine < 120])) < 0))
  # The product of the two logistic curves, scaled by its maximum.
  product <- function(x, minimum = 0) stats::plogis(log(19) * (x - 20) / 10) *
    (minimum + (1 - minimum) * stats::plogis(-log(19) * (x - 50) / 10))
  expect_equal(dome(mid), product(mid) / max(product(fine)), tolerance = 1e-8)
  # The curve does not depend on the lengths at which it is evaluated.
  expect_identical(dome(mid)[3:5], dome(mid[3:5]))
  expect_lt(max(dome(mid)), 1)
  # The descending curve is 0.95 at L95_desc and 0.5 at L50_desc before scaling.
  expect_equal(dome(c(40, 50)) / dome(c(40, 50))[1],
               c(1, stats::plogis(log(19) * 3) * .5 / (stats::plogis(log(19) * 2) * .95)), tolerance = 1e-12)
  # A floor for the largest lengths.
  floor <- dome(fine, minimum = .3)
  expect_equal(max(floor), 1, tolerance = 1e-8)
  expect_equal(dome(1000, minimum = .3), .3 / max(product(fine, .3)), tolerance = 1e-8)
  expect_true(all(dome(c(60, 80, 100), .3) > dome(c(60, 80, 100))))
  expect_true(all(ALSCL:::.acl_survey_q(dome(mid, .3), 9, 5)$q == dome(mid, .3)))

  expect_error(survey_catchability(mid, "logistic", 30, 20), "L95 must be greater than L50")
  expect_error(survey_catchability(mid, "logistic", 20, 30, L50_desc = 50), "use shape = \"dome\"")
  expect_error(survey_catchability(mid, "logistic", 20, 30, minimum = .1), "use shape = \"dome\"")
  expect_error(survey_catchability(mid, "dome", 20, 30), "requires L50_desc and L95_desc")
  expect_error(survey_catchability(mid, "dome", 20, 30, L50_desc = 40, L95_desc = 50), "L95_desc must be below L50_desc")
  expect_error(survey_catchability(mid, "dome", 20, 30, L50_desc = 15, L95_desc = 10), "L50_desc must be greater than L50")
  expect_error(survey_catchability(mid, "dome", 20, 30, 50, 40, minimum = 1), "minimum must be at least 0 and below 1")
  expect_error(survey_catchability(mid, "dome", 20, 30, 50, 40, minimum = -.1), "minimum")
  expect_error(survey_catchability(c(mid, NA), "logistic", 20, 30), "finite lengths")
  expect_error(survey_catchability(mid, "logistic", c(20, 21), 30), "L50 must be one finite number")
  expect_error(survey_catchability(mid, "bell", 20, 30), "should be one of")
})

test_that("survey_q by length and time step is validated and passed to the templates", {
  default <- ns_prepare()
  q <- stats::plogis(log(19) * (default$bins$mid - 20) / 10)
  by_time <- cbind(matrix(q, 9, 3), matrix(.5 * q, 9, 2))
  x <- ns_prepare(survey_q = by_time, sel_L50 = NULL, sel_L95 = NULL)
  expect_equal(x$data$log_q_LY, log(by_time))
  expect_equal(x$data$log_q, log(q))
  for (model in c("ACL", "ALSCL"))
    expect_equal(ALSCL:::.acl_model_setup(model, x)$data$log_q_LY, log(by_time))
  # A matrix with one column is the vector by length.
  one_column <- ns_prepare(survey_q = matrix(q, ncol = 1), sel_L50 = NULL, sel_L95 = NULL)
  expect_null(one_column$data$log_q_LY)
  expect_equal(one_column$data$log_q, log(q))
  expect_null(default$data$log_q_LY)

  run <- function(value) ns_prepare(survey_q = value, sel_L50 = NULL, sel_L95 = NULL)
  expect_error(run(t(by_time)), "9 rows \\(one per length bin\\) and 5 columns \\(one per time step\\).*matrix with 5 rows and 9 columns.*transpose")
  expect_error(run(by_time[, 1:4]), "It is a matrix with 9 rows and 4 columns")
  expect_error(run(replace(by_time, 7, 0)), "finite positive values")
  expect_error(run(array(q, c(9, 5, 2))), "survey_q must be a numeric vector with 9")
  named <- by_time; colnames(named) <- 2000:2004
  expect_equal(run(named)$data$log_q_LY, log(by_time))
  colnames(named) <- c(2000:2003, 2010)
  expect_error(run(named), "column names of survey_q.*column 5 is named 2010 and the time step is 2004")
  expect_error(ns_prepare(survey_q = by_time), "cannot be combined")

  args <- list(M = .2, survey_q = by_time)
  expect_identical(ALSCL:::.acl_input_forms(list(recipe = list(args = args))),
                   "survey catchability at length and time step supplied as survey_q")
  args$survey_q <- q
  expect_identical(ALSCL:::.acl_input_forms(list(recipe = list(args = args))),
                   "survey catchability at length supplied as survey_q")

  # The catchability plot draws one line for each distinct curve.
  fit <- function(value) list(model_type = "ACL", len_mid = default$bins$mid,
    recipe = list(args = list(survey_q = value)))
  p <- plot_compare_selectivity(fit(by_time), fit(q), "by time", "constant")
  lines <- ggplot2::ggplot_build(p)$data[[1]]
  expect_length(unique(lines$group), 3L)
  expect_equal(sort(lines$y), sort(c(q, .5 * q, q)))
  expect_match(p$labels$caption, "one line for each distinct curve")
  constant <- plot_compare_selectivity(fit(matrix(q, 9, 5)), fit(q), "a", "b")
  expect_null(constant$labels$caption)
  expect_equal(sort(ggplot2::ggplot_build(constant)$data[[1]]$y), sort(c(q, q)))
})
