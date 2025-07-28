# run_project.R
#
# This script orchestrates the entire data analysis workflow,
# from data loading and preparation to analysis, visualization,
# and report generation.
#
# To run this script:
# 1. Ensure all required R packages are installed (see README.md).
# 2. Place all raw data files in the '01_rawdata/' folder (see README.md).
# 3. Configure your local settings in 'user_profile.R' (copy from .template).
# 4. Open this project in RStudio and click 'Source' on this script.

# --- 0. Load Required Libraries ---
# Ensure these packages are installed: install.packages(c("readxl", "dplyr", "Hmisc", "ggplot2", "rmarkdown", "knitr"))
library(readxl)
library(dplyr)
library(Hmisc)    # For label() function
library(ggplot2)  # For visualization
library(rmarkdown) # For knitting R Markdown reports
library(knitr)    # For knitting R Markdown reports

# --- 1. Load User-Specific Profile/Configuration ---
# This file contains paths to data, output settings, etc.,
# customized for the local machine. It should NOT be committed to Git.
if (file.exists("user_profile.R")) {
  source("user_profile.R")
  message("Loaded user_profile.R for local configurations.")
} else {
  stop("Error: 'user_profile.R' not found. Please copy 'user_profile.R.template' to 'user_profile.R' and configure it for your local machine.")
}

# --- 2. Source Modular Scripts ---
# Load functions defined in separate R scripts for better organization.
source(file.path(scripts_dir, "data_preparation.R"))
source(file.path(scripts_dir, "analysis.R"))
source(file.path(scripts_dir, "visualization.R"))

# --- 3. Data Preparation ---
message("\n--- Starting Data Preparation ---")

# Load WPP Population Data
message("Loading UN World Population Prospects data...")
wpp_data <- load_wpp_data(wpp_filepath, sheet = wpp_data_sheet)
message(paste("WPP data loaded. Rows:", nrow(wpp_data)))

# Load Under-five Mortality Classification Data
message("Loading Under-five Mortality Classification data...")
u5mr_classification <- load_u5mr_classification(u5mr_classification_filepath, sheet = u5mr_data_sheet)
message(paste("U5MR classification loaded. Rows:", nrow(u5mr_classification)))

# Load ANC4 and SBA data (assuming they are CSVs or Excel files)
message("Loading ANC4 coverage data...")
# Check file extension to use appropriate reader
if (grepl("\\.csv$", anc4_filename, ignore.case = TRUE)) {
  anc4_data <- read.csv(anc4_filepath, stringsAsFactors = FALSE)
} else if (grepl("\\.xlsx$", anc4_filename, ignore.case = TRUE)) {
  anc4_data <- read_excel(anc4_filepath, sheet = anc4_data_sheet)
} else {
  stop("Unsupported file type for ANC4 data. Please use .csv or .xlsx.")
}
message(paste("ANC4 data loaded. Rows:", nrow(anc4_data)))

message("Loading SBA coverage data...")
if (grepl("\\.csv$", sba_filename, ignore.case = TRUE)) {
  sba_data <- read.csv(sba_filepath, stringsAsFactors = FALSE)
} else if (grepl("\\.xlsx$", sba_filename, ignore.case = TRUE)) {
  sba_data <- read_excel(sba_filepath, sheet = sba_data_sheet)
} else {
  stop("Unsupported file type for SBA data. Please use .csv or .xlsx.")
}
message(paste("SBA data loaded. Rows:", nrow(sba_data)))


# Clean and merge all datasets
message("Cleaning and merging datasets...")
# Combine ANC4 and SBA for easier processing
health_data_raw <- bind_rows(
  mutate(anc4_data, Indicator = "ANC4"),
  mutate(sba_data, Indicator = "SBA")
)

# Use the data_preparation function to get the final merged data
merged_data <- clean_and_merge_all_data(
  health_data_raw = health_data_raw,
  wpp_data = wpp_data,
  u5mr_classification = u5mr_classification
)
message(paste("Merged data prepared. Final rows:", nrow(merged_data)))

# --- 4. Calculate Population-Weighted Coverage ---
message("\n--- Starting Population-Weighted Coverage Calculation ---")
weighted_coverage_results <- calculate_population_weighted_coverage(merged_data)
print(weighted_coverage_results)
message("Population-weighted coverage calculated.")

# --- 5. Reporting ---
message("\n--- Generating Report ---")

# Create a temporary Rmd file for rendering.
# This ensures the Rmd always uses the correct paths and variables from user_profile.R
# and the generated data.
# We'll write the content of the Rmd directly here.
rmd_content <- '
---
title: "Population-Weighted Coverage Analysis: Maternal & Child Health"
author: "Your Name"
date: "`r format(Sys.Date(), "%B %d, %Y")`"
output:
  html_document:
    toc: true
    toc_depth: 2
    theme: cosmo
  pdf_document:
    toc: true
    toc_depth: 2
  word_document:
    toc: true
    toc_depth: 2
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = FALSE, message = FALSE, warning = FALSE, fig.align = "center")

# Load necessary libraries for the Rmd rendering context
library(ggplot2)
library(dplyr)
library(Hmisc) # For labels, if needed in the report directly

# Pass the calculated results and figure path from run_project.R
# These variables are created in the environment of run_project.R and passed to knit
weighted_coverage_results_rmd <- weighted_coverage_results
figures_dir_rmd <- figures_dir
```

## Introduction

This report presents an analysis of population-weighted coverage for Antenatal Care (ANC4) and Skilled Birth Attendance (SBA) across countries, categorized by their progress towards under-five mortality (U5MR) targets. The objective is to compare health service coverage between "on-track" and "off-track" countries.

## Methodology

Data for ANC4 and SBA indicators were retrieved from the UNICEF Global Data Repository for the years 2018-2022. Population data (projected births for 2022) were sourced from the UN World Population Prospects 2022. Country classifications for U5MR targets were obtained from a separate provided file.

All datasets were cleaned, merged, and harmonized using consistent country identifiers. For ANC4 and SBA, the most recent estimate within the 2018-2022 range was used for each country. Population-weighted averages were then calculated using 2022 projected births as weights.

## Results

### Population-Weighted Coverage Summary

```{r display_results, echo=FALSE}
knitr::kable(weighted_coverage_results_rmd,
             caption = "Population-Weighted Coverage (%) for ANC4 and SBA by U5MR Track Status")
```

### Visualization

```{r plot_coverage, fig.width=10, fig.height=6, echo=FALSE}
# Generate and save the visualization
coverage_plot <- create_coverage_plot(weighted_coverage_results_rmd)
plot_filepath <- file.path(figures_dir_rmd, "coverage_comparison_plot.png")
ggsave(plot_filepath, coverage_plot, width = 10, height = 6, units = "in")
print(coverage_plot)
```

### Interpretation

The table and visualization above compare the population-weighted coverage of ANC4 and SBA for countries categorized as "on-track" or "off-track" for under-five mortality targets.

*(A short paragraph interpreting the results will go here. You will write this based on the actual results you get after running the analysis.)*

For example:
"The results indicate that [On-track/Off-track] countries generally show [higher/lower] population-weighted coverage for both ANC4 and SBA compared to the other group. Specifically, ANC4 coverage is [X]% in on-track countries versus [Y]% in off-track countries, suggesting [interpretation]. Similarly, SBA coverage is [A]% in on-track countries compared to [B]% in off-track countries, which implies [interpretation]. This pattern [supports/does not support] the hypothesis that better maternal and child health service coverage correlates with progress in reducing under-five mortality.

**Caveats and Assumptions:**
* **Data Availability:** The analysis relies on the most recent available data between 2018-2022, which might not be uniformly available for all countries.
* **Population Projections:** 2022 projected births are used as weights, which are estimates and may have inherent uncertainties.
* **Causality:** This analysis is descriptive and does not imply direct causality between health service coverage and U5MR status. Other factors undoubtedly contribute to under-five mortality rates.
* **Country Classification:** The U5MR classification is based on targets as of 2022 and may not reflect real-time changes.
'
# Write the Rmd content to a temporary file in the output directory
# This ensures the Rmd file is always up-to-date with the latest run parameters
rmd_temp_file <- file.path(output_dir, "temp_report.Rmd")
writeLines(rmd_content, rmd_temp_file)

# Render the R Markdown report
output_file_full_path <- file.path(output_dir, paste0(final_report_name, ".",
                                                      switch(report_output_format,
                                                             "html_document" = "html",
                                                             "pdf_document" = "pdf",
                                                             "word_document" = "docx")))

message(paste("Rendering report to:", output_file_full_path))

rmarkdown::render(
  input = rmd_temp_file,
  output_format = report_output_format,
  output_file = output_file_full_path,
  # Pass variables to the Rmd environment
  params = list(
    weighted_coverage_results_rmd = weighted_coverage_results,
    figures_dir_rmd = figures_dir
  ),
  envir = new.env() # Render in a clean environment
)

# Clean up the temporary Rmd file
file.remove(rmd_temp_file)

message("\n--- Workflow Complete! ---")
message(paste("Final report saved to:", output_file_full_path))
