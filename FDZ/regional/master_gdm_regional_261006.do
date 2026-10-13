/*********************************************************************************************************************
This is the master file for the results dsipalyed in table A.7 

*********************************************************************************************************************/

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

/*** Path macros																							  ***/
global main "Z:\Fuerth\GWA61_5015"				// Project directory
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
log using "$log\gdm_master_regional_$date.log", replace



/********************************************************************************************************************/
/*			Do-files for the regional analyses																								*/
/********************************************************************************************************************/	 

/*** Run the individual do-files 																			  ***/

*1. Prepare external (regional) data
do "$do\aufbereitung_extern_update.do"

*2. Produce results for Table A.7 
do "$do\gdm_newborn_GISD_261006.do" // Heterogeneity in newborn outcomes by GISD tercile (Panel A)
do "$do\gdm_pregnant_GISD_261006.do" // Heterogeneity in maternal outcomes by GISD tercile (Panel b)
do "$do\gdm_newborn_pregnant_kosten_GISD_261006.do" // Heterogeneity in combined maternal and newborn costs by GISD tercile (Panel C)


log close































