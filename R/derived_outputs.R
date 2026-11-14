# Outputs computed in R from a fitted object for comparison with age readings
# and with external assessments: mean length at age, spawning stock biomass
# from maturity at age, and relative catch. None of them enters the fit.

# Check a fitted result and return its model type and coordinates.
.acl_derived_fit <- function(fit) {
  if (!is.list(fit)) stop("fit must be a fitted ACL or ALSCL result.", call. = FALSE)
  if (is.null(fit$report) && (!is.null(fit$error) || identical(fit$converge, "FAILED"))) {
    reason <- if (is.character(fit$error) && length(fit$error) == 1L && !is.na(fit$error))
      paste0(" Fit error: ", fit$error) else ""
    stop("fit is a failed fit without estimates and cannot be used here.", reason, call. = FALSE)
  }
  if (!is.list(fit$report)) stop("fit must be a fitted ACL or ALSCL result with a report.", call. = FALSE)
  model <- .detect_model_name(fit, NA_character_)
  if (!model %in% c("ACL", "ALSCL")) stop("fit must be an ACL or ALSCL result.", call. = FALSE)
  years <- .acl_plot_year(fit, name = "fit")
  ages <- fit$age
  if (!is.numeric(ages) || !length(ages) || any(!is.finite(ages)))
    stop("fit must contain finite age metadata.", call. = FALSE)
  list(model = model, years = years, ages = as.numeric(ages))
}

# The data list that the model template received: weight and maturity at
# length by time step, and log survey catchability at length. A live fit holds
# it in its TMB object. A saved assessment has no TMB object; the list is then
# rebuilt from the stored recipe by the preparation function that fitting
# uses. NULL when neither source is available.
.acl_fit_data <- function(fit) {
  data <- fit$obj$env$data
  if (is.list(data) && is.numeric(data$log_q)) return(data)
  args <- fit$recipe$args
  if (!is.list(args)) return(NULL)
  prepared <- tryCatch(do.call(.acl_prepare_data,
    args[intersect(names(args), names(formals(.acl_prepare_data)))]),
    error = function(e) NULL)
  prepared$data
}

# Survey catchability of a fit: catchability at length and, when the fit
# stores one, a multiplier by age class (NULL otherwise). Every quantity "as
# the survey sees it" reads catchability through this function only.
.acl_survey_catchability <- function(fit) {
  data <- .acl_fit_data(fit)
  log_q <- data$log_q
  if (!is.numeric(log_q) || !length(log_q) || anyNA(log_q))
    stop("Survey catchability at length is unavailable: fit has neither a live TMB object nor a stored recipe. ",
         "Use basis = \"population\", or save the fit with save_assessment() and its inputs.", call. = FALSE)
  list(length = exp(as.numeric(log_q)), age = data$q_age)
}

# Numbers by length bin, age class and time step (L x A x Y). ALSCL reports
# this array. In ACL every age class has the same length distribution in all
# time steps, so the array is the age-length key times numbers at age.
.acl_numbers_length_age <- function(fit, info = .acl_derived_fit(fit)) {
  r <- fit$report
  A <- length(info$ages); Y <- length(info$years)
  if (info$model == "ALSCL") {
    numbers <- r$NLA
    if (!is.array(numbers) || length(dim(numbers)) != 3L || !is.numeric(numbers))
      stop("The ALSCL report must contain numbers by length, age and time step (NLA).", call. = FALSE)
  } else {
    key <- r$pla; at_age <- r[["NA"]]
    if (!is.matrix(key) || !is.numeric(key) || !is.matrix(at_age) || !is.numeric(at_age) ||
        ncol(key) != nrow(at_age))
      stop("The ACL report must contain the age-length key (pla) and numbers at age (NA).", call. = FALSE)
    numbers <- array(vapply(seq_len(ncol(at_age)), function(y)
      sweep(key, 2L, at_age[, y], "*"), key), c(nrow(key), ncol(key), ncol(at_age)))
  }
  if (!identical(dim(numbers)[2:3], c(A, Y)) || any(!is.finite(numbers)))
    stop("Numbers by length, age and time step do not match the ages and time steps of fit, or are not finite.",
         call. = FALSE)
  numbers
}

# Mean and standard deviation of length for each age class and time step
# (A x Y matrices) from numbers by length, age and time step. Each length bin
# is represented by its midpoint.
.acl_length_moments <- function(numbers, mid) {
  d <- dim(numbers)
  flat <- matrix(numbers, d[1L], d[2L] * d[3L])
  total <- colSums(flat)
  average <- colSums(flat * mid) / total
  variance <- colSums(flat * outer(mid, average, "-")^2) / total
  empty <- !is.finite(total) | total <= 0
  average[empty] <- NA_real_; variance[empty] <- NA_real_
  list(mean = matrix(average, d[2L], d[3L]), sd = matrix(sqrt(variance), d[2L], d[3L]))
}

# A x Y moments of length at age for one basis.
.acl_length_at_age <- function(fit, basis, info = .acl_derived_fit(fit)) {
  numbers <- .acl_numbers_length_age(fit, info)
  mid <- fit$len_mid
  if (!is.numeric(mid) || length(mid) != dim(numbers)[1L] || any(!is.finite(mid)))
    stop("fit must contain finite length-bin midpoints that match its report.", call. = FALSE)
  if (basis == "survey") {
    q <- .acl_survey_catchability(fit)
    if (length(q$length) != length(mid))
      stop("Survey catchability at length does not match the length bins of fit.", call. = FALSE)
    numbers <- sweep(numbers, 1L, q$length, "*")
    # A multiplier by age class scales all lengths of an age class equally: it
    # changes the survey index at age but cancels in the moments of length.
    if (!is.null(q$age)) numbers <- sweep(numbers, 2L, as.numeric(q$age), "*")
  }
  .acl_length_moments(numbers, as.numeric(mid))
}

#' Mean length at age from a fitted model
#'
#' Mean and standard deviation of length for each age class and time step of
#' a fitted ACL or ALSCL model. Two forms are given: in the population, and as
#' the survey sees it, that is, with numbers at length multiplied by the
#' survey catchability at length used in the fit.
#'
#' @param fit A fitted ACL or ALSCL result, including a saved assessment read
#'   with [read_assessment()].
#' @param basis One or both of `"survey"` (numbers at length multiplied by
#'   survey catchability at length) and `"population"` (numbers at length in
#'   the population). The default returns both.
#' @return A data frame with one row per basis, time step and age class:
#'   basis, year (the time step, as in `fit$year`), age (the age class, as in
#'   `fit$age`; the oldest age class is a plus group), mean_length and
#'   sd_length (in the length unit of the length bins) and numerical_ok (the
#'   numerical screen of the fit, the same verdict that summary() reports).
#' @details For an ALSCL fit the quantities are calculated from the estimated
#'   numbers by length bin, age class and time step (`fit$report$NLA`). For an
#'   ACL fit they are calculated from the age-length key (`fit$report$pla`, the
#'   probability of each length bin given age). ACL uses the same key in every
#'   time step, so its values do not change with time. Each length bin is
#'   represented by its midpoint, including the two open-ended outer bins.
#'   The standard deviation is that of the bin midpoints weighted by numbers
#'   and does not include the spread of lengths within a bin.
#'
#'   With `basis = "survey"`, the numbers in each length bin are multiplied by
#'   the survey catchability at length before the mean and standard deviation
#'   are calculated. Where catchability increases with length over the
#'   lengths of an age class, the small fish of that age class are
#'   under-represented in the survey catch, and mean length at age is larger
#'   than in the population. Use this basis to compare the fit with mean
#'   length at age from age readings of fish caught in the same survey.
#'
#'   Compare growth through mean length at age, not through the growth
#'   parameters. In ACL, Linf, k and t0 are the parameters of a von
#'   Bertalanffy curve of mean length at age. In ALSCL they are not. Linf and
#'   k set the mean growth increment in one time step as a function of
#'   length, and Linf, k and t0 set the mean length of recruits (and, in the
#'   published structure, of every age class in the first time step; see
#'   `structure` in [run_alscl()]). After recruitment, the lengths of a cohort
#'   follow from the growth increments and from mortality at length. Growth
#'   parameters estimated from growth increments and from age-length data
#'   have different meanings and are not directly comparable (Francis 1988).
#'   Linf, k and t0 of an ALSCL fit should therefore not be compared with
#'   those of an ACL fit or of a von Bertalanffy curve fitted to age readings.
#' @references Francis, R. I. C. C. (1988). Are growth parameters estimated
#'   from tagging and age-length data comparable? Canadian Journal of
#'   Fisheries and Aquatic Sciences 45, 936--942. \doi{10.1139/f88-115}.
#' @seealso [compare_models()], which reports mean length at age of two fits
#'   side by side; [ssb_at_age()]; [relative_catch()].
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' growth <- length_at_age(fit)
#' head(growth)
#'
#' # Mean length at age as the survey sees it, in the first time step
#' subset(growth, basis == "survey" & year == min(year))
#' }
#' @export
length_at_age <- function(fit, basis = c("survey", "population")) {
  basis <- match.arg(basis, several.ok = TRUE)
  if (anyDuplicated(basis)) stop("basis must not repeat a value.", call. = FALSE)
  info <- .acl_derived_fit(fit)
  A <- length(info$ages); Y <- length(info$years)
  numerical_ok <- .acl_numerical_ok(fit)
  rows <- lapply(basis, function(b) {
    moments <- .acl_length_at_age(fit, b, info)
    data.frame(basis = b, year = rep(info$years, each = A), age = rep(info$ages, Y),
      mean_length = as.numeric(moments$mean), sd_length = as.numeric(moments$sd),
      numerical_ok = numerical_ok, stringsAsFactors = FALSE, row.names = NULL)
  })
  do.call(rbind, rows)
}

# Mean length at age averaged over the time steps (an unweighted mean of the
# values by time step), for summaries such as compare_models().
.acl_mean_length_at_age <- function(fit, basis) {
  info <- .acl_derived_fit(fit)
  data.frame(age = info$ages, mean_length = rowMeans(.acl_length_at_age(fit, basis, info)$mean))
}

# A value by age class (vector) or by age class and time step (matrix), as an
# A x Y matrix.
.acl_age_input <- function(x, name, ages, years, upper = Inf) {
  A <- length(ages); Y <- length(years)
  shape <- paste0(name, " must be a numeric vector with one value per age class (", A,
    ") or a matrix with one row per age class and one column per time step (", A, " x ", Y, ").")
  if (is.data.frame(x)) x <- as.matrix(x)
  if (!is.numeric(x)) stop(shape, call. = FALSE)
  if (is.null(dim(x))) {
    if (length(x) != A) stop(shape, call. = FALSE)
    x <- matrix(as.numeric(x), A, Y)
  } else if (!identical(dim(x), c(A, Y))) stop(shape, call. = FALSE)
  if (any(!is.finite(x)) || any(x < 0) || any(x > upper))
    stop(name, " must be finite and ", if (is.finite(upper)) paste0("between 0 and ", upper) else "nonnegative",
         ".", call. = FALSE)
  unname(x)
}

# Mean weight at age (A x Y) of an ACL fit: weight at length averaged over
# the age-length key. NULL when the weights used in the fit are unavailable.
.acl_weight_at_age <- function(fit) {
  key <- fit$report$pla; weight <- .acl_fit_data(fit)$weight
  if (!is.matrix(key) || !is.matrix(weight) || nrow(weight) != nrow(key)) return(NULL)
  crossprod(key, weight)
}

# Biomass at age (A x Y). ALSCL reports it; for ACL it is numbers at age
# times mean weight at age. With `weight`, numbers at age times these weights.
.acl_biomass_at_age <- function(fit, weight = NULL, info = .acl_derived_fit(fit)) {
  r <- fit$report; dims <- c(length(info$ages), length(info$years))
  at_age <- r[["NA"]]
  usable <- function(x) is.matrix(x) && is.numeric(x) && identical(dim(x), dims) && all(is.finite(x))
  if (!is.null(weight)) {
    if (!usable(at_age)) stop("The report must contain numbers at age (NA) for the ages and time steps of fit.", call. = FALSE)
    return(at_age * .acl_age_input(weight, "weight", info$ages, info$years))
  }
  if (info$model == "ALSCL") {
    if (!usable(r$BA)) stop("The ALSCL report must contain biomass at age (BA) for the ages and time steps of fit.", call. = FALSE)
    return(r$BA)
  }
  mean_weight <- .acl_weight_at_age(fit)
  if (!usable(at_age) || !usable(mean_weight))
    stop("Biomass at age of this ACL fit is unavailable: it needs numbers at age, the age-length key and the weight at length ",
         "used in the fit (a live TMB object or a stored recipe). Supply weight at age in weight.", call. = FALSE)
  at_age * mean_weight
}

#' Spawning stock biomass from maturity at age
#'
#' Spawning stock biomass (SSB) by time step, calculated as the sum over age
#' classes of biomass at age multiplied by the proportion mature at age. ACL
#' and ALSCL calculate SSB from the proportion mature at length. This function
#' gives the SSB that corresponds to a maturity ogive by age, such as the one
#' used in an age-based assessment of the same stock.
#'
#' @param fit A fitted ACL or ALSCL result, including a saved assessment read
#'   with [read_assessment()].
#' @param maturity Proportion mature at age, between 0 and 1. A numeric vector
#'   with one value per age class of the fit, in the order of `fit$age` (the
#'   last value applies to the plus group), or a matrix with one row per age
#'   class and one column per time step.
#' @param weight NULL (default) uses the biomass at age of the model, which
#'   follows from the weight at length supplied to the fit. Otherwise mean
#'   weight at age, as a vector or matrix of the same form as `maturity`;
#'   biomass at age is then numbers at age multiplied by these weights.
#' @return A data frame with one row per time step: year (as in `fit$year`),
#'   SSB (from maturity at age), SSB_model (the SSB of the model, from
#'   maturity at length) and numerical_ok (the numerical screen of the fit).
#' @details Biomass at age of an ALSCL fit is `fit$report$BA`. An ACL fit
#'   does not report biomass at age. It is calculated as numbers at age
#'   multiplied by mean weight at age, where mean weight at age is the weight
#'   at length supplied to the fit averaged over the age-length key.
#'
#'   The SSB of the model (`fit$report$SSB`) is the sum over length bins of
#'   biomass at length multiplied by the proportion mature at length supplied
#'   to the fit. The two series are equal when maturity at age is the mean of
#'   maturity at length within each age class and time step, weighted by
#'   biomass at length (for ALSCL, `fit$report$SBA / fit$report$BA`). They
#'   differ in three cases. First, the maturity ogive by age comes from a
#'   source other than the maturity at length supplied to the fit, for
#'   example from an age-based assessment. Second, maturity at age is constant
#'   over time, whereas the lengths at age in the model, and with them the
#'   proportion mature at age implied by maturity at length, change over time
#'   or differ from those of the stock. Third, one proportion is applied to
#'   all fish of an age class, whereas maturity at length is higher for the
#'   large fish of the age class, which are also the heavy ones. With maturity
#'   at age equal to the mean of maturity at length weighted by numbers, and
#'   weight and maturity both increasing with length, the SSB from maturity at
#'   age is the lower of the two.
#'
#'   Both series are in the unit of model biomass, whose level depends on the
#'   assumed survey catchability. Compare the trend with an external series,
#'   not the level.
#' @seealso [length_at_age()], [relative_catch()], [extract_estimates()].
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#'
#' # An assumed maturity ogive by age: half of the fish mature at the fourth
#' # age class, all fish from the sixth
#' ogive <- pmin(1, pmax(0, (seq_along(fit$age) - 3) / 2))
#' ssb <- ssb_at_age(fit, maturity = ogive)
#' head(ssb)
#' cor(log(ssb$SSB), log(ssb$SSB_model))
#' }
#' @export
ssb_at_age <- function(fit, maturity, weight = NULL) {
  info <- .acl_derived_fit(fit)
  if (missing(maturity)) stop("maturity (proportion mature at age) is required.", call. = FALSE)
  maturity <- .acl_age_input(maturity, "maturity", info$ages, info$years, upper = 1)
  biomass <- .acl_biomass_at_age(fit, weight, info)
  model <- fit$report$SSB
  if (!is.numeric(model) || length(model) != length(info$years)) model <- rep(NA_real_, length(info$years))
  data.frame(year = info$years, SSB = as.numeric(colSums(maturity * biomass)),
             SSB_model = as.numeric(model), numerical_ok = .acl_numerical_ok(fit), row.names = NULL)
}

# Model catch in numbers and in weight by time step. ALSCL reports both. ACL
# reports catch in numbers; catch in weight is catch in numbers at age times
# mean weight at age, and is NULL when the weights of the fit are unavailable.
.acl_catch_series <- function(fit) {
  r <- fit$report
  number <- r$CN; weight <- r$CB
  if (is.null(weight) && is.matrix(r$CNA)) {
    mean_weight <- .acl_weight_at_age(fit)
    if (is.matrix(mean_weight) && identical(dim(mean_weight), dim(r$CNA)))
      weight <- colSums(r$CNA * mean_weight)
  }
  list(number = if (is.null(number)) NULL else as.numeric(number),
       weight = if (is.null(weight)) NULL else as.numeric(weight))
}

#' Relative catch by time step
#'
#' Model catch in numbers and in weight for each time step, each divided by
#' its mean over the time steps. Use it to compare the trend of the model
#' catch with reported catch.
#'
#' @param fit A fitted ACL or ALSCL result, including a saved assessment read
#'   with [read_assessment()].
#' @param years Time steps over which the mean is calculated, as values of
#'   `fit$year`. NULL (default) uses all time steps. Give the time steps with
#'   reported catch, and divide the reported catch by its mean over the same
#'   time steps, to place both series on the same scale.
#' @return A data frame with one row per time step: year (as in `fit$year`),
#'   catch_number and catch_weight (catch divided by its mean over `years`;
#'   no unit), extrapolated (TRUE for time steps whose catch is a prediction,
#'   see Details) and numerical_ok (the numerical screen of the fit).
#' @details ACL and ALSCL are fitted to a survey index alone. Such a fit has
#'   no information on the absolute level of catch or of the fishing mortality
#'   rate (F). The model catch follows from the Baranov catch equation with
#'   the estimated F and abundance, and the level of both depends on the
#'   assumed natural mortality rate (M) and the assumed survey catchability.
#'   Total mortality is estimated from the decline of cohorts in the survey, F
#'   is total mortality minus the assumed M, and abundance is the survey index
#'   divided by the assumed catchability. Only the trend of the model catch
#'   should be compared with reported catch, and the function therefore
#'   returns relative values only.
#'
#'   No observation informs F in the terminal time step (see
#'   [extract_estimates()]). Catch in that time step is a prediction and has
#'   extrapolated = TRUE. When the last time steps have no positive survey
#'   observation, catch from the last time step with an observation onwards
#'   is a prediction as well. These time steps are included in the mean
#'   unless `years` excludes them.
#'
#'   ALSCL reports catch in weight. For ACL it is calculated as catch in
#'   numbers at age multiplied by mean weight at age, where mean weight at age
#'   is the weight at length supplied to the fit averaged over the age-length
#'   key. For an ACL result with neither a live TMB object nor a stored
#'   recipe, the weights are unavailable and catch_weight is NA.
#' @seealso [length_at_age()], [ssb_at_age()], [plot_catch()].
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' catch <- relative_catch(fit)
#' head(catch)
#'
#' # Mean taken over the first ten time steps only
#' head(relative_catch(fit, years = fit$year[1:10]))
#' }
#' @export
relative_catch <- function(fit, years = NULL) {
  info <- .acl_derived_fit(fit)
  times <- info$years
  reference <- rep(TRUE, length(times))
  if (!is.null(years)) {
    if (!is.numeric(years) || !length(years) || any(!is.finite(years)))
      stop("years must be finite numeric time steps of fit.", call. = FALSE)
    position <- vapply(years, function(y) {
      hit <- which(abs(times - y) <= 1e-8 * max(1, abs(y)))
      if (length(hit)) hit[1L] else NA_integer_
    }, integer(1))
    if (anyNA(position))
      stop("years must be time steps of fit (fit$year); not found: ",
           paste(format(years[is.na(position)]), collapse = ", "), ".", call. = FALSE)
    reference <- seq_along(times) %in% position
  }
  series <- .acl_catch_series(fit)
  relative <- function(value, label) {
    if (is.null(value)) return(rep(NA_real_, length(times)))
    if (length(value) != length(times) || any(!is.finite(value)))
      stop("Catch in ", label, " does not match the time steps of fit, or is not finite.", call. = FALSE)
    scale <- mean(value[reference])
    if (!is.finite(scale) || scale <= 0)
      stop("Mean catch in ", label, " over the reference time steps must be positive.", call. = FALSE)
    value / scale
  }
  if (is.null(series$number)) stop("The report must contain catch in numbers (CN).", call. = FALSE)
  data.frame(year = times, catch_number = relative(series$number, "numbers"),
             catch_weight = relative(series$weight, "weight"),
             extrapolated = times >= .acl_last_informed(fit, times),
             numerical_ok = .acl_numerical_ok(fit), row.names = NULL)
}

# The last time step with a positive survey observation. F from that time
# step onwards enters no likelihood term (see extract_estimates()).
.acl_last_informed <- function(fit, years) {
  observed <- fit$observations
  if (is.matrix(observed) && ncol(observed) == length(years)) {
    with_data <- which(colSums(is.finite(observed) & observed > 0) > 0)
    if (length(with_data)) return(years[max(with_data)])
  }
  max(years)
}
