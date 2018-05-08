***============================================
*	Title:	Clean stakeholder salience dataset
*	Author: Nicholas Poggioli poggi005@umn.edu
*	Date:	April 25, 2018
***============================================
clear
set more off
version
cd
							***=======================***
							*							*
							*	CREATE SINGLE DTA FILE	*
							*							*
							***=======================***
global media Factiva-CSR-stakeholder-media-coverage

***	Environment
import delimited "$media\FACTIVA-csr-environmental-stakeholder-media-hits-by-year.csv", clear

drop in 1/3
drop in 34/47
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
drop in 29/42
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

***	Save
compress

tsset year
tsfill, full

egen ch1 = rowtotal(supplier customer employee enviro), missing
gen missing_year = (ch1==.)
drop ch1
label var missing_year "=1 if no articles for any group in year"

foreach v in supplier customer employee enviro {
	replace `v' = 0 if `v' == .
}

label data "Number of hits for Factiva media search of stakeholders and CSR coverage"

save data-csrhub/factiva-stakeholder-coverage.dta, replace


							***=======================***
							*							*
							*	EXPLORATORY GRAPHICS	*
							*							*
							***=======================***
***	Bar graphs

*	Stacked
graph bar (asis) supplier customer employee enviro, over(year, lab(angle(90))) stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment")) ///
	ti("Articles returned from Factiva search") ///
	note("Search term: 'corporate social responsibility' AND '<stakeholder name>'", size(vsmall)) ///
	scheme(plotplainblind)

graph bar (asis) supplier customer employee enviro, over(year) stack scheme(plotplainblind) ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment")) 
	
	
	
graph bar (asis) env, over(year, lab(angle(90))) blab(total) scale(.7) yti("")
