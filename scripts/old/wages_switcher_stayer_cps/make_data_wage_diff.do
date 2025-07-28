* Yash Singh 
* goal: get wage growth by jstayergroup x wage quartile 
* we want to make comparisons between switchers and stayers within initial wage quartiles 

global proj_dir "C:/Users/singhy/Dropbox/Labor_Market_PT/replication/empirical"

use "$proj_dir/outputs/atl_fed/atlFed_wage_data_15t24.dta", clear

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
export delimited "$proj_dir/outputs/processed_data/switcher_wage_growth_by_quartile.csv", replace 
restore 



