# Data folder

## raw/occurrences
Historical macroalgal occurrence tables and source biodiversity records.

## raw/cmems
Physical and biogeochemical environmental files derived from Copernicus Marine products. In the uploaded repository, `.nc` files are Git LFS pointer files rather than full NetCDF binaries.

## processed
Processed analytical tables used by legacy scripts and article analyses.

## metadata
File manifests and curation records.

Do not overwrite raw files. Derived objects should be written to `data/processed/` or `outputs/`.
