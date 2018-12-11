use data/csrhub-kld-cstat-year-level-with-treatment-variables.dta, clear

/// PRETTIFY

***	Set panel
encode cusip, gen(cusip_n)
xtset cusip_n year, y

***	Order variables
order cusip year firm firm_kld conm
format %20s firm firm_kld conm

///	KEEP DATA MATCHED IN ALL THREE DATASETS
gen in_cstat=(conm!="")
gen in_csrhub=(firm!="")
gen in_kld=(firm_kld!="")

drop in_cstat_*

gen in_all=(in_cstat==1 & in_kld==1 & in_csrhub==1)

tab in_all
/*     in_all |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    164,729       92.60       92.60
          1 |     13,172        7.40      100.00
------------+-----------------------------------
      Total |    177,901      100.00
*/
keep if in_all==1

***	Histogram of years in data for each CUSIP
preserve

bysort cusip: gen n=_n
keep if n==1

histogram N, d freq addlabel xlab(0(1)8) ///
	ti("Years of observations for each CUSIP" "in data matched across all 3 datasets") ///
	xti("Years of observations in the 8-year panel") ///
	yti("CUSIPs")
	
restore
