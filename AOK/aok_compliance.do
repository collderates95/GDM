/*******************************************************************************
					Compliance
*******************************************************************************/
version 17

global path ""

import excel "$path\aok_raw.xlsx", sheet("Daten") firstrow clear 

*********************** Data prep **********************************************
drop if year == . | year < 2010

* Generate year-month combination
egen bdate_ym = group(year month)

* Generate quarter of birth 
gen quarter = 3 if inrange(month,7,9)
replace quarter = 4 if inrange(month,10,12)

**** Treatment 2013 ********
* Generate treatment indicator (year = 2013)
gen treat = 0
replace treat = 1 if year == 2013

* Gen post indicator (October to December born) 
gen post = inrange(month,10,12)

* Gen treat*post
gen did = post*treat

**** Treatment 2012 ********
* Generate treatment indicator for the introduction in maternity guidelines (year = 2012)
gen treat_ = 0
replace treat_ = 1 if year == 2012

* Gen post indicator (October to December born) 
gen post_ = inrange(month,6,8)
****

* Convert the share-variable into a percentage variable
gen test_all = (Versichert - N) + tested
replace share = test_all/Versichert * 100

replace N = Versichert


*********************** Display Fig. 1**************************************

gen shade = 100       
sum bdate_ym if year==2012 & month==5
gen change1 = r(mean)
sum bdate_ym if year==2013 & month==9
gen change2 = r(mean)

twoway (area shade bdate_ym if bdate_ym>=change1 & bdate_ym<=change1+1, color(white) fcolor(cranberry) fintensity(inten10)) /// Inclusion into maternity guidelines
	   (area shade bdate_ym if bdate_ym>=change2 & bdate_ym<=change2+1, color(white) fcolor(cranberry) fintensity(inten10)) /// Reimbursement by SHI
	   (line share bdate_ym,  lcolor(black) lwidth(medthick)) ///
		lfit 	share bdate_ym [aweight=N] if bdate_ym <= change1, lcolor(gs8) lpattern(shortdash) lwidth(medthin) || 	///
		lfit	share bdate_ym [aweight=N] if bdate_ym > change1 & bdate_ym <= change2 , lcolor(gs8) lpattern(shortdash) lwidth(medthin) || ///
		lfit 	share bdate_ym [aweight=N] if bdate_ym > change2, lcolor(gs8) lpattern(shortdash) lwidth(medthin)  	///
		legend(label(3 "Linear fit"))		///
		, ylabel(20(10)100, format(%9.0f) labsize(medsmall)  angle(0)) ytitle("Screening rate in %") ///
		xlabel(1 "1/2010" 4 "4/2010" 7 "7/2010" 	10 "40/2010" 	    ///
				13 "1/2011" 16 "4/2011" 19 "7/2011" 22 "10/2011" ///
				25 "1/2012" 28 "4/2012" 31 "7/2012" 34 "10/2012" ///
				37 "1/2013" 40 "4/2013" 43 "7/2013" 46 "10/2013" ///
				49 "1/2014" 52 "4/2014" 55 "7/2014" 58 "10/2014" , labsize(medsmall) angle(35) ) ///
				xtitle("Date of delivery") legend(off order(3) position(5) ring(0) cols(1)) ///
				graphregion(color(white)) scheme(s1mono) ///
				text(22 30 "Inclusion in guidelines", place(e) size(small)  orientation(horizontal) ) ///
				text(22 46 "Cost reimbursement", place(e) size(small)  orientation(horizontal) ) 
				
graph display, xsize(13) ysize(8)				
graph save "${path}/20250704_screening_aok",  replace
graph export "${path}/20250704_screening_aok.pdf", replace	
				
				

***************************** Table 2 (Appendix)  **************************************
replace share = share / 100
*main
reg share c.treat##c.post i.year [aweight=N] if year<=2013 & inrange(month,7,12), vce(robust)
estimates store main
sum share [fweight=N] if e(sample) & year==2013 & month>=7 & month<=9
scalar pre_mean=r(mean)	
qui estadd scalar pre_mean, replace
scalar rel=_b[c.treat#c.post]/pre_mean*100
sum share [fweight=N] if e(sample) 
qui estadd scalar rel, replace
scalar N_ind=r(N)	
qui estadd scalar N_ind, replace
*donut
reg share c.treat##c.post i.year [aweight=N] if year<=2013 & inrange(month,7,12) & month!=9 & month!=10, vce(robust)
estimates store donut
sum share [fweight=N] if e(sample) & year==2013 & month>=7 & month<=9 & month!=9 & month!=10
scalar pre_mean=r(mean)	
qui estadd scalar pre_mean, replace
scalar rel=_b[c.treat#c.post]/pre_mean*100
sum share [fweight=N] if e(sample) 
qui estadd scalar rel, replace
scalar N_ind=r(N)	
qui estadd scalar N_ind, replace
*excl. 2012
reg share c.treat##c.post i.year [aweight=N] if year<=2013 & inrange(month,7,12) & year!=2012, vce(robust)
estimates store no2012
sum share [fweight=N] if e(sample) & year==2013 & month>=7 & month<=9
scalar pre_mean=r(mean)	
qui estadd scalar pre_mean, replace
scalar rel=_b[c.treat#c.post]/pre_mean*100
sum share [fweight=N] if e(sample) 
qui estadd scalar rel, replace
scalar N_ind=r(N)	
qui estadd scalar N_ind, replace
*placebo 2014
preserve
replace treat=year==2014
reg share c.treat##c.post i.year [aweight=N] if year<=2014 & year!=2013 & inrange(month,7,12), vce(robust)
estimates store placebo
sum share [fweight=N] if e(sample) & year==2014 & month>=7 & month<=9
scalar pre_mean=r(mean)	
qui estadd scalar pre_mean, replace
scalar rel=_b[c.treat#c.post]/pre_mean*100
sum share [fweight=N] if e(sample) 
qui estadd scalar rel, replace
scalar N_ind=r(N)	
qui estadd scalar N_ind, replace
restore

esttab ** using "$path\20250704_aok_reg", replace scsv order (*treat#c.post) title (" AOK: time series data ") ///
cells(b(fmt(3) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(pre_mean rel N N_ind,  fmt(3 1 0 0 )) stardetach


