user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
.libPaths(c(user_lib, .libPaths()))

pkgs <- c("officer", "webshot2", "rvg")
to_install <- pkgs[!sapply(pkgs, function(p) requireNamespace(p, quietly=TRUE))]
if (length(to_install) > 0) {
  message("Installing: ", paste(to_install, collapse=", "))
  install.packages(to_install, repos="https://cloud.r-project.org", Ncpus=4)
}
message("Packages ready")
