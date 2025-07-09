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