import numpy as np
import pandas as pd 
from sklearn.linear_model import LinearRegression
import json 
import statsmodels.api as sm
import matplotlib.pyplot as plt

# Set the data directory and output directory
data_dir = "/Users/giyoung/Library/CloudStorage/Dropbox/Labor_Market_PT/replication/empirical/inputs/raw_data"
output_dir = "/Users/giyoung/Library/CloudStorage/Dropbox/Labor_Market_PT/replication/empirical/outputs/figures"

# Load the re-uploaded Excel file
df_raw = pd.read_excel(f"{data_dir}/JOLTS/jolts_flows.xlsx", skiprows=2)

# Extract header and reformat
new_header = df_raw.iloc[0]
df_clean = df_raw[1:]
df_clean.columns = new_header
df_clean = df_clean.rename(columns={df_clean.columns[0]: "seriesid"})
df_clean.columns = df_clean.columns.astype(str)

# Reshape and clean
df_long = df_clean.melt(id_vars=["seriesid"], var_name="date", value_name="value")
df_long["date"] = df_long["date"].str.replace("\n", " ").str.strip()
df_long["date"] = pd.to_datetime(df_long["date"], format="%b %Y", errors="coerce")
df_long = df_long.dropna(subset=["date", "value"])
df_long = df_long.sort_values(by=["seriesid", "date"]).reset_index(drop=True)

# Extract codes from seriesid
df_long["industry_code"] = df_long["seriesid"].str[3:11]
df_long["flow_type_code"] = df_long["seriesid"].str[-3:]

# Get unique codes
industry_codes = df_long["industry_code"].unique()
flow_type_codes = df_long["flow_type_code"].unique()

industry_codes, flow_type_codes

# Define flow type mapping
flow_type_map = {
    "HIR": "Hires",
    "QUR": "Quits",
    "TSR": "Total Separations",
    "JOR": "Job Openings",
    "LDR": "Layoffs & Discharges",
    "UOR": "Other Separations",
    "OSR": "Other Separations (Residual)"
}

# Define industry code mapping based on BLS JOLTS industry categories
industry_map = {
    "00000000": "Total nonfarm",
    "10000000": "Total private",
    "11009900": "Mining and logging",
    "23000000": "Construction",
    "30000000": "Manufacturing",
    "32000000": "Durable goods manufacturing",
    "34000000": "Nondurable goods manufacturing",
    "40000000": "Trade, transportation, and utilities",
    "42000000": "Wholesale trade",
    "44000000": "Retail trade",
    "48009900": "Transportation, warehousing, and utilities",
    "51000000": "Information",
    "51009900": "Financial activities",
    "52000000": "Finance and insurance",
    "53000000": "Real estate and rental and leasing",
    "54009900": "Professional and business services",
    "60000000": "Private education and health services", 
    "61000000": "Private education services",
    "62000000": "Healthcare and Social Assistance",
    "70000000": "Leisure and Hospitality",
    "71000000": "Arts, entertainment, and recreation",
    "72000000": "Accomodation and food services",
    "81000000": "Other services",
    "90000000": "Government",
    "91000000": "Federal government",
    "92000000": "State and local government",
    "92300000": "State and local government education",
    "92900000": "State and local government, excluding education"
}

# Apply mappings
df_long["flow_type"] = df_long["flow_type_code"].map(flow_type_map)
df_long["industry"] = df_long["industry_code"].map(industry_map)

df_long = df_long.rename(columns={
    'value': 'rate',
})
keep = ['date', 'rate', 'flow_type', 'industry']
data = df_long[keep]

data = data.groupby(['industry', 'flow_type', 'date'])['rate'].mean().reset_index()
data = data[data['date'].dt.year != 2020]

conditions = [
    data['date'] < '2020-01-01',
    (data['date'] >= '2021-04-01') & (data['date'] <= '2023-05-01'),
    data['date'] >= '2023-06-01'
]
choices = ['pre', 'inf', 'post']

data['period'] = np.select(conditions, choices, default=pd.NA)

table = data.groupby(['industry', 'flow_type', 'period'])['rate'].mean().reset_index()

table = table[table['flow_type'].isin(['Quits', 'Job Openings'])]

exclude_keywords = ['government', 'Total']

# Filter to keep only industries that do NOT contain any exclude keywords
table = table[~table['industry'].str.contains('|'.join(exclude_keywords), case=False)]

# List of industry labels to drop
industries_to_drop = [
    'Financial activities',
    'Manufacturing',
    'Leisure and Hospitality',
    'Private education and health services',
    'Trade, transportation, and utilities',
]

# Filter the DataFrame
table = table[~table['industry'].isin(industries_to_drop)]

# Keep only rows where period is 'inf' or 'pre'
df = table[table['period'].isin(['inf', 'pre'])]
df = df.rename(columns={"industry":"jolts_industry"})

# Pivot so we have one row per industry and flow_type, with 'inf' and 'pre' as columns
pivot_df = df.pivot_table(index=['jolts_industry', 'flow_type'], columns='period', values='rate').reset_index()

# Calculate percent change: ((inf - pre) / pre) * 100
pivot_df['pct_change'] = 100 * (pivot_df['inf'] - pivot_df['pre']) / pivot_df['pre']

# Pivot to get pct_change for Job Openings and Quits per industry
pivot_df = pivot_df.pivot(index='jolts_industry', columns='flow_type', values='pct_change').reset_index()

# Rename columns
pivot_df = pivot_df.rename(columns={
    "Job Openings": "job_opening_pct_change",
    "Quits": "quits_pct_change"
})


final_df = pivot_df.copy()

# Set up variables
x = final_df["quits_pct_change"].to_numpy(dtype=float)  # now x is quits
y = final_df["job_opening_pct_change"].to_numpy(dtype=float)  # now y is vacancies
# weights = final_df["emp_share"].to_numpy(dtype=float)
industries = final_df["jolts_industry"]

# Fit weighted linear regression
X = sm.add_constant(x)
model = sm.WLS(y, X).fit()

# Regression results
slope = model.params[1]
intercept = model.params[0]
r_squared = model.rsquared

print(f"Intercept: {intercept:.2f}")
print(f"Slope (coefficient on quits): {slope:.2f}")
print(f"R-squared: {r_squared:.2f}")

# Predicted line
x_pred = np.linspace(x.min(), x.max(), 100)
y_pred = model.predict(sm.add_constant(x_pred))

# Plot
plt.figure(figsize=(10, 7))
plt.scatter(y, x, alpha=0.7)  # flip x and y

# Add labels for each industry
for i in range(len(final_df)):
    plt.text(y[i], x[i], industries.iloc[i], fontsize=10, ha='center', va='bottom')

# Regression line
plt.plot(y_pred, x_pred, linewidth=2)  # flip x and y

# Axis labels and title
plt.xlabel("% Change in Quits", fontsize=18)
plt.ylabel("% Change in Vacancies", fontsize=18)
# plt.title("Industry-Level % Changes: Vacancies vs Quits", fontsize=22)

# Add regression info
plt.text(0.05, 0.95,
         f"Slope = {slope:.2f}\n$R^2$ = {r_squared:.2f}",
         transform=plt.gca().transAxes,
         verticalalignment='top',
         fontsize=14,
         bbox=dict(boxstyle="round,pad=0.5", facecolor="white", alpha=0.5))

# Remove top and right spines
ax = plt.gca()
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
plt.tick_params(axis='x', labelsize=16)
plt.tick_params(axis='y', labelsize=16)

plt.tight_layout()
plt.savefig(f"{output_dir}/industry_flows_scatter.pdf")
plt.show()
