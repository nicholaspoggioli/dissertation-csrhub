///	Increasing matches between CSRHub, KLD, and Compustat

/*	Time coverage
		Compustat: 	1988 - present
		KLD:		1995 - 2016
		CSRHub:		2008 - 2017
		
		Limiting coverage window: 2008 (CSRHub) - 2016 (KLD)
*/


*** CSRHub
*	Load data
use data/csrhub-all-year-level.dta, clear

*	Keep needed variables
keep cusip cusip9 isin firm year in_csrhub
replace firm=upper(firm)
sort firm year
order firm year isin cusip cusip9
gen firm_csrhub=firm

label var firm_csrhub "(CSRHub) firm name"
label var year "(CSRHub) year"
label var in_csrhub "(CSRHub) =1 if in CSRHub data"

*	Generate country code where stock is listed
gen country_csrhub=substr(isin,1,2)
label var country_csrhub "(CSRHub) Country code from ISIN"

*	Save
rename cusip cusip8
gen cusip8_csrhub = cusip8
label var cusip8_csrhub "(CSRHub) 8-digit CUSIP"
gen cusip9_csrhub = cusip9
label var cusip9_csrhub "(CSRHub) 9-digit CUSIP"

compress
save data/csrhub-all-unique-firm-years-with-cusips.dta, replace






***	KLD
*	Load data
use data/kld-all.dta, clear

*	Fix too-short CUSIP
gen len=length(cusip)
tab len
/*        len |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |          1        0.00        0.00
          4 |          2        0.00        0.01
          6 |         39        0.08        0.09
          7 |        420        0.89        0.98
          8 |     46,635       99.02      100.00
------------+-----------------------------------
      Total |     47,097      100.00
*/

replace cusip="0" + cusip if len==7
replace cusip="00" + cusip if len==6

replace cusip="00036020" if ticker=="AAON"

*	Keep needed variables
keep firm_kld year cusip ticker in_kld
gen firm=upper(firm_kld)
replace cusip=upper(cusip)
sort cusip year
order firm year cusip ticker firm_kld

label var firm "(KLD) firm name"
label var in_kld "(KLD) =1 if in KLD data"

*	Export unique cusip for conversion to 9 digit
preserve
bysort cusip: gen n=_n
keep if n==1
keep cusip
export delimited using "data\unique-8-digit-cusips-in-kld-data.txt", delimiter(tab) novarnames replace
restore

*	Merge with 9-digit CUSIPs from WRDS cusip converter
preserve
use data/kld-9-digit-cusip-from-8-digit-in-kld-data.dta, clear
rename cusip cusip9
label var cusip9 "(KLD) 9-digit CUSIP"
gen cusip=substr(cusip9,1,8)
compress
save data/kld-9-digit-cusip-from-8-digit-in-kld-data-with-8-digit-added.dta, replace
restore

merge m:1 cusip using data/kld-9-digit-cusip-from-8-digit-in-kld-data-with-8-digit-added.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             1
        from master                         0  (_merge==1)
        from using                          1  (_merge==2)

    matched                            47,097  (_merge==3)
    -----------------------------------------

The one _merge == 2 comes from fixing ticker=="AAON" manually above.
*/
drop _merge



*	Save
rename cusip cusip8
label var cusip8 "(KLD) 8-digit CUSIP"
gen cusip8_kld = cusip8
label var cusip8_kld "(KLD) 8-digit CUSIP"
gen cusip9_kld = cusip9
label var cusip9_kld "(KLD) 9-digit CUSIP"
rename ticker ticker_kld
gen year_kld=year
label var year_kld "(KLD) year"

compress
save data/kld-all-unique-firm-years-with-cusips.dta, replace







***	Compustat
*	Load data
use data/cstat-fundamentals-annual-all-firms-1989-2018.dta, clear
keep if indfmt=="INDL"
drop if fyear==.
rename conm firm
gen in_cstat=1

*	Keep needed variables
keep firm tic cusip fyear fic in_cstat
gen firm_cstat=firm
replace firm=upper(firm)
order firm fyear cusip tic

*	Export unique CUSIPS for conversion to 8-digit
preserve
replace cusip=upper(cusip)
bysort cusip: gen n=_n
keep if n==1
keep cusip
drop if cusip==""
export delimited using "data\unique-9-digit-cusips-in-cstat-data.txt", delimiter(tab) novarnames replace
restore

*	Merge with 8-digit CUSIPs from WRDS cusip converter
preserve
use data/cstat-8-digit-cusip-from-9-digit-in-cstat-data.dta, clear
rename cusip cusip8
compress
save data/cstat-8-digit-cusip-from-9-digit-in-cstat-data-2.dta, replace
restore

gen cusip8=upper(substr(cusip,1,8))

merge m:1 cusip8 using data/cstat-8-digit-cusip-from-9-digit-in-cstat-data-2.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                           123
        from master                       123  (_merge==1)
        from using                          0  (_merge==2)

    matched                           338,097  (_merge==3)
    -----------------------------------------
*/

drop if cusip==""
tab _merge
/*                 _merge |      Freq.     Percent        Cum.
------------------------+-----------------------------------
            matched (3) |    338,097      100.00      100.00
------------------------+-----------------------------------
                  Total |    338,097      100.00
*/
drop _merge

*	Save
rename cusip cusip9
rename fyear year
order firm year cusip8 cusip9
label var firm "(CSTAT) firm name"
label var year "(CSTAT) year"
label var cusip8 "(CSTAT) 8-digit CUSIP"
label var cusip9 "(CSTAT) 9-digit CUSIP"
rename tic ticker
label var ticker "(CSTAT) ticker symbol"
gen ticker_cstat = ticker
label var ticker_cstat "(CSTAT) ticker symbol"
rename fic country_cstat
label var country_cstat "(CSTAT) ISO country code of incorporation"
label var in_cstat "(CSTAT) =1 if in Compustat"
label var firm_cstat "(CSTAT) firm name"
gen cusip8_cstat = cusip8
label var cusip8_cstat "(CSTAT) 8-digit CUSIP"
gen cusip9_cstat = cusip9
label var cusip9_cstat "(CSTAT) 9-digit CUSIP"

compress
save data/cstat-all-unique-firm-years-with-cusips.dta, replace













***	Merge on CUSIP
/*	CSRHub
		- 8-digit
		- 9-digit
	KLD
		- 8-digit
		- 9-digit
	Compustat
		- 8-digit
		- 9-digit
*/

*	Merge CSRHub and KLD
use data/csrhub-all-unique-firm-years-with-cusips.dta, clear
merge 1:1 cusip8 year using data/kld-all-unique-firm-years-with-cusips.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        92,802
        from master                    62,254  (_merge==1)
        from using                     30,548  (_merge==2)

    matched                            16,550  (_merge==3)
    -----------------------------------------
*/
use data/csrhub-all-unique-firm-years-with-cusips.dta, clear
merge 1:1 cusip9 year using data/kld-all-unique-firm-years-with-cusips.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        92,802
        from master                    62,254  (_merge==1)
        from using                     30,548  (_merge==2)

    matched                            16,550  (_merge==3)
    -----------------------------------------
*/




*	Merge KLD and Compustat
use data/kld-all-unique-firm-years-with-cusips.dta, clear
merge 1:1 cusip8 year using data/cstat-all-unique-firm-years-with-cusips.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       316,915
        from master                    12,958  (_merge==1)
        from using                    303,957  (_merge==2)

    matched                            34,140  (_merge==3)
    -----------------------------------------
*/


use data/kld-all-unique-firm-years-with-cusips.dta, clear
merge 1:1 cusip9 year using data/cstat-all-unique-firm-years-with-cusips.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       316,915
        from master                    12,958  (_merge==1)
        from using                    303,957  (_merge==2)

    matched                            34,140  (_merge==3)
    -----------------------------------------
*/











*	Merge CSRHub and Compustat
use data/csrhub-all-unique-firm-years-with-cusips.dta, clear
merge 1:1 cusip8 year using data/cstat-all-unique-firm-years-with-cusips.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       366,049
        from master                    53,378  (_merge==1)
        from using                    312,671  (_merge==2)

    matched                            25,426  (_merge==3)
    -----------------------------------------
*/

/*
use data/csrhub-all-unique-firm-years-with-cusips.dta, clear
merge 1:1 cusip9 year using data/cstat-all-unique-firm-years-with-cusips.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       366,049
        from master                    53,378  (_merge==1)
        from using                    312,671  (_merge==2)

    matched                            25,426  (_merge==3)
    -----------------------------------------
*/
*/

*	Merge with KLD
drop _merge
merge 1:1 cusip8 year using data/kld-all-unique-firm-years-with-cusips.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       367,347
        from master                   355,862  (_merge==1)
        from using                     11,485  (_merge==2)

    matched                            35,613  (_merge==3)
    -----------------------------------------
*/
drop _merge

*	Identify matches
egen datasets=rowtotal(in_csrhub in_cstat in_kld)
tab datasets
/*   datasets |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |          1        0.00        0.00
          1 |    356,997       88.59       88.59
          2 |     30,885        7.66       96.26
          3 |     15,077        3.74      100.00
------------+-----------------------------------
      Total |    402,960      100.00
*/

gen in_three=(datasets==3)
tab in_three
label var in_three "=1 if matched across all datasets"
/*   in_three |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    387,883       96.26       96.26
          1 |     15,077        3.74      100.00
------------+-----------------------------------
      Total |    402,960      100.00
*/
drop datasets

*	Keep observations in limiting data window
keep if year >= 2008
keep if year <= 2016

*	Organize data
sort firm year


*	Save
compress

tab in_three
/*    =1 if |
    matched |
 across all |
   datasets |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    135,747       90.00       90.00
          1 |     15,077       10.00      100.00
------------+-----------------------------------
      Total |    150,824      100.00

	  About 200 fewer matches than produced by the existing data creation file
	  
	  */



















































*END
