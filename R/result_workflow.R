# Attach plain inputs rather than retaining a caller environment or TMB pointer.
.acl_attach_recipe <- function(result, model, args) {
  result$recipe <- list(schema_version = 1L, model = tolower(model), args = args,
    versions = list(ALSCL = as.character(utils::packageVersion("ALSCL")),
                    TMB = as.character(utils::packageVersion("TMB")),
                    R = as.character(getRversion())),
    implementation = .acl_implementation(model),
    settings = list(ALSCL.framework = .acl_framework(),
                    ALSCL.sd_cores = getOption("ALSCL.sd_cores", "auto")))
  class(result) <- c("alscl_fit", "list")
  result
}

# Read an optional source-checkout revision without invoking git or storing paths.
.acl_checkout_revision <- function(root) {
  if (!is.character(root) || length(root) != 1L || is.na(root) || !nzchar(root) || !dir.exists(root))
    return(NA_character_)
  read_text <- function(path) {
    if (!file.exists(path) || dir.exists(path)) return(character())
    readLines(path, warn = FALSE)
  }
  valid_sha <- function(x) length(x) == 1L && !is.na(x) &&
    grepl("^([a-fA-F0-9]{40}|[a-fA-F0-9]{64})$", x)
  tryCatch({
    git_dir <- file.path(root, ".git")
    if (!dir.exists(git_dir)) {
      pointer <- read_text(git_dir)
      if (length(pointer) != 1L || !startsWith(pointer, "gitdir: ")) return(NA_character_)
      path <- substring(pointer, 9L)
      git_dir <- if (grepl("^(/|[A-Za-z]:[/\\\\])", path)) path else file.path(root, path)
    }
    head <- read_text(file.path(git_dir, "HEAD"))
    if (valid_sha(head)) return(tolower(head))
    if (length(head) != 1L || !startsWith(head, "ref: ")) return(NA_character_)
    ref <- substring(head, 6L)
    common <- read_text(file.path(git_dir, "commondir"))
    common_dir <- if (length(common) == 1L) {
      if (grepl("^(/|[A-Za-z]:[/\\\\])", common)) common else file.path(git_dir, common)
    } else git_dir
    for (directory in unique(c(git_dir, common_dir))) {
      sha <- read_text(file.path(directory, ref))
      if (valid_sha(sha)) return(tolower(sha))
      packed <- strsplit(read_text(file.path(directory, "packed-refs")), " ", fixed = TRUE)
      for (entry in packed) if (length(entry) == 2L && identical(entry[2L], ref) && valid_sha(entry[1L]))
        return(tolower(entry[1L]))
    }
    NA_character_
  }, error = function(e) NA_character_)
}

.acl_source_identity <- function(description, root) {
  field <- function(name) {
    value <- description[[name]]
    if (is.character(value) && length(value) == 1L && !is.na(value) && nzchar(value)) value else NA_character_
  }
  revision <- .acl_checkout_revision(root)
  revision_source <- if (!is.na(revision)) "checkout HEAD" else NA_character_
  if (is.na(revision)) {
    candidate <- field("RemoteSha")
    if (!is.na(candidate) && grepl("^([a-fA-F0-9]{40}|[a-fA-F0-9]{64})$", candidate)) {
      revision <- tolower(candidate)
      revision_source <- "DESCRIPTION RemoteSha"
    }
  }
  list(revision = revision, revision_source = revision_source,
    repository = field("Repository"), remote_type = field("RemoteType"), built = field("Built"))
}

.acl_implementation <- function(model) {
  description_file <- system.file("DESCRIPTION", package = "ALSCL")
  description <- tryCatch(as.list(read.dcf(description_file)[1L, ]), error = function(e) list())
  files <- c(paste0(toupper(model), ".cpp"), "model_math.hpp")
  paths <- vapply(files, function(file) system.file("extdata", file, package = "ALSCL"), character(1))
  hashes <- stats::setNames(rep(NA_character_, length(files)), files)
  present <- nzchar(paths) & file.exists(paths)
  hashes[present] <- unname(tools::md5sum(paths[present]))
  root <- if (nzchar(description_file)) dirname(description_file) else NA_character_
  r_files <- if (!is.na(root)) sort(list.files(file.path(root, "R"), pattern = "[.][Rr]$", full.names = TRUE)) else character()
  r_hashes <- stats::setNames(unname(tools::md5sum(r_files)), basename(r_files))
  blas <- unname(extSoftVersion()["BLAS"])
  list(source = .acl_source_identity(description, root),
    model_sources = hashes, r_sources = r_hashes,
    runtime = list(platform = R.version$platform, arch = R.version$arch, os = R.version$os,
      BLAS = if (length(blas) == 1L && !is.na(blas)) basename(blas) else NA_character_,
      LAPACK = La_version(), Matrix = as.character(utils::packageVersion("Matrix")),
      RcppEigen = as.character(utils::packageVersion("RcppEigen"))))
}

.acl_check_implementation <- function(recipe) {
  saved <- recipe$implementation
  if (!is.list(saved)) return(invisible(NULL))
  current <- .acl_implementation(recipe$model)
  changed <- character()
  different <- function(old, new) is.character(old) && length(old) == 1L &&
    !is.na(old) && nzchar(old) && is.character(new) && length(new) == 1L &&
    !is.na(new) && nzchar(new) && !identical(old, new)
  for (file in intersect(names(saved$model_sources), names(current$model_sources)))
    if (different(unname(saved$model_sources[file]), unname(current$model_sources[file])))
      changed <- c(changed, paste0("model source ", file))
  if (length(saved$r_sources) && length(current$r_sources) &&
      !identical(saved$r_sources[order(names(saved$r_sources))], current$r_sources[order(names(current$r_sources))]))
    changed <- c(changed, "R source files")
  if (different(saved$source$revision, current$source$revision)) changed <- c(changed, "source revision")
  for (package in c("ALSCL", "TMB"))
    if (different(recipe$versions[[package]], as.character(utils::packageVersion(package))))
      changed <- c(changed, paste(package, "version"))
  for (package in c("Matrix", "RcppEigen"))
    if (different(saved$runtime[[package]], current$runtime[[package]]))
      changed <- c(changed, paste(package, "version"))
  if (length(changed)) warning("The current implementation differs from the saved assessment (",
    paste(changed, collapse = "; "), "). Results may differ.",
    call. = FALSE)
  invisible(changed)
}

.acl_recipe <- function(fit) {
  r <- fit$recipe
  if (!is.list(r) || !identical(r$schema_version, 1L) ||
      length(r$model) != 1L || !r$model %in% c("acl", "alscl") || !is.list(r$args))
    stop("A complete fit recipe is required. Refit with the current package or supply x when saving an older result.", call. = FALSE)
  r
}

.acl_conf_level <- function(x) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0 || x >= 1)
    stop("conf_level must be a finite number strictly between 0 and 1.", call. = FALSE)
  stats::qnorm((1 + x) / 2)
}

#' Extract fixed-effect parameter estimates on a specified scale
#' @param fit A fitted ACL or ALSCL result. Older lists remain supported.
#' @param scale Natural scale (default), or the internal optimizer scale.
#' @param conf_level Nominal confidence level of approximate Wald intervals,
#'   strictly between zero and one.
#' @return A data frame with parameter, scale, status, estimate, std_error,
#'   conf_low, conf_high and numerical_ok. Fixed parameters are included when a recipe exists;
#'   their standard errors and intervals are NA. Without a recipe, only free
#'   fixed effects can be identified. Random effects are not included.
#' @details Natural-scale estimates use exp for log and mean_log parameters,
#'   plogis for logit parameters, and identity for ACL t0. The natural-scale SE
#'   uses the delta method; interval endpoints transform an internal-scale Wald
#'   interval. exp(mean_log_F) and exp(mean_log_R) are baseline process levels,
#'   not arithmetic averages over time. Parameter names retain their exact
#'   internal spelling to make the transformation explicit. Unavailable or
#'   invalid covariance entries produce NA uncertainty, never zero uncertainty.
#'   numerical_ok records the existing fit screen; intervals from a fit failing
#'   this screen must not be interpreted as validated uncertainty.
#' @examples
#' \dontrun{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' extract_parameters(fit)
#' extract_parameters(fit, scale = "internal")
#' }
#' @export
extract_parameters <- function(fit, scale = c("natural", "internal"), conf_level = .95) {
  scale <- match.arg(scale); z <- .acl_conf_level(conf_level)
  par <- fit$opt$par
  if (!is.numeric(par) || !length(par) || is.null(names(par)) ||
      anyDuplicated(names(par)) || any(!is.finite(par)))
    stop("fit must contain finite, uniquely named fixed-effect estimates in opt$par.", call. = FALSE)
  values <- par; status <- rep("estimated", length(par)); names(status) <- names(par)
  if (!is.null(fit$recipe)) {
    recipe <- .acl_recipe(fit)
    # Optimizer controls do not affect the parameter map. Older archives can
    # contain controls accepted by an earlier fitting implementation.
    inspection_args <- recipe$args
    inspection_args$control <- list()
    inspection <- inspect_parameters(inspection_args, model = recipe$model)
    # Inspection is also authoritative for data-adjusted fixed starting values.
    scalars <- inspection[inspection$kind == "fixed_effect", , drop = FALSE]
    if (nrow(scalars)) {
      fixed <- scalars[!scalars$parameter %in% names(par), , drop = FALSE]
      if (nrow(fixed)) {
        fixed_values <- vapply(fixed$start, function(v) as.numeric(v)[1L], numeric(1))
        names(fixed_values) <- fixed$parameter
        values <- c(values, fixed_values)
        status <- c(status, stats::setNames(ifelse(fixed$status == "inactive", "inactive", "fixed"), fixed$parameter))
      }
    }
  }
  se <- rep(NA_real_, length(values)); names(se) <- names(values)
  cov <- fit$vcov
  if (is.matrix(cov) && is.numeric(cov) && identical(dim(cov), c(length(par), length(par)))) {
    if (is.null(rownames(cov))) dimnames(cov) <- list(names(par), names(par))
    if (identical(rownames(cov), colnames(cov)) && all(names(par) %in% rownames(cov))) {
      d <- diag(cov[names(par), names(par), drop = FALSE])
      good <- is.finite(d) & d >= 0
      se[names(par)[good]] <- sqrt(d[good])
    }
  }
  lo <- values - z * se; hi <- values + z * se
  if (scale == "natural") {
    transform <- function(x) vapply(seq_along(values), function(i)
      .acl_parameter_transform(names(values)[i], x[i]), numeric(1))
    se <- se * vapply(seq_along(values), function(i)
      abs(.acl_parameter_transform(names(values)[i], values[i], derivative = TRUE)), numeric(1))
    lo <- transform(lo); hi <- transform(hi); values <- stats::setNames(transform(values), names(values))
  }
  data.frame(parameter = names(values), scale = scale, status = unname(status),
    estimate = unname(values), std_error = unname(se), conf_low = unname(lo),
    conf_high = unname(hi), numerical_ok = isTRUE(fit$diagnostics$numerical_ok), row.names = NULL)
}

#' Extract population estimates with explicit time and group coordinates
#' @param fit A fitted ACL or ALSCL result, including a portable saved result.
#' @param quantities Character vector of reported population quantities. F resolves
#'   to age-specific F for ACL and length-specific FL for ALSCL. Supported outputs
#'   include SSB, Rec, B, N, CN, CB, NA, NL, BA, BL, SBA, SBL, CNA, CNL, CBA,
#'   CBL, F, FL, FA and the joint NLA/BLA/SBLA/CNLA/CBLA arrays when reported.
#' @param conf_level Nominal confidence level of approximate normal intervals
#'   on the reported scale, strictly between zero and one.
#' @return A long data frame with quantity, report_name, year, age, length,
#'   length_label, estimate, std_error, conf_low, conf_high and numerical_ok.
#'   Unavailable SEs remain NA. No averaging of F or annualization is performed.
#' @details Estimates come from report. Complete finite nonnegative standard errors
#'   come from exact matching rows of est_std. Incomplete uncertainty for a quantity
#'   remains NA. Normal intervals are not truncated at zero. FA uses source ages
#'   and source periods of the cohort-survival interval, not destination labels.
#' @examples
#' \dontrun{
#' fit <- run_alscl(YTF_example, silent = TRUE)
#' estimates <- extract_estimates(fit, c("SSB", "Rec", "F"))
#' write.csv(estimates, tempfile(fileext = ".csv"), row.names = FALSE)
#' }
#' @export
extract_estimates <- function(fit, quantities = c("SSB", "Rec", "B", "N", "CN", "F"), conf_level = .95) {
  z <- .acl_conf_level(conf_level)
  if (!is.character(quantities) || !length(quantities) || anyNA(quantities) || anyDuplicated(quantities))
    stop("quantities must be distinct, nonmissing quantity names.", call. = FALSE)
  years <- .acl_plot_year(fit)
  time_only <- c("SSB", "Rec", "B", "N", "CN", "CB")
  age_time <- c("NA", "BA", "SBA", "CNA", "CBA", "F", "FA")
  length_time <- c("NL", "BL", "SBL", "CNL", "CBL", "FL")
  joint <- c("NLA", "BLA", "SBLA", "CNLA", "CBLA")
  numerical_ok <- isTRUE(fit$diagnostics$numerical_ok)
  rows <- lapply(quantities, function(quantity) {
    nm <- if (quantity == "F" && is.null(fit$report[["F"]])) "FL" else quantity
    if (!nm %in% c(time_only, age_time, length_time, joint))
      stop("Unsupported population quantity: ", quantity, call. = FALSE)
    value <- fit$report[[nm]]
    if (!is.numeric(value) || !length(value) || any(!is.finite(value)))
      stop("Quantity '", quantity, "' is unavailable or contains nonfinite estimates.", call. = FALSE)
    period <- if (nm == "FA") head(years, -1L) else years
    age <- if (nm == "FA") head(fit$age, -1L) else fit$age
    if (nm %in% time_only) {
      if (length(value) != length(period)) stop("Time dimensions do not match for ", nm, call. = FALSE)
      coords <- data.frame(year = period, age = NA_real_, length = NA_real_, length_label = NA_character_)
    } else if (nm %in% age_time) {
      if (!is.numeric(age) || any(!is.finite(age)) || !identical(dim(value), c(length(age), length(period))))
        stop("Age/time dimensions do not match for ", nm, call. = FALSE)
      coords <- data.frame(year = rep(period, each = length(age)), age = rep(age, length(period)),
        length = NA_real_, length_label = NA_character_)
    } else {
      mid <- fit$len_mid; labels <- fit$len_label
      if (!is.numeric(mid) || any(!is.finite(mid)) || length(labels) != length(mid) || anyNA(labels))
        stop("Complete length coordinates are required for ", nm, call. = FALSE)
      if (nm %in% length_time) {
        if (!identical(dim(value), c(length(mid), length(period)))) stop("Length/time dimensions do not match for ", nm, call. = FALSE)
        coords <- data.frame(year = rep(period, each = length(mid)), age = NA_real_,
          length = rep(mid, length(period)), length_label = rep(as.character(labels), length(period)))
      } else {
        if (!is.numeric(age) || any(!is.finite(age)) || !identical(dim(value), c(length(mid), length(age), length(period))))
          stop("Length/age/time dimensions do not match for ", nm, call. = FALSE)
        coords <- data.frame(year = rep(period, each = length(mid) * length(age)),
          age = rep(rep(age, each = length(mid)), length(period)),
          length = rep(mid, length(age) * length(period)),
          length_label = rep(as.character(labels), length(age) * length(period)))
      }
    }
    se <- rep(NA_real_, length(value)); tab <- fit$est_std
    if (length(dim(tab)) == 2L && !is.null(rownames(tab)) && "Std. Error" %in% colnames(tab)) {
      selected <- tab[which(rownames(tab) == nm), "Std. Error"]
      if (is.numeric(selected) && length(selected) == length(value) && all(is.finite(selected)) && all(selected >= 0)) se <- as.numeric(selected)
    }
    data.frame(quantity = quantity, report_name = nm, coords, estimate = as.numeric(value),
      std_error = se, conf_low = as.numeric(value) - z * se,
      conf_high = as.numeric(value) + z * se, numerical_ok = numerical_ok, row.names = NULL)
  })
  do.call(rbind, rows)
}

#' Summarize an assessment fit
#' @param object A fitted alscl_fit object.
#' @param ... Reserved for future methods.
#' @return summary returns a summary.alscl_fit list with numerical diagnostics and
#'   a natural-scale parameter table. print returns its input invisibly.
#' @export
summary.alscl_fit <- function(object, ...) {
  structure(list(model = object$model_type, periods = range(object$year),
    F_structure = object$F_structure, elapsed = object$elapsed,
    diagnostics = .acl_fit_status(object), parameters = extract_parameters(object)),
    class = "summary.alscl_fit")
}

#' @rdname summary.alscl_fit
#' @param x A fitted object or its summary.
#' @export
print.summary.alscl_fit <- function(x, ...) {
  cat(x$model, "assessment; periods", paste(x$periods, collapse = " to "),
      "; F structure:", x$F_structure, "\n")
  print(x$diagnostics, row.names = FALSE)
  cat("\nFixed-effect parameters (natural scale):\n")
  print(x$parameters, row.names = FALSE)
  invisible(x)
}

#' @rdname summary.alscl_fit
#' @export
print.alscl_fit <- function(x, ...) {
  print(summary(x), ...)
  invisible(x)
}

#' Extract optimizer coefficients and covariance
#' @param object A fitted alscl_fit object.
#' @param ... Reserved for future methods.
#' @return coef returns free fixed effects on the optimizer scale. vcov returns
#'   their covariance matrix, or NULL when unavailable. Fixed and random effects
#'   are excluded; use extract_parameters for natural-scale estimates.
#' @export
coef.alscl_fit <- function(object, ...) object$opt$par

#' @rdname coef.alscl_fit
#' @export
vcov.alscl_fit <- function(object, ...) object$vcov

#' Save a portable assessment and its complete refit recipe
#' @param fit A fitted result.
#' @param file Destination RDS file. Its parent directory must exist.
#' @param x Optional complete input bundle for an older fit without a recipe.
#' @param overwrite Allow replacement of an existing archive; default FALSE.
#' @return The normalized archive path, invisibly. The original fit is unchanged.
#' @details The archive excludes the session-specific TMB object, and stores a
#'   schema version, fitted estimates, input tables, map, bounds, settings and
#'   software versions. New fits also record available source revisions, MD5
#'   hashes of the model template and shared header, and platform, BLAS, LAPACK
#'   and dependency information in recipe$implementation. These identify the
#'   recorded source files; a checkout revision alone does not establish that
#'   the working tree was clean. R source-file hashes are also recorded when
#'   available in a source tree; ordinary installed packages need not retain
#'   those files. Missing source metadata remains unavailable, and no
#'   source revision is inferred for an older fit supplied with x.
#'   Concurrent saves to the same path use a temporary lock directory during
#'   the final rename. With overwrite = FALSE, only the first save can publish
#'   the archive. If an interrupted process leaves a lock, confirm that the
#'   writer has stopped before removing the lock directory named in the error.
#'   A fresh session can summarize and plot it without a live
#'   TMB pointer. refit_model rebuilds a live model; cross-version numerical
#'   equality is not promised. Only read archives from trusted sources.
#' @examples
#' \dontrun{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' path <- tempfile(fileext = ".rds")
#' save_assessment(fit, path)
#' saved <- read_assessment(path)
#' summary(saved)
#' }
#' @export
save_assessment <- function(fit, file, x = NULL, overwrite = FALSE) {
  if (!is.character(file) || length(file) != 1L || is.na(file) || !nzchar(file) || !dir.exists(dirname(file)))
    stop("file must be a path with an existing parent directory.", call. = FALSE)
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) stop("overwrite must be TRUE or FALSE.", call. = FALSE)
  if (dir.exists(file) || (file.exists(file) && !overwrite)) stop("Archive already exists; use overwrite = TRUE for a file.", call. = FALSE)
  if (!is.null(x)) {
    if (!is.null(fit$recipe)) stop("x is only accepted for older fits without a recipe.", call. = FALSE)
    model <- tolower(fit$model_type)
    if (!model %in% c("acl", "alscl")) stop("An explicit ACL or ALSCL model_type is required.", call. = FALSE)
    args <- .acl_resolved_args(x, model)
    unknown <- .acl_validate_survey_fit(fit, .acl_survey_data(args$data.CatL))
    fit <- .acl_attach_recipe(fit, model, args)
    # Current source metadata cannot establish which implementation fitted legacy results.
    fit$recipe$implementation <- NULL
    fit$recipe$provenance <- paste("User-supplied recipe for legacy fit; original biology, weights, maturity, maps, bounds, starts, software and computational settings unverified.",
      if (length(unknown)) paste("Observation checks incomplete:", paste(unknown, collapse = "; ")) else "Stored observations match supplied observations.")
  }
  .acl_recipe(fit)
  portable <- fit; portable$obj <- NULL
  class(portable) <- c("alscl_fit", "list")
  temporary <- tempfile(".alscl-archive-", tmpdir = dirname(file))
  on.exit(unlink(temporary, expand = FALSE), add = TRUE)
  saveRDS(list(format = "ALSCL assessment", schema_version = 1L, fit = portable), temporary, version = 2)
  # Two writers may both have observed an absent archive before serialization.
  # Acquire an exclusive directory only for the existence check and rename.
  lock <- file.path(dirname(file), paste0(".", basename(file), ".alscl-lock"))
  if (!dir.create(lock, showWarnings = FALSE))
    stop("Could not acquire the archive lock: ", lock, call. = FALSE)
  on.exit(unlink(lock, recursive = TRUE, expand = FALSE), add = TRUE)
  if (!overwrite && file.exists(file))
    stop("Archive already exists; use overwrite = TRUE for a file.", call. = FALSE)
  if (!file.rename(temporary, file))
    stop("Could not install the assessment archive.", call. = FALSE)
  invisible(normalizePath(file, winslash = "/"))
}

#' Read a portable assessment archive
#' @param file RDS file created by save_assessment.
#' @return An alscl_fit object with a recipe and no live TMB obj.
#' @export
read_assessment <- function(file) {
  archive <- readRDS(file)
  if (!is.list(archive) || !identical(archive$format, "ALSCL assessment") ||
      !identical(archive$schema_version, 1L) || !is.list(archive$fit))
    stop("Unsupported assessment archive or schema version.", call. = FALSE)
  fit <- archive$fit
  .acl_recipe(fit)
  fit$obj <- NULL; class(fit) <- c("alscl_fit", "list")
  fit
}

#' Refit a stored assessment with optional argument overrides
#' @param fit An assessment containing a complete recipe, including read_assessment output.
#' @param ... Named run_acl or run_alscl argument overrides. Lists replace the
#'   corresponding whole list, and explicit NULL is preserved. Output file writing
#'   is disabled unless output = TRUE is explicitly requested.
#' @return A fresh fitted result with a live TMB object and an updated recipe.
#' @details Recorded framework and standard-error settings are applied during the
#'   fit and restored afterward. Uses the recorded original starts, not a claim of
#'   portable executable pointers. Refitting with different software may differ.
#'   When recorded metadata is available, a change in model- or R-source hashes,
#'   source revision, or ALSCL, TMB, Matrix or RcppEigen version produces a
#'   warning before fitting. Missing metadata in older archives remains
#'   supported. Platform and build information is retained for inspection;
#'   it does not establish cross-platform numerical equality.
#' @export
refit_model <- function(fit, ...) {
  recipe <- .acl_recipe(fit)
  .acl_check_implementation(recipe)
  overrides <- list(...)
  if (!"output" %in% names(overrides)) overrides$output <- FALSE
  args <- .acl_bundle_args(recipe$args, recipe$model, overrides)
  previous <- options(recipe$settings); on.exit(options(previous), add = TRUE)
  do.call(if (recipe$model == "acl") run_acl else run_alscl, args)
}
