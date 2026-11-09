<p align="right"><a href="README.md">English</a> | <strong>简体中文</strong></p>

# ALSCL <img src="ALSCLlogo.png" align="right" height="140" alt="ALSCL 标志" />

> 利用调查体长数据做资源评估的年龄结构模型与年龄-体长联合结构模型

<!-- badges: start -->
[![R-CMD-check](https://github.com/FanZhang-LAB-SHOU/ALSCL/actions/workflows/R-CMD-check.yaml/badge.svg?branch=main)](https://github.com/FanZhang-LAB-SHOU/ALSCL/actions/workflows/R-CMD-check.yaml)
[![Documentation](https://github.com/FanZhang-LAB-SHOU/ALSCL/actions/workflows/documentation.yaml/badge.svg?branch=main)](https://fanzhang-lab-shou.github.io/ALSCL/zh/)
[![Latest release](https://img.shields.io/github/v/release/FanZhang-LAB-SHOU/ALSCL?label=release&color=1f6feb)](https://github.com/FanZhang-LAB-SHOU/ALSCL/releases/latest)
[![License: GPL-3](https://img.shields.io/badge/license-GPL--3-blue.svg)](LICENSE.md)
[![Model paper](https://img.shields.io/badge/paper-Fish%20and%20Fisheries%202022-6f42c1.svg)](https://doi.org/10.1111/faf.12673)
<!-- badges: end -->

ALSCL 是一个 R 包，利用渔业独立调查的体长数据做资源评估。它拟合两个用 [TMB](https://github.com/kaskr/adcomp) 编写的种群模型：年龄结构 catch-at-length 模型 **ACL**，以及 [Zhang 和 Cadigan（2022）](https://doi.org/10.1111/faf.12673) 提出的年龄与体长联合结构统计 catch-at-length 模型 **ALSCL**。两个模型都不需要年龄数据，适合没有年龄数据或年龄鉴定不可靠的种群，例如南极磷虾。

围绕这两个模型，软件包提供数据准备与检查、多初值并行拟合、诊断、模型比较、回溯分析、敏感性情景、似然剖面、投影、从拟合模型模拟调查数据、预测检验、可移植的评估存档和 22 个绘图函数。

**最新版本：2.4.3** · [更新记录](NEWS.md) · [中文网站](https://fanzhang-lab-shou.github.io/ALSCL/zh/) · [Wiki](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [函数参考](docs/FUNCTION_REFERENCE.md) · [图谱](docs/PLOT_GALLERY.md)

## 能做什么

- **准备并检查数据。** 用 `read_survey_excel()` 或 `read_survey_csv()` 读入三张调查表，用 `prepare_alscl_data()` 把它们和生物学设置组成一个输入列表，再用 `check_alscl_data()` 和 `inspect_parameters()` 确认列表可以拟合、哪些参数将被估计。支持年度和季度时间步。
- **用同一组表拟合两种模型结构。** `run_acl()` 追踪年龄别尾数，并用年龄-体长概率矩阵转换为体长别尾数；`run_alscl()` 追踪体长与年龄别尾数，死亡率随体长变化，存活个体按生长转移矩阵推进。两者都可以用多个独立初值在并行进程上拟合（`nstarts`、`ncores`），并对最优初值做带检查的 Newton 收尾（`polish`）。
- **判断拟合。** `diagnose_model()` 报告收敛码、梯度、Hessian 和落在边界上的参数；`check_fit()` 增加残差热图、滞后相关和 QQ 图；`compare_models()` 按 AIC、BIC 和拟合统计量比较同一数据的两次拟合。
- **检验评估结果。** 带 Mohn's rho 的回溯分析（`retro_model()`）、敏感性情景（`fit_scenarios()`）、似然剖面（`profile_model()`）、确定性投影（`project_model()`）、从拟合模型模拟调查数据（`simulate_fit()`）和对留出时间步的预测检验（`hindcast_model()`）。
- **保存并分享结果。** `save_assessment()` 把拟合连同完整设置一起保存，`read_assessment()` 和 `refit_model()` 读回并重新拟合，`extract_estimates()` 返回带标准误的估计值。
- **用同一组参数画所有图。** 22 个绘图函数共用参数名和一个主题 `acl_theme_set()`，提供五种色板。[图谱](docs/PLOT_GALLERY.md)展示全部 44 张示例图及其代码。

## 安装

```r
install.packages("remotes")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL")          # 开发版（main 分支）
remotes::install_github("FanZhang-LAB-SHOU/ALSCL@v2.4.3")   # 指定版本
```

ALSCL 需要 R 4.1 或更高版本，以及与 R 匹配的 C++ 编译器：Windows 装 Rtools，macOS 装 Xcode Command Line Tools，Linux 装 C++ 编译器和 make。每个 R 会话第一次拟合某个模型时会编译它；设置 `options(ALSCL.tmb.cache = "~/ALSCL-cache")` 可以在会话之间保留编译结果。详见[安装 ALSCL 并完成第一次拟合](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/getting-started.html)。

## 快速开始

```r
library(ALSCL)
data("YTF_example")               # 内置模拟数据：三张表加设置
x <- YTF_example
a <- run_acl(x, silent = TRUE)    # 年龄结构模型
b <- run_alscl(x, silent = TRUE)  # 年龄与体长联合结构模型
diagnose_model(x$data.CatL, a)    # 读估计值之前先看数值检查
extract_estimates(a)              # 带标准误的估计值
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
save_assessment(a, "ytf_acl.rds")
```

![ACL 与 ALSCL 的生物量、产卵生物量和补充量](docs/figures/ytf/compare_ts.png)

`YTF_example` 是带有已知模拟真值的模拟数据集，用于教学，不是论文中的实测数据。要拟合自己的调查数据，先读[准备调查数据](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/data-preparation.html)。

<p align="center">
  <a href="docs/PLOT_GALLERY.md"><img src="docs/figures/ytf/CatL_length_TRUE.png" width="32%" alt="按体长组的调查指数拟合值与观测值"></a>
  <a href="docs/PLOT_GALLERY.md"><img src="docs/figures/ytf/residuals_year.png" width="32%" alt="按年份的对数残差"></a>
  <a href="docs/PLOT_GALLERY.md"><img src="docs/figures/ytf/ridges.png" width="32%" alt="各年份观测与拟合的体长组成"></a>
</p>

按体长组的调查拟合、按年份的残差，以及各年份观测与拟合的体长组成，是[图谱](docs/PLOT_GALLERY.md)中的三张图。

## 两种模型，同一种输入

| | ACL | ALSCL |
|---|---|---|
| 种群状态 | 年龄 × 时间的尾数 | 体长 × 年龄 × 时间的尾数 |
| 体长与生长 | 年龄-体长概率矩阵 | 补充和初始状态用概率矩阵，存活个体按生长转移矩阵推进 |
| 捕捞死亡率 | 按年龄估计 | 按体长估计，年龄别 F 由模型推导 |
| 拟合函数 | `run_acl()` | `run_alscl()` |

两个模型读取相同的三张表，按年或按季度：体长别调查尾数、体长别平均体重和体长别成熟比例。自然死亡率和调查可捕性作为设置给出。[Excel 填表示例](docs/data/ALSCL_Data_Entry_Example.xlsx)展示了表格格式。

## 文档

从哪里开始：

1. [安装 ALSCL 并完成第一次拟合](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/getting-started.html)：安装软件包，拟合内置示例并检查结果。
2. [准备调查数据](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/data-preparation.html)：排好三张表，选择生物学设置，查看将被估计的参数。
3. [模型能重现观测并预测留出时间步吗？](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/case-model-validation.html)：模拟与预测检验。

每一页先说明目的，再给出要运行的代码、应看到的结果和出错时的处理。

| 入口 | 内容 |
|---|---|
| **[中文网站](https://fanzhang-lab-shou.github.io/ALSCL/zh/)** · **[English website](https://fanzhang-lab-shou.github.io/ALSCL/)** | 安装、第一次拟合、数据准备、拟合设置、诊断、绘图、模拟、复现，六个工作案例，以及 65 个函数的参考 |
| [Wiki](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [单页书稿](docs/BOOK.md) | 同一内容的中英对照版本，18 章 |
| [使用指南](docs/USER_GUIDE.md) | 从安装到回溯分析的双语手册 |
| [评估工作流](docs/ASSESSMENT_WORKFLOWS.md) · [模型验证](docs/MODEL_VALIDATION.md) · [工作案例](docs/CASES.md) | 结果提取与存档、敏感性、剖面、投影、模拟、预测检验 |
| [函数参考](docs/FUNCTION_REFERENCE.md) · [图谱](docs/PLOT_GALLERY.md) | 全部参数与默认值；44 张示例图及其代码 |
| [加速指南](docs/SPEED_GUIDE.md) | 用 `alscl_speed()` 在并行进程上计算标准误，以及 TMBad 选项 |

## 获取帮助

通过 [GitHub Issues](https://github.com/FanZhang-LAB-SHOU/ALSCL/issues) 报告问题，请附最小可复现示例、包版本、输入维度和 `sessionInfo()` 输出。常见问题见[复现结果与排除故障](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/reproducibility.html)。

## 引用

请引用模型论文，并用 `citation("ALSCL")` 引用软件包：

Zhang, F. and Cadigan, N. G. (2022). An age- and length-structured statistical catch-at-length model for hard-to-age fisheries stocks. *Fish and Fisheries*, 23(5), 1121-1135. [doi:10.1111/faf.12673](https://doi.org/10.1111/faf.12673)

南极磷虾应用，考察同一队列内随体长变化的生长和死亡率如何影响评估结果：

Dong, S., Zhang, F. and Zhu, G. (2025). Length-dependent growth and mortality within each cohort cannot be ignored in stock assessment: a case study of Antarctic krill *Euphausia superba*. *Marine Ecology Progress Series*, 769, 1-22. [doi:10.3354/meps14923](https://doi.org/10.3354/meps14923)

<details>
<summary>BibTeX</summary>

```bibtex
@article{zhang2022age,
  title={An age-and length-structured statistical catch-at-length model for hard-to-age fisheries stocks},
  author={Zhang, Fan and Cadigan, Noel G},
  journal={Fish and Fisheries}, volume={23}, number={5},
  pages={1121--1135}, year={2022}, doi={10.1111/faf.12673}
}

@article{dong2025length,
  title={Length-dependent growth and mortality within each cohort cannot be ignored in stock assessment: a case study of Antarctic krill Euphausia superba},
  author={Dong, Sisong and Zhang, Fan and Zhu, Guoping},
  journal={Marine Ecology Progress Series}, volume={769},
  pages={1--22}, year={2025}, doi={10.3354/meps14923}
}
```

</details>

## 作者

ALSCL 由上海海洋大学[海洋渔业生态系统实验室](https://github.com/FanZhang-LAB-SHOU)开发，作者为 Hongyu Lin（[ORCID 0000-0001-6226-179X](https://orcid.org/0000-0001-6226-179X)）、Fan Zhang（[ORCID 0000-0003-0214-1790](https://orcid.org/0000-0003-0214-1790)）和 Sisong Dong。报告分析时请记录包版本（`packageVersion("ALSCL")`）和 Git 提交号。

## 许可

[GPL-3](LICENSE.md)
