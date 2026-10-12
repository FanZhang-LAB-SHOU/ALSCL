# Speed-up of ALSCL model fitting: change and results report

Report date: 12 October 2026. Branch: [`dev`](https://github.com/Linbojun99/ALSCL/tree/dev), compared with `main` at ALSCL 2.0.0 (commit [`4dc1fc3`](https://github.com/Linbojun99/ALSCL/commit/4dc1fc3a69b5140c898b61a57a8c023cdbcbba6b)). Full diff: [main...dev](https://github.com/Linbojun99/ALSCL/compare/main...dev). This report summarises the change for review; the detailed record is [docs/SPEED.md](SPEED.md).

## 1. Summary

The aim was to make `run_acl()` and `run_alscl()` faster without changing their results. Two changes were kept, both set with the new exported function `alscl_speed()`:

1. **Standard errors on several cores** (`sd_cores`, default `"auto"`: up to four physical cores, one kept free). The fixed-effect Hessian and the delta-method standard errors of the ADREPORT quantities are computed in forked processes. The result is identical (`identical()`) to the sequential `TMB::sdreport()`.
2. **TMBad automatic differentiation** (`framework`, default `"TMBad"`). Models are compiled with TMB's TMBad library instead of CppAD, the library used by ALSCL 2.0.0. Results differ from CppAD only by floating-point rounding; `alscl_speed(framework = "CppAD")` reproduces ALSCL 2.0.0 bit for bit.

In a benchmark of 90 fits (six model and data combinations, five settings, three repeats), fits with the default settings were 1.25-1.68 times faster than the original code. With CppAD, every estimate and standard error was identical to the original code; with TMBad, the largest difference was 2.3e-11 (relative). All 300 existing tests and 44 new tests pass.

## 2. Commits

| Commit | Content |
|---|---|
| [`4402f78`](https://github.com/Linbojun99/ALSCL/commit/4402f780cb35e8272f003cbfc1e699648261b4df) | Code, tests and help page: `R/speed.R` (new), changes to `R/model_fit.R`, `R/compile_acl.R`, `R/retro_model.R`, `R/sim_acl.R`, `DESCRIPTION`, `NAMESPACE`, `man/alscl_speed.Rd`, `tests/testthat/test-speed.R` |
| [`7bf2c5a`](https://github.com/Linbojun99/ALSCL/commit/7bf2c5a652e657d46a53280eb6a3d97d7918be91) | Documentation and benchmark: `docs/SPEED.md`, `scripts/benchmark_speed.R`, `docs/results/speed/` (raw runs, summary, environment), README and NEWS entries |

Size: 16 files, 744 lines added, 14 removed. The TMB templates (`inst/extdata/*.cpp`) are unchanged.

## 3. What changed, file by file

| File | Change |
|---|---|
| [`R/speed.R`](https://github.com/Linbojun99/ALSCL/blob/4402f780cb35e8272f003cbfc1e699648261b4df/R/speed.R) | New. `alscl_speed()` (L35), the core resolver `.acl_cores()` (L58), `.acl_mclapply()` (L71, `mclapply` that turns worker failures into an error of class `acl_parallel_error`), `.acl_optimhess()` (L92, parallel `stats::optimHess()`), `.acl_delta_sd()` (L113, parallel delta method), `.acl_sdreport()` (L170, the replacement for the `TMB::sdreport()` call). |
| [`R/model_fit.R`](https://github.com/Linbojun99/ALSCL/blob/4402f780cb35e8272f003cbfc1e699648261b4df/R/model_fit.R#L151) | One line: `TMB::sdreport(obj, par.fixed = opt$par, getReportCovariance = FALSE)` becomes `.acl_sdreport(obj, opt$par)`. |
| [`R/compile_acl.R`](https://github.com/Linbojun99/ALSCL/blob/4402f780cb35e8272f003cbfc1e699648261b4df/R/compile_acl.R#L6-L30) | `.acl_compile()` gains `framework`, passes it to `TMB::compile()` and adds it to the cache key, so models compiled with each library are kept apart. |
| [`R/retro_model.R`](https://github.com/Linbojun99/ALSCL/blob/4402f780cb35e8272f003cbfc1e699648261b4df/R/retro_model.R#L193-L195), [`R/sim_acl.R`](https://github.com/Linbojun99/ALSCL/blob/4402f780cb35e8272f003cbfc1e699648261b4df/R/sim_acl.R#L61-L63) | Socket workers receive the main process's AD library and `sd_cores = 1`, so parallel peels or replicates do not each fork further processes. |
| `DESCRIPTION` | `TMB (>= 1.9.0)`; `Matrix` added to Imports (for `Matrix::solve`). |
| [`tests/testthat/test-speed.R`](https://github.com/Linbojun99/ALSCL/blob/4402f780cb35e8272f003cbfc1e699648261b4df/tests/testthat/test-speed.R) | Settings validation; `identical()` checks of the parallel Hessian and of the whole sdreport object against TMB for both models with random effects; fits with one and two cores give identical `est_std`; TMBad and CppAD fits agree to rounding. |

## 4. Why the parallel standard errors are identical

`TMB::sdreport(..., getReportCovariance = FALSE)` spends its time in two independent loops: the columns of `stats::optimHess()` and the per-quantity delta method. `.acl_sdreport()`:

1. computes the fixed-effect Hessian with `.acl_optimhess()`;
2. calls `TMB::sdreport(obj, par.fixed, hessian.fixed = H, getReportCovariance = FALSE, skip.delta.method = TRUE)`, so TMB itself computes everything except the delta method (including `cov.fixed`, `pdHess`, `par.random` and `diag.cov.random`);
3. checks that `obj$env$last.par` holds the estimates and the joint mode reported by TMB, and that the recomputed ADREPORT values are identical to TMB's;
4. runs the delta method of TMB 1.9.x (`doDeltaMethod(chunk = i)`, copied step by step) for each quantity in forked processes, and inserts the standard errors.

Points that make the result identical rather than nearly equal:

- R's C routine behind `optimHess()` resets coordinate j to ((p + 0.001) - 0.002) + 0.001 after column j; later columns use that value. `.acl_optimhess()` reproduces it.
- With random effects, every gradient call starts the inner Newton optimisation from `obj$env$last.par.best`, which only objective-function calls update. So each column starts from the same point in the sequential and the parallel calculation. (The porting guide from ALSCLtuna expected only tolerance-level agreement here; the parallel Hessian turned out to be identical.)
- The sparse solve must be `Matrix::solve()`. Inside the package namespace, `solve()` dispatched to base R, which made the matrix dense and changed the standard errors by about 1e-16.

Fallbacks: one core, Windows (no fork), TMB outside 1.9.x, or any worker failure use the sequential `TMB::sdreport()` (a worker failure also gives a warning).

## 5. Results

### 5.1 Profile before the change

20-year `YTF_example`, ALSCL conditional fit (5 fixed effects, 494 random effects, `train_times = 2`), original code: 100-111 s in total, of which about 88 s was the outer optimisation, 11.4 s the fixed-effect Hessian and 10.6 s the delta method for 3,866 ADREPORT quantities.

### 5.2 Benchmark

Six combinations: ACL and ALSCL fitted to `YTF_example` (20 years), and the flatfish (20 years) and tuna (20 quarters) cases in `docs/data/cases`, with the conditional configurations of `scripts/case_studies.R`. Each fit ran three times in a fresh R process, settings in rotating order, compilation excluded. Apple M2 Pro (10 cores, 32 GiB), R 4.6.0, TMB 1.9.21, Matrix 1.7.5. Other jobs ran on the computer throughout (one-minute load average 12-27, median 16), which lengthens elapsed times and reduces the gain from several cores.

**Table 1.** Median elapsed time per fit including standard errors; speed-up relative to the original code in parentheses.

| Data | Model | Random effects | Original | CppAD, 4 cores | TMBad, 1 core | TMBad, 4 cores (default) |
|---|---|---:|---:|---:|---:|---:|
| YTF_example | ACL | 334 | 8.6 s | 7.7 s (1.13) | 7.3 s (1.18) | 6.6 s (1.31) |
| YTF_example | ALSCL | 494 | 140.9 s | 118.8 s (1.19) | 97.3 s (1.45) | 83.9 s (1.68) |
| flatfish | ACL | 334 | 9.0 s | 7.4 s (1.21) | 7.9 s (1.13) | 7.2 s (1.25) |
| flatfish | ALSCL | 494 | 107.8 s | 86.9 s (1.24) | 85.6 s (1.26) | 78.8 s (1.37) |
| tuna | ACL | 439 | 14.3 s | 11.8 s (1.21) | 13.1 s (1.09) | 11.3 s (1.27) |
| tuna | ALSCL | 499 | 217.4 s | 180.9 s (1.20) | 153.9 s (1.41) | 141.3 s (1.54) |

CPU time, which other jobs affect less, gave the same picture: TMBad on one core reduced the CPU time of the ALSCL fits by a factor of 1.35-1.42 and of the ACL fits by 1.06-1.16. In a separate run on a less busy computer, the standard errors of the 20-year ALSCL fit (CppAD) took 9.0 s on four cores instead of 23.4 s.

**Table 2.** Largest difference between TMBad and the original code (identical with one and four cores). Reported values are the random effects and ADREPORT quantities, divided by the largest absolute value of the same quantity.

| Data | Model | Estimates (relative) | Objective (absolute) | Reported values | Standard errors (relative) |
|---|---|---:|---:|---:|---:|
| YTF_example | ACL | 4.2e-12 | 5.7e-12 | 7.6e-12 | 7.6e-12 |
| YTF_example | ALSCL | 3.1e-15 | 1.0e-11 | 6.7e-15 | 2.2e-13 |
| flatfish | ACL | 5.2e-13 | 3.0e-12 | 7.7e-13 | 7.8e-13 |
| flatfish | ALSCL | 1.1e-14 | 1.6e-12 | 2.3e-14 | 3.3e-13 |
| tuna | ACL | 6.1e-15 | 3.4e-13 | 6.1e-15 | 4.4e-13 |
| tuna | ALSCL | 2.2e-11 | 1.5e-11 | 2.2e-11 | 2.3e-11 |

With CppAD (one or four cores), estimates, objective and every row of `summary(sdreport)` were identical to the original code in all six combinations. All 90 fits converged with a positive definite Hessian and a maximum absolute gradient below 2e-4. Raw data: [`docs/results/speed/runs.csv`](results/speed/runs.csv), [`summary.csv`](results/speed/summary.csv).

### 5.3 Candidate changes tested and not kept

| Change | Result | Decision |
|---|---|---|
| Atomic matrix product (`atomic::matmul`) for the growth transition `G * survival` | CppAD: fit 168 s instead of 100 s. TMBad: faster, but estimates moved by up to 1.4e-8 and reported quantities by up to 5e-6 (relative), because the optimiser took a different path. | Not kept |
| Leave derived quantities (biomass, catch, F-at-age arrays) out of the tape during optimisation | Gradient 0.155 s instead of 0.172 s, within run-to-run variation; TMB already removes operations that do not affect the objective function. | Not kept |
| Newton steps with the AD Hessian after `nlminb()` | Not available with random effects (`obj$he()`). | Not applicable |
| Fewer ADREPORT quantities | Small remaining gain after the parallel delta method; the plotting functions use all reported quantities. | Not added |
| TMBad compressed sparse Hessian (`tmbad.sparse_hessian_compress = 1`) | Gradient 1.8 s instead of 0.3 s; results not identical. | Not kept |

## 6. Points for review

1. **TMBad as the default.** The differences in Table 2 are far below the convergence tolerances of `nlminb()` (1e-10 for the objective function, 1.5e-8 for the parameters), but they are larger than the 1e-12 accepted for ALSCLtuna, which has no random effects. The alternative is CppAD as the default and TMBad as an option.
2. **Dependence on TMB internals.** `.acl_sdreport()` and `.acl_delta_sd()` use `obj$env$spHess`, `obj$env$f` (with `rangeweight`, `doforward = 0` and `type = "ADGrad"`), `obj$env$L.created.by.newton`, the TMB 1.9.x semantics of `last.par.best`, and a copy of the delta-method code of TMB 1.9.21. The version guard (`1.9.0 <= TMB < 1.10.0`) and the identity checks in step 3 of section 4 are meant to catch changes in TMB; please check whether they are sufficient.
3. **Fork-based parallelism.** `parallel::mclapply()` on macOS and Linux; sequential on Windows. Fits run inside a user's own parallel loop should set `sd_cores = 1` (documented, not detected automatically).
4. **Not yet tested:** fits that estimate more fixed effects (10-15 in typical assessments; the benchmark used 5), Windows and Linux, and a benchmark on an idle computer.
5. **Not yet updated:** the documentation website and `docs/FUNCTION_REFERENCE.md` ("43 public functions"; `alscl_speed()` makes 44).

## 7. How to reproduce

```bash
git clone https://github.com/Linbojun99/ALSCL.git && cd ALSCL && git checkout dev
Rscript -e 'devtools::test()'
git archive 4dc1fc3 | (mkdir -p /tmp/alscl-original && tar -x -C /tmp/alscl-original)
Rscript scripts/benchmark_speed.R /tmp/alscl-original docs/results/speed 3
```

The tests compile both templates with both AD libraries, which takes several minutes; the benchmark takes about 90 minutes. On macOS with a non-ASCII path, set `LC_ALL=en_US.UTF-8`.
