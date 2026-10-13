/*********************************************************************************************************************
This master do-file contains the analysis of all results relating to the newborns 
*********************************************************************************************************************/

clear all

/*** Set Stata version																							  ***/
version 17   /*** Specify version                                                                                ***/

/*** Configure display output																					  ***/
set more off
set logtype text
set linesize 255 

/*** Set ado-file path																							  ***/
sysdir set PERSONAL "Z:\Fuerth\GWA61_5015\C_Programme\ado"

mata mata mlib index

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
log using "$log\gdm_pregnant_$date.log", replace


/********************************************************************************************************************/
/*			Do-Files																								*/
/********************************************************************************************************************/	 


*1. Prepare data 
do "$do\gdm_pregnant_aufbereitung_261006.do"

*2. descriptive analyses 
do "$do\gdm_pregnant_deskriptiv_261006.do" // Fig A.2 + Tab A.1 
do "$do\gdm_pregnant_means_261006.do" // Tab 1

*3. Regressionsanalysen (Tab. 3)
do "$do\gdm_pregnant_regressionen_261006.do"

*4. Robustness (Tab. A.6)
do "$do\gdm_pregnant_robustness_261006.do"

*5. Balancing (Tab. A.3)
do "$do\gdm_pregnant_balancing_261006.do"

*6. Balancing (Tab. A.4)
do "$do\gdm_pregnant_selektion_261006.do"


cap log close
