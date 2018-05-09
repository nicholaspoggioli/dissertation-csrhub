***============================================
*	Title:	Clean media coverage data
*	Author: Nicholas Poggioli poggi005@umn.edu
*	Date:	April 25, 2018
***============================================
clear
set more off
version
cd


							***===========================***
							*								*
							*	STAKEHOLDER TYPE BY YEAR	*
							*								*
							***===========================***
global media data-Factiva-CSR-stakeholder-media-coverage

***	Environment
import delimited "$media\FACTIVA-csr-environment-stakeholder-media-hits-by-year.csv", clear

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
import delimited "$media\FACTIVA-csr-employee-stakeholder-media-hits-by-year.csv", clear

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
import delimited "$media\FACTIVA-csr-customer-stakeholder-media-hits-by-year.csv", clear

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
import delimited "$media\FACTIVA-csr-supplier-stakeholder-media-hits-by-year.csv", clear

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
import delimited "$media/FACTIVA-csr-only-by-year.csv", clear

drop in 1/4
drop in 41/54
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

label data "Number of hits for Factiva media search of stakeholders and CSR coverage"

save data-csrhub/factiva-stakeholder-type-by-year.dta, replace



***	EXPLORATORY GRAPHICS	*

use data-csrhub/factiva-stakeholder-type-by-year.dta, clear
							
***	Bar graphs

*	Stacked
graph bar (asis) supplier customer employee enviro, over(year, lab(angle(90))) stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment") order(4 3 2 1)) ///
	ti("Count of results from Factiva search of media coverage") ///
	note("Search term: 'corporate social responsibility' AND '<stakeholder name>'", size(vsmall)) ///
	scheme(plotplain)

graph bar (asis) supplier customer employee enviro csr, over(year, lab(angle(90))) stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment") lab(5 "csr only") order(5 4 3 2 1)) ///
	ti("Count of results from Factiva search of media coverage") ///
	note("Search terms:""(all except csr only): 'corporate social responsibility' AND '<stakeholder name>'""(csr only): 'corporate social responsibility' NOT 'environment*' NOT 'employee*' NOT 'customer*' NOT 'supplier*'", size(vsmall)) ///
	scheme(plotplain)

*	Percent
graph bar (asis) supplier customer employee enviro, over(year, lab(angle(90))) percentages stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment") order(4 3 2 1)) ///
	ti("Percent of results from Factiva search of media coverage") ///
	note("Search term: 'corporate social responsibility' AND '<stakeholder name>'", size(vsmall)) ///
	scheme(plotplain)

graph bar (asis) supplier customer employee enviro csr, over(year, lab(angle(90))) percentages stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment") lab(5 "csr only") order(5 4 3 2 1)) ///
	ti("Percent of results from Factiva search of media coverage") ///
	note("Search terms:""(all except csr only): 'corporate social responsibility' AND '<stakeholder name>'""(csr only): 'corporate social responsibility' NOT 'environment*' NOT 'employee*' NOT 'customer*' NOT 'supplier*'", size(vsmall)) ///
	scheme(plotplain)
	
	
*	Environment	
graph bar (asis) env, over(year, lab(angle(90))) blab(total) scale(.7) yti("")




							***===========================***
							*								*
							*		INDUSTRY VARIATION		*
							*								*
							***===========================***
/*	NOTE: 	Factiva only allows downloading the results for the top 100 of 141 industry
			categories, by number of hits. For each stakeholder group, the hits for
			industries 101 - 141 by number of hits is missing and cannot be assumed zero.
*/
global media data-Factiva-CSR-stakeholder-media-coverage

***	Customers
import delimited "$media\FACTIVA-csr-customer-stakeholder-media-hits-by-most-mentioned-industries.csv", clear

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
import delimited "$media\FACTIVA-csr-employee-stakeholder-media-hits-by-most-mentioned-industries.csv", clear

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
import delimited "$media\FACTIVA-csr-environment-stakeholder-media-hits-by-most-mentioned-industries.csv", clear

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
import delimited "$media\FACTIVA-csr-supplier-stakeholder-media-hits-by-most-mentioned-industries.csv", clear

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




















capt log close
