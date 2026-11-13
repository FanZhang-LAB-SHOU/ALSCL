# Characterization of current behaviour (review findings F03 and F04), not a
# bug fix. A population with constant recruitment, no fishing and all
# recruitment and F deviations at zero should keep a constant spawning stock
# biomass (SSB). The current first-period state of both templates is not the
# stationary state of their own dynamics, so SSB drifts:
#
#   F03  the last age starts as one cohort and not as an accumulated plus
#        group (ACL and ALSCL);
#   F04  ALSCL spreads first-period numbers and recruits over length with the
#        length-at-age key, and later steps move them with the growth matrix G,
#        which gives a different length composition at age.
#
# ref_stationarity_ratio() in helper-review-reference.R returns SSB in the
# last time step divided by SSB in the first, from the R reference dynamics
# (source = "reference") or from the compiled template (source = "tmb").

test_that("reference and template give the same SSB ratio", {
  for (case in c("tuna", "flatfish")) for (model in c("ALSCL", "ACL"))
    for (deviation in c("zero", "equilibrium")) {
      reference <- ref_stationarity_ratio(case, model, "reference", deviation)
      compiled <- ref_stationarity_ratio(case, model, "tmb", deviation)
      expect_lt(abs(as.numeric(reference) - as.numeric(compiled)), 1e-10,
                label = paste(case, model, deviation, "difference in SSB ratio"))
      expect_length(attr(compiled, "SSB"), 41L)
    }
})

test_that("ACL is stationary once the initial plus group is at equilibrium", {
  # With the last first-period deviation set to -log(1 - exp(-M)) the ACL
  # numbers at age are stationary and the same key applies in every step.
  for (case in c("tuna", "flatfish")) for (source in c("reference", "tmb")) {
    ratio <- ref_stationarity_ratio(case, "ACL", source, "equilibrium")
    expect_lt(abs(as.numeric(ratio) - 1), 1e-8, label = paste(case, source, "|SSB ratio - 1|"))
  }
})

test_that("the helper returns 1 for a first-period state built from the dynamics", {
  # Positive control in R only: start each age from the previous age after one
  # step of survival and growth, and the last age from the accumulated sum
  # (I - G S)^-1 G S n(A - 1). No package code implements this at the base
  # commit; it shows that the ratio reaches 1 for a consistent structure.
  consistent_state <- function(numbers_at_age, key, G, Z_at_length) {
    A <- ncol(key); L <- nrow(key)
    step <- G %*% diag(exp(-Z_at_length))
    state <- matrix(0, L, A)
    state[, 1L] <- numbers_at_age[1L] * key[, 1L]
    for (a in seq_len(A - 1L)[-1L]) state[, a] <- step %*% state[, a - 1L]
    state[, A] <- solve(diag(L) - step, step %*% state[, A - 1L])
    state
  }
  for (case in c("tuna", "flatfish")) {
    ratio <- ref_stationarity_ratio(case, "ALSCL", "reference", initial_state = consistent_state)
    expect_lt(abs(as.numeric(ratio) - 1), 1e-8, label = paste(case, "|SSB ratio - 1|"))
    expect_lt(max(abs(attr(ratio, "SSB") / attr(ratio, "SSB")[1L] - 1)), 1e-8)
  }
})

test_that("current default structures are not stationary (F03, F04)", {
  # ---------------------------------------------------------------------------
  # CURRENT BEHAVIOUR, TO BE REPLACED FOR CORRECTED STRUCTURES.
  #
  # The values below pin what the default structures compute at base commit
  # 6b072b9. They are loose on purpose and must keep passing while the
  # defaults are unchanged.
  #
  # A corrected structure (new argument, default off) must instead satisfy
  #   abs(ref_stationarity_ratio(case, model, "tmb", "zero", tmb_data = <switch>) - 1) < 1e-8
  # for both cases and both models, with every deviation at zero. Pass the new
  # data switch or parameter through `tmb_data` / `tmb_parameters`, and the
  # matching R parts (`initial_numbers`, `initial_state`, `growth`, `key`)
  # through `...` for source = "reference".
  # ---------------------------------------------------------------------------
  ratio <- function(case, model, deviation)
    as.numeric(ref_stationarity_ratio(case, model, "tmb", deviation))

  # F04 alone: numbers at age are stationary (equilibrium plus group), and SSB
  # still changes in ALSCL. The review measured 0.675 (tuna) and 1.060
  # (flatfish) over 41 time steps.
  tuna <- ratio("tuna", "ALSCL", "equilibrium")
  flatfish <- ratio("flatfish", "ALSCL", "equilibrium")
  expect_gt(abs(tuna - 1), .1)
  expect_equal(tuna, .675, tolerance = .02)
  expect_gt(abs(flatfish - 1), .02)
  expect_equal(flatfish, 1.060, tolerance = .02)

  # F03 and F04 together: every deviation at zero, which is the prior mode of
  # the first-period state.
  expect_gt(abs(ratio("tuna", "ALSCL", "zero") - 1), .1)       # 0.788
  expect_gt(abs(ratio("flatfish", "ALSCL", "zero") - 1), .1)   # 1.224

  # F03 alone: ACL with every deviation at zero.
  expect_gt(ratio("tuna", "ACL", "zero") - 1, .1)              # 1.482
  expect_gt(ratio("flatfish", "ACL", "zero") - 1, .05)         # 1.155
})
