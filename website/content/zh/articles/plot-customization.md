# ggsci 配色与导出

先完成[内置 YTF 拟合示例](first-model.html)，得到 `a`、`b` 和 `x`。下面先拟合三个截短回溯，建立 `rb`，再调整图形；结果含义见[回溯分析](retrospectives.html)。这些主题设置同样适用于其他拟合结果。

默认使用 **ggsci NPG**。单模型估计用深蓝，观测用朱红；两模型比较按模型顺序使用深蓝、朱红；回溯按截止期从新到旧分配 NPG 原生颜色。设置在创建图时生效，已有图对象不会自动重绘。


```r
# 先建立回溯结果，再调整绘图样式
rb <- retro_alscl(x, nyear = 3, train_times = 2, ncores = 1, silent = TRUE)

# 一次设置，随后重新创建图
acl_theme_set(palette = "npg", base_theme = "theme_bw", font_family = "sans")
plot_retro(rb, facet_col = 2, rho_digits = 3)
plot_compare_ts(a, b, se = TRUE)

# 可选期刊色板
acl_theme_set(palette = "jama") # npg, aaas, nejm, lancet, jama
plot_abundance(b, type = "NL", facet_ncol = 3)

# 单图覆盖优先于全局设置
plot_retro(rb, palette = "nejm", rho_position = "top_left")
plot_retro(rb, colors = c("2019" = "#3C5488", "2018" = "#E64B35",
                         "2017" = "#00A087", "2016" = "#4DBBD5"))
plot_SSB(b, line_color = "#00A087", se = TRUE, se_color = "#00A087")
plot_compare_ts(a, b, colors = c("ACL" = "#3C5488", "ALSCL" = "#E64B35"))

# 连续量使用浅到深渐变
plot_pla(b)                         # 全局端点
plot_compare_F(a, b, palette = "npg")
plot_compare_F(a, b, palette = "inferno") # 其他渐变
plot_ridges(b)                      # 默认 viridis 年份渐变
plot_ridges(b, palette = "cividis")
acl_theme_set(ylab = list(year = "Survey year")) # 山脊图时间轴
plot_ridges(b, palette = c("#E8F1FA", "#3C5488"))

# 恢复默认
acl_theme_reset()
```

山脊图 `plot_ridges()` 独立使用 **viridis 连续渐变**，按输入年份顺序取色，两侧观测与拟合使用相同的年份颜色。它不继承全局 ggsci 分类色板；`palette=NULL` 也使用 viridis。可改为 `"cividis"`、`"plasma"`、`"ocean"`，或提供两个以上颜色作为渐变端点。


`plot_retro(colors=...)` 的命名向量必须覆盖本次结果的所有截止期；无名称时按截止期降序对应。普通 `retro_*` 拟合入口通过全局主题控制自动生成的图；对已返回结果调用 `plot_retro()` 可单独改色。


|设置|范围与优先级|
|---|---|
| `palette` |`npg`（10 色）、`aaas`（10）、`nejm`（8）、`lancet`（9）、`jama`（7）；切换时重设色彩角色|
| `line_color`, `se_color`, `point_color` |单模型线、区间、散点；NULL 继承主题|
| `observed_color`, `smooth_color`, `hline_color` |观测、残差平滑和零参考线|
| `compare_colors` |模型 1、模型 2；可按模型名称匹配|
| `low_col`, `high_col` |连续热图端点；不把分类色板当数值刻度|
| `font_family`, `title_size`, `axis_text_size`, `strip_text_size` |字体、标题、刻度与分面文字|
| `line_size` / `linewidth` | 单模型 / 比较图线宽，按函数签名使用 / Function-specific line width |
| `facet_ncol` / `facet_col` / `ncol` | 单模型 / 回溯 / 比较图分面列数 / Function-specific layout |

当类别数超过色板原生颜色数，回溯图使用插值扩展，**不代表 ggsci 原生提供了更多独立类别色**。大量回溯应减少同时展示的期数，或显式提供经过检查的命名颜色；打印时也要检查线型和端点。


```r
# 调整文字与布局
acl_theme_set(palette="npg", title_size=16, axis_title_size=12,
              axis_text_size=10, strip_text_size=10, title_hjust=0,
              compare_legend_pos="bottom", compare_linetypes=c("solid","dashed"))
p <- plot_retro(rb, facet_col=2, point_size=1.8, line_size=.8)
ggplot2::ggsave("retrospective.png", p, width=11, height=7, dpi=300, bg="white")
ggplot2::ggsave("retrospective.pdf", p, width=11, height=7)
# 保存并恢复主题；无参数 acl_theme_set() 不会重置
old <- acl_theme()
acl_theme_set(palette="aaas")
do.call(acl_theme_set, old)
acl_theme_reset()
```

可显式指定颜色；默认颜色参数为 `NULL`，从全局主题取值。改变 `line_color` 不会自动改变 `se_color`；要让自定义线与区间同色，请一起指定。`palette` 与颜色同时传入时，显式颜色优先。


色板来源：[ggsci NPG documentation](https://nanx.me/ggsci/reference/pal_npg.html)。

### 2.2.5 默认无网格线

所有包内绘图默认去掉主、次面板网格线，包括模型比较和回溯图；配色、置信区间及坐标轴保留原设置。升级后需重新创建旧图，才会应用新默认值。以下使用完整拟合示例中的 `b`，对旧图或手写 ggplot 图明确应用无网格样式：

```r
p <- plot_SSB(b, se = TRUE)
p + ggplot2::theme(panel.grid.major = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank())
```

2.2.6 进一步保证 SSB、丰度、生物量、捕获量、偏差和捕捞死亡率图在主题加载失败后的回退路径也不显示网格。显式指定的主题仍优先。说明书的 ggplot 导出统一检查各子图的主、次网格；发现网格时停止导出并保留原文件。正式 2.2.6 下载包包含更新后的帮助图片。

### 生长图范围与文字设置

`age_range = NULL` 时，`plot_VB()` 使用拟合结果中的年龄范围；没有年龄元数据的旧结果从 1–25 岁开始。自动范围的起点不早于 `t0`，若没有正跨度则报错。显式范围必须为两个有限、递增的年龄，且起点不早于 `t0`，避免在生长曲线起点之前出现负体长和上下界倒置的区间。仍支持合法的显式范围，包括超出最老拟合年龄的外推。

曲线和区间均继承 `ylab$growth` 及所选字体。无论是否显示区间，都保留 Linf/k 标注，并遵守 `text_size`、`text_color`；显式 `ylab` 覆盖全局标签。如果 `se = TRUE` 但协方差不可用，会提示并仅绘制曲线，同时保留指定的标签、字号、刻度、基础主题和标注设置。

```r
plot_VB(b, se = FALSE, ylab = "Length (cm)",
        axis_text_size = 12, x_breaks = c(1, 5, 10, 15),
        age_range = c(1, 15), text_size = 4)
```

### 一致性修正

残差图的两种布局均遵守单次调用的 `title`、`xlab`、`ylab` 和 `title_hjust`。例如 `plot_residuals(b, type = "year", title = "Survey residuals", xlab = "Length (cm)", ylab = "Log residual", title_hjust = 0)` 使用指定标签并左对齐标题。所有默认图继续不显示主、次网格线。

调查拟合图按矩阵位置及拟合年份、体长元数据对齐观测与预测，增删行列名不会改变坐标；缺失及零观测继续排除。若预测取指数会溢出，请使用 `exp_transform = FALSE`。残差图的 `resid_cap` 必须为有限正标量，或以 `NULL` 关闭截断；不再允许负值或零值抹去诊断特征。

2.2.9 中，省略的通用 `line_size` 与 `se_alpha` 继承 `acl_theme_set()`（默认 1.5 与 0.2），函数显式参数优先。比较曲线遵守 `linetypes` 与 `compare_linetypes`，残差／指标组合图标题及 F 分面文字继承全局字体设置。默认仍无网格。ACL F 偏差图按年龄数字排序；`plot_pla(x_breaks = c(1, 5, 10, 15))` 选择年龄组刻度，不删除热图单元。

### 全局标签与坐标轴

`plot_SSB()`、`plot_biomass()`、`plot_abundance()` 和 `plot_catch()` 的总量、年龄及体长模式，无论是否显示区间，都继承全局 `titles`、`xlab`、`ylab`、`x_breaks` 和 `x_expand`。SSB 的纵轴使用 `ylab$ssb`；标题使用数量键，区间版本加 `_se`（年龄别丰度保留 `NA_` 与 `NA_se`）。这些设置只改变标签和显示范围，不会换算估计值或单位，主、次网格线仍默认隐藏。

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

`plot_fishing_mortality()` 也继承全局标题、标签、`x_breaks` 与 `x_expand`。标题键为 `F_year`、`F_age`、`F_length`，区间版本加 `_se`；横轴分别使用 `xlab$year`、`xlab$age`、`xlab$length`，纵轴使用 `ylab$F`。年龄模式的坐标是组序号，因此未修改时默认标签仍为 “Age Group”，自定义的 `xlab$age` 则会生效。ACL 的旧 length 别名使用年龄模式设置。单次调用中显式指定的标签和刻度优先。`base_theme` 支持 `"theme_bw"`、`"bw"` 等名称、`ggplot2::theme_bw()` 等现有主题对象，或以 `NULL` 继承全局设置；这些形式均保持无主、次网格线。

单模型与比较调查拟合图使用调查指数标签，不再取渔业捕获量标签。可用 `acl_theme_set(ylab = list(survey = "Survey index (relative units)"))` 统一设置；未设置 `survey` 时仍兼容旧的自定义 `ylab$abundance`，否则默认为 “Survey index”。单模型对数图会增加 “Log” 前缀，显式 `ylab` 仍优先。`ylab$catch` 继续用于真实捕获量图，不会改变调查指数标签。
