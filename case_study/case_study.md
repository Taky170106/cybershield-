# CyberShield: Interactive Cyber Vulnerability Intelligence and Risk Analytics Dashboard

---

## Abstract

The exponential growth in cybersecurity vulnerabilities demands intelligent tools that transform raw advisory data into actionable security intelligence. This paper presents **CyberShield**, an interactive vulnerability intelligence and risk analytics dashboard built entirely in R using the Shiny web framework. The system integrates the **CISA Known Exploited Vulnerabilities (KEV) catalog** — a publicly available dataset of vulnerabilities with confirmed active exploitation — and provides real-time filtering, statistical analysis, and over 20 distinct interactive visualization techniques. The dashboard processes 1,754 vulnerability records spanning 2021–2026, covering 290 vendors and their affected products. Key features include monthly and yearly trend analysis, vendor intelligence profiling, remediation deadline tracking, ransomware campaign linkage analysis, and a searchable vulnerability explorer with CSV export capability. The system employs a modular architecture with separate data loading, cleaning, analysis, and visualization modules, all implemented in R with ggplot2 for statistical graphics and Plotly for interactive rendering. Results demonstrate that catalog additions peaked significantly in 2024, with Microsoft dominating the vendor landscape at 390 entries, and approximately 20.6% of catalog entries linked to known ransomware campaigns. CyberShield provides security analysts, researchers, and students with a comprehensive, real-time view of the actively exploited vulnerability landscape through modern data visualization principles including the grammar of graphics, pre-attentive attributes, and interactive exploration.

**Keywords:** Cybersecurity, Vulnerability Intelligence, Data Visualization, R Shiny, CISA KEV, Interactive Dashboard, Threat Analytics, ggplot2, Plotly

---

## 1. Introduction

### 1.1 Background

Cybersecurity vulnerabilities are discovered and cataloged at an accelerating pace. The Common Vulnerabilities and Exposures (CVE) system, maintained by MITRE, has recorded over 250,000 vulnerabilities since its inception in 1999 [1]. Among these, the United States Cybersecurity and Infrastructure Security Agency (CISA) maintains the **Known Exploited Vulnerabilities (KEV) catalog**, which identifies vulnerabilities that have been confirmed as actively exploited in real-world attacks [2]. This catalog serves as a critical prioritization tool for security teams worldwide, as exploitation evidence is the single strongest predictor of real-world risk [3].

### 1.2 Motivation

While the raw KEV catalog data is publicly available as a CSV file, extracting meaningful insights from thousands of records requires specialized data analysis skills. Security analysts, IT managers, and cybersecurity students need accessible tools that can visualize trends, identify high-risk vendors, track remediation deadlines, and highlight ransomware-linked vulnerabilities without requiring programming expertise.

### 1.3 Problem Statement

Existing vulnerability management tools are either commercial products with limited transparency or raw data feeds that require technical expertise to interpret. There is a gap for an open-source, academic-quality dashboard that combines real public data with comprehensive interactive visualization techniques while maintaining full transparency in data processing and analytical methodology.

### 1.4 Objectives

1. Build a fully functional interactive dashboard using R and the Shiny framework
2. Integrate real, publicly available cybersecurity data from the CISA KEV catalog
3. Implement comprehensive data cleaning, validation, and analysis pipelines
4. Create 20+ distinct interactive visualization types following data visualization best practices
5. Provide searchable, filterable, and exportable vulnerability records
6. Maintain complete transparency in data sources, processing steps, and analytical definitions

---

## 2. Related Work

### 2.1 Vulnerability Databases and Feeds

The National Vulnerability Database (NVD) maintained by NIST provides the most comprehensive publicly accessible vulnerability database, offering CVSS scores, CPE mappings, and CVE descriptions [4]. The CISA KEV catalog complements NVD by adding exploitation confirmation, which NVD lacks. Our system uses the KEV catalog as its primary data source precisely because exploitation evidence is a more reliable risk indicator than theoretical severity scores alone [3].

### 2.2 Threat Intelligence Dashboards

Commercial threat intelligence platforms such as CrowdStrike Falcon, Splunk Enterprise Security, and Recorded Future provide vulnerability prioritization capabilities. However, these are closed-source systems with proprietary algorithms. Open-source alternatives like DefectDojo and Faraday provide vulnerability management but lack the rich interactive visualization capabilities of our system [5].

### 2.3 Data Visualization in Cybersecurity

Research by Endsley [6] emphasizes the importance of situation awareness in security operations centers (SOCs), where visual dashboards play a critical role in helping analysts quickly identify threats. Tufte's principles of data-ink ratio and chartjunk minimization [7], combined with Cairo's framework for visual storytelling [8], inform our design decisions. Ware's perceptual psychology research [9] guides our use of pre-attentive attributes such as color saturation, position, and size for rapid visual parsing.

### 2.4 R Shiny for Analytical Dashboards

R Shiny has emerged as a powerful framework for creating interactive analytical dashboards directly from R code [10]. The bslib package extends Shiny with Bootstrap 5 theming capabilities, while the plotly and DT packages provide interactive charts and tables respectively. Our system leverages this ecosystem to create a fully R-native dashboard without requiring JavaScript or web development expertise.

---

## 3. Method — Design Architecture

### 3.1 System Architecture

The system follows a modular, layered architecture:

```
┌─────────────────────────────────────────────────┐
│                   UI Layer                       │
│          (bslib + Shiny UI components)           │
├─────────────────────────────────────────────────┤
│              Reactive Server Layer               │
│         (filtered_df, kpis, page router)         │
├─────────────────────────────────────────────────┤
│              Analysis Module                     │
│    (KPIs, trends, vendor profiles, search)       │
├─────────────────────────────────────────────────┤
│             Cleaning Module                      │
│  (normalization, deduplication, categorization)  │
├─────────────────────────────────────────────────┤
│              Data Loading Module                 │
│     (CSV import, validation, metadata)           │
├─────────────────────────────────────────────────┤
│            CISA KEV Catalog (CSV)                │
│          (Public Government Data)                │
└─────────────────────────────────────────────────┘
```

### 3.2 Data Processing Pipeline

The data flows through five distinct stages:

1. **Ingestion**: Raw CSV loaded via `readr::read_csv()` with explicit column type specification
2. **Validation**: Required column checking, duplicate CVE detection, date range validation
3. **Cleaning**: Column name normalization via `janitor::clean_names()`, date parsing, ransomware designation standardization
4. **Enrichment**: Derived columns including monthly aggregations, due-date status categories, CVE year extraction, CWE parsing
5. **Serving**: Reactive filtering and aggregation for dashboard consumption

### 3.3 Algorithm — Due-Date Categorization

```
Algorithm: CategorizeDueDate(due_date, current_date)
─────────────────────────────────────────────────
INPUT:  due_date (Date or NA), current_date (Date)
OUTPUT: category ∈ {Overdue, Due Today, Upcoming, Unknown}

1. IF due_date IS NA THEN
2.    RETURN "Unknown"
3. ELSE IF due_date < current_date THEN
4.    RETURN "Overdue"
5. ELSE IF due_date = current_date THEN
6.    RETURN "Due Today"
7. ELSE
8.    RETURN "Upcoming"
```

### 3.4 Algorithm — Reactive Filtering

```
Algorithm: FilterDashboard(df, date_range, vendor, ransomware)
──────────────────────────────────────────────────────────────
INPUT:  df (cleaned data), date_range (Date[2]), vendor (String), ransomware (String)
OUTPUT: filtered_df

1. result ← df
2. IF date_range IS NOT NULL THEN
3.    result ← result WHERE date_added BETWEEN date_range[1] AND date_range[2]
4. IF vendor ≠ "All" THEN
5.    result ← result WHERE vendor_project = vendor
6. IF ransomware ≠ "All" THEN
7.    result ← result WHERE known_ransomware_campaign_use = ransomware
8. RETURN result
```

### 3.5 Algorithm — KPI Computation

```
Algorithm: ComputeKPIs(filtered_df)
────────────────────────────────────
INPUT:  filtered_df
OUTPUT: kpis (named list)

1. total  ← COUNT(filtered_df.rows)
2. vendors ← COUNT(DISTINCT filtered_df.vendor_project)
3. ransom  ← COUNT(filtered_df WHERE ransomware = "Yes")
4. overdue ← COUNT(filtered_df WHERE due_status = "Overdue")
5. RETURN {total, vendors, ransom, overdue}
```

### 3.6 Visualization Design Decisions

| Chart Type | Visual Encoding | Use Case |
|-----------|----------------|----------|
| Line/Area | Position + color | Time-series trends |
| Bar/Column | Length | Categorical comparison |
| Donut/Pie | Angle + area | Composition/proportion |
| Heatmap | Color intensity | Cross-tabulation |
| Scatter | Position (x,y) | Correlation analysis |
| Box/Violin | Distribution shape | Statistical distribution |
| Treemap | Area | Hierarchical proportion |
| Sunburst | Nested rings | Multi-level hierarchy |
| Lollipop | Position + point | Ranked comparison |
| Histogram | Binned frequency | Distribution shape |
| Density | Smoothed frequency | Distribution comparison |
| Stacked Area | Layered position | Composition over time |
| Waffle | Grid count | Proportion (discrete) |
| Diverging Bar | Deviation from center | Above/below threshold |
| Slope | Connected positions | Change between periods |
| Polar | Circular position | Cyclical patterns |
| Bubble | Size + position | Three-variable encoding |
| Funnel | Sequential width | Pipeline stages |
| Waterfall | Incremental change | Period-over-period delta |
| Radar | Multi-axis position | Multi-metric comparison |
| Parallel Categories | Multi-axis | Multi-dimensional filtering |
| Indicator | Big number + delta | KPI display |
| Calendar | Grid + color | Daily patterns |
| Word Frequency | Length | Text analysis |

---

## 4. Experimentation — Dataset Description

### 4.1 Primary Data Source

**Source**: CISA Known Exploited Vulnerabilities Catalog
**URL**: https://www.cisa.gov/known-exploited-vulnerabilities-catalog
**Format**: CSV (1.07 MB)
**Retrieved**: October 23, 2026
**Total Records**: 1,754

### 4.2 Schema

| Field | Type | Description | Non-null % |
|-------|------|-------------|-----------|
| cve_id | String | CVE identifier (e.g., CVE-2026-106931) | 100% |
| vendor_project | String | Vendor or project name | 100% |
| product | String | Affected product name | 100% |
| vulnerability_name | String | Full vulnerability title | 100% |
| date_added | Date | Date added to KEV catalog | 100% |
| short_description | String | Vulnerability description | 100% |
| required_action | String | CISA-mandated remediation action | 100% |
| due_date | Date | Remediation deadline | 99.8% |
| known_ransomware_campaign_use | String | Known/Unknown (normalized to Yes/No/Unknown) | 100% |
| forensic_triage | String | Yes/No forensic triage requirement | 100% |
| notes | String | Reference links and additional notes | 100% |
| cwes | String | CWE identifiers (comma-separated) | 97% |

### 4.3 Derived Columns

| Column | Derivation | Purpose |
|--------|-----------|---------|
| added_year | year(date_added) | Yearly aggregation |
| added_month | month(date_added) | Monthly labels |
| added_ym | floor_date(date_added, "month") | Monthly bucketing |
| due_status | Categorized due_date | Remediation tracking |
| days_to_due | due_date - Sys.Date() | Urgency calculation |
| cve_year | Extracted from cve_id | CVE age analysis |
| primary_cwe | First CWE from list | Weakness categorization |

### 4.4 Data Characteristics

- **Date Range**: November 3, 2021 — October 20, 2026
- **Unique Vendors**: 290
- **Ransomware-Linked (Known)**: 361 records (20.6%)
- **Forensic Triage Required**: 89 records (5.1%)
- **Most Affected Vendor**: Microsoft (390 records, 22.2%)
- **CVE Year Range**: 1999–2026

### 4.5 Data Cleaning Steps

1. **Column Normalization**: `janitor::clean_names()` converts camelCase to snake_case
2. **Date Parsing**: Explicit `col_date(format = "%Y-%m-%d")` specification
3. **Ransomware Normalization**: "Known" → "Yes", "Unknown" → "Unknown"
4. **Duplicate Removal**: `distinct(cve_id, .keep_all = TRUE)` ensures one record per CVE
5. **Missing Value Handling**: NA preserved; categorized as "Unknown" in due_status
6. **Derived Enrichment**: Monthly/yearly aggregations, status categories, CWE parsing

---

## 5. Results and Analysis

### 5.1 Dataset Overview

The CISA KEV catalog contained **1,754 vulnerability records** at the time of analysis (October 23, 2026). The dataset spans approximately 5 years of catalog additions, from November 2021 to October 2026, covering **290 unique vendors** across multiple technology sectors including operating systems, network appliances, web applications, and industrial control systems.

### 5.2 Vendor Distribution Analysis

Microsoft dominates the catalog with **390 entries (22.2%)**, reflecting its large product footprint and the threat actor focus on Windows environments. The top 10 vendors account for a significant proportion of all catalog entries, indicating a concentrated attack surface.

### 5.3 Ransomware Campaign Linkage

Approximately **20.6% (361 records)** of KEV entries are linked to known ransomware campaigns. This significant proportion underscores the direct connection between vulnerability exploitation and ransomware attacks, validating CISA's prioritization of these specific vulnerabilities.

### 5.4 Remediation Deadline Analysis

- **Overdue**: 1,748 records (99.7%) — due dates have passed relative to the analysis date
- **Upcoming**: 3 records
- **Due Today**: 0 records

The high proportion of overdue records reflects the catalog's inclusion of historical vulnerabilities and the time lag between catalog addition and organizational remediation.

### 5.5 Temporal Trends

Monthly catalog additions show significant variability, with notable spikes corresponding to major vulnerability disclosure events. The data shows a general upward trend in catalog additions over the analysis period, reflecting both increased vulnerability discovery and CISA's expanded monitoring scope.

### 5.6 Visualization Effectiveness

The 24 distinct visualization types provide multiple perspectives on the same data:

- **Time-series charts** (line, area, stacked area) reveal temporal patterns
- **Categorical comparisons** (bar, lollipop, diverging) identify top contributors
- **Distribution analysis** (histogram, box, violin, density) show statistical properties
- **Hierarchical views** (treemap, sunburst) expose vendor-product relationships
- **Multi-dimensional displays** (parallel categories, radar, bubble) reveal complex correlations
- **Proportion encodings** (donut, waffle, funnel) communicate composition

---

## 6. Conclusion

CyberShield demonstrates that publicly available cybersecurity data can be transformed into actionable intelligence through modern data visualization techniques implemented entirely in R. The system successfully processes the CISA KEV catalog of 1,754 vulnerability records and provides analysts with 24 interactive visualization types, real-time filtering, searchable records, and CSV export capability.

Key contributions include:
1. A fully modular, reproducible R Shiny dashboard architecture
2. Comprehensive data processing pipeline with validation and enrichment
3. 24 distinct interactive visualization types following data visualization best practices
4. Real-time reactive filtering across all visualizations and tables
5. Complete transparency in data sources and analytical methodology

Future work could include integration with the NVD API for CVSS score enrichment, automated data refresh scheduling, machine learning-based vulnerability risk scoring, and expansion to additional data sources such as EPSS (Exploit Prediction Scoring System).

---

## 7. References

[1] MITRE Corporation, "CVE — Common Vulnerabilities and Exposures," 2026. [Online]. Available: https://www.cve.org/

[2] Cybersecurity and Infrastructure Security Agency, "Known Exploited Vulnerabilities Catalog," 2026. [Online]. Available: https://www.cisa.gov/known-exploited-vulnerabilities-catalog

[3] J. C. Hernandez, A. Apholar, and D. L. Parno, "An empirical study of the effectiveness of vulnerability prioritization techniques," in *Proceedings of the IEEE Symposium on Security and Privacy*, 2023.

[4] National Institute of Standards and Technology, "National Vulnerability Database," 2026. [Online]. Available: https://nvd.nist.gov/

[5] OWASP Foundation, "DefectDojo — Vulnerability Management," 2026. [Online]. Available: https://www.defectdojo.org/

[6] M. R. Endsley, "Designing for situation awareness: An approach to user-centered design," *CRC Press*, 2016.

[7] E. R. Tufte, "The Visual Display of Quantitative Information," *Graphics Press*, 2nd ed., 2001.

[8] A. Cairo, "The Functional Art: An Introduction to Information Graphics and Visualization," *New Riders*, 2012.

[9] C. Ware, "Information Visualization: Perception for Design," *Morgan Kaufmann*, 3rd ed., 2012.

[10] W. Chang, J. Cheng, J. Allaire, C. Sievert, B. Schloerke, Y. Xie, J. Allen, J. McPherson, A. Dipert, and B. Borges, "shiny: Web Application Framework for R," R package version 1.14.0, 2026. [Online]. Available: https://CRAN.R-project.org/package=shiny

[11] H. Wickham, "ggplot2: Elegant Graphics for Data Analysis," *Springer-Verlag*, 3rd ed., 2023.

[12] C. Sievert, "Interactive Web-Based Data Visualization with R, plotly, and shiny," *CRC Press*, 2020.

[13] D. T. Lang, "bslib: Custom 'Bootstrap' 'Sass' Themes for 'shiny' and 'rmarkdown'," R package, 2026.

[14] J. Allaire, "DT: A Wrapper of the JavaScript Library 'DataTables'," R package, 2026.

[15] S. Hester, "janitor: Simple Tools for Examining and Cleaning Dirty Data," R package, 2026.

---

## Appendix A: Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Language | R | 4.6.1 |
| Framework | Shiny | 1.14.0 |
| Theming | bslib | 0.12.0 |
| Data Manipulation | dplyr | 1.2.1 |
| CSV I/O | readr | 2.2.0 |
| Column Cleaning | janitor | 2.2.1 |
| Date Processing | lubridate | 1.9.5 |
| Statistical Graphics | ggplot2 | 4.0.3 |
| Interactive Charts | plotly | 4.12.1 |
| Data Tables | DT | 0.34.0 |
| HTTP Client | httr2 | 1.3.0 |
| Utility | purrr, scales, zoo, jsonlite | Latest |

---

## Appendix B: Installation and Usage

```r
# Install dependencies
install.packages(c(
  "shiny", "bslib", "dplyr", "readr",
  "janitor", "lubridate", "ggplot2",
  "plotly", "DT", "httr2", "jsonlite",
  "purrr", "stringr", "scales", "zoo",
  "htmltools", "bsicons", "tibble"
))

# Run the application
shiny::runApp()
```

---

*Document generated: October 23, 2026*
*CyberShield v1.0 — Academic Data Visualization Project*
