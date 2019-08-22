* For Ghana TiSeed aquaculture survey
* Data cleaning and dscriptive/summary tables
****************************OPTIONS******************************
clear
#delimit ; 
set more off; capture log close; clear matrix; set matsize 2000;
label drop _all; 
#delimit cr 
*****************************************************************.
global root	     		"C:\Users\\CRAGASA\Dropbox (IFPRI)\Catherine\Aquaculture\July17"
global inputs    		"$root\survey_july17"
global intermediate		"$root\checks\intermediate"
global clean    		"$root\checks"
global hfc				"$root\hfc_check\05_data\02_survey"
global tables			"$root\tables"
global regressions		"$root\regressions"
global temp				"$root\temp"

****************************************************************

use "$clean\00_HOUSEHOLD_main_hfc_check.dta", clear

*pond cage pondcage
gen culture=1 if nc==2| pb_1_i==2
replace culture=2 if pb_1_i==1| nc==1
replace culture=3 if pb_1_i==3| nc==3
lab def culture 1"Pond" 2"Cage" 3"Pond&cage" 
lab val culture culture
lab var culture "Culture"  

*active inactive
gen active=1 if a01!=4
replace active=0 if active==.


*distance
tab b2 b2i
gen distance=b2 if b2i==1
replace distance=0 if b2==0
replace distance=b2/1.60934 if b2i==2 
replace distance=b2/1000 if b2i==3
replace distance=b2/15 if b2i==5 
*15 min walk=1km 
*check 38 obs with 999
*check 1 obs with 500 km and 600 km,  too high
*84% of farms are within 2 km (30 minutes walk) to the respondent's house


table culture active, by(region)
*check that there is 1 cage&pond in Ashanti

*specie in cages
split c1, destring

*specie in biggest pond
split c12a, destring

*specie in smallest pond
split c13a, destring

*checked why there is 777 in fish specie
*one is tilapia and catfish, so I adjusted, but one says "not stocked yet"
gen tilapia=1 if c11==1|c12==1|c12a1==1|c12a2==1|c13a1==1|c13a2==1|c13a3==1|c12ai=="Tilapia and catfish"
replace tilapia=0 if tilapia==.

gen catfish=1 if c11==2|c12==2|c12a1==2|c12a2==2|c13a1==2|c13a2==2|c13a3==2|c12ai=="Tilapia and catfish"
replace catfish=0 if catfish==.

gen tilapiacatfish=1 if tilapia==1&catfish==1
replace tilapiacatfish=0 if tilapiacatfish==.
*check why 217 obs do not have tilapia when we were supposed to interview only tilapia farmers

use "$clean\04_POND_characteristics_hfc_check.dta", clear 
tab c9
tab c9i
split c9, destring
gen tilapallpond=1 if c91==1|c92==1|c93==1|c9i=="Tilapia and Catfight"|c9i=="Tilapia and catfish"
*there are 17 obs with 777,  13 of them are tilapia and catfish so they are already adjusted
collapse (max) tilapallpond, by(HHID)

save "$temp\tilapiaallponds.dta", replace  

use "$clean\00_HOUSEHOLD_main_hfc_check.dta", clear
merge 1:1 HHID using "$temp\tilapiaallponds.dta"
