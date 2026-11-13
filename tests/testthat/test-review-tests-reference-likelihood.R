# Review finding F47: the joint negative log-likelihood of both templates is
# compared with the independent R reference in helper-review-reference.R.
#
# The fixture has unequal length-bin widths, missing and zero survey cells,
# nonzero random effects and different F correlations for the group and time
# dimensions. Observations are drawn around the reference prediction, so each
# likelihood part has an ordinary size and none dominates the comparison.

review_likelihood_fixture <- function(model, F_structure, growth_step, seed = 11L) {
  restore_rng <- ALSCL:::.acl_preserve_rng()
  on.exit(restore_rng(), add = TRUE)
  set.seed(seed)
  len_border <- c(12, 18, 25, 33, 40, 52, 60, 75)
  len_mid <- c(8, 15, 21.5, 29, 36.5, 46, 56, 67.5, 82)
  L <- length(len_mid); A <- 5L; Y <- 6L
  acl <- model == "ACL"
  start <- list(log_Linf = log(95), log_vbk = log(.3), log_cv_len = log(.15),
                log_init_Z = log(.35), mean_log_R = 6, mean_log_F = log(.12),
                logit_log_R = qlogis(.45), logit_log_F_y = qlogis(.8))
  start[[if (acl) "t0" else "log_t0"]] <- if (acl) -.1 else log(.1)
  start[[if (acl) "logit_log_F_a" else "logit_log_F_l"]] <- qlogis(.3)
  start[[if (acl) "log_std_log_F" else "log_sigma_log_F"]] <- log(.6)
  start[[if (acl) "log_std_log_R" else "log_sigma_log_R"]] <- log(.4)
  start[[if (acl) "log_std_log_N0" else "log_sigma_log_N0"]] <- log(.3)
  start[[if (acl) "log_std_index" else "log_sigma_index"]] <- log(.25)
  if (!acl) start$log_cv_grow <- log(.25)
  weight <- matrix(runif(L * Y, .1, 2), L, Y)
  maturity <- matrix(runif(L * Y), L, Y)
  build <- function(observations) ref_model_inputs(model, observations, len_mid, len_border,
    rec.age = if (growth_step < 1) .5 else 1, nage = A, M = .07, growth_step = growth_step,
    weight = weight, maturity = maturity, sel_L50 = 30, sel_L95 = 45,
    parameters = start, F_structure = F_structure)
  x <- build(matrix(1, L, Y))
  p <- x$parameters
  p$dev_log_R <- rnorm(Y, 0, .4)
  p$dev_log_F[] <- rnorm(length(p$dev_log_F), 0, .5)
  p$dev_log_N0 <- rnorm(A - 1L, 0, .3)
  expected <- ref_dynamics(model, x$data, p)$Elog_index
  observations <- exp(expected + rnorm(L * Y, 0, .25))
  observations[2, 3] <- NA
  observations[9, 6] <- NA
  observations[5, 1] <- 0
  x <- build(observations)
  x$parameters <- p
  x
}

test_that("joint TMB likelihood equals the independent R likelihood (F47)", {
  for (model in c("ACL", "ALSCL")) for (F_structure in c("group_year", "year"))
    for (growth_step in c(1, .25)) {
      label <- paste(model, F_structure, "growth_step", growth_step)
      x <- review_likelihood_fixture(model, F_structure, growth_step)
      d <- x$data; p <- x$parameters
      expect_equal(sum(d$na_matrix == 0), 3, label = paste(label, "missing cells"))
      expect_equal(nrow(p$dev_log_F),
                   if (F_structure == "year") 1L else if (model == "ACL") d$A else d$L,
                   label = label)
      compiled <- ref_tmb_joint(model, d, p)
      dynamics <- ref_dynamics(model, d, p)
      reference <- ref_joint_nll(model, d, p, dynamics)
      expect_true(all(is.finite(reference$parts)), label = label)
      expect_lt(abs(compiled$nll - reference$total), 1e-8, label = paste(label, "joint difference"))

      # The same value must come from the object that the fit uses, where the
      # deviations are random effects and fixed parameters are mapped.
      fitted <- TMB::MakeADFun(d, p, random = x$random, map = x$map,
                               DLL = ALSCL:::.acl_compile(model)$dll_name, silent = TRUE)
      expect_lt(abs(as.numeric(fitted$env$f(fitted$env$par)) - reference$total), 1e-8,
                label = paste(label, "joint difference with random effects declared"))

      # Each reported quantity that the reference also computes must agree.
      shared <- intersect(names(dynamics), names(compiled$report))
      expect_true(all(c("pla", "NL", "NA", "SSB", "CN", "Elog_index", "resid_index") %in% shared))
      for (name in shared) {
        expect_lt(ref_relative_difference(compiled$report[[name]], dynamics[[name]],
                                          floor = 1e-12), 1e-10,
                  label = paste(label, name, "relative difference"))
      }

      swapped <- ref_joint_nll(model, d, p, dynamics, swap_F_correlations = TRUE)$total
      if (F_structure == "group_year") {
        # With different correlations the two orientations differ by several
        # likelihood units, so applying phi_log_F_y to the group dimension
        # cannot pass the comparison above.
        expect_gt(abs(swapped - reference$total), 1)
        expect_gt(abs(compiled$nll - swapped), 1)
      } else {
        expect_identical(swapped, reference$total)
      }
    }
})

test_that("the shared F row ignores the group correlation and uses the time correlation (F47)", {
  for (model in c("ACL", "ALSCL")) {
    x <- review_likelihood_fixture(model, "year", 1)
    group <- if (model == "ACL") "logit_log_F_a" else "logit_log_F_l"
    base <- ref_tmb_joint(model, x$data, x$parameters)$nll
    p <- x$parameters
    p[[group]] <- qlogis(.9)
    expect_identical(ref_tmb_joint(model, x$data, p)$nll, base)
    p <- x$parameters
    p$logit_log_F_y <- qlogis(.2)
    changed <- ref_tmb_joint(model, x$data, p)$nll
    reference_change <- ref_joint_nll(model, x$data, p)$parts[["F"]] -
      ref_joint_nll(model, x$data, x$parameters)$parts[["F"]]
    expect_lt(abs(changed - base - reference_change), 1e-8)
    expect_gt(abs(changed - base), .1)
  }
})

test_that("each likelihood part responds to its own parameter as in the reference (F47)", {
  # Changing one scale or correlation changes the compiled objective by the
  # same amount as the reference, which locates a disagreement in one part.
  for (model in c("ACL", "ALSCL")) {
    x <- review_likelihood_fixture(model, "group_year", .25)
    acl <- model == "ACL"
    base_tmb <- ref_tmb_joint(model, x$data, x$parameters)$nll
    base_ref <- ref_joint_nll(model, x$data, x$parameters)$total
    changes <- c(list(logit_log_F_y = qlogis(.35), logit_log_R = qlogis(.7)),
      stats::setNames(list(qlogis(.65), log(.35), log(.6), log(.2), log(.4)),
        if (acl) c("logit_log_F_a", "log_std_log_F", "log_std_log_R", "log_std_log_N0", "log_std_index")
        else c("logit_log_F_l", "log_sigma_log_F", "log_sigma_log_R", "log_sigma_log_N0", "log_sigma_index")))
    for (name in names(changes)) {
      p <- x$parameters
      p[[name]] <- changes[[name]]
      compiled_change <- ref_tmb_joint(model, x$data, p)$nll - base_tmb
      reference_change <- ref_joint_nll(model, x$data, p)$total - base_ref
      expect_gt(abs(reference_change), 1e-3, label = paste(model, name, "reference change"))
      expect_lt(abs(compiled_change - reference_change), 1e-8,
                label = paste(model, name, "difference in change"))
    }
  }
})
