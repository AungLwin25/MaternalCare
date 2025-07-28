# data_preparation.R
#
# This script contains functions for loading, cleaning, and merging
# the various datasets required for the analysis.

# --- Helper Function for Consistent Country Name Cleaning ---
# This function will be applied to all country name columns before merging
clean_country_name <- function(country_col) {
  country_col %>%
    trimws() %>%
    # Remove content in parentheses (e.g., "(Bolivarian State of)", "(Bolivarian Republic of)")
    gsub("\\s*\\([^\\)]+\\)", "", .) %>%
    # Remove asterisks and other special characters often found in UN names
    gsub("\\*|\\#|\\<U\\+00A0>", "", .) %>%
    # Standardize common variations (add more as needed based on mismatches)
    gsub("United States of America", "United States", .) %>%
    gsub("Dem. People's Republic of Korea", "Democratic People's Republic of Korea", .) %>%
    gsub("Democratic Republic of the Congo", "Democratic Republic of Congo", .) %>%
    gsub("Türkiye", "Turkey", .) %>%
    gsub("Viet Nam", "Vietnam", .) %>%
    gsub("Cabo Verde", "Cape Verde", .) %>%
    gsub("Czechia", "Czech Republic", .) %>%
    gsub("Republic of Moldova", "Moldova", .) %>%
    gsub("Russian Federation", "Russia", .) %>%
    gsub("Syrian Arab Republic", "Syria", .) %>%
    gsub("United Republic of Tanzania", "Tanzania", .) %>%
    # Add more specific cleanups based on observed mismatches if they occur
    trimws() # Trim again after replacements
}


# --- 1. Load WPP Population Data ---
#' @title Load UN World Population Prospects Data
#' @description Loads the specified sheet from the WPP CSV file,
#'   filters for 2022 births, and cleans country names, standardizing by ISO3.
#' @param filepath Path to the WPP CSV file. # <--- CHANGED PARAMETER DESCRIPTION
#' @param sheet This parameter is no longer used for CSV.
#' @return A data frame with 2022 projected births, cleaned country names, and ISO3 codes.
load_wpp_data <- function(filepath, sheet) { # 'sheet' parameter will be ignored but kept for function signature consistency
  # Use read_csv for WPP data due to Excel parsing issues with ISO3 Alpha-code
  wpp_raw <- read_csv(filepath, skip = 16, show_col_types = FALSE) # <--- CHANGED TO read_csv, added show_col_types=FALSE
  
  # Filter for 2022 and ensure it's country-level data by checking ISO3 Alpha-code
  wpp_clean <- wpp_raw %>%
    # ISO3 Alpha-code is already character from read_csv, no need for mutate() here
    filter(
      .data$Year == 2022,           # Filter for the year 2022
      !is.na(.data$`ISO3 Alpha-code`), # Ensure ISO3 code exists
      nchar(.data$`ISO3 Alpha-code`) == 3 # Ensure it's a 3-character ISO3 code (filters out regions/world)
    ) %>%
    select(
      Country = `Region, subregion, country or area *`, # Use exact column name for Country
      ISO3Code = `ISO3 Alpha-code`,                     # Extract ISO3 code
      `2022_Births` = `Births (thousands)`              # Use exact column name for Births
    ) %>%
    # Convert births to numeric, handling any potential non-numeric values
    mutate(`2022_Births` = as.numeric(gsub(",", "", .data$`2022_Births`))) %>% # Remove commas if present in numbers
    # Apply consistent country name cleaning
    mutate(Country = clean_country_name(.data$Country)) %>%
    distinct(.data$ISO3Code, .keep_all = TRUE) # Ensure unique entry per ISO3 code
  
  return(wpp_clean)
}

# --- 2. Load Under-five Mortality Classification Data ---
#' @title Load Under-five Mortality Classification Data
#' @description Loads the U5MR classification data and cleans country names, standardizing by ISO3.
#' @param filepath Path to the main Excel workbook.
#' @param sheet Name of the sheet containing the U5MR data ("Sheet1").
#' @return A data frame with country names, ISO3 codes, and U5MR track status.
load_u5mr_classification <- function(filepath, sheet) {
  u5mr_raw <- read_excel(filepath, sheet = sheet)
  
  u5mr_clean <- u5mr_raw %>%
    select(
      ISO3Code = .data$ISO3Code, # Assuming ISO3Code is the column name
      Country = .data$OfficialName, # Keep original country name for reference
      Status.U5MR = .data$`Status.U5MR`
    ) %>%
    mutate(ISO3Code = as.character(.data$ISO3Code)) %>% # Force ISO3Code to character type (safe to keep)
    filter(!is.na(.data$ISO3Code)) %>% # Filter out NA ISO3 codes
    mutate(Country = clean_country_name(.data$Country)) %>% # Apply consistent country name cleaning
    # Classify into on-track/off-track based on exact values
    mutate(
      TrackStatus = case_when(
        .data$Status.U5MR %in% c("Achieved", "On Track") ~ "on-track",
        .data$Status.U5MR == "Acceleration Needed" ~ "off-track",
        TRUE ~ "unclassified" # Handle any other statuses
      )
    ) %>%
    filter(.data$TrackStatus %in% c("on-track", "off-track")) %>% # Keep only classified
    distinct(.data$ISO3Code, .keep_all = TRUE) # Ensure unique entry per ISO3 code
  
  return(u5mr_clean)
}

# --- 3. Load UNICEF Health Indicator Data (ANC4 & SBA) ---
#' @title Load UNICEF Health Indicator Data
#' @description Loads the specified sheet from the main Excel workbook,
#'   containing ANC4 and SBA data, standardizing by ISO3.
#' @param filepath Path to the main Excel workbook.
#' @param sheet Name of the sheet containing the UNICEF data ("fusion_GLOBAL_DATAFLOW_UNICEF_1").
#' @return A data frame with raw UNICEF health indicator data, including ISO3 codes.
load_unicef_health_data <- function(filepath, sheet) {
  unicef_raw <- read_excel(filepath, sheet = sheet)
  
  unicef_clean <- unicef_raw %>%
    # Extract ISO3 code from 'REF_AREA:Geographic area' (e.g., "AFG: Afghanistan" -> "AFG")
    mutate(ISO3Code = sub(":.*", "", `REF_AREA:Geographic area`)) %>%
    # Filter out regional aggregates (those with non-standard ISO3 codes or containing "_")
    filter(nchar(ISO3Code) == 3, !grepl("_", ISO3Code), !is.na(.data$ISO3Code)) %>% # Ensure ISO3 code is valid
    # Rename other columns
    rename(
      Country = `REF_AREA:Geographic area`, # Keep original for reference, but will use ISO3 for merge
      Indicator = `INDICATOR:Indicator`,
      Year = `TIME_PERIOD:Time period`,
      Value = `OBS_VALUE:Observation Value`
    ) %>%
    # Convert Indicator column to plain character to avoid 'labelled' class issues
    mutate(Indicator = as.character(.data$Indicator)) %>%
    filter(
      .data$Indicator %in% c(
        "MNCH_ANC4: Antenatal care 4+ visits - percentage of women (aged 15-49 years) attended at least four times during pregnancy by any provider",
        "MNCH_SAB: Skilled birth attendant - percentage of deliveries attended by skilled health personnel"
      ),
      .data$Year >= 2018,
      .data$Year <= 2022
    ) %>%
    # Convert Value to numeric, handling potential non-numeric values
    mutate(Value = as.numeric(gsub(",", "", .data$Value))) %>%
    # Apply consistent country name cleaning (for reference, though ISO3 is merge key)
    mutate(Country = clean_country_name(.data$Country)) %>%
    # For each country (ISO3) and indicator, get the most recent estimate within the range
    group_by(.data$ISO3Code, .data$Indicator) %>%
    arrange(desc(.data$Year)) %>%
    slice(1) %>% # Take the most recent year's observation
    ungroup() %>%
    select(.data$ISO3Code, .data$Indicator, .data$Value, .data$Country) # Keep Country for reference
  
  return(unicef_clean)
}


# --- 4. Clean and Merge All Datasets ---
#' @title Clean and Merge All Datasets
#' @description Cleans and merges health indicator data (ANC4, SBA),
#'   WPP population data, and U5MR classification data using ISO3 codes.
#'   Filters for 2018-2022 and takes the most recent estimate per country.
#' @param unicef_health_data_clean Cleaned UNICEF data.
#' @param wpp_data Cleaned WPP population data.
#' @param u5mr_classification Cleaned U5MR classification data.
#' @return A merged data frame ready for weighted coverage calculation.
clean_and_merge_all_data <- function(unicef_health_data_clean, wpp_data, u5mr_classification) {
  
  # Merge health data with U5MR classification using ISO3Code
  merged_health_u5mr <- unicef_health_data_clean %>%
    left_join(u5mr_classification, by = "ISO3Code") %>%
    filter(!is.na(.data$TrackStatus)) # Keep only countries with a U5MR classification
  
  # Merge with WPP population data using ISO3Code
  # Now that WPP ISO3 is forced to character, we should use it for merging
  final_merged_data <- merged_health_u5mr %>%
    left_join(wpp_data, by = "ISO3Code") %>% # <--- MERGING BY ISO3Code
    filter(!is.na(.data$`2022_Births`)) # Keep only countries with population data
  
  # Only apply labels if final_merged_data is not empty
  if (nrow(final_merged_data) > 0) {
    label(final_merged_data$Country) <- "Country Name" # This 'Country' is from U5MR classification
    label(final_merged_data$Indicator) <- "Health Service Indicator"
    label(final_merged_data$Value) <- "Coverage Value (%)"
    label(final_merged_data$Status.U5MR) <- "Under-five Mortality Target Status (Original)"
    label(final_merged_data$TrackStatus) <- "U5MR Track Status (Classified)"
    label(final_merged_data$`2022_Births`) <- "Projected Live Births (2022)"
    label(final_merged_data$ISO3Code) <- "ISO3 Alpha-code" # This ISO3 is from UNICEF/U5MR
  }
  
  
  # Rename Indicator values for plotting
  final_merged_data <- final_merged_data %>%
    mutate(
      Indicator = as.character(.data$Indicator), # Redundant but safe
      Indicator = case_when(
        .data$Indicator == "MNCH_ANC4: Antenatal care 4+ visits - percentage of women (aged 15-49 years) attended at least four times during pregnancy by any provider" ~ "Antenatal Care (ANC4)",
        .data$Indicator == "MNCH_SAB: Skilled birth attendant - percentage of deliveries attended by skilled health personnel" ~ "Skilled Birth Attendance (SBA)",
        TRUE ~ as.character(.data$Indicator) # Catch-all for any other indicators
      )
    )
  
  return(final_merged_data)
}
