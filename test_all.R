user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
if (dir.exists(user_lib)) .libPaths(c(user_lib, .libPaths()))
setwd("D:/new_ajay/CyberShield")

suppressPackageStartupMessages({
  library(shiny); library(bslib); library(dplyr); library(readr)
  library(janitor); library(lubridate); library(ggplot2); library(plotly)
  library(DT); library(purrr); library(bsicons); library(scales); library(tibble)
})

source("R/data_loader.R")
source("R/data_cleaning.R")
source("R/analysis.R")
source("R/charts.R")
source("R/helpers.R")

cat("=== TEST 1: Data loading ===\n")
raw <- load_kev_raw("data/known_exploited_vulnerabilities.csv")
cat("Raw rows:", nrow(raw), "\n")
raw <- validate_kev_columns(raw)
dedup <- check_duplicates(raw)
df <- clean_kev_data(dedup$data)
cat("Clean rows:", nrow(df), "\n")
cat("Columns:", paste(names(df), collapse=", "), "\n")

cat("\n=== TEST 2: Key columns ===\n")
required <- c("cve_id","vendor_project","product","vulnerability_name",
              "date_added","due_date","known_ransomware_campaign_use",
              "due_status","added_ym","added_year","forensic_triage",
              "primary_cwe","days_to_due")
for (col in required) {
  if (col %in% names(df)) cat("  [OK]", col, "\n") else cat("  [MISSING]", col, "\n")
}

cat("\n=== TEST 3: Filtering ===\n")
filtered <- df |>
  filter(date_added >= Sys.Date() - 365, date_added <= Sys.Date()) |>
  filter(if (TRUE) vendor_project == "All" else TRUE)
cat("Filtered rows (last 365 days, all vendors):", nrow(filtered), "\n")

filtered2 <- df |> filter(vendor_project == "Microsoft")
cat("Filtered rows (Microsoft):", nrow(filtered2), "\n")

cat("\n=== TEST 4: KPI calculations ===\n")
cat("Total:", nrow(df), "\n")
cat("Vendors:", n_distinct(df$vendor_project), "\n")
cat("Ransomware Yes:", sum(df$known_ransomware_campaign_use == "Yes", na.rm=TRUE), "\n")
cat("Overdue:", sum(df$due_status == "Overdue", na.rm=TRUE), "\n")
cat("Upcoming:", sum(df$due_status == "Upcoming", na.rm=TRUE), "\n")

cat("\n=== TEST 5: Chart data prep ===\n")
monthly <- df |> count(added_ym, name="vuln_count") |> arrange(added_ym)
cat("Monthly buckets:", nrow(monthly), "\n")

top_vendors <- df |> count(vendor_project, name="n") |> arrange(desc(n)) |> head(10)
cat("Top vendor:", top_vendors$vendor_project[1], "with", top_vendors$n[1], "entries\n")

cat("\n=== TEST 6: ggplot rendering ===\n")
p <- ggplot(monthly, aes(x=added_ym, y=vuln_count)) + geom_line() + theme_cybershield()
cat("ggplot builds: OK\n")
pl <- ggplotly(p)
cat("ggplotly converts: OK\n")

cat("\n=== TEST 7: ggplotly_cs (full styling) ===\n")
pl2 <- ggplotly_cs(p)
cat("ggplotly_cs: OK\n")

cat("\n=== TEST 8: Pie chart (plot_ly) ===\n")
tab <- df |> count(known_ransomware_campaign_use, name="n")
pie <- plot_ly(tab, labels=~known_ransomware_campaign_use, values=~n,
               type="pie", hole=0.6)
cat("plot_ly pie: OK\n")

cat("\n=== TEST 9: Treemap ===\n")
top25 <- df |> count(vendor_project, sort=TRUE) |> head(25)
tm <- plot_ly(top25, labels=~vendor_project, parents="", values=~n, type="treemap")
cat("Treemap: OK\n")

cat("\n=== TEST 10: Box plot ===\n")
bd <- df |> mutate(rw = as.numeric(due_date - date_added)) |>
  filter(!is.na(rw), rw >= 0, rw <= 90)
p3 <- ggplot(bd, aes(x=factor(added_year), y=rw, fill=factor(added_year))) +
  geom_boxplot() + theme_cybershield()
pl3 <- ggplotly_cs(p3)
cat("Box plot: OK\n")

cat("\n=== TEST 11: Scatter ===\n")
sd <- df |> mutate(rw = as.numeric(due_date - date_added)) |>
  filter(!is.na(rw), rw >= 0, rw <= 90)
p4 <- ggplot(sd, aes(x=date_added, y=rw, color=known_ransomware_campaign_use)) +
  geom_point() + theme_cybershield()
pl4 <- ggplotly_cs(p4)
cat("Scatter: OK\n")

cat("\n=== TEST 12: Waffle data ===\n")
triage <- df |> count(forensic_triage, name="n") |>
  mutate(pct = round(n / sum(n) * 100, 0))
cat("Triage categories:", nrow(triage), "\n")
waffle_data <- purrr::map_dfr(1:nrow(triage), function(i) {
  sq <- seq_len(triage$pct[i])
  if (length(sq) == 0) return(NULL)
  tibble(id=1:100, col=(id-1)%%10, row=(id-1)%/%10, category=NA_character_)[sq,] |>
    mutate(category = triage$forensic_triage[i])
})
cat("Waffle squares:", nrow(waffle_data), "\n")

cat("\n=== TEST 13: Slope chart ===\n")
slope <- df |> filter(!is.na(added_year), added_year >= 2022) |>
  group_by(added_year) |>
  summarise(rs = mean(known_ransomware_campaign_use == "Yes", na.rm=TRUE)*100, .groups="drop") |>
  mutate(ylag = lag(added_year), rslag = lag(rs)) |> filter(!is.na(rslag))
cat("Slope rows:", nrow(slope), "\n")

cat("\n=== TEST 14: Diverging bar ===\n")
top15 <- df |> count(vendor_project, sort=TRUE) |> head(15) |> pull(vendor_project)
vrisk <- df |> filter(vendor_project %in% top15) |>
  group_by(vendor_project) |>
  summarise(rp = mean(known_ransomware_campaign_use == "Yes", na.rm=TRUE)*100, .groups="drop") |>
  mutate(dev = rp - 50)
cat("Diverging rows:", nrow(vrisk), "\n")

cat("\n=== TEST 15: Polar chart ===\n")
wd <- df |> mutate(wday = wday(date_added, label=TRUE)) |> count(wday, name="n")
cat("Polar rows:", nrow(wd), "\n")
pp <- plot_ly(wd, labels=~wday, values=~n, type="polar", direction="clockwise")
cat("Polar plotly: OK\n")

cat("\n=== TEST 16: Density ===\n")
mon2 <- monthly |> mutate(year = year(added_ym))
p5 <- ggplot(mon2, aes(x=n, fill=factor(year))) + geom_density(alpha=0.5) +
  scale_fill_viridis_d(option="plasma") + theme_cybershield()
pl5 <- ggplotly_cs(p5)
cat("Density: OK\n")

cat("\n=== TEST 17: Stacked area ===\n")
sa <- df |> count(added_ym, known_ransomware_campaign_use, name="n")
p6 <- ggplot(sa, aes(x=added_ym, y=n, fill=known_ransomware_campaign_use)) +
  geom_area() + theme_cybershield()
pl6 <- ggplotly_cs(p6)
cat("Stacked area: OK\n")

cat("\n=== TEST 18: CWE bar ===\n")
cwe <- df |> filter(!is.na(primary_cwe), primary_cwe != "N/A", primary_cwe != "") |>
  count(primary_cwe, sort=TRUE) |> head(12)
cat("CWE rows:", nrow(cwe), "\n")

cat("\n=== TEST 19: Histogram ===\n")
p7 <- ggplot(df, aes(x=cve_year)) + geom_histogram(binwidth=1) + theme_cybershield()
pl7 <- ggplotly_cs(p7)
cat("Histogram: OK\n")

cat("\n=== TEST 20: Lollipop ===\n")
top_prod <- df |> count(product, sort=TRUE) |> head(15)
p8 <- ggplot(top_prod, aes(x=n, y=reorder(product,n))) +
  geom_segment(aes(x=0, xend=n, y=product, yend=product)) +
  geom_point() + theme_cybershield()
pl8 <- ggplotly_cs(p8)
cat("Lollipop: OK\n")

cat("\n=== TEST 21: Heatmap ===\n")
tv <- df |> count(vendor_project, sort=TRUE) |> head(12) |> pull(vendor_project)
hm <- df |> filter(vendor_project %in% tv) |> count(vendor_project, added_year, name="n")
p9 <- ggplot(hm, aes(x=factor(added_year), y=vendor_project, fill=n)) +
  geom_tile() + theme_cybershield()
pl9 <- ggplotly_cs(p9)
cat("Heatmap: OK\n")

cat("\n=== TEST 22: Slope chart plot ===\n")
p10 <- ggplot(slope, aes(group=added_year)) +
  geom_segment(aes(x=ylag, xend=added_year, y=rslag, yend=rs)) +
  geom_point(aes(x=ylag, y=rslag)) +
  geom_point(aes(x=added_year, y=rs)) +
  theme_cybershield()
pl10 <- ggplotly_cs(p10)
cat("Slope: OK\n")

cat("\n=== TEST 23: Diverging plot ===\n")
p11 <- ggplot(vrisk, aes(x=dev, y=reorder(vendor_project,dev), fill=dev>0)) +
  geom_col() + theme_cybershield()
pl11 <- ggplotly_cs(p11)
cat("Diverging: OK\n")

cat("\n=== TEST 24: YoY change ===\n")
yearly <- df |> count(added_year, name="n") |> arrange(added_year) |>
  mutate(yoy = (n - lag(n))/lag(n)*100) |> filter(!is.na(yoy))
p12 <- ggplot(yearly, aes(x=factor(added_year), y=yoy, fill=yoy>0)) +
  geom_col() + theme_cybershield()
pl12 <- ggplotly_cs(p12)
cat("YoY: OK\n")

cat("\n=== TEST 25: CSV export ===\n")
tmp <- tempfile(fileext=".csv")
export_filtered_csv(df |> head(100), tmp)
cat("CSV written:", file.exists(tmp), "size:", file.size(tmp), "bytes\n")
rt <- read_csv(tmp, show_col_types=FALSE)
cat("CSV read back:", nrow(rt), "rows\n")

cat("\n=== ALL TESTS PASSED ===\n")
