# ALSCL 2.2.8: simulation, diagnostics and plotting consistency

## Changes

- Use the same open-tail age-length probabilities in the quick simulator and compiled ACL model. Validate simulator inputs, probability sums and derived outputs before saving. Full-simulator process parameters are checked before drawing random numbers or creating output files.
- Interpret data frames, matrices, tibbles and numeric-text factor columns consistently across fitting, diagnostics and comparison.
- Slice recruitment and fishing-mortality maps with each retrospective peel, preserving fixed entries and parameter ties for both models and F structures.
- Build survey and F plot coordinates from fitted metadata and matrix positions. Keep age panels numerically ordered with or without intervals. Reject incomplete, nonfinite or negative standard errors instead of recycling values or silently hiding intervals.
- Honor residual labels and title alignment, and require a positive residual cap. Preserve grid-free defaults and update affected manual figures.
- Default time-series comparisons to the five quantities with uncertainty in both models: SSB, recruitment, B, N and CN. Explicit CB requires both reports to contain it; neither current model reports CB standard errors. Use `plot_compare_annual_F()` to choose apical or unweighted mean F per model period; no aggregate-F interval is inferred.
- Load the same source checkout on development socket workers and test source and installed workflows in CI.

The fitting likelihood, C++ model equations and optimizer are unchanged. Correcting quick-simulator tail probabilities can change newly simulated observations even with an old seed; previously saved datasets retain their original generating truth. In the reviewed shifted-bin example, first-year first-bin abundance now agrees with the compiled key instead of differing by 22.07%.

## Validation

Local source-mode tests and the installed-package `R CMD check --no-manual` both passed **2,713 assertions**, with no failures, warnings or skips. This adds 794 assertions to 2.2.7. Package check status is **OK**. Tests cover actual ACL/ALSCL fits, both F structures, serial/socket retrospectives with mapped effects, compiled-key simulation comparisons, table classes, named/unnamed plotting matrices and invalid uncertainty.

All 45 saved-YTF tutorial plots rendered without warnings. Four age-panel figures and the affected help copy were refreshed; the other valid figures retained their content. The bilingual website check passed for 140 pages, 45 public functions per language and 544 R code blocks. Manual export tests rejected all 12 intentionally gridded cases while preserving existing files. The source archive was verified against the current R code, regression tests and help files.

Source archive SHA-256: `48703196002a14fe543b583ed71584d5118398e12e5a8374830a5c8c055b3ee7`.

## Reproduce

```sh
Rscript -e 'testthat::test_local(stop_on_failure=TRUE)'
Rscript scripts/test_plot_exports.R
R CMD build .
NOT_CRAN=true R CMD check --no-manual ALSCL_2.2.8.tar.gz
python3 scripts/build_wiki.py
python3 website/build.py
python3 website/check.py
```

The three-platform package workflow also installs the candidate and checks source-mode socket workers before the installed-package check. See [R-CMD-check](https://github.com/FanZhang-LAB-SHOU/ALSCL/actions/workflows/R-CMD-check.yaml) and [Documentation](https://github.com/FanZhang-LAB-SHOU/ALSCL/actions/workflows/documentation.yaml) for release-commit results.

## 简体中文

2.2.8 统一快速模拟与核心的首尾组概率，补齐完整模拟器的过程参数和概率守恒检查，保留零死亡率、零噪声及负的平稳 AR 系数。无效过程输入在随机抽样和创建文件前报错。

诊断与比较兼容拟合所接受的表格类型；回溯同步裁剪按时期设置的映射，保留固定项和共享关系。调查与 F 图使用矩阵位置和拟合元数据，年龄分面保持数值排序，区间验证完整性和标准误有效性。残差图遵守标签与对齐设置，截断值必须为正。所有默认图保持无网格。

默认时间序列比较使用两模型共有的五项输出；F 使用明确选择最大值或非加权均值的专用函数。源码模式并行和安装模式均纳入检查。拟合似然、C++ 模型方程和优化器不变；新生成的快速模拟数据可能因尾部修正而改变，原保存数据及其真值不改写。

本地源码测试和安装包检查均通过 2,713 项断言，比 2.2.7 新增 794 项，无失败、警告或跳过，包检查为 OK。45 张教程图重新导出无警告，4 张年龄排序图及对应帮助副本已刷新。140 页双语网站、每种语言 45 个公开函数及 544 段代码检查通过；导出保护测试拦截全部 12 个故意带网格的案例，并保留原文件。
