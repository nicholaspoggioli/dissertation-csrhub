********************************************************************************
*Title: Dissertation graphs and figures
*Created by: Nicholas Poggioli (poggi005@umn.edu)
*Created on: October 2018
*Purpose: Create graphs and figures
********************************************************************************


					***===========================***
					*	 	CSRHub and KLD			*
					***===========================***	
use data/mergefile-kld-cstat-csrhub.dta, clear

*** Scatterplots
graph matrix net_kld net_kld_str net_kld_con over_rtg, half scheme(plotplain) m(o) msize(small)


*** Binscatters
binscatter over_rtg net_kld, nquantiles(31) xlab(-20(5)20) ylab(0(5)100) scheme(plotplainblind)
binscatter over_rtg net_kld, nquantiles(31) xlab(-20(5)20) ylab(0(5)100) scheme(plotplainblind) median

*** Box plots
graph box over_rtg, over(net_kld) scheme(plotplainblind)

*** Violin plots
capt n ssc install vioplot

vioplot over_rtg, over(net_kld)

					***===========================***
					*	CHAPTER 2: B&S REPLICATION	*
					***===========================***
///	LOAD DATA
use data/csrhub-kld-cstat-bs2012.dta, clear

///	CSRHUB - KLD RELATIONSHIP

***	Binscatters
binscatter over_rtg net_kld, nquantiles(30) ///
	xlab(-20(5)20) ylab(0(10)100, angle(0)) ///
	scheme(s1mono) ///
	nodraw ///
	ti("MEAN CSRHub Overall Rating") ///
	xti("Net KLD Score") ///
	saving(figures\overnetmean.gph, replace)

binscatter over_rtg net_kld, nquantiles(30) ///
	xlab(-20(5)20) ylab(0(10)100, angle(0)) ///
	scheme(s1mono) ///
	nodraw ///
	ti("MEDIAN CSRHub Overall Rating") ///
	xti("Net KLD Score") ///
	saving(figures\overnetmedian.gph, replace)

graph combine overnetmean.gph overnetmedian.gph, col(1)


					***===================================***
					*	CHAPTER 3: MEDIATION ANALYSIS		*
					***===================================***
use data/csrhub-kld-cstat-matched-on-cusip.dta, clear

graph matrix net_kld_str net_kld_con over_rtg revt ni at tobinq roa


					***===================================***
					*	CHAPTER 4: INDUSTRY HETEROGENEITY	*
					***===================================***
///	KLD		

***	Histograms
histogram net_kld, d ///
	percent ///
	by(division_sic2, ti("Percentage of Observations by SIC Division, 1991-2015, `v'") note("")) ///
	xline(0) ///
	xti("")
	graph export "figures\industry-variation\histogram-`v'-by-sic-division-percent.tif", as(tif) replace

foreach v in net_kld net_kld_str net_kld_con {
	qui histogram `v', d ///
		percent ///
		by(division_sic2, ti("Percentage of Observations by SIC Division, 1991-2015, `v'") note("")) ///
		xline(0) ///
		xti("")
	graph export "figures\industry-variation\histogram-`v'-by-sic-division-percent.tif", as(tif) replace

	qui histogram `v', d ///
		freq ///
		by(division_sic2, ti("Frequency of Observations by SIC Division, 1991-2015, `v'") note("")) ///
		xline(0) ///
		xti("")
	graph export "figures\industry-variation\histogram-`v'-by-sic-division-freq.tif", as(tif) replace
}

///	KLD by Industry

***	Binscatters
replace net_kld_con=net_kld_con*-1
foreach v in net_kld net_kld_str net_kld_con {
	binscatter ni `v', by(division_sic2) line(qfit) legend(pos(6) cols(3) size(vsmall))
	graph export "figures\industry-variation\binscatter-ni-by-`v'.tif", as(tif) replace
}

foreach v in cgov_agg com_agg div_agg emp_agg env_agg hum_agg pro_agg alc_agg gam_agg mil_agg nuc_agg tob_agg {
	binscatter ni `v', by(division_sic2) line(qfit) legend(pos(6) cols(3) size(vsmall))
	graph export "figures\industry-variation\binscatter-ni-by-`v'.tif", as(tif) replace
}

graph hbar (count), over(division_sic2)

tab sic1_f

*	Relationship shape by SIC divison
binscatter roa net_kld, by(division_sic2) line(qfit) scheme(s1mono) legend(tstyle(size(vsmall)))
binscatter roa net_kld_str, by(division_sic2) line(qfit) scheme(s1mono) legend(tstyle(size(vsmall)))
binscatter roa net_kld_con, by(division_sic2) line(qfit) scheme(s1mono) legend(tstyle(size(vsmall)))

binscatter ni net_kld, by(division_sic2) line(qfit) scheme(s1mono) legend(tstyle(size(vsmall)))



///	MARGINAL EFFECTS PLOTS FOR REGRESSIONS

reg roa net_kld_str net_kld_con sic1num
qui margins, at(net_kld_str=(0 2 4 6 8 10 12 14 16 18 20 22) sic1num=(4 5 7 8 9))
marginsplot

qui margins, at(net_kld_con=(0 2 4 6 8 10 12 14 16 18) sic1num=(4 5 7 8 9))
marginsplot, scheme(s1mono) recastci(rarea)



					***===========================***
					*		  	APPENDIX 1			*
					*	 FACTIVA STAKEHOLDER DATA	*
					***===========================***				
clear
set more off
version

*************************
*	ALL MEDIA INCLUDED IN FACTIVA SEARCH
*	(see below for subset of media sources data)

///		STAKEHOLDER TYPE BY YEAR	
***	Environment
import delimited "data/data-factiva/FACTIVA-csr-environment-stakeholder-media-hits-by-year.csv", clear

drop in 1/3
drop in 38/51
rename (v1 v2) (date enviro)
drop in 1

destring enviro, replace

gen year = substr(date,23,4)
destring year, replace

drop date
order year

compress

label var year "year"
label var enviro "count Factiva results with 'corporate social responsibility' AND 'environment*'"

tempfile d1
save `d1'


***	Employee
import delimited "data/data-factiva/FACTIVA-csr-employee-stakeholder-media-hits-by-year.csv", clear

drop in 1/3
drop in 34/47
rename (v1 v2) (date employee)
drop in 1

destring employee, replace

gen year = substr(date,23,4)
destring year, replace

drop date
order year

compress

label var year "year"
label var employee "count Factiva results with 'corporate social responsibility' AND 'employee*'"

merge 1:1 year using `d1', nogen
tempfile d2
save `d2'


***	Customer
import delimited "data/data-factiva/FACTIVA-csr-customer-stakeholder-media-hits-by-year.csv", clear

drop in 1/4
drop in 34/47
rename (v1 v2) (date customer)

destring customer, replace

gen year = substr(date,23,4)
destring year, replace

drop date
order year

compress

label var year "year"
label var customer "count Factiva results with 'corporate social responsibility' AND 'customer*'"

merge 1:1 year using `d2', nogen
tempfile d3
save `d3'

***	Supplier
import delimited "data/data-factiva/FACTIVA-csr-supplier-stakeholder-media-hits-by-year.csv", clear

drop in 1/4
drop in 33/46
rename (v1 v2) (date supplier)

destring supplier, replace

gen year = substr(date,23,4)
destring year, replace

drop date
order year

compress

label var year "year"
label var supplier "count Factiva results with 'corporate social responsibility' AND 'supplier*'"

merge 1:1 year using `d3', nogen
tempfile d4
save `d4'

***	All CSR articles
import delimited "data/data-factiva/FACTIVA-csr-only-by-year.csv", clear

drop in 1/4
drop in 41/55
rename (v1 v2) (date csr)

destring csr, replace

gen year = substr(date,23,4)
destring year, replace

drop date
order year

compress

label var year "year"
label var csr "count Factiva results with 'corporate social responsibility'"

merge 1:1 year using `d4', nogen

***	Save
tsset year
tsfill, full

mark nomiss
markout nomiss csr supplier customer employee enviro
label var nomiss "=1 if no missing values of csr supplier customer employee enviro"

foreach v in supplier customer employee enviro {
	replace `v' = 0 if `v' == .
}

label data "Number of hits for Factiva search of all media for stakeholders and CSR coverage"

save data-csrhub/factiva-stakeholder-type-by-year-media-all.dta, replace



///		INDUSTRY VARIATION
/*	NOTE: 	Factiva only allows downloading the results for the top 100 of 141 industry
			categories, by number of hits. For each stakeholder group, the hits for
			industries 101 - 141 by number of hits is missing and cannot be assumed zero.
*/
***	Customers
import delimited "data/data-factiva/FACTIVA-csr-customer-stakeholder-media-hits-by-most-mentioned-industries.csv", clear

drop in 1/2
drop in 102/114
rename (v1 v2) (industry customer)
drop in 1

destring customer, replace

compress

label var industry "Factiva industry"
label var customer "Factiva documents referring to CSR and customers"

tempfile d1
save `d1'


***	Employees
import delimited "data/data-factiva/FACTIVA-csr-employee-stakeholder-media-hits-by-most-mentioned-industries.csv", clear

drop in 1/2
drop in 102/114
rename (v1 v2) (industry employee)
drop in 1

destring employee, replace

compress

label var industry "Factiva industry"
label var employee "Factiva documents referring to CSR and employees"

merge 1:1 industry using `d1', nogen
tempfile d2
save `d2'


***	Environment
import delimited "data/data-factiva/FACTIVA-csr-environment-stakeholder-media-hits-by-most-mentioned-industries.csv", clear

drop in 1/2
drop in 102/114
rename (v1 v2) (industry environment)
drop in 1

destring environment, replace

compress

label var industry "Factiva industry"
label var environment "Factiva documents referring to CSR and environment"

merge 1:1 industry using `d2', nogen
tempfile d3
save `d3'


***	Supplier
import delimited "data/data-factiva/FACTIVA-csr-supplier-stakeholder-media-hits-by-most-mentioned-industries.csv", clear

drop in 1/2
drop in 102/114
rename (v1 v2) (industry supplier)
drop in 1

destring supplier, replace

compress

label var industry "Factiva industry"
label var supplier "Factiva documents referring to CSR and supplier"

merge 1:1 industry using `d3', nogen


***	Generate
mark all100
markout all100 supplier environment employee customer
label var all100 "=1 if values for all four stakeholder groups"

egen total=rowtotal(supplier environment employee customer) if all100==1
label var total "total count of hits for all four stakeholder groups"

gen pct_sup=supplier/total if all100==1
gen pct_env=environment/total if all100==1
gen pct_emp=employee/total if all100==1
gen pct_cus=customer/total if all100==1

label var pct_sup "percent total hits from suppliers"
label var pct_env "percent total hits from environment"
label var pct_emp "percent total hits from employees"
label var pct_cus "percent total hits from customers"

gen sup100=(supplier!=.)
gen env100=(environment!=.)
gen emp100=(employee!=.)
gen cus100=(customer!=.)

label var sup100 "=1 if a top-100 industry for supplier"
label var env100 "=1 if a top-100 industry for environment"
label var emp100 "=1 if a top-100 industry for employee"
label var cus100 "=1 if a top-100 industry for customer"

egen ind_rank = rowtotal(sup100 env100 emp100 cus100)
label var ind_rank "number of stakeholder groups for which industry is top 100"

***	Save
compress
sort industry

label data "Factiva results (to 2017) for top 100 industries by stakeholder (made May 2018)"
save data-csrhub/DATA-factiva-stakeholder-type-by-industry.dta, replace


***	EXPLORATORY GRAPHICS	
use data-csrhub/DATA-factiva-stakeholder-type-by-industry.dta, clear

*	Stacked bar
graph hbar (asis) pct_sup pct_env pct_emp pct_cus if all100==1, over(industry) scheme(plotplain)

*	kdensity 
tw kdensity pct_sup || kdensity pct_env || kdensity pct_emp || kdensity pct_cus, scheme(plotplain)





/*************************
*	SUBSET OF MEDIA INCLUDED IN FACTIVA SEARCH
*	(see below for subset of media sources data)

The New York Times - All sources Or 
The Wall Street Journal - All sources Or 
Washington Post - All sources Or 
USA Today - All sources Or 
Chicago Tribune - All sources Or 
Financial Times (Available through Third Party Subscription Services) - All sources Or 
Los Angeles Times - All sources
*/

clear all



///	STAKEHOLDER TYPE BY YEAR
***	Environment
import delimited "data/data-factiva/subset-of-sources\FACTIVA-SUBSET-csr-environment-stakeholder-media-hits-by-year.csv", clear

drop in 1/3
drop in 37/50
rename (v1 v2) (date enviro)
drop in 1

destring enviro, replace

gen year = substr(date,23,4)
destring year, replace

drop date
order year

compress

label var year "year"
label var enviro "FACTIVA SUBSET media hits for environment"

tempfile d1
save `d1'


***	Employee
import delimited "data/data-factiva/subset-of-sources\FACTIVA-SUBSET-csr-employee-stakeholder-media-hits-by-year.csv", clear

drop in 1/3
drop in 38/51
compress
rename (v1 v2) (date employee)
drop in 1

destring employee, replace

gen year = substr(date,23,4)
destring year, replace

drop date
order year

label var year "year"
label var employee "FACTIVA SUBSET media hits for employee"

merge 1:1 year using `d1', nogen
tempfile d2
save `d2'


***	Customer
import delimited "data/data-factiva/subset-of-sources\FACTIVA-SUBSET-csr-customer-stakeholder-media-hits-by-year.csv", clear

drop in 1/3
drop in 30/43
compress
rename (v1 v2) (date customer)
drop in 1

destring customer, replace

gen year = substr(date,23,4)
destring year, replace

drop date
order year

compress

label var year "year"
label var customer "FACTIVA SUBSET media hits for customer"

merge 1:1 year using `d2', nogen
tempfile d3
save `d3'

***	Supplier
import delimited "data/data-factiva/subset-of-sources\FACTIVA-SUBSET-csr-supplier-stakeholder-media-hits-by-year.csv", clear

drop in 1/3
drop in 29/43
rename (v1 v2) (date supplier)
compress
drop in 1

destring supplier, replace

gen year = substr(date,23,4)
destring year, replace

drop date
order year

compress

label var year "year"
label var supplier "FACTIVA SUBSET media hits for supplier"

merge 1:1 year using `d3', nogen
tempfile d4
save `d4'

***	All CSR articles
import delimited "data/data-factiva/subset-of-sources/FACTIVA-SUBSET-csr-only-by-year.csv", clear

drop in 1/3
drop in 39/53
rename (v1 v2) (date csr)
drop in 1

destring csr, replace

gen year = substr(date,23,4)
destring year, replace

drop date
order year

compress

label var year "year"
label var csr "FACTIVA SUBSET media hits corporate social responsbility minus stakeholder terms"

merge 1:1 year using `d4', nogen

***	Save
tsset year
tsfill, full

mark nomiss
markout nomiss csr supplier customer employee enviro
label var nomiss "=1 if no missing values of csr supplier customer employee enviro"

foreach v in supplier customer employee enviro {
	replace `v' = 0 if `v' == .
}

*	Label and save
label data "Hits for Factiva search of media subset for stakeholders and CSR coverage"
save data-csrhub/factiva-stakeholder-type-by-year-media-subset.dta, replace

***		GRAPHICS
tw kdensity supplier || kdensity customer || kdensity employee || kdensity enviro, scheme(plotplain)

graph bar (asis) supplier customer employee enviro, over(year, label(angle(90))) scheme(plotplainblind)





		

					***===========================***
					*		  	APPENDIX 2			*
					*	 GRAPHICS AND FIGURES		*
					***===========================***
///		KLD data

***	Load data
use data-csrhub\kld-cstat-bs2012.dta, clear

set scheme plotplainblind

***	Distribution
*stripplot net_kld, over(year) height(5) stack center vertical m(oh) mc(black) xlab(, ang(v))

*graph tw scatter net_kld year, jitter(.1) m(oh) mc(black) xlab(1990(1)2016, angle(v))

binscatter net_kld year, ylab(-2(1)2) col(black) discrete
binscatter net_kld year, ylab(-2(1)2) median discrete

*	KLD strengths
binscatter net_kld_str year, ylab(0(1)4) discrete xlab(1990(2)2016)
binscatter net_kld_str year, ylab(0(1)4) line(qfit) discrete xlab(1990(2)2016)
binscatter net_kld_str year, ylab(0(1)4) median discrete

*	KLD concerns
replace net_kld_con = net_kld_con*-1
binscatter net_kld_con year, ylab(-4(1)0) discrete xlab(1990(2)2016)
binscatter net_kld_con year, ylab(-4(1)0) line(qfit) discrete xlab(1990(2)2016)
binscatter net_kld_con year, ylab(-4(1)0) median discrete

*binscatter net_kld year, rd(2011)
*binscatter net_kld year, median rd(2011)

graph box net_kld, over(year, label(angle(vertical))) ti("Net KLD ratings, 1991 - 2015", size(large)) yti("")

graph bar (count) firm_n, over(year, lab(angle(90)))

*	Strengths
scatter net_kld_str year, xlab(, angle(v)) m(oh) ti("Sum KLD Strengths, 1991 - 2015", size(large)) yti("") jitter(1)

gen net_con=net_kld_con*-1
scatter net_con year, xlab(, angle(v)) m(oh) ti("Sum KLD Concerns, 1991 - 2015", size(large)) yti("") jitter(1)

graph box net_kld_con, over(year, label(angle(vertical))) ti("Sum KLD Concerns, 1991 - 2015", size(large)) yti("")



*	Binscatter
replace sum_env_con=sum_env_con*-1

binscatter sum_env_con sum_env_str, reportreg n(8) ylab(-6(2)0) xlab(0(2)6)
binscatter sum_env_con sum_env_str, reportreg n(8) line(qfit) ylab(-6(2)0) xlab(0(2)6)

binscatter sum_env_con sum_env_str, reportreg absorb(firm_n)


///		COMPUSTAT
***	Firm performance distribution

*ROA (net income / assets)
gen roaout=roa
replace roaout=. if roa>100
replace roaout=. if roa<-50

stripplot roaout, over(year) height(5) stack center vertical m(oh) mc(black) xlab(, ang(v))

scatter roaout year, jitter(1) m(oh) mc(black)
binscatter roaout year

scatter ni at
binscatter ni at, n(100)


graph box roaout, over(year, label(angle(vertical)))



*Assets
scatter at year, jitter(1) m(oh) mc(black) xlab(1990(1)2016, angle(v))
binscatter at year

graph box at, over(year, label(angle(vertical)))

*Net income
stripplot ni, over(year) stack center vertical m(oh) mc(black) xlab(, ang(v))

scatter ni year, jitter(1) m(oh) mc(black) ti("Net income, 1991 - 2015", size(large)) yti("") xti("") xlab(1990(1)2016,angle(v))
binscatter ni year

graph box ni, over(year, label(angle(vertical))) ti("Net income, 1991 - 2015") yti("")


///		CSRHUB
***	Load data
use data/csrhub-all.dta, clear

*	Overall rating by year
graph box over_rtg, over(ym, label(angle(vertical))) ti("CSRHub overall rating, 2008 - 2017") yti("")




///	U-shaped graphic

*	U-shaped
set scheme plotplainblind

graph set window fontface "Arial"

clear

set obs 2000
gen x = rnormal()
gen y = 3*x^2 + 4
gen sic=(x>0)
label define hilo 1 "High SIC" 0 "Low SIC"
label values sic hilo

drop if y>40

tw qfit y x if sic==0, xti("Social influence capacity") ///
	yti("Financial Performance of Responsibility") ///
	ytick(0(40)40) ///
	ylab(0(40)40 0 "( - )" 40 "( + )") ///
	xtick(-5(10)5) ///
	xlab(-5(5)5 -5 "( - )" 5 "( + )")

tw qfit y x if sic==1, xti("Stakeholder influence capacity", size(vlarge)) ///
	yti("Financial Performance of Responsibility", size(vlarge)) ///
	ytick(0(40)40) ///
	ylab(0(40)40 0 "( - )" 40 "( + )") ///
	xtick(-5(10)5) ///
	xlab(-5(5)5 -5 "( - )" 5 "( + )")

twoway (qfit y x), xti("Stakeholder influence capacity") ///
	yti("Financial Performance of Responsibility") ///
	ytick(0(40)40) ///
	ylab(0(40)40 0 "( - )" 40 "( + )") ///
	xtick(-5(10)5) ///
	xlab(-5(5)5 -5 "( - )" 5 "( + )") ///
	by(sic, note("") noiytick noixtick)

twoway (qfit y x), ///
	xti("Stakeholder influence capacity") ///
	yti("Financial Performance of Responsibility") ///
	ytick(0(40)40) ///
	ylab(0(40)40 0 "( - )" 40 "( + )") ///
	xtick(-5(10)5) ///
	xlab(-5(5)5 -5 "( - )" 5 "( + )")


graph set window fontface default










///		FACTIVA MEDIA SEARCH VIZ

use data-csrhub/factiva-stakeholder-type-by-year-media-all.dta, clear
							
***	Bar graphs

*	Stacked
graph bar (asis) supplier customer employee enviro, over(year, lab(angle(90))) stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment") order(4 3 2 1)) ///
	ti("Count of results from Factiva search of all media coverage") ///
	note("Search term: 'corporate social responsibility' AND '<stakeholder name>'", size(vsmall)) ///
	scheme(plotplain)

graph bar (asis) supplier customer employee enviro csr, over(year, lab(angle(90))) stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment") lab(5 "csr only") order(5 4 3 2 1)) ///
	ti("Count of results from Factiva search of all media coverage") ///
	note("Search terms:""(all except csr only): 'corporate social responsibility' AND '<stakeholder name>'""(csr only): 'corporate social responsibility' NOT 'environment*' NOT 'employee*' NOT 'customer*' NOT 'supplier*'", size(vsmall)) ///
	scheme(plotplain)

*	Percent
graph bar (asis) supplier customer employee enviro, over(year, lab(angle(90))) percentages stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment") order(4 3 2 1)) ///
	ti("Percent of results from Factiva search of all media coverage") ///
	note("Search term: 'corporate social responsibility' AND '<stakeholder name>'", size(vsmall)) ///
	scheme(plotplain)

graph bar (asis) supplier customer employee enviro csr, over(year, lab(angle(90))) percentages stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment") lab(5 "csr only") order(5 4 3 2 1)) ///
	ti("Percent of results from Factiva search of all media coverage") ///
	note("Search terms:""(all except csr only): 'corporate social responsibility' AND '<stakeholder name>'""(csr only): 'corporate social responsibility' NOT 'environment*' NOT 'employee*' NOT 'customer*' NOT 'supplier*'", size(vsmall)) ///
	scheme(plotplain)
	
	
*	Environment	
graph bar (asis) env, over(year, lab(angle(90))) blab(total) scale(.7) yti("")























