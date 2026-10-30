# Configure workers without serializing an ALSCL namespace in the initializer.
# Otherwise deserialization may load an older default installation before the
# worker has applied the caller's library paths.
.acl_initialize_workers <- function(cl, cache = NULL, dll_path = NULL,
                                    settings = list()) {
  package_path <- normalizePath(getNamespaceInfo(asNamespace("ALSCL"), "path"),
                                winslash = "/", mustWork = TRUE)
  source_mode <- !file.exists(file.path(package_path, "Meta", "package.rds"))
  initialize <- function(paths, package_path, source_mode, cache, dll_path, settings) {
    .libPaths(c(dirname(package_path), paths))
    if (!is.null(cache)) options(ALSCL.tmb.cache = cache)
    options(settings)
    if (source_mode) {
      if (!requireNamespace("pkgload", quietly = TRUE))
        stop("Install pkgload to run socket workers from a source checkout, or install ALSCL first.",
             call. = FALSE)
      pkgload::load_all(package_path, quiet = TRUE, export_all = FALSE,
                        helpers = FALSE)
    } else loadNamespace("ALSCL", lib.loc = dirname(package_path))
    loaded <- normalizePath(getNamespaceInfo(asNamespace("ALSCL"), "path"),
                            winslash = "/", mustWork = TRUE)
    if (!identical(loaded, package_path))
      stop("Socket worker loaded a different ALSCL installation: ", loaded,
           "; expected ", package_path, call. = FALSE)
    if (!is.null(dll_path)) dyn.load(dll_path)
    invisible(NULL)
  }
  # Installations with R_KEEP_PKG_SOURCE retain source-file environments that
  # also refer to the package namespace. Strip those before serialization.
  initialize <- utils::removeSource(initialize)
  environment(initialize) <- baseenv()
  parallel::clusterCall(cl, initialize, .libPaths(), package_path,
                        source_mode, cache, dll_path, settings)
  invisible(NULL)
}
