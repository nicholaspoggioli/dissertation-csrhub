***	CLEANING ALL COMPUSTAT FUNDAMENTALS ANNUAL VARIABLES FOR ALL CUSIPS IN CSRHUB DATA
/*
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

*	keep only ym in csrhub (587 - 692)
drop if ym<587 | ym>692

*	save
compress
save data/cstat-all-variables-for-all-cusips-in-csrhub-data-csrhub-ym-only.dta
*/

*	merge with csrhub data
use data/cstat-all-variables-for-all-cusips-in-csrhub-data-csrhub-ym-only, clear

merge 1:m cusip ym using data/csrhub-all.dta
