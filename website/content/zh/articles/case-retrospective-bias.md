# 移除近期数据后，估计结果会怎样变化？

本页带你对模拟 YTF 示例运行 ACL 和 ALSCL 的回溯分析：每个模型在去掉最后 1、2、3 个时间步后重新拟合，每一轮与完整拟合比较，再用 Mohn's rho 汇总修订幅度。你需要已安装的软件包（[安装 ALSCL](getting-started.html)）；每次分析运行四次拟合，[运行回溯分析](retrospectives.html)解释了函数及其返回表。结束时你会有两个结果、它们的图和一个保存文件夹。

<h2 id="run">1. 运行 ALSCL 回溯分析</h2>

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
rb <- retro_alscl(x, nyear = 3, train_times = 2, silent = TRUE)
rb$fit_diagnostics
rb$rho_text
plot_retro(rb, facet_ncol = 2, rho_digits = 3)
```

`retro_alscl()` 像 `run_alscl(x)` 一样读取输入列表 `x`，先拟合完整序列，再做三轮：第 1 轮去掉最后一个时间步，第 2 轮去掉最后两个，第 3 轮去掉最后三个。`nyear` 以时间步计（季度数据就是季度），每一轮至少要保留两个。调用中的参数对每次拟合都生效，本次调用的 `ncores` 让各轮并行运行（[运行回溯分析](retrospectives.html#run)）。先读 `rb$fit_diagnostics`：每次拟合一行（`Peel` 为 0 是完整拟合），含数值检查和报错信息。只有完整拟合和所有轮次都通过检查、每个末端比较都有限且参考值非零时，`rb$rho_text$Rho` 才给出每个量的 Mohn's rho；否则为 `NA` 并警告，`rb$errors` 列出失败的拟合，`rb$raw_rho_text` 保留未经检查的均值供诊断。教学数据的四次拟合约需六分钟，全部通过（[retro_diagnostics_ALSCL.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/retro_diagnostics_ALSCL.csv)）。

![仓库提供的 ALSCL 回溯示例](../assets/manual/figures/ytf/retro_ALSCL.png)

每条线是一次拟合，按其最后一个时间步着色；空心点标出末端估计，rho 把它与完整拟合在同一时间步的值比较。像这里一样，各轮的线在大部分序列上与完整拟合重合、只在最后几年分开，说明图中较明显的修订集中在近期。在记录运行中，生物量的 rho 为 0.033，产卵生物量 0.017，丰度 0.027，补充量 0.0018（[rho_ALSCL.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/rho_ALSCL.csv)）；正值表示截短拟合的末期估计平均高于完整拟合对同一期的估计。符号相反的项在均值中会抵消，所以也要读 `rb$rho_by_peel`。若没有任何拟合给出估计，`plot_retro()` 会停止并提示你读 `fit_diagnostics` 和 `errors`。

<h2 id="acl">2. 运行 ACL 分析并比较两个模型</h2>

```r
ra <- retro_acl(x, nyear = 3, train_times = 2, silent = TRUE)
ra$fit_diagnostics
ra$rho_text
plot_retro(ra, facet_ncol = 2, rho_digits = 3)
```

![模拟 YTF：ACL 回溯轨迹](../assets/manual/figures/ytf/retro_ACL.png)

两个模型使用相同的观测和三轮截短拟合。对于生物量、产卵生物量和总丰度，ACL 的 Mohn’s ρ 绝对值较小，其 ρ 依次为 0.0069、0.0079 和 −0.00025。补充量的 ρ 在 ACL 中为 −0.0104，在 ALSCL 中为 +0.0018，平均修订方向相反，ACL 的绝对值较大。可在 `rho_by_peel` 中查看每一轮末期修订的方向和幅度。[ACL 结果](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/rho_ACL.csv) · [ALSCL 结果](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/rho_ALSCL.csv)。

<h2 id="save">3. 保存记录</h2>

```r
dir.create("my_retrospective", showWarnings = FALSE)
write.csv(rb$results, "my_retrospective/alscl_trajectories.csv", row.names = FALSE)
write.csv(rb$rho_text, "my_retrospective/alscl_rho.csv", row.names = FALSE)
write.csv(rb$fit_diagnostics, "my_retrospective/fit_diagnostics.csv", row.names = FALSE)
write.csv(rb$rho_by_peel, "my_retrospective/rho_by_peel.csv", row.names = FALSE)
write.csv(ra$rho_text, "my_retrospective/acl_rho.csv", row.names = FALSE)
p_retro <- plot_retro(rb, facet_ncol = 2, rho_digits = 3)
ggplot2::ggsave("my_retrospective/alscl.png", p_retro,
               width = 10, height = 7, dpi = 300)
saveRDS(list(ACL = ra, ALSCL = rb, fit_args = x$fit_args,
             fit_config = x$fit_config), "my_retrospective/results.rds")
writeLines(capture.output(sessionInfo()), "my_retrospective/session.txt")
```

结果是没有活动 TMB 对象的表，所以 `saveRDS()` 能完整保存，`plot_retro()` 在新会话中可以重画。文件夹记录每次拟合的序列、每个量和每一轮的 rho、数值检查、图、`x` 的设置和会话信息。对自己的评估，用你报告的那次拟合的设置运行分析，使各轮与完整拟合只差去掉的观测；季度数据用 `nyear = 4` 去掉一年。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 读每张返回表和 rho 的公式 | [运行回溯分析](retrospectives.html) |
| 修复未通过数值检查的一轮 | [判断拟合是否可用](diagnostics.html) |
| 给留出时间步的预测打分 | [模型能重现观测并预测留出时间步吗？](case-model-validation.html) |
| 用更多核心运行各轮 | [速度设置](speed.html) |
