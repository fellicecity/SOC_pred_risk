# =============================================================================
# config.R — SOC Carbon Risk Framework: Hawke's Bay Planted Forests
# =============================================================================
# All file paths, weights, and parameters are set here.
# Edit this file before running any step script.
# =============================================================================

# ------------------------------------------------------------------------------
# INPUT PATHS
# ------------------------------------------------------------------------------
path_soc        <- "F:/internship/CarbonDataSets/Validation/output/Pred_NZ_SOC_1m.tif"
path_flood      <- "F:/internship/CarbonDataSets/Validation/input/FSI_Raw.tif"
path_landslide  <- "F:/internship/CarbonDataSets/Validation/input/LSI_Raw.tif"

# ------------------------------------------------------------------------------
# OUTPUT DIRECTORY
# ------------------------------------------------------------------------------
dir_output <- "F:/internship/CarbonDataSets/Validation/output/"

# Derived output paths (do not edit unless changing filenames)
path_out_carbon_risk   <- file.path(dir_output, "Carbon_Risk_Index_1m.tif")
path_out_risk_zones    <- file.path(dir_output, "Final_Risk_Zones.tif")
path_out_ls_zones      <- file.path(dir_output, "LSI_Carbon_Risk_Zones.tif")
path_out_fl_zones      <- file.path(dir_output, "FSI_Carbon_Risk_Zones.tif")
path_out_summary_csv   <- file.path(dir_output, "Carbon_Risk_Summary.csv")
path_out_ls_csv        <- file.path(dir_output, "Carbon_Risk_Landslide_Only.csv")
path_out_fl_csv        <- file.path(dir_output, "Carbon_Risk_Flood_Only.csv")
path_out_soc_map_png   <- file.path(dir_output, "Predicted_SOC_Map.png")
path_out_plots_png     <- file.path(dir_output, "Carbon_Risk_Summary_Plots.png")

# ------------------------------------------------------------------------------
# AHP OVERLAY WEIGHTS
# Must sum to 1.0
# ------------------------------------------------------------------------------
weight_soc       <- 0.40   # SOC contribution to composite risk index
weight_landslide <- 0.40   # Landslide susceptibility contribution
weight_flood     <- 0.20   # Flood susceptibility contribution

# Weights for single-hazard overlays (SOC + one hazard only)
weight_soc_single    <- 0.40
weight_hazard_single <- 0.60

# ------------------------------------------------------------------------------
# RISK ZONE THRESHOLDS
# After tertile reclassification, composite ranges 1.0–3.0
# Thresholds divide this range into three equal tiers
# ------------------------------------------------------------------------------
threshold_low_mod  <- 1.667   # Low / Moderate boundary
threshold_mod_high <- 2.333   # Moderate / High boundary

# ------------------------------------------------------------------------------
# CARBON STOCK PARAMETERS
# ------------------------------------------------------------------------------
bulk_density <- 0.9     # t/m³ — topsoil bulk density (Beare et al. 2014, NZ)
depth_m      <- 0.075   # Sampling depth in metres (0–7.5 cm)

# ------------------------------------------------------------------------------
# MONTE CARLO UNCERTAINTY PARAMETERS
# ------------------------------------------------------------------------------
# Replace rmse_pct with your RF model's RMSE divided by mean(SOC)
rmse_pct <- 0.30        # Relative RMSE (30% = conservative estimate)
n_sims   <- 1000        # Number of Monte Carlo simulations
mc_seed  <- 42          # Random seed for reproducibility

# ------------------------------------------------------------------------------
# PLOT SETTINGS
# ------------------------------------------------------------------------------
n_sample_violin <- 200000   # Pixels sampled for violin plot (speed vs. precision)
plot_width      <- 14       # inches
plot_height     <- 12       # inches
plot_dpi        <- 300

# Colour scheme for risk zones (used across all plots)
risk_colours <- c(
  "Low Risk"      = "#2c7bb6",
  "Moderate Risk" = "#fdae61",
  "High Risk"     = "#d7191c"
)
