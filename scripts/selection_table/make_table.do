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

    * Step 2: Collapse to average share by group
    drop if missing(period)
    collapse (mean) share, by(jstayergroup period `current_var')

    * Step 3: Construct reshape stub with ordering control
    gen period_code = cond(period == "pre", "a_pre", ///
                          cond(period == "inf", "b_inf", "c_post"))
    gen group_code = cond(jstayergroup == "Job Stayer", "a_stayer", "b_switcher")
    gen str stub = group_code + "_" + period_code

    * Step 4: Prepare for reshaping
    drop period jstayergroup period_code group_code

    * Step 5: Reshape to wide format
    reshape wide share, i(`current_var') j(stub) string

    * Step 6: Rename columns and add group identifier
    gen group = "`current_name'"
    rename `current_var' group_val
    order group group_val

    * Step 7: Shorten wide column names
    * This part needs to be dynamic based on 'share' prefix
    ds share*
    foreach var of varlist `r(varlist)' {
        local short = subinstr("`var'", "share", "", .) // Remove 'share' prefix
        local short = subinstr("`short'", "a_stayer_a_pre", "stayer_pre", .)
        local short = subinstr("`short'", "a_stayer_b_inf", "stayer_inf", .)
        local short = subinstr("`short'", "a_stayer_c_post", "stayer_post", .)
        local short = subinstr("`short'", "b_switcher_a_pre", "switcher_pre", .)
        local short = subinstr("`short'", "b_switcher_b_inf", "switcher_inf", .)
        local short = subinstr("`short'", "b_switcher_c_post", "switcher_post", .)
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

use `final_data', clear

* Display final result (optional)
list


