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

# Normalize survey observations once before validating or computing diagnostics.
.acl_survey_data <- function(data.CatL) {
  if (length(dim(data.CatL)) != 2L || ncol(data.CatL) < 2L)
    stop("data.CatL must contain length labels and time columns.", call. = FALSE)
  original <- as.matrix(data.CatL[, -1L, drop = FALSE])
  observed <- suppressWarnings(matrix(as.numeric(original), nrow(original), ncol(original)))
  if (any(is.na(observed) & !is.na(original)) ||
      any(is.infinite(observed)) || any(observed < 0, na.rm = TRUE))
    stop("Survey observations must be numeric, nonnegative and finite, or NA.", call. = FALSE)
  mask <- is.finite(observed) & observed > 0
  if (!any(mask)) stop("No positive finite observations are available.", call. = FALSE)
  years <- suppressWarnings(as.numeric(sub("^X", "", colnames(data.CatL)[-1L])))
  labels <- trimws(as.character(data.CatL[, 1L]))
  list(observed = observed, mask = mask, years = years, labels = labels)
}

# Diagnostics describe the fitted observations. Reject known mismatches rather
# than treating a reordered or changed table as a worse fit. Legacy objects may
# omit metadata, so return the missing evidence separately from actual errors.
.acl_validate_survey_fit <- function(m, survey, label = "Model") {
  observed <- survey$observed; mask <- survey$mask
  fail <- function(part, detail = NULL) {
    if (!is.null(detail) && identical(label, "Model")) stop(detail, call. = FALSE)
    stop(label, " does not match data.CatL: ", part, ".", call. = FALSE)
  }
  log_predicted <- m$report$Elog_index
  if (!identical(dim(log_predicted), dim(observed)))
    fail("prediction dimensions", "Observed and predicted dimensions differ.")
  if (!is.numeric(log_predicted) || any(!is.finite(log_predicted[mask])) ||
      any(!is.finite(exp(log_predicted[mask]))))
    fail("nonfinite predictions", "Predictions are non-finite at observed cells.")
  unknown <- character()
  missing <- function(part) paste(tolower(label), part, "unavailable")
  if (is.null(m$year)) unknown <- c(unknown, missing("time metadata"))
  else if (!is.numeric(m$year) || length(m$year) != length(survey$years) ||
           any(!is.finite(m$year)) || any(!is.finite(survey$years)) ||
           any(abs(m$year - survey$years) > 1e-8)) fail("time columns")
  if (is.null(m$len_label)) unknown <- c(unknown, missing("length labels"))
  else if (!identical(trimws(as.character(m$len_label)), survey$labels))
    fail("length labels/order")
  if (is.null(m$observations)) {
    unknown <- c(unknown, missing("original observations"))
  } else {
    stored <- m$observations
    if (!identical(dim(stored), dim(observed))) fail("observation dimensions")
    if (!is.numeric(stored) || any(is.infinite(stored)) || any(stored < 0, na.rm = TRUE))
      fail("invalid stored observations")
    stored_mask <- is.finite(stored) & stored > 0
    if (!identical(unname(stored_mask), unname(mask))) fail("observation mask")
    if (!isTRUE(all.equal(as.numeric(stored[mask]), as.numeric(observed[mask]),
                         tolerance = 1e-12))) fail("observation values")
  }
  unknown
}

# With old objects lacking metadata, retain raw statistics but withhold an
# automatic preference because comparability is unknown.
.acl_comparison_data <- function(models, data.CatL) {
  survey <- .acl_survey_data(data.CatL)
  unknown <- as.character(unlist(lapply(seq_along(models), function(i)
    .acl_validate_survey_fit(models[[i]], survey, paste("Model", i))), use.names = FALSE))
  list(verified = !length(unknown), issues = unknown)
}
