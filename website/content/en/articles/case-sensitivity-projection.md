# How sensitive is an assessment, and what happens under future F scenarios?

## The question

Changing an externally supplied M, changing the F structure, and prescribing future F answer different questions. This case uses one synthetic YTF dataset to keep those questions separate: fit sensitivity on the same observations, inspect the information about a free F parameter, then project conditional future paths. The calculations below are complete and can be run in order.

The bundled biology and fixed-parameter maps are teaching assumptions. For your own stock, prepare its three tables and independently supported biology with the [assessment workflow](assessment-workflows.html). Do not copy the YTF fixed map merely to force convergence.

## Fit the common data

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

## Separate sensitivity scenarios from parameter profiles

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

## Project explicitly defined future scenarios

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

## What this executed example shows

The reference, low-M and shared-F ACL fits and all three profile points passed their numerical screens in the recorded run. At the last fitted period (2019):

| Scenario | SSB | Mean F per model step |
|---|---:|---:|
| Reference | 75.655 | 0.3184 |
| M = 0.15 | 75.579 | 0.3694 |
| Shared F | 74.292 | 0.3308 |

Reducing the supplied M produces a higher estimated F here while terminal SSB changes little. This is sensitivity within one synthetic dataset and its conditional biological assumptions, not a general identification result or evidence that one structure is superior. F is the unweighted age-group mean in this table.

The F-baseline profile points are approximately 0.2811, 0.3123 and 0.3436, with changes in negative log likelihood of 0.9321, approximately zero and 0.7623. The tiny negative middle change (about −7.7e−11) is numerical roundoff. Three points illustrate the method; they do not define a confidence interval.

Both ALSCL projections start at SSB 65.032 in 2020, because the terminal fitted mortality produces that first future state. In 2023, SSB is 114.631 under F = 0.10 and 73.311 under F = 0.25, conditional on the supplied fixed recruitment and biology. The first-period catches already differ. These numbers are in the units implied by the example's weights; they are not forecasts for a real stock.

Full recorded tables: [scenario status](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/scenario-status.csv), [scenario estimates](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/scenario-estimates.csv), [profile](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/profile-F.csv), [projections](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/projections.csv).

## Retain diagnostics and assumptions

Review warnings, errors, gradients, Hessians and boundaries for every fit. A numerical pass does not remove residual structure or prove adequacy. See the [complete workflow](assessment-workflows.html) for conditional residual diagnostics, portable records and simulation failure/coverage summaries.
