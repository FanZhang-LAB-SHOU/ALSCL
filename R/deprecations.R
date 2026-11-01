# Renamed arguments, functions and theme keys are accepted for one release
# cycle. Each deprecated name warns once per session so that loops stay quiet.
.acl_deprecation_env <- new.env(parent = emptyenv())

# Former argument names of each function and the names that replace them.
# website/check.py reads this table to flag former names in the documentation.
.acl_renamed_arguments <- list(
  plot_CatL = c(type = "facet_by"),
  plot_residuals = c(type = "facet_by"),
  plot_compare_ts = c(linewidth = "line_size", ncol = "facet_ncol", scales = "facet_scales"),
  plot_compare_CatL = c(linewidth = "line_size", ncol = "facet_ncol", scales = "facet_scales"),
  plot_compare_metrics = c(ncol = "facet_ncol"),
  plot_compare_residuals = c(linewidth = "line_size"),
  plot_compare_growth = c(linewidth = "line_size"),
  plot_compare_selectivity = c(linewidth = "line_size"),
  plot_compare_F_ts = c(linewidth = "line_size"),
  plot_retro = c(facet_col = "facet_ncol", facet_row = "facet_nrow"),
  retro_model = c(facet_col = "facet_ncol", facet_row = "facet_nrow"),
  retro_acl = c(facet_col = "facet_ncol", facet_row = "facet_nrow"),
  retro_alscl = c(facet_col = "facet_ncol", facet_row = "facet_nrow"),
  acl_theme_set = c(compare_linewidth = "compare_line_size")
)

# Former function names and their replacements.
.acl_deprecated_functions <- c(plot_compare_annual_F = "plot_compare_F_ts")

# Former title keys of acl_theme_set(titles = ...) and their replacements.
.acl_title_aliases <- c(CatL_year = "CatL_by_length", CatL_year_dist = "CatL_by_year",
                        compare_annualF = "compare_F_ts")

.acl_deprecated_message <- function(key, message) {
  if (!is.null(.acl_deprecation_env[[key]])) return(invisible(FALSE))
  assign(key, TRUE, envir = .acl_deprecation_env)
  warning(message, call. = FALSE)
  invisible(TRUE)
}

# Map the former names passed through ... onto their replacements. Unknown
# names are errors, as they would be without the dots.
.acl_renamed <- function(dots, fun) {
  if (!length(dots)) return(list())
  renames <- .acl_renamed_arguments[[fun]]
  given <- names(dots)
  if (is.null(given)) given <- rep("", length(dots))
  unknown <- given[!given %in% names(renames)]
  if (length(unknown))
    stop(fun, "(): unused argument", if (length(unknown) > 1L) "s", " ",
         paste(ifelse(nzchar(unknown), unknown, "<unnamed>"), collapse = ", "), call. = FALSE)
  for (old in given)
    .acl_deprecated_message(paste(fun, old, sep = "."), sprintf(
      "%s(): argument '%s' is deprecated and will be removed; use '%s' instead.",
      fun, old, renames[[old]]))
  stats::setNames(dots, unname(renames[given]))
}

.acl_renamed_titles <- function(titles) {
  old <- intersect(names(titles), names(.acl_title_aliases))
  for (key in old)
    .acl_deprecated_message(paste0("title.", key), sprintf(
      "Title key '%s' is deprecated and will be removed; use '%s' instead.",
      key, .acl_title_aliases[[key]]))
  names(titles)[names(titles) %in% old] <- unname(.acl_title_aliases[names(titles)[names(titles) %in% old]])
  titles
}

.acl_deprecated_function <- function(old) {
  .acl_deprecated_message(paste0("function.", old), sprintf(
    "%s() is deprecated and will be removed; use %s() instead.", old, .acl_deprecated_functions[[old]]))
}

# Tests reset the once-per-session warnings.
.acl_reset_deprecations <- function() {
  rm(list = ls(.acl_deprecation_env, all.names = TRUE), envir = .acl_deprecation_env)
  invisible(NULL)
}
