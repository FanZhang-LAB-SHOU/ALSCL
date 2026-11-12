# How sensitive is an assessment, and what happens under future F scenarios?

On this page you ask three questions of one fitted assessment, the synthetic YTF example: how much the estimates move when the fixed natural mortality or the F structure changes, how well the data determine an estimated parameter, and what deterministic future F scenarios imply. You need the package installed ([Install ALSCL](getting-started.html)); the code runs in order from the fits of step 1 and takes a few minutes. At the end you have a scenario table and figure, a parameter profile and two projections, each with its numerical checks.

<h2 id="fit">1. Fit the reference models</h2>

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

The ACL fit `a` serves the scenarios and the profile, because an ACL refit takes about twenty seconds; the ALSCL fit `b` serves the projections. `summary()` prints the time steps, the F structure, the numerical checks (`numerical_ok` should be `TRUE`) and the scalar parameters on the natural scale. `YTF_example` fixes growth, the length CVs, two process standard deviations and the recruitment correlation at teaching values, with `M` = 0.20 per annual time step and the default `F_structure = "group_year"`; your own bundle needs supported biology ([Choose the fitting settings](fitting-controls.html)). If a check fails, repair the fit before any scenario ([Judge whether a fit can be used](diagnostics.html)).

<h2 id="scenarios">2. Fit the sensitivity scenarios</h2>

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

`fit_scenarios()` refits the same three tables under named changes of the inputs the model takes as given: each scenario is a list of arguments that replace the settings of `x`, an empty list is the reference, and a list such as `map` replaces the stored list completely. `low_M` lowers natural mortality from 0.20 to 0.15 per time step; `shared_F` sets `F_structure = "year"`, one F per time step shared by all ages (one per quarter for quarterly data), leaving the correlation across ages inactive. `ncores` runs scenarios on separate workers, each fit with one worker and the bundle's or the call's `nstarts` (one start when neither sets it); `F_summary = "mean"` averages F over the ages of each time step and `"apical"` takes the maximum. Read `scenarios$status` first: one row per scenario with time taken, warnings, errors and the numerical checks. A scenario that failed the checks stays in `scenarios$estimates` with `numerical_ok = FALSE`, and one that stopped with an error has no estimates.

![ACL sensitivity to the supplied M and shared-F structure](../assets/manual/figures/workflows/scenario-SSB.png)

In the recorded run all three fits passed ([scenario-status.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/scenario-status.csv)), and at the last time step, 2019 ([scenario-estimates.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/scenario-estimates.csv)):

| Scenario | Spawning biomass 2019 | Mean F per time step |
|---|---:|---:|
| `reference` | 75.7 | 0.318 |
| `low_M` | 75.6 | 0.369 |
| `shared_F` | 74.3 | 0.331 |

The lower M raises the estimated F while terminal spawning biomass hardly moves, and the three curves nearly coincide; with your own data the spread between the curves is the sensitivity to report.

<h2 id="profile">3. Profile an estimated parameter</h2>

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

`profile_model()` fixes one estimated scalar parameter at each grid value and refits the other scalar parameters and the process deviations; the name must be in `names(a$opt$par)`, so `log_Linf`, fixed in `YTF_example`, stops with an error, while `mean_log_F` is estimated. With `scale = "natural"` the grid is on the natural scale, here 0.9, 1 and 1.1 times the fitted baseline, and must lie within the optimizer bounds. `profile_F$grid` gives each value with its objective, `delta_nll` (the rise in negative log likelihood relative to the original fit) and the numerical checks of that refit; failed points stay visible. Negative `delta_nll` values are retained; a value below `-1e-6` triggers a warning about a lower objective. Check that grid fit's numerical status and rerun the original with more starts. Tiny negative differences can reflect roundoff. Fixed inputs such as `M` and survey catchability belong in step 2.

![Illustrative profile of the free F process baseline](../assets/manual/figures/workflows/profile-F.png)

In the recorded run ([profile-F.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/profile-F.csv)) the three points 0.281, 0.312 and 0.344 gave changes of 0.93, about 0 (-8e-11, rounding) and 0.76, all passing the checks: a 10% change of the baseline F costs 0.8 to 0.9 units. Three points show the method; a profile for a report needs a denser grid, and the function infers no confidence interval from it.

<h2 id="project">4. Project future F scenarios</h2>

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

`project_model()` advances the last fitted population through future time steps under values you supply: `F` (one value per step shared by all groups, or a group by step matrix), `recruitment` (its length sets the horizon), and complete `weight` and `maturity` matrices with one column per future step; `M` stays at the fitted value unless you pass another. Nothing is carried forward for you: the code repeats the last observed weight and maturity columns and the last fitted recruitment for four steps, a choice to state in the report. Each row of `summary` describes the start of a time step: the first future state is the last fitted population survived through the last fitted F and M plus the first supplied recruitment, and a future `F[t]` sets the catch of step `t` and the survival into step `t + 1`, so the two scenarios share the first future spawning biomass and separate from the second step on, though their first catches differ. The projection is deterministic and conditional on the fit, without intervals, a stock-recruitment relationship or reference points; `low_F$assumptions` records every choice. A fit that failed the numerical checks is refused unless `allow_failed_fit = TRUE`, which records the override.

![Conditional ALSCL SSB scenarios with explicitly held future biology](../assets/manual/figures/workflows/projection-SSB.png)

In the recorded run ([projections.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/projections.csv)) both scenarios start at a spawning biomass of 65.0 in 2020; in 2023 it is 115 under F = 0.10 and 73.3 under F = 0.25, in the units implied by the example's weights and conditional on the held recruitment and biology.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Save the scenario, profile and projection record with the fit | [Assessment workflows](assessment-workflows.html#save-workflow) |
| Examine residual patterns before trusting a projection | [Judge whether a fit can be used](diagnostics.html) |
| Refit after removing recent time steps | [Do estimates change when recent data are removed?](case-retrospective-bias.html) |
| Simulate from the fit and score predictions of withheld time steps | [Can the fitted model reproduce observations and predict withheld time steps?](case-model-validation.html) |
