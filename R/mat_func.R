#' @title Maturation function
#' @description Calculate maturation probability based on the length of the fish.
#' @param L50 Length at which 50% of individuals are mature.
#' @param L95 Length at which 95% of individuals are mature.
#' @param length Length of the fish.
#' @return Maturation probability.
#' @details L50 and L95 must be distinct finite scalars. A decreasing curve
#'   (L95 below L50) is supported for descending selectivity limbs. Stable
#'   logistic evaluation retains probabilities of zero or one in extreme tails.
#' @export
mat_func <- function(L50, L95, length) {
  .acl_scalar(L50, "L50")
  .acl_scalar(L95, "L95")
  if (L50 == L95) stop("L50 and L95 must be distinct.", call. = FALSE)
  if (!is.numeric(length) || any(!is.finite(length)))
    stop("length must contain finite numeric values.", call. = FALSE)
  stats::plogis(log(19) * (length - L50) / (L95 - L50))
}
