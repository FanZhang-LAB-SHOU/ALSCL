# Configure workers without serializing an ALSCL namespace in the initializer.
# Otherwise deserialization may load an older default installation before the
# worker has applied the caller's library paths.
.acl_initialize_workers <- function(cl, cache = NULL, dll_path = NULL,
                                    settings = list(),
                                    tmb_version = as.character(utils::packageVersion("TMB"))) {
  package_path <- normalizePath(getNamespaceInfo(asNamespace("ALSCL"), "path"),
                                winslash = "/", mustWork = TRUE)
  source_mode <- !file.exists(file.path(package_path, "Meta", "package.rds"))
  initialize <- function(paths, package_path, source_mode, cache, dll_path, settings, tmb_version) {
    # An installed ALSCL is found in the library that holds it. The parent
    # folder of a source checkout is not a library: a sibling folder named
    # after a dependency would shadow the installed package.
    .libPaths(c(if (!source_mode) dirname(package_path), paths))
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
    # The compiled model and the standard-error code depend on the TMB version.
    worker_tmb <- as.character(utils::packageVersion("TMB"))
    if (!identical(worker_tmb, tmb_version))
      stop("Socket worker loaded TMB ", worker_tmb, " but the main process uses TMB ",
           tmb_version, ". Put the library that holds TMB ", tmb_version,
           " first on .libPaths().", call. = FALSE)
    if (!is.null(dll_path)) dyn.load(dll_path)
    invisible(NULL)
  }
  # Installations with R_KEEP_PKG_SOURCE retain source-file environments that
  # also refer to the package namespace. Strip those before serialization.
  initialize <- utils::removeSource(initialize)
  environment(initialize) <- baseenv()
  parallel::clusterCall(cl, initialize, .acl_dependency_paths("TMB"), package_path,
                        source_mode, cache, dll_path, settings, tmb_version)
  invisible(NULL)
}
