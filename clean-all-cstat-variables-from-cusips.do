***	CLEANING ALL COMPUSTAT FUNDAMENTALS ANNUAL VARIABLES FOR ALL CUSIPS

***===============================================***
*		CSTAT data using CSRHub CUSIPs				*
***===============================================***
***	File size reduction
use data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, clear

*	clean
order conm cusip tic datadate fyear fyr

*	gen
gen ym=ym(year(datadate),month(datadate))

*	save
compress
save data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, replace

***		Drop years not in CSRHub
use data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, replace

*	keep only ym in csrhub (587 - 692)
drop if ym<587 | ym>692

*	save
compress
save data/cstat-all-variables-for-all-cusip9-in-csrhub-data-csrhub-ym-only.dta, replace


***=======================================***
*		CSTAT data using KLD CUSIPs			*
***=======================================***
***	File size reduction
use data/cstat-all-variables-for-all-cusip9-in-kld-data-1990-2018.dta, clear

order conm cusip tic datadate fyear fyr

gen ym=ym(year(datadate),month(datadate))

bysort cusip ym: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     94,504       99.87       99.87
          4 |          4        0.00       99.88
          8 |          8        0.01       99.89
         13 |         13        0.01       99.90
         15 |         30        0.03       99.93
         16 |         64        0.07      100.00
------------+-----------------------------------
      Total |     94,623      100.00
*/
drop if N>1
drop N

compress
save data/cstat-all-variables-for-all-cusip9-in-kld-data-1990-2018.dta, replace


***===============================================***
*	MERGE CSTAT data from CSRHUB and KLD CUSIPs		*
***===============================================***
use data/cstat-all-variables-for-all-cusip9-in-kld-data-1990-2018.dta, clear

bysort cusip ym: gen N=_N
tab N
keep if N==1
drop N

merge 1:1 cusip ym using data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, gen(cstatvars) update assert(1 2 3 4 5)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        39,837
        from master                    20,147  (_merge==1)
        from using                     19,690  (_merge==2)

    matched                            74,357
        not updated                    74,357  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/

save data/cstat-all-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, replace

***	Subset to needed variables
use data/cstat-all-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, clear
/*	CSTAT variables
		
		MEASURE					VARNAME			EQUATION TO CREATE FROM CSTAT VARIABLES
		--------------------	--------		---------------------------------------
		Revenue					revt		=	REVT
		Net income				ni			=	NI
		Sales					sale		=	SALE
		Total assets			at			=	AT								
		Advertising expense		xad			=	XAD								
		R&D expense				xrd			=	XRD								
		Firm size				emp			=	EMP								*Barnett & Salomon 2012
		
********VARIABLE EQUATIONS FROM C:\Dropbox\papers\active\dissertation-csrhub\project\data\data-documentation\2017_10_12_wrds_data_items.pdf
		Debt					debt		=	DLTT / AT		
		Return on assets 		roa 		=	NI / AT
		Tobin's Q 				tobinq		=	(AT + (CSHO * PRCC_F) - CEQ) / AT
		Market to book ratio	mkt2book	=	MKVALT / BKVLPS
		R&D intensity			rd			=	XRD / SALE
		Advertising intensity	ad			=	XAD / SALE
		Firm size				size		=	log(AT)
*/

keep cusip ym conm tic datadate fyear fyr gvkey curcd apdedate fdate pdate ///
	revt ni sale at xad xrd emp dltt csho prcc_f ceq at mkvalt bkvlps ///
	gp unnp unnpl drc drlt dvrre lcoxdr loxdr nfsr revt ris urevub
	
*	Generate variables
gen tobinq = (at + (csho * prcc_f) - ceq) / at
gen mkt2book = mkvalt / bkvlps

*	ROA
gen roa = ni / at

sort cusip ym
by cusip: gen lroa=roa[_n-1]

*	Net income
sort cusip ym
by cusip: gen lni=ni[_n-1]
	
*	Debt ratio
gen debt = dltt / at

*	R&D
gen rd = xrd / sale

*	Advertising
gen ad = xad / sale

foreach var of varlist * {
	local lab `: var label `var''
	label var `var' "(CSTAT) `lab'"
}

*	Firm size
gen size = log(at)

*	Employees
replace emp=emp*1000

*	Set panel
encode cusip, gen(cusip_n)
xtset cusip_n ym, m

*	Revenue growth
gen revt_growth=revt-l12.revt

*	Save
label var roa "(CSTAT) Return on assets = ni / at"
label var tobinq "(CSTAT) Tobin's q = (at + (csho * prcc_f) - ceq) / at"
label var mkt2book "(CSTAT) Market to book ratio = mkvalt / bkvlps"
label var ym "(CSTAT) Fiscal year and end-of-fiscal-year month"
label var lroa "(CSTAT) Lagged roa, 1 year"
label var lni "(CSTAT) Lagged ni, 1 year"
label var debt "(CSTAT) Debt ratio = dltt / at"
label var rd "(CSTAT) R&D intensity = xrd / sale"
label var ad "(CSTAT) Advertising intensity = xad / sale"
label var emp "(CSTAT) Number of employees"
label var size "(CSTAT) Firm size = logarithm of AT"
label var revt_growth

compress
save data/cstat-subset-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, replace


***===================================================================***
*	MERGE CSTAT data from CSRHUB and KLD	with  		CSRHub data		*
***===================================================================***
***	
use data/csrhub-all.dta, clear
bysort cusip ym: gen N=_N
drop if N>1
drop N firm_n
compress
save data/csrhub-all-unique-cusip-ym.dta, replace

use data/cstat-subset-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, clear
drop cusip_n

merge 1:1 cusip ym using data/csrhub-all-unique-cusip-ym.dta, update assert(1 2 3 4 5)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       923,911
        from master                    91,645  (_merge==1)
        from using                    832,266  (_merge==2)

    matched                            22,549
        not updated                    22,549  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/

*	Move cusip to cusip9; generate cusip8 to match with KLD only having cusip8
gen len=length(cusip)
tab len
/*
        len |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |          3        0.00        0.00
          5 |        318        0.03        0.03
          7 |      1,614        0.17        0.20
          9 |    944,525       99.80      100.00
------------+-----------------------------------
      Total |    946,460      100.00
*/
keep if len==9
drop len
gen cusip9=cusip
replace cusip=substr(cusip9,1,8)
bysort cusip ym: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    893,983       94.65       94.65
          2 |     25,460        2.70       97.34
          3 |      8,895        0.94       98.29
          4 |      8,016        0.85       99.13
          5 |      4,040        0.43       99.56
          6 |      1,452        0.15       99.72
          7 |        805        0.09       99.80
          8 |        600        0.06       99.87
          9 |        450        0.05       99.91
         10 |        300        0.03       99.94
         11 |        275        0.03       99.97
         12 |        132        0.01       99.99
         13 |        117        0.01      100.00
------------+-----------------------------------
      Total |    944,525      100.00
*/
drop if N>1
drop N _merge ticker
compress
save data/csrhub-with-cstat-from-csrhub-kld-cusips.dta, replace


***	Merge with KLD data
use data/kld-all-clean.dta, clear
/*
foreach v of varlist * {
	rename `v' `v'kld
}
rename (cusipkld yearkld) (cusip year)
*/
gen month=12
gen ym=ym(year,month)

bysort cusip ym: gen N=_N
tab N
/*

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     44,788       88.23       88.23
          2 |         34        0.07       88.30
          3 |         18        0.04       88.33
          4 |          8        0.02       88.35
          5 |         20        0.04       88.39
          6 |         12        0.02       88.41
          7 |         14        0.03       88.44
          8 |         24        0.05       88.49
         10 |         10        0.02       88.51
         63 |         63        0.12       88.63
         69 |         69        0.14       88.77
         77 |         77        0.15       88.92
        185 |        185        0.36       89.28
        643 |        643        1.27       90.55
        647 |        647        1.27       91.82
        651 |        651        1.28       93.11
        652 |        652        1.28       94.39
       2847 |      2,847        5.61      100.00
------------+-----------------------------------
      Total |     50,762      100.00
*/
drop if N>1
drop firm

drop N firm_n entity_type month year stnd_firm

merge 1:1 cusip ym using data/csrhub-with-cstat-from-csrhub-kld-cusips.dta, update assert(1 2 3 4 5) gen(_merge3)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       881,723
        from master                    16,264  (_merge3==1)
        from using                    865,459  (_merge3==2)

    matched                            28,524
        not updated                    28,524  (_merge3==3)
        missing updated                     0  (_merge3==4)
        nonmissing conflict                 0  (_merge3==5)
    -----------------------------------------
*/

drop stnd_firm _merge3

encode cusip, gen(cusip_n)
bysort cusip_n ym: gen N=_N
tab N
xtset cusip_n ym, m

order firm_kld firm_csrhub cusip ym

compress
save data/csrhub-kld-cstat-matched-on-cusip.dta, replace













/*	EXPLORATORY DATA ANALYSIS

set scheme plotplainblind

gen logrev=log(revt)
replace net_kld_con=net_kld_con*-1
graph matrix revt logrev tobinq mkt2book over_rtg net_kld net_kld_str net_kld_con


binscatter logrev net_kld, nq(31) xlabel(-20(5)20) line(none) by(year) legend(off) ylabel(-4(2)14)
binscatter logrev net_kld, nq(31) xlabel(-20(5)20) line(none) by(year) legend(off) ylabel(-4(2)14) medians

binscatter revt net_kld, nq(31) xlabel(-20(5)20) line(none) by(year) legend(off) medians
*/












*END
