* For aquaculture survey
****************************OPTIONS******************************
clear
#delimit ; 
set more off; capture log close; clear matrix;
label drop _all; 
#delimit cr 
*****************************************************************.
global root	     		"C:\Users\\MKEDIRJEMAL\Dropbox (IFPRI)\Catherine\Aquaculture\July17"
global inputs    		"$root\survey_july17"
global intermediate		"$root\checks\intermediate"
global outputs    		"$root\checks"
global hfc				"$root\hfc_check\05_data\02_survey"
****************************************************************
*HOUSEHOLD LEVEL - Household identification 
****************************************************************
use "$inputs\aquaculture household survey.dta", clear

*Drop pretest values
keep if submissiondate > tc(05jun2019 15:00:00)

order hhid
rename hhid HHID

mvdecode HHID a6 a1 a2 a3  c14a c14b e49, mv(999 = .)  
mvdecode  a6 a1 a2 a3 c14b e49 e49, mv(666 = .)  

**Decode enumerato id and keep both in the report
decode a6, gen(enumerator_n)
label var enumerator_n "Enumerator name"
order a6 enumerator_n, after(HHID)

*hhid duplication or missing error
gen n = _n
bysort HHID: egen temp = count(n)
gen dup_hhid_error = (temp != 1)
drop temp n
label var dup_hhid_error "hhid duplicates"
order dup_hhid_error, after (HHID)

gen missing_hhid_error=(HHID==.) //initially HHID replaced as missing
label var missing_hhid_error "HHID missing"
order missing_hhid_error, after (dup_hhid_error)

*decode region
*decode a1, generate(region_name_a1)
gen region=""
replace region="Brong-Ahafo" 		if a1=="BA"
replace region="Greater Accra" 		if a1=="GA"
replace region="Volta" 				if a1=="VR"
replace region="Ashanti" 			if a1=="AS"
replace region="Central" 			if a1=="CR"
replace region="Eastern" 			if a1=="ER"
replace region="Western" 			if a1=="WR"

order region, after(a1)

*label define regName 1 "Brong-Ahafo" 2 "Greater Accra" 3 "Volta"  4 "Ashanti" 5 "Central" 6 "Eastern" 7 "Western"
*label values region regName

*Check missing admin units
gen reg_dist_error=(a1=="" | a2==.)
lab var reg_dist_error "Check missing region or district" 
order reg_dist_error, after(a2)


*Check if lat/lon are missing
gen gpscheck_error =(a4latitude == . | a4longitude == .)
lab var gpscheck_error "Check gps if lat or long are missing"
order gpscheck_error, after(a4longitude)



*Check missing or farthest farm distance
gen farm_dist_missing_error=(b2 ==. |  b2 ==0)
*replace farm_dist_missing_error=1 if  (b2 > 20 & b2i ==1) //above 20km far
*replace farm_dist_missing_error=1 if  (b2 > 12.4274 & b2i ==2) //above 20km far
*replace farm_dist_error=1 if  (b2 > 90 & b2i ==5)
lab var farm_dist_missing_error "missing farm distance"
order farm_dist_missing_error, after(b2i)

*Check  if the interview was consensual  
gen consentcheck_error= (consent!=1 )
lab var consentcheck_error "Flag not consensual interview"
order consentcheck_error, after(consent)

*gen incomplet_interv_error=(consent!=5 | consent!=6 | consent!= 7)
*lab var incomplet_interv_error "Check inmplete/partial interview"
*order incomplet_interv_error, after(consent)


*check gender vs hh type
gen gender_hhtyp_error=(b4==1 & b7==0 & b11==2)
lab var gender_hhtyp_error "Check female owner vs hh type-consistent"
order gender_hhtyp_error, after(b4)



*Check out of range age (>80)   
gen respondent_age_error= (b8 > 80 | b8 ==.) 
lab var respondent_age_error "respondent age too old or missing"
order respondent_age_error, after(b8)

*Check out of range age (>80)   
gen owner_age_error= (b8a > 80 | b8a ==.) 
lab var owner_age_error "Owner age too old or missing"
order owner_age_error, after(b8a)
save "$outputs\00_HOUSEHOLD_main_hfc_check", replace

/*
keep HHID deviceid subscriberid simid caseid a1 a2 a3 a4latitude a4longitude ///
consent a6 a7 b2 b3 b4 b6 b7 b8 b10 b11 b15 c1 c2 c3 c4_xb  c4_xc_i c4_xc_ii ///
c4_xd_i c4_xd_i_i c4_xd_ii c4_xd_ii_i c4_xe c4_xe_ii f13 f19 key ///
c7 c8  parent_key submissiondate setof*

order HHID a6 b3 b4 b6
*tempfile farmer_info
*save `farmer_info'
*/
destring c4_xk , replace



order HHID a1 a2

gen r_id=""
replace r_id="1" if a1=="AS"
replace r_id="2" if a1=="BA"
replace r_id="3" if a1=="ER"
replace r_id="4" if a1=="VR"

gen zz_id=a2 
gen dist_id=a2_i 
replace dist_id=77 if a2_i==.

order HHID r_id zz_id dist_id a1 a2 a2_i
bys r_id zz_id dist_id: gen hh_numb=_n
order HHID r_id zz_id dist_id hh_numb a1 a2 a2_i

tostring dist_id zz_id hh_numb, replace
*replace r_id=("0" + r_id) if strlen(r_id)==1
replace zz_id=("0" + zz_id) if strlen(zz_id)==1
replace zz_id=substr(zz_id,1,2) if strlen(zz_id)>=4


replace dist_id=("0" + dist_id) if strlen(dist_id)==1
replace dist_id=substr(dist_id,1,2) if strlen(dist_id)==3
replace dist_id="99" if a2_i==529


replace hh_numb=("0" + hh_numb) if strlen(hh_numb)==1

gen hhid_new=(r_id + zz_id + dist_id + hh_numb)
order hhid_new, after(HHID)

rename HHID hhid_original
rename hhid_new HHID

order hhid_original b3 HHID  r_id zz_id dist_id hh_numb a1 a2 a2_i

save "$outputs\00_HOUSEHOLD_main_hfc_check", replace
save "$hfc\00_HOUSEHOLD_main_hfc_check", replace
export delimited using "$intermediate\Main_respondent.csv", replace

