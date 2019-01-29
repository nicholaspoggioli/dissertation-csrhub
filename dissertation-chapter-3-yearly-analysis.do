///	LOG
capt n log close
log using code/logs/20190139-yearly-analysis.txt, text replace

///	LOAD DATA
use data/csrhub-kld-cstat-year-level-with-treatment-variables.dta, clear

est clear

/// SET PANEL
encode cusip, gen(cusip_n)
xtset cusip_n year, y

///	GENERATE YEAR-ON-YEAR REVENUE CHANGE
gen revt_yoy = revt - l.revt
label var revt_yoy "Year-on-year change in revenue (revt - previous year revt)"

///	KEEP VARIABLES IN REGRESSION MODELS TO REDUCE FILE SIZE
keep cusip cusip_n year revt revt_yoy dltt at xad xrd emp age ///
	over_rtg *rtg_lym sic tobinq

	
						***===========================***
						*	FIXED EFFECTS REGRESSION	*	
						***===========================***	
***===========================***
*	REVENUE CHANGE = F (CSRHUB) 	*
***===========================***
///	CONTROL VARIABLE MODELS

***	DV: Revenue (Level)
*mark mark3
*markout mark3 revt over_rtg dltt at xad xrd emp year
qui xtreg revt_yoy over_rtg, fe cluster(cusip_n)										
est store revt_yoymod1
estadd local yearFE "No", replace
qui xtreg revt_yoy over_rtg i.year, fe cluster(cusip_n)									
est store revt_yoymod2
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt i.year, fe cluster(cusip_n)							
est store revt_yoymod3
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt at i.year, fe cluster(cusip_n)							
est store revt_yoymod4
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt at emp i.year, fe cluster(cusip_n)						
est store revt_yoymod5
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt at emp tobinq i.year, fe cluster(cusip_n)					
est store revt_yoymod6
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt at emp tobinq age i.year, fe cluster(cusip_n)				
est store revt_yoymod7
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt at emp tobinq age xad i.year, fe cluster(cusip_n)				
est store revt_yoymod8
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt at emp tobinq age xad xrd i.year, fe cluster(cusip_n)				
est store revt_yoymod9
estadd local yearFE "Yes", replace


*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

qui xtreg revt_yoy over_rtg dltt at emp tobinq age xad xrd i.year, fe cluster(cusip_n)				
est store revt_yoymod10
estadd local yearFE "Yes", replace
restore

esttab revt_yoymod*, ///
	b se s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC")) ///
	keep(over_rtg dltt at xad xrd tobinq emp age)

	

	
	
***===============================***
*	REVENUE CHANGE = F (CSRHUB) 	*
***===============================***	
/// DV: Revenue (1-year change)
local dv revt_yoy
local iv over_rtg 
local controls "dltt at age emp tobinq xad xrd"

qui xtreg F.`dv' `iv', fe cluster(cusip_n)
est store over_rtgmod0
estadd local yearFE "No", replace

qui xtreg F.`dv' `iv' i.year, fe cluster(cusip_n)
est store over_rtgmod1
estadd local yearFE "Yes", replace

local vars ""
local counter 2
foreach control of local controls {
	*	Regression
	qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(cusip_n)
		
	*	Store results
	est store over_rtgmod`counter'
	estadd local yearFE "Yes", replace
	
	*	Increment
	local vars "`vars' `control'"
	local counter = `counter' + 1
}

*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

qui xtreg F.revt_yoy over_rtg dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)	
est store over_rtgas1
estadd local yearFE "Yes", replace
restore 

*	Assume missing xad and xrd are 0, interact over_rtg and revt, 
*	all independent variables lagged
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

qui xtreg F.revt_yoy c.over_rtg##c.revt dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
est store over_rtgint1
estadd local yearFE "Yes", replace
restore

*	Assume missing xad and xrd are 0, interact over_rtg and revt, 
*	all independent variables lagged, and standardized revt and over_rtg
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

egen Sover_rtg = std(over_rtg)
egen Srevt = std(revt)

qui xtreg F.revt_yoy c.Sover_rtg##c.Srevt dltt at emp tobinq xad xrd age i.year, fe cluster(cusip_n)
est store over_rtgint2
estadd local yearFE "Yes", replace
restore

esttab over_rtgmod* over_rtgas1, ///
	keep(over_rtg dltt at age emp tobinq xad xrd) ///
	order(over_rtg dltt at age emp tobinq xad xrd) ///
	s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC"))
	
esttab over_rtgint1 over_rtgint2, ///
	keep(over_rtg revt c.over_rtg* Sover_rtg Srevt c.Sover_rtg* dltt at age emp tobinq xad xrd) ///
	order(over_rtg revt c.over_rtg* Sover_rtg Srevt c.Sover_rtg* dltt at age emp tobinq xad xrd) ///
	r2 ar2 aic


	

/*
///	REVENUE = F (CSRHUB CATEGORIES)
		CSRHub CATEGORIES and subcategories:
			-	COMMUNITY
				*	Community development and philanthropy
				*	Product
				*	Human rights and supply chain
			-	EMPLOYEES
				*	Compensation and benefits
				*	Diversity and labor rights
				*	Training health and safety
			-	ENVIRONMENT
				*	Energy and climate change
				*	Environmental policy and reporting
				*	Resource management
			-	GOVERNANCE
				*	Board
				*	Leadership ethics
				*	Transparency and reporting
*/

///	COMMUNITY

local dv revt_yoy
local iv cmty_rtg_lym
local controls "dltt at age emp tobinq xad xrd"

qui xtreg F.`dv' `iv', fe cluster(cusip_n)
est store cmtymod0
estadd local yearFE "No", replace

qui xtreg F.`dv' `iv' i.year, fe cluster(cusip_n)
est store cmtymod1
estadd local yearFE "Yes", replace

local vars ""
local counter 2
foreach control of local controls {
	*	Regression
	qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(cusip_n)
		
	*	Store results
	est store cmtymod`counter'
	estadd local yearFE "Yes", replace
	
	*	Increment
	local vars "`vars' `control'"
	local counter = `counter' + 1
}

esttab cmty*, ///
	keep(cmty_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(cmty_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC"))

*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & `iv'!=.												/*	assumption	*/
replace xrd=0 if xrd==. & `iv'!=.												/*	assumption	*/

qui xtreg F.`dv' `iv' `controls' i.year, fe cluster(cusip_n)
est store cmtyas1
estadd local yearFE "Yes", replace
restore 

*	Table
esttab cmtymod* cmtyas1, ///
	keep(cmty_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(cmty_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC"))


	
	
	
///	EMPLOYEES

local dv revt_yoy
local iv emp_rtg_lym
local controls "dltt at age emp tobinq xad xrd"

qui xtreg F.`dv' `iv', fe cluster(cusip_n)
est store empmod0
estadd local yearFE "No", replace

qui xtreg F.`dv' `iv' i.year, fe cluster(cusip_n)
est store empmod1
estadd local yearFE "Yes", replace

local vars ""
local counter 2
foreach control of local controls {
	*	Regression
	qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(cusip_n)
		
	*	Store results
	est store empmod`counter'
	estadd local yearFE "Yes", replace
	
	*	Increment
	local vars "`vars' `control'"
	local counter = `counter' + 1
}

esttab emp*, ///
	keep(emp_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(emp_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC"))

*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & `iv'!=.												/*	assumption	*/
replace xrd=0 if xrd==. & `iv'!=.												/*	assumption	*/

qui xtreg F.`dv' `iv' `controls' i.year, fe cluster(cusip_n)
est store empas1
estadd local yearFE "Yes", replace
restore 

*	Table
esttab empmod* empas1, ///
	keep(emp_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(emp_rtg_lym  dltt at age emp tobinq xad xrd) ///
	s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC"))


///	ENVIRONMENT

local dv revt_yoy
local iv enviro_rtg_lym
local controls "dltt at age emp tobinq xad xrd"

qui xtreg F.`dv' `iv', fe cluster(cusip_n)
est store enviromod0
estadd local yearFE "No", replace
estadd local firmFE "Yes", replace

qui xtreg F.`dv' `iv' i.year, fe cluster(cusip_n)
est store enviromod1
estadd local yearFE "Yes", replace

local vars ""
local counter 2
foreach control of local controls {
	*	Regression
	qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(cusip_n)
		
	*	Store results
	est store enviromod`counter'
	estadd local yearFE "Yes", replace
	estadd local firmFE "Yes", replace
	
	*	Increment
	local vars "`vars' `control'"
	local counter = `counter' + 1
}

esttab enviro*, ///
	keep(enviro_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(enviro_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(yearFE firmFE N N_g r2 aic, label("Year FEs" "Firm FEs" "Observations" "Firms" "R^2" "AIC"))

*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & `iv'!=.												/*	assumption	*/
replace xrd=0 if xrd==. & `iv'!=.												/*	assumption	*/

qui xtreg F.`dv' `iv' `controls' i.year, fe cluster(cusip_n)
est store enviroas1
estadd local yearFE "Yes", replace
estadd local firmFE "Yes", replace
restore 

*	Table
esttab enviromod* enviroas1, ///
	keep(enviro_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(enviro_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(yearFE firmFE N N_g r2 aic, label("Year FEs" "Firm FEs" "Observations" "Firms" "R^2" "AIC"))


	
///	GOVERNANCE

local dv revt_yoy
local iv gov_rtg_lym
local controls "dltt at age emp tobinq xad xrd"

qui xtreg F.`dv' `iv', fe cluster(cusip_n)
est store govmod0
estadd local yearFE "No", replace
estadd local firmFE "Yes", replace

qui xtreg F.`dv' `iv' i.year, fe cluster(cusip_n)
est store govmod1
estadd local yearFE "Yes", replace

local vars ""
local counter 2
foreach control of local controls {
	*	Regression
	qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(cusip_n)
		
	*	Store results
	est store govmod`counter'
	estadd local yearFE "Yes", replace
	estadd local firmFE "Yes", replace
	
	*	Increment
	local vars "`vars' `control'"
	local counter = `counter' + 1
}

esttab govmod*, ///
	keep(gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(yearFE firmFE N N_g r2 aic, label("Year FEs" "Firm FEs" "Observations" "Firms" "R^2" "AIC"))

*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & `iv'!=.												/*	assumption	*/
replace xrd=0 if xrd==. & `iv'!=.												/*	assumption	*/

qui xtreg F.`dv' `iv' `controls' i.year, fe cluster(cusip_n)
est store govas1
estadd local yearFE "Yes", replace
estadd local firmFE "Yes", replace
restore 

*	Table
esttab govmod* govas1, ///
	keep(gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(yearFE firmFE N N_g r2 aic, label("Year FEs" "Firm FEs" "Observations" "Firms" "R^2" "AIC"))



	
	
///	ALL CATEGORIES
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym , fe cluster(cusip_n)
est store m1
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym i.year, fe cluster(cusip_n)
est store m2
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt i.year, fe cluster(cusip_n)
est store m3
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at i.year, fe cluster(cusip_n)
est store m4
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age i.year, fe cluster(cusip_n)
est store m5
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp i.year, fe cluster(cusip_n)
est store m6
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad i.year, fe cluster(cusip_n)
est store m7
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
est store m8


***	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==.															/*	assumption	*/
replace xrd=0 if xrd==.															/*	assumption	*/

qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
est store m9
restore 

***	Table
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9, ///
	keep(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	r2 ar2 aic

***	Full model comparisons of CATEGORY-level CSRHub
esttab m8 m9 cmtymod7 cmtyas1 empmod7 empas1 enviromod7 enviroas1 govmod7 govas1, ///
	keep(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(N N_g r2_a ar2 aic)
	
esttab m8 cmtymod7 empmod7 enviromod7 govmod7 m9 cmtyas1 empas1 enviroas1 govas1, ///
	keep(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(N N_g r2_a ar2 aic)
	

	
	
	
	
/*	
///	REVENUE = F (CSRHUB subcategories)
		CSRHub CATEGORIES and subcategories:
			-	COMMUNITY
				*	Community development and philanthropy
				*	Product
				*	Human rights and supply chain
			-	EMPLOYEES
				*	Compensation and benefits
				*	Diversity and labor rights
				*	Training health and safety
			-	ENVIRONMENT
				*	Energy and climate change
				*	Environmental policy and reporting
				*	Resource management
			-	GOVERNANCE
				*	Board
				*	Leadership ethics
				*	Transparency and reporting

 ///
					
				*/

local dv revt_yoy
local ivs "com_dev_phl_rtg_lym prod_rtg_lym humrts_supchain_rtg_lym comp_ben_rtg_lym div_lab_rtg_lym train_hlth_safe_rtg_lym enrgy_climchge_rtg_lym enviro_pol_rpt_rtg_lym resource_mgmt_rtg_lym board_rtg_lym ldrship_ethics_rtg_lym trans_report_rtg_lym"
local controls "dltt at age emp tobinq xad xrd"

foreach iv of local ivs {
	local vars ""
	display "`iv'"
	xtreg F.`dv' `iv', fe cluster(cusip_n)
	est store `iv'0
	qui estadd local yearFE "No", replace
	qui estadd local firmFE "Yes", replace

	xtreg F.`dv' `iv' i.year, fe cluster(cusip_n)
	est store `iv'1
	qui estadd local yearFE "Yes", replace
	qui estadd local firmFE "Yes", replace
	
	local vars ""
	local counter 2
	foreach control of local controls {
		*	Regression
		xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(cusip_n)
			
		*	Store results
		est store `iv'`counter'
		estadd local yearFE "Yes", replace
		estadd local firmFE "Yes", replace
		
		*	Increment
		local vars "`vars' `control'"
		local counter = `counter' + 1
	}

	esttab `iv'*, ///
		keep(`iv' dltt at age emp tobinq xad xrd) ///
		order(`iv' dltt at age emp tobinq xad xrd) ///
		s(yearFE firmFE N N_g r2 aic, label("Year FEs" "Firm FEs" "Observations" "Firms" "R^2" "AIC"))

	*	Many xad and xrd observations are missing. Assume missing = 0.
	preserve
	replace xad=0 if xad==. & `iv'!=.											/*	assumption	*/
	replace xrd=0 if xrd==. & `iv'!=.											/*	assumption	*/

	xtreg F.`dv' `iv' `controls' i.year, fe cluster(cusip_n)
	est store as1
	qui estadd local yearFE "Yes", replace
	qui estadd local firmFE "Yes", replace
	restore 

	*	Table
	esttab `iv'* as1, ///
		keep(`iv' dltt at age emp tobinq xad xrd) ///
		order(`iv' dltt at age emp tobinq xad xrd) ///
		s(yearFE firmFE N N_g r2 aic, label("Year FEs" "Firm FEs" "Observations" "Firms" "R^2" "AIC"))
}


///	ALL SUBCATEGORIES
xtreg F.revt_yoy com_dev_phl_rtg_lym prod_rtg_lym humrts_supchain_rtg_lym ///
	comp_ben_rtg_lym div_lab_rtg_lym train_hlth_safe_rtg_lym ///
	enrgy_climchge_rtg_lym enviro_pol_rpt_rtg_lym resource_mgmt_rtg_lym ///
	board_rtg_lym ldrship_ethics_rtg_lym trans_report_rtg_lym ///
	dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
	
preserve
replace xad=0 if xad==.
replace xrd=0 if xrd==.

xtreg F.revt_yoy com_dev_phl_rtg_lym prod_rtg_lym humrts_supchain_rtg_lym ///
	comp_ben_rtg_lym div_lab_rtg_lym train_hlth_safe_rtg_lym ///
	enrgy_climchge_rtg_lym enviro_pol_rpt_rtg_lym resource_mgmt_rtg_lym ///
	board_rtg_lym ldrship_ethics_rtg_lym trans_report_rtg_lym ///
	dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
est sto subcat_all
qui estadd local yearFE "Yes", replace
qui estadd local firmFE "Yes", replace

restore

esttab subcat_all, ///
	drop(*.year) ///
	s(yearFE firmFE N N_g r2 aic, label("Year FEs" "Firm FEs" "Observations" "Firms" "R^2" "AIC"))














capt n log close



/*


						***===========================***
						*		  INDUSTRY-LEVEL		*	
						***===========================***
gen sic2 = substr(sic,1,2)
destring sic2, replace

replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

collapse (mean) revt over_rtg dltt at emp tobinq xad xrd age, by(sic2 year)

xtset sic2 year, y

xtreg revt over_rtg dltt at emp tobinq xad xrd age, fe cluster(sic2)
xtreg revt over_rtg dltt at emp tobinq xad xrd age i.year, fe cluster(sic2)


gen revt_yoy = revt-l.revt

xtreg F.revt over_rtg dltt at emp tobinq xad xrd age, fe cluster(sic2)
xtreg F.revt over_rtg dltt at emp tobinq xad xrd age i.year, fe cluster(sic2)

xtreg F.revt_yoy over_rtg dltt at emp tobinq xad xrd age, fe cluster(sic2)
xtreg F.revt_yoy over_rtg dltt at emp tobinq xad xrd age i.year, fe cluster(sic2)















	
///	SALES (REVENUE LEVEL)
xtabond f.revt enviro_rtg_lym gov_rtg_lym emp_rtg_lym cmty_rtg_lym dltt at emp tobinq xad xrd, lags(1) artests(2)

///	SALES GROWTH (REVENUE YEAR-ON-YEAR CHANGE)
xtabond f.revt enviro_rtg_lym gov_rtg_lym emp_rtg_lym cmty_rtg_lym dltt at emp tobinq xad xrd, lags(1) artests(2)













***===============================================================***
*	EXPLORATORY DATA ANALYSIS: FIXED EFFECTS REGRESSION				*
***===============================================================***

///	Generate change in revenue DV
gen revt_delta = revt-l.revt
label var revt_delta "Year-on-year change in total revenue (revt)"

***	Implement assumptions
keep if year > 2010

///	BINARY TREATMENT
foreach threshold in 2 3 4 {
	*	DV: Change in revenue
	xtreg f.revt_yoy trt`threshold'_year_only_sdg revt_yoy rd emp debt i.year, fe cluster(cusip_n)
	xtreg f.revt_yoy trt`threshold'_year_only_sdg revt_yoy rd emp debt i.year, fe cluster(cusip_n)
	xtreg f.revt_yoy trt`threshold'_year_only_sdw revt_yoy rd emp debt i.year, fe cluster(cusip_n)
	
	
	
	*	DV: Revenue
	xtreg f.revt trt`threshold'_year_only_sdg revt rd emp debt i.year, fe cluster(cusip_n)
	xtreg f.revt trt`threshold'_year_only_sdw revt rd emp debt i.year, fe cluster(cusip_n)
}


///	CONTINUOUS TREATMENT
***	DV: Change in revenue
xtreg f.revt_yoy trt_cont_sdg revt_yoy rd emp debt i.year, fe cluster(cusip_n)
xtreg f.revt_yoy trt_cont_sdw revt_yoy rd emp debt i.year, fe cluster(cusip_n)
xtreg f.revt_yoy i.trt_cont_sdg revt_yoy rd emp debt i.year, fe cluster(cusip_n)
xtreg f.revt_yoy i.trt_cont_sdw revt_yoy rd emp debt i.year, fe cluster(cusip_n)	


***	DV: Revenue
xtreg f.revt trt_cont_sdg revt rd emp debt i.year, fe cluster(cusip_n)
xtreg f.revt trt_cont_sdw revt rd emp debt i.year, fe cluster(cusip_n)
xtreg f.revt i.trt_cont_sdg revt rd emp debt i.year, fe cluster(cusip_n)
xtreg f.revt i.trt_cont_sdw revt rd emp debt i.year, fe cluster(cusip_n)



***===============================================================================***
*	EXPLORATORY DATA ANALYSIS: RANDOM EFFECTS WITHIN-BETWEEN REGRESSION				*
***===============================================================================***
///	GENERATE MEAN AND DEMEANED VARIABLES
xtset
drop *_m *_dm
foreach variable in trt_cont_sdg trt_cont_sdw revt revt_yoy rd emp debt {
	by cusip_n: egen `variable'_m = mean(`variable')
	gen `variable'_dm = `variable' - `variable'_m
}



///	CONTINUOUS TREATMENT
***	DV: Change in revenue
xtreg f.revt_yoy trt_cont_sdg_dm revt_yoy_dm rd_dm emp_dm debt_dm ///
	trt_cont_sdg_m revt_yoy_m rd_m emp_m debt_m ///
	i.year, re cluster(cusip_n)

xtreg f.revt_yoy trt_cont_sdw_dm revt_yoy_dm rd_dm emp_dm debt_dm ///
	trt_cont_sdw_m revt_yoy_m rd_m emp_m debt_m ///
	i.year, re cluster(cusip_n)

***	DV: Revenue
xtreg f.revt trt_cont_sdg_dm revt_dm rd_dm emp_dm debt_dm ///
	trt_cont_sdg_m revt_m rd_m emp_m debt_m ///
	i.year, re cluster(cusip_n)

xtreg f.revt trt_cont_sdw_dm revt_dm rd_dm emp_dm debt_dm ///
	trt_cont_sdw_m revt_m rd_m emp_m debt_m ///
	i.year, re cluster(cusip_n)
	
	
	
	


capt n log close










***===============================================================***
*	EXPLORATORY DATA ANALYSIS: GRAPHICAL 							*
***===============================================================***
set scheme plotplainblind

/// WITHIN-FIRM OVERALL RATING STANDARD DEVIATION
gen one_year_change_over_rtg_dm = over_rtg_dm - l.over_rtg_dm

/*
set scheme plotplainblind
xtsum over_rtg
local sd1p = `r(sd_w)'
local sd1n = `r(sd_w)' * -1
local sd2p = `r(sd_w)' * 2
local sd2n = `r(sd_w)' * -2
local sd3p = `r(sd_w)' * 3
local sd3n = `r(sd_w)' * -3
local sd3p = `r(sd_w)' * 4
local sd3n = `r(sd_w)' * -4
scatter one_year_change_over_rtg_dm cusip_n, sort mlabsize(tiny) m(p) mcolor(black%30) ///
	yline(`sd1p') ///
	yline(`sd1n') /// 
	yline(`sd2p') ///
	yline(`sd2n') ///
	yline(`sd4p') ///
	yline(`sd4n')
*/

///	CHECK IF TREATED FIRMS ARE JUST THOSE THAT HAVE HIGH STANDARD DEVIATIONS IN THEIR OWN SCORES
bysort cusip: egen over_std=sd(over_rtg)
replace over_std=. if over_rtg==.
histogram over_std, bin(100) normal ///
	ti("Distribution of within-firm CSRHub overall rating standard deviations") ///
	saving(graphics/hist-over_std, replace)

foreach value in 4 3 2 {
	graph box over_std, over(trt`value') saving(graphics/trt`value', replace) ti("`value'-standard deviation treatment") nodraw
}
gr combine graphics/trt4.gph graphics/trt3.gph graphics/trt2.gph, r(1) c(3) ///
	saving(graphics/trt-combined, replace) nodraw

	
///	FINANCIAL PERFORMANCE DIFFERENCES IN RAW DATA
capt matrix drop A
foreach cfp in revt ni tobinq {
	foreach threshold in 4 3 2 {
		ttest `cfp', by(trt`threshold')
		capt noisily confirm matrix A
		if (_rc!=0) {
			matrix define A = (r(mu_1), r(mu_2), r(mu_1)-r(mu_2), r(t), r(p))
			matrix colnames A = Mu_0 Mu_1 Difference T-stat P-value
			matrix rownames A = "ttest_`cfp'_trt`threshold'"
			}
		else {
			local matrownames `:rownames A'
			mat A = (A \ r(mu_1), r(mu_2), r(mu_1)-r(mu_2), r(t), r(p))
			mat rownames A = `matrownames' ttest_`cfp'_trt`threshold'
		}
	}
}

putexcel set tables-and-figures/ttestresults, replace
putexcel A1=matrix(A), names 




/// Histogram of years in data for each CUSIP
preserve

bysort cusip: gen n=_n
keep if n==1

histogram N, d freq addlabel xlab(0(1)8) ///
	ti("Years of observations for each CUSIP" "in data matched across all 3 datasets") ///
	xti("Years of observations in the 8-year panel") ///
	yti("CUSIPs")
	
restore

///	DISTRIBUTION OF TREATED FIRMS ACROSS YEARS

***	Treated CUSIPs per year
foreach threshold in 4 3 2 {
	graph bar (count) cusip_n if trt`threshold'_date==1, over(year, label(angle(90))) ///
		ti("Count of `threshold'sd treated CUSIPs per year") ///
		yti("CUSIPs treated at `threshold'sd") ///
		blabel(total, size(vsmall)) ///
		saving(graphics/treated-cusips-per-year-`threshold'sd, replace) ///
		nodraw		
}
	
graph combine graphics/treated-cusips-per-year-4sd.gph ///
	graphics/treated-cusips-per-year-3sd.gph ///
	graphics/treated-cusips-per-year-2sd.gph, row(1) col(3) ///
	altshrink ///
	ycommon xcommon

***	Only firms in the entire CSRHub panel
keep if in_csrhub==1
bysort cusip: gen N=_N
tab N
keep if N==10
drop N

foreach threshold in 4 3 2 {
	graph bar (count) cusip_n if trt`threshold'_date==1, over(year, label((2008(1)2017), angle(90))) ///
		ti("Count of `threshold'sd treated CUSIPs per year") ///
		yti("CUSIPs treated at `threshold'sd") ///
		blabel(total, size(vsmall)) ///
		saving(graphics/treated-cusips-per-year-`threshold'sd-balanced-panel, replace) ///
		nodraw		
}
	
graph combine graphics/treated-cusips-per-year-4sd-balanced-panel.gph ///
	graphics/treated-cusips-per-year-3sd-balanced-panel.gph ///
	graphics/treated-cusips-per-year-2sd-balanced-panel.gph, row(1) col(3) ///
	altshrink ///
	ycommon xcommon ///
	ti("CUSIPs in all years of CSRHub data")
