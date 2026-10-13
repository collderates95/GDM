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
log using "$log\gdm_newborn_regressionen_$date.log", replace


/********************************************************************************************************************/
/*** III.  Regression analyses (main table)  							  								***/
/********************************************************************************************************************/



/*** Load the dataset	(only observations with birth in the 3. & 4. quarter)																					  ***/
use "$data_prep\drg_08bis14_kids_sample_reg.dta", clear

destring kh_land kh_rb kh_kreis kh_gem kh_plz kh_typ_gem, replace

global base i.did i.post i.geb_jahr



/*** III.a DiD estimations 															  ***/

			
			
** Without control variables
		foreach var of varlist diabetes_icd aufn_gew makro_40 makro_45 low_bw tage ln_erloes { 
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
esttab did_diabetes_icd did_aufn_gew did_makro_40 did_makro_45 did_low_bw did_tage did_ln_erloes using "${results}\did_results_newborn_main_$date", replace scsv mtitles("Transient metab. disorder" "Birthweight" "Macrosomia (4000g and more)" "Macrosomia (4500g and more)" "Low birthweight (< 2500g)" "Verweildauer" "Erlös (log.)") keep(1.did)  addnotes("robuste Standardfehler") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Tabellen mit den Ergebnissen der DiD-Schätzungen") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3))



** With control variables 
eststo clear
		foreach var of varlist diabetes_icd aufn_gew makro_40 makro_45 low_bw tage ln_erloes   { 
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
esttab did_diabetes_icd did_aufn_gew did_makro_40 did_makro_45 did_low_bw did_tage did_ln_erloes using "${results}\did_results_newborn_main_$date", append scsv mtitles("Transient metab. disorder" "Birthweight" "Macrosomia (4000g and more)" "Macrosomia (4500g and more)" "Low birthweight (< 2500g)" "Verweildauer" "Erlös (log.)") keep(1.did)  addnotes("robuste Standardfehler") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Tabellen mit den Ergebnissen der DiD-Schätzungen mit KV") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3))


cap log close
























