# Yash Singh 
# 11/22/24 
# this script takes data from Philly Fed and does some processing. This script will generate cleaned files that will be used to make plots. 

import pandas as pd

# Define directories
data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"

# Load FMP data

#df = pd.read_excel(f"{data_dir}/FMP/ee_fmp.xlsx", sheet_name="Data")
df = pd.read_csv(f"{data_dir}/FMP/EE.csv") 

# Rename column
df.rename(columns={"FMPNSA3MA": "ee_pol", 'observation_date': 'date'}, inplace=True)

# Create 'date_monthly' column
#df["date_monthly"] = pd.to_datetime(df[["year", "month"]].assign(day=1))
df['date_monthly'] = pd.to_datetime(df['date'])

# Keep only relevant columns
df = df[["date_monthly", "ee_pol"]]


# save monthly data 
df.to_csv(f"{output_dir}/data/ee_monthly.csv", index = False )

# Create 'date_quarterly' column
df["date_quarterly"] = df["date_monthly"].dt.to_period("Q").dt.start_time


# Collapse to quarterly level by averaging 'ee_pol'
df_quarterly = df.groupby("date_quarterly", as_index=False)["ee_pol"].mean()


df_quarterly.to_csv(f"{output_dir}/data/ee_quarterly.csv", index=False)
