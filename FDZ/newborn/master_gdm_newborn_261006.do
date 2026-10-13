/*********************************************************************************************************************
This master do-file contains the analysis of all results relating to mothers 
*********************************************************************************************************************/

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
log using "$log\gdm_newborn_$date.log", replace

	 
/********************************************************************************************************************/
/*			Do-files																								*/
/********************************************************************************************************************/	 

/*** Run the individual do-files 																			  ***/

*1. Data preparation
do "$do\gdm_newborn_aufbereitung_261006.do"

*2. Descriptive analyses 
do "$do\gdm_newborn_deskriptiv_261006.do" // (Fig. 2 & Fig. A.1 & Tab A.1)
do "$do\gdm_newborn_means_261006.do" // Tab 1

*3. Regression analyses (Table 2)
do "$do\gdm_newborn_regressionen_261006.do"

*4 Robustness Regression analyses (Table A.5)
do "$do\gdm_newborn_robustness_261006.do"

*5. Balancing tests (Table A.3)
do "$do\gdm_newborn_balancing_261006.do"

*6. Selection (Table A.4)
do "$do\gdm_newborn_selektion_261006.do"

*7. Robustness Makrosomie (Fig A.4)
do "$do\gdm_newborn_makro_261006.do"

cap log close































