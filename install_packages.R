pkgs <- c("shiny","bslib","dplyr","readr","janitor","lubridate",
          "ggplot2","plotly","DT","httr2","jsonlite","purrr",
          "stringr","scales","zoo","htmltools","bsicons")

# Use a user-writable library path
user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(user_lib)
message("Using library: ", user_lib)

to_install <- pkgs[!sapply(pkgs, function(p) 
  requireNamespace(p, quietly=TRUE) || requireNamespace(p, lib.loc=user_lib, quietly=TRUE))]

if (length(to_install) > 0) {
  message("Installing: ", paste(to_install, collapse=", "))
  install.packages(to_install, lib=user_lib, repos="https://cloud.r-project.org", Ncpus=4)
} else {
  message("All packages already installed.")
}

# Verify
ok <- sapply(pkgs, function(p) {
  tryCatch(requireNamespace(p, quietly=TRUE), error=function(e) FALSE)
})
print(ok)
