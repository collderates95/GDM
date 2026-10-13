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

mata mata mlib index

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
log using "$log\gdm_newborn_makro_$date.log", replace


/********************************************************************************************************************/
*************** Produce results for different birth weight thresholds ************************************************
/********************************************************************************************************************/

*** The results that are obtained are used to create Figure A.4 locally


/*** Load the dataset	(only observations with birth in the 3. & 4. quarter)																					  ***/
use "$data_prep\drg_08bis14_kids_sample_reg.dta", clear





***** Create different birth weight thresholds 
gen makro_3000 = aufn_gew >= 3000 & aufn_gew <. 
gen makro_3250 = aufn_gew >= 3250 & aufn_gew <. 
gen makro_3500 = aufn_gew >= 3500 & aufn_gew <. 
gen makro_3750 = aufn_gew >= 3750 & aufn_gew <. 
gen makro_4250 = aufn_gew >= 4250 & aufn_gew <.
gen makro_4750 = aufn_gew >= 4750 & aufn_gew <.
gen makro_5000 = aufn_gew >= 5000 & aufn_gew <.


destring kh_land kh_rb kh_kreis kh_gem kh_plz kh_typ_gem, replace

global base i.did i.post i.geb_jahr


		
			
** Without control variables
		foreach var of varlist makro_3000 makro_3250 makro_3500 makro_3750 makro_4250 makro_4750 makro_5000  { 
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
			

** Export regression results
esttab did_makro_3000 did_makro_3250 did_makro_3500 did_makro_3750 did_makro_4250 did_makro_4750 did_makro_5000 using "${results}\did_results_newborn_makro_$date", replace scsv mtitles("Makro 3000g" "Makro 3250g" "Makro 3500g" "Makro 3750g" "Makro 4250g" "Makro 4750g" "Makro 5000g") keep(1.did)  addnotes("robuste Standardfehler") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Tabellen mit den Ergebnissen der DiD-Schätzungen") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3))



** With control variables 
eststo clear
		foreach var of varlist makro_3000 makro_3250 makro_3500 makro_3750 makro_4250 makro_4750 makro_5000   { 
			eststo did_`var': reg `var' $base pat_bula_2 - pat_bula_16 i.female pat_typ_gem_reg_2 pat_typ_gem_reg_3, vce(robust) 
		
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
esttab did_makro_3000 did_makro_3250 did_makro_3500 did_makro_3750 did_makro_4250 did_makro_4750 did_makro_5000 using "${results}\did_results_newborn_makro_$date", append scsv mtitles("Makro 3000g" "Makro 3250g" "Makro 3500g" "Makro 3750g" "Makro 4250g" "Makro 4750g" "Makro 5000g") keep(1.did)  addnotes("robuste Standardfehler") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Tabellen mit den Ergebnissen der DiD-Schätzungen mit KV") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3))

cap log close