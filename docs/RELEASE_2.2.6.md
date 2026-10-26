# ALSCL 2.2.6: reliable grid-free exports

## Changes

- SSB, abundance, biomass, catch, deviation and fishing-mortality plots use a shared grid-free recovery theme if normal theme loading fails. Normal theme settings and explicit overrides are preserved.
- All manual ggplot exporters use the same checked save function, including the simulation cases and complete own-data example. Every drawn panel is checked, including nested patchwork panels; empty layout containers and spacers are ignored. A visible major or minor grid stops export before a file is written or replaced.
- The source release includes the refreshed help figures from the complete documentation-image update. The v2.2.5 tag and archive are retained unchanged. English and Simplified Chinese documentation, website and Wiki describe the new behavior.
- Model likelihoods, optimization, acceleration and estimates are unchanged in this release.

## Validation

- Eight new package assertions cover the six failure-recovery paths, preservation of explicit user themes, and normal configured themes.
- `scripts/test_plot_exports.R` successfully exports plain and nested grid-free plots, rejects 12 deliberately gridded plots across both axes and major/minor grids, and checks that rejecting an export preserves an existing image. This check also runs in all three CI platform jobs.
- The bilingual website check covers 140 pages, 45 functions per language and 534 displayed R code blocks. Image inventory checks cover 105 plot files, three worksheet illustrations and one logo.
- Full package checks run on macOS, Linux and Windows. See the [R-CMD-check workflow](https://github.com/FanZhang-LAB-SHOU/ALSCL/actions/workflows/R-CMD-check.yaml) for the results associated with this release commit.

## Reproduce

```sh
Rscript scripts/test_plot_exports.R
R CMD build .
NOT_CRAN=true R CMD check --no-manual ALSCL_2.2.6.tar.gz
python3 scripts/build_wiki.py
python3 website/build.py
python3 website/check.py
```

## 简体中文

2.2.6 修正六个绘图函数的异常回退主题，主题加载失败时仍不显示网格。说明书中的 ggplot 导出统一检查所有实际子图，含嵌套组合图；发现主、次网格时停止保存，并保留已有文件。正常主题设置及用户显式覆盖仍受支持。正式下载包包含此前更新的帮助图片，旧版标签与下载包不改写。

新增八项包内断言，并用独立导出测试验证正常图片、嵌套图片、12 种故意加入网格的图片及拒绝覆盖行为。该导出测试接入三个平台的自动检查。中英文网站、说明书及 Wiki 同步更新；模型似然、优化、加速和估计结果均未改动。
