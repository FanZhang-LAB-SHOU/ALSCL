# 运行回溯分析

读完本页，你会得到每个模型的 Mohn rho（生物量、产卵生物量、补充量和丰度）、重拟合序列的图和每次重拟合的数值检查。你需要[理解第一次拟合](first-model.html)中的输入列表 `x` 和 ALSCL 拟合结果 `b`。

回溯分析从三张表中去掉最后一个时间步并重拟合模型，再去掉一个，再拟合，依此类推；每次截短重拟合称为一轮。把各轮与完整拟合比较，就能看出加入后来的观测后近期估计改变了多少；各轮修订方向一致时，应进一步调查这种系统性变化的原因。

<h2 id="run">1. 运行分析</h2>

```r
ra <- retro_acl(x, nyear = 3, silent = TRUE)
rb <- retro_alscl(x, nyear = 3, silent = TRUE)
```

`retro_acl()` 使用 ACL 模型，`retro_alscl()` 使用 ALSCL 模型。每次调用先用完整的数据表拟合模型，再运行 `nyear` 轮：第 1 轮去掉最后一个时间步并重拟合，第 2 轮去掉最后两个，依此类推。`nyear` 以时间步计数，季度数据一年有四个时间步。

每次拟合都使用输入列表中保存的设置，与 `run_acl(x)` 相同，初值个数为列表中显式保存的 `nstarts`，没有保存时为一个；调用时给出的参数会对每次拟合覆盖保存的值。`ncores` 让各轮在工作进程上运行；输入列表中保存的拟合用 `ncores` 会被忽略，一次拟合内部的多个初值依次运行。`silent = FALSE` 时控制台每次拟合打印一行。

有两种错误会在任何拟合开始之前终止调用：调查指数表的时间列必须带有递增的数字标签（[准备调查数据](data-preparation.html)），并且每一轮都必须至少保留两个时间步，所以 `nyear` 最多为时间步数减二。某一轮在优化器内部失败时会记录在下一步的表中，分析继续进行。

<h2 id="tables">2. 读返回的表</h2>

```r
rb$fit_diagnostics
rb$rho_by_peel
rb$rho_text
rb$raw_rho_text
rb$errors
```

返回值是一个由表组成的列表，`ra` 的元素与 `rb` 相同：

| 元素 | 每行对应 | 内容 |
|---|---|---|
| `fit_diagnostics` | 一次拟合 | `Peel`（0 是完整拟合）、`RetrospectiveYear`（保留的最后一个时间步）、`elapsed`、数值检查及其汇总 `numerical_ok` 和未通过的项目 `issues`，以及拟合中止时的错误信息 `error` |
| `rho_by_peel` | 一轮和一个量 | `RawRho`，该轮末端估计与完整拟合在该时间步估计的相对差；`Rho`，两次拟合都通过数值检查且参考值有限、非零时等于 `RawRho`，否则为 `NA`；`Valid` |
| `rho_text` | 一个量 | Mohn rho，即各轮 `Rho` 的平均值，附 `Valid`、`ValidPeels` 和 `RequestedPeels`；`Year` 只是标签位置 |
| `raw_rho_text` | 一个量 | 不经检查的 `RawRho` 平均值，仅供诊断；任一比较缺失时为 `NA` |
| `errors` | 一次失败的拟合 | `Peel`、`RetrospectiveYear` 和错误信息；所有拟合都运行完成时为零行 |

这些量是总生物量 `B`、补充量 `Rec`、产卵生物量 `SSB` 和丰度 `N`；完整序列在 `rb$results` 中。当完整拟合或任一轮未通过数值检查，或某个末端比较缺失时，`rho_text$Rho` 为 `NA` 并发出警告，以便报告的均值只使用两次拟合均通过数值检查的比较。请在 `fit_diagnostics$issues` 和 `errors` 中找到失败的拟合，按[判断拟合是否可用](diagnostics.html)修复它并重新运行；`raw_rho_text` 只用来看可用差值的大小。

<h2 id="plot">3. 绘制重拟合序列</h2>

```r
plot_retro(rb, facet_ncol = 2, rho_digits = 3)
```

![示例的 ALSCL 回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true)

`plot_retro()` 直接绘制保存的序列，无需重拟合，每个量一个面板，`facet_ncol = 2` 把它们排成两列。每条线是一次拟合，颜色按它的最后一个时间步区分（图例「Retrospective Year」）：完整拟合止于 2019 年，各轮止于 2018、2017 和 2016 年。空心点标出每次拟合的末端估计，也就是 rho 与完整拟合比较的那个值；面板标签给出保留 `rho_digits` 位小数的 Mohn rho。本页的图另加了 `rho_size = 3`、`point_size = 1` 和 `line_size = 0.6`。

![示例的 ACL 回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ACL.png?raw=true)

两张图中，截短拟合与完整拟合之间较明显的差异集中在序列末期。其他时间步的修订幅度可通过保存的估计值计算。rho 为 `NA` 时，面板显示 `rho unavailable: check diagnostics`；若没有任何拟合给出估计值，`plot_retro()` 会停止并提示读 `fit_diagnostics` 和 `errors`。标题、标签、字号和各次拟合的颜色（`palette`、`colors`）见 [ggsci 配色与导出](plot-customization.html)；全部参数见 [plot_retro 参考](../reference/plot_retro.html)。

`plot` 和 `silent` 都必须是单个 `TRUE` 或 `FALSE`，无效值会在任何拟合开始前报错。如果没有一行同时包含有限时间和有限估计值，`plot_retro()` 会停止并提示检查诊断；存在有效估计时，序列内部的缺失值继续保留为断点，不跨缺失处连接。

<h2 id="rho">4. 解释 Mohn rho</h2>

Mohn rho 把每一轮的末端估计与完整拟合在同一时间步的估计之间的相对差，对各轮取平均：

```math
\rho=\frac{1}{K}\sum_{k=1}^{K}\frac{\hat\theta^{(-k)}_{T-k}-\hat\theta^{(0)}_{T-k}}{\hat\theta^{(0)}_{T-k}}.
```

`K` 是 `nyear`，`T` 是完整拟合的最后一个时间步；第 `k` 轮止于 `T-k`。ρ 为 +0.03 表示截短拟合的末期估计平均比完整拟合对同一期的估计高 3%。ρ 为负表示平均偏低。符号相反的项会抵消，所以也要读 `rho_by_peel`；完整拟合的估计为零时该项没有定义。Mohn rho 衡量的是加入后来的观测后末端估计被修订的程度；预测准确度由[预测检验](case-model-validation.html)来回答。按评估量分别报告修订的方向和幅度。

<h2 id="adapt">5. 用于自己的评估</h2>

```r
rb2 <- retro_alscl(x, nyear = 3, nstarts = 2, ncores = 3, silent = TRUE)
rb2$fit_diagnostics
```

用你报告的那次拟合的设置运行分析，这样各轮之间的差异只来自去掉的观测。调用中的参数会传给每次拟合：`nstarts = 2` 让每次拟合运行两个初值并保留目标函数值较低的那个，`ncores = 3` 同时拟合三轮（工作进程最多 `nyear` 个），`map`、`parameters` 或 `control` 参数会整体替换保存的列表（[选择拟合设置](fitting-controls.html)）。对自己的输入列表有四条规则：

- `dev_log_R` 和 `dev_log_F`（补充量和捕捞死亡率的过程偏差）的 map 必须覆盖完整数据表的全部时间步，先排一个时间步的所有组再排下一个（`F_structure = "year"` 时只有一组）；每一轮保留它所保留的时间步及其固定值和绑定关系，长度不符的 map 会终止分析。
- 使用与主拟合相同的 F 结构：保存的 `F_structure` 会被使用，调用中显式给出的则作用于每次拟合。
- 最短的一轮至少保留两个观测时间步，序列较短时要保留更多，因为较短的一轮要用更少的观测估计同样多的参数。
- 按时间步而不是按年计数：季度数据中 `nyear = 4` 去掉一年，`RetrospectiveYear` 显示保留的最后一个时间步。

<h2 id="record">6. 记录结果</h2>

```r
save_assessment(b, "ytf_alscl.rds")
saveRDS(rb, "ytf_alscl_retro.rds")
plot_retro(readRDS("ytf_alscl_retro.rds"), facet_ncol = 2, rho_digits = 3)
```

回溯结果只包含表，没有只在当前会话有效的 TMB 对象，所以 `saveRDS()` 能完整保存它，`plot_retro()` 能在新会话中绘制重新读入的对象。`save_assessment()` 用于拟合结果：它将 `b` 连同重新拟合所需的输入和设置一起保存，供 `refit_model()` 使用；传入回溯结果时以 `A complete fit recipe is required` 停止。把这两个文件放在一起；[进阶、复现与故障处理](reproducibility.html)说明如何记录软件包版本和会话。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 完整做一遍案例 | [移除近期数据后，估计结果会怎样变化？](case-retrospective-bias.html) |
| 修复失败的一轮 | [判断拟合是否可用](diagnostics.html) |
| 更改 map、F 结构或初值 | [选择拟合设置](fitting-controls.html) |
| 检验对后来时间步的预测 | [模型验证](case-model-validation.html) |
| 用更多核心运行各轮 | [速度设置](speed.html) |
| 更改颜色和标签 | [ggsci 配色与导出](plot-customization.html) |
| 查阅全部参数 | [retro_model](../reference/retro_model.html)、[retro_acl](../reference/retro_acl.html)、[retro_alscl](../reference/retro_alscl.html)、[plot_retro](../reference/plot_retro.html) |
