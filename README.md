# SOC Carbon Risk Framework — Hawke's Bay Planted Forests

A reproducible spatial framework for quantifying soil organic carbon (SOC) exposure risk under compound flood and landslide hazards in Hawke's Bay planted forests, New Zealand. Developed as part of an internship with [Interpine Group](https://www.interpine.nz/) in support of NZ ETS carbon reporting and post-Cyclone Gabrielle forest risk assessment.

---

## Overview

This repository implements a multi-hazard carbon risk index by combining:

- A **Random Forest-predicted SOC map** (0–7.5 cm depth, 1 m resolution) derived from LiDAR-based terrain covariates (DEM, slope, TWI, land cover)
- A **Landslide Susceptibility Index (LSI)** built from an eleven-factor AHP overlay
- A **Flood Susceptibility Index (FSI)** from a separate AHP overlay pipeline

All three layers are reclassified to a common ordinal 1–3 scale via quantile tertile breaks before weighted overlay, ensuring commensurability across inputs with different native scales. Carbon stocks at risk are quantified in t C/ha, with prediction uncertainty propagated via Monte Carlo simulation.

---

## Repository Structure

```
SOC-Carbon-Risk-HawkesBay/
├── config.R            # All paths, weights, and parameters — edit here first
├── 01_load_align.R     # Load SOC, FSI, LSI rasters; resample to 1m SOC grid
├── 02_reclassify.R     # Tertile reclassification → common ordinal 1–3 scale
├── 03_overlay.R        # Weighted AHP composite + risk zone classification
├── 04_carbon_stock.R   # SOC % → t C/ha conversion + Monte Carlo 95% CI
├── 05_plots.R          # ggplot2 figures: SOC map, risk zone map, bar, violin
├── input/              # Input rasters (not tracked — see Data section)
└── output/             # Generated outputs (not tracked)
```

Run scripts in order (01 → 05), or source them sequentially — each script calls its upstream dependency automatically if objects are not already in the R environment.

---

## Methods Summary

### 1. SOC Prediction
SOC (%) was predicted at 1 m resolution using a Random Forest model (`ranger` package) trained on field measurements from Hawke's Bay planted forests. Terrain covariates were derived from a 1 m LiDAR DEM: slope, TWI (Topographic Wetness Index), and land cover class.

### 2. Hazard Susceptibility Indices
LSI and FSI were produced using the Analytic Hierarchy Process (AHP; Saaty 1980) in a separate pipeline. See the companion repositories:
- [Landslide Susceptibility — link to your LSI repo]
- [Flood Susceptibility — link to your FSI repo]

### 3. Tertile Reclassification
All three inputs were reclassified to ordinal classes 1 (low), 2 (medium), 3 (high) using the 0th, 33rd, 66th, and 100th percentile breaks of each layer's distribution. This step ensures layers are commensurable prior to overlay (Malczewski 1999).

### 4. Weighted Overlay
A composite Carbon Risk Index was computed as:

```
CRI = (SOC_class × 0.40) + (LSI_class × 0.40) + (FSI_class × 0.20)
```

The composite (range: 1.0–3.0) was then classified into three risk zones using equal-interval thresholds (< 1.667 = Low; 1.667–2.333 = Moderate; > 2.333 = High).

### 5. Carbon Stock Quantification
SOC (%) was converted to t C/ha using:

```
SOC (t C/ha) = SOC (%) / 100 × bulk density (t/m³) × depth (m) × 10,000
```

Default parameters: bulk density = 0.9 t/m³ (Beare et al. 2014); depth = 0.075 m (0–7.5 cm). Update these in `config.R` if using site-specific values.

### 6. Uncertainty Analysis
Prediction uncertainty in the RF SOC model was propagated through 1,000 Monte Carlo simulations using a multiplicative noise term scaled by the model's relative RMSE. Update `rmse_pct` in `config.R` with your actual RF model RMSE / mean(SOC) before final reporting.

---

## Dependencies

| Package    | Version tested | Purpose                         |
|------------|---------------|---------------------------------|
| terra      | ≥ 1.7         | Raster I/O, resampling, masking |
| ggplot2    | ≥ 3.4         | All figures                     |
| patchwork  | ≥ 1.2         | Multi-panel figure composition  |
| scales     | ≥ 1.3         | Axis formatting                 |

Install all dependencies:
```r
install.packages(c("terra", "ggplot2", "patchwork", "scales"))
```

---

## Data

Input rasters are not tracked in this repository due to file size. The expected inputs are:

| File              | Description                                      | CRS       | Resolution |
|-------------------|--------------------------------------------------|-----------|------------|
| `Pred_NZ_SOC_1m.tif` | Random Forest predicted SOC (%)             | NZTM 2000 | 1 m        |
| `FSI_Raw.tif`     | Flood Susceptibility Index (continuous)          | NZTM 2000 | 1 m        |
| `LSI_Raw.tif`     | Landslide Susceptibility Index (continuous)      | NZTM 2000 | 1 m        |

Update paths in `config.R` before running.

---

## Outputs

| File                            | Description                                      |
|---------------------------------|--------------------------------------------------|
| `Carbon_Risk_Index_1m.tif`      | Continuous composite CRI raster (1.0–3.0)        |
| `Final_Risk_Zones.tif`          | Classified risk zones (1 = Low, 2 = Mod, 3 = High)|
| `LSI_Carbon_Risk_Zones.tif`     | Landslide-only risk zones                        |
| `FSI_Carbon_Risk_Zones.tif`     | Flood-only risk zones                            |
| `Carbon_Risk_Summary.csv`       | Area (ha) and % by risk zone                     |
| `Carbon_Risk_Landslide_Only.csv`| Area summary — landslide-only overlay            |
| `Carbon_Risk_Flood_Only.csv`    | Area summary — flood-only overlay                |
| `Predicted_SOC_Map.png`         | Continuous SOC prediction map                    |
| `Carbon_Risk_Summary_Plots.png` | Three-panel summary figure                       |

---

## References

- Beare, M.H. et al. (2014). Changes in the abundance and activity of soil organisms following organic matter inputs. *New Zealand Journal of Agricultural Research*.
- Malczewski, J. (1999). *GIS and Multicriteria Decision Analysis*. Wiley.
- Poeplau, C. et al. (2017). Soil organic carbon stocks as an indicator of environmental change. *Geoderma*.
- Saaty, T.L. (1980). *The Analytic Hierarchy Process*. McGraw-Hill.

---

## License

MIT License — see `LICENSE` for details.
