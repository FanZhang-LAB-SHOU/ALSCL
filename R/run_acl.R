#' Fit the ACL survey catch-at-length model
#' @param data.CatL Data frame or matrix with length labels in its first column,
#'   followed by at least two numerically labelled time columns. Alternatively, a
#'   named input bundle such as YTF_example; see Details.
#' @param data.wgt Weight-at-length, with identical labels, columns and dimensions.
#' @param data.mat Maturity-at-length between 0 and 1, with the same layout.
#' @param rec.age Recruitment age in years, greater than t0.
#' @param nage Number of age classes including the plus group (at least two).
#' @param M Nonnegative natural mortality per model time step.
#' @param sel_L50,sel_L95 Lengths at 50 and 95 percent survey catchability.
#' @param parameters Named list of initial fixed-effect values.
#' @param parameters.L,parameters.U Named lower and upper bounds. Bounds are aligned
#'   with free parameters after applying map. Initial free values are clamped to bounds.
#' @param map Named TMB factor mappings. factor(NA) fixes a parameter at its supplied
#'   value; a named NULL entry releases that parameter. A whole map = NULL or
#'   list() applies model defaults. Other unspecified defaults remain in force.
#' @param len_mid Finite length-bin midpoints; overrides automatic parsing.
#' @param len_border Interior boundaries, one fewer than the number of length bins.
#' @param output Save diagnostic tables and plots below output/ when TRUE.
#' @param train_times Positive integer; exact number of optimization passes per start.
#' @param ncores Positive integer; maximum number of socket workers for fitting
#'   independent starts. Uses at most nstarts workers; not threads within one start.
#' @param nstarts Positive integer; number of independent starts. Defaults to
#'   ncores for backward compatibility. Set explicitly to compare worker counts
#'   at equal work. Start 1 uses supplied values; later starts deterministically
#'   jitter free parameters only, identically for sequential and parallel fits.
#' @param silent Suppress fitting progress messages when TRUE.
#' @param growth_step Time between consecutive ages, in years. Use 0.25 for quarters.
#'   NULL uses rec.age when it is below one, otherwise one.
#'   Numeric time-column labels must have this spacing. Keep missing periods as
#'   NA survey columns, with weights and maturity supplied for every period.
#' @param zero_action Exclude zero observations as missing (historical behavior),
#'   or reject them with "error". NA is always missing; negative/infinite values fail.
#' @param control A named list of nlminb control settings.
#' @details M and F are per model time step; vbk is per year. The first and last
#'   length bins absorb the distribution tails. Compilation uses a writable session
#'   cache. Optimizer success, gradient size, Hessian status and boundary hits should
#'   be assessed separately before interpreting estimates or uncertainty.
#' @details Starting values are estimated unless mapped as fixed. ACL defaults fix
#'   log_std_log_F, logit_log_F_y, logit_log_F_a and t0, leaving 10 free scalar
#'   parameters. To release one, pass map = list(log_std_log_F = NULL) directly.
#'   Single-bracket assignment such as `map["name"] <- list(NULL)` preserves a
#'   release; `map$name <- NULL` deletes it and can restore a default fix.
#'   M, survey catchability, weights, maturity and age/bin settings are supplied
#'   inputs, not estimable parameters. Random deviations are constructed
#'   internally and are not listed in the outer optimizer's opt$par.
#' @details Since 2.2.0, `run_acl(x)` accepts a named list of fitting
#'   arguments or a structured bundle such as [YTF_example]. A structured bundle
#'   contains data.CatL, data.wgt and data.mat, shared settings in fit_args, and
#'   optional model settings in fit_config$acl. Settings are resolved in this
#'   order: data tables, fit_args, selected fit_config, explicit call arguments
#'   (highest priority). Explicit parameters, map and control replace the entire
#'   corresponding list; NULL is preserved. Other top-level fields in a structured
#'   bundle, including simulation parameters and truth, are not fitting settings.
#'   The original separate-argument and do.call interfaces remain supported.
#'   Both interfaces use the same fitting and standard-error acceleration.
#' @examples
#' \donttest{
#' x <- YTF_example
#' fit <- run_acl(x, silent = TRUE)
#' fit
#'
#' # Two independent starts; compare their objectives
#' fit <- run_acl(x, nstarts = 2, silent = TRUE)
#' fit$start_diagnostics[, c("start_id", "objective", "convergence")]
#' }
#' @param F_structure Fishing-mortality structure. `"group_year"` (default)
#'   retains the age-by-year (ACL) or length-by-year (ALSCL) AR(1) field.
#'   `"year"` uses one shared F per time step with a one-dimensional AR(1)
#'   density; the unused group correlation is automatically fixed and omitted
#'   from reports. Other default map rules still apply. Subannual data share F
#'   per model step, not per calendar year.
#' @param polish Logical. By default, apply up to five safeguarded Newton steps
#'   to the selected fit, requiring a positive-definite Hessian, in-bounds
#'   parameters, a smaller maximum gradient and objective increase at most
#'   `1e-8` (roundoff tolerance). FALSE skips refinement. Raw optimizer codes
#'   remain unchanged; inspect `optimizer_history`, `refinement`, and
#'   `diagnostics` separately. This may change estimates at numerical precision.
#'   On checked TMB versions, the refinement Hessian shares the sd_cores limit
#'   when forked processes are selected; other sessions compute it sequentially.
#'   refinement$hessian_calculations records methods, cores and fallback notes.
#' @param structure Named list of optional model structures. The default, an
#'   empty list, is the published structure of Zhang and Cadigan (2022).
#'   ACL has one setting, `initial_plus_group`: `"single_cohort"` (default;
#'   the first-period plus group holds one cohort) or `"equilibrium"` (it
#'   holds the sum of all older cohorts at total mortality init_Z, so a
#'   population with constant recruitment, no fishing and init_Z equal to M
#'   stays constant over time). `correlation_range`: `"positive"` (default;
#'   AR(1) correlations between 0 and 1, the logistic transform of the
#'   `logit_*` parameters) or `"symmetric"` (between -1 and 1, as
#'   2 * logistic - 1; a correlation rho is then `qlogis((rho + 1) / 2)` on the
#'   optimizer scale). The settings used are stored in the `structure`
#'   element of the fit.
#' @param start_spread Standard deviation of the normal deviates added to the
#'   starting values (on the scale of the optimizer, mostly logarithms) of
#'   the second and later starts. The default 0.15 keeps the starts used by
#'   earlier versions. See Details for when to use a larger value.
#' @details A single start can stop at a local optimum that passes every
#'   numerical check, particularly for the growth parameters of ALSCL. The
#'   checks in `diagnostics` are local: they do not show whether a better
#'   optimum exists. For results that will be reported, use several starts
#'   (for example `nstarts = 5`) with a wider `start_spread` (for example
#'   0.5) and compare the objectives in `start_diagnostics`. `start_summary`
#'   gives the number of converged starts, the range of their objectives and
#'   the number that agree with the best one; a range above 2 is added to
#'   `diagnostics$issues`.
#' @details The process densities are evaluated on the complete arrays of
#'   deviations. A map that ties entries of dev_log_R, dev_log_F or dev_log_N0
#'   to shared values, or fixes entries with NA, is therefore accepted only
#'   when the matching standard deviation and correlation parameters are fixed
#'   too; otherwise their estimates would be biased and the fit is rejected.
#'   For one F deviation per time step shared by all groups, use
#'   `F_structure = "year"`, which has its own correctly normalized density.
#'   With tied entries the shared value has a smaller prior standard deviation
#'   than the stated one, and the objective of a fit with tied or fixed
#'   entries cannot be compared (for example by AIC) with fits that use
#'   another map for these deviations. `restricted_random` in the fit names
#'   the arrays concerned.
#' @details Starting values outside their bounds are moved to the nearest
#'   bound: with a warning when the start was supplied, and with a message for
#'   default starts. `clamped_starts` in the fit lists them.
#'   The default start (60) and bounds (10 to 100) of Linf are in the length
#'   units of the yellowtail flounder example. When the upper bound is below
#'   1.2 times the largest length-bin midpoint, or the start is outside 0.7 to
#'   2 times that midpoint, the start and bounds that were not supplied are
#'   set from the data. The start is 1.1 times the length below which 99
#'   percent of the summed survey index lies, the upper bound is 2 times the
#'   largest midpoint, and the lower bound is the smaller of the default (10)
#'   and half of that 99 percent length, so that length bins extending beyond
#'   the largest fish do not exclude the true Linf.
#' @return An alscl_fit list (legacy dollar access is unchanged) with report,
#'   opt, obj, est_std, vcov, pdHess, gradient,
#'   max_abs_gradient (also final_outer_mgc), convergence_code, bound_hit,
#'   year, age, length-bin metadata, growth_step, elapsed and multi-start diagnostics.
#'   start_diagnostics records each start's PID, Unix start/end times, elapsed
#'   and CPU seconds, objective and convergence code; workers and nstarts record
#'   the actual worker count and total starts. The lowest finite objective is
#'   selected; inspect convergence diagnostics separately.
#'   sd_info records how the standard errors were computed: method (forked
#'   processes, socket workers for the delta method, or sequential), cores, elapsed
#'   seconds and a note; see \code{\link{alscl_speed}}.
#'   The DLL remains loaded so the returned obj can be evaluated in the same session.
#'   After standard-error calculation, obj is restored to the final fitted
#'   parameters, including sequential and fallback paths. Its report describes
#'   the same fitted state as report. Saved estimates and standard errors are
#'   unchanged by this restoration; refit serialized results before using obj.
#'   recipe stores the complete resolved fitting inputs and software settings.
#'   Use summary(), extract_parameters(), extract_estimates(), save_assessment()
#'   and refit_model() for inspection, portable storage and reproducible refitting.
#' @export
run_acl <- function(data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95,
                    parameters = NULL, parameters.L = NULL, parameters.U = NULL,
                    map = NULL, len_mid = NULL, len_border = NULL, output = FALSE,
                    train_times = 1, ncores = 1, silent = FALSE, growth_step = NULL,
                    zero_action = c("missing", "error"), control = list(), nstarts = ncores,
                      F_structure = c("group_year", "year"), polish = TRUE,
                    structure = list(), start_spread = 0.15) {
  if (is.list(data.CatL) && !is.data.frame(data.CatL))
    return(.acl_fit_bundle(data.CatL, "acl", match.call(), environment()))
  prepared <- .acl_prepare_data(data.CatL, data.wgt, data.mat, rec.age, nage, M,
    sel_L50, sel_L95, growth_step, len_mid, len_border, zero_action = zero_action,
    structure = structure, start_spread = start_spread)
  result <- .acl_fit("ACL", prepared, parameters, parameters.L, parameters.U, map,
           train_times, ncores, silent, output, control, nstarts, F_structure, polish)
  .acl_attach_recipe(result, model = "acl",
    args = mget(names(formals(run_acl)), envir = environment(), inherits = FALSE))
}
