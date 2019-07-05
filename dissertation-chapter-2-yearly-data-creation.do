***=====================================================***
*	CHAPTER 2 DATA CREATION
*	FIRM-YEAR LEVEL DATASET COMBINING
*		CSRHUB AND COMPUSTAT GLOBAL AND NORTH AMERICA
***=====================================================***

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


***===============================================***
*	CREATE CSTAT GLOBAL CURRENCY CONVERSION FILE	*
***===============================================***
/*	PROBLEM: 	CSTAT Global reports local currency. CSTAT North Am reports USA dollars.
				Need to convert CSTAT Global to USA dollars.
				
				This can be done by using the currency exchange file from CSTAT,
				matching on curcd to convert to British pounds, then converting
				from British pounds to USD.
				
				The Compustat Global Fundamentals Annual Exchange Rate Monthly
				data were accessed at https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=162&file_id=95591
*/
///	CREATE .DTA FILE
import delimited "data\cstat-global-exchange-rate-monthly.csv", clear

***	Keep needed variables
*	exratm:		Exchange rate monthly.
*	datadate: 	The date for which exratm is valid? Documentation does not specify.
keep datadate fromcurm tocurm exratm

***	Generate variables
tostring(datadate), gen(datestring)
gen date = date(datestring,"YMD")
gen year=year(date)
gen month=month(date)
drop datestring


gen curcd = tocurm

***	Save
compress

label var tocurm "Exchange rate to currency code"
label var exratm "Exchange rate"
label var fromcurm "Exchange rate from currency code"
label var curcd "Currency code of dollar values in row"

save data\cstat-global-exchange-rate-monthly.dta, replace

***	Save only GBP to USD conversion
keep if tocurm=="USD"

rename exratm exratm_gbp_to_usd
label var exratm_gbp_to_usd "Exchange rate of GBP to USD"
rename tocurm to_usd
label var to_usd "Exchange rate currency code USD only"
drop curcd
drop datadate

compress
save data\cstat-global-exchange-rate-monthly-gbp-to-usd-only.dta, replace



***===========================================***
*	MERGE CSRHUB AND CSTAT GLOBAL ON ISIN YEAR	*
***===========================================***
///	PREPARE COMPUSTAT GLOBAL FOR MERGE
use data/cstat-all-firms-fundamentals-annual-global-2000-2018.dta, clear

***	Keep unique isin-years
gen year=fyear
codebook isin
/*
unique values:  38,028                   missing "":  2,611/479,423
*/
drop if isin==""

bysort isin year indfmt: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    578,800       99.28       99.28
          2 |      4,128        0.71       99.99
          3 |         42        0.01      100.00
          4 |          4        0.00      100.00
         14 |         14        0.00      100.00
------------+-----------------------------------
      Total |    582,988      100.00
*/
keep if N==1
drop N

***	Generate indicator variable
gen in_cstatg=1
label var in_cstatg "(CSTAT Global) =1 if in CSTAT Global"

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
    matched                            32,745  (_merge==3)
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
    not matched                       592,114
        from master                    46,059  (_merge==1)
        from using                    546,055  (_merge==2)

    matched                            32,745  (_merge==3)
    -----------------------------------------
*/

*	Save unmatched
keep if _merge==1
drop _merge gvkey indfmt datafmt consol popsrc fyear fyr datadate exchg sedol ///
	conm costat fic cik conml loc naics sic in_cstatg
compress

save data/unmatched-csrhub-cstat-global-isin-year.dta, replace





***===============================================================***
*	MERGE UNMATCHED CSRHUB AND CSTAT NORTH AMERICA ON CUSIP9 YEAR	*
***===============================================================***
///	PREPARE COMPUSTAT NORTH AMERICA FOR MERGE
use data/cstat-all-firms-fundamentals-annual-north-am-2006-2017.dta, clear

gen year = fyear
rename cusip cusip9

bysort cusip9 year indfmt: gen N=_N
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
gen in_cstatn = 1
label var in_cstatn "(CSTAT North Am) =1 if in CSTAT North America"

***	Keep industrial format when duplicate cusip9 year observations
bysort cusip9 year: gen N=_N
tab N
/*          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    110,820       80.66       80.66
          2 |     26,580       19.34      100.00
------------+-----------------------------------
      Total |    137,400      100.00
*/
bysort cusip9 year: gen n=_n
tab n
/*          n |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    124,110       90.33       90.33
          2 |     13,290        9.67      100.00
------------+-----------------------------------
      Total |    137,400      100.00
*/
drop if indfmt=="FS" & N==2

bysort cusip9 year: gen N2=_N
tab N2
/*         N2 |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    124,110      100.00      100.00
------------+-----------------------------------
      Total |    124,110      100.00
*/

drop N N2 n

***	Save
compress
save data/mergefile-cstat-fundamentals-annual-northam-2005-2017.dta, replace


///	MERGE NONMATCHED CSRHUB WITH CSTAT NORTH AM ON CUSIP9 YEAR
***	Merge and keep matched	
use data/unmatched-csrhub-cstat-global-isin-year.dta, clear

*	Merge with CSRHub on cusip9-year
merge 1:1 cusip9 year using ///
	data/mergefile-cstat-fundamentals-annual-northam-2005-2017.dta, ///
	keep(match)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                            22,928  (_merge==3)
    -----------------------------------------
*/

*	Save matched
drop _merge
compress
save data/matched-csrhub-cstat-northam-cusip9-year.dta, replace


***	Merge and keep unmatched
use data/unmatched-csrhub-cstat-global-isin-year.dta, clear

*	Merge with CSRHub on cusip9-year
merge 1:1 cusip9 year using ///
	data/mergefile-cstat-fundamentals-annual-northam-2005-2017.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       124,313
        from master                    23,131  (_merge==1)
        from using                    101,182  (_merge==2)

    matched                            22,928  (_merge==3)
    -----------------------------------------
*/

*	Save unmatched
keep if _merge==1
drop _merge tic cik gvkey datadate fyear fyr naics sic spcindcd spcseccd curcd ///
	exchg costat gsubind fic loc city ipodate indfmt conm conml in_cstatn
compress

save data/unmatched-after-csrhub-cstat-global-and-northam-exact-merges.dta, replace






***===================================================================***
*	APPEND CSRHUB/CSTAT GLOBAL AND CSRHUB/CSTAT NORTHAM DATASETS		*
***===================================================================***
///	APPEND
use data/matched-csrhub-cstat-global-isin-year.dta, clear

append using data/matched-csrhub-cstat-northam-cusip9-year.dta

///	CLEAN
***	Indictor variables
foreach variable in in_cstatg in_cstatn {
	replace `variable'=0 if `variable'==.
}

tab in_cstat*
/*
    (CSTAT |
Global) =1 |  (CSTAT North Am) =1
     if in |   if in CSTAT North
     CSTAT |        America
    Global |         0          1 |     Total
-----------+----------------------+----------
         0 |         0     22,928 |    22,928 
         1 |    32,745          0 |    32,745 
-----------+----------------------+----------
     Total |    32,745     22,928 |    55,673
*/


///	SAVE
compress
save data/merged-matched-csrhub-cstat-global-and-northam.dta, replace






***===============================================================***
*	EXPORT MATCHED FIRM IDENTIFIERS TO USE IN WRDS CSTAT DOWNLOAD	*
***===============================================================***
///	CSTAT NORTH AMERICA
use data/merged-matched-csrhub-cstat-global-and-northam.dta, clear

***	Keep North America
keep if in_cstatn==1
compress

***	Keep identifiers
keep firm_csrhub conm year cusip8 cusip9 year isin gvkey cik 
order firm_csrhub conm year cusip8 cusip9 year isin gvkey cik 


***	Keep unique gvkey
bysort gvkey: gen n=_n
tab n
/*
          n |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      4,356       19.00       19.00
          2 |      3,733       16.28       35.28
          3 |      3,363       14.67       49.95
          4 |      2,955       12.89       62.84
          5 |      2,549       11.12       73.95
          6 |      2,144        9.35       83.30
          7 |      1,716        7.48       90.79
          8 |      1,170        5.10       95.89
          9 |        942        4.11      100.00
------------+-----------------------------------
      Total |     22,928      100.00
*/
keep if n==1
drop n

***	Export list of unique gvkey
keep gvkey
export delimited using ///
	"data\unique-csrhub-gvkeys-matched-in-csrhub-and-cstat-northam.txt", ///
	delimiter(tab) novarnames replace


///	CSTAT GLOBAL
use data/merged-matched-csrhub-cstat-global-and-northam.dta, clear

***	Keep North America
keep if in_cstatg==1
compress

***	Keep identifiers
keep firm_csrhub conm year cusip8 cusip9 year isin gvkey
order firm_csrhub conm year cusip8 cusip9 year isin gvkey


***	Keep unique gvkey
bysort gvkey: gen n=_n
tab n
/*
          n |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      5,736       17.52       17.52
          2 |      5,358       16.36       33.88
          3 |      4,219       12.88       46.76
          4 |      3,633       11.09       57.86
          5 |      3,263        9.96       67.82
          6 |      2,926        8.94       76.76
          7 |      2,561        7.82       84.58
          8 |      2,184        6.67       91.25
          9 |      1,699        5.19       96.44
         10 |      1,166        3.56      100.00
------------+-----------------------------------
      Total |     32,745      100.00
*/
keep if n==1
drop n

***	Export list of unique gvkey
keep gvkey
export delimited using ///
	"data\unique-csrhub-gvkeys-matched-in-csrhub-and-cstat-global.txt", ///
	delimiter(tab) novarnames replace



	
	
***===================================================================***
*	MERGE NORTHAM MATCHES WITH NORTHAM AND GLOBAL DATA ON GVKEY-YEAR	*
***===================================================================***
///	PREPARE CSTAT NORTH AM DATA FOR MERGE
use data/cstat-all-variables-for-gvkeys-in-matched-csrhub-cstat-northam.dta, clear

***	Generate year and drop missing
gen year = fyear
drop if year==.

***	Drop business description
drop busdesc

***	Drop duplicate gvkey year
bysort gvkey year: gen N=_N
tab N
/*          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     46,161       67.54       67.54
          2 |     22,182       32.46      100.00
------------+-----------------------------------
      Total |     68,343      100.00
*/

bysort gvkey year indfmt: gen N2=_N
tab N2
/*
         N2 |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     68,343      100.00      100.00
------------+-----------------------------------
      Total |     68,343      100.00
*/

*	Drop indfmt FS if duplicate INDL in gvkey year
drop if indfmt=="FS" & N==2

bysort gvkey year: gen N3=_N
tab N3
/*
         N3 |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     57,252      100.00      100.00
------------+-----------------------------------
      Total |     57,252      100.00
*/

drop N N2 N3

***	Save
compress
save data/cstat-all-variables-for-gvkeys-in-matched-csrhub-cstat-northam-for-merge.dta, replace
	
	
///	PREPARE CSTAT GLOBAL DATA FOR MERGE
use data/cstat-all-variables-for-gvkeys-in-matched-csrhub-cstat-global.dta, clear

***	Generate year and drop duplicates
gen year = fyear
bysort gvkey year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     83,749       99.56       99.56
          2 |        370        0.44      100.00
------------+-----------------------------------
      Total |     84,119      100.00
*/
drop if N>1
drop N

***	Prep for merge
gen month=fyr

*	Fix incorrect curcd codes
replace curcd="VND" if gvkey=="286468" & year==2013


***	Merge on curcd year month
merge m:1 curcd year month using data\cstat-global-exchange-rate-monthly.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        60,845
        from master                     3,745  (_merge==1)
        from using                     57,100  (_merge==2)

    matched                            80,004  (_merge==3)
    -----------------------------------------
*/
drop if _merge==2
drop if _merge==1 /*	All 2018 observations	*/
drop _merge



***	Merge on fromcurm year month to get GBP to USD conversion
merge m:1 fromcurm year month ///
	using data\cstat-global-exchange-rate-monthly-gbp-to-usd-only.dta, ///
	update assert(1 2 3 4 5)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                           247
        from master                         0  (_merge==1)
        from using                        247  (_merge==2)

    matched                            80,004
        not updated                    80,004  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/
drop if _merge==2
drop _merge




///	CONVERT CURRENCY VARIABLES USED IN EMPIRICAL ANALYSIS TO USD
foreach variable in revt dltt at csho ceq {
	gen `variable'_usd = (`variable'/exratm)*exratm_gbp_to_usd
	label var `variable'_usd "`variable' in United States dollars"
}

***	Save
drop busdesc weburl 
compress
save data/cstat-all-variables-for-gvkeys-in-matched-csrhub-cstat-global-for-merge.dta, replace



///	MERGE CSRHUB-CSTAT WITH CSTAT NORTHAM DATA
use data/merged-matched-csrhub-cstat-global-and-northam.dta, clear

***	Merge on gvkey year
merge 1:1 gvkey year using ///
	data/cstat-all-variables-for-gvkeys-in-matched-csrhub-cstat-northam-for-merge.dta, ///
	gen(_merge_northam)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        67,081
        from master                    32,751  (_merge_northam==1)
        from using                     34,330  (_merge_northam==2)

    matched                            22,922  (_merge_northam==3)
    -----------------------------------------
*/
drop if _merge_northam==2


///	MERGE CSRHUB-CSTAT WITH CSTAT GLOBAL DATA
***	Merge on gvkey year and update missing values of compustat
merge 1:1 gvkey year using ///
	data/cstat-all-variables-for-gvkeys-in-matched-csrhub-cstat-global-for-merge.dta, ///
	gen(_merge_global) ///
	update assert(1 2 3 4 5)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        73,932
        from master                    22,928  (_merge_global==1)
        from using                     51,004  (_merge_global==2)

    matched                            32,745
        not updated                         0  (_merge_global==3)
        missing updated                32,700  (_merge_global==4)
        nonmissing conflict                45  (_merge_global==5)
    -----------------------------------------
*/
drop if _merge_global==2	

///	EXAMINE
***	Ensure all observations merged
tab _merge*, miss
/*
                      |          _merge_global
       _merge_northam | master on  missing u  nonmissin |     Total
----------------------+---------------------------------+----------
      master only (1) |        11     32,700         40 |    32,751 
          matched (3) |    22,917          0          5 |    22,922 
----------------------+---------------------------------+----------
                Total |    22,928     32,700         45 |    55,673
*/

***	List firms that merged in neither
list firm year if _merge_northam==1 & _merge_global==1
/*
       +-------------------------------------------------------+
       |                                           firm   year |
       |-------------------------------------------------------|
 7977. |                                TMX Group, Inc.   2011 |
 9660. | Science Applications International Corporation   2008 |
10453. |                          ServiceMaster Company   2009 |
10454. |                          ServiceMaster Company   2010 |
10455. |                          ServiceMaster Company   2011 |
       |-------------------------------------------------------|
10456. |                          ServiceMaster Company   2012 |
11450. |                                       Exterran   2012 |
11455. |                   The Babcock & Wilcox Company   2010 |
11456. |                   The Babcock & Wilcox Company   2011 |
11457. |                   The Babcock & Wilcox Company   2012 |
       |-------------------------------------------------------|
16570. |         Bright Horizons Family Solutions, Inc.   2008 |
       +-------------------------------------------------------+
*/

***	List firms that merged in both
list firm year if _merge_northam==3 & _merge_global==5
/*
       +-------------------------+
       |             firm   year |
       |-------------------------|
 8434. | Signet Group PLC   2009 |
 8435. | Signet Group PLC   2010 |
 8436. | Signet Group PLC   2011 |
 8437. | Signet Group PLC   2012 |
 8438. | Signet Group PLC   2013 |
       +-------------------------+
*/

///	KEEP NEEDED VARIABLES
keep firm year *_lym gvkey fyear industry in_* conm loc naics sic tic ipodate ///
	cusip *_usd revt dltt at csho ceq cusip8 xad* xrd* curcd prcc_c prcc_f emp

///	SAVE
compress
save data/matched-csrhub-cstat-northam-and-global-2008-2017, replace




						***===============================***
						*									*
						*  	   CREATE FIRM AGE VARIABLE		*
						*									*
						***===============================***
///	CSTAT NORTH AMERICA
use data/cstat-north-am-for-age-calculation.dta, clear

*	Create age variable
bysort gvkey: gen n=_n

gen start = fyear if n==1
bysort gvkey: replace start=start[_n-1] if start==.

gen age = (fyear - start) + 1

drop n start

*	Keep CSRHub years
keep if fyear > 2007
keep if fyear < 2018

*	Save
compress
save data/cstat-north-am-for-age-calculation-with-age-variable.dta, replace

///	MERGED MATCHED DATA WITH AGE VARIABLE
use data/matched-csrhub-cstat-northam-and-global-2008-2017, clear

merge 1:1 gvkey fyear using ///
	data/cstat-north-am-for-age-calculation-with-age-variable.dta, ///
	keepusing(age) update assert(1 2 3 4 5)
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       117,320
        from master                    29,999  (_merge==1)
        from using                     87,321  (_merge==2)

    matched                            25,674
        not updated                    25,674  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/
drop if _merge==2

///	CSTAT GLOBAL
***	NOTE: CSTAT GLOBAL is unreliable for creating firm age from first
*			appearance in the data
*		  Might use ipodate, but many missing.

/// REPLACE MISSING AGE WITH IPODATE WHERE AVAILABLE
gen ipoyear=year(ipodate)

replace age = (fyear - ipoyear) + 1 if age == .

drop ipoyear

replace age = . if age < 1


						***===============================***
						*									*
						*  	CURRENCY-ADJUST VARIABLES
						*									*
						***===============================***
/*	Varibales to adjust: revt dltt at csho ceq	*/

foreach variable in revt dltt at csho ceq {
	replace `variable'_usd=`variable' if in_cstatn==1 & `variable'_usd==.
	label var `variable'_usd "(CSTAT) `variable' in USD"
}

///	SAVE
compress
save data/matched-csrhub-cstat-northam-and-global-2008-2017-with-age.dta, replace



			***======================================================***
			*	CREATE TREATMENT VARIABLES
			*		- Binary +/- deviation from standard deviation
			*		- Continuous measure number of standard deviations
			*		- Categorical measure standard deviations rounded to integer
			***======================================================***
///	LOAD DATA
clear all
use data/matched-csrhub-cstat-northam-and-global-2008-2017-with-age.dta, clear


///	SET PANEL
encode gvkey, gen(gvkey_num)
xtset gvkey_num year, y


///	Generate year-on-year change in over_rtg
rename over_rtg_lym over_rtg

gen over_rtg_yoy = over_rtg - l.over_rtg
label var over_rtg_yoy "Year-on-year change in CSRHub overall rating"


///	Binary +/- deviation from standard deviation
***	Firm-specific within-firm standard deviation

*	Generate firm-specific within-firm over_rtg standard deviation
by gvkey_num: egen sdw = sd(over_rtg)
label var sdw "Within-firm standard deviation of over_rtg for each gvkey_num"
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
	by gvkey_num: gen trt_yr_sdw_pos = year if trt`threshold'_sdw_pos==1
	sort gvkey_num trt_yr_sdw_pos
	by gvkey_num: replace trt_yr_sdw_pos = trt_yr_sdw_pos[_n-1] if _n!=1
	replace trt_yr_sdw_pos = . if over_rtg==.

	by gvkey_num: gen trt_yr_sdw_neg = year if trt`threshold'_sdw_neg==1
	sort gvkey_num trt_yr_sdw_neg
	by gvkey_num: replace trt_yr_sdw_neg = trt_yr_sdw_neg[_n-1] if _n!=1
	replace trt_yr_sdw_neg = . if over_rtg==.

	*	Post-treatment years
	by gvkey_num: gen post`threshold'_sdw_pos=(year>trt_yr_sdw_pos)
	label var post`threshold'_sdw_pos ///
		"Indicator =1 if post-treatment year for `threshold' std dev of sdw"
	replace post`threshold'_sdw_pos=. if over_rtg==.

	by gvkey_num: gen post`threshold'_sdw_neg=(year>trt_yr_sdw_neg)
	label var post`threshold'_sdw_neg ///
		"Indicator =1 if post-treatment year for `threshold' std dev of sdw"
	replace post`threshold'_sdw_neg=. if over_rtg==.

	*	Treated firms
	by gvkey_num: egen trt`threshold'_sdw_pos_grp= max(post`threshold'_sdw_pos)
	label var trt`threshold'_sdw_pos_grp ///
		"Indicator = 1 if treatment group for `threshold' std dev of sdw"

	by gvkey_num: egen trt`threshold'_sdw_neg_grp= max(post`threshold'_sdw_neg)
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
         0 |         0         86 |        86 
         7 |        21          0 |        21 
-----------+----------------------+----------
     Total |        21         86 |       107
*/
sum over_rtg_yoy if trt_cat_sdw_pos==7 & trt_cat_sdw_neg==-7
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
over_rtg_yoy |         21           0           0          0          0
*/

*	No values of the trt_cat_sdw variables are greater than 3 or less than -3
replace trt_cat_sdw_pos = . if trt_cat_sdw_pos > 3
replace trt_cat_sdw_neg = . if trt_cat_sdw_neg < -3



///	REPLACE trt_sdw variables with missing for years without CSRHub data to
*	calculate change in overall rating
foreach variable of varlist *sdw* {
	display "`variable'"
	replace `variable'=. if year < 2009
}


		*************************************************************
		*															*
		*	Assess treatment variables distribution and zscores		*
		*															*
		*************************************************************
bysort gvkey_num: egen yoy_mean = mean(over_rtg_yoy)
replace yoy_mean=. if over_rtg_yoy==.

bysort gvkey_num: egen yoy_std_dev = sd(over_rtg_yoy)
replace yoy_std_dev=. if over_rtg_yoy==.

gen yoy_zscore = (over_rtg_yoy - yoy_mean) / yoy_std_dev

*	Histogram
histogram yoy_zscore, bin(100) percent normal ///
	xti("Z-score") xlab(-4(1)4) scheme(plotplain)

***	Remove firms with only two observations on year-on-year change
gen ch1 = (over_rtg_yoy!=.)
bysort gvkey_num: egen ch2=total(ch1)
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




						***===============================***
						*									*
						*  		  GENERATE VARIABLES		*
						*									*
						***===============================***	
///	RENAME CURRENCY ADJUSTED VARIABLES
rename (dltt at csho ceq) (dltt_unadjusted at_unadjusted csho_unadjusted ceq_unadjusted)
label var dltt_unadjusted "dltt in curcd currency"
label var at_unadjusted "at in curcd currency"
label var csho_unadjusted "csho in curcd currency"
label var ceq_unadjusted "ceq in curcd currency"
						
///	REVENUE GROWTH VARIABLES
*** Next year
xtset
gen Frevt_usd = f.revt_usd
label var Frevt_usd "Next year's revt_usd"

***	Current year minus previous year
gen revt_usd_yoy = revt_usd - l.revt_usd
label var revt_usd_yoy "Year-on-year change in revt_usd (revt_usd - previous year revt_usd)"

***	Next year minus current year
gen Frevt_usd_yoy = F.revt_usd-revt_usd
label var Frevt_usd_yoy "Next year revt_usd - current year revt_usd"

***	Percent change in sales, current to next year
gen revt_usd_pct = (revt_usd_yoy/L.revt_usd)*100
label var revt_usd_pct "Percent change in revenue, current to previous year"




///	GENERATE INVERSE HYPERBOLIC SINE TRANSFORMED REVENUE VARIABLE
capt n gen revt_usd_ihs = asinh(revt_usd)
label var revt_usd_ihs "Inverse hyperbolic sine transformation of revt"


///	Tobin's Q
gen tobinq = (at_usd + (csho_usd * prcc_f) - ceq_usd) / at_usd

/*
gen mkt2book = mkvalt / bkvlps

*	ROA
gen roa = ni / at

xtset
gen lroa = L.roa

*	Net income
xtset
gen lni = L.ni

*	Net income growth
gen ni_growth = ni - L.ni

*	Net income percent growth
gen nipct = ((ni - L.ni) / L.ni) * 100
	
*	Debt ratio
gen debt = dltt / at

*	R&D
gen rd = xrd / sale

*	Advertising
gen ad = xad / sale

*	Revenue growth
gen revg = revt - L.revt

*	Revenue percent growth
gen revpct = ((revt - L.revt) / L.revt) * 100
*/

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



					***=======================================***
					*											*
					*  SAVE FINAL MATCHED CSRHUB-CSTAT DATASET 	*
					*											*
					***=======================================***
***	Drop unneeded variables
drop xrdp

///	RENAME
rename (dltt_usd at_usd) (dltt at)

///	LABEL
label var emp "(CSTAT) Number of employees, in 1000s"

label var at "(CSTAT) Assets, in $millions"
					
///	SAVE					
compress
label data "Firm-year matched CSRHub-CSTAT data, 2008-2017"
capt n drop _merge
save data/matched-csrhub-cstat-2008-2017, replace
	
	
	

	
	
	
	
	
	
	
	
/*
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

***===========================================================***
*	EXPORT UNMATCHED CSRHUB FIRM NAMES FOR MANUAL MATCHING		*
***===========================================================***
///	LOAD UNMATCHED CSRHUB DATA
use data/unmatched-after-csrhub-cstat-global-and-northam-exact-merges.dta, clear

///	KEEP UNIQUE FIRM YEARS
codebook firm_csrhub
/*
unique values:  9,494                    missing "":  0/29,741
*/
bysort firm_csrhub: gen n=_n
tab n
/*
          n |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      9,494       31.92       31.92
          2 |      4,681       15.74       47.66
          3 |      3,772       12.68       60.34
          4 |      3,160       10.63       70.97
          5 |      2,570        8.64       79.61
          6 |      1,961        6.59       86.20
          7 |      1,518        5.10       91.31
          8 |      1,185        3.98       95.29
          9 |        835        2.81       98.10
         10 |        565        1.90      100.00
------------+-----------------------------------
      Total |     29,741      100.00
*/
keep if n==1

///	KEEP NEEDED VARIABLES
keep firm_csrhub cusip8 cusip9 isin
order firm_csrhub cusip8 cusip9 isin

///	EXPORT
export excel using ///
	"data\unique csrhub firm names not mached to cstat global or northam.xlsx", ///
	firstrow(variables) replace












	
	
	
	
	
	
	
	
	
	
	
**===========================================================***
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



*END
