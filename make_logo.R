user_lib <- file.path(Sys.getenv("USERPROFILE"), "R", "R-library")
.libPaths(c(user_lib, .libPaths()))
setwd("D:/new_ajay/CyberShield")

suppressPackageStartupMessages({
  library(grid)
})

dir.create("report", showWarnings = FALSE)

# ── VIT Emblem using grid graphics ───────────────────────────────────────────
png("report/vit_emblem.png", width = 450, height = 450, res = 300, bg = "white")

# Navy color
navy <- "#1B1464"

# Draw concentric circles
grid.circle(x = 0.5, y = 0.5, r = 0.48, gp = gpar(fill = navy, col = navy))
grid.circle(x = 0.5, y = 0.5, r = 0.43, gp = gpar(fill = "white", col = "white"))
grid.circle(x = 0.5, y = 0.5, r = 0.40, gp = gpar(fill = navy, col = navy))
grid.circle(x = 0.5, y = 0.5, r = 0.28, gp = gpar(fill = "white", col = "white"))

# Tower body (rectangle)
grid.rect(x = 0.5, y = 0.48, width = 0.10, height = 0.18,
          gp = gpar(fill = navy, col = navy))

# Tower roof (triangle using polygon)
grid.polygon(x = c(0.42, 0.58, 0.50), y = c(0.57, 0.57, 0.68),
             gp = gpar(fill = navy, col = navy))

# Tower door
grid.rect(x = 0.5, y = 0.42, width = 0.04, height = 0.06,
          gp = gpar(fill = "white", col = "white"))

# Water waves
grid.lines(x = c(0.25, 0.75), y = c(0.36, 0.36),
           gp = gpar(col = "white", lwd = 1.5))
grid.lines(x = c(0.28, 0.72), y = c(0.32, 0.32),
           gp = gpar(col = "white", lwd = 1.2))
grid.lines(x = c(0.31, 0.69), y = c(0.28, 0.28),
           gp = gpar(col = "white", lwd = 1.0))

# "VIT" text at top
grid.text("VIT", x = 0.5, y = 0.76,
          gp = gpar(fontface = "bold", fontsize = 16, col = "white",
                    fontfamily = "serif"))

# Year text at bottom
grid.text("1984", x = 0.5, y = 0.20,
          gp = gpar(fontface = "bold", fontsize = 7, col = "white"))

dev.off()
cat("[OK] vit_emblem.png\n")

# ── VIT Header Banner (emblem + text side by side) ─────────────────────────
png("report/vit_header.png", width = 1800, height = 500, res = 300, bg = "white")

# Left: small emblem
# Redraw emblem in left portion
pushViewport(viewport(x = 0.12, y = 0.5, width = 0.2, height = 0.8))

# Navy circle
grid.circle(x = 0.5, y = 0.5, r = 0.45, gp = gpar(fill = navy, col = navy))
grid.circle(x = 0.5, y = 0.5, r = 0.40, gp = gpar(fill = "white", col = "white"))
grid.circle(x = 0.5, y = 0.5, r = 0.37, gp = gpar(fill = navy, col = navy))
grid.circle(x = 0.5, y = 0.5, r = 0.25, gp = gpar(fill = "white", col = "white"))

# Tower
grid.rect(x = 0.5, y = 0.48, width = 0.10, height = 0.16,
          gp = gpar(fill = navy, col = navy))
grid.polygon(x = c(0.42, 0.58, 0.50), y = c(0.56, 0.56, 0.66),
             gp = gpar(fill = navy, col = navy))
grid.rect(x = 0.5, y = 0.42, width = 0.04, height = 0.06,
          gp = gpar(fill = "white", col = "white"))

# Waves
grid.lines(x = c(0.28, 0.72), y = c(0.36, 0.36), gp = gpar(col = "white", lwd = 1.2))
grid.lines(x = c(0.31, 0.69), y = c(0.32, 0.32), gp = gpar(col = "white", lwd = 1.0))

# VIT text
grid.text("VIT", x = 0.5, y = 0.74,
          gp = gpar(fontface = "bold", fontsize = 12, col = "white",
                    fontfamily = "serif"))

popViewport()

# Right: text block
pushViewport(viewport(x = 0.6, y = 0.5, width = 0.7, height = 0.9))

# VIT large text
grid.text("VIT", x = 0.35, y = 0.75, just = "left",
          gp = gpar(fontface = "bold", fontsize = 52, col = navy,
                    fontfamily = "serif"))

# Registered trademark
grid.text("\u00AE", x = 0.58, y = 0.82, just = "left",
          gp = gpar(fontsize = 14, col = navy))

# Horizontal line
grid.lines(x = c(0.0, 1.0), y = c(0.52, 0.52),
           gp = gpar(col = "black", lwd = 2))

# University name
grid.text("Vellore Institute of Technology", x = 0.5, y = 0.38, just = "center",
          gp = gpar(fontface = "bold", fontsize = 16, col = "black"))

# Subtitle
grid.text("(Deemed to be University under section 3 of UGC Act, 1956)",
          x = 0.5, y = 0.22, just = "center",
          gp = gpar(fontsize = 9, col = "black"))

popViewport()

dev.off()
cat("[OK] vit_header.png\n")

cat("\n=== Logo assets ready ===\n")
print(list.files("report", pattern = "\\.png$"))
