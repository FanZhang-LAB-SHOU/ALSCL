# Run from the repository root; no model fitting or cached assessments required.
library(ggplot2)
library(patchwork)
source('scripts/plot_helpers.R')
local({
  out <- tempfile('alscl-export-test-')
  dir.create(out)
  on.exit(unlink(out, recursive = TRUE))
  p <- ggplot(data.frame(x = 1:3, y = 1:3), aes(x, y)) + geom_line() +
    theme_bw() + theme(panel.grid.major = element_blank(),
                       panel.grid.minor = element_blank())
  save_grid_free_plot(file.path(out, 'valid.png'), p, width = 3, height = 2)
  stopifnot(file.info(file.path(out, 'valid.png'))$size > 0)
  # One grid in any axis, including a non-final nested panel, must stop export.
  for (element in c('panel.grid.major.x', 'panel.grid.major.y',
                    'panel.grid.minor.x', 'panel.grid.minor.y')) {
    bad <- p + do.call(theme, setNames(list(element_line()), element))
    for (plot in list(bad, (bad | p) / (p | p), p / (p | bad))) {
      target <- file.path(out, 'rejected.png')
      err <- tryCatch({save_grid_free_plot(target, plot, width = 3, height = 2); NULL},
                      error = identity)
      stopifnot(inherits(err, 'error'), grepl('visible grid', conditionMessage(err)),
                !file.exists(target))
    }
  }
  # Empty patchwork layout containers are not drawn panels.
  save_grid_free_plot(file.path(out, 'nested.png'),
                      (p | plot_spacer()) / (p | p), width = 4, height = 4)
  stopifnot(file.info(file.path(out, 'nested.png'))$size > 0)
  # Refusing an export must also leave any pre-existing image untouched.
  target <- file.path(out, 'valid.png')
  before <- tools::md5sum(target)
  tryCatch(save_grid_free_plot(target, p + theme_bw()), error = function(e) NULL)
  stopifnot(identical(tools::md5sum(target), before))
  cat('PASS: valid and nested exports; all 12 invalid-grid exports rejected; existing file preserved.\n')
})
