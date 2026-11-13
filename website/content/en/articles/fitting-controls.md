# Choose the fitting settings

On this page you decide which parameters the models estimate, which are fixed, how fishing mortality is structured, and how the optimizer runs. You need an input bundle `x` ([Prepare your survey data](data-preparation.html)) and you should have read [Understand your first fit](first-model.html), whose checks tell you whether a setting needs changing.

The settings fall into three groups: the biology and data settings in `x$fit_args`, which [Prepare your survey data](data-preparation.html) explains; the model configuration (starting values, bounds, `map`, F structure), chosen separately for ACL and ALSCL; and the optimizer settings (starts, workers, passes), which change how the answer is found and leave the model unchanged.

<h2 id="settings">1. Know the settings and where they live</h2>

| Setting | Meaning | Where to put it |
|---|---|---|
| `rec.age`, `nage`, `M`, `sel_L50`, `sel_L95`, `growth_step`, `len_mid`, `len_border` | Biology, survey catchability and time step | `x$fit_args`, shared by both models |
| `zero_action` | Treat survey zeros as missing (`"missing"`, default) or stop (`"error"`) | `x$fit_args` |
| `parameters`, `parameters.L`, `parameters.U` | Starting values and bounds of the scalar parameters, on the optimizer scale | `x$fit_config$acl` or `x$fit_config$alscl` |
| `map` | Which parameters are fixed at their starting value and which default fixes are released | `x$fit_config$acl` or `x$fit_config$alscl` |
| `F_structure` | `"group_year"` (default): F varies by age or length and by time step; `"year"`: one F per time step | `x$fit_args` or the call |
| `nstarts`, `ncores` | Number of independent optimizer starts and of worker processes running them | The call |
| `train_times` | Successive optimizer passes from each start (default 1) | The call |
| `polish` | Finish the best start with checked Newton steps (default `TRUE`) | The call |
| `control` | `nlminb()` controls such as `iter.max` | The call |
| `silent`, `output` | Hide progress messages; write diagnostics and plots to `output/` | The call |

Values in the call override the stored ones for that call only. Store a choice in `x` when every later analysis (retrospectives, scenarios, hindcast validation) should use it; step 7 shows how.

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

By default ACL fixes `log_std_log_F`, `logit_log_F_y`, `logit_log_F_a` and `t0`, and ALSCL fixes `log_sigma_log_F` and `log_t0`; everything else is estimated. `YTF_example` fixes more so that its teaching configuration runs quickly: the growth parameters (`log_Linf`, `log_vbk`, `t0` or `log_t0`, `log_cv_len` and, for ALSCL, `log_cv_grow`), the standard deviations of the F deviations and of the initial-numbers deviations, and every AR(1) correlation (`logit_log_R`, `logit_log_F_y`, and `logit_log_F_a` or `logit_log_F_l`). Each model then estimates five scalar parameters: `log_init_Z`, `mean_log_R`, `mean_log_F`, the recruitment SD and the survey observation SD. The intervals of the example are conditional on all of these fixed values. Your own bundle starts from the defaults. The process deviations `dev_log_R`, `dev_log_F` and `dev_log_N0` are created from the data dimensions and estimated as random effects; step 3 explains why their `map` entries should stay at the default. The `n_free`, `n_fixed` and `n_tied` columns show how many entries of each block are estimated.

<h2 id="map">3. Fix or release parameters with map</h2>

```r
# Fix growth at the starting values and estimate the F correlation across time
my_map <- list(log_Linf = factor(NA), log_vbk = factor(NA), logit_log_F_y = NULL)
a_map <- run_acl(x, map = my_map, silent = TRUE)
extract_parameters(a_map)
# Keep the choice in the bundle for later analyses
# A bundle built without fit_config has no stored configuration:
# create an entry for each model before the first assignment
if (is.null(x$fit_config)) x$fit_config <- list(acl = list(), alscl = list())
x$fit_config$acl$map <- my_map
```

`factor(NA)` fixes a parameter at its starting value; a named `NULL` releases a parameter that the model fixes by default. A `map` given in the call or stored in `x$fit_config` replaces the stored map completely, so list every fix you want each time. Investigate a non-positive-definite Hessian or a correlation near a boundary by checking gradients, parameter scales, bounds, additional starts and profiles. Fix a parameter when these checks support doing so and an external estimate or biological assumption provides a defensible value; record that basis with the assessment. `generate_map()` merges a list with the ACL defaults but drops `NULL` entries, so pass release lists directly as `map`. A stored `fit_config` must have an entry for the model you fit: assigning `x$fit_config$acl$map` to a bundle that has no `fit_config` would create an ACL entry only, and every ALSCL call would then stop. The `if` line above creates both entries; an empty entry means the model defaults.

Leave the process-deviation blocks `dev_log_R`, `dev_log_F` and `dev_log_N0` out of `map`. The models evaluate the process likelihood for every entry of a block. Fixing entries with `NA`, or giving several entries the same factor level, therefore does not give the likelihood of a model with fewer deviations. Such a map is rejected unless the standard deviation and the AR(1) correlations of that process are fixed as well. Even then the objective is not comparable with that of other fits, so do not compare it by AIC. To let all ages or lengths share one fishing mortality rate in each time step, use `F_structure = "year"` (step 5), which has its own one-dimensional AR(1) likelihood. `simulate_fit(process = "resample")` requires unrestricted process deviations, and `hindcast_model()` requires unrestricted `dev_log_R` and `dev_log_F`. See [Simulate and validate a fitted model](case-model-validation.html).

For a named `NULL` release, copy the exact parameter name from `inspect_parameters(x, model)`. An unknown name stops the fit. When you subset a map factor, unused levels are discarded and the remaining entries keep their fixed or estimated status.

<h2 id="starts">4. Set starting values and bounds</h2>

```r
p <- create_parameters(model_type = "acl", species = "flatfish")
p$parameters$log_Linf <- log(65)
p$parameters.U$log_Linf <- log(90)
if (is.null(x$fit_config)) x$fit_config <- list(acl = list(), alscl = list())
x$fit_config$acl$parameters <- p$parameters
x$fit_config$acl$parameters.U <- p$parameters.U
inspect_parameters(x, "acl")[, c("parameter", "natural_start", "lower", "upper")]
```

Starting values and bounds are entered on the optimizer scale: `log_Linf = log(65)` for an asymptotic length of 65 cm, `logit_log_R = qlogis(0.5)` for a correlation of 0.5. `create_parameters()` returns complete lists of starts (`parameters`), lower bounds (`parameters.L`) and upper bounds (`parameters.U`) for a species preset (`"flatfish"`, `"tuna"`, `"krill"` or none); change the entries you have information about. The presets are starting configurations taken from simulation operating models, not validated settings for a stock. The `"tuna"` preset, for example, is the tuna-like operating model M6 of the simulation study: 20 quarterly age classes with a plus group at 5 years, an asymptotic length of 152 cm and constant natural mortality. ACL uses `t0` directly, while ALSCL uses `log_t0`, so an ALSCL `t0` must lie between 0 and `rec.age`. A starting value outside its bounds is moved to the nearest bound before fitting. [Estimation parameter lists](estimation-parameters.html) gives the full list with transformations.

<h2 id="f-structure">5. Choose the F structure</h2>

With the default `F_structure = "group_year"`, fishing mortality has one value for every age (ACL) or length bin (ALSCL) in every time step, with deviations correlated across time and across ages or lengths. With `F_structure = "year"`, all ages or lengths share one F in each time step: one value per quarter for quarterly data. Consider `"year"` when equal F across groups is a defensible assumption or diagnostics suggest that the data provide little information about group-specific variation. A group correlation near 1 or a non-positive-definite Hessian warrants investigation, but neither alone selects the F structure. Compare the fits, residuals and sensitivity under both structures.

```r
a_year <- run_acl(x, F_structure = "year", silent = TRUE)
diagnose_model(x$data.CatL, a_year)
plot_fishing_mortality(a_year, se = TRUE)
plot_deviance(a_year, type = "F", se = TRUE)
```

With `"year"` the correlation across groups (`logit_log_F_a` or `logit_log_F_l`) is unused and left out of the fit, `report$dev_log_F` has one row, and `report$F` keeps its age (or length) by time shape with identical rows. Use the same structure in every later analysis of the same bundle, including retrospectives.

<h2 id="optimizer">6. Control the optimizer</h2>

```r
a4 <- run_acl(x, nstarts = 4, ncores = 2, silent = TRUE)
a4$start_diagnostics
a4$refinement$status
```

`nstarts` runs independent starts: the first from the supplied starting values, the later ones from deterministic perturbations of them, and the lowest objective is kept. `start_diagnostics` lists every start with its objective and convergence code. If the final objectives differ, check convergence and compare the final gradients and parameter estimates before interpreting the difference as evidence for multiple local minima. `ncores` sets how many worker processes run the starts at the same time (`nstarts` defaults to `ncores`, so set both when you compare timings). `train_times` repeats the optimizer from each start's end point; `polish = TRUE` finishes the best start with up to five Newton steps that are accepted only when the gradient decreases and the Hessian stays positive definite, and `a4$refinement` records what happened. `control = list(iter.max = 3000)` passes limits to `nlminb()`.

A failed restart does not replace an actual successful pass when the objective values differ by at most `1e-8` and every parameter differs by at most `1e-6 * max(1, abs(p1), abs(p2))`. These tolerances identify numerically equivalent repeated passes; meaningful objective improvements or separated parameter vectors still compete by the lower objective. All raw codes and messages remain in `optimizer_history`, and `raw_opt$selected_pass` identifies the retained pass. The final gradient, Hessian and boundary checks remain separate from the optimizer code.

Supply each `nlminb()` option once by name, for example `control = list(iter.max = 3000L)`. Both preflight and fitting check the names and values before optimization.

<h2 id="record">7. Record your choices</h2>

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
