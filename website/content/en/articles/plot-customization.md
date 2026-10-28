# Colors and export

The plotting examples use the `a` and `b` fits from the [worked YTF example](first-model.html). Theme settings also apply to other fitted models.

The default is **ggsci NPG**: navy estimates, vermilion observations, and navy/vermilion model comparisons. Retrospective colors follow descending terminal periods. Settings affect newly created plots, not existing objects.

```r
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

### Growth-plot settings in 2.2.7

`plot_VB()` honors `ylab` for both curves and intervals. If covariance is unavailable and `se = TRUE`, it warns and draws only the curve while retaining the requested labels, text sizes, axis breaks, base theme and annotation settings.

```r
plot_VB(b, se = FALSE, ylab = "Length (cm)",
        axis_text_size = 12, x_breaks = c(1, 5, 10, 15),
        age_range = c(1, 15), text_size = 4)
```
