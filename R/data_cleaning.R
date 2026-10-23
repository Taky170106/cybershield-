# CyberShield Data Cleaning Module
# Transforms raw KEV data into analysis-ready format

library(dplyr)
library(lubridate)
library(stringr)

#' Clean and standardize the KEV dataset
#' @param raw_df Raw data from load_kev_raw()
#' @return Cleaned tibble ready for analysis
clean_kev_data <- function(raw_df) {
  df <- raw_df
  
  # Standardize column names (already clean from janitor in loader, but ensure consistency)
  df <- df |> janitor::clean_names()
  
  # Ensure date columns are proper Date type
  df <- df |>
    mutate(
      date_added = as.Date(date_added),
      due_date = as.Date(due_date)
    )
  
  # Normalize ransomware designation
  df <- df |>
    mutate(
      known_ransomware_campaign_use = case_when(
        str_to_lower(known_ransomware_campaign_use) %in% c("yes", "true", "1", "known") ~ "Yes",
        str_to_lower(known_ransomware_campaign_use) %in% c("no", "false", "0") ~ "No",
        TRUE ~ "Unknown"
      ),
      known_ransomware_campaign_use = factor(
        known_ransomware_campaign_use, 
        levels = c("Yes", "No", "Unknown")
      )
    )
  
  # Normalize forensic triage
  df <- df |>
    mutate(
      forensic_triage = case_when(
        str_to_lower(forensic_triage) %in% c("yes", "true", "1") ~ "Yes",
        str_to_lower(forensic_triage) %in% c("no", "false", "0") ~ "No",
        TRUE ~ "Unknown"
      ),
      forensic_triage = factor(forensic_triage, levels = c("Yes", "No", "Unknown"))
    )
  
  # Clean vendor and product names (trim whitespace)
  df <- df |>
    mutate(
      vendor_project = str_trim(vendor_project),
      product = str_trim(product),
      vulnerability_name = str_trim(vulnerability_name)
    )
  
  # Add derived columns for analysis
  df <- df |>
    mutate(
      # Year and month of catalog addition
      added_year = year(date_added),
      added_month = month(date_added, label = TRUE, abbr = TRUE),
      added_ym = floor_date(date_added, "month"),
      
      # Due date status categories
      due_status = case_when(
        is.na(due_date) ~ "Unknown",
        due_date < Sys.Date() ~ "Overdue",
        due_date == Sys.Date() ~ "Due Today",
        due_date > Sys.Date() ~ "Upcoming",
        TRUE ~ "Unknown"
      ),
      due_status = factor(due_status, levels = c("Overdue", "Due Today", "Upcoming", "Unknown")),
      
      # Days overdue (negative = days until due)
      days_to_due = as.numeric(due_date - Sys.Date()),
      
      # CVE year for grouping
      cve_year = as.numeric(str_extract(cve_id, "^CVE-(\\d{4})", group = 1))
    )
  
  # Parse CWEs into list column for potential future use
  df <- df |>
    mutate(
      cwe_list = str_split(cwes, ",\\s*"),
      primary_cwe = purrr::map_chr(cwe_list, ~ .x[1])
    )
  
  df
}

#' Create monthly summary for trend analysis
#' @param clean_df Cleaned KEV data
#' @return Monthly aggregation tibble
create_monthly_summary <- function(clean_df) {
  clean_df |>
    filter(!is.na(date_added)) |>
    count(added_ym, name = "vuln_count") |>
    arrange(added_ym) |>
    complete(added_ym = seq.Date(min(added_ym), max(added_ym), by = "month"),
             fill = list(vuln_count = 0)) |>
    mutate(
      year_month = format(added_ym, "%Y-%m"),
      year = year(added_ym),
      month = month(added_ym, label = TRUE, abbr = TRUE)
    )
}

#' Create vendor summary for vendor intelligence
#' @param clean_df Cleaned KEV data
#' @param top_n Number of top vendors to return
#' @return Vendor aggregation tibble
create_vendor_summary <- function(clean_df, top_n = 20) {
  clean_df |>
    count(vendor_project, name = "vuln_count") |>
    arrange(desc(vuln_count)) |>
    slice_head(n = top_n) |>
    mutate(
      vendor_rank = row_number(),
      pct_of_total = round(vuln_count / sum(vuln_count) * 100, 2)
    )
}

#' Create vendor-product breakdown
#' @param clean_df Cleaned KEV data
#' @param vendor_filter Optional vendor name to filter
#' @return Product aggregation tibble
create_vendor_product_summary <- function(clean_df, vendor_filter = NULL) {
  df <- clean_df
  if (!is.null(vendor_filter) && vendor_filter != "All") {
    df <- df |> filter(vendor_project == vendor_filter)
  }
  
  df |>
    count(vendor_project, product, name = "vuln_count") |>
    arrange(desc(vuln_count))
}

#' Create remediation summary
#' @param clean_df Cleaned KEV data
#' @return Remediation status summary tibble
create_remediation_summary <- function(clean_df) {
  clean_df |>
    count(due_status, name = "count") |>
    mutate(
      pct = round(count / sum(count) * 100, 1),
      due_status = factor(due_status, levels = c("Overdue", "Due Today", "Upcoming", "Unknown"))
    ) |>
    arrange(due_status)
}

#' Create ransomware designation summary
#' @param clean_df Cleaned KEV data
#' @return Ransomware summary tibble
create_ransomware_summary <- function(clean_df) {
  clean_df |>
    count(known_ransomware_campaign_use, name = "count") |>
    mutate(pct = round(count / sum(count) * 100, 1))
}

#' Create yearly summary for YoY comparison
#' @param clean_df Cleaned KEV data
#' @return Yearly aggregation tibble
create_yearly_summary <- function(clean_df) {
  clean_df |>
    filter(!is.na(date_added)) |>
    count(added_year, name = "vuln_count") |>
    arrange(added_year) |>
    mutate(
      cumsum = cumsum(vuln_count),
      pct_change = round((vuln_count - lag(vuln_count)) / lag(vuln_count) * 100, 1)
    )
}

#' Filter data based on user selections
#' @param clean_df Cleaned KEV data
#' @param date_range Date range filter (length 2 vector)
#' @param vendor_filter Vendor filter (character vector or "All")
#' @param ransomware_filter Ransomware filter (character vector or "All")
#' @return Filtered tibble
filter_kev_data <- function(clean_df, 
                            date_range = NULL, 
                            vendor_filter = "All", 
                            ransomware_filter = "All") {
  df <- clean_df
  
  # Date range filter
  if (!is.null(date_range) && length(date_range) == 2) {
    df <- df |> filter(date_added >= date_range[1] & date_added <= date_range[2])
  }
  
  # Vendor filter
  if (!is.null(vendor_filter) && vendor_filter != "All" && length(vendor_filter) > 0) {
    df <- df |> filter(vendor_project %in% vendor_filter)
  }
  
  # Ransomware filter
  if (!is.null(ransomware_filter) && ransomware_filter != "All" && length(ransomware_filter) > 0) {
    df <- df |> filter(known_ransomware_campaign_use %in% ransomware_filter)
  }
  
  df
}

#' Calculate KPIs for overview page
#' @param filtered_df Filtered KEV data
#' @return Named list of KPI values
calculate_kpis <- function(filtered_df) {
  total_vulns <- nrow(filtered_df)
  distinct_vendors <- n_distinct(filtered_df$vendor_project)
  ransomware_count <- sum(filtered_df$known_ransomware_campaign_use == "Yes", na.rm = TRUE)
  overdue_count <- sum(filtered_df$due_status == "Overdue", na.rm = TRUE)
  
  list(
    total_vulnerabilities = total_vulns,
    distinct_vendors = distinct_vendors,
    ransomware_campaign_use = ransomware_count,
    overdue_remediations = overdue_count
  )
}