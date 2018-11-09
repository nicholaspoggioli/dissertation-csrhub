********************************************************************************
*Title: Dissertation Chapter 2 Barnett and Salomon (2012) Replication and Extension
*Created by: Nicholas Poggioli (poggi005@umn.edu)
*Created on: October 2018
*Purpose: Analyze KLD and CSRHub data
********************************************************************************


/***
DATA CREATION AND CLEANING
	KLD Data
	Compustat Data
	CSRHub Data
	
SAMPLE
	Start with KLD 1991-2006
		Drop years before 1998 because KLD changed reporting standards (lose 650 firms/4,550 obs)
	Merge with COMPUSTAT
		Lose 1,236 firms to no match in COMPUSTAT
	Final sample
		1998 - 2006
		1,214 firms
		5,944 observations
	ANALYSIS SAMPLE
		Lose 1,214 obs to lagged DV as independent variable
		1,214 firms
		4,730 observations
		1998 - 2006
		
VARIABLES
	Performance
		- ROA = Net Income / Total Assets ($millions)
		- Net Income = Earnings after interest, taxes, depreciation, amortization ($millions)
	Social Responsibility (proxy for what they call "stakeholder influence capacity"
		- Net KLD Score = KLD strengths - KLD concerns
	Controls
		- Firm size = Number of employees (1000s)
		- Debt ratio = Long-term debt / Total assets
		- R&D intensity = R&D expenditures / sales
		- Advertising intensity = Advertising expenditures / sales
*/

***	CREATE VARIABLES
/*VARIABLES
	Performance
		- ROA = Net Income / Total Assets ($millions)
		- Net Income = Earnings after interest, taxes, depreciation, amortization ($millions)
	Social Responsibility (proxy for what they call "stakeholder influence capacity"
		- Net KLD Score = KLD strengths - KLD concerns
	Controls
		- Firm size = Number of employees (1000s)
		- Debt ratio = Long-term debt / Total assets
		- R&D intensity = R&D expenditures / sales
		- Advertising intensity = Advertising expenditures / sales
*/

set more off




***===========================================================***
*	Create KLD Data												*
*	By: Nicholas Poggioli poggi005@umn.edu						*
*	Date: January 2018											*
*	Nicholas Poggioli downloaded all data for all firms 		*
*	from WRDS in February 2017 as kld-all-data.dta				*
***===========================================================***

*** IMPORT DATA
use data\all-available-kld-data-from-wrds-downloaded-20180212.dta, clear

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


					***===========================***
					*								*
					*	CREATE AGGREGATE VARIABLES	*
					*								*
					***===========================***

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
          1 |     50,762       99.94       99.94
          2 |         24        0.05       99.99
          4 |          4        0.01      100.00
------------+-----------------------------------
      Total |     50,790      100.00
*/

list firm year ticker cusip if N>1, sepby(firm)
/*
       +------------------------------------------------------------+
       |                            firm   year   ticker      cusip |
       |------------------------------------------------------------|
 6107. |                    BENIHANA INC   2010            82047200 |
 6108. |                    BENIHANA INC   2010    BNHNA   82047101 |
       |------------------------------------------------------------|
 7293. |           BROADWING CORPORATION   2005     BWNG   62878610 |
 7294. |           BROADWING CORPORATION   2005     BWNG   11161E10 |
       |------------------------------------------------------------|
 9180. |    CENTRAL GARDEN & PET COMPANY   2010     CENT   15352720 |
 9181. |    CENTRAL GARDEN & PET COMPANY   2010     CENT   15352710 |
       |------------------------------------------------------------|
17466. |                   FIRST BANCORP   2014     FBNC   31891010 |
17467. |                   FIRST BANCORP   2014      FBP   31867270 |
17468. |                   FIRST BANCORP   2015     FBNC   31891010 |
17469. |                   FIRST BANCORP   2015      FBP   31867270 |
       |------------------------------------------------------------|
21580. |              HEICO CORP. (CL A)   2010      HEI   42280620 |
21581. |              HEICO CORP. (CL A)   2010      HEI   42280610 |
       |------------------------------------------------------------|
24346. |                     INVESCO LTD   2007   IVZ_LN     128269 |
24347. |                     INVESCO LTD   2007   IVZ_LN   46127U10 |
       |------------------------------------------------------------|
25515. |            KCAP FINANCIAL, INC.   2012     KCAP   50023310 |
25516. |            KCAP FINANCIAL, INC.   2012     KCAP   48668E10 |
       |------------------------------------------------------------|
37893. |             REALOGY CORPORATION   2006        H   36935210 |
37894. |             REALOGY CORPORATION   2006        H   41163G10 |
       |------------------------------------------------------------|
45900. |    TRANSOCEAN SEDCO FOREX, INC.   2000      RIG   G9007810 |
45901. |    TRANSOCEAN SEDCO FOREX, INC.   2000      RIG   CH011117 |
45902. |    TRANSOCEAN SEDCO FOREX, INC.   2000      RIG   H8817H10 |
45903. |    TRANSOCEAN SEDCO FOREX, INC.   2000      RIG   G9007310 |
       |------------------------------------------------------------|
47276. |         UNIVERSAL AMERICAN CORP   2012      UAM   91338E10 |
47277. |         UNIVERSAL AMERICAN CORP   2012      UAM   91337710 |
       |------------------------------------------------------------|
47541. | URSTADT BIDDLE PROPERTIES, INC.   2010      UBA   91728620 |
47542. | URSTADT BIDDLE PROPERTIES, INC.   2010      UBA   91728610 |
       |------------------------------------------------------------|
48216. |                     VIACOM INC.   2010     VIAB   92553P20 |
48217. |                     VIACOM INC.   2010    VIA/B   92553P10 |
       +------------------------------------------------------------+
*/
drop if N>1
drop N

***	SET PANEL
encode firm, gen(firm_n)
xtset firm_n year, y

***	SAVE
compress
label data "KLD Data 1991 - 2015 downloaded Feb 12, 2018 by poggi005@umn.edu"
save data\kld-all-clean.dta, replace



***===================================================================***
*	Create Compustat Data												*
*	By: Nicholas Poggioli poggi005@umn.edu								*
*	Compustat Annual Data with variables used in						*
*		Barnett & Salomon 2012 downloaded from 							*
*		Wharton Research Data Service (WRDS)							*
*	Data saved as 														*
*     cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta 	*
***===================================================================***
/*	No data creation needed because the data were simply downloaded from
	WRDS
*/

***===================================================================***
*	Create CSRHub Data													*
*	By: Nicholas Poggioli poggi005@umn.edu								*
*	Compustat Annual Data with variables used in						*
*		Barnett & Salomon 2012 downloaded from 							*
*		Wharton Research Data Service (WRDS)							*
*	Data saved as 														*
*     cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta 	*
***===================================================================***

*	CODE TO CONVERT RAW .CSVS TO STATSETS, LAST RUN MARCH 2, 2018 (LINES 39 - 474)

			***===========================================***
			*												*
			*	Convert CSRHub .csv files to Stata .dta		*
			*												*
			***====================== =====================***
***	CSRHub+Dashboard+CSR_ESG+Research--2017-04-26-OVERALL-ENVIRONMENT-RESOURCEMGMT-RANDOM-FIRMS-ALL
set more off

* 	a)	Load file
import delimited "data/data-csrhub/csrhub-raw/CSRHub+Dashboard+CSR_ESG+Research--2017-04-26 -OVERALL-ENVIRONMENT-RESOURCEMGMT-RANDOM-FIRMS-ALL.csv", ///
	varnames(13) rowrange(14) colrange(3) clear
gen row=_n+13
keep if getresultsinthesecells!=""
compress

* 	b)	Rename and label variables with variable names from first row
foreach v of varlist * {
	local varlab = `v'[1]
	label var `v' "`varlab'"
}

foreach v of varlist getresultsinthesecells v2 v3 {
	local varname = `v'[1]
	local varname2 = subinstr("`varname'"," ","",.)
	rename `v' `varname2'
}

rename CSRHubOfficialName firm
rename v104 industry
rename v105 country
drop v106

foreach v of varlist v4-v103 {
	local date = subinstr((subinstr((subinstr(`v'[1],"Overall Rating (","",.)),")","",.))," ","",.)
	local varname = "over_rtg`date'"
	rename `v' `varname'
}

foreach v of varlist v107-v206 {
	local date = subinstr((subinstr((subinstr(`v'[1],"# of Sources Used in Rating (","",.)),")","",.))," ","",.)
	local varname = "num_sources`date'"
	rename `v' `varname'
}

foreach v of varlist v207-v306 {
	local date = subinstr((subinstr((subinstr(`v'[1],"Industry Average Rating (","",.)),")","",.))," ","",.)
	local varname = "industry_avg_rtg`date'"
	rename `v' `varname'
}

foreach v of varlist v307-v406 {
	local date = subinstr((subinstr((subinstr(`v'[1],"Environment Rating (","",.)),")","",.))," ","",.)
	local varname = "enviro_rtg`date'"
	rename `v' `varname'
}

foreach v of varlist v407-v506 {
	local date = subinstr((subinstr((subinstr(`v'[1],"Environment Policy & Reporting Rating (","",.)),")","",.))," ","",.)
	local varname = "enviro_pol_rpt_rtg`date'"
	rename `v' `varname'
}

foreach v of varlist v507-v606 {
	local date = subinstr((subinstr((subinstr(`v'[1],"Resource Management Rating (","",.)),")","",.))," ","",.)
	local varname = "resource_mgmt_rtg`date'"
	rename `v' `varname'
}

*	c)	Reshape from wide to long
order industry country, after(ISIN)

drop in 1

bysort firm: gen n=_n
drop if n>1
drop row n

reshape long over_rtg num_sources industry_avg_rtg enviro_rtg ///
	enviro_pol_rpt_rtg resource_mgmt_rtg, i(firm) j(date) string

drop if over_rtg=="NA"
compress

*Destring numerics	
foreach v of varlist over_rtg num_sources industry_avg_rtg enviro_rtg ///
	enviro_pol_rpt_rtg resource_mgmt_rtg {
	replace `v'="" if `v'=="NA"
	destring `v', replace
}
compress

*Generate date variables
gen datenum=date(date,"MY")
gen month=month(datenum)
gen year=year(datenum)
order datenum, after(date)

*Standardize country to iso3 codes
replace country="Macao" if country=="Macau"
replace country="Korea, Republic of" if country=="South Korea"
replace country="Taiwan, Province of China" if country=="Taiwan"
replace country="United States" if country=="USA"


*	d)	Save as .dta
gen in_ovrl_enviro=1
compress
save "data/data-csrhub/csrhub-raw/OVERALL-ENVIRO.dta", replace



***	CSRHub+Dashboard+CSR_ESG+Research--2017-04-26-ALL-OTHER-VARIABLES-_________.csv

*	a) 	Load data
set more off
local files : dir "data/data-csrhub/csrhub-raw" files "*all-other*.csv"
display `files'

local n=1

foreach file of local files {
	display("`file'")
	import delimited "data/data-csrhub/csrhub-raw/`file'", clear ///
	varnames(13) rowrange(14) colrange(3)
	drop if getresultsinthesecells==""

	* 	b)	Rename and label variables with variable names from first row
	*Label
	foreach v of varlist * {
		local varlab = `v'[1]
		label var `v' "`varlab'"
	}
	drop v1404

	*Rename
	foreach v of varlist getresultsinthesecells v2 v3 {
		local varname = `v'[1]
		local varname2 = subinstr("`varname'"," ","",.)
		rename `v' `varname2'
	}

	rename CSRHubOfficialName firm

	foreach v of varlist v4-v103 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Overall Percentile Rank (","",.)),")","",.))," ","",.)
		local varname = "over_pct_rank`date'"
		rename `v' `varname'
	}


	foreach v of varlist v104-v203 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Community Rating (","",.)),")","",.))," ","",.)
		local varname = "cmty_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v204-v303 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Employees Rating (","",.)),")","",.))," ","",.)
		local varname = "emp_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v304-v403 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Governance Rating (","",.)),")","",.))," ","",.)
		local varname = "gov_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v404-v503 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Community Dev & Philanthropy Rating (","",.)),")","",.))," ","",.)
		local varname = "com_dev_phl_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v504-v603 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Human Rights & Supply Chain Rating (","",.)),")","",.))," ","",.)
		local varname = "humrts_supchain_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v604-v703 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Product Rating (","",.)),")","",.))," ","",.)
		local varname = "prod_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v704-v803 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Compensation & Benefits Rating (","",.)),")","",.))," ","",.)
		local varname = "comp_ben_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v804-v903 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Diversity & Labor Rights Rating (","",.)),")","",.))," ","",.)
		local varname = "div_lab_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v904-v1003 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Training, Health & Safety Rating (","",.)),")","",.))," ","",.)
		local varname = "train_hlth_safe_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v1004-v1103 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Energy & Climate Change Rating (","",.)),")","",.))," ","",.)
		local varname = "enrgy_climchge_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v1104-v1203 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Board Rating (","",.)),")","",.))," ","",.)
		local varname = "board_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v1204-v1303 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Leadership Ethics Rating (","",.)),")","",.))," ","",.)
		local varname = "ldrship_ethics_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v1304-v1403 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Transparency & Reporting Rating (","",.)),")","",.))," ","",.)
		local varname = "trans_report_rtg`date'"
		rename `v' `varname'
	}

	*	c)	Reshape
	drop in 1

	reshape long over_pct_rank cmty_rtg emp_rtg gov_rtg com_dev_phl_rtg humrts_supchain_rtg ///
		prod_rtg comp_ben_rtg div_lab_rtg train_hlth_safe_rtg enrgy_climchge_rtg ///
		board_rtg ldrship_ethics_rtg trans_report_rtg, i(firm) j(date) string

	*Destring numerics	
	foreach v of varlist over_pct_rank cmty_rtg emp_rtg gov_rtg com_dev_phl_rtg ///
		humrts_supchain_rtg prod_rtg comp_ben_rtg div_lab_rtg train_hlth_safe_rtg ///
		enrgy_climchge_rtg board_rtg ldrship_ethics_rtg trans_report_rtg {
		replace `v'="" if `v'=="NA"
		destring `v', replace
	}

	gen check = max(over_pct_rank, cmty_rtg, emp_rtg, gov_rtg, com_dev_phl_rtg, humrts_supchain_rtg, prod_rtg, comp_ben_rtg, div_lab_rtg, train_hlth_safe_rtg, enrgy_climchge_rtg, board_rtg, ldrship_ethics_rtg, trans_report_rtg)
	drop if check==.
	drop check
	compress

	*	d)	Append
	capt noisily append using `file1'
	tempfile file1
	save `file1'
}

*Generate date variables
gen datenum=date(date,"MY")
gen month=month(datenum)
gen year=year(datenum)
order datenum, after(date)

*	Save unique firm dates
bysort firm date: gen N=_N
tab N
/*. tab N

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    855,620       99.97       99.97
          2 |        248        0.03      100.00
------------+-----------------------------------
      Total |    855,868      100.00
*/
tab firm if N>1
/*
. tab firm if N>1

                   CSRHub Official Name |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
            Embratel Participacoes S.A. |         58       23.39       23.39
                     RHB Capital Berhad |        190       76.61      100.00
----------------------------------------+-----------------------------------
                                  Total |        248      100.00
*/
bysort firm date: gen n=_n
drop if n>1	/* 	Appear to have duplicates for all obs of Embratel Participacoes S.A.
				and RHB Capital Berhad. Duplicates need to be dropped for merge	*/

drop N

bysort firm date: gen N=_N
tab N
/*. tab N

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    855,744      100.00      100.00
------------+-----------------------------------
      Total |    855,744      100.00
*/
drop n N


*	e)	Save
gen in_other_vars=1
compress
save "data/data-csrhub/csrhub-raw/OTHER-VARIABLES-ALL.dta", replace


***	CSRHub+Dashboard+CSR_ESG+Research--2017-06-12-updating data from march 2017 to sept 2017-________.csv
set more off
local files : dir "data/data-csrhub/csrhub-raw/" files "*updating data*.csv"

local n=1

foreach file of local files {
	display("`file'")
	import delimited "data/data-csrhub/csrhub-raw/`file'", clear ///
	varnames(13)
	
	* 	b)	Rename and label variables with variable names from first row
	*Label
	foreach v of varlist * {
		local varlab = `v'[1]
		label var `v' "`varlab'"
	}
	
	*Rename
	rename (getresultsinthesecells v4 v5) (firm ticker isin)
	drop enteryourdatainthesecells v2
	
	foreach v of varlist v6-v12 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Overall Rating (","",.)),")","",.))," ","",.)
		local varname = "over_rtg`date'"
		rename `v' `varname'
	}
	
	foreach v of varlist v13-v19 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Overall Percentile Rank (","",.)),")","",.))," ","",.)
		local varname = "over_pct_rank`date'"
		rename `v' `varname'
	}

	rename (v20 v21) (industry country)

	foreach v of varlist v22-v28 {
		local date = subinstr((subinstr((subinstr(`v'[1],"# of Sources Used in Rating (","",.)),")","",.))," ","",.)
		local varname = "num_sources`date'"
		rename `v' `varname'
	}

	drop v29-v35
	
	foreach v of varlist v36-v42 {
	local date = subinstr((subinstr((subinstr(`v'[1],"Industry Average Rating (","",.)),")","",.))," ","",.)
	local varname = "industry_avg_rtg`date'"
	rename `v' `varname'
	}

	foreach v of varlist v43-v49 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Employees Rating (","",.)),")","",.))," ","",.)
		local varname = "emp_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v50-v56 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Environment Rating (","",.)),")","",.))," ","",.)
		local varname = "enviro_rtg`date'"
		rename `v' `varname'
	}
	
	foreach v of varlist v57-v63 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Governance Rating (","",.)),")","",.))," ","",.)
		local varname = "gov_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v64-v70 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Community Dev & Philanthropy Rating (","",.)),")","",.))," ","",.)
		local varname = "com_dev_phl_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v71-v77 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Human Rights & Supply Chain Rating (","",.)),")","",.))," ","",.)
		local varname = "humrts_supchain_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v78-v84 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Product Rating (","",.)),")","",.))," ","",.)
		local varname = "prod_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v85-v91 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Compensation & Benefits Rating (","",.)),")","",.))," ","",.)
		local varname = "comp_ben_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v92-v98 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Diversity & Labor Rights Rating (","",.)),")","",.))," ","",.)
		local varname = "div_lab_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v99-v105 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Training, Health & Safety Rating (","",.)),")","",.))," ","",.)
		local varname = "train_hlth_safe_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v106-v112 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Energy & Climate Change Rating (","",.)),")","",.))," ","",.)
		local varname = "enrgy_climchge_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v113-v119 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Environment Policy & Reporting Rating (","",.)),")","",.))," ","",.)
		local varname = "enviro_pol_rpt_rtg`date'"
		rename `v' `varname'
	} 
	foreach v of varlist v120-v126 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Resource Management Rating (","",.)),")","",.))," ","",.)
		local varname = "resource_mgmt_rtg`date'"
		rename `v' `varname'	
	}	
	foreach v of varlist v127-v133 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Board Rating (","",.)),")","",.))," ","",.)
		local varname = "board_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v134-v140 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Leadership Ethics Rating (","",.)),")","",.))," ","",.)
		local varname = "ldrship_ethics_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v141-v147 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Transparency & Reporting Rating (","",.)),")","",.))," ","",.)
		local varname = "trans_report_rtg`date'"
		rename `v' `varname'
	}

	*	c)	Reshape
	drop in 1
	drop if firm==""
	
	reshape long over_rtg over_pct_rank num_sources industry_avg_rtg emp_rtg ///
		enviro_rtg gov_rtg com_dev_phl_rtg humrts_supchain_rtg prod_rtg comp_ben_rtg ///
		div_lab_rtg train_hlth_safe_rtg enrgy_climchge_rtg enviro_pol_rpt_rtg ///
		resource_mgmt_rtg board_rtg ldrship_ethics_rtg trans_report_rtg, i(firm) j(date) string

	*Destring numerics	
	foreach v of varlist over_rtg over_pct_rank num_sources industry_avg_rtg emp_rtg ///
		enviro_rtg gov_rtg com_dev_phl_rtg humrts_supchain_rtg prod_rtg comp_ben_rtg ///
		div_lab_rtg train_hlth_safe_rtg enrgy_climchge_rtg enviro_pol_rpt_rtg ///
		resource_mgmt_rtg board_rtg ldrship_ethics_rtg trans_report_rtg {
		replace `v'="" if `v'=="NA"
		destring `v', replace
	}

	gen check = max(over_rtg , over_pct_rank , industry_avg_rtg , emp_rtg , enviro_rtg , gov_rtg , com_dev_phl_rtg , humrts_supchain_rtg , prod_rtg , comp_ben_rtg , div_lab_rtg , train_hlth_safe_rtg , enrgy_climchge_rtg , enviro_pol_rpt_rtg , resource_mgmt_rtg , board_rtg , ldrship_ethics_rtg , trans_report_rtg)
	drop if check==.
	drop check
	compress

	*	d)	Append
	capt noisily append using `file1'
	tempfile file1
	save `file1'
}

*Generate date variables
gen datenum=date(date,"MY")
gen month=month(datenum)
gen year=year(datenum)
order datenum, after(date)

*	Keep unique firm date
bysort firm date: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    120,645       99.97       99.97
          2 |         42        0.03      100.00
------------+-----------------------------------
      Total |    120,687      100.00
*/

bysort firm date: gen n=_n
tab n
/*
          n |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    120,666       99.98       99.98
          2 |         21        0.02      100.00
------------+-----------------------------------
      Total |    120,687      100.00
*/

/*	THESE ALL APPEAR TO BE EXACT DUPLICATES SO I DROP THE DUPLICATES	*/
drop if n>1
drop N n

*	Rename variables for appending to other CSRHub datasets
rename (isin ticker) (ISIN Ticker)

*	e)	Save
gen in_2017_update=1
label var in_2017_update "(CSRHub) =1 if in 2017 data downloaded in early 2018"
compress
save "data/data-csrhub/csrhub-raw/UPDATE-2017.dta", replace
*/

						***=========================*
						*							*
						*	Merge CSRHub datasets	*
						*							*
						***=========================*
*	LAST RUN MARCH 9 2018 (LINES 553-794)
						
set more off
***	OVERALL RATINGS
use data/data-csrhub/csrhub-raw/OVERALL-ENVIRO.DTA, clear
bysort firm date: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    512,381      100.00      100.00
------------+-----------------------------------
      Total |    512,381      100.00
*/
drop N

*	Merge other variables file
merge 1:1 firm date using "data/data-csrhub/csrhub-raw/OTHER-VARIABLES-ALL.dta", nogen
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       348,985
        from master                     2,811  (_merge==1)
        from using                    346,174  (_merge==2)

    matched                           509,570  (_merge==3)
    -----------------------------------------
*/

*	Merge data update
append using "data/data-csrhub/csrhub-raw/UPDATE-2017.dta"

bysort firm date: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    952,891       97.31       97.31
          2 |     26,330        2.69      100.00
------------+-----------------------------------
      Total |    979,221      100.00
*/
tab date if N>1
/*
         date |      Freq.     Percent        Cum.
--------------+-----------------------------------
    March2017 |     26,330      100.00      100.00
--------------+-----------------------------------
        Total |     26,330      100.00
*/
drop N
*Keep the observations in the more recent March 2017 download
drop if date=="March2017" & in_2017_update!=1
*(13,344 observations deleted)

bysort firm date: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    965,877      100.00      100.00
------------+-----------------------------------
      Total |    965,877      100.00
*/
drop N

foreach v of varlist in_* {
	replace `v' = 0 if `v'==.
}

***	Fill in missing variables
*	Industry
gsort firm -industry
by firm: gen ind_ch=(industry!=industry[_n-1]) if industry!="" & industry[_n-1]!=""
by firm: replace industry=industry[_n-1] if industry=="" & _n!=1 /* Confirm no industry changes in data	*/
drop ind_ch

*	Country
gsort firm -country
by firm: gen ctry_ch=(country!=country[_n-1]) if country!="" & country[_n-1]!=""
by firm: egen c=sum(ctry_ch)
/*	Reveals these country variable inconsistencies:
		United States and USA
		Taiwan, Province of China and Taiwan
		South Korea and Korea, Republic of
		South Korea and Korea
		Macau and Macao
*/
drop ctry_ch c

replace country="United States" if country=="USA"
replace country="Taiwan, Province of China" if country=="Taiwan"
replace country="Korea, Republic of" if country=="South Korea"
replace country="Korea, Republic of" if country=="Korea"
replace country="Macao" if country=="Macau"

by firm: gen ctry_ch=(country!=country[_n-1]) if country!="" & country[_n-1]!=""
by firm: egen c=sum(ctry_ch)
drop ctry_ch c
/*	All country changes accounted for. All were changes in spelling of same country	*/

gsort firm -country
by firm: replace country=country[_n-1] if country=="" & _n!=1

***	Save
sort firm datenum
order firm date board_rtg cmty_rtg com_dev_phl_rtg comp_ben_rtg div_lab_rtg ///
	emp_rtg enrgy_climchge_rtg enviro_pol_rpt_rtg enviro_rtg gov_rtg ///
	humrts_supchain_rtg industry_avg_rtg ///
	ldrship_ethics_rtg over_pct_rank over_rtg prod_rtg resource_mgmt_rtg ///
	train_hlth_safe_rtg trans_report_rtg Ticker ISIN country industry datenum month year ///
	in_other_vars in_ovrl_enviro 

*Label
label var board_rtg "(CSRHub) Board Rating"
label var cmty_rtg "(CSRHub) Community Rating"
label var com_dev_phl_rtg "(CSRHub) Community Development and Philanthropy Rating"
label var comp_ben_rtg "(CSRHub) Compensation and Benefits Rating"
label var country "(CSRHub) Firm Country Location"
label var date "(CSRHub) Ratings Date"
label var datenum "(CSRHub) Numerical Stata Value for Day"
label var div_lab_rtg "(CSRHub) Diversity and Labor Rights Rating"
label var emp_rtg "(CSRHub) Employee Rating"
label var enrgy_climchge_rtg "(CSRHub) Energy and Climate Change Rating"
label var enviro_pol_rpt_rtg "(CSRHub) Environmental Policy and Reporting Rating"
label var enviro_rtg "(CSRHub) Environmental Rating"
label var firm "(CSRHub) Official Company Name"
label var gov_rtg "(CSRHub) Governance Rating"
label var humrts_supchain_rtg "(CSRHub) Human Rights and Supply Chain Rating"
label var in_other_vars "(CSRHub) =1 if in OTHER VARIABLES file"
label var in_ovrl_enviro "(CSRHub) =1 if in OVERALL ENVIRONMENT RESOURCEMGMT csv"
label var industry "(CSRhub) Industry Classification"
label var industry_avg_rtg "(CSRHub) Industry Average over_rtg"
label var ISIN "(CSRHub) ISIN"
label var ldrship_ethics_rtg "(CSRHub) Leadership Ethics Rating"
label var month "(CSRHub) Data Month"
label var num_sources "(CSRHub) Number of Sources for Calculating Overall Rating"
label var over_rtg "(CSRHub) Overall Rating"
label var over_pct_rank "(CSRHub) Overall Percentile Rank"
label var prod_rtg "(CSRHub) Product Rating"
label var resource_mgmt_rtg "(CSRHub) Resource Management Rating"
label var Ticker "(CSRHub) Firm Ticker Symbol"
label var train_hlth_safe_rtg "(CSRHub) Training and Health and Safety Rating"
label var trans_report_rtg "(CSRHub) Transparency and Reporting Rating"
label var year "(CSRHub) Data Year"

*	Create variables
encode firm,gen(firm_n)
gen ym=ym(year,month)
label var firm_n "(CSRHub) Firm Encoded as Numerical"
label var ym "(CSRHub) Year-Month Date Value"

gen tic_csrhub = Ticker
label var tic_csrhub "(CSRHub) ticker"

gen in_csrhub=1
label var in_csrhub "(CSRHub) =1 if in csrhub data"


*	Set panel
xtset firm_n ym, m

by firm_n: gen csrhub_first = (_n==1)
label var csrhub_first "(CSRHub) =1 for year-month of firm's first appearance in data"

by firm_n: gen n = _n
by firm_n: gen N = _N
by firm_n: gen csrhub_last = (N - n == 0)
drop n N
label var csrhub_last "(CSRHub) =1 for year-month of firm's last appearance in data"

gen csrhub_cr = (date=="March2017")
label var csrhub_cr "(CSRHub) =1 if firm in last year-month of CSRHub data (right censor)"
gen csrhub_cl = (date=="December2008")
label var csrhub_cl "(CSRHub) =1 if firm in first year-month of CSRHub data (left censor)"

*	Rename and order
rename Ticker ticker
rename ISIN isin

order in_*, last

*	Label data
label data "CSRHub Data December 2008 - September 2017"

*	Create CSRHub row id
gen row_id_csrhub=_n
label var row_id_csrhub "(CSRHub) Unique row identifier"

						***===================***
						*						*
						*	Merge iso3 codes	*
						*						*
						***===================***
replace country="Jersey" if country=="Channel Islands"
/*	Channel Islands are known as Jersey	*/
replace country="Iran, Islamic Republic of" if country=="Iran"
replace country="Cote d'Ivoire" if country=="Ivory Coast"
replace country="Macedonia, the Former Yugoslav Republic of" if country=="Macedonia"
replace country="Moldova, Republic of" if country=="Moldova"
replace country="Norway" if country=="NORWAY"
replace country="Palestine, State of" if country=="Palestine"
replace country="Syrian Arab Republic" if country=="Syria"
replace country="Trinidad and Tobago" if country=="Trinidad & Tobago"
replace country="Viet Nam" if country=="Vietnam"

merge m:1 country using "data/data-csrhub/country-codes-iso3-conversion.dta", ///
	keepusing(A3UN)
/* 
    Result                           # of obs.
    -----------------------------------------
    not matched                         2,390
        from master                     2,273  (_merge==1)
        from using                        117  (_merge==2)

    matched                           963,604  (_merge==3)
    -----------------------------------------
*/
	
label var A3UN "(United Nations) 3-digit country code"
order A3UN,after(country)
rename A3UN a3un
	
drop if _merge==2
drop _merge


*	Standardize firm names
preserve
keep firm
bysort firm: gen n=_n
keep if n==1
drop n
capt n search stnd_compname												/*	Installing user-created package	*/
stnd_compname firm, gen(stnd_firm entity_type)
tempfile d1
save `d1'
restore

merge m:1 firm using `d1', nogen
/*    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                           965,877  
    -----------------------------------------
*/

*	Save
compress
save data/csrhub-all.dta, replace

* 	Create CSRHub year-level datasets aggregating by mean and median
preserve
foreach variable of varlist *_rtg {
	rename `variable' `variable'_mean
}
collapse (mean) *_rtg_mean, by(stnd_firm year) fast
save data\csrhub-all-mean-year-level.dta, replace
restore

preserve
foreach variable of varlist *_rtg {
	rename `variable' `variable'_p50
}
collapse (median) *_rtg_p50, by(stnd_firm year) fast
save data\csrhub-all-p50-year-level.dta, replace
restore
*/





***=======================================================================***
*	MERGE CSTAT AND KLD USING ONLY UNIQUE TICKER-YEARS FROM EACH DATASET	*
*	By: Nicholas Poggioli poggi005@umn.edu									*
***=======================================================================***

***	CREATE LIST OF UNIQUE TICKER-YEARS IN CSTAT TO IMPROVE MERGE WITH KLD
capt n use data/cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear
rename tic ticker
gen year=fyear
drop if indfmt=="FS"
bysort ticker conm year: gen n=_n
tab n
/*
          n |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     90,795       99.86       99.86
          2 |         71        0.08       99.94
          3 |         39        0.04       99.99
          4 |         12        0.01      100.00
          5 |          1        0.00      100.00
------------+-----------------------------------
      Total |     90,918      100.00
*/
keep if n==1
drop n

*	Rename variables
rename cusip cusip_cstat

foreach var of varlist * {
    local lab `: var label `var''
    label var `var' "(CSTAT) `lab'"
 }

***	GENERATE VARIABLES
gen firm_cstat=conm
encode firm_cstat, gen(firm_n)
rename conm firm

*	Set panel
xtset firm_n year, y

*	ROA
gen roa = ni / at

sort firm_n year
by firm_n: gen lroa=roa[_n-1]

*	Net income
sort firm_n year
by firm_n: gen lni=ni[_n-1]
	
*	Debt ratio
gen debt = dltt / at

*	R&D
gen rd = xrd / sale

*	Advertising
gen ad = xad / sale

*	NAICS
encode naics,gen(naics_n)

*	Flag
gen in_cstat=1


***	LABEL
label var firm_cstat "(CSTAT) Firm name"
label var firm_n "(CSTAT) Firm name encoded as numeric"
label var roa "(CSTAT) Return on assets (ni / at)"
label var lroa "(CSTAT) 1-year lagged roa"
label var lni "(CSTAT) 1-year lagged ni"
label var debt "(CSTAT) Debt ratio (dltt / at)"
label var rd "(CSTAT) R&D expense by sales (xrd / sale)"
label var ad "(CSTAT) Advertising expense by sales (xad / sale)"
label var year "(CSTAT) Fiscal year"
label var in_cstat "(CSTAT) =1 if in CSTAT before merge with KLD"
label var naics_n "(CSTAT) NAICS encoded as numeric"

***	SAVE
compress
save data/unique-ticker-years-in-cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, replace

***	CREATE LIST OF UNIQUE TICKER-YEARS IN KLD DATA TO IMPROVE MERGE WITH CSTAT ON TICKER-YEAR
use data/kld-all-clean.dta, clear
keep firm ticker year cusip
sort ticker year firm

*	Fix #N/A tickers
gen ch=(ticker=="#N/A")
bysort firm: egen ch1=max(ch)
replace ticker="" if ticker=="#N/A"
gsort firm -ticker
by firm: replace ticker=ticker[_n-1] if _n!=1 & ch1>0
drop ch ch1

*	Fix empty tickers
replace ticker="ITCI" if firm=="INTRA-CELLULAR THERAPIES INC"
replace ticker="FNBCQ" if firm=="FIRST NBC BANK HOLDING CO"
replace ticker="BNHN" if firm=="BENIHANA INC"				/*	Acquired by private equity after 2012	*/
drop if cusip=="82047101"									/*	Drop duplicate Benihana with different CUSIP	*/

*	Keep unique ticker years
bysort ticker year:gen N=_N
drop if N>1
drop N

*	Rename variables
rename cusip cusip_kld

gen in_kld=1
label var in_kld "(KLD) =1 if in KLD before merge with CSTAT"

gen tic_kld = ticker
gen firm_kld=firm

*	Save
compress
save data/unique-ticker-years-in-kld-all.dta, replace


***	MERGE KLD WITH CSTAT
use data/unique-ticker-years-in-kld-all.dta, clear

merge 1:1 ticker year using data/unique-ticker-years-in-cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        74,874
        from master                    16,874  (_merge==1)
        from using                     58,000  (_merge==2)

    matched                            32,795  (_merge==3)
    -----------------------------------------
*/
drop if _merge==2
drop _merge

tempfile d1
save `d1'

use data/kld-all-clean.dta, clear


*	Fix #N/A tickers
gen ch=(ticker=="#N/A")
bysort firm: egen ch1=max(ch)
replace ticker="" if ticker=="#N/A"
gsort firm -ticker
by firm: replace ticker=ticker[_n-1] if _n!=1 & ch1>0
drop ch ch1

*	Fix empty tickers
replace ticker="ITCI" if firm=="INTRA-CELLULAR THERAPIES INC"
replace ticker="FNBCQ" if firm=="FIRST NBC BANK HOLDING CO"
replace ticker="BNHN" if firm=="BENIHANA INC"				/*	Acquired by private equity after 2012	*/
drop if cusip=="82047101"									/*	Drop duplicate Benihana with different CUSIP	*/

merge m:1 ticker year using `d1'
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         1,093
        from master                     1,093  (_merge==1)
        from using                          0  (_merge==2)

    matched                            49,669  (_merge==3)
    -----------------------------------------
*/
keep if _merge==3
drop _merge

bysort ticker year: gen N=_N
keep if N==1
drop N

***	STANDARDIZE FIRM NAME
capt n ssc install stnd_compname												/* Install user program, but need
																					to use search stnd_compname to find it, not ssc	*/
stnd_compname firm, gen(stnd_firm entity_type)
label var stnd_firm "KLD firm name standardized with stnd_compname user program"

bysort stnd_firm year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     49,660       99.98       99.98
          2 |          6        0.01       99.99
          3 |          3        0.01      100.00
------------+-----------------------------------
      Total |     49,669      100.00
*/

list stnd_firm ticker year net_kld N firm if N>1, sepby(stnd_firm year)
/*
       +---------------------------------------------------------------------------------------------+
       |                  stnd_firm   ticker   year   net_kld   N                               firm |
       |---------------------------------------------------------------------------------------------|
   57. |                1ST BANCORP     FBNC   2012         2   3                  FIRST BANCORP INC |
   58. |                1ST BANCORP      FBP   2012         0   3                      FIRST BANCORP |
   59. |                1ST BANCORP     FNLC   2012         0   3            THE FIRST BANCORP, INC. |
       |---------------------------------------------------------------------------------------------|
   60. |                1ST BANCORP      FBP   2013         2   2                      FIRST BANCORP |
   61. |                1ST BANCORP     FBNC   2013         0   2                  FIRST BANCORP INC |
       |---------------------------------------------------------------------------------------------|
17921. |                        FNB      FNB   2003        -1   2                 F.N.B. CORPORATION |
17922. |                        FNB     FNBN   2003        -1   2                          FNB CORP. |
       |---------------------------------------------------------------------------------------------|
45948. | UNITED SECURITY BANCSHARES     UBFO   2003         0   2         UNITED SECURITY BANCSHARES |
45949. | UNITED SECURITY BANCSHARES     USBI   2003         1   2   UNITED SECURITY BANCSHARES, INC. |
       +---------------------------------------------------------------------------------------------+

FNB is FNB Corporation
FBP is a bank holding company for FirstBank Puerto Rico
FBNC is a bank holding company for First Bank in North Carolina
FNBN is a private firm named FNBNY Bancorp
FNLC is a holding company for First National Bank
UBFO is United Security Bancshares, a holding company for United Security Bank
USBI appears to be an old Ticker for USB, US Bancshares, the holding company for First US Bank
*/

foreach ticker in FNB FBP FBNC FNBN FNLC UBFO USBI {
	list stnd_firm ticker year firm if ticker=="`ticker'"
}
/*
      +---------------------------------------------------------+
       |   stnd_firm   ticker   year                        firm |
       |---------------------------------------------------------|
  113. | 1ST CHICAGO      FNB   1991   FIRST CHICAGO CORPORATION |
  114. | 1ST CHICAGO      FNB   1992   FIRST CHICAGO CORPORATION |
  115. | 1ST CHICAGO      FNB   1993   FIRST CHICAGO CORPORATION |
  116. | 1ST CHICAGO      FNB   1994   FIRST CHICAGO CORPORATION |
  117. | 1ST CHICAGO      FNB   1995   FIRST CHICAGO CORPORATION |
       |---------------------------------------------------------|
17921. |         FNB      FNB   2003          F.N.B. CORPORATION |
17923. |         FNB      FNB   2004          F.N.B. CORPORATION |
17924. |         FNB      FNB   2005          F.N.B. CORPORATION |
17925. |         FNB      FNB   2006          F.N.B. CORPORATION |
17926. |         FNB      FNB   2007          F.N.B. CORPORATION |
       |---------------------------------------------------------|
17927. |         FNB      FNB   2008          F.N.B. CORPORATION |
17928. |         FNB      FNB   2009          F.N.B. CORPORATION |
17929. |         FNB      FNB   2010          F.N.B. CORPORATION |
17930. |         FNB      FNB   2011          F.N.B. CORPORATION |
17931. |         FNB      FNB   2012          F.N.B. CORPORATION |
       |---------------------------------------------------------|
17932. |         FNB      FNB   2013          F.N.B. CORPORATION |
17933. |         FNB      FNB   2014          F.N.B. CORPORATION |
17934. |         FNB      FNB   2015          F.N.B. CORPORATION |
       +---------------------------------------------------------+

       +----------------------------------------------------------------------+
       |               stnd_firm   ticker   year                         firm |
       |----------------------------------------------------------------------|
   58. |             1ST BANCORP      FBP   2012                FIRST BANCORP |
   60. |             1ST BANCORP      FBP   2013                FIRST BANCORP |
   71. | 1ST BANCORP PUERTO RICO      FBP   2003   FIRST BANCORP. PUERTO RICO |
   72. | 1ST BANCORP PUERTO RICO      FBP   2004   FIRST BANCORP. PUERTO RICO |
   73. | 1ST BANCORP PUERTO RICO      FBP   2005   FIRST BANCORP. PUERTO RICO |
       |----------------------------------------------------------------------|
   74. | 1ST BANCORP PUERTO RICO      FBP   2006   FIRST BANCORP. PUERTO RICO |
   75. | 1ST BANCORP PUERTO RICO      FBP   2007   FIRST BANCORP. PUERTO RICO |
   76. | 1ST BANCORP PUERTO RICO      FBP   2008   FIRST BANCORP. PUERTO RICO |
   77. | 1ST BANCORP PUERTO RICO      FBP   2009   FIRST BANCORP. PUERTO RICO |
   78. | 1ST BANCORP PUERTO RICO      FBP   2010   FIRST BANCORP. PUERTO RICO |
       |----------------------------------------------------------------------|
   79. | 1ST BANCORP PUERTO RICO      FBP   2011   FIRST BANCORP. PUERTO RICO |
       +----------------------------------------------------------------------+

       +-----------------------------------------------------------------------+
       |              stnd_firm   ticker   year                           firm |
       |-----------------------------------------------------------------------|
   57. |            1ST BANCORP     FBNC   2012              FIRST BANCORP INC |
   61. |            1ST BANCORP     FBNC   2013              FIRST BANCORP INC |
   62. | 1ST BANCORP N CAROLINA     FBNC   2003   FIRST BANCORP NORTH CAROLINA |
   63. | 1ST BANCORP N CAROLINA     FBNC   2004   FIRST BANCORP NORTH CAROLINA |
   64. | 1ST BANCORP N CAROLINA     FBNC   2005   FIRST BANCORP NORTH CAROLINA |
       |-----------------------------------------------------------------------|
   65. | 1ST BANCORP N CAROLINA     FBNC   2006   FIRST BANCORP NORTH CAROLINA |
   66. | 1ST BANCORP N CAROLINA     FBNC   2007   FIRST BANCORP NORTH CAROLINA |
   67. | 1ST BANCORP N CAROLINA     FBNC   2008   FIRST BANCORP NORTH CAROLINA |
   68. | 1ST BANCORP N CAROLINA     FBNC   2009   FIRST BANCORP NORTH CAROLINA |
   69. | 1ST BANCORP N CAROLINA     FBNC   2010   FIRST BANCORP NORTH CAROLINA |
       |-----------------------------------------------------------------------|
   70. | 1ST BANCORP N CAROLINA     FBNC   2011   FIRST BANCORP NORTH CAROLINA |
       +-----------------------------------------------------------------------+

       +--------------------------------------+
       | stnd_f~m   ticker   year        firm |
       |--------------------------------------|
17922. |      FNB     FNBN   2003   FNB CORP. |
       +--------------------------------------+

       +-------------------------------------------------------+
       |   stnd_firm   ticker   year                      firm |
       |-------------------------------------------------------|
   53. | 1ST BANCORP     FNLC   2008   THE FIRST BANCORP, INC. |
   54. | 1ST BANCORP     FNLC   2009   THE FIRST BANCORP, INC. |
   55. | 1ST BANCORP     FNLC   2010   THE FIRST BANCORP, INC. |
   56. | 1ST BANCORP     FNLC   2011   THE FIRST BANCORP, INC. |
   59. | 1ST BANCORP     FNLC   2012   THE FIRST BANCORP, INC. |
       +-------------------------------------------------------+

       +-------------------------------------------------------------------------+
       |                  stnd_firm   ticker   year                         firm |
       |-------------------------------------------------------------------------|
45948. | UNITED SECURITY BANCSHARES     UBFO   2003   UNITED SECURITY BANCSHARES |
45951. | UNITED SECURITY BANCSHARES     UBFO   2006   UNITED SECURITY BANCSHARES |
45952. | UNITED SECURITY BANCSHARES     UBFO   2007   UNITED SECURITY BANCSHARES |
45953. | UNITED SECURITY BANCSHARES     UBFO   2008   UNITED SECURITY BANCSHARES |
45954. | UNITED SECURITY BANCSHARES     UBFO   2009   UNITED SECURITY BANCSHARES |
       |-------------------------------------------------------------------------|
45955. | UNITED SECURITY BANCSHARES     UBFO   2010   UNITED SECURITY BANCSHARES |
       +-------------------------------------------------------------------------+

       +-------------------------------------------------------------------------------+
       |                  stnd_firm   ticker   year                               firm |
       |-------------------------------------------------------------------------------|
45949. | UNITED SECURITY BANCSHARES     USBI   2003   UNITED SECURITY BANCSHARES, INC. |
45950. | UNITED SECURITY BANCSHARES     USBI   2005   UNITED SECURITY BANCSHARES, INC. |
       +-------------------------------------------------------------------------------+
*/
replace stnd_firm = "1ST BANCORP PUERTO RICO" if ticker=="FBP"
replace stnd_firm = "1ST BANCORP N CAROLINA" if ticker=="FBNC"
replace stnd_firm = "FNBNY BANCORP" if ticker=="FNBN"
replace stnd_firm = "THE 1ST BANCORP" if ticker=="FNLC"
replace stnd_firm = "UNITED SECURITY BANCSHARES (CALIFORNIA)" if ticker=="UBFO"

drop N
bysort stnd_firm year: gen N=_N
tab N
/*

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     49,669      100.00      100.00
------------+-----------------------------------
      Total |     49,669      100.00
*/
drop N

***	SAVE
compress
save data/mergefile-kld-cstat-barnett-salomon-tickers.dta, replace


																				
*/		



***===================================***
*										*
*		Merge KLD-CSTAT with CSRHUB		*
*										*
***===================================***

***	PREPARE DATA
*use data/mergefile-kld-cstat-barnett-salomon-tickers.dta, clear
/*	Merge variables
		- firm:		stnd_firm		--> created using stnd_compname user program
		- year: 	year
*/

use data/csrhub-all.dta, clear
/*	Merge variables
		- firm:		stnd_firm		--> created using stnd_compname user program
		- year: 	year
*/

***	MERGE
merge m:1 stnd_firm year using data/mergefile-kld-cstat-barnett-salomon-tickers.dta, gen(csrhub2kldcstat)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       803,010
        from master                   771,399  (_merge==1)
        from using                     31,611  (_merge==2)

    matched                           194,478  (_merge==3)
    -----------------------------------------
*/

***	SAVE
save data/mergefile-kld-cstat-csrhub.dta, replace

*	Export for OpenRefine cleaning
*export delimited stnd_firm year firm firm_kld firm_cstat ticker tic_csrhub tic_kld ///
*	using "D:\Dropbox\papers\active\dissertation-csrhub\project\data\openrefine-cleaning-kld-cstat-csrhub.csv", replace


***===================================***
*										*
*		Merge with FACTIVA media		*
*										*
***===================================***
set more off

use data/csrhub-all.dta, clear

rename year year_csrhub

gen csrdate=dofm(ym)
gen year_all = year(csrdate)
gen year=year_all

merge m:1 year using data/factiva-stakeholder-type-by-year-media-subset.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                            29
        from master                         0  (_merge==1)
        from using                         29  (_merge==2)

    matched                           965,877  (_merge==3)
    -----------------------------------------
*/
drop if _merge!=3
drop _merge

compress
save data/CSRHub-CSTAT-KLD-FACTIVA.dta, replace















***===================***
*	CLEAN MERGED DATA	*
***===================***
***	LOAD DATA
use data/mergefile-kld-cstat-barnett-salomon-tickers.dta, clear

***	GENERATE VARIABLES
gen in_bs2012=(year>1997 & year < 2007)
label var in_bs2012 "(KLD) =1 if part of sample used in Barnett & Salomon 2012 (SMJ)"

*	Net KLD
sum net_kld
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
     net_kld |     49,669   -.1078741    2.425428        -12         19
*/

sum net_kld if in_bs==1
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
     net_kld |     16,166   -.3785723    2.171536        -11         14

Compare B&S2012			-->		my data
Obs: 	not reported  	-->		16,166
Mean:	-0.43			-->		-0.38
Min:	-12				-->		-11
Max:	 15				-->		 14
*/

gen net_kld_adj = net_kld + 12 if in_bs2012==1
/*	Barnett & Salomon add an integer to net_kld to bring minimum to 0,
	but their minimum value is -12, not -11 as I have	*/

gen net_kld_adj_sq = net_kld_adj^2 

label var net_kld_adj "(KLD) net_kld + 11 to make minimum = 0, replicating Barnett & Salomon 2012"
label var net_kld_adj_sq "(KLD) net_kld_adj squared, replicating measure in Barnett & Salomon 2012"


***	SAVE
compress
save data/kld-cstat-bs2012.dta, replace





