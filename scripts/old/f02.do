* Yash Singh 
* date: 7/28/24 
* this script generates plots for several key flows EE, layoffs, UE rates in the aggregate 

************************************************************************************************
* List of plots 

************************************
* Section 1: Aggregate Flows 
************************************

* 1) EE flows from FMP 
* 2) UE flows from Shimer 
* 3) EU flows from Shimer 
* 4) JOLTS layoffs 
* 5) JOLTS Job Openings 
* 6) JOLTS Quits 

*******************************************
* Section 2: Flows across the distribution 
* 7) EE flows by Education 
* 8) EE flows by decile 


*************************************************************************************************

clear 
global data_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\raw_data"
global temp_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\temp"
global output_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\output"




*********************************
* 1) FMP Series - EE rates 
*********************************

import excel using "$data_dir\ee_fmp.xlsx", sheet("Data") firstrow clear
rename FMP_SA ee_pol	
gen date_monthly = mdy(month, 1, year)
format date_monthly %td
keep year month date_monthly ee_pol

sort year month 
gen ee_pol_ma3 = (ee_pol + ee_pol[_n-1] + ee_pol[_n-2]) / 3 if _n > 2

replace ee_pol = ee_pol*100
replace ee_pol_ma3 = ee_pol_ma3*100

// Ensure data is sorted by date_monthly
sort date_monthly
keep if date_monthly >= td(01jan2016)

// Calculate the start and end dates for the entire period
sum date_monthly
local start_date = r(min)
local end_date = r(max)

// Pre-inflation period
sum ee_pol if date_monthly >= td(01jan2016) & date_monthly <= td(31dec2019)
local avg_2016_2019 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)

// 12-month inflation period
sum ee_pol_ma3 if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_jun21_jun22 = r(mean)
local start_jun21 = td(01april2021)
local end_jun22 = td(30may2023)

// Create the time series plot
twoway (connected ee_pol_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
       (function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_jun22', range(`start_jun21' `end_jun22') lcolor(red) lpattern(dash)), ///
       ylabel(, angle(horizontal)) ///
       ytitle("Smoothed Rate") ///
       title() ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) /// 
       xtitle("") ///
       legend(off)

graph export "$output_dir/figures/ee.png", replace
	   
******************************************************	   
* 2) Shimer Method - UE flows 	   
******************************************************

use "$temp_dir/shimer_macro_flows.dta", clear 

keep date_monthly ue_rate ue_rate_ma3 unemp_stock_next short_unemp_stock_next unemp_stock

gen period = (date_monthly >= td(01Apr2021) & date_monthly <= td(30May2023))
*drop if (date_monthly >= td(01Jan2020) & date_monthly < td(01Apr2021))
*drop if (date_monthly > td(30May2023))
keep if (date_monthly >= td(01Jan2016))

* Plots

* Pre inflation period 
keep if date_monthly >= td(01jan2016)
sum ue_rate_ma3 if date_monthly >= td(01jan2016) & date_monthly <= td(31dec2019)
local avg_2016_2019 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)
sum date_monthly
local start_date = r(min)
local end_date = r(max)
sum ue_rate_ma3 if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_jun21_jun22 = r(mean)
local start_apr21 = td(01apr2021)
local end_may23 = td(30may2023)

twoway (connected ue_rate_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_jun22', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    title() ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
    legend(off)    

graph export "$output_dir/figures/ue_12.png", replace	   
	   
******************************************************
******************************************************
* UE QUARTERLY 

* Load the dataset
use "$temp_dir/shimer_macro_flows.dta", clear 

* Keep necessary variables
keep date_monthly ue_rate ue_rate_ma3 unemp_stock_next short_unemp_stock_next unemp_stock

* Create a period variable for filtering
gen period = (date_monthly >= td(01Apr2021) & date_monthly <= td(30May2023))

* Keep data from January 2016 onward
keep if (date_monthly >= td(01Jan2016))

* Generate a quarterly date variable
gen date_quarterly = qofd(date_monthly)

* Collapse data to quarterly averages
replace ue_rate_ma3 = ue_rate_ma3*100
collapse (mean) ue_rate_ma3 = ue_rate_ma3, by(date_quarterly)

* Define the periods and calculate averages
local start_2016 = tq(2016q1)
local end_2019 = tq(2019q4)
sum ue_rate_ma3 if date_quarterly >= `start_2016' & date_quarterly <= `end_2019'
local avg_2016_2019 = r(mean)

local start_apr21 = tq(2021q2)
local end_may23 = tq(2023q2)
sum ue_rate_ma3 if date_quarterly >= `start_apr21' & date_quarterly <= `end_may23'
local avg_jun21_jun22 = r(mean)

local end_may24 = tq(2024q2)
* Plot
twoway (connected ue_rate_ma3 date_quarterly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_jun22', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///
    ylabel(10 (5) 50, angle(horizontal)) ///
    ytitle() ///
    title() ///
    xlabel(`start_2016'(2)`end_may24', format(%tq) angle(45) labsize(small)) ///
    xtitle("") /// 
    legend(off)    

* Export the graph
graph export "$output_dir/figures/ue_quarterly.png", replace



***********************************************************************
*******************************************************************	  
** EE Quarterly 
	  
* Import the Excel data
import excel using "$data_dir\ee_fmp.xlsx", sheet("Data") firstrow clear

* Rename and create necessary variables
rename FMP_SA ee_pol	
gen date_monthly = mdy(month, 1, year)
format date_monthly %td
keep year month date_monthly ee_pol

* Sort data by year and month
sort year month 

* Calculate 3-month moving average
gen ee_pol_ma3 = (ee_pol + ee_pol[_n-1] + ee_pol[_n-2]) / 3 if _n > 2

* Scale variables
replace ee_pol = ee_pol * 100



replace ee_pol_ma3 = ee_pol_ma3 * 100

save "$temp_dir/ee_cleaned.dta", replace 

* Ensure data is sorted by date_monthly
sort date_monthly
keep if date_monthly >= td(01jan2016)

* Convert to quarterly frequency
gen date_quarterly = qofd(date_monthly)

* Collapse data to quarterly averages
collapse (mean) ee_pol_ma3, by(date_quarterly)

* Define the periods and calculate averages
local start_2016 = tq(2016q1)
local end_2019 = tq(2019q4)
sum ee_pol_ma3 if date_quarterly >= `start_2016' & date_quarterly <= `end_2019'
local avg_2016_2019 = r(mean)

local start_jun21 = tq(2021q2)
local end_jun22 = tq(2023q2)
sum ee_pol_ma3 if date_quarterly >= `start_jun21' & date_quarterly <= `end_jun22'
local avg_jun21_jun22 = r(mean)

local end_may24 = tq(2024q2)

* Create the time series plot
twoway (connected ee_pol_ma3 date_quarterly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
       (function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_jun22', range(`start_jun21' `end_jun22') lcolor(red) lpattern(dash)), ///
       ylabel(1.7 (.2) 2.7, angle(horizontal)) ///
       ytitle() ///
       title() ///
       xlabel(`start_2016' (2) `end_may24', format(%tq) angle(45) labsize(small)) /// 
       xtitle("") ///
       legend(off)

* Export the graph
graph export "$output_dir/figures/ee_quarterly.png", replace
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
***************************************************************
* 3) Shimer Method - EU flows 
***************************************************************	   

use "$temp_dir/shimer_macro_flows.dta", clear 
keep date_monthly eu_rate eu_rate_ma3 
gen period = (date_monthly >= td(01Apr2021) & date_monthly <= td(30May2023))
keep if (date_monthly >= td(01Jan2016))

* Drop the months you want to exclude
drop if (date_monthly >= td(01mar2020) & date_monthly <= td(01nov2020))

* Calculate summary statistics
sum eu_rate_ma3 if date_monthly >= td(01jan2016) & date_monthly <= td(31dec2019)
local avg_2016_2019 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)
sum date_monthly
local start_date = r(min)
local end_date = r(max)
sum eu_rate_ma3 if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_jun21_jun22 = r(mean)
local start_apr21 = td(01apr2021)
local end_may23 = td(30may2023)

* Create the plot
twoway (connected eu_rate_ma3 date_monthly if date_monthly < td(01mar2020), msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (connected eu_rate_ma3 date_monthly if date_monthly > td(01nov2020), msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_jun22', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    title() ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
    legend(off)    
graph export "$output_dir/figures/eu_12.png", replace
	   
	   
*********************************************************************
* JOLTS flows data 
**********************************************************************

import excel "$data_dir\JOLTS_flows_2000_2024.xlsx", sheet("BLS Data Reformatted") firstrow clear 
	   
keep A LayoffsDischargesNOCOV JobOpenings Quits
rename A date_monthly
rename LayoffsDischargesNOCOV layoffs 

	   
gen period = (date_monthly >= td(01Apr2021) & date_monthly <= td(30May2023))
keep if (date_monthly >= td(01Jan2016))

******************************************************
* 4) Layoffs 
******************************************************

preserve 
* Drop the months you want to exclude
drop if (date_monthly >= td(01mar2020) & date_monthly <= td(01nov2020))

* Calculate summary statistics
sum layoffs if date_monthly >= td(01jan2016) & date_monthly <= td(31dec2019)
local avg_2016_2019 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)
sum date_monthly
local start_date = r(min)
local end_date = r(max)
sum layoffs if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_jun21_jun22 = r(mean)
local start_apr21 = td(01apr2021)
local end_may23 = td(30may2023)

* Create the plot
twoway (connected layoffs date_monthly if date_monthly < td(01mar2020), msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (connected layoffs date_monthly if date_monthly > td(01nov2020), msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_jun22', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    title() ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
    legend(off)    
	
graph export "$output_dir/figures/jolts_layoffs.png", replace	   
restore 
***************************************************
* 5) Job Openings 
***************************************************

preserve 
* Calculate summary statistics
sum JobOpenings if date_monthly >= td(01jan2016) & date_monthly <= td(31dec2019)
local avg_2016_2019 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)
sum date_monthly
local start_date = r(min)
local end_date = r(max)
sum JobOpenings if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_jun21_jun22 = r(mean)
local start_apr21 = td(01apr2021)
local end_may23 = td(30may2023)

* Create the plot
twoway (connected JobOpenings date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_jun22', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///
    ylabel(0(1)8, angle(horizontal)) ///
    ytitle("") ///
    title() ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
    legend(off)    
	
graph export "$output_dir/figures/jolts_JobOpenings.png", replace	   
restore 

***************************************************
* 6) Quits 
***************************************************

preserve 
* Calculate summary statistics
sum Quits if date_monthly >= td(01jan2016) & date_monthly <= td(31dec2019)
local avg_2016_2019 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)
sum date_monthly
local start_date = r(min)
local end_date = r(max)
sum Quits if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_jun21_jun22 = r(mean)
local start_apr21 = td(01apr2021)
local end_may23 = td(30may2023)

* Create the plot
twoway (connected Quits date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_jun22', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///
    ylabel(0(1)4, angle(horizontal)) ///
    ytitle("") ///
    title() ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
    legend(off)    
	
graph export "$output_dir/figures/jolts_Quits.png", replace	   
restore 	   
	 
*************************************************************
*************************************************************
* Section 2: Job Flows by distribution 
*************************************************************
*************************************************************

* 7) EE by education level 

use "$output_dir\data\job_flow.dta", clear 
rename Date date_monthly 
keep date_monthly ee_educ_1 ee_educ_2

* smoother version
gen ee_educ_1_ma3 = (ee_educ_1 + ee_educ_1[_n-1] + ee_educ_1[_n-2]) / 3 if _n > 2
gen ee_educ_2_ma3 = (ee_educ_2 + ee_educ_2[_n-1] + ee_educ_2[_n-2]) / 3 if _n > 2


*********************
* less than hs 
*********************

* pre period 
sum ee_educ_1_ma3 if date_monthly >= td(01jan2016) & date_monthly <= td(30dec2019)
local avg_2016_2019_educ_1 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)

* inflation period 
sum ee_educ_1_ma3 if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_educ_1_inf_period = r(mean)

local start_apr21 = td(01april2021)
local end_may23 = td(30may2023)

* Plotting 
keep if date_monthly >= td(01jan2016)
sum date_monthly
local start_date = r(min)
local end_date = r(max)

twoway (connected ee_educ_1_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019_educ_1', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_educ_1_inf_period', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)		
	
graph export "$output_dir/figures/ee_educ_1.png", replace		
	

*********************
* college+
*********************

* pre period 
sum ee_educ_2_ma3 if date_monthly >= td(01jan2016) & date_monthly <= td(30dec2019)
local avg_2016_2019_educ_2 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)

* inflation period 
sum ee_educ_2_ma3 if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_educ_2_inf_period = r(mean)

local start_apr21 = td(01april2021)
local end_may23 = td(30may2023)

* Plotting 
keep if date_monthly >= td(01jan2016)
sum date_monthly
local start_date = r(min)
local end_date = r(max)

twoway (connected ee_educ_2_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019_educ_2', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_educ_2_inf_period', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)		
	
graph export "$output_dir/figures/ee_educ_2.png", replace		
	

* 8) EU by education 
use "$output_dir\data\job_flow.dta", clear
rename Date date_monthly 
keep date_monthly Year Month eu_layoffs_educ_1 eu_layoffs_educ_2


* smoother version
gen eu_layoffs_educ_1_ma3 = (eu_layoffs_educ_1 + eu_layoffs_educ_1[_n-1] + eu_layoffs_educ_1[_n-2]) / 3 if _n > 2
gen eu_layoffs_educ_2_ma3 = (eu_layoffs_educ_2 + eu_layoffs_educ_2[_n-1] + eu_layoffs_educ_2[_n-2]) / 3 if _n > 2


*********************
* less than hs 
*********************

* pre period 
sum eu_layoffs_educ_1_ma3 if date_monthly >= td(01jan2016) & date_monthly <= td(30dec2019)
local avg_2016_2019_educ_1 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)

* inflation period 
sum eu_layoffs_educ_1_ma3 if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_educ_1_inf_period = r(mean)

local start_apr21 = td(01sep2021)
local end_may23 = td(30may2023)

* Plotting 
keep if date_monthly >= td(01jan2016)
sum date_monthly
local start_date = r(min)
local end_date = r(max)

drop if (date_monthly>=td(01jan2020) & date_monthly <= td(01dec2020)) 



twoway (connected eu_layoffs_educ_1_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019_educ_1', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_educ_1_inf_period', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)		
	
graph export "$output_dir/figures/eu_educ_1.png", replace		
	

*********************
* college+
*********************

* pre period 
sum ee_educ_2_ma3 if date_monthly >= td(01jan2016) & date_monthly <= td(30dec2019)
local avg_2016_2019_educ_2 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)

* inflation period 
sum ee_educ_2_ma3 if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_educ_2_inf_period = r(mean)

local start_apr21 = td(01april2021)
local end_may23 = td(30may2023)

* Plotting 
keep if date_monthly >= td(01jan2016)
sum date_monthly
local start_date = r(min)
local end_date = r(max)

twoway (connected ee_educ_2_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019_educ_2', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_educ_2_inf_period', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)		
	
graph export "$output_dir/figures/ee_educ_2.png", replace		
































// Calculate percent difference (using log difference)
gen percent_diff = (log(eu_layoffs_educ_1*100) - log(eu_layoffs_educ_1*100))*100

// Calculate 3-month moving average
gen percent_diff_ma = (percent_diff + percent_diff[_n-1] + percent_diff[_n-2])/3

// Calculate summary statistics
sum percent_diff_ma if Date >= td(01jan2016) & Date <= td(31dec2019)
local avg_2016_2019 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)

sum Date
local start_date = r(min)
local end_date = r(max)

sum percent_diff_ma if Date >= td(01apr2021) & Date <= td(30may2023)
local avg_apr21_may23 = r(mean)
local start_apr21 = td(01apr2021)
local end_may23 = td(30may2023)

// Create the plot
twoway (connected percent_diff_ma Date, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_apr21_may23', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("Percent Difference") ///
    title("Percent Difference between eu_1 and eu_4") ///
    subtitle("3-month moving average") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
    legend(order(1 "Percent Difference" 2 "2016-2019 Average" 3 "Apr 2021-May 2023 Average") ///
           position(6) rows(1)) ///
    note("Source: Job Flow Data")

	

gen period = (date_monthly >= td(01sep2021) & date_monthly <= td(30dec2022))
drop if (date_monthly >= td(01Jan2020) & date_monthly < td(01sep2021))
drop if (date_monthly > td(30dec2022))

* Regression 1 




gen log_ee_educ_1_ma3 = log(eu_layoffs_org_wage_1 eu_layoffs_org_wage_4)
regress log_ee_educ_1_ma3 period
regress ee_educ_1_ma3  period 

* Regression 2 
gen log_ee_educ_1 = log(ee_educ_1)
regress log_ee_educ_1 period
regress ee_educ_1_ma3 period 	
	
	
	
	
	
	
	   
// Load the data
use "$output_dir\data\job_flow.dta", clear

// Keep only relevant variables
keep Date Year Month ue_educ_1 ee_educ_2

// Calculate percent difference (using log difference)
gen percent_diff = (log(ee_educ_1*100) - log(ee_educ_2*100))*100

// Calculate 3-month moving average
gen percent_diff_ma = (percent_diff + percent_diff[_n-1] + percent_diff[_n-2])/3

keep if Date >= td(01Jan2016)
// Calculate summary statistics
sum percent_diff_ma if Date >= td(01jan2016) & Date <= td(31dec2019)
local avg_2016_2019 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)

sum Date
local start_date = r(min)
local end_date = r(max)

sum percent_diff_ma if Date >= td(01apr2021) & Date <= td(30may2023)
local avg_apr21_may23 = r(mean)
local start_apr21 = td(01apr2021)
local end_may23 = td(30may2023)

// Create the plot
twoway (connected percent_diff_ma Date, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_apr21_may23', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("Percent Difference") ///
    title("Percent Difference between eu_1 and eu_4") ///
    subtitle("3-month moving average") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
    note("Source: Job Flow Data")
	   	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
********************************************
* regression: EE 
********************************************

keep date_monthly ee_pol ee_pol_ma3

gen period = (date_monthly >= td(01Apr2021) & date_monthly <= td(30May2023))
drop if (date_monthly >= td(01Jan2020) & date_monthly < td(01Apr2021))
drop if (date_monthly > td(30May2023))

* Regression 1 
regress ee_pol_ma3 period

* Regression 2 
regress ee_pol period
	   	   

	 
*************************************************************

use "$output_dir\data\job_flow.dta", clear 
rename Date date_monthly 
keep date_monthly ee_educ_1 ee_educ_2

* smoother version
gen ee_educ_1_ma3 = (ee_educ_1 + ee_educ_1[_n-1] + ee_educ_1[_n-2]) / 3 if _n > 2
gen ee_educ_2_ma3 = (ee_educ_2 + ee_educ_2[_n-1] + ee_educ_2[_n-2]) / 3 if _n > 2


*********************
* less than hs 
*********************

* pre period 
sum ee_educ_1_ma3 if date_monthly >= td(01jan2016) & date_monthly <= td(30dec2019)
local avg_2016_2019_educ_1 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)

* inflation period 
sum ee_educ_1_ma3 if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_educ_1_inf_period = r(mean)

local start_apr21 = td(01april2021)
local end_may23 = td(30may2023)

* Plotting 
keep if date_monthly >= td(01jan2016)
sum date_monthly
local start_date = r(min)
local end_date = r(max)

twoway (connected ee_educ_1_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019_educ_1', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_educ_1_inf_period', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)		
	
graph export "$output_dir/figures/ee_educ_1.png", replace		
	

preserve 

gen period = (date_monthly >= td(01sep2021) & date_monthly <= td(30dec2022))
drop if (date_monthly >= td(01Jan2020) & date_monthly < td(01sep2021))
drop if (date_monthly > td(30dec2022))

* Regression 1 
gen log_ee_educ_1_ma3 = log(ee_educ_1_ma3)
regress log_ee_educ_1_ma3 period
regress ee_educ_1_ma3  period 

* Regression 2 
gen log_ee_educ_1 = log(ee_educ_1)
regress log_ee_educ_1 period
regress ee_educ_1_ma3 period 
restore 

*********************
* college+
*********************

* pre period 
sum ee_educ_2_ma3 if date_monthly >= td(01jan2016) & date_monthly <= td(30dec2019)
local avg_2016_2019_educ_2 = r(mean)
local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)

* inflation period 
sum ee_educ_2_ma3 if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_educ_2_inf_period = r(mean)

local start_apr21 = td(01april2021)
local end_may23 = td(30may2023)

* Plotting 
keep if date_monthly >= td(01jan2016)
sum date_monthly
local start_date = r(min)	
local end_date = r(max)

twoway (connected ee_educ_2_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019_educ_2', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_educ_2_inf_period', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)		
	
graph export "$output_dir/figures/ee_educ_2.png", replace		
	


gen period = (date_monthly >= td(01sep2021) & date_monthly <= td(30dec2022))
drop if (date_monthly >= td(01Jan2020) & date_monthly < td(01sep2021))
drop if (date_monthly > td(30dec2022))

* Regression 1 
gen log_ee_educ_2_ma3 = log(ee_educ_2_ma3)

* logs 
regress log_ee_educ_2_ma3 period

* levels 
regress ee_educ_2_ma3 period 

* Regression 2 
gen log_ee_educ_2 = log(ee_educ_2)

* logs 
regress log_ee_educ_2 period

* levels 
regress ee_educ_2_ma3 period 



use "$temp_dir/cps_bas"




















use "$output_dir\data\job_flow.dta", clear 

rename Date date_monthly 
rename Year year 
rename Month month 

keep year month date_monthly ee_pol ee_org_wage_1 ee_org_wage_2 ee_org_wage_3 ee_org_wage_4 ee_educ_1 ee_educ_2 ee_educ_3 ee_educ_4 ee_educ_5 ee_educ_6 

************************************************************************************
* Pooled EE 
************************************************************************************

* pre inflation period 
sum ee_pol if date_monthly >= td(01jan2016) & date_monthly <= td(31dec2019)
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







/*
* Calculate averages for specific periods

************************************************
* 12 month inflation period 
************************************************

sum ee_pol if date_monthly >= td(01jun2021) & date_monthly <= td(30jun2022)
local avg_jun21_jun22 = r(mean)

local start_jun21 = td(01jun2021)
local end_jun22 = td(30jun2022)

twoway (connected ee_pol date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_jun22', range(`start_jun21' `end_jun22') lcolor(red) lpattern(dash)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("Rate") ///
    title("EE") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xmtick(, nolabels ticks) ///
    xtitle("") ///
    legend(off)

*************************************************
* 18 month inflation period 
*************************************************

sum ee_pol if date_monthly >= td(01jun2021) & date_monthly <= td(30dec2022)
local avg_jun21_dec22 = r(mean)


local start_jun21 = td(01jun2021)
local end_dec22 = td(30dec2022)

twoway (connected ee_pol date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) ///
       (function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_dec22', range(`start_jun21' `end_dec22') lcolor(red) lpattern(dash)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("Rate") ///
    title("EE") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xmtick(, nolabels ticks) ///
    xtitle("") ///
    legend(off)	
restore 


*************************************************************
* Smoothed Version 
*************************************************************

* select your time period 
keep if year >=2015


sum date_monthly
local start_date = r(min)
local end_date = r(max)

sort date_monthly

gen ee_pol_ma3 = (ee_pol + ee_pol[_n-1] + ee_pol[_n-2]) / 3 if _n > 2

keep if year >=2016
sum date_monthly
local start_date = r(min)
local end_date = r(max)

************************************************
* 12 month inflation period 
************************************************

sum ee_pol_ma3 if date_monthly >= td(01jun2021) & date_monthly <= td(30jun2022)
local avg_jun21_jun22 = r(mean)

local start_jun21 = td(01jun2021)
local end_jun22 = td(30jun2022)


twoway (connected ee_pol_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_jun22', range(`start_jun21' `end_jun22') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    title("EE") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)	
	
	
************************************************
* 18 month inflation period 
************************************************

sum ee_pol_ma3 if date_monthly >= td(01jun2021) & date_monthly <= td(30dec2022)
local avg_jun21_dec22 = r(mean)

local start_jun21 = td(01jun2021)
local end_dec22 = td(30dec2022)


twoway (connected ee_pol_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_dec22', range(`start_jun21' `end_dec22') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    title("EE") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)	
	
	
****************************************************
* Percent deviations 
****************************************************	
preserve
keep if year >=2016
keep if year < 2020 

collapse (mean) ee_pol_pre = ee_pol ee_org_wage_1_pre = ee_org_wage_1 ee_org_wage_2_pre = ee_org_wage_2 ee_org_wage_3_pre = ee_org_wage_3 ee_org_wage_4_pre = ee_org_wage_4 ee_educ_1_pre = ee_educ_1 ee_educ_2_pre = ee_educ_2 ee_educ_3_pre = ee_educ_3 ee_educ_4_pre = ee_educ_4 ee_educ_5_pre = ee_educ_5 ee_educ_6_pre = ee_educ_6, by(month)

save "$temp_dir/ee_pre_period.dta", replace 		 
restore 	

preserve 	
merge m:1 month using "$temp_dir/ee_pre_period.dta"

sort year month 
*gen ee_pol_ma3 = (ee_pol + ee_pol[_n-1] + ee_pol[_n-2]) / 3 if _n > 2
gen ee_pol_pre_ma3 = (ee_pol_pre + ee_pol_pre[_n-1] + ee_pol_pre[_n-2]) / 3 if _n > 2
	
gen ee_pol_dev = ((ee_pol_ma3/ee_pol_pre_ma3) - 1)*100

keep if year >= 2021 
keep if year <= 2023
sort year month 
	
sort date_monthly
local start_jan21 = td(01jan2021)
local end_dec23 = td(30dec2023)


* Create the time series plot
twoway (connected ee_pol_dev date_monthly, msymbol(circle) mcolor(navy) lcolor(navy)) ///
       (function y = 0, range(date_monthly) lcolor(black) lpattern(solid)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("EE Policy Deviation (%)") ///
    title("EE Policy Deviation from Pre-2020 Average") ///
    subtitle("2021 onwards") ///
    xlabel(`start_jan21'(180)`end_dec23', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") ///
    legend(off)
	
	
keep if year <= 2022	
local start_jan21 = td(01jan2021)
local end_dec22 = td(30dec2022)
	
* Create the time series plot
twoway (connected ee_pol_dev date_monthly, msymbol(circle) mcolor(navy) lcolor(navy)) ///
       (function y = 0, range(date_monthly) lcolor(black) lpattern(solid)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("% deviation") ///
    title("EE") ///
    xlabel(`start_jan21'(90)`end_dec22', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") ///
    legend(off)
restore 
*/ 
		
******************************************************
* EE by quartie - compare 1 and 4 
******************************************************	

sort date_monthly

gen ee_org_wage_1_ma3 = (ee_org_wage_1 + ee_org_wage_1[_n-1] + ee_org_wage_1[_n-2]) / 3 if _n > 2
gen ee_org_wage_4_ma3 = (ee_org_wage_4 + ee_org_wage_4[_n-1] + ee_org_wage_4[_n-2]) / 3 if _n > 2

sum date_monthly
local start_date = r(min)
local end_date = r(max)

twoway (connected ee_org_wage_1_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
       (connected ee_org_wage_4_ma3 date_monthly, msymbol(square_hollow) mcolor(green) lcolor(green)), ///
       ylabel(, angle(horizontal)) ///
       ytitle("Smoothed Rate") ///
       title("EE") ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) /// 
       xtitle("") ///
       legend(order(1 "Q1" 2 "Q4"))

graph export "$output_dir/figures/ee_q1_q4.png", replace	



******************************************************
* EE by education - compare hs grad vs college grad 
******************************************************		

sort date_monthly

* HS Grad 
gen ee_educ_2_ma3 = (ee_educ_2 + ee_educ_2[_n-1] + ee_educ_2[_n-2]) / 3 if _n > 2

sum date_monthly
local start_date = r(min)
local end_date = r(max)
twoway (connected ee_educ_2_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)), /// 
       ylabel(, angle(horizontal)) ///
       ytitle("Smoothed Rate") ///
       title("EE - HS Grad") ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
       xtitle("") ///
       legend(off)
	   
graph export "$output_dir/figures/ee_hs.png", replace	
	   
* College Grad 	   
gen ee_educ_5_ma3 = (ee_educ_5 + ee_educ_5[_n-1] + ee_educ_5[_n-2]) / 3 if _n > 2
sum date_monthly
local start_date = r(min)
local end_date = r(max)
twoway (connected ee_educ_5_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)), /// 
       ylabel(, angle(horizontal)) ///
       ytitle("Smoothed Rate") ///
       title("EE - College Grad") ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
       xtitle("") ///
       legend(off)
	   
graph export "$output_dir/figures/ee_college.png", replace		   
	   
* Masters, Professional, Doctoral Grad 	 
  
gen ee_educ_6_ma3 = (ee_educ_6 + ee_educ_6[_n-1] + ee_educ_6[_n-2]) / 3 if _n > 2
sum date_monthly
local start_date = r(min)
local end_date = r(max)
twoway (connected ee_educ_6_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)), /// 
       ylabel(, angle(horizontal)) ///
       ytitle("Smoothed Rate") ///
       title("EE - Masters, Professional, Doctoral") ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
       xtitle("") ///
       legend(off)

graph export "$output_dir/figures/ee_masters+.png", replace	
	





*********************************
* FMP Series 
*********************************

import excel using "$data_dir\ee_fmp.xlsx", sheet("Data") firstrow clear
rename FMP_SA ee_pol	
gen date_monthly = mdy(month, 1, year)
format date_monthly %td
keep year month date_monthly ee_pol

preserve
keep if year >=2016
keep if year < 2020 

collapse (mean) ee_pol_pre = ee_pol, by(month)

save "$temp_dir/ee_pre_period.dta", replace 		 
restore 	
	
merge m:1 month using "$temp_dir/ee_pre_period.dta"

sort year month 
gen ee_pol_ma3 = (ee_pol + ee_pol[_n-1] + ee_pol[_n-2]) / 3 if _n > 2
gen ee_pol_pre_ma3 = (ee_pol_pre + ee_pol_pre[_n-1] + ee_pol_pre[_n-2]) / 3 if _n > 2
	
gen ee_pol_dev = ((ee_pol_ma3/ee_pol_pre_ma3) - 1)*100

preserve 
keep if year >= 2021 
keep if year <= 2023
sort year month 
	
sort date_monthly
local start_jan21 = td(01jan2021)
local end_dec23 = td(30dec2023)

* Create the time series plot
twoway (connected ee_pol_dev date_monthly, msymbol(circle) mcolor(navy) lcolor(navy)) ///
       (function y = 0, range(date_monthly) lcolor(black) lpattern(solid)), ///
    ylabel(, angle(horizontal)) ///
    ytitle("% deviation") ///
    title("EE") ///
    xlabel(`start_jan21'(90)`end_dec23', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") ///
    legend(off)	
	
graph export "$output_dir/figures/ee_pol_fmp_deviation.png", replace
restore 


* select your time period 
keep if year >=2015


sum date_monthly
local start_date = r(min)
local end_date = r(max)

sort date_monthly

keep if year >=2016
sum date_monthly
local start_date = r(min)
local end_date = r(max)

* pre inflation period 
sum ee_pol if date_monthly >= td(01jan2016) & date_monthly <= td(31dec2019)
local avg_2016_2019 = r(mean)

************************************************
* 12 month inflation period 
************************************************


sum ee_pol_ma3 if date_monthly >= td(01jun2021) & date_monthly <= td(30jun2022)
local avg_jun21_jun22 = r(mean)

local start_jun21 = td(01jun2021)
local end_jun22 = td(30jun2022)


twoway (connected ee_pol_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_jun22', range(`start_jun21' `end_jun22') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    title("EE") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)	
		
graph export "$output_dir/figures/ee_fmp_smoothed_rate12.png", replace	
	
	
	
************************************************
* 18 month inflation period 
************************************************

sum ee_pol_ma3 if date_monthly >= td(01jun2021) & date_monthly <= td(30dec2022)
local avg_jun21_dec22 = r(mean)

local start_jun21 = td(01jun2021)
local end_dec22 = td(30dec2022)


twoway (connected ee_pol_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_jun21_dec22', range(`start_jun21' `end_dec22') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    title("EE") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)		
	
graph export "$output_dir/figures/ee_fmp_smoothed_rate18.png", replace		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
******************************************************
* EE by quartie - compare 1 and 4 
******************************************************	

sort date_monthly

gen ee_org_wage_1_ma3 = (ee_org_wage_1 + ee_org_wage_1[_n-1] + ee_org_wage_1[_n-2]) / 3 if _n > 2
gen ee_org_wage_4_ma3 = (ee_org_wage_4 + ee_org_wage_4[_n-1] + ee_org_wage_4[_n-2]) / 3 if _n > 2

sum date_monthly
local start_date = r(min)
local end_date = r(max)

twoway (connected ee_org_wage_1_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
       (connected ee_org_wage_4_ma3 date_monthly, msymbol(square_hollow) mcolor(green) lcolor(green)), ///
       ylabel(, angle(horizontal)) ///
       ytitle("Smoothed Rate") ///
       title("EE") ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) /// 
       xtitle("") ///
       legend(order(1 "Q1" 2 "Q4"))

graph export "$output_dir/figures/ee_q1_q4.png", replace	

******************************************************
* EE by quartie - compare 2 and 3 
******************************************************	
	   
gen ee_org_wage_2_ma3 = (ee_org_wage_2 + ee_org_wage_2[_n-1] + ee_org_wage_2[_n-2]) / 3 if _n > 2
gen ee_org_wage_3_ma3 = (ee_org_wage_3 + ee_org_wage_3[_n-1] + ee_org_wage_3[_n-2]) / 3 if _n > 2

sum date_monthly
local start_date = r(min)
local end_date = r(max)

twoway (connected ee_org_wage_3_ma3 date_monthly, msymbol(square_hollow) mcolor(green) lcolor(green)), ///
       ylabel(, angle(horizontal)) ///
       ytitle("Smoothed Rate") ///
       title("EE - Q3") ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) /// 
       xtitle("") ///
       legend(off)
	
******************************************************
* EE by education - compare hs grad vs college grad 
******************************************************		

sort date_monthly

* HS Grad 
gen ee_educ_2_ma3 = (ee_educ_2 + ee_educ_2[_n-1] + ee_educ_2[_n-2]) / 3 if _n > 2

sum date_monthly
local start_date = r(min)
local end_date = r(max)
twoway (connected ee_educ_2_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)), /// 
       ylabel(, angle(horizontal)) ///
       ytitle("Smoothed Rate") ///
       title("EE - HS Grad") ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
       xtitle("") ///
       legend(off)
	   
graph export "$output_dir/figures/ee_hs.png", replace	
	   
* College Grad 	   
gen ee_educ_5_ma3 = (ee_educ_5 + ee_educ_5[_n-1] + ee_educ_5[_n-2]) / 3 if _n > 2
sum date_monthly
local start_date = r(min)
local end_date = r(max)
twoway (connected ee_educ_5_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)), /// 
       ylabel(, angle(horizontal)) ///
       ytitle("Smoothed Rate") ///
       title("EE - College Grad") ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
       xtitle("") ///
       legend(off)
	   
graph export "$output_dir/figures/ee_college.png", replace		   
	   
* College Grad 	   
gen ee_educ_6_ma3 = (ee_educ_6 + ee_educ_6[_n-1] + ee_educ_6[_n-2]) / 3 if _n > 2
sum date_monthly
local start_date = r(min)
local end_date = r(max)
twoway (connected ee_educ_6_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)), /// 
       ylabel(, angle(horizontal)) ///
       ytitle("Smoothed Rate") ///
       title("EE - Masters, Professional, Doctoral") ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
       xtitle("") ///
       legend(off)

graph export "$output_dir/figures/ee_masters+.png", replace	
	
	
		