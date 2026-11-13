# Independent R reference for the ACL and ALSCL templates.
#
# These functions restate what inst/extdata/ACL.cpp, inst/extdata/ALSCL.cpp and
# inst/extdata/model_math.hpp compute at base commit 6b072b9. The model parts
# listed below use only base R and stats and do not call any ALSCL function,
# so a change in the templates or in the R simulators shows up as a difference
# from this file. Only the input builders at the end (ref_tmb_joint(),
# ref_model_inputs(), ref_stationarity_case(), ref_stationarity_ratio()) call
# the package, to prepare data and to evaluate the compiled templates.
#
# The reference is split into small parts so that an optional model structure
# can replace one part without touching the others:
#   ref_length_age_key()      probability of length bin given age (pla)
#   ref_growth_matrix()       ALSCL growth transition matrix (G)
#   ref_initial_numbers()     numbers at age in the first period
#   ref_alscl_initial_state() numbers at length and age in the first period
#   ref_acl_dynamics()        ACL population, catch and survey predictions
#   ref_alscl_dynamics()      ALSCL population, catch and survey predictions
#   ref_joint_nll()           joint negative log-likelihood and its components
# ref_acl_dynamics() and ref_alscl_dynamics() take the parts as function
# arguments (`key`, `growth`, `initial_numbers`, `initial_state`), so a
# corrected structure is tested by passing its own R function for that part.

# ---------------------------------------------------------------------------
# Small numerical pieces
# ---------------------------------------------------------------------------

# Probability that a standard normal variable lies in (lower, upper]. The right
# tail is used when lower > 0, as in normal_interval() of model_math.hpp.
ref_normal_interval <- function(upper, lower) {
  left <- stats::pnorm(upper) - stats::pnorm(lower)
  right <- stats::pnorm(lower, lower.tail = FALSE) - stats::pnorm(upper, lower.tail = FALSE)
  pmax(ifelse(lower > 0, right, left), 0)
}

# Integral of exp(-z t) over one time step, (1 - exp(-z)) / z, with limit 1.
ref_survival_integral <- function(z) {
  out <- rep(1, length(z))
  positive <- z > 0
  out[positive] <- -expm1(-z[positive]) / z[positive]
  dim(out) <- dim(z)
  out
}

ref_ar1_correlation <- function(n, phi) phi^abs(outer(seq_len(n), seq_len(n), "-"))

# Negative log density of a zero-mean multivariate normal vector.
ref_mvn_nll <- function(x, covariance) {
  root <- chol(covariance)
  z <- backsolve(root, x, transpose = TRUE)
  0.5 * length(x) * log(2 * pi) + sum(log(diag(root))) + 0.5 * sum(z^2)
}

# Stationary AR(1) process with marginal standard deviation sigma, written as
# the product of conditional normal densities.
ref_ar1_nll <- function(x, phi, sigma) {
  n <- length(x)
  innovation <- sigma * sqrt(1 - phi^2)
  -(stats::dnorm(x[1L], 0, sigma, log = TRUE) +
      sum(stats::dnorm(x[-1L], phi * x[-n], innovation, log = TRUE)))
}

# Separable two-dimensional AR(1) field. Rows of `x` are groups (ages in ACL,
# length bins in ALSCL) and columns are time steps. vec(x) stacks columns, so
# its covariance is sigma^2 * (time correlation %x% group correlation).
ref_separable_ar1_nll <- function(x, phi_group, phi_time, sigma) {
  covariance <- sigma^2 * kronecker(ref_ar1_correlation(ncol(x), phi_time),
                                    ref_ar1_correlation(nrow(x), phi_group))
  ref_mvn_nll(as.numeric(x), covariance)
}

# ---------------------------------------------------------------------------
# Parameters on the natural scale, with one set of names for both models
# ---------------------------------------------------------------------------
ref_natural_parameters <- function(model, p) {
  acl <- model == "ACL"
  pick <- function(a, b) p[[if (acl) a else b]]
  list(
    init_Z = exp(p$log_init_Z),
    sd_log_N0 = exp(pick("log_std_log_N0", "log_sigma_log_N0")),
    mean_log_R = p$mean_log_R,
    sd_log_R = exp(pick("log_std_log_R", "log_sigma_log_R")),
    phi_log_R = stats::plogis(p$logit_log_R),
    mean_log_F = p$mean_log_F,
    sd_log_F = exp(pick("log_std_log_F", "log_sigma_log_F")),
    phi_log_F_time = stats::plogis(p$logit_log_F_y),
    phi_log_F_group = stats::plogis(pick("logit_log_F_a", "logit_log_F_l")),
    vbk = exp(p$log_vbk), Linf = exp(p$log_Linf),
    t0 = if (acl) p$t0 else exp(p$log_t0),
    cv_len = exp(p$log_cv_len),
    cv_grow = if (acl) NULL else exp(p$log_cv_grow),
    sd_index = exp(pick("log_std_index", "log_sigma_index")),
    dev_log_R = as.numeric(p$dev_log_R),
    dev_log_F = as.matrix(p$dev_log_F),
    dev_log_N0 = as.numeric(p$dev_log_N0))
}

# ---------------------------------------------------------------------------
# Length-at-age key (model_math.hpp, length_age_key)
# ---------------------------------------------------------------------------
# Rows are length bins and columns are ages. Mean length at age follows the
# von Bertalanffy curve and the standard deviation is cv_len times the mean.
# Each cell is floored at 1e-300 and each column is rescaled to sum to one.
ref_length_age_key <- function(len_border, age, Linf, vbk, t0, cv_len) {
  L <- length(len_border) + 1L
  key <- vapply(age, function(a) {
    mean_length <- Linf * (1 - exp(-vbk * (a - t0)))
    z <- (len_border - mean_length) / (mean_length * cv_len)
    column <- c(stats::pnorm(z[1L]),
                if (L > 2L) ref_normal_interval(z[-1L], z[-(L - 1L)]),
                stats::pnorm(-z[L - 1L]))
    column <- pmax(column, 1e-300)
    column / sum(column)
  }, numeric(L))
  key
}

# ---------------------------------------------------------------------------
# ALSCL growth transition matrix (ALSCL.cpp lines 104-121)
# ---------------------------------------------------------------------------
# G[i, j] is the probability of moving from length bin j to bin i in one time
# step. The mean increment declines with length along a logistic curve with
# 50% of the maximum at 0.5 Linf and 95% at 0.05 Linf. The increment is normal
# with standard deviation cv_grow times its mean, measured from the bin
# midpoint. Fish cannot shrink, the last bin absorbs the right tail, and each
# column is rescaled to sum to one.
ref_growth_increment <- function(len_mid, Linf, vbk, growth_step) {
  max_increment <- (1 - exp(-vbk)) * Linf
  l50 <- 0.5 * Linf
  l95 <- 0.05 * Linf
  growth_step * max_increment / (1 + exp(-log(19) * (len_mid - l50) / (l95 - l50)))
}

ref_growth_matrix <- function(len_mid, len_border, Linf, vbk, cv_grow, growth_step) {
  L <- length(len_mid)
  G <- matrix(0, L, L)
  increment <- ref_growth_increment(len_mid, Linf, vbk, growth_step)
  for (j in seq_len(L)) {
    if (j == L) {
      G[L, L] <- 1
      next
    }
    sd_increment <- increment[j] * cv_grow
    z <- (len_border - len_mid[j] - increment[j]) / sd_increment
    for (i in j:L) {
      G[i, j] <- if (i == L) stats::pnorm(-z[L - 1L])
        else if (i == j) stats::pnorm(z[i])
        else ref_normal_interval(z[i], z[i - 1L])
    }
    G[, j] <- G[, j] / sum(G[, j])
  }
  G
}

# ---------------------------------------------------------------------------
# First-period state
# ---------------------------------------------------------------------------
# Numbers at age in the first period: recruitment for the first age, then
# log N(a) = log N(a - 1) - init_Z + dev_log_N0(a - 1) for every later age,
# including the last one. The last age therefore starts as a single cohort and
# not as an accumulated plus group (review finding F03).
ref_initial_numbers <- function(recruitment, init_Z, dev_log_N0) {
  A <- length(dev_log_N0) + 1L
  log_n <- numeric(A)
  log_n[1L] <- log(recruitment)
  for (a in 2:A) log_n[a] <- log_n[a - 1L] - init_Z + dev_log_N0[a - 1L]
  exp(log_n)
}

# ALSCL numbers at length and age in the first period: numbers at age spread
# over length bins with the length-at-age key (ALSCL.cpp lines 144-146). The
# growth matrix and the mortality rates are accepted but not used, so that a
# structure that builds the first period from the dynamics has the same
# signature.
ref_alscl_initial_state <- function(numbers_at_age, key, G = NULL, Z_at_length = NULL) {
  sweep(key, 2L, numbers_at_age, "*")
}

# ---------------------------------------------------------------------------
# ACL dynamics (ACL.cpp)
# ---------------------------------------------------------------------------
# `data` is the TMB data list and `p` the TMB parameter list of the ACL
# template. Returns the reported quantities under the template's names.
ref_acl_dynamics <- function(data, p, key = ref_length_age_key,
                             initial_numbers = ref_initial_numbers) {
  q <- ref_natural_parameters("ACL", p)
  A <- data$A; Y <- data$Y
  pla <- key(data$len_border, data$age, q$Linf, q$vbk, q$t0, q$cv_len)
  dev_F <- if (nrow(q$dev_log_F) == 1L) q$dev_log_F[rep(1L, A), , drop = FALSE] else q$dev_log_F
  FA <- exp(q$mean_log_F + dev_F)
  Z <- FA + data$M
  Rec <- exp(q$mean_log_R + q$dev_log_R)
  N_at_age <- matrix(0, A, Y)
  N_at_age[, 1L] <- initial_numbers(Rec[1L], q$init_Z, q$dev_log_N0)
  for (y in seq_len(Y)[-1L]) {
    N_at_age[1L, y] <- Rec[y]
    if (A > 2L) N_at_age[2:(A - 1L), y] <-
      N_at_age[1:(A - 2L), y - 1L] * exp(-Z[1:(A - 2L), y - 1L])
    N_at_age[A, y] <- N_at_age[A - 1L, y - 1L] * exp(-Z[A - 1L, y - 1L]) +
      N_at_age[A, y - 1L] * exp(-Z[A, y - 1L])
  }
  NL <- pla %*% N_at_age
  BL <- NL * data$weight
  SBL <- BL * data$mat
  CNA <- N_at_age * FA * ref_survival_integral(Z)
  Elog_index <- data$log_q + log(NL + 1e-300)
  observed <- data$na_matrix > 0
  resid_index <- matrix(0, data$L, Y)
  resid_index[observed] <- (data$logN_at_len - Elog_index)[observed]
  out <- list(pla = pla, Rec = Rec, N = colSums(N_at_age), NL = NL, BL = BL, SBL = SBL,
              B = colSums(BL), SSB = colSums(SBL), F = FA, Z = Z, CNA = CNA,
              CN = colSums(CNA), Elog_index = Elog_index, resid_index = resid_index)
  out[["NA"]] <- N_at_age
  out
}

# ---------------------------------------------------------------------------
# ALSCL dynamics (ALSCL.cpp)
# ---------------------------------------------------------------------------
# Numbers are tracked by length bin, age and time step. Recruits enter with the
# length-at-age key of the first age. Every other age survives at the
# length-specific rate and then grows through G. The last age accumulates.
ref_alscl_dynamics <- function(data, p, key = ref_length_age_key,
                               growth = ref_growth_matrix,
                               initial_numbers = ref_initial_numbers,
                               initial_state = ref_alscl_initial_state) {
  q <- ref_natural_parameters("ALSCL", p)
  A <- data$A; Y <- data$Y; L <- data$L
  pla <- key(data$len_border, data$age, q$Linf, q$vbk, q$t0, q$cv_len)
  G <- growth(data$len_mid, data$len_border, q$Linf, q$vbk, q$cv_grow, data$growth_step)
  dev_F <- if (nrow(q$dev_log_F) == 1L) q$dev_log_F[rep(1L, L), , drop = FALSE] else q$dev_log_F
  FL <- exp(q$mean_log_F + dev_F)
  ZL <- FL + data$M
  Rec <- exp(q$mean_log_R + q$dev_log_R)
  NLA <- array(0, c(L, A, Y))
  NLA[, , 1L] <- initial_state(initial_numbers(Rec[1L], q$init_Z, q$dev_log_N0),
                               pla, G, ZL[, 1L])
  for (y in seq_len(Y)[-1L]) {
    survival <- exp(-ZL[, y - 1L])
    NLA[, 1L, y] <- pla[, 1L] * Rec[y]
    if (A > 2L) for (a in 2:(A - 1L))
      NLA[, a, y] <- G %*% (NLA[, a - 1L, y - 1L] * survival)
    NLA[, A, y] <- G %*% ((NLA[, A - 1L, y - 1L] + NLA[, A, y - 1L]) * survival)
  }
  per_length <- function(x) sweep(NLA, c(1L, 3L), x, "*")
  BLA <- per_length(data$weight)
  SBLA <- per_length(data$weight * data$mat)
  CNLA <- per_length(FL * ref_survival_integral(ZL))
  CBLA <- sweep(CNLA, c(1L, 3L), data$weight, "*")
  by_length <- function(x) apply(x, c(1L, 3L), sum)
  by_age <- function(x) apply(x, c(2L, 3L), sum)
  NL <- by_length(NLA)
  # Total mortality at age is the log ratio of a cohort's numbers before and
  # after one step of length-specific mortality, for all ages but the last and
  # all time steps but the last.
  ZA <- matrix(0, A - 1L, Y - 1L)
  for (a in seq_len(A - 1L)) for (y in seq_len(Y - 1L)) {
    cohort <- NLA[, a, y]
    ZA[a, y] <- log(max(sum(cohort), 1e-300)) -
      log(max(sum(cohort * exp(-ZL[, y])), 1e-300))
  }
  Elog_index <- data$log_q + log(pmax(NL, 1e-300))
  observed <- data$na_matrix > 0
  resid_index <- matrix(0, L, Y)
  resid_index[observed] <- (data$logN_at_len - Elog_index)[observed]
  out <- list(pla = pla, G = G, Rec = Rec, NLA = NLA, NL = NL, N = colSums(NL),
              BLA = BLA, BL = by_length(BLA), BA = by_age(BLA), B = apply(BLA, 3L, sum),
              SBLA = SBLA, SBL = by_length(SBLA), SBA = by_age(SBLA),
              SSB = apply(SBLA, 3L, sum),
              CNLA = CNLA, CNL = by_length(CNLA), CNA = by_age(CNLA),
              CN = apply(CNLA, 3L, sum),
              CBLA = CBLA, CBL = by_length(CBLA), CBA = by_age(CBLA),
              CB = apply(CBLA, 3L, sum),
              FL = FL, ZL = ZL, ZA = ZA, FA = ZA - data$M,
              Elog_index = Elog_index, resid_index = resid_index)
  out[["NA"]] <- by_age(NLA)
  out
}

ref_dynamics <- function(model, data, p, ...) {
  if (model == "ACL") ref_acl_dynamics(data, p, ...) else ref_alscl_dynamics(data, p, ...)
}

# ---------------------------------------------------------------------------
# Joint negative log-likelihood
# ---------------------------------------------------------------------------
# Sum of four parts, evaluated at the supplied random effects:
#   index       lognormal survey observation error in the observed cells
#   F           AR(1) over time when dev_log_F has one row (F_structure =
#               "year"); otherwise a separable AR(1) field with
#               phi_log_F_time along columns and phi_log_F_group along rows
#   recruitment AR(1) over time
#   N0          independent normal deviations of first-period numbers at age
# `dynamics` can be supplied when it has already been computed.
ref_joint_nll <- function(model, data, p, dynamics = ref_dynamics(model, data, p),
                          swap_F_correlations = FALSE) {
  q <- ref_natural_parameters(model, p)
  observed <- data$na_matrix > 0
  index <- -sum(stats::dnorm(data$logN_at_len[observed], dynamics$Elog_index[observed],
                             q$sd_index, log = TRUE))
  fishing <- if (nrow(q$dev_log_F) == 1L) {
    ref_ar1_nll(as.numeric(q$dev_log_F), q$phi_log_F_time, q$sd_log_F)
  } else if (swap_F_correlations) {
    ref_separable_ar1_nll(q$dev_log_F, q$phi_log_F_time, q$phi_log_F_group, q$sd_log_F)
  } else {
    ref_separable_ar1_nll(q$dev_log_F, q$phi_log_F_group, q$phi_log_F_time, q$sd_log_F)
  }
  recruitment <- ref_ar1_nll(q$dev_log_R, q$phi_log_R, q$sd_log_R)
  initial <- -sum(stats::dnorm(q$dev_log_N0, 0, q$sd_log_N0, log = TRUE))
  parts <- c(index = index, F = fishing, recruitment = recruitment, N0 = initial)
  list(total = sum(parts), parts = parts)
}

# ---------------------------------------------------------------------------
# Compiled templates evaluated at supplied random effects
# ---------------------------------------------------------------------------
# Without `random`, obj$fn() is the joint negative log-likelihood and
# obj$report() is evaluated at exactly the supplied values.
ref_tmb_joint <- function(model, data, parameters, map = list()) {
  info <- ALSCL:::.acl_compile(model)
  obj <- TMB::MakeADFun(data, parameters, map = map, DLL = info$dll_name, silent = TRUE)
  list(obj = obj, nll = as.numeric(obj$fn(obj$par)), report = obj$report(obj$par))
}

# Largest relative difference, with a floor so that exact zeros compare equal.
ref_relative_difference <- function(actual, expected, floor = 1e-300) {
  max(abs(actual - expected) / pmax(abs(actual), abs(expected), floor))
}

# ---------------------------------------------------------------------------
# Model inputs built through the package's own preparation path
# ---------------------------------------------------------------------------
# Returns the TMB data and parameter lists for `model` with survey observations
# `observations` (length bins by time steps; NA and zero cells are treated as
# missing). `parameters` sets values on the internal scale. They are used
# exactly as given, without the clamping to optimizer bounds that the fitting
# functions apply to starting values.
ref_model_inputs <- function(model, observations, len_mid, len_border, rec.age, nage, M,
                             growth_step, weight, maturity, sel_L50, sel_L95,
                             parameters = NULL, F_structure = "group_year",
                             first_year = 2000) {
  L <- length(len_mid); Y <- ncol(observations)
  years <- first_year + (seq_len(Y) - 1L) * growth_step
  frame <- function(values) {
    out <- data.frame(LengthBin = as.character(len_mid), matrix(values, L, Y),
                      check.names = FALSE)
    names(out) <- c("LengthBin", as.character(years))
    out
  }
  prepared <- ALSCL:::.acl_prepare_data(frame(observations), frame(weight), frame(maturity),
    rec.age = rec.age, nage = nage, M = M, sel_L50 = sel_L50, sel_L95 = sel_L95,
    growth_step = growth_step, len_mid = len_mid, len_border = len_border)
  setup <- ALSCL:::.acl_model_setup(model, prepared, parameters = parameters,
                                    F_structure = F_structure)
  for (name in names(parameters)) setup$parameters[[name]] <- parameters[[name]]
  list(data = setup$data, parameters = setup$parameters, map = setup$map,
       random = setup$random, prepared = prepared)
}

# ---------------------------------------------------------------------------
# Stationarity under constant recruitment and no fishing
# ---------------------------------------------------------------------------
# Biological settings of the two cases used in the review. Lengths in cm.
ref_stationarity_case <- function(case = c("tuna", "flatfish")) {
  case <- match.arg(case)
  sp <- initialize_params(species = case)
  bins <- ALSCL:::.acl_simulation_bins(sp$len_mid, sp$len_border)
  list(case = case, len_mid = bins$mid, len_border = bins$border,
       rec.age = sp$rec.age, nage = sp$nage, growth_step = sp$growth_step, M = sp$M,
       Linf = sp$Linf, vbk = sp$vbk, t0 = sp$t0, cv_len = sp$cv_L, cv_grow = sp$cv_inc,
       weight = sp$a * bins$mid^sp$b,
       maturity = stats::plogis(log(19) * (bins$mid - sp$mat_L50) / (sp$mat_L95 - sp$mat_L50)))
}

# Project a population with constant recruitment, fishing mortality rate
# `fishing` (default 0) and all recruitment and F deviations at zero, and
# return the ratio of spawning stock biomass (SSB) in the last time step to
# SSB in the first. A structure with a stationary first-period state gives 1.
#
#   model     "ALSCL" or "ACL"
#   source    "reference" uses the R dynamics in this file; "tmb" uses the
#             report of the compiled template
#   plus_group_deviation
#             "zero" leaves every dev_log_N0 at zero. "equilibrium" sets the
#             last dev_log_N0 to -log(1 - exp(-Z)), which makes numbers at age
#             stationary under the current first-period recursion and leaves
#             only the length-at-age inconsistency of ALSCL.
#   steps     number of time steps
#   ...       passed to ref_dynamics() (source = "reference") so that another
#             structure can supply `key`, `growth`, `initial_numbers` or
#             `initial_state`
#   tmb_data, tmb_parameters
#             named lists merged into the TMB data and parameter lists
#             (source = "tmb"), for new data switches or parameters
# The value carries the SSB series in attribute "SSB".
ref_stationarity_ratio <- function(case = "tuna", model = "ALSCL",
                                   source = c("reference", "tmb"),
                                   plus_group_deviation = c("zero", "equilibrium"),
                                   steps = 41L, fishing = 0, recruitment = 1e4, ...,
                                   tmb_data = list(), tmb_parameters = list()) {
  source <- match.arg(source)
  plus_group_deviation <- match.arg(plus_group_deviation)
  x <- if (is.list(case)) case else ref_stationarity_case(case)
  L <- length(x$len_mid); A <- x$nage
  Z <- x$M + fishing
  parameters <- list(log_Linf = log(x$Linf), log_vbk = log(x$vbk),
                     log_cv_len = log(x$cv_len), mean_log_R = log(recruitment),
                     log_init_Z = log(Z))
  if (model == "ACL") parameters$t0 <- x$t0 else {
    parameters$log_t0 <- log(x$t0); parameters$log_cv_grow <- log(x$cv_grow)
  }
  inputs <- ref_model_inputs(model, matrix(1, L, steps), x$len_mid, x$len_border,
    x$rec.age, A, x$M, x$growth_step, x$weight, x$maturity,
    sel_L50 = x$len_mid[2L], sel_L95 = x$len_mid[3L], parameters = parameters)
  p <- inputs$parameters
  # exp(-Inf) is exactly zero in R and in the double evaluation of the report.
  p$mean_log_F <- log(fishing)
  if (plus_group_deviation == "equilibrium") p$dev_log_N0[A - 1L] <- -log(1 - exp(-Z))
  ssb <- if (source == "reference") {
    ref_dynamics(model, inputs$data, p, ...)$SSB
  } else {
    data <- utils::modifyList(inputs$data, tmb_data)
    p <- utils::modifyList(p, tmb_parameters)
    info <- ALSCL:::.acl_compile(model)
    obj <- TMB::MakeADFun(data, p, DLL = info$dll_name, type = "Fun", silent = TRUE)
    obj$report(unlist(p[names(obj$env$parameters)], use.names = FALSE))$SSB
  }
  structure(ssb[steps] / ssb[1L], SSB = as.numeric(ssb))
}
