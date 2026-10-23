user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
.libPaths(c(user_lib, .libPaths()))
setwd("D:/new_ajay/CyberShield")

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(scales)
  library(lubridate)
})

dir.create("screenshots", showWarnings = FALSE)

source("R/charts.R")

# Load data
raw <- read_csv("data/known_exploited_vulnerabilities.csv", show_col_types = FALSE) |>
  janitor::clean_names()

df <- raw |>
  mutate(
    date_added = as.Date(date_added),
    due_date = as.Date(due_date),
    known_ransomware_campaign_use = case_when(
      tolower(known_ransomware_campaign_use) %in% c("known", "yes") ~ "Yes",
      tolower(known_ransomware_campaign_use) == "unknown" ~ "Unknown",
      TRUE ~ "Unknown"
    ),
    added_ym = floor_date(date_added, "month"),
    added_year = year(date_added)
  )

cat("=== Generating chart images ===\n")

# ── CHART 1: Proposed Visualization — Horizontal Bar with Dual Encoding ──────
top_vendors <- df |>
  count(vendor_project, name = "total") |>
  arrange(desc(total)) |>
  head(10) |>
  left_join(
    df |>
      group_by(vendor_project) |>
      summarise(ransom_pct = mean(known_ransomware_campaign_use == "Yes", na.rm=TRUE) * 100, .groups="drop"),
    by = "vendor_project"
  ) |>
  mutate(vendor_project = factor(vendor_project, levels = rev(vendor_project)))

p1 <- ggplot(top_vendors, aes(x = total, y = vendor_project, fill = ransom_pct)) +
  geom_col(width = 0.75) +
  geom_text(aes(label = total), hjust = -0.2, color = "#f0f0f5", size = 4, fontface = "bold") +
  scale_fill_gradient(low = "#4d7cfe", high = "#ef4444", name = "Ransomware %") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Top 10 Vendors by CISA KEV Catalog Entries",
    subtitle = "Bar length = total vulnerabilities | Color = ransomware proportion",
    x = "Vulnerability Count",
    y = NULL,
    caption = "Source: CISA KEV Catalog (Oct 2026)"
  ) +
  theme_cybershield() +
  theme(panel.grid.major.y = element_blank())

ggsave("screenshots/fig1_proposed_bar.png", p1, width = 10, height = 6, dpi = 150, bg = "#12121a")
cat("  [OK] fig1_proposed_bar.png\n")

# ── CHART 2: Proposed Visualization — Line Chart Dual Series ────────────────
monthly_total <- df |> count(added_ym, name = "total")
monthly_ransom <- df |>
  filter(known_ransomware_campaign_use == "Yes") |>
  count(added_ym, name = "ransom")
monthly <- monthly_total |>
  left_join(monthly_ransom, by = "added_ym") |>
  mutate(ransom = ifelse(is.na(ransom), 0, ransom))

p2 <- ggplot() +
  geom_line(data = monthly, aes(x = added_ym, y = total, color = "Total Additions"),
            linewidth = 1.3) +
  geom_line(data = monthly, aes(x = added_ym, y = ransom, color = "Ransomware-Linked"),
            linewidth = 1.3) +
  scale_color_manual(values = c("Total Additions" = "#4d7cfe", "Ransomware-Linked" = "#ef4444"),
                     name = NULL) +
  scale_x_date(date_labels = "%b %Y", date_breaks = "6 months") +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title = "Monthly KEV Catalog Additions (2021–2026)",
    subtitle = "Blue = total additions | Red = ransomware-linked additions",
    x = NULL,
    y = "Count",
    caption = "Source: CISA KEV Catalog (Oct 2026)"
  ) +
  theme_cybershield() +
  theme(legend.position = "bottom")

ggsave("screenshots/fig2_proposed_line.png", p2, width = 10, height = 5.5, dpi = 150, bg = "#12121a")
cat("  [OK] fig2_proposed_line.png\n")

# ── CHART 3: Flawed Visualization — Truncated Axis + All Green ──────────────
flawed_data <- top_vendors |>
  mutate(score = 100 - ransom_pct * 0.02 - total * 0.01) |>
  arrange(desc(total))

p3 <- ggplot(flawed_data, aes(x = score, y = vendor_project)) +
  geom_col(fill = "#10b981", width = 0.75) +
  coord_cartesian(xlim = c(90, 100)) +
  scale_x_continuous(breaks = seq(90, 100, by = 2)) +
  labs(
    title = "Vendor Security Scores",
    subtitle = "(FLAWED — truncated axis + misleading green color)",
    x = "Security Score",
    y = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.background = element_rect(fill = "#12121a", color = NA),
    panel.background = element_rect(fill = "#12121a", color = NA),
    panel.grid.major = element_line(color = "#1e1e2e"),
    panel.grid.minor = element_blank(),
    text = element_text(color = "#f0f0f5"),
    axis.text = element_text(color = "#6b6b80"),
    axis.title = element_text(color = "#f0f0f5"),
    plot.title = element_text(face = "bold", color = "#f0f0f5"),
    plot.subtitle = element_text(color = "#ef4444")
  )

ggsave("screenshots/fig3_flawed.png", p3, width = 10, height = 5.5, dpi = 150, bg = "#12121a")
cat("  [OK] fig3_flawed.png\n")

# ── CHART 4: Corrected Visualization — True Zero + Blue Gradient ────────────
p4 <- ggplot(top_vendors, aes(x = total, y = vendor_project, fill = total)) +
  geom_col(width = 0.75) +
  geom_text(aes(label = total), hjust = -0.2, color = "#f0f0f5", size = 4, fontface = "bold") +
  scale_fill_gradient(low = "#1a3a6e", high = "#4d7cfe", guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15)), limits = c(0, 420)) +
  labs(
    title = "CISA KEV Catalog Entries by Vendor (Top 10)",
    subtitle = "Bar length = vulnerability count (higher = more exploited vulnerabilities)",
    x = "Vulnerability Count",
    y = NULL,
    caption = "Source: CISA KEV Catalog. Higher count = more exploited vulnerabilities.\nDoes not indicate vendor security quality."
  ) +
  theme_cybershield() +
  theme(panel.grid.major.y = element_blank())

ggsave("screenshots/fig4_corrected.png", p4, width = 10, height = 6, dpi = 150, bg = "#12121a")
cat("  [OK] fig4_corrected.png\n")

cat("\n=== All chart images generated ===\n")
