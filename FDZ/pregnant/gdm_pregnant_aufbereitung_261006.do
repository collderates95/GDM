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
log using "$log\gdm_pregnant_aufbereitung_$date.log", replace


/********************************************************************************************************************/
/********************************************************************************************************************/
/*** Titel of the Projekts: 			<Die Entwicklung the frühkindlichen Gesundheit and the 
									 Effekt gesundheitspolitischer Maßnahmen>    								  ***/
/*** Data source: 				<DRG 2008-2014>																  ***/
/***																										      ***/
/*** Program filename: 	<gdm_pregnant_aufbereitung_260901.do>													  ***/
/*** created: 						<01.09.2026> 																  ***/
/*** by: 							<Anton Barabasch> 															  ***/
/*** E-Mail: 						<anton.barabasch@fau.de> 													  ***/
/*** Tel.: 							<0911-530295-344> 															  ***/
/*** 																											  ***/
/*** Output filename: 	<gdm_pregnant_260901.log> 															  ***/
/*** 																											  ***/
/*** 																											  ***/
/*** Program outline: <Reprocess data to create additional outcomes	>					  ***/

/********************************************************************************************************************/
/********************************************************************************************************************/

/********************************************************************************************************************/
/*** I.  DATA PREPARATION														  								  ***/
/********************************************************************************************************************/


/********************************************************************************************************************/
*** a. Select required variables and observations	

/*** Identify all women admitted for inpatient delivery between 2008 and 2014 */
/*** The year 2014 is required because it also contains children born in 2013  ***/
/*** Separate preparation because some variables are only available in certain years ***/


/*** 2008 + 2009 																          ***/
foreach year of numlist 2008/2009 { 		    	  

	use kh_land kh_rb kh_kreis kh_gem kh_plz pat_land pat_rb pat_kreis pat_gem pat_ags5 sex geb_jahr geb_monat alter aufn_anl aufn_grd icd_hd3 - icd_nd89 ops_ko1 - ops_ko101 auf_monat aufn_jahr dat_aufn dat_entl BwrlVol kh_typ_gem pat_typ_gem tage typ_vwd ///
	using "$datenpfad\drg`year'_5015_2024_gwap.dta" if inrange(alter,14,50), clear
	save "$data_prep\drg`year'_pregnant.dta", replace
}

**2010
foreach year of numlist 2010 { 		    	  

	use kh_land kh_rb kh_kreis kh_gem kh_plz pat_land pat_rb pat_kreis pat_gem pat_ags5 sex geb_jahr geb_monat alter aufn_anl aufn_grd icd_hd3 - icd_nd89 ops_ko1 - ops_ko101 auf_monat aufn_jahr dat_aufn dat_entl cm_vol kh_typ_gem pat_typ_gem tage typ_vwd ///
	using "$datenpfad\drg`year'_5015_2024_gwap.dta" if inrange(alter,14,50), clear
	save "$data_prep\drg`year'_pregnant.dta", replace
}

**2011 - 2014
foreach year of numlist 2011/2014 { 		    	  

	use kh_land kh_rb kh_kreis kh_gem kh_plz pat_land pat_rb pat_kreis pat_gem pat_ags5 sex geb_jahr geb_monat alter aufn_anl aufn_grd icd_hd3 - icd_nd89 ops_ko1 - ops_ko101 auf_monat aufn_jahr dat_aufn dat_entl cm_vol kh_typ_gem3 pat_typ_gem3 tage typ_vwd ///
	using "$datenpfad\drg`year'_5015_2024_gwap.dta" if inrange(alter,14,50), clear
	save "$data_prep\drg`year'_pregnant.dta", replace
}
																																							


			
/***	Append annual datasets																								***/
use "$data_prep\drg2008_pregnant.dta", replace
foreach year of numlist 2009/2014 {
	append using "$data_prep\drg`year'_pregnant.dta"
}

/*** Save raw dataset for 2008–2014																								 ***/
save "$data_prep\drg_08bis14_pregnant_appended.dta", replace

use "$data_prep\drg_08bis14_pregnant_appended.dta", clear


/********************************************************************************************************************/
/*** b. Create post and treatment indicators based on month of birth			  				  ***/

generate post = 0
qui replace post = 1 if inrange(auf_monat,10,12)
label var post "=1, wenn Okt-Dez"

generate treat = 0
qui replace treat = 1 if aufn_jahr == 2013
label var treat "=1, wenn im Treatmentjahr aufgenommen"

/************************************************************************************************************************/
/*** c. Create interaction terms, that takes the value 1 for the observations, who were eligible for GDM screening (10/2013 - 12/2013).  ***/
   					
gen did = post*treat
label var did "= 1, wenn tatsächlicher Anspruch im Jahr 2013 auf das GDM-Screening bestand"



/********************************************************************************************************************/
/*** d. Create a birth-quarter indicator												  		  ***/
gen quarter = 1 if inrange(auf_monat,1,3)
qui replace quarter = 2 if inrange(auf_monat,4,6)
qui replace quarter = 3 if inrange(auf_monat,7,9)
qui replace quarter = 4 if inrange(auf_monat,10,12)
label var quarter "Quartal der Aufnahme ins Krankenhaus"
			
/********************************************************************************************************************/
/*** d. Create a birth-year-by-birth-quarter indicator								  ***/					
egen gruppe = group(aufn_jahr quarter)
label var gruppe "Indikator für Aufnahmejahr-Aufnahmequartal"
					
label def gruppe 	1 "Q1/2008" 	2 "Q2/2008" 	3 "Q3/2008" 	4 "Q4/2008"		///	
					5 "Q1/2009" 	6 "Q2/2009" 	7 "Q3/2009" 	8 "Q4/2009" 	///
					9 "Q1/2010" 	10 "Q2/2010" 	11 "Q3/2010" 	12 "Q4/2010"	///
					13 "Q1/2011" 	14 "Q2/2011" 	15 "Q3/2011" 	16 "Q4/2011"	///
					17 "Q1/2012" 	18 "Q2/2012" 	19 "Q3/2012" 	20 "Q4/2012"	///
					21 "Q1/2013" 	22 "Q2/2013" 	23 "Q3/2013" 	24 "Q4/2013"
					
label val gruppe gruppe					




/********************************************************************************************************************/
/*** f. Birth in last 14 days of September or first 14 days of October						  ***/

gen aufn_tag = substr(dat_aufn,7,2) 
destring aufn_tag, replace		
		
gen donut = 0
qui replace donut = 1 if auf_monat == 9 & inrange(aufn_tag,17,30)
qui replace donut = 1 if auf_monat == 10 & inrange(aufn_tag,1,14)



/********************************************************************************************************************/
/*** g. C-section													  	  ***/
		foreach var of varlist ops_ko1 - ops_ko101 {
			generate kaiser_`var' = 0
		}

		foreach num of numlist 1(1)101 {
			qui replace kaiser_ops_ko`num' = 1 if 	substr(ops_ko`num',1,4) == "5740" | ///
												substr(ops_ko`num',1,4) == "5741" | ///
												substr(ops_ko`num',1,4) == "5742" | ///
												substr(ops_ko`num',1,4) == "5749" 
		}
		
egen kaiser_ops = rowmax(kaiser_ops_ko1 - kaiser_ops_ko101)
label var kaiser_ops "=1, wenn Kaiserschnittentbindung als OPS Code"
drop kaiser_ops_ko1 - kaiser_ops_ko101


/********************************************************************************************************************/
/*** h. Shoulder dystocia													  	  ***/

*** primary diagnosis
		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			generate `var'_schulter = 0
		}

		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			qui replace `var'_schulter = 1 if substr(`var',1,3) == "O66" 
		}

egen schulter_hd = rowmax(icd_hd3_schulter icd_hd4_schulter icd_hd_schulter)
label var schulter_hd "=1, wenn Schulterdystokie als Hauptdiagnose"

drop icd_hd3_schulter icd_hd4_schulter icd_hd_schulter

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate schulter_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace schulter_icd_nd`num' = 1 if substr(icd_nd`num',1,3) == "O66"
		}
		
egen schulter_nd = rowmax(schulter_icd_nd1 - schulter_icd_nd89)
label var schulter_nd "=1, wenn Schulterdystokie als Nebendiagnose"
drop schulter_icd_nd1 - schulter_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen schulter_icd = (schulter_hd == 1 | schulter_nd == 1)
label var schulter_icd "= 1, wenn Schulterdystokie als Haupt- oder Nebendiagnose"

drop schulter_hd schulter_nd


/********************************************************************************************************************/
/*** i. Normal term	  ***/

*** primary diagnosis
		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			generate `var'_normaldauer = 0
		}

		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			qui replace `var'_normaldauer = 1 if substr(`var',1,4) == "O096" 
		}

egen normaldauer_hd = rowmax(icd_hd3_normaldauer icd_hd4_normaldauer icd_hd_normaldauer)
label var normaldauer_hd "=1, wenn standardgemäße Dauer der Schwangerschaft als Hauptdiagnose"

drop icd_hd3_normaldauer icd_hd4_normaldauer icd_hd_normaldauer

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate normaldauer_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace normaldauer_icd_nd`num' = 1 if substr(icd_nd`num',1,4) == "O096"
		}
		
egen normaldauer_nd = rowmax(normaldauer_icd_nd1 - normaldauer_icd_nd89)
label var normaldauer_nd "=1, wenn standardgemäße Dauer der Schwangerschaft als Nebendiagnose"
drop normaldauer_icd_nd1 - normaldauer_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen normaldauer_icd = (normaldauer_hd == 1 | normaldauer_nd == 1)
label var normaldauer_icd "= 1, wenn standardgemäße Dauer der Schwangerschaft als Haupt- oder Nebendiagnose"

drop normaldauer_hd normaldauer_nd



/********************************************************************************************************************/
/*** j. Preterm										  ***/

*** primary diagnosis
		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			generate `var'_frueh = 0
		}

		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			qui replace `var'_frueh = 1 if 	substr(`var',1,4) == "O091" | ///
										substr(`var',1,4) == "O092" | ///
										substr(`var',1,4) == "O093" | ///
										substr(`var',1,4) == "O094" | ///
										substr(`var',1,4) == "O095" 
		}

egen frueh_hd = rowmax(icd_hd3_frueh icd_hd4_frueh icd_hd_frueh)
label var frueh_hd "=1, wenn Entbindung früher als SSW 37 als Hauptdiagnose"

drop icd_hd3_frueh icd_hd4_frueh icd_hd_frueh

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate frueh_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace frueh_icd_nd`num' = 1 if 	substr(icd_nd`num',1,4) == "O091" | ///
												substr(icd_nd`num',1,4) == "O092" | ///
												substr(icd_nd`num',1,4) == "O093" | ///
												substr(icd_nd`num',1,4) == "O094" | ///
												substr(icd_nd`num',1,4) == "O095" 
		}
		
egen frueh_nd = rowmax(frueh_icd_nd1 - frueh_icd_nd89)
label var frueh_nd "=1, wenn Entbindung früher als SSW 37 als Nebendiagnose"
drop frueh_icd_nd1 - frueh_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen frueh_icd = (frueh_hd == 1 | frueh_nd == 1)
label var frueh_icd "= 1, wenn Entbindung früher als SSW 37 als Haupt- oder Nebendiagnose"

drop frueh_hd frueh_nd


/********************************************************************************************************************/
/*** k. Late term	  											  ***/

*** primary diagnosis
		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			generate `var'_spaet = 0
		}

		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			qui replace `var'_spaet = 1 if substr(`var',1,4) == "O097" 
		}

egen spaet_hd = rowmax(icd_hd3_spaet icd_hd4_spaet icd_hd_spaet)
label var spaet_hd "=1, wenn Entbindung später als SSW 41 als Hauptdiagnose"

drop icd_hd3_spaet icd_hd4_spaet icd_hd_spaet

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate spaet_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace spaet_icd_nd`num' = 1 if substr(icd_nd`num',1,4) == "O097" 
		}
		
egen spaet_nd = rowmax(spaet_icd_nd1 - spaet_icd_nd89)
label var spaet_nd "=1, wenn Entbindung später als SSW 41 als Nebendiagnose"
drop spaet_icd_nd1 - spaet_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen spaet_icd = (spaet_hd == 1 | spaet_nd == 1)
label var spaet_icd "= 1, wenn Entbindung später als SSW 41 als Haupt- oder Nebendiagnose"

drop spaet_hd spaet_nd


/********************************************************************************************************************/
/*** l. unknown gets. week	  											  ***/

***primary diagnosis
		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			generate `var'_unbekannt = 0
		}

		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			qui replace `var'_unbekannt = 1 if substr(`var',1,4) == "O099" 
		}

egen unbekannt_hd = rowmax(icd_hd3_unbekannt icd_hd4_unbekannt icd_hd_unbekannt)
label var unbekannt_hd "=1, wenn Entbindungswoche unbekannt als Hauptdiagnose"

drop icd_hd3_unbekannt icd_hd4_unbekannt icd_hd_unbekannt

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate unbekannt_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace unbekannt_icd_nd`num' = 1 if substr(icd_nd`num',1,4) == "O099" 
		}
		
egen unbekannt_nd = rowmax(unbekannt_icd_nd1 - unbekannt_icd_nd89)
label var unbekannt_nd "=1, wenn Entbindung später als SSW 41 als Nebendiagnose"
drop unbekannt_icd_nd1 - unbekannt_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen unbekannt_icd = (unbekannt_hd == 1 | unbekannt_nd == 1)
label var unbekannt_icd "= 1, wenn Entbindung später als SSW 41 als Haupt- oder Nebendiagnose"

drop unbekannt_hd unbekannt_nd




/********************************************************************************************************************/
/*** m. Identify maternal diabetes mellitus (all diabetes diagnoses)		  ***/


*** primary diagnosis
		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			generate `var'_diabetes = 0
		}

		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			qui replace `var'_diabetes = 1 if substr(`var',1,3) == "O24"
		}

egen diabetes_hd = rowmax(icd_hd3_diabetes icd_hd4_diabetes icd_hd_diabetes)
label var diabetes_hd "=1, wenn Diabetes mellitus als Hauptdiagnose"

drop icd_hd3_diabetes icd_hd4_diabetes icd_hd_diabetes

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate diabetes_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace diabetes_icd_nd`num' = 1 if substr(icd_nd`num',1,3) == "O24"
		}
		
egen diabetes_nd = rowmax(diabetes_icd_nd1 - diabetes_icd_nd89)
label var diabetes_nd "=1, wenn Diabetes mellitus als Nebendiagnose"
drop diabetes_icd_nd1 - diabetes_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen diabetes_icd = (diabetes_hd == 1 | diabetes_nd == 1)
label var diabetes_icd "= 1, wenn Diabetes mellitus als Haupt- oder Nebendiagnose"

drop diabetes_hd diabetes_nd


/********************************************************************************************************************/
/*** n. Identify mothers with GDM						  ***/

*** primary diagnosis
		foreach var of varlist icd_hd4 icd_hd {
			generate `var'_gdm = 0
		}

		foreach var of varlist icd_hd4 icd_hd {
			qui replace `var'_gdm = 1 if substr(`var',1,4) == "O244" | substr(`var',1,4) == "O249"
		}

egen gdm_hd = rowmax(icd_hd4_gdm icd_hd_gdm)
label var gdm_hd "=1, wenn GDM als Hauptdiagnose"

drop  icd_hd4_gdm icd_hd_gdm

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate gdm_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace gdm_icd_nd`num' = 1 if substr(icd_nd`num',1,4) == "O244" | substr(icd_nd`num',1,4) == "O249"
		}
		
egen gdm_nd = rowmax(gdm_icd_nd1 - gdm_icd_nd89)
label var gdm_nd "=1, wenn GDM als Nebendiagnose"
drop gdm_icd_nd1 - gdm_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen gdm_icd = (gdm_hd == 1 | gdm_nd == 1)
label var gdm_icd "= 1, wenn GDM als Haupt- oder Nebendiagnose"

drop gdm_hd gdm_nd


/************************************************************************************************************************/
/*** o. Identify mothers with pre-existing diabetes  ***/

*** primary diagnosis
		foreach var of varlist icd_hd4 icd_hd {
			generate `var'_dm = 0
		}

		foreach var of varlist icd_hd4 icd_hd {
			qui replace `var'_dm = 1 if substr(`var',1,4) == "O240" | substr(`var',1,4) == "O241" | substr(`var',1,4) == "O242" | substr(`var',1,4) == "O243"
		}

egen dm_hd = rowmax(icd_hd4_dm icd_hd_dm)
label var dm_hd "=1, wenn vorheriger Diabetes als Hauptdiagnose"

drop  icd_hd4_dm icd_hd_dm

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate dm_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace dm_icd_nd`num' = 1 if substr(icd_nd`num',1,4) == "O240" | substr(icd_nd`num',1,4) == "O241" | substr(icd_nd`num',1,4) == "O242" | substr(icd_nd`num',1,4) == "O243"
		}
		
egen dm_nd = rowmax(dm_icd_nd1 - dm_icd_nd89)
label var dm_nd "=1, wenn vorheriger Diabetes als Nebendiagnose"
drop dm_icd_nd1 - dm_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen dm_icd = (dm_hd == 1 | dm_nd == 1)
label var dm_icd "= 1, vorheriger Diabetes als Haupt- oder Nebendiagnose"

drop dm_hd dm_nd


/************************************************************************************************************************/
/*** p. multiple children  ***/

*** primary diagnosis
		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			generate `var'_mehrling = 0
		}

		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			qui replace `var'_mehrling = 1 if substr(`var',1,3) == "O30" 
		}

egen mehrling_hd = rowmax(icd_hd3_mehrling icd_hd4_mehrling icd_hd_mehrling)
label var mehrling_hd "=1, wenn Mehrlingsschwangerschaft als Hauptdiagnose"

drop  icd_hd3_mehrling icd_hd4_mehrling icd_hd_mehrling

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate mehrling_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace mehrling_icd_nd`num' = 1 if substr(icd_nd`num',1,3) == "O30" 
		}
		
egen mehrling_nd = rowmax(mehrling_icd_nd1 - mehrling_icd_nd89)
label var mehrling_nd "=1, wenn Mehrlingsschwangerschaft als Nebendiagnose"
drop mehrling_icd_nd1 - mehrling_icd_nd89


*** Dummy, if primary or secondary diagnosis 
gen mehrling_icd = (mehrling_hd == 1 | mehrling_nd == 1)
label var mehrling_icd "= 1, wenn Mehrlingsschwangerschaft als Haupt- oder Nebendiagnose"

drop mehrling_hd mehrling_nd



/********************************************************************************************************************/
/*** q. Labor induction  													  	  				  ***/

*** Labor induction based on OPS code
		foreach var of varlist ops_ko1 - ops_ko101 {
			generate wehen_`var' = 0
		}

		foreach num of numlist 1(1)101 {
			qui replace wehen_ops_ko`num' = 1 if 	substr(ops_ko`num',1,4) == "5730" | ///
												substr(ops_ko`num',1,4) == "5731" 
		}
		
egen wehen_ops = rowmax(wehen_ops_ko1 - wehen_ops_ko101)
label var wehen_ops "=1, wenn Weheneinleitung als OPS Code"
drop wehen_ops_ko1 - wehen_ops_ko101


*** Labor induction as primary diagnosis (ICD)
		foreach var of varlist icd_hd4 icd_hd {
			generate `var'_wehen = 0
		}

		foreach var of varlist icd_hd4 icd_hd {
			qui replace `var'_wehen = 1 if substr(`var',1,3) == "O61" 
		}

egen wehen_hd = rowmax(icd_hd4_wehen icd_hd_wehen)
label var wehen_hd "=1, wenn Wehen als Hauptdiagnose"

drop  icd_hd4_wehen icd_hd_wehen

*** Labor induction as secondary diagnosis (ICD)
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate wehen_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace wehen_icd_nd`num' = 1 if substr(icd_nd`num',1,3) == "O61" 
		}
		
egen wehen_nd = rowmax(wehen_icd_nd1 - wehen_icd_nd89)
label var wehen_nd "=1, wenn Wehen als Nebendiagnose"
drop wehen_icd_nd1 - wehen_icd_nd89


*** Dummy, if primary or secondary diagnosis (ICD)
gen wehen_icd = (wehen_hd == 1 | wehen_nd == 1)
label var wehen_icd "= 1, wenn Weheneinleitung als Haupt- oder Nebendiagnose (ICD)"

drop wehen_hd wehen_nd

egen wehen_final = rowmax(wehen_ops wehen_icd)



/********************************************************************************************************************/
/*** r. Count procedures and diagnoses													  	  				  ***/

*** Number of procedures (overall)
		foreach var of varlist ops_ko1 - ops_ko101 {
			qui generate prozedur_`var' = !missing(trim(`var'))
		}

		egen prozedur_all_total = rowtotal(prozedur_ops_ko1 - prozedur_ops_ko101)
		label var prozedur_all_total "Prozeduren (gesamt)"

		drop prozedur_ops_ko1 - prozedur_ops_ko101
		
/*** Number of procedures (geburtsbezogen)
		foreach var of varlist ops_ko1 - ops_ko101 {
			generate prozedur_`var' = 0
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
		label var prozedur_preg_total "Geburtsprozeduren (total)"
		drop prozedur_ops_ko1 - prozedur_ops_ko101
*/
		
*** Number of diagnoses (overall)
		foreach var of varlist icd_hd icd_nd1-icd_nd89 {
			qui generate diagnose_`var' = !missing(trim(`var'))
		}

		egen diagnose_all_total = rowtotal(diagnose_icd_hd - diagnose_icd_nd89)
		label var diagnose_all_total "Diagnosen (gesamt)"

		drop diagnose_icd_hd - diagnose_icd_nd89
		
/*** Number of diagnoses (geburtsbezogen)
		foreach var of varlist icd_hd icd_nd1-icd_nd89 {
			qui generate diagnose_`var' = 0
		}

		
		foreach var of varlist icd_hd icd_nd1-icd_nd89 {
			qui replace diagnose_`var' = 1 if 		substr(`var',1,1) == "P" | ///
													substr(`var',1,1) == "O" 
												
		}		
		
		egen diagnose_preg_total = rowtotal(diagnose_icd_hd - diagnose_icd_nd89)
		label var diagnose_preg_total "Geburtsprozeduren (total)"
		
		drop diagnose_icd_hd - diagnose_icd_nd89
*/
		
		
*** Number of procedures + Diagnosen (overall)
		

		egen proz_diag_all = rowtotal(prozedur_all_total diagnose_all_total)
		label var proz_diag_all "Gesamtzahl an Prozeduren + Diagnosen"
		
		*egen proz_diag_preg = rowtotal(prozedur_preg_total diagnose_preg_total)
		*label var proz_diag_preg "Gesamtzahl an Prozeduren + Diagnosen (SW + Geburt)"	



/************************************************************************************************************************/
/*** s. Identify a mother with preeclampsia ***/

*** primary diagnosis
		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			generate `var'_präeklamp = 0
		}

		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			qui replace `var'_präeklamp = 1 if substr(`var',1,3) == "O14" 
		}

egen präeklamp_hd = rowmax(icd_hd3_präeklamp icd_hd4_präeklamp icd_hd_präeklamp)
label var präeklamp_hd "=1, wenn Präeklampsie als Hauptdiagnose"

drop  icd_hd3_präeklamp icd_hd4_präeklamp icd_hd_präeklamp

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate präeklamp_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace präeklamp_icd_nd`num' = 1 if substr(icd_nd`num',1,4) == "O140" | substr(icd_nd`num',1,4) == "O141" | substr(icd_nd`num',1,4) == "O142" | substr(icd_nd`num',1,4) == "O149"
		}
		
egen präeklamp_nd = rowmax(präeklamp_icd_nd1 - präeklamp_icd_nd89)
label var präeklamp_nd "=1, wenn Präeklampsie als Nebendiagnose"
drop präeklamp_icd_nd1 - präeklamp_icd_nd89


*** Dummy, if primary or secondary diagnosis
gen präeklamp_icd = (präeklamp_hd == 1 | präeklamp_nd == 1)
label var präeklamp_icd "= 1, Präeklampsie als Haupt- oder Nebendiagnose"

drop präeklamp_hd präeklamp_nd


/************************************************************************************************************************/
/*** t. Identify a mother with any form of hypertension ***/

*** primary diagnosis
		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			generate `var'_hyper = 0
		}

		foreach var of varlist icd_hd3 icd_hd4 icd_hd {
			qui replace `var'_hyper = 1 if substr(`var',1,3) == "O10" | substr(`var',1,3) == "O11" | substr(`var',1,3) == "O12" | substr(`var',1,3) == "O13" | substr(`var',1,3) == "O14" | substr(`var',1,3) == "O15" | substr(`var',1,3) == "O16"
		}

egen hyper_hd = rowmax(icd_hd3_hyper icd_hd4_hyper icd_hd_hyper)
label var hyper_hd "=1, wenn Hypertonie als Hauptdiagnose"

drop  icd_hd3_hyper icd_hd4_hyper icd_hd_hyper

*** secondary diagnosis
		foreach var of varlist icd_nd1 - icd_nd89 {
			generate hyper_`var' = 0
		}

		foreach num of numlist 1/89 {
			qui replace hyper_icd_nd`num' = 1 if substr(icd_nd`num',1,3) == "O10" | substr(icd_nd`num',1,3) == "O11" | substr(icd_nd`num',1,3) == "O12" | substr(icd_nd`num',1,3) == "O13" | substr(icd_nd`num',1,3) == "O14" | substr(icd_nd`num',1,3) == "O15" | substr(icd_nd`num',1,3) == "O16" 
		}
		
egen hyper_nd = rowmax(hyper_icd_nd1 - hyper_icd_nd89)
label var hyper_nd "=1, wenn Hypertonie als Nebendiagnose"
drop hyper_icd_nd1 - hyper_icd_nd89


*** Dummy, if primary or secondary diagnosis
gen hyper_icd = (hyper_hd == 1 | hyper_nd == 1)
label var hyper_icd "= 1, Hypertonie als Haupt- oder Nebendiagnose"

drop hyper_hd hyper_nd
		
		
/********************************************************************************************************************/
/*** u. Number of diagnoses in certain ICD-categories													  	  				  ***/		
		
gen anzahl_O = 0		
gen anzahl_P = 0		
gen anzahl_Z = 0				
		
*** Number of diagnoses (overall)
		foreach var of varlist icd_hd icd_nd1-icd_nd89 {
			qui replace anzahl_O = anzahl_O + (upper(substr(trim(`var'),1,1)) == "O")  
			qui replace anzahl_P = anzahl_P + (upper(substr(trim(`var'),1,1)) == "P")  
			qui replace anzahl_Z = anzahl_Z + (upper(substr(trim(`var'),1,1)) == "Z")  		
		}

label var anzahl_O "Anzahl der Diagnosen mit ICD-Code O"		
label var anzahl_P "Anzahl der Diagnosen mit ICD-Code P"
label var anzahl_Z "Anzahl der Diagnosen mit ICD-Code Z"				
			
		
		
		
/********************************************************************************************************************/
/*** v. Harmonize hospital and patient region types 						  ***/


** Hospital 2008-2010
destring kh_typ_gem, replace
recode kh_typ_gem (1/8 = 1) (9/13=2) (14/17=3), gen(kh_typ_gem_neu)
tab kh_typ_gem_neu

** Hospital from 2011
destring kh_typ_gem3, replace
tab kh_typ_gem3

** Hospital harmonized
clonevar kh_typ_gem_reg = kh_typ_gem_neu
qui replace kh_typ_gem_reg = kh_typ_gem3 if kh_typ_gem_reg == .
label def kh_typ_gem_reg 1 "Städtische Region" 2 "Verstädterte Räume" 3 "Ländliche Region"
label val kh_typ_gem_reg kh_typ_gem_reg  
label var kh_typ_gem_reg "Gebietstyp KKH"
tab kh_typ_gem_reg, gen(kh_typ_gem_reg_)			// Dummy


** Patient 2008-2010
qui replace pat_typ_gem = "18" if pat_typ_gem == "oh" | pat_typ_gem == "un" | pat_typ_gem == "au" | pat_typ_gem == ""
destring pat_typ_gem, replace
recode pat_typ_gem (1/8 = 1) (9/13=2) (14/17=3) (18=4), gen(pat_typ_gem_neu)
qui replace pat_typ_gem_neu = kh_typ_gem_reg if pat_typ_gem_neu == 4 

** Patient from 2011
destring pat_typ_gem3, replace

** Patient harmonized
clonevar pat_typ_gem_reg = pat_typ_gem_neu
qui replace pat_typ_gem_reg = pat_typ_gem3 if pat_typ_gem_reg == .
label def pat_typ_gem_reg 1 "Städtische Region" 2 "Verstädterte Räume" 3 "Ländliche Region"
label val pat_typ_gem_reg pat_typ_gem_reg  
label var pat_typ_gem_reg "Gebietstyp Patient"
tab pat_typ_gem_reg, gen(pat_typ_gem_reg_)			// Dummy


/********************************************************************************************************************/
/*** w. Economic outcomes					  																***/

gen erloes = BwrlVol 
qui replace erloes = cm_vol if erloes == .
gen ln_erloes = ln(erloes)

gen ln_tage = ln(tage)


label var erloes "Erlösvolumen"
label var ln_erloes "Erlösvolumen (logarithmiert)"
label var tage "Verweildauer"
label var ln_tage "Verweildauer (logarithmiert)"



/********************************************************************************************************************/
/*** x. Bundesland of the patient aufbereiten																	  ***/
clonevar pat_bula = pat_land
*If state of residence of patient invalid, replaced with federal state of the hospital ersetzt 
qui replace pat_bula = kh_land if inlist(pat_bula,"oh","un")								
destring pat_bula, replace

tab pat_bula, gen(pat_bula_)



/********************************************************************************************************************/
/*** y. Age quadratic																						  ***/
gen alter2 = alter*alter		



/********************************************************************************************************************/
/*** z.	Save prepared dataset containing all deliveries  							  	  ***/
save "$data_prep\drg_08bis14_pregnant_prep.dta", replace

********************************************************************************************************************/
/*** za.	Sample restrictions							  	  								  					  ***/
keep if inrange(aufn_jahr,2008,2013)					// birth from 2008 to 2013
drop if inlist(pat_land,"au")	// Drop patients residing abroad -> no eligibility for GDM screening in Germany
keep if inrange(alter,14,50) // Age restriction
keep if inlist(aufn_grd,5,6)  // Admission reason relating to birth/delivery 

save "$data_prep\drg_08bis14_pregnant_sample_deskr.dta", replace // full Sample (including all quarters)


preserve
keep if inlist(quarter,3,4)
save "$data_prep\drg_08bis14_pregnant_sample_reg.dta", replace // sample with restrictions to birth quarters 3 and 4 (for analysis) 
restore


cap log close




