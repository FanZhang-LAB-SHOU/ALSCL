# 拟合模型能重现观测，并预测未参与拟合的时期吗？

本案例用两种互补方法检查模型：`simulate_fit()` 从已拟合的 ACL 或 ALSCL 生成观测；`hindcast_model()` 只拟合较早时期，再预测留出的后续调查指数。这些开发功能需要更新后的源码，2.2.9 发布标签不包含它们。

| 问题 | 函数与设计 | 含义 |
|---|---|---|
| 给定拟合种群状态，重复调查会是什么样？ | `simulate_fit(process = "conditional")` | 只改变观测误差，拟合状态保持不变。 |
| 拟合的过程与观测模型会生成什么数据？ | `simulate_fit(process = "resample")` | 重新抽取补充、F 和初始种群偏差；标量参数保持拟合值。 |
| 较早观测能否预测后续观测？ | `hindcast_model()` | 每次训练在验证期之前结束，对实际留出的指数评分。 |

## 1. 拟合并检查源评估结果

示例使用模拟的 `YTF_example` 数据。其教学 map 固定了部分生物学参数；正式评估应使用有依据的生物学输入和参数映射。数值检查通过表示优化结果可用于这些计算，不代表模型已充分描述真实种群。

使用本地开发源码时，请先在仓库根目录运行 `pkgload::load_all(".")`，再执行下文。若已安装包含这些函数的版本，可直接用 `library(ALSCL)`。

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
a <- run_acl(x, silent = TRUE)
b <- run_alscl(x, silent = TRUE)
stopifnot(a$diagnostics$numerical_ok, b$diagnostics$numerical_ok)
```

## 2. 从拟合模型模拟观测

```r
conditional <- simulate_fit(b, nsim = 3, seed = 20261101,
  process = "conditional")
resampled <- simulate_fit(b, nsim = 3, seed = 20261101,
  process = "resample")
conditional$metadata
resampled$simulations[[1]]$truth$SSB
simulated_x <- resampled$simulations[[1]]$x
# 两个模型均可直接读取各自模拟得到的输入列表。
simulated_fit <- run_alscl(simulated_x, nstarts = 2, ncores = 1,
  silent = TRUE)
simulated_fit$diagnostics
```

两种模式均使用拟合的对数正态观测模型：对数观测的均值为 `Elog_index`，标准差为拟合观测标准差。因此，`exp(Elog_index)` 是观测中位数。默认保留原始缺失和零值位置；设置 `preserve_missing = FALSE` 可生成完整的正值调查数据。显式提供种子可复现抽样，并在结束后恢复调用者的随机数状态。

`"resample"` 模式按拟合的平稳 AR(1) 分布生成补充偏差。F 使用可分离的组别／时间 AR(1) 场；`F_structure = "year"` 时使用单个时间过程。这些过程标准差是边际标准差，时间创新标准差等于边际标准差乘以 `sqrt(1 - phi^2)`。初始丰度偏差来自独立正态分布。已有 C++ 模型使用这些抽样计算种群状态，保留末龄加组及 ALSCL 生长转移。该模式不支持固定或绑定随机效应的 map，会明确报错；条件观测模拟仍可使用。

两种模式都固定标量参数，不包含参数估计不确定性。它们也不同于 `sim_data()` 生成的独立操作模型模拟，后者有自己的补充量假设。明确失败的源拟合默认被拒绝；`allow_failed_fit = TRUE` 可在警告后用于探索。

![给定状态或重新抽取过程后生成的 ALSCL 调查观测](../assets/manual/figures/workflows/fitted-simulation.png)

图中为若干体长组在两种模式下各生成的三条调查序列。参考线是原拟合的对数观测中位数。条件模拟围绕相同拟合状态变化，过程重抽样还改变种群轨迹。这些曲线是模拟实现，不是置信带。

## 3. 重新拟合重复数据，并与生成真值比较

每个重复保留输入列表与生成的种群真值。计算性能统计前，应保留失败拟合记录。

```r
replicate_fits <- lapply(resampled$simulations, function(s) {
  tryCatch(run_alscl(s$x, nstarts = 2, ncores = 1, silent = TRUE),
    error = function(e) list(error = conditionMessage(e)))
})
truth <- lapply(resampled$simulations, function(s) s$truth)
performance <- summarize_simulations(replicate_fits, truth,
  quantities = c("SSB", "Rec"))
performance$summary
```

三个重复用于演示接口，不足以确定偏差或区间覆盖率。正式实验应使用足够的重复，并报告失败拟合数及可用区间数。参数自助法还需要明确的重抽样设计、重新拟合协议及区间构造方法；`simulate_fit()` 提供生成步骤，不会自动计算自助法区间。

对于已有磁盘操作模型批次，`sim_model(..., nstarts = 3, ncores = 2)` 每个重复使用三个初值，最多同时运行两个重复。初值和标准误在每个工作进程内依次计算。`train_times` 控制每个初值的优化轮数，每个结果保留 `start_diagnostics`。

## 4. 预测未参与拟合的时期

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

`min_train` 是最少训练时期数，`horizon` 按模型时间步计数；季度数据的一步为一季度。使用最后 `nfolds` 个合格预测起点。每折截短三张输入表及支持的时间映射，从提供的拟合配置开始；不会拿完整序列的拟合估计作为初值。比较模型时，起点、预测期距和观测必须相同。生物学假设、固定参数及手动提供的初值也应在不参照留出数据调参的前提下确定。

未来对数补充量及对数 F 偏差沿训练末期出发的 AR(1) 条件均值路径延伸，再由种群方程推进丰度，并用给定调查可捕性转为指数。这是沿对数过程路径的代入式点预测，不是边际预测均值或预测分布；不抽取未来随机扰动或参数，也不提供预测区间。计算中沿用训练末期体重与成熟比例，不读取未来实际生物学资料。

固定或绑定随时间变化的补充／F 偏差的非恒等 map 会被拒绝，因为这些约束未定义当前支持的未来无约束 AR(1) 预测。失败或数值状态无法确认的训练拟合保留在诊断表中，不产生预测或参与评分。

![留出的调查指数与模型预测及持平基准](../assets/manual/figures/workflows/hindcast-predictions.png)

图中比较留出期的对数调查指数、模型预测及“沿用最近一次正训练观测”的基准。本例是模拟 YTF 数据上的方法演示，不证明任一模型普遍更好。

## 5. 解读评分并保留复现记录

评分使用自然对数调查指数，并报告分母。验证数据中的零值与缺失值按拟合约定排除。持平基准使用相同体长组最近一次正训练观测；与基准比较时，两种方法使用相同的合格观测。

对数尺度 MASE 将每个绝对预测误差除以该体长组训练期内相邻正观测的平均绝对对数差。缺失时期不会被压缩。尺度分母为零或不可用时，缩放评分记为 `NA`，不会记成零误差；请检查可用缩放观测数。短期验证上的较低分数不构成普遍排名。Mohn rho 和条件残差图回答其他问题，可与此检查配合使用。

实际执行本例时，两个模型使用相同的 2018–2019 年共 46 个正观测，四个训练拟合均通过数值检查；两次比较使用同一个持平基准。

| 预测方法 | 评分观测数 | 对数 RMSE | 对数 MAE | 对数 MASE |
|---|---:|---:|---:|---:|
| ACL | 46 | 0.0963 | 0.0802 | 0.4213 |
| ALSCL | 46 | 0.2583 | 0.1951 | 1.0655 |
| 持平基准 | 46 | 0.1722 | 0.1467 | 0.7356 |

在这份模拟数据、教学 map 和两个起点的设计下，ACL 优于持平基准，ALSCL 没有优于基准。即使两者优化均收敛，这个差异也值得研究。两个验证时期不能确立普遍排名。三组过程模拟数据的重新拟合也都通过数值检查，但三个重复不足以确定覆盖率。

```r
archive <- tempfile(fileext = ".rds")
save_assessment(b, archive)
saved <- read_assessment(archive)
saved$recipe$implementation
# 模拟不依赖序列化的活跃 TMB 指针。
again <- simulate_fit(saved, nsim = 1, seed = 20261101,
  process = "conditional")
```

评估配方保存可取得的源码提交、核心／R 源码摘要与运行环境。源码 HEAD 本身不能证明工作区没有修改。`refit_model()` 会提示已知实现或依赖变化，旧结果无法恢复的来源保持未知。请同时保存模拟元数据、真值和验证诊断，以便核对输入、排除位置及拟合协议。


从仓库根目录运行 `scripts/model_validation.R` 可重新生成这些图及 CSV 结果；绘图辅助程序在保存前逐面板检查网格线。

```r
pkgload::load_all(".")
source("scripts/model_validation.R")
run_model_validation_guide()
```
