# Figures for docs/SPEED.md from the saved benchmark results, without refitting.
# Rscript scripts/plot_speed_benchmark.R [results_dir] [figures_dir]
# timing:    elapsed time per fit, original code against the speed settings
#            (docs/results/speed/runs.csv and summary.csv).
# agreement: every reported estimate and standard error of one fit, original
#            code against the speed settings (agreement_YTF_ALSCL.csv).
# The figures use the package style (theme_acl(), acl_palette()); loading the
# checkout does not fit anything.
suppressPackageStartupMessages(library(ggplot2))
suppressMessages(pkgload::load_all('.', quiet = TRUE, export_all = FALSE))
source('scripts/plot_helpers.R')
suppressMessages(acl_theme_reset())
args <- commandArgs(trailingOnly = TRUE)
results <- if (length(args)) args[1] else 'docs/results/speed'
figures <- if (length(args) > 1) args[2] else 'docs/figures/speed'
dir.create(figures, recursive = TRUE, showWarnings = FALSE)
runs <- read.csv(file.path(results, 'runs.csv'))
summary <- read.csv(file.path(results, 'summary.csv'))
# Facts for the captions come from the result files, not from this script.
environment_file <- file.path(results, 'environment.txt')
recorded <- if (file.exists(environment_file)) readLines(environment_file) else character()
field <- function(name) {
  line <- grep(paste0('^', name, ': '), recorded, value = TRUE)
  if (length(line)) sub(paste0('^', name, ': '), '', line[1L]) else NA_character_
}
n_runs <- unique(as.vector(table(runs$case, runs$model, runs$config)))
runs_text <- if (length(n_runs) == 1L) sprintf('median of %d runs', n_runs) else 'median of the runs'
computer <- if (is.na(field('CPU'))) 'Computer' else field('CPU')
cores <- if (is.na(field('Logical CPUs'))) '' else sprintf(' on %s cores', field('Logical CPUs'))
settings <- c(original = 'Original code (ALSCL 2.0.0)',
              cppad_par = 'Default, parallel standard errors (CppAD)',
              tmbad_par = 'Option framework = "TMBad"')
# The original code is a gray reference; the two speed settings take the
# primary and accent colors of the package style.
cols <- c(original = 'grey55', cppad_par = unname(acl_palette(role = 'primary')),
          tmbad_par = unname(acl_palette(role = 'accent')))
shapes <- c(original = 21, cppad_par = 22, tmbad_par = 24)
load <- range(runs$load, na.rm = TRUE)
case_names <- c(tuna = 'Tuna\n(20 quarters)', flatfish = 'Flatfish\n(20 years)',
                YTF = 'YTF_example\n(20 years)')

# Elapsed time per fit: each run (small dots) and the median (large symbol,
# labeled with the time and the speed-up relative to the original code).
r <- runs[runs$config %in% names(settings), ]
m <- summary[summary$config %in% names(settings), ]
for (nm in c('r', 'm')) {
  z <- get(nm)
  z$case <- factor(case_names[z$case], levels = case_names)
  z$config <- factor(z$config, levels = names(settings))
  assign(nm, z)
}
slowest <- aggregate(elapsed ~ case + model + config, r, max)
m <- merge(m, setNames(slowest, c('case', 'model', 'config', 'slowest')))
m$label <- ifelse(m$config == 'original', sprintf('%.1f s', m$median_seconds),
                  sprintf('%.1f s (%.2fx)', m$median_seconds, m$speedup))
dodge <- position_dodge(width = .75)
p <- ggplot(m, aes(median_seconds, case, group = config)) +
  geom_point(data = r, aes(elapsed, case, colour = config), position = dodge,
             size = .9, alpha = .5, show.legend = FALSE) +
  geom_point(aes(fill = config, shape = config), position = dodge, size = 3, colour = 'white', stroke = .6) +
  geom_text(aes(x = pmax(slowest, median_seconds), label = label), position = dodge,
            hjust = -.15, size = 2.9) +
  facet_wrap(~model, scales = 'free_x') +
  scale_colour_manual(values = cols, guide = 'none') +
  scale_fill_manual(values = cols, labels = settings, name = NULL) +
  scale_shape_manual(values = shapes, labels = settings, name = NULL) +
  scale_x_continuous(limits = c(0, NA), expand = expansion(mult = c(0, .35))) +
  labs(x = 'Elapsed time per fit (seconds)', y = NULL,
       title = 'Fit time before and after the speed settings',
       caption = sprintf(paste('Large symbols give the %s, small dots single runs, and the number in parentheses',
                               'the speed-up relative to the original code.\n%s, shared with other jobs',
                               '(load average %.0f-%.0f%s).'),
                         runs_text, computer, load[1], load[2], cores)) +
  theme_acl() + guides(fill = guide_legend(nrow = 1), shape = guide_legend(nrow = 1))
# Nine rows of symbols and labels need more height than acl_figure_size() gives a facet.
save_grid_free_plot(file.path(figures, 'timing.png'), p, height = 6.2)

# The agreement file holds the original values and the exact differences of
# each setting from them (setting minus original), because R does not parse
# decimal strings with correct rounding: a difference of 0 reads back exactly.
agreement <- file.path(results, 'agreement_YTF_ALSCL.csv')
if (file.exists(agreement)) {
  a <- read.csv(agreement)
  panels <- c(estimate = 'Estimate', std_error = 'Standard error')
  d <- do.call(rbind, lapply(names(panels), function(k) {
    x <- a[[paste0('original_', k)]]
    do.call(rbind, lapply(c('tmbad_par', 'cppad_par'), function(cfg) {
      diff <- a[[paste0(cfg, '_', k, '_diff')]]
      data.frame(panel = panels[[k]], config = cfg, original = x, new = x + diff, diff = diff)
    }))
  }))
  d <- d[is.finite(d$original) & d$original > 0, ]
  d$panel <- factor(d$panel, levels = panels)
  d$config <- factor(d$config, levels = c('cppad_par', 'tmbad_par'))
  # A small number with a power of ten and a raised exponent, as on the log
  # axes, rather than in E notation such as "1.4e-12".
  power_of_ten <- function(v) {
    parts <- strsplit(sprintf('%.1e', v), 'e', fixed = TRUE)[[1]]
    exponent <- chartr('-0123456789', '\u207b\u2070\u00b9\u00b2\u00b3\u2074\u2075\u2076\u2077\u2078\u2079',
                       as.character(as.integer(parts[2])))
    paste0(parts[1], ' \u00d7 10', exponent)
  }
  # The largest relative difference of each setting in each panel.
  describe <- function(z) {
    if (all(z$diff == 0)) return('identical (every difference 0)')
    paste('largest relative difference', power_of_ten(max(abs(z$diff) / abs(z$original))))
  }
  # Panel names carry the largest difference of each setting.
  strips <- vapply(levels(d$panel), function(k) paste0(k, '\nDefault ',
    describe(d[d$panel == k & d$config == 'cppad_par', ]), '\nTMBad ',
    describe(d[d$panel == k & d$config == 'tmbad_par', ])), character(1))
  d$panel <- factor(strips[as.character(d$panel)], levels = strips)
  note_cols <- cols[c('cppad_par', 'tmbad_par')]
  exact_default <- all(a$cppad_par_estimate_diff == 0, na.rm = TRUE) &&
    all(a$cppad_par_std_error_diff == 0, na.rm = TRUE)
  p <- ggplot(d, aes(original, new)) +
    geom_abline(slope = 1, intercept = 0, colour = 'grey55', linewidth = .8) +
    geom_point(aes(colour = config, fill = config, shape = config), size = 1.1, stroke = .4, alpha = .7) +
    facet_wrap(~panel, scales = 'free') +
    # Tick labels as powers of ten (10 with a raised exponent), not "1e-04".
    scale_x_log10(labels = scales::label_log()) + scale_y_log10(labels = scales::label_log()) +
    scale_colour_manual(values = note_cols, labels = settings[names(note_cols)], name = NULL) +
    scale_fill_manual(values = note_cols, labels = settings[names(note_cols)], name = NULL) +
    scale_shape_manual(values = shapes[names(note_cols)], labels = settings[names(note_cols)], name = NULL) +
    labs(x = 'Value with the original code', y = 'Value with the speed setting',
         title = 'Results before and after the speed settings',
         subtitle = 'ALSCL fitted to YTF_example',
         caption = sprintf(paste('Each point is one reported value of the fit, %s values of fixed effects, random effects',
                                 'and derived quantities (positive values, log scales).\nPoints on the gray line are equal; %s'),
                           format(nrow(a), big.mark = ','),
                           if (exact_default) 'the default settings reproduce the original code exactly.'
                           else 'the panel names give the largest relative difference of each setting.')) +
    theme_acl() + theme(aspect.ratio = 1) +
    guides(colour = guide_legend(override.aes = list(size = 3, alpha = 1)))
  # Two square panels side by side; acl_figure_size() treats a fixed aspect ratio as one square plot.
  save_grid_free_plot(file.path(figures, 'agreement.png'), p, width = 10, height = 7)
}
cat('Figures written to', figures, '\n')
