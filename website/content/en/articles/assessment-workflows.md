# Assessment workflows

## Start with a complete worked assessment

This guide covers six connected tasks: preparing and checking inputs, extracting and saving results, checking residuals, fitting sensitivity scenarios and parameter profiles, projecting explicitly defined future scenarios, and summarizing simulation performance. These functions are available from the latest `main` source on GitHub; they are not included in the earlier 2.2.9 release tag. Install the latest source before running the examples.

The examples below start from the **synthetic** `YTF_example`. Its model-specific maps deliberately condition on several biological values to make a reproducible teaching example. Those maps are not a recommendation to fix the same parameters in your own stock assessment. For real observations, use supported stock-specific biology, inspect the effective map, and investigate weakly identified parameters rather than fixing them merely to obtain a successful optimizer code.

Run the blocks in order. Model fitting requires a working TMB compiler. All plots retain the package's default absence of gridlines.

```r
library(ALSCL)
library(ggplot2)
data("YTF_example")
x <- YTF_example
acl_theme_set(palette = "npg", base_theme = "theme_bw")

check_alscl_data(x, "acl")$summary
check_alscl_data(x, "alscl")$summary
a <- run_acl(x, silent = TRUE)
b <- run_alscl(x, silent = TRUE)
summary(a)
summary(b)
```

## 1. Prepare your own tables and inspect what will be estimated

The three tables have length-bin labels in the first column and numeric time headers thereafter. `data.CatL` contains survey numbers or indices, `data.wgt` mean individual weights, and `data.mat` mature proportions. Their bins, periods and order must agree. Missing survey periods remain explicit columns of `NA`; weights and maturity must be supplied for every period. Zeros are retained on import, then excluded by `zero_action = "missing"` or rejected by `"error"`.

This executable CSV round-trip demonstrates the new public readers. It uses YTF biology only because the tables are YTF data. **No `fit_config` is copied into `survey_x`**, so the ordinary fitting defaults apply: ACL fixes its four documented default scalars, ALSCL fixes its two; the remaining scalar parameters are estimated. For your own files, replace both the input tables and `fit_args` with your stock-specific settings. The package does not estimate M, catchability, weights, maturity, recruitment age or bin definitions automatically.

```r
folder <- tempfile("survey-csv-")
dir.create(folder)
for (nm in c("data.CatL", "data.wgt", "data.mat")) {
  write.csv(x[[nm]], file.path(folder, paste0(nm, ".csv")), row.names = FALSE)
}
tables <- read_survey_csv(folder)
survey_x <- prepare_alscl_data(tables, fit_args = x$fit_args)
input_check <- check_alscl_data(survey_x, "acl")
input_check$valid
input_check$errors
input_check$warnings
input_check$summary

parameter_plan <- inspect_parameters(survey_x, "acl")
parameter_plan[, c("parameter", "status", "map_source", "start",
                    "natural_start", "lower", "upper", "n_free")]
# For Excel, use read_survey_excel("survey.xlsx") instead.
# Required sheets: data.CatL, data.wgt, data.mat; optional dependency: readxl.
```

## Read the parameter plan before changing map

`check_alscl_data()` and `inspect_parameters()` share the fitting preparation and do not compile or optimize. They include data-derived starts, the recruitment-age constraint on t0, bounds, random-effect dimensions and the shared-F restriction. A valid input check establishes consistency, not identifiability or convergence.

In the table, `kind = "fixed_effect"` means an outer-model scalar, not that its value is fixed. `status` distinguishes free, fixed, tied, mixed and inactive entries; `map_source` distinguishes default rules, explicit settings and `F_structure`. `n_free` counts independent mapped values. A shared-F model has one random F value per model step, and its unused group correlation is inactive.

Starting values are not fixed values. A whole `map = NULL` restores defaults; a named NULL releases one default fix. Use single-bracket assignment to retain that NULL. Releasing a variance or correlation is a scientific choice requiring sufficient information; the following code only inspects that choice.

```r
released_x <- survey_x
released_x$fit_args$map <- list(log_std_log_F = NULL)
inspect_parameters(released_x, "acl")
shared_x <- survey_x
shared_x$fit_args$F_structure <- "year"
inspect_parameters(shared_x, "alscl")
# After reviewing inputs and assumptions:
# own_acl <- run_acl(survey_x)
# own_alscl <- run_alscl(survey_x)
```

## 2. Extract results and keep a portable assessment record

`summary()` reports numerical status alongside parameter estimates. `extract_parameters()` gives natural-scale estimates by default, with internal-scale names retained so each transformation is explicit. Fixed values have `NA` uncertainty. Exponentiating `mean_log_F` or `mean_log_R` gives the process baseline, not an arithmetic average over years.

`conf_level` is a nominal confidence level (default 0.95). The reported Wald intervals are pointwise and conditional on the fitted model and fixed inputs. It is not a probability assigned to a fixed parameter, and the simulation `coverage` statistic measures the observed fraction of usable intervals containing their generating truth.

`extract_estimates()` returns long tables with actual time, age or length coordinates. F retains native age groups for ACL and length groups for ALSCL; it is neither silently averaged nor annualized. Missing uncertainty remains `NA`; a finite standard error alone does not establish that a failed fit is suitable for inference.

A portable archive stores inputs, maps, bounds, reports, versions and recorded fitting settings, and removes the session-specific TMB pointer. Summaries, extraction and report-based plots work after reading. `refit_model()` reruns the saved recipe when a live model or a changed assumption is needed; it is not a claim of identical results across software versions.

```r
parameter_estimates <- extract_parameters(b)
parameter_estimates
estimates <- extract_estimates(b, quantities = c("SSB", "Rec", "F"))
head(estimates)

archive <- tempfile(fileext = ".rds")
save_assessment(b, archive)
saved <- read_assessment(archive)
summary(saved)
plot_SSB(saved)
# Refit when a live objective is needed:
# b_again <- refit_model(saved, silent = TRUE)
```

## 3. Diagnose observation residuals on the model time grid

Standardized residuals are `(log(observation) - fitted_log_index) / fitted_observation_SD`. The table retains original observations and marks excluded zero/missing cells, whose residuals are `NA`. The heatmap locates systematic length/time patterns; the lag table uses actual model-step separations and does not compress missing periods. Correlations need at least three nonconstant paired observations. The QQ plot compares pooled standardized residuals with standard-normal quantiles.

These residuals condition on fitted latent effects. Standardization does not make them independent or turn the plots into calibrated goodness-of-fit tests. Interpret numerical status, residual patterns, biological assumptions and sensitivity together. All three plots are grid-free.

In the regenerated YTF figures, the QQ plot has a heavier positive tail and the heatmap shows positive residuals in the largest length group during later periods. These patterns warrant investigation even though the fitted models pass the numerical screen; successful optimization does not establish adequate observation structure.

```r
checks <- check_fit(b, max_lag = 4)
head(residuals(b, type = "standardized"))
checks$lag_correlations
checks$plots$heatmap
checks$plots$lag
checks$plots$qq
```

![Conditional standardized residuals by length and period](../assets/manual/figures/workflows/residual-heatmap.png)

![Actual-time lag correlations with available pair counts](../assets/manual/figures/workflows/residual-lag.png)

![Pooled conditional residual QQ plot](../assets/manual/figures/workflows/residual-qq.png)

## 4. Separate sensitivity scenarios from parameter profiles

`fit_scenarios()` keeps the same three observation tables and applies explicitly named setting changes. Here ACL is used to keep the example short. Set `model = "alscl"` to use the matching ALSCL configuration; parameter and map names must belong to that model. M = 0.15 is an illustrative perturbation around the YTF value, not a biological recommendation.

The three ACL configurations use the same survey tables, growth inputs, supplied starting values and maps, except for the stated change below. In `YTF_example`, M = 0.20 per annual step and the default F structure is `"group_year"`.

| Scenario ID | M per model step | F structure | Change from the reference |
|---|---:|---|---|
| `reference` | 0.20 | `group_year`: age × time | None |
| `low_M` | 0.15 | `group_year`: age × time | Supplied natural mortality |
| `shared_F` | 0.20 | `year`: shared across ages within each step | F structure; unused age correlation becomes inactive |

For quarterly data, `"year"` still means one F per model step (one per quarter), not one per calendar year. The two future ALSCL projections separately compare F = 0.10 and F = 0.25 per step with identical recruitment, weights, maturity and M.

Inspect every row of `status`, including warnings and failed fits, before comparing trajectories. There is no automatic ranking. `F_summary = "mean"` requests an unweighted group mean; `"apical"` requests the maximum. These meanings differ and neither annualizes subannual F. `ncores` parallelizes independent scenarios; inner fits and standard errors use one worker while preserving the chosen `nstarts`. List-valued overrides replace entire lists, including map; they are not deep merges.

```r
scenarios <- fit_scenarios(x, list(
  reference = list(),
  low_M = list(M = 0.15),
  shared_F = list(F_structure = "year")
), model = "acl", ncores = 1, nstarts = 1,
   F_summary = "mean", silent = TRUE)
scenarios$status
head(scenarios$estimates)

scenario_ssb <- subset(scenarios$estimates, quantity == "SSB")
ggplot(scenario_ssb, aes(year, estimate, color = scenario)) +
  geom_line() + labs(x = "Year", y = "SSB") +
  theme_bw() + theme(panel.grid = element_blank())
```

![ACL sensitivity to the supplied M and shared-F structure](../assets/manual/figures/workflows/scenario-SSB.png)

## Profile a parameter that was actually estimated

A parameter profile fixes one free scalar at successive values and refits the other free scalars and random effects. The YTF example fixes `log_Linf`, so it is not an eligible target here. `mean_log_F` is free, and the following three points illustrate how the API works on its natural baseline scale. A useful scientific profile usually needs a denser, justified range and successful fits across the grid.

`delta_nll` is measured relative to the original fit. A negative value means a grid refit found a lower objective and the original optimum should be investigated; it is not clipped to zero. Failed points remain visible. The function does not infer confidence intervals or automatic likelihood-ratio cutoffs. External inputs such as M and survey catchability belong in sensitivity scenarios, not this scalar profile.

```r
profile_values <- exp(a$opt$par[["mean_log_F"]]) * c(0.9, 1, 1.1)
profile_F <- profile_model(a, "mean_log_F", profile_values,
                           scale = "natural", ncores = 1)
profile_F$grid
ggplot(profile_F$grid, aes(value, delta_nll)) +
  geom_line() + geom_point() +
  labs(x = "F process baseline", y = "Change in negative log likelihood") +
  theme_bw() + theme(panel.grid = element_blank())
```

![Illustrative profile of the free F process baseline](../assets/manual/figures/workflows/profile-F.png)

## 5. Project explicitly defined future scenarios

`project_model()` advances saved population states under supplied future fishing mortality, recruitment, weights and maturity. The code below **explicitly chooses** to carry forward the last observed weight/maturity columns and terminal fitted recruitment for four periods. Those are example assumptions, not defaults selected by the function. Growth remains at the fitted key and, for ALSCL, fitted transition matrix. Future M defaults to the original recorded input; it can also be supplied explicitly.

States, B and SSB describe the **start** of each future period. The first future state uses the terminal fitted F and original M, followed by the first supplied recruitment. Future F[t] affects catch[t] and survival into t+1. The two scenarios therefore have the same first future SSB, but different first-period catches; their SSB responses appear subsequently. M and F are instantaneous rates per model step, including quarters.

These are deterministic conditional scenarios. They include no uncertainty intervals, estimated stock–recruitment function, MSY or TAC calculation. Use the output to examine stated assumptions, not to imply forecast certainty or a management recommendation.

```r
h <- 4L
w <- as.matrix(x$data.wgt[-1L])
mat <- as.matrix(x$data.mat[-1L])
future_w <- matrix(w[, ncol(w)], nrow(w), h)
future_mat <- matrix(mat[, ncol(mat)], nrow(mat), h)
future_rec <- rep(tail(b$report$Rec, 1), h)

low_F <- project_model(b, F = rep(0.10, h), recruitment = future_rec,
                       weight = future_w, maturity = future_mat)
higher_F <- project_model(b, F = rep(0.25, h), recruitment = future_rec,
                          weight = future_w, maturity = future_mat)
low_F$summary
higher_F$summary
low_F$assumptions
projection_ssb <- rbind(
  transform(low_F$summary, scenario = "F = 0.10"),
  transform(higher_F$summary, scenario = "F = 0.25"))
ggplot(projection_ssb, aes(year, SSB, color = scenario)) +
  geom_line() + geom_point() + labs(x = "Year", y = "Start-of-period SSB") +
  theme_bw() + theme(panel.grid = element_blank())
```

![Conditional ALSCL SSB scenarios with explicitly held future biology](../assets/manual/figures/workflows/projection-SSB.png)

## 6. Fit simulation replicates and report their failure rate

`sim_model()` selects ACL or ALSCL for files produced by `sim_data()`. `sim_acl()` retains the original ACL interface; `sim_alscl()` is its ALSCL counterpart. This short example uses two replicates to demonstrate file alignment, not to estimate simulation performance precisely. Use the matching model's starts and map. The teaching presets are conditional simulation settings, not evidence for fixing those parameters with real data.

Each input file `sim_rep<i>` contains `sim.data`. Each fitted record is named and saved as `result_rep_<i>`, including failures. Truth must be keyed to those exact result names and use the recorded simulation time coordinates. Do not reuse one returned replicate's truth for every fit. Below, truth is read from each separate simulation file and aligned explicitly.

```r
pa <- x$parameters
bio <- sim_cal(pa)
iterations <- 1:2
simulation_dir <- tempfile("assessment-sim-")
sm <- sim_data(bio, pa, iter_range = iterations,
               return_iter = iterations[1], output_dir = simulation_dir)

cfg <- x$fit_config$alscl
simulation_fits <- sim_model(iterations, simulation_dir,
  file.path(simulation_dir, "fits_alscl"), model = "alscl", ncores = 1,
  parameters = cfg$parameters, parameters.L = cfg$parameters.L,
  parameters.U = cfg$parameters.U, map = cfg$map, M = pa$M)

simulation_truth <- setNames(lapply(iterations, function(i) {
  e <- new.env(parent = emptyenv())
  load(file.path(simulation_dir, paste0("sim_rep", i)), envir = e)
  s <- e$sim.data
  list(year = s$years, SSB = as.numeric(s$SSB), Rec = as.numeric(s$Rec))
}), paste0("result_rep_", iterations))
stopifnot(identical(names(simulation_fits), names(simulation_truth)))
performance <- summarize_simulations(simulation_fits, simulation_truth,
                                     quantities = c("SSB", "Rec"))
performance$replicates
performance$summary
head(performance$estimates)
```

## Interpret the simulation denominators and retain the record

Bias and RMSE use numerically valid estimate–truth pairs; coverage additionally requires usable reported standard errors. Always report `failure_rate`, `n_replicates`, `n_valid_fits`, `n_valid_pairs` and `n_intervals` alongside the performance statistics. Missing standard errors are not counted as coverage failures; relative bias excludes zero truth. F is intentionally excluded because its group summary and uncertainty must be defined separately.

These are operating-model experiments, not automatically a fitted parametric bootstrap. Two replicates cannot establish coverage or model superiority. For a real experiment, specify scenarios and sufficient replication before interpreting results. Save the configuration, all failures and the generating truth, rather than only successful estimates.

```r
record_dir <- tempfile("assessment-record-")
dir.create(record_dir)
write.csv(scenarios$status, file.path(record_dir, "scenario_status.csv"), row.names = FALSE)
write.csv(profile_F$grid, file.path(record_dir, "profile_F.csv"), row.names = FALSE)
write.csv(performance$summary, file.path(record_dir, "simulation_summary.csv"), row.names = FALSE)
saveRDS(list(input = x, scenarios = scenarios, profile = profile_F,
  projections = list(low_F = low_F, higher_F = higher_F),
  simulation_truth = simulation_truth, performance = performance),
  file.path(record_dir, "workflow_record.rds"))
writeLines(capture.output(sessionInfo()), file.path(record_dir, "session.txt"))
```
