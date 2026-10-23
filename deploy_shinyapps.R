user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
.libPaths(c(user_lib, .libPaths()))

library(rsconnect)

cat("=== Deploying CyberShield to shinyapps.io ===\n\n")

# Check if account is set
accounts <- tryCatch(rsconnect::accounts(), error = function(e) NULL)
if (is.null(accounts) || nrow(accounts) == 0) {
  cat("ERROR: No shinyapps.io account configured.\n\n")
  cat("First run setup_deploy.R to get instructions.\n")
  cat("Then set your credentials:\n")
  cat('  rsconnect::setAccountInfo(name="...", token="...", secret="...")\n')
  quit(status = 1)
}

cat("Account found:", accounts$name[1], "\n")
cat("Deploying app...\n\n")

rsconnect::deployApp(
  appDir = "D:/new_ajay/CyberShield",
  appName = "cybershield",
  appTitle = "CyberShield - Cybersecurity Vulnerability Dashboard",
  launch.browser = TRUE,
  forceUpdate = TRUE
)

cat("\n=== Deployment complete ===\n")
