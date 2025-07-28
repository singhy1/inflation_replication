* Yash Singh 


global data_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\raw_data"
global temp_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\temp"

use "$temp_dir/cps_basic_monthly.dta", clear 

gen emp_flag = (EMPSTAT >= 10 & EMPSTAT <= 12)

sort date_monthly educ SEX 

* Pooled Average during pre period 
preserve 
by date_monthly: egen emp_stock = sum(compwt * emp_flag)
by date_monthly: egen pop = sum(compwt)

collapse (mean) emp_stock pop, by(date_monthly)
gen emp_pop_ratio = emp_stock / pop
gen pre_period = (date_monthly >= td(01jan2016) & date_monthly <= td(01dec2019))
collapse (mean) emp_pop_ratio, by(pre_period)
restore 

* Pooled Average during inflation period 
preserve 
by date_monthly: egen emp_stock = sum(compwt * emp_flag)
by date_monthly: egen pop = sum(compwt)

collapse (mean) emp_stock pop, by(date_monthly)
gen emp_pop_ratio = emp_stock / pop
gen inf_period = (date_monthly >= td(01apr2021) & date_monthly <= td(01may2023))
collapse (mean) emp_pop_ratio, by(inf_period)
restore 

* employed stock by sex and education 
by date_monthly educ SEX: egen emp_stock = sum(compwt * emp_flag)
by date_monthly educ SEX: egen pop = sum(compwt)

collapse (mean) emp_stock pop, by(date_monthly educ SEX)

gen emp_pop_ratio = emp_stock / pop

keep if date_monthly >= td(01jan2016)

gen pre_period = (date_monthly >= td(01jan2016) & date_monthly <= td(01dec2019))
gen inf_period = (date_monthly >= td(01apr2021) & date_monthly <= td(01may2023))

preserve 
collapse (mean) emp_pop_ratio, by(SEX educ inf_period)
keep if inf_period == 1
restore 

collapse (mean) emp_pop_ratio, by(SEX educ pre_period)
keep if pre_period == 1