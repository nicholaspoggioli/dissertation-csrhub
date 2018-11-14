***	CLEANING ALL COMPUSTAT FUNDAMENTALS ANNUAL VARIABLES FOR ALL CUSIPS

***=======================***
*		CSRHUB				*
***=======================***

/***	File size reduction
use data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, clear

*	clean
order conm cusip tic datadate fyear fyr

*	gen
gen ym=ym(year(datadate),month(datadate))

*	save
compress
save data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, replace
*/

use data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, replace

*	keep only ym in csrhub (587 - 692)
drop if ym<587 | ym>692

*	save
compress
save data/cstat-all-variables-for-all-cusip9-in-csrhub-data-csrhub-ym-only.dta, replace


***=======================***
*			KLD				*
***=======================***
/***	File size reduction
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
*/


***===========================================***
*	MERGE CSTAT FOR CSRHUB 2 CSTAT FOR KLD		*
***===========================================***

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

tempfile d1
save `d1'

***	Merge with CSRHub data
use data/csrhub-all.dta, clear
bysort cusip ym: gen N=_N
drop if N>1
drop N

tempfile d2
save `d2'

use `d1', clear
merge 1:1 cusip ym using `d2', update assert(1 2 3 4 5)

gen cusip9=cusip
replace cusip=substr(cusip9,1,8)

bysort cusip ym: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    895,918       94.66       94.66
          2 |     25,460        2.69       97.35
          3 |      8,895        0.94       98.29
          4 |      8,016        0.85       99.14
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
      Total |    946,460      100.00
*/
drop if N>1
drop N

tempfile d3
save `d3'

***	Merge with KLD data
use data/kld-all-clean.dta, clear

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
drop N

drop firm_n
merge 1:1 cusip ym using `d3', update assert(1 2 3 4 5) gen(_merge3)


encode cusip, gen(cusip9)
xtset cusip9 ym, m


set scheme plotplainblind
gen logrev=log(revt)
binscatter logrev net_kld, nq(31) xlabel(-20(5)20) line(none) by(year) legend(off) ylabel(-4(2)14)
binscatter logrev net_kld, nq(31) xlabel(-20(5)20) line(none) by(year) legend(off) ylabel(-4(2)14) medians

binscatter revt net_kld, nq(31) xlabel(-20(5)20) line(none) by(year) legend(off) medians












*END
