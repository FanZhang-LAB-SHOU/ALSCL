# Write a minimal workbook; `errors` maps a sheet name to cell references that
# hold an Excel error value, as a formula such as =1/0 leaves behind.
review_workbook <- function(tables, errors = list(), error_value = "#DIV/0!") {
  folder <- tempfile(); dir.create(folder)
  for (path in c("_rels", "xl/_rels", "xl/worksheets"))
    dir.create(file.path(folder, path), recursive = TRUE, showWarnings = FALSE)
  write_xml <- function(text, path) writeLines(text, file.path(folder, path), useBytes = TRUE)
  n <- seq_along(tables)
  write_xml(paste0('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
    '<Default Extension="xml" ContentType="application/xml"/>',
    '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
    paste0('<Override PartName="/xl/worksheets/sheet', n, '.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>', collapse = ''),
    '</Types>'), '[Content_Types].xml')
  relation <- 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/'
  write_xml(paste0('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
    '<Relationship Id="rId1" Type="', relation, 'officeDocument" Target="xl/workbook.xml"/>',
    '</Relationships>'), '_rels/.rels')
  write_xml(paste0('<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="', relation, '"><sheets>',
    paste0('<sheet name="', names(tables), '" sheetId="', n, '" r:id="rId', n, '"/>', collapse = ''),
    '</sheets></workbook>'), 'xl/workbook.xml')
  write_xml(paste0('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
    paste0('<Relationship Id="rId', n, '" Type="', relation, 'worksheet" Target="worksheets/sheet', n, '.xml"/>', collapse = ''),
    '</Relationships>'), 'xl/_rels/workbook.xml.rels')
  for (i in n) {
    cells <- rbind(names(tables[[i]]), as.matrix(tables[[i]]))
    flagged <- errors[[names(tables)[i]]]
    rows <- vapply(seq_len(nrow(cells)), function(r) {
      reference <- paste0(LETTERS[seq_len(ncol(cells))], r)
      xml <- ifelse(is.na(cells[r, ]), "",
        paste0('<c r="', reference, '" t="inlineStr"><is><t>', cells[r, ], '</t></is></c>'))
      xml[reference %in% flagged] <- paste0('<c r="', reference[reference %in% flagged],
        '" t="e"><f>1/0</f><v>', error_value, '</v></c>')
      paste0('<row r="', r, '">', paste(xml, collapse = ''), '</row>')
    }, character(1))
    write_xml(paste0('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>',
      paste(rows, collapse = ''), '</sheetData></worksheet>'), paste0('xl/worksheets/sheet', i, '.xml'))
  }
  workbook <- tempfile(fileext = '.xlsx')
  withr::with_dir(folder, utils::zip(workbook,
    list.files('.', recursive = TRUE, all.files = TRUE, no.. = TRUE), flags = '-q'))
  workbook
}

test_that("Excel error cells are rejected with their sheet and cell (F37)", {
  skip_if_not_installed("readxl")
  skip_if(!nzchar(Sys.which("zip")), "A zip executable is needed to write the test workbook")
  tables <- fixture_frames()[c("data.CatL", "data.wgt", "data.mat")]

  clean <- review_workbook(tables)
  expect_identical(ALSCL:::.acl_excel_error_cells(clean, names(tables)),
    list(data.CatL = character(), data.wgt = character(), data.mat = character()))
  expect_identical(read_survey_excel(clean), prepare_alscl_data(tables)[names(tables)])

  # readxl imports the error cell as NA, which the tables read as missing.
  broken <- review_workbook(tables, list(data.CatL = "C3"))
  raw <- readxl::read_excel(broken, sheet = "data.CatL", col_types = "text", na = c("", "NA"))
  expect_true(is.na(raw[[3L]][2L]))
  expect_error(read_survey_excel(broken), "sheet data.CatL: C3", fixed = TRUE)
  expect_error(read_survey_excel(broken), "Excel error values")
  expect_error(prepare_alscl_data(file = broken, format = "excel"), "sheet data.CatL: C3", fixed = TRUE)

  several <- review_workbook(tables, list(data.CatL = c("B2", "D5"), data.mat = "F10"), "#N/A")
  expect_error(read_survey_excel(several),
               "sheet data.CatL: B2, D5; sheet data.mat: F10", fixed = TRUE)

  # A blank cell remains a missing observation.
  gaps <- tables
  gaps$data.CatL[2L, 3L] <- NA
  imported <- read_survey_excel(review_workbook(gaps))
  expect_true(is.na(imported$data.CatL[2L, 3L]))
  expect_identical(sum(is.na(as.matrix(imported$data.CatL[-1L]))), 1L)

  # A file that is not a zipped workbook cannot be inspected and is left to readxl.
  expect_null(ALSCL:::.acl_excel_error_cells(tempfile(), names(tables)))
})
