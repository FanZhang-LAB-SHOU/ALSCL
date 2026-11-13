# Understand your first fit

After [installing the package](getting-started.html) you have the input bundle `x` and a fitted ACL model `a`. On this page you learn what a fitted object contains, how to judge whether a fit can be used, how to read its estimates, and how the second model, ALSCL, compares with it. Run the steps in one R session; later pages reuse `x`, `a` and `b`.

`YTF_example` is synthetic: 23 length bins and 20 years generated from a known population. Its stored settings fix growth and some process parameters, so the uncertainty intervals you will see are conditional on those fixed values. Learn the workflow on it before choosing assumptions for your own stock.

<h2 id="fit">1. Fit the two models</h2>

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
a <- run_acl(x, silent = TRUE)
b <- run_alscl(x, silent = TRUE)
```

ALSCL offers two models of the same data. ACL (`run_acl()`) follows the number of fish at each age and converts ages to lengths with an age-length probability matrix. ALSCL (`run_alscl()`) follows the number of fish at each length and age and moves survivors between length bins with a growth transition matrix, which suits stocks that are hard to age. The ACL fit takes about twenty seconds for this example and the ALSCL fit about two minutes, after the one-time compilation of each model.

Both calls read the same `x`: the three tables, the shared biology in `x$fit_args` (recruitment age, number of ages, natural mortality `M`, survey catchability `sel_L50` and `sel_L95`, length bins and time step) and the model's own starting values and `map` in `x$fit_config$acl` or `x$fit_config$alscl`. The [bundle section](#bundle) explains `x` in detail.

<h2 id="checks">2. Read the numerical checks</h2>

```r
diagnose_model(x$data.CatL, a)
a$diagnostics$numerical_ok
a$diagnostics$issues
```

Read the numerical checks before interpreting estimates. `diagnose_model()` prints the raw optimizer convergence code (0 means normal termination), the maximum absolute gradient, Hessian and covariance status, and parameter-boundary checks. `Numerical checks`, also stored as `a$diagnostics$numerical_ok`, requires a gradient below 0.001, a positive-definite Hessian and covariance matrix, and no flagged parameter boundaries. This numerical screen does not include the raw optimizer code or strong parameter correlations; inspect those separately in `a$diagnostics$issues`. Passing the screen supports further examination of the fit but does not establish a unique or global optimum.

| Failed check | Possible causes | What to try |
|---|---|---|
| Convergence code is not 0, or the gradient is large | The optimizer stopped early or the surface is flat | Run more starts, `run_acl(x, nstarts = 4, ncores = 2)`, and compare their objectives in `a$start_diagnostics` |
| Hessian not positive definite | The fit is away from a minimum, parameter scales cause numerical difficulty, or some parameters are weakly identified | Check gradients, scales and additional starts; use profiles or sensitivity analyses before fixing parameters or simplifying F ([Fitting controls](fitting-controls.html)) |
| Parameter on a bound | The constrained optimum is at a bound, or the fit has not reached a stable solution | Inspect the bound and its biological basis, try other starts, and examine a profile before changing it |
| Natural-scale boundary | A standard deviation near 0 or a correlation near 0 or 1 | Check gradients, bounds, alternative starts and profiles; assess biological support before fixing a value or simplifying F |
| Checks pass but residuals show patterns | The model misses a feature of the data | Continue with [Diagnostics](diagnostics.html) |

<h2 id="estimates">3. Read the estimates</h2>

```r
estimates <- extract_estimates(a)
head(estimates)
subset(estimates, quantity == "SSB")
extract_parameters(a)
plot_SSB(a, se = TRUE)
```

`extract_estimates()` returns one table for the population quantities: spawning biomass `SSB`, recruitment `Rec`, total biomass `B`, abundance `N`, catch numbers `CN` and fishing mortality `F`, with the year, the age or length where the quantity has one, the estimate, its standard error and a 95% interval. `extract_parameters()` lists the scalar parameters with their status (`estimated`, `fixed` or `inactive`) and estimates on the natural scale. `plot_SSB()` draws spawning biomass with its interval; the other plot functions follow the same pattern.

The intervals come from the standard errors of the estimated parameters only; the fixed values in `x$fit_config` contribute no uncertainty. The raw arrays behind the table are in `a$report` (for example `a$report$SSB`), and `a$sd_info` records how the standard errors were computed.

<h2 id="fit-to-data">4. Check the fit to the observations</h2>

```r
plot_CatL(a, facet_by = "year", facet_ncol = 5)
plot_residuals(a, facet_by = "year", facet_ncol = 5)
```

`plot_CatL()` shows the observed and fitted survey indices across length bins, one panel per year. `plot_residuals()` shows observed minus fitted values on the log scale for those panels. Look for residuals centred near zero and for persistent signs across lengths or time. Such patterns can motivate checks of growth, cohort dynamics or survey catchability, but do not identify a unique cause; [Diagnostics](diagnostics.html) explains how to investigate them.

<h2 id="compare">5. Compare ACL and ALSCL</h2>

```r
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
comparison <- compare_models(a, b, x$data.CatL)
comparison$comparison
comparison$fit_diagnostics
```

![ACL and ALSCL biomass, spawning biomass and recruitment estimates](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true)

The figure shows both models' total biomass, spawning biomass and recruitment with intervals. Similar trajectories mean the two population structures agree on the trend; a persistent difference in scale calls for closer comparison of growth, mortality and age-length conversion assumptions.

`compare_models()` first verifies that both fits used the same observations, then prints AIC, BIC and fit statistics. `comparison$comparison` records `data_verified`, `eligible` (both fits passed the numerical checks), `preferred` (the model with the lower AIC, given only when both are eligible and the AIC values differ by at least 2) and any `issues`. AIC balances likelihood fit against parameter count; among compatible fits to the same observations, a lower value supports that candidate under this criterion. Whether its assumptions suit the stock is a separate, biological decision.

<h2 id="save">6. Save the fit</h2>

```r
save_assessment(a, "ytf_acl.rds")
saved <- read_assessment("ytf_acl.rds")
plot_SSB(saved, se = TRUE)
```

`save_assessment()` writes everything in the fit except the live TMB object `a$obj`, a pointer valid only in the current session, and stores the recipe (the tables, settings and package version) so that `refit_model(saved)` can rebuild the live object later. Plots and extraction functions work directly on the saved fit. The call stops when the file exists; pass `overwrite = TRUE` to replace it.

<h2 id="bundle">How run_acl(x) reads the input bundle</h2>

The input bundle `x` is a named list. Its three tables `data.CatL`, `data.wgt` and `data.mat` hold the observations. `x$fit_args` holds the settings both models share: `rec.age`, `nage`, `M`, `sel_L50`, `sel_L95`, `len_mid`, `len_border` and `growth_step`. `x$fit_config$acl` and `x$fit_config$alscl` hold the starting values (`parameters`) and the `map` of each model. The fitting functions ignore other elements, such as the simulation `truth` and `provenance` of `YTF_example`.

Settings are read in this order: the tables, then `fit_args`, then the `fit_config` entry of the chosen model, then the arguments of the call. An argument in the call therefore overrides the stored value, and a list argument such as `map` replaces the stored list completely.

```r
# Four starts on two workers; the stored M is replaced by 0.25 for this call only
a4 <- run_acl(x, nstarts = 4, ncores = 2, M = 0.25)
```

Every table and setting can also be passed as a separate argument, as in `do.call(run_acl, args)`; both forms use the same fitting code. A flat named list with the three tables, `rec.age`, `nage`, `M`, `sel_L50` and `sel_L95` is accepted as a bundle too.

<h2 id="data-provenance">About the bundled data</h2>

| Object | Contents |
|---|---|
| `YTF_example` | The three tables (23 bins by 20 years), `fit_args`, `fit_config`, the generating `truth` and `provenance` |
| `YTF` | The original list of 26 biological parameters, without survey tables |
| `example_data` | Three ALSCL tables (9 bins, 2001-2021) of unverified origin, for trying the functions only |

`YTF_example` was generated with ALSCL 2.0.0 (seed 4, 80 burn-in years, 20 retained years, survey log SD 0.1) and is not the empirical dataset of the paper. The [generation script](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/data-raw/YTF_example.R) runs the same settings with the installed simulator and records its version. Load the bundled dataset to reproduce the values used in this guide.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Replace the example with your own tables | [Prepare your survey data](data-preparation.html) |
| Decide which parameters to fix or estimate | [Fitting controls](fitting-controls.html) |
| Examine residuals and compare configurations | [Diagnostics](diagnostics.html) |
| Plot a particular quantity | [Survey and population plots](population-plots.html) |
| Test sensitivity, profile a parameter, project forward | [Assessment workflows](assessment-workflows.html) |
| Simulate from the fit or test predictions of future years | [Model validation](case-model-validation.html) |
