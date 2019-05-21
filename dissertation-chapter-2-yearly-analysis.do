///	LOG
*capt n log close
*log using code/logs/20190219-yearly-analysis.txt, text

///	SET ENVIRONMENT
clear all
set scheme plotplain

///	LOAD DATA
use data/csrhub-kld-cstat-year-level-with-treatment-variables.dta, clear

drop over_rtg_mean over_rtg_med over_pct_rank_lym

***	Clear estimates
est clear

*** Assess treatment variables distribution and zscores
bysort cusip: egen yoy_mean = mean(over_rtg_yoy)
replace yoy_mean=. if over_rtg_yoy==.

bysort cusip: egen yoy_std_dev = sd(over_rtg_yoy)
replace yoy_std_dev=. if over_rtg_yoy==.

gen yoy_zscore = (over_rtg_yoy - yoy_mean) / yoy_std_dev

*	Histogram
histogram yoy_zscore, bin(100) percent normal ///
	xti("Z-score") xlab(-4(1)4) scheme(plotplain)

***	Remove firms with only two observations on year-on-year change
gen ch1 = (over_rtg_yoy!=.)
bysort cusip: egen ch2=total(ch1)
replace yoy_zscore=. if ch2==2

drop ch1 ch2

*	Histogram
histogram yoy_zscore, bin(100) percent normal ///
	xti("Z-score") xlab(-4(1)4) scheme(plotplain)
	

*	Example
scatter over_rtg_yoy year if cusip=="00103079", ///
	xti("Year") ///
	yline(1.974611, lstyle(solid)) ///
	ti("Jyske Bank A/S year-on-year change in overall rating.") ///
	subti("Solid line is average year-on-year change for the firm." ///
	"Treatment at -2 z-score occurs in 2014.")
	
*	Treatment indicators
gen trt1pos = (yoy_zscore>1 & yoy_zscore!=.)
gen trt1neg = (yoy_zscore<-1 & yoy_zscore!=.)	
gen trt2pos = (yoy_zscore>2 & yoy_zscore!=.)
gen trt2neg = (yoy_zscore<-2 & yoy_zscore!=.)
gen trt3pos = (yoy_zscore>3 & yoy_zscore!=.)
gen trt3neg = (yoy_zscore<-3 & yoy_zscore!=.)




/*	THESE ARE NOT CORRECT ZSCORE CALCULATIONS

gen zscore = over_rtg_yoy/sdw	/*	This is not how to calculate a zscore	*/
bysort zscore: gen N=_N
tab N, sort
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
     135667 |    135,667       76.26       76.26
          1 |     40,799       22.93       99.19
        457 |        457        0.26       99.45
        393 |        393        0.22       99.67
        317 |        317        0.18       99.85
        100 |        100        0.06       99.91
         71 |         71        0.04       99.95
          2 |         28        0.02       99.96
         21 |         21        0.01       99.97
         18 |         18        0.01       99.98
         14 |         14        0.01       99.99
          7 |          7        0.00       99.99
          5 |          5        0.00      100.00
          4 |          4        0.00      100.00
------------+-----------------------------------
      Total |    177,901      100.00

N = 457 and N = 317 are the problem.
	  */
gen ch1=(N==457)
replace ch1=1 if N==317
bysort cusip: egen ch2=max(ch1)

*For some reason, the problem clusters in 2017
tab year if ch1==1
/*
 (KLD) Year |      Freq.     Percent        Cum.
------------+-----------------------------------
       2009 |          5        0.65        0.65
       2010 |         34        4.39        5.04
       2011 |         21        2.71        7.75
       2012 |          7        0.90        8.66
       2013 |         14        1.81       10.47
       2014 |          9        1.16       11.63
       2015 |          4        0.52       12.14
       2016 |          8        1.03       13.18
       2017 |        672       86.82      100.00
------------+-----------------------------------
      Total |        774      100.00
*/

*	Z-score for deviation of over_rtg compared to within-firm standard deviation
histogram zscore, bin(100) percent normal ///
	scheme(plotplain) ///
	xti("") ///
	ti("Number of standard deviations from the within-firm mean" "for each year-on-year change in overall rating") ///
	xline(-4 -3 -2 -1 0 1 2 3 4) ///
	xlab(-4(1)4)

*	 Table of descriptive statistics for treatment variables
tab trt1_sdw_pos
tab trt1_sdw_neg
tab trt2_sdw_pos
tab trt2_sdw_neg
tab trt3_sdw_pos
tab trt3_sdw_neg



*	Drop firms with problematic zscores resulting from only 2 observations in the data
foreach variable of varlist trt1_sdw_pos trt1_sdw_neg trt2_sdw_pos ///
	trt2_sdw_neg trt3_sdw_pos trt3_sdw_neg {
	replace `variable'=. if N==457
	replace `variable'=. if N==317
	replace zscore=. if N==457
	replace zscore=. if N==317
}

histogram zscore, bin(100) percent normal ///
	scheme(plotplain) ///
	xti("") ///
	xline(-4 -3 -2 -1 0 1 2 3 4) ///
	xlab(-4(1)4)

*	Table of descriptive statistics for treatment variables
tab trt1_sdw_pos
tab trt1_sdw_neg
tab trt2_sdw_pos
tab trt2_sdw_neg
tab trt3_sdw_pos
tab trt3_sdw_neg	

*/
	
***	Keep only years with CSRHub data
drop if year>2017
drop if year<2008




/// CREATE INDUSTRY VARIABLE USING 2-DIGIT SIC
gen sic2 = substr(sic,1,2)
destring sic2, replace

gen sic2cat=""

replace sic2cat="agforfish" if sic2==1
replace sic2cat="agforfish" if sic2==2
replace sic2cat="agforfish" if sic2==7
replace sic2cat="agforfish" if sic2==8
replace sic2cat="agforfish" if sic2==9

replace sic2cat="mining" if sic2==10
replace sic2cat="mining" if sic2==12
replace sic2cat="mining" if sic2==13
replace sic2cat="mining" if sic2==14

replace sic2cat="construction" if sic2==15
replace sic2cat="construction" if sic2==16
replace sic2cat="construction" if sic2==17

replace sic2cat="manufacture" if sic2==20
replace sic2cat="manufacture" if sic2==21
replace sic2cat="manufacture" if sic2==22
replace sic2cat="manufacture" if sic2==23
replace sic2cat="manufacture" if sic2==24
replace sic2cat="manufacture" if sic2==25
replace sic2cat="manufacture" if sic2==26
replace sic2cat="manufacture" if sic2==27
replace sic2cat="manufacture" if sic2==28
replace sic2cat="manufacture" if sic2==29
replace sic2cat="manufacture" if sic2==30
replace sic2cat="manufacture" if sic2==31
replace sic2cat="manufacture" if sic2==32
replace sic2cat="manufacture" if sic2==33
replace sic2cat="manufacture" if sic2==34
replace sic2cat="manufacture" if sic2==35
replace sic2cat="manufacture" if sic2==36
replace sic2cat="manufacture" if sic2==37
replace sic2cat="manufacture" if sic2==38
replace sic2cat="manufacture" if sic2==39

replace sic2cat="transport" if sic2==40
replace sic2cat="transport" if sic2==41
replace sic2cat="transport" if sic2==42
replace sic2cat="transport" if sic2==43
replace sic2cat="transport" if sic2==44
replace sic2cat="transport" if sic2==45
replace sic2cat="transport" if sic2==46
replace sic2cat="transport" if sic2==47
replace sic2cat="transport" if sic2==48
replace sic2cat="transport" if sic2==49

replace sic2cat="wholesale" if sic2==50
replace sic2cat="wholesale" if sic2==51

replace sic2cat="retail" if sic2==52
replace sic2cat="retail" if sic2==53
replace sic2cat="retail" if sic2==54
replace sic2cat="retail" if sic2==55
replace sic2cat="retail" if sic2==56
replace sic2cat="retail" if sic2==57
replace sic2cat="retail" if sic2==58
replace sic2cat="retail" if sic2==59

replace sic2cat="finance" if sic2==60
replace sic2cat="finance" if sic2==61
replace sic2cat="finance" if sic2==62
replace sic2cat="finance" if sic2==63
replace sic2cat="finance" if sic2==64
replace sic2cat="finance" if sic2==65
replace sic2cat="finance" if sic2==67

replace sic2cat="services" if sic2==70
replace sic2cat="services" if sic2==72
replace sic2cat="services" if sic2==73
replace sic2cat="services" if sic2==75
replace sic2cat="services" if sic2==76
replace sic2cat="services" if sic2==78
replace sic2cat="services" if sic2==79
replace sic2cat="services" if sic2==80
replace sic2cat="services" if sic2==81
replace sic2cat="services" if sic2==82
replace sic2cat="services" if sic2==83
replace sic2cat="services" if sic2==84
replace sic2cat="services" if sic2==86
replace sic2cat="services" if sic2==87
replace sic2cat="services" if sic2==88
replace sic2cat="services" if sic2==89

replace sic2cat="publicadmin" if sic2==91
replace sic2cat="publicadmin" if sic2==92
replace sic2cat="publicadmin" if sic2==93
replace sic2cat="publicadmin" if sic2==94
replace sic2cat="publicadmin" if sic2==95
replace sic2cat="publicadmin" if sic2==96
replace sic2cat="publicadmin" if sic2==97
replace sic2cat="publicadmin" if sic2==99

encode sic2cat, gen(sic2division)
label var sic2division "SIC division (2-digit level)"

///	KEEP VARIABLES IN REGRESSION MODELS TO REDUCE FILE SIZE
keep cusip cusip_n year revt revt_yoy revt_pct Frevt_yoy ///
	dltt at xad xrd emp age ///
	over_rtg *rtg_lym sic tobinq sic sic2division ///
	trt1_sdw_neg trt1_sdw_neg_grp trt1_sdw_pos trt1_sdw_pos_grp ///
	trt2_sdw_neg trt2_sdw_neg_grp trt2_sdw_pos trt2_sdw_pos_grp ///
	trt3_sdw_neg trt3_sdw_neg_grp trt3_sdw_pos trt3_sdw_pos_grp ///
	in_cstat in_csrhub in_kld in_all
	
	

///	CREATE DUMMY FOR FIRMS IN THE CSRHUB DATA FOR ALL YEARS OF PANEL
***	CSRHub data have 9 years of observations
bysort cusip: egen csrhub_years = total(in_csrhub)
gen in_csrhub_all=(csrhub_years==9)
label var in_csrhub_all "(CSRHub) =1 if firm in all 9 years of CSRHub data"
drop csrhub_years
replace in_csrhub_all=0 if in_csrhub==0


///	Descriptive statistics
mark both
markout both over_rtg revt
keep if both==1
compress


/*
///	Revenue distribution
mark both
markout both revt over_rtg

keep if both ==1 

histogram revt, bin(100) scheme(plotplain) percent ///
	xtitle("Annual Revenue (millions US dollars)") ///
	xlabel(,format(%9.0gc))

sum revt, d
*/

/*	
						***===========================***
						*	FIXED EFFECTS REGRESSION	*
						*		DV: SALES GROWTH		*
						***===========================***	
***===========================***
*	REVENUE = F (CSRHUB) 	*
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

	
***	COMPARE THE TWO DVs
esttab revt_yoymod9 over_rtgmod8 revt_yoymod10 over_rtgas1 , ///
	keep(over_rtg dltt at age emp tobinq xad xrd) ///
	order(over_rtg dltt at age emp tobinq xad xrd) ///
	s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC"))

	
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



///	COMPARE ALL CSRHUB CATEGORIES
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym , fe cluster(cusip_n)
est store m1
estadd local yearFE "Yes", replace
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym i.year, fe cluster(cusip_n)
est store m2
estadd local yearFE "Yes", replace
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt i.year, fe cluster(cusip_n)
est store m3
estadd local yearFE "Yes", replace
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at i.year, fe cluster(cusip_n)
est store m4
estadd local yearFE "Yes", replace
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age i.year, fe cluster(cusip_n)
est store m5
estadd local yearFE "Yes", replace
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp i.year, fe cluster(cusip_n)
est store m6
estadd local yearFE "Yes", replace
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad i.year, fe cluster(cusip_n)
est store m7
estadd local yearFE "Yes", replace
qui xtreg F.revt_yoy cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
est store m8
estadd local yearFE "Yes", replace


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
	s(yearFE N N_g r2 r2_a aic, label("Year FEs" "Observations" "Firms" "R^2" "Adj'd R^2" "AIC"))	

***	Full model comparisons of CATEGORY-level CSRHub
esttab cmtymod8 cmtyas1 empmod8 empas1 enviromod8 enviroas1 govmod8 govas1 m8 m9 , ///
	keep(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(N N_g r2 r2_a aic, label("Observations" "Firms" "R^2" "Adj'd R^2" "AIC"))	
	
esttab cmtymod8 empmod8 enviromod8 govmod8 m8 cmtyas1 empas1 enviroas1 govas1 m9, ///
	keep(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(yearFEs N N_g r2 r2_a aic, label("Year FEs" "Observations" "Firms" "R^2" "Adj'd R^2" "AIC"))	

	
	
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
	qui xtreg F.`dv' `iv', fe cluster(cusip_n)
	est store `iv'0
	qui estadd local yearFE "No", replace
	qui estadd local firmFE "Yes", replace

	qui xtreg F.`dv' `iv' i.year, fe cluster(cusip_n)
	est store `iv'1
	qui estadd local yearFE "Yes", replace
	qui estadd local firmFE "Yes", replace
	
	local vars ""
	local counter 2
	foreach control of local controls {
		*	Regression
		qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(cusip_n)
			
		*	Store results
		est store `iv'`counter'
		estadd local yearFE "Yes", replace
		estadd local firmFE "Yes", replace
		
		*	Increment
		local vars "`vars' `control'"
		local counter = `counter' + 1
	}

	*	Many xad and xrd observations are missing. Assume missing = 0.
	preserve
	replace xad=0 if xad==. & `iv'!=.											/*	assumption	*/
	replace xrd=0 if xrd==. & `iv'!=.											/*	assumption	*/

	qui xtreg F.`dv' `iv' `controls' i.year, fe cluster(cusip_n)
	est store `iv'as1
	qui estadd local yearFE "Yes", replace
	qui estadd local firmFE "Yes", replace
	restore 

	*	Table
	esttab `iv'* `iv'as1, ///
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





						***===========================***
						*	FIXED EFFECTS REGRESSION	*
						*			DV: SALES 			*
						***===========================***	
***===========================***
*	REVENUE = F (CSRHUB) 	*
***===========================***
///	CONTROL VARIABLE MODELS

***	DV: Revenue (Level)
*mark mark3
*markout mark3 revt over_rtg dltt at xad xrd emp year
qui xtreg revt over_rtg, fe cluster(cusip_n)										
est store revtmod1
estadd local yearFE "No", replace
qui xtreg revt over_rtg i.year, fe cluster(cusip_n)									
est store revtmod2
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt i.year, fe cluster(cusip_n)							
est store revtmod3
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt at i.year, fe cluster(cusip_n)							
est store revtmod4
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt at emp i.year, fe cluster(cusip_n)						
est store revtmod5
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt at emp tobinq i.year, fe cluster(cusip_n)					
est store revtmod6
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt at emp tobinq age i.year, fe cluster(cusip_n)				
est store revtmod7
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt at emp tobinq age xad i.year, fe cluster(cusip_n)				
est store revtmod8
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt at emp tobinq age xad xrd i.year, fe cluster(cusip_n)				
est store revtmod9
estadd local yearFE "Yes", replace


*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

qui xtreg revt over_rtg dltt at emp tobinq age xad xrd i.year, fe cluster(cusip_n)				
est store revtmod10
estadd local yearFE "Yes", replace
restore

esttab revtmod*, ///
	b se s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC")) ///
	keep(over_rtg dltt at xad xrd tobinq emp age)

	
/// DV: Revenue (1-year change)
local dv revt
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

qui xtreg F.revt over_rtg dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)	
est store over_rtgas1
estadd local yearFE "Yes", replace
restore 

*	Assume missing xad and xrd are 0, interact over_rtg and revt, 
*	all independent variables lagged
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

qui xtreg F.revt c.over_rtg##c.revt dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
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

qui xtreg F.revt c.Sover_rtg##c.Srevt dltt at emp tobinq xad xrd age i.year, fe cluster(cusip_n)
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

	
***	COMPARE THE TWO DVs
esttab revtmod9 over_rtgmod8 revtmod10 over_rtgas1 , ///
	keep(over_rtg dltt at age emp tobinq xad xrd) ///
	order(over_rtg dltt at age emp tobinq xad xrd) ///
	s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC"))

	
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

local dv revt
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

local dv revt
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

local dv revt
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

local dv revt
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


	
///	COMPARE ALL CSRHUB CATEGORIES
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym , fe cluster(cusip_n)
est store m1
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym i.year, fe cluster(cusip_n)
est store m2
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt i.year, fe cluster(cusip_n)
est store m3
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at i.year, fe cluster(cusip_n)
est store m4
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age i.year, fe cluster(cusip_n)
est store m5
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp i.year, fe cluster(cusip_n)
est store m6
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad i.year, fe cluster(cusip_n)
est store m7
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
est store m8
estadd local yearFE "Yes", replace


***	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==.															/*	assumption	*/
replace xrd=0 if xrd==.															/*	assumption	*/

qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
est store m9
restore 

***	Table
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9, ///
	keep(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(yearFE N N_g r2 r2_a aic, label("Year FEs" "Observations" "Firms" "R^2" "Adj'd R^2" "AIC"))	

***	Full model comparisons of CATEGORY-level CSRHub
esttab cmtymod8 cmtyas1 empmod8 empas1 enviromod8 enviroas1 govmod8 govas1 m8 m9 , ///
	keep(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(N N_g r2 r2_a aic, label("Observations" "Firms" "R^2" "Adj'd R^2" "AIC"))	
	
esttab cmtymod8 empmod8 enviromod8 govmod8 m8 cmtyas1 empas1 enviroas1 govas1 m9, ///
	keep(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(yearFEs N N_g r2 r2_a aic, label("Year FEs" "Observations" "Firms" "R^2" "Adj'd R^2" "AIC"))	

	
	
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

local dv revt
local ivs "com_dev_phl_rtg_lym prod_rtg_lym humrts_supchain_rtg_lym comp_ben_rtg_lym div_lab_rtg_lym train_hlth_safe_rtg_lym enrgy_climchge_rtg_lym enviro_pol_rpt_rtg_lym resource_mgmt_rtg_lym board_rtg_lym ldrship_ethics_rtg_lym trans_report_rtg_lym"
local controls "dltt at age emp tobinq xad xrd"

foreach iv of local ivs {
	local vars ""
	display "`iv'"
	qui xtreg F.`dv' `iv', fe cluster(cusip_n)
	est store `iv'0
	qui estadd local yearFE "No", replace
	qui estadd local firmFE "Yes", replace

	qui xtreg F.`dv' `iv' i.year, fe cluster(cusip_n)
	est store `iv'1
	qui estadd local yearFE "Yes", replace
	qui estadd local firmFE "Yes", replace
	
	local vars ""
	local counter 2
	foreach control of local controls {
		*	Regression
		qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(cusip_n)
			
		*	Store results
		est store `iv'`counter'
		estadd local yearFE "Yes", replace
		estadd local firmFE "Yes", replace
		
		*	Increment
		local vars "`vars' `control'"
		local counter = `counter' + 1
	}

	*	Many xad and xrd observations are missing. Assume missing = 0.
	preserve
	replace xad=0 if xad==. & `iv'!=.											/*	assumption	*/
	replace xrd=0 if xrd==. & `iv'!=.											/*	assumption	*/

	qui xtreg F.`dv' `iv' `controls' i.year, fe cluster(cusip_n)
	est store `iv'as1
	qui estadd local yearFE "Yes", replace
	qui estadd local firmFE "Yes", replace
	restore 

	*	Table
	esttab `iv'* `iv'as1, ///
		keep(`iv' dltt at age emp tobinq xad xrd) ///
		order(`iv' dltt at age emp tobinq xad xrd) ///
		s(yearFE firmFE N N_g r2 aic, label("Year FEs" "Firm FEs" "Observations" "Firms" "R^2" "AIC"))
}


///	ALL SUBCATEGORIES
xtreg F.revt com_dev_phl_rtg_lym prod_rtg_lym humrts_supchain_rtg_lym ///
	comp_ben_rtg_lym div_lab_rtg_lym train_hlth_safe_rtg_lym ///
	enrgy_climchge_rtg_lym enviro_pol_rpt_rtg_lym resource_mgmt_rtg_lym ///
	board_rtg_lym ldrship_ethics_rtg_lym trans_report_rtg_lym ///
	dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
	
preserve
replace xad=0 if xad==.
replace xrd=0 if xrd==.

xtreg F.revt com_dev_phl_rtg_lym prod_rtg_lym humrts_supchain_rtg_lym ///
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







						***===========================***
						*	FIXED EFFECTS REGRESSION	*
						*		DV: % SALES GROWTH		*
						***===========================***	
***===========================***
*	REVENUE = F (CSRHUB) 	*
***===========================***
///	CONTROL VARIABLE MODELS

***	DV: Revenue (Level)
qui xtreg F.revt_pct over_rtg, fe cluster(cusip_n)										
est store revt_pctmod1
estadd local yearFE "No", replace
qui xtreg F.revt_pct over_rtg i.year, fe cluster(cusip_n)									
est store revt_pctmod2
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct over_rtg dltt i.year, fe cluster(cusip_n)							
est store revt_pctmod3
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct over_rtg dltt at i.year, fe cluster(cusip_n)							
est store revt_pctmod4
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct over_rtg dltt at emp i.year, fe cluster(cusip_n)						
est store revt_pctmod5
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct over_rtg dltt at emp tobinq i.year, fe cluster(cusip_n)					
est store revt_pctmod6
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct over_rtg dltt at emp tobinq age i.year, fe cluster(cusip_n)				
est store revt_pctmod7
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct over_rtg dltt at emp tobinq age xad i.year, fe cluster(cusip_n)				
est store revt_pctmod8
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct over_rtg dltt at emp tobinq age xad xrd i.year, fe cluster(cusip_n)				
est store revt_pctmod9
estadd local yearFE "Yes", replace


*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

qui xtreg F.revt_pct over_rtg dltt at emp tobinq age xad xrd i.year, fe cluster(cusip_n)				
est store revt_pctmod10
estadd local yearFE "Yes", replace
restore

esttab revt_pctmod*, ///
	b se s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC")) ///
	keep(over_rtg dltt at xad xrd tobinq emp age)

	
/// DV: Revenue (1-year change)
local dv revt_pct
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

qui xtreg F.revt_pct over_rtg dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)	
est store over_rtgas1
estadd local yearFE "Yes", replace
restore 

*	Assume missing xad and xrd are 0, interact over_rtg and revt, 
*	all independent variables lagged
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

qui xtreg F.revt_pct c.over_rtg##c.revt dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
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

qui xtreg F.revt_pct c.Sover_rtg##c.Srevt dltt at emp tobinq xad xrd age i.year, fe cluster(cusip_n)
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

	
***	COMPARE THE TWO DVs
esttab revt_yoymod9 over_rtgmod8 revt_yoymod10 over_rtgas1 , ///
	keep(over_rtg dltt at age emp tobinq xad xrd) ///
	order(over_rtg dltt at age emp tobinq xad xrd) ///
	s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC"))

	
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

local dv revt_pct
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

local dv revt_pct
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

local dv revt_pct
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

local dv revt_pct
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



///	COMPARE ALL CSRHUB CATEGORIES
qui xtreg F.revt_pct cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym , fe cluster(cusip_n)
est store m1
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym i.year, fe cluster(cusip_n)
est store m2
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt i.year, fe cluster(cusip_n)
est store m3
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at i.year, fe cluster(cusip_n)
est store m4
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age i.year, fe cluster(cusip_n)
est store m5
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp i.year, fe cluster(cusip_n)
est store m6
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad i.year, fe cluster(cusip_n)
est store m7
estadd local yearFE "Yes", replace
qui xtreg F.revt_pct cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
est store m8
estadd local yearFE "Yes", replace


***	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==.															/*	assumption	*/
replace xrd=0 if xrd==.															/*	assumption	*/

qui xtreg F.revt_pct cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
est store m9
restore 

***	Table
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9, ///
	keep(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(yearFE N N_g r2 r2_a aic, label("Year FEs" "Observations" "Firms" "R^2" "Adj'd R^2" "AIC"))	

***	Full model comparisons of CATEGORY-level CSRHub
esttab cmtymod8 cmtyas1 empmod8 empas1 enviromod8 enviroas1 govmod8 govas1 m8 m9 , ///
	keep(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(N N_g r2 r2_a aic, label("Observations" "Firms" "R^2" "Adj'd R^2" "AIC"))	
	
esttab cmtymod8 empmod8 enviromod8 govmod8 m8 cmtyas1 empas1 enviroas1 govas1 m9, ///
	keep(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	order(cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd) ///
	s(yearFEs N N_g r2 r2_a aic, label("Year FEs" "Observations" "Firms" "R^2" "Adj'd R^2" "AIC"))	

	
	
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

local dv revt_pct
local ivs "com_dev_phl_rtg_lym prod_rtg_lym humrts_supchain_rtg_lym comp_ben_rtg_lym div_lab_rtg_lym train_hlth_safe_rtg_lym enrgy_climchge_rtg_lym enviro_pol_rpt_rtg_lym resource_mgmt_rtg_lym board_rtg_lym ldrship_ethics_rtg_lym trans_report_rtg_lym"
local controls "dltt at age emp tobinq xad xrd"

foreach iv of local ivs {
	local vars ""
	display "`iv'"
	qui xtreg F.`dv' `iv', fe cluster(cusip_n)
	est store `iv'0
	qui estadd local yearFE "No", replace
	qui estadd local firmFE "Yes", replace

	qui xtreg F.`dv' `iv' i.year, fe cluster(cusip_n)
	est store `iv'1
	qui estadd local yearFE "Yes", replace
	qui estadd local firmFE "Yes", replace
	
	local vars ""
	local counter 2
	foreach control of local controls {
		*	Regression
		qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(cusip_n)
			
		*	Store results
		est store `iv'`counter'
		estadd local yearFE "Yes", replace
		estadd local firmFE "Yes", replace
		
		*	Increment
		local vars "`vars' `control'"
		local counter = `counter' + 1
	}

	*	Many xad and xrd observations are missing. Assume missing = 0.
	preserve
	replace xad=0 if xad==. & `iv'!=.											/*	assumption	*/
	replace xrd=0 if xrd==. & `iv'!=.											/*	assumption	*/

	qui xtreg F.`dv' `iv' `controls' i.year, fe cluster(cusip_n)
	est store `iv'as1
	qui estadd local yearFE "Yes", replace
	qui estadd local firmFE "Yes", replace
	restore 

	*	Table
	esttab `iv'* `iv'as1, ///
		keep(`iv' dltt at age emp tobinq xad xrd) ///
		order(`iv' dltt at age emp tobinq xad xrd) ///
		s(yearFE firmFE N N_g r2 aic, label("Year FEs" "Firm FEs" "Observations" "Firms" "R^2" "AIC"))
}


///	ALL SUBCATEGORIES
xtreg F.revt_pct com_dev_phl_rtg_lym prod_rtg_lym humrts_supchain_rtg_lym ///
	comp_ben_rtg_lym div_lab_rtg_lym train_hlth_safe_rtg_lym ///
	enrgy_climchge_rtg_lym enviro_pol_rpt_rtg_lym resource_mgmt_rtg_lym ///
	board_rtg_lym ldrship_ethics_rtg_lym trans_report_rtg_lym ///
	dltt at age emp tobinq xad xrd i.year, fe cluster(cusip_n)
	
preserve
replace xad=0 if xad==.
replace xrd=0 if xrd==.

xtreg F.revt_pct com_dev_phl_rtg_lym prod_rtg_lym humrts_supchain_rtg_lym ///
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





*/
						***===============================***
						*  PROPENSITY SCORE MATCHING MODELS	*
						*			BY YEAR					*
						***===============================***
*	Matching variables: dltt at age emp tobinq xad xrd
*	Using https://ssc.wisc.edu/sscc/pubs/stata_psmatch.htm

***	Propensity score estimation using teffects psmatch: trt1_sdw_pos
capt n drop ps2*
capt n drop mark
mark mark1
markout mark1 trt1_sdw_pos Frevt_yoy dltt at age emp tobinq
tab year trt1_sdw_pos if mark1==1

capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2009, ///
	osample(ps2009)
estimates store ps2009

capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2010 & ps2010==0
estimates store ps2010	

capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2011 & ps2011==0
estimates store ps2011

capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2012 & ps2012==0
estimates store ps2012

capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0
estimates store ps2013

capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2015, ///
	osample(ps2015)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2015 & ps2015==0
estimates store ps2015

capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2016, ///
	osample(ps2016)
estimates store ps2016

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015 ps2016, ///
	b se p ///
	stats(N)


***	Propensity score estimation using teffects psmatch: trt2_sdw_pos
capt n drop ps2*
capt n drop mark
mark mark1
markout mark1 trt2_sdw_pos Frevt_yoy dltt at age emp tobinq
tab year trt2_sdw_pos if mark1==1


capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2008, ///
	osample(ps2008)

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2009, ///
	osample(ps2009)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2009 & ps2009==0
estimates store ps2009

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2010 & ps2010==0
estimates store ps2010	

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2011 & ps2011==0
estimates store ps2011

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2012 & ps2012==0
estimates store ps2012

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0
estimates store ps2013

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2015, ///
	osample(ps2015)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2015 & ps2015==0
estimates store ps2015

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2016, ///
	osample(ps2016)
estimates store ps2016

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015 ps2016, ///
	b se p ///
	stats(N)





***	Propensity score estimation using teffects psmatch: trt2_sdw_neg
drop ps2*
drop mark
mark mark1
markout mark1 trt2_sdw_neg Frevt_yoy dltt at age emp tobinq
tab year trt2_sdw_neg if mark1==1

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2009, ///
	osample(ps2009)
estimates store ps2009

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2010 & ps2010==0
estimates store ps2010		

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
estimates store ps2011

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2012 & ps2012==0
estimates store ps2012

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0
estimates store ps2013

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2015, ///
	osample(ps2015)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2015 & ps2015==0
estimates store ps2015

capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2016, ///
	osample(ps2016)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2016 & ps2016 == 0
estimates store ps2016

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015 ps2016, ///
	b se p ///
	stats(N)
	
	
***	Propensity score estimation using teffects psmatch: trt3_sdw_pos
drop ps2*
drop mark
mark mark1
markout mark1 trt3_sdw_pos Frevt_yoy dltt at age emp tobinq
tab year trt3_sdw_pos if mark1==1



capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) if year == 2008, ///
	osample(ps2008)

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) if year == 2009, ///
	osample(ps2009)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) ///
	if year == 2009 & ps2009==0
estimates store ps2009

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) ///
	if year == 2010 & ps2010==0
estimates store ps2010	

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) ///
	if year == 2011 & ps2011==0
estimates store ps2011

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) ///
	if year == 2012 & ps2012==0
estimates store ps2012

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0
estimates store ps2013

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) if year == 2015, ///
	osample(ps2015)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) ///
	if year == 2015 & ps2015==0
estimates store ps2015

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq) if year == 2016, ///
	osample(ps2016)
estimates store ps2016

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015 ps2016, ///
	b se p ///
	stats(N)





***	Propensity score estimation using teffects psmatch: trt3_sdw_neg
drop ps2*
drop mark
mark mark1
markout mark1 trt3_sdw_neg Frevt_yoy dltt at age emp tobinq
tab year trt3_sdw_neg if mark1==1

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) if year == 2009, ///
	osample(ps2009)
estimates store ps2009

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) ///
	if year == 2010 & ps2010==0
estimates store ps2010		

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
estimates store ps2011

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) ///
	if year == 2012 & ps2012==0
estimates store ps2012

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0
estimates store ps2013

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) if year == 2015, ///
	osample(ps2015)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) ///
	if year == 2015 & ps2015==0
estimates store ps2015

capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) if year == 2016, ///
	osample(ps2016)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq) ///
	if year == 2016 & ps2016 == 0
estimates store ps2016

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015 ps2016, ///
	b se p ///
	stats(N)
	
	
	
	
	
	
						***===============================***
						*  PROPENSITY SCORE MATCHING MODELS	*
						*			BY ALL YEARS			*
						***===============================***
***	Generate firmyear variable
egen firmyear = group(cusip year)

***	Generate year-on-year revenue change
capt n gen Frevt_yoy = F.revt-revt
label var Frevt_yoy "Next year revt - current year revt"

///	PROPENSITY SCORE MATCHING

***	Positive

*	trt1_sdw_pos
capt n drop prop*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq sic2division), ///
	osample(prop1)

*	trt2_sdw_pos
drop prop*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq sic2division), ///
	osample(prop1)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq sic2division) ///
	if prop1 == 0

*	trt3_sdw_pos
drop prop*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq sic2division), ///
	osample(prop1)

	
***	Negative
*	trt1_sdw_neg
capt n drop prop*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq sic2division), ///
	osample(prop1)
	
*	trt2_sdw_neg 
drop prop*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq sic2division), ///
	osample(prop1)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq sic2division) ///
	if prop1 == 0

***	trt2_sdw_neg 
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq sic2division), ///
	osample(prop1)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq sic2division) ///
	if prop1 == 0

***	trt3_sdw_neg 
drop prop*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq sic2division), ///
	osample(prop1)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq sic2division) ///
	if prop1 == 0



	
	
	














						***===============================***
						*	NEAREST NEIGHBORS MATCHING		*
						***===============================***		
///	 NEAREST NEIGHBORS MATCHING WITH EXACT YEAR MATCH TO AVOID MATCHING FIRMS TOGETHER
teffects nnmatch (revtyoy2 dltt age emp tobinq) (trt2_sdw_pos), ///
	biasadj(dltt age emp tobinq) ematch(year) osample(ch1)

teffects nnmatch (revtyoy2 dltt age emp tobinq) (trt2_sdw_pos), ///
	biasadj(dltt age emp tobinq) ematch(year) osample(ch2)

teffects nnmatch (revtyoy2 dltt age emp tobinq) (trt2_sdw_pos) if ch1==0 & ch2==0, ///
	biasadj(dltt age emp tobinq) ematch(year) osample(ch3)

teffects nnmatch (revtyoy2 dltt age emp tobinq) (trt2_sdw_pos) if ch1==0 & ch2==0 & ch3==0, ///
	biasadj(dltt age emp tobinq) ematch(year)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

/*


	
						***===============================***
						*  CENTERING TREATED FIRMS IN TIME	*	
						***===============================***
///	LOAD DATA						
use data/csrhub-kld-cstat-year-level-with-treatment-variables.dta, clear
est clear

///	KEEP IN YEARS WITH CSRHUB AND CSTAT DATA
keep if revt!=.
keep if over_rtg!=.

/// SET PANEL
encode cusip, gen(cusip_n)
xtset cusip_n year, y

///	GENERATE YEAR-ON-YEAR REVENUE CHANGE
gen revt_yoy = revt - l.revt
label var revt_yoy "Year-on-year change in revenue (revt - previous year revt)" 

///	CENTER ON TREATMENT YEAR
***	Generate period variable
gen period = 0 if trt2_sdw_neg==1
label var period "Years since treatment"
bysort cusip_n: gen yeartreat = year if period == 0
bysort cusip_n: egen yeartreatmax = max(yeartreat)
replace period = year - yeartreatmax
drop yeartreat yeartreatmax


***	Visualize
*	Line
bysort period: egen meanrevt = mean(revt)
twoway (line meanrevt period, sort xline(0))

bysort period: egen medrevt = median(revt)
twoway (line medrevt period, sort xline(0))

*	Boxplot
graph box revt, over(period)


















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
