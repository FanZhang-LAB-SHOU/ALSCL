# Colors and export

First complete the [worked YTF example](first-model.html) to create `a`, `b` and `x`. The following block also creates `rb` by fitting three retrospective peels; see [retrospectives](retrospectives.html) for their interpretation. Theme settings also apply to other fitted models.

The default is **ggsci NPG**: navy estimates, vermilion observations, and navy/vermilion model comparisons. Retrospective colors follow descending terminal periods. Settings affect newly created plots, not existing objects.

```r
# Create the retrospective result before styling it
rb <- retro_alscl(x, nyear = 3, train_times = 2, ncores = 1, silent = TRUE)

# Set once, then recreate plots
acl_theme_set(palette = "npg", base_theme = "theme_bw", font_family = "sans")
plot_retro(rb, facet_col = 2, rho_digits = 3)
plot_compare_ts(a, b, se = TRUE)

# Alternative journal palettes
acl_theme_set(palette = "jama") # npg, aaas, nejm, lancet, jama
plot_abundance(b, type = "NL", facet_ncol = 3)

# Per-call overrides take precedence
plot_retro(rb, palette = "nejm", rho_position = "top_left")
plot_retro(rb, colors = c("2019" = "#3C5488", "2018" = "#E64B35",
                         "2017" = "#00A087", "2016" = "#4DBBD5"))
plot_SSB(b, line_color = "#00A087", se = TRUE, se_color = "#00A087")
plot_compare_ts(a, b, colors = c("ACL" = "#3C5488", "ALSCL" = "#E64B35"))

# Sequential gradients encode continuous quantities
plot_pla(b)                         # Global endpoints
plot_compare_F(a, b, palette = "npg")
plot_compare_F(a, b, palette = "inferno") # Another gradient
plot_ridges(b)                      # Default time gradient
plot_ridges(b, palette = "cividis")
acl_theme_set(ylab = list(year = "Survey year")) # Ridge time axis
plot_ridges(b, palette = c("#E8F1FA", "#3C5488"))

# Restore defaults
acl_theme_reset()
```


Ridges independently use the **sequential viridis gradient**, sampled in input-year order and shared by observed and fitted panels. They do not inherit the global ggsci categorical palette; NULL also selects viridis. Choose cividis, plasma, ocean, or a vector of gradient colors for an alternative.


Named retrospective colors must cover every terminal period; unnamed colors follow descending periods. Use the global theme for automatic plots from `retro_*`, or call `plot_retro()` on the returned result for per-plot styling.

|Setting|Scope and precedence|
|---|---|
| `palette` |Switching resets derived roles|
| `line_color`, `se_color`, `point_color` |Single-model lines, intervals and scatter|
| `observed_color`, `smooth_color`, `hline_color` |Observation, residual smoother and reference|
| `compare_colors` |Model pair, optionally matched by name|
| `low_col`, `high_col` |Sequential heatmap endpoints|
| `font_family`, `title_size`, `axis_text_size`, `strip_text_size` |Typography|
| `line_size` / `linewidth` | Function-specific line width |
| `facet_ncol` / `facet_col` / `ncol` | Function-specific facet layout |


Beyond native palette size, retrospective colors are interpolated. These are not additional native categorical colors. For many peels, show fewer at once or supply reviewed named colors; check lines and endpoints in print.

```r
# Typography and layout
acl_theme_set(palette="npg", title_size=16, axis_title_size=12,
              axis_text_size=10, strip_text_size=10, title_hjust=0,
              compare_legend_pos="bottom", compare_linetypes=c("solid","dashed"))
p <- plot_retro(rb, facet_col=2, point_size=1.8, line_size=.8)
ggplot2::ggsave("retrospective.png", p, width=11, height=7, dpi=300, bg="white")
ggplot2::ggsave("retrospective.pdf", p, width=11, height=7)
# Preserve settings explicitly
old <- acl_theme()
acl_theme_set(palette="aaas")
do.call(acl_theme_set, old)
acl_theme_reset()
```


Explicit colors override the theme; `NULL` color arguments inherit it. Changing `line_color` alone does not change `se_color`; specify both to match custom ribbons. Explicit colors win when supplied together with a palette.

### Grid-free defaults in 2.2.5

All package plotting functions omit major and minor panel gridlines by default, including comparison panels and retrospectives. Colours, confidence intervals and axes retain their existing settings. Recreate an old plot after upgrading to apply the new defaults. Using `b` from the worked fitting example, explicitly apply the grid-free style to an older plot or a hand-written ggplot:

```r
p <- plot_SSB(b, se = TRUE)
p + ggplot2::theme(panel.grid.major = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank())
```

Version 2.2.6 also keeps SSB, abundance, biomass, catch, deviation and fishing-mortality plots grid-free if theme loading fails. Explicit theme choices remain available. Manual ggplot exports check major and minor grids in every panel; a visible grid stops export without replacing an existing file. The 2.2.6 release archive includes the refreshed help images.

### Growth-plot ranges and text settings

`plot_VB()` uses the fitted age range when `age_range = NULL`. For older results without age metadata, it starts from 1–25 years. Automatic ranges start no earlier than `t0`; a range with no positive span produces an error. An explicit range must contain two finite increasing ages and start at or after `t0`. This avoids negative predicted lengths and reversed intervals before the biological growth curve begins. Explicit valid ranges, including extrapolation beyond the oldest fitted age, remain supported.

Curves and intervals both inherit `ylab$growth` and the selected font. The Linf/k annotation is shown with and without intervals and honors `text_size` and `text_color`. Explicit `ylab` overrides the global label. If covariance is unavailable and `se = TRUE`, the function warns and draws only the curve while retaining the requested labels, text sizes, axis breaks, base theme and annotation settings.

```r
plot_VB(b, se = FALSE, ylab = "Length (cm)",
        axis_text_size = 12, x_breaks = c(1, 5, 10, 15),
        age_range = c(1, 15), text_size = 4)
```

### Consistency corrections

Both residual layouts honor per-call `title`, `xlab`, `ylab` and `title_hjust`. For example, `plot_residuals(b, type = "year", title = "Survey residuals", xlab = "Length (cm)", ylab = "Log residual", title_hjust = 0)` uses the supplied labels and a left-aligned title. Default plots remain free of major and minor gridlines.

Survey fit plots align both observed and predicted matrices by their positions and fitted calendar/length metadata, even if dimnames are added or removed. Missing and zero observations stay excluded. Use `exp_transform = FALSE` if exponentiating predictions would overflow. In residual plots, `resid_cap` must be a finite positive scalar or `NULL` to disable capping; negative or zero caps cannot erase the diagnostic pattern.

In 2.2.9, omitted generic `line_size` and `se_alpha` inherit `acl_theme_set()` (defaults 1.5 and 0.2); explicit function arguments take priority. Comparison curves honor `linetypes` and `compare_linetypes`. Combined residual/metric titles and F facet labels inherit the global typography. Grid lines remain absent by default. ACL F-deviation age panels use numeric order. `plot_pla(x_breaks = c(1, 5, 10, 15))` selects age-bin ticks without removing heatmap cells.

### Global labels and axes

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

`plot_fishing_mortality()` also inherits global titles, labels, `x_breaks` and `x_expand`. Title keys are `F_year`, `F_age` and `F_length`, with `_se` for interval variants. The horizontal label uses `xlab$year`, `xlab$age` or `xlab$length`; the vertical label uses `ylab$F`. Age-mode coordinates are group indices, so the unchanged default label is “Age Group”; a custom `xlab$age` is honored. The ACL legacy length alias uses the age settings. Explicit per-call labels and breaks take precedence. `base_theme` accepts a name such as `"theme_bw"` or `"bw"`, an existing ggplot2 theme object such as `ggplot2::theme_bw()`, or `NULL` for the global setting. All forms keep major and minor gridlines hidden.

Single-model and comparison survey-fit plots use the survey-index label rather than the fishery-catch label. Set `acl_theme_set(ylab = list(survey = "Survey index (relative units)"))` to label both consistently. When `survey` is unset, a customized legacy `ylab$abundance` still applies; otherwise the default is “Survey index”. Single-model log plots add a “Log” prefix, and their explicit `ylab` remains authoritative. `ylab$catch` continues to describe actual catch plots and does not relabel survey indices.
