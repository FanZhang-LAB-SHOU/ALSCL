retro_test_fit <- function(args) {
  n <- ncol(args$data.CatL) - 1L
  value <- rep(100, n)
  if (n == 4L) value[n] <- 120
  if (n == 3L) value[n] <- 140
  list(year = as.numeric(sub("^X", "", colnames(args$data.CatL)[-1L])),
       report = list(B = value, Rec = value, SSB = value, N = value),
       opt = list(par = c(mean_log_R = 1), objective = 10, convergence = 0L),
       convergence_code = 0L, max_abs_gradient = 1e-8, pdHess = TRUE,
       bound_hit = FALSE,
       diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE,
                          issues = character()))
}

retro_test_mock <- function(model, handler = retro_test_fit) {
  original <- if (model == "acl") run_acl else run_alscl
  arg_names <- names(formals(original))
  body(original) <- quote(handler(mget(arg_names, envir = environment())))
  environment(original) <- environment()
  original
}

test_that("retrospective bundles retain model settings and explicit NULL overrides", {
  f <- fixture_frames()
  x <- list(data.CatL = f$data.CatL, data.wgt = f$data.wgt, data.mat = f$data.mat,
            fit_args = c(f[-(1:3)], list(ncores = 7, nstarts = 2,
              zero_action = "error", control = list(iter.max = 45),
              growth_step = 1, F_structure = "year")),
            fit_config = list(acl = list(map = list(t0 = factor(NA))),
                              alscl = list(map = list(log_t0 = factor(NA)))))
  seen <- list()
  handler <- function(args) {
    seen[[length(seen) + 1L]] <<- args
    retro_test_fit(args)
  }
  local_mocked_bindings(run_acl = retro_test_mock("acl", handler),
                        run_alscl = retro_test_mock("alscl", handler), .package = "ALSCL")
  for (fun in list(retro_acl, retro_alscl)) {
    seen <- list()
    out <- fun(x, nyear = 2, silent = TRUE, map = NULL,
               control = list(eval.max = 100), nstarts = 3)
    expect_length(seen, 3)
    expect_true(all(vapply(seen, function(a) is.null(a$map), logical(1))))
    expect_true(all(vapply(seen, function(a) identical(a$ncores, 1L), logical(1))))
    expect_true(all(vapply(seen, function(a) identical(a$nstarts, 3), logical(1))))
    expect_true(all(vapply(seen, function(a) identical(a$zero_action, "error"), logical(1))))
    expect_true(all(vapply(seen, function(a) identical(a$control, list(eval.max = 100)), logical(1))))
    expect_true(all(vapply(seen, function(a) identical(a$F_structure, "year"), logical(1))))
    expect_equal(out$workers, 1L)
    expect_equal(out$nstarts, 3)
    expect_equal(out$rho_text$Rho, rep(.3, 4))
    expect_true(all(out$fit_diagnostics$numerical_ok))
  }
  seen <- list()
  out <- retro_model(data.CatL = x, nyear = 2, model_type = "alscl", silent = TRUE)
  expect_identical(seen[[1]]$map, x$fit_config$alscl$map)
  expect_identical(seen[[1]]$control, x$fit_args$control)
  expect_equal(out$nstarts, 2)
})

test_that("flat bundles and legacy positional retrospective calls agree", {
  f <- fixture_frames()
  local_mocked_bindings(run_acl = retro_test_mock("acl"),
                        run_alscl = retro_test_mock("alscl"), .package = "ALSCL")
  for (fun in list(retro_acl, retro_alscl)) {
    bundle <- fun(f, nyear = 2, silent = TRUE)
    separate <- do.call(fun, c(list(nyear = 2), f, list(silent = TRUE)))
    positional <- do.call(fun, c(list(2), unname(f), list(silent = TRUE)))
    expect_equal(bundle$results, separate$results)
    expect_equal(bundle$results, positional$results)
  }
  seen <- NULL
  local_mocked_bindings(run_alscl = retro_test_mock("alscl", function(args) {
    seen <<- args
    retro_test_fit(args)
  }), .package = "ALSCL")
  # Additional unnamed arguments after growth_step historically match the
  # remaining retro_model formals, starting with parameters.
  do.call(retro_alscl, c(list(2), unname(f), list(1),
                         list(list(log_Linf = log(60))), list(silent = TRUE)))
  expect_identical(seen$parameters, list(log_Linf = log(60)))
  # A bundle in the first positional slot uses the historical five-peel default.
  for (name in c("data.CatL", "data.wgt", "data.mat")) {
    f[[name]] <- f[[name]][, c(1:6, 6, 6)]
    colnames(f[[name]]) <- c("LengthBin", 2000:2006)
  }
  out <- retro_acl(f, silent = TRUE)
  expect_equal(nrow(out$fit_diagnostics), 6)
  expect_equal(out$fit_diagnostics$Peel, 0:5)
})

test_that("one invalid peel suppresses aggregate rho without discarding raw estimates", {
  f <- fixture_frames()
  handler <- function(args) {
    fit <- retro_test_fit(args)
    if (ncol(args$data.CatL) == 5L) {
      fit$pdHess <- FALSE
      fit$diagnostics$numerical_ok <- FALSE
    }
    fit
  }
  local_mocked_bindings(run_acl = retro_test_mock("acl", handler), .package = "ALSCL")
  expect_warning(out <- retro_acl(f, nyear = 2, silent = TRUE), "Mohn's rho is unavailable")
  expect_true(all(is.na(out$rho_text$Rho)))
  expect_equal(out$raw_rho_text$Rho, rep(.3, 4))
  expect_equal(out$fit_diagnostics$numerical_ok, c(TRUE, FALSE, TRUE))
  expect_equal(out$rho_text$ValidPeels, rep(1L, 4))
  expect_true(all(is.na(out$rho_by_peel$Rho[out$rho_by_peel$Peel == 1])))
  expect_equal(out$rho_by_peel$RawRho[out$rho_by_peel$Peel == 1], rep(.2, 4))
  expect_true(any(!out$results$NumericalOK))
  plot <- plot_retro(out)
  built <- ggplot2::ggplot_build(plot)
  expect_true(all(grepl("unavailable", built$data[[3]]$label)))
  expect_match(plot$labels$subtitle, "numerical checks")
})

test_that("full-fit failure retains every peel diagnostic and records errors", {
  f <- fixture_frames()
  handler <- function(args) {
    if (ncol(args$data.CatL) == 6L) stop("deliberate full-fit failure")
    retro_test_fit(args)
  }
  local_mocked_bindings(run_acl = retro_test_mock("acl", handler), .package = "ALSCL")
  expect_warning(out <- retro_acl(f, nyear = 2, silent = TRUE), "Mohn's rho is unavailable")
  expect_equal(out$fit_diagnostics$Peel, 0:2)
  expect_equal(out$fit_diagnostics$numerical_ok, c(FALSE, TRUE, TRUE))
  expect_equal(out$errors$Peel, 0L)
  expect_match(out$errors$error, "deliberate full-fit failure")
  expect_true(all(is.na(out$rho_text$Rho)))
  expect_true(all(is.na(out$raw_rho_text$Rho)))
  expect_equal(sort(unique(out$results$Peel)), 1:2)
})

test_that("requested plotting preserves diagnostics when every fit fails", {
  f <- fixture_frames()
  handler <- function(args) stop("deliberate fit failure")
  local_mocked_bindings(run_acl = retro_test_mock("acl", handler),
                        run_alscl = retro_test_mock("alscl", handler), .package = "ALSCL")
  for (fun in list(retro_acl, retro_alscl)) {
    warnings <- character()
    out <- withCallingHandlers(fun(f, nyear = 2, plot = TRUE, silent = TRUE),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      })
    expect_length(warnings, 2L)
    expect_match(warnings[1], "Mohn's rho is unavailable")
    expect_match(warnings[2], "plot skipped")
    expect_true("plot" %in% names(out))
    expect_null(out$plot)
    expect_equal(nrow(out$results), 0L)
    expect_equal(out$fit_diagnostics$Peel, 0:2)
    expect_equal(out$errors$Peel, 0:2)
    expect_true(all(out$errors$error == "deliberate fit failure"))
    expect_true(all(is.na(out$rho_text$Rho)))
  }
})

test_that("a failed peel is not omitted from Mohn's rho or diagnostic rows", {
  f <- fixture_frames()
  handler <- function(args) {
    if (ncol(args$data.CatL) == 5L) stop("deliberate peel failure")
    retro_test_fit(args)
  }
  local_mocked_bindings(run_alscl = retro_test_mock("alscl", handler), .package = "ALSCL")
  expect_warning(out <- retro_alscl(f, nyear = 2, silent = TRUE), "Mohn's rho is unavailable")
  expect_equal(out$errors$Peel, 1L)
  expect_equal(nrow(out$fit_diagnostics), 3L)
  expect_equal(nrow(out$rho_by_peel), 8L)
  expect_true(all(is.na(out$rho_text$Rho)))
  expect_true(all(is.na(out$raw_rho_text$Rho)))
  expect_equal(out$rho_by_peel$RawRho[out$rho_by_peel$Peel == 2], rep(.4, 4))
})

test_that("missing diagnostics and nonfinite terminal values cannot pass the screen", {
  f <- fixture_frames()
  handler <- function(args) {
    fit <- retro_test_fit(args)
    if (ncol(args$data.CatL) == 5L) fit$report$SSB[4] <- NA_real_
    fit
  }
  local_mocked_bindings(run_acl = retro_test_mock("acl", handler), .package = "ALSCL")
  expect_warning(out <- retro_acl(f, nyear = 2, silent = TRUE), "Mohn's rho is unavailable")
  expect_true(all(out$fit_diagnostics$numerical_ok))
  expect_true(is.na(out$rho_text$Rho[out$rho_text$Variable == "SSB"]))
  expect_equal(out$rho_text$Rho[out$rho_text$Variable != "SSB"], rep(.3, 3))
  local_mocked_bindings(run_acl = retro_test_mock("acl", function(args) {
    fit <- retro_test_fit(args)
    fit[c("diagnostics", "pdHess", "bound_hit", "max_abs_gradient")] <- NULL
    fit
  }), .package = "ALSCL")
  expect_warning(out <- retro_acl(f, nyear = 2, silent = TRUE), "Mohn's rho is unavailable")
  expect_true(all(!out$fit_diagnostics$numerical_ok))
  expect_true(all(is.na(out$rho_text$Rho)))
})

test_that("nonzero raw optimizer codes remain usable after successful refinement", {
  f <- fixture_frames()
  local_mocked_bindings(run_acl = retro_test_mock("acl", function(args) {
    fit <- retro_test_fit(args)
    fit$convergence_code <- fit$opt$convergence <- 1L
    fit
  }), .package = "ALSCL")
  expect_no_warning(out <- retro_acl(f, nyear = 2, silent = TRUE))
  expect_true(all(out$fit_diagnostics$numerical_ok))
  expect_equal(out$rho_text$Rho, rep(.3, 4))
})

test_that("retrospectives preserve optimizer messages, passes and refinement evidence", {
  f <- fixture_frames()
  handler <- function(args) {
    fit <- retro_test_fit(args)
    fit$converge <- "relative convergence (4)"
    fit$raw_opt <- list(selected_pass = 1L)
    fit$optimizer_history <- list(
      list(convergence = 0L, message = "relative convergence (4)"),
      list(convergence = 1L, message = "false convergence (8)"))
    fit$refinement <- list(status = "gradient_tolerance", steps = 1L,
                          initial_max_gradient = 0.002)
    # A genuinely selected failed pass remains visible even after good polish.
    if (ncol(args$data.CatL) == 4L) {
      fit$converge <- "false convergence (8)"
      fit$convergence_code <- 1L
      fit$raw_opt$selected_pass <- 2L
    }
    fit
  }
  local_mocked_bindings(run_acl = retro_test_mock("acl", handler), .package = "ALSCL")
  expect_no_warning(out <- retro_acl(f, nyear = 2, silent = TRUE))
  d <- out$fit_diagnostics
  expect_equal(d$convergence_code, c(0L, 0L, 1L))
  expect_equal(d$selected_pass, c(1L, 1L, 2L))
  expect_equal(d$optimizer_message, c(rep("relative convergence (4)", 2),
                                      "false convergence (8)"))
  expect_equal(d$optimizer_codes, rep("0; 1", 3))
  expect_equal(d$optimizer_messages,
               rep("relative convergence (4); false convergence (8)", 3))
  expect_equal(d$refinement_status, rep("gradient_tolerance", 3))
  expect_equal(d$refinement_steps, rep(1L, 3))
  expect_equal(d$pre_refinement_max_gradient, rep(0.002, 3))
  expect_true(all(d$numerical_ok))
})

test_that("missing optimizer history in legacy and failed peels remains missing", {
  f <- fixture_frames()
  handler <- function(args) {
    if (ncol(args$data.CatL) == 5L) stop("fit construction failed")
    retro_test_fit(args)
  }
  local_mocked_bindings(run_acl = retro_test_mock("acl", handler), .package = "ALSCL")
  expect_warning(out <- retro_acl(f, nyear = 2, silent = TRUE), "Mohn's rho is unavailable")
  d <- out$fit_diagnostics
  fields <- c("optimizer_message", "selected_pass", "optimizer_codes",
    "optimizer_messages", "refinement_status", "refinement_steps",
    "pre_refinement_max_gradient")
  expect_equal(nrow(d), 3L)
  expect_true(all(is.na(d[fields])))
  expect_match(d$error[2], "fit construction failed")
  expect_false(d$numerical_ok[2])
  expect_true(all(d$numerical_ok[c(1, 3)]))
})

test_that("all failed fits return diagnostics and plot errors clearly", {
  f <- fixture_frames()
  local_mocked_bindings(run_acl = retro_test_mock("acl", function(args) {
    stop("no fit available")
  }), .package = "ALSCL")
  expect_warning(out <- retro_acl(f, nyear = 2, silent = TRUE), "Mohn's rho is unavailable")
  expect_equal(nrow(out$errors), 3L)
  expect_equal(nrow(out$results), 0L)
  expect_error(plot_retro(out), "No retrospective estimates")
})
test_that("retrospectives reject unnamed time columns before building fit records", {
  x <- fixture_frames()
  x$data.CatL <- as.matrix(x$data.CatL)
  colnames(x$data.CatL) <- NULL
  expect_error(retro_acl(x, nyear = 2, silent = TRUE), "increasing numeric labels")
})

test_that("retrospective flags are validated before any full or peeled fit", {
  f <- fixture_frames()
  calls <- 0L
  local_mocked_bindings(.acl_retro_fit = function(...) {
    calls <<- calls + 1L
    stop("fitting must not start for an invalid flag")
  }, .package = "ALSCL")
  invalid <- list(NULL, NA, logical(), c(TRUE, FALSE), 0, 1, "TRUE", list(TRUE))
  for (fun in list(retro_model, retro_acl, retro_alscl)) {
    for (flag in c("plot", "silent")) for (value in invalid) {
      args <- list(data.CatL = f, nyear = 2, silent = TRUE, plot = FALSE)
      args[flag] <- list(value)
      expect_error(do.call(fun, args), paste0(flag, " must be TRUE or FALSE"))
      expect_equal(calls, 0L)
    }
  }
})

test_that("stored retrospective plots require a finite time-estimate pair", {
  f <- fixture_frames()
  local_mocked_bindings(run_acl = retro_test_mock("acl", function(args) {
    fit <- retro_test_fit(args)
    fit$report <- lapply(fit$report, function(x) rep(NA_real_, length(x)))
    fit$diagnostics$numerical_ok <- FALSE
    fit
  }), .package = "ALSCL")
  warnings <- character()
  out <- withCallingHandlers(retro_acl(f, nyear = 2, silent = TRUE, plot = TRUE),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  expect_true(nrow(out$results) > 0L)
  expect_null(out$plot)
  expect_match(warnings[2], "no finite estimates")
  for (value in c(NA_real_, NaN, Inf, -Inf)) {
    out$results$Value <- value
    expect_error(plot_retro(out), "No retrospective estimates")
  }
  # Individually finite time and value columns are insufficient when no row
  # has both: there is still no drawable point.
  out$results$Value <- 1
  out$results$Year <- NA_real_
  out$results$Year[1] <- 2000
  out$results$Value[1] <- NA_real_
  expect_error(plot_retro(out), "No retrospective estimates")
})

test_that("retrospective plots retain gaps between available estimates without grids", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  f <- fixture_frames()
  local_mocked_bindings(run_acl = retro_test_mock("acl"), .package = "ALSCL")
  out <- retro_acl(f, nyear = 2, silent = TRUE)
  missing <- out$results$Year == 2002 & out$results$Peel == 0L
  out$results$Value[missing] <- NA_real_
  expect_no_warning(p <- plot_retro(out))
  expect_equal(nrow(p$data), nrow(out$results))
  expect_identical(p$data$Value, out$results$Value)
  built <- ggplot2::ggplot_build(p)
  # Keep the missing middle points so geom_line breaks the path rather than
  # drawing a spurious connection across the missing time step.
  expect_equal(sum(is.na(built$data[[1]]$y)), sum(missing))
  expect_true(any(is.finite(built$data[[1]]$y)))
  expect_no_warning(ggplot2::ggplotGrob(p))
  for (grid in c("panel.grid.major.x", "panel.grid.major.y",
                 "panel.grid.minor.x", "panel.grid.minor.y"))
    expect_s3_class(ggplot2::calc_element(grid, built$plot$theme), "element_blank")
})

