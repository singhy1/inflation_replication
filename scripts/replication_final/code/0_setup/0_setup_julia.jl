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

required_packages = [
    "Statistics",       
    "Dates",       
    "DataFrames",      
    "DataFramesMeta", 
    "CSV",            
    "DelimitedFiles", 
    "CategoricalArrays", 
    "PanelDataTools",  
    "PeriodicalDates", 
    "Plots",           
    "PGFPlotsX",      
    "LaTeXStrings",     
    "Binscatters",   
    "FileIO",     
    "Revise",           
]

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

println("\nInstalling $(length(required_packages)) required packages...")
for pkg in required_packages
    install_if_missing(pkg)
end

println("\n" * "="^60)
println("Julia package setup completed!")

# Display package status for debugging
println("\nPackage Status:")
Pkg.status()
