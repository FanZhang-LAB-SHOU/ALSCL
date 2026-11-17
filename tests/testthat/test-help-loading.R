test_that("source help is read from the selected tree without installed indices", {
  path <- tempfile("source-help-")
  dir.create(file.path(path, "man"), recursive = TRUE)
  on.exit(unlink(path, recursive = TRUE), add = TRUE)
  writeLines(c("\\name{source_only}", "\\alias{source_only}",
    "\\title{Help from this source tree}",
    "\\description{A topic that is absent from the installed package.}"),
    file.path(path, "man", "source_only.Rd"))
  db <- test_rd_database(package_path = path)
  expect_named(db, "source_only.Rd")
  expect_s3_class(db[[1L]], "Rd")
  expect_match(paste(as.character(db[[1L]]), collapse = ""),
    "Help from this source tree", fixed = TRUE)
})

test_that("installed help is read from its library database", {
  db <- test_rd_database("stats")
  expect_true("acf.Rd" %in% names(db))
  expect_identical(db[["acf.Rd"]], tools::Rd_db("stats")[["acf.Rd"]])
})

test_that("the loaded ALSCL package supplies all tested help topics", {
  db <- test_rd_database()
  for (name in c("ALSCL-package.Rd", "acl_theme_set.Rd", "self_test.Rd",
                 "run_acl.Rd", "run_alscl.Rd")) {
    expect_true(name %in% names(db), info = name)
    expect_s3_class(db[[name]], "Rd")
  }
})
