# data_preparation.R
#
# This script contains functions for loading, cleaning, and merging
# the various datasets required for the analysis.

# --- 1. Load WPP Population Data ---
#' @title Load UN World Population Prospects Data
#' @description Loads the specified sheet from the WPP Excel file,
#'   filters for 2022 births, and cleans country names.
#' @param filepath Path to the WPP Excel file.
#' @param sheet Name of the sheet containing the relevant data.
#' @return A data frame with 2022 projected births and cleaned country names.
load_wpp_data <- function(filepath, sheet) {
  wpp_raw <- read_excel(filepath, sheet = sheet)
  
  # Filter for 'Estimates', 'Total' population, 'Both sexes', and 'Live births'
  # And specifically for the year 2022
  wpp_clean <- wpp_raw %>%
    filter(
      .data$Variant == "Estimates",
      .data$Type == "Total",
      .data$Sex == "Both sexes",
      .data$Indicator == "Live births",
      .data$Year == 2022
    ) %>%
    select(
      Country = .data$Location,
      `2022_Births` = .data$Value # Rename Value to 2022_Births
    ) %>%
    # Clean country names for merging (e.g., remove asterisks, extra spaces)
    mutate(Country = trimws(gsub("\\*|\\(.*?\\)", "", .data$Country))) %>%
    distinct(.data$Country, .keep_all = TRUE) # Ensure unique country entries
  
  return(wpp_clean)
}

# --- 2. Load Under-five Mortality Classification Data ---
#' @title Load Under-five Mortality Classification Data
#' @description Loads the U5MR classification data and cleans country names.
#' @param filepath Path to the U5MR classification Excel file.
#' @param sheet Name of the sheet containing the data.
#' @return A data frame with country names and their U5MR track status.
load_u5mr_classification <- function(filepath, sheet) {
  u5mr_raw <- read_excel(filepath, sheet = sheet)
  
  # Assuming the U5MR file has columns like 'Country' and 'Status.U5MR'
  # Clean country names for merging
  u5mr_clean <- u5mr_raw %>%
    select(Country = .data$Country, Status.U5MR = .data$`Status.U5MR`) %>%
    mutate(Country = trimws(gsub("\\*|\\(.*?\\)", "", .data$Country))) %>%
    # Classify into on-track/off-track
    mutate(
      TrackStatus = case_when(
        .data$Status.U5MR %in% c("achieved", "on-track") ~ "on-track",
        .data$Status.U5MR == "acceleration needed" ~ "off-track",
        TRUE ~ "unclassified" # Handle any other statuses
      )
    ) %>%
    filter(.data$TrackStatus %in% c("on-track", "off-track")) %>% # Keep only classified
    distinct(.data$Country, .keep_all = TRUE) # Ensure unique country entries
  
  return(u5mr_clean)
}

# --- 3. Clean and Merge All Datasets ---
#' @title Clean and Merge All Datasets
#' @description Cleans and merges health indicator data (ANC4, SBA),
#'   WPP population data, and U5MR classification data.
#'   Filters for 2018-2022 and takes the most recent estimate per country.
#' @param health_data_raw Combined raw ANC4 and SBA data.
#' @param wpp_data Cleaned WPP population data.
#' @param u5mr_classification Cleaned U5MR classification data.
#' @return A merged data frame ready for weighted coverage calculation.
clean_and_merge_all_data <- function(health_data_raw, wpp_data, u5mr_classification) {
  # Standardize column names and filter years for health data
  health_data_clean <- health_data_raw %>%
    # Assuming columns like 'Country', 'TimePeriod', 'ObsValue'
    rename(
      Country = `Country or area`, # Adjust based on actual column name in UNICEF data
      Year = TimePeriod,           # Adjust based on actual column name in UNICEF data
      Value = ObsValue             # Adjust based on actual column name in UNICEF data
    ) %>%
    filter(
      .data$Year >= 2018,
      .data$Year <= 2022
    ) %>%
    # Clean country names
    mutate(Country = trimws(gsub("\\*|\\(.*?\\)", "", .data$Country))) %>%
    # For each country and indicator, get the most recent estimate within the range
    group_by(.data$Country, .data$Indicator) %>%
    arrange(desc(.data$Year)) %>%
    slice(1) %>% # Take the most recent year's observation
    ungroup() %>%
    select(.data$Country, .data$Indicator, .data$Value) # Keep only relevant columns
  
  # Merge health data with U5MR classification
  merged_health_u5mr <- health_data_clean %>%
    left_join(u5mr_classification, by = "Country") %>%
    filter(!is.na(.data$TrackStatus)) # Keep only countries with a U5MR classification
  
  # Merge with WPP population data
  final_merged_data <- merged_health_u5mr %>%
    left_join(wpp_data, by = "Country") %>%
    filter(!is.na(.data$`2022_Births`)) # Keep only countries with population data
  
  # Apply labels for clarity in the final data frame (optional but good practice)
  label(final_merged_data$Country) <- "Country Name"
  label(final_merged_data$Indicator) <- "Health Service Indicator"
  label(final_merged_data$Value) <- "Coverage Value (%)"
  label(final_merged_data$Status.U5MR) <- "Under-five Mortality Target Status (Original)"
  label(final_merged_data$TrackStatus) <- "U5MR Track Status (Classified)"
  label(final_merged_data$`2022_Births`) <- "Projected Live Births (2022)"
  
  return(final_merged_data)
}

