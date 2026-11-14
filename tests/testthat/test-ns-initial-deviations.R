# Deviations of the initial numbers at age: cumulative over ages (default)
# or independent by age, Equation 11 of Zhang and Cadigan (2022).

id_prepare <- function(structure = list()) {
  f <- fixture_frames()
  f$structure <- structure
  do.call(ALSCL:::.acl_prepare_data, f)
}

# Template report at fixed parameter values, without optimization.
id_report <- function(model, extra = list(), n_dev = NULL) {
  fixture <- cpp_fixture(model)
  p <- fixture$parameters
  p$log_init_Z <- log(.4)
  p$dev_log_R <- c(-.2, .1, .3, -.1)
  if (is.null(n_dev)) n_dev <- if (identical(extra$initial_deviations, 1L)) fixture$data$A else fixture$data$A - 1L
  p$dev_log_N0 <- seq(-.3, .25, length.out = n_dev)
  d <- fixture$data
  d[names(extra)] <- extra
  obj <- TMB::MakeADFun(d, p, DLL = fixture$info$dll_name, silent = TRUE)
  list(report = obj$report(obj$par), parameters = p, data = d)
}

# Numbers at age in the first period from Equation 11, computed in R.
id_equation_11 <- function(p, A, equilibrium = FALSE) {
  Z <- exp(p$log_init_Z)
  n <- exp(p$mean_log_R + p$dev_log_R[1L]) * exp(-Z * (seq_len(A) - 1) + p$dev_log_N0)
  if (equilibrium) n[A] <- n[A] / (1 - exp(-Z))
  n
}

test_that("the setting is accepted, validated and stored only when it is not the default", {
  for (model in c("ACL", "ALSCL")) {
    default <- ALSCL:::.acl_structure(list(), model)
    expect_null(default$choices$initial_deviations)
    expect_false("initial_deviations" %in% names(default$data))
    explicit <- ALSCL:::.acl_structure(list(initial_deviations = "cumulative"), model)
    expect_identical(explicit, default)
    independent <- ALSCL:::.acl_structure(list(initial_deviations = "independent"), model)
    expect_identical(independent$choices$initial_deviations, "independent")
    expect_identical(independent$data$initial_deviations, 1L)
    expect_error(ALSCL:::.acl_structure(list(initial_deviations = "additive"), model),
                 "structure\\$initial_deviations must be one of: \"cumulative\", \"independent\"")
  }
  expect_identical(ALSCL:::.acl_initial_deviations(list()), "cumulative")
  expect_identical(ALSCL:::.acl_initial_deviation_count(list(), 6L), 5L)
  expect_identical(ALSCL:::.acl_initial_deviation_count(list(initial_deviations = "independent"), 6L), 6L)
  # The setting is not part of the set "von_bertalanffy" and combines with it.
  expect_false("initial_deviations" %in% names(ALSCL:::.acl_structure_sets$von_bertalanffy))
  both <- ALSCL:::.acl_structure(list(set = "von_bertalanffy", initial_deviations = "independent"), "ALSCL")
  expect_identical(both$choices$initial_deviations, "independent")
  expect_identical(both$choices$initial_length, "growth")
  expect_identical(ALSCL:::.acl_structure(list(set = "von_bertalanffy", initial_deviations = "independent"),
                                          "ACL")$choices$initial_plus_group, "equilibrium")
})

test_that("the setting does not give the message about a part of the set von_bertalanffy", {
  expect_identical(ALSCL:::.acl_partial_set(list(initial_deviations = "independent")), character())
  expect_identical(ALSCL:::.acl_partial_set(list(initial_deviations = "independent", growth_increment = "von_bertalanffy",
    growth_transition = "bin", initial_length = "growth", initial_plus_group = "equilibrium")), character())
  expect_no_message(ALSCL:::.acl_partial_set_note(list(initial_deviations = "independent"), "ALSCL", FALSE))
  expect_message(ALSCL:::.acl_partial_set_note(list(initial_deviations = "independent", initial_length = "growth"),
                                               "ALSCL", FALSE), "leaves initial_plus_group")
})

test_that("the setup gives the template one deviation per age only with the independent form", {
  for (model in c("ACL", "ALSCL")) {
    default <- ALSCL:::.acl_model_setup(model, id_prepare())
    expect_length(default$parameters$dev_log_N0, default$data$A - 1L)
    expect_false("initial_deviations" %in% names(default$data))
    expect_null(default$structure$initial_deviations)
    independent <- ALSCL:::.acl_model_setup(model, id_prepare(list(initial_deviations = "independent")))
    expect_length(independent$parameters$dev_log_N0, independent$data$A)
    expect_identical(independent$data$initial_deviations, 1L)
    expect_identical(independent$structure$initial_deviations, "independent")
  }
})

test_that("ACL gives the numbers at age of Equation 11 under the independent form", {
  skip_on_cran()
  for (equilibrium in c(FALSE, TRUE)) {
    extra <- c(list(initial_deviations = 1L), if (equilibrium) list(initial_plus_group = 1L))
    x <- id_report("ACL", extra)
    expected <- id_equation_11(x$parameters, x$data$A, equilibrium)
    expect_equal(x$report[["NA"]][, 1L], expected, tolerance = 1e-12)
    # The reported recruitment of the first period has no age deviation.
    expect_equal(x$report$Rec[1L], exp(x$parameters$mean_log_R + x$parameters$dev_log_R[1L]), tolerance = 1e-12)
  }
})

test_that("ALSCL gives the numbers at length and age of Equation 11 under every initial-state setting", {
  skip_on_cran()
  for (equilibrium in c(FALSE, TRUE)) for (growth in c(FALSE, TRUE)) {
    extra <- c(list(initial_deviations = 1L), if (equilibrium) list(initial_plus_group = 1L),
               if (growth) list(initial_length = 1L))
    x <- id_report("ALSCL", extra)
    p <- x$parameters; A <- x$data$A; L <- x$data$L
    pla <- x$report$pla; G <- x$report$G; Z <- exp(p$log_init_Z)
    R1 <- exp(p$mean_log_R + p$dev_log_R[1L])
    expected <- matrix(NA_real_, L, A)
    if (!growth) {
      n <- id_equation_11(p, A, equilibrium)
      for (a in seq_len(A)) expected[, a] <- pla[, a] * n[a]
    } else {
      state <- R1 * pla[, 1L]
      expected[, 1L] <- state * exp(p$dev_log_N0[1L])
      for (a in 2:A) {
        state <- as.vector(G %*% state) * exp(-Z)
        if (a == A && equilibrium) state <- as.vector(solve(diag(L) - exp(-Z) * G, state))
        expected[, a] <- state * exp(p$dev_log_N0[a])
      }
      # Without growth beyond the length-at-age key the numbers at age are
      # those of Equation 11 when no plus group sum is taken.
      if (!equilibrium) expect_equal(colSums(expected), id_equation_11(p, A), tolerance = 1e-10)
    }
    expect_equal(x$report$NLA[, , 1L], expected, tolerance = 1e-10)
  }
})

test_that("the cumulative form is unchanged and the template checks the number of deviations", {
  skip_on_cran()
  for (model in c("ACL", "ALSCL")) {
    x <- id_report(model)
    p <- x$parameters; Z <- exp(p$log_init_Z)
    expected <- exp(p$mean_log_R + p$dev_log_R[1L] + cumsum(c(0, -Z + p$dev_log_N0)))
    expect_equal(x$report[["NA"]][, 1L], expected, tolerance = 1e-12)
    expect_identical(x$report$dev_log_N0, p$dev_log_N0)
    fixture <- cpp_fixture(model)
    d <- fixture$data; d$initial_deviations <- 1L
    expect_error(TMB::MakeADFun(d, fixture$parameters, DLL = fixture$info$dll_name, silent = TRUE),
                 "must have A entries")
  }
})

test_that("fits store the setting and simulate_fit() keeps the form of the fit", {
  skip_on_cran()
  base <- fit_fixture("ACL")
  args <- c(base$input, list(parameters = base$parameters, map = base$map, silent = TRUE,
    structure = list(initial_deviations = "independent")))
  fit <- do.call(run_acl, args)
  expect_identical(fit$structure$initial_deviations, "independent")
  expect_length(fit$report$dev_log_N0, base$input$nage)
  expect_null(base$result$structure$initial_deviations)
  expect_length(base$result$report$dev_log_N0, base$input$nage - 1L)
  sims <- if (isTRUE(fit$diagnostics$numerical_ok)) simulate_fit(fit, nsim = 2, seed = 3, process = "resample") else
    expect_warning(simulate_fit(fit, nsim = 2, seed = 3, process = "resample", allow_failed_fit = TRUE), "failed")
  for (s in sims$simulations) {
    expect_length(s$truth$random_effects$dev_log_N0, base$input$nage)
    # Initial numbers of the drawn population follow Equation 11.
    p <- s$truth$parameters
    expect_equal(s$truth[["NA"]][, 1L], exp(p[["mean_log_R"]] + s$truth$random_effects$dev_log_R[1L] -
      exp(p[["log_init_Z"]]) * (seq_len(base$input$nage) - 1) + s$truth$random_effects$dev_log_N0), tolerance = 1e-10)
    expect_identical(s$x$fit_config$acl$structure, list(initial_deviations = "independent"))
  }
})

test_that("sim_model() checks the structure of the fitted model", {
  expect_error(sim_model(iter_range = 1, sim_data_path = tempfile(), structure = list(initial_deviations = "both")),
               "structure\\$initial_deviations must be one of")
  expect_identical(formals(sim_model)$structure, quote(list()))
  expect_identical(formals(sim_acl)$structure, quote(list()))
})

# Simulator: the first-year numbers at age from the draws of one replicate.
id_simulate <- function(form, iter = 7, species = "flatfish", extra = list(), ...) {
  pa <- initialize_params(species = species, nyear = if (species == "tuna") 2 else 3, burn_in = 0,
                          random_numbers = "by_process", std_logN0 = .3, ...)
  if (!is.null(form)) pa$structure <- c(list(initial_deviations = form), extra)
  else if (length(extra)) pa$structure <- extra
  bio <- sim_cal(pa)
  folder <- tempfile("initial-deviations")
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  invisible(capture.output(sm <- sim_data(bio, pa, iter_range = iter, output_dir = folder)))
  set.seed(iter, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  streams <- sample.int(.Machine$integer.max, 4L)
  nstep <- round(pa$nyear / pa$growth_step)
  R1 <- pa$R_init * exp(ALSCL:::.acl_simulation_normal(nstep, streams, 1L, pa$R_ar)[1L] * pa$std_logR)
  z <- ALSCL:::.acl_simulation_normal(pa$nage, streams, 3L) * pa$std_logN0
  list(sm = sm, pa = pa, bio = bio, R1 = R1, z = z)
}

test_that("the simulator generates initial numbers with either form", {
  skip_on_cran()
  cumulative <- id_simulate("cumulative")
  A <- cumulative$pa$nage; Z <- cumulative$pa$init_Z
  expect_equal(cumulative$sm$N_at_age[1L, ], cumulative$R1 * exp(cumsum(c(0, -Z + cumulative$z[seq_len(A - 1L)]))),
               tolerance = 1e-12)
  default <- id_simulate(NULL)
  expect_identical(default$sm[names(default$sm) != "provenance"], cumulative$sm[names(cumulative$sm) != "provenance"])
  independent <- id_simulate("independent")
  dev <- independent$z[c(A, seq_len(A - 1L))]
  expect_equal(independent$sm$N_at_age[1L, ], independent$R1 * exp(-Z * (seq_len(A) - 1) + dev), tolerance = 1e-12)
  # Same draws for recruitment, F and survey errors in the two forms.
  expect_equal(independent$sm$F_at_age, cumulative$sm$F_at_age)
  equilibrium <- id_simulate("independent", extra = list(initial_plus_group = "equilibrium"))
  expect_equal(equilibrium$sm$N_at_age[1L, A], independent$sm$N_at_age[1L, A] / (1 - exp(-Z)), tolerance = 1e-12)
  expect_equal(equilibrium$sm$N_at_age[1L, -A], independent$sm$N_at_age[1L, -A], tolerance = 1e-12)
})

test_that("the simulator combines independent deviations with initial lengths from growth", {
  skip_on_cran()
  for (equilibrium in c(FALSE, TRUE)) {
    extra <- c(list(initial_length = "growth"), if (equilibrium) list(initial_plus_group = "equilibrium"))
    x <- id_simulate("independent", species = "tuna", extra = extra)
    A <- x$pa$nage; L <- length(x$pa$len_mid); Z <- x$pa$init_Z
    G <- x$bio$Gij; pla <- x$bio$pla
    dev <- x$z[c(A, seq_len(A - 1L))]
    state <- x$R1 * pla[, 1L]; nla <- matrix(NA_real_, L, A); nla[, 1L] <- state * exp(dev[1L])
    for (a in 2:A) {
      state <- as.vector(G %*% state) * exp(-Z)
      if (a == A && equilibrium) state <- as.vector(solve(diag(L) - exp(-Z) * G, state))
      nla[, a] <- state * exp(dev[a])
    }
    expect_equal(x$sm$N_at_age[1L, ], colSums(nla), tolerance = 1e-10)
    expect_equal(x$sm$N_at_len[1L, ], rowSums(nla), tolerance = 1e-10)
  }
})

test_that("increments of the initial log numbers are uncorrelated only under the cumulative form", {
  skip_on_cran()
  increments <- function(form) {
    pa <- initialize_params(species = "flatfish", nyear = 2, burn_in = 0, nage = 8, std_logN0 = .3)
    pa$structure <- list(initial_deviations = form)
    bio <- sim_cal(pa); folder <- tempfile("initial-deviations")
    on.exit(unlink(folder, recursive = TRUE), add = TRUE)
    invisible(capture.output(sim_data(bio, pa, iter_range = 1:300, output_dir = folder)))
    t(vapply(1:300, function(i) {
      e <- new.env(); load(file.path(folder, paste0("sim_rep", i)), e)
      diff(log(e$sim.data$N_at_age[1L, ])) + pa$init_Z
    }, numeric(7)))
  }
  lag_correlation <- function(x) stats::cor(as.vector(x[, -ncol(x)]), as.vector(x[, -1L]))
  cumulative <- increments("cumulative"); independent <- increments("independent")
  # Cumulative: independent increments of SD 0.3. Independent: increments
  # e(a) - e(a - 1) of SD 0.3 * sqrt(2) with lag-one correlation -0.5.
  expect_lt(abs(lag_correlation(cumulative)), .12)
  expect_lt(abs(lag_correlation(independent) + .5), .12)
  expect_lt(abs(stats::sd(as.vector(cumulative)) / .3 - 1), .1)
  expect_lt(abs(stats::sd(as.vector(independent)) / (.3 * sqrt(2)) - 1), .1)
})
