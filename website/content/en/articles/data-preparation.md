# Prepare your survey data

**Goal:** turn three aligned survey tables into an input bundle `x`, ready for `run_acl(x)` or `run_alscl(x)`. This page covers table layout, import and checks. Choose biological inputs and parameter maps before fitting; the final section links to that step.

Use the current `main` installation from [Getting started](getting-started.html) for the public import and checking functions below. If you want to try a fit without preparing files, start with the [bundled YTF example](first-model.html).

<h2 id="table-layout">1. Fill in three matching tables</h2>

Download the [Excel example workbook](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx). Its `Instructions` sheet contains bilingual directions; the other three sheets contain the synthetic YTF example. Save a copy before replacing the values.

| Location | Entry rule |
|---|---|
| Sheet names | Exactly `data.CatL`, `data.wgt`, `data.mat` |
| A1 | `LengthBin`; no title rows above the header |
| A2:A… | One length bin per row; example midpoints are 6, 8, …, 50 |
| B1, C1, … | Increasing numeric times: 2000, 2001 for annual data; 2000, 2000.25 for quarters |
| Numeric cells | Value for that bin and period |
| Alignment | Identical bins, periods and order in all three tables |

<h3 id="section-1">Survey number index: data.CatL</h3>

Enter counts or a consistently standardized number index. For CPUE, keep effort, units and standardization comparable. Decimals are valid. Unknown observations are blank or `NA`; do not replace them with zero, dashes, `<1` or text labels.

![Survey data worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_CatL.png?raw=true)

<h3 id="section-2">Mean individual weight: data.wgt</h3>

Enter mean weight per fish, using one documented unit. The table should contain individual weights rather than total weight in a bin. A defensible length–weight relationship can be repeated across periods when that assumption is reported. Every cell must have a value.

![Mean-weight worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_wgt.png?raw=true)

<h3 id="section-3">Maturity proportion: data.mat</h3>

Enter proportions between 0 and 1: use `0.6` for 60%. Both 0 and 1 are valid maturity values. Every cell must have a value. Keep units, totals, merged cells and explanatory prose outside all three data grids.

![Maturity worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_mat.png?raw=true)

Scientific notation can make tiny positive values easier to read. It changes their display, not the stored values.

<h2 id="time-and-bins">2. Check the time grid, bins and missing values</h2>

Consecutive time headers must differ by `growth_step`. Use 1 for annual data and 0.25 for quarterly data. For example:

| Situation | How to represent it |
|---|---|
| Annual observations for 2000, 2001 and 2003 | Keep a 2002 column; put `NA` in its survey cells and supply weight and maturity |
| Quarterly observations | Use headers such as 2000, 2000.25, 2000.5 and `growth_step = 0.25` |
| One unknown survey cell | Use blank or `NA`; keep the row and column |
| A recorded survey zero | Retain the zero and decide explicitly how the observation model will treat it |

The models check this grid and do not fill missing periods or reinterpret irregular intervals. Omitting 2002 from an annual series produces an error.

For length bins, the example uses midpoints 6:50 by 2 and 22 internal boundaries 7:49. Supply actual boundaries for unequal bins. Interval labels must be contiguous and non-overlapping: labels such as `0-20`, `21-25` contain a gap that should be resolved from the original metadata. The first and last bins absorb the distribution tails.

Package fits use `zero_action = "missing"` by default, excluding survey zeros from the log likelihood; `zero_action = "error"` rejects them. Excluding genuine zero observations changes inference. The current lognormal observation model has no zero-inflated component, so arbitrary small constants are not a principled replacement. These survey rules do not exclude legitimate zeros in the maturity table.

<h2 id="section-4">3. Import Excel or CSV files</h2>

Choose **one** import method. Both return `tables`, a list containing `data.CatL`, `data.wgt` and `data.mat`, and check their alignment. The public functions require no `source()` call.

**Excel:** install the optional reader once, then select the downloaded example workbook or your own workbook.

```r
install.packages("readxl") # Once, if not already installed
library(ALSCL)
tables <- ALSCL::read_survey_excel(file.choose())
str(tables)
```

**CSV:** place `data.CatL.csv`, `data.wgt.csv` and `data.mat.csv` in one folder. This example reads the supplied files when R's working directory is the downloaded repository root. Replace `"docs/data"` with your own folder for your observations.

```r
library(ALSCL)
tables <- ALSCL::read_survey_csv("docs/data")
str(tables)
```

Excel import preserves time headers and converts numeric text explicitly. Successful import confirms table structure and values; it does not choose the biology or a parameter map.

<h2 id="input-bundle">4. Add biological settings and inspect the parameter plan</h2>

The following setup is for the **supplied synthetic workbook or CSV files**. Its biological settings come from `YTF_example` because these are YTF teaching data. For your stock, replace these values with supported stock-specific inputs before using the bundle.

```r
data("YTF_example")
demo_biology <- YTF_example$fit_args
x <- prepare_alscl_data(tables, fit_args = demo_biology)

input_check <- check_alscl_data(x, "acl")
input_check$valid
input_check$errors
input_check$warnings

parameter_plan <- inspect_parameters(x, "acl")
parameter_plan[, c("parameter", "status", "start", "n_free")]
```

This preparation does not copy `YTF_example$fit_config`: both models use their ordinary default maps. Inspect those maps before fitting. `check_alscl_data()` and `inspect_parameters()` prepare inputs without compiling or optimizing a model; a valid input check does not establish convergence or identifiability. Repeat the checks with `model = "alscl"` when preparing that model.

For your data, provide recruitment age, number of age classes, natural mortality, survey catchability, time step and actual bin geometry. Weights and maturity also need independent support. Matching the example's table dimensions does not justify reusing its biology.

**Next:** use [the own-data fitting case](case-fit-survey.html) to decide which parameters are supplied, fixed or estimated, and how `map` works. The [assessment workflow](assessment-workflows.html) then connects fitting, result extraction, saving and diagnostics. Once the inputs and assumptions have been reviewed, the direct calls are `run_acl(x)` and `run_alscl(x)`.

<h2 id="legacy-workflows">Earlier script-based workflows</h2>

Existing scripts that use `validate_survey_tables()` or `fit_survey_tables()` remain supported. These helpers require the [repository helper script](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/real_data_workflow.R), unlike the public readers above. Run this optional example from the repository root:

```r
source("scripts/real_data_workflow.R", encoding = "UTF-8")
my_inputs <- read_survey_excel("docs/data/ALSCL_Data_Entry_Example.xlsx")
validate_survey_tables(my_inputs, growth_step = 1, zero_action = "error")
```

The script validator rejects survey zeros by default, asking you to resolve their meaning. This differs from the package fitting default described in step 2. Keep the intended `zero_action` explicit when adapting an older workflow.

<h3 id="section-5">Inspecting legacy example_data</h3>

```r
data("example_data")
names(example_data)
head(example_data$data.CatL)
example_data$data.CatL[[1]]
sum(as.matrix(example_data$data.CatL[-1]) == 0, na.rm = TRUE)
```

These 9-bin, 2001–2021 tables are preserved unchanged from the original ALSCL repository. Their old help describes anonymized survey data, but species, units, source and zero meanings remain unverified. The gapped interval labels are rejected by the current bin parser. Recover the metadata and actual boundaries before assessment; these are not verified empirical data from the cited paper.
