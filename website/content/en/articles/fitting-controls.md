# Choose the fitting settings

On this page you decide which parameters the models estimate, which are fixed, how fishing mortality is structured, and how the optimizer runs. You need an input bundle `x` ([Prepare your survey data](data-preparation.html)) and you should have read [Understand your first fit](first-model.html), whose checks tell you whether a setting needs changing.

The settings fall into three groups: the biology and data settings in `x$fit_args`, which [Prepare your survey data](data-preparation.html) explains; the model configuration (starting values, bounds, `map`, F structure and optional model structures), chosen separately for ACL and ALSCL; and the optimizer settings (starts, workers, passes), which change how the answer is found and leave the model unchanged.

<h2 id="settings">1. Know the settings and where they live</h2>

| Setting | Meaning | Where to put it |
|---|---|---|
| `rec.age`, `nage`, `M`, `sel_L50`, `sel_L95`, `growth_step`, `len_mid`, `len_border` | Biology, survey catchability and time step | `x$fit_args`, shared by both models |
| `zero_action` | Treat survey zeros as missing (`"missing"`, default) or stop (`"error"`) | `x$fit_args` |
| `parameters`, `parameters.L`, `parameters.U` | Starting values and bounds of the scalar parameters, on the optimizer scale | `x$fit_config$acl` or `x$fit_config$alscl` |
| `map` | Which parameters are fixed at their starting value and which default fixes are released | `x$fit_config$acl` or `x$fit_config$alscl` |
| `F_structure` | `"group_year"` (default): F varies by age or length and by time step; `"year"`: one F per time step | `x$fit_args` or the call |
| `structure` | Optional model structures, including the range of the AR(1) correlations; the default is the published structure of Zhang and Cadigan (2022) | `x$fit_config$acl` or `x$fit_config$alscl`, or the call |
| `t0_lower` | Lower limit of the ALSCL growth parameter `t0` in years (default 0); a negative value allows a negative `t0` | `x$fit_config$alscl` or the call to `run_alscl()` |
| `nstarts`, `ncores` | Number of independent optimizer starts and of worker processes running them | The call |
| `start_spread` | Spread of the second and later starts around the first (default 0.15) | The call |
| `train_times` | Successive optimizer passes from each start (default 1) | The call |
| `polish` | Finish the best start with checked Newton steps (default `TRUE`) | The call |
| `control` | `nlminb()` controls such as `iter.max` | The call |
| `silent`, `output` | Hide progress messages; write diagnostics and plots to `output/` | The call |

Values in the call override the stored ones for that call only. Store a choice in `x` when every later analysis (retrospectives, scenarios, hindcast validation) should use it; step 8 shows how.

<h2 id="parameters">2. See which parameters are estimated</h2>

```r
plan <- inspect_parameters(x, "acl")
plan[, c("parameter", "kind", "status", "map_source", "natural_start")]
inspect_parameters(x, "alscl")[, c("parameter", "status", "natural_start")]
```

`inspect_parameters()` lists the scalar parameters and process-deviation blocks of the chosen model, with their starting values and status, including `free` (estimated), `fixed` or `tied`. `map_source` tells whether a fixed status comes from the model default or from your `map`. Run it after every change below; it compiles and fits nothing.

| Meaning | ACL parameter | ALSCL parameter |
|---|---|---|
| Growth (von Bertalanffy) | `log_Linf`, `log_vbk`, `t0` | `log_Linf`, `log_vbk`, `log_t0` |
| Spread of length at age; growth increment CV | `log_cv_len` | `log_cv_len`, `log_cv_grow` |
| Mean recruitment and mean F (log scale) | `mean_log_R`, `mean_log_F` | `mean_log_R`, `mean_log_F` |
| Standard deviations of the process deviations | `log_std_log_R`, `log_std_log_F`, `log_std_log_N0` | `log_sigma_log_R`, `log_sigma_log_F`, `log_sigma_log_N0` |
| Correlation of F across time; across ages or lengths | `logit_log_F_y`, `logit_log_F_a` | `logit_log_F_y`, `logit_log_F_l` |
| Correlation of recruitment across time | `logit_log_R` | `logit_log_R` |
| Initial total mortality; survey observation SD | `log_init_Z`, `log_std_index` | `log_init_Z`, `log_sigma_index` |

By default ACL fixes `log_std_log_F`, `logit_log_F_y`, `logit_log_F_a` and `t0`, and ALSCL fixes `log_sigma_log_F` and `log_t0`; everything else is estimated. `YTF_example` fixes more so that its teaching configuration runs quickly: the growth parameters (`log_Linf`, `log_vbk`, `t0` or `log_t0`, `log_cv_len` and, for ALSCL, `log_cv_grow`), the standard deviation of the F deviations (0.302, the marginal SD `F_sd / sqrt(1 - F_ar^2)` of the AR(1) process that generated the data), the standard deviation of the initial-numbers deviations, and every AR(1) correlation (`logit_log_R`, `logit_log_F_y`, and `logit_log_F_a` or `logit_log_F_l`). Each model then estimates five scalar parameters: `log_init_Z`, `mean_log_R`, `mean_log_F`, the recruitment SD and the survey observation SD. The intervals of the example are conditional on all of these fixed values. Your own bundle starts from the defaults. The process deviations `dev_log_R`, `dev_log_F` and `dev_log_N0` are created from the data dimensions and estimated as random effects; step 3 explains why their `map` entries should stay at the default. The `n_free`, `n_fixed` and `n_tied` columns show how many entries of each block are estimated.

<h2 id="map">3. Fix or release parameters with map</h2>

```r
# Fix growth at the starting values and estimate the F correlation across time
my_map <- list(log_Linf = factor(NA), log_vbk = factor(NA), logit_log_F_y = NULL)
a_map <- run_acl(x, map = my_map, silent = TRUE)
extract_parameters(a_map)
# Keep the choice in the bundle for later analyses
x$fit_config$acl$map <- my_map
```

`factor(NA)` fixes a parameter at its starting value; a named `NULL` releases a parameter that the model fixes by default. A `map` given in the call or stored in `x$fit_config` replaces the stored map completely, so list every fix you want each time. Investigate a non-positive-definite Hessian or a correlation near a boundary by checking gradients, parameter scales, bounds, additional starts and profiles. Fix a parameter when these checks support doing so and an external estimate or biological assumption provides a defensible value; record that basis with the assessment. `generate_map()` merges a list with the ACL defaults but drops `NULL` entries, so pass release lists directly as `map`. The assignment creates `x$fit_config$acl` when the bundle has no stored configuration. A model without an entry in `x$fit_config` uses the shared `x$fit_args` and the model defaults, so a bundle that stores a configuration for ACL only can still be fitted with ALSCL.

Leave the process-deviation blocks `dev_log_R`, `dev_log_F` and `dev_log_N0` out of `map`. The models evaluate the process likelihood for every entry of a block. Fixing entries with `NA`, or giving several entries the same factor level, therefore does not give the likelihood of a model with fewer deviations. Such a map is rejected unless the standard deviation and the AR(1) correlations of that process are fixed as well, because their estimates would otherwise be biased. Even then the objective is not comparable with that of fits that use another map for these deviations, so do not compare it by AIC; the fit lists the blocks concerned in `restricted_random`. To let all ages or lengths share one fishing mortality rate in each time step, use `F_structure = "year"` (step 5), which has its own one-dimensional AR(1) likelihood. `simulate_fit(process = "resample")` requires unrestricted process deviations, and `hindcast_model()` requires unrestricted `dev_log_R` and `dev_log_F`. See [Simulate and validate a fitted model](case-model-validation.html).

For a named `NULL` release, copy the exact parameter name from `inspect_parameters(x, model)`. An unknown name stops the fit. When you subset a map factor, unused levels are discarded and the remaining entries keep their fixed or estimated status.

<h2 id="starts">4. Set starting values and bounds</h2>

```r
p <- create_parameters(model_type = "acl", species = "flatfish")
p$parameters$log_Linf <- log(65)
p$parameters.U$log_Linf <- log(90)
x$fit_config$acl$parameters <- p$parameters
x$fit_config$acl$parameters.U <- p$parameters.U
inspect_parameters(x, "acl")[, c("parameter", "natural_start", "lower", "upper")]
```

Starting values and bounds are entered on the optimizer scale: `log_Linf = log(65)` for an asymptotic length of 65 cm, `logit_log_R = qlogis(0.5)` for a correlation of 0.5 (with the default range of the correlations; step 6 gives the value for correlations between -1 and 1). `create_parameters()` returns complete lists of starts (`parameters`), lower bounds (`parameters.L`) and upper bounds (`parameters.U`) for a species preset (`"flatfish"`, `"tuna"`, `"krill"` or none); change the entries you have information about. The presets are starting configurations taken from simulation operating models, not validated settings for a stock. The `"tuna"` preset, for example, is the tuna-like operating model M6 of the simulation study: 20 quarterly age classes with a plus group at 5 years, an asymptotic length of 152 cm and constant natural mortality. ACL uses `t0` directly, while ALSCL uses `log_t0` with `t0 = t0_lower + exp(log_t0)`, so with the default `t0_lower = 0` an ALSCL `t0` must lie between 0 and `rec.age`; step 6 shows how to allow a negative `t0`. A starting value outside its bounds is moved to the nearest bound before fitting, with a warning when you supplied the start and with a message for a default start; the fit lists these values in `clamped_starts`. The ACL defaults for `Linf` (start 60, bounds 10 to 100) are in the length units of the yellowtail flounder example. When they do not suit your length bins, for example tuna lengths in cm, `run_acl()` sets the start and bounds that you did not supply from the data. The start is 1.1 times the length below which 99 percent of the summed survey index lies. The upper bound is 2 times the largest length-bin midpoint. The lower bound is the smaller of the default (10) and half of that 99 percent length, so that length bins extending beyond the largest fish do not exclude the true `Linf`. `run_alscl()` always sets the values you did not supply from the data: the start is 1.1 times the largest length-bin midpoint and the bounds are 0.7 and 2 times that midpoint, so supply `parameters.L$log_Linf` when the bins extend well beyond the largest fish. [Estimation parameter lists](estimation-parameters.html) gives the full list with transformations.

<h2 id="f-structure">5. Choose the F structure</h2>

With the default `F_structure = "group_year"`, fishing mortality has one value for every age (ACL) or length bin (ALSCL) in every time step, with deviations correlated across time and across ages or lengths. With `F_structure = "year"`, all ages or lengths share one F in each time step: one value per quarter for quarterly data. Consider `"year"` when equal F across groups is a defensible assumption or diagnostics suggest that the data provide little information about group-specific variation. A group correlation near 1 or a non-positive-definite Hessian warrants investigation, but neither alone selects the F structure. Compare the fits, residuals and sensitivity under both structures.

```r
a_year <- run_acl(x, F_structure = "year", silent = TRUE)
diagnose_model(x$data.CatL, a_year)
plot_fishing_mortality(a_year, se = TRUE)
plot_deviance(a_year, type = "F", se = TRUE)
```

With `"year"` the correlation across groups (`logit_log_F_a` or `logit_log_F_l`) is unused and left out of the fit, `report$dev_log_F` has one row, and `report$F` keeps its age (or length) by time shape with identical rows. Use the same structure in every later analysis of the same bundle, including retrospectives.

<h2 id="structure">6. Choose an optional model structure</h2>

```r
b_structure <- run_alscl(x, structure = "consistent", silent = TRUE)
b_structure$structure
b_structure$growth_check$stalled
a_structure <- run_acl(x, structure = list(initial_plus_group = "equilibrium"),
                       silent = TRUE)
a_structure$structure
```

The `structure` argument selects optional model structures. The default, an empty list, is the published structure of Zhang and Cadigan (2022), so a call without `structure` fits the same model as before. `structure = "consistent"` selects the first four settings of the table together, so that the first time step and the growth transition follow one growth model; `structure = "published"` is the default structure. A named list selects single settings, and a list can name a set and add settings to it, for example `list(set = "consistent", correlation_range = "symmetric")`. ACL has the first and the last setting of the table; ALSCL has all five.

| Setting | Published structure (default) | Optional structure |
|---|---|---|
| `initial_plus_group` (ACL and ALSCL) | `"single_cohort"`: the plus group of the first time step holds one cohort | `"equilibrium"`: it holds the sum of all older cohorts at the initial total mortality rate `init_Z` |
| `initial_length` (ALSCL) | `"length_at_age"`: in the first time step every age has the length-at-age distribution with coefficient of variation `cv_len` | `"growth"`: the first age has that distribution, and each older age is the previous age after survival at `init_Z` and one growth step, as in all later time steps |
| `growth_increment` (ALSCL) | `"logistic"`: the expected growth increment is a decreasing logistic function of length, multiplied by `growth_step` | `"von_bertalanffy"`: the expected increment over one time step is `(Linf - L) * (1 - exp(-vbk * growth_step))` for a length `L` below `Linf` and declines smoothly to zero above `Linf`, so `Linf` and `vbk` have the same meaning as in the length-at-age curve. Fish then stop growing at about `Linf`, so `Linf` acts as an upper limit of length after the first time step: data with many fish larger than the mean asymptotic length fit poorly, and the standard error of `Linf` can be very small. The logistic increment stays positive above `Linf` |
| `growth_transition` (ALSCL) | `"midpoint"`: every fish in a length bin grows from the bin midpoint | `"bin"`: starting lengths are uniform within the bin and the transition is integrated over the bin, so fish keep moving to the next bin when the growth increment per time step is small relative to the bin width |
| `correlation_range` (ACL and ALSCL) | `"positive"`: the AR(1) correlations of recruitment and of F lie between 0 and 1, as the logistic transform of the `logit_*` parameters | `"symmetric"`: they lie between -1 and 1, as 2 times the logistic transform minus 1, so a correlation of zero is an interior value and a negative correlation can be estimated |

Two pairs of settings give a property that the published structure does not have. With `initial_length = "growth"` and `initial_plus_group = "equilibrium"`, a population with constant recruitment, no fishing and `init_Z` equal to `M` stays constant over time. With `growth_increment = "von_bertalanffy"` and `growth_transition = "bin"`, the mean length of a cohort follows the von Bertalanffy curve closely when the length bins are a few times wider than the growth increment per time step. With much wider bins it remains approximate, because fish are spread evenly over their bin after every time step. Under the published structure the mean length falls well below the curve when the increment per time step is small relative to the bin width, as with quarterly time steps and wide length bins. As an example, take a cohort that starts in the length bin nearest 40 cm, with quarterly time steps, `Linf` of 152 cm, `vbk` of 0.38 per year and a coefficient of variation of the growth increment of 0.3. After 10 years the von Bertalanffy curve gives 149.5 cm. With `"von_bertalanffy"` and `"bin"` the mean length is 149.6 cm with 1-cm bins, 148.3 cm with 5-cm bins and 146.6 cm with 10-cm bins. With the published structure it is 143.0 cm with 1-cm bins, 121.7 cm with 5-cm bins and 105.3 cm with 10-cm bins.

Use the four settings of `"consistent"` together. With `growth_transition = "midpoint"`, growth stops at the length where the growth increment in one time step falls well below half the bin width, whatever the value of `Linf`. In simulation tests with quarterly time steps and 5-cm length bins (`Linf` of 152 cm), growth under the published structure stopped between 113 and 120 cm. Fits with only the two initial-state settings or only the two growth settings then failed the numerical checks or gave strongly biased estimates of the fishing mortality rate, because the first time step and the later time steps followed different growth models. When the fitted transition has a length bin, with a midpoint below 90% of the estimated `Linf`, in which fish stay with a probability of at least 0.99 per time step, `run_alscl()` reports it in a message (unless `silent = TRUE`), `summary()` prints it, and `growth_check` in the fit stores the result. The published structure and the `"consistent"` set have the same number of parameters, so fit both and compare their objective values.

`b_structure$structure` and `a_structure$structure` list the value used for every setting, and a saved fit keeps them. A fit with an optional structure is a different model, so compare its numerical checks, residuals and estimates with those of the default fit before you choose it ([Diagnostics](diagnostics.html)). If `run_acl()` stops because a setting "applies to ALSCL only", remove the growth and initial-length settings from the ACL call: ACL has no growth transition matrix. Store the choice under the model it belongs to, for example in `x$fit_config$alscl$structure`, so that later fits of the bundle, including the retrospective peels, use it. To simulate data with the same structure, see [Simulate survey data](simulation.html#generate).

<h3 id="correlation-range">Allow negative AR(1) correlations</h3>

```r
# Start from the stored configuration of YTF_example
cfg <- YTF_example$fit_config$acl
cfg$parameters$logit_log_R <- qlogis((0.1 + 1) / 2)  # a correlation of 0.1
cfg$map$logit_log_R <- NULL                          # estimate the recruitment correlation
a_sym <- run_acl(YTF_example, parameters = cfg$parameters, map = cfg$map,
                 structure = list(correlation_range = "symmetric"), silent = TRUE)
a_sym$structure$correlation_range
subset(extract_parameters(a_sym), parameter == "logit_log_R")
```

With the default `correlation_range = "positive"`, every AR(1) correlation (recruitment over time; F over time and over ages or lengths) lies between 0 and 1, because the correlation is the logistic transform of its `logit_*` parameter. When the recruitment deviations of a stock have no autocorrelation or a negative one, the estimate then runs to the lower limit, the fit reports a natural-scale boundary and it fails the numerical checks. With `correlation_range = "symmetric"` the correlations lie between -1 and 1. A correlation of zero is then an interior value, at a `logit_*` value of 0, a negative correlation can be estimated, and the numerical checks flag a correlation only when it is close to -1 or 1. The block estimates the recruitment correlation of the example: the estimate is 0.18 with a standard error of 0.23, and the 95% interval from -0.27 to 0.57 includes zero and negative values.

A `logit_*` starting value or fixed value has a different meaning under the two settings: a correlation `rho` is `qlogis(rho)` under `"positive"` and `qlogis((rho + 1) / 2)` under `"symmetric"`. Convert every `logit_*` value that you supply, as the line of the block that sets `logit_log_R` does. Starting values that you do not supply keep their natural value under either setting; the two F correlations of this fit stay fixed at 0.75. `inspect_parameters()`, `extract_parameters()`, `profile_model()` and `simulate_fit()` use the transform of the bundle or fit, so the values they show or take on the natural scale are correlations under both settings. Store the choice with the converted values, for example in `x$fit_config$acl$structure` and `x$fit_config$acl$parameters`, so that later fits of the bundle use both.

<h3 id="t0-lower">Allow a negative t0 in ALSCL</h3>

```r
x_t0 <- YTF_example
x_t0$fit_config$alscl$t0_lower <- -1
x_t0$fit_config$alscl$parameters$log_t0 <- log(-0.2 + 1)  # t0 = -0.2 years
plan_t0 <- inspect_parameters(x_t0, "alscl")
plan_t0[plan_t0$parameter == "log_t0", c("parameter", "natural_start", "transform", "status")]
b_t0 <- run_alscl(x_t0, silent = TRUE)
subset(extract_parameters(b_t0), parameter == "log_t0")
b_t0$t0_lower
```

ALSCL holds the von Bertalanffy parameter `t0` on the log scale, as `t0 = t0_lower + exp(log_t0)`. The default `t0_lower = 0` is the published parameterization, in which `t0` is positive. For a stock with a negative `t0`, set `t0_lower` to a value below the smallest `t0` you consider, for example -1, and supply `t0` as `log_t0 = log(t0 - t0_lower)`: the block fixes `t0` at -0.2 years with `log(-0.2 + 1)`. `t0_lower` must be below the recruitment age, and `t0` itself stays below the recruitment age. `inspect_parameters()` shows the natural starting value -0.2 with the transform `t0_lower+exp`. `extract_parameters()`, `plot_VB()`, `profile_model()` and `b_t0$report$t0` give or take `t0` in years, and the fit keeps the limit in `b_t0$t0_lower`. To estimate `t0` in place of fixing it, release it with a named `NULL` in `map` (step 3).

The value -0.2 only shows how the argument works. `YTF_example` was generated with a `t0` of 1/60 years, so this fit has a higher objective than the default fit. ACL needs no such argument: its parameter `t0` is on the natural scale and can be negative, and `run_acl()` does not accept `t0_lower`. Store `t0_lower` under `x$fit_config$alscl`, as in the block, and not in `x$fit_args`, which both models read; later ALSCL fits of the bundle, including the retrospective peels, then use it. `retro_alscl()` and `retro_model()` also take `t0_lower` in the call.

<h2 id="optimizer">7. Control the optimizer</h2>

```r
a4 <- run_acl(x, nstarts = 4, ncores = 2, silent = TRUE)
a4$start_diagnostics
a4$start_summary
a4$refinement$status
# For results that will be reported: more starts, spread more widely
a5 <- run_acl(x, nstarts = 5, start_spread = 0.5, ncores = 2, silent = TRUE)
a5$start_summary
```

`nstarts` runs independent starts: the first from the supplied starting values, the later ones from deterministic perturbations of them, and the lowest objective is kept. The perturbations are normal deviates with standard deviation `start_spread` (default 0.15) on the optimizer scale. `start_diagnostics` lists every start with its objective and convergence code, and `start_summary` gives the number of converged starts, the range of their objectives and the number that agree with the best one; a range above 2 is added to `diagnostics$issues`. If the final objectives differ, check convergence and compare the final gradients and parameter estimates before interpreting the difference as evidence for multiple local minima. `ncores` sets how many worker processes run the starts at the same time (`nstarts` defaults to `ncores`, so set both when you compare timings). `train_times` repeats the optimizer from each start's end point; `polish = TRUE` finishes the best start with up to five Newton steps that are accepted only when the gradient decreases and the Hessian stays positive definite, and `a4$refinement` records what happened. `control = list(iter.max = 3000)` passes limits to `nlminb()`.

A single start can stop at a local optimum that passes every numerical check, particularly for the growth parameters of ALSCL. The numerical checks are local: they describe the solution that was found and do not show whether a better one exists. For results that will be reported, use several starts (for example `nstarts = 5`) with a wider `start_spread` (for example 0.5), as in the last two lines of the block, and compare the objectives in `start_diagnostics`.

A failed restart does not replace an actual successful pass when the objective values differ by at most `1e-8` and every parameter differs by at most `1e-6 * max(1, abs(p1), abs(p2))`. These tolerances identify numerically equivalent repeated passes; meaningful objective improvements or separated parameter vectors still compete by the lower objective. All raw codes and messages remain in `optimizer_history`, and `raw_opt$selected_pass` identifies the retained pass. The final gradient, Hessian and boundary checks remain separate from the optimizer code.

Supply each `nlminb()` option once by name, for example `control = list(iter.max = 3000L)`. Both preflight and fitting check the names and values before optimization.

<h2 id="record">8. Record your choices</h2>

```r
x$fit_args$F_structure <- "year"
x$fit_config$acl$map <- my_map
saveRDS(x, "my_bundle.rds")
a <- run_acl(x, silent = TRUE)
save_assessment(a, "my_acl.rds")
```

Every workflow function reads the bundle, so a choice stored in `x` is applied consistently by `retro_acl(x)`, `fit_scenarios(x, ...)`, `hindcast_model(x)` and the simulation functions. `save_assessment()` keeps the complete recipe with the fit, so a reader can see which values were fixed and refit the model with `refit_model()`.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Judge the fit and look for residual patterns | [Diagnostics](diagnostics.html) |
| See the full list of parameters and transformations | [Estimation parameter lists](estimation-parameters.html) |
| Test how fixed values change the answer | [Assessment workflows](assessment-workflows.html) |
| Make fits faster | [Speed settings](speed.html) |
