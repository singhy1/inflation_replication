

clear 
global data_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\raw_data"
global temp_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\temp"
global output_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\output"


* FMP data 

import excel using "$data_dir\FMP\ee_fmp.xlsx", sheet("Data") firstrow clear
rename FMP_SA ee_pol	
gen date_monthly = mdy(month, 1, year)
format date_monthly %td
keep year month date_monthly ee_pol


*******************************************************************
** pre trends ***
preserve
keep if year >=2016
keep if year < 2020 

collapse (mean) ee_pol_pre = ee_pol, by(month)

save "$temp_dir/ee_pre_period.dta", replace 		 
restore 	
*******************************************************************

merge m:1 month using "$temp_dir/ee_pre_period.dta"

sort year month 
gen ee_pol_ma3 = (ee_pol + ee_pol[_n-1] + ee_pol[_n-2]) / 3 if _n > 2
gen ee_pol_pre_ma3 = (ee_pol_pre + ee_pol_pre[_n-1] + ee_pol_pre[_n-2]) / 3 if _n > 2
	
gen ee_pol_dev = ((ee_pol_ma3/ee_pol_pre_ma3) - 1)*100



* pre inflation period 
sum ee_pol if date_monthly >= td(01jan2016) & date_monthly <= td(31dec2019)
local avg_2016_2019 = r(mean)

local start_2016 = td(01jan2016)
local end_2019 = td(31dec2019)


************************************************
* April21 - May23 
************************************************
keep if year >=2016
sum date_monthly
local start_date = r(min)
local end_date = r(max)

sum ee_pol_ma3 if date_monthly >= td(01apr2021) & date_monthly <= td(30may2023)
local avg_apr21_may23 = r(mean)

local start_apr21 = td(30apr2021)
local end_may23 = td(30may2023)


twoway (connected ee_pol_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)) /// 
		(function y = `avg_2016_2019', range(`start_2016' `end_2019') lcolor(red) lpattern(dash)) ///
       (function y = `avg_apr21_may23', range(`start_apr21' `end_may23') lcolor(red) lpattern(dash)), ///, ///
    ylabel(, angle(horizontal)) ///
    ytitle("Smoothed Rate") ///
    title("EE") ///
    xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
    xtitle("") /// 
	legend(off)	
		
graph export "$output_dir/figures/ee_fmp_smoothed_rate12.png", replace	
	
	
/*	
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



/* 
preserve 
keep if year >= 2021 
keep if year <= 2023
sort year month 
	
sort date_monthly
local start_jan21 = td(01jan2021)
local end_dec23 = td(30dec2023)




* deviations from trend 
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




* Micro-Data for distributional Analysis 
*
*


use "$output_dir\data\job_flow.dta", clear 

rename Date date_monthly 
rename Year year 
rename Month month 

keep year month date_monthly ee_pol ee_org_wage_1 ee_org_wage_2 ee_org_wage_3 ee_org_wage_4 ee_educ_1 ee_educ_2 ee_educ_3 ee_educ_4 ee_educ_5 ee_educ_6 



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

* Associates 
gen ee_educ_3_ma3 = (ee_educ_3 + ee_educ_3[_n-1] + ee_educ_3[_n-2]) / 3 if _n > 2

sum date_monthly
local start_date = r(min)
local end_date = r(max)
twoway (connected ee_educ_3_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)), /// 
       ylabel(, angle(horizontal)) ///
       ytitle("Smoothed Rate") ///
       title("EE - Associate") ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
       xtitle("") ///
       legend(off)
	   
graph export "$output_dir/figures/ee_associate.png", replace		
	
	
	
	
* College Grad 	   
gen ee_educ_4_ma3 = (ee_educ_4 + ee_educ_4[_n-1] + ee_educ_4[_n-2]) / 3 if _n > 2
sum date_monthly
local start_date = r(min)
local end_date = r(max)
twoway (connected ee_educ_4_ma3 date_monthly, msymbol(circle_hollow) mcolor(navy) lcolor(navy)), /// 
       ylabel(, angle(horizontal)) ///
       ytitle("Smoothed Rate") ///
       title("EE - Some College") ///
       xlabel(`start_date'(180)`end_date', angle(45) format(%tdMon-YY) labsize(small)) ///
       xtitle("") ///
       legend(off)
	   
graph export "$output_dir/figures/ee_some_college.png", replace		   
	   
	
	
	
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



preserve 
keep if year >= 2021 
keep if year <= 2023
sort year month 
	
sort date_monthly
local start_jan21 = td(01jan2021)
local end_dec23 = td(30dec2023)




* deviations from trend 
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






