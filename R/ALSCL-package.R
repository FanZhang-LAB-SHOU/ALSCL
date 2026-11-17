#' @description
#' ALSCL fits two stock assessment models to survey abundance indices at
#' length with Template Model Builder (TMB): the age-structured
#' catch-at-length model (ACL) and the age- and length-structured
#' statistical catch-at-length model (ALSCL) of Zhang and Cadigan (2022). It
#' estimates recruitment, fishing mortality and stock size over time, and
#' checks, plots, compares, projects and simulates the fits.
#'
#' @section Functions to start with:
#' \describe{
#'   \item{[run_acl()] and [run_alscl()]}{Fit the ACL or the ALSCL model to
#'     an input bundle such as [YTF_example].}
#'   \item{[diagnose_model()]}{Fit statistics and numerical checks of a fit.}
#'   \item{[plot_SSB()]}{Spawning stock biomass over time; the other
#'     `plot_` functions draw the other estimates and the diagnostics.}
#'   \item{[extract_estimates()]}{Estimates, standard errors and confidence
#'     intervals of the time series as a table.}
#' }
#'
#' @section Tutorials:
#' The website \url{https://fanzhang-lab-shou.github.io/ALSCL/} has the
#' tutorials, for example
#' \href{https://fanzhang-lab-shou.github.io/ALSCL/articles/getting-started.html}{Install ALSCL and run a first fit},
#' \href{https://fanzhang-lab-shou.github.io/ALSCL/articles/first-model.html}{Understand your first fit},
#' \href{https://fanzhang-lab-shou.github.io/ALSCL/articles/data-preparation.html}{Prepare your survey data}
#' and
#' \href{https://fanzhang-lab-shou.github.io/ALSCL/articles/diagnostics.html}{Judge whether a fit can be used}.
#'
#' @references Zhang, F. and Cadigan, N. G. (2022). An age- and
#'   length-structured statistical catch-at-length model for hard-to-age
#'   fisheries stocks. Fish and Fisheries, 23(5), 1121-1135.
#'   \doi{10.1111/faf.12673}
#'
#' @examples
#' \donttest{
#' # Fit the ACL model to the bundled example, check it and plot one estimate
#' fit <- run_acl(YTF_example, silent = TRUE)
#' fit
#' diagnose_model(YTF_example$data.CatL, fit)
#' plot_SSB(fit, se = TRUE)
#' head(extract_estimates(fit, "SSB"))
#' }
"_PACKAGE"

#' @importFrom stats arima.sim nlminb pnorm rnorm var fitted logLik nobs
#' @importFrom scales pretty_breaks
#' @importFrom utils head modifyList tail write.csv
#' @importFrom ggplot2 ggplot aes geom_line geom_point geom_ribbon geom_tile
#'   geom_smooth geom_hline geom_text facet_wrap labs theme theme_minimal
#'   element_text scale_fill_gradient ggsave
#' @importFrom dplyr mutate group_by filter summarise ungroup first pull distinct %>%
#' @importFrom tidyr pivot_longer
#' @importFrom TMB compile MakeADFun sdreport
#' @importFrom RColorBrewer brewer.pal
NULL

# Suppress R CMD check notes for non-standard evaluation variables
utils::globalVariables(c(
 "Year", "Variable", "Value", "RetrospectiveYear", "Rho",
 "estimate", "lower", "upper",
 "Count", "Abundance", "LengthGroup", "AgeGroup",
 "number.age", "residual", "variable", "value",
 "SSB", "Rec", "age", "length_lower", "length_upper",
 "len_mid", "sim.data",
 "number", "biomass", "recruitment", "CN", "CNA", "F"
))
