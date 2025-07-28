# visualization.R
#
# This script contains a function to create the required visualization.

#' @title Create Coverage Comparison Plot
#' @description Generates a bar plot comparing population-weighted coverage
#'   for ANC4 and SBA between on-track and off-track countries.
#' @param data A data frame containing TrackStatus, Indicator, and WeightedCoverage.
#' @return A ggplot2 object.
create_coverage_plot <- function(data) {
  # Ensure TrackStatus is ordered for consistent plotting
  data$TrackStatus <- factor(data$TrackStatus, levels = c("on-track", "off-track"))
  
  plot <- ggplot(data, aes(x = .data$Indicator, y = .data$WeightedCoverage, fill = .data$TrackStatus)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
    geom_text(aes(label = paste0(.data$WeightedCoverage, "%")),
              position = position_dodge(width = 0.8),
              vjust = -0.5, size = 3.5) +
    scale_fill_manual(values = c("on-track" = "#1f78b4", "off-track" = "#e31a1c")) + # Blue for on-track, Red for off-track
    labs(
      title = "Population-Weighted Coverage of ANC4 and SBA",
      subtitle = "Comparison between On-track and Off-track Countries for U5MR Targets (2018-2022)",
      x = "Health Service Indicator",
      y = "Population-Weighted Coverage (%)",
      fill = "U5MR Target Status"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5),
      legend.position = "bottom",
      panel.grid.major.x = element_blank(),
      panel.grid.minor.y = element_blank(),
      axis.line.y = element_line(color = "grey"),
      axis.ticks.y = element_line(color = "grey")
    ) +
    ylim(0, 100) # Ensure y-axis goes from 0 to 100%
  
  return(plot)
}
