* Yash Singh

global temp_dir   "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\temp"
global output_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\output"

* ------------------------------------------------------
* Part 1: Group-specific averages by SEX and EDUC
* ------------------------------------------------------
use "$temp_dir/cps_basic_monthly.dta", clear

gen emp_flag = (EMPSTAT >= 10 & EMPSTAT <= 12)

gen pre_period = (date_monthly >= td(01jan2016) & date_monthly <= td(01dec2019))
gen inf_period = (date_monthly >= td(01apr2021) & date_monthly <= td(01may2023))
keep if pre_period == 1 | inf_period == 1

bysort date_monthly educ SEX: egen emp_stock = total(compwt * emp_flag)
bysort date_monthly educ SEX: egen pop = total(compwt)
gen emp_pop_ratio = emp_stock / pop

gen period = .
replace period = 0 if pre_period == 1
replace period = 1 if inf_period == 1

collapse (mean) emp_pop_ratio, by(SEX educ period)

reshape wide emp_pop_ratio, i(SEX educ) j(period)

rename emp_pop_ratio0 pre_2016_2019
rename emp_pop_ratio1 inf_2021_2023

tempfile group_table
save `group_table'

* ------------------------------------------------------
* Part 2: Pooled average (all SEX and EDUC)
* ------------------------------------------------------
use "$temp_dir/cps_basic_monthly.dta", clear

gen emp_flag = (EMPSTAT >= 10 & EMPSTAT <= 12)

gen pre_period = (date_monthly >= td(01jan2016) & date_monthly <= td(01dec2019))
gen inf_period = (date_monthly >= td(01apr2021) & date_monthly <= td(01may2023))
keep if pre_period == 1 | inf_period == 1

bysort date_monthly: egen emp_stock = total(compwt * emp_flag)
bysort date_monthly: egen pop = total(compwt)
gen emp_pop_ratio = emp_stock / pop

gen period = .
replace period = 0 if pre_period == 1
replace period = 1 if inf_period == 1

collapse (mean) emp_pop_ratio, by(period)

* Manually reshape into one row with two columns
gen pre_2016_2019 = .
gen inf_2021_2023 = .

replace pre_2016_2019 = emp_pop_ratio if period == 0
replace inf_2021_2023 = emp_pop_ratio if period == 1

* Keep one row that has both values
collapse (mean) pre_2016_2019 inf_2021_2023

gen SEX = .
gen educ = .

tempfile pooled
save `pooled'

* ------------------------------------------------------
* Part 3: Combine and export
* ------------------------------------------------------
use `group_table', clear
append using `pooled'

order SEX educ pre_2016_2019 inf_2021_2023

export delimited using "$output_dir/emp_to_pop_table.csv", replace
