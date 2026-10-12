# Speed-up of ALSCL model fitting: change and results report

Report date: 12 October 2026 (revised after review). Branch: [`dev`](https://github.com/Linbojun99/ALSCL/tree/dev), compared with `main` at ALSCL 2.0.0 (commit [`4dc1fc3`](https://github.com/Linbojun99/ALSCL/commit/4dc1fc3a69b5140c898b61a57a8c023cdbcbba6b)). Full diff: [main...dev](https://github.com/Linbojun99/ALSCL/compare/main...dev); changes since the first review: [54f1350...dev](https://github.com/Linbojun99/ALSCL/compare/54f1350...dev). This report summarises the change for review; the detailed record is [docs/SPEED.md](SPEED.md).

## 1. Summary

The aim was to make `run_acl()` and `run_alscl()` faster without changing their results. Two changes are set with the new exported function `alscl_speed()`:

1. **Standard errors on several cores** (`sd_cores`, default `"auto"`). The fixed-effect Hessian and the delta-method standard errors of the ADREPORT quantities are computed in forked processes. The result is identical (`identical()`) to the sequential `TMB::sdreport()`. `"auto"` uses up to four physical cores and keeps one free, and one core on Windows, in GUI or embedded front-ends and with Apple's Accelerate BLAS.
2. **TMBad automatic differentiation** (`framework = "TMBad"`, an option). The default remains CppAD, the library used by ALSCL 2.0.0. TMBad is faster but its results are not identical.

With the default settings, results are identical to ALSCL 2.0.0 and fits were 1.13-1.24 times faster in a benchmark of 90 fits (six model and data combinations, five settings, three repeats). With TMBad, fits were 1.25-1.68 times faster; estimates differed from the original code by up to 2.3e-11 (relative) in the six combinations, which estimate 5 fixed effects, and by up to 2.7e-8 in an ACL fit that estimates 10. All 322 tests pass (256 existing and 66 in the new `test-speed.R`).

## 2. Commits

| Commit | Content |
|---|---|
| [`4402f78`](https://github.com/Linbojun99/ALSCL/commit/4402f780cb35e8272f003cbfc1e699648261b4df) | First version of the code, tests and help page |
| [`7bf2c5a`](https://github.com/Linbojun99/ALSCL/commit/7bf2c5a652e657d46a53280eb6a3d97d7918be91) | Documentation (`docs/SPEED.md`), benchmark script and results (`docs/results/speed/`), README and NEWS |
| [`54f1350`](https://github.com/Linbojun99/ALSCL/commit/54f1350) | First version of this report (the version reviewed) |
| [`243469b`](https://github.com/Linbojun99/ALSCL/commit/243469b2f8104b31075d30a771d157c74f50a56b) | Fixes after review (section 6), CppAD as the default, website and function reference |

The TMB templates (`inst/extdata/*.cpp`) are unchanged.

## 3. What changed, file by file

Links point to commit `243469b`.

| File | Change |
|---|---|
| [`R/speed.R`](https://github.com/Linbojun99/ALSCL/blob/243469b2f8104b31075d30a771d157c74f50a56b/R/speed.R) | New. `alscl_speed()` (L39); `.acl_check_cores()` (L53); `.acl_fork_safe()` (L64, whether `"auto"` may fork); `.acl_cores()` (L74); `.acl_tmb_checked` and `.acl_tmb_supported()` (L89-L90, TMB versions the parallel delta method was checked against); `.acl_mclapply()` (L100, turns a failure to fork or a worker failure into an error of class `acl_parallel_error`); `.acl_optimhess()` (L120, parallel `stats::optimHess()`); `.acl_delta_sd()` (L141, parallel delta method); `.acl_sdreport()` (L198, the replacement for the `TMB::sdreport()` call). |
| [`R/model_fit.R`](https://github.com/Linbojun99/ALSCL/blob/243469b2f8104b31075d30a771d157c74f50a56b/R/model_fit.R#L151) | One line: `TMB::sdreport(obj, par.fixed = opt$par, getReportCovariance = FALSE)` becomes `.acl_sdreport(obj, opt$par)`. |
| [`R/compile_acl.R`](https://github.com/Linbojun99/ALSCL/blob/243469b2f8104b31075d30a771d157c74f50a56b/R/compile_acl.R#L6-L30) | `.acl_compile()` gains `framework`, passes it to `TMB::compile()` and adds it to the cache key. |
| [`R/retro_model.R`](https://github.com/Linbojun99/ALSCL/blob/243469b2f8104b31075d30a771d157c74f50a56b/R/retro_model.R#L193-L195), [`R/sim_acl.R`](https://github.com/Linbojun99/ALSCL/blob/243469b2f8104b31075d30a771d157c74f50a56b/R/sim_acl.R#L61-L63) | Socket workers receive the main process's AD library and `sd_cores = 1`. |
| `DESCRIPTION` | `TMB (>= 1.9.0)`; `Matrix` added to Imports (for `Matrix::solve`). |
| [`tests/testthat/test-speed.R`](https://github.com/Linbojun99/ALSCL/blob/243469b2f8104b31075d30a771d157c74f50a56b/tests/testthat/test-speed.R) | Settings and input validation (including `Inf`, `NA`, `2^31`); fork-safety rules; TMB version list; `identical()` checks of the parallel Hessian and of the whole sdreport object against TMB for both models; a simulated failure to fork; one and two cores give identical `est_std`; TMBad and CppAD agree within 1e-8 on the test fixture. |
| `docs/FUNCTION_REFERENCE.md`, `website/build.py`, `website/check.py`, `website/reference-notes.json`, `website/content/*/news.md`, `docs/BOOK.md`, `docs/wiki/14-Function-Reference.md`, `README.md` | `alscl_speed()` added to the function reference, the website groups, the bilingual notes and the changelog; 43 changed to 44 functions. `BOOK.md` and the wiki were regenerated with `scripts/build_wiki.py`. |

## 4. Why the parallel standard errors are identical

`TMB::sdreport(..., getReportCovariance = FALSE)` spends its time in two independent loops: the columns of `stats::optimHess()` and the per-quantity delta method. `.acl_sdreport()`:

1. computes the fixed-effect Hessian with `.acl_optimhess()`;
2. calls `TMB::sdreport(obj, par.fixed, hessian.fixed = H, getReportCovariance = FALSE, skip.delta.method = TRUE)`, so TMB itself computes everything except the delta method (including `cov.fixed`, `pdHess`, `par.random` and `diag.cov.random`);
3. checks that `obj$env$last.par` holds the estimates and the joint mode reported by TMB, and that the recomputed ADREPORT values are identical to TMB's;
4. runs the delta method of TMB 1.9.21 (`doDeltaMethod(chunk = i)`, copied step by step) for each quantity in forked processes, and inserts the standard errors.

Points that make the result identical rather than nearly equal:

- R's C routine behind `optimHess()` resets coordinate j to ((p + 0.001) - 0.002) + 0.001 after column j; later columns use that value. `.acl_optimhess()` reproduces it.
- With random effects, every gradient call starts the inner Newton optimisation from `obj$env$last.par.best`, which only objective-function calls update. So each column starts from the same point in the sequential and the parallel calculation.
- The sparse solve must be `Matrix::solve()`. Inside the package namespace, `solve()` dispatched to base R, which made the matrix dense and changed the standard errors by about 1e-16.

The sequential `TMB::sdreport()` is used for one core, for TMB versions other than 1.9.21, and, with a warning, after any failure of the parallel calculation, including a failure to fork.

## 5. Results

### 5.1 Profile before the change

20-year `YTF_example`, ALSCL conditional fit (5 fixed effects, 494 random effects, `train_times = 2`), original code: 100-111 s in total, of which about 88 s was the outer optimisation, 11.4 s the fixed-effect Hessian and 10.6 s the delta method for 3,866 ADREPORT quantities.

### 5.2 Benchmark

Six combinations: ACL and ALSCL fitted to `YTF_example` (20 years), and the flatfish (20 years) and tuna (20 quarters) cases in `docs/data/cases`, with the conditional configurations of `scripts/case_studies.R`. Each fit ran three times in a fresh R process, settings in rotating order, compilation excluded. Apple M2 Pro (10 cores, 32 GiB), R 4.6.0, TMB 1.9.21, Matrix 1.7.5. Other jobs ran on the computer throughout (one-minute load average 12-27, median 16), which lengthens elapsed times and reduces the gain from several cores. The benchmark was run with the first version of the code; the fixes in section 6 do not change the computations it timed (`Rscript` is not a GUI front-end, and the default BLAS was R's own).

**Table 1.** Median elapsed time per fit including standard errors; speed-up relative to the original code in parentheses.

| Data | Model | Random effects | Original | CppAD, 4 cores (default) | TMBad, 1 core | TMBad, 4 cores |
|---|---|---:|---:|---:|---:|---:|
| YTF_example | ACL | 334 | 8.6 s | 7.7 s (1.13) | 7.3 s (1.18) | 6.6 s (1.31) |
| YTF_example | ALSCL | 494 | 140.9 s | 118.8 s (1.19) | 97.3 s (1.45) | 83.9 s (1.68) |
| flatfish | ACL | 334 | 9.0 s | 7.4 s (1.21) | 7.9 s (1.13) | 7.2 s (1.25) |
| flatfish | ALSCL | 494 | 107.8 s | 86.9 s (1.24) | 85.6 s (1.26) | 78.8 s (1.37) |
| tuna | ACL | 439 | 14.3 s | 11.8 s (1.21) | 13.1 s (1.09) | 11.3 s (1.27) |
| tuna | ALSCL | 499 | 217.4 s | 180.9 s (1.20) | 153.9 s (1.41) | 141.3 s (1.54) |

CPU time, which other jobs affect less, gave the same picture: TMBad on one core reduced the CPU time of the ALSCL fits by a factor of 1.35-1.42 and of the ACL fits by 1.06-1.16. In separate runs, the standard errors of the 20-year ALSCL fit (CppAD) took 9.0 s on four cores instead of 23.4 s, and those of an ACL fit with 10 fixed effects 1.58 s instead of 3.70 s (2.54 s in a repeat under heavier load); the results were identical.

**Table 2.** Largest difference between TMBad and the original code (identical with one and four cores). Reported values are the random effects and ADREPORT quantities, divided by the largest absolute value of the same quantity.

| Data | Model | Fixed effects | Estimates (relative) | Objective (absolute) | Reported values | Standard errors (relative) |
|---|---|---:|---:|---:|---:|---:|
| YTF_example | ACL | 5 | 4.2e-12 | 5.7e-12 | 7.6e-12 | 7.6e-12 |
| YTF_example | ALSCL | 5 | 3.1e-15 | 1.0e-11 | 6.7e-15 | 2.2e-13 |
| flatfish | ACL | 5 | 5.2e-13 | 3.0e-12 | 7.7e-13 | 7.8e-13 |
| flatfish | ALSCL | 5 | 1.1e-14 | 1.6e-12 | 2.3e-14 | 3.3e-13 |
| tuna | ACL | 5 | 6.1e-15 | 3.4e-13 | 6.1e-15 | 4.4e-13 |
| tuna | ALSCL | 5 | 2.2e-11 | 1.5e-11 | 2.2e-11 | 2.3e-11 |
| YTF_example, 5 more parameters freed | ACL | 10 | 2.7e-8 | 1.7e-11 | not computed | 3.5e-8 |

The last row was found in the review and reproduced: freeing `log_Linf`, `log_vbk`, `log_cv_len`, `log_std_log_N0` and `logit_log_R` in the bundled ACL configuration. The largest difference was in `logit_log_R` (4.1e-8 absolute); both fits converged with a positive definite Hessian, a maximum absolute gradient below 1e-4 and no parameter at a bound. The difference exceeds the parameter tolerance of `nlminb()` (1.5e-8), which is why TMBad is not the default.

With CppAD (one or four cores), estimates, objective and every row of `summary(sdreport)` were identical to the original code in all six combinations. All 90 benchmark fits converged with a positive definite Hessian and a maximum absolute gradient below 2e-4. Raw data: [`docs/results/speed/runs.csv`](results/speed/runs.csv), [`summary.csv`](results/speed/summary.csv).

### 5.3 Candidate changes tested and not kept

| Change | Result | Decision |
|---|---|---|
| Atomic matrix product (`atomic::matmul`) for the growth transition `G * survival` | CppAD: fit 168 s instead of 100 s. TMBad: faster, but estimates moved by up to 1.4e-8 and reported quantities by up to 5e-6 (relative), because the optimiser took a different path. | Not kept |
| Leave derived quantities (biomass, catch, F-at-age arrays) out of the tape during optimisation | Gradient 0.155 s instead of 0.172 s, within run-to-run variation; TMB already removes operations that do not affect the objective function. | Not kept |
| Newton steps with the AD Hessian after `nlminb()` | Not available with random effects (`obj$he()`). | Not applicable |
| Fewer ADREPORT quantities | Small remaining gain after the parallel delta method; the plotting functions use all reported quantities. | Not added |
| TMBad compressed sparse Hessian (`tmbad.sparse_hessian_compress = 1`) | Gradient 1.8 s instead of 0.3 s; results not identical. | Not kept |

## 6. Review of the first version and fixes

The first version (`54f1350`) was reviewed externally. Every finding was reproduced on that commit and fixed in `243469b`:

| Finding | Reproduced on `54f1350` | Fix and check on `243469b` |
|---|---|---|
| A failure to start forked processes was not caught | With `mclapply()` replaced by a function that signals "unable to fork", the fit returned `est_std = NULL`, `vcov = NULL`, `pdHess = NA` | Any error from `mclapply()` now triggers the sequential `TMB::sdreport()` with a warning. Same simulation: `est_std` and `vcov` present, `pdHess = TRUE`; a new test checks that they are identical to the sequential result |
| `sd_cores = Inf` accepted | Accepted; `as.integer(Inf)` later gave `NA` with a warning | The check requires a finite whole number between 1 and `.Machine$integer.max`; `Inf`, `NA`, `2^31`, vectors and strings are rejected (tested) |
| Website does not build | `website/build.py` requires an entry for every exported function; `alscl_speed` had none (`KeyError`) | Entry, notes and group added; `website/build.py` builds 136 pages and `website/check.py` passes with 44 functions per language |
| Test count "300 + 44" | The 300 already included the 44 new tests | Corrected; the suite now has 322 tests, 66 in `test-speed.R` |
| TMBad differences larger with 10 fixed effects | Estimates 2.7e-8 (relative), standard errors 3.5e-8 | TMBad is no longer the default (Table 2) |
| TMB version guard too wide | All TMB 1.9.x versions were allowed; only 1.9.21 was checked | Only the checked versions use the parallel delta method; the identity test runs the parallel code with any installed TMB (`check_version = FALSE`), so a new version can be added once it passes |
| Forking in unsuitable environments | `?parallel::mclapply` discourages forking in GUI or embedded front-ends and with multithreaded libraries | `"auto"` uses one core in R.app, RGui, RStudio and Positron and with Apple's Accelerate BLAS; an explicit number of cores is used as given (tested) |

## 7. Open points

1. **TMBad as an option.** Whether TMBad could become the default after more checks (fits that estimate more fixed effects, real data, Linux and Windows).
2. **Not yet tested:** Windows (sequential path) and Linux; a benchmark on an idle computer.
3. **Dependence on TMB internals.** `.acl_sdreport()` and `.acl_delta_sd()` use `obj$env$spHess`, `obj$env$f` (with `rangeweight`, `doforward = 0` and `type = "ADGrad"`), `obj$env$L.created.by.newton` and the TMB 1.9.21 semantics of `last.par.best`. The version list and the identity checks in step 3 of section 4 are meant to catch changes in TMB.
4. **Fits in a user's own parallel loop** should set `sd_cores = 1`; this is documented but not detected.

## 8. How to reproduce

```bash
git clone https://github.com/Linbojun99/ALSCL.git && cd ALSCL && git checkout dev
Rscript -e 'devtools::test()'
git archive 4dc1fc3 | (mkdir -p /tmp/alscl-original && tar -x -C /tmp/alscl-original)
Rscript scripts/benchmark_speed.R /tmp/alscl-original docs/results/speed 3
python3 -m venv .venv-docs && .venv-docs/bin/python -m pip install -r website/requirements.txt
.venv-docs/bin/python website/build.py && .venv-docs/bin/python website/check.py
```

The tests compile both templates with both AD libraries, which takes several minutes; the benchmark takes about 90 minutes. On macOS with a non-ASCII path, set `LC_ALL=en_US.UTF-8`.
