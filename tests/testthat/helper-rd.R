# Read help belonging to the loaded package, not an older installation in
# another library. pkgload loads a source tree with man/*.Rd; R CMD check
# loads an installed package with a help database instead.
test_rd_database <- function(package = "ALSCL",
                             package_path = getNamespaceInfo(package, "path")) {
  man <- file.path(package_path, "man")
  if (dir.exists(man)) {
    files <- list.files(man, pattern = "\\.Rd$", full.names = TRUE)
    return(stats::setNames(lapply(files, tools::parse_Rd), basename(files)))
  }
  tools::Rd_db(package, lib.loc = dirname(package_path))
}
