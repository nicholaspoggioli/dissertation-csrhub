***	UNIQUE STND_FIRM IN KLD
use data\kld-all-clean.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
stnd_compname firm, gen(stnd_firm entity_type)

gen firm_kld=firm
label var firm_kld "firm name in kld-all-clean.dta"

compress
save data\kld-all-clean.dta, replace

*	Keep unique stnd_firm
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Save
compress
save data\unique-stnd_firm-kld.dta, replace



***	UNIQUE STND_FIRM IN CSTAT
use data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
stnd_compname conm, gen(stnd_firm entity_type)

gen firm_cstat=conm
label var firm_cstat "firm name in cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta"

gen year=fyear

compress
save data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, replace

*	Keep unique stnd_firm
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Save
compress
save data\unique-stnd_firm-cstat.dta, replace



***	UNIQUE STND_FIRM IN CSRHUB
use data/csrhub-all.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
capt n stnd_compname firm, gen(stnd_firm entity_type)

gen firm_csrhub=firm
label var firm_csrhub "firm name in csrhub-all.dta"

compress
save data\csrhub-all.dta, replace

*	Keep unique stnd_firm
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Save
compress
save data\unique-stnd_firm-csrhub.dta, replace





***	MATCH

*	KLD to CSTAT
use data\unique-stnd_firm-kld, clear

merge 1:1 stnd_firm using data\unique-stnd_firm-cstat.dta, gen(kld2cstat)
label var kld2cstat "indicator for merge of kld to cstat on stnd_firm"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         8,508
        from master                     6,458  (kld2cstat==1)
        from using                      2,050  (kld2cstat==2)

    matched                             3,222  (kld2cstat==3)
    -----------------------------------------
*/

merge 1:1 stnd_firm using data\unique-stnd_firm-csrhub.dta, gen(kldcstat2csrhub)
label var kldcstat2csrhub "indicator for merge of kldcstat to csrhub on stnd_firm"
/*

    Result                           # of obs.
    -----------------------------------------
    not matched                        14,712
        from master                     4,508  (kldcstat2csrhub==1)
        from using                     10,204  (kldcstat2csrhub==2)

    matched                             7,222  (kldcstat2csrhub==3)
    -----------------------------------------
*/


tab kld2cstat kldcstat2csrhub

/*
                      |    kldcstat2csrhub
            kld2cstat | master on  matched ( |     Total
----------------------+----------------------+----------
      master only (1) |     2,907      3,551 |     6,458 
       using only (2) |     1,254        796 |     2,050 
          matched (3) |       347      2,875 |     3,222 
----------------------+----------------------+----------
                Total |     4,508      7,222 |    11,730 
*/

*	Keep stnd_firm that match across all three datasets
gen keep=(kld2cstat==3 & kldcstat2csrhub==3)

keep if keep==1

keep stnd_firm firm_* kld2cstat kldcstat2csrhub
drop firm_n

codebook stnd_firm
*	2,875 unique stnd_firm names that are matched across all three datasets

gen stnd_firm_ind=1
label var stnd_firm_ind "=1 if stnd_firm matched across kld, cstat, and csrhub"

*	Save
compress
save data\unique-stnd_firm-kld-cstat-csrhub-match.dta, replace




/*	CREATE SUBSAMPLES OF EACH FULL DATASET,
	KEEPING ONLY OBSERVATIONS WITH FIRM NAMES THAT ARE
	MATCHED ACROSS ALL THREE DATASETS
*/

***	KLD
use data\kld-all-clean.dta, clear
merge m:1 stnd_firm using data\unique-stnd_firm-kld-cstat-csrhub-match.dta, ///
	keepusing(stnd_firm_ind)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        24,848
        from master                    24,848  (_merge==1)
        from using                          0  (_merge==2)

    matched                            25,914  (_merge==3)
    -----------------------------------------
*/

keep if stnd_firm_ind==1

tempfile d1
save `d1'
	
	
***	CSTAT
use data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear
merge m:1 stnd_firm using data\unique-stnd_firm-kld-cstat-csrhub-match.dta, ///
	keepusing(stnd_firm_ind)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        41,245
        from master                    41,245  (_merge==1)
        from using                          0  (_merge==2)

    matched                            64,225  (_merge==3)
    -----------------------------------------
*/

keep if stnd_firm_ind==1

tempfile d2
save `d2'


***	CSRHUB
use data\csrhub-all.dta, clear
merge m:1 stnd_firm using data\unique-stnd_firm-kld-cstat-csrhub-match.dta, ///
	keepusing(stnd_firm_ind)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       739,177
        from master                   739,177  (_merge==1)
        from using                          0  (_merge==2)

    matched                           226,700  (_merge==3)
    -----------------------------------------
*/

keep if stnd_firm_ind==1


***	Create single dataset: tricky because CSTAT and KLD are year-level and CSRHub is monthly




keep if stnd_firm_ind==1

codebook stnd_firm
/*
------------------------------------------------------------------------------------------------------------------------------------
stnd_firm                                                                                                              official name
------------------------------------------------------------------------------------------------------------------------------------

                  type:  string (str85), but longest is str28

         unique values:  2,875                    missing "":  0/316,839

              examples:  "CHART IND"
                         "GNC HOLDINGS"
                         "MIDDLESEX WATER"
                         "SCHOLASTIC"

               warning:  variable has embedded blanks
*/

*	2,875 unique firms, which matches the number above. IT WORKS!

compress







***	CLEAN DATA
order stnd_firm firm_csrhub firm_kld firm_cstat
order firm_csrhub firm_kld firm_cstat, after(firm

















































































*END
