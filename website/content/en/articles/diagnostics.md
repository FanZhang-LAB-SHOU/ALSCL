# Diagnostics

Complete the [worked YTF example](first-model.html) first. The examples below use its `x`, `inputs`, `a` (ACL) and `b` (ALSCL) objects.

## 1. Inspect numerical status

```r
# Numerical checks
c(code = b$convergence_code, gradient = b$max_abs_gradient,
  pdHess = b$pdHess, boundary = b$bound_hit)
diagnose_model(x$data.CatL, b)
diagnostic_metrics(x$data.CatL, b)
comparison <- compare_models(a, b, x$data.CatL)
comparison$fit_metrics
comparison$fit_diagnostics
comparison$comparison
comparison$correlation # Includes Ratio_Mean
plot_residuals(b, type = "length", facet_ncol = 4)
plot_compare_residuals(a, b, x$data.CatL)
```


In the bundled example results, both fits returned code 0, positive-definite Hessians and no detected bound hits. Maximum absolute gradients were about `2.8e-10` and `5.75e-9`. The tutorial's 0.001 screening threshold is not a universal validity criterion.

`run_acl(x)` and `run_alscl(x)` finish the selected fit with up to five safeguarded Newton steps (`polish = TRUE`). Each step requires a positive-definite numerical Hessian, parameters strictly inside their bounds, a smaller maximum absolute gradient, and an objective increase no greater than `1e-8` for floating-point roundoff. Refinement stops if a condition fails; it cannot repair insufficient information or an inappropriate model. Set `polish = FALSE` to skip it. Refinement, introduced in 2.2.2, can change estimates at numerical precision; preserve the package revision and `polish` setting when reproducing older fits.

Repeated optimizer passes retain their raw parameters, objective, code and message in `fit$optimizer_history`. An unchanged failed restart retains an earlier successful pass. `fit$raw_opt` records the selected result before refinement; `fit$refinement` records accepted steps and before/after gradients. `convergence_code` remains the selected raw optimizer code, not an invented success code after refinement. Multistart selection still uses the lowest finite objective before refinement; `starts` and `start_diagnostics` describe those unrefined starts.

`fit$diagnostics` reports a separate numerical screen: maximum gradient below `1e-3`, positive-definite Hessian and covariance, no optimizer boundary and no natural-scale boundary. Free correlations within `1e-4` of 0 or 1 and free process/observation SDs at or below `1e-4` are flagged. These are screening thresholds, not statistical tests. `high_correlations` lists parameter pairs with absolute correlation at least 0.95; this warrants investigation but does not alone prove non-identifiability. The covariance condition number depends on parameter scaling. `diagnose_model()` prints the raw optimizer status and numerical screen separately; inspect residuals, alternative starts, profiles and sensitivity as well.

## 2. Verify observations before comparing fits

`diagnostic_metrics()`, `diagnose_model()` and `compare_models()` check known time labels, length labels, the positive-observation mask and the observations stored with the fit. A table with reordered years or length bins is an error even when its dimensions match. Pass the original fitting table, for example `diagnose_model(x$data.CatL, b)`; these are in-sample diagnostics, not an interface for held-out prediction. Older results without metadata still support raw metrics, but cannot establish verified model comparability.

Comparison tables and metric plots share the same calculations: only finite positive observations contribute, R-squared is `NA` for constant observations, and nonfinite original-scale predictions at observed cells cause an error. Missing or zero observations remain excluded. Passing these checks does not establish model adequacy.

Fitting, diagnostics and comparison use the same interpretation of ordinary data frames, matrices, tibbles and numeric-text factor columns. Factor labels are converted to observation values, never to internal level codes. Length labels are extracted as a vector. The checks for changed observations, missing-data masks, time labels and length-bin order still apply.

`compare_models()` checks both fits against the supplied survey table: time labels, length-bin labels and order, positive observed values and their observation mask must agree. A known mismatch is an error. Older saved results without enough metadata remain readable, but automatic preference is withheld. If either fit fails the numerical screen, the function warns and retains raw AIC/BIC and fit statistics for inspection without declaring a preferred model. Read `comparison$fit_diagnostics` and `comparison$comparison` (`data_verified`, `eligible`, `preferred`, `issues`). A passed screen permits a conditional comparison; you must still assess likelihood comparability and biological assumptions.

## 3. Examine residual patterns and plotting scales

`plot_residuals()` displays raw log residuals: observed log index minus fitted log index. `check_fit()` additionally returns conditional standardized residuals, a heatmap, actual-time lag correlations and a QQ plot. These residuals condition on fitted latent effects; standardization does not make them independent. `plot_deviance()` displays process deviations, not likelihood deviance.

```r
checks <- check_fit(b, max_lag = 4)
checks$plots$heatmap
checks$plots$lag
checks$plots$qq
checks$lag_correlations
```

Survey fit plots align both observed and predicted matrices by their positions and fitted calendar/length metadata, even if dimnames are added or removed. Missing and zero observations stay excluded. Use `exp_transform = FALSE` if exponentiating predictions would overflow. In residual plots, `resid_cap` must be a finite positive scalar or `NULL` to disable capping; negative or zero caps cannot erase the diagnostic pattern.

The default `plot_CatL(exp_transform = FALSE)` displays natural-log survey indices and labels that scale explicitly. `exp_transform = TRUE` displays original-scale survey indices; curves are fitted medians. An explicit `ylab` overrides the automatic label. Ridge compositions are normalized stably on the log scale, including very large or small finite log predictions; nonfinite predictions are rejected.

Each facet chooses its smoother independently using the number of distinct observed x values: fewer than two omit smoothing, two to five use a linear trend, and six or more use loess. The loess span is enlarged within that facet when needed for at least five neighbors. A sparse tail bin does not remove or change trends in other panels.

## 4. Investigate sensitivity and the F structure

Compare results across starting values, biologically supported fixed inputs and alternative F structures. `F_structure = "group_year"` estimates age × time F for ACL or length × time F for ALSCL. `F_structure = "year"` shares F across all groups within each model time step: one value per quarter for quarterly data. Choose this assumption from the fishery and data, not from convergence alone. See [fitting controls](fitting-controls.html) for its AR(1) parameterization, effective map and t0-only example, and [sensitivity and projection](case-sensitivity-projection.html) for a complete comparison.

In the recorded synthetic YTF comparison, the t0-only ACL fit had age correlation approaching 1; those data were generated with F shared across ages. The shared-F structure addressed that mismatch. The t0-only ALSCL fit benefited from optimizer refinement. These are distinct findings for the teaching dataset; the [2.2.2 validation record](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/RELEASE_2.2.2.md) gives the settings and results.

![Recorded numerical checks for the YTF fits](../assets/manual/figures/convergence-2.2.2.png)
