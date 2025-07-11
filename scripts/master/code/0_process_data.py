######################################################################
# Date Created: 7/10/2025
# Last Modified: 7/10/2025
# This Code:
# - takes the raw data from /master/data/raw
# - processes it to create Dataframes for making all figures in the main text
# - (see /code/1_make_figures.jl)
######################################################################

import numpy as np 
import pandas as pd 
import os
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
import warnings
warnings.filterwarnings("ignore")

# Set directories (Set your own global path)
global_dir = "/Users/giyoung/Downloads/inflation_replication/scripts/master/"
data_dir = os.path.join(global_dir, "data/raw")
output_dir = os.path.join(global_dir, "data/processed")

# import helper module
from helper import *

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
# Figure 1.1, Panel A 
######################################################################
print("Processing data for Figure 1.1, Panel A...")

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


######################################################################
# Figure 1.1, Panel B
######################################################################
print("Processing data for Figure 1.1, Panel B...")

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
