#' Plot the probability of length given age
#'
#' Display the age-length probability matrix reported by an ACL or ALSCL fit.
#' Each cell shows the probability that a fish of a given age falls within
#' a length group. Columns correspond to ages and rows to length groups.
#'
#' @param model_result An ACL or ALSCL fitted result containing report$pla
#'   and length-group metadata.
#' @param low_col Character or NULL. NULL inherits the global low_col setting.
#' @param high_col Character or NULL. NULL inherits the global high_col setting.
#'
#' @param title Character or NULL. Custom plot title. If NULL, uses global theme setting. See \code{acl_theme_set()}.
#' @param xlab Character or NULL. Custom x-axis label. If NULL, uses global theme setting.
#' @param ylab Character or NULL. Custom y-axis label. If NULL, uses the global ylab$length setting.
#' @param font_family Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans").
#' @param title_size Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14).
#' @param axis_title_size Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12).
#' @param axis_text_size Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10).
#' @param strip_text_size Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10).
#' @param legend_text_size Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10).
#' @param x_breaks Integer age-bin positions to label (between 1 and the number
#'   of age bins). This changes tick labels only, never the heatmap cells.
#'   NULL inherits global x_breaks; when both are NULL all age bins are labelled.
#' @param base_theme Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting.
#' @param title_hjust Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting.
#' @return A ggplot heatmap of the probability of length given age.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' model_result <- run_alscl(YTF_example, train_times = 2, silent = TRUE)
#'
#' # Generate a heatmap with the default color gradient
#' plot_pla(model_result)
#'
#' # Generate a heatmap with a custom color gradient from white to steelblue
#' plot_pla(model_result, "white", "steelblue")
#' }
plot_pla <- function(model_result, low_col = NULL, high_col = NULL, title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL, title_hjust = NULL) {
  # NULL inherits the global palette.
  if (is.null(low_col)) low_col <- acl_theme("low_col")
  if (is.null(high_col)) high_col <- acl_theme("high_col")


  pla=model_result[["report"]][["pla"]]
  len_label=model_result[["len_label"]]

  df <- as.data.frame(pla)

  age_labels <- paste("Age bin", seq_len(ncol(df)))
  colnames(df) <- age_labels
  breaks <- if (is.null(x_breaks)) acl_theme("x_breaks") else x_breaks
  if (!is.null(breaks) && (!is.numeric(breaks) || any(!is.finite(breaks)) ||
      any(breaks != trunc(breaks)) || any(breaks < 1 | breaks > length(age_labels)) ||
      anyDuplicated(breaks)))
    stop("x_breaks must contain unique integer age-bin positions within the PLA matrix.", call. = FALSE)
  age_breaks <- if (is.null(breaks)) age_labels else age_labels[breaks]

  len_levels <- .acl_fix_len_labels(len_label)
  df$LengthGroup <- factor(len_levels, levels = len_levels)

  dfm <- reshape2::melt(df, id.vars = "LengthGroup")
  dfm$variable <- factor(dfm$variable, levels = age_labels)

  #
  p <- ggplot2::ggplot(dfm, ggplot2::aes(x=variable, y=LengthGroup, fill=value)) +
    ggplot2::geom_tile() +
    ggplot2::scale_x_discrete(breaks = age_breaks, drop = FALSE) +
    ggplot2::scale_fill_gradient(low = low_col, high = high_col) +
    .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size, strip_text_size, legend_text_size, base_theme = base_theme, title_hjust = title_hjust) +
    ggplot2::labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", "age"), y = if (!is.null(ylab)) ylab else .acl_lab("y", "length"), fill = "Probability", title = if (!is.null(title)) title else .acl_title("pla"))

  return(p)
}
