user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
.libPaths(c(user_lib, .libPaths()))
setwd("D:/new_ajay/CyberShield")

suppressPackageStartupMessages({
  library(officer)
  library(xml2)
})

cat("=== Building VIT Front Page ===\n\n")

doc <- read_docx()

# ── Helper: add centered paragraph with formatting ─────────────────────────
add_centered <- function(doc, text, bold = TRUE, italic = FALSE,
                         size_pt = 24, font = "Times New Roman",
                         space_before = 0, space_after = 0) {
  doc <- body_add_par(doc, text)
  
  # Get the last paragraph and format it
  body <- doc$doc_obj$get()
  paras <- xml_find_all(body, ".//w:p")
  last_para <- paras[[length(paras)]]
  
  # Create paragraph properties
  pPr <- xml_child(last_para, "w:pPr")
  if (is.null(pPr)) {
    pPr <- xml_add_child(last_para, "w:pPr", .where = 0)
  }
  
  # Alignment: center
  jc <- xml_child(pPr, "w:jc")
  if (is.null(jc)) {
    jc <- xml_add_child(pPr, "w:jc")
  }
  xml_set_attr(jc, "w:val", "center")
  
  # Spacing
  spacing <- xml_child(pPr, "w:spacing")
  if (is.null(spacing)) {
    spacing <- xml_add_child(pPr, "w:spacing")
  }
  xml_set_attr(spacing, "w:before", as.character(space_before))
  xml_set_attr(spacing, "w:after", as.character(space_after))
  xml_set_attr(spacing, "w:line", "240")  # single spacing
  xml_set_attr(spacing, "w:lineRule", "auto")
  
  # Run properties (font, size, bold)
  runs <- xml_find_all(last_para, ".//w:r")
  if (length(runs) > 0) {
    run <- runs[[1]]
    rPr <- xml_child(run, "w:rPr")
    if (is.null(rPr)) {
      rPr <- xml_add_child(run, "w:rPr", .where = 0)
    }
    
    # Font
    rFonts <- xml_child(rPr, "w:rFonts")
    if (is.null(rFonts)) {
      rFonts <- xml_add_child(rPr, "w:rFonts", .where = 0)
    }
    xml_set_attr(rFonts, "w:ascii", font)
    xml_set_attr(rFonts, "w:hAnsi", font)
    
    # Size
    sz <- xml_child(rPr, "w:sz")
    if (is.null(sz)) {
      sz <- xml_add_child(rPr, "w:sz")
    }
    xml_set_attr(sz, "w:val", as.character(size_pt * 2))  # half-points
    
    szCs <- xml_child(rPr, "w:szCs")
    if (is.null(szCs)) {
      szCs <- xml_add_child(rPr, "w:szCs")
    }
    xml_set_attr(szCs, "w:val", as.character(size_pt * 2))
    
    # Bold
    if (bold) {
      b <- xml_child(rPr, "w:b")
      if (is.null(b)) {
        xml_add_child(rPr, "w:b")
      }
    }
    
    # Italic
    if (italic) {
      i <- xml_child(rPr, "w:i")
      if (is.null(i)) {
        xml_add_child(rPr, "w:i")
      }
    }
  }
  
  doc
}

# ── Build the document ─────────────────────────────────────────────────────

# VIT Header Image
doc <- doc |> body_add_img("report/vit_header.png", width = 6.0, height = 1.65)
doc <- doc |> body_add_par("")

# School info lines (centered, bold, 12pt)
school_lines <- c(
  "School of Computer Science Engineering and Information Systems",
  "5Yr Integrated M.Tech(Software Engineering)",
  "ISWE415L : Cyber Security",
  "FALL 2026-2027"
)

for (line in school_lines) {
  doc <- doc |> add_centered(line, bold = TRUE, size_pt = 12)
}

doc <- doc |> body_add_par("")

# Course Project Report (centered, bold, 16pt)
doc <- doc |> add_centered("Course Project Report", bold = TRUE, size_pt = 16,
                           space_before = 200, space_after = 200)

doc <- doc |> body_add_par("")

# Project Title (centered, bold, 14pt)
doc <- doc |> add_centered(
  "CyberShield: Interactive Cyber Vulnerability Intelligence and Risk Analytics Dashboard",
  bold = TRUE, size_pt = 14, space_before = 100, space_after = 100
)

doc <- doc |> body_add_par("")

# Submitted for the Course
doc <- doc |> add_centered("Submitted for the Course:  ISWE415L : Cyber Security",
                           bold = TRUE, size_pt = 12)

doc <- doc |> body_add_par("")

# Offered by
doc <- doc |> add_centered("Offered by Dr. R. K. NADESH during FALL 2026-2027",
                           bold = TRUE, size_pt = 12)

doc <- doc |> body_add_par("")
doc <- doc |> body_add_par("")

# By (centered, bold, italic)
doc <- doc |> add_centered("By", bold = TRUE, italic = TRUE, size_pt = 14)

doc <- doc |> body_add_par("")
doc <- doc |> body_add_par("")

# Student names (left-aligned in a 2-column layout)
# Using a simple table via flextable
suppressPackageStartupMessages(library(flextable))

students <- data.frame(
  Name = c("[Student Name 1]", "[Student Name 2]", "[Student Name 3]"),
  RegNo = c("[Reg No 1]", "[Reg No 2]", "[Reg No 3]"),
  stringsAsFactors = FALSE
)

ft <- flextable(students) |>
  align(align = "left", part = "all") |>
  fontsize(size = 12, part = "all") |>
  font(fontname = "Times New Roman", part = "all") |>
  bold(part = "all") |>
  padding(padding = 3, part = "all") |>
  border_remove() |>
  set_table_properties(width = 0.7)

doc <- doc |> body_add_flextable(ft)

doc <- doc |> body_add_par("")
doc <- doc |> body_add_par("")

# Date
doc <- doc |> add_centered("October 2026", bold = TRUE, size_pt = 12)

# ── Save ────────────────────────────────────────────────────────────────────
output <- "report/VIT_Front_Page.docx"
print(doc, target = output)

cat("\n=== Front page created ===\n")
cat("File:", output, "\n")
cat("Size:", file.size(output), "bytes\n")
