* Yash Singh 
* date: 7/26/24 
* this script classifies each worker in the CPS Outgoing Rotation Group into quintiles 

clear 
global data_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\raw_data"
global temp_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\temp"
global output_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\output"

use "$temp_dir/cps_basic_monthly.dta", clear 
keep if YEAR >= 2014
* Calculate average price index for Q1 2019 
preserve
use "$temp_dir/cpi_clean.dta", clear
keep if date_monthly >= td(01jan2019) & date_monthly <= td(01mar2019)
summarize cpi 
local price_index_q1_2019 = r(mean)
restore

keep YEAR MONTH date_monthly MISH CPSIDP WTFINL earn_wgt EARNWEEK2 HOURWAGE2 EMPSTAT LABFORCE EDUC UHRSWORKORG wkstat
*keep YEAR MONTH date_monthly MISH CPSIDP final_wgt EARNWEEK2 EARNWEEK HOURWAGE2 HOURWAGE EMPSTAT LABFORCE educ EARNWT UHRSWORKORG 

merge m:1 date_monthly using "$temp_dir/cpi_clean.dta", keep(match master) nogenerate

* some sample selection

* individuals are asked extensive questions (earnings/wages for us) during month 4 and 8 
keep if MISH == 4 | MISH == 8 

* we only observe earnings/wages for people who are employed and in the labor force 
keep if EMPSTAT == 10

* only look at full time workers 
keep if wkstat == 11

* drop missing and top coded weekly earnings - and weekly earnings that imply a nominal wage less than half the minimum wage (similar to Autor et al)

drop if EARNWEEK2 == 9999.99
drop if EARNWEEK2 > 2880


* Calculate real weekly and hourly earnings in 2019 dollars
rename EARNWEEK2 wkly_earn
rename HOURWAGE2 hrly_wage
*rename EARNWEEK wkly_earn
*rename HOURWAGE hrly_wage
rename UHRSWORKORG wkly_hours 



gen real_wkly_earn = (wkly_earn / cpi) * `price_index_q1_2019' 
gen real_hrly_wage = (hrly_wage/cpi) * `price_index_q1_2019' 
replace earn_wgt = int(earn_wgt)

* Weekly earnings decile 
preserve 
keep if YEAR > 2014
sort YEAR MONTH 
by YEAR MONTH: egen earn_decile = xtile(real_wkly_earn), nquantiles(10) weight(earn_wgt)
collapse (mean) real_wkly_earn, by(YEAR MONTH date_monthly earn_decile)
reshape wide real_wkly_earn, i(YEAR MONTH date_monthly) j(earn_decile)

save "$output_dir/data/org_weekly_earnings_dist_mon.dta", replace 
export excel using "$output_dir/data/org_wkly_earnings_dist_mon.xlsx", firstrow(variables) replace


collapse (mean) real_wkly_earn1 real_wkly_earn2 real_wkly_earn3 real_wkly_earn4 real_wkly_earn5 real_wkly_earn6 real_wkly_earn7 real_wkly_earn8 real_wkly_earn9 real_wkly_earn10 , by(YEAR)
 

save "$output_dir/data/org_weekly_earnings_dist_yr.dta", replace 
export excel using "$output_dir/data/org_wkly_earnings_dist_yr.xlsx", firstrow(variables) replace
restore 

* Hourly wage decile 
preserve 
keep if YEAR > 2014
sort YEAR MONTH 
by YEAR MONTH: egen earn_decile = xtile(real_hrly_wage), nquantiles(10) weight(earn_wgt)
collapse (mean) real_hrly_wage, by(YEAR MONTH date_monthly earn_decile)
reshape wide real_hrly_wage, i(YEAR MONTH date_monthly) j(earn_decile)

save "$output_dir/data/org_hrly_wage_dist_mon.dta", replace 
export excel using "$output_dir/data/org_hrly_wage_dist_mon.xlsx", firstrow(variables) replace
restore 


* Weekly Earnings Percentiles 
preserve 
collapse (p95) p95 = real_wkly_earn (p90) p90 = real_wkly_earn (p80) p80 = real_wkly_earn (p70) p70 = real_wkly_earn (p60) p60 = real_wkly_earn (p50) p50 = real_wkly_earn (p40) p40 = real_wkly_earn (p30) p30 = real_wkly_earn (p20) p20 = real_wkly_earn (p10) p10 = real_wkly_earn [fw=earn_wgt], by (YEAR MONTH date_monthly)

save "$output_dir/data/org_weekly_earnings_percentiles_mon.dta", replace 
export excel using "$output_dir/data/org_wkly_earnings_percentiles_mon.xlsx", firstrow(variables) replace
restore 

** Hourly Wage Percentiles 
preserve 
collapse (p95) p95 = real_hrly_wage (p90) p90 = real_hrly_wage (p80) p80 = real_hrly_wage (p70) p70 = real_hrly_wage (p60) p60 = real_hrly_wage (p50) p50 = real_hrly_wage (p40) p40 = real_hrly_wage (p30) p30 = real_hrly_wage (p20) p20 = real_hrly_wage (p10) p10 = real_hrly_wage [fw=earn_wgt], by (YEAR MONTH date_monthly)

save "$output_dir/data/org_hrly_wage_percentiles_mon.dta", replace 
restore 





/*
************************************************
* Hourly Wages - ORG 
************************************************
preserve 
gen real_hrly_wage = real_wkly_earn / wkly_hours 
drop if UHRSWORKORG > 168 
drop if UHRSWORKORG < 35
collapse (p90) p90 = real_hrly_wage (p80) p80 = real_hrly_wage (p70) p70 = real_hrly_wage (p60) p60 = real_hrly_wage (p50) p50 = real_hrly_wage (p40) p40 = real_hrly_wage (p30) p30 = real_hrly_wage (p20) p20 = real_hrly_wage (p10) p10 = real_hrly_wage (p05) p05= real_hrly_wage [fw=earn_wgt], by (YEAR MONTH date_monthly)

save "$output_dir/data/org_hrly_earnings_dist_mon.dta", replace 

graph export "$output_dir/figures/org_hrly_earnings_ratios.pdf", replace	
restore 
***********************************************************************************
*/ 


/*
************************************************
* Hourly Wages - ORG 
************************************************
preserve 
keep if real_hrly_wage > 3
collapse (p90) p90 = real_hrly_wage (p80) p80 = real_hrly_wage (p70) p70 = real_hrly_wage (p60) p60 = real_hrly_wage (p50) p50 = real_hrly_wage (p40) p40 = real_hrly_wage (p30) p30 = real_hrly_wage (p20) p20 = real_hrly_wage (p10) p10 = real_hrly_wage (p05) p05= real_hrly_wage [fw=earn_wgt], by (YEAR MONTH date_monthly)

save "$output_dir/data/org_hrly_earnings_dist_mon.dta", replace 

gen ratio_p90_p50 = p90 / p50
gen ratio_p50_p10 = p50 / p10

twoway (connected ratio_p90_p50 date_monthly, lcolor(red) mcolor(red) msymbol(triangle)) ///
       (connected ratio_p50_p10 date_monthly, lcolor(blue) mcolor(blue) msymbol(square)), ///
       title("Hourly Wages (ORG)") ///
       ytitle("Ratio") ///
       ylabel(, angle(horizontal)) ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
       xmtick(, nolabels ticks) ///
       xtitle("") ///
       legend(order(1 "P90/P50" 2 "P50/P10")) ///
       name(weekly_earnings_plot, replace)

graph export "$output_dir/figures/org_hrly_earnings_ratios.pdf", replace	
restore 

***************************************************
* Weekly Earnings - ORG 
****************************************************
preserve 
collapse (p90) p90 = real_wkly_earn (p80) p80 = real_wkly_earn (p70) p70 = real_wkly_earn (p60) p60 = real_wkly_earn (p50) p50 = real_wkly_earn (p40) p40 = real_wkly_earn (p30) p30 = real_wkly_earn (p20) p20 = real_wkly_earn (p10) p10 = real_wkly_earn [fw=earn_wgt], by (YEAR MONTH date_monthly)

save "$output_dir/data/org_weekly_earnings_dist_mon.dta", replace 
export excel using "$output_dir/data/org_wkly_earnings_dist_mon.xlsx", firstrow(variables) replace	


gen ratio_p90_p50 = p90 / p50
gen ratio_p50_p10 = p50 / p10

twoway (connected ratio_p90_p50 date_monthly, lcolor(red) mcolor(red) msymbol(triangle)) ///
       (connected ratio_p50_p10 date_monthly, lcolor(blue) mcolor(blue) msymbol(square)), ///
       title("Weekly Earnings (ORG)") ///
       ytitle("Ratio") ///
       ylabel(, angle(horizontal)) ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
       xmtick(, nolabels ticks) ///
       xtitle("") ///
       legend(order(1 "P90/P50" 2 "P50/P10")) ///
       name(weekly_earnings_plot, replace)
	   
graph export "$output_dir/figures/org_wkly_earnings_ratio.pdf", replace	
restore 
*/ 

* Step 7: Classify each worker into quartiles
egen year_month = group(YEAR MONTH)
levelsof year_month, local(ym)
gen real_earn_q = .
quietly foreach y of local ym {
    _pctile real_wkly_earn [pweight=earn_wgt] if year_month == `y', nquantiles(4)
    forvalues i = 1/3 {
        replace real_earn_q = `i' if year_month == `y' & real_wkly_earn <= r(r`i') & real_earn_q == .
    }
    replace real_earn_q = 4 if year_month == `y' & real_earn_q == .
}

* Step 8: Keep only necessary variables and remove duplicates
keep CPSIDP real_earn_q
duplicates drop
duplicates drop CPSIDP, force


* Step 9: Save the results
save "$temp_dir/org_workers_by_earn_quartile.dta", replace


 
***********************************************
***********************************************
* create the clean basic monthly file 

use "$temp_dir/cps_basic_monthly.dta", clear 

merge m:1 CPSIDP using "$temp_dir/org_workers_by_earn_quartile.dta"
drop _merge 

merge m:1 CPSIDP using "$temp_dir/asec_workers_by_earn_decile.dta"
drop if _merge == 2
drop _merge 

save "$temp_dir/cps_basic_monthly_matched.dta", replace 


















