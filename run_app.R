user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
if (dir.exists(user_lib)) .libPaths(c(user_lib, .libPaths()))
setwd("D:/new_ajay/CyberShield")
shiny::runApp(".", port = 8888, host = "0.0.0.0", launch.browser = FALSE)
