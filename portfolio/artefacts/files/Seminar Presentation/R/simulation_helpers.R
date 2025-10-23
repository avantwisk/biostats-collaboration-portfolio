# simulation_helpers.R
# Helper functions for ADEMP simulation framework
# Author: Alexander van Twisk
# Date: 2025-10-11

#' Generate simulated trial data with realistic features
#'
#' @param n Sample size per arm
#' @param p0 Control group event rate
#' @param delta Treatment effect (risk difference)
#' @param dropout Proportion of dropout (MCAR)
#' @param misclass Misclassification rate (non-differential)
#' @param seed Random seed for reproducibility
#'
#' @return Data frame with treatment and outcome
#' @export
generate_trial_data <- function(
  n,
  p0,
  delta = -0.05,
  dropout = 0,
  misclass = 0,
  seed = NULL
) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  # Generate treatment assignment (balanced)
  trt <- rep(0:1, each = n)
  n_total <- length(trt)

  # Calculate treatment group probability
  p1 <- p0 + delta

  # Ensure probabilities are valid
  p1 <- pmax(0, pmin(1, p1))

  # Generate true outcomes
  y_true <- rbinom(n_total, 1, ifelse(trt == 0, p0, p1))

  # Apply dropout (MCAR - Missing Completely At Random)
  if (dropout > 0) {
    observed <- rbinom(n_total, 1, 1 - dropout)
  } else {
    observed <- rep(1, n_total)
  }

  # Apply misclassification (non-differential)
  if (misclass > 0) {
    misclass_indicator <- rbinom(n_total, 1, misclass)
    y_obs <- ifelse(misclass_indicator == 1, 1 - y_true, y_true)
  } else {
    y_obs <- y_true
  }

  # Create output data frame (complete cases only)
  data.frame(
    id = seq_len(n_total)[observed == 1],
    trt = trt[observed == 1],
    y = y_obs[observed == 1],
    stringsAsFactors = FALSE
  )
}


#' Fit statistical model with error handling
#'
#' @param data Data frame with trt and y columns
#' @param method Method to use ("logistic", "prop.test")
#' @param max_retries Maximum number of convergence retries
#'
#' @return List with results or NA values if failed
#' @export
fit_model <- function(data, method = "logistic", max_retries = 1) {
  results <- list(
    estimate = NA_real_,
    se = NA_real_,
    ci_lower = NA_real_,
    ci_upper = NA_real_,
    p_value = NA_real_,
    converged = FALSE,
    method = method
  )

  # Check if there's enough data
  if (nrow(data) < 10 || length(unique(data$trt)) < 2) {
    return(results)
  }

  if (method == "logistic") {
    # Logistic regression with retries
    attempt <- 0
    while (attempt <= max_retries) {
      attempt <- attempt + 1

      tryCatch(
        {
          fit <- glm(y ~ trt, data = data, family = binomial(link = "logit"))

          if (fit$converged) {
            coef_summary <- coef(summary(fit))

            if ("trt" %in% rownames(coef_summary)) {
              results$estimate <- coef_summary["trt", "Estimate"]
              results$se <- coef_summary["trt", "Std. Error"]
              results$ci_lower <- results$estimate - 1.96 * results$se
              results$ci_upper <- results$estimate + 1.96 * results$se
              results$p_value <- coef_summary["trt", "Pr(>|z|)"]
              results$converged <- TRUE
              break
            }
          }
        },
        error = function(e) {
          # Continue to next attempt
        }
      )
    }
  } else if (method == "prop.test") {
    # Proportion test
    tryCatch(
      {
        tab <- table(data$trt, data$y)

        if (nrow(tab) == 2 && ncol(tab) == 2) {
          test <- prop.test(tab[, 2], rowSums(tab), correct = FALSE)

          results$estimate <- diff(test$estimate) # p1 - p0
          results$ci_lower <- test$conf.int[1]
          results$ci_upper <- test$conf.int[2]
          results$p_value <- test$p.value
          results$converged <- TRUE

          # Calculate SE from CI
          results$se <- (results$ci_upper - results$ci_lower) / (2 * 1.96)
        }
      },
      error = function(e) {
        # Results remain NA
      }
    )
  }

  return(results)
}


#' Run single simulation iteration
#'
#' @param n Sample size per arm
#' @param config List with simulation configuration
#'
#' @return Data frame with simulation results
#' @export
run_single_simulation <- function(n, config) {
  # Generate data
  data <- generate_trial_data(
    n = n,
    p0 = config$p0,
    delta = config$delta,
    dropout = config$dropout,
    misclass = config$misclass
  )

  # Fit models
  results_list <- list()

  for (method in config$methods) {
    fit_result <- fit_model(
      data,
      method = method,
      max_retries = config$max_retries
    )

    results_list[[method]] <- data.frame(
      n = n,
      method = method,
      estimate = fit_result$estimate,
      se = fit_result$se,
      ci_lower = fit_result$ci_lower,
      ci_upper = fit_result$ci_upper,
      p_value = fit_result$p_value,
      converged = fit_result$converged,
      reject = fit_result$p_value < config$alpha,
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, results_list)
}


#' Run full simulation study
#'
#' @param config List with full simulation configuration
#' @param parallel Whether to use parallel processing
#' @param n_cores Number of cores for parallel processing
#' @param progress Whether to show progress bar
#'
#' @return Data frame with all simulation results
#' @export
run_simulation_study <- function(
  config,
  parallel = TRUE,
  n_cores = NULL,
  progress = TRUE
) {
  # Validate configuration
  config <- validate_config(config)

  # Setup parallel processing if requested
  if (parallel) {
    if (is.null(n_cores)) {
      n_cores <- parallel::detectCores() - 1
    }
    future::plan(future::multisession, workers = n_cores)
  } else {
    future::plan(future::sequential)
  }

  # Create scenario grid
  scenarios <- expand.grid(
    n = config$n_seq,
    p0 = config$p0_values,
    dropout = config$dropout_values,
    misclass = config$misclass_values,
    stringsAsFactors = FALSE
  )

  # Progress setup
  if (progress) {
    pb <- progressr::progressor(steps = nrow(scenarios) * config$R)
  }

  # Run simulations
  results <- furrr::future_map_dfr(
    seq_len(nrow(scenarios)),
    function(i) {
      scenario <- scenarios[i, ]

      # Update config for this scenario
      current_config <- config
      current_config$p0 <- scenario$p0
      current_config$dropout <- scenario$dropout
      current_config$misclass <- scenario$misclass

      # Run R replications for this scenario
      replicate_results <- map_dfr(
        seq_len(config$R),
        function(r) {
          if (progress) {
            pb()
          }

          result <- run_single_simulation(scenario$n, current_config)
          result$rep <- r
          result$p0 <- scenario$p0
          result$dropout <- scenario$dropout
          result$misclass <- scenario$misclass
          result
        }
      )

      replicate_results
    },
    .options = furrr::furrr_options(seed = TRUE)
  )

  # Reset future plan
  future::plan(future::sequential)

  return(results)
}


#' Summarize simulation results
#'
#' @param results Data frame with simulation results
#' @param config Simulation configuration
#'
#' @return Data frame with summarized results
#' @export
summarize_simulation_results <- function(results, config) {
  summary_stats <- results %>%
    group_by(n, method, p0, dropout, misclass) %>%
    summarise(
      n_sims = n(),
      n_converged = sum(converged, na.rm = TRUE),
      convergence_rate = mean(converged, na.rm = TRUE),

      # Power (for delta != 0) or Type I error (for delta == 0)
      power = mean(reject, na.rm = TRUE),
      power_mcse = sqrt(power * (1 - power) / n()),

      # Bias (if true value is known)
      bias = mean(estimate - config$delta, na.rm = TRUE),
      bias_mcse = sd(estimate, na.rm = TRUE) / sqrt(n()),

      # RMSE
      rmse = sqrt(mean((estimate - config$delta)^2, na.rm = TRUE)),

      # Coverage
      coverage = mean(
        ci_lower <= config$delta & ci_upper >= config$delta,
        na.rm = TRUE
      ),
      coverage_mcse = sqrt(coverage * (1 - coverage) / n()),

      # Average CI width
      ci_width = mean(ci_upper - ci_lower, na.rm = TRUE),

      .groups = "drop"
    )

  return(summary_stats)
}


#' Calculate Monte Carlo standard errors
#'
#' @param x Vector of values
#' @param type Type of MCSE ("mean", "proportion", "variance")
#'
#' @return Monte Carlo standard error
#' @export
calculate_mcse <- function(x, type = "mean") {
  n <- length(x)

  if (n == 0) {
    return(NA_real_)
  }

  switch(
    type,
    "mean" = sd(x, na.rm = TRUE) / sqrt(n),
    "proportion" = {
      p <- mean(x, na.rm = TRUE)
      sqrt(p * (1 - p) / n)
    },
    "variance" = {
      # Using delta method approximation
      v <- var(x, na.rm = TRUE)
      sqrt(2 * v^2 / (n - 1))
    },
    NA_real_
  )
}


#' Validate simulation configuration
#'
#' @param config List with simulation parameters
#'
#' @return Validated configuration list
#' @export
validate_config <- function(config) {
  # Set defaults if missing
  defaults <- list(
    R = 1000,
    n_seq = seq(50, 500, by = 50),
    p0_values = 0.25,
    delta = -0.05,
    dropout_values = 0,
    misclass_values = 0,
    methods = c("logistic", "prop.test"),
    alpha = 0.05,
    max_retries = 1
  )

  for (name in names(defaults)) {
    if (!name %in% names(config)) {
      config[[name]] <- defaults[[name]]
    }
  }

  # Validate ranges
  stopifnot(
    config$R > 0,
    all(config$n_seq > 0),
    all(config$p0_values >= 0 & config$p0_values <= 1),
    all(config$dropout_values >= 0 & config$dropout_values < 1),
    all(config$misclass_values >= 0 & config$misclass_values < 0.5),
    config$alpha > 0 & config$alpha < 1,
    config$max_retries >= 0
  )

  return(config)
}


#' Create ADEMP reporting table
#'
#' @param config Simulation configuration
#' @param results Optional results to include summary
#'
#' @return Data frame formatted as ADEMP table
#' @export
create_ademp_table <- function(config, results = NULL) {
  ademp_table <- data.frame(
    Component = c(
      "Aims",
      "Data-generating mechanisms",
      "Estimands",
      "Methods",
      "Performance measures"
    ),
    Description = c(
      paste0(
        "Determine sample size for ",
        100 * (1 - config$alpha),
        "% power to detect Δ = ",
        config$delta
      ),
      paste0(
        "p0 ∈ {",
        paste(config$p0_values, collapse = ", "),
        "}; ",
        "dropout ∈ {",
        paste(config$dropout_values, collapse = ", "),
        "}; ",
        "misclassification ∈ {",
        paste(config$misclass_values, collapse = ", "),
        "}"
      ),
      "Population risk difference (marginal effect)",
      paste(config$methods, collapse = ", "),
      "Power, bias, coverage, RMSE with Monte Carlo SEs"
    ),
    stringsAsFactors = FALSE
  )

  if (!is.null(results)) {
    # Add summary statistics if results provided
    summary_stats <- summarize_simulation_results(results, config)
    ademp_table$Summary <- c(
      paste0("R = ", config$R, " simulations"),
      paste0(
        nrow(expand.grid(
          p0 = config$p0_values,
          dropout = config$dropout_values,
          misclass = config$misclass_values
        )),
        " scenarios"
      ),
      paste0("True value: Δ = ", config$delta),
      paste0(length(config$methods), " methods compared"),
      paste0(
        "Mean convergence: ",
        round(100 * mean(summary_stats$convergence_rate), 1),
        "%"
      )
    )
  }

  return(ademp_table)
}


#' Export simulation results
#'
#' @param results Data frame with results
#' @param config Simulation configuration
#' @param path Output directory path
#' @param prefix File name prefix
#'
#' @export
export_simulation_results <- function(
  results,
  config,
  path = "output",
  prefix = "simulation"
) {
  # Create output directory if needed
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }

  # Timestamp for file names
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

  # Save raw results
  saveRDS(
    results,
    file.path(path, paste0(prefix, "_results_", timestamp, ".rds"))
  )

  # Save configuration
  saveRDS(
    config,
    file.path(path, paste0(prefix, "_config_", timestamp, ".rds"))
  )

  # Save summary
  summary_stats <- summarize_simulation_results(results, config)
  write.csv(
    summary_stats,
    file.path(path, paste0(prefix, "_summary_", timestamp, ".csv")),
    row.names = FALSE
  )

  # Save ADEMP table
  ademp_table <- create_ademp_table(config, results)
  write.csv(
    ademp_table,
    file.path(path, paste0(prefix, "_ademp_", timestamp, ".csv")),
    row.names = FALSE
  )

  # Save session info
  writeLines(
    capture.output(sessionInfo()),
    file.path(path, paste0(prefix, "_session_", timestamp, ".txt"))
  )

  message("Results saved to ", path)
  invisible(list(
    results = file.path(path, paste0(prefix, "_results_", timestamp, ".rds")),
    config = file.path(path, paste0(prefix, "_config_", timestamp, ".rds")),
    summary = file.path(path, paste0(prefix, "_summary_", timestamp, ".csv")),
    ademp = file.path(path, paste0(prefix, "_ademp_", timestamp, ".csv")),
    session = file.path(path, paste0(prefix, "_session_", timestamp, ".txt"))
  ))
}
