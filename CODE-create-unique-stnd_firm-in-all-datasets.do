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
keep stnd_firm firm
gen idkld=_n
label var idkld "unique row variable"
compress
save data\unique-stnd_firm-kld-stnd_firm-only.dta, replace
export delimited using data\unique-stnd_firm-kld.csv, replace



***	UNIQUE STND_FIRM IN CSTAT
use data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
stnd_compname conm, gen(stnd_firm entity_type)

gen firm_cstat=conm
label var firm_cstat "firm name in cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta"

gen year=year(datadate)

compress
save data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, replace

*	Keep unique stnd_firm
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Save
compress
save data\unique-stnd_firm-cstat.dta, replace
keep stnd_firm conm
gen idcstat=_n
label var idcstat "unique row identifier"
compress
save data\unique-stnd_firm-cstat-stnd_firm-only.dta, replace
export delimited using data\unique-stnd_firm-cstat.csv, replace


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
keep stnd_firm firm
gen idcsrhub=_n
label var idcsrhub "unique row identifier"
compress
save data\unique-stnd_firm-csrhub-stnd_firm-only.dta, replace
export delimited using data\unique-stnd_firm-csrhub.csv, replace





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
drop _merge

tempfile 1
save `1'
	
	
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
drop if indfmt=="FS" /*	DROP FINANCIAL SERVICE FIRMS	*/

bysort stnd_firm year: gen N=_N
tab N
/*

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     55,453       99.55       99.55
          2 |        250        0.45      100.00
------------+-----------------------------------
      Total |     55,703      100.00
*/
drop if N>1
drop N

drop _merge

***	Merge KLD and CSTAT on stnd_firm year

merge 1:1 stnd_firm year using `1'
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        29,997
        from master                    29,768  (_merge==1)
        from using                        229  (_merge==2)

    matched                            25,685  (_merge==3)
    -----------------------------------------
*/

keep if _merge==3
*(29,997 observations deleted)
drop _merge

gen month=month(datadate)

tempfile A
save `A'

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
keep if _merge==3
drop _merge

bysort stnd_firm year month: gen N=_N											/*	Could do better here	*/
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    737,803       99.81       99.81
          2 |      1,374        0.19      100.00
------------+-----------------------------------
      Total |    739,177      100.00

*/
drop if N>1
drop N

compress

***	Merge all three
merge 1:1 stnd_firm year month using `A'

*	correct firm_n
drop firm_n
encode stnd_firm, gen(firm_n)


/*
----------------------------------------------------------------------------------------------------------------------------------------------------------------
stnd_firm                                                                                                                                          official name
----------------------------------------------------------------------------------------------------------------------------------------------------------------

                  type:  string (str67), but longest is str28

         unique values:  2,875                    missing "":  0/226,700

              examples:  "CHARTER COMMUNICATIONS"
                         "GOGO"
                         "MIDDLEBY"
                         "SCHERING PLOUGH"

               warning:  variable has embedded blanks
*/

*	2,875 unique firms, which matches the number above. IT WORKS!

compress


***	CLEAN DATA
order stnd_firm firm_csrhub firm_kld firm_cstat
order firm_csrhub firm_kld firm_cstat, after(firm)

label data "unique stnd_firm that match across kld, cstat, and csrhub data"

***	SAVE
save data\subset-stnd_firm-in-all-three-datasets.dta, replace





				***=============================***
				***		COMBINE WITH MATCHIT	***
				***=============================***





***	fuzzy string matching csrhub to cstat
/*
use data\unique-stnd_firm-csrhub-stnd_firm-only.dta, clear

capt n ssc install matchit
capt n ssc install freqindex

matchit idcsrhub stnd_firm using data\unique-stnd_firm-cstat-stnd_firm-only.dta, ///
	idu(idcstat) txtu(stnd_firm) similmethod(ngram,3) time threshold(.75)
	
gsort stnd_firm -similscore

by stnd_firm: egen simmax=max(similscore)
by stnd_firm: gen n=_n
drop if simmax==1 & n!=1
drop simmax n

compress
save data\matchit-csrhub-2-cstat.dta

preserve
keep if similscore==1
compress
save data\matchit-csrhub-2-cstat-exact-matches.dta
restore
*/

***	Assess likely matches:
use data\matchit-csrhub-2-cstat.dta, clear
drop if similscore==1
set seed 61047
bysort stnd_firm: gen rando=rnormal()
by stnd_firm: replace rando=rando[_n-1] if _n!=1

gsort rando stnd_firm -similscore
br idcsrhub stnd_firm idcstat stnd_firm1

/*
idcsrhub	stnd_firm	idcstat	stnd_firm1
16453	VANCEINFO TECHNOLOGIES	4941	VANCEINFO TECHNOLOGIES ADR
idcsrhub	stnd_firm	idcstat	stnd_firm1
14805	STEVEN MADDEN	2918	MADDEN STEVEN
idcsrhub	stnd_firm	idcstat	stnd_firm1
938	AMERICAN EAGLE OUTFITTERS	366	AMERN EAGLE OUTFITTERS
idcsrhub	stnd_firm	idcstat	stnd_firm1
7677	HORIZON BANCORP	2340	HORIZON BANCORP IN
idcsrhub	stnd_firm	idcstat	stnd_firm1
4885	DIVERSIFIED RESTAURANT HOLDINGS	1550	DIVERSIFIED RESTAURANT HLDGS
idcsrhub	stnd_firm	idcstat	stnd_firm1
12347	PHYSICIANS REALTY TRUST	3725	PHYSICIANS REALTY TR
idcsrhub	stnd_firm	idcstat	stnd_firm1
14795	STERLING BANK	4466	STERLING BANCORP
idcsrhub	stnd_firm	idcstat	stnd_firm1
699	ALEXANDRIA REAL ESTATE EQUITIES	243	ALEXANDRIA RE EQUITIES



*/




***	fuzzy string matching csrhub to kld
use data\unique-stnd_firm-csrhub-stnd_firm-only.dta, clear

capt n ssc install matchit
capt n ssc install freqindex

matchit idcsrhub stnd_firm using data\unique-stnd_firm-kld-stnd_firm-only.dta, ///
	idu(idkld) txtu(stnd_firm) similmethod(ngram,3) time threshold(.75)
	
gsort stnd_firm -similscore

by stnd_firm: egen simmax=max(similscore)
by stnd_firm: gen n=_n
drop if simmax==1 & n!=1
drop simmax n

compress
save data\matchit-csrhub-2-kld.dta

preserve
keep if similscore==1
compress
save data\matchit-csrhub-2-kld-exact-matches.dta
restore

keep if similscore!=1
































*END








































































*END
