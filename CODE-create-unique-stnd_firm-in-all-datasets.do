***	UNIQUE STND_FIRM IN KLD
use data\kld-all-clean.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
capt n search stnd_compname
stnd_compname firm, gen(stnd_firm entity_type)

*	Keep unique stnd_firm
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Save
save data\kld-unique-stnd_firm, replace



***	UNIQUE STND_FIRM IN CSTAT
use data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
capt n search stnd_compname
stnd_compname conm, gen(stnd_firm entity_type)

*	Keep unique stnd_firm
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Save
save data\cstat-unique-stnd_firm, replace



***	UNIQUE STND_FIRM IN CSRHUB
use data/csrhub-all.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
capt n search stnd_compname
stnd_compname firm, gen(stnd_firm entity_type)

*	Keep unique stnd_firm
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Save
save data\csrhub-unique-stnd_firm, replace
