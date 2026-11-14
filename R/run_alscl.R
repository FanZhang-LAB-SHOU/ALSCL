#' Fit the ALSCL survey catch-at-length model
#' @param data.CatL Data frame or matrix with length labels in its first column,
#'   followed by at least two numerically labelled time columns. Alternatively, a
#'   named input bundle such as YTF_example; see Details.
#' @param data.wgt Weight-at-length, with identical labels, columns and dimensions.
#' @param data.mat Maturity-at-length between 0 and 1, with the same layout.
#' @param rec.age Recruitment age in years, greater than t0.
#' @param nage Number of age classes including the plus group (at least two).
#' @param M Nonnegative natural mortality rate (M) per model time step (for
#'   quarterly time steps, the annual rate divided by 4), in one of three
#'   forms. A single number is one rate for all lengths, ages and time steps.
#'   A matrix with one row per age class (`nage` rows) and one column per
#'   time step, or one column that is used for every time step, is M by age
#'   and time step. A numeric vector with one value per length bin is M by
#'   length, the same for all ages and time steps; [lorenzen_M()] computes
#'   such a vector. The `dim` attribute tells the last two forms apart. An
#'   object with two dimensions is read as M by age, also when it has one
#'   column, and a vector without dimensions is read as M by length. M by age
#'   that is constant over time is therefore `matrix(M_at_age, ncol = 1)`.
#'   Any other object is rejected with the expected dimensions. See Details.
#' @param sel_L50,sel_L95 Lengths at 50 and 95 percent survey catchability,
#'   which define a logistic survey catchability curve with a maximum of 1.
#'   Leave both as NULL when `survey_q` is supplied.
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
#' @details Starting values are estimated unless mapped as fixed. ALSCL defaults fix
#'   log_sigma_log_F and log_t0, leaving 13 free scalar parameters. To release
#'   one, pass map = list(log_sigma_log_F = NULL) directly.
#'   Single-bracket assignment such as `map["name"] <- list(NULL)` preserves a
#'   release; `map$name <- NULL` deletes it and can restore a default fix.
#'   M, survey catchability, weights, maturity and age/bin settings are supplied
#'   inputs, not estimable parameters. Random deviations are constructed
#'   internally and are not listed in the outer optimizer's opt$par.
#' @details Since 2.2.0, `run_alscl(x)` accepts a named list of fitting
#'   arguments or a structured bundle such as [YTF_example]. A structured bundle
#'   contains data.CatL, data.wgt and data.mat, shared settings in fit_args, and
#'   optional model settings in fit_config$alscl. Settings are resolved in this
#'   order: data tables, fit_args, selected fit_config, explicit call arguments
#'   (highest priority). Explicit parameters, map and control replace the entire
#'   corresponding list; NULL is preserved. Other top-level fields in a structured
#'   bundle, including simulation parameters and truth, are not fitting settings.
#'   The original separate-argument and do.call interfaces remain supported.
#'   Both interfaces use the same fitting and standard-error acceleration.
#' @examples
#' \donttest{
#' # One fishing mortality rate (F) shared by all lengths in each year keeps
#' # this example short. The default, F by length and year, takes several
#' # times longer for these data.
#' x <- YTF_example
#' fit <- run_alscl(x, F_structure = "year", silent = TRUE)
#' fit
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
#' @param structure Optional model structures: the name of a set or a named
#'   list of settings. The default, an empty list, and `"original"` are the
#'   original structure for every setting: the structure of the package as
#'   first released, which implements the model of Zhang and Cadigan (2022).
#'   `"von_bertalanffy"` selects `growth_increment = "von_bertalanffy"`,
#'   `growth_transition = "bin"`, `initial_length = "growth"` and
#'   `initial_plus_group = "equilibrium"` together, so that the first period
#'   and the growth transition follow one growth model. A list can name a set
#'   and add single settings, for example
#'   `list(set = "von_bertalanffy", correlation_range = "symmetric")`.
#'   `"published"` and `"consistent"` are accepted as the earlier names of
#'   `"original"` and `"von_bertalanffy"`.
#'
#'   The four settings of `"von_bertalanffy"` were tested as a set. A fit
#'   with only some of them can fail when the growth increment per time step
#'   is small relative to the bin width. A `structure` list that changes
#'   one, two or three of the four settings therefore gives a message that
#'   names the settings left at their original values (unless
#'   `silent = TRUE`; a function that runs several fits in one call gives it
#'   once). `"von_bertalanffy"` is the name of the set and also a value of
#'   the single setting `growth_increment`.
#'   `structure = list(growth_increment = "von_bertalanffy")` changes one
#'   setting, and `structure = "von_bertalanffy"` changes all four. A list
#'   that names the set and replaces one of its settings, for example
#'   `list(set = "von_bertalanffy", growth_transition = "midpoint")`, is
#'   taken as a deliberate choice and gives no message. `correlation_range`
#'   does not belong to the set. Settings and values (default first):
#'   \describe{
#'   \item{`growth_increment`}{`"logistic"`: the expected growth increment is a
#'     decreasing logistic function of length, multiplied by `growth_step`.
#'     Zhang and Cadigan (2022) define this function. They give neither the
#'     lengths at which the increment is 50% and 95% of its maximum nor the
#'     conversion of the increment to a time step shorter than one year. The
#'     lengths 0.5 Linf and 0.05 Linf and the multiplication by `growth_step`
#'     are those of the code.
#'     `"von_bertalanffy"`: the expected increment over one time step is
#'     (Linf - L)(1 - exp(-vbk * growth_step)) for length L below Linf and
#'     declines smoothly to zero above Linf, so Linf and vbk have the same
#'     meaning as in the length-at-age curve. Fish then stop growing at about
#'     Linf, so Linf acts as an upper limit of length after the first period:
#'     data with many fish larger than the mean asymptotic length fit poorly,
#'     and the standard error of Linf can be very small. The logistic
#'     increment stays positive above Linf.}
#'   \item{`growth_transition`}{`"midpoint"`: every fish in a length bin grows
#'     from the bin midpoint. `"bin"`: starting lengths are uniform within the
#'     bin and the transition is integrated over the bin, so fish keep moving
#'     to the next bin when the increment per time step is small relative to
#'     the bin width (for example quarterly steps with wide bins). The mean
#'     length of a cohort then follows the growth curve closely for bins a
#'     few times wider than the increment; with much wider bins it remains
#'     approximate, because fish are spread evenly over their bin after every
#'     step.}
#'   \item{`initial_length`}{`"length_at_age"`: in the first period every age
#'     has the length-at-age distribution with coefficient of variation
#'     cv_len. `"growth"`: the first age has that distribution and each older
#'     age is the previous age after survival at init_Z and one growth step,
#'     as in all later periods.}
#'   \item{`initial_plus_group`}{`"single_cohort"`: the first-period plus group
#'     holds one cohort. `"equilibrium"`: it holds the sum of all older cohorts
#'     at total mortality init_Z.}
#'   \item{`correlation_range`}{`"positive"`: the AR(1) correlations of
#'     recruitment and of F over time and length lie between 0 and 1, as the
#'     logistic transform of the `logit_*` parameters. `"symmetric"`: they
#'     lie between -1 and 1, as 2 * logistic - 1, so a `logit_*` value of 0
#'     means no correlation and negative correlation can be estimated. A
#'     `logit_*` start or fixed value has a different meaning under the two
#'     settings: a correlation rho is `qlogis(rho)` under `"positive"` and
#'     `qlogis((rho + 1) / 2)` under `"symmetric"`.}
#'   }
#'   With `initial_length = "growth"` and `initial_plus_group = "equilibrium"`
#'   a population with constant recruitment, no fishing and init_Z equal to M
#'   stays constant over time; with the original structure it does not.
#'   The settings used are stored in the `structure` element of the fit.
#' @param t0_lower Lower limit of the von Bertalanffy parameter t0 in years.
#'   The model uses t0 = t0_lower + exp(log_t0). The default 0 is the original
#'   parameterization, in which t0 is positive. Set a negative value, for
#'   example -1, to allow negative t0; a known t0 is then supplied as
#'   `parameters = list(log_t0 = log(t0 - t0_lower))`. Reported t0 values are
#'   always on the natural scale.
#' @param start_spread Standard deviation of the normal deviates added to the
#'   starting values (on the scale of the optimizer, mostly logarithms) of
#'   the second and later starts. The default 0.15 keeps the starts used by
#'   earlier versions. See Details for when to use a larger value.
#' @details With `growth_transition = "midpoint"` every fish of a length bin
#'   grows from the bin midpoint. Growth then stops at the length where the
#'   increment in one time step falls well below half the bin width, whatever
#'   the value of Linf; this happens with short time steps and wide bins (for
#'   example quarterly steps with 5 cm bins, or annual steps with 5 cm bins
#'   for a slow-growing stock). The fit stores `growth_check`. When the
#'   fitted transition has a length bin, with a midpoint below 90% of the
#'   estimated Linf, in which fish stay with a probability of at least 0.99
#'   per time step, the fit reports it in a message (unless `silent = TRUE`)
#'   and `summary()` prints it. Consider a refit with
#'   `structure = "von_bertalanffy"` in that case. The original structure and
#'   the `"von_bertalanffy"` set have the same number of parameters, so their
#'   objective values can be compared directly.
#' @details A single start can stop at a local optimum that passes every
#'   numerical check, particularly for the growth parameters of ALSCL. The
#'   checks in `diagnostics` are local: they do not show whether a better
#'   optimum exists. A fit with one start (`nstarts = 1`, the default)
#'   therefore gives a message unless `silent = TRUE`; a function that runs
#'   several fits in one call gives it once. For results that will be
#'   reported, use at least three starts (`nstarts = 3` or more) with a wider
#'   `start_spread` (for example 0.5) and compare the objectives in
#'   `start_diagnostics`. `start_summary`
#'   gives the number of converged starts, the range of their objectives and
#'   the number that agree with the best one; a range above 2 is added to
#'   `diagnostics$issues`.
#' @details Besides the gradient, the Hessian and the optimizer bounds, the
#'   numerical screen in `diagnostics` looks for parameters that are at their
#'   limit in practice although they have not reached a bound: `log_t0` below
#'   -10 (ALSCL; t0 then equals `t0_lower`), the logarithm of a standard
#'   deviation below -9 (a variance of zero) and a logit correlation with an
#'   absolute value above 15 (a correlation at the end of its range). Such a
#'   fit fails the screen (`numerical_ok = FALSE`), as a fit that stopped at
#'   a bound does. `diagnostics$limit_parameters` lists these parameters with
#'   their values on the natural scale and `diagnostics$advice` says what to
#'   do: fix the parameter with `map` at a chosen value and refit, or, for a
#'   correlation at zero, use
#'   `structure = list(correlation_range = "symmetric")`.
#'   `diagnostics$plausibility` lists notes that do not change the verdict of
#'   the screen: the mean length of recruits lies more than two length-bin
#'   widths below the lower border of the second length bin; the estimated
#'   standard deviation of the observation error on the log scale is above
#'   0.9; an estimated coefficient of variation of length at age (cv_len) or
#'   of the growth increment (cv_grow, ALSCL) is above 0.3 (the example range
#'   of cv_len in the Stock Synthesis manual is 0.10 to 0.25); the estimated
#'   initial total mortality rate is below the smallest natural mortality
#'   rate. Except for the mean length of recruits, the notes concern
#'   estimated parameters only, not values fixed with `map`. The thresholds
#'   are stored in `diagnostics$check_thresholds`. The messages of a fit and
#'   `summary()` show the advice and the notes.
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
#'   Unless supplied, the start of Linf is 1.1 times the largest length-bin
#'   midpoint and its bounds are 0.7 and 2 times that midpoint. Supply
#'   `parameters.L$log_Linf` when the bins extend well beyond the largest
#'   fish, because Linf below 0.7 times the largest midpoint is otherwise
#'   excluded.
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
#'   growth_check reports whether growth stops below Linf under the midpoint
#'   growth transition (stalled, the length and the probability of staying in
#'   that length bin per time step); see Details.
#'   Use summary(), extract_parameters(), extract_estimates(), save_assessment()
#'   and refit_model() for inspection, portable storage and reproducible refitting.
#' @param survey_q Optional survey catchability at length: a numeric vector
#'   with one positive value per length bin. It is used in place of the
#'   logistic curve from `sel_L50` and `sel_L95`, for example for a
#'   dome-shaped curve; [survey_catchability()] computes logistic and
#'   dome-shaped curves. A matrix with one row per length bin and one column
#'   per time step gives survey catchability by length and time step, for
#'   example after a change of survey gear; a matrix with one column is read
#'   as the vector. Supplying survey_q together with `sel_L50` or `sel_L95`
#'   is an error; when an input bundle or a stored fit already holds these
#'   two, add `sel_L50 = NULL, sel_L95 = NULL` to the call. The values are
#'   fixed inputs and are not estimated.
#' @param survey_q_age Optional survey catchability multiplier by age: a
#'   numeric vector with one positive value per age class. The default NULL
#'   is 1 for every age. The expected survey index at length is then
#'   q(length) times the sum over ages of `survey_q_age[age]` times numbers
#'   at that length and age, where q(length) is the survey catchability at
#'   length from `sel_L50` and `sel_L95` or from `survey_q`. When
#'   `survey_q_age` is supplied and `parameters` holds no start for
#'   mean_log_R, the default start of mean_log_R is raised by
#'   `-log(survey_q_age[1])`, because the survey then sees only that
#'   fraction of the recruits.
#' @details With M by age and time step or by length, M replaces the single
#'   rate in survival, in the catch equation and in total mortality (Z) and F
#'   at age. In the plus group, the fish that enter from the age before it and
#'   the fish already in it each have the M of their own age class. Two
#'   reported quantities then need a definition, because fish of one age have
#'   different lengths and fish of one length have different ages. F at age
#'   (`FA`) is Z at age minus the mean of M over lengths, weighted by the
#'   numbers at length of that age. Z at length (`ZL`) is F at length plus
#'   the mean of M over ages, weighted by the numbers at age of that length;
#'   it is a summary and not the rate that any one age experiences. The
#'   report holds the rates used as `M_LAY` (length by age by time step).
#'   The default start of init_Z uses the median of M in the first time
#'   step. A constant given in a non-scalar form, `survey_q` equal to the
#'   logistic curve, a `survey_q` matrix with equal columns, or
#'   `survey_q_age` of ones gives the fit of the default inputs up to
#'   rounding error.
#'
#'   M is an assumption. The survey index informs Z but not its split into
#'   fishing and natural mortality, so an error in M enters F directly, and
#'   the objective of a fit is not a basis for choosing M. Supply M by age and
#'   time step only when independent estimates exist, for example from a
#'   multispecies model. `survey_q` and `survey_q_age` are assumptions of the
#'   same kind. A survey catchability that declines with length or age is
#'   otherwise fitted as higher mortality.
#' @export
#' @param len_lower,len_upper Optional bounds consistent with len_border and len_mid.
#'   The first lower boundary must be -Inf and the last upper boundary must be
#'   Inf: outer bins absorb the distribution tails. Finite outer bounds are
#'   rejected because finite truncation is not supported. Leave both as NULL
#'   to construct open-ended bounds from len_border. Numeric interval labels
#'   describe bin centers and interior boundaries; they do not truncate the tails.
#' @details ALSCL tracks joint length-age abundance and F at length; FA summarizes
#'   effective cohort survival. log_t0 represents a positive t0 below rec.age.
run_alscl <- function(data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50 = NULL, sel_L95 = NULL,
                      growth_step = NULL, parameters = NULL, parameters.L = NULL, parameters.U = NULL,
                      map = NULL, len_mid = NULL, len_border = NULL, len_lower = NULL, len_upper = NULL,
                      output = FALSE, train_times = 1, ncores = 1, silent = FALSE,
                      zero_action = c("missing", "error"), control = list(), nstarts = ncores,
                      F_structure = c("group_year", "year"), polish = TRUE,
                    structure = list(), start_spread = 0.15, t0_lower = 0,
                    survey_q = NULL, survey_q_age = NULL) {
  if (is.list(data.CatL) && !is.data.frame(data.CatL))
    return(.acl_fit_bundle(data.CatL, "alscl", match.call(), environment()))
  prepared <- .acl_prepare_data(data.CatL, data.wgt, data.mat, rec.age, nage, M,
    sel_L50, sel_L95, growth_step, len_mid, len_border, len_lower, len_upper, zero_action,
    structure, start_spread, t0_lower, survey_q, survey_q_age)
  result <- .acl_fit("ALSCL", prepared, parameters, parameters.L, parameters.U, map,
           train_times, ncores, silent, output, control, nstarts, F_structure, polish)
  .acl_attach_recipe(result, model = "alscl",
    args = mget(names(formals(run_alscl)), envir = environment(), inherits = FALSE))
}
