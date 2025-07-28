********************************************************************************
* TABLE GENERATION - APPENDIX TABLES (STATA)
* 
* Purpose: Generate tables for appendix
* 
* Description:
*   - Takes data from /replication_final/data/processed
*   - Creates formatted tables for appendix
*   - Outputs LaTeX-formatted tables to /replication_final/output/tables
*
* Tables Generated:
*   - Table B.1: Employment to Population Ratio Over Time, 15-64 Year Olds
*   - Table B.2: Selection Table
*
* Author: Yash Singh, Giyoung Kwon
* Last Updated: 2025/7/28
********************************************************************************

* Clear environment and set up
clear all
set more off


********************************************************************************
* SETUP: CONFIGURE PATHS AND DIRECTORIES
********************************************************************************

* Detect operating system for cross-platform compatibility
local os : environment OS
local is_win = strpos("`os'", "Windows") > 0

* Get username (cross-platform)
local user : environment USER
if "`user'" == "" local user : environment USERNAME  // For Windows systems

* Define base project directory path based on operating system
if `is_win' {
    global proj_dir "C:/Users/`user'/Dropbox/Labor_Market_PT/replication/final" 
}
else {
    global proj_dir "/Users/`user'/Library/CloudStorage/Dropbox/Labor_Market_PT/replication/final"
}

* Define input and output directories
global data_dir = "$proj_dir/data/raw"
global temp_dir = "$proj_dir/data/moments/temp"
global output_dir = "$proj_dir/output/tables"


********************************************************************************
* TABLE B.1: DEMOGRAPHICS AND SAMPLE CHARACTERISTICS
********************************************************************************

* Load and process CPS data for demographic analysis
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


******* Table B.2 ******************************************************************

********************************************************************************
* Define grouping variables and their corresponding display names
********************************************************************************
local group_vars "gengroup educ_group wagegroup racegroup"
local group_names "Gender Education Wage Race"

tempfile final_data

********************************************************************************
* Loop through each grouping variable to process data
********************************************************************************
forvalues i = 1/`=wordcount("`group_vars'")' {
    local current_var : word `i' of `group_vars'
    local current_name : word `i' of `group_names'

    use "$proj_dir/data/processed/table_B_2.dta", clear

    * Step 1: Aggregate to monthly shares for the current group
    collapse (sum) weight = weightbls98, by(jstayergroup period `current_var' date_monthly)
    gen total_weight = .
    bysort jstayergroup period date_monthly (`current_var'): replace total_weight = sum(weight)
    bysort jstayergroup period date_monthly (`current_var'): replace total_weight = total_weight[_N]
    gen share = weight / total_weight // Use a generic 'share' variable name

    * Step 2: Collapse to average share by group - exclude post period
    drop if missing(period) | period == "post"
    collapse (mean) share, by(jstayergroup period `current_var')
    
    * Debug: Check data before reshape
    list, clean

    * Step 3: Encode categorical variable to numeric for reshape
    encode `current_var', gen(`current_var'_num)
    drop `current_var'
    rename `current_var'_num `current_var'

    * Step 4: Construct reshape stub with ordering control
    gen str period_code = cond(period == "pre", "a_pre", "b_inf")
    gen str group_code = cond(jstayergroup == "Job Stayer", "a_stayer", "b_switcher")
    gen str stub = group_code + "_" + period_code
    
    * Debug: Check stub variable
    list `current_var' stub share, clean

    * Step 5: Prepare for reshaping
    drop period jstayergroup period_code group_code

    * Step 6: Reshape to wide format
    reshape wide share, i(`current_var') j(stub) string

    * Step 7: Filter for specific categories only
    if "`current_var'" == "gengroup" {
        keep if `current_var' == 2  // Keep only Male (Male gets encoded as 2, Female as 1)
        gen group_val = "Male"
    }
    else if "`current_var'" == "educ_group" {
        keep if `current_var' == 1  // Keep only Bachelors+
        gen group_val = "Bachelors+"
    }
    else if "`current_var'" == "racegroup" {
        keep if `current_var' == 1  // Keep only Non-White
        gen group_val = "Non-White"
    }
    else if "`current_var'" == "wagegroup" {
        // Keep all wage quartiles
        gen group_val = ""
        replace group_val = "1st Wage Quartile" if `current_var' == 1
        replace group_val = "2nd Wage Quartile" if `current_var' == 2
        replace group_val = "3rd Wage Quartile" if `current_var' == 3
        replace group_val = "4th Wage Quartile" if `current_var' == 4
    }

    * Step 8: Add group identifier and clean up
    gen group = "`current_name'"
    drop `current_var'
    order group group_val

    * Step 9: Shorten wide column names (remove post period columns)
    ds share*
    foreach var of varlist `r(varlist)' {
        local short = subinstr("`var'", "share", "", .) // Remove 'share' prefix
        local short = subinstr("`short'", "a_stayer_a_pre", "stayer_pre", .)
        local short = subinstr("`short'", "a_stayer_b_inf", "stayer_inf", .)
        local short = subinstr("`short'", "b_switcher_a_pre", "switcher_pre", .)
        local short = subinstr("`short'", "b_switcher_b_inf", "switcher_inf", .)
        rename `var' `short'
    }


    * Append to the final dataset
    if `i' == 1 {
        save `final_data', replace
    } 
	else {
        append using `final_data'
        save `final_data', replace
    }

}

********************************************************************************
* Add average age row for each jstayergroup x period combination
********************************************************************************
use "$proj_dir/data/processed/table_B_2.dta", clear

* Step A1: Collapse to average age by group - exclude post period
collapse (mean) age = age, by(jstayergroup period)
drop if missing(period) | period == "post"
* Step A2: Generate reshape stubs
gen period_code = cond(period == "pre", "a_pre", "b_inf")
gen group_code = cond(jstayergroup == "Job Stayer", "stayer", "switcher")

* Step A3: Generate columns for wide format
gen varname = group_code + "_" + substr(period_code, 3, .)

* Step A4: Reshape to wide
drop period jstayergroup period_code group_code
gen id = 1
reshape wide age, i(id) j(varname) string
drop id
* Step A5: Add identifying columns to match format
gen group = "Age"
gen group_val = "Average Age"
order group group_val

ds age*
foreach var of varlist `r(varlist)' {
    local newname = subinstr("`var'", "age", "", .)
    rename `var' `newname'
}

* Step A6: Append to final data
append using `final_data'
save `final_data', replace

use `final_data', clear

* Reorder columns: pre-stayer, pre-changer, inf-stayer, inf-changer
order group group_val ///
      stayer_pre switcher_pre stayer_inf switcher_inf

* Calculate differences between changer vs stayer in each period
gen diff_pre = switcher_pre - stayer_pre
gen diff_inf = switcher_inf - stayer_inf

********************************************************************************
* Run DID regressions and store p-values
********************************************************************************

* Initialize p-value variable
gen pval_did = .

* Load original micro data for regressions
tempfile main_data
save `main_data'

use "$proj_dir/data/processed/table_B_2.dta", clear
drop if missing(period) | period == "post"

* Create binary variables for DID regression
gen is_inf = (period == "inf")
gen is_switch = (jstayergroup == "Job Switcher")

* 1. Education (Bachelors+)
gen is_bach = (educ_group == "Bachelors+")
reg is_bach i.is_inf##i.is_switch, robust
matrix b = e(b)
matrix V = e(V)
scalar pval_educ = 2*ttail(e(df_r), abs(_b[1.is_inf#1.is_switch]/_se[1.is_inf#1.is_switch]))

* 2. Gender (Male)  
gen is_male = (gengroup == "Male")
reg is_male i.is_inf##i.is_switch, robust
scalar pval_gender = 2*ttail(e(df_r), abs(_b[1.is_inf#1.is_switch]/_se[1.is_inf#1.is_switch]))

* 3. Race (Non-White)
gen is_nonwhite = (racegroup == "Nonwhite") 
reg is_nonwhite i.is_inf##i.is_switch, robust
scalar pval_race = 2*ttail(e(df_r), abs(_b[1.is_inf#1.is_switch]/_se[1.is_inf#1.is_switch]))

* 4. Wage quartiles
forvalues q = 1/4 {
    if `q' == 1 {
        gen is_q`q' = (wagegroup == "1st")
    }
    else if `q' == 2 {
        gen is_q`q' = (wagegroup == "2nd")
    }
    else if `q' == 3 {
        gen is_q`q' = (wagegroup == "3rd")
    }
    else if `q' == 4 {
        gen is_q`q' = (wagegroup == "4th")
    }
    reg is_q`q' i.is_inf##i.is_switch, robust
    scalar pval_wage`q' = 2*ttail(e(df_r), abs(_b[1.is_inf#1.is_switch]/_se[1.is_inf#1.is_switch]))
}

* 5. Age (continuous)
reg age i.is_inf##i.is_switch, robust
scalar pval_age = 2*ttail(e(df_r), abs(_b[1.is_inf#1.is_switch]/_se[1.is_inf#1.is_switch]))

* Return to main data and add p-values
use `main_data', clear

* Assign p-values to each row
replace pval_did = pval_age if group == "Age"
replace pval_did = pval_educ if group == "Education" 
replace pval_did = pval_gender if group == "Gender"
replace pval_did = pval_race if group == "Race"
replace pval_did = pval_wage1 if group == "Wage" & group_val == "1st Wage Quartile"
replace pval_did = pval_wage2 if group == "Wage" & group_val == "2nd Wage Quartile" 
replace pval_did = pval_wage3 if group == "Wage" & group_val == "3rd Wage Quartile"
replace pval_did = pval_wage4 if group == "Wage" & group_val == "4th Wage Quartile"

* Display final result (optional)
list

* Round to 2 decimal points
foreach var in stayer_pre switcher_pre stayer_inf switcher_inf diff_pre diff_inf {
    replace `var' = round(`var', .01)
}

* Round p-values to 3 decimal points
replace pval_did = round(pval_did, .001)

********************************************************************************
* Generate LaTeX table with p-values
********************************************************************************

* Round values to 2 decimal points (in display only)
tempname f
file open `f' using "$output_dir/table_B_2.tex", write replace text

* Write LaTeX header - now with 9 columns
file write `f' "\begin{tabular}{llrrrrrrr}" _n
file write `f' "\toprule" _n
file write `f' "Group & Category & \multicolumn{2}{c}{Pre} & \multicolumn{2}{c}{Inf} & \multicolumn{2}{c}{Difference} & P-value \\\\" _n
file write `f' "\cmidrule(lr){3-4} \cmidrule(lr){5-6} \cmidrule(lr){7-8}" _n
file write `f' " & & Stayer & Changer & Stayer & Changer & Pre & Inf & (DID) \\\\" _n
file write `f' "\midrule" _n

* Loop over rows
quietly {
    sort group group_val
    levelsof group, local(groups)

    foreach g of local groups {
        preserve
        keep if group == "`g'"
        foreach row in group_val stayer_pre switcher_pre stayer_inf switcher_inf diff_pre diff_inf pval_did {
            capture confirm variable `row'
            if _rc == 111 {
                di as err "Variable `row' not found"
                continue
            }
        }

        gen double s_pre    = round(stayer_pre, .01)
        gen double sw_pre   = round(switcher_pre, .01)
        gen double s_inf    = round(stayer_inf, .01)
        gen double sw_inf   = round(switcher_inf, .01)
        gen double d_pre    = round(diff_pre, .01)
        gen double d_inf    = round(diff_inf, .01)
        gen double p_did    = round(pval_did, .001)

        levelsof group_val, local(vals)
        foreach v of local vals {
            su s_pre if group_val == "`v'", meanonly
            local x1 = string(r(mean), "%6.2f")
            su sw_pre if group_val == "`v'", meanonly
            local x2 = string(r(mean), "%6.2f")
            su s_inf if group_val == "`v'", meanonly
            local x3 = string(r(mean), "%6.2f")
            su sw_inf if group_val == "`v'", meanonly
            local x4 = string(r(mean), "%6.2f")
            su d_pre if group_val == "`v'", meanonly
            local x5 = string(r(mean), "%6.2f")
            su d_inf if group_val == "`v'", meanonly
            local x6 = string(r(mean), "%6.2f")
            su p_did if group_val == "`v'", meanonly
            local x7 = string(r(mean), "%6.3f")

            file write `f' "`g' & `v' & `x1' & `x2' & `x3' & `x4' & `x5' & `x6' & `x7' \\\\" _n
        }
        restore
    }
}

* Finish table
file write `f' "\bottomrule" _n
file write `f' "\end{tabular}" _n
file close `f'