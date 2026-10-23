# CyberShield Analysis Module
# Higher-level analytical functions for the dashboard

library(dplyr)
library(lubridate)

#' Compute summary statistics for a date range
#' @param clean_df Cleaned KEV data
#' @param start_date Start date for period
#' @param end_date End date for period
#' @return List with period statistics
compute_period_stats <- function(clean_df, start_date, end_date) {
  period_data <- clean_df |>
    filter(date_added >= start_date & date_added <= end_date)
  
  total <- nrow(period_data)
  by_month <- period_data |>
    count(added_ym, name = "count") |>
    arrange(added_ym)
  
  avg_per_month <- if (nrow(by_month) > 0) mean(by_month$count) else 0
  
  top_vendors <- period_data |>
    count(vendor_project, name = "count") |>
    arrange(desc(count)) |>
    slice_head(n = 10)
  
  ransomware_pct <- if (total > 0) {
    round(sum(period_data$known_ransomware_campaign_use == "Yes", na.rm = TRUE) / total * 100, 1)
  } else 0
  
  list(
    period_start = start_date,
    period_end = end_date,
    total_vulnerabilities = total,
    avg_per_month = round(avg_per_month, 1),
    months_with_data = nrow(by_month),
    monthly_breakdown = by_month,
    top_vendors = top_vendors,
    ransomware_percentage = ransomware_pct
  )
}

#' Year-over-year comparison
#' @param clean_df Cleaned KEV data
#' @param years Vector of years to compare
#' @return Comparison tibble
compute_yoy_comparison <- function(clean_df, years = NULL) {
  if (is.null(years)) {
    years <- sort(unique(clean_df$added_year))
    years <- years[!is.na(years)]
  }
  
  clean_df |>
    filter(added_year %in% years) |>
    count(added_year, name = "yearly_total") |>
    arrange(added_year) |>
    mutate(
      prev_year = lag(yearly_total),
      yoy_change = yearly_total - prev_year,
      yoy_pct_change = round((yearly_total - prev_year) / prev_year * 100, 1)
    )
}

#' Rolling average calculation
#' @param monthly_df Monthly summary from create_monthly_summary
#' @param window Months for rolling window
#' @return Monthly summary with rolling average column
compute_rolling_average <- function(monthly_df, window = 3) {
  monthly_df |>
    mutate(
      rolling_avg = zoo::rollmean(vuln_count, k = window, fill = NA, align = "right")
    )
}

#' Vendor risk profile
#' @param clean_df Cleaned KEV data
#' @param vendor_name Vendor to profile
#' @return List with vendor profile metrics
compute_vendor_profile <- function(clean_df, vendor_name) {
  vendor_data <- clean_df |> filter(vendor_project == vendor_name)
  
  if (nrow(vendor_data) == 0) {
    return(list(error = "Vendor not found"))
  }
  
  total <- nrow(vendor_data)
  products <- n_distinct(vendor_data$product)
  ransomware <- sum(vendor_data$known_ransomware_campaign_use == "Yes", na.rm = TRUE)
  overdue <- sum(vendor_data$due_status == "Overdue", na.rm = TRUE)
  upcoming <- sum(vendor_data$due_status == "Upcoming", na.rm = TRUE)
  
  # Timeline
  first_added <- min(vendor_data$date_added, na.rm = TRUE)
  last_added <- max(vendor_data$date_added, na.rm = TRUE)
  
  # Top products
  top_products <- vendor_data |>
    count(product, name = "count") |>
    arrange(desc(count)) |>
    slice_head(n = 10)
  
  # Monthly trend
  monthly_trend <- vendor_data |>
    count(added_ym, name = "count") |>
    arrange(added_ym)
  
  list(
    vendor = vendor_name,
    total_vulnerabilities = total,
    distinct_products = products,
    ransomware_count = ransomware,
    ransomware_pct = round(ransomware / total * 100, 1),
    overdue_count = overdue,
    upcoming_count = upcoming,
    first_catalog_entry = first_added,
    latest_catalog_entry = last_added,
    top_products = top_products,
    monthly_trend = monthly_trend
  )
}

#' Search vulnerabilities by text
#' @param clean_df Cleaned KEV data
#' @param query Search query string
#' @param columns Columns to search in
#' @return Filtered tibble
search_vulnerabilities <- function(clean_df, query, 
                                   columns = c("cve_id", "vendor_project", "product", 
                                               "vulnerability_name", "short_description")) {
  if (is.null(query) || query == "") {
    return(clean_df)
  }
  
  # Escape special regex characters for literal search
  safe_query <- stringr::str_escape(query)
  
  # Build search condition
  search_conditions <- purrr::map(columns, function(col) {
    if (col %in% names(clean_df)) {
      stringr::str_detect(clean_df[[col]], regex(safe_query, ignore_case = TRUE))
    } else {
      FALSE
    }
  })
  
  combined <- Reduce(`|`, search_conditions)
  clean_df[combined, ]
}

#' Get recent additions for overview table
#' @param clean_df Cleaned KEV data
#' @param n Number of recent records
#' @return Recent records tibble
get_recent_additions <- function(clean_df, n = 10) {
  clean_df |>
    arrange(desc(date_added)) |>
    slice_head(n = n) |>
    select(cve_id, vendor_project, product, vulnerability_name, 
           date_added, due_date, known_ransomware_campaign_use)
}

#' Export filtered data to CSV
#' @param filtered_df Filtered data
#' @param file_path Output file path
#' @return Invisible file path
export_filtered_csv <- function(filtered_df, file_path) {
  # Select relevant columns for export
  export_df <- filtered_df |>
    select(
      cve_id, vendor_project, product, vulnerability_name,
      date_added, short_description, required_action, due_date,
      known_ransomware_campaign_use, forensic_triage, notes, cwes
    )
  
  readr::write_csv(export_df, file_path)
  invisible(file_path)
}

#' Compute date range options for UI
#' @param clean_df Cleaned KEV data
#' @return List with min/max dates and preset ranges
get_date_range_options <- function(clean_df) {
  min_date <- min(clean_df$date_added, na.rm = TRUE)
  max_date <- max(clean_df$date_added, na.rm = TRUE)
  today <- Sys.Date()
  
  list(
    min_date = min_date,
    max_date = max_date,
    presets = list(
      "Last 30 days" = c(today - 30, today),
      "Last 90 days" = c(today - 90, today),
      "Last 1 year" = c(today - 365, today),
      "Last 2 years" = c(today - 730, today),
      "All time" = c(min_date, max_date)
    )
  )
}