review_retro_fit <- function(args) {
  n <- ncol(args$data.CatL) - 1L
  value <- rep(100, n)
  value[n] <- 100 + 10 * n
  list(year = as.numeric(sub("^X", "", colnames(args$data.CatL)[-1L])),
       report = list(B = value, Rec = value, SSB = value, N = value),
       opt = list(par = c(mean_log_R = 1), objective = 10, convergence = 0L),
       convergence_code = 0L, max_abs_gradient = 1e-8, pdHess = TRUE,
       bound_hit = FALSE,
       diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE,
                          issues = character()))
}
review_retro_mock <- function(model, handler = review_retro_fit) {
  original <- if (model == "acl") run_acl else run_alscl
  arg_names <- names(formals(original))
  body(original) <- quote(handler(mget(arg_names, envir = environment())))
  environment(original) <- environment()
  original
}
review_retro_frames <- function(periods = 5L) {
  f <- fixture_frames()
  if (periods > 5L) for (name in c("data.CatL", "data.wgt", "data.mat")) {
    f[[name]] <- f[[name]][, c(1L, rep_len(2:6, periods))]
    colnames(f[[name]]) <- c("LengthBin", 1999L + seq_len(periods))
  }
  f
}

test_that("a map-fixed mean_log_R keeps the full-data value in every peel (F87)", {
  f <- review_retro_frames()
  seen <- list()
  handler <- function(args) {
    seen[[length(seen) + 1L]] <<- args
    review_retro_fit(args)
  }
  local_mocked_bindings(run_acl = review_retro_mock("acl", handler), .package = "ALSCL")
  totals <- colSums(as.matrix(f$data.CatL[-1L]))
  full_value <- log(mean(totals))

  retro_acl(f, nyear = 2, silent = TRUE, map = list(mean_log_R = factor(NA)),
            parameters = list(log_vbk = log(.3)))
  expect_length(seen, 3L)
  expect_identical(vapply(seen, function(a) ncol(a$data.CatL), integer(1)), c(6L, 5L, 4L))
  for (args in seen) {
    expect_identical(args$parameters$mean_log_R, full_value)
    expect_identical(args$parameters$log_vbk, log(.3))
  }
  # The value equals the one that the fitting setup derives from the complete data.
  inspected <- inspect_parameters(c(f, list(map = list(mean_log_R = factor(NA)))), "acl")
  expect_identical(inspected$start[inspected$parameter == "mean_log_R"], full_value)
  truncated <- f
  for (name in c("data.CatL", "data.wgt", "data.mat")) truncated[[name]] <- truncated[[name]][, 1:4]
  peeled <- inspect_parameters(c(truncated, list(map = list(mean_log_R = factor(NA)))), "acl")
  expect_false(isTRUE(all.equal(peeled$start[peeled$parameter == "mean_log_R"], full_value)))

  # An explicit value, a free mean_log_R and the default map are passed on unchanged.
  seen <- list()
  retro_acl(f, nyear = 1, silent = TRUE, map = list(mean_log_R = factor(NA)),
            parameters = list(mean_log_R = 3))
  expect_true(all(vapply(seen, function(a) identical(a$parameters, list(mean_log_R = 3)), logical(1))))
  seen <- list()
  retro_acl(f, nyear = 1, silent = TRUE, map = list(log_vbk = factor(NA)))
  expect_true(all(vapply(seen, function(a) is.null(a$parameters), logical(1))))
  seen <- list()
  retro_acl(f, nyear = 1, silent = TRUE)
  expect_true(all(vapply(seen, function(a) is.null(a$parameters) && is.null(a$map), logical(1))))
})

test_that("warnings are recorded with the fit that raised them (F89)", {
  f <- review_retro_frames()
  handler <- function(args) {
    if (ncol(args$data.CatL) == 5L) {
      warning("Standard errors unavailable: test cause")
      warning("Standard errors unavailable: test cause")
      warning("second message")
    }
    review_retro_fit(args)
  }
  local_mocked_bindings(run_acl = review_retro_mock("acl", handler), .package = "ALSCL")
  seen <- character()
  out <- withCallingHandlers(retro_acl(f, nyear = 2, silent = TRUE), warning = function(w) {
    seen <<- c(seen, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  expect_identical(out$fit_diagnostics$warnings,
                   c("", "Standard errors unavailable: test cause; second message", ""))
  expect_identical(names(out$fit_diagnostics)[ncol(out$fit_diagnostics)], "warnings")
  expect_length(seen, 1L)
  expect_match(seen, "Warnings were raised while fitting peel 1. See the warnings column")
  expect_equal(nrow(out$errors), 0L)

  local_mocked_bindings(run_acl = review_retro_mock("acl"), .package = "ALSCL")
  quiet <- expect_no_warning(retro_acl(f, nyear = 2, silent = TRUE))
  expect_identical(quiet$fit_diagnostics$warnings, c("", "", ""))
})

test_that("a bundle followed by a positional number of peels is accepted (F90)", {
  f <- review_retro_frames()
  local_mocked_bindings(run_acl = review_retro_mock("acl"),
                        run_alscl = review_retro_mock("alscl"), .package = "ALSCL")
  strip <- function(x) {
    x$fit_diagnostics$elapsed <- NULL
    x
  }
  for (fun in list(retro_acl, retro_alscl)) {
    named <- fun(f, nyear = 2, silent = TRUE)
    positional <- fun(f, 2, silent = TRUE)
    expect_identical(strip(positional), strip(named))
    expect_identical(positional$fit_diagnostics$Peel, 0:2)
    expect_error(fun(f, f, silent = TRUE), "data.CatL must not be supplied as well")
    expect_error(fun(f, f$data.CatL, silent = TRUE), "nyear = 3")
  }
  expect_identical(strip(retro_model(f, 2, silent = TRUE)), strip(retro_acl(f, nyear = 2, silent = TRUE)))
  expect_error(retro_model(f, 2.5, silent = TRUE), "nyear must be an integer")
})

test_that("peel_step removes several time steps per peel (F41)", {
  f <- review_retro_frames(12L)
  seen <- integer()
  handler <- function(args) {
    seen <<- c(seen, ncol(args$data.CatL) - 1L)
    review_retro_fit(args)
  }
  local_mocked_bindings(run_acl = review_retro_mock("acl", handler),
                        run_alscl = review_retro_mock("alscl", handler), .package = "ALSCL")
  out <- retro_acl(f, nyear = 2, peel_step = 4, silent = TRUE)
  expect_identical(seen, c(12L, 8L, 4L))
  expect_identical(out$peel_step, 4L)
  expect_identical(out$fit_diagnostics$Peel, 0:2)
  expect_equal(out$fit_diagnostics$RetrospectiveYear, c(2011, 2007, 2003))
  expect_equal(unique(out$rho_by_peel$RetrospectiveYear), c(2007, 2003))
  # Terminal estimate of a peel against the full-fit estimate for the same period.
  expect_equal(out$rho_by_peel$RawRho[out$rho_by_peel$Variable == "SSB"], c(.8, .4))
  expect_equal(out$rho_text$RequestedPeels, rep(2L, 4L))

  # The default is one time step per peel, as before.
  seen <- integer()
  default <- retro_alscl(f, nyear = 2, silent = TRUE)
  expect_identical(seen, c(12L, 11L, 10L))
  expect_identical(default$peel_step, 1L)

  # Time-dependent maps are truncated by the same number of steps.
  maps <- list()
  local_mocked_bindings(run_acl = review_retro_mock("acl", function(args) {
    maps[[length(maps) + 1L]] <<- args$map$dev_log_R
    review_retro_fit(args)
  }), .package = "ALSCL")
  retro_acl(f, nyear = 2, peel_step = 3, silent = TRUE,
            map = list(dev_log_R = factor(seq_len(12L))))
  expect_identical(lengths(maps), c(12L, 9L, 6L))

  expect_error(retro_acl(f, nyear = 3, peel_step = 4, silent = TRUE),
               "at least two time steps. nyear \\* peel_step is 12")
  expect_error(retro_acl(f, nyear = 2, peel_step = 0, silent = TRUE), "peel_step must be an integer")
  expect_error(retro_acl(f, nyear = 2, peel_step = 1.5, silent = TRUE), "peel_step must be an integer")
})

test_that("the full fit runs in the same batch as the peels with identical estimates (F88)", {
  skip_on_cran()
  x <- fit_fixture("ACL")
  args <- c(list(nyear = 2, model_type = "acl"), x$input,
            list(parameters = x$parameters, map = x$map, silent = TRUE))
  serial <- do.call(retro_model, c(args, list(ncores = 1)))
  concurrent <- do.call(retro_model, c(args, list(ncores = 3)))
  expect_identical(serial$workers, 1L)
  expect_identical(concurrent$workers, min(3L, ALSCL:::.acl_core_limit()))
  expect_identical(concurrent$results, serial$results)
  expect_identical(concurrent$rho_text, serial$rho_text)
  expect_identical(concurrent$rho_by_peel, serial$rho_by_peel)
  status <- c("Peel", "RetrospectiveYear", "error", "convergence_code", "pdHess",
              "bound_hit", "natural_boundary", "numerical_ok", "issues", "warnings")
  expect_identical(concurrent$fit_diagnostics[status], serial$fit_diagnostics[status])
  expect_equal(concurrent$fit_diagnostics$max_abs_gradient,
               serial$fit_diagnostics$max_abs_gradient, tolerance = 1e-10)
  # The full fit of the retrospective equals a direct fit.
  direct <- x$result
  full <- serial$results[serial$results$Peel == 0L & serial$results$Variable == "SSB", ]
  expect_identical(full$Value, as.numeric(direct$report$SSB))

  messages <- character()
  withCallingHandlers(do.call(retro_model, c(replace(args, "silent", FALSE), list(ncores = 3))),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    })
  expect_true(any(grepl("full ACL model and 2 retrospective peels on", messages)))
  expect_true(any(grepl("Full model:", messages)))
  expect_true(any(grepl("Peel 2:", messages)))
})

test_that("a fixed mean_log_R leaves the full fit unchanged in an actual retrospective (F87)", {
  skip_on_cran()
  x <- fit_fixture("ACL")
  parameters <- x$parameters
  parameters$mean_log_R <- NULL
  mapping <- x$map
  mapping$mean_log_R <- factor(NA)
  mapping$mean_log_F <- NULL
  args <- c(x$input, list(parameters = parameters, map = mapping, silent = TRUE))
  direct <- do.call(run_acl, args)
  out <- do.call(retro_acl, c(list(nyear = 1), args))
  full <- out$results[out$results$Peel == 0L & out$results$Variable == "SSB", ]
  expect_identical(full$Value, as.numeric(direct$report$SSB))
  expect_identical(nrow(out$errors), 0L)
})
