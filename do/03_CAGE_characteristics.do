/* For aquaculture survey
****************************OPTIONS******************************
clear
#delimit ; 
set more off; capture log close; clear matrix;
label drop _all; 
#delimit cr 
*****************************************************************.
global root	     		"C:\Users\MKEDIRJEMAL\Dropbox (IFPRI)\Catherine\Aquaculture\June17"
global inputs     		"$root\survey_june17"
global intermediate		"$root\checks\intermediate"
global outputs    		"$root\checks"
global hfc				"$root\hfc_check\05_data\02_survey"

****************************************************************
*CAGE characteristics-cage culture
****************************************************************
**stocking desnity=number of fingerlings per m3 (range 40-100) or number of fingerlings/m2(range 10-30)
use "$outputs\00_HOUSEHOLD_main_hfc_check.dta" ,clear
keep HHID a6 enumerator_n enumerator_n a1 a2 a3 b3 b4 b6 e49 c1 c* e36a submissiondate setofsel_speciecage 
merge m:m setofsel_speciecage using "$inputs\aquaculture household survey-Module_I-Active_farmer-Section_C-Cageculture-sel_specieCage"
keep if _merge==3 
drop _merge

**replace production if reported 999
mvdecode c4b c4bi c5c c5a c5d, mv(999 = .) 
mvdecode c4b c4bi c5c c5a c5d, mv(666 = .) 

*check number of cage
order   HHID a6 enumerator_n enumerator_n c1 c1_name c1_id  c1 c2
order 	parent_key, last
destring c1_id, replace 

***To calculate production rate 1. use size and production of the most common cage used on the last full cycle production.
***2. use total harvested by total number of cages used in the last full produciton (prnd per cage)
***most common cages (volume, staocking and production)
gen comcag_dim=cage_size_name1
replace comcag_dim = subinstr(comcag_dim, "X", "x",.) 
replace comcag_dim = subinstr(comcag_dim, " x ", "x",.) 
gen dimenCircular=comcag_dim  if substr(comcag_dim,1,8)=="Circular" //will return the first 4 digits
replace comcag_dim ="" if substr(comcag_dim,1,8)=="Circular" 
gen diameterCircl_num = regexs(2) if regexm(dimenCircular, "^([^0-9]*)([0-9]+)([^0-9]*)$") 
destring diameterCircl_num, replace

split comcag_dim, parse("x")  destring //
gen cageMostComnV=(comcag_dim1 * comcag_dim2 * comcag_dim3)
drop comcag_dim dimenCircular comcag_dim1 comcag_dim2 comcag_dim3

replace cageMostComnV=. if diameterCircl_num!=.
*replace cageMostComnV=_pi*(0.5 * dimenCircular_num)^2*(0.5 * dimenCircular_num) if dimenCircular_num!=.
*order cageMostComnV, after (c4a)

*label define dimension 1 "5x5x5(125m^3)" 2 "6x6x6(216m^3)" 3 "7x7x7(343m^3)" 4 "10x10x10(1000m^3)" 5 "Other-check next column"
*label values c41 dimension
*replace c41=. if num_c4 !=1
***most common cages (volume, staocking and production)
/*
cap gen cageMostComnV=.
cap replace cageMostComnV=5*5*5 if c4a==1 
cap replace cageMostComnV=6*6*6 if c4a==2
cap replace cageMostComnV=7*7*7 if c4a==3
cap replace cageMostComnV=10*10*10 if c4a==4

cap replace cageMostComnV=5*5*5 	if (c4a==. & num_c4==1 & c41==1)
cap replace cageMostComnV=6*6*6 	if (c4a==. & num_c4==1 & c41==2)
cap replace cageMostComnV=7*7*7 	if (c4a==. & num_c4==1 & c41==3)
cap replace cageMostComnV=10*10*10 	if (c4a==. & num_c4==1 & c41==4)
*/
label var cageMostComnV "Volume of most common cage used during the last full production cycle"

***stocking rate on most common size
gen stockingMostComnCage=c4b/cageMostComnV
cap gen stockingMostComnCage_error=(stockingMostComnCage < 40 | stockingMostComnCage > 100)
cap label var stockingMostComnCage_error "Check if stocking rate out of a presumed average range (40-100)"

***production rate on most common cage size used
**gen harvestUnit_error=(c5a > 100) //asuming production is under 100 tonne per farmer

gen c5a_unit_kg=c5a*1000 if c5a<100
replace c5a_unit_kg = c5a if c5a>=100
label var c5a_unit_kg "Production per cage--convert tonne to kg---kept the above 100 as kg"

gen cagePrdnRateMostComn=.
label var cagePrdnRateMostComn "Production on the most common cage used in the last full production cycle"
cap replace cagePrdnRateMostComn=c5a_unit_kg / cageMostComnV  if cageMostComnV !=.
cap gen cagePrdnRateMostComn_error=(cagePrdnRateMostComn < 15 | cagePrdnRateMostComn > 25)
cap label var cagePrdnRateMostComn_error "Report error if stocking rate out of presumed average range (15-25)"


**total production/harvest from ALL cages used during the last full production cycle 
gen totharvestUnit_error=(c5d > 100) //assuming production is under 100 tonne per farmer
label var totharvestUnit_error "Report error if total production exceeds 100 tonne per cycle"
gen c5d_unit_kg=c5d*1000 if c5d<100
replace c5d_unit_kg = c5d if c5d>=100
label var c5d_unit_kg "Tot production--convert tonne to kg---kept the above 100 as kg"

**average cage production rate (kg/m^3)---total harvested production by total cage volume used during the last full prodn cycle
gen Prdn_per_Cage=c5d_unit_kg/c3 if c3>0
label var Prdn_per_Cage "Average production per cage (kg/cage)"

gen avgProdn_cage=Prdn_per_Cage/cageMostComnV if cageMostComnV !=.
lab var avgProdn_cage "Average production (average prodn per cage by most common size)"

gen totcageProdn_error= (avgProdn_cage < 15 | avgProdn_cage > 25)
label var totcageProdn_error "Report error if per cage prodn is out of 15-25 kg/m^3 range"

***check prodn consistency [compare total and single cage prdn] 
gen prodnConsistency_error= (c5d_unit_kg < c5a_unit_kg)
label var  prodnConsistency_error "Check if tot prodn is less than single cage prodn" 


preserve
collapse (mean) c3, by(HHID)
save "$intermediate\03_CAGE_number_of_cages_lastFull_prdn.dta", replace
restore

save "$outputs\03_CAGE_Characteristics_hfc_check.dta", replace
save "$hfc\03_CAGE_Characteristics_hfc_check", replace
*/
* For aquaculture survey
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
*CAGE characteristics-cage culture
****************************************************************
**stocking desnity=number of fingerlings per m3 (range 40-100) or number of fingerlings/m2(range 10-30)
use "$inputs\aquaculture household survey-Module_I-Active_farmer-Section_C-Cageculture-sel_specieCage", clear
keep if c4 !=""

**replace production if reported 999
mvdecode c4a c4b c4bi c5a c4d c4di c5c c5cii c5d, mv(999 = .) 
mvdecode c4a c4b c4bi c5a c4d c4di c5c c5cii c5d, mv(666 = .) 

merge m:m setofsel_speciecage  using "$outputs\00_HOUSEHOLD_main_hfc_check.dta"
keep if _merge==3 
drop _merge

order HHID a6 enumerator_n b3 a01 c1 c1_name c1_id c2 c3 c4 c4a cage_size_name1 c4b c4bi c4bi_i c5a c5b c5bi c5d 
order 	parent_key, last

***To calculate production rate 1. use size and production of the most common cage used on the last full cycle production.
***2. use total harvested by total number of cages used in the last full produciton (prnd per cage)
***most common cages (volume, staocking and production)
gen comcag_dim=cage_size_name1
cap replace comcag_dim = subinstr(comcag_dim, "X", "x",.) 
replace comcag_dim = subinstr(comcag_dim, " x ", "x",.) 
cap replace comcag_dim = subinstr(comcag_dim, "×", "x",.) 
cap gen dimenCircular=comcag_dim  if substr(comcag_dim,1,8)=="Circular" //will return the first 4 digits
cap replace comcag_dim ="" if substr(comcag_dim,1,8)=="Circular" 
cap gen diameterCircl_num = regexs(2) if regexm(dimenCircular, "^([^0-9]*)([0-9]+)([^0-9]*)$") 
destring diameterCircl_num, replace

cap gen dimenCubic=comcag_dim  if substr(comcag_dim,6,5)=="cubic" //will return the first 4 digits 1500 cubic metres
cap replace comcag_dim ="" if substr(comcag_dim,6,5)=="cubic" 
cap gen dimenCubic_num = regexs(2) if regexm(dimenCubic, "^([^0-9]*)([0-9]+)([^0-9]*)$") 
destring dimenCubic_num, replace



split comcag_dim, parse("x")  destring //
gen cageMostComnV=(comcag_dim1 * comcag_dim2 * comcag_dim3)
cap drop comcag_dim dimenCircular dimenCubic comcag_dim1 comcag_dim2 comcag_dim3 

replace cageMostComnV=. if diameterCircl_num!=.
replace cageMostComnV=dimenCubic_num if dimenCubic_num!=.

*replace cageMostComnV=_pi*(0.5 * dimenCircular_num)^2*(0.5 * dimenCircular_num) if dimenCircular_num!=.
*order cageMostComnV, after (c4a)

*label define dimension 1 "5x5x5(125m^3)" 2 "6x6x6(216m^3)" 3 "7x7x7(343m^3)" 4 "10x10x10(1000m^3)" 5 "Other-check next column"
*label values c41 dimension
*replace c41=. if num_c4 !=1
***most common cages (volume, staocking and production)
/*
cap gen cageMostComnV=.
cap replace cageMostComnV=5*5*5 if c4a==1 
cap replace cageMostComnV=6*6*6 if c4a==2
cap replace cageMostComnV=7*7*7 if c4a==3
cap replace cageMostComnV=10*10*10 if c4a==4

cap replace cageMostComnV=5*5*5 	if (c4a==. & num_c4==1 & c41==1)
cap replace cageMostComnV=6*6*6 	if (c4a==. & num_c4==1 & c41==2)
cap replace cageMostComnV=7*7*7 	if (c4a==. & num_c4==1 & c41==3)
cap replace cageMostComnV=10*10*10 	if (c4a==. & num_c4==1 & c41==4)
*/
label var cageMostComnV "Volume of most common cage used during the last full production cycle"
order cageMostComnV, after (c4a)

***stocking rate on most common size
gen stockingMostComnCage=c4b/cageMostComnV
cap gen stockingMostComnCage_error=(stockingMostComnCage < 40 | stockingMostComnCage > 100)
cap label var stockingMostComnCage_error "Check if stocking rate out of a presumed average range (40-100)"

***production rate on most common cage size used
**gen harvestUnit_error=(c5a > 100) //asuming production is under 100 tonne per farmer

gen c5a_unit_kg=c5a*1000 if c5a<100
replace c5a_unit_kg = c5a if c5a>=100
label var c5a_unit_kg "Production per cage--convert tonne to kg---kept the above 100 as kg"

gen cagePrdnRateMostComn=.
label var cagePrdnRateMostComn "Production on the most common cage used in the last full production cycle"
cap replace cagePrdnRateMostComn=c5a_unit_kg / cageMostComnV  if cageMostComnV !=.
cap gen cagePrdnRateMostComn_error=(cagePrdnRateMostComn < 15 | cagePrdnRateMostComn > 25)
cap label var cagePrdnRateMostComn_error "Report error if stocking rate out of presumed average range (15-25)"


**total production/harvest from ALL cages used during the last full production cycle 
gen totharvestUnit_error=(c5d > 100) //assuming production is under 100 tonne per farmer
label var totharvestUnit_error "Report error if total production exceeds 100 tonne per cycle"
gen c5d_unit_kg=c5d*1000 if c5d<100
replace c5d_unit_kg = c5d if c5d>=100
label var c5d_unit_kg "Tot production--convert tonne to kg---kept the above 100 as kg"

**average cage production rate (kg/m^3)---total harvested production by total cage volume used during the last full prodn cycle
gen Prdn_per_Cage=c5d_unit_kg/c3 if c3>0
label var Prdn_per_Cage "Average production per cage (kg/cage)"

gen avgProdn_cage=Prdn_per_Cage/cageMostComnV if cageMostComnV !=.
lab var avgProdn_cage "Average production (average prodn per cage by most common size)"

gen totcageProdn_error= (avgProdn_cage < 15 | avgProdn_cage > 25)
label var totcageProdn_error "Report error if per cage prodn is out of 15-25 kg/m^3 range"

***check prodn consistency [compare total and single cage prdn] 
gen prodnConsistency_error= (c5d_unit_kg < c5a_unit_kg)
label var  prodnConsistency_error "Check if tot prodn is less than single cage prodn" 

order stockingMostComnCage - prodnConsistency_error, after (c5d)

keep if a01==1   //active farmer


**create a production bounda limit based on max and min size fingerling can grow using stocking and survival rate
**a fingerling can grow a maximum of 1 kg and minimum of 100 gram (0.1kg)
gen PerCageMaxBound_prdn_ton=.
replace PerCageMaxBound_prdn_ton= (1 * c4bi) / 1000			 			if c4bi_i==1   //max size of 1kg * # of fingerling survived
replace PerCageMaxBound_prdn_ton= (1 * c4b * (c4bi /100)) / 1000		if c4bi_i==2   //max size of 1kg * stoking rate * % fingerling survived

gen PerCageMinBound_prdn_ton=.
replace PerCageMinBound_prdn_ton= (0.1 * c4bi )	/ 1000		 			if c4bi_i==1   //max size of 0.1kg * # of fingerling survived
replace PerCageMinBound_prdn_ton= (0.1 * c4b * (c4bi /100)) / 1000	 	if c4bi_i==2   //max size of 1kg * stoking rate * % fingerling survived

label var PerCageMaxBound_prdn_ton "Expected max per cage production at 1kg max growth limit of fingerlings stocked in metric ton"
label var PerCageMinBound_prdn_ton "Expected min per cage production at 0.1kg min growth limit of fingerlings stocked in metric ton"


gen totCageMaxBound_prdn_ton=.
replace totCageMaxBound_prdn_ton= (1 * c4bi * c3)/ 1000		 				if c4bi_i==1   //max size of 1kg * # of fingerling survived * tot number of cages used
replace totCageMaxBound_prdn_ton= (1 * c4b * c3 * (c4bi /100)) / 1000		if c4bi_i==2   //max size of 1kg * stoking rate * % fingerling survived * tot number of cages used

gen totCageMinBound_prdn_ton=.
replace totCageMinBound_prdn_ton= (0.1 * c4bi * c3 ) / 1000		 			if c4bi_i==1   //max size of 0.1kg * # of fingerling survived * tot number of cages used
replace totCageMinBound_prdn_ton= (0.1 * c4b * c3*  (c4bi /100)) / 1000		if c4bi_i==2   //max size of 1kg * stoking rate * % fingerling survived * tot number of cages used

label var totCageMaxBound_prdn_ton "Expected max production from total number of cages at 1kg min growth of fingerling stocked in metric ton"
label var totCageMinBound_prdn_ton "Expected min production from total number of cages at 0.1kg min growth of fingerling stocked in metric ton"

order PerCageMaxBound_prdn_ton - totCageMinBound_prdn_ton, after (c5d)

save "$outputs\03_CAGE_Characteristics_hfc_check.dta", replace
save "$hfc\03_CAGE_Characteristics_hfc_check", replace



**fixed cost-CAGE [average out the duration to one full cycle~6 month. Divide the year in to half]
****land and building cost
use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Cage-F1_F7-F2a_F7a", clear
merge m:m parent_key using "$outputs\03_CAGE_Characteristics_hfc_check.dta", keepusing (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 a6 c2 c3 c4 c4a cage_size_name1 e49 cageMostComnV submissiondate)
keep if _merge==3
*drop if _merge==2
drop _merge


mvdecode f4a, mv(999 = .) 
sort HHID
drop if (f4a ==. &  f5a  ==. & f6a  ==. )
gen landBuil_cost_cycl=f4a/(c3 * f6a * 2) if (f4a!=. | f5a!=1) 
label var landBuil_cost_cycl "Average fixed land and building cost per prdn cycle per cage "

gen landBuil_cost_m3=landBuil_cost_cycl/cageMostComnV
label var landBuil_cost_m3 "Average fixed land and building cost per m^3"

*drop if (f4a==. & f5a==.)
*collapse (sum) landBuil_cost_cycl landBuil_cost_m3, by (parent_key)
save "$outputs\03_CAGE_land_building_cost.dta", replace 
save "$hfc\03_CAGE_land_building_cost", replace

*****
****gear and other cost
use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Cage-F1_F7-F2b_F7b", clear
merge m:m parent_key using "$outputs\03_CAGE_Characteristics_hfc_check.dta", keepusing (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 a6 c2 c3 e49 cageMostComnV submissiondate)
keep if  _merge==3
drop _merge

mvdecode f4b , mv(999 = .) 
gen  gear_cost_cycl=f4b/(c3 * f6b * 2) if (f4b!=. | f5b!=1)
label var gear_cost_cycl "Average fixed gear and other cost per prdn cycle per cage "

gen gear_cost_m3=gear_cost_cycl/cageMostComnV
label var gear_cost_m3 "Average fixed gear and other cost per m^3"

drop if (f4b==. & f5b==.)
*collapse (sum) gear_cost_cycl gear_cost_m3, by (parent_key)
save "$outputs\03_CAGE_fishing_gear_cost.dta", replace 
save "$hfc\03_CAGE_fishing_gear_cost", replace

****equipment cost
use"$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Cage-F1_F7-F2c_F7c", clear
merge m:m parent_key using "$outputs\03_CAGE_Characteristics_hfc_check.dta", keepusing (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 a6 c2 c3 e49 cageMostComnV submissiondate)
keep if _merge==3
drop _merge

mvdecode f4c, mv(999 = .) 
gen  equipment_cost_cycl=f4c/(c3 * f6c * 2) if (f4c!=. | f5c!=1) 
label var equipment_cost_cycl "Average fixed equipment cost per prdn cycle per cage "


gen equipment_cost_m3=equipment_cost_cycl/cageMostComnV
label var equipment_cost_m3 "Average fixed equipment cost per m^3"

drop if (f4c==. & f5c==.)
*collapse (sum) equipment_cost_cycl equipment_cost_m3, by (parent_key)
save "$outputs\03_CAGE_equipment_cost_cost.dta", replace 
save "$hfc\03_CAGE_equipment_cost_cost", replace


***permit and evironment
use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Cage-F1_F7-F2d_F7d", clear
merge m:m parent_key using "$outputs\03_CAGE_Characteristics_hfc_check.dta", keepusing (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 a6 c2 c3 e49 cageMostComnV submissiondate)
keep if _merge==3
drop _merge

mvdecode f4d f4, mv(999 = .) 

gen  permit_cost_cycl=f4d/(c3 * f6d * 2) if (f4d!=. | f5d !=1) 
label var permit_cost_cycl "Average fixed permit and environemt cost per prdn cycle per cage "

gen permit_cost_m3=permit_cost_cycl/cageMostComnV
label var permit_cost_cycl "Average fixed permit and environemt cost per m^3"

drop if (f4d==. &f6d==.)
*collapse (sum) permit_cost_cycl permit_cost_m3, by (parent_key)

save "$outputs\03_CAGE_permit_cost_cost.dta", replace
save "$hfc\03_CAGE_permit_cost_cost", replace

****other cost
use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Cage-F1_F7-F2e_F7e", clear
merge m:m parent_key using "$outputs\03_CAGE_Characteristics_hfc_check.dta", keepusing (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 a6 c3 c4b c2 c3 e49  cageMostComnV submissiondate)
keep if _merge==3
drop _merge

mvdecode f4e f6e, mv(999 = .) 

gen  other_cost_cycl=f4e/(c3 * f6e * 2) if (f4e!=. | f5e!=1)
label var other_cost_cycl "Average fixed other cost per prdn cycle per cage"
 
gen other_cost_m3=other_cost_cycl/cageMostComnV
label var other_cost_m3 "Average fixed other cost per m^3"

drop if (f4e==. & f6e==.)
*collapse (sum) other_cost_cycl other_cost_m3, by (parent_key)
save "$outputs\03_CAGE_other_cost_cost.dta", replace
save "$hfc\03_CAGE_other_cost_cost", replace

**variable cost CAGE
use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Cage-F9_F12" , clear
merge m:m parent_key using "$outputs\03_CAGE_Characteristics_hfc_check.dta", keepusing (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 a6 c2 c3 c4b e12 e49 cageMostComnV submissiondate)
keep if _merge==3
drop _merge

mvdecode cg_quantity cg_cost, mv(999 = .) 
drop if cg_quantity==.


**total fingerling used in all operational cage used in the last full production cycle
**all last used cages times stocking rate of the most commong cages used
gen totFingerling=c3*c4b 
label var totFingerling "Total fingerling in cages all cages used during last full production season/cycle? 
order c4b totFingerling, after (c3)


/*gen unitVar_cost=.
replace unitVar_cost=f11 			if f10==1
replace unitVar_cost=f11*20			if f10==2
replace unitVar_cost=f11*50			if f10==3
replace unitVar_cost=f11	if f10==5
replace unitVar_cost=f11*3.78541	if f10==7
*/
gen allCageVarCost=cg_quantity*cg_cost
label var allCageVarCost "Itemized 1 full cycle variable cost for all cages"

gen PerCageVarCost=allCageVarCost/c3
label var PerCageVarCost "Itemized 1 full cycle total variable cost per cage"

gen CageVarCost_perm3=PerCageVarCost/cageMostComnV
label var CageVarCost_perm3 "Itemized 1 full cycle total variable cost per m3"

bys parent_key: egen totCageVarCost=sum(CageVarCost_perm3)
label var totCageVarCost "Total variable cost per household per m3"

*collapse (sum) CageVarCost, by ( cagevc_id cagevc_name parent_key c2 c3 cageMostComnV )
*label var  CageVarCost "Variable cost--cage"
*drop if (feed_purchased==999 | feed_purchased==0)
gen extraPay_ratio=.
replace extraPay_ratio=(e49 / cg_cost) if cg_unit==6
replace extraPay_ratio=e49 /(cg_cost / totFingerling) if cg_unit==5
label var extraPay_ratio "The ratio of willing to pay more on fingerling/broodstock" 

save "$outputs\03_CAGE_other_variable_cost.dta", replace
save "$hfc\03_CAGE_other_variable_cost", replace

***merge fixed costs
clear
use "$outputs\03_CAGE_land_building_cost.dta", clear
merge m:m parent_key using "$outputs\03_CAGE_fishing_gear_cost.dta", keepusing (gear_cost_cycl gear_cost_m3)
drop _merge

merge m:m parent_key using "$outputs\03_CAGE_equipment_cost_cost.dta", keepusing(equipment_cost_cycl equipment_cost_m3)
drop _merge

merge m:m parent_key using "$outputs\03_CAGE_permit_cost_cost.dta", keepusing(permit_cost_cycl permit_cost_m3)
drop _merge

merge m:m parent_key using "$outputs\03_CAGE_other_cost_cost.dta", keepusing(other_cost_cycl other_cost_m3)
drop _merge

egen totFixedCost_cycl=rowtotal(landBuil_cost_cycl gear_cost_cycl equipment_cost_cycl permit_cost_cycl other_cost_cycl), missing
egen totFixedCost_m3=rowtotal(landBuil_cost_m3 gear_cost_m3 equipment_cost_m3 permit_cost_m3 other_cost_m3), missing
label var totFixedCost_cycl "Total fixed cost per cycle"
label var totFixedCost_m3 "Total fixed cost per m^3"

save "$outputs\03_CAGE_fixed_cycle_and_perm3_cost.dta", replace
save "$hfc\03_CAGE_fixed_cycle_and_perm3_cost.dta", replace

