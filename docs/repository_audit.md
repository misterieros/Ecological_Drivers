# Repository audit and curation notes

## Main problems detected in the uploaded repository

1. Analysis scripts, raw data, processed data, reports and workspace files were mixed in the original `Scripts/` folder.
2. Several R scripts used absolute Windows paths such as `D:/Investigación/...` or `E:/Investigación/...`.
3. Figure numbering in the original file names did not match the corrected manuscript narrative order.
4. R workspace files, PowerPoint files and Word outputs were stored together with executable analysis scripts.
5. The manuscript source was not present in the uploaded repository archive, so the corrected `main.tex` and bibliography were inserted from the current working session.
6. NetCDF files in the uploaded archive are Git LFS pointers, not full binary NetCDF files.

## Curation decisions applied

1. Final article materials were moved to `article/`.
2. Raw, processed and metadata files were separated under `data/`.
3. Cleaned entry-point scripts were created under `scripts/` using relative paths.
4. Original scripts were preserved unchanged under `scripts/legacy_original/`.
5. Rendered reports and generated figures were moved to `outputs/`.
6. Workspace and office-output files were moved to `archive/legacy_workspace/`.
7. A complete file manifest was generated at `docs/file_manifest.csv` and copied to `data/metadata/file_manifest.csv`.

## Figure remapping applied

| Corrected article figure | Source file in uploaded repository | Destination |
|---|---|---|
| Figure 1 | `Figs/ALL_VARIABLES_4x5.*` | `article/figures/Figure_1_environmental_gradients/` |
| Figure 2 | `Figs/Fig 2.png` | `article/figures/Figure_2_spatial_richness/` |
| Figure 3 | `Figs/Fig 5.png` | `article/figures/Figure_3_beta_diversity_NMDS/` |
| Figure 4 | `Figs/Fig 3.png` | `article/figures/Figure_4_decadal_richness/` |
| Figure 5 | `Figs/Fig 4.png` | `article/figures/Figure_5_environmental_variability/` |

## Items requiring manual review

1. Check that all final figures are called by the exact filenames expected in `article/manuscript/main.tex`.
2. Export final tables from LaTeX or R into `article/tables/` as editable files.
3. Validate the cleaned scripts computationally after restoring full NetCDF files through Git LFS or the external data source.
4. Decide the final public license before making the repository public.
