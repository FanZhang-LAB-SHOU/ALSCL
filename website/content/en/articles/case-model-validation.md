# Can the fitted model reproduce observations and predict withheld time steps?

On this page you check a fitted model from two sides. Fitted-model simulation draws new survey data from the fit and refits them, to see whether the estimates recover the known values; hindcast validation fits on the earlier time steps and scores the predictions of the withheld later ones against the observations. You need the package installed ([Install ALSCL](getting-started.html)); the code uses the synthetic `YTF_example` and takes about fifteen minutes in total, because steps 3 and 4 refit the models several times. For hindcast validation alone, run step 1 and go to step 4. At the end you have simulated datasets with their truth, a table of bias, RMSE and interval coverage, the prediction scores of both models against a persistence baseline, and a saved fit.

<h2 id="section-1">1. Load the input bundle</h2>

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
```

`x` contains the three survey tables and the model settings. For hindcast validation alone, continue directly to [step 4](#section-4): it fits the training windows from `x` and requires no full-data fit. For simulation, continue to step 2.

<h2 id="section-2">2. Generate survey observations from the fit</h2>

<h3 id="source-fit">Fit the source model for simulation</h3>

```r
b <- run_alscl(x, silent = TRUE)
b$diagnostics
stopifnot(b$diagnostics$numerical_ok)
```

`b` is the ALSCL fit that the simulations start from. Its `numerical_ok` must be `TRUE`, because `simulate_fit()` rejects a fit that failed the numerical checks unless `allow_failed_fit = TRUE`; if it is `FALSE`, follow [Judge whether a fit can be used](diagnostics.html) before simulating. The teaching example fixes growth and several process parameters through `map`; with your own bundle choose supported biological settings ([Choose the fitting settings](fitting-controls.html)). Each simulated `x` preserves the source fit's effective fixed scalar values, including `mean_log_R` when its value was derived from the original data. To choose a particular fixed value yourself, provide it in `parameters` when fitting the source model.

<h3 id="conditional-draws">Keep the fitted population states</h3>

```r
conditional <- simulate_fit(b, nsim = 3, seed = 20261101,
  process = "conditional")
conditional$metadata
conditional$simulations[[1]]$observations[1:3, 1:3]
```

`process = "conditional"` keeps the fitted population and redraws only the observation error, the shortest way to see repeated surveys of the same states. `metadata` records the model, the process, the seed, the original observation mask, the status of the source fit and the assumption `parameter_uncertainty = "none"`.

<h3 id="process-draws">Generate new population trajectories</h3>

```r
resampled <- simulate_fit(b, nsim = 3, seed = 20261101,
  process = "resample")
resampled$simulations[[1]]$truth$SSB
simulated_x <- resampled$simulations[[1]]$x
```

`process = "resample"` also draws new process deviations of recruitment, fishing mortality and initial abundance at the fitted scalar parameter values: recruitment and F follow the fitted stationary AR(1) processes (one F series per time step under `F_structure = "year"`), the initial-abundance deviations are independent normals, and the C++ population model turns the draws into a new population. Both modes draw log observations around the fitted `Elog_index` with the fitted observation SD, so `exp(Elog_index)` is the median; scalar parameters, biology and survey catchability stay fixed, so neither mode carries parameter uncertainty. Each element of `$simulations` holds `observations` (length bins by time steps), `truth` (population quantities, scalar parameters and the deviations used) and `x`, an input bundle for `run_alscl()` that keeps the fitting configuration of `b` except `output`, `ncores` and `silent`, which you choose when fitting it. Missing and zero cells of the original survey stay as they are unless `preserve_missing = FALSE`; the seed makes the draws repeatable, and the caller's random-number state is restored afterwards. A `map` that fixes or ties the process deviations stops the resample mode, while conditional draws still work. For an operating model with its own recruitment assumptions, use [Simulate survey data](simulation.html).

![ALSCL observations simulated conditionally or with resampled processes](../assets/manual/figures/workflows/fitted-simulation.png)

The figure shows three draws per mode for three length bins; the dashed line is the fitted log median. Conditional draws scatter around the same fitted states, and resampled draws also move the trajectory. Each curve is one draw, an example of the generating distribution.

<h2 id="section-3">3. Refit the replicates and compare with the truth</h2>

```r
replicate_fits <- lapply(resampled$simulations, function(s) {
  tryCatch(run_alscl(s$x, nstarts = 2, ncores = 1, silent = TRUE),
    error = function(e) list(error = conditionMessage(e)))
})
truth <- lapply(resampled$simulations, function(s) s$truth)
performance <- summarize_simulations(replicate_fits, truth,
  quantities = c("SSB", "Rec"))
performance$replicates
performance$summary
```

Each refit is an ordinary fit of the simulated bundle, `run_alscl(s$x)` here and `run_acl(s$x)` for draws from an ACL fit, with two starts each; `tryCatch()` keeps the error message of a failed replicate so that it stays in the summary. `summarize_simulations()` matches the fits with the truth by replicate name and year and returns `replicates` (numerical checks, time and error of each fit) and `summary` (per quantity: failure rate, bias, relative bias, RMSE and interval coverage with their denominators); bias and RMSE use the fits that passed the checks, and coverage uses only intervals with a finite standard error ([Simulate survey data](simulation.html#fit) explains the denominators). In the recorded run all three refits passed, each taking about three minutes, with coverage 1.0 for spawning biomass and 0.95 for recruitment over 60 pairs ([simulation-performance.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/model-validation/simulation-performance.csv)). Three replicates show the mechanics; a study of bias or coverage needs enough replicates for the failure rate to mean something, and a parametric bootstrap also needs a stated refitting protocol and interval construction, for which `simulate_fit()` supplies only the generating step. For replicates already on disk, `sim_model()` fits them in batch ([Simulate survey data](simulation.html#fit)).

<h2 id="section-4">4. Predict time steps withheld from fitting</h2>

```r
acl_validation <- hindcast_model(x, model = "acl", horizon = 1,
  nfolds = 2, min_train = 8, nstarts = 1, ncores = 2)
alscl_validation <- hindcast_model(x, model = "alscl", horizon = 1,
  nfolds = 2, min_train = 8, nstarts = 1, ncores = 2)
acl_validation$diagnostics
alscl_validation$diagnostics
acl_validation$scores
alscl_validation$scores
head(alscl_validation$predictions)
```

`hindcast_model()` is the hindcast validation: it fits each model on the time steps up to a training origin and predicts the survey index of the next `horizon` steps, from the last `nfolds` eligible origins, every fit starting afresh from `x` with the stored configuration. Here each model is fitted through 2017 to predict 2018 and through 2018 to predict 2019.

| Setting | Meaning in this annual example |
|---|---|
| `horizon = 1` | Predict one time step ahead |
| `nfolds = 2` | Use the last two eligible training origins |
| `min_train = 8` | Require at least eight training time steps |
| `ncores = 2` | Run at most two training folds in parallel; the starts inside a fold run one after another |

`horizon` and `min_train` count time steps (quarters for quarterly data); each fold truncates the three tables and the time-varying maps, and a `map` that fixes or ties the process deviations over time stops the call. Read `$diagnostics` first: one row per fold with `origin`, the numerical checks, `prediction_ok`, warnings and errors; a fold that failed stays in the table and contributes no predictions or scores. `$predictions` lists every withheld cell with the observed, predicted and persistence log index and an inclusion flag.

![Withheld survey indices and model and persistence predictions](../assets/manual/figures/workflows/hindcast-predictions.png)

The figure compares the withheld log survey indices with the model prediction and the persistence baseline, the latest positive training observation of the same length bin held constant, for three length bins. The prediction rule: the process deviations of recruitment and F continue along their fitted AR(1) conditional means from the training end (the last deviation times phi to the power of the horizon), the population equations advance abundance, and the fitted survey catchability turns it into survey indices; the last training weights and maturity are repeated for the biomass calculation only. These are plug-in point predictions along the conditional process path, without future shocks, parameter draws or intervals. Choose fixed values and starting values without looking at the withheld data, and compare models on the same origins, horizons and cells.

<h2 id="section-5">5. Read the scores and save the analysis</h2>

<h3 id="prediction-scores">Read the scores and their sample sizes together</h3>

| Output | How to read it |
|---|---|
| `n_positive`, `n_prediction`, `n` | Positive withheld observations, those with a model prediction, and cells scored for both model and persistence |
| `log_RMSE`, `log_MAE` | Prediction error on the log-index scale; smaller is better on those cells |
| `naive_log_RMSE`, `naive_log_MAE` | The persistence errors on the same cells |
| `log_MASE`, `naive_log_MASE`, `n_scaled` | Scaled absolute errors and the number of cells with a usable training scale |

Scores use natural-log survey indices; zero and missing withheld observations are excluded, and model and persistence errors use the same cells. For MASE each absolute log error is divided by the length bin's mean absolute change between consecutive positive training observations; a bin without such a pair gets no scaled score, so check `n_scaled` before reading it. In the recorded run both models scored the same 46 positive observations of 2018-2019 and all four training fits passed the checks ([hindcast-scores.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/model-validation/hindcast-scores.csv)):

| Prediction | Scored observations | Log RMSE | Log MAE | Log MASE |
|---|---:|---:|---:|---:|
| ACL | 46 | 0.096 | 0.080 | 0.42 |
| ALSCL | 46 | 0.26 | 0.20 | 1.07 |
| Persistence | 46 | 0.17 | 0.15 | 0.74 |

On this synthetic dataset, with the teaching maps and two origins, ACL predicts better than persistence and ALSCL worse, although both optimizations converged: a difference worth investigating, while two validation time steps give no general ranking of the models.

<h3 id="save-record">Save the validation results</h3>

```r
validation_file <- tempfile(fileext = ".rds")
saveRDS(list(acl = acl_validation, alscl = alscl_validation),
  validation_file)
```

The validation results are plain lists, so `saveRDS()` keeps both models together. Replace the temporary path with a permanent file. This completes the hindcast-only route.

<h3 id="simulation-archive">Save the source fit after simulation</h3>

Run this block if you fitted `b` in step 2. If you only ran hindcast validation, continue to [What next](#next).

```r
archive <- tempfile(fileext = ".rds")
save_assessment(b, archive)
saved <- read_assessment(archive)
saved$recipe$implementation
again <- simulate_fit(saved, nsim = 1, seed = 20261101,
  process = "conditional")
```

`save_assessment()` writes the saved fit without the live TMB object, and `simulate_fit()` accepts what `read_assessment()` returns, so a new session can simulate without refitting; the same seed gives the same draws. `saved$recipe$implementation` records the package versions, the source revision and the hashes of the model source, which `refit_model()` compares with the current installation, warning on a difference. Keep the simulation objects and truth beside this fit in permanent files.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Examine residual patterns of the source fit | [Judge whether a fit can be used](diagnostics.html) |
| See how the estimates change when recent time steps are removed | [Do estimates change when recent data are removed?](case-retrospective-bias.html) |
| Test the sensitivity to the fixed values | [How sensitive is the assessment, and what happens under future F?](case-sensitivity-projection.html) |
| Fit many simulated replicates in batch | [Simulate survey data](simulation.html#fit) |
| Regenerate the figures and tables of this page | From the repository root: `pkgload::load_all("."); source("scripts/model_validation.R"); run_model_validation_guide()` |
