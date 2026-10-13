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
log using "$log\gdm_newborn_deskriptiv_$date.log", replace

/********************************************************************************************************************/
/*** II.  Descriptives								  ***/
/********************************************************************************************************************/


/*

1. This file produces the means of the sample by yob x quarter of birth
2. These means are used to create Figure 2 and Fig A.1, which is performed locally
3. This files also contains the number of observations by yob * quarter of birth. The number of observations for each year in Table A.1 is calculated locally based on these numbers
*/


* Load the dataset
use "$data_prep\drg_08bis14_kids_sample_deskr.dta", clear



	   
/*** II.a means by yob x quarter of birth***/											

* Darstellung for the Geheimhaltungsprüfung per tabstat
tabstat geb_jahr quarter aufn_gew makro_40 makro_45 low_bw, statistics(mean count) by (gruppe) save 


* Step 1
putexcel set "$results/means_by_year_quarter_newborn_$date.xlsx", replace
putexcel A1 = "Gruppe"
putexcel B1 = "Geburtsjahr"
putexcel C1 = "Geburtsquartal"
putexcel D1 = "aufn_gew"
putexcel E1 = "makro_40"
putexcel F1 = "makro_45"
putexcel G1 = "low_bw"
putexcel H1 = "N"


* Step 2
		foreach num of numlist 1(1)24 {
				local zeile = `num'+1
				putexcel A`zeile'= "`num'"
				matrix gruppe`num' = r(Stat`num')[1,1] , r(Stat`num')[1,2] , r(Stat`num')[1,3], r(Stat`num')[1,4], r(Stat`num')[1,5], r(Stat`num')[1,6], r(Stat`num')[2,1]
				putexcel B`zeile'=matrix(gruppe`num')

		}

*Step 3 
matrix total = . , . , r(StatTotal)[1,3], r(StatTotal)[1,4], r(StatTotal)[1,5], r(StatTotal)[1,6], r(StatTotal)[2,1]
putexcel B26=matrix(total) 
putexcel A26= "Total"

cap log close













