use data/csrhub-kld-cstat-year-level-with-treatment-variables.dta, clear

/// PRETTIFY

***	Set panel
encode cusip, gen(cusip_n)
xtset cusip_n year, y





***	Histogram of years in data for each CUSIP
preserve

bysort cusip: gen n=_n
keep if n==1

histogram N, d freq addlabel xlab(0(1)8) ///
	ti("Years of observations for each CUSIP" "in data matched across all 3 datasets") ///
	xti("Years of observations in the 8-year panel") ///
	yti("CUSIPs")
	
restore
