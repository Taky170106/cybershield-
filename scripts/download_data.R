# CyberShield Data Download Script
# Downloads the CISA Known Exploited Vulnerabilities (KEV) catalog
# Run this script to refresh the local data snapshot

library(httr2)
library(readr)
library(lubridate)

# Configuration
CISA_KEV_URL <- "https://www.cisa.gov/sites/default/files/csv/known_exploited_vulnerabilities.csv"
DATA_DIR <- "data"
DATA_FILE <- file.path(DATA_DIR, "known_exploited_vulnerabilities.csv")
METADATA_FILE <- file.path(DATA_DIR, "data_metadata.json")

# Ensure data directory exists
if (!dir.exists(DATA_DIR)) {
  dir.create(DATA_DIR, recursive = TRUE)
}

#' Download the CISA KEV catalog
#' @return List with status, data, and metadata
download_kev_catalog <- function(url = CISA_KEV_URL, dest_file = DATA_FILE) {
  message("Downloading CISA KEV catalog from: ", url)
  
  tryCatch({
    req <- request(url) |>
      req_user_agent("CyberShield/1.0 (Academic Research)") |>
      req_timeout(60) |>
      req_retry(max_tries = 3, backoff = ~ 2 * .x)
    
    resp <- req_perform(req)
    
    if (resp_status(resp) == 200) {
      content <- resp_body_string(resp)
      writeLines(content, dest_file)
      
      # Verify the download by reading it back
      test_read <- read_csv(dest_file, show_col_types = FALSE, n_max = 5)
      
      metadata <- list(
        source_url = url,
        retrieval_date = as.character(Sys.Date()),
        retrieval_timestamp = as.character(Sys.time()),
        file_path = dest_file,
        file_size_bytes = file.size(dest_file),
        row_count = nrow(read_csv(dest_file, show_col_types = FALSE)),
        column_names = names(test_read),
        status = "success"
      )
      
      # Save metadata
      jsonlite::write_json(metadata, METADATA_FILE, pretty = TRUE, auto_unbox = TRUE)
      
      message("Download successful! Rows: ", metadata$row_count)
      message("Metadata saved to: ", METADATA_FILE)
      
      return(list(status = "success", metadata = metadata))
    } else {
      stop(sprintf("HTTP %d: %s", resp_status(resp), resp_status_desc(resp)))
    }
  }, error = function(e) {
    message("Download failed: ", e$message)
    
    # Check if we have a local copy
    if (file.exists(dest_file)) {
      message("Using existing local data file: ", dest_file)
      existing_meta <- if (file.exists(METADATA_FILE)) {
        jsonlite::read_json(METADATA_FILE)
      } else {
        list(retrieval_date = "unknown", status = "local_fallback")
      }
      return(list(status = "local_fallback", metadata = existing_meta, error = e$message))
    } else {
      return(list(status = "error", error = e$message, metadata = NULL))
    }
  })
}

#' Load metadata about the current dataset
load_metadata <- function() {
  if (file.exists(METADATA_FILE)) {
    jsonlite::read_json(METADATA_FILE)
  } else {
    list(
      source_url = CISA_KEV_URL,
      retrieval_date = "unknown",
      retrieval_timestamp = "unknown",
      status = "no_metadata"
    )
  }
}

# Main execution when run as script
if (sys.nframe() == 0) {
  result <- download_kev_catalog()
  if (result$status == "error") {
    stop("Failed to download data and no local fallback available: ", result$error)
  }
  print(result$metadata)
}