


global proj_dir "C:/Users/singhy/Dropbox/Labor_Market_PT/replication/empirical" 

use "$proj_dir/temp/atl_cps_matched_dingel_neiman.dta", clear 

*keep if agegroup == "25-54"
gen obs = 1 
*collapse (mean) avg_w_growth = wagegrowthtracker83 [fw=int(weigh76)], by(date_monthly educ_group wagegroup)
*collapse (mean) avg_w_growth = wagegrowthtracker83 [fw=int(weightbls98)], by(date_monthly educ_group wagegroup)
*collapse (mean) avg_w_growth = wagegrowthtracker83 [fw=int(weightl92)], by(date_monthly educ_group wagegroup)
*collapse (mean) avg_w_growth = wagegrowthtracker83 [fw=int(weightern82)], by(date_monthly educ_group wagegroup)
*collapse (mean) avg_w_growth = wagegrowthtracker83 [fw=int(weight76_tm12)], by(date_monthly educ_group wagegroup)

collapse (median) avg_w_growth = wagegrowthtracker83 (sum) wgt = obs, ///
    by(date_monthly)
	

*collapse (mean) avg_w_growth = wagegrowth83 [fw=int(weightern82_tm12)], by(date_monthly educ_group wagegroup)


* Generate baseline (2015m12 = index of 1)
preserve
keep educ_group wagegroup
duplicates drop
gen date_monthly = tm(2015m12)
gen avg_w_growth = .
gen wage_index = 1
tempfile base
save `base'
restore

* Merge with your original data
append using `base'
sort educ_group wagegroup date_monthly

* Make sure data is sorted correctly
sort educ_group wagegroup date_monthly

* Replace missing growths with 0 (for baseline row)
replace avg_w_growth = 0 if missing(avg_w_growth)

* Convert percentage growth to growth factors (e.g., 5% -> 1.05)
gen growth_factor = 1 + avg_w_growth / (12*100)


* Drop old wage_index before redefining it
drop wage_index
gen wage_index = .

* Set base case
gen base = (date_monthly == tm(2015m12))
bysort educ_group wagegroup (date_monthly): replace wage_index = 1 if base

* Recursively fill wage index
gen L = .
quietly {
    local filled = 0
    while `filled' == 0 {
        gen temp_index = .
        bysort educ_group wagegroup (date_monthly): ///
            replace temp_index = wage_index[_n-1] * growth_factor if missing(wage_index) & _n > 1
        replace wage_index = temp_index if missing(wage_index)
        drop temp_index

        count if missing(wage_index)
        if r(N) == 0 local filled = 1
    }
}
drop L base



gen group_label = educ_group + ", " + wagegroup

* Sort the data
sort group_label date_monthly

* Plot with line + trend, faceted by group
twoway ///
    (line wage_index date_monthly, lwidth(medium)) ///
    (lfit wage_index date_monthly, lpattern(dash)), ///
    by(group_label, ///
        title("Real Wage Index with Trend by Education × Wage Quartile") ///
        note("") ///
        compact ///
        cols(2)) ///
    xtitle("Date") ///
    ytitle("Wage Index") ///
    ylabel(, angle(0)) ///
    legend(off)




