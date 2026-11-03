# Execute the setup and example exactly as rendered for each reference language.
# Actual YTF fits are supplied by the plot-example test, avoiding duplicate fits.
check_growth_reference_examples <- function(a, b, assert_grid_free_plot) {
  stopifnot(inherits(a, "alscl_fit"), inherits(b, "alscl_fit"),
            is.list(a$report), is.list(b$report))
  python <- Sys.which("python3")
  if (!nzchar(python)) python <- Sys.which("python")
  if (!nzchar(python)) stop("Python is required to extract website examples.")
  output <- system2(python, c("scripts/extract_reference_examples.py", "plot_compare_growth"),
                    stdout = TRUE, stderr = TRUE)
  if (!is.null(attr(output, "status"))) stop(paste(output, collapse = "\n"))
  entries <- jsonlite::fromJSON(paste(output, collapse = "\n"), simplifyVector = FALSE)
  stopifnot(length(entries) == 2L)
  library(ALSCL)
  old_theme <- acl_theme()
  on.exit(do.call(acl_theme_set, old_theme), add = TRUE)
  acl_theme_reset()
  for (entry in entries) {
    # Skip the caller/global environment: hidden gallery helpers and leftover
    # reference data must not make an incomplete example appear self-contained.
    e <- new.env(parent = as.environment("package:ALSCL"))
    calls <- c(acl = 0L, alscl = 0L)
    e$run_acl <- function(x, silent) {
      stopifnot(identical(x, ALSCL::YTF_example), identical(silent, TRUE))
      calls[["acl"]] <<- calls[["acl"]] + 1L
      a
    }
    e$run_alscl <- function(x, silent) {
      stopifnot(identical(x, ALSCL::YTF_example), identical(silent, TRUE))
      calls[["alscl"]] <<- calls[["alscl"]] + 1L
      b
    }
    eval(parse(text = entry$setup), envir = e)
    stopifnot(identical(unname(calls), c(1L, 1L)),
              !exists("ref", e, inherits = FALSE),
              !exists("growth_display", e, inherits = TRUE))
    value <- eval(parse(text = entry$example), envir = e)
    stopifnot(inherits(value, "ggplot"), nrow(e$ref) == 75L,
              all(is.finite(e$ref$Length)), all(e$ref$Age %in% 1:15))
    assert_grid_free_plot(value)
    # Render to exercise scales, the fitted reference curve and the composition.
    print(value)
    cat("PASS isolated reference setup and example:", entry$name, entry$language, "\n")
  }
  invisible(TRUE)
}
