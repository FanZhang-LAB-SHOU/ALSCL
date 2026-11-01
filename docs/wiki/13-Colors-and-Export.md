# 13 ggsci 配色与导出 · Colors and export

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/12-Case-Studies) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/14-Function-Reference)

**ALSCL 2.3.0 · 简体中文 / English**

先完成[使用指南](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md)中的内置 YTF 拟合，得到 `a`、`b` 和 `x`。下面先建立回溯结果 `rb`，再调整图形；回溯含义见指南第 9 节。

First complete the bundled YTF fit in the [user guide](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md) to create `a`, `b` and `x`. The following block creates the retrospective result `rb` before styling it; section 9 explains retrospectives.

默认使用 **ggsci NPG**。单模型估计用深蓝，观测用朱红；两模型比较按模型顺序使用深蓝、朱红；回溯按截止期从新到旧分配 NPG 原生颜色。设置在创建图时生效，已有图对象不会自动重绘。

The default is **ggsci NPG**: navy estimates, vermilion observations, and navy/vermilion model comparisons. Retrospective colors follow descending terminal periods. Settings affect newly created plots, not existing objects.

```r
# 建立回溯结果 / Create the retrospective result
rb <- retro_alscl(x, nyear = 3, train_times = 2, ncores = 1, silent = TRUE)

# 一次设置，随后重新创建图 / Set once, then recreate plots
acl_theme_set(palette = "npg", base_theme = "theme_bw", font_family = "sans")
plot_retro(rb, facet_col = 2, rho_digits = 3)
plot_compare_ts(a, b, se = TRUE)

# 可选期刊色板 / Alternative journal palettes
acl_theme_set(palette = "jama") # npg, aaas, nejm, lancet, jama
plot_abundance(b, type = "NL", facet_ncol = 3)

# 单图覆盖优先于全局设置 / Per-call overrides take precedence
plot_retro(rb, palette = "nejm", rho_position = "top_left")
plot_retro(rb, colors = c("2019" = "#3C5488", "2018" = "#E64B35",
                         "2017" = "#00A087", "2016" = "#4DBBD5"))
plot_SSB(b, line_color = "#00A087", se = TRUE, se_color = "#00A087")
plot_compare_ts(a, b, colors = c("ACL" = "#3C5488", "ALSCL" = "#E64B35"))

# 连续量使用浅到深渐变 / Sequential gradients encode continuous quantities
plot_pla(b)                         # 全局端点 / Global endpoints
plot_compare_F(a, b, palette = "npg")
plot_compare_F(a, b, palette = "inferno") # 其他渐变 / Another gradient
plot_ridges(b)                      # 默认 viridis 年份渐变 / Default time gradient
plot_ridges(b, palette = "cividis")
acl_theme_set(ylab = list(year = "Survey year")) # 山脊图时间轴 / Ridge time axis
plot_ridges(b, palette = c("#E8F1FA", "#3C5488"))

# 恢复默认 / Restore defaults
acl_theme_reset()
```

山脊图 `plot_ridges()` 独立使用 **viridis 连续渐变**，按输入年份顺序取色，两侧观测与拟合使用相同的年份颜色。它不继承全局 ggsci 分类色板；`palette=NULL` 也使用 viridis。可改为 `"cividis"`、`"plasma"`、`"ocean"`，或提供两个以上颜色作为渐变端点。

Ridges independently use the **sequential viridis gradient**, sampled in input-year order and shared by observed and fitted panels. They do not inherit the global ggsci categorical palette; NULL also selects viridis. Choose cividis, plasma, ocean, or a vector of gradient colors for an alternative.

`plot_retro(colors=...)` 的命名向量必须覆盖本次结果的所有截止期；无名称时按截止期降序对应。普通 `retro_*` 拟合入口通过全局主题控制自动生成的图；对已返回结果调用 `plot_retro()` 可单独改色。

Named retrospective colors must cover every terminal period; unnamed colors follow descending periods. Use the global theme for automatic plots from `retro_*`, or call `plot_retro()` on the returned result for per-plot styling.

| 设置 / Setting | 范围与优先级 / Scope and precedence |
|---|---|
| `palette` | `npg`（10 色）、`aaas`（10）、`nejm`（8）、`lancet`（9）、`jama`（7）；切换时重设色彩角色 / Switching resets derived roles |
| `line_color`, `se_color`, `point_color` | 单模型线、区间、散点；NULL 继承主题 / Single-model lines, intervals and scatter |
| `observed_color`, `smooth_color`, `hline_color` | 观测、残差平滑和零参考线 / Observation, residual smoother and reference |
| `compare_colors` | 模型 1、模型 2；可按模型名称匹配 / Model pair, optionally matched by name |
| `low_col`, `high_col` | 连续热图端点；不把分类色板当数值刻度 / Sequential heatmap endpoints |
| `font_family`, `title_size`, `axis_text_size`, `strip_text_size` | 字体、标题、刻度与分面文字 / Typography |
| `line_size` / `linewidth` | 单模型 / 比较图线宽，按函数签名使用 / Function-specific line width |
| `facet_ncol` / `facet_col` / `ncol` | 单模型 / 回溯 / 比较图分面列数 / Function-specific layout |

当类别数超过色板原生颜色数，回溯图使用插值扩展，**不代表 ggsci 原生提供了更多独立类别色**。大量回溯应减少同时展示的期数，或显式提供经过检查的命名颜色；打印时也要检查线型和端点。

Beyond native palette size, retrospective colors are interpolated. These are not additional native categorical colors. For many peels, show fewer at once or supply reviewed named colors; check lines and endpoints in print.

```r
# 调整文字与布局 / Typography and layout
acl_theme_set(palette="npg", title_size=16, axis_title_size=12,
              axis_text_size=10, strip_text_size=10, title_hjust=0,
              compare_legend_pos="bottom", compare_linetypes=c("solid","dashed"))
p <- plot_retro(rb, facet_col=2, point_size=1.8, line_size=.8)
ggplot2::ggsave("retrospective.png", p, width=11, height=7, dpi=300, bg="white")
ggplot2::ggsave("retrospective.pdf", p, width=11, height=7)
# 保存并恢复主题；无参数 acl_theme_set() 不会重置 / Preserve settings explicitly
old <- acl_theme()
acl_theme_set(palette="aaas")
do.call(acl_theme_set, old)
acl_theme_reset()
```

可显式指定颜色；默认颜色参数为 `NULL`，从全局主题取值。改变 `line_color` 不会自动改变 `se_color`；要让自定义线与区间同色，请一起指定。`palette` 与颜色同时传入时，显式颜色优先。

Explicit colors override the theme; `NULL` color arguments inherit it. Changing `line_color` alone does not change `se_color`; specify both to match custom ribbons. Explicit colors win when supplied together with a palette.

色板来源：[ggsci NPG documentation](https://nanx.me/ggsci/reference/pal_npg.html)。

### 2.2.5 默认无网格线

所有包内绘图默认去掉主、次面板网格线，包括模型比较和回溯图；配色、置信区间及坐标轴保留原设置。升级后需重新创建旧图，才会应用新默认值。以下使用完整拟合示例中的 `b`，对旧图或手写 ggplot 图明确应用无网格样式：

```r
p <- plot_SSB(b, se = TRUE)
p + ggplot2::theme(panel.grid.major = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank())
```

### Grid-free defaults in 2.2.5

All package plotting functions omit major and minor panel gridlines by default, including comparison panels and retrospectives. Colours, confidence intervals and axes retain their existing settings. Recreate an old plot after upgrading to apply the new defaults. Using `b` from the worked fitting example, explicitly apply the grid-free style to an older plot or a hand-written ggplot:

```r
p <- plot_SSB(b, se = TRUE)
p + ggplot2::theme(panel.grid.major = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank())
```

2.2.6 进一步保证 SSB、丰度、生物量、捕获量、偏差和捕捞死亡率图在主题加载失败后的回退路径也不显示网格。显式指定的主题仍优先。说明书的 ggplot 导出统一检查各子图的主、次网格；发现网格时停止导出并保留原文件。正式 2.2.6 下载包包含更新后的帮助图片。

Version 2.2.6 also keeps SSB, abundance, biomass, catch, deviation and fishing-mortality plots grid-free if theme loading fails. Explicit theme choices remain available. Manual ggplot exports check major and minor grids in every panel; a visible grid stops export without replacing an existing file. The 2.2.6 release archive includes the refreshed help images.

### 2.2.7 的保存结果与不确定性

丰度图按矩阵位置和拟合结果中的 `year`、`len_label` 对齐。给 `report$NA` 或 `report$NL` 添加行列名称，不会改变年份或组别对应关系。保存结果时应一起保留矩阵原有顺序和拟合元数据。

丰度、补充量和过程偏差的区间需要完整的有限估计值，以及有限、非负的标准误。标准误缺失、非法或不完整时会明确报错。只需绘制估计值时使用 `se = FALSE`；过程偏差图此时读取 `report$dev_log_R` 或 `report$dev_log_F`，没有 `est_std` 也可绘制，旧结果可使用有效摘要表中的估计值。解释区间前仍须查看拟合诊断。

```r
saved <- b
saved$obj <- NULL
saved$est_std <- NULL
plot_abundance(saved, type = "NL", se = FALSE)
plot_recruitment(saved, se = FALSE)
plot_deviance(saved, type = "F", se = FALSE)
```

### Saved results and uncertainty in 2.2.7

Abundance plots use matrix positions with the fitted `year` and `len_label` metadata. Adding row or column names to `report$NA` or `report$NL` does not change time or group alignment. Keep the original matrix order and the fitted metadata together when saving results.

Abundance, recruitment and process-deviation intervals require a complete table of finite estimates and finite, nonnegative standard errors. Missing, invalid or incomplete uncertainty produces an explicit error. Use `se = FALSE` when only estimates are intended. Process-deviation plots then read `report$dev_log_R` or `report$dev_log_F`, so they work without `est_std`; older results can use the estimates in a valid summary table. Review the fit diagnostics before interpreting any interval.

```r
saved <- b
saved$obj <- NULL
saved$est_std <- NULL
plot_abundance(saved, type = "NL", se = FALSE)
plot_recruitment(saved, se = FALSE)
plot_deviance(saved, type = "F", se = FALSE)
```

### 生长图范围与文字设置

`age_range = NULL` 时，`plot_VB()` 使用拟合结果中的年龄范围；没有年龄元数据的旧结果从 1–25 岁开始。自动范围的起点不早于 `t0`，若没有正跨度则报错。显式范围必须为两个有限、递增的年龄，且起点不早于 `t0`，避免在生长曲线起点之前出现负体长和上下界倒置的区间。仍支持合法的显式范围，包括超出最老拟合年龄的外推。

曲线和区间均继承 `ylab$growth` 及所选字体。无论是否显示区间，都保留 Linf/k 标注，并遵守 `text_size`、`text_color`；显式 `ylab` 覆盖全局标签。如果 `se = TRUE` 但协方差不可用，会提示并仅绘制曲线，同时保留指定的标签、字号、刻度、基础主题和标注设置。

```r
plot_VB(b, se = FALSE, ylab = "Length (cm)",
        axis_text_size = 12, x_breaks = c(1, 5, 10, 15),
        age_range = c(1, 15), text_size = 4)
```

### Growth-plot ranges and text settings

`plot_VB()` uses the fitted age range when `age_range = NULL`. For older results without age metadata, it starts from 1–25 years. Automatic ranges start no earlier than `t0`; a range with no positive span produces an error. An explicit range must contain two finite increasing ages and start at or after `t0`. This avoids negative predicted lengths and reversed intervals before the biological growth curve begins. Explicit valid ranges, including extrapolation beyond the oldest fitted age, remain supported.

Curves and intervals both inherit `ylab$growth` and the selected font. The Linf/k annotation is shown with and without intervals and honors `text_size` and `text_color`. Explicit `ylab` overrides the global label. If covariance is unavailable and `se = TRUE`, the function warns and draws only the curve while retaining the requested labels, text sizes, axis breaks, base theme and annotation settings.

```r
plot_VB(b, se = FALSE, ylab = "Length (cm)",
        axis_text_size = 12, x_breaks = c(1, 5, 10, 15),
        age_range = c(1, 15), text_size = 4)
```

## 2.2.9

2.2.9 中，省略的通用 `line_size` 与 `se_alpha` 继承 `acl_theme_set()`（默认 1.5 与 0.2），函数显式参数优先。比较曲线遵守 `linetypes` 与 `compare_linetypes`，残差／指标组合图标题及 F 分面文字继承全局字体设置。默认仍无网格。ACL F 偏差图按年龄数字排序；`plot_pla(x_breaks = c(1, 5, 10, 15))` 选择年龄组刻度，不删除热图单元。

In 2.2.9, omitted generic `line_size` and `se_alpha` inherit `acl_theme_set()` (defaults 1.5 and 0.2); explicit function arguments take priority. Comparison curves honor `linetypes` and `compare_linetypes`. Combined residual/metric titles and F facet labels inherit the global typography. Grid lines remain absent by default. ACL F-deviation age panels use numeric order. `plot_pla(x_breaks = c(1, 5, 10, 15))` selects age-bin ticks without removing heatmap cells.

## 全局标签、坐标与诊断图 · Global labels, axes and diagnostic plots

`plot_SSB()`、`plot_biomass()`、`plot_abundance()` 和 `plot_catch()` 的总量、年龄及体长模式，无论是否显示区间，都继承全局 `titles`、`xlab`、`ylab`、`x_breaks` 和 `x_expand`。SSB 的纵轴使用 `ylab$ssb`；标题使用数量键，区间版本加 `_se`（年龄别丰度保留 `NA_` 与 `NA_se`）。这些设置只改变标签和显示范围，不会换算估计值或单位，主、次网格线仍默认隐藏。

The total, age and length modes of `plot_SSB()`, `plot_biomass()`, `plot_abundance()` and `plot_catch()` inherit global `titles`, `xlab`, `ylab`, `x_breaks` and `x_expand`, with or without intervals. For SSB, use `ylab$ssb`; titles use the quantity key, with `_se` for interval variants (age-specific abundance retains `NA_` and `NA_se`). These settings only change labels and display ranges, not estimates or units. Major and minor gridlines remain absent.

```r
acl_theme_set(
  titles = list(SSB = "Spawning biomass",
                SSB_se = "Spawning biomass with 95% intervals"),
  xlab = list(year = "Survey year"),
  ylab = list(ssb = "Spawning biomass"),
  x_breaks = c(2000, 2009, 2019), x_expand = c(0, 0)
)
plot_SSB(b, se = TRUE)
acl_theme_reset()
```

每个分面按自身有效观测的不同横坐标数量选择趋势：少于 2 个不画平滑线，2–5 个使用线性趋势，至少 6 个使用 loess；需要时仅增加该分面的 span，以包含至少 5 个邻近点。稀疏尾部体长组不会删除或改变其他分面的趋势。

Each facet chooses its smoother independently using the number of distinct observed x values: fewer than two omit smoothing, two to five use a linear trend, and six or more use loess. The loess span is enlarged within that facet when needed for at least five neighbors. A sparse tail bin does not remove or change trends in other panels.

提供 `ref_data` 时，`ref_name` 必须是一个非空字符串，且不能与任一模型名称相同。名称用于标识独立的参照曲线；重复名称会在拟合参照曲线前报错。

When `ref_data` is supplied, `ref_name` must be one nonempty string and differ from both model names. The name identifies a separate reference curve; duplicate names are rejected before fitting the reference.

调查拟合图标题表示调查指数，山脊图标题表示调查体长组成，两者都不是渔业捕获量估计。过程偏差图在 `log = TRUE` 时标为对数偏差（参照值 0），在 `log = FALSE` 时标为乘数（参照值 1）。取指数只改变尺度，不改变已拟合的过程；两者都不是似然偏差统计量。

Survey-fit titles refer to survey indices, and ridge titles refer to survey length compositions; neither is a fishery catch estimate. In process-deviation plots, `log = TRUE` labels log deviations (reference value 0), while `log = FALSE` labels multiplicative factors (reference value 1). Exponentiation changes the scale, not the underlying fitted process; neither quantity is a likelihood deviance statistic.

`plot_fishing_mortality()` 也继承全局标题、标签、`x_breaks` 与 `x_expand`。标题键为 `F_year`、`F_age`、`F_length`，区间版本加 `_se`；横轴分别使用 `xlab$year`、`xlab$age`、`xlab$length`，纵轴使用 `ylab$F`。年龄模式的坐标是组序号，因此未修改时默认标签仍为 “Age Group”，自定义的 `xlab$age` 则会生效。ACL 的旧 length 别名使用年龄模式设置。单次调用中显式指定的标签和刻度优先。`base_theme` 支持 `"theme_bw"`、`"bw"` 等名称、`ggplot2::theme_bw()` 等现有主题对象，或以 `NULL` 继承全局设置；这些形式均保持无主、次网格线。

`plot_fishing_mortality()` also inherits global titles, labels, `x_breaks` and `x_expand`. Title keys are `F_year`, `F_age` and `F_length`, with `_se` for interval variants. The horizontal label uses `xlab$year`, `xlab$age` or `xlab$length`; the vertical label uses `ylab$F`. Age-mode coordinates are group indices, so the unchanged default label is “Age Group”; a custom `xlab$age` is honored. The ACL legacy length alias uses the age settings. Explicit per-call labels and breaks take precedence. `base_theme` accepts a name such as `"theme_bw"` or `"bw"`, an existing ggplot2 theme object such as `ggplot2::theme_bw()`, or `NULL` for the global setting. All forms keep major and minor gridlines hidden.

单模型与比较调查拟合图使用调查指数标签，不再取渔业捕获量标签。可用 `acl_theme_set(ylab = list(survey = "Survey index (relative units)"))` 统一设置；未设置 `survey` 时仍兼容旧的自定义 `ylab$abundance`，否则默认为 “Survey index”。单模型对数图会增加 “Log” 前缀，显式 `ylab` 仍优先。`ylab$catch` 继续用于真实捕获量图，不会改变调查指数标签。

Single-model and comparison survey-fit plots use the survey-index label rather than the fishery-catch label. Set `acl_theme_set(ylab = list(survey = "Survey index (relative units)"))` to label both consistently. When `survey` is unset, a customized legacy `ylab$abundance` still applies; otherwise the default is “Survey index”. Single-model log plots add a “Log” prefix, and their explicit `ylab` remains authoritative. `ylab$catch` continues to describe actual catch plots and does not relabel survey indices.

---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/12-Case-Studies) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/14-Function-Reference)
