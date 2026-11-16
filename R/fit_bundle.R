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
    # Only the tables, fit_args and fit_config of a structured bundle are
    # fitting settings. A top-level entry named like a fitting argument is
    # most likely a setting in the wrong place. The top-level parameters entry
    # is exempt: example bundles keep their simulation settings there.
    every_argument <- union(names(formals(run_acl)), names(formals(run_alscl)))
    misplaced <- setdiff(intersect(names(x), every_argument), c(tables, "parameters"))
    if (length(misplaced))
      warning("x contains fit_args or fit_config, so these top-level entries are not used in fitting: ",
              paste(misplaced, collapse = ", "), ". Move them into x$fit_args or x$fit_config$",
              model, ".", call. = FALSE)
    if ("fit_args" %in% names(x)) {
      shared <- validate(x[["fit_args"]], "x$fit_args")
      # fit_args is shared by both models. The deprecated ALSCL-only bin
      # bounds must not make the bundle unusable for ACL.
      bounds <- intersect(names(shared), c("len_lower", "len_upper"))
      if (model == "acl" && length(bounds)) {
        .acl_deprecated_bin_bounds("run_acl")
        shared <- shared[setdiff(names(shared), bounds)]
      }
      args <- overlay(args, validate(shared, "x$fit_args", allowed))
    }
    if ("fit_config" %in% names(x)) {
      configs <- validate(x[["fit_config"]], "x$fit_config", c("acl", "alscl"))
      # A configuration for the other model only: this model uses fit_args.
      if (model %in% names(configs))
        args <- overlay(args, validate(configs[[model]],
                                      paste0("x$fit_config$", model), allowed))
    }
    stored_names <- names(args)
  } else {
    args <- validate(x, "x", allowed)
    stored_names <- names(args)
  }
  args <- overlay(args, validate(overrides, "Overrides", allowed))
  # Where t0_lower and the parameters list (with log_t0) come from: "call"
  # for the arguments of the call, "stored" for the bundle or a saved recipe.
  # A list resolved earlier keeps its sources (see .acl_t0_sources()).
  sources <- attr(x, "acl_t0_sources")
  if (!is.list(sources)) sources <- list()
  for (nm in c("t0_lower", "parameters"))
    if (nm %in% names(overrides)) sources[[nm]] <- "call" else
      if (is.null(sources[[nm]]) && nm %in% stored_names) sources[[nm]] <- "stored"
  attr(args, "acl_t0_sources") <- sources
  required <- allowed[vapply(formals(fun), function(v) identical(v, quote(expr = )), logical(1))]
  absent <- required[!required %in% names(args)]
  if (length(absent))
    stop("Missing required bundle arguments: ", paste(absent, collapse = ", "), call. = FALSE)
  if (!is.data.frame(args$data.CatL) && !is.matrix(args$data.CatL))
    stop("x$data.CatL must be a data frame or matrix.", call. = FALSE)
  args
}

# The stored parameters list of a bundle and the expression that names it in
# messages: fit_config$<model>, then fit_args, then a flat list of arguments.
# The top-level parameters entry of a structured bundle holds simulation
# settings and is not a fitting setting. NULL when nothing is stored.
.acl_stored_parameters <- function(x, model) {
  if (!is.list(x) || is.data.frame(x)) return(NULL)
  if (any(c("fit_args", "fit_config") %in% names(x))) {
    config <- if (is.list(x$fit_config)) x$fit_config[[model]]
    if (is.list(config) && "parameters" %in% names(config))
      return(list(parameters = config$parameters, label = paste0("x$fit_config$", model, "$parameters")))
    if (is.list(x$fit_args) && "parameters" %in% names(x$fit_args))
      return(list(parameters = x$fit_args$parameters, label = "x$fit_args$parameters"))
    return(NULL)
  }
  if ("parameters" %in% names(x)) list(parameters = x$parameters, label = "x$parameters")
}

# Stored parameter values that a parameters argument of the call drops: a
# list in the call replaces the stored list, so a stored entry that the call
# does not repeat takes its default start, and a map entry that fixes it
# (a factor with only NA values) fixes it at that default. `map` is the map
# of the resolved fit, which may come from the call. Returns list(dropped,
# fixed), or NULL when the call has no parameters argument, nothing is stored
# or nothing is dropped.
.acl_replaced_parameters <- function(stored, overrides, map) {
  if (!is.list(overrides) || !"parameters" %in% names(overrides) || !is.list(stored) || !length(stored))
    return(NULL)
  new <- overrides[["parameters"]]
  dropped <- setdiff(names(stored), if (is.list(new)) names(new))
  dropped <- dropped[!is.na(dropped) & nzchar(dropped)]
  if (!length(dropped)) return(NULL)
  fixed <- if (is.list(map) && !is.data.frame(map))
    dropped[vapply(dropped, function(nm) {
      entry <- map[[nm]]
      is.factor(entry) && length(entry) > 0L && all(is.na(entry))
    }, logical(1))] else character()
  list(dropped = dropped, fixed = fixed)
}

.acl_fit_bundle <- function(x, model, call, frame) {
  explicit <- setdiff(names(as.list(call)[-1L]), "data.CatL")
  overrides <- mget(explicit, envir = frame, inherits = FALSE)
  args <- .acl_bundle_args(x, model, overrides)
  stored <- .acl_stored_parameters(x, model)
  .acl_replaced_parameters_note(.acl_replaced_parameters(stored$parameters, overrides, args$map),
                                isTRUE(args$silent), stored$label)
  .acl_with_t0_sources(args, do.call(if (model == "acl") run_acl else run_alscl, args, quote = TRUE))
}

# TRUE when t0_lower and the parameters list of resolved arguments come from
# different places: one from the call and the other from the bundle or a
# saved recipe. Only then is a supplied log_t0 named under t0_lower (see
# .acl_t0_lower_start()): when both are stored or both are typed in one call,
# they were chosen together.
.acl_t0_sources <- function(args) {
  sources <- attr(args, "acl_t0_sources")
  is.list(sources) && all(c("t0_lower", "parameters") %in% names(sources)) &&
    !identical(sources[["t0_lower"]], sources[["parameters"]])
}

# Resolved arguments without the internal source attribute, for lists that
# are returned to the user or saved (scenario and fold settings, recipes).
# `x` is one argument list or a list of them.
.acl_drop_t0_sources <- function(x, nested = FALSE) {
  if (nested) return(lapply(x, .acl_drop_t0_sources))
  attr(x, "acl_t0_sources") <- NULL
  x
}

# Evaluate a fit of resolved arguments with the source flag of t0_lower and
# log_t0 set, so that .acl_fit() can read it, and restore the previous flag.
.acl_with_t0_sources <- function(args, expr) {
  previous <- .acl_notes$t0_sources_differ
  .acl_notes$t0_sources_differ <- .acl_t0_sources(args)
  on.exit(.acl_notes$t0_sources_differ <- previous, add = TRUE)
  expr
}
