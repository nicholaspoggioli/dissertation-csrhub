

***===============================***
*	CREATE YEAR LEVEL CSRHUB DATA	*
***===============================***
///	LOAD DATA
use data/csrhub-all.dta, clear
/*	Created at D:\Dropbox\Data\csrhub-data\code-csrHub-data\CREATE-CSRHub-full-dataset.do	*/
drop firm_n csrhub_cr

///	Keep unique cusip ym
bysort cusip ym: gen N=_N
drop if N>1
*111,062 observations deleted, either missing CUSIPs (110,221) or ///
*	duplicate CUSIP ym values (841) 
drop N

///	Set panel
encode cusip, gen(cusip_n)
xtset cusip_n ym

///	Create last month of year variable
gsort cusip -ym
by cusip: gen last_ob = (_n==1)
label var last_ob "(CSRHUB) =1 if last ym CUSIP appears in CSRHUB data"

gen right_censor = (ym==692)
label var right_censor "(CSRHUB) =1 if last ym for CUSIP is 2017m9, the last ym in data"

***	Genearate last month of year variable for each rating
foreach variable of varlist over_rtg board_rtg cmty_rtg com_dev_phl_rtg comp_ben_rtg ///
	div_lab_rtg emp_rtg enrgy_climchge_rtg enviro_pol_rpt_rtg enviro_rtg ///
	gov_rtg humrts_supchain_rtg industry_avg_rtg ldrship_ethics_rtg ///
	over_pct_rank prod_rtg resource_mgmt_rtg train_hlth_safe_rtg trans_report_rtg {

	capt drop var maxmth
	mark var
	markout var `variable'

	sort cusip year month

	markout var year month `variable'

	by cusip year: egen maxmth=max(month) if var==1

	gen `variable'_lym = `variable' if month==maxmth
	label var `variable'_lym "(CSRHUB) Last ym of `variable' for each year"
}

drop var maxmth


///	Collapse to year level
foreach variable of varlist *rtg {
	gen `variable'_mean = `variable'
	gen `variable'_med = `variable'
}

collapse (max) *lym (mean) *_mean (median) *_med, by(cusip year firm isin industry)

order *, alpha
order cusip year firm

///	Drop duplicate cusip years
bysort cusip year: gen N=_N
tab N
/*          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     84,012       99.98       99.98
          2 |         20        0.02      100.00
------------+-----------------------------------
      Total |     84,032      100.00
*/
drop if N>1
drop N

///	Create 8 digit CUSIPS for merge with KLD
gen cusip9 = cusip
label var cusip9 "(CSRHub) CUSIP 9-digit"

replace cusip = substr(isin,3,8)
label var cusip "(CSRHub) CUSIP 8-digit created from cusip9"

/// Keep unique cusip year observations
bysort cusip year: gen N=_N
tab N
/*          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     78,804       93.80       93.80
          2 |      2,504        2.98       96.78
          3 |        918        1.09       97.87
          4 |        776        0.92       98.80
          5 |        495        0.59       99.39
          6 |        174        0.21       99.59
          7 |        105        0.12       99.72
          8 |         80        0.10       99.81
          9 |         45        0.05       99.87
         10 |         40        0.05       99.92
         11 |         22        0.03       99.94
         12 |         36        0.04       99.98
         13 |         13        0.02      100.00
------------+-----------------------------------
      Total |     84,012      100.00
*/
drop if N>1
drop N

***	Indicator variable
gen in_csrhub=1
label var in_csrhub "Indicator = 1 if in CSRHub data"

***	Save year-level CSRHub data
compress
save data/csrhub-all-year-level.dta, replace



***===================================***
*	CREATE MERGED YEAR LEVEL DATASET	*
*	Merge on CUSIP-year					*
***===================================***
*** IMPORT DATA
use data\20190402-all-kld-downloaded-from-wrds.dta, clear

***	ORDER AND SORT
rename companyname firm
replace firm=upper(firm)
order firm year ticker, first
sort firm year

***	GENERATE
gen row_id_kld=_n

***	LABEL
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

***	SUMMATION VARIABLES		/*	The variables included in KLD are wrong	*/
drop *num

egen sum_alc_con = rowtotal(alc_con_a alc_con_x), missing
egen sum_cgov_con = rowtotal(cgov_con_b cgov_con_f cgov_con_g cgov_con_h cgov_con_i cgov_con_j cgov_con_k cgov_con_l cgov_con_m cgov_con_x), missing
egen sum_cgov_str = rowtotal(cgov_str_a cgov_str_c cgov_str_d cgov_str_e cgov_str_f cgov_str_g cgov_str_h cgov_str_x), missing
egen sum_com_con = rowtotal(com_con_a com_con_b com_con_d com_con_x), missing
egen sum_com_str = rowtotal(com_str_a com_str_b com_str_c com_str_d com_str_f com_str_g com_str_h com_str_x), missing
egen sum_div_con = rowtotal(div_con_a div_con_b div_con_c div_con_d div_con_x), missing
egen sum_div_str = rowtotal(div_str_a div_str_b div_str_c div_str_d div_str_e div_str_f div_str_g div_str_h div_str_x), missing
egen sum_emp_con = rowtotal(emp_con_a emp_con_b emp_con_c emp_con_d emp_con_f emp_con_g emp_con_x), missing
egen sum_emp_str = rowtotal(emp_str_a emp_str_b emp_str_c emp_str_d emp_str_f emp_str_g emp_str_h emp_str_i emp_str_j emp_str_k emp_str_l emp_str_n emp_str_x), missing
egen sum_env_con = rowtotal(env_con_a env_con_b env_con_c env_con_d env_con_e env_con_f env_con_g env_con_h env_con_i env_con_j env_con_k env_con_x), missing
egen sum_env_str = rowtotal(env_str_a env_str_b env_str_c env_str_d env_str_f env_str_g env_str_h env_str_i env_str_j env_str_k env_str_l env_str_m env_str_n env_str_o env_str_p env_str_q env_str_x), missing
egen sum_gam_con = rowtotal(gam_con_a gam_con_x), missing
egen sum_hum_con = rowtotal(hum_con_a hum_con_b hum_con_c hum_con_d hum_con_f hum_con_g hum_con_h hum_con_j hum_con_k hum_con_x), missing
egen sum_hum_str = rowtotal(hum_str_a hum_str_d hum_str_g hum_str_x), missing
egen sum_mil_con = rowtotal(mil_con_a mil_con_b mil_con_c mil_con_x), missing
egen sum_nuc_con = rowtotal(nuc_con_a nuc_con_c nuc_con_d nuc_con_x), missing
egen sum_pro_con = rowtotal(pro_con_a pro_con_d pro_con_e pro_con_f pro_con_g pro_con_x), missing
egen sum_pro_str = rowtotal(pro_str_a pro_str_b pro_str_c pro_str_d pro_str_e pro_str_f pro_str_g pro_str_h pro_str_i pro_str_j pro_str_k pro_str_x), missing
egen sum_tob_con = rowtotal(tob_con_a tob_con_x), missing

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


***	GENERATE
foreach v in cgov com div emp env hum pro {
	gen `v'_agg = sum_`v'_str - sum_`v'_con
}

gen alc_agg = sum_alc_con
gen gam_agg = sum_gam_con
gen mil_agg = sum_mil_con
gen nuc_agg = sum_nuc_con
gen tob_agg = sum_tob_con

***	LABEL
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


***	GENERATE NET VARIABLES
egen net_kld_str = rowtotal(sum_cgov_str sum_com_str sum_div_str sum_emp_str sum_env_str sum_hum_str sum_pro_str)
egen net_kld_con = rowtotal(sum_alc_con sum_cgov_con sum_com_con sum_div_con sum_emp_con sum_env_con sum_gam_con sum_hum_con sum_mil_con sum_nuc_con sum_pro_con sum_tob_con)
gen net_kld = net_kld_str - net_kld_con

label var net_kld_str "(KLD) Sum of KLD strengths"
label var net_kld_con "(KLD) Sum of KLD concerns"
label var net_kld "(KLD) Net KLD score (strengths - concerns)"


***	CREATE UNIQUE FIRM-YEARS
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

***	SET PANEL
encode firm, gen(firm_n)
xtset firm_n year, y

compress
label data "KLD Data 1991 - 2016 downloaded April 2, 2019 by poggi005@umn.edu"

///	CREATE CUSIP-YEAR PANEL
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


///	MERGE WITH CSRHUB YEARLY
rename firm	firm_kld /*	Avoids conflicts with the firm variable in csrhub-all-year-level	*/

merge 1:1 cusip year using data/csrhub-all-year-level.dta, update assert(1 2 3 4 5)
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        92,809
        from master                    30,551  (_merge==1)
        from using                     62,258  (_merge==2)

    matched                            16,546
        not updated                    16,546  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/
codebook cusip if _merge==3
*	3,549 unique CUSIPs matched between CSRHub and KLD
codebook cusip if in_csrhub==1
*	13,496 unique CUSIPs in CSRHub
*	3,549 / 13,496 = 26.3% of CSRHub CUSIPs matched in KLD
drop _merge

compress
save data/mergefile-kld-csrhub-cusip-year.dta, replace


///	MERGE WITH CSTAT YEARLY
use data/cstat-all-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, clear

xtset, clear

gen year = year(datadate)
rename cusip cusip9

gen cusip=substr(cusip9,1,8)
drop if cusip==""
bysort cusip year: gen N=_N
tab N
/*          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    113,801       99.66       99.66
          2 |        390        0.34      100.00
------------+-----------------------------------
      Total |    114,191      100.00
*/
drop if N>1
drop N

***	Generate indicator variable
gen in_cstat = 1
label var in_cstat "Indicator = 1 if in CSTAT data"

***	Merge
merge 1:1 cusip year using data/mergefile-kld-csrhub-cusip-year.dta, update assert(1 2 3 4 5)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       132,890
        from master                    68,668  (_merge==1)
        from using                     64,222  (_merge==2)

    matched                            45,133
        not updated                    45,133  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/

codebook cusip if _merge==3
*	6,373 unique CUSIPs matched between CSTAT and KLD-CSRHub
codebook cusip if in_cstat==1 & in_csrhub==1 & in_kld==1
*	3,194 unique CUSIPs matched across all three datasets


***	Drop variables
drop _merge cusip_n
drop in_cstat_csrhub_cusip in_cstat_kld_cusip




***=======================================***
*	CREATE NEW VARIABLES FOR REWB MODELS	*
***=======================================***
encode cusip, gen(cusip_n)

rename over_rtg_lym over_rtg
/// Create de-meaned and mean variables for random effects within-between modeling
foreach variable in net_kld_str net_kld_con over_rtg emp debt rd ad size {
	bysort cusip_n: egen `variable'_m = mean(`variable')
	label var `variable'_m "CUSIP-level mean of `variable'"
	bysort cusip_n: gen `variable'_dm = `variable' - `variable'_m
	label var `variable'_dm "CUSIP-level de-meaned `variable'"
}

///	SET PANEL
xtset cusip_n year, y
compress
order cusip year conm firm_kld firm




***======================================================***
*	CREATE TREATMENT VARIABLES
*		- Binary +/- deviation from standard deviation
*		- Continuous measure number of standard deviations
*		- Categorical measure standard deviations rounded to integer
***======================================================***

*	Generate year-on-year change in over_rtg
gen over_rtg_yoy = over_rtg - l.over_rtg
label var over_rtg_yoy "Year-on-year change in CSRHub overall rating"

///	Binary +/- deviation from standard deviation


***	Firm-specific within-firm standard deviation

*	Generate firm-specific within-firm over_rtg standard deviation
by cusip_n: egen sdw = sd(over_rtg)
label var sdw "Within-firm standard deviation of over_rtg for each cusip_n"
replace sdw=. if over_rtg==.

*	Generate treatment variables
foreach threshold in 3 2 1 {
	*	Treatment event
	gen trt`threshold'_sdw_pos = over_rtg_yoy > (`threshold' * sdw) & ///
		over_rtg_yoy!=.
	label var trt`threshold'_sdw_pos ///
		"Treatment = 1 if year-on-year over_rtg > `threshold' std dev of sdw and positive"
	gen trt`threshold'_sdw_neg = over_rtg_yoy < (-`threshold' * sdw) & over_rtg_yoy!=.
	label var trt`threshold'_sdw_neg "Treatment = 1 if year-on-year over_rtg > `threshold' std dev of sdw and negative"

	*	Treatment year
	by cusip_n: gen trt_yr_sdw_pos = year if trt`threshold'_sdw_pos==1
	sort cusip_n trt_yr_sdw_pos
	by cusip_n: replace trt_yr_sdw_pos = trt_yr_sdw_pos[_n-1] if _n!=1
	replace trt_yr_sdw_pos = . if over_rtg==.

	by cusip_n: gen trt_yr_sdw_neg = year if trt`threshold'_sdw_neg==1
	sort cusip_n trt_yr_sdw_neg
	by cusip_n: replace trt_yr_sdw_neg = trt_yr_sdw_neg[_n-1] if _n!=1
	replace trt_yr_sdw_neg = . if over_rtg==.

	*	Post-treatment years
	by cusip_n: gen post`threshold'_sdw_pos=(year>trt_yr_sdw_pos)
	label var post`threshold'_sdw_pos ///
		"Indicator =1 if post-treatment year for `threshold' std dev of sdw"
	replace post`threshold'_sdw_pos=. if over_rtg==.

	by cusip_n: gen post`threshold'_sdw_neg=(year>trt_yr_sdw_neg)
	label var post`threshold'_sdw_neg ///
		"Indicator =1 if post-treatment year for `threshold' std dev of sdw"
	replace post`threshold'_sdw_neg=. if over_rtg==.

	*	Treated firms
	by cusip_n: egen trt`threshold'_sdw_pos_grp= max(post`threshold'_sdw_pos)
	label var trt`threshold'_sdw_pos_grp ///
		"Indicator = 1 if treatment group for `threshold' std dev of sdw"

	by cusip_n: egen trt`threshold'_sdw_neg_grp= max(post`threshold'_sdw_neg)
	label var trt`threshold'_sdw_neg_grp ///
		"Indicator = 1 if treatment group for `threshold' std dev of sdw"

	qui xtset
	drop trt_yr_sdw_*
}


/*	Remove overlap in treatment groups											/*	Still needs to be done */
gen trt4_year_only_sdg = trt4_year_sdg
label var trt4_year_only_sdg "Indicator =1 if year of ONLY 4 global std dev treatment"
gen post4_only_sdg = post4_sdg
label var post4_only_sdg "Indicator =1 if post-treatment year of ONLY 4 global std dev treatment"
gen trt4_only_sdg = trt4_sdg
label var trt4_only_sdg "Indicator = 1 if treatment group of ONLY 4 global std dev treated"

foreach threshold in 3 2 1 {
	local y = `threshold' + 1

	gen trt`threshold'_year_only_sdg = trt`threshold'_year_sdg
	label var trt`threshold'_year_only_sdg "Indicator =1 if year of ONLY `threshold' global std dev treatment"
	gen post`threshold'_only_sdg = post`threshold'_sdg
	label var post`threshold'_only_sdg "Indicator =1 if post-treatment year of ONLY `threshold' global std dev treatment"
	gen trt`threshold'_only_sdg = trt`threshold'_sdg
	label var trt`threshold'_only_sdg "Indicator = 1 if treatment group of ONLY `threshold' global std dev treated"

	replace trt`threshold'_year_only_sdg = 0 if trt`y'_year_sdg==1
	replace post`threshold'_only_sdg = 0 if post`y'_sdg == 1
	replace trt`threshold'_only_sdg = 0 if trt`y'_sdg == 1
}
*/


///	Continuous measure number of standard deviations

***	Combined
xtset

*gen trt_cont_sdg = over_rtg_yoy / sdg
*label var trt_cont_sdg "Continuous treatment = over_rtg_yoy / sdg"

gen trt_cont_sdw = over_rtg_yoy / sdw
label var trt_cont_sdw "Continuous treatment = over_rtg_yoy / sdw"

***	Positive and negative

/*	sdg
gen trt_cont_sdg_pos = trt_cont_sdg
replace trt_cont_sdg_pos = . if trt_cont_sdg_pos < 0
label var trt_cont_sdg_pos "Continuous value of trt_cont_sdg if trt_cont_sdg >= 0"

gen trt_cont_sdg_neg = trt_cont_sdg
replace trt_cont_sdg_neg = . if trt_cont_sdg_neg > 0
label var trt_cont_sdg_neg "Continuous value of trt_cont_sdg if trt_cont_sdg <= 0"
*/

*	sdw
gen trt_cont_sdw_pos = trt_cont_sdw
replace trt_cont_sdw_pos = . if trt_cont_sdw_pos < 0
label var trt_cont_sdw_pos "Continuous value of trt_cont_sdw if trt_cont_sdw >= 0"

gen trt_cont_sdw_neg = trt_cont_sdw
replace trt_cont_sdw_neg = . if trt_cont_sdw_neg > 0
label var trt_cont_sdw_neg "Continuous value of trt_cont_sdw if trt_cont_sdw <= 0"


///	Categorical measure standard deviations rounded to integer

/***	Global standard deviation
xtset
gen trt_cat_sdg_pos = .
gen trt_cat_sdg_neg = .

foreach threshold in 0 1 2 3 4 5 6 7 {
	replace trt_cat_sdg_pos = `threshold' if over_rtg_yoy >= `threshold'*sdg
	replace trt_cat_sdg_pos = . if over_rtg_yoy == .
	replace trt_cat_sdg_neg = (-1*`threshold') if over_rtg_yoy <= `threshold'*(-1*sdg)
	replace trt_cat_sdg_neg = . if over_rtg_yoy == .
}
label var trt_cat_sdg_pos "Categorical treatment = integer of over_rtg_yoy positive std dev from sdg"
label var trt_cat_sdg_neg "Categorical treatment = integer of over_rtg_yoy negative std dev from sdg"

***	These variables should be mutually exclusive except where year-on-year
***		over_rtg change is zero
tab trt_cat_sdg_pos trt_cat_sdg_neg
/*
           | trt_cat_sd
trt_cat_sd |   g_neg
     g_pos |         0 |     Total
-----------+-----------+----------
         0 |       514 |       514
-----------+-----------+----------
     Total |       514 |       514
*/
sum over_rtg_yoy if trt_cat_sdg_pos==0 & trt_cat_sdg_neg==0
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
over_rtg_yoy |        514           0           0          0          0
*/
*/

***	Firm-specific standard deviation
xtset
gen trt_cat_sdw_pos = .
gen trt_cat_sdw_neg = .

foreach threshold in 0 1 2 3 4 5 6 7 {
	replace trt_cat_sdw_pos = `threshold' if over_rtg_yoy >= `threshold'*sdw
	replace trt_cat_sdw_pos = . if over_rtg_yoy == .
	replace trt_cat_sdw_neg = (-1*`threshold') if over_rtg_yoy <= `threshold'*(-1*sdw)
	replace trt_cat_sdw_neg = . if over_rtg_yoy == .
}
label var trt_cat_sdw_pos "Categorical treatment = integer of over_rtg_yoy positive std dev from sdw"
label var trt_cat_sdw_neg "Categorical treatment = integer of over_rtg_yoy negative std dev from sdw"

***	These variables should be mutually exclusive except where year-on-year
***		over_rtg change is zero
tab trt_cat_sdw_pos trt_cat_sdw_neg
/*

Categorica |
         l |
 treatment |
 = integer |
        of |
over_rtg_y | Categorical treatment
        oy |     = integer of
  positive | over_rtg_yoy negative
   std dev |   std dev from sdw
  from sdw |        -7          0 |     Total
-----------+----------------------+----------
         0 |         0        393 |       393
         7 |       121          0 |       121
-----------+----------------------+----------
     Total |       121        393 |       514

*/
sum over_rtg_yoy if trt_cat_sdw_pos==7 & trt_cat_sdw_neg==-7
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
         sdw |        121           0           0          0          0
*/

*	No values of the trt_cat_sdw variables are greater than 3 or less than -3
replace trt_cat_sdw_pos = . if trt_cat_sdw_pos > 3
replace trt_cat_sdw_neg = . if trt_cat_sdw_neg < -3



///	REPLACE trt_sdw variables with missing for years without CSRHub data
foreach variable of varlist *sdw* {
	display "`variable'"
	replace `variable'=. if year < 2009
}

/*
///	CREATE STANDARDIZED VARIABLES
foreach variable of varlist over_rtg dltt at emp tobinq age xad xrd {
	capt n egen z`variable'=std(`variable')
	label var z`variable' "Standardized value of `variable'"
}
*/


///	FIX MARKER VARIABLES
foreach variable of varlist in_csrhub in_kld in_cstat {
	replace `variable'=0 if `variable'==.
}

/// SET PANEL
drop cusip_n
label drop _all
encode cusip, gen(cusip_n)
xtset cusip_n year, y

///	SALES GROWTH VARIABLES
***	Current year minus previous year
gen revt_yoy = revt - l.revt
label var revt_yoy "Year-on-year change in revenue (revt - previous year revt)"

***	Next year minus current year
gen Frevt_yoy = F.revt-revt
label var Frevt_yoy "Next year revt - current year revt"

***	Percent change in sales, current to next year
gen revt_pct = (revt_yoy/L.revt)*100
label var revt_pct "Percent change in revenue, current to previous year"



///	SAVE
***	Order variables
order cusip year firm firm_kld conm
format %20s firm firm_kld conm

sort cusip year

gen in_all = (in_cstat==1 & in_kld==1 & in_csrhub==1)
label var in_all "Indicator = 1 if in CSRHub, CSTAT, and KLD data"

compress
save data/csrhub-kld-cstat-year-level-with-treatment-variables.dta, replace




*END
