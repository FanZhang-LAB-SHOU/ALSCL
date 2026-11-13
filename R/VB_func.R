#' @title Von Bertalanffy growth function
#' @description Calculate length at age using the von Bertalanffy growth function.
#' @param Linf The asymptotic length.
#' @param k The growth coefficient.
#' @param t0 The theoretical age at zero length.
#' @param age Age of the fish.
#' @return Length at age.
#' @examples
#' # Length at ages 1 to 15 with the yellowtail flounder parameters in YTF
#' VB_func(Linf = YTF$Linf, k = YTF$vbk, t0 = YTF$t0, age = 1:15)
#' @export
VB_func <- function(Linf, k, t0, age) {
  Lt = Linf * (1 - exp(-k * (age - t0)))
  return(Lt)
}
