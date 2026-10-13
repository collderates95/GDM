clear all

/*** Specify Stata version																							  ***/
version 17   /*** Specify version                                                                                ***/

/*** Configure console output																					  ***/
set more off
set logtype text
set linesize 255 
set seed 5698753

/*** Set ado directory																							  ***/
sysdir set PERSONAL "Z:\Fuerth\GWA61_5015\C_Programme\ado"

/*** Directory path macros																							  ***/
global main "Z:\Fuerth\GWA61_5015"				// Project directory
global datenpfad "$main\A_Mikrodaten\DRG"		// Original data
global externpfad "$main\A_Mikrodaten\externe_Daten"		// External data
global outputpfad "$main\D_Ergebnisse"			// Project work is carried out in this directory

/*** Create subdirectories in the output directory								  ***/
cd "$outputpfad"
cap mkdir data			// For data preparation
cap mkdir results		// For descriptive statistics and regression results
cap mkdir graphs		// For graphs
cap mkdir log			// For saving log files
cap mkdir do			// For storing the do-files


/*** Path macros for the results subdirectories																	  ***/
global data_prep "$outputpfad\data"
global results "$outputpfad\results"
global graphs "$outputpfad\graphs"
global log "$outputpfad\results"
global do "$outputpfad\do"


/*** File and output name macros																			  ***/						
global dateiname "drg"
global outputname "gdm"															  


* Generate a global macro for the current date
gen date_current_temp = date("`c(current_date)'","DMY")
format date_current_temp %tdYYNNDD
global date = string(date("`c(current_date)'","DMY"),"%tdYYNNDD")
drop date_current_temp
di "$date"

/*** Start logging.                                                                            ***/
cap log close
log using "$log\gdm_newborn_selektion_$date.log", replace


/********************************************************************************************************************/
/***  Selection into hospital births.		  ***/
/********************************************************************************************************************/


/*** Load the dataset	(only observations with birth in quarters 3 & 4)																					  ***/
use "$data_prep\drg_08bis14_kids_sample_reg.dta", clear

destring kh_land kh_rb kh_kreis kh_gem kh_plz, replace
egen kh_ags = group(kh_land kh_rb kh_kreis kh_gem)

gen N= 1




*Step 1 - data prep (for each ZIP code: create a cell for each combination of yob x mob x female)
foreach var of varlist kh_plz  { // kh_ags kh_kreis

preserve

duplicates drop `var', force
keep `var' geb_jahr geb_monat female 


qui replace geb_jahr = 2008
qui replace geb_monat = 7
qui replace female = 0

expand 36
bys `var': gen row = _n
qui replace geb_jahr = 2008 if inrange(row,1,6) 
qui replace geb_jahr = 2009 if inrange(row,7,12) 
qui replace geb_jahr = 2010 if inrange(row,13,18) 
qui replace geb_jahr = 2011 if inrange(row,19,24) 
qui replace geb_jahr = 2012 if inrange(row,25,30) 
qui replace geb_jahr = 2013 if inrange(row,31,36) 

qui replace geb_monat = 7 if inlist(row,1,7,13,19,25,31) 
qui replace geb_monat = 8 if inlist(row,2,8,14,20,26,32) 
qui replace geb_monat = 9 if inlist(row,3,9,15,21,27,33) 
qui replace geb_monat = 10 if inlist(row,4,10,16,22,28,34) 
qui replace geb_monat = 11 if inlist(row,5,11,17,23,29,35) 
qui replace geb_monat = 12 if inlist(row,6,12,18,24,30,36) 

expand 2
bysort `var' geb_jahr geb_monat: replace female = 1 if _n == 2

save "$data_prep\newborn_selektion_`var'_temp.dta", replace
restore
}

*Step 2	- data prep - compute the number of births on the level of Step 1 
foreach var of varlist kh_plz  { // kh_ags kh_kreis
preserve
egen geburt_kh = group(`var' geb_jahr geb_monat female)
collapse (mean) post treat `var' geb_jahr geb_monat female (count) N, by(geburt_kh)


save "$data_prep\newborn_selektion_`var'_data.dta", replace
restore
}



** Step 3 - merge datasets and generate the variables for the analyses
foreach var of varlist kh_plz  { // kh_ags kh_kreis

preserve
use "$data_prep\newborn_selektion_`var'_temp.dta", clear
merge 1:1 `var' geb_jahr geb_monat female using "$data_prep\newborn_selektion_`var'_data.dta", keepusing(N)
drop _merge
recode N (. = 0)

generate post = 0
qui replace post = 1 if inrange(geb_monat,10,12)
label var post "=1, wenn Okt-Dez"

generate treat = 0
qui replace treat = 1 if geb_jahr == 2013
label var treat "=1, wenn im Treatmentjahr geboren"

gen did = post*treat
label var did "= 1, wenn tatsächlicher Anspruch im Jahr 2013 auf das GDM-Screening bestand"

save "$data_prep\newborn_selektion_`var'_final.dta", replace

restore	
}






global base i.did i.post i.geb_jahr

************ZIP code - regression results
cap erase "${results}\did_results_newborn_selektion_$date.csv"

preserve															 
use "$data_prep\newborn_selektion_kh_plz_final.dta", clear

gen N1 = N+1
gen ln_N1 = ln(N1)
gen lnN = ln(N)


** Without control variables
		foreach var of varlist  ln_N1 {  //  N lnN
			eststo did_`var': reg `var' $base, vce(robust) 

			*Store lower confidence interval bound
			scalar ci_ll = r(table)[5,2]
			qui estadd scalar ci_ll
			
			*Store upper confidence interval bound
			scalar ci_ul = r(table)[6,2]
			qui estadd scalar ci_ul			
			
			*Store mean of the dependent variable in the estimation sample
			qui sum `var' if e(sample)
			scalar y_mean = r(mean)
			qui estadd scalar y_mean
			
			*Coefficient relative to outcome mean
			scalar b_rel = (_b[1.did]/y_mean)*100
			qui estadd scalar b_rel
			
			* Confidence interval relative to outcome mean
			scalar ci_ll_rel = (ci_ll/y_mean)*100
			qui estadd scalar ci_ll_rel
	
			scalar ci_ul_rel = (ci_ul/y_mean)*100
			qui estadd scalar ci_ul_rel
	
}			
		
** With control variables 
		foreach var of varlist ln_N1  { // N lnN 
			eststo did_kv_`var': qui reg `var' $base i.female i.kh_plz, vce(robust) 

		
			*Store lower confidence interval bound
			scalar ci_ll = r(table)[5,2]
			qui estadd scalar ci_ll
			
			*Store upper confidence interval bound
			scalar ci_ul = r(table)[6,2]
			qui estadd scalar ci_ul			
			
			*Store mean of the dependent variable in the estimation sample
			qui sum `var' if e(sample)
			scalar y_mean = r(mean)
			qui estadd scalar y_mean
			
			*Coefficient relative to outcome mean
			scalar b_rel = (_b[1.did]/y_mean)*100
			qui estadd scalar b_rel
			
			* Confidence interval relative to outcome mean
			scalar ci_ll_rel = (ci_ll/y_mean)*100
			qui estadd scalar ci_ll_rel
	
			scalar ci_ul_rel = (ci_ul/y_mean)*100
			qui estadd scalar ci_ul_rel
	
}
		
		

** Export regression results
esttab  did_ln_N1 did_kv_ln_N1 using "${results}\did_results_newborn_selektion_$date", append scsv mtitles("Ohne KV (log y+1)" "Mit KV (log y+1)") keep(1.did)   addnotes("robuste Standardfehler; KV: PLZ-FE + female") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Selektion in KKH-Geburten auf PLZ-Ebene") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3)) // did_N did_kv_N did_lnN did_kv_lnN "Ohne KV" "Mit KV" "Ohne KV (log y)" "Mit KV (log y)"
restore

log close



































