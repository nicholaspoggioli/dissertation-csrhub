***============================================
*	Title:	Clean stakeholder salience dataset
*	Author: Nicholas Poggioli poggi005@umn.edu
*	Date:	April 25, 2018
***============================================
clear
set more off
version
cd
							***===============***
							*					*
							*	LOAD RAW DATA	*
							*					*
							***===============***
***	Environment
import delimited FACTIVA-environmental-stakeholder-chart-media-hits-by-year.csv, clear

drop in 1/3
drop in 34/47
rename (v1 v2) (date env)
drop in 1

destring env, replace

compress

gen year = substr(date,23,4)
destring year, replace

drop date

order year

label var year "year"
label var env "number of environment articles"


***	
