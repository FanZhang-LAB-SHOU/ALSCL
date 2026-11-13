# 模型能重现观测并预测留出时间步吗？

本页从两个方面检验一个拟合好的模型。先从已拟合的模型模拟调查数据，再用这些数据重新拟合，比较估计值与生成数据时的已知值；预测检验用较早的时间步拟合，再把留出的后续时间步的预测与观测对照打分。你需要已安装的软件包（[安装 ALSCL](getting-started.html)）；代码使用模拟的 `YTF_example`。第 3、4 步要多次重新拟合模型，请为优化计算预留时间；实际耗时取决于电脑和拟合设置。只做预测检验时，运行第 1 步后直接到第 4 步。结束时你会有带真值的模拟数据集、偏差、RMSE 和区间覆盖率表、两个模型相对于朴素预测的预测评分，以及保存的拟合结果。

<h2 id="section-1">1. 读取输入列表</h2>

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
```

`x` 包含三张调查表和模型设置。只做预测检验时，直接到[第 4 步](#section-4)：它从 `x` 拟合各个训练窗口，不需要全数据拟合。需要模拟时，继续第 2 步。

<h2 id="section-2">2. 从拟合生成调查观测</h2>

<h3 id="source-fit">拟合用于模拟的源模型</h3>

```r
b <- run_alscl(x, silent = TRUE)
b$diagnostics
stopifnot(b$diagnostics$numerical_ok)
```

`b` 是模拟的起点 ALSCL 拟合。它的 `numerical_ok` 必须为 `TRUE`，因为除非 `allow_failed_fit = TRUE`，`simulate_fit()` 会拒绝未通过数值检查的拟合；若为 `FALSE`，先按[判断拟合是否可用](diagnostics.html)处理再模拟。教学示例通过 `map` 固定了生长和若干过程参数；用自己的输入列表时，选择有依据的生物学设置（[选择拟合设置](fitting-controls.html)）。每份模拟 `x` 都保留源拟合实际采用的固定标量值，包括由原始数据推得的 `mean_log_R`。要自行选择某个固定值，在拟合源模型时将它写入 `parameters`。

<h3 id="conditional-draws">保留拟合的种群状态</h3>

```r
conditional <- simulate_fit(b, nsim = 3, seed = 20261101,
  process = "conditional")
conditional$metadata
conditional$simulations[[1]]$observations[1:3, 1:3]
```

`process = "conditional"` 保持拟合的种群不变，只重新抽取观测误差，是查看同一状态下重复调查的最短路径。`metadata` 记录模型、过程、种子、原始观测掩码、源拟合的状态和假设 `parameter_uncertainty = "none"`。

<h3 id="process-draws">生成新的种群轨迹</h3>

```r
resampled <- simulate_fit(b, nsim = 3, seed = 20261101,
  process = "resample")
resampled$simulations[[1]]$truth$SSB
simulated_x <- resampled$simulations[[1]]$x
```

`process = "resample"` 还在拟合的标量参数值下重新抽取补充量、捕捞死亡率和初始丰度的过程偏差：补充量和 F 遵循拟合的平稳 AR(1) 过程（`F_structure = "year"` 时各组共用一条 F 时间序列，每个时间步有一个 F 值），初始尾数在对数尺度上加入独立正态扰动后逐龄递推。C++ 种群模型根据抽得的偏差计算新的种群状态。条件抽样使用源拟合的 `Elog_index`，过程重抽样则从新的过程状态重新计算 `Elog_index`。两种模式均按拟合的观测标准差添加对数尺度的观测误差，因此对应状态的 `exp(Elog_index)` 是观测中位数；标量参数、生物学设置和调查可捕性保持固定，因此两种模式都没有参数不确定性。`$simulations` 的每个元素包含 `observations`（体长组 × 时间步）、`truth`（种群量、标量参数和所用的偏差）和 `x`，后者是可交给 `run_alscl()` 的输入列表，保留 `b` 的拟合配置，但 `output`、`ncores` 和 `silent` 除外，由你在拟合时指定。原始调查的缺失和零值单元保持原样，除非 `preserve_missing = FALSE`；种子让抽样可以重复，结束后恢复调用者的随机数状态。固定或绑定过程偏差的 `map` 会使重抽模式终止，条件抽样仍可使用。若要用有自己补充量假设的操作模型，见[模拟调查数据](simulation.html)。

![给定状态或重新抽取过程后生成的 ALSCL 调查观测](../assets/manual/figures/workflows/fitted-simulation.png)

图中为三个体长组在两种模式下各三次抽样；虚线是拟合的对数中位数。条件抽样围绕相同的拟合状态散布，重抽过程的抽样还会移动轨迹。每条曲线是一次抽样，是生成分布的一个例子。

<h2 id="section-3">3. 重新拟合重复数据并与真值比较</h2>

```r
replicate_fits <- lapply(resampled$simulations, function(s) {
  tryCatch(run_alscl(s$x, nstarts = 2, ncores = 1, silent = TRUE),
    error = function(e) list(error = conditionMessage(e)))
})
truth <- lapply(resampled$simulations, function(s) s$truth)
performance <- summarize_simulations(replicate_fits, truth,
  quantities = c("SSB", "Rec"))
performance$replicates
performance$summary
```

每次重新拟合都是对模拟输入列表的普通拟合，这里用 `run_alscl(s$x)`，来自 ACL 拟合的抽样用 `run_acl(s$x)`，各用两个初值；`tryCatch()` 保留失败重复的报错信息，使它留在汇总中。`summarize_simulations()` 按重复名和年份把拟合与真值对齐，返回 `replicates`（每次拟合的数值检查、耗时和报错）和 `summary`（每个量的失败率、偏差、相对偏差、RMSE 和区间覆盖率及其分母）；偏差和 RMSE 使用通过检查的拟合，覆盖率只使用标准误有限的区间（[模拟调查数据](simulation.html#fit)解释了这些分母）。在记录运行中三次重新拟合都通过检查，60 对数值的覆盖率为产卵生物量 1.0、补充量 0.95（[simulation-performance.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/model-validation/simulation-performance.csv)）。`performance$replicates` 的 `elapsed` 列记录每次重新拟合的秒数。三个重复只演示流程；研究偏差或覆盖率需要足够多的重复，失败率才有意义，参数自助法还需要写明重新拟合的规程和区间构造方法，`simulate_fit()` 只提供生成数据这一步。磁盘上已有的重复数据可用 `sim_model()` 批量拟合（[模拟调查数据](simulation.html#fit)）。

<h2 id="section-4">4. 预测未参与拟合的时间步</h2>

```r
acl_validation <- hindcast_model(x, model = "acl", horizon = 1,
  nfolds = 2, min_train = 8, nstarts = 1, ncores = 2)
alscl_validation <- hindcast_model(x, model = "alscl", horizon = 1,
  nfolds = 2, min_train = 8, nstarts = 1, ncores = 2)
acl_validation$diagnostics
alscl_validation$diagnostics
acl_validation$scores
alscl_validation$scores
head(alscl_validation$predictions)
```

`hindcast_model()` 在每个预测起点重新拟合模型；预测起点是该次训练数据的最后一个时间步，模型用截至该期的数据拟合，再预测随后 `horizon` 步的调查指数。函数使用最后 `nfolds` 个合格起点，每次都从 `x` 和保存的配置重新拟合。本例中，每个模型先用截至 2017 年的数据预测 2018 年，再用截至 2018 年的数据预测 2019 年。

| 设置 | 在本年度示例中的含义 |
|---|---|
| `horizon = 1` | 向前预测一个时间步 |
| `nfolds = 2` | 使用最后两个合格的预测起点 |
| `min_train = 8` | 要求至少八个训练时间步 |
| `ncores = 2` | 最多并行运行两个训练折；一折内的初值依次运行 |

`horizon` 和 `min_train` 都按时间步计（季度数据就是季度）；每一折截短三张表和随时间变化的 map，固定或绑定过程偏差随时间变化的 `map` 会使调用终止。先读 `$diagnostics`：每折一行，含 `origin`、数值检查、`prediction_ok`、警告和报错；失败的折留在表中，但不产生预测和评分。`$predictions` 列出每个留出单元的观测、预测和朴素预测的对数指数，以及是否纳入的标志。

![留出的调查指数与模型预测及朴素预测](../assets/manual/figures/workflows/hindcast-predictions.png)

图中按三个体长组比较留出的对数调查指数和两种预测。朴素预测对每个体长组沿用训练期内最近一次大于零的调查观测值。模型预测先将补充量和 F 的末期对数偏差分别乘以各自 AR(1) 相关系数的预测步数次方，再按种群方程推进数量。各体长组的预测尾数乘以预先指定的调查可捕系数，得到这条种群轨迹下原尺度调查指数的条件中位数。计算生物量时沿用训练末期的体重和成熟比例。这些点预测固定参数，并将未来过程扰动设为零。请只用训练期资料选择固定值和初值，并对同一起点、预测期和观测比较模型。[朴素预测的定义](https://otexts.com/fppcn/toolbox.html)。

<h2 id="section-5">5. 读评分并保存分析</h2>

<h3 id="prediction-scores">把评分和样本数放在一起读</h3>

| 输出 | 读法 |
|---|---|
| `n_positive`、`n_prediction`、`n` | 正的留出观测数、其中有模型预测的数量，以及模型和朴素预测共同评分的单元数 |
| `log_RMSE`、`log_MAE` | 对数指数尺度上的预测误差；在这些单元上越小越好 |
| `naive_log_RMSE`、`naive_log_MAE` | 同一批单元上朴素预测的误差 |
| `log_MASE`、`naive_log_MASE`、`n_scaled` | 缩放后的绝对误差，以及训练期尺度可用的单元数 |

评分使用自然对数调查指数；留出观测中的零值和缺失值被排除，模型和朴素预测的误差使用相同的单元。MASE 把每个绝对对数误差除以该体长组训练期内相邻时间步的平均绝对对数指数变化，只使用两端观测均为正值的配对。保留原时间网格，不跨越零值或缺失时段配对。没有有效配对或缩放分母为零的体长组不计算缩放评分；解读前先查看 `n_scaled`。在记录运行中，两个模型对 2018-2019 年相同的 46 个正观测评分，四个训练拟合都通过检查（[hindcast-scores.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/model-validation/hindcast-scores.csv)）：

| 预测 | 评分观测数 | 对数 RMSE | 对数 MAE | 对数 MASE |
|---|---:|---:|---:|---:|
| ACL | 46 | 0.097 | 0.081 | 0.42 |
| ALSCL | 46 | 0.22 | 0.18 | 0.95 |
| 朴素预测 | 46 | 0.17 | 0.15 | 0.74 |

在这份模拟数据、教学 map 和两个起点下，ACL 的预测好于朴素预测，ALSCL 差于基准，尽管两者的优化都收敛了：这个差异值得追查，而两个检验时间步给不出模型的一般排序。

<h3 id="save-record">保存预测检验结果</h3>

```r
validation_file <- tempfile(fileext = ".rds")
saveRDS(list(acl = acl_validation, alscl = alscl_validation),
  validation_file)
```

预测检验结果是普通列表，`saveRDS()` 将两个模型的结果保存在一起。将临时路径换成永久文件即可。只做预测检验的操作到此完成。

<h3 id="simulation-archive">模拟后保存源拟合</h3>

若在第 2 步拟合了 `b`，运行下面的代码。只做了预测检验时，继续到[下一步](#next)。

```r
archive <- tempfile(fileext = ".rds")
save_assessment(b, archive)
saved <- read_assessment(archive)
saved$recipe$implementation
again <- simulate_fit(saved, nsim = 1, seed = 20261101,
  process = "conditional")
```

`save_assessment()` 保存拟合结果时去掉只在当前会话有效的 TMB 对象，`simulate_fit()` 接受 `read_assessment()` 读回的结果，所以新会话无需重新拟合即可模拟；相同种子给出相同抽样。`saved$recipe$implementation` 记录包版本、源码修订和模型源码哈希，`refit_model()` 会与当前安装比较，有差异就警告。把模拟对象和真值与这个拟合一起永久保存。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 检查源拟合的残差规律 | [判断拟合是否可用](diagnostics.html) |
| 看去掉近期时间步后估计如何变化 | [移除近期数据后，估计结果会怎样变化？](case-retrospective-bias.html) |
| 检验对固定值的敏感性 | [评估对假设有多敏感，未来 F 情景会怎样改变结果？](case-sensitivity-projection.html) |
| 批量拟合多次模拟重复 | [模拟调查数据](simulation.html#fit) |
| 重新生成本页的图和表 | 在仓库根目录运行 `pkgload::load_all("."); source("scripts/model_validation.R"); run_model_validation_guide()` |
