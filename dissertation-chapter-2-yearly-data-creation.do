clear all

/*
***===============================***
*	COLLAPSE CSRHUB TO YEAR LEVEL 	*
***===============================***
///	LOAD DATA
use data/csrhub-all.dta, clear
/*	Created at D:\Dropbox\Data\csrhub-data\code-csrHub-data\CREATE-CSRHub-full-dataset.do	*/
drop firm_n csrhub_cr

///	KEEP UNIQUE CUSIP YM
bysort cusip ym: gen N=_N
drop if N>1
*111,062 observations deleted, either missing CUSIPs (110,221) or ///
*	duplicate CUSIP ym values (841) 
drop N

///	SET PANEL
encode cusip, gen(cusip_n)
xtset cusip_n ym

///	CREATE LAST MONTH OF YEAR VARIABLE
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


///	COLLAPSE TO YEAR LEVEL
foreach variable of varlist *rtg {
	gen `variable'_mean = `variable'
	gen `variable'_med = `variable'
}

collapse (max) *lym (mean) *_mean (median) *_med, by(cusip year firm isin industry)

order *, alpha
order cusip year firm

***	Drop duplicate cusip years
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


***	Generate indicator variable
gen in_csrhub=1
label var in_csrhub "Indicator = 1 if in CSRHub data"


/// SAVE
compress
xtset, clear
label data "Year-level CSRHub 2008-2017"
save data/csrhub-all-year-level-pre-manual-match.dta, replace


***=======================================================***
*	MERGE MANUALLY-MATCHED CSRHUB-CSTAT FIRM INFORMATION 	*
***=======================================================***
///	PREP MANUALLY-MATCHED DATA FOR MERGE
import excel "data\manual-match-csrhub-to-cstat.xlsx", ///
	firstrow allstring clear

	
***	Label variables
label var firm_csrhub "(CSRHub) firm name from manual CSRHUB-CSTAT match"
label var cusip8 "(CSRHub) cusip8 from manual CSRHUB-CSTAT match"
label var cusip9 "(CSRHub) cusip9 from manual CSRHUB-CSTAT match"
label var isin "(CSRHub) isin from manual CSRHUB-CSTAT match"
label var firm "(CSTAT) firm name from manual CSRHUB-CSTAT match"
label var tic "(CSTAT) ticker from manual CSRHUB-CSTAT match"
label var cusip "(CSTAT) cusip9 from manual CSRHUB-CSTAT match"
label var cik "(CSTAT) cik from manual CSRHUB-CSTAT match"
label var gvkey "(CSTAT) gvkey from manual CSRHUB-CSTAT match"

***	Drop unneeded variables
drop isin tic cik gvkey

***	Rename variables to preserve through merge
rename (cusip8 cusip9 firm cusip) (cusip8_csr_man cusip9_csr_man firm_cstat_man cusip9_cstat_man)

***	Clean
replace firm_csrhub=upper(firm_csrhub)

***	Save manually-matched data
compress
save data/manually-matched-csrhub-cstat-firms.dta, replace


///	LOAD CSRHUB DATA
use data/csrhub-all-year-level-pre-manual-match.dta, clear

/// MERGE
gen firm_csrhub=upper(firm)
label var firm_csrhub "(CSRHUB) firm name used to match to manual CSTAT match"
merge m:1 firm_csrhub using data/manually-matched-csrhub-cstat-firms.dta, ///
	update assert(1 2 3 4 5)
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        75,921
        from master                    75,921  (_merge==1)
        from using                          0  (_merge==2)

    matched                             2,883
        not updated                     2,883  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/
drop _merge

/// SAVE CSRHUB WITH MANUALLY-MATCHED CSTAT IDENTIFIERS
save data/csrhub-all-year-level.dta, replace

*/





***=======================================***
*	MERGE CSRHUB AND CSTAT GLOBAL ON ISIN	*
***=======================================***
///	PREPARE COMPUSTAT GLOBAL FOR MERGE
use data/cstat-all-firms-fundamentals-annual-global-2000-2018.dta, clear

***	Keep industrial format
keep if indfmt=="INDL"

***	Keep unique isin-years
gen year=fyear

codebook isin
/*
unique values:  38,028                   missing "":  2,611/479,423
*/
drop if isin==""

bysort isin year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    473,302       99.26       99.26
          2 |      3,468        0.73       99.99
          3 |         42        0.01      100.00
------------+-----------------------------------
      Total |    476,812      100.00
*/
keep if N==1
drop N

***	Save
compress
save data/mergefile-cstat-fundamentals-annual-global-2000-2018.dta, replace


///	MERGE CSRHUB WITH CSTAT GLOBAL ON ISIN
***	Merge and keep matched
use data/csrhub-all-year-level.dta, clear

merge 1:1 isin year using ///
	data/mergefile-cstat-fundamentals-annual-global-2000-2018.dta, ///
	keep(match)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                            26,116  (_merge==3)
    -----------------------------------------
*/

*	Save matched
drop _merge
compress
save data/matched-csrhub-cstat-global-isin-year.dta, replace

***	Merge and keep unmatched
use data/csrhub-all-year-level.dta, clear

merge 1:1 isin year using ///
	data/mergefile-cstat-fundamentals-annual-global-2000-2018.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       499,874
        from master                    52,688  (_merge==1)
        from using                    447,186  (_merge==2)

    matched                            26,116  (_merge==3)
    -----------------------------------------
*/

*	Save unmatched
keep if _merge==1
drop _merge gvkey indfmt datafmt consol popsrc fyear fyr datadate exchg sedol ///
	conm costat fic cik conml loc naics sic
compress

save data/unmatched-csrhub-cstat-global-isin-year.dta, replace








***===============================================================***
*	MERGE UNMATCHED CSRHUB AND CSTAT NORTH AMERICA ON CUSIP9 YEAR	*
***===============================================================***
///	MERGE AND SAVE EXACT MATCHES
use data/cstat-fundamentals-annual-all-firms-2006-2017.dta, clear
xtset, clear

gen year = fyear
rename cusip cusip9

drop if indfmt=="FS"

bysort cusip9 year: gen N=_N
tab N
/*          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    124,099       99.68       99.68
          2 |        126        0.10       99.78
          3 |         84        0.07       99.85
          4 |         48        0.04       99.89
          5 |         10        0.01       99.89
         10 |         10        0.01       99.90
         15 |         15        0.01       99.91
         17 |         34        0.03       99.94
         18 |         72        0.06      100.00
------------+-----------------------------------
      Total |    124,498      100.00
*/
drop if N>1
drop N

***	Generate indicator variable
gen in_cstat = 1
label var in_cstat "Indicator = 1 if in CSTAT data"

***	Merge with CSRHub on cusip9-year
merge 1:1 cusip9 year using data/csrhub-all-year-level.dta, ///
	assert(1 2 3 4 5)
	
***	Merge with CSTAT Global on ISIN
replace fyear = year if fyear==.

drop if _merge==1

merge 1:m isin fyear using data/cstat-all-firms-fundamentals-annual-global-2000-2018.dta, ///
	gen(_merge_global)
	

***	Save matched sample







///	MERGE AND SAVE NON-MATCHED CSRHUB FIRMS


***	Generate indicator variable


***	Merge with CSRHub on cusip9-year


***	Save non-matched CSRHub firm-years

*	Keep CSRHub variables for match to CSTAT

*	Keep unique firm names

*	Save





























///	PREPARE CSRHUB/CSTAT FOR MERGE WITH KLD
***	Create 8 digit CUSIPS in CSRHUB/CSTAT to merge with KLD
gen cusip8 = substr(cusip9,1,8)
label var cusip8 "(CSTAT) CUSIP8 created from CUSIP9"


///	SAVE
compress
save data/mergefile-csrhub-cstat.dta, replace











***===========================================================***
*	MERGE CSRHUB AND CSTAT ON MANUALLY-MATCHED FIRM IDENTIFIERS	*
***===========================================================***
///	PREP COMPUSTAT DATA FOR MERGE ON CUSIP9_CSTAT_MAN YEAR
use data/cstat-all-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, clear

gen year=fyear
gen cusip9_cstat_man = cusip

bysort cusip9_cstat_man year: gen N=_N
tab N
/*          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    113,988       99.82       99.82
          2 |         58        0.05       99.87
          3 |         99        0.09       99.96
          4 |         44        0.04      100.00
          5 |          5        0.00      100.00
------------+-----------------------------------
      Total |    114,194      100.00
*/
keep if N==1
drop N

drop if cusip9_cstat_man==""

***	Save
compress
save data/cstat-all-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018-for-manual-match.dta, replace




///	MERGE ON CUSIP9_ALT YEAR
use data/cstat-all-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018-for-manual-match.dta, clear

merge 1:m cusip9_cstat_man year using data/mergefile-csrhub-cstat.dta,
	keepusing() ///
	update assert(1 2 3 4 5)
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       278,984
        from master                   113,006  (_merge==1)
        from using                    165,978  (_merge==2)

    matched                               985
        not updated                         0  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict               985  (_merge==5)
    -----------------------------------------
*/














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


***	Generate
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












***===============================================***
*	MERGE KLD AND CSRHUB/CSTAT ON KLD CUSIP8		*
***===============================================***
///	LOAD KLD
use data/kld-all.dta, clear

gen cusip8=cusip


///	MERGE KLD AND CSRHUB/CSTAT
merge 1:1 cusip8 year using data/mergefile-csrhub-cstat.dta, ///
	update assert(1 2 3 4 5)

/*    Result                           # of obs.
    -----------------------------------------
    not matched                       142,594
        from master                    11,364  (_merge==1)
        from using                    131,230  (_merge==2)

    matched                            35,733
        not updated                    35,733  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/


///	EXAMINE
foreach variable in in_cstat in_csrhub in_kld {
	replace `variable'=0 if `variable'==.
}

tab in_cstat in_csrhub
/*
 Indicator |  Indicator = 1 if in
 = 1 if in |      CSRHub data
CSTAT data |         0          1 |     Total
-----------+----------------------+----------
         0 |    11,364     52,975 |    64,339 
         1 |    88,159     25,829 |   113,988 
-----------+----------------------+----------
     Total |    99,523     78,804 |   178,327
*/

tab in_cstat in_kld
/* 
 Indicator |  Indicator = 1 if in
 = 1 if in |       KLD data
CSTAT data |         0          1 |     Total
-----------+----------------------+----------
         0 |    51,692     12,647 |    64,339 
         1 |    79,538     34,450 |   113,988 
-----------+----------------------+----------
     Total |   131,230     47,097 |   178,327 
*/

tab in_csrhub in_kld
/*
 Indicator |
 = 1 if in |  Indicator = 1 if in
    CSRHub |       KLD data
      data |         0          1 |     Total
-----------+----------------------+----------
         0 |    68,972     30,551 |    99,523 
         1 |    62,258     16,546 |    78,804 
-----------+----------------------+----------
     Total |   131,230     47,097 |   178,327
*/

gen in_all = (in_cstat==1 & in_csrhub==1 & in_kld==1)
label var in_all "=1 if matched in cstat csrhub and kld"
tab in_all
/*    =1 if |
 matched in |
      cstat |
 csrhub and |
        kld |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    163,064       91.44       91.44
          1 |     15,263        8.56      100.00
------------+-----------------------------------
      Total |    178,327      100.00
*/


///	SET PANEL
xtset, clear

encode cusip8, gen(cusip8_num)

xtset cusip8_num year, y


///	SAVE
***	Drop unneeded variables
drop in_cstat_csrhub_cusip in_cstat_kld_cusip

***	Save all
compress
save data/analysis-file-cstat-kld-csrhub-cusip8-year-all.dta, replace

***	Only non-matched observations
keep if _merge!=3
compress
drop _merge
save data/mergefile-nonmatched-cstat-kld-csrhub-cusip8-year.dta, replace































***======================================================***
*	CREATE TREATMENT VARIABLES
*		- Binary +/- deviation from standard deviation
*		- Continuous measure number of standard deviations
*		- Categorical measure standard deviations rounded to integer
***======================================================***
///	LOAD DATA
clear all
use data/analysis-file-cstat-kld-csrhub-cusip8-year-all.dta, clear

***	Set panel
encode cusip8, gen(cusip_n)
xtset cusip_n year, y

///	Generate year-on-year change in over_rtg
rename over_rtg_lym over_rtg

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
	replace trt`threshold'_sdw_pos=. if over_rtg==.
	
	gen trt`threshold'_sdw_neg = over_rtg_yoy < (-`threshold' * sdw) & over_rtg_yoy!=.
	label var trt`threshold'_sdw_neg "Treatment = 1 if year-on-year over_rtg > `threshold' std dev of sdw and negative"
	replace trt`threshold'_sdw_neg=. if over_rtg==.
	
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



///	Continuous measure number of standard deviations

***	Combined
xtset

gen trt_cont_sdw = over_rtg_yoy / sdw
label var trt_cont_sdw "Continuous treatment = over_rtg_yoy / sdw"

***	Positive and negative

*	sdw
gen trt_cont_sdw_pos = trt_cont_sdw
replace trt_cont_sdw_pos = . if trt_cont_sdw_pos < 0
label var trt_cont_sdw_pos "Continuous value of trt_cont_sdw if trt_cont_sdw >= 0"

gen trt_cont_sdw_neg = trt_cont_sdw
replace trt_cont_sdw_neg = . if trt_cont_sdw_neg > 0
label var trt_cont_sdw_neg "Continuous value of trt_cont_sdw if trt_cont_sdw <= 0"


///	Categorical measure standard deviations rounded to integer

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


///	FIX MARKER VARIABLES
foreach variable of varlist in_csrhub in_kld in_cstat {
	replace `variable'=0 if `variable'==.
}

/// SET PANEL
drop cusip_n
label drop _all
encode cusip8, gen(cusip_n)
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








*************************************************************
*															*
*	Assess treatment variables distribution and zscores		*
*															*
*************************************************************
bysort cusip_n: egen yoy_mean = mean(over_rtg_yoy)
replace yoy_mean=. if over_rtg_yoy==.

bysort cusip_n: egen yoy_std_dev = sd(over_rtg_yoy)
replace yoy_std_dev=. if over_rtg_yoy==.

gen yoy_zscore = (over_rtg_yoy - yoy_mean) / yoy_std_dev

*	Histogram
histogram yoy_zscore, bin(100) percent normal ///
	xti("Z-score") xlab(-4(1)4) scheme(plotplain)

***	Remove firms with only two observations on year-on-year change
gen ch1 = (over_rtg_yoy!=.)
bysort cusip_n: egen ch2=total(ch1)
replace yoy_zscore=. if ch2==2

drop ch1 ch2

*	Histogram
histogram yoy_zscore, bin(100) percent normal ///
	xti("Z-score") xlab(-4(1)4) scheme(plotplain)
	

*	Example
scatter over_rtg_yoy year if cusip8=="00103079", ///
	xti("Year") ///
	yline(1.974611, lstyle(solid)) ///
	ti("Jyske Bank A/S year-on-year change in overall rating.") ///
	subti("Solid line is average year-on-year change for the firm." ///
	"Treatment at -2 z-score occurs in 2014.")
	
*	Treatment indicators
gen trt1pos = (yoy_zscore>1 & yoy_zscore!=.)
gen trt1neg = (yoy_zscore<-1 & yoy_zscore!=.)	
gen trt2pos = (yoy_zscore>2 & yoy_zscore!=.)
gen trt2neg = (yoy_zscore<-2 & yoy_zscore!=.)
gen trt3pos = (yoy_zscore>3 & yoy_zscore!=.)
gen trt3neg = (yoy_zscore<-3 & yoy_zscore!=.)




/*	THESE ARE NOT CORRECT ZSCORE CALCULATIONS

gen zscore = over_rtg_yoy/sdw	/*	This is not how to calculate a zscore	*/
bysort zscore: gen N=_N
tab N, sort
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
     135667 |    135,667       76.26       76.26
          1 |     40,799       22.93       99.19
        457 |        457        0.26       99.45
        393 |        393        0.22       99.67
        317 |        317        0.18       99.85
        100 |        100        0.06       99.91
         71 |         71        0.04       99.95
          2 |         28        0.02       99.96
         21 |         21        0.01       99.97
         18 |         18        0.01       99.98
         14 |         14        0.01       99.99
          7 |          7        0.00       99.99
          5 |          5        0.00      100.00
          4 |          4        0.00      100.00
------------+-----------------------------------
      Total |    177,901      100.00

N = 457 and N = 317 are the problem.
	  */
gen ch1=(N==457)
replace ch1=1 if N==317
bysort cusip: egen ch2=max(ch1)

*For some reason, the problem clusters in 2017
tab year if ch1==1
/*
 (KLD) Year |      Freq.     Percent        Cum.
------------+-----------------------------------
       2009 |          5        0.65        0.65
       2010 |         34        4.39        5.04
       2011 |         21        2.71        7.75
       2012 |          7        0.90        8.66
       2013 |         14        1.81       10.47
       2014 |          9        1.16       11.63
       2015 |          4        0.52       12.14
       2016 |          8        1.03       13.18
       2017 |        672       86.82      100.00
------------+-----------------------------------
      Total |        774      100.00
*/

*	Z-score for deviation of over_rtg compared to within-firm standard deviation
histogram zscore, bin(100) percent normal ///
	scheme(plotplain) ///
	xti("") ///
	ti("Number of standard deviations from the within-firm mean" "for each year-on-year change in overall rating") ///
	xline(-4 -3 -2 -1 0 1 2 3 4) ///
	xlab(-4(1)4)

*	 Table of descriptive statistics for treatment variables
tab trt1_sdw_pos
tab trt1_sdw_neg
tab trt2_sdw_pos
tab trt2_sdw_neg
tab trt3_sdw_pos
tab trt3_sdw_neg



*	Drop firms with problematic zscores resulting from only 2 observations in the data
foreach variable of varlist trt1_sdw_pos trt1_sdw_neg trt2_sdw_pos ///
	trt2_sdw_neg trt3_sdw_pos trt3_sdw_neg {
	replace `variable'=. if N==457
	replace `variable'=. if N==317
	replace zscore=. if N==457
	replace zscore=. if N==317
}

histogram zscore, bin(100) percent normal ///
	scheme(plotplain) ///
	xti("") ///
	xline(-4 -3 -2 -1 0 1 2 3 4) ///
	xlab(-4(1)4)

*	Table of descriptive statistics for treatment variables
tab trt1_sdw_pos
tab trt1_sdw_neg
tab trt2_sdw_pos
tab trt2_sdw_neg
tab trt3_sdw_pos
tab trt3_sdw_neg	

*/
	
***	Keep only years with CSRHub data
drop if year>2017
drop if year<2008

compress




*************************************************************
*															*
*	CREATE INDUSTRY VARIABLE USING 2-DIGIT SIC				*
*															*
*************************************************************
gen sic2 = substr(sic,1,2)
destring sic2, replace

gen sic2cat=""

replace sic2cat="agforfish" if sic2==1
replace sic2cat="agforfish" if sic2==2
replace sic2cat="agforfish" if sic2==7
replace sic2cat="agforfish" if sic2==8
replace sic2cat="agforfish" if sic2==9

replace sic2cat="mining" if sic2==10
replace sic2cat="mining" if sic2==12
replace sic2cat="mining" if sic2==13
replace sic2cat="mining" if sic2==14

replace sic2cat="construction" if sic2==15
replace sic2cat="construction" if sic2==16
replace sic2cat="construction" if sic2==17

replace sic2cat="manufacture" if sic2==20
replace sic2cat="manufacture" if sic2==21
replace sic2cat="manufacture" if sic2==22
replace sic2cat="manufacture" if sic2==23
replace sic2cat="manufacture" if sic2==24
replace sic2cat="manufacture" if sic2==25
replace sic2cat="manufacture" if sic2==26
replace sic2cat="manufacture" if sic2==27
replace sic2cat="manufacture" if sic2==28
replace sic2cat="manufacture" if sic2==29
replace sic2cat="manufacture" if sic2==30
replace sic2cat="manufacture" if sic2==31
replace sic2cat="manufacture" if sic2==32
replace sic2cat="manufacture" if sic2==33
replace sic2cat="manufacture" if sic2==34
replace sic2cat="manufacture" if sic2==35
replace sic2cat="manufacture" if sic2==36
replace sic2cat="manufacture" if sic2==37
replace sic2cat="manufacture" if sic2==38
replace sic2cat="manufacture" if sic2==39

replace sic2cat="transport" if sic2==40
replace sic2cat="transport" if sic2==41
replace sic2cat="transport" if sic2==42
replace sic2cat="transport" if sic2==43
replace sic2cat="transport" if sic2==44
replace sic2cat="transport" if sic2==45
replace sic2cat="transport" if sic2==46
replace sic2cat="transport" if sic2==47
replace sic2cat="transport" if sic2==48
replace sic2cat="transport" if sic2==49

replace sic2cat="wholesale" if sic2==50
replace sic2cat="wholesale" if sic2==51

replace sic2cat="retail" if sic2==52
replace sic2cat="retail" if sic2==53
replace sic2cat="retail" if sic2==54
replace sic2cat="retail" if sic2==55
replace sic2cat="retail" if sic2==56
replace sic2cat="retail" if sic2==57
replace sic2cat="retail" if sic2==58
replace sic2cat="retail" if sic2==59

replace sic2cat="finance" if sic2==60
replace sic2cat="finance" if sic2==61
replace sic2cat="finance" if sic2==62
replace sic2cat="finance" if sic2==63
replace sic2cat="finance" if sic2==64
replace sic2cat="finance" if sic2==65
replace sic2cat="finance" if sic2==67

replace sic2cat="services" if sic2==70
replace sic2cat="services" if sic2==72
replace sic2cat="services" if sic2==73
replace sic2cat="services" if sic2==75
replace sic2cat="services" if sic2==76
replace sic2cat="services" if sic2==78
replace sic2cat="services" if sic2==79
replace sic2cat="services" if sic2==80
replace sic2cat="services" if sic2==81
replace sic2cat="services" if sic2==82
replace sic2cat="services" if sic2==83
replace sic2cat="services" if sic2==84
replace sic2cat="services" if sic2==86
replace sic2cat="services" if sic2==87
replace sic2cat="services" if sic2==88
replace sic2cat="services" if sic2==89

replace sic2cat="publicadmin" if sic2==91
replace sic2cat="publicadmin" if sic2==92
replace sic2cat="publicadmin" if sic2==93
replace sic2cat="publicadmin" if sic2==94
replace sic2cat="publicadmin" if sic2==95
replace sic2cat="publicadmin" if sic2==96
replace sic2cat="publicadmin" if sic2==97
replace sic2cat="publicadmin" if sic2==99

encode sic2cat, gen(sic2division)
label var sic2division "SIC division (2-digit level)"











*************************************************************
*															*
*					SAVE									*
*															*
*************************************************************
***	Order variables
order cusip year firm firm_kld conm
format %20s firm firm_kld conm

xtset

***	Label
label data "Matched CSRHub, CSTAT, KLD 2008-2017"

***	Save
compress
save data/csrhub-kld-cstat-year-level-with-treatment-variables.dta, replace




*************************************************************
*															*
*	EXPORT UNMATCHED CSRHUB FIRMS FOR MANUAL MATCHING		*
*		WITH CSTAT AND KLD									*
*															*
*************************************************************
///	DESCRIPTIVES
tab in_csrhub
/*
Indicator = |
    1 if in |
CSRHub data |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     23,675       23.10       23.10
          1 |     78,804       76.90      100.00
------------+-----------------------------------
      Total |    102,479      100.00
*/

tab in_cstat
/*Indicator = |
    1 if in |
 CSTAT data |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     58,156       56.75       56.75
          1 |     44,323       43.25      100.00
------------+-----------------------------------
      Total |    102,479      100.00
*/

tab in_kld
/*Indicator = |
1 if in KLD |
       data |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     76,411       74.56       74.56
          1 |     26,068       25.44      100.00
------------+-----------------------------------
      Total |    102,479      100.00
*/

tab in_csrhub in_cstat
/* Indicator |
 = 1 if in |  Indicator = 1 if in
    CSRHub |      CSTAT data
      data |         0          1 |     Total
-----------+----------------------+----------
         0 |     5,281     18,394 |    23,675 
         1 |    52,875     25,929 |    78,804 
-----------+----------------------+----------
     Total |    58,156     44,323 |   102,479
*/

tab in_csrhub in_kld
/* Indicator |
 = 1 if in |  Indicator = 1 if in
    CSRHub |       KLD data
      data |         0          1 |     Total
-----------+----------------------+----------
         0 |    14,153      9,522 |    23,675 
         1 |    62,258     16,546 |    78,804 
-----------+----------------------+----------
     Total |    76,411     26,068 |   102,479 
*/


///	CSRHub firms not matched to Compustat
keep if in_csrhub==1 & in_cstat==0

keep firm cusip cusip9 year isin
order firm cusip cusip9 year isin

bysort cusip9: gen n=_n
tab n
/*
          n |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     10,162       19.22       19.22
          2 |      8,745       16.54       35.76
          3 |      7,113       13.45       49.21
          4 |      6,139       11.61       60.82
          5 |      5,300       10.02       70.84
          6 |      4,505        8.52       79.36
          7 |      3,764        7.12       86.48
          8 |      3,149        5.96       92.44
          9 |      2,385        4.51       96.95
         10 |      1,613        3.05      100.00
------------+-----------------------------------
      Total |     52,875      100.00
*/

codebook firm
/*                  type:  string (str65)

         unique values:  10,162                   missing "":  0/52,875

              examples:  "Cleveland BioLabs Inc"
                         "Health Care REIT, Inc."
                         "Multiplus SA"
                         "Sekisui House Limited"

               warning:  variable has embedded blanks
*/

keep if n==1
drop n

*	Export
export excel using "D:\Dropbox\papers\4 work in progress\dissertation-csrhub\project\data\firms in csrhub and not in compustat.xlsx"







/*
***=======================================***
*	CREATE NEW VARIABLES FOR REWB MODELS	*
***=======================================***
use data/analysis-file-cstat-kld-csrhub-cusip8-year-all.dta, clear

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

*/






*END
