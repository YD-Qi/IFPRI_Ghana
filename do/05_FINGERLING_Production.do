* adapted from Andrew Comstock, IFPRI-DC
****************************OPTIONS******************************
clear
#delimit ; 
set more off; capture log close; clear matrix;
label drop _all; 
#delimit cr 
*****************************************************************.
global root	     		"C:\Users\MKEDIRJEMAL\Dropbox (IFPRI)\Catherine\Aquaculture\July17"
global inputs     		"$root\survey_july17"
global intermediate		"$root\checks\intermediate"
global outputs    		"$root\checks"
global hfc				"$root\hfc_check\05_data\02_survey"

****************************************************************
*Fingerling production cost
****************************************************************
**hatchery/fingeling production Fixed cost fingerling
use "$inputs\aquaculture household survey-Module_I-Active_farmer-Section_C-Finger-TableCc" , clear
merge m:m setoftablecc using "$outputs\00_HOUSEHOLD_main_hfc_check.dta" , keepusing (HHID a6 a1 a2 a3 b3 b4 b6  c16 hatchery_fixedcost_intro hatchery_unit submissiondate)
keep if _merge==3
drop _merge

gen fingerLing_prdn_numb=.
replace fingerLing_prdn_numb=c21a * (c27 / 100) 		if c27i ==2
replace fingerLing_prdn_numb=c27  						if c27i ==1

save "$outputs\06_FINGERLING_production_hfc_check", replace
save "$hfc\06_FINGERLING_production_hfc_check", replace


**Fingerling: fixed cost

use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Hatchery-F25_F30-F26a_F30a", clear
merge m:m setoff26a_f30a using "$outputs\00_HOUSEHOLD_main_hfc_check.dta" , keepusing (HHID a6 a1 a2 a3 b3 b4 b6  c16 hatchery_fixedcost_intro hatchery_unit submissiondate)
keep if _merge==3
drop _merge


destring f29ai, 		replace
gen hatchery_fxd_cost=	f28a / (f30a * 2) 				if f29a==1  //Must be multiplied by tot number of hatchery per cycle 
replace hatchery_fxd_cost=	f28a / (f30a * 2) 				if f29a==2	//per cycle 
replace hatchery_fxd_cost=	f28a / (f30a * 2) 				if f29a==3
*replace hatchery_fxd_cost=	(f28a * f29ai)/ (f30a * 2) 		if f29ai !=.

order HHID a6 a1 a2 a3
order parent_key key setoff26a_f30a, last 
order hatchery_fxd_cost, after(f30)

preserve
collapse (sum) hatchery_fxd_cost if f28a !=., by (HHID a6 a1 a2 a3 b3 b4)
save "$intermediate\06_FINGERLING_fixed_cost_by_type", replace
restore

save "$outputs\06_FINGERLING_fixed_cost_hfc_check", replace
save "$hfc\06_FINGERLING_fixed_cost_hfc_check", replace


**Fingerling variable cost     **hatchery---variable cost

use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Hatchery-F32_F35.dta", clear
merge m:m setoff32_f35 using "$outputs\00_HOUSEHOLD_main_hfc_check.dta" , keepusing (HHID a6 a1 a2 a3 b3 b4 b6  c16 e49 hatchery_fixedcost_intro hatchery_unit submissiondate)
keep if _merge==3
drop _merge

gen hatcheryVar_cost_cyl=ht_quantity * ht_cost
label var hatcheryVar_cost_cyl "Hatchery variable/ running cost" 

order HHID a6 a1 a2 a3
order parent_key key setoff32_f35, last 
order hatcheryVar_cost_cyl, after(ht_cost)

preserve 
collapse (sum) hatcheryVar_cost_cyl if ht_quantity !=., by(HHID a6 a1 a2 a3 b3 hatcheryvc_name ht_unit)
save  "$intermediate\06_FINGERLING_varcost_cost_by_type.dta", replace
restore 

save "$outputs\06_FINGERLING_variable_cost_hfc_check", replace
save "$hfc\06_FINGERLING_variable_cost_hfc_check", replace

























