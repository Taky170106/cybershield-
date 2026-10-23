user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
.libPaths(c(user_lib, .libPaths()))

# Install rsconnect if needed
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect", repos = "https://cloud.r-project.org")
}

library(rsconnect)

cat("=== shinyapps.io Deployment Setup ===\n\n")
cat("To deploy, you need a shinyapps.io account.\n")
cat("1. Sign up free at: https://www.shinyapps.io\n")
cat("2. Go to: Account > Tokens > Show\n")
cat("3. Copy the token and secret\n\n")

cat("Then run these commands in R:\n\n")
cat('rsconnect::setAccountInfo(\n')
cat('  name = "YOUR_ACCOUNT_NAME",\n')
cat('  token = "YOUR_TOKEN",\n')
cat('  secret = "YOUR_SECRET"\n')
cat(')\n\n')

cat('rsconnect::deployApp(\n')
cat('  appDir = "D:/new_ajay/CyberShield",\n')
cat('  appName = "cybershield",\n')
cat('  appTitle = "CyberShield - Cybersecurity Dashboard",\n')
cat('  launch.browser = TRUE\n')
cat(')\n\n')

cat("Or use this automated script after setting credentials:\n")
cat("  Rscript deploy_shinyapps.R\n")
