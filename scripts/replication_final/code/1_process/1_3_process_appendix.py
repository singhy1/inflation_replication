######################################################################
# Date Created: 7/10/2025
# Last Modified: 7/11/2025
# This Code:
# - takes the raw data from /master/data/raw
# - processes it to create Dataframes for making all figures
# - in the appendix.
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
vacancy_raw = pd.read_excel(f"{data_dir}/barnichon/barnichon_vacancy.xlsx")
# Stock of Employed and Unemployed Workers 
stocks_raw = pd.read_csv(f"{data_dir}/fred/fred_employment.csv")
# JOLTS (level)
jolts_raw = pd.read_csv(f"{data_dir}/jolts/jolts_level.csv")
# JOLTS (rates)
jolts_rates_raw = pd.read_csv(f"{data_dir}/jolts/jolts_rates.csv")
# JOLTS (flows)
jolts_flows_raw = pd.read_excel(f"{data_dir}/jolts/jolts_industry_rates.xlsx", skiprows=2)
# JOLTS (industry level)
jolts_industry_raw = pd.read_excel(f"{data_dir}/jolts/jolts_industry_level.xlsx", skiprows=2)
# Consumer Price Index
cpi_raw = pd.read_csv(f"{data_dir}/fred/CPI.csv")
# Average Wage Quartile
wage_raw = pd.read_excel(f"{data_dir}/atl_fed/atl_fed_wage.xlsx", sheet_name = 'Average Wage Quartile', skiprows=2, header=0)
# Job Switcher and Stayer Wage Growth
switcher_raw = pd.read_excel(f"{data_dir}/atl_fed/atl_fed_wage.xlsx", sheet_name = 'Job Switcher', skiprows=2, header=0)    
# FMP
fmp_raw = pd.read_csv(f"{data_dir}/fmp/fmp_ee_flow.csv") 
# UE
ue_raw = pd.read_csv(f"{data_dir}/fred/UE.csv")
# EU
eu_raw = pd.read_csv(f"{data_dir}/fred/EU.csv")
# NE
ne_raw = pd.read_csv(f"{data_dir}/fred/NE.csv")
# NU
nu_raw = pd.read_csv(f"{data_dir}/fred/NU.csv")
# Unemployment Rate
u_rate_raw = pd.read_csv(f"{data_dir}/fred/fred_urate.csv")
# Employment to Population Ratio
emp2pop_raw = pd.read_csv(f"{data_dir}/fred/fred_emp2pop.csv")
# ADP
adp_raw = pd.read_csv(f"{data_dir}/adp/adp_pay_history.csv")
# Employment by Industry
emp_industry_raw = pd.read_excel(f"{data_dir}/bls/hours_employed_industry.xlsx", sheet_name="MachineReadable")
# Employment Flow by Education
ee_flows_raw = pd.read_csv(f"{data_dir}/lehd/flows_by_education.csv")
# Employment by Education
employment_raw = pd.read_csv(f"{data_dir}/lehd/employment_by_education.csv")
# Profit share
profit_share_raw = pd.read_csv(f"{data_dir}/fred/profit_share.csv")
# Gallup Financial Situation Data
gallup_raw = pd.read_excel(f"{data_dir}/gallup/gallup_data.xlsx", sheet_name="Financial situation today", skiprows=7)


######################################################################
# Figure B.1, Panel A, B
######################################################################
print("Processing data for Figure B.1, Panel A, B...")

df = jolts_rates_raw.copy()
cpi = cpi_raw.copy()

df.rename(columns={
    'observation_date': 'date',
    'JTSLDR': 'layoff_rate_jolts',
    'JTSQUR': 'quit_rate_jolts',
    'JTSJOR': 'vacancy_rate_jolts',
}, inplace=True)
df['date'] = pd.to_datetime(df['date'])

cpi.rename(columns={'observation_date': 'date', 'CPIAUCSL': 'P'}, inplace=True)
cpi['date'] = pd.to_datetime(cpi['date'])
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100

df = df.merge(cpi, on='date')
df = df[df['date'] >= '2016-01-01']
df.sort_values('date', inplace=True)

df.to_csv(f"{output_dir}/figure_B_1.csv", index=False)
print("Processed data for Figure B.1, Panel A, B saved.")

######################################################################
# Figure B.2, Panel A, B, C
######################################################################
print("Processing data for Figure B.2, Panel A, B, C...")

stocks = stocks_raw.copy()
ue = eu_raw.copy()
u_rate = u_rate_raw.copy()
emp2pop = emp2pop_raw.copy()

stocks.columns = ['date', 'E', 'U']
stocks = stocks.iloc[11:].reset_index(drop=True)
stocks = stocks.dropna(subset=['date', 'E', 'U'])
stocks['date'] = pd.to_datetime(stocks['date'])
stocks['U'] = stocks['U'].astype(float)

ue.columns = ['date', 'eu_flows']
ue['date'] = pd.to_datetime(ue['date'])

# Merge and calculate job finding rate
data = stocks.merge(ue, on=['date'])
data['eu_rate'] = (data['eu_flows'] / data['E'])* 100

u_rate.columns = ['date', 'u_rate']
u_rate = u_rate.iloc[11:].reset_index(drop=True)
u_rate = u_rate.dropna(subset=['date', 'u_rate'])
u_rate['date'] = pd.to_datetime(u_rate['date'])
u_rate['u_rate'] = u_rate['u_rate'].astype(float)

emp2pop.columns = ['date', 'emp2pop']
emp2pop = emp2pop.iloc[11:].reset_index(drop=True)
emp2pop = emp2pop.dropna(subset=['date', 'emp2pop'])
emp2pop['date'] = pd.to_datetime(emp2pop['date'])
emp2pop['emp2pop'] = emp2pop['emp2pop'].astype(float)

final = data.merge(u_rate, on=['date'])
final = final.merge(emp2pop, on= ['date'])
final = final[(final['date'] >= '2016-01-01')]
keep = ['date', 'eu_rate', 'u_rate', 'emp2pop']
final = final[keep].reset_index(drop=True)
final['inf_period'] = ((final['date'] >= '2021-04-01') & (final['date'] <= '2023-05-01')).astype(int)
final['pre_period'] = ((final['date'] <= '2019-12-01')).astype(int)

# Mask out 2020 but keep NaNs so lines are broken
plot_data = final.copy()
plot_data.loc[plot_data['date'].between('2020-01-01', '2020-12-31'), ['eu_rate', 'u_rate', 'emp2pop']] = np.nan

plot_data.to_csv(f"{output_dir}/figure_B_2.csv", index=False)
print("Processed data for Figure B.2, Panel A, B, C saved.")

######################################################################
# Figure B.3, Panel A, B
######################################################################
print("Processing data for Figure B.3, Panel A, B...")

NE = ne_raw.copy()
NU = nu_raw.copy()

# Basic Processing of stocks 
NE.columns = ['date', 'NE']
NU.columns = ['date', 'NU']

data = NU.merge(NE, on=['date'])
data['NU'] = data['NU']*100
data['NE'] = data['NE']*100

# Add pre/inflation period indicators
data['date'] = pd.to_datetime(data['date'])
data['inf_period'] = ((data['date'] >= '2021-04-01') & (data['date'] <= '2023-05-01')).astype(int)
data['pre_period'] = (data['date'] <= '2019-12-01').astype(int)

# Mask out 2020 for line break
plot_data = data.copy()
plot_data.loc[plot_data['date'].between('2020-01-01', '2020-12-31'), ['NE', 'NU']] = np.nan

plot_data.to_csv(f"{output_dir}/figure_B_3.csv", index=False)
print("Processed data for Figure B.3, Panel A, B saved.")

######################################################################
# Figure B.4
######################################################################
print("Processing data for Figure B.4...")

stocks = stocks_raw.copy()
eu = eu_raw.copy()
ue = ue_raw.copy()

stocks.columns = ['date', 'E', 'U']
stocks = stocks.iloc[11:].reset_index(drop=True)
stocks = stocks.dropna(subset=['date', 'E', 'U'])
stocks['date'] = pd.to_datetime(stocks['date'])
stocks['U'] = stocks['U'].astype(float)

eu.columns = ['date', 'eu_flows']
ue.columns = ['date', 'ue_flows']

flows = eu.merge(ue, on = ['date'])
flows['date'] = pd.to_datetime(flows['date'])

data = stocks.merge(flows, on = ['date'])

data['L'] = data['E'] + data['U']
data['u_rate'] = data['U'] / data['L']
data['seperation_rate'] = data['eu_flows'] / data['E']
data['job_finding_rate'] = data['ue_flows'] / data['U']

keep = ['date', 'u_rate', 'seperation_rate', 'job_finding_rate']
final = data[keep]

final['u_rate_ma3'] = final['u_rate'].rolling(window=3).mean()
final['seperation_rate_ma3'] = final['seperation_rate'].rolling(window=3).mean()
final['job_finding_rate_ma3'] = final['job_finding_rate'].rolling(window=3).mean()

keep = ['date', 'u_rate_ma3', 'seperation_rate_ma3', 'job_finding_rate_ma3' ]
final = final[keep]
final = final.rename(columns = {'u_rate_ma3' : 'u_rate', 'seperation_rate_ma3': 'seperation_rate', 'job_finding_rate_ma3':'job_finding_rate'})

final.to_csv(f"{output_dir}/figure_B_4.csv", index=False)
print("Processed data for Figure B.4 saved.")

######################################################################
# Figure B.5, Panel A
######################################################################
print("Processing data for Figure B.5...")

data = switcher_raw.copy()
df = pd.DataFrame(data)

# Convert the date column to datetime objects
df["Unnamed: 0"] = pd.to_datetime(df["Unnamed: 0"])

# Replace placeholder '.' values with NaN
df.replace(".", float("nan"), inplace=True)

# Convert the numeric columns to float
df["Job Stayer"] = pd.to_numeric(df["Job Stayer"], errors="coerce")
df["Job Switcher"] = pd.to_numeric(df["Job Switcher"], errors="coerce")

# Set the date column as the index
df.set_index("Unnamed: 0", inplace=True)

# Filter the dataframe to include only data from 2016 to 2024.
start_date = "2016-01-01"
end_date = "2024-12-31"
filtered_df = df.loc[start_date:end_date]

filtered_df.to_csv(f"{output_dir}/figure_B_5_A.csv", index=True)
print("Processed data for Figure B.5, Panel A saved.")

######################################################################
# Figure B.7
######################################################################
print("Processing data for Figure B.7...")

data = wage_raw.copy()
cpi = cpi_raw.copy()

plt.rcParams.update({
    'font.size': 14,             # Set default font size
    'axes.titlesize': 24,        # Title font size
    'axes.labelsize': 20,        # Axis labels font size
    'legend.fontsize': 12,       # Legend font size
    'xtick.labelsize': 20,       # X-axis tick labels
    'ytick.labelsize': 20,       # Y-axis tick labels
    'legend.frameon': False,     # Remove legend box
    'axes.spines.top': False,    # Remove top spine
    'axes.spines.right': False,  # Remove right spine
})

# Atlanta Fed Wage Data 
data = data.rename(columns={
    'Unnamed: 0': 'date',
    'Lowest quartile of wage distribution': 'Q1',
     '2nd quartile of wage distribution': 'Q2', 
    '3rd quartile of wage distribution': 'Q3', 
    'Highest quartile of wage distribution': 'Q4'
})

select = ['date', 'Q1', 'Q2', 'Q3', 'Q4']
df = data[select]

# CPI-U 
cpi = cpi.iloc[10:].reset_index(drop=True)

cpi = cpi.rename(columns={
                            'observation_date': 'date', 
                            'CPIAUCSL':               'P'
})

cpi['date'] = pd.to_datetime(cpi['date'])
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100

wage_data = data.merge(cpi, on='date', how = 'left')

# 2000-2024 
wage_data = wage_data[wage_data['date'] >= '1999-12-01']
wage_data = wage_data[wage_data['date'] <= '2024-12-01']

wage_data = wage_data.drop(['Lowest half of wage distribution', 'Upper half of wage distribution'], axis = 1)
wage_data = wage_data.reset_index(drop=True)

wage_data['wage_index_1'] = 1   
wage_data['wage_index_2'] = 1
wage_data['wage_index_3'] = 1
wage_data['wage_index_4'] = 1
wage_data['med_wage_index'] = 1 

p_2020_m1 = wage_data[wage_data['date'] == '2020-01-01']['P'].values[0]
wage_data['P_norm'] = wage_data['P'] / p_2020_m1

wage_data['price_mom_grth'] = 1 + wage_data['P_norm'].pct_change()

wage_data = wage_data[wage_data['date'] >= '2000-01-01']

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
wage_data['price_index'] = wage_data['P_1m_change'].cumprod()
wage_data['price_index'] = wage_data['price_mom_grth'].cumprod()

wage_data = wage_data.fillna(1)

wage_data['real_wage_index_1'] = wage_data['nom_wage_index_1'] / wage_data['price_index']
wage_data['real_wage_index_2'] = wage_data['nom_wage_index_2'] / wage_data['price_index']
wage_data['real_wage_index_3'] = wage_data['nom_wage_index_3'] / wage_data['price_index']
wage_data['real_wage_index_4'] = wage_data['nom_wage_index_4'] / wage_data['price_index']
wage_data['med_real_wage_index'] = wage_data['med_nom_wage_index'] / wage_data['price_index']

start_date = '2000-01-01'
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

wage_data.to_csv(f"{output_dir}/figure_B_7.csv", index=False)
print("Processed data for Figure B.7 saved.")

######################################################################
# Figure B.8 
######################################################################
print("Processing data for Figure B.8...")

# initally processed atlanta fed data
df = pd.read_csv(f"{output_dir}/figure_B_8_temp1.csv")
df_pol = pd.read_csv(f"{output_dir}/figure_B_8_temp2.csv")
cpi = cpi_raw.copy()

df = df.merge(df_pol, on='date_monthly')


# Convert 'date_monthly' from '2016m1' format to datetime
df['date'] = pd.to_datetime(
    df['date_monthly'].str.extract(r'(\d{4})m(\d{1,2})')
    .apply(lambda x: f"{x[0]}-{int(x[1]):02d}", axis=1)
)


cpi['date'] = pd.to_datetime(cpi['observation_date'])
cpi = cpi.rename(columns={'CPIAUCSL': 'P'})
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100
cpi['P_1m_change'] = 1 + (cpi['P_12m_change'] / 100) / 12
cpi = cpi[['date', 'P_1m_change']]

    # Merge CPI with wage growth data
df = df.merge(cpi, on='date', how='left')
    
# Compute monthly wage growth factors
wage_columns = [col for col in df.columns if col.startswith('smwg')]
for col in wage_columns:
    df[f'{col}_mom_grth'] = 1 + (df[col] / 100) / 12

# Compute nominal wage indices
for col in wage_columns:
    df[f'nom_index_{col}'] = df[f'{col}_mom_grth'].cumprod()

# Compute price index
df['price_index'] = df['P_1m_change'].cumprod()

# Compute real wage indices
for col in wage_columns:
        df[f'real_index_{col}'] = df[f'nom_index_{col}'] / df['price_index']

# Select final columns
result_cols = ['date', 'price_index'] + [f'real_index_{col}' for col in wage_columns]
result_df = df[result_cols]
# Recalculate trend dataframe based on the existing df
start_date = pd.to_datetime("2016-01-01")
end_date = pd.to_datetime("2019-12-31")

trend_df = df[(df['date'] >= start_date) & (df['date'] <= end_date)]
X_trend = ((trend_df['date'].dt.year - trend_df['date'].min().year) * 12 +
           (trend_df['date'].dt.month - trend_df['date'].min().month)).values.reshape(-1, 1)
X_all = ((df['date'].dt.year - trend_df['date'].min().year) * 12 +
         (df['date'].dt.month - trend_df['date'].min().month)).values.reshape(-1, 1)

# Identify real wage index columns
real_index_cols = [col for col in df.columns if col.startswith('real_index_')]

predicted = {}
for col in real_index_cols + ['price_index']:
    y = trend_df[col].values
    model = LinearRegression()
    model.fit(X_trend, y)
    predicted[col] = model.predict(X_all)
    df[f'predicted_{col}'] = predicted[col]

# Compute final gaps between actual and trend
gaps = {
    col: df[f'predicted_{col}'].iloc[-1] - df[col].iloc[-1]
    for col in real_index_cols + ['price_index']
}
# Define relevant columns
gap_columns = {
    'Bachelor_plus_1st_Quartile': ('real_index_smwg1st_Bachelors_plus', 'predicted_real_index_smwg1st_Bachelors_plus'),

    'Less_Bachelor_1st_Quartile': ('real_index_smwg1st_Less_than_Bachelors', 'predicted_real_index_smwg1st_Less_than_Bachelors'),


    'Bachelor_plus_4th_Quartile': ('real_index_smwg4th_Bachelors_plus', 'predicted_real_index_smwg4th_Bachelors_plus'),
    'Less_Bachelor_4th_Quartile': ('real_index_smwg4th_Less_than_Bachelors', 'predicted_real_index_smwg4th_Less_than_Bachelors'),

    'q1_Pooled': ('real_index_smwg1st', 'predicted_real_index_smwg1st'),
    'q4_Pooled': ('real_index_smwg4th', 'predicted_real_index_smwg4th')
}

# Filter from Jan 2020 onward
plot_start_date = pd.to_datetime("2020-01-01")
mask = df['date'] >= plot_start_date
df_filtered = df.loc[mask].copy()

# Initialize output DataFrame
gap_df = df_filtered[['date']].copy()

# Calculate gaps
for label, (actual_col, trend_col) in gap_columns.items():
    gap = (df_filtered[actual_col] - df_filtered[trend_col]) *100
    gap.iloc[0] = 0  # normalize gap to 0 at 2020-01
    gap_df[label] = gap.values

gap_df.to_csv(f"{output_dir}/figure_B_8.csv", index=False)
print("Processed data for Figure B.8 saved.")

######################################################################
# Figure B.9
######################################################################
print("Processing data for Figure B.9...")

df_raw = jolts_flows_raw.copy()

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

df_long = df_long.rename(columns={
    'value': 'rate',
})
keep = ['date', 'rate', 'flow_type', 'industry']
data = df_long[keep]

data = data.groupby(['industry', 'flow_type', 'date'])['rate'].mean().reset_index()
data = data[data['date'].dt.year != 2020]

conditions = [
    data['date'] < '2020-01-01',
    (data['date'] >= '2021-04-01') & (data['date'] <= '2023-05-01'),
    data['date'] >= '2023-06-01'
]
choices = ['pre', 'inf', 'post']

data['period'] = np.select(conditions, choices, default=pd.NA)

table = data.groupby(['industry', 'flow_type', 'period'])['rate'].mean().reset_index()

table = table[table['flow_type'].isin(['Quits', 'Job Openings'])]

exclude_keywords = ['government', 'Total']

# Filter to keep only industries that do NOT contain any exclude keywords
table = table[~table['industry'].str.contains('|'.join(exclude_keywords), case=False)]

# List of industry labels to drop
industries_to_drop = [
    'Financial activities',
    'Manufacturing',
    'Leisure and Hospitality',
    'Private education and health services',
    'Trade, transportation, and utilities',
]

# Filter the DataFrame
table = table[~table['industry'].isin(industries_to_drop)]

# Keep only rows where period is 'inf' or 'pre'
df = table[table['period'].isin(['inf', 'pre'])]
df = df.rename(columns={"industry":"jolts_industry"})

# Pivot so we have one row per industry and flow_type, with 'inf' and 'pre' as columns
pivot_df = df.pivot_table(index=['jolts_industry', 'flow_type'], columns='period', values='rate').reset_index()

# Calculate percent change: ((inf - pre) / pre) * 100
pivot_df['pct_change'] = 100 * (pivot_df['inf'] - pivot_df['pre']) / pivot_df['pre']

# Pivot to get pct_change for Job Openings and Quits per industry
pivot_df = pivot_df.pivot(index='jolts_industry', columns='flow_type', values='pct_change').reset_index()

# Rename columns
pivot_df = pivot_df.rename(columns={
    "Job Openings": "job_opening_pct_change",
    "Quits": "quits_pct_change"
})

### Generate vacancy weights

df_raw = jolts_industry_raw.copy()

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

# Define flow type mapping
flow_type_map = {
    "HIL": "Hires",
    "QUL": "Quits",
    "TSL": "Total Separations",
    "JOL": "Job Openings",
    "LDL": "Layoffs & Discharges",
    "UOL": "Other Separations",
    "OSL": "Other Separations (Residual)"
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
df_long["jolts_industry"] = df_long["industry_code"].map(industry_map)

df_long = df_long.rename(columns={
    'value': 'level',
})

df = df_long

# List of industries to keep
industries_to_keep = [
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

# Filter the DataFrame
df = df[df['jolts_industry'].isin(industries_to_keep)].copy()

df['year'] = df['date'].dt.year
df = df[df['flow_type'].isin(['Job Openings'])].copy()
df = df.groupby(['year', 'jolts_industry'], as_index=False)['level'].sum()

exclude_keywords = ['government', 'Total']

# Filter to keep only industries that do NOT contain any exclude keywords
df = df[~df['jolts_industry'].str.contains('|'.join(exclude_keywords), case=False)]

df['tot'] = df.groupby(['year'])['level'].transform('sum')
df['vac_share'] = df['level']/df['tot']
df = df[df['year'] <= 2019]

industry_avg = df.groupby('jolts_industry', as_index=False)['vac_share'].mean()
vac_wgt = industry_avg.copy()

### Generate employment weights

df = emp_industry_raw.copy()

# Year (2016-2019)
df= df[(df["Year"] >= 2016) & (df['Year'] <= 2019)]
# Measure 
df = df[df['Measure'] == "Employment"]
# Units 
df = df[df['Units'] == "Thousands of jobs"]
# mapping based on 4 digit NAICS sectors 
df = df[df['Digit'] == "4-Digit"]

def map_naics_code_to_industry(naics_code):
    """
    Map NAICS 4- or 2-digit code to a JOLTS industry category.
    """
    naics_str = str(naics_code).zfill(4)  # Pad to 4 digits
    naics_4 = int(naics_str[:4])
    naics_2 = int(naics_str[:2])

    # Priority mapping for specific 4-digit codes
    four_digit_map = {
        1133: "Mining and Logging",
        321: "Durable Goods Manufacturing",
        327: "Durable Goods Manufacturing",
        322: "Nondurable Goods Manufacturing",
        323: "Nondurable Goods Manufacturing",
        324: "Nondurable Goods Manufacturing",
        325: "Nondurable Goods Manufacturing",
        326: "Nondurable Goods Manufacturing",
    }

    # General 2-digit NAICS to JOLTS sector
    two_digit_map = {
        21: "Mining and Logging",
        22: "Utilities",
        23: "Construction",
        31: "Nondurable Goods Manufacturing",
        32: "Nondurable Goods Manufacturing",
        33: "Durable Goods Manufacturing",
        42: "Wholesale Trade",
        44: "Retail Trade",
        45: "Retail Trade",
        48: "Transportation and Warehousing",
        49: "Transportation and Warehousing",
        51: "Information",
        52: "Finance and Insurance",
        53: "Real Estate and Rental and Leasing",
        54: "Professional and Business Services",
        55: "Professional and Business Services",
        56: "Administrative and support and waste management",
        61: "Private Educational Services",
        62: "Health Care and Social Assistance",
        71: "Arts, Entertainment, and Recreation",
        72: "Accommodation and Food Services",
        81: "Other Services",
    }

    # Try 4-digit first, fallback to 2-digit
    return four_digit_map.get(naics_4, two_digit_map.get(naics_2, "Unknown"))

df['industry'] = df['NAICS'].apply(map_naics_code_to_industry)

def map_to_jolts_industry(industry):
    """
    Maps detailed industry labels to standardized JOLTS industry labels.
    """
    mapping = {
        'Accommodation and Food Services': 'Accomodation and food services',
        'Arts, Entertainment, and Recreation': 'Arts, entertainment, and recreation',
        'Construction': 'Construction',
        'Durable Goods Manufacturing': 'Durable goods manufacturing',
        'Finance and Insurance': 'Finance and insurance',
        'Health Care and Social Assistance': 'Healthcare and Social Assistance',
        'Information': 'Information',
        'Mining and Logging': 'Mining and logging',
        'Nondurable Goods Manufacturing': 'Nondurable goods manufacturing',
        'Other Services': 'Other services',
        'Private Educational Services': 'Private education services',
        'Professional and Business Services': 'Professional and business services',
        'Real Estate and Rental and Leasing': 'Real estate and rental and leasing',
        'Retail Trade': 'Retail trade',
        'Transportation and Warehousing': 'Transportation, warehousing, and utilities',
        'Utilities': 'Transportation, warehousing, and utilities',  # grouped in JOLTS
        'Wholesale Trade': 'Wholesale trade',
        'Administrative and support and waste management': 'Professional and business services',  # subcategory of sector 56
        'Unknown': 'Unknown'  # or could be np.nan if you want to drop/mask it
    }

    return mapping.get(industry, 'Unknown')

df = df[df['industry'] != "Unknown"]
df['jolts_industry'] = df['industry'].apply(map_to_jolts_industry)
df = df.groupby(['Year', 'jolts_industry'], as_index=False)['Value'].sum()
total_emp_per_year = df.groupby('Year')['Value'].transform('sum')
df['emp_share'] = df['Value'] / total_emp_per_year
df = df.groupby('jolts_industry', as_index=False)['emp_share'].mean()
emp_wgt = df.copy()

final_df = pivot_df.merge(emp_wgt, on='jolts_industry')
final_df = final_df.merge(vac_wgt, on='jolts_industry')

final_df.to_csv(f"{output_dir}/figure_B_9.csv", index=False)
print("Processed data for Figure B.9 saved.")

######################################################################
# Figure B.10, Panel A, B
######################################################################
print("Processing data for Figure B.10, Panel A, B...")

ee_flows = ee_flows_raw.copy() 
employment = employment_raw.copy()

# First, re-import and clean to start from raw data
ee_clean = ee_flows[['year', 'quarter', 'education', 'EE', 'EES', 'J2J', 'J2JS']]

ee_clean['EE'] = pd.to_numeric(ee_clean['EE'], errors='coerce')
ee_clean['EES'] = pd.to_numeric(ee_clean['EES'], errors='coerce')
ee_clean['J2J'] = pd.to_numeric(ee_clean['J2J'], errors='coerce')
ee_clean['J2JS'] = pd.to_numeric(ee_clean['J2JS'], errors='coerce')

emp_clean = employment[['year', 'quarter', 'education', 'Emp']]
emp_clean['Emp'] = pd.to_numeric(emp_clean['Emp'], errors='coerce')

# Merge
merged = pd.merge(ee_clean, emp_clean, on=['year', 'quarter', 'education'])

merged['date'] = pd.to_datetime(merged['year'].astype(str) + 'Q' + merged['quarter'].astype(str))

# Compute merged EE rate and convert to %
merged['ee_rate'] = 100 * merged['EE'] / merged['Emp']
merged['ee_rate_stable'] = 100 * merged['EES'] / merged['Emp']
merged['j2j_rate'] = 100 * merged['J2J'] / merged['Emp']
merged['j2j_rate_stable'] = 100 * merged['J2JS'] / merged['Emp']

# Already pivoted data: pivot_df
pivot_df = merged.pivot(index='date', columns='education', values='j2j_rate')

# Define periods
pivot_df['inf_period'] = ((pivot_df.index >= '2021-04-01') & (pivot_df.index <= '2023-05-01')).astype(int)
pivot_df['pre_period'] = (pivot_df.index <= '2019-12-01').astype(int)

# Resample to quarterly averages (calendar quarters)
pivot_quarterly = pivot_df.resample('Q').mean()

# Redefine period flags after resampling
pivot_quarterly['inf_period'] = ((pivot_quarterly.index >= '2021-04-01') & (pivot_quarterly.index <= '2023-05-01')).astype(int)
pivot_quarterly['pre_period'] = (pivot_quarterly.index <= '2019-12-01').astype(int)

pivot_quarterly.to_csv(f"{output_dir}/figure_B_10.csv", index=True)
print("Processed data for Figure B.10, Panel A, B saved.")

######################################################################
# Figure B.12
######################################################################
print("Processing data for Figure B.12...")

gallup = gallup_raw.copy()
gallup = gallup[gallup['Demographic Value'] == 'Aggregate']
keep_cols = ['Time', 'Excellent', 'Good']
gallup = gallup[keep_cols]
gallup['Excellent_Good'] = gallup['Excellent'] + gallup['Good']
# keep only if 
gallup['date'] = pd.to_datetime(gallup['Time'], format='%Y')
gallup.to_csv(f"{output_dir}/figure_B_12.csv", index=False)

######################################################################
# Figure B.13
######################################################################
print("Processing data for Figure B.13...")

jolts = jolts_raw.copy()
stocks = stocks_raw.copy()

jolts.columns = ['date', 'vacancy_stock', 'tot_quits','tot_hires', 'tot_layoffs']
jolts = jolts.iloc[13:].reset_index(drop=True)
jolts['date'] = pd.to_datetime(jolts['date'])

stocks.columns = ['date', 'E', 'U']
stocks = stocks.iloc[11:].reset_index(drop=True)
stocks = stocks.dropna(subset=['date', 'E', 'U'])
stocks['date'] = pd.to_datetime(stocks['date'])
stocks['U'] = stocks['U'].astype(float)

final = stocks.merge(jolts, on = ['date'])
keep = ['date', 'E', 'U', 'vacancy_stock', 'tot_hires', 'tot_layoffs']
final = final[keep]
final.to_csv(f"{output_dir}/figure_B_13.csv", index=False)
print("Processed data for Figure B.13 saved.")

#######################################################################
# Figure B.14, Panel A
#######################################################################
print("Processing data for Figure B.14...")

cpi = cpi_raw.copy()
profit_share = profit_share_raw.copy()
historical_data = pd.read_csv(f"{output_dir}/figure_1_1_A.csv")

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

profit_share.to_csv(f"{output_dir}/figure_B_14_A.csv", index=False)
print("Processed data for Figure B.14, Panel A saved.")

#######################################################################
# Figure B.14, Panel B, Table B.4, Figure B.15
#######################################################################
print("Processing data for Figure B.14, Panel B...")

data = profit_share.merge(cpi, on='date')
data = data.merge(u_rate, on='date')
data.to_csv(f"{output_dir}/figure_B_14_B.csv", index=False)
data.to_csv(f"{output_dir}/figure_B_15.csv", index=False)
print("Processed data for Figure B.14, Panel B saved.")
print("Processed data for Figure B.15, Table B.4 saved.")
