utils::globalVariables(c(
  "Model", "Year", "Value", "lower", "upper", "estimate",
  "Quantity", "Age", "Length", "Probability", "From", "To",
  "LenBin", "YearIdx", "F_value", "Label", "Residual",
  "Observed", "Predicted", "Metric_Name", "Metric_Value",
  "abs_resid", "year_fct", "MeanF", "Selectivity", "Source",
  "mean_r", "sd_r", "Width", "Height"
))

# ---------------------------------------------------------------------------
# Internal: detect model name
# ---------------------------------------------------------------------------
.detect_model_name <- function(m, fallback) {
  if (!is.null(m$model_type)) return(m$model_type)
  if (!is.null(m$report$FL))  return("ALSCL")
  if (!is.null(m$report[["F"]]))   return("ACL")
  return(fallback)
}


# Keep two fits in separate groups even when their model types are identical.
.acl_plot_compare_names <- function(model1, model2, name1 = NULL, name2 = NULL) {
  supplied <- c(!is.null(name1), !is.null(name2))
  labels <- list(name1 %||% .detect_model_name(model1, "Model 1"),
                 name2 %||% .detect_model_name(model2, "Model 2"))
  valid <- vapply(labels, function(x)
    is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x)), logical(1))
  if (!all(valid)) stop("Model names must be nonempty character strings.", call. = FALSE)
  labels <- unlist(labels, use.names = FALSE)
  if (labels[1L] == labels[2L]) {
    if (all(supplied))
      stop("model1_name and model2_name must be distinct.", call. = FALSE)
    structures <- c(model1$F_structure, model2$F_structure)
    distinct_structures <- length(structures) == 2L && !anyNA(structures) &&
      all(nzchar(structures)) && !anyDuplicated(structures)
    suffix <- if (!any(supplied) && distinct_structures) structures else c("1", "2")
    auto <- which(!supplied)
    labels[auto] <- paste0(labels[auto], " (", suffix[auto], ")")
  }
  labels
}

.acl_plot_year <- function(model, n = NULL, name = "Model") {
  years <- model$year
  if (!is.numeric(years) || !length(years) || any(!is.finite(years)) ||
      any(diff(years) <= 0))
    stop(name, " must contain finite, increasing year metadata.", call. = FALSE)
  if (!is.null(n) && length(years) != n)
    stop(name, " report dimensions do not match its year metadata.", call. = FALSE)
  years
}

# Plots sharing one observed table must use its order. Legacy metric-only
# results can lack metadata, but known mismatches must never be relabeled.
.acl_plot_comparison_grid <- function(models, data.CatL, midpoints = FALSE) {
  survey <- .acl_survey_data(data.CatL)
  observed <- survey$observed; years <- survey$years; labels <- survey$labels
  if (length(years) != ncol(observed) || any(!is.finite(years)) || any(diff(years) <= 0))
    stop("data.CatL must have finite, increasing numeric time columns.", call. = FALSE)
  for (i in seq_along(models)) {
    model <- models[[i]]
    # Share the in-sample checks used by diagnostic_metrics() and
    # compare_models(): matching dimensions alone cannot identify the data.
    .acl_validate_survey_fit(model, survey, paste("Model", i))
    if (midpoints && (!is.numeric(model$len_mid) ||
        length(model$len_mid) != nrow(observed) || any(!is.finite(model$len_mid)) ||
        any(diff(model$len_mid) <= 0)))
      stop("Model ", i, " does not match data.CatL: length midpoints.", call. = FALSE)
  }
  if (midpoints && !isTRUE(all.equal(as.numeric(models[[1L]]$len_mid),
                                     as.numeric(models[[2L]]$len_mid), tolerance = 1e-8)))
    stop("Models have different length midpoints; plot_compare_CatL() needs both fits on the same length bins.",
         call. = FALSE)
  list(observed = observed, year = years, len_label = labels)
}


# ==========================================================================
# plot_compare_ts: Time-series comparison
# ==========================================================================

#' Compare Time-Series Outputs of Two Models
#'
#' Plots spawning stock biomass (SSB), recruitment, total biomass, total
#' abundance and catch from two models on the same axes. The plot uses the
#' global theme and can be extended with \code{+ ggplot2::theme()} or any
#' ggplot2 layer.
#'
#' @param model1 First model result (reference).
#' @param model2 Second model result (alternative).
#' @param quantities Character vector. Quantities to compare. Accepts: "SSB", "R" (or "Rec"),
#'   "B", "N", "CN", "CB". Default c("SSB","R","B","N","CN"), the
#'   quantities reported with uncertainty by both ACL and ALSCL. CB can be
#'   requested explicitly when both supplied results contain it.
#'   For F, use \code{plot_compare_F_ts()} and explicitly choose the group
#'   mean or apical summary; F is not a scalar time series in the model reports.
#' @param se Logical. Show 95% confidence intervals. Default FALSE.
#' @param interval Character or NULL. The interval drawn when \code{se = TRUE}.
#'   \code{"lognormal"} is \code{exp(log(estimate) +/- 1.96 * SE / estimate)} and
#'   stays above zero (an estimate of exactly zero keeps the Wald upper bound
#'   with the lower bound at zero). \code{"wald"} is \code{estimate +/- 1.96 * SE} and can
#'   fall below zero. NULL inherits the global \code{interval} setting (default
#'   "lognormal"). Point estimates are the same for both.
#' @param model1_name,model2_name Character. Labels. Auto-detected if NULL.
#' @param colors Character vector of 2 colors, named by model or in model
#'   order. NULL = use global theme. A vector with fewer than two colors gives
#'   a warning and the global setting is used.
#' @param linetypes Character vector of 2 linetypes, with the same rules as
#'   \code{colors}. NULL = use global theme.
#' @param line_size Numeric or NULL. Line width; NULL uses the global compare_line_size.
#' @param facet_ncol Integer or NULL. Facet columns; NULL uses the global compare_facet_ncol.
#' @param facet_scales Character or NULL. Facet scales; NULL uses the global compare_facet_scales.
#' @param return_data Logical. Return data alongside plot. Default FALSE.
#' @param ... Former argument names, accepted with a warning: linewidth for
#'   line_size, ncol for facet_ncol and scales for facet_scales.
#'
#' @return A ggplot object (can be further modified with + theme(), + labs(), etc.)
#' @details Every requested quantity must be a finite series matching its model's
#'   time metadata. Unknown or unavailable quantities are errors, rather than
#'   silently omitted panels. With se = TRUE, both models must have complete,
#'   finite estimates and finite nonnegative standard errors for every requested
#'   quantity. Use se = FALSE when uncertainty is unavailable.
#'   A model with one estimate in a panel is drawn as a point, with an error
#'   bar when se = TRUE. Models with multiple estimates retain lines and ribbons.
#' @export
#'
#' @examples
#' \donttest{
#' # Fit both models to the last ten years of the example data. The shorter
#' # series and one fishing mortality rate (F) shared by all lengths in each
#' # year keep the ALSCL fit short.
#' x <- YTF_example
#' tables <- c("data.CatL", "data.wgt", "data.mat")
#' x[tables] <- lapply(x[tables], function(tab) tab[, c(1, 12:21)])
#' fit_acl <- run_acl(x, silent = TRUE)
#' fit_alscl <- run_alscl(x, F_structure = "year", silent = TRUE)
#' plot_compare_ts(fit_acl, fit_alscl)
#'
#' # With 95% confidence intervals
#' plot_compare_ts(fit_acl, fit_alscl, quantities = c("SSB", "R"), se = TRUE)
#'
#' # Colors for one call, followed by ggplot2 layers
#' plot_compare_ts(fit_acl, fit_alscl,
#'   colors = c(ACL = "darkgreen", ALSCL = "orange")) +
#'   ggplot2::theme(legend.position = "top") +
#'   ggplot2::labs(title = "My Title")
#'
#' # Or set the style of all comparison plots, then restore the previous
#' # settings
#' old <- acl_theme_set(
#'   compare_colors = c(ACL = "steelblue", ALSCL = "tomato"),
#'   compare_linetypes = c(ACL = "solid", ALSCL = "longdash"),
#'   base_theme = "theme_classic"
#' )
#' plot_compare_ts(fit_acl, fit_alscl)
#' do.call(acl_theme_set, old)
#' }
plot_compare_ts <- function(model1, model2,
                            quantities = c("SSB", "R", "B", "N", "CN"),
                            se = FALSE,
                            model1_name = NULL, model2_name = NULL,
                            colors = NULL, linetypes = NULL, line_size = NULL,
                            facet_ncol = NULL, facet_scales = NULL,
                            return_data = FALSE, ..., interval = NULL) {

  renamed <- .acl_renamed(list(...), "plot_compare_ts")
  interval <- .acl_interval_type(interval)
  if (is.null(line_size)) line_size <- renamed$line_size
  if (is.null(facet_ncol)) facet_ncol <- renamed$facet_ncol
  if (is.null(facet_scales)) facet_scales <- renamed$facet_scales
  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]

  cfg <- .acl_compare_defaults(colors = colors, linetypes = linetypes,
                               line_size = line_size, facet_ncol = facet_ncol,
                               facet_scales = facet_scales,
                               m1 = model1_name, m2 = model2_name)
  year1 <- .acl_plot_year(model1, name = model1_name)
  year2 <- .acl_plot_year(model2, name = model2_name)
  .acl_check_flag(se, "se")
  if (!is.character(quantities) || !length(quantities) || anyNA(quantities) ||
      any(!nzchar(quantities)))
    stop("quantities must be a nonempty character vector of supported quantities.", call. = FALSE)
  if (any(quantities %in% c("F", "f")))
    stop("F is a group-by-time quantity. Use plot_compare_F_ts() with method = 'mean' ",
         "or 'apical' to choose its time-series summary.", call. = FALSE)

  # Aliases: user-friendly names -> report field names
  qty_aliases <- c(R = "Rec", Rec = "Rec", rec = "Rec",
                   SSB = "SSB", ssb = "SSB",
                   B = "B", biomass = "B",
                   N = "N", abundance = "N",
                   CN = "CN", catch = "CN",
                   CB = "CB")

  qty_labels <- c(SSB = "Spawning stock biomass (SSB)", Rec = "Recruitment",
                  B = "Total biomass", N = "Total abundance",
                  CN = "Catch numbers", CB = "Catch biomass")

  # Resolve aliases
  unknown <- setdiff(quantities, names(qty_aliases))
  if (length(unknown))
    stop("Unknown quantities: ", paste(unknown, collapse = ", "),
         ". Available: SSB, R, Rec, B, N, CN, CB.", call. = FALSE)
  resolved <- unique(unname(qty_aliases[quantities]))

  df_list <- list()
  for (q in resolved) {
    series <- function(model, years, name) {
      value <- model$report[[q]]
      if (is.null(value))
        stop("Quantity '", q, "' is unavailable in ", name, ".", call. = FALSE)
      if (!is.numeric(value) || length(value) != length(years) ||
          any(!is.finite(value)))
        stop("Quantity '", q, "' in ", name,
             " must have one finite numeric estimate per time step.", call. = FALSE)
      as.numeric(value)
    }
    v1 <- series(model1, year1, model1_name)
    v2 <- series(model2, year2, model2_name)
    label <- ifelse(q %in% names(qty_labels), qty_labels[q], q)
    df_list[[length(df_list) + 1]] <- data.frame(
      Year = c(year1, year2), Value = c(as.numeric(v1), as.numeric(v2)),
      Model = rep(c(model1_name, model2_name), c(length(year1), length(year2))),
      Quantity = label, stringsAsFactors = FALSE)
  }
  df <- do.call(rbind, df_list)
  df$Quantity <- factor(df$Quantity, levels = unique(df$Quantity))

  p <- ggplot2::ggplot(df, ggplot2::aes(x = Year, y = Value,
                                         color = Model, linetype = Model)) +
    ggplot2::geom_line(linewidth = cfg$line_size) +
    ggplot2::scale_color_manual(values = cfg$colors) +
    ggplot2::scale_linetype_manual(values = cfg$linetypes) +
    ggplot2::facet_wrap(~Quantity, ncol = cfg$facet_ncol, scales = cfg$facet_scales) +
    ggplot2::labs(title = .acl_title("compare_ts", model1_name, model2_name),
                  x = .acl_lab("x", "year"), y = "Estimate",
                  color = "Model", linetype = "Model") +
    .acl_base_theme() +
    .acl_scale_x(values = df$Year, check_overlap = TRUE) +
    ggplot2::theme(legend.position = cfg$legend_pos,
                   strip.text = ggplot2::element_text(face = "bold"))

  if (se) {
    ribbon_list <- list()
    for (q in resolved) {
      for (info in list(list(m = model1, name = model1_name),
                        list(m = model2, name = model2_name))) {
        years <- info$m$year
        ss <- .acl_plot_estimates(info$m, q, length(years))
        label <- ifelse(q %in% names(qty_labels), qty_labels[q], q)
        bounds <- .acl_interval(ss[, "Estimate"], ss[, "Std. Error"], interval)
        ribbon_list[[length(ribbon_list) + 1]] <- data.frame(
          Year = years, estimate = ss[, "Estimate"],
          lower = bounds$lower, upper = bounds$upper,
          Model = info$name, Quantity = label, stringsAsFactors = FALSE)
      }
    }
    if (length(ribbon_list) > 0) {
      ribbon_df <- do.call(rbind, ribbon_list)
      ribbon_df$Quantity <- factor(ribbon_df$Quantity, levels = levels(df$Quantity))
      p <- p + ggplot2::geom_ribbon(
        data = ribbon_df,
        ggplot2::aes(x = Year, ymin = lower, ymax = upper, fill = Model),
        alpha = cfg$se_alpha, inherit.aes = FALSE
      ) + ggplot2::scale_fill_manual(values = cfg$colors, limits = names(cfg$colors))
    }
  }

  p <- .acl_show_singletons(p, c("Model", "Quantity"), cfg$point_size)
  if (return_data) return(list(plot = p, data = df)) else return(p)
}


# ==========================================================================
# plot_compare_F: Fishing mortality heatmap
# ==========================================================================

#' Compare Fishing Mortality Heatmaps Between Two Models
#'
#' @inheritParams plot_compare_ts
#' @param palette Character or NULL. NULL uses the global sequential colors; a ggsci palette name or a viridis option overrides them.
#' @details ACL rows use the ages stored in each fit. The oldest age class is a
#'   plus group and is marked with a plus sign, for example "Age 15+". Older
#'   fits without age metadata show age-group numbers. ALSCL rows follow the
#'   fitted length bins. An ACL fit and an ALSCL fit have different rows, so
#'   their heatmaps cannot be compared row by row. For a summary of both fits
#'   over the same ages, use \code{plot_compare_F_ts(basis = "age")}.
#' @return A ggplot object.
#' @examples
#' \donttest{
#' # Fit both models to the last ten years of the example data. The shorter
#' # series and one fishing mortality rate (F) shared by all lengths in each
#' # year keep the ALSCL fit short.
#' x <- YTF_example
#' tables <- c("data.CatL", "data.wgt", "data.mat")
#' x[tables] <- lapply(x[tables], function(tab) tab[, c(1, 12:21)])
#' fit_acl <- run_acl(x, silent = TRUE)
#' fit_alscl <- run_alscl(x, F_structure = "year", silent = TRUE)
#' plot_compare_F(fit_acl, fit_alscl)
#' }
#' @export
plot_compare_F <- function(model1, model2,
                           model1_name = NULL, model2_name = NULL,
                           palette = NULL) {

  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]

  extract_F <- function(model, mname) {
    is_alscl <- is.null(model$report[["F"]]) && !is.null(model$report$FL)
    Fmat <- if (is_alscl) model$report$FL else model$report[["F"]]
    if (!is.matrix(Fmat) || !is.numeric(Fmat) || !nrow(Fmat) || !ncol(Fmat))
      stop(mname, " must contain a numeric F or FL matrix.", call. = FALSE)
    if (is_alscl) {
      labels <- if (!is.null(model$len_label)) model$len_label else paste0("L", seq_len(nrow(Fmat)))
      dim_type <- "length"
    } else {
      age <- model$age
      if (is.null(age)) {
        age <- seq_len(nrow(Fmat))
        labels <- paste("Age group", age)
      } else {
        if (!is.numeric(age) || !is.null(dim(age)) || length(age) != nrow(Fmat) ||
            any(!is.finite(age)) || any(diff(age) <= 0))
          stop(mname, " ages must be finite, increasing and match the F matrix rows.", call. = FALSE)
        # The oldest age class of an ACL fit is a plus group.
        labels <- paste("Age", age)
        labels[length(labels)] <- paste0(labels[length(labels)], "+")
      }
      dim_type <- "age"
    }
    years <- .acl_plot_year(model, ncol(Fmat), mname)
    if (length(labels) != nrow(Fmat) || anyNA(labels) || anyDuplicated(labels))
      stop(mname, " length labels must match the F matrix rows and be distinct.", call. = FALSE)
    df <- data.frame(Year = rep(years, each = nrow(Fmat)),
                     F_value = as.numeric(Fmat),
                     Label = factor(rep(labels, ncol(Fmat)), levels = rev(labels)))
    df$Model <- mname
    if (!is_alscl) attr(df, "ages") <- stats::setNames(age, labels)
    attr(df, "dim_type") <- dim_type
    return(df)
  }

  df1 <- extract_F(model1, model1_name)
  df2 <- extract_F(model2, model2_name)

  # Warn if comparing different dimensions
  if (attr(df1, "dim_type") != attr(df2, "dim_type")) {
    message("Note: ", model1_name, " reports F at ", attr(df1, "dim_type"),
            " and ", model2_name, " reports F at ", attr(df2, "dim_type"),
            ". The heatmap rows are not directly comparable.\n",
            "  plot_compare_F_ts(basis = \"age\") summarizes F at age over the ages ",
            "and time steps that both fits share.")
  }
  dim_types <- unique(c(attr(df1, "dim_type"), attr(df2, "dim_type")))
  row_label <- if (length(dim_types) > 1L) "Age class or length bin" else
    if (dim_types == "age") "Age class" else "Length bin"
  bases <- unique(c(.acl_rate_basis(model1), .acl_rate_basis(model2)))
  fill_label <- paste0("F (", if (length(bases) == 1L) bases else "per time step", ")")

  df <- rbind(df1, df2)
  # Combining factors appends new levels. Reorder ages numerically so panels
  # with overlapping annual and subannual age grids both keep their own order.
  ages <- c(attr(df1, "ages"), attr(df2, "ages"))
  if (length(ages)) {
    labels <- union(names(sort(ages, decreasing = TRUE)), levels(df$Label))
    df$Label <- factor(df$Label, levels = labels)
  }
  df$Model <- factor(df$Model, levels = c(model1_name, model2_name))

  p <- ggplot2::ggplot(df, ggplot2::aes(x = Year, y = Label, fill = F_value)) +
    ggplot2::geom_tile() +
    .acl_fill_continuous(palette, name = fill_label) +
    ggplot2::facet_wrap(~Model, scales = "free_y") +
    ggplot2::labs(title = .acl_title("compare_F", model1_name, model2_name),
                  x = .acl_lab("x", "year"), y = row_label) +
    .acl_base_theme() + .acl_scale_x(values = df$Year, check_overlap = TRUE) +
    ggplot2::theme(strip.text = ggplot2::element_text(face = "bold"),
                   legend.position = acl_theme("compare_legend_pos"))

  return(p)
}


# ==========================================================================
# plot_compare_residuals: 4-panel diagnostics
# ==========================================================================

#' Compare Residual Diagnostics Between Two Models
#'
#' Four panels of log residuals (log observed survey index minus log fitted
#' index): histogram, normal quantile-quantile (QQ) plot, mean residual by time
#' step, and absolute residual by length bin.
#' A single unified color legend is displayed (default: bottom center).
#'
#' @inheritParams plot_compare_ts
#' @param data.CatL Survey index table used for both fits: a length-bin column
#'   followed by one column of survey indices per time step.
#' @param bins Integer. Histogram bins. Default 35.
#' @param point_size Numeric or NULL. Size of QQ and mean-residual points.
#'   NULL inherits the comparison point-size override, if set, or global point_size.
#' @param legend_pos Character. Legend position. NULL = use global theme (default "bottom").
#' @param qq_alpha Numeric. QQ point transparency. Default 0.6.
#' @param errorbar_width Numeric. Error bar cap width. Default 0.3.
#' @param ... The former argument name linewidth, accepted with a warning.
#' @return A ggplot object (combined 4-panel via patchwork).
#' @details These are in-sample residuals. Known time labels, length labels,
#'   positive-observation values and missing-data masks must match both fitted
#'   results. Zeros and NA are excluded as in fitting. Saved fits without
#'   stored observation metadata remain usable, but their original-data alignment
#'   cannot be fully verified. Data frames, matrices and tibbles use the same
#'   numeric conversion as the fitting functions.
#'   The mean-residual axis retains the full fitted time range, including
#'   unobserved first or last periods. The line breaks at unobserved periods. Isolated
#'   observed periods remain visible as points; an SD bar requires at least
#'   two observed length bins in that period.
#' @examples
#' \donttest{
#' # Fit both models to the last ten years of the example data. The shorter
#' # series and one fishing mortality rate (F) shared by all lengths in each
#' # year keep the ALSCL fit short.
#' x <- YTF_example
#' tables <- c("data.CatL", "data.wgt", "data.mat")
#' x[tables] <- lapply(x[tables], function(tab) tab[, c(1, 12:21)])
#' fit_acl <- run_acl(x, silent = TRUE)
#' fit_alscl <- run_alscl(x, F_structure = "year", silent = TRUE)
#' plot_compare_residuals(fit_acl, fit_alscl, x$data.CatL)
#' }
#' @export
plot_compare_residuals <- function(model1, model2, data.CatL,
                                   model1_name = NULL, model2_name = NULL,
                                   colors = NULL, linetypes = NULL,
                                   line_size = NULL, point_size = NULL,
                                   legend_pos = NULL, bins = 35,
                                   qq_alpha = 0.6, errorbar_width = 0.3, ...) {

  renamed <- .acl_renamed(list(...), "plot_compare_residuals")
  if (is.null(line_size)) line_size <- renamed$line_size
  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]
  cfg <- .acl_compare_defaults(colors = colors, linetypes = linetypes,
                               line_size = line_size, point_size = point_size,
                               legend_pos = legend_pos,
                               m1 = model1_name, m2 = model2_name)

  grid <- .acl_plot_comparison_grid(list(model1, model2), data.CatL)
  observed <- grid$observed; len_label <- grid$len_label; year <- grid$year
  if (length(year) != ncol(observed) || any(!is.finite(year)) || any(diff(year) <= 0))
    stop("data.CatL must have finite, increasing numeric time columns.", call. = FALSE)
  valid <- is.finite(observed) & observed > 0
  if (!any(valid)) stop("No positive finite observations are available.", call. = FALSE)

  make_resid_df <- function(model, mname) {
    residuals <- model$report$resid_index
    if (!identical(dim(residuals), dim(observed)))
      stop(mname, " residual dimensions do not match data.CatL.", call. = FALSE)
    if (any(!is.finite(residuals[valid])))
      stop(mname, " residuals are non-finite for observed cells.", call. = FALSE)
    df <- data.frame(Residual = as.numeric(residuals),
                     Year = rep(year, each = nrow(observed)),
                     LenBin = rep(len_label, ncol(observed)), Model = mname)
    df[as.vector(valid), , drop = FALSE]
  }

  df <- rbind(make_resid_df(model1, model1_name), make_resid_df(model2, model2_name))
  base_layers <- .acl_base_theme()
  no_legend <- ggplot2::theme(legend.position = "none")

  # P1: Histogram; the shared model legend comes from the time-series lines.
  p1 <- ggplot2::ggplot(df, ggplot2::aes(x = Residual, fill = Model)) +
    ggplot2::geom_histogram(alpha = 0.5, position = "identity", bins = bins) +
    ggplot2::scale_fill_manual(values = cfg$colors) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
    ggplot2::labs(title = "Residual distribution", x = .acl_lab("y", "residual"),
                  y = "Number of observations") +
    base_layers +
    no_legend

  # P2: QQ
  p2 <- ggplot2::ggplot(df, ggplot2::aes(sample = Residual, color = Model)) +
    ggplot2::stat_qq(size = cfg$point_size, alpha = qq_alpha) +
    ggplot2::stat_qq_line(ggplot2::aes(linetype = Model)) +
    ggplot2::scale_linetype_manual(values = cfg$linetypes) +
    ggplot2::scale_color_manual(values = cfg$colors) +
    ggplot2::labs(title = "QQ plot", x = "Theoretical normal quantile",
                  y = "Sample quantile") +
    base_layers + no_legend

  # P3: Mean residual by year
  # Retain the complete time grid before splitting the observed runs.
  resid_by_year <- do.call(rbind, lapply(model_names, function(name) {
    do.call(rbind, lapply(year, function(time) {
      values <- df$Residual[df$Model == name & df$Year == time]
      data.frame(Year = time, Model = name,
        mean_r = if (length(values)) mean(values) else NA_real_,
        sd_r = stats::sd(values), stringsAsFactors = FALSE)
    }))
  }))
  runs <- .acl_observed_plot_runs(resid_by_year, "Model", "Year", "mean_r")

  p3 <- ggplot2::ggplot(resid_by_year, ggplot2::aes(x = Year, y = mean_r, color = Model)) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    ggplot2::geom_line(data = runs[runs$run_size > 1L, , drop = FALSE],
      ggplot2::aes(linetype = Model, group = survey_run), linewidth = cfg$line_size,
      show.legend = TRUE) +
    ggplot2::geom_point(data = runs, size = cfg$point_size, show.legend = FALSE) +
    ggplot2::geom_errorbar(data = runs[is.finite(runs$sd_r), , drop = FALSE],
      ggplot2::aes(ymin = mean_r - sd_r, ymax = mean_r + sd_r),
                           width = errorbar_width, alpha = 0.5, show.legend = FALSE) +
    ggplot2::scale_color_manual(values = cfg$colors, limits = model_names) +
    ggplot2::scale_linetype_manual(values = cfg$linetypes, limits = model_names) +
    ggplot2::labs(title = "Mean residual by year", x = .acl_lab("x", "year"),
                  y = "Mean log residual (bars: 1 SD)",
                  color = NULL, linetype = NULL) +
    base_layers + .acl_scale_x(values = year, check_overlap = TRUE) + ggplot2::theme(legend.position = "bottom") +
    ggplot2::expand_limits(x = range(year))

  # P4: |Residual| by length bin
  df$abs_resid <- abs(df$Residual)
  df$LenBin <- factor(df$LenBin, levels = unique(len_label))

  p4 <- ggplot2::ggplot(df, ggplot2::aes(x = LenBin, y = abs_resid, fill = Model)) +
    ggplot2::geom_boxplot(alpha = 0.6, outlier.size = 0.5) +
    ggplot2::scale_fill_manual(values = cfg$colors) +
    ggplot2::labs(title = "|Residual| by length bin", x = "Length bin",
                  y = "Absolute log residual") +
    base_layers + no_legend +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  if (requireNamespace("patchwork", quietly = TRUE)) {
    top    <- patchwork::wrap_plots(p1, p2, ncol = 2)
    bottom <- patchwork::wrap_plots(p3, p4, ncol = 2)
    p <- patchwork::wrap_plots(top, bottom, ncol = 1) +
      patchwork::plot_annotation(
        title = .acl_title("compare_resid", model1_name, model2_name),
        theme = .acl_annotation_theme(cfg$legend_pos)) +
      patchwork::plot_layout(guides = "collect")
  } else {
    p <- p4
  }
  return(p)
}


# ==========================================================================
# plot_compare_growth: mean length at age + length distribution at age
# ==========================================================================

#' Compare mean length at age and the length distribution at age of two fits
#'
#' Left panel: mean length at age of each model, calculated on the same basis
#' for both ([length_at_age()]) and averaged over the time steps. For an ACL
#' fit the values come from its age-length key, and for an ALSCL fit from the
#' fitted numbers by length bin and age class. Observed mean length at age
#' from age readings can be added as points (`observed`), and a von
#' Bertalanffy curve fitted to observed age-length pairs with \code{nls()}
#' can be added as a reference (`ref_data`). Right panel: heatmaps of the
#' probability of length given age, side by side, on the same basis and for
#' the same time steps.
#'
#' The left panel does not draw curves from the growth parameters. In ACL,
#' Linf, k and t0 are the parameters of a von Bertalanffy curve of mean length
#' at age. In ALSCL they set the growth increment at length and the mean
#' length of recruits, so the parameters of the two models have different
#' meanings and are not compared (see [length_at_age()]). Earlier versions
#' drew one curve from the parameters of each model and listed Linf and k of
#' both models in the subtitle.
#'
#' @inheritParams plot_compare_ts
#' @param age_range Numeric vector of length 2, or NULL. NULL draws all age
#'   classes of both fits. An explicit range must be finite and increasing
#'   and selects the age classes within it; each fit needs at least one.
#' @param ref_data Optional data.frame with columns \code{Age} and \code{Length}
#'   containing observed age-length measurements (e.g. from otolith readings).
#'   If provided, a VB curve is fitted via \code{nls()} and overlaid as a
#'   reference, with the raw data as scatter points. The reference curve is
#'   drawn only at ages at or above its fitted t0, within the plotted ages. A
#'   fit with invalid growth parameters or no positive age span in that range
#'   is omitted with a warning; model lines and observed points are retained.
#'   The subtitle gives Linf and k of this curve, which are the parameters
#'   of a von Bertalanffy curve of the observed lengths at age.
#' @param ref_name Character. Nonempty label for the reference curve, distinct
#'   from both model labels when ref_data is supplied. Default "Observed VB".
#' @param ref_color Character. Color for the reference curve and its points,
#'   and for the points of `observed`. Default "grey30".
#' @param ref_linetype Character. Linetype for reference curve. Default "dotdash".
#' @param show_points Logical. Show raw data points from \code{ref_data}. Default TRUE.
#' @param point_size Numeric. Size of data points. NULL = use global theme.
#' @param point_alpha Numeric. Transparency of the raw data points of
#'   \code{ref_data}. Default 0.4.
#' @param nls_start Named list. Starting values for nls. Default attempts
#'   auto-detection from data range.
#' @param ... The former argument name linewidth, accepted with a warning.
#' @param observed NULL or a data frame of observed mean length at age from
#'   age readings, drawn as points in the left panel. Required columns: `age`
#'   (years) and `mean_length`. Optional columns: `sd_length` (or `sd`), drawn
#'   as bars of one standard deviation on each side of the mean, or `lower`
#'   and `upper`, drawn as the bars of an interval; and `year` (the time
#'   step). Every row is drawn as one point. With `years`, only the rows of
#'   those time steps are drawn; rows without a time step are always drawn.
#' @param basis `"population"` (default): mean length at age and the length
#'   distribution at age in the population. `"survey"`: in the survey catch,
#'   that is, with numbers at length multiplied by the survey catchability at
#'   length used in each fit. Use `"survey"` to compare with age readings of
#'   fish caught in the survey.
#' @param years NULL (all time steps of each fit) or the time steps over which
#'   the values are averaged. They must be time steps of both fits.
#' @param observed_name Character. Name of the points of `observed` in the
#'   legend, distinct from both model labels and from `ref_name`. Default is
#'   "Age readings".
#' @return A ggplot object.
#' @details Both panels need the ages, the length-bin midpoints and the time
#'   steps of each fit, and an ALSCL fit needs its numbers by length, age and
#'   time step. Results without them give an error. The heatmap cells sit at
#'   the ages in \code{model$age} and at the length-bin midpoints in
#'   \code{model$len_mid}. For an ACL fit on the population basis, the
#'   heatmap is its age-length key (\code{report$pla}). For an ALSCL fit it is
#'   the proportion of each age class in each length bin from the fitted
#'   numbers, averaged over the time steps; \code{report$pla} of an ALSCL fit
#'   is the length distribution of recruits (and, with the original structure,
#'   of every age class in the first time step) and is shown by [plot_pla()].
#'   The subtitle of the left panel states the basis and the time steps.
#' @seealso [length_at_age()], [plot_VB()], [plot_length_at_age()],
#'   [compare_models()].
#' @export
#'
#' @examples
#' \donttest{
#' # Fit both models to the last ten years of the example data. The shorter
#' # series and one fishing mortality rate (F) shared by all lengths in each
#' # year keep the ALSCL fit short.
#' x <- YTF_example
#' tables <- c("data.CatL", "data.wgt", "data.mat")
#' x[tables] <- lapply(x[tables], function(tab) tab[, c(1, 12:21)])
#' fit_acl <- run_acl(x, silent = TRUE)
#' fit_alscl <- run_alscl(x, F_structure = "year", silent = TRUE)
#'
#' # Mean length at age of both fits in the population
#' plot_compare_growth(fit_acl, fit_alscl)
#'
#' # With observed mean length at age from age readings, on the survey
#' # basis. These values are made up for the example.
#' readings <- data.frame(age = 1:8,
#'                        mean_length = c(12, 20, 27, 32, 37, 40, 43, 45),
#'                        sd_length = c(2, 2.5, 3, 3, 3.5, 3.5, 4, 4))
#' plot_compare_growth(fit_acl, fit_alscl, observed = readings, basis = "survey")
#'
#' # With observed age-length pairs and a von Bertalanffy curve fitted to them
#' obs <- data.frame(Age = c(1,1,2,2,3,3,4,5,6,7),
#'                   Length = c(20,22,30,28,38,35,42,48,50,52))
#' plot_compare_growth(fit_acl, fit_alscl, ref_data = obs)
#'
#' # Customize reference
#' plot_compare_growth(fit_acl, fit_alscl,
#'   ref_data = obs, ref_name = "Otolith data",
#'   ref_color = "forestgreen", show_points = TRUE)
#' }
plot_compare_growth <- function(model1, model2, age_range = NULL,
                                model1_name = NULL, model2_name = NULL,
                                colors = NULL, linetypes = NULL, line_size = NULL,
                                ref_data = NULL, ref_name = "Observed VB",
                                ref_color = "grey30", ref_linetype = "dotdash",
                                show_points = TRUE, point_size = NULL,
                                point_alpha = 0.4, nls_start = NULL, ...,
                                observed = NULL, basis = c("population", "survey"),
                                years = NULL, observed_name = "Age readings") {

  renamed <- .acl_renamed(list(...), "plot_compare_growth")
  if (is.null(line_size)) line_size <- renamed$line_size
  basis <- match.arg(basis)
  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]
  if (!is.null(ref_data)) {
    if (!is.character(ref_name) || length(ref_name) != 1L || is.na(ref_name) ||
        !nzchar(trimws(ref_name)))
      stop("ref_name must be a nonempty character string.", call. = FALSE)
    if (ref_name %in% model_names)
      stop("ref_name must be distinct from both model names.", call. = FALSE)
  }
  obs <- .acl_observed_length(observed)
  if (!is.null(obs)) {
    .acl_check_series_name(observed_name, "observed_name")
    if (observed_name %in% c(model_names, if (!is.null(ref_data)) ref_name))
      stop("observed_name must be distinct from both model names and from ref_name.", call. = FALSE)
    obs <- .acl_observed_years(obs, years)
  }
  cfg <- .acl_compare_defaults(colors = colors, linetypes = linetypes,
                               line_size = line_size, point_size = point_size,
                               m1 = model1_name, m2 = model2_name)

  # Mean length at age on the same basis for both fits: from the age-length
  # key of an ACL fit and from the fitted numbers of an ALSCL fit.
  series <- list(.acl_growth_series(model1, basis, years, "model1"),
                 .acl_growth_series(model2, basis, years, "model2"))
  if (!is.null(age_range))
    .acl_check_age_range(age_range, "; it selects the age classes to draw.")
  vb_df <- do.call(rbind, Map(function(x, name) {
    keep <- if (is.null(age_range)) seq_along(x$ages) else
      which(x$ages >= age_range[1L] & x$ages <= age_range[2L])
    if (!length(keep))
      stop("age_range contains no age class of ", name, ".", call. = FALSE)
    data.frame(Age = x$ages[keep], Length = x$mean[keep], Model = name)
  }, series, list(model1_name, model2_name)))
  if (is.null(age_range)) age_range <- range(vb_df$Age)
  valid_scalar <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)
  VB <- function(Linf, k, t0, age) Linf * (1 - exp(-k * (age - t0)))
  ages <- seq(age_range[1], age_range[2], by = 0.5)
  if (tail(ages, 1L) < age_range[2L]) ages <- c(ages, age_range[2L])

  all_colors <- cfg$colors
  all_linetypes <- cfg$linetypes
  ref_text <- NULL

  # Add reference VB curve from observed data
  if (!is.null(ref_data)) {
    if (!all(c("Age", "Length") %in% colnames(ref_data))) {
      stop("ref_data must have columns 'Age' and 'Length'")
    }

    # Auto starting values for nls
    if (is.null(nls_start)) {
      nls_start <- list(
        Linf = max(ref_data$Length) * 1.1,
        k    = 0.3,
        t0   = 0
      )
    }

    # Fit VB via nls
    nls_fit <- tryCatch(
      stats::nls(Length ~ Linf * (1 - exp(-k * (Age - t0))),
                 data = ref_data, start = nls_start,
                 control = stats::nls.control(maxiter = 200)),
      error = function(e) {
        warning("nls VB fitting failed: ", e$message, ". Skipping reference curve.")
        NULL
      }
    )

    if (!is.null(nls_fit)) {
      nls_coef <- stats::coef(nls_fit)
      if (!valid_scalar(nls_coef["Linf"]) || nls_coef["Linf"] <= 0 ||
          !valid_scalar(nls_coef["k"]) || nls_coef["k"] <= 0 ||
          !valid_scalar(nls_coef["t0"])) {
        warning("nls VB reference requires finite positive Linf and k and finite t0. Skipping reference curve.",
                call. = FALSE)
        nls_fit <- NULL
      } else if (max(age_range[1L], nls_coef["t0"]) >= age_range[2L]) {
        warning("nls VB reference has no positive age span at or above its t0 within age_range. Skipping reference curve.",
                call. = FALSE)
        nls_fit <- NULL
      }
    }
    if (!is.null(nls_fit)) {
      # The reference can have a later growth origin than the first plotted
      # age. Include that origin exactly without shortening the model lines.
      reference_ages <- sort(unique(c(max(age_range[1L], nls_coef["t0"]),
                                      ages[ages >= nls_coef["t0"]])))
      ref_curve <- data.frame(
        Age    = reference_ages,
        Length = VB(nls_coef["Linf"], nls_coef["k"], nls_coef["t0"], reference_ages),
        Model  = ref_name
      )
      vb_df <- rbind(vb_df, ref_curve)

      all_colors[ref_name]    <- ref_color
      all_linetypes[ref_name] <- ref_linetype
      ref_text <- sprintf("%s: Linf = %.1f, k = %.3f per year", ref_name, nls_coef["Linf"], nls_coef["k"])
    }
  }

  p_vb <- ggplot2::ggplot(vb_df, ggplot2::aes(x = Age, y = Length, color = Model, linetype = Model)) +
    ggplot2::geom_line(linewidth = cfg$line_size)
  # Raw age-length pairs of the reference data
  if (!is.null(ref_data) && show_points)
    p_vb <- p_vb +
      ggplot2::geom_point(
        data = ref_data,
        ggplot2::aes(x = Age, y = Length),
        color = ref_color, size = cfg$point_size,
        alpha = point_alpha, inherit.aes = FALSE
      )
  # Observed mean length at age: points named in a shape legend
  has_observed <- !is.null(obs) && nrow(obs) > 0L
  if (has_observed) {
    bars <- obs[is.finite(obs$lower) & is.finite(obs$upper), , drop = FALSE]
    if (nrow(bars)) p_vb <- p_vb + ggplot2::geom_errorbar(data = bars,
      ggplot2::aes(x = age, ymin = lower, ymax = upper), color = ref_color, width = 0, inherit.aes = FALSE)
    obs$Series <- observed_name
    p_vb <- p_vb +
      ggplot2::geom_point(data = obs, ggplot2::aes(x = age, y = mean_length, shape = Series),
                          color = ref_color, size = cfg$point_size, inherit.aes = FALSE) +
      ggplot2::scale_shape_manual(name = NULL, values = stats::setNames(16, observed_name))
  }

  same_years <- isTRUE(all.equal(series[[1L]]$years, series[[2L]]$years))
  sub_txt <- paste(c(
    if (same_years) .acl_growth_subtitle(basis, series[[1L]]$years, series[[1L]]$all_years,
                                         model1$growth_step) else
      paste0(.acl_growth_subtitle(basis, by_time = TRUE), ", mean of the time steps of each fit"),
    ref_text), collapse = "\n")
  p_vb <- p_vb +
    ggplot2::scale_color_manual(values = all_colors) +
    ggplot2::scale_linetype_manual(values = all_linetypes) +
    ggplot2::labs(title = .acl_title("compare_growth", model1_name, model2_name),
                  subtitle = sub_txt, caption = if (has_observed) .acl_caption(.acl_observed_caption(obs), 75),
                  x = .acl_lab("x", "age"), y = .acl_lab("y", "growth")) +
    .acl_base_theme() + ggplot2::theme(legend.position = cfg$legend_pos,
                                       plot.caption = ggplot2::element_text(hjust = 0))
  p_vb <- .acl_show_singletons(p_vb, "Model", point_size = cfg$point_size)

  # Probability of length given age on the same basis and for the same time
  # steps. Heatmap cells sit at fitted ages and length-bin midpoints, on the
  # same axes as the left panel.
  pla_parts <- Map(function(model, x, name) {
    mids <- model$len_mid
    if (any(diff(mids) <= 0))
      stop(name, " must have increasing length-bin midpoints.", call. = FALSE)
    list(pla = .acl_length_given_age(model, basis, x), ages = x$ages, mids = mids)
  }, list(model1, model2), series, list("model1", "model2"))
  # Cell size from the spacing of the coordinates; edge cells mirror their
  # inner half-width.
  cell_size <- function(x) {
    if (length(x) < 2L) return(rep(1, length(x)))
    half <- diff(x) / 2
    c(half[1L], half) + c(half, half[length(half)])
  }
  pla_df <- do.call(rbind, Map(function(part, name) {
    long <- .acl_matrix_long(part$pla, c("Length", "Age", "Probability"))
    long$Width <- cell_size(part$ages)[long$Age]
    long$Height <- cell_size(part$mids)[long$Length]
    long$Age <- part$ages[long$Age]
    long$Length <- part$mids[long$Length]
    long$Model <- rep(name, nrow(long))
    long
  }, pla_parts, list(model1_name, model2_name)))
  pla_df$Model <- factor(pla_df$Model, levels = c(model1_name, model2_name))

  p_pla <- ggplot2::ggplot(pla_df, ggplot2::aes(x = Age, y = Length, fill = Probability)) +
    ggplot2::geom_tile(ggplot2::aes(width = Width, height = Height)) + .acl_fill_continuous() +
    ggplot2::facet_wrap(~Model) +
    ggplot2::labs(title = "Probability of length given age",
                  x = .acl_lab("x", "age"), y = .acl_lab("y", "length")) +
    .acl_base_theme() + ggplot2::theme(strip.text = ggplot2::element_text(face = "bold"),
                                    legend.position = cfg$legend_pos)

  if (requireNamespace("patchwork", quietly = TRUE)) {
    p <- patchwork::wrap_plots(p_vb, p_pla, ncol = 2)
  } else { p <- p_pla }
  return(p)
}

# Probability of length given age (L x A) of one fit on one basis: the share
# of each age class in each length bin, averaged over the time steps of
# `series` (the result of .acl_growth_series()). For an ACL fit on the
# population basis this is its age-length key.
.acl_length_given_age <- function(fit, basis, series) {
  info <- list(model = series$model, years = series$all_years, ages = series$ages)
  numbers <- .acl_basis_numbers(fit, basis, info)$numbers
  keep <- match(series$years, series$all_years)
  share <- vapply(keep, function(y) {
    at_age <- numbers[, , y, drop = TRUE]
    dim(at_age) <- dim(numbers)[1:2]
    sweep(at_age, 2L, colSums(at_age), "/")
  }, matrix(0, dim(numbers)[1L], dim(numbers)[2L]))
  dim(share) <- c(dim(numbers)[1:2], length(keep))
  out <- apply(share, c(1L, 2L), mean, na.rm = TRUE)
  out[!is.finite(out)] <- NA_real_
  out
}


# ==========================================================================
# plot_compare_CatL: Observed vs predicted
# ==========================================================================

#' Compare Observed and Fitted Survey Indices at Length
#'
#' @inheritParams plot_compare_ts
#' @param data.CatL Survey index table used for both fits: a length-bin column
#'   followed by one column of survey indices per time step.
#' @param years Numeric vector of years to show. Default NULL = all years.
#'   Use e.g. \code{years = seq(1991, 2011, by = 2)} to select specific years.
#' @param facet_ncol Integer. Facet columns. Default 4.
#' @param facet_scales Character. Facet scales. Default "free_y".
#' @param obs_color Character. Color for observed points. Default "grey40".
#' @param point_size Numeric or NULL. Size of observed points. NULL uses an
#'   explicit obs_size first, then the comparison point-size override, if set,
#'   or the global point_size setting.
#' @param obs_size Numeric or NULL. Compatibility name for the observed point
#'   size. An explicit point_size takes priority when both are supplied.
#' @param obs_alpha Numeric. Transparency of observed points. Default 0.6.
#' @param obs_shape Integer. Shape of observed points. Default 16.
#' @param legend_pos Character. Legend position. NULL = use global theme.
#' @return A ggplot object.
#' @details Positive observations and their missing-data mask must match both
#'   fitted results whenever stored observations are available. Known length and
#'   time metadata must also match. Zeros and NA are omitted from observed points
#'   as in fitting; prediction curves retain every length in each selected period
#'   and must be finite at every plotted cell. Saved fits lacking observation
#'   metadata remain usable, but original-data alignment cannot be fully verified.
#'   Data frames, matrices and tibbles use the fitting functions' numeric conversion.
#'   The y-axis uses the global survey label, independently of the catch label.
#'   If survey is unset, a legacy custom abundance label is retained; otherwise
#'   the default is Survey index. The plotted predictions are exp(Elog_index).
#' @export
#'
#' @examples
#' \donttest{
#' # Fit both models to the last ten years of the example data. The shorter
#' # series and one fishing mortality rate (F) shared by all lengths in each
#' # year keep the ALSCL fit short.
#' x <- YTF_example
#' tables <- c("data.CatL", "data.wgt", "data.mat")
#' x[tables] <- lapply(x[tables], function(tab) tab[, c(1, 12:21)])
#' fit_acl <- run_acl(x, silent = TRUE)
#' fit_alscl <- run_alscl(x, F_structure = "year", silent = TRUE)
#'
#' # All years (default)
#' plot_compare_CatL(fit_acl, fit_alscl, x$data.CatL)
#'
#' # Select specific years
#' plot_compare_CatL(fit_acl, fit_alscl, x$data.CatL,
#'   years = c(2010, 2015, 2019))
#'
#' # Customize layout
#' plot_compare_CatL(fit_acl, fit_alscl, x$data.CatL,
#'   facet_ncol = 5, obs_color = "black", point_size = 2)
#' }
plot_compare_CatL <- function(model1, model2, data.CatL, years = NULL,
                              model1_name = NULL, model2_name = NULL,
                              colors = NULL, linetypes = NULL, line_size = NULL,
                              facet_ncol = 4, facet_scales = "free_y",
                              obs_color = "grey40", obs_size = NULL,
                              obs_alpha = 0.6, obs_shape = 16,
                              legend_pos = NULL, ..., point_size = NULL) {

  renamed <- .acl_renamed(list(...), "plot_compare_CatL")
  if (is.null(line_size)) line_size <- renamed$line_size
  if (missing(facet_ncol) && !is.null(renamed$facet_ncol)) facet_ncol <- renamed$facet_ncol
  if (missing(facet_scales) && !is.null(renamed$facet_scales)) facet_scales <- renamed$facet_scales
  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]
  cfg <- .acl_compare_defaults(colors = colors, linetypes = linetypes,
                               line_size = line_size, point_size = point_size %||% obs_size,
                               legend_pos = legend_pos, m1 = model1_name, m2 = model2_name)

  grid <- .acl_plot_comparison_grid(list(model1, model2), data.CatL, midpoints = TRUE)
  year <- grid$year; len_mid <- model1$len_mid; observed <- grid$observed
  if (length(year) != ncol(observed) || any(!is.finite(year)) || any(diff(year) <= 0))
    stop("data.CatL must have finite, increasing numeric time columns.", call. = FALSE)
  if ("Observed" %in% model_names)
    stop("Model names must differ from the observed-series label 'Observed'.", call. = FALSE)
  if (is.null(years)) years <- year
  if (!is.numeric(years) || !length(years) || any(!is.finite(years)))
    stop("years must contain finite numeric values.", call. = FALSE)
  years <- unique(years[years %in% year])
  if (!length(years)) stop("No requested years occur in data.CatL.", call. = FALSE)
  pred1 <- exp(model1$report$Elog_index); pred2 <- exp(model2$report$Elog_index)
  if (!identical(dim(pred1), dim(observed)) || !identical(dim(pred2), dim(observed)))
    stop("Prediction dimensions do not match data.CatL.", call. = FALSE)
  selected <- match(years, year)
  if (any(!is.finite(pred1[, selected, drop = FALSE])) ||
      any(!is.finite(pred2[, selected, drop = FALSE])))
    stop("Predictions must be finite at every plotted length and period.", call. = FALSE)

  df_list <- list()
  for (y in years) {
    yi <- which(year == y); if (length(yi) == 0) next
    observed_df <- data.frame(Length = len_mid, Value = observed[, yi], Source = "Observed", Year = y)
    valid <- is.finite(observed_df$Value) & observed_df$Value > 0
    df_list[[length(df_list) + 1]] <- observed_df[valid, , drop = FALSE]
    df_list[[length(df_list) + 1]] <- data.frame(Length = len_mid, Value = pred1[, yi], Source = model1_name, Year = y)
    df_list[[length(df_list) + 1]] <- data.frame(Length = len_mid, Value = pred2[, yi], Source = model2_name, Year = y)
  }
  df <- do.call(rbind, df_list); df$year_fct <- .acl_period_factor(df$Year, year, model1$growth_step)
  color_vals <- c("Observed" = obs_color, cfg$colors)
  has_observed <- any(df$Source == "Observed")
  legend_order <- c(model1_name, model2_name, if (has_observed) "Observed")

  p <- ggplot2::ggplot(df, ggplot2::aes(x = Length, y = Value, color = Source)) +
    ggplot2::geom_point(data = df[df$Source == "Observed", ],
                        size = cfg$point_size, alpha = obs_alpha, shape = obs_shape) +
    ggplot2::geom_line(data = df[df$Source != "Observed", ],
                        ggplot2::aes(linetype = Source), linewidth = cfg$line_size) +
    ggplot2::scale_color_manual(values = color_vals, breaks = legend_order) +
    ggplot2::scale_linetype_manual(values = cfg$linetypes, guide = "none") +
    ggplot2::guides(color = ggplot2::guide_legend(override.aes = list(
      linetype = c(unname(cfg$linetypes), if (has_observed) "blank"),
      shape = c(NA, NA, if (has_observed) obs_shape)))) +
    ggplot2::facet_wrap(~year_fct, ncol = facet_ncol, scales = facet_scales) +
    ggplot2::labs(title = .acl_title("compare_CatL", model1_name, model2_name),
                  x = .acl_lab("x", "length"), y = .acl_survey_label(), color = "") +
    .acl_base_theme() +
    ggplot2::theme(legend.position = cfg$legend_pos,
                   strip.text = ggplot2::element_text(face = "bold"))
  return(p)
}


# ==========================================================================
# plot_compare_metrics: Bar chart
# ==========================================================================

#' Compare Goodness-of-Fit Metrics
#'
#' @inheritParams plot_compare_ts
#' @param data.CatL Survey index table used for both fits: a length-bin column
#'   followed by one column of survey indices per time step.
#' @param metrics Character vector selecting which panels to show. Options:
#'   \code{"error"} (root mean squared error, RMSE, and mean absolute error,
#'   MAE), \code{"R2"} (coefficient of determination), \code{"MAPE"} (mean
#'   absolute percentage error), \code{"IC"} (Akaike information criterion,
#'   AIC, Bayesian information criterion, BIC, and the negative
#'   log-likelihood), \code{"npar"} (number of estimated parameters).
#'   Default NULL = all five panels. E.g. \code{metrics = c("error", "R2", "IC")}.
#' @param facet_ncol Integer or NULL. Columns of panels. NULL uses up to three.
#' @param legend_pos Character. Legend position. NULL = use global theme.
#' @param label_size Numeric. Text label size on bars. Default 3.2.
#' @param bar_width Numeric. Bar width. Default 0.6.
#' @param bar_alpha Numeric. Bar transparency. Default 0.85.
#' @param ... The former argument name ncol, accepted with a warning.
#' @return A ggplot object.
#' @export
#'
#' @examples
#' \donttest{
#' # Fit both models to the last ten years of the example data. The shorter
#' # series and one fishing mortality rate (F) shared by all lengths in each
#' # year keep the ALSCL fit short.
#' x <- YTF_example
#' tables <- c("data.CatL", "data.wgt", "data.mat")
#' x[tables] <- lapply(x[tables], function(tab) tab[, c(1, 12:21)])
#' fit_acl <- run_acl(x, silent = TRUE)
#' fit_alscl <- run_alscl(x, F_structure = "year", silent = TRUE)
#'
#' # All panels (default)
#' plot_compare_metrics(fit_acl, fit_alscl, x$data.CatL)
#'
#' # Only error and information criteria
#' plot_compare_metrics(fit_acl, fit_alscl, x$data.CatL,
#'   metrics = c("error", "IC"))
#' }
plot_compare_metrics <- function(model1, model2, data.CatL,
                                 model1_name = NULL, model2_name = NULL,
                                 colors = NULL, metrics = NULL,
                                 facet_ncol = NULL, legend_pos = NULL,
                                 label_size = 3.2, bar_width = 0.6,
                                 bar_alpha = 0.85, ...) {

  renamed <- .acl_renamed(list(...), "plot_compare_metrics")
  if (is.null(facet_ncol)) facet_ncol <- renamed$facet_ncol
  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]
  cfg <- .acl_compare_defaults(colors = colors, legend_pos = legend_pos,
                               m1 = model1_name, m2 = model2_name)

  calc_fit <- function(model, d) {
    measured <- diagnostic_metrics(d, model)
    metric_names <- c("RMSE", "MAE", "Rsquared", "MAPE", "AIC", "BIC")
    values <- measured$Value[match(metric_names, measured$Metric)]
    names(values) <- c("RMSE", "MAE", "R2", "MAPE", "AIC", "BIC")
    n_par <- .acl_npar(model)
    nll <- as.numeric(model$opt$objective)[1]
    c(values, "Neg. Log-Likelihood" = nll, "N. Parameters" = n_par)
  }
  .acl_plot_comparison_grid(list(model1, model2), data.CatL)
  f1 <- calc_fit(model1, data.CatL); f2 <- calc_fit(model2, data.CatL)
  df <- data.frame(Metric_Name = rep(names(f1), 2), Metric_Value = c(f1, f2),
                   Model = rep(c(model1_name, model2_name), each = length(f1)))
  base_layers <- .acl_base_theme()

  make_bar <- function(metric_names, title) {
    sub_df <- df[df$Metric_Name %in% metric_names, ]
    sub_df$Metric_Name <- factor(sub_df$Metric_Name, levels = metric_names)
    ggplot2::ggplot(sub_df, ggplot2::aes(x = Metric_Name, y = Metric_Value, fill = Model)) +
      ggplot2::geom_col(position = "dodge", alpha = bar_alpha, width = bar_width) +
      ggplot2::geom_text(ggplot2::aes(label = round(Metric_Value, 2)),
                         position = ggplot2::position_dodge(width = bar_width),
                         vjust = -0.3, size = label_size,
                         family = acl_theme("font_family")) +
      ggplot2::scale_fill_manual(values = cfg$colors) +
      ggplot2::labs(title = title, x = "", y = "") +
      base_layers + ggplot2::theme(legend.position = "none")
  }

  # Define available panels
  all_panels <- list(
    error = list(metrics = c("RMSE", "MAE"),                        title = "Error (survey index units)"),
    R2    = list(metrics = "R2",                                     title = "R-squared"),
    MAPE  = list(metrics = "MAPE",                                   title = "Mean absolute percentage error (%)"),
    IC    = list(metrics = c("AIC", "BIC", "Neg. Log-Likelihood"),   title = "Information criteria"),
    npar  = list(metrics = "N. Parameters",                          title = "Number of parameters")
  )

  # Select panels
  if (is.null(metrics)) metrics <- names(all_panels)
  panels <- list()
  for (m in metrics) {
    if (m %in% names(all_panels)) {
      panels[[m]] <- make_bar(all_panels[[m]]$metrics, all_panels[[m]]$title)
    }
  }

  if (length(panels) == 0) stop("No valid metrics selected. Choose from: error, R2, MAPE, IC, npar")

  if (requireNamespace("patchwork", quietly = TRUE)) {
    n <- length(panels)
    nc <- if (!is.null(facet_ncol)) facet_ncol else min(n, 3)
    # Add legend to last panel for collection
    panels[[length(panels)]] <- panels[[length(panels)]] +
      ggplot2::theme(legend.position = "bottom") +
      ggplot2::guides(fill = ggplot2::guide_legend(title = NULL))
    p <- patchwork::wrap_plots(panels, ncol = nc) +
      patchwork::plot_annotation(
        title = .acl_title("compare_metrics", model1_name, model2_name),
        theme = .acl_annotation_theme(cfg$legend_pos)) +
      patchwork::plot_layout(guides = "collect")
  } else { p <- panels[[1]] }
  return(p)
}


# Survey catchability at length of one fit for the catchability plots
# (plot_compare_selectivity() and plot_survey_catchability()): a vector with
# one value per length bin, or, when catchability supplied by length and time
# step differs among time steps, a matrix with one column for each distinct
# curve in time order. The attribute "curve" then gives the column of each
# time step.
.acl_plot_catchability <- function(model) {
  lengths <- model$len_mid
  if (!is.numeric(lengths) || !length(lengths) || any(!is.finite(lengths)))
    stop("Catchability plots require finite fitted length midpoints.", call. = FALSE)
  args <- model$recipe$args
  if (!is.null(args$survey_q)) {
    # Survey catchability at length supplied directly; it can exceed one.
    q <- args$survey_q
    by_time <- length(dim(q)) == 2L && ncol(q) > 1L
    if (!is.numeric(q) || (if (by_time) nrow(q) else length(q)) != length(lengths) ||
        any(!is.finite(q)) || any(q <= 0))
      stop("The saved recipe must have one finite positive survey_q value per length midpoint.",
           call. = FALSE)
    if (!by_time) return(as.numeric(q))
    # By time step: one curve for each distinct column, in time order.
    first <- !duplicated(t(q))
    distinct <- unname(q[, first, drop = FALSE])
    if (ncol(distinct) == 1L) return(as.numeric(distinct))
    attr(distinct, "curve") <- match(apply(q, 2L, paste, collapse = " "),
                                     apply(distinct, 2L, paste, collapse = " "))
    return(distinct)
  }
  if (!is.null(args$sel_L50) && !is.null(args$sel_L95)) {
    valid_scalar <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)
    if (!valid_scalar(args$sel_L50) || !valid_scalar(args$sel_L95) ||
        args$sel_L95 <= args$sel_L50)
      stop("The saved recipe must have finite sel_L50 and sel_L95 with sel_L95 greater than sel_L50.",
           call. = FALSE)
    log_q <- stats::plogis(log(19) * (lengths - args$sel_L50) /
                            (args$sel_L95 - args$sel_L50), log.p = TRUE)
  } else {
    log_q <- model$obj$env$data$log_q
  }
  if (!is.numeric(log_q) || length(log_q) != length(lengths) ||
      anyNA(log_q) || any(log_q > 0))
    stop("Catchability plots require a complete saved recipe or fitted log_q values matching the length midpoints.",
         call. = FALSE)
  exp(log_q)
}

# ==========================================================================
# plot_compare_selectivity
# ==========================================================================

#' Compare supplied survey catchability at length
#'
#' Connects the supplied catchability values directly, preserving their range.
#' The values are fixed model inputs, not estimated fishery selectivity.
#' @inheritParams plot_compare_ts
#' @param point_size Numeric or NULL. Point size. NULL inherits the comparison
#'   point-size override, if set, or the global point_size setting.
#' @param ... The former argument name linewidth, accepted with a warning.
#' @return A ggplot object.
#' @details Saved assessments are supported without refitting. Survey
#'   catchability is reconstructed from the saved recipe's sel_L50 and sel_L95
#'   at the fitted length midpoints, or taken from its survey_q when the fit
#'   used survey catchability at length supplied directly. Older fits without
#'   a recipe use log_q from their live TMB object. When survey_q was
#'   supplied by length and time step, one line is drawn for each distinct
#'   curve and a caption says so. A survey catchability multiplier by age
#'   (survey_q_age) is not shown.
#' @examples
#' \donttest{
#' # Fit both models to the last ten years of the example data. The shorter
#' # series and one fishing mortality rate (F) shared by all lengths in each
#' # year keep the ALSCL fit short.
#' x <- YTF_example
#' tables <- c("data.CatL", "data.wgt", "data.mat")
#' x[tables] <- lapply(x[tables], function(tab) tab[, c(1, 12:21)])
#' fit_acl <- run_acl(x, silent = TRUE)
#' fit_alscl <- run_alscl(x, F_structure = "year", silent = TRUE)
#' plot_compare_selectivity(fit_acl, fit_alscl)
#' }
#' @export
plot_compare_selectivity <- function(model1, model2,
                                     model1_name = NULL, model2_name = NULL,
                                     colors = NULL, linetypes = NULL, line_size = NULL, ..., point_size = NULL) {

  renamed <- .acl_renamed(list(...), "plot_compare_selectivity")
  if (is.null(line_size)) line_size <- renamed$line_size
  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]
  cfg <- .acl_compare_defaults(colors = colors, linetypes = linetypes,
                               line_size = line_size, point_size = point_size,
                               m1 = model1_name, m2 = model2_name)

  q1 <- .acl_plot_catchability(model1); q2 <- .acl_plot_catchability(model2)
  varying <- is.matrix(q1) || is.matrix(q2)
  if (!varying) {
    df <- rbind(data.frame(Length = model1$len_mid, Selectivity = q1, Model = model1_name),
                data.frame(Length = model2$len_mid, Selectivity = q2, Model = model2_name))
  } else {
    # Survey catchability that changes over time: one line per distinct curve.
    curves <- function(model, q, name) {
      q <- as.matrix(q)
      data.frame(Length = rep(model$len_mid, ncol(q)), Selectivity = as.vector(q), Model = name,
                 Curve = paste(name, rep(seq_len(ncol(q)), each = nrow(q))))
    }
    df <- rbind(curves(model1, q1, model1_name), curves(model2, q2, model2_name))
  }

  p <- ggplot2::ggplot(df, ggplot2::aes(x = Length, y = Selectivity, color = Model, linetype = Model)) +
    (if (varying) ggplot2::geom_line(ggplot2::aes(group = Curve), linewidth = cfg$line_size) else
      ggplot2::geom_line(linewidth = cfg$line_size)) +
    ggplot2::geom_point(size = cfg$point_size) +
    ggplot2::scale_color_manual(values = cfg$colors) +
    ggplot2::scale_linetype_manual(values = cfg$linetypes) +
    ggplot2::labs(title = .acl_title("compare_sel", model1_name, model2_name),
                  x = .acl_lab("x", "length"), y = .acl_lab("y", "survey_q")) +
    .acl_base_theme() + ggplot2::theme(legend.position = cfg$legend_pos)
  if (varying) p <- p + ggplot2::labs(
    caption = "Survey catchability supplied by time step: one line for each distinct curve of a fit.")
  return(p)
}


# ==========================================================================
# plot_compare_F_ts
# ==========================================================================

#' Compare Fishing Mortality by Time Step
#'
#' One summary value of the fishing mortality rate (F) per model time step for
#' each fit, on the same axes. Quarterly fits stay quarterly; nothing is
#' annualized. The y-axis label gives the time basis of the rate and the
#' caption states the groups that each summary covers.
#'
#' @inheritParams plot_compare_ts
#' @param method Character. How to summarize F across groups in each model
#'   time step.
#'   \code{"apical"} (default): maximum F across groups.
#'   \code{"mean"}: unweighted arithmetic mean across groups.
#' @param basis Character. The groups over which F is summarized.
#'   \code{"native"} (default) uses the F matrix that each model estimates: F at
#'   age for ACL and F at length for ALSCL. An ACL summary and an ALSCL summary
#'   then cover different groups. An unweighted mean depends on the number of
#'   low-F groups, and a maximum over ages need not equal a maximum over length
#'   bins, because F at age combines survival across lengths. Read the time
#'   pattern of such a pair, not the difference in level.
#'   \code{"age"} uses F at age for both fits: \code{report$F} for ACL and the
#'   derived \code{report$FA} for ALSCL. Only the fitted ages and the time
#'   steps present in both fits are summarized. ALSCL F at age covers every age
#'   and time step when the fit holds numbers at length and age; otherwise it
#'   has no plus-group row and no value for the last time step, and the
#'   comparison leaves out the ACL plus group and the last time step. The two
#'   fits must have the same time step.
#' @param point_size Numeric or NULL. Point size. NULL inherits the comparison
#'   point-size override, if set, or the global point_size setting.
#' @param ... The former argument name linewidth, accepted with a warning.
#' @return A ggplot object.
#' @examples
#' \donttest{
#' # Fit both models to the last ten years of the example data. The shorter
#' # series and one fishing mortality rate (F) shared by all lengths in each
#' # year keep the ALSCL fit short.
#' x <- YTF_example
#' tables <- c("data.CatL", "data.wgt", "data.mat")
#' x[tables] <- lapply(x[tables], function(tab) tab[, c(1, 12:21)])
#' fit_acl <- run_acl(x, silent = TRUE)
#' fit_alscl <- run_alscl(x, F_structure = "year", silent = TRUE)
#'
#' # Largest fishing mortality rate over ages (ACL) or lengths (ALSCL) in
#' # each year
#' plot_compare_F_ts(fit_acl, fit_alscl)
#'
#' # Mean fishing mortality rate at age over the ages that both fits share
#' plot_compare_F_ts(fit_acl, fit_alscl, method = "mean", basis = "age")
#' }
#' @export
plot_compare_F_ts <- function(model1, model2,
                              model1_name = NULL, model2_name = NULL,
                              method = c("apical", "mean"),
                              colors = NULL, linetypes = NULL, line_size = NULL, ..., point_size = NULL,
                              basis = c("native", "age")) {

  renamed <- .acl_renamed(list(...), "plot_compare_F_ts")
  if (is.null(line_size)) line_size <- renamed$line_size
  method <- match.arg(method)
  basis <- match.arg(basis)
  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]
  cfg <- .acl_compare_defaults(colors = colors, linetypes = linetypes,
                               line_size = line_size, point_size = point_size,
                               m1 = model1_name, m2 = model2_name)
  summarize <- function(Fmat) if (method == "apical") apply(Fmat, 2, max) else colMeans(Fmat)
  summary_name <- if (method == "apical") "maximum" else "mean"

  get_F <- function(m, mname) {
    Fmat <- if (!is.null(m$report$FL)) m$report$FL else m$report[["F"]]
    if (!is.matrix(Fmat) || !is.numeric(Fmat) || !nrow(Fmat) || !ncol(Fmat))
      stop(mname, " must contain a numeric F or FL matrix.", call. = FALSE)
    years <- .acl_plot_year(m, ncol(Fmat), mname)
    list(data = data.frame(Year = years, MeanF = summarize(Fmat), Model = mname),
         groups = paste(nrow(Fmat), if (!is.null(m$report$FL)) "length bins" else "ages"))
  }
  # F at age with its fitted ages and time steps. ALSCL F at age (FA) is
  # completed with the plus group and the last time step when the fit holds
  # numbers at length and age; otherwise it has neither.
  get_F_age <- function(m, mname) {
    alscl <- !is.null(m$report$FL)
    completed <- if (alscl) .acl_F_at_age(m)
    Fmat <- if (alscl) (if (is.null(completed)) m$report$FA else completed$FA) else m$report[["F"]]
    short <- alscl && !isTRUE(completed$complete)
    if (!is.matrix(Fmat) || !is.numeric(Fmat) || !nrow(Fmat) || !ncol(Fmat) ||
        any(!is.finite(Fmat)))
      stop(mname, " has no finite F-at-age matrix (", if (alscl) "report$FA" else "report$F",
           "), which basis = \"age\" needs. Use basis = \"native\".", call. = FALSE)
    years <- .acl_plot_year(m, ncol(Fmat) + short, mname)
    ages <- .acl_fitted_ages(m, nrow(Fmat), plus_group = !short)
    if (is.null(ages))
      stop(mname, " has no age metadata matching its F-at-age matrix, so basis = \"age\" ",
           "cannot match ages between the fits. Use basis = \"native\".", call. = FALSE)
    list(F = Fmat, years = years[seq_len(ncol(Fmat))], ages = ages,
         plus = if (short) rep(FALSE, length(ages)) else seq_along(ages) == length(ages))
  }

  if (basis == "native") {
    f1 <- get_F(model1, model1_name); f2 <- get_F(model2, model2_name)
    df <- rbind(f1$data, f2$data)
    caption <- paste0(model1_name, ": ", summary_name, " across ", f1$groups, ". ",
                      model2_name, ": ", summary_name, " across ", f2$groups, ".")
  } else {
    a1 <- get_F_age(model1, model1_name); a2 <- get_F_age(model2, model2_name)
    steps <- c(model1$growth_step, model2$growth_step)
    if (length(steps) == 2L && all(is.finite(steps)) && abs(diff(steps)) > 1e-8)
      stop("basis = \"age\" needs fits with the same time step, because F is a rate per time step. ",
           model1_name, " has a step of ", steps[1L], " years and ", model2_name, " a step of ", steps[2L],
           " years.", call. = FALSE)
    key <- function(x) round(x, 8)
    ages <- intersect(key(a1$ages), key(a2$ages))
    # An age that is a plus group in only one fit covers different fish.
    same_kind <- a1$plus[match(ages, key(a1$ages))] == a2$plus[match(ages, key(a2$ages))]
    ages <- ages[same_kind]
    years <- intersect(key(a1$years), key(a2$years))
    if (!length(ages) || !length(years))
      stop("basis = \"age\" needs at least one fitted age and one time step present in both fits. ",
           "The fits share ", length(ages), " age(s) and ", length(years),
           " time step(s). Use basis = \"native\".", call. = FALSE)
    age_summary <- function(a, mname) {
      Fmat <- a$F[match(ages, key(a$ages)), match(years, key(a$years)), drop = FALSE]
      data.frame(Year = a$years[match(years, key(a$years))], MeanF = summarize(Fmat), Model = mname)
    }
    df <- rbind(age_summary(a1, model1_name), age_summary(a2, model2_name))
    plus <- any(a1$plus[match(ages, key(a1$ages))])
    caption <- paste0("Both fits: ", summary_name, " across ", length(ages),
      if (length(ages) == 1L) " age (" else " ages (", min(ages),
      if (length(ages) > 1L) paste0(" to ", max(ages), if (plus) "+"), "), in the ",
      length(years), " time steps that both fits share.")
  }

  bases <- unique(c(.acl_rate_basis(model1), .acl_rate_basis(model2)))
  rate_basis <- if (length(bases) == 1L) bases else "per time step"
  ylab <- paste0(if (method == "apical") "Apical fishing mortality rate (" else
    "Mean fishing mortality rate (", rate_basis, ")")
  p <- ggplot2::ggplot(df, ggplot2::aes(x = Year, y = MeanF, color = Model, linetype = Model)) +
    ggplot2::geom_line(linewidth = cfg$line_size) +
    ggplot2::geom_point(size = cfg$point_size) +
    ggplot2::scale_color_manual(values = cfg$colors) +
    ggplot2::scale_linetype_manual(values = cfg$linetypes) +
    ggplot2::labs(title = .acl_title("compare_F_ts", model1_name, model2_name),
                  x = .acl_lab("x", "year"), y = ylab, caption = caption) +
    .acl_base_theme() + .acl_scale_x(values = df$Year, check_overlap = TRUE) +
    ggplot2::theme(legend.position = cfg$legend_pos)
  return(p)
}


#' Former name of plot_compare_F_ts()
#'
#' Deprecated. \code{plot_compare_annual_F()} summarizes F per model time step
#' and never annualized quarterly values, so it is now called
#' \code{\link{plot_compare_F_ts}()}. This alias warns once per session and
#' will be removed in a later release.
#'
#' @param ... Arguments passed to \code{plot_compare_F_ts()}.
#' @return A ggplot object.
#' @export
plot_compare_annual_F <- function(...) {
  .acl_deprecated_function("plot_compare_annual_F")
  plot_compare_F_ts(...)
}
