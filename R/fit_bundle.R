# Resolve a data bundle without changing the legacy positional interfaces.
.acl_bundle_args <- function(x, model, overrides = list()) {
  fun <- if (model == "acl") run_acl else run_alscl
  allowed <- names(formals(fun))
  validate <- function(value, label, permitted = NULL) {
    if (!is.list(value) || is.data.frame(value) ||
        (length(value) && (is.null(names(value)) || anyNA(names(value)) ||
         any(!nzchar(names(value))) || anyDuplicated(names(value)))))
      stop(label, " must be a list with unique, non-empty names.", call. = FALSE)
    unknown <- setdiff(names(value), permitted)
    if (!is.null(permitted) && length(unknown))
      stop(label, " contains unknown arguments: ", paste(unknown, collapse = ", "),
           call. = FALSE)
    value
  }
  # Single-bracket assignment preserves explicit NULL overrides.
  overlay <- function(base, extra) {
    base[names(extra)] <- extra
    base
  }
  validate(x, "x")
  if (any(c("fit_args", "fit_config") %in% names(x))) {
    tables <- c("data.CatL", "data.wgt", "data.mat")
    args <- x[intersect(tables, names(x))]
    if ("fit_args" %in% names(x))
      args <- overlay(args, validate(x[["fit_args"]], "x$fit_args", allowed))
    if ("fit_config" %in% names(x)) {
      configs <- validate(x[["fit_config"]], "x$fit_config", c("acl", "alscl"))
      if (!model %in% names(configs))
        stop("x$fit_config must contain a '", model, "' configuration.", call. = FALSE)
      args <- overlay(args, validate(configs[[model]],
                                    paste0("x$fit_config$", model), allowed))
    }
  } else {
    args <- validate(x, "x", allowed)
  }
  args <- overlay(args, validate(overrides, "Overrides", allowed))
  required <- allowed[vapply(formals(fun), function(v) identical(v, quote(expr = )), logical(1))]
  absent <- required[!required %in% names(args)]
  if (length(absent))
    stop("Missing required bundle arguments: ", paste(absent, collapse = ", "), call. = FALSE)
  if (!is.data.frame(args$data.CatL) && !is.matrix(args$data.CatL))
    stop("x$data.CatL must be a data frame or matrix.", call. = FALSE)
  args
}

.acl_fit_bundle <- function(x, model, call, frame) {
  explicit <- setdiff(names(as.list(call)[-1L]), "data.CatL")
  args <- .acl_bundle_args(x, model, mget(explicit, envir = frame, inherits = FALSE))
  do.call(if (model == "acl") run_acl else run_alscl, args, quote = TRUE)
}
