# Setup user library path
user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
if (dir.exists(user_lib)) .libPaths(c(user_lib, .libPaths()))

library(shiny)
library(bslib)
library(dplyr)
library(readr)
library(janitor)
library(lubridate)
library(ggplot2)
library(plotly)
library(DT)
library(purrr)
library(bsicons)
library(scales)
library(tibble)

source("R/data_loader.R")
source("R/data_cleaning.R")
source("R/analysis.R")
source("R/charts.R")
source("R/helpers.R")

cat("Loading CISA KEV data...\n")
raw <- load_kev_raw("data/known_exploited_vulnerabilities.csv")
raw <- validate_kev_columns(raw)
dedup <- check_duplicates(raw)
df <- clean_kev_data(dedup$data)
meta <- get_dataset_info()
cat("Loaded", nrow(df), "records\n")

# ── Modern CSS for fintech-style dashboard ─────────────────────────────────────
custom_css <- "
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');

:root {
  --bg-base: #0a0a0f;
  --bg-card: #12121a;
  --bg-card-hover: #1a1a25;
  --bg-surface: #16161f;
  --border: #1e1e2e;
  --border-hover: #2a2a3e;
  --text-primary: #f0f0f5;
  --text-secondary: #6b6b80;
  --text-muted: #4a4a5e;
  --accent-blue: #4d7cfe;
  --accent-purple: #8b5cf6;
  --accent-cyan: #06b6d4;
  --accent-green: #10b981;
  --accent-red: #ef4444;
  --accent-amber: #f59e0b;
  --accent-pink: #ec4899;
  --glow-blue: rgba(77,124,254,0.15);
  --glow-purple: rgba(139,92,246,0.15);
  --glow-green: rgba(16,185,129,0.15);
  --glow-red: rgba(239,68,68,0.15);
}

* { box-sizing: border-box; }

body {
  background: var(--bg-base) !important;
  color: var(--text-primary) !important;
  font-family: 'Inter', -apple-system, sans-serif !important;
  -webkit-font-smoothing: antialiased;
}

/* Sidebar */
#sidebar {
  background: var(--bg-base) !important;
  border-right: 1px solid var(--border) !important;
  padding: 0 !important;
}

#sidebar .sidebar-header {
  padding: 20px 20px 10px 20px;
  border-bottom: 1px solid var(--border);
}

.logo-section {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 20px 24px 16px;
  border-bottom: 1px solid var(--border);
}

.logo-icon {
  width: 38px;
  height: 38px;
  background: linear-gradient(135deg, var(--accent-blue), var(--accent-purple));
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  box-shadow: 0 0 20px var(--glow-blue);
}

.logo-text {
  font-size: 20px;
  font-weight: 700;
  background: linear-gradient(135deg, #fff, #a0a0c0);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

/* Cards */
.card {
  background: var(--bg-card) !important;
  border: 1px solid var(--border) !important;
  border-radius: 16px !important;
  box-shadow: none !important;
  transition: all 0.2s ease;
  overflow: hidden;
}
.card:hover {
  border-color: var(--border-hover) !important;
}
.card-header {
  background: transparent !important;
  border-bottom: 1px solid var(--border) !important;
  color: var(--text-primary) !important;
  font-weight: 600 !important;
  font-size: 14px !important;
  padding: 16px 20px !important;
}
.card-body { padding: 20px !important; }
.card-footer {
  background: transparent !important;
  border-top: 1px solid var(--border) !important;
}

/* KPI Cards */
.kpi-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 24px;
  position: relative;
  overflow: hidden;
  transition: all 0.3s ease;
}
.kpi-card:hover {
  border-color: var(--border-hover);
  transform: translateY(-2px);
}
.kpi-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  border-radius: 16px 16px 0 0;
}
.kpi-card.blue::before { background: linear-gradient(90deg, var(--accent-blue), var(--accent-cyan)); }
.kpi-card.purple::before { background: linear-gradient(90deg, var(--accent-purple), var(--accent-pink)); }
.kpi-card.green::before { background: linear-gradient(90deg, var(--accent-green), var(--accent-cyan)); }
.kpi-card.red::before { background: linear-gradient(90deg, var(--accent-red), var(--accent-amber)); }
.kpi-card.amber::before { background: linear-gradient(90deg, var(--accent-amber), var(--accent-red)); }

.kpi-icon {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
}
.kpi-icon.blue { background: rgba(77,124,254,0.15); color: var(--accent-blue); }
.kpi-icon.purple { background: rgba(139,92,246,0.15); color: var(--accent-purple); }
.kpi-icon.green { background: rgba(16,185,129,0.15); color: var(--accent-green); }
.kpi-icon.red { background: rgba(239,68,68,0.15); color: var(--accent-red); }
.kpi-icon.amber { background: rgba(245,158,11,0.15); color: var(--accent-amber); }

.kpi-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1;
  margin: 12px 0 4px;
}
.kpi-label {
  font-size: 13px;
  color: var(--text-secondary);
  font-weight: 500;
}
.kpi-change {
  font-size: 12px;
  font-weight: 600;
  margin-top: 8px;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 8px;
  border-radius: 6px;
}
.kpi-change.up { background: rgba(16,185,129,0.1); color: var(--accent-green); }
.kpi-change.down { background: rgba(239,68,68,0.1); color: var(--accent-red); }

/* Navigation */
.navset_card_tab > .nav-tabs {
  background: transparent !important;
  border-bottom: 1px solid var(--border) !important;
  padding: 0 12px;
  gap: 4px;
}
.navset_card_tab > .nav-tabs .nav-link {
  color: var(--text-secondary) !important;
  border: none !important;
  border-radius: 10px !important;
  padding: 10px 16px !important;
  font-size: 13px !important;
  font-weight: 500 !important;
  margin: 6px 0 !important;
  transition: all 0.2s;
}
.navset_card_tab > .nav-tabs .nav-link:hover {
  color: var(--text-primary) !important;
  background: var(--bg-surface) !important;
}
.navset_card_tab > .nav-tabs .nav-link.active {
  color: #fff !important;
  background: linear-gradient(135deg, var(--accent-blue), var(--accent-purple)) !important;
  box-shadow: 0 0 20px var(--glow-blue);
}

/* Inputs */
.form-control, .form-select {
  background: var(--bg-surface) !important;
  border: 1px solid var(--border) !important;
  border-radius: 10px !important;
  color: var(--text-primary) !important;
  font-size: 13px !important;
  padding: 10px 14px !important;
}
.form-control:focus, .form-select:focus {
  border-color: var(--accent-blue) !important;
  box-shadow: 0 0 0 3px var(--glow-blue) !important;
}
.form-label { color: var(--text-secondary) !important; font-size: 12px !important; font-weight: 500 !important; }

/* Tables */
.dataTables_wrapper { color: var(--text-primary) !important; }
table.dataTable { border-color: var(--border) !important; }
table.dataTable thead th {
  background: var(--bg-surface) !important;
  color: var(--text-secondary) !important;
  border-bottom: 1px solid var(--border) !important;
  font-weight: 600 !important;
  font-size: 11px !important;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  padding: 12px 16px !important;
}
table.dataTable tbody td {
  color: var(--text-primary) !important;
  border-bottom: 1px solid var(--border) !important;
  padding: 10px 16px !important;
  font-size: 13px !important;
}
table.dataTable tbody tr:hover { background: var(--bg-surface) !important; }

/* Status pills */
.status-pill {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 10px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 600;
}
.status-pill.red { background: rgba(239,68,68,0.15); color: var(--accent-red); }
.status-pill.green { background: rgba(16,185,129,0.15); color: var(--accent-green); }
.status-pill.amber { background: rgba(245,158,11,0.15); color: var(--accent-amber); }
.status-pill.blue { background: rgba(77,124,254,0.15); color: var(--accent-blue); }
.status-pill.gray { background: rgba(107,107,128,0.15); color: var(--text-secondary); }
.status-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}
.status-dot.red { background: var(--accent-red); box-shadow: 0 0 6px var(--accent-red); }
.status-dot.green { background: var(--accent-green); box-shadow: 0 0 6px var(--accent-green); }

/* Badge */
.badge {
  font-size: 10px !important;
  font-weight: 600 !important;
  padding: 4px 10px !important;
  border-radius: 6px !important;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

/* Section title */
.section-title {
  font-size: 18px;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: 4px;
}
.section-subtitle {
  font-size: 13px;
  color: var(--text-secondary);
}

/* Scrollbar */
::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: var(--bg-base); }
::-webkit-scrollbar-thumb { background: var(--border); border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: var(--border-hover); }

/* Alert */
.alert {
  border-radius: 12px !important;
  border: 1px solid var(--border) !important;
  background: var(--bg-card) !important;
}

/* Divider */
hr { border-color: var(--border) !important; opacity: 1 !important; }
"

# ── UI ─────────────────────────────────────────────────────────────────────────
ui <- page_sidebar(
  title = NULL,
  theme = bs_theme(
    version = 5,
    bg = "#0a0a0f", fg = "#f0f0f5",
    primary = "#4d7cfe",
    "body-bg" = "#0a0a0f",
    "navbar-bg" = "#0a0a0f",
    "sidebar-bg" = "#0a0a0f",
    "card-bg" = "#12121a",
    "border-color" = "#1e1e2e",
    base_font = font_google("Inter")
  ),
  
  tags$head(tags$style(HTML(custom_css))),
  
  sidebar = sidebar(
    width = 270,
    class = "p-0",
    
    # Logo
    tags$div(class = "logo-section",
      tags$div(class = "logo-icon", bs_icon("shield-lock", size = "1.2rem")),
      tags$div(
        tags$div(class = "logo-text", "CyberShield"),
        tags$div(style = "font-size:10px;color:#6b6b80;margin-top:-2px;", "Vulnerability Intelligence")
      )
    ),
    
    # Live status
    tags$div(
      style = "margin:16px 20px;padding:10px 14px;background:rgba(16,185,129,0.08);border:1px solid rgba(16,185,129,0.2);border-radius:10px;",
      tags$div(class = "d-flex align-items-center gap-2",
        tags$span(style = "width:7px;height:7px;border-radius:50%;background:#10b981;box-shadow:0 0 8px #10b981;display:inline-block;"),
        tags$span(style = "font-size:11px;font-weight:600;color:#10b981;", "Live Data"),
        tags$span(style = "font-size:10px;color:#6b6b80;margin-left:auto;", meta$retrieved)
      )
    ),
    
    # Navigation
    tags$div(style = "padding:0 12px;",
      tags$div(style = "padding:8px 12px;font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#4a4a5e;font-weight:600;", "Navigation"),
      uiOutput("nav_buttons")
    ),
    
    # Filters
    tags$div(style = "padding:16px 20px 0;border-top:1px solid #1e1e2e;margin-top:12px;",
      tags$div(style = "padding:8px 0;font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#4a4a5e;font-weight:600;", "Filters"),
      
      selectInput("vendor_filter", "Vendor",
        choices = c("All Vendors" = "All", sort(unique(df$vendor_project))),
        selected = "All", width = "100%"),
      
      selectInput("ransom_filter", "Ransomware",
        choices = c("All" = "All", "Yes" = "Yes", "No" = "No", "Unknown" = "Unknown"),
        selected = "All", width = "100%"),
      
      dateRangeInput("date_range", "Date Range",
        start = max(min(df$date_added, na.rm=TRUE), Sys.Date() - 365),
        end = max(df$date_added, na.rm=TRUE),
        min = min(df$date_added, na.rm=TRUE),
        max = max(df$date_added, na.rm=TRUE),
        separator = " to ", width = "100%")
    ),
    
    # Quick stats
    tags$div(style = "padding:16px 20px;border-top:1px solid #1e1e2e;margin-top:16px;",
      tags$div(style = "padding-bottom:8px;font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#4a4a5e;font-weight:600;", "Dataset Info"),
      tags$div(style = "font-size:11px;color:#6b6b80;line-height:1.8;",
        tags$div(class = "d-flex justify-content-between",
          tags$span("Source:"), tags$span(style="color:#f0f0f5;", "CISA KEV")),
        tags$div(class = "d-flex justify-content-between",
          tags$span("Records:"), tags$span(style="color:#f0f0f5;", fmt_num(nrow(df)))),
        tags$div(class = "d-flex justify-content-between",
          tags$span("Retrieved:"), tags$span(style="color:#f0f0f5;", meta$retrieved))
      )
    )
  ),
  
  # ── Main content ─────────────────────────────────────────────────────────────
  tags$div(style = "padding:4px 8px;",
    uiOutput("main_content")
  )
)

# ── Server ─────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  # Reactive page state
  page <- reactiveVal("overview")
  
  # Nav buttons
  output$nav_buttons <- renderUI({
    pages <- list(
      overview = list(icon = "speedometer2", label = "Overview"),
      analytics = list(icon = "graph-up", label = "Analytics"),
      gallery = list(icon = "grid-1x2", label = "Visualizations"),
      remediation = list(icon = "clipboard-check", label = "Remediation"),
      explorer = list(icon = "search", label = "Explorer"),
      about = list(icon = "info-circle", label = "About")
    )
    
    btns <- lapply(names(pages), function(p) {
      active <- page() == p
      tags$a(
        onclick = sprintf("Shiny.setInputValue('nav_page', '%s', {priority:'event'})", p),
        style = paste0(
          "display:flex;align-items:center;gap:10px;padding:10px 14px;border-radius:10px;",
          "cursor:pointer;font-size:13px;font-weight:500;transition:all 0.2s;margin-bottom:2px;",
          if (active) "background:linear-gradient(135deg,rgba(77,124,254,0.15),rgba(139,92,246,0.15));color:#4d7cfe;border:1px solid rgba(77,124,254,0.2);"
          else "color:#6b6b80;border:1px solid transparent;"
        ),
        bs_icon(pages[[p]]$icon, size = "1rem"),
        pages[[p]]$label
      )
    })
    tags$div(do.call(tagList, btns))
  })
  
  # Update page on nav click
  observeEvent(input$nav_page, {
    page(input$nav_page)
  })
  
  # ── Reactive data ────────────────────────────────────────────────────────────
  filtered_df <- reactive({
    df |>
      filter(
        date_added >= input$date_range[1],
        date_added <= input$date_range[2]
      ) |>
      filter(if (input$vendor_filter != "All") vendor_project == input$vendor_filter else TRUE) |>
      filter(if (input$ransom_filter != "All")
               as.character(known_ransomware_campaign_use) == input$ransom_filter
             else TRUE)
  })
  
  # ── KPI helpers ──────────────────────────────────────────────────────────────
  kpi_card_ui <- function(value, label, icon, color_class, change = NULL) {
    change_html <- if (!is.null(change)) {
      tags$div(class = paste("kpi-change", if (change >= 0) "up" else "down"),
        bs_icon(if (change >= 0) "arrow-up-right" else "arrow-down-right", size = "0.7rem"),
        sprintf("%+.0f%% vs last year", change)
      )
    }
    tags$div(class = paste("kpi-card", color_class),
      tags$div(class = "kpi-icon", color_class, bs_icon(icon, size = "1.2rem")),
      tags$div(class = "kpi-value", fmt_num(value)),
      tags$div(class = "kpi-label", label),
      change_html
    )
  }
  
  # Year-over-year change for a metric
  yoy_change <- function(metric_fn) {
    d <- filtered_df()
    this_year <- d |> filter(added_year == max(added_year, na.rm=TRUE))
    last_year <- d |> filter(added_year == max(added_year, na.rm=TRUE) - 1)
    if (nrow(last_year) == 0) return(NA)
    val_now <- metric_fn(this_year)
    val_prev <- metric_fn(last_year)
    if (val_prev == 0) return(NA)
    round((val_now - val_prev) / val_prev * 100, 1)
  }
  
  # ── Main content router ──────────────────────────────────────────────────────
  output$main_content <- renderUI({
    switch(page(),
      overview = overview_ui(),
      analytics = analytics_ui(),
      gallery = gallery_ui(),
      remediation = remediation_ui(),
      explorer = explorer_ui(),
      about = about_ui(),
      overview_ui()
    )
  })
  
  # ── UI builders ──────────────────────────────────────────────────────────────
  
  overview_ui <- function() {
    d <- filtered_df()
    total <- nrow(d)
    vendors <- n_distinct(d$vendor_project)
    ransom <- sum(d$known_ransomware_campaign_use == "Yes", na.rm=TRUE)
    overdue <- sum(d$due_status == "Overdue", na.rm=TRUE)
    upcoming <- sum(d$due_status == "Upcoming", na.rm=TRUE)
    triage <- sum(d$forensic_triage == "Yes", na.rm=TRUE)
    
    tagList(
      # Header
      tags$div(style = "margin-bottom:24px;",
        tags$div(class = "section-title", "Security Intelligence Overview"),
        tags$div(class = "section-subtitle", "Real-time view of known exploited vulnerabilities from CISA KEV Catalog")
      ),
      
      # KPI row 1
      layout_columns(col_widths = c(3,3,3,3), class = "mb-4",
        kpi_card_ui(total, "Total Vulnerabilities", "shield-exclamation", "blue",
                    yoy_change(function(x) nrow(x))),
        kpi_card_ui(vendors, "Unique Vendors", "buildings", "purple"),
        kpi_card_ui(ransom, "Ransomware-Linked", "bug", "red",
                    yoy_change(function(x) sum(x$known_ransomware_campaign_use=="Yes", na.rm=TRUE))),
        kpi_card_ui(overdue, "Overdue Remediation", "clock", "amber",
                    yoy_change(function(x) sum(x$due_status=="Overdue", na.rm=TRUE)))
      ),
      
      # KPI row 2
      layout_columns(col_widths = c(4,4,4), class = "mb-4",
        kpi_card_ui(upcoming, "Upcoming Deadlines", "calendar-check", "green"),
        kpi_card_ui(triage, "Forensic Triage Required", "search", "purple"),
        kpi_card_ui(n_distinct(d$product), "Affected Products", "box", "blue")
      ),
      
      # Main charts
      layout_columns(col_widths = c(8,4), class = "mb-4",
        card(
          card_header(
            class = "d-flex justify-content-between align-items-center",
            tags$span("Vulnerability Timeline"),
            tags$span(class = "badge bg-primary", "Monthly")
          ),
          plotlyOutput("trend_plot", height = "300px")
        ),
        card(
          card_header("Threat Distribution"),
          plotlyOutput("ransom_pie", height = "300px")
        )
      ),
      
      layout_columns(col_widths = c(7,5), class = "mb-4",
        card(
          card_header(
            class = "d-flex justify-content-between align-items-center",
            tags$span("Top Vulnerable Vendors"),
            tags$span(class = "badge bg-secondary", "Top 10")
          ),
          plotlyOutput("vendor_bar", height = "300px")
        ),
        card(
          card_header("Remediation Status"),
          plotlyOutput("remediation_plot", height = "300px")
        )
      ),
      
      # Recent activity
      card(
        card_header(
          class = "d-flex justify-content-between align-items-center",
          tags$span("Recent Catalog Additions"),
          tags$span(class = "badge bg-success", "Live Feed")
        ),
        DTOutput("recent_table")
      )
    )
  }
  
  analytics_ui <- function() {
    tagList(
      tags$div(style = "margin-bottom:24px;",
        tags$div(class = "section-title", "Advanced Analytics"),
        tags$div(class = "section-subtitle", "Statistical analysis and trend decomposition")
      ),
      
      layout_columns(col_widths = c(12),
        card(card_header("Year-over-Year Vulnerability Additions"),
          plotlyOutput("yearly_plot", height = "350px"))
      ),
      
      layout_columns(col_widths = c(6,6),
        card(card_header("YoY Change (%)"), plotlyOutput("yoy_plot", height = "280px")),
        card(card_header("Period Summary"), verbatimTextOutput("period_summary"))
      )
    )
  }
  
  gallery_ui <- function() {
    tagList(
      tags$div(style = "margin-bottom:24px;",
        tags$div(class = "section-title", "Visualization Gallery"),
        tags$div(class = "section-subtitle", "20+ interactive chart types showcasing different visual encoding techniques")
      ),
      
      layout_columns(col_widths = c(7,5),
        card(card_header(tags$span("Heatmap — Vendor × Year", class="badge bg-primary ms-2")),
          plotlyOutput("viz_heatmap", height = "380px")),
        card(card_header(tags$span("Donut — Ransomware", class="badge bg-danger ms-2")),
          plotlyOutput("viz_donut", height = "380px"))
      ),
      
      layout_columns(col_widths = c(6,6),
        card(card_header(tags$span("Lollipop — Top Products", class="badge bg-success ms-2")),
          plotlyOutput("viz_lollipop", height = "400px")),
        card(card_header(tags$span("Treemap — Vendor Ecosystem", class="badge bg-warning ms-2")),
          plotlyOutput("viz_treemap", height = "400px"))
      ),
      
      layout_columns(col_widths = c(6,6),
        card(card_header(tags$span("Histogram — CVE Years", class="badge bg-info ms-2")),
          plotlyOutput("viz_histogram", height = "350px")),
        card(card_header(tags$span("Box Plot — Remediation Window", class="badge bg-secondary ms-2")),
          plotlyOutput("viz_boxplot", height = "350px"))
      ),
      
      layout_columns(col_widths = c(6,6),
        card(card_header(tags$span("Density — Monthly Distribution", class="badge bg-primary ms-2")),
          plotlyOutput("viz_density", height = "350px")),
        card(card_header(tags$span("Stacked Area — Ransomware Over Time", class="badge bg-danger ms-2")),
          plotlyOutput("viz_stacked_area", height = "350px"))
      ),
      
      layout_columns(col_widths = c(6,6),
        card(card_header(tags$span("Scatter — Due Date Analysis", class="badge bg-success ms-2")),
          plotlyOutput("viz_scatter", height = "380px")),
        card(card_header(tags$span("Polar — Day of Week", class="badge bg-warning ms-2")),
          plotlyOutput("viz_polar", height = "380px"))
      ),
      
      layout_columns(col_widths = c(6,6),
        card(card_header(tags$span("Waffle — Forensic Triage", class="badge bg-info ms-2")),
          plotlyOutput("viz_waffle", height = "380px")),
        card(card_header(tags$span("Diverging — Vendor Risk", class="badge bg-secondary ms-2")),
          plotlyOutput("viz_diverging", height = "380px"))
      ),
      
      layout_columns(col_widths = c(6,6),
        card(card_header(tags$span("Slope — Ransomware YoY", class="badge bg-primary ms-2")),
          plotlyOutput("viz_slope", height = "350px")),
        card(card_header(tags$span("CWE — Weakness Types", class="badge bg-danger ms-2")),
          plotlyOutput("viz_cwe", height = "350px"))
      ),
      
      # NEW ROWS — additional chart types
      layout_columns(col_widths = c(6,6),
        card(card_header(tags$span("Bubble — Vendor Scale × Ransomware", class="badge bg-success ms-2")),
          plotlyOutput("viz_bubble", height = "400px")),
        card(card_header(tags$span("Violin — Remediation Window by Year", class="badge bg-warning ms-2")),
          plotlyOutput("viz_violin", height = "400px"))
      ),
      
      layout_columns(col_widths = c(6,6),
        card(card_header(tags$span("Sunburst — Vendor → Product Hierarchy", class="badge bg-info ms-2")),
          plotlyOutput("viz_sunburst", height = "420px")),
        card(card_header(tags$span("Funnel — Due Date Pipeline", class="badge bg-secondary ms-2")),
          plotlyOutput("viz_funnel", height = "420px"))
      ),
      
      layout_columns(col_widths = c(6,6),
        card(card_header(tags$span("Calendar Heatmap — Daily Additions", class="badge bg-primary ms-2")),
          plotlyOutput("viz_calendar", height = "300px")),
        card(card_header(tags$span("Parallel Categories — Vendor / Year / Ransomware", class="badge bg-danger ms-2")),
          plotlyOutput("viz_parcats", height = "400px"))
      ),
      
      layout_columns(col_widths = c(6,6),
        card(card_header(tags$span("Indicator Cards — Key Metrics", class="badge bg-success ms-2")),
          plotlyOutput("viz_indicators", height = "200px")),
        card(card_header(tags$span("Waterfall — Monthly Change", class="badge bg-warning ms-2")),
          plotlyOutput("viz_waterfall", height = "350px"))
      ),
      
      layout_columns(col_widths = c(6,6),
        card(card_header(tags$span("Radar — Vendor Comparison", class="badge bg-info ms-2")),
          plotlyOutput("viz_radar", height = "400px")),
        card(card_header(tags$span("Word Frequency — Vulnerability Types", class="badge bg-secondary ms-2")),
          plotlyOutput("viz_wordfreq", height = "400px"))
      )
    )
  }
  
  remediation_ui <- function() {
    tagList(
      tags$div(style = "margin-bottom:24px;",
        tags$div(class = "section-title", "Remediation Tracker"),
        tags$div(class = "section-subtitle", "CISA catalog due dates vs. current status")
      ),
      card(card_header("Overdue Vulnerabilities"),
        DTOutput("overdue_table"))
    )
  }
  
  explorer_ui <- function() {
    tagList(
      tags$div(style = "margin-bottom:24px;",
        tags$div(class = "section-title", "Vulnerability Explorer"),
        tags$div(class = "section-subtitle", "Search, filter, and export vulnerability records")
      ),
      
      layout_sidebar(
        sidebar = sidebar(
          textInput("search_box", "Search CVE / Vendor / Product", "", width = "100%"),
          width = 300, bg = "#12121a", border = "#1e1e2e"
        ),
        card(
          card_header(
            class = "d-flex justify-content-between align-items-center",
            tags$span("Explorer"),
            downloadButton("download_csv", "Export CSV", class = "btn-sm btn-outline-primary")
          ),
          DTOutput("explorer_table")
        )
      )
    )
  }
  
  about_ui <- function() {
    tagList(
      tags$div(style = "margin-bottom:24px;",
        tags$div(class = "section-title", "About & Data Sources"),
        tags$div(class = "section-subtitle", "Project information, methodology, and attributions")
      ),
      
      layout_columns(col_widths = c(6,6),
        card(card_header("Data Source"),
          tags$p(style="color:#f0f0f5;", tags$b("CISA Known Exploited Vulnerabilities (KEV) Catalog")),
          tags$p(style="color:#6b6b80;font-size:13px;", "https://www.cisa.gov/known-exploited-vulnerabilities-catalog"),
          tags$p(style="color:#6b6b80;font-size:13px;", paste("Records:", fmt_num(nrow(df)))),
          tags$p(style="color:#6b6b80;font-size:13px;", paste("Retrieved:", meta$retrieved)),
          hr(),
          tags$p(style="color:#6b6b80;font-size:12px;", "All metrics are derived from the public CISA KEV catalog. This dashboard does not reflect organization-specific security posture.")
        ),
        card(card_header("Data Dictionary"),
          tags$table(class = "table table-sm",
            tags$thead(tags$tr(
              tags$th(style="color:#4d7cfe;","Field"),
              tags$th(style="color:#4d7cfe;","Description"))),
            tags$tbody(
              tags$tr(tags$td(style="color:#f0f0f5;","cve_id"), tags$td(style="color:#6b6b80;","CVE identifier")),
              tags$tr(tags$td(style="color:#f0f0f5;","vendor_project"), tags$td(style="color:#6b6b80;","Vendor name")),
              tags$tr(tags$td(style="color:#f0f0f5;","product"), tags$td(style="color:#6b6b80;","Affected product")),
              tags$tr(tags$td(style="color:#f0f0f5;","date_added"), tags$td(style="color:#6b6b80;","Catalog addition date")),
              tags$tr(tags$td(style="color:#f0f0f5;","due_date"), tags$td(style="color:#6b6b80;","Remediation deadline")),
              tags$tr(tags$td(style="color:#f0f0f5;","known_ransomware_campaign_use"), tags$td(style="color:#6b6b80;","Ransomware linkage"))
            ))
        )
      ),
      
      card(card_header("Technology Stack"),
        tags$div(class="d-flex flex-wrap gap-2",
          lapply(c("R 4.6","Shiny","bslib","dplyr","ggplot2","plotly","DT","janitor","lubridate"),
            function(pkg) tags$span(class="badge bg-secondary", pkg))
        )
      )
    )
  }
  
  # ── Shared chart outputs ─────────────────────────────────────────────────────
  
  output$trend_plot <- renderPlotly({
    d <- filtered_df()
    if (nrow(d) == 0) return(plotly_empty("No data for selected filters"))
    monthly <- d |> count(added_ym, name = "vuln_count") |> arrange(added_ym)
    p <- ggplot(monthly, aes(x = added_ym, y = vuln_count)) +
      geom_area(fill = "#4d7cfe", alpha = 0.15) +
      geom_line(color = "#4d7cfe", linewidth = 1.5) +
      geom_point(color = "#06b6d4", size = 1.5) +
      labs(x = NULL, y = "Count") +
      scale_x_date(date_labels = "%b %Y", date_breaks = "2 months") +
      scale_y_continuous(labels = scales::label_comma()) +
      theme_cybershield()
    ggplotly_cs(p)
  })
  
  output$vendor_bar <- renderPlotly({
    d <- filtered_df()
    if (nrow(d) == 0) return(plotly_empty())
    top <- d |> count(vendor_project, name = "n") |> arrange(desc(n)) |> head(10) |>
      mutate(vendor_project = factor(vendor_project, levels = rev(vendor_project)))
    p <- ggplot(top, aes(x = n, y = vendor_project, fill = n)) +
      geom_col(width = 0.7, show.legend = FALSE) +
      geom_text(aes(label = scales::label_comma()(n)), hjust = -0.2, color = "#f0f0f5", size = 3.5) +
      scale_fill_gradient(low = "#4d7cfe", high = "#8b5cf6") +
      labs(x = "Count", y = NULL) +
      theme_cybershield() +
      theme(panel.grid.major.y = element_blank())
    ggplotly_cs(p, tooltip = c("y", "x"))
  })
  
  output$ransom_pie <- renderPlotly({
    d <- filtered_df()
    if (nrow(d) == 0) return(plotly_empty())
    tab <- d |> count(known_ransomware_campaign_use, name = "n")
    colors <- c("Yes" = "#ef4444", "No" = "#10b981", "Unknown" = "#4a4a5e")
    plot_ly(tab, labels = ~known_ransomware_campaign_use, values = ~n,
            type = "pie", hole = 0.65,
            marker = list(colors = unname(colors[as.character(tab$known_ransomware_campaign_use)]),
                          line = list(color = "#0a0a0f", width = 2)),
            textinfo = "label+percent",
            textfont = list(color = "#f0f0f5", size = 12),
            hoverinfo = "label+value+percent",
            hoverlabel = list(bgcolor = "#12121a", font = list(color = "#f0f0f5"))) |>
      layout(plot_bgcolor = "#12121a", paper_bgcolor = "#12121a",
             font = list(color = "#f0f0f5", family = "Inter"),
             margin = list(l=20,r=20,t=20,b=20),
             showlegend = TRUE,
             legend = list(bgcolor = "#12121a", font = list(color = "#f0f0f5"))) |>
      config(displayModeBar = FALSE)
  })
  
  output$remediation_plot <- renderPlotly({
    d <- filtered_df()
    tab <- d |> count(due_status, name = "n") |>
      mutate(due_status = factor(due_status, levels = c("Overdue","Due Today","Upcoming","Unknown")))
    if (nrow(tab) == 0) return(plotly_empty())
    colors <- c("Overdue"="#ef4444", "Due Today"="#f59e0b", "Upcoming"="#4d7cfe", "Unknown"="#4a4a5e")
    p <- ggplot(tab, aes(x = due_status, y = n, fill = due_status)) +
      geom_col(width = 0.55, show.legend = FALSE) +
      geom_text(aes(label = scales::label_comma()(n)), vjust = -0.3, color = "#f0f0f5") +
      scale_fill_manual(values = colors) +
      labs(x = NULL, y = "Count") +
      theme_cybershield() +
      theme(axis.text.x = element_text(angle = 15, hjust = 1))
    ggplotly_cs(p, tooltip = c("x", "y"))
  })
  
  output$recent_table <- renderDT({
    d <- filtered_df() |> arrange(desc(date_added)) |> head(10) |>
      transmute(
        `CVE ID` = cve_id,
        Vendor = vendor_project,
        Product = product,
        Name = vulnerability_name,
        `Date Added` = format(date_added, "%Y-%m-%d"),
        `Ransomware` = as.character(known_ransomware_campaign_use)
      )
    datatable(d, options = dt_options_cybershield(10), rownames = FALSE,
              class = "compact stripe hover") |>
      formatStyle("Ransomware",
        backgroundColor = styleEqual("Yes", "rgba(239,68,68,0.15)"),
        color = styleEqual("Yes", "#ef4444"))
  })
  
  output$yearly_plot <- renderPlotly({
    d <- filtered_df()
    yearly <- d |> count(added_year, name = "n") |> arrange(added_year)
    if (nrow(yearly) == 0) return(plotly_empty())
    p <- ggplot(yearly, aes(x = factor(added_year), y = n)) +
      geom_col(fill = "#4d7cfe", alpha = 0.9, width = 0.65) +
      geom_text(aes(label = scales::label_comma()(n)), vjust = -0.3, color = "#f0f0f5") +
      labs(x = "Year", y = "Count") +
      scale_y_continuous(labels = scales::label_comma()) +
      theme_cybershield()
    ggplotly_cs(p, tooltip = c("x", "y"))
  })
  
  output$yoy_plot <- renderPlotly({
    d <- filtered_df()
    yearly <- d |> count(added_year, name = "n") |> arrange(added_year) |>
      mutate(yoy = (n - lag(n)) / lag(n) * 100) |> filter(!is.na(yoy))
    if (nrow(yearly) == 0) return(plotly_empty("Not enough data"))
    p <- ggplot(yearly, aes(x = factor(added_year), y = yoy, fill = yoy > 0)) +
      geom_col(width = 0.6) +
      geom_hline(yintercept = 0, color = "#1e1e2e", linewidth = 0.5) +
      scale_fill_manual(values = c("TRUE"="#ef4444", "FALSE"="#10b981"), guide = "none") +
      labs(x = "Year", y = "YoY Change (%)") +
      theme_cybershield()
    ggplotly_cs(p, tooltip = c("x", "y"))
  })
  
  output$period_summary <- renderPrint({
    d <- filtered_df()
    cat("Selected Period: ", format(input$date_range[1]), " to ", format(input$date_range[2]), "\n\n")
    cat("Total:", fmt_num(nrow(d)), "\n")
    cat("Vendors:", n_distinct(d$vendor_project), "\n")
    cat("Products:", n_distinct(d$product), "\n")
    cat("Ransomware:", sum(d$known_ransomware_campaign_use == "Yes", na.rm=TRUE), "\n")
    cat("Overdue:", sum(d$due_status == "Overdue", na.rm=TRUE), "\n")
  })
  
  output$overdue_table <- renderDT({
    d <- filtered_df() |> filter(due_status == "Overdue") |> arrange(due_date) |> head(20) |>
      transmute(
        `CVE ID` = cve_id, Vendor = vendor_project, Product = product,
        `Due Date` = format(due_date, "%Y-%m-%d"),
        `Days Overdue` = abs(days_to_due),
        `Ransomware` = as.character(known_ransomware_campaign_use))
    if (nrow(d) == 0) d <- data.frame(Message = "No overdue vulnerabilities.")
    datatable(d, options = dt_options_cybershield(10), rownames = FALSE, class = "compact stripe hover")
  })
  
  # ── Explorer ─────────────────────────────────────────────────────────────────
  explorer_df <- reactive({
    d <- filtered_df()
    q <- input$search_box
    if (!is.null(q) && nchar(q) > 0) {
      d <- d |> filter(
        grepl(q, cve_id, ignore.case=TRUE) |
        grepl(q, vendor_project, ignore.case=TRUE) |
        grepl(q, product, ignore.case=TRUE) |
        grepl(q, vulnerability_name, ignore.case=TRUE))
    }
    d
  })
  
  output$explorer_table <- renderDT({
    d <- explorer_df() |>
      transmute(
        `CVE ID` = cve_id, Vendor = vendor_project, Product = product,
        `Vuln Name` = vulnerability_name,
        `Date Added` = format(date_added, "%Y-%m-%d"),
        `Due Date` = ifelse(is.na(due_date), "—", format(due_date, "%Y-%m-%d")),
        `Ransomware` = as.character(known_ransomware_campaign_use),
        `Due Status` = as.character(due_status),
        Description = short_description)
    datatable(d, options = dt_options_cybershield(15), rownames = FALSE,
              class = "compact stripe hover") |>
      formatStyle("Ransomware",
        backgroundColor = styleEqual("Yes", "rgba(239,68,68,0.15)"),
        color = styleEqual("Yes", "#ef4444")) |>
      formatStyle("Due Status",
        backgroundColor = styleEqual("Overdue", "rgba(239,68,68,0.15)"),
        color = styleEqual("Overdue", "#ef4444"))
  })
  
  output$download_csv <- downloadHandler(
    filename = function() paste0("cybershield_export_", Sys.Date(), ".csv"),
    content = function(file) {
      explorer_df() |>
        select(cve_id, vendor_project, product, vulnerability_name,
               date_added, short_description, required_action, due_date,
               known_ransomware_campaign_use, forensic_triage, notes, cwes) |>
        write_csv(file)
    }, contentType = "text/csv"
  )
  
  # ── Gallery visualizations ───────────────────────────────────────────────────
  
  output$viz_heatmap <- renderPlotly({
    d <- filtered_df()
    top_v <- d |> count(vendor_project, sort=TRUE) |> head(12) |> pull(vendor_project)
    hm <- d |> filter(vendor_project %in% top_v) |> count(vendor_project, added_year, name="n")
    if (nrow(hm) == 0) return(plotly_empty())
    p <- ggplot(hm, aes(x = factor(added_year), y = reorder(vendor_project, n), fill = n)) +
      geom_tile(color = "#0a0a0f", linewidth = 0.5) +
      geom_text(aes(label = ifelse(n > 0, n, "")), color = "#f0f0f5", size = 3) +
      scale_fill_gradient(low = "#12121a", high = "#4d7cfe", name = "Count") +
      labs(x = "Year", y = NULL) +
      theme_cybershield() +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
    ggplotly_cs(p, tooltip = c("x", "y", "fill"))
  })
  
  output$viz_donut <- renderPlotly({
    d <- filtered_df()
    tab <- d |> count(known_ransomware_campaign_use, name="n") |>
      mutate(pct = round(n / sum(n) * 100, 1))
    colors <- c("Yes"="#ef4444", "No"="#10b981", "Unknown"="#4a4a5e")
    plot_ly(tab, labels = ~known_ransomware_campaign_use, values = ~n,
            type = "pie", hole = 0.6,
            marker = list(colors = unname(colors[as.character(tab$known_ransomware_campaign_use)]),
                          line = list(color = "#0a0a0f", width = 2)),
            textinfo = "label+percent", textfont = list(color = "#f0f0f5", size = 12),
            hoverinfo = "label+value+percent",
            hoverlabel = list(bgcolor = "#12121a", font = list(color = "#f0f0f5"))) |>
      layout(plot_bgcolor = "#12121a", paper_bgcolor = "#12121a",
             font = list(color = "#f0f0f5", family = "Inter"),
             margin = list(l=20,r=20,t=20,b=20),
             showlegend = TRUE, legend = list(bgcolor = "#12121a", font = list(color = "#f0f0f5"))) |>
      config(displayModeBar = FALSE)
  })
  
  output$viz_lollipop <- renderPlotly({
    d <- filtered_df()
    top <- d |> count(product, sort=TRUE) |> head(15) |>
      mutate(product = factor(product, levels = rev(product)))
    if (nrow(top) == 0) return(plotly_empty())
    p <- ggplot(top, aes(x = n, y = product)) +
      geom_segment(aes(x = 0, xend = n, y = product, yend = product), color = "#1e1e2e", linewidth = 0.8) +
      geom_point(aes(color = n), size = 5) +
      scale_color_gradient(low = "#4d7cfe", high = "#06b6d4", guide = "none") +
      labs(x = "Count", y = NULL) +
      theme_cybershield() +
      theme(panel.grid.major.y = element_blank())
    ggplotly_cs(p, tooltip = c("y", "x"))
  })
  
  output$viz_treemap <- renderPlotly({
    d <- filtered_df()
    top <- d |> count(vendor_project, sort=TRUE) |> head(25)
    if (nrow(top) == 0) return(plotly_empty())
    plot_ly(top, labels = ~vendor_project, parents = "", values = ~n,
            type = "treemap", textinfo = "label+value+percent root",
            marker = list(colors = scales::col_numeric("Blues", domain = range(top$n))(top$n),
                          line = list(color = "#0a0a0f", width = 1)),
            textfont = list(color = "#f0f0f5")) |>
      layout(paper_bgcolor = "#12121a", margin = list(l=0,r=0,t=20,b=0)) |>
      config(displayModeBar = FALSE)
  })
  
  output$viz_histogram <- renderPlotly({
    d <- filtered_df()
    if (nrow(d) == 0) return(plotly_empty())
    p <- ggplot(d, aes(x = cve_year, fill = after_stat(cut(x, c(-Inf,2020,2022,2024,Inf))))) +
      geom_histogram(binwidth = 1, color = "#0a0a0f", linewidth = 0.5, show.legend = FALSE) +
      scale_fill_manual(values = c("#4a4a5e", "#4d7cfe", "#06b6d4", "#10b981")) +
      labs(x = "CVE Year", y = "Frequency") +
      scale_y_continuous(labels = scales::label_comma()) +
      theme_cybershield()
    ggplotly_cs(p, tooltip = c("x", "y"))
  })
  
  output$viz_boxplot <- renderPlotly({
    d <- filtered_df() |>
      mutate(remediation_window = as.numeric(due_date - date_added)) |>
      filter(!is.na(remediation_window), remediation_window >= 0, remediation_window <= 90)
    if (nrow(d) == 0) return(plotly_empty())
    p <- ggplot(d, aes(x = factor(added_year), y = remediation_window, fill = factor(added_year))) +
      geom_boxplot(alpha = 0.8, outlier.color = "#ef4444", outlier.size = 1.5) +
      scale_fill_brewer(palette = "Blues", guide = "none") +
      labs(x = "Year", y = "Days (catalog → due)") +
      theme_cybershield()
    ggplotly_cs(p, tooltip = c("x", "y"))
  })
  
  output$viz_density <- renderPlotly({
    d <- filtered_df()
    monthly <- d |> count(added_ym, name="vuln_count") |> mutate(year = year(added_ym))
    if (nrow(monthly) < 2) return(plotly_empty("Insufficient data"))
    p <- ggplot(monthly, aes(x = vuln_count, fill = factor(year))) +
      geom_density(alpha = 0.5, color = NA) +
      scale_fill_viridis_d(option = "plasma", end = 0.8, name = "Year") +
      labs(x = "Monthly Count", y = "Density") +
      theme_cybershield() +
      theme(legend.position = "bottom")
    ggplotly_cs(p, tooltip = c("x", "y", "fill"))
  })
  
  output$viz_stacked_area <- renderPlotly({
    d <- filtered_df()
    stacked <- d |> count(added_ym, known_ransomware_campaign_use, name="n")
    if (nrow(stacked) == 0) return(plotly_empty())
    p <- ggplot(stacked, aes(x = added_ym, y = n, fill = known_ransomware_campaign_use)) +
      geom_area(alpha = 0.85, color = NA) +
      scale_fill_manual(values = c("Yes"="#ef4444", "No"="#10b981", "Unknown"="#4a4a5e"), name = "Ransomware") +
      labs(x = NULL, y = "Count") +
      scale_x_date(date_labels = "%b %Y", date_breaks = "4 months") +
      theme_cybershield() +
      theme(legend.position = "bottom")
    ggplotly_cs(p, tooltip = c("x", "y", "fill"))
  })
  
  output$viz_scatter <- renderPlotly({
    d <- filtered_df() |>
      mutate(days_to_due = as.numeric(due_date - date_added)) |>
      filter(!is.na(days_to_due), days_to_due >= 0, days_to_due <= 90)
    if (nrow(d) == 0) return(plotly_empty())
    p <- ggplot(d, aes(x = date_added, y = days_to_due, color = known_ransomware_campaign_use)) +
      geom_point(alpha = 0.4, size = 1.5) +
      geom_hline(yintercept = 14, linetype = "dashed", color = "#f59e0b", linewidth = 0.7) +
      scale_color_manual(values = c("Yes"="#ef4444", "No"="#10b981", "Unknown"="#4a4a5e"), name = "Ransomware") +
      labs(x = "Date Added", y = "Days Until Due") +
      scale_x_date(date_labels = "%b %Y", date_breaks = "6 months") +
      theme_cybershield() +
      theme(legend.position = "bottom")
    ggplotly_cs(p, tooltip = c("x", "y", "color"))
  })
  
  output$viz_polar <- renderPlotly({
    d <- filtered_df()
    wd <- d |> mutate(wday = wday(date_added, label = TRUE)) |> count(wday, name="n")
    if (nrow(wd) == 0) return(plotly_empty())
    plot_ly(wd, labels = ~wday, values = ~n,
            type = "barpolar", direction = "clockwise",
            marker = list(colors = scales::col_numeric("Blues", domain = range(wd$n))(wd$n),
                          line = list(color = "#0a0a0f", width = 1)),
            hoverinfo = "label+value",
            hoverlabel = list(bgcolor = "#12121a", font = list(color = "#f0f0f5"))) |>
      layout(plot_bgcolor = "#12121a", paper_bgcolor = "#12121a",
             font = list(color = "#f0f0f5", family = "Inter"),
             polar = list(bgcolor = "#12121a",
               radialaxis = list(visible = TRUE, color = "#1e1e2e", gridcolor = "#1e1e2e"),
               angularaxis = list(color = "#f0f0f5")),
             margin = list(l=40,r=40,t=20,b=20)) |>
      config(displayModeBar = FALSE)
  })
  
  output$viz_waffle <- renderPlotly({
    d <- filtered_df()
    triage <- d |> count(forensic_triage, name="n") |>
      mutate(pct = round(n / sum(n) * 100, 0))
    if (nrow(triage) == 0) return(plotly_empty())
    waffle_data <- purrr::map_dfr(1:nrow(triage), function(i) {
      sq <- seq_len(triage$pct[i])
      if (length(sq) == 0) return(NULL)
      tibble(id = 1:100, col = (id-1) %% 10, row = (id-1) %/% 10, category = NA_character_)[sq, ] |>
        mutate(category = triage$forensic_triage[i])
    })
    colors <- c("Yes" = "#f59e0b", "No" = "#10b981", "Unknown" = "#4a4a5e")
    p <- ggplot(waffle_data, aes(x = col, y = row, fill = category)) +
      geom_tile(color = "#0a0a0f", linewidth = 1, width = 0.9, height = 0.9) +
      scale_fill_manual(values = colors, name = "Forensic Triage") +
      coord_fixed() +
      labs(x = NULL, y = NULL) +
      theme_cybershield() +
      theme(axis.text = element_blank(), axis.ticks = element_blank(),
            panel.grid = element_blank(), legend.position = "bottom")
    ggplotly_cs(p, tooltip = c("x", "y", "fill"))
  })
  
  output$viz_diverging <- renderPlotly({
    d <- filtered_df()
    top_v <- d |> count(vendor_project, sort=TRUE) |> head(15) |> pull(vendor_project)
    vrisk <- d |> filter(vendor_project %in% top_v) |>
      group_by(vendor_project) |>
      summarise(ransom_pct = mean(known_ransomware_campaign_use == "Yes", na.rm=TRUE) * 100,
                .groups = "drop") |>
      mutate(dev = ransom_pct - 50, label_col = ifelse(dev > 0, "Above 50%", "Below 50%")) |>
      arrange(dev)
    if (nrow(vrisk) == 0) return(plotly_empty())
    p <- ggplot(vrisk, aes(x = dev, y = reorder(vendor_project, dev), fill = label_col)) +
      geom_col(width = 0.7, show.legend = FALSE) +
      geom_vline(xintercept = 0, color = "#f0f0f5", linewidth = 0.5) +
      scale_fill_manual(values = c("Above 50%" = "#ef4444", "Below 50%" = "#10b981")) +
      labs(x = "Ransomware Deviation from 50%", y = NULL) +
      theme_cybershield() +
      theme(panel.grid.major.y = element_blank())
    ggplotly_cs(p, tooltip = c("y", "x"))
  })
  
  output$viz_slope <- renderPlotly({
    d <- filtered_df() |> filter(!is.na(added_year), added_year >= 2022) |>
      group_by(added_year) |>
      summarise(ransom_share = mean(known_ransomware_campaign_use == "Yes", na.rm=TRUE) * 100,
                .groups = "drop") |>
      mutate(year_lag = lag(added_year), share_lag = lag(ransom_share)) |>
      filter(!is.na(share_lag))
    if (nrow(d) == 0) return(plotly_empty())
    p <- ggplot(d, aes(group = added_year)) +
      geom_segment(aes(x = year_lag, xend = added_year, y = share_lag, yend = ransom_share),
                   color = "#4d7cfe", linewidth = 1.2) +
      geom_point(aes(x = year_lag, y = share_lag), color = "#06b6d4", size = 4) +
      geom_point(aes(x = added_year, y = ransom_share), color = "#ef4444", size = 4) +
      geom_text(aes(x = year_lag, y = share_lag, label = paste0(round(share_lag,1),"%")),
                vjust = -1, color = "#6b6b80", size = 3) +
      geom_text(aes(x = added_year, y = ransom_share, label = paste0(round(ransom_share,1),"%")),
                vjust = -1, color = "#ef4444", size = 3) +
      scale_x_continuous(breaks = unique(c(d$year_lag, d$added_year))) +
      labs(x = "Year", y = "Ransomware Share (%)") +
      theme_cybershield()
    ggplotly_cs(p, tooltip = c("x", "y"))
  })
  
  output$viz_cwe <- renderPlotly({
    d <- filtered_df()
    cwe <- d |> filter(!is.na(primary_cwe), primary_cwe != "N/A", primary_cwe != "") |>
      count(primary_cwe, sort=TRUE) |> head(12) |>
      mutate(primary_cwe = factor(primary_cwe, levels = rev(primary_cwe)))
    if (nrow(cwe) == 0) return(plotly_empty("No CWE data"))
    p <- ggplot(cwe, aes(x = n, y = primary_cwe, fill = n)) +
      geom_col(width = 0.7, show.legend = FALSE) +
      scale_fill_gradient(low = "#06b6d4", high = "#ef4444") +
      labs(x = "Count", y = "CWE") +
      theme_cybershield() +
      theme(panel.grid.major.y = element_blank())
    ggplotly_cs(p, tooltip = c("y", "x"))
  })
  
  # ── NEW CHARTS ───────────────────────────────────────────────────────────────
  
  # 15. Bubble — Vendor Scale × Ransomware
  output$viz_bubble <- renderPlotly({
    d <- filtered_df()
    vb <- d |> group_by(vendor_project) |>
      summarise(
        total = n(),
        ransom = sum(known_ransomware_campaign_use == "Yes", na.rm=TRUE),
        ransom_pct = ifelse(total > 0, ransom / total * 100, 0),
        products = n_distinct(product),
        .groups = "drop"
      ) |>
      filter(total >= 3) |>
      arrange(desc(total)) |>
      head(20)
    if (nrow(vb) == 0) return(plotly_empty())
    
    p <- ggplot(vb, aes(x = total, y = ransom_pct, size = products,
                        color = ransom_pct, text = vendor_project)) +
      geom_point(alpha = 0.7) +
      scale_size_continuous(range = c(4, 18)) +
      scale_color_gradient(low = "#10b981", high = "#ef4444", name = "Ransomware %") +
      labs(x = "Total Vulnerabilities", y = "Ransomware Share (%)",
           size = "Products", color = "Ransomware %") +
      theme_cybershield() +
      theme(legend.position = "right")
    ggplotly_cs(p, tooltip = "text")
  })
  
  # 16. Violin — Remediation Window by Year
  output$viz_violin <- renderPlotly({
    d <- filtered_df() |>
      mutate(rw = as.numeric(due_date - date_added)) |>
      filter(!is.na(rw), rw >= 0, rw <= 90, added_year >= 2022)
    if (nrow(d) == 0) return(plotly_empty())
    p <- ggplot(d, aes(x = factor(added_year), y = rw, fill = factor(added_year))) +
      geom_violin(alpha = 0.7, trim = TRUE) +
      geom_boxplot(width = 0.15, fill = "#0a0a0f", outlier.color = "#ef4444", outlier.size = 1) +
      scale_fill_brewer(palette = "Dark2", guide = "none") +
      labs(x = "Year", y = "Days (catalog → due)") +
      theme_cybershield()
    ggplotly_cs(p, tooltip = c("x", "y"))
  })
  
  # 17. Sunburst — Vendor → Product
  output$viz_sunburst <- renderPlotly({
    d <- filtered_df()
    vp <- d |>
      count(vendor_project, product, name = "n") |>
      arrange(desc(n)) |>
      head(60)
    if (nrow(vp) == 0) return(plotly_empty())
    
    # Build hierarchy: root → vendors → products
    vendors <- vp |>
      group_by(vendor_project) |>
      summarise(total = sum(n), .groups = "drop") |>
      arrange(desc(total))
    
    labels <- c("All", vendors$vendor_project, vp$product)
    parents <- c("", rep("All", nrow(vendors)), vp$vendor_project)
    values <- c(sum(vendors$total), vendors$total, vp$n)
    
    plot_ly(labels = labels, parents = parents, values = values,
            type = "sunburst", branchvalues = "total",
            marker = list(
              colors = scales::col_numeric("Blues", domain = range(values[-1]))(values[-1]),
              line = list(color = "#0a0a0f", width = 1)
            ),
            textinfo = "label+value",
            textfont = list(color = "#f0f0f5", size = 10),
            hoverlabel = list(bgcolor = "#12121a", font = list(color = "#f0f0f5"))) |>
      layout(paper_bgcolor = "#12121a", margin = list(l=0,r=0,t=20,b=0)) |>
      config(displayModeBar = FALSE)
  })
  
  # 18. Funnel — Due Date Pipeline
  output$viz_funnel <- renderPlotly({
    d <- filtered_df()
    stages <- d |>
      summarise(
        `Total Catalog` = n(),
        `With Due Date` = sum(!is.na(due_date)),
        `Upcoming or Due` = sum(due_status %in% c("Upcoming", "Due Today"), na.rm=TRUE),
        `Overdue` = sum(due_status == "Overdue", na.rm=TRUE),
        `Ransomware + Overdue` = sum(due_status == "Overdue" & known_ransomware_campaign_use == "Yes", na.rm=TRUE)
      ) |>
      tidyr::pivot_longer(everything(), names_to = "stage", values_to = "count") |>
      mutate(stage = factor(stage, levels = rev(stage)))
    
    if (nrow(stages) == 0) return(plotly_empty())
    
    colors <- c("#4d7cfe", "#8b5cf6", "#06b6d4", "#f59e0b", "#ef4444")
    
    plot_ly(stages, y = ~stage, x = ~count, type = "funnel",
            marker = list(colors = rev(colors[1:nrow(stages)]),
                          line = list(color = "#0a0a0f", width = 1)),
            textinfo = "value+percent initial",
            textfont = list(color = "#f0f0f5", size = 12),
            hoverlabel = list(bgcolor = "#12121a", font = list(color = "#f0f0f5"))) |>
      layout(paper_bgcolor = "#12121a", plot_bgcolor = "#12121a",
             font = list(color = "#f0f0f5", family = "Inter"),
             margin = list(l=20,r=20,t=20,b=20)) |>
      config(displayModeBar = FALSE)
  })
  
  # 19. Calendar Heatmap — Daily Additions
  output$viz_calendar <- renderPlotly({
    d <- filtered_df() |> filter(!is.na(date_added))
    if (nrow(d) == 0) return(plotly_empty())
    
    daily <- d |> count(date_added, name = "n")
    daily <- daily |>
      mutate(
        year = year(date_added),
        week = isoweek(date_added),
        wday = wday(date_added, week_start = 1)
      )
    
    p <- ggplot(daily, aes(x = week, y = wday, fill = n)) +
      geom_tile(color = "#0a0a0f", linewidth = 0.5, width = 1, height = 1) +
      scale_fill_gradient(low = "#12121a", high = "#4d7cfe", name = "Count") +
      labs(x = "Week of Year", y = "Day of Week") +
      scale_y_continuous(breaks = 1:7, labels = c("Mon","Tue","Wed","Thu","Fri","Sat","Sun")) +
      theme_cybershield() +
      theme(panel.grid = element_blank())
    ggplotly_cs(p, tooltip = c("x", "y", "fill"))
  })
  
  # 20. Parallel Categories — Vendor / Year / Ransomware
  output$viz_parcats <- renderPlotly({
    d <- filtered_df() |>
      filter(!is.na(added_year)) |>
      mutate(year = factor(added_year)) |>
      head(500)
    if (nrow(d) == 0) return(plotly_empty())
    
    plot_ly(d, type = "parcoords",
            dimensions = list(
              list(label = "Vendor", values = as.numeric(factor(d$vendor_project))),
              list(label = "Year", values = as.numeric(d$added_year)),
              list(label = "Ransomware", values = as.numeric(d$known_ransomware_campaign_use)),
              list(label = "Days to Due", values = d$days_to_due %||% 0)
            ),
            line = list(
              color = as.numeric(d$known_ransomware_campaign_use),
              colorscale = list(c(0, "#10b981"), c(0.5, "#4d7cfe"), c(1, "#ef4444")),
              showscale = TRUE,
              colorbar = list(title = "Risk", tickfont = list(color = "#f0f0f5"))
            ),
            labelfont = list(color = "#f0f0f5", size = 10),
            tickfont = list(color = "#6b6b80", size = 9),
            line = list(
              color = as.numeric(d$known_ransomware_campaign_use),
              colorscale = list(c(0, "#10b981"), c(1, "#ef4444")),
              showscale = TRUE
            )) |>
      layout(paper_bgcolor = "#12121a", plot_bgcolor = "#12121a",
             font = list(color = "#f0f0f5", family = "Inter"),
             margin = list(l=60,r=60,t=30,b=30)) |>
      config(displayModeBar = FALSE)
  })
  
  # 21. Indicator Cards — Key Metrics
  output$viz_indicators <- renderPlotly({
    d <- filtered_df()
    total <- nrow(d)
    ransom <- sum(d$known_ransomware_campaign_use == "Yes", na.rm=TRUE)
    overdue <- sum(d$due_status == "Overdue", na.rm=TRUE)
    
    plot_ly() |>
      add_trace(type = "indicator", mode = "number+delta",
                value = total, number = list(font = list(color = "#4d7cfe", size = 36)),
                delta = list(reference = total * 0.9, font = list(color = "#10b981")),
                x = 0.15, y = 0.7) |>
      add_trace(type = "indicator", mode = "number",
                value = ransom, number = list(font = list(color = "#ef4444", size = 36)),
                x = 0.5, y = 0.7) |>
      add_trace(type = "indicator", mode = "number",
                value = overdue, number = list(font = list(color = "#f59e0b", size = 36)),
                x = 0.85, y = 0.7) |>
      layout(paper_bgcolor = "#12121a", plot_bgcolor = "#12121a",
             font = list(color = "#f0f0f5", family = "Inter"),
             margin = list(l=20,r=20,t=20,b=20),
             annotations = list(
               list(x = 0.15, y = 0.2, text = "Total", showarrow = FALSE, font = list(color = "#6b6b80", size = 12)),
               list(x = 0.5, y = 0.2, text = "Ransomware", showarrow = FALSE, font = list(color = "#6b6b80", size = 12)),
               list(x = 0.85, y = 0.2, text = "Overdue", showarrow = FALSE, font = list(color = "#6b6b80", size = 12))
             )) |>
      config(displayModeBar = FALSE)
  })
  
  # 22. Waterfall — Monthly Change
  output$viz_waterfall <- renderPlotly({
    d <- filtered_df()
    monthly <- d |> count(added_ym, name = "vuln_count") |> arrange(added_ym) |>
      tail(12)
    if (nrow(monthly) < 2) return(plotly_empty("Need at least 2 months"))
    
    monthly <- monthly |>
      mutate(
        change = vuln_count - lag(vuln_count),
        measure = ifelse(is.na(change), "absolute", ifelse(change >= 0, "relative", "relative")),
        base = ifelse(is.na(change), 0, lag(vuln_count)),
        text = paste0(format(added_ym, "%b %Y"), ": ", vuln_count)
      ) |>
      filter(!is.na(change))
    
    if (nrow(monthly) == 0) return(plotly_empty())
    
    plot_ly(monthly, x = ~format(added_ym, "%b %y"),
            y = ~change, type = "waterfall",
            measure = ~measure,
            increasing = list(marker = list(color = "#ef4444")),
            decreasing = list(marker = list(color = "#10b981")),
            totals = list(marker = list(color = "#4d7cfe")),
            text = ~text,
            textposition = "outside",
            textfont = list(color = "#f0f0f5", size = 10),
            hoverlabel = list(bgcolor = "#12121a", font = list(color = "#f0f0f5"))) |>
      layout(paper_bgcolor = "#12121a", plot_bgcolor = "#12121a",
             font = list(color = "#f0f0f5", family = "Inter"),
             margin = list(l=60,r=20,t=30,b=50),
             yaxis = list(gridcolor = "#1e1e2e", zerolinecolor = "#1e1e2e"),
             xaxis = list(tickfont = list(color = "#6b6b80"))) |>
      config(displayModeBar = FALSE)
  })
  
  # 23. Radar — Vendor Comparison
  output$viz_radar <- renderPlotly({
    d <- filtered_df()
    top_v <- d |> count(vendor_project, sort=TRUE) |> head(5) |> pull(vendor_project)
    
    radar_data <- d |> filter(vendor_project %in% top_v) |>
      group_by(vendor_project) |>
      summarise(
        total = n(),
        ransom_pct = mean(known_ransomware_campaign_use == "Yes", na.rm=TRUE) * 100,
        overdue_pct = mean(due_status == "Overdue", na.rm=TRUE) * 100,
        triage_pct = mean(forensic_triage == "Yes", na.rm=TRUE) * 100,
        products = n_distinct(product),
        .groups = "drop"
      )
    
    if (nrow(radar_data) == 0) return(plotly_empty())
    
    colors <- c("#4d7cfe", "#ef4444", "#10b981", "#f59e0b", "#8b5cf6")
    
    p <- plot_ly(type = "scatterpolar", mode = "lines+markers", fill = "toself")
    for (i in 1:nrow(radar_data)) {
      row <- radar_data[i, ]
      p <- p |>
        add_trace(
          r = c(row$total/max(radar_data$total)*100,
                row$ransom_pct, row$overdue_pct, row$triage_pct,
                row$products/max(radar_data$products)*100,
                row$total/max(radar_data$total)*100),
          theta = c("Total", "Ransomware %", "Overdue %", "Triage %", "Products", "Total"),
          name = row$vendor_project,
          line = list(color = colors[i]),
          fillcolor = paste0(colors[i], "20"),
          marker = list(color = colors[i])
        )
    }
    p |>
      layout(paper_bgcolor = "#12121a", plot_bgcolor = "#12121a",
             font = list(color = "#f0f0f5", family = "Inter"),
             polar = list(bgcolor = "#12121a",
               radialaxis = list(visible = TRUE, color = "#1e1e2e", gridcolor = "#1e1e2e"),
               angularaxis = list(color = "#f0f0f5")),
             legend = list(bgcolor = "#12121a", font = list(color = "#f0f0f5")),
             margin = list(l=60,r=60,t=30,b=30)) |>
      config(displayModeBar = FALSE)
  })
  
  # 24. Word Frequency — Vulnerability Types
  output$viz_wordfreq <- renderPlotly({
    d <- filtered_df()
    # Extract vulnerability type keywords from vulnerability_name
    words <- d$vulnerability_name |>
      tolower() |>
      str_extract_all("\\b(vulnerability|injection|overflow|bypass|traversal|spoofing|forgery|disclosure|escalation|execution|tampering|denial|authentication|authorization|memory|buffer|code|path|remote|local|privilege|ssrf|xss|csrf|rce|dos)\\b") |>
      unlist()
    
    if (length(words) == 0) return(plotly_empty("No vulnerability type data"))
    
    wf <- tibble(word = words) |> count(word, sort=TRUE) |> head(15) |>
      mutate(word = factor(word, levels = rev(word)))
    
    p <- ggplot(wf, aes(x = n, y = word, fill = n)) +
      geom_col(width = 0.7, show.legend = FALSE) +
      geom_text(aes(label = n), hjust = -0.2, color = "#f0f0f5", size = 3.5) +
      scale_fill_gradient(low = "#8b5cf6", high = "#ec4899") +
      labs(x = "Frequency", y = NULL) +
      theme_cybershield() +
      theme(panel.grid.major.y = element_blank())
    ggplotly_cs(p, tooltip = c("y", "x"))
  })
}

# Read PORT from environment (for Render deployment)
port <- as.integer(Sys.getenv("PORT", "8888"))

shinyApp(ui, server, options = list(port = port, host = "0.0.0.0"))
