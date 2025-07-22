######################################################################
# Last Modified: 7/21/2025
# This Code:
# - takes data from /master/data/processed and /master/data/raw
# - makes figures for the main text
######################################################################

import numpy as np 
import pandas as pd 
import os
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
import statsmodels.api as sm
import warnings
warnings.filterwarnings("ignore")

# Set directories (Set your own global path)
global_dir = "/Users/giyoung/Downloads/inflation_replication/scripts/master/"
data_dir = os.path.join(global_dir, "data/raw")
data_processed_dir = os.path.join(global_dir, "data/processed")
figures_dir = os.path.join(global_dir, "output/figures")
table_dir = os.path.join(global_dir, "output/tables")

######################################################################
# Table 4
######################################################################
print("Making Table 4...")

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
 