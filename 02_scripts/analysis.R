# analysis.R
#
# This script contains functions for calculating population-weighted coverage.

#' @title Calculate Population-Weighted Coverage
#' @description Calculates the population-weighted average for ANC4 and SBA
#'   for countries categorized as on-track or off-track based on U5MR targets.
#' @param data A data frame containing Country, Indicator, Value (coverage),
#'   TrackStatus (on-track/off-track), and 2022_Births (for weighting).
#' @return A data frame with population-weighted coverage for each indicator
#'   by U5MR track status.
calculate_population_weighted_coverage <- function(data) {
  # Calculate population-weighted averages
  weighted_results <- data %>%
    group_by(.data$TrackStatus, .data$Indicator) %>%
    summarise(
      # Calculate weighted average: sum(Value * Weight) / sum(Weight)
      WeightedCoverage = sum(.data$Value * .data$`2022_Births`, na.rm = TRUE) / sum(.data$`2022_Births`, na.rm = TRUE),
      .groups = "drop" # Drop grouping to get a flat data frame
    ) %>%
    # Format to percentage with one decimal place
    mutate(WeightedCoverage = round(.data$WeightedCoverage, 1))
  
  return(weighted_results)
}
