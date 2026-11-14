# Simulate survey data

At the end of this page you have simulated survey tables that the fitting functions accept, replicate files (one simulated dataset each, saved with its generating population) and a table of bias, RMSE and interval coverage for fits to those replicates. You need the package installed; every step uses package functions.

<h2 id="choose">1. Choose a simulator</h2>

```r
library(ALSCL)
quick <- simulate_example_data(
  years = 2000:2019, seed = 42, bin_breaks = seq(5, 51, 2),
  Linf = 60, vbk = 0.2, t0 = 1/60, M = 0.2, nage = 15,
  L50_sel = 15, L95_sel = 20, L50_mat = 35, L95_mat = 40,
  wgt_a = exp(-12), wgt_b = 3, mean_F = 0.3,
  cv_catch = 0.2, rec_sigma = 0.3,
  save_csv = TRUE, output_dir = "my_simulation")
str(quick, max.level = 1)
initialize_params(species = "?")
```

`simulate_example_data()` is the quick simulator for testing import, fitting and plotting: one call returns the survey index table `data.CatL`, the weight table `data.wgt` and the maturity table `data.mat` with the generating values in `true_params`, and `save_csv = TRUE` writes them as CSV files to `output_dir`. It applies one fishing mortality to all ages and fixes the length CV at 0.1. `years` must be consecutive calendar years; relabeling columns as quarters does not create quarterly dynamics.

The full operating model, for experiments against a known population, takes three calls: `initialize_params()` builds the parameter list from a preset, `sim_cal()` derives the biological arrays, and `sim_data()` runs the population through a burn-in (discarded first years) and writes one file per replicate, with Beverton-Holt recruitment and AR(1) process deviations in recruitment and fishing mortality. The table compares the two presets; the [reference of `initialize_params()`](../reference/initialize_params.html) lists every setting.

| Setting | flatfish | tuna |
|---|---|---|
| Operating model | Age-based | Joint age-length |
| `growth_step` | 1 year | 0.25 year |
| `nyear`, `burn_in` | 100, 80 years | 100, 95 years |
| Retained observations | 20 annual steps | 20 quarterly steps |
| `nage`, `rec.age` | 15 classes, 1 year | 20 classes, 0.25 year |
| `Linf`, `vbk` | 60, 0.2 per year | 152, 0.38 per year |
| `M`, `F_mean` | 0.2, 0.3 per annual step | 0.2, 0.2 per quarterly step |

`str()` shows the three tables and `true_params`; `initialize_params(species = "?")` lists the presets. Invalid inputs, such as `L95_sel` below `L50_sel`, stop the call before any file is written.

<h2 id="generate">2. Generate replicates and convert them to input tables</h2>

```r
pa <- initialize_params(species = "flatfish", first.year = 2000,
                        observation_error = "independent")
bio <- sim_cal(pa)
sm <- sim_data(bio, pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_examples/flatfish")
inputs <- simulation_to_tables(sm, pa)
tuna_pa <- initialize_params(species = "tuna", first.year = 2000)
tuna <- sim_data(sim_cal(tuna_pa), tuna_pa, iter_range = 4:5,
                 return_iter = 4, output_dir = "simulation_examples/tuna")
tuna_inputs <- simulation_to_tables(tuna, tuna_pa)
sm$years
tuna$years
str(inputs)
```

`iter_range` gives distinct nonnegative integer replicate IDs, which are also the seeds; ID 0 is accepted by `sim_data()`, `sim_model()`, `sim_acl()` and `sim_alscl()`; `sim_data()` saves each replicate as `sim_rep<id>` in `output_dir` with `save()`, read back with `load()`, and `return_iter` selects the one returned in memory. Each replicate sets its own seed and random-number generator and records them with the package version in `provenance`, so an ID gives the same data in any session and the random-number stream of your session is unchanged after the call. By default all processes of a replicate draw from one stream, so a change in one process, for example in the recruitment correlation `R_ar`, also changes the draws of the other processes. With `initialize_params(random_numbers = "by_process")`, recruitment, F, the initial numbers and the survey errors each have their own stream with a fixed number of draws, so scenarios that differ in one process share the random numbers of the others. The two settings give different data for the same ID, and each replicate records its setting in `provenance$random_numbers`. In `sm`, `SN_at_len` is a time by length matrix of survey numbers, `weight` and `mat` are length by time, `years` is the calendar of retained time steps and `nyear` their count, and `SSB`, `Rec`, `TB` and `N_at_age` are the generating truth.

`simulation_to_tables(sm, pa)` transposes `SN_at_len`, labels rows with the length midpoints and columns with `sm$years`, and returns the three tables as a list; the [simulate survey case](case-simulate-survey.html) adds the biology from `pa` and fits one replicate. In a copy of the repository, `run_simulation_examples(out = "simulation_examples")` from `scripts/simulation_workflow.R` runs this step for both presets and writes CSV tables with `truth.rds` beside them; the seed-4 replicate of both presets is in the repository with [download and reading instructions](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/cases/README.md).

If `simulation_to_tables()` stops because `len_mid` differs from the coordinates recorded in the replicate, pass the parameter list that generated the file. Keep the `sim_rep` files, the parameter list and the package version with an experiment.

`sim_data()` checks that the biological arrays and their recorded inputs match `pa` before drawing data or writing files. After changing growth, ages, the time step, length bins, weight, maturity, catchability or selectivity, run `bio <- sim_cal(pa)` again; do not edit the arrays by hand. Changes only to mortality, recruitment, error, duration or dates do not require rebuilding biology. To simulate with an optional model structure, set the same value that the fitting functions take as `structure`, for example `pa$structure <- "von_bertalanffy"`, before `sim_cal(pa)` ([Choose the fitting settings](fitting-controls.html#structure)). Matching older objects without recorded inputs still work. When fitting saved replicates, inconsistent survey-catchability metadata produces an error record: regenerate the simulation with matching inputs.

Length bins in the tails of the length-at-age distribution can have very small positive probabilities. The simulator carries those probabilities into the survey observations. For custom dome-shaped fishery selectivity, set `pa$sel_type` to `"dome"` and supply both logistic limbs. In an age-based simulation, selectivity at each age is the length-specific curve averaged over the distribution of length at that age. The length-based simulation uses the curve directly.

<h2 id="rates">3. Set rates, variation and time units</h2>

```r
mean(quick$true_params$F_trend)
pa$F_sd / sqrt(1 - pa$F_ar^2)
short_pa <- initialize_params(species = "flatfish", nyear = 5, burn_in = 2,
                              first.year = 2024)
short <- sim_data(sim_cal(short_pa), short_pa, iter_range = 4:5,
                  return_iter = 4, output_dir = "simulation_examples/short")
short$years
short$nyear
```

In the quick simulator `mean_F` is the arithmetic mean of the generated annual F. In the full simulator `F_mean` is the baseline of `F[t] = F_mean * exp(d[t])`, where `d[t]` is a zero-mean AR(1) process with coefficient `F_ar` and innovation SD `F_sd`, so the mean of the generated F differs from `F_mean`; compare the marginal SD `F_sd / sqrt(1 - F_ar^2)`, not `F_sd`, with a fitted log-F SD. `std_logR` and `R_ar` do the same for recruitment, `std_SN` is the SD of the log survey error, and `M` and `F_mean` are rates per time step, so the tuna values are per quarter.

`nyear` and `burn_in` are durations in years; `growth_step` must divide one year, `burn_in` must be an exact multiple of `growth_step` and smaller than `nyear`, and at least two time steps must be retained for fitting. `first.year` labels the first retained step, and `sm$nyear` counts retained steps. If the call stops because `burn_in` is not an exact multiple of `growth_step`, use whole years for annual steps and quarter years for quarterly steps.

<h2 id="fit">4. Fit the replicates and summarize</h2>

```r
data("YTF_example")
cfg <- YTF_example$fit_config$acl
cfg$parameters$log_std_log_F <- log(pa$F_sd / sqrt(1 - pa$F_ar^2))
fits <- sim_acl(iter_range = 4:5, sim_data_path = "simulation_examples/flatfish",
                output_dir = "simulation_examples/fits_acl",
                parameters = cfg$parameters, map = cfg$map,
                nstarts = 2, ncores = 2)
truth <- setNames(lapply(4:5, function(i) {
  e <- new.env(parent = emptyenv())
  load(file.path("simulation_examples/flatfish", paste0("sim_rep", i)), envir = e)
  s <- e$sim.data
  list(year = s$years, SSB = as.numeric(s$SSB), Rec = as.numeric(s$Rec))
}), paste0("result_rep_", 4:5))
performance <- summarize_simulations(fits, truth, quantities = c("SSB", "Rec"))
performance$replicates
performance$summary
performance$summary_converged
performance$failures
```

`sim_acl()` reads each `sim_rep<id>` in `sim_data_path`, builds the tables and the biology from the file and fits ACL with the starting values and `map` you pass and with the natural mortality rate recorded in the file; `sim_alscl()` does the same with ALSCL parameter names. Files that earlier versions wrote under names such as `sim_rep1e+05` are read as well. A supplied `M` must equal the recorded rate. To study a misspecified natural mortality, pass `M` with `allow_M_mismatch = TRUE`. `initialize_params()`, `sim_data()`, `simulate_example_data()` and `sim_model()` with its two wrappers use a single natural mortality rate. A matrix by age and time step or a vector by length stops them with an error that says so; these forms are accepted by `run_acl()` and `run_alscl()` only.

This example uses the flatfish growth settings in `YTF_example` and fixes the marginal SD of log F at 0.3023716, calculated from `pa`. The configuration stored in `YTF_example` holds the same value, because the bundled data were generated with this preset; the line that sets `log_std_log_F` keeps the fitted SD equal to that of the operating model when you change `F_sd` or `F_ar` in `pa`. The operating model generates F from one shared time series and selectivity. The ACL fit uses a separable age-by-time F process. Both models initialize numbers at age recursively with independent increments on the log scale. To change the fitting assumptions, see [Choose the fitting settings](fitting-controls.html).

Each replicate is fitted on one worker with its `nstarts` starts run one after the other, and `ncores` sets how many replicates run at the same time. Every result, including a failure with `converge = "FAILED"` and an `error` message, is returned and saved as `result_rep_<id>` in `output_dir`. The results do not hold the TMB object `obj`; call `refit_model()` on a result when you need one.

`summarize_simulations()` needs the truth as a list with the same names as the fits, each with `year` and one vector per quantity, read here from the replicate files so that the time coordinates match. `performance$replicates` gives the numerical checks and error of each replicate; `performance$summary` gives, per quantity, failure rate, bias, relative bias, RMSE and interval coverage with their counts. Bias and RMSE use fits that passed the numerical checks and coverage also needs finite standard errors, so report `failure_rate` with the statistics. `performance$summary_converged` repeats the statistics for all converged fits, whether or not they passed the numerical checks, and `performance$failures` counts the failed replicates by reason. Compare the two summaries to see whether the fits excluded by the numerical checks change bias, RMSE or coverage. If the call stops with "identical unique replicate names" or "time coordinates differ", the truth was not read from the same files as the fits.

Both the time coordinates and each quantity must be one-dimensional real numeric vectors. Matrices and arrays are rejected even when their total length matches the number of periods. Aggregate age- or length-specific quantities to the intended time series before calling; do not flatten grouped values into time.

<h2 id="fitted">5. Simulate from a fitted model</h2>

```r
fit <- run_acl(YTF_example, silent = TRUE)
simulated <- simulate_fit(fit, nsim = 3, seed = 42, process = "resample")
names(simulated$simulations[[1]])
simulated$simulations[[1]]$truth$SSB
```

`simulate_fit()` generates datasets from a fitted ACL or ALSCL model: fitted-model simulation. `process = "conditional"` keeps the fitted population and redraws only the observation error; `process = "resample"` also draws new recruitment, fishing mortality and initial-abundance process deviations at the fitted scalar parameter values. Each element of `simulated$simulations` has `x`, an input bundle for `run_acl(x)`, `observations` and `truth`, so `summarize_simulations()` applies to the refits with `lapply(simulated$simulations, function(s) s$truth)` as the truth. A fit that failed the numerical checks is rejected unless `allow_failed_fit = TRUE`; the [model validation case](case-model-validation.html) refits the replicates and continues with hindcast validation.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Plot one replicate, fit both models and compare with the truth | [How do I simulate survey data?](case-simulate-survey.html) |
| Refit fitted-model simulations and predict withheld years | [Model validation](case-model-validation.html) |
| Run more replicates in less time | [Speed settings](speed.html) |
| Keep seeds, settings and versions for a repeatable experiment | [Reproducibility](reproducibility.html) |
| Compare annual and quarterly settings | [Annual and quarterly time steps](case-studies.html) |
| Fit your own tables | [Prepare your survey data](data-preparation.html) |
