# Shared numerical screen for consumers of fitted results. A raw optimizer code
# alone is not a verdict: successful refinement can retain a nonzero raw code.
.acl_npar <- function(fit) {
  par <- fit$opt$par %||% fit$obj$par
  if (!is.numeric(par) || !length(par) || any(!is.finite(par))) return(NA_integer_)
  length(par)
}

.acl_fit_status <- function(fit, error = NULL) {
  scalar <- function(x, default = NA_real_) {
    if (length(x) == 1L && !is.na(x)) x else default
  }
  code <- scalar(fit$convergence_code %||% fit$opt$convergence, NA_integer_)
  gradient <- .acl_max_gradient(fit)
  hessian <- scalar(fit$pdHess, NA)
  boundary <- scalar(fit$bound_hit, NA)
  diagnostics <- fit$diagnostics
  if (is.null(diagnostics) && !is.null(fit)) {
    normalized <- fit
    normalized$convergence_code <- code
    normalized$max_abs_gradient <- gradient
    diagnostics <- tryCatch(.acl_fit_diagnostics(normalized), error = function(e) NULL)
  }
  natural <- scalar(diagnostics$natural_boundary, NA)
  objective <- scalar(fit$opt$objective)
  ok <- is.null(error) && isTRUE(diagnostics$numerical_ok) &&
    !is.na(.acl_npar(fit)) &&
    is.finite(objective) && is.finite(gradient) && gradient < 1e-3 &&
    isTRUE(hessian) && identical(boundary, FALSE) && identical(natural, FALSE)
  issues <- diagnostics$issues
  if (is.na(.acl_npar(fit))) issues <- c(issues, "free parameter count unavailable")
  if (!is.finite(objective)) issues <- c(issues, "nonfinite or unavailable objective")
  if (!is.finite(gradient) || gradient >= 1e-3)
    issues <- c(issues, "large or nonfinite gradient")
  if (!isTRUE(hessian)) issues <- c(issues, "Hessian unavailable or not positive definite")
  if (is.na(boundary)) issues <- c(issues, "optimizer boundary status unavailable")
  else if (boundary) issues <- c(issues, "optimizer-scale boundary")
  if (is.na(natural)) issues <- c(issues, "natural boundary status unavailable")
  else if (natural) issues <- c(issues, "natural-scale boundary")
  if (is.null(diagnostics)) issues <- c(issues, "numerical diagnostics unavailable")
  if (!is.null(error)) issues <- c(issues, paste0("fit error: ", error))
  data.frame(convergence_code = code, max_abs_gradient = gradient,
    pdHess = hessian, bound_hit = boundary, natural_boundary = natural,
    numerical_ok = ok, issues = paste(unique(issues), collapse = "; "),
    stringsAsFactors = FALSE)
}

# Refuse known data mismatches; with old objects lacking metadata, retain raw
# statistics but withhold an automatic preference because comparability is unknown.
.acl_comparison_data <- function(models, data.CatL) {
  if (length(dim(data.CatL)) != 2L || ncol(data.CatL) < 2L)
    stop("data.CatL must contain length labels and time columns.", call. = FALSE)
  original <- as.matrix(data.CatL[, -1L, drop = FALSE])
  observed <- suppressWarnings(matrix(as.numeric(original), nrow(original), ncol(original)))
  if (any(is.na(observed) & !is.na(original)) ||
      any(is.infinite(observed)) || any(observed < 0, na.rm = TRUE))
    stop("Comparison observations must be numeric, nonnegative and finite, or NA.", call. = FALSE)
  mask <- is.finite(observed) & observed > 0
  if (!any(mask)) stop("No positive finite observations are available.", call. = FALSE)
  years <- suppressWarnings(as.numeric(sub("^X", "", colnames(data.CatL)[-1L])))
  labels <- trimws(as.character(data.CatL[, 1L]))
  unknown <- character()
  for (i in seq_along(models)) {
    m <- models[[i]]
    fail <- function(part) stop("Model ", i, " does not match data.CatL: ", part, ".",
                                call. = FALSE)
    if (!identical(dim(m$report$Elog_index), dim(observed))) fail("prediction dimensions")
    if (any(!is.finite(m$report$Elog_index[mask]))) fail("nonfinite predictions")
    if (is.null(m$year)) unknown <- c(unknown, paste("model", i, "time metadata unavailable"))
    else if (length(m$year) != length(years) || any(!is.finite(m$year)) || any(!is.finite(years)) ||
             any(abs(m$year - years) > 1e-8)) fail("time columns")
    if (is.null(m$len_label)) unknown <- c(unknown, paste("model", i, "length labels unavailable"))
    else if (!identical(trimws(as.character(m$len_label)), labels)) fail("length labels/order")
    if (is.null(m$observations)) {
      unknown <- c(unknown, paste("model", i, "original observations unavailable"))
    } else {
      stored <- m$observations
      if (!identical(dim(stored), dim(observed))) fail("observation dimensions")
      stored_mask <- is.finite(stored) & stored > 0
      if (!identical(unname(stored_mask), unname(mask))) fail("observation mask")
      if (!isTRUE(all.equal(as.numeric(stored[mask]), as.numeric(observed[mask]),
                            tolerance = 1e-12))) fail("observation values")
    }
  }
  list(verified = !length(unknown), issues = unknown)
}
