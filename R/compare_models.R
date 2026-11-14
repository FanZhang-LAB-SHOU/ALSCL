utils::globalVariables(c("Model", "Metric", "lower", "upper"))

#' Compare Two Stock Assessment Models (ACL vs ALSCL)
#'
#' Computes a set of comparison metrics between two model results,
#' including convergence diagnostics, parameter estimates, goodness-of-fit statistics,
#' time-series correlations, and information criteria.
#'
#' @param model1 A list from \code{run_acl} or \code{run_alscl}. Treated as the reference model.
#' @param model2 A list from \code{run_acl} or \code{run_alscl}. Treated as the alternative model.
#' @param data.CatL A data frame with survey catch-at-length data (used for goodness-of-fit).
#' @param model1_name Character. Label for model1. Default is auto-detected from model_type.
#' @param model2_name Character. Label for model2. Default is auto-detected from model_type.
#'
#' @return A list with:
#' \describe{
#'   \item{summary}{Data frame with convergence, objective, AIC, BIC, number of parameters.}
#'   \item{growth}{Data frame with one block of rows per model: Model,
#'     Parameter (Linf, k, t0, cv_len, cv_grow for ALSCL, and sigma_index, the
#'     standard deviation of the observation error of the log survey index),
#'     Estimate and Meaning. The growth parameters of ACL and ALSCL are not
#'     placed side by side, because they are different quantities (see
#'     Details).}
#'   \item{length_at_age}{Data frame with Age, Basis and one column per model:
#'     mean length at age, averaged over the time steps. This is the
#'     comparison of growth between the two fits. Basis is "survey" (numbers
#'     at length multiplied by survey catchability at length) when the survey
#'     catchability of both fits is available and "population" otherwise.
#'     NULL when neither fit holds the quantities needed (see
#'     [length_at_age()]).}
#'   \item{fit_metrics}{Data frame with MSE, RMSE, R-squared, MAPE, etc. for each model.}
#'   \item{correlation}{Data frame with Pearson correlations and Ratio_Mean,
#'     the ratio of means (model2/model1), for common population quantities.
#'     Catch in numbers and catch in weight are compared as relative catch
#'     (rows "CN (relative)" and "CB (relative)"): only the correlation is
#'     given and Ratio_Mean is NA (see Details).}
#'   \item{model1_name,model2_name}{Labels used in the comparison.}
#'   \item{fit_diagnostics}{Numerical status of each fit, including the raw code,
#'     gradient, Hessian and natural-scale boundaries.}
#'   \item{comparison}{Whether data comparability was verified (data_verified) and
#'     both numerical screens passed (eligible); preferred is NULL when an
#'     automatic preference is withheld. issues lists unverified data and
#'     failed numerical screens. delta_aic is the Akaike information criterion
#'     (AIC) of model2 minus that of model1, aic_threshold is the smallest
#'     absolute difference for which a preference is given (2), and reason
#'     states why a preference was withheld (NA when one is given).}
#' }
#' @details Both fits must use the same positive observations, missing-data mask,
#'   length labels and time grid as data.CatL. Known mismatches are errors.
#'   Older results lacking this metadata can still display raw statistics, but
#'   receive no automatic model preference. The same applies to failed numerical
#'   screens. Passing the screen does not establish model adequacy; AIC expresses
#'   relative support among these candidates, not biological validation.
#'   When both fits are eligible, preferred names the model with the lower AIC
#'   only if the two AIC values differ by at least 2. With a smaller difference
#'   preferred is NULL, issues is empty and comparison$reason records that the
#'   AIC difference is below 2; such a difference does not establish that the
#'   models are equivalent. A failure record from a batch function, such as an
#'   element of fit_scenarios()$fits that holds an error, is rejected with its
#'   fit error.
#'   Growth is compared through mean length at age, not through Linf, k and
#'   t0. In ACL these are the parameters of a von Bertalanffy curve of mean
#'   length at age. In ALSCL, Linf and k set the mean growth increment in one
#'   time step as a function of length, and Linf, k and t0 set the mean length
#'   of recruits; the lengths of older fish follow from the growth increments
#'   and from mortality at length. The parameters are therefore listed in a
#'   separate block for each model, with their meaning, and length_at_age
#'   holds mean length at age of both fits as an unweighted mean over the time
#'   steps of the values that [length_at_age()] returns.
#'   A fit to survey data alone has no information on the absolute level of
#'   catch, which depends on the assumed natural mortality rate and the
#'   assumed survey catchability (see [relative_catch()]). The catch series
#'   of the two fits are therefore compared by their correlation only. ACL
#'   does not report catch in weight; it is calculated from catch in numbers
#'   at age and mean weight at age when the weights used in the fit are
#'   available.
#'   Goodness-of-fit measures use the same calculation as
#'   \code{diagnostic_metrics()}. Undefined R-squared for constant observations
#'   is NA; nonfinite response-scale predictions at observed cells are errors.
#'   Data frames, tibbles and matrices follow the same input conversion as
#'   fitting. Numeric text and factor labels are read as observations, never
#'   as internal factor-level codes.
#'
#' @examples
#' \donttest{
#' # Fit both models to the last ten years of the example data. The shorter
#' # series and one fishing mortality rate (F) shared by all lengths in each
#' # year keep the ALSCL fit short.
#' x <- YTF_example
#' tables <- c("data.CatL", "data.wgt", "data.mat")
#' x[tables] <- lapply(x[tables], function(tab) tab[, c(1, 12:21)])
#' fit_acl <- run_acl(x, silent = TRUE)
#' fit_alscl <- run_alscl(x, F_structure = "year", silent = TRUE)
#' comparison <- compare_models(fit_acl, fit_alscl, x$data.CatL)
#' comparison$comparison$delta_aic
#' comparison$comparison$preferred
#' }
#' @export
compare_models <- function(model1, model2, data.CatL,
                           model1_name = NULL, model2_name = NULL) {

  # Auto-detect names
  detect_type <- function(m, fallback) {
    if (!is.null(m$model_type)) return(m$model_type)
    # Infer from report structure
    if (!is.null(m$report$FL)) return("ALSCL")
    if (!is.null(m$report[["F"]]))  return("ACL")
    return(fallback)
  }
  auto_names <- is.null(model1_name) && is.null(model2_name)
  if (is.null(model1_name)) model1_name <- detect_type(model1, "Model 1")
  if (is.null(model2_name)) model2_name <- detect_type(model2, "Model 2")
  if (identical(model1_name, model2_name)) {
    structures <- c(model1$F_structure, model2$F_structure)
    suffix <- if (auto_names && length(structures) == 2L && !anyDuplicated(structures))
      structures else c("1", "2")
    model1_name <- paste0(model1_name, " (", suffix[1L], ")")
    model2_name <- paste0(model2_name, " (", suffix[2L], ")")
  }
  data_check <- .acl_comparison_data(list(model1, model2), data.CatL)
  fit_diagnostics <- rbind(.acl_fit_status(model1), .acl_fit_status(model2))
  fit_diagnostics <- cbind(Model = c(model1_name, model2_name), fit_diagnostics)
  eligible <- data_check$verified && all(fit_diagnostics$numerical_ok)
  reasons <- data_check$issues
  if (any(!fit_diagnostics$numerical_ok))
    reasons <- c(reasons, paste("numerical screen failed:",
      paste(fit_diagnostics$Model[!fit_diagnostics$numerical_ok], collapse = ", ")))
  if (!eligible) warning("Automatic model preference withheld: ",
    paste(reasons, collapse = "; "), ". Inspect fit_diagnostics and raw statistics.", call. = FALSE)

  # ===== 1. Convergence & model summary =====
  n_obs <- data_check$n_obs

  obj1 <- as.numeric(model1$opt$objective)[1]
  obj2 <- as.numeric(model2$opt$objective)[1]
  npar1 <- .acl_npar(model1)
  npar2 <- .acl_npar(model2)

  aic1 <- 2 * npar1 + 2 * obj1
  aic2 <- 2 * npar2 + 2 * obj2
  bic1 <- npar1 * log(n_obs) + 2 * obj1
  bic2 <- npar2 * log(n_obs) + 2 * obj2
  valid_elapsed <- function(value) is.numeric(value) && length(value) == 1L &&
    is.finite(value) && value > 0
  elapsed_ratio <- if (valid_elapsed(model1$elapsed) && valid_elapsed(model2$elapsed))
    round(model2$elapsed / model1$elapsed, 4) else NA_real_

  summary_df <- data.frame(
    Metric = c("Model Type", "Convergence", "Boundary Hit",
               "Objective (NLL)", "N Parameters", "N Observations",
               "AIC", "BIC", "Delta AIC", "Delta BIC",
               "Max |Gradient|", "Run Time Ratio"),
    Model1 = as.character(c(
      model1_name,
      as.character(model1$converge)[1],
      as.character(model1$bound_hit)[1],
      round(obj1[1], 2),
      npar1,
      n_obs,
      round(aic1, 2),
      round(bic1, 2),
      "0 (ref)",
      "0 (ref)",
      round(.acl_max_gradient(model1), 6),
      if (valid_elapsed(model1$elapsed)) "1.0 (ref)" else NA_character_
    )),
    Model2 = as.character(c(
      model2_name,
      as.character(model2$converge)[1],
      as.character(model2$bound_hit)[1],
      round(obj2[1], 2),
      npar2,
      n_obs,
      round(aic2, 2),
      round(bic2, 2),
      round(aic2 - aic1, 2),
      round(bic2 - bic1, 2),
      round(.acl_max_gradient(model2), 6),
      elapsed_ratio
    )),
    stringsAsFactors = FALSE
  )
  colnames(summary_df) <- c("Metric", model1_name, model2_name)

  # ===== 2. Growth parameters, by model, and mean length at age =====
  # Linf, k and t0 are different quantities in ACL and ALSCL, so each model
  # has its own block of rows. Growth is compared through mean length at age.
  growth_df <- rbind(.acl_growth_block(model1, model1_name),
                     .acl_growth_block(model2, model2_name))
  length_df <- .acl_compare_length_at_age(model1, model2, model1_name, model2_name)

  # ===== 3. Goodness-of-fit metrics =====
  calc_fit <- function(model, data.CatL) {
    values <- .acl_survey_metrics(data.CatL, model)
    keys <- c("MSE", "RMSE", "MAE", "Rsquared", "MAPE", "SMAPE", "SD_log_resid")
    out <- values[keys]
    names(out)[names(out) == "Rsquared"] <- "R2"
    out
  }

  fit1 <- calc_fit(model1, data.CatL)
  fit2 <- calc_fit(model2, data.CatL)

  fit_df <- data.frame(
    Metric = names(fit1),
    Model1 = round(fit1, 4),
    Model2 = round(fit2, 4),
    stringsAsFactors = FALSE
  )
  colnames(fit_df) <- c("Metric", model1_name, model2_name)

  # ===== 4. Time-series correlations =====
  quantities <- c("SSB", "Rec", "B", "N", "CN", "CB")
  cors <- numeric(length(quantities))
  ratios <- numeric(length(quantities))

  # A fit to survey data alone does not estimate the level of catch, so the
  # catch series are compared as relative catch: correlation only.
  relative <- c("CN", "CB")
  catch <- lapply(list(model1, model2), function(m)
    tryCatch(.acl_catch_series(m), error = function(e) list()))
  series <- function(k, q) switch(q, CN = catch[[k]]$number, CB = catch[[k]]$weight,
                                  list(model1, model2)[[k]]$report[[q]])
  for (i in seq_along(quantities)) {
    q <- quantities[i]
    v1 <- series(1L, q)
    v2 <- series(2L, q)
    if (!is.null(v1) && !is.null(v2) && length(v1) == length(v2)) {
      cors[i]   <- round(stats::cor(v1, v2), 4)
      ratios[i] <- if (q %in% relative) NA else round(mean(v2) / mean(v1), 4)
    } else {
      cors[i]   <- NA
      ratios[i] <- NA
    }
  }

  corr_df <- data.frame(
    Quantity    = ifelse(quantities %in% relative, paste(quantities, "(relative)"), quantities),
    Correlation = cors,
    Ratio_Mean  = ratios,
    stringsAsFactors = FALSE
  )

  # ===== Print summary =====
  cat("\n", paste(rep("=", 60), collapse = ""), "\n")
  cat("  Model Comparison:", model1_name, "vs", model2_name, "\n")
  cat(paste(rep("=", 60), collapse = ""), "\n\n")

  cat("--- Convergence & Information Criteria ---\n")
  print(summary_df, row.names = FALSE)

  cat("\n--- Growth and observation error parameters, by model ---\n")
  for (name in c(model1_name, model2_name)) {
    cat(name, ":\n", sep = "")
    print(growth_df[growth_df$Model == name, c("Parameter", "Estimate", "Meaning")],
          row.names = FALSE, right = FALSE)
  }
  cat(.acl_growth_note(model1, model2), "\n", sep = "")

  cat("\n--- Mean length at age ---\n")
  if (is.null(length_df)) {
    cat("Not available: the fits do not hold numbers by length and age or an age-length key.\n")
  } else {
    print(data.frame(Age = length_df$Age, round(length_df[c(model1_name, model2_name)], 2),
                     check.names = FALSE), row.names = FALSE)
    cat(if (identical(length_df$Basis[1L], "survey"))
      "As the survey sees it (numbers at length multiplied by survey catchability at length)" else
      "In the population (survey catchability is unavailable for at least one fit)",
      "; mean over the time steps. See ?length_at_age.\n", sep = "")
  }

  cat("\n--- Goodness-of-Fit ---\n")
  print(fit_df, row.names = FALSE)

  cat("\n--- Time-Series Agreement ---\n")
  print(corr_df, row.names = FALSE)
  cat("CN and CB (catch in numbers and in weight) are compared as relative catch: a fit to survey data\n",
      "alone has no information on the absolute level of catch, so only the correlation is given.\n",
      "See ?relative_catch.\n", sep = "")

  cat("\n--- Numerical status ---\n")
  print(fit_diagnostics, row.names = FALSE)
  # Report raw information criteria even when a fit is unsuitable for inference,
  # but never present an automatic winner for unverified or failed fits.
  delta_aic <- aic2 - aic1
  aic_threshold <- 2
  preferred <- NULL
  reason <- NA_character_
  cat(sprintf("\nDelta AIC = %.2f ", delta_aic))
  if (!eligible || !is.finite(delta_aic)) {
    reason <- if (!eligible)
      "data not verified or a fit failed the numerical screen; see issues" else
      "AIC difference unavailable"
    cat("(automatic preference withheld; inspect diagnostics)\n")
  } else if (abs(delta_aic) < aic_threshold) {
    reason <- sprintf("absolute AIC difference below %g", aic_threshold)
    cat("(little separation in AIC; this does not establish model equivalence)\n")
  } else if (delta_aic < 0) {
    preferred <- model2_name
    cat(sprintf("(%s has lower AIC among these candidates)\n", model2_name))
  } else {
    preferred <- model1_name
    cat(sprintf("(%s has lower AIC among these candidates)\n", model1_name))
  }

  invisible(list(
    summary     = summary_df,
    growth      = growth_df,
    length_at_age = length_df,
    fit_metrics = fit_df,
    correlation = corr_df,
    fit_diagnostics = fit_diagnostics,
    comparison = list(data_verified = data_check$verified, eligible = eligible,
                      preferred = preferred, issues = reasons,
                      delta_aic = delta_aic, aic_threshold = aic_threshold,
                      reason = reason),
    model1_name = model1_name,
    model2_name = model2_name
  ))
}

# Growth and observation error parameters of one fit, with the meaning that
# each parameter has in that model. In ACL, Linf, k and t0 are the parameters
# of the von Bertalanffy curve of mean length at age. In ALSCL, Linf and k
# set the growth increment at length, and with t0 the length of recruits.
.acl_growth_block <- function(model, name) {
  type <- .detect_model_name(model, NA_character_)
  r <- model$report
  value <- function(x, digits = 4) {
    if (is.null(x) || length(x) == 0) return(NA_real_)
    round(as.numeric(x)[1], digits)
  }
  sigma <- if (is.null(r$sigma_index)) r$std_index else r$sigma_index
  observation <- "standard deviation of the observation error of the log survey index"
  if (identical(type, "ALSCL")) {
    parameter <- c("Linf", "k (vbk)", "t0", "cv_len", "cv_grow", "sigma_index")
    estimate <- c(value(r$Linf, 3), value(r$vbk), value(r$t0), value(r$cv_len), value(r$cv_grow), value(sigma))
    meaning <- c("sets the growth increment at length and the mean length of recruits (length unit)",
                 "sets the growth increment at length and the mean length of recruits (per year)",
                 "sets the mean length of recruits (years)",
                 "coefficient of variation of the length of recruits",
                 "coefficient of variation of the growth increment", observation)
  } else {
    parameter <- c("Linf", "k (vbk)", "t0", "cv_len", "sigma_index")
    estimate <- c(value(r$Linf, 3), value(r$vbk), value(r$t0), value(r$cv_len), value(sigma))
    meaning <- if (identical(type, "ACL"))
      c("asymptote of the von Bertalanffy curve of mean length at age (length unit)",
        "growth coefficient of that curve (per year)",
        "age at which mean length on that curve is zero (years)",
        "coefficient of variation of length at age", observation) else
      c(rep("model type unknown", 4L), observation)
  }
  data.frame(Model = name, Parameter = parameter, Estimate = estimate, Meaning = meaning,
             stringsAsFactors = FALSE)
}

# One sentence on whether the growth parameters of the two fits can be compared.
.acl_growth_note <- function(model1, model2) {
  types <- c(.detect_model_name(model1, NA_character_), .detect_model_name(model2, NA_character_))
  if (!anyNA(types) && types[1L] == types[2L])
    return(paste0("Both fits are ", types[1L], ", so each parameter has the same meaning in both."))
  paste0("Linf, k and t0 are different quantities in ACL and ALSCL and are not compared.\n",
         "Compare growth through mean length at age.")
}

# Mean length at age of two fits, averaged over the time steps. The survey
# basis is used when the survey catchability of both fits is available, the
# population basis otherwise. A fit without the quantities needed has NA;
# NULL when neither fit has them.
.acl_compare_length_at_age <- function(model1, model2, name1, name2) {
  models <- list(model1, model2)
  tables <- function(basis) lapply(models, function(m)
    tryCatch(.acl_mean_length_at_age(m, basis), error = function(e) NULL))
  basis <- "survey"; found <- tables(basis)
  if (any(vapply(found, is.null, logical(1)))) {
    population <- tables("population")
    if (sum(!vapply(population, is.null, logical(1))) > sum(!vapply(found, is.null, logical(1)))) {
      basis <- "population"; found <- population
    }
  }
  if (all(vapply(found, is.null, logical(1)))) return(NULL)
  ages <- sort(unique(round(unlist(lapply(found, `[[`, "age")), 8)))
  column <- function(x) if (is.null(x)) rep(NA_real_, length(ages)) else
    x$mean_length[match(ages, round(x$age, 8))]
  out <- data.frame(Age = ages, Basis = basis, column(found[[1L]]), column(found[[2L]]),
                    stringsAsFactors = FALSE)
  names(out)[3:4] <- c(name1, name2)
  out
}
