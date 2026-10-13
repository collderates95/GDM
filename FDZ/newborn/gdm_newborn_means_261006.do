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
log using "$log\gdm_newborn_means_$date.log", replace

/********************************************************************************************************************/
/*** II.  Sample means are produced in this file								  ***/
/********************************************************************************************************************/




* Load the dataset
use "$data_prep\drg_08bis14_kids_sample_reg.dta", clear

	   
/*** II.a Sample means					  	 ***/											


 
destring pat_bula pat_typ_gem_reg, replace

label var diabetes_icd "Transient metab. dirsorder" 
label var aufn_gew "Birth weight (in grams)"
label var makro_40 "Macrosomie >= 4000g"
label var low_bw "Low birth weight"
label var tage "Length of stay"
label var erloes "Reimbursement claims (in euro)"
label var prozedur_all_total "No. of procedures"
label var diagnose_all_total "No. of diagnoses"

label var female "Female"

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

tabstat diabetes_icd aufn_gew makro_40 low_bw tage erloes prozedur_all_total diagnose_all_total female pat_bula_1 - pat_bula_16 pat_typ_gem_reg_1 - pat_typ_gem_reg_3, statistics(mean n sd)

dtable diabetes_icd aufn_gew makro_40 low_bw tage erloes prozedur_all_total diagnose_all_total female pat_bula_1 - pat_bula_16 pat_typ_gem_reg_1 pat_typ_gem_reg_2 pat_typ_gem_reg_3, export("$results/sample_means_$date.xlsx", replace) 

cap log close










