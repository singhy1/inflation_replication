######################################################################
# Date Created: 7/10/2025
# Last Modified: 7/11/2025
# This Code:
# - takes the raw data from /master/data/raw
# - processes it to create Dataframes for making all figures
# - in the main text.
######################################################################

import numpy as np 
import pandas as pd 
import os
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
import statsmodels.api as sm
import warnings
from collections import defaultdict
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
# Consumer Price Index
cpi_raw = pd.read_csv(f"{data_dir}/fred/CPI.csv")
# Average Wage Quartile
wage_raw = pd.read_excel(f"{data_dir}/atl_fed/atl_fed_wage.xlsx", sheet_name = 'Average Wage Quartile', skiprows=2, header=0)
# FMP
fmp_raw = pd.read_csv(f"{data_dir}/fmp/fmp_ee_flow.csv") 
# U-E
ue_raw = pd.read_csv(f"{data_dir}/fred/UE.csv")
# ADP
adp_raw = pd.read_csv(f"{data_dir}/adp/adp_pay_history.csv")

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
vacancy = vacancy.iloc[7:].reset_index(drop=True)
vacancy = vacancy.dropna(subset=['date', 'V'])
vacancy = vacancy.drop(['V_rate'], axis = 1)
vacancy['V'] = vacancy['V'].astype(float)

# Convert decimal year to datetime
def decimal_to_datetime(decimal_year):
    year = int(decimal_year)
    fraction = decimal_year - year
    month = int(round(fraction * 12)) + 1  # Adjusting based on your clarification
    if month > 12:
        year += 1
        month = 1
    return pd.Timestamp(year=year, month=month, day=1)

vacancy['date'] = vacancy['date'].apply(decimal_to_datetime)

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
# Figure 1.1, Panel B (Same data for Figure 2.4, Panel A, B and 
# Figure B.6, Panel A, B)
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
final.to_csv(f"{output_dir}/figure_B_6.csv", index = False)
print("Processed data for Figure B.6, Panel A, B saved.")


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
# Figure 2.5, Panel A, B, C
######################################################################
print("Processing data for Figure 2.5, Panel A, B, C...")

df = pd.read_csv(f"{output_dir}/figure_2_5_temp1.csv")
df_pol = pd.read_csv(f"{output_dir}/figure_2_5_temp2.csv")
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
    'WFH_1st_Quartile': ('real_index_smwg1st_high_wfh', 'predicted_real_index_smwg1st_high_wfh'),
    'No_WFH_1st_Quartile': ('real_index_smwg1st_no_wfh', 'predicted_real_index_smwg1st_no_wfh'),
    'WFH_4th_Quartile': ('real_index_smwg4th_high_wfh', 'predicted_real_index_smwg4th_high_wfh'),
    'No_WFH_4th_Quartile': ('real_index_smwg4th_no_wfh', 'predicted_real_index_smwg4th_no_wfh'),
    'WFH_Pooled': ('real_index_smwghigh_wfh', 'predicted_real_index_smwghigh_wfh'),
    'No_WFH_Pooled': ('real_index_smwgno_wfh', 'predicted_real_index_smwgno_wfh')
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

gap_df.to_csv(f"{output_dir}/figure_2_5.csv", index= False)
print("Processed data for Figure 2.5, Panel A, B, C saved.")



######################################################################
# Figure 6.1, Panel A
######################################################################
# See Section for Figure 1.1, Panel A for data processing

######################################################################
# Figure 6.1, Panel B 
######################################################################
# See Section for Figure 1.1, Panel A for data processing

