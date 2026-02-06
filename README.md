# Ecological_Drivers
Este repositorio integra registros históricos de biodiversidad y variables ambientales satelitales para analizar patrones espaciales y temporales de la riqueza y diversidad de macroalgas en Canarias, evaluando gradientes ambientales y su relación con la dinámica oceanográfica mediante modelos estadísticos avanzados.

# Macroalgal Diversity and Environmental Drivers in the Canary Islands

## 📌 Project description

This repository contains the complete analytical workflow for the study of **marine macroalgal diversity across the Canary Islands archipelago**, integrating long-term biodiversity records with physical and biogeochemical environmental variables derived from satellite-based oceanographic products.

The main objective of this project is to **quantify spatial and temporal patterns of macroalgal richness and diversity**, and to **identify the key environmental gradients shaping macroalgal communities** in an oceanographically complex insular system characterized by a strong east–west gradient.

The analysis combines:
- Historical macroalgal occurrence and richness records spanning multiple decades.
- Environmental variables derived from Copernicus Marine Environment Monitoring Service (CMEMS) products.
- Advanced statistical approaches, including **Generalized Additive Models (GAMs)**, to explore potentially non-linear relationships between biodiversity and environmental drivers.

This integrative approach allows the detection of signals associated with **ocean warming**, **biogeochemical variability**, and **regional ocean circulation**, and their influence on benthic macroalgal communities.

---

## 📂 Repository structure

```text
.
├── Figs/          
│   └── plots_gam_effects/   
├── nc/            
├── QGIS/          
├── Reports/       
└── Scripts/
```
   
🔹 Figs/
Contains final figures used in reports and manuscripts, including spatial patterns of macroalgal richness and partial effect plots from GAM analyses for multiple environmental variables.

🔹 nc/
NetCDF files containing physical and biogeochemical environmental variables (e.g. temperature, currents, chlorophyll, nutrients, dissolved inorganic carbon), organized at both regional and island scales.

🔹 QGIS/
QGIS project files and auxiliary Python scripts used for spatial visualization and cartographic representation of biodiversity data and environmental gradients.

🔹 Reports/
Reproducible reports generated using RMarkdown, available in HTML and PDF formats, documenting the analytical workflow and main results.

🔹 Scripts/
R and RMarkdown scripts for:

Biodiversity data cleaning and organization.

Extraction and processing of environmental variables.

Calculation of diversity metrics.

Fitting and diagnostic assessment of GAMs.

Generation of figures and summary outputs.

This folder also includes auxiliary datasets (.xlsx, .csv) and intermediate results used throughout the analysis.

🔬 Methodological approach
Integration of ecological and environmental data across multiple spatial scales.

Use of non-linear statistical models (GAMs).

Spatial and temporal visualization of biodiversity patterns.

Reproducible research workflow oriented toward scientific applications.

📈 Applications
This repository is intended for:

Ecological analyses in marine insular systems.

Biodiversity and environmental change studies.

Methodological support for scientific publications, theses, and technical reports.

Reuse and extension of the workflow in other coastal or oceanic regions.

📦 Requirements
The analysis is primarily conducted in R and relies on commonly used packages for ecological statistics, spatial analysis, and data visualization (e.g. mgcv, tidyverse, sf, raster, ncdf4).
Specific package versions and dependencies are documented within the scripts and RMarkdown files.
