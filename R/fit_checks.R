# Checks for fits that pass the gradient, Hessian and bound checks of the
# numerical screen but are not usable.
#  - .acl_limit_parameters(): a parameter on a logarithmic or logit scale that
#    has run so far that it is at its limit in practice, although it has not
#    reached the optimizer bound. Such a fit fails the numerical screen, as a
#    fit that stopped at a bound does.
#  - .acl_bound_advice(): what to do when a fit stopped at an upper bound that
#    the user can widen.
#  - .acl_plausibility(): estimates with implausible values. These are notes
#    and do not change the verdict of the numerical screen.
# The thresholds are set in .acl_check_thresholds and nowhere else.
.acl_check_thresholds <- list(
  # log_t0 below this value: t0 is less than 5e-5 years above t0_lower.
  log_t0 = -10,
  # Logarithm of a standard deviation below this value: the standard
  # deviation is below 1.3e-4, a variance of zero.
  log_sd = -9,
  # Absolute value of a logit correlation above this value: the correlation
  # is within 3.1e-7 (range 0 to 1) or 6.2e-7 (range -1 to 1) of an end.
  logit_correlation = 15,
  # Number of length-bin widths by which the mean length of recruits may lie
  # below the lower border of the second length bin.
  recruit_length_bins = 2,
  # Standard deviation of the observation error on the log scale.
  observation_sd = 0.9,
  # Coefficients of variation of length at age (cv_len) and of the growth
  # increment (cv_grow).
  growth_cv = 0.3,
  # Example range of the coefficient of variation of length at age in the
  # Stock Synthesis manual; quoted in the note on cv_len.
  growth_cv_reference = c(0.10, 0.25))

.acl_check_number <- function(x) vapply(x, function(v) format(signif(v, 3)), character(1), USE.NAMES = FALSE)

# Parameters at their limit in practice. `flagged` names parameters that the
# natural-scale boundary check has already found; they are listed as well, so
# that every such parameter is named with its natural value and with advice.
.acl_limit_parameters <- function(fit, flagged = character()) {
  th <- .acl_check_thresholds
  par <- fit$opt$par
  out <- data.frame(parameter = character(), estimate = numeric(), natural = numeric(),
    description = character(), advice = character(), stringsAsFactors = FALSE)
  if (!is.numeric(par) || !length(par) || is.null(names(par))) return(out)
  settings <- .acl_scale_settings(fit)
  number <- .acl_check_number
  fix <- function(nm) paste0("Fix ", nm, " with map = list(", nm, " = factor(NA)) and a chosen value in parameters")
  for (nm in names(par)) {
    x <- par[[nm]]
    if (!is.finite(x)) next
    row <- NULL
    if (nm == "log_t0" && x < th$log_t0) {
      row <- list(natural = settings$t0_lower + exp(x),
        description = sprintf("log_t0 = %s (t0 = t0_lower + %s years)", number(x), number(exp(x))),
        advice = sprintf(paste0("log_t0 is estimated at %s, so t0 is %s years above its lower limit ",
          "t0_lower = %s and equals that limit in practice. %s, or allow a smaller t0 with t0_lower, and refit."),
          number(x), number(exp(x)), number(settings$t0_lower), fix(nm)))
    } else if (grepl("^log_(std|sigma)", nm) && (x < th$log_sd || nm %in% flagged)) {
      row <- list(natural = exp(x),
        description = sprintf("%s = %s (standard deviation %s)", nm, number(x), number(exp(x))),
        advice = sprintf(paste0("%s is estimated at %s, a standard deviation of %s, so the variance is ",
          "estimated at zero. %s and refit."), nm, number(x), number(exp(x)), fix(nm)))
    } else if (grepl("^logit_", nm) && (abs(x) > th$logit_correlation || nm %in% flagged)) {
      low <- if (settings$symmetric) -1 else 0
      # Distance to the nearer end of the range, computed without cancellation.
      gap <- (if (settings$symmetric) 2 else 1) * stats::plogis(-abs(x))
      upper <- x > 0
      natural <- if (upper) 1 - gap else low + gap
      shown <- if (upper) paste0("1 - ", number(gap)) else if (settings$symmetric)
        paste0("-1 + ", number(gap)) else number(gap)
      range <- if (settings$symmetric) "-1 to 1" else "0 to 1"
      row <- list(natural = natural,
        description = sprintf("%s = %s (correlation %s)", nm, number(x), shown),
        advice = sprintf("%s is estimated at %s, a correlation of %s, at the %s end of its range (%s). %s%s and refit.",
          nm, number(x), shown, if (upper) "upper" else "lower", range, fix(nm),
          if (!upper && !settings$symmetric) paste0(", or use structure = list(correlation_range = \"symmetric\"), ",
            "with which a correlation of zero lies inside the range,") else ""))
    }
    if (!is.null(row))
      out <- rbind(out, data.frame(parameter = nm, estimate = x, natural = row$natural,
        description = row$description, advice = row$advice, stringsAsFactors = FALSE))
  }
  rownames(out) <- NULL
  out
}

# ACL names of the parameters whose bounds run_acl(bounds = "wide") takes from
# ALSCL, with their ALSCL names.
.acl_wide_names <- c(log_init_Z = "log_init_Z", mean_log_F = "mean_log_F",
  log_std_log_N0 = "log_sigma_log_N0", log_std_log_R = "log_sigma_log_R", log_vbk = "log_vbk")

# Lower and upper bounds that ALSCL has for these parameters, under ACL names.
.acl_wide_bounds <- function(species = NULL) {
  alscl <- create_parameters("alscl", species = species)
  list(lower = stats::setNames(alscl$parameters.L[.acl_wide_names], names(.acl_wide_names)),
       upper = stats::setNames(alscl$parameters.U[.acl_wide_names], names(.acl_wide_names)))
}

# Advice for a fit that stopped at an upper bound which can be widened: the
# upper bounds of ACL that are lower than those of ALSCL, and the upper bound
# of t0.
.acl_bound_advice <- function(fit) {
  p <- fit$par_low_up
  if (!is.matrix(p) || !is.numeric(p) || is.null(rownames(p)) ||
      !all(c("estimate", "upper") %in% colnames(p))) return(character())
  at_upper <- rownames(p)[is.finite(p[, "upper"]) & is.finite(p[, "estimate"]) &
                          p[, "upper"] - p[, "estimate"] <= 1e-7]
  if (!length(at_upper)) return(character())
  number <- .acl_check_number
  out <- character()
  if (identical(fit$model_type, "ACL")) {
    wide <- unlist(.acl_wide_bounds()$upper)
    hit <- intersect(at_upper, names(wide))
    hit <- hit[p[hit, "upper"] < wide[hit] - 1e-7]
    if (length(hit))
      out <- c(out, paste0(
        paste(sprintf("%s (%s on the natural scale)", hit, number(exp(p[hit, "upper"]))), collapse = ", "),
        " stopped at ", if (length(hit) > 1L) "upper bounds" else "an upper bound",
        " of ACL that ", if (length(hit) > 1L) "are" else "is", " below the upper bound of ALSCL (",
        paste(sprintf("%s for %s", number(exp(wide[hit])), hit), collapse = ", "),
        "). Refit with run_acl(bounds = \"wide\"), which gives ACL the bounds of ALSCL for the initial total ",
        "mortality rate, the mean fishing mortality rate, the standard deviations of the initial numbers ",
        "at age and of recruitment, and the von Bertalanffy growth rate k, or supply single bounds in parameters.U."))
  }
  t0_name <- intersect(c("t0", "log_t0"), at_upper)
  age <- fit$age
  if (length(t0_name) == 1L && is.numeric(age) && length(age) && is.finite(age[1L])) {
    t0_lower <- .acl_scale_settings(fit)$t0_lower
    bound <- p[t0_name, "upper"]
    t0 <- if (t0_name == "t0") bound else t0_lower + exp(bound)
    if (t0 >= age[1L] * (1 - 1e-5)) {
      out <- c(out, sprintf(paste0("%s stopped at its upper bound, where t0 equals the first modelled age ",
        "(rec.age = %s) and the mean length of recruits is zero. Check rec.age and the starting values of the ",
        "growth parameters."), t0_name, number(age[1L])))
    } else if (t0_name == "log_t0") {
      out <- c(out, sprintf(paste0("log_t0 stopped at its upper bound (t0 = %s years), which is below the first ",
        "modelled age (rec.age = %s). A higher bound, up to log(%s), can be supplied in parameters.U."),
        number(t0), number(age[1L]), number(age[1L] - t0_lower)))
    }
  }
  out
}

# Natural mortality rate of a fit, in whatever form the fit stores it (one
# number, a vector or a matrix). NULL when the fit does not store it.
.acl_fit_M <- function(fit) {
  data <- tryCatch(fit$obj$env$data, error = function(e) NULL)
  # With natural mortality by age and time step or by length the templates
  # read M_AY (ACL) or M_LAY (ALSCL); the single number M in the data is then
  # only a summary used for a default start, so it is the last candidate.
  candidates <- list(data[["M_AY"]], data[["M_LAY"]], fit$report[["M_LAY"]], fit[["M"]],
    fit$recipe$args[["M"]], data[["M"]])
  for (M in candidates)
    if (is.numeric(M) && any(is.finite(M))) return(M[is.finite(M)])
  NULL
}

# Plausibility notes. The mean length of recruits is derived from the growth
# parameters and the first modelled age and is checked whether or not those
# are estimated. The other checks apply to estimated parameters only: a value
# that the user fixed is an assumption, not a result of the fit.
.acl_plausibility <- function(fit) {
  th <- .acl_check_thresholds
  out <- data.frame(check = character(), parameter = character(), value = numeric(),
    threshold = numeric(), note = character(), stringsAsFactors = FALSE)
  add <- function(check, parameter, value, threshold, note)
    out <<- rbind(out, data.frame(check = check, parameter = parameter, value = value,
      threshold = threshold, note = note, stringsAsFactors = FALSE))
  number <- .acl_check_number
  one <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)
  par <- fit$opt$par
  if (!is.numeric(par) || is.null(names(par))) par <- numeric()
  estimated <- function(nm) nm %in% names(par) && is.finite(par[[nm]])
  report <- fit$report

  Linf <- report$Linf; vbk <- report$vbk; t0 <- report$t0
  age <- fit$age; border <- fit$len_border
  if (one(Linf) && one(vbk) && one(t0) && is.numeric(age) && length(age) && is.finite(age[1L]) &&
      is.numeric(border) && length(border) >= 2L && all(is.finite(border[1:2]))) {
    recruit <- Linf * (1 - exp(-vbk * (age[1L] - t0)))
    width <- border[2L] - border[1L]
    limit <- border[1L] - th$recruit_length_bins * width
    if (is.finite(recruit) && recruit < limit)
      add("recruit_length", "Linf, vbk, t0", recruit, limit, sprintf(paste0(
        "The mean length of recruits (rec.age = %s) is %s, more than %s length-bin width%s (%s) below the lower ",
        "border of the second length bin (%s), in the length units of the data. Check that rec.age is the age ",
        "of the smallest fish in the survey index, and the growth parameters (Linf = %s, k = %s per year, ",
        "t0 = %s years)."),
        number(age[1L]), number(recruit), number(th$recruit_length_bins),
        if (th$recruit_length_bins == 1) "" else "s", number(width), number(border[1L]),
        number(Linf), number(vbk), number(t0)))
  }

  for (nm in intersect(c("log_std_index", "log_sigma_index"), names(par))) {
    if (!estimated(nm) || exp(par[[nm]]) <= th$observation_sd) next
    add("observation_sd", nm, exp(par[[nm]]), th$observation_sd, sprintf(paste0(
      "The standard deviation of the observation error on the log scale is estimated at %s (%s), above %s. ",
      "With an observation error this large the predicted survey index is far from the observed index. ",
      "Inspect the residuals (plot_residuals(), check_fit()) and review the settings for growth and survey ",
      "catchability."),
      number(exp(par[[nm]])), nm, number(th$observation_sd)))
  }

  cv_text <- c(log_cv_len = "cv_len, the coefficient of variation of length at age,",
               log_cv_grow = "cv_grow, the coefficient of variation of the growth increment,")
  for (nm in names(cv_text)) {
    if (!estimated(nm) || exp(par[[nm]]) <= th$growth_cv) next
    add("growth_cv", nm, exp(par[[nm]]), th$growth_cv, sprintf(paste0(
      "%s is estimated at %s (%s), above %s. %s Compare the fitted length at age with age data, or fix %s ",
      "with map at a value from age data."),
      cv_text[[nm]], number(exp(par[[nm]])), nm, number(th$growth_cv),
      if (nm == "log_cv_len") sprintf("The example range in the Stock Synthesis manual is %s to %s.",
        format(th$growth_cv_reference[1L], nsmall = 2), format(th$growth_cv_reference[2L], nsmall = 2)) else
        "No published range is known for this parameter.", nm))
  }

  M <- .acl_fit_M(fit)
  if (estimated("log_init_Z") && !is.null(M)) {
    init_Z <- exp(par[["log_init_Z"]]); lowest <- min(M)
    if (init_Z < lowest)
      add("initial_Z", "log_init_Z", init_Z, lowest, sprintf(paste0(
        "The initial total mortality rate is estimated at %s per time step (log_init_Z), below the %snatural ",
        "mortality rate M = %s. The numbers at age in the first period then decline with age more slowly than ",
        "natural mortality alone would give. Check M, the survey catchability and whether recruitment ",
        "increased before the first period."),
        number(init_Z), if (length(M) > 1L) "smallest " else "", number(lowest)))
  }
  rownames(out) <- NULL
  out
}

# Notes about default behaviour are given once per user call: a function that
# runs several fits in this process opens a batch with .acl_notes_begin(),
# and the fits after the first one that shows a note stay quiet about it
# until .acl_notes_end() closes the batch. Three notes use this: a single
# start can stop at a local optimum (.acl_single_start_note()), a structure
# that changes only some of the four settings of the set "von_bertalanffy"
# (.acl_partial_set_note()), and the default start of mean_log_R moved by
# survey_q_age (.acl_q_age_start_note()). A fourth note names supplied
# correlation starts under correlation_range = "symmetric"
# (.acl_symmetric_start_note()). A fifth note gives the t0 that the start of
# log_t0 means under t0_lower (.acl_t0_lower_start_note()). A sixth note names
# the stored parameter values that a parameters list of the call replaces
# (.acl_replaced_parameters_note()).
.acl_notes <- new.env(parent = emptyenv())

.acl_notes_reset <- function()
  .acl_notes$single_start <- .acl_notes$partial_set <- .acl_notes$q_age_start <-
    .acl_notes$symmetric_start <- .acl_notes$t0_lower_start <- .acl_notes$replaced_parameters <- FALSE

.acl_notes_begin <- function() {
  depth <- if (is.null(.acl_notes$depth)) 0L else .acl_notes$depth
  if (depth == 0L) .acl_notes_reset()
  .acl_notes$depth <- depth + 1L
  invisible(NULL)
}

.acl_notes_end <- function() {
  depth <- if (is.null(.acl_notes$depth)) 0L else .acl_notes$depth
  .acl_notes$depth <- max(0L, depth - 1L)
  if (.acl_notes$depth == 0L) .acl_notes_reset()
  invisible(NULL)
}

.acl_single_start_note <- function(nstarts, silent) {
  if (isTRUE(silent) || !isTRUE(nstarts == 1L)) return(invisible(FALSE))
  in_batch <- isTRUE(.acl_notes$depth > 0L)
  if (in_batch && isTRUE(.acl_notes$single_start)) return(invisible(FALSE))
  if (in_batch) .acl_notes$single_start <- TRUE
  message("One start was used (nstarts = 1). A single start can stop at a local optimum that passes ",
          "every numerical check. For results that will be reported, use at least three starts with a wider ",
          "spread of the starting values, for example nstarts = 3 and start_spread = 0.5, and compare the ",
          "objectives in start_diagnostics.")
  invisible(TRUE)
}

# The shift of the default start of mean_log_R by -log(survey_q_age[1]),
# from the arguments of a fit: NULL when survey_q_age is not supplied or
# parameters holds a start for mean_log_R. Used for fits that run on socket
# workers or silently, whose own note does not reach the user.
.acl_q_age_start_shift <- function(args) {
  q_age <- args$survey_q_age
  if (!is.numeric(q_age) || !length(q_age) || !is.finite(q_age[1L]) || q_age[1L] <= 0 ||
      !is.null(args$parameters[["mean_log_R"]])) return(NULL)
  -log(q_age[1L])
}

# The note on the default start of mean_log_R with survey_q_age: once per
# fit, and once per batch of fits (see .acl_notes_begin()). No note when the
# shift is zero (survey_q_age[1] = 1).
.acl_q_age_start_note <- function(shift, q_age, silent) {
  if (isTRUE(silent) || !is.numeric(shift) || length(shift) != 1L || !is.finite(shift) || shift == 0)
    return(invisible(FALSE))
  in_batch <- isTRUE(.acl_notes$depth > 0L)
  if (in_batch && isTRUE(.acl_notes$q_age_start)) return(invisible(FALSE))
  if (in_batch) .acl_notes$q_age_start <- TRUE
  message("The default start of mean_log_R was changed by -log(survey_q_age[1]) = ", format(signif(shift, 4)),
          " (survey_q_age[1] = ", format(signif(q_age[1L], 4)), "), because the survey sees only that fraction ",
          "of the recruits. To use another start, supply it as parameters$mean_log_R.")
  invisible(TRUE)
}

# Supplied starts of the correlation parameters (logit_*) when the structure
# uses correlation_range = "symmetric": a value x then means the correlation
# 2 * plogis(x) - 1, not plogis(x). Default starts are converted to keep their
# value; supplied ones are not, so a start written for the default range
# changes meaning (YTF_example fixes logit_log_R = qlogis(0.1), which becomes
# a correlation of -0.8). NULL when there is none.
.acl_symmetric_supplied <- function(structure, parameters, model) {
  choices <- tryCatch(.acl_structure(structure, model)$choices, error = function(e) NULL)
  if (!identical(choices$correlation_range, "symmetric") || !is.list(parameters)) return(NULL)
  names <- grep("^logit_", names(parameters), value = TRUE)
  values <- vapply(names, function(nm) {
    x <- parameters[[nm]]
    if (is.numeric(x) && length(x) == 1L && is.finite(x)) as.numeric(x) else NA_real_
  }, numeric(1))
  values <- values[is.finite(values)]
  if (length(values)) values else NULL
}

.acl_symmetric_start_note <- function(values, silent) {
  if (isTRUE(silent) || !length(values)) return(invisible(FALSE))
  in_batch <- isTRUE(.acl_notes$depth > 0L)
  if (in_batch && isTRUE(.acl_notes$symmetric_start)) return(invisible(FALSE))
  if (in_batch) .acl_notes$symmetric_start <- TRUE
  read <- vapply(names(values), function(nm)
    paste0(nm, " = ", format(signif(values[[nm]], 4)), " is a correlation of ",
           format(round(2 * stats::plogis(values[[nm]]) - 1, 3)), " (",
           format(round(stats::plogis(values[[nm]]), 3)), " under the default range)"), character(1))
  message("With correlation_range = \"symmetric\" a supplied start x of a correlation parameter means the ",
          "correlation 2 * plogis(x) - 1: ", paste(read, collapse = "; "),
          ". To use a correlation rho, set the value to qlogis((rho + 1) / 2) in the parameters list that ",
          "the fit uses. A parameters list in the call replaces the stored list of a bundle, so change the ",
          "value in the stored list or pass the complete list.")
  invisible(TRUE)
}

# The start of log_t0 of an ALSCL fit with t0_lower different from 0, where
# t0 = t0_lower + exp(log_t0). A supplied start x is not converted, so it
# means t0 = t0_lower + exp(x) (YTF_example fixes log_t0 = log(1/60), which
# becomes t0 = -0.983 years with t0_lower = -1). The default start is
# converted to keep the default t0 (1/60 year, the start of
# create_parameters()) when that t0 is above t0_lower; otherwise it means
# t0 = t0_lower + 1/60. Returns c(t0_lower, log_t0) with
# log_t0 = NA for the default start that cannot be converted, or NULL when
# there is nothing to report.
.acl_t0_lower_start <- function(t0_lower, parameters, model) {
  if (toupper(model) != "ALSCL" || !is.numeric(t0_lower) || length(t0_lower) != 1L ||
      !is.finite(t0_lower) || t0_lower == 0) return(NULL)
  x <- if (is.list(parameters)) parameters[["log_t0"]]
  if (is.null(x)) {
    if (1 / 60 > t0_lower) return(NULL)
    return(c(t0_lower = t0_lower, log_t0 = NA_real_))
  }
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x)) return(NULL)
  c(t0_lower = t0_lower, log_t0 = as.numeric(x))
}

.acl_t0_lower_start_note <- function(start, silent) {
  if (isTRUE(silent) || length(start) != 2L) return(invisible(FALSE))
  in_batch <- isTRUE(.acl_notes$depth > 0L)
  if (in_batch && isTRUE(.acl_notes$t0_lower_start)) return(invisible(FALSE))
  if (in_batch) .acl_notes$t0_lower_start <- TRUE
  number <- function(x) format(signif(x, 4))
  lower <- start[["t0_lower"]]; x <- start[["log_t0"]]
  if (is.na(x)) {
    message("With t0_lower = ", number(lower), " the default start of log_t0 means t0 = t0_lower + 1/60 = ",
            number(lower + 1 / 60), " years, because the default t0 of 1/60 year is not above t0_lower. ",
            "To use another t0, supply parameters$log_t0 = log(t0 - t0_lower).")
  } else {
    message("With t0_lower = ", number(lower), " the supplied start log_t0 = ", number(x),
            " means t0 = t0_lower + exp(log_t0) = ", number(lower + exp(x)), " years. With t0_lower = 0 ",
            "it means t0 = ", number(exp(x)), " years. To keep a t0, supply log_t0 = log(t0 - t0_lower).")
  }
  invisible(TRUE)
}

# The note on stored parameter values that a parameters list of the call
# replaces (see .acl_replaced_parameters()). `stored` is the expression of the
# stored list for the advice, for example "x$fit_config$alscl$parameters",
# or NULL; `source` names where the replacing list comes from.
.acl_replaced_parameters_note <- function(replaced, silent, stored = NULL, source = "the call") {
  if (isTRUE(silent) || !length(replaced$dropped)) return(invisible(FALSE))
  in_batch <- isTRUE(.acl_notes$depth > 0L)
  if (in_batch && isTRUE(.acl_notes$replaced_parameters)) return(invisible(FALSE))
  if (in_batch) .acl_notes$replaced_parameters <- TRUE
  fixed <- replaced$fixed
  message("The parameters list of ", source, " replaces the stored list, so the stored values of ",
          .acl_word_list(replaced$dropped), " are no longer used.",
          if (length(fixed) > 1L && setequal(fixed, replaced$dropped))
            " The map still fixes all of them, now at their default values." else if (length(fixed))
            paste0(" The map still fixes ", .acl_word_list(fixed), ", now at ",
                   if (length(fixed) == 1L) "its default value." else "their default values."),
          if (is.null(stored)) " To change single values and keep the others, pass the complete list, for example built with utils::modifyList()." else
            paste0(" To change single values and keep the others, supply parameters = utils::modifyList(",
                   stored, ", list(...)) or edit the stored list."))
  invisible(TRUE)
}

# The four ALSCL settings of the set "von_bertalanffy" were tested together.
# For a structure that changes one, two or three of them from their original
# values, return the settings that keep their original values; otherwise
# character(0). A list that names the set and replaces single settings,
# for example list(set = "von_bertalanffy", growth_transition = "midpoint"),
# is a deliberate departure from the set and also gives character(0).
# `correlation_range` does not belong to the set. ACL has one of the four
# settings only, so no ACL structure is a part of the set.
.acl_partial_set <- function(structure, model = "ALSCL") {
  if (toupper(model) != "ALSCL") return(character())
  if (is.list(structure) && identical(.acl_structure_set_name(structure[["set"]]), "von_bertalanffy"))
    return(character())
  choices <- tryCatch(.acl_structure(structure, "ALSCL")$choices, error = function(e) NULL)
  if (is.null(choices)) return(character())
  settings <- names(.acl_structure_sets$von_bertalanffy)
  original <- vapply(settings, function(nm) identical(choices[[nm]], .acl_structure_choices[[nm]][1L]), logical(1))
  if (all(original) || !any(original)) character() else settings[original]
}

# "a", "a and b" or "a, b and c".
.acl_word_list <- function(x) {
  if (length(x) < 2L) return(paste(x))
  paste(paste(x[-length(x)], collapse = ", "), "and", x[length(x)])
}

# The note for a part of the set "von_bertalanffy": once per fit, and once
# per batch of fits (see .acl_notes_begin()).
.acl_partial_set_note <- function(structure, model, silent) {
  if (isTRUE(silent)) return(invisible(FALSE))
  kept <- .acl_partial_set(structure, model)
  if (!length(kept)) return(invisible(FALSE))
  in_batch <- isTRUE(.acl_notes$depth > 0L)
  if (in_batch && isTRUE(.acl_notes$partial_set)) return(invisible(FALSE))
  if (in_batch) .acl_notes$partial_set <- TRUE
  changed <- setdiff(names(.acl_structure_sets$von_bertalanffy), kept)
  message("The structure changes ", .acl_word_list(changed), " and leaves ", .acl_word_list(kept),
          if (length(kept) == 1L) " at its original value" else " at their original values",
          ". These four settings were tested as a set, structure = \"von_bertalanffy\", and a fit with only ",
          "some of them can fail when the growth increment in one time step is small relative to the width of ",
          "the length bins.",
          if ("growth_increment" %in% changed)
            " The value growth_increment = \"von_bertalanffy\" is one setting of the set and does not select the other three.",
          " See ?run_alscl.")
  invisible(TRUE)
}
