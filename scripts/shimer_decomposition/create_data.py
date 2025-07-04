# Yash Singh 
# date: 11/11/2024 
# this script creates processed data file which includes the 

import numpy as np 
import pandas as pd 

# Specify directories 
data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"

stocks = pd.read_csv(f"{data_dir}/fred_employment/employment_v2.csv")

# Basic Processing of stocks 
stocks.columns = ['date', 'E', 'U']
stocks = stocks.iloc[11:].reset_index(drop=True)
stocks = stocks.dropna(subset=['date', 'E', 'U'])
stocks['date'] = pd.to_datetime(stocks['date'])
stocks['U'] = stocks['U'].astype(float)


eu = pd.read_csv(f"{data_dir}/fred_flows/EU.csv")
ue = pd.read_csv(f"{data_dir}/fred_flows/UE.csv")

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


final.to_csv(f"{output_dir}/data/shimer_decomposition_data.csv", index=False)

