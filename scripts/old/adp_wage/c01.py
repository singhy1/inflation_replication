# Yash Singh 
# make data for adp wage series 

import numpy as np 
import pandas as pd

data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"


# two datasets - ADP wage data and Consumer Price Index 
df = pd.read_csv(f"{data_dir}/adp/ADP_PAY_history.csv")
cpi = pd.read_csv(f"{data_dir}/CPI/CPIAUCSL.csv")

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

data.to_csv(f"{output_dir}/data/adp_wage_v2.csv", index = False ) 