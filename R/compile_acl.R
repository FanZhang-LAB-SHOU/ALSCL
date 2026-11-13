# Platform of this R build. A cache folder shared between machines or between
# two builds of R on one machine (for example arm64 and x86_64 R on one Mac)
# must not reuse a library compiled for another platform.
.acl_build_platform <- function()
  c(R.version$platform, R.version$arch, unname(Sys.info()[["machine"]]), .Platform$dynlib.ext)

# C++ settings that reach TMB::compile(): the compiler entries of R's Makeconf
# and the contents of the site and user Makevars files. TMB sets CXXFLAGS
# itself, but the compiler (CXX), CPPFLAGS and the linker settings come from
# these files.
.acl_build_toolchain <- function(makeconf = file.path(R.home("etc"), .Platform$r_arch, "Makeconf"),
                                 makevars = c(tools::makevars_site(), tools::makevars_user())) {
  read <- function(path) tryCatch(readLines(path, warn = FALSE), error = function(e) character())
  conf <- read(makeconf)
  conf <- conf[grepl("^(CXX|CPPFLAGS|LDFLAGS|SHLIB_CXX|SHLIB_OPENMP_CXX)", conf)]
  makevars <- makevars[file.exists(makevars)]
  c(conf, unlist(lapply(makevars, read), use.names = FALSE))
}

# Name of the cache entry of a model template. It changes with the template
# sources, the R and package versions, the automatic-differentiation library,
# the platform and the C++ settings, so each combination has its own folder.
.acl_compile_key <- function(src, header, framework, platform = .acl_build_platform(),
                             toolchain = .acl_build_toolchain()) {
  key_file <- tempfile(); on.exit(unlink(key_file), add = TRUE)
  writeLines(c(unname(tools::md5sum(c(src, header))), R.version.string,
               as.character(utils::packageVersion("TMB")),
               as.character(utils::packageVersion("RcppEigen")), framework,
               platform, toolchain), key_file)
  substr(unname(tools::md5sum(key_file)), 1L, 12L)
}

# Move a finished build folder to its cache folder with one rename. R processes
# that share the cache (for example the tasks of a job array) then see either
# no library or a complete one, never a library that is still being written.
# Returns TRUE when this build was installed and FALSE when another process
# had already installed the same entry.
.acl_install_build <- function(build, cache, lib) {
  if (file.exists(lib)) return(invisible(FALSE))
  # A cache folder without a library was left by an interrupted build.
  if (dir.exists(cache)) unlink(cache, recursive = TRUE)
  if (suppressWarnings(file.rename(build, cache))) return(invisible(TRUE))
  # The rename fails when another process installed the entry in the meantime.
  if (file.exists(lib)) return(invisible(FALSE))
  stop("Could not move the compiled model to ", cache,
       ". Check that the folder set by options(ALSCL.tmb.cache = ) is writable.", call. = FALSE)
}

# Compile a model template in a temporary folder next to its cache folder.
.acl_build <- function(src, header, root, dll, framework) {
  cache <- file.path(root, dll)
  build <- tempfile(paste0(".build-", dll, "-"), tmpdir = root)
  if (!dir.create(build))
    stop("Could not create a build folder in ", root,
         ". Check that the folder set by options(ALSCL.tmb.cache = ) is writable.", call. = FALSE)
  on.exit(unlink(build, recursive = TRUE), add = TRUE)
  cpp <- paste0(dll, ".cpp")
  file.copy(src, file.path(build, cpp), overwrite = TRUE)
  file.copy(header, file.path(build, "model_math.hpp"), overwrite = TRUE)
  # Let make see a plain filename, avoiding Windows backslashes and spaces in paths.
  # Leave the build folder before it is removed or renamed.
  previous_dir <- setwd(build); on.exit(setwd(previous_dir), add = TRUE, after = FALSE)
  TMB::compile(cpp, flags = "-O2", openmp = FALSE, framework = framework)
  setwd(previous_dir)
  if (!file.exists(TMB::dynlib(file.path(build, dll))))
    stop("Compiling the model template ", cpp, " produced no library.", call. = FALSE)
  .acl_install_build(build, cache, TMB::dynlib(file.path(cache, dll)))
}

# Compile (once per cache entry) and load a model template. The default cache
# is a folder of this R session; options(ALSCL.tmb.cache = ) sets a persistent
# one. Returns the paths of the template and the library and the DLL name.
.acl_compile <- function(model, framework = .acl_framework()) {
  # Binary TMB installations do not necessarily install their LinkingTo headers.
  if (!requireNamespace("RcppEigen", quietly = TRUE)) stop("Install RcppEigen to compile model templates.")
  src <- system.file("extdata", paste0(model, ".cpp"), package = "ALSCL")
  header <- system.file("extdata", "model_math.hpp", package = "ALSCL")
  if (!nzchar(src) || !nzchar(header)) stop("Model sources are missing; reinstall the ALSCL package.")
  dll <- paste0(model, "_", .acl_compile_key(src, header, framework))
  root <- getOption("ALSCL.tmb.cache", file.path(tempdir(), "ALSCL-tmb"))
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  cache <- file.path(root, dll)
  cpp <- file.path(cache, paste0(dll, ".cpp")); lib <- TMB::dynlib(file.path(cache, dll))
  # Another process may install the entry while this one compiles; .acl_build()
  # checks again before it installs its own build.
  if (!file.exists(lib)) .acl_build(src, header, root, dll, framework)
  loaded <- vapply(getLoadedDLLs(), function(x) x[["path"]], character(1))
  loaded <- loaded[file.exists(loaded)] # R's built-in "base" entry is not a file.
  if (!normalizePath(lib, winslash = "/") %in% normalizePath(loaded, winslash = "/"))
    tryCatch(dyn.load(lib), error = function(e)
      stop("Could not load the compiled model ", lib, ": ", conditionMessage(e),
           " Delete the folder ", cache, " and fit again to compile it afresh.", call. = FALSE))
  invisible(list(cpp_path = cpp, dll_path = lib, dll_name = dll))
}
