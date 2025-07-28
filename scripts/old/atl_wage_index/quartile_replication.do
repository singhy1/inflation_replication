* Yash Singh
* Inputs: "raw" Atlanta Fed data

global proj_dir "C:/Users/singhy/Dropbox/Labor_Market_PT/replication/empirical"

use "$proj_dir/outputs/atl_fed/atlFed_wage_data_15t24.dta", clear


* Take the median wage growth for each group
*collapse (median) med_w_growth = wagegrowthtracker83 (sum) wgt = obs, ///
*    by(date_monthly wagegroup)

* Take the median wage growth for each group
collapse (median) med_w_growth = wagegrowth83 (sum) wgt = obs, ///
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

* Keep only necessary variables
keep date_monthly wagegroup smwg

* Reshape to wide format
reshape wide smwg, i(date_monthly) j(wagegroup) string

* Restrict to post-2016 period
keep if date_monthly >= tm(2016m1)

* now we have our wage growth measure for each wage group {1,2,3,4} x work-from-home exposure group {low, high}
export delimited "$proj_dir/temp/quartile_wage_growth.csv", replace 


