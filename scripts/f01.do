* Yash Singh 
* date: 08/06/24 
* this script generates all the main and appendix wage growth plots 

clear 
global data_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\raw_data"
global temp_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\temp"
global output_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\output"


* By deciles 

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
	gen `var'_3yr_grth = ((`var' - `var'[_n-39]) / `var'[_n-39])*100
	
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

*************************************************************************************************
*************************************************************************************************


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
keep if date_monthly == td(01jun2024)
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


gen grth_rel_trend = . 
replace grth_rel_trend = growth - annual_grth[_n-20]*(39/12) if period == "Post-period" 

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


twoway (connected annual_grth percentile if period == "Pre-period", sort msymbol(S) lpattern(solid) mcolor(black) lcolor(black)) ///
       (function y = 0, range(1 10) lcolor(black) lpattern(dot)), ///
       xlabel(1(1)10, angle(0) valuelabel) ///
       ylabel(-1(1)3, format(%2.0f) angle(0)) ///
       xtitle("Earnings Decile") ///
       ytitle("% Annual Real Wage Growth") ///
       legend(off) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white)) ///
       yline(0, lcolor(gray) lpattern(dash))

graph export "$output_dir/figures/wage_growth_plot_16_19.png", replace

drop if period == "Inflation period"


rename growth cum_grth
export delimited using "$output_dir/data/post_rwgt.csv", replace





use "$output_dir/data/org_weekly_earnings_percentiles_mon.dta", clear 


keep YEAR MONTH date_monthly p50 
gen p50_ma3 = (p50 + p50[_n-1] + p50[_n-2])/3
gen p50_ma3_lag = p50_ma3[_n-12]
gen p50_grth = ((p50_ma3 - p50_ma3_lag)/p50_ma3_lag)*100
gen p50_grth_ma3 = (p50_grth + p50_grth[_n-1] + p50_grth[_n-2])/3 

save "$temp_dir/median_wgt.dta", replace 


keep if YEAR >= 2016
summarize date_monthly
local start_date = r(min)
local end_date = r(max)

* pre period 
sum p50_grth if date_monthly >= td(01jan2016) & date_monthly <= td(31dec2019)
local avg_2016_2019_p50_grth = r(mean)
di `avg_2016_2019_p50_grth'

local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)

* inflation period 
sum p50_grth if date_monthly >= td(01apr2021) & date_monthly <= td(31may2023)
local p50_grth_inf_period = r(mean)
di `p50_grth_inf_period'
local start_apr21 = td(01apr2021)
local end_may23 = td(31may2023)

save "$temp_dir/median_wgt.dta", replace 

twoway (connected p50_grth date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (function y = `avg_2016_2019_p50_grth', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `p50_grth_inf_period', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("% Growth") ///
    title("") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	
        
graph export "$output_dir/figures/median_earnings_growth_smoothed.png", replace

keep date_monthly p50_grth 
save "$temp_dir/median_wgt.dta", replace 

******************************************************
******************************************************
use "$output_dir/data/org_weekly_earnings_percentiles_mon.dta", clear 

* Generate the ratios
gen ratio_p90_p50 = p90 / p50 
gen ratio_p50_p20 = p50 / p20
gen ratio_p50_p10 = p50 / p10

* Calculate the minimum and maximum date
summarize date_monthly
local start_date = r(min)
local end_date = r(max)

* Plot the ratios
twoway  (connected ratio_p50_p10 date_monthly, msymbol(circle_hollow) mcolor(black) lcolor(black) ///
           lpattern(solid) lwidth(medium))
		 (connected ratio_p50_p20 date_monthly, msymbol(circle_hollow) mcolor(black) lcolor(black) ///
           lpattern(solid) lwidth(medium)), //////
    ylabel(1.25 (.25) 2.25, angle(horizontal)) ///
    ytitle("Ratio") ///
    title(") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
    legend(order(1 "P50/P10" 2 "P50/P20"))     
        
graph export "$output_dir/figures/percentile_ratios.png", replace

* Plot the ratios
twoway  (connected ratio_p50_p20 date_monthly, msymbol(circle_hollow) mcolor(black) lcolor(black) ///
           lpattern(solid) lwidth(medium)), ///
    ylabel(1.25 (.1) 2.5, angle(horizontal)) ///
    ytitle("Ratio") ///
    title("50/20 Ratio") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") ///   
        
graph export "$output_dir/figures/percentile_ratios.png", replace


******************************************************
******************************************************
use "$output_dir/data/org_weekly_earnings_percentiles_mon.dta", clear 

* Generate the ratios
gen ratio_p90_p10 = p90 / p10 
gen ratio_p90_p20 = p90 / p20 
gen ratio_p50_p20 = p50 / p20
gen ratio_p50_p10 = p50 / p10

* Calculate the minimum and maximum date
summarize date_monthly
local start_date = r(min)
local end_date = r(max)

* Plot the ratios
twoway (connected ratio_p50_p10 date_monthly, msymbol(circle_hollow) mcolor(black) lcolor(black) ///
           lpattern(solid) lwidth(medium)) ///
       (connected ratio_p50_p20 date_monthly, msymbol(circle_hollow) mcolor(red) lcolor(red) ///
           lpattern(solid) lwidth(medium)), ///
    ylabel(1.25(.25)2.25, angle(horizontal)) ///
    ytitle("Ratio") ///
    title("Earnings Ratios") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
    legend(order(1 "P50/P10" 2 "P50/P20"))
    
graph export "$output_dir/figures/percentile_ratios.png", replace

* Plot the ratios
twoway (connected ratio_p90_p10 date_monthly, msymbol(circle_hollow) mcolor(black) lcolor(black) ///
           lpattern(solid) lwidth(medium)) ///
       (connected ratio_p90_p20 date_monthly, msymbol(circle_hollow) mcolor(red) lcolor(red) ///
           lpattern(solid) lwidth(medium)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("Ratio") ///
    title("Earnings Ratios") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
    legend(order(1 "P90/P10" 2 "P90/P20"))


/*
*************************************************************************
*************************************************************************
* Hourly Wage Deciles
*************************************************************************
*************************************************************************

use "$output_dir/data/org_hrly_wage_dist_mon.dta", clear 
rename YEAR year 
rename MONTH month 
sort year month 

tsset date_monthly
sort year month

rename real_hrly_wage10 d10 
rename real_hrly_wage9 d9 
rename real_hrly_wage8 d8 
rename real_hrly_wage7 d7 
rename real_hrly_wage6 d6 
rename real_hrly_wage5 d5 
rename real_hrly_wage4 d4 
rename real_hrly_wage3 d3 
rename real_hrly_wage2 d2 
rename real_hrly_wage1 d1 


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

*************************************************************************************************
*************************************************************************************************


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


gen grth_rel_trend = . 
replace grth_rel_trend = growth - annual_grth[_n-10]*(26/12) if period == "Inflation period"
replace grth_rel_trend = growth - annual_grth[_n-20]*(38/12) if period == "Post-period" 


twoway (connected growth percentile if period == "Post-period", sort msymbol(S) lpattern(solid) mcolor(black) lcolor(black)) ///
		(connected grth_rel_trend percentile if period == "Post-period", sort msymbol(D) lpattern(dash) mcolor(red) lcolor(red)) ///
       (function y = 0, range(1 10) lcolor(black) lpattern(dot)), ///
       xlabel(1(1)10, angle(0)) ///
       ylabel(-10(2)8, format(%2.0f) angle(0)) ///
       xtitle("Earnings Decile") ///
       ytitle("% Cumulative Change") ///
       title("") ///
       legend(order(1 "Raw Growth" 2 "Relative to Trend") position(2) ring(0) bmargin(small) rows(2) region(lcolor(none))) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white)) 

graph export "$output_dir/figures/hrly_wage_growth_plot.png", replace

************************************************************************
************************************************************************
* Weekly Earnings Percentiles 
************************************************************************
************************************************************************

use "$output_dir/data/org_weekly_earnings_percentiles_mon.dta", clear 

rename YEAR year 
rename MONTH month 
sort year month 

tsset date_monthly
sort year month

rename p95 d10 
rename p90 d9 
rename p80 d8 
rename p70 d7 
rename p60 d6 
rename p50 d5 
rename p40 d4 
rename p30 d3 
rename p20 d2 
rename p10 d1 



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

*************************************************************************************************
*************************************************************************************************


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


gen grth_rel_trend = . 
replace grth_rel_trend = growth - annual_grth[_n-10]*(26/12) if period == "Inflation period"
replace grth_rel_trend = growth - annual_grth[_n-20]*(38/12) if period == "Post-period" 


twoway (connected growth percentile if period == "Post-period", sort msymbol(S) lpattern(solid) mcolor(black) lcolor(black)) ///
		(connected grth_rel_trend percentile if period == "Post-period", sort msymbol(D) lpattern(dash) mcolor(red) lcolor(red)) ///
       (function y = 0, range(1 10) lcolor(black) lpattern(dot)), ///
       xlabel(1(1)10, angle(0)) ///
       ylabel(-10(2)8, format(%2.0f) angle(0)) ///
       xtitle("Earnings Decile") ///
       ytitle("% Cumulative Change") ///
       title("") ///
       legend(order(1 "Raw Growth" 2 "Relative to Trend") position(2) ring(0) bmargin(small) rows(2) region(lcolor(none))) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white)) 

graph export "$output_dir/figures/wage_growth_plot.png", replace




************************************************************************
************************************************************************
* Weekly Percentile 
***********************************************************************
***********************************************************************

use "$output_dir/data/org_weekly_earnings_percentiles_mon.dta", clear 
keep YEAR MONTH date_monthly p50 
gen p50_ma3 = (p50 + p50[_n-1] + p50[_n-2])/3
gen p50_ma3_lag = p50_ma3[_n-12]
gen p50_grth = ((p50_ma3 - p50_ma3_lag)/p50_ma3_lag)*100
gen p50_grth_ma3 = (p50_grth + p50_grth[_n-1] + p50_grth[_n-2])/3 
keep if YEAR >= 2016

summarize date_monthly
local start_date = r(min)
local end_date = r(max)

* pre period 
sum p50_grth if date_monthly >= td(01jan2016) & date_monthly <= td(30dec2019)
local avg_2016_2019_p50_grth = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)

* inflation period 
sum p50_grth if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local p50_grth_inf_period = r(mean)

local start_apr21 = td(01april2021)
local end_may23 = td(30may2023)


twoway (connected p50_grth date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy))
		(function y = `avg_2016_2019_p50_grth', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = ` p50_grth_inf_period', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("% Growth") ///
    title("") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
    legend(off)    
        
graph export "$output_dir/figures/median_earnings_growth_smoothed.png", replace




use "$output_dir/data/org_weekly_earnings_percentiles_mon.dta", clear 
keep YEAR MONTH date_monthly p50 
gen p50_ma3 = (p50 + p50[_n-1] + p50[_n-2])/3
gen p50_ma3_lag = p50_ma3[_n-12]
gen p50_grth = ((p50_ma3 - p50_ma3_lag)/p50_ma3_lag)*100
gen p50_grth_ma3 = (p50_grth + p50_grth[_n-1] + p50_grth[_n-2])/3 
keep if YEAR >= 2016
summarize date_monthly
local start_date = r(min)
local end_date = r(max)

* pre period 
sum p50_grth if date_monthly >= td(01jan2016) & date_monthly <= td(31dec2019)
local avg_2016_2019_p50_grth = r(mean)
di `avg_2016_2019_p50_grth'

local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)

* inflation period 
sum p50_grth if date_monthly >= td(01apr2021) & date_monthly <= td(31may2023)
local p50_grth_inf_period = r(mean)
di `p50_grth_inf_period'
local start_apr21 = td(01apr2021)
local end_may23 = td(31may2023)

twoway (connected p50_grth date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (function y = `avg_2016_2019_p50_grth', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `p50_grth_inf_period', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("% Growth") ///
    title("") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
    legend(off)    
        
graph export "$output_dir/figures/median_earnings_growth_smoothed.png", replace



************************************************************************
************************************************************************
* Hourly Wage Percentiles 
************************************************************************
************************************************************************

use "$output_dir/data/org_hrly_wage_percentiles_mon.dta", clear 

rename YEAR year 
rename MONTH month 
sort year month 

tsset date_monthly
sort year month

rename p95 d10 
rename p90 d9 
rename p80 d8 
rename p70 d7 
rename p60 d6 
rename p50 d5 
rename p40 d4 
rename p30 d3 
rename p20 d2 
rename p10 d1 



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

*************************************************************************************************
*************************************************************************************************


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


gen grth_rel_trend = . 
replace grth_rel_trend = growth - annual_grth[_n-10]*(26/12) if period == "Inflation period"
replace grth_rel_trend = growth - annual_grth[_n-20]*(38/12) if period == "Post-period" 


twoway (connected growth percentile if period == "Post-period", sort msymbol(S) lpattern(solid) mcolor(black) lcolor(black)) ///
		(connected grth_rel_trend percentile if period == "Post-period", sort msymbol(D) lpattern(dash) mcolor(red) lcolor(red)) ///
       (function y = 0, range(1 10) lcolor(black) lpattern(dot)), ///
       xlabel(1(1)10, angle(0)) ///
       ylabel(-10(2)8, format(%2.0f) angle(0)) ///
       xtitle("Earnings Decile") ///
       ytitle("% Cumulative Change") ///
       title("") ///
       legend(order(1 "Raw Growth" 2 "Relative to Trend") position(2) ring(0) bmargin(small) rows(2) region(lcolor(none))) ///
       scheme(s1color) ///
       graphregion(color(white)) ///
       plotregion(lcolor(white)) 

graph export "$output_dir/figures/wage_growth_plot.png", replace










