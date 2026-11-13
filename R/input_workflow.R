# Fully evaluate the original run_* formals without fitting. In particular,
# nstarts = ncores follows the final override, and named NULL entries survive.
.acl_resolved_args <- function(x, model, overrides = list()) {
  model <- match.arg(model, c("acl", "alscl"))
  fun <- if (model == "acl") run_acl else run_alscl
  args <- .acl_bundle_args(x, model, overrides)
  frame <- list2env(args, parent = environment(fun))
  defaults <- formals(fun)
  for (nm in setdiff(names(defaults), names(args)))
    assign(nm, eval(defaults[[nm]], envir = frame), envir = frame)
  mget(names(defaults), envir = frame, inherits = FALSE)
}

.acl_input_list <- function(x, label, allowed = NULL) {
  if (!is.list(x) || is.data.frame(x) || (length(x) &&
      (is.null(names(x)) || anyNA(names(x)) || any(!nzchar(names(x))) ||
       anyDuplicated(names(x)))))
    stop(label, " must be a list with unique, non-empty names.", call. = FALSE)
  if (!is.null(allowed) && length(setdiff(names(x), allowed)))
    stop(label, " contains unknown arguments: ",
         paste(setdiff(names(x), allowed), collapse = ", "), call. = FALSE)
  x
}

.acl_numeric_survey_table <- function(x, label) {
  if (length(dim(x)) != 2L || ncol(x) < 3L || nrow(x) < 2L)
    stop(label, " requires a label column, two time columns and two length bins.",
         call. = FALSE)
  x <- as.data.frame(x, stringsAsFactors = FALSE, check.names = FALSE)
  if (is.null(names(x)) || anyNA(names(x)) || any(!nzchar(names(x))) ||
      anyDuplicated(names(x)))
    stop(label, " must have unique, non-empty column names.", call. = FALSE)
  x[[1L]] <- trimws(as.character(x[[1L]]))
  if (anyNA(x[[1L]]) || any(!nzchar(x[[1L]])) || anyDuplicated(x[[1L]]))
    stop(label, " length labels must be present and unique.", call. = FALSE)
  for (i in seq.int(2L, ncol(x))) {
    # Preserve native floating-point observations exactly. A round-trip through
    # as.character() can discard significant digits and alter a fitted result.
    if (is.numeric(x[[i]]) && !is.complex(x[[i]])) next
    old <- trimws(as.character(x[[i]]))
    old[is.na(old) | old %in% c("", "NA")] <- NA_character_
    value <- suppressWarnings(as.numeric(old))
    if (any(is.na(value) & !is.na(old)))
      stop(label, " contains a nonnumeric cell in time column ", names(x)[i],
           call. = FALSE)
    x[[i]] <- value
  }
  x
}

.acl_input_tables <- function(tables) {
  required <- c("data.CatL", "data.wgt", "data.mat")
  .acl_input_list(tables, "tables", required)
  if (!all(required %in% names(tables)))
    stop("Three input tables are required: data.CatL, data.wgt and data.mat.",
         call. = FALSE)
  tables <- stats::setNames(lapply(required, function(nm)
    .acl_numeric_survey_table(tables[[nm]], nm)), required)
  d <- tables$data.CatL
  for (nm in required[-1L]) {
    other <- tables[[nm]]
    if (!identical(dim(other), dim(d)) ||
        !identical(names(other)[-1L], names(d)[-1L]) ||
        !identical(other[[1L]], d[[1L]]))
      stop(nm, " must match data.CatL length labels and time columns, including order.",
           call. = FALSE)
  }
  survey <- .acl_survey_data(d)
  if (any(!is.finite(survey$years)) || any(diff(survey$years) <= 0))
    stop("Time columns must have increasing numeric labels.", call. = FALSE)
  weights <- as.matrix(tables$data.wgt[-1L])
  maturity <- as.matrix(tables$data.mat[-1L])
  if (any(!is.finite(weights)) || any(weights < 0))
    stop("Weights must be finite and nonnegative.", call. = FALSE)
  if (any(!is.finite(maturity)) || any(maturity < 0 | maturity > 1))
    stop("Maturity must be finite and in [0, 1].", call. = FALSE)
  tables
}

#' Read survey tables from three CSV files
#'
#' Read `data.CatL.csv`, `data.wgt.csv` and `data.mat.csv` from one directory.
#' Each table has length labels in its first column and numeric time labels
#' in the remaining headers. Numeric text and factor labels are converted
#' safely; blank cells and `NA` denote missing values. Tables retain their
#' original row and column order. Biological inputs are supplied separately.
#' @param folder Directory containing the three CSV files.
#' @return A named list containing numeric data.CatL, data.wgt and data.mat
#'   tables. No missing periods, weights or maturity values are imputed.
#' @seealso [prepare_alscl_data()], [check_alscl_data()]
#' @examples
#' # Write the three example tables as CSV files, then read them back
#' folder <- tempfile("survey")
#' dir.create(folder)
#' for (name in c("data.CatL", "data.wgt", "data.mat"))
#'   write.csv(YTF_example[[name]], file.path(folder, paste0(name, ".csv")),
#'             row.names = FALSE)
#' tables <- read_survey_csv(folder)
#' tables$data.CatL[1:3, 1:4]
#'
#' # Add the biological inputs and check the configuration before fitting
#' x <- prepare_alscl_data(tables, fit_args = YTF_example$fit_args)
#' check_alscl_data(x, "acl")$valid
#' unlink(folder, recursive = TRUE)
#' @export
read_survey_csv <- function(folder) {
  if (!is.character(folder) || length(folder) != 1L || is.na(folder) ||
      !dir.exists(folder))
    stop("folder must name an existing directory.", call. = FALSE)
  names <- c("data.CatL", "data.wgt", "data.mat")
  files <- file.path(folder, paste0(names, ".csv"))
  if (any(!file.exists(files)))
    stop("Missing survey CSV files: ",
         paste(basename(files[!file.exists(files)]), collapse = ", "), call. = FALSE)
  tables <- stats::setNames(lapply(files, function(path) utils::read.csv(path,
    check.names = FALSE, colClasses = "character", na.strings = c("", "NA"))), names)
  .acl_input_tables(tables)
}

# Locate cells that hold an Excel error value such as #DIV/0! or #N/A. readxl
# imports these cells as NA, which the survey tables read as missing
# observations. Only the zipped workbook formats (.xlsx, .xlsm) can be
# inspected; NULL means that the workbook could not be inspected.
.acl_excel_error_cells <- function(file, sheets) {
  tryCatch({
    parts <- utils::unzip(file, list = TRUE)$Name
    index <- c("xl/workbook.xml", "xl/_rels/workbook.xml.rels")
    if (!all(index %in% parts)) return(NULL)
    folder <- tempfile("alscl-workbook-")
    dir.create(folder)
    on.exit(unlink(folder, recursive = TRUE), add = TRUE)
    read_part <- function(part) {
      utils::unzip(file, files = part, exdir = folder)
      paste(readLines(file.path(folder, part), warn = FALSE, encoding = "UTF-8"), collapse = "")
    }
    tags <- function(text, element)
      regmatches(text, gregexpr(paste0("<(?:[A-Za-z0-9]+:)?", element, "\\s[^>]*>"), text, perl = TRUE))[[1L]]
    attribute <- function(tag, name) {
      found <- regmatches(tag, regexec(paste0("\\s", name, "=\"([^\"]*)\""), tag, perl = TRUE))
      vapply(found, function(m) if (length(m) == 2L) m[2L] else NA_character_, character(1))
    }
    sheet_tags <- tags(read_part(index[1L]), "sheet")
    relation_tags <- tags(read_part(index[2L]), "Relationship")
    sheet_names <- attribute(sheet_tags, "name")
    sheet_ids <- attribute(sheet_tags, "(?:[A-Za-z0-9]+:)id")
    targets <- stats::setNames(attribute(relation_tags, "Target"), attribute(relation_tags, "Id"))
    out <- stats::setNames(vector("list", length(sheets)), sheets)
    for (sheet in sheets) {
      target <- targets[[sheet_ids[match(sheet, sheet_names)]]]
      part <- if (startsWith(target, "/")) substring(target, 2L) else paste0("xl/", target)
      if (!part %in% parts) return(NULL)
      cells <- tags(read_part(part), "c")
      cells <- cells[grepl("\\st=\"e\"", cells, perl = TRUE)]
      references <- attribute(cells, "r")
      references[is.na(references)] <- "unknown cell"
      out[[sheet]] <- references
    }
    out
  }, error = function(e) NULL, warning = function(w) NULL)
}

#' Read survey tables from an Excel workbook
#'
#' The workbook must contain sheets named `data.CatL`, `data.wgt` and `data.mat`
#' with the same layout as [read_survey_csv()]. Requires the optional readxl
#' package. Importing validates the tables but does not choose biological inputs.
#' @param file Path to an existing Excel workbook.
#' @return A named list containing the three numeric survey tables.
#' @details Only blank cells and `NA` denote missing values. A cell that holds
#'   an Excel error value, such as `#DIV/0!` or `#N/A` from a formula, is an
#'   error: readxl would otherwise import it as a missing value and the
#'   observation would be left out of the likelihood without a message. The
#'   error names the sheet and the cells. This check reads the workbook file
#'   directly and applies to the `.xlsx` and `.xlsm` formats; cells of a
#'   workbook in the older `.xls` format cannot be checked in this way.
#' @seealso [prepare_alscl_data()], [check_alscl_data()]
#' @examples
#' # The typical call is not run: the package has no example workbook, and R
#' # needs an additional package to write one.
#' \dontrun{
#' tables <- read_survey_excel("survey.xlsx")
#' x <- prepare_alscl_data(tables, fit_args = list(rec.age = 1, nage = 15,
#'   M = 0.2, sel_L50 = 15, sel_L95 = 20))
#' check_alscl_data(x, "acl")$valid
#' }
#'
#' # A workbook without the three sheets is rejected, and the message names
#' # the missing sheets.
#' if (requireNamespace("readxl", quietly = TRUE)) {
#'   workbook <- readxl::readxl_example("datasets.xlsx")
#'   try(read_survey_excel(workbook))
#' }
#' @export
read_survey_excel <- function(file) {
  if (!is.character(file) || length(file) != 1L || is.na(file) || !file.exists(file))
    stop("file must name an existing Excel workbook.", call. = FALSE)
  if (!requireNamespace("readxl", quietly = TRUE))
    stop("Reading Excel requires the optional readxl package; install.packages('readxl').",
         call. = FALSE)
  sheets <- c("data.CatL", "data.wgt", "data.mat")
  absent <- setdiff(sheets, readxl::excel_sheets(file))
  if (length(absent))
    stop("Missing workbook sheets: ", paste(absent, collapse = ", "), call. = FALSE)
  flagged <- .acl_excel_error_cells(file, sheets)
  flagged <- flagged[lengths(flagged) > 0L]
  if (length(flagged)) {
    listing <- vapply(names(flagged), function(sheet) {
      cells <- flagged[[sheet]]
      shown <- paste(utils::head(cells, 10L), collapse = ", ")
      if (length(cells) > 10L) shown <- paste0(shown, " and ", length(cells) - 10L, " more")
      paste0("sheet ", sheet, ": ", shown)
    }, character(1))
    stop("The workbook contains Excel error values (for example #DIV/0! or #N/A) in ",
         paste(listing, collapse = "; "),
         ". Correct these cells, or clear them to record missing values.", call. = FALSE)
  }
  tables <- stats::setNames(lapply(sheets, function(sheet) readxl::read_excel(file,
    sheet = sheet, col_types = "text", na = c("", "NA"), .name_repair = "minimal")), sheets)
  .acl_input_tables(tables)
}

#' Prepare an input bundle for ACL and ALSCL fitting
#'
#' Construct a bundle accepted directly by [run_acl()] and [run_alscl()]. The
#' constructor checks table alignment and values without compiling or fitting.
#' Supply biological inputs explicitly in fit_args; no stock biology, time step
#' or parameter map is inferred from a file. Run [check_alscl_data()] to validate
#' the complete configuration for a particular model before fitting.
#' @param data.CatL Survey table, or a named list containing all three tables.
#' @param data.wgt Weight-at-length table.
#' @param data.mat Maturity-at-length table.
#' @param file CSV directory or Excel workbook when format is not "tables".
#' @param format Input format: "tables", "csv" or "excel".
#' @param fit_args Named list of shared fitting arguments, including rec.age,
#'   nage, M, sel_L50 and sel_L95. Keep the three tables outside this list.
#'   The ALSCL-only arguments len_lower and len_upper are deprecated: they
#'   cannot change a fit, ACL fits ignore them, and they will be removed.
#' @param fit_config Optional named list with acl and/or alscl model-specific
#'   settings. A model without an entry uses the shared fit_args only.
#' @details Settings follow the ordinary bundle precedence: shared fit_args,
#'   selected fit_config, then explicit arguments to run_acl/run_alscl. List-valued
#'   overrides replace complete lists. Named NULL map releases are preserved.
#'   Zeros remain zeros; the model's zero_action decides whether to exclude or
#'   reject them. Missing survey periods must be explicit columns with complete
#'   weights and maturity. This constructor never fills or reorders periods.
#'
#'   Only the three tables, fit_args and fit_config are fitting settings. A
#'   fitting argument stored at the top level of the returned list, for example
#'   `x$M <- 0.3` or `x$map <- ...`, is not used, and fitting warns about it.
#'   Store such a setting in `x$fit_args` or `x$fit_config$acl` or
#'   `x$fit_config$alscl`. A top-level `parameters` entry is not reported:
#'   example bundles such as YTF_example keep their simulation settings there.
#' @return A structured input list with the three tables, fit_args and optional
#'   fit_config. It can be saved with saveRDS() and reused in either model.
#' @examples
#' x <- prepare_alscl_data(YTF_example[c("data.CatL", "data.wgt", "data.mat")],
#'   fit_args = YTF_example$fit_args, fit_config = YTF_example$fit_config)
#' check_alscl_data(x, "acl")$valid
#' inspect_parameters(x, "acl")
#' @export
prepare_alscl_data <- function(data.CatL = NULL, data.wgt = NULL, data.mat = NULL,
                               file = NULL, format = c("tables", "csv", "excel"),
                               fit_args = list(), fit_config = NULL) {
  format <- match.arg(format)
  table_names <- c("data.CatL", "data.wgt", "data.mat")
  allowed <- setdiff(union(names(formals(run_acl)), names(formals(run_alscl))), table_names)
  .acl_input_list(fit_args, "fit_args", allowed)
  if (!is.null(fit_config)) {
    .acl_input_list(fit_config, "fit_config", c("acl", "alscl"))
    for (model in names(fit_config))
      .acl_input_list(fit_config[[model]], paste0("fit_config$", model),
        setdiff(names(formals(if (model == "acl") run_acl else run_alscl)), table_names))
  }
  bounds <- c("len_lower", "len_upper")
  if (any(bounds %in% names(fit_args)) || any(bounds %in% names(fit_config$alscl)))
    .acl_deprecated_bin_bounds("prepare_alscl_data")
  if (format == "tables") {
    if (!is.null(file)) stop("file is only used with format = 'csv' or 'excel'.", call. = FALSE)
    tables <- if (is.list(data.CatL) && !is.data.frame(data.CatL)) {
      if (!is.null(data.wgt) || !is.null(data.mat))
        stop("Supply either a three-table list or three separate tables.", call. = FALSE)
      data.CatL
    } else list(data.CatL = data.CatL, data.wgt = data.wgt, data.mat = data.mat)
    tables <- .acl_input_tables(tables)
  } else {
    if (!is.null(data.CatL) || !is.null(data.wgt) || !is.null(data.mat))
      stop("File imports cannot also supply table arguments.", call. = FALSE)
    tables <- if (format == "csv") read_survey_csv(file) else read_survey_excel(file)
  }
  tables$fit_args <- fit_args
  if (!is.null(fit_config)) tables$fit_config <- fit_config
  tables
}

.acl_preflight <- function(x, model) {
  args <- .acl_resolved_args(x, model)
  data_names <- intersect(names(formals(.acl_prepare_data)), names(args))
  prepared <- do.call(.acl_prepare_data, args[data_names])
  structure <- match.arg(args$F_structure, c("group_year", "year"))
  setup <- .acl_model_setup(toupper(model), prepared, args$parameters,
    args$parameters.L, args$parameters.U, args$map, structure)
  .acl_check_fit_flags(args$polish, args$silent, args$output)
  .acl_fit_control(args$control)
  for (nm in c("train_times", "ncores", "nstarts"))
    .acl_positive_integer(args[[nm]], nm)
  if (any(!is.finite(unlist(setup$parameters))))
    stop("Effective parameter starts must be finite, including fixed parameters.", call. = FALSE)
  scalar_names <- names(setup$config$parameters)
  free <- scalar_names[vapply(scalar_names, function(nm)
    is.null(setup$map[[nm]]) || any(!is.na(setup$map[[nm]])), logical(1))]
  if (!length(free)) stop("At least one fixed-effect parameter must remain free.", call. = FALSE)
  .acl_bounds(unlist(setup$parameters[free]), setup$config)
  list(args = args, prepared = prepared, setup = setup)
}

# Shared optimizer/natural-scale transformation; no arithmetic-mean claim is
# attached to exponentiated log locations or log random-effect deviations.
.acl_parameter_transform <- function(name, value, derivative = FALSE, inverse = FALSE,
                                     settings = .acl_scale_settings()) {
  correlation <- grepl("^logit_", name)
  positive <- grepl("^(log_|mean_log_|dev_log_)", name)
  shift <- if (identical(name, "log_t0")) settings$t0_lower else 0
  if (inverse) {
    if (correlation) return(stats::qlogis(if (settings$symmetric) (value + 1) / 2 else value))
    if (positive) return(log(value - shift))
    return(value)
  }
  if (correlation) {
    p <- stats::plogis(value)
    if (settings$symmetric) return(if (derivative) 2 * p * (1 - p) else 2 * p - 1)
    return(if (derivative) p * (1 - p) else p)
  }
  if (positive) return(if (derivative) exp(value) else shift + exp(value))
  if (derivative) rep(1, length(value)) else value
}

.acl_parameter_table <- function(preflight, model) {
  setup <- preflight$setup; args <- preflight$args
  settings <- .acl_scale_settings(list(structure = setup$structure, t0_lower = setup$t0_lower))
  default_map <- .acl_map(setup$parameters, NULL, toupper(model))
  group <- if (model == "acl") "logit_log_F_a" else "logit_log_F_l"
  rows <- lapply(names(setup$parameters), function(nm) {
    value <- setup$parameters[[nm]]; mapping <- setup$map[[nm]]
    size <- length(value)
    fixed <- if (is.null(mapping)) 0L else sum(is.na(mapping))
    free <- if (is.null(mapping)) size else length(unique(mapping[!is.na(mapping)]))
    tied <- size - fixed - free
    inactive <- setup$F_structure == "year" && nm == group
    source <- if (inactive) "F_structure" else if (nm %in% names(args$map))
      "explicit" else if (nm %in% names(default_map)) "default" else "unmapped"
    status <- if (inactive) "inactive" else if (fixed == size) "fixed" else if (fixed > 0L)
      "mixed" else if (tied > 0L) "tied" else "free"
    scalar <- nm %in% names(setup$config$parameters)
    data.frame(parameter = nm, kind = if (scalar) "fixed_effect" else "random_effect",
      start = unname(value[1L]), natural_start = unname(.acl_parameter_transform(nm, value[1L], settings = settings)),
      lower = if (scalar) setup$config$parameters.L[[nm]] else -Inf,
      upper = if (scalar) setup$config$parameters.U[[nm]] else Inf,
      transform = if (grepl("^logit_", nm)) (if (settings$symmetric) "2*plogis-1" else "plogis") else
        if (nm == "log_t0" && settings$t0_lower != 0) "t0_lower+exp" else
        if (grepl("^(log_|mean_log_|dev_log_)", nm)) "exp" else "identity",
      status = status, map_source = source, size = size,
      dimensions = paste(if (is.null(dim(value))) length(value) else dim(value), collapse = " x "),
      n_free = free, n_fixed = fixed, n_tied = tied, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Inspect effective parameter starts, bounds and map restrictions
#'
#' Resolve the same bundle settings and preparation used by fitting, without
#' compiling or optimizing. This includes data-derived starts, start clamping,
#' recruitment-age bounds and shared-F restrictions, which a table made only
#' from create_parameters() cannot show.
#' @param x Named input bundle accepted by run_acl() or run_alscl().
#' @param model Model to inspect: "acl" or "alscl".
#' @return A data frame with one row per parameter or random-effect block.
#'   Columns include parameter, kind, start, natural_start, lower, upper,
#'   transform, status, map_source, size, dimensions, n_free, n_fixed and n_tied.
#'   Bounds and starts are on the optimizer scale. Natural starts apply exp,
#'   plogis or identity. exp(mean_log_R) and exp(mean_log_F) are natural-scale
#'   process baselines, not arithmetic means. Random-effect starts are all zero;
#'   natural_start is their
#'   multiplicative factor. n_free counts independent mapped values; n_tied
#'   counts additional entries sharing these values. kind = "fixed_effect"
#'   identifies an outer-model parameter, even when its status is "free".
#'   An inactive correlation is fixed because shared F does not use it.
#' @seealso [check_alscl_data()], [prepare_alscl_data()]
#' @examples
#' starts <- inspect_parameters(YTF_example, "alscl")
#' starts[, c("parameter", "natural_start", "lower", "upper", "status")]
#' @export
inspect_parameters <- function(x, model = c("acl", "alscl")) {
  model <- match.arg(model)
  .acl_parameter_table(.acl_preflight(x, model), model)
}

#' Check a complete ALSCL or ACL input configuration without fitting
#'
#' Perform the core table, time-grid, biology, bin, start, bound and map checks
#' without compiling TMB or running an optimizer. A successful check establishes
#' input consistency; it does not establish identifiability or convergence.
#' @param x Named input bundle accepted by run_acl() or run_alscl().
#' @param model Model to check: "acl" or "alscl".
#' @return A list with valid, errors, warnings, summary, time and length_bins.
#'   Invalid configurations return valid = FALSE and an error message instead
#'   of fitting. summary records positive, zero and missing observations, fully
#'   unobserved periods/bins, and free fixed/random parameter counts. Warnings
#'   flag excluded zeros, unobserved periods/bins and very sparse observations.
#'   They are screening messages, not a statistical test of data sufficiency.
#' @seealso [inspect_parameters()], [prepare_alscl_data()]
#' @examples
#' check <- check_alscl_data(YTF_example, "acl")
#' check$valid
#' check$summary
#'
#' # An invalid setting is reported and the call does not stop
#' x <- YTF_example
#' x$fit_args$M <- -1
#' check_alscl_data(x, "acl")$errors
#' @export
check_alscl_data <- function(x, model = c("acl", "alscl")) {
  model <- match.arg(model)
  preflight <- tryCatch(.acl_preflight(x, model), error = function(e) e)
  if (inherits(preflight, "error"))
    return(list(valid = FALSE, model = model, errors = conditionMessage(preflight),
      warnings = character(), summary = NULL, time = NULL, length_bins = NULL))
  obs <- preflight$prepared$observations
  mask <- is.finite(obs) & obs > 0
  table <- .acl_parameter_table(preflight, model)
  fixed <- sum(table$n_free[table$kind == "fixed_effect"])
  random <- sum(table$n_free[table$kind == "random_effect"])
  empty_periods <- which(colSums(mask) == 0L)
  empty_bins <- which(rowSums(mask) == 0L)
  zeros <- sum(obs == 0, na.rm = TRUE)
  messages <- character()
  if (zeros) messages <- c(messages, paste(zeros, "zero observations will be excluded by zero_action = 'missing'."))
  if (length(empty_periods)) messages <- c(messages,
    paste("No positive observations in periods:", paste(preflight$prepared$year[empty_periods], collapse = ", ")))
  if (length(empty_bins)) messages <- c(messages,
    paste("No positive observations in length bins:", paste(preflight$prepared$bins$labels[empty_bins], collapse = ", ")))
  if (sum(mask) <= fixed) messages <- c(messages,
    "Positive observation count does not exceed the free fixed-parameter count; review identifiability.")
  list(valid = TRUE, model = model, errors = character(), warnings = messages,
    summary = data.frame(length_bins = nrow(obs), time_steps = ncol(obs),
      positive = sum(mask), zeros = zeros, missing = sum(is.na(obs)),
      unobserved_periods = length(empty_periods), unobserved_bins = length(empty_bins),
      free_fixed = fixed, free_random = random),
    time = preflight$prepared$year, length_bins = preflight$prepared$bins)
}
