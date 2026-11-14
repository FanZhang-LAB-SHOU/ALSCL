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
    .acl_check_time_names(M, time, "M")
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

# Keep the first `kept` time steps of an input when the data are cut to them
# (retrospective peels and hindcast training windows). The input is M or
# survey_q. Only a matrix with one column per time step of the complete data
# is cut; other forms do not depend on time. A matrix of another width is
# returned unchanged, so that the fit reports its dimensions.
.acl_truncate_time <- function(x, periods, kept) {
  if (is.numeric(x) && length(dim(x)) == 2L && ncol(x) > 1L && ncol(x) == periods && kept < periods)
    return(x[, seq_len(kept), drop = FALSE])
  x
}

# Values of M or survey_q for the `horizon` time steps after `origin`, for a
# matrix with one column per time step of the complete data. NULL for the
# forms that do not depend on time, for which the fitted input applies.
.acl_future_time <- function(x, periods, origin, horizon) {
  if (is.numeric(x) && length(dim(x)) == 2L && ncol(x) > 1L && ncol(x) == periods)
    return(unname(x[, origin + seq_len(horizon), drop = FALSE]))
  NULL
}

# Column names of an input by time step that are numbers must be the time
# steps of the data. Names that are not numbers carry no time information.
.acl_check_time_names <- function(x, time, name) {
  labels <- colnames(x)
  if (ncol(x) < 2L || is.null(labels) || is.null(time)) return(invisible(NULL))
  supplied <- suppressWarnings(as.numeric(sub("^X", "", labels)))
  if (!all(is.finite(supplied))) return(invisible(NULL))
  differs <- which(abs(supplied - time) > 1e-8 * pmax(1, abs(time)))
  if (length(differs))
    stop("The column names of ", name, " do not match the time steps of data.CatL: column ", differs[1L],
         " is named ", labels[differs[1L]], " and the time step is ", format(time[differs[1L]]),
         ". Order the columns of ", name, " as the time columns of data.CatL, or remove its column names.",
         call. = FALSE)
  invisible(NULL)
}

# Survey catchability at length supplied directly (survey_q), in place of the
# logistic curve from sel_L50 and sel_L95. A numeric vector, or a matrix with
# one column, is survey catchability at length for every time step (form
# "length"). A matrix with one column per time step is survey catchability by
# length and time step (form "length_time").
.acl_survey_q <- function(survey_q, nlength, ntime, time = NULL) {
  expected <- paste0("survey_q must be a numeric vector with ", nlength,
    " finite positive values (one survey catchability per length bin), or a numeric matrix with ", nlength,
    " rows (one per length bin) and ", ntime, " columns (one per time step).")
  if (!is.numeric(survey_q) || length(dim(survey_q)) > 2L) stop(expected, call. = FALSE)
  by_time <- length(dim(survey_q)) == 2L && ncol(survey_q) > 1L
  if (by_time) {
    if (nrow(survey_q) != nlength || ncol(survey_q) != ntime)
      stop(expected, " It is a matrix with ", nrow(survey_q), " rows and ", ncol(survey_q), " columns.",
           if (nrow(survey_q) == ntime && ncol(survey_q) == nlength)
             " Rows are length bins, so transpose it with t()." else "", call. = FALSE)
    .acl_check_time_names(survey_q, time, "survey_q")
    value <- matrix(as.numeric(survey_q), nlength, ntime)
  } else {
    if (length(survey_q) != nlength) stop(expected, call. = FALSE)
    value <- as.numeric(survey_q)
  }
  if (any(!is.finite(value)) || any(value <= 0)) stop(expected, call. = FALSE)
  list(form = if (by_time) "length_time" else "length", q = value)
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
  q <- args$survey_q
  if (!is.null(q)) out <- c(out, paste0("survey catchability at length",
    if (length(dim(q)) == 2L && ncol(q) > 1L) " and time step" else "", " supplied as survey_q"))
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

utils::globalVariables("Curve")

#' Survey catchability at length for common shapes
#'
#' Compute survey catchability at length, the factor by which the models
#' multiply numbers at length to obtain the expected survey index, as a
#' logistic curve or as a dome-shaped curve. The result can be passed as
#' `survey_q` to [run_acl()] and [run_alscl()].
#' @param length Lengths at which survey catchability is wanted, usually the
#'   midpoints of the length bins of the model, in the unit of `L50`.
#' @param shape `"logistic"`: catchability increases with length to 1.
#'   `"dome"`: catchability increases with length, reaches 1 and decreases
#'   for larger fish.
#' @param L50,L95 Lengths at which the ascending logistic curve is 0.5 and
#'   0.95, with `L50` below `L95`. They have the meaning of `sel_L50` and
#'   `sel_L95` in [run_alscl()].
#' @param L50_desc,L95_desc Dome only. Lengths at which the descending
#'   logistic curve is 0.5 and 0.95, with `L95_desc` below `L50_desc`. The
#'   decline therefore starts near `L95_desc` and is halfway at `L50_desc`.
#'   `L50_desc` must be above `L50`.
#' @param minimum Dome only. Value between 0 and 1 (1 excluded) that the
#'   descending curve approaches for the largest lengths, before scaling. The
#'   default 0 lets catchability decline towards zero. With a positive value
#'   the descending curve is `minimum + (1 - minimum)` times the descending
#'   logistic curve, so `L50_desc` is the length halfway between 1 and
#'   `minimum`.
#' @return A numeric vector with one survey catchability per element of
#'   `length`. For `"logistic"` it holds the values that `sel_L50 = L50` and
#'   `sel_L95 = L95` give in [run_alscl()]. For `"dome"` it is the product of
#'   the ascending and the descending curve, divided by the maximum of that
#'   product over all lengths, so the curve has a maximum of 1. The largest
#'   returned value is below 1 when no element of `length` lies at the peak.
#' @details Survey catchability is an input of ACL and ALSCL. The models do
#'   not estimate it. With survey data alone its level cannot be estimated,
#'   because the survey index gives relative numbers only (Cook 2013). A
#'   decline of catchability with length cannot be estimated either, because
#'   it is confounded with mortality (Thompson 1994; Cook 2013): fewer large
#'   fish in the survey can mean that they died or that the gear does not
#'   catch them. A model that is given a logistic curve for a gear that
#'   catches large fish poorly therefore estimates a higher mortality rate.
#'   Take the shape from studies of the survey gear (for example Fraser et
#'   al. 2007 for the GOV trawl of the North Sea International Bottom Trawl
#'   Survey) or from age data, not from the fit, and report how the results
#'   change with it.
#'
#'   `survey_q` must be positive, so a dome with `minimum = 0` cannot be used
#'   when it reaches zero in double precision at the largest lengths; set a
#'   small `minimum` in that case. For a survey catchability that changes
#'   over time, for example after a change of survey gear, compute one vector
#'   per period and bind the vectors into a matrix with one column per time
#'   step (see the examples).
#' @references
#' Cook, R. M. (2013). A fish stock assessment model using survey data when
#' estimates of catch are unreliable. Fisheries Research, 143, 1-11.
#' \doi{10.1016/j.fishres.2013.01.003}
#'
#' Fraser, H. M., Greenstreet, S. P. R., and Piet, G. J. (2007). Taking
#' account of catchability in groundfish survey trawls: implications for
#' estimating demersal fish biomass. ICES Journal of Marine Science, 64,
#' 1800-1819. \doi{10.1093/icesjms/fsm145}
#'
#' Thompson, G. G. (1994). Confounding of gear selectivity and the natural
#' mortality rate in cases where the former is a nonmonotone function of
#' age. Canadian Journal of Fisheries and Aquatic Sciences, 51, 2654-2664.
#' \doi{10.1139/f94-265}
#' @seealso [run_alscl()], [plot_compare_selectivity()]
#' @examples
#' mid <- YTF_example$fit_args$len_mid
#' # The logistic curve of the example settings (sel_L50 = 15, sel_L95 = 20)
#' round(survey_catchability(mid, "logistic", L50 = 15, L95 = 20), 3)
#'
#' # A dome: the same ascending curve and a descending curve that starts to
#' # decline near 34 cm, is halfway at 42 cm and levels off at 0.2
#' dome <- survey_catchability(mid, "dome", L50 = 15, L95 = 20,
#'                             L50_desc = 42, L95_desc = 34, minimum = 0.2)
#' round(dome, 3)
#'
#' # Survey catchability by time step: the logistic curve in the first 15
#' # years and the dome in the last 5 years of the example data
#' logistic <- survey_catchability(mid, "logistic", L50 = 15, L95 = 20)
#' by_time <- cbind(matrix(logistic, length(mid), 15), matrix(dome, length(mid), 5))
#' dim(by_time)
#' @export
survey_catchability <- function(length, shape = c("logistic", "dome"), L50, L95,
                                L50_desc = NULL, L95_desc = NULL, minimum = 0) {
  shape <- match.arg(shape)
  if (!is.numeric(length) || !base::length(length) || any(!is.finite(length)))
    stop("length must contain finite lengths.", call. = FALSE)
  one <- function(x, name) {
    if (!is.numeric(x) || base::length(x) != 1L || !is.finite(x))
      stop(name, " must be one finite number.", call. = FALSE)
    x
  }
  one(L50, "L50"); one(L95, "L95"); one(minimum, "minimum")
  if (L95 <= L50) stop("L95 must be greater than L50.", call. = FALSE)
  ascending <- function(x) stats::plogis(log(19) * (x - L50) / (L95 - L50))
  if (shape == "logistic") {
    if (!is.null(L50_desc) || !is.null(L95_desc) || minimum != 0)
      stop("L50_desc, L95_desc and minimum describe the descending part of a dome; use shape = \"dome\".",
           call. = FALSE)
    return(ascending(as.numeric(length)))
  }
  if (is.null(L50_desc) || is.null(L95_desc))
    stop("shape = \"dome\" requires L50_desc and L95_desc, the lengths at which the descending curve is 0.5 and 0.95.",
         call. = FALSE)
  one(L50_desc, "L50_desc"); one(L95_desc, "L95_desc")
  if (L95_desc >= L50_desc)
    stop("L95_desc must be below L50_desc, because the descending curve is 0.95 at L95_desc and 0.5 at L50_desc.",
         call. = FALSE)
  if (L50_desc <= L50) stop("L50_desc must be greater than L50.", call. = FALSE)
  if (minimum < 0 || minimum >= 1) stop("minimum must be at least 0 and below 1.", call. = FALSE)
  descending <- function(x) minimum + (1 - minimum) *
    stats::plogis(-log(19) * (x - L50_desc) / (L50_desc - L95_desc))
  dome <- function(x) ascending(x) * descending(x)
  # Maximum of the curve over all lengths: a grid search between the two
  # curves, refined by a one-dimensional search around the best grid point.
  width <- max(L95 - L50, L50_desc - L95_desc)
  grid <- seq(L50 - 20 * width, L50_desc + 20 * width, length.out = 4001L)
  best <- which.max(dome(grid))
  around <- grid[c(max(best - 1L, 1L), min(best + 1L, 4001L))]
  peak <- max(dome(grid[best]),
              stats::optimize(dome, around, maximum = TRUE, tol = 1e-10)$objective)
  dome(as.numeric(length)) / peak
}
