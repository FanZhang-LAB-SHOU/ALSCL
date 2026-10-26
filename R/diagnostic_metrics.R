#' Compute survey-fit and information-criterion diagnostics
#' @param data.CatL Length labels followed by time columns.
#' @param model_result A fitted ACL or ALSCL result.
#' @return A data frame with Metric and Value. Undefined metrics are NA.
#' @details Only finite positive observations are included. MASE divides MAE by
#'   the pooled absolute one-step differences within each length-bin time series;
#'   pairs containing missing or zero observations are excluded. MAD is the mean
#'   absolute deviation of observations about their mean.
#'   These are in-sample diagnostics: known time labels, length-bin order,
#'   positive-observation masks and values must match the fitted result. Older
#'   results without this metadata remain usable, but their alignment cannot be
#'   fully verified. Nonfinite predictions at observed cells are rejected,
#'   including overflow when converting log predictions to the response scale.
#' @export
diagnostic_metrics <- function(data.CatL, model_result) {
  values <- .acl_survey_metrics(data.CatL, model_result)
  # Retain the public metric names and ordering; SD_log_resid is an additional
  # internal metric used by compare_models().
  values <- values[names(values) != "SD_log_resid"]
  data.frame(Metric=names(values),Value=unname(values),row.names=NULL)
}

.acl_survey_metrics <- function(data.CatL, model_result) {
  survey <- .acl_survey_data(data.CatL)
  .acl_validate_survey_fit(model_result, survey)
  observed <- survey$observed; idx <- survey$mask
  predicted <- exp(model_result$report$Elog_index)
  obs <- observed[idx]; pred <- predicted[idx]; errors <- obs - pred
  mse <- mean(errors^2); mae <- mean(abs(errors)); sst <- sum((obs-mean(obs))^2)
  scale <- NA_real_
  if (ncol(observed) > 1L) {
    pairs <- idx[, -1L, drop=FALSE] & idx[, -ncol(idx), drop=FALSE]
    differences <- abs(observed[, -1L, drop=FALSE] - observed[, -ncol(observed), drop=FALSE])
    if (any(pairs)) scale <- mean(differences[pairs])
  }
  npar <- .acl_npar(model_result)
  nll <- model_result$opt$objective
  if (!is.numeric(nll) || length(nll) != 1L || !is.finite(nll)) nll <- NA_real_
  values <- c(MSE=mse, MAE=mae, MAD=mean(abs(obs-mean(obs))),
    MASE=if(is.finite(scale) && scale>0) mae/scale else NA_real_, RMSE=sqrt(mse),
    Rsquared=if(sst>0) 1-sum(errors^2)/sst else NA_real_, MAPE=100*mean(abs(errors/obs)),
    SMAPE=100*mean(2*abs(errors)/(abs(obs)+abs(pred))),
    'Explained Variance Score'=if(length(obs)>1L && stats::var(obs)>0) 1-stats::var(errors)/stats::var(obs) else NA_real_,
    'Max Error'=max(abs(errors)), AIC=2*npar+2*nll, BIC=npar*log(length(obs))+2*nll,
    # Use the fitted log prediction directly to avoid taking log(0) after
    # response-scale underflow of a finite log prediction.
    SD_log_resid=stats::sd(log(obs)-model_result$report$Elog_index[idx]))
  values
}
.acl_max_gradient <- function(m) {
  x <- m$gradient
  if (is.null(x)) x <- m$max_abs_gradient
  if (is.null(x)) x <- m$final_outer_mgc
  if (is.null(x) || !length(x) || any(!is.finite(x))) return(NA_real_)
  max(abs(x))
}
