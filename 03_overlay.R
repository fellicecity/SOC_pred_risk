# =============================================================================
# 03_overlay.R — Weighted Overlay and Risk Zone Classification
# =============================================================================
# Combines the three ordinal (1–3) reclassified layers into a single Carbon
# Risk Index using AHP-derived weights, then classifies the composite into
# three risk zones (Low / Moderate / High) using equal-interval thresholds.
#
# Also produces separate single-hazard risk overlays (landslide-only and
# flood-only) for disaggregated reporting.
#
# Composite index range: min = 1.0 (all low), max = 3.0 (all high)
# Zone thresholds: Low < 1.667 | Moderate 1.667–2.333 | High > 2.333
#
# Weights (set in config.R):
#   SOC: 0.40 | Landslide: 0.40 | Flood: 0.20
#
# Inputs:  soc_classes, landslide_classes, flood_classes (from 02_reclassify.R)
# Outputs: carbon_at_risk, final_risk_zones, ls_zones, fl_zones (.tif files)
# Dependencies: terra
# =============================================================================

library(terra)
source("config.R")

# Run upstream steps if objects not already in environment
if (!exists("soc_classes")) source("02_reclassify.R")

# ------------------------------------------------------------------------------
# 1. Weighted composite Carbon Risk Index
# ------------------------------------------------------------------------------
message("Computing weighted composite Carbon Risk Index...")
carbon_at_risk <- (soc_classes       * weight_soc)       +
                  (landslide_classes * weight_landslide)  +
                  (flood_classes     * weight_flood)

writeRaster(carbon_at_risk, path_out_carbon_risk, overwrite = TRUE)
message(sprintf("  Composite saved: %s", path_out_carbon_risk))
cat(sprintf("  Composite range: %.3f – %.3f\n",
            as.numeric(global(carbon_at_risk, fun = "min", na.rm = TRUE)),
            as.numeric(global(carbon_at_risk, fun = "max", na.rm = TRUE))))

# ------------------------------------------------------------------------------
# 2. Classify composite into three risk zones
# ------------------------------------------------------------------------------
message("Classifying into Low / Moderate / High risk zones...")
risk_matrix <- matrix(c(-Inf,               threshold_low_mod,  1,
                         threshold_low_mod,  threshold_mod_high, 2,
                         threshold_mod_high, Inf,                3),
                      ncol = 3, byrow = TRUE)

final_risk_zones <- classify(carbon_at_risk, risk_matrix, include.lowest = TRUE)
writeRaster(final_risk_zones, path_out_risk_zones, overwrite = TRUE)
message(sprintf("  Risk zones saved: %s", path_out_risk_zones))

# Pixel count summary
pixel_counts <- freq(final_risk_zones)

summary_table <- data.frame(
  Risk_Category = c("Low Risk", "Moderate Risk", "High Risk"),
  Total_Area_Ha = round(c(
    sum(pixel_counts$count[pixel_counts$value == 1], na.rm = TRUE) / 10000,
    sum(pixel_counts$count[pixel_counts$value == 2], na.rm = TRUE) / 10000,
    sum(pixel_counts$count[pixel_counts$value == 3], na.rm = TRUE) / 10000
  ), 2)
)
summary_table$Percentage <- round(
  (summary_table$Total_Area_Ha / sum(summary_table$Total_Area_Ha)) * 100, 2
)

cat("\n=== MULTI-HAZARD CARBON RISK SUMMARY ===\n")
print(summary_table, row.names = FALSE)
write.csv(summary_table, path_out_summary_csv, row.names = FALSE)

# ------------------------------------------------------------------------------
# 3. Single-hazard overlays (landslide-only and flood-only)
# ------------------------------------------------------------------------------
message("Computing single-hazard overlays...")

# Landslide-only: SOC (40%) + LSI (60%)
ls_risk  <- (soc_classes * weight_soc_single) + (landslide_classes * weight_hazard_single)
ls_zones <- classify(ls_risk, risk_matrix, include.lowest = TRUE)
writeRaster(ls_zones, path_out_ls_zones, overwrite = TRUE)

ls_counts  <- freq(ls_zones)
ls_summary <- data.frame(
  Risk_Category = c("Low Risk", "Moderate Risk", "High Risk"),
  Total_Area_Ha = round(c(
    sum(ls_counts$count[ls_counts$value == 1], na.rm = TRUE) / 10000,
    sum(ls_counts$count[ls_counts$value == 2], na.rm = TRUE) / 10000,
    sum(ls_counts$count[ls_counts$value == 3], na.rm = TRUE) / 10000
  ), 2)
)
ls_summary$Percentage <- round(
  (ls_summary$Total_Area_Ha / sum(ls_summary$Total_Area_Ha)) * 100, 2
)
write.csv(ls_summary, path_out_ls_csv, row.names = FALSE)

# Flood-only: SOC (40%) + FSI (60%)
fl_risk  <- (soc_classes * weight_soc_single) + (flood_classes * weight_hazard_single)
fl_zones <- classify(fl_risk, risk_matrix, include.lowest = TRUE)
writeRaster(fl_zones, path_out_fl_zones, overwrite = TRUE)

fl_counts  <- freq(fl_zones)
fl_summary <- data.frame(
  Risk_Category = c("Low Risk", "Moderate Risk", "High Risk"),
  Total_Area_Ha = round(c(
    sum(fl_counts$count[fl_counts$value == 1], na.rm = TRUE) / 10000,
    sum(fl_counts$count[fl_counts$value == 2], na.rm = TRUE) / 10000,
    sum(fl_counts$count[fl_counts$value == 3], na.rm = TRUE) / 10000
  ), 2)
)
fl_summary$Percentage <- round(
  (fl_summary$Total_Area_Ha / sum(fl_summary$Total_Area_Ha)) * 100, 2
)
write.csv(fl_summary, path_out_fl_csv, row.names = FALSE)

cat("\n=== LANDSLIDE-ONLY CARBON RISK ===\n"); print(ls_summary, row.names = FALSE)
cat("\n=== FLOOD-ONLY CARBON RISK ===\n");     print(fl_summary, row.names = FALSE)

message("Step 03 complete. Run 04_carbon_stock.R next.")
