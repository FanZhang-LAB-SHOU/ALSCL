# Shared input validation and bin parsing.
# Save the caller's RNG kind and seed; the returned function restores them.
.acl_preserve_rng <- function() {
  previous_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  previous_seed <- if (had_seed) get(".Random.seed", envir = .GlobalEnv)
  function() {
    do.call(RNGkind, as.list(previous_kind))
    if (had_seed) assign(".Random.seed", previous_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }
}
.acl_check_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x))
    stop(name, " must be TRUE or FALSE.", call. = FALSE)
  invisible(x)
}
.acl_positive_integer <- function(x, name, minimum = 1L) {
  if (length(x) != 1L || !is.numeric(x) || !is.finite(x) || x != floor(x) || x < minimum || x > .Machine$integer.max)
    stop(name, " must be an integer >= ", minimum, call. = FALSE)
  as.integer(x)
}
.acl_scalar <- function(x, name, lower = -Inf, strict = FALSE) {
  if (length(x) != 1L || !is.numeric(x) || !is.finite(x) ||
      (if (strict) x <= lower else x < lower))
    stop(name, " must be finite and ", if (strict) "> " else ">= ", lower, call. = FALSE)
  x
}

# Convert each time column separately. Converting a mixed-type data frame to a
# character matrix first formats its numeric columns using getOption("digits")
# and can silently alter observations, weights and maturity before fitting.
.acl_numeric_matrix <- function(x, invalid_message) {
  columns <- lapply(x, function(value) {
    if (!is.atomic(value) || !is.null(dim(value)) || is.complex(value))
      stop(invalid_message, call. = FALSE)
    original <- value
    if (is.factor(value)) value <- as.character(value)
    # TRUE/FALSE are not observations; only an all-missing logical column is accepted.
    if (is.logical(value) && any(!is.na(value))) stop(invalid_message, call. = FALSE)
    if (!is.numeric(value) && !is.logical(value)) value <- as.character(value)
    value <- suppressWarnings(as.numeric(value))
    if (any(is.na(value) & !is.na(original)))
      stop(invalid_message, call. = FALSE)
    value
  })
  matrix(unlist(columns, use.names = FALSE), nrow = nrow(x), ncol = ncol(x),
         dimnames = list(NULL, names(x)))
}

.acl_length_number_pattern <- "[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?"
.acl_length_interval_pattern <- paste0("^(", .acl_length_number_pattern, ")\\s*-\\s*(", .acl_length_number_pattern, ")$")

.acl_length_bins <- function(labels, len_mid = NULL, len_border = NULL,
                             len_lower = NULL, len_upper = NULL) {
  labels <- trimws(as.character(labels)); n <- length(labels)
  if (n < 2L || anyNA(labels) || anyDuplicated(labels)) stop("At least two distinct length bins are required.", call. = FALSE)
  number <- .acl_length_number_pattern
  single <- grepl(paste0("^", number, "$"), labels, perl = TRUE)
  lower <- upper <- mid <- rep(NA_real_, n)
  if (all(single)) {
    mid <- as.numeric(labels)
    edges <- (mid[-n] + mid[-1L]) / 2
    if (is.null(len_border) && n > 2L && diff(range(diff(mid))) > 1e-8 * max(abs(mid)))
      warning("Length labels are single numbers with unequal spacing, and len_border is not supplied. ",
              "Boundaries were set halfway between adjacent labels, which is correct only for equal-width bins. ",
              "Supply len_border, or use interval labels such as \"20-25\".", call. = FALSE)
    lower <- c(-Inf, edges); upper <- c(edges, Inf)
  } else {
    for (i in seq_len(n)) {
      s <- labels[i]
      if (grepl(paste0("^<\\s*", number, "$"), s, perl = TRUE) && i == 1L) {
        lower[i] <- -Inf; upper[i] <- as.numeric(sub("^<\\s*", "", s))
      } else if (grepl(paste0("^>\\s*", number, "$"), s, perl = TRUE) && i == n) {
        lower[i] <- as.numeric(sub("^>\\s*", "", s)); upper[i] <- Inf
      } else {
        parts <- regmatches(s, regexec(.acl_length_interval_pattern, s, perl = TRUE))[[1L]]
        if (length(parts) != 3L) {
          if (is.null(len_mid) || is.null(len_border)) stop("Cannot parse length bin '", s, "'; supply len_mid and len_border.", call. = FALSE)
        } else {
          lower[i] <- as.numeric(parts[2L]); upper[i] <- as.numeric(parts[3L])
          mid[i] <- (lower[i] + upper[i]) / 2
        }
      }
    }
    if (all(!is.na(lower)) && all(!is.na(upper))) {
      if (any(upper <= lower) || any(abs(upper[-n] - lower[-1L]) > 1e-8)) stop("Length intervals must have positive widths and be contiguous.", call. = FALSE)
      if (!is.finite(mid[1L]) && n > 2L) mid[1L] <- upper[1L] - (upper[2L] - lower[2L]) / 2
      if (!is.finite(mid[n]) && n > 2L) mid[n] <- lower[n] + (upper[n-1L] - lower[n-1L]) / 2
    }
    edges <- upper[-n]
  }
  if (!is.null(len_mid)) mid <- len_mid
  if (!is.null(len_border)) edges <- len_border
  if (!is.numeric(mid) || length(mid) != n || any(!is.finite(mid)) || any(diff(mid) <= 0)) stop("len_mid must contain one finite increasing midpoint per bin.", call. = FALSE)
  if (!is.numeric(edges) || length(edges) != n-1L || any(!is.finite(edges)) || any(diff(edges) <= 0)) stop("len_border must contain nbin - 1 finite increasing boundaries.", call. = FALSE)
  lower <- if (is.null(len_lower)) c(-Inf, edges) else len_lower
  upper <- if (is.null(len_upper)) c(edges, Inf) else len_upper
  if (!is.numeric(lower) || !is.numeric(upper) || length(lower) != n || length(upper) != n ||
      anyNA(lower) || anyNA(upper) || any(lower >= upper) || any(mid <= lower | mid >= upper) ||
      any(!is.finite(lower[-1L])) || any(!is.finite(upper[-n])) ||
      any(abs(lower[-1L] - edges) > 1e-8) || any(abs(upper[-n] - edges) > 1e-8))
    stop("Length bounds must contain the midpoints and agree with len_border.", call. = FALSE)
  # The likelihood and growth transition absorb both distribution tails. Do
  # not silently reinterpret an explicit finite truncation as an open bin.
  if (is.finite(lower[1L]) || is.finite(upper[n]))
    stop("Finite outer length bounds are not supported: the first and last bins absorb the distribution tails. ",
         "Use len_lower[1] = -Inf and len_upper[length(len_upper)] = Inf, ",
         "or leave len_lower and len_upper as NULL for the default open-ended bins.", call. = FALSE)
  list(mid = as.numeric(mid), border = as.numeric(edges), lower = c(-Inf, edges),
       upper = c(edges, Inf), labels = labels)
}
.acl_prepare_data <- function(data.CatL, data.wgt, data.mat, rec.age, nage, M,
                              sel_L50 = NULL, sel_L95 = NULL, growth_step = NULL,
                              len_mid = NULL, len_border = NULL, len_lower = NULL,
                              len_upper = NULL, zero_action = c("missing", "error"),
                              structure = list(), start_spread = 0.15, t0_lower = 0,
                              survey_q = NULL, survey_q_age = NULL,
                              bounds = c("default", "wide")) {
  zero_action <- match.arg(zero_action)
  bounds <- match.arg(bounds)
  nage <- .acl_positive_integer(nage, "nage", 2L)
  rec.age <- .acl_scalar(rec.age, "rec.age", 0, TRUE)
  # A single number is the constant natural mortality rate. The other forms
  # (see .acl_M_input) are checked below, once the data dimensions are known.
  M_single <- is.null(M) || (is.atomic(M) && length(M) == 1L)
  if (M_single) M <- .acl_scalar(M, "M", 0)
  if (is.null(growth_step)) growth_step <- if (rec.age < 1) rec.age else 1
  growth_step <- .acl_scalar(growth_step, "growth_step", 0, TRUE)
  if (is.null(survey_q)) {
    if (is.null(sel_L50) || is.null(sel_L95))
      stop("sel_L50 and sel_L95 are required unless survey catchability at length is supplied as survey_q.",
           call. = FALSE)
    .acl_scalar(sel_L50, "sel_L50"); .acl_scalar(sel_L95, "sel_L95")
    if (sel_L95 <= sel_L50) stop("sel_L95 must be greater than sel_L50.", call. = FALSE)
  } else if (!is.null(sel_L50) || !is.null(sel_L95)) {
    stop("survey_q replaces the logistic survey catchability curve, so it cannot be combined with sel_L50 or sel_L95. ",
         "Supply either survey_q or both sel_L50 and sel_L95. When an input bundle or a stored fit already holds ",
         "sel_L50 and sel_L95, add sel_L50 = NULL and sel_L95 = NULL to the call.", call. = FALSE)
  }
  frames <- list(data.CatL = data.CatL, data.wgt = data.wgt, data.mat = data.mat)
  if (any(vapply(frames, function(x) length(dim(x)) != 2L || ncol(x) < 3L || nrow(x) < 2L, logical(1)))) stop("Inputs require a length-label column, at least two time columns and two length bins.", call. = FALSE)
  frames <- lapply(frames, as.data.frame, stringsAsFactors = FALSE); catl <- frames$data.CatL
  if (anyDuplicated(names(catl)[-1L])) stop("Time column names must be unique.", call. = FALSE)
  for (nm in names(frames)[-1L]) {
    x <- frames[[nm]]
    if (!identical(dim(x), dim(catl)) || !identical(as.character(x[[1L]]), as.character(catl[[1L]])) || !identical(names(x)[-1L], names(catl)[-1L])) stop(nm, " must match data.CatL length labels and time columns, including order.", call. = FALSE)
  }
  numeric_matrix <- function(x, name) {
    .acl_numeric_matrix(x[-1L], paste0(name, " contains nonnumeric observations; real values are required."))
  }
  obs <- numeric_matrix(catl, "data.CatL"); weight <- numeric_matrix(frames$data.wgt, "data.wgt"); mat <- numeric_matrix(frames$data.mat, "data.mat")
  if (any(is.infinite(obs)) || any(obs < 0, na.rm = TRUE)) stop("Survey indices must be nonnegative and finite, or NA for missing observations.", call. = FALSE)
  if (zero_action == "error" && any(obs == 0, na.rm = TRUE)) stop("Zero observations are incompatible with the lognormal observation model.", call. = FALSE)
  if (any(!is.finite(weight)) || any(weight < 0)) stop("Weights must be finite and nonnegative.", call. = FALSE)
  if (any(!is.finite(mat)) || any(mat < 0 | mat > 1)) stop("Maturity must be finite and in [0, 1].", call. = FALSE)
  observed <- !is.na(obs) & obs > 0
  if (!any(observed)) stop("At least one positive survey observation is required.", call. = FALSE)
  log_obs <- matrix(0, nrow(obs), ncol(obs), dimnames = dimnames(obs)); log_obs[observed] <- log(obs[observed])
  bins <- .acl_length_bins(catl[[1L]], len_mid, len_border, len_lower, len_upper)
  years <- suppressWarnings(as.numeric(sub("^X", "", names(catl)[-1L])))
  if (any(!is.finite(years)) || any(diff(years) <= 0)) stop("Time columns must have increasing numeric labels (decimal years are supported).", call. = FALSE)
  if (any(abs(diff(years) - growth_step) > 1e-8 * max(1, growth_step)))
    stop("Time column spacing must equal growth_step (", growth_step,
         " years). Include every model period; use NA survey observations for missing periods,",
         " and provide weights and maturity for the complete time grid.", call. = FALSE)
  supplied_q <- if (is.null(survey_q)) NULL else .acl_survey_q(survey_q, nrow(obs), ncol(obs), years)
  # With survey catchability by length and time step the templates read
  # log_q_LY (added below); log_q then holds the first time step.
  log_q <- if (is.null(survey_q))
    stats::plogis(log(19) * (bins$mid - sel_L50) / (sel_L95 - sel_L50), log.p = TRUE) else
    if (supplied_q$form == "length") log(supplied_q$q) else log(supplied_q$q[, 1L])
  data <- list(logN_at_len = log_obs, na_matrix = observed * 1, log_q = log_q,
               len_border = bins$border, age = rec.age + seq.int(0L, nage-1L) * growth_step,
               Y = ncol(obs), A = nage, L = nrow(obs), weight = weight, mat = mat, M = M)
  out <- list(data = data,
       bins = bins, year = years, growth_step = growth_step, observations = obs, data.CatL = catl,
       structure = structure, start_spread = start_spread, t0_lower = t0_lower,
       zero_observations = sum(obs == 0, na.rm = TRUE), bounds = bounds)
  # The entries below exist only for the non-default input forms, so the
  # prepared input of a default fit is the same as in earlier versions.
  if (!M_single) {
    out$natural_mortality <- .acl_M_input(M, nage, nrow(obs), ncol(obs), years)
    # The templates still read the single number M; with a non-scalar M it is
    # used only for the default start of init_Z.
    out$data$M <- .acl_M_summary(out$natural_mortality)
  }
  if (!is.null(survey_q_age)) out$data$q_age <- .acl_survey_q_age(survey_q_age, nage)
  if (!is.null(supplied_q) && supplied_q$form == "length_time") out$data$log_q_LY <- log(supplied_q$q)
  out
}

# Optional model structures. The first choice of each setting is the original
# structure and is the default: the structure of the package as first
# released, which implements the model of Zhang and Cadigan (2022).
.acl_structure_choices <- list(
  initial_plus_group = c("single_cohort", "equilibrium"),
  initial_length = c("length_at_age", "growth"),
  growth_increment = c("logistic", "von_bertalanffy"),
  growth_transition = c("midpoint", "bin"),
  correlation_range = c("positive", "symmetric"),
  initial_deviations = c("cumulative", "independent"))

# Settings that apply to ACL as well as ALSCL.
.acl_structure_acl <- c("initial_plus_group", "correlation_range", "initial_deviations")

# Settings that a fit stores only when they differ from the default, so that
# the stored structure of a default fit is the same as in earlier versions.
.acl_structure_stored_if_set <- "initial_deviations"

# Named sets of settings. "original" is the structure of the package as first
# released, the implementation of the model of Zhang and Cadigan (2022). Two
# details of its growth increment are in the code and not in the paper: the
# constants l50 = 0.5 Linf and l95 = 0.05 Linf of the logistic function, and
# the multiplication of the increment by the length of the time step.
# "von_bertalanffy" holds the four ALSCL settings that are used together: the
# von Bertalanffy growth increment, transition probabilities integrated over
# each length bin, a length distribution of the first period generated by the
# growth model, and an equilibrium plus group in the first period.
.acl_structure_sets <- list(
  original = list(),
  von_bertalanffy = list(initial_plus_group = "equilibrium", initial_length = "growth",
                         growth_increment = "von_bertalanffy", growth_transition = "bin"))

# Earlier names of the sets. They are accepted with the same effect and
# without a message, so that existing scripts keep working.
.acl_structure_set_aliases <- c(published = "original", consistent = "von_bertalanffy")

# The current name of a set, or NA when `name` is not the name of a set.
.acl_structure_set_name <- function(name) {
  if (!is.character(name) || length(name) != 1L || is.na(name)) return(NA_character_)
  if (name %in% names(.acl_structure_set_aliases)) name <- .acl_structure_set_aliases[[name]]
  if (name %in% names(.acl_structure_sets)) name else NA_character_
}

# Expand a set name, or a list with a `set` element, to a plain list of
# settings. Settings given next to `set` replace those of the set. ACL keeps
# the settings of a set that apply to it.
.acl_structure_expand <- function(structure, model = "ALSCL") {
  if (is.null(structure)) return(list())
  pick <- function(name, label) {
    name <- .acl_structure_set_name(name)
    if (is.na(name))
      stop(label, " must be \"original\" or \"von_bertalanffy\" (the name of a set); use a named list for ",
           "single settings, for example list(correlation_range = \"symmetric\").", call. = FALSE)
    set <- .acl_structure_sets[[name]]
    if (toupper(model) == "ACL") set <- set[intersect(names(set), .acl_structure_acl)]
    set
  }
  if (is.character(structure)) return(pick(structure, "A character structure"))
  if (is.list(structure) && !is.data.frame(structure) && "set" %in% names(structure)) {
    if (sum(names(structure) == "set") > 1L) stop("structure has more than one `set` element.", call. = FALSE)
    set <- pick(structure$set, "structure$set")
    extra <- structure[names(structure) != "set"]
    return(c(set[setdiff(names(set), names(extra))], extra))
  }
  structure
}

# Settings that decide how optimizer-scale values map to natural values:
# whether AR(1) correlations lie between -1 and 1, and the lower limit of the
# ALSCL t0. `x` is a fit, a recipe argument list or a prepared input.
.acl_scale_settings <- function(x = NULL) {
  structure <- x$structure
  if (is.null(structure)) structure <- x$recipe$args$structure
  structure <- tryCatch(.acl_structure_expand(structure), error = function(e) list())
  t0_lower <- x$t0_lower
  if (is.null(t0_lower)) t0_lower <- x$recipe$args$t0_lower
  if (is.null(t0_lower)) t0_lower <- 0
  list(symmetric = identical(structure$correlation_range, "symmetric"), t0_lower = t0_lower)
}

# Validate a structure list for one model. Returns the complete named choices
# and the data entries passed to the template (non-default settings only, so a
# default fit passes exactly the same data as earlier versions).
.acl_structure <- function(structure = list(), model = "ALSCL") {
  model <- toupper(model)
  structure <- .acl_structure_expand(structure, model)
  available <- if (model == "ACL") .acl_structure_acl else names(.acl_structure_choices)
  if (!is.list(structure) || is.data.frame(structure) || (length(structure) &&
      (is.null(names(structure)) || anyNA(names(structure)) || any(!nzchar(names(structure))) ||
       anyDuplicated(names(structure)))))
    stop("structure must be \"original\", \"von_bertalanffy\" or a named list, for example ",
         "list(set = \"von_bertalanffy\", correlation_range = \"symmetric\").", call. = FALSE)
  unknown <- setdiff(names(structure), names(.acl_structure_choices))
  if (length(unknown))
    stop("Unknown structure setting: ", paste(unknown, collapse = ", "), ". Available settings: ",
         paste(names(.acl_structure_choices), collapse = ", "), ".", call. = FALSE)
  choices <- lapply(.acl_structure_choices[available], `[`, 1L)
  for (nm in names(structure)) {
    value <- structure[[nm]]
    allowed <- .acl_structure_choices[[nm]]
    if (!is.character(value) || length(value) != 1L || is.na(value) || !value %in% allowed)
      stop("structure$", nm, " must be one of: ", paste0("\"", allowed, "\"", collapse = ", "), ".", call. = FALSE)
    if (!nm %in% available) {
      if (value != allowed[1L])
        stop("structure$", nm, " applies to ALSCL only; ACL has no growth transition matrix.", call. = FALSE)
      next
    }
    choices[[nm]] <- value
  }
  codes <- vapply(names(choices), function(nm) match(choices[[nm]], .acl_structure_choices[[nm]]) - 1L, integer(1))
  unset <- names(codes)[codes == 0L & names(codes) %in% .acl_structure_stored_if_set]
  list(choices = choices[setdiff(names(choices), unset)], data = as.list(codes[codes > 0L]))
}

# The form of the deviations of the initial numbers at age in a list of
# structure choices. Fits with the default form and fits of earlier versions
# do not store the setting.
.acl_initial_deviations <- function(choices) {
  value <- choices$initial_deviations
  if (is.null(value)) .acl_structure_choices$initial_deviations[1L] else value
}

# Number of deviations of the initial numbers at age: A - 1 (all ages but the
# first) with cumulative deviations, A with independent deviations.
.acl_initial_deviation_count <- function(choices, nage)
  if (.acl_initial_deviations(choices) == "independent") nage else nage - 1L
.acl_observed_log <- function(model_result) {
  observed <- model_result$observations
  if (!is.null(observed)) {
    observed <- as.matrix(observed)
    if (!is.numeric(observed) || length(dim(observed)) != 2L ||
        any(is.infinite(observed)) || any(observed < 0, na.rm = TRUE))
      stop("Stored observations must be a numeric matrix of nonnegative values or NA.", call. = FALSE)
    z <- matrix(NA_real_, nrow(observed), ncol(observed), dimnames = dimnames(observed))
    valid <- is.finite(observed) & observed > 0
    z[valid] <- log(observed[valid])
    return(z)
  }
  # Older fitted objects store observations and their mask in the TMB data.
  d <- model_result$obj$env$.data
  z <- d$logN_at_len
  if (is.null(z))
    stop("Observed data are unavailable; retain model_result$observations when saving a fit.", call. = FALSE)
  if (!is.numeric(z) || length(dim(z)) != 2L)
    stop("Stored log observations must be a numeric matrix.", call. = FALSE)
  if (!is.null(d$na_matrix)) {
    if (!identical(dim(d$na_matrix), dim(z)))
      stop("The observation mask dimensions differ from the stored observations.", call. = FALSE)
    z[!is.finite(d$na_matrix) | d$na_matrix == 0] <- NA_real_
  }
  z[!is.finite(z)] <- NA_real_
  z
}
