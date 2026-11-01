## Laboratory / 實驗室

[Oceanic Fisheries Ecosystem Laboratory](https://github.com/FanZhang-LAB-SHOU),
Shanghai Ocean University.

# ALSCL <img src="ALSCLlogo.png" align="right" height="140" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/FanZhang-LAB-SHOU/ALSCL/actions/workflows/R-CMD-check.yaml/badge.svg?branch=main)](https://github.com/FanZhang-LAB-SHOU/ALSCL/actions)
[![License: GPL-3](https://img.shields.io/badge/License-GPL--3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<!-- badges: end -->

**利用调查体长数据的年龄结构与年龄—体长联合结构资源评估模型**

**Age-structured and joint age-length stock assessment using survey length data**

ALSCL 是一个 R 包，用渔业独立调查的体长数据拟合两个种群模型：年龄结构 catch-at-length 模型 **ACL**，以及年龄与体长联合结构的统计 catch-at-length 模型 **ALSCL**（Zhang & Cadigan 2022）。模型用 TMB 编写；软件包提供数据准备与检查、拟合、诊断、模型比较、回溯分析、敏感性情景、参数剖面、投影、拟合模型模拟、预测检验、结果存档和 22 个绘图函数。

ALSCL is an R package that fits two population models to fishery-independent survey length data: the age-structured catch-at-length model **ACL** and the age- and length-structured statistical catch-at-length model **ALSCL** (Zhang & Cadigan 2022). The models are written in TMB. The package provides data preparation and checks, fitting, diagnostics, model comparison, retrospective analysis, sensitivity scenarios, likelihood profiles, projections, fitted-model simulation, hindcast validation, saved assessments and 22 plotting functions.

**Latest release: 2.4.0 · 简体中文 / English** · [Changes / 更新记录](NEWS.md)

## 文档 / Documentation

说明按任务组织：每一页先说明目的，再给出要运行的代码、应看到的结果和出错时的处理。

The documentation is organized by task: each page states its purpose, the code to run, what to expect and what to do when it fails.

| 入口 / Entry | 内容 / Contents |
|---|---|
| **[在线文档（英文）/ Website, English](https://fanzhang-lab-shou.github.io/ALSCL/)** · **[简体中文](https://fanzhang-lab-shou.github.io/ALSCL/zh/)** | 安装、第一次拟合、数据准备、拟合设置、诊断、绘图、模拟、复现，六个工作案例，65 个函数的参考 / Install, first fit, data preparation, fitting settings, diagnostics, plots, simulation, reproducibility, six worked cases and the reference of all 65 functions |
| [Wiki 双语手册 / Bilingual Wiki](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [单页书稿 / Single-page book](docs/BOOK.md) | 同一内容的中英对照版本，18 章 / The same content with both languages side by side, 18 chapters |
| [使用指南 / User guide](docs/USER_GUIDE.md) | 安装到回溯分析的双语手册 / The bilingual manual from installation to retrospectives |
| [评估工作流 / Assessment workflows](docs/ASSESSMENT_WORKFLOWS.md) · [模型验证 / Model validation](docs/MODEL_VALIDATION.md) · [工作案例 / Worked cases](docs/CASES.md) | 结果提取与存档、敏感性、剖面、投影、模拟、预测检验 / Result extraction and archives, sensitivity, profiles, projections, simulation, hindcast validation |
| [函数参考 / Function reference](docs/FUNCTION_REFERENCE.md) · [图谱 / Plot gallery](docs/PLOT_GALLERY.md) | 全部参数与默认值；44 张示例图及其代码 / Every argument and default; 44 figures with their code |
| [Excel 填表示例 / Example workbook](docs/data/ALSCL_Data_Entry_Example.xlsx) | 三张输入表的格式 / The layout of the three input tables |

## 安装 / Installation

```r
install.packages("remotes")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL")
```

第一次拟合会在本机编译模型，需要与 R 匹配的 C++ 编译器（Windows 装 Rtools，macOS 装 Xcode Command Line Tools，Linux 装 C++ 编译器和 make）。详见[安装并完成第一次拟合](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/getting-started.html)。

The first fit compiles the models on your computer and needs a C++ compiler that matches R (Rtools on Windows, the Xcode Command Line Tools on macOS, a C++ compiler and make on Linux). See [Install and run a first fit](https://fanzhang-lab-shou.github.io/ALSCL/articles/getting-started.html).

## 快速开始 / Quick start

```r
library(ALSCL)
data("YTF_example")              # 内置模拟数据 / bundled synthetic example
x <- YTF_example                 # 三张表加设置 / three tables plus settings
a <- run_acl(x, silent = TRUE)   # 年龄结构模型 / age-structured model
b <- run_alscl(x, silent = TRUE) # 年龄与体长联合结构模型 / age- and length-structured model
diagnose_model(x$data.CatL, a)   # 读估计值前先看数值检查 / numerical checks first
extract_estimates(a)             # SSB、补充量等估计值及标准误 / estimates with standard errors
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
save_assessment(a, "ytf_acl.rds")
```

![ACL 与 ALSCL 的生物量、产卵生物量和补充量 / ACL and ALSCL biomass, spawning biomass and recruitment](docs/figures/ytf/compare_ts.png)

| | ACL | ALSCL |
|---|---|---|
| 种群状态 / Population state | 年龄 × 时间的尾数 / Numbers by age and time | 体长 × 年龄 × 时间的尾数 / Numbers by length, age and time |
| 体长 / Length | 年龄—体长概率矩阵 / Age-length probability matrix | 补充和初始状态用概率矩阵，存活个体按生长转移矩阵推进 / Probability matrix for recruits and initial numbers; growth transition matrix for survivors |
| 捕捞死亡率 / Fishing mortality | 按年龄估计 / By age | 按体长估计，年龄别 F 由模型推导 / By length; F at age is derived |
| 拟合函数 / Fitting function | `run_acl()` | `run_alscl()` |

两个模型使用相同的三张输入表：体长别调查指数、体长别平均体重和体长别成熟比例。要拟合自己的数据，先读[准备调查数据](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/data-preparation.html)。

Both models read the same three input tables: survey index, mean weight and maturity at length. To fit your own data, start with [Prepare your survey data](https://fanzhang-lab-shou.github.io/ALSCL/articles/data-preparation.html).

## 获取帮助 / Getting help

通过 [GitHub Issues](https://github.com/FanZhang-LAB-SHOU/ALSCL/issues) 报告问题，请附最小可复现示例、包版本、输入维度和 `sessionInfo()` 输出。常见问题见[复现结果与排除故障](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/reproducibility.html)。

Report problems in the [GitHub issue tracker](https://github.com/FanZhang-LAB-SHOU/ALSCL/issues) with a small reproducible example, the package version, the input dimensions and the output of `sessionInfo()`. Common problems are covered in [Reproduce results and fix problems](https://fanzhang-lab-shou.github.io/ALSCL/articles/reproducibility.html).

## 引用 / Citation

Zhang, F. & Cadigan, N. G. (2022). An age- and length-structured statistical catch-at-length model for hard-to-age fisheries stocks. *Fish and Fisheries*, 23(5), 1121-1135. [doi:10.1111/faf.12673](https://doi.org/10.1111/faf.12673)

```bibtex
@article{zhang2022age,
  title={An age-and length-structured statistical catch-at-length model for hard-to-age fisheries stocks},
  author={Zhang, Fan and Cadigan, Noel G},
  journal={Fish and Fisheries}, volume={23}, number={5},
  pages={1121--1135}, year={2022}, doi={10.1111/faf.12673}
}
```

### 南极磷虾应用 / Antarctic krill application

Dong, S., Zhang, F. & Zhu, G. (2025). Length-dependent growth and mortality within each cohort cannot be ignored in stock assessment: a case study of Antarctic krill *Euphausia superba*. *Marine Ecology Progress Series*, 769, 1-22. [doi:10.3354/meps14923](https://doi.org/10.3354/meps14923)

该研究将 ACL 与 ALSCL 应用于南极磷虾，考察同一队列内体长相关的生长和死亡率差异如何影响资源评估结果。

This study applies ACL and ALSCL to Antarctic krill to examine how length-dependent growth and mortality within cohorts affect assessment results.

```bibtex
@article{dong2025length,
  title={Length-dependent growth and mortality within each cohort cannot be ignored in stock assessment: a case study of Antarctic krill Euphausia superba},
  author={Dong, Sisong and Zhang, Fan and Zhu, Guoping},
  journal={Marine Ecology Progress Series}, volume={769},
  pages={1--22}, year={2025}, doi={10.3354/meps14923}
}
```

```r
citation("ALSCL")      # 包引用 / package citation
packageVersion("ALSCL")
```

包作者 Hongyu Lin、Fan Zhang 和 Sisong Dong；报告分析时记录包版本和提交号。

Authors: Hongyu Lin, Fan Zhang and Sisong Dong. Record the package version and Git commit with every analysis.

ORCID: [Hongyu Lin, 0000-0001-6226-179X](https://orcid.org/0000-0001-6226-179X) · [Fan Zhang, 0000-0003-0214-1790](https://orcid.org/0000-0003-0214-1790).

## 许可 / License

[GPL-3](LICENSE.md). 问题反馈 / Issues: [GitHub Issues](https://github.com/FanZhang-LAB-SHOU/ALSCL/issues).
