# Python Package Setup for Replication
# =====================================
# This file installs all required Python packages for the replication study
# Run this file before executing any Python scripts in the replication

"""
INSTRUCTIONS:
1. Make sure you have Python 3.7+ installed
2. It's recommended to create a virtual environment:
   python -m venv replication_env
   source replication_env/bin/activate  # On Windows: replication_env\Scripts\activate
3. Run this script: python 0_setup_python.py
4. Alternative: pip install -r requirements.txt (if requirements.txt is available)
"""

import subprocess
import sys

def install_package(package):
    """Install a package using pip"""
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])
        print(f"✓ Successfully installed {package}")
    except subprocess.CalledProcessError:
        print(f"✗ Failed to install {package}")

# Core packages required for all scripts
required_packages = [
    # Data manipulation and analysis
    "numpy>=1.20.0",
    "pandas>=1.3.0",
    
    # Plotting and visualization  
    "matplotlib>=3.3.0",
    
    # Machine learning
    "scikit-learn>=1.0.0",
    
    # Statistical analysis
    "statsmodels>=0.12.0",
    
    # Excel file support (for reading .xlsx files)
    "openpyxl>=3.0.0",
    "xlrd>=2.0.0",
    
    # Other utilities (standard library, but ensuring compatibility)
    # os, platform, pathlib, subprocess, time, warnings, collections are standard library
]

def main():
    print("Setting up Python environment for replication study...")
    print("=" * 60)
    
    # Upgrade pip first
    print("Upgrading pip...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--upgrade", "pip"])
    
    # Install required packages
    print(f"\nInstalling {len(required_packages)} required packages...")
    for package in required_packages:
        install_package(package)
    
    print("\n" + "=" * 60)
    print("Python package setup completed!")
    print("\nIf you encounter any issues:")
    print("1. Make sure you're using Python 3.7+")
    print("2. Consider using a virtual environment")
    print("3. Try upgrading pip: python -m pip install --upgrade pip")
    print("4. Install packages individually if batch installation fails")

if __name__ == "__main__":
    main()
