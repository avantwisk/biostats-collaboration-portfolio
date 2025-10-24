### Simulating power for a two-arm trial with dropout
library(dplyr)
library(purrr)
library(tidyr)
library(gt)

#Parameters
n_enrolled <- 60
p0 <- 0.30
p1 <- 0.45
dropout <- 0.1
alpha <- 0.05

simulate_one_trial <- function(n_enrolled, p0, p1, dropout, alpha) {
  # Apply dropout to get observed sample sizes
  n0_obs <- rbinom(1, n_enrolled, 1 - dropout)
  n1_obs <- rbinom(1, n_enrolled, 1 - dropout)

  # Skip if either group is empty
  if (n0_obs == 0 || n1_obs == 0) {
    return(NA)
  }

  # Generate outcomes
  y0 <- rbinom(1, n0_obs, p0)
  y1 <- rbinom(1, n1_obs, p1)

  # Test for difference in proportions
  test <- prop.test(x = c(y1, y0), n = c(n1_obs, n0_obs))

  # Return TRUE if we reject H0
  test$p.value < alpha
}

# Run simulation for a given sample size
simulate_power <- function(n_enrolled, p0, p1, dropout, nsim = 2000, alpha) {
  # Simulate nsim trials
  results <- map_lgl(
    1:nsim,
    ~ simulate_one_trial(n_enrolled, p0, p1, dropout, alpha)
  )

  # Calculate power and MCSE
  power_hat <- mean(results, na.rm = TRUE)
  mcse <- sqrt(power_hat * (1 - power_hat) / sum(!is.na(results)))

  tibble(power = power_hat, mcse = mcse)
}

### Exploration: Wide

# Test a range of sample sizes
n_grid <- seq(50, 350, by = 10)

# Run simulation for each sample size
res <- map_df(
  n_grid,
  ~ {
    simulate_power(
      n_enrolled = .x,
      p0 = 0.3,
      p1 = 0.45,
      dropout = 0.1,
      nsim = 2000,
      alpha = 0.05
    ) %>%
      mutate(n_enrolled = .x)
  }
)

res %>%
  gt() %>%
  tab_header(
    title = "Power Simulation Results"
  ) %>%
  cols_label(
    n_enrolled = "Sample Size per Arm",
    power = "Estimated Power",
    mcse = "Monte Carlo SE"
  ) %>%
  cols_align("center") -> res_table

# Find smallest n achieving target power
chosen_n <- res %>%
  filter(power >= power_target) %>%
  slice_min(n_enrolled, n = 1) %>%
  pull(n_enrolled)

### Exploration: Narrow

# Test a range of sample sizes
n_grid <- seq(180, 220, by = 1)

# Run simulation for each sample size
res_narrow <- map_df(
  n_grid,
  ~ {
    simulate_power(
      n_enrolled = .x,
      p0 = 0.3,
      p1 = 0.45,
      dropout = 0.1,
      nsim = 5000,
      alpha = 0.05
    ) %>%
      mutate(n_enrolled = .x)
  }
)

res_narrow %>% gt::gt()

# Find smallest n achieving target power
chosen_n_narrow <- res_narrow %>%
  filter(power >= power_target) %>%
  slice_min(n_enrolled, n = 1) %>%
  pull(n_enrolled)
