#' Project conditional population scenarios from a fitted assessment
#'
#' @param fit An ACL or ALSCL fit retaining its terminal population report.
#' @param F Future instantaneous fishing mortality per model time step. Supply
#'   a numeric vector with one value per future period (shared by all groups),
#'   or a group-by-period matrix: age groups for ACL, length groups for ALSCL.
#' @param recruitment Numeric vector of recruitment numbers, one per future
#'   period. This determines the projection horizon; zero recruitment is allowed.
#' @param weight,maturity Complete length-by-future-period numeric matrices.
#'   Weights must be nonnegative; maturity proportions must lie between zero and one. No
#'   biological values are carried forward or recycled implicitly. Optional
#'   row names must match fitted length labels or midpoints, and column names
#'   must match future times.
#' @param M Future natural mortality per model time step, a nonnegative scalar
#'   or one value per future period. NULL uses the original fitted M stored in
#'   the fit recipe. Legacy fits without a recipe require explicit M; its first
#'   value also specifies the terminal fitted interval's natural mortality.
#' @return A list with `summary` (future time, N, B, SSB, Rec, CN, CB, F_mean,
#'   F_apical), long `trajectories`, `fishing_mortality`, future `F`, `states`
#'   (NA, NL and, for ALSCL, NLA), `catch` (CNA and CNL), supplied `biology`,
#'   time metadata, and explicit `assumptions`. CN is catch in numbers; CB is
#'   catch biomass in the units implied by supplied individual weights.
#' @details These are deterministic conditional scenarios, not statistical
#'   forecasts or management recommendations. There are no confidence intervals,
#'   estimated stock-recruitment relationships, MSY or TAC calculations.
#'
#'   Population states, biomass and SSB refer to the start of each future model
#'   period. The first future state is the terminal fitted population survived
#'   through the terminal fitted F and original M, plus the first supplied
#'   recruitment. Future F[t] and M[t] govern catch in future period t and
#'   survival into t+1; they do not retroactively replace the terminal fitted F.
#'   Thus a one-period future F scenario changes catch, but not start-of-period
#'   SSB. Set a horizon of at least two periods to examine its population effect.
#'
#'   ACL uses its fitted age-length key and age survival with a plus group;
#'   ALSCL uses its fitted length-age state and growth matrix, with survival
#'   before growth. Growth and age-length probabilities remain fixed. ACL catch
#'   at length (and hence catch biomass) is derived from catch at age through
#'   the fitted age-length key. F_mean is an unweighted group mean; F_apical is
#'   a group maximum. Neither is an annualization of subannual mortality.
#'
#'   Only saved report arrays and metadata are needed: a live TMB object is not
#'   used. All assumptions and supplied future inputs are retained in the result.
#' @examples
#' \dontrun{
#' fit <- run_acl(YTF_example)
#' h <- 4L
#' nlength <- length(fit$len_mid)
#' future_weight <- matrix(1, nlength, h) # replace with species-specific values
#' future_maturity <- matrix(.5, nlength, h)
#' scenario <- project_model(fit, F = rep(.15, h),
#'   recruitment = rep(tail(fit$report$Rec, 1), h),
#'   weight = future_weight, maturity = future_maturity)
#' scenario$summary
#' }
#' @export
project_model <- function(fit, F, recruitment, weight, maturity, M = NULL) {
  if (!is.list(fit) || !is.list(fit$report))
    stop("fit must contain a fitted population report.", call. = FALSE)
  model <- toupper(fit$model_type)
  if (length(model) != 1L || !model %in% c("ACL", "ALSCL"))
    stop("fit$model_type must be ACL or ALSCL.", call. = FALSE)
  if (!is.numeric(recruitment) || !is.null(dim(recruitment)) || !length(recruitment) ||
      any(!is.finite(recruitment)) || any(recruitment < 0))
    stop("recruitment must contain finite nonnegative numbers for every future period.", call. = FALSE)
  horizon <- length(recruitment)
  L <- length(fit$len_mid); A <- length(fit$age); Y <- length(fit$year)
  coordinates <- .acl_check_coordinates(fit, L, Y)
  if (L < 2L || A < 2L || !is.numeric(fit$age) || any(!is.finite(fit$age)) ||
      any(diff(fit$age) <= 0) || Y < 1L)
    stop("Fit age, length and time dimensions are invalid.", call. = FALSE)
  step <- .acl_check_time_step(fit)
  if (any(abs(diff(fit$age) - step) > 1e-8 * max(1, step)))
    stop("Fitted ages must advance by one model time step.", call. = FALSE)
  years <- tail(coordinates$year, 1L) + seq_len(horizon) * step
  if (any(!is.finite(years)) || any(diff(c(tail(fit$year, 1L), years)) <= 0))
    stop("Future time grid is not finite and increasing.", call. = FALSE)
  check_matrix <- function(x, nr, nc, name, upper = Inf) {
    if (!is.matrix(x) || !is.numeric(x) || !identical(dim(x), as.integer(c(nr, nc))) ||
        any(!is.finite(x)) || any(x < 0) || any(x > upper))
      stop(name, " must be a finite nonnegative ", nr, "-by-", nc,
        " matrix", if (is.finite(upper)) paste0(" with values at most ", upper) else "", ".", call. = FALSE)
    x
  }
  check_names <- function(x, row_values, row_labels, name) {
    if (!is.null(rownames(x)) && !identical(rownames(x), as.character(row_values)) &&
        !identical(rownames(x), as.character(row_labels)))
      stop(name, " row names must match the fitted group order.", call. = FALSE)
    if (!is.null(colnames(x))) {
      supplied <- suppressWarnings(as.numeric(colnames(x)))
      if (any(!is.finite(supplied)) || any(abs(supplied - years) > 1e-8 * max(1, step)))
        stop(name, " column names must match future times.", call. = FALSE)
    }
    x
  }
  weight <- check_names(check_matrix(weight, L, horizon, "weight"),
    coordinates$length, coordinates$labels, "weight")
  maturity <- check_names(check_matrix(maturity, L, horizon, "maturity", 1),
    coordinates$length, coordinates$labels, "maturity")
  groups <- if (model == "ACL") A else L
  group_values <- if (model == "ACL") fit$age else coordinates$length
  group_labels <- if (model == "ACL") as.character(fit$age) else coordinates$labels
  if (is.numeric(F) && is.null(dim(F)) && length(F) == horizon)
    F <- matrix(rep(F, each = groups), groups, horizon)
  F <- check_names(check_matrix(F, groups, horizon, "F"), group_values, group_labels, "F")
  original_M <- fit$recipe$args$M
  if (!is.null(original_M)) .acl_scalar(original_M, "original fitted M", 0)
  legacy_M <- is.null(original_M)
  if (is.null(M)) {
    if (legacy_M) stop("Original fitted M is unavailable; supply M explicitly for this legacy fit.", call. = FALSE)
    M <- original_M
  }
  if (!is.numeric(M) || !is.null(dim(M)) || !length(M) %in% c(1L, horizon) ||
      any(!is.finite(M)) || any(M < 0))
    stop("M must be finite and nonnegative, with one value or one per future period.", call. = FALSE)
  M <- rep(M, length.out = horizon)
  if (legacy_M) original_M <- M[1L]
  pla <- check_matrix(fit$report$pla, L, A, "fitted pla")
  if (any(abs(colSums(pla) - 1) > 1e-8))
    stop("Each fitted pla column must sum to one.", call. = FALSE)
  terminal_F <- check_matrix(fit$report[[if (model == "ACL") "F" else "FL"]],
    groups, Y, "fitted F")[, Y]
  if (any(!is.finite(terminal_F + original_M)) || any(!is.finite(sweep(F, 2L, M, "+"))))
    stop("Total mortality overflowed; use finite representable F + M.", call. = FALSE)
  NA_state <- matrix(0, A, horizon)
  NL <- matrix(0, L, horizon)
  CNA <- matrix(0, A, horizon)
  CNL <- matrix(0, L, horizon)
  NLA <- if (model == "ALSCL") array(0, c(L, A, horizon)) else NULL
  G <- NULL
  if (model == "ACL") {
    previous <- check_matrix(fit$report[["NA"]], A, Y, "fitted NA")[, Y]
  } else {
    full <- fit$report$NLA
    if (!is.array(full) || !is.numeric(full) || !identical(dim(full), as.integer(c(L, A, Y))) ||
        any(!is.finite(full)) || any(full < 0))
      stop("fitted NLA must be a finite nonnegative length-by-age-by-time array.", call. = FALSE)
    previous <- matrix(full[, , Y], L, A)
    G <- check_matrix(fit$report$G, L, L, "fitted growth matrix")
    if (any(abs(colSums(G) - 1) > 1e-8))
      stop("Each fitted growth-matrix column must sum to one.", call. = FALSE)
  }
  for (t in seq_len(horizon)) {
    source_F <- if (t == 1L) terminal_F else F[, t - 1L]
    source_M <- if (t == 1L) original_M else M[t - 1L]
    survival <- exp(-(source_F + source_M))
    catch_fraction <- .acl_projection_catch_fraction(F[, t], M[t])
    if (model == "ACL") {
      next_state <- numeric(A)
      next_state[1L] <- recruitment[t]
      if (A > 2L) next_state[2L:(A - 1L)] <- previous[seq_len(A - 2L)] * survival[seq_len(A - 2L)]
      next_state[A] <- previous[A - 1L] * survival[A - 1L] + previous[A] * survival[A]
      NA_state[, t] <- next_state
      NL[, t] <- as.vector(pla %*% next_state)
      CNA[, t] <- next_state * catch_fraction
      CNL[, t] <- as.vector(pla %*% CNA[, t])
    } else {
      survived <- sweep(previous, 1L, survival, "*")
      next_state <- matrix(0, L, A)
      next_state[, 1L] <- pla[, 1L] * recruitment[t]
      if (A > 2L) next_state[, 2L:(A - 1L)] <- G %*% survived[, seq_len(A - 2L), drop = FALSE]
      next_state[, A] <- as.vector(G %*% (survived[, A - 1L] + survived[, A]))
      NLA[, , t] <- next_state
      NA_state[, t] <- colSums(next_state)
      NL[, t] <- rowSums(next_state)
      catch_at_length_age <- sweep(next_state, 1L, catch_fraction, "*")
      CNA[, t] <- colSums(catch_at_length_age)
      CNL[, t] <- rowSums(catch_at_length_age)
    }
    previous <- next_state
  }
  summary <- data.frame(year = years, N = colSums(NA_state), B = colSums(NL * weight),
    SSB = colSums(NL * weight * maturity), Rec = as.numeric(recruitment),
    CN = colSums(CNA), CB = colSums(CNL * weight), F_mean = colMeans(F),
    F_apical = apply(F, 2L, max), row.names = NULL)
  if (any(!is.finite(as.matrix(summary))))
    stop("Projection produced nonfinite population or biomass values.", call. = FALSE)
  dimnames(NA_state) <- dimnames(CNA) <- list(as.character(fit$age), as.character(years))
  dimnames(NL) <- dimnames(CNL) <- list(coordinates$labels, as.character(years))
  dimnames(F) <- list(group_labels, as.character(years))
  if (!is.null(NLA)) dimnames(NLA) <- list(coordinates$labels, as.character(fit$age), as.character(years))
  quantities <- setdiff(names(summary), "year")
  trajectories <- data.frame(year = rep(years, times = length(quantities)),
    quantity = rep(quantities, each = horizon), value = unlist(summary[quantities], use.names = FALSE))
  fishing <- data.frame(year = rep(years, each = groups),
    group = rep(group_values, times = horizon),
    group_type = if (model == "ACL") "age" else "length", F = as.vector(F))
  list(summary = summary, trajectories = trajectories, fishing_mortality = fishing,
    F = F, states = list("NA" = NA_state, NL = NL, NLA = NLA), catch = list(CNA = CNA, CNL = CNL),
    biology = list(weight = weight, maturity = maturity, M = M), model_type = model,
    year = years, time_step = step, terminal_year = tail(fit$year, 1L),
    assumptions = list(deterministic = TRUE, uncertainty = "none",
      recruitment = "explicitly supplied numbers", growth = "fixed fitted pla and growth matrix",
      terminal_F = terminal_F, terminal_M = original_M,
      terminal_M_source = if (legacy_M) "explicit M[1] for legacy fit" else "original fit recipe",
      state_timing = "start of each future period",
      mortality_timing = "terminal fitted F/M produce first future state; future F[t]/M[t] produce catch[t] and survival to t+1",
      mortality_units = "instantaneous per model time step; not annualized",
      source_fit_numerical_ok = fit$diagnostics$numerical_ok))
}

.acl_projection_catch_fraction <- function(F, M) {
  total <- F + M
  fraction <- numeric(length(total))
  positive <- total > 0
  fraction[positive] <- F[positive] / total[positive] * (-expm1(-total[positive]))
  fraction
}
