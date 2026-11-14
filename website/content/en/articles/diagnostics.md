# Judge whether a fit can be used

On this page you check a fit from four sides: the numerical checks of the optimizer, the residual patterns, the comparison with other configurations, and the sensitivity to the fixed values. You need the objects of [Understand your first fit](first-model.html): the bundle `x`, the ACL fit `a` and the ALSCL fit `b`. The code uses `b`; it works the same for `a`.

<h2 id="numerical">1. Numerical checks</h2>

```r
diagnose_model(x$data.CatL, b)
b$diagnostics$issues
b$diagnostics$high_correlations
b$refinement$status
b$start_diagnostics
```

`diagnose_model()` prints the raw optimizer code, maximum absolute gradient, Hessian and covariance status, and parameter-boundary checks. The numerical screen uses a gradient threshold of 0.001, positive-definite Hessian and covariance matrices, the boundary checks and the check for parameters at their limit in practice (next subsection); the raw optimizer code is reported separately. `b$diagnostics$issues` lists all diagnostic flags. `high_correlations` lists parameter pairs with an absolute estimated correlation of at least 0.95, including negative correlations. These pairs warrant checking parameter identifiability with profiles, additional starts or sensitivity analyses. `b$refinement` records the finishing Newton steps (`status = "gradient_tolerance"` when that criterion was met), and `b$start_diagnostics` records the objective for each start.

When a check fails, change one thing at a time: run more starts (`nstarts = 4`), inspect parameter scales and bounds, and use profiles to investigate poorly determined parameters. If the evidence supports it, fix a parameter or share F across groups (`F_structure = "year"`), as described in [Fitting controls](fitting-controls.html). Compare the revised fit with the original in step 3. Passing the numerical screen does not establish a unique or global optimum, parameter identifiability or an adequate model. A single start can stop at a local optimum that passes every check, so for results that will be reported run several starts with a wider `start_spread` and read `b$start_summary` ([Choose the fitting settings](fitting-controls.html#optimizer)). [Carvalho et al. (2021), section 2.1](https://repository.library.noaa.gov/view/noaa/32687/noaa_32687_DS1.pdf) explains why several diagnostics are needed.

<h3 id="limits">Parameters at their limit, advice and plausibility notes</h3>

```r
# A fit that fails: the correlation of F across ages is released and runs to 1
cfg <- x$fit_config$acl
cfg$map["logit_log_F_a"] <- list(NULL)
a_limit <- run_acl(x, map = cfg$map, silent = TRUE)
a_limit$diagnostics$numerical_ok
a_limit$diagnostics$limit_parameters[, c("parameter", "estimate", "natural")]
a_limit$diagnostics$advice
# A fit that passes with a note: M is set above the initial total mortality rate
a_note <- run_acl(x, M = 0.5, silent = TRUE)
a_note$diagnostics$numerical_ok
a_note$diagnostics$plausibility[, c("check", "parameter", "value", "threshold")]
a_note$diagnostics$plausibility$note
a_note$diagnostics$check_thresholds
```

A parameter can be at its limit without reaching an optimizer bound: it runs so far on the optimizer scale that its natural value equals the limit. The numerical screen fails such a fit, as it fails a fit that stopped at a bound. Three cases are checked. `log_t0` below -10 (ALSCL) means that `t0` equals its lower limit `t0_lower`. The logarithm of a standard deviation below -9 means a variance estimated at zero. A logit correlation with an absolute value above 15 means a correlation at the end of its range. `diagnostics$limit_parameters` lists these parameters with their estimates and natural values, and `diagnostics$issues` names them. In the first fit of the block the correlation of F across ages is estimated at 19.1 on the logit scale, a correlation of 1, and `numerical_ok` is `FALSE`. R also warns that NaNs were produced, because the covariance matrix of this fit is not positive definite.

`diagnostics$advice` says what to do, and the messages of the fit, `print()` and `summary()` show it. A parameter estimated at a bound indicates a possible problem with the data or the model structure, and looking for such parameters is the first step of a convergence check ([Carvalho et al. 2021](https://doi.org/10.1016/j.fishres.2021.105959)). A parameter at its limit in practice is the same case without a bound. A variance estimated at zero should not be read as absence of variation; the usual practice is to fix or remove the parameter. The advice is therefore to fix the parameter with `map` at a value you can justify and to refit. Two cases have a further option: for a correlation at zero, `structure = list(correlation_range = "symmetric")` makes zero an interior value ([Choose the fitting settings](fitting-controls.html#correlation-range)), and for `t0` at `t0_lower`, a lower `t0_lower` allows a smaller `t0`. The advice also covers two upper bounds. An ACL fit that stops at one of the five default upper bounds that are below those of ALSCL is told to refit with `bounds = "wide"` ([Choose the fitting settings](fitting-controls.html#starts)), and a fit in which `t0` stops at its upper bound is told what that bound means.

Plausibility notes concern estimates that pass the numerical checks but have values that call for a check of the inputs. They do not change `numerical_ok`. The four checks are in the table. Except for the mean length of recruits, they apply to estimated parameters only, because a value fixed with `map` is an assumption and not a result of the fit. In the second fit of the block, `M = 0.5` is above the estimated initial total mortality rate of 0.49 per time step, so the fit passes and carries one note.

| Check | A note is given when | What to examine |
|---|---|---|
| `recruit_length` | The mean length of recruits, calculated from `Linf`, `k`, `t0` and `rec.age`, lies more than two length-bin widths below the lower border of the second length bin | Whether `rec.age` is the age of the smallest fish in the survey index, and the growth parameters |
| `observation_sd` | The estimated standard deviation of the observation error on the log scale is above 0.9 | The residuals, and the settings for growth and survey catchability |
| `growth_cv` | An estimated coefficient of variation of length at age (`cv_len`) or of the growth increment (`cv_grow`, ALSCL) is above 0.3. The example range of `cv_len` in the Stock Synthesis manual is 0.10 to 0.25; no published range is known for `cv_grow` | Fitted length at age against age data ([Assessment workflows](assessment-workflows.html#outputs)), or fix the parameter at a value from age data |
| `initial_Z` | The estimated initial total mortality rate is below the smallest natural mortality rate | `M`, the survey catchability, and whether recruitment increased before the first time step |

The thresholds are stored in `diagnostics$check_thresholds`. They are screening values chosen for this package and are not taken from the literature. `diagnose_model()` reports the number of parameters at their limit and the number of notes, and `summarize_simulations()` counts a parameter at its limit among the reasons for failure. A fit saved by an earlier version keeps its stored verdict.

<h2 id="residuals">2. Residual patterns</h2>

```r
plot_residuals(b, facet_by = "year", facet_ncol = 5)
plot_residuals(b, facet_by = "length", facet_ncol = 4)
checks <- check_fit(b, max_lag = 4)
checks$plots$heatmap
checks$plots$lag
checks$plots$qq
checks$lag_correlations
```

The residual is the observed log survey index minus the fitted one. `facet_by = "year"` plots residuals against length within each year; `facet_by = "length"` plots them against time within each length bin. `check_fit()` uses standardized residuals in three views: a time-by-length heatmap to locate persistent signs or patterns, correlations at lags from one to `max_lag` model time steps to examine temporal dependence, and a QQ plot to compare the residual distribution with a normal reference. The reference line of the QQ plot is the standard normal distribution, N(0,1). Standardized conditional residuals have a standard deviation below 1 even when the model is correct, because the fitted process deviations absorb part of the observation error. In simulation checks with correctly specified models this standard deviation was about 0.91 to 0.96. Expect the points to lie slightly inside the line at both tails, and do not read that slope as evidence of a light-tailed or under-dispersed error distribution. Skewness or a single heavy tail remains worth examining.

Use these patterns to choose hypotheses to examine. A pattern in the smallest bins may motivate a sensitivity analysis of survey catchability (`sel_L50`, `sel_L95`); a diagonal pattern may motivate checks of growth and cohort dynamics. Neither pattern identifies a unique cause, and short-lag correlation alone does not identify a missing year effect. The residuals condition on fitted process deviations, so these plots have no calibrated significance threshold. Compare alternative assumptions before assigning a biological explanation.

<h2 id="compare">3. Compare configurations and models</h2>

```r
comparison <- compare_models(a, b, x$data.CatL)
comparison$comparison
comparison$fit_metrics
comparison$length_at_age
comparison$growth
comparison$correlation
plot_compare_residuals(a, b, x$data.CatL)
plot_compare_ts(a, b, quantities = c("SSB", "Rec"), se = TRUE)
```

`compare_models()` works for any two fits of the same observations: ACL against ALSCL, or two configurations of one model, such as a parameter fixed and released. It first verifies that both fits used the same survey table (`data_verified`), then compares AIC, BIC and the fit statistics in `fit_metrics`. The `preferred` entry names the model with the lower AIC only when both fits passed the numerical checks (`eligible`) and the two AIC values differ by at least 2. When a fit failed a check, `preferred` stays empty and `issues` says why. When the fits are eligible but the AIC difference is below 2, `preferred` also stays empty and `issues` is empty: the function prints that the AIC values show little separation, and the `Delta AIC` row of `comparison$summary` gives the difference. `comparison$comparison` also records `delta_aic` (the AIC of the second model minus that of the first), `aic_threshold` (2) and `reason`, which states why no preference was given. A difference below 2 does not show that the models are equivalent. Use the comparison to choose between statistically comparable configurations; a lower AIC does not make a model with unsuitable fixed values or structure usable.

Three tables compare the estimates of the two fits. `comparison$length_at_age` holds the mean length at age of both fits, averaged over the time steps, with one column per model. `Basis` is `"survey"` (numbers at length multiplied by survey catchability at length) when the survey catchability of both fits is available, and `"population"` otherwise. This table is the comparison of growth. `comparison$growth` lists the parameters `Linf`, `k`, `t0`, `cv_len`, `cv_grow` (ALSCL) and the standard deviation of the observation error in a separate block of rows for each model, with the columns `Model`, `Parameter`, `Estimate` and `Meaning`. The parameters are not placed side by side, because `Linf`, `k` and `t0` are the parameters of a von Bertalanffy curve of mean length at age in ACL and set the growth increment at length and the mean length of recruits in ALSCL ([Model principles](model-theory.html#difference-increment)). `comparison$correlation` gives, for spawning biomass, recruitment, biomass and abundance, the correlation between the two series and `Ratio_Mean`, the mean of the second fit divided by that of the first. Catch in numbers and in weight are compared as relative catch, in the rows `CN (relative)` and `CB (relative)`: only the correlation is given, because a fit to a survey index does not determine the level of catch.

Use the original survey table for both fits. Each positive index is checked at its own scale, with a relative tolerance of `1e-12`. For example, replacing `1e-13` with `1e-20` changes the log observation by about 16 units. The comparison stops before calculating a preference.

<h2 id="sensitivity">4. Sensitivity to the fixed values</h2>

```r
scenarios <- fit_scenarios(x, list(reference = list(), low_M = list(M = 0.15), high_M = list(M = 0.25)),
                           model = "acl", ncores = 2)
scenarios$status
subset(scenarios$estimates, quantity == "SSB" & year == max(year))
# Other forms of the inputs: M by age class and a dome-shaped survey catchability
q_dome <- survey_catchability(x$fit_args$len_mid, "dome", L50 = 15, L95 = 20,
                              L50_desc = 42, L95_desc = 34, minimum = 0.2)
inputs <- fit_scenarios(x, list(
  reference = list(),
  M_by_age = list(M = matrix(c(0.4, 0.3, rep(0.2, 13)), ncol = 1)),
  dome = list(survey_q = q_dome, sel_L50 = NULL, sel_L95 = NULL)),
  model = "acl", ncores = 2, F_summary = "mean", silent = TRUE)
inputs$status[, c("scenario", "numerical_ok")]
mean_F <- subset(inputs$estimates, quantity == "F")
tapply(mean_F$estimate, mean_F$scenario, mean)
ssb <- subset(inputs$estimates, quantity == "SSB")
tapply(ssb$estimate, ssb$scenario, mean)
tapply(ssb$estimate, ssb$scenario, function(v) v[length(v)] / mean(v))
```

The fixed inputs (natural mortality `M`, survey catchability, fixed growth parameters) set the scale of the estimates. `fit_scenarios()` refits the same observations under named changes and returns every fit's status and a table of estimates by scenario, so you can see how much the spawning biomass in the last year moves when `M` varies over its supported range. Read `status` first: a scenario that failed the numerical checks stays in the table, flagged. [Assessment workflows](assessment-workflows.html) continues with likelihood profiles and projections.

A scenario can change `M` to any of its forms and can replace the logistic survey catchability with `survey_q`; the scenario then sets `sel_L50` and `sel_L95` to `NULL`, because the bundle stores them. Choose the range of each input from its source. For an M from maximum age, one standard deviation of the estimator (0.31 on the log scale) corresponds to M multiplied by 0.73 and by 1.36 ([Hamel and Cope 2022](https://doi.org/10.1016/j.fishres.2022.106477)). A dome-shaped survey catchability lowers the estimated mortality and is confounded with M, so always run the logistic curve next to it.

The level of F and of stock size depends on these inputs more than the trends do. In the second part of the block, the mean F over ages and years is 0.32 in the reference fit, 0.28 with a higher M for the two youngest age classes and 0.12 with the dome, and mean spawning biomass is 57, 57 and 141. Spawning biomass in the last year relative to its mean over the years is 1.33, 1.34 and 1.19. The survey index informs the total mortality rate and relative numbers; it does not inform the split of mortality into F and M or the level of catchability ([Model principles](model-theory.html#survey)). Report trends and the total mortality rate with their range over the scenarios, and give a level of F only together with the M and survey catchability that it depends on.

<h2 id="stability">5. Stability over time</h2>

Two further checks look at the time dimension. A retrospective analysis refits the model after removing the last one, two and three time steps and reports how much the terminal estimates change (Mohn's rho); see [Retrospectives](retrospectives.html). Hindcast validation fits on the earlier time steps and scores the predictions of later ones against the withheld observations; see [Model validation](case-model-validation.html).

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Change a setting that a check pointed to | [Fitting controls](fitting-controls.html) |
| Run retrospectives | [Retrospectives](retrospectives.html) |
| Profile a parameter or project the stock forward | [Assessment workflows](assessment-workflows.html) |
| Check predictions of future time steps | [Model validation](case-model-validation.html) |
| Draw other comparison figures | [Model comparison plots](model-comparison.html) |
