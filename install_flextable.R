user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
.libPaths(c(user_lib, .libPaths()))

if (!requireNamespace("flextable", quietly = TRUE)) {
  install.packages("flextable", repos = "https://cloud.r-project.org", timeout = 300)
}
cat("flextable ready\n")
