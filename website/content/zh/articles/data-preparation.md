# 准备自己的调查数据

**本页目标：**把三张对齐的调查表整理成输入列表 `x`，供 `run_acl(x)` 或 `run_alscl(x)` 使用。先完成填表、导入和检查，再决定生物输入与参数 map；页末会引导到拟合步骤。

以下公开导入与检查函数需要按[开始使用](getting-started.html)安装当前 `main` 版本。若想先试一次拟合，不必准备文件，直接使用[内置 YTF 示例](first-model.html)。

<h2 id="table-layout">1. 填写三张相互对应的表</h2>

下载 [Excel 示例工作簿](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx)。`Instructions` 是双语说明页，其余三张表已填入模拟 YTF 数据。请另存副本再替换数值。

| 位置 | 填写规则 |
|---|---|
| 工作表名 | 必须为 `data.CatL`、`data.wgt`、`data.mat` |
| A1 | `LengthBin`，不要在表头上方加标题 |
| A2:A… | 每行一个体长组；示例中心值为 6、8、…、50 |
| B1、C1、… | 递增数字时间；年度如 2000、2001，季度如 2000、2000.25 |
| 数值单元 | 对应体长组、对应时期的值 |
| 三表对齐 | 体长组、时间和行列顺序完全相同 |

<h3 id="section-1">调查数量指数：data.CatL</h3>

填写数量或已标准化到可比尺度的数量指数。若使用 CPUE，各期努力量、单位和标准化方式应保持可比；正数可以是小数。未知观测留空或填 `NA`，不要用 0、破折号、`<1` 或“未测”代替。

![调查数据填表示例](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_CatL.png?raw=true)

<h3 id="section-2">平均个体重量：data.wgt</h3>

填写平均单尾重量，并统一和记录单位。这张表表示个体重量，不是某组的总重。在有依据并明确报告的情况下，可以跨时期重复同一长度—重量关系。每个单元都必须有值。

![平均体重填表示例](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_wgt.png?raw=true)

<h3 id="section-3">成熟比例：data.mat</h3>

填写 0–1 的比例：60% 填 `0.6`。0 和 1 都是合法成熟比例，每个单元都必须有值。三张数据表中的单位、合计、合并单元格和说明文字应放在数据区之外。

![成熟比例填表示例](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_mat.png?raw=true)

科学记数法可让很小的正数更容易辨认；它改变显示方式，不改变已保存的数值。

<h2 id="time-and-bins">2. 检查时间、体长分组与缺失值</h2>

相邻时间表头之差必须等于 `growth_step`，年度用 1，季度用 0.25。例如：

| 情况 | 整理方式 |
|---|---|
| 只有 2000、2001、2003 年的年度观测 | 保留 2002 列，调查单元填 `NA`，并提供该期重量与成熟比例 |
| 季度观测 | 表头用 2000、2000.25、2000.5 等，设置 `growth_step = 0.25` |
| 某个调查单元未知 | 留空或填 `NA`，保留所在行列 |
| 记录到调查零值 | 保留该零值，并明确决定观测模型如何处理 |

模型会检查时间网格，不会插补缺失时期或重新解释不规则间隔。年度序列若直接删去 2002 列，会报错。

体长分组方面，示例中心值为 6:50、间隔 2，22 个内部边界为 7:49。不等宽组应提供真实边界。区间标签必须连续且不重叠；如 `0-20`、`21-25` 存在间隙，应回到原始元数据核实。首尾分组按模型约定吸收分布尾部。

包内拟合默认 `zero_action = "missing"`，将调查零值从对数似然中排除；`zero_action = "error"` 则拒绝零值。排除真实零观测会改变推断。当前对数正态观测模型没有零膨胀部分，因此不应任意加小常数代替零值。这些调查规则不排除成熟表中的合法零值。

<h2 id="section-4">3. 导入 Excel 或 CSV</h2>

选择**一种**导入方式即可。两种方式都返回包含 `data.CatL`、`data.wgt` 和 `data.mat` 的 `tables`，并检查三表是否对齐。这些公开函数无需先运行 `source()`。

**Excel：**可选读取包只需安装一次，随后选择已下载的示例工作簿或自己的工作簿。

```r
install.packages("readxl") # 未安装时运行一次
library(ALSCL)
tables <- ALSCL::read_survey_excel(file.choose())
str(tables)
```

**CSV：**把 `data.CatL.csv`、`data.wgt.csv` 和 `data.mat.csv` 放在同一目录。以下从下载的仓库根目录读取附带示例；读取自己的观测时，把 `"docs/data"` 改为自己的文件夹。

```r
library(ALSCL)
tables <- ALSCL::read_survey_csv("docs/data")
str(tables)
```

Excel 导入保留时间表头，并显式转换数字文本。导入成功说明表格结构和值符合要求，生物输入和参数 map 仍需另行设置。

<h2 id="input-bundle">4. 加入生物设置，查看参数计划</h2>

以下设置用于**附带的模拟工作簿或 CSV**。因为它们是 YTF 教学数据，生物设置取自 `YTF_example`。自己的种群应在使用这个列表前，换成有依据的物种和种群输入。

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

这里没有复制 `YTF_example$fit_config`，两个模型使用各自的普通默认 map。拟合前应查看这些映射。`check_alscl_data()` 和 `inspect_parameters()` 只准备输入，不编译或优化模型；输入检查通过不能证明收敛或可识别性。准备 ALSCL 时，把模型选项改为 `"alscl"` 再检查一次。

正式数据还需提供补充年龄、年龄组数、自然死亡率、调查可捕性、时间步和真实体长边界。重量与成熟信息也应有独立依据。不能因为表格尺寸与示例相同，就沿用其生物学设置。

**下一步：**阅读[正式数据拟合案例](case-fit-survey.html)，决定哪些参数自行提供、哪些固定或估计，以及如何设置 `map`；[评估工作流](assessment-workflows.html)再把拟合、结果提取、保存和诊断连起来。输入与假设检查完成后，可直接调用 `run_acl(x)` 和 `run_alscl(x)`。

<h2 id="legacy-workflows">已有脚本工作流</h2>

使用 `validate_survey_tables()` 或 `fit_survey_tables()` 的已有脚本仍可运行。这些辅助函数需要[仓库脚本](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/real_data_workflow.R)，与上面的公开读取函数不同。以下为可选的旧接口示例，需从仓库根目录运行：

```r
source("scripts/real_data_workflow.R", encoding = "UTF-8")
my_inputs <- read_survey_excel("docs/data/ALSCL_Data_Entry_Example.xlsx")
validate_survey_tables(my_inputs, growth_step = 1, zero_action = "error")
```

脚本检查器默认拒绝调查零值，要求先确认其含义。这与第 2 步说明的包内拟合默认值不同；整理旧工作流时，应明确保留所需的 `zero_action`。

<h3 id="section-5">检查旧版 example_data</h3>

```r
data("example_data")
names(example_data)
head(example_data$data.CatL)
example_data$data.CatL[[1]]
sum(as.matrix(example_data$data.CatL[-1]) == 0, na.rm = TRUE)
```

这组 9 个体长组、2001–2021 年的表从原 ALSCL 仓库原样保留。旧说明称匿名调查数据，但物种、单位、来源和零值含义仍未核实。现有区间标签有间隙，会被当前分组检查拒绝。正式评估前应恢复元数据和真实边界；它们不是已核实的论文实测数据。
