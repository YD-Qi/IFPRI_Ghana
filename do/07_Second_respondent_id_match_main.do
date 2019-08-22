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
*****************************************************************.
use "$inputs\aquaculture household survey 2nd respondent.dta", clear

order hhid a9 a1 a1i a2 a2i a2_i a2_ii
save "$intermediate\00_Second_respondent.dta", replace
export delimited using "$intermediate\Second_respondent.csv", replace

*export excel "$intermediate\Second_respondent.xlsx", firstrow(variables) replace






***pause here--do fuzzy matching (main hh and second respondent) using python script



clear
import excel using   "$intermediate\match_main_vs_second_respondent.xlsx",   firstrow 
save "$intermediate\match_main_vs_second_respondent.dta", replace

clear
use "$intermediate\00_Second_respondent.dta", clear
merge 1:1 hhid a9 a1 a2_ii using "$intermediate\match_main_vs_second_respondent.dta" ,keepusing(Main_respondent_b3 HHID_new r_id zz_id dist_id hh_numb match_score ID_remark)
drop _merge
rename hhid hhid_2ndresp
rename HHID_new HHID
rename a9 mainResp_2nd_a9
order hhid_2ndresp mainResp_2nd_a9 a1 a2 a2_i match_score HHID r_id zz_id dist_id hh_numb ID_remark

save "$outputs\07_Match_main_vs_second_respondent.dta", replace

keep if ID_remark=="Not matched"
save "$root\error_summary\unmatched_secondary_respondent", replace
