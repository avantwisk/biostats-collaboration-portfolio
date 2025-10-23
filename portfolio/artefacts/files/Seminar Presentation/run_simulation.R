# run_simulation.R
# Example script to run ADEMP simulation study
# Author: Alexander van Twisk
# Date: 2025-10-11

# Load required libraries and helper functions
library(tidyverse)
library(furrr)
library(progressr)
source("R/simulation_helpers.R")
source("R/visualization_helpers.R")

# ============================================================================
# CONFIGURATION (Following ADEMP Framework)
# ============================================================================

# Set up simulation configuration
config <- list(
  # Simulation parameters
  R = 2000, # Number of simulation replications
  seed = 20251011, # Master seed for reproducibility

  # Sample size sequence to test
  n_seq = seq(80, 400, by = 20),

  # Data-generating mechanism parameters
  p0_values = c(0.15, 0.25), # Baseline event rates
  delta = -0.05, # Target treatment effect (risk difference)
  dropout_values = c(0, 0.10), # Dropout rates (MCAR)
  misclass_values = c(0, 0.02), # Misclassification rates

  # Methods to compare
  methods = c("logistic", "prop.test"),

  # Performance criteria
  alpha = 0.05, # Type I error rate
  target_power = 0.80, # Target power
  target_coverage = 0.95, # Target coverage probability

  # Computational settings
  max_retries = 1, # Maximum convergence retries
  parallel = TRUE, # Use parallel processing
  n_cores = parallel::detectCores() - 1 # Leave one core free
)

# ============================================================================
# RUN SIMULATION
# ============================================================================

cat("ADEMP Simulation Study\n")
cat("======================\n")
cat("Configuration:\n")
cat("  R =", config$R, "replications\n")
cat("  N range:", min(config$n_seq), "to", max(config$n_seq), "\n")
cat(
  "  Scenarios:",
  length(config$p0_values) *
    length(config$dropout_values) *
    length(config$misclass_values),
  "\n"
)
cat("  Methods:", paste(config$methods, collapse = ", "), "\n")
cat("  Parallel:", config$parallel, "with", config$n_cores, "cores\n")
cat("\n")

# Set master seed
set.seed(config$seed)

# Run main simulation with progress bar
cat("Running simulations...\n")
start_time <- Sys.time()

progressr::with_progress({
  results <- run_simulation_study(config)
})

end_time <- Sys.time()
run_time <- difftime(end_time, start_time, units = "mins")

cat("\nSimulation complete in", round(run_time, 1), "minutes\n")
cat("Total simulations run:", nrow(results), "\n")

# ============================================================================
# SUMMARIZE RESULTS
# ============================================================================

cat("\nSummarizing results...\n")

# Calculate summary statistics
summary_stats <- summarize_simulation_results(results, config)

# Find optimal sample sizes
optimal_n <- summary_stats %>%
  filter(power >= config$target_power) %>%
  group_by(method, p0, dropout, misclass) %>%
  slice_min(n, n = 1) %>%
  ungroup()

# Print key findings
cat("\n")
cat("Key Findings\n")
cat("============\n")

# Overall convergence
cat("\nConvergence rates:\n")
summary_stats %>%
  group_by(method) %>%
  summarise(
    mean_convergence = mean(convergence_rate),
    min_convergence = min(convergence_rate),
    .groups = "drop"
  ) %>%
  print()

# Sample size requirements
cat("\nSample sizes for", config$target_power * 100, "% power:\n")
optimal_n %>%
  select(method, p0, dropout, misclass, n) %>%
  arrange(method, n) %>%
  print(n = 20)

# Type I error (if delta = 0 scenarios exist)
if (any(abs(config$delta) < .Machine$double.eps)) {
  cat("\nType I error rates:\n")
  summary_stats %>%
    filter(abs(config$delta) < .Machine$double.eps) %>%
    group_by(method) %>%
    summarise(
      mean_type_i = mean(power),
      mcse_type_i = sqrt(mean(power * (1 - power)) / n()),
      .groups = "drop"
    ) %>%
    print()
}

# ============================================================================
# CREATE VISUALIZATIONS
# ============================================================================

cat("\nCreating visualizations...\n")

# Create output directories
dir.create("output", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# Generate main plots
plots <- list()

# 1. Power curves by scenario
for (p0_val in config$p0_values) {
  for (drop_val in config$dropout_values) {
    scenario_data <- summary_stats %>%
      filter(p0 == p0_val, dropout == drop_val)

    if (nrow(scenario_data) > 0) {
      plot_name <- paste0("power_p0_", p0_val, "_dropout_", drop_val)
      plots[[plot_name]] <- plot_power_curve(
        scenario_data,
        target_power = config$target_power
      ) +
        labs(
          subtitle = paste0(
            "p₀ = ",
            p0_val,
            ", dropout = ",
            drop_val * 100,
            "%"
          )
        )
    }
  }
}

# 2. Overall power comparison
plots$power_overall <- plot_power_curve(summary_stats, config$target_power)

# 3. Bias-coverage trade-off
plots$bias_coverage <- plot_bias_coverage(summary_stats, config$target_coverage)

# 4. Factorial heatmap
plots$factorial <- plot_factorial_heatmap(summary_stats, metric = "power")

# 5. Method comparison
plots$comparison <- plot_method_comparison(
  summary_stats,
  metrics = c("power", "bias", "coverage", "rmse")
)

# 6. Convergence diagnostics
plots$convergence <- plot_convergence_diagnostics(results)

# 7. Complete ADEMP summary
plots$ademp_summary <- plot_ademp_summary(config, summary_stats)

# Save all plots
save_all_plots(summary_stats, config, path = "figures", format = "png")

# Create interactive power curve
if (require(plotly, quietly = TRUE)) {
  interactive_plot <- plot_power_curve_interactive(
    summary_stats,
    target_power = config$target_power
  )

  htmlwidgets::saveWidget(
    interactive_plot,
    file.path("figures", "power_curve_interactive.html"),
    selfcontained = TRUE
  )
  cat("  Interactive plot saved\n")
}

# ============================================================================
# CREATE ADEMP REPORT
# ============================================================================

cat("\nGenerating ADEMP report...\n")

# Create ADEMP table
ademp_table <- create_ademp_table(config, results)

# Print ADEMP table
cat("\nADEMP Framework Summary\n")
cat("=======================\n")
print(ademp_table)

# ============================================================================
# EXPORT RESULTS
# ============================================================================

cat("\nExporting results...\n")

# Save all results and configuration
export_files <- export_simulation_results(
  results = results,
  config = config,
  path = "output",
  prefix = "ademp_simulation"
)

# Create summary report
report_text <- c(
  "ADEMP Simulation Study Report",
  "=============================",
  paste("Generated:", Sys.time()),
  paste("R version:", R.version.string),
  "",
  "Configuration",
  "-------------",
  paste("Replications:", config$R),
  paste("Sample sizes:", paste(range(config$n_seq), collapse = " to ")),
  paste("Baseline rates:", paste(config$p0_values, collapse = ", ")),
  paste("Treatment effect:", config$delta),
  paste("Dropout rates:", paste(config$dropout_values, collapse = ", ")),
  paste("Misclassification:", paste(config$misclass_values, collapse = ", ")),
  paste("Methods:", paste(config$methods, collapse = ", ")),
  paste("Alpha:", config$alpha),
  paste("Target power:", config$target_power),
  "",
  "Key Results",
  "-----------",
  paste("Total scenarios:", nrow(optimal_n)),
  paste(
    "Convergence rate:",
    round(mean(summary_stats$convergence_rate) * 100, 1),
    "%"
  ),
  "",
  "Optimal Sample Sizes (per arm):",
  capture.output(print(
    optimal_n %>%
      select(method, p0, dropout, misclass, n) %>%
      arrange(n)
  )),
  "",
  "Runtime",
  "-------",
  paste("Total time:", round(run_time, 2), "minutes"),
  paste(
    "Time per simulation:",
    round(as.numeric(run_time) * 60 / nrow(results), 3),
    "seconds"
  ),
  "",
  "Output Files",
  "------------",
  paste("Results:", export_files$results),
  paste("Config:", export_files$config),
  paste("Summary:", export_files$summary),
  paste("ADEMP table:", export_files$ademp),
  paste("Session info:", export_files$session)
)

writeLines(report_text, file.path("output", "simulation_report.txt"))

# ============================================================================
# FINAL MESSAGE
# ============================================================================

cat("\n")
cat("=====================================\n")
cat("Simulation study complete!\n")
cat("=====================================\n")
cat("\nResults saved to:\n")
cat("  - Figures: ./figures/\n")
cat("  - Data: ./output/\n")
cat("  - Report: ./output/simulation_report.txt\n")
cat("\nNext steps:\n")
cat("  1. Review the ADEMP summary table\n")
cat("  2. Check convergence diagnostics\n")
cat("  3. Examine power curves for your scenarios\n")
cat("  4. Validate results with sensitivity analysis\n")
cat("\n")

# Return key results
invisible(list(
  results = results,
  summary = summary_stats,
  optimal_n = optimal_n,
  ademp_table = ademp_table,
  plots = plots,
  config = config
))
