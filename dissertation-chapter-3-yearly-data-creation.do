***=====================================================***
*	CHAPTER 3 DATA CREATION
*	FIRM-YEAR LEVEL DATASET COMBINING
*		CSRHUB/CSTAT AND KLD
***=====================================================***

							***===============***
							*	CLEAN KLD DATA	*
							***===============***
/// IMPORT DATA
use data\20190402-all-kld-downloaded-from-wrds.dta, clear

///	ORDER AND SORT
rename companyname firm
replace firm=upper(firm)
order firm year ticker, first
sort firm year

///	GENERATE
gen row_id_kld=_n

///	LABEL
foreach var of varlist * {
	local lab `: var label `var''
	label var `var' "(KLD) `lab'"
}

label var firm "(KLD) Firm name"
label var companyid "(KLD) Company numerical identifier"
label var cusip "(KLD) CUSIP firm identifier (8-digit max length)"
label var ticker "(KLD) Ticker symbol"

label var cgov_str_g "(KLD) Corruption and instability"
label var cgov_str_h "(KLD) Financial system risk"
label var com_str_h "(KLD) Community engagement"
label var div_str_h "(KLD) Employment of underrepresented groups (ended after 2013)"
label var env_str_h "(KLD) Natural resource use - water stress"
label var env_str_i "(KLD) Natural resource use - biodiversity and land use"
label var env_str_j "(KLD) Natural resource use - raw material sourcing"
label var env_str_k "(KLD) Natural resource use - financing environmental impact"
label var env_str_l "(KLD) Environmental opportunities - green buildings"
label var env_str_m "(KLD) Environmental opportunities in renewable energy"
label var env_str_n "(KLD) Waste management - electronic waste"
label var env_str_o "(KLD) Climate change - energy efficiency"
label var env_str_p "(KLD) Climate change - product carbon footprint"
label var env_str_q "(KLD) Climate change - insuring climate change risk"
label var emp_str_i "(KLD) Variable missing from kld data dictionary"
label var emp_str_j "(KLD) Variable missing from kld data dictionary"
label var emp_str_k "(KLD) Variable missing from kld data dictionary"
label var emp_str_l "(KLD) Human capital development"
label var emp_str_n "(KLD) Controversial sourcing (start 2013, previously hum-str-x)"
label var hum_con_h "(KLD) Operations in Sudan"
label var pro_str_d "(KLD) Customer controversies not covered by other rating variables"
label var pro_str_e "(KLD) Social opportunities - access to communications"
label var pro_str_f "(KLD) Social opportunities - opportunities in nutrition and health"
label var pro_str_g "(KLD) Product safety - chemical safety"
label var pro_str_h "(KLD) Product safety - financial product safety"
label var pro_str_i "(KLD) Product safety - privacy and data security"
label var pro_str_j "(KLD) Product safety - responsible investment"
label var pro_str_k "(KLD) Product safety - insuring health and demographic risk"
label var pro_con_g "(KLD) Variable missing from kld data dictionary"

label var row_id_kld "(KLD) Unique ID for each row of data"


///	CREATE AGGREGATE VARIABLES

***	Sum variables	/*	The sum variables included in KLD are wrong	*/
drop *num

*	Sum of 1s
egen sum_alc_con = rowtotal(alc_con_a alc_con_x)
egen sum_cgov_con = rowtotal(cgov_con_b cgov_con_f cgov_con_g cgov_con_h cgov_con_i cgov_con_j cgov_con_k cgov_con_l cgov_con_m cgov_con_x)
egen sum_cgov_str = rowtotal(cgov_str_a cgov_str_c cgov_str_d cgov_str_e cgov_str_f cgov_str_g cgov_str_h cgov_str_x)
egen sum_com_con = rowtotal(com_con_a com_con_b com_con_d com_con_x)
egen sum_com_str = rowtotal(com_str_a com_str_b com_str_c com_str_d com_str_f com_str_g com_str_h com_str_x)
egen sum_div_con = rowtotal(div_con_a div_con_b div_con_c div_con_d div_con_x)
egen sum_div_str = rowtotal(div_str_a div_str_b div_str_c div_str_d div_str_e div_str_f div_str_g div_str_h div_str_x)
egen sum_emp_con = rowtotal(emp_con_a emp_con_b emp_con_c emp_con_d emp_con_f emp_con_g emp_con_x)
egen sum_emp_str = rowtotal(emp_str_a emp_str_b emp_str_c emp_str_d emp_str_f emp_str_g emp_str_h emp_str_i emp_str_j emp_str_k emp_str_l emp_str_n emp_str_x)
egen sum_env_con = rowtotal(env_con_a env_con_b env_con_c env_con_d env_con_e env_con_f env_con_g env_con_h env_con_i env_con_j env_con_k env_con_x)
egen sum_env_str = rowtotal(env_str_a env_str_b env_str_c env_str_d env_str_f env_str_g env_str_h env_str_i env_str_j env_str_k env_str_l env_str_m env_str_n env_str_o env_str_p env_str_q env_str_x)
egen sum_gam_con = rowtotal(gam_con_a gam_con_x)
egen sum_hum_con = rowtotal(hum_con_a hum_con_b hum_con_c hum_con_d hum_con_f hum_con_g hum_con_h hum_con_j hum_con_k hum_con_x)
egen sum_hum_str = rowtotal(hum_str_a hum_str_d hum_str_g hum_str_x)
egen sum_mil_con = rowtotal(mil_con_a mil_con_b mil_con_c mil_con_x)
egen sum_nuc_con = rowtotal(nuc_con_a nuc_con_c nuc_con_d nuc_con_x)
egen sum_pro_con = rowtotal(pro_con_a pro_con_d pro_con_e pro_con_f pro_con_g pro_con_x)
egen sum_pro_str = rowtotal(pro_str_a pro_str_b pro_str_c pro_str_d pro_str_e pro_str_f pro_str_g pro_str_h pro_str_i pro_str_j pro_str_k pro_str_x)
egen sum_tob_con = rowtotal(tob_con_a tob_con_x)

label var sum_alc_con "(KLD) Sum of alcohol concerns"
label var sum_cgov_con "(KLD) Sum of corporate governance concerns"
label var sum_cgov_str "(KLD) Sum of corporate governance strengths"
label var sum_com_con "(KLD) Sum of community concerns"
label var sum_com_str "(KLD) Sum of community strengths"
label var sum_div_con "(KLD) Sum of diversity concerns"
label var sum_div_str "(KLD) Sum of diversity strengths"
label var sum_emp_con "(KLD) Sum of employee concerns"
label var sum_emp_str "(KLD) Sum of employee strengths"
label var sum_env_con "(KLD) Sum of environment concerns"
label var sum_env_str "(KLD) Sum of environment strengths"
label var sum_gam_con "(KLD) Sum of gambling concerns"
label var sum_hum_con "(KLD) Sum of human rights concerns"
label var sum_hum_str "(KLD) Sum of human rights strengths"
label var sum_mil_con "(KLD) Sum of military concerns"
label var sum_nuc_con "(KLD) Sum of nuclear concerns"
label var sum_pro_con "(KLD) Sum of product concerns"					
label var sum_pro_str "(KLD) Sum of product strengths"
label var sum_tob_con "(KLD) Sum of tobacco concerns"

*	Number of rated sub-dimensions
egen nonmiss_alc_con = rownonmiss(alc_con_a alc_con_x)
egen nonmiss_cgov_con = rownonmiss(cgov_con_b cgov_con_f cgov_con_g cgov_con_h cgov_con_i cgov_con_j cgov_con_k cgov_con_l cgov_con_m cgov_con_x)
egen nonmiss_cgov_str = rownonmiss(cgov_str_a cgov_str_c cgov_str_d cgov_str_e cgov_str_f cgov_str_g cgov_str_h cgov_str_x)
egen nonmiss_com_con = rownonmiss(com_con_a com_con_b com_con_d com_con_x)
egen nonmiss_com_str = rownonmiss(com_str_a com_str_b com_str_c com_str_d com_str_f com_str_g com_str_h com_str_x)
egen nonmiss_div_con = rownonmiss(div_con_a div_con_b div_con_c div_con_d div_con_x)
egen nonmiss_div_str = rownonmiss(div_str_a div_str_b div_str_c div_str_d div_str_e div_str_f div_str_g div_str_h div_str_x)
egen nonmiss_emp_con = rownonmiss(emp_con_a emp_con_b emp_con_c emp_con_d emp_con_f emp_con_g emp_con_x)
egen nonmiss_emp_str = rownonmiss(emp_str_a emp_str_b emp_str_c emp_str_d emp_str_f emp_str_g emp_str_h emp_str_i emp_str_j emp_str_k emp_str_l emp_str_n emp_str_x)
egen nonmiss_env_con = rownonmiss(env_con_a env_con_b env_con_c env_con_d env_con_e env_con_f env_con_g env_con_h env_con_i env_con_j env_con_k env_con_x)
egen nonmiss_env_str = rownonmiss(env_str_a env_str_b env_str_c env_str_d env_str_f env_str_g env_str_h env_str_i env_str_j env_str_k env_str_l env_str_m env_str_n env_str_o env_str_p env_str_q env_str_x)
egen nonmiss_gam_con = rownonmiss(gam_con_a gam_con_x)
egen nonmiss_hum_con = rownonmiss(hum_con_a hum_con_b hum_con_c hum_con_d hum_con_f hum_con_g hum_con_h hum_con_j hum_con_k hum_con_x)
egen nonmiss_hum_str = rownonmiss(hum_str_a hum_str_d hum_str_g hum_str_x)
egen nonmiss_mil_con = rownonmiss(mil_con_a mil_con_b mil_con_c mil_con_x)
egen nonmiss_nuc_con = rownonmiss(nuc_con_a nuc_con_c nuc_con_d nuc_con_x)
egen nonmiss_pro_con = rownonmiss(pro_con_a pro_con_d pro_con_e pro_con_f pro_con_g pro_con_x)
egen nonmiss_pro_str = rownonmiss(pro_str_a pro_str_b pro_str_c pro_str_d pro_str_e pro_str_f pro_str_g pro_str_h pro_str_i pro_str_j pro_str_k pro_str_x)
egen nonmiss_tob_con = rownonmiss(tob_con_a tob_con_x)

label var nonmiss_alc_con "(KLD) Number of rated dimensions of alcohol concerns"
label var nonmiss_cgov_con "(KLD) Number of rated dimensions of corporate governance concerns"
label var nonmiss_cgov_str "(KLD) Number of rated dimensions of corporate governance strengths"
label var nonmiss_com_con "(KLD) Number of rated dimensions of community concerns"
label var nonmiss_com_str "(KLD) Number of rated dimensions of community strengths"
label var nonmiss_div_con "(KLD) Number of rated dimensions of diversity concerns"
label var nonmiss_div_str "(KLD) Number of rated dimensions of diversity strengths"
label var nonmiss_emp_con "(KLD) Number of rated dimensions of employee concerns"
label var nonmiss_emp_str "(KLD) Number of rated dimensions of employee strengths"
label var nonmiss_env_con "(KLD) Number of rated dimensions of environment concerns"
label var nonmiss_env_str "(KLD) Number of rated dimensions of environment strengths"
label var nonmiss_gam_con "(KLD) Number of rated dimensions of gambling concerns"
label var nonmiss_hum_con "(KLD) Number of rated dimensions of human rights concerns"
label var nonmiss_hum_str "(KLD) Number of rated dimensions of human rights strengths"
label var nonmiss_mil_con "(KLD) Number of rated dimensions of military concerns"
label var nonmiss_nuc_con "(KLD) Number of rated dimensions of nuclear concerns"
label var nonmiss_pro_con "(KLD) Number of rated dimensions of product concerns"					
label var nonmiss_pro_str "(KLD) Number of rated dimensions of product strengths"
label var nonmiss_tob_con "(KLD) Number of rated dimensions of tobacco concerns"

*	Number of non-rated sub-dimensions
egen miss_alc_con = rowmiss(alc_con_a alc_con_x)
egen miss_cgov_con = rowmiss(cgov_con_b cgov_con_f cgov_con_g cgov_con_h cgov_con_i cgov_con_j cgov_con_k cgov_con_l cgov_con_m cgov_con_x)
egen miss_cgov_str = rowmiss(cgov_str_a cgov_str_c cgov_str_d cgov_str_e cgov_str_f cgov_str_g cgov_str_h cgov_str_x)
egen miss_com_con = rowmiss(com_con_a com_con_b com_con_d com_con_x)
egen miss_com_str = rowmiss(com_str_a com_str_b com_str_c com_str_d com_str_f com_str_g com_str_h com_str_x)
egen miss_div_con = rowmiss(div_con_a div_con_b div_con_c div_con_d div_con_x)
egen miss_div_str = rowmiss(div_str_a div_str_b div_str_c div_str_d div_str_e div_str_f div_str_g div_str_h div_str_x)
egen miss_emp_con = rowmiss(emp_con_a emp_con_b emp_con_c emp_con_d emp_con_f emp_con_g emp_con_x)
egen miss_emp_str = rowmiss(emp_str_a emp_str_b emp_str_c emp_str_d emp_str_f emp_str_g emp_str_h emp_str_i emp_str_j emp_str_k emp_str_l emp_str_n emp_str_x)
egen miss_env_con = rowmiss(env_con_a env_con_b env_con_c env_con_d env_con_e env_con_f env_con_g env_con_h env_con_i env_con_j env_con_k env_con_x)
egen miss_env_str = rowmiss(env_str_a env_str_b env_str_c env_str_d env_str_f env_str_g env_str_h env_str_i env_str_j env_str_k env_str_l env_str_m env_str_n env_str_o env_str_p env_str_q env_str_x)
egen miss_gam_con = rowmiss(gam_con_a gam_con_x)
egen miss_hum_con = rowmiss(hum_con_a hum_con_b hum_con_c hum_con_d hum_con_f hum_con_g hum_con_h hum_con_j hum_con_k hum_con_x)
egen miss_hum_str = rowmiss(hum_str_a hum_str_d hum_str_g hum_str_x)
egen miss_mil_con = rowmiss(mil_con_a mil_con_b mil_con_c mil_con_x)
egen miss_nuc_con = rowmiss(nuc_con_a nuc_con_c nuc_con_d nuc_con_x)
egen miss_pro_con = rowmiss(pro_con_a pro_con_d pro_con_e pro_con_f pro_con_g pro_con_x)
egen miss_pro_str = rowmiss(pro_str_a pro_str_b pro_str_c pro_str_d pro_str_e pro_str_f pro_str_g pro_str_h pro_str_i pro_str_j pro_str_k pro_str_x)
egen miss_tob_con = rowmiss(tob_con_a tob_con_x)

label var miss_alc_con "(KLD) Number of non-rated dimensions of alcohol concerns"
label var miss_cgov_con "(KLD) Number of non-rated dimensions of corporate governance concerns"
label var miss_cgov_str "(KLD) Number of non-rated dimensions of corporate governance strengths"
label var miss_com_con "(KLD) Number of non-rated dimensions of community concerns"
label var miss_com_str "(KLD) Number of non-rated dimensions of community strengths"
label var miss_div_con "(KLD) Number of non-rated dimensions of diversity concerns"
label var miss_div_str "(KLD) Number of non-rated dimensions of diversity strengths"
label var miss_emp_con "(KLD) Number of non-rated dimensions of employee concerns"
label var miss_emp_str "(KLD) Number of non-rated dimensions of employee strengths"
label var miss_env_con "(KLD) Number of non-rated dimensions of environment concerns"
label var miss_env_str "(KLD) Number of non-rated dimensions of environment strengths"
label var miss_gam_con "(KLD) Number of non-rated dimensions of gambling concerns"
label var miss_hum_con "(KLD) Number of non-rated dimensions of human rights concerns"
label var miss_hum_str "(KLD) Number of non-rated dimensions of human rights strengths"
label var miss_mil_con "(KLD) Number of non-rated dimensions of military concerns"
label var miss_nuc_con "(KLD) Number of non-rated dimensions of nuclear concerns"
label var miss_pro_con "(KLD) Number of non-rated dimensions of product concerns"					
label var miss_pro_str "(KLD) Number of non-rated dimensions of product strengths"
label var miss_tob_con "(KLD) Number of non-rated dimensions of tobacco concerns"

*	Number of sub-dimensions
foreach variable in alc_con cgov_con cgov_str com_con com_str div_con div_str ///
	emp_con emp_str env_con env_str gam_con hum_con hum_str mil_con nuc_con ///
	pro_con pro_str tob_con {
	
	gen dims_`variable' = miss_`variable' + nonmiss_`variable'
	
	label var dims_`variable' "(KLD) Number of sub-dimensions for `variable'"
}

*	Sum adjusted for number of rated sub-dimensions
foreach variable in alc_con cgov_con cgov_str com_con com_str div_con div_str ///
	emp_con emp_str env_con env_str gam_con hum_con hum_str mil_con nuc_con ///
	pro_con pro_str tob_con {

	*	Generate
	gen sum_adj_`variable' = sum_`variable'/nonmiss_`variable'
	
	*	Label
	label var sum_adj_`variable' "(KLD) Adjusted sum of `variable'"
	
}

***	Aggregate 
*	Strengths and concerns sums
foreach v in cgov com div emp env hum pro {
	gen `v'_agg = sum_`v'_str - sum_`v'_con
}

gen alc_agg = sum_alc_con
gen gam_agg = sum_gam_con
gen mil_agg = sum_mil_con
gen nuc_agg = sum_nuc_con
gen tob_agg = sum_tob_con

***	Label
label var cgov_agg "(KLD) Aggregate corporate governance"
label var com_agg "(KLD) Aggregate community"
label var div_agg "(KLD) Aggregate diversity"
label var emp_agg "(KLD) Aggregate employee relations"
label var env_agg "(KLD) Aggregate environment"
label var hum_agg "(KLD) Aggregate indigenous peoples relations"
label var pro_agg "(KLD) Aggregate product"
label var alc_agg "(KLD) Aggregate alcohol (no strengths in KLD)"
label var gam_agg "(KLD) Aggregate gambling involvement (no strengths in KLD)"
label var mil_agg "(KLD) Aggregate military involvement (no strengths in KLD)"
label var nuc_agg "(KLD) Aggregate nuclear involvement (no strengths in KLD)"
label var tob_agg "(KLD) Aggregate tobacco invovlement (no strengths in KLD)"




***	Generate Net Variables
egen net_kld_str = rowtotal(sum_cgov_str sum_com_str sum_div_str sum_emp_str sum_env_str sum_hum_str sum_pro_str)
egen net_kld_con = rowtotal(sum_alc_con sum_cgov_con sum_com_con sum_div_con sum_emp_con sum_env_con sum_gam_con sum_hum_con sum_mil_con sum_nuc_con sum_pro_con sum_tob_con)
gen net_kld = net_kld_str - net_kld_con

label var net_kld_str "(KLD) Sum of KLD strengths"
label var net_kld_con "(KLD) Sum of KLD concerns"
label var net_kld "(KLD) Net KLD score (strengths - concerns)"






///	CREATE UNIQUE FIRM-YEARS
bysort firm year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     53,136       99.94       99.94
          2 |         28        0.05       99.99
          4 |          4        0.01      100.00
------------+-----------------------------------
      Total |     53,168      100.00

*/
drop if N>1
drop N

///	SET PANEL
encode firm, gen(firm_n)
xtset firm_n year, y

compress
label data "KLD Data 1991 - 2016 downloaded April 2, 2019 by poggi005@umn.edu"


drop firm_n
drop if cusip==""

bysort cusip year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     47,097       99.15       99.15
          2 |         34        0.07       99.23
          3 |         21        0.04       99.27
          4 |          8        0.02       99.29
          5 |         20        0.04       99.33
          6 |          6        0.01       99.34
         60 |         60        0.13       99.47
         69 |         69        0.15       99.61
        184 |        184        0.39      100.00
------------+-----------------------------------
      Total |     47,499      100.00

*/
drop if N>1
drop N
*(402 observations deleted)

***	Generate indicator variable
gen in_kld = 1
label var in_kld "Indicator = 1 if in KLD data"

rename firm	firm_kld /*	Avoids conflicts with the firm variable in csrhub-all-year-level	*/

/// SAVE
compress
save data/kld-all.dta, replace




						***===============================***
						*									*
						*	MERGE KLD WITH CHAPTER 2 DATA	*
						*									*
						***===============================***
/*	PLAN
		Match variables in KLD
			-	CUSIP8
			-	Ticker
			-	Firm name
			-	Year
*/


///	IMPORT CHAPTER 2 DATA
clear all
set scheme plotplainblind

use data/matched-csrhub-cstat-2008-2017, clear


///	MERGE ON CUSIP8-YEAR

***	Prep for merge
rename cusip cusip9
gen cusip=cusip8

***	Merge
capt n drop _merge
merge 1:1 cusip year using data/kld-all.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        71,594
        from master                    40,085  (_merge==1)
        from using                     31,509  (_merge==2)

    matched                            15,588  (_merge==3)
    -----------------------------------------
*/

***	Save matches
preserve
keep if _merge==3
drop _merge
compress
save data/csrhub-cstat-kld-matched.dta, replace
restore

***	Save unmatched
preserve
keep if _merge!=3
drop _merge
compress
save data/csrhub-cstat-kld-unmatched.dta, replace
restore


///	MERGE NON-MATCHES ON TICKER-YEAR

***	Keep non-matches
keep if _merge==1
compress

***	Merge
capt n drop _merge
merge 1:1 ticker year using data/kld-all.dta









							***===========================***
							*								*
							*				SAVE			*
							*								*
							***===========================***
///	SET PANEL


///	SAVE
***	Drop unneeded variables


***	Save all
compress
save data/, replace











*END
