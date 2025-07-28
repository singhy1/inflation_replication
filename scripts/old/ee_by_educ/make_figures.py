import numpy as np 
import pandas as pd 
import matplotlib.pyplot as plt


# Specify directories 
data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"
temp_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/temp"


ee_flows = pd.read_csv(f"{data_dir}/LEHD/flows_by_education.csv")
employment = pd.read_csv(f"{data_dir}/LEHD/employment_by_education.csv")

# First, re-import and clean to start from raw data
ee_clean = ee_flows[['year', 'quarter', 'education', 'EE', 'EES', 'J2J', 'J2JS']]

ee_clean['EE'] = pd.to_numeric(ee_clean['EE'], errors='coerce')
ee_clean['EES'] = pd.to_numeric(ee_clean['EES'], errors='coerce')
ee_clean['J2J'] = pd.to_numeric(ee_clean['J2J'], errors='coerce')
ee_clean['J2JS'] = pd.to_numeric(ee_clean['J2JS'], errors='coerce')


emp_clean = employment[['year', 'quarter', 'education', 'Emp']]
emp_clean['Emp'] = pd.to_numeric(emp_clean['Emp'], errors='coerce')

# Merge
merged = pd.merge(ee_clean, emp_clean, on=['year', 'quarter', 'education'])

merged['date'] = pd.to_datetime(merged['year'].astype(str) + 'Q' + merged['quarter'].astype(str))

# Compute merged EE rate and convert to %
merged['ee_rate'] = 100 * merged['EE'] / merged['Emp']
merged['ee_rate_stable'] = 100 * merged['EES'] / merged['Emp']
merged['j2j_rate'] = 100 * merged['J2J'] / merged['Emp']
merged['j2j_rate_stable'] = 100 * merged['J2JS'] / merged['Emp']

# Already pivoted data: pivot_df
pivot_df = merged.pivot(index='date', columns='education', values='j2j_rate')

# Define periods
pivot_df['inf_period'] = ((pivot_df.index >= '2021-04-01') & (pivot_df.index <= '2023-05-01')).astype(int)
pivot_df['pre_period'] = (pivot_df.index <= '2019-12-01').astype(int)

# Resample to quarterly averages (calendar quarters)
pivot_quarterly = pivot_df.resample('Q').mean()

# Redefine period flags after resampling
pivot_quarterly['inf_period'] = ((pivot_quarterly.index >= '2021-04-01') & (pivot_quarterly.index <= '2023-05-01')).astype(int)
pivot_quarterly['pre_period'] = (pivot_quarterly.index <= '2019-12-01').astype(int)


# Loop over each education group
for edu_group in ['E2', 'E4']:
    
    pre_dates = pivot_quarterly.loc[pivot_quarterly['pre_period'] == 1].index
    inf_dates = pivot_quarterly.loc[pivot_quarterly['inf_period'] == 1].index
    
    avg_pre = pivot_quarterly.loc[pivot_quarterly['pre_period'] == 1, edu_group].mean()
    print("pre", avg_pre)
    avg_inf = pivot_quarterly.loc[pivot_quarterly['inf_period'] == 1, edu_group].mean()
    print("inflation", avg_inf)
    
    plt.figure(figsize=(8, 4))
    plt.plot(pivot_quarterly.index, pivot_quarterly[edu_group], marker='o', linewidth=2)
    plt.hlines(avg_pre, xmin=pre_dates.min(), xmax=pre_dates.max(), color='red', linestyle='--', linewidth=2)
    plt.hlines(avg_inf, xmin=inf_dates.min(), xmax=inf_dates.max(), color='red', linestyle='--', linewidth=2)
    plt.gca().spines['top'].set_visible(False)
    plt.gca().spines['right'].set_visible(False)
    plt.xticks(fontsize=16)
    plt.yticks(fontsize=16)
    plt.ylim(2,7)
    plt.tight_layout()
    
    # Save figure as PDF
    plt.savefig(f"{output_dir}/figures/{edu_group}_ee_rate_plot.pdf")
    plt.close()
