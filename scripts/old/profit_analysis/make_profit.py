# Yash Singh 


import numpy as np
import pandas as pd 
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
import statsmodels.api as sm

# Specify directories 
data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"

cpi = pd.read_csv(f"{data_dir}/CPI/CPIAUCSL.csv")
profit_share = pd.read_csv(f"{data_dir}/profits/profit_share.csv")


# dataset (this dataset comes from the beveridge curve folder)
historical_data = pd.read_csv(f"{output_dir}/data/historical_data_feb.csv")

keep = ['date', 'U_rate']
u_rate = historical_data[keep]
u_rate['date'] = pd.to_datetime(u_rate['date'])

u_rate['quarter_start'] = u_rate['date'].dt.to_period('Q').dt.start_time

# Group by the quarter start date and take mean
u_rate = u_rate.groupby('quarter_start').mean().reset_index()
u_rate = u_rate.drop(columns = ['date'])
u_rate = u_rate.rename(columns = {'quarter_start':'date'})


# CPI-U 
cpi = cpi.iloc[10:].reset_index(drop=True)

cpi = cpi.rename(columns={
                            'observation_date': 'date', 
                            'CPIAUCSL':               'P'
})

cpi['date'] = pd.to_datetime(cpi['date'])
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100

cpi = cpi[cpi['date'] >= '1951-01-01']

cpi['quarter_start'] = cpi['date'].dt.to_period('Q').dt.start_time

# Group by the quarter start date and take mean
cpi = cpi.groupby('quarter_start').mean().reset_index()
cpi = cpi.drop(columns = ['date'])
cpi = cpi.rename(columns = {'quarter_start':'date'})

profit_share = profit_share.rename(columns={
                            'observation_date': 'date', 
                            'CP_GDP': 'profit_share'
})

profit_share['date'] = pd.to_datetime(profit_share['date'])
profit_share['profit_share'] = profit_share['profit_share']*100

# profit share time series 
profit_share.to_csv(f"{output_dir}/data/profit_share.csv", index = False)

data = profit_share.merge(cpi, on='date')
data = data.merge(u_rate, on='date')


# Ensure 'date' is in datetime format
data['date'] = pd.to_datetime(data['date'])

# Plot
ax = data.plot(x='date', y='profit_share', figsize=(14, 10), legend=False, linewidth  = 6)
plt.ylim(0, 14)

# Clean up the plot appearance
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

# Remove x-axis label and set tick label size
ax.set_xlabel("")  # This removes the 'date' label
ax.tick_params(axis='both', labelsize=38)

plt.tight_layout()
plt.savefig(f"{output_dir}/figures/profit_share_timeseries.pdf", format='pdf')
plt.show()



# Filter data for historical regressions (pre-2000)
reg_data = data[(data['date'] >= '1951-01-01') & (data['date'] <= '1999-12-01')].copy()
reg_data['U_rate_squared'] = reg_data['U_rate'] ** 2

def run_regression(data, y_var, covariates):
    X = sm.add_constant(data[covariates])
    y = data[y_var]
    return sm.OLS(y, X).fit()

# LaTeX table header
latex_table = """\\begin{table}[!htbp]
\\centering
\\caption{Regression Results: Profit Share as Outcome}
\\label{tab:profit_share_regs}
\\begin{tabular}{lccc}
\\hline\\hline
& (1) & (2) & (3) \\\\
\\hline
"""

# Define regression specs
specs = [
    ['U_rate'],
    ['U_rate', 'P_12m_change'],
    ['U_rate', 'U_rate_squared', 'P_12m_change']
]

# Run regressions
models = [run_regression(reg_data, 'profit_share', covs) for covs in specs]

# Helper: format coefficient + stars
def format_coef(coef, pval):
    stars = ''
    if pval < 0.01:
        stars = '^{***}'
    elif pval < 0.05:
        stars = '^{**}'
    elif pval < 0.1:
        stars = '^{*}'
    return f"{coef:.3f}{stars}"

# Variable label mapping
var_labels = {
    'U_rate': 'Unemployment Rate',
    'P_12m_change': 'Inflation',
    'U_rate_squared': 'Unemployment Rate$^2$',
    'const': 'Constant'
}

# Add coefficients + standard errors
for var in ['U_rate', 'U_rate_squared', 'P_12m_change', 'const']:
    row = var_labels.get(var, var) + " & "
    for model in models:
        if var in model.params:
            coef = format_coef(model.params[var], model.pvalues[var])
            se = f"({model.bse[var]:.3f})"
            row += f"${coef}$ & "
        else:
            row += " & "
    row = row.rstrip(" & ") + " \\\\\n"

    # Add standard error row if variable exists in any model
    se_row = " & "
    for model in models:
        if var in model.params:
            se_row += f"({model.bse[var]:.3f}) & "
        else:
            se_row += " & "
    se_row = se_row.rstrip(" & ") + " \\\\\n"

    latex_table += row + se_row

# Add R-squared and sample size
latex_table += "\\hline\n"
r2_row = "R$^2$ & " + " & ".join(f"{m.rsquared:.3f}" for m in models) + " \\\\\n"
n_row = "Observations & " + " & ".join(str(int(m.nobs)) for m in models) + " \\\\\n"
latex_table += r2_row + n_row

# Footer
latex_table += """\\hline\\hline
\\multicolumn{4}{l}{\\textit{Note:} Standard errors in parentheses.} \\\\
\\multicolumn{4}{l}{*** p$<$0.01, ** p$<$0.05, * p$<$0.1} \\\\
\\end{tabular}
\\end{table}
"""

# Write LaTeX to file
with open(f"{output_dir}/tables/profit_share_regressions.tex", "w") as f:
    f.write(latex_table)


inflation_model = run_regression(reg_data, 'P_12m_change', ['U_rate'])
reg_data['inflation_residuals'] = inflation_model.resid

profit_model = run_regression(reg_data, 'profit_share', ['U_rate'])
reg_data['profit_share_residuals'] = profit_model.resid


# Set figure style for AER
plt.style.use('default')
fig, ax = plt.subplots(figsize=(8, 6))  # Slightly larger figure

# Create scatter plot with blue outlines and no fill
ax.scatter(reg_data['inflation_residuals'], 
           reg_data['profit_share_residuals'], 
           edgecolor='blue', 
           facecolor='none', 
           s=40)  # Slightly larger point size

# Fit and add regression line
x = reg_data['inflation_residuals']
y = reg_data['profit_share_residuals']
z = np.polyfit(x, y, 1)
p = np.poly1d(z)
ax.plot(x, p(x), color='red', linewidth=2.5)  # Thicker regression line

# Clean up plot appearance
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['left'].set_linewidth(0.5)
ax.spines['bottom'].set_linewidth(0.5)

# Font and label styling
plt.rcParams['font.family'] = 'Times New Roman'
ax.set_xlabel('Inflation Residuals', fontsize=20)
ax.set_ylabel('Profit Share Residuals', fontsize=20)
ax.tick_params(direction='out', length=6, width=0.75, labelsize=18)

plt.tight_layout()
plt.savefig(f"{output_dir}/figures/profit_residuals_plot.pdf")
plt.show()


