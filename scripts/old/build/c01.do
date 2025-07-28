* Yash Singh 
* date: 7/11/24 
* goal: this script takes in the raw asec data and performs some cleaning and sample selection. 

set more off

global data_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\raw_data\CPS"
global temp_dir "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\temp"

cd "$data_dir\cps_00101.dat" 

clear
quietly infix                 ///
  int     year       1-4      ///
  long    serial     5-9      ///
  byte    month      10-11    ///
  double  cpsid      12-25    ///
  byte    asecflag   26-26    ///
  byte    hflag      27-27    ///
  double  asecwth    28-38    ///
  byte    pernum     39-40    ///
  double  cpsidv     41-55    ///
  double  cpsidp     56-69    ///
  double  asecwt     70-80    ///
  double  earnweek2  81-88    ///
  double  hourwage2  89-93    ///
  byte    age        94-95    ///
  byte    sex        96-96    ///
  int     race       97-99    ///
  byte    empstat    100-101  ///
  byte    labforce   102-102  ///
  int     occ1990    103-105  ///
  int     ind1990    106-108  ///
  byte    classwkr   109-110  ///
  int     uhrswork1  111-113  ///
  byte    durunem2   114-115  ///
  byte    whyunemp   116-116  ///
  int     educ       117-119  ///
  double  earnwt     120-129  ///
  int     occ90ly    130-132  ///
  int     ind90ly    133-135  ///
  byte    wkswork1   136-137  ///
  double  incwage    138-145  ///
  byte    paidhour   146-146  ///
  using `"cps_00101.dat"'

replace asecwth   = asecwth   / 10000
replace asecwt    = asecwt    / 10000
replace earnweek2 = earnweek2 / 100
replace hourwage2 = hourwage2 / 100
replace earnwt    = earnwt    / 10000

format cpsid     %14.0f
format asecwth   %11.4f
format cpsidv    %15.0f
format cpsidp    %14.0f
format asecwt    %11.4f
format earnweek2 %8.2f
format hourwage2 %5.2f
format earnwt    %10.4f
format incwage   %8.0f

label var year      `"Survey year"'
label var serial    `"Household serial number"'
label var month     `"Month"'
label var cpsid     `"CPSID, household record"'
label var asecflag  `"Flag for ASEC"'
label var hflag     `"Flag for the 3/8 file 2014"'
label var asecwth   `"Annual Social and Economic Supplement Household weight"'
label var pernum    `"Person number in sample unit"'
label var cpsidv    `"Validated Longitudinal Identifier"'
label var cpsidp    `"CPSID, person record"'
label var asecwt    `"Annual Social and Economic Supplement Weight"'
label var earnweek2 `"Weekly earnings (rounded)"'
label var hourwage2 `"Hourly wage (rounded)"'
label var age       `"Age"'
label var sex       `"Sex"'
label var race      `"Race"'
label var empstat   `"Employment status"'
label var labforce  `"Labor force status"'
label var occ1990   `"Occupation, 1990 basis"'
label var ind1990   `"Industry, 1990 basis"'
label var classwkr  `"Class of worker "'
label var uhrswork1 `"Hours usually worked per week at main job"'
label var durunem2  `"Continuous weeks unemployed, intervalled"'
label var whyunemp  `"Reason for unemployment"'
label var educ      `"Educational attainment recode"'
label var earnwt    `"Earnings weight"'
label var occ90ly   `"Occupation last year, 1990 basis"'
label var ind90ly   `"Industry last year, 1990 basis"'
label var wkswork1  `"Weeks worked last year"'
label var incwage   `"Wage and salary income"'
label var paidhour  `"Paid by the hour"'


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


/*
* Sample Selection 
* prime age workers 
keep if AGE >= 16
keep if AGE <= 55

* must be part of the labor force 
* keep if LABFORCE == 2

* self employed 
drop if CLASSWKR == 10
drop if CLASSWKR == 13
drop if CLASSWKR == 14 

* government employees 
drop if CLASSWKR == 24 
drop if CLASSWKR == 25 
drop if CLASSWKR == 26 
drop if CLASSWKR == 27 
drop if CLASSWKR == 28

* Unpaid family members 
drop if CLASSWKR == 29 

drop if INCWAGE == 0 
drop if WKSWORK1 <= 0 

* weekly earnings and wages 
gen weekly_earnings = INCWAGE / WKSWORK1
*gen hrly_earn       = INCWAGE / (WKSWORK1 * UHRSWORK1)			
		
*/ 

* Education 
gen educ = .
replace educ = 1 if EDUC < 111
replace educ = 2 if EDUC >= 111
label define educ_label 1 "Less than College" 2 "College+"
label values educ educ_label

keep if LABFORCE == 2

keep if AGE >= 25
keep if AGE <= 55

drop if INCWAGE == 0 
drop if WKSWORK1 <= 0 
keep if YEAR >= 2014

* weekly earnings and wages 
gen weekly_earnings = INCWAGE / WKSWORK1


save "$temp_dir\asec.dta", replace 