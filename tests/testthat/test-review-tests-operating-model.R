# Review finding F30: the operating models in R/sim_data.R and R/sim_cal.R
# compute the same population as the estimation templates when the template
# is given the operating model's parameters and realized processes. This file
# enforces that identity, so a change to growth, the plus group, mortality or
# selectivity on one side only fails here and is not later read as estimation
# bias in a simulation study.
#
# The simulated data pass through the package's own preparation path
# (.acl_simulation_to_tables, .acl_prepare_data, .acl_model_setup).
#
# The length-based operating model is compared with ALSCL at burn_in = 0 only.
# With a burn-in the operating model's first observed state has grown through
# Gij, while ALSCL starts from the length-at-age key (review finding F04), so
# the two differ by construction.

review_operating_model <- function(species, ..., seed = 7L) {
  folder <- withr::local_tempdir(.local_envir = parent.frame())
  params <- initialize_params(species = species, first.year = 2000, ...)
  bio <- sim_cal(params)
  utils::capture.output(sm <- sim_data(bio, params, iter_range = seed, output_dir = folder))
  tables <- ALSCL:::.acl_simulation_to_tables(sm)
  prepared <- ALSCL:::.acl_prepare_data(tables$data.CatL, tables$data.wgt, tables$data.mat,
    rec.age = sm$ages[1L], nage = sm$nage, M = params$M,
    sel_L50 = params$q_surv_L50, sel_L95 = params$q_surv_L95,
    growth_step = sm$growth_step, len_mid = sm$len_mid, len_border = sm$len_border)
  model <- if (params$model_type == "length_based") "ALSCL" else "ACL"
  setup <- ALSCL:::.acl_model_setup(model, prepared)
  p <- setup$parameters
  p$log_Linf <- log(params$Linf); p$log_vbk <- log(params$vbk); p$log_cv_len <- log(params$cv_L)
  # Realized recruitment, fishing mortality and first-period numbers at age
  # enter as deviations around zero means.
  p$mean_log_R <- 0; p$dev_log_R <- log(sm$Rec)
  p$mean_log_F <- 0
  p$log_init_Z <- log(params$init_Z)
  p$dev_log_N0 <- diff(log(sm$N_at_age[1L, ])) + params$init_Z
  if (model == "ACL") {
    p$t0 <- params$t0
    p$dev_log_F <- t(log(sm$F_at_age))
  } else {
    p$log_t0 <- log(params$t0); p$log_cv_grow <- log(params$cv_inc)
    p$dev_log_F <- t(log(sm$F_at_len))
  }
  list(model = model, params = params, bio = bio, sm = sm, data = setup$data, parameters = p,
       report = ref_tmb_joint(model, setup$data, p)$report)
}

expect_same_population <- function(actual, expected, label, tolerance = 1e-10) {
  expect_identical(dim(as.matrix(actual)), dim(as.matrix(expected)), label = paste(label, "dimensions"))
  expect_lt(ref_relative_difference(actual, expected), tolerance,
            label = paste(label, "largest relative difference"))
}

test_that("the age-based operating model reproduces the ACL template (F30)", {
  for (burn_in in c(0, 2)) {
    x <- review_operating_model("flatfish", nyear = 10 + burn_in, burn_in = burn_in)
    r <- x$report; sm <- x$sm; label <- paste("flatfish, burn_in", burn_in, ":")
    expect_identical(x$model, "ACL")
    expect_identical(dim(r$NL), c(x$data$L, 10L))
    expect_lt(max(abs(r$pla - t(x$bio$pla))), 1e-12, label = paste(label, "max |pla difference|"))
    expect_same_population(r[["NA"]], t(sm$N_at_age), paste(label, "numbers at age"))
    expect_same_population(r$NL, t(sm$N_at_len), paste(label, "numbers at length"))
    expect_same_population(r$SSB, sm$SSB, paste(label, "SSB"))
    expect_same_population(r$B, sm$TB, paste(label, "total biomass"))
    expect_same_population(r$N, sm$TN, paste(label, "total numbers"))
    expect_same_population(r$Rec, sm$Rec, paste(label, "recruitment"))
    expect_same_population(r$F, t(sm$F_at_age), paste(label, "F at age"))
    expect_same_population(r$CNA, t(sm$CN_at_age), paste(label, "catch numbers at age"))
    expect_same_population(r$CN, sm$CN, paste(label, "catch numbers"))
    # ACL does not report catch biomass; build it from its catch at age.
    catch_biomass <- colSums((r$pla %*% r$CNA) * x$data$weight)
    expect_same_population(catch_biomass, sm$CB, paste(label, "catch biomass"))
    expect_lt(max(abs(r$Elog_index - log(t(sm$N_at_len) * sm$q_surv))), 1e-10,
              label = paste(label, "max |expected log index difference|"))
    # The R reference dynamics give the same population as both.
    reference <- ref_acl_dynamics(x$data, x$parameters)
    expect_same_population(reference$NL, t(sm$N_at_len), paste(label, "reference numbers at length"))
    expect_same_population(reference$SSB, sm$SSB, paste(label, "reference SSB"))
  }
})

test_that("the length-based operating model reproduces the ALSCL template without burn-in (F30)", {
  x <- review_operating_model("tuna", nyear = 4, burn_in = 0)
  r <- x$report; sm <- x$sm; label <- "tuna, burn_in 0:"
  expect_identical(x$model, "ALSCL")
  expect_identical(dim(r$NL), c(x$data$L, 16L))
  expect_equal(x$data$growth_step, .25)
  expect_lt(max(abs(r$pla - x$bio$pla)), 1e-12, label = paste(label, "max |pla difference|"))
  expect_lt(max(abs(r$G - x$bio$Gij)), 1e-12, label = paste(label, "max |G - Gij|"))
  expect_same_population(r[["NA"]], t(sm$N_at_age), paste(label, "numbers at age"))
  expect_same_population(r$NL, t(sm$N_at_len), paste(label, "numbers at length"))
  expect_same_population(r$SSB, sm$SSB, paste(label, "SSB"))
  expect_same_population(r$B, sm$TB, paste(label, "total biomass"))
  expect_same_population(r$N, sm$TN, paste(label, "total numbers"))
  expect_same_population(r$Rec, sm$Rec, paste(label, "recruitment"))
  expect_same_population(r$FL, t(sm$F_at_len), paste(label, "F at length"))
  expect_same_population(r$CNL, t(sm$CN_at_len), paste(label, "catch numbers at length"))
  expect_same_population(r$CNA, t(sm$CN_at_age), paste(label, "catch numbers at age"))
  expect_same_population(r$CN, sm$CN, paste(label, "catch numbers"))
  expect_same_population(r$CB, sm$CB, paste(label, "catch biomass"))
  expect_lt(max(abs(r$Elog_index - log(t(sm$N_at_len) * sm$q_surv))), 1e-10,
            label = paste(label, "max |expected log index difference|"))
  reference <- ref_alscl_dynamics(x$data, x$parameters)
  expect_same_population(reference$NL, t(sm$N_at_len), paste(label, "reference numbers at length"))
  expect_same_population(reference$SSB, sm$SSB, paste(label, "reference SSB"))
})

test_that("a burn-in separates the length-based operating model from ALSCL (F04, current behaviour)", {
  # Characterization, not a requirement: after one year of burn-in the
  # operating model's length composition at age has passed through Gij, and
  # the template's first period has not. Numbers at age still agree.
  x <- review_operating_model("tuna", nyear = 2, burn_in = 1)
  expect_same_population(x$report[["NA"]][, 1L], x$sm$N_at_age[1L, ], "first-period numbers at age")
  expect_gt(ref_relative_difference(x$report$NL[, 1L], x$sm$N_at_len[1L, ]), .05)
})
