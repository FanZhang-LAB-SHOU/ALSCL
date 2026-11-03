# Exercise the actual helper and save call maintained in the own-data script
# and its English/Chinese tutorials, using the gallery's already fitted models.
# Called by scripts/test_plot_examples.R so all three CI platforms run it.
check_portable_own_data_examples <- function(fits) {
  stopifnot(all(c("acl", "alscl") %in% names(fits)),
    inherits(fits$acl, "alscl_fit"), inherits(fits$alscl, "alscl_fit"))
  directory <- tempfile("alscl-portable-examples-")
  stopifnot(dir.create(directory))
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)

  expressions <- function(path) {
    if (grepl("[.]R$", path)) return(as.list(parse(path, keep.source = FALSE)))
    lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
    starts <- which(grepl("^```r[[:space:]]*$", lines))
    unlist(lapply(starts, function(start) {
      end <- which(seq_along(lines) > start & trimws(lines) == "```")[1L]
      if (is.na(end)) stop("Unclosed R block in ", path, call. = FALSE)
      as.list(parse(text = lines[seq.int(start + 1L, end - 1L)], keep.source = FALSE))
    }), recursive = FALSE)
  }
  helper <- function(expr) is.call(expr) && identical(expr[[1L]], as.name("<-")) &&
    identical(expr[[2L]], as.name("portable"))
  save_call <- function(expr) is.call(expr) && identical(expr[[1L]], as.name("saveRDS")) &&
    any(grepl("assessment_summary.rds", deparse(expr), fixed = TRUE))
  paths <- c("scripts/fit_own_data_example.R", paste0("website/content/", c("en", "zh"),
    "/articles/case-fit-survey.md"))
  expected_helper <- expected_save <- NULL
  for (path in paths) {
    code <- expressions(path)
    portable <- Filter(helper, code)
    save <- Filter(save_call, code)
    stopifnot(length(portable) == 1L, length(save) == 1L)
    if (is.null(expected_helper)) {
      expected_helper <- portable[[1L]]
      expected_save <- save[[1L]]
    } else stopifnot(identical(portable[[1L]], expected_helper),
                     identical(save[[1L]], expected_save))
    env <- new.env(parent = baseenv())
    env$a <- fits$acl; env$b <- fits$alscl
    env$checks <- list(ACL = summary(fits$acl)$diagnostics,
                       ALSCL = summary(fits$alscl)$diagnostics)
    env$output_dir <- directory
    eval(portable[[1L]], env)
    eval(save[[1L]], env)
    restored <- readRDS(file.path(directory, "assessment_summary.rds"))
    stopifnot(identical(names(restored), c("ACL", "ALSCL", "diagnostics")),
              identical(restored$diagnostics, env$checks))
    for (model in c("ACL", "ALSCL")) {
      original <- fits[[tolower(model)]]
      saved <- restored[[model]]
      stopifnot(is.null(saved$obj), identical(class(saved), class(original)),
                inherits(summary(saved), "summary.alscl_fit"),
                identical(summary(saved), summary(original)))
      original$obj <- NULL
      stopifnot(identical(saved, original))
    }
    cat("PASS portable own-data RDS and assessment summary dispatch:", path, "\n")
  }
  invisible(TRUE)
}
