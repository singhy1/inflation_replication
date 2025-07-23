
*********************************************************
* Micro Flows - Pre Period 
*********************************************************
global data_dir "/Users/giyoung/Downloads/inflation_replication/scripts/replication_final/data/moments/raw"
global temp_dir "/Users/giyoung/Downloads/inflation_replication/scripts/replication_final/data/moments/temp"
global output_dir "/Users/giyoung/Downloads/inflation_replication/scripts/replication_final/data/moments/output"

use "$temp_dir/gross_flows_v1.dta", clear

rename Date date_monthly 
rename Year year 

keep if year >=2016
keep if year <= 2019
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

*** Pre-Period Averages *** 
preserve 
collapse (mean) ee ue eu_tot 
gen period = "pre"
save "$temp_dir/pre_period_micro_average.dta", replace  
restore 

*** Pre-Period Aggregates ***

* EU and UE 
preserve 
import delimited "$data_dir/shimer_decomposition_data.csv", clear

gen date_new = date(date, "YMD")
format date_new %td
drop date 
rename date_new date 

keep if date >= date("2016-01-01", "YMD") & date <= date("2019-12-31", "YMD")

rename seperation_rate eu
rename job_finding_rate ue

collapse (mean) eu_macro = eu ue_macro = ue u_rate_bls = u_rate 
gen period = "pre"
gen u_rate_macro = eu_macro / (eu_macro + ue_macro) 

save "$temp_dir/pre_period_macro_average_1.dta", replace 
restore 

* ee average 
preserve 
import delimited "$data_dir/ee_monthly.csv", clear

gen date_new = date(date_monthly, "YMD")
format date_new %td
drop date_monthly 
rename date_new date 

keep if date >= date("2016-01-01", "YMD") & date <= date("2019-12-31", "YMD")

collapse (mean) ee_macro = ee_pol 
gen period = "pre"
save "$temp_dir/pre_period_macro_average_2.dta", replace 
restore 

preserve 
use "$temp_dir/pre_period_micro_average.dta", clear 
merge 1:1 period using "$temp_dir/pre_period_macro_average_2.dta"
drop _merge 
merge 1:1 period using "$temp_dir/pre_period_macro_average_1.dta"


gen eu_scale = eu_macro / eu_tot
gen ue_scale = ue_macro / ue
gen ee_scale = (ee_macro/100) / ee

keep eu_scale ue_scale ee_scale 
save "$temp_dir/scaling_factors.dta", replace 
restore 

append using "$temp_dir/scaling_factors.dta"

replace eu_scale = eu_scale[11]
replace ee_scale = ee_scale[11]
replace ue_scale = ue_scale[11]

replace ee = ee*ee_scale

replace eu_quits = eu_quits * eu_scale
replace eu_layoffs = eu_layoffs * eu_scale
replace eu_other = eu_other * eu_scale

replace ue = ue * ue_scale

replace eu_tot = eu_quits + eu_layoffs + eu_other

gen u_rate = eu_tot / (eu_tot + ue)  

gen quit_share = eu_quits/eu_tot
gen layoff_share = eu_layoffs/eu_tot
gen other_share = eu_other / eu_tot 

keep decile ee eu_quits eu_layoffs eu_other ue eu_tot u_rate quit_share layoff_share other_share
drop if missing(decile)
describe
export delimited using "$output_dir/flow_moments.csv", replace nolabel 
