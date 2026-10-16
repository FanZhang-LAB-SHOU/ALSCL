# Speed settings

This guide explains how `run_acl()` and `run_alscl()` use several cores, how much faster fits become, how to check what your session does, and when to change the settings. The [technical record](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED.md) explains how each change was tested, and the [review report](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_REPORT.md) lists the checks.

## 1. Summary

You do not need to change anything. Default fits use several cores for standard errors when supported. Parallel standard errors match the sequential calculation at the same fitted parameters. Version 2.2.2 also refines the optimum by default, so complete fits need not be bitwise identical to older releases. Benchmarks below measured the earlier optimization path; `polish = FALSE` skips the new refinement. Two settings, both set with `alscl_speed()`, control this:

| Setting | Default | Results | Speed | When to change it |
|---|---|---|---|---|
| `sd_cores` | `"auto"`: up to four cores | Identical to the sequential calculation | Fits 1.13-1.24 times faster in the benchmark (macOS, terminal) | Set `1` inside your own parallel loops; set a number to use a fixed number of cores |
| `framework` | `"CppAD"` | Same AD library as ALSCL 2.0.0 | Baseline | `"TMBad"` makes fits 1.25-1.68 times faster, but results differ slightly (section 6) |

`alscl_speed_info()` shows what the settings mean on your computer, and each fit records what was done in `fit$sd_info`.

## 2. Quick start

```r
library(ALSCL)
alscl_speed_info()   # what the current settings mean on this computer
x <- YTF_example
fit <- run_alscl(x, silent = FALSE)
fit$sd_info          # how the standard errors were computed and how long they took
```

With `silent = FALSE` the fit prints one line about the standard errors, and `alscl_speed_info()` prints the settings. For example, on macOS in a terminal:

```r
#> Standard errors: forked processes on 4 cores, 9.0 s.
alscl_speed_info()
#> ALSCL speed settings
#>   sd_cores setting:                  auto
#>   cores for standard errors:         4
#>   standard errors computed by:       forked processes on 4 cores: Hessian and delta method
#>   reason:                            forked processes are safe here (macOS or Linux outside a GUI front-end)
#>   framework:                         CppAD
#>   cross-version numerical identity:  not guaranteed (2.2.2 adds optimizer refinement)
#>   TMB version:                       1.9.21 (checked)
```

## 3. Where the time goes in a fit

A fit has two parts:

1. **Optimisation.** `nlminb()` searches over the fixed effects. Each evaluation of the objective function or its gradient runs an inner Newton optimisation over the random effects (the Laplace approximation). This part is sequential: each step depends on the previous one, so it cannot use several cores without changing the path of the optimiser and therefore the results.
2. **Standard errors.** After the optimisation, `TMB::sdreport()` computes (a) the Hessian of the fixed effects, from two gradient evaluations per fixed effect, and (b) the delta-method standard error of every ADREPORT quantity (recruitment, abundance, biomass, spawning biomass, catch and fishing mortality by year, age and length; 3,866 quantities for the 20-year ALSCL example). The columns of the Hessian do not depend on each other, and neither do the ADREPORT quantities, so both can be computed on several cores with identical results.

For ALSCL fitted to the 20 years of `YTF_example` with the original code, the optimisation took about 88 s, the Hessian 11.4 s and the delta method 10.6 s. The speed settings shorten the standard errors; `framework = "TMBad"` also shortens the optimisation.

## 4. How standard errors use several cores

### 4.1 Forked processes: macOS and Linux in a terminal

Where it is safe, ALSCL starts forked processes (copies of the R session made by `parallel::mclapply()`). Each copy already holds the fitted model, so both the Hessian columns and the delta method are shared out with almost no start-up cost. This is the fastest method: for the 20-year ALSCL example the standard errors took 9.0 s on four cores instead of 23.4 s.

Forked processes are used in R or `Rscript` run from a terminal on macOS or Linux, and on computing clusters.

### 4.2 Socket workers: Windows, RStudio, R.app and Positron

Forking is not available on Windows, and R's documentation (`?parallel::mclapply`) discourages it in GUI front-ends (R.app, RGui, RStudio, Positron) and with multithreaded libraries such as Apple's Accelerate BLAS. In these sessions ALSCL uses socket workers instead: new R processes that receive the data and rebuild the model.

A new process has to rebuild TMB's derivative tapes before it can compute a gradient; for the 20-year ALSCL example the first gradient took 14 s with CppAD (42 s with TMBad), more than the whole Hessian. So with socket workers:

- the Hessian is computed in the main R session;
- the delta method is shared out among socket workers, which need only the objective's gradient tape (built in about 0.1 s) and receive the random-effect Hessian from the main session;
- ALSCL first computes a few ADREPORT quantities itself to measure the time per quantity, and starts workers only if the remaining quantities would take more than about 3 seconds. Small models, such as most ACL fits, therefore compute standard errors in the main session, which is faster than starting workers.

For the 20-year ALSCL example, the delta method took 6.5 s on four socket workers instead of 13.9 s (of which 0.3 s was starting the workers and 0.9 s rebuilding the model in them). The gain for the whole fit is smaller than with forked processes (section 8).

On macOS or Linux in RStudio you can choose forked processes for the full speed-up with `options(ALSCL.sd_backend = "fork")`. This is what R's documentation advises against, so use it only if your session runs fits without problems.

### 4.3 When standard errors are computed sequentially

| Situation | What happens |
|---|---|
| `sd_cores = 1`, or one core available | Sequential `TMB::sdreport()` |
| Fits inside `retro_model()` or `sim_acl()` running on parallel workers | One core per fit, so the number of processes does not multiply |
| The installed TMB version is not one the parallel code was checked against (currently 1.9.21) | Sequential `TMB::sdreport()`; `fit$sd_info$note` says so |
| Socket workers would not save time (little work) | Computed in the main session |
| The parallel calculation fails (for example, processes cannot be started) | A warning, then the sequential `TMB::sdreport()`; results are unaffected |

### 4.4 Why the results are identical

The parallel code performs exactly the same arithmetic as `TMB::sdreport()`, in the same order for each quantity; only the order in which quantities are computed differs, and they do not depend on each other. Two details matter: the Hessian reproduces the way `stats::optimHess()` moves through the parameters, and with random effects every gradient starts the inner optimisation from the same point. The test suite compares every component of the result with `TMB::sdreport()` using `identical()`, for ACL and ALSCL, CppAD and TMBad, forked processes and socket workers, and these tests pass on Linux, macOS and Windows.

## 5. Choosing the number of cores

- **`"auto"` (default)** uses up to four physical cores and keeps one free for the rest of the computer. More than four cores shortened fits little in tests, because the optimisation itself is sequential.
- **A number**, for example `alscl_speed(sd_cores = 6)`, uses that many cores. On a computing cluster, use the number of cores your job was given; `parallel::detectCores()` may report all cores of the node.
- **Memory.** Forked processes share the memory of the R session until they change it. Each socket worker holds its own copy of the model and its data; with large models, fewer workers use less memory.
- **Multiple starts.** `ncores` in `run_acl()` and `run_alscl()` sets how many starts run at once; the standard errors are computed afterwards, once, with `sd_cores`.
- **Your own parallel loops.** If you run many fits in parallel yourself (for example with `parallel::mclapply()`, `foreach` or `future`), set `alscl_speed(sd_cores = 1)` inside the workers, so that each fit uses one core. `retro_model()` and `sim_acl()` do this for their workers automatically.

## 6. The TMBad option

TMB can compile a model with one of two automatic-differentiation libraries. CppAD, the default, is also the AD library used in ALSCL 2.0.0; refinement and model changes can alter results. TMBad evaluates the Laplace approximation and its gradient several times faster:

```r
alscl_speed(framework = "TMBad")   # the next fit compiles the model with TMBad once
```

TMBad computes the same derivatives in a different order, so results differ in the last digits. In the benchmark, with 5 estimated fixed effects, estimates differed by at most 2.3e-11 (relative). In an ACL fit with 10 estimated fixed effects they differed by up to 2.7e-8 (relative; the objective function by 1.7e-11): with more free parameters the likelihood is flatter, and small differences move the point at which `nlminb()` stops within its tolerance.

Use TMBad for exploratory fits, many fits (simulation studies, sensitivity runs) and anywhere differences of this size do not matter. Use CppAD to reproduce published or earlier results exactly. To check on your own data, fit both and compare:

```r
args <- x  # YTF_example
alscl_speed(framework = "CppAD"); a <- run_alscl(args)
alscl_speed(framework = "TMBad"); b <- run_alscl(args)
max(abs(b$opt$par - a$opt$par) / abs(a$opt$par))   # largest relative difference in estimates
max(abs(b$est_std[, 2] - a$est_std[, 2]) / a$est_std[, 2], na.rm = TRUE)  # standard errors
```

Here `args` is the list of arguments you pass to `run_alscl()`.

## 7. Checking and recording the settings

- Before fitting, `alscl_speed_info()` shows the setting, the cores and method that will be used, the reason, the AD library and a reminder that cross-version identity is not guaranteed.
- After fitting, `fit$sd_info` gives `method` (`"forked processes"`, `"socket workers (delta method)"` or `"sequential"`), `cores`, `seconds` and a `note` explaining a sequential calculation. With `silent = FALSE` the same information is printed.
- When you report results, record `alscl_speed_info()` with `sessionInfo()`. With the default settings, results do not depend on the number of cores or the method; with `framework = "TMBad"` they differ slightly from CppAD, so state which library was used.

## 8. Measured speed-up

In a benchmark of 90 fits (ACL and ALSCL fitted to `YTF_example` and the flatfish and tuna cases, three runs each, Apple M2 Pro shared with other jobs, macOS terminal so forked processes):

| Model, data | Original | Default | TMBad |
|---|---:|---:|---:|
| ACL, YTF_example | 8.6 s | 7.7 s (1.13x) | 6.6 s (1.31x) |
| ALSCL, YTF_example | 140.9 s | 118.8 s (1.19x) | 83.9 s (1.68x) |
| ALSCL, flatfish | 107.8 s | 86.9 s (1.24x) | 78.8 s (1.37x) |
| ALSCL, tuna (quarterly) | 217.4 s | 180.9 s (1.20x) | 141.3 s (1.54x) |

![Fit time before and after the speed settings](../../../docs/figures/speed/timing.png)

With the default settings every result was identical to the original code; the figure below shows all 4,365 rows of `summary(sdreport)` for the ALSCL `YTF_example` fit.

![Estimates and standard errors before and after the speed settings](../../../docs/figures/speed/agreement.png)

In a simulated RStudio session (macOS with `RSTUDIO=1`, so socket workers; load average about 12 on 10 cores), the standard errors of the 20-year ALSCL fit took 25.4 s on four socket workers instead of 28.3 s sequentially, and the whole fit 114.9 s instead of 120.4 s, with identical results. With socket workers the gain comes from the delta method only; the Hessian, computed in the main session, takes about half of the standard-error time. On macOS or Linux, `options(ALSCL.sd_backend = "fork")` gives the speed of forked processes in RStudio as well (section 4.2).

The gain grows with the number of estimated fixed effects (more Hessian columns) and ADREPORT quantities (longer time series, more length classes). For an ACL fit with 10 fixed effects, the standard errors took 1.6 s on four forked processes instead of 3.7 s.

## 9. Troubleshooting

| Message or symptom | Meaning and what to do |
|---|---|
| `Parallel standard errors failed (...); computing them sequentially.` | Processes could not be started or a worker failed. The standard errors were computed sequentially and are correct. If it happens often, set `alscl_speed(sd_cores = 1)`. |
| `Standard errors: sequential (TMB x.y.z was not checked)` | The parallel code reproduces `TMB::sdreport()` of the checked TMB versions only. Results are correct; to use a new TMB version in parallel, run the package tests with it (`tests/testthat/test-speed.R`) and add it to the list in `R/speed.R`. |
| `Standard errors: sequential (too little work to start socket workers)` | In a GUI front-end or on Windows, the model was small enough that starting workers would not save time. |
| No speed-up in RStudio | See `alscl_speed_info()`. With socket workers only the delta method is shared out (section 4.2); on macOS or Linux, `options(ALSCL.sd_backend = "fork")` gives the full speed-up at your own risk. |
| Memory errors with many cores | Use fewer cores, for example `alscl_speed(sd_cores = 2)`. |
| The first fit after `alscl_speed(framework = "TMBad")` is slow | The model is compiled once for TMBad; later fits in the session reuse it. |

## 10. Advanced options

These options are for testing and special cases; the defaults suit normal use.

| Option | Effect |
|---|---|
| `options(ALSCL.sd_backend = "fork")` | Use forked processes even where R advises against it (never on Windows) |
| `options(ALSCL.sd_backend = "socket")` | Use socket workers even where forking is safe |
| `options(ALSCL.sd_socket_min_seconds = 3)` | Minimum estimated time of the delta method, in seconds, before socket workers are started; `0` always starts them |
| `options(ALSCL.tmb.cache = path)` | Folder for compiled models |

Reset an option with, for example, `options(ALSCL.sd_backend = NULL)`.
