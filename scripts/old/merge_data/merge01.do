* Yash Singh 
* Merge data for all empirical figures into 1 csv file 

* monthly series 

import excel "$data_dir\JOLTS_flows_2000_2024.xlsx", sheet("BLS Data Reformatted") firstrow clear 
	   
keep A LayoffsDischarges JobOpenings Quits
rename A date_monthly
rename LayoffsDischarges layoff_rate_jolts
rename JobOpenings vacancy_rate_jolts 
rename Quits quit_rate_jolts 

merge 1:1 date_monthly using "$temp_dir/shimer_macro_flows.dta"
drop _merge 

merge 1:1 date_monthly using "$temp_dir/ee_cleaned.dta"
drop if _merge == 2
drop _merge 

keep date_monthly vacancy_rate_jolts layoff_rate_jolts quit_rate_jolts ue_rate_ma3 eu_rate_ma3 ee_pol_ma3
rename ue_rate_ma3 ue_rate_cps 
rename eu_rate_ma3 eu_rate_cps 
rename ee_pol_ma3 ee_rate_cps 

merge 1:1 date_monthly using "$temp_dir/inflation_series.dta"
drop _merge 

merge 1:1 date_monthly using "$temp_dir/atl_fed_data.dta"
drop _merge bls_inflation 

merge 1:1 date_monthly using "$output_dir/data/org_weekly_earnings_dist_mon.dta"
drop YEAR MONTH
drop _merge 

merge 1:1 date_monthly using "$temp_dir/eu_micro_data.dta"

replace ue_rate_cps = ue_rate_cps * 100 
replace eu_rate_cps = eu_rate_cps * 100 

gen eu_quits_cps = eu_quits_all * 100 
drop eu_quits_all 

gen eu_layoff_cps = eu_layoff_all * 100 
drop eu_layoff_all 

gen eu_other_cps = eu_other_all * 100 
drop eu_other_all 

drop _merge 

merge 1:1 date_monthly using "$temp_dir/adp_wage_data.dta"
drop _merge 

merge 1:1 date_monthly using "$temp_dir/median_wgt.dta"
drop _merge 

* Save the dataset as a CSV file
export delimited using "$output_dir/data/all_data_monthly.csv", replace

*****************************************************
*****************************************************
gen date_quarterly = qofd(date_monthly)

* Format the new quarterly date variable
format date_quarterly %tq

drop date_monthly

* List all variables
ds

* Store the list of all variables
local all_vars `r(varlist)'

* Remove 'date_quarterly' from the list of variables to collapse
local all_vars_no_date_quarterly : subinstr local all_vars "date_quarterly" "", all

* Collapse all numeric variables except 'date_quarterly'
collapse (mean) `all_vars_no_date_quarterly', by(date_quarterly)

merge 1:1 date_quarterly using "$temp_dir/profit_share.dta" 
replace profit_share = profit_share * 100 
drop _merge 

keep date_quarterly ue_rate_cps ee_rate_cps profit_share

* Save the dataset as a CSV file
export delimited using "$output_dir/data/all_data_quarterly.csv", replace

