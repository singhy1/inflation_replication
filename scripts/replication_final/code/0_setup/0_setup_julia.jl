# Julia Package Setup for Replication
# ====================================
# This script installs all required Julia packages for the replication study
# Run this file before executing any Julia scripts in the replication

# INSTRUCTIONS:
# 1. Make sure you have Julia 1.6+ installed
# 2. Open Julia REPL or Julia IDE
# 3. Run this script: include("0_setup_julia.jl")
# 4. Alternatively, copy and paste the code below into your Julia REPL

println("Setting up Julia environment for replication study...")
println("="^60)

using Pkg

# Required packages for the replication
required_packages = [
    # Core Julia packages
    "Statistics",        # Statistical functions (usually part of standard library)
    "Dates",            # Date/time handling (standard library)
    
    # Data manipulation and analysis
    "DataFrames",       # Data manipulation (similar to pandas)
    "DataFramesMeta",   # Additional data manipulation tools
    "CSV",              # CSV file reading/writing
    "DelimitedFiles",   # For working with delimited text files
    
    # Data structures and utilities
    "CategoricalArrays", # For categorical data
    "PanelDataTools",   # Panel data analysis tools
    "PeriodicalDates",  # Date handling for time series
    
    # Plotting and visualization
    "Plots",            # Main plotting package
    "PGFPlotsX",        # LaTeX-quality plots
    "LaTeXStrings",     # LaTeX string formatting
    
    # Statistical analysis and econometrics
    "Binscatters",      # Binscatter plots for econometrics
    
    # File I/O
    "FileIO",           # General file I/O
    
    # Development tools
    "Revise",           # For interactive development (optional but useful)
]

# Function to add packages if not already installed
function install_if_missing(pkg_name)
    try
        # Try to load the package
        eval(Meta.parse("using $pkg_name"))
        println("✓ $pkg_name already installed and loaded")
    catch
        try
            println("Installing $pkg_name...")
            Pkg.add(pkg_name)
            eval(Meta.parse("using $pkg_name"))
            println("✓ Successfully installed and loaded $pkg_name")
        catch e
            println("✗ Failed to install $pkg_name: $e")
        end
    end
end

# Install all required packages
println("\nInstalling $(length(required_packages)) required packages...")
for pkg in required_packages
    install_if_missing(pkg)
end

println("\n" * "="^60)
println("Julia package setup completed!")
println("\nIf you encounter any issues:")
println("1. Make sure you have Julia 1.6+ installed")
println("2. Try updating Julia to the latest stable version")
println("3. Run Pkg.update() to update existing packages")
println("4. Install packages individually if batch installation fails:")
println("   Pkg.add(\"PackageName\")")
println("5. Check your internet connection")
println("6. Try Pkg.resolve() if you encounter dependency conflicts")

# Display package status for debugging
println("\nPackage Status:")
Pkg.status()

println("\nJulia Version Information:")
println(VERSION)
