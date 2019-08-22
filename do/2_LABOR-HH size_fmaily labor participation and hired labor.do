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
*LABOR: HH size, labor participation and hired labor 
****************************************************************
**************************************************
use "$inputs\aquaculture household survey-Module_I-Active_farmer-hh_size-G1a_G1b", clear
merge m:m setofg1a_g1b using "$outputs\00_HOUSEHOLD_main_hfc_check.dta" , keepusing (HHID a6 enumerator_n a01 a1 a2 a3 b3 b4 b6 submissiondate  )
keep if _merge==3 
drop _merge

gen age_group=""
replace age_group="under_5" 		if g0_id=="1" 
replace age_group="age_6to17" 		if g0_id=="2" 
replace age_group="age_18to30" 		if g0_id=="3" 
replace age_group="age_31to35" 		if g0_id=="4" 
replace age_group="age_36to50" 		if g0_id=="5" 
replace age_group="age_51to65" 		if g0_id=="6" 
replace age_group="over_65" 			if g0_id=="7" 

bys HHID: egen tot_male=sum(male)
bys HHID: egen tot_female=sum(female)
egen tot_family_size=rowtotal (tot_male tot_female)

order HHID a6 a1 a2 a3 b3 b4 b6 
order age_group, after( g0_name)

drop g0_id g0_name setofg1a_g1b
rename male male_
rename female female_

reshape wide male_ female_ , i(HHID a6 parent_key key submissiondate  tot_male tot_female tot_family_size) j(age_group) string

gen familysize_error=(tot_family_size ==0 | tot_family_size > 10)
label var familysize_error "Report error if family size is more than 10"

order HHID a6 a1 a2 a3 b3 b4 b6 
order parent_key key, after( familysize_error)

save "$intermediate\hh_age_group.dta", replace 

 
collapse (sum) male_age_18to30 - female_under_5 ///
(mean)tot_male tot_female tot_family_size,by (HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 parent_key submissiondate )

merge 1:m  parent_key using "$inputs\aquaculture household survey-Module_I-Active_farmer-G1_G25-G3_G6-GA_F_aquaculture"
drop if _merge==2
drop _merge

mvdecode younger_men - hrs_older_women, mv(999 = .) 

egen male_family_labor=rowtotal (younger_men older_men)
label var male_family_labor "Total male family/communal labor worked on SELECTED cages/ponds"

egen female_family_labor=rowtotal (younger_women older_women)
label var female_family_labor "Total female family/communal labor worked on SELECTED cages/ponds"

egen tot_family_labor=rowtotal (younger_men older_men younger_women older_women)
label var tot_family_labor "Total family/communal labor worked on SELECTED cages/ponds"

egen male_family_labrHr=rowtotal(hrs_younger_men hrs_older_men)
label var male_family_labrHr "Total male family/communal labor hour worked on SELECTED cages/ponds"

egen female_family_labrHr=rowtotal(hrs_younger_women  hrs_older_women)
label var female_family_labrHr "Total female family/communal labor hour worked on SELECTED cages/ponds"

egen totfamily_labrHr=rowtotal(hrs_younger_men hrs_older_men hrs_younger_women  hrs_older_women)
label var totfamily_labrHr "Total family/communal labor hour worked on SELECTED cages/ponds"

egen male_family_labrday=rowtotal(days_younger_men  days_older_men)
label var male_family_labrday "Total family/communal labor days worked on SELECTED cages/ponds"

egen female_family_labrday=rowtotal(days_younger_women  days_older_women)
label var female_family_labrday "Total family/communal labor days worked on SELECTED cages/ponds"

egen totfamily_labrday=rowtotal(days_younger_men  days_older_men days_younger_women  days_older_women)
label var totfamily_labrday "Total family/communal labor days worked on SELECTED cages/ponds"

save "$intermediate\02_Labor_family_gender_per_activity.dta", replace 
save "$hfc\02_Labor_family_gender_per_activity.dta", replace


collapse (mean) male_age_18to30 - tot_family_size (sum) younger_men - days_older_women male_family_labor - totfamily_labrday  ///
(first) submissiondate , by(HHID a6 enumerator_n a1 a2 a3 b3 b4 parent_key)
 
save "$outputs\02_LABOR_HH_labor_person_day.dta", replace 



*** merge admin and finance permanent labor
use "$outputs\02_Labor_HH_labor_person_day.dta", clear
merge 1:m parent_key using "$inputs\aquaculture household survey-Module_I-Active_farmer-G1_G25-G9_G19-G10_G15"
drop if _merge==2
drop _merge

mvdecode g10 - g11c, mv(999 = .) 

gen hired_male_mgt=g10
label var hired_male_mgt "What is the total number of MALE permanent employees for ${G9_name}"

gen hired_female_mgt=g11
label var hired_female_mgt "What is the total number of FEMALE permanent employees for ${G9_name}"

egen hired_tot_mgt=rowtotal(hired_male_mgt  hired_female_mgt)
label var hired_tot_mgt "Total number of male and female permanent managment employees "

*total permanent wage per cycle (6 month)
gen mgmt_salary_cycle=.
replace mgmt_salary_cycle=g11c*6 if g11ci==1
replace mgmt_salary_cycle=g11c*6*4.3 if g11ci==2	//convert weekly salary to 4.3 weeks a month times 1 cycle (6 month)	
label var mgmt_salary_cycle "Permanent employee (finance & mangt)salary per one full cycle (~6 month)"

*collapse (mean)male_age_18to30 - totfamily_labrday (sum) hired_male_mgt hired_female_mgt /// 
*hired_tot_mgt g10 g10a g10b g11 g11a g11b mgmt_salary_cycle (first) submissiondate key if (g10 !=. | g11 !=.), by(HHID a6 enumerator_n a1 a2 a3 b3 b4 g9_id g9_name parent_key)

gen male_permEmply_check_error=(((g10a + g10b)- g10) !=0)
gen female_permEmply_check_error=(((g11a + g11b)- g11) !=0)
label var male_permEmply_check_error "Check total men employee reported vs sum of age category"
label var female_permEmply_check_error "Check total women employee reported vs sum of age category"

gen salary_missing_error=((g10!=0 | g11!=0) & mgmt_salary_cycle==0)
gen numPermEmply_missing_error=(mgmt_salary_cycle!=0 & (g10==0 & g11==0))
label var salary_missing_error "Salary of permanent emplyee missing"
label var numPermEmply_missing_error "Number of permanent emplyee missing"

order g9_id g9_nam,after (totfamily_labrday)

mvdecode mgmt_salary_cycle, mv(0 = .) 
decode g11ci, gen (g11ci_unit)
order g11ci_unit, after (g11ci )
save "$outputs\02_LABOR_hired_finance_mgmt_gender_per_activity.dta", replace 
save "$hfc\02_LABOR_hired_finance_mgmt_gender_per_activity.dta", replace



****merge hired labor--daily 
use "$inputs\aquaculture household survey-Module_I-Active_farmer-G1_G25-G9_G19-G17_G19", clear
merge m:m setofg17_g19 using "$outputs\00_HOUSEHOLD_main_hfc_check.dta", keepusing (HHID a6 enumerator_n a01 a1 a2 a3 b3 b4 b6 c2 c3 c7 c8 submissiondate)
keep if _merge ==3
drop _merge
order HHID a6 enumerator_n a1 a2 a3 b3 b4 b6 c2 c3 c7 c8
order parent_key key setofg17_g19, last


egen hired_male=rowtotal(hyounger_men  holder_men)
label var hired_male "Number of hired male laborer-count"

egen hired_female=rowtotal(hyounger_women holder_women)
label var hired_female "Number of hired female laborer-count"

egen tot_hired_labor=rowtotal(hired_male hired_female)
label var tot_hired_labor "Number of total hired laborer-count"

egen hired_male_hr=rowtotal (hrs_hyounger_men  hrs_holder_men)
label var hired_male_hr "Total number hired male labor hours per day"  

egen hired_female_hr=rowtotal (hrs_hyounger_women  hrs_holder_women)
label var hired_female_hr "Total number hired female labor hours per day" 

egen tot_hired_labHr=rowtotal(hrs_hyounger_men  hrs_holder_men hrs_hyounger_women  hrs_holder_women)
label var tot_hired_labHr "Total number hired labor hours per day"  

egen hired_male_day=rowtotal(days_hyounger_men days_holder_men)
label var hired_male_day "Total number hired male labor days per week" 

egen hired_female_day=rowtotal(days_hyounger_women days_holder_women)
label var hired_female_day "Total number hired female days per week" 

egen tot_hired_labrday=rowtotal(days_hyounger_men days_holder_men days_hyounger_women days_holder_women)
label var tot_hired_labrday "Total number hired male + female labor days" 

order parent_key key setofg17_g19, last

**merge number and volume/area of cage/pond
merge m:m parent_key using "$outputs\03_CAGE_Characteristics_hfc_check.dta", keepusing (c2 c3 avgProdn_cage cageMostComnV)
drop _merge
merge m:m parent_key using "$outputs\04_POND_characteristics_hfc_check.dta" , keepusing (c7 c8 biggestPondArea)
drop if _merge==2
drop _merge


***wage rate (1=per day, 2=per hour, 3=whole activity, 4=whole pond/cage 5=per month 6=other)
gen daily_hired_wage=g20a
label var daily_hired_wage "daily wage rate per activity"
replace daily_hired_wage= g20 							if g20a== 1
replace daily_hired_wage=g20*8 							if g20a== 2 //assuming 8 working hours per day
replace daily_hired_wage=g20 / tot_hired_labrday		if g20a== 3
replace daily_hired_wage=(g20 / c3)						if (g20a== 4 & c3!=.)
replace daily_hired_wage=(g20 / c8)						if (g20a== 4 & c8!=.)
replace daily_hired_wage=(g20 /(6*8*4.3)) 				if g20a== 5 //month translated to day as 8hrs per day for 6 days a week
*replace daily_wage=g20 *		if g20a== 6

**wage rate (1=per day, 2=per hour, 3=whole activity, 4=whole pond/cage 5=per month 6=other)
gen daily_male_wage=g22
label var daily_male_wage "daily wage rate per activity-male"
replace daily_male_wage=g22 							if g22i== 1
replace daily_male_wage=g22*8 							if g22i== 2
replace daily_male_wage=g22 / hired_male_day			if g22i== 3
replace daily_male_wage=(g22 / c3)						if (g22i== 4 & c3!=.)	
replace daily_male_wage=(g22 /  c8)						if (g22i== 4 & c8!=.)
replace daily_male_wage=(g22 /  (6*8*4.3)) 			 	if g22i== 5 
*replace daily_male_wage=g20 					if g22ii== 6

gen daily_female_wage=g23
label var daily_female_wage "daily wage rate per activity-female"
replace daily_female_wage=g23 							if g23i== 1
replace daily_female_wage=g23*8 						if g23i== 2 //assuming 8 working hours per day
replace daily_female_wage=g23 /	hired_female_day		if g23i== 3
replace daily_female_wage=(g23 / c3)					if (g23i== 4 & c3!=.)
replace daily_female_wage=(g23 / c8)					if (g23i== 4 & c8!=.)
replace daily_female_wage=(g23 / (6*8*4.3))				if g23i== 5 
*replace daily_male_wage=g20 					if g20a== 6

***wage rate (1=per day, 2=per hour, 3=whole activity, 4=whole pond/cage 5=per month 6=other)
gen tot_hired_wagePerCycle=daily_hired_wage * tot_hired_labrday
gen tot_male_hired_wagePerCycle=daily_male_wage * hired_male_day
gen tot_female_hired_wagePerCycle=daily_female_wage * hired_female_day

label var tot_hired_wagePerCycle "Total hired labor cost per cycle per cage/pond"
label var tot_male_hired_wagePerCycle "Total male hired labor cost per cycle per cage/pond "
label var tot_female_hired_wagePerCycle "Total female hired labor cost per cycle per cage/pond"

**hired labor cost per m^3 or m^2
gen hired_wage_per_m3=.
label var hired_wage_per_m3 "Wage rate on cage per m3 per cycle"
replace hired_wage_per_m3=tot_hired_wagePerCycle / cageMostComnV	 	if c3!=.

gen hired_wage_per_m2=.
label var hired_wage_per_m2 "Wage rate on pond per m2 per cycle"
replace hired_wage_per_m2=tot_hired_wagePerCycle / biggestPondArea	 	if c8!=.


merge m:m parent_key using "$outputs\02_LABOR_HH_labor_person_day.dta", keepusing(totfamily_labrday)
drop if _merge==2==2
drop _merge

gen family_wage_per_m3=.
label var family_wage_per_m3 "Family wage rate per m3 per cycle"
replace family_wage_per_m3=(totfamily_labrday * daily_hired_wage) / cageMostComnV	 	if c3!=.

gen family_wage_per_m2=.
label var family_wage_per_m2 "Family wage rate per m2 per cycle"
replace family_wage_per_m2=(totfamily_labrday * daily_hired_wage) / biggestPondArea	 	if c8!=.

save "$outputs\02_LABOR_hired_wage_family_wage_hfc_check.dta", replace
save "$hfc\02_LABOR_hired_wage_family_wage_hfc_check.dta", replace

