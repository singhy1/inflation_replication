* Yash Singh 
* date: 8/1/24 
* this file generates UE and EU flow rates using Shimer (2005) methodology. 
* This also implies steady state unemployment rate. 

*********************************************************************

clear 
global data_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\raw_data"
global temp_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\temp"
global output_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\output"

* Erik's inflation series 
import excel "$data_dir\inflation_series.xlsx", sheet("FRED Graph") firstrow clear
drop in 1/10
rename FREDGraphObservations date
rename B inflation
gen date_monthly = date(date, "DMY")
format date_monthly %tdMon-YY
destring inflation, replace 
keep date_monthly inflation 
drop if missing(date_monthly)
save "$temp_dir/inflation_series.dta", replace 

* ADP wage data 
import excel "$data_dir\ADP_PAY_history.xlsx", sheet("ADP Wage Data") firstrow clear 
drop D 
rename A date_monthly
rename WageGrowthJobChanger nom_wgt_changer
rename WageGrowthJobStayer nom_wgt_stayer 
rename Difference nom_changer_stay_wgt_diff 
drop if missing(date_monthly)
save "$temp_dir/adp_wage_data.dta", replace 


* atl fed wage growth 
import excel "$data_dir\wage-growth-data_atl_fed.xlsx", sheet("Processed Data") firstrow clear 
rename A date_monthly
rename OverallPercentofzerowagech zero_share 
rename CPIInflationRateBLS bls_inflation 
rename MedianNominalWageGrowth nom_wage_grth_atlfed
keep date_monthly zero_share nom_wage_grth_atlfed 
duplicates report date_monthly
drop if missing(date_monthly)
save "$temp_dir/atl_fed_data.dta", replace 


* Import the Excel file
import excel "$data_dir\corporate_profits.xlsx", sheet("FRED Graph") firstrow clear
rename FREDGraphObservations date 
rename B profit_share 

* Delete the first 10 rows
drop in 1/10

gen date_daily = date(date, "DMY")

* Convert daily date to quarterly date
gen date_quarterly = qofd(date_daily)

* Format the quarterly date
format date_quarterly %tq

destring profit_share, replace force

keep date_quarterly profit_share
save "$temp_dir/profit_share.dta", replace 

* job flows data 
use "$output_dir\data\job_flow.dta", clear 
rename Date date_monthly 
keep date_monthly eu_quits_all eu_layoff_all eu_other_all 
save "$temp_dir/eu_micro_data.dta", replace 

* Macro Method

use "$temp_dir/cps_basic_monthly.dta", clear 

keep YEAR MONTH date_monthly MISH CPSIDP compwt EMPSTAT DURUNEM2 LABFORCE

************************************************

gen emp_flag = (EMPSTAT >= 10 & EMPSTAT <= 12)
gen unemp_flag = (EMPSTAT >= 20 & EMPSTAT <= 22)
gen short_unemp_flag = (DURUNEM2 > 0 & DURUNEM2 <= 4)

sort date_monthly

* employed stock
by date_monthly: egen emp_stock = sum(compwt * emp_flag)

* unemployed stock 
by date_monthly: egen unemp_stock = sum(compwt * unemp_flag) 

* short-term unemployed 
by date_monthly: egen short_unemp_stock = sum(compwt * short_unemp_flag * unemp_flag)

keep YEAR MONTH date_monthly short_unemp_stock emp_stock unemp_stock 
duplicates drop 

* employed and unemplyed stocks next month 
gen emp_stock_next = emp_stock[_n+1]
gen unemp_stock_next = unemp_stock[_n+1]
gen short_unemp_stock_next = short_unemp_stock[_n+1]

* flows 

* job finding rate - UE - use equation (1) in Shimer(2005)
gen ue_rate = 1 - ((unemp_stock_next - short_unemp_stock_next)/unemp_stock)

sort date_monthly
gen ue_rate_ma3 = (ue_rate + ue_rate[_n-1] + ue_rate[_n-2]) / 3 if _n > 2
replace ue_rate_ma3 = ue_rate_ma3 

* seperation rate - EU - use equation (2) in Shimer(2005)
gen eu_rate =  short_unemp_stock_next / (emp_stock*(1-.5*ue_rate))
gen eu_rate_ma3 = (eu_rate + eu_rate[_n-1] + eu_rate[_n-2])/3 if _n > 2

* steady state unemployment rate 
gen u_rate = eu_rate_ma3/(eu_rate_ma3 + ue_rate_ma3)  

keep if YEAR >= 2016

save "$temp_dir/shimer_macro_flows.dta", replace 

keep if YEAR >=2016
keep if YEAR <= 2019
collapse (mean) ue_rate eu_rate u_rate 

save "$temp_dir/pre_period_macro_flow_rates.dta", replace 

*********************************
* FMP Series - EE rates 
*********************************

import excel using "$data_dir\ee_fmp.xlsx", sheet("Data") firstrow clear
rename FMP_SA ee_pol	
gen date_monthly = mdy(month, 1, year)
format date_monthly %td
keep year month date_monthly ee_pol

keep if year >=2016
keep if year < 2020 

collapse (mean) ee = ee_pol


save "$temp_dir/ee_pre_period.dta", replace 		 


*********************************************************
* Micro Flows - Pre Period 
*********************************************************

use "$output_dir\data\job_flow.dta", clear 

rename Date date_monthly 
rename Year year 

* First, create a list of all variables
unab allvars: *

* Create a list of variables to exclude
local exclude_vars year MONTH date_monthly

* Create the list of variables to collapse
local collapse_vars : list allvars - exclude_vars

* Display the variables to be collapsed (for verification)
display "`collapse_vars'"

* Collapse the data
collapse (mean) `collapse_vars', by(year)
drop Month 
keep if year < 2020
keep if year > 2015
unab allvars: *
collapse (mean) `allvars' 
drop year 

ds *asec*
keep `r(varlist)'

* Create an identifier variable
gen id = 1

* Create a list of the base variable names (without the digit)
unab varlist: *asec*
local bases
foreach var of local varlist {
    local base = substr("`var'", 1, length("`var'") - 2)
    if !`:list base in bases' {
        local bases `bases' `base'
    }
}

* Reshape the data
reshape long `bases', i(id) j(percentile)

replace percentile = 10 if percentile == 0

* Sort the data
sort percentile

* Drop the id variable as it's no longer needed
drop id
rename percentile decile 
rename ee_asec_wage_ ee
rename eu_quits_asec_wage_ eu_quits
rename eu_layoffs_asec_wage_ eu_layoffs 
rename eu_other_asec_wage_ eu_other 
rename ue_asec_wage_ ue

keep decile ee eu_quits eu_layoffs eu_other ue

gen eu_tot = eu_quits + eu_layoffs + eu_other

save "$temp_dir/pre_period_micro_flows.dta", replace 

* Load the first dataset and prepare it
use "$temp_dir/pre_period_macro_flow_rates.dta", clear 
rename ue_rate ue 
rename eu_rate eu 
gen class = "macro"

* Save it temporarily
tempfile temp_macro
save `temp_macro'

* Load the second dataset and prepare it
use "$temp_dir/pre_period_micro_flows.dta", replace 
collapse (mean) ee eu = eu_tot ue 
gen class = "micro"

* Append the first dataset
append using `temp_macro'

* Save the combined dataset temporarily
tempfile temp_combined
save `temp_combined'

* Load the third dataset and prepare it
use "$temp_dir/ee_pre_period.dta", clear 
gen class = "fmp"

* Append the combined dataset
append using `temp_combined'

gen ee_scale = ee / ee[_n+1]

gen eu_scale = eu / eu[_n-1]

gen ue_scale = ue / ue[_n-1]

keep ee_scale eu_scale ue_scale 

* Save the final combined dataset
save "$temp_dir/scaling_factors.dta", replace

***********************************************
***********************************************

use "$temp_dir/pre_period_micro_flows.dta", replace 

append using "$temp_dir/scaling_factors.dta"

replace ee_scale = ee_scale[11]
replace eu_scale = eu_scale[13]
replace ue_scale = ue_scale[13]
drop if missing(decile)

replace ee = ee*ee_scale
replace eu_quits = eu_quits*eu_scale 
replace eu_layoffs = eu_layoffs*eu_scale
replace eu_other = eu_other*eu_scale
replace eu_tot = eu_tot*eu_scale 
replace ue_scale = ue*ue_scale 

gen u_rate = eu_tot/(eu_tot + ue)

drop ee_scale eu_scale ue_scale 

export delimited using "$output_dir/data/flow_moments.csv", replace 