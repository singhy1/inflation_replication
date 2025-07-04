
# Yash Singh 
# date: 11/12/24 
# this scripts estimates the monthly flow rate of vacancy creation and vacancy fill rate 

# Specify directories 
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"
 

import numpy as np 
import pandas as pd 
import matplotlib.pyplot as plt

# Set global styles
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

data = pd.read_csv(f"{output_dir}/data/dfh_estimation.csv")
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

plt.savefig(f"{output_dir}/figures/vacancy_duration_short.pdf", bbox_inches='tight')
plt.show()
