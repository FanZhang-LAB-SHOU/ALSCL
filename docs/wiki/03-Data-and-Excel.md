# 03 准备调查数据 · Prepare your survey data

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/02-Theory) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/04-Built-in-YTF)

**ALSCL 2.4.1 · 简体中文 / English**

本页把你的调查观测整理成 `run_acl(x)` 和 `run_alscl(x)` 可以接受的输入列表 `x`，并在第一次拟合前检查它。你需要已安装的软件包（[安装 ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)）、按年或按季度的体长别调查尾数、体长别平均体重和成熟比例，以及第 4 步列出的本种群生物学数值。

On this page you turn your survey observations into an input bundle `x` that `run_acl(x)` and `run_alscl(x)` accept, and you check it before the first fit. You need the package installed ([Install ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)), your survey numbers at length by year or quarter, mean weight and maturity at length, and the biological values of your stock listed in step 4.

| 步骤 / Step | 完成后得到什么 / What you will have afterwards |
|---|---|
| 1. 排好三张表 / 1. Lay out three tables | 行列完全一致的工作簿或三个 CSV 文件 / A workbook or three CSV files with identical rows and columns |
| 2. 确定时间步 / 2. Choose the time step | 没有隐藏缺口的时间网格，以及零值的处理决定 / A time grid without hidden gaps and a decision about zeros |
| 3. 读入文件 / 3. Read the files | R 中已检查对齐的三张表列表 / The three tables as a list in R, already checked for alignment |
| 4. 加入生物学设置 / 4. Add the biology | 带有本种群设置的输入列表 `x` / The input bundle `x` with your stock's settings |
| 5. 检查输入列表 / 5. Check the bundle | 确认 `x` 可以拟合，并得到将被估计的参数清单 / A confirmation that `x` can be fitted, and the list of parameters that will be estimated |

<a id="data-preparation-table-layout"></a>

### 1. 排好三张匹配的表 / Lay out three matching tables

两个模型读取布局相同的三张表：调查指数表 `data.CatL`（每个体长组、每个时间步调查捕到的尾数）、体重表 `data.wgt`（每个体长组、每个时间步一尾鱼的平均体重）和成熟比例表 `data.mat`（成熟个体比例）。行是体长组，列是时间步，三张表顺序相同。下载[示例工作簿](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx)，留一份副本，再把其中的数值换成你的数据。

Both models read three tables with the same layout: the survey index table `data.CatL` (numbers of fish caught by the survey in each length bin and time step), the weight table `data.wgt` (mean weight of one fish in each bin and time step) and the maturity table `data.mat` (proportion mature). The rows are the length bins and the columns are the time steps, in the same order in all three tables. Download the [example workbook](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx), keep a copy, and replace its values with yours.

| 位置 / Location | 规则 / Rule |
|---|---|
| 工作表名 / Sheet names | 必须是 `data.CatL`、`data.wgt` 和 `data.mat`（或三个同名的 CSV 文件） / Exactly `data.CatL`, `data.wgt` and `data.mat` (or three CSV files with these names) |
| A1 单元格 / Cell A1 | `LengthBin`；表头上方不要有标题行 / `LengthBin`; no title rows above the header |
| A 列 / Column A | 每行一个体长组；示例用中点 6、8、...、50 cm / One length bin per row; the example uses the midpoints 6, 8, ..., 50 cm |
| 第 1 行 / Row 1 | 递增的数值时间标签：年度为 2000、2001、...；季度为 2000、2000.25、2000.5、... / Increasing numeric time labels: 2000, 2001, ... for years; 2000, 2000.25, 2000.5, ... for quarters |
| 其他单元格 / Other cells | 每个体长组和时间步一个数字；表格内不放其他内容 / One number per bin and time step; nothing else inside the grid |
| 三张表 / All three tables | 体长组、时间标签和顺序完全相同 / Identical bins, time labels and order |

<a id="data-preparation-survey-table"></a>

#### 调查指数表 data.CatL / Survey index table data.CatL

填入体长别调查尾数，或经一致标准化的指数（例如每网次尾数），可以有小数。某个体长组在某个时间步没有观测时，单元格留空或写 `NA`；不要用 0、短横线或 `<1` 表示未知。0 表示调查在该体长组确实没有捕到。

Enter the survey numbers at length, or a consistently standardized index of them (for example numbers per tow). Decimals are fine. Leave a cell blank, or write `NA`, when that bin was not observed in that time step; do not write 0, a dash or `<1` for an unknown value. A 0 means the survey observed nothing in that bin.

![调查指数工作表 / Survey index worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_CatL.png?raw=true&v=86653ca443d4)

<a id="data-preparation-weight-table"></a>

#### 体重表 data.wgt / Weight table data.wgt

填入每个体长组、每个时间步一尾鱼的平均体重，全表使用同一单位（示例为 kg）。每个单元格都要有值，因为模型用尾数乘体重得到生物量。如果只有体长-体重关系而没有逐年测量值，就用关系式的结果填满所有时间步，并在报告评估时说明。

Enter the mean weight of one fish in each bin and time step, in one unit throughout (the example uses kg). Every cell needs a value, because the model multiplies numbers by weight to obtain biomass. If you have a length-weight relationship instead of yearly measurements, fill all time steps with its values and say so when you report the assessment.

![体重工作表 / Weight worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_wgt.png?raw=true&v=d9137372f011)

<a id="data-preparation-maturity-table"></a>

#### 成熟比例表 data.mat / Maturity table data.mat

填入 0 到 1 之间的成熟比例（60% 写 0.6）。每个单元格都要有值，0 和 1 都可以。产卵生物量等于尾数乘体重乘成熟比例，这张表决定哪些体长组算作亲体。

Enter the proportion mature as a number between 0 and 1 (0.6 for 60%). Every cell needs a value; 0 and 1 are valid. Spawning biomass is numbers times weight times maturity, so this table decides which bins count as spawners.

![成熟比例工作表 / Maturity worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_mat.png?raw=true&v=8d3c34642af1)

<a id="data-preparation-time-and-bins"></a>

### 2. 确定时间步并处理缺口 / Choose the time step and handle gaps

模型逐个时间步推进种群，`growth_step` 是一个时间步的长度（年）：年度调查为 1，季度调查为 0.25。相邻列标签之差必须恰好等于 `growth_step`，模型才知道两列之间过了多长时间。没有调查的时间步仍要保留为一列，调查单元格留空，体重和成熟比例照常填写；模型会把这一步当作未观测。

The models advance the population one time step at a time, and `growth_step` is the length of that step in years: 1 for annual surveys, 0.25 for quarterly surveys. Consecutive column labels must differ by exactly `growth_step`, so the models know how much time passed between two columns. A time step without a survey stays in the table as a column of blank survey cells with its weight and maturity filled in; the models then treat that step as unobserved.

| 情况 / Situation | 如何填写 / What to enter |
|---|---|
| 年度调查，2002 年没有调查 / Annual survey, no survey in 2002 | 保留 2002 列；调查单元格留空；填写体重和成熟比例 / Keep a 2002 column; leave its survey cells blank; fill weight and maturity |
| 季度调查 / Quarterly survey | 标签 2000、2000.25、2000.5、2000.75、...；第 4 步设 `growth_step = 0.25` / Labels 2000, 2000.25, 2000.5, 2000.75, ...; `growth_step = 0.25` in step 4 |
| 某个体长组在某个时间步没有观测 / One bin not observed in one time step | 该调查单元格留空 / Leave that survey cell blank |
| 记录到的零值 / A recorded zero | 保留 0；在第 4 步决定零值按缺失处理（默认 `zero_action = "missing"`）还是终止拟合（`"error"`） / Keep the 0; decide in step 4 whether zeros are treated as missing (`zero_action = "missing"`, the default) or stop the fit (`"error"`) |

体长组需要中点（`len_mid`，每行一个）和相邻体长组之间的内部边界（`len_border`，比行数少一个）。第一组和最后一组分别延伸到 0 和无穷大，比你的范围更小或更大的鱼都计入两端的组。等宽体长组的中点就是行标签，边界在相邻中点的中间；不等宽时填写调查设计中的实际边界。

The length bins need their midpoints (`len_mid`, one per row) and the internal boundaries between bins (`len_border`, one fewer than the rows). The first and last bins extend to zero and infinity, so fish smaller or larger than your range are counted in the end bins. If your bins have equal width, the midpoints are the row labels and the boundaries lie halfway between them; if not, enter the actual boundaries from your survey design.

<a id="data-preparation-import"></a>

### 3. 把文件读入 R / Read the files into R

两个读取函数任选其一。两者都返回包含三张表的列表，把数字文本转换为数值，并在表格不一致时停止并给出提示。

Use one of the two readers. Both return a list with the three tables, convert numeric text to numbers, and stop with a message when the tables differ.

```r
library(ALSCL)
install.packages("readxl") # 只需一次；仅读取 Excel 文件时需要 / once; only needed for Excel files
tables <- read_survey_excel("my_survey.xlsx")
str(tables)
```

```r
# 同一文件夹中的三个文件 data.CatL.csv、data.wgt.csv 和 data.mat.csv / Three files data.CatL.csv, data.wgt.csv and data.mat.csv in one folder
tables <- read_survey_csv("my_data")
str(tables)
```

`str(tables)` 应显示三张行列数相同的数据框，每张表第一列是体长标签。提示“nonnumeric cell in time column 2003”说明表格里有文本；“must match data.CatL length labels and time columns”说明某张表的行或列与其他表不同。修改文件后重新读取。

`str(tables)` should show three data frames with the same number of rows and columns, the first column of each being the length labels. A message such as "nonnumeric cell in time column 2003" points to a text entry in the grid; "must match data.CatL length labels and time columns" means the rows or columns of one table differ from the others. Fix the file and read it again.

<a id="data-preparation-bundle"></a>

### 4. 加入生物学设置，组成输入列表 / Add the biology and build the input bundle

`prepare_alscl_data()` 把三张表和两个模型共用的设置 `fit_args` 组合成输入列表 `x`。这些设置描述你的种群和调查，模型把它们当作已知值。

`prepare_alscl_data()` combines the three tables with the settings both models share, `fit_args`, into the input bundle `x`. The settings describe your stock and your survey; the models take them as given.

| 设置 / Setting | 含义 / Meaning | 数值来源 / Where the value comes from |
|---|---|---|
| `rec.age` | 模型中最小年龄组的年龄（年） / Age of the youngest age class in the model, in years | 鱼首次出现在调查中的年龄 / Age at which fish first appear in the survey |
| `nage` | 年龄组数；最后一组是加组 / Number of age classes; the last one is a plus group | 值得追踪的最大年龄除以 `growth_step` / Oldest age worth tracking, divided by `growth_step` |
| `M` | 每个时间步的自然死亡率 / Natural mortality per time step | 文献或生活史方法；季度时间步时把年值除以 4 / Literature or life-history methods; divide an annual value by 4 for quarterly steps |
| `sel_L50`、`sel_L95` / `sel_L50`, `sel_L95` | 调查可捕性达到 50% 和 95% 的体长 / Lengths at which survey catchability reaches 50% and 95% | 渔具选择性研究或渔获体长分布 / Gear selectivity studies or the length distribution of the catch |
| `growth_step` | 每个时间步的年数 / Years per time step | 第 2 步 / Step 2 |
| `len_mid`、`len_border` / `len_mid`, `len_border` | 体长组中点和内部边界 / Bin midpoints and internal boundaries | 第 2 步 / Step 2 |
| `zero_action` | 调查表中 0 的处理方式 / How a 0 in the survey table is treated | `"missing"`（默认）或 `"error"` / `"missing"` (default) or `"error"` |

```r
x <- prepare_alscl_data(tables, fit_args = list(
  rec.age = 1, nage = 15, M = 0.2, sel_L50 = 15, sel_L95 = 20,
  growth_step = 1, len_mid = seq(6, 50, 2), len_border = seq(7, 49, 2)))
saveRDS(x, "my_bundle.rds")
```

上面的数值是模拟示例的设置，请换成你的种群的值。`x` 是普通列表，用 `saveRDS()` 保存后可在以后的会话中用 `readRDS()` 读回。各模型的初值和 `map` 可以之后以 `fit_config` 的形式加入；没有时模型使用默认初值，并固定[拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)中列出的参数。

The numbers above are the settings of the synthetic example; replace them with the values for your stock. `x` is a plain list, so `saveRDS()` keeps it for later sessions and `readRDS()` brings it back. Starting values and a `map` for each model can be added later as `fit_config`; without them the models use their default starting values and fix the parameters listed in [Fitting controls](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting).

<a id="data-preparation-check"></a>

### 5. 拟合前检查输入列表 / Check the bundle before fitting

```r
check <- check_alscl_data(x, "acl")
check$valid
check$errors
check$warnings
check$summary
plan <- inspect_parameters(x, "acl")
plan[, c("parameter", "status", "natural_start", "n_free")]
```

`check_alscl_data()` 按拟合时的方式准备数据，但不编译任何东西，然后报告输入列表能否拟合。`check$summary` 统计体长组数、时间步数、正观测数、零值数、空白数、没有任何观测的时间步和体长组，以及将被估计的标量参数（`free_fixed`）和随机效应（`free_random`）数量。`inspect_parameters()` 列出每个参数在自然尺度上的初值及其状态：`free`（估计）、`fixed`（固定）或 `tied`（共享）。打算拟合 ALSCL 时，用 `"alscl"` 再运行一遍这两个函数。

`check_alscl_data()` prepares the data exactly as a fit would, without compiling anything, and reports whether the bundle can be fitted. `check$summary` counts the bins, time steps, positive observations, zeros, blanks, time steps and bins without any observation, and the numbers of scalar (`free_fixed`) and random-effect (`free_random`) parameters that will be estimated. `inspect_parameters()` lists every parameter with its starting value on the natural scale and its status: `free` (estimated), `fixed` or `tied`. Run both again with `"alscl"` when you intend to fit that model.

若 `check$valid` 为 `FALSE`，`check$errors` 中的信息会指出要修改的表、列或设置；警告提示值得查看的情况，例如零值很多或某个时间步没有观测。检查通过后，用 `run_acl(x)` 或 `run_alscl(x)` 拟合，并按[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)继续。

If `check$valid` is `FALSE`, the messages in `check$errors` name the table, column or setting to correct; warnings point to things worth a look, such as many zeros or an unobserved time step. When the check passes, fit with `run_acl(x)` or `run_alscl(x)` and continue as in [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin).

<a id="data-preparation-legacy"></a>

### 仓库脚本和兼容数据 / Repository script and compatibility data

调用仓库中 `scripts/real_data_workflow.R` 的 `validate_survey_tables()` 或 `fit_survey_tables()` 的脚本仍可使用，该脚本的读取函数直接调用上面的包函数。软件包还附带 `example_data`，是三张 ALSCL 数据表（9 个体长组，2001-2021），物种、单位和体长组边界都没有记录；只用它试运行函数。

Scripts that call `validate_survey_tables()` or `fit_survey_tables()` from `scripts/real_data_workflow.R` in the repository still work; the script's readers call the package functions above. The package also ships `example_data`, three ALSCL tables with 9 bins and the years 2001-2021 whose species, units and bin boundaries are undocumented; use it only to try the functions.

<a id="data-preparation-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 拟合输入列表并判断结果 / Fit the bundle and judge the result | [理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) / [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) |
| 决定哪些参数固定、哪些估计，选择 F 结构 / Decide which parameters to fix or estimate, choose the F structure | [拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Fitting controls](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 跟着完整的实测数据示例从 CSV 做到保存结果 / Follow a complete own-data example from CSV to saved results | [如何拟合自己的调查数据？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md) / [How do I fit my own survey data?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md) |
| 检查季度调查的时间网格 / Check the time grid of a quarterly survey | [年度与季度时间步](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) / [Annual and quarterly time steps](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) |

---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/02-Theory) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/04-Built-in-YTF)
