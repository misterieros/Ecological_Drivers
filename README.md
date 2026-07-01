````markdown
# Ecological Drivers: Macroalgal Diversity Across the Canary Islands

## Project overview
This repository contains the analytical workflow, data organization, scripts, figures, tables, and manuscript-related materials associated with the study of marine macroalgal diversity across the Canary Islands archipelago.

The project integrates long-term macroalgal occurrence records with physical and biogeochemical environmental variables derived from Copernicus Marine products to analyse spatial and temporal biodiversity patterns across an oceanographically heterogeneous insular system.

The main objective of the study is to quantify spatial and temporal patterns of macroalgal richness and diversity, and to identify the environmental gradients associated with macroalgal community structure across the Canary Islands.

The Canary Islands provide a relevant marine system for this analysis because the archipelago is characterized by strong environmental heterogeneity and a pronounced east-west oceanographic gradient.

This gradient separates eastern islands, more influenced by cooler and nutrient-enriched waters, from western islands, which are generally warmer and more oligotrophic.

The workflow combines biodiversity data processing, environmental data extraction, diversity metric calculation, spatial and temporal visualization, multivariate analyses, and generalized additive models.

The repository is organized to support reproducibility, manuscript development, figure and table generation, and future extensions of the workflow to other coastal or oceanic systems.

## Project origin

This repository and the associated manuscript were conceptually inspired by an earlier Master's Final Project developed by **Eros Fernando Geppi** during the **2021/2022 academic year** within the **Máster Interuniversitario en Oceanografía** offered by the Universidad de Las Palmas de Gran Canaria (ULPGC), Universidade de Vigo (UVigo), and Universidad de Cádiz (UCA).

The Master's Final Project was entitled: **Synergistic interactions between environmental components that affect the presence of macroalgae species in the Canary Islands: an ecological approximation with Generalized Additive Models (GAMs).**

Although the present article follows a different analytical and conceptual direction, that earlier work helped motivate the broader research interest in macroalgal diversity, environmental variability, and the use of statistical modelling approaches in the Canary Islands.

The current repository should therefore be understood as an independent article-oriented workflow that was inspired by that previous academic work, rather than as a direct continuation of it.

## Associated article

**Title:** Spatiotemporal patterns of macroalgal diversity across an environmentally heterogeneous oceanic archipelago.

**Journal:** Estuarine, Coastal and Shelf Science

**Manuscript number:** YECSS-D-26-XXXXXXX

## Article authorship

The article associated with this repository was authored by:

- Eros Fernando Geppi
- Daniel Gonzalez-Aragon
- Rodrigo Riera


## Research scope

This repository supports the analysis of:

- Long-term macroalgal diversity dynamics across the Canary Islands
- Spatial structuring of macroalgal assemblages across an oceanic archipelago
- Alpha, beta, and gamma diversity patterns across multiple temporal scales
- Relationships between macroalgal diversity and environmental variability
- Non-linear diversity-environment associations using generalized additive models
- Regional differences between eastern and western islands
- Macro-ecological baselines for biodiversity assessment under environmental change

## Analytical approach

The analysis combines:

- Historical macroalgal occurrence and richness records spanning multiple decades
- Physical and biogeochemical variables derived from Copernicus Marine Environment Monitoring Service products
- Diversity metrics, including species richness, Shannon diversity, beta diversity, and gamma diversity
- Spatial and temporal visualization of biodiversity patterns
- Multivariate analyses of environmental gradients
- Generalized additive models to explore non-linear relationships between biodiversity and environmental drivers

This integrative approach allows the exploration of signals associated with ocean warming, biogeochemical variability, regional ocean circulation, and their relationships with benthic macroalgal communities.

## Repository structure

```text
Ecological_Drivers/
├── article/                         # Material directly associated with the manuscript
│   ├── manuscript/                  # Article source files: main.tex, references, and appendices
│   ├── figures/                     # Final figures organized according to the manuscript order
│   ├── tables/                      # Main and supplementary tables used in the manuscript
│   └── submission/                  # Editorial submission files: highlights, cover letter, and rebuttal
│
├── data/                            # Data used or generated during the analysis
│   ├── raw/                         # Original, unmodified data
│   ├── processed/                   # Cleaned, filtered, or aggregated data ready for analysis
│   └── metadata/                    # Variable descriptions, data sources, units, and filtering criteria
│
├── scripts/                         # Reproducible code for data processing, analysis, and outputs
│
├── notebooks/                       # Exploratory notebooks and preliminary analyses
│
├── outputs/                         # Results generated by the scripts
│                                   # Includes figures, tables, models, logs, and derived reports
│
├── references/                      # Bibliographic files, .bib databases, and supporting references
│
└── docs/                            # Internal repository documentation
                                    # Includes repository audit, file manifest, and reproducibility notes
````

## Repository components and workflow

### Article

The `article/` folder contains all files directly associated with the manuscript. This includes the LaTeX source files, references, figures, tables, supplementary material, and editorial submission documents.

Recommended use:

* Keep the active manuscript files in `article/manuscript/`
* Store final manuscript figures in `article/figures/`
* Store main and supplementary tables in `article/tables/`
* Store cover letters, highlights, response letters, and revision files in `article/submission/`

### Data

The `data/` folder contains the biological and environmental datasets used in the analysis.

Recommended organization:

* `data/raw/`: original data files, kept unchanged
* `data/processed/`: cleaned, filtered, or aggregated data used by the scripts
* `data/metadata/`: information on variables, units, sources, filtering criteria, and data structure

Raw data should not be overwritten. Any transformation, filtering, or aggregation should generate a new file in `data/processed/`.

### Scripts

The `scripts/` folder contains R and RMarkdown scripts for:

* Biodiversity data cleaning and organization
* Extraction and processing of environmental variables
* Calculation of diversity metrics
* Fitting and diagnostic assessment of generalized additive models
* Generation of figures and summary outputs

### Notebooks

The `notebooks/` folder is intended for exploratory analyses, preliminary tests, and interactive workflows.

Notebooks should be used for exploration, not as the main reproducible workflow. Analyses that become part of the final article should be transferred into scripts under `scripts/`.

### Outputs

The `outputs/` folder contains files generated by the analysis, including:

* Figures
* Reports

Generated outputs should be reproducible from the scripts and processed data.

### References

The `references/` folder contains bibliographic resources used for manuscript preparation.

This may include:

* BibTeX databases
* Reference lists

The active bibliography used by the manuscript should also be available in `article/manuscript/`.

### Documentation

The `docs/` folder contains internal repository documentation, including:

* Repository audit notes
* File manifests
* Workflow descriptions
* Reproducibility notes
* Data documentation
* Notes on manuscript revisions

## Methodological approach

This repository follows a reproducible workflow based on:

* Integration of ecological and environmental data across multiple spatial scales
* Use of non-linear statistical models, particularly generalized additive models
* Spatial and temporal visualization of biodiversity patterns
* Organization of scripts, data, outputs, and manuscript files for scientific use
* Separation between raw data, processed data, generated outputs, and manuscript materials

## Applications

This repository is intended to support:

* Ecological analyses in marine insular systems
* Biodiversity and environmental change studies
* Macroalgal community analyses
* Scientific publications, theses, and technical reports
* Reuse and extension of the workflow in other coastal or oceanic regions

## Requirements

The analysis is primarily conducted in R and relies on packages commonly used for ecological statistics, spatial analysis, and data visualization.

Main R packages include:

* `tidyverse`
* `mgcv`
* `vegan`
* `sf`
* `raster`
* `terra`
* `ncdf4`
* `ggplot2`
* `patchwork`

Additional packages may be required by specific scripts or RMarkdown files. Package requirements should be checked in the individual scripts before running the full workflow.

## Reproducibility notes

To improve reproducibility:

* Use relative paths rather than absolute local paths
* Keep raw data unchanged
* Document all filtering and aggregation steps
* Store generated outputs separately from source data
* Keep exploratory analyses separate from the main workflow
* Update metadata whenever variables, files, or processing steps change
* Record software versions when possible

## Data availability

Data availability information should be described in the manuscript and, when applicable, linked to the corresponding public repository or DOI.

If using external environmental products, data sources should be cited according to their provider guidelines.

## License

This repository uses a dual-license structure to distinguish between code and
research materials.

### Code

All code, scripts, computational workflows, and software-like materials in this
repository are released under the MIT License, unless otherwise stated.

This applies to materials such as:

- R scripts
- RMarkdown scripts
- workflow scripts
- data-processing code
- analysis code
- plotting code
- model-fitting code
- utility functions

The MIT License allows reuse, modification, distribution, sublicensing, and
incorporation of the code into other projects, provided that the copyright
notice and license text are retained.

The full license text is available in the `LICENSE` file.

### Data, figures, tables, and documentation

Data products, processed datasets, figures, tables, metadata, documentation,
and non-code research materials created by the authors are released under the
Creative Commons Attribution 4.0 International License, CC BY 4.0, unless
otherwise stated.

This applies to author-generated materials such as:

- processed biodiversity datasets
- processed environmental datasets
- derived summary tables
- manuscript figures
- supplementary tables
- metadata files
- documentation files
- repository workflow descriptions

Under CC BY 4.0, these materials may be shared and adapted, provided that
appropriate credit is given, a link to the license is provided, and any changes
made to the material are indicated.

The full data and documentation license notice is available in the
`LICENSE-DATA` file.

### Third-party data and external products

This repository may include or refer to third-party datasets, environmental
products, biodiversity databases, satellite-derived products, reanalysis
products, bibliographic resources, or other external materials.

These third-party materials are not relicensed by this repository. They remain
subject to the licenses, terms of use, citation requirements, and access
conditions established by their original providers.

Users are responsible for checking the original license and citation
requirements before reusing third-party materials.

### Manuscript and published article

The manuscript and any published version of the associated article are subject
to the copyright and licensing conditions established by the journal and
publisher.

If the article is published open access, reuse of the published article will
follow the Creative Commons license selected during publication.

If the article is published under a subscription model, the final published PDF
should not be redistributed through this repository unless this is permitted by
the publisher's policy. In that case, only the version allowed by the publisher
should be shared.

### Recommended citation

If you use this repository, please cite the associated article once published.

Suggested APA citation for the article before publication:
```text
Geppi, E. F., Gonzalez-Aragon, D., & Riera, R. (2026). Spatiotemporal patterns of macroalgal diversity across an environmentally heterogeneous oceanic archipelago. Estuarine, Coastal and Shelf Science. Manuscript submitted for publication.
```
Once the article is published, please replace this provisional citation with the final bibliographic information, including volume, article number, pages, and DOI.

## License

This repository uses a dual-license structure to distinguish between code and research materials.

### Code

All code, scripts, computational workflows, and software-like materials in this repository are released under the MIT License, unless otherwise stated.

This applies to materials such as:

* R scripts
* RMarkdown scripts
* workflow scripts
* data-processing code
* analysis code
* plotting code
* model-fitting code
* utility functions

The MIT License allows reuse, modification, distribution, sublicensing, and incorporation of the code into other projects, provided that the copyright notice and license text are retained.

The full license text is available in the `LICENSE` file.

### Data, figures, tables, and documentation

Data products, processed datasets, figures, tables, metadata, documentation, and non-code research materials created by the authors are released under the Creative Commons Attribution 4.0 International License, CC BY 4.0, unless otherwise stated.

This applies to author-generated materials such as:

* processed biodiversity datasets
* processed environmental datasets
* derived summary tables
* manuscript figures
* supplementary tables
* metadata files
* documentation files
* repository workflow descriptions

Under CC BY 4.0, these materials may be shared and adapted, provided that appropriate credit is given, a link to the license is provided, and any changes made to the material are indicated.

The full data and documentation license notice is available in the `LICENSE-DATA` file.

### Third-party data and external products

This repository may include or refer to third-party datasets, environmental products, biodiversity databases, satellite-derived products, reanalysis products, bibliographic resources, or other external materials.

These third-party materials are not relicensed by this repository. They remain subject to the licenses, terms of use, citation requirements, and access conditions established by their original providers.

Users are responsible for checking the original license and citation requirements before reusing third-party materials.

### Manuscript and published article

The manuscript and any published version of the associated article are subject to the copyright and licensing conditions established by the journal and publisher.

If the article is published open access, reuse of the published article will follow the Creative Commons license selected during publication.

If the article is published under a subscription model, the final published PDF should not be redistributed through this repository unless this is permitted by the publisher's policy. In that case, only the version allowed by the publisher should be shared.

### Recommended citation

When reusing materials from this repository, please cite the associated article once published and acknowledge the repository according to the citation information provided in `CITATION.cff`.

## Contact

For questions related to the manuscript, data organization, or analytical workflow, please contact the article authors.
