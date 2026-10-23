user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
.libPaths(c(user_lib, .libPaths()))
setwd("D:/new_ajay/CyberShield")

suppressPackageStartupMessages({
  library(officer)
})

cat("=== Building DOCX with real chart images ===\n")

doc <- read_docx()

# ── Title page ────────────────────────────────────────────────────────────────
doc <- doc |>
  body_add_par("CSI3005 — Advanced Data Visualization Techniques", style = "heading 1") |>
  body_add_par("Case Study Based Assessment — Theory Component", style = "heading 2") |>
  body_add_par("") |>
  body_add_par("Case Study Title: CyberShield — Interactive Cyber Vulnerability Intelligence and Risk Analytics Dashboard") |>
  body_add_par("Slot: E2 (Theory)  |  Semester: Fall Sem 2026–2027  |  Deadline: 23.10.2026") |>
  body_add_break()

# ── Section 1: Frame the Problem ──────────────────────────────────────────────
doc <- doc |>
  body_add_par("1. Frame the Problem", style = "heading 1") |>
  body_add_par(paste(
    "Cyber vulnerabilities are discovered at an accelerating pace. The CISA Known Exploited",
    "Vulnerabilities (KEV) Catalog lists vulnerabilities with confirmed real-world exploitation [1].",
    "At the time of this analysis, the catalog contains 1,754 vulnerability records spanning",
    "November 2021 to October 2026, covering 290 unique vendors. The problem: security analysts,",
    "IT managers, and cybersecurity students cannot easily extract actionable insights from the",
    "raw catalog data. They need a tool that visualizes trends, identifies high-risk vendors,",
    "tracks remediation deadlines, and highlights ransomware-linked vulnerabilities."
  )) |>
  body_add_par("") |>
  body_add_par("Intended Audience", style = "heading 2")

audience <- data.frame(
  Audience = c("Security Analysts", "IT Managers", "Cybersecurity Students", "Policy Makers"),
  Level = c("High", "Medium", "Low–Medium", "Low"),
  Need = c("Prioritize patching", "Understand vendor risk", "Learn landscape patterns", "Understand systemic risk")
)
doc <- doc |> body_add_table(audience, style = "table_template")

doc <- doc |>
  body_add_par("") |>
  body_add_par("Decision the Visualization Should Support", style = "heading 2") |>
  body_add_par('"Which vulnerabilities should my organization patch first, and where should I focus my limited security resources?"') |>
  body_add_par("") |>
  body_add_par("Relevant Dataset Attributes", style = "heading 2")

attrs <- data.frame(
  Attribute = c("cve_id", "vendor_project", "product", "date_added", "due_date",
                "known_ransomware_campaign_use", "forensic_triage", "cwes"),
  Type = c("Categorical (String)", "Categorical (Nominal)", "Categorical (Nominal)",
           "Temporal (Date)", "Temporal (Date)", "Categorical (Binary)",
           "Categorical (Binary)", "Categorical (Nominal)"),
  Description = c("Unique CVE identifier", "Vendor name", "Affected product",
                  "Date added to catalog", "Remediation deadline",
                  "Ransomware linkage", "Forensic requirement", "CWE identifiers")
)
doc <- doc |> body_add_table(attrs, style = "table_template")

doc <- doc |>
  body_add_par("") |>
  body_add_par("Two Analytical Questions", style = "heading 2") |>
  body_add_par(paste(
    "Q1: Which vendors have the highest concentration of actively exploited vulnerabilities,",
    "and what proportion are linked to known ransomware campaigns?",
    "Security teams have limited budgets and must prioritize which vendor ecosystems to",
    "secure first. A vendor with many exploited vulnerabilities AND high ransomware linkage",
    "represents the greatest organizational risk."
  )) |>
  body_add_par("") |>
  body_add_par(paste(
    "Q2: How have monthly vulnerability catalog additions changed over time, and is there",
    "a measurable shift in the proportion of ransomware-linked entries?",
    "This helps security leadership understand whether the threat landscape is worsening",
    "and whether ransomware is becoming a more dominant attack vector."
  )) |>
  body_add_break()

# ── Section 2: Choose and Defend ──────────────────────────────────────────────
doc <- doc |>
  body_add_par("2. Choose and Defend", style = "heading 1") |>
  body_add_par("Visualization 1: Horizontal Bar Chart with Dual Encoding — Vendor Risk Profile", style = "heading 2") |>
  body_add_par("Addresses Q1. Bar length encodes vulnerability count; color encodes ransomware proportion (blue = 0%, red = 100%).")

# Embed fig1
if (file.exists("screenshots/fig1_proposed_bar.png")) {
  doc <- doc |>
    body_add_par("") |>
    body_add_img("screenshots/fig1_proposed_bar.png", width = 6.0, height = 3.6) |>
    body_add_par("")
}

doc <- doc |>
  body_add_par("How It Helps Answer Q1:", style = "heading 3") |>
  body_add_par(paste(
    "Bar length immediately reveals Microsoft (390) and Cisco (247) as the top two, making",
    "the concentration visible. The color encoding adds a critical second dimension — Fortinet",
    "has fewer total vulnerabilities (178) than Microsoft, but its darker red color reveals a",
    "higher ransomware linkage rate, making it arguably higher priority for ransomware-focused",
    "defense."
  )) |>
  body_add_par("") |>
  body_add_par("Comparison with Alternative (Treemap):", style = "heading 3")

comp1 <- data.frame(
  Aspect = c("Data type fit", "Readability", "Comparison accuracy"),
  `Horizontal Bar` = c("Nominal + 2 quantitative", "Exact values from bar length", "Position on common baseline"),
  Treemap = c("Nominal + 1 quantitative", "Area comparison imprecise", "Area perception less accurate")
)
doc <- doc |> body_add_table(comp1, style = "table_template")

doc <- doc |>
  body_add_par("") |>
  body_add_par(paste(
    "Justification: The horizontal bar chart is selected because it supports two quantitative",
    "variables (count + ransomware %) via length + color encoding, and provides accurate",
    "comparison through position on a common baseline (Cleveland & McGill, 1984)."
  )) |>
  body_add_par("") |>
  body_add_par("Visualization 2: Line Chart with Dual Series — Temporal Trend Analysis", style = "heading 2") |>
  body_add_par("Addresses Q2. Blue line = total monthly additions; red line = ransomware-linked additions.")

# Embed fig2
if (file.exists("screenshots/fig2_proposed_line.png")) {
  doc <- doc |>
    body_add_par("") |>
    body_add_img("screenshots/fig2_proposed_line.png", width = 6.0, height = 3.3) |>
    body_add_par("")
}

doc <- doc |>
  body_add_par("How It Helps Answer Q2:", style = "heading 3") |>
  body_add_par(paste(
    "The blue line's trajectory reveals whether catalog additions are accelerating. The red",
    "line's slope relative to the blue line shows whether ransomware proportion is growing.",
    "Annotations at spike points help correlate sudden increases with known events."
  )) |>
  body_add_par("") |>
  body_add_par("Comparison with Alternative (Stacked Area):", style = "heading 3")

comp2 <- data.frame(
  Aspect = c("Trend clarity", "Dual series", "Spike visibility"),
  `Line Chart` = c("Line = clearest trend", "Two lines easy to compare", "Sharp peaks visible"),
  `Stacked Area` = c("Fill can obscure thin layers", "Require mental subtraction", "Fill can smooth perception")
)
doc <- doc |> body_add_table(comp2, style = "table_template")

doc <- doc |>
  body_add_par("") |>
  body_add_par(paste(
    "Justification: The line chart is selected because Q2 asks whether the ransomware",
    "proportion is shifting — this requires comparing slopes of two lines. Line charts follow",
    "Tufte's data-ink ratio principle and provide the most perceptually accurate encoding for",
    "temporal change."
  )) |>
  body_add_break()

# ── Section 3: Critique and Correct ───────────────────────────────────────────
doc <- doc |>
  body_add_par("3. Critique and Correct", style = "heading 1") |>
  body_add_par("3.1 Flawed Visualization", style = "heading 2") |>
  body_add_par("Two deliberate flaws: (1) truncated axis (starts at 90, not 0) and (2) inappropriate green 'secure' coloring with misleading title.")

# Embed fig3
if (file.exists("screenshots/fig3_flawed.png")) {
  doc <- doc |>
    body_add_par("") |>
    body_add_img("screenshots/fig3_flawed.png", width = 6.0, height = 3.3) |>
    body_add_par("")
}

doc <- doc |>
  body_add_par("Flaw Identification", style = "heading 3") |>
  body_add_par(paste(
    "Flaw 1 — Truncated Axis: The Y-axis starts at 90 instead of 0. This exaggerates",
    "differences — Microsoft has 390 vulnerabilities and Siemens has ~80, but with the axis",
    "truncated at 90, all bars appear nearly the same length. Impact: IT managers would",
    "distribute resources equally across all vendors, leading to under-investment in",
    "high-risk areas."
  )) |>
  body_add_par("") |>
  body_add_par(paste(
    "Flaw 2 — Inappropriate Color: All bars are bright green, a universally recognized",
    "'safe/secure' color. The title says 'Security Scores' which falsely implies positive",
    "ratings, when the data shows vulnerability counts (more = worse). Impact: Creates a",
    "false sense of security."
  )) |>
  body_add_par("") |>
  body_add_par("3.2 Corrected Visualization", style = "heading 2") |>
  body_add_par("Corrections: (1) axis starts at 0 (true zero baseline), (2) neutral blue sequential color + accurate title + explanatory caption.")

# Embed fig4
if (file.exists("screenshots/fig4_corrected.png")) {
  doc <- doc |>
    body_add_par("") |>
    body_add_img("screenshots/fig4_corrected.png", width = 6.0, height = 3.6) |>
    body_add_par("")
}

doc <- doc |>
  body_add_par("Justification of Corrections", style = "heading 3") |>
  body_add_par(paste(
    "Starting the axis at 0 ensures bar lengths are proportional to values — Microsoft's bar",
    "is now visibly ~5x longer than Siemens's. Title changed to 'CISA KEV Catalog Entries by",
    "Vendor' for accuracy. Color changed to a blue sequential gradient that reinforces the",
    "count encoding. A caption explicitly states 'Higher count = more exploited",
    "vulnerabilities. Does not indicate vendor security quality.'"
  )) |>
  body_add_break()

# ── Section 4: Changed Requirement ────────────────────────────────────────────
doc <- doc |>
  body_add_par("4. Respond to a Changed Requirement", style = "heading 1") |>
  body_add_par(paste(
    "The stakeholder now needs to monitor vulnerability catalog additions continuously as new",
    "data arrive. I would adapt Visualization 2 (the line chart) for streaming data."
  )) |>
  body_add_par("") |>
  body_add_par("Update Interval: Every 6 hours", style = "heading 3") |>
  body_add_par(paste(
    "The CISA KEV catalog is updated periodically, not in real-time. A 6-hour interval catches",
    "new additions within the same working day, avoids excessive API calls, and is frequent",
    "enough to detect sudden spikes."
  )) |>
  body_add_par("") |>
  body_add_par("Display Time Window: Rolling 90-day window", style = "heading 3") |>
  body_add_par(paste(
    "A 90-day window is short enough that a spike is visually prominent, shows quarterly",
    "patterns, and reduces visual clutter. Users can expand to 12 months for context."
  )) |>
  body_add_par("") |>
  body_add_par("Individual vs Aggregated: Dual-layer approach", style = "heading 3") |>
  body_add_par(paste(
    "Background layer: Raw daily counts as small semi-transparent points. Foreground layer:",
    "7-day moving average as a bold line revealing the underlying trend."
  )) |>
  body_add_par("") |>
  body_add_par("Trade-off Analysis:", style = "heading 3")

tradeoff <- data.frame(
  Aspect = c("Spike detection", "Trend detection", "Noise level", "Best for"),
  `Short (30d)` = c("Excellent", "Poor", "High", "Incident response"),
  `Medium (90d)` = c("Good", "Good", "Moderate", "Operational monitoring"),
  `Long (12mo)` = c("Poor", "Excellent", "Low", "Strategic planning")
)
doc <- doc |> body_add_table(tradeoff, style = "table_template")

doc <- doc |>
  body_add_par("") |>
  body_add_par(paste(
    "Recommended: 90-day rolling window with 7-day moving average overlay. This provides",
    "good spike detection, good trend detection, and noise reduction."
  )) |>
  body_add_break()

# ── References ────────────────────────────────────────────────────────────────
doc <- doc |>
  body_add_par("References", style = "heading 1") |>
  body_add_par("[1] CISA, \"Known Exploited Vulnerabilities Catalog,\" 2026. Available: https://www.cisa.gov/known-exploited-vulnerabilities-catalog") |>
  body_add_par("[2] W. Cleveland and R. McGill, \"Graphical Perception,\" JASA, vol. 79, no. 387, pp. 531–554, 1984.") |>
  body_add_par("[3] C. Ware, \"Information Visualization: Perception for Design,\" Morgan Kaufmann, 3rd ed., 2012.") |>
  body_add_par("[4] E. R. Tufte, \"The Visual Display of Quantitative Information,\" Graphics Press, 2nd ed., 2001.") |>
  body_add_break()

# ── Dashboard Screenshots ─────────────────────────────────────────────────────
doc <- doc |>
  body_add_par("Appendix: CyberShield Dashboard Screenshots", style = "heading 1") |>
  body_add_par("") |>
  body_add_par("Overview Page", style = "heading 3")
if (file.exists("screenshots/overview.png")) {
  doc <- doc |> body_add_img("screenshots/overview.png", width = 6.5, height = 4.0)
}
doc <- doc |> body_add_par("") |> body_add_par("Gallery Page", style = "heading 3")
if (file.exists("screenshots/gallery.png")) {
  doc <- doc |> body_add_img("screenshots/gallery.png", width = 6.5, height = 4.0)
}

# ── Save ──────────────────────────────────────────────────────────────────────
output_file <- "CSI3005_Case_Study_CyberShield_v2.docx"
print(doc, target = output_file)
cat("\n=== DOCX created:", output_file, "===\n")
cat("Size:", file.size(output_file), "bytes\n")
