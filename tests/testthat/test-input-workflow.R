test_that("survey import and preparation preserve values, periods and explicit map releases", {
  x <- fixture_frames()
  tables <- x[c("data.CatL", "data.wgt", "data.mat")]
  tables$data.CatL[[2]][1:2] <- c(0, NA)
  # Importers use numeric labels, including factors, rather than factor codes.
  tables$data.wgt[[2]] <- factor(as.character(tables$data.wgt[[2]]))
  folder <- tempfile(); dir.create(folder)
  for (nm in names(tables)) utils::write.csv(tables[[nm]],
    file.path(folder, paste0(nm, ".csv")), row.names = FALSE, na = "")
  imported <- read_survey_csv(folder)
  expect_identical(imported$data.CatL[[2]][1:2], c(0, NA_real_))
  expect_identical(imported$data.wgt[[2]], rep(1, nrow(tables$data.wgt)))
  expect_identical(names(imported$data.CatL), names(tables$data.CatL))
  args <- x[setdiff(names(x), names(tables))]
  args$map <- list(log_std_log_F = NULL)
  direct <- prepare_alscl_data(tables, fit_args = args)
  from_csv <- prepare_alscl_data(file = folder, format = "csv", fit_args = args)
  expect_identical(direct, from_csv)
  expect_true("log_std_log_F" %in% names(direct$fit_args$map))
  expect_null(direct$fit_args$map$log_std_log_F)
  check <- check_alscl_data(direct, "acl")
  expect_true(check$valid)
  expect_equal(check$summary$zeros, 1)
  expect_equal(check$summary$missing, 1)
  expect_true(any(grepl("zero observations", check$warnings)))
  direct$fit_args$zero_action <- "error"
  expect_false(check_alscl_data(direct, "acl")$valid)
})

test_that("import validation catches actionable file and alignment failures", {
  x <- fixture_frames()
  tables <- x[c("data.CatL", "data.wgt", "data.mat")]
  expect_error(read_survey_csv(tempfile()), "existing directory")
  folder <- tempfile(); dir.create(folder)
  expect_error(read_survey_csv(folder), "Missing survey CSV files")
  bad <- tables; bad$data.mat <- bad$data.mat[c(2, 1, 3:nrow(bad$data.mat)), ]
  expect_error(prepare_alscl_data(bad), "including order")
  bad <- tables; bad$data.wgt[[2]][1] <- NA_real_
  expect_error(prepare_alscl_data(bad), "Weights must be finite")
  bad <- tables; bad$data.mat[[2]][1] <- 1.2
  expect_error(prepare_alscl_data(bad), "Maturity must be finite")
  bad <- tables; bad$data.CatL[[2]] <- as.character(bad$data.CatL[[2]])
  bad$data.CatL[[2]][1] <- "not measured"
  expect_error(prepare_alscl_data(bad), "nonnumeric cell in time column 2000")
  expect_error(prepare_alscl_data(tables, file = folder), "file is only used")
  expect_error(prepare_alscl_data(tables, format = "csv", file = folder), "cannot also supply")
  expect_error(prepare_alscl_data(tables, fit_args = list(ncore = 2)), "unknown arguments: ncore")
  expect_error(prepare_alscl_data(tables, fit_config = list(other = list())), "unknown arguments: other")
  expect_error(read_survey_excel(tempfile()), "existing Excel workbook")
})

test_that("Excel import checks required sheet names using an actual workbook", {
  skip_if_not_installed("readxl")
  workbook <- readxl::readxl_example("datasets.xlsx")
  expect_error(read_survey_excel(workbook), "Missing workbook sheets: data.CatL, data.wgt, data.mat")
})

test_that("an actual Excel workbook imports to the same tables as native input", {
  skip_if_not_installed("readxl")
  skip_if(!nzchar(Sys.which("zip")), "A zip executable is needed to write the test workbook")
  tables <- fixture_frames()[c("data.CatL", "data.wgt", "data.mat")]
  folder <- tempfile(); dir.create(folder)
  for (path in c("_rels", "xl/_rels", "xl/worksheets"))
    dir.create(file.path(folder, path), recursive = TRUE, showWarnings = FALSE)
  write_xml <- function(text, path) writeLines(text, file.path(folder, path), useBytes = TRUE)
  write_xml(paste0('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
    '<Default Extension="xml" ContentType="application/xml"/>',
    '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
    paste0('<Override PartName="/xl/worksheets/sheet', 1:3, '.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>', collapse = ''),
    '</Types>'), '[Content_Types].xml')
  relation <- 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/'
  write_xml(paste0('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
    '<Relationship Id="rId1" Type="', relation, 'officeDocument" Target="xl/workbook.xml"/>',
    '</Relationships>'), '_rels/.rels')
  write_xml(paste0('<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="', relation, '"><sheets>',
    paste0('<sheet name="', names(tables), '" sheetId="', 1:3, '" r:id="rId', 1:3, '"/>', collapse = ''),
    '</sheets></workbook>'), 'xl/workbook.xml')
  write_xml(paste0('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
    paste0('<Relationship Id="rId', 1:3, '" Type="', relation, 'worksheet" Target="worksheets/sheet', 1:3, '.xml"/>', collapse = ''),
    '</Relationships>'), 'xl/_rels/workbook.xml.rels')
  for (i in seq_along(tables)) {
    cells <- rbind(names(tables[[i]]), as.matrix(tables[[i]]))
    rows <- vapply(seq_len(nrow(cells)), function(r) paste0('<row r="', r, '">',
      paste0('<c r="', LETTERS[seq_len(ncol(cells))], r, '" t="inlineStr"><is><t>',
        cells[r, ], '</t></is></c>', collapse = ''), '</row>'), character(1))
    write_xml(paste0('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>',
      paste(rows, collapse = ''), '</sheetData></worksheet>'), paste0('xl/worksheets/sheet', i, '.xml'))
  }
  workbook <- tempfile(fileext = '.xlsx')
  withr::with_dir(folder, utils::zip(workbook,
    list.files('.', recursive = TRUE, all.files = TRUE, no.. = TRUE), flags = '-q'))
  imported <- read_survey_excel(workbook)
  expected <- prepare_alscl_data(tables)[names(tables)]
  expect_identical(imported, expected)
  expect_identical(prepare_alscl_data(file = workbook, format = "excel"),
    prepare_alscl_data(tables))
})

test_that("resolved arguments retain override precedence and evaluate dependent defaults", {
  x <- YTF_example
  x$fit_args$ncores <- 3L
  x$fit_args$nstarts <- NULL
  x$fit_args$map <- list(log_std_log_F = factor(NA))
  resolved <- .acl_resolved_args(x, "acl", list(ncores = 2L,
    map = list(log_std_log_F = NULL), parameters = NULL))
  expect_identical(names(resolved), names(formals(run_acl)))
  expect_identical(resolved$ncores, 2L)
  expect_identical(resolved$nstarts, 2L)
  expect_null(resolved$parameters)
  expect_true("log_std_log_F" %in% names(resolved$map))
  expect_null(resolved$map$log_std_log_F)
  x$fit_args$nstarts <- 7L
  expect_identical(.acl_resolved_args(x, "acl", list(ncores = 2L))$nstarts, 7L)
  expect_identical(.acl_resolved_args(x, "acl", list(map = NULL))$map, NULL)
})

test_that("inspection and preflight do not compile or optimize and use effective data defaults", {
  local_mocked_bindings(.acl_compile = function(...) stop("must not compile"))
  local_mocked_bindings(MakeADFun = function(...) stop("must not make a TMB object"),
    .package = "TMB")
  x <- fixture_frames()
  for (model in c("acl", "alscl")) {
    table <- inspect_parameters(x, model)
    row <- function(nm) table[table$parameter == nm, , drop = FALSE]
    expect_equal(row("mean_log_R")$start,
      log(mean(colSums(as.matrix(x$data.CatL[-1L])))))
    expect_equal(row("log_init_Z")$natural_start, x$M + .3)
    expect_equal(row(if (model == "acl") "t0" else "log_t0")$upper,
      if (model == "acl") x$rec.age * (1 - 1e-6) else log(x$rec.age * (1 - 1e-6)))
    if (model == "alscl") {
      expect_equal(row("log_Linf")$natural_start, 1.1 * 57.5)
      expect_equal(row("log_Linf")$lower, log(.7 * 57.5))
    }
    check <- check_alscl_data(x, model)
    expect_true(check$valid)
    expect_equal(check$summary$free_fixed, if (model == "acl") 10 else 13)
    expect_equal(check$summary$free_random,
      5 + (if (model == "acl") 4 else 9) * 5 + 3)
    expect_length(check$warnings, 0)
  }
  x$parameters <- list(mean_log_F = 100)
  expect_equal(subset(inspect_parameters(x, "acl"), parameter == "mean_log_F")$start,
    create_parameters("acl")$parameters.U$mean_log_F)
})

test_that("inspection explains explicit releases, shared F, fixed and tied random effects", {
  x <- fixture_frames()
  x$F_structure <- "year"
  x$map <- list(log_sigma_log_F = NULL,
    dev_log_F = factor(c(NA, 1, 1, 2, 2)), dev_log_R = factor(rep(NA, 5)))
  # Tied or fixed deviations with an estimated process SD give a biased
  # likelihood; preflight and inspection reject that combination.
  expect_error(inspect_parameters(x, "alscl"), "dev_log_R fixes deviations while log_sigma_log_R")
  expect_false(check_alscl_data(x, "alscl")$valid)
  x$map <- list(log_sigma_log_F = NULL)
  released <- inspect_parameters(x, "alscl")
  expect_identical(released$status[released$parameter == "log_sigma_log_F"], "free")
  expect_identical(released$map_source[released$parameter == "log_sigma_log_F"], "explicit")
  x$map <- list(dev_log_F = factor(c(NA, 1, 1, 2, 2)), dev_log_R = factor(rep(NA, 5)),
    logit_log_F_y = factor(NA), log_sigma_log_R = factor(NA), logit_log_R = factor(NA))
  table <- inspect_parameters(x, "alscl")
  row <- function(nm) table[table$parameter == nm, , drop = FALSE]
  expect_identical(row("log_sigma_log_F")$status, "fixed")
  expect_identical(row("log_t0")$map_source, "default")
  expect_identical(row("logit_log_F_l")$status, "inactive")
  expect_identical(row("logit_log_F_l")$map_source, "F_structure")
  expect_identical(row("dev_log_F")$dimensions, "1 x 5")
  expect_identical(row("dev_log_F")$status, "mixed")
  expect_equal(unlist(row("dev_log_F")[c("n_free", "n_fixed", "n_tied")]),
    c(n_free = 2, n_fixed = 1, n_tied = 2))
  expect_identical(row("dev_log_R")$status, "fixed")
  expect_equal(check_alscl_data(x, "alscl")$summary$free_random, 5)
  x$map$dev_log_F <- factor(c(1, 1, 2, 2, 2))
  expect_identical(subset(inspect_parameters(x, "alscl"), parameter == "dev_log_F")$status, "tied")
})

test_that("preflight reports missing periods, invalid bounds and maps before fitting", {
  x <- fixture_frames()
  x$data.CatL[[3]] <- NA_real_
  x$data.CatL[1, -1] <- NA_real_
  check <- check_alscl_data(x, "acl")
  expect_true(check$valid)
  expect_equal(check$summary$unobserved_periods, 1)
  expect_equal(check$summary$unobserved_bins, 1)
  expect_true(any(grepl("periods: 2001", check$warnings)))
  expect_true(any(grepl("length bins: 0-20", check$warnings)))
  bad <- x
  for (nm in c("data.CatL", "data.wgt", "data.mat")) bad[[nm]] <- bad[[nm]][, -3]
  check <- check_alscl_data(bad, "acl")
  expect_false(check$valid)
  expect_match(check$errors, "Time column spacing")
  bad <- x; bad$parameters.L <- list(mean_log_R = 31)
  expect_match(check_alscl_data(bad, "acl")$errors, "Invalid bounds for mean_log_R")
  bad <- x; bad$map <- list(dev_log_R = factor(1:4))
  expect_match(check_alscl_data(bad, "acl")$errors, "Map length does not match parameter dev_log_R")
  bad <- x; bad$nstarts <- Inf
  expect_match(check_alscl_data(bad, "acl")$errors, "nstarts must be an integer")
  bad <- x; bad$parameters <- list(log_std_log_F = Inf)
  expect_match(check_alscl_data(bad, "acl")$errors, "starts must be finite")
  bad <- x; bad$control <- c(iter.max = 2)
  expect_match(check_alscl_data(bad, "acl")$errors, "control must be a list")
})

test_that("prepared bundles and inspected maps agree with actual fresh fits", {
  old <- options(ALSCL.sd_cores = 1, ALSCL.framework = "CppAD")
  on.exit(options(old), add = TRUE)
  for (model in c("ACL", "ALSCL")) {
    example <- fit_fixture(model)
    scalar <- tolower(model)
    table_names <- c("data.CatL", "data.wgt", "data.mat")
    args <- c(example$input[setdiff(names(example$input), table_names)],
      list(parameters = example$parameters, map = example$map, silent = TRUE))
    x <- prepare_alscl_data(example$input[table_names], fit_args = args)
    check <- check_alscl_data(x, scalar)
    inspected <- inspect_parameters(x, scalar)
    fit <- (if (model == "ACL") run_acl else run_alscl)(x)
    expect_true(check$valid)
    expect_equal(check$summary$free_fixed, length(fit$opt$par))
    expect_equal(check$summary$free_random, length(fit$obj$env$random))
    expect_identical(fit$report, example$result$report)
    expect_identical(fit$opt$par, example$result$opt$par)
    expect_identical(fit$recipe$model, scalar)
    expect_identical(fit$recipe$args$data.CatL, x$data.CatL)
    expect_identical(inspect_parameters(fit$recipe$args, scalar), inspected)
    # An inspected fixed value is the value actually used by the template.
    expect_equal(subset(inspected, parameter == "log_Linf")$natural_start,
      fit$report$Linf)
  }
})

test_that("preflight and fitting reject the same invalid logical controls", {
  local_mocked_bindings(.acl_compile = function(...) stop("must reject before compiling"))
  for (model in c("acl", "alscl")) {
    fun <- if (model == "acl") run_acl else run_alscl
    for (nm in c("silent", "output", "polish")) {
      for (value in list(c(TRUE, FALSE), NA, logical(), 1, "TRUE")) {
        x <- fixture_frames(); x[nm] <- list(value)
        check <- check_alscl_data(x, model)
        expect_false(check$valid)
        expect_match(check$errors, paste0(nm, " must be TRUE or FALSE"))
        expect_error(fun(x), paste0(nm, " must be TRUE or FALSE"))
      }
    }
  }
})
