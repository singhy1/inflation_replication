######################################################################
# Date Created: 7/11/2025
# Last Modified: 7/13/2025
# This Code:
# - takes the processed data from /master/data/processed
# - makes figures for the appendix, except for Figure B.6 and Figure B.8
# - creates Table B.4
# - creates Figure 6.1, Panel B and Table 4
######################################################################

import numpy as np 
import pandas as pd 
import os
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
import statsmodels.api as sm
import warnings
warnings.filterwarnings("ignore")

# Set directories (Set your own global path)
global_dir = "/Users/giyoung/Downloads/inflation_replication/scripts/master/"
data_dir = os.path.join(global_dir, "data/processed")
figures_dir = os.path.join(global_dir, "output/figures")
table_dir = os.path.join(global_dir, "output/tables")

######################################################################
# Figure B.1, Panel A
######################################################################
print("Making figure for Figure B.1, Panel A...")

df = pd.read_csv(f"{data_dir}/figure_B_1.csv")

# Plot settings
plt.rcParams.update({'font.size': 16})

# Panel A: Quit Rate vs. Inflation
plt.figure(figsize=(7, 5))
plt.scatter(df['P_12m_change'], df['quit_rate_jolts'], color='blue', alpha=0.7)
plt.plot(df['P_12m_change'], df['quit_rate_jolts'], color='blue', alpha=0.5)
plt.xlabel('Annual Inflation Rate (%)', fontsize=18)
plt.ylabel('Monthly Quit Rate (%)', fontsize=18)
plt.ylim(0, 3.5)
plt.xticks(fontsize=16)
plt.yticks(fontsize=16)
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.tight_layout()
plt.savefig(f"{figures_dir}/figure_B_1_A.pdf")
plt.close()
print("Figure B.1, Panel A processed and saved.")

######################################################################
# Figure B.1, Panel B
######################################################################
print("Making figure for Figure B.1, Panel B...")

plt.figure(figsize=(7, 5))
plt.scatter(df['P_12m_change'], df['vacancy_rate_jolts'], color='blue', alpha=0.7)
plt.plot(df['P_12m_change'], df['vacancy_rate_jolts'], color='blue', alpha=0.5)
plt.xlabel('Annual Inflation Rate (%)', fontsize=18)
plt.ylabel('Monthly Vacancy Rate (%)', fontsize=18)
plt.ylim(0, 8)
plt.xticks(fontsize=16)
plt.yticks(fontsize=16)
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.tight_layout()
plt.savefig(f"{figures_dir}/figure_B_1_B.pdf")
plt.close()
print("Figure B.1, Panel B processed and saved.")

######################################################################
# Figure B.2, Panel A
######################################################################
print("Making figure for Figure B.2, Panel A...")

plot_data = pd.read_csv(f"{data_dir}/figure_B_2.csv")
plot_data['date'] = pd.to_datetime(plot_data['date'])

# Define date ranges
pre_dates = plot_data.loc[plot_data['pre_period'] == 1, 'date']
inf_dates = plot_data.loc[plot_data['inf_period'] == 1, 'date']

# Compute averages
avg_eu_pre = plot_data.loc[plot_data['pre_period'] == 1, 'eu_rate'].mean()
avg_eu_inf = plot_data.loc[plot_data['inf_period'] == 1, 'eu_rate'].mean()

avg_u_pre = plot_data.loc[plot_data['pre_period'] == 1, 'u_rate'].mean()
avg_u_inf = plot_data.loc[plot_data['inf_period'] == 1, 'u_rate'].mean()

avg_emp_pre = plot_data.loc[plot_data['pre_period'] == 1, 'emp2pop'].mean()
avg_emp_inf = plot_data.loc[plot_data['inf_period'] == 1, 'emp2pop'].mean()

plt.figure(figsize=(8, 4))
plt.plot(plot_data['date'], plot_data['emp2pop'], linewidth=3)
plt.hlines(avg_emp_pre, xmin=pre_dates.min(), xmax=pre_dates.max(), color='red', linestyle='--', linewidth=2)
plt.hlines(avg_emp_inf, xmin=inf_dates.min(), xmax=inf_dates.max(), color='red', linestyle='--', linewidth=2)
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.xticks(fontsize=16)
plt.yticks(fontsize=16)
plt.ylim(65,75)
plt.savefig(f"{figures_dir}/figure_B_2_A.pdf")
plt.close()
print("Figure B.2, Panel A processed and saved.")

######################################################################
# Figure B.2, Panel B
######################################################################
print("Making figure for Figure B.2, Panel B...")

plt.figure(figsize=(8, 4))
plt.plot(plot_data['date'], plot_data['u_rate'], linewidth=3)
plt.hlines(avg_u_pre, xmin=pre_dates.min(), xmax=pre_dates.max(), color='red', linestyle='--', linewidth=2)
plt.hlines(avg_u_inf, xmin=inf_dates.min(), xmax=inf_dates.max(), color='red', linestyle='--', linewidth=2)
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.xticks(fontsize=16)
plt.yticks(fontsize=16)
plt.ylim(2,7)
plt.savefig(f"{figures_dir}/figure_B_2_B.pdf")
plt.close()
print("Figure B.2, Panel B processed and saved.")

######################################################################
# Figure B.2, Panel C
######################################################################
print("Making figure for Figure B.2, Panel C...")

plt.figure(figsize=(8, 4))
plt.plot(plot_data['date'], plot_data['eu_rate'], linewidth=3)
plt.hlines(avg_eu_pre, xmin=pre_dates.min(), xmax=pre_dates.max(), color='red', linestyle='--', linewidth=2)
plt.hlines(avg_eu_inf, xmin=inf_dates.min(), xmax=inf_dates.max(), color='red', linestyle='--', linewidth=2)
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.xticks(fontsize=16)
plt.yticks(fontsize=16)
plt.ylim(.5,1.5)
plt.savefig(f"{figures_dir}/figure_B_2_C.pdf")
plt.close()
print("Figure B.2, Panel C processed and saved.")

######################################################################
# Figure B.3, Panel A
######################################################################
print("Making figure for Figure B.3, Panel A...")

plot_data = pd.read_csv(f"{data_dir}/figure_B_3.csv")
plot_data['date'] = pd.to_datetime(plot_data['date'])

# Define date ranges
pre_dates = plot_data.loc[plot_data['pre_period'] == 1, 'date']
inf_dates = plot_data.loc[plot_data['inf_period'] == 1, 'date']

# Compute averages
avg_ne_pre = plot_data.loc[plot_data['pre_period'] == 1, 'NE'].mean()
avg_ne_inf = plot_data.loc[plot_data['inf_period'] == 1, 'NE'].mean()

avg_nu_pre = plot_data.loc[plot_data['pre_period'] == 1, 'NU'].mean()
avg_nu_inf = plot_data.loc[plot_data['inf_period'] == 1, 'NU'].mean()

# Plot NU
plt.figure(figsize=(8, 4))
plt.plot(plot_data['date'], plot_data['NU'], linewidth=3)
plt.hlines(avg_nu_pre, xmin=pre_dates.min(), xmax=pre_dates.max(), color='red', linestyle='--', linewidth=2)
plt.hlines(avg_nu_inf, xmin=inf_dates.min(), xmax=inf_dates.max(), color='red', linestyle='--', linewidth=2)
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.xticks(fontsize=16)
plt.yticks(fontsize=16)
plt.ylim(0, 3)  # adjust as needed
plt.savefig(f"{figures_dir}/figure_B_3_A.pdf")
print("Figure B.3, Panel A processed and saved.")

######################################################################
# Figure B.3, Panel B
######################################################################
print("Making figure for Figure B.3, Panel B...")

plt.figure(figsize=(8, 4))
plt.plot(plot_data['date'], plot_data['NE'], linewidth=3)
plt.hlines(avg_ne_pre, xmin=pre_dates.min(), xmax=pre_dates.max(), color='red', linestyle='--', linewidth=2)
plt.hlines(avg_ne_inf, xmin=inf_dates.min(), xmax=inf_dates.max(), color='red', linestyle='--', linewidth=2)
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.xticks(fontsize=16)
plt.yticks(fontsize=16)
plt.ylim(3, 6)  # adjust as needed
plt.savefig(f"{figures_dir}/figure_B_3_B.pdf")
plt.close()
print("Figure B.3, Panel B processed and saved.")

######################################################################
# Figure B.4
######################################################################
print("Making figure for Figure B.4...")

plt.rcParams.update({
    'font.size': 14,             # Set default font size
    'axes.titlesize': 24,        # Title font size
    'axes.labelsize': 20,        # Axis labels font size
    'legend.fontsize': 12,       # Legend font size
    'xtick.labelsize': 16,       # X-axis tick labels
    'ytick.labelsize': 16,       # Y-axis tick labels
    'legend.frameon': False,     # Remove legend box
    'axes.spines.top': False,    # Remove top spine
    'axes.spines.right': False,  # Remove right spine
})

# read data 
data = pd.read_csv(f"{data_dir}/figure_B_4.csv")

data['date'] = pd.to_datetime(data['date'])

# Create quarterly series by avering the monthly data 
data = data.drop(columns=['date']).groupby(data['date'].dt.to_period('Q')).mean().reset_index()
data['date'] = data['date'].dt.to_timestamp()

# Key Estimates 
# implied steady state unemployment rate 
data['u_rate_est'] = data['seperation_rate'] / (data['seperation_rate'] + data['job_finding_rate'] ) * 100
# contribution of job finding 
data['u_rate_job_finding'] = (np.mean(data['seperation_rate']) / (np.mean(data['seperation_rate']) + data['job_finding_rate']))* 100
# contribution of job destruction 
data['u_rate_job_destruction'] = (data['seperation_rate'] / (data['seperation_rate'] + np.mean(data['job_finding_rate']))) * 100
# Pick period to be plotted 
data_post = data[data['date'] >= '2021-01-01']

# Create the plot 
plt.figure(figsize=(12, 6)) 

# Plot both lines
plt.plot(data_post['date'], data_post['u_rate_est'], label='Steady-State Unemployment Rate', color='black')
plt.plot(data_post['date'], data_post['u_rate_job_finding'], label='Contribution of Job Finding', color='red')
plt.plot(data_post['date'], data_post['u_rate_job_destruction'], label='Contribution of Job Destruction', color='blue')
    
# Customize the plot
plt.ylabel('Unemployment Rate')
plt.legend()
plt.ylim(2.5, 6)
plt.savefig(f"{figures_dir}/figure_B_4.pdf", bbox_inches='tight')
plt.rcdefaults()  # Reset to default settings after plotting

print("Figure B.4 processed and saved.")

######################################################################
# Figure B.5, Panel A
######################################################################
print("Making figure for Figure B.5...")

filtered_df = pd.read_csv(f"{data_dir}/figure_B_5_A.csv")
filtered_df['date'] = pd.to_datetime(filtered_df['Unnamed: 0'])
filtered_df.set_index("date", inplace=True)

plt.figure(figsize=(10, 6))

# Plot the data with thicker lines for a more professional look
plt.plot(filtered_df.index, filtered_df["Job Switcher"], label="Job Switcher", linewidth=3)
plt.plot(filtered_df.index, filtered_df["Job Stayer"], label="Job Stayer", linewidth=3)
plt.ylim(0, 10)

# Disable the legend frame for a cleaner appearance and increase legend font size
plt.legend(fontsize=18, frameon=False, loc = 'upper left')

# Customize the axes: remove the top and right spines and increase tick label sizes for readability
ax = plt.gca()
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
ax.tick_params(axis="both", which="major", labelsize=18)

plt.tight_layout()
plt.savefig(f"{figures_dir}/figure_B_5_A.pdf")
#plt.show()
print("Figure B.5, Panel A processed and saved.")

######################################################################
# Figure B.5, Panel B
######################################################################
print("Making figure for Figure B.5, Panel B...")

# Load the reshaped data
df = pd.read_csv(f"{data_dir}/figure_B_5_B_C.csv")

# Convert date column to datetime
df["date_monthly"] = pd.to_datetime(df["date_monthly"], format="%YM%m")

# Filter to match date range of main plot
df = df[(df["date_monthly"] >= "2016-01-01") & (df["date_monthly"] <= "2024-12-31")]

# === Quartile 1 ===
plt.figure(figsize=(10, 6))
plt.plot(df["date_monthly"], df["smwg1st_Job_Switcher"], label="Job Switcher", linewidth=3)
plt.plot(df["date_monthly"], df["smwg1st_Job_Stayer"], label="Job Stayer", linewidth=3)
plt.ylim(0, 10)
plt.legend(fontsize=18, frameon=False, loc = "upper left")

# Clean axis aesthetics
ax = plt.gca()
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
ax.tick_params(axis="both", which="major", labelsize=18)

plt.tight_layout()
plt.savefig(f"{figures_dir}/figure_B_5_B.pdf")
#plt.show()
print("Figure B.5, Panel B processed and saved.")

#######################################################################
# Figure B.5, Panel C
#######################################################################
print("Making figure for Figure B.5, Panel C...")

plt.figure(figsize=(10, 6))
plt.plot(df["date_monthly"], df["smwg4th_Job_Switcher"], label="Job Switcher", linewidth=3)
plt.plot(df["date_monthly"], df["smwg4th_Job_Stayer"], label="Job Stayer", linewidth=3)
plt.ylim(0, 10)
plt.legend(fontsize=18, frameon=False, loc = "upper left")

# Clean axis aesthetics
ax = plt.gca()
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
ax.tick_params(axis="both", which="major", labelsize=18)

plt.tight_layout()
plt.savefig(f"{figures_dir}/figure_B_5_C.pdf")
#plt.show()
print("Figure B.5, Panel C processed and saved.")

######################################################################
# Figure B.7, Panel A
######################################################################
print("Making figure for Figure B.7, Panel A...")

plt.rcParams.update({
    'font.size': 14,             # Set default font size
    'axes.titlesize': 24,        # Title font size
    'axes.labelsize': 20,        # Axis labels font size
    'legend.fontsize': 12,       # Legend font size
    'xtick.labelsize': 20,       # X-axis tick labels
    'ytick.labelsize': 20,       # Y-axis tick labels
    'legend.frameon': False,     # Remove legend box
    'axes.spines.top': False,    # Remove top spine
    'axes.spines.right': False,  # Remove right spine
})

wage_data = pd.read_csv(f"{data_dir}/figure_B_7.csv")
wage_data['date'] = pd.to_datetime(wage_data['date'])

gaps = {
    'gap_1': wage_data['predicted_real_wage_index_1'].iloc[-1] - wage_data['real_wage_index_1'].iloc[-1],
    'gap_2': wage_data['predicted_real_wage_index_2'].iloc[-1] - wage_data['real_wage_index_2'].iloc[-1],
    'gap_3': wage_data['predicted_real_wage_index_3'].iloc[-1] - wage_data['real_wage_index_3'].iloc[-1],
    'gap_4': wage_data['predicted_real_wage_index_4'].iloc[-1] - wage_data['real_wage_index_4'].iloc[-1],
    'gap_med': wage_data['predicted_med_real_wage_index'].iloc[-1] - wage_data['med_real_wage_index'].iloc[-1],
    'gap_price': wage_data['price_index'].iloc[-1] - wage_data['predicted_price_index'].iloc[-1]
}

plt.figure(figsize=(8, 6))
plt.plot(wage_data['date'], wage_data['med_real_wage_index'], label='Real Wage Index',linewidth=3)
plt.plot(wage_data['date'], wage_data['predicted_med_real_wage_index'], color='black', linestyle='--', label='Predicted', linewidth=1.5)
plt.ylim(0.95, 1.4)
plt.axhline(y=1, color='black')
plt.xticks(fontsize=22)
plt.yticks(fontsize=22)
plt.annotate(f'{gaps["gap_med"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_med_real_wage_index'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_med_real_wage_index'].iloc[-1] + 0.015), fontsize=22)
plt.savefig(f"{figures_dir}/figure_B_7_A.pdf")
#plt.show()
print("Figure B.7, Panel A processed and saved.")

######################################################################
# Figure B.7, Panel B
######################################################################
print("Making figure for Figure B.7, Panel B...")

plt.figure(figsize=(8, 6))
plt.plot(wage_data['date'], wage_data['real_wage_index_1'], label='Real Wage Index', linewidth=3)
plt.plot(wage_data['date'], wage_data['predicted_real_wage_index_1'], color='black', linestyle='--', label='Predicted', linewidth=1.5)
plt.ylim(0.95, 1.4)
plt.axhline(y=1, color='black')
plt.xticks(fontsize=22)
plt.yticks(fontsize=22)
plt.annotate(f'{gaps["gap_1"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_1'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_1'].iloc[-1] + 0.015), fontsize=24)
plt.savefig(f"{figures_dir}/figure_B_7_B.pdf")
#plt.show()
print("Figure B.7, Panel B processed and saved.")

######################################################################
# Figure B.7, Panel C
######################################################################
print("Making figure for Figure B.7, Panel C...")

plt.figure(figsize=(8, 6))
plt.plot(wage_data['date'], wage_data['real_wage_index_4'], label='Real Wage Index', linewidth=3)
plt.plot(wage_data['date'], wage_data['predicted_real_wage_index_4'], color='black', linestyle='--', label='Predicted', linewidth=1.5)
plt.ylim(0.95, 1.4)
plt.axhline(y=1, color='black')
plt.xticks(fontsize=22)
plt.yticks(fontsize=22)
plt.annotate(f'{gaps["gap_4"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_4'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_4'].iloc[-1] + 0.015), fontsize=22)
plt.savefig(f"{figures_dir}/figure_B_7_C.pdf")
#plt.show()
print("Figure B.7, Panel C processed and saved.")

plt.rcdefaults()  # Reset to default settings after plotting


######################################################################
# Figure B.9
######################################################################
print("Making figure for Figure B.9...")

final_df = pd.read_csv(f"{data_dir}/figure_B_9.csv")

# Set up variables
y = final_df["job_opening_pct_change"].to_numpy(dtype=float)  
x = final_df["quits_pct_change"].to_numpy(dtype=float)       
weights = final_df["emp_share"].to_numpy(dtype=float)
industries = final_df["jolts_industry"]

# Fit weighted linear regression: quits ~ vacancies
X = sm.add_constant(x)
model = sm.WLS(y, X, weights = weights).fit()

# Regression results
slope = model.params[1]
intercept = model.params[0]
r_squared = model.rsquared

print(f"Intercept: {intercept:.2f}")
print(f"Slope (coefficient on vacancies): {slope:.2f}")
print(f"R-squared: {r_squared:.2f}")

# Predicted line
x_pred = np.linspace(x.min(), x.max(), 100)
y_pred = model.predict(sm.add_constant(x_pred))

# Plot
plt.figure(figsize=(10, 7))
plt.scatter(x, y, s=weights * 2000, alpha=0.7)

# Add labels for each industry
for i in range(len(final_df)):
    plt.text(x[i], y[i], industries.iloc[i], fontsize=10, ha='center', va='bottom')

# Regression line
plt.plot(x_pred, y_pred, linewidth=2)

# Axis labels
plt.xlabel("% Change in Quits", fontsize=18)
plt.ylabel("% Change in Vacancies", fontsize=18)

# Regression info box
plt.text(0.05, 0.95,
         f"Slope = {slope:.2f}\n$R^2$ = {r_squared:.2f}",
         transform=plt.gca().transAxes,
         verticalalignment='top',
         fontsize=14,
         bbox=dict(boxstyle="round,pad=0.5", facecolor="white", alpha=0.5))

# Styling
ax = plt.gca()
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
plt.tick_params(axis='x', labelsize=16)
plt.tick_params(axis='y', labelsize=16)

# Save and show
plt.tight_layout()
plt.savefig(f"{figures_dir}/figure_B_9.pdf")
print("Figure B.9 processed and saved.")

######################################################################
# Figure B.10, Panel A
######################################################################
print("Making figure for Figure B.10, Panel A...")

pivot_quarterly = pd.read_csv(f"{data_dir}/figure_B_10.csv")
pivot_quarterly['date'] = pd.to_datetime(pivot_quarterly['date'])
pivot_quarterly.set_index('date', inplace=True)
edu_group = 'E2'

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
plt.savefig(f"{figures_dir}/figure_B_10_A.pdf")
plt.close()
print("Figure B.10, Panel A processed and saved.")

######################################################################
# Figure B.10, Panel B
######################################################################
print("Making figure for Figure B.10, Panel B...")

edu_group = 'E4'

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
plt.savefig(f"{figures_dir}/figure_B_10_B.pdf")
plt.close()
print("Figure B.10, Panel B processed and saved.")

######################################################################
# Figure B.13
######################################################################
print("Making figure for Figure B.13...")

plt.rcParams.update({
    'font.size': 14,             # Set default font size
    'axes.titlesize': 24,        # Title font size
    'axes.labelsize': 20,        # Axis labels font size
    'legend.fontsize': 12,       # Legend font size
    'xtick.labelsize': 20,       # X-axis tick labels
    'ytick.labelsize': 20,       # Y-axis tick labels
    'legend.frameon': False,     # Remove legend box
    'axes.spines.top': False,    # Remove top spine
    'axes.spines.right': False,  # Remove right spine
})

data = pd.read_csv(f"{data_dir}/figure_B_13.csv")

data['date'] = pd.to_datetime(data['date'])
# Create quarterly series by avering the monthly data 
data = data.drop(columns=['date']).groupby(data['date'].dt.to_period('Q')).mean().reset_index()
data['date'] = data['date'].dt.to_timestamp()

days = 26 
data['vacancy_rate'] = data['vacancy_stock'] / (data['E'] + data['U'])
data['daily_job_filling_rate'] = (data['tot_hires']/data['vacancy_stock'])*(1/days)
data['daily_obsolesence'] = (data['tot_layoffs']/data['E'])*(1/days)
data['daily_flow_new_vacancies_lvl'] = data['vacancy_stock']*(data['daily_obsolesence'] + 
                                                    data['daily_job_filling_rate'] - 
                                                    (data['daily_obsolesence']*data['daily_job_filling_rate']))
data['monthly_flow_new_vacancy_rate'] = (data['daily_flow_new_vacancies_lvl']*days / (data['E']+ data['U']))*100
data['vacancy_duration'] = 1/data['daily_job_filling_rate']
# Specify Time frame 
data = data[data['date'] >= '2016-01-01']

# Create the plot 
plt.figure(figsize=(16, 10)) 
    
# Plot both lines
plt.plot(data['date'], data['vacancy_duration'], linewidth = 4)
plt.ylim(10,50)
# Customize the plot
plt.ylabel("Days")
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.tick_params(axis='both', which='minor', length=4, width=1)  # Optional for minor ticks
plt.savefig(f"{figures_dir}/figure_B_13.pdf", bbox_inches='tight')
print("Figure B.13 processed and saved.")
plt.rcdefaults()

######################################################################
# Figure B.14, Panel B
######################################################################
print("Making figure for Figure B.14, Panel B...")

data = pd.read_csv(f"{data_dir}/figure_B_14_B.csv")
# Ensure 'date' is in datetime format
data['date'] = pd.to_datetime(data['date'])

# Plot
ax = data.plot(x='date', y='profit_share', figsize=(14, 10), legend=False, linewidth  = 6)
plt.ylim(0, 14)

# Clean up the plot appearance
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

# Remove x-axis label and set tick label size
ax.set_xlabel("")  # This removes the 'date' label
ax.tick_params(axis='both', labelsize=38)

plt.tight_layout()
plt.savefig(f"{figures_dir}/figure_B_14_B.pdf", format='pdf')
#plt.show()

########################################################################
# Table B.4
########################################################################
print("Making Table B.4...")

data = pd.read_csv(f"{data_dir}/figure_B_15.csv")
reg_data = data[(data['date'] >= '1951-01-01') & (data['date'] <= '1999-12-01')].copy()
reg_data['U_rate_squared'] = reg_data['U_rate'] ** 2

def run_regression(data, y_var, covariates):
    X = sm.add_constant(data[covariates])
    y = data[y_var]
    return sm.OLS(y, X).fit()

# LaTeX table header
latex_table = """\\begin{table}[!htbp]
\\centering
\\caption{Regression Results: Profit Share as Outcome}
\\label{tab:profit_share_regs}
\\begin{tabular}{lccc}
\\hline\\hline
& (1) & (2) & (3) \\\\
\\hline
"""

# Define regression specs
specs = [
    ['U_rate'],
    ['U_rate', 'P_12m_change'],
    ['U_rate', 'U_rate_squared', 'P_12m_change']
]

# Run regressions
models = [run_regression(reg_data, 'profit_share', covs) for covs in specs]

# Helper: format coefficient + stars
def format_coef(coef, pval):
    stars = ''
    if pval < 0.01:
        stars = '^{***}'
    elif pval < 0.05:
        stars = '^{**}'
    elif pval < 0.1:
        stars = '^{*}'
    return f"{coef:.3f}{stars}"

# Variable label mapping
var_labels = {
    'U_rate': 'Unemployment Rate',
    'P_12m_change': 'Inflation',
    'U_rate_squared': 'Unemployment Rate$^2$',
    'const': 'Constant'
}

# Add coefficients + standard errors
for var in ['U_rate', 'U_rate_squared', 'P_12m_change', 'const']:
    row = var_labels.get(var, var) + " & "
    for model in models:
        if var in model.params:
            coef = format_coef(model.params[var], model.pvalues[var])
            se = f"({model.bse[var]:.3f})"
            row += f"${coef}$ & "
        else:
            row += " & "
    row = row.rstrip(" & ") + " \\\\\n"

    # Add standard error row if variable exists in any model
    se_row = " & "
    for model in models:
        if var in model.params:
            se_row += f"({model.bse[var]:.3f}) & "
        else:
            se_row += " & "
    se_row = se_row.rstrip(" & ") + " \\\\\n"

    latex_table += row + se_row

# Add R-squared and sample size
latex_table += "\\hline\n"
r2_row = "R$^2$ & " + " & ".join(f"{m.rsquared:.3f}" for m in models) + " \\\\\n"
n_row = "Observations & " + " & ".join(str(int(m.nobs)) for m in models) + " \\\\\n"
latex_table += r2_row + n_row

# Footer
latex_table += """\\hline\\hline
\\multicolumn{4}{l}{\\textit{Note:} Standard errors in parentheses.} \\\\
\\multicolumn{4}{l}{*** p$<$0.01, ** p$<$0.05, * p$<$0.1} \\\\
\\end{tabular}
\\end{table}
"""

with open(f"{table_dir}/table_B_4.tex", "w") as f:
    f.write(latex_table)
print("Table B.4 processed and saved.")

######################################################################
# Figure B.15
######################################################################
print("Making figure for Figure B.15...")

inflation_model = run_regression(reg_data, 'P_12m_change', ['U_rate'])
reg_data['inflation_residuals'] = inflation_model.resid

profit_model = run_regression(reg_data, 'profit_share', ['U_rate'])
reg_data['profit_share_residuals'] = profit_model.resid


# Set figure style for AER
plt.style.use('default')
fig, ax = plt.subplots(figsize=(8, 6))  # Slightly larger figure

# Create scatter plot with blue outlines and no fill
ax.scatter(reg_data['inflation_residuals'], 
           reg_data['profit_share_residuals'], 
           edgecolor='blue', 
           facecolor='none', 
           s=40)  # Slightly larger point size

# Fit and add regression line
x = reg_data['inflation_residuals']
y = reg_data['profit_share_residuals']
z = np.polyfit(x, y, 1)
p = np.poly1d(z)
ax.plot(x, p(x), color='red', linewidth=2.5)  # Thicker regression line

# Clean up plot appearance
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['left'].set_linewidth(0.5)
ax.spines['bottom'].set_linewidth(0.5)

# Font and label styling
plt.rcParams['font.family'] = 'Times New Roman'
ax.set_xlabel('Inflation Residuals', fontsize=20)
ax.set_ylabel('Profit Share Residuals', fontsize=20)
ax.tick_params(direction='out', length=6, width=0.75, labelsize=18)

plt.tight_layout()
plt.savefig(f"{figures_dir}/figure_B_15.pdf")
#plt.show()
plt.rcdefaults()
print("Figure B.15 processed and saved.")  

######################################################################
# Figure 6.1, Panel B 
######################################################################
print("Making figure for Figure 6.1, Panel B...")

data = pd.read_csv(f"{data_dir}/figure_6_1.csv")
data['date'] = pd.to_datetime(data['date']) 

reg_data = data[(data['date'] >= '1951-01-01') & (data['date'] <= '2019-12-01')]
reg_data = reg_data.copy()

reg_data.loc[:, 'U_rate_squared'] = reg_data['U_rate'] ** 2

inflation_vars = ['U_rate', 'U_rate_squared', 'P_12m_change']
subset_infl = reg_data[inflation_vars].dropna()
X = sm.add_constant(subset_infl[['U_rate', 'U_rate_squared']])  
y = subset_infl['P_12m_change'] 
model = sm.OLS(y, X).fit()
reg_data.loc[subset_infl.index, 'inflation_residuals'] = model.resid

# Residualizing Tightness
tightness_vars = ['U_rate', 'U_rate_squared', 'tightness']
subset_tight = reg_data[tightness_vars].dropna()
X = sm.add_constant(subset_tight[['U_rate', 'U_rate_squared']])  
y = subset_tight['tightness'] 
model = sm.OLS(y, X).fit()
reg_data.loc[subset_tight.index, 'tightness_residuals'] = model.resid

# Stick to the original structure; just fix the residual alignment issue

# Set figure style for AER
plt.style.use('default')
fig, ax = plt.subplots(figsize=(6.5, 4.5))  # AER typically uses smaller figures

# Drop rows where either residual is missing
resid_data = reg_data[['inflation_residuals', 'tightness_residuals']].dropna()

# Create scatter plot with blue outlines and no fill
ax.scatter(resid_data['inflation_residuals'], 
           resid_data['tightness_residuals'], 
           edgecolor='blue',  # Outline color
           facecolor='none',  # No fill color
           s=20)  # Smaller point size

# Calculate and add regression line in red
x = resid_data['inflation_residuals']
y = resid_data['tightness_residuals']
z = np.polyfit(x, y, 1)
p = np.poly1d(z)
ax.plot(x, p(x), color='red', linewidth=1.5)  # Regression line in red

# Customize axes and labels
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['left'].set_linewidth(0.5)
ax.spines['bottom'].set_linewidth(0.5)

# Set font to Times New Roman
plt.rcParams['font.family'] = 'Times New Roman'

# Add labels with proper formatting
ax.set_xlabel('Inflation Residuals', fontsize=10)
ax.set_ylabel('Vac-to-Unemp Residuals', fontsize=10)

# Remove grid
ax.grid(False)

# Set tick parameters
ax.tick_params(direction='out', length=4, width=0.5, labelsize=9)

# Adjust layout
plt.tight_layout()

# Optional: Save with high DPI for publication
plt.savefig(f"{figures_dir}/figure_6_1_B.pdf")

# #plt.show()
print("Figure 6.1, Panel B processed and saved.")


#######################################################################
# Table 4
#######################################################################
print("Making Table 4...")

def run_regression_get_latex(data, y_var, covariates):
    X = sm.add_constant(data[covariates])
    y = data[y_var]
    model = sm.OLS(y, X).fit()
    return model

# Create LaTeX table header
latex_table = """\\begin{table}[!htbp]
\\centering
\\caption{Regression Results}
\\label{tab:regressions}
\\begin{tabular}{lcccccc}
\\hline\\hline
& \\multicolumn{3}{c}{Vacancy Rate} & \\multicolumn{3}{c}{Labor Market Tightness} \\\\
\\cline{2-4} \\cline{5-7}
& (1) & (2) & (3) & (4) & (5) & (6) \\\\
\\hline
"""

# Define specifications
specs = [
    ('V_rate', ['U_rate']),
    ('V_rate', ['U_rate', 'P_12m_change']),
    ('V_rate', ['U_rate', 'U_rate_squared', 'P_12m_change']),
    ('tightness', ['U_rate']),
    ('tightness', ['U_rate', 'P_12m_change']),
    ('tightness', ['U_rate', 'U_rate_squared', 'P_12m_change'])
]

# Run all models and store results
models = [run_regression_get_latex(reg_data, y_var, covs) for y_var, covs in specs]

# Function to format coefficient with stars
def format_coef(coef, pval):
    coef_str = f"{coef:0.3f}"
    if pval < 0.01:
        coef_str += "^{***}"
    elif pval < 0.05:
        coef_str += "^{**}"
    elif pval < 0.1:
        coef_str += "^{*}"
    return coef_str

# Add coefficients to table
variables = ['Unemployment Rate', 'Inflation', 'Unemployment Rate$^2$', 'Constant']
var_mapping = {
    'U_rate': 'Unemployment Rate',
    'P_12m_change': 'Inflation',
    'U_rate_squared': 'Unemployment Rate$^2$',
    'const': 'Constant'
}

for var in ['U_rate', 'P_12m_change', 'U_rate_squared', 'const']:
    row = f"{var_mapping[var]} & "
    for model in models:
        if var in model.params:
            coef = format_coef(model.params[var], model.pvalues[var])
            se = f"({model.bse[var]:0.3f})"
            row += f"${coef}$ & "
            row += f"{se} & "
        else:
            row += "& & "
    row = row[:-2] + "\\\\"
    latex_table += row + "\n"

# Add R-squared and N
latex_table += "\\hline\n"
r2_row = "R$^2$ & "
n_row = "Observations & "
for model in models:
    r2_row += f"{model.rsquared:0.3f} & "
    n_row += f"{int(model.nobs)} & "
r2_row = r2_row[:-2] + "\\\\\n"
n_row = n_row[:-2] + "\\\\\n"
latex_table += r2_row
latex_table += n_row

# Add table footer
latex_table += """\\hline\\hline
\\multicolumn{7}{l}{\\textit{Note:} Standard errors in parentheses} \\\\
\\multicolumn{7}{l}{*** p$<$0.01, ** p$<$0.05, * p$<$0.1} \\\\
\\end{tabular}
\\end{table}"""

with open(f"{table_dir}/table_4.tex", "w") as file:
    file.write(latex_table)
print("Table 4 processed and saved.")
 
