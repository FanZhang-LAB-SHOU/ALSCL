# Forms of the natural mortality rate (M) and of survey catchability that
# run_acl() and run_alscl() accept, and their expansion to the data entries of
# the model templates.
#
# M has three forms:
#   "scalar"    a single number, the constant rate of the published models;
#   "age_time"  a matrix with one row per age class and one column per time
#               step, or one column that is used for every time step;
#   "length"    a numeric vector with one value per length bin (ALSCL only).
# The `dim` attribute alone separates the last two forms: an object with two
# dimensions is M by age, also when it has one column, and a numeric vector
# without dimensions is M by length. A one-column matrix with as many rows as
# there are length bins is therefore still M by age.

.acl_M_forms_text <- function(nage, nlength, ntime)
  paste0("a single number; a numeric matrix with ", nage, " rows (one per age class) and ", ntime,
         " columns (one per time step) or one column; or a numeric vector with ", nlength,
         " values (one per length bin, ALSCL only)")

# Validate M against the dimensions of the data. Returns the form and M in a
# standard shape: the number, an age-by-time matrix, or the vector by length.
.acl_M_input <- function(M, nage, nlength, ntime, time = NULL) {
  if (is.data.frame(M) || !is.numeric(M) || length(dim(M)) > 2L)
    stop("M must be one of: ", .acl_M_forms_text(nage, nlength, ntime), ". It is ",
         if (is.data.frame(M)) "a data frame (convert it with as.matrix())" else
           if (is.numeric(M)) paste0("an array with ", length(dim(M)), " dimensions") else
             paste0("of class ", class(M)[1L]), ".", call. = FALSE)
  if (length(M) == 1L) return(list(form = "scalar", M = .acl_scalar(M, "M", 0)))
  if (length(dim(M)) == 2L) {
    if (nrow(M) != nage || !ncol(M) %in% c(1L, ntime))
      stop("M is a matrix with ", nrow(M), " rows and ", ncol(M), " columns. A matrix is read as the natural ",
           "mortality rate by age and time step and must have ", nage, " rows (one per age class) and ",
           ntime, " columns (one per time step) or one column.",
           if (nrow(M) == ntime && ncol(M) == nage) " Rows are age classes, so transpose it with t()." else "",
           call. = FALSE)
    labels <- colnames(M)
    if (ncol(M) > 1L && !is.null(labels) && !is.null(time)) {
      supplied <- suppressWarnings(as.numeric(sub("^X", "", labels)))
      # Names that are not numbers carry no time information and are ignored.
      if (all(is.finite(supplied))) {
        differs <- which(abs(supplied - time) > 1e-8 * pmax(1, abs(time)))
        if (length(differs))
          stop("The column names of M do not match the time steps of data.CatL: column ", differs[1L],
               " is named ", labels[differs[1L]], " and the time step is ", format(time[differs[1L]]),
               ". Order the columns of M as the time columns of data.CatL, or remove its column names.",
               call. = FALSE)
      }
    }
    value <- matrix(as.numeric(M), nage, ntime)
    form <- "age_time"
  } else {
    if (length(M) != nlength)
      stop("M is a numeric vector with ", length(M), " values. A vector is read as the natural mortality ",
           "rate by length and must have ", nlength, " values (one per length bin). For the rate by age, ",
           "supply a matrix with ", nage, " rows and one column, for example matrix(M, ncol = 1).",
           call. = FALSE)
    value <- as.numeric(M)
    form <- "length"
  }
  if (any(!is.finite(value)) || any(value < 0))
    stop("M must contain finite, nonnegative values only.", call. = FALSE)
  list(form = form, M = value)
}

# One number that stands for a non-scalar M where the fitting setup needs one:
# the default start of init_Z. The median of the first time step is used.
.acl_M_summary <- function(input) {
  switch(input$form, scalar = input$M, age_time = stats::median(input$M[, 1L]),
         length = stats::median(input$M))
}

# Data entries of the templates for a non-scalar M. ACL takes M by age and
# time step (M_AY, A x Y). ALSCL takes M by length, age and time step (M_LAY,
# L x A x Y), to which both non-scalar forms are expanded.
.acl_M_data <- function(input, model, nlength, nage, ntime) {
  if (is.null(input) || input$form == "scalar") return(list())
  if (model == "ACL") {
    if (input$form == "length")
      stop("M is a numeric vector, which is read as the natural mortality rate by length. ACL does not accept ",
           "this form, because it follows numbers at age only and assigns lengths from the length-at-age distribution ",
           "in every time step. Fish therefore do not keep their length, and a rate by length cannot be applied to them. ",
           "Use run_alscl(), or supply the rate by age as a matrix with ", nage,
           " rows and one column, for example matrix(M_at_age, ncol = 1).", call. = FALSE)
    return(list(M_AY = input$M))
  }
  M_LAY <- if (input$form == "length") array(input$M, c(nlength, nage, ntime)) else
    aperm(array(input$M, c(nage, ntime, nlength)), c(3L, 1L, 2L))
  list(M_LAY = M_LAY)
}

# Keep the first `kept` time steps of M when the data are cut to them
# (retrospective peels and hindcast training windows). Only a matrix with one
# column per time step of the complete data is cut; other forms do not depend
# on time. A matrix of another width is returned unchanged, so that the fit
# reports its dimensions.
.acl_M_truncate <- function(M, periods, kept) {
  if (is.numeric(M) && length(dim(M)) == 2L && ncol(M) > 1L && ncol(M) == periods && kept < periods)
    return(M[, seq_len(kept), drop = FALSE])
  M
}

# Natural mortality rate of the `horizon` time steps after `origin`, for a
# matrix with one column per time step of the complete data. NULL for the
# forms that do not depend on time: the fitted rate then applies.
.acl_M_future <- function(M, periods, origin, horizon) {
  if (is.numeric(M) && length(dim(M)) == 2L && ncol(M) > 1L && ncol(M) == periods)
    return(unname(M[, origin + seq_len(horizon), drop = FALSE]))
  NULL
}

# Survey catchability at length supplied directly (survey_q), in place of the
# logistic curve from sel_L50 and sel_L95.
.acl_survey_q <- function(survey_q, nlength) {
  if (!is.numeric(survey_q) || length(dim(survey_q)) > 1L || length(survey_q) != nlength ||
      any(!is.finite(survey_q)) || any(survey_q <= 0))
    stop("survey_q must be a numeric vector with ", nlength,
         " finite positive values, one survey catchability per length bin.", call. = FALSE)
  as.numeric(survey_q)
}

# Survey catchability multiplier by age (survey_q_age).
.acl_survey_q_age <- function(survey_q_age, nage) {
  if (!is.numeric(survey_q_age) || length(dim(survey_q_age)) > 1L || length(survey_q_age) != nage ||
      any(!is.finite(survey_q_age)) || any(survey_q_age <= 0))
    stop("survey_q_age must be a numeric vector with ", nage,
         " finite positive values, one survey catchability multiplier per age class.", call. = FALSE)
  as.numeric(survey_q_age)
}

# Simulation functions use one natural mortality rate. Give a clear error for
# the non-scalar forms that the fitting functions accept.
.acl_single_M <- function(M, caller) {
  if (is.numeric(M) && length(M) > 1L)
    stop(caller, " uses a single natural mortality rate. M must be one nonnegative number. ",
         "A rate by age and time step (a matrix) or by length (a vector) is accepted by run_acl() ",
         "and run_alscl() only.", call. = FALSE)
  invisible(M)
}

# Short descriptions of the non-default input forms of a fit, read from its
# recipe. A fit from an earlier version has none of these entries.
.acl_input_forms <- function(fit) {
  args <- fit$recipe$args
  if (!is.list(args)) return(character())
  out <- character()
  M <- args$M
  if (is.numeric(M) && length(M) > 1L)
    out <- c(out, if (length(dim(M)) == 2L)
      paste0("natural mortality rate by age", if (ncol(M) > 1L) " and time step" else
        " (the same in every time step)") else "natural mortality rate by length")
  if (!is.null(args$survey_q)) out <- c(out, "survey catchability at length supplied as survey_q")
  if (!is.null(args$survey_q_age)) out <- c(out, "survey catchability multiplier by age (survey_q_age)")
  out
}

#' Natural mortality rate as a power function of length
#'
#' Compute a natural mortality rate (M) for each length from the rate at a
#' reference length: `M_ref * (length / L_ref)^exponent`. With the default
#' exponent of -1 the rate is inversely proportional to length. The result
#' can be passed as `M` to [run_alscl()], which reads a numeric vector with
#' one value per length bin as M by length.
#' @param length Positive lengths at which M is wanted, usually the midpoints
#'   of the length bins of the model, in the unit of `L_ref`.
#' @param M_ref Natural mortality rate at the reference length `L_ref`. For
#'   use in a model it is a rate per model time step (for quarterly time
#'   steps, the annual rate divided by 4).
#' @param L_ref Positive reference length at which M equals `M_ref`.
#' @param exponent Exponent of length. The default -1 is the value that
#'   Lorenzen (2022) and Lorenzen et al. (2022) found for the change of M
#'   with length within a population.
#' @return A numeric vector with one natural mortality rate per element of
#'   `length`, in the unit of `M_ref`.
#' @details `M_ref` is the rate at `L_ref`, not a mean over lengths. A single
#'   rate from the literature or from a maximum-age estimator usually stands
#'   for adult fish, so `L_ref` should be a length of adult fish. Take it from
#'   data outside the model, for example the mean length of mature fish from
#'   age readings. Do not use the asymptotic length (Linf) estimated by the
#'   model, because the assumed M would then depend on the fit that uses it.
#'
#'   The curve depends on `M_ref` and `L_ref` only through the product
#'   `M_ref * L_ref^(-exponent)`, so a sensitivity analysis needs to vary
#'   only one of them. With a negative exponent M at small lengths is large,
#'   so check the rates of the smallest length bins before fitting. Lorenzen
#'   (2022) describes departures from the inverse relation in early juveniles,
#'   below about 20 percent of the asymptotic length.
#'
#'   The survey index informs total mortality, not its split into fishing and
#'   natural mortality. M by length is an assumption like a single M, and
#'   the objective of a fit is not a basis for choosing between them.
#' @references
#' Lorenzen, K. (2022). Size- and age-dependent natural mortality in fish
#' populations: Biology, models, implications, and a generalized
#' length-inverse mortality paradigm. Fisheries Research, 255, 106454.
#' \doi{10.1016/j.fishres.2022.106454}
#'
#' Lorenzen, K., Camp, E. V., and Garlock, T. M. (2022). Natural mortality
#' and body size in fish populations. Fisheries Research, 252, 106327.
#' \doi{10.1016/j.fishres.2022.106327}
#' @seealso [run_alscl()]
#' @examples
#' # Length-bin midpoints of the example data (cm) and an adult M of 0.2 per
#' # year at a reference length of 40 cm
#' mid <- YTF_example$fit_args$len_mid
#' M_length <- lorenzen_M(mid, M_ref = 0.2, L_ref = 40)
#' round(M_length, 3)
#'
#' # A steeper decline with length
#' round(lorenzen_M(mid, M_ref = 0.2, L_ref = 40, exponent = -1.5), 3)
#' @export
lorenzen_M <- function(length, M_ref, L_ref, exponent = -1) {
  if (!is.numeric(length) || !base::length(length) || any(!is.finite(length)) || any(length <= 0))
    stop("length must contain finite positive lengths.", call. = FALSE)
  .acl_scalar(M_ref, "M_ref", 0)
  .acl_scalar(L_ref, "L_ref", 0, TRUE)
  if (!is.numeric(exponent) || length(exponent) != 1L || !is.finite(exponent))
    stop("exponent must be one finite number.", call. = FALSE)
  M_ref * (as.numeric(length) / L_ref)^exponent
}
