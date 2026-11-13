# Validate the output actually supplied by a fit instead of assuming every
# model reports every population quantity and its standard error.
.acl_plot_population_data <- function(model_result, type, choices, se) {
  .acl_check_flag(se, "se")
  value <- model_result$report[[type]]
  if (is.null(value)) {
    available <- choices[vapply(choices, function(nm)
      !is.null(model_result$report[[nm]]), logical(1))]
    stop("Quantity '", type, "' is not available in this model output.",
         if (length(available)) paste0(" Available types: ",
           paste(available, collapse = ", "), ".") else " No supported quantity is available.",
         call. = FALSE)
  }
  years <- model_result$year
  if (!is.numeric(years) || !length(years) || any(!is.finite(years)) ||
      any(diff(years) <= 0))
    stop("model_result$year must contain finite increasing time labels.", call. = FALSE)
  if (is.data.frame(value)) value <- as.matrix(value)
  if (!is.numeric(value) || !length(value) || any(!is.finite(value)))
    stop("Quantity '", type, "' must contain finite numeric estimates.", call. = FALSE)
  if (type %in% c("B", "SSB", "CN", "N", "Rec")) {
    if (length(value) != length(years))
      stop("Quantity '", type, "' must have one estimate per time step.", call. = FALSE)
    value <- as.numeric(value)
  } else {
    if (!is.matrix(value) || ncol(value) != length(years))
      stop("Quantity '", type, "' must be a group-by-time matrix matching model_result$year.",
           call. = FALSE)
    if (type %in% c("BL", "SBL", "CNL", "NL")) {
      labels <- model_result$len_label
      if (length(labels) != nrow(value) || anyNA(labels) ||
          any(!nzchar(as.character(labels))) || anyDuplicated(labels))
        stop("model_result$len_label must identify every length group uniquely.", call. = FALSE)
    }
    # Matrix dimnames are optional display metadata, not row/column indices.
    # The model's year and length labels provide the coordinates.
    dimnames(value) <- NULL
  }
  standard_errors <- if (se) .acl_plot_estimates(model_result, type, length(value)) else NULL
  list(value = value, se = standard_errors)
}

# Exact quantity names and matrix-preserving selection prevent partial matches,
# silent recycling and dropped dimensions in single-period stored results.
.acl_plot_estimates <- function(model_result, type, n, require_se = TRUE) {
  estimates <- model_result$est_std
  missing_values <- function() stop(
    if (require_se) "Standard errors" else "Estimates", " for '", type,
    "' are unavailable or incomplete in this model output.",
    if (require_se) " Use se = FALSE to draw estimates only.", call. = FALSE)
  columns <- if (require_se) c("Estimate", "Std. Error") else "Estimate"
  if (length(dim(estimates)) != 2L || is.null(rownames(estimates)) ||
      anyNA(rownames(estimates)) || !all(columns %in% colnames(estimates))) missing_values()
  selected <- estimates[rownames(estimates) == type, columns, drop = FALSE]
  if (nrow(selected) != n) missing_values()
  selected <- as.matrix(selected)
  if (!is.numeric(selected) || any(!is.finite(selected)) ||
      (require_se && any(selected[, "Std. Error"] < 0)))
    stop(if (require_se) "Standard errors" else "Estimates", " for '", type,
      if (require_se) "' must be finite and nonnegative. Inspect fit diagnostics or use se = FALSE."
      else "' must be finite numeric values.", call. = FALSE)
  selected
}

# Lines and ribbons have no visible extent for a single observation. Apply this
# only to the estimate layers assembled by our plot functions, keeping their
# data, facet coordinates and styles intact. Multi-point groups are unchanged.
.acl_show_singletons <- function(plot, groups = character(),
                                  point_size = acl_theme("point_size")) {
  singleton_rows <- function(data) {
    if (!length(groups)) return(rep(nrow(data) == 1L, nrow(data)))
    group <- interaction(data[groups], drop = TRUE, lex.order = TRUE)
    tabulate(group)[as.integer(group)] == 1L
  }
  points <- list()
  for (i in seq_along(plot$layers)) {
    layer <- plot$layers[[i]]
    line <- inherits(layer$geom, "GeomLine")
    ribbon <- inherits(layer$geom, "GeomRibbon")
    if (!line && !ribbon) next
    data <- if (inherits(layer$data, "waiver")) plot$data else layer$data
    if (!is.data.frame(data) || !nrow(data)) next
    single <- singleton_rows(data)
    if (!any(single)) next
    # Clone the layer rather than modifying a potentially shared ggproto object.
    # ggproto resolves its parent lazily; bind the actual object, not the loop
    # variable, so earlier clones cannot inherit a subsequent ribbon layer.
    plot$layers[[i]] <- do.call(ggplot2::ggproto,
      list(NULL, layer, data = data[!single, , drop = FALSE]))
    mapping <- layer$mapping
    style <- layer$aes_params
    args <- list(data = data[single, , drop = FALSE], mapping = mapping,
      inherit.aes = layer$inherit.aes, show.legend = FALSE)
    if (line) {
      args$show.legend <- layer$show.legend
      args <- c(args, style[intersect(c("colour", "alpha"), names(style))],
        list(size = point_size))
      points[[length(points) + 1L]] <- do.call(ggplot2::geom_point, args)
    } else {
      # A mapped fill in a comparison ribbon becomes the interval's colour.
      if (!is.null(mapping$fill)) {
        if (is.null(mapping$colour)) mapping$colour <- mapping$fill
        mapping$fill <- NULL
      }
      args$mapping <- mapping
      colour <- style$colour %||% style$fill
      if (!is.null(colour)) args$colour <- colour
      # The ribbon's transparency suits a filled area, not a thin line: the
      # replacement bar is drawn opaque.
      args <- c(args, style[intersect("linewidth", names(style))], list(width = .3))
      plot <- plot + do.call(ggplot2::geom_errorbar, args)
    }
  }
  # Keep estimate points above their uncertainty intervals.
  plot + points
}

# Long table of a matrix in column-major order with integer row and column
# positions, as reshape2::melt() returned for a matrix without dimnames.
.acl_matrix_long <- function(x, names = c("Var1", "Var2", "value")) {
  x <- as.matrix(x)
  out <- data.frame(rep(seq_len(nrow(x)), times = ncol(x)),
                    rep(seq_len(ncol(x)), each = nrow(x)), as.vector(x))
  names(out) <- names
  out
}

# Interval type requested in a plot call, or the global setting when NULL.
.acl_interval_type <- function(interval = NULL) {
  if (is.null(interval)) interval <- acl_theme("interval") %||% "lognormal"
  if (!is.character(interval) || length(interval) != 1L || is.na(interval) ||
      !interval %in% c("lognormal", "wald"))
    stop("interval must be \"lognormal\" or \"wald\".", call. = FALSE)
  interval
}

# 95% interval from an estimate and its standard error on the reported scale.
# "wald" is estimate +/- 1.96 SE and can fall below zero. "lognormal" treats
# the log of a positive estimate as normal with standard error SE / estimate
# (delta method), which gives exp(log(estimate) +/- 1.96 SE / estimate) and
# stays positive. An estimate that is not positive, or whose lognormal upper
# bound overflows, keeps the Wald bounds. Estimates are never changed.
.acl_interval <- function(estimate, se, interval = "lognormal", z = 1.96) {
  estimate <- as.numeric(estimate); se <- as.numeric(se)
  lower <- estimate - z * se
  upper <- estimate + z * se
  if (identical(interval, "lognormal")) {
    positive <- which(is.finite(estimate) & estimate > 0 & is.finite(se))
    width <- z * se[positive] / estimate[positive]
    log_upper <- exp(log(estimate[positive]) + width)
    usable <- is.finite(log_upper)
    positive <- positive[usable]; width <- width[usable]
    lower[positive] <- exp(log(estimate[positive]) - width)
    upper[positive] <- log_upper[usable]
    # Where the lognormal bounds are not available (an estimate of exactly
    # zero, or an upper bound that overflows), the Wald bounds are kept but
    # the lower bound of a nonnegative estimate stops at zero. Negative
    # estimates keep the Wald bounds.
    nonnegative <- which(is.finite(estimate) & estimate >= 0 & is.finite(lower))
    lower[nonnegative] <- pmax(lower[nonnegative], 0)
  }
  list(lower = lower, upper = upper)
}
