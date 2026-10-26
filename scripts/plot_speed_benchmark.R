# Figures for docs/SPEED.md from the saved benchmark results, without refitting.
# Rscript scripts/plot_speed_benchmark.R [results_dir] [figures_dir]
# timing:    elapsed time per fit, original code against the speed settings
#            (docs/results/speed/runs.csv and summary.csv).
# agreement: every reported estimate and standard error of one fit, original
#            code against the speed settings (agreement_YTF_ALSCL.csv).
args <- commandArgs(trailingOnly = TRUE)
results <- if (length(args)) args[1] else 'docs/results/speed'
figures <- if (length(args) > 1) args[2] else 'docs/figures/speed'
dir.create(figures, recursive = TRUE, showWarnings = FALSE)
runs <- read.csv(file.path(results, 'runs.csv'))
summary <- read.csv(file.path(results, 'summary.csv'))
settings <- c(original = 'Original code (ALSCL 2.0.0)',
              cppad_par = 'Default: parallel standard errors (CppAD)',
              tmbad_par = 'Option: framework = "TMBad"')
cols <- c(original = '#8a8984', cppad_par = '#2a78d6', tmbad_par = '#eb6834')
pchs <- c(original = 21, cppad_par = 22, tmbad_par = 24)
ink <- '#0b0b0b'; muted <- '#52514e'; reference <- '#e6e5e1'
render <- function(name, draw, width = 10, height = 5) {
  svg(file.path(figures, paste0(name, '.svg')), width = width, height = height,
      family = 'sans', bg = 'white'); draw(); dev.off()
  png(file.path(figures, paste0(name, '.png')), width = width * 160, height = height * 160,
      res = 160, type = 'cairo', bg = 'white'); draw(); dev.off()
}
load <- range(runs$load, na.rm = TRUE)

render('timing', function() {
  par(mfrow = c(1, 2), mar = c(4.5, 6.5, 3, 1), oma = c(5.5, 0, 2.2, 0), las = 1,
      col.axis = muted, col.lab = ink, fg = muted)
  cases <- c('tuna', 'flatfish', 'YTF')
  labels <- c(tuna = 'Tuna\n(20 quarters)', flatfish = 'Flatfish\n(20 years)', YTF = 'YTF_example\n(20 years)')
  for (model in c('ACL', 'ALSCL')) {
    r <- runs[runs$model == model & runs$config %in% names(settings), ]
    s <- summary[summary$model == model & summary$config %in% names(settings), ]
    xmax <- max(r$elapsed) * 1.32
    plot(NA, xlim = c(0, xmax), ylim = c(.5, 3.5), yaxt = 'n', xaxs = 'i',
         xlab = 'Elapsed time per fit (s)', ylab = '', main = model, col.main = ink)
    axis(2, at = 1:3, labels = labels[cases], tick = FALSE, cex.axis = .85)
    for (k in seq_along(cases)) for (j in seq_along(settings)) {
      cfg <- names(settings)[j]; y <- k + (2 - j) * .25
      t <- r$elapsed[r$case == cases[k] & r$config == cfg]
      m <- s[s$case == cases[k] & s$config == cfg, ]
      points(t, rep(y, length(t)), pch = 16, cex = .55, col = adjustcolor(cols[cfg], .45))
      points(m$median_seconds, y, pch = pchs[cfg], bg = cols[cfg], col = 'white', cex = 1.5, lwd = 1.2)
      # Label to the right of the slowest run, so that labels do not cover points.
      text(max(t, m$median_seconds), y, pos = 4, offset = .6, cex = .72, col = ink,
           labels = if (cfg == 'original') sprintf('%.1f s', m$median_seconds)
                    else sprintf('%.1f s (%.2fx)', m$median_seconds, m$speedup))
    }
  }
  mtext('Fit time before and after the speed settings', side = 3, outer = TRUE, font = 2,
        col = ink, line = .6)
  par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
  plot(0, 0, type = 'n', bty = 'n', xaxt = 'n', yaxt = 'n')
  legend('bottom', legend = settings, pch = pchs, pt.bg = cols, col = 'white', pt.cex = 1.4,
         ncol = 3, bty = 'n', cex = .8, text.col = ink, inset = c(0, .07), x.intersp = .7,
         text.width = max(strwidth(settings, cex = .8)) * 1.12)
  mtext(sprintf(paste('Large symbol: median of 3 runs; small dots: each run; (x): speed-up relative to',
                      'the original code. Apple M2 Pro, shared with other jobs (load average %.0f-%.0f on 10 cores).'),
                load[1], load[2]), side = 1, line = -1.2, cex = .68, col = muted)
}, height = 5.4)

# The agreement file holds the original values and the exact differences of
# each setting from them (setting minus original), because R does not parse
# decimal strings with correct rounding: a difference of 0 reads back exactly.
agreement <- file.path(results, 'agreement_YTF_ALSCL.csv')
if (file.exists(agreement)) {
  a <- read.csv(agreement)
  render('agreement', function() {
    par(mfrow = c(1, 2), mar = c(4.5, 6.4, 3, 2), oma = c(4.2, 0, 2.2, 0), las = 1,
        col.axis = muted, col.lab = ink, fg = muted)
    panels <- list(c('estimate', 'Estimate'), c('std_error', 'Standard error'))
    for (p in panels) {
      x <- a[[paste0('original_', p[1])]]
      diff <- function(cfg) a[[paste0(cfg, '_', p[1], '_diff')]]
      keep <- is.finite(x) & x > 0
      lim <- range(x[keep])
      plot(NA, xlim = lim, ylim = lim, log = 'xy', main = p[2], col.main = ink,
           xlab = paste(p[2], 'with the original code'), ylab = '')
      title(ylab = paste(p[2], 'with the speed setting'), line = 5)
      abline(0, 1, col = reference, lwd = 2)
      for (cfg in c('tmbad_par', 'cppad_par')) {
        y <- x + diff(cfg)
        points(x[keep], y[keep], pch = pchs[cfg], cex = .55, col = cols[cfg],
               bg = adjustcolor(cols[cfg], .35), lwd = .6)
      }
      rel <- function(cfg) { ok <- is.finite(x) & x != 0; max(abs(diff(cfg)[ok]) / abs(x[ok])) }
      describe <- function(cfg) if (all(diff(cfg) == 0, na.rm = TRUE)) 'identical (every difference 0)'
                                else sprintf('max. relative difference %.1e', rel(cfg))
      legend('topleft', bty = 'n', cex = .75, text.col = ink, pch = pchs[c('cppad_par', 'tmbad_par')],
             col = cols[c('cppad_par', 'tmbad_par')], pt.bg = adjustcolor(cols[c('cppad_par', 'tmbad_par')], .35),
             legend = c(paste('Default:', describe('cppad_par')), paste('TMBad:', describe('tmbad_par'))))
    }
    mtext('Results before and after the speed settings: ALSCL fitted to YTF_example', side = 3,
          outer = TRUE, font = 2, col = ink, line = .6)
    mtext(sprintf(paste('Each point is one row of summary(sdreport) (%s rows: fixed effects, random effects and',
                        'ADREPORT quantities; positive values shown on log scales).\nPoints on the grey line are',
                        'equal; the default settings reproduce the original code exactly.'),
                  format(nrow(a), big.mark = ',')), side = 1, outer = TRUE, line = 2.6, cex = .72, col = muted)
  }, height = 5.4)
}
cat('Figures written to', figures, '\n')
