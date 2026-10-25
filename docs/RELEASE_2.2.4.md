# ALSCL 2.2.4: simulation and diagnostic workflow corrections

## Changes

- Socket batch fitting evaluates caller-supplied paths, parameters and controls before distributing tasks. Worker setup selects the intended R library before loading ALSCL. Ordinary global-script calls now use the same inputs as sequential calls.
- All comparison plots distinguish same-model configurations. Time-series, intervals and F plots retain each fit's own calendar; plots paired to survey observations validate known time and length metadata. Unknown parameter counts remain NA.
- Ridges, residuals and shared observation extraction preserve NA/zero masks using saved observations, with a legacy TMB-data fallback. Wholly unobserved periods stay empty. Partial observed compositions are normalized over available positives; predictions still cover all bins.
- SSB–recruitment plots convert age in years into a whole number of model steps. Annual calls retain their meaning; quarterly age 0.25 pairs adjacent quarters and age 1 pairs observations four quarters apart.
- The quick annual simulator realizes the requested arithmetic mean F and supports zero F. It rejects irregular or subannual labels. This correction changes newly simulated data at a given seed; bundled historical datasets and figures retain their original generating truth.
- Full simulators validate burn-in alignment and retain observation years and one-period matrix dimensions. The table converter and batch fitter preserve the calendar; the converter's explicit first_year override remains supported. Old files lacking all applicable year metadata retain the 2000 fallback.
- All-failed retrospectives requested with plot = TRUE return diagnostics and plot = NULL with warnings rather than discarding the failure record.
- The bilingual reference, articles, book and Wiki document these behaviors. Generated Wiki version labels now follow DESCRIPTION.

## Validation

Validated with R 4.6.0 and TMB 1.9.21 on macOS:

- 1,249 passing assertions in 99 test blocks; no failures, errors, warnings or skips. See [per-block results](results/regression-2.2.4.csv).
- A separate Rscript executes ordinary global-variable calls on one and two actual socket workers. Objectives, parameter vectors and SSB agree within 1e-10; distinct worker PIDs and the retained 1985–1989 calendar are verified.
- Tests retain the existing actual ACL/ALSCL fits, both F structures, multistart/retrospective worker comparisons, and fork/socket standard-error agreement for CppAD and TMBad.
- Targeted checks cover mean/zero F, annual and quarterly burn-in, one-period outputs, absent legacy metadata, missing-observation plots, different comparison calendars and whole-step recruitment lags.
- `R CMD check --no-manual`: **Status: OK**.
- Documentation build/check passes: 140 pages, 45 functions per language and 506 parsed R code blocks; bilingual structure, local links, assets and argument coverage verified.
- Historical flatfish/tuna table reconstruction preserves both stored calendar labels and observation values. Actual saved F-structure results and a deliberately masked survey plot were rendered and visually checked.

The model likelihoods and within-fit acceleration settings are unchanged. These checks verify the tested workflows; they do not establish biological adequacy or parameter identifiability for a new assessment.

## Reproduce

```sh
R CMD INSTALL .
NOT_CRAN=true Rscript -e 'testthat::test_local(".", load_package="installed")'
R CMD build .
NOT_CRAN=true R CMD check --no-manual ALSCL_2.2.4.tar.gz
python3 scripts/build_wiki.py
python3 website/build.py
python3 website/check.py
```

Install website/requirements.txt in a Python virtual environment first. Fitting tests require an R-compatible C++ toolchain. Set ALSCL_TEST_CACHE to reuse a writable TMB compilation cache.

## 简体中文

本版修正批次并行的变量传参、同模型比较图例和时间轴、缺测绘图、季度 SSB–补充量配对、模拟平均 F 与观测年份，以及全部回溯失败时的诊断返回。原拟合入口、F 结构和加速设置继续保留。快速模拟器生成的新数据会因 F 修正而改变；已有内附数据和历史配图不冒充本版重新生成的结果。

本地完整测试共 1,249 项断言、99 个测试块，全部通过，无警告或跳过。独立 R 脚本验证普通变量传参的真实双工作进程，结果与顺序计算一致；R CMD check 为 OK；网站 140 页、每语言 45 个函数及 506 个 R 代码块通过检查。
