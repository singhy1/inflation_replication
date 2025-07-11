import numpy as np 
import pandas as pd 

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