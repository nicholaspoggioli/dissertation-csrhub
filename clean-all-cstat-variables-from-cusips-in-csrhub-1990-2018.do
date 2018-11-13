***	CLEANING ALL COMPUSTAT FUNDAMENTALS ANNUAL VARIABLES FOR ALL CUSIPS IN CSRHUB DATA

use data/cstat-all-variables-for-all-cusips-in-csrhub-data-1990-2018.dta, clear

*	nondestructive file size reduction
compress

*	clean
order conm cusip tic datadate fyear fyr

*	gen
gen ym=ym(year(datadate),month(datadate))

*	save
compress
save data/cstat-all-variables-for-all-cusips-in-csrhub-data-1990-2018-clean.dta, replace
