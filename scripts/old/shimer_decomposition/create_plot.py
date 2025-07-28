# Yash Singh 
# date: 
# Specify directories 

output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"

# Necessary Packages 
import numpy as np 
import pandas as pd
import matplotlib.pyplot as plt
import statsmodels.api as sm

# Set global styles
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
#########################################################################################

# read data 
data = pd.read_csv(f"{output_dir}/data/shimer_decomposition_data.csv")

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
plt.savefig(f"{output_dir}/figures/u_rate_decomposition.pdf", bbox_inches='tight')
print("Script is done running")