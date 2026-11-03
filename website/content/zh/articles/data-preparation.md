# 准备调查数据

本页把你的调查观测整理成 `run_acl(x)` 和 `run_alscl(x)` 可以接受的输入列表 `x`，并在第一次拟合前检查它。你需要已安装的软件包（[安装 ALSCL](getting-started.html)）、按年或按季度的体长别调查尾数、体长别平均体重和成熟比例，以及第 4 步列出的本种群生物学数值。

| 步骤 | 完成后得到什么 |
|---|---|
| 1. 排好三张表 | 行列完全一致的工作簿或三个 CSV 文件 |
| 2. 确定时间步 | 没有隐藏缺口的时间网格，以及零值的处理决定 |
| 3. 读入文件 | R 中已检查对齐的三张表列表 |
| 4. 加入生物学设置 | 带有本种群设置的输入列表 `x` |
| 5. 检查输入列表 | 确认 `x` 可以拟合，并得到将被估计的参数清单 |

<h2 id="table-layout">1. 排好三张匹配的表</h2>

两个模型读取布局相同的三张表：调查指数表 `data.CatL`（每个体长组、每个时间步调查捕到的尾数）、体重表 `data.wgt`（每个体长组、每个时间步一尾鱼的平均体重）和成熟比例表 `data.mat`（成熟个体比例）。行是体长组，列是时间步，三张表顺序相同。下载[示例工作簿](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx)，留一份副本，再把其中的数值换成你的数据。

| 位置 | 规则 |
|---|---|
| 工作表名 | 必须是 `data.CatL`、`data.wgt` 和 `data.mat`（或三个同名的 CSV 文件） |
| A1 单元格 | `LengthBin`；表头上方不要有标题行 |
| A 列 | 每行一个体长组；示例用中点 6、8、...、50 cm |
| 第 1 行 | 递增的数值时间标签：年度为 2000、2001、...；季度为 2000、2000.25、2000.5、... |
| 其他单元格 | 每个体长组和时间步一个数字；表格内不放其他内容 |
| 三张表 | 体长组、时间标签和顺序完全相同 |

<h3 id="survey-table">调查指数表 data.CatL</h3>

填入体长别调查尾数，或经一致标准化的指数（例如每网次尾数），可以有小数。某个体长组在某个时间步没有观测时，单元格留空或写 `NA`；不要用 0、短横线或 `<1` 表示未知。0 表示调查在该体长组确实没有捕到。

![调查指数工作表](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_CatL.png?raw=true)

<h3 id="weight-table">体重表 data.wgt</h3>

填入每个体长组、每个时间步一尾鱼的平均体重，全表使用同一单位（示例为 kg）。每个单元格都要有值，因为模型用尾数乘体重得到生物量。如果只有体长-体重关系而没有逐年测量值，就用关系式的结果填满所有时间步，并在报告评估时说明。

![体重工作表](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_wgt.png?raw=true)

<h3 id="maturity-table">成熟比例表 data.mat</h3>

填入 0 到 1 之间的成熟比例（60% 写 0.6）。每个单元格都要有值，0 和 1 都可以。产卵生物量等于尾数乘体重乘成熟比例，这张表决定哪些体长组算作亲体。

![成熟比例工作表](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_mat.png?raw=true)

<h2 id="time-and-bins">2. 确定时间步并处理缺口</h2>

模型逐个时间步推进种群，`growth_step` 是一个时间步的长度（年）：年度调查为 1，季度调查为 0.25。相邻列标签之差必须恰好等于 `growth_step`，模型才知道两列之间过了多长时间。没有调查的时间步仍要保留为一列，调查单元格留空，体重和成熟比例照常填写；模型会把这一步当作未观测。

| 情况 | 如何填写 |
|---|---|
| 年度调查，2002 年没有调查 | 保留 2002 列；调查单元格留空；填写体重和成熟比例 |
| 季度调查 | 标签 2000、2000.25、2000.5、2000.75、...；第 4 步设 `growth_step = 0.25` |
| 某个体长组在某个时间步没有观测 | 该调查单元格留空 |
| 记录到的零值 | 保留 0；在第 4 步决定零值按缺失处理（默认 `zero_action = "missing"`）还是终止拟合（`"error"`） |

体长组需要中点（`len_mid`，每行一个）和相邻体长组之间的内部边界（`len_border`，比行数少一个）。第一组和最后一组分别延伸到 0 和无穷大，比你的范围更小或更大的鱼都计入两端的组。等宽体长组的中点就是行标签，边界在相邻中点的中间；不等宽时填写调查设计中的实际边界。

<h2 id="import">3. 把文件读入 R</h2>

两个读取函数任选其一。两者都返回包含三张表的列表，把数字文本转换为数值，并在表格不一致时停止并给出提示。

其他时间列含数字文本或因子时，原有数值列仍保留精度。直接向 `run_acl()` 或 `run_alscl()` 传入表格也遵循此规则，诊断使用相同数值。单元格不能包含复数。

```r
library(ALSCL)
install.packages("readxl") # 只需一次；仅读取 Excel 文件时需要
tables <- read_survey_excel("my_survey.xlsx")
str(tables)
```

```r
# 同一文件夹中的三个文件 data.CatL.csv、data.wgt.csv 和 data.mat.csv
tables <- read_survey_csv("my_data")
str(tables)
```

`str(tables)` 应显示三张行列数相同的数据框，每张表第一列是体长标签。提示“nonnumeric cell in time column 2003”说明表格里有文本；“must match data.CatL length labels and time columns”说明某张表的行或列与其他表不同。修改文件后重新读取。

<h2 id="bundle">4. 加入生物学设置，组成输入列表</h2>

`prepare_alscl_data()` 把三张表和两个模型共用的设置 `fit_args` 组合成输入列表 `x`。这些设置描述你的种群和调查，模型把它们当作已知值。

| 设置 | 含义 | 数值来源 |
|---|---|---|
| `rec.age` | 模型中最小年龄组的年龄（年） | 鱼首次出现在调查中的年龄 |
| `nage` | 年龄组数；最后一组是加组 | 值得追踪的最大年龄除以 `growth_step` |
| `M` | 每个时间步的自然死亡率 | 文献或生活史方法；季度时间步时把年值除以 4 |
| `sel_L50`、`sel_L95` | 调查可捕性达到 50% 和 95% 的体长 | 渔具选择性研究或渔获体长分布 |
| `growth_step` | 每个时间步的年数 | 第 2 步 |
| `len_mid`、`len_border` | 体长组中点和内部边界 | 第 2 步 |
| `zero_action` | 调查表中 0 的处理方式 | `"missing"`（默认）或 `"error"` |

```r
x <- prepare_alscl_data(tables, fit_args = list(
  rec.age = 1, nage = 15, M = 0.2, sel_L50 = 15, sel_L95 = 20,
  growth_step = 1, len_mid = seq(6, 50, 2), len_border = seq(7, 49, 2)))
saveRDS(x, "my_bundle.rds")
```

上面的数值是模拟示例的设置，请换成你的种群的值。`x` 是普通列表，用 `saveRDS()` 保存后可在以后的会话中用 `readRDS()` 读回。各模型的初值和 `map` 可以之后以 `fit_config` 的形式加入；没有时模型使用默认初值，并固定[拟合设置](fitting-controls.html)中列出的参数。

<h2 id="check">5. 拟合前检查输入列表</h2>

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

若 `check$valid` 为 `FALSE`，`check$errors` 中的信息会指出要修改的表、列或设置；警告提示值得查看的情况，例如零值很多或某个时间步没有观测。检查通过后，用 `run_acl(x)` 或 `run_alscl(x)` 拟合，并按[理解第一次拟合](first-model.html)继续。

<h2 id="legacy">仓库脚本和兼容数据</h2>

调用仓库中 `scripts/real_data_workflow.R` 的 `validate_survey_tables()` 或 `fit_survey_tables()` 的脚本仍可使用，该脚本的读取函数直接调用上面的包函数。软件包还附带 `example_data`，是三张 ALSCL 数据表（9 个体长组，2001-2021），物种、单位和体长组边界都没有记录；只用它试运行函数。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 拟合输入列表并判断结果 | [理解第一次拟合](first-model.html) |
| 决定哪些参数固定、哪些估计，选择 F 结构 | [拟合设置](fitting-controls.html) |
| 跟着完整的实测数据示例从 CSV 做到保存结果 | [如何拟合自己的调查数据？](case-fit-survey.html) |
| 检查季度调查的时间网格 | [年度与季度时间步](case-studies.html) |
