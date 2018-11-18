capt log close
log using logs\mediation-analysis-20181113.txt, text replace


				***=============================***
				***		RUN MEDIATION ANALYSIS	***
				***=============================***

				
***=============================================***
***		DATA FROM CHAPTER 2 DATA CREATION FILE	***
***=============================================***
///	LOAD DATA
use data\csrhub-kld-cstat-with-crosswalk-exact-stnd_firm-ym-matches-clean.dta, clear

///	ALL INDUSTRIES
*	Y = ni
*	X = over_rtg
*	M = net_kld
*mark medall
*markout medall ni over_rtg net_kld year debt rd ad

///		All industries: 	Net KLD strengths		No imputation of missing values

***	KLD Strengths
xtreg f12.ni over_rtg emp debt rd ad i.year, fe cluster(firm_n)
eststo m1_ni

xtreg net_kld_str over_rtg emp debt rd ad i.year, fe cluster(firm_n)
eststo m1_ni_kld

xtreg f12.ni over_rtg net_kld_str emp debt rd ad i.year, fe cluster(firm_n)
eststo m1_ni_med

estout m1_ni m1_ni_kld m1_ni_med, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	keep(over_rtg net_kld_str emp debt rd ad _cons) ///
	order(over_rtg net_kld_str emp debt rd ad _cons)

outreg2 [m1_ni m1_ni_kld m1_ni_med] using "tables-and-figures/ch3-ni-on-kld-str", excel ///
	stats(coef tstat) ///
	keep(over_rtg net_kld_str emp debt rd ad) ///
	sortvar(over_rtg net_kld_str emp debt rd ad) ///
	dec(2) fmt(f) ///
	alpha(.001, .01, .05) ///
	addtext(Firm FE, YES, Year FE, YES) ///
	replace	

	
***	All industries
***	Net KLD concerns
*Main relationship
xtreg ni over_rtg emp debt rd ad i.year, fe cluster(firm_n)
eststo m2_ni

*Mediator predicting independent variable
xtreg net_kld_con over_rtg emp debt rd ad i.year, fe cluster(firm_n)
eststo m2_net_kld

*Mediation analysis
xtreg ni over_rtg net_kld_con emp debt rd ad i.year, fe cluster(firm_n)
eststo m2_med

estout m2_ni m2_net_kld m2_med, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	keep(over_rtg net_kld_con emp debt rd ad _cons) ///
	order(over_rtg net_kld_con emp debt rd ad _cons)
	
outreg2 [m2_ni m2_net_kld m2_med] using "tables-and-figures/ch3-ni-on-kld-con", excel ///
	stats(coef tstat) ///
	keep(over_rtg net_kld_con emp debt rd ad) ///
	sortvar(over_rtg net_kld_con emp debt rd ad) ///
	dec(2) fmt(f) ///
	alpha(.001, .01, .05) ///
	addtext(Firm FE, YES, Year FE, YES) ///
	replace		
	
///	WITHIN-BETWEEN RANDOM EFFECTS MODELS
foreach variable in net_kld_str net_kld_con over_rtg emp debt rd ad {
	bysort firm_n: egen `variable'_m=mean(`variable')
	bysort firm_n: gen `variable'_dm=`variable'-`variable'_m
}


*** All industries
***	Net KLD strengths
xtreg ni over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, re cluster(firm_n) base

xtreg net_kld_str over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, re cluster(firm_n) base

xtreg ni over_rtg_dm net_kld_str_dm over_rtg_m net_kld_str_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, re cluster(firm_n) base


***	Control 2-digit NAICS
gen naics2=substr(naics,1,2)
destring(naics2), gen(naics_2)
replace naics_2=31 if naics_2==32 | naics_2==33									/*	Manufacturing */
replace naics_2=44 if naics_2==45												/*	Retail Trade	*/
replace naics_2=48 if naics_2==49												/*	Transport and Warehousing	*/

fvset base 51 naics_2

*	Net KLD strengths
xtreg ni over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nis1

xtreg net_kld_str over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nis2

xtreg ni over_rtg_dm net_kld_str_dm over_rtg_m net_kld_str_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nis3

*	Net KLD concerns
xtreg ni over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nic1

xtreg net_kld_con over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nic2

xtreg ni over_rtg_dm net_kld_con_dm over_rtg_m net_kld_con_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nic3


*	Regression of net income on CSRHub rating
estout nis1 nic1, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	order(over* net*)

*	Regression of CSRHub rating on KLD strengths or concerns
estout nis2 nic2, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	order(over* net*)

*	Regression of net income on CSRHub rating and KLD strengths or concerns
estout nis1 nic1 nis3 nic3, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	order(over* net*)

*	Regression of net income on CSRHub rating and KLD strengths and KLD concerns
xtreg ni over_rtg_dm net_kld_str_dm net_kld_con_dm over_rtg_m net_kld_str_m net_kld_con_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nistrcon










***=========================================================***
*		DATA FROM CLEAN-ALL-CSTAT-VARIABLES-FROM-CUSIPS.DO	  *
***=========================================================***
use data/csrhub-kld-cstat-matched-on-cusip.dta, clear

***	Descriptive analysis
corr revt ni tobinq roa net_kld_str net_kld_con over_rtg, means
pwcorr revt ni tobinq roa net_kld_str net_kld_con over_rtg, p(.05)
graph matrix net_kld_str net_kld_con over_rtg revt ni tobinq roa, half


///	Main CFP - CSR performance
set scheme plotplainblind


***	Univariate analysis
*	Contemporaneous
foreach dv of varlist sale ni tobinq roa {
	
	foreach iv of varlist net_kld_str net_kld_con over_rtg {
		
		xtreg `dv' `iv', fe cluster(cusip_n)
	}
}

*	Lagged CSR
foreach dv of varlist revt ni tobinq roa {

	foreach iv of varlist net_kld_str net_kld_con over_rtg {

		xtreg `dv' L12.`iv', fe cluster(cusip_n)
		
	}
}

///	Barron & Kinny Mediation Analysis

***	All independent variables lagged 12 months by regressing 12-month leading DV.
foreach dv of varlist revt ni tobinq roa {

	foreach iv of varlist net_kld_str net_kld_con {

		xtreg f12.`dv' over_rtg emp debt rd ad i.year, fe cluster(cusip_n)
		eststo `dv'_m1
		
		xtreg `iv' over_rtg emp debt rd ad i.year, fe cluster(cusip_n)
		eststo `dv'_m2
		
		xtreg f12.`dv' over_rtg `iv' emp debt rd ad i.year, fe cluster(cusip_n)
		eststo `dv'_m3

		estout `dv'_m1 `dv'_m2 `dv'_m3, cells(b(star fmt(%9.3f)) z(par)) ///
		stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
		labels("N" "Firms" "Adj. R^2"))      ///
		legend collabels(none) ///
		keep(over_rtg `iv' emp debt rd ad _cons) ///
		order(over_rtg `iv' emp debt rd ad _cons) ///
		title("DV: 1-year leading `dv'. Fixed effects regression on `iv'. Errors clustered by CUSIP.")
	}
}


***	KLD and CSRHub lagged 12 months. Other variables contemporaneous with DV.
foreach dv of varlist revt ni tobinq roa {

	foreach iv of varlist net_kld_str net_kld_con {

		xtreg `dv' l12.over_rtg emp debt rd ad i.year, fe cluster(cusip_n)
		eststo `dv'_m1
		
		xtreg l12.`iv' l12.over_rtg emp debt rd ad i.year, fe cluster(cusip_n)
		eststo `dv'_m2
		
		xtreg `dv' l12.over_rtg l12.`iv' emp debt rd ad i.year, fe cluster(cusip_n)
		eststo `dv'_m3

		estout `dv'_m1 `dv'_m2 `dv'_m3, cells(b(star fmt(%9.3f)) z(par)) ///
		stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
		labels("N" "Firms" "Adj. R^2"))      ///
		legend collabels(none) ///
		keep(L12.over_rtg L12.`iv' emp debt rd ad _cons) ///
		order(L12.over_rtg L12.`iv' emp debt rd ad _cons) ///
		title("Fixed effects regression of `dv' on `iv'. CSR variables lagged 12 months. Errors clustered by CUSIP.")
	}
}



	
***	WITHIN-BETWEEN RANDOM EFFECTS MODELS

*** All industries
***	Net KLD strengths
xtreg f12.revt over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, ///
	re cluster(cusip_n) base

xtreg net_kld_str over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, ///
	re cluster(cusip_n) base

xtreg f12.revt over_rtg_dm net_kld_str_dm over_rtg_m net_kld_str_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, ///
	re cluster(cusip_n) base


***	Control 2-digit NAICS
gen naics2=substr(naics,1,2)
destring(naics2), gen(naics_2)
replace naics_2=31 if naics_2==32 | naics_2==33									/*	Manufacturing */
replace naics_2=44 if naics_2==45												/*	Retail Trade	*/
replace naics_2=48 if naics_2==49												/*	Transport and Warehousing	*/

fvset base 51 naics_2

*	Net KLD strengths
xtreg f12.revt over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo revts1

xtreg net_kld_str over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo revts2

xtreg f12.revt over_rtg_dm net_kld_str_dm over_rtg_m net_kld_str_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo revts3

*	Net KLD concerns
xtreg revt over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re cluster(cusip_n) base
eststo revtc1

xtreg net_kld_con over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re cluster(cusip_n) base
eststo revtc2

xtreg revt over_rtg_dm net_kld_con_dm over_rtg_m net_kld_con_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re cluster(cusip_n) base
eststo revtc3


*	Regression of net income on CSRHub rating
estout revts1 revtc1, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	order(over* net*)

*	Regression of CSRHub rating on KLD strengths or concerns
estout revts2 revtc2, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	order(over* net*)

*	Regression of net income on CSRHub rating and KLD strengths or concerns
estout revts1 revtc1 revts3 revtc3, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	order(over* net*)

*	Regression of net income on CSRHub rating and KLD strengths and KLD concerns
xtreg revt over_rtg_dm net_kld_str_dm net_kld_con_dm over_rtg_m net_kld_str_m net_kld_con_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo revtstrcon







*************************
*	DV: Net income 		*
*************************
/*
*	Y = ni
*	X = over_rtg
*	M = net_kld
*/

///	Load data
use data/csrhub-kld-cstat-matched-on-cusip.dta, clear

*Generate random effects within-between variables
foreach variable in net_kld_str net_kld_con over_rtg emp debt rd ad {
	bysort cusip_n: egen `variable'_m=mean(`variable')
	bysort cusip_n: gen `variable'_dm=`variable'-`variable'_m
}
*Generate 2-digit NAICS for control variable
gen naics2=substr(naics,1,2)
destring(naics2), gen(naics_2)
replace naics_2=31 if naics_2==32 | naics_2==33									/*	Manufacturing */
replace naics_2=44 if naics_2==45												/*	Retail Trade	*/
replace naics_2=48 if naics_2==49												/*	Transport and Warehousing	*/

fvset base 51 naics_2





///	All industries: 	Net KLD strengths

***	Fixed effects regression
xtreg f12.ni over_rtg emp debt rd ad i.year, fe cluster(cusip_n)
eststo m1_ni

xtreg net_kld_str over_rtg emp debt rd ad i.year, fe cluster(cusip_n)
eststo m1_net_kld

xtreg f12.ni over_rtg net_kld_str emp debt rd ad i.year, fe cluster(cusip_n)
eststo m1_med

estout m1_ni m1_net_kld m1_med, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	keep(over_rtg net_kld_str emp debt rd ad _cons) ///
	order(over_rtg net_kld_str emp debt rd ad _cons)

*** Random effects within-between models
*	Main relationships
xtreg ni over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, /// 
	re cluster(cusip_n) base
eststo ni_m

xtreg net_kld_str over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, ///
	re cluster(cusip_n) base
eststo kld_str_m
	
xtreg ni over_rtg_dm net_kld_str_dm over_rtg_m net_kld_str_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, ///
	re cluster(cusip_n) base
eststo ni_mod_m

*	Controlling for industry
qui xtreg f12.ni over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo ni

qui xtreg net_kld_str over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo kld_str

qui xtreg f12.ni over_rtg_dm net_kld_str_dm over_rtg_m net_kld_str_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo ni_mod

estout ni kld_str ni_mod m1_med, cells(b(star fmt(%9.3f)) z(par))	///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	keep(over_rtg_dm net_kld_str_dm over_rtg_m net_kld_str_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m) ///
	order(over_rtg_dm net_kld_str_dm over_rtg_m net_kld_str_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m)



///	All industries: 	Net KLD concerns

*** Fixed effects regression
xtreg ni over_rtg emp debt rd ad i.year, fe cluster(cusip_n)
eststo m2_ni

xtreg net_kld_con over_rtg emp debt rd ad i.year, fe cluster(cusip_n)
eststo m2_net_kld

xtreg ni over_rtg net_kld_con emp debt rd ad i.year, fe cluster(cusip_n)
eststo m2_med

estout m2_ni m2_net_kld m2_med, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	keep(over_rtg net_kld_con emp debt rd ad _cons) ///
	order(over_rtg net_kld_con emp debt rd ad _cons)
	
*** Random effects within-between models
*	Main relationships
xtreg ni over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, re cluster(cusip_n) base
xtreg net_kld_con over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, re cluster(cusip_n) base
xtreg ni over_rtg_dm net_kld_con_dm over_rtg_m net_kld_con_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, re cluster(cusip_n) base

*	Controlling for industry
xtreg ni over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nic1

xtreg net_kld_con over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nic2

xtreg ni over_rtg_dm net_kld_con_dm over_rtg_m net_kld_con_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nic3
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	


















capt log close
