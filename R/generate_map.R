#' Generate a custom map or use default values for the stock assessment model
#'
#' This function generates a map for the stock assessment model with either custom or default values.
#' Users can provide custom values for specific map elements, and the function will use the default values for the others.
#'
#' @param map A list containing the custom values for the map elements (default is NULL).
#'   - log_std_log_F: Custom value for log_std_log_F (default is NA).
#'   - logit_log_F_y: Custom value for logit_log_F_y (default is NA).
#'   - logit_log_F_a: Custom value for logit_log_F_a (default is NA).
#'   - t0: Custom value for t0 (default is NA).
#'   Growth parameters log_vbk and log_Linf are free unless explicitly mapped.
#'
#' @details This helper uses ACL defaults and drops named NULL entries from its
#'   result. When releasing default fixes through run_acl(), pass the named NULL
#'   list directly as map rather than wrapping it in generate_map(): the fitter
#'   would otherwise reapply defaults for the removed entries.
#'
#' @return A list representing the generated map with custom or default values.
#' @examples
#' # ACL parameters that are fixed by default
#' names(generate_map())
#'
#' # Also fix the von Bertalanffy growth coefficient at its starting value
#' map <- generate_map(list(log_vbk = factor(NA)))
#' names(map)
#' @export
generate_map <- function(map = NULL) {
  allowed <- c(names(create_parameters(model_type = "acl")$parameters),
               "dev_log_R", "dev_log_F", "dev_log_N0")
  .acl_merge_map(map, "ACL", allowed)
}

.acl_merge_map <- function(map, model, allowed) {
  default_map <- if (model == "ACL") {
    list(log_std_log_F = factor(NA), logit_log_F_y = factor(NA),
         logit_log_F_a = factor(NA), t0 = factor(NA))
  } else {
    list(log_sigma_log_F = factor(NA), log_t0 = factor(NA))
  }
  if (!is.null(map)) {
    if (!is.list(map) || is.data.frame(map) || (length(map) &&
        (is.null(names(map)) || anyNA(names(map)) || any(!nzchar(names(map))) ||
         anyDuplicated(names(map)))))
      stop("map must be a named list with unique, non-empty parameter names.", call. = FALSE)
    # A named NULL releases a default fix. Check its spelling before removal.
    unknown <- setdiff(names(map), allowed)
    if (length(unknown))
      stop("Unknown map parameter: ", paste(unknown, collapse = ", "), call. = FALSE)
    default_map[names(map)] <- map
  }
  default_map[!vapply(default_map, is.null, logical(1))]
}

# TMB allocates a coordinate for every level, including unused levels. Work
# with integer codes so a genuine fixed entry stays missing even when a free
# group has an NA label (which base droplevels() can merge with that entry).
.acl_drop_map_levels <- function(value) {
  codes <- as.integer(value)
  used <- which(tabulate(codes, nbins = nlevels(value)) > 0L)
  if (length(used) == nlevels(value)) return(value)
  names(codes) <- names(value)
  factor(codes, levels = used, labels = levels(value)[used], ordered = is.ordered(value))
}
