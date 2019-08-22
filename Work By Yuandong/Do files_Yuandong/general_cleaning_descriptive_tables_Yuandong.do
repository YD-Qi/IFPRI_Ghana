/* Data documentation by Yuandong Qi:

"00_HOUSEHOLD_main_hfc_check" 
it records at HH level, demongraphic info and farming info at HH level
respondent/owner/manager's male, age, edu, distance to farm
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


*************************

* DATA CLEANING/PREPARING

*************************

use "$clean/00_HOUSEHOLD_main_hfc_check.dta",clear

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

tab region c1 if active==1
tab region c1 if active==0

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


* rename respondent's info
rename b7 male_respondent
rename b8 age_respondent
rename b9 edu_respondent
rename distance distance_respondent
rename b4 role_respondent
rename b15 ownerManager

replace edu_respondent=5 if edu_respondent==777 & b9i=="Form 1"
replace edu_respondent=5 if edu_respondent==777 & b9i=="Form 4"
replace edu_respondent=1 if edu_respondent==777 & b9i=="O level"
replace edu_respondent=6 if edu_respondent==777 & b9i=="Teacher Training College"
replace edu_respondent=6 if edu_respondent==777 & b9i=="Tourism"
replace edu_respondent=6 if edu_respondent==777 & b9i=="Deferred Course at University at level 200"
replace edu_respondent=6 if edu_respondent==777 & b9i=="Chatered institute of management"

* reconstruct owner's info
gen male_owner=b7a 
replace male_owner=male_respondent if male_owner==. & role_respondent==1
replace male_owner=male_respondent if male_owner==. & role_respondent==2 & ownerManager==1



gen age_owner=b8a
replace age_owner=age_respondent if age_owner==. & role_respondent==1
replace age_owner=age_respondent if age_owner==. & role_respondent==2 & ownerManager==1

gen edu_owner=b9a
replace edu_owner=edu_respondent if edu_owner==. & role_respondent==1
replace edu_owner=edu_respondent if edu_owner==. & role_respondent==2 & ownerManager==1
replace edu_owner=1 if edu_owner==777 & b9ai=="Can't tell"
replace edu_owner=1 if edu_owner==777 & b9ai=="Dk"
replace edu_owner=1 if edu_owner==777 & b9ai=="O level"
replace edu_owner=7 if edu_owner==777 & b9ai=="The farm is for the university of Ghana, legon"
replace edu_owner=8 if edu_owner==777 & b9ai=="Professor"

gen distance_owner = b2a if b2ai==1
replace distance_owner=0 if b2a==0
replace distance_owner=b2a/1.60934 if b2i==2 
replace distance_owner=b2a/1000 if b2i==3
replace distance_owner=b2a/15 if b2i==5
replace distance_owner=distance_respondent if distance_owner==. & role_respondent==1
replace distance_owner=distance_respondent if distance_owner==. & role_respondent==2 & ownerManager==1


* reconstruct manager's info
gen male_manager=b6c
replace male_manager=male_respondent if male_manager==. & role_respondent==2
replace male_manager=male_respondent if male_manager==. & role_respondent==1 & ownerManager==1



gen age_manager=b7c 
replace age_manager=age_respondent if age_manager==. & role_respondent==2
replace age_manager=age_respondent if age_manager==. & role_respondent==1 & ownerManager==1

gen edu_manager=b8c
replace  edu_manager=edu_respondent if edu_manager==. & role_respondent==2
replace edu_manager=edu_respondent if edu_manager==. & role_respondent==1 & ownerManager==1
replace edu_manager=5 if edu_manager==777 & b8ci=="Form 4"

gen distance_manager = b2c if b2ci==1
replace distance_manager=0 if b2c==0
replace distance_manager=b2c/1.60934 if b2ci==2 
replace distance_manager=b2c/1000 if b2ci==3
replace distance_manager=b2c/15 if b2ci==5
replace distance_manager=distance_respondent if distance_manager==. & role_respondent==2
replace distance_manager=distance_respondent if distance_manager==. & ownerManager==1

* number of average ponds/cages owned/used by HH
rename (c7 c8 c2 c3) (n_ponds_owned n_ponds_used n_cages_owned n_cages_used) 


* age category
recode age_respondent (min/35=1 youth) (36/50=2 midAge) (51/max=3 Old), gen(age_respondent_range)
recode age_owner (min/35=1 youth) (36/50=2 midAge) (51/max=3 Old), gen(age_owner_range)
recode age_manager (min/35=1 youth) (36/50=2 midAge) (51/max=3 Old), gen(age_manager_range)



save "$newData/00_HOUSEHOLD_main_hfc_check_YQ.dta",replace


use "$clean/04_POND_characteristics_hfc_check.dta", clear 

gen active=1 if a01>=1&a01<=3
replace active=0 if a01==4

gen tilapia_only=0
replace tilapia_only=1 if c9=="1"
gen tilapia_mix=0
replace tilapia_mix=1 if c9=="1 2"|c9=="1 2 3"|c9=="1 3"
rename a1 region

save "$newData/04_POND_characteristics_hfc_check_YQ.dta", replace 




*************************

* SUMMARY STATISTICS

*************************
use "$newData/00_HOUSEHOLD_main_hfc_check_YQ.dta",clear

*Table 1
tab region culture if active==1
tab region culture if active==0

*Table 2. Average number of ponds and cages owned and operational per household
tabstat n_ponds_owned n_ponds_used n_cages_owned n_cages_used if active==1,  by(region)



use "$newData/04_POND_characteristics_hfc_check_YQ.dta", clear

* Table 3.  Types of tilapia ponds (single and mixed)
tab region if tilapia_only==1 & active==1
tab region if tilapia_mix==1 & active==1
tab region if tilapia_only==1 & active==0
tab region if tilapia_mix==1 & active==0

*Table 4.1 Dimension of tilapia ponds by region (operational tilapia ponds only)
graph box c10a_lengthm
graph box c10b_widthm

foreach var of varlist c10a_lengthm c10b_widthm c10c_deepm c10d_shallowm indivPondArea individualPondVol{
tabstat `var' if (tilapia_only==1 | tilapia_mix==1) & active==1 & c10a_lengthm<=100 & c10b_widthm<=100, by(region) s(n mean median sd min max) c(s)
}

*Table 4.2 Dimension of tilapia ponds by region (both active and inactive tilapia ponds)
foreach var of varlist c10a_lengthm c10b_widthm c10c_deepm c10d_shallowm indivPondArea individualPondVol{
tabstat `var' if (tilapia_only==1 | tilapia_mix==1) & c10a_lengthm<=100 & c10b_widthm<=100, by(region) s(n mean median sd min max) c(s)
}


use "$clean/03_CAGE_Characteristics_hfc_check.dta",clear
drop if c1_name=="Cat fish only"
*table 5.1 cage size 
tab cage_size_name1

* table 5.2 most common cage size
tab c4a
tab c4i if c4a==777

*table xx: FUTURE TREND
use "$clean/00_HOUSEHOLD_main_hfc_check_CRR.dta", clear
*plan to increase, decrease cage production?
tab c23
bys region: tab c23

*plan to increase, decrease pond production?
tab c24
bys region: tab c24

*table xx: PAST TREND
*production decreasing/increasing over past 5 years?
tab c15
bys region: tab c15
tab c15 if pond==1

use "$clean/03_CAGE_Characteristics_hfc_check.dta",clear
tab c6
bys region: tab c6

use "$newData/00_HOUSEHOLD_main_hfc_check_YQ.dta", clear
gen pond=culture==1
replace pond=1 if culture==3
gen cage=culture==2
replace cage=1 if culture==3

keep if active==1
* table XX: DEMOGRAPHIC INFO OF RESPONDENTS, OWNERS, MANAGERS
*role
tab region role_respondent, row nofreq

*male
tab region male_respondent, row nofreq

*age
tabstat age_respondent, by(region) s(n mean median sd min max)

*marital
tab region b10, row nofreq

bys region: tab b10

* edu
tab region edu_respondent, row nofreq

* polygamous or monogamous
tab region b12, row nofreq

*religion
tab region b14, row nofreq

*distance
tabstat distance_respondent if distance_respondent<500, by(region) s(n mean median sd min max)

*OWNER's info summary
sum male_respondent age_respondent edu_respondent distance_respondent 
sum male_owner age_owner edu_owner distance_owner 
sum male_manager age_manager edu_manager distance_manager
*male
tab region male_owner, row nofreq

*age
tabstat age_owner if age_owner<100, by(region) s(n mean median sd min max)

* edu
tab region edu_owner, row nofreq


*distance
tabstat distance_owner if distance_owner<500, by(region) s(n mean median sd min max)

* table 5 manager's info
*male
tab region male_manager, row nofreq

*age
tabstat age_manager if age_manager<100, by(region) s(n mean median sd min max)

* edu
tab region edu_manager, row nofreq

*distance
tabstat distance_manager if distance_manager<500, by(region) s(n mean median sd min max)

*table age distribution
tab region age_respondent_range
tab region age_respondent_range, row nofreq
tab region age_owner_range
tab region age_owner_range, row nofreq
tab region age_manager_range
tab region age_manager_range, row nofreq

*table xx: PRACTICE CHANGED?
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

des d6ai d6aii d6aiii d6aiv d6av d6avi d6avii d6aviii d6aix d6ax d6axi
foreach var of varlist d6ai d6aii d6aiii d6aiv d6av d6avi d6avii d6aviii d6aix d6ax d6axi{
tabstat `var' if `var'<=1, by(region) s(n mean)
}

foreach var of varlist d6ai d6aii d6aiii d6aiv d6av d6avi d6avii d6aviii d6aix d6ax d6axi{
tabstat `var' if `var'<=1 & pond==1 & (region=="Eastern"|region=="Volta"), by(region) s(n mean)
}
foreach var of varlist d6ai d6aii d6aiii d6aiv d6av d6avi d6avii d6aviii d6aix d6ax d6axi{
tabstat `var' if `var'<=1 & cage==1 & (region=="Eastern"|region=="Volta"), by(region) s(n mean)
}

*table xx: SPECIFIC CHANGES
foreach var of varlist d6bi d6bii d6biii d6biv d6bv d6bvi d6bvii d6bviii d6bix d6bx d6bxi{
table `var', stubwidth(40) left
}

foreach var of varlist d6bi d6bii d6biii d6biv d6bv d6bvi d6bvii d6bviii d6bix d6bx d6bxi{
table `var', by (region) stubwidth(40) left
}

foreach var of varlist d6bi d6bii d6biii d6biv d6bv d6bvi d6bvii d6bviii d6bix d6bx d6bxi{
table `var' if pond==1 & (region=="Eastern"|region=="Volta"), by (region) stubwidth(40) left
}
foreach var of varlist d6bi d6bii d6biii d6biv d6bv d6bvi d6bvii d6bviii d6bix d6bx d6bxi{
table `var'if cage==1 & (region=="Eastern"|region=="Volta"), by (region) stubwidth(40) left
}

*BEST PRACTICE RECOMMENDATIONS
foreach var of varlist d6di d6dii d6diii d6div d6dv d6dvi d6dvii d6dviii d6dix d6dx d6dxi{
table `var', stubwidth(40) left
}

foreach var of varlist d6di d6dii d6diii d6div d6dv d6dvi d6dvii d6dviii d6dix d6dx d6dxi{
table `var', by(region) stubwidth(40) left
}

foreach var of varlist d6di d6dii d6diii d6div d6dv d6dvi d6dvii d6dviii d6dix d6dx d6dxi{
table `var' if pond==1 & (region=="Eastern"|region=="Volta"), by (region) stubwidth(40) left
}
foreach var of varlist d6di d6dii d6diii d6div d6dv d6dvi d6dvii d6dviii d6dix d6dx d6dxi{
table `var' if cage==1 & (region=="Eastern"|region=="Volta"), by (region) stubwidth(40) left
}
*table xx: FEED QUALITY PERCEPTION

*feed and region
tab region e39e, row nofreq
*feed and its type
*note on farm production is not rated
tab e36e e39e, row nofreq
tab e35i e39e, row nofreq
table e35i, stubwidth(40) left

tab if e36e==5

* first fingerling and region
tab region e39a, row nofreq
* fingerling and source
tab e36a e39a, row nofreq
tab e2i e39a, row nofreq
table e2i, stubwidth(40) left

* table xx: FEED AVAILABILITY PERCEPTION
tab region e40e_i
tab region e40e_i, row nofreq
*feed and its type
tab e36e e40e_i
tab e36e e40e_i, row nofreq


* table xx: FEED affordability PERCEPTION
tab region e41e_i
tab region e41e_i, row nofreq
*feed and its type
tab e36e e41e_i
tab e36e e41e_i, row nofreq



foreach var of varlist e39a e39n e39o e39c e39d e39c_i e39_i e39e e39f e39e_i e39f_i e39g e39h e39k e39p e39q e39i e39zi e39j e39m e39l{
tab `var' if pond==1
}

tab region edu_owner, row nofreq

*table xx: MORTALITY RATE OF FINGERLING DURING TRANSPORT
tabstat e25a if active==1, by(region) s(n mean median sd min max) c(s)


tab region if active==1& pond==1&tilaponly==1
tab region if active==1& pond==1&tilapiacatfish==1
tab region if active==1& pond==1&tilcatheter==1
tab region if active==1& pond==1&tilapiaheterotis==1

tab region if active==1& cage==1&tilaponly==1
tab region if active==1& cage==1&tilapiacatfish==1
tab region if active==1& cage==1&tilcatheter==1
tab region if active==1& cage==1&tilapiaheterotis==1


* table7: have hatchery or not? less than 5%
bys culture: tab region c16 if active==1
bys culture: tab region c16 if active==0


* table 8: months of production cycle (big tilapia pond)
bys culture: tabstat  c12_ibi if c12_ibi<999 & active==1, by(region) s(n mean median sd min max) c(s)

* months of production cycle (small tilapia pond)
bys culture: tabstat  c13_ibi if c13_ibi<999 & active==1, by(region) s(n mean median sd min max) c(s)



* ERROR: active famers missing tilapia's months of production cycle (big and small ponds)
list region enumerator_n HHID name_respondent phone_respondent if c12_ibi==999 & a01==1
list region enumerator_n HHID name_respondent phone_respondent if c13_ibi==999 & a01==1


*table 12: learning source
* learning about fish farming for the first time from extension agent?
gen learning_source=strpos(d2, "1")
tab learning_source
bys culture: tab region learning_source
* seek advice?
bys culture: tab region d3

* advice sources is extension agent?
gen advice_source=strpos(d4, "1")
tab advice_source
bys culture: tab region advice_source


* table 15: still do crop farming?
gen crop_farming=strpos(d14, "2")
tab crop_farming
bys culture: tab crop_farming


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

foreach var of varlist e304  e307  e336  e338a{
tab `var'
}
foreach var of varlist e304a e307a e336a e338b{
tab `var'
}

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

use "$clean/04_POND_BIG_pond_production_hfc_check.dta", clear

rename (a6 a1 b3) (name_enumerator region name_respondent)
tab c12a_name
* ERROR: someone reported Tilapia and Catfish mixed
list HHID name_enumerator region name_respondent c12a_name if c12a_name=="Tilapia and catfish"

*stocking rate (big pond)
bys c12a_name: tabstat bp_stocking, by(region) s(n mean median sd min max)

* production rate kg/m2 (big pond)
* WARNING: too small numbers
bys c12a_name: tabstat bgp_prdn_kg_m2, by(region) s(n mean median sd min max)

*survival rate expressed in % (big pond)
gen survival_rate_bp=bp_survival if bp_survival_i == 2
replace survival_rate_bp=(bp_survival/bp_stocking)*100 if bp_survival_i == 1

bys c12a_name: tabstat survival_rate_bp if survival_rate_bp<=100, by(region) s(n mean median sd min max)

list HHID name_enumerator region name_respondent c12a_name survival_rate_bp bp_survival bp_stocking bp_survival_i if  survival_rate_bp>100 & survival_rate_bp<.


use "$clean/04_POND_SMALL_pond_production_hfc_check.dta", clear
rename (a6 a1 b3) (name_enumerator region name_respondent)
* ERROR: someone reported Tilapia and Catfish mixed
tab c13a_name
list HHID name_enumerator region name_respondent c13a_name if c13a_name=="Tilapia and Catfish"

*survival rate expressed in % (small pond)
gen survival_rate_sp=(sp_survival/sp_stocking)*100 if sp_survival_i == 1
replace survival_rate_sp=sp_survival if sp_survival <= 100


*stocking rate (small pond)
bys c13a_name: tabstat sp_stocking, by(region) s(n mean median sd min max)

* production rate kg/m2 (small pond)
* WARNING: too small numbers
bys c13a_name: tabstat sp_prdn_kg_m2, by(region) s(n mean median sd min max)

*survival rate expressed in % (small pond)
bys c13a_name: tabstat survival_rate_sp if survival_rate_sp<=100, by(region) s(n mean median sd min max)

list HHID name_enumerator region name_respondent survival_rate_sp sp_survival c13a_name sp_stocking sp_survival_i if survival_rate_sp>100&survival_rate_sp!=.


* Fingerling size
use "$clean/06_FINGERLING_production_hfc_check.dta",clear
rename (a1 a6 b3) (region name_enumerator name_respondent)

*size of fingerling produced
bys c18_name: tabstat c20, by(region) s(n mean median sd min max)

* hatchery production (what is the unit, number?)
bys c18_name: tabstat c21a, by(region) s(n mean median sd min max)

*survival rate by number and percent, note c27i is missing for these reported 999 or 0 on c27
bys c18_name: tabstat c27 if c27i==1, by(region) s(n mean median sd min max)
bys c18_name: tabstat c27 if c27i==2, by(region) s(n mean median sd min max)

list region name_enumerator HHID name_respondent c16 c27 c27i if c27!=.&c27i==.

* growth rate (days took from 2g to 5g)
*ERROR 6 report 999
bys c18_name: tabstat c26 if c26!=999, by(region) s(n mean median sd min max)

list region name_enumerator name_respondent c16 c26 if c26==999

* fingerling production increasing, decreasing?
bys c18_name: tab c22 by(region)


*POND characteristics
use "$clean/04_POND_characteristics_hfc_check.dta",clear

gen region_species= a1+ "-" + pd_species

tab a1
tab pd_species

tabstat indivPondArea individualPondVol, by(a1) s(n mean median sd min max) c(s)

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









