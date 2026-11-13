# ALSCL documentation website

English is the default at `https://fanzhang-lab-shou.github.io/ALSCL/`; Simplified Chinese uses `/zh/`. Every page links to its translated counterpart. Section IDs are stable across languages. The visual layout follows the familiar pkgdown documentation pattern used by the sdmTMB website; this is a small static generator, not a pkgdown build.

## Build and preview

Run from the repository root with Python 3.10+ and R:

```sh
python3 -m venv .venv-docs
.venv-docs/bin/python -m pip install -r website/requirements.txt
Rscript -e 'install.packages("jsonlite", repos="https://cloud.r-project.org")'
.venv-docs/bin/python website/build.py
.venv-docs/bin/python website/check.py
python3 -m http.server 8765 --directory _site
```

Committed figures and tables must come from the code of this checkout. The figure scripts `scripts/ytf_workflow.R` and `scripts/refresh_manual_figures.R` source `scripts/checkout_guard.R`, which loads the checkout with `pkgload::load_all()`, so no installation is needed. Without pkgload, or when an ALSCL namespace is already loaded, the guard compares the loaded package with the checkout (every function, the TMB templates, the bundled data and the version number) and stops when they differ. A version comparison cannot do this, because an installation built from an earlier commit keeps the same version number. `Rscript scripts/test_checkout_guard.R` checks the guard without fitting models, and `scripts/test_plot_exports.R` runs it. `scripts/case_studies.R` and `scripts/simulation_workflow.R` apply the same check when they write into `docs/`, and `scripts/benchmark_parallel.R` applies it to the installed package that it times. To install the checkout, build it in a clean folder and install that one file, for example `R CMD build . && R CMD INSTALL ALSCL_$(sed -n 's/^Version: //p' DESCRIPTION).tar.gz`; a pattern such as `ALSCL_*.tar.gz` would also install older tarballs left in the folder.

`ytf_workflow.R` saves its fits to `output/ytf-guide/fits.rds`. `refresh_manual_figures.R` reads that file and `output/own-data-example/assessment_summary.rds` (written by `scripts/fit_own_data_example.R`) by default; `output/` is not under version control, so run those two scripts first on a fresh clone. `fit_own_data_example.R` is a tutorial script and attaches whichever ALSCL is installed. Before its output is used for committed figures, load the checkout first (`pkgload::load_all()`, then `source("scripts/fit_own_data_example.R", encoding = "UTF-8")`) or install the checkout.

`main` carries a development version: the fourth component of `Version` in `DESCRIPTION` is 9000 (for example 2.4.3.9000 after release 2.4.3). The site, the manuals and the Wiki print this version, while `README.md` keeps "Latest release" at the released version. `check.py` derives the release from the first three components and checks both. For a release, set `Version` to the new number, give the changes in `NEWS.md` and in `content/{en,zh}/news.md` a heading for that version, update the version strings that `check.py` reports, and set the version back to a `.9000` development version in the first commit after the tag.

After editing a tutorial pair, regenerate the manuals, book and Wiki:

```sh
python3 scripts/build_manual.py
python3 scripts/build_wiki.py
python3 scripts/test_manual_builder.py
Rscript scripts/test_plot_exports.R
```

The export check executes the maintained plotting tutorials, creates their teaching fits when no cache is supplied, and writes example exports to a temporary directory. It checks all returned panels for visible gridlines. Use the equivalent virtual-environment Python path on Windows. The build installs no ALSCL package and does not fit models. KaTeX 0.16.22 is downloaded from the npm registry with a pinned SHA-256 and copied, with its MIT license and fonts, into the generated site. The published site requires no external fonts, analytics, translation service or JavaScript CDN. Search and mathematics work from the bundled files.

## Content sources

- `content/en/` and `content/zh/`: the tutorials, homepage and news, written in both languages with the same block structure. They are the only source of the tutorials: `scripts/build_manual.py` generates the bilingual manuals in `docs/` (USER_GUIDE.md, ASSESSMENT_WORKFLOWS.md, MODEL_VALIDATION.md, CASE_STUDIES.md, PLOT_STYLE.md, SPEED_GUIDE.md, ADVANCED_WORKFLOWS.md, CASES.md) from the article pairs, and `scripts/build_wiki.py` then builds the book and the Wiki from those manuals.
- `articles.json`: matching routes and titles; keep both languages together when adding a chapter. `source` names the Wiki chapter generated from an article and is used to rewrite Wiki links. The "View source" link of a page opens the article file in `content/`, which is the file to edit; every generated manual, Wiki chapter and the book starts with a comment that names its sources.
- `article-groups.json`: bilingual basic-function categories for homepage Contents and summaries. Each article belongs to exactly one category.
- `cases.json`: problem-oriented case studies grouped in the Articles dropdown and index; separate from basic function guides.
- `reference-notes.json`: reviewed bilingual purposes, return values, interpretation notes and related articles for all public functions.
- `docs/FUNCTION_REFERENCE.md`: bilingual argument descriptions and function examples.
- `R/` and `NAMESPACE`: authoritative exported-function signatures and default expressions. `export_reference.R` parses function definitions without running package code.
- `man/`: R help details for English references.
- `docs/figures/` and `docs/data/`: existing figures and downloadable input data; the original directories are preserved.
- `man/figures/`: figures under former file names, kept in the repository for old links. No help page uses them, and `.Rbuildignore` leaves them out of the built package.
- `assets/site.css`, `assets/site.js`: layout, responsive navigation, search, copy buttons, formula rendering and language switching.

When changing a public API, update its descriptions in the reference Markdown and editorial notes. The build fails if documented argument names and actual formals disagree. For a new or removed exported function, update these sources: its section and index line in `docs/FUNCTION_REFERENCE.md` (anchor, usage block, argument table, return value and example), its entry in `reference-notes.json`, the `GROUPS` table in `build.py` (and `example_setup()` there when the example needs no fitted model), and the function counts in the first lines of `docs/FUNCTION_REFERENCE.md`, in `README.md` and in `README.zh-CN.md`; a new plotting function also changes the count in the first line of `docs/PLOT_GALLERY.md`. `check.py` prints the count it expects. Then rebuild the manuals, the Wiki and the site; `docs/BOOK.md` and `docs/wiki/` are generated and must not be edited by hand. Keep English and Chinese article structure aligned so same-section language switching remains meaningful. Existing figures illustrate synthetic datasets and conditional fits; do not relabel them as new or empirical results.

Keep the basic-guide order in `articles.json` aligned with the homepage groups:
first fit, own data, fitting choices, diagnostics, plots, simulation and reproducibility.
Introduce the objects a page needs before its first code block, state which output to
inspect, and place optional technical detail after the corresponding operation.
Worked cases remain under Articles. When reorganizing a page, retain its existing
section IDs and use matching explicit IDs for new English and Chinese sections.
Small screens have a collapsible table of contents; reference examples display
their preparation code by default.

## Writing rules for tutorials

Every tutorial is a task page. Write the English and Chinese versions together, with the same sequence of headings, paragraphs, lists, tables, code blocks and figures, because `scripts/build_manual.py` interleaves the two files block by block to produce the bilingual manuals, book and Wiki. The two files may differ in wording and in the number of comments or blank lines inside a code block. Executable code must match. The merger checks that the generated code is unchanged; a different block sequence fails the build.

Structure of a task page:

1. Title names the task ("Prepare your survey data"), not the topic.
2. First paragraph: what the reader will have at the end, and what they need before starting (objects, files, an earlier page).
3. Numbered steps. Each step has, in this order: what to run (one code block), why this step is needed, what the output should look like, and what to do when it does not. Introduce every object before its first use.
4. A closing table "What next" that names the following pages by task.
5. Reference detail (every argument, edge cases) belongs in the function reference and in the reference notes, not in the tutorial. Link to it.
6. Version history belongs in `NEWS.md` and the changelog page only. Do not write "since 2.2.3", "in 2.2.9" or "consistency corrections" in a tutorial.

Sentences:

- Say what the function does and what the reader should look at. Write "does not" only where a reader would otherwise draw a wrong conclusion, and say it once.
- Define a term where it first appears, then use the same term everywhere. Use the glossary below; do not invent new terms.
- Use plain verbs (run, read, compare, save). Avoid notably, crucially, robust, comprehensive, leverage, underscore.
- No em dashes or en dashes as punctuation; write a range as 2000-2019. Give numbers with two or three significant digits unless the exact value matters.
- Chinese pages use Chinese punctuation; English pages use English punctuation and contain no Chinese characters, including in code comments.

Glossary (one term per concept):

| Concept | English | Chinese |
|---|---|---|
| The named list holding the three tables and the settings, passed to `run_acl(x)` | input bundle `x` | 输入列表 `x` |
| The three tables | survey index table `data.CatL`, weight table `data.wgt`, maturity table `data.mat` | 调查指数表、体重表、成熟比例表 |
| One row of the tables | length bin | 体长组 |
| One column of the tables | time step (a year or a quarter; `growth_step` years) | 时间步 |
| Parameters estimated by the optimizer | scalar parameters | 标量参数 |
| Yearly random deviations of recruitment, F and initial numbers | process deviations | 过程偏差 |
| The TMB list that fixes or ties parameters | map | map |
| Independent optimizer starts (`nstarts`) | starts | 初值 |
| Checks of optimizer code, gradient, Hessian and bounds (`fit$diagnostics`) | numerical checks | 数值检查 |
| Removing the last time steps and refitting (`retro_model()`) | retrospective analysis; each refit is a peel | 回溯分析；每次截短为一轮 |
| Fitting on earlier time steps and predicting later ones (`hindcast_model()`) | hindcast validation | 预测检验 |
| Datasets generated from a fitted model (`simulate_fit()`) | fitted-model simulation | 从拟合模型模拟调查数据 |
| A fit saved without the live TMB object (`save_assessment()`) | saved fit | 保存的拟合结果 |
| Standard errors from `TMB::sdreport()` | standard errors | 标准误 |
| `B`, `SSB`, `Rec`, `N`, `F` | biomass, spawning biomass, recruitment, abundance, fishing mortality | 生物量、产卵生物量、补充量、丰度、捕捞死亡率 |

## Validation

`check.py` verifies every generated local link, asset, anchor and translation counterpart; public-function and argument coverage; English-language separation; and syntax of all displayed R blocks. It also checks explicitly named arguments to direct public-function calls, on the site and in the R blocks of the Markdown manuals, the book and the Wiki, and it reports a deprecated function name mentioned outside its own reference section. The documentation workflow also verifies that generated manuals and Wiki files are current, and runs `scripts/test_tutorial_workflows.R` to check the early package-version gate and the hindcast-only route with recording stubs. This is documentation validation, not a rerun of expensive model fits or a statistical validation of the models. The repository's R-CMD-check workflow remains the package check.

## GitHub Pages

In the repository's **Settings → Pages**, select **GitHub Actions** as the source. The Documentation workflow builds and checks pull requests, then deploys successful builds of `main`. A manual workflow dispatch is also available. No custom domain or paid hosting is required.

Generated output is `_site/`, excluded from Git and R package builds. Do not replace the existing `docs/` directory with generated HTML.

## Author icons and development status

`assets/orcid.svg` is the unmodified ORCID iD icon from https://orcid.org/assets/vectors/orcid.logo.icon.svg. ORCID and the iD logo are trademarks of ORCID, Inc.; the icon links to the named author's supplied record. See https://info.orcid.org/brand-guidelines/.

The homepage's Dev status section uses live GitHub Actions badges for the existing `R-CMD-check.yaml` and `documentation.yaml` workflows on `main`. Badge images are loaded from GitHub and may briefly lag the linked workflow logs because of caching.
