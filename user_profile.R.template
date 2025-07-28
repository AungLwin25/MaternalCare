# user_profile.R.template
#
# This file defines machine-specific settings and input parameters
# required to run the project's workflow.
#
# INSTRUCTIONS FOR USERS:
# 1. Copy this file and rename it to `user_profile.R` (remove .template).
# 2. DO NOT commit `user_profile.R` to Git (it's already in .gitignore).
# 3. Modify the paths and settings below to match your local machine.

# --- 1. Base Project Directory ---
# This should be the absolute path to the root of THIS Git repository
# on your local machine. This helps in constructing other paths reliably.
# Use forward slashes (/) even on Windows.
if (.Platform$OS.type == "windows") {
  # Example for Windows:
  base_project_dir <- "C:/Users/YourUsername/Documents/GitProjects/MaternalCare/"
} else if (.Platform$OS.type == "unix") { # Covers macOS and Linux
  # Example for macOS/Linux:
  base_project_dir <- "/Users/YourUsername/Documents/GitProjects/MaternalCare/"
} else {
  stop("Unsupported operating system. Please update user_profile.R.")
}

# --- 2. Input Data File Paths ---
# These are the filenames for the raw data files expected in the 01_rawdata/ folder.
# IMPORTANT: You must manually download these files and place them in 01_rawdata/.

# UN World Population Prospects data
wpp_filename <- "WPP2022_GEN_F01_DEMOGRAPHIC_INDICATORS_COMPACT_REV1.xlsx"

# Under-five mortality classification data
u5mr_classification_filename <- "On-track and off-track countries.xlsx"

# UNICEF ANC4 coverage data (downloaded from UNICEF Global Data Repository)
# Example: "ANC4_coverage_2018-2022.csv" or "ANC4_coverage_2018-2022.xlsx"
anc4_filename <- "ANC4_coverage_2018-2022.csv" # <--- UPDATE THIS with actual filename and extension

# UNICEF SBA coverage data (downloaded from UNICEF Global Data Repository)
# Example: "SBA_coverage_2018-2022.csv" or "SBA_coverage_2018-2022.xlsx"
sba_filename <- "SBA_coverage_2018-2022.csv" # <--- UPDATE THIS with actual filename and extension


# --- 3. Excel Sheet Names (if applicable) ---
# For the WPP and U5MR classification files, specify the sheet names if different from defaults.
wpp_data_sheet <- "Table_1" # <--- UPDATE THIS if different
u5mr_data_sheet <- "Sheet1" # <--- UPDATE THIS if different

# For UNICEF data, if they are Excel files, specify sheet names
anc4_data_sheet <- "Sheet1" # <--- UPDATE THIS if using .xlsx and sheet name is different
sba_data_sheet <- "Sheet1" # <--- UPDATE THIS if using .xlsx and sheet name is different


# --- 4. Output Report Settings ---
# Desired format for the final report. Choose one: "html_document", "pdf_document", "word_document"
report_output_format <- "html_document" # <--- UPDATE THIS

# Name for the final generated report (without extension, it will be added automatically)
final_report_name <- "Population_Weighted_Coverage_Report"


# --- DO NOT MODIFY BELOW THIS LINE (Paths are constructed automatically) ---
raw_data_dir <- file.path(base_project_dir, "01_rawdata")
scripts_dir <- file.path(base_project_dir, "02_scripts")
output_dir <- file.path(base_project_dir, "03_output")
figures_dir <- file.path(output_dir, "figures")

# Create output directories if they don't exist
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

# Full paths to raw data files
wpp_filepath <- file.path(raw_data_dir, wpp_filename)
u5mr_classification_filepath <- file.path(raw_data_dir, u5mr_classification_filename)
anc4_filepath <- file.path(raw_data_dir, anc4_filename)
sba_filepath <- file.path(raw_data_dir, sba_filename)

# Full path for the R Markdown report source
rmd_report_path <- file.path(base_project_dir, "03_output", "report.Rmd") # Placing Rmd in output for simplicity of file paths
