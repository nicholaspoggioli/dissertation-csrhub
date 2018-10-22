********************************************************************************
*Title: Dissertation data creation and cleaning
*Created by: Nicholas Poggioli (poggi005@umn.edu)
*Created on: October 2018
*Purpose: Create and clean data for dissertation

/*	OUTLINE
	-	Recreate Barnett & Salomon 2012 data
	-	Merge with CSRHub
*/

********************************************************************************

						***=================================***
						*	Recreate Barnett & Salomon 2012   *
						***=================================***
							***===========================***
							*								*
							*			VARIABLES			*
							*	Barnett and Salomon 2012	*
							*								*
							***===========================***
/***
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

	***=======================================================================***
	*	MERGE CSTAT AND KLD USING ONLY UNIQUE TICKER-YEARS FROM EACH DATASET	*
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
capt n save data/unique-ticker-years-in-cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, replace

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
capt n save data/unique-ticker-years-in-kld-all.dta, replace


***	MERGE KLD WITH CSTAT
use data/unique-ticker-years-in-cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear


tempfile d2
save `d2'

use data/unique-ticker-years-in-kld-all.dta, clear

merge 1:1 ticker year using `d2'
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

***	SAVE
compress
capt n save data/mergefile-kld-cstat-barnett-salomon-tickers.dta, replace


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

Compare the above to B&S2012 description of their net_kld variable:
Obs: 	not reported  	-->		Here = 16,166
Mean:	-0.43			-->		Here = -0.38
Min:	-12				-->		Here = -11
Max:	 15				-->		Here = 14
*/

gen net_kld_adj = net_kld + 11 if in_bs2012==1
replace net_kld_adj = net_kld +12 if in_bs2012!=1
/*	Barnett & Salomon add an integer to net_kld to bring minimum to 0,
	but their minimum value is -12, not -11 as I have	*/

gen net_kld_adj_sq = net_kld_adj^2 

label var net_kld_adj "(KLD) net_kld + 11 to make minimum = 0, replicating Barnett & Salomon 2012"
label var net_kld_adj_sq "(KLD) net_kld_adj squared, replicating measure in Barnett & Salomon 2012"


***	SAVE
compress
save data/kld-cstat-bs2012.dta, replace
				
				
							***===========================***
							*	MERGE KLD/CSTAT WITH CSRHUB *
							***===========================***
							
*use data/kld-cstat-bs2012.dta, clear
/*	firm:		firm name
	year:		year
	ticker:		ticker
*/

use data/csrhub-all.dta, clear
/*	firm:		firm name
	year:		year
	ticker:	ticker
*/

bysort ticker year: gen n=_n
keep if n==1

keep firm year ticker tic_csrhub in_csrhub

tempfile csrh
save `csrh'

merge 1:1 ticker year using data/kld-cstat-bs2012.dta, gen(csrhub2kldcstat)							/// Match KLD/CSTAT to CSRHub on ticker year
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        85,835
        from master                    55,163  (_merge==1)
        from using                     30,672  (_merge==2)

    matched                            18,997  (_merge==3)
    -----------------------------------------
*/

*	Merge matches back to full CSRHub data on firm year
keep if csrhub2kldcstat==3
merge 1:m firm year using data/csrhub-all.dta, gen(csrhubkldcstat2csrhub)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       760,397
        from master                         0  (_merge==1)
        from using                    760,397  (_merge==2)

    matched                           205,480  (_merge==3)
    -----------------------------------------
*/

order ym, after(year)
sort firm ym

* Gen firm name variable for deduplication in OpenRefine
gen firm_dedup=upper(firm)
label var firm_dedup "Copy of 'firm' used for OpenRefine deduplication on firm name"

***	Save
compress
capt n save data/csrhub-kld-cstat-bs2012.dta, replace
