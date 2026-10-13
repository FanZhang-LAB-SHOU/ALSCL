# How do I organize my own data into x?

## The input bundle

ALSCL 2.2.1 includes a complete [executable example](https://github.com/Linbojun99/ALSCL/blob/main/scripts/fit_own_data_example.R): read CSV or Excel tables, build `x`, call `run_acl(x)` and `run_alscl(x)`, inspect diagnostics, draw plots and save results. The demonstration uses the bundled synthetic YTF observations. **For your stock, replace the data and review the biological inputs, parameter bounds and fixed assumptions in steps 1–3. Changing only the file path is insufficient.**

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

## Run the complete example

Install ALSCL 2.2.1 and download the repository. Run from the repository root; the import helpers are repository scripts, not exported package functions. CSV import needs no additional reader. For Excel, install `readxl` once.

```r
library(ALSCL)
packageVersion("ALSCL")
source("scripts/fit_own_data_example.R", encoding = "UTF-8")
```

This creates `x`, `a` (ACL) and `b` (ALSCL), and writes inputs, portable result summaries, two PNG figures and session information to `output/own-data-example`. Change that output directory when setting up your assessment. The complete code follows; copy it into an R script or edit the supplied file.

```r
# ALSCL 2.2.1: CSV -> x -> ACL / ALSCL -> diagnostics and saved summaries.
# Run from the repository root:
# source("scripts/fit_own_data_example.R", encoding = "UTF-8")
# The supplied numbers describe the synthetic YTF example, not your stock.

library(ALSCL)
stopifnot(packageVersion("ALSCL") >= "2.2.1")
source("scripts/real_data_workflow.R", encoding = "UTF-8")

# Read the three aligned tables -------------------------------
# data.CatL.csv, data.wgt.csv, data.mat.csv.
data_dir <- "docs/data"
inputs <- read_survey_csv(data_dir)
# Excel alternative (requires readxl):
# inputs <- read_survey_excel("my_survey.xlsx")

# Shared biology -----------------------------------------
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

# Model-specific settings ------------------------------
# For observations, review starts, bounds and every fixed parameter independently.
# Other parameters use the package's default starts, bounds and maps.
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
map_acl <- lapply(p_acl, function(z) factor(NA))
map_alscl <- lapply(p_alscl, function(z) factor(NA))
map_alscl$logit_log_F_l <- map_alscl$logit_log_F_y <- factor(NA)
# map_acl["log_Linf"] <- list(NULL)
# map_alscl["log_Linf"] <- list(NULL)

# Assemble the input bundle -----------------------------------
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
    zero_action = "error", train_times = 1,
    nstarts = 1, ncores = 1, silent = FALSE),
  fit_config = list(
    acl = list(parameters = p_acl, map = map_acl),
    alscl = list(parameters = p_alscl, map = map_alscl)))

# Fit directly ----------------------------------------------
alscl_speed_info()
a <- run_acl(x)
b <- run_alscl(x)
# a <- run_acl(x, nstarts = 4, ncores = 2)
# b <- run_alscl(x, nstarts = 4, ncores = 2)

# Inspect, plot and save ------------------------------
checks <- list(ACL = diagnose_model(x$data.CatL, a),
               ALSCL = diagnose_model(x$data.CatL, b))
print(checks)
print(a$sd_info)
print(b$sd_info)
for (fit in list(a, b)) {
  print(list(convergence = fit$convergence_code,
             max_gradient = fit$max_abs_gradient,
             pdHess = fit$pdHess, bound_hit = fit$bound_hit))
}
residual_plot <- plot_residuals(b, type = "year", facet_ncol = 4,
                                x_breaks = pretty(len_mid, n = 4))
ssb_plot <- plot_SSB(b, se = TRUE)
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
# Refit in a new session:
# x <- readRDS("output/own-data-example/inputs_x.rds")
# b <- run_alscl(x)
```

## Replace the demonstration with your observations

1. **Files:** change `data_dir` to your CSV folder, such as `"my_data"`. For Excel, replace the reader with `read_survey_excel("my_survey.xlsx")`. Preserve original numeric time headers; the helpers avoid R's automatic `X2000` renaming.
2. **Biology and units:** replace `bio`. `rec.age` is in years; `nage` is the number of age classes including the plus group. Annual time labels use `growth_step = 1`; regular quarterly labels such as `2020`, `2020.25`, `2020.5`, `2020.75` use `0.25`. The script converts annual instantaneous natural mortality to per-step `M` by multiplication. Growth `vbk` remains annual. `sel_L50` and `sel_L95` set survey catchability, not estimated fishery selectivity.
3. **Length groups:** replace `len_mid` and `len_border` with the actual definitions. The example's midpoint-based boundary calculation is only for its contiguous equal-width bins. There must be one fewer internal boundary than bins; the model handles the outer tails. Interval labels such as `"5-7"` need an explicit midpoint vector in this script.
4. **Model assumptions:** review `p_acl`, `p_alscl` and both maps. The teaching example fixes known growth and selected process parameters with `factor(NA)`; this is a conditional fit and omits uncertainty in those fixed values. Supplying an initial value alone does not fix a parameter. Use a named `NULL` map entry to release a parameter, including one fixed by model defaults; `map["name"] <- list(NULL)` preserves the entry. Unspecified parameters, bounds and maps follow package defaults. Add `parameters.L` and `parameters.U` inside the corresponding `fit_config` entry if needed.
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
