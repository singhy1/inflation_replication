# Python Package Setup for Replication
# =====================================
# This file installs all required Python packages for the replication study
# Run this file before executing any Python scripts in the replication

"""
INSTRUCTIONS:
1. Make sure you have Python 3.7+ installed
2. Run this script: python 0_setup_python.py
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
    "numpy>=1.20.0",
    "pandas>=1.3.0", 
    "matplotlib>=3.3.0",
    "scikit-learn>=1.0.0",
    "statsmodels>=0.12.0",
    "openpyxl>=3.0.0",
    "xlrd>=2.0.0"
]

def main():
    print("Setting up Python environment for replication study...")
    print("=" * 60)
    
    print("Upgrading pip...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--upgrade", "pip"])
    
    print(f"\nInstalling {len(required_packages)} required packages...")
    for package in required_packages:
        install_package(package)
    
    print("\n" + "=" * 60)
    print("Python package setup completed!")

if __name__ == "__main__":
    main()
