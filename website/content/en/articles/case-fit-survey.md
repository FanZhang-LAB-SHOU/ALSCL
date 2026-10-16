# How do I organize my own data into x?

## The input bundle

ALSCL 2.2.2 includes a complete [executable example](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/fit_own_data_example.R): read CSV or Excel tables, build `x`, call `run_acl(x)` and `run_alscl(x)`, inspect diagnostics, draw plots and save results. The demonstration uses the bundled synthetic YTF observations. **For your stock, replace the data and review the biological inputs, parameter bounds and fixed assumptions in steps 1–3. Changing only the file path is insufficient.**

|Field in x|Contents|
|---|---|
|`data.CatL`|Survey numbers or a consistently standardized number index by length and time|
|`data.wgt`|Mean individual weight, not total catch weight|
|`data.mat`|Mature proportion, between zero and one|
|`fit_args`|Shared biology, time step, length bins and fitting controls|
|`fit_config$acl`|ACL initial parameters, optional bounds and map|
|`fit_config$alscl`|ALSCL initial parameters, optional bounds and map|

Both functions read the same tables and shared settings, then select their own model configuration. Explicit call arguments have highest priority. List-valued overrides replace the whole stored list; see [input lists and overrides](first-model.html).

## Prepare the three tables

Put `data.CatL.csv`, `data.wgt.csv` and `data.mat.csv` in one folder. Each needs the same `LengthBin` first column, numeric time headers, dimensions and ordering. The example uses numeric length midpoints as labels. Keep all periods in a regular annual or quarterly sequence. Missing survey values are `NA`; weights and maturity must be complete. Do not substitute zeros for missing observations.

Alternatively, use the [Excel template](../assets/manual/data/ALSCL_Data_Entry_Example.xlsx) with sheets named `data.CatL`, `data.wgt` and `data.mat`. Record species, index standardization, units, bin definitions and the meaning of zeros separately.

![Survey numbers: synthetic workbook layout](../assets/manual/figures/excel_CatL.png)

![Mean individual weight: synthetic workbook layout](../assets/manual/figures/excel_wgt.png)

![Maturity proportions: synthetic workbook layout](../assets/manual/figures/excel_mat.png)

These images illustrate the bundled synthetic data, not empirical observations from your stock. Length and weight units must be consistent throughout the analysis.

## Inputs you must supply

`parameters` supplies starting values, or the values of parameters fixed by `map`. **Supplying a number does not itself fix a parameter.** The input data and biological settings below are not estimated by either fitting function.

|Input|What you must provide|
|---|---|
|`data.CatL`|Survey numbers or a consistently standardized number index by length and time; not total catch weight|
|`data.wgt`, `data.mat`|Aligned mean individual weights and mature proportions; these are treated as supplied values|
|`M`|Natural mortality per model step, supported by external information; annual instantaneous M multiplied by `growth_step`|
|`rec.age`, `nage`, `growth_step`|Recruitment age in years, number of age classes including the plus group, and years per step|
|`sel_L50`, `sel_L95`|Locations of the fixed survey catchability curve, with L95 greater than L50; not estimated fishery selectivity|
|`len_mid`, `len_border`|Actual bin midpoints and internal boundaries; verify any values inferred from labels|

Changing `map` cannot make `M`, survey catchability or the age/bin definitions estimable: they are model inputs, not entries in the current parameter vector. Their uncertainty is not propagated automatically. Record sources, units and sensitivity scenarios. The script's biological values are illustrative, not estimates for your stock.

## Parameters the models can estimate

Every scalar parameter below can be estimated if its map allows it. Unspecified starting values and bounds use package defaults, with some starts adapted to the data. Check their suitability for your species. `log_` values use `log(value)` and correlation starts use `qlogis(rho)` for `0 < rho < 1`; the current models restrict these correlations to positive values.

|Meaning|ACL name|ALSCL name|
|---|---|---|
|Initial total mortality setting the initial age structure|`log_init_Z`|`log_init_Z`|
|Initial log-number deviation SD|`log_std_log_N0`|`log_sigma_log_N0`|
|Log recruitment location|`mean_log_R`|`mean_log_R`|
|Recruitment process SD scale|`log_std_log_R`|`log_sigma_log_R`|
|Recruitment time correlation|`logit_log_R`|`logit_log_R`|
|Log fishing-mortality location|`mean_log_F`|`mean_log_F`|
|Fishing-mortality process SD scale|`log_std_log_F`|`log_sigma_log_F`|
|Fishing-mortality time correlation|`logit_log_F_y`|`logit_log_F_y`|
|Fishing-mortality age / length correlation|`logit_log_F_a`|`logit_log_F_l`|
|Asymptotic length and annual VB growth k|`log_Linf`, `log_vbk`|`log_Linf`, `log_vbk`|
|VB t0|`t0` (untransformed)|`log_t0` (log scale)|
|Length-at-age CV|`log_cv_len`|`log_cv_len`|
|Growth-increment CV|Not present|`log_cv_grow`|
|Log survey observation SD|`log_std_index`|`log_sigma_index`|

`log_init_Z` is distinct from the supplied natural mortality `M`. Exponentiating a log-process location is not the unconditional arithmetic mean. ACL allows negative `t0`; ALSCL currently requires `0 < t0 < rec.age`. Do not replace a negative external t0 by its absolute value. Starts and `parameters.L` / `parameters.U` use the optimizer scale; equal bounds are rejected, so use a map to fix a parameter.

The models also infer random effects `dev_log_R`, `dev_log_F` and `dev_log_N0`. Their dimensions are constructed from the data; do not add them to the scalar starting-value list. F varies over ages and years in ACL, and lengths and years in ALSCL. These random effects are not listed in `fit$opt$par`.

## Set map without fixing everything

|Setting|Effect|
|---|---|
|`parameters = list(log_Linf = log(60))`|A starting value if free; a fixed value only if the map fixes it|
|`map = list(log_Linf = factor(NA))`|Fix Linf at the supplied value, or its model default when omitted|
|`map = list(log_std_log_F = NULL)`|Release this default-fixed ACL parameter; keep other model defaults|
|`map = NULL` or `map = list()`|Apply model defaults, not an all-free model|
|Omit `map` in `run_acl(x)` / `run_alscl(x)`|Use the map stored in the selected `x$fit_config`, if present|

|Model|Default-fixed scalar parameters|Other free scalar parameters|
|---|---|---|
|ACL|`log_std_log_F`, `logit_log_F_y`, `logit_log_F_a`, `t0`|10|
|ALSCL|`log_sigma_log_F`, `log_t0`|13|

The complete script below uses `map_acl <- list()` and `map_alscl <- list()`: **it removes the previous teaching-only fixes on growth, initial-number variability and recruitment correlation**, while retaining the documented model defaults. All fixed values still require review. The defaults are a reproducible baseline, not proof of identifiability for every dataset.

The remaining fixed scalar values in this script are F-process SD 0.2 and t0 = 1/60 in both models, plus F correlations 0.75 across years and ages in ACL (the package starting values for those two fixed correlations). These numbers must also be reviewed for your stock. The script uses two successive optimization passes (`train_times = 2`); this is not two independent starts.

To remove an older bundle's extra fixed assumptions without editing it:

```r
fit_acl <- run_acl(x, map = NULL)
fit_alscl <- run_alscl(x, map = NULL)
```

To fix only t0 and estimate all remaining scalar parameters, explicitly release the other defaults. Save the maps in `x` to retain the direct-call syntax:

```r
x$fit_config$acl$map <- list(
  t0 = factor(NA), log_std_log_F = NULL,
  logit_log_F_y = NULL, logit_log_F_a = NULL)
x$fit_config$alscl$map <- list(
  log_t0 = factor(NA), log_sigma_log_F = NULL)
# Review the t0 / log_t0 values already stored in parameters first.
fit_acl <- run_acl(x)
fit_alscl <- run_alscl(x)
# 13 free scalar parameters in ACL; 14 in ALSCL.
```

This more flexible configuration is an option, not the baseline used for the figures. If t0 should also be estimated, preserve an explicit named NULL:

```r
x$fit_config$acl$map["t0"] <- list(NULL)
x$fit_config$alscl$map["log_t0"] <- list(NULL)
# All 14 / 15 scalar parameters are now free on the next fit.
```

Do not use `map$t0 <- NULL` to release default-fixed t0: it deletes the entry and the default will fix it again. Pass release lists directly to `run_*()` or store them in `x`. `generate_map()` is ACL-specific and removes NULL entries from its result; feeding that result back into `run_acl()` re-applies absent defaults and can undo a release.

Explicit `map` arguments replace the whole map stored in `x`, after which model defaults are applied. To change one stored entry while preserving the rest, use `x$fit_config$acl$map["log_Linf"] <- list(NULL)`, for example. Do not generate a map by applying `factor(NA)` to every supplied start for an empirical assessment.

After fitting, inspect the actual free parameters and diagnostics:

```r
names(fit_acl$opt$par)
fit_acl$par_low_up
names(fit_alscl$opt$par)
fit_alscl$par_low_up
diagnose_model(x$data.CatL, fit_acl)
diagnose_model(x$data.CatL, fit_alscl)
```

Check the optimizer code, gradient, Hessian, boundary hits, uncertainty and residuals together. Release parameter groups in separate, saved configurations and compare diagnostics; increasing optimizer iterations or the number of starts does not make weakly identified parameters identifiable. The more flexible map may expose problems that a heavily fixed teaching fit hid. Report those problems rather than silently fixing additional parameters to obtain a favorable diagnostic.

## Run the complete example

Install ALSCL 2.2.2 and download the repository. Run from the repository root; the import helpers are repository scripts, not exported package functions. CSV import needs no additional reader. For Excel, install `readxl` once.

```r
library(ALSCL)
packageVersion("ALSCL")
source("scripts/fit_own_data_example.R", encoding = "UTF-8")
```

This creates `x`, `a` (ACL) and `b` (ALSCL), and writes inputs, portable result summaries, two PNG figures and session information to `output/own-data-example`. Change that output directory when setting up your assessment. The complete code follows; copy it into an R script or edit the supplied file.

```r
# ALSCL 2.2.2: CSV -> x -> ACL / ALSCL -> diagnostics and saved summaries.
# source("scripts/fit_own_data_example.R", encoding = "UTF-8")
# The supplied numbers describe the synthetic YTF example, not your stock.

library(ALSCL)
stopifnot(packageVersion("ALSCL") >= "2.2.2")
source("scripts/real_data_workflow.R", encoding = "UTF-8")

# data.CatL.csv, data.wgt.csv, data.mat.csv.
data_dir <- "docs/data"
inputs <- read_survey_csv(data_dir)
# inputs <- read_survey_excel("my_survey.xlsx")

# M_annual and vbk are annual; lengths are cm; weights in the example are kg.
bio <- list(rec.age = 1, nage = 15, M_annual = 0.2,
            growth_step = 1, sel_L50 = 15, sel_L95 = 20,
            Linf = 60, vbk = 0.2, t0 = 1 / 60,
            cv_len = 0.2, cv_grow = 0.2)
stopifnot(bio$t0 > 0, bio$t0 < bio$rec.age)

# For labels such as "5-7", supply the actual midpoints explicitly instead.
len_mid <- as.numeric(inputs$data.CatL[[1]])
stopifnot(all(is.finite(len_mid)), all(diff(len_mid) > 0))
# This midpoint formula is only used for the equal-width demonstration bins.
stopifnot(max(abs(diff(len_mid) - diff(len_mid)[1])) < 1e-8)
len_border <- (head(len_mid, -1) + tail(len_mid, -1)) / 2
validate_survey_tables(inputs, growth_step = bio$growth_step, zero_action = "error")

# Growth and most process values below are starts, not automatic fixes.
# Review starts, bounds and the documented default fixed values for your stock.
p_acl <- list(
  log_Linf = log(bio$Linf), log_vbk = log(bio$vbk), t0 = bio$t0,
  log_cv_len = log(bio$cv_len),
  log_std_log_F = log(0.2), log_std_log_N0 = log(0.2),
  logit_log_R = qlogis(0.1))
p_alscl <- list(
  log_Linf = log(bio$Linf), log_vbk = log(bio$vbk), log_t0 = log(bio$t0),
  log_cv_len = log(bio$cv_len), log_cv_grow = log(bio$cv_grow),
  log_sigma_log_F = log(0.2), log_sigma_log_N0 = log(0.2),
  logit_log_R = qlogis(0.1))
# Default maps: ACL fixes 4 and estimates 10 scalars; ALSCL fixes 2 and estimates 13.
# ACL fixes log_std_log_F, logit_log_F_y, logit_log_F_a and t0.
# ALSCL fixes log_sigma_log_F and log_t0. These values still need justification.
map_acl <- list()
map_alscl <- list()
# Optional: fix only t0; diagnose this more flexible configuration separately.
# map_acl <- list(t0 = factor(NA), log_std_log_F = NULL,
#                 logit_log_F_y = NULL, logit_log_F_a = NULL)
# map_alscl <- list(log_t0 = factor(NA), log_sigma_log_F = NULL)
# Preserve a named NULL to release a default fix; $t0 <- NULL deletes the entry.
# map_acl["t0"] <- list(NULL)
# map_alscl["log_t0"] <- list(NULL)

x <- list(
  data.CatL = inputs$data.CatL,
  data.wgt = inputs$data.wgt,
  data.mat = inputs$data.mat,
  fit_args = list(
    rec.age = bio$rec.age, nage = bio$nage,
    M = bio$M_annual * bio$growth_step,
    sel_L50 = bio$sel_L50, sel_L95 = bio$sel_L95,
    growth_step = bio$growth_step,
    len_mid = len_mid, len_border = len_border,
    zero_action = "error", train_times = 2,
    nstarts = 1, ncores = 1, silent = FALSE),
  fit_config = list(
    acl = list(parameters = p_acl, map = map_acl),
    alscl = list(parameters = p_alscl, map = map_alscl)))

alscl_speed_info()
a <- run_acl(x)
b <- run_alscl(x)
# a <- run_acl(x, nstarts = 4, ncores = 2)
# b <- run_alscl(x, nstarts = 4, ncores = 2)

checks <- list(ACL = diagnose_model(x$data.CatL, a),
               ALSCL = diagnose_model(x$data.CatL, b))
print(checks)
print(a$sd_info)
print(b$sd_info)
for (fit in list(a, b)) {
  print(fit$par_low_up)
  print(list(convergence = fit$convergence_code,
             max_gradient = fit$max_abs_gradient,
             pdHess = fit$pdHess, bound_hit = fit$bound_hit))
  print(fit$refinement)
  print(fit$diagnostics)
  if (!isTRUE(fit$convergence_code == 0L) || !isTRUE(fit$pdHess) ||
      !isTRUE(fit$diagnostics$numerical_ok))
    warning("Review fit diagnostics before interpreting this assessment.")
}
residual_plot <- plot_residuals(b, type = "year", facet_ncol = 4,
                                x_breaks = pretty(len_mid, n = 4))
ssb_plot <- plot_SSB(b, se = isTRUE(b$pdHess))
print(residual_plot)
print(ssb_plot)
portable <- function(fit) fit[setdiff(names(fit), "obj")]
output_dir <- "output/own-data-example"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(file.path(output_dir, "residuals.png"), residual_plot,
                width = 10, height = 8, dpi = 150)
ggplot2::ggsave(file.path(output_dir, "SSB.png"), ssb_plot,
                width = 8, height = 5, dpi = 150)
saveRDS(x, file.path(output_dir, "inputs_x.rds"))
saveRDS(list(ACL = portable(a), ALSCL = portable(b), diagnostics = checks),
        file.path(output_dir, "assessment_summary.rds"))
writeLines(capture.output(sessionInfo()), file.path(output_dir, "sessionInfo.txt"))
# x <- readRDS("output/own-data-example/inputs_x.rds")
# b <- run_alscl(x)
```

## Replace the demonstration with your observations

1. **Files:** change `data_dir` to your CSV folder, such as `"my_data"`. For Excel, replace the reader with `read_survey_excel("my_survey.xlsx")`. Preserve original numeric time headers; the helpers avoid R's automatic `X2000` renaming.
2. **Biology and units:** replace `bio`. `rec.age` is in years; `nage` is the number of age classes including the plus group. Annual time labels use `growth_step = 1`; regular quarterly labels such as `2020`, `2020.25`, `2020.5`, `2020.75` use `0.25`. The script converts annual instantaneous natural mortality to per-step `M` by multiplication. Growth `vbk` remains annual. `sel_L50` and `sel_L95` set survey catchability, not estimated fishery selectivity.
3. **Length groups:** replace `len_mid` and `len_border` with the actual definitions. The example's midpoint-based boundary calculation is only for its contiguous equal-width bins. There must be one fewer internal boundary than bins; the model handles the outer tails. Interval labels such as `"5-7"` need an explicit midpoint vector in this script.
4. **Model assumptions:** review `p_acl`, `p_alscl` and both maps. The example now uses model-default maps, with 10 free scalar parameters in ACL and 13 in ALSCL. Growth and the other released parameters are estimated; the remaining default-fixed values require external justification and sensitivity checks. Supplying an initial value alone does not fix a parameter. Use a named `NULL` map entry to release a parameter, including one fixed by model defaults; `map["name"] <- list(NULL)` preserves the entry. Unspecified parameters, bounds and maps follow package defaults. Add `parameters.L` and `parameters.U` inside the corresponding `fit_config` entry if needed.
5. **Zeros and missing data:** this script uses `zero_action = "error"`, so it stops on zero survey indices. Decide what zeros mean before selecting another treatment; `"missing"` excludes them from the likelihood. Do not add arbitrary small constants. See [data preparation](data-preparation.html).

ACL uses raw `t0`; ALSCL uses `log_t0` and currently requires a positive `t0` below `rec.age`. Do not take the logarithm or absolute value of a negative external estimate to force compatibility. ACL and ALSCL also use different names for several variance parameters; do not interchange their complete parameter lists.

## Fit directly and check acceleration

After building your own `x`, the calls remain short:

```r
a <- run_acl(x)
b <- run_alscl(x)
# Same total work, up to two workers for four independent starts:
a_multi <- run_acl(x, nstarts = 4, ncores = 2)
b_multi <- run_alscl(x, nstarts = 4, ncores = 2)
# The actual standard-error method and core count:
a$sd_info
b$sd_info
```

The existing `alscl_speed()` settings apply automatically. `ncores` controls independent optimization starts; `sd_cores` controls standard-error computation within a fit. The default AD framework remains CppAD. More workers do not guarantee a faster small job. See [speed settings](speed.html).

## Inspect the results

Check convergence code, maximum gradient, Hessian status, boundary hits and residual patterns separately. A completed fit is not sufficient evidence of identifiability or suitable assumptions. The full synthetic CSV workflow was run for both models: convergence code 0, positive-definite Hessian, no boundary hits and maximum gradients below 0.001. These checks validate the example workflow, not an unseen empirical assessment.

The updated script was rerun with the model-default maps and two successive optimization passes. The recorded [diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/own-data-example-checks.csv) are:

|Model|Free scalars|Convergence code|Maximum gradient|Positive-definite Hessian|Boundary hit|
|---|---|---|---|---|---|
|ACL|10|0|2.62e-9|Yes|No|
|ALSCL|13|0|2.59e-9|Yes|No|

The 2.2.2 run used four cores for standard errors and the default safeguarded refinement. These are numerical checks of synthetic data, not validation of an unseen stock assessment. Before refinement was added (2.2.1), the t0-only ALSCL fit could return false convergence at an unchanged optimum. Version 2.2.2 retains the successful earlier pass and refines its gradient to about 5.37e-9. The t0-only ACL with the original F structure still has an age-correlation boundary and fails the numerical screen; choosing shared F is a separate biological model decision, described below.

The following plots were generated by this script using the synthetic CSV inputs.

![ALSCL residuals by year from the complete CSV example](../assets/manual/figures/own-data-example/residuals.png)

![ALSCL spawning biomass from the complete CSV example](../assets/manual/figures/own-data-example/SSB.png)

The spawning-biomass intervals are conditional on the fixed model assumptions. Inspect your own figures and assess sensitivity to supported alternative values of M, catchability and fixed biological parameters.

## Save and reuse x

The script saves `inputs_x.rds`, `assessment_summary.rds`, `residuals.png`, `SSB.png` and `sessionInfo.txt`. The portable summary excludes `obj`, whose TMB pointers belong to the current R session. To refit in a new session:

```r
library(ALSCL)
x <- readRDS("output/own-data-example/inputs_x.rds")
a <- run_acl(x)
b <- run_alscl(x)
```

Keep the original data, configuration, provenance and package version together. The older `fit_survey_tables()` helper, separate-argument calls and `do.call()` remain supported.

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

![2.2.2 convergence checks](../assets/manual/figures/convergence-2.2.2.png)
