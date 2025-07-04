# Yash Singh 
# 11/18/24 
# This script makes 2 plots to show the relative contribution of the job-finding rate on unemployent dynamics between 1967-2024. 

# Specify directories 
data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"

import numpy as np
import pandas as pd 
import matplotlib.pyplot as plt
import statsmodels.api as sm

# Set global styles
plt.rcParams.update({
    'font.size': 14,             # Set default font size
    'axes.titlesize': 16,        # Title font size
    'axes.labelsize': 14,        # Axis labels font size
    'legend.fontsize': 12,       # Legend font size
    'xtick.labelsize': 12,       # X-axis tick labels
    'ytick.labelsize': 12,       # Y-axis tick labels
    'legend.frameon': False,     # Remove legend box
    'axes.spines.top': False,    # Remove top spine
    'axes.spines.right': False,  # Remove right spine
})

data = pd.read_csv(f"{data_dir}/mongey_data/mongey_data.csv") 

##################################################
# Some Basic processing 
##################################################

# Define a function to convert Quarter to datetime
def quarter_to_datetime(quarter):
    year = int(quarter)
    fraction = quarter - year
    if fraction == 0.00:
        month = 3
    elif fraction == 0.25:
        month = 6
    elif fraction == 0.50:
        month = 9
    elif fraction == 0.75:
        month = 12
    return pd.Timestamp(year=year, month=month, day=1)

# Apply the conversion to the Quarter column
data['date'] = data['Quarter'].apply(quarter_to_datetime)

data = data.rename(columns = {'u_c':'u_rate', 'uhatf_c':'u_rate_job_finding'})


data['u_rate'] = data['u_rate']*100 
data['u_rate_job_finding'] = data['u_rate_job_finding']*100

##################################################
# Decomposition Plots 
##################################################


#################################################
# This is the pre-period (long-run 1967-2019)
#################################################

data_pre = data[data['date'] <= '2019-12-01']

# Create the plot 
plt.figure(figsize=(12, 6)) 
    
# Plot both lines
plt.plot(data_pre['date'], data_pre['u_rate'], label='Actual Unemployment Rate', color='blue')
plt.plot(data_pre['date'], data_pre['u_rate_job_finding'], label='Counterfactual Unemployment Rate', color='red')
    
# Customize the plot
plt.title('Contribution of Job-Finding on Unemployment')
plt.ylabel('Unemployment %')
plt.ylim(2,12)
plt.legend(frameon=False)
# Remove the top and right spines
ax = plt.gca()  # Get current axis
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
plt.savefig(f"{output_dir}/figures/u_rate_comparison_job_finding_pre.pdf", bbox_inches='tight')
plt.show()

##############################################
# 2016-2024 plot
##############################################

data_post = data[data['date'] >= '2018-01-01']

# Create the plot 
plt.figure(figsize=(12, 6)) 
    
# Plot both lines
plt.plot(data_post['date'], data_post['u_rate'], label='Actual Unemployment Rate', color='blue')
plt.plot(data_post['date'], data_post['u_rate_job_finding'], label='Counterfactual Unemployment Rate', color='red')
    
# Customize the plot
plt.title('Contribution of Job-Finding on Unemployment')
plt.ylabel('Unemployment %')
plt.ylim(2,12)
plt.legend(frameon=False)
# Remove the top and right spines
ax = plt.gca()  # Get current axis
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

plt.savefig(f"{output_dir}/figures/u_rate_comparison_job_finding_post.pdf", bbox_inches='tight')
plt.show()


##################################################################
# 
##################################################################

# Assuming you have a DataFrame named 'data' with the relevant columns
X = data_pre['u_rate']  # Independent variable
y = data_pre['u_rate_job_finding']  # Dependent variable

# Add a constant to the independent variable (for the intercept)
X = sm.add_constant(X)

# Fit the linear regression model
model = sm.OLS(y, X).fit()

# Print the summary of the regression results
print(model.summary())