global proj_dir "C:/Users/singhy/Dropbox/Labor_Market_PT/replication/empirical"

use "$proj_dir/temp/atl_cps_matched_dingel_neiman.dta", clear

gen obs = 1

*collapse (sum) wgt = obs, by(date_monthly wagegroup)

collapse (mean) avg_w_growth = wagegrowthtracker83_wkly [fw=int(weightern82)], by(date_monthly wagegroup)


* Ensure teleworkable is clean integer
replace teleworkable = int(teleworkable)

* Generate observation count for weighting
gen obs = 1

* Collapse to monthly avg wage growth by teleworkability × wage group
collapse (mean) avg_w_growth = wagegrowthtracker83_wkly (sum) wgt = obs, ///
    by(date_monthly teleworkable wagegroup)

* Generate baseline (2015m12 = index of 1)
preserve
keep teleworkable wagegroup
duplicates drop
gen date_monthly = tm(2015m12)
gen avg_w_growth = .
gen wage_index = 1
tempfile base
save `base'
restore

* Merge with original data
append using `base'
sort teleworkable wagegroup date_monthly

* Replace missing growths with 0 for baseline
replace avg_w_growth = 0 if missing(avg_w_growth)

* Convert percentage to growth factor (monthly)
gen growth_factor = 1 + avg_w_growth / (12*100)

* Drop old wage_index and reinitialize
drop wage_index
gen wage_index = .

* Set base case
gen base = (date_monthly == tm(2015m12))
bysort teleworkable wagegroup (date_monthly): replace wage_index = 1 if base

* Recursively fill wage index
gen L = .
quietly {
    local filled = 0
    while `filled' == 0 {
        gen temp_index = .
        bysort teleworkable wagegroup (date_monthly): ///
            replace temp_index = wage_index[_n-1] * growth_factor if missing(wage_index) & _n > 1
        replace wage_index = temp_index if missing(wage_index)
        drop temp_index

        count if missing(wage_index)
        if r(N) == 0 local filled = 1
    }
}
drop L base


* Combine label and wagegroup for plot panels
gen group_label = string(teleworkable) + ", " + wagegroup


* Sort the data
sort group_label date_monthly

* Plot wage index + trend by group
twoway ///
    (line wage_index date_monthly, lwidth(medium)) ///
    (lfit wage_index date_monthly, lpattern(dash)), ///
    by(group_label, ///
        title("Real Wage Index with Trend by Teleworkability × Wage Quartile") ///
        note("") compact cols(2)) ///
    xtitle("Date") ///
    ytitle("Wage Index") ///
    ylabel(, angle(0)) ///
    legend(off)

