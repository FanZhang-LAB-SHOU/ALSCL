utils::globalVariables(c("Variable", "RetrospectiveYear"))

# Retain compact results rather than serializing a live TMB objective between
# processes. A failed fit still contributes a diagnostic row and a missing rho.
.acl_retro_fit <- function(peel, fit_args, model_type, silent) {
  started <- proc.time()
  end_col <- ncol(fit_args$data.CatL) - peel
  years <- suppressWarnings(as.numeric(sub("^X", "",
    colnames(fit_args$data.CatL)[seq.int(2L, end_col)])))
  error <- NULL
  fit <- tryCatch({
    for (name in c("data.CatL", "data.wgt", "data.mat"))
      fit_args[[name]] <- fit_args[[name]][, seq_len(end_col), drop = FALSE]
    do.call(if (model_type == "acl") run_acl else run_alscl, fit_args)
  }, error = function(e) {
    error <<- conditionMessage(e)
    NULL
  })
  if (!is.null(fit$year)) years <- fit$year
  elapsed <- (proc.time() - started)[["elapsed"]]
  diagnostics <- cbind(data.frame(Peel = peel,
    RetrospectiveYear = tail(years, 1L), elapsed = elapsed,
    error = if (is.null(error)) "" else error), .acl_fit_status(fit, error))
  if (!silent) cat(sprintf("  %s: %.1f sec%s\n",
    if (peel == 0L) "Full model" else paste("Peel", peel), elapsed,
    if (is.null(error)) "" else paste0(" (failed: ", error, ")")))
  list(peel = peel, year = years, diagnostics = diagnostics,
       variables = list(B = fit$report$B, Rec = fit$report$R %||% fit$report$Rec,
                        SSB = fit$report$SSB, N = fit$report$N))
}

.acl_retro_wrapper <- function(call, frame, model) {
  explicit <- setdiff(names(as.list(call)[-1L]), "...")
  args <- mget(explicit, envir = frame, inherits = FALSE)
  extra <- eval(quote(list(...)), envir = frame)
  extra_names <- names(extra) %||% rep("", length(extra))
  named <- nzchar(extra_names)
  if (anyNA(extra_names) || anyDuplicated(extra_names[named]))
    stop("Named additional retrospective arguments must be unique.", call. = FALSE)
  args[extra_names[named]] <- extra[named]
  bundled <- (is.list(args$nyear) && !is.data.frame(args$nyear)) ||
    (is.list(args$data.CatL) && !is.data.frame(args$data.CatL))
  # Preserve the historical ALSCL wrapper default for separate arguments;
  # a bundle supplies its own growth step and must not be overwritten.
  if (model == "alscl" && !bundled && !"growth_step" %in% names(args))
    args$growth_step <- 1
  args$model_type <- model
  do.call(retro_model, c(args, unname(extra[!named])))
}

#' Retrospective Analysis for ACL or ALSCL Models
#'
#' Conduct a retrospective analysis by sequentially removing the most recent
#' time steps of data and re-fitting the model. Computes Mohn's rho for SSB,
#' Recruitment, Biomass, and Abundance to quantify retrospective bias.
#' Supports both ACL and ALSCL model types via the `model_type` argument.
#'
#' @param nyear Integer. Number of time columns to peel sequentially. Default is
#'   5. One peel removes one model time step (one quarter for quarterly data).
#' @param data.CatL The Catch-at-Length data or the same named input bundle used
#'   by [run_acl()] or [run_alscl()]. For example, `retro_acl(x, nyear = 3)`.
#' @param data.wgt The weight data.
#' @param data.mat The maturity data.
#' @param rec.age The recruitment age.
#' @param nage The number of age classes.
#' @param M The natural mortality rate.
#' @param sel_L50 The length at 50 percent selectivity.
#' @param sel_L95 The length at 95 percent selectivity.
#' @param model_type Character. Model to use: `"acl"` (default) or `"alscl"`.
#' @param growth_step Time step in years. NULL uses recruitment age when below 1, otherwise 1.
#' @param parameters Optional custom starting parameter list.
#' @param parameters.L Optional lower bounds for parameters.
#' @param parameters.U Optional upper bounds for parameters.
#' @param map Optional TMB map argument for fixing parameters.
#' @param len_mid Optional numeric vector of length bin midpoints.
#' @param len_border Optional numeric vector of length bin borders.
#' @param len_lower Optional numeric vector of lower bin boundaries (ALSCL only).
#' @param len_upper Optional numeric vector of upper bin boundaries (ALSCL only).
#' @param train_times Numeric. Number of optimization restarts. Default is 1.
#' @param nstarts Positive integer. Number of independent starts per full/peel
#'   fit, run sequentially within each fit. Defaults to 1 or the bundle's nstarts.
#' @param ncores Integer. Number of CPU cores for parallel peel computation.
#'   Default is 1. A bundle's fitting ncores is ignored: specify this argument
#'   explicitly for peel workers. Each fit runs its nstarts sequentially with
#'   ncores = 1, avoiding nested fitting workers.
#' @param silent Logical. Suppress progress messages when TRUE. Numerical-screen
#'   warnings are still reported. Default is FALSE.
#' @param plot Logical. If TRUE, include plot in return value. Default is FALSE.
#' @param line_size Numeric. Line thickness. Default is 1.2.
#' @param point_size Numeric. Point size for endpoints. Default is 3.
#' @param point_shape Numeric. Point shape for endpoints. Default is 21.
#' @param facet_scales Character. Facet scales argument. Default is "free".
#' @param facet_col Integer or NULL. Number of facet columns.
#' @param facet_row Integer or NULL. Number of facet rows.
#' @param title Character or NULL. Custom plot title.
#' @param xlab Character or NULL. Custom x-axis label.
#' @param ylab Character or NULL. Custom y-axis label.
#' @param font_family Character or NULL. Font family.
#' @param title_size Numeric or NULL. Title size in pt.
#' @param axis_title_size Numeric or NULL. Axis title size in pt.
#' @param axis_text_size Numeric or NULL. Axis tick label size in pt.
#' @param strip_text_size Numeric or NULL. Facet label size in pt.
#' @param legend_text_size Numeric or NULL. Legend text size in pt.
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks.
#' @param base_theme Character or NULL. Base ggplot2 theme name.
#' @param title_hjust Numeric or NULL. Title horizontal alignment.
#' @param rho_digits Integer. Decimal places for Mohn's rho display. Default is 4.
#' @param rho_position Character. Position of rho text. Default is "top_right".
#' @param rho_size Numeric. Font size of rho text. Default is 3.5.
#' @inheritParams run_acl
#' @details Bundle settings use the same precedence as [run_acl()]: shared
#'   fit_args, selected fit_config, then explicit call arguments. Explicit map,
#'   parameters and control replace the complete corresponding list, including
#'   NULL. zero_action, control and nstarts are forwarded to every full/peel fit.
#'   The full fit and every requested peel must pass the numerical screen, and
#'   have finite terminal estimates with a nonzero reference, before a quantity's
#'   Mohn's rho is reported. Invalid or failed fits are not silently dropped.
#' @return A list containing `results`, `rho_text`, `last_points`, `model_type`,
#'   and optionally `plot`. `fit_diagnostics` records the full fit (Peel = 0)
#'   and every requested peel, including errors and numerical status.
#'   `rho_by_peel` contains screened Rho, diagnostic RawRho and Valid for each
#'   quantity and peel. `rho_text$Rho` is NA when any required fit or endpoint
#'   is invalid. `raw_rho_text` retains an unscreened mean for diagnosis only;
#'   it is NA if any terminal comparison is missing. `errors` lists fit errors.
#'   `results` retains available estimates, with NumericalOK and RawRho flags.
#' @export
#' @examples
#' \dontrun{
#' retro <- retro_model(nyear = 5, data.CatL, data.wgt, data.mat,
#'                      rec.age = 1, nage = 7, M = 0.8,
#'                      sel_L50 = 28, sel_L95 = 36, model_type = "acl")
#' plot_retro(retro)
#' retro <- retro_alscl(YTF_example, nyear = 3, F_structure = "year")
#' retro$fit_diagnostics
#' retro$rho_by_peel
#' }
retro_model <- function(nyear = 5, data.CatL, data.wgt, data.mat,
                        rec.age, nage, M, sel_L50, sel_L95,
                        model_type = c("acl", "alscl"),
                        growth_step = NULL,
                        parameters = NULL, parameters.L = NULL, parameters.U = NULL,
                        map = NULL, len_mid = NULL, len_border = NULL,
                        len_lower = NULL, len_upper = NULL,
                        train_times = 1, ncores = 1, silent = FALSE,
                        plot = FALSE,
                        line_size = 1.2, point_size = 3, point_shape = 21,
                        facet_scales = "free", facet_col = NULL, facet_row = NULL,
                        title = NULL, xlab = NULL, ylab = NULL,
                        font_family = NULL, title_size = NULL,
                        axis_title_size = NULL, axis_text_size = NULL,
                        strip_text_size = NULL, legend_text_size = NULL,
                        x_breaks = NULL, base_theme = NULL, title_hjust = NULL,
                        rho_digits = 4, rho_position = "top_right", rho_size = 3.5,
                        F_structure = c("group_year", "year"), polish = TRUE,
                        zero_action = c("missing", "error"), control = list(), nstarts = 1) {
  model_type <- match.arg(model_type)
  supplied <- names(as.list(match.call())[-1L])
  if (is.list(nyear) && !is.data.frame(nyear)) {
    if (!missing(data.CatL))
      stop("Supply the input bundle only once.", call. = FALSE)
    data.CatL <- nyear
    nyear <- 5L
    supplied <- union(setdiff(supplied, "nyear"), "data.CatL")
  }
  nyear <- .acl_positive_integer(nyear, "nyear")
  ncores <- .acl_positive_integer(ncores, "ncores")
  fit_fun <- if (model_type == "acl") run_acl else run_alscl
  fit_names <- intersect(names(formals(fit_fun)), names(formals(retro_model)))
  # Peel workers and within-fit starts are separate controls. Only explicit
  # settings override a bundle, and single-bracket assignment preserves NULL.
  fit_names <- setdiff(fit_names, c("ncores", "silent", "output"))
  if (is.list(data.CatL) && !is.data.frame(data.CatL)) {
    explicit <- intersect(setdiff(supplied, "data.CatL"), fit_names)
    fit_args <- .acl_bundle_args(data.CatL, model_type,
                                mget(explicit, envir = environment()))
  } else {
    fit_args <- mget(fit_names, envir = environment())
  }
  fit_args[c("ncores", "silent", "output")] <- list(1L, TRUE, FALSE)
  if (!"nstarts" %in% names(fit_args)) fit_args$nstarts <- 1L
  if (!is.data.frame(fit_args$data.CatL) && !is.matrix(fit_args$data.CatL))
    stop("data.CatL must be a data frame, matrix or input bundle.", call. = FALSE)
  labels <- colnames(fit_args$data.CatL)
  years <- suppressWarnings(as.numeric(sub("^X", "", labels[-1L])))
  if (length(labels) != ncol(fit_args$data.CatL) || any(!is.finite(years)) ||
      any(diff(years) <= 0))
    stop("Time columns must have increasing numeric labels before retrospective fitting.", call. = FALSE)
  if (nyear > ncol(fit_args$data.CatL) - 3L)
    stop("Every retrospective peel must retain at least two time steps.", call. = FALSE)

  progress <- function(...) if (!silent) cat(...)
  t_grand <- proc.time()
  progress(sprintf("Fitting full %s model...\n", toupper(model_type)))
  full <- .acl_retro_fit(0L, fit_args, model_type, silent)
  ncores_use <- min(ncores, nyear)
  if (ncores_use == 1L) {
    progress(sprintf("Running %d retrospective peels sequentially...\n", nyear))
    peels <- lapply(seq_len(nyear), .acl_retro_fit, fit_args = fit_args,
                    model_type = model_type, silent = silent)
  } else {
    progress(sprintf("Running %d retrospective peels on %d socket workers...\n",
                     nyear, ncores_use))
    cache <- dirname(dirname(.acl_compile(toupper(model_type))$cpp_path))
    cl <- parallel::makeCluster(ncores_use)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    parallel::clusterCall(cl, function(paths, cache, settings) {
      .libPaths(paths)
      options(ALSCL.tmb.cache = cache)
      options(settings)
      library(ALSCL)
      NULL
    }, .libPaths(), cache, .acl_worker_options())
    peels <- parallel::parLapply(cl, seq_len(nyear), .acl_retro_fit,
                                 fit_args = fit_args, model_type = model_type,
                                 silent = silent)
  }
  fits <- c(list(full), peels)
  fit_diagnostics <- do.call(rbind, lapply(fits, `[[`, "diagnostics"))
  rownames(fit_diagnostics) <- NULL
  variables <- c("B", "Rec", "SSB", "N")
  rho_by_peel <- do.call(rbind, lapply(peels, function(peel) {
    do.call(rbind, lapply(variables, function(variable) {
      values <- peel$variables[[variable]]
      full_values <- full$variables[[variable]]
      full_index <- match(tail(peel$year, 1L), full$year)
      reference <- if (length(full_values) == length(full$year) &&
                       !is.na(full_index)) full_values[full_index] else NA_real_
      endpoint <- if (length(values) == length(peel$year)) tail(values, 1L) else NA_real_
      raw_rho <- if (length(endpoint) == 1L && is.finite(endpoint) &&
                    length(reference) == 1L && is.finite(reference) && reference != 0)
        (endpoint - reference) / reference else NA_real_
      valid <- isTRUE(full$diagnostics$numerical_ok) &&
        isTRUE(peel$diagnostics$numerical_ok) && is.finite(raw_rho)
      data.frame(Peel = peel$peel, RetrospectiveYear = tail(peel$year, 1L),
                 Variable = variable, RawRho = raw_rho,
                 Rho = if (valid) raw_rho else NA_real_, Valid = valid)
    }))
  }))
  results <- do.call(rbind, lapply(fits, function(fit) {
    do.call(rbind, lapply(variables, function(variable) {
      values <- fit$variables[[variable]]
      if (is.null(values) || length(values) != length(fit$year)) return(NULL)
      rho_row <- rho_by_peel[rho_by_peel$Peel == fit$peel &
                              rho_by_peel$Variable == variable, , drop = FALSE]
      data.frame(Year = fit$year, Variable = variable, Value = as.numeric(values),
                 RetrospectiveYear = tail(fit$year, 1L),
                 Rho = if (nrow(rho_row)) rho_row$Rho else NA_real_,
                 RawRho = if (nrow(rho_row)) rho_row$RawRho else NA_real_,
                 Peel = fit$peel, NumericalOK = isTRUE(fit$diagnostics$numerical_ok))
    }))
  }))
  if (is.null(results))
    results <- data.frame(Year = numeric(), Variable = character(), Value = numeric(),
      RetrospectiveYear = numeric(), Rho = numeric(), RawRho = numeric(),
      Peel = integer(), NumericalOK = logical())
  results$RetrospectiveYear <- factor(results$RetrospectiveYear,
    levels = sort(unique(results$RetrospectiveYear), decreasing = TRUE))
  xpos <- min(full$year) + diff(range(full$year)) / 5
  rho_text <- do.call(rbind, lapply(variables, function(variable) {
    rows <- rho_by_peel[rho_by_peel$Variable == variable, , drop = FALSE]
    valid <- nrow(rows) == nyear && all(rows$Valid)
    data.frame(Variable = variable, Rho = if (valid) mean(rows$Rho) else NA_real_,
               Year = xpos, Valid = valid, ValidPeels = sum(rows$Valid),
               RequestedPeels = nyear)
  }))
  raw_rho_text <- do.call(rbind, lapply(variables, function(variable) {
    rows <- rho_by_peel[rho_by_peel$Variable == variable, , drop = FALSE]
    # Retain the diagnostic raw mean, but never silently drop missing peels.
    data.frame(Variable = variable,
               Rho = if (all(is.finite(rows$RawRho))) mean(rows$RawRho) else NA_real_,
               Year = xpos)
  }))
  last_points <- if (nrow(results)) results %>%
    dplyr::group_by(Variable, RetrospectiveYear) %>%
    dplyr::filter(Year == max(Year)) %>%
    dplyr::ungroup() else results
  if (any(!rho_text$Valid))
    warning("Mohn's rho is unavailable for one or more quantities: a full/peel fit failed the numerical screen or a terminal estimate is missing. Inspect fit_diagnostics, errors and rho_by_peel; raw_rho_text is descriptive only.",
            call. = FALSE)
  progress(sprintf("Retrospective analysis complete: %.1f sec.\n",
                   (proc.time() - t_grand)[["elapsed"]]))
  output <- list(results = results, rho_text = rho_text, last_points = last_points,
                 model_type = model_type, fit_diagnostics = fit_diagnostics,
                 rho_by_peel = rho_by_peel, raw_rho_text = raw_rho_text,
                 errors = fit_diagnostics[nzchar(fit_diagnostics$error),
                                          c("Peel", "RetrospectiveYear", "error"), drop = FALSE],
                 workers = ncores_use, nstarts = fit_args$nstarts)
  if (plot) {
    p <- plot_retro(output,
                    rho_digits = rho_digits, rho_position = rho_position, rho_size = rho_size,
                    line_size = line_size, point_size = point_size,
                    point_shape = point_shape, facet_scales = facet_scales,
                    facet_col = facet_col, facet_row = facet_row,
                    title = title, xlab = xlab, ylab = ylab, font_family = font_family,
                    title_size = title_size, axis_title_size = axis_title_size,
                    axis_text_size = axis_text_size, strip_text_size = strip_text_size,
                    legend_text_size = legend_text_size, x_breaks = x_breaks,
                    base_theme = base_theme, title_hjust = title_hjust)
    output$plot <- p
  }

  return(output)
}


#' Retrospective Analysis for ACL Model
#'
#' Convenience wrapper that calls `retro_model(..., model_type = "acl")`.
#' See [retro_model()] for full documentation of all parameters.
#'
#' @param nyear Integer. Number of time columns to peel. Default is 5.
#' @param data.CatL The Catch-at-Length data or a named input bundle, as in
#'   `retro_acl(x, nyear = 3)`.
#' @param data.wgt The weight data.
#' @param data.mat The maturity data.
#' @param rec.age The recruitment age.
#' @param nage The number of age classes.
#' @param M The natural mortality rate.
#' @param sel_L50 Length at 50 percent selectivity.
#' @param sel_L95 Length at 95 percent selectivity.
#' @param ... Additional arguments passed to [retro_model()].
#' @return A list. See [retro_model()].
#' @inheritParams retro_model
#' @seealso [retro_model()], [retro_alscl()], [plot_retro()]
#' @export
retro_acl <- function(nyear = 5, data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95,
                      parameters = NULL, parameters.L = NULL, parameters.U = NULL,
                      map = NULL, len_mid = NULL, len_border = NULL, plot = FALSE,
                      line_size = 1.2, point_size=3,point_shape=21,facet_scales = "free", facet_col = NULL, facet_row = NULL,train_times=1, title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL, title_hjust = NULL, rho_digits = 4, rho_position = "top_right", rho_size = 3.5, ncores = 1, ...) {
  .acl_retro_wrapper(match.call(expand.dots = FALSE), environment(), "acl")
}


#' Retrospective Analysis for ALSCL Model
#'
#' Convenience wrapper that calls `retro_model(..., model_type = "alscl")`.
#' See [retro_model()] for full documentation of all parameters.
#'
#' @param nyear Integer. Number of time columns to peel. Default is 5.
#' @param data.CatL The Catch-at-Length data or a named input bundle, as in
#'   `retro_alscl(x, nyear = 3)`.
#' @param data.wgt The weight data.
#' @param data.mat The maturity data.
#' @param rec.age The recruitment age.
#' @param nage The number of age classes.
#' @param M The natural mortality rate.
#' @param sel_L50 Length at 50 percent selectivity.
#' @param sel_L95 Length at 95 percent selectivity.
#' @param growth_step Numeric. Growth transition time step. Defaults to 1 for
#'   separate arguments; bundled calls retain the bundle's setting or infer it
#'   as in [run_alscl()].
#' @param ... Additional arguments passed to [retro_model()].
#' @return A list. See [retro_model()].
#' @seealso [retro_model()], [retro_acl()], [plot_retro()]
#' @export
retro_alscl <- function(nyear = 5, data.CatL, data.wgt, data.mat,
                        rec.age, nage, M, sel_L50, sel_L95,
                        growth_step = 1, ...) {
  .acl_retro_wrapper(match.call(expand.dots = FALSE), environment(), "alscl")
}


#' Plot Retrospective Analysis Results
#'
#' Generate or re-generate the retrospective plot from stored results.
#' This allows changing display options without re-running the computation.
#'
#' @param retro_result A list returned by `retro_model()`, `retro_acl()`, or `retro_alscl()`.
#' @param rho_digits Integer. Decimal places for Mohn's rho. Default is 4.
#' @param rho_position Character. Position of rho text. Default is "top_right".
#' @param rho_size Numeric. Font size of rho text. Default is 3.5.
#' @param line_size Numeric. Line thickness. Default is 1.2.
#' @param point_size Numeric. Point size. Default is 3.
#' @param point_shape Numeric. Point shape. Default is 21.
#' @param facet_scales Character. Facet scales. Default is "free".
#' @param facet_col Integer or NULL. Number of facet columns.
#' @param facet_row Integer or NULL. Number of facet rows.
#' @param title Character or NULL. Custom plot title.
#' @param xlab Character or NULL. Custom x-axis label.
#' @param ylab Character or NULL. Custom y-axis label.
#' @param font_family Character or NULL. Font family.
#' @param title_size Numeric or NULL. Title size in pt.
#' @param axis_title_size Numeric or NULL. Axis title size in pt.
#' @param axis_text_size Numeric or NULL. Axis tick label size in pt.
#' @param strip_text_size Numeric or NULL. Facet label size in pt.
#' @param legend_text_size Numeric or NULL. Legend text size in pt.
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks.
#' @param base_theme Character or NULL. Base ggplot2 theme name.
#' @param title_hjust Numeric or NULL. Title horizontal alignment.
#' @return A ggplot object.
#' @param palette Character or NULL. ggsci palette name; NULL inherits acl_theme().
#'   Native colors are interpolated when there are more peels than colors.
#' @param colors Character vector or NULL. Explicit period colors, ordered by
#'   descending terminal period or named by terminal period. Overrides palette.
#' @export
#' @examples
#' \dontrun{
#' retro <- retro_acl(nyear = 5, data.CatL, data.wgt, data.mat,
#'                    rec.age = 1, nage = 7, M = 0.8,
#'                    sel_L50 = 28, sel_L95 = 36)
#' plot_retro(retro)
#' }
plot_retro <- function(retro_result,
                       rho_digits = 4,
                       rho_position = "top_right",
                       rho_size = 3.5,
                       line_size = 1.2, point_size = 3, point_shape = 21,
                       facet_scales = "free", facet_col = NULL, facet_row = NULL,
                       title = NULL, xlab = NULL, ylab = NULL,
                       font_family = NULL, title_size = NULL,
                       axis_title_size = NULL, axis_text_size = NULL,
                       strip_text_size = NULL, legend_text_size = NULL,
                       x_breaks = NULL, base_theme = NULL, title_hjust = NULL, palette = NULL, colors = NULL) {

  results     <- retro_result$results
  rho_text    <- retro_result$rho_text
  last_points <- retro_result$last_points
  if (!nrow(results) || !any(is.finite(results$Year)))
    stop("No retrospective estimates are available to plot; inspect fit_diagnostics and errors.",
         call. = FALSE)

  # 截止期排序固定颜色映射 / Stable color mapping by terminal period.
  periods <- sort(unique(as.character(results$RetrospectiveYear)), decreasing = TRUE)
  numeric_periods <- suppressWarnings(as.numeric(periods))
  if (all(is.finite(numeric_periods))) periods <- periods[order(numeric_periods, decreasing = TRUE)]
  if (is.null(colors)) {
    colors <- stats::setNames(.acl_palette(palette %||% acl_theme("palette"), length(periods)), periods)
  } else {
    if (length(colors) < length(periods)) stop("colors must cover every retrospective period.")
    if (!is.null(names(colors))) {
      if (!all(periods %in% names(colors))) stop("Named colors must include every retrospective period.")
      colors <- colors[periods]
    } else colors <- stats::setNames(colors[seq_along(periods)], periods)
    if (anyNA(colors)) stop("colors must not contain missing values.")
    grDevices::col2rgb(colors)
  }
  results$RetrospectiveYear <- factor(results$RetrospectiveYear, levels = periods)
  last_points$RetrospectiveYear <- factor(last_points$RetrospectiveYear, levels = periods)

  x_min <- min(results$Year, na.rm = TRUE)
  x_max <- max(results$Year, na.rm = TRUE)
  x_range <- x_max - x_min

  pos <- match.arg(rho_position, c("top_right", "top_left", "bottom_right", "bottom_left"))
  if (pos %in% c("top_right", "bottom_right")) {
    rho_text$Year <- x_max - x_range * 0.02
    rho_hjust <- 1
  } else {
    rho_text$Year <- x_min + x_range * 0.02
    rho_hjust <- 0
  }
  if (pos %in% c("top_right", "top_left")) {
    rho_y <- Inf
    rho_vjust <- 1.5
  } else {
    rho_y <- -Inf
    rho_vjust <- -0.5
  }

  auto_title <- if (!is.null(retro_result$model_type)) {
    paste0("Retrospective Analysis (", toupper(retro_result$model_type), ")")
  } else {
    "Retrospective Analysis"
  }

  p <- ggplot2::ggplot(results, ggplot2::aes(x = Year, y = Value,
                                              color = RetrospectiveYear,
                                              group = RetrospectiveYear)) +
    ggplot2::geom_line(linewidth = line_size) +
    ggplot2::scale_color_manual(values = colors, breaks = periods) +
    ggplot2::geom_point(data = last_points, size = point_size, shape = point_shape) +
    ggplot2::facet_wrap(~Variable, scales = facet_scales, ncol = facet_col, nrow = facet_row) +
    .acl_scale_x(x_breaks, n_breaks = 10) +
    .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size,
                    strip_text_size, legend_text_size,
                    base_theme = base_theme, title_hjust = title_hjust) +
    ggplot2::theme(legend.position = "bottom") +
    ggplot2::labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", "year"),
                  y = if (!is.null(ylab)) ylab else "Value", color = "Retrospective Year",
                  title = if (!is.null(title)) title else auto_title)

  p <- p + ggplot2::geom_text(
    data = rho_text,
    ggplot2::aes(x = Year,
                 label = ifelse(is.finite(Rho),
                   paste0("rho = ", sprintf(paste0("%.", rho_digits, "f"), Rho)),
                   "rho unavailable: check diagnostics")),
    y = rho_y, hjust = rho_hjust, vjust = rho_vjust,
    size = rho_size,
    inherit.aes = FALSE
  )
  if (any(!is.finite(rho_text$Rho)))
    p <- p + ggplot2::labs(subtitle =
      "Available estimates shown; numerical checks or terminal estimates are incomplete.")

  return(p)
}
