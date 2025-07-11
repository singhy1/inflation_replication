* Yash Singh
* run make data in the wfh folder before running this file 

global proj_dir "C:/Users/singhy/Dropbox/Labor_Market_PT/replication/empirical"

use "$proj_dir/temp/atl_cps_matched_dingel_neiman.dta", clear

* will use this variable to see the number of observations in each bin 
gen obs = 1

* create telworkable groups 
gen str6 tel_group = ""

replace tel_group = "no" if teleworkable == 0
replace tel_group = "some" if teleworkable > 0 & teleworkable < 1
replace tel_group = "high" if teleworkable == 1


* share of people in each teleworkable group (pooled across quartiles)
preserve 
collapse (sum) num_people = obs, by(tel_group)
egen tot_workers = total(num_people) 
gen tel_share = num_people / tot_workers
export delimited "$proj_dir/outputs/processed_data/pooled_tel_work_share.csv", replace 
restore 


* share of people in each wage group x teleworkable group 
preserve 
collapse (sum) num_people = obs, by(tel_group wagegroup)
bysort wagegroup: egen tot_workers = total(num_people)
gen tel_share = num_people / tot_workers
export delimited "$proj_dir/outputs/processed_data/wage_x_tel_work_group_share.csv", replace 
restore 


* we observe the Dingel-Neiman measure of exposure to teleworkability on the interval [0,1] so we split our sample into 
* 2 groups - high or some teleworkable exposure on (0,1] and no teleworkable {0}. 

replace teleworkable = ceil(teleworkable)

* Define a new label
label define teleworkable_lbl 0 "no_wfh" 1 "high_wfh"

* Apply it to the variable
label values teleworkable teleworkable_lbl



***** Wage Growth by Quartile x Education *****

* take the median wage growth for each group (this is consistent with the aggregation done by the atlanta fed for their aggregate series)

preserve 
collapse (median) med_w_growth = wagegrowthtracker83 (sum) wgt = obs, by(date_monthly wagegroup teleworkable)

* smooth the series 
sort wagegroup teleworkable date_monthly

* 3-month moving average
gen smoothed_med_w_growth = ( ///
    med_w_growth + ///
    med_w_growth[_n-1] + med_w_growth[_n-2] + med_w_growth[_n-3] + med_w_growth[_n-4] + med_w_growth[_n-5] + ///
    med_w_growth[_n-6] + med_w_growth[_n-7] + med_w_growth[_n-8] + med_w_growth[_n-9] + med_w_growth[_n-10] + ///
    med_w_growth[_n-11]) / 12


rename smoothed_med_w_growth smwg

decode teleworkable, gen(teleworkable_lbl)

gen group = wagegroup + "_" + teleworkable_lbl

keep date_monthly group smwg
reshape wide smw, i(date_monthly) j(group) string

keep if date_monthly >= tm(2016m1)

* now we have our wage growth measure for each wage group {1,2,3,4} x work-from-home exposure group {low, high}
export delimited "$proj_dir/temp/wfh_wage_growth_by_quartile.csv", replace 
restore 
******************************************************************************************


**** Pooled *****

preserve 
collapse (median) med_w_growth = wagegrowthtracker83 (sum) wgt = obs, by(date_monthly teleworkable)

* smooth the series 
sort teleworkable date_monthly

* 3-month moving average
gen smoothed_med_w_growth = ( ///
    med_w_growth + ///
    med_w_growth[_n-1] + med_w_growth[_n-2] + med_w_growth[_n-3] + med_w_growth[_n-4] + med_w_growth[_n-5] + ///
    med_w_growth[_n-6] + med_w_growth[_n-7] + med_w_growth[_n-8] + med_w_growth[_n-9] + med_w_growth[_n-10] + ///
    med_w_growth[_n-11]) / 12


rename smoothed_med_w_growth smwg

decode teleworkable, gen(teleworkable_lbl)

gen group = teleworkable_lbl

keep date_monthly group smwg
reshape wide smw, i(date_monthly) j(group) string

keep if date_monthly >= tm(2016m1)

* now we have our wage growth measure for each wage group {1,2,3,4} x work-from-home exposure group {low, high}
export delimited "$proj_dir/temp/wfh_wage_growth_pooled.csv", replace 
restore 
