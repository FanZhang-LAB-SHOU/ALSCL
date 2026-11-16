# Draw the six palettes that acl_theme_set(palette = ...) accepts (the
# default palette and five ggsci palettes), the roles each color takes in the plots,
# the four quantity colors of the default style, and the same two figures
# under every palette. Run from the repository root:
#   Rscript scripts/palette_swatches.R [output_dir] [teaching_fits.rds]
# Writes docs/figures/palettes/palettes.png, ssb_by_palette.png and
# compare_by_palette.png. Fits YTF_example once (about two minutes).
suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
})
suppressMessages(pkgload::load_all(".", quiet = TRUE))
source("scripts/plot_helpers.R")
# Optional arguments: an output folder and an archive of teaching fits
# (a list with elements acl and alscl), to redraw without refitting.
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[[1L]] else file.path("docs", "figures", "palettes")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
palettes <- c("default", "npg", "aaas", "nejm", "lancet", "jama")
suppressMessages(acl_theme_reset())

# Black text on light tiles, white text on dark tiles.
ink_on <- function(hex) {
  rgb <- grDevices::col2rgb(hex) / 255
  ifelse(colSums(rgb * c(0.299, 0.587, 0.114)) > 0.55, "black", "white")
}

# 1. Swatches: one row per palette, hex codes, and the role of each color,
# and below them the colors of the four quantity families.
swatch <- do.call(rbind, lapply(palettes, function(p) {
  cols <- acl_palette(palette = p)
  roles <- acl_palette(palette = p, role = c("primary", "accent", "smooth"))
  role <- rep("", length(cols))
  role[match(roles[["primary"]], cols)] <- "line, interval"
  role[match(roles[["accent"]], cols)] <- "observed"
  role[match(roles[["smooth"]], cols)] <- "smoother"
  data.frame(palette = p, index = seq_along(cols), hex = cols, role = role)
}))
swatch$palette <- factor(swatch$palette, levels = rev(palettes))
# ggsci adds an alpha channel ("FF") to its codes; the label shows the color alone.
label_hex <- toupper(substr(swatch$hex, 1L, 7L))
swatch$text <- ifelse(nzchar(swatch$role), paste0(label_hex, "\n", swatch$role), label_hex)
p_swatch <- ggplot(swatch, aes(index, palette)) +
  geom_tile(aes(fill = hex), width = 0.92, height = 0.8) +
  geom_text(aes(label = text, colour = ink_on(hex)), size = 2.9, lineheight = 0.9) +
  scale_fill_identity() + scale_colour_identity() +
  scale_x_continuous(breaks = 1:10, expand = expansion(add = 0.3)) +
  labs(x = "Color index", y = NULL,
       title = "Palettes accepted by acl_theme_set(palette = ...)",
       subtitle = paste("Labeled colors are used by default for lines and intervals, for observed points",
                        "or the second model, and for smoothers")) +
  theme_acl() +
  theme(axis.text.y = element_text(face = "bold"))
quantity <- acl_palette(role = c("stock", "F", "recruitment", "catch"))
q_swatch <- data.frame(index = seq_along(quantity), hex = unname(quantity),
  text = paste0(c("Stock size", "Fishing mortality", "Recruitment", "Catch"), "\n", toupper(quantity)))
p_quantity <- ggplot(q_swatch, aes(index, 1)) +
  geom_tile(aes(fill = hex), width = 0.92, height = 0.8) +
  geom_text(aes(label = text, colour = ink_on(hex)), size = 3, lineheight = 0.9) +
  scale_fill_identity() + scale_colour_identity() +
  scale_x_continuous(expand = expansion(add = 0.3)) +
  labs(x = NULL, y = NULL,
       title = "Colors of the quantities under the default style",
       subtitle = paste0("Stock size (spawning stock biomass, total biomass, total abundance), fishing mortality, ",
                         "recruitment and catch keep these colors under every palette.\nSet stock_color, F_color, ",
                         "recruitment_color or catch_color to NULL in acl_theme_set() to give that quantity ",
                         "the line color of the palette.")) +
  theme_acl() +
  theme(axis.text = element_blank(), axis.ticks = element_blank(), axis.line = element_blank(),
        panel.border = element_blank())
save_grid_free_plot(file.path(out, "palettes.png"),
  # Ten tiles per row and long subtitles need a wider figure than acl_figure_size() gives.
  p_swatch / p_quantity + plot_layout(heights = c(6, 1.3)), width = 12, height = 8)

# 2. The same figures under every palette. The theme is changed inside a
# function so that on.exit() restores the caller's theme when the figures are
# saved; a top-level on.exit() would not run at the end of the script.
data("YTF_example")
x <- YTF_example
fits <- if (length(args) > 1L) readRDS(args[[2L]]) else NULL
a <- if (is.null(fits)) run_acl(x, silent = TRUE) else fits$acl
b <- if (is.null(fits)) run_alscl(x, silent = TRUE) else fits$alscl
draw_under_palettes <- function() {
  old_theme <- acl_theme()
  on.exit(do.call(acl_theme_set, old_theme), add = TRUE)
  annotation_theme <- theme(plot.title = element_text(face = "bold", size = 13))
  panel_title <- function(p) labs(title = paste0('palette = "', p, '"'))
  # Six small panels in three columns: smaller text than a full-width plot,
  # and the year labels of each panel chosen for a figure with three columns.
  small <- list(title_size = 11, axis_title_size = 9, axis_text_size = 8,
                strip_text_size = 9, legend_text_size = 9)
  in_grid <- function(p) ALSCL:::.acl_tidy_axes(p, outer_cols = 3L)
  # Under the default style the SSB line keeps the stock color whatever the
  # palette; without a stock color it takes the line color of the palette.
  ssb <- lapply(palettes, function(p) {
    suppressMessages(acl_theme_reset())
    do.call(acl_theme_set, c(list(palette = p, stock_color = NULL), small))
    in_grid(plot_SSB(b, se = TRUE, title = paste0('palette = "', p, '"')))
  })
  compare <- lapply(palettes, function(p) {
    suppressMessages(acl_theme_reset())
    do.call(acl_theme_set, c(list(palette = p), small))
    in_grid(plot_compare_ts(a, b, quantities = "SSB", se = TRUE) + panel_title(p))
  })
  suppressMessages(acl_theme_reset())
  save_grid_free_plot(file.path(out, "ssb_by_palette.png"),
    wrap_plots(ssb, ncol = 3) + plot_annotation(
      title = "plot_SSB(b, se = TRUE) under each palette, after acl_theme_set(stock_color = NULL)",
      subtitle = "With the default stock color the line is #047c6c under every palette",
      theme = annotation_theme), width = 10, height = 6.5)
  save_grid_free_plot(file.path(out, "compare_by_palette.png"),
    wrap_plots(compare, ncol = 3) + plot_annotation(
      title = 'plot_compare_ts(a, b, quantities = "SSB", se = TRUE) under each palette',
      theme = annotation_theme), width = 10, height = 7.5)
}
draw_under_palettes()
cat("Wrote", length(list.files(out)), "files to", out, "\n")
