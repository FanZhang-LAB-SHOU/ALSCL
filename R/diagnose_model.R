#' Diagnose a fitted assessment model
#' @param data.CatL Length labels followed by time columns.
#' @param model_result A fitted model result.
#' @return A data frame of fit metrics and convergence diagnostics.
#' @details Reports the optimizer convergence code, maximum absolute gradient,
#'   boundary status and Hessian positive definiteness separately. A successful
#'   optimizer code alone does not establish reliable statistical inference.
#'   Input observations are checked against available fitted time, length and
#'   observation metadata by \code{diagnostic_metrics()}; known mismatches are errors.
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
  result <- rbind(metrics, data.frame(Metric=c("Boundary Hit","Model Converged","Final Outer mgc","Positive Definite Hessian"),
                            Value=c(bound,if(is.na(code)) NA else code==0L,gradient,hessian)))
  if (!is.null(model_result$diagnostics)) {
    d <- model_result$diagnostics
    cat("Numerical screen:", d$numerical_ok, "\nNatural-scale boundary:",
        d$natural_boundary, "\nRefinement:", model_result$refinement$status, "\n")
    result <- rbind(result, data.frame(Metric = c("Numerical Screen Passed",
      "Natural Scale Boundary", "Covariance Condition", "Highly Correlated Pairs"),
      Value = c(d$numerical_ok, d$natural_boundary, d$covariance_condition, nrow(d$high_correlations))))
  }
  result
}
