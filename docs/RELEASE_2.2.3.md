# ALSCL 2.2.3: assessment workflow validation

## Changes

- Both fitting functions check time-column spacing against the model step. Missing survey periods must remain as NA columns, with weights and maturity supplied on the full grid.
- Model comparisons verify observation values, included cells, length labels and periods. Failed numerical screens or missing comparability metadata retain raw statistics but cannot produce an automatic preference. An unavailable parameter count is not treated as zero.
- Retrospective wrappers accept the same input bundle as fitting functions and preserve legacy positional calls. Explicit settings, including NULL, override stored settings. Peel workers and within-fit starts remain separate.
- Full-fit and per-peel diagnostics, errors and raw estimates remain inspectable. A failed required numerical screen or undefined endpoint makes the corresponding authoritative Mohn's rho unavailable; failed peels are never silently dropped.
- Comparison plots share missing-observation handling with diagnostic_metrics. ALSCL length-mode F plots use numerical length midpoints and year facets. The ACL legacy length alias remains available with a warning.

## Local validation

Validated on macOS with R 4.6.0 and TMB 1.9.21:

- 938 passing assertions in 82 test blocks; zero failures, errors, warnings or skipped blocks. See [per-block results](results/regression-2.2.3.csv).
- The suite exercises real ACL/ALSCL fits with model-default maps and t0-only maps, both F structures, quarterly inputs and missing observations. These small fixtures deliberately retain weakly informed variance/correlation parameters; tests require their boundary diagnostics instead of claiming all fits are suitable for inference.
- Sequential and socket retrospective results agree, including requested worker counts 1, 2 and 4. Six additional actual full/peel fits passed their numerical screens in the focused retrospective check.
- Parallel standard-error tests execute for both CppAD and TMBad, including fork/socket agreement and failure fallbacks. The model likelihoods and acceleration defaults are unchanged.
- `R CMD check --no-manual`: **Status: OK**.
- Documentation build/check: 140 pages, 45 functions per language, 492 parsed R blocks; bilingual sections, local links, images, arguments and examples checked.
- The ALSCL length-mode gallery figure was regenerated from YTF_example using the updated package and visually checked. Its fit had raw code 0, maximum gradient 5.75e-9 and a positive-definite Hessian.

These checks establish regression behavior on the tested inputs, not general identifiability, global optimality or biological adequacy. The public three-platform workflow provides the separate Windows, Linux and macOS release checks.

## Reproduce

```sh
R CMD INSTALL .
NOT_CRAN=true Rscript -e 'pkgload::load_all("."); testthat::test_dir("tests/testthat")'
R CMD build .
NOT_CRAN=true R CMD check --no-manual ALSCL_2.2.3.tar.gz
python3 scripts/build_wiki.py
python3 website/build.py
python3 website/check.py
```

Install the documentation dependencies from website/requirements.txt in a Python virtual environment first. A C++ compiler is required for TMB templates. To use the fast local regression cache, set ALSCL_TEST_CACHE to a writable directory.

## 简体中文

本版修正时间轴、模型比较、回溯诊断与参数转送，以及缺失值和体长别 F 绘图。`retro_acl(x, nyear = 3)` 和 `retro_alscl(x, nyear = 3)` 可沿用正式数据的 x，原有写法保留。

本地 938 项断言、82 个测试块全部通过，无失败、警告或跳过；R CMD check 为 OK。网站 140 页、每语言 45 个函数、492 个 R 代码块通过检查。新增测试包含真正的多参数拟合；短序列的边界问题会明确标记，不能把数值有限等同于可可靠推断。年度共用 F 继续为可选结构。
