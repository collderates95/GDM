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
log using "$log\gdm_newborn_aufbereitung_$date.log", replace


/********************************************************************************************************************/
/*** I.  DATA PREPARATION														  								  ***/
/********************************************************************************************************************/


/********************************************************************************************************************/
/*** a. Select the required variables and observations													              ***/


/*** Identify newborns born between 2008 and 2013 with valid birth-month information; save annual datasets separately. ***/
/*** Include the 2014 reporting year because it also includes children born in 2013. ***/
/*** Process reporting years separately because variable availability changes over time. ***/


/*** 2008 + 2009	(BwrlVol only in 2008 and 2009)															          ***/
foreach year of numlist 2008/2009 { 
	use kh_land kh_rb kh_kreis kh_gem kh_plz  pat_land pat_rb pat_kreis pat_gem pat_ags5 sex geb_jahr geb_monat alter_tage aufn_anl aufn_grd aufn_gew icd_hd3 - icd_nd89 ops_ko1 - ops_ko101 auf_monat aufn_jahr dat_aufn BwrlVol kh_typ_gem pat_typ_gem tage typ_vwd entl_grd ///
	using "$datenpfad\drg`year'_5015_2024_gwap.dta" if alter_tage == 1 & inrange(geb_monat,1,12) & inrange(geb_jahr,2008,2013) , clear
	save "$data_prep\drg`year'_kids.dta", replace
}


/*** 2010 (revenue variable changes from BwrlVol to cm_vol in 2010)															          ***/
foreach year of numlist 2010 { 
	use kh_land kh_rb kh_kreis kh_gem kh_plz  pat_land pat_rb pat_kreis pat_gem pat_ags5 sex geb_jahr geb_monat alter_tage aufn_anl aufn_grd aufn_gew icd_hd3 - icd_nd89 ops_ko1 - ops_ko101 auf_monat aufn_jahr dat_aufn cm_vol kh_typ_gem pat_typ_gem tage typ_vwd  ///
	using "$datenpfad\drg`year'_5015_2024_gwap.dta" if alter_tage == 1 & inrange(geb_monat,1,12) & inrange(geb_jahr,2008,2013) , clear
	save "$data_prep\drg`year'_kids.dta", replace
}


/*** 2011 - 2014	(regional-classification variables change to ..._typ_gem3 from 2011 onwards)														***/
foreach year of numlist 2011/2014 { 
	use kh_land kh_rb kh_kreis kh_gem kh_plz  pat_land pat_rb pat_kreis pat_gem pat_ags5 sex geb_jahr geb_monat alter_tage aufn_anl aufn_grd aufn_gew icd_hd3 - icd_nd89 ops_ko1 - ops_ko101 auf_monat aufn_jahr dat_aufn cm_vol kh_typ_gem3 pat_typ_gem3 tage typ_vwd entl_grd ///
	using "$datenpfad\drg`year'_5015_2024_gwap.dta" if alter_tage == 1 & inrange(geb_monat,1,12) & inrange(geb_jahr,2008,2013) , clear
	save "$data_prep\drg`year'_kids.dta", replace
}


/***	Append annual datasets																				***/
use "$data_prep\drg2008_kids.dta", replace
foreach year of numlist 2009/2014 {
	append using "$data_prep\drg`year'_kids.dta"
}

*** Save the raw dataset for the years 2008-2014
save "$data_prep\drg_08bis14_kids_appended.dta", replace

use "$data_prep\drg_08bis14_kids_appended.dta", clear



				
/********************************************************************************************************************/
/*** b. Create post and treatment indicators based on month of birth			  				  ***/
generate post = 0
qui replace post = 1 if inrange(geb_monat,10,12)
label var post "=1, wenn Okt-Dez"

generate treat = 0
qui replace treat = 1 if geb_jahr == 2013
label var treat "=1, wenn im Treatmentjahr geboren"

/************************************************************************************************************************/
/*** c. Create interaction terms, that takes the value 1 for the observations, who were eligible for GDM screening (10/2013 - 12/2013).  ***/
   					
gen did = post*treat
label var did "= 1, wenn tatsächlicher Anspruch im Jahr 2013 auf das GDM-Screening bestand"



/********************************************************************************************************************/
/*** d. Create a birth-quarter indicator												  		  ***/
gen quarter = 1 if inrange(geb_monat,1,3)
qui replace quarter = 2 if inrange(geb_monat,4,6)
qui replace quarter = 3 if inrange(geb_monat,7,9)
qui replace quarter = 4 if inrange(geb_monat,10,12)
label var quarter "Quartal der Geburt"
			
/********************************************************************************************************************/
/*** d. Create a birth-year-by-birth-quarter indicator								  ***/					
egen gruppe = group(geb_jahr quarter)
label var gruppe "Indikator für Geburtjahr-Geburtsquartal"
					
label def gruppe 	1 "Q1/2008" 	2 "Q2/2008" 	3 "Q3/2008" 	4 "Q4/2008"		///	
					5 "Q1/2009" 	6 "Q2/2009" 	7 "Q3/2009" 	8 "Q4/2009" 	///
					9 "Q1/2010" 	10 "Q2/2010" 	11 "Q3/2010" 	12 "Q4/2010"	///
					13 "Q1/2011" 	14 "Q2/2011" 	15 "Q3/2011" 	16 "Q4/2011"	///
					17 "Q1/2012" 	18 "Q2/2012" 	19 "Q3/2012" 	20 "Q4/2012"	///
					21 "Q1/2013" 	22 "Q2/2013" 	23 "Q3/2013" 	24 "Q4/2013"
					
label val gruppe gruppe					

/********************************************************************************************************************/
/*** e. P70 (Transitory metab. disorder)		  ***/


*** primary diagnosis
		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			generate `var'_diabetes = 0
		}

		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			qui replace `var'_diabetes = 1 if substr(`var',1,3) == "P70"
		}

egen diabetes_hd = rowmax(icd_hd3_diabetes icd_hd4_diabetes icd_hd_diabetes)
label var diabetes_hd "=1, wenn Diabetes als Hauptdiagnose"

drop icd_hd3_diabetes icd_hd4_diabetes icd_hd_diabetes

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate diabetes_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace diabetes_icd_nd`num' = 1 if substr(icd_nd`num',1,3) == "P70"
		}
		
egen diabetes_nd = rowmax(diabetes_icd_nd1 - diabetes_icd_nd89)
label var diabetes_nd "=1, wenn Diabetes als Nebendiagnose"
drop diabetes_icd_nd1 - diabetes_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen diabetes_icd = (diabetes_hd == 1 | diabetes_nd == 1)
label var diabetes_icd "= 1, wenn Diabetes als Haupt- oder Nebendiagnose"

drop diabetes_hd diabetes_nd


/********************************************************************************************************************/
/*** f. P700						  ***/

*** primary diagnosis
		foreach var of varlist icd_hd4 icd_hd {
			generate `var'_gdm = 0
		}

		foreach var of varlist icd_hd4 icd_hd {
			qui replace `var'_gdm = 1 if substr(`var',1,4) == "P700"
		}

egen gdm_hd = rowmax(icd_hd4_gdm icd_hd_gdm)
label var gdm_hd "=1, wenn Mutter mit GDM als Hauptdiagnose"

drop  icd_hd4_gdm icd_hd_gdm

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate gdm_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace gdm_icd_nd`num' = 1 if substr(icd_nd`num',1,4) == "P700"
		}
		
egen gdm_nd = rowmax(gdm_icd_nd1 - gdm_icd_nd89)
label var gdm_nd "=1, wenn wenn Mutter mit GDM als Nebendiagnose"
drop gdm_icd_nd1 - gdm_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen gdm_icd = (gdm_hd == 1 | gdm_nd == 1)
label var gdm_icd "= 1, wenn wenn Mutter mit GDM als Haupt- oder Nebendiagnose"

drop gdm_hd gdm_nd


/************************************************************************************************************************/
/*** g. P700 or P701	  ***/

*** primary diagnosis
		foreach var of varlist icd_hd4 icd_hd {
			generate `var'_dm = 0
		}

		foreach var of varlist icd_hd4 icd_hd {
			qui replace `var'_dm = 1 if substr(`var',1,4) == "P700" | substr(`var',1,4) == "P701"
		}

egen dm_hd = rowmax(icd_hd4_dm icd_hd_dm)
label var dm_hd "=1, wenn Mutter mit GDM oder DM als Hauptdiagnose"

drop  icd_hd4_dm icd_hd_dm

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate dm_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace dm_icd_nd`num' = 1 if substr(icd_nd`num',1,4) == "P700" | substr(icd_nd`num',1,4) == "P701"
		}
		
egen dm_nd = rowmax(dm_icd_nd1 - dm_icd_nd89)
label var dm_nd "=1, wenn Mutter mit GDM oder DM als Nebendiagnose"
drop dm_icd_nd1 - dm_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen dm_icd = (dm_hd == 1 | dm_nd == 1)
label var dm_icd "= 1, wenn wenn Mutter mit GDM oder DM als Haupt- oder Nebendiagnose"

drop dm_hd dm_nd



/************************************************************************************************************************/
/*** h. P700 - P 702 ***/

*** primary diagnosis
		foreach var of varlist icd_hd4 icd_hd {
			generate `var'_diab = 0
		}

		foreach var of varlist icd_hd4 icd_hd {
			qui replace `var'_diab = 1 if substr(`var',1,4) == "P700" | substr(`var',1,4) == "P701" | substr(`var',1,4) == "P702"
		}

egen diab_hd = rowmax(icd_hd4_diab icd_hd_diab)
label var diab_hd "=1, wenn Mutter mit GDM oder DM als Hauptdiagnose oder Kind mit Diabetes"

drop  icd_hd4_diab icd_hd_diab

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate diab_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace diab_icd_nd`num' = 1 if substr(icd_nd`num',1,4) == "P700" | substr(icd_nd`num',1,4) == "P701" | substr(icd_nd`num',1,4) == "P702"
		}
		
egen diab_nd = rowmax(diab_icd_nd1 - diab_icd_nd89)
label var diab_nd "=1, wenn Mutter mit GDM oder DM als Nebendiagnose"
drop diab_icd_nd1 - diab_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen diab_icd = (diab_hd == 1 | diab_nd == 1)
label var diab_icd "= 1, wenn wenn Mutter mit GDM oder DM als Haupt- oder Nebendiagnose oder Kind mit Diabetes"

drop diab_hd diab_nd




/************************************************************************************************************************/
/*** i. E10 to E14 ***/

*** primary diagnosis
		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			generate `var'_e1014 = 0
		}

		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			qui replace `var'_e1014 = 1 if substr(`var',1,3) == "E10" | substr(`var',1,3) == "E11" | substr(`var',1,3) == "E12" | substr(`var',1,3) == "E13" | substr(`var',1,3) == "E14"
		}

egen e1014_hd = rowmax(icd_hd3_e1014 icd_hd4_e1014 icd_hd_e1014)
label var e1014_hd "=1, wenn Diabetes bei ICD-Codes E10 bis E14 als Hauptdiagnose"

drop icd_hd3_e1014 icd_hd4_e1014 icd_hd_e1014

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate e1014_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace e1014_icd_nd`num' = 1 if substr(icd_nd`num',1,3) == "E10" | substr(icd_nd`num',1,3) == "E11" | substr(icd_nd`num',1,3) == "E12" | substr(icd_nd`num',1,3) == "E13" | substr(icd_nd`num',1,3) == "E14"
		}
		
egen e1014_nd = rowmax(e1014_icd_nd1 - e1014_icd_nd89)
label var e1014_nd "=1, wenn Diabetes bei ICD-Codes E10 bis E14 als Nebendiagnose"
drop e1014_icd_nd1 - e1014_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen e1014_icd = (e1014_hd == 1 | e1014_nd == 1)
label var e1014_icd "= 1, wenn Diabetes bei ICD-Codes E10 bis E14 als Haupt- oder Nebendiagnose"

drop e1014_hd e1014_nd



/********************************************************************************************************************/
/*** j. Multiple births						  ***/


*** primary diagnosis
		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			generate `var'_mehrling = 0
		}

		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			qui replace `var'_mehrling = 1 if substr(`var',1,4) == "Z383" | substr(`var',1,4) == "Z384" | substr(`var',1,4) == "Z385" | substr(`var',1,4) == "Z386" | substr(`var',1,4) == "Z387" | substr(`var',1,4) == "Z388" | substr(`var',1,4) == "Z372" | substr(`var',1,4) == "Z375"
		}

egen mehrling_hd = rowmax(icd_hd3_mehrling icd_hd4_mehrling icd_hd_mehrling)
label var mehrling_hd "=1, wenn Zwilling/Mehrling als Hauptdiagnose"

drop icd_hd3_mehrling icd_hd4_mehrling icd_hd_mehrling

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate mehrling_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace mehrling_icd_nd`num' = 1 if substr(icd_nd`num',1,4) == "Z383" | substr(icd_nd`num',1,4) == "Z384" | substr(icd_nd`num',1,4) == "Z385" | substr(icd_nd`num',1,4) == "Z386" | substr(icd_nd`num',1,4) == "Z387" | substr(icd_nd`num',1,4) == "Z388" | substr(icd_nd`num',1,4) == "Z372" | substr(icd_nd`num',1,4) == "Z375"
		}
		
egen mehrling_nd = rowmax(mehrling_icd_nd1 - mehrling_icd_nd89)
label var mehrling_nd "=1, wenn Zwilling/Mehrling als Nebendiagnose"
drop mehrling_icd_nd1 - mehrling_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen mehrling_icd = (mehrling_hd == 1 | mehrling_nd == 1)
label var mehrling_icd "=1, wenn Zwilling/Mehrling als  Haupt- oder Nebendiagnose"



/********************************************************************************************************************/
/*** k. Harmonization of regional type variables (City, Urban, Rural)					  ***/


** KKH-Gebiet 2008-2010
destring kh_typ_gem, replace
recode kh_typ_gem (1/8 = 1) (9/13=2) (14/17=3), gen(kh_typ_gem_neu)
tab kh_typ_gem_neu

** KKH-Gebiet ab 2011
destring kh_typ_gem3, replace
tab kh_typ_gem3

** KKH-Gebiet harmonisiert
clonevar kh_typ_gem_reg = kh_typ_gem_neu
qui replace kh_typ_gem_reg = kh_typ_gem3 if kh_typ_gem_reg == .
label def kh_typ_gem_reg 1 "Städtische Region" 2 "Verstädterte Räume" 3 "Ländliche Region"
label val kh_typ_gem_reg kh_typ_gem_reg  
label var kh_typ_gem_reg "Gebietstyp KKH"
tab kh_typ_gem_reg, gen(kh_typ_gem_reg_)			// Dummy
drop kh_typ_gem_neu


** Patienten-Gebiet 2008-2010
qui replace pat_typ_gem = "18" if pat_typ_gem == "oh" | pat_typ_gem == "un" | pat_typ_gem == "au" | pat_typ_gem == ""
destring pat_typ_gem, replace
recode pat_typ_gem (1/8 = 1) (9/13=2) (14/17=3) (18=4), gen(pat_typ_gem_neu)
qui replace pat_typ_gem_neu = kh_typ_gem_reg if pat_typ_gem_neu == 4 

** Patienten-Gebiet ab 2011
destring pat_typ_gem3, replace

** Patienten-Gebiet harmonisiert
clonevar pat_typ_gem_reg = pat_typ_gem_neu
qui replace pat_typ_gem_reg = pat_typ_gem3 if pat_typ_gem_reg == .
label def pat_typ_gem_reg 1 "Städtische Region" 2 "Verstädterte Räume" 3 "Ländliche Region"
label val pat_typ_gem_reg pat_typ_gem_reg  
label var pat_typ_gem_reg "Gebietstyp Patient"
tab pat_typ_gem_reg, gen(pat_typ_gem_reg_)			// Dummy



/********************************************************************************************************************/
/*** l. Further outcome variables 																***/

gen makro_40 = aufn_gew >= 4000 & aufn_gew <. 
gen makro_45 = aufn_gew >= 4500 & aufn_gew <. 
gen low_bw = aufn_gew < 2500

gen erloes = BwrlVol 
qui replace erloes = cm_vol if erloes == .

gen ln_erloes = ln(erloes)
gen ln_tage = ln(tage)


label var makro_40 "= 1, wenn Geburtsgewicht >= 4000g"
label var makro_45 "= 1, wenn Geburtsgewicht >= 4500g"
label var low_bw "= 1, wenn Geburtsgewicht < 2500g"	   
label var aufn_gew "Gewicht bei Aufnahme (hier: Geburtsgewicht)"
label var erloes "Erlösvolumen"
label var tage "Verweildauer"


/********************************************************************************************************************/
/*** m. Birth in last 14 days of September or first 14 days of October					  ***/
gen auf_tag = substr(dat_aufn,7,2) 
destring auf_tag, replace

gen donut = 0
qui replace donut = 1 if auf_monat == 9 & inrange(auf_tag,17,30)
qui replace donut = 1 if auf_monat == 10 & inrange(auf_tag,1,14)



/********************************************************************************************************************/
/***m.  If state of residence of patient invalid, replaced with federal state of the hospital ersetzt */
clonevar pat_bula = pat_land
qui replace pat_bula = kh_land if inlist(pat_bula,"oh","un")								
destring pat_bula, replace

tab pat_bula, gen(pat_bula_)


/********************************************************************************************************************/
/*** n. Gender	 									  								  ***/
gen female = 0 
qui replace female = 1 if sex == "w"
label var female "=1, wenn weiblich"


/********************************************************************************************************************/
/*** o. Birth ***/

*** primary diagnosis
foreach var of varlist icd_hd3 icd_hd4 icd_hd {
	generate `var'_geburt = 0
}

foreach var of varlist icd_hd3 icd_hd4 icd_hd {
	qui replace `var'_geburt = 1 if substr(`var',1,3) == "Z38" 
}

egen geburt_hd = rowmax(icd_hd3_geburt icd_hd4_geburt icd_hd_geburt)
label var geburt_hd "=1, wenn Geburt als Hauptdiagnose"

drop icd_hd3_geburt icd_hd4_geburt icd_hd_geburt

*** secondary diagnosis
foreach var of varlist icd_nd1 - icd_nd89 {
	generate geburt_`var' = 0
}

foreach num of numlist 1/89 {
	qui replace geburt_icd_nd`num' = 1 if substr(icd_nd`num',1,3) == "Z38"  
}
egen geburt_nd = rowmax(geburt_icd_nd1 - geburt_icd_nd89)
label var geburt_nd "=1, wenn Geburt als Nebendiagnose"
drop geburt_icd_nd1 - geburt_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen geburt_icd = (geburt_hd == 1 | geburt_nd == 1)


/********************************************************************************************************************/
/*** p. Number of procedures and diagnoses													  	  				  ***/

*** Number of procedures (total)
		foreach var of varlist ops_ko1 - ops_ko101 {
			qui generate prozedur_`var' = !missing(trim(`var'))
		}

		egen prozedur_all_total = rowtotal(prozedur_ops_ko1 - prozedur_ops_ko101)
		label var prozedur_all_total "Prozeduren (gesamt)"

		drop prozedur_ops_ko1 - prozedur_ops_ko101
		
/*** Number of procedures (geburtsbezogen)
		foreach var of varlist ops_ko1 - ops_ko101 {
			qui generate prozedur_`var' = 0
		}

		foreach var of varlist ops_ko1 - ops_ko101 {
			qui replace prozedur_`var' = 1 if 		substr(`var',1,3) == "572" | ///
													substr(`var',1,3) == "573" | ///
													substr(`var',1,3) == "574" | ///
													substr(`var',1,3) == "575" | ///
													substr(`var',1,3) == "926" | ///
													substr(`var',1,3) == "927" | ///
													substr(`var',1,3) == "928"  													
		}

		egen prozedur_preg_total = rowtotal(prozedur_ops_ko1 - prozedur_ops_ko101)
		label var prozedur_preg_total "Geburtsprozeduren (gesamt)"
		drop prozedur_ops_ko1 - prozedur_ops_ko101
*/
		
*** number of diagnoses (total)
		foreach var of varlist icd_hd icd_nd1-icd_nd89 {
			qui generate diagnose_`var' = !missing(trim(`var'))
		}

		egen diagnose_all_total = rowtotal(diagnose_icd_hd - diagnose_icd_nd89)
		label var diagnose_all_total "Diagnosen (gesamt)"

		drop diagnose_icd_hd - diagnose_icd_nd89
		
/*** number an Diagnosen (geburtsbezogen)
		foreach var of varlist icd_hd icd_nd1-icd_nd89 {
			generate diagnose_`var' = 0
		}

		
		foreach var of varlist icd_hd icd_nd1-icd_nd89 {
			qui replace diagnose_`var' = 1 if 		substr(`var',1,1) == "P" | ///
													substr(`var',1,1) == "O" 
												
		}		
		
		egen diagnose_preg_total = rowtotal(diagnose_icd_hd - diagnose_icd_nd89)
		label var diagnose_preg_total "Geburtsprozeduren (gesamt)"
		
		drop diagnose_icd_hd - diagnose_icd_nd89
*/
		
		
*** Number of procedures + diagnoses (total)
		

		egen proz_diag_all = rowtotal(prozedur_all_total diagnose_all_total)
		label var proz_diag_all "Gesamtzahl an Prozeduren + Diagnosen"
		
		*egen proz_diag_preg = rowtotal(prozedur_preg_total diagnose_preg_total)
		*label var proz_diag_preg "Gesamtzahl an Prozeduren + Diagnosen (SW + birth)"	



/********************************************************************************************************************/
/*** q.	Save data							  	  								  ***/
save "$data_prep\drg_08bis14_kids_prep.dta", replace



/********************************************************************************************************************/
/*** r.	Sample restriction							  	  								  					  ***/
keep if alter_tage == 1	// Identifying newborns
drop if inlist(pat_land,"au")	// Drop patients residing abroad -> no eligibility for GDM screening in Germany
keep if inlist(aufn_grd,1,5,6)  // Admission reason relating to birth/delivery 

compress
save "$data_prep\drg_08bis14_kids_sample_deskr.dta", replace // full Sample (including all quarters)

preserve
keep if inlist(quarter,3,4)
save "$data_prep\drg_08bis14_kids_sample_reg.dta", replace // sample with restrictions to birth quarters 3 and 4 (for analysis) 
restore

cap log close
