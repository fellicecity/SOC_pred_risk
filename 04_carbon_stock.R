# =============================================================================
# 04_carbon_stock.R — Carbon Stock Quantification and Uncertainty Analysis
# =============================================================================
# Converts the continuous SOC (%) raster to t C/ha using bulk density and
# sampling depth, then quantifies total carbon stocks within each risk zone.
# Uncertainty in the Random Forest SOC prediction is propagated through a
# Monte Carlo simulation to produce 95% confidence intervals.
#
# Conversion formula (Poeplau et al. 2017):
#   SOC (t C/ha) = SOC (%) / 100 × bulk density (t/m³) × depth (m) × 10,000
#
# Parameters (set in config.R):
#   bulk_density = 0.9 t/m³  (Beare et al. 2014, NZ topsoils)
#   depth_m      = 0.075 m   (0–7.5 cm sampling layer)
#   rmse_pct     = 0.30      (relative RMSE — UPDATE with your model value)
#   n_sims       = 1000
#
# Inputs:  soc_1m, final_risk_zones (from 03_overlay.R)
# Outputs: printed paragraph fill values; soc_tcha raster (in-memory)
# Dependencies: terra
# =============================================================================

library(terra)
source("config.R")

# Run upstream steps if objects not already in environment
if (!exists("final_risk_zones")) source("03_overlay.R")

# ------------------------------------------------------------------------------
# 1. Convert SOC (%) → t C/ha per pixel
# ------------------------------------------------------------------------------
message("Converting SOC (%) to t C/ha...")
soc_tcha <- soc_1m / 100 * bulk_density * depth_m * 10000

cat(sprintf("  Bulk density:  %.2f t/m³\n",  bulk_density))
cat(sprintf("  Sampling depth: %.4f m (%.1f cm)\n", depth_m, depth_m * 100))
cat(sprintf("  SOC t C/ha range: %.3f – %.3f\n",
            as.numeric(global(soc_tcha, fun = "min", na.rm = TRUE)),
            as.numeric(global(soc_tcha, fun = "max", na.rm = TRUE))))

# ------------------------------------------------------------------------------
# 2. Sum and mean SOC stocks per risk zone
# Each pixel = 1m × 1m = 0.0001 ha
# ------------------------------------------------------------------------------
message("Summing carbon stocks per risk zone...")
pixel_area_ha <- 0.0001

sum_zone <- function(zone_val) {
  masked <- mask(soc_tcha, final_risk_zones == zone_val, maskvalues = FALSE)
  global(masked, fun = "sum",  na.rm = TRUE)[[1]] * pixel_area_ha
}

mean_zone <- function(zone_val) {
  masked <- mask(soc_tcha, final_risk_zones == zone_val, maskvalues = FALSE)
  global(masked, fun = "mean", na.rm = TRUE)[[1]]
}

soc_sum_low      <- sum_zone(1)
soc_sum_moderate <- sum_zone(2)
soc_sum_high     <- sum_zone(3)
soc_sum_total    <- soc_sum_low + soc_sum_moderate + soc_sum_high

soc_mean_low      <- mean_zone(1)
soc_mean_moderate <- mean_zone(2)
soc_mean_high     <- mean_zone(3)

cat(sprintf("\nMean SOC (t C/ha):  Low = %.2f | Moderate = %.2f | High = %.2f\n",
            soc_mean_low, soc_mean_moderate, soc_mean_high))
cat(sprintf("Total SOC — Low:      %12.0f t C\n", soc_sum_low))
cat(sprintf("Total SOC — Moderate: %12.0f t C\n", soc_sum_moderate))
cat(sprintf("Total SOC — High:     %12.0f t C\n", soc_sum_high))
cat(sprintf("Total SOC — All zones:%12.0f t C\n", soc_sum_total))

# ------------------------------------------------------------------------------
# 3. Monte Carlo 95% CI for High Risk zone SOC
# Propagates RF prediction uncertainty (RMSE-based, multiplicative noise)
# ------------------------------------------------------------------------------
message(sprintf("Running %d Monte Carlo simulations (rmse_pct = %.2f)...", n_sims, rmse_pct))
set.seed(mc_seed)

mc_high  <- replicate(n_sims, soc_sum_high * rnorm(1, mean = 1, sd = rmse_pct))
ci_lower <- quantile(mc_high, 0.025)
ci_upper <- quantile(mc_high, 0.975)

# ------------------------------------------------------------------------------
# 4. Print paragraph fill values for manuscript
# ------------------------------------------------------------------------------
high_pct_area   <- summary_table$Percentage[summary_table$Risk_Category == "High Risk"]
high_pct_carbon <- round((soc_sum_high / soc_sum_total) * 100, 1)

cat("\n")
cat("=======================================================\n")
cat("  MANUSCRIPT PARAGRAPH FILL VALUES\n")
cat("=======================================================\n")
cat(sprintf("  [X]     = %.1f%%   (high-risk area as %% of total)\n", high_pct_area))
cat(sprintf("  [Y]     = %.0f t C  (total SOC in high-risk zone)\n",  soc_sum_high))
cat(sprintf("  [lower] = %.0f t C  (95%% CI lower bound)\n",          ci_lower))
cat(sprintf("  [upper] = %.0f t C  (95%% CI upper bound)\n",          ci_upper))
cat(sprintf("  [Z]     = %.1f%%   (high-risk zone share of total SOC)\n", high_pct_carbon))
cat("=======================================================\n")
cat("  NOTE: Update rmse_pct in config.R with your actual\n")
cat("  RF model RMSE / mean(SOC) before final reporting.\n")
cat("=======================================================\n\n")

message("Step 04 complete. Run 05_plots.R next.")
