# Fitting controls

Complete the [worked YTF example](first-model.html) first. The examples below use its `x`, `inputs`, `a` (ACL) and `b` (ALSCL) objects.

|Setting|Meaning and effect|
|---|---|
| `rec.age`, `nage` |Recruitment age and number of age classes|
| `growth_step` |Years per step. ACL NULL uses rec.age if below 1, otherwise 1; ALSCL defaults to 1. Set 0.25 explicitly for quarterly data.|
| `M` |Instantaneous natural mortality per model step|
| `sel_L50`, `sel_L95` |Fixed survey catchability locations|
| `len_mid`, `len_border` |Midpoints and internal boundaries; ALSCL also offers outer bounds|
| `parameters`, `.L`, `.U` |Named starting values and bounds on the optimizer scale|
| `map` |Fix or release parameters at their supplied values|
| `train_times` |Successive optimization passes, not independent random starts|
| `control` |Optimizer controls|
| `ncores` |Maximum simultaneous socket workers; not threads within one start|
| `nstarts` |Total fit starts, defaulting to ncores. Fix this value when comparing worker counts|
| `output` |Export diagnostics and plots under output when TRUE|


Simulation presets and estimation starts are separate. Choosing a species in `create_parameters()` does not automatically change the biological arguments passed to `run_*()`.

```r
p <- create_parameters(model_type = "acl", species = "flatfish")
names(p) # Inspect start and bound components
# Explicit fixed parameters, model-specific names
fixed <- list(log_Linf = factor(NA), log_vbk = factor(NA))
# NULL releases a default fixed item
released <- list(logit_log_F_y = NULL)
VB_func(Linf = 60, k = 0.2, t0 = 1/60, age = 1:15)
mat_func(L50 = 35, L95 = 40, length = seq(6, 50, 2))
```

| Meaning | ACL parameter | ALSCL parameter |
|---|---|---|
|Growth| `log_Linf`, `log_vbk`, `t0` | `log_Linf`, `log_vbk`, `log_t0` |
|Length dispersion| `log_cv_len` | `log_cv_len`, `log_cv_grow` |
|Process SD| `log_std_log_R`, `log_std_log_F`, `log_std_log_N0` | `log_sigma_log_R`, `log_sigma_log_F`, `log_sigma_log_N0` |
|F correlation| `logit_log_F_a`, `logit_log_F_y` | `logit_log_F_l`, `logit_log_F_y` |
|Recruitment correlation| `logit_log_R` | `logit_log_R` |


Most `log_` parameters use log-transformed values; correlation transforms must match the template. ACL `t0` is untransformed, while ALSCL exponentiates `log_t0`, preventing negative t0 in this parameterization. Do not interchange their parameter lists.

For the required-input checklist, all estimable parameters, exact default maps and complete examples, see [your own survey assessment](case-fit-survey.html). Pass release lists directly as `map`; `generate_map()` removes NULL entries, so passing its output back to the fitter can reapply default fixes.

## Refinement and shared F in 2.2.2

`run_acl(x)` and `run_alscl(x)` now finish the selected fit with up to five safeguarded Newton steps (`polish = TRUE`). Each step requires a positive-definite numerical Hessian, parameters strictly inside their bounds, a smaller maximum absolute gradient, and an objective increase no greater than `1e-8` for floating-point roundoff. Refinement stops if a condition fails; it cannot repair insufficient information or an inappropriate model. Set `polish = FALSE` to skip it. This can change estimates at numerical precision, so 2.2.2 does not promise bitwise equality with older fits.

Repeated optimizer passes retain their raw parameters, objective, code and message in `fit$optimizer_history`. An unchanged failed restart no longer overwrites an earlier successful pass. `fit$raw_opt` records the selected result before refinement; `fit$refinement` records accepted steps and before/after gradients. `convergence_code` remains the selected raw optimizer code, not an invented success code after refinement. Multistart selection still uses the lowest finite objective before refinement; `starts` and `start_diagnostics` describe those unrefined starts.

`fit$diagnostics` adds a separate numerical screen: maximum gradient below `1e-3`, positive-definite Hessian and covariance, no optimizer boundary and no natural-scale boundary. Free correlations within `1e-4` of 0 or 1 and free process/observation SDs at or below `1e-4` are flagged. These are screening thresholds, not statistical tests. `high_correlations` lists parameter pairs with absolute correlation at least 0.95; this warrants investigation but does not alone prove non-identifiability. The covariance condition number depends on parameter scaling. `diagnose_model()` prints the raw optimizer status and numerical screen separately; inspect residuals, alternative starts, profiles and sensitivity as well.

### Choose the F structure explicitly

The default `F_structure = "group_year"` preserves the original age × time (ACL) or length × time (ALSCL) separable AR(1) field. The optional `F_structure = "year"` assumes **the same instantaneous F for all ages or lengths within each time step**. For quarterly data, this is one F per quarter, not one per calendar year. This biological assumption is appropriate only when supported by the fishery; it is not an automatic cure for non-convergence.

In the shared structure, `log(F[y]) = mean_log_F + u[y]`, with a stationary one-dimensional AR(1): `u[1]` has SD `sigma_F`, and later innovations have SD `sigma_F * sqrt(1 - rho_y^2)`. There are Y random F effects instead of A × Y or L × Y. The C++ likelihood includes exactly one normalized AR(1) density. It does not tie together cells of a two-dimensional density. The unused age/length correlation is automatically fixed, excluded from free parameters and omitted from the fitted report, even if its map entry is NULL. Other map defaults remain unchanged. `report$dev_log_F` is 1 × Y; `report$F` (ACL) or `report$FL` (ALSCL) retains its full group × Y shape, and F-deviation plots show one shared series.

The following example assumes `x` contains your validated input tables, biology and starting values from the complete survey example. It fixes only t0 among the **active** scalar parameters; the unused group correlation is structurally absent:

```r
map_acl_t0 <- list(t0 = factor(NA), log_std_log_F = NULL,
                   logit_log_F_y = NULL, logit_log_F_a = NULL)
map_alscl_t0 <- list(log_t0 = factor(NA), log_sigma_log_F = NULL)
a_year <- run_acl(x, map = map_acl_t0, F_structure = "year")
b_year <- run_alscl(x, map = map_alscl_t0, F_structure = "year")
a_year$optimizer_history
a_year$refinement
b_year$diagnostics
b_year$sd_info
diagnose_model(x$data.CatL, b_year)
plot_deviance(a_year, type = "F", se = TRUE)
plot_fishing_mortality(b_year, se = TRUE)
# Store the choice to continue using the shortest syntax:
x$fit_config$acl$map <- map_acl_t0
x$fit_config$alscl$map <- map_alscl_t0
x$fit_args$F_structure <- "year"
a_year <- run_acl(x)
b_year <- run_alscl(x)
```

Original separate-argument and `do.call()` calls remain valid. `retro_model()` (including its wrappers) and `sim_acl()` also accept `F_structure` and `polish`; pass the same structure to all retrospective peels. Parallel standard errors and multistart workers continue to use the existing speed settings. In `sim_data()`, F innovation SD is not the same as the marginal SD in the fitting AR(1); for one-dimensional stationary AR(1), marginal SD equals innovation SD divided by `sqrt(1 - rho_y^2)`.

The earlier t0-only ACL failure on the synthetic YTF data was associated with age correlation approaching 1; those data were generated with shared F across ages. The shared-F alternative addresses that mismatch. The t0-only ALSCL false-convergence case instead benefits from numerical refinement. Neither finding establishes that all parameters are identifiable in your own observations. See the [2.2.2 reproducible validation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/RELEASE_2.2.2.md) for measured results and limitations.
