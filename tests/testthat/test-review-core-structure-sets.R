# Named sets of structure settings, the check for growth that stops below Linf
# under the midpoint growth transition, and the second pass of the refinement.

test_that("a set name selects the settings that belong together", {
  S <- ALSCL:::.acl_structure
  expect_identical(S("original", "ALSCL"), S(list(), "ALSCL"))
  full <- S("von_bertalanffy", "ALSCL")
  expect_identical(full$choices, list(initial_plus_group = "equilibrium", initial_length = "growth",
    growth_increment = "von_bertalanffy", growth_transition = "bin", correlation_range = "positive"))
  expect_identical(full$data, list(initial_plus_group = 1L, initial_length = 1L,
    growth_increment = 1L, growth_transition = 1L))
  expect_identical(S("von_bertalanffy", "ACL")$choices,
    list(initial_plus_group = "equilibrium", correlation_range = "positive"))
  expect_identical(S(list(set = "von_bertalanffy", correlation_range = "symmetric"), "ALSCL")$choices$correlation_range,
    "symmetric")
  # A setting given next to the set replaces the value of the set.
  mixed <- S(list(set = "von_bertalanffy", growth_transition = "midpoint"), "ALSCL")$choices
  expect_identical(mixed$growth_transition, "midpoint")
  expect_identical(mixed$initial_length, "growth")
  expect_identical(S(list(set = "original", growth_transition = "bin"), "ALSCL")$data, list(growth_transition = 1L))
  expect_error(S("best", "ALSCL"), "must be \"original\" or \"von_bertalanffy\"")
  expect_error(S(c("von_bertalanffy", "original"), "ALSCL"), "must be \"original\" or \"von_bertalanffy\"")
  expect_error(S(list(set = "best"), "ALSCL"), "structure\\$set must be")
  expect_error(S(list(set = "von_bertalanffy", set = "original"), "ALSCL"), "more than one `set`")
  expect_error(S(list(set = "von_bertalanffy", growth = "vb"), "ALSCL"), "Unknown structure setting: growth")
  expect_error(S(list("von_bertalanffy"), "ALSCL"), "named list")
  # The scale settings read a set name as well as a list.
  expect_false(ALSCL:::.acl_scale_settings(list(structure = "von_bertalanffy"))$symmetric)
  expect_true(ALSCL:::.acl_scale_settings(list(structure = list(set = "von_bertalanffy",
    correlation_range = "symmetric")))$symmetric)
})

test_that("the operating model accepts a set name", {
  params <- initialize_params(species = "tuna", nyear = 30, burn_in = 20)
  params$structure <- "von_bertalanffy"
  by_name <- sim_cal(params)
  params$structure <- list(initial_plus_group = "equilibrium", initial_length = "growth",
    growth_increment = "von_bertalanffy", growth_transition = "bin")
  expect_identical(by_name, sim_cal(params))
})

test_that("the growth check finds growth that stops below Linf under the midpoint transition", {
  check <- ALSCL:::.acl_growth_check
  fit_like <- function(mid, step, Linf, vbk, cv, increment = "logistic", transition = "midpoint") {
    border <- c(-Inf, (mid[-1L] + mid[-length(mid)]) / 2, Inf)
    list(model_type = "ALSCL", len_mid = mid, structure = list(growth_transition = transition),
      report = list(Linf = Linf, G = ALSCL:::.acl_growth_matrix(mid, border[-c(1L, length(border))], Linf, vbk, cv,
        step, increment, transition)))
  }
  # Quarterly steps with 5 cm bins: the logistic increment at 120 cm is about 1.5 cm.
  tuna <- fit_like(seq(12.5, 172.5, 5), .25, 152, .38, .3)
  result <- check(tuna)
  expect_true(result$stalled)
  expect_gte(result$stay_probability, .99)
  expect_gt(result$length, 105); expect_lt(result$length, .9 * 152)
  stay <- diag(tuna$report$G)
  expect_identical(result$length, tuna$len_mid[which(stay >= .99 & tuna$len_mid < .9 * 152)[1L]])
  expect_match(result$message, "Growth stops near length")
  expect_match(result$message, "structure = \"von_bertalanffy\"")
  # Annual steps with 2 cm bins do not stall, and neither does the transition integrated over the bin.
  expect_false(check(fit_like(seq(6, 50, 2), 1, 60, .2, .2))$stalled)
  expect_false(check(fit_like(seq(12.5, 172.5, 5), .25, 152, .38, .3, "von_bertalanffy", "bin"))$stalled)
  # The von Bertalanffy increment with the midpoint transition stalls as well when the bins are wide enough.
  expect_true(check(fit_like(seq(15, 175, 10), .25, 152, .38, .3, "von_bertalanffy", "midpoint"))$stalled)
  # A fit saved before the structure was recorded uses the midpoint transition.
  legacy <- tuna; legacy$structure <- NULL
  expect_true(check(legacy)$stalled)
  expect_null(check(list(model_type = "ACL")))
  broken <- tuna; broken$report$G <- NULL
  expect_false(check(broken)$stalled)
})

test_that("a fit reports growth that stops below Linf, and not with the von_bertalanffy set", {
  skip_on_cran()
  f <- fixture_frames()
  f$data.CatL[[1]] <- as.character(seq(15, 55, 5)); f$data.wgt[[1]] <- f$data.mat[[1]] <- f$data.CatL[[1]]
  p <- create_parameters("alscl")$parameters
  p$log_sigma_index <- log(.2); p$log_sigma_log_N0 <- log(.1); p$log_sigma_log_R <- log(.1)
  p$log_Linf <- log(100); p$log_vbk <- log(.02)
  mapping <- lapply(p, function(x) factor(NA)); mapping$mean_log_R <- NULL
  args <- c(f, list(parameters = p, map = mapping, silent = TRUE))
  expect_no_message(fit <- do.call(run_alscl, args))
  expect_true(fit$growth_check$stalled)
  expect_lt(fit$growth_check$length, 90)
  expect_match(summary(fit)$growth_check, "Growth stops near length")
  expect_output(print(summary(fit)), "Growth check: Growth stops near length")
  args$silent <- FALSE
  expect_message(do.call(run_alscl, args), "Growth stops near length")
  expect_no_message(full <- do.call(run_alscl, c(args, list(structure = "von_bertalanffy"))),
                    message = "Growth stops near length")
  expect_null(summary(full)$growth_check)
  expect_false(full$growth_check$stalled)
  expect_identical(full$structure$growth_transition, "bin")
  expect_identical(full$structure$initial_length, "growth")
  expect_identical(full$recipe$args$structure, "von_bertalanffy")
  # ACL takes the plus-group setting of the set and has no growth check.
  prepared <- do.call(ALSCL:::.acl_prepare_data, c(f, list(structure = "von_bertalanffy")))
  setup <- ALSCL:::.acl_model_setup("ACL", prepared)
  expect_identical(setup$data$initial_plus_group, 1L)
  expect_identical(setup$structure$initial_plus_group, "equilibrium")
})

test_that("the second refinement pass accepts steps within the precision of the objective", {
  withr::local_options(ALSCL.sd_cores = 1L)
  # A likelihood that is very sharp in the first parameter. Every evaluation
  # after the first returns the objective 1e-7 too high, as when the
  # random-effect mode is found from another starting point.
  curvature <- c(1e8, 1); optimum <- c(5, -1)
  make <- function() {
    calls <- 0L
    list(fn = function(x) { calls <<- calls + 1L
           300 + .5 * sum(curvature * (x - optimum)^2) + if (calls > 1L) 1e-7 else 0 },
         gr = function(x) curvature * (x - optimum))
  }
  start <- optimum + c(3e-10, 0)          # gradient 0.03, objective 4.5e-12 above the minimum
  refined <- ALSCL:::.acl_polish(make(), start, c(-10, -10), c(10, 10))
  expect_true(refined$second_pass)
  expect_gte(refined$initial_max_gradient, 1e-3)
  expect_lt(refined$final_max_gradient, 1e-3)
  expect_true(all(refined$history$iteration > 5L))
  expect_equal(refined$par, optimum, tolerance = 1e-9)
  # Below the gradient check the first pass is final, whatever its status.
  near <- optimum + c(5e-12, 0)           # gradient 5e-4
  kept <- ALSCL:::.acl_polish(make(), near, c(-10, -10), c(10, 10))
  expect_false(kept$second_pass)
  expect_identical(kept$status, "no_acceptable_step")
  expect_identical(kept$par, near)
  # A rise of the objective above its working precision is still rejected.
  rising <- make(); noisy <- rising$fn
  rising$fn <- function(x) noisy(x) + if (environment(noisy)$calls > 1L) 1e-3 else 0
  rejected <- ALSCL:::.acl_polish(rising, start, c(-10, -10), c(10, 10))
  expect_true(rejected$second_pass)
  expect_identical(rejected$status, "no_acceptable_step")
  expect_identical(rejected$par, start)
  # An exact quadratic converges in the first pass and has no second pass.
  exact <- list(fn = function(x) sum((x - 2)^2), gr = function(x) 2 * (x - 2))
  expect_false(ALSCL:::.acl_polish(exact, c(x = 1), -10, 10)$second_pass)
  expect_false(ALSCL:::.acl_polish(exact, c(x = 1), -10, 10, enabled = FALSE)$second_pass)
})
