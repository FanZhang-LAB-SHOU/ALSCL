# Speed benchmark: the original code against the speed settings of alscl_speed().
#
# Every fit runs in a fresh R process. Results are compared with the original
# code: estimates, objective, standard errors (every row of est_std) and SSB.
#
# Usage, from the repository root (needs pkgload):
#   git archive 4dc1fc3 | (mkdir -p /tmp/alscl-original && tar -x -C /tmp/alscl-original)
#   Rscript scripts/benchmark_speed.R /tmp/alscl-original [output_dir] [repeats]
# The original source is the version before the speed changes (ALSCL 2.0.0,
# commit 4dc1fc3). On macOS, set LC_ALL=en_US.UTF-8 if the path is not ASCII.
args <- commandArgs(trailingOnly = TRUE)

# ---- One fit, in a child process --------------------------------------------
if (length(args) && args[1] == "--child") {
  src <- args[2]; config <- args[3]; case <- args[4]; model <- args[5]
  out <- args[6]; repo <- args[7]; cache <- args[8]
  suppressMessages(pkgload::load_all(src, quiet = TRUE, export_all = FALSE))
  options(ALSCL.tmb.cache = cache)
  settings <- list(original = NULL,
                   cppad_seq = list(sd_cores = 1, framework = "CppAD"),
                   cppad_par = list(sd_cores = "auto", framework = "CppAD"),
                   tmbad_seq = list(sd_cores = 1, framework = "TMBad"),
                   tmbad_par = list(sd_cores = "auto", framework = "TMBad"))[[config]]
  if (!is.null(settings)) do.call(alscl_speed, settings)
  # Fit arguments for each case. YTF_example uses its bundled conditional
  # configuration; flatfish and tuna follow scripts/case_studies.R.
  if (case == "YTF") {
    x <- YTF_example
    fit_args <- c(x[c("data.CatL", "data.wgt", "data.mat")], x$fit_args,
                  x$fit_config[[tolower(model)]])
  } else {
    z <- readRDS(file.path(repo, "docs", "data", "cases", case, "truth.rds"))
    pa <- z$parameters; sm <- z$truth
    years <- 2000 + (seq_len(sm$nyear) - 1) * pa$growth_step
    frame <- function(m) {
      d <- data.frame(LengthBin = as.character(pa$len_mid), m, check.names = FALSE)
      names(d) <- c("LengthBin", as.character(years)); d
    }
    p <- if (model == "ACL") list(log_Linf = log(pa$Linf), log_vbk = log(pa$vbk), t0 = pa$t0,
           log_cv_len = log(pa$cv_L), log_std_log_F = log(pa$F_sd),
           log_std_log_N0 = log(pa$std_logN0), logit_log_R = qlogis(pa$R_ar))
         else list(log_Linf = log(pa$Linf), log_vbk = log(pa$vbk), log_t0 = log(pa$t0),
           log_cv_len = log(pa$cv_L), log_cv_grow = log(pa$cv_inc), log_sigma_log_F = log(pa$F_sd),
           log_sigma_log_N0 = log(pa$std_logN0), logit_log_R = qlogis(pa$R_ar))
    m <- lapply(p, function(v) factor(NA))
    if (model == "ALSCL") m$logit_log_F_l <- m$logit_log_F_y <- factor(NA)
    fit_args <- list(data.CatL = frame(t(sm$SN_at_len)), data.wgt = frame(sm$weight),
                     data.mat = frame(sm$mat), rec.age = pa$rec.age, nage = pa$nage, M = pa$M,
                     sel_L50 = pa$q_surv_L50, sel_L95 = pa$q_surv_L95, len_mid = pa$len_mid,
                     len_border = pa$len_border[-c(1, length(pa$len_border))],
                     growth_step = pa$growth_step, parameters = p, map = m)
  }
  fit_args <- c(fit_args, list(train_times = 2, nstarts = 1, ncores = 1, silent = TRUE))
  invisible(utils::capture.output(ALSCL:::.acl_compile(model)))  # compile outside the timing
  if (out == "-") quit(save = "no")  # warm-up: compile only
  fun <- if (model == "ACL") run_acl else run_alscl
  # CPU time includes forked workers (collected by mclapply) and is less
  # affected than elapsed time by other jobs on a shared computer.
  timing <- system.time(fit <- do.call(fun, fit_args))
  cpu <- sum(timing[c("user.self", "sys.self", "user.child", "sys.child")], na.rm = TRUE)
  saveRDS(list(elapsed = timing[["elapsed"]], cpu = cpu, par = fit$opt$par, objective = fit$opt$objective,
               est_std = fit$est_std, SSB = fit$report$SSB, convergence = fit$convergence_code,
               pdHess = fit$pdHess, max_gradient = fit$max_abs_gradient,
               # Rows of summary(sdreport): fixed effects, random effects and ADREPORT.
               n_report = if (is.null(fit$est_std)) 0L else nrow(fit$est_std),
               n_fixed = length(fit$opt$par), n_random = length(fit$obj$env$random)), out)
  quit(save = "no")
}

# ---- Driver ------------------------------------------------------------------
original <- normalizePath(args[1], mustWork = TRUE)
repo <- normalizePath(".", mustWork = TRUE)
out <- if (length(args) > 1) args[2] else "docs/results/speed"
repeats <- if (length(args) > 2) as.integer(args[3]) else 2L
stopifnot(file.exists(file.path(repo, "R", "speed.R")), repeats >= 1L)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
work <- tempfile("alscl-speed-")
dir.create(work)
cache <- c(original = file.path(work, "cache-original"), new = file.path(work, "cache-new"))
script <- normalizePath("scripts/benchmark_speed.R")
configs <- c("original", "cppad_seq", "cppad_par", "tmbad_seq", "tmbad_par")
cases <- expand.grid(model = c("ACL", "ALSCL"), case = c("YTF", "flatfish", "tuna"),
                     stringsAsFactors = FALSE)
# One-minute load average, to show how busy the computer was during a fit.
load_average <- function() tryCatch({
  if (file.exists("/proc/loadavg")) scan("/proc/loadavg", n = 1, quiet = TRUE)
  else as.numeric(strsplit(trimws(gsub("[{}]", "", system("sysctl -n vm.loadavg", intern = TRUE))), " +")[[1]][1])
}, error = function(e) NA_real_, warning = function(w) NA_real_)
run_child <- function(config, case, model, file) {
  src <- if (config == "original") original else repo
  status <- system2(file.path(R.home("bin"), "Rscript"),
    shQuote(c(script, "--child", src, config, case, model, file, repo,
              cache[[if (config == "original") "original" else "new"]])),
    stdout = FALSE, stderr = FALSE)
  if (status != 0L || (file != "-" && !file.exists(file)))
    stop("Fit failed: ", config, " ", case, " ", model)
  if (file != "-") readRDS(file)
}
writeLines(c(paste("UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("R:", R.version.string), paste("Platform:", R.version$platform),
  paste("TMB:", utils::packageVersion("TMB")), paste("RcppEigen:", utils::packageVersion("RcppEigen")),
  paste("Matrix:", utils::packageVersion("Matrix")),
  paste("Logical CPUs:", parallel::detectCores()),
  paste("Physical CPUs:", parallel::detectCores(logical = FALSE)),
  paste("Repeats:", repeats), "Each fit: train_times = 2, nstarts = 1, in a fresh R process;",
  "compilation excluded; timing covers run_acl()/run_alscl() including standard errors.",
  "Other user processes may share this computer."), file.path(out, "environment.txt"))

# Warm-up: compile every template once per source tree and AD library.
for (model in c("ACL", "ALSCL")) for (config in c("original", "cppad_seq", "tmbad_seq"))
  run_child(config, "YTF", model, "-")

runs <- list(); fits <- list()
for (rep in seq_len(repeats)) for (i in seq_len(nrow(cases))) {
  # Rotate the order of configurations to reduce order effects.
  order <- configs[((seq_along(configs) + rep + i - 3L) %% length(configs)) + 1L]
  for (config in order) {
    key <- paste(cases$case[i], cases$model[i], config, rep, sep = "_")
    message(format(Sys.time(), "%H:%M:%S"), " ", key)
    f <- run_child(config, cases$case[i], cases$model[i], file.path(work, paste0(key, ".rds")))
    fits[[key]] <- f
    runs[[key]] <- data.frame(case = cases$case[i], model = cases$model[i], config = config,
      repetition = rep, elapsed = f$elapsed, cpu = f$cpu,
      load = load_average(),
      objective = f$objective, convergence = f$convergence,
      pdHess = f$pdHess, max_gradient = f$max_gradient, n_fixed = f$n_fixed,
      n_random = f$n_random, n_report = f$n_report)
    utils::write.csv(do.call(rbind, runs), file.path(out, "runs.csv"), row.names = FALSE)
  }
}
runs <- do.call(rbind, runs)

# Compare each configuration with the original code (first repetition).
rel <- function(a, b) max(abs(a - b) / pmax(abs(b), .Machine$double.xmin))
# Differences in reported quantities relative to the largest absolute value of
# the same quantity, so that values near zero (for example random effects)
# do not inflate relative differences.
scaled <- function(a, b, quantity)
  max(abs(a - b) / pmax(stats::ave(abs(b), quantity, FUN = max), .Machine$double.xmin))
summary <- do.call(rbind, lapply(seq_len(nrow(cases)), function(i) do.call(rbind, lapply(configs, function(config) {
  ref <- fits[[paste(cases$case[i], cases$model[i], "original", 1, sep = "_")]]
  f <- fits[[paste(cases$case[i], cases$model[i], config, 1, sep = "_")]]
  this <- runs$case == cases$case[i] & runs$model == cases$model[i]
  t <- runs$elapsed[this & runs$config == config]; t0 <- runs$elapsed[this & runs$config == "original"]
  cpu <- runs$cpu[this & runs$config == config]; cpu0 <- runs$cpu[this & runs$config == "original"]
  data.frame(case = cases$case[i], model = cases$model[i], config = config,
    n_fixed = f$n_fixed, n_random = f$n_random, n_report = f$n_report,
    median_seconds = stats::median(t), speedup = stats::median(t0) / stats::median(t),
    median_cpu_seconds = stats::median(cpu), cpu_ratio = stats::median(cpu0) / stats::median(cpu),
    identical_estimates = identical(f$par, ref$par) && identical(f$objective, ref$objective),
    identical_std_errors = identical(f$est_std, ref$est_std),
    par_rel_diff = rel(f$par, ref$par), objective_abs_diff = abs(f$objective - ref$objective),
    estimate_scaled_diff = scaled(f$est_std[, 1], ref$est_std[, 1], rownames(ref$est_std)),
    std_error_rel_diff = rel(f$est_std[, 2], ref$est_std[, 2]),
    SSB_rel_diff = rel(f$SSB, ref$SSB))
}))))
utils::write.csv(summary, file.path(out, "summary.csv"), row.names = FALSE)
print(summary, digits = 3)
unlink(work, recursive = TRUE)
