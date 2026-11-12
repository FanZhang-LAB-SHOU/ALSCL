# Render the maintained bilingual examples for single estimates and missing bins.
# Rscript scripts/plot_sparse_panels.R [path/to/teaching-fits.rds]
render_sparse_panels <- function(fits_file = NULL) {
  pkgload::load_all(quiet = TRUE)
  source("scripts/plot_helpers.R", local = environment())
  old <- options(acl.theme = NULL)
  on.exit(options(old), add = TRUE)
  acl_theme_set(palette = "npg", base_theme = "theme_bw")
  b <- if (is.null(fits_file)) run_alscl(YTF_example, silent = TRUE) else readRDS(fits_file)$alscl
  out <- "docs/figures/sparse-panels"
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  cases <- list(
    list(article = "population-plots", match = "one_period <- list(",
         file = "single-period-SSB.png", width = 6, height = 4),
    list(article = "growth-mortality", match = "ridge_example <- list(",
         file = "ridges-missing-edges.png", width = 9, height = 5))
  for (case in cases) {
    plots <- list()
    for (language in c("en", "zh")) {
      path <- paste0("website/content/", language, "/articles/", case$article, ".md")
      text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
      blocks <- regmatches(text, gregexpr("(?s)```r\\n.*?\\n```", text, perl = TRUE))[[1L]]
      block <- blocks[grepl(case$match, blocks, fixed = TRUE)]
      stopifnot(length(block) == 1L)
      code <- sub("^```r\\n", "", sub("\\n```$", "", block))
      env <- new.env(parent = environment())
      plot <- eval(parse(text = code), env)
      assert_grid_free_plot(plot)
      # Force actual rendering in each language, not just code parsing.
      ggplot2::ggplotGrob(plot)
      plots[[language]] <- plot
      cat("PASS sparse-panel example:", path, "\n")
    }
    save_grid_free_plot(file.path(out, case$file), plots$en,
      width = case$width, height = case$height, dpi = 150, bg = "white")
  }
  invisible(TRUE)
}
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  render_sparse_panels(if (length(args)) args[[1L]] else NULL)
}
