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
global externpfad "$main\A_Mikrodaten\externe_Daten"		// External data
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

/*** Aufzeichung im Protokoll starten.                                                                            ***/
cap log close
log using "$log\gdm_pregnant_het_regional_$date.log", replace

/********************************************************************************************************************/
/*** III.  Heterogeneity analysis by eprivation tercile ***/
/********************************************************************************************************************/




/*** Load original analysis dataset			***/
use "$data_prep\drg_08bis14_pregnant_sample_reg.dta", clear


***********************1. Construct municipality IDs ***********************************

** IDs for the hospital location and patient residence
gen kh_ags8 = kh_land + kh_rb + kh_kreis + kh_gem
label var kh_ags8 "AGS 8-Steller (Ort des Krankenhauses)"

gen pat_ags8 = pat_land + pat_rb + pat_kreis + pat_gem
label var pat_ags8 "AGS 8-Steller (Wohnort Patient)"

order kh_ags8 pat_ags8

gen pat_ags8_valid = (pat_gem != "ohn" & pat_gem != "unb")
label var pat_ags8_valid "valider AGS 8-Steller von Patiennt" 

gen kh_pat_equal = kh_ags8 == pat_ags8 if pat_ags8_valid == 1
label var kh_pat_equal "Übereinstimmung von AGS 8-Stellern " 

*Harmonize municipality IDs (patient residence by default; otherwise use the hospital’s eight-digit municipality code)
clonevar gem_id_pat = pat_ags8
qui replace gem_id_pat = kh_ags8 if pat_ags8_valid == 0
qui replace gem_id_pat = "11000000" if substr(gem_id_pat,1,2) == "11" // Treat Berlin as one entity (as in the institutional data)

* Create East-West indicator
gen gem_id_bula = substr(gem_id_pat,1,2)
destring gem_id_bula, replace

gen west = inrange(gem_id_bula,1,11)
label var west "Westdeutschland (Patient)"

**************2. Merge external data by municipality ID and year **********************

clonevar year = aufn_jahr 
merge m:1 gem_id_pat year using "${data_prep}\Regio_FINAL.dta"
gen nomatch = _merge == 1
drop if _merge == 2
drop _merge

gen gemeinde_missing = gemeinde_betroffen == 1 | nomatch == 1
label var gemeinde_missing "keine valide Gemeinde-ID vorhanden"
tab gemeinde_missing


save "$data_prep\drg_08bis14_pregnant_sample_reg_gemeinde_full.dta", replace



preserve
**************3.Classify municipalities into high/low GISD groups and terciles for subsequent heterogeneity analyses**********************

** Define groups only among municipalities available for subsequent heterogeneity analyses
keep if gemeinde_missing == 0


*** High/low classification
foreach y in 2008 2009 2010 2011 2012 {

qui xtile gisd_median_`y'_upper = gisd_s if aufn_jahr == `y' & gemeinde_missing == 0, nquantiles(2)
qui bys gem_id_pat: egen gisd_above_`y'_ = max(gisd_median_`y'_upper)
}

qui gen gisd_abovemed = .
qui replace gisd_abovemed = gisd_above_2012_ if gisd_abovemed == .		
qui replace gisd_abovemed = gisd_above_2011_ if gisd_abovemed == .
qui replace gisd_abovemed = gisd_above_2010_ if gisd_abovemed == .
qui replace gisd_abovemed = gisd_above_2009_ if gisd_abovemed == .
qui replace gisd_abovemed = gisd_above_2008_ if gisd_abovemed == .

gen gisd_upper = 0 if gisd_abovemed == 1
replace gisd_upper = 1 if gisd_abovemed == 2
label var gisd_upper "GIDS Deprivationsdummy (1 = hohe Deprivation)"

*** Tercile classification
foreach y in 2008 2009 2010 2011 2012 {

qui xtile gisd_terzile_`y'_ = gisd_s if aufn_jahr == `y' & gemeinde_missing == 0, nquantiles(3)
qui bys gem_id_pat: egen gisd_terz_`y' = max(gisd_terzile_`y'_)
}

qui gen gisd_terz = .
qui replace gisd_terz = gisd_terz_2012 if gisd_terz == .		
qui replace gisd_terz = gisd_terz_2011 if gisd_terz == .
qui replace gisd_terz = gisd_terz_2010 if gisd_terz == .
qui replace gisd_terz = gisd_terz_2009 if gisd_terz == .
qui replace gisd_terz = gisd_terz_2008 if gisd_terz == .
label var gisd_terz "GIDS Deprivationsterzile (aufsteigend 1 bis 3)"



**************4. Save dataset with municipality ID**********************
save "$data_prep\drg_08bis14_pregnant_sample_reg_gemeinde_ohnemissings.dta", replace
restore


/********************************************************************************
       5. The following heterogeneity analysis uses GISD scores 
			(socioeconomic deprivation index), splitting observations into terciles 
*******************************************************************************/

use "$data_prep\drg_08bis14_pregnant_sample_reg_gemeinde_ohnemissings.dta", clear
destring gem_id_pat, replace	
global base i.did i.post i.aufn_jahr	


** upper terzile without control variables
preserve 
qui keep if gisd_terz == 3
		foreach var of varlist kaiser_ops schulter_icd wehen_ops spaet_icd normaldauer_icd frueh_icd tage ln_tage erloes ln_erloes prozedur_all_total diagnose_all_total { // 
			eststo did_`var': reg `var' $base, vce(robust) 		
				
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
esttab did_kaiser_ops did_schulter_icd did_wehen_ops did_spaet_icd did_normaldauer_icd did_frueh_icd did_tage did_ln_tage did_erloes did_ln_erloes did_prozedur_all_total did_diagnose_all_total using "${results}\did_results_pregnant_gisd_terz_$date", replace scsv mtitles("Kaiserschnitt" "Schulterdystokie" "Labor induction" "Late term" "Normal term" "Pre term" "Verweildauer" "Verweildauer (log.)" "Erlös" "Erlös (log.)" "Prozeduren" "Diagnosen") keep(1.did) addnotes("robuste Standardfehler") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Tabellen mit den Ergebnissen der DiD-Schätzungen für Entbindungen - GISD highest terzile (highest depriv)") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3))   // 
restore



** medium terzile without control variables
preserve 
qui keep if gisd_terz == 2
		foreach var of varlist kaiser_ops schulter_icd wehen_ops spaet_icd normaldauer_icd frueh_icd tage ln_tage erloes ln_erloes prozedur_all_total diagnose_all_total { // 
			eststo did_`var': reg `var' $base, vce(robust) 		
				
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
esttab did_kaiser_ops did_schulter_icd did_wehen_ops did_spaet_icd did_normaldauer_icd did_frueh_icd did_tage did_ln_tage did_erloes did_ln_erloes did_prozedur_all_total did_diagnose_all_total using "${results}\did_results_pregnant_gisd_terz_$date", append scsv mtitles("Kaiserschnitt" "Schulterdystokie" "Labor induction" "Late term" "Normal term" "Pre term" "Verweildauer" "Verweildauer (log.)" "Erlös" "Erlös (log.)" "Prozeduren" "Diagnosen") keep(1.did) addnotes("robuste Standardfehler") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Tabellen mit den Ergebnissen der DiD-Schätzungen für Entbindungen - GISD medium terzile (medium depriv)") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3))   // 
restore




** lowest terzile without control variables
preserve 
qui keep if gisd_terz == 1
		foreach var of varlist kaiser_ops schulter_icd wehen_ops spaet_icd normaldauer_icd frueh_icd tage ln_tage erloes ln_erloes prozedur_all_total diagnose_all_total { // 
			eststo did_`var': reg `var' $base, vce(robust) 		
				
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
esttab did_kaiser_ops did_schulter_icd did_wehen_ops did_spaet_icd did_normaldauer_icd did_frueh_icd did_tage did_ln_tage did_erloes did_ln_erloes did_prozedur_all_total did_diagnose_all_total using "${results}\did_results_pregnant_gisd_terz_$date", append scsv mtitles("Kaiserschnitt" "Schulterdystokie" "Labor induction" "Late term" "Normal term" "Pre term" "Verweildauer" "Verweildauer (log.)" "Erlös" "Erlös (log.)" "Prozeduren" "Diagnosen") keep(1.did) addnotes("robuste Standardfehler") cells(b(fmt(6) star) se(par) p) starlevels(* 0.1 ** 0.05 *** 0.01) stardetach title("Tabellen mit den Ergebnissen der DiD-Schätzungen für Entbindungen - GISD lowest terzile (low depriv)") stats(N y_mean ci_ll ci_ul b_rel ci_ll_rel ci_ul_rel, labels("Observations" "Mean of outcome" "95%-KI LB" "95%-KI UB" "prozentualer Effekt" "Konfidenzintervall lower bound- prozentual" "Konfidenzintervall upper bound- prozentual") fmt(0 3 6 6 3 3 3))   // 
restore


cap log close