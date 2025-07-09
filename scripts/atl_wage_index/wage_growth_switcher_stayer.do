* Yash Singh 
* 
* date: 


global proj_dir "C:/Users/singhy/Dropbox/Labor_Market_PT/replication/empirical" 

use "$proj_dir/temp/atl_cps_matched_dingel_neiman.dta", clear 


collapse (mean) avg_w_growth = wagegrowth83 [fw=int(weightern82_tm12)], by(period wagegroup jstayergroup)

* Keep only the variables needed for reshape
keep wagegroup period jstayergroup avg_w_growth

* Clean jstayergroup to make j variable usable
gen jgroup = subinstr(jstayergroup, " ", "_", .)

* Drop the original jstayergroup to avoid reshape error
drop jstayergroup

* Reshape to wide format
reshape wide avg_w_growth, i(wagegroup period) j(jgroup) string

* Compute pp difference 
gen pp_diff = avg_w_growthJob_Switcher - avg_w_growthJob_Stayer

export delimited "$proj_dir/outputs/processed_data/pp_diff_wage_growth_by_quartile_x_period.csv", replace 





* Sort the data
sort wagegroup jstayergroup date_monthly

* Create panel plots (1 per wage group), comparing Switchers vs Stayers
twoway ///
    (line avg_w_growth date_monthly if jstayergroup == "Job Stayer", lwidth(medium) lcolor(blue)) ///
    (line avg_w_growth date_monthly if jstayergroup == "Job Switcher", lwidth(medium) lcolor(red)), ///
    by(wagegroup, title("Wage Growth: Job Switchers vs Stayers by Wage Group") ///
        note("") compact cols(2)) ///
    xtitle("Date") ///
    ytitle("Average Wage Growth (%)") ///
    legend(order(1 "Stayer" 2 "Switcher") pos(6) ring(0)) ///
    ylabel(, angle(0))
	
	