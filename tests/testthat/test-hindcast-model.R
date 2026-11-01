hindcast_test_input <- local({
  cache <- new.env(parent = emptyenv())
  function(model = "ACL") {
    if (!exists(model, envir = cache, inherits = FALSE)) {
      f <- fit_fixture(model)
      assign(model, c(f$input, list(parameters = f$parameters, map = f$map)), envir = cache)
    }
    get(model, envir = cache, inherits = FALSE)
  }
})

test_that("real ACL and ALSCL fits predict genuine held-out periods", {
  for (model in c("ACL", "ALSCL")) {
    x <- hindcast_test_input(model)
    out <- hindcast_model(x, model = tolower(model), nfolds = 2,
      nstarts = 2, save_fits = TRUE)
    expect_identical(out$diagnostics$origin, c(2002, 2003))
    expect_true(all(out$diagnostics$numerical_ok))
    expect_true(all(out$diagnostics$prediction_ok))
    expect_identical(out$diagnostics$nstarts, c(2L, 2L))
    expect_equal(out$scores$n, 18)
    expect_true(all(is.finite(out$predictions$predicted_log)))
    expect_identical(out$predictions$year, rep(c(2003, 2004), each = 9))
    for (i in seq_along(out$fits)) {
      f <- out$fits[[i]]
      expect_null(f$obj)
      expect_equal(max(f$year), out$diagnostics$origin[i])
      expect_equal(ncol(out$recipes[[i]]$args$data.CatL) - 1L, i + 2L)
      expect_equal(nrow(out$start_diagnostics[[i]]), 2L)
      expect_identical(f$workers, 1L)
    }
    errors <- out$predictions$error_log
    expect_equal(out$scores$log_RMSE, sqrt(mean(errors^2)))
    expect_equal(out$scores$log_MAE, mean(abs(errors)))
  }
})

test_that("held-out indices and biology cannot alter a fold's predictions", {
  for (model in c("ACL", "ALSCL")) {
    x <- hindcast_test_input(model)
    baseline <- hindcast_model(x, model = tolower(model), nfolds = 1, horizon = 2)
    changed <- x
    changed$data.CatL[, 5:6] <- changed$data.CatL[, 5:6] * 100
    changed$data.wgt[, 5:6] <- changed$data.wgt[, 5:6] * 20
    changed$data.mat[, 5:6] <- .1
    other <- hindcast_model(changed, model = tolower(model), nfolds = 1, horizon = 2)
    expect_identical(other$predictions$predicted_log, baseline$predictions$predicted_log)
    expect_identical(other$process_paths, baseline$process_paths)
    expect_identical(other$recipes[[1]]$args, baseline$recipes[[1]]$args)
    expect_equal(other$predictions$observed_log - baseline$predictions$observed_log,
      rep(log(100), nrow(baseline$predictions)))
    expect_true(other$scores$log_RMSE[1] > baseline$scores$log_RMSE[1])
    expect_null(baseline$fits)
  }
})

test_that("quarterly horizons and common F retain model-step coordinates", {
  for (model in c("ACL", "ALSCL")) {
    x <- hindcast_test_input(model)
    x$rec.age <- .25
    x$growth_step <- .25
    x$F_structure <- "year"
    for (nm in c("data.CatL", "data.wgt", "data.mat"))
      names(x[[nm]]) <- c("LengthBin", as.character(2000 + (0:4) * .25))
    # Generate a compatible known trajectory on the quarterly grid before fitting.
    prepared <- do.call(ALSCL:::.acl_prepare_data,
      x[intersect(names(x), names(formals(ALSCL:::.acl_prepare_data)))])
    setup <- ALSCL:::.acl_model_setup(model, prepared, x$parameters, map = x$map,
      F_structure = "year")
    info <- ALSCL:::.acl_compile(model)
    obj <- TMB::MakeADFun(setup$data, setup$parameters, DLL = info$dll_name, silent = TRUE)
    x$data.CatL[-1L] <- exp(obj$report(obj$par)$Elog_index)
    out <- hindcast_model(x, model = tolower(model), horizon = 2, nfolds = 1,
      save_fits = TRUE)
    expect_true(out$diagnostics$prediction_ok)
    expect_identical(out$time_step, .25)
    expect_identical(out$predictions$year, rep(c(2000.75, 2001), each = 9))
    expect_identical(out$predictions$horizon, rep(1:2, each = 9))
    expect_equal(out$scores$n, c(9L, 9L))
    expect_true(all(apply(out$process_paths[[1]]$F, 2, function(z) length(unique(z))) == 1L))
  }
})

test_that("conditional log-process paths reproduce independent C++ future indices", {
  for (model in c("ACL", "ALSCL")) for (F_structure in c("group_year", "year")) {
    x <- hindcast_test_input(model)
    x$F_structure <- F_structure
    prepared <- do.call(ALSCL:::.acl_prepare_data,
      x[intersect(names(x), names(formals(ALSCL:::.acl_prepare_data)))])
    setup <- ALSCL:::.acl_model_setup(model, prepared, x$parameters, map = x$map,
      F_structure = F_structure)
    p <- setup$parameters
    p$logit_log_R <- qlogis(.6)
    p$logit_log_F_y <- qlogis(.8)
    p$dev_log_R <- c(-.1, .2, .4, .4 * .6, .4 * .6^2)
    groups <- nrow(p$dev_log_F)
    p$dev_log_F <- outer(seq_len(groups) / 20, c(-1, .5, 1, .8, .8^2))
    info <- ALSCL:::.acl_compile(model)
    obj <- TMB::MakeADFun(setup$data, p, DLL = info$dll_name, silent = TRUE)
    truth <- obj$report(obj$par)
    prefix <- truth
    Fname <- if (model == "ACL") "F" else "FL"
    prefix[[Fname]] <- truth[[Fname]][, 1:3, drop = FALSE]
    prefix[["NA"]] <- truth[["NA"]][, 1:3, drop = FALSE]
    prefix$dev_log_R <- truth$dev_log_R[1:3]
    prefix$dev_log_F <- truth$dev_log_F[, 1:3, drop = FALSE]
    if (model == "ALSCL") prefix$NLA <- truth$NLA[, , 1:3, drop = FALSE]
    args <- ALSCL:::.acl_resolved_args(x, tolower(model))
    training <- ALSCL:::.acl_hindcast_args(args, 3L, tolower(model))
    fit <- list(report = prefix, model_type = model, year = prepared$year[1:3],
      age = setup$data$age, len_mid = prepared$bins$mid,
      len_label = prepared$bins$labels, growth_step = prepared$growth_step,
      recipe = list(args = training), diagnostics = list(numerical_ok = TRUE))
    predicted <- ALSCL:::.acl_hindcast_predict(fit, 2L)
    expect_equal(unname(predicted$predicted_log), truth$Elog_index[, 4:5],
      tolerance = 1e-12)
    expect_equal(as.numeric(predicted$recruitment), as.numeric(truth$Rec[4:5]),
      tolerance = 1e-12)
    expect_equal(unname(predicted$F), truth[[Fname]][, 4:5], tolerance = 1e-12)
  }
})

test_that("missing and zero held-out cells stay explicit and unscored", {
  x <- hindcast_test_input()
  x$data.CatL[1, 5] <- NA_real_
  x$data.CatL[2, 6] <- 0
  out <- hindcast_model(x, horizon = 2, nfolds = 1)
  d <- out$predictions
  expect_equal(nrow(d), 18L)
  expect_equal(sum(d$included), 16L)
  expect_identical(d$status[c(1, 11)], c("missing_observation", "zero_observation"))
  expect_true(all(is.na(d$error_log[c(1, 11)])))
  expect_true(all(is.finite(d$predicted_log)))
  expect_equal(out$scores$n_positive, c(8L, 8L))
  expect_equal(out$scores$n, c(8L, 8L))
})

test_that("naive scaling uses adjacent positive training periods without compression", {
  observed <- rbind(exp(c(0, 1, 3, 6)), c(1, NA, exp(2), exp(5)),
    c(1, 0, exp(4), NA), rep(2, 4), rep(NA_real_, 4))
  base <- ALSCL:::.acl_hindcast_baseline(observed)
  expect_equal(base$naive_log, c(6, 5, 4, log(2), NA))
  expect_equal(base$scale_log, c(2, 3, NA, 0, NA))
  expect_identical(base$scale_pairs, c(3L, 1L, 0L, 3L, 0L))
  d <- data.frame(horizon = 1, positive_observation = TRUE,
    predicted_log = c(1, 3, 1, 1), included = c(TRUE, TRUE, FALSE, TRUE),
    error_log = c(2, -6, 20, 1), naive_error_log = c(4, 3, 20, 2),
    scale_log = c(2, 3, 1, 0))
  scores <- ALSCL:::.acl_hindcast_scores(d, 1)
  expect_equal(scores$n, 3)
  expect_equal(scores$n_scaled, 2)
  expect_equal(scores$log_RMSE, sqrt(41/3))
  expect_equal(scores$log_MAE, 3)
  expect_equal(scores$naive_log_RMSE, sqrt(29/3))
  expect_equal(scores$log_MASE, 1.5)
  expect_equal(scores$naive_log_MASE, 1.5)
})

test_that("identity time maps are cropped and unsupported future constraints rejected", {
  for (model in c("ACL", "ALSCL")) {
    x <- hindcast_test_input(model)
    groups <- if (model == "ACL") x$nage else nrow(x$data.CatL)
    x$map$dev_log_R <- factor(seq_len(5L))
    x$map$dev_log_F <- factor(seq_len(groups * 5L))
    out <- hindcast_model(x, model = tolower(model), horizon = 2, nfolds = 1)
    expect_true(out$diagnostics$prediction_ok)
    expect_equal(length(out$settings[[1]]$map$dev_log_R), 3L)
    expect_equal(length(out$settings[[1]]$map$dev_log_F), groups * 3L)
    expect_equal(nlevels(out$settings[[1]]$map$dev_log_F), groups * 3L)
    for (nm in c("dev_log_R", "dev_log_F")) {
      invalid <- x
      invalid$map[[nm]][1] <- NA
      expect_error(hindcast_model(invalid, model = tolower(model), nfolds = 1),
        paste("fixed or tied", nm), fixed = TRUE)
      invalid <- x
      invalid$map[[nm]][2] <- invalid$map[[nm]][1]
      expect_error(hindcast_model(invalid, model = tolower(model), nfolds = 1),
        paste("fixed or tied", nm), fixed = TRUE)
    }
  }
})

test_that("failed folds retain diagnostics and cannot contribute scores", {
  x <- hindcast_test_input()
  out <- hindcast_model(x, nfolds = 2, control = list(iter.max = 0, eval.max = 1),
    polish = FALSE, parameters = modifyList(x$parameters, list(mean_log_R = log(1))))
  expect_equal(nrow(out$diagnostics), 2L)
  expect_false(any(out$diagnostics$numerical_ok))
  expect_false(any(out$diagnostics$prediction_ok))
  expect_true(all(is.na(out$predictions$predicted_log)))
  expect_false(any(out$predictions$included))
  expect_true(all(out$predictions$status == "fit_failed"))
  expect_equal(length(out$process_paths), 2L)
  expect_equal(out$scores$n, 0L)
  expect_true(is.na(out$scores$log_RMSE))
  expect_true(is.na(out$scores$log_MASE))
  empty_training <- x
  empty_training$data.CatL[, 2:4] <- NA_real_
  failure <- hindcast_model(empty_training, horizon = 2, nfolds = 1)
  expect_match(failure$diagnostics$error, "positive survey observation")
  expect_equal(nrow(failure$predictions), 18L)
  expect_equal(failure$scores$n, c(0, 0))
})

test_that("prediction failures and unknown screens are retained without scoring", {
  x <- hindcast_test_input()
  args <- ALSCL:::.acl_resolved_args(x, "acl", list(ncores = 1, silent = TRUE))
  settings <- list(ALSCL:::.acl_hindcast_args(args, 4L, "acl"))
  result <- ALSCL:::.acl_batch_apply(settings, "acl", 1L)
  local_mocked_bindings(.acl_batch_apply = function(...) result,
    .acl_hindcast_predict = function(...) {
      warning("forecast diagnostic warning")
      stop("intentional forecast failure")
    }, .package = "ALSCL")
  failure <- hindcast_model(x, nfolds = 1)
  expect_true(failure$diagnostics$numerical_ok)
  expect_false(failure$diagnostics$prediction_ok)
  expect_match(failure$diagnostics$prediction_error, "intentional forecast failure")
  expect_match(failure$diagnostics$warnings, "forecast diagnostic warning")
  expect_true(all(failure$predictions$status == "prediction_failed"))
  expect_equal(failure$scores$n, 0L)
  result[[1]]$fit$diagnostics <- NULL
  unknown <- hindcast_model(x, nfolds = 1)
  expect_false(unknown$diagnostics$numerical_ok)
  expect_match(unknown$diagnostics$issues, "numerical screen unavailable")
  expect_identical(unknown$diagnostics$prediction_error, "")
  expect_false(unknown$diagnostics$prediction_ok)
  expect_true(all(is.na(unknown$predictions$predicted_log)))
})

test_that("socket folds and sequential folds retain identical forecasts", {
  for (model in c("acl", "alscl")) {
    x <- hindcast_test_input(toupper(model))
    sequential <- hindcast_model(x, model = model, nfolds = 2, nstarts = 2)
    parallel <- hindcast_model(x, model = model, nfolds = 2, nstarts = 2, ncores = 2)
    expect_identical(parallel$predictions, sequential$predictions)
    expect_identical(parallel$scores, sequential$scores)
    expect_identical(parallel$process_paths, sequential$process_paths)
    expect_identical(parallel$workers, 2L)
    expect_equal(length(unique(parallel$diagnostics$pid)), 2L)
    expect_true(all(parallel$diagnostics$pid != Sys.getpid()))
    expect_true(all(vapply(parallel$start_diagnostics,
      function(x) length(unique(x$pid)) == 1L && nrow(x) == 2L, logical(1))))
  }
})

test_that("fold counts and controls are validated before fitting", {
  x <- hindcast_test_input()
  expect_error(hindcast_model(x), "only 2 origins", fixed = TRUE)
  expect_error(hindcast_model(x, horizon = 5, nfolds = 1), "only 0 origins", fixed = TRUE)
  expect_error(hindcast_model(x, horizon = .5), "horizon")
  expect_error(hindcast_model(x, min_train = 1), "min_train")
  expect_error(hindcast_model(x, nstarts = 0), "nstarts")
  expect_error(hindcast_model(x, nfolds = 1, silent = NA), "silent")
  expect_error(hindcast_model(x, nfolds = 1, save_fits = 1), "save_fits")
  expect_error(hindcast_model(x, nfolds = 1, typo_argument = 1), "Unknown|unknown")
  x$ncores <- 6L
  default <- hindcast_model(x, nfolds = 1)
  expect_identical(default$diagnostics$nstarts, 1L)
  x$nstarts <- 2L
  bundled <- hindcast_model(x, nfolds = 1)
  expect_identical(bundled$diagnostics$nstarts, 2L)
  explicit <- hindcast_model(x, nfolds = 1, nstarts = 1)
  expect_identical(explicit$diagnostics$nstarts, 1L)
})
