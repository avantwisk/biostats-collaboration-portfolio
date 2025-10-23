# visualization_helpers.R
# Visualization functions for ADEMP simulation framework
# Author: Alexander van Twisk
# Date: 2025-10-11

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)

#' Create power curve plot with confidence bands
#'
#' @param summary_stats Summary statistics from simulation
#' @param target_power Target power level (default 0.80)
#' @param show_mcse Whether to show Monte Carlo SE bands
#'
#' @return ggplot object
#' @export
plot_power_curve <- function(
  summary_stats,
  target_power = 0.80,
  show_mcse = TRUE
) {
  p <- ggplot(summary_stats, aes(x = n, y = power, color = method)) +
    geom_hline(
      yintercept = target_power,
      linetype = "dashed",
      alpha = 0.5,
      color = "gray40"
    ) +
    geom_line(linewidth = 1.2)

  if (show_mcse) {
    p <- p +
      geom_ribbon(
        aes(
          ymin = power - 1.96 * power_mcse,
          ymax = power + 1.96 * power_mcse,
          fill = method
        ),
        alpha = 0.2,
        color = NA
      )
  }

  # Find N for target power
  n_star <- summary_stats %>%
    filter(power >= target_power) %>%
    group_by(method) %>%
    slice_min(n) %>%
    ungroup()

  if (nrow(n_star) > 0) {
    p <- p + geom_point(data = n_star, size = 3, shape = 21, fill = "white")
  }

  p <- p +
    scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
    labs(
      x = "Sample Size per Arm",
      y = "Statistical Power",
      title = "Power Curve Analysis",
      subtitle = if (show_mcse) {
        "Shaded regions show 95% CI from Monte Carlo uncertainty"
      } else {
        NULL
      }
    ) +
    theme_minimal() +
    theme(
      legend.position = "top",
      plot.title = element_text(face = "bold", hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5)
    )

  return(p)
}


#' Create bias-coverage plot
#'
#' @param summary_stats Summary statistics from simulation
#' @param target_coverage Target coverage level (default 0.95)
#'
#' @return ggplot object
#' @export
plot_bias_coverage <- function(summary_stats, target_coverage = 0.95) {
  p <- ggplot(summary_stats, aes(x = bias, y = coverage, color = method)) +
    geom_hline(yintercept = target_coverage, linetype = "dashed", alpha = 0.5) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
    geom_point(aes(size = n), alpha = 0.6) +
    geom_errorbar(
      aes(
        ymin = coverage - 1.96 * coverage_mcse,
        ymax = coverage + 1.96 * coverage_mcse
      ),
      width = 0.001,
      alpha = 0.3
    ) +
    geom_errorbarh(
      aes(xmin = bias - 1.96 * bias_mcse, xmax = bias + 1.96 * bias_mcse),
      height = 0.01,
      alpha = 0.3
    ) +
    scale_y_continuous(labels = scales::percent) +
    scale_size_continuous(
      range = c(2, 6),
      guide = guide_legend(title = "Sample Size")
    ) +
    labs(
      x = "Bias",
      y = "Coverage Probability",
      title = "Bias vs Coverage Trade-off",
      subtitle = "Ideal point at (0, 95%)"
    ) +
    theme_minimal() +
    theme(
      legend.position = "right",
      plot.title = element_text(face = "bold", hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5)
    )

  return(p)
}


#' Create factorial heatmap of performance metrics
#'
#' @param summary_stats Summary statistics from simulation
#' @param metric Which metric to display ("power", "bias", "coverage", "rmse")
#' @param facet_by Variable to facet by (default "method")
#'
#' @return ggplot object
#' @export
plot_factorial_heatmap <- function(
  summary_stats,
  metric = "power",
  facet_by = "method"
) {
  # Select metric column and label
  metric_info <- switch(
    metric,
    "power" = list(col = "power", label = "Power", limits = c(0, 1)),
    "bias" = list(col = "bias", label = "Bias", limits = c(-0.1, 0.1)),
    "coverage" = list(
      col = "coverage",
      label = "Coverage",
      limits = c(0.85, 1)
    ),
    "rmse" = list(col = "rmse", label = "RMSE", limits = NULL)
  )

  plot_data <- summary_stats
  plot_data$metric_value <- plot_data[[metric_info$col]]

  p <- ggplot(
    plot_data,
    aes(x = factor(dropout), y = factor(misclass), fill = metric_value)
  ) +
    geom_tile(color = "white", size = 0.5) +
    facet_grid(reformulate(facet_by, "p0"), labeller = label_both) +
    scale_x_discrete(labels = scales::percent) +
    scale_y_discrete(labels = scales::percent) +
    labs(
      x = "Dropout Rate",
      y = "Misclassification Rate",
      fill = metric_info$label,
      title = paste("Factorial Design:", metric_info$label),
      subtitle = "Performance across scenario grid"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(face = "bold", hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5),
      strip.background = element_rect(fill = "gray95", color = NA),
      strip.text = element_text(face = "bold")
    )

  # Add appropriate color scale
  if (metric == "power" || metric == "coverage") {
    p <- p +
      scale_fill_viridis_c(
        limits = metric_info$limits,
        labels = scales::percent
      )
  } else if (metric == "bias") {
    p <- p +
      scale_fill_gradient2(
        low = "blue",
        mid = "white",
        high = "red",
        midpoint = 0,
        limits = metric_info$limits
      )
  } else {
    p <- p + scale_fill_viridis_c(limits = metric_info$limits)
  }

  return(p)
}


#' Create performance comparison plot across methods
#'
#' @param summary_stats Summary statistics from simulation
#' @param metrics Vector of metrics to include
#'
#' @return ggplot object
#' @export
plot_method_comparison <- function(
  summary_stats,
  metrics = c("power", "bias", "coverage", "rmse")
) {
  # Reshape data for plotting
  plot_data <- summary_stats %>%
    select(n, method, all_of(metrics)) %>%
    pivot_longer(
      cols = all_of(metrics),
      names_to = "metric",
      values_to = "value"
    ) %>%
    mutate(
      metric = factor(metric, levels = metrics),
      metric_label = case_when(
        metric == "power" ~ "Power",
        metric == "bias" ~ "Bias",
        metric == "coverage" ~ "Coverage",
        metric == "rmse" ~ "RMSE"
      )
    )

  # Create separate plots for each metric
  plot_list <- list()

  for (m in unique(plot_data$metric_label)) {
    p <- plot_data %>%
      filter(metric_label == m) %>%
      ggplot(aes(x = method, y = value, fill = method)) +
      geom_boxplot(alpha = 0.7) +
      geom_jitter(width = 0.1, alpha = 0.3, size = 0.5) +
      labs(
        x = NULL,
        y = m,
        title = m
      ) +
      theme_minimal() +
      theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(face = "bold", hjust = 0.5, size = 10)
      )

    # Add reference lines based on metric
    if (m == "Power") {
      p <- p +
        geom_hline(
          yintercept = 0.80,
          linetype = "dashed",
          color = "red",
          alpha = 0.5
        )
    } else if (m == "Bias") {
      p <- p +
        geom_hline(
          yintercept = 0,
          linetype = "dashed",
          color = "red",
          alpha = 0.5
        )
    } else if (m == "Coverage") {
      p <- p +
        geom_hline(
          yintercept = 0.95,
          linetype = "dashed",
          color = "red",
          alpha = 0.5
        )
    }

    plot_list[[m]] <- p
  }

  # Combine plots
  combined_plot <- wrap_plots(plot_list, ncol = 2) +
    plot_annotation(
      title = "Method Performance Comparison",
      subtitle = "Distribution across all scenarios"
    )

  return(combined_plot)
}


#' Create convergence diagnostic plot
#'
#' @param results Raw simulation results
#'
#' @return ggplot object
#' @export
plot_convergence_diagnostics <- function(results) {
  conv_data <- results %>%
    group_by(n, method, p0, dropout, misclass) %>%
    summarise(
      convergence_rate = mean(converged, na.rm = TRUE),
      n_failed = sum(!converged, na.rm = TRUE),
      .groups = "drop"
    )

  p1 <- ggplot(conv_data, aes(x = n, y = convergence_rate, color = method)) +
    geom_line(
      aes(group = interaction(method, p0, dropout, misclass)),
      alpha = 0.3
    ) +
    geom_smooth(se = TRUE, method = "loess") +
    scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
    labs(
      x = "Sample Size per Arm",
      y = "Convergence Rate",
      title = "Convergence by Sample Size"
    ) +
    theme_minimal()

  p2 <- conv_data %>%
    filter(n_failed > 0) %>%
    ggplot(aes(x = method, y = n_failed, fill = method)) +
    geom_boxplot(alpha = 0.7) +
    scale_y_log10() +
    labs(
      x = "Method",
      y = "Number of Failures (log scale)",
      title = "Distribution of Convergence Failures"
    ) +
    theme_minimal() +
    theme(legend.position = "none")

  combined <- p1 +
    p2 +
    plot_annotation(
      title = "Convergence Diagnostics",
      subtitle = "Monitoring numerical stability"
    )

  return(combined)
}


#' Create ADEMP summary visualization
#'
#' @param config Simulation configuration
#' @param summary_stats Summary statistics
#'
#' @return Combined plot object
#' @export
plot_ademp_summary <- function(config, summary_stats) {
  # Create individual components
  p1 <- plot_power_curve(summary_stats)
  p2 <- plot_bias_coverage(summary_stats)
  p3 <- plot_factorial_heatmap(summary_stats, metric = "power")
  p4 <- plot_method_comparison(
    summary_stats,
    metrics = c("power", "bias", "coverage")
  )

  # Combine with layout
  layout <- "
  AAABBB
  AAABBB
  CCCDDD
  CCCDDD
  "

  combined <- p1 +
    p2 +
    p3 +
    p4 +
    plot_layout(design = layout) +
    plot_annotation(
      title = "ADEMP Simulation Study Results",
      subtitle = paste0("R = ", config$R, " simulations per scenario"),
      caption = paste0("Generated: ", Sys.Date())
    )

  return(combined)
}


#' Create interactive power curve using plotly
#'
#' @param summary_stats Summary statistics from simulation
#' @param target_power Target power level
#'
#' @return plotly object
#' @export
plot_power_curve_interactive <- function(summary_stats, target_power = 0.80) {
  library(plotly)

  # Prepare data
  plot_data <- summary_stats %>%
    mutate(
      lower = power - 1.96 * power_mcse,
      upper = power + 1.96 * power_mcse,
      hover_text = paste0(
        "Method: ",
        method,
        "<br>",
        "N per arm: ",
        n,
        "<br>",
        "Power: ",
        round(power * 100, 1),
        "%<br>",
        "95% CI: [",
        round(lower * 100, 1),
        "%, ",
        round(upper * 100, 1),
        "%]<br>",
        "MCSE: ",
        round(power_mcse * 100, 2),
        "%"
      )
    )

  # Create plot
  p <- plot_ly()

  # Add traces for each method
  for (m in unique(plot_data$method)) {
    method_data <- filter(plot_data, method == m)

    # Add confidence band
    p <- p %>%
      add_trace(
        data = method_data,
        x = ~n,
        y = ~upper,
        type = "scatter",
        mode = "lines",
        line = list(width = 0),
        showlegend = FALSE,
        hoverinfo = "skip"
      ) %>%
      add_trace(
        data = method_data,
        x = ~n,
        y = ~lower,
        type = "scatter",
        mode = "lines",
        fill = "tonexty",
        fillcolor = "rgba(68, 68, 68, 0.2)",
        line = list(width = 0),
        showlegend = FALSE,
        hoverinfo = "skip"
      )

    # Add main line
    p <- p %>%
      add_trace(
        data = method_data,
        x = ~n,
        y = ~power,
        type = "scatter",
        mode = "lines+markers",
        name = m,
        line = list(width = 2),
        marker = list(size = 6),
        text = ~hover_text,
        hoverinfo = "text"
      )
  }

  # Add target power line
  p <- p %>%
    add_trace(
      x = range(plot_data$n),
      y = c(target_power, target_power),
      type = "scatter",
      mode = "lines",
      line = list(dash = "dash", color = "red", width = 1),
      name = paste0(target_power * 100, "% Target"),
      hoverinfo = "skip"
    )

  # Layout
  p <- p %>%
    layout(
      title = list(text = "Interactive Power Analysis"),
      xaxis = list(title = "Sample Size per Arm"),
      yaxis = list(
        title = "Statistical Power",
        tickformat = ".0%",
        range = c(0, 1)
      ),
      hovermode = "closest",
      legend = list(x = 0.7, y = 0.2)
    )

  return(p)
}


#' Save all plots to files
#'
#' @param summary_stats Summary statistics
#' @param config Configuration
#' @param path Output directory
#' @param format File format ("png", "pdf", "svg")
#' @param width Plot width in inches
#' @param height Plot height in inches
#' @param dpi Resolution for raster formats
#'
#' @export
save_all_plots <- function(
  summary_stats,
  config,
  path = "figures",
  format = "png",
  width = 10,
  height = 8,
  dpi = 300
) {
  # Create directory if needed
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }

  # Generate all plots
  plots <- list(
    power_curve = plot_power_curve(summary_stats),
    bias_coverage = plot_bias_coverage(summary_stats),
    factorial_heatmap = plot_factorial_heatmap(summary_stats),
    method_comparison = plot_method_comparison(summary_stats),
    ademp_summary = plot_ademp_summary(config, summary_stats)
  )

  # Save each plot
  for (name in names(plots)) {
    filename <- file.path(path, paste0(name, ".", format))

    ggsave(
      filename = filename,
      plot = plots[[name]],
      width = width,
      height = height,
      dpi = dpi,
      units = "in"
    )

    message("Saved: ", filename)
  }

  invisible(plots)
}
