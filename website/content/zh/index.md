> 利用调查体长数据的年龄结构与年龄—体长联合结构资源评估模型

**ALSCL** 是基于 [Template Model Builder（TMB）](https://github.com/kaskr/adcomp) 的 R 包，利用独立于渔业的调查体长数据拟合种群模型。包内提供年龄结构 catch-at-length 模型 **ACL**，以及年龄—体长联合结构统计 catch-at-length 模型 **ALSCL**（age- and length-structured statistical catch-at-length），并提供模拟、诊断、模型比较和绘图工具。

模型框架基于 [Zhang & Cadigan（2022）](https://doi.org/10.1111/faf.12673)。先选择下面适合自己的入口；首页目录列出基本使用方法，专题案例展示解决具体问题的完整过程。

<div class="reading-paths">
<p>你想从哪里开始？</p>
<ol>
<li><a href="articles/getting-started.html">第一次使用 ALSCL</a><br>安装软件包，拟合内置示例，再检查结果。</li>
<li><a href="articles/data-preparation.html">拟合自己的调查数据</a><br>准备三张对齐的表，选择生物学输入，并检查哪些参数会被估计。</li>
<li><a href="articles/case-model-validation.html">用模拟或未来观测检查模型</a><br>生成重复数据，或评估未参与拟合时期的预测表现。</li>
</ol>
</div>

<h2 id="contents">目录</h2>

- [安装](#installation)
- [两种模型结构](#models)
- [基本使用](#basic-use)
- [检查与解释拟合](#check-fit)
<!-- ARTICLE_CONTENTS -->
- [获取帮助](#help)
- [引用](#citation)

<h2 id="installation">安装</h2>

从 GitHub 安装 ALSCL <span class="current-version">{{VERSION}}</span>：

```r
install.packages("remotes")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL")
library(ALSCL)
```

拟合时会编译包内的 TMB 模型，因此需要与 R 匹配的 C++ 工具链。各操作系统的说明见 [安装与编译](articles/getting-started.html)。

网站对应 ALSCL 2.4.0；各版本变化见[更新记录](news/index.html)。

<h2 id="models">两种模型结构</h2>

| | ACL | ALSCL |
|---|---|---|
| 种群状态 | 年龄 × 时间的尾数 | 体长 × 年龄 × 时间的尾数 |
| 体长与生长表达 | 年龄—体长概率矩阵 | 补充和初始状态使用年龄—体长概率矩阵；存活个体通过生长转移矩阵推进 |
| 捕捞死亡率 | 按年龄估计 | 按体长估计；年龄别 F 由模型推导 |
| 拟合函数 | `run_acl()` | `run_alscl()` |

两种模型都使用三张对齐的输入表：调查体长别数量、体长别平均个体重量和体长别成熟比例。自然死亡率及调查可捕性设置由使用者提供。这些假设影响估计的尺度与解释，详见 [模型原理](articles/model-theory.html)。

<h2 id="basic-use">基本使用</h2>

内置 `YTF_example` 包含黄尾鲽风格的模拟数据、生物参数设置和已知模拟真值。它是教学数据，不是论文的实测样本。

```r
data("YTF_example")
x <- YTF_example
a <- run_acl(x, silent = TRUE)    # 年龄结构模型
b <- run_alscl(x, silent = TRUE)  # 年龄与体长联合结构模型
diagnose_model(x$data.CatL, a)    # 读任何估计值前先看数值检查
diagnose_model(x$data.CatL, b)
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
```

`run_acl(x)` 和 `run_alscl(x)` 读取同一个输入列表 `x`（三张表加设置），各自选择保存的配置。[理解第一次拟合](articles/first-model.html)逐步解释拟合结果、检查和估计值；[选择拟合设置](articles/fitting-controls.html)说明可以修改什么，[速度设置](articles/speed.html)说明如何使用多核。

![模拟 YTF 示例中 ACL 与 ALSCL 的生物量、产卵生物量和补充量估计](assets/manual/figures/ytf/compare_ts.png)

本示例固定了部分生物与过程参数，区间以这些设置为条件。[完整示例](articles/first-model.html) 解释输入、拟合结果与数据来源。

<h2 id="check-fit">检查与解释拟合</h2>

```r
diagnose_model(x$data.CatL, b)
plot_residuals(b, facet_by = "year")
comparison <- compare_models(a, b, x$data.CatL)
comparison$summary
```

先读数值检查（收敛码、梯度、Hessian、边界），再看残差规律，然后看对自然死亡率等固定值的敏感性。[判断拟合是否可用](articles/diagnostics.html)逐项说明这些检查，[模型比较图](articles/model-comparison.html)展示比较图形。

<h2 id="learn-more">基本功能</h2>

<!-- ARTICLE_GUIDE -->

<h2 id="help">获取帮助</h2>

通过 [GitHub Issues](https://github.com/FanZhang-LAB-SHOU/ALSCL/issues) 报告问题或提出功能需求。建议附上最小可复现示例、包版本、输入维度及 `sessionInfo()` 输出。常见数据和编译问题见 [故障处理](articles/reproducibility.html)。

<h2 id="citation">引用</h2>

Zhang, F. & Cadigan, N. G. (2022). An age- and length-structured statistical catch-at-length model for hard-to-age fisheries stocks. *Fish and Fisheries*, **23**(5), 1121–1135. [doi:10.1111/faf.12673](https://doi.org/10.1111/faf.12673)。

<h3 id="krill-paper">相关应用：南极磷虾</h3>

Dong, S., Zhang, F. & Zhu, G. (2025). Length-dependent growth and mortality within each cohort cannot be ignored in stock assessment: a case study of Antarctic krill *Euphausia superba*. *Marine Ecology Progress Series*, **769**, 1–22. [doi:10.3354/meps14923](https://doi.org/10.3354/meps14923).

该研究将 ACL 与 ALSCL 应用于南极磷虾，考察同一队列内体长相关的生长和死亡率差异如何影响资源评估结果。

报告分析时，也应记录 ALSCL 版本、代码提交号、数据来源与拟合假设。
