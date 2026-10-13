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
global datenpfad "$main\A_Mikrodaten\externe_Daten"		// External data
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
log using "$log\gdm_extern_$date.log", replace




/********************************************************************************************************************/
/*** I.  First prepare the external data							  				***/
/********************************************************************************************************************/


****** Convert all datasets to .dta format
foreach y in 08 09 10 11 12 13  {
import delimited "${datenpfad}\Regio_20`y'_final.csv", clear
destring gem_id_08, replace
save "${data_prep}\Regio_20`y'_prep.dta", replace
}

*****************Perform the following steps for each year
foreach y in 08 09 10 11 12 13 { // 
	
		** 1. Load dataset
		use "${data_prep}\Regio_20`y'_prep.dta", clear

		****** 2. Convert municipality variables to strings
		foreach var of varlist gem_id_09 gem_id_10 gem_id_11 gem_id_12 gem_id_13  {
				gen `var'_str = string(`var', "%08.0f")
		}
		
		****** 3. Add leading zeros to construct eight-digit municipality codes (AGS)
		foreach var of varlist gem_id_08 {
				clonevar `var'_str = `var'
				qui replace `var'_str = "0" + `var' if length(`var') == 7 
		}


		***** 4. Identify municipalities affected by a code change but not an actual municipal boundary change
		
		qui gen zeile = _n
		qui gen key_change = 0
		qui replace key_change = 1 if inlist(zeile,2246,2247,2248,2250,2252,2256,2262,2263,2264,4682,6179,11444)
		qui replace key_change = 1 if inrange(zeile,9177,10019)
		*gen key_change = ag_t == 3 // Municipalities affected only by an ID change, without a substantive municipal reform
	
		** Identify municipalities affected by both a substantive municipal change and an ID change.
		qui gen multiple_change = 0
		qui replace multiple_change = 1 if inlist(zeile,9190,9199,  ///
													9211,9224,9266,9275,9287,9288,9290,9291,9292, ///
													9372,9376,9386,9387,9388,9390,9391,9392, ///
													9576,9577, ///
													9610,9611,9640,9664,9665,9694, ///
													9704,9716,9717,9718,9733,9744,9745,9763,9771, ///
													9800,9801,9813,9814,9816,9835,9836,9855,9894,9896, ///
													9926,9928,9929,9934,9959,9978,9980, ///
													10003,10006,10007)
		qui replace multiple_change = 1	if inrange(zeile,9342,9349)										
		qui replace multiple_change = 1	if inrange(zeile,9570,9574)
		
		qui replace key_change = 0 if multiple_change == 1
		
		
		****5. Remove duplicates
		duplicates drop gem_id_08_str gem_id_09_str gem_id_10_str ///
                gem_id_11_str gem_id_12_str gem_id_13_str, force					

	
		******** 6. Identify changes in municipality IDs over time, which may indicate a merger or establishment of a new municipality
		egen change = diff(gem_id_08_str gem_id_09_str gem_id_10_str gem_id_11_str gem_id_12_str gem_id_13_str)
		label var change "Betroffen von Gemeindereform (Änderung der Gemeinde ID im Zeitverlauf)"	

	
		******* 6. Identify repeated municipality IDs within a year -> indicating municipality mergers
		order gem_id_08_str gem_id_09_str gem_id_10_str gem_id_11_str gem_id_12_str gem_id_13_str 
		sort gem_id_08_str
		
		foreach var of varlist gem_id_08_str gem_id_09_str gem_id_10_str gem_id_11_str gem_id_12_str gem_id_13_str  {
				sort `var'
				gen zusammenlegung_`var' = (`var' == `var'[_n+1]) | (`var' == `var'[_n-1])
						}
		
		egen zusammenlegung_ = rowmax(zusammenlegung_gem_id_08_str zusammenlegung_gem_id_09_str zusammenlegung_gem_id_10_str zusammenlegung_gem_id_11_str zusammenlegung_gem_id_12_str zusammenlegung_gem_id_13_str)
		gen zusammenlegung = zusammenlegung_ >= 1 & zusammenlegung_ < .
		label var zusammenlegung "Betroffen von Gemeidnereform (besteht aus mehreren, früher eigenständigen Gemeinden)"

		
		* Municipality is affected by an eight-digit AGS code change over time or multiple IDs within a year, excluding pure code changes
		gen gemeinde_betroffen = (change == 1 | zusammenlegung == 1) & key_change == 0
		
		
		****** 7. generate further variables 
		
		* Share of private health insurees
		gen pkv = (br_v + br_t + selbst)/bev_rdb
		label var pkv "Proxy PKV"		
	
		gen year = 20`y' 
		clonevar gem_id_pat = gem_id_`y'_str
		
		keep gem_id_`y'_str gem_id_`y'_str anz_kk_gem - gem_id_pat
		order gem_id_pat gem_id_`y'_str year
		
		*Duplicates 
		bys gem_id_pat year: gen row = _n 
		keep if row == 1
	
		save "${data_prep}\Regio_20`y'_final.dta", replace
		
}


** Append all data sets
use "${data_prep}\Regio_2008_final.dta", clear
append using "${data_prep}\Regio_2009_final.dta", force
append using "${data_prep}\Regio_2010_final.dta", force
append using "${data_prep}\Regio_2011_final.dta", force
append using "${data_prep}\Regio_2012_final.dta", force
append using "${data_prep}\Regio_2013_final.dta", force

** Save final regional data set that can be merged
save "${data_prep}\Regio_FINAL.dta", replace


log close


