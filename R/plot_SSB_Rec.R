#' @title Plot the Relationship between Spawning Stock Biomass (SSB) and Recruitment (Rec)
#'
#' @description This function takes the model result as an input and creates a scatter plot to visualize the relationship between
#' Spawning Stock Biomass (SSB) and Recruitment (Rec). These metrics are fundamental in the context of fishery stock assessment.
#'
#' @param model_result A list containing the model results. It includes a component "report" that comprises "SSB" and "Rec".
#' @param age_at_recruitment Numeric. Recruitment age in years, used to pair SSB
#'   with later recruitment. Must be nonnegative and an exact multiple of the
#'   model's \code{growth_step}. Default is 1 year (four periods for quarterly
#'   fits). A value of 0 pairs SSB and recruitment in the same period. For older
#'   fits without \code{growth_step}, the time step is inferred from \code{year},
#'   or defaults to 1 year when no time metadata are available.
#' @param point_color Character or NULL. NULL inherits the global point_color setting.
#' @param point_size Numeric. The size of the points in the scatter plot. Default is 2.
#' @param point_shape Numeric. The shape of the points in the scatter plot, as an integer value (see ?points in base R for more info). Default is 16 (filled circle).
#' @param return_data A logical indicating whether to return the processed data alongside the plot. Default is FALSE.
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
#' @return A ggplot object representing the scatter plot of SSB versus Recruitment.
#'
#' @examples
#' \dontrun{
#' # The model_result is typically obtained from run_acl().
#' # Here, we create a dummy example.
#' # Use 'run_acl' to get 'model_result'
#' model_result <- run_acl(...)
#'
#' # Call the function
#' p <- plot_SSB_Rec(model_result)
#'
#' # Print the plot
#' print(p)
#' }
#' @export
plot_SSB_Rec <- function(model_result, age_at_recruitment = 1,
                         point_size=2,point_color = NULL,point_shape=16, return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL, title_hjust = NULL) {
  # NULL 继承全局色板 / NULL inherits the global palette.
  if (is.null(point_color)) point_color <- acl_theme("point_color")



  # Extract the necessary data
  SSB_data <- model_result[["report"]][["SSB"]]
  Rec_data <- model_result[["report"]][["Rec"]]

  if (!is.numeric(age_at_recruitment) || length(age_at_recruitment) != 1L ||
      !is.finite(age_at_recruitment) || age_at_recruitment < 0)
    stop("age_at_recruitment must be one finite, nonnegative number of years.", call. = FALSE)
  if (!is.numeric(SSB_data) || !is.numeric(Rec_data) || !length(SSB_data) ||
      length(SSB_data) != length(Rec_data))
    stop("SSB and recruitment must be numeric vectors of equal, nonzero length.", call. = FALSE)
  years <- model_result$year
  if (!is.null(years) && (!is.numeric(years) || length(years) != length(SSB_data) ||
                        any(!is.finite(years)) || any(diff(years) <= 0)))
    stop("Time metadata must contain one increasing, finite year per model period.", call. = FALSE)
  growth_step <- model_result$growth_step
  if (is.null(growth_step))
    growth_step <- if (length(years) > 1L) diff(years)[1L] else 1
  if (!is.numeric(growth_step) || length(growth_step) != 1L ||
      !is.finite(growth_step) || growth_step <= 0)
    stop("growth_step must be one finite, positive number of years.", call. = FALSE)
  if (length(years) > 1L && any(abs(diff(years) - growth_step) > 1e-8 * max(1, growth_step)))
    stop("Time column spacing must equal growth_step to align SSB and recruitment.", call. = FALSE)
  lag <- age_at_recruitment / growth_step
  if (!is.finite(lag) || abs(lag - round(lag)) > 1e-8 * max(1, abs(lag)))
    stop("age_at_recruitment must be an exact multiple of growth_step.", call. = FALSE)
  lag <- round(lag)
  if (lag >= length(SSB_data))
    stop("age_at_recruitment is too large compared to the time span of the data.", call. = FALSE)

  # Align calendar ages with model periods before indexing the two time series.
  source_periods <- seq_len(length(SSB_data) - lag)
  SSB_adjusted <- SSB_data[source_periods]
  Rec_adjusted <- Rec_data[source_periods + lag]

  # Create a data frame for ggplot
  plot_data <- data.frame(SSB = SSB_adjusted, Rec = Rec_adjusted)

  # Create the plot
  p <-  ggplot2::ggplot(plot_data, aes(x = SSB, y = Rec)) +
    ggplot2::geom_point(size= point_size, color= point_color,shape=point_shape) +
    ggplot2:: labs(x = if (!is.null(xlab)) xlab else .acl_lab("x", "ssb"), y = if (!is.null(ylab)) ylab else .acl_lab("y", "rec"), title = if (!is.null(title)) title else .acl_title("SSB_Rec"))+
    .acl_scale_x(x_breaks, n_breaks = 8) +
      .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size, strip_text_size, legend_text_size, base_theme = base_theme, title_hjust = title_hjust)

  data_out <-plot_data

  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}




