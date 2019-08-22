/* Data documentation by Yuandong Qi:

"00_HOUSEHOLD_main_hfc_check" 
it records at HH level, demongraphic info and farming info at HH level
respondent/owner/manager's gender, age, edu, distance to farm
culture: pond, cage, or pond and cage
number of ponds, cages
perception of quality of input
record keeping
if changes being made

"03_CAGE_Characteristics_hfc_check.dta"
it records at HH-cage level (not every cage is recorded)
unique(HHID c1_id)
cage's dimension
cage's volumne
production
stocking rate
survival rate

"04_POND_characteristics_hfc_check.dta"
it records at HH-pond level (not every pond is recorded)
unique(HHID c9_id)
1025 ponds belong to 415 HH
pond area
pond volumne
pond species


"03_CAGE_equipment_cost_cost.dta"
HH-equipment level

"03_CAGE_fishing_gear_cost.dta"
HH-fishing gear level

"03_CAGE_fixed_cycle_and_perm3_cost.dta"
HH-land-building level
it includes all fixed costs from equipment to land, to permit

"03_CAGE_land_building_cost.dta"
HH-land-building level

"03_CAGE_other_cost_cost.dta"
HH-other item level

"03_CAGE_other_variable_cost.dta"



*/










* For Ghana TiSeed aquaculture survey
* Data cleaning and dscriptive/summary tables
****************************OPTIONS******************************
clear
#delimit ; 
set more off; capture log close; clear matrix; set matsize 800;
label drop _all; 
#delimit cr 
*****************************************************************.
global root	     		"/Users/yd/Dropbox/IFPRI_Ghana"
global inputs    		"$root/survey_july17"
global intermediate		"$root/checks/intermediate"
global clean    		"$root/checks"
global newData    		"$root/checks/Data_Yuandong"
global hfc				"$root/hfc_check/05_data/02_survey"
global tables			"$root/temp"
global tables			"$root/tables"
global regressions		"$root/regressions"


****************************************************************
log using "/Users/yd/Dropbox/IFPRI_Ghana/Work By Yuandong/Do files_Yuandong/log_general_cleaning_descriptive_tables_Yuandong.smcl",replace

use "$clean/00_HOUSEHOLD_main_hfc_check.dta",clear

*************************

* DATA CLEANING/PREPARING

*************************

rename (a2 a2_i b3 b5) (zone district name_respondent phone_respondent)
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
tab active


*distance
gen distance=b2 if b2i==1
replace distance=0 if b2==0
replace distance=b2/1.60934 if b2i==2 
replace distance=b2/1000 if b2i==3
replace distance=b2/15 if b2i==5 
*15 min walk=1km 
*check 38 obs with 999
*check 1 obs with 500 km and 600 km,  too high
*84% of farms are within 2 km (30 minutes walk) to the respondent's house

table culture active
table culture active, by(region)
sum pb_1_iii if active==1
keep if active==1

*check that there is 1 cage&pond in Ashanti

split c1, destring
split c12a, destring
split c13a, destring

* create new varible region_culture
gen culture_="Pond" if culture==1
replace culture_="Cage" if culture==2
replace culture_="Pond&Cage" if culture==3
gen region_culture=region + "-" + culture_

*Tilapia species
*checked why there is 777 in fish specie
*one is tilapia and catfish, so I adjusted, but one says "not stocked yet"
gen tilapia=1 if c11==1|c12==1|c12a1==1|c12a2==1|c13a1==1|c13a2==1|c13a3==1|c12ai=="Tilapia and catfish"
replace tilapia=0 if tilapia==.

gen catfish=1 if c11==2|c12==2|c12a1==2|c12a2==2|c13a1==2|c13a2==2|c13a3==2|c12ai=="Tilapia and catfish"
replace catfish=0 if catfish==.

gen tilapiacatfish=1 if tilapia==1&catfish==1
replace tilapiacatfish=0 if tilapiacatfish==.
*check why 217 obs do not have tilapia when we were supposed to interview only tilapia farmers

* roles of respondents: owner or manager
tab b4
tab b4i
* owner is the manager?
tab b15
*ERROR
list region enumerator_n HHID name_respondent phone_respondent if b4==777

* reconstruct owner's info
gen gender_owner=b7a 
replace gender_owner=b7 if gender_owner==. & b4==1

gen age_owner=b8a
replace age_owner=b8 if age_owner==. & b4==1

gen edu_owner=b9a
replace  edu_owner=b9 if edu_owner==. & b4==1

gen distance_owner = b2a if b2ai==1
replace distance_owner=0 if b2a==0
replace distance_owner=b2a/1.60934 if b2i==2 
replace distance_owner=b2a/1000 if b2i==3
replace distance_owner=b2a/15 if b2i==5
replace distance_owner=distance if distance_owner==. & b4==1


* reconstruct manager's info
gen gender_manager=b6c
replace gender_manager=b7 if gender_manager==. & b4==2

gen age_manager=b7c 
replace age_manager=b8 if age_manager==. & b4==2

gen edu_manager=b8c
replace  edu_manager=b9 if edu_manager==. & b4==2

gen distance_manager = b2c if b2ci==1
replace distance_manager=0 if b2c==0
replace distance_manager=b2c/1.60934 if b2ci==2 
replace distance_manager=b2c/1000 if b2ci==3
replace distance_manager=b2c/15 if b2ci==5
replace distance_manager=distance if distance_manager==. & b4==2

* number of average ponds owned by HH
gen n_ponds_owned = c7

* number of ponds used by the HH
gen n_ponds_used = c8

* average number of cages set up by HH
gen n_cages_owned = c2

* average number of cages used by the HH
gen n_cages_used = c3


*************************

* SUMMARY STATISTICS

*************************

*Table 1
tab region culture if active==1
tab region culture if active==0

*Table 2
tab region c1 if active==1
tab region c1 if active==0

gen tilapia_only=0
replace tilapia_only=1 if c12a=="1"| c13a=="1"

gen tilapia_mix=0
replace tilapia_mix=1 if c12a=="1 2"|c12a=="1 2 3"|c12a=="1 3"|c12ai=="Tilapia and catfish"| c13a=="1 2"|c13a=="1 2 3"|c13a=="1 3"|c13ai=="Tilapia and catfish"

tab region tilapia_only if active==1
tab region tilapia_only if active==0

tab region tilapia_mix if active==1
tab region tilapia_mix if active==0

* table 3 respondant's info

*gender
bys culture: tab region b7 if active==1
bys culture: tab region b7 if active==0

*age
bys culture: tabstat b8 if active==1, by(region) s(n mean median sd min max) c(s)
bys culture: tabstat b8 if active==0, by(region) s(n mean median sd min max) c(s)

* edu
bys culture: tab region b9 if active==1
bys culture: tab region b9 if active==0

*marital
bys culture: tab region b10 if active==1
bys culture: tab region b10 if active==0

* polygamous or monogamous
bys culture: tab region b12 if active==1
bys culture: tab region b12 if active==0

*religion
bys culture: tab region b14 if active==1
bys culture: tab region b14 if active==0

*distance
bys culture: tabstat distance if active==1, by(region) s(n mean median sd min max) c(s)
bys culture: tabstat distance if active==0, by(region) s(n mean median sd min max) c(s)


* table 4 owner's info (fill missing with respondent data)
*gender
bys culture: tab region gender_owner if active==1
bys culture: tab region gender_owner if active==0

*age
bys culture: tabstat age_owner if active==1, by(region) s(n mean median sd min max) c(s)
bys culture: tabstat age_owner if active==0, by(region) s(n mean median sd min max) c(s)

* edu
bys culture: tab region edu_owner if active==1
bys culture: tab region edu_owner if active==0

*distance
bys culture: tabstat distance_manager if active==1, by(region) s(n mean median sd min max) c(s)
bys culture: tabstat distance_manager if active==0, by(region) s(n mean median sd min max) c(s)


* table 5 manager's info
*gender
bys culture: tab region gender_manager if active==1
bys culture: tab region gender_manager if active==0

*age
bys culture: tabstat age_manager if active==1, by(region) s(n mean median sd min max) c(s)
bys culture: tabstat age_manager if active==0, by(region) s(n mean median sd min max) c(s)

* edu
bys culture: tab region edu_manager if active==1
bys culture: tab region edu_manager if active==0

*distance
bys culture: tabstat distance_manager if active==1, by(region) s(n mean median sd min max) c(s)
bys culture: tabstat distance_manager if active==0, by(region) s(n mean median sd min max) c(s)

* table 6: number of ponds and cages
bys culture: tabstat n_ponds_owned n_ponds_used n_cages_owned n_cages_used if active==1, by(region) s(n mean median sd min max) c(s)
bys culture: tabstat n_ponds_owned n_ponds_used n_cages_owned n_cages_used if active==0, by(region) s(n mean median sd min max) c(s)

* table7: have hatchery or not? less than 5%
bys culture: tab region c16 if active==1
bys culture: tab region c16 if active==0


* months of production cycle (big pond)
*ERROR: one reported 999
tabstat c12_ibi if c12_ibi<999, by(region_culture) s(n mean median sd min max) c(s)

* months of production cycle (small pond)
*ERROR: one reported 999
tabstat c13_ibi if c13_ibi<999, by(region_culture) s(n mean median sd min max) c(s)


* missing tilapia's months of production cycle (big and small ponds)
list region enumerator_n HHID name_respondent phone_respondent if c12_ibi==999
list region enumerator_n HHID name_respondent phone_respondent if c13_ibi==999

*plan to increase, decrease cage production?
bys region_culture: tab c23 
*plan to increase, decrease pond production?
bys region_culture: tab c24 
*plan to increase, decrease production next 3 years?
bys region_culture:  tab c25

*production decreasing/increasing over past 5 years?
bys region_culture:  tab c15

* mortality rate of fingerling during transport
tabstat e25a, by(region_culture) s(n mean median sd min max) c(s)

*history of fish farming
* learning about fish farming for the first time from extension agent?
gen learning_source=strpos(d2, "1")
tab learning_source
tabstat learning_source, by(region_culture) s(n mean) c(s)
* seek advice?
tabstat d3, by(region_culture) s(n mean) c(s)

* advice sources is extension agent?
gen advice_source=strpos(d4, "1")
tab advice_source
tabstat advice_source, by(region_culture) s(n mean) c(s)

* changing in  practice?

* species
tab d6ai 
*fingerling
tab d6aii 
*feed
tab d6aiii 
*water management
tab d6aiv 
* use of chemical
tab d6av 
* stocking rate
tab d6avi 
* location
tab d6avii
* dimension 
tab d6aviii 
*packaging
tab d6aix 
*size of fingerling
tab d6ax 
*labor
tab d6axi

foreach var of varlist d6ai d6aii d6aiii d6aiv d6av d6avi d6avii d6aviii d6aix d6ax d6axi{
replace `var'=. if `var'==98
}

tabstat d6ai d6aii d6aiii d6aiv d6av d6avi d6avii d6aviii d6aix d6ax d6axi, by(region_culture) s(n) 
tabstat d6ai d6aii d6aiii d6aiv d6av d6avi d6avii d6aviii d6aix d6ax d6axi, by(region_culture) s(mean) 

foreach var of varlist d6bi d6bii d6biii d6biv d6bv d6bvi d6bvii d6bviii d6bix d6bx d6bxi{
tab `var'
}


* still do crop farming?
gen crop_farming=strpos(d14, "2")
tab crop_farming
tabstat crop_farming, by(region_culture) s(n mean)

* did crop farming before aquaculture
gen crop_farming_before=strpos(d10, "2")
tab crop_farming_before

tabstat d15, by(region_culture) s(n mean median sd min max) c(s)

*quality perception
foreach var of varlist e39n e39o e39c e39d e39c_i e39_i e39e e39f e39e_i e39f_i e39g e39h e39k e39p e39q e39i e39zi e39j e39m e39l{
bys region_culture: tab `var'
}

* record keeping
* Do you have water quality record?
tab e304  
* Did farmer show you a proof of his/her water quality record?
tab e304a  
* Do you have effluent (waste water).  management record?
tab e307    
* Did respondent show any proof/documentation for effluent management record?
tab e307a  
* Do you have feeds and feeding records?
tab e336  
* Did farmer show you any proof/documentation for feed and feeding record?
tab e336a 
* tab Do you keep records of drugs/chemical/antibiotic use?
tab e338a 
* Did farmer show you any proof/documentation for drugs/chemical/antibiotic use?
tab e338b

tabstat e304  e307  e336  e338a, by(region_culture) s(mean) c(s)
tabstat e304a e307a e336a e338b, by(region_culture) s(mean) c(s)


* CAGE characteristic
use "$clean/03_CAGE_Characteristics_hfc_check.dta",clear

gen region_species=region + "-" + c1_name

* volumne of most common cage size
tabstat cageMostComnV, by(region_species) s(n mean median sd min max)

* dimension of most common cage
decode c4a, gen(mostCommonSize)
replace mostCommonSize=c4i if c4a==777
bys region_species: tab mostCommonSize

*CAGE PRODUCTION
*stocking rate most common cage per m3 excluding stocking rate out of a presumed average range (40-100)
tabstat stockingMostComnCage if stockingMostComnCage_error!=1, by(region_species) s(n mean median sd min max)
*report error
list HHID enumerator_n b3 c4b cageMostComnV c4a if stockingMostComnCage_error==1

*production rate most common cage kg per m3 excluding production rate out of a presumed average range (15-25)
tabstat cagePrdnRateMostComn if cagePrdnRateMostComn_error!=1, by(region_species) s(n mean median sd min max)
*report error
list HHID enumerator_n b3 c5a cageMostComnV c4a if cagePrdnRateMostComn_error==1

*survival rate of the most common cage
tabstat c4bi if c4bi_i==1, by(region_species) s(n mean median sd min max)
tabstat c4bi if c4bi_i==2, by(region_species) s(n mean median sd min max)

*POND characteristics
use "$clean/04_POND_characteristics_hfc_check.dta",clear

gen region_species= a1+ "-" + pd_species

tab a1
tab pd_species

tabstat indivPondArea individualPondVol, by(a1) s(n mean median sd min max) c(s)

* Fingerling size
use "$clean/06_FINGERLING_production_hfc_check.dta",clear
rename (a1 a6 b3) (region name_enumerator name_respondent)

*size of fingerling produced
tabstat c20, by(c18_name) s(n mean median sd min max)

* hatchery production (what is the unit, number?)
tabstat c21a, by(c18_name) s(n mean median sd min max)

*survival rate by number and percent, note c27i is missing for these reported 999 or 0 on c27
tabstat c27 if c27i==1, by(c18_name) s(n mean median sd min max)
tabstat c27 if c27i==2, by(c18_name) s(n mean median sd min max)
list region name_enumerator HHID name_respondent c16 c27 c27i if c27!=.&c27i==.

* growth rate (days took from 2g to 5g)
*ERROR 6 report 999
tabstat c26 if c26!=999, by(c18_name) s(n mean median sd min max)

list region name_enumerator name_respondent c16 c26 if c26==999

* fingerling production increasing, decreasing?
bys c18_name: tab c22



use "$clean/04_POND_BIG_pond_production_hfc_check.dta", clear

rename (a6 a1 b3) (name_enumerator region name_respondent)
tab c12a_name
* ERROR: someone reported Tilapia and Catfish mixed
list HHID name_enumerator region name_respondent c12a_name if c12a_name=="Tilapia and catfish"

* production rate kg/m2 (big pond)
* WARNING: too small numbers
tabstat bgp_prdn_kg_m2 if c12a_name=="Cat fish", by(region) s(n mean median sd min max)
tabstat bgp_prdn_kg_m2 if c12a_name=="Tilapia", by(region) s(n mean median sd min max)
tabstat bgp_prdn_kg_m2 if c12a_name=="Heterotis", by(region) s(n mean median sd min max)
tabstat bgp_prdn_kg_m2 if c12a_name=="Tilapia and catfish", by(region) s(n mean median sd min max)

*stocking rate (big pond)
tabstat bp_stocking if c12a_name=="Cat fish", by(region) s(n mean median sd min max)
tabstat bp_stocking if c12a_name=="Tilapia", by(region) s(n mean median sd min max)
tabstat bp_stocking if c12a_name=="Heterotis", by(region) s(n mean median sd min max)
tabstat bp_stocking if c12a_name=="Tilapia and catfish", by(region) s(n mean median sd min max)


*survival rate expressed in % (big pond)
gen survival_rate_bp=bp_survival if bp_survival_i == 2
replace survival_rate_bp=(bp_survival/bp_stocking)*100 if bp_survival_i == 1

tabstat survival_rate_bp if survival_rate_bp<=100& c12a_name=="Cat fish", by(region) s(n mean median sd min max)
tabstat survival_rate_bp if survival_rate_bp<=100& c12a_name=="Tilapia", by(region) s(n mean median sd min max)
tabstat survival_rate_bp if survival_rate_bp<=100& c12a_name=="Heterotis", by(region) s(n mean median sd min max)
tabstat survival_rate_bp if survival_rate_bp<=100& c12a_name=="Tilapia and catfish", by(region) s(n mean median sd min max)

list HHID name_enumerator region name_respondent c12a_name survival_rate_bp bp_survival bp_stocking bp_survival_i if  survival_rate_bp>100 & survival_rate_bp<.


use "$clean/04_POND_SMALL_pond_production_hfc_check.dta", clear
rename (a6 a1 b3) (name_enumerator region name_respondent)
* ERROR: someone reported Tilapia and Catfish mixed
tab c13a_name
list HHID name_enumerator region name_respondent c13a_name if c13a_name=="Tilapia and Catfish"

*survival rate expressed in % (small pond)
gen survival_rate_sp=(sp_survival/sp_stocking)*100 if sp_survival_i == 1
replace survival_rate_sp=sp_survival if sp_survival <= 100


* production rate kg/m2 (small pond)
* WARNING: too small numbers
tabstat sp_prdn_kg_m2 if c13a_name=="Cat fish", by(region) s(n mean median sd min max)
tabstat sp_prdn_kg_m2 if c13a_name=="Tilapia", by(region) s(n mean median sd min max)
tabstat sp_prdn_kg_m2 if c13a_name=="Heterotis", by(region) s(n mean median sd min max)
tabstat sp_prdn_kg_m2 if c13a_name=="Tilapia and Catfish", by(region) s(n mean median sd min max)
tabstat sp_prdn_kg_m2 if c13a_name=="Tilapia and Catfish", by(region) s(n mean median sd min max)
tabstat sp_prdn_kg_m2 if c13a_name=="mud fish", by(region) s(n mean median sd min max)

*stocking rate (small pond)
tabstat sp_stocking if c13a_name=="Cat fish", by(region) s(n mean median sd min max)
tabstat sp_stocking if c13a_name=="Tilapia", by(region) s(n mean median sd min max)
tabstat sp_stocking if c13a_name=="Heterotis", by(region) s(n mean median sd min max)
tabstat sp_stocking if c13a_name=="Tilapia and Catfish", by(region) s(n mean median sd min max)
tabstat sp_stocking if c13a_name=="mud fish", by(region) s(n mean median sd min max)


*survival rate expressed in % (small pond)

tabstat survival_rate_sp if survival_rate_sp<=100& c13a_name=="Cat fish", by(region) s(n mean median sd min max)
tabstat survival_rate_sp if survival_rate_sp<=100& c13a_name=="Tilapia", by(region) s(n mean median sd min max)
tabstat survival_rate_sp if survival_rate_sp<=100& c13a_name=="Heterotis", by(region) s(n mean median sd min max)
tabstat survival_rate_sp if survival_rate_sp<=100& c13a_name=="Tilapia and Catfish", by(region) s(n mean median sd min max)

list HHID name_enumerator region name_respondent survival_rate_sp sp_survival c13a_name sp_stocking sp_survival_i if survival_rate_sp>100&survival_rate_sp!=.


log close





use "$clean/04_POND_characteristics_hfc_check.dta", clear 

gen tilapia=0
replace tilapia=1 if strpos(c9, "1")==1|strpos(c9i, "Tilapia")

*drop inactive farmers
drop if a01==4 
*there are 17 obs with 777,  13 of them are tilapia and catfish so they are already adjusted
collapse (max) tilapia, by(HHID)

tab tilapia

save "$clean/temp/tilapiaallponds.dta", replace  

use "$clean/03_CAGE_Characteristics_hfc_check.dta",clear
gen tilapia=0
replace tilapia=1 if strpos(c1, "1")==1
collapse (max) tilapia, by(HHID)

tab tilapia

append using "$clean/temp/tilapiaallponds.dta"

collapse (max) tilapia, by(HHID)
tab tilapia
* in total, we have 462 tilapia farmers from production data (cage, small pond and big pond)
save "$clean/temp/tilapia_farmers.dta",replace

use "$clean/00_HOUSEHOLD_main_hfc_check.dta", clear

*drop inactive farmers
drop if a01==4

merge 1:1 HHID using "$clean/temp/tilapia_farmers.dta"

gen tilapia_hh=0
replace tilapia_hh=1 if strpos(c1, "1")==1|strpos(c1i, "Tilapia")|strpos(c12a, "1")==1|strpos(c12ai, "Tilapia")|strpos(c13a, "1")==1|strpos(c13ai, "Tilapia")
tab tilapia_hh
tab tilapia

tab tilapia_hh tilapia

*Error, HHs indicate tilapia farming in cage and pond chracteristics data, while the HH data disagree
count if tilapia==1 & tilapia_hh==0
list HHID region enumerator_n b3 if tilapia==1 & tilapia_hh==0









