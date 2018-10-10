/*	
Author: Nicholas Poggioli
Email:	poggi005@umn.edu
Stata version 15.1

OUTLINE
	Data creation
	Chapter 1:	Improved CSR Measurement Using Metaratings and the CSRHub Dataset
	Chapter 2:	Replicating and Extending Barnett & Salomon (2012)
	Chapter 3:	Identifying the Causal Effect of Social Performance on Financial Performance
	Chapter 4:	The Relationship between CSR Reputation and Engaging in Collective Action to Manage Resource Scarcity
	Appendix 1: Graphics and Figures
*/

					*******************************
					***		  DATA CREATION		***
					*******************************
///		KLD


///		COMPUSTAT


///		MERGE KLD AND COMPUSTAT


///		CSRHUB
					
///		MERGE KLD/CSTAT WITH CSRHUB

*use data/kld-cstat-bs2012.dta, clear
/*	firm:		firm name
	year:		year
	ticker:		ticker
*/

use data/csrhub-all.dta, clear
/*	firm:		firm name
	year:		year
	ticker:	ticker
*/

bysort ticker year: gen n=_n
keep if n==1

keep firm year ticker tic_csrhub in_csrhub

tempfile csrh
save `csrh'

merge 1:1 ticker year using data/kld-cstat-bs2012.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        85,835
        from master                    55,163  (_merge==1)
        from using                     30,672  (_merge==2)

    matched                            18,997  (_merge==3)
    -----------------------------------------
*/


					***=======================***
					*		  CHAPTER 1			*
					*	  THE CSRHUB DATASET	*
					***=======================***
					
					
					***=======================***
					*		  CHAPTER 2			*
					*	 REPLICATE B&S (2012)	*
					***=======================***

					
					***=======================***
					*		  CHAPTER 3			*
					*	INDUSTRY HETEROGENEITY	*
					***=======================***
/*	Outline
		1. Heterogeneity in KLD
			-	Recreate Table 6 Perrault & Quinn 2018
		2. Heterogeneity in CSTAT
		3. Heterogeneity in performance
*/

///		1. Heterogeneity in KLD
***	Load data
use data\kld-cstat-bs2012.dta, clear

set scheme plotplainblind

***	Merge SIC industry names
*	4-digit SIC codes
preserve
capt n import excel "D:\Dropbox\papers\active\dissertation-csrhub\project\data\sic-codes.xlsx", sheet("codes") firstrow allstring clear
capt n save data/sic-codes.dta
restore

merge m:1 sic using data/sic-codes.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        19,629
        from master                    19,557  (_merge==1)
        from using                         72  (_merge==2)

    matched                            30,112  (_merge==3)
    -----------------------------------------
*/
tab sic if _merge==1, miss
/*
    (CSTAT) |
   Standard |
   Industry |
Classificat |
   ion Code |      Freq.     Percent        Cum.
------------+-----------------------------------
            |     16,874       86.28       86.28
       1044 |         25        0.13       86.41
       2085 |         15        0.08       86.49
       4888 |         87        0.44       86.93
       5093 |         11        0.06       86.99
       6020 |      2,060       10.53       97.52
       6722 |         76        0.39       97.91
       6726 |         89        0.46       98.36
       6797 |        121        0.62       98.98
       7323 |         61        0.31       99.29
       7996 |         11        0.06       99.35
       8721 |         64        0.33       99.68
       9997 |         63        0.32      100.00
------------+-----------------------------------
      Total |     19,557      100.00
*/

*	Replace non-matched codes with codes from https://www.osha.gov/pls/imis/sicsearch.html?p_sic=1044&p_search=
replace industry="Silver Ores" if sic=="1044"
replace industry="Distilled and Blended Liquors" if sic=="2085"
*replace industry="" if sic=="4888"
replace industry="Scrap and Waste Materials" if sic=="5093"
*replace industry="" if sic=="6020"
replace industry="Management Investment Offices, Open-End" if sic=="6722"
replace industry="Unit Investment Trusts, Face-Amount Certificate Offices, and Closed-End Management Investment Offices" if sic=="6726"
*replace industry="" if sic=="6797"
replace industry="Credit Reporting Services" if sic=="7323"
replace industry="Amusement Parks" if sic=="7996"
replace industry="Accounting, Auditing, and Bookkeeping Services" if sic=="8721"
*replace industry="" if sic=="9997"

replace _merge=3 if _merge==1 & industry!=""

tab sic if _merge==1, miss
/*    (CSTAT) |
   Standard |
   Industry |
Classificat |
   ion Code |      Freq.     Percent        Cum.
------------+-----------------------------------
            |     16,874       87.86       87.86
       4888 |         87        0.45       88.32
       6020 |      2,060       10.73       99.04
       6797 |        121        0.63       99.67
       9997 |         63        0.33      100.00
------------+-----------------------------------
      Total |     19,205      100.00
*/

rename industry industry_sic4
label var industry_sic4 "4-digit SIC code industry description"

drop if _merge==2
drop _merge


*	2-digit SIC codes
gen sic2 = substr(sic,1,2)
tab sic2						/*	Perrault & Quinn 2018 uses 2-digit SIC codes	*/

preserve
capt n import excel "D:\Dropbox\papers\active\dissertation-csrhub\project\data\sic_2_digit_codes.xlsx", sheet("SIC 2 Digit Code") firstrow allstring clear
capt n save data/sic2.dta
restore

merge m:1 sic2 using data/sic2.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        16,889
        from master                    16,874  (_merge==1)
        from using                         15  (_merge==2)

    matched                            32,795  (_merge==3)
    -----------------------------------------
*/

tab sic2 if _merge==1, miss
/*
2-digit SIC |
   industry |
       code |
   (created |
   from sic |
  variable) |      Freq.     Percent        Cum.
------------+-----------------------------------
            |     16,874      100.00      100.00
------------+-----------------------------------
      Total |     16,874      100.00
*/

drop if _merge==2
drop _merge

label var sic2 "2-digit SIC industry code (created from sic variable)"
label var industry_sic2 "2-digit SIC code industry description"


***		Recreate Table 6 Perrault & Quinn 2018
sort sic2

preserve

drop if year<1998 | year > 2010

egen tag = tag(sic2 firm)
egen firm_N = total(tag), by(sic2)
drop tag
tabdisp sic2, c(firm_N)
label var firm_N "number of unique firm names in sic2"

foreach v in cgov com div emp env hum pro {
	by sic2: egen sic2_`v'_str = total(sum_`v'_str)
	by sic2: egen sic2_`v'_con = total(sum_`v'_con)
}

by sic2: gen sic2_N=_N
foreach v in cgov com div emp env hum pro {
	by sic2: egen sic2_`v'_str_st = total(sum_`v'_str)
	replace sic2_`v'_str_st = sic2_`v'_str_st / sic2_N
	by sic2: egen sic2_`v'_con_st = total(sum_`v'_con)
	replace sic2_`v'_con_st = sic2_`v'_con_st / sic2_N
}
label var sic2_N "number of observations in sic2 industry"

bysort sic2: gen n=_n
keep if n==1
drop n

keep sic2* sic2_N industry_sic2 firm_N
order sic2 industry_sic2 sic2_N firm_N *str *con

drop if sic2==""

capt n export excel using "figures\kld-sic2-sum-strengths-concerns.xls", firstrow(variables)
restore

***	Descriptive statistics

drop if sic2==""
egen tag = tag(sic2 firm)
egen firm_N = total(tag), by(sic2)
drop tag
tabdisp sic2, c(firm_N)
label var firm_N "number of unique firm names in sic2"

*	Summary
sum sum*str sum*con

*	Correlations
corr sum*str, means
corr sum*con, means

corr sum*, means

*	Means and standard deviations
foreach v in cgov com div emp env hum pro {
	bysort sic2: egen mean_`v'_str = mean(sum_`v'_str)
	bysort sic2: egen sd_`v'_str = sd(sum_`v'_str)
	bysort sic2: egen mean_`v'_con = mean(sum_`v'_con)
	bysort sic2: egen sd_`v'_con = sd(sum_`v'_con)
}

*	Product
tabstat sum_pro_str, by(sic2) stat(mean p50 min max N)


*	Corporate governance

*	Diversity

*	Community

*	Employees

*	Environment
tabstat sum_env_str, by(sic2) stat(mean p50 min max N)

tabstat sum_env_con, by(sic2) stat(mean p50 min max N)

*	Human rights













					
					***===========================***
					*		  	CHAPTER 4			*
					*	 CSP AND COLLECTIVE ACTION	*
					***===========================***

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





///		GRAPHICS
***	U-shaped graphic
clear

set obs 2000
gen x = rnormal()
gen y = x^2 + 4

twoway (qfit y x), xti("Social Performance", size(vlarge)) yti("Financial Performance", size(vlarge)) ytick(0(20)20) xtick(-5(10)5) ylab("") xlab("")



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


























/*	References

Perrault, E., & Quinn, M. A. (2018). What Have Firms Been Doing? Exploring What KLD Data Report About Firms’ Corporate Social Performance in the Period 2000-2010. Business and Society, 57(5), 890–928. https://doi.org/10.1177/0007650316648671






















*/
