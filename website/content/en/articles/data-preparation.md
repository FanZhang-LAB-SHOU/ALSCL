# Prepare your survey data

On this page you turn your survey observations into an input bundle `x` that `run_acl(x)` and `run_alscl(x)` accept, and you check it before the first fit. You need the package installed ([Install ALSCL](getting-started.html)), your survey numbers at length by year or quarter, mean weight and maturity at length, and the biological values of your stock listed in step 4.

| Step | What you will have afterwards |
|---|---|
| 1. Lay out three tables | A workbook or three CSV files with identical rows and columns |
| 2. Choose the time step | A time grid without hidden gaps and a decision about zeros |
| 3. Read the files | The three tables as a list in R, already checked for alignment |
| 4. Add the biology | The input bundle `x` with your stock's settings |
| 5. Check the bundle | A confirmation that `x` can be fitted, and the list of parameters that will be estimated |

<h2 id="table-layout">1. Lay out three matching tables</h2>

Both models read three tables with the same layout: the survey index table `data.CatL` (numbers of fish caught by the survey in each length bin and time step), the weight table `data.wgt` (mean weight of one fish in each bin and time step) and the maturity table `data.mat` (proportion mature). The rows are the length bins and the columns are the time steps, in the same order in all three tables. Download the [example workbook](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx), keep a copy, and replace its values with yours.

| Location | Rule |
|---|---|
| Sheet names | Exactly `data.CatL`, `data.wgt` and `data.mat` (or three CSV files with these names) |
| Cell A1 | `LengthBin`; no title rows above the header |
| Column A | One length bin per row; the example uses the midpoints 6, 8, ..., 50 cm |
| Row 1 | Increasing numeric time labels: 2000, 2001, ... for years; 2000, 2000.25, 2000.5, ... for quarters |
| Other cells | One number per bin and time step; nothing else inside the grid |
| All three tables | Identical bins, time labels and order |

<h3 id="survey-table">Survey index table data.CatL</h3>

Enter the survey numbers at length, or a consistently standardized index of them (for example numbers per tow). Decimals are fine. The model outputs are on the scale of this index. Survey catchability rises to a fixed maximum of 1 for large fish, and no catchability scale is estimated. Abundance, biomass, spawning biomass, recruitment and catch are therefore absolute estimates only when the index is an absolute abundance estimate at length, such as swept-area numbers expanded to the stock area. With a relative index such as numbers per tow, read them as relative values in the units of the index and label the axes accordingly. Fishing mortality rates do not depend on the scale of the index. Leave a cell blank, or write `NA`, when that bin was not observed in that time step; do not write 0, a dash or `<1` for an unknown value. A 0 means the survey observed nothing in that bin.

![Survey index worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_CatL.png?raw=true)

<h3 id="weight-table">Weight table data.wgt</h3>

Enter the mean weight of one fish in each bin and time step, in one unit throughout (the example uses kg). Every cell needs a value, because the model multiplies numbers by weight to obtain biomass. If you have a length-weight relationship instead of yearly measurements, fill all time steps with its values and say so when you report the assessment.

![Weight worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_wgt.png?raw=true)

<h3 id="maturity-table">Maturity table data.mat</h3>

Enter the proportion mature as a number between 0 and 1 (0.6 for 60%). Every cell needs a value; 0 and 1 are valid. Spawning biomass is numbers times weight times maturity, so this table decides which bins count as spawners.

![Maturity worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_mat.png?raw=true)

<h2 id="time-and-bins">2. Choose the time step and handle gaps</h2>

The models advance the population one time step at a time, and `growth_step` is the length of that step in years: 1 for annual surveys, 0.25 for quarterly surveys. Consecutive column labels must differ by exactly `growth_step`, so the models know how much time passed between two columns. A time step without a survey stays in the table as a column of blank survey cells with its weight and maturity filled in; the models then treat that step as unobserved.

| Situation | What to enter |
|---|---|
| Annual survey, no survey in 2002 | Keep a 2002 column; leave its survey cells blank; fill weight and maturity |
| Quarterly survey | Labels 2000, 2000.25, 2000.5, 2000.75, ...; `growth_step = 0.25` in step 4 |
| One bin not observed in one time step | Leave that survey cell blank |
| A recorded zero | Keep the 0; decide in step 4 whether zeros are treated as missing (`zero_action = "missing"`, the default) or stop the fit (`"error"`) |

Supply length-bin midpoints (`len_mid`, one per row) and internal boundaries (`len_border`, one fewer than the rows). In the age-length probability calculation, the first and last bins absorb the normal distribution's lower and upper tails, with mathematical bounds of negative and positive infinity. The distribution is not truncated at zero; this is a probability-allocation convention, not a negative observed length. For equal-width bins, midpoints are the row labels and internal boundaries are halfway between them. Otherwise supply the boundaries used in your survey design: when the labels are single numbers with unequal spacing and `len_border` is missing, the fit sets the boundaries halfway between adjacent labels and gives a warning.

<h2 id="import">3. Read the files into R</h2>

Use one of the two readers. Both return a list with the three tables, convert numeric text to numbers, and stop with a message when the tables differ.

Native numeric columns retain their precision when other time columns contain numeric text or factors. This also applies when you pass tables directly to `run_acl()` or `run_alscl()`; diagnostics read the same values. Complex-valued cells are invalid.

```r
library(ALSCL)
install.packages("readxl") # once; only needed for Excel files
tables <- read_survey_excel("my_survey.xlsx")
str(tables)
```

```r
# Three files data.CatL.csv, data.wgt.csv and data.mat.csv in one folder
tables <- read_survey_csv("my_data")
str(tables)
```

`str(tables)` should show three data frames with the same number of rows and columns, the first column of each being the length labels. A message such as "nonnumeric cell in time column 2003" points to a text entry in the grid; "must match data.CatL length labels and time columns" means the rows or columns of one table differ from the others. `read_survey_excel()` also stops when a cell holds an Excel error value such as `#DIV/0!` or `#N/A`, and names the sheet and the cells; only blank cells and `NA` denote missing values. Fix the file and read it again.

<h2 id="bundle">4. Add the biology and build the input bundle</h2>

`prepare_alscl_data()` combines the three tables with the settings both models share, `fit_args`, into the input bundle `x`. The settings describe your stock and your survey; the models take them as given.

| Setting | Meaning | Where the value comes from |
|---|---|---|
| `rec.age` | Age of the youngest age class in the model, in years | Age at which fish first appear in the survey |
| `nage` | Number of age classes, including the oldest (plus) group | Choose the starting age A of the plus group on the age grid, in years. Set `nage = 1 + (A - rec.age) / growth_step` |
| `M` | Natural mortality per time step | Literature or life-history methods; divide an annual value by 4 for quarterly steps |
| `sel_L50`, `sel_L95` | Lengths at which survey catchability reaches 50% and 95% of its maximum, which is fixed at 1 | Calibration or comparative fishing trials for the survey gear. If borrowing a curve, document the assumption and test sensitivity to it. |
| `growth_step` | Years per time step | Step 2 |
| `len_mid`, `len_border` | Bin midpoints and internal boundaries | Step 2 |
| `zero_action` | How a 0 in the survey table is treated | `"missing"` (default) or `"error"` |

```r
x <- prepare_alscl_data(tables, fit_args = list(
  rec.age = 1, nage = 15, M = 0.2, sel_L50 = 15, sel_L95 = 20,
  growth_step = 1, len_mid = seq(6, 50, 2), len_border = seq(7, 49, 2)))
saveRDS(x, "my_bundle.rds")
```

The numbers above are the settings of the synthetic example; replace them with the values for your stock. `x` is a plain list, so `saveRDS()` keeps it for later sessions and `readRDS()` brings it back. Starting values and a `map` for each model can be added later as `fit_config`; without them the models use their default starting values and fix the parameters listed in [Fitting controls](fitting-controls.html).

<h2 id="check">5. Check the bundle before fitting</h2>

```r
check <- check_alscl_data(x, "acl")
check$valid
check$errors
check$warnings
check$summary
plan <- inspect_parameters(x, "acl")
plan[, c("parameter", "status", "natural_start", "n_free")]
```

`check_alscl_data()` prepares the data exactly as a fit would, without compiling anything, and reports whether the bundle can be fitted. `check$summary` counts the bins, time steps, positive observations, zeros, blanks, time steps and bins without any observation, and the numbers of scalar (`free_fixed`) and random-effect (`free_random`) parameters that will be estimated. `inspect_parameters()` lists every parameter with its starting value on the natural scale and its status: `free` (estimated), `fixed` or `tied`. Run both again with `"alscl"` when you intend to fit that model.

If `check$valid` is `FALSE`, the messages in `check$errors` name the table, column or setting to correct; warnings point to things worth a look, such as many zeros or an unobserved time step. When the check passes, fit with `run_acl(x)` or `run_alscl(x)` and continue as in [Understand your first fit](first-model.html).

<h2 id="legacy">Repository script and compatibility data</h2>

Scripts that call `validate_survey_tables()` or `fit_survey_tables()` from `scripts/real_data_workflow.R` in the repository still work; the script's readers call the package functions above. The package also ships `example_data`, three ALSCL tables with 9 bins and the years 2001-2021 whose species, units and bin boundaries are undocumented; use it only to try the functions.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Fit the bundle and judge the result | [Understand your first fit](first-model.html) |
| Decide which parameters to fix or estimate, choose the F structure | [Fitting controls](fitting-controls.html) |
| Follow a complete own-data example from CSV to saved results | [How do I fit my own survey data?](case-fit-survey.html) |
| Check the time grid of a quarterly survey | [Annual and quarterly time steps](case-studies.html) |
