* Yash Singh
* Inputs: "raw" Atlanta Fed data

global proj_dir "C:/Users/singhy/Dropbox/Labor_Market_PT/replication/empirical"

use "$proj_dir/outputs/atl_fed/atlFed_wage_data_15t24.dta", clear


* Create education group label based on numeric codes
gen educ_group_lbl = ""
replace educ_group_lbl = "Bachelors_plus" if inlist(educ92, 6, 7)
replace educ_group_lbl = "Less than Bachelors" if inlist(educ92, 1, 2, 3, 4, 5)


* share of people in each education group (pooled across quartiles)
preserve 
collapse (sum) num_people = obs, by(educ_group_lbl)
egen tot_workers = total(num_people) 
gen tel_share = num_people / tot_workers
export delimited "$proj_dir/outputs/processed_data/pooled_educ_work_share.csv", replace 
restore 


* share of people in each wage group x education group 
preserve 
collapse (sum) num_people = obs, by(educ_group_lbl wagegroup)
bysort wagegroup: egen tot_workers = total(num_people)
gen tel_share = num_people / tot_workers
export delimited "$proj_dir/outputs/processed_data/wage_x_educ__group_share.csv", replace 
restore 


******************************************************************

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
export delimited "$proj_dir/temp/educ_wage_growth_by_quartile.csv", replace 
restore 


******************************************************************

* Pooled 

******************************************************************

* Take the median wage growth for each group
collapse (median) med_w_growth = wagegrowthtracker83 (sum) wgt = obs, ///
    by(date_monthly educ_group_lbl)

* Sort to prepare for moving average
sort educ_group_lbl date_monthly

* 3-month moving average
gen smoothed_med_w_growth = ( ///
    med_w_growth + ///
    med_w_growth[_n-1] + med_w_growth[_n-2] + med_w_growth[_n-3] + med_w_growth[_n-4] + med_w_growth[_n-5] + ///
    med_w_growth[_n-6] + med_w_growth[_n-7] + med_w_growth[_n-8] + med_w_growth[_n-9] + med_w_growth[_n-10] + ///
    med_w_growth[_n-11]) / 12


* Rename for consistency
rename smoothed_med_w_growth smwg


gen group = educ_group_lbl
replace group = subinstr(group, " ", "_", .)

* Keep only necessary variables
keep date_monthly group smwg

* Reshape to wide format
reshape wide smwg, i(date_monthly) j(group) string

* Restrict to post-2016 period
keep if date_monthly >= tm(2016m1)

* now we have our wage growth measure for each wage group {1,2,3,4} x work-from-home exposure group {low, high}
export delimited "$proj_dir/temp/educ_wage_growth_pooled.csv", replace 


