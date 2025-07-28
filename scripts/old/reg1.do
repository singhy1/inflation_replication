* Yash Singh 
* date: 8/14/24 
* distributional regression analysis - this script generates regression results 

global data_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\raw_data"
global temp_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\temp"
global output_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\output"

********************************
* EE 
********************************

* aggregate flows 
import excel using "$data_dir\ee_fmp.xlsx", sheet("Data") firstrow clear
rename FMP_SA ee_pol	
gen date_monthly = mdy(month, 1, year)
format date_monthly %td
keep year month date_monthly ee_pol

sort year month 
gen ee_pol_ma3 = (ee_pol + ee_pol[_n-1] + ee_pol[_n-2]) / 3 if _n > 2

replace ee_pol_ma3 = ee_pol_ma3*100
replace ee_pol = ee_pol*100 
gen log_ee = log(ee_pol)

keep date_monthly ee_pol ee_pol_ma3 log_ee
 
* Save the data to the tempfile
save "$temp_dir/temp_ee_data.dta", replace


* flows by education 
use "$output_dir\data\job_flow.dta", clear			 
rename Date date_monthly
keep date_monthly ee_educ_1 ee_educ_2 
gen ee_educ_1_ma3 = ee_educ_1*100 
gen ee_educ_2_ma3 = ee_educ_2*100

gen log_ee_educ_1 = log(ee_educ_1_ma3)
gen log_ee_educ_2 = log(ee_educ_2_ma3)

keep date_monthly ee_educ_1_ma3 ee_educ_2_ma3 log_ee_educ_1 log_ee_educ_2
save "$temp_dir/ee_educ_flows.dta", replace 

***********************************
*
***********************************
use "$temp_dir/shimer_macro_flows.dta", clear 

keep YEAR MONTH date_monthly ue_rate_ma3 eu_rate_ma3 

replace eu_rate_ma3 = eu_rate_ma3*100 
replace ue_rate_ma3 = ue_rate_ma3*100

gen log_eu = log(eu_rate_ma3)
gen log_ue = log(ue_rate_ma3) 

merge 1:1 date_monthly using "$temp_dir/temp_ee_data.dta"
drop _merge 
merge 1:1 date_monthly using "$temp_dir/ee_educ_flows.dta"

gen pre_period = (date_monthly >= td(01jan2016) & date_monthly <= td(01dec2019))



gen inf_period = (date_monthly >= td(01apr2021) & date_monthly <= td(01dec2022))
*gen inf_period = (date_monthly >= td(01apr2021) & date_monthly <= td(01may2023))

drop if ((date_monthly >= td(01jan2020) & date_monthly < td(01apr2021)) | date_monthly > td(01dec2022) | date_monthly < td(01jan2016)) 
*drop if ((date_monthly >= td(01jan2020) & date_monthly < td(01apr2021)) | date_monthly > td(01may2023) | date_monthly < td(01jan2016)) 

regress log_ue inf_period
eststo model1

regress log_ee inf_period
eststo model2

regress log_ee_educ_1 inf_period
eststo model3

regress log_ee_educ_2 inf_period 
eststo model4 

* Export to LaTeX with notes
esttab model1 model2 model3 model4 using "$output_dir/regressions/flow_regression_1.tex", ///
    replace tex label b(4) se(4) ///
    title("Regression Results") ///
    addnotes("Standard errors in parentheses" ///
             "Significance levels: * p<0.1, ** p<0.05, *** p<0.01")

***************************************************************************


use "$temp_dir/shimer_macro_flows.dta", clear 

keep YEAR MONTH date_monthly ue_rate ue_rate_ma3 eu_rate_ma3 

*replace eu_rate_ma3 = eu_rate * 100 
replace ue_rate = ue_rate * 100

gen log_eu = log(eu_rate)
gen log_ue = log(ue_rate) 

merge 1:1 date_monthly using "$temp_dir/temp_ee_data.dta"
drop _merge 
merge 1:1 date_monthly using "$temp_dir/ee_educ_flows.dta"
drop if (date_monthly < td(01jan2016))


* 2 periods 
/*
gen inf_period_1 = (date_monthly >= td(01apr2021) & date_monthly <= td(01dec2021))
replace inf_period_1 = 2 if (date_monthly >= td(01jan2022) & date_monthly <= td(01dec2022))
replace inf_period_1 = 3 if (date_monthly >= td(01jan2023) & date_monthly <= td(01dec2023))
drop if (date_monthly > td(01dec2023)) 
*/ 

* 3 periods 

gen inf_period_1 = (date_monthly >= td(01apr2021) & date_monthly <= td(01sep2021))
replace inf_period_1 = 2 if (date_monthly >= td(01oct2021) & date_monthly <= td(01mar2022))
replace inf_period_1 = 3 if (date_monthly >= td(01apr2022) & date_monthly <= td(01sept2022))
replace inf_period_1 = 4 if (date_monthly >= td(01oct2022) & date_monthly <= td(01mar2023))
*replace inf_period_1 = 5 if (date_monthly >= td(01apr2023) & date_monthly <= td(01sept2023))
drop if  (date_monthly > td(01sep2023)) 


* exclude covid 
drop if (date_monthly >= td(01jan2020) & date_monthly <= td(01mar2021))

* Run the regression with the pre-period as the base category
regress log_ue i.inf_period
eststo model1

regress log_ee i.inf_period
eststo model2


regress log_ee_educ_1 i.inf_period
eststo model3

regress log_ee_educ_2 i.inf_period
eststo model4 


* Export to LaTeX with notes
esttab model3 model4 using "$output_dir/regressions/flow_regression_1.tex", ///
    replace tex label b(4) se(4) ///
    title("Regression Results") ///
    addnotes("Standard errors in parentheses" ///
             "Significance levels: * p<0.1, ** p<0.05, *** p<0.01")













*regress eu_rate_ma3 inf_period
*regress ue_rate_ma3 inf_period 

************************
* layoff margin  

use "$output_dir\data\job_flow.dta", clear


************************
* layoff margin  
keep Date Year Month eu_layoffs_org_wage_1 eu_layoffs_org_wage_4
rename Date date_monthly


gen log_eu_layoffs_1 = log(eu_layoffs_org_wage_1*100)
gen log_eu_layoffs_4 = log(eu_layoffs_org_wage_4*100)

gen log_eu_layoffs_1_ma3 = (log_eu_layoffs_1 + log_eu_layoffs_1[_n-1] + log_eu_layoffs_1[_n-2])/3 
gen log_eu_layoffs_4_ma3 = (log_eu_layoffs_4 + log_eu_layoffs_4[_n-1] + log_eu_layoffs_4[_n-2])/3 


gen period = (date_monthly >= td(01oct2021) & date_monthly <= td(01dec2022))

keep if date_monthly >= td(01jan2016)
drop if date_monthly >= td(01apr2023)

regress log_eu_layoffs_1_ma3 period
regress log_eu_layoffs_4_ma3  period 

