################################################################################
# FIGURE GENERATION - MAIN TEXT FIGURES (PYTHON)
# 
# Purpose: Generate figures for main text
# 
# Description:
#   - Takes processed data from /replication_final/data/processed
#   - Generates Figure 6.1 Panel B
#   - Outputs PDF figures to /replication_final/output/figures
#
# Figures Generated:
#   - Figure 6.1, Panel B: V/U Residuals vs. Inflation Residuals
#
# Author: Yash Singh, Giyoung Kwon
# Last Updated: 2025/7/28
################################################################################

import numpy as np 
import pandas as pd 
import os
import platform
from pathlib import Path
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
import statsmodels.api as sm
import warnings
warnings.filterwarnings("ignore")


# Detect OS
is_win = platform.system() == "Windows"

# Get username (cross-platform)
user = os.environ.get("USER") or os.environ.get("USERNAME")

# Define base path
if is_win:
    proj_dir = Path(f"C:/Users/{user}/Dropbox/Labor_Market_PT/replication/final")
else:
    proj_dir = Path(f"/Users/{user}/Library/CloudStorage/Dropbox/Labor_Market_PT/replication/final")

# Define other paths
data_dir = proj_dir / "data" / "processed"
figures_dir = proj_dir / "output" / "figures"
table_dir = proj_dir / "output" / "tables"

######################################################################
# Figure 6.1, Panel B 
######################################################################
print("Making figure for Figure 6.1, Panel B...")

data = pd.read_csv(f"{data_dir}/figure_6_1.csv")
data['date'] = pd.to_datetime(data['date']) 

reg_data = data[(data['date'] >= '1951-01-01') & (data['date'] <= '2019-12-01')]
reg_data = reg_data.copy()

reg_data.loc[:, 'U_rate_squared'] = reg_data['U_rate'] ** 2

inflation_vars = ['U_rate', 'U_rate_squared', 'P_12m_change']
subset_infl = reg_data[inflation_vars].dropna()
X = sm.add_constant(subset_infl[['U_rate', 'U_rate_squared']])  
y = subset_infl['P_12m_change'] 
model = sm.OLS(y, X).fit()
reg_data.loc[subset_infl.index, 'inflation_residuals'] = model.resid

# Residualizing Tightness
tightness_vars = ['U_rate', 'U_rate_squared', 'tightness']
subset_tight = reg_data[tightness_vars].dropna()
X = sm.add_constant(subset_tight[['U_rate', 'U_rate_squared']])  
y = subset_tight['tightness'] 
model = sm.OLS(y, X).fit()
reg_data.loc[subset_tight.index, 'tightness_residuals'] = model.resid

# Stick to the original structure; just fix the residual alignment issue

# Set figure style for AER
plt.style.use('default')
fig, ax = plt.subplots(figsize=(6.5, 4.5))  # AER typically uses smaller figures

# Drop rows where either residual is missing
resid_data = reg_data[['inflation_residuals', 'tightness_residuals']].dropna()

# Create scatter plot with blue outlines and no fill
ax.scatter(resid_data['inflation_residuals'], 
           resid_data['tightness_residuals'], 
           edgecolor='blue',  # Outline color
           facecolor='none',  # No fill color
           s=20)  # Smaller point size

# Calculate and add regression line in red
x = resid_data['inflation_residuals']
y = resid_data['tightness_residuals']
z = np.polyfit(x, y, 1)
p = np.poly1d(z)
ax.plot(x, p(x), color='red', linewidth=1.5)  # Regression line in red

# Customize axes and labels
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['left'].set_linewidth(0.5)
ax.spines['bottom'].set_linewidth(0.5)

# Set font to Times New Roman
plt.rcParams['font.family'] = 'Times New Roman'

# Add labels with proper formatting
ax.set_xlabel('Inflation Residuals', fontsize=10)
ax.set_ylabel('Vac-to-Unemp Residuals', fontsize=10)

# Remove grid
ax.grid(False)

# Set tick parameters
ax.tick_params(direction='out', length=4, width=0.5, labelsize=9)

# Adjust layout
plt.tight_layout()

# Optional: Save with high DPI for publication
plt.savefig(f"{figures_dir}/figure_6_1_B.pdf")

# #plt.show()
print("Figure 6.1, Panel B processed and saved.")

