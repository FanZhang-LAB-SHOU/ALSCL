# Draw the five ggsci palettes that acl_theme_set(palette = ...) accepts, the
# roles each colour takes in the plots, and the same two figures under every
# palette. Run from the repository root:
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
palettes <- c("npg", "aaas", "nejm", "lancet", "jama")

# 1. Swatches: one row per palette, hex codes, and the role of each colour.
swatch <- do.call(rbind, lapply(palettes, function(p) {
  cols <- ALSCL:::.acl_palette(p)
  roles <- ALSCL:::.acl_palette_roles(p)
  role <- rep("", length(cols))
  role[match(roles$line_color, cols)] <- "line, interval"
  role[match(roles$observed_color, cols)] <- "observed"
  role[match(roles$smooth_color, cols)] <- "smoother"
  data.frame(palette = p, index = seq_along(cols), hex = cols, role = role)
}))
swatch$palette <- factor(swatch$palette, levels = rev(palettes))
swatch$text <- ifelse(nzchar(swatch$role), paste0(swatch$hex, "\n", swatch$role), swatch$hex)
p_swatch <- ggplot(swatch, aes(index, palette)) +
  geom_tile(aes(fill = hex), width = 0.92, height = 0.8) +
  geom_text(aes(label = text), size = 2.4, lineheight = 0.9) +
  scale_fill_identity() +
  scale_x_continuous(breaks = 1:10, expand = expansion(add = 0.3)) +
  labs(x = "Colour index", y = NULL,
       title = "Palettes accepted by acl_theme_set(palette = ...)",
       subtitle = "Labelled colours are the ones the plots use by default: line and interval, observed points or second model, smoother") +
  theme_bw(base_size = 11) +
  theme(panel.grid = element_blank(), axis.text.y = element_text(face = "bold"))
save_grid_free_plot(file.path(out, "palettes.png"), p_swatch, width = 11, height = 4.2, dpi = 160, bg = "white")

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
  ssb <- lapply(palettes, function(p) {
    acl_theme_set(palette = p, base_theme = "bw", font_family = "sans")
    plot_SSB(b, se = TRUE) + labs(title = paste0('palette = "', p, '"'))
  })
  compare <- lapply(palettes, function(p) {
    acl_theme_set(palette = p, base_theme = "bw", font_family = "sans")
    plot_compare_ts(a, b, quantities = "SSB", se = TRUE) + labs(title = paste0('palette = "', p, '"'))
  })
  save_grid_free_plot(file.path(out, "ssb_by_palette.png"),
    wrap_plots(ssb, ncol = 3) + plot_annotation(title = "plot_SSB(b, se = TRUE) under each palette"),
    width = 12, height = 7, dpi = 160, bg = "white")
  save_grid_free_plot(file.path(out, "compare_by_palette.png"),
    wrap_plots(compare, ncol = 3) + plot_annotation(title = 'plot_compare_ts(a, b, quantities = "SSB", se = TRUE) under each palette'),
    width = 12, height = 7, dpi = 160, bg = "white")
}
draw_under_palettes()
cat("Wrote", length(list.files(out)), "files to", out, "\n")
