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

# Inspect the stored recipe to list fixed and inactive parameters. Printing a
# stored assessment must not depend on the input checks of the installed
# version: an archive written by an earlier release can hold inputs that the
# current checks reject. Return the condition in that case, never stop.
.acl_recipe_inspection <- function(recipe) {
  args <- .acl_recipe_map_compat(recipe$args, recipe$model)
  # Optimizer controls do not affect the parameter map. Older archives can
  # contain controls accepted by an earlier fitting implementation.
  args$control <- list()
  tryCatch(inspect_parameters(args, model = recipe$model), error = function(e) e)
}

# A named NULL map entry only releases a default restriction. Release 2.4.3
# accepted such an entry for a parameter that the model does not have (for
# example t0 in a map shared by ACL and ALSCL) and ignored it. Drop these
# entries from a stored recipe so that it describes the same fit as before.
.acl_recipe_map_compat <- function(args, model) {
  mapping <- args$map
  if (!is.list(mapping) || is.data.frame(mapping) || !length(mapping) ||
      is.null(names(mapping))) return(args)
  known <- c(names(create_parameters(model_type = model)$parameters),
             "dev_log_R", "dev_log_F", "dev_log_N0")
  ignored <- vapply(mapping, is.null, logical(1)) & !names(mapping) %in% known
  if (any(ignored)) args["map"] <- list(mapping[!ignored])
  args
}

# One numerical-screen verdict for every consumer of a fitted result. A fit
# without stored diagnostics is screened from its stored fields, exactly as in
# summary(), compare_models() and the batch status tables.
# ALSCL F at age and total mortality at age for every age and period. The
# template reports them, with standard errors, for the ages before the plus
# group and the periods before the last. The other cells follow from the
# reported numbers at length and age (NLA) and total mortality at length (ZL)
# by the same formula; they are computed here and not in the template, where
# the extra operations would change fitted values at rounding level. Returns
# the reported matrices with complete = FALSE when the report lacks NLA or ZL.
.acl_F_at_age <- function(fit) {
  r <- fit$report
  FA <- r$FA; ZA <- r$ZA; NLA <- r$NLA; ZL <- r$ZL
  if (!is.matrix(FA) || !is.numeric(FA)) return(NULL)
  reported <- list(FA = FA, ZA = ZA, complete = FALSE)
  if (!is.array(NLA) || length(dim(NLA)) != 3L || !is.matrix(ZL) || !is.matrix(ZA) ||
      !identical(dim(ZA), dim(FA)) || any(!is.finite(NLA)) || any(!is.finite(ZL)))
    return(reported)
  L <- dim(NLA)[1L]; A <- dim(NLA)[2L]; Y <- dim(NLA)[3L]
  if (!identical(dim(FA), c(A - 1L, Y - 1L)) || !identical(dim(ZL), c(L, Y))) return(reported)
  before <- matrix(apply(NLA, c(2L, 3L), sum), A, Y)
  after <- matrix(vapply(seq_len(Y), function(y)
    colSums(matrix(NLA[, , y], L, A) * exp(-ZL[, y])), numeric(A)), A, Y)
  all_Z <- log(pmax(before, 1e-300)) - log(pmax(after, 1e-300))
  all_F <- all_Z - mean(ZA - FA)   # ZA - FA is the natural mortality rate
  old <- cbind(rep(seq_len(A - 1L), Y - 1L), rep(seq_len(Y - 1L), each = A - 1L))
  all_Z[old] <- ZA; all_F[old] <- FA  # keep the reported values in their cells
  list(FA = all_F, ZA = all_Z, complete = TRUE)
}

.acl_numerical_ok <- function(fit) {
  isTRUE(tryCatch(.acl_fit_status(fit)$numerical_ok, error = function(e) FALSE))
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
#'   numerical_ok records the numerical screen of the fit, the same verdict
#'   that summary() reports; intervals from a fit failing
#'   this screen must not be interpreted as validated uncertainty.
#'
#'   Fixed and inactive parameters are listed by inspecting the stored recipe
#'   with [inspect_parameters()]. An archive written by an earlier release can
#'   hold inputs that the current input checks reject. In that case the table
#'   contains the estimated parameters only, a warning gives the reason, and
#'   the reason is stored in the "inspection_error" attribute.
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' extract_parameters(fit)
#' extract_parameters(fit, scale = "internal")
#' }
#' @export
extract_parameters <- function(fit, scale = c("natural", "internal"), conf_level = .95) {
  scale <- match.arg(scale); z <- .acl_conf_level(conf_level)
  out <- .acl_extract_parameters(fit, scale, z)
  problem <- attr(out, "inspection_error")
  if (!is.null(problem))
    warning("Fixed parameters are not listed: the stored inputs do not pass the current input checks (",
            problem, "). The table contains the estimated parameters only.", call. = FALSE)
  out
}

.acl_extract_parameters <- function(fit, scale, z) {
  par <- fit$opt$par
  if (!is.numeric(par) || !length(par) || is.null(names(par)) ||
      anyDuplicated(names(par)) || any(!is.finite(par)))
    stop("fit must contain finite, uniquely named fixed-effect estimates in opt$par.", call. = FALSE)
  values <- par; status <- rep("estimated", length(par)); names(status) <- names(par)
  problem <- NULL
  if (!is.null(fit$recipe)) {
    recipe <- .acl_recipe(fit)
    inspection <- .acl_recipe_inspection(recipe)
    if (inherits(inspection, "error")) {
      problem <- conditionMessage(inspection)
      inspection <- NULL
    }
    # Inspection is also authoritative for data-adjusted fixed starting values.
    fixed <- if (is.null(inspection)) NULL else
      inspection[inspection$kind == "fixed_effect" &
                 !inspection$parameter %in% names(par), , drop = FALSE]
    if (!is.null(fixed) && nrow(fixed)) {
      fixed_values <- vapply(fixed$start, function(v) as.numeric(v)[1L], numeric(1))
      names(fixed_values) <- fixed$parameter
      values <- c(values, fixed_values)
      status <- c(status, stats::setNames(ifelse(fixed$status == "inactive", "inactive", "fixed"), fixed$parameter))
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
    settings <- .acl_scale_settings(fit)
    transform <- function(x) vapply(seq_along(values), function(i)
      .acl_parameter_transform(names(values)[i], x[i], settings = settings), numeric(1))
    se <- se * vapply(seq_along(values), function(i)
      abs(.acl_parameter_transform(names(values)[i], values[i], derivative = TRUE, settings = settings)), numeric(1))
    lo <- transform(lo); hi <- transform(hi); values <- stats::setNames(transform(values), names(values))
  }
  out <- data.frame(parameter = names(values), scale = scale, status = unname(status),
    estimate = unname(values), std_error = unname(se), conf_low = unname(lo),
    conf_high = unname(hi), numerical_ok = .acl_numerical_ok(fit), row.names = NULL)
  attr(out, "inspection_error") <- problem
  out
}

#' Extract population estimates with explicit time and group coordinates
#' @param fit A fitted ACL or ALSCL result, including a portable saved result.
#' @param quantities Character vector of reported population quantities. F resolves
#'   to age-specific F for ACL and length-specific FL for ALSCL. Supported outputs
#'   include SSB, Rec, B, N, CN, CB, NA, NL, BA, BL, SBA, SBL, CNA, CNL, CBA,
#'   CBL, F, FL, FA and the joint NLA/BLA/SBLA/CNLA/CBLA arrays when reported.
#'   Numbers at age can be requested as N_at_age, an alias of NA: a table with
#'   the label "NA" loses that label when it is written to a CSV file and read
#'   back with the default settings of \code{read.csv()}, which read "NA" as a
#'   missing value (use N_at_age, or \code{na.strings = ""} when reading).
#'   In the fitted report the matrix is \code{fit$report[["NA"]]}; the
#'   double brackets are needed because NA is a reserved word in R.
#' @param conf_level Nominal confidence level of approximate normal intervals
#'   on the reported scale, strictly between zero and one.
#' @return A long data frame with quantity, report_name, year, age, length,
#'   length_label, estimate, std_error, conf_low, conf_high, numerical_ok and
#'   extrapolated. Unavailable SEs remain NA. No averaging of F or annualization
#'   is performed. numerical_ok is the numerical screen of the fit, the same
#'   verdict that summary() reports. extrapolated is TRUE for rows that depend
#'   on the fishing mortality rate (F) of the terminal period (see Details).
#' @details Estimates come from report. Complete finite nonnegative standard errors
#'   come from exact matching rows of est_std. Incomplete uncertainty for a quantity
#'   remains NA. Normal intervals are not truncated at zero. FA uses source ages
#'   and source periods of the cohort-survival interval, not destination labels.
#'
#'   No observation informs F in the terminal period. The survey index of a
#'   period measures abundance at the start of that period, and abundance at
#'   the start of a period depends on F in earlier periods only. The reported
#'   terminal-period F (F and FL) is therefore the first-order autoregressive
#'   (AR(1)) prediction from the preceding period, and its standard error
#'   reflects the F process, not data. Terminal-period catch in number (CN,
#'   CNA, CNL, CNLA) and catch in weight (CB, CBA, CBL, CBLA) are the product of
#'   an abundance that the data inform and this predicted F. These rows have
#'   extrapolated = TRUE, as do the terminal-period rows of ALSCL F at age
#'   (FA). When the last periods have no positive survey observation, F is
#'   a prediction from the last period with an observation onwards, and those
#'   periods are marked as well.
#'
#'   For ALSCL, FA covers every age, including the plus group, and every
#'   period. The fitted report (\code{fit$report$FA}) holds the ages before
#'   the plus group and the periods before the last, with standard errors; the
#'   other cells are computed from the reported numbers at length and age and
#'   total mortality at length by the same formula, and their standard errors
#'   are NA.
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' estimates <- extract_estimates(fit, c("SSB", "Rec", "F"))
#' head(estimates)
#' path <- tempfile(fileext = ".csv")
#' write.csv(estimates, path, row.names = FALSE)
#' unlink(path)
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
  numerical_ok <- .acl_numerical_ok(fit)
  # Terminal-period F enters no likelihood term; catch depends on it.
  terminal_F <- c("F", "FL", "FA", "CN", "CNA", "CNL", "CNLA", "CB", "CBA", "CBL", "CBLA")
  # F in a period is informed only by observations of later periods, so F is a
  # prediction from the last period with a positive observation onwards.
  observed <- fit$observations
  last_informed <- if (is.matrix(observed) && ncol(observed) == length(years)) {
    with_data <- which(colSums(is.finite(observed) & observed > 0) > 0)
    if (length(with_data)) years[max(with_data)] else max(years)
  } else max(years)
  rows <- lapply(quantities, function(quantity) {
    nm <- if (quantity == "F" && is.null(fit$report[["F"]])) "FL" else
      if (quantity == "N_at_age") "NA" else quantity
    if (!nm %in% c(time_only, age_time, length_time, joint))
      stop("Unsupported population quantity: ", quantity, call. = FALSE)
    value <- fit$report[[nm]]
    # F at age is completed with the plus group and the last period.
    if (nm == "FA" && isTRUE(.acl_F_at_age(fit)$complete)) value <- .acl_F_at_age(fit)$FA
    if (!is.numeric(value) || !length(value) || any(!is.finite(value)))
      stop("Quantity '", quantity, "' is unavailable or contains nonfinite estimates.", call. = FALSE)
    # F at age from earlier versions has no plus-group row and no last period.
    short_FA <- nm == "FA" && is.matrix(value) && ncol(value) == length(years) - 1L
    period <- if (short_FA) head(years, -1L) else years
    age <- if (short_FA) head(fit$age, -1L) else fit$age
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
      # Standard errors of F at age exist for the cells the template reports.
      if (nm == "FA" && is.matrix(value) && is.matrix(fit$report$FA) && length(selected) == length(fit$report$FA) &&
          length(selected) < length(value) && is.numeric(selected) && all(is.finite(selected)) && all(selected >= 0)) {
        placed <- matrix(NA_real_, nrow(value), ncol(value))
        placed[seq_len(nrow(fit$report$FA)), seq_len(ncol(fit$report$FA))] <- selected
        se <- as.numeric(placed)
      }
    }
    data.frame(quantity = quantity, report_name = if (quantity == "N_at_age") quantity else nm,
      coords, estimate = as.numeric(value),
      std_error = se, conf_low = as.numeric(value) - z * se,
      conf_high = as.numeric(value) + z * se, numerical_ok = numerical_ok,
      extrapolated = nm %in% terminal_F & coords$year >= last_informed, row.names = NULL)
  })
  do.call(rbind, rows)
}

#' Summarize an assessment fit
#' @param object A fitted alscl_fit object.
#' @param digits Number of significant digits to print; NULL uses
#'   getOption("digits").
#' @param ... Reserved for future methods.
#' @return summary returns a summary.alscl_fit list with numerical diagnostics and
#'   a natural-scale parameter table. print returns its input invisibly.
#' @details The numerical screen is computed once and is the same in the
#'   diagnostics row and in the parameter table. A fit without stored
#'   diagnostics is screened from its stored optimizer code, gradient, Hessian
#'   status and boundary status. A stored assessment whose inputs do not pass
#'   the current input checks is still summarized: the parameter table then
#'   contains the estimated parameters only, and notes gives the reason.
#'   For an ALSCL fit in which growth stops below Linf under the midpoint
#'   growth transition, growth_check holds the message described in the
#'   Details of [run_alscl()].
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' fit
#' s <- summary(fit)
#' s$diagnostics
#' print(s, digits = 3)
#' }
#' @export
summary.alscl_fit <- function(object, ...) {
  years <- object$year
  periods <- if (is.numeric(years) && any(is.finite(years)))
    range(years[is.finite(years)]) else c(NA_real_, NA_real_)
  parameters <- .acl_extract_parameters(object, "natural", .acl_conf_level(.95))
  problem <- attr(parameters, "inspection_error")
  attr(parameters, "inspection_error") <- NULL
  diagnostics <- .acl_fit_status(object)
  parameters$numerical_ok <- rep(isTRUE(diagnostics$numerical_ok), nrow(parameters))
  out <- list(model = object$model_type, periods = periods,
    F_structure = object$F_structure, elapsed = object$elapsed,
    diagnostics = diagnostics, parameters = parameters)
  if (!is.null(problem))
    out$notes <- paste0("Fixed parameters are not listed: the stored inputs do not pass the current input checks (",
                        problem, ").")
  if (isTRUE(object$growth_check$stalled)) out$growth_check <- object$growth_check$message
  structure(out, class = "summary.alscl_fit")
}

#' @rdname summary.alscl_fit
#' @param x A fitted object or its summary.
#' @export
print.summary.alscl_fit <- function(x, digits = NULL, ...) {
  structure_label <- if (length(x$F_structure) == 1L && !is.na(x$F_structure))
    x$F_structure else "not recorded"
  cat(x$model, "assessment; periods", paste(x$periods, collapse = " to "),
      "; F structure:", structure_label, "\n")
  print(x$diagnostics, row.names = FALSE, digits = digits)
  cat("\nFixed-effect parameters (natural scale):\n")
  print(x$parameters, row.names = FALSE, digits = digits)
  if (length(x$notes)) cat("\nNote: ", paste(x$notes, collapse = " "), "\n", sep = "")
  if (length(x$growth_check)) cat("\nGrowth check: ", x$growth_check, "\n", sep = "")
  invisible(x)
}

#' @rdname summary.alscl_fit
#' @export
print.alscl_fit <- function(x, ...) {
  print(summary(x), ...)
  invisible(x)
}

# A stored covariance is usable only when it is finite, has the dimension of
# the free fixed effects and is positive definite. TMB fills the matrix with
# NaN when the Hessian cannot be inverted.
.acl_valid_vcov <- function(fit) {
  cov <- fit$vcov; par <- fit$opt$par
  if (!is.matrix(cov) || !is.numeric(cov) || !length(par) ||
      !identical(dim(cov), c(length(par), length(par))) ||
      any(!is.finite(cov)) || any(diag(cov) <= 0)) return(FALSE)
  all(eigen((cov + t(cov)) / 2, symmetric = TRUE, only.values = TRUE)$values > 0)
}

#' Extract optimizer coefficients and covariance
#' @param object A fitted alscl_fit object.
#' @param ... Reserved for future methods.
#' @return coef returns free fixed effects on the optimizer scale. vcov returns
#'   their covariance matrix, or NULL when unavailable. Fixed and random effects
#'   are excluded; use extract_parameters for natural-scale estimates.
#' @details vcov returns NULL when no covariance was stored, and when the
#'   stored matrix contains nonfinite values or is not positive definite, as
#'   happens when the Hessian is singular. The stored matrix remains available
#'   as object$vcov for inspection.
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' coef(fit)
#'
#' # Standard errors on the optimizer scale
#' sqrt(diag(vcov(fit)))
#' }
#' @export
coef.alscl_fit <- function(object, ...) object$opt$par

#' @rdname coef.alscl_fit
#' @export
vcov.alscl_fit <- function(object, ...) {
  if (.acl_valid_vcov(object)) object$vcov else NULL
}

#' Fitted values, log-likelihood and number of observations of an assessment fit
#' @param object A fitted alscl_fit object, including a portable saved result.
#' @param ... Reserved for future methods; unused arguments are rejected.
#' @return fitted returns a data frame with year, length, length_label and
#'   fitted_log, the fitted natural-log survey index, with rows ordered by
#'   time and then length as in [residuals.alscl_fit()]. logLik returns an
#'   object of class logLik: the negative of the minimized objective, with df
#'   equal to the number of free fixed-effect parameters and nobs equal to the
#'   number of observations in the likelihood. nobs returns that number of
#'   observations.
#' @details The objective is the Laplace approximation of the marginal
#'   negative log-likelihood, with random effects integrated out. AIC() and
#'   BIC() computed from logLik therefore equal the values reported by
#'   [diagnostic_metrics()] and [compare_models()]. They count fixed effects
#'   only and are valid for comparing fits to the same observations. Zero and
#'   missing observations are excluded from the likelihood and from nobs.
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' head(fitted(fit))
#' logLik(fit)
#' AIC(fit)
#' nobs(fit)
#' }
#' @export
fitted.alscl_fit <- function(object, ...) {
  if (length(list(...))) stop("Unused arguments to fitted().", call. = FALSE)
  expected <- object$report$Elog_index
  if (!is.numeric(expected) || !is.matrix(expected))
    stop("The fit does not contain a fitted log index matrix (report$Elog_index).", call. = FALSE)
  coordinates <- .acl_check_coordinates(object, nrow(expected), ncol(expected))
  data.frame(year = rep(coordinates$year, each = nrow(expected)),
    length = rep(coordinates$length, times = ncol(expected)),
    length_label = rep(coordinates$labels, times = ncol(expected)),
    fitted_log = as.vector(expected), stringsAsFactors = FALSE)
}

#' @rdname fitted.alscl_fit
#' @export
nobs.alscl_fit <- function(object, ...) {
  if (length(list(...))) stop("Unused arguments to nobs().", call. = FALSE)
  as.integer(sum(is.finite(.acl_observed_log(object))))
}

#' @rdname fitted.alscl_fit
#' @export
logLik.alscl_fit <- function(object, ...) {
  if (length(list(...))) stop("Unused arguments to logLik().", call. = FALSE)
  objective <- object$opt$objective
  npar <- .acl_npar(object)
  if (!is.numeric(objective) || length(objective) != 1L || !is.finite(objective) || is.na(npar))
    stop("The fit must contain a finite objective (opt$objective) and finite free parameters (opt$par).",
         call. = FALSE)
  n <- tryCatch(nobs.alscl_fit(object), error = function(e) NA_integer_)
  structure(-as.numeric(objective), df = npar, nobs = n, class = "logLik")
}

#' Methods for a failed fit record
#'
#' Batch functions such as [sim_model()] and [fit_scenarios()] keep a record of
#' class alscl_fit_error for a fit that stopped with an error. The record is a
#' list with converge = "FAILED" and the error message in error.
#' @param object,x A failure record of class alscl_fit_error.
#' @param ... Reserved for future methods.
#' @return print and summary report the error message. summary returns a
#'   summary.alscl_fit_error list with the error, the replicate number when
#'   recorded, and a one-row diagnostics table with numerical_ok = FALSE.
#'   coef and vcov return NULL, so a loop over a batch of results does not stop
#'   at a failed fit.
#' @examples
#' # A scenario with an invalid natural mortality rate stops before any model
#' # is fitted, and its error is kept as a failure record.
#' z <- fit_scenarios(YTF_example, list(negative_M = list(M = -1)))
#' failed <- z$fits$negative_M
#' failed
#' summary(failed)$diagnostics$numerical_ok
#' coef(failed)
#' @export
summary.alscl_fit_error <- function(object, ...) {
  message_text <- .acl_error_text(object)
  structure(list(error = message_text, iter = object$iter,
    diagnostics = .acl_fit_status(unclass(object), error = message_text)),
    class = "summary.alscl_fit_error")
}

.acl_error_text <- function(object) {
  value <- object$error
  if (is.character(value) && length(value) == 1L && !is.na(value) && nzchar(value)) value else
    "no error message was recorded"
}

#' @rdname summary.alscl_fit_error
#' @export
print.summary.alscl_fit_error <- function(x, ...) {
  cat("Failed fit", if (length(x$iter) == 1L) paste0("(replicate ", x$iter, ")"), "\n")
  cat("Error:", x$error, "\n")
  invisible(x)
}

#' @rdname summary.alscl_fit_error
#' @export
print.alscl_fit_error <- function(x, ...) {
  print(summary(x), ...)
  invisible(x)
}

#' @rdname summary.alscl_fit_error
#' @export
coef.alscl_fit_error <- function(object, ...) NULL

#' @rdname summary.alscl_fit_error
#' @export
vcov.alscl_fit_error <- function(object, ...) NULL

# An older fit can lack fields that later functions read from the result. Its
# observations may exist only in the live TMB object, which an archive drops.
# Fill absent fields from the supplied inputs; never replace a stored field.
.acl_legacy_metadata <- function(fit, args) {
  notes <- character()
  prepared <- tryCatch(do.call(.acl_prepare_data,
    args[intersect(names(formals(.acl_prepare_data)), names(args))]),
    error = function(e) e)
  if (inherits(prepared, "error"))
    return(list(fit = fit, notes = paste0(
      "Missing result fields were not filled from x: ", conditionMessage(prepared), ".")))
  if (is.null(fit$observations)) {
    supplied <- prepared$observations
    positive <- is.finite(supplied) & supplied > 0
    fitted_log <- tryCatch(.acl_observed_log(fit), error = function(e) NULL)
    if (!is.null(fitted_log)) {
      used <- is.finite(fitted_log)
      if (!identical(dim(fitted_log), dim(supplied)) || !identical(unname(used), unname(positive)) ||
          any(abs(fitted_log[used] - log(supplied[positive])) > 1e-8))
        stop("x$data.CatL does not match the observations in the fitted TMB object. ",
             "Supply the survey table that was used for this fit.", call. = FALSE)
      notes <- c(notes, "Observations were copied from x after they matched the data in the fitted TMB object.")
    } else {
      notes <- c(notes, "Observations were copied from x and could not be compared with the data used in the fit.")
    }
    fit$observations <- supplied
  }
  fill <- list(year = prepared$year, len_mid = prepared$bins$mid,
    len_label = prepared$bins$labels, len_border = prepared$bins$border,
    len_lower = prepared$bins$lower, len_upper = prepared$bins$upper,
    growth_step = prepared$growth_step, age = prepared$data$age,
    F_structure = match.arg(args$F_structure %||% "group_year", c("group_year", "year")))
  absent <- names(fill)[vapply(names(fill), function(nm) is.null(fit[[nm]]), logical(1))]
  if (length(absent)) {
    fit[absent] <- fill[absent]
    notes <- c(notes, paste0("Fields taken from x: ", paste(absent, collapse = ", "), "."))
  }
  list(fit = fit, notes = notes)
}

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
#'   source revision is inferred for an older fit supplied with x. For such a
#'   fit, result fields that it lacks (observations, time labels, ages, length
#'   bins, time step and F structure) are filled from x, so that residuals,
#'   estimates and plots remain available after the live TMB object is
#'   dropped. Observations are compared with the data in the live TMB object
#'   when it is present, and a mismatch is an error. recipe$provenance lists
#'   the fields that came from x. The file uses R serialization version 3,
#'   which records the character encoding of length labels and column names.
#'   Concurrent saves to the same path use a temporary lock directory during
#'   the final rename. With overwrite = FALSE, only the first save can publish
#'   the archive. If an interrupted process leaves a lock, confirm that the
#'   writer has stopped before removing the lock directory named in the error.
#'   A fresh session can summarize and plot it without a live
#'   TMB pointer. refit_model rebuilds a live model; cross-version numerical
#'   equality is not promised. Only read archives from trusted sources.
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' path <- tempfile(fileext = ".rds")
#' save_assessment(fit, path)
#' saved <- read_assessment(path)
#' summary(saved)
#' unlink(path)
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
    filled <- .acl_legacy_metadata(fit, args)
    fit <- .acl_attach_recipe(filled$fit, model, args)
    # Current source metadata cannot establish which implementation fitted legacy results.
    fit$recipe$implementation <- NULL
    fit$recipe$provenance <- paste(c("User-supplied recipe for legacy fit; original biology, weights, maturity, maps, bounds, starts, software and computational settings unverified.",
      if (length(unknown)) paste0("Observation checks incomplete: ", paste(unknown, collapse = "; "), ".") else "Stored observations match supplied observations.",
      filled$notes), collapse = " ")
  }
  .acl_recipe(fit)
  portable <- fit; portable$obj <- NULL
  class(portable) <- c("alscl_fit", "list")
  temporary <- tempfile(".alscl-archive-", tmpdir = dirname(file))
  on.exit(unlink(temporary, expand = FALSE), add = TRUE)
  # Serialization version 3 records the native encoding of the writing session,
  # so labels with non-ASCII characters are converted when read elsewhere.
  saveRDS(list(format = "ALSCL assessment", schema_version = 1L, fit = portable), temporary, version = 3)
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
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' path <- tempfile(fileext = ".rds")
#' save_assessment(fit, path)
#' saved <- read_assessment(path)
#'
#' # The archive has no TMB object, and the estimates are unchanged
#' is.null(saved$obj)
#' all.equal(coef(saved), coef(fit))
#' plot_SSB(saved)
#' unlink(path)
#' }
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
#'   it does not establish cross-platform numerical equality. A stored map can
#'   hold a named NULL entry for a parameter that the model does not have,
#'   which release 2.4.3 accepted and ignored; such an entry is dropped before
#'   refitting unless map is overridden.
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#'
#' # Refit with a lower natural mortality rate; other settings are unchanged
#' low_M <- refit_model(fit, M = 0.15)
#' low_M$recipe$args$M
#' extract_parameters(low_M)[1:5, c("parameter", "estimate")]
#' }
#' @export
refit_model <- function(fit, ...) {
  recipe <- .acl_recipe(fit)
  .acl_check_implementation(recipe)
  overrides <- list(...)
  if (!"output" %in% names(overrides)) overrides$output <- FALSE
  args <- .acl_bundle_args(.acl_recipe_map_compat(recipe$args, recipe$model),
                           recipe$model, overrides)
  previous <- options(recipe$settings); on.exit(options(previous), add = TRUE)
  do.call(if (recipe$model == "acl") run_acl else run_alscl, args)
}
