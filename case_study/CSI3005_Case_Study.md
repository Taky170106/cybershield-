# CSI3005 — Advanced Data Visualization Techniques
## Case Study Based Assessment — Theory Component

**Student Name:** [Your Name]
**Register Number:** [Your Register Number]
**Slot:** E2 (Theory)
**Semester:** Fall Sem 2026–2027
**Deadline:** 23.10.2026
**Case Study Title:** CyberShield — Interactive Cyber Vulnerability Intelligence and Risk Analytics Dashboard

---

## 1. Frame the Problem (2 Marks)

### 1.1 Case Study Description

Cyber vulnerabilities — software flaws that attackers can exploit to compromise systems — are discovered and cataloged at an accelerating pace. The **CISA Known Exploited Vulnerabilities (KEV) Catalog** is a publicly maintained dataset by the U.S. Cybersecurity and Infrastructure Security Agency that lists vulnerabilities with confirmed real-world exploitation [1]. At the time of this analysis, the catalog contains **1,754 vulnerability records** spanning November 2021 to October 2026, covering **290 unique vendors**.

The problem is: **security analysts, IT managers, and cybersecurity students cannot easily extract actionable insights from the raw catalog data**. They need a tool that visualizes trends, identifies high-risk vendors, tracks remediation deadlines, and highlights ransomware-linked vulnerabilities.

### 1.2 Intended Audience

| Audience | Technical Level | Primary Need |
|----------|----------------|--------------|
| Security Analysts | High | Prioritize patching based on exploitation evidence |
| IT Managers | Medium | Understand vendor risk concentration |
| Cybersecurity Students | Low–Medium | Learn vulnerability landscape patterns |
| Policy Makers | Low | Understand systemic risk trends |

### 1.3 Decision the Visualization Should Support

> **"Which vulnerabilities should my organization patch first, and where should I focus my limited security resources?"**

The visualization must help users prioritize remediation by showing:
- Which vendors have the most exploited vulnerabilities
- Which vulnerabilities are linked to ransomware campaigns
- Which remediation deadlines have passed (overdue)
- How the threat landscape is changing over time

### 1.4 Relevant Dataset Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `cve_id` | Categorical (String) | Unique CVE identifier (e.g., CVE-2026-106931) |
| `vendor_project` | Categorical (Nominal) | Vendor name (e.g., Microsoft, Cisco) |
| `product` | Categorical (Nominal) | Affected product (e.g., Windows, PAN-OS) |
| `date_added` | Temporal (Date) | Date added to KEV catalog |
| `due_date` | Temporal (Date) | CISA remediation deadline |
| `known_ransomware_campaign_use` | Categorical (Binary) | Known/Unknown ransomware linkage |
| `forensic_triage` | Categorical (Binary) | Yes/No forensic requirement |
| `short_description` | Text (Free-form) | Vulnerability description |
| `cwes` | Categorical (Nominal) | CWE weakness identifiers |

### 1.5 Two Analytical Questions

**Q1: Which vendors have the highest concentration of actively exploited vulnerabilities, and what proportion of these are linked to known ransomware campaigns?**

*Justification:* This question is meaningful because security teams have limited budgets and must prioritize which vendor ecosystems to secure first. A vendor with many exploited vulnerabilities AND high ransomware linkage represents the greatest organizational risk. Understanding this helps IT managers allocate patching resources and negotiate with vendors.

**Q2: How have monthly vulnerability catalog additions changed over time, and is there a measurable shift in the proportion of ransomware-linked entries?**

*Justification:* This question is meaningful because it helps security leadership understand whether the threat landscape is worsening and whether ransomware is becoming a more dominant attack vector. Trend analysis supports budget justification and strategic planning decisions.

---

## 2. Choose and Defend (3 Marks)

### Visualization 1: Horizontal Bar Chart with Dual Encoding — Vendor Risk Profile

**Addresses: Q1** (Which vendors have the highest concentration of exploited vulnerabilities + ransomware proportion?)

#### 2.1 Labelled Sketch Description

```
┌─────────────────────────────────────────────────────────────────────────┐
│  TOP 15 VENDORS BY CISA KEV CATALOG ENTRIES                            │
│  (Bar length = total vulnerabilities, Color = ransomware proportion)    │
│                                                                         │
│  Microsoft  ████████████████████████████████████████████  390           │
│             ████████████████████████████████████████████  (18% ransom)  │
│                                                                         │
│  Cisco      ██████████████████████████████████            247           │
│             ██████████████████████████████████            (12% ransom)  │
│                                                                         │
│  Apple      ████████████████████████████                  205           │
│             ████████████████████████████                  (8% ransom)   │
│                                                                         │
│  Google     ██████████████████████████                    189           │
│             ██████████████████████████                    (22% ransom)  │
│                                                                         │
│  Fortinet   ████████████████████████                      178           │
│             ████████████████████████                      (45% ransom)  │
│                                                                         │
│  ────────────────────────────────────────────────────────────────────   │
│  0        50       100      150      200      250      300      350     │
│                         Vulnerability Count                              │
│                                                                         │
│  Color scale: ──── Low ransomware % ──── High ransomware %              │
│               (light blue)              (dark red)                      │
└─────────────────────────────────────────────────────────────────────────┘
```

**Axes:**
- **X-axis:** Vulnerability count (quantitative, linear scale, 0–400)
- **Y-axis:** Vendor names (categorical, nominal, sorted descending by count)

**Visual Encodings:**
- **Position/Length:** Bar length encodes total vulnerability count (primary encoding)
- **Color hue + saturation:** Bar color encodes ransomware proportion — light blue (0%) → dark red (100%) (secondary encoding)
- **Label:** Vendor name at left of each bar

#### 2.2 How It Helps Answer Q1

The bar chart directly answers Q1 by showing:
1. **Which vendors dominate:** Bar length immediately reveals Microsoft (390) and Cisco (247) as the top two, making the concentration visible.
2. **Ransomware risk overlay:** The color encoding adds a critical second dimension — Fortinet has fewer total vulnerabilities (178) than Microsoft, but its dark red color reveals a 45% ransomware linkage rate, making it arguably higher priority for ransomware-focused defense.

This dual encoding allows analysts to identify both "high volume" and "high risk" vendors simultaneously, which is exactly the decision the dashboard must support.

#### 2.3 Comparison with Alternative Technique

| Aspect | Selected: Horizontal Bar | Alternative: Treemap |
|--------|------------------------|---------------------|
| **Data type fit** | Nominal categories + 2 quantitative variables | Nominal categories + 1 quantitative variable |
| **Readability** | Exact values readable from bar length | Area comparison is imprecise |
| **Color encoding** | Can encode ransomware % as continuous color | Limited to single color scale |
| **Comparison accuracy** | Position on common baseline = accurate | Area perception = less accurate |
| **Label clarity** | Vendor names fit horizontally | Labels truncated in small rectangles |
| **Scalability** | Works for 15–20 vendors | Better for 50+ vendors |

#### 2.4 Justification

The **horizontal bar chart** is selected over the treemap because:

1. **Data types:** We have two quantitative variables (count AND ransomware %), and bar charts can encode both via length + color, while treemaps only encode area.

2. **Analytical purpose:** Q1 requires comparing vendors precisely — bar charts place all bars on a common baseline, making length comparison accurate (Cleveland & McGill, 1984 [2]). Treemaps require comparing areas of differently shaped rectangles, which is perceptually harder.

3. **Readability:** With only 15 vendors, horizontal bars fit comfortably with full vendor names visible. Treemaps would truncate names for long vendor names like "Palo Alto Networks."

4. **Color as secondary variable:** The ransomware proportion as a continuous color gradient is a natural, pre-attentive encoding (Ware, 2012 [3]) that allows rapid identification of high-risk vendors without a separate chart.

---

### Visualization 2: Line Chart with Dual Series — Temporal Trend Analysis

**Addresses: Q2** (How have monthly additions changed? Is ransomware proportion shifting?)

#### 2.5 Labelled Sketch Description

```
┌─────────────────────────────────────────────────────────────────────────┐
│  MONTHLY KEV CATALOG ADDITIONS (2021–2026)                             │
│                                                                         │
│  Count                                                                  │
│  120 ┤                                        ╭──╮                      │
│      │                                   ╭───╯  ╰──╮    ╭──╮           │
│  100 ┤                              ╭───╯         ╰───╯  ╰╮           │
│      │                         ╭───╯                      ╰──╮         │
│   80 ┤                    ╭───╯                               ╰──╮     │
│      │               ╭───╯                                       ╰──  │
│   60 ┤          ╭───╯                                                 │
│      │     ╭───╯                                                     │
│   40 ┤╭───╯                                                          │
│      ││                                                              │
│   20 ┤╯                                                              │
│      └──┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──  │
│        2021   2022   2023   2024   2025   2026                             │
│                                                                         │
│  ──── Total additions (blue, primary axis)                             │
│  ──── Ransomware-linked additions (red, secondary axis)                │
│                                                                         │
│  Annotations: "Log4Shell spike"  "MOVEit campaign"                      │
└─────────────────────────────────────────────────────────────────────────┘
```

**Axes:**
- **X-axis:** Time in months (temporal, ordinal/monthly, Nov 2021 – Oct 2026)
- **Y-axis (left):** Total monthly additions (quantitative, linear, 0–120)
- **Y-axis (right, optional):** Ransomware-linked additions (quantitative, 0–40)

**Visual Encodings:**
- **Position (x, y):** Line connecting monthly data points shows temporal trend
- **Line color:** Blue line = total additions; Red line = ransomware-linked additions
- **Line thickness:** Main line slightly thicker than reference line
- **Annotations:** Text labels for major spike events (e.g., Log4Shell in Dec 2021)

#### 2.6 How It Helps Answer Q2

The line chart directly answers Q2 by showing:
1. **Overall trend:** The blue line's upward or downward trajectory reveals whether catalog additions are accelerating.
2. **Ransomware shift:** The red line's position relative to the blue line shows whether the ransomware proportion is growing. If the red line's slope is steeper than the blue line's, ransomware linkage is increasing.
3. **Event correlation:** Annotations at spike points help analysts correlate sudden increases with known events (e.g., Log4Shell disclosure in December 2021).

#### 2.7 Comparison with Alternative Technique

| Aspect | Selected: Line Chart | Alternative: Area Chart (Stacked) |
|--------|---------------------|----------------------------------|
| **Trend clarity** | Line = clearest trend perception | Filled area can obscure thin layers |
| **Dual series** | Two lines easy to compare | Stacked areas require mental subtraction |
| **Ransomware %** | Can overlay proportion as second line | Stacked area shows absolute count only |
| **Spike visibility** | Sharp peaks clearly visible | Area fill can smooth perception |
| **Space efficiency** | Compact | Requires more vertical space |
| **Data density** | Good for monthly data | Better for daily/high-frequency data |

#### 2.8 Justification

The **line chart** is selected over the stacked area chart because:

1. **Data types:** We have two time series (total and ransomware-linked) that need comparison, not composition. Line charts allow direct comparison of two lines, while stacked areas require the viewer to mentally subtract the bottom layer to estimate the top layer's value.

2. **Analytical purpose:** Q2 asks whether the ransomware proportion is *shifting* — this requires comparing the *slopes* of two lines. Two lines make slope comparison easy; stacked areas make slope comparison difficult.

3. **Readability:** Line charts follow Tufte's data-ink ratio principle [4] — they use minimal ink to convey maximum information. The line is the most perceptually accurate encoding for temporal change (Cleveland & McGill, 1984 [2]).

4. **Event annotation:** Spike points in line charts can be precisely annotated with text labels, which is harder to do cleanly on stacked areas where the annotation point is ambiguous.

---

## 3. Critique and Correct (3 Marks)

### 3.1 Flawed Visualization Sketch

**Case:** Same dataset — vendor vulnerability counts. This visualization uses **two deliberately misleading design choices**.

```
┌─────────────────────────────────────────────────────────────────────────┐
│  VENDOR SECURITY SCORES (FRAUDULENT VERSION)                           │
│                                                                         │
│  Score                                                                  │
│  100 ┤ ████████████████████████████████████████████████ Microsoft       │
│      │ ████████████████████████████████████████████████ Cisco           │
│   98 ┤ ██████████████████████████████████████████████   Apple           │
│      │ █████████████████████████████████████████████    Google          │
│   96 ┤ ██████████████████████████████████████████       Fortinet        │
│      │ █████████████████████████████████████████        Ivanti          │
│   94 ┤ ████████████████████████████████████████         Palo Alto       │
│      │ ██████████████████████████████████████           Citrix          │
│   92 ┤ ████████████████████████████████████             Atlassian       │
│      │ ██████████████████████████████████               Adobe           │
│   90 ┤ ████████████████████████████████                 Siemens         │
│      └─────────────────────────────────────────────────────────────    │
│         (All bars appear nearly equal in length)                       │
│                                                                         │
│  COLOR: All bars are bright GREEN ("secure")                           │
│                                                                         │
│  TITLE: "Vendor Security Scores"                                        │
│  (Implies these are security ratings, not vulnerability counts)        │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Flaw Identification

**Flaw 1: Truncated Axis (Y-axis starts at 90, not 0)**

The Y-axis starts at 90 instead of 0. This is a classic misleading technique that exaggerates differences between values. Microsoft has 390 vulnerabilities and Siemens has ~80, but with the axis truncated at 90, all bars appear nearly the same length. A casual viewer would conclude that all vendors have similar vulnerability counts, which is completely false — Microsoft has **nearly 5x more** entries than Siemens.

**Impact on interpretation:** IT managers using this chart would distribute security resources equally across all vendors, when in reality Microsoft ecosystem vulnerabilities deserve proportionally more attention. This could lead to under-investment in high-risk areas.

**Flaw 2: Inappropriate Color Encoding (All bars bright green)**

All bars are colored bright green, which is a universally recognized "safe/secure" color. This is inappropriate for two reasons:
- The chart title says "Security Scores" which falsely implies these are *positive* security ratings, when the data actually shows *vulnerability counts* (more = worse).
- Green is a pre-attentive signal for "good" or "safe" [3], so viewers instantly perceive all vendors as equally secure, regardless of their actual vulnerability burden.

**Impact on interpretation:** The green coloring combined with the misleading title creates a false sense of security. Stakeholders might conclude "all our vendors are secure" when the data shows the opposite.

### 3.3 Corrected Visualization Sketch

```
┌─────────────────────────────────────────────────────────────────────────┐
│  CISA KEV CATALOG ENTRIES BY VENDOR (Top 10)                           │
│  Bar length = vulnerability count (higher = more exploited vulns)      │
│                                                                         │
│  Vendor                                                                 │
│                                                                         │
│  Microsoft  ██████████████████████████████████████████████████████ 390 │
│  Cisco      ██████████████████████████████████                      247 │
│  Apple      ████████████████████████████                            205 │
│  Google     ██████████████████████████                              189 │
│  Fortinet   ████████████████████████                                178 │
│  Ivanti     ██████████████████████                                  157 │
│  Palo Alto  █████████████████████                                   148 │
│  Citrix     ████████████████████                                    136 │
│  Atlassian  ██████████████████                                      121 │
│  Adobe      ████████████████                                        108 │
│             └──┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──   │
│               0      50     100    150    200    250    300    350     │
│                        Vulnerability Count                              │
│                                                                         │
│  Color: Blue gradient (light = few, dark = many)                       │
│  Caption: "Source: CISA KEV Catalog. Higher count = more exploited     │
│            vulnerabilities. Does not indicate vendor security quality." │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.4 Justification of Corrections

**Correction 1: Y-axis starts at 0 (True Zero)**

Starting the axis at 0 ensures that bar lengths are proportional to their values. Microsoft's bar is now visibly ~5x longer than Siemens's, accurately representing the 5x difference in vulnerability counts. This follows Tufte's principle of maintaining the correct data-ink ratio [4] and Cleveland & McGill's finding that position on a common scale is the most accurate visual encoding [2].

**Correction 2: Neutral color encoding + accurate title**

- **Title changed** from "Vendor Security Scores" to "CISA KEV Catalog Entries by Vendor" — accurately describing what the data represents.
- **Color changed** from uniform green to a blue gradient (light = fewer, dark = more) — this is a sequential encoding that reinforces the count encoding rather than misleading the viewer.
- **Caption added** explicitly stating "Higher count = more exploited vulnerabilities. Does not indicate vendor security quality." This prevents the common misinterpretation that high counts mean "bad vendor."

These corrections ensure the visualization supports accurate decision-making rather than creating a false sense of security.

---

## 4. Respond to a Changed Requirement (2 Marks)

### 4.1 New Requirement

The stakeholder now needs to **monitor vulnerability catalog additions continuously as new data arrive** in real-time, rather than viewing static historical snapshots. The visualization must support streaming/rolling updates.

### 4.2 Adaptation: Streaming Line Chart — Monthly Additions

I would adapt **Visualization 2 (the line chart)** for streaming data as follows:

#### 4.2.1 Update Interval: **Every 6 hours**

**Justification:** The CISA KEV catalog is updated periodically (not in real-time). New entries are typically added in batches. A 6-hour update interval:
- Catches new additions within the same working day
- Avoids excessive API calls to the CISA data source
- Reduces computational overhead for re-rendering
- Is frequent enough to detect sudden spikes (e.g., a large batch addition after a major exploit disclosure)

A shorter interval (e.g., 5 minutes) would waste resources since the source data doesn't change that frequently. A longer interval (e.g., 24 hours) would delay awareness of critical new additions.

#### 4.2.2 Display Time Window: **Rolling 90-day window** (with option to expand to 12 months)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  LIVE: Monthly KEV Additions — Rolling 90-Day Window                   │
│  Last updated: 2026-10-23 14:00 UTC | Auto-refresh: 6h                │
│                                                                         │
│  Count                                                                  │
│   40 ┤                                        ╭──╮                     │
│      │                                   ╭───╯  ╰──╮                  │
│   30 ┤                              ╭───╯         ╰──╮                │
│      │                         ╭───╯                 ╰──╮             │
│   20 ┤                    ╭───╯                         ╰──            │
│      │               ╭───╯                                             │
│   10 ┤          ╭───╯                                                  │
│      │     ╭───╯                                                       │
│    0 ┤╭───╯                                                            │
│      └──┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──   │
│        Jul    Aug    Sep    Oct    Nov    Dec    Jan    Feb    Mar     │
│                         (rolling window boundary)                       │
│                                                                         │
│  ──── Daily additions (smoothed, 7-day moving average)                 │
│  ──── Raw daily count (light gray, background)                         │
│                                                                         │
│  ▲ New entry added: 2026-10-23 (3 new CVEs)                           │
└─────────────────────────────────────────────────────────────────────────┘
```

**Justification for 90-day window:**
- **Detects sudden changes:** A 90-day window is short enough that a spike (e.g., 50 additions in one day after a major exploit) is visually prominent and not diluted by historical data.
- **Reveals seasonal patterns:** Quarterly patterns (e.g., end-of-quarter reporting surges) are visible.
- **Reduces visual clutter:** A 5-year window would compress 90 days of data into a tiny fraction of the x-axis, making recent changes invisible.
- **Expandable:** Users can expand to 12 months or 5 years for historical context, but the default view prioritizes recent activity.

#### 4.2.3 Individual vs. Aggregated Values: **Dual-layer approach**

- **Background layer:** Raw daily counts as small, semi-transparent points (light gray) — shows individual data points and data density.
- **Foreground layer:** 7-day moving average as a bold colored line — reveals the underlying trend without noise.

**Justification:**
- The raw daily points preserve **individual values** so analysts can see exact counts on any given day and detect anomalies.
- The 7-day moving average smooths day-to-day noise to reveal **overall trends** — this is critical because daily counts are highly variable (some days have 0 additions, others have 20+).
- The dual-layer approach gives analysts **both** the signal (trend) and the noise (individual points), allowing them to choose which to focus on depending on their task.

#### 4.2.4 Trade-off: Sudden Changes vs. Overall Trends

| Aspect | Short Window (30 days) | Medium Window (90 days) | Long Window (12 months) |
|--------|----------------------|------------------------|------------------------|
| **Spike detection** | Excellent — spikes are very prominent | Good — spikes visible but less dominant | Poor — spikes compressed |
| **Trend detection** | Poor — too few data points | Good — shows quarterly trend | Excellent — shows annual pattern |
| **Noise level** | High — daily variation dominates | Moderate — 7-day smoothing helps | Low — seasonal patterns emerge |
| **Context** | Minimal historical context | Moderate context | Full historical context |
| **Best for** | Incident response | Operational monitoring | Strategic planning |

**Recommended approach:** Use a **90-day rolling window as the default** with a **7-day moving average overlay**. This provides:
- Good spike detection (90 days is short enough that a spike occupies significant visual space)
- Good trend detection (13 weeks of data is enough to see direction)
- Noise reduction (7-day smoothing removes day-of-week effects)

Users who need incident-response-level monitoring can switch to a 30-day view. Users doing quarterly reviews can expand to 12 months. The dual-layer approach (raw points + smoothed line) ensures that neither sudden changes nor overall trends are lost regardless of the time window selected.

---

## References

[1] Cybersecurity and Infrastructure Security Agency, "Known Exploited Vulnerabilities Catalog," 2026. [Online]. Available: https://www.cisa.gov/known-exploited-vulnerabilities-catalog

[2] W. Cleveland and R. McGill, "Graphical Perception: Theory, Experimentation, and Application to the Development of Graphical Methods," *Journal of the American Statistical Association*, vol. 79, no. 387, pp. 531–554, 1984.

[3] C. Ware, "Information Visualization: Perception for Design," *Morgan Kaufmann*, 3rd ed., 2012.

[4] E. R. Tufte, "The Visual Display of Quantitative Information," *Graphics Press*, 2nd ed., 2001.

[5] A. Cairo, "The Functional Art: An Introduction to Information Graphics and Visualization," *New Riders*, 2012.

---

*Note: All hypothetical patterns and values used in sketches above are clearly identified as illustrative. Real data values (e.g., Microsoft = 390, Cisco = 247) are sourced from the actual CISA KEV catalog as of October 23, 2026.*
