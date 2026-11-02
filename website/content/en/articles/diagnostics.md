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

`diagnose_model()` prints the optimizer convergence code (0 is normal), the maximum absolute gradient (below 0.001 passes), whether the Hessian is positive definite, whether a parameter sits on a bound, and whether a standard deviation or correlation was estimated at its natural limit. `b$diagnostics$issues` lists the failed checks; `high_correlations` lists pairs of parameters whose estimates are correlated at 0.95 or more, which means the data separate them poorly. `b$refinement` records the Newton steps that finished the fit (`status` is `gradient_tolerance` when the gradient criterion was met), and `b$start_diagnostics` shows the objective of every start when you used `nstarts`.

When a check fails, change one thing at a time: run more starts (`nstarts = 4`), fix the parameter that is poorly determined or share F across groups (`F_structure = "year"`), as described in [Fitting controls](fitting-controls.html), and compare the new fit with the old one in step 3. A fit that passes the checks has a well-defined optimum; whether it describes the data is the question of step 2.

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

The residual is the observed log survey index minus the fitted one. `facet_by = "year"` draws the residuals against length for each year; `facet_by = "length"` draws them against year for each length bin. `check_fit()` standardizes the residuals and adds three views: a heatmap of year by length, where blocks of the same colour show a cohort or a size range the model misses; the correlation between residuals of the same length bin one to `max_lag` time steps apart, where values far from zero at short lags show year effects missing from the model; and a QQ plot, where heavy tails point to outliers or to observation errors that depart from the lognormal.

Treat these views as guides to what to change, not as tests: the residuals are conditional on the fitted process deviations, so no significance level is attached to them. A pattern confined to the smallest bins often reflects survey selectivity (`sel_L50`, `sel_L95`); a pattern that moves diagonally through the heatmap reflects growth.

<h2 id="compare">3. Compare configurations and models</h2>

```r
comparison <- compare_models(a, b, x$data.CatL)
comparison$comparison
comparison$fit_metrics
plot_compare_residuals(a, b, x$data.CatL)
plot_compare_ts(a, b, quantities = c("SSB", "Rec"), se = TRUE)
```

`compare_models()` works for any two fits of the same observations: ACL against ALSCL, or two configurations of one model, such as a parameter fixed and released. It first verifies that both fits used the same survey table (`data_verified`), then compares AIC, BIC and the fit statistics in `fit_metrics`. The `preferred` entry names the model with the lower AIC only when both fits passed the numerical checks (`eligible`); otherwise it stays empty and `issues` says why. Use the comparison to choose between statistically comparable configurations; a lower AIC does not make a model with unsuitable fixed values or structure usable.

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
