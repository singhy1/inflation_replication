# Yash Singh 
# date: 4/10/25 
# industry flows and wages 

import numpy as np
import pandas as pd 
from sklearn.linear_model import LinearRegression



# Specify directories 
data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"
temp_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/temp"

# Wage and Price data 
wage_data = pd.read_excel(f"{data_dir}/atl_fed/wage-growth-data.xlsx", sheet_name = "Industry", skiprows=2, header=0)
cpi = pd.read_csv(f"{data_dir}/CPI/CPIAUCSL.csv")

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


#############################################################################################
#############################################################################################
# Flow Analysis 
#############################################################################################
#############################################################################################


df_raw = pd.read_excel(f"{data_dir}/JOLTS/jolts_flows.xlsx", skiprows=2)

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
    'Mining and logging', 'Construction',
    'Wholesale trade',
    'Retail trade',
    'Education and health services', 'Educational services', 'Health care and social assistance',
    'Leisure and hospitality', 'Other services',
    'Trade, transportation, and utilities', 'Transportation, warehousing, and utilities',
    'Manufacturing',
    'Information', 'Information (detailed)', 'Financial activities', 'Finance and insurance',
    'Real estate and rental and leasing', 'Professional and business services',
    'Professional, scientific, and technical services', 'Administrative and support and waste management', 
     "Federal government", "State and local government", "State government", "Local government"
]

data = data[data['industry'].isin(keep_list)]

jolts_to_wage_mapping = {
    'Mining and logging': 'Construction and Mining',
    'Construction': 'Construction and Mining',

    'Education and health services': 'Education and health',
    'Educational services': 'Education and health',
    'Health care and social assistance': 'Education and health',

    'Leisure and hospitality': 'Leisure and hospitality and other services',
    'Other services': 'Leisure and hospitality and other services',

    'Trade, transportation, and utilities': 'Trade and transportation',
    'Transportation, warehousing, and utilities': 'Trade and transportation',
    'Wholesale trade': 'Trade and transportation',
    'Retail trade': 'Trade and transportation',

    'Manufacturing': 'Manufacturing',

    'Information': 'Finance and business services',
    'Information (detailed)': 'Finance and business services',
    'Financial activities': 'Finance and business services',
    'Finance and insurance': 'Finance and business services',
    'Real estate and rental and leasing': 'Finance and business services',
    'Professional and business services': 'Finance and business services',
    'Professional, scientific, and technical services': 'Finance and business services',
    'Administrative and support and waste management': 'Finance and business services', 
    
    "Federal government" : "Public Administration", 
    "State and local government" : "Public Administration", 
    "State government" : "Public Administration", 
    "Local government" : "Public Administration", 
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

pct_change_with_gap_final.to_excel(f"{output_dir}/tables/structural_change.xlsx") 


print("HI")
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


