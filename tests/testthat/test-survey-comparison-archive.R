test_that("data verification checks positive indices on each cell's own scale", {
  fixture <- fit_fixture("ACL")
  args <- c(fixture$input, list(parameters = fixture$parameters,
                               map = fixture$map, silent = TRUE))
  args$data.CatL[9, 2] <- 1e-13
  first <- run_acl(args)
  original <- args$data.CatL
  args$data.CatL[9, 2] <- 1e-20
  second <- run_acl(args)
  expect_true(first$diagnostics$numerical_ok)
  expect_true(second$diagnostics$numerical_ok)
  expect_error(compare_models(first, second, original), "observation values")
  expect_error(diagnostic_metrics(args$data.CatL, first), "observation values")

  changed <- original
  changed[9, 2] <- 1e-20
  changed[1, 3] <- original[1, 3] * (1 + 1e-15)
  expect_error(diagnostic_metrics(changed, first), "observation values")
  rounded <- original
  rounded[9, 2] <- original[9, 2] * (1 + 1e-14)
  rounded[[2]] <- sprintf("%.17g", rounded[[2]])
  expect_no_error(diagnostic_metrics(rounded, first))
  first$recipe$args$data.CatL <- changed
  expect_error(simulate_fit(first, nsim = 1), "observation values")
})

test_that("archived parameter estimates can be read with legacy optimizer controls", {
  fit <- fit_fixture("ACL")$result
  expected <- extract_parameters(fit)
  fit$recipe$args$control <- list(100)
  file <- tempfile(tmpdir = withr::local_tempdir(), fileext = ".rds")
  save_assessment(fit, file)
  saved <- read_assessment(file)
  expect_identical(extract_parameters(saved), expected)
  expect_identical(saved$recipe$args$control, list(100))
})

test_that("concurrent archive creation keeps exactly one successful writer", {
  folder <- withr::local_tempdir()
  path <- file.path(folder, "assessment.rds")
  fit <- fit_fixture("ACL")$result
  fit$obj <- NULL
  workers <- parallel::makePSOCKcluster(2)
  withr::defer(parallel::stopCluster(workers))
  ALSCL:::.acl_initialize_workers(workers)
  markers <- file.path(folder, paste0("ready-", 1:2))
  write_archive <- function(id, fit, path, markers) {
    # Synchronize while the fit is first evaluated, after both writers have
    # seen an absent target but before either can publish an archive.
    tryCatch({
      ALSCL::save_assessment({
        file.create(markers[id])
        deadline <- Sys.time() + 30
        while (!all(file.exists(markers))) {
          if (Sys.time() > deadline) stop("Writer synchronization timed out.")
          Sys.sleep(.01)
        }
        fit$writer <- id
        fit
      }, path)
      "saved"
    }, error = conditionMessage)
  }
  environment(write_archive) <- baseenv()
  outcomes <- unlist(parallel::parLapply(workers, 1:2, write_archive, fit, path, markers))
  winner <- which(outcomes == "saved")
  expect_length(winner, 1L)
  expect_match(outcomes[-winner], "already exists|archive lock")
  expect_identical(read_assessment(path)$writer, winner)
  expect_setequal(list.files(folder, all.files = TRUE, no.. = TRUE),
                  basename(c(path, markers)))
})
