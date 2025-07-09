* Yash Singh
* run make data in the wfh folder before running this file 

global proj_dir "C:/Users/singhy/Dropbox/Labor_Market_PT/replication/empirical"

use "$proj_dir/temp/atl_cps_matched_dingel_neiman.dta", clear

* will use this variable to see the number of observations in each bin 
gen obs = 1

* we observe the Dingel-Neiman measure of exposure to teleworkability on the interval [0,1] so we split our sample into 
* 2 groups - high teleworkable on [.5,1] and low teleworkable [0,.5]

replace teleworkable = round(teleworkable)

* Define a new label
label define teleworkable_lbl 0 "low_wfh" 1 "high_wfh"

* Apply it to the variable
label values teleworkable teleworkable_lbl


* take the median wage growth for each group (this is consistent with the aggregation done by the atlanta fed for their aggregate series)

collapse (median) med_w_growth = wagegrowthtracker83 (sum) wgt = obs, by(date_monthly wagegroup teleworkable)

* smooth the series 
sort wagegroup teleworkable date_monthly

* 3-month moving average (current + lag1 + lag2) / 3
gen smoothed_med_w_growth = (med_w_growth + med_w_growth[_n-1] +  med_w_growth[_n-2]) / 3
	
rename smoothed_med_w_growth smwg

decode teleworkable, gen(teleworkable_lbl)

gen group = wagegroup + "_" + teleworkable_lbl

keep date_monthly group smwg
reshape wide smw, i(date_monthly) j(group) string

keep if date_monthly >= tm(2016m1)

* now we have our wage growth measure for each wage group {1,2,3,4} x work-from-home exposure group {low, high}
export delimited "$proj_dir/temp/wfh_wage_growth.csv", replace 