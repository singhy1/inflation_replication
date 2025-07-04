* Yash Singh 
* date: 7/11/24 
* goal: this script allocates each worker in the ASEC into an weekly earnings decile and 
* generates the cx weekly earnings distribution. 

* step 1: get the cpi 

clear
global data_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\raw_data"
global temp_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\temp"
global output_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\output"


* Step 1: Bring in the CPI for urban consumers 
import excel "$data_dir/CPI/CPIAUCSL.xls", cellrange(A11) firstrow clear


* Rename columns
rename observation_date date_monthly
rename CPIAUCSL cpi

format date_monthly %td

sort date_monthly
gen inflation_4m = (cpi / cpi[_n-4] - 1) * 100 if _n > 4
gen inflation_12m = (cpi / cpi[_n-12] - 1) * 100 if _n > 12


gen cpi_12m_lag = cpi[_n-12] if _n > 12

gen year = year(date_monthly)

bysort year: egen avg_cpi_12m_lag = mean(cpi_12m_lag)


save "$temp_dir/cpi_clean.dta", replace


* step 2: merge the cpi with asec sample 

use "$temp_dir/asec.dta", clear 

gen date_monthly = mdy(MONTH, 1, YEAR)
format date_monthly %td

* Step 3: Calculate average price index for Q1 2019
preserve
use "$temp_dir/cpi_clean.dta", clear
keep if date_monthly >= td(01jan2019) & date_monthly <= td(01mar2019)
summarize cpi
local price_index_q1_2019 = r(mean)
restore

* Step 4: Merge CPS data with CPI data
merge m:1 date_monthly using "$temp_dir/cpi_clean.dta", keep(match master) nogenerate

* Step 5: Calculate real weekly and hourly earnings in 2019 dollars
gen real_anl_inc = (INCWAGE / avg_cpi_12m_lag) * `price_index_q1_2019'
gen real_wkly_earn = (weekly_earnings / avg_cpi_12m_lag ) * `price_index_q1_2019'
*gen real_hrly_earn = (hrly_earn / avg_cpi_12m_lag ) * `price_index_q1_2019'

gen log_real_anl_inc = log(real_anl_inc)
gen log_real_wkly_earn = log(real_wkly_earn)

gen final_wgt = int(ASECWT)

keep YEAR MONTH CPSIDP final_wgt AGE real_anl_inc log_real_anl_inc real_wkly_earn log_real_wkly_earn

* Step 6: Get weekly earnings by dceile  

*** WEEKLY EARNINGS **** 
preserve 
sort YEAR 
by YEAR: egen earn_decile = xtile(real_wkly_earn), nquantiles(10) weight(final_wgt)

collapse (mean) real_wkly_earn, by(YEAR earn_decile)

reshape wide real_wkly_earn, i(YEAR) j(earn_decile)

rename YEAR smpl_yr 
gen report_yr = smpl_yr[_n-1]
drop if missing(report_yr)
drop if report_yr < 2016


save "$output_dir/data/asec_weekly_earnings_dist.dta", replace 
export excel using "$output_dir/data/asec_wkly_earnings_dist.xlsx", firstrow(variables) replace
restore 

* step 7: get weekly earnings by percentiles 

* All workers (25-55)
preserve 
*keep if real_hrly_earn > 3.75
keep if YEAR <= 2020
keep if YEAR >= 2016
collapse (p95) p95 = log_real_wkly_earn (p90) p90 = log_real_wkly_earn (p50) p50 = log_real_wkly_earn (p10) p10 = log_real_wkly_earn (sd) sd_log_real_wkly_earn = log_real_wkly_earn [fw=final_wgt], by (YEAR)
gen age_grp = "25-55"
save "$temp_dir/wkly_earn_moments_all.dta", replace 
restore 

* Young Workers (25-27)
preserve 
*keep if real_hrly_earn > 3.75
keep if YEAR <= 2020
keep if YEAR >= 2017
keep if AGE <= 27
collapse (p95) p95 = log_real_wkly_earn (p90) p90 = log_real_wkly_earn (p50) p50 = log_real_wkly_earn (p10) p10 = log_real_wkly_earn (p05) p05 = log_real_wkly_earn (sd) sd_log_real_wkly_earn = log_real_wkly_earn [fw=final_wgt], by (YEAR)


gen age_grp = "25-27"
save "$temp_dir/wkly_earn_moments_young_age.dta", replace 
restore 

* Old Workers (53-55)
preserve 
*keep if real_hrly_earn > 3.75
keep if YEAR <= 2020
keep if YEAR >= 2016
keep if AGE >=53 
collapse (p95) p95 = log_real_wkly_earn (p90) p90 = log_real_wkly_earn (p50) p50 = log_real_wkly_earn (p10) p10 = log_real_wkly_earn (p05) p05 = log_real_wkly_earn (sd) sd_log_real_wkly_earn = log_real_wkly_earn [fw=final_wgt], by (YEAR)
gen age_grp = "53-55"
save "$temp_dir/wkly_earn_moments_old_age.dta", replace 
restore 

preserve 
use "$temp_dir/wkly_earn_moments_all.dta", clear
append using "$temp_dir/wkly_earn_moments_young_age.dta"
append using "$temp_dir/wkly_earn_moments_old_age.dta"

collapse (mean) p95 p90 p50 p10 p05 sd_log, by(age_grp)
gen ratio_p95_p50 = p95 / p50 
gen ratio_p90_p50 = p90 / p50
gen ratio_p50_p10 = p50 / p10


gen wage_measure = "wkly"
save "$temp_dir/wkly_earn_moments.dta", replace 
restore 

/*
*******************************************************************
*******************************************************************

* step 7: get hourly earnings by percentiles 

* All workers (25-55)
preserve 
*keep if real_hrly_earn > 3.75
keep if YEAR <= 2020
keep if YEAR >= 2017
gen log_real_hrly_earn = log(real_hrly_earn)
collapse (p95) p95 = real_hrly_earn (p90) p90 = real_hrly_earn (p50) p50 = real_hrly_earn (p10) p10 = real_hrly_earn (sd) sd_log_real_hrly_earn = log_real_hrly_earn [fw=final_wgt], by (YEAR)
gen age_grp = "25-55"
save "$temp_dir/hrly_earn_moments_all.dta", replace 
restore 

* Young Workers (25-27)
preserve 
*keep if real_hrly_earn > 3.75
keep if YEAR <= 2020
keep if YEAR >= 2017
keep if AGE <= 27
gen log_real_hrly_earn = log(real_hrly_earn)
collapse (p95) p95 = real_hrly_earn (p90) p90 = real_hrly_earn (p50) p50 = real_hrly_earn (p10) p10 = real_hrly_earn (sd) sd_log_real_hrly_earn = log_real_hrly_earn [fw=final_wgt], by (YEAR)
gen age_grp = "25-27"
save "$temp_dir/hrly_earn_moments_young_age.dta", replace 
restore 

* Old Workers (53-55)
preserve 
*keep if real_hrly_earn > 3.75
keep if YEAR <= 2020
keep if YEAR >= 2017
keep if AGE >=53 
gen log_real_hrly_earn = log(real_hrly_earn)
collapse (p95) p95 = real_hrly_earn (p90) p90 = real_hrly_earn (p50) p50 = real_hrly_earn (p10) p10 = real_hrly_earn (sd) sd_log_real_hrly_earn = log_real_hrly_earn [fw=final_wgt], by (YEAR)
gen age_grp = "53-55"
save "$temp_dir/hrly_earn_moments_old_age.dta", replace 
restore 

preserve 
use "$temp_dir/hrly_earn_moments_all.dta", clear
append using "$temp_dir/hrly_earn_moments_young_age.dta"
append using "$temp_dir/hrly_earn_moments_old_age.dta"

collapse (mean) p95 p90 p50 p10 sd_log_real_hrly_earn, by(age_grp)
gen ratio_p95_p50 = p95 / p50 
gen ratio_p90_p50 = p90 / p50
gen ratio_p50_p10 = p50 / p10
gen var_log_real_hrly_earn = sd_log_real_hrly_earn^2
gen wage_measure = "hrly"

save "$temp_dir/hrly_earn_moments.dta", replace 
restore 

preserve 
use "$temp_dir/hrly_earn_moments.dta", clear 
append using "$temp_dir/wkly_earn_moments.dta"
export excel using "$output_dir/data/earn_moments.xlsx", firstrow(variables) replace
restore 
*/ 

**********************************************
* Annual Income 
**********************************************

* step 7: get weekly earnings by percentiles 

* All workers (25-55)
preserve 
*keep if real_hrly_earn > 3.75
keep if YEAR <= 2020
keep if YEAR >= 2017

collapse (p95) p95 = log_real_anl_inc (p90) p90 = log_real_anl_inc (p50) p50 = log_real_anl_inc (p10) p10 = log_real_anl_inc (sd) sd_log_anl_real_inc = log_real_anl_inc [fw=final_wgt], by (YEAR)

gen var_log_real_anl_inc = sd_log_anl_real_inc^2 

gen age_grp = "25-55"
save "$temp_dir/anl_earn_moments_all.dta", replace 
restore 

* Young Workers (25-27)
preserve 
*keep if real_hrly_earn > 3.75
keep if YEAR <= 2020
keep if YEAR >= 2017
keep if AGE <= 27


collapse (p95) p95 = log_real_anl_inc (p90) p90 = log_real_anl_inc (p50) p50 = log_real_anl_inc (p10) p10 = log_real_anl_inc (sd) sd_log_anl_real_inc = log_real_anl_inc [fw=final_wgt], by (YEAR)

gen var_log_real_anl_inc = sd_log_anl_real_inc^2 
gen age_grp = "25-27"

save "$temp_dir/anl_earn_moments_young_age.dta", replace 
restore 

* Old Workers (53-55)
preserve 
*keep if real_hrly_earn > 3.75
keep if YEAR <= 2020
keep if YEAR >= 2017
keep if AGE >=53 


collapse (p95) p95 = log_real_anl_inc (p90) p90 = log_real_anl_inc (p50) p50 = log_real_anl_inc (p10) p10 = log_real_anl_inc (sd)sd_log_anl_real_inc = log_real_anl_inc [fw=final_wgt], by (YEAR)

gen var_log_real_anl_inc = sd_log_anl_real_inc^2 

gen age_grp = "53-55"
save "$temp_dir/anl_earn_moments_old_age.dta", replace 
restore 


preserve 
use "$temp_dir/anl_earn_moments_all.dta", clear
append using "$temp_dir/anl_earn_moments_young_age.dta"
append using "$temp_dir/anl_earn_moments_old_age.dta"

collapse (mean) p95 p90 p50 p10 sd_log var_log_real_anl_inc, by(age_grp)
gen ratio_p95_p50 = p95 / p50 
gen ratio_p90_p50 = p90 / p50
gen ratio_p50_p10 = p50 / p10

gen wage_measure = "annual"
save "$temp_dir/anl_earn_moments.dta", replace 
restore 








/*
preserve 
*keep if real_hrly_earn > 4.5
collapse (p98) p98 = real_wkly_earn (p95) p95 = real_wkly_earn (p90) p90 = real_wkly_earn (p80) p80 = real_wkly_earn (p70) p70 = real_wkly_earn (p60) p60 = real_wkly_earn (p50) p50 = real_wkly_earn (p40) p40 = real_wkly_earn (p30) p30 = real_wkly_earn (p20) p20 = real_wkly_earn (p10) p10 = real_wkly_earn (p05) p05= real_wkly_earn [fw=final_wgt], by (YEAR)
save "$output_dir/data/asec_weekly_earnings_dist.dta", replace 
export excel using "$output_dir/data/asec_wkly_earnings_dist.xlsx", firstrow(variables) replace

use "$output_dir/data/asec_weekly_earnings_dist.dta", clear 

gen ratio_p90_p50 = p90 / p50
gen ratio_p50_p10 = p50 / p10

* Create the plot
twoway (connected ratio_p90_p50 YEAR, lcolor(red) mcolor(red) msymbol(triangle)) ///
       (connected ratio_p50_p10 YEAR, lcolor(blue) mcolor(blue) msymbol(square)), ///
       title("Weekly Earnings (ASEC)") ///
       ytitle("Ratio") ///
       xtitle("Year") ///
       legend(order(1 "P90/P50" 2 "P50/P10")) ///
	   ylabel(2.25(0.25)3, angle(horizontal)) ///
       xlabel(, angle(45)) ///
       yscale(range(2 3)) ///
	   name(mygraph, replace)

	   
graph export "$output_dir/figures/asec_wkly_earnings_ratios.pdf", replace
restore 

**** HOURLY WAGE *****

preserve 
keep if real_hrly_earn >= 4

collapse (p98) p98 = real_hrly_earn (p95) p95 = real_hrly_earn (p90) p90 = real_hrly_earn (p80) p80 = real_hrly_earn (p70) p70 = real_hrly_earn (p60) p60 = real_hrly_earn (p50) p50 = real_hrly_earn (p40) p40 = real_hrly_earn (p30) p30 = real_hrly_earn (p20) p20 = real_hrly_earn (p10) p10 = real_hrly_earn (p05) p05= real_hrly_earn [fw=final_wgt], by (YEAR)

save "$output_dir/data/asec_hrly_earnings_dist.dta", replace 

use "$output_dir/data/asec_hrly_earnings_dist.dta", clear 


gen ratio_p90_p50 = p90 / p50
gen ratio_p50_p10 = p50 / p10

* Create the plot
twoway (connected ratio_p90_p50 YEAR, lcolor(red) mcolor(red) msymbol(triangle)) ///
       (connected ratio_p50_p10 YEAR, lcolor(blue) mcolor(blue) msymbol(square)), ///
       title("Hourly Wages (ASEC)") ///
       ytitle("Ratio") ///
       xtitle("Year") ///
       legend(order(1 "P95/P50" 2 "P50/P10")) ///
	   ylabel(2(0.25)3, angle(horizontal)) ///
       xlabel(, angle(45)) ///
	   name(mygraph, replace)
graph export "$output_dir/figures/asec_hrly_earnings_ratios_over_time.pdf", replace	   
restore 











* Calculate all percentiles
forvalues i = 1/99 {
    _pctile real_wkly_earn [aw=final_wgt], p(`i')
    gen p`i' = r(r1)
}

* Calculate averages for 10 bins
forvalues i = 1/10 {
    local lower = (`i' - 1) * 10
    local upper = `i' * 10
    egen avg_earn_`lower'_`upper' = mean(real_wkly_earn) if inrange(percentile, `lower', `upper') [aw=final_wgt]
}

* Collapse to get one observation per year
collapse (mean) p1-p99 avg_earn_*, by(YEAR)
*/ 


* Step 7: Classify each worker into deciles
egen year_month = group(YEAR MONTH)
levelsof year_month, local(ym)

gen real_earn_d = .

quietly foreach y of local ym {
    _pctile real_wkly_earn [pweight=final_wgt] if year_month == `y', nquantiles(10)
    forvalues i = 1/9 {
        replace real_earn_d = `i' if year_month == `y' & real_wkly_earn <= r(r`i') & real_earn_d == .
    }
    replace real_earn_d = 10 if year_month == `y' & real_earn_d == .
}

* Step 8: Keep only necessary variables and remove duplicates
keep CPSIDP real_earn_d
duplicates drop
duplicates drop CPSIDP, force

* Step 9: Save the results
save "$temp_dir/asec_workers_by_earn_decile.dta", replace



