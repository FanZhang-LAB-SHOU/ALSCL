# ALSCL 2.2.7: input and plotting consistency

## Changes

- Explicit finite outer `len_lower`/`len_upper` endpoints are rejected with instructions to use open endpoints or `NULL`. First/last bins retain the existing distribution-tail convention; existing finite interval labels remain supported. Default prepared model data are unchanged.
- Abundance plots use matrix positions and fitted metadata for age/length groups and calendar time. Matrix dimnames cannot become numeric indices or silently reorder values.
- Abundance, recruitment and deviation intervals require a complete table of finite estimates and finite nonnegative standard errors. Single-period stored results retain matrix dimensions. Estimate-only deviations use the reported random-effect modes without `est_std`; legacy results can fall back to a valid `Estimate` column.
- Growth curves honor `ylab` without intervals, and preserve all supplied style settings when unavailable covariance triggers an estimate-only fallback.
- English and Simplified Chinese references, manual, website and Wiki explain these rules. All plots retain grid-free defaults. Model equations and optimization are unchanged.

## Validation

Local `R CMD check --no-manual` passed with **1,919 assertions**, no failures, warnings or skips (340 additional assertions). All 45 saved-YTF figures were rendered without warnings; the corrected 15-age figure and its help copy were refreshed. The bilingual website check passed for 140 pages and 544 R code blocks. The built source archive matches the final R code, tests and all 43 help images; local installation is 2.2.7.

Regression tests cover explicit finite/open bounds and pre-compilation rejection, named abundance matrices, missing/invalid/incomplete uncertainty, one-period outputs, shared/group-specific F, real ACL/ALSCL fits, legacy summaries, and preservation of growth-plot labels, breaks, themes and annotations.

The full package and manual export checks run on macOS, Linux and Windows. See the [R-CMD-check workflow](https://github.com/FanZhang-LAB-SHOU/ALSCL/actions/workflows/R-CMD-check.yaml) for the results associated with the release commit. The website checker verifies both languages, public arguments, local links, image versions and displayed R code.

## Reproduce

```sh
Rscript scripts/test_plot_exports.R
R CMD build .
NOT_CRAN=true R CMD check --no-manual ALSCL_2.2.7.tar.gz
python3 scripts/build_wiki.py
python3 website/build.py
python3 website/check.py
```

## 简体中文

2.2.7 明确拒绝不受支持的有限外体长边界，保留首尾组吸收尾部概率的模型约定。丰度图按矩阵位置和拟合元数据对齐；区间要求完整、有限、非负的标准误，偏差图不绘区间时可直接使用报告估计。生长图遵守自定义纵轴标签，并在缺协方差时保留字号、刻度、主题与标注。

回归测试覆盖四类问题及实际 ACL/ALSCL 拟合、两种 F 结构、单期结果、旧摘要表与异常输入。中英文说明书、网站、Wiki 和帮助页同步更新，保留默认无网格样式。模型方程与优化未改动。

本地完整包检查通过：1,919 项断言（新增 340 项），无失败、警告或跳过。45 张保存的 YTF 结果图重新导出无警告，年龄排序图与帮助副本已更新；140 页双语网站和 544 段 R 代码检查通过，本地安装为 2.2.7。
