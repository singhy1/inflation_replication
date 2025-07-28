* make sure the atlanta fed data replicates there aggregate smoothed and unsmoothed series 


global proj_dir "C:/Users/singhy/Dropbox/Labor_Market_PT/replication/empirical" 


use "$proj_dir/outputs/atl_fed/atlFed_wage_data_15t24.dta", clear


collapse (median) med_w_growth_v1 = wagegrowth83 med_w_growth_v2 = wagegrowthtracker83 med_w_growth_v3 =wagegrowthtracker83_wkly (sum) wgt = obs, by(date_monthly)

*collapse (mean) med_w_growth_v1 = wagegrowth83 med_w_growth_v2 = wagegrowthtracker83 med_w_growth_v3 =wagegrowthtracker83_wkly (sum) wgt = obs, by(date_monthly)

drop med_w_growth_v1 med_w_growth_v3 

rename med_w_growth_v2 med_w_growth

sort date_monthly

gen smoothed_med_w_growth = ( ///
    med_w_growth + ///
    med_w_growth[_n-1] + med_w_growth[_n-2] + med_w_growth[_n-3] + med_w_growth[_n-4] + med_w_growth[_n-5] + ///
    med_w_growth[_n-6] + med_w_growth[_n-7] + med_w_growth[_n-8] + med_w_growth[_n-9] + med_w_growth[_n-10] + ///
    med_w_growth[_n-11]) / 12


keep if date_monthly >= tm(2016m1)


* Time series plot
twoway (line med_w_growth date_monthly, lpattern(solid) lwidth(medthick) ///
        lcolor(blue) legend(label(1 "Unsmoothed"))) ///
       (line smoothed_med_w_growth date_monthly, lpattern(dash) lwidth(medthick) ///
        lcolor(red) legend(label(2 "Smoothed (3MA)"))), ///
       ytitle("Median Wage Growth (%)") ///
	   yscale(range(0(1)8)) /// 
       xtitle("Date (Monthly)") ///
       title("Median Wage Growth: Unsmoothed vs 3-Month Moving Average") ///
       legend(order(1 2) pos(6) ring(0)) ///
       graphregion(color(white))
