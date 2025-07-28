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

    use "$proj_dir/data/processed/make_selection_table.dta", clear

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
use "$proj_dir/data/processed/make_selection_table.dta", clear

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

use "$proj_dir/data/processed/make_selection_table.dta", clear
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
file open `f' using "/Users/giyoung/Desktop/inflation_replication/scripts/selection_table/final_table.tex", write replace text

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