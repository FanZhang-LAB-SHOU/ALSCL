# Render measured timings and worker intervals, without rerunning fits.
# Rscript scripts/plot_parallel_benchmark.R [results_dir] [figures_dir]
# The figures use the package style (theme_acl(), compare colors); loading
# the checkout does not fit anything.
suppressPackageStartupMessages(library(ggplot2))
suppressMessages(pkgload::load_all('.', quiet = TRUE, export_all = FALSE))
source('scripts/plot_helpers.R')
args <- commandArgs(trailingOnly = TRUE)
results <- if (length(args)) args[1] else 'docs/results/parallel'
figures <- if (length(args) > 1) args[2] else 'docs/figures/parallel'
dir.create(figures, recursive = TRUE, showWarnings = FALSE)
s <- read.csv(file.path(results, 'summary.csv'))
r <- read.csv(file.path(results, 'runs.csv'))
d <- read.csv(file.path(results, 'starts.csv'))
suppressMessages(acl_theme_reset())
cols <- setNames(acl_theme('compare_colors'), c('ACL', 'ALSCL'))
meta <- readLines(file.path(results, 'environment.txt'))
years <- sub('.*; ([0-9]+) years.*', '\\1', grep('^Data:', meta, value = TRUE))
cpu <- sub('^CPU: ', '', grep('^CPU:', meta, value = TRUE))
if (!length(cpu)) cpu <- 'Computer'

# Total fit time against the number of workers: each run (open circles), the
# range of the runs (error bars) and the median (line and filled points).
s$label <- sprintf('%.2f s\n%.2fx', s$median_seconds, s$speedup)
p <- ggplot(s, aes(ncores, median_seconds, colour = model)) +
  geom_point(data = r, aes(ncores, elapsed_seconds), shape = 1, size = 2, alpha = .6) +
  geom_errorbar(aes(ymin = min_seconds, ymax = max_seconds), width = .12) +
  geom_line(linewidth = .8) + geom_point(size = 2.6) +
  geom_text(aes(y = max_seconds, label = label), vjust = -.35, size = 3, lineheight = .9,
            colour = 'black', show.legend = FALSE) +
  facet_wrap(~model, scales = 'free_y') +
  scale_colour_manual(values = cols, guide = 'none') +
  scale_x_continuous(breaks = c(1, 2, 4), limits = c(.6, 4.4)) +
  scale_y_continuous(expand = expansion(mult = c(0, .3))) + expand_limits(y = 0) +
  labs(x = 'Number of worker processes (ncores)', y = 'Total fit time (seconds)',
       title = 'Total fit time with one, two and four worker processes',
       subtitle = 'The same four starting points, each with two optimizer passes',
       caption = sprintf(paste('Median and range of %s runs. Synthetic YTF data, %s years.',
                               '%s shared with other jobs. Labels give the median time and the speed-up.'),
                         paste(unique(s$repetitions), collapse = ' or '), years, cpu)) +
  theme_acl()
# One row of two panels: acl_figure_size() gives a facet row too little height for the labels.
save_grid_free_plot(file.path(figures, 'timing.png'), p, height = 5.5)

# Worker intervals of the first run with four workers.
first <- r[r$ncores == 4 & r$repetition == 1, ]
z <- do.call(rbind, lapply(seq_len(nrow(first)), function(i) {
  run <- first[i, ]
  zz <- d[d$run_id == run$run_id, ]
  offset <- min(zz$started_at)
  data.frame(model = run$model, start = factor(paste('Start', zz$start_id), levels = paste('Start', 4:1)),
             from = zz$started_at - offset, to = zz$finished_at - offset, pid = zz$pid,
             panel = sprintf('%s, worker CPU time %.2f s, elapsed %.2f s', run$model,
                             sum(zz$cpu_seconds), max(zz$finished_at - offset)))
}))
p <- ggplot(z, aes(y = start, colour = model)) +
  geom_segment(aes(x = from, xend = to, yend = start), linewidth = 7, alpha = .85) +
  geom_text(aes(x = (from + to) / 2, label = paste('Process', pid)), colour = 'white', size = 3) +
  facet_wrap(~panel, scales = 'free_x') +
  scale_colour_manual(values = cols, guide = 'none') + expand_limits(x = 0) +
  labs(x = 'Seconds since the first worker started', y = NULL,
       title = 'Four fitting processes run at the same time',
       caption = paste('First run with four workers. The bars cover building the TMB objective',
                       'and the optimization only.')) +
  theme_acl()
save_grid_free_plot(file.path(figures, 'worker-timeline.png'), p, height = 4.2)
cat('Figures written to', figures, '\n')
