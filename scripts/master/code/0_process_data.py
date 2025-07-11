######################################################################
# Date Created: 7/10/2025
# Last Modified: 7/11/2025
# This Code:
# - takes the raw data from /master/data/raw
# - processes it to create Dataframes for making all figures in the main text
# - (see /code/1_make_figures.jl)
# - also generates Figure 6.1, Panel B and Table 4
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
output_dir = os.path.join(global_dir, "data/processed")

######################################################################
# Load Raw Data
######################################################################
print("Loading raw data...")

# Stock of Vacancies 
vacancy_raw = pd.read_excel(f"{data_dir}/CompositeHWI.xlsx")
# Stock of Employed and Unemployed Workers 
stocks_raw = pd.read_csv(f"{data_dir}/employment_v2.csv")
# JOLTS (level)
jolts_raw = pd.read_csv(f"{data_dir}/jolts_level_v3.csv")
# JOLTS (rates)
jolts_rates_raw = pd.read_csv(f"{data_dir}/jolts_rates_v2.csv")
# Consumer Price Index
cpi_raw = pd.read_csv(f"{data_dir}/CPIAUCSL.csv")
# Average Wage Quartile
wage_raw = pd.read_excel(f"{data_dir}/wage-growth-data.xlsx", sheet_name = 'Average Wage Quartile', skiprows=2, header=0)
# FMP
fmp_raw = pd.read_csv(f"{data_dir}/FMPSA3MA.csv") 
# U-E
ue_raw = pd.read_csv(f"{data_dir}/UE.csv")
# ADP
adp_raw = pd.read_csv(f"{data_dir}/ADP_PAY_history.csv")

######################################################################
# Figure 1.1, Panel A (Same data for Figure 6.1, Panel A, B)
######################################################################
print("Processing data for Figure 1.1, Panel A and Figure 6.1, Panel A, B...")

vacancy = vacancy_raw.copy()
stocks = stocks_raw.copy()
cpi = cpi_raw.copy()
jolts = jolts_raw.copy()

# Basic Processing of historical vacancies 
vacancy.columns = ['date', 'V', 'V_rate']  
vacancy = vacancy.iloc[8:].reset_index(drop=True)
vacancy = vacancy.dropna(subset=['date', 'V'])
vacancy = vacancy.drop(['V_rate'], axis = 1)
vacancy['V'] = vacancy['V'].astype(float)

# Define the mapping function with increased tolerance
def map_to_month(decimal_date):
    fraction = decimal_date - int(decimal_date)
    #print("decimal_date", decimal_date)
    #print("integer decimal_date", int(decimal_date))
    #print('fraction', fraction)
    
    # Define exact mappings with slightly higher tolerance
    if np.isclose(fraction, 1, atol=0.02):
        month = 1  # January
    elif np.isclose(fraction, 0.08, atol=0.02):
        month = 2  # February
    elif np.isclose(fraction, 0.17, atol=0.02):
        month = 3  # March
    elif np.isclose(fraction, 0.25, atol=0.02):
        month = 4  # April
    elif np.isclose(fraction, 0.33, atol=0.02):
        month = 5  # May
    elif np.isclose(fraction, 0.42, atol=0.02):
        month = 6  # June
    elif np.isclose(fraction, 0.50, atol=0.02):
        month = 7  # July
    elif np.isclose(fraction, 0.58, atol=0.02):
        month = 8  # August
    elif np.isclose(fraction, 0.67, atol=0.02):
        month = 9  # September
    elif np.isclose(fraction, 0.75, atol=0.02):
        month = 10  # October
    elif np.isclose(fraction, 0.83, atol=0.02):
        month = 11  # November
    elif np.isclose(fraction, 0.92, atol=0.02):
        month = 12  # December
    else:
        raise ValueError(f"Fraction {fraction} does not match any month")
    
    return month

# Define the conversion function
def convert_to_datetime(decimal_date):
    decimal_date = float(decimal_date)
    year = int(decimal_date)
    month = map_to_month(decimal_date)
    return pd.Timestamp(year=year, month=month, day=1)

# Apply the conversion function to your dataset
vacancy['date'] = vacancy['date'].apply(convert_to_datetime)

# Basic Processing of stocks 
stocks.columns = ['date', 'E', 'U']
#stocks = stocks.iloc[11:].reset_index(drop=True)
stocks = stocks.dropna(subset=['date', 'E', 'U'])
stocks['date'] = pd.to_datetime(stocks['date'])
stocks['U'] = stocks['U'].astype(float)

# CPI-U 
cpi = cpi.iloc[10:].reset_index(drop=True)
cpi = cpi.rename(columns={
                            'observation_date': 'date', 
                            'CPIAUCSL':               'P'
})

cpi['date'] = pd.to_datetime(cpi['date'])
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_1m_change'] = cpi['P'].pct_change(periods=1) * 100
cpi['P_4m_change'] = cpi['P'].pct_change(periods=4) * 100
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100

# JOLTS 
jolts.columns = ['date', 'vacancy_stock', 'tot_quits',  'tot_hires', 'tot_layoffs']
#jolts = jolts.iloc[13:].reset_index(drop=True)
jolts['date'] = pd.to_datetime(jolts['date'])

temp = stocks.merge(cpi, on = ['date'], how = 'inner')
temp2 = temp.merge(jolts, on = ['date'], how='outer')
final = temp2.merge(vacancy, on = ['date'], how = 'outer')
final = final[(final['date'] >= '1951-01-01')]
final['V'] = final['V'].fillna(final['vacancy_stock'])
final['date'] = pd.to_datetime(final['date'])

# Create key variables 
final['L'] = final['E'] + final['U']
final['U_rate'] = (final['U'] / final['L']) * 100 
final['V_rate'] = (final['V'] / final['L']) * 100
final['tightness'] = final['V'] / final['U']
final['ln_tightness'] = np.log(final['V']) - np.log(final['U'])

# Keep main variables 
keep = ['date','P_1m_change', 'P_4m_change', 'P_12m_change', 'V', 'U', 'U_rate', 'V_rate', 'tightness', 'ln_tightness']
final = final[keep]

# Save the processed data
final.to_csv(f"{output_dir}/figure_1_1_A.csv", index=False)
print("Processed data for Figure 1.1, Panel A saved.")

final.to_csv(f"{output_dir}/figure_6_1.csv", index=False)
print("Processed data for Figure 6.1 saved.")


######################################################################
# Figure 1.1, Panel B (Same data for Figure 2.4, Panel A, B)
######################################################################
print("Processing data for Figure 1.1, Panel B and Figure 2.4, Panel A, B...")

data = wage_raw.copy()
cpi = cpi_raw.copy()

data = data.rename(columns={
    'Unnamed: 0': 'date',
    'Lowest quartile of wage distribution': 'Q1',
     '2nd quartile of wage distribution': 'Q2', 
    '3rd quartile of wage distribution': 'Q3', 
    'Highest quartile of wage distribution': 'Q4'
})

cpi = cpi.iloc[10:].reset_index(drop=True)

cpi = cpi.rename(columns={
                            'observation_date': 'date', 
                            'CPIAUCSL':               'P'
})
cpi['date'] = pd.to_datetime(cpi['date'])
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100

wage_data = data.merge(cpi, on='date', how = 'left')
wage_data_copy = wage_data.copy()
wage_data = wage_data[wage_data['date'] >= '2015-12-01']
wage_data = wage_data[wage_data['date'] <= '2024-12-01']
wage_data = wage_data.drop(['Lowest half of wage distribution', 'Upper half of wage distribution'], axis = 1)
wage_data = wage_data.reset_index(drop=True)

wage_data['wage_index_1'] = 1
wage_data['wage_index_2'] = 1
wage_data['wage_index_3'] = 1
wage_data['wage_index_4'] = 1
wage_data['med_wage_index'] = 1 

wage_data = wage_data[wage_data['date'] >= '2016-01-01']

wage_data['q1_mom_grth'] = 1+ (wage_data['Q1']/100)/12
wage_data['q2_mom_grth'] = 1+ (wage_data['Q2']/100)/12
wage_data['q3_mom_grth'] = 1+ (wage_data['Q3']/100)/12
wage_data['q4_mom_grth'] = 1+ (wage_data['Q4']/100)/12
wage_data['med_mom_grth'] = 1+ (wage_data['Overall']/100)/12
wage_data['P_1m_change'] = 1 + (wage_data['P_12m_change']/100)/12
wage_data['nom_wage_index_1'] = wage_data['q1_mom_grth'].cumprod()
wage_data['nom_wage_index_2'] = wage_data['q2_mom_grth'].cumprod()
wage_data['nom_wage_index_3'] = wage_data['q3_mom_grth'].cumprod()
wage_data['nom_wage_index_4'] = wage_data['q4_mom_grth'].cumprod()
wage_data['med_nom_wage_index'] = wage_data['med_mom_grth'].cumprod()
wage_data['price_index']      = wage_data['P_1m_change'].cumprod()

wage_data = wage_data.fillna(1)

wage_data['real_wage_index_1'] = wage_data['nom_wage_index_1'] / wage_data['price_index']
wage_data['real_wage_index_2'] = wage_data['nom_wage_index_2'] / wage_data['price_index']
wage_data['real_wage_index_3'] = wage_data['nom_wage_index_3'] / wage_data['price_index']
wage_data['real_wage_index_4'] = wage_data['nom_wage_index_4'] / wage_data['price_index']
wage_data['med_real_wage_index'] = wage_data['med_nom_wage_index'] / wage_data['price_index']


# Define the date range for the trend line
start_date = '2016-01-01'
end_date = '2019-12-31'

# Filter the data for the trend calculation
trend_data = wage_data[(wage_data['date'] >= start_date) & (wage_data['date'] <= end_date)]

# Prepare for linear regression with months since the start date
X = ((trend_data['date'].dt.year - trend_data['date'].min().year) * 12 +
     (trend_data['date'].dt.month - trend_data['date'].min().month)).values.reshape(-1, 1)

# Create a dictionary to hold the predicted values for each wage index
predicted_values = {}

# Loop through each wage index to predict values
for column_name in ['real_wage_index_1', 'real_wage_index_2', 'real_wage_index_3', 'real_wage_index_4', 
                    'med_real_wage_index', 'price_index']:
    
    # Fit linear regression model
    y = trend_data[column_name].values
    model = LinearRegression()
    model.fit(X, y)
    
    # Predict for the entire dataset, using months since the start date
    all_dates = ((wage_data['date'].dt.year - trend_data['date'].min().year) * 12 +
                 (wage_data['date'].dt.month - trend_data['date'].min().month)).values.reshape(-1, 1)
    predicted_values[column_name] = model.predict(all_dates)

# Add the predicted columns to the DataFrame
for column_name in predicted_values:
    wage_data[f'predicted_{column_name}'] = predicted_values[column_name]

main = ['date', 'price_index', 'predicted_price_index', 
                'med_real_wage_index', 'predicted_med_real_wage_index', 
                'real_wage_index_1', 'predicted_real_wage_index_1', 
                'real_wage_index_2', 'predicted_real_wage_index_2', 
                'real_wage_index_3', 'predicted_real_wage_index_3', 
                'real_wage_index_4', 'predicted_real_wage_index_4']
final = wage_data[main]

final.to_csv(f"{output_dir}/figure_1_1_B.csv", index = False)
print("Processed data for Figure 1.1, Panel B saved.")
final.to_csv(f"{output_dir}/figure_2_4.csv", index = False)
print("Processed data for Figure 2.4 saved.")


######################################################################
# Figure 2.1, Panel A, B, C
######################################################################
print("Processing data for Figure 2.1, Panel A, B, C...")

df = jolts_rates_raw.copy()
df = df.rename(columns={
                            'observation_date': 'date', 
                            'JTSLDR':               'layoff_rate_jolts', 
                            'JTSQUR': 'quit_rate_jolts', 
                            'JTSJOR': 'vacancy_rate_jolts', 
})
df['date'] = pd.to_datetime(df['date']) 

df.to_csv(f"{output_dir}/figure_2_1.csv", index = False) 
print("Processed data for Figure 2.1, Panel A, B, C saved.")


######################################################################
# Figure 2.2, Panel A
######################################################################
print("Processing data for Figure 2.2, Panel A...")

df = fmp_raw.copy()
df.rename(columns={"FMPSA3MA": "ee_pol", 'observation_date': 'date'}, inplace=True)
df['date_monthly'] = pd.to_datetime(df['date'])
df.to_csv(f"{output_dir}/figure_2_2_A.csv", index = False)
print("Processed data for Figure 2.2, Panel A saved.")

######################################################################
# Figure 2.2, Panel B
######################################################################
print("Processing data for Figure 2.2, Panel B...")

stocks = stocks_raw.copy()
ue = ue_raw.copy()

stocks.columns = ['date', 'E', 'U']
stocks = stocks.iloc[11:].reset_index(drop=True)
stocks = stocks.dropna(subset=['date', 'E', 'U'])
stocks['date'] = pd.to_datetime(stocks['date'])
stocks['U'] = stocks['U'].astype(float)

ue.columns = ['date', 'ue_flows']
ue['date'] = pd.to_datetime(ue['date'])

# Merge and calculate job finding rate
data = stocks.merge(ue, on=['date'])
data['job_finding_rate'] = data['ue_flows'] / data['U']

# Add 3-month moving average (centered)
data['job_finding_rate_3ma'] = data['job_finding_rate'].rolling(window=3, center=True, min_periods=1).mean()
data['job_finding_rate_3ma'] = data['job_finding_rate_3ma'] * 100

# Keep and save relevant columns
output_cols = ['date', 'job_finding_rate', 'job_finding_rate_3ma']
data[output_cols].to_csv(f"{output_dir}/figure_2_2_B.csv", index=False)
print("Processed data for Figure 2.2, Panel B saved.")

######################################################################
# Figure 2.3, Panel A, B
######################################################################
print("Processing data for Figure 2.3, Panel A, B...")

df = adp_raw.copy()
cpi = cpi_raw.copy()

# ADP wage data 
temp = df[df['category'] == 'Job Stayer']
keep = ['date', 'median pay change']
stayer = temp[keep]
stayer = stayer.rename(columns={'median pay change':'delta_w_stay'})

temp = df[df['category'] == 'Job Changer']
keep = ['date', 'median pay change']
switcher = temp[keep]
switcher = switcher.rename(columns={'median pay change':'delta_w_switch'}) 

data = switcher.merge(stayer, on=['date']) 
data['date'] = pd.to_datetime(data['date'])
data['diff'] = data['delta_w_switch'] - data['delta_w_stay']


# CPI 
cpi = cpi.iloc[10:].reset_index(drop=True)
cpi = cpi.rename(columns={
                            'observation_date': 'date', 
                            'CPIAUCSL':               'P'
})

cpi['date'] = pd.to_datetime(cpi['date'])
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100

data = data.merge(cpi, on =['date'])
data.to_csv(f"{output_dir}/figure_2_3.csv", index = False ) 
print("Processed data for Figure 2.3, Panel A, B saved.")

######################################################################
# Figure 2.4, Panel A, B
######################################################################
# See Section for Figure 1.1, Panel B for data processing

######################################################################
# Figure 6.1, Panel A
######################################################################
# See Section for Figure 1.1, Panel A for data processing

######################################################################
# Figure 6.1, Panel B (Make figure here)
######################################################################
# See Section for Figure 1.1, Panel A for data processing

print("Making figure for Figure 6.1, Panel B...")
figure_dir = os.path.join(global_dir, "output/figures")

data = pd.read_csv(f"{output_dir}/figure_6_1.csv")
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
plt.savefig(f"{figure_dir}/figure_6_1_B.pdf")

# plt.show()
print("Figure 6.1, Panel B processed and saved.")

#######################################################################
# Table 4
#######################################################################
print("Making Table 4...")

table_dir = os.path.join(global_dir, "output/tables")

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