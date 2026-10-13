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
log using "$log\gdm_newborn_balancing_$date.log", replace



/********************************************************************************************************************/
/*** III.  Balancing Tests  							  ***/
/********************************************************************************************************************/

/*** Load the dataset	(only observations with birth in the 3. & 4. quarter)																					  ***/
use "$data_prep\drg_08bis14_kids_sample_reg.dta", clear

*destring kh_land kh_rb kh_kreis kh_gem kh_Postal code kh_typ_gem, replace

global base i.did i.post i.geb_jahr



/*** 	Balancing test for each covariate seperately  	***/
 
** Federal state
		foreach num of numlist 1(1)16 {
			eststo did_pat_bula_`num': reg pat_bula_`num' $base, vce(robust) 

			*Store lower confidence interval bound
			scalar ci_ll = r(table)[5,2]
			qui estadd scalar ci_ll
			
			*Store upper confidence interval bound
			scalar ci_ul = r(table)[6,2]
			qui estadd scalar ci_ul
			
			*Store mean of the dependent variable in the estimation sample
			qui sum pat_bula_`num' if e(sample)
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
		
		
** Female + twins
		foreach var of varlist female mehrling_icd  {	
			eststo did_`var': reg `var' $base, vce(robust)  
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
		
** Regional type
		foreach num of numlist 1(1)3 {
			eststo did_patreg_`num': reg pat_typ_gem_reg_`num' $base, vce(robust) 

			*Store lower confidence interval bound
			scalar ci_ll = r(table)[5,2]
			qui estadd scalar ci_ll
			
			*Store upper confidence interval bound
			scalar ci_ul = r(table)[6,2]
			qui estadd scalar ci_ul
			
			*Store mean of the dependent variable in the estimation sample
			qui sum pat_typ_gem_reg_`num' if e(sample)
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
		

** Export regression results (only the coefficient 1.did is of interest)		
esttab did_female did_pat_bula_* did_mehrling_icd did_patreg_* using "${results}\did_results_newborn_balancing_$date", replace scsv addnotes("robuste Standardfehler") keep(1.did) cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Balancing Tests") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3))

cap log close