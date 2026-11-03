#' Calculate Biological and Fishing Variables for Simulation
#'
#' This function calculates derived biological variables (length-at-age,
#' weight-at-length, maturity, selectivity, survey catchability) and the
#' age-length probability matrix for the selected operating model. Both
#' pathways construct pla, the probability of length given age. The length-based
#' pathway additionally constructs Gij, the growth transition matrix.
#'
#' @param params A list of parameters from \code{initialize_params()}.
#'   Must contain \code{model_type} ("age_based" or "length_based") to
#'   determine the matrix orientation and whether to build growth transitions.
#'   Length midpoints must lie inside the matching open-tail bins; geometry is
#'   checked again so that manually edited parameter lists cannot bypass it.
#'
#' @return A list containing:
#'   \describe{
#'     \item{model_type}{Character: "age_based" or "length_based"}
#'     \item{LatA}{Length-at-age vector}
#'     \item{W_at_len}{Weight-at-length vector}
#'     \item{mat}{Maturity-at-length vector}
#'     \item{q_surv}{Survey catchability-at-length vector}
#'     \item{sel}{Selectivity vector (at-age for age_based, at-length for length_based)}
#'     \item{pla}{Probability of length given age. Rows are ages and columns
#'       are length groups for age_based; this orientation is transposed for
#'       length_based. Each age's probabilities sum to one.}
#'     \item{Gij}{Growth transition probabilities for length_based: row i and
#'       column j give the probability of moving from length group j to i in
#'       one model time step. Each column sums to one.}
#'     \item{nlen, len_mid, len_lower, len_upper}{Length bin dimensions and coordinates}
#'     \item{biology_inputs}{The biological parameters and age/length coordinates
#'       used to construct these arrays. sim_data() checks them against params;
#'       rerun sim_cal(params) after changing biological inputs.}
#'   }
#'
#' @export
sim_cal <- function(params) {

  biology_inputs <- .acl_simulation_biology_inputs(params)
  bins <- .acl_simulation_bins(params$len_mid, params$len_border)

  # =========================================================================
  # Extract common parameters
  # =========================================================================
  nage       <- params$nage
  ages       <- params$ages
  rec.age    <- params$rec.age
  vbk        <- params$vbk
  Linf       <- params$Linf
  t0         <- params$t0
  len_mid    <- bins$mid
  len_border <- c(-Inf, bins$border, Inf)
  cv_L       <- params$cv_L
  cv_inc     <- params$cv_inc
  q_surv_L50 <- params$q_surv_L50
  q_surv_L95 <- params$q_surv_L95

  model_type <- biology_inputs$model_type
  growth_step <- biology_inputs$growth_step

  # =========================================================================
  # Length bin setup
  # =========================================================================
  nlen      <- length(len_mid)
  len_lower <- bins$lower
  len_upper <- bins$upper

  # =========================================================================
  # Common derived variables
  # =========================================================================
  # Length-at-age (VB growth curve)
  LatA <- VB_func(Linf, vbk, t0, ages)

  # Weight-at-length: W = a * L^b
  W_at_len <- params$a * (len_mid ^ params$b)

  # Maturity-at-length: logistic function
  mat <- mat_func(params$mat_L50, params$mat_L95, len_mid)

  # Survey catchability-at-length: logistic function
  q_surv <- mat_func(q_surv_L50, q_surv_L95, len_mid)

  # =========================================================================
  # Age-length probability matrix (pla) -- always built, needed for
  # initial conditions in both age-based and length-based models
  # NOTE: In M7 (age-based), pla is nage x nlen (rows=ages, cols=lengths)
  #       In M6 (length-based), pla is nlen x nage (rows=lengths, cols=ages)
  # =========================================================================
  ml <- VB_func(Linf, vbk, t0, ages)
  sl <- cv_L * ml

  if (model_type == "age_based") {
    # pla[age, length] -- probability of length given age
    pla <- matrix(NA, nrow = nage, ncol = nlen)
    for (i in 1:nlen) {
      pla[, i] <- pnorm(len_border[i + 1], ml, sl) - pnorm(len_border[i], ml, sl)
    }
  } else {
    # pla[length, age] -- probability of length given age (transposed orientation)
    pla <- matrix(NA, nrow = nlen, ncol = nage)
    for (i in 1:nlen) {
      pla[i, ] <- pnorm(len_border[i + 1], ml, sl) - pnorm(len_border[i], ml, sl)
    }
  }

  # =========================================================================
  # Selectivity
  # =========================================================================
  sel_type <- if (!is.null(params$sel_type)) params$sel_type else "flat"

  if (sel_type == "flat") {
    # Flat selectivity at age (all ages fully selected)
    sel <- rep(1, if (model_type == "length_based") nlen else nage)

  } else if (sel_type == "dome") {
    # Dome-shaped double logistic selectivity at length
    # Ascending limb (small fish becoming selected)
    L50_asc  <- params$sel_L50_asc
    L95_asc  <- params$sel_L95_asc
    # Descending limb (large fish becoming unselected; note L50 > L95)
    L50_desc <- params$sel_L50_desc
    L95_desc <- params$sel_L95_desc

    # Find the break point: where ascending > 0.5 and descending starts
    mid_len  <- (L95_asc + L50_desc) / 2
    asc_idx  <- which(len_mid <= mid_len)
    desc_idx <- which(len_mid > mid_len)

    sel <- numeric(nlen)
    sel[asc_idx]  <- mat_func(L50_asc, L95_asc, len_mid[asc_idx])
    sel[desc_idx] <- mat_func(L50_desc, L95_desc, len_mid[desc_idx])

  } else {
    # Default fallback: flat at age
    sel <- rep(1, if (model_type == "length_based") nlen else nage)
  }

  # =========================================================================
  # Growth transition matrix Gij (length-based model only)
  # Gij[i,j] = probability of growing from bin j to bin i in one time step
  # Uses decreasing logistic growth increment model from M6 (tuna)
  # =========================================================================
  Gij <- NULL
  if (model_type == "length_based") {
    Gij <- matrix(NA, nrow = nlen, ncol = nlen)

    for (j in 1:nlen) {
      # Decreasing logistic growth increment
      # Maximum expected size increment (annual)
      delta_max <- (1 - exp(-vbk)) * Linf
      # Size at which growth increment is 50% of maximum
      l50_grow <- 0.5 * Linf
      # Size at which growth increment is 95% of maximum
      l95_grow <- 0.05 * Linf
      # Expected growth increment per time step (scaled by growth_step)
      ml_inc <- growth_step * delta_max /
        (1 + exp(-log(19) * (len_mid[j] - l50_grow) / (l95_grow - l50_grow)))
      # Variability of growth increment
      sl_inc <- ml_inc * cv_inc

      for (i in 1:nlen) {
        if (i < j) {
          # Cannot shrink: no transition to smaller bins
          Gij[i, j] <- 0
        } else if (i == j) {
          # Stay in same bin: CDF up to upper border
          Gij[i, j] <- pnorm(len_upper[i] - len_mid[j], ml_inc, sl_inc)
        } else {
          # Grow to larger bin: CDF difference
          Gij[i, j] <- pnorm(len_upper[i] - len_mid[j], ml_inc, sl_inc) -
            pnorm(len_lower[i] - len_mid[j], ml_inc, sl_inc)
        }
      }
    }
  }

  # =========================================================================
  # Return all calculated variables
  # =========================================================================
  result <- list(
    model_type = model_type,
    LatA       = LatA,
    W_at_len   = W_at_len,
    mat        = mat,
    pla        = pla,
    Gij        = Gij,
    q_surv     = q_surv,
    sel        = sel,
    len_mid    = len_mid,
    len_lower  = len_lower,
    len_upper  = len_upper,
    nlen       = nlen,
    biology_inputs = biology_inputs
  )
  .acl_simulation_biology(result, params, model_type)
  result
}

# Record only inputs that determine the biological arrays or their time scale.
# Process scales, simulation duration, burn-in, labels and output controls can
# change without rebuilding biology. Defaults match the simulation engines.
.acl_simulation_biology_inputs <- function(params) {
  model_type <- params$model_type %||% "age_based"
  if (!is.character(model_type) || length(model_type) != 1L ||
      !model_type %in% c("age_based", "length_based"))
    stop("Unknown simulation model_type.", call. = FALSE)
  nage <- .acl_positive_integer(params$nage, "nage", 2L)
  step <- .acl_scalar(params$growth_step %||%
    if (model_type == "length_based") 0.25 else 1, "growth_step", 0, TRUE)
  rec_age <- .acl_scalar(params$rec.age, "rec.age", 0, TRUE)
  ages <- params$ages
  expected <- rec_age + seq.int(0L, nage - 1L) * step
  if (!is.numeric(ages) || length(ages) != nage || any(!is.finite(ages)) ||
      any(abs(ages - expected) > 1e-8 * pmax(1, abs(expected))))
    stop("ages must equal rec.age + (0:(nage - 1)) * growth_step; ",
         "update the age grid and rerun sim_cal(params).", call. = FALSE)
  bins <- .acl_simulation_bins(params$len_mid, params$len_border)
  sel_type <- params$sel_type %||% "flat"
  fields <- c("Linf", "vbk", "t0", "cv_L", "a", "b", "mat_L50", "mat_L95",
              "q_surv_L50", "q_surv_L95")
  if (model_type == "length_based") fields <- c(fields, "cv_inc")
  if (identical(sel_type, "dome"))
    fields <- c(fields, "sel_L50_asc", "sel_L95_asc", "sel_L50_desc", "sel_L95_desc")
  c(list(model_type = model_type, nage = nage, rec.age = rec_age, ages = ages,
    growth_step = step, len_mid = bins$mid, len_border = c(-Inf, bins$border, Inf),
    sel_type = if (identical(sel_type, "dome")) "dome" else "flat"), params[fields])
}
