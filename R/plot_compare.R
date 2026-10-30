utils::globalVariables(c(
  "Model", "Year", "Value", "lower", "upper", "estimate",
  "Quantity", "Age", "Length", "Probability", "From", "To",
  "LenBin", "YearIdx", "F_value", "Label", "Residual",
  "Observed", "Predicted", "Metric_Name", "Metric_Value",
  "abs_resid", "year_fct", "MeanF", "Selectivity", "Source",
  "mean_r", "sd_r"
))

# ---------------------------------------------------------------------------
# Internal: detect model name
# ---------------------------------------------------------------------------
.detect_model_name <- function(m, fallback) {
  if (!is.null(m$model_type)) return(m$model_type)
  if (!is.null(m$report$FL))  return("ALSCL")
  if (!is.null(m$report$F))   return("ACL")
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
  if (length(dim(data.CatL)) != 2L || ncol(data.CatL) < 2L)
    stop("data.CatL must contain length labels and time columns.", call. = FALSE)
  data.CatL <- as.data.frame(data.CatL, stringsAsFactors = FALSE)
  original <- as.matrix(data.CatL[, -1L, drop = FALSE])
  observed <- suppressWarnings(matrix(as.numeric(original), nrow(original), ncol(original)))
  if (any(is.na(observed) & !is.na(original)) || any(is.infinite(observed)) ||
      any(observed < 0, na.rm = TRUE))
    stop("Comparison observations must be numeric, nonnegative and finite, or NA.", call. = FALSE)
  years <- suppressWarnings(as.numeric(sub("^X", "", colnames(data.CatL)[-1L])))
  labels <- trimws(as.character(data.CatL[, 1L]))
  for (i in seq_along(models)) {
    model <- models[[i]]
    fail <- function(part) stop("Model ", i, " does not match data.CatL: ", part, ".",
                                call. = FALSE)
    if (!is.null(model$year)) {
      fit_years <- .acl_plot_year(model, ncol(observed), paste("Model", i))
      if (length(years) != length(fit_years) || any(!is.finite(years)) ||
          any(abs(fit_years - years) > 1e-8)) fail("time columns")
    }
    if (!is.null(model$len_label) &&
        !identical(trimws(as.character(model$len_label)), labels)) fail("length labels/order")
    if (midpoints && (!is.numeric(model$len_mid) ||
        length(model$len_mid) != nrow(observed) || any(!is.finite(model$len_mid)) ||
        any(diff(model$len_mid) <= 0))) fail("length midpoints")
  }
  if (midpoints && !isTRUE(all.equal(as.numeric(models[[1L]]$len_mid),
                                     as.numeric(models[[2L]]$len_mid), tolerance = 1e-8)))
    stop("Models have different length midpoints; a paired catch-at-length plot requires the same grid.",
         call. = FALSE)
  list(observed = observed, year = years, len_label = labels)
}


# ==========================================================================
# plot_compare_ts: Time-series comparison
# ==========================================================================

#' Compare Time-Series Outputs of Two Models
#'
#' Plots SSB, Recruitment, Biomass, Abundance, Catch from two models
#' on the same axes. Fully supports the global theme system and can be
#' extended with \code{+ ggplot2::theme()} or any ggplot2 layer.
#'
#' @param model1 First model result (reference).
#' @param model2 Second model result (alternative).
#' @param quantities Character vector. Quantities to compare. Accepts: "SSB", "R" (or "Rec"),
#'   "B", "N", "CN", "CB". Default c("SSB","R","B","N","CN"), the
#'   quantities reported with uncertainty by both ACL and ALSCL. CB can be
#'   requested explicitly when both supplied results contain it.
#'   For F, use \code{plot_compare_annual_F()} and explicitly choose the group
#'   mean or apical summary; F is not a scalar time series in the model reports.
#' @param se Logical. Show confidence intervals. Default FALSE.
#' @param model1_name,model2_name Character. Labels. Auto-detected if NULL.
#' @param colors Named character vector of 2 colors. NULL = use global theme.
#' @param linetypes Named character vector of 2 linetypes. NULL = use global theme.
#' @param linewidth Numeric. NULL = use global theme.
#' @param ncol Integer. Facet columns. NULL = use global theme.
#' @param scales Character. Facet scales. NULL = use global theme.
#' @param return_data Logical. Return data alongside plot. Default FALSE.
#'
#' @return A ggplot object (can be further modified with + theme(), + labs(), etc.)
#' @details Every requested quantity must be a finite series matching its model's
#'   time metadata. Unknown or unavailable quantities are errors, rather than
#'   silently omitted panels. With se = TRUE, both models must have complete,
#'   finite estimates and finite nonnegative standard errors for every requested
#'   quantity. Use se = FALSE when uncertainty is unavailable.
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' plot_compare_ts(result_acl, result_alscl)
#'
#' # With CI
#' plot_compare_ts(result_acl, result_alscl, se = TRUE)
#'
#' # Per-call override + ggplot2 layering
#' plot_compare_ts(result_acl, result_alscl,
#'   colors = c(ACL = "darkgreen", ALSCL = "orange")) +
#'   ggplot2::theme(legend.position = "top") +
#'   ggplot2::labs(title = "My Title")
#'
#' # Or set globally once
#' acl_theme_set(
#'   compare_colors = c(ACL = "steelblue", ALSCL = "tomato"),
#'   compare_linetypes = c(ACL = "solid", ALSCL = "longdash"),
#'   base_theme = "theme_classic"
#' )
#' plot_compare_ts(result_acl, result_alscl)  # uses global settings
#' }
plot_compare_ts <- function(model1, model2,
                            quantities = c("SSB", "R", "B", "N", "CN"),
                            se = FALSE,
                            model1_name = NULL, model2_name = NULL,
                            colors = NULL, linetypes = NULL, linewidth = NULL,
                            ncol = NULL, scales = NULL,
                            return_data = FALSE) {

  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]

  cfg <- .acl_compare_defaults(colors = colors, linetypes = linetypes,
                               linewidth = linewidth, ncol = ncol, scales = scales,
                               m1 = model1_name, m2 = model2_name)
  year1 <- .acl_plot_year(model1, name = model1_name)
  year2 <- .acl_plot_year(model2, name = model2_name)
  if (!is.logical(se) || length(se) != 1L || is.na(se))
    stop("se must be TRUE or FALSE.", call. = FALSE)
  if (!is.character(quantities) || !length(quantities) || anyNA(quantities) ||
      any(!nzchar(quantities)))
    stop("quantities must be a nonempty character vector of supported quantities.", call. = FALSE)
  if (any(quantities %in% c("F", "f")))
    stop("F is a group-by-time quantity. Use plot_compare_annual_F() with method = 'mean' ",
         "or 'apical' to choose its time-series summary.", call. = FALSE)

  # Aliases: user-friendly names -> report field names
  qty_aliases <- c(R = "Rec", Rec = "Rec", rec = "Rec",
                   SSB = "SSB", ssb = "SSB",
                   B = "B", biomass = "B",
                   N = "N", abundance = "N",
                   CN = "CN", catch = "CN",
                   CB = "CB")

  qty_labels <- c(SSB = "Spawning Stock Biomass", Rec = "Recruitment",
                  B = "Total Biomass", N = "Total Abundance",
                  CN = "Catch Numbers", CB = "Catch Biomass")

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
    ggplot2::geom_line(linewidth = cfg$linewidth) +
    ggplot2::scale_color_manual(values = cfg$colors) +
    ggplot2::scale_linetype_manual(values = cfg$linetypes) +
    ggplot2::facet_wrap(~Quantity, ncol = cfg$ncol, scales = cfg$scales) +
    ggplot2::labs(title = .acl_title("compare_ts", model1_name, model2_name),
                  x = .acl_lab("x", "year"), y = "Value",
                  color = "Model", linetype = "Model") +
    .acl_base_theme() +
    .acl_scale_x() +
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
        ribbon_list[[length(ribbon_list) + 1]] <- data.frame(
          Year = years, estimate = ss[, "Estimate"],
          lower = ss[, "Estimate"] - 1.96 * ss[, "Std. Error"],
          upper = ss[, "Estimate"] + 1.96 * ss[, "Std. Error"],
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
      ) + ggplot2::scale_fill_manual(values = cfg$colors)
    }
  }

  if (return_data) return(list(plot = p, data = df)) else return(p)
}


# ==========================================================================
# plot_compare_F: Fishing mortality heatmap
# ==========================================================================

#' Compare Fishing Mortality Heatmaps Between Two Models
#'
#' @inheritParams plot_compare_ts
#' @param palette Character or NULL. NULL uses the global sequential colors; a ggsci palette name or a viridis option overrides them.
#' @return A ggplot object.
#' @export
plot_compare_F <- function(model1, model2,
                           model1_name = NULL, model2_name = NULL,
                           palette = NULL) {

  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]

  extract_F <- function(model, mname) {
    is_alscl <- is.null(model$report$F) && !is.null(model$report$FL)
    Fmat <- if (is_alscl) model$report$FL else model$report$F
    if (!is.matrix(Fmat) || !is.numeric(Fmat) || !nrow(Fmat) || !ncol(Fmat))
      stop(mname, " must contain a numeric F or FL matrix.", call. = FALSE)
    if (is_alscl) {
      labels <- if (!is.null(model$len_label)) model$len_label else paste0("L", seq_len(nrow(Fmat)))
      dim_type <- "length"
    } else {
      labels <- paste("Age", seq_len(nrow(Fmat)))
      dim_type <- "age"
    }
    years <- .acl_plot_year(model, ncol(Fmat), mname)
    if (length(labels) != nrow(Fmat) || anyNA(labels) || anyDuplicated(labels))
      stop(mname, " length labels must match the F matrix rows and be distinct.", call. = FALSE)
    df <- data.frame(Year = rep(years, each = nrow(Fmat)),
                     F_value = as.numeric(Fmat),
                     Label = factor(rep(labels, ncol(Fmat)), levels = rev(labels)))
    df$Model <- mname
    attr(df, "dim_type") <- dim_type
    return(df)
  }

  df1 <- extract_F(model1, model1_name)
  df2 <- extract_F(model2, model2_name)

  # Warn if comparing different dimensions
  if (attr(df1, "dim_type") != attr(df2, "dim_type")) {
    message("Note: ", model1_name, " uses F-at-", attr(df1, "dim_type"),
            " while ", model2_name, " uses F-at-", attr(df2, "dim_type"),
            ". The heatmap y-axes are not directly comparable.\n",
            "  Use plot_compare_annual_F() for a comparable summary.")
  }

  df <- rbind(df1, df2)
  df$Model <- factor(df$Model, levels = c(model1_name, model2_name))

  p <- ggplot2::ggplot(df, ggplot2::aes(x = Year, y = Label, fill = F_value)) +
    ggplot2::geom_tile() +
    .acl_fill_continuous(palette, name = "F") +
    ggplot2::facet_wrap(~Model, scales = "free_y") +
    ggplot2::labs(title = .acl_title("compare_F", model1_name, model2_name),
                  x = .acl_lab("x", "year"), y = "") +
    .acl_base_theme() + .acl_scale_x() +
    ggplot2::theme(strip.text = ggplot2::element_text(face = "bold", size = 12))

  return(p)
}


# ==========================================================================
# plot_compare_residuals: 4-panel diagnostics
# ==========================================================================

#' Compare Residual Diagnostics Between Two Models
#'
#' Four panels: histogram, QQ plot, mean residual by year, |residual| by length.
#' A single unified color legend is displayed (default: bottom center).
#'
#' @inheritParams plot_compare_ts
#' @param data.CatL Catch-at-length data frame.
#' @param bins Integer. Histogram bins. Default 35.
#' @param point_size Numeric. Point size. NULL = use global theme.
#' @param legend_pos Character. Legend position. NULL = use global theme (default "bottom").
#' @param qq_alpha Numeric. QQ point transparency. Default 0.6.
#' @param errorbar_width Numeric. Error bar cap width. Default 0.3.
#' @return A ggplot object (combined 4-panel via patchwork).
#' @export
plot_compare_residuals <- function(model1, model2, data.CatL,
                                   model1_name = NULL, model2_name = NULL,
                                   colors = NULL, linetypes = NULL,
                                   linewidth = NULL, point_size = NULL,
                                   legend_pos = NULL, bins = 35,
                                   qq_alpha = 0.6, errorbar_width = 0.3) {

  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]
  cfg <- .acl_compare_defaults(colors = colors, linetypes = linetypes,
                               linewidth = linewidth, point_size = point_size,
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

  # P1: Histogram -- keeps legend (will be collected to bottom)
  p1 <- ggplot2::ggplot(df, ggplot2::aes(x = Residual, fill = Model)) +
    ggplot2::geom_histogram(alpha = 0.5, position = "identity", bins = bins) +
    ggplot2::scale_fill_manual(values = cfg$colors) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
    ggplot2::labs(title = "Residual Distribution", x = "Residual", y = "Count") +
    base_layers +
    ggplot2::guides(fill = ggplot2::guide_legend(title = NULL)) +
    ggplot2::theme(legend.position = "bottom")

  # P2: QQ
  p2 <- ggplot2::ggplot(df, ggplot2::aes(sample = Residual, color = Model)) +
    ggplot2::stat_qq(size = 0.8, alpha = qq_alpha) + ggplot2::stat_qq_line() +
    ggplot2::scale_color_manual(values = cfg$colors) +
    ggplot2::labs(title = "QQ Plot", x = "Theoretical", y = "Sample") +
    base_layers + no_legend

  # P3: Mean residual by year
  resid_by_year <- do.call(rbind, lapply(split(df, list(df$Year, df$Model), drop = TRUE), function(x) {
    data.frame(Year = x$Year[1], Model = x$Model[1],
               mean_r = mean(x$Residual), sd_r = stats::sd(x$Residual),
               stringsAsFactors = FALSE)
  }))

  p3 <- ggplot2::ggplot(resid_by_year, ggplot2::aes(x = Year, y = mean_r, color = Model)) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    ggplot2::geom_line(linewidth = cfg$linewidth) +
    ggplot2::geom_point(size = cfg$point_size) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = mean_r - sd_r, ymax = mean_r + sd_r),
                           width = errorbar_width, alpha = 0.5) +
    ggplot2::scale_color_manual(values = cfg$colors) +
    ggplot2::labs(title = "Mean Residual by Year", x = "Year", y = "Mean Residual") +
    base_layers + .acl_scale_x() + no_legend

  # P4: |Residual| by length bin
  df$abs_resid <- abs(df$Residual)
  df$LenBin <- factor(df$LenBin, levels = unique(len_label))

  p4 <- ggplot2::ggplot(df, ggplot2::aes(x = LenBin, y = abs_resid, fill = Model)) +
    ggplot2::geom_boxplot(alpha = 0.6, outlier.size = 0.5) +
    ggplot2::scale_fill_manual(values = cfg$colors) +
    ggplot2::labs(title = "|Residual| by Length Bin", x = "Length Bin", y = "|Residual|") +
    base_layers + no_legend +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  if (requireNamespace("patchwork", quietly = TRUE)) {
    top    <- patchwork::wrap_plots(p1, p2, ncol = 2)
    bottom <- patchwork::wrap_plots(p3, p4, ncol = 2)
    p <- patchwork::wrap_plots(top, bottom, ncol = 1) +
      patchwork::plot_annotation(
        title = .acl_title("compare_resid", model1_name, model2_name),
        theme = ggplot2::theme(legend.position = cfg$legend_pos)) +
      patchwork::plot_layout(guides = "collect")
  } else {
    p <- p4
  }
  return(p)
}


# ==========================================================================
# plot_compare_growth: VB + pla
# ==========================================================================

#' Compare Growth Curves and Length-at-Age Matrices
#'
#' Left panel: VB growth curves from each model. Optionally overlay a VB curve
#' fitted independently from observed age-length data via \code{nls()}.
#' Right panel: pla heatmaps side-by-side.
#'
#' @inheritParams plot_compare_ts
#' @param age_range Numeric vector of length 2. Default c(1, 20).
#' @param ref_data Optional data.frame with columns \code{Age} and \code{Length}
#'   containing observed age-length measurements (e.g. from otolith readings).
#'   If provided, a VB curve is fitted via \code{nls()} and overlaid as a
#'   reference, with the raw data as scatter points.
#' @param ref_name Character. Label for the reference curve. Default "Observed VB".
#' @param ref_color Character. Color for reference curve/points. Default "grey30".
#' @param ref_linetype Character. Linetype for reference curve. Default "dotdash".
#' @param show_points Logical. Show raw data points from \code{ref_data}. Default TRUE.
#' @param point_size Numeric. Size of data points. NULL = use global theme.
#' @param point_alpha Numeric. Transparency of data points. Default 0.4.
#' @param nls_start Named list. Starting values for nls. Default attempts
#'   auto-detection from data range.
#' @return A ggplot object.
#' @export
#'
#' @examples
#' \dontrun{
#' # Without reference data
#' plot_compare_growth(result_acl, result_alscl)
#'
#' # With observed age-length data
#' obs <- data.frame(Age = c(1,1,2,2,3,3,4,5,6,7),
#'                   Length = c(20,22,30,28,38,35,42,48,50,52))
#' plot_compare_growth(result_acl, result_alscl, ref_data = obs)
#'
#' # Customize reference
#' plot_compare_growth(result_acl, result_alscl,
#'   ref_data = obs, ref_name = "Otolith data",
#'   ref_color = "forestgreen", show_points = TRUE)
#' }
plot_compare_growth <- function(model1, model2, age_range = c(1, 20),
                                model1_name = NULL, model2_name = NULL,
                                colors = NULL, linetypes = NULL, linewidth = NULL,
                                ref_data = NULL, ref_name = "Observed VB",
                                ref_color = "grey30", ref_linetype = "dotdash",
                                show_points = TRUE, point_size = NULL,
                                point_alpha = 0.4, nls_start = NULL) {

  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]
  cfg <- .acl_compare_defaults(colors = colors, linetypes = linetypes,
                               linewidth = linewidth, point_size = point_size,
                               m1 = model1_name, m2 = model2_name)

  VB <- function(Linf, k, t0, age) Linf * (1 - exp(-k * (age - t0)))
  ages <- seq(age_range[1], age_range[2], by = 0.5)
  vb_df <- rbind(
    data.frame(Age = ages, Length = VB(model1$report$Linf, model1$report$vbk, model1$report$t0, ages), Model = model1_name),
    data.frame(Age = ages, Length = VB(model2$report$Linf, model2$report$vbk, model2$report$t0, ages), Model = model2_name))

  # Build color/linetype scales including optional ref
  all_colors <- cfg$colors
  all_linetypes <- cfg$linetypes

  p_vb <- ggplot2::ggplot(vb_df, ggplot2::aes(x = Age, y = Length, color = Model, linetype = Model)) +
    ggplot2::geom_line(linewidth = cfg$linewidth)

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
      ref_curve <- data.frame(
        Age    = ages,
        Length = VB(nls_coef["Linf"], nls_coef["k"], nls_coef["t0"], ages),
        Model  = ref_name
      )
      vb_df <- rbind(vb_df, ref_curve)

      all_colors[ref_name]    <- ref_color
      all_linetypes[ref_name] <- ref_linetype
    }

    # Scatter points
    if (show_points) {
      p_vb <- p_vb +
        ggplot2::geom_point(
          data = ref_data,
          ggplot2::aes(x = Age, y = Length),
          color = ref_color, size = cfg$point_size,
          alpha = point_alpha, inherit.aes = FALSE
        )
    }

    # Rebuild with all data (including ref curve)
    p_vb <- ggplot2::ggplot(vb_df, ggplot2::aes(x = Age, y = Length, color = Model, linetype = Model)) +
      ggplot2::geom_line(linewidth = cfg$linewidth)

    if (show_points) {
      p_vb <- p_vb +
        ggplot2::geom_point(
          data = ref_data,
          ggplot2::aes(x = Age, y = Length),
          color = ref_color, size = cfg$point_size,
          alpha = point_alpha, inherit.aes = FALSE
        )
    }

    # Subtitle with ref params
    if (!is.null(nls_fit)) {
      sub_txt <- sprintf("%s: Linf=%.1f, k=%.3f | %s: Linf=%.1f, k=%.3f | %s: Linf=%.1f, k=%.3f",
                         model1_name, model1$report$Linf, model1$report$vbk,
                         model2_name, model2$report$Linf, model2$report$vbk,
                         ref_name, nls_coef["Linf"], nls_coef["k"])
    } else {
      sub_txt <- sprintf("%s: Linf=%.1f, k=%.3f | %s: Linf=%.1f, k=%.3f",
                         model1_name, model1$report$Linf, model1$report$vbk,
                         model2_name, model2$report$Linf, model2$report$vbk)
    }
  } else {
    sub_txt <- sprintf("%s: Linf=%.1f, k=%.3f | %s: Linf=%.1f, k=%.3f",
                       model1_name, model1$report$Linf, model1$report$vbk,
                       model2_name, model2$report$Linf, model2$report$vbk)
  }

  p_vb <- p_vb +
    ggplot2::scale_color_manual(values = all_colors) +
    ggplot2::scale_linetype_manual(values = all_linetypes) +
    ggplot2::labs(title = .acl_title("compare_growth", model1_name, model2_name),
                  subtitle = sub_txt,
                  x = .acl_lab("x", "age"), y = .acl_lab("y", "growth")) +
    .acl_base_theme() + ggplot2::theme(legend.position = cfg$legend_pos)

  pla1 <- reshape2::melt(model1$report$pla); pla1$Model <- model1_name
  pla2 <- reshape2::melt(model2$report$pla); pla2$Model <- model2_name
  pla_df <- rbind(pla1, pla2)
  colnames(pla_df) <- c("Length", "Age", "Probability", "Model")

  p_pla <- ggplot2::ggplot(pla_df, ggplot2::aes(x = Age, y = Length, fill = Probability)) +
    ggplot2::geom_tile() + .acl_fill_continuous() +
    ggplot2::facet_wrap(~Model) +
    ggplot2::labs(title = "Length-at-Age Probability (pla)", x = "Age Group", y = "Length Bin") +
    .acl_base_theme() + ggplot2::theme(strip.text = ggplot2::element_text(face = "bold"))

  if (requireNamespace("patchwork", quietly = TRUE)) {
    p <- patchwork::wrap_plots(p_vb, p_pla, ncol = 2)
  } else { p <- p_pla }
  return(p)
}


# ==========================================================================
# plot_compare_CatL: Observed vs predicted
# ==========================================================================

#' Compare Observed vs Predicted Catch-at-Length
#'
#' @inheritParams plot_compare_ts
#' @param data.CatL Catch-at-length data frame.
#' @param years Numeric vector of years to show. Default NULL = all years.
#'   Use e.g. \code{years = seq(1991, 2011, by = 2)} to select specific years.
#' @param ncol Integer. Facet columns. Default 4.
#' @param scales Character. Facet scales. Default "free_y".
#' @param obs_color Character. Color for observed points. Default "grey40".
#' @param obs_size Numeric. Size of observed points. Default 1.5.
#' @param obs_alpha Numeric. Transparency of observed points. Default 0.6.
#' @param obs_shape Integer. Shape of observed points. Default 16.
#' @param legend_pos Character. Legend position. NULL = use global theme.
#' @return A ggplot object.
#' @export
#'
#' @examples
#' \dontrun{
#' # All years (default)
#' plot_compare_CatL(result_acl, result_alscl, data.CatL)
#'
#' # Select specific years
#' plot_compare_CatL(result_acl, result_alscl, data.CatL,
#'   years = c(1991, 1995, 2000, 2005, 2011))
#'
#' # Customize layout
#' plot_compare_CatL(result_acl, result_alscl, data.CatL,
#'   ncol = 5, obs_color = "black", obs_size = 2)
#' }
plot_compare_CatL <- function(model1, model2, data.CatL, years = NULL,
                              model1_name = NULL, model2_name = NULL,
                              colors = NULL, linetypes = NULL, linewidth = NULL,
                              ncol = 4, scales = "free_y",
                              obs_color = "grey40", obs_size = 1.5,
                              obs_alpha = 0.6, obs_shape = 16,
                              legend_pos = NULL) {

  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]
  cfg <- .acl_compare_defaults(colors = colors, linetypes = linetypes,
                               linewidth = linewidth, legend_pos = legend_pos,
                               m1 = model1_name, m2 = model2_name)

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

  df_list <- list()
  for (y in years) {
    yi <- which(year == y); if (length(yi) == 0) next
    df_list[[length(df_list) + 1]] <- data.frame(Length = len_mid, Value = observed[, yi], Source = "Observed", Year = y)
    df_list[[length(df_list) + 1]] <- data.frame(Length = len_mid, Value = pred1[, yi], Source = model1_name, Year = y)
    df_list[[length(df_list) + 1]] <- data.frame(Length = len_mid, Value = pred2[, yi], Source = model2_name, Year = y)
  }
  df <- do.call(rbind, df_list); df$year_fct <- factor(df$Year)
  color_vals <- c("Observed" = obs_color, cfg$colors)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = Length, y = Value, color = Source)) +
    ggplot2::geom_point(data = df[df$Source == "Observed", ],
                        size = obs_size, alpha = obs_alpha, shape = obs_shape) +
    ggplot2::geom_line(data = df[df$Source != "Observed", ], linewidth = cfg$linewidth) +
    ggplot2::scale_color_manual(values = color_vals) +
    ggplot2::facet_wrap(~year_fct, ncol = ncol, scales = scales) +
    ggplot2::labs(title = .acl_title("compare_CatL", model1_name, model2_name),
                  x = .acl_lab("x", "length"), y = .acl_lab("y", "catch"), color = "") +
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
#' @param data.CatL Catch-at-length data frame.
#' @param metrics Character vector selecting which panels to show. Options:
#'   \code{"error"} (RMSE, MAE), \code{"R2"}, \code{"MAPE"},
#'   \code{"IC"} (AIC, BIC, NLL), \code{"npar"}.
#'   Default NULL = all five panels. E.g. \code{metrics = c("error", "R2", "IC")}.
#' @param ncol Integer. Columns for panel layout. Default: auto.
#' @param legend_pos Character. Legend position. NULL = use global theme.
#' @param label_size Numeric. Text label size on bars. Default 3.2.
#' @param bar_width Numeric. Bar width. Default 0.6.
#' @param bar_alpha Numeric. Bar transparency. Default 0.85.
#' @return A ggplot object.
#' @export
#'
#' @examples
#' \dontrun{
#' # All panels (default)
#' plot_compare_metrics(result_acl, result_alscl, data.CatL)
#'
#' # Only error and information criteria
#' plot_compare_metrics(result_acl, result_alscl, data.CatL,
#'   metrics = c("error", "IC"))
#'
#' # Just R2 and MAPE
#' plot_compare_metrics(result_acl, result_alscl, data.CatL,
#'   metrics = c("R2", "MAPE"))
#' }
plot_compare_metrics <- function(model1, model2, data.CatL,
                                 model1_name = NULL, model2_name = NULL,
                                 colors = NULL, metrics = NULL,
                                 ncol = NULL, legend_pos = NULL,
                                 label_size = 3.2, bar_width = 0.6,
                                 bar_alpha = 0.85) {

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
                         vjust = -0.3, size = label_size) +
      ggplot2::scale_fill_manual(values = cfg$colors) +
      ggplot2::labs(title = title, x = "", y = "") +
      base_layers + ggplot2::theme(legend.position = "none")
  }

  # Define available panels
  all_panels <- list(
    error = list(metrics = c("RMSE", "MAE"),                        title = "Error Metrics"),
    R2    = list(metrics = "R2",                                     title = "R-squared"),
    MAPE  = list(metrics = "MAPE",                                   title = "MAPE (%)"),
    IC    = list(metrics = c("AIC", "BIC", "Neg. Log-Likelihood"),   title = "Information Criteria"),
    npar  = list(metrics = "N. Parameters",                          title = "Parameters")
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
    nc <- if (!is.null(ncol)) ncol else min(n, 3)
    p <- patchwork::wrap_plots(panels, ncol = nc) +
      patchwork::plot_annotation(
        title = .acl_title("compare_metrics", model1_name, model2_name),
        theme = ggplot2::theme(legend.position = cfg$legend_pos)) +
      patchwork::plot_layout(guides = "collect")
    # Add legend to last panel for collection
    panels[[length(panels)]] <- panels[[length(panels)]] +
      ggplot2::theme(legend.position = "bottom") +
      ggplot2::guides(fill = ggplot2::guide_legend(title = NULL))
    p <- patchwork::wrap_plots(panels, ncol = nc) +
      patchwork::plot_annotation(
        title = .acl_title("compare_metrics", model1_name, model2_name),
        theme = ggplot2::theme(legend.position = cfg$legend_pos)) +
      patchwork::plot_layout(guides = "collect")
  } else { p <- panels[[1]] }
  return(p)
}


# ==========================================================================
# plot_compare_selectivity
# ==========================================================================

#' Compare supplied survey catchability at length
#'
#' Connects the supplied catchability values directly, preserving their range.
#' The values are fixed model inputs, not estimated fishery selectivity.
#' @inheritParams plot_compare_ts
#' @return A ggplot object.
#' @export
plot_compare_selectivity <- function(model1, model2,
                                     model1_name = NULL, model2_name = NULL,
                                     colors = NULL, linetypes = NULL, linewidth = NULL) {

  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]
  cfg <- .acl_compare_defaults(colors = colors, linetypes = linetypes,
                               linewidth = linewidth, m1 = model1_name, m2 = model2_name)

  q1 <- exp(model1$obj$env$data$log_q); q2 <- exp(model2$obj$env$data$log_q)
  df <- rbind(data.frame(Length = model1$len_mid, Selectivity = q1, Model = model1_name),
              data.frame(Length = model2$len_mid, Selectivity = q2, Model = model2_name))

  p <- ggplot2::ggplot(df, ggplot2::aes(x = Length, y = Selectivity, color = Model, linetype = Model)) +
    ggplot2::geom_line(linewidth = cfg$linewidth) +
    ggplot2::geom_point(size = cfg$point_size) +
    ggplot2::scale_color_manual(values = cfg$colors) +
    ggplot2::scale_linetype_manual(values = cfg$linetypes) +
    ggplot2::labs(title = .acl_title("compare_sel", model1_name, model2_name),
                  x = .acl_lab("x", "length"), y = "Survey catchability (q)") +
    .acl_base_theme() + ggplot2::theme(legend.position = cfg$legend_pos)
  return(p)
}


# ==========================================================================
# plot_compare_annual_F
# ==========================================================================

#' Compare Fishing Mortality by Time Step
#'
#' @inheritParams plot_compare_ts
#' @param method Character. How to summarize F across age/length groups each model
#'   time step. Quarterly fits remain quarterly; no annual aggregation is performed.
#'   \code{"apical"} (default): maximum F across groups -- comparable across
#'   age-based and length-based models.
#'   \code{"mean"}: arithmetic mean across all groups -- can be misleading when
#'   models differ in dimension (e.g. 20 ages vs 22 length bins with many near-zero).
#' @return A ggplot object.
#' @export
plot_compare_annual_F <- function(model1, model2,
                                  model1_name = NULL, model2_name = NULL,
                                  method = c("apical", "mean"),
                                  colors = NULL, linetypes = NULL, linewidth = NULL) {

  method <- match.arg(method)
  model_names <- .acl_plot_compare_names(model1, model2, model1_name, model2_name)
  model1_name <- model_names[1L]; model2_name <- model_names[2L]
  cfg <- .acl_compare_defaults(colors = colors, linetypes = linetypes,
                               linewidth = linewidth, m1 = model1_name, m2 = model2_name)

  get_F <- function(m, mname) {
    Fmat <- if (!is.null(m$report$FL)) m$report$FL else m$report$F
    if (!is.matrix(Fmat) || !is.numeric(Fmat) || !nrow(Fmat) || !ncol(Fmat))
      stop(mname, " must contain a numeric F or FL matrix.", call. = FALSE)
    years <- .acl_plot_year(m, ncol(Fmat), mname)
    values <- if (method == "apical") apply(Fmat, 2, max) else colMeans(Fmat)
    data.frame(Year = years, MeanF = values, Model = mname)
  }
  df <- rbind(get_F(model1, model1_name), get_F(model2, model2_name))

  ylab <- if (method == "apical") "Apical F (max across groups)" else "Mean F"
  p <- ggplot2::ggplot(df, ggplot2::aes(x = Year, y = MeanF, color = Model, linetype = Model)) +
    ggplot2::geom_line(linewidth = cfg$linewidth) +
    ggplot2::geom_point(size = cfg$point_size) +
    ggplot2::scale_color_manual(values = cfg$colors) +
    ggplot2::scale_linetype_manual(values = cfg$linetypes) +
    ggplot2::labs(title = .acl_title("compare_annualF", model1_name, model2_name),
                  x = .acl_lab("x", "year"), y = ylab) +
    .acl_base_theme() + .acl_scale_x() +
    ggplot2::theme(legend.position = cfg$legend_pos)
  return(p)
}
