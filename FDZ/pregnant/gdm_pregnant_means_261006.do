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
log using "$log\gdm_pregnant_means_$date.log", replace

/********************************************************************************************************************/
/*** II.  Sample means are produced in this file								  ***/
/********************************************************************************************************************/





* Load dataset
use "$data_prep\drg_08bis14_pregnant_sample_reg.dta", clear




/*** II.a Sample means					  	 ***/											

	   
destring pat_bula pat_typ_gem_reg, replace

label var kaiser_ops "C-section" 
label var schulter_icd "Obstructed labor due to shoulder dystocia"
label var wehen_ops "Labor induction procedure"
label var spaet_icd "Late-term birth"
label var frueh_icd "Pre-term birth"

label var tage "Length of stay"
label var erloes "Reimbursement claims (in euro)"
label var prozedur_all_total "No. of procedures"
label var diagnose_all_total "No. of diagnoses"

label var alter "Age"

label var pat_bula_1 "Schleswig-Holstein"
label var pat_bula_2 "Hamburg"
label var pat_bula_3 "Lower Saxony"
label var pat_bula_4 "Bremen"
label var pat_bula_5 "North-Rhine Westphalia"
label var pat_bula_6 "Hesse"
label var pat_bula_7 "Rhineland-Palatinate"
label var pat_bula_8 "Baden-Wuerttemberg"
label var pat_bula_9 "Bavaria"
label var pat_bula_10 "Saarland"
label var pat_bula_11 "Berlin"
label var pat_bula_12 "Brandenburg"
label var pat_bula_13 "Meckelnburg-Western Pomerania"
label var pat_bula_14 "Saxony"
label var pat_bula_15 "Saxony-Anhalt"
label var pat_bula_16 "Thuringia"

label var pat_typ_gem_reg_1 "City"
label var pat_typ_gem_reg_2 "Urban"
label var pat_typ_gem_reg_3 "Rural"

tabstat kaiser_ops schulter_icd wehen_ops spaet_icd frueh_icd tage erloes prozedur_all_total diagnose_all_total alter pat_bula_1 - pat_bula_16 pat_typ_gem_reg_1 - pat_typ_gem_reg_3, statistics(mean n sd)

dtable kaiser_ops schulter_icd wehen_ops spaet_icd frueh_icd tage erloes prozedur_all_total diagnose_all_total alter pat_bula_1 - pat_bula_16 pat_typ_gem_reg_1 - pat_typ_gem_reg_3, export("$results/sample_means_$date.xlsx", replace) 

cap log close


