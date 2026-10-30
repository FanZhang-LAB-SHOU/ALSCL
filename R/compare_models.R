utils::globalVariables(c("Model", "Metric", "lower", "upper"))

#' Compare Two Stock Assessment Models (ACL vs ALSCL)
#'
#' Computes a comprehensive set of comparison metrics between two model results,
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
#'   \item{growth}{Data frame comparing VB growth parameters.}
#'   \item{fit_metrics}{Data frame with MSE, RMSE, R-squared, MAPE, etc. for each model.}
#'   \item{correlation}{Data frame with Pearson correlations and Ratio_Mean,
#'     the ratio of means (model2/model1), for common population quantities.}
#'   \item{model1_name,model2_name}{Labels used in the comparison.}
#'   \item{fit_diagnostics}{Numerical status of each fit, including the raw code,
#'     gradient, Hessian and natural-scale boundaries.}
#'   \item{comparison}{Whether data comparability was verified and both numerical
#'     screens passed; preferred is NULL when an automatic preference is withheld.}
#' }
#' @details Both fits must use the same positive observations, missing-data mask,
#'   length labels and time grid as data.CatL. Known mismatches are errors.
#'   Older results lacking this metadata can still display raw statistics, but
#'   receive no automatic model preference. The same applies to failed numerical
#'   screens. Passing the screen does not establish model adequacy; AIC expresses
#'   relative support among these candidates, not biological validation.
#'   Goodness-of-fit measures use the same calculation as
#'   \code{diagnostic_metrics()}. Undefined R-squared for constant observations
#'   is NA; nonfinite response-scale predictions at observed cells are errors.
#'   Data frames, tibbles and matrices follow the same input conversion as
#'   fitting. Numeric text and factor labels are read as observations, never
#'   as internal factor-level codes.
#'
#' @export
compare_models <- function(model1, model2, data.CatL,
                           model1_name = NULL, model2_name = NULL) {

  # Auto-detect names
  detect_type <- function(m, fallback) {
    if (!is.null(m$model_type)) return(m$model_type)
    # Infer from report structure
    if (!is.null(m$report$FL)) return("ALSCL")
    if (!is.null(m$report$F))  return("ACL")
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
      "1.0 (ref)"
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
      ""
    )),
    stringsAsFactors = FALSE
  )
  colnames(summary_df) <- c("Metric", model1_name, model2_name)

  # ===== 2. Growth parameters =====
  safe_round <- function(x, digits = 4) {
    if (is.null(x) || length(x) == 0) return(NA)
    round(as.numeric(x)[1], digits)
  }

  growth_df <- data.frame(
    Parameter = c("Linf", "k (vbk)", "t0", "cv_len", "cv_grow", "sigma_index"),
    Model1 = c(
      safe_round(model1$report$Linf, 3),
      safe_round(model1$report$vbk),
      safe_round(model1$report$t0),
      safe_round(model1$report$cv_len),
      safe_round(model1$report$cv_grow),
      safe_round(if(is.null(model1$report$sigma_index)) model1$report$std_index else model1$report$sigma_index)
    ),
    Model2 = c(
      safe_round(model2$report$Linf, 3),
      safe_round(model2$report$vbk),
      safe_round(model2$report$t0),
      safe_round(model2$report$cv_len),
      safe_round(model2$report$cv_grow),
      safe_round(if(is.null(model2$report$sigma_index)) model2$report$std_index else model2$report$sigma_index)
    ),
    stringsAsFactors = FALSE
  )
  colnames(growth_df) <- c("Parameter", model1_name, model2_name)

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

  for (i in seq_along(quantities)) {
    q <- quantities[i]
    v1 <- model1$report[[q]]
    v2 <- model2$report[[q]]
    if (!is.null(v1) && !is.null(v2) && length(v1) == length(v2)) {
      cors[i]   <- round(stats::cor(v1, v2), 4)
      ratios[i] <- round(mean(v2) / mean(v1), 4)
    } else {
      cors[i]   <- NA
      ratios[i] <- NA
    }
  }

  corr_df <- data.frame(
    Quantity    = quantities,
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

  cat("\n--- Growth Parameters ---\n")
  print(growth_df, row.names = FALSE)

  cat("\n--- Goodness-of-Fit ---\n")
  print(fit_df, row.names = FALSE)

  cat("\n--- Time-Series Agreement ---\n")
  print(corr_df, row.names = FALSE)

  cat("\n--- Numerical status ---\n")
  print(fit_diagnostics, row.names = FALSE)
  # Report raw information criteria even when a fit is unsuitable for inference,
  # but never present an automatic winner for unverified or failed fits.
  delta_aic <- aic2 - aic1
  preferred <- NULL
  cat(sprintf("\nDelta AIC = %.2f ", delta_aic))
  if (!eligible || !is.finite(delta_aic)) {
    cat("(automatic preference withheld; inspect diagnostics)\n")
  } else if (abs(delta_aic) < 2) {
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
    fit_metrics = fit_df,
    correlation = corr_df,
    fit_diagnostics = fit_diagnostics,
    comparison = list(data_verified = data_check$verified, eligible = eligible,
                      preferred = preferred, issues = reasons),
    model1_name = model1_name,
    model2_name = model2_name
  ))
}
