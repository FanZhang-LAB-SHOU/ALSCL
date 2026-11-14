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

填入体长别调查尾数，或经一致标准化的指数（例如每网次尾数），可以有小数。模型输出的尺度就是这个指数的尺度。使用默认的 logistic 曲线时，调查可捕性对大个体上升到固定的最大值 1，模型不估计可捕性的比例系数。因此，只有当指数本身是体长别绝对丰度估计（例如按扫海面积扩展到种群分布区的尾数）时，丰度、生物量、产卵生物量、补充量和捕获量才是绝对估计。使用每网次尾数这类相对指数时，这些量是以指数单位表示的相对值，坐标轴也应这样标注。捕捞死亡率不受指数尺度影响。某个体长组在某个时间步没有观测时，单元格留空或写 `NA`；不要用 0、短横线或 `<1` 表示未知。0 表示调查在该体长组确实没有捕到。

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

提供体长组中点（`len_mid`，每行一个）和组间内部边界（`len_border`，比行数少一个）。计算年龄–体长概率时，首组和末组分别吸收正态分布的下尾和上尾，数学边界为负无穷和正无穷。该分布不在零处截断；这是分配概率的约定，不表示观测到负体长。等宽组的中点可用行标签，内部边界位于相邻中点之间；不等宽组则填写调查设计使用的边界：行标签是间距不等的单个数值而又没有提供 `len_border` 时，拟合把边界设在相邻标签的中点并给出警告。

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

`str(tables)` 应显示三张行列数相同的数据框，每张表第一列是体长标签。提示“nonnumeric cell in time column 2003”说明表格里有文本；“must match data.CatL length labels and time columns”说明某张表的行或列与其他表不同。单元格含 `#DIV/0!` 或 `#N/A` 这样的 Excel 错误值时，`read_survey_excel()` 也会停止，并指出工作表和单元格；只有空单元格和 `NA` 表示缺失。修改文件后重新读取。

<h2 id="bundle">4. 加入生物学设置，组成输入列表</h2>

`prepare_alscl_data()` 把三张表和两个模型共用的设置 `fit_args` 组合成输入列表 `x`。这些设置描述你的种群和调查，模型把它们当作已知值。

| 设置 | 含义 | 数值来源 |
|---|---|---|
| `rec.age` | 模型中最小年龄组的年龄（年） | 鱼首次出现在调查中的年龄 |
| `nage` | 年龄组数，最后一组包括达到或超过该组起始年龄的个体 | 在年龄网格上选定末组起始年龄 A（年），取 `nage = 1 + (A - rec.age) / growth_step` |
| `M` | 每个时间步的自然死亡率：一个数，或下一小节中的其他形式 | 该种群已有公认的评估时，取评估所用的值。否则按最大年龄估计：年死亡率等于 5.4 除以最大年龄（年）（[Hamel 和 Cope 2022](https://doi.org/10.1016/j.fishres.2022.106477)）。季度时间步时把年值除以 4 |
| `sel_L50`、`sel_L95` | 调查可捕性达到其最大值的 50% 和 95% 时的体长；最大值固定为 1。给出 `survey_q` 时两者都不要给 | 调查渔具的校准资料或对比捕捞试验。借用外部曲线时，说明假设并检验结果对该曲线的敏感性。 |
| `survey_q`、`survey_q_age` | 可选。直接给出的体长别调查可捕性，以及按年龄组的调查可捕性系数 | 见下一小节 |
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

<h3 id="mortality-catchability">自然死亡率和调查可捕性的其他形式</h3>

```r
mid <- seq(6, 50, 2)
# 按年龄组的 M，各时间步相同：只有一列的矩阵
M_age <- matrix(c(0.4, 0.3, rep(0.2, 13)), ncol = 1)
# 按体长组的 M（仅 ALSCL）：与体长成反比，40 cm 处为 0.2
M_length <- lorenzen_M(mid, M_ref = 0.2, L_ref = 40)
round(M_length, 2)
# 用穹顶形调查可捕性代替 sel_L50 和 sel_L95
q_dome <- survey_catchability(mid, "dome", L50 = 15, L95 = 20,
                              L50_desc = 42, L95_desc = 34, minimum = 0.2)
round(q_dome, 2)
x_dome <- prepare_alscl_data(tables, fit_args = list(
  rec.age = 1, nage = 15, M = M_age, survey_q = q_dome,
  growth_step = 1, len_mid = mid, len_border = seq(7, 49, 2)))
check_alscl_data(x_dome, "acl")$valid
```

`M` 有三种形式，由它的 `dim` 属性区分。一个数表示所有年龄、体长和时间步共用一个死亡率。每个年龄组一行的矩阵是按年龄的 M：每个时间步一列，或者只有一列并用于所有时间步，所以不随时间变化的年龄别 M 写作 `matrix(M_at_age, ncol = 1)`。没有维度的数值向量，每个体长组一个值，是按体长的 M。`run_alscl()` 接受这种形式，`run_acl()` 不接受，因为 ACL 只跟踪各年龄的尾数。所有数值都是每个时间步的死亡率。代码中的数字只用来演示这些形式。

`lorenzen_M()` 按 `M_ref * (length / L_ref)^exponent` 返回按体长的 M。默认指数 -1 使 M 与体长成反比，这是 [Lorenzen 等 (2022)](https://doi.org/10.1016/j.fishres.2022.106327) 得到的种群内部 M 随体长的变化；[Lorenzen (2022)](https://doi.org/10.1016/j.fishres.2022.106454) 指出，体长小于渐近体长的约 20% 时会偏离这一关系。`M_ref` 是体长为 `L_ref` 时的死亡率，而文献中的单一 M 通常代表成鱼，所以 `L_ref` 应取成鱼的体长，数值来自年龄鉴定资料或文献。不要用模型估计的 `Linf`，否则所假定的 M 会依赖于使用它的那次拟合。`round(M_length, 2)` 对 6 cm 组给出 1.33，对 50 cm 组给出 0.16，所以拟合前要检查最小几个体长组的死亡率。

`survey_q` 代替 `sel_L50` 和 `sel_L95`。它是每个体长组一个正值的向量；可捕性随时间变化时（例如调查网具更换之后），是每个体长组一行、每个时间步一列的矩阵。`survey_catchability()` 计算最大值为 1 的 logistic 曲线或穹顶形曲线。对穹顶形曲线，`L50_desc` 和 `L95_desc` 是下降段取 0.5 和 0.95 时的体长，`minimum` 是下降段对最大个体趋近的值。`survey_q_age` 是按年龄组的系数，每个年龄组一个正值，例如按年龄的评估对同一调查估计出的各年龄相对可捕性。同时给出 `survey_q` 和 `sel_L50` 或 `sel_L95` 会报错。对新的输入列表，`check_alscl_data()` 应返回 `TRUE`。

这些输入都是假定，拟合本身无法检验它们。调查指数提供的是总死亡率的信息，不能把它分成捕捞死亡率和自然死亡率；可捕性随体长或年龄下降而输入中没有给出时，拟合会把它当作更高的死亡率（[模型原理与时间尺度](model-theory.html#survey)）。按年龄和时间步的 M 应来自独立的估计（例如多鱼种模型），可捕性的形状应来自对调查网具的研究或年龄资料。不要按拟合的目标函数来选择它们。记录每项输入的来源，并报告结果随它们的变化（[判断拟合是否可用](diagnostics.html#sensitivity)）。

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
