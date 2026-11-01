# 用内置 YTF 数据完成首个拟合

**完成[安装](getting-started.html)后，从本页开始。** 依次读取输入列表、拟合 ACL、检查结果，再与 ALSCL 比较。请在同一个 R 会话中运行；代码会创建后续教程使用的 `x`、`inputs`、`a` 和 `b`。

示例为 **23 个体长组、20 个年度的模拟数据**。教学配置固定了部分生物和过程参数，所得区间以这些设置为条件。先用它熟悉流程，再为自己的种群选择有依据的假设。

<h2 id="section-1">1. 读取数据并拟合 ACL</h2>

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
inputs <- x[c("data.CatL", "data.wgt", "data.mat")]
str(inputs)
x$provenance

a <- run_acl(x, train_times = 2, silent = TRUE)
```

`x` 已包含三张输入表、共享生物设置和两个模型各自的配置。`run_acl(x)` 会自动选择 ACL 配置。这里的 `train_times = 2` 表示每个初值连续优化两轮，不是两个独立初值。

首次拟合会编译模型，因此可能更慢。运行结束后，`a` 保存 ACL 结果；先检查结果，再比较估计值或解释区间。

<h2 id="section-3">2. 检查拟合结果</h2>

```r
a$diagnostics
diagnose_model(x$data.CatL, a)
plot_residuals(a, type = "year")
```

一起查看优化状态、最大梯度、Hessian 和参数边界，再看残差是否有系统性变化。若数值检查未通过，先按[诊断指南](diagnostics.html)排查，再使用估计量和区间。数值检查通过也不等于模型已经充分描述观测。

结果中最常用的部分是：

| 字段 | 内容 |
|---|---|
| `diagnostics` | 数值状态及需要排查的问题 |
| `report` | SSB、补充量等种群量及调查预测 |
| `opt` | 优化后的标量参数和目标函数值 |
| `est_std`、`vcov` | 近似标准误和协方差 |
| `sd_info` | 实际采用的标准误方法和核数 |
| `obj` | 当前 R 会话中的可执行 TMB 目标函数 |

```r
names(a$report)
a$sd_info
```

<h2 id="compare-models">3. 拟合 ALSCL，并比较两个模型</h2>

ALSCL 也使用同一个 `x`。函数选择对应的 ALSCL 配置，保留相同的观测和共享生物输入。

```r
b <- run_alscl(x, train_times = 2, silent = TRUE)
b$diagnostics
diagnose_model(x$data.CatL, b)
plot_residuals(b, type = "year")

plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
```

![ACL 与 ALSCL 的生物量、产卵生物量和补充量估计](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true)

各面板展示总生物量、产卵生物量和补充量，以及在各自固定假设下的近似区间。应一起比较诊断和轨迹，不能只凭这张图给模型排名。在相同观测集合上开展比较的方法见[模型比较](model-comparison.html)。

<h2 id="next-step">4. 选择下一步</h2>

| 想完成的任务 | 接着阅读 |
|---|---|
| 将教学数据换成自己的观测 | [准备三张输入表](data-preparation.html) |
| 决定哪些参数固定、哪些估计 | [拟合设置与 map](fitting-controls.html) |
| 绘制某个种群量 | [调查与种群图](population-plots.html) |
| 保存结果、检查残差或测试敏感性 | [评估工作流](assessment-workflows.html) |
| 从拟合模型生成数据，或检验未来预测 | [模拟与预测验证](case-model-validation.html) |

<h2 id="section-2">输入列表、覆盖设置与旧写法</h2>

首个拟合使用上面的直接调用即可。本节用于修改设置或整理已有脚本。

结构化 `x` 的读取顺序为：三张数据表、共享的 `x$fit_args`、所选模型的 `x$fit_config$acl` 或 `x$fit_config$alscl`，最后应用调用时显式传入的参数。例如 `run_acl(x, M = 0.25, nstarts = 4, ncores = 2)` 修改 M，并用最多两个工作进程运行四个独立初值。0.25 仅用于说明覆盖写法，不是对自己种群的推荐值。

列表参数（`parameters`、`map`、`control`）会整体替换已有列表，显式 `NULL` 也会保留。`x$parameters` 中的模拟设置和 `x$truth` 中的生成真值不会被当作拟合参数。修改 map 前请先看[拟合设置](fitting-controls.html)。

自己的数据也可放入扁平命名列表，包含 `data.CatL`、`data.wgt`、`data.mat`、`rec.age`、`nage`、`M`、`sel_L50`、`sel_L95` 及可选拟合参数。结构化输入可省略 `fit_config`，使用模型默认设置；若包含 `fit_config`，则必须包含所选模型。重名、未命名、未知参数或缺少必需参数都会在拟合前报错。

所有写法共用相同拟合核心和 `alscl_speed()` 设置。`ncores` 控制独立初值的工作进程数，`alscl_speed()` 的 `sd_cores` 控制标准误计算。用 `a$sd_info` 或 `b$sd_info` 查看实际执行方式，具体选项见[速度设置](speed.html)。

原来的逐项传参和 `do.call()` 写法继续支持。整理旧脚本时，下面的表达式与 `run_acl(x, silent = TRUE)` 使用相同拟合设置；本教程不必再运行一次。

```r
old_args <- c(x[c("data.CatL", "data.wgt", "data.mat")],
              x$fit_args, x$fit_config$acl, list(silent = TRUE))
# 可选的旧接口示例：
# legacy_fit <- do.call(run_acl, old_args)
```

<h2 id="data-provenance">内置数据的来源与适用范围</h2>

| 对象 | 内容与用途 |
|---|---|
| `YTF` | 原有 26 项生物参数列表，不含调查表 |
| `YTF_example` | 23 个体长组 × 20 期；三张表、模拟参数、真值、拟合设置和来源 |
| `example_data` | 原 ALSCL 保留的 9 组 × 21 年三张表；来源未核实 |

`YTF_example` 复用 `YTF` 的共有参数，包括调查对数 SD = 0.1，其余采用 flatfish 预设。随机种子为 4，预热 80 年后保留 20 年。年份仅为示意，cm 和 kg 是教学单位约定，数据不是论文的实测样本。[数据生成脚本](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/data-raw/YTF_example.R)可重建对象，并恢复调用者的随机数状态。

`x$fit_config` 固定已知生长及部分过程／相关参数，区间不包含这些固定值的不确定性。本例不能证明同时估计全部参数时可识别。模型比较与回溯分析应保留原始设置。
