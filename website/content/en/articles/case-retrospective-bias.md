# Do estimates change when recent data are removed?

## The problem

An assessment may revise historical biomass or recruitment as new observations arrive. A retrospective analysis asks how estimates differ when the terminal observations are removed and the same model is refitted. It does not measure forecast accuracy.

## Refit shorter series

This complete setup uses the synthetic YTF example and its conditional biological settings. It requires a working compiler and performs multiple fits.

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
inputs <- x[c("data.CatL", "data.wgt", "data.mat")]
rb <- retro_alscl(x, nyear = 3, train_times = 2, silent = TRUE)
plot_retro(rb, facet_col = 2, rho_digits = 3)
rb$rho_text
```

## Inspect trajectories and Mohn’s rho

![Bundled ALSCL retrospective example](../assets/manual/figures/ytf/retro_ALSCL.png)

Compare each peel with the full fit at the peel’s final period. Positive rho means shortened fits tend to be higher at those terminal periods; negative rho indicates the opposite. Opposing deviations can cancel, so inspect individual curves and the numerical status of each fit. A zero reference estimate makes its relative difference undefined.

## Compare the ACL retrospective

Use the same observations and peel count, but keep ACL’s own parameter names and maps.

```r
ra <- retro_acl(x, nyear = 3, train_times = 2, silent = TRUE)
plot_retro(ra, facet_col = 2, rho_digits = 3)
ra$rho_text
```

![Synthetic YTF: ACL retrospective trajectories](../assets/manual/figures/ytf/retro_ACL.png)

The two model figures are bundled examples. Compare revisions within each model before comparing rho between models; inspect the same quantity and terminal periods. Different y scales can exaggerate or hide apparent differences.

## Inspect the returned tables

```r
head(rb$results)
rb$last_points
rb$rho_text
names(rb)
```

`fit_diagnostics` includes the full fit (`Peel = 0`) and every requested peel, with elapsed time, raw optimizer status, gradient, Hessian, boundaries and errors. `rho_by_peel` contains screened `Rho`, diagnostic `RawRho` and `Valid`. A quantity receives a reported value in `rho_text$Rho` only if the full fit and all requested peels pass the numerical screen and all terminal comparisons are finite with a nonzero reference. Otherwise it is `NA`, with a warning; failed peels are never silently dropped. `raw_rho_text` is an unscreened diagnostic summary, not a replacement for the screened result. It remains `NA` when a terminal comparison is missing. Available trajectories remain in `results` for inspection.

### Inspect every fit without repeating the analysis

```r
rb$fit_diagnostics
rb$rho_by_peel
rb$rho_text
rb$raw_rho_text
rb$errors
```

Version 2.2.3 accepts the same input bundle as the fitting functions: `retro_acl(x, nyear = 3)` and `retro_alscl(x, nyear = 3)`. The general form is `retro_model(data.CatL = x, model_type = "alscl", nyear = 3)`. Shared settings, then model-specific settings, then explicit call arguments determine each fit; explicit `map`, `parameters` and `control` replace their complete stored lists. `zero_action`, `control`, `nstarts`, `F_structure` and `polish` reach every fit. A fitting `ncores` stored in `x` is ignored: set `ncores` on the retrospective call for parallel peels. Within each peel, optimization starts run sequentially, with their number controlled by `nstarts`.

## Adapt the analysis to your assessment

Replace the inputs and biology with the same configuration used for your full-data fit. Keep fixed parameters, observation handling and time units consistent. `nyear` counts removed terminal steps: three quarterly steps are not three years. Retain sufficient observations in each peel; see [the function guide](retrospectives.html).

## Export the retrospective record

```r
dir.create("my_retrospective", showWarnings = FALSE)
write.csv(rb$results, "my_retrospective/alscl_trajectories.csv", row.names = FALSE)
write.csv(rb$rho_text, "my_retrospective/alscl_rho.csv", row.names = FALSE)
write.csv(rb$fit_diagnostics, "my_retrospective/fit_diagnostics.csv", row.names = FALSE)
write.csv(rb$rho_by_peel, "my_retrospective/rho_by_peel.csv", row.names = FALSE)
write.csv(ra$rho_text, "my_retrospective/acl_rho.csv", row.names = FALSE)
p_retro <- plot_retro(rb, facet_col = 2, rho_digits = 3)
ggplot2::ggsave("my_retrospective/alscl.png", p_retro,
               width = 10, height = 7, dpi = 300)
saveRDS(list(ACL = ra, ALSCL = rb, fit_args = x$fit_args,
             fit_config = x$fit_config), "my_retrospective/results.rds")
writeLines(capture.output(sessionInfo()), "my_retrospective/session.txt")
```

|Symptom|Interpretation or check|
|---|---|
|Too few time steps after peeling|Reduce peel count; every fit must retain at least two time steps|
|Opposite-signed terminal deviations|Inspect individual peels; average rho can hide cancellation|
|Quarterly analysis interpreted as years|Convert removed steps to duration using `growth_step`|
|A custom `zero_action` is required|Set `zero_action` in `x$fit_args` or pass it explicitly to `retro_alscl(x, ...)`; every fit uses the same setting|
|A short fit is unstable|Inspect its diagnostics before interpreting its terminal revision|

## Decide what to investigate next

A repeated directional revision motivates checks of input changes, model assumptions and parameter sensitivity. Rho alone does not identify a cause or supply a correction factor. Record the full fit, each peel’s diagnostics and its terminal period before drawing conclusions.

## Retaining diagnostics when every fit fails

When all retrospective fits fail or no finite trajectories remain, `plot = TRUE` now warns and returns `plot = NULL` while preserving `fit_diagnostics`, `errors` and the unavailable rho values. Inspect those fields to correct the input or fitting problem. Requesting a plot must not prevent access to the failure record.

### Consistency corrections

Retrospective peels shorten time-dependent `map$dev_log_R` and `map$dev_log_F` with the retained periods. Supply maps for the full dataset: recruitment uses one entry per period; F uses group-by-time column order (age groups for ACL, length groups for ALSCL, one group for `F_structure = "year"`). Factor ties and fixed NA entries are retained. Invalid full-data map lengths are rejected. Scalar maps and `dev_log_N0` do not change with a peel.
