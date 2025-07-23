######################################################################
# Date Created: 7/11/2025
# Last Modified: 7/13/2025
# This Code:
# - takes the processed data from /replication_final/data/processed
# - creates Figure 6.1, Panel B and Table 4
######################################################################

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


#######################################################################
# Table 4
#######################################################################
print("Making Table 4...")

def run_regression_get_latex(data, y_var, covariates):
    X = sm.add_constant(data[covariates])
    y = data[y_var]
    model = sm.OLS(y, X).fit()
    return model

# Create LaTeX table header
latex_table = """\\begin{table}[!htbp]
\\centering
\\caption{Regression Results}
\\label{tab:regressions}
\\begin{tabular}{lcccccc}
\\hline\\hline
& \\multicolumn{3}{c}{Vacancy Rate} & \\multicolumn{3}{c}{Labor Market Tightness} \\\\
\\cline{2-4} \\cline{5-7}
& (1) & (2) & (3) & (4) & (5) & (6) \\\\
\\hline
"""

# Define specifications
specs = [
    ('V_rate', ['U_rate']),
    ('V_rate', ['U_rate', 'P_12m_change']),
    ('V_rate', ['U_rate', 'U_rate_squared', 'P_12m_change']),
    ('tightness', ['U_rate']),
    ('tightness', ['U_rate', 'P_12m_change']),
    ('tightness', ['U_rate', 'U_rate_squared', 'P_12m_change'])
]

# Run all models and store results
models = [run_regression_get_latex(reg_data, y_var, covs) for y_var, covs in specs]

# Function to format coefficient with stars
def format_coef(coef, pval):
    coef_str = f"{coef:0.3f}"
    if pval < 0.01:
        coef_str += "^{***}"
    elif pval < 0.05:
        coef_str += "^{**}"
    elif pval < 0.1:
        coef_str += "^{*}"
    return coef_str

# Add coefficients to table
variables = ['Unemployment Rate', 'Inflation', 'Unemployment Rate$^2$', 'Constant']
var_mapping = {
    'U_rate': 'Unemployment Rate',
    'P_12m_change': 'Inflation',
    'U_rate_squared': 'Unemployment Rate$^2$',
    'const': 'Constant'
}

for var in ['U_rate', 'P_12m_change', 'U_rate_squared', 'const']:
    row = f"{var_mapping[var]} & "
    for model in models:
        if var in model.params:
            coef = format_coef(model.params[var], model.pvalues[var])
            se = f"({model.bse[var]:0.3f})"
            row += f"${coef}$ & "
            row += f"{se} & "
        else:
            row += "& & "
    row = row[:-2] + "\\\\"
    latex_table += row + "\n"

# Add R-squared and N
latex_table += "\\hline\n"
r2_row = "R$^2$ & "
n_row = "Observations & "
for model in models:
    r2_row += f"{model.rsquared:0.3f} & "
    n_row += f"{int(model.nobs)} & "
r2_row = r2_row[:-2] + "\\\\\n"
n_row = n_row[:-2] + "\\\\\n"
latex_table += r2_row
latex_table += n_row

# Add table footer
latex_table += """\\hline\\hline
\\multicolumn{7}{l}{\\textit{Note:} Standard errors in parentheses} \\\\
\\multicolumn{7}{l}{*** p$<$0.01, ** p$<$0.05, * p$<$0.1} \\\\
\\end{tabular}
\\end{table}"""

with open(f"{table_dir}/table_4.tex", "w") as file:
    file.write(latex_table)
print("Table 4 processed and saved.")
 
