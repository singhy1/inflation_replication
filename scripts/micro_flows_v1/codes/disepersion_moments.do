set more off

global data_dir "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
global temp_dir "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/temp"
global output_dir "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output"

* CPI Cleanings 
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

cd "$data_dir/CPS/cps_00110.dat"

clear
quietly infix                  ///
  int     year        1-4      ///
  long    serial      5-9      ///
  byte    month       10-11    ///
  double  cpsid       12-25    ///
  byte    asecflag    26-26    ///
  double  asecwth     27-37    ///
  byte    pernum      38-39    ///
  double  cpsidp      40-53    ///
  double  cpsidv      54-68    ///
  double  asecwt      69-79    ///
  double  earnweek2   80-87    ///
  double  hourwage2   88-92    ///
  byte    age         93-94    ///
  byte    sex         95-95    ///
  int     race        96-98    ///
  byte    empstat     99-100   ///
  byte    labforce    101-101  ///
  int     occ1990     102-104  ///
  int     ind1990     105-107  ///
  byte    classwkr    108-109  ///
  int     uhrswork1   110-112  ///
  byte    durunem2    113-114  ///
  byte    whyunemp    115-115  ///
  int     educ        116-118  ///
  double  earnwt      119-128  ///
  int     occ90ly     129-131  ///
  int     ind90ly     132-134  ///
  byte    wkswork1    135-136  ///
  int     uhrsworkly  137-139  ///
  double  incwage     140-147  ///
  byte    paidhour    148-148  ///
  using `"cps_00110.dat"'

replace asecwth    = asecwth    / 10000
replace asecwt     = asecwt     / 10000
replace earnweek2  = earnweek2  / 100
replace hourwage2  = hourwage2  / 100
replace earnwt     = earnwt     / 10000

format cpsid      %14.0f
format asecwth    %11.4f
format cpsidp     %14.0f
format cpsidv     %15.0f
format asecwt     %11.4f
format earnweek2  %8.2f
format hourwage2  %5.2f
format earnwt     %10.4f
format incwage    %8.0f

label var year       `"Survey year"'
label var serial     `"Household serial number"'
label var month      `"Month"'
label var cpsid      `"CPSID, household record"'
label var asecflag   `"Flag for ASEC"'
label var asecwth    `"Annual Social and Economic Supplement Household weight"'
label var pernum     `"Person number in sample unit"'
label var cpsidp     `"CPSID, person record"'
label var cpsidv     `"Validated Longitudinal Identifier"'
label var asecwt     `"Annual Social and Economic Supplement Weight"'
label var earnweek2  `"Weekly earnings (rounded)"'
label var hourwage2  `"Hourly wage (rounded)"'
label var age        `"Age"'
label var sex        `"Sex"'
label var race       `"Race"'
label var empstat    `"Employment status"'
label var labforce   `"Labor force status"'
label var occ1990    `"Occupation, 1990 basis"'
label var ind1990    `"Industry, 1990 basis"'
label var classwkr   `"Class of worker "'
label var uhrswork1  `"Hours usually worked per week at main job"'
label var durunem2   `"Continuous weeks unemployed, intervalled"'
label var whyunemp   `"Reason for unemployment"'
label var educ       `"Educational attainment recode"'
label var earnwt     `"Earnings weight"'
label var occ90ly    `"Occupation last year, 1990 basis"'
label var ind90ly    `"Industry last year, 1990 basis"'
label var wkswork1   `"Weeks worked last year"'
label var uhrsworkly `"Usual hours worked per week (last yr)"'
label var incwage    `"Wage and salary income"'
label var paidhour   `"Paid by the hour"'

rename year YEAR 
rename month MONTH 
rename cpsid CPSID 
rename cpsidp CPSIDP 
rename asecwth ASECWTH
rename pernum PERNUM 
rename asecwt ASECWT
rename age AGE 
rename sex SEX 
rename race RACE 
rename empstat EMPSTAT 
rename labforce LABFORCE 
rename occ1990 OCC1990
rename ind1990 IND1990
rename occ90ly OCC90LY 
rename ind90ly IND90LY
rename classwkr CLASSWKR
rename uhrswork1 UHRSWORK1
rename earnwt EARNWT
rename incwage INCWAGE 
rename wkswork1 WKSWORK1 
rename hourwage2 HOURWAGE2
rename earnweek2 EARNWEEK2
rename educ EDUC 
rename paidhour PAIDHOUR
rename durunem2 DURUNEM2 


* sample selection 
keep if YEAR >= 2016
keep if YEAR <= 2019

* Full-year, Full-Time 
keep if AGE >= 25
keep if AGE <= 55 

* top coding and imputed wages are dropped 
drop if INCWAGE == 0 
*drop if INCWAGE > 150000

drop if WKSWORK1 < 40 
drop if uhrsworkly  < 35

* weekly earnings and wages 
gen weekly_earnings = INCWAGE / WKSWORK1

* hourly wage
gen hourly_wage = weekly_earnings/uhrsworkly 

drop if hourly_wage <= 2.13 


* Generate percentiles by year and month
bysort YEAR MONTH: egen p5_earnings = pctile(weekly_earnings), p(1)
bysort YEAR MONTH: egen p95_earnings = pctile(weekly_earnings), p(99)

* Drop observations outside the 3rd and 97th percentiles
drop if weekly_earnings < p5_earnings | weekly_earnings > p95_earnings

*drop if weekly_earnings < p5_earnings

* Clean up
drop p5_earnings p95_earnings



* Education 
gen educ = .
replace educ = 1 if EDUC < 111
replace educ = 2 if EDUC >= 111
label define educ_label 1 "Less than College" 2 "College+"
label values educ educ_label


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
gen real_wkly_earn = (weekly_earnings / avg_cpi_12m_lag ) * `price_index_q1_2019'
gen log_real_wkly_earn = log(real_wkly_earn) 

gen final_wgt = int(ASECWT)

keep YEAR MONTH AGE CPSIDP final_wgt real_wkly_earn log_real_wkly_earn 



* step 7: get weekly earnings by percentiles 

* All workers (25-55)
preserve 
*keep if real_hrly_earn > 3.75
keep if YEAR <= 2019
keep if YEAR >= 2016
collapse (p95) p95 = real_wkly_earn (p90) p90 = real_wkly_earn (p50) p50 = real_wkly_earn (p10) p10 = real_wkly_earn (sd) sd_log_real_wkly_earn = log_real_wkly_earn [fw=final_wgt], by (YEAR)
gen age_grp = "25-55"
save "$temp_dir/wkly_earn_moments_all.dta", replace 
restore 

* Young Workers (25-27)
preserve 
*keep if real_hrly_earn > 3.75
keep if YEAR <= 2019
keep if YEAR >= 2016
keep if AGE <= 27
collapse (p95) p95 = real_wkly_earn (p90) p90 = real_wkly_earn (p50) p50 = real_wkly_earn (p10) p10 = real_wkly_earn (p05) p05 = real_wkly_earn (sd) sd_log_real_wkly_earn = log_real_wkly_earn [fw=final_wgt], by (YEAR)


gen age_grp = "25-27"
save "$temp_dir/wkly_earn_moments_young_age.dta", replace 
restore 

preserve 
use "$temp_dir/wkly_earn_moments_all.dta", clear
append using "$temp_dir/wkly_earn_moments_young_age.dta"

collapse (mean) p95 p90 p50 p10 p05 sd_log, by(age_grp)
gen ratio_p95_p50 = p95 / p50 
gen ratio_p90_p50 = p90 / p50
gen ratio_p50_p10 = p50 / p10


gen wage_measure = "wkly"
save "$temp_dir/wkly_earn_moments.dta", replace 
restore 
