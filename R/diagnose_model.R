#' Diagnose a fitted assessment model
#' @param data.CatL Length labels followed by time columns.
#' @param model_result A fitted model result.
#' @param x A table returned by \code{diagnose_model()}.
#' @param digits Number of significant digits of the printed values.
#' @param ... Not used.
#' @return A data frame with the columns Metric and Value: the fit statistics
#'   of [diagnostic_metrics()] followed by the numerical checks. Value is
#'   numeric; a check that is TRUE or FALSE has the value 1 or 0 and is
#'   printed as TRUE or FALSE. The table prints with values to 4 significant
#'   digits and a legend of the fit statistics.
#' @details The fit statistics compare the observed and the fitted survey
#'   index at length over the positive observations: MSE and RMSE, the mean
#'   squared error and its square root; MAE, the mean absolute error; MAD, the
#'   mean absolute deviation of the observations from their mean; MASE, the
#'   MAE divided by the mean absolute change of the observations between
#'   adjacent time steps; Rsquared, the coefficient of determination; MAPE and
#'   SMAPE, the mean absolute percentage error and its symmetric form;
#'   Explained Variance Score, one minus the variance of the errors divided by
#'   the variance of the observations; Max Error, the largest absolute error;
#'   AIC and BIC, the Akaike and Bayesian information criteria.
#'
#'   The numerical checks are the optimizer convergence code ("Optimizer
#'   converged" is TRUE for code 0), the maximum absolute gradient, whether a
#'   parameter is at a bound of the optimizer and whether the Hessian is
#'   positive definite, reported separately. A successful
#'   optimizer code alone does not establish reliable statistical inference.
#'   For fits that store them, the numbers of parameters at their limit in
#'   practice and of plausibility notes are added; see the Details of
#'   [run_acl()] and \code{model_result$diagnostics}.
#'   Input observations are checked against available fitted time, length and
#'   observation metadata by \code{diagnostic_metrics()}; known mismatches are errors.
#' @examples
#' \donttest{
#' fit <- run_acl(YTF_example, silent = TRUE)
#' diagnose_model(YTF_example$data.CatL, fit)
#' }
#' @export
diagnose_model <- function(data.CatL, model_result) {
  if (!is.list(model_result)) stop("Model output should be a list.")
  metrics <- diagnostic_metrics(data.CatL, model_result)
  code <- model_result$convergence_code
  if (is.null(code)) code <- model_result$opt$convergence
  if (is.null(code)) code <- NA_integer_
  hessian <- model_result$pdHess
  if (is.null(hessian)) hessian <- NA
  bound <- model_result$bound_hit
  if (is.null(bound)) bound <- NA
  gradient <- .acl_max_gradient(model_result)
  cat("Optimizer convergence code:",code,"\nMaximum absolute gradient:",gradient,
      "\nPositive-definite Hessian:",hessian,"\nParameter boundary hit:",bound,"\n")
  result <- rbind(metrics, data.frame(Metric = c("Parameter boundary hit", "Optimizer converged",
                                                  "Maximum absolute gradient", "Positive-definite Hessian"),
                            Value = c(bound, if (is.na(code)) NA else code == 0L, gradient, hessian)))
  if (!is.null(model_result$diagnostics)) {
    d <- model_result$diagnostics
    cat("Numerical checks:", d$numerical_ok, "\nNatural-scale boundary:",
        d$natural_boundary, "\nRefinement:", model_result$refinement$status, "\n")
    result <- rbind(result, data.frame(Metric = c("Numerical checks passed",
      "Natural-scale boundary", "Covariance condition number", "Highly correlated parameter pairs"),
      Value = c(d$numerical_ok, d$natural_boundary, d$covariance_condition, nrow(d$high_correlations))))
    # Fits of earlier versions do not store these two elements.
    if (is.data.frame(d$limit_parameters) && is.data.frame(d$plausibility)) {
      cat("Parameters at their limit in practice:", nrow(d$limit_parameters),
          "\nPlausibility notes:", nrow(d$plausibility), "\n")
      result <- rbind(result, data.frame(Metric = c("Parameters at their limit in practice", "Plausibility notes"),
        Value = c(nrow(d$limit_parameters), nrow(d$plausibility))))
    }
  }
  structure(result, class = c("alscl_diagnosis", "data.frame"))
}

# Rows of the table of diagnose_model() whose value is TRUE or FALSE.
.acl_diagnosis_flags <- c("Parameter boundary hit", "Optimizer converged", "Positive-definite Hessian",
                          "Numerical checks passed", "Natural-scale boundary")

#' @rdname diagnose_model
#' @export
print.alscl_diagnosis <- function(x, digits = 4L, ...) {
  values <- as.numeric(x$Value)
  shown <- .acl_signif_text(values, digits)
  flags <- x$Metric %in% .acl_diagnosis_flags
  shown[flags] <- ifelse(is.na(values[flags]), "NA", ifelse(values[flags] != 0, "TRUE", "FALSE"))
  shown[!flags & is.na(values)] <- "NA"
  table <- data.frame(Metric = x$Metric, Value = formatC(shown, width = max(nchar(c(shown, "Value")))))
  print(table, row.names = FALSE, right = FALSE)
  .acl_cat_wrapped(paste(
    "MSE, RMSE: mean squared error and its square root; MAE: mean absolute error; MAD: mean absolute",
    "deviation of the observations from their mean; MASE: MAE divided by the mean absolute change",
    "between adjacent time steps; Rsquared: coefficient of determination; MAPE, SMAPE: mean absolute",
    "percentage error and its symmetric form; AIC, BIC: Akaike and Bayesian information criteria.",
    "The errors compare observed and fitted survey indices; see ?diagnose_model."), before = "")
  invisible(x)
}
