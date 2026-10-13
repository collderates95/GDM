clear all

/*** Set Stata version																							  ***/
version 17   /*** Specify version                                                                                ***/

/*** Configure display output																					  ***/
set more off
set logtype text
set linesize 255 

/*** Set ado-file path																							  ***/
sysdir set PERSONAL "Z:\Fuerth\GWA61_5015\C_Programme\ado"


/*** Path macros																							  ***/
global main "Z:\Fuerth\GWA61_5015"				// Project directory
global datenpfad "$main\A_Mikrodaten\DRG"		// Original data
global outputpfad "$main\D_Ergebnisse"			// Project work is carried out in this directory

/*** Create subdirectories in the results folder (output path)								  ***/
cd "$outputpfad"
cap mkdir data			// For data preparation
cap mkdir results		// For descriptive analyses and regression results
cap mkdir graphs		// For graphs
cap mkdir log			// For saving log files
cap mkdir do			// For storing the corresponding do-files


/*** Path macros for the results subdirectory																	  ***/
global data_prep "$outputpfad\data"
global results "$outputpfad\results"
global graphs "$outputpfad\graphs"
global log "$outputpfad\results"
global do "$outputpfad\do"


/*** File and output name macros																			  ***/						
global dateiname "drg"
global outputname "gdm"															  


* Create a global macro for the date
gen date_current_temp = date("`c(current_date)'","DMY")
format date_current_temp %tdYYNNDD
global date = string(date("`c(current_date)'","DMY"),"%tdYYNNDD")
drop date_current_temp
di "$date"

/*** Start logging.                                                                            ***/
cap log close
log using "$log\gdm_pregnant_regressionen_$date.log", replace

/********************************************************************************************************************/
/*** III.  Regression analyses (main table)  							  								***/
/********************************************************************************************************************/


/*** Load prepared dataset (third and fourth quarters only)																		  ***/
use "$data_prep\drg_08bis14_pregnant_sample_reg.dta", clear

destring kh_land kh_rb kh_kreis kh_gem kh_plz kh_typ_gem, replace




global base i.did i.post i.aufn_jahr				

/*** III.a DiD estimations 															  ***/


			
*without control variables			
		foreach var of varlist kaiser_ops schulter_icd wehen_ops spaet_icd normaldauer_icd frueh_icd tage ln_erloes { // 
			eststo did_`var': reg `var' $base, vce(robust) 		
				
			*Store lower confidence interval bound
			scalar ci_ll = r(table)[5,2]
			qui estadd scalar ci_ll
			
			*Store upper confidence interval bound
			scalar ci_ul = r(table)[6,2]
			qui estadd scalar ci_ul			
			
			*Store the mean of the dependent variable in the analysis sample
			qui sum `var' if e(sample)
			scalar y_mean = r(mean)
			qui estadd scalar y_mean
			
			*relative coefficient
			scalar b_rel = (_b[1.did]/y_mean)*100
			qui estadd scalar b_rel
			
			* relative confidence interval
			scalar ci_ll_rel = (ci_ll/y_mean)*100
			qui estadd scalar ci_ll_rel
	
			scalar ci_ul_rel = (ci_ul/y_mean)*100
			qui estadd scalar ci_ul_rel
}


** Export regression results
esttab did_kaiser_ops did_schulter_icd did_wehen_ops did_spaet_icd did_normaldauer_icd did_frueh_icd did_tage did_ln_erloes using "${results}\did_results_pregnant_main_$date", replace scsv mtitles("Kaiserschnitt" "Schulterdystokie" "Weheneinleitung" "Late term" "Normal term" "Pre term" "Verweildauer" "Erlös (log.)" ) keep(1.did) addnotes("robuste Standardfehler") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Tabellen mit den Ergebnissen der DiD-Schätzungen für Entbindungen") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3))   // 



* with control variables			
		foreach var of varlist kaiser_ops schulter_icd wehen_ops spaet_icd normaldauer_icd frueh_icd tage ln_erloes {
			eststo did_`var': reg `var' $base pat_bula_2 - pat_bula_16 alter alter2 pat_typ_gem_reg_2 pat_typ_gem_reg_3, vce(robust) 
			
			*Store lower confidence interval bound
			scalar ci_ll = r(table)[5,2]
			qui estadd scalar ci_ll
			
			*Store upper confidence interval bound
			scalar ci_ul = r(table)[6,2]
			qui estadd scalar ci_ul			
			
			*Store the mean of the dependent variable in the analysis sample
			qui sum `var' if e(sample)
			scalar y_mean = r(mean)
			qui estadd scalar y_mean
			
			*relative coefficient
			scalar b_rel = (_b[1.did]/y_mean)*100
			qui estadd scalar b_rel
			
			* relative confidence interval
			scalar ci_ll_rel = (ci_ll/y_mean)*100
			qui estadd scalar ci_ll_rel
	
			scalar ci_ul_rel = (ci_ul/y_mean)*100
			qui estadd scalar ci_ul_rel
	
}

 
** Export regression results
esttab did_kaiser_ops did_schulter_icd did_wehen_ops did_spaet_icd did_normaldauer_icd did_frueh_icd did_tage did_ln_erloes using "${results}\did_results_pregnant_main_$date", append scsv mtitles("Kaiserschnitt" "Schulterdystokie" "Weheneinleitung" "Late term" "Normal term" "Pre term" "Verweildauer" "Erlös (log.)" ) keep(1.did) addnotes("robuste Standardfehler; KV: bula-FE, alter quadriert, regionstyp-fe") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Tabellen mit den Ergebnissen der DiD-Schätzungen für Entbindungen mit KV") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3)) 

cap log close






