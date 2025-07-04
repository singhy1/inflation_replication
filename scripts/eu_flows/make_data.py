# Yash Singh 


# Yash Singh 
# date: 11/11/2024 
# this script creates processed data that will be used to make ue plot 

# Necessary Packages 

import numpy as np 
import pandas as pd 

# Specify directories 
data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"

# Stock of Employed and Unemployed Workers 
#stocks = pd.read_excel(f"{data_dir}/fred_employment/employment.xls", engine='xlrd')

stocks = pd.read_csv(f"{data_dir}/fred_employment/employment_v2.csv")

# Basic Processing of stocks 
stocks.columns = ['date', 'E', 'U']
stocks = stocks.iloc[11:].reset_index(drop=True)
stocks = stocks.dropna(subset=['date', 'E', 'U'])
stocks['date'] = pd.to_datetime(stocks['date'])
stocks['U'] = stocks['U'].astype(float)

ue = pd.read_csv(f"{data_dir}/fred_flows/UE.csv")
ue.columns = ['date', 'ue_flows']
ue['date'] = pd.to_datetime(ue['date'])

data= stocks.merge(ue, on = ['date'])
data['job_finding_rate'] = data['ue_flows'] / data['U']

keep = ['date', 'job_finding_rate']
data = data[keep]

# Create 'date_quarterly' column
data["date_quarterly"] = data["date"].dt.to_period("Q").dt.start_time


# Collapse to quarterly level by averaging 'ee_pol'
df_quarterly = data.groupby("date_quarterly", as_index=False)["job_finding_rate"].mean()


keep = ['date_quarterly', 'job_finding_rate']
df_quarterly = df_quarterly[keep] 
df_quarterly['job_finding_rate'] = df_quarterly['job_finding_rate'] * 100 


df_quarterly.to_csv(f"{output_dir}/data/ue_flows.csv", index=False)

# Yash Singh 
# date: 11/11/2024 
# this script creates processed data with 3-month moving average

# Necessary Packages 
import pandas as pd 

# Specify directories 
data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"

# Load and process data
stocks = pd.read_csv(f"{data_dir}/fred_employment/employment_v2.csv")
stocks.columns = ['date', 'E', 'U']
stocks = stocks.iloc[11:].reset_index(drop=True)
stocks = stocks.dropna(subset=['date', 'E', 'U'])
stocks['date'] = pd.to_datetime(stocks['date'])
stocks['U'] = stocks['U'].astype(float)

ue = pd.read_csv(f"{data_dir}/fred_flows/EU.csv")
ue.columns = ['date', 'eu_flows']
ue['date'] = pd.to_datetime(ue['date'])

# Merge and calculate job finding rate
data = stocks.merge(ue, on=['date'])
data['eu_rate'] = (data['eu_flows'] / data['E'])* 100


# Keep and save relevant columns
output_cols = ['date', 'eu_rate']
data[output_cols].to_csv(f"{output_dir}/data/eu_rate.csv", index=False)