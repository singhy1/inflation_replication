# R Package Setup for Replication
# ================================
# This script installs all required R packages for the replication study
# Run this file before executing any R scripts in the replication

# INSTRUCTIONS:
# 1. Make sure you have R 4.0+ installed
# 2. Open R or RStudio
# 3. Run this script: source("0_setup_r.R")
# 4. Alternatively, copy and paste the code below into your R console

cat("Setting up R environment for replication study...\n")
cat("=" %R% strrep("=", 59), "\n")

# Set CRAN mirror for package installation
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Required packages for the replication
required_packages <- c(
  # Data manipulation and analysis
  "tidyverse",      # Collection of packages (dplyr, ggplot2, readr, etc.)
  
  # Data import/export
  "haven",          # For reading Stata files (.dta)
  "writexl",        # For writing Excel files
  "ipumsr",         # For working with IPUMS data
  
  # Plotting and visualization
  "ggplot2",        # Already included in tidyverse, but listing explicitly
  
  # Base R packages (usually pre-installed)
  # stats, utils, base are part of base R
)

# Function to install packages if not already installed
install_if_missing <- function(pkg) {
  if (!(pkg %in% rownames(installed.packages()))) {
    cat("Installing", pkg, "...\n")
    suppressMessages(
      suppressWarnings(
        install.packages(pkg, quietly = TRUE, dependencies = TRUE)
      )
    )
    
    # Check if installation was successful
    if (pkg %in% rownames(installed.packages())) {
      cat("✓ Successfully installed", pkg, "\n")
    } else {
      cat("✗ Failed to install", pkg, "\n")
    }
  } else {
    cat("✓", pkg, "already installed\n")
  }
}

# Install all required packages
cat("\nInstalling", length(required_packages), "required packages...\n")
for (pkg in required_packages) {
  install_if_missing(pkg)
}

# Load packages to test installation
cat("\nTesting package loading...\n")
for (pkg in required_packages) {
  result <- tryCatch({
    suppressMessages(library(pkg, character.only = TRUE))
    cat("✓", pkg, "loaded successfully\n")
  }, error = function(e) {
    cat("✗ Error loading", pkg, ":", e$message, "\n")
  })
}

cat("\n" %R% strrep("=", 60), "\n")
cat("R package setup completed!\n")
cat("\nIf you encounter any issues:\n")
cat("1. Make sure you have R 4.0+ installed\n")
cat("2. Try updating R and RStudio to the latest versions\n")
cat("3. Install packages individually if batch installation fails\n")
cat("4. Check your internet connection\n")
cat("5. Try install.packages('package_name', dependencies = TRUE)\n")

# Display session info for debugging
cat("\nSession Information:\n")
print(sessionInfo())
