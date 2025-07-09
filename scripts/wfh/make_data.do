* Yash Singh 
* inputs: atlFed_wage_data_16t24.dta - filter out Blanco's full data to be only 2016-2024, 
* and workers in the labor force (ie assigned wage group)

global proj_dir "C:/Users/singhy/Dropbox/Labor_Market_PT/replication/empirical" 

* bring in the Dingel-Neiman work from home measures 
import delimited "$proj_dir/inputs/raw_data/DingelNeiman/onet_teleworkable_blscodes.csv", clear 
rename occ_code oes_occ_code 
save "$proj_dir/temp/onet_teleworkable_blscodes.dta", replace 


use "$proj_dir/outputs/atl_fed/atlFed_wage_data_16t24.dta", clear

* wage group 
gen wagegroup_num = real(regexs(1)) if regexm(wagegroup, "^([0-9]+)")


* Create education group based on numeric codes
gen str15 educ_group = ""
replace educ_group = "Bachelors+" if inlist(educ92, 6, 7)
replace educ_group = "Less than Bachelors" if inlist(educ92, 1, 2, 3, 4, 5)


* Create a string variable to hold the label
gen str occ_lbl = ""

* Loop through all unique values of occ and assign labels
levelsof occ, local(occs)
foreach x of local occs {
    local lbl : label peio1ocd `x'
    replace occ_lbl = "`lbl'" if occ == `x'
}

* Extract OES occupation code from label (e.g., 35-2010)
gen str oes_occ_code = ""
replace oes_occ_code = regexs(1) if regexm(occ_lbl, "([0-9]{2}-[0-9]{4})")

gen str occ_clean = regexs(1) if regexm(occ_lbl, "^(.*?)[\s\(]+[0-9]{2}-[0-9]{4}\)?$")

merge m:1 oes_occ_code using "$proj_dir/temp/onet_teleworkable_blscodes.dta"

/*
*******************************************************************************
* custom mapping of codes given by Atl Fed and OES occupational codes 

replace oes_occ_code = "15-1131" if occ_lbl == "Software developers, applications and systems software 15-113X"

* the actual codes 
* 15-1131 : Computer Programmers
* 15-1132 : Software Developers, Applications
* 15-1133 : Software Developers, Systems Software
* 15-1134 : Web Developers

* we aggregate these codes into a single code since this is what Atl fed does 
* all the codes have teleworkable value of 1 so it does not really matter that we 
* do this aggregation 

replace oes_occ_code = "49-9041"  if occ_lbl == "Industrial and refractory machinery mechanics 49-904X"



replace oes_occ_code = "31-201X"  if occ_lbl == "Janitors and building cleaners 31-201X"

replace oes_occ_code = "21-109X"  if occ_lbl == "Miscellaneous community and social service specialists, including health educators and community health workers 21-109X"
replace oes_occ_code = "5630"     if occ_lbl == "5630"
replace oes_occ_code = "31-909X"  if occ_lbl == "Miscellaneous healthcare support occupations, including medical equipment preparers 31-909X"
replace oes_occ_code = "9050"     if occ_lbl == "9050"
replace oes_occ_code = "25-90XX"  if occ_lbl == "Other education, training, and library workers 25-90XX"
replace oes_occ_code = "2720"     if occ_lbl == "2720"
replace oes_occ_code = "1106"     if occ_lbl == "1106"
replace oes_occ_code = "49-909X"  if occ_lbl == "Other installation, maintenance, and repair workers 49-909X"
replace oes_occ_code = "47-50XX"  if occ_lbl == "Other extraction workers 47-50XX"
replace oes_occ_code = "33-909X"  if occ_lbl == "Lifeguards and other recreational and all other protective service workers 33-909X"
replace oes_occ_code = "53-60XX"  if occ_lbl == "Other transportation workers 53-60XX"
replace oes_occ_code = "53-40XX"  if occ_lbl == "Subway, streetcar, and other rail transportation workers 53-40XX"
replace oes_occ_code = "39-40XX"  if occ_lbl == "Embalmers and funeral attendants 39-40XX"
replace oes_occ_code = "49-209X"  if occ_lbl == "Electrical and electronics repairers, industrial and utility 49-209X"
*/ 

keep if _merge == 3
drop _merge 

* Define 3 periods 
gen pre_period  = inrange(date_monthly, tm(2016m1), tm(2019m12))
gen inf_period  = inrange(date_monthly, tm(2021m4), tm(2023m5))
gen post_period = inrange(date_monthly, tm(2023m6), tm(2024m12))

gen str10 period = ""
replace period = "pre"  if pre_period == 1
replace period = "inf"  if inf_period == 1
replace period = "post" if post_period == 1
drop if period == ""  // removes obs not in any period

save "$proj_dir/temp/atl_cps_matched_dingel_neiman.dta", replace 