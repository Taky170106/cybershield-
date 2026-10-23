user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
.libPaths(c(user_lib, .libPaths()))

retry <- c("fontLiberation", "textshaping", "websocket", "fontquiver",
           "ragg", "gdtools", "systemfonts")
to_install <- retry[!sapply(retry, function(p) requireNamespace(p, quietly=TRUE))]
if (length(to_install) > 0) {
  message("Retrying: ", paste(to_install, collapse=", "))
  install.packages(to_install, repos="https://cloud.r-project.org",
                   Ncpus=1, timeout = 300)
}
ok <- sapply(retry, function(p) requireNamespace(p, quietly=TRUE))
print(ok)
