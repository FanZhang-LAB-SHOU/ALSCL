# Simulation

Load the package before running these examples. Calls to `source("scripts/…")` below use repository scripts and must run from the repository root; the public batch-fitting functions work from an installed package.

```r
library(ALSCL)
```

## 1. Choose a simulator

```r
# Simple annual simulation with CSV export
quick <- simulate_example_data(
  years = 2000:2019, seed = 42, bin_breaks = seq(5, 51, 2),
  Linf = 60, vbk = 0.2, t0 = 1/60, M = 0.2, nage = 15,
  L50_sel = 15, L95_sel = 20, L50_mat = 35, L95_mat = 40,
  wgt_a = exp(-12), wgt_b = 3, mean_F = 0.3,
  cv_catch = 0.2, rec_sigma = 0.3,
  save_csv = TRUE, output_dir = "my_simulation")
str(quick)
```


Use consecutive annual `years`. Changing labels does not create quarterly dynamics. `cv_catch` controls survey observation CV and `rec_sigma` log recruitment variation. This simplified simulator uses common F, independent recruitment perturbations and fixed length CV 0.1; it differs from both the full operating model and the bundled YTF generation recipe.

### Annual and quarterly operating models

The seed-4 data, input CSV files and complete truth objects are included in the repository. See [download and reading instructions](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/cases/README.md).

```r
# Parameters → biological arrays → simulation
pa <- initialize_params(species = "flatfish", first.year = 2000,
                        observation_error = "independent")
bio <- sim_cal(pa)
sm <- sim_data(bio, pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_examples/flatfish")
# Length-based quarterly case
tuna_pa <- initialize_params(species = "tuna", first.year = 2000)
tuna <- sim_data(sim_cal(tuna_pa), tuna_pa, iter_range = 4:5,
                 return_iter = 4, output_dir = "simulation_examples/tuna")
# Convert simulated matrices to input tables
source("scripts/simulation_workflow.R", encoding = "UTF-8")
flatfish_inputs <- simulation_to_tables(sm, pa)
tuna_inputs <- simulation_to_tables(tuna, tuna_pa)
```

|Setting| flatfish / YTF-style | tuna |
|---|---|---|
|Operating model|Age-based|Joint age-length|
| `growth_step` | 1 year | 0.25 year |
| `nyear`, `burn_in` | 100, 80 years | 100, 95 years |
| Retained observations | 20 annual steps | 20 quarterly steps |
| `nage`, `rec.age` | 15 classes, 1 year | 20 classes, 0.25 year |
| `Linf`, `vbk` | 60, 0.2 per year | 152, 0.38 per year |
| `M`, `F_mean` | 0.2, 0.3 per annual step | 0.2, 0.2 per quarterly step |


These are the two package simulation presets, not recovered empirical datasets from the paper. Duration arguments are in **years**, whereas returned `sm$nyear` counts retained **steps**. Transpose `SN_at_len` (time × length); weight and maturity are already length × time.


`iter_range` provides replicate IDs and seeds; `return_iter` selects the in-memory replicate. `sim_rep*` files use `save()/load()`, not RDS. Independent error varies across cells, while shared-time error applies the same perturbation to all length bins in a period.

```r
# Generate both cases, CSV and truth files
cases <- run_simulation_examples(out = "simulation_examples", fit_batch = FALSE)
# Add two ACL fits and retain failures
# run_simulation_examples(out = "simulation_examples", fit_batch = TRUE)
e <- new.env()
load("simulation_examples/flatfish/sim_rep4", envir = e)
str(e$sim.data)
```


## 2. Specify rates, variation and time units

`mean_F` in `simulate_example_data()` is the arithmetic mean of the generated annual F trajectory. In the full simulator, `F_mean` instead sets the process baseline in `F[t] = F_mean * exp(d[t])`; random variation means it is not generally the realized arithmetic mean. `F_sd` is the innovation SD of the log-F AR(1) process. For stationary correlation `F_ar`, its marginal SD is `F_sd / sqrt(1 - F_ar^2)`. This differs from the marginal log-F SD used by the fitted models. Survey catchability is set by `q_surv_L50` and `q_surv_L95`; these are survey inputs, not fishing selectivity estimates.

For the full simulator, `nyear` and `burn_in` are durations in years and must each contain a whole number of `growth_step` intervals. Thus a half-year burn-in is valid with quarterly steps, but not annual steps. Returned `sm$nyear` counts retained steps. `first.year` labels the first retained observation, and `sm$years` records the complete retained calendar. `simulation_to_tables()` and the batch-fitting functions preserve this calendar; old files lacking year metadata still have a documented 2000-based fallback. A single retained period stays a matrix, although fitting requires at least two periods.

```r
quick <- simulate_example_data(years = 2000:2019, mean_F = 0.3, seed = 42)
stopifnot(isTRUE(all.equal(mean(quick$true_params$F_trend), 0.3)))
zero_F <- simulate_example_data(years = 2000:2019, mean_F = 0, seed = 42)
stopifnot(all(zero_F$true_params$F_trend == 0))
pa <- initialize_params(species = "flatfish", nyear = 5, burn_in = 2,
                        first.year = 2024)
sm <- sim_data(sim_cal(pa), pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_224")
stopifnot(identical(as.numeric(sm$years), as.numeric(2024:2026)))
source("scripts/simulation_workflow.R", encoding = "UTF-8")
inputs <- simulation_to_tables(sm, pa)
```

## 3. Check biological inputs and zeros

`mat_func()` uses a stable logistic calculation: a steep increasing curve approaches one without overflowing. `L50` and `L95` must be distinct finite scalars; a descending curve (`L95 < L50`) remains available for dome selectivity. Length values and derived biological arrays must be finite. Simulated natural and fishing mortality must be nonnegative. With both `M = 0` and `F_mean = 0`, fishery catch numbers and biomass are zero; abundance and recruitment still follow the chosen operating model.

```r
stopifnot(all(is.finite(mat_func(20, 20.1, c(20, 30, 50)))))
pa0 <- initialize_params(species = "flatfish", nyear = 4, burn_in = 2,
                         M = 0, F_mean = 0)
sm0 <- sim_data(sim_cal(pa0), pa0, iter_range = 4,
                output_dir = file.path(tempdir(), "alscl-zero-mortality"))
stopifnot(all(sm0$CN == 0), all(sm0$CB == 0))
```

### Length bins and process parameters

The quick simulator integrates the first and last length bins to negative and positive infinity, matching the fitted models. Finite `bin_breaks` still determine labels and midpoints; they do not truncate probability. Use nonnegative M, F and noise scales, positive growth parameters and a nonnegative weight coefficient, and increasing selectivity/maturity endpoints. Invalid parameters or nonfinite generated values stop before CSV files are created. The full simulator also requires normalized age-length keys and growth transitions.

The full simulator validates `init_Z`, process and observation standard deviations, and the F process baseline as finite nonnegative values. `F_ar` and `R_ar` must lie strictly between -1 and 1; negative stationary correlations remain valid. Beverton–Holt alpha and initial recruitment may be zero, while beta must be positive. Invalid process inputs stop before random draws or file creation, preserving existing simulations and the caller's random-number state.

### Retain the observation scale and coordinates

Full simulations retain zero and very small positive survey observations. Survey biomass equals survey abundance times weight, including extinction scenarios. For fitting, zero observations are missing with `zero_action = "missing"` and rejected with `"error"`; an entirely zero survey contains no positive observations and cannot be fitted by the current lognormal model.

Simulation length midpoints must lie within their corresponding bins, using the same containment rules as fitting. The first and last bins absorb the tails. Invalid bin geometry is rejected during parameter preparation and rechecked before biological calculations or simulation, including manually modified inputs, before random draws or output files.

## 4. Fit replicates and summarize performance

`sim_model(model = "acl")` and `sim_model(model = "alscl")` fit replicate files with the selected model. `sim_acl()` and `sim_alscl()` provide model-specific interfaces; the original `sim_acl()` calls remain valid. A custom loop around `run_acl()` or `run_alscl()` is optional. Generator and estimator parameter names differ. Use model-specific starts and maps, retain every replicate and its generating truth, and report bias, RMSE, interval coverage and failure rates. See the [complete batch example](assessment-workflows.html) for matched inputs and summary denominators.

`sim_model()`, `sim_acl()` and `sim_alscl()` resolve path and parameter variables before sending tasks to socket workers, so ordinary console/script calls work with multiple cores. Retain failed replicates and inspect each fit's diagnostics; successful worker execution alone does not establish a usable assessment.

`sim_model()`, `sim_acl()` and `sim_alscl()` save the status of every replicate, including failures, to `result_rep_<iter>`. Reusing an output directory replaces an earlier success with the current failure record; inspect `converge` and `error` before summarizing results. Output write failures are reported and must not be treated as saved results. `simulation_to_tables(sm, pa)` uses the simulation length coordinates and rejects conflicting parameter coordinates instead of relabeling observations; legacy simulations without coordinates can use matching parameter metadata.

## Reproducing saved experiments

To reproduce an older experiment, keep its saved inputs, generating truth, seed and package revision. The correction to quick-simulator `mean_F` in 2.2.4, tail-bin integration changes, and removal of the full simulator's `1e-6` survey floor in 2.2.9 can change regenerated observations with the same seed. Saved datasets are not rewritten. See the [changelog](../news/index.html) for version history.


## Simulate directly from an assessment fit

`simulate_fit(fit, process = "conditional")` varies observations at the fitted states; `process = "resample"` redraws the fitted model’s recruitment, F and initial-state deviations. Both keep scalar parameters fixed and retain a directly reusable input bundle and truth. These differ from the operating-model simulations above. See the [complete fitted-model simulation and validation case](case-model-validation.html). Existing simulation batches also accept `nstarts`, run sequentially inside each replicate worker; `ncores` controls the number of simultaneous replicates.
