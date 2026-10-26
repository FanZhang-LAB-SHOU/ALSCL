# Reproducibility

Complete the [worked YTF example](first-model.html) first. The examples below use its `x`, `inputs`, `a` (ACL) and `b` (ALSCL) objects.

## Sensitivity to fixed assumptions


Changing M, q or fixed CV can alter abundance and SSB. Vary justified assumptions on identical observations and retain diagnostics, rather than optimizing assumptions solely for AIC.

```r
# Use inputs and x defined in the guide
sensitivity <- lapply(c(.15, .20, .25), function(M_value) {
  fit <- run_alscl(x, M = M_value, train_times = 2, silent = TRUE)
  list(M=M_value, diagnostics=diagnose_model(x$data.CatL, fit), fit=fit)
})
# Inspect each diagnostic before comparison
lapply(sensitivity, function(z) z$diagnostics)
plot_compare_ts(sensitivity[[1]]$fit, sensitivity[[3]]$fit,
                model1_name="M = 0.15", model2_name="M = 0.25")
```


Review bounds and maps before releasing parameters. ACL and ALSCL use different t0 parameterizations. Compare objectives, gradients and derived quantities across credible starting values.

## Parallelism and compilation

```r
# Fall back safely when core count is unavailable
cores <- parallel::detectCores()
workers <- if (is.na(cores)) 1L else max(1L, min(4L, cores - 1L))
# Supply ncores once
multi <- run_acl(x, ncores=workers, nstarts=4, train_times=2, silent=TRUE)
```

|Entry| ncores=1 | ncores>1 |
|---|---|---|
| `run_acl`, `run_alscl` |Sequential execution of nstarts starts|Up to min(ncores, nstarts) socket workers|
| `sim_acl` |Sequential replicates|Parallel replicates|
| `retro_model`, `retro_acl`, `retro_alscl` |Sequential peels|Parallel peels|

For `retro_acl(x)` and `retro_alscl(x)`, a stored fitting `ncores` is ignored; set `ncores` explicitly on the retrospective call to control peel workers. `nstarts` still controls the number of starts in each fit, executed sequentially. Inspect `fit_diagnostics` before interpreting `rho_text`; an invalid required fit makes the screened rho unavailable.


Set `nstarts` to the same value when comparing worker counts. Its default is `ncores` for compatibility, so changing only `ncores` also changes the amount of work. Later starts use the same deterministic perturbations in serial and parallel runs. `multi$start_diagnostics` records each start’s PID, elapsed and CPU seconds, objective and convergence. More starts can help explore local optima but do not establish convergence; the selected result has the lowest finite objective. Runtime includes serial preparation, reporting and standard errors as well as the slowest worker and startup overhead. Avoid oversubscribing nested parallel jobs. Socket workers support Windows, macOS and Linux.


Fits compile automatically with a cache keyed by sources, headers, R/TMB/RcppEigen and compilation options. Call run_acl() or run_alscl() directly to compile and fit. An OpenMP compiler option alone does not guarantee parallel likelihood evaluation.

```r
# Optional writable compilation cache
options(ALSCL.tmb.cache=file.path(tempdir(), "alscl_tmb_cache"))
```


Use an R-compatible C++ toolchain: command-line tools on macOS, matching Rtools on Windows, and C++/make on Linux. Resolve dependency and toolchain failures before fitting.

## Save portable results

```r
# obj contains session-specific external pointers
portable <- function(fit) fit[setdiff(names(fit), "obj")]
saveRDS(portable(b), "alscl_report.rds")
capture.output(sessionInfo(), file="sessionInfo.txt")
saved <- readRDS("alscl_report.rds")
saved$report$SSB
# These plots can use saved reports
plot_SSB(saved)
```


Refit in a new session for `plot_ridges()`, which requires a live TMB object. Record version, commit, seed, provenance, units, maps, bounds, time step and diagnostics. An RDS file does not preserve a portable compiled model.

## Troubleshooting


|Symptom|Action|
|---|---|
| `YTF$data.CatL` is NULL |Load the input-data object|
| Excel years become X2000 |Preserve original headers|
| Discontinuous length boundaries |Verify actual bin definitions|
| Zero survey observations |Establish meaning before excluding zeros|
| Missing weight or maturity |Supply defensible complete biology|
| Nonzero optimizer code, large gradient or non-positive-definite Hessian |Investigate data and parameterization|
| Quarterly F appears small |Rates are per step, not auto-annualized|
| ACL F plot with `type="length"` |Current ACL compatibility alias plots age-specific F|
| Growth intervals collapse to a line |Expected when growth parameters are fixed|


Executable scripts and numerical results accompany the guide. Interpret figures in light of model assumptions and data provenance.

## Measured parallel performance

On 7 October 2026, we ran real ACL and ALSCL fits on an Apple M2 Pro (32 GiB). Each trial used **the same four starts**, two optimizer passes per start, and the first 10 years of synthetic `YTF_example` (23 length bins, 15 ages). Each setting was repeated three times. Compilation and warm-up were excluded; worker startup, fitting, reporting and standard errors were included.

| Model | Workers | Median (s) | Range (s) | Speedup |
|---|---:|---:|---:|---:|
| ACL | 1 | 4.23 | 4.18–4.44 | 1.00× |
| ACL | 2 | 3.50 | 3.27–3.90 | 1.21× |
| ACL | 4 | 3.08 | 2.93–3.14 | 1.38× |
| ALSCL | 1 | 71.38 | 71.28–72.35 | 1.00× |
| ALSCL | 2 | 45.03 | 44.55–51.00 | 1.59× |
| ALSCL | 4 | 33.23 | 31.21–33.95 | 2.15× |

![Measured total fitting times](../../../docs/figures/parallel/timing.png)

The points show all three measurements; lines show medians and bars show ranges. The computer was shared with other analyses, so results are conditional on this workload and machine. Smaller jobs can lose time to worker startup, and the serial reporting phase limits speedup.

![Actual concurrent fitting processes](../../../docs/figures/parallel/worker-timeline.png)

The first four-worker trials recorded four different PIDs with overlapping execution intervals and real CPU usage. All 18 timed fits and 72 starts passed the benchmark checks. Starting vectors and per-start objectives agreed across worker counts; the selected fits passed optimizer, Hessian, gradient and boundary checks. The unchanged C++ likelihood is evaluated within each worker; a single start is still serial.

See the [full bilingual report](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PARALLEL_BENCHMARK.md), [raw run timings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/parallel/runs.csv), [per-start evidence](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/parallel/starts.csv) and [reproducible benchmark script](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/benchmark_parallel.R). The report also records the original-version test and distinguishes it from an equal-work speed comparison.

## Speed settings for one fit

`alscl_speed()` sets how every later fit computes standard errors and which automatic-differentiation library TMB uses. The default settings give results identical to ALSCL 2.0.0: the fixed-effect Hessian and the delta-method standard errors are computed on several cores (`sd_cores = "auto"`: up to four; forked processes on macOS and Linux, socket workers for the delta method on Windows and in GUI front-ends such as RStudio). `framework = "TMBad"` compiles the model with TMB's TMBad library, which is faster, but its estimates differ slightly from the default (by up to 2.7e-8, relative, in the fits tested).

```r
# Defaults: identical results, parallel standard errors
alscl_speed()
b <- run_alscl(x, silent = TRUE)
# Faster option; results not identical to the default
alscl_speed(framework = "TMBad")
# Sequential standard errors, for example inside your own parallel loop
alscl_speed(sd_cores = 1)
```

In a benchmark of 90 fits on 12 October 2026 (ACL and ALSCL fitted to `YTF_example` and the flatfish and tuna cases, three runs each, Apple M2 Pro shared with other jobs), the default settings made fits 1.13-1.24 times faster and `framework = "TMBad"` 1.25-1.68 times faster than the original code.

| Model | Original (s) | Default (s) | TMBad (s) |
|---|---:|---:|---:|
| ACL, YTF_example | 8.6 | 7.7 (1.13×) | 6.6 (1.31×) |
| ALSCL, YTF_example | 140.9 | 118.8 (1.19×) | 83.9 (1.68×) |
| ALSCL, flatfish | 107.8 | 86.9 (1.24×) | 78.8 (1.37×) |
| ALSCL, tuna (quarterly) | 217.4 | 180.9 (1.20×) | 141.3 (1.54×) |

![Fit time before and after the speed settings](../../../docs/figures/speed/timing.png)

With the default settings, every estimate, the objective function and every row of `summary(sdreport)` were identical to the original code in all six combinations, and `R CMD check` passed on Linux, macOS and Windows.

![Estimates and standard errors before and after the speed settings](../../../docs/figures/speed/agreement.png)

The [speed settings](speed.html) article explains every setting, how to check what your session does and how socket workers are used on Windows and in RStudio. See also the [speed report](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED.md), the [raw timings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/speed/runs.csv) and the [benchmark script](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/benchmark_speed.R).

### Consistent package libraries in 2.2.5

Multistart fits, retrospective peels and simulation batches initialize socket workers with the parent session's library paths before loading ALSCL. This also applies when a newer installation is selected with `.libPaths()`. All workers must load the same ALSCL installation as the parent. Keep `nstarts` fixed when comparing worker counts; standard-error parallelism continues to use `alscl_speed()`.
