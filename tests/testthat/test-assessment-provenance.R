test_that("source revisions are read without requiring a git executable", {
  root <- tempfile("assessment-source-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE))
  sha <- paste(rep("a", 40), collapse = "")
  expect_true(is.na(ALSCL:::.acl_checkout_revision(root)))
  expect_true(is.na(ALSCL:::.acl_checkout_revision("")))
  dir.create(file.path(root, ".git", "refs", "heads"), recursive = TRUE)
  writeLines("ref: refs/heads/main", file.path(root, ".git", "HEAD"))
  writeLines(sha, file.path(root, ".git", "refs", "heads", "main"))
  expect_identical(ALSCL:::.acl_checkout_revision(root), sha)
  unlink(file.path(root, ".git", "refs", "heads", "main"))
  writeLines(c("# pack-refs with: peeled", paste(sha, "refs/heads/main")),
    file.path(root, ".git", "packed-refs"))
  expect_identical(ALSCL:::.acl_checkout_revision(root), sha)
  writeLines(sha, file.path(root, ".git", "HEAD"))
  expect_identical(ALSCL:::.acl_checkout_revision(root), sha)

  worktree <- file.path(root, "worktree")
  dir.create(worktree)
  dir.create(file.path(root, "metadata"))
  writeLines("gitdir: ../metadata", file.path(worktree, ".git"))
  writeLines("../.git", file.path(root, "metadata", "commondir"))
  writeLines("ref: refs/heads/main", file.path(root, "metadata", "HEAD"))
  expect_identical(ALSCL:::.acl_checkout_revision(worktree), sha)
  writeLines("broken revision", file.path(root, "metadata", "HEAD"))
  expect_true(is.na(ALSCL:::.acl_checkout_revision(worktree)))
})

test_that("installed source metadata has a noninvented fallback", {
  root <- tempfile("assessment-installed-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE))
  sha <- paste(rep("b", 40), collapse = "")
  remote <- ALSCL:::.acl_source_identity(list(RemoteSha = sha, RemoteType = "github"), root)
  expect_identical(remote$revision, sha)
  expect_identical(remote$revision_source, "DESCRIPTION RemoteSha")
  expect_identical(remote$remote_type, "github")
  repository <- ALSCL:::.acl_source_identity(list(Repository = "CRAN"), root)
  expect_identical(repository$repository, "CRAN")
  expect_true(is.na(repository$revision))
  expect_true(is.na(repository$revision_source))
  expect_true(is.na(ALSCL:::.acl_source_identity(list(RemoteSha = "not a commit"), root)$revision))
})

test_that("new recipes record source hashes and portable runtime metadata", {
  for (model in c("ACL", "ALSCL")) {
    fit <- ALSCL:::.acl_attach_recipe(list(), model, list())
    info <- fit$recipe$implementation
    files <- c(paste0(model, ".cpp"), "model_math.hpp")
    paths <- vapply(files, function(file) system.file("extdata", file, package = "ALSCL"), character(1))
    expect_identical(info$model_sources, stats::setNames(unname(tools::md5sum(paths)), files))
    expect_identical(info$runtime$platform, R.version$platform)
    expect_identical(info$runtime$RcppEigen, as.character(utils::packageVersion("RcppEigen")))
    expect_false(any(grepl("[/\\\\]", names(info$model_sources))))
    expect_false(any(grepl("[/\\\\]", names(info$r_sources))))
    expect_false(grepl("[/\\\\]", info$runtime$BLAS))
    expect_no_warning(ALSCL:::.acl_check_implementation(fit$recipe))
  }
})

test_that("implementation checks distinguish known changes from unavailable metadata", {
  recipe <- ALSCL:::.acl_attach_recipe(list(), "acl", list())$recipe
  current <- recipe$implementation
  current$source$revision <- paste(rep("a", 40), collapse = "")
  current$r_sources <- c("core.R" = paste(rep("a", 32), collapse = ""))
  local_mocked_bindings(.acl_implementation = function(model) current)
  recipe$implementation <- current
  original <- recipe
  recipe$implementation$model_sources["ACL.cpp"] <- paste(rep("0", 32), collapse = "")
  expect_warning(ALSCL:::.acl_check_implementation(recipe), "model source ACL.cpp")
  recipe <- original
  recipe$implementation$source$revision <- paste(rep("0", 40), collapse = "")
  expect_warning(ALSCL:::.acl_check_implementation(recipe), "source revision")
  recipe <- original
  recipe$implementation$r_sources[1L] <- paste(rep("0", 32), collapse = "")
  expect_warning(ALSCL:::.acl_check_implementation(recipe), "R source files")
  recipe <- original
  recipe$versions$TMB <- "0.0.0"
  expect_warning(ALSCL:::.acl_check_implementation(recipe), "TMB version")
  recipe <- original
  recipe$implementation$runtime$RcppEigen <- "0.0.0"
  expect_warning(ALSCL:::.acl_check_implementation(recipe), "RcppEigen version")
  recipe <- original
  recipe$implementation$source$revision <- NA_character_
  recipe$implementation$model_sources[] <- NA_character_
  recipe$implementation$r_sources <- character()
  recipe$implementation$source$built <- "an older build timestamp"
  recipe$implementation$runtime$platform <- "another-platform"
  expect_no_warning(ALSCL:::.acl_check_implementation(recipe))
  recipe$implementation <- NULL
  expect_no_warning(ALSCL:::.acl_check_implementation(recipe))
})

test_that("archives retain source provenance and older archives still refit", {
  fit <- fit_fixture("ACL")$result
  file <- tempfile(fileext = ".rds")
  withr::defer(unlink(file))
  save_assessment(fit, file)
  saved <- read_assessment(file)
  expect_identical(saved$recipe$implementation, fit$recipe$implementation)
  expect_identical(saved$recipe$schema_version, 1L)
  expect_null(saved$obj)
  saved$recipe$implementation$model_sources["ACL.cpp"] <- paste(rep("0", 32), collapse = "")
  expect_warning(replay <- refit_model(saved, silent = TRUE), "model source ACL.cpp")
  expect_equal(replay$report$SSB, fit$report$SSB, tolerance = 1e-10)
  expect_identical(replay$recipe$implementation$model_sources, fit$recipe$implementation$model_sources)
  saved$recipe$implementation <- NULL
  save_assessment(saved, file, overwrite = TRUE)
  old <- read_assessment(file)
  expect_no_warning(replay <- refit_model(old, silent = TRUE))
  expect_equal(replay$report$SSB, fit$report$SSB, tolerance = 1e-10)
  legacy <- fit
  legacy$recipe <- NULL
  save_assessment(legacy, file, x = fit$recipe$args, overwrite = TRUE)
  reconstructed <- read_assessment(file)
  expect_null(reconstructed$recipe$implementation)
  expect_match(reconstructed$recipe$provenance, "unverified")
})
