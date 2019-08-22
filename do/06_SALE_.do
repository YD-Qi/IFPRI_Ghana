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
global outputs    		"$root\checks"
global hfc				"$root\hfc_check\05_data\02_survey"

****************************************************************
******Tilapia harvest, sale and prices
****************************************************************
use "$inputs\aquaculture household survey-Module_I-Active_farmer-Section_H-H2_H2", clear
merge m:m setofh2_h2 using "$outputs\00_HOUSEHOLD_main_hfc_check.dta",keepusing (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 setofh2_h2 setofh2_h10 setoff9_f12 setofsel_speciecage submissiondate )
keep if _merge==3
drop _merge


*drop if percentage_total_harvest==.
bys parent_key: egen percent_check=sum( percentage_total_harvest)
order percent_check, after(percentage_total_harvest)
order HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 

rename h1_id h1_id2
*merge m:m setofh2_h10 using "$inputs\aquaculture household survey-Module_I-Active_farmer-Section_H-H2_H10"
merge m:m parent_key h1_id2 using "$inputs\aquaculture household survey-Module_I-Active_farmer-Section_H-H2_H10"
drop if _merge==2
drop _merge
*merge m:m setofh2_h2 using "$outputs\hh_labor_main_hfc_check.dta" , keepusing (HHID a6 enumerator_na1 a2 a3 b3 b4 b6  )
*drop if _merge==2

order setofh2_h2 setofh2_h10 parent_key key, last 
gen sold_in_kg_buyer1=h7
replace sold_in_kg_buyer1=h7 / 25 			if h7i==2 // crate ~ 25kg
lab var sold_in_kg_buyer1 "Tilapia unit price sold for the first buyer in kg"

gen sold_in_kg_buyer2=h9
replace sold_in_kg_buyer2=h9 / 25 			if h9i==2 // crate ~ 25kg
lab var sold_in_kg_buyer2 "Tilapia unit price sold for the first buyer in kg"


*merge m:m setofsel_speciecage using "$outputs\03_CAGE_Characteristics_hfc_check", keepusing (c2 c3 c4b c4bi c4bi_i c5a c5d c5a_unit_kg c5d_unit_kg c4bi c4bi_i c4di c4di_i c4b c4d c5c c5a_unit_kg c5d c5d_unit_kg stockingMostComnCage Prdn_per_Cage avgProdn_cage)
merge m:m parent_key using "$outputs\03_CAGE_Characteristics_hfc_check", keepusing (c2 c3 c4b c4bi c4bi_i c5a c5d c5a_unit_kg c5d_unit_kg c4bi c4bi_i c4di c4di_i c4b c4d c5c c5a_unit_kg c5d c5d_unit_kg stockingMostComnCage Prdn_per_Cage avgProdn_cage)
///keepusing (c2 c3 c4b c4bi c4bi_i c5a c5d stockingMostComnCage c5a_unit_kg cagePrdnRateMostComn Prdn_per_Cage avgProdn_cage c5d_unit_kg)
drop if _merge==2
drop _merge


merge m:m parent_key using "$outputs\04_POND_BIG_pond_production_hfc_check", keepusing (c7 c8 avgStockingBgPond biggestPondArea bp_harvest bp_harvest_kg bp_stocking bp_survival bp_survival_i )
///keepusing (c7 c8 avgStockingBgPond bgp_prdn_kg_m2 biggestPondArea bp_harvest bp_harvest_kg bp_stocking bp_survival bp_survival_i )
drop if _merge==2
drop _merge

gen surivival_rate=.
replace surivival_rate=c4bi/c4b if c4bi_i==1 
replace surivival_rate=bp_survival/bp_stocking if bp_survival_i==1

replace surivival_rate=c4bi/100 if c4bi_i==2
replace surivival_rate=bp_survival/100 if bp_survival_i==2
label var surivival_rate "survaival rate in percentage"

gen FingSizeConvRate_kg=.
replace FingSizeConvRate_kg=1 				if h1_id2=="1" //size 4 (1 fishes is almost 1 kg)
replace FingSizeConvRate_kg=(3 /2)  		if h1_id2=="2" //size 3 (3 fishes for 2 kg)
replace FingSizeConvRate_kg=(1 /2)  		if h1_id2=="3" //size 2 (2 fishes for 1 kg)
replace FingSizeConvRate_kg=(1 /3)  		if h1_id2=="4" //Size 1 (3 fishes for 1 kg)
replace FingSizeConvRate_kg=(1 /4.5)  		if h1_id2=="5" //Regular (4-5 fishes for 1 kg)
replace FingSizeConvRate_kg=(1 /5.5)  		if h1_id2=="6" //Economy (5-6 fishes for 1 kg)
replace FingSizeConvRate_kg=(1 /7)  		if h1_id2=="7" //Small size (6-8 fishes for 1 kg)
replace FingSizeConvRate_kg=(1 /9)  		if h1_id2=="8" //School boys (8-10 fishes for 1 kg)
label var FingSizeConvRate_kg "Conversion rate of the 8 fish size classes to Kg"

gen CalculatedPrdn_siz_kg=.
replace CalculatedPrdn_siz_kg=c4b * surivival_rate  * c3 * (percentage_total_harvest / 100) * FingSizeConvRate_kg 			if c3 != 0
replace CalculatedPrdn_siz_kg=bp_stocking * surivival_rate * c8 * (percentage_total_harvest / 100) * FingSizeConvRate_kg 	if (c8 != 0 & CalculatedPrdn_siz_kg ==.)


bys HHID b3: egen CalculatedPrdn_tot_kg= sum(CalculatedPrdn_siz_kg)
label var CalculatedPrdn_tot_kg "Calculated total production by HH (kg)"

order HHID enumerator_n b3 h1_name percentage_total_harvest c3 c4b c4bi c4bi_i c5a c4d c5c c5d bp_stocking bp_survival bp_survival_i /// 
bp_harvest avgStockingBgPond bp_harvest_kg surivival_rate FingSizeConvRate_kg CalculatedPrdn_siz_kg CalculatedPrdn_tot_kg

save "$outputs\05_SALE_tilapia_sale_vs_cage_pond_prdn_hfc_check.dta", replace
save "$hfc\05_SALE_tilapia_sale_vs_cage_pond_prdn_hfc_check", replace














/*




gen fingerling_numb_sold==.
lab var fingerling_numb_sold "Amount sold for the first buyer in kg"
replace fingerling_numb_sold=h7 * 1 			if (h7i==1 & h1_id=="1") 
replace fingerling_numb_sold=h7 * (2 / 3) 	if (h7i==1 & h1_id=="2") 
replace fingerling_numb_sold=h7 * (1 / 2) 	if (h7i==1 & h1_id=="3") 
replace fingerling_numb_sold=h7 * (1 / 3) 	if (h7i==1 & h1_id=="4") 
replace fingerling_numb_sold=h7 * (1 / 4.5) 	if (h7i==1 & h1_id=="5") 
replace fingerling_numb_sold=h7 * (1 / 5.5) 	if (h7i==1 & h1_id=="6") 
replace fingerling_numb_sold=h7 * (1 / 7) 	if (h7i==1 & h1_id=="7") 
replace fingerling_numb_sold=h7 * (1 / 9) 	if (h7i==1 & h1_id=="8") 

replace sold_in_kg_buyer1=h7 / 25 			if h7i==2 // crate ~ 25kg

replace sold_in_kg_buyer1=h7 				if h7i==3

gen sold_in_kg_buyer2=.
lab var sold_in_kg_buyer2 "Amount sold for the second buyer in kg"
replace sold_in_kg_buyer2=h9 * 1 			if (h9i==1 & h1_id=="1") 
replace sold_in_kg_buyer2=h9 * (2 / 3) 	if (h9i==1 & h1_id=="2") 
replace sold_in_kg_buyer2=h9 * (1 / 2) 	if (h9i==1 & h1_id=="3") 
replace sold_in_kg_buyer2=h9 * (1 / 3) 	if (h9i==1 & h1_id=="4") 
replace sold_in_kg_buyer2=h9 * (1 / 4.5) 	if (h9i==1 & h1_id=="5") 
replace sold_in_kg_buyer2=h9 * (1 / 5.5) 	if (h9i==1 & h1_id=="6") 
replace sold_in_kg_buyer2=h9 * (1 / 7) 	if (h9i==1 & h1_id=="7") 
replace sold_in_kg_buyer2=h9 * (1 / 9) 	if (h9i==1 & h1_id=="8") 

replace sold_in_kg_buyer2=h9 / 25 			if h9i==2 // crate ~ 25kg

replace sold_in_kg_buyer2=h9 				if h9i==3



destring h5, replace
order setofh2_h2 setofh2_h10 parent_key key, last 



*bys h1_id : egen telapsizeTotal=total (sold_in_kg)
*egen commonTelapSize=max(telapsizeTotal) 
*lab var commonTelapSize "Most common tilapia size produced"

preserve 

collapse (sum) percentage_total_harvest (mean)sold_in_kg_buyer1 sold_in_kg_buyer2, by (parent_key)

gen harvest_pct_error=(percentage_total_harvest>100)
lab var harvest_pct_error "Check percent total of tilapia produced by size" 

*gen harvestConsum_pct_error=(h3>100)
*lab var harvestConsum_pct_error "Check percent total of tilapia consumed by size" 

*gen harvestSold_pct_error=(h4>100)
*lab var harvestSold_pct_error "Check percent total of tilapia sold by size" 

drop if sold_in_kg_buyer1==. 
save "$outputs\Telapia_harvest_sale_per_hh_hfc_check.dta", replace
restore 

collapse (sum) percentage_total_harvest (mean)sold_in_kg_buyer1 sold_in_kg_buyer2, by  (h1_id )
save "$outputs\Telapia_harvest_sale_per_size_category_hfc_check.dta", replace
