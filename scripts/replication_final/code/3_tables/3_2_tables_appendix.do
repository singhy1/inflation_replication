clear all
set more off

global data_dir "/Users/giyoung/Desktop/inflation_replication/scripts/replication_final/data/raw"
global temp_dir "/Users/giyoung/Desktop/inflation_replication/scripts/replication_final/data/moments/temp"
global output_dir "/Users/giyoung/Desktop/inflation_replication/scripts/replication_final/output/tables"

******* Table B.1 ******************************************************************

quietly infix                   ///
  int     year         1-4      ///
  long    serial       5-9      ///
  byte    month        10-11    ///
  double  hwtfinl      12-21    ///
  double  cpsid        22-35    ///
  byte    asecflag     36-36    ///
  byte    mish         37-37    ///
  byte    region       38-39    ///
  byte    pernum       40-41    ///
  double  wtfinl       42-55    ///
  double  cpsidv       56-70    ///
  double  cpsidp       71-84    ///
  double  earnweek2    85-92    ///
  double  hourwage2    93-97    ///
  byte    age          98-99    ///
  byte    sex          100-100  ///
  int     race         101-103  ///
  byte    nativity     104-104  ///
  byte    empstat      105-106  ///
  byte    labforce     107-107  ///
  int     occ1990      108-110  ///
  byte    classwkr     111-112  ///
  int     uhrswork1    113-115  ///
  byte    durunem2     116-117  ///
  byte    whyunemp     118-118  ///
  byte    wkstat       119-120  ///
  byte    empsame      121-122  ///
  int     educ         123-125  ///
  double  earnwt       126-135  ///
  double  compwt       136-149  ///
  double  lnkfw1mwt    150-163  ///
  double  hourwage     164-168  ///
  byte    paidhour     169-169  ///
  double  earnweek     170-177  ///
  int     uhrsworkorg  178-180  ///
  byte    wksworkorg   181-182  ///
  using `"$data_dir/cps/cps_00111.dat"'

replace hwtfinl     = hwtfinl     / 10000
replace wtfinl      = wtfinl      / 10000
replace earnweek2   = earnweek2   / 100
replace hourwage2   = hourwage2   / 100
replace earnwt      = earnwt      / 10000
replace compwt      = compwt      / 10000
replace lnkfw1mwt   = lnkfw1mwt   / 10000
replace hourwage    = hourwage    / 100
replace earnweek    = earnweek    / 100

format hwtfinl     %10.4f
format cpsid       %14.0f
format wtfinl      %14.4f
format cpsidv      %15.0f
format cpsidp      %14.0f
format earnweek2   %8.2f
format hourwage2   %5.2f
format earnwt      %10.4f
format compwt      %14.4f
format lnkfw1mwt   %14.4f
format hourwage    %5.2f
format earnweek    %8.2f

label var year        `"Survey year"'
label var serial      `"Household serial number"'
label var month       `"Month"'
label var hwtfinl     `"Household weight, Basic Monthly"'
label var cpsid       `"CPSID, household record"'
label var asecflag    `"Flag for ASEC"'
label var mish        `"Month in sample, household level"'
label var region      `"Region and division"'
label var pernum      `"Person number in sample unit"'
label var wtfinl      `"Final Basic Weight"'
label var cpsidv      `"Validated Longitudinal Identifier"'
label var cpsidp      `"CPSID, person record"'
label var earnweek2   `"Weekly earnings (rounded)"'
label var hourwage2   `"Hourly wage (rounded)"'
label var age         `"Age"'
label var sex         `"Sex"'
label var race        `"Race"'
label var nativity    `"Foreign birthplace or parentage"'
label var empstat     `"Employment status"'
label var labforce    `"Labor force status"'
label var occ1990     `"Occupation, 1990 basis"'
label var classwkr    `"Class of worker "'
label var uhrswork1   `"Hours usually worked per week at main job"'
label var durunem2    `"Continuous weeks unemployed, intervalled"'
label var whyunemp    `"Reason for unemployment"'
label var wkstat      `"Full or part time status"'
label var empsame     `"Still working for same employer"'
label var educ        `"Educational attainment recode"'
label var earnwt      `"Earnings weight"'
label var compwt      `"Composite Weight for replicating BLS labor force estimates"'
label var lnkfw1mwt   `"Longitudinal weight for two adjacent months (BMS only)"'
label var hourwage    `"Hourly wage"'
label var paidhour    `"Paid by the hour"'
label var earnweek    `"Weekly earnings"'
label var uhrsworkorg `"Usual hours worked per week, outgoing rotation groups"'
label var wksworkorg  `"Weeks worked per year, outgoing rotation groups"'

rename year YEAR 
rename month MONTH 
rename cpsid CPSID 
rename cpsidp CPSIDP 
rename mish MISH 
rename wtfinl WTFINL 
rename age AGE 
rename sex SEX 
rename empstat EMPSTAT 
rename labforce LABFORCE 
rename occ1990 OCC1990
rename empsame EMPSAME
rename whyunemp WHYUNEMP
rename educ EDUC 
rename lnkfw1mwt LNKFW1MWT
rename hourwage HOURWAGE 
rename paidhour PAIDHOUR 
rename earnweek EARNWEEK 
rename uhrsworkorg UHRSWORKORG 
rename earnwt EARNWT
rename uhrswork1 UHRSWORK1
rename hourwage2 HOURWAGE2
rename earnweek2 EARNWEEK2
rename race RACE 
rename region REGION
rename nativity NATIVITY 
rename classwkr CLASSWKR
rename durunem2 DURUNEM2  

*****************************************************
*****************************************************

* Sample Selection 
keep if YEAR >= 2014

* prime age workers 
keep if AGE >= 15
keep if AGE <= 64

* Education 
gen date_monthly = mdy(MONTH, 1, YEAR)
format date_monthly %td

gen educ = .
replace educ = 1 if EDUC < 111
replace educ = 2 if EDUC >= 111
label define educ_label 1 "Less than College" 2 "College+"
label values educ educ_label

label define sex_lbl 1 "Male" 2 "Female"  
label values SEX sex_lbl                

keep if date_monthly >= td(01jan2016)

format date_monthly %tm

* Create employment flag
gen emp_flag = (EMPSTAT >= 10 & EMPSTAT <= 12)

* Keep relevant variables
keep date_monthly educ SEX emp_flag WTFINL
sort date_monthly educ SEX

* Define periods in a loop-friendly way
gen pre_period         = inrange(date_monthly, td(01jan2016), td(01dec2019))
gen inf_period         = inrange(date_monthly, td(01apr2021), td(01may2023))
gen post_period        = inrange(date_monthly, td(01apr2021), td(01dec2024))
gen early_post_period  = inrange(date_monthly, td(01apr2021), td(01dec2021))
gen late_post_period   = inrange(date_monthly, td(01jan2022), td(01dec2024))

* --------- OVERALL EMP-POP RATIO BY PERIOD ---------
local periods pre_period inf_period post_period early_post_period late_post_period
* --------- OVERALL EMP-POP RATIO ---------
foreach per of local periods {
	preserve
		by date_monthly: egen emp_stock = total(WTFINL * emp_flag)
		by date_monthly: egen pop = total(WTFINL)
		gen emp_pop_ratio = emp_stock / pop

		collapse (mean) emp_pop_ratio, by(`per')
		keep if `per' == 1
		gen period = "`=upper("`per'")'"
		save "$temp_dir/overall_`per'.dta", replace
	restore
}

* --------- GROUPED EMP-POP RATIO BY SEX × EDUC ---------
by date_monthly educ SEX: egen emp_stock = total(WTFINL * emp_flag)
by date_monthly educ SEX: egen pop = total(WTFINL)
gen emp_pop_ratio = emp_stock / pop

foreach per of local periods {
	preserve
		collapse (mean) emp_pop_ratio, by(SEX educ `per')
		keep if `per' == 1
		gen period = upper("`per'")
		save "$temp_dir/grouped_`per'.dta", replace
	restore
}

* --------- COMBINE RESULTS ---------
* Combine grouped
use "$temp_dir/grouped_pre_period.dta", clear
foreach per of local periods {
	if "`per'" != "pre_period" {
		append using "$temp_dir/grouped_`per'.dta"
	}
}

* Add overall
foreach per of local periods {
	append using "$temp_dir/overall_`per'.dta"
}

* Clean and export
drop pre_period inf_period post_period early_post_period late_post_period
export delimited using "$output_dir/table_B_1.csv", replace

* --------- CLEANUP TEMP FILES ---------
foreach per of local periods {
    erase "$temp_dir/overall_`per'.dta"
    erase "$temp_dir/grouped_`per'.dta"
}
