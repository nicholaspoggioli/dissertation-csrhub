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

save data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, replace

*	Keep unique stnd_firm
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Gen
gen year=fyear

*	Save
compress
save data\unique-stnd_firm-cstat.dta, replace



***	UNIQUE STND_FIRM IN CSRHUB
use data/csrhub-all.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
capt n stnd_compname firm, gen(stnd_firm entity_type)

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

merge 1:1 stnd_firm using data\unique-stnd_firm-csrhub.dta, gen(kldcstat2csrhub)

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
gen keep=(kld2cstat==3 | kldcstat2csrhub==3)

keep if keep==1

*	Save
drop entity_type
compress
save data\unique-stnd_firm-kld-cstat-csrhub-match.dta, replace




***	MERGE BACK INTO PARENT DATASETS

*	KLD
merge 1:m firm using data\kld-all-clean.dta
