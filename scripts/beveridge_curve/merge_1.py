# Yash Singh 
# Date Created: 9/6/24 
# Date Updated: 2/5/25 

# Update Notes: the only update was to the datetime function (see the version in archive for the previous version)

# goal: this script generates our historical data set used later for further analysis 
# the raw data consists of stock of vacancies, employed, unemployed workers, and the price index 

####################################
# 1) vacacy rate: V / E + U 
# 2) unemployment rate: U / E + U 
# 3) inflation (12 month change)
#######################################

# Specify directories 
data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"


# Necessary Packages 

import numpy as np 
import pandas as pd 

########################################################################################
# Necessary Raw Data Sets 

# Stock of Vacancies 
vacancy = pd.read_excel(f"{data_dir}/barnichon/CompositeHWI.xlsx")

# Stock of Employed and Unemployed Workers 
#stocks = pd.read_excel(f"{data_dir}/fred_employment/employment.xls", engine='xlrd')
stocks = pd.read_csv(f"{data_dir}/fred_employment/employment_v2.csv")

# jolts 
#jolts = pd.read_excel(f"{data_dir}/JOLTS/jolts_level.xls", engine='xlrd')

jolts = pd.read_csv(f"{data_dir}/JOLTS/jolts_level_v3.csv")

# Consumer Price Index 
#cpi = pd.read_excel(f"{data_dir}/CPI/CPIAUCSL.xls", engine='xlrd')

cpi = pd.read_csv(f"{data_dir}/CPI/CPIAUCSL.csv")

# Basic Processing of historical vacancies 
vacancy.columns = ['date', 'V', 'V_rate']  
vacancy = vacancy.iloc[8:].reset_index(drop=True)
vacancy = vacancy.dropna(subset=['date', 'V'])
vacancy = vacancy.drop(['V_rate'], axis = 1)
vacancy['V'] = vacancy['V'].astype(float)
# Define the mapping function with increased tolerance
def map_to_month(decimal_date):
    fraction = decimal_date - int(decimal_date)
    #print("decimal_date", decimal_date)
    #print("integer decimal_date", int(decimal_date))
    #print('fraction', fraction)
    
    # Define exact mappings with slightly higher tolerance
    if np.isclose(fraction, 1, atol=0.02):
        month = 1  # January
    elif np.isclose(fraction, 0.08, atol=0.02):
        month = 2  # February
    elif np.isclose(fraction, 0.17, atol=0.02):
        month = 3  # March
    elif np.isclose(fraction, 0.25, atol=0.02):
        month = 4  # April
    elif np.isclose(fraction, 0.33, atol=0.02):
        month = 5  # May
    elif np.isclose(fraction, 0.42, atol=0.02):
        month = 6  # June
    elif np.isclose(fraction, 0.50, atol=0.02):
        month = 7  # July
    elif np.isclose(fraction, 0.58, atol=0.02):
        month = 8  # August
    elif np.isclose(fraction, 0.67, atol=0.02):
        month = 9  # September
    elif np.isclose(fraction, 0.75, atol=0.02):
        month = 10  # October
    elif np.isclose(fraction, 0.83, atol=0.02):
        month = 11  # November
    elif np.isclose(fraction, 0.92, atol=0.02):
        month = 12  # December
    else:
        raise ValueError(f"Fraction {fraction} does not match any month")
    
    return month

# Define the conversion function
def convert_to_datetime(decimal_date):
    decimal_date = float(decimal_date)
    year = int(decimal_date)
    month = map_to_month(decimal_date)
    return pd.Timestamp(year=year, month=month, day=1)

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

final.to_csv(f"{output_dir}/data/historical_data_feb.csv", index=False)
