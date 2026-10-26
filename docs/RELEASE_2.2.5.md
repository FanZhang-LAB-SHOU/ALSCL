# ALSCL 2.2.5: diagnostic, simulation and plotting reliability

## Changes

- Multistart fits, retrospective peels and simulation batches share a socket-worker initializer. It sets the parent session's library paths before loading ALSCL and verifies the loaded package path. Custom library installations no longer silently mix with a default installation on workers. Source references are removed from worker callbacks before serialization, including standard-error callbacks, so installations built with R_KEEP_PKG_SOURCE cannot preload another namespace.
- In-sample diagnostics validate known time labels, length-bin order, positive-observation masks and stored observations. Old objects without metadata retain raw metrics; model comparisons continue to withhold automatic preference when comparability cannot be verified.
- Comparison tables and diagnostic functions share metric arithmetic. Undefined R-squared for constant observations is NA. Nonfinite response-scale predictions at observed cells are errors; log residuals retain finite stored log predictions even when exponentiation underflows.
- Logistic maturity/selectivity remains finite for steep increasing and descending curves. Both simulators use a stable Baranov limit: F = M = 0 gives exactly zero catch. Invalid biological arrays or nonfinite simulated outputs fail before saving a replicate.
- Length-specific biomass and spawning biomass plots draw existing ALSCL standard errors when se = TRUE. Unavailable model outputs or intervals produce clear errors. The bilingual support table distinguishes ACL estimates-only outputs from ALSCL interval support; no C++ model outputs were added.
- All 22 plotting functions use grid-free panels by default. Major/minor grids can still be explicitly restored with a ggplot2 theme override. Axes, colour defaults and other public plotting arguments remain available.
- Current homepage installation versions are generated from DESCRIPTION and checked during the website build. R help examples use real fitting functions. English and Simplified Chinese guides, reference pages, book and Wiki document the corrected behavior.

The model likelihoods, fitted parameterizations, direct run_acl(x)/run_alscl(x) calls, legacy argument calls and acceleration defaults remain unchanged. Normal preset simulations differ from 2.2.4 only at floating-point precision in the independent checks (less than 7e-16 after normalization); extreme inputs now receive defined results or clear errors.

## Validation

Validated locally with R 4.6.0 and TMB 1.9.21 on macOS, with R_KEEP_PKG_SOURCE=yes:

- **1,571 passing assertions in 116 test blocks**, with no failures, errors, warnings or skips. This includes 322 added assertions. See [per-block results](results/regression-2.2.5.csv).
- Real socket integration tests load ALSCL from a separate installation path, run two multistart and two retrospective workers, verify distinct process IDs and loaded package paths, and compare with sequential results within 1e-10. Explicit retained-source references reproduce the CI serialization boundary; forced socket standard errors match native TMB and their workers do not load ALSCL.
- Plot tests exercise the 36 model/type/interval combinations, check interval values and matrix order, and verify grid-free panels across all 22 public plotting functions and nine base themes. Explicit grid overrides are also tested.
- Simulation checks cover three presets, steep/descending logistic curves, zero and tiny mortality, invalid biological arrays and output overflow. Separate normal-input comparisons retain the existing simulated biology at floating-point precision.
- A second independent review checks the final changes with actual stored fits: data-order rejection, missing observations, legacy diagnostics, uncertainty extraction, unsupported plotting combinations, grid defaults and documentation contracts.
- The website validates 140 pages, 45 functions per language, bilingual structure, local links/assets and 534 R code blocks. A deliberate stale installation-version mutation is rejected by its checker.

- `R CMD check --no-manual`: **Status: OK**.
- Installed 2.2.5 in the local user library and verified both direct bundle calls against legacy calls in a fresh R session. Both numerical screens passed; each fixture recorded four forked standard-error workers and grid-free plots.

- Refit the bundled YTF teaching data, completed both retrospective examples, and rendered all **45 gallery figures** with no recorded warnings. The BL/SBL figures show the new intervals and all package plots use the grid-free defaults. Revised R help examples were built from the fitted teaching result.

These checks establish behavior in the tested configurations; they do not establish biological adequacy or parameter identifiability for an unseen stock assessment. Historical simulation datasets retain their original generating truth.

## Documentation figure follow-up

The complete asset inventory covers 105 plot files (including PNG/SVG variants and retained help-image filenames), three worksheet illustrations and one logo. Refresh legacy help figures, both simulation cases, the own-data figures and benchmark graphics as well as the YTF gallery. Gallery exports check every ggplot panel for blank major/minor grids. Worksheet cell borders and meaningful diagnostic/reference lines are retained. Website and Wiki figure URLs contain content hashes to prevent old cached images from appearing after an update; the website checker validates those hashes and inventory coverage.

图形补充修订覆盖 105 个绘图文件（含 PNG/SVG 和旧帮助图片文件名）、3 张表格示意图及 1 个标识。旧帮助图、模拟案例、正式数据示例、基准图与 YTF 图库均已补齐无网格样式；保留表格单元格边界及有意义的诊断参考线。网站及 Wiki 图片链接使用内容校验值，并由网站检查核对图片版本和清单，避免旧图缓存。

## Reproduce

```sh
R CMD INSTALL .
NOT_CRAN=true Rscript -e 'testthat::test_local(".", load_package="installed")'
R CMD build .
NOT_CRAN=true R CMD check --no-manual ALSCL_2.2.5.tar.gz
python3 scripts/build_wiki.py
python3 website/build.py
python3 website/check.py
Rscript scripts/ytf_workflow.R
```

Install website/requirements.txt in a Python virtual environment first. Fitting requires an R-compatible C++ toolchain. ALSCL_TEST_CACHE can point to a writable TMB compilation cache. The gallery command fits the bundled teaching data and writes figures and diagnostic tables.

## 简体中文

2.2.5 统一并行进程的安装库，核对诊断输入与原始拟合数据，共用比较指标，修正陡峭 logistic 和零死亡率模拟，补上体长别生物量及 SSB 的可用区间，并明确不支持的绘图组合。所有 22 个绘图函数默认没有主、次网格线；用户仍可显式恢复。中英文网站、函数参考、书稿与 Wiki 同步更新，首页安装版本由 DESCRIPTION 自动生成。

本地完整测试为 1,571 项断言、116 个测试块，包含 322 项新增断言，零失败、错误、警告或跳过。真实多进程测试核对安装路径、独立 PID 和顺序结果；完成修订后又独立复核了一遍。模型似然、旧写法、run_acl(x)/run_alscl(x) 和加速设置保留。
