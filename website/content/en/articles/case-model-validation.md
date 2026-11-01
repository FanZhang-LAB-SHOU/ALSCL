# Can the fitted model reproduce observations and predict withheld periods?

Use this case to generate survey data from a fitted model, check estimates against known simulated values, or test predictions against observations withheld from fitting.

**Before you start:** these functions require ALSCL 2.3.0 or later. Install that version, or run `pkgload::load_all(".")` from the downloaded repository root.

| What would you like to check? | Where to start |
|---|---|
| Repeated observations at the same fitted population states | [Step 2: conditional simulation](#section-2) |
| New population trajectories and how well they can be estimated | [Steps 2–3: resample processes and refit](#section-2) |
| Predictions of later survey observations | [Step 4: leave out future periods](#section-4) |

Start with step 1 to load `x`. For simulation, also fit `b` and continue through steps 2–3. For prediction checks only, go from `x` directly to step 4. Step 5 explains the prediction scores and saved records.

<h2 id="section-1">1. Prepare the example and check its fit</h2>

The case uses the **synthetic** `YTF_example` dataset. Load it once as the input bundle `x`:

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
```

For simulation, fit the source model as `b` below. If you already fitted this same example, reuse that result and inspect its diagnostics. For prediction checks only, skip this fit and go to [step 4](#section-4), which creates its own training fits.

```r
b <- run_alscl(x, silent = TRUE)
b$diagnostics
stopifnot(b$diagnostics$numerical_ok)
```

Continue when `numerical_ok` is `TRUE`. If it is `FALSE`, investigate the reported issues before generating simulations; see [fitting diagnostics](diagnostics.html). This screen checks the numerical fit. Residuals and sensitivity to assumptions still need assessment.

The teaching example fixes several biological parameters through `map`. For your own assessment, choose supported stock-specific biology and inspect which parameters are fixed or estimated using [data and parameter checks](assessment-workflows.html). When fixing `mean_log_R` for a simulation study, supply its numeric value explicitly in `parameters` so that a data-derived value is not recalculated from each simulated dataset.

<h2 id="section-2">2. Generate survey observations</h2>

<h3 id="conditional-draws">Keep the fitted population states</h3>

`process = "conditional"` changes observation error while retaining the fitted population. This is the shortest way to inspect repeated surveys under the same fitted states.

```r
conditional <- simulate_fit(b, nsim = 3, seed = 20261101,
  process = "conditional")
conditional$metadata
conditional$simulations[[1]]$observations[1:3, 1:3]
```

<h3 id="process-draws">Generate new population trajectories</h3>

`process = "resample"` redraws recruitment, fishing-mortality and initial-population deviations at the fitted scalar parameter values. Use these replicates for the refitting exercise in step 3.

```r
resampled <- simulate_fit(b, nsim = 3, seed = 20261101,
  process = "resample")
resampled$simulations[[1]]$truth$SSB
simulated_x <- resampled$simulations[[1]]$x
```

Each element of `$simulations` contains:

| Field | What it contains |
|---|---|
| `$observations` | Simulated survey values, with length in rows and time in columns |
| `$x` | An input bundle for the corresponding `run_acl()` or `run_alscl()` function |
| `$truth` | Generating population quantities, scalar parameters and expected survey indices |

Original missing and zero cells are preserved by default. Set `preserve_missing = FALSE` for a complete positive survey. A supplied seed reproduces the draws and restores the caller's random-number state afterward.

![ALSCL observations simulated conditionally or with resampled processes](../assets/manual/figures/workflows/fitted-simulation.png)

The figure shows three generated survey series in each mode for selected length groups. The dashed reference is the original fit's log observation median. Conditional simulations vary around the same fitted states; resampling also changes the population trajectory. The curves are individual draws, not confidence bands.

<h3 id="simulation-assumptions">Understand what is being simulated</h3>

Both modes use the fitted lognormal observation model: log observations have mean `Elog_index` and the fitted observation standard deviation. Thus `exp(Elog_index)` is the observation median. Scalar parameters remain fixed, so neither mode includes parameter-estimation uncertainty.

In resample mode, recruitment follows a stationary AR(1) process. F follows a separable group/time AR(1) field, or a single time process for `F_structure = "year"`. Process SDs are marginal SDs; the temporal innovation SD is the marginal SD multiplied by `sqrt(1 - phi^2)`. Initial-abundance deviations are independent normals. The C++ population model uses these draws with the plus group and ALSCL growth transitions.

Fixed or tied random-effect maps are rejected in resample mode; conditional simulation remains available. A known failed source fit is rejected by default. `allow_failed_fit = TRUE` permits exploratory use with a warning. For a separate operating model with its own recruitment assumptions, use [the operating-model simulation workflow](simulation.html).

<h2 id="section-3">3. Refit the replicates and compare with truth</h2>

This step fits the three resampled datasets with two starts each. It is more time-consuming than drawing observations. To examine prediction performance only, go directly to [step 4](#section-4).

The same direct-input syntax applies to each replicate: `run_alscl(s$x)` for this ALSCL example, or `run_acl(s$x)` for simulations from an ACL fit. The loop keeps error records so that failed replicates remain in the summary.

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

Read `$replicates` first to check fitting status. Then read `$summary` for bias, RMSE, coverage and their denominators. Three replicates demonstrate the interface; a study of bias or interval coverage needs adequate repetitions and explicit failed-fit and usable-interval counts. A parametric bootstrap also needs a stated resampling design, refitting protocol and interval construction; `simulate_fit()` supplies the generating step.

**If your simulations are already on disk:** `sim_model(..., nstarts = 3, ncores = 2)` uses three starts per replicate and at most two replicate workers. Starts and standard errors run sequentially inside each worker. `train_times` controls optimization passes per start; each fit retains `start_diagnostics`. This is a separate batch workflow, described in [simulation and batch experiments](simulation.html).

<h2 id="section-4">4. Predict periods withheld from fitting</h2>

`hindcast_model()` takes `x` and creates its own training fits. It does not reuse `b` or the simulated datasets. Here, each model is fitted through 2017 to predict 2018, and through 2018 to predict 2019.

| Setting | Meaning in this annual example |
|---|---|
| `horizon = 1` | Predict one model period ahead |
| `nfolds = 2` | Use the last two eligible training endpoints |
| `min_train = 8` | Require at least eight training periods |
| `ncores = 2` | Run at most two training folds in parallel |

```r
acl_validation <- hindcast_model(x, model = "acl", horizon = 1,
  nfolds = 2, min_train = 8, nstarts = 1, ncores = 2)
alscl_validation <- hindcast_model(x, model = "alscl", horizon = 1,
  nfolds = 2, min_train = 8, nstarts = 1, ncores = 2)
acl_validation$diagnostics
alscl_validation$diagnostics
```

Check every fold's `numerical_ok`, `prediction_ok`, warnings and errors. Failed or numerically unverified training fits remain in `$diagnostics` and contribute no predictions or scores. Once these rows are understood, inspect the scores and individual prediction cells:

```r
acl_validation$scores
alscl_validation$scores
head(alscl_validation$predictions)
```

![Withheld survey indices and model and persistence predictions](../assets/manual/figures/workflows/hindcast-predictions.png)

The figure compares withheld log survey indices with the model prediction and a persistence baseline: the latest positive training observation in the same length bin, held constant. Step 5 compares their errors on the same eligible observation cells.

<h3 id="forecast-design">Adapt the validation design</h3>

`horizon` and `min_train` count model periods; one step is one quarter for quarterly inputs. The last `nfolds` eligible origins are used. Each fold truncates all three input tables and supported time maps, then uses the supplied fitting configuration. Starting estimates never come from a fit to the complete series. Choose biological assumptions, fixed values and manual starts without tuning to withheld data; compare models using the same origins, horizons and observation cells.

<h3 id="forecast-assumptions">Understand the prediction rule</h3>

Forecast log recruitment and log F deviations follow their AR(1) conditional-mean paths from the training endpoint. Population equations propagate abundance, and supplied catchability converts it to survey indices. Training-end weights and maturity are carried forward; future observed biology is not read into the prediction.

These are plug-in point predictions along conditional log-process paths. They include no future random shocks or parameter draws and provide no predictive distribution or intervals. Nonidentity maps fixing or tying time-varying recruitment/F deviations are rejected because their future constraints are unspecified.

<h2 id="section-5">5. Interpret scores and save the analysis</h2>

<h3 id="prediction-scores">Read the scores and their sample sizes together</h3>

Scores use natural-log survey indices. Zero and missing validation observations are excluded. Model and persistence errors use the same cells with both predictions available.

| Output | How to read it |
|---|---|
| `n_positive`, `n_prediction`, `n` | Positive held-out observations, those with model predictions, and cells scored for both model and persistence |
| `log_RMSE`, `log_MAE` | Prediction error on the log-index scale; smaller values mean smaller errors on those cells |
| `naive_log_RMSE`, `naive_log_MAE` | Corresponding persistence errors on the same cells |
| `log_MASE`, `naive_log_MASE`, `n_scaled` | Scaled absolute errors and the number of cells with a usable training scale |

For MASE, each absolute log error is divided by that length bin's mean absolute difference between consecutive positive training log observations. Missing periods are not compressed. A zero or unavailable scale excludes that cell from the scaled score; when no eligible cells remain, the score is `NA`. Check `n_scaled` before interpreting it.

In the executed example, both models scored the same 46 positive observations from 2018–2019. All four training fits passed the numerical screen, and both comparisons used the same persistence baseline.

| Prediction | Scored observations | Log RMSE | Log MAE | Log MASE |
|---|---:|---:|---:|---:|
| ACL | 46 | 0.0963 | 0.0802 | 0.4213 |
| ALSCL | 46 | 0.2583 | 0.1951 | 1.0655 |
| Persistence | 46 | 0.1722 | 0.1467 | 0.7356 |

Under this synthetic dataset, teaching maps and two-origin design, ACL improves on persistence and ALSCL does not. The difference deserves investigation even though both optimizations converged. Two validation periods do not establish a general model ranking. The three simulated-process refits also passed the numerical screen, but three replicates are insufficient to establish coverage.

<h3 id="save-record">Save a portable fit</h3>

If you completed the simulation steps, save the source fit `b` with the following block. The archive can be read in a new R session and used for simulation without a live TMB pointer:

```r
archive <- tempfile(fileext = ".rds")
save_assessment(b, archive)
saved <- read_assessment(archive)
saved$recipe$implementation
again <- simulate_fit(saved, nsim = 1, seed = 20261101,
  process = "conditional")
```

Replace the temporary path with a permanent filename for your analysis. Save the simulation objects and truth alongside the fit. To save the validation results from step 4, retain both models together:

```r
validation_file <- tempfile(fileext = ".rds")
saveRDS(list(acl = acl_validation, alscl = alscl_validation),
  validation_file)
```

Use a permanent path here too for your own analysis. Recipes retain available source revision, core/R source hashes and runtime metadata. A source HEAD alone does not establish a clean working tree; `refit_model()` warns about known implementation or dependency changes, while unknown older provenance remains unknown.

<h3 id="next-steps">Choose the next check</h3>

Use [residual diagnostics](diagnostics.html) to examine observation patterns, [retrospective analysis](retrospectives.html) to examine revisions to historical estimates, or [sensitivity scenarios](case-sensitivity-projection.html) to examine supplied assumptions. These answer different questions from held-out prediction.

To regenerate this case's figures and CSV results, run the following from the downloaded repository root. It performs the full fitting exercise again; the plotting helper checks every panel for gridlines before saving.

```r
pkgload::load_all(".")
source("scripts/model_validation.R")
run_model_validation_guide()
```
