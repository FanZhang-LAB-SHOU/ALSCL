# Retrospectives

Complete the [worked YTF example](first-model.html) first. The examples below use its `x`, `inputs`, `a` (ACL) and `b` (ALSCL) objects.

```r
# Refit after peeling 1, 2 and 3 steps
ra <- retro_acl(x, nyear = 3, train_times = 2, silent = TRUE)
rb <- retro_alscl(x, nyear = 3, train_times = 2, silent = TRUE)
plot_retro(rb, facet_col = 2, rho_digits = 3)
rb$fit_diagnostics
rb$rho_by_peel
rb$rho_text
```


Here `nyear` counts terminal **steps**: four quarterly steps equal one year. Retain at least two observations and keep assumptions consistent across peels. Mohn's rho measures retrospective revision, not forecast accuracy; inspect each fit's numerical status.

![ALSCL retrospective](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true)

```r
# Rebuild figures, CSV and session record
source("scripts/ytf_workflow.R", encoding = "UTF-8")
result <- run_ytf_guide(out = "my_ytf_guide", npeels = 3)
# Keep live fits for TMB-dependent plots
plot_ridges(result$alscl)
```


The default output is `docs` and overwrites matching outputs; choose another folder to preserve bundled files. The workflow requires ggplot2, patchwork and jsonlite. Initial compilation needs a compiler, and retrospectives involve multiple fits. A writable TMB cache can be configured. Saved R objects do not preserve usable TMB external pointers across sessions; refit for operations requiring a live `obj`.
Version 2.2.3 accepts the same input bundle as the fitting functions: `retro_acl(x, nyear = 3)` and `retro_alscl(x, nyear = 3)`. The general form is `retro_model(data.CatL = x, model_type = "alscl", nyear = 3)`. Shared settings, then model-specific settings, then explicit call arguments determine each fit; explicit `map`, `parameters` and `control` replace their complete stored lists. `zero_action`, `control`, `nstarts`, `F_structure` and `polish` reach every fit. A fitting `ncores` stored in `x` is ignored: set `ncores` on the retrospective call for parallel peels. Within each peel, optimization starts run sequentially, with their number controlled by `nstarts`.

`fit_diagnostics` includes the full fit (`Peel = 0`) and every requested peel, with elapsed time, raw optimizer status, gradient, Hessian, boundaries and errors. `rho_by_peel` contains screened `Rho`, diagnostic `RawRho` and `Valid`. A quantity receives a reported value in `rho_text$Rho` only if the full fit and all requested peels pass the numerical screen and all terminal comparisons are finite with a nonzero reference. Otherwise it is `NA`, with a warning; failed peels are never silently dropped. `raw_rho_text` is an unscreened diagnostic summary, not a replacement for the screened result. It remains `NA` when a terminal comparison is missing. Available trajectories remain in `results` for inspection.

## Meaning of Mohn's rho

Compare each peeled estimate with the full fit at that peel's terminal period, then average relative differences:

```math
\rho=\frac{1}{K}\sum_{k=1}^{K}\frac{\hat\theta^{(-k)}_{T-k}-\hat\theta^{(0)}_{T-k}}{\hat\theta^{(0)}_{T-k}}.
```

Positive rho means shorter fits tend to be higher at their terminal periods; signs can cancel. Inspect individual trajectories and fits. A zero full-fit denominator makes the relative difference undefined.


## ACL retrospective analysis

```r
# Draw this figure
plot_retro(ra, facet_col = 2, rho_digits = 3, rho_size = 3, point_size = 1, line_size = 0.6)
```

[![ACL retrospective analysis](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ACL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ACL.png?raw=true)



Successively peel terminal observations and refit; colors indicate different terminal periods.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_retro)



## ALSCL retrospective analysis

```r
# Draw this figure
plot_retro(rb, facet_col = 2, rho_digits = 3, rho_size = 3, point_size = 1, line_size = 0.6)
```

[![ALSCL retrospective analysis](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true)



Successively peel terminal observations and refit; colors indicate different terminal periods.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_retro)

## Retaining diagnostics when every fit fails

When all retrospective fits fail or no finite trajectories remain, `plot = TRUE` now warns and returns `plot = NULL` while preserving `fit_diagnostics`, `errors` and the unavailable rho values. Inspect those fields to correct the input or fitting problem. Requesting a plot must not prevent access to the failure record.

### Consistent package libraries in 2.2.5

Multistart fits, retrospective peels and simulation batches initialize socket workers with the parent session's library paths before loading ALSCL. This also applies when a newer installation is selected with `.libPaths()`. All workers must load the same ALSCL installation as the parent. Keep `nstarts` fixed when comparing worker counts; standard-error parallelism continues to use `alscl_speed()`.
