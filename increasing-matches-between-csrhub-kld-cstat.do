///	Increasing matches between CSRHub, KLD, and Compustat



*** CSRHub
*	Load data
use data/csrhub-all-year-level.dta, clear

*	Keep needed variables
keep cusip cusip9 isin firm year in_csrhub
replace firm=upper(firm)
sort firm year
order firm year isin cusip cusip9

*	Generate country code where stock is listed
gen country_csrhub=substr(isin,1,2)
label var country_csrhub "(CSRHub) Country code from ISIN"

*	Save
compress
rename cusip cusip8
save data/csrhub-all-unique-firm-years-with-cusips.dta, replace






***	KLD
*	Load data
use data/kld-all.dta, clear

*	Keep needed variables
keep firm_kld year cusip ticker in_kld
gen firm=upper(firm_kld)
replace cusip=upper(cusip)
sort cusip year
order firm year cusip ticker firm_kld

*	Export unique cusip for conversion to 9 digit
preserve
bysort cusip: gen n=_n
keep if n==1
keep cusip
export delimited using "D:\Dropbox\papers\4 work in progress\dissertation-csrhub\project\data\unique-8-digit-cusips-in-kld-data.txt", delimiter(tab) novarnames replace
restore

*	Merge with 9-digit CUSIPs from WRDS cusip converter
preserve
use data/kld-9-digit-cusip-from-8-digit-in-kld-data.dta, clear
rename cusip cusip9
gen cusip=substr(cusip9,1,8)
compress
save data/kld-9-digit-cusip-from-8-digit-in-kld-data-with-8-digit-added.dta, replace
restore

merge m:1 cusip using data/kld-9-digit-cusip-from-8-digit-in-kld-data-with-8-digit-added.dta
/*     Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                            47,097  (_merge==3)
    -----------------------------------------
*/
drop _merge

*	Save
compress
rename cusip cusip8
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
export delimited using "D:\Dropbox\papers\4 work in progress\dissertation-csrhub\project\data\unique-9-digit-cusips-in-cstat-data.txt", delimiter(tab) novarnames replace
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
compress
rename cusip cusip9
rename fyear year
order firm year cusip8 cusip9
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
use data/csrhub-all-unique-firm-years-with-cusips.dta
merge 1:1 cusip8 year using data/kld-all-unique-firm-years-with-cusips.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        92,809
        from master                    62,258  (_merge==1)
        from using                     30,551  (_merge==2)

    matched                            16,546  (_merge==3)
    -----------------------------------------
*/
use data/csrhub-all-unique-firm-years-with-cusips.dta, clear
merge 1:1 cusip9 year using data/kld-all-unique-firm-years-with-cusips.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        92,809
        from master                    62,258  (_merge==1)
        from using                     30,551  (_merge==2)

    matched                            16,546  (_merge==3)
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

egen in_three=rowtotal(in_csrhub in_cstat in_kld)
tab in_three
/*   in_three |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    357,011       88.60       88.60
          2 |     30,884        7.66       96.26
          3 |     15,073        3.74      100.00
------------+-----------------------------------
      Total |    402,968      100.00
*/











*	Merge KLD and Compustat
use data/kld-all-unique-firm-years-with-cusips.dta, clear
merge 1:1 cusip8 year using data/cstat-all-unique-firm-years-with-cusips.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       316,932
        from master                    12,966  (_merge==1)
        from using                    303,966  (_merge==2)

    matched                            34,131  (_merge==3)
    -----------------------------------------
*/


use data/kld-all-unique-firm-years-with-cusips.dta, clear
merge 1:1 cusip9 year using data/cstat-all-unique-firm-years-with-cusips.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       316,932
        from master                    12,966  (_merge==1)
        from using                    303,966  (_merge==2)

    matched                            34,131  (_merge==3)
    -----------------------------------------

*/




































*END
