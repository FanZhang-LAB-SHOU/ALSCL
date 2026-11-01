# Understand your first fit

After [installing the package](getting-started.html) you have the input bundle `x` and a fitted ACL model `a`. On this page you learn what a fitted object contains, how to judge whether a fit can be used, how to read its estimates, and how the second model, ALSCL, compares with it. Run the steps in one R session; later pages reuse `x`, `a` and `b`.

`YTF_example` is synthetic: 23 length bins and 20 years generated from a known population. Its stored settings fix growth and some process parameters, so the uncertainty intervals you will see are conditional on those fixed values. Use it to learn the workflow before choosing assumptions for your own stock.

<h2 id="fit">1. Fit the two models</h2>

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
a <- run_acl(x, silent = TRUE)
b <- run_alscl(x, silent = TRUE)
```

ALSCL offers two models of the same survey data. ACL (`run_acl()`) follows the number of fish at each age and converts ages to lengths with an age-length probability matrix. ALSCL (`run_alscl()`) follows the number of fish at each length and age and moves survivors between length bins with a growth transition matrix, which suits stocks that are hard to age. The ACL fit takes about twenty seconds for this example and the ALSCL fit about two minutes, after the one-time compilation of each model.

Both calls read the same `x`: the three tables, the shared biology in `x$fit_args` (recruitment age, number of ages, natural mortality `M`, survey catchability `sel_L50` and `sel_L95`, length bins and time step) and the model's own starting values and `map` in `x$fit_config$acl` or `x$fit_config$alscl`. The last section of this page explains the bundle in detail.

<h2 id="checks">2. Read the numerical checks</h2>

```r
diagnose_model(x$data.CatL, a)
a$diagnostics$numerical_ok
a$diagnostics$issues
```

Read the numerical checks before any estimate. `diagnose_model()` prints the optimizer convergence code (0 means it finished normally), the maximum absolute gradient at the solution (below 0.001 when the optimizer really reached a minimum), whether the Hessian is positive definite (needed for standard errors), whether a parameter sits on a bound, and whether a variance or correlation was estimated at its natural limit. `Numerical screen` summarizes all of them; it is the same value as `a$diagnostics$numerical_ok`, and `a$diagnostics$issues` names any check that failed.

| Failed check | Usual cause | What to try |
|---|---|---|
| Convergence code is not 0, or the gradient is large | The optimizer stopped early or the surface is flat | Run more starts, `run_acl(x, nstarts = 4, ncores = 2)`, and compare their objectives in `a$start_diagnostics` |
| Hessian not positive definite | A parameter is not informed by the data | Fix that parameter with `map` or share F across groups with `F_structure = "year"` ([Fitting controls](fitting-controls.html)) |
| Parameter on a bound | A bound or starting value is wrong for this stock | Inspect starts and bounds with `inspect_parameters(x, "acl")` and adjust them |
| Natural-scale boundary | A standard deviation near 0 or a correlation near 1 | Fix the parameter at a supported value, or simplify the F structure |
| Checks pass but residuals show patterns | The model misses a feature of the data | Continue with [Diagnostics](diagnostics.html) |

<h2 id="estimates">3. Read the estimates</h2>

```r
estimates <- extract_estimates(a)
head(estimates)
subset(estimates, quantity == "SSB")
extract_parameters(a)
plot_SSB(a, se = TRUE)
```

`extract_estimates()` returns one table for the population quantities: spawning biomass `SSB`, recruitment `Rec`, total biomass `B`, abundance `N`, catch numbers `CN` and fishing mortality `F`, with the year, the age or length where the quantity has one, the estimate, its standard error and a 95% interval. `extract_parameters()` lists the scalar parameters with their status (estimated or fixed) and estimates on the natural scale. `plot_SSB()` draws spawning biomass with its interval; the other plot functions follow the same pattern.

The intervals come from the standard errors of the estimated parameters only; the fixed values in `x$fit_config` contribute no uncertainty. The raw arrays behind the table are in `a$report` (for example `a$report$SSB`), and `a$sd_info` records how the standard errors were computed.

<h2 id="fit-to-data">4. Check the fit to the observations</h2>

```r
plot_CatL(a, type = "year", facet_ncol = 5)
plot_residuals(a, type = "year", facet_ncol = 5)
```

`plot_CatL()` shows the observed survey index (points) and the fitted index (line) across length bins, one panel per year. `plot_residuals()` shows the log residuals, observed minus fitted on the log scale, for the same panels. A usable fit has residuals scattered around zero in every panel. A run of residuals with the same sign across neighbouring lengths in one year, or across years in one length bin, means the model misses a feature of the data, such as a cohort passing through the survey or a selectivity that differs from the assumed one; [Diagnostics](diagnostics.html) shows how to examine such patterns.

<h2 id="compare">5. Compare ACL and ALSCL</h2>

```r
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
comparison <- compare_models(a, b, x$data.CatL)
comparison$comparison
comparison$fit_diagnostics
```

![ACL and ALSCL biomass, spawning biomass and recruitment estimates](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true)

The figure shows total biomass, spawning biomass and recruitment from both models with their intervals. Similar trajectories mean the two population structures agree on the trend; a persistent difference in scale usually comes from how each model converts between age and length.

`compare_models()` first verifies that both fits used the same observations, then prints AIC, BIC and fit statistics. `comparison$comparison` records `data_verified`, `eligible` (both fits passed the numerical checks), `preferred` (the model with the lower AIC, given only when both are eligible) and any `issues`. A lower AIC supports a model statistically on these data; whether its assumptions suit the stock is a separate, biological decision.

<h2 id="save">6. Save the fit</h2>

```r
save_assessment(a, "ytf_acl.rds")
saved <- read_assessment("ytf_acl.rds")
plot_SSB(saved, se = TRUE)
```

`save_assessment()` writes everything in the fit except the live TMB object `a$obj`, which is a pointer valid only in the current session, and stores the recipe (the tables, settings and package version) so that `refit_model(saved)` can rebuild the live object later. Plots and the extraction functions work directly on the saved fit.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Replace the example with your own tables | [Prepare your survey data](data-preparation.html) |
| Decide which parameters to fix or estimate | [Fitting controls](fitting-controls.html) |
| Examine residuals and compare configurations | [Diagnostics](diagnostics.html) |
| Plot a particular quantity | [Survey and population plots](population-plots.html) |
| Test sensitivity, profile a parameter, project forward | [Assessment workflows](assessment-workflows.html) |
| Simulate from the fit or test predictions of future years | [Model validation](case-model-validation.html) |

<h2 id="bundle">How run_acl(x) reads the input bundle</h2>

The input bundle `x` is a named list. Its three tables `data.CatL`, `data.wgt` and `data.mat` hold the observations. `x$fit_args` holds the settings both models share: `rec.age`, `nage`, `M`, `sel_L50`, `sel_L95`, `len_mid`, `len_border` and `growth_step`. `x$fit_config$acl` and `x$fit_config$alscl` hold the starting values (`parameters`) and the `map` of each model. Other elements, such as the simulation `truth` and `provenance` of `YTF_example`, are ignored by the fitting functions.

Settings are read in this order: the tables, then `fit_args`, then the `fit_config` entry of the chosen model, then the arguments of the call. An argument in the call therefore overrides the stored value, and a list argument such as `map` replaces the stored list completely.

```r
# Four starts on two workers; the stored M is replaced by 0.25 for this call only
a4 <- run_acl(x, nstarts = 4, ncores = 2, M = 0.25)
```

You can also pass every table and setting as a separate argument, as older scripts do with `do.call(run_acl, args)`; both forms use the same fitting code. A flat named list with the three tables, `rec.age`, `nage`, `M`, `sel_L50` and `sel_L95` is accepted as a bundle too.

<h2 id="data-provenance">About the bundled data</h2>

| Object | Contents |
|---|---|
| `YTF_example` | The three tables (23 bins by 20 years), `fit_args`, `fit_config`, the generating `truth` and `provenance` |
| `YTF` | The original list of 26 biological parameters, without survey tables |
| `example_data` | Three older ALSCL tables (9 bins, 2001-2021) of unverified origin, kept for compatibility |

`YTF_example` was generated with the package simulator (seed 4, 80 burn-in years, 20 retained years, survey log SD 0.1) and is not the empirical dataset of the paper. The [generation script](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/data-raw/YTF_example.R) rebuilds it.
