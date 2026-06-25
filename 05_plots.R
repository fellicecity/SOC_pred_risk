# =============================================================================
# 05_plots.R — Visualisation: SOC Prediction Map and Carbon Risk Summary Plots
# =============================================================================
# Produces two publication-ready figures:
#
#   Figure 1 — Predicted SOC (%) map (continuous, downsampled to 5m for display)
#   Figure 2 — Three-panel composite:
#               (a) Spatial risk zone map
#               (b) Bar chart — area (ha) per risk zone
#               (c) Violin + boxplot — SOC distribution per risk zone
#
# All raster-to-dataframe conversions use aggregate() + as.data.frame() to
# avoid tidyterra dependency, matching the approach used in the LSI pipeline.
#
# Inputs:  soc_1m, final_risk_zones, summary_table (from 03_overlay.R/04_carbon_stock.R)
# Outputs: Predicted_SOC_Map.png, Carbon_Risk_Summary_Plots.png
# Dependencies: terra, ggplot2, patchwork, scales
# =============================================================================

library(terra)
library(ggplot2)
library(patchwork)
library(scales)
source("config.R")

# Run upstream steps if objects not already in environment
if (!exists("final_risk_zones")) source("03_overlay.R")
if (!exists("summary_table"))    source("04_carbon_stock.R")

# =============================================================================
# FIGURE 1: Predicted SOC (%) — continuous map
# =============================================================================
message("Rendering predicted SOC map...")

soc_agg <- aggregate(soc_1m, fact = 5, fun = "mean")
soc_df  <- as.data.frame(soc_agg, xy = TRUE, na.rm = TRUE)
colnames(soc_df) <- c("x", "y", "SOC_pct")

p_soc <- ggplot(soc_df, aes(x = x, y = y, fill = SOC_pct)) +
  geom_raster() +
  scale_fill_gradientn(
    colours = c("#f7fbff", "#9ecae1", "#2171b5",
                "#74c476", "#006d2c",
                "#fdcc8a", "#d7301f"),
    name    = "SOC (%)",
    na.value = "transparent",
    guide   = guide_colorbar(
      barwidth       = 12,
      barheight      = 0.8,
      title.position = "top",
      title.hjust    = 0.5
    )
  ) +
  coord_equal() +
  labs(
    title    = "Predicted Soil Organic Carbon (0–7.5 cm)",
    subtitle = "Hawke's Bay planted forests | Random Forest prediction | 1 m resolution",
    caption  = "SOC values represent topsoil organic carbon concentration (%)"
  ) +
  theme_void(base_size = 11) +
  theme(
    plot.title      = element_text(face = "bold", size = 13),
    plot.subtitle   = element_text(colour = "grey40", size = 10),
    plot.caption    = element_text(colour = "grey50", size = 8),
    legend.position = "bottom",
    legend.title    = element_text(face = "bold")
  )

ggsave(path_out_soc_map_png, plot = p_soc,
       width = 10, height = 9, dpi = plot_dpi)
message(sprintf("  SOC map saved: %s", path_out_soc_map_png))

# =============================================================================
# FIGURE 2a: Spatial risk zone map
# =============================================================================
message("Rendering risk zone map...")

zones_agg <- aggregate(final_risk_zones, fact = 5, fun = "modal")
map_df    <- as.data.frame(zones_agg, xy = TRUE, na.rm = TRUE)
colnames(map_df) <- c("x", "y", "Risk_Zone")
map_df$Risk_Zone <- factor(map_df$Risk_Zone, levels = 1:3,
                           labels = c("Low Risk", "Moderate Risk", "High Risk"))

p_map <- ggplot(map_df, aes(x = x, y = y, fill = Risk_Zone)) +
  geom_raster() +
  scale_fill_manual(values = risk_colours, na.value = "transparent",
                    name = "Risk Zone") +
  coord_equal() +
  labs(
    title    = "Carbon at Risk — Multi-Hazard Risk Zones",
    subtitle = "Hawke's Bay planted forests | 1 m resolution",
    caption  = "Composite index: SOC (40%) + LSI (40%) + FSI (20%)"
  ) +
  theme_void(base_size = 11) +
  theme(
    plot.title      = element_text(face = "bold", size = 13),
    plot.subtitle   = element_text(colour = "grey40", size = 10),
    plot.caption    = element_text(colour = "grey50", size = 8),
    legend.position = "bottom",
    legend.title    = element_text(face = "bold")
  )

# =============================================================================
# FIGURE 2b: Bar chart — area per risk zone
# =============================================================================
p_bar <- ggplot(summary_table,
                aes(x = Risk_Category, y = Total_Area_Ha, fill = Risk_Category)) +
  geom_col(width = 0.6, colour = "white") +
  geom_text(aes(label = paste0(Percentage, "%")),
            vjust = -0.4, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = risk_colours, guide = "none") +
  scale_y_continuous(labels = comma,
                     expand = expansion(mult = c(0, 0.12))) +
  labs(title = "Area by Risk Zone", x = NULL, y = "Total Area (ha)") +
  theme_classic(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 12))

# =============================================================================
# FIGURE 2c: SOC distribution violin + boxplot by risk zone
# Safer approach: stack rasters and sample together to preserve spatial pairing
# =============================================================================
message(sprintf("Sampling %d pixels for violin plot...", n_sample_violin))
set.seed(mc_seed)

stack     <- c(soc_1m, final_risk_zones)
sample_df <- as.data.frame(
  spatSample(stack, size = n_sample_violin, method = "random", na.rm = TRUE)
)
colnames(sample_df) <- c("SOC_pct", "Risk_Zone")
sample_df$Risk_Zone <- factor(sample_df$Risk_Zone, levels = 1:3,
                              labels = c("Low Risk", "Moderate Risk", "High Risk"))
sample_df <- na.omit(sample_df)

p_violin <- ggplot(sample_df, aes(x = Risk_Zone, y = SOC_pct, fill = Risk_Zone)) +
  geom_violin(alpha = 0.7, colour = "white", trim = TRUE) +
  geom_boxplot(width = 0.12, outlier.shape = NA, colour = "grey20", fill = "white") +
  scale_fill_manual(values = risk_colours, guide = "none") +
  labs(title = "SOC Distribution by Risk Zone", x = NULL, y = "SOC (%)") +
  theme_classic(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 12))

# =============================================================================
# COMBINE & SAVE FIGURE 2
# =============================================================================
combined_plot <- p_map / (p_bar | p_violin) +
  plot_layout(heights = c(2, 1)) +
  plot_annotation(
    tag_levels = "a",
    theme = theme(plot.tag = element_text(face = "bold"))
  )

ggsave(path_out_plots_png, plot = combined_plot,
       width = plot_width, height = plot_height, dpi = plot_dpi)
message(sprintf("  Summary plots saved: %s", path_out_plots_png))

message("Step 05 complete. All outputs saved.")
