* Yash Singh 
* this script computes the employment to population ratio for 25-55 year by (sex x schooling) groups 

* specify your directory
global path_dir "C:\Users\singhy\Desktop\Chicago\inflation_replication"

global temp_dir "${path_dir}\temp"
global output_dir "${path_dir}\output"

* Yash Singh
* Compute employment-to-population ratio by (sex × schooling) group and overall for multiple periods

* Load data
use "$temp_dir/employment_to_population_data.dta", clear

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

* --------- GROUPED EMP-POP RATIO BY PERIOD (SEX × EDUC) ---------
* Compute stocks by group
by date_monthly educ SEX: egen emp_stock = total(WTFINL * emp_flag)
by date_monthly educ SEX: egen pop = total(WTFINL)
gen emp_pop_ratio = emp_stock / pop

foreach per of local periods {
    preserve
        collapse (mean) emp_pop_ratio, by(SEX educ `per')
        keep if `per' == 1
        gen period = upper("`per'")
        save "$temp_dir/grouped_`per'", replace
    restore
}

* --------- COMBINE AND EXPORT ---------
* Combine grouped
use "$temp_dir/grouped_pre_period", clear
foreach per of local periods {
    if "`per'" != "pre_period" {
        append using "$temp_dir/grouped_`per'"
    }
}

* Add overall rows
foreach per of local periods {
    append using "$temp_dir/overall_`per'"
}

* Clean and export
drop pre_period inf_period post_period early_post_period late_post_period
export delimited using "$output_dir/tables/emp_pop_ratio.csv", replace
