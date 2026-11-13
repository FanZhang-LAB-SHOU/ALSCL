test_that("the compile cache key separates platforms and C++ settings (F35)", {
  src <- tempfile(fileext = ".cpp"); header <- tempfile(fileext = ".hpp")
  on.exit(unlink(c(src, header)), add = TRUE)
  writeLines("// template", src); writeLines("// header", header)
  key <- ALSCL:::.acl_compile_key
  reference <- key(src, header, "CppAD", platform = "aarch64-apple-darwin23", toolchain = "CXX = clang++")
  expect_match(reference, "^[0-9a-f]{12}$")
  expect_identical(reference,
    key(src, header, "CppAD", platform = "aarch64-apple-darwin23", toolchain = "CXX = clang++"))
  expect_false(identical(reference,
    key(src, header, "CppAD", platform = "x86_64-apple-darwin20", toolchain = "CXX = clang++")))
  expect_false(identical(reference,
    key(src, header, "CppAD", platform = "aarch64-apple-darwin23", toolchain = "CXX = g++")))
  expect_false(identical(reference,
    key(src, header, "TMBad", platform = "aarch64-apple-darwin23", toolchain = "CXX = clang++")))
  platform <- ALSCL:::.acl_build_platform()
  expect_true(all(c(R.version$platform, R.version$arch, .Platform$dynlib.ext) %in% platform))
})

test_that("the cache key follows the compiler entries of Makeconf and the user Makevars (F35)", {
  makeconf <- tempfile(); makevars <- tempfile()
  on.exit(unlink(c(makeconf, makevars)), add = TRUE)
  writeLines(c("CC = clang", "CXX = clang++", "CPPFLAGS = -I/opt/include", "FC = gfortran",
               "SHLIB_CXXLD = clang++"), makeconf)
  toolchain <- ALSCL:::.acl_build_toolchain
  without <- toolchain(makeconf, makevars = character())
  expect_identical(without, c("CXX = clang++", "CPPFLAGS = -I/opt/include", "SHLIB_CXXLD = clang++"))
  expect_identical(toolchain(makeconf, makevars = makevars), without)  # the file does not exist yet
  writeLines("CPPFLAGS = -I/opt/include -DNEW_FLAG", makevars)
  expect_identical(toolchain(makeconf, makevars = makevars),
                   c(without, "CPPFLAGS = -I/opt/include -DNEW_FLAG"))
  expect_true(length(toolchain()) > 0L)
})

test_that("a finished build is installed with one rename and never replaces a library (F35)", {
  root <- tempfile("cache-"); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  install <- ALSCL:::.acl_install_build
  make_build <- function(text) {
    build <- tempfile(".build-", tmpdir = root); dir.create(build)
    writeLines(text, file.path(build, "model.so"))
    build
  }
  cache <- file.path(root, "model"); lib <- file.path(cache, "model.so")
  # A cache folder without a library, left by an interrupted build, is replaced.
  dir.create(cache); writeLines("partial", file.path(cache, "model.o"))
  first <- make_build("first")
  expect_true(install(first, cache, lib))
  expect_false(dir.exists(first))
  expect_identical(readLines(lib), "first")
  expect_false(file.exists(file.path(cache, "model.o")))
  # A second process that compiled the same entry keeps the installed library.
  second <- make_build("second")
  expect_false(install(second, cache, lib))
  expect_identical(readLines(lib), "first")
  expect_true(dir.exists(second))  # removed by .acl_build() on exit
})

test_that("compiling leaves one complete cache folder and no build folder (F35, F67)", {
  skip_on_cran()
  info <- ALSCL:::.acl_compile("ACL")
  root <- dirname(dirname(info$dll_path))
  expect_true(file.exists(info$dll_path))
  expect_true(file.exists(info$cpp_path))
  expect_identical(basename(dirname(info$dll_path)), info$dll_name)
  expect_length(list.files(root, pattern = paste0("^\\.build-", info$dll_name), all.files = TRUE), 0L)
  expect_true(info$dll_name %in% names(getLoadedDLLs()))
  # The unused OpenMP switch and its wrappers are gone.
  expect_false("openmp" %in% names(formals(ALSCL:::.acl_compile)))
  expect_false(exists("compile_and_load_acl", envir = asNamespace("ALSCL"), inherits = FALSE))
  expect_false(exists("unload_acl", envir = asNamespace("ALSCL"), inherits = FALSE))
})
