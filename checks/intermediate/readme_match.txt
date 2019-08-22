paste the the following variables name starting from i

" matching_score hhid_original	b3	HHID	r_id	zz_id	dist_id	hh_numb	a1	a2	a2_i "

drop hhid_original
rename b3 Main_respondent_b3
rename a1 a1_main
rename a2 a2_main
rename a2_i a2_i_main


cross check the matching status for scores less than 100 percent. To record the status add "ID_remark" field
and lable those flawed matches as "not matched"



