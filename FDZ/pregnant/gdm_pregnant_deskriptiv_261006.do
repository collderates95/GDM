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
log using "$log\gdm_pregnant_deskriptiv_$date.log", replace

/********************************************************************************************************************/
/*** II.  Descriptives								  ***/
/********************************************************************************************************************/

* Load dataset
use "$data_prep\drg_08bis14_pregnant_sample_deskr.dta", clear


/*

1. This file produces the means of the sample by yob x quarter of birth
2. These means are used to create Fig A.2, which is performed locally
3. This files also contains the number of observations by yob * quarter of birth. The number of observations for each year in Table A.1 is calculated locally based on these numbers
*/


   
/*** II.a means by yob x quarter of birth***/		

tabstat aufn_jahr quarter kaiser_ops schulter_icd, statistics(mean count) by (gruppe) save


* 1. Schritt
putexcel set "$results/means_by_year_quarter_pregnant.xlsx", replace
putexcel A1 = "Gruppe"
putexcel B1 = "Geburtsjahr"
putexcel C1 = "Geburtsquartal"
putexcel D1 = "kaiser_ops"
putexcel E1 = "schulter_icd"
*putexcel F1 = "normaldauer_icd"
*putexcel G1 = "frueh_icd"
*putexcel H1 = "spaet_icd"
*putexcel I1 = "unbekannt_icd"
*putexcel K1 = "diabetes_icd"
*putexcel K1 = "gdm_icd"
*putexcel L1 = "dm_icd"
*putexcel M1 = "wehen_final"
putexcel F1 = "N"


* 2. Schritt
		foreach num of numlist 1(1)24 {
				local zeile = `num'+1
				putexcel A`zeile'= "`num'"
				matrix gruppe`num' = r(Stat`num')[1,1] , r(Stat`num')[1,2] , r(Stat`num')[1,3], r(Stat`num')[1,4], r(Stat`num')[2,1]
				putexcel B`zeile'=matrix(gruppe`num')

		}

*3. Schritt 
matrix total = . , . , r(StatTotal)[1,3], r(StatTotal)[1,4],  r(StatTotal)[2,1]
putexcel B26=matrix(total) 
putexcel A26= "Total"


cap log close


