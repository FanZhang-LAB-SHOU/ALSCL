# Render the maintained bilingual examples for single estimates and missing bins.
# Rscript scripts/plot_sparse_panels.R [path/to/teaching-fits.rds]
render_sparse_panels <- function(fits_file = NULL) {
  pkgload::load_all(quiet = TRUE)
  source("scripts/plot_helpers.R", local = environment())
  # Draw in the default package style, whatever theme the session has set.
  old <- options(acl.theme = NULL)
  on.exit(options(old), add = TRUE)
  b <- if (is.null(fits_file)) run_alscl(YTF_example, silent = TRUE) else readRDS(fits_file)$alscl
  out <- "docs/figures/sparse-panels"
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  cases <- list(
    list(article = "population-plots", match = "one_period <- list(",
         file = "single-period-SSB.png"),
    list(article = "growth-mortality", match = "ridge_example <- list(",
         file = "ridges-missing-edges.png", height = 4.5))
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
    # 300 dpi at the size of acl_figure_size(); the two ridge panels side by
    # side need more height than it gives.
    save_grid_free_plot(file.path(out, case$file), plots$en, height = case$height)
  }
  invisible(TRUE)
}
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  render_sparse_panels(if (length(args)) args[[1L]] else NULL)
}
