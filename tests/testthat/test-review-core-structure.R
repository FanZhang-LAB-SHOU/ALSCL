# Optional model structures (findings F03, F04, F05, F06): the default is the
# original structure; the alternatives make the first period follow the same
# growth and mortality as later periods and make growth follow the von
# Bertalanffy curve.

structure_fixture <- function(model, flags = list(), width = 5, step = .25, A = 12L, Y = 30L,
                              Linf = 152, vbk = .38, F = exp(-40)) {
  border <- seq(10 + width, 180, by = width)
  mid <- c(border[1] - width / 2, border + width / 2)
  L <- length(mid)
  p <- create_parameters(model_type = tolower(model))$parameters
  p$log_Linf <- log(Linf); p$log_vbk <- log(vbk); p$mean_log_F <- log(F); p$log_init_Z <- log(.2)
  p$dev_log_R <- rep(0, Y); p$dev_log_N0 <- rep(0, A - 1L)
  p$dev_log_F <- array(0, c(if (model == "ACL") A else L, Y))
  d <- list(logN_at_len = matrix(1, L, Y), na_matrix = matrix(1, L, Y), log_q = rep(0, L),
    len_border = border, age = step * seq_len(A), Y = Y, A = A, L = L,
    weight = matrix(1e-5 * mid^3, L, Y), mat = matrix(stats::plogis((mid - 90) / 5), L, Y), M = .2)
  if (model == "ALSCL")
    d <- c(d, list(len_mid = mid, len_lower = c(-Inf, border), len_upper = c(border, Inf), growth_step = step))
  obj <- TMB::MakeADFun(c(d, flags), p, DLL = ALSCL:::.acl_compile(model)$dll_name, silent = TRUE)
  list(obj = obj, report = obj$report(), mid = mid, border = border, step = step, Linf = Linf, vbk = vbk)
}

test_that("structure settings are validated and default to the original structure", {
  default <- ALSCL:::.acl_structure(list(), "ALSCL")
  expect_identical(default$choices, list(initial_plus_group = "single_cohort",
    initial_length = "length_at_age", growth_increment = "logistic", growth_transition = "midpoint",
    correlation_range = "positive"))
  expect_length(default$data, 0L)
  chosen <- ALSCL:::.acl_structure(list(growth_transition = "bin", initial_plus_group = "equilibrium"), "ALSCL")
  expect_identical(chosen$data, list(initial_plus_group = 1L, growth_transition = 1L))
  expect_identical(names(ALSCL:::.acl_structure(NULL, "ACL")$choices), c("initial_plus_group", "correlation_range"))
  expect_error(ALSCL:::.acl_structure(list(growth_increment = "von_bertalanffy"), "ACL"), "applies to ALSCL only")
  expect_silent(ALSCL:::.acl_structure(list(growth_increment = "logistic"), "ACL"))
  expect_error(ALSCL:::.acl_structure(list(growth = "vb"), "ALSCL"), "Unknown structure setting: growth")
  expect_error(ALSCL:::.acl_structure(list(growth_increment = "vb"), "ALSCL"), "must be one of")
  expect_error(ALSCL:::.acl_structure("bin", "ALSCL"), "named list")
})

test_that("the growth matrix of each structure matches its R counterpart", {
  skip_on_cran()
  for (increment in c("logistic", "von_bertalanffy")) for (transition in c("midpoint", "bin")) {
    if (increment == "logistic" && transition == "midpoint") next
    flags <- list(growth_increment = (increment == "von_bertalanffy") * 1,
                  growth_transition = (transition == "bin") * 1)
    for (step in c(1, .25)) {
      f <- structure_fixture("ALSCL", flags, step = step, A = 3L, Y = 2L)
      expected <- ALSCL:::.acl_growth_matrix(f$mid, f$border, f$Linf, f$vbk, .3, step, increment, transition)
      expect_equal(f$report$G, expected, tolerance = 1e-12)
      expect_equal(colSums(f$report$G), rep(1, length(f$mid)), tolerance = 1e-12)
      expect_true(all(f$report$G[upper.tri(f$report$G)] == 0))
      expect_true(all(is.finite(f$obj$gr())))
    }
  }
})

test_that("the von Bertalanffy increment with bin integration follows the growth curve", {
  skip_on_cran()
  cohort_mean <- function(flags, width) {
    f <- structure_fixture("ALSCL", flags, width = width, A = 3L, Y = 2L)
    n <- as.numeric(seq_along(f$mid) == which.min(abs(f$mid - 40)))
    start <- sum(n * f$mid)
    for (i in 1:40) n <- as.vector(f$report$G %*% n)
    c(mean = sum(n * f$mid), curve = f$Linf - (f$Linf - start) * exp(-f$vbk * 10))
  }
  corrected <- list(growth_increment = 1, growth_transition = 1)
  for (width in c(1, 5)) {
    result <- cohort_mean(corrected, width)
    expect_lt(abs(result[["mean"]] - result[["curve"]]), 2)
  }
  # Original structure: growth stalls with wide bins (documented behaviour).
  original <- cohort_mean(list(), 5)
  expect_lt(original[["mean"]], original[["curve"]] - 20)
})

test_that("integration over the source bin does not stall and is smooth in Linf", {
  grid <- function(width) {
    border <- seq(10 + width, 180, by = width)
    list(mid = c(border[1] - width / 2, border + width / 2), border = border)
  }
  cohort_mean <- function(Linf, vbk, width, step, years, cv = .3) {
    g <- grid(width)
    G <- ALSCL:::.acl_growth_matrix(g$mid, g$border, Linf, vbk, cv, step, "von_bertalanffy", "bin")
    n <- as.numeric(seq_along(g$mid) == which.min(abs(g$mid - 40)))
    start <- sum(n * g$mid)
    for (i in seq_len(round(years / step))) n <- as.vector(G %*% n)
    c(mean = sum(n * g$mid), curve = Linf - (Linf - start) * exp(-vbk * years))
  }
  # Increments far below the bin width: slow growth, 5-cm bins, quarterly and
  # monthly steps over 60 years. A rule with a few nodes per bin stalled at
  # 131 to 143 cm here.
  for (step in c(.25, 1 / 12)) {
    result <- cohort_mean(150, .1, 5, step, 60)
    expect_lt(abs(result[["mean"]] - result[["curve"]]), 1)
  }
  wide <- cohort_mean(152, .38, 10, .25, 60)
  expect_lt(abs(wide[["mean"]] - wide[["curve"]]), 4)
  # Mean length at age 10 rises steadily with Linf; steps of uneven size would
  # give the likelihood several optima in Linf about one bin width apart.
  Linf <- seq(148, 160, by = .5)
  means <- vapply(Linf, function(x) cohort_mean(x, .38, 5, .25, 10, cv = .1)[["mean"]], numeric(1))
  expect_true(all(diff(means) > .4 & diff(means) < .6))
  # The closed form agrees with direct numerical integration over the bin.
  g <- grid(5)
  closed <- ALSCL:::.acl_growth_matrix(g$mid, g$border, 152, .38, .3, .25, "von_bertalanffy", "bin")
  j <- 20L; n <- 20000L
  x <- g$border[j - 1L] + (g$border[j] - g$border[j - 1L]) * (seq_len(n) - .5) / n
  m <- ALSCL:::.acl_growth_increment(x, 152, .38, .25, "von_bertalanffy")
  cdf <- vapply(g$border, function(b) mean(stats::pnorm((b - x - m) / (.3 * m + 1e-12 * 152))), numeric(1))
  direct <- diff(c(0, cdf, 1)); direct[seq_len(j - 1L)] <- 0; direct[j] <- cdf[j]
  expect_equal(closed[, j], direct / sum(direct), tolerance = 1e-3)
  expect_equal(ALSCL:::.acl_mean_pnorm(c(2, 1e-10, 40), c(-1, 0, 30)),
               c(stats::integrate(stats::pnorm, -1, 2)$value / 3, .5, 1), tolerance = 1e-8)
})

test_that("a population with constant recruitment and no fishing stays constant with the initial state generated by the dynamics", {
  skip_on_cran()
  ratio <- function(model, flags, ...) {
    r <- structure_fixture(model, flags, ...)$report
    c(SSB = r$SSB[length(r$SSB)] / r$SSB[1], N = r$N[length(r$N)] / r$N[1])
  }
  expect_equal(unname(ratio("ACL", list(initial_plus_group = 1))), c(1, 1), tolerance = 1e-8)
  expect_gt(abs(ratio("ACL", list())[["SSB"]] - 1), .01)
  initial <- list(initial_length = 1, initial_plus_group = 1)
  expect_equal(unname(ratio("ALSCL", initial)), c(1, 1), tolerance = 1e-8)
  expect_equal(unname(ratio("ALSCL", initial, step = 1)), c(1, 1), tolerance = 1e-8)
  expect_equal(unname(ratio("ALSCL", c(initial, list(growth_increment = 1, growth_transition = 1)))),
               c(1, 1), tolerance = 1e-8)
  # Each setting alone is not enough, and the original structure drifts.
  expect_gt(abs(ratio("ALSCL", list())[["SSB"]] - 1), .01)
  expect_gt(abs(ratio("ALSCL", list(initial_plus_group = 1))[["SSB"]] - 1), .01)
  expect_gt(abs(ratio("ALSCL", list(initial_length = 1))[["SSB"]] - 1), .01)
})

test_that("the equilibrium plus group holds the sum of all older cohorts", {
  skip_on_cran()
  single <- structure_fixture("ACL", list())$report[["NA"]][, 1]
  summed <- structure_fixture("ACL", list(initial_plus_group = 1))$report[["NA"]][, 1]
  A <- length(single)
  expect_equal(summed[-A], single[-A], tolerance = 1e-12)
  expect_equal(summed[A], single[A] / (1 - exp(-.2)), tolerance = 1e-12)
  # ALSCL: the same total numbers at age whichever way lengths are assigned.
  for (flags in list(list(initial_plus_group = 1), list(initial_plus_group = 1, initial_length = 1)))
    expect_equal(structure_fixture("ALSCL", flags)$report[["NA"]][, 1], summed, tolerance = 1e-10)
})

test_that("fits store the structure and pass only non-default settings to the template", {
  skip_on_cran()
  f <- fixture_frames()
  f$data.CatL[[1]] <- as.character(seq(15, 55, 5)); f$data.wgt[[1]] <- f$data.mat[[1]] <- f$data.CatL[[1]]
  prepared <- do.call(ALSCL:::.acl_prepare_data, f)
  expect_null(ALSCL:::.acl_model_setup("ALSCL", prepared)$data$growth_increment)
  prepared <- do.call(ALSCL:::.acl_prepare_data, c(f, list(structure = list(growth_increment = "von_bertalanffy",
    growth_transition = "bin", initial_length = "growth", initial_plus_group = "equilibrium"))))
  setup <- ALSCL:::.acl_model_setup("ALSCL", prepared)
  expect_identical(setup$data[c("initial_plus_group", "initial_length", "growth_increment", "growth_transition")],
    list(initial_plus_group = 1L, initial_length = 1L, growth_increment = 1L, growth_transition = 1L))
  p <- create_parameters("alscl")$parameters
  p$log_sigma_index <- log(.2); p$log_sigma_log_N0 <- log(.1); p$log_sigma_log_R <- log(.1)
  mapping <- lapply(p, function(x) factor(NA)); mapping$mean_log_R <- NULL
  args <- c(f, list(parameters = p, map = mapping, silent = TRUE,
    structure = list(growth_increment = "von_bertalanffy", growth_transition = "bin",
                     initial_length = "growth", initial_plus_group = "equilibrium")))
  fit <- do.call(run_alscl, args)
  expect_identical(fit$structure$growth_increment, "von_bertalanffy")
  expect_identical(fit$recipe$args$structure$initial_length, "growth")
  expect_true(fit$diagnostics$numerical_ok)
  expect_equal(fit$report$G, ALSCL:::.acl_growth_matrix(fit$len_mid, fit$len_border, fit$report$Linf,
    fit$report$vbk, fit$report$cv_grow, 1, "von_bertalanffy", "bin"), tolerance = 1e-12)
  default <- do.call(run_alscl, args[setdiff(names(args), "structure")])
  expect_identical(default$structure$growth_increment, "logistic")
  expect_false(isTRUE(all.equal(default$report$SSB, fit$report$SSB)))
  expect_error(run_acl(c(f, list(structure = list(initial_length = "growth")))), "applies to ALSCL only")
})

test_that("the operating model uses the same structures as the template", {
  skip_on_cran()
  params <- initialize_params(species = "tuna", nyear = 30, burn_in = 20)
  params$structure <- list(growth_increment = "von_bertalanffy", growth_transition = "bin",
                           initial_length = "growth", initial_plus_group = "equilibrium")
  bio <- sim_cal(params)
  expect_identical(bio$biology_inputs$growth_increment, "von_bertalanffy")
  expect_equal(bio$Gij, ALSCL:::.acl_growth_matrix(params$len_mid, params$len_border[-c(1, length(params$len_border))],
    params$Linf, params$vbk, params$cv_inc, params$growth_step, "von_bertalanffy", "bin"), tolerance = 1e-14)
  default <- sim_cal(initialize_params(species = "tuna", nyear = 30, burn_in = 20))
  expect_false(isTRUE(all.equal(default$Gij, bio$Gij)))
  expect_null(default$biology_inputs$growth_increment)
  out <- withr::local_tempdir()
  utils::capture.output(sim <- sim_data(bio, params, output_dir = out, iter_range = 4))
  expect_true(all(is.finite(sim$SSB)))
  # A changed structure is detected as changed biology.
  other <- params; other$structure <- list(growth_transition = "bin")
  expect_error(sim_data(bio, other, output_dir = out, iter_range = 4))
})
