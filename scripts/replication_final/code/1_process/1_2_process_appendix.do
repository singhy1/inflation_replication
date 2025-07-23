clear all
set more off

global data_dir "/Users/giyoung/Downloads/inflation_replication/scripts/replication_final/data/raw"
global output_dir "/Users/giyoung/Downloads/inflation_replication/scripts/replication_final/data/processed"

******* Figure B.5, Panel B, C ******************************************************

use "$data_dir/atl_fed/atl_fed_wage_raw.dta", clear

gen obs = 1

* Wage Growth by Quartile x jstayergroup
preserve 
* Take the median wage growth for each group
collapse (median) med_w_growth = wagegrowthtracker83 (sum) wgt = obs, ///
    by(date_monthly wagegroup jstayergroup)

* Sort to prepare for moving average
sort wagegroup jstayergroup date_monthly

* 3-month moving average
gen smoothed_med_w_growth = ( ///
    med_w_growth + ///
    med_w_growth[_n-1] + med_w_growth[_n-2] + med_w_growth[_n-3] + med_w_growth[_n-4] + med_w_growth[_n-5] + ///
    med_w_growth[_n-6] + med_w_growth[_n-7] + med_w_growth[_n-8] + med_w_growth[_n-9] + med_w_growth[_n-10] + ///
    med_w_growth[_n-11]) / 12


* Rename for consistency
rename smoothed_med_w_growth smwg

* Create group ID
gen group = wagegroup + "_" + jstayergroup
replace group = subinstr(group, " ", "_", .)


* Keep only necessary variables
keep date_monthly group smwg

* Reshape to wide format
reshape wide smwg, i(date_monthly) j(group) string

* Restrict to post-2016 period
keep if date_monthly >= tm(2016m1)

* now we have our wage growth measure for each wage group {1,2,3,4} x jstayergroup 
export delimited "$output_dir/figure_B_5_B_C.csv", replace 
restore 


******* Figure B.8 **************************************************************

use "$data_dir/atl_fed/atl_fed_wage_raw.dta", clear

* Create education group label based on numeric codes
gen educ_group_lbl = ""
replace educ_group_lbl = "Bachelors_plus" if inlist(educ92, 6, 7)
replace educ_group_lbl = "Less than Bachelors" if inlist(educ92, 1, 2, 3, 4, 5)

* Wage Growth by Quartile x education group 
preserve 
* Take the median wage growth for each group
collapse (median) med_w_growth = wagegrowthtracker83 (sum) wgt = obs, ///
    by(date_monthly wagegroup educ_group_lbl)

* Sort to prepare for moving average
sort wagegroup educ_group_lbl date_monthly

* 3-month moving average
gen smoothed_med_w_growth = ( ///
    med_w_growth + ///
    med_w_growth[_n-1] + med_w_growth[_n-2] + med_w_growth[_n-3] + med_w_growth[_n-4] + med_w_growth[_n-5] + ///
    med_w_growth[_n-6] + med_w_growth[_n-7] + med_w_growth[_n-8] + med_w_growth[_n-9] + med_w_growth[_n-10] + ///
    med_w_growth[_n-11]) / 12

* Rename for consistency
rename smoothed_med_w_growth smwg

* Create group ID
gen group = wagegroup + "_" + educ_group_lbl
replace group = subinstr(group, " ", "_", .)

* Keep only necessary variables
keep date_monthly group smwg

* Reshape to wide format
reshape wide smwg, i(date_monthly) j(group) string

* Restrict to post-2016 period
keep if date_monthly >= tm(2016m1)

* now we have our wage growth measure for each wage group {1,2,3,4} x work-from-home exposure group {low, high}
export delimited "$output_dir/figure_B_8_temp1.csv", replace 
restore 

* Pooled 

* Take the median wage growth for each group
collapse (median) med_w_growth = wagegrowthtracker83 (sum) wgt = obs, ///
    by(date_monthly wagegroup)

* Sort to prepare for moving average
sort wagegroup date_monthly

* 3-month moving average
gen smoothed_med_w_growth = ( ///
    med_w_growth + ///
    med_w_growth[_n-1] + med_w_growth[_n-2] + med_w_growth[_n-3] + med_w_growth[_n-4] + med_w_growth[_n-5] + ///
    med_w_growth[_n-6] + med_w_growth[_n-7] + med_w_growth[_n-8] + med_w_growth[_n-9] + med_w_growth[_n-10] + ///
    med_w_growth[_n-11]) / 12

* Rename for consistency
rename smoothed_med_w_growth smwg

gen group = wagegroup
replace group = subinstr(group, " ", "_", .)

* Keep only necessary variables
keep date_monthly group smwg

* Reshape to wide format
reshape wide smwg, i(date_monthly) j(group) string

* Restrict to post-2016 period
keep if date_monthly >= tm(2016m1)

* now we have our wage growth measure for each wage group {1,2,3,4} 
export delimited "$output_dir/figure_B_8_temp2.csv", replace 


