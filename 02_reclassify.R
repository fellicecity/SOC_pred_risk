# =============================================================================
# 02_reclassify.R — Tertile Reclassification to Ordinal 1–3 Scale
# =============================================================================
# Reclassifies SOC, flood susceptibility, and landslide susceptibility rasters
# from their native continuous scales into a common ordinal 1–3 scale using
# quantile tertile breaks (0th, 33rd, 66th, 100th percentiles).
#
# This step is critical for ensuring all inputs are commensurable before the
# weighted overlay in 03_overlay.R. Without it, layers on different native
# scales (e.g., FSI 1–5 vs SOC 0–15%) would produce meaningless composites.
#
# Reference: Malczewski (1999) — GIS and Multicriteria Decision Analysis
#
# Inputs:  soc_1m, flood_1m, landslide_1m  (from 01_load_align.R)
# Outputs: soc_classes, flood_classes, landslide_classes (ordinal SpatRasters)
# Dependencies: terra
# =============================================================================

library(terra)
source("config.R")

# Run Step 01 if objects not already in environment
if (!exists("soc_1m")) source("01_load_align.R")

# ------------------------------------------------------------------------------
# Helper: reclassify any continuous raster into 1/2/3 using tertile breaks
# ------------------------------------------------------------------------------
reclassify_tertiles <- function(r, layer_name = "") {
  breaks <- as.numeric(global(r, fun = quantile,
                              probs = c(0, 0.33, 0.66, 1),
                              na.rm = TRUE))
  message(sprintf("  %s tertile breaks: %.4f | %.4f | %.4f | %.4f",
                  layer_name, breaks[1], breaks[2], breaks[3], breaks[4]))

  m <- matrix(c(-Inf,       breaks[2], 1,
                breaks[2],  breaks[3], 2,
                breaks[3],  Inf,       3),
              ncol = 3, byrow = TRUE)

  classify(r, m, include.lowest = TRUE)
}

# ------------------------------------------------------------------------------
# Reclassify all three layers
# ------------------------------------------------------------------------------
message("Reclassifying layers to ordinal 1–3 scale...")
soc_classes       <- reclassify_tertiles(soc_1m,       "SOC")
landslide_classes <- reclassify_tertiles(landslide_1m, "Landslide")
flood_classes     <- reclassify_tertiles(flood_1m,     "Flood")

# ------------------------------------------------------------------------------
# Sanity check — all three should range 1–3
# ------------------------------------------------------------------------------
layers <- list(SOC = soc_classes, Landslide = landslide_classes, Flood = flood_classes)
for (nm in names(layers)) {
  rng <- as.numeric(global(layers[[nm]], fun = "range", na.rm = TRUE))
  stopifnot(
    sprintf("%s class min is not 1", nm) = rng[1] == 1,
    sprintf("%s class max is not 3", nm) = rng[2] == 3
  )
  cat(sprintf("  %-12s class range: %d – %d  ✓\n", nm, rng[1], rng[2]))
}

message("Step 02 complete. Run 03_overlay.R next.")
