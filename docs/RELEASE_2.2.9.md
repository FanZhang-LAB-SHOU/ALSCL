# ALSCL 2.2.9: plotting controls and reproducible simulation results

## Changes

- Honor global line widths, interval opacity, comparison line types and typography while preserving explicit function arguments. Keep all plot defaults free of grid lines; order ACL age panels numerically and implement PLA age-bin tick selection.
- Label log and original-scale survey indices distinctly. Normalize ridge compositions stably and support portable fits containing stored observations.
- Validate simulation-table length coordinates against recorded metadata. Persist failed simulation fits as current replicate results so reusing a directory cannot silently reuse an earlier success.
- Stabilize compiled-model catch calculations at very small total mortality. This addresses floating-point cancellation, without changing the biological model.
- Restore the live TMB objective after standard-error calculations; validate comparison observations, preserve zero/tiny simulated survey values and validate simulation bins. Extend the verified parallel TMB versions to 1.9.21 and 1.9.25, retaining the sequential fallback for other versions.
- Synchronize English and Simplified Chinese help, website, manual figures and Wiki. Clarify that species presets supply starts and bounds, and do not themselves fix parameters or replace biological fitting inputs.

Generic single-model line widths now inherit the global default of 1.5 when omitted. Explicit widths still win. CatL's two yearly curves retain distinct relative widths. Saved datasets and fitted results are not rewritten by the plotting updates; the manual uses saved teaching fits to isolate display changes. Removing the old simulation observation floor can change newly generated data that previously hit that floor. Stable catch arithmetic can differ at floating-point precision.

## Validation

Source and installed-package suites each passed **3,371 assertions**, with **0 failures, warnings or skips**. This adds 658 assertions to 2.2.8. `R CMD check --no-manual`, run with source references retained, finished with **Status: OK**.

Checks include serial and two-worker success-to-failure reruns, legacy and recorded simulation coordinates, live-object restoration, strict sequential/parallel standard-error equivalence, both AD frameworks, tiny/zero and ordinary mortality, plot argument precedence, age ordering, tick-only selection and stable ridge normalization.

All **45 YTF tutorial plots**, **42 legacy help figures** and **2 own-data figures** were regenerated from saved teaching assessments without warnings. The export checks rejected all 12 deliberately gridded cases and preserved existing files. The bilingual website check passed for **140 pages**, **45 functions per language** and **544 R code blocks**. Website and Wiki sources were rebuilt; figure content hashes were refreshed.

The local run was on macOS with R 4.6.0 and TMB 1.9.21. Cross-platform checks run separately in GitHub Actions after pushing.

Tested source archive SHA256: `864534ea5974ca3458735eaf4986e04953eb59bdac532e3e09da77102b1a6e41`.

## 简体中文

本版统一全局绘图参数、年龄排序、热图刻度和调查指数尺度标签；模拟转换核对长度坐标，批量拟合保存本轮失败状态，避免旧成功文件混入新一轮汇总。默认仍为无网格绘图，函数显式参数优先。

核心渔获计算在极小死亡率下采用稳定表达式；标准误结束后恢复 TMB 最优状态，补全观测匹配与模拟分箱验证。中英文网站、函数参考、配图与 Wiki 同步更新。物种预设仅给出初值与边界，固定参数仍需明确设置 map。

源码与安装包均通过 3,371 项断言，无失败、警告或跳过；包检查状态为 OK。已重生成教程和旧帮助配图，网站双语、链接、参数与代码块检查通过。
