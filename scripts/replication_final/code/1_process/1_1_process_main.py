################################################################################
# DATA PROCESSING - MAIN TEXT FIGURES (PYTHON)
# 
# Purpose: Process raw data to create clean datasets for main text figures
# 
# Description:
#   - Takes raw data from /replication_final/data/raw
#   - Creates processed datasets for main text figures
#   - Outputs to /replication_final/data/processed
#
# Generated Processed Datasets:
#   - figure_1_1_A.csv (= figure_6_1.csv)
#   - figure_1_1_B.csv (= figure_B_6.csv)
#   - figure_2_1.csv
#   - figure_2_2_A.csv
#   - figure_2_2_B.csv
#   - figure_2_3.csv
#   - figure_2_4.csv
#
# Author: Yash Singh, Giyoung Kwon
# Last Updated: 2025/7/28
################################################################################

# Import required libraries
import numpy as np 
import pandas as pd 
import os
import platform
from pathlib import Path
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
import statsmodels.api as sm
import warnings
from collections import defaultdict

# Suppress warnings for cleaner output
warnings.filterwarnings("ignore")

################################################################################
# SETUP: CONFIGURE PATHS AND DIRECTORIES
################################################################################

# Detect operating system for cross-platform compatibility
is_win = platform.system() == "Windows"

# Get username (cross-platform)
user = os.environ.get("USER") or os.environ.get("USERNAME")

# Define base project directory path
if is_win:
    proj_dir = Path(f"C:/Users/{user}/Dropbox/Labor_Market_PT/replication/final")
else:
    proj_dir = Path(f"/Users/{user}/Library/CloudStorage/Dropbox/Labor_Market_PT/replication/final")

# Define input and output directories
data_dir = proj_dir / "data" / "raw"
output_dir = proj_dir / "data" / "processed"


################################################################################
# DATA LOADING: IMPORT ALL RAW DATASETS
################################################################################

print("Loading raw data...")

# Stock of Vacancies (Barnichon data)
vacancy_raw = pd.read_excel(f"{data_dir}/barnichon/barnichon_vacancy.xlsx")

# Stock of Employed and Unemployed Workers (FRED)
stocks_raw = pd.read_csv(f"{data_dir}/fred/fred_employment.csv")

# JOLTS - Job Openings and Labor Turnover Survey (levels)
jolts_raw = pd.read_csv(f"{data_dir}/jolts/jolts_level.csv")

# JOLTS - Job Openings and Labor Turnover Survey (rates)
jolts_rates_raw = pd.read_csv(f"{data_dir}/jolts/jolts_rates.csv")

# Consumer Price Index (FRED)
cpi_raw = pd.read_csv(f"{data_dir}/fred/CPI.csv")

# Average Wage by Quartile (Atlanta Fed)
wage_raw = pd.read_excel(f"{data_dir}/atl_fed/atl_fed_wage.xlsx", 
                         sheet_name='Average Wage Quartile', 
                         skiprows=2, header=0)

# Federal Reserve Economic Data - Job Finding and Movement Probability (FMP)
fmp_raw = pd.read_csv(f"{data_dir}/fmp/fmp_ee_flow.csv") 

# Unemployment to Employment flows (FRED)
ue_raw = pd.read_csv(f"{data_dir}/fred/UE.csv")

# ADP Pay History Data
adp_raw = pd.read_csv(f"{data_dir}/adp/adp_pay_history.csv")

################################################################################
# FIGURE 1.1, PANEL A (Also used for Figure 6.1, Panel A, B)
# Labor Market Tightness and Unemployment Rate over Time
################################################################################

print("Processing data for Figure 1.1, Panel A and Figure 6.1, Panel A, B...")

# Create working copies of raw data
vacancy = vacancy_raw.copy()
stocks = stocks_raw.copy()
cpi = cpi_raw.copy()
jolts = jolts_raw.copy()

# Process historical vacancy data (Barnichon)
vacancy.columns = ['date', 'V', 'V_rate']  
vacancy = vacancy.iloc[7:].reset_index(drop=True)
vacancy = vacancy.dropna(subset=['date', 'V'])
vacancy = vacancy.drop(['V_rate'], axis=1)
vacancy['V'] = vacancy['V'].astype(float)

# Convert decimal year format to datetime
def decimal_to_datetime(decimal_year):
    """Convert decimal year (e.g., 1951.083) to datetime object"""
    year = int(decimal_year)
    fraction = decimal_year - year
    month = int(round(fraction * 12)) + 1  
    if month > 12:
        year += 1
        month = 1
    return pd.Timestamp(year=year, month=month, day=1)

vacancy['date'] = vacancy['date'].apply(decimal_to_datetime)

# Process employment and unemployment stocks (FRED)
stocks.columns = ['date', 'E', 'U']
stocks = stocks.dropna(subset=['date', 'E', 'U'])
stocks['date'] = pd.to_datetime(stocks['date'])
stocks['U'] = stocks['U'].astype(float)

# Process Consumer Price Index (CPI-U)
cpi = cpi.iloc[10:].reset_index(drop=True)
cpi = cpi.rename(columns={
    'observation_date': 'date', 
    'CPIAUCSL': 'P'
})

# Calculate price change rates
cpi['date'] = pd.to_datetime(cpi['date'])
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_1m_change'] = cpi['P'].pct_change(periods=1) * 100
cpi['P_4m_change'] = cpi['P'].pct_change(periods=4) * 100
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100

# Process JOLTS data
jolts.columns = ['date', 'vacancy_stock', 'tot_quits', 'tot_hires', 'tot_layoffs']
jolts['date'] = pd.to_datetime(jolts['date'])

# Merge datasets in sequence
temp = stocks.merge(cpi, on=['date'], how='inner')
temp2 = temp.merge(jolts, on=['date'], how='outer')
final = temp2.merge(vacancy, on=['date'], how='outer')

# Filter to start from 1951 and fill missing vacancy data
final = final[(final['date'] >= '1951-01-01')]
final['V'] = final['V'].fillna(final['vacancy_stock'])
final['date'] = pd.to_datetime(final['date'])

# Create key labor market variables
final['L'] = final['E'] + final['U']                           # Labor force
final['U_rate'] = (final['U'] / final['L']) * 100              # Unemployment rate
final['V_rate'] = (final['V'] / final['L']) * 100              # Vacancy rate
final['tightness'] = final['V'] / final['U']                   # Labor market tightness
final['ln_tightness'] = np.log(final['V']) - np.log(final['U']) # Log tightness

# Select and save key variables
keep = ['date', 'P_1m_change', 'P_4m_change', 'P_12m_change', 
        'V', 'U', 'U_rate', 'V_rate', 'tightness', 'ln_tightness']
final = final[keep]

# Save processed data for multiple figures
final.to_csv(f"{output_dir}/figure_1_1_A.csv", index=False)
print("Processed data for Figure 1.1, Panel A saved.")

final.to_csv(f"{output_dir}/figure_6_1.csv", index=False)
print("Processed data for Figure 6.1 saved.")


################################################################################
# FIGURE 1.1, PANEL B (Also used for Figure B.6)
# Real Wage Growth by Quartile
################################################################################

print("Processing data for Figure 1.1, Panel B and Figure 2.4, Panel A, B...")

# Create working copies
data = wage_raw.copy()
cpi = cpi_raw.copy()

# Rename wage data columns for clarity
data = data.rename(columns={
    'Unnamed: 0': 'date',
    'Lowest quartile of wage distribution': 'Q1',
    '2nd quartile of wage distribution': 'Q2', 
    '3rd quartile of wage distribution': 'Q3', 
    'Highest quartile of wage distribution': 'Q4'
})

# Process CPI data
cpi = cpi.iloc[10:].reset_index(drop=True)
cpi = cpi.rename(columns={
    'observation_date': 'date', 
    'CPIAUCSL': 'P'
})
cpi['date'] = pd.to_datetime(cpi['date'])
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100

# Merge wage and price data
wage_data = data.merge(cpi, on='date', how='left')
wage_data_copy = wage_data.copy()

# Filter to analysis period (2015-2024) and clean columns
wage_data = wage_data[wage_data['date'] >= '2015-12-01']
wage_data = wage_data[wage_data['date'] <= '2024-12-01']
wage_data = wage_data.drop(['Lowest half of wage distribution', 
                           'Upper half of wage distribution'], axis=1)
wage_data = wage_data.reset_index(drop=True)

# Initialize wage indices
wage_data['wage_index_1'] = 1
wage_data['wage_index_2'] = 1
wage_data['wage_index_3'] = 1
wage_data['wage_index_4'] = 1
wage_data['med_wage_index'] = 1 

# Filter to main analysis period
wage_data = wage_data[wage_data['date'] >= '2016-01-01']

# Calculate monthly growth rates
wage_data['q1_mom_grth'] = 1 + (wage_data['Q1']/100)/12
wage_data['q2_mom_grth'] = 1 + (wage_data['Q2']/100)/12
wage_data['q3_mom_grth'] = 1 + (wage_data['Q3']/100)/12
wage_data['q4_mom_grth'] = 1 + (wage_data['Q4']/100)/12
wage_data['med_mom_grth'] = 1 + (wage_data['Overall']/100)/12
wage_data['P_1m_change'] = 1 + (wage_data['P_12m_change']/100)/12

# Calculate cumulative nominal wage indices
wage_data['nom_wage_index_1'] = wage_data['q1_mom_grth'].cumprod()
wage_data['nom_wage_index_2'] = wage_data['q2_mom_grth'].cumprod()
wage_data['nom_wage_index_3'] = wage_data['q3_mom_grth'].cumprod()
wage_data['nom_wage_index_4'] = wage_data['q4_mom_grth'].cumprod()
wage_data['med_nom_wage_index'] = wage_data['med_mom_grth'].cumprod()
wage_data['price_index'] = wage_data['P_1m_change'].cumprod()

# Fill any missing values
wage_data = wage_data.fillna(1)

# Calculate real wage indices (deflated by price index)
wage_data['real_wage_index_1'] = wage_data['nom_wage_index_1'] / wage_data['price_index']
wage_data['real_wage_index_2'] = wage_data['nom_wage_index_2'] / wage_data['price_index']
wage_data['real_wage_index_3'] = wage_data['nom_wage_index_3'] / wage_data['price_index']
wage_data['real_wage_index_4'] = wage_data['nom_wage_index_4'] / wage_data['price_index']
wage_data['med_real_wage_index'] = wage_data['med_nom_wage_index'] / wage_data['price_index']

# Calculate pre-pandemic trend lines (2016-2019)
start_date = '2016-01-01'
end_date = '2019-12-31'

# Filter data for trend calculation
trend_data = wage_data[(wage_data['date'] >= start_date) & (wage_data['date'] <= end_date)]

# Prepare time variable for linear regression (months since start)
X = ((trend_data['date'].dt.year - trend_data['date'].min().year) * 12 +
     (trend_data['date'].dt.month - trend_data['date'].min().month)).values.reshape(-1, 1)

# Store predicted values for each wage index
predicted_values = {}

# Calculate trend lines for each wage index using linear regression
wage_indices = ['real_wage_index_1', 'real_wage_index_2', 'real_wage_index_3', 
                'real_wage_index_4', 'med_real_wage_index', 'price_index']

for column_name in wage_indices:
    # Fit linear regression model to pre-pandemic trend
    y = trend_data[column_name].values
    model = LinearRegression()
    model.fit(X, y)
    
    # Predict for entire dataset
    all_dates = ((wage_data['date'].dt.year - trend_data['date'].min().year) * 12 +
                 (wage_data['date'].dt.month - trend_data['date'].min().month)).values.reshape(-1, 1)
    predicted_values[column_name] = model.predict(all_dates)

# Add predicted trend lines to DataFrame
for column_name in predicted_values:
    wage_data[f'predicted_{column_name}'] = predicted_values[column_name]

# Select final variables for output
main_vars = ['date', 'price_index', 'predicted_price_index', 
             'med_real_wage_index', 'predicted_med_real_wage_index', 
             'real_wage_index_1', 'predicted_real_wage_index_1', 
             'real_wage_index_2', 'predicted_real_wage_index_2', 
             'real_wage_index_3', 'predicted_real_wage_index_3', 
             'real_wage_index_4', 'predicted_real_wage_index_4']
final = wage_data[main_vars]

# Save processed data
final.to_csv(f"{output_dir}/figure_1_1_B.csv", index=False)
print("Processed data for Figure 1.1, Panel B saved.")

final.to_csv(f"{output_dir}/figure_B_6.csv", index=False)
print("Processed data for Figure B.6, Panel A, B, C, D saved.")


################################################################################
# FIGURE 2.1, PANEL A, B, C
# JOLTS Rates (Layoffs, Quits, Job Openings)
################################################################################

print("Processing data for Figure 2.1, Panel A, B, C...")

# Process JOLTS rates data
df = jolts_rates_raw.copy()
df = df.rename(columns={
    'observation_date': 'date', 
    'JTSLDR': 'layoff_rate_jolts', 
    'JTSQUR': 'quit_rate_jolts', 
    'JTSJOR': 'vacancy_rate_jolts'
})
df['date'] = pd.to_datetime(df['date']) 

# Save processed data
df.to_csv(f"{output_dir}/figure_2_1.csv", index=False) 
print("Processed data for Figure 2.1, Panel A, B, C saved.")


################################################################################
# FIGURE 2.2, PANEL A
# Federal Reserve Economic Data - Job Movement Probability
################################################################################

print("Processing data for Figure 2.2, Panel A...")

# Process FMP (Federal Market Participation) data
df = fmp_raw.copy()
df.rename(columns={"FMPSA3MA": "ee_pol", 'observation_date': 'date'}, inplace=True)
df['date_monthly'] = pd.to_datetime(df['date'])

# Save processed data
df.to_csv(f"{output_dir}/figure_2_2_A.csv", index=False)
print("Processed data for Figure 2.2, Panel A saved.")


################################################################################
# FIGURE 2.2, PANEL B
# Job Finding Rate with Moving Average
################################################################################

print("Processing data for Figure 2.2, Panel B...")

# Create working copies
stocks = stocks_raw.copy()
ue = ue_raw.copy()

# Process employment/unemployment stocks
stocks.columns = ['date', 'E', 'U']
stocks = stocks.iloc[11:].reset_index(drop=True)
stocks = stocks.dropna(subset=['date', 'E', 'U'])
stocks['date'] = pd.to_datetime(stocks['date'])
stocks['U'] = stocks['U'].astype(float)

# Process unemployment to employment flows
ue.columns = ['date', 'ue_flows']
ue['date'] = pd.to_datetime(ue['date'])

# Merge and calculate job finding rate
data = stocks.merge(ue, on=['date'])
data['job_finding_rate'] = data['ue_flows'] / data['U']

# Add 3-month centered moving average
data['job_finding_rate_3ma'] = data['job_finding_rate'].rolling(
    window=3, center=True, min_periods=1).mean()
data['job_finding_rate_3ma'] = data['job_finding_rate_3ma'] * 100

# Select and save relevant columns
output_cols = ['date', 'job_finding_rate', 'job_finding_rate_3ma']
data[output_cols].to_csv(f"{output_dir}/figure_2_2_B.csv", index=False)
print("Processed data for Figure 2.2, Panel B saved.")


################################################################################
# FIGURE 2.3, PANEL A, B
# ADP Wage Growth: Job Stayers vs Job Switchers
################################################################################

print("Processing data for Figure 2.3, Panel A, B...")

# Create working copies
df = adp_raw.copy()
cpi = cpi_raw.copy()

# Process ADP wage data - separate stayers and switchers
temp_stayer = df[df['category'] == 'Job Stayer']
stayer = temp_stayer[['date', 'median pay change']].copy()
stayer = stayer.rename(columns={'median pay change': 'delta_w_stay'})

temp_switcher = df[df['category'] == 'Job Changer']
switcher = temp_switcher[['date', 'median pay change']].copy()
switcher = switcher.rename(columns={'median pay change': 'delta_w_switch'}) 

# Merge stayer and switcher data
data = switcher.merge(stayer, on=['date']) 
data['date'] = pd.to_datetime(data['date'])
data['diff'] = data['delta_w_switch'] - data['delta_w_stay']

# Process CPI data for inflation context
cpi = cpi.iloc[10:].reset_index(drop=True)
cpi = cpi.rename(columns={
    'observation_date': 'date', 
    'CPIAUCSL': 'P'
})
cpi['date'] = pd.to_datetime(cpi['date'])
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100

# Merge wage and price data
data = data.merge(cpi, on=['date'])

# Save processed data
data.to_csv(f"{output_dir}/figure_2_3.csv", index=False) 
print("Processed data for Figure 2.3, Panel A, B saved.")


################################################################################
# FIGURE 2.4, PANEL A, B, C
# Work-from-Home Analysis: Wage Growth by WFH Status
################################################################################

print("Processing data for Figure 2.4, Panel A, B, C...")

# Load pre-processed temporary files (created by other scripts)
df = pd.read_csv(f"{output_dir}/figure_2_4_temp1.csv")
df_pol = pd.read_csv(f"{output_dir}/figure_2_4_temp2.csv")
cpi = cpi_raw.copy()

# Merge the temporary datasets
df = df.merge(df_pol, on='date_monthly')

# Convert date format from '2016m1' to datetime
df['date'] = pd.to_datetime(
    df['date_monthly'].str.extract(r'(\d{4})m(\d{1,2})')
    .apply(lambda x: f"{x[0]}-{int(x[1]):02d}", axis=1)
)

# Process CPI data
cpi['date'] = pd.to_datetime(cpi['observation_date'])
cpi = cpi.rename(columns={'CPIAUCSL': 'P'})
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100
cpi['P_1m_change'] = 1 + (cpi['P_12m_change'] / 100) / 12
cpi = cpi[['date', 'P_1m_change']]

# Merge CPI with wage growth data
df = df.merge(cpi, on='date', how='left')
    
# Calculate monthly wage growth factors for all wage columns
wage_columns = [col for col in df.columns if col.startswith('smwg')]
for col in wage_columns:
    df[f'{col}_mom_grth'] = 1 + (df[col] / 100) / 12

# Calculate cumulative nominal wage indices
for col in wage_columns:
    df[f'nom_index_{col}'] = df[f'{col}_mom_grth'].cumprod()

# Calculate cumulative price index
df['price_index'] = df['P_1m_change'].cumprod()

# Calculate real wage indices (deflated by price index)
for col in wage_columns:
    df[f'real_index_{col}'] = df[f'nom_index_{col}'] / df['price_index']

# Select final columns for output
result_cols = ['date', 'price_index'] + [f'real_index_{col}' for col in wage_columns]
result_df = df[result_cols]

# Calculate pre-pandemic trend lines (2016-2019)
start_date = pd.to_datetime("2016-01-01")
end_date = pd.to_datetime("2019-12-31")

# Filter data for trend calculation
trend_df = df[(df['date'] >= start_date) & (df['date'] <= end_date)]

# Prepare time variables for linear regression
X_trend = ((trend_df['date'].dt.year - trend_df['date'].min().year) * 12 +
           (trend_df['date'].dt.month - trend_df['date'].min().month)).values.reshape(-1, 1)
X_all = ((df['date'].dt.year - trend_df['date'].min().year) * 12 +
         (df['date'].dt.month - trend_df['date'].min().month)).values.reshape(-1, 1)

# Identify real wage index columns for trend calculation
real_index_cols = [col for col in df.columns if col.startswith('real_index_')]

# Calculate trend lines for each real wage index
predicted = {}
for col in real_index_cols + ['price_index']:
    y = trend_df[col].values
    model = LinearRegression()
    model.fit(X_trend, y)
    predicted[col] = model.predict(X_all)
    df[f'predicted_{col}'] = predicted[col]

# Calculate gaps between actual and predicted values
gaps = {
    col: df[f'predicted_{col}'].iloc[-1] - df[col].iloc[-1]
    for col in real_index_cols + ['price_index']
}

# Define column mappings for different demographic groups
gap_columns = {
    'WFH_1st_Quartile': ('real_index_smwg1st_high_wfh', 'predicted_real_index_smwg1st_high_wfh'),
    'No_WFH_1st_Quartile': ('real_index_smwg1st_no_wfh', 'predicted_real_index_smwg1st_no_wfh'),
    'WFH_4th_Quartile': ('real_index_smwg4th_high_wfh', 'predicted_real_index_smwg4th_high_wfh'),
    'No_WFH_4th_Quartile': ('real_index_smwg4th_no_wfh', 'predicted_real_index_smwg4th_no_wfh'),
    'WFH_Pooled': ('real_index_smwghigh_wfh', 'predicted_real_index_smwghigh_wfh'),
    'No_WFH_Pooled': ('real_index_smwgno_wfh', 'predicted_real_index_smwgno_wfh')
}

# Filter data from January 2020 onward for gap analysis
plot_start_date = pd.to_datetime("2020-01-01")
mask = df['date'] >= plot_start_date
df_filtered = df.loc[mask].copy()

# Initialize output DataFrame with date column
gap_df = df_filtered[['date']].copy()

# Calculate gaps from trend for each demographic group
for label, (actual_col, trend_col) in gap_columns.items():
    gap = (df_filtered[actual_col] - df_filtered[trend_col]) * 100
    gap.iloc[0] = 0  # Normalize gap to 0 at 2020-01
    gap_df[label] = gap.values

# Save processed data
gap_df.to_csv(f"{output_dir}/figure_2_4.csv", index=False)
print("Processed data for Figure 2.4, Panel A, B, C saved.")
