# 模拟与批量实验

运行以下示例前先加载 R 包。下文的 `source("scripts/…")` 需在仓库根目录运行；公开的批量拟合函数可直接通过已安装的包调用。

```r
library(ALSCL)
```

## 1. 选择模拟器

```r
# 简单年度模拟，可直接导出 CSV
quick <- simulate_example_data(
  years = 2000:2019, seed = 42, bin_breaks = seq(5, 51, 2),
  Linf = 60, vbk = 0.2, t0 = 1/60, M = 0.2, nage = 15,
  L50_sel = 15, L95_sel = 20, L50_mat = 35, L95_mat = 40,
  wgt_a = exp(-12), wgt_b = 3, mean_F = 0.3,
  cv_catch = 0.2, rec_sigma = 0.3,
  save_csv = TRUE, output_dir = "my_simulation")
str(quick)
```

`years` 必须是连续年度，不能通过写季度列名把该简易模拟器变成季度模型。`cv_catch` 控制调查观测 CV；`rec_sigma` 控制对数补充变异；该函数使用简化的共同 F、独立补充扰动及固定长度 CV = 0.1。它不等于完整 Beverton–Holt 模拟器，也不等于内置 `YTF_example` 的生成流程。


### 年度与季度模拟模型

两个预设的 seed 4 数据、三张 CSV 和完整真值对象已随文档保存，见[下载及读取方法](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/cases/README.md)。

```r
# 参数 → 生物量表 → 随机模拟
pa <- initialize_params(species = "flatfish", first.year = 2000,
                        observation_error = "independent")
bio <- sim_cal(pa)
sm <- sim_data(bio, pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_examples/flatfish")
# 长度型季度案例
tuna_pa <- initialize_params(species = "tuna", first.year = 2000)
tuna <- sim_data(sim_cal(tuna_pa), tuna_pa, iter_range = 4:5,
                 return_iter = 4, output_dir = "simulation_examples/tuna")
# 将模拟矩阵变成模型输入
source("scripts/simulation_workflow.R", encoding = "UTF-8")
flatfish_inputs <- simulation_to_tables(sm, pa)
tuna_inputs <- simulation_to_tables(tuna, tuna_pa)
```

|设置| flatfish / YTF 风格 | tuna / 金枪鱼风格 |
|---|---|---|
|生成模型|年龄型|年龄与长度联合|
| `growth_step` |1 年|0.25 年|
| `nyear`, `burn_in` |100, 80 年|100, 95 年|
|保留观测|20 年度|20 季度|
| `nage`, `rec.age` |15, 1 年|20, 0.25 年|
| `Linf`, `vbk` |60, 0.2/年|152, 0.38/年|
| `M`, `F_mean` |0.2, 0.3 每年|0.2, 0.2 每季度|

这是包内的两个模拟预设案例，不能当成已取得论文两个案例的原始观测。完整参数见 [initialize_params](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#initialize_params)。`nyear`、`burn_in`、`sim_year` 的单位是**年**；返回 `sm$nyear` 是保留的**时间步数**。`SN_at_len` 是时间 × 长度，导入时要转置；`weight` 和 `mat` 已是长度 × 时间。


`iter_range` 同时指定重复编号和随机种子；`return_iter` 选择在内存中返回哪次重复。每个 `sim_rep4` 等文件由 `save()` 写出，应用 `load()`，不是 `readRDS()`。`observation_error="independent"` 让每个长度与时间单元有独立扰动；`"shared_time"` 让同一期的长度组共享扰动，适合专门的误差结构实验。


```r
# 同时生成两个案例及 CSV、真值文件
cases <- run_simulation_examples(out = "simulation_examples", fit_batch = FALSE)
# 加上两个 ACL 重复拟合，保存失败诊断
# run_simulation_examples(out = "simulation_examples", fit_batch = TRUE)
e <- new.env()
load("simulation_examples/flatfish/sim_rep4", envir = e)
str(e$sim.data)
```

## 2. 明确死亡率、变异和时间单位

`simulate_example_data()` 的 `mean_F` 是生成年度 F 序列的算术平均值。完整模拟器的 `F_mean` 则是 `F[t] = F_mean * exp(d[t])` 中的过程基准水平；加入随机偏差后，通常不等于实际序列的算术平均值。`F_sd` 是对数 F 的 AR(1) 创新标准差，平稳相关为 `F_ar` 时，边际标准差为 `F_sd / sqrt(1 - F_ar^2)`，不同于拟合模型采用的边际对数 F 标准差。`q_surv_L50` 和 `q_surv_L95` 定义调查可捕性曲线，是调查输入，不是捕捞选择性的估计结果。

完整模拟器的 `nyear`、`burn_in` 都以年为单位，且分别必须对应整数个 `growth_step`。因此季度模式允许半年预热，年度模式不允许。返回的 `sm$nyear` 是保留时间步数；`first.year` 是第一期保留观测的年份，`sm$years` 保存完整观测时间轴。`simulation_to_tables()` 与批量拟合函数保留这条时间轴；完全没有年份元数据的旧文件仍可使用从 2000 开始的后备规则。只保留一期时仍返回矩阵，但拟合至少需要两期。

```r
quick <- simulate_example_data(years = 2000:2019, mean_F = 0.3, seed = 42)
stopifnot(isTRUE(all.equal(mean(quick$true_params$F_trend), 0.3)))
zero_F <- simulate_example_data(years = 2000:2019, mean_F = 0, seed = 42)
stopifnot(all(zero_F$true_params$F_trend == 0))
pa <- initialize_params(species = "flatfish", nyear = 5, burn_in = 2,
                        first.year = 2024)
sm <- sim_data(sim_cal(pa), pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_224")
stopifnot(identical(as.numeric(sm$years), as.numeric(2024:2026)))
source("scripts/simulation_workflow.R", encoding = "UTF-8")
inputs <- simulation_to_tables(sm, pa)
```

## 3. 检查生物输入与零值

`mat_func()` 使用稳定的 logistic 计算，陡峭上升曲线接近 1 时不会溢出。`L50` 与 `L95` 必须是不同的有限标量；仍允许下降曲线（`L95 < L50`），用于穹顶选择性。体长及派生生物矩阵必须有限，模拟的自然与捕捞死亡率必须非负。当 `M = 0` 且 `F_mean = 0` 时，渔获尾数和生物量为零；丰度和补充量仍按选定模拟模型演变。

```r
stopifnot(all(is.finite(mat_func(20, 20.1, c(20, 30, 50)))))
pa0 <- initialize_params(species = "flatfish", nyear = 4, burn_in = 2,
                         M = 0, F_mean = 0)
sm0 <- sim_data(sim_cal(pa0), pa0, iter_range = 4,
                output_dir = file.path(tempdir(), "alscl-zero-mortality"))
stopifnot(all(sm0$CN == 0), all(sm0$CB == 0))
```

### 体长分组与过程参数

快速模拟器把首尾体长组分别积分到负无穷和正无穷，与拟合模型一致。有限 `bin_breaks` 仍用于标签与中点，不截断概率。M、F 和噪声尺度必须非负，生长参数为正、重量系数非负，选择性及成熟曲线的 95% 端点高于 50% 端点。非法参数或非有限生成结果会在创建 CSV 前报错。完整模拟器还检查年龄—体长概率及生长转移概率的归一化。

完整模拟器要求 `init_Z`、过程与观测标准差、F 过程基准水平均为有限非负值。`F_ar` 与 `R_ar` 必须严格介于 -1 和 1 之间，允许负的平稳相关。Beverton–Holt 的 alpha 和初始补充量可以为零，beta 必须为正。非法过程输入会在随机抽样或创建文件前报错，保留已有模拟文件及调用者的随机数状态。

### 保留观测尺度与坐标

完整模拟保留零值和极小正调查观测。调查生物量等于调查尾数乘以重量，零资源情形也保持一致。拟合时，`zero_action = "missing"` 将零视为缺失，`"error"` 拒绝零值；全零调查没有正观测，不能使用当前对数正态模型拟合。

模拟体长中点必须落在对应组内，检查规则与拟合一致；首尾组仍吸收分布尾部。参数准备阶段会拒绝无效分组，生物量计算和模拟前还会再次检查，包括用户手动修改的输入；错误发生在随机抽样和写文件前。

## 4. 批量拟合并汇总表现

`sim_model(model = "acl")` 和 `sim_model(model = "alscl")` 可批量拟合重复文件；`sim_acl()` 和 `sim_alscl()` 提供模型专用入口，原来的 `sim_acl()` 写法保留。自行循环调用 `run_acl()` 或 `run_alscl()` 也是可选方式。生成器与拟合器的参数名不同，应使用对应模型的初值与 map，保留每次重复及其生成真值，并报告偏差、RMSE、区间覆盖率和失败率。匹配输入与汇总分母见[完整批量示例](assessment-workflows.html)。

`sim_model()`、`sim_acl()` 和 `sim_alscl()` 在发送 socket 任务前求值路径与参数变量，因此一般控制台或脚本中的变量传参也支持多核。保留失败重复并检查逐次拟合诊断；工作进程运行成功并不单独证明评估结果可用。

`sim_model()`、`sim_acl()` 和 `sim_alscl()` 将每次重复的结果（包括失败状态）保存到 `result_rep_<iter>`。复用输出目录时，本轮失败记录会替换旧成功结果；汇总前检查 `converge` 和 `error`。写入失败会明确报告，不能视为已经保存。`simulation_to_tables(sm, pa)` 使用模拟结果的长度坐标，并拒绝与参数不一致的坐标，不再给观测重新贴错标签；没有坐标的旧模拟可使用匹配的参数元数据。

## 复现已保存的实验

复现旧实验时，应保存原始输入、生成真值、种子和包的代码版本。2.2.4 对快速模拟器 `mean_F` 的修正、首尾组概率积分修正，以及 2.2.9 取消完整模拟器调查值的 `1e-6` 下限，都可能使相同种子重新生成不同观测。已保存的数据不会被改写。版本沿革见[更新日志](../news/index.html)。


## 直接从评估拟合生成模拟数据

`simulate_fit(fit, process = "conditional")` 在拟合状态下改变观测；`process = "resample"` 重新抽取拟合模型的补充、F 及初始状态偏差。两种模式均固定标量参数，保留可直接再拟合的输入列表与真值，与上面的操作模型模拟用途不同。完整步骤见[拟合模型模拟与预测验证案例](case-model-validation.md)。现有模拟批次也支持 `nstarts`，在每个重复内部依次运行；`ncores` 控制同时运行的重复数。
