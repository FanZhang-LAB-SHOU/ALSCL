# Execute the maintained examples, rather than only parsing their argument names.
# Run from the repository root. Fits are reused; the documented retrospective
# is fitted once and reused only for identical calls in the translated examples.
# Rscript scripts/test_plot_examples.R output/release-225/gallery/fits.rds
check_reference_grid_examples <- function(b, assert_grid_free_plot) {
  notes <- jsonlite::fromJSON("website/reference-notes.json", simplifyVector = FALSE)
  for (name in c("acl_theme", "acl_theme_set", "acl_theme_reset")) {
    for (lang in c("en", "zh")) {
      text <- notes[[name]]$details[[lang]]
      blocks <- regmatches(text, gregexpr("(?s)```r\\n.*?\\n```", text, perl = TRUE))[[1L]]
      if (length(blocks) != 1L)
        stop("Expected one grid-free reference example: ", name, "/", lang)
      code <- sub("^```r\\n", "", sub("\\n```$", "", blocks[[1L]]))
      acl_theme_reset()
      e <- new.env(parent = environment())
      e$b <- b
      plots <- 0L
      for (expr in parse(text = code)) {
        value <- eval(expr, e)
        if (inherits(value, "ggplot")) {
          assert_grid_free_plot(value)
          plots <- plots + 1L
        }
      }
      if (plots != 2L)
        stop("Reference example must create and style one plot: ", name, "/", lang)
      cat("PASS grid-free reference example:", name, lang, "\n")
    }
  }
  invisible(TRUE)
}

# Execute maintained plotting blocks using saved fits, without model refitting.
check_growth_fishing_examples <- function(a, b, assert_grid_free_plot) {
  old <- options(acl.theme = NULL)
  on.exit(options(old), add = TRUE)
  paths <- c("docs/PLOT_GALLERY.md", "docs/PLOT_STYLE.md",
    unlist(lapply(c("en", "zh"), function(lang) paste0("website/content/", lang,
      "/articles/", c("growth-mortality", "model-comparison", "population-plots",
                        "plot-customization"), ".md"))))
  targets <- c("plot_VB", "plot_fishing_mortality", "plot_compare_CatL")
  expensive <- c("run_acl", "run_alscl", "retro_acl", "retro_alscl", "retro_model",
                 "source", "run_ytf_guide", "sim_acl")
  calls_to <- function(expr, names) {
    if (!is.call(expr)) return(list())
    head <- if (is.symbol(expr[[1L]])) as.character(expr[[1L]]) else ""
    here <- if (head %in% names) list(expr) else list()
    c(here, unlist(lapply(as.list(expr)[-1L], calls_to, names = names), recursive = FALSE))
  }
  check <- function(ok, context) {
    if (!isTRUE(ok)) stop(context, call. = FALSE)
  }
  # This is the actual dedicated-label setting shown in the style guide.
  style <- paste(readLines("docs/PLOT_STYLE.md", warn = FALSE), collapse = "\n")
  inline <- regmatches(style, gregexpr("`[^`\\n]+`", style, perl = TRUE))[[1L]]
  survey_setting <- unique(gsub("^`|`$", "", inline[
    grepl("^`acl_theme_set\\(ylab = list\\(survey =", inline)]))
  check(length(survey_setting) == 1L, "Style guide must show one dedicated survey-label setting")
  counts <- stats::setNames(integer(length(targets)), targets)
  custom_survey_checks <- 0L
  for (path in paths) {
    content <- paste(readLines(path, warn = FALSE), collapse = "\n")
    raw <- regmatches(content, gregexpr("(?s)```r\\n.*?\\n```", content, perl = TRUE))[[1L]]
    for (block in raw) {
      code <- sub("^```r\\n", "", sub("\\n```$", "", block))
      expressions <- as.list(parse(text = code))
      target_calls <- unlist(lapply(expressions, calls_to, names = targets), recursive = FALSE)
      costly_calls <- unlist(lapply(expressions, calls_to, names = expensive), recursive = FALSE)
      if (!length(target_calls) || length(costly_calls)) next
      options(acl.theme = NULL)
      acl_theme_set(font_family = "mono", ylab = list(growth = "Length (audit)",
                                                      catch = "Fishery catch (numbers)"))
      e <- new.env(parent = environment())
      e$a <- a; e$b <- b; e$x <- ALSCL::YTF_example; e$dat <- e$x$data.CatL
      for (expr in expressions) {
        value <- eval(expr, e)
        plotted_calls <- calls_to(expr, targets)
        if (!length(plotted_calls)) next
        check(inherits(value, "ggplot"), paste(path, "did not return a plot"))
        assert_grid_free_plot(value)
        check(length(plotted_calls) == 1L, paste(path, "ambiguous plot expression"))
        call <- plotted_calls[[1L]]
        name <- as.character(call[[1L]])
        counts[[name]] <- counts[[name]] + 1L
        arguments <- as.list(call)[-1L]
        if (name == "plot_VB") {
          fit <- eval(arguments[[1L]], e)
          if (is.null(arguments$age_range)) {
            wanted <- range(fit$age)
            wanted[1L] <- max(wanted[1L], fit$report$t0)
            check(isTRUE(all.equal(range(value$data$age), wanted)),
                  paste(path, "default VB range differs from fitted ages"))
          }
          check(all(value$data$age >= fit$report$t0) && all(value$data$length >= 0),
                paste(path, "VB example extrapolated before t0"))
          if (all(c("lower", "upper") %in% names(value$data)))
            check(all(value$data$lower <= value$data$upper), paste(path, "reversed growth interval"))
          wanted_label <- if (is.null(arguments$ylab)) "Length (audit)" else eval(arguments$ylab, e)
          check(identical(value$labels$y, wanted_label), paste(path, "growth label ignored"))
          built <- ggplot2::ggplot_build(value)
          text_layers <- which(vapply(value$layers, function(layer)
            inherits(layer$geom, "GeomText"), logical(1)))
          check(length(text_layers) == 1L, paste(path, "growth annotation missing"))
          wanted_font <- if (is.null(arguments$font_family)) "mono" else eval(arguments$font_family, e)
          check(all(built$data[[text_layers]]$family == wanted_font), paste(path, "annotation font ignored"))
          if (!is.null(arguments$text_size))
            check(all(built$data[[text_layers]]$size == eval(arguments$text_size, e)),
                  paste(path, "annotation size ignored"))
        } else if (name == "plot_compare_CatL") {
          check(identical(value$labels$y, "Survey index"), paste(path, "survey comparison uses catch label"))
          eval(parse(text = survey_setting), e)
          custom <- eval(expr, e)
          assert_grid_free_plot(custom)
          check(identical(custom$labels$y, acl_theme("ylab")$survey),
                paste(path, "dedicated survey label ignored"))
          custom_survey_checks <- custom_survey_checks + 1L
        }
      }
    }
  }
  check(all(counts > 0L), "Missing growth, fishing-mortality or survey-comparison examples")
  cat("PASS maintained plot blocks:", paste(names(counts), counts, collapse = "; "),
      "; custom survey-label checks:", custom_survey_checks, "\n")
  invisible(list(examples = counts, survey_labels = custom_survey_checks))
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  fits_file <- if (length(args)) args[[1L]] else "output/release-225/gallery/fits.rds"
  if (!file.exists(fits_file)) stop("Supply the saved teaching fits as the first argument.")
  pkgload::load_all(quiet = TRUE)
  library(ggplot2)
  library(patchwork)
  source("scripts/plot_helpers.R", local = environment())
  cache <- Sys.getenv("ALSCL_MANUAL_CACHE")
  if (nzchar(cache)) options(ALSCL.tmb.cache = cache)
  fits <- readRDS(fits_file)
  old_theme <- acl_theme()
  on.exit(do.call(acl_theme_set, old_theme), add = TRUE)
  figure_file <- tempfile(fileext = ".pdf")
  grDevices::pdf(figure_file)
  on.exit({ grDevices::dev.off(); unlink(figure_file) }, add = TRUE)

  r_blocks <- function(path) {
    lines <- readLines(path, warn = FALSE)
    starts <- which(grepl("^```r[[:space:]]*$", lines))
    lapply(starts, function(start) {
      end <- which(seq_along(lines) > start & lines == "```")[1L]
      if (is.na(end)) stop("Unclosed R block: ", path)
      paste(lines[seq.int(start + 1L, end - 1L)], collapse = "\n")
    })
  }
  fresh_context <- function() {
    e <- new.env(parent = environment())
    e$a <- fits$acl
    e$b <- fits$alscl
    e$x <- ALSCL::YTF_example
    e
  }
  # Run the real fit once, but avoid repeating the same calculation for the
  # English, Chinese and bilingual copies of an identical documented call.
  cached_args <- NULL
  cached_retro <- NULL
  retrospective_calls <- 0L
  retro_alscl <- function(...) {
    actual <- list(...)
    retrospective_calls <<- retrospective_calls + 1L
    if (is.null(cached_retro) || !identical(actual, cached_args)) {
      cached_retro <<- do.call(ALSCL::retro_alscl, actual)
      cached_args <<- actual
    }
    cached_retro
  }
  evaluate <- function(code, e) {
    plots <- list()
    for (expr in parse(text = code)) {
      value <- eval(expr, e)
      if (inherits(value, "ggplot")) {
        assert_grid_free_plot(value)
        plots[[length(plots) + 1L]] <- value
      }
    }
    plots
  }
  check <- function(ok, context) {
    if (!isTRUE(ok)) stop(context, call. = FALSE)
  }

  check_reference_grid_examples(fits$alscl, assert_grid_free_plot)
  check_growth_fishing_examples(fits$acl, fits$alscl, assert_grid_free_plot)

  style_files <- c("docs/PLOT_STYLE.md", paste0("website/content/", c("en", "zh"),
                                               "/articles/plot-customization.md"))
  for (path in style_files) {
    acl_theme_reset()
    e <- fresh_context()
    check(!exists("rb", e, inherits = FALSE), "Prerequisite test must start without rb")
    calls_before <- retrospective_calls
    plots <- evaluate(r_blocks(path)[[1L]], e)
    check(exists("rb", e, inherits = FALSE), paste(path, "did not create rb"))
    check(retrospective_calls == calls_before + 1L, paste(path, "did not run its retrospective setup"))
    check(length(plots) >= 10L, paste(path, "did not execute all styling examples"))
    cat("PASS setup and styling:", path, "\n")
  }

  gallery_files <- c("docs/PLOT_GALLERY.md", paste0("website/content/", c("en", "zh"),
                                                  "/articles/population-plots.md"))
  for (path in gallery_files) {
    acl_theme_reset()
    calls <- unlist(lapply(r_blocks(path), function(code) as.list(parse(text = code))),
                    recursive = FALSE)
    calls <- Filter(function(expr) is.call(expr) && identical(expr[[1L]], as.name("plot_CatL")) &&
                      identical(as.list(expr)$type, "year"), calls)
    check(length(calls) == 2L, paste(path, "must cover both year-mode scales"))
    for (call in calls) {
      p <- eval(call, fresh_context())
      assert_grid_free_plot(p)
      built <- ggplot2::ggplot_build(p)
      check(identical(unique(built$data[[1L]]$linewidth), 0.4),
            paste(path, "observed year-mode width is not 0.4"))
      check(identical(unique(built$data[[2L]]$linewidth), 0.6),
            paste(path, "fitted year-mode width is not 0.6"))
    }
    cat("PASS year-mode widths on both scales:", path, "\n")
  }
  for (path in style_files) {
    codes <- Filter(function(code) grepl("Spawning biomass with 95% intervals", code, fixed = TRUE),
                    r_blocks(path))
    check(length(codes) == 1L, paste(path, "must include the global-axis example"))
    e <- fresh_context()
    plots <- evaluate(codes[[1L]], e)
    check(length(plots) == 1L, paste(path, "global-axis example must create one plot"))
    p <- plots[[1L]]
    check(identical(p$labels$title, "Spawning biomass with 95% intervals"), "Global title ignored")
    check(identical(p$labels$x, "Survey year") && identical(p$labels$y, "Spawning biomass"),
          "Global axis labels ignored")
    built <- ggplot2::ggplot_build(p)$layout$panel_params[[1L]]
    check(identical(built$x$breaks, c(2000, 2009, 2019)), "Global breaks ignored")
    check(isTRUE(all.equal(built$x.range, range(e$b$year))), "Global expansion ignored")
    cat("PASS global labels and axes:", path, "\n")
  }
  cat("PASS: three prerequisite/styling examples, six year-mode figures, three global-axis examples, six grid-free reference examples.\n")
}
main()
