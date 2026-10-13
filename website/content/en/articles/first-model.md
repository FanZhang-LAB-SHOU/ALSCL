# Built-in YTF

## Fit the example

Run this code in one R session after [installation](getting-started.html). Both calls use the same observations but different population structures. They create `a` (ACL), `b` (ALSCL), `x` and `inputs`, reused throughout the tutorials.

```r
install.packages("remotes")
remotes::install_github("Linbojun99/ALSCL")
library(ALSCL)
data("YTF_example")
x <- YTF_example
inputs <- x[c("data.CatL", "data.wgt", "data.mat")]
# Inspect dimensions and provenance
str(inputs)
x$provenance
# Same observations and conditional settings
a <- run_acl(x, train_times = 2, silent = TRUE)
b <- run_alscl(x, train_times = 2, silent = TRUE)
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
```

## Input lists and overrides

Since 2.2.0, both `run_acl(x)` and `run_alscl(x)` accept a complete named input list. For `YTF_example`, they read the three tables and `x$fit_args`, then the matching `x$fit_config$acl` or `x$fit_config$alscl`. Explicit call arguments have highest priority, for example `run_acl(x, M = 0.25, nstarts = 4, ncores = 2)`. List-valued overrides (`parameters`, `map`, `control`) replace the whole stored list, and explicit `NULL` is retained. The simulation settings in `x$parameters` and the generating `x$truth` are not fitting arguments.

For your own data, `x` can instead be a flat named list containing `data.CatL`, `data.wgt`, `data.mat`, `rec.age`, `nage`, `M`, `sel_L50`, `sel_L95` and any optional fitting arguments. A structured bundle may omit `fit_config` to use the model defaults; if it includes `fit_config`, that list must contain the selected model. Duplicate, unnamed, unknown or missing required arguments produce an error before fitting. All calls use the existing fitting core and `alscl_speed()` settings; inspect `fit$sd_info` to see the actual standard-error method. `ncores` controls independent optimization starts, while `sd_cores` in `alscl_speed()` controls standard errors.

The original separate-argument interface and `do.call()` remain supported. This older expression has the same fitting settings as `run_acl(x, silent = TRUE)`:

```r
old_args <- c(x[c("data.CatL", "data.wgt", "data.mat")],
              x$fit_args, x$fit_config$acl, list(silent = TRUE))
legacy_fit <- do.call(run_acl, old_args)
```

![Model comparison](https://github.com/Linbojun99/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true)

|Object|Contents and use|
|---|---|
| `YTF` |Original 26-element biological parameter list, no survey table|
| `YTF_example` |23 bins × 20 periods, three tables, parameters, truth, fit settings and provenance|
| `example_data` |Legacy ALSCL tables, 9 bins × 21 years, provenance unverified|


`YTF_example` reuses shared YTF parameters, including survey log SD 0.1, with remaining flatfish defaults. Seed 4, 80 burn-in years and 20 retained years are used. Dates are illustrative; cm and kg are teaching conventions. These are not empirical paper data. The data-raw script rebuilds the object and restores the caller's RNG state.


`x$fit_config` fixes known growth and selected process/correlation parameters. Intervals are conditional on these assumptions and omit their uncertainty. The example does not establish identifiability when all parameters are estimated together.

## Inspect the result

```r
names(b)
names(b$report)
diagnose_model(x$data.CatL, b)
plot_residuals(b, type = "year")
```

`report` contains derived population quantities and survey predictions. `opt` contains optimization results. `est_std` and `vcov` describe approximate uncertainty; `obj` is the live TMB objective. Preserve the original settings when comparing models or running retrospectives. See [diagnostics](diagnostics.html) before interpreting the estimates.
