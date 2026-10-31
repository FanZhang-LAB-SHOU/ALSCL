test_that("simulation table conversion preserves recorded coordinates and rejects relabeling", {
  convert <- ALSCL:::.acl_simulation_to_tables
  sm <- list(nyear = 4L, growth_step = .25, years = 2000 + (0:3) / 4,
    len_mid = c(6, 8, 10), SN_at_len = matrix(1:12, 4, 3),
    weight = matrix(2, 3, 4), mat = matrix(.5, 3, 4))
  pa <- list(len_mid = sm$len_mid, growth_step = .25, first.year = 1990)
  expected <- convert(sm, pa)
  expect_identical(expected$data.CatL$LengthBin, c("6", "8", "10"))
  expect_equal(as.matrix(expected$data.CatL[-1]), t(sm$SN_at_len), ignore_attr = TRUE)
  expect_identical(names(expected$data.CatL)[-1], as.character(sm$years))
  expect_identical(convert(sm), expected)
  expect_identical(convert(sm, pa["growth_step"]), expected)
  legacy <- sm; legacy$len_mid <- NULL
  expect_identical(convert(legacy, pa), expected)
  expect_error(convert(legacy), "length coordinates are required")
  wrong <- pa; wrong$len_mid <- wrong$len_mid + 100
  expect_error(convert(sm, wrong), "must match.*coordinates")
  wrong$len_mid <- c(6, 8)
  expect_error(convert(sm, wrong), "must match.*coordinates")
  for (mid in list(c(6, 6, 10), c(6, 5, 10), c(6, NA, 10), c(0, 8, 10))) {
    wrong <- sm; wrong$len_mid <- mid
    expect_error(convert(wrong, pa), "finite, positive and increasing")
  }
  for (name in c("SN_at_len", "weight", "mat")) {
    wrong <- sm; wrong[[name]] <- wrong[[name]][-1, , drop = FALSE]
    expect_error(convert(wrong, pa), paste0(name, " dimensions"))
  }
  one <- sm; one$nyear <- 1L; one$years <- 2000
  one$SN_at_len <- sm$SN_at_len[1, , drop = FALSE]
  one$weight <- sm$weight[, 1, drop = FALSE]; one$mat <- sm$mat[, 1, drop = FALSE]
  expect_identical(dim(convert(one, pa)$data.CatL), c(3L, 2L))
  expect_identical(names(convert(sm, pa, first_year = 1980)$data.CatL)[-1],
                   as.character(1980 + (0:3) / 4))
  expect_error(convert(sm, pa, first_year = Inf), "first.year")
})

test_that("batch reruns persist current failures instead of stale successes", {
  x <- fit_fixture("ACL"); f <- x$input; fit <- x$result
  folder <- tempfile("rerun-simulation-"); dir.create(folder)
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  sim.data <- list(SN_at_len = t(as.matrix(f$data.CatL[-1])), nyear = length(fit$year),
    nage = length(fit$age), ages = fit$age, growth_step = 1, len_mid = fit$len_mid,
    len_border = fit$len_border, weight = as.matrix(f$data.wgt[-1]),
    mat = as.matrix(f$data.mat[-1]), q_surv_L50 = f$sel_L50, q_surv_L95 = f$sel_L95)
  for (i in 1:2) save(sim.data, file = file.path(folder, paste0("sim_rep", i)))
  read_result <- function(i) {
    e <- new.env(parent = emptyenv())
    load(file.path(folder, paste0("result_rep_", i)), e)
    e$result
  }
  for (workers in c(1L, 2L)) {
    success <- sim_acl(1:2, folder, folder, parameters = x$parameters, map = x$map,
                        M = f$M, ncores = workers)
    for (i in 1:2) {
      expect_null(success[[i]]$error)
      expect_equal(read_result(i)$opt$objective, success[[i]]$opt$objective)
    }
    failed <- sim_acl(1:2, folder, folder, parameters = x$parameters,
      map = list(no_such_parameter = factor(NA)), M = f$M, ncores = workers)
    for (i in 1:2) {
      expect_identical(failed[[i]]$converge, "FAILED")
      expect_match(failed[[i]]$error, "Unknown map parameter")
      expect_identical(read_result(i), failed[[i]])
      expect_null(read_result(i)$opt)
    }
  }
  # A directory is not a previous result and must never be recursively removed.
  blocked <- file.path(folder, "blocked"); dir.create(blocked)
  writeLines("keep", file.path(blocked, "user-file"))
  expect_error(ALSCL:::.acl_save_simulation_result(list(), blocked), "over a directory")
  expect_identical(readLines(file.path(blocked, "user-file")), "keep")
  expect_false(any(grepl("^\\.alscl-result-", list.files(folder, all.files = TRUE))))
})

test_that("catch reports are stable for tiny mortality in both AD frameworks", {
  old <- getOption("ALSCL.framework")
  on.exit(options(ALSCL.framework = old), add = TRUE)
  for (framework in c("CppAD", "TMBad")) {
    options(ALSCL.framework = framework)
    for (model in c("ACL", "ALSCL")) {
      x <- cpp_fixture(model)
      for (F in c(0, 1e-18, 1e-7, 0.2)) {
        x$data$M <- if (F == .2) .2 else 0
        x$parameters$mean_log_F <- if (F == 0) -1000 else log(F)
        obj <- TMB::MakeADFun(x$data, x$parameters, DLL = x$info$dll_name, silent = TRUE)
        r <- obj$report(obj$par)
        z <- if (model == "ACL") r$Z else r$ZL
        ff <- if (model == "ACL") r$F else r$FL
        nn <- if (model == "ACL") r[["NA"]] else r$NL
        integral <- matrix(1, nrow(z), ncol(z))
        positive <- z > 0
        integral[positive] <- -expm1(-z[positive]) / z[positive]
        expected <- colSums(nn * ff * integral)
        if (F == 0) expect_true(all(r$CN == 0)) else {
          expect_true(all(r$CN > 0))
          expect_lt(max(abs(r$CN / expected - 1)), 1e-12)
        }
        expect_true(is.finite(obj$fn(obj$par)))
        expect_true(all(is.finite(obj$gr(obj$par))))
        reported <- TMB::MakeADFun(x$data, x$parameters, ADreport = TRUE,
          DLL = x$info$dll_name, silent = TRUE)
        expect_true(all(is.finite(reported$gr(reported$par))))
        expect_equal(colSums(r$CNA), r$CN, tolerance = 1e-12)
      }
    }
  }
})
