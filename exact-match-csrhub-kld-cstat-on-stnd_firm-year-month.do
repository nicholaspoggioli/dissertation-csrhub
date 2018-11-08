***	UNIQUE STND_FIRM IN KLD
/*use data\kld-all-clean.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
stnd_compname firm, gen(stnd_firm entity_type)

gen firm_kld=firm
label var firm_kld "firm name in kld-all-clean.dta"

compress
save data\kld-all-clean.dta, replace
*/

*	Keep unique stnd_firm
use data\kld-all-clean.dta, clear
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Fix observations to prevent duplicate matches later
replace stnd_firm="SPIRE CORP" if stnd_firm=="SPIRE"

*	Save
compress
save data\unique-stnd_firm-kld.dta, replace
keep stnd_firm firm_kld
sort stnd_firm
gen idkld=_n
label var idkld "unique row id for unique stnd_firm in kld data"
compress
save data\unique-stnd_firm-kld-stnd_firm-only.dta, replace
export delimited using data\unique-stnd_firm-kld.csv, replace



***	UNIQUE STND_FIRM IN CSTAT
/*use data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear

*Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
stnd_compname conm, gen(stnd_firm entity_type)

gen firm_cstat=conm
label var firm_cstat "firm name in cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta"

gen year=year(datadate)

compress
save data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, replace
*/

*	Keep unique stnd_firm
use data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Fix observations to prevent duplicate matches later
replace stnd_firm="SPIRE CORP" if stnd_firm=="SPIRE"
replace stnd_firm="STERLING BANCORP INC" if stnd_firm=="STERLING BANCORP" & cik=="0001680379"

*	Save
compress
save data\unique-stnd_firm-cstat.dta, replace
keep stnd_firm firm_cstat
sort stnd_firm
gen idcstat=_n
label var idcstat "unique row id for unique stnd_firm in cstat"
compress
save data\unique-stnd_firm-cstat-stnd_firm-only.dta, replace
export delimited using data\unique-stnd_firm-cstat.csv, replace


***	UNIQUE STND_FIRM IN CSRHUB
/*use data/csrhub-all.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
capt n stnd_compname firm, gen(stnd_firm entity_type)

gen firm_csrhub=firm
label var firm_csrhub "firm name in csrhub-all.dta"

compress
save data\csrhub-all.dta, replace
*/

*	Keep unique stnd_firm
use data\csrhub-all.dta, clear
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Fix observations to prevent duplicate matches later
replace stnd_firm="SPIRE INC" if stnd_firm=="SPIRE"

*	Save
compress
save data\unique-stnd_firm-csrhub.dta, replace
keep stnd_firm firm_csrhub
sort stnd_firm
gen idcsrhub=_n
label var idcsrhub "unique row id for unique stnd_firm in csrhub data"
compress
save data\unique-stnd_firm-csrhub-stnd_firm-only.dta, replace
export delimited using data\unique-stnd_firm-csrhub.csv, replace







***	MATCH KLD AND CSTAT TO CSRHUB ON UNIQUE STND_FIRM
use data\unique-stnd_firm-csrhub-stnd_firm-only.dta, clear

merge 1:1 stnd_firm using data\unique-stnd_firm-kld-stnd_firm-only.dta, gen(hub2kld)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        14,256
        from master                    11,001  (hub2kld==1)
        from using                      3,255  (hub2kld==2)

    matched                             6,425  (hub2kld==3)
    -----------------------------------------
*/

merge 1:1 stnd_firm using data\unique-stnd_firm-cstat-stnd_firm-only.dta, gen(hubkld2cstat)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        17,917
        from master                    16,663  (hubkld2cstat==1)
        from using                      1,254  (hubkld2cstat==2)

    matched                             4,018  (hubkld2cstat==3)
    -----------------------------------------
*/
tab hub2kld hubkld2cstat
/*
                      |     hubkld2cstat
              hub2kld | master on  matched ( |     Total
----------------------+----------------------+----------
      master only (1) |    10,205        796 |    11,001 
       using only (2) |     2,907        348 |     3,255 
          matched (3) |     3,551      2,874 |     6,425 
----------------------+----------------------+----------
                Total |    16,663      4,018 |    20,681 

*/

keep stnd_firm firm_csrhub firm_kld firm_cstat id*
order id*, last
format %30s stnd_firm firm_*

mark match_all
markout match_all idcsrhub idkld idcstat
label var match_all "=1 if stnd_firm matched across csrhub kld & cstat"

mark match_hubkld
markout match_hubkld idcsrhub idkld
label var match_hubkld "=1 if stnd_firm matched across csrhub & kld"

mark match_hubcstat
markout match_hubcstat idcsrhub idcstat
label var match_hubcstat "=1 if stnd_firm matched across csrhub & cstat"

mark match_kldcstat
markout match_kldcstat idkld idcstat
label var match_kldcstat "=1 if stnd_firm matched across kld & cstat"

*Save
save data\crosswalk-csrhub-kld-cstat-stnd_firm.dta, replace

*/









/*

***	MERGE STND_NAME CROSSWALK INTO EACH MASTER DATASET
*	KLD
use data\kld-all-clean.dta, clear
merge m:1 stnd_firm using data\crosswalk-csrhub-kld-cstat-stnd_firm.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        12,257
        from master                         1  (_merge==1)
        from using                     12,256  (_merge==2)

    matched                            50,761  (_merge==3)
    -----------------------------------------
*/
keep if _merge==3
drop _merge firm_n
order stnd_firm firm_*
format %30s stnd_firm firm_* firm
sort stnd_firm year
compress

bysort stnd_firm year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     50,752       99.98       99.98
          2 |          6        0.01       99.99
          3 |          3        0.01      100.00
------------+-----------------------------------
      Total |     50,761      100.00
*/

*	Fix observations to prevent duplicate matches later
sort stnd_firm ticker year
replace stnd_firm="1ST BANCORP INC" if stnd_firm=="1ST BANCORP" & ticker=="FBNC"
replace stnd_firm="THE 1ST BANCORP INC" if stnd_firm=="1ST BANCORP" & ticker=="FNLC"
replace stnd_firm="FNB CORP" if stnd_firm=="FNB" & ticker=="FNBN"
replace stnd_firm="UNITED SECURITY BANCSHARES INC" if stnd_firm=="UNITED SECURITY BANCSHARES" & ticker=="USBI"

drop N
bysort stnd_firm year: gen N=_N
tab N
/*

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     50,761      100.00      100.00
------------+-----------------------------------
      Total |     50,761      100.00
*/
drop N

gen in_kld=1
label var in_kld "=1 if in kld data"

compress
save data\kld-all-clean-with-stnd_firm-crosswalk.dta, replace



*	CSTAT
use data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear
replace stnd_firm="STERLING BANCORP INC" if stnd_firm=="STERLING BANCORP" & cik=="0001680379"
replace stnd_firm="UNION BANKSHARES INC" if stnd_firm=="UNION BANKSHARES" & gvkey=="111537"

merge m:1 stnd_firm using data\crosswalk-csrhub-kld-cstat-stnd_firm.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        16,752
        from master                        88  (_merge==1)
        from using                     16,664  (_merge==2)

    matched                           105,382  (_merge==3)
    -----------------------------------------

*/
keep if _merge==3
order stnd_firm firm_*
sort stnd_firm datadate
drop _merge
compress

*change year from datadate to fiscal year
drop year
gen year=fyear
replace year=year(datadate) if fyear==.

bysort stnd_firm year: gen N=_N
tab N
/*

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     76,316       72.42       72.42
          2 |     29,066       27.58      100.00
------------+-----------------------------------
      Total |    105,382      100.00


*/
tab N indfmt if N>1
/*

           |    Industry Format
         N |        FS       INDL |     Total
-----------+----------------------+----------
         2 |    14,525     14,541 |    29,066 
-----------+----------------------+----------
     Total |    14,525     14,541 |    29,066 

*/
drop if indfmt=="FS"
drop N
bysort stnd_firm year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     90,832       99.98       99.98
          2 |         16        0.02      100.00
------------+-----------------------------------
      Total |     90,848      100.00

*/
drop if fyear==.
drop N
bysort stnd_firm year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     90,601      100.00      100.00
------------+-----------------------------------
      Total |     90,601      100.00

*/

*create needed variables
encode stnd_firm, gen(firm_n)
xtset firm_n year, y
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

label var roa "(CSTAT) Return on assets (ni / at)"
label var lroa "(CSTAT) 1-year lagged roa"
label var lni "(CSTAT) 1-year lagged ni"
label var debt "(CSTAT) Debt ratio (dltt / at)"
label var rd "(CSTAT) R&D expense by sales (xrd / sale)"
label var ad "(CSTAT) Advertising expense by sales (xad / sale)"

drop N

gen in_cstat=1
label var in_cstat "=1 if in compustat data"

gen ym=ym(fyear,fyr)

compress
save data\cstat-all-clean-with-stnd_firm-crosswalk.dta, replace


*	CSRHUB
use data\csrhub-all.dta, clear
merge m:1 stnd_firm using data\crosswalk-csrhub-kld-cstat-stnd_firm.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         4,539
        from master                        28  (_merge==1)
        from using                      4,511  (_merge==2)

    matched                           965,849  (_merge==3)
    -----------------------------------------

*/
keep if _merge==3
order stnd_firm ym
sort stnd_firm ym
drop _merge firm_n ticker in_other_vars in_ovrl_enviro in_2017_update ///
	in_csrhub row_id_csrhub entity_type
compress

gen in_csrhub=1
label var in_csrhub "=1 if in csrhub data"

compress
save data\csrhub-all-clean-with-stnd_firm-crosswalk.dta, replace

*/




/*


***	MERGE DATASETS TOGETHER ON STND_FIRM YM
*	Merge CSTAT and KLD on stnd_firm year
use data\cstat-all-clean-with-stnd_firm-crosswalk.dta, clear

merge 1:1 stnd_firm year using data\kld-all-clean-with-stnd_firm-crosswalk.dta, nogen
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        86,248
        from master                    63,044  (_merge==1)
        from using                     23,204  (_merge==2)

    matched                            27,557  (_merge==3)
    -----------------------------------------
*/
replace ym=ym(year,12) if ym==. & in_kld==1										/* Assume KLD not matched with CSTAT is month 12	*/

save data\cstat-2-kld-stnd_firm-year.dta, replace


*	CSRhub with merged CSTAT-KLD on stnd_firm ym
use data\csrhub-all-clean-with-stnd_firm-crosswalk.dta, clear

bysort stnd_firm ym: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |  1,051,911       99.84       99.84
          2 |      1,716        0.16      100.00
------------+-----------------------------------
      Total |  1,053,627      100.00
*/
drop if N>1																		/*	Come back and fix this	*/
drop N

merge 1:1 stnd_firm ym using data\cstat-2-kld-stnd_firm-year.dta, nogen
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                     1,028,922
        from master                   939,625  
        from using                     89,297  

    matched                            24,508  
    -----------------------------------------
*/
drop firm_n
order stnd_firm firm_*
format stnd_firm firm_* %30s

***	Set panel
encode stnd_firm, gen(firm_n)
xtset firm_n ym, m
order stnd_firm ym

*SAVE
compress
save data\csrhub-kld-cstat-with-crosswalk-exact-stnd_firm-ym-matches-clean.dta, replace









