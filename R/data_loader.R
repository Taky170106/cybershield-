# CyberShield Data Loader Module
# Handles loading and initial validation of the CISA KEV dataset

library(readr)
library(janitor)
library(dplyr)
library(lubridate)

#' Load the KEV dataset from local CSV
#' @param file_path Path to the CSV file
#' @return Tibble with raw data
load_kev_raw <- function(file_path = "data/known_exploited_vulnerabilities.csv") {
  if (!file.exists(file_path)) {
    stop("Data file not found: ", file_path, 
         "\nRun scripts/download_data.R to fetch the latest catalog.")
  }
  
  read_csv(file_path, 
           show_col_types = FALSE,
           col_types = cols(
             cveID = col_character(),
             vendorProject = col_character(),
             product = col_character(),
             vulnerabilityName = col_character(),
             dateAdded = col_date(format = "%Y-%m-%d"),
             shortDescription = col_character(),
             requiredAction = col_character(),
             dueDate = col_date(format = "%Y-%m-%d"),
             knownRansomwareCampaignUse = col_character(),
             forensicTriage = col_character(),
             notes = col_character(),
             cwes = col_character()
           ))
}

#' Validate required columns exist
#' @param df Raw data frame
#' @return Validated data frame (throws error if invalid)
validate_kev_columns <- function(df) {
  required_cols <- c("cveID", "vendorProject", "product", "vulnerabilityName", 
                     "dateAdded", "shortDescription", "requiredAction", 
                     "dueDate", "knownRansomwareCampaignUse")
  
  missing <- setdiff(required_cols, names(df))
  if (length(missing) > 0) {
    stop("Missing required columns: ", paste(missing, collapse = ", "))
  }
  
  if (nrow(df) == 0) {
    warning("Dataset has zero rows")
  }
  
  df
}

#' Check for duplicate CVE IDs
#' @param df Data frame
#' @return List with duplicate info and deduplicated data
check_duplicates <- function(df) {
  dup_cves <- df |>
    count(cveID) |>
    filter(n > 1) |>
    pull(cveID)
  
  if (length(dup_cves) > 0) {
    warning("Found ", length(dup_cves), " duplicate CVE IDs: ", 
            paste(head(dup_cves, 10), collapse = ", "),
            if (length(dup_cves) > 10) " ..." else "")
  }
  
  # Keep first occurrence of each CVE
  df_dedup <- df |> distinct(cveID, .keep_all = TRUE)
  
  list(
    duplicates_found = length(dup_cves),
    duplicate_cves = dup_cves,
    data = df_dedup
  )
}

#' Check missing values in key columns
#' @param df Data frame
#' @return Summary of missing values
check_missing_values <- function(df) {
  key_cols <- c("cveID", "vendorProject", "product", "vulnerabilityName",
                "dateAdded", "dueDate", "knownRansomwareCampaignUse")
  
  missing_summary <- df |>
    select(all_of(intersect(key_cols, names(df)))) |>
    summarise(across(everything(), ~ sum(is.na(.)))) |>
    tidyr::pivot_longer(everything(), names_to = "column", values_to = "missing_count") |>
    mutate(missing_pct = round(missing_count / nrow(df) * 100, 2))
  
  missing_summary
}

#' Validate date ordering and ranges
#' @param df Data frame
#' @return List with validation results
validate_dates <- function(df) {
  today <- Sys.Date()
  
  issues <- list()
  
  # Check dateAdded is not in future (with small buffer for timezone)
  future_added <- df |> filter(dateAdded > today + 1)
  if (nrow(future_added) > 0) {
    issues$future_dateAdded <- nrow(future_added)
  }
  
  # Check dueDate is not before dateAdded
  bad_order <- df |> filter(!is.na(dueDate) & !is.na(dateAdded) & dueDate < dateAdded)
  if (nrow(bad_order) > 0) {
    issues$dueDate_before_dateAdded <- nrow(bad_order)
  }
  
  # Check for very old dates (before 1999 when CVE started)
  ancient <- df |> filter(dateAdded < as.Date("1999-01-01"))
  if (nrow(ancient) > 0) {
    issues$ancient_dates <- nrow(ancient)
  }
  
  issues
}

#' Validate categorical values
#' @param df Data frame
#' @return List with validation results
validate_categoricals <- function(df) {
  issues <- list()
  
  # knownRansomwareCampaignUse should be Yes/No/Unknown
  valid_ransomware <- c("Yes", "No", "Unknown")
  invalid_ransomware <- df |>
    filter(!knownRansomwareCampaignUse %in% valid_ransomware) |>
    pull(knownRansomwareCampaignUse) |>
    unique()
  
  if (length(invalid_ransomware) > 0) {
    issues$invalid_ransomware_values <- invalid_ransomware
  }
  
  # forensicTriage should be Yes/No
  valid_forensic <- c("Yes", "No")
  invalid_forensic <- df |>
    filter(!forensicTriage %in% valid_forensic) |>
    pull(forensicTriage) |>
    unique()
  
  if (length(invalid_forensic) > 0) {
    issues$invalid_forensic_values <- invalid_forensic
  }
  
  issues
}

#' Load and validate the complete KEV dataset
#' @param file_path Path to CSV file
#' @return List with cleaned data and validation report
load_kev_validated <- function(file_path = "data/known_exploited_vulnerabilities.csv") {
  message("Loading KEV dataset from: ", file_path)
  
  raw_data <- load_kev_raw(file_path)
  raw_data <- validate_kev_columns(raw_data)
  
  # Check duplicates
  dup_result <- check_duplicates(raw_data)
  data <- dup_result$data
  
  # Check missing values
  missing_summary <- check_missing_values(data)
  
  # Validate dates
  date_issues <- validate_dates(data)
  
  # Validate categoricals
  categorical_issues <- validate_categoricals(data)
  
  validation_report <- list(
    row_count = nrow(data),
    column_count = ncol(data),
    duplicates = dup_result,
    missing_values = missing_summary,
    date_issues = date_issues,
    categorical_issues = categorical_issues,
    load_timestamp = Sys.time()
  )
  
  message("Loaded ", nrow(data), " vulnerabilities after deduplication")
  
  list(
    data = data,
    validation = validation_report
  )
}

#' Load metadata about the dataset
load_dataset_metadata <- function() {
  meta_file <- "data/data_metadata.json"
  if (file.exists(meta_file)) {
    jsonlite::read_json(meta_file)
  } else {
    list(
      source_url = "https://www.cisa.gov/sites/default/files/csv/known_exploited_vulnerabilities.csv",
      retrieval_date = "unknown",
      status = "no_metadata_file"
    )
  }
}