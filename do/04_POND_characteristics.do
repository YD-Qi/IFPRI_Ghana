* Aquaculture survey
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
*POND characteristics-pond culture
****************************************************************
**stocking desnity=number of fingerlings per m^2 number of fingerlings/m2(range 10-30)
use "$inputs\aquaculture household survey-Module_I-Active_farmer-Section_C-Pondculture-TableCb", clear
merge m:m setoftablecb using "$outputs\00_HOUSEHOLD_main_hfc_check.dta",  ///
keepusing(HHID a6 enumerator_n caseid submissiondate a01 a1 a2 a3 b3 b4 b6 c1 c7 c8 e12 f13 e49 setoftablecb setofc12_bigpond ///
setofc13b_smallpond setofh2_h10 setoff2a_f7a submissiondate) force
keep if _merge==3
drop _merge

order HHID a6 a1 a2 a3 b3 b4 b6 c1 c7 c8 f13

mvdecode c10a - c10d, mv(999 = .) 

***convert shallow and deep pond depth to meter
gen c10a_lengthm=c10c*0.3048 if c10ai==1
replace c10a_lengthm=c10a if c10ai==2
label var c10a_lengthm "Pond length in meter"

gen c10b_widthm=c10b*0.3048 if c10bi==1
replace c10b_widthm=c10b if c10bi==2
label var c10b_widthm "Pond width in meter"

gen c10c_deepm=c10c*0.3048 if c10ci==1
replace c10c_deepm=c10c if c10ci==2
label var c10c_deepm "Pond depth-deep in meter"

gen c10d_shallowm=c10d*0.3048 if c10di==1
replace c10d_shallowm=c10d if c10di==2
label var c10d_shallowm "Pond depth--shallow in meter"

**average pond depth
egen avegDepthm= rowmean(c10c_deepm c10d_shallowm) 
label var avegDepthm "Average pond depth avg(deep,shallow) in meter"

***individual pond  AREA M^2
gen indivPondArea= c10a_lengthm * c10b_widthm
label var indivPondArea "Individual pond area in m^2"

***Pond average AREA M^2
bys HHID c9: egen avegPondArea = mean(indivPondArea)
bys HHID c9: egen biggestPondArea = max(indivPondArea)
bys HHID c9: egen smallestPondArea = min(indivPondArea)

label var avegPondArea "Average pond area in m^2 of a HH" 
label var biggestPondArea "The biggest pond area in m^2 of a HH"
label var smallestPondArea "The smallest pond area in m^2 of a HH"


***Pond average VOLUME M^3
gen individualPondVol= avegDepthm * c10a_lengthm * c10b_widthm
label var individualPondVol "Individual pond volume in m^3"

save "$outputs\04_POND_characteristics_hfc_check.dta", replace
save "$hfc\04_POND_characteristics_hfc_check", replace

gen pd_species=""
replace pd_species="Tilapia" if c9=="1"
replace pd_species="Catfish" if c9=="2"
replace pd_species="Heterotis" if c9=="3"
replace pd_species="Tilapia and Cathfish" if c9=="1 2"
replace pd_species="Tilapia and Heterotis" if c9=="1 3"
replace pd_species="Cathfish and Heterotis" if c9=="2 3"
replace pd_species="other" if c9=="777"


save "$outputs\04_POND_characteristics_hfc_check.dta", replace
save "$hfc\04_POND_characteristics_hfc_check", replace



preserve 

duplicates drop HHID c9  biggestPondArea, force
merge m:m setofc12_bigpond using "$inputs\aquaculture household survey-Module_I-Active_farmer-Section_C-Pondculture-C12-C12_bigpond"
drop if _merge==2
drop _merge

mvdecode bp_stocking bp_survival bp_harvest, mv(999 = .) 

drop if (bp_stocking==. &  bp_survival==. &  bp_harvest ==.)

*big pond harvest unit error
gen bgp_harvestUnit_error=(bp_harvest >= 10)
label var bgp_harvestUnit_error "Harvest above 10 tone--for checking"

***big pond-stocking rate [BIG POND]
gen avgStockingBgPond=bp_stocking / biggestPondArea if biggestPondArea!=.
label var avgStockingBgPond "Average stocking rate on big ponds (number of fingerlings/m^2)" 


**big pond unit corrections (tonne to kg)
gen bp_harvest_kg=bp_harvest * 1000
replace bp_harvest_kg=bp_harvest  if bp_harvest >=100
label var bp_harvest_kg "harvest reported > 100 (error) automatically considered as kg"

**big pond harvest per m^2
gen bgp_prdn_kg_m2=bp_harvest_kg / biggestPondArea if biggestPondArea!=.
label var bgp_prdn_kg_m2 "Big pond production rate kg/m2"


**production consistency ratio
gen survival_r=bp_survival if bp_survival_i==1
replace survival_r=(bp_survival/100 )* bp_stocking if bp_survival_i==2

gen bp_prdn_consistency=(bp_harvest_kg >= 0.3*survival_r)

keep if a01==1 //keep active only


**create a production bounda limit based on max and min size fingerling can grow using stocking and survival rate
**a fingerling can grow a maximum of 1 kg and minimum of 100 gram (0.1kg)
gen PerBpMaxBound_prdn_ton=.
replace PerBpMaxBound_prdn_ton= (1 * bp_survival) / 1000			 				if bp_survival_i==1   //max growth size of 1kg * # of fingerling survived per big pond
replace PerBpMaxBound_prdn_ton= (1 * bp_stocking * (bp_survival /100)) / 1000		if bp_survival_i==2   //max growth size of 1kg * stocking rate * % fingerling survived

gen PerBpMinBound_prdn_ton=.
replace PerBpMinBound_prdn_ton= (0.1 * bp_survival )	/ 1000		 				if bp_survival_i==1   //min size growth of 0.1kg * # of fingerling survived
replace PerBpMinBound_prdn_ton= (0.1 * bp_stocking * (bp_survival /100)) / 1000	 	if bp_survival_i==2   //min size growth of 0.11kg * stoking rate * % fingerling survived

label var PerBpMaxBound_prdn_ton "Expected max per cage production at 1kg max growth limit of fingerlings stocked in metric ton"
label var PerBpMinBound_prdn_ton "Expected min per cage production at 0.1kg min growth limit of fingerlings stocked in metric ton"


gen totBpMaxBound_prdn_ton=.
replace totBpMaxBound_prdn_ton= (1 * bp_survival * c8)/ 1000		 					if bp_survival_i==1   //max size growth of 1kg * # of fingerling survived * tot number of big pond used
replace totBpMaxBound_prdn_ton= (1 * bp_stocking * c8 * (bp_survival /100)) / 1000		if bp_survival_i==2   //max size of 1kg * stoking rate * % fingerling survived * tot number of big pond used

gen totBpMinBound_prdn_ton=.
replace totBpMinBound_prdn_ton= (0.1 * bp_survival * c8 ) / 1000		 				if bp_survival_i==1   //max size of 0.1kg * # of fingerling survived * tot number of big ponds used
replace totBpMinBound_prdn_ton= (0.1 * bp_stocking * c8*  (bp_survival /100)) / 1000	if bp_survival_i==2   //max size of 1kg * stoking rate * % fingerling survived * tot number of big ponds used

label var totBpMaxBound_prdn_ton "Expected max total number of cage production at 1kg max growth limit of fingerlings stocked in metric ton"
label var totBpMinBound_prdn_ton "Expected min total number of cage production at 0.1kg min growth limit of fingerlings stocked in metric ton"

order totBpMaxBound_prdn_ton - totBpMinBound_prdn_ton, after (bp_harvest)





save  "$outputs\04_POND_BIG_pond_production_hfc_check.dta", replace
save "$hfc\04_POND_BIG_pond_production_hfc_check.dta", replace

restore

*********Smallest pond (sp)
preserve
duplicates drop HHID c9  smallestPondArea, force

merge m:m setofc13b_smallpond using "$inputs\aquaculture household survey-Module_I-Active_farmer-Section_C-Pondculture-C13-C13b_smallpond", force
drop if _merge==2
drop _merge

mvdecode sp_stocking sp_survival sp_harvest, mv(999 = .) 

drop if (sp_stocking==. &  sp_survival==. &  sp_harvest ==.)

*small pond(sp) harvest unit error
gen sp_harvestUnit_error=(sp_harvest >= 10)
label var sp_harvestUnit_error "Harvest above 10 tone--for checking"

***small pond (smlp)-stocking rate [BIG POND]
gen avgStockingsmlpond=sp_stocking / smallestPondArea if smallestPondArea!=.
label var avgStockingsmlpond "Average stocking rate on the smallest ponds (number of fingerlings/m^2)" 

**small pond (sp) unit corrections (tonne to kg)
gen sp_harvest_kg=sp_harvest * 100
replace sp_harvest_kg=sp_harvest   if sp_harvest_kg >=100
label var sp_harvest_kg "harvest reported > 100 (error) automatically considered as kg"

**harvest per m^2
gen sp_prdn_kg_m2=sp_harvest_kg / smallestPondArea if smallestPondArea!=.
label var sp_prdn_kg_m2 "Smallest pond production rate kg/m2"

**production consistency ratio
gen survival_r_sp=sp_survival if sp_survival_i==1
replace survival_r_sp=(sp_survival/100 )* sp_stocking if sp_survival_i==2
gen sp_prdn_consistency=(sp_harvest_kg >= 0.3*survival_r_sp)

keep if a01==1 //keep active only
save  "$outputs\04_POND_SMALL_pond_production_hfc_check.dta", replace
save "$hfc\04_POND_SMALL_pond_production_hfc_check.dta", replace
 
restore


save "$outputs\04_POND_characteristics_hfc_check.dta", replace
save "$hfc\04_POND_characteristics_hfc_check", replace



*************************************************************
****************POND*****************************************
**fixed cost-POND

use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Pond-F14_F19-F15_F19", clear
merge m:m parent_key using "$outputs\04_POND_BIG_pond_production_hfc_check.dta" , keepusing (HHID a6 enumerator_n a01 a1 a2 a3 b3 b4 b6 a6 c7 c8 f13 e49 biggestPondArea bp_harvest_kg submissiondate)
keep if _merge==3
drop _merge
mvdecode f17a f19a, mv(999 = .) 

gen PondplanBldg_cost=f17a / (f19a * 2)
label var PondplanBldg_cost "Pond land plan and building cost per cycle"
order PondplanBldg_cost, after(f19a)

gen perPondplanBldg_cost=PondplanBldg_cost 

replace perPondplanBldg_cost=PondplanBldg_cost / c8 if f13==0
label var perPondplanBldg_cost "Per pond -land plan and building cost per cycle"
order perPondplanBldg_cost, after(f19a)

gen PondplanBldg_perm2=perPondplanBldg_cost / biggestPondArea
label var perPondplanBldg_cost "Pond-land plan and building cost per m2"

gen bldcost_shareonprdn_perm2=perPondplanBldg_cost / bp_harvest_kg
label var bldcost_shareonprdn_perm2 "Pond-land and building cost over per production total"

bys HHID: egen perHH_planBuilding_cost=sum(PondplanBldg_perm2)
replace perHH_planBuilding_cost=. if PondplanBldg_perm2==.
bys HHID: egen perHH_landblg_cost_on_prdn=sum(bldcost_shareonprdn_perm2)
replace perHH_landblg_cost_on_prdn=. if bldcost_shareonprdn_perm2==.

label var perHH_planBuilding_cost "Household level cost for land and building material for pond (m^2) "

gen pondLandBldcost_error=(f17a!=. & f19a==.)
label var pondLandBldcost_error "Number of years the cost refers missing"

*collapse (sum) planBuilding_cost=f17a if (f17a!=.) , by (parent_key)
*drop if (planBuilding_cost==999 | planBuilding_cost==0)
*label var planBuilding_cost "Cost of land and building material for pond"

drop  if (f17a==. & f19a==.)
order HHID a6 a1 a2 a3 b3 b4 b6

save "$outputs\04_POND_land_and_building_cost.dta", replace
save "$hfc\04_POND_land_and_building_cost", replace


**pond construction cost
use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Pond-F14_F19-F17_F19.dta", clear
merge m:m parent_key using "$outputs\04_POND_BIG_pond_production_hfc_check.dta" , keepusing (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 a6 c7 c8 f13 e49 biggestPondArea bp_harvest_kg submissiondate)
keep if _merge==3
drop _merge
mvdecode f17b f19b, mv(999 = .) 

gen Pondconstrn_cost=f17b / (f19b * 2)
label var Pondconstrn_cost "Pond construction cost per cycle"

gen perPondconstrn_cost=Pondconstrn_cost 
replace perPondconstrn_cost=Pondconstrn_cost / c8	 if f13==0
label var perPondconstrn_cost "Per pond construction cost per cycle"

gen Pondconstrn_perm2=perPondconstrn_cost / biggestPondArea
label var Pondconstrn_perm2 "Pond construction cost per m2"


bys parent_key: egen perHH_pondconstruction_cost=sum(Pondconstrn_perm2)
replace perHH_pondconstruction_cost=. if Pondconstrn_perm2==.
label var perHH_pondconstruction_cost "Total per m^2 pond construction cost"


gen pondConstrcost_error=(f17b!=. & f19b==.)
label var pondConstrcost_error "Number of years the cost refers missing"


*collapse (sum) pondconstrn_cost=f17b if (f17b!=. | f17b !=999) , by ( f15b f19b parent_key)
*drop if (pondconstrn_cost==999 | pondconstrn_cost==0)
*label var pondconstrn_cost "Cost of pond construction"
*drop  if (f17b==. & f19b==.)

order HHID a6 a1 a2 a3 b3 b4 b6

drop if (f17b==. &  f19b ==.)

save "$outputs\04_POND_construction_cost.dta", replace
save "$hfc\04_POND_construction_cost", replace

**Equipment and machine cost/rental
use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Pond-F14_F19-F15c_F19c", clear
merge m:m parent_key using "$outputs\04_POND_BIG_pond_production_hfc_check.dta" , keepusing (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 a6 c7 c8 f13 e49 biggestPondArea bp_harvest_kg submissiondate)
keep if _merge==3
drop _merge

mvdecode f17c f19c, mv(999 = .) 

gen Pondequipmnt_cost=f17c / (f19c * 2)
label var Pondequipmnt_cost "Pond equipment/machine [rental] cost per cycle"

gen perPondequipmnt_cost=Pondequipmnt_cost
replace perPondequipmnt_cost=Pondequipmnt_cost / c8		 if f13==0
label var perPondequipmnt_cost "Per pond equipment/machine [rental] cost per cycle"

gen Pondequipmnt_perm2=perPondequipmnt_cost / biggestPondArea
label var Pondequipmnt_perm2 "Pond equipment/machine [rental] cost per m2"

bys parent_key: egen perHH_Pondequipmnt_cost=sum(Pondequipmnt_perm2)
replace perHH_Pondequipmnt_cost=. if Pondequipmnt_perm2==.
label var perHH_Pondequipmnt_cost "Total per m^2 equioment/machine [rental] cost"

gen pondequipmnt_error=(f17c!=. & f19c==.)
label var pondequipmnt_error "Number of years the cost refers missing"
*collapse (sum) pondpermit_cost=f17d if (f17d!=. | f17d !=999) , by ( f15d f19d parent_key)
*drop if (pondpermit_cost==999 | pondpermit_cost==0)
*label var pondpermit_cost "Cost of permit and environment for pond"
*drop  if (f17c==. & f19c==.)
order HHID a6 a1 a2 a3 b3 b4 b6

drop if (f17c ==. & f19c ==.)
save "$outputs\04_POND_equipment_cost.dta", replace
save "$hfc\04_POND_equipment_cost", replace


**Environment permit cost
use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Pond-F14_F19-F15d_F19d", clear
merge m:m parent_key using "$outputs\04_POND_BIG_pond_production_hfc_check.dta" , keepusing (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 a6 c7 c8 f13 e49 biggestPondArea bp_harvest_kg submissiondate)
keep if _merge==3
drop _merge
mvdecode f17d f19d, mv(999 = .) 

gen PondenvtPermit_cost=f17d / (f19d * 2)	
label var PondenvtPermit_cost "Pond environmental permit and other  cost per cycle"

gen perPondenvtPermit_cost=PondenvtPermit_cost 		
replace  perPondenvtPermit_cost=PondenvtPermit_cost / c8	 if f13==0
label var perPondenvtPermit_cost "Per pond environmental permit cost per cycle"

gen PondenvtPermit_perm2=perPondenvtPermit_cost / biggestPondArea
label var PondenvtPermit_perm2 "Pond environmental permit cost per m2"

bys parent_key: egen perHH_PondenvtPermit_cost=sum(PondenvtPermit_perm2)
replace perHH_PondenvtPermit_cost=. if PondenvtPermit_perm2==.
label var perHH_PondenvtPermit_cost "Total per m^2 pond environmental permit cost"

gen pondenvPermit_error=(f17d!=. & f19d==.)
label var pondenvPermit_error "Number of years the cost refers missing"
*collapse (sum) pondpermit_cost=f17d if (f17d!=. | f17d !=999) , by ( f15d f19d parent_key)
*drop if (pondpermit_cost==999 | pondpermit_cost==0)
*label var pondpermit_cost "Cost of permit and environment for pond"
order HHID a6 a1 a2 a3 b3 b4 b6
drop  if (f17d==. & f19d==.)

save "$outputs\04_POND_envt_permit.dta", replace
save "$hfc\04_POND_envt_permit", replace

**Machine purchase/rental cost
use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Pond-F14_F19-F15e_F19e", clear
merge m:m parent_key using "$outputs\04_POND_BIG_pond_production_hfc_check.dta" , keepusing (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 a6 c7 c8 f13 e49 biggestPondArea bp_harvest_kg submissiondate)
keep if _merge==3
drop _merge

mvdecode f17e f19e, mv(999 = .) 

gen Pondmachine_cost=f17e / (f19e * 2)
label var Pondmachine_cost "Pond environmental permit and other  cost per cycle"

gen perPondmachine_cost=Pondmachine_cost 
replace perPondmachine_cost=Pondmachine_cost / c8	if f13==0
label var perPondmachine_cost "Per pond environmental permit cost per cycle"

gen Pondmachine_perm2=perPondmachine_cost / biggestPondArea
label var Pondmachine_perm2 "Pond environmental permit cost per m2"

bys parent_key: egen perHH_Pondmachine_cost=sum(Pondmachine_perm2)
replace perHH_Pondmachine_cost=. if Pondmachine_perm2==.
label var perHH_Pondmachine_cost "Total per m^2 pond environmental permit cost"

gen pondmachine_error=(f17e!=. & f19e==.)
label var pondmachine_error "Number of years the cost refers missing"
*collapse (sum) pondpermit_cost=f17d if (f17d!=. | f17d !=999) , by ( f15d f19d parent_key)
*drop if (pondpermit_cost==999 | pondpermit_cost==0)
*label var pondpermit_cost "Cost of permit and environment for pond"
order HHID a6 a1 a2 a3 b3 b4 b6
drop  if (f17e==. & f19e==.)

save "$outputs\04_POND_machine_cost.dta", replace
save "$hfc\04_POND_machine_cost", replace

**variable cost POND
use "$inputs\aquaculture household survey-Module_I-Active_farmer-F1_F35-Pond-F21_F24" , clear
merge m:m parent_key using "$outputs\04_POND_BIG_pond_production_hfc_check.dta" , keepusing (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 a6 c7 e12 c8 f13 e49 biggestPondArea bp_stocking bp_harvest_kg submissiondate)
keep if _merge==3
drop _merge

merge m:m setoff21_f24 using "$outputs\00_HOUSEHOLD_main_hfc_check.dta", keepusing (f19 )
keep if _merge==3
drop _merge

mvdecode e12 pd_cost pd_quantity, mv(999 = .) 


gen itemzdVarCost=pd_cost*pd_quantity
label var itemzdVarCost "Itemized 1 full cycle variable cost for all ponds"

gen PerPondVarCost=itemzdVarCost
replace PerPondVarCost=itemzdVarCost / c8  if f19==0
label var PerPondVarCost "Itemized 1 full cycle total variable cost per pond"

gen PondVarCost_perm2=PerPondVarCost/biggestPondArea
label var PondVarCost_perm2 "Itemized 1 full cycle total variable cost per m2"

bys parent_key: egen totPondVarCost=sum(PondVarCost_perm2)
replace totPondVarCost=. if PondVarCost_perm2==.
label var totPondVarCost "Total pond variable cost per household per m2"

gen extraPay_ratio_pnd=.
replace extraPay_ratio_pnd=(e49 / pd_cost) if pd_unit==6  //pd_cost: cost of fingerling pd_unit==6: piece
replace extraPay_ratio_pnd=(e49 / (pd_cost * e12)) if pd_unit==8 //e12 : size of fingerling in gram
replace extraPay_ratio_pnd=(e49 / (pd_cost / (c8 * bp_stocking ))) 	if (f19==0 & pd_unit==5)
replace extraPay_ratio_pnd=(e49 / (pd_cost /  bp_stocking )) 		if (f19==1 & pd_unit==5)
label var extraPay_ratio_pnd "The ratio of willing to pay more on fingerling/broodstock" 


order HHID a6 enumerator_n a1 a2 a3 b3 b4 b6
destring pondvc_id, replace
drop if (pd_cost==. & pd_quantity==.)

save "$outputs\04_POND_Variable_cost.dta", replace
save "$hfc\04_POND_Variable_cost", replace


