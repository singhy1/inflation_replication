# Yash Singh 
# date: 11/1/2024 
# this script uses data from the Atlanta Fed Wage Tracker to construct real wage indices across the income distribution 

# Specify directories 
data_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
output_dir = "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"

import numpy as np
import pandas as pd 
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression

data = pd.read_excel(f"{data_dir}/atl_fed/wage-growth-data.xlsx", sheet_name = 'Average Wage Quartile', skiprows=2, header=0)
cpi = pd.read_csv(f"{data_dir}/CPI/CPIAUCSL.xls", engine='xlrd', header=0)

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

# Atlanta Fed Wage Data 
data = data.rename(columns={
    'Unnamed: 0': 'date',
    'Lowest quartile of wage distribution': 'Q1',
     '2nd quartile of wage distribution': 'Q2', 
    '3rd quartile of wage distribution': 'Q3', 
    'Highest quartile of wage distribution': 'Q4'
})

select = ['date', 'Q1', 'Q2', 'Q3', 'Q4']
df = data[select]


# CPI-U 
cpi = cpi.iloc[10:].reset_index(drop=True)

cpi = cpi.rename(columns={
                            'FRED Graph Observations': 'date', 
                            'Unnamed: 1':               'P'
})

cpi['date'] = pd.to_datetime(cpi['date'])
cpi['P'] = pd.to_numeric(cpi['P'], errors='coerce')
cpi['P_12m_change'] = cpi['P'].pct_change(periods=12) * 100


wage_data = data.merge(cpi, on='date', how = 'left')

wage_data_copy = wage_data.copy()

wage_data = wage_data[wage_data['date'] >= '2015-12-01']
wage_data = wage_data[wage_data['date'] <= '2024-06-01']


wage_data = wage_data.drop(['Lowest half of wage distribution', 'Upper half of wage distribution'], axis = 1)
wage_data = wage_data.reset_index(drop=True)

wage_data['wage_index_1'] = 1
wage_data['wage_index_2'] = 1
wage_data['wage_index_3'] = 1
wage_data['wage_index_4'] = 1
wage_data['med_wage_index'] = 1 
wage_data['P_norm'] = wage_data['P'] / wage_data['P'].iloc[0]
wage_data['price_mom_grth'] = 1 + wage_data['P_norm'].pct_change()

wage_data = wage_data[wage_data['date'] >= '2016-01-01']

wage_data['q1_mom_grth'] = 1+ (wage_data['Q1']/100)/12
wage_data['q2_mom_grth'] = 1+ (wage_data['Q2']/100)/12
wage_data['q3_mom_grth'] = 1+ (wage_data['Q3']/100)/12
wage_data['q4_mom_grth'] = 1+ (wage_data['Q4']/100)/12
wage_data['med_mom_grth'] = 1+ (wage_data['Overall']/100)/12

wage_data['P_1m_change'] = 1 + (wage_data['P_12m_change']/100)/12

wage_data['nom_wage_index_1'] = wage_data['q1_mom_grth'].cumprod()
wage_data['nom_wage_index_2'] = wage_data['q2_mom_grth'].cumprod()
wage_data['nom_wage_index_3'] = wage_data['q3_mom_grth'].cumprod()
wage_data['nom_wage_index_4'] = wage_data['q4_mom_grth'].cumprod()
wage_data['med_nom_wage_index'] = wage_data['med_mom_grth'].cumprod()
wage_data['price_index']      = wage_data['P_1m_change'].cumprod()
wage_data['cpi']              = wage_data['price_mom_grth'].cumprod()



wage_data = wage_data.fillna(1)

wage_data['real_wage_index_1'] = wage_data['nom_wage_index_1'] / wage_data['price_index']
wage_data['real_wage_index_2'] = wage_data['nom_wage_index_2'] / wage_data['price_index']
wage_data['real_wage_index_3'] = wage_data['nom_wage_index_3'] / wage_data['price_index']
wage_data['real_wage_index_4'] = wage_data['nom_wage_index_4'] / wage_data['price_index']
wage_data['med_real_wage_index'] = wage_data['med_nom_wage_index'] / wage_data['price_index']


# Define the date range for the trend line
start_date = '2016-01-01'
end_date = '2019-12-31'

# Filter the data for the trend calculation
trend_data = wage_data[(wage_data['date'] >= start_date) & (wage_data['date'] <= end_date)]

# Prepare for linear regression with months since the start date
X = ((trend_data['date'].dt.year - trend_data['date'].min().year) * 12 +
     (trend_data['date'].dt.month - trend_data['date'].min().month)).values.reshape(-1, 1)

# Create a dictionary to hold the predicted values for each wage index
predicted_values = {}

# Loop through each wage index to predict values
for column_name in ['real_wage_index_1', 'real_wage_index_2', 'real_wage_index_3', 'real_wage_index_4', 
                    'med_real_wage_index', 'cpi']:
    
    # Fit linear regression model
    y = trend_data[column_name].values
    model = LinearRegression()
    model.fit(X, y)
    
    # Predict for the entire dataset, using months since the start date
    all_dates = ((wage_data['date'].dt.year - trend_data['date'].min().year) * 12 +
                 (wage_data['date'].dt.month - trend_data['date'].min().month)).values.reshape(-1, 1)
    predicted_values[column_name] = model.predict(all_dates)

# Add the predicted columns to the DataFrame
for column_name in predicted_values:
    wage_data[f'predicted_{column_name}'] = predicted_values[column_name]
    


# Assuming wage_data is already defined and includes predicted columns
# Calculate gaps for each index
gaps = {
    'gap_1': wage_data['predicted_real_wage_index_1'].iloc[-1] - wage_data['real_wage_index_1'].iloc[-1],
    'gap_2': wage_data['predicted_real_wage_index_2'].iloc[-1] - wage_data['real_wage_index_2'].iloc[-1],
    'gap_3': wage_data['predicted_real_wage_index_3'].iloc[-1] - wage_data['real_wage_index_3'].iloc[-1],
    'gap_4': wage_data['predicted_real_wage_index_4'].iloc[-1] - wage_data['real_wage_index_4'].iloc[-1],
    'gap_med': wage_data['predicted_med_real_wage_index'].iloc[-1] - wage_data['med_real_wage_index'].iloc[-1],
    'gap_price': wage_data['cpi'].iloc[-1] - wage_data['predicted_cpi'].iloc[-1]
}

# Create five separate plots
plt.figure(figsize=(18, 18))

# Plot for real_wage_index_1
plt.subplot(3, 2, 1)
plt.plot(wage_data['date'], wage_data['real_wage_index_1'], label='Real Wage Index 1')
plt.plot(wage_data['date'], wage_data['predicted_real_wage_index_1'], color='black', linestyle='--', label='Predicted', linewidth=1.5)
plt.title('Bottom Income Quartile')
plt.ylabel('Real Wage Index')
plt.ylim(0.95, 1.4)
plt.xticks(rotation=0)
plt.axhline(y=1, color='black', linewidth=1)  # Horizontal line at y=1
plt.annotate(f'Gap: {gaps["gap_1"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_1'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_1'].iloc[-1] + 0.03), 
             arrowprops=dict(facecolor='black', arrowstyle='->'), 
             fontsize=22, color='black', ha='left')
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)

plt.xticks(fontsize=16)  
plt.yticks(fontsize=16) 


# Plot for real_wage_index_2
plt.subplot(3, 2, 2)
plt.plot(wage_data['date'], wage_data['real_wage_index_2'], label='Real Wage Index 2')
plt.plot(wage_data['date'], wage_data['predicted_real_wage_index_2'], color='black', linestyle='--', label='Predicted', linewidth=1.5)
plt.title('Income Quartile 2')
plt.ylabel('Real Wage Index')
plt.ylim(0.95, 1.4)
plt.xticks(rotation=0)
plt.axhline(y=1, color='black', linewidth=1)  # Horizontal line at y=1
plt.annotate(f'Gap: {gaps["gap_2"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_2'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_2'].iloc[-1] + 0.03), 
             arrowprops=dict(facecolor='black', arrowstyle='->'), 
             fontsize=22, color='black', ha='left')
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.xticks(fontsize=16)  
plt.yticks(fontsize=16) 


# Plot for real_wage_index_3
plt.subplot(3, 2, 3)
plt.plot(wage_data['date'], wage_data['real_wage_index_3'], label='Real Wage Index 3')
plt.plot(wage_data['date'], wage_data['predicted_real_wage_index_3'], color='black', linestyle='--', label='Predicted', linewidth=1.5)
plt.title('Income Quartile 3')
plt.ylabel('Real Wage Index')
plt.ylim(0.95, 1.4)
plt.xticks(rotation=0)
plt.axhline(y=1, color='black', linewidth=1)  # Horizontal line at y=1
plt.annotate(f'Gap: {gaps["gap_3"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_3'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_3'].iloc[-1] + 0.03), 
             arrowprops=dict(facecolor='black', arrowstyle='->'), 
             fontsize=22, color='black', ha='left')
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.xticks(fontsize=16)  
plt.yticks(fontsize=16) 


# Plot for real_wage_index_4
plt.subplot(3, 2, 4)
plt.plot(wage_data['date'], wage_data['real_wage_index_4'], label='Real Wage Index 4')
plt.plot(wage_data['date'], wage_data['predicted_real_wage_index_4'], color='black', linestyle='--', label='Predicted', linewidth=1.5)
plt.title('Top Income Quartile 4')
plt.ylabel('Real Wage Index')
plt.ylim(0.95, 1.4)
plt.xticks(rotation=0)
plt.axhline(y=1, color='black', linewidth=1)  # Horizontal line at y=1
plt.annotate(f'Gap: {gaps["gap_4"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_4'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_4'].iloc[-1] + 0.03), 
             arrowprops=dict(facecolor='black', arrowstyle='->'), 
             fontsize=22, color='black', ha='left')

plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.xticks(fontsize=16)  
plt.yticks(fontsize=16) 


plt.subplot(3, 2, 5)  # Leave the 5th subplot blank
plt.plot(wage_data['date'], wage_data['med_real_wage_index'])
plt.plot(wage_data['date'], wage_data['predicted_med_real_wage_index'], color='black', linestyle='--', label='Predicted', linewidth=1.5)
plt.xticks(fontsize=16)  
plt.yticks(fontsize=16) 

plt.title('Median Real Wage Index')
plt.ylabel('Real Wage Index')
plt.ylim(0.95, 1.4)
plt.xticks(rotation=0)
plt.axhline(y=1, color='black', linewidth=1)  # Horizontal line at y=1
plt.annotate(f'Gap: {gaps["gap_med"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_med_real_wage_index'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_med_real_wage_index'].iloc[-1] + 0.03), 
             arrowprops=dict(facecolor='black', arrowstyle='->'), 
             fontsize=22, color='black', ha='left')

plt.plot(wage_data['date'], wage_data['cpi'])
plt.plot(wage_data['date'], wage_data['predicted_cpi'], color='red', linestyle='--', label='Predicted', linewidth=1.5)


plt.annotate(f'Gap: {gaps["gap_price"] * 100:.2f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_cpi'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_cpi'].iloc[-1] + 0.03), 
             arrowprops=dict(facecolor='black', arrowstyle='->'), 
             fontsize=10, color='red', ha='center')

# Adjust layout
plt.tight_layout()  
plt.savefig(f"{output_dir}/figures/wage_index_trends_short.pdf")


# Export data 
main = ['date', 'cpi', 'predicted_cpi', 
                'med_real_wage_index', 'predicted_med_real_wage_index', 
                'real_wage_index_1', 'predicted_real_wage_index_1', 
                'real_wage_index_2', 'predicted_real_wage_index_2', 
                'real_wage_index_3', 'predicted_real_wage_index_3', 
                'real_wage_index_4', 'predicted_real_wage_index_4']

final = wage_data[main]

final.to_csv(f"{output_dir}/data/real_wage_figures.csv", index = False)

############################################################################################
############################################################################################
# Appendix figure with evolution of real wages across the wage distribution since 2000 
############################################################################################
############################################################################################

wage_data = wage_data_copy

# 2000-2024 
wage_data = wage_data[wage_data['date'] >= '1999-12-01']
wage_data = wage_data[wage_data['date'] <= '2024-06-01']


wage_data = wage_data.drop(['Lowest half of wage distribution', 'Upper half of wage distribution'], axis = 1)
wage_data = wage_data.reset_index(drop=True)

wage_data['wage_index_1'] = 1
wage_data['wage_index_2'] = 1
wage_data['wage_index_3'] = 1
wage_data['wage_index_4'] = 1
wage_data['med_wage_index'] = 1 

p_2020_m1 = wage_data[wage_data['date'] == '2020-01-01']['P'].values[0]
wage_data['P_norm'] = wage_data['P'] / p_2020_m1

wage_data['price_mom_grth'] = 1 + wage_data['P_norm'].pct_change()


#wage_data = wage_data[wage_data['date'] >= '2016-01-01']
wage_data = wage_data[wage_data['date'] >= '2000-01-01']


wage_data['q1_mom_grth'] = 1+ (wage_data['Q1']/100)/12
wage_data['q2_mom_grth'] = 1+ (wage_data['Q2']/100)/12
wage_data['q3_mom_grth'] = 1+ (wage_data['Q3']/100)/12
wage_data['q4_mom_grth'] = 1+ (wage_data['Q4']/100)/12
wage_data['med_mom_grth'] = 1+ (wage_data['Overall']/100)/12

wage_data['P_1m_change'] = 1 + (wage_data['P_12m_change']/100)/12

wage_data['nom_wage_index_1'] = wage_data['q1_mom_grth'].cumprod()
wage_data['nom_wage_index_2'] = wage_data['q2_mom_grth'].cumprod()
wage_data['nom_wage_index_3'] = wage_data['q3_mom_grth'].cumprod()
wage_data['nom_wage_index_4'] = wage_data['q4_mom_grth'].cumprod()
wage_data['med_nom_wage_index'] = wage_data['med_mom_grth'].cumprod()
wage_data['price_index']      = wage_data['P_1m_change'].cumprod()
wage_data['cpi']              = wage_data['price_mom_grth'].cumprod()



wage_data = wage_data.fillna(1)

wage_data['real_wage_index_1'] = wage_data['nom_wage_index_1'] / wage_data['price_index']
wage_data['real_wage_index_2'] = wage_data['nom_wage_index_2'] / wage_data['price_index']
wage_data['real_wage_index_3'] = wage_data['nom_wage_index_3'] / wage_data['price_index']
wage_data['real_wage_index_4'] = wage_data['nom_wage_index_4'] / wage_data['price_index']
wage_data['med_real_wage_index'] = wage_data['med_nom_wage_index'] / wage_data['price_index']

start_date = '2000-01-01'
end_date = '2019-12-31'

# Filter the data for the trend calculation
trend_data = wage_data[(wage_data['date'] >= start_date) & (wage_data['date'] <= end_date)]

# Prepare for linear regression with months since the start date
X = ((trend_data['date'].dt.year - trend_data['date'].min().year) * 12 +
     (trend_data['date'].dt.month - trend_data['date'].min().month)).values.reshape(-1, 1)

# Create a dictionary to hold the predicted values
predicted_values = {}

# Loop through each wage index to predict values
for column_name in ['real_wage_index_1', 'real_wage_index_2', 'real_wage_index_3', 'real_wage_index_4', 
                    'med_real_wage_index', 'cpi']:
    
    # Fit linear regression model through (0,1)
    y = trend_data[column_name].values
    # Subtract 1 from y values to center around 0
    y_adjusted = y - 1
    
    # Fit regression through origin
    model = LinearRegression(fit_intercept=False)
    model.fit(X, y_adjusted)
    
    # Calculate predictions for all dates and add 1 back
    all_dates = ((wage_data['date'].dt.year - trend_data['date'].min().year) * 12 +
                 (wage_data['date'].dt.month - trend_data['date'].min().month)).values.reshape(-1, 1)
    predicted_values[column_name] = model.predict(all_dates) + 1

# Add the predicted columns to the DataFrame
for column_name in predicted_values:
    wage_data[f'predicted_{column_name}'] = predicted_values[column_name]


# Assuming wage_data is already defined and includes predicted columns
# Calculate gaps for each index
gaps = {
    'gap_1': wage_data['predicted_real_wage_index_1'].iloc[-1] - wage_data['real_wage_index_1'].iloc[-1],
    'gap_2': wage_data['predicted_real_wage_index_2'].iloc[-1] - wage_data['real_wage_index_2'].iloc[-1],
    'gap_3': wage_data['predicted_real_wage_index_3'].iloc[-1] - wage_data['real_wage_index_3'].iloc[-1],
    'gap_4': wage_data['predicted_real_wage_index_4'].iloc[-1] - wage_data['real_wage_index_4'].iloc[-1],
    'gap_med': wage_data['predicted_med_real_wage_index'].iloc[-1] - wage_data['med_real_wage_index'].iloc[-1],
    'gap_price': wage_data['cpi'].iloc[-1] - wage_data['predicted_cpi'].iloc[-1]
}

# Create five separate plots
plt.figure(figsize=(18, 18))

# Plot for real_wage_index_1
plt.subplot(3, 2, 1)
plt.plot(wage_data['date'], wage_data['real_wage_index_1'], label='Real Wage Index 1')
plt.plot(wage_data['date'], wage_data['predicted_real_wage_index_1'], color='black', linestyle='--', label='Predicted', linewidth=1.5)
plt.title('Bottom Income Quartile')
plt.ylabel('Real Wage Index')
plt.ylim(0.95, 1.4)
plt.xticks(rotation=0)
plt.axhline(y=1, color='black', linewidth=1)  # Horizontal line at y=1
plt.annotate(f'Gap: {gaps["gap_1"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_1'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_1'].iloc[-1] + 0.03), 
             arrowprops=dict(facecolor='black', arrowstyle='->'), 
             fontsize=22, color='black', ha='left')
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)


# Plot for real_wage_index_2
plt.subplot(3, 2, 2)
plt.plot(wage_data['date'], wage_data['real_wage_index_2'], label='Real Wage Index 2')
plt.plot(wage_data['date'], wage_data['predicted_real_wage_index_2'], color='black', linestyle='--', label='Predicted', linewidth=1.5)
plt.title('Income Quartile 2')
plt.ylabel('Real Wage Index')
plt.ylim(0.95, 1.4)
plt.xticks(rotation=0)
plt.axhline(y=1, color='black', linewidth=1)  # Horizontal line at y=1
plt.annotate(f'Gap: {gaps["gap_2"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_2'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_2'].iloc[-1] + 0.03), 
             arrowprops=dict(facecolor='black', arrowstyle='->'), 
             fontsize=22, color='black', ha='left')
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)


# Plot for real_wage_index_3
plt.subplot(3, 2, 3)
plt.plot(wage_data['date'], wage_data['real_wage_index_3'], label='Real Wage Index 3')
plt.plot(wage_data['date'], wage_data['predicted_real_wage_index_3'], color='black', linestyle='--', label='Predicted', linewidth=1.5)
plt.title('Income Quartile 3')
plt.ylabel('Real Wage Index')
plt.ylim(0.95, 1.4)
plt.xticks(rotation=0)
plt.axhline(y=1, color='black', linewidth=1)  # Horizontal line at y=1
plt.annotate(f'Gap: {gaps["gap_3"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_3'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_3'].iloc[-1] + 0.03), 
             arrowprops=dict(facecolor='black', arrowstyle='->'), 
             fontsize=22, color='black', ha='left')
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)


# Plot for real_wage_index_4
plt.subplot(3, 2, 4)
plt.plot(wage_data['date'], wage_data['real_wage_index_4'], label='Real Wage Index 4')
plt.plot(wage_data['date'], wage_data['predicted_real_wage_index_4'], color='black', linestyle='--', label='Predicted', linewidth=1.5)
plt.title('Top Income Quartile 4')
plt.ylabel('Real Wage Index')
plt.ylim(0.95, 1.4)
plt.xticks(rotation=0)
plt.axhline(y=1, color='black', linewidth=1)  # Horizontal line at y=1
plt.annotate(f'Gap: {gaps["gap_4"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_4'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_real_wage_index_4'].iloc[-1] + 0.03), 
             arrowprops=dict(facecolor='black', arrowstyle='->'), 
             fontsize=22, color='black', ha='left')

plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)


plt.subplot(3, 2, 5)  # Leave the 5th subplot blank
plt.plot(wage_data['date'], wage_data['med_real_wage_index'])
plt.plot(wage_data['date'], wage_data['predicted_med_real_wage_index'], color='black', linestyle='--', label='Predicted', linewidth=1.5)


plt.title('Median Real Wage Index')
plt.ylabel('Real Wage Index')
plt.ylim(0.95, 1.4)
plt.xticks(rotation=0)
plt.axhline(y=1, color='black', linewidth=1)  # Horizontal line at y=1
plt.annotate(f'Gap: {gaps["gap_med"] * 100:.1f}', 
             xy=(wage_data['date'].iloc[-1], wage_data['predicted_med_real_wage_index'].iloc[-1]), 
             xytext=(wage_data['date'].iloc[-1], wage_data['predicted_med_real_wage_index'].iloc[-1] + 0.03), 
             arrowprops=dict(facecolor='black', arrowstyle='->'), 
             fontsize=22, color='black', ha='left')
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)


plt.tight_layout()  
plt.savefig(f"{output_dir}/figures/wage_index_trends_long.pdf")


main = ['date',
                'med_real_wage_index', 'predicted_med_real_wage_index', 
                'real_wage_index_1', 'predicted_real_wage_index_1', 
                'real_wage_index_2', 'predicted_real_wage_index_2', 
                'real_wage_index_3', 'predicted_real_wage_index_3', 
                'real_wage_index_4', 'predicted_real_wage_index_4']

final = wage_data[main]
final.to_csv(f"{output_dir}/data/wage_data_00_24.csv", index=False)

print("Script finished running")





