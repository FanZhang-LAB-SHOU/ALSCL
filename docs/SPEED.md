# Speed settings and how the results were checked

This page records the changes that make `run_acl()` and `run_alscl()` faster, how each change was checked against the original code (ALSCL 2.0.0, commit [`4dc1fc3`](https://github.com/Linbojun99/ALSCL/commit/4dc1fc3)), and which candidate changes were rejected. The changes come from the speed-up scheme developed for the tuna version of the model (ALSCLtuna). ALSCL estimates three sets of random effects with the Laplace approximation, which ALSCLtuna does not, so each part of the scheme was tested again here; the parts that were not kept are listed in section 4.

The work had four steps:

1. Profile one ALSCL fit to find where the time goes (section 2).
2. Implement each candidate change and compare its results with the original code (sections 3 and 4).
3. Keep the changes that leave results identical, or that change them only by floating-point rounding; reject the rest (section 4).
4. Benchmark the original code against the kept changes on six model and data combinations (section 5). With the default settings, fits were 1.25-1.68 times faster, and results differed from the original code by at most 2.3e-11 (relative).

Both kept changes are set with `alscl_speed()`:

```r
library(ALSCL)
alscl_speed()                      # defaults: sd_cores = "auto", framework = "TMBad"
alscl_speed(framework = "CppAD")   # reproduce ALSCL 2.0.0 results bit for bit
alscl_speed(sd_cores = 1)          # sequential standard errors
```

## 1. When results count as unchanged

The rule carried over from ALSCLtuna is that a speed change may alter how quantities are computed but not the results:

- A change that can give identical results must give identical results, checked with `identical()` on the estimates, the objective function and every row of `summary(sdreport)`.
- A change that alters the order of floating-point operations is accepted only if the differences in the estimates and the objective function are far below the convergence tolerances of `nlminb()` (relative tolerance 1e-10 for the objective function and 1.5e-8 for the parameters), and the standard errors differ by less than 1e-7 (relative). The standard errors use a Hessian from finite differences of the gradient, which magnifies rounding error. In ALSCLtuna, which has no random effects, such changes gave relative differences of about 1e-12; in ALSCL the rounding differences also pass through the inner Newton optimisation over the random effects.
- Changes that alter the model or the optimisation (for example, fewer random effects or looser inner-optimisation tolerances) are not considered.

## 2. Where the time goes

In single runs, with fewer other jobs on the computer than during the benchmark in section 5, a conditional fit of ALSCL to the 20 annual years of `YTF_example` (23 length classes, 15 ages; 5 estimated fixed effects and 494 random effects; `train_times = 2`) took 100-111 s with the original code. Of this, about 88 s was the outer optimisation (`nlminb()`, each call of the objective function or its gradient running the inner Newton optimisation over the random effects), 11.4 s was the fixed-effect Hessian for the standard errors (`stats::optimHess()`, 10 gradient evaluations), and 10.6 s was the delta method for the 3,866 ADREPORT quantities (one calculation per quantity). At the optimum, one objective evaluation took 0.21 s and one gradient evaluation 0.65 s.

## 3. Changes kept

### 3.1 Standard errors on several cores (`sd_cores`)

`TMB::sdreport(..., getReportCovariance = FALSE)`, which `run_acl()` and `run_alscl()` call after the optimisation, does two expensive things in sequence:

- It computes the fixed-effect Hessian with `stats::optimHess()`: for each fixed effect, the gradient with that parameter increased and decreased by 0.001. The columns do not depend on each other.
- It applies the delta method to each ADREPORT quantity separately. TMB records the operations of the model once (the tape) and obtains derivatives by sweeping through the tape; each quantity needs one reverse sweep of the ADREPORT tape, one sparse solve with the random-effect Hessian and one reverse sweep of the gradient tape. The quantities do not depend on each other.

`.acl_sdreport()` (in `R/speed.R`) computes the Hessian columns and the delta method for groups of quantities in forked processes, and leaves every other step to `TMB::sdreport()` itself (called with `hessian.fixed` and `skip.delta.method = TRUE`). The returned object is identical to that of the sequential `TMB::sdreport()`: in the tests every component (`value`, `sd`, `cov.fixed`, `gradient.fixed`, `par.random`, `diag.cov.random` and `summary()`) passes `identical()` for both models.

Two details make the results identical rather than nearly equal:

- `optimHess()` (R's C routine `optimhess`) reuses one parameter vector and, after each column j, resets coordinate j to ((p + 0.001) - 0.002) + 0.001, which can differ from p in the last bit. Later columns are evaluated at that value, so the parallel version reproduces it.
- With random effects, each gradient call starts the inner Newton optimisation from `obj$env$last.par.best`. Only calls of the objective function update it, never gradient calls, so in the sequential `optimHess()` every column starts from the same point, and each forked process starts from that point too.

On the 20-year ALSCL fit compiled with CppAD, the standard errors took 9.0 s on four cores instead of 23.4 s. On Windows, where R cannot fork processes, and for one core, the sequential `TMB::sdreport()` is used. If a forked process fails, the calculation is repeated sequentially with a warning. The parallel code reproduces the delta method of TMB 1.9.x; other TMB versions use the sequential `TMB::sdreport()`.

### 3.2 TMBad automatic differentiation (`framework`)

TMB can compile a model with one of two automatic-differentiation (AD) libraries: CppAD, its default, and TMBad, its newer library. ALSCL 2.0.0 used CppAD. The model code is the same for both; only the compiler setting (`TMB::compile(..., framework = "TMBad")`) changes. On the 20-year ALSCL fit at the optimum, TMBad evaluated the objective function in 0.010 s instead of 0.21 s, and the gradient in 0.20 s instead of 0.65 s. The whole fit became faster by a smaller factor (section 5).

TMBad computes the same derivatives with a different order of floating-point operations, so results differ from those under CppAD only by rounding (section 5). The AD library is part of the key of the compiled-model cache, so models compiled with each library are kept apart. `alscl_speed(framework = "CppAD")` compiles the original way and, together with any `sd_cores`, reproduces the results of ALSCL 2.0.0 bit for bit (checked in section 5).

## 4. Changes tested and not kept

| Candidate change | Result in ALSCL | Decision |
|---|---|---|
| Growth transition product `G * survival` with TMB's atomic matrix product (`atomic::matmul`) | Under CppAD the fit took 168 s instead of 100 s (gradient 1.19 s instead of 0.65 s). Under TMBad it was faster (55 s instead of 71 s) but moved the estimates by up to 1.4e-8 and the reported quantities by up to 5e-6 (relative), because the optimiser took a different path. | Not kept: slower, or results changed beyond rounding |
| Leave quantities that do not enter the likelihood (biomass, catch and F-at-age arrays) out of the tape during the optimisation | The gradient took 0.155 s instead of 0.172 s, within run-to-run variation; TMB already removes operations that do not affect the objective function when it optimises the tape. | Not kept: no measurable gain |
| Newton steps with the AD Hessian after `nlminb()` | Not applicable: with random effects the fixed-effect AD Hessian (`obj$he()`) is not available. | Not applicable |
| Report fewer ADREPORT quantities | With parallel standard errors the delta method takes a few seconds, and the plotting functions use all reported quantities. | Not added |
| TMBad's compressed sparse Hessian (`TMB::config(tmbad.sparse_hessian_compress = 1)`), not part of the ALSCLtuna scheme | The gradient took 1.8 s instead of 0.3 s and the fit about twice as long; results were not identical. | Not kept: slower |

## 5. Benchmark

The benchmark measured the gain of each setting on fits like those of the case studies, and repeated the result checks of section 1 on more data. ACL and ALSCL were fitted to three data sets: `YTF_example` (20 annual years), and the flatfish (20 annual years) and tuna (20 quarters) cases in `docs/data/cases`. The fits used the conditional configurations of `scripts/case_studies.R` and the bundled `fit_config`: 5 estimated fixed effects, 334-499 random effects and `train_times = 2`. Five settings were compared: the original code (ALSCL 2.0.0) and the new code with CppAD or TMBad, each with one core or `sd_cores = "auto"` (four cores on this computer) for the standard errors. Each fit ran three times in a fresh R process, with the order of the settings rotated; compilation was excluded. The computer was an Apple M2 Pro (10 cores, 32 GiB) with R 4.6.0, TMB 1.9.21 and Matrix 1.7.5.

Other users' jobs ran on the computer throughout (one-minute load average 12-27 on 10 cores, median 16), so elapsed times are longer than on an idle computer and varied by up to a factor of 1.7 between repeats; the gain from several cores is also smaller than without other jobs. Table 1 gives medians; CPU time, which other jobs affect less, is in `docs/results/speed/summary.csv`. Without parallel standard errors, TMBad reduced the CPU time of the ALSCL fits by a factor of 1.35-1.42 and of the ACL fits by 1.06-1.16.

**Table 1.** Median elapsed time of one fit, including standard errors, and speed-up relative to the original code (in parentheses).

| Data | Model | Random effects | ADREPORT quantities | Original | CppAD, 4 cores | TMBad, 1 core | TMBad, 4 cores (default) |
|---|---|---:|---:|---:|---:|---:|---:|
| YTF_example | ACL | 334 | 1,160 | 8.6 s | 7.7 s (1.13) | 7.3 s (1.18) | 6.6 s (1.31) |
| YTF_example | ALSCL | 494 | 3,866 | 140.9 s | 118.8 s (1.19) | 97.3 s (1.45) | 83.9 s (1.68) |
| flatfish | ACL | 334 | 1,160 | 9.0 s | 7.4 s (1.21) | 7.9 s (1.13) | 7.2 s (1.25) |
| flatfish | ALSCL | 494 | 3,866 | 107.8 s | 86.9 s (1.24) | 85.6 s (1.26) | 78.8 s (1.37) |
| tuna | ACL | 439 | 1,360 | 14.3 s | 11.8 s (1.21) | 13.1 s (1.09) | 11.3 s (1.27) |
| tuna | ALSCL | 499 | 4,361 | 217.4 s | 180.9 s (1.20) | 153.9 s (1.41) | 141.3 s (1.54) |

With CppAD, on one core or four, the estimates, the objective function and every row of `summary(sdreport)` were identical to those of the original code in all six combinations. With TMBad, the results differed only by rounding (Table 2), far below the tolerances of section 1. The differences were the same with one and four cores, because the parallel standard errors are identical to the sequential ones. All 90 fits converged (`nlminb()` code 0) with a positive definite Hessian and a maximum absolute gradient below 2e-4.

**Table 2.** Largest difference between TMBad and the original code. Estimates and standard errors: relative difference. Objective function: absolute difference in the negative log-likelihood. Reported values: difference in the estimates of the random effects and ADREPORT quantities, divided by the largest absolute value of the same quantity, so that values near zero (for example random effects) do not inflate the relative difference.

| Data | Model | Estimates | Objective function | Reported values | Standard errors |
|---|---|---:|---:|---:|---:|
| YTF_example | ACL | 4.2e-12 | 5.7e-12 | 7.6e-12 | 7.6e-12 |
| YTF_example | ALSCL | 3.1e-15 | 1.0e-11 | 6.7e-15 | 2.2e-13 |
| flatfish | ACL | 5.2e-13 | 3.0e-12 | 7.7e-13 | 7.8e-13 |
| flatfish | ALSCL | 1.1e-14 | 1.6e-12 | 2.3e-14 | 3.3e-13 |
| tuna | ACL | 6.1e-15 | 3.4e-13 | 6.1e-15 | 4.4e-13 |
| tuna | ALSCL | 2.2e-11 | 1.5e-11 | 2.2e-11 | 2.3e-11 |

To repeat the benchmark (about 90 minutes), from the repository root:

```bash
git archive 4dc1fc3 | (mkdir -p /tmp/alscl-original && tar -x -C /tmp/alscl-original)
Rscript scripts/benchmark_speed.R /tmp/alscl-original docs/results/speed 3
```

The script writes every fit to `runs.csv` (elapsed and CPU time, load average, convergence) and the comparison with the original code to `summary.csv`, in which `n_report` counts all rows of `summary(sdreport)` (fixed effects, random effects and ADREPORT quantities).

## 6. Implementation notes

- Inside the package namespace, `solve()` on the sparse random-effect Hessian must be `Matrix::solve()`. Base R's `solve()` converts the matrix to dense and uses LAPACK, which changed the standard errors by about 1e-16 (relative) and broke `identical()`. TMB itself calls the Matrix method, which uses a sparse Cholesky factorisation.
- `TMB::sdreport(obj, hessian.fixed = optimHess(...))` evaluates the Hessian lazily inside `sdreport()`, after it has stored the random effects that maximise the joint likelihood at the estimates (the joint mode), and leaves `obj$env$last.par` at the last finite-difference point. `.acl_sdreport()` therefore computes the Hessian first, and checks that `obj$env$last.par` holds the estimates and the joint mode before the delta method starts.
- Socket workers that fit models themselves (`retro_model()`, `sim_acl()`) receive the AD library of the main process and use one core for standard errors, so the number of processes does not multiply. Fits run in a user's own parallel loop should use `alscl_speed(sd_cores = 1)`.
- Benchmarks were run on frozen copies of the code (`git archive`), because `pkgload::load_all()` reads the source when each process starts.
