# Yash Singh 
# Date: 11/12/24 
# this data creates our dataset of monthly flows of hires, layoffs, and the end of month stock of vacancies. 

import numpy as np 
import pandas as pd 

# Specify directories 
data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"
 
# jolts 
jolts = pd.read_csv(f"{data_dir}/JOLTS/jolts_level_v3.csv")

# JOLTS 
jolts.columns = ['date', 'vacancy_stock', 'tot_quits','tot_hires', 'tot_layoffs']
jolts = jolts.iloc[13:].reset_index(drop=True)
jolts['date'] = pd.to_datetime(jolts['date'])


stocks = pd.read_csv(f"{data_dir}/fred_employment/employment_v2.csv")

# Basic Processing of stocks 
stocks.columns = ['date', 'E', 'U']
stocks = stocks.iloc[11:].reset_index(drop=True)
stocks = stocks.dropna(subset=['date', 'E', 'U'])
stocks['date'] = pd.to_datetime(stocks['date'])
stocks['U'] = stocks['U'].astype(float)


final = stocks.merge(jolts, on = ['date'])

keep = ['date', 'E', 'U', 'vacancy_stock', 'tot_hires', 'tot_layoffs']
final = final[keep]



final.to_csv(f"{output_dir}/data/dfh_estimation.csv", index=False)

