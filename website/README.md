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

Figure scripts (`scripts/ytf_workflow.R`, `scripts/refresh_manual_figures.R`) load the installed package, so install this checkout first (`R CMD build . && R CMD INSTALL ALSCL_*.tar.gz`) before regenerating figures; they stop when an older installation is loaded.

After editing a tutorial pair, regenerate the manuals, book and Wiki:

```sh
python3 scripts/build_manual.py
python3 scripts/build_wiki.py
```

Use the equivalent virtual-environment Python path on Windows. The build installs no ALSCL package and does not fit models. KaTeX 0.16.22 is downloaded from the npm registry with a pinned SHA-256 and copied, with its MIT license and fonts, into the generated site. The published site requires no external fonts, analytics, translation service or JavaScript CDN. Search and mathematics work from the bundled files.

## Content sources

- `content/en/` and `content/zh/`: the tutorials, homepage and news, written in both languages with the same block structure. They are the only source of the tutorials: `scripts/build_manual.py` generates the bilingual manuals in `docs/` (USER_GUIDE.md, ASSESSMENT_WORKFLOWS.md, MODEL_VALIDATION.md, CASE_STUDIES.md, PLOT_STYLE.md, SPEED_GUIDE.md, ADVANCED_WORKFLOWS.md, CASES.md) from the article pairs, and `scripts/build_wiki.py` then builds the book and the Wiki from those manuals.
- `articles.json`: matching routes and titles; keep both languages together when adding a chapter.
- `article-groups.json`: bilingual basic-function categories for homepage Contents and summaries. Each article belongs to exactly one category.
- `cases.json`: problem-oriented case studies grouped in the Articles dropdown and index; separate from basic function guides.
- `reference-notes.json`: reviewed bilingual purposes, return values, interpretation notes and related articles for all public functions.
- `docs/FUNCTION_REFERENCE.md`: bilingual argument descriptions and function examples.
- `R/` and `NAMESPACE`: authoritative exported-function signatures and default expressions. `export_reference.R` parses function definitions without running package code.
- `man/`: R help details for English references.
- `docs/figures/` and `docs/data/`: existing figures and downloadable input data; the original directories are preserved.
- `assets/site.css`, `assets/site.js`: layout, responsive navigation, search, copy buttons, formula rendering and language switching.

When changing a public API, update its descriptions in the reference Markdown and editorial notes. The build fails if documented argument names and actual formals disagree. Keep English and Chinese article structure aligned so same-section language switching remains meaningful. Existing figures illustrate synthetic datasets and conditional fits; do not relabel them as new or empirical results.

Keep the basic-guide order in `articles.json` aligned with the homepage groups:
first fit, own data, fitting choices, diagnostics, plots, simulation and reproducibility.
Introduce the objects a page needs before its first code block, state which output to
inspect, and place optional technical detail after the corresponding operation.
Worked cases remain under Articles. When reorganizing a page, retain its existing
section IDs and use matching explicit IDs for new English and Chinese sections.
Small screens have a collapsible table of contents; reference examples display
their preparation code by default.

## Writing rules for tutorials

Every tutorial is a task page. Write the English and Chinese versions together, with the same sequence of headings, paragraphs, lists, tables, code blocks and figures, because `scripts/build_manual.py` interleaves the two files block by block to produce the bilingual manuals, book and Wiki. The two files may differ only in wording; a different block sequence fails the build.

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
| Datasets generated from a fitted model (`simulate_fit()`) | fitted-model simulation | 拟合模型模拟 |
| A fit saved without the live TMB object (`save_assessment()`) | saved fit | 保存的拟合结果 |
| Standard errors from `TMB::sdreport()` | standard errors | 标准误 |
| `B`, `SSB`, `Rec`, `N`, `F` | biomass, spawning biomass, recruitment, abundance, fishing mortality | 生物量、产卵生物量、补充量、丰度、捕捞死亡率 |

## Validation

`check.py` verifies every generated local link, asset, anchor and translation counterpart; public-function and argument coverage; English-language separation; and syntax of all displayed R blocks. It also checks explicitly named arguments to direct public-function calls. The documentation workflow also verifies that generated manuals and Wiki files are current, and runs `scripts/test_tutorial_workflows.R` to check the early package-version gate and the hindcast-only route with recording stubs. This is documentation validation, not a rerun of expensive model fits or a statistical validation of the models. The repository's R-CMD-check workflow remains the package check.

## GitHub Pages

In the repository's **Settings → Pages**, select **GitHub Actions** as the source. The Documentation workflow builds and checks pull requests, then deploys successful builds of `main`. A manual workflow dispatch is also available. No custom domain or paid hosting is required.

Generated output is `_site/`, excluded from Git and R package builds. Do not replace the existing `docs/` directory with generated HTML.

## Author icons and development status

`assets/orcid.svg` is the unmodified ORCID iD icon from https://orcid.org/assets/vectors/orcid.logo.icon.svg. ORCID and the iD logo are trademarks of ORCID, Inc.; the icon links to the named author's supplied record. See https://info.orcid.org/brand-guidelines/.

The homepage's Dev status section uses live GitHub Actions badges for the existing `R-CMD-check.yaml` and `documentation.yaml` workflows on `main`. Badge images are loaded from GitHub and may briefly lag the linked workflow logs because of caching.
