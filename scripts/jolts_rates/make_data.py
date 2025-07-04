import pandas as pd 
import numpy as np

data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"
df = pd.read_csv(f"{data_dir}/JOLTS/jolts_rates_v2.csv")

df = df.rename(columns={
                            'observation_date': 'date', 
                            'JTSLDR':               'layoff_rate_jolts', 
                            'JTSQUR': 'quit_rate_jolts', 
                            'JTSJOR': 'vacancy_rate_jolts', 
})

df['date'] = pd.to_datetime(df['date']) 

df.to_csv(f"{output_dir}/data/jolts_rates.csv", index = False) 

