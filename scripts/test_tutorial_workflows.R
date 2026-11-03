# Exercise tutorial dependencies without fitting models or loading ALSCL.
# Run from the repository root with base R.
(function() {
  test_dir <- tempfile("alscl-tutorials-")
  stopifnot(dir.create(test_dir))
  test_dir <- normalizePath(test_dir, mustWork = TRUE)
  on.exit(unlink(test_dir, recursive = TRUE), add = TRUE)
  owned_file <- function(path) {
    if (!is.character(path) || length(path) != 1L || is.na(path) ||
        !identical(normalizePath(dirname(path), mustWork = TRUE), test_dir))
      stop("Tutorial test file must be inside its temporary directory.", call. = FALSE)
    path
  }
  code_blocks <- function(lines) {
    result <- list(); current <- NULL
    for (line in lines) {
      if (is.null(current)) {
        if (identical(trimws(line), "```r")) current <- character()
      } else if (identical(trimws(line), "```")) {
        result[[length(result) + 1L]] <- parse(text = current)
        current <- NULL
      } else current <- c(current, line)
    }
    stopifnot(is.null(current))
    result
  }
  section <- function(lines, id) {
    start <- grep(paste0('^<h[23] id="', id, '">'), lines)
    stopifnot(length(start) == 1L)
    following <- which(grepl('^<h[23] ', lines) & seq_along(lines) > start)
    end <- if (length(following)) following[1L] - 1L else length(lines)
    lines[seq.int(start, end)]
  }
  run_blocks <- function(blocks, env) {
    for (block in blocks) for (expr in block) eval(expr, envir = env)
  }
  no_library <- function(package, ...) {
    stopifnot(identical(substitute(package), quote(ALSCL)))
    invisible(NULL)
  }

  # Rejected installations must stop before sourcing helpers, reading inputs,
  # compiling or fitting. Accepted installations proceed to the helper load.
  version_gate <- function(expressions) {
    for (version in c("2.3.0", "2.3.99", "2.4.0", "2.4.1")) {
      env <- new.env(parent = baseenv())
      env$library <- no_library
      env$packageVersion <- function(package) {
        stopifnot(identical(package, "ALSCL"))
        package_version(version)
      }
      env$source <- function(...) stop("reached helper load", call. = FALSE)
      error <- tryCatch({
        for (expr in expressions) eval(expr, env)
        NULL
      }, error = identity)
      stopifnot(inherits(error, "error"))
      if (package_version(version) < "2.4.0")
        stopifnot(grepl("requires ALSCL >= 2.4.0", conditionMessage(error), fixed = TRUE))
      else stopifnot(identical(conditionMessage(error), "reached helper load"))
    }
  }
  version_gate(parse("scripts/fit_own_data_example.R"))
  for (lang in c("en", "zh")) {
    own_data <- readLines(file.path("website/content", lang, "articles/case-fit-survey.md"),
      warn = FALSE, encoding = "UTF-8")
    blocks <- code_blocks(own_data)
    script_block <- Filter(function(block)
      any(grepl("scripts/plot_helpers.R", deparse(block), fixed = TRUE)), blocks)
    stopifnot(length(script_block) == 1L)
    version_gate(script_block[[1L]])

    # Follow the documented hindcast-only route in a fresh environment. Use
    # the real bundled input, and record workflow calls instead of fitting.
    page <- readLines(file.path("website/content", lang, "articles/case-model-validation.md"),
      warn = FALSE, encoding = "UTF-8")
    env <- new.env(parent = baseenv())
    env$library <- no_library
    env$data <- function(name) {
      stopifnot(identical(name, "YTF_example"))
      load("data/YTF_example.rda", envir = parent.frame())
    }
    env$run_acl <- env$run_alscl <- env$simulate_fit <- env$save_assessment <-
      function(...) stop("hindcast-only route unexpectedly requires a full-data fit", call. = FALSE)
    calls <- list()
    env$hindcast_model <- function(x, model, ...) {
      stopifnot(is.list(x), all(c("data.CatL", "data.wgt", "data.mat") %in% names(x)))
      calls[[length(calls) + 1L]] <<- list(model = model, args = list(...))
      list(diagnostics = data.frame(model = model, prediction_ok = TRUE),
        scores = data.frame(model = model, log_RMSE = 0.1),
        predictions = data.frame(model = model, year = 2019, predicted_log_index = 1))
    }
    env$head <- utils::head
    env$tempfile <- function(pattern = "file", tmpdir = tempdir(), fileext = "")
      owned_file(base::tempfile(basename(pattern), tmpdir = test_dir, fileext = fileext))
    env$saveRDS <- function(object, file, ...)
      base::saveRDS(object, file = owned_file(file), ...)
    outside <- tempfile("alscl-outside-test-")
    rejected <- tryCatch(env$saveRDS(list(), outside), error = identity)
    stopifnot(inherits(rejected, "error"),
      grepl("inside its temporary directory", conditionMessage(rejected), fixed = TRUE),
      !file.exists(outside))
    run_blocks(code_blocks(section(page, "section-1")), env)
    stopifnot(exists("x", env, inherits = FALSE), !exists("b", env, inherits = FALSE))
    run_blocks(code_blocks(section(page, "section-4")), env)
    stopifnot(identical(vapply(calls, `[[`, character(1), "model"), c("acl", "alscl")),
      all(vapply(calls, function(call) identical(call$args$horizon, 1), logical(1))))
    run_blocks(code_blocks(section(page, "save-record")), env)
    record <- readRDS(owned_file(env$validation_file))
    unlink(owned_file(env$validation_file))
    stopifnot(identical(names(record), c("acl", "alscl")),
      identical(record$acl, env$acl_validation), identical(record$alscl, env$alscl_validation))
  }
  cat("PASS: tutorial version gates reject old packages before work; both languages complete the hindcast-only route without a full-data fit.\n")
})()
