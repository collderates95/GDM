
clear all

/*** Set Stata version																							  ***/
version 17   /*** Specify Stata version                                                                                ***/

/*** Bildschirmausgabe steuern																					  ***/
set more off
set logtype text
set linesize 255 
set seed 5698753

/*** Ado-Pfad festlegen																							  ***/
sysdir set PERSONAL "Z:\Fuerth\GWA61_5015\C_Programme\ado"

mata mata mlib index

/*** Path macros																							  ***/
global main "Z:\Fuerth\GWA61_5015"				// Ordner des Projekts
global datenpfad "$main\A_Mikrodaten\DRG"		// Original data
global outputpfad "$main\D_Ergebnisse"			// Project work is carried out in this directory

/*** Create subdirectories in the D_Ergebnisse working directory (output path)								  ***/
cd "$outputpfad"
cap mkdir data			// For data preparation
cap mkdir results		// For descriptive statistics and regression results
cap mkdir graphs		// For graphs
cap mkdir log			// For storing log files
cap mkdir do			// For storing the respective do-files


/*** Path macros for results subdirectories																	  ***/
global data_prep "$outputpfad\data"
global results "$outputpfad\results"
global graphs "$outputpfad\graphs"
global log "$outputpfad\log"
global do "$outputpfad\do"


/*** Macros for filenames and outputs																			  ***/						
global dateiname "drg"
global outputname "gdm"															  


* Create a global macro for the date
gen date_current_temp = date("`c(current_date)'","DMY")
format date_current_temp %tdYYNNDD
global date = string(date("`c(current_date)'","DMY"),"%tdYYNNDD")
drop date_current_temp
di "$date"

/*** Start logging                                                                            ***/
cap log close
log using "$log\gdm_newborn_pregnant_kosten_regional_$date.log", replace



/*********************************************************************************************************************
These analyses examine cost outcomes in the pooled maternal and newborn samples	(Panel C of Tab A.7)

The following steps are performed:
1. First, pool the two samples
2. Next, harmonize the main variables. 
3. Finally, estimate alternative regression specifications for economic outcomes (length of stay, revenue, and numbers of diagnoses/procedures).
*********************************************************************************************************************/

/*** Load newborn dataset	(only births in the third and fourth quarters)																					  ***/
use "$data_prep\drg_08bis14_kids_sample_reg_gemeinde_ohnemissings.dta", clear
gen samp = 0

/*** Append maternal dataset 	(only births in the third and fourth quarters)																					  ***/
append using "$data_prep\drg_08bis14_pregnant_sample_reg_gemeinde_ohnemissings.dta"
replace samp = 1 if samp == .

/*** Harmonize variables																					  ***/
clonevar geburtsjahr = geb_jahr if samp == 0
replace geburtsjahr = aufn_jahr if samp == 1


/*** Save newborn.mother.dataset ***/
save "$data_prep\drg_08bis14_kids_pregnant_sample_reg_gemeinde_ohnemissings.dta", replace

global base i.did i.post i.geburtsjahr
destring gem_id_pat, replace		

															  



/********************************************************************************
       The following heterogeneity analysis uses GISD scores 
			(socioeconomic deprivation index), using terciles 
*******************************************************************************/

			 

** upper terzile without control variables
preserve 
qui keep if gisd_terz == 3
		foreach var of varlist tage ln_tage erloes ln_erloes  { 
			eststo did_`var': reg `var' $base i.samp, vce(robust) 
		
			*Store lower confidence-interval bound
			scalar ci_ll = r(table)[5,2]
			qui estadd scalar ci_ll
			
			*Store upper confidence-interval bound
			scalar ci_ul = r(table)[6,2]
			qui estadd scalar ci_ul			
			
			*Store mean of the dependent variable in the analysis sample
			qui sum `var' if e(sample)
			scalar y_mean = r(mean)
			qui estadd scalar y_mean
			
			*Relative beta
			scalar b_rel = (_b[1.did]/y_mean)*100
			qui estadd scalar b_rel
			
			* Relative confidence interval
			scalar ci_ll_rel = (ci_ll/y_mean)*100
			qui estadd scalar ci_ll_rel
	
			scalar ci_ul_rel = (ci_ul/y_mean)*100
			qui estadd scalar ci_ul_rel
	
}			
			

** Export regression results
esttab did_tage did_ln_tage did_erloes did_ln_erloes using "${results}\did_results_pregnant_newborn_gisd_terz_$date", replace scsv mtitles("Verweildauer" "Verweildauer (logarithmiert)" "Erlös" "Erlös (log.)") keep(1.did)  addnotes("robuste Standardfehler") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Tabellen mit den Ergebnissen der DiD-Schätzungen - GISD highest terzile (highest depriv)") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3))
restore


** medium terzile without control variables
preserve 
qui keep if gisd_terz == 2
		foreach var of varlist tage ln_tage erloes ln_erloes  { 
			eststo did_`var': reg `var' $base i.samp, vce(robust) 
		
			*Store lower confidence-interval bound
			scalar ci_ll = r(table)[5,2]
			qui estadd scalar ci_ll
			
			*Store upper confidence-interval bound
			scalar ci_ul = r(table)[6,2]
			qui estadd scalar ci_ul			
			
			*Store mean of the dependent variable in the analysis sample
			qui sum `var' if e(sample)
			scalar y_mean = r(mean)
			qui estadd scalar y_mean
			
			*Relative beta
			scalar b_rel = (_b[1.did]/y_mean)*100
			qui estadd scalar b_rel
			
			* Relative confidence interval
			scalar ci_ll_rel = (ci_ll/y_mean)*100
			qui estadd scalar ci_ll_rel
	
			scalar ci_ul_rel = (ci_ul/y_mean)*100
			qui estadd scalar ci_ul_rel
	
}			
			

** Export regression results
esttab did_tage did_ln_tage did_erloes did_ln_erloes using "${results}\did_results_pregnant_newborn_gisd_terz_$date", append scsv mtitles("Verweildauer" "Verweildauer (logarithmiert)" "Erlös" "Erlös (log.)") keep(1.did)  addnotes("robuste Standardfehler") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Tabellen mit den Ergebnissen der DiD-Schätzungen - GISD medium terzile (medium depriv)") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3))
restore


** lowest terzile without control variables
preserve 
qui keep if gisd_terz == 1
		foreach var of varlist tage ln_tage erloes ln_erloes  { 
			eststo did_`var': reg `var' $base i.samp, vce(robust) 
		
			*Store lower confidence-interval bound
			scalar ci_ll = r(table)[5,2]
			qui estadd scalar ci_ll
			
			*Store upper confidence-interval bound
			scalar ci_ul = r(table)[6,2]
			qui estadd scalar ci_ul			
			
			*Store mean of the dependent variable in the analysis sample
			qui sum `var' if e(sample)
			scalar y_mean = r(mean)
			qui estadd scalar y_mean
			
			*Relative beta
			scalar b_rel = (_b[1.did]/y_mean)*100
			qui estadd scalar b_rel
			
			* Relative confidence interval
			scalar ci_ll_rel = (ci_ll/y_mean)*100
			qui estadd scalar ci_ll_rel
	
			scalar ci_ul_rel = (ci_ul/y_mean)*100
			qui estadd scalar ci_ul_rel
	
}			
			

** Export regression results
esttab did_tage did_ln_tage did_erloes did_ln_erloes using "${results}\did_results_pregnant_newborn_gisd_terz_$date", append scsv mtitles("Verweildauer" "Verweildauer (logarithmiert)" "Erlös" "Erlös (log.)") keep(1.did)  addnotes("robuste Standardfehler") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Tabellen mit den Ergebnissen der DiD-Schätzungen - GISD lowest terzile (low depriv)") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3))
restore



log close