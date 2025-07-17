* Yash Singh 
* goal: take inputs from make_data, and make summary stats for switcher/stayer in pre/inflation/full post period 

global proj_dir "C:/Users/singhy/Dropbox/Labor_Market_PT/replication/empirical" 

use "$proj_dir/temp/atl_cps_matched_dingel_neiman.dta", clear 

* Pr(Sex | Period, Switcher)
preserve 
collapse (sum) weight = weightbls98, by(jstayergroup period gengroup)
gen total_weight = .
bysort jstayergroup period (gengroup): replace total_weight = sum(weight)
bysort jstayergroup period (gengroup): replace total_weight = total_weight[_N]
gen gender_share = weight / total_weight
restore 

* Pr(Education | Period, Switcher)
preserve 
collapse (sum) weight = weightbls98, by(jstayergroup period educ_group)
gen total_weight = .
bysort jstayergroup period (educ_group): replace total_weight = sum(weight)
bysort jstayergroup period (educ_group): replace total_weight = total_weight[_N]
gen educ_share = weight / total_weight
restore 
*****************************************


* race group 
preserve 
collapse (sum) weight = weightbls98, by(jstayergroup period racegroup)
gen total_weight = .
bysort jstayergroup period (racegroup): replace total_weight = sum(weight)
bysort jstayergroup period (racegroup): replace total_weight = total_weight[_N]

* Step 3: Calculate gender share
gen race_share = weight / total_weight
restore 

* teleworkable 
preserve 
collapse (mean) telework_share = teleworkable [fw=int(weightbls98)], by(jstayergroup period)
restore 

* Age 
preserve 
collapse (mean) avg_age = age [fw=int(weightbls98)], by(jstayergroup period)
restore 

* wage group 
preserve 
collapse (mean) avg_wage_quartile = wagegroup_num [fw=int(weightbls98)], by(jstayergroup period)
restore 

****************************************************************************************
****************************************************************************************


* Pr(Switch | period, education)
preserve 
collapse (sum) weight = weightbls98, by(jstayergroup period educ_group)

gen total_group_weight = .
bysort period educ_group (jstayergroup): replace total_group_weight = sum(weight)
bysort period educ_group (jstayergroup): replace total_group_weight = total_group_weight[_N]

gen switch_stay_share = weight / total_group_weight
restore 


********* Giyoung's Code *******************************************************

use "$proj_dir/temp/atl_cps_matched_dingel_neiman.dta", clear 

*** Task: Check all P(Demographic | Period, Switcher) holds the same across different periods

* 1. By Gender Group
preserve
collapse (sum) weight = weightbls98, by(jstayergroup period gengroup date_monthly)
gen total_weight = .
bysort jstayergroup period date_monthly (gengroup): replace total_weight = sum(weight)
bysort jstayergroup period date_monthly (gengroup): replace total_weight = total_weight[_N]
gen gender_share = weight / total_weight
drop if missing(period) // drop 2015 and 2020

gen i_inf = period == "inf"
gen i_post = period == "post"

reg gender_share i_inf i_post if jstayergroup == "Job Stayer"
reg gender_share i_inf i_post if jstayergroup == "Job Switcher"
restore

* 2. By Education Group
preserve
collapse (sum) weight = weightbls98, by(jstayergroup period educ_group date_monthly)
gen total_weight = .
bysort jstayergroup period date_monthly (educ_group): replace total_weight = sum(weight)
bysort jstayergroup period date_monthly (educ_group): replace total_weight = total_weight[_N]
gen educ_share = weight / total_weight
drop if missing(period) // drop 2015 and 2020

gen i_inf = period == "inf"
gen i_post = period == "post"

reg educ_share i_inf i_post if jstayergroup == "Job Stayer"
reg educ_share i_inf i_post if jstayergroup == "Job Switcher"
restore

* 3. By Race Group
preserve
collapse (sum) weight = weightbls98, by(jstayergroup period racegroup date_monthly)
gen total_weight = .
bysort jstayergroup period date_monthly (racegroup): replace total_weight = sum(weight)
bysort jstayergroup period date_monthly (racegroup): replace total_weight = total_weight[_N]
gen race_share = weight / total_weight
drop if missing(period) // drop 2015 and 2020

gen i_inf = period == "inf"
gen i_post = period == "post"

reg race_share i_inf i_post if jstayergroup == "Job Stayer"
reg race_share i_inf i_post if jstayergroup == "Job Switcher"
restore

* By (Binarized) Teleworkable
preserve
gen telegroup = teleworkable > 0.5
collapse (sum) weight = weightbls98, by(jstayergroup period telegroup date_monthly)
gen total_weight = .
bysort jstayergroup period date_monthly (telegroup): replace total_weight = sum(weight)
bysort jstayergroup period date_monthly (telegroup): replace total_weight = total_weight[_N]
gen tele_share = weight / total_weight
drop if missing(period) // drop 2015 and 2020

gen i_inf = period == "inf"
gen i_post = period == "post"

reg tele_share i_inf i_post if jstayergroup == "Job Stayer"
reg tele_share i_inf i_post if jstayergroup == "Job Switcher"
restore

* By Age
preserve
collapse (sum) weight = weightbls98, by(jstayergroup period age date_monthly)
gen total_weight = .
bysort jstayergroup period date_monthly (age): replace total_weight = sum(weight)
bysort jstayergroup period date_monthly (age): replace total_weight = total_weight[_N]
gen age_share = weight / total_weight
drop if missing(period) // drop 2015 and 2020

gen i_inf = period == "inf"
gen i_post = period == "post"

reg age_share i_inf i_post if jstayergroup == "Job Stayer"
reg age_share i_inf i_post if jstayergroup == "Job Switcher"
restore

* By Age Group 
preserve
gen age_group = .
replace age_group = 1 if inrange(age, 16, 24)
replace age_group = 2 if inrange(age, 25, 34)
replace age_group = 3 if inrange(age, 35, 44)
replace age_group = 4 if inrange(age, 45, 54)
replace age_group = 5 if age >= 55

collapse (sum) weight = weightbls98, by(jstayergroup period age_group date_monthly)
gen total_weight = .
bysort jstayergroup period date_monthly (age_group): replace total_weight = sum(weight)
bysort jstayergroup period date_monthly (age_group): replace total_weight = total_weight[_N]
gen age_group_share = weight / total_weight
drop if missing(period) // drop 2015 and 2020

gen i_inf = period == "inf"
gen i_post = period == "post"

reg age_group_share i_inf i_post if jstayergroup == "Job Stayer"
reg age_group_share i_inf i_post if jstayergroup == "Job Switcher"
restore

* By Wage Group
preserve
collapse (sum) weight = weightbls98, by(jstayergroup period wagegroup date_monthly)
gen total_weight = .
bysort jstayergroup period date_monthly (wagegroup): replace total_weight = sum(weight)
bysort jstayergroup period date_monthly (wagegroup): replace total_weight = total_weight[_N]
gen wage_share = weight / total_weight
drop if missing(period) // drop 2015 and 2020

gen i_inf = period == "inf"
gen i_post = period == "post"

reg wage_share i_inf i_post if jstayergroup == "Job Stayer"
reg wage_share i_inf i_post if jstayergroup == "Job Switcher"
restore


