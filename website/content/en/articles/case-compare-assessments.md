# Do ACL and ALSCL give different answers?

On this page you fit ACL and ALSCL to the same synthetic YTF observations and see where the two population structures agree and where they differ. You need the package installed ([Install ALSCL](getting-started.html)); `YTF_example` supplies the tables, the biology and the fixed parameters of both models, so the comparison is conditional on those teaching values. At the end you have comparison tables, four figures and a saved folder.

<h2 id="fit">1. Fit both models to the same observations</h2>

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
inputs <- x[c("data.CatL", "data.wgt", "data.mat")]
a <- run_acl(x, train_times = 2, silent = TRUE)
b <- run_alscl(x, train_times = 2, silent = TRUE)
```

Both fits read the input bundle `x`, so they share the tables, `M`, survey catchability and time grid, and each model takes its starting values and `map` from `x$fit_config`; the fixed growth and process values contribute no uncertainty to the intervals. Use the same tables and biological inputs, and document each model's map, fixed values, bounds and numerical checks. Interpret the differences under these fitting configurations when assessing the effect of model structure.

<h2 id="checks">2. Check both fits and compare the fit statistics</h2>

```r
diagnose_model(x$data.CatL, a)
diagnose_model(x$data.CatL, b)
comparison <- compare_models(a, b, x$data.CatL)
comparison$summary
comparison$fit_diagnostics
comparison$comparison
plot_compare_residuals(a, b, x$data.CatL)
```

Read the numerical checks first ([Understand your first fit](first-model.html#checks)). `compare_models()` verifies that both fits used the same survey table, then compares the objective, AIC, BIC and the fit statistics in `fit_metrics`. `comparison$comparison` records `data_verified`, `eligible` (both fits passed the checks), `preferred` (the model with the lower AIC, given only when both are eligible and the AIC values differ by at least 2) and `issues`. In the recorded run ([comparison_summary.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/comparison_summary.csv)) both fits passed; ACL had the lower AIC and the smaller survey-index RMSE, 2.5 against 4.4. A lower AIC is statistical support on these data; whether the structure suits the stock is a biological decision.

![Synthetic YTF: residual comparison for ACL and ALSCL](../assets/manual/figures/ytf/compare_residuals.png)

The four panels show the residual histogram, the QQ plot, the mean residual by year (error bars: one standard deviation) and the absolute residual by length bin; [Judge whether a fit can be used](diagnostics.html#residuals) explains the patterns.

<h2 id="survey">3. Compare the fit to the survey observations</h2>

```r
plot_compare_CatL(a, b, x$data.CatL,
                  years = c(2000, 2005, 2010, 2015), facet_ncol = 2)
```

![Synthetic YTF: observed survey indices and fitted medians in four years](../assets/manual/figures/ytf/compare_CatL.png)

Points are the observations and curves the fitted medians in the four selected years. Compare the fitted shapes, in particular in the larger length bins with low survey indices, before reading differences in abundance.

<h2 id="estimates">4. Compare the population estimates</h2>

```r
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
comparison$correlation
comparison$length_at_age
comparison$growth
```

![Conditional population estimates from the synthetic YTF example](../assets/manual/figures/ytf/compare_ts.png)

Compare the timing, trends and magnitudes of the point estimates, then inspect their uncertainty; `se = TRUE` adds each fit's approximate intervals. Overlap alone does not show that point estimates are close: wide intervals can overlap despite large differences. For a quantitative comparison, report differences or ratios at matching times. Inference about those differences requires their joint uncertainty because the fits use the same data. This example describes one dataset.

`comparison$correlation` gives the correlation between the two fits and the ratio of their means for spawning biomass, recruitment, biomass and abundance. Catch is compared as relative catch (rows `CN (relative)` and `CB (relative)`, without a ratio), because a fit to a survey index does not determine the level of catch. Compare growth through `comparison$length_at_age`, the mean length at age of both fits. `comparison$growth` lists `Linf`, `k` and `t0` in a separate block for each model, because they are the parameters of a von Bertalanffy curve of mean length at age in ACL and set the growth increment at length in ALSCL ([Judge whether a fit can be used](diagnostics.html#compare)).

<h2 id="mortality">5. Compare fishing mortality</h2>

```r
plot_compare_F(a, b)
```

![Synthetic YTF: age-based and length-based fishing mortality](../assets/manual/figures/ytf/compare_F.png)

ACL estimates fishing mortality by age and ALSCL by length, so the panels' cells match only in time. `plot_compare_F_ts()` summarizes the groups of each time step by their maximum (`method = "apical"`, the default) or mean; quarterly values stay per quarter.

<h2 id="save">6. Save the comparison for review</h2>

```r
dir.create("my_model_comparison", showWarnings = FALSE)
write.csv(comparison$summary, "my_model_comparison/summary.csv", row.names = FALSE)
write.csv(comparison$fit_metrics, "my_model_comparison/fit_metrics.csv", row.names = FALSE)
write.csv(comparison$fit_diagnostics, "my_model_comparison/fit_diagnostics.csv", row.names = FALSE)
p_population <- plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
ggplot2::ggsave("my_model_comparison/population.png", p_population,
               width = 10, height = 7, dpi = 300)
saveRDS(list(inputs = inputs, fit_args = x$fit_args, fit_config = x$fit_config,
             comparison = comparison, ACL_report = a$report, ALSCL_report = b$report),
        "my_model_comparison/summary.rds")
writeLines(capture.output(sessionInfo()), "my_model_comparison/session.txt")
```

The folder holds the CSV tables, the population figure, an RDS with the inputs, settings, comparison and both reports, and the session information. Report with it the time window, fixed biology, zero treatment and sensitivity to the fixed values.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Draw the other comparison figures | [Model comparisons](model-comparison.html) |
| Examine the residual patterns of one fit | [Judge whether a fit can be used](diagnostics.html) |
| Remove recent time steps and refit | [Do estimates change when recent data are removed?](case-retrospective-bias.html) |
| Test the sensitivity to M and the F structure | [How sensitive is the assessment, and what happens under future F?](case-sensitivity-projection.html) |
| Fit both models to your own tables | [How do I fit my own survey data?](case-fit-survey.html) |
