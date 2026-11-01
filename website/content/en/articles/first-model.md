# Your first fit with the bundled YTF data

**Start here after [installation](getting-started.html).** This page takes you from an input bundle to a fitted ACL model, its diagnostics and an ALSCL comparison. Run the steps in one R session. They create `x`, `inputs`, `a` and `b`, which later tutorials reuse.

The example is **synthetic**, with 23 length bins and 20 annual periods. Its teaching configuration fixes selected biological and process parameters; the resulting intervals are conditional on those settings. Use it to learn the workflow before choosing assumptions for your own stock.

<h2 id="section-1">1. Load the data and fit ACL</h2>

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
inputs <- x[c("data.CatL", "data.wgt", "data.mat")]
str(inputs)
x$provenance

a <- run_acl(x, train_times = 2, silent = TRUE)
```

`x` already contains the three input tables, shared biological settings and a configuration for each model. `run_acl(x)` selects the ACL configuration automatically. Here `train_times = 2` requests two successive optimization passes from each start; it does not request two independent starts.

The first fit compiles a model and can take longer. Once it finishes, `a` contains the ACL results. Inspect these before comparing estimates or interpreting uncertainty.

<h2 id="section-3">2. Check the fitted result</h2>

```r
a$diagnostics
diagnose_model(x$data.CatL, a)
plot_residuals(a, type = "year")
```

Read the optimizer status, maximum gradient, Hessian and parameter boundaries together. Then look for residual patterns. If numerical checks fail, use the [diagnostics guide](diagnostics.html) before treating estimates or intervals as an assessment result. Passing the numerical screen does not establish that the model adequately describes the observations.

The most useful parts of a fit are:

| Field | What it contains |
|---|---|
| `diagnostics` | Numerical status and issues to investigate |
| `report` | Population quantities, including SSB and recruitment, and survey predictions |
| `opt` | Optimized scalar parameters and objective value |
| `est_std`, `vcov` | Approximate standard errors and covariance |
| `sd_info` | The standard-error method and cores actually used |
| `obj` | The live TMB objective for this R session |

```r
names(a$report)
a$sd_info
```

<h2 id="compare-models">3. Fit ALSCL and compare the two models</h2>

Use the same `x` for ALSCL. It selects the ALSCL configuration while retaining the same observations and shared biological inputs.

```r
b <- run_alscl(x, train_times = 2, silent = TRUE)
b$diagnostics
diagnose_model(x$data.CatL, b)
plot_residuals(b, type = "year")

plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
```

![ACL and ALSCL biomass, spawning biomass and recruitment estimates](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true)

The panels show total biomass, spawning biomass and recruitment, with approximate intervals under each model's fixed assumptions. Compare both diagnostics and trajectories; the plot alone does not rank the models. See [model comparisons](model-comparison.html) for comparisons on a common set of observations.

<h2 id="next-step">4. Choose your next step</h2>

| What you want to do | Continue with |
|---|---|
| Replace the teaching data with your observations | [Prepare the three input tables](data-preparation.html) |
| Decide which parameters to fix or estimate | [Fitting settings and map](fitting-controls.html) |
| Plot a particular population quantity | [Survey and population plots](population-plots.html) |
| Save results, check residuals or test sensitivity | [Assessment workflows](assessment-workflows.html) |
| Generate data from a fitted model or test future predictions | [Simulation and prediction validation](case-model-validation.html) |

<h2 id="section-2">Input bundles, overrides and earlier syntax</h2>

For the first fit, the direct calls above are sufficient. This section explains how to change their settings and reuse older scripts.

A structured `x` is read in this order: the three data tables, shared `x$fit_args`, and the selected `x$fit_config$acl` or `x$fit_config$alscl`. Explicit call arguments have highest priority. For example, `run_acl(x, M = 0.25, nstarts = 4, ncores = 2)` changes M and runs four independent starts on at most two workers. The value 0.25 is only an example override, not a recommendation for your stock.

List-valued overrides (`parameters`, `map`, `control`) replace the whole stored list; explicit `NULL` is retained. The simulation settings in `x$parameters` and the generating `x$truth` are not fitting arguments. See [fitting controls](fitting-controls.html) before changing a map.

For your own data, a flat named list is also accepted. It contains `data.CatL`, `data.wgt`, `data.mat`, `rec.age`, `nage`, `M`, `sel_L50`, `sel_L95` and optional fitting arguments. A structured bundle can omit `fit_config` to use model defaults; when present, `fit_config` must contain the selected model. Duplicate, unnamed, unknown or missing required arguments produce an error before fitting.

All interfaces use the same fitting core and `alscl_speed()` settings. `ncores` controls workers for independent starts; `sd_cores` in `alscl_speed()` controls standard-error calculations. Check `a$sd_info` or `b$sd_info` for actual execution; [speed settings](speed.html) explains the options.

The original separate-argument interface and `do.call()` remain supported. If adapting an older script, this expression has the same fitting settings as `run_acl(x, silent = TRUE)`; you do not need to run it again for this tutorial.

```r
old_args <- c(x[c("data.CatL", "data.wgt", "data.mat")],
              x$fit_args, x$fit_config$acl, list(silent = TRUE))
# Optional compatibility example:
# legacy_fit <- do.call(run_acl, old_args)
```

<h2 id="data-provenance">About the bundled datasets</h2>

| Object | Contents and use |
|---|---|
| `YTF` | Original 26-element biological parameter list, without survey tables |
| `YTF_example` | 23 bins × 20 periods; three tables, simulation parameters, truth, fitting settings and provenance |
| `example_data` | Legacy ALSCL tables, 9 bins × 21 years; provenance unverified |

`YTF_example` reuses shared YTF parameters, including survey log SD 0.1, with remaining flatfish defaults. It uses seed 4, 80 burn-in years and 20 retained years. Dates are illustrative, and cm and kg are teaching conventions. These are not empirical paper data. The [data-generation script](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/data-raw/YTF_example.R) rebuilds the object and restores the caller's RNG state.

`x$fit_config` fixes known growth and selected process/correlation parameters. Its intervals omit uncertainty in those fixed values. This example does not establish identifiability when all parameters are estimated together. Preserve the original settings when comparing models or running retrospectives.
