######################################################################
# Last Modified: 7/21/2025
# This Code:
# - takes data from /replication_final/data/processed and /replication_final/data/raw
# - makes figures for the appendix 
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
global_dir = "/Users/giyoung/Downloads/inflation_replication/scripts/replication_final/"
data_dir = os.path.join(global_dir, "data/raw")
data_processed_dir = os.path.join(global_dir, "data/processed")
figures_dir = os.path.join(global_dir, "output/figures")
table_dir = os.path.join(global_dir, "output/tables")

######################################################################
# Figure B.2
######################################################################
print("Making table for Figure B.2...")

wage_data = pd.read_excel(f"{data_dir}/atl_fed/atl_fed_wage.xlsx", sheet_name = "Industry", skiprows=2, header=0)
cpi = pd.read_csv(f"{data_dir}/fred/CPI.csv")
df_raw = pd.read_excel(f"{data_dir}/jolts/jolts_industry_rates.xlsx", skiprows=2)


#################################################
# CPI-U 
cpi = cpi.iloc[10:].reset_index(drop=True)

cpi = cpi.rename(columns={
                            'observation_date': 'date', 
                            'CPIAUCSL':               'P'
})

cpi['date'] = pd.to_datetime(cpi['date'])
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100
####################################################


wage_data = wage_data.rename(columns =
                   {'Unnamed: 0' : 'date'})
wage_data = wage_data.merge(cpi, on='date', how = 'left')

wage_data = wage_data[wage_data['date'] >= '2015-12-01']
wage_data = wage_data[wage_data['date'] <= '2024-12-01'] 


wage_data['wage_index_Construction and mining'] = 1
wage_data['wage_index_Education and health'] = 1
wage_data['wage_index_Finance and business services'] = 1
wage_data['wage_index_Leisure and hospitality and other services'] = 1
wage_data['wage_index_Manufacturing'] = 1
wage_data['wage_index_Public administration'] = 1
wage_data['wage_index_Trade and transportation'] = 1
wage_data['med_wage_index'] = 1 

wage_data = wage_data[wage_data['date'] >= '2016-01-01']

wage_data['Construction and mining_mom_grth'] = 1+ (wage_data['Construction and mining']/100)/12
wage_data['Education and health_mom_grth'] = 1+ (wage_data['Education and health']/100)/12
wage_data['Finance and business services_mom_grth'] = 1+ (wage_data['Finance and business services']/100)/12
wage_data['Leisure and hospitality and other services_mom_grth'] = 1+ (wage_data['Leisure and hospitality and other services']/100)/12
wage_data['Manufacturing_mom_grth'] = 1+ (wage_data['Manufacturing']/100)/12
wage_data['Public administration_mom_grth'] = 1+ (wage_data['Public administration']/100)/12
wage_data['Trade and transportation_mom_grth'] = 1+ (wage_data['Trade and transportation']/100)/12

wage_data['med_mom_grth'] = 1+ (wage_data['Overall']/100)/12

wage_data['P_1m_change'] = 1 + (wage_data['P_12m_change']/100)/12

wage_data['nom_wage_index_Construction and mining'] = wage_data['Construction and mining_mom_grth'].cumprod()
wage_data['nom_wage_index_Education and health'] = wage_data['Education and health_mom_grth'].cumprod()
wage_data['nom_wage_index_Finance and business services'] = wage_data['Finance and business services_mom_grth'].cumprod()
wage_data['nom_wage_index_Leisure and hospitality and other services'] = wage_data['Leisure and hospitality and other services_mom_grth'].cumprod()
wage_data['nom_wage_index_Manufacturing'] = wage_data['Manufacturing_mom_grth'].cumprod()
wage_data['nom_wage_index_Public administration'] = wage_data['Public administration_mom_grth'].cumprod()
wage_data['nom_wage_index_Trade and transportation'] = wage_data['Trade and transportation_mom_grth'].cumprod()
wage_data['med_nom_wage_index'] = wage_data['med_mom_grth'].cumprod()
wage_data['price_index']      = wage_data['P_1m_change'].cumprod()

wage_data = wage_data.fillna(1)

wage_data['real_wage_index_Construction and mining'] = wage_data['nom_wage_index_Construction and mining'] / wage_data['price_index']
wage_data['real_wage_index_Education and health'] = wage_data['nom_wage_index_Education and health'] / wage_data['price_index']
wage_data['real_wage_index_Finance and business services'] = wage_data['nom_wage_index_Finance and business services'] / wage_data['price_index']
wage_data['real_wage_index_Leisure and hospitality and other services'] = wage_data['nom_wage_index_Leisure and hospitality and other services'] / wage_data['price_index']

wage_data['real_wage_index_Manufacturing'] = wage_data['nom_wage_index_Manufacturing'] / wage_data['price_index']
wage_data['real_wage_index_Public administration'] = wage_data['nom_wage_index_Public administration'] / wage_data['price_index']
wage_data['real_wage_index_Trade and transportation'] = wage_data['nom_wage_index_Trade and transportation'] / wage_data['price_index']

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
for column_name in [
       'real_wage_index_Construction and mining',
       'real_wage_index_Education and health',
       'real_wage_index_Finance and business services',
       'real_wage_index_Leisure and hospitality and other services',
       'real_wage_index_Manufacturing', 'real_wage_index_Public administration',
       'real_wage_index_Trade and transportation', 'med_real_wage_index',
       'price_index']:
    
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

gaps = {
    'gap_Construction and Mining': wage_data['predicted_real_wage_index_Construction and mining'].iloc[-1] - wage_data['real_wage_index_Construction and mining'].iloc[-1],
    'gap_Education and health': wage_data['predicted_real_wage_index_Education and health'].iloc[-1] - wage_data['real_wage_index_Education and health'].iloc[-1],
    'gap_Leisure and hospitality and other services': wage_data['predicted_real_wage_index_Leisure and hospitality and other services'].iloc[-1] - wage_data['real_wage_index_Leisure and hospitality and other services'].iloc[-1],
    'gap_Manufacturing': wage_data['predicted_real_wage_index_Manufacturing'].iloc[-1] - wage_data['real_wage_index_Manufacturing'].iloc[-1],
    'gap_Public administration': wage_data['predicted_real_wage_index_Public administration'].iloc[-1] - wage_data['real_wage_index_Public administration'].iloc[-1],
    'gap_Trade and transportation': wage_data['predicted_real_wage_index_Trade and transportation'].iloc[-1] - wage_data['real_wage_index_Trade and transportation'].iloc[-1],
    'gap_Finance and business Services': wage_data['predicted_real_wage_index_Finance and business services'].iloc[-1] - wage_data['real_wage_index_Finance and business services'].iloc[-1], 
    'gap_med': wage_data['predicted_med_real_wage_index'].iloc[-1] - wage_data['med_real_wage_index'].iloc[-1],
}


# Extract header and reformat
new_header = df_raw.iloc[0]
df_clean = df_raw[1:]
df_clean.columns = new_header
df_clean = df_clean.rename(columns={df_clean.columns[0]: "seriesid"})
df_clean.columns = df_clean.columns.astype(str)

# Reshape and clean
df_long = df_clean.melt(id_vars=["seriesid"], var_name="date", value_name="value")
df_long["date"] = df_long["date"].str.replace("\n", " ").str.strip()
df_long["date"] = pd.to_datetime(df_long["date"], format="%b %Y", errors="coerce")
df_long = df_long.dropna(subset=["date", "value"])
df_long = df_long.sort_values(by=["seriesid", "date"]).reset_index(drop=True)

# Extract codes from seriesid
df_long["industry_code"] = df_long["seriesid"].str[3:11]
df_long["flow_type_code"] = df_long["seriesid"].str[-3:]

# Get unique codes
industry_codes = df_long["industry_code"].unique()
flow_type_codes = df_long["flow_type_code"].unique()

industry_codes, flow_type_codes

# Define flow type mapping
flow_type_map = {
    "HIR": "Hires",
    "QUR": "Quits",
    "TSR": "Total Separations",
    "JOR": "Job Openings",
    "LDR": "Layoffs & Discharges",
    "UOR": "Other Separations",
    "OSR": "Other Separations (Residual)"
}

# Define industry code mapping based on BLS JOLTS industry categories
industry_map = {
    "00000000": "Total nonfarm",
    "10000000": "Total private",
    "11009900": "Mining and logging",
    "23000000": "Construction",
    "30000000": "Manufacturing",
    "32000000": "Durable goods manufacturing",
    "34000000": "Nondurable goods manufacturing",
    "40000000": "Trade, transportation, and utilities",
    "42000000": "Wholesale trade",
    "44000000": "Retail trade",
    "48009900": "Transportation, warehousing, and utilities",
    "51000000": "Information",
    "51009900": "Financial activities",
    "52000000": "Finance and insurance",
    "53000000": "Real estate and rental and leasing",
    "54009900": "Professional and business services",
    "60000000": "Private education and health services", 
    "61000000": "Private education services",
    "62000000": "Healthcare and Social Assistance",
    "70000000": "Leisure and Hospitality",
    "71000000": "Arts, entertainment, and recreation",
    "72000000": "Accomodation and food services",
    "81000000": "Other services",
    "90000000": "Government",
    "91000000": "Federal government",
    "92000000": "State and local government",
    "92300000": "State and local government education",
    "92900000": "State and local government, excluding education"
}

# Apply mappings
df_long["flow_type"] = df_long["flow_type_code"].map(flow_type_map)
df_long["industry"] = df_long["industry_code"].map(industry_map)

# List of industry labels to drop
industries_to_drop = [
    'Financial activities',
    'Manufacturing',
    'Leisure and Hospitality',
    'Private education and health services',
    'Trade, transportation, and utilities',
]

# Filter the DataFrame
df_long = df_long[~df_long['industry'].isin(industries_to_drop)]



df_long = df_long.rename(columns={
    'value': 'rate',
})

keep = ['date', 'rate', 'flow_type', 'industry']
data = df_long[keep]

keep_list = [
    "Accomodation and food services",
    "Arts, entertainment, and recreation",
    "Construction",
    "Durable goods manufacturing",
    "Finance and insurance",
    "Healthcare and Social Assistance",
    "Information",
    "Mining and logging",
    "Nondurable goods manufacturing",
    "Other services",
    "Private education services",
    "Professional and business services",
    "Real estate and rental and leasing",
    "Retail trade",
    "Transportation, warehousing, and utilities",
    "Wholesale trade"
]

data = data[data['industry'].isin(keep_list)]

jolts_to_wage_mapping = {
    "Accomodation and food services": "Leisure and hospitality and other services",
    "Arts, entertainment, and recreation": "Leisure and hospitality and other services",
    "Construction": "Construction and Mining",
    "Durable goods manufacturing": "Manufacturing",
    "Finance and insurance": "Finance and business services",
    "Healthcare and Social Assistance": "Education and health",
    "Information": "Finance and business services",
    "Mining and logging": "Construction and Mining",
    "Nondurable goods manufacturing": "Manufacturing",
    "Other services": "Leisure and hospitality and other services",
    "Private education services": "Education and health",
    "Professional and business services": "Finance and business services",
    "Real estate and rental and leasing": "Finance and business services",
    "Retail trade": "Trade and transportation",
    "Transportation, warehousing, and utilities": "Trade and transportation",
    "Wholesale trade": "Trade and transportation"
}


data['agg_ind'] = data['industry'].map(jolts_to_wage_mapping)

data = data.groupby(['agg_ind', 'flow_type', 'date'])['rate'].mean().reset_index()
data = data[data['date'].dt.year != 2020]

conditions = [
    data['date'] < '2020-01-01',
    (data['date'] >= '2021-04-01') & (data['date'] <= '2023-05-01'),
    data['date'] >= '2023-06-01'
]
choices = ['pre', 'inf', 'post']

data['period'] = np.select(conditions, choices, default=pd.NA)

table = data.groupby(['agg_ind', 'flow_type', 'period'])['rate'].mean().reset_index()

table = table[table['period'] != 'post']

table = table.pivot_table(index=['agg_ind', 'flow_type'], columns='period', values='rate').reset_index()

table['pct_change'] = ((table['inf'] - table['pre']) / table['pre']) * 100

table = table.sort_values(by='flow_type').reset_index(drop = True) 

pct_change_matrix = table.pivot(index='agg_ind', columns='flow_type', values='pct_change')

selected_columns = ['Hires', 'Job Openings', 'Layoffs & Discharges', 'Quits']
pct_change_selected = pct_change_matrix[selected_columns]

# Create updated DataFrame
wage_gap_df_final = pd.DataFrame.from_dict(gaps, orient='index', columns=['real_wage_gap'])
wage_gap_df_final.index = wage_gap_df_final.index.str.replace('gap_', '', regex=False).str.lower()

# Rejoin with the lower-cased index table
pct_change_with_gap_final = pct_change_selected.copy()
pct_change_with_gap_final.index = pct_change_with_gap_final.index.str.lower()
pct_change_with_gap_final = pct_change_with_gap_final.join(wage_gap_df_final, how='left')

# Capitalize for final display
pct_change_with_gap_final.index.name = 'agg_ind'
pct_change_with_gap_final = pct_change_with_gap_final.reset_index()
pct_change_with_gap_final['agg_ind'] = pct_change_with_gap_final['agg_ind'].str.title()
pct_change_with_gap_final = pct_change_with_gap_final.set_index('agg_ind')

pct_change_with_gap_final['real_wage_gap']  = -pct_change_with_gap_final['real_wage_gap'] * 100


df = pct_change_with_gap_final

# 2. Convert the entire DataFrame to LaTeX (no index column)
latex_body = df.to_latex(index=False)

# 3. Wrap it in a LaTeX table environment
latex_table = f"""\\begin{{table}}[ht!]
\\centering
\\resizebox{{\\textwidth}}{{!}}{{%
{latex_body}
}}
\\caption{{Structural Change Data}}
\\label{{tab:structural_change}}
\\end{{table}}
"""

# 4. Print the LaTeX so you can copy and paste into your .tex file
print(latex_table)

# save latex table
with open(f"{table_dir}/table_B_2.tex", "w") as f:
    f.write(latex_table)

######################################################################
# Figure B.3
######################################################################
print("Making table for Figure B.3...")

# Load the data
financial_situation = pd.read_excel(f"{data_dir}/gallup/gallup_data.xlsx", sheet_name = "Financial situation today", skiprows=7)
personal_satisfaction = pd.read_excel(f"{data_dir}/gallup/gallup_data.xlsx", sheet_name = "Personal Satisfaction", skiprows=7)
very_satisfaction = pd.read_excel(f"{data_dir}/gallup/gallup_data.xlsx", sheet_name = "Satisfaction with personal life", skiprows=7)

financial_situation['excellent_good'] = financial_situation['Excellent'] + financial_situation['Good']

income_level_mapping = {
    'Aggregate': 'Aggregate',
    'Lower income (approx. bottom third)': 'Lower',
    'Middle income (approx. middle third)': 'Middle', 
    'Upper income (approx. upper third)': 'Upper'
}

results = []
for demo_value, income_label in income_level_mapping.items():
    # Filter data for this income level
    income_data = financial_situation[financial_situation['Demographic Value'] == demo_value].copy()
    
    if len(income_data) > 0:
        # Calculate averages for the two periods
        period_2016_2019 = income_data[
            (income_data['Time'] >= 2016) & (income_data['Time'] <= 2019)
        ]['excellent_good'].mean()
        
        period_2022_2025 = income_data[
            (income_data['Time'] >= 2022) & (income_data['Time'] <= 2025)
        ]['excellent_good'].mean()
        
        difference = period_2022_2025 - period_2016_2019
        
        results.append({
            'Income Level': income_label,
            '2016-2019 Average': period_2016_2019,
            '2022-2025 Average': period_2022_2025,
            'Difference (22-25 minus 16-19)': difference
        })
    else:
        print(f"Warning: No data found for income level: {demo_value}")

# Create the final table
financial_situation_table = pd.DataFrame(results)
financial_situation_table['Measure'] = 'Financial Situation (Excellent + Good)'

# Convert to LaTeX
latex_body_fin = financial_situation_table.to_latex(index=False, float_format="%.f")

latex_table_fin = f"""\\begin{{table}}[ht!]
\\centering
{latex_body_fin}
\\caption{{Financial Situation by Income Level: Excellent + Good Percentages}}
\\label{{tab:financial_situation}}
\\end{{table}}
"""
personal_results = []

for demo_value, income_label in income_level_mapping.items():
    # Filter data for this income level
    income_data = personal_satisfaction[personal_satisfaction['Demographic Value'] == demo_value].copy()
    
    if len(income_data) > 0:
        # Calculate averages for the two periods (note: 2024-2025 instead of 2022-2025)
        period_2016_2019 = income_data[
            (income_data['Time'] >= 2016) & (income_data['Time'] <= 2019)
        ]['Satisfied'].mean()
        
        period_2024_2025 = income_data[
            (income_data['Time'] >= 2024) & (income_data['Time'] <= 2025)
        ]['Satisfied'].mean()
        
        difference = period_2024_2025 - period_2016_2019
        
        personal_results.append({
            'Income Level': income_label,
            '2016-2019 Average': period_2016_2019,
            '2024-2025 Average': period_2024_2025,
            'Difference (24-25 minus 16-19)': difference
        })
        
        # print(f"Personal Satisfaction - {income_label}: 2016-2019 avg = {period_2016_2019:.3f}, 2024-2025 avg = {period_2024_2025:.3f}")
    else:
        print(f"Warning: No personal satisfaction data found for income level: {demo_value}")

# Create the personal satisfaction table
personal_satisfaction_table = pd.DataFrame(personal_results)
personal_satisfaction_table['Measure'] = 'Personal Satisfaction (Satisfied)'

very_results = []

for demo_value, income_label in income_level_mapping.items():
    # Filter data for this income level
    income_data = very_satisfaction[very_satisfaction['Demographic Value'] == demo_value].copy()
    
    if len(income_data) > 0:
        # Calculate averages for the two periods (2016-2019 and 2024-2025)
        period_2016_2019 = income_data[
            (income_data['Time'] >= 2016) & (income_data['Time'] <= 2019)
        ]['Very satisfied'].mean()
        
        period_2024_2025 = income_data[
            (income_data['Time'] >= 2024) & (income_data['Time'] <= 2025)
        ]['Very satisfied'].mean()
        
        difference = period_2024_2025 - period_2016_2019
        
        very_results.append({
            'Income Level': income_label,
            '2016-2019 Average': period_2016_2019,
            '2024-2025 Average': period_2024_2025,
            'Difference (24-25 minus 16-19)': difference
        })
        
        # print(f"Very Satisfaction - {income_label}: 2016-2019 avg = {period_2016_2019:.3f}, 2024-2025 avg = {period_2024_2025:.3f}")
    else:
        print(f"Warning: No very satisfaction data found for income level: {demo_value}")

# Create the very satisfaction table
very_satisfaction_table = pd.DataFrame(very_results)

# Add a measure identifier to the very satisfaction table
very_satisfaction_table['Measure'] = 'Very Satisfaction (Very satisfied)'

# Rename columns to be consistent (very satisfaction uses 2024-2025)
very_satisfaction_table = very_satisfaction_table.rename(columns={
    '2024-2025 Average': '2022-2025 Average',
    'Difference (24-25 minus 16-19)': 'Difference (22-25 minus 16-19)'
})

# Append to the combined table
combined_table = pd.concat([financial_situation_table, personal_satisfaction_table, very_satisfaction_table], ignore_index=True)

# Reorder columns for better presentation
combined_table = combined_table[['Measure', 'Income Level', '2016-2019 Average', '2022-2025 Average',
                                 '2024-2025 Average', 'Difference (22-25 minus 16-19)', 'Difference (24-25 minus 16-19)']]

# Convert updated combined table to LaTeX
latex_body_combined_updated = combined_table.to_latex(index=False, float_format="%.3f")

latex_table_combined_updated = f"""\\begin{{table}}[ht!]
\\centering
\\resizebox{{\\textwidth}}{{!}}{{%
{latex_body_combined_updated}
}}
\\caption{{Financial Situation, Personal Satisfaction, and Very Satisfaction by Income Level}}
\\label{{tab:combined_satisfaction_updated}}
\\end{{table}}"""

# Save updated combined LaTeX table
with open(f"{table_dir}/table_B_3.tex", "w") as f:
    f.write(latex_table_combined_updated)


########################################################################
# Table B.4
########################################################################
print("Making Table B.4...")

data = pd.read_csv(f"{data_processed_dir}/figure_B_15.csv")
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

with open(f"{table_dir}/table_B_4.tex", "w") as f:
    f.write(latex_table)
print("Table B.4 processed and saved.")
