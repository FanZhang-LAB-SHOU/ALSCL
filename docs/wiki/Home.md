# ALSCL 完整使用手册 · Complete user manual

<img src="https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/ALSCLlogo.png?raw=true" alt="ALSCL logo" align="right" height="140" />

**调查体长数据的种群评估 · Survey catch-at-length stock assessment**

**ALSCL 2.2.9 · 简体中文与英文 · 17 章 / chapters**

本手册按主题整理模型原理、数据、拟合、诊断、绘图、模拟与预测验证。第一次使用可按下面的路线完成操作，再查阅需要的技术细节。说明随 main 开发源码更新；较早的 2.2.9 发布标签不包含全部新增接口。

This manual groups model principles, data, fitting, diagnostics, plotting, simulation and prediction checks by task. Follow a reading path below, then consult the technical sections you need. The manual follows main; the earlier 2.2.9 release tag does not contain every new interface.

[开始使用 · Getting started](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/01-Start) · [仓库主页 · Repository](https://github.com/FanZhang-LAB-SHOU/ALSCL/tree/main) · [单页书稿 · Single-page book](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/BOOK.md) · [Excel 示例 · Workbook](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx)

## 选择阅读路线 · Choose a reading path

| 你的任务 / Your task | 建议顺序 / Suggested order |
|---|---|
| 第一次使用 / First run | [安装 / Install](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/01-Start) → [内置拟合 / First fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/04-Built-in-YTF) → [诊断 / Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/07-Diagnostics) |
| 拟合自己的数据 / Your own data | [准备数据 / Prepare data](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/03-Data-and-Excel) → [参数与 map / Parameters and maps](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/06-Fitting) → [诊断 / Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/07-Diagnostics) |
| 整理和评估拟合结果 / Work with fitted results | [结果、敏感性与情景 / Results, sensitivity and scenarios](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/16-Assessment-Workflows) |
| 模拟或检验未来预测 / Simulation or prediction checks | [模型验证完整案例 / Model-validation case](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/17-Model-Validation) |
| 选择图形与导出 / Plot and export | [种群图 / Population plots](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/08-Population-Plots) → [配色和导出 / Style and export](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/13-Colors-and-Export) |

这些是按任务选择的入口，不必按章节编号从头读起。需要逐项查参数时使用第 14 章；想用单一语言连续阅读时，访问 [English website](https://fanzhang-lab-shou.github.io/ALSCL/) 或 [简体中文网站](https://fanzhang-lab-shou.github.io/ALSCL/zh/)。

Use these task-based entry points without reading every chapter in numerical order. Chapter 14 is an argument reference. The website provides continuous reading in either language.

## 目录 · Contents

| 章 / Chapter | 内容 / Contents |
|---|---|
| 01 | [开始使用 · Getting started](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/01-Start) |
| 02 | [模型原理与时间尺度 · Model principles](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/02-Theory) |
| 03 | [数据、Excel 与实测导入 · Data and observations](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/03-Data-and-Excel) |
| 04 | [内置数据与首个拟合 · Built-in YTF](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/04-Built-in-YTF) |
| 05 | [模拟与批量实验 · Simulation](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/05-Simulation) |
| 06 | [初值、边界与拟合 · Fitting controls](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/06-Fitting) |
| 07 | [诊断与结果解读 · Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/07-Diagnostics) |
| 08 | [调查与种群图 · Survey and population plots](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/08-Population-Plots) |
| 09 | [生长、死亡与残差图 · Growth, mortality and residuals](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/09-Growth-and-Mortality) |
| 10 | [模型比较与真值 · Model comparisons](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/10-Model-Comparisons) |
| 11 | [回溯分析 · Retrospectives](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/11-Retrospectives) |
| 12 | [年度与季度案例 · Annual and quarterly cases](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/12-Case-Studies) |
| 13 | [ggsci 配色与导出 · Colors and export](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/13-Colors-and-Export) |
| 14 | [全部函数与参数 · Complete function reference](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/14-Function-Reference) |
| 15 | [进阶、复现与故障处理 · Reproducibility](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/15-Reproducibility) |
| 16 | [评估工作流 · Assessment workflows](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/16-Assessment-Workflows) |
| 17 | [模型模拟与预测验证 · Model simulation and prediction checks](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/17-Model-Validation) |

## 相关链接 · Links

**张帆教授 · Prof. Fan Zhang**

- [个人主页 · Faculty homepage](https://hyxy.shou.edu.cn/2021/0721/c18717a291861/page.htm)
- [GitHub · fzhang-shou](https://github.com/fzhang-shou)
- 邮箱 · Email: [f-zhang@shou.edu.cn](mailto:f-zhang@shou.edu.cn)

**董思宋 · Sisong Dong**

- [GitHub · dongworks97](https://github.com/dongworks97)
- [南极磷虾评估论文 · Antarctic krill assessment (Dong, Zhang & Zhu, 2025)](https://doi.org/10.3354/meps14923)

理论来源 / Reference: Zhang & Cadigan (2022), *Fish and Fisheries* 23,1121–1135. [Paper and Appendix S1](https://doi.org/10.1111/faf.12673).
