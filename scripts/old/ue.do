
clear 
global data_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\raw_data"
global temp_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\temp"
global output_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\output"

use "$output_dir\data\job_flow.dta", clear 

rename Date date_monthly 
rename Year year 
rename Month month 

keep year month date_monthly ue_pol 

* pre inflation period 
sum ue_pol if date_monthly >= td(01jan2016) & date_monthly <= td(31dec2019)
local avg_2016_2019 = r(mean)

local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)


preserve 
* select your time period 
keep if year >=2016

gen cutoff_date = date("01may2024", "DMY")
keep if date <= cutoff_date

sum date_monthly
local start_date = r(min)
local end_date = r(max)



* select your time period 
keep if year >=2015


sum date_monthly
local start_date = r(min)
local end_date = r(max)

sort date_monthly

gen ue_pol_ma3 = (ue_pol + ue_pol[_n-1] + ue_pol[_n-2]) / 3 if _n > 2

keep if year >=2016
sum date_monthly
local start_date = r(min)
local end_date = r(max)

************************************************
* 12 month inflation period 
************************************************

sum ue_pol_ma3 if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_jun21_jun22 = r(mean)

local start_apr21 = td(01apr2021)
local end_may23 = td(30may2023)


twoway (connected ue_pol_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_jun22', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    title("UE") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)	
	
graph export "$output_dir/figures/ue_12.png", replace	
	
************************************************
* 18 month inflation period 
************************************************

sum ue_pol_ma3 if date_monthly >= td(01jun2021) & date_monthly <= td(30dec2022)
local avg_jun21_dec22 = r(mean)

local start_jun21 = td(01jun2021)
local end_dec22 = td(30dec2022)


twoway (connected ue_pol_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_dec22', range(`start_jun21' `end_dec22') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    title("ue") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)	
	
graph export "$output_dir/figures/ue_18.png", replace	