# =============================================================================
# 01_load_align.R — Load and Align Input Rasters
# =============================================================================
# Loads the 1m SOC prediction raster and both hazard susceptibility layers,
# then resamples hazard layers to exactly match the SOC master grid
# (extent, resolution, CRS) using nearest-neighbour resampling to preserve
# ordinal class values.
#
# Outputs: soc_1m, flood_1m, landslide_1m (in-memory SpatRasters)
# Dependencies: terra
# =============================================================================

library(terra)
source("config.R")

# ------------------------------------------------------------------------------
# 1. Load master SOC raster (1m resolution, Random Forest prediction)
# ------------------------------------------------------------------------------
message("Loading SOC raster...")
soc_1m <- rast(path_soc)
message(sprintf("  SOC loaded: %d cols x %d rows | CRS: %s",
                ncol(soc_1m), nrow(soc_1m), crs(soc_1m, describe = TRUE)$code))

# ------------------------------------------------------------------------------
# 2. Load raw hazard susceptibility rasters
# ------------------------------------------------------------------------------
message("Loading flood and landslide susceptibility rasters...")
flood_raw     <- rast(path_flood)
landslide_raw <- rast(path_landslide)

# ------------------------------------------------------------------------------
# 3. Resample hazard layers to match the SOC 1m grid
# method = "near" preserves class integer values (no interpolation artefacts)
# ------------------------------------------------------------------------------
message("Resampling hazard layers to 1m SOC grid (nearest-neighbour)...")
flood_1m     <- resample(flood_raw,     soc_1m, method = "near")
landslide_1m <- resample(landslide_raw, soc_1m, method = "near")

# ------------------------------------------------------------------------------
# 4. Quick alignment check
# ------------------------------------------------------------------------------
stopifnot(
  "Flood extent does not match SOC grid"     = ext(flood_1m)     == ext(soc_1m),
  "Landslide extent does not match SOC grid" = ext(landslide_1m) == ext(soc_1m)
)
message("Alignment check passed — all layers share the same 1m grid.")

# ------------------------------------------------------------------------------
# 5. Print summary
# ------------------------------------------------------------------------------
cat("\n--- Layer Summary ---\n")
cat(sprintf("SOC raster:       %.4f – %.4f %%\n",
            as.numeric(global(soc_1m,       fun = "min", na.rm = TRUE)),
            as.numeric(global(soc_1m,       fun = "max", na.rm = TRUE))))
cat(sprintf("Flood index:      %.4f – %.4f\n",
            as.numeric(global(flood_1m,     fun = "min", na.rm = TRUE)),
            as.numeric(global(flood_1m,     fun = "max", na.rm = TRUE))))
cat(sprintf("Landslide index:  %.4f – %.4f\n",
            as.numeric(global(landslide_1m, fun = "min", na.rm = TRUE)),
            as.numeric(global(landslide_1m, fun = "max", na.rm = TRUE))))

message("Step 01 complete. Run 02_reclassify.R next.")
