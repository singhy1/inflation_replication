* Yash Singh 
* this script computes the employment to population ratio for 25-55 year by (sex x schooling) groups 

* specify your directory
global path_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation"

global data_dir "${path_dir}\raw_data"
global temp_dir "${path_dir}\temp"
global output_dir "${path_dir}\output"


* data 
use "$temp_dir/employment_to_population_data.dta", clear 

gen emp_flag = (EMPSTAT >= 10 & EMPSTAT <= 12)

sort date_monthly educ SEX 

keep date_monthly educ SEX emp_flag WTFINL

* Jan 16 - Dec 19
gen pre_period = (date_monthly >= td(01jan2016) & date_monthly <= td(01dec2019))

* April 21 - May 23 
gen inf_period = (date_monthly >= td(01apr2021) & date_monthly <= td(01may2023))

* April 21 - Dec 24 
gen post_period = (date_monthly >= td(01apr2021) & date_monthly <= td(01Dec2024))

* April 21 - Dec 2021 
gen early_post_period = (date_monthly >= td(01apr2021) & date_monthly <= td(01Dec2021))

* Jan 22 - Dec 2024 
gen late_post_period = (date_monthly >= td(01jan2022) & date_monthly <= td(01Dec2024))


* aggregate employment to population - pre period 
preserve
by date_monthly: egen emp_stock = sum(WTFINL * emp_flag)
by date_monthly: egen pop = sum(WTFINL)
gen emp_pop_ratio = emp_stock / pop
collapse (mean) emp_pop_ratio, by(pre_period)
keep if pre_period == 1
gen period = "Pre-Period"
save temp_all_pre, replace
restore


* aggregate employment to population - inflation period 
preserve
by date_monthly: egen emp_stock = sum(WTFINL * emp_flag)
by date_monthly: egen pop = sum(WTFINL)
gen emp_pop_ratio = emp_stock / pop
collapse (mean) emp_pop_ratio, by(inf_period)
keep if inf_period == 1
gen period = "Inflation"
save temp_all_inflation, replace
restore



* employed and poulation stock by sex and education 
by date_monthly educ SEX: egen emp_stock = sum(WTFINL * emp_flag)
by date_monthly educ SEX: egen pop = sum(WTFINL)

collapse (mean) emp_stock pop, by(date_monthly educ SEX)
gen emp_pop_ratio = emp_stock / pop

* Jan 16 - Dec 19
gen pre_period = (date_monthly >= td(01jan2016) & date_monthly <= td(01dec2019))

* April 21 - May 23 
gen inf_period = (date_monthly >= td(01apr2021) & date_monthly <= td(01may2023))

* Step 1: Create a dataset for the Inflation Period
preserve
collapse (mean) emp_pop_ratio, by(SEX educ inf_period)
keep if inf_period == 1
gen period = "Inflation"
save temp_inflation, replace
restore

* Step 2: Create a dataset for the Pre-Period
collapse (mean) emp_pop_ratio, by(SEX educ pre_period)
keep if pre_period == 1
gen period = "Pre-Period"
save temp_preperiod, replace

* Step 3: Combine the datasets 
use temp_inflation, clear
append using temp_preperiod
append using temp_all_pre
append using temp_all_inflation

drop inf_period pre_period 

export delimited using "$output_dir\tables\emp_pop_ratio.csv", replace
