********************************************************************************
*Title: Dissertation Chapter 2 Barnett and Salomon (2012) Replication and Extension
*Created by: Nicholas Poggioli (poggi005@umn.edu)
*Created on: October 2018
*Purpose: Analyze KLD and CSRHub data
********************************************************************************


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
save data/unique-ticker-years-in-cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta

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
save data/unique-ticker-years-in-kld-all.dta


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
save data/mergefile-kld-cstat-barnett-salomon-tickers.dta




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
save data/kld-cstat-bs2012.dta











			***===================================================***
			*					NARROW REPLICATION 1				*
			*		SAME DESIGN, SAME POPULATION, SAME SAMPLE		*
			***===================================================***
/*** Variables from Barnett and Salomon 2012
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
		- Industry = 
*/

***	LOAD DATA
use data/kld-cstat-bs2012.dta, clear

***	DATA DECISIONS
*	Barnett & Salomon assume missing advertising data = 0
keep if in_bs2012==1
replace ad=0 if ad==.

***	BS TABLE 1: CORRELATION TABLE
corr roa lroa ni lni net_kld_adj net_kld_adj_sq emp debt rd ad, means
pwcorr roa lroa ni lni net_kld_adj net_kld_adj_sq emp debt rd ad, st(.05) list

***	KEEP OBSERVATIONS WITH ALL NEEDED VARIABLES
gen comp=(net_kld_adj!=. & net_kld_adj!=. & lroa!=. & emp!=. & debt!=. & rd!=. & ad!=.)
keep if comp==1

***	BS TABLE 2: ROA REGRESSION
est clear

qui reg roa lroa emp debt rd ad
est sto t21

qui reg roa net_kld_adj lroa emp debt rd ad
est sto t22

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad
est sto t23

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year
est sto t24

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year i.naics_n
est sto t25

qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, fe
est sto t26

estout *, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	starlevels(* .1 ** .05 *** .01)

outreg2 [t21 t22 t23 t24 t25 t26] using "tables-and-figures/barnett-salomon-replicated-figures/bs2012-table-2-roa-regression", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	dec(2) fmt(f) ///
	replace
	
***	BS TABLE 3: NI REGRESSION
est clear

qui reg ni lni emp debt rd ad
est sto t31

qui reg ni net_kld_adj lni emp debt rd ad
est sto t32

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad
est sto t33

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year
est sto t34

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year i.naics_n
est sto t35

qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, fe
est sto t36

estout *, cells(b(star fmt(%9.3f)) t(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons) ///
	starlevels(* .1 ** .05 *** .01)

outreg2 [t31 t32 t33 t34 t35 t36] using "tables-and-figures/barnett-salomon-replicated-figures/bs2012-table-3-ni-regression", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	dec(2) fmt(f) ///
	replace

***	BS FIGURE 1
/*	B&S2012: "We use the models with the most explanatory power to graph these relationships.
	For ROA, we base Figure 1 on Model 5 from Table 3.	
	
	NOTE: 	B&S are wrong in the above quote. Table 3 reports regressions of NI, not ROA.
			I assume they mean Model 5 from Table 2, which reports regressions of ROA.
*/
reg roa i.net_kld_adj i.net_kld_adj_sq lroa emp debt rd ad i.year i.naics_n
margins net_kld_adj
/*	Margins not estimable. I'm guessing what they did is take the point estimates from
	the regression and plot them against a y-axis labeled as the DV		
	
	But margins works when I exclude net_kld_adj_sq from the model.
	
	Is that what they did, simply drop one of the independent variables?!*/
reg roa i.net_kld_adj lroa emp debt rd ad i.year i.naics_n
margins net_kld_adj	
marginsplot, xti("Adjusted Net KLD Score") yti("ROA Impact") ///
	xlab(0(1)26) ///
	scheme(s1mono) ///
	scale(.8) ///
	yline(0,lp(dot)) ///
	xline(11,lp(dot)) ///
	note("Vertical line at x = 11 indicates unadjusted net KLD score of 0")
	
	
***	BS FIGURE 2
/*	B&S2012: "For net income, we use Model 4 from Table 4.

	NOTE: 	B&S are wrong in the above quote. There is no Table 4 in the paper.
			I assume they mean Model 4 from Table 3, which reports regressions of NI.
*/
reg ni i.net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year
margins net_kld_adj, cont
/*	Margins not estimable. I'm guessing what they did is take the point estimates from
	the regression and plot them against a y-axis labeled as the DV	
	
	But margins works when I exclude net_kld_adj_sq from the model.
	
	Is that what they did, simply drop one of the independent variables?!
*/
reg ni i.net_kld_adj lni emp debt rd ad i.year
margins net_kld_adj
marginsplot, xti("Adjusted Net KLD Score") yti("Net Income Impact") ///
	xlab(0(1)26) ///
	scheme(s1mono) ///
	scale(.8) ///
	yline(0,lp(dot)) ///
	xline(11,lp(dot)) ///
	note("Vertical line at x = 11 indicates unadjusted net KLD score of 0")




	
			***===================================================***
			*					NARROW REPLICATION 2				*
			*		SAME DESIGN, SAME POPULATION, NEW SAMPLE		*
			***===================================================***
***	LOAD DATA
use data/kld-cstat-bs2012.dta, clear

***	DATA DECISIONS
*	Barnett & Salomon assume missing advertising data = 0
replace ad=0 if ad==.

*	Post 1998 to align with Barnett & Salomon's claim that KLD reporting changed in 1998
drop if year<1998

***	CORRELATION TABLE
corr roa lroa ni lni net_kld_adj net_kld_adj_sq emp debt rd ad, means
pwcorr roa lroa ni lni net_kld_adj net_kld_adj_sq emp debt rd ad, st(.05) list

***	ROA REGRESSION
est clear

qui reg roa lroa emp debt rd ad
est sto m1

qui reg roa net_kld_adj lroa emp debt rd ad
est sto m2

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad
est sto m3

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year
est sto m4

set matsize 800
qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year i.naics_n
est sto m5

qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, fe
est sto m6

estout *, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	title("Regressions of ROA using KLD data from 1998 - 2015.") ///
	starlevels(* .1 ** .05 *** .01)

outreg2 [m1 m2 m3 m4 m5 m6] using "tables-and-figures/barnett-salomon-replicated-figures/rep2-roa-regression", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	dec(3) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace	
	
***	NET INCOME REGRESSION
est clear

qui reg ni lni emp debt rd ad
est sto ni1

qui reg ni net_kld_adj lni emp debt rd ad
est sto ni2

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad
est sto ni3

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year
est sto ni4

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year i.naics_n
est sto ni5

qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, fe
est sto ni6

estout *, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons)  ///
	title("Regressions of NET INCOME using KLD data from 1998 - 2015.") ///
	starlevels(* .1 ** .05 *** .01)

outreg2 [ni1 ni2 ni3 ni4 ni5 ni6] using "tables-and-figures/barnett-salomon-replicated-figures/rep2-ni-regression", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	dec(3) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace	

	
	
	
	
	
	
			***===================================================***
			*					QUASI-REPLICATION 3				*
			*		SAME DESIGN, NEW POPULATION, NEW SAMPLE			*
			***===================================================***

***	LOAD DATA TO CREATE SAMPLE FROM NEW POPULATION
/*
use data/csrhub-all.dta, clear

*	Randomly sample 4,000 firms
drop if ticker==""
drop if ticker=="NA" & firm!="National Bank of Canada"
bysort ticker: gen n=_n
keep if n==1
drop n

set seed 61047
gen rngstate=c(rngstate)
label var rngstate "Stata rngstate from set seed 61047
sample 4000, count

gen in_rando=1
label var in_rando "=1 if a firm in the random sample of CSRHub firms"

compress
save data-csrhub/random-4000-csrhub-firms.dta
*/

***	MATCH THE SAMPLE WITH KLD
use data/random-4000-csrhub-firms.dta, clear

keep firm ticker tic_csrhub year in_csrhub
gen firm_csrhub=upper(firm)
rename year year_csrhub

drop if strpos(firm_csrhub,"FUND")>0

merge 1:m ticker using data/kld-cstat-bs2012.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        38,073
        from master                     1,943  (_merge==1)
        from using                     36,130  (_merge==2)

    matched                            13,539  (_merge==3)
    -----------------------------------------
*/
replace firm_kld=upper(firm_kld)


foreach v in "," "." {
	replace firm_kld=subinstr(firm_kld,"`v'","",.)
	replace firm_csrhub=subinstr(firm_csrhub,"`v'","",.)
}

ustrdist firm_kld firm_csrhub if _merge==3
stem strdist
/*Stem-and-leaf plot for strdist

  0* | 0000000000000000000000000000000000000000000000000000000000000 ... (8700)
  0* | 11111111111111111111111111111111111111111111111111111111111111 ... (135)
  0* | 2222222222222222222222222222222
  0* | 333333333333333333333333333333333333333333333333333333333333333 ... (94)
  0* | 44444444444444444444444444444444444444444444444444444444444444 ... (576)
  0* | 55555555555555555555555555555555555555555555555555555555555555 ... (141)
  0* | 66666666666666666666666666666666666666666666666666666666666666 ... (125)
  0* | 77777777777777777777777777777777777777777777777777777777777777 ... (379)
  0* | 88888888888888888888888888888888888888888888888888888888888888 ... (137)
  0* | 99999999999999999999999999999999999999999999999999999999999999 ... (344)
  1* | 00000000000000000000000000000000000000000000000000000000000000 ... (277)
  1* | 11111111111111111111111111111111111111111111111111111111111111 ... (171)
  1* | 22222222222222222222222222222222222222222222222222222222222222 ... (236)
  1* | 33333333333333333333333333333333333333333333333333333333333333 ... (244)
  1* | 44444444444444444444444444444444444444444444444444444444444444 ... (109)
  1* | 55555555555555555555555555555555555555555555555555555555555555 ... (243)
  1* | 66666666666666666666666666666666666666666666666666666666666666 ... (222)
  1* | 77777777777777777777777777777777777777777777777777777777777777 ... (206)
  1* | 88888888888888888888888888888888888888888888888888888888888888 ... (163)
  1* | 99999999999999999999999999999999999999999999999999999999999999 ... (147)
  2* | 00000000000000000000000000000000000000000000000000000000000000 ... (150)
  2* | 11111111111111111111111111111111111111111111111111111111111111 ... (142)
  2* | 22222222222222222222222222222222222222222222222222222222222222 ... (136)
  2* | 33333333333333333333333333333333333333333333333333333333333333 ... (105)
  2* | 44444444444444444444444444444444444444444444444444444444444444444444444
  2* | 555555555555555555555555555
  2* | 666666666666666666666666666666666666666666666666666666
  2* | 77777777777777777777777777777777777777777
  2* | 88888888888888888888888888
  2* | 99999999999999
  3* | 00000000000
  3* | 1111111111111111111111
  3* | 2222222222222222222
  3* | 33333333333333
  3* | 44
  3* | 55555555555
  3* | 66666
  3* | 7777
  3* | 8
  3* | 999
  4* | 
  4* | 
  4* | 
  4* | 
  4* | 
  4* | 
  4* | 
  4* | 
  4* | 
  4* | 
  5* | 0
*/

***	SAVE
compress
capt save data/replication3.dta

***	DATA DECISIONS
*	Barnett & Salomon assume missing advertising data = 0
replace ad=0 if ad==.

*	Post 1998 to align with Barnett & Salomon's claim that KLD reporting changed in 1998
drop if year<1998

*	Keep firms merged from CSRHub population
keep if _merge==3

xtset firm_n year, y

***	CORRELATION TABLE
corr roa lroa ni lni net_kld_adj net_kld_adj_sq emp debt rd ad, means
pwcorr roa lroa ni lni net_kld_adj net_kld_adj_sq emp debt rd ad, st(.05) list
/*
(obs=5,336)

    Variable |         Mean    Std. Dev.          Min          Max
-------------+----------------------------------------------------
         roa |     .0125124     .1845652    -2.435433     1.625642
        lroa |     .0095886      .214167    -6.783386     1.625642
          ni |     408.5504     2132.727       -16198        53394
         lni |     379.3568     1979.551       -16198        41733
 net_kld_adj |     11.49569     2.614856            1           29
net_kld_ad~q |     138.9871     70.17546            1          841
         emp |     21.87611     114.2367            0         2300
        debt |     .1830017     .2154874            0     2.444689
          rd |     9.624451      395.491            0      25684.4
          ad |     .0122439     .0499207            0     2.821317


             |      roa     lroa       ni      lni net_kl~j net_kl~q      emp     debt       rd       ad
-------------+------------------------------------------------------------------------------------------
         roa |   1.0000
        lroa |   0.6022   1.0000
          ni |   0.1405   0.0991   1.0000
         lni |   0.1195   0.1334   0.8933   1.0000
 net_kld_adj |   0.0675   0.0665   0.1019   0.1010   1.0000
net_kld_ad~q |   0.0780   0.0755   0.1382   0.1402   0.9751   1.0000
         emp |   0.0525   0.0492   0.4173   0.4301  -0.0571  -0.0050   1.0000
        debt |  -0.0516  -0.0373  -0.0193  -0.0155  -0.0648  -0.0507   0.0430   1.0000
          rd |  -0.0924  -0.0585  -0.0075  -0.0073   0.0021  -0.0003  -0.0045   0.0272   1.0000
          ad |  -0.0562  -0.0403  -0.0001  -0.0012   0.0529   0.0540  -0.0037   0.0026  -0.0037   1.0000

*/

*	Generate rep3 flag
gen in_rep3=(roa!=. & lroa!=. & ni!=. & lni!=. & net_kld_adj!=. & net_kld_adj_sq!=. & emp!=. & debt!=. & rd!=. & ad!=.)

***	ID MIN/MAX VALUES
replace firm=upper(firm)
keep if in_rep3==1
sort roa
list firm year roa ni at in 1/5
/*	MINIMUM 5 OBS ON ROA
     +------------------------------------------------------------------------------------+
     |                                     firm   year         roa          ni         at |
     |------------------------------------------------------------------------------------|
  1. |                           NEOPROBE CORP.   2012   -2.435433     -29.157     11.972 |
  2. |                           VERISIGN, INC.   2002   -2.074712   -4961.297   2391.318 |
  3. |                        OPKO HEALTH, INC.   2008    -1.83027     -39.834     21.764 |
  4. |                   CELL THERAPEUTICS, INC   2010   -1.542058     -82.642     53.592 |
  5. | INTEGRATED DEVICE TECHNOLOGY, INC. (IDT)   2008    -1.54071   -1045.167    678.367 |
     +------------------------------------------------------------------------------------+

*/
gsort -roa
list firm year roa ni at in 1/5
/*	MAX 5 OBS ON ROA
     +-------------------------------------------------------------------------------------+
     |                                firm   year        roa                  ni        at |
     |-------------------------------------------------------------------------------------|
  1. | LIGAND PHARMACEUTICALS INCORPORATED   2007   1.625642             281.688   173.278 |
  2. |         SYNTA PHARMACEUTICALS CORP.   2009   1.617011   79.08799999999999     48.91 |
  3. |      QUESTCOR PHARMACEUTICALS, INC.   2012   .7830853             197.675   252.431 |
  4. |                     ZIX CORPORATION   2010   .6164812              41.213    66.852 |
  5. |                 CAMBREX CORPORATION   2007   .5602926             209.248   373.462 |
     +-------------------------------------------------------------------------------------+

*/
sort ni
list firm year roa ni at in 1/5
/*	MINIMUM 5 OBS ON NI
     +---------------------------------------------------------------+
     |                     firm   year         roa       ni       at |
     |---------------------------------------------------------------|
  1. | LUCENT TECHNOLOGIES INC.   2001   -.4811668   -16198    33664 |
  2. |       FORD MOTOR COMPANY   2008   -.0672016   -14672   218328 |
  3. |       FORD MOTOR COMPANY   2006   -.0452803   -12613   278554 |
  4. | LUCENT TECHNOLOGIES INC.   2002   -.6606149   -11753    17791 |
  5. |     CORNING INCORPORATED   2001   -.4297663    -5498    12793 |
     +---------------------------------------------------------------+
*/
gsort -ni
list firm year roa ni at in 1/5
/*	MAX 5 OBS ON NI
     +--------------------------------------------------+
     |          firm   year        roa      ni       at |
     |--------------------------------------------------|
  1. |    APPLE INC.   2015   .1838136   53394   290479 |
  2. |    APPLE INC.   2012   .2370331   41733   176064 |
  3. |    APPLE INC.   2014     .17042   39510   231839 |
  4. |    APPLE INC.   2013   .1789227   37037   207000 |
  5. | CHEVRON CORP.   2011    .128393   26895   209474 |
     +--------------------------------------------------+
*/
compress
save data/mergefile-csrhub-kld-random-sample



***	REPLICATION 3
*	Load CSRHub sample data
use data/mergefile-csrhub-kld-random-sample, clear

*	ROA regression
est clear

qui reg roa lroa emp debt rd ad
est sto m1

qui reg roa net_kld_adj lroa emp debt rd ad
est sto m2

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad
est sto m3

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year
est sto m4

set matsize 800
qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year i.naics_n
est sto m5

qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, fe
est sto m6

estout *, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	title("Regressions of ROA using CSRHub population.") ///
	starlevels(* .1 ** .05 *** .01)
	
outreg2 [m1 m2 m3 m4 m5 m6] using "tables-and-figures/barnett-salomon-replicated-figures/rep3-roa-regression", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace
	

*	Net income regression
est clear

qui reg ni lni emp debt rd ad
est sto ni1

qui reg ni net_kld_adj lni emp debt rd ad
est sto ni2

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad
est sto ni3

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year
est sto ni4

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year i.naics_n
est sto ni5

qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, fe
est sto ni6

estout *, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons)  ///
	title("Regressions of NET INCOME using CSRHub population.") ///
	starlevels(* .1 ** .05 *** .01)

outreg2 [ni1 ni2 ni3 ni4 ni5 ni6] using "tables-and-figures/barnett-salomon-replicated-figures/rep3-ni-regression", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace

	
	
			
			***===================================================***
			*					QUASI-REPLICATION 4				*
			*		 NEW DESIGN, SAME POPULATION, SAME SAMPLE		*
			***===================================================***
***	LOAD DATA
use data/kld-cstat-bs2012.dta, clear

***	DATA DECISIONS
*	Barnett & Salomon assume missing advertising data = 0
keep if in_bs2012==1
replace ad=0 if ad==.

***	CORRELATION TABLE
corr roa lroa ni lni net_kld_adj net_kld_adj_sq emp debt rd ad, means
pwcorr roa lroa ni lni net_kld_adj net_kld_adj_sq emp debt rd ad, st(.05) list

***	4.1 CLUSTERED STANDARD ERRORS												//	4.1
*	ROA
est clear

qui reg roa lroa emp debt rd ad, cluster(firm_n)
est sto m1

qui reg roa net_kld_adj lroa emp debt rd ad, cluster(firm_n)
est sto m2

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad, cluster(firm_n)
est sto m3

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, cluster(firm_n)
est sto m4

set matsize 800
qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year i.naics_n, cluster(firm_n)
est sto m5

qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, fe cluster(firm_n)
est sto m6

estout *, cells(b(star fmt(2)) t(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	starlevels(* .1 ** .05 *** .01)

outreg2 [m1 m2 m3 m4 m5 m6] using "tables-and-figures/barnett-salomon-replicated-figures/rep4-roa-clustered-errors", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace

*	Net income
est clear

qui reg ni lni emp debt rd ad, cluster(firm_n)
est sto ni1

qui reg ni net_kld_adj lni emp debt rd ad, cluster(firm_n)
est sto ni2

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad, cluster(firm_n)
est sto ni3

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, cluster(firm_n)
est sto ni4

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year i.naics_n, cluster(firm_n)
est sto ni5

qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, fe cluster(firm_n)
est sto ni6

estout *, cells(b(star fmt(2)) t(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons)  ///
	starlevels(* .1 ** .05 *** .01)

outreg2 [ni1 ni2 ni3 ni4 ni5 ni6] using "tables-and-figures/barnett-salomon-replicated-figures/rep4-ni-clustered-errors", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace


***	4.2		HYBRID FIXED AND RANDOM EFFECTS MODELS 								//	4.2
*	Generate firm means
sort firm_n
foreach v of varlist net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad {
	by firm_n: egen m_`v'=mean(`v')
	gen dm_`v'=`v'-m_`v'
}		
			
*	ROA and NI hybrid regressions
qui xtreg roa dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_emp dm_debt dm_rd dm_ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad i.year, re
est sto hyb_roa

qui xtreg ni dm_net_kld_adj dm_net_kld_adj_sq dm_lni dm_emp dm_debt dm_rd dm_ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lni m_emp m_debt m_rd m_ad i.year, re
est sto hyb_ni

testparm dm_net_kld_adj m_net_kld_adj, equal									/// Test coefficient equality
test dm_net_kld_adj_sq = m_net_kld_adj_sq

estout hyb_roa hyb_ni, cells(b(star fmt(3)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(dm_* m_* _cons) ///
	order(dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_* _cons) ///
	starlevels(* .1 ** .05 *** .01)
	
outreg2 [hyb_roa hyb_ni] using "tables-and-figures/barnett-salomon-replicated-figures/rep4-hybrid-models", excel ///
	stats(coef tstat) ///
	keep(dm_* m_*) ///
	sortvar(dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_*) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace	
	
	
***	4.2		HYBRID FIXED AND RANDOM EFFECTS MODELS WITH CLUSTERED ERRORS		//	4.2 continued
*	ROA and NI hybrid regressions
qui xtreg roa dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_emp dm_debt dm_rd dm_ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad i.year, re cluster(firm_n)
est sto hybc_roa

qui xtreg ni dm_net_kld_adj dm_net_kld_adj_sq dm_lni dm_emp dm_debt dm_rd dm_ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lni m_emp m_debt m_rd m_ad i.year, re cluster(firm_n)
est sto hybc_ni

estout hybc_roa hybc_ni, cells(b(star fmt(2)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(dm_* m_* _cons) ///
	order(dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_* _cons) ///
	starlevels(* .1 ** .05 *** .01)
	
outreg2 [hybc_roa hybc_ni] using "tables-and-figures/barnett-salomon-replicated-figures/rep4-hybrid-models-clustered-errors", excel ///
	stats(coef tstat) ///
	keep(dm_* m_*) ///
	sortvar(dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_*) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace

/*	
***	4.3 CORRELATED RANDOM EFFECTS MODELS WITH AND WITHOUT CLUSTERED ERRORS		///	4.3
*	ROA and NI CRE regressions
qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad i.year, re
est sto cre_roa

qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lni m_emp m_debt m_rd m_ad i.year, re
est sto cre_ni

qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad i.year, re cluster(firm_n)
est sto crec_roa

qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lni m_emp m_debt m_rd m_ad i.year, re cluster(firm_n)
est sto crec_ni

estout cre_roa crec_roa cre_ni crec_ni, cells(b(star fmt(2)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad m_* _cons) ///
	order(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad m_* _cons) ///
	starlevels(* .1 ** .05 *** .01)
	
outreg2 [cre_roa crec_roa cre_ni crec_ni] using "tables-and-figures/barnett-salomon-replicated-figures/rep4-cre", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad m_*) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad m_*) ///
	dec(2) fmt(f) ///
	e(r2_a r2_o r2_b r2_w) ///
	replace	
*/
	
*	COMPARATIVE TABLES															///	4.4
*	ROA, no clustered errors
qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, re
est sto re_roa

qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, fe
est sto fe_roa

hausman fe_roa re_roa	//	Clear rejection of coefficient equivalence. RE model differs from FE model.

estout re_roa fe_roa hyb_roa cre_roa, cells(b(star fmt(2)) z(par)) ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad dm_* m_*) ///
	order(net_kld_adj net_kld_adj_sq lroa emp debt rd ad dm_* m_*) ///
	starlevels(* .1 ** .05 *** .01)
	
outreg2 [re_roa fe_roa hyb_roa cre_roa] using "tables-and-figures/barnett-salomon-replicated-figures/rep4-roa-comparative-tables", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad dm_* m_*) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa emp debt rd ad dm_* m_*) ///
	dec(2) fmt(f) ///
	e(r2_a r2_o r2_b r2_w) ///
	replace
	
*	Net Income, no clustered errors
qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, re
est sto re_ni

qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, fe
est sto fe_ni

estout re_ni fe_ni hyb_ni cre_ni, cells(b(star fmt(2)) z(par)) ///
	stats(N N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad dm_* m_*) ///
	order(net_kld_adj net_kld_adj_sq lni emp debt rd ad dm_* m_*) ///
	starlevels(* .1 ** .05 *** .01)
	
outreg2 [re_ni fe_ni hyb_ni cre_ni] using "tables-and-figures/barnett-salomon-replicated-figures/rep4-ni-comparative-tables", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad dm_* m_*) ///
	sortvar(net_kld_adj net_kld_adj_sq lni emp debt rd ad dm_* m_*) ///
	dec(2) fmt(f) ///
	e(r2_a r2_o r2_b r2_w) ///
	replace	

	
***	4.6	Controlling for industry and firm in the same model

*	Assume missing industry is the same as industry in next non-missing year
sort firm year
forvalues v = 1/10 {
	by firm: replace naics_n=naics_n[_n+1] if naics_n==.
}

forvalues v = 1/10 {
	by firm: replace naics_n=naics_n[_n-1] if naics_n==. & _n!=1
}

sort firm year
by firm: gen ind=naics_n!=naics_n[_n-1] & _n!=1
tab ind

/*        ind |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     16,164       99.99       99.99
          1 |          2        0.01      100.00
------------+-----------------------------------
      Total |     16,166      100.00
*/

by firm: egen ind2=max(ind)
tab ind2

list firm year naics ind ind2 if ind2==1
/*	TWO FIRMS CHANGE NAICS IN THE DATA
       +---------------------------------------------------+
       |                 firm   year    naics   ind   ind2 |
       |---------------------------------------------------|
 7885. | ITT INDUSTRIES, INC.   1998   334510     0      1 |
 7886. | ITT INDUSTRIES, INC.   1999   334510     0      1 |
 7887. | ITT INDUSTRIES, INC.   2000   333911     1      1 |
 7888. | ITT INDUSTRIES, INC.   2001   333911     0      1 |
 7889. | ITT INDUSTRIES, INC.   2002   333911     0      1 |
       |---------------------------------------------------|
 7890. | ITT INDUSTRIES, INC.   2003   333911     0      1 |
 7891. | ITT INDUSTRIES, INC.   2004   333911     0      1 |
 7892. | ITT INDUSTRIES, INC.   2005   333911     0      1 |
 9012. |     MANOR CARE, INC.   1998   531120     0      1 |
 9013. |     MANOR CARE, INC.   2000   623110     1      1 |
       |---------------------------------------------------|
 9014. |     MANOR CARE, INC.   2001   623110     0      1 |
 9015. |     MANOR CARE, INC.   2002   623110     0      1 |
 9016. |     MANOR CARE, INC.   2003   623110     0      1 |
 9017. |     MANOR CARE, INC.   2004   623110     0      1 |
 9018. |     MANOR CARE, INC.   2005   623110     0      1 |
       |---------------------------------------------------|
 9019. |     MANOR CARE, INC.   2006   623110     0      1 |
       +---------------------------------------------------+
*/


*	Generate firm means
sort firm_n
foreach v of varlist net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad naics_n {
	by firm_n: egen m_`v'=mean(`v')
	gen dm_`v'=`v'-m_`v'
}

*	Check industry variable to see if demeaning worked
tab dm_naics_n
/* APPEARS TO WORK
 dm_naics_n |      Freq.     Percent        Cum.
------------+-----------------------------------
    -91.875 |          1        0.01        0.01
      -7.25 |          6        0.06        0.07
          0 |     10,064       99.84       99.91
     13.125 |          7        0.07       99.98
      21.75 |          2        0.02      100.00
------------+-----------------------------------
      Total |     10,080      100.00

ONLY TWO FIRMS CHANGE INDUSTRY IN THE PANEL, GIVEN ASSUMPTION THAT MISSING NAICS
IS EQUAL TO THE NEXT YEAR IN WHICH NAICS IS NOT MISSING
*/

drop ind ind2
			
*	ROA and NI hybrid regressions
est clear

qui xtreg roa dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_emp dm_debt dm_rd dm_ad dm_naics_n ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad m_naics_n i.year, re
est sto hyb_roa_ind

qui xtreg ni dm_net_kld_adj dm_net_kld_adj_sq dm_lni dm_emp dm_debt dm_rd dm_ad dm_naics_n ///
	m_net_kld_adj m_net_kld_adj_sq m_lni m_emp m_debt m_rd m_ad m_naics_n i.year, re
est sto hyb_ni_ind

*	ROA and NI hybrid regressions with clustered errors at firm level
qui xtreg roa dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_emp dm_debt dm_rd dm_ad dm_naics_n ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad m_naics_n i.year, re cluster(firm_n)
est sto hybc_roa_ind

qui xtreg ni dm_net_kld_adj dm_net_kld_adj_sq dm_lni dm_emp dm_debt dm_rd dm_ad dm_naics_n ///
	m_net_kld_adj m_net_kld_adj_sq m_lni m_emp m_debt m_rd m_ad m_naics_n i.year, re cluster(firm_n)
est sto hybc_ni_ind

estout hyb_roa hybc_roa hyb_roa_ind hybc_roa_ind hyb_ni hybc_ni hyb_ni_ind hybc_ni_ind, cells(b(star fmt(3)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(dm_* m_* _cons) ///
	order(dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_net_kld_adj m_net_kld_adj_sq m_lroa m_lni m_* _cons) ///
	starlevels(+ .1 * .05 ** .01 *** .001)

estout hyb_roa hybc_roa hyb_roa_ind hybc_roa_ind hyb_ni hybc_ni hyb_ni_ind hybc_ni_ind, cells(b(star fmt(3)) p(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(dm_* m_* _cons) ///
	order(dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_net_kld_adj m_net_kld_adj_sq m_lroa m_lni m_* _cons)  ///
	starlevels(+ .1 * .05 ** .01 *** .001)
	
	
outreg2 [hyb_roa hybc_roa hyb_roa_ind hybc_roa_ind hyb_ni hybc_ni hyb_ni_ind hybc_ni_ind] using "tables-and-figures/rep4-all-models-comparison-zstats", excel ///
	stats(coef tstat) ///
	keep(dm_* m_*) ///
	sortvar(dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_net_kld_adj m_net_kld_adj_sq m_lroa m_lni m_* _cons) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace
	
	
outreg2 [hyb_roa hybc_roa hyb_roa_ind hybc_roa_ind hyb_ni hybc_ni hyb_ni_ind hybc_ni_ind] using "tables-and-figures/rep4-all-models-comparison-pvalues", excel ///
	stats(coef pval) ///
	keep(dm_* m_*) ///
	sortvar(dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_net_kld_adj m_net_kld_adj_sq m_lroa m_lni m_* _cons) ///
	dec(3) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	alpha(0.001,0.01,0.05,0.1) symbol(***,**,*,+) ///
	
	replace
*/			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			***===================================================***
			*					QUASI-REPLICATION 5				*
			*		 NEW DESIGN, SAME POPULATION, NEW SAMPLE		*
			***===================================================***
/*	New sample: 1998 - 2015
	New designs:
		1)	Clustered standard errors
		2)	Hybrid models
		3)	Correlated random effects models
		4)	Combinations of 1, 2, and 3
*/
***	CREATE NEW SAMPLE
*	Load data
use data-csrhub/kld-cstat-bs2012.dta, clear

*	Barnett & Salomon assume missing advertising data = 0
replace ad=0 if ad==.

*	Post 1998 to align with Barnett & Salomon's claim that KLD reporting changed in 1998
drop if year<1998

***	CORRELATION TABLE
corr roa lroa ni lni net_kld_adj net_kld_adj_sq emp debt rd ad, means
pwcorr roa lroa ni lni net_kld_adj net_kld_adj_sq emp debt rd ad, st(.05) list
			
***	5.1	CLUSTERED STANDARD ERRORS												///	5.1			
*	ROA
qui reg roa lroa emp debt rd ad, cluster(firm_n)
est sto m1

qui reg roa net_kld_adj lroa emp debt rd ad, cluster(firm_n)
est sto m2

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad, cluster(firm_n)
est sto m3

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, cluster(firm_n)
est sto m4

set matsize 800
qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year i.naics_n, cluster(firm_n)
est sto m5

qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, fe cluster(firm_n)
est sto m6

estout m*, cells(b(star fmt(2)) t(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	starlevels(* .1 ** .05 *** .01)

/* outreg2 [m1 m2 m3 m4 m5 m6] using "tables-and-figures/barnett-salomon-replicated-figures/rep51-roa-regression-clustered-errors", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace */

*	Net income
qui reg ni lni emp debt rd ad, cluster(firm_n)
est sto ni1

qui reg ni net_kld_adj lni emp debt rd ad, cluster(firm_n)
est sto ni2

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad, cluster(firm_n)
est sto ni3

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, cluster(firm_n)
est sto ni4

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year i.naics_n, cluster(firm_n)
est sto ni5

qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, fe cluster(firm_n)
est sto ni6

estout ni*, cells(b(star fmt(2)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons)  ///
	starlevels(* .1 ** .05 *** .01)

/* outreg2 [ni1 ni2 ni3 ni4 ni5 ni6] using "tables-and-figures/barnett-salomon-replicated-figures/rep51-ni-regression-clustered-errors", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace */

	
	
***	5.2	HYBRID AND CRE MODELS													//	5.2
*	Generate firm means
sort firm_n
foreach v of varlist net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad {
	by firm_n: egen m_`v'=mean(`v')
	gen dm_`v'=`v'-m_`v'
}		
*	ROA and NI hybrid regressions
qui xtreg roa dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_emp dm_debt dm_rd dm_ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad i.year, re
est sto hybrid_roa

qui xtreg ni dm_net_kld_adj dm_net_kld_adj_sq dm_lni dm_emp dm_debt dm_rd dm_ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lni m_emp m_debt m_rd m_ad i.year, re
est sto hybrid_ni

estout m6 hybrid_roa ni6 hybrid_ni, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_* m_* _cons) ///
	order(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_* _cons) ///
	starlevels(* .1 ** .05 *** .01)
	
outreg2 [m6 hybrid_roa ni6 hybrid_ni] using "tables-and-figures/barnett-salomon-replicated-figures/rep52-roa-ni-hybrid-regressions", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_* m_*) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_* m_*) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace 
*/	
	
	

*	ROA and NI CRE regressions
qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad i.year, re
est sto cre_roa

qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lni m_emp m_debt m_rd m_ad i.year, re
est sto cre_ni

estout m6 cre_roa ni6 cre_ni, cells(b(star fmt(2)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad  m_*) ///
	order(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm* m_* _cons) ///
	starlevels(* .1 ** .05 *** .01)
	
outreg2 [m6 cre_roa ni6 cre_ni] using "tables-and-figures/barnett-salomon-replicated-figures/rep52-roa-ni-cre-regressions", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad  m_*) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad  m_*) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace 	

		
***	5.4 CLUSTERED STANDARD ERRORS AND HYBRID AND CRE MODELS						//	5.3
*	ROA and NI Clustered Hybrid regressions
qui xtreg roa dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_emp dm_debt dm_rd dm_ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad i.year, re cluster(firm_n)
est sto hybrid_roa_clus

qui xtreg ni dm_net_kld_adj dm_net_kld_adj_sq dm_lni dm_emp dm_debt dm_rd dm_ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lni m_emp m_debt m_rd m_ad i.year, re cluster(firm_n)
est sto hybrid_ni_clus

*	ROA and NI Clustered CRE regressions
qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad i.year, re cluster(firm_n)
est sto cre_roa_clus

qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lni m_emp m_debt m_rd m_ad i.year, re cluster(firm_n)
est sto cre_ni_clus


estout hybrid_roa hybrid_roa_clus cre_roa cre_roa_clus hybrid_ni hybrid_ni_clus cre_ni cre_ni_clus, cells(b(star fmt(2)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_* m_*) ///
	order(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_* m_*) ///
	starlevels(* .1 ** .05 *** .01)
/*	
outreg2 [m6 hybrid_roa hybrid_roa_clus ni6 hybrid_ni hybrid_ni_clus] ///
	using "tables-and-figures/barnett-salomon-replicated-figures/rep53-hybrid-clustered-errors", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_* m_*) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_* m_*) ///
	dec(2) fmt(f) ///
	e(r2_a r2_o r2_b r2_w) ///
	replace
	
outreg2 [m6 cre_roa cre_roa_clus ni6 cre_ni cre_ni_clus] ///
	using "tables-and-figures/barnett-salomon-replicated-figures/rep53-cre-clustered-errors", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_* m_*) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_* m_*) ///
	dec(2) fmt(f) ///
	e(r2_a r2_o r2_b r2_w) ///
	replace	
*/
	
*	Omnibus table with all hybrid, CRE, and clustered results
outreg2 [m6 hybrid_roa hybrid_roa_clus cre_roa cre_roa_clus ni6 hybrid_ni hybrid_ni_clus cre_ni cre_ni_clus] ///
	using "tables-and-figures/barnett-salomon-replicated-figures/rep53-omnibus-table", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_* m_*) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_* m_*) ///
	dec(2) fmt(f) ///
	e(r2_a r2_o r2_b r2_w) ///
	replace	
*/

	
	
	
			***===================================================***
			*					QUASI-REPLICATION 6					*
			*		  NEW DESIGN, NEW POPULATION, NEW SAMPLE		*
			***===================================================***
/*	Using the sample from replication 3 and research design from rep 5 */

***	LOAD DATA
use data/replication3.dta, clear

***	DATA DECISIONS
*	Barnett & Salomon assume missing advertising data = 0
replace ad=0 if ad==.

*	Post 1998 to align with Barnett & Salomon's claim that KLD reporting changed in 1998
drop if year<1998

*	Keep firms merged from CSRHub population
keep if _merge==3

xtset firm_n year, y
	
***	CLUSTERED STANDARD ERRORS													//	6.1
*	ROA
qui reg roa lroa emp debt rd ad, cluster(firm_n)
est sto roa1

qui reg roa net_kld_adj lroa emp debt rd ad, cluster(firm_n)
est sto roa2

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad, cluster(firm_n)
est sto roa3

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, cluster(firm_n)
est sto roa4

set matsize 800
qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year i.naics_n, cluster(firm_n)
est sto roa5

qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, fe cluster(firm_n)
est sto roa6

estout roa*, cells(b(star fmt(2)) t(par)) ///	
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within")) ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	title("Clustered standard errors with random sample from CSRHub population") ///
	starlevels(* .1 ** .05 *** .01)

outreg2 [roa1 roa2 roa3 roa4 roa5 roa6] using "tables-and-figures/rep6-roa-clust-err", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace

	
*	Net income
qui reg ni lni emp debt rd ad, cluster(firm_n)
est sto ni1

qui reg ni net_kld_adj lni emp debt rd ad, cluster(firm_n)
est sto ni2

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad, cluster(firm_n)
est sto ni3

reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, cluster(firm_n)
est sto ni4

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year i.naics_n, cluster(firm_n)
est sto ni5

qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, fe cluster(firm_n)
est sto ni6

estout ni*, cells(b(star fmt(2)) t(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within")) ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons)  ///
	title("Clustered standard errors with random sample from CSRHub population") ///	
	starlevels(* .1 ** .05 *** .01)

outreg2 [ni1 ni2 ni3 ni4 ni5 ni6] using "tables-and-figures/rep6-ni-clust-err", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace
	

***	HYBRID MODELS WITH CLUSTERED ERRORS
sort firm_n
foreach v of varlist net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad {
	by firm_n: egen m_`v'=mean(`v')
	gen dm_`v'=`v'-m_`v'
}

*	Regressions
qui xtreg roa dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_emp dm_debt dm_rd dm_ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad i.year, re cluster(firm_n)
est sto hybc_roa

qui xtreg ni dm_net_kld_adj dm_net_kld_adj_sq dm_lni dm_emp dm_debt dm_rd dm_ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lni m_emp m_debt m_rd m_ad i.year, re cluster(firm_n)
est sto hybc_ni

estout hybc_roa hybc_ni, cells(b(star fmt(2)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(dm_* m_* _cons) ///
	order(dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_* _cons) ///
	starlevels(* .1 ** .05 *** .01)
	
outreg2 [hybc_roa hybc_ni] using "tables-and-figures/rep6-hybrid-models-clustered-errors", excel ///
	stats(coef tstat) ///
	keep(dm_* m_*) ///
	sortvar(dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_*) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
***	CSRHUB MEASURES																//	6.2
/*	I need to
		-	Create a dataset with CSRHub and CSTAT variables
		-	Create the variables used above
*/
***	CREATE UNIQUE FIRM-TICKER IN CSRHUB DATA
use data-csrhub/csrhub-all.dta, clear

drop if ticker==""
drop if ticker=="NA" & firm!="National Bank of Canada"
gen firm_csrhub=firm


***	MERGE CSRHUB WITH KLD CSTAT
*	Merge ticker-year-month with ticker-year: many-to-one merge
merge m:1 ticker year using data-csrhub/kld-cstat-bs2012.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       628,457
        from master                   597,785  (_merge==1)
        from using                     30,672  (_merge==2)

    matched                           229,726  (_merge==3)
    -----------------------------------------
All obs with _merge==2 are KLD data.
*/
drop _merge
drop if in_csrhub!=1															//	Drop
merge 1:1 firm date using data-csrhub/random-4000-csrhub-firms.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       823,511
        from master                   823,511  (_merge==1)
        from using                          0  (_merge==2)

    matched                             4,000  (_merge==3)
    -----------------------------------------
*/
sort firm in_rando
by firm: replace in_rando=in_rando[_n-1] if in_rando==.

replace in_rando=0 if in_rando==.	
compress
	
*	Replace 0s
replace in_csrhub=0 if in_csrhub==.
replace in_kld=0 if in_kld==.
replace in_cstat=0 if in_cstat==.



***	CLEAN DATA
/*	The plan here is to create a list of matches, standardize names, calculate string
	distances, and manually check high string distance matches.
	
	Once I eval which matches are real and which are not, create an indicator variable,
	merge back into full dataset, and drop observations that are mismatches
*/
drop firm_n
gen f = (firm!="" & firm_csrhub!="" & firm_kld!="" & firm_cstat!="")
foreach v of varlist firm firm_* {
	format `v' %20s
}

foreach v of varlist firm firm_csrhub firm_kld firm_cstat {
	stnd_compname `v', gen(stn_`v')
}

bysort firm firm_csrhub firm_kld firm_cstat: gen n=_n
keep if n==1

ustrdist stn_firm_csrhub stn_firm_kld






























*	Load random 4,000 CSRHub firms and merge with CSTAT
use data-csrhub/random-4000-csrhub-firms.dta, clear

merge 1:m firm date using data-csrhub/csrhub-all.dta

sort firm in_rando
by firm: replace in_rando=in_rando[_n-1] if in_rando==.
keep if in_rando==1

/*
*	Merge with CSTAT Annual
drop _merge
merge m:1 ticker year using data-csrhub/unique-ticker-years-in-cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta
*/

*	Merge with CSTAT Quarterly
preserve
use D:\Dropbox\data\cstat\quarterly-all-data\data-cstat-quarterly-all-data-since-1995-CLEAN.dta, clear
bysort tic cal_yr cal_mnth: gen N=_N
keep if N==1
drop N

tempfile d
save `d'
restore

drop _merge
gen tic = ticker
gen cal_yr = year
gen cal_mnth=month
merge m:1 tic cal_yr cal_mnth using `d'

sort tic in_rando



*	Create squared measures
foreach v in varlist over_rtg 

*	ROA
qui reg roa lroa emp debt rd ad, cluster(firm_n)
est sto roa1

qui reg roa net_kld_adj lroa emp debt rd ad, cluster(firm_n)
est sto roa2

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad, cluster(firm_n)
est sto roa3

qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, cluster(firm_n)
est sto roa4

set matsize 800
qui reg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year i.naics_n, cluster(firm_n)
est sto roa5

qui xtreg roa net_kld_adj net_kld_adj_sq lroa emp debt rd ad i.year, fe cluster(firm_n)
est sto roa6

estout roa*, cells(b(star fmt(2)) t(par)) ///	
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within")) ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lroa emp debt rd ad _cons) ///
	title("Clustered standard errors with random sample from CSRHub population") ///
	starlevels(* .1 ** .05 *** .01)

/* outreg2 [m1 m2 m3 m4 m5 m6] using "tables-and-figures/barnett-salomon-replicated-figures/rep6-roa-clustered-errors", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lroa emp debt rd ad) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace */

	
*	Net income
qui reg ni lni emp debt rd ad, cluster(firm_n)
est sto ni1

qui reg ni net_kld_adj lni emp debt rd ad, cluster(firm_n)
est sto ni2

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad, cluster(firm_n)
est sto ni3

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, cluster(firm_n)
est sto ni4

qui reg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year i.naics_n, cluster(firm_n)
est sto ni5

qui xtreg ni net_kld_adj net_kld_adj_sq lni emp debt rd ad i.year, fe cluster(firm_n)
est sto ni6

estout ni*, cells(b(star fmt(2)) t(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within")) ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons) ///
	order(net_kld_adj net_kld_adj_sq lni emp debt rd ad _cons)  ///
	title("Clustered standard errors with random sample from CSRHub population") ///	
	starlevels(* .1 ** .05 *** .01)

/* outreg2 [ni1 ni2 ni3 ni4 ni5 ni6] using "tables-and-figures/barnett-salomon-replicated-figures/rep6-ni-clustered-errors", excel ///
	stats(coef tstat) ///
	keep(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	sortvar(net_kld_adj net_kld_adj_sq lni emp debt rd ad) ///
	dec(2) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace */



***	CLUSTERED ERRORS AND CSRHUB MEASURES										//	6.3	
	
	
	
	
	
	
***	HYBRID AND CRE MODELS														//	6.4
*	Generate firm means
sort firm_n
foreach v of varlist net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad {
	by firm_n: egen m_`v'=mean(`v')
	gen dm_`v'=`v'-m_`v'
}		
*	ROA and NI hybrid regressions
qui xtreg roa dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_emp dm_debt dm_rd dm_ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad i.year, re
est sto hybrid_roa

qui xtreg ni dm_net_kld_adj dm_net_kld_adj_sq dm_lni dm_emp dm_debt dm_rd dm_ad ///
	m_net_kld_adj m_net_kld_adj_sq m_lroa m_emp m_debt m_rd m_ad i.year, re
est sto hybrid_ni

estout hybrid_roa hybrid_ni, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a r2_o r2_b r2_w, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2" "R^2 Overall" "R^2 Between" "R^2 Within"))      ///
	legend collabels(none) ///
	keep(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_* m_* _cons) ///
	order(net_kld_adj net_kld_adj_sq lroa lni emp debt rd ad dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_* _cons) ///
	starlevels(* .1 ** .05 *** .01)

/* outreg2 [hybrid_roa1 hybrid_ni] using "tables-and-figures/barnett-salomon-replicated-figures/rep5-hybrid-models", excel ///
	stats(coef tstat) ///
	keep(dm_* m_*) ///
	sortvar(dm_net_kld_adj dm_net_kld_adj_sq dm_lroa dm_lni dm_* m_*) ///
	dec(3) fmt(f) ///
	e(N_g r2_a r2_o r2_b r2_w) ///
	replace */
					
				
				
					***=======================***
					*	  SUMMARY STATISTICS	*
					*	  		 KLD			*
					***=======================***

					
					
					capt n ssc install asdoc

*	Summary
asdoc sum sum*str sum*con, save(figures/summary-stats-kld-by-sic2)

*	Correlations
corr sum*str, means
corr sum*con, means

doc corr sum*str sum*con, means	
