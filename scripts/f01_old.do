* Yash Singh 
* date: 7/9/2024 
* get wage growth statistics for pre period, inflation period 

clear 
global data_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\raw_data"
global temp_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\temp"
global output_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\output"


use "$output_dir/data/org_weekly_earnings_dist_mon.dta", clear 
rename YEAR year 
rename MONTH month 
sort year month 

tsset date_monthly
sort year month

rename real_wkly_earn10 d10 
rename real_wkly_earn9 d9 
rename real_wkly_earn8 d8 
rename real_wkly_earn7 d7 
rename real_wkly_earn6 d6 
rename real_wkly_earn5 d5 
rename real_wkly_earn4 d4 
rename real_wkly_earn3 d3 
rename real_wkly_earn2 d2 
rename real_wkly_earn1 d1 



* 3 month moving average 
foreach var of varlist d10 d9 d8 d7 d6 d5 d4 d3 d2 d1 {
    generate `var'_avg3 = (`var' + `var'[_n-1] + `var'[_n-2] + `var'[_n-3] + `var'[_n-4] +  `var'[_n-5]) / 6
}

sort date_monthly
foreach var of varlist d10_avg3 d9_avg3 d8_avg3 d7_avg3 d6_avg3 d5_avg3 d4_avg3 d3_avg3 d2_avg3 d1_avg3 {
    gen `var'_1yr_grth = ((`var' - `var'[_n-12]) / `var'[_n-12])*100
	gen `var'_2yr_grth = ((`var' - `var'[_n-26]) / `var'[_n-26])*100
	gen `var'_3yr_grth = ((`var' - `var'[_n-38]) / `var'[_n-38])*100
	
    label variable `var'_1yr_grth "12-month cumulative growth rate of `var'"
	label variable `var'_2yr_grth "24-month cumulative growth rate of `var'"
	label variable `var'_3yr_grth "36-month cumulative growth rate of `var'"
}

**************************************************
* time series patterns for different by deciles 
**************************************************

sort date_monthly
keep if date_monthly >= td(01jan2016)

sum date_monthly
local start_date = r(min)
local end_date = r(max)
/*
// Create time series line plot for d10_avg3
twoway (line d10_avg3 date_monthly, lcolor(blue) lpattern(solid) lwidth(medium)), ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) /// Adjust x-axis labels for 90-day intervals
       ylabel(, format(%2.0f) angle(0)) /// Adjust y-axis labels
       xtitle("Date (Monthly)") ///
       ytitle("Growth") ///
       title("Time Series Plot of Growth by Deciles (D10)") ///
       legend(order(1 "D10") position(2) ring(0) bmargin(small)) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white)) ///

// Export the graph
graph export "$output_dir/figures/ts_deciles_d10.png", replace

// Create time series line plot for d5_avg3
twoway (line d5_avg3 date_monthly, lcolor(green) lpattern(solid) lwidth(medium)), ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) /// Adjust x-axis labels for 90-day intervals
       ylabel(, format(%2.0f) angle(0)) /// Adjust y-axis labels
       xtitle("Date (Monthly)") ///
       ytitle("Growth") ///
       title("Time Series Plot of Growth by Deciles (D5)") ///
       legend(order(1 "D5") position(2) ring(0) bmargin(small)) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white)) ///

// Export the graph
graph export "$output_dir/figures/ts_deciles_d5.png", replace

// Create time series line plot for d1_avg3
twoway (line d1_avg3 date_monthly, lcolor(red) lpattern(solid) lwidth(medium)), ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) /// Adjust x-axis labels for 90-day intervals
       ylabel(, format(%2.0f) angle(0)) /// Adjust y-axis labels
       xtitle("Date (Monthly)") ///
       ytitle("Growth") ///
       title("Time Series Plot of Growth by Deciles (D1)") ///
       legend(order(1 "D1") position(2) ring(0) bmargin(small)) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white)) ///

// Export the graph
graph export "$output_dir/figures/ts_deciles_d1.png", replace
*/ 

* Pre-period (February 1, 2019)
preserve
collapse (mean) d1 d2 d3 d4 d5 d6 d7 d8 d9 d10, by(year)
keep if year <= 2019
foreach var of varlist d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 {
	gen `var'_3yr_grth = ((`var' - `var'[_n-3]) / `var'[_n-3])*100
	drop `var'
}
drop if missing(d1_3yr_grth)

gen period = "Pre-period"
reshape long d@_3yr_grth, i(period) j(percentile)
rename d_3yr_grth growth
drop year 
save "$temp_dir/pre_period_rwgt.dta", replace
restore

* Inflation period (May 1, 2023)
preserve
keep if date_monthly == td(01may2023)

keep d10_avg3_2yr_grth d9_avg3_2yr_grth d8_avg3_2yr_grth d7_avg3_2yr_grth d6_avg3_2yr_grth d5_avg3_2yr_grth d4_avg3_2yr_grth d3_avg3_2yr_grth d2_avg3_2yr_grth d1_avg3_2yr_grth

gen period = "Inflation period"
reshape long d@_avg3_2yr_grth, i(period) j(percentile)
rename d_avg3_2yr_grth growth
save "$temp_dir/inflation_period_rwgt.dta", replace
restore

* Post-period (April 1, 2024)
preserve
keep if date_monthly == td(01may2024)
keep d10_avg3_3yr_grth d9_avg3_3yr_grth d8_avg3_3yr_grth d7_avg3_3yr_grth d6_avg3_3yr_grth d5_avg3_3yr_grth d4_avg3_3yr_grth d3_avg3_3yr_grth d2_avg3_3yr_grth d1_avg3_3yr_grth
gen period = "Post-period"
reshape long d@_avg3_3yr_grth, i(period) j(percentile)
rename d_avg3_3yr_grth growth
save "$temp_dir/post_period_rwgt.dta", replace
restore


* Combine the datasets
use "$temp_dir/pre_period_rwgt.dta", clear
append using "$temp_dir/inflation_period_rwgt.dta"
append using "$temp_dir/post_period_rwgt.dta"


gen annual_grth = growth/3 if period == "Pre-period"

/*
* Create line plots with modifications
twoway (connected growth percentile if period == "Inflation period", sort msymbol(D) lpattern(solid) mcolor(red) lcolor(red)) ///
       (connected growth percentile if period == "Post-period", sort msymbol(S) lpattern(dash) mcolor(black) lcolor(black)) ///
       (function y = 0, range(1 10) lcolor(black) lpattern(dash)), ///
       xlabel(1(1)10, angle(0)) ///
       ylabel(-12(2)6, format(%2.0f) angle(0)) ///
       xtitle("Earnings Decile") ///
       ytitle("% Cumulative Change") ///
       title() ///
       legend(order(1 "Apr21-May23" 2 "Apr21-May24") position(2) ring(0) bmargin(small) rows(2) region(lcolor(none))) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white)) ///

graph export "$output_dir/figures/cum_real_wkly_earn_grth.png", replace	


* Create line plots with modifications
twoway (connected annual_grth percentile if period == "Inflation period", sort msymbol(D)) ///
       (connected annual_grth percentile if period == "Post-period", sort msymbol(S)) ///
       (function y = 0, range(1 10) lcolor(black) lpattern(dash)), ///
       xlabel(1(1)10, angle(0)) ///
       ylabel(-10(2)10, format(%2.0f) angle(0)) ///
       xtitle("Decile") ///
       ytitle("% change") ///
       title("Annualized Change in Real Weekly Earnings") ///
       legend(order(1 "Apr21-May23" 2 "Apr21-May24") position(2) ring(0) bmargin(small)) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white)) ///


graph export "$output_dir/figures/annual_real_wkly_earn_grth.png", replace
*/

gen grth_rel_trend = . 
replace grth_rel_trend = growth - annual_grth[_n-10]*(26/12) if period == "Inflation period"
replace grth_rel_trend = growth - annual_grth[_n-20]*(38/12) if period == "Post-period" 

/* 
* Create line plots with modifications
twoway (connected grth_rel_trend percentile if period == "Inflation period", sort msymbol(D) lpattern(solid) mcolor(red) lcolor(red)) ///
       (connected grth_rel_trend percentile if period == "Post-period", sort msymbol(S) lpattern(dash) lcolor(red)) ///
       (function y = 0, range(1 10) lcolor(black) lpattern(dash)), ///
       xlabel(1(1)10, angle(0)) ///
       ylabel(-10(1)0, format(%2.0f) angle(0)) ///
       xtitle("Earnings Decile") ///
       ytitle("% Cummulative Change") ///
       title() ///
       legend(order(1 "Apr21-May23" 2 "Apr21-May24") position(2) ring(0) bmargin(small) rows(2) region(lcolor(none))) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white)) ///

graph export "$output_dir/figures/trend_annual_real_wkly_earn_grth.png", replace



twoway (connected grth_rel_trend percentile if period == "Post-period", sort msymbol(D) lpattern(solid) mcolor(red) lcolor(red)) ///
		(connected growth percentile if period == "Post-Period", sort msymbol(D) lpattern(dashed) mcolor(black) lcolor(black)) ///
       (function y = 0, range(1 10) lcolor(black) lpattern(dash)), ///
       xlabel(1(1)10, angle(0)) ///
       ylabel(-10(1)0, format(%2.0f) angle(0)) ///
       xtitle("Earnings Decile") ///
       ytitle("% Cummulative Change") ///
       title() ///
       legend(order(1 "Relative Trend" 2 "Raw") position(2) ring(0) bmargin(small) rows(2) region(lcolor(none))) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white)) ///
graph export "$output_dir/figures/trend_annual_real_wkly_earn_grth.png", replace		
*/ 

twoway (connected growth percentile if period == "Post-period", sort msymbol(S) lpattern(solid) mcolor(black) lcolor(black)) ///
		(connected grth_rel_trend percentile if period == "Post-period", sort msymbol(D) lpattern(dash) mcolor(red) lcolor(red)) ///
       (function y = 0, range(1 10) lcolor(black) lpattern(dot)), ///
       xlabel(1(1)10, angle(0)) ///
       ylabel(-10(2)6, format(%2.0f) angle(0)) ///
       xtitle("Earnings Decile") ///
       ytitle("% Cumulative Change") ///
       title("") ///
       legend(order(1 "Raw Growth" 2 "Relative to Trend") position(2) ring(0) bmargin(small) rows(2) region(lcolor(none))) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white)) 

graph export "$output_dir/figures/wage_growth_plot.png", replace


********************************************************************
********************************************************************

use "$output_dir/data/org_weekly_earnings_percentiles_mon.dta", clear 

keep YEAR MONTH date_monthly p50 

gen p50_ma3 = (p50 + p50[_n-1] + p50[_n-2])/3

gen p50_ma3_lag = p50_ma3[_n-12]

gen p50_grth = ((p50_ma3 - p50_ma3_lag)/p50_ma3_lag)*100

gen p50_grth_ma3 = (p50_grth + p50_grth[_n-1] + p50_grth[_n-2])/3 

keep if YEAR >= 2016

********************************
















use "$output_dir/data/org_hrly_earnings_dist_mon.dta", clear 

keep YEAR MONTH date_monthly p50 
gen p50_lag = p50[_n-12]

gen p50_grth = ((p50 - p50_lag)/p50_lag)*100

gen p50_grth_ma3 = (p50_grth + p50_grth[_n-1] + p50_grth[_n-2])/3 
keep if YEAR >= 2016
********************************************************
********************************************************
* by percentiles 
********************************************************
********************************************************
use "$output_dir/data/org_weekly_earnings_percentiles_mon.dta", clear

rename YEAR year 
********************************************************************************************************************
*********************************************************************************************************


* 3 month moving average 
foreach var of varlist p90 p80 p70 p60 p50 p40 p30 p20 p10 {
    generate `var'_avg3 = (`var' + `var'[_n-1] + `var'[_n-2] + `var'[_n-3] + `var'[_n-4] +  `var'[_n-5]) / 6
}

sort date_monthly
foreach var of varlist p90_avg3 p80_avg3 p70_avg3 p60_avg3 p50_avg3 p40_avg3 p30_avg3 p20_avg3 p10_avg3 {
    gen `var'_1yr_grth = ((`var' - `var'[_n-12]) / `var'[_n-12])*100
    gen `var'_2yr_grth = ((`var' - `var'[_n-26]) / `var'[_n-26])*100
    gen `var'_3yr_grth = ((`var' - `var'[_n-38]) / `var'[_n-38])*100

    label variable `var'_1yr_grth "12-month cumulative growth rate of `var'"
    label variable `var'_2yr_grth "24-month cumulative growth rate of `var'"
    label variable `var'_3yr_grth "36-month cumulative growth rate of `var'"
}

**************************************************
* time series patterns for different percentiles 
**************************************************

sort date_monthly
keep if date_monthly >= td(01jan2016)

sum date_monthly
local start_date = r(min)
local end_date = r(max)

*************************************************************************************************
*************************************************************************************************

* Pre-period (up to 2019)
preserve
collapse (mean) p10 p20 p30 p40 p50 p60 p70 p80 p90, by(year)
keep if year <= 2019
foreach var of varlist p10 p20 p30 p40 p50 p60 p70 p80 p90 {
    gen `var'_3yr_grth = ((`var' - `var'[_n-3]) / `var'[_n-3])*100
    drop `var'
}
drop if missing(p10_3yr_grth)

gen period = "Pre-period"
reshape long p@_3yr_grth, i(period) j(percentile)
rename p_3yr_grth growth
drop year 
save "$temp_dir/pre_period_rwgt.dta", replace
restore

* Inflation period (May 1, 2023)
preserve
keep if date_monthly == td(01may2023)

keep p90_avg3_2yr_grth p80_avg3_2yr_grth p70_avg3_2yr_grth p60_avg3_2yr_grth p50_avg3_2yr_grth p40_avg3_2yr_grth p30_avg3_2yr_grth p20_avg3_2yr_grth p10_avg3_2yr_grth

gen period = "Inflation period"
reshape long p@_avg3_2yr_grth, i(period) j(percentile)
rename p_avg3_2yr_grth growth
save "$temp_dir/inflation_period_rwgt.dta", replace
restore

* Post-period (April 1, 2024)
preserve
keep if date_monthly == td(01apr2024)
keep p90_avg3_3yr_grth p80_avg3_3yr_grth p70_avg3_3yr_grth p60_avg3_3yr_grth p50_avg3_3yr_grth p40_avg3_3yr_grth p30_avg3_3yr_grth p20_avg3_3yr_grth p10_avg3_3yr_grth
gen period = "Post-period"
reshape long p@_avg3_3yr_grth, i(period) j(percentile)
rename p_avg3_3yr_grth growth
save "$temp_dir/post_period_rwgt.dta", replace
restore

* Combine the datasets
use "$temp_dir/pre_period_rwgt.dta", clear
append using "$temp_dir/inflation_period_rwgt.dta"
append using "$temp_dir/post_period_rwgt.dta"

gen annual_grth = growth/3 if period == "Pre-period"

gen grth_rel_trend = . 
replace grth_rel_trend = growth - annual_grth[_n-9]*(26/12) if period == "Inflation period"
replace grth_rel_trend = growth - annual_grth[_n-18]*(38/12) if period == "Post-period"

twoway (connected growth percentile if period == "Post-period", sort msymbol(S) lpattern(solid) mcolor(black) lcolor(black)) ///
       (connected grth_rel_trend percentile if period == "Post-period", sort msymbol(D) lpattern(dash) mcolor(red) lcolor(red)) ///
       (function y = 0, range(10 90) lcolor(black) lpattern(dot)), ///
       xlabel(10(10)90, angle(0)) ///
       ylabel(-10(2)6, format(%2.0f) angle(0)) ///
       xtitle("Earnings Percentile") ///
       ytitle("% Cumulative Change") ///
       title("") ///
       legend(order(1 "Raw Growth" 2 "Relative to Trend") position(2) ring(0) bmargin(small) rows(2) region(lcolor(none))) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white))

graph export "$output_dir/figures/wage_growth_plot.png", replace





















/*












* Pre-period (February 1, 2019)
preserve
keep if date_monthly == td(01feb2019)
keep p90_avg3_2yr_grth p80_avg3_2yr_grth p70_avg3_2yr_grth p60_avg3_2yr_grth p50_avg3_2yr_grth p40_avg3_2yr_grth p30_avg3_2yr_grth p20_avg3_2yr_grth p10_avg3_2yr_grth
gen period = "Pre-period"
save "$temp_dir/pre_period_rwgt.dta", replace
restore

* Inflation period (May 1, 2023)
preserve
keep if date_monthly == td(01may2023)
keep p90_avg3_2yr_grth p80_avg3_2yr_grth p70_avg3_2yr_grth p60_avg3_2yr_grth p50_avg3_2yr_grth p40_avg3_2yr_grth p30_avg3_2yr_grth p20_avg3_2yr_grth p10_avg3_2yr_grth
gen period = "Inflation period"
save "$temp_dir/inflation_period_rwgt.dta", replace
restore

* Post-period (April 1, 2024)
preserve
keep if date_monthly == td(01apr2024)
keep p90_avg3_3yr_grth p80_avg3_3yr_grth p70_avg3_3yr_grth p60_avg3_3yr_grth p50_avg3_3yr_grth p40_avg3_3yr_grth p30_avg3_3yr_grth p20_avg3_3yr_grth p10_avg3_3yr_grth
gen period = "Post-period"
save "$temp_dir/post_period_rwgt.dta", replace
restore

* Combine the datasets
use "$temp_dir/pre_period_rwgt.dta", clear
append using "$temp_dir/inflation_period_rwgt.dta"
append using "$temp_dir/post_period_rwgt.dta" 


* Rename variables for consistency
rename (p90_avg3_2yr_grth p80_avg3_2yr_grth p70_avg3_2yr_grth p60_avg3_2yr_grth p50_avg3_2yr_grth p40_avg3_2yr_grth p30_avg3_2yr_grth p20_avg3_2yr_grth p10_avg3_2yr_grth) (p90_2yr p80_2yr p70_2yr p60_2yr p50_2yr p40_2yr p30_2yr p20_2yr p10_2yr)

rename (p90_avg3_3yr_grth p80_avg3_3yr_grth p70_avg3_3yr_grth p60_avg3_3yr_grth p50_avg3_3yr_grth p40_avg3_3yr_grth p30_avg3_3yr_grth p20_avg3_3yr_grth p10_avg3_3yr_grth) (p90_3yr p80_3yr p70_3yr p60_3yr p50_3yr p40_3yr p30_3yr p20_3yr p10_3yr)

* Reshape the data from wide to long format
reshape long p90_ p80_ p70_ p60_ p50_ p40_ p30_ p20_ p10_, i(period) j(percentile) string

* Rename the reshaped variable for consistency
rename p*_2yr growth_rate_2yr
rename p*_3yr growth_rate_3yr


* Create the line plot
twoway (line growth_rate_2yr percentile if period == "Pre-period", lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line growth_rate_2yr percentile if period == "Inflation period", lcolor(red) lpattern(dash) lwidth(medium)) ///
       (line growth_rate_3yr percentile if period == "Post-period", lcolor(green) lpattern(dot) lwidth(medium)), ///
       legend(label(1 "Feb17-Feb19") label(2 "April21-April23") label(3 "April21-April24")) ///
       title("Real Weekly Earnings Growth") ///
       xtitle("Percentiles") ytitle("Growth Rate") ///
       xlabel(1 "10" 2 "20" 3 "30" 4 "40" 5 "50" 6 "60" 7 "70" 8 "80" 9 "90") 




















* pre period 
keep if date_monthly == td(01feb2019)
keep p90_avg3_2yr_grth p80_avg3_2yr_grth p70_avg3_2yr_grth p60_avg3_2yr_grth p50_avg3_2yr_grth p40_avg3_2yr_grth p30_avg3_2yr_grth p20_avg3_2yr_grth p10_avg3_2yr_grth 

* inflation period 
keep if date_monthly == td(01may2023)
keep p90_avg3_2yr_grth p80_avg3_2yr_grth p70_avg3_2yr_grth p60_avg3_2yr_grth p50_avg3_2yr_grth p40_avg3_2yr_grth p30_avg3_2yr_grth p20_avg3_2yr_grth p10_avg3_2yr_grth 

* post period 
keep if date_monthly == td(01april2024)
keep p90_avg3_3yr_grth p80_avg3_3yr_grth p70_avg3_3yr_grth p60_avg3_3yr_grth p50_avg3_3yr_grth p40_avg3_3yr_grth p30_avg3_3yr_grth p20_avg3_3yr_grth p10_avg3_3yr_grth 









* Pre-period wage growth 

* 3 year pre period 
keep if YEAR >= 2016
keep if YEAR <= 2019

collapse (mean) p90 p80 p70 p60 p50 p40 p30 p20 p10, by (YEAR)

* annualized growth by deciles 
gen p90_grth = (log(p90) - log(p90[_n-3]))/3
gen p80_grth = (log(p80) - log(p80[_n-3]))/3
gen p70_grth = (log(p70) - log(p70[_n-3]))/3 
gen p60_grth = (log(p60) - log(p60[_n-3]))/3 
gen p50_grth = (log(p50) - log(p50[_n-3]))/3 
gen p40_grth = (log(p40) - log(p40[_n-3]))/3 
gen p30_grth = (log(p30) - log(p30[_n-3]))/3 
gen p20_grth = (log(p20) - log(p20[_n-3]))/3 
gen p10_grth = (log(p10) - log(p10[_n-3]))/3 

keep if YEAR == 2019 
drop YEAR p90 p80 p70 p60 p50 p40 p30 p20 p10
gen period = "16-19"
save "$output_dir/data/16_19_annualized_rwgt.dta", replace 

*********************************************************************
* inflation period 
* 12 month 

clear 
use "$output_dir/data/org_wkly_earnings_dist.dta", clear 
rename YEAR year 
keep if inrange(date_monthly, td(01jul2021), td(01jul2022))

collapse (mean) p90 p80 p70 p60 p50 p40 p30 p20 p10, by (year)

* annualized growth by deciles 
gen p90_grth = (log(p90) - log(p90[_n-1]))
gen p80_grth = (log(p80) - log(p80[_n-1]))
gen p70_grth = (log(p70) - log(p70[_n-1]))
gen p60_grth = (log(p60) - log(p60[_n-1]))
gen p50_grth = (log(p50) - log(p50[_n-1]))
gen p40_grth = (log(p40) - log(p40[_n-1]))
gen p30_grth = (log(p30) - log(p30[_n-1]))
gen p20_grth = (log(p20) - log(p20[_n-1]))
gen p10_grth = (log(p10) - log(p10[_n-1]))

keep if year == 2022 
drop year p90 p80 p70 p60 p50 p40 p30 p20 p10
gen period = "Jul21-Jul22" 

save "$output_dir/data/Jul21_Jul22_annualized_rwgt.dta", replace 

**********************************************************************
* entire post period 

clear 
use "$output_dir/data/org_wkly_earnings_dist.dta", clear 

rename YEAR year 
local start_date = date("01jul2021", "DMY")
local end_date = date("01dec2022", "DMY")

keep if inrange(date_monthly, `start_date', `end_date')

local num_months = mofd(`end_date') - mofd(`start_date') + 1
local years = `num_months' / 12


collapse (mean) p90 p80 p70 p60 p50 p40 p30 p20 p10, by (year)

* annualized growth by deciles 
gen p90_grth = (log(p90) - log(p90[_n-1]))/`years'
gen p80_grth = (log(p80) - log(p80[_n-1]))/`years'
gen p70_grth = (log(p70) - log(p70[_n-1]))/`years'
gen p60_grth = (log(p60) - log(p60[_n-1]))/`years'
gen p50_grth = (log(p50) - log(p50[_n-1]))/`years' 
gen p40_grth = (log(p40) - log(p40[_n-1]))/`years' 
gen p30_grth = (log(p30) - log(p30[_n-1]))/`years'
gen p20_grth = (log(p20) - log(p20[_n-1]))/`years'
gen p10_grth = (log(p10) - log(p10[_n-1]))/`years'

gen period = "Jul21-Dec22"
keep if year == 2022 
drop year p90 p80 p70 p60 p50 p40 p30 p20 p10
save "$output_dir/data/Jul21_Dec22_annualized_rwgt.dta", replace 

* combine the data 
use "$output_dir/cps/15_19_annualized_rwgt.dta", clear 
append using "$output_dir/data/Jul21_Jul22_annualized_rwgt.dta"

gen p90_rwgt_inf1 = (p90_grth - p90_grth[_n-1])*100
gen p80_rwgt_inf1 = (p80_grth - p80_grth[_n-1])*100
gen p70_rwgt_inf1 = (p70_grth - p70_grth[_n-1])*100
gen p60_rwgt_inf1 = (p60_grth - p60_grth[_n-1])*100
gen p50_rwgt_inf1 = (p50_grth - p50_grth[_n-1])*100
gen p40_rwgt_inf1 = (p40_grth - p40_grth[_n-1])*100
gen p30_rwgt_inf1 = (p30_grth - p30_grth[_n-1])*100
gen p20_rwgt_inf1 = (p20_grth - p20_grth[_n-1])*100
gen p10_rwgt_inf1 = (p10_grth - p10_grth[_n-1])*100


append using "$output_dir/cps/Jul21_Dec22_annualized_rwgt.dta"

gen p90_rwgt_post = (p90_grth - p90_grth[_n-2])*100
gen p80_rwgt_post = (p80_grth - p80_grth[_n-2])*100
gen p70_rwgt_post = (p70_grth - p70_grth[_n-2])*100
gen p60_rwgt_post = (p60_grth - p60_grth[_n-2])*100
gen p50_rwgt_post = (p50_grth - p50_grth[_n-2])*100
gen p40_rwgt_post = (p40_grth - p40_grth[_n-2])*100
gen p30_rwgt_post = (p30_grth - p30_grth[_n-2])*100
gen p20_rwgt_post = (p20_grth - p20_grth[_n-2])*100
gen p10_rwgt_post = (p10_grth - p10_grth[_n-2])*100

drop p90_grth p80_grth p70_grth p60_grth p50_grth p40_grth p30_grth p20_grth p10_grth


save "$output_dir/cps/figure2_data.dta", replace 





