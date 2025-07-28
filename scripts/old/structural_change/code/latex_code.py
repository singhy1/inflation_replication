# Yash Singh 
# import pandas as pd

# 1. Read the Excel file

df = pd.read_excel('C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output/tables/structural_change.xlsx')

# 2. Convert all numeric columns to integer (no decimal places).
#    We attempt to round any float columns before converting to int.
for col in df.columns:
    if pd.api.types.is_numeric_dtype(df[col]):
        df[col] = df[col].round(0).astype(int)

# 3. Generate LaTeX code.
#    - We do not use `longtable=True` here because we wrap the table
#      in a `\resizebox`, which typically goes with a regular table environment.
latex_table = df.to_latex(
    index=False,
    float_format="%.0f",        # Another safeguard for float formatting
    caption="Structural Change Data", 
    label="tab:structural_change"
)

# 4. Wrap the LaTeX in a resizebox so it does not overflow the page
latex_code = (
    "\\begin{table}[ht!]\n"
    "\\centering\n"
    "\\resizebox{\\textwidth}{!}{%\n"
    + latex_table +
    "}\n\\end{table}\n"
)

print(latex_code)
