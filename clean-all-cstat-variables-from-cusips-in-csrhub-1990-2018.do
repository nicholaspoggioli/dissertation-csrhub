***	CLEANING ALL COMPUSTAT FUNDAMENTALS ANNUAL VARIABLES FOR ALL CUSIPS

***	CSRHUB
/*
use data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, clear

*	nondestructive file size reduction
compress

*	clean
order conm cusip tic datadate fyear fyr

*	gen
gen ym=ym(year(datadate),month(datadate))

*	save
compress
save data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, replace

*	keep only ym in csrhub (587 - 692)
drop if ym<587 | ym>692

*	save
compress
save data/cstat-all-variables-for-all-cusip9-in-csrhub-data-csrhub-ym-only.dta, replace
*/

*	merge with csrhub data
use data/cstat-all-variables-for-all-cusip9-in-csrhub-data-csrhub-ym-only, clear

merge 1:m cusip ym using data/csrhub-all.dta





***	KLD
use data/cstat-all-variables-for-all-cusip9-in-kld-data-1990-2018.dta, clear

compress

order conm cusip tic datadate fyear fyr

gen ym=ym(year(datadate),month(datadate))

*save
compress
save data/cstat-all-variables-for-all-cusip9-in-kld-data-csrhub-ym-only.dta, replace
