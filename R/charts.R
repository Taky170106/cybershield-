# CyberShield Charts Module
# All visualization functions for the dashboard

library(ggplot2)
library(plotly)
library(dplyr)
library(scales)

# CyberShield color palette
CS_COLORS <- list(
  bg_dark = "#0a0a0f",
  bg_panel = "#12121a",
  bg_card = "#16161f",
  border = "#1e1e2e",
  text_primary = "#f0f0f5",
  text_secondary = "#6b6b80",
  accent_blue = "#4d7cfe",
  accent_cyan = "#06b6d4",
  accent_green = "#10b981",
  warning_amber = "#f59e0b",
  danger_red = "#ef4444",
  ransomware_yes = "#ef4444",
  ransomware_no = "#10b981",
  ransomware_unknown = "#4a4a5e",
  due_overdue = "#ef4444",
  due_today = "#f59e0b",
  due_upcoming = "#4d7cfe",
  due_unknown = "#4a4a5e"
)

#' Custom ggplot theme for CyberShield
theme_cybershield <- function(base_size = 12) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      plot.background = element_rect(fill = CS_COLORS$bg_panel, color = NA),
      panel.background = element_rect(fill = CS_COLORS$bg_panel, color = NA),
      panel.border = element_rect(fill = NA, color = CS_COLORS$border, linewidth = 0.5),
      panel.grid.major = element_line(color = CS_COLORS$border, linewidth = 0.3),
      panel.grid.minor = element_line(color = CS_COLORS$border, linewidth = 0.2),
      panel.grid.minor.x = element_blank(),
      text = element_text(color = CS_COLORS$text_primary, family = "Inter"),
      plot.title = element_text(size = rel(1.3), face = "bold", color = CS_COLORS$text_primary),
      plot.subtitle = element_text(size = rel(1.0), color = CS_COLORS$text_secondary),
      plot.caption = element_text(size = rel(0.8), color = CS_COLORS$text_secondary),
      axis.text = element_text(color = CS_COLORS$text_secondary, size = rel(0.9)),
      axis.title = element_text(color = CS_COLORS$text_primary, size = rel(1.0)),
      axis.line = element_line(color = CS_COLORS$border, linewidth = 0.5),
      axis.ticks = element_line(color = CS_COLORS$border, linewidth = 0.5),
      legend.background = element_rect(fill = CS_COLORS$bg_panel, color = NA),
      legend.key = element_rect(fill = CS_COLORS$bg_panel, color = NA),
      legend.text = element_text(color = CS_COLORS$text_primary),
      legend.title = element_text(color = CS_COLORS$text_primary),
      strip.background = element_rect(fill = CS_COLORS$bg_card, color = CS_COLORS$border),
      strip.text = element_text(color = CS_COLORS$text_primary, face = "bold"),
      plot.margin = margin(10, 15, 10, 10)
    )
}

#' Convert ggplot to plotly with consistent styling
ggplotly_cs <- function(p, tooltip = "all", ...) {
  ggplotly(p, tooltip = tooltip, ...) |>
    layout(
      plot_bgcolor = CS_COLORS$bg_panel,
      paper_bgcolor = CS_COLORS$bg_panel,
      font = list(color = CS_COLORS$text_primary, family = "Inter"),
      margin = list(l = 60, r = 30, t = 40, b = 40),
      xaxis = list(
        gridcolor = CS_COLORS$border,
        zerolinecolor = CS_COLORS$border,
        linecolor = CS_COLORS$border,
        tickfont = list(color = CS_COLORS$text_secondary)
      ),
      yaxis = list(
        gridcolor = CS_COLORS$border,
        zerolinecolor = CS_COLORS$border,
        linecolor = CS_COLORS$border,
        tickfont = list(color = CS_COLORS$text_secondary)
      ),
      legend = list(
        bgcolor = CS_COLORS$bg_panel,
        bordercolor = CS_COLORS$border,
        font = list(color = CS_COLORS$text_primary)
      ),
      hoverlabel = list(
        bgcolor = CS_COLORS$bg_card,
        bordercolor = CS_COLORS$border,
        font = list(color = CS_COLORS$text_primary, family = "Inter")
      )
    ) |>
    config(displayModeBar = FALSE, responsive = TRUE)
}

#' KPI Card value box (returns HTML for bslib value_box)
#' @param value Numeric value
#' @param title Card title
#' @param subtitle Optional subtitle
#' @param icon Bootstrap icon name
#' @param theme Color theme
#' @return bslib value_box
kpi_card <- function(value, title, subtitle = NULL, icon = "shield-check", 
                     theme = "primary") {
  bslib::value_box(
    title = title,
    value = scales::label_comma()(value),
    showcase = bsicons::bs_icon(icon, size = "2rem"),
    theme = theme,
    p(class = "text-muted small", subtitle %||% "")
  )
}

#' Monthly vulnerability additions line chart
#' @param monthly_df Monthly summary from create_monthly_summary
#' @param show_rolling Whether to show rolling average
#' @param rolling_window Rolling window size
#' @return plotly object
plot_monthly_trend <- function(monthly_df, show_rolling = TRUE, rolling_window = 3) {
  p <- monthly_df |>
    ggplot(aes(x = added_ym, y = vuln_count)) +
    geom_line(color = CS_COLORS$accent_blue, linewidth = 1.2, alpha = 0.9) +
    geom_point(color = CS_COLORS$accent_blue, size = 2, alpha = 0.7) +
    labs(
      title = "Monthly Vulnerability Additions to CISA KEV Catalog",
      subtitle = "Count of vulnerabilities added to the catalog each month",
      x = "Month",
      y = "Vulnerabilities Added",
      caption = "Source: CISA Known Exploited Vulnerabilities Catalog"
    ) +
    scale_x_date(date_labels = "%b %Y", date_breaks = "3 months") +
    scale_y_continuous(labels = scales::label_comma()) +
    theme_cybershield()
  
  if (show_rolling && "rolling_avg" %in% names(monthly_df)) {
    p <- p + geom_line(aes(y = rolling_avg), color = CS_COLORS$accent_cyan, 
                       linewidth = 1, linetype = "dashed", alpha = 0.8)
  }
  
  ggplotly_cs(p, tooltip = c("x", "y"))
}

#' Top vendors bar chart
#' @param vendor_df Vendor summary from create_vendor_summary
#' @param top_n Number of vendors to show
#' @return plotly object
plot_top_vendors <- function(vendor_df, top_n = 10) {
  plot_data <- vendor_df |>
    slice_head(n = top_n) |>
    mutate(vendor_project = factor(vendor_project, levels = rev(vendor_project)))
  
  p <- plot_data |>
    ggplot(aes(x = vuln_count, y = vendor_project, fill = vuln_count)) +
    geom_col(width = 0.7, alpha = 0.9) +
    geom_text(aes(label = scales::label_comma()(vuln_count)), 
              hjust = -0.1, color = CS_COLORS$text_primary, size = 3.5) +
    scale_fill_gradient(low = CS_COLORS$accent_blue, high = CS_COLORS$accent_cyan, guide = "none") +
    labs(
      title = paste("Top", top_n, "Vendors by KEV Catalog Entries"),
      subtitle = "Number of vulnerabilities per vendor in the CISA KEV catalog",
      x = "Vulnerability Count",
      y = NULL,
      caption = "Higher count does not imply lower security; reflects product footprint and reporting"
    ) +
    theme_cybershield() +
    theme(
      panel.grid.major.y = element_blank(),
      axis.text.y = element_text(size = rel(0.95))
    )
  
  ggplotly_cs(p, tooltip = c("y", "x"))
}

#' Ransomware designation pie/donut chart
#' @param ransomware_df Ransomware summary from create_ransomware_summary
#' @return plotly object
plot_ransomware_distribution <- function(ransomware_df) {
  plot_data <- ransomware_df |>
    mutate(
      known_ransomware_campaign_use = factor(
        known_ransomware_campaign_use, 
        levels = c("Yes", "No", "Unknown")
      ),
      label = paste0(known_ransomware_campaign_use, ": ", count, " (", pct, "%)")
    )
  
  colors <- c(
    "Yes" = CS_COLORS$ransomware_yes,
    "No" = CS_COLORS$ransomware_no,
    "Unknown" = CS_COLORS$ransomware_unknown
  )
  
  p <- plot_data |>
    ggplot(aes(x = "", y = count, fill = known_ransomware_campaign_use)) +
    geom_col(width = 1, color = CS_COLORS$bg_dark, linewidth = 2) +
    coord_polar("y", start = 0) +
    scale_fill_manual(values = colors, name = "Ransomware Use") +
    labs(
      title = "Known Ransomware Campaign Use",
      subtitle = "Distribution of ransomware designation in KEV catalog",
      caption = "Source: CISA KEV Catalog - 'Known Ransomware Campaign Use' field"
    ) +
    theme_cybershield() +
    theme(
      axis.text = element_blank(),
      axis.title = element_blank(),
      panel.grid = element_blank(),
      legend.position = "right"
    )
  
  ggplotly_cs(p, tooltip = c("fill", "y"))
}

#' Remediation status stacked bar
#' @param remediation_df Remediation summary from create_remediation_summary
#' @return plotly object
plot_remediation_status <- function(remediation_df) {
  plot_data <- remediation_df |>
    mutate(
      due_status = factor(due_status, levels = c("Overdue", "Due Today", "Upcoming", "Unknown"))
    )
  
  colors <- c(
    "Overdue" = CS_COLORS$due_overdue,
    "Due Today" = CS_COLORS$due_today,
    "Upcoming" = CS_COLORS$due_upcoming,
    "Unknown" = CS_COLORS$due_unknown
  )
  
  p <- plot_data |>
    ggplot(aes(x = "", y = count, fill = due_status)) +
    geom_col(width = 0.5) +
    geom_text(aes(label = paste0(count, " (", pct, "%)")), 
              position = position_stack(vjust = 0.5), 
              color = "white", size = 4, fontface = "bold") +
    scale_fill_manual(values = colors, name = "Due Date Status") +
    labs(
      title = "Remediation Due Date Status",
      subtitle = "Categorization based on CISA catalog due dates vs. current date",
      caption = "Due dates from CISA catalog; does not confirm organizational patch status",
      x = NULL,
      y = "Count"
    ) +
    theme_cybershield() +
    theme(
      axis.text.x = element_blank(),
      legend.position = "right"
    )
  
  ggplotly_cs(p, tooltip = c("fill", "y"))
}

#' Yearly comparison chart
#' @param yearly_df Yearly summary from create_yearly_summary
#' @return plotly object
plot_yearly_comparison <- function(yearly_df) {
  p <- yearly_df |>
    ggplot(aes(x = factor(added_year), y = vuln_count)) +
    geom_col(fill = CS_COLORS$accent_blue, alpha = 0.9, width = 0.7) +
    geom_text(aes(label = scales::label_comma()(vuln_count)), 
              vjust = -0.3, color = CS_COLORS$text_primary, size = 3.5) +
    geom_line(aes(y = cumsum, group = 1), color = CS_COLORS$accent_cyan, 
              linewidth = 1, linetype = "dashed") +
    geom_point(aes(y = cumsum), color = CS_COLORS$accent_cyan, size = 2) +
    labs(
      title = "Yearly Vulnerability Additions (with Cumulative)",
      subtitle = "Bars: yearly count | Dashed line: cumulative total",
      x = "Year",
      y = "Vulnerabilities Added",
      caption = "Cumulative line shows total catalog growth over time"
    ) +
    scale_y_continuous(labels = scales::label_comma()) +
    theme_cybershield()
  
  ggplotly_cs(p, tooltip = c("x", "y"))
}

#' Vendor comparison chart (selected vendors)
#' @param clean_df Cleaned KEV data
#' @param vendors Vector of vendor names to compare
#' @return plotly object
plot_vendor_comparison <- function(clean_df, vendors) {
  if (length(vendors) == 0) {
    return(plotly_empty("Select vendors to compare"))
  }
  
  plot_data <- clean_df |>
    filter(vendor_project %in% vendors) |>
    count(vendor_project, added_ym, name = "count") |>
    complete(vendor_project, added_ym, fill = list(count = 0))
  
  p <- plot_data |>
    ggplot(aes(x = added_ym, y = count, color = vendor_project)) +
    geom_line(linewidth = 1.2, alpha = 0.9) +
    geom_point(size = 2, alpha = 0.7) +
    scale_color_brewer(palette = "Dark2") +
    labs(
      title = "Vendor Comparison: Monthly KEV Entries",
      subtitle = paste("Comparing", length(vendors), "selected vendors"),
      x = "Month",
      y = "Vulnerabilities Added",
      color = "Vendor"
    ) +
    scale_x_date(date_labels = "%b %Y", date_breaks = "3 months") +
    theme_cybershield() +
    theme(legend.position = "bottom")
  
  ggplotly_cs(p, tooltip = c("x", "y", "color"))
}

#' Product breakdown for a vendor
#' @param vendor_product_df Product summary from create_vendor_product_summary
#' @param top_n Top products to show
#' @return plotly object
plot_vendor_products <- function(vendor_product_df, top_n = 10) {
  plot_data <- vendor_product_df |>
    slice_head(n = top_n) |>
    mutate(product = factor(product, levels = rev(product)))
  
  p <- plot_data |>
    ggplot(aes(x = vuln_count, y = product)) +
    geom_col(fill = CS_COLORS$accent_blue, alpha = 0.9, width = 0.7) +
    geom_text(aes(label = vuln_count), hjust = -0.1, 
              color = CS_COLORS$text_primary, size = 3.5) +
    labs(
      title = "Top Products by Vulnerability Count",
      subtitle = "Product-level breakdown for selected vendor",
      x = "Vulnerability Count",
      y = NULL
    ) +
    theme_cybershield() +
    theme(panel.grid.major.y = element_blank())
  
  ggplotly_cs(p, tooltip = c("y", "x"))
}

#' Due date timeline chart
#' @param clean_df Cleaned KEV data
#' @return plotly object
plot_due_date_timeline <- function(clean_df) {
  due_data <- clean_df |>
    filter(!is.na(due_date)) |>
    mutate(
      due_status = factor(due_status, levels = c("Overdue", "Due Today", "Upcoming", "Unknown"))
    ) |>
    count(due_date, due_status, name = "count") |>
    arrange(due_date)
  
  if (nrow(due_data) == 0) {
    return(plotly_empty("No due dates available"))
  }
  
  colors <- c(
    "Overdue" = CS_COLORS$due_overdue,
    "Due Today" = CS_COLORS$due_today,
    "Upcoming" = CS_COLORS$due_upcoming,
    "Unknown" = CS_COLORS$due_unknown
  )
  
  p <- due_data |>
    ggplot(aes(x = due_date, y = count, fill = due_status)) +
    geom_col(position = "stack", width = 1) +
    scale_fill_manual(values = colors, name = "Status") +
    labs(
      title = "Remediation Due Dates Timeline",
      subtitle = "Stacked view of upcoming and overdue remediation deadlines",
      x = "Due Date",
      y = "Vulnerabilities Due",
      caption = "Based on CISA catalog due dates; not organizational patch status"
    ) +
    scale_x_date(date_labels = "%b %Y", date_breaks = "1 month") +
    theme_cybershield() +
    theme(legend.position = "bottom")
  
  ggplotly_cs(p, tooltip = c("x", "y", "fill"))
}

#' Empty plotly placeholder
plotly_empty <- function(message = "No data available") {
  plot_ly() |>
    add_annotations(
      text = message,
      x = 0.5, y = 0.5,
      xref = "paper", yref = "paper",
      showarrow = FALSE,
      font = list(color = CS_COLORS$text_secondary, size = 14)
    ) |>
    layout(
      plot_bgcolor = CS_COLORS$bg_panel,
      paper_bgcolor = CS_COLORS$bg_panel,
      xaxis = list(visible = FALSE),
      yaxis = list(visible = FALSE)
    ) |>
    config(displayModeBar = FALSE)
}

#' Year-over-year change chart
#' @param yoy_df YoY comparison from compute_yoy_comparison
#' @return plotly object
plot_yoy_change <- function(yoy_df) {
  plot_data <- yoy_df |>
    filter(!is.na(yoy_pct_change))
  
  if (nrow(plot_data) == 0) {
    return(plotly_empty("Insufficient data for YoY comparison"))
  }
  
  p <- plot_data |>
    ggplot(aes(x = factor(added_year), y = yoy_pct_change,
               fill = yoy_pct_change > 0)) +
    geom_col(width = 0.6, alpha = 0.9) +
    geom_hline(yintercept = 0, color = CS_COLORS$border, linewidth = 0.5) +
    geom_text(aes(label = paste0(ifelse(yoy_pct_change > 0, "+", ""), 
                                  round(yoy_pct_change, 1), "%")), 
              vjust = ifelse(plot_data$yoy_pct_change > 0, -0.3, 1.3),
              color = CS_COLORS$text_primary, size = 3.5) +
    scale_fill_manual(values = c("TRUE" = CS_COLORS$danger_red, "FALSE" = CS_COLORS$accent_green),
                      guide = "none") +
    labs(
      title = "Year-over-Year Change in KEV Additions",
      subtitle = "Percentage change in catalog additions vs. previous year",
      x = "Year",
      y = "YoY Change (%)",
      caption = "Positive = more additions than prior year"
    ) +
    theme_cybershield()
  
  ggplotly_cs(p, tooltip = c("x", "y"))
}