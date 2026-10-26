# Validate the output actually supplied by a fit instead of assuming every
# model reports every population quantity and its standard error.
.acl_plot_population_data <- function(model_result, type, choices, se) {
  if (!is.logical(se) || length(se) != 1L || is.na(se))
    stop("se must be TRUE or FALSE.", call. = FALSE)
  value <- model_result$report[[type]]
  if (is.null(value)) {
    available <- choices[vapply(choices, function(nm)
      !is.null(model_result$report[[nm]]), logical(1))]
    stop("Quantity '", type, "' is not available in this model output.",
         if (length(available)) paste0(" Available types: ",
           paste(available, collapse = ", "), ".") else " No supported quantity is available.",
         call. = FALSE)
  }
  years <- model_result$year
  if (!is.numeric(years) || !length(years) || any(!is.finite(years)) ||
      any(diff(years) <= 0))
    stop("model_result$year must contain finite increasing time labels.", call. = FALSE)
  if (is.data.frame(value)) value <- as.matrix(value)
  if (!is.numeric(value) || !length(value) || any(!is.finite(value)))
    stop("Quantity '", type, "' must contain finite numeric estimates.", call. = FALSE)
  if (type %in% c("B", "SSB", "CN")) {
    if (length(value) != length(years))
      stop("Quantity '", type, "' must have one estimate per time step.", call. = FALSE)
    value <- as.numeric(value)
  } else {
    if (!is.matrix(value) || ncol(value) != length(years))
      stop("Quantity '", type, "' must be a group-by-time matrix matching model_result$year.",
           call. = FALSE)
    if (type %in% c("BL", "SBL", "CNL")) {
      labels <- model_result$len_label
      if (length(labels) != nrow(value) || anyNA(labels) ||
          any(!nzchar(as.character(labels))) || anyDuplicated(labels))
        stop("model_result$len_label must identify every length group uniquely.", call. = FALSE)
    }
    # Matrix dimnames are optional display metadata, not row/column indices.
    # The model's year and length labels provide the coordinates.
    dimnames(value) <- NULL
  }
  standard_errors <- NULL
  if (se) {
    estimates <- model_result$est_std
    missing_se <- function() stop("Standard errors for '", type,
      "' are unavailable or incomplete in this model output. Use se = FALSE to draw estimates only.",
      call. = FALSE)
    if (is.null(dim(estimates)) || is.null(rownames(estimates)) ||
        !all(c("Estimate", "Std. Error") %in% colnames(estimates))) missing_se()
    standard_errors <- estimates[rownames(estimates) == type,
      c("Estimate", "Std. Error"), drop = FALSE]
    if (nrow(standard_errors) != length(value)) missing_se()
    standard_errors <- as.matrix(standard_errors)
    if (!is.numeric(standard_errors) || any(!is.finite(standard_errors)) ||
        any(standard_errors[, "Std. Error"] < 0))
      stop("Standard errors for '", type,
           "' must be finite and nonnegative. Inspect fit diagnostics or use se = FALSE.",
           call. = FALSE)
  }
  list(value = value, se = standard_errors)
}
