# Judge whether a fit can be used

On this page you check a fit from four sides: the numerical checks of the optimizer, the residual patterns, the comparison with other configurations, and the sensitivity to the fixed values. You need the objects of [Understand your first fit](first-model.html): the bundle `x`, the ACL fit `a` and the ALSCL fit `b`. The code uses `b`; it works the same for `a`.

<h2 id="numerical">1. Numerical checks</h2>

```r
diagnose_model(x$data.CatL, b)
b$diagnostics$issues
b$diagnostics$high_correlations
b$refinement$status
b$start_diagnostics
```

`diagnose_model()` prints the raw optimizer code, maximum absolute gradient, Hessian and covariance status, and parameter-boundary checks. The numerical screen uses a gradient threshold of 0.001, positive-definite Hessian and covariance matrices, and the boundary checks; the raw optimizer code is reported separately. `b$diagnostics$issues` lists all diagnostic flags. `high_correlations` lists parameter pairs with an absolute estimated correlation of at least 0.95, including negative correlations. These pairs warrant checking parameter identifiability with profiles, additional starts or sensitivity analyses. `b$refinement` records the finishing Newton steps (`status = "gradient_tolerance"` when that criterion was met), and `b$start_diagnostics` records the objective for each start.

When a check fails, change one thing at a time: run more starts (`nstarts = 4`), inspect parameter scales and bounds, and use profiles to investigate poorly determined parameters. If the evidence supports it, fix a parameter or share F across groups (`F_structure = "year"`), as described in [Fitting controls](fitting-controls.html). Compare the revised fit with the original in step 3. Passing the numerical screen does not establish a unique or global optimum, parameter identifiability or an adequate model. [Carvalho et al. (2021), section 2.1](https://repository.library.noaa.gov/view/noaa/32687/noaa_32687_DS1.pdf) explains why several diagnostics are needed.

<h2 id="residuals">2. Residual patterns</h2>

```r
plot_residuals(b, facet_by = "year", facet_ncol = 5)
plot_residuals(b, facet_by = "length", facet_ncol = 4)
checks <- check_fit(b, max_lag = 4)
checks$plots$heatmap
checks$plots$lag
checks$plots$qq
checks$lag_correlations
```

The residual is the observed log survey index minus the fitted one. `facet_by = "year"` plots residuals against length within each year; `facet_by = "length"` plots them against time within each length bin. `check_fit()` uses standardized residuals in three views: a time-by-length heatmap to locate persistent signs or patterns, correlations at lags from one to `max_lag` model time steps to examine temporal dependence, and a QQ plot to compare the residual distribution with a normal reference. Departures from the QQ line describe distributional differences, including skewness or tail behaviour.

Use these patterns to choose hypotheses to examine. A pattern in the smallest bins may motivate a sensitivity analysis of survey catchability (`sel_L50`, `sel_L95`); a diagonal pattern may motivate checks of growth and cohort dynamics. Neither pattern identifies a unique cause, and short-lag correlation alone does not identify a missing year effect. The residuals condition on fitted process deviations, so these plots have no calibrated significance threshold. Compare alternative assumptions before assigning a biological explanation.

<h2 id="compare">3. Compare configurations and models</h2>

```r
comparison <- compare_models(a, b, x$data.CatL)
comparison$comparison
comparison$fit_metrics
plot_compare_residuals(a, b, x$data.CatL)
plot_compare_ts(a, b, quantities = c("SSB", "Rec"), se = TRUE)
```

`compare_models()` works for any two fits of the same observations: ACL against ALSCL, or two configurations of one model, such as a parameter fixed and released. It first verifies that both fits used the same survey table (`data_verified`), then compares AIC, BIC and the fit statistics in `fit_metrics`. The `preferred` entry names the model with the lower AIC only when both fits passed the numerical checks (`eligible`); otherwise it stays empty and `issues` says why. Use the comparison to choose between statistically comparable configurations; a lower AIC does not make a model with unsuitable fixed values or structure usable.

Use the original survey table for both fits. Each positive index is checked at its own scale, with a relative tolerance of `1e-12`. For example, replacing `1e-13` with `1e-20` changes the log observation by about 16 units. The comparison stops before calculating a preference.

<h2 id="sensitivity">4. Sensitivity to the fixed values</h2>

```r
scenarios <- fit_scenarios(x, list(reference = list(), low_M = list(M = 0.15), high_M = list(M = 0.25)),
                           model = "acl", ncores = 2)
scenarios$status
subset(scenarios$estimates, quantity == "SSB" & year == max(year))
```

The fixed inputs (natural mortality `M`, survey catchability, fixed growth parameters) set the scale of the estimates. `fit_scenarios()` refits the same observations under named changes and returns every fit's status and a table of estimates by scenario, so you can see how much the spawning biomass in the last year moves when `M` varies over its supported range. Read `status` first: a scenario that failed the numerical checks stays in the table, flagged. [Assessment workflows](assessment-workflows.html) continues with likelihood profiles and projections.

<h2 id="stability">5. Stability over time</h2>

Two further checks look at the time dimension. A retrospective analysis refits the model after removing the last one, two and three time steps and reports how much the terminal estimates change (Mohn's rho); see [Retrospectives](retrospectives.html). Hindcast validation fits on the earlier time steps and scores the predictions of later ones against the withheld observations; see [Model validation](case-model-validation.html).

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Change a setting that a check pointed to | [Fitting controls](fitting-controls.html) |
| Run retrospectives | [Retrospectives](retrospectives.html) |
| Profile a parameter or project the stock forward | [Assessment workflows](assessment-workflows.html) |
| Check predictions of future time steps | [Model validation](case-model-validation.html) |
| Draw other comparison figures | [Model comparison plots](model-comparison.html) |
