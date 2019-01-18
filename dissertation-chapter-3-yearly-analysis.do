///	LOG
capt n log close
log using logs/yearly-analysis-leading-dv.txt, text replace

///	LOAD DATA
use data/csrhub-kld-cstat-year-level-with-treatment-variables.dta, clear

/// SET PANEL
encode cusip, gen(cusip_n)
xtset cusip_n year, y

///	GENERATE YEAR-ON-YEAR REVENUE CHANGE
gen revt_yoy = revt - l.revt
label var revt_yoy "Year-on-year change in revenue (revt)"

///	KEEP VARIABLES IN REGRESSION MODELS TO REDUCE FILE SIZE
keep cusip cusip_n year revt revt_yoy dltt at xad xrd emp ///
	over_rtg *rtg_lym


***===========================***
*	REVENUE LEVEL = F (CSRHUB) 	*
***===========================***
///	CONTROL VARIABLE MODELS

***	DV: Revenue (Level)
*mark mark3
*markout mark3 revt over_rtg dltt at xad xrd emp year

xtreg revt over_rtg, fe cluster(cusip_n)										/*	non-sig	*/
est store con1
estadd local yearFE "No", replace
xtreg revt over_rtg i.year, fe cluster(cusip_n)									/*	non-sig	*/
est store con2
estadd local yearFE "Yes", replace
xtreg revt over_rtg dltt i.year, fe cluster(cusip_n)							/*	non-sig	*/
est store con3
estadd local yearFE "Yes", replace
xtreg revt over_rtg dltt at i.year, fe cluster(cusip_n)							/*	sig	*/
est store con4
estadd local yearFE "Yes", replace
xtreg revt over_rtg dltt at emp i.year, fe cluster(cusip_n)						/*	non-sig	*/
est store con5
estadd local yearFE "Yes", replace
xtreg revt over_rtg dltt at emp xad i.year, fe cluster(cusip_n)					/*	non-sig	*/
est store con6
estadd local yearFE "Yes", replace
xtreg revt over_rtg dltt at emp xad xrd i.year, fe cluster(cusip_n)				/*	non-sig	*/
est store con7
estadd local yearFE "Yes", replace

*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

xtreg revt over_rtg dltt at emp xad xrd i.year, fe cluster(cusip_n)				/*	non-sig	*/
est store con8
estadd local yearFE "Yes", replace
restore

esttab con1 con2 con3 con4 con5 con6 con7 con8, ///
	b se s(yearFE N r2 aic, label("Year FEs" "N" "R^2" "AIC")) ///
	keep(over_rtg dltt at xad xrd emp)

	
	
***===============================***
*	REVENUE CHANGE = F (CSRHUB) 	*
***===============================***	
/// DV: Revenue (1-year change)
xtreg F.revt_yoy over_rtg, fe cluster(cusip_n)									/*	non-sig	*/
est store con8
xtreg F.revt_yoy over_rtg i.year, fe cluster(cusip_n)								/*	sig	*/
est store con9
xtreg F.revt_yoy over_rtg dltt i.year, fe cluster(cusip_n)						/*	sig	*/
est store con10
xtreg F.revt_yoy over_rtg dltt at i.year, fe cluster(cusip_n)						/*	sig	*/
est store con11
xtreg F.revt_yoy over_rtg dltt at xad i.year, fe cluster(cusip_n)					/*	non-sig	*/
est store con12
xtreg F.revt_yoy over_rtg dltt at xad xrd i.year, fe cluster(cusip_n)				/*	non-sig	*/
est store con13
xtreg F.revt_yoy over_rtg dltt at xad xrd emp i.year, fe cluster(cusip_n)			/*	non-sig	*/
est store con14

*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

xtreg F.revt_yoy over_rtg dltt at xad xrd emp i.year, fe cluster(cusip_n)			/*	sig	*/
est store con15
restore 

*	Assume missing xad and xrd are 0, interact over_rtg and revt, 
*	all independent variables lagged
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

xtreg F.revt_yoy c.over_rtg##c.revt dltt at xad xrd emp i.year, fe cluster(cusip_n)			/*	sig	*/
est store con16
restore

*	Assume missing xad and xrd are 0, interact over_rtg and revt, 
*	all independent variables lagged, and standardized revt and over_rtg
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

egen Sover_rtg = std(over_rtg)
egen Srevt = std(revt)

xtreg F.revt_yoy c.Sover_rtg##c.Srevt dltt at xad xrd emp i.year, fe cluster(cusip_n)			/*	sig	*/
est store con17
restore

esttab con8 con9 con10 con11 con12 con13 con14 con15, ///
	keep(over_rtg dltt at xad xrd emp) ///
	order(over_rtg dltt at xad xrd emp) ///
	r2 ar2 aic
	
esttab con16 con17, ///
	keep(over_rtg revt c.over_rtg* Sover_rtg Srevt c.Sover_rtg* dltt at xad xrd emp) ///
	order(over_rtg revt c.over_rtg* Sover_rtg Srevt c.Sover_rtg* dltt at xad xrd emp) ///
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
xtreg F.revt_yoy cmty_rtg_lym, fe cluster(cusip_n)								/*	non-sig	*/
est store m1
xtreg F.revt_yoy cmty_rtg_lym i.year, fe cluster(cusip_n)							/*	sig	*/
est store m2
xtreg F.revt_yoy cmty_rtg_lym dltt i.year, fe cluster(cusip_n)					/*	sig	*/
est store m3
xtreg F.revt_yoy cmty_rtg_lym dltt at i.year, fe cluster(cusip_n)					/*	sig	*/
est store m4
xtreg F.revt_yoy cmty_rtg_lym dltt at xad i.year, fe cluster(cusip_n)				/*	non-sig	*/
est store m5
xtreg F.revt_yoy cmty_rtg_lym dltt at xad xrd i.year, fe cluster(cusip_n)			/*	non-sig	*/
est store m6
xtreg F.revt_yoy cmty_rtg_lym dltt at xad xrd emp i.year, fe cluster(cusip_n)		/*	non-sig	*/
est store m7

*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & cmty_rtg_lym!=.										/*	assumption	*/
replace xrd=0 if xrd==. & cmty_rtg_lym!=.										/*	assumption	*/

xtreg F.revt_yoy cmty_rtg_lym dltt at xad xrd emp i.year, fe cluster(cusip_n)		/*	sig	*/
est store m8
restore 

*	Table
esttab m1 m2 m3 m4 m5 m6 m7 m8, ///
	keep(cmty_rtg_lym dltt at xad xrd emp) ///
	r2 ar2 aic


	
///	EMPLOYEES
xtreg F.revt_yoy emp_rtg_lym, fe cluster(cusip_n)									/*	non-sig	*/
est store m1
xtreg F.revt_yoy emp_rtg_lym i.year, fe cluster(cusip_n)							/*	sig	*/
est store m2
xtreg F.revt_yoy emp_rtg_lym dltt i.year, fe cluster(cusip_n)						/*	sig	*/
est store m3
xtreg F.revt_yoy emp_rtg_lym dltt at i.year, fe cluster(cusip_n)					/*	sig	*/
est store m4
xtreg F.revt_yoy emp_rtg_lym dltt at xad i.year, fe cluster(cusip_n)				/*	non-sig	*/
est store m5
xtreg F.revt_yoy emp_rtg_lym dltt at xad xrd i.year, fe cluster(cusip_n)			/*	non-sig	*/
est store m6
xtreg F.revt_yoy emp_rtg_lym dltt at xad xrd emp i.year, fe cluster(cusip_n)		/*	non-sig	*/
est store m7

*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & emp_rtg_lym!=.										/*	assumption	*/
replace xrd=0 if xrd==. & emp_rtg_lym!=.										/*	assumption	*/

xtreg F.revt_yoy emp_rtg_lym dltt at xad xrd emp i.year, fe cluster(cusip_n)		/*	sig	*/
est store m8
restore 

*	Table
esttab m1 m2 m3 m4 m5 m6 m7 m8, ///
	keep(emp_rtg_lym dltt at xad xrd emp) ///
	r2 ar2 aic
	
	
	
///	ENVIRONMENT
xtreg F.revt_yoy enviro_rtg_lym, fe cluster(cusip_n)								/*	non-sig	*/
est store m1
xtreg F.revt_yoy enviro_rtg_lym i.year, fe cluster(cusip_n)						/*	sig	*/
est store m2
xtreg F.revt_yoy enviro_rtg_lym dltt i.year, fe cluster(cusip_n)					/*	sig	*/
est store m3
xtreg F.revt_yoy enviro_rtg_lym dltt at i.year, fe cluster(cusip_n)				/*	non-sig	*/
est store m4
xtreg F.revt_yoy enviro_rtg_lym dltt at xad i.year, fe cluster(cusip_n)			/*	non-sig	*/
est store m5
xtreg F.revt_yoy enviro_rtg_lym dltt at xad xrd i.year, fe cluster(cusip_n)		/*	non-sig	*/
est store m6
xtreg F.revt_yoy enviro_rtg_lym dltt at xad xrd emp i.year, fe cluster(cusip_n)	/*	non-sig	*/
est store m7

*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & enviro_rtg_lym!=.										/*	assumption	*/
replace xrd=0 if xrd==. & enviro_rtg_lym!=.										/*	assumption	*/

xtreg F.revt_yoy enviro_rtg_lym dltt at xad xrd emp i.year, fe cluster(cusip_n)	/*	non-sig	*/
est store m8
restore 

*	Table
esttab m1 m2 m3 m4 m5 m6 m7 m8, ///
	keep(enviro_rtg_lym dltt at xad xrd emp) ///
	r2 ar2 aic

///	GOVERNANCE
xtreg F.revt_yoy gov_rtg_lym, fe cluster(cusip_n)									/*	non-sig	*/
est store m1
xtreg F.revt_yoy gov_rtg_lym i.year, fe cluster(cusip_n)							/*	non-sig	*/
est store m2
xtreg F.revt_yoy gov_rtg_lym dltt i.year, fe cluster(cusip_n)						/*	non-sig	*/
est store m3
xtreg F.revt_yoy gov_rtg_lym dltt at i.year, fe cluster(cusip_n)					/*	non-sig	*/
est store m4
xtreg F.revt_yoy gov_rtg_lym dltt at xad i.year, fe cluster(cusip_n)				/*	non-sig	*/
est store m5
xtreg F.revt_yoy gov_rtg_lym dltt at xad xrd i.year, fe cluster(cusip_n)			/*	non-sig	*/
est store m6
xtreg F.revt_yoy gov_rtg_lym dltt at xad xrd emp i.year, fe cluster(cusip_n)		/*	non-sig	*/
est store m7

*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & gov_rtg_lym!=.										/*	assumption	*/
replace xrd=0 if xrd==. & gov_rtg_lym!=.										/*	assumption	*/

xtreg F.revt_yoy gov_rtg_lym dltt at xad xrd emp i.year, fe cluster(cusip_n)		/*	non-sig	*/
est store m8
restore 

*	Table
esttab m1 m2 m3 m4 m5 m6 m7 m8, ///
	keep(gov_rtg_lym dltt at xad xrd emp) ///
	r2 ar2 aic
	
	
///	ALL CATEGORIES
xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym , fe cluster(cusip_n)									/*	non-sig	*/
est store m1
xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym  i.year, fe cluster(cusip_n)							/*	non-sig	*/
est store m2
xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym  dltt i.year, fe cluster(cusip_n)						/*	non-sig	*/
est store m3
xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym  dltt at i.year, fe cluster(cusip_n)					/*	non-sig	*/
est store m4
xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym  dltt at xad i.year, fe cluster(cusip_n)				/*	non-sig	*/
est store m5
xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym  dltt at xad xrd i.year, fe cluster(cusip_n)			/*	non-sig	*/
est store m6
xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym  dltt at xad xrd emp i.year, fe cluster(cusip_n)		/*	non-sig	*/
est store m7

*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==.															/*	assumption	*/
replace xrd=0 if xrd==.															/*	assumption	*/

xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym  dltt at xad xrd emp i.year, fe cluster(cusip_n)		/*	non-sig	*/
est store m8
restore 

*	Table
esttab m1 m2 m3 m4 m5 m6 m7 m8, ///
	keep(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym  dltt at xad xrd emp) ///
	r2 ar2 aic
	
	
	
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
*/

local subcategories com_dev_phl_rtg_lym prod_rtg_lym humrts_supchain_rtg_lym ///
	comp_ben_rtg_lym div_lab_rtg_lym train_hlth_safe_rtg_lym enrgy_climchge_rtg_lym ///
	enviro_pol_rpt_rtg_lym resource_mgmt_rtg_lym board_rtg_lym ldrship_ethics_rtg_lym ///
	trans_report_rtg_lym
*/
foreach subcategory in `subcategories' {
	xtreg F.revt_yoy `subcategory', fe cluster(cusip_n)
	est store m1
	xtreg F.revt_yoy `subcategory' i.year, fe cluster(cusip_n)
	est store m2
	xtreg F.revt_yoy `subcategory' dltt i.year, fe cluster(cusip_n)
	est store m3
	xtreg F.revt_yoy `subcategory' dltt at i.year, fe cluster(cusip_n)
	est store m4
	xtreg F.revt_yoy `subcategory' dltt at xad i.year, fe cluster(cusip_n)
	est store m5
	xtreg F.revt_yoy `subcategory' dltt at xad xrd i.year, fe cluster(cusip_n)
	est store m6
	xtreg F.revt_yoy `subcategory' dltt at xad xrd emp i.year, fe cluster(cusip_n)
	est store m7

	*	Many xad and xrd observations are missing. Assume missing = 0.
	preserve
	replace xad=0 if xad==. & `subcategory'!=.									/*	assumption	*/
	replace xrd=0 if xrd==. & `subcategory'!=.									/*	assumption	*/

	xtreg F.revt_yoy `subcategory' dltt at xad xrd emp i.year, fe cluster(cusip_n)
	est store m8
	restore 

	*	Table
	esttab m1 m2 m3 m4 m5 m6 m7 m8, ///
		keep(`subcategory' dltt at xad xrd emp) ///
		r2 ar2 aic
}
	


capt n log close


/*

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
