# Review finding F49: Mohn's rho compares each retrospective peel's terminal
# estimate with the full run's estimate for the same time step,
#   rho(peel) = (peel terminal value - full-run value in that step) / full-run value in that step,
# and the reported rho is the mean over peels. The mocked full-run series
# below change from step to step, so using any other reference step (for
# example the full run's terminal step) gives different values.

# Full-run series for the four reported quantities. Each quantity has its own
# level and trend so that a mix-up between quantities is also detected.
review_rho_series <- function(n) {
  step <- seq_len(n)
  list(B = 100 + 10 * step, Rec = 500 - 30 * step + 4 * step^2,
       SSB = 40 * 1.15^step, N = 1000 + 50 * step * (-1)^step)
}
# Relative difference of the terminal estimate of peel 1, 2, 3, ... by quantity.
review_rho_bias <- list(B = c(.2, -.1, .05, .3), Rec = c(-.25, .4, .1, -.05),
                        SSB = c(.02, .04, .08, .16), N = c(-.3, -.2, -.1, .1))

# A fitted-model stand-in. A peel reproduces the full run in all retained
# steps except its last, which is biased by review_rho_bias; the step before
# it is also perturbed to show that only the terminal estimate enters rho.
review_rho_fit <- function(n_full) {
  function(args) {
    labels <- colnames(args$data.CatL)[-1L]
    n <- length(labels)
    peel <- n_full - n
    series <- lapply(review_rho_series(n_full), `[`, seq_len(n))
    if (peel > 0L) for (name in names(series)) {
      series[[name]][n] <- series[[name]][n] * (1 + review_rho_bias[[name]][peel])
      series[[name]][n - 1L] <- series[[name]][n - 1L] * 3
    }
    list(year = as.numeric(sub("^X", "", labels)), report = series,
         opt = list(par = c(mean_log_R = 1), objective = 10, convergence = 0L),
         convergence_code = 0L, max_abs_gradient = 1e-8, pdHess = TRUE, bound_hit = FALSE,
         diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE, issues = character()))
  }
}
review_rho_mock <- function(model, handler) {
  original <- if (model == "acl") run_acl else run_alscl
  arg_names <- names(formals(original))
  body(original) <- quote(handler(mget(arg_names, envir = environment())))
  environment(original) <- environment()
  original
}
review_rho_frames <- function(times) {
  labels <- c("0-20", "20-25", "25-30", "30-35", "35-40", "40-45", "45-50", "50-55", "55-60")
  n <- length(times)
  data <- data.frame(LengthBin = labels, matrix(seq_len(9L * n) + 10, 9L, n), check.names = FALSE)
  names(data) <- c("LengthBin", as.character(times))
  w <- m <- data
  w[-1L] <- 1; m[-1L] <- .5
  list(data.CatL = data, data.wgt = w, data.mat = m)
}
# Mohn's rho written directly from its definition, for `peels` peels of one
# time step each.
review_rho_expected <- function(n_full, peels) {
  full <- review_rho_series(n_full)
  do.call(rbind, lapply(seq_len(peels), function(peel) {
    step <- n_full - peel
    do.call(rbind, lapply(names(full), function(name) {
      terminal <- full[[name]][step] * (1 + review_rho_bias[[name]][peel])
      data.frame(Peel = peel, Variable = name,
                 rho = (terminal - full[[name]][step]) / full[[name]][step],
                 wrong_reference = (terminal - full[[name]][n_full]) / full[[name]][n_full])
    }))
  }))
}

expect_rho_definition <- function(out, times, peels) {
  n_full <- length(times)
  expected <- review_rho_expected(n_full, peels)
  by_peel <- out$rho_by_peel
  expect_equal(nrow(by_peel), peels * 4L)
  for (i in seq_len(nrow(expected))) {
    row <- by_peel[by_peel$Peel == expected$Peel[i] & by_peel$Variable == expected$Variable[i], ]
    label <- paste("peel", expected$Peel[i], expected$Variable[i])
    expect_equal(nrow(row), 1L, label = paste(label, "rows"))
    expect_equal(row$RawRho, expected$rho[i], tolerance = 1e-12, label = paste(label, "RawRho"))
    expect_equal(row$Rho, expected$rho[i], tolerance = 1e-12, label = paste(label, "Rho"))
    # The time step of the comparison is the peel's last retained step.
    expect_equal(as.numeric(as.character(row$RetrospectiveYear)),
                 times[n_full - expected$Peel[i]], label = paste(label, "terminal time step"))
    # The fixture separates the two candidate reference steps.
    expect_gt(abs(expected$rho[i] - expected$wrong_reference[i]), .01)
  }
  for (name in unique(expected$Variable)) {
    mean_rho <- mean(expected$rho[expected$Variable == name])
    expect_equal(out$rho_text$Rho[out$rho_text$Variable == name], mean_rho,
                 tolerance = 1e-12, label = paste(name, "mean rho"))
    expect_equal(out$raw_rho_text$Rho[out$raw_rho_text$Variable == name], mean_rho,
                 tolerance = 1e-12, label = paste(name, "raw mean rho"))
  }
  # The stored peel series end at the biased terminal estimate.
  results <- out$results
  for (i in seq_len(nrow(expected))) {
    rows <- results[results$Peel == expected$Peel[i] & results$Variable == expected$Variable[i], ]
    step <- n_full - expected$Peel[i]
    full_value <- review_rho_series(n_full)[[expected$Variable[i]]][step]
    expect_equal(rows$Value[which.max(rows$Year)], full_value * (1 + expected$rho[i]),
                 tolerance = 1e-12)
    expect_equal(max(rows$Year), times[step])
  }
}

test_that("Mohn's rho uses the full-run estimate of each peel's terminal year (F49)", {
  times <- 2000:2009
  f <- c(review_rho_frames(times),
         list(rec.age = 1, nage = 4, M = .2, sel_L50 = 20, sel_L95 = 30))
  handler <- review_rho_fit(length(times))
  local_mocked_bindings(run_acl = review_rho_mock("acl", handler),
                        run_alscl = review_rho_mock("alscl", handler), .package = "ALSCL")
  for (model in c("acl", "alscl")) for (peels in c(1L, 3L, 4L)) {
    out <- do.call(retro_model, c(list(nyear = peels, model_type = model, silent = TRUE), f))
    expect_rho_definition(out, times, peels)
  }
  out <- do.call(retro_acl, c(list(nyear = 2L, silent = TRUE), f))
  expect_rho_definition(out, times, 2L)
})

test_that("Mohn's rho uses the same quarter of the full run for quarterly time steps (F49)", {
  times <- 2000 + (0:11) * .25
  f <- c(review_rho_frames(times),
         list(rec.age = .25, nage = 6, M = .05, sel_L50 = 20, sel_L95 = 30, growth_step = .25))
  handler <- review_rho_fit(length(times))
  local_mocked_bindings(run_acl = review_rho_mock("acl", handler),
                        run_alscl = review_rho_mock("alscl", handler), .package = "ALSCL")
  for (model in c("acl", "alscl")) {
    # Each peel removes one time step, here one quarter. Warnings about peel
    # length are not the subject of this test.
    out <- suppressWarnings(do.call(retro_model,
      c(list(nyear = 3L, model_type = model, silent = TRUE), f)))
    expect_rho_definition(out, times, 3L)
    expect_equal(sort(unique(out$rho_by_peel$RetrospectiveYear)), c(2002, 2002.25, 2002.5))
  }
})
