## Speed settings on every system

Standard errors now also use several cores on Windows and in RStudio, R.app and Positron: socket workers compute the delta method when it would take more than about 3 seconds, with identical results. Each fit records how its standard errors were computed in `fit$sd_info`, and `alscl_speed_info()` shows what the settings mean on your computer. The new [speed settings](../articles/speed.html) article explains every setting.

## Speed settings

The new `alscl_speed()` sets how fits compute standard errors. By default they are computed on several cores within one fit, with results identical to ALSCL 2.0.0; in the benchmark, fits were 1.13-1.24 times faster. `alscl_speed(framework = "TMBad")` compiles the models with TMB's TMBad library and made fits 1.25-1.68 times faster, but estimates differ slightly from the default. See the [`alscl_speed()` reference](../reference/alscl_speed.html).

## Parallel fitting update

`run_acl()` and `run_alscl()` now accept `nstarts` separately from `ncores`, with the previous default behavior preserved. Returned diagnostics record actual worker PIDs and CPU time. See [measured parallel performance](../articles/reproducibility.html) for equal-work timings and reproducible evidence.

## ALSCL 2.0.0

- Two survey catch-at-length models, ACL and ALSCL, with annual or quarterly time steps.
- Built-in YTF teaching data, full simulation workflows, Excel templates and guidance for importing observations.
- Fit diagnostics, model comparisons and retrospective analyses.
- Customizable ggsci palettes, with sequential viridis colors for time-ordered ridge plots.

## Documentation website

The documentation is available in English and Simplified Chinese. Use the language link in the navigation bar to switch the current page. The website includes task-based articles, the existing worked figures, and a reference page for every exported function.

Function signatures and defaults are extracted from the R source during each build. Purpose, arguments, return values and usage notes are maintained alongside the package documentation.
