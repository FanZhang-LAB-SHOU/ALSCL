#' @title Plot log residuals of the survey index from an ACL or ALSCL fit
#'
#' @description Plot observed log survey index minus fitted Elog_index.
#' The facet_by argument selects the layout of these same residuals:
#' 1) "length" plots residuals over time, with one facet per length group;
#' 2) "year" plots residuals over length, with one facet per model time step.
#' Missing and zero observations
#' are excluded using the fit's stored observations, including saved fits without
#' a live TMB object. Saved fits use the observation mask in the TMB data.
#'
#' @param model_result An ACL or ALSCL fitted result with report$resid_index,
#'   stored observations and time/length metadata.
#' @param f Numeric. The smoother span for the loess smooth line in the plot. This gives the proportion of points in the plot which
#' influence the smooth at each value. Larger values result in more smoothing. Default is 0.4.
#' Each facet is handled independently: fewer than two distinct observed x values
#' omit its trend, two to five use a linear trend, and six or more use loess.
#' The loess span is enlarged per facet when needed for at least five neighbors.
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param smooth_color Character or NULL. NULL inherits the global smooth_color setting.
#' @param hline_color Character or NULL. NULL inherits the global hline_color setting.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting (default 1.5).
#' @param facet_ncol Numeric, optional. Number of columns in facet wrap.  Default is NULL.
#' @param facet_scales Character. The "scales" argument for the facet_wrap function in ggplot2. Default is "free".
#' @param facet_by Character. "length" (default) draws one panel per length bin
#'   with time on the x axis; "year" draws one panel per time step with length
#'   on the x axis. This changes the layout, not the residual definition.
#' @param resid_cap Finite positive numeric scalar or NULL. Symmetrically cap
#'   residuals at +/- this value; NULL disables capping.
#'   Useful for species with many length bins where tail bins (e.g. >120 for tuna)
#'   have very few observations, producing extreme log-residuals that distort the
#'   plot. Default is NULL (no capping). A value of 1 is a reasonable starting point.
#' @param return_data A logical indicating whether to return the processed data alongside the plot. Default is FALSE.
#' @param ... The former argument name type, accepted with a warning.
#'
#' @param title Character or NULL. Custom plot title. If NULL, uses global theme setting. See \code{acl_theme_set()}.
#' @param xlab Character or NULL. Custom x-axis label. If NULL, uses global theme setting.
#' @param ylab Character or NULL. Custom y-axis label. If NULL, uses global theme setting.
#' @param font_family Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans").
#' @param title_size Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14).
#' @param axis_title_size Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12).
#' @param axis_text_size Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10).
#' @param strip_text_size Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10).
#' @param legend_text_size Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10).
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks (e.g. \code{seq(1, 20, by = 2)}). NULL = auto.
#' @param base_theme Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting.
#' @param title_hjust Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting.
#' @return A ggplot object representing the facet plot of residuals.
#'
#' @examples
#' \dontrun{
#' # Use 'run_acl' to get 'model_result'
#' model_result <- run_acl(...)
#'
#' # One panel per length bin
#' p_length <- plot_residuals(model_result, facet_by = "length")
#'
#' # Print the plot for "length"
#' print(p_length)
#'
#' # One panel per time step
#' p_year <- plot_residuals(model_result, facet_by = "year")
#'
#' # Print the plot for "year"
#' print(p_year)
#' }
#' @export
plot_residuals <- function(model_result, f = 0.4, line_color = NULL, smooth_color = NULL, hline_color = NULL, line_size = NULL, facet_scales = "free", facet_ncol = NULL, facet_by = c("length", "year"), resid_cap = NULL, return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL, title_hjust = NULL, ...) {
  renamed <- .acl_renamed(list(...), "plot_residuals")
  if (missing(facet_by) && !is.null(renamed$facet_by)) facet_by <- renamed$facet_by
  facet_by <- match.arg(facet_by)
  # NULL inherits the global palette.
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(smooth_color)) smooth_color <- acl_theme("smooth_color")
  if (is.null(hline_color)) hline_color <- acl_theme("hline_color")


  if (!is.null(resid_cap)) .acl_scalar(resid_cap, "resid_cap", 0, TRUE)
  if (length(f) != 1L || !is.finite(f) || f <= 0 || f > 1) stop("f must be in (0, 1].")
  smoother <- function(data, x, group) {
    valid <- is.finite(data[[x]]) & is.finite(data$residual)
    counts <- vapply(split(data[[x]][valid], data[[group]][valid], drop = TRUE),
                     function(z) length(unique(z)), integer(1))
    # Facets with the same support can share a layer, but a sparse facet must
    # not remove trends or change the method/span in better-supported facets.
    lapply(sort(unique(counts[counts >= 2L])), function(n) {
      selected <- names(counts)[counts == n]
      trend_data <- data[valid & as.character(data[[group]]) %in% selected, , drop = FALSE]
      short <- n < 6L
      ggplot2::geom_smooth(data = trend_data,
        method = if (short) "lm" else "loess", formula = y ~ x,
        method.args = if (short) list() else list(degree = 1),
        span = max(f, 5 / n), se = FALSE, na.rm = TRUE,
        color = smooth_color, linetype = 2, linewidth = line_size)
    })
  }
  observed_log <- .acl_observed_log(model_result)
  residuals <- model_result$report$resid_index
  if (!is.numeric(residuals) || !identical(dim(residuals), dim(observed_log)))
    stop("Residual and observation matrix dimensions differ.", call. = FALSE)
  model_result$report$resid_index[!is.finite(observed_log)] <- NA_real_
  len_label=model_result[["len_label"]]

  if (facet_by == "length") {

    fixed_len_labels <- .acl_fix_len_labels(len_label)
    num_indices <- dim(model_result[["report"]][["resid_index"]])[1]
    plot_data <- data.frame()
    for(i in seq_len(num_indices)){
      temp_data <- as.data.frame(model_result[["report"]][["resid_index"]][i,])

      temp_data$LengthGroup <- fixed_len_labels[i]

      temp_data$year <- model_result[["year"]]
      plot_data <- rbind(plot_data, temp_data)
    }
    colnames(plot_data) <- c("residual", "LengthGroup","year")

    # Cap extreme residuals (common in tail bins with few observations)
    if (!is.null(resid_cap)) {
      n_capped <- sum(abs(plot_data$residual) > resid_cap, na.rm = TRUE)
      if (n_capped > 0) {
        message(sprintf("plot_residuals: %d residual(s) capped at +/-%.1f (tail bins with few observations)",
                        n_capped, resid_cap))
      }
      plot_data$residual <- pmax(pmin(plot_data$residual, resid_cap), -resid_cap)
    }

    plot_data$LengthGroup <- factor(plot_data$LengthGroup,
                                    levels = fixed_len_labels)
    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x=year, y=residual)) +
      ggplot2::geom_line(color = line_color, linewidth = line_size) +
      smoother(plot_data, "year", "LengthGroup") +
      ggplot2::geom_hline(yintercept=0, color=hline_color, linewidth=line_size) +
      ggplot2::facet_wrap(~LengthGroup, scales = facet_scales, ncol = facet_ncol)+
      .acl_scale_x(x_breaks, n_breaks = 8) +
      .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size, strip_text_size, legend_text_size, base_theme = base_theme, title_hjust = title_hjust)+
      ggplot2::labs(x = if (is.null(xlab)) .acl_lab("x", "year") else xlab,
        y = if (is.null(ylab)) .acl_lab("y", "residual") else ylab,
        title = if (is.null(title)) .acl_title("resid_length") else title)

    data_out <-plot_data

  }
  if (facet_by == "year")
  {
    # Define the data
    resid_index <- model_result[["report"]][["resid_index"]]
    year <- model_result[["year"]]
    len_mid <- model_result[["len_mid"]]
    # Transform the matrix into a data frame and add column names
    df <- as.data.frame(resid_index)
    colnames(df) <- year
    df$len_mid <- len_mid
    # Reshape the data from wide to long format
    df_long <- df %>%
      tidyr::pivot_longer(-len_mid, names_to = "year", values_to = "residuals")
    colnames(df_long) <- c("length", "Year","residual")

    # Cap extreme residuals (common in tail bins with few observations)
    if (!is.null(resid_cap)) {
      n_capped <- sum(abs(df_long$residual) > resid_cap, na.rm = TRUE)
      if (n_capped > 0) {
        message(sprintf("plot_residuals: %d residual(s) capped at +/-%.1f (tail bins with few observations)",
                        n_capped, resid_cap))
      }
      df_long$residual <- pmax(pmin(df_long$residual, resid_cap), -resid_cap)
    }

    year_levels <- .acl_time_labels(year)
    df_long$Year <- factor(year_levels[match(as.numeric(df_long$Year), year)], levels = year_levels)
    p <- ggplot2::ggplot(df_long, ggplot2::aes(x=length, y=residual)) +
      ggplot2::geom_line(color = line_color, linewidth = line_size) +
      smoother(df_long, "length", "Year") +
      ggplot2::geom_hline(yintercept=0, color=hline_color, linewidth=line_size) +
      ggplot2::facet_wrap(~Year, scales = facet_scales,ncol = facet_ncol)+
      .acl_scale_x(x_breaks, n_breaks = 8) +
      .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size, strip_text_size, legend_text_size, base_theme = base_theme, title_hjust = title_hjust)+
      ggplot2::labs(x = if (is.null(xlab)) .acl_lab("x", "length") else xlab,
        y = if (is.null(ylab)) .acl_lab("y", "residual") else ylab,
        title = if (is.null(title)) .acl_title("resid_year") else title)

    data_out <-df_long

  }
  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}
