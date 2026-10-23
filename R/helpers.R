# CyberShield Helpers Module
# Utility functions for the dashboard

library(dplyr)
library(lubridate)
library(htmltools)

# Null coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Format number with commas
#' @param x Numeric value
#' @return Formatted character string
fmt_num <- function(x) {
  if (is.na(x) || is.null(x)) return("—")
  scales::label_comma()(x)
}

#' Format percentage
#' @param x Numeric proportion (0-1)
#' @param digits Decimal places
#' @return Formatted percentage string
fmt_pct <- function(x, digits = 1) {
  if (is.na(x) || is.null(x)) return("—")
  paste0(round(x * 100, digits), "%")
}

#' Format date for display
#' @param d Date object
#' @param format_str Format string
#' @return Formatted date string
fmt_date <- function(d, format_str = "%b %d, %Y") {
  if (is.na(d) || is.null(d)) return("—")
  format(d, format_str)
}

#' Generate date range presets for UI
#' @param min_date Minimum available date
#' @param max_date Maximum available date
#' @return Named list of date ranges
generate_date_presets <- function(min_date, max_date) {
  today <- Sys.Date()
  list(
    "Last 7 days" = c(max(today - 7, min_date), today),
    "Last 30 days" = c(max(today - 30, min_date), today),
    "Last 90 days" = c(max(today - 90, min_date), today),
    "Last 180 days" = c(max(today - 180, min_date), today),
    "Last 1 year" = c(max(today - 365, min_date), today),
    "Last 2 years" = c(max(today - 730, min_date), today),
    "All time" = c(min_date, max_date)
  )
}

#' Safe subset for reactive data
#' @param df Data frame
#' @param condition Logical condition
#' @return Subsetted data frame (empty if error)
safe_filter <- function(df, condition) {
  tryCatch({
    df[condition, , drop = FALSE]
  }, error = function(e) {
    df[0, , drop = FALSE]
  })
}

#' Create a styled info box for UI
#' @param title Box title
#' @param content Box content (HTML)
#' @param status Bootstrap status color
#' @return HTML div
info_box <- function(title, content, status = "info") {
  colors <- list(
    info = list(bg = "#1e3a5f", border = "#3a7bd5"),
    success = list(bg = "#1a3c2e", border = "#2ea043"),
    warning = list(bg = "#3d2e00", border = "#d29922"),
    danger = list(bg = "#3d1515", border = "#f85149")
  )
  
  clr <- colors[[status]] %||% colors$info
  
  tags$div(
    class = "p-3 mb-3 rounded",
    style = sprintf(
      "background-color: %s; border-left: 4px solid %s;",
      clr$bg, clr$border
    ),
    tags$h6(class = "mb-2", style = "color: #f0f6fc;", title),
    tags$div(style = "color: #c9d1d9;", content)
  )
}

#' Create a metric card for KPI display
#' @param value Numeric value
#' @param label Label text
#' @param change Optional change indicator
#' @param icon Bootstrap icon name
#' @return HTML div
metric_card <- function(value, label, change = NULL, icon = "graph-up") {
  change_html <- if (!is.null(change)) {
    change_color <- if (grepl("^\\+|^\\d", change)) "#3fb950" else "#f85149"
    tags$span(
      class = "small",
      style = sprintf("color: %s;", change_color),
      change
    )
  } else NULL
  
  tags$div(
    class = "p-3 h-100",
    style = "background-color: #21262d; border: 1px solid #30363d; border-radius: 12px;",
    tags$div(
      class = "d-flex justify-content-between align-items-start mb-2",
      tags$span(class = "fw-bold", style = "font-size: 1.5rem; color: #f0f6fc;", fmt_num(value)),
      tags$span(bsicons::bs_icon(icon, size = "1.5rem"), style = "color: #58a6ff;")
    ),
    tags$div(class = "small text-muted", label),
    if (!is.null(change_html)) tags$div(class = "mt-1", change_html)
  )
}

#' Format data table for DT with CyberShield styling
#' @param df Data frame
#' @param page_length Default page length
#' @return DT datatable options list
dt_options_cybershield <- function(page_length = 15) {
  list(
    pageLength = page_length,
    lengthMenu = c(10, 15, 25, 50, 100),
    scrollX = TRUE,
    autoWidth = TRUE,
    dom = 'lfrtip',
    language = list(
      search = "Search:",
      lengthMenu = "Show _MENU_ entries",
      info = "Showing _START_ to _END_ of _TOTAL_ entries",
      paginate = list(
        first = "First",
        last = "Last",
        `next` = "Next",
        previous = "Previous"
      ),
      emptyTable = "No matching records found",
      zeroRecords = "No records to display"
    ),
    initComplete = htmlwidgets::JS(
      "function(settings, json) {",
      "  $(this.api().table().header()).css({'background-color': '#161b22', 'color': '#f0f6fc'});",
      "}"
    )
  )
}

#' Get unique sorted vendors for filter dropdown
#' @param clean_df Cleaned KEV data
#' @return Sorted character vector
get_vendor_choices <- function(clean_df) {
  sort(unique(clean_df$vendor_project))
}

#' Get unique sorted products for a vendor
#' @param clean_df Cleaned KEV data
#' @param vendor Vendor name
#' @return Sorted character vector
get_product_choices <- function(clean_df, vendor = NULL) {
  df <- clean_df
  if (!is.null(vendor)) {
    df <- df |> filter(vendor_project == vendor)
  }
  sort(unique(df$product))
}

#' Validate CVE ID format
#' @param cve_id Character string
#' @return Logical
is_valid_cve <- function(cve_id) {
  grepl("^CVE-\\d{4}-\\d{4,}$", cve_id)
}

#' Extract CVE year
#' @param cve_id Character string
#' @return Numeric year or NA
extract_cve_year <- function(cve_id) {
  match <- regexec("^CVE-(\\d{4})", cve_id)
  regmatches(cve_id, match) |>
    sapply(function(x) if (length(x) > 1) as.numeric(x[2]) else NA_real_)
}

#' Create download handler for filtered CSV
#' @param filtered_reactive Reactive expression returning filtered data
#' @param filename_prefix Prefix for downloaded file
#' @return Shiny downloadHandler
create_csv_download <- function(filtered_reactive, filename_prefix = "cybershield_export") {
  shiny::downloadHandler(
    filename = function() {
      paste0(filename_prefix, "_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      df <- filtered_reactive()
      export_df <- df |>
        select(
          cve_id, vendor_project, product, vulnerability_name,
          date_added, short_description, required_action, due_date,
          known_ransomware_campaign_use, forensic_triage, notes, cwes
        )
      readr::write_csv(export_df, file)
    },
    contentType = "text/csv"
  )
}

#' Debounce helper for search input
#' @param input_reactive Reactive input
#' @param millis Debounce milliseconds
#' @return Debounced reactive
debounce_input <- function(input_reactive, millis = 300) {
  shiny::debounce(input_reactive, millis)
}

#' Get dataset metadata for display
#' @return List with metadata
get_dataset_info <- function() {
  meta_file <- "data/data_metadata.json"
  if (file.exists(meta_file)) {
    meta <- jsonlite::read_json(meta_file)
    list(
      source = meta$source_url %||% "CISA KEV Catalog",
      retrieved = meta$retrieval_date %||% "Unknown",
      rows = meta$row_count %||% "Unknown",
      status = meta$status %||% "unknown"
    )
  } else {
    list(
      source = "CISA KEV Catalog",
      retrieved = "Unknown",
      rows = "Unknown",
      status = "no_metadata"
    )
  }
}

#' Check if running in RStudio
#' @return Logical
is_rstudio <- function() {
  Sys.getenv("RSTUDIO") == "1"
}

#' Get R version string
#' @return Formatted version string
get_r_version <- function() {
  paste0("R ", R.version$major, ".", R.version$minor)
}

#' Get package versions for reproducibility
#' @param packages Character vector of package names
#' @return Named list of versions
get_package_versions <- function(packages = c("shiny", "bslib", "dplyr", "readr", 
                                               "janitor", "lubridate", "ggplot2",
                                               "plotly", "DT", "httr2")) {
  versions <- list()
  for (pkg in packages) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      versions[[pkg]] <- as.character(packageVersion(pkg))
    } else {
      versions[[pkg]] <- "not installed"
    }
  }
  versions
}
