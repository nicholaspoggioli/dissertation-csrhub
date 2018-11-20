capt log close
log using logs\dissertation-chapter-3-analysis.txt, text replace


				***=============================***
				***		RUN MEDIATION ANALYSIS	***
				***=============================***

/*				
***=============================================***
***		DATA FROM CHAPTER 2 DATA CREATION FILE	***
***		Uses string matching on firm name to match datasets
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

*	Set base industry as retail trade
fvset base 44 naics_2

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


*/


















***===========================================================***
*		DATA FROM CLEAN-ALL-CSTAT-VARIABLES-FROM-CUSIPS.DO	  	*
*		Uses exact matching on CUSIPs to match datasets			*
***===========================================================***
use data/csrhub-kld-cstat-matched-on-cusip.dta, clear

***	Descriptive analysis
d
corr revt ni tobinq roa net_kld_str net_kld_con over_rtg, means

///	Main CFP - CSR performance

***	Contemporaneous 
*	CSRHub
eststo clear
foreach dv of varlist revt ni tobinq roa {
	
	foreach iv of varlist net_kld_str net_kld_con over_rtg {
		
		qui xtreg `dv' `iv', fe cluster(cusip_n)
		eststo reg1_`dv'
		qui xtreg `dv' `iv' i.year, fe cluster(cusip_n)
		eststo reg1yr_`dv'
	}
}

estout *, cells(b(star fmt(%9.3f)) z(par)) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
drop(_cons) ///
indicate(Year FEs = *.year) ///
title("Fixed effects regressions. Panel is CUSIP-yearmonth. Errors clustered by CUSIP.")

*	KLD
eststo clear
foreach dv of varlist revt ni tobinq roa {
		
	xtreg `dv' net_kld_str net_kld_con, fe cluster(cusip_n)
	eststo reg2_`dv'
	xtreg `dv' net_kld_str net_kld_con i.year, fe cluster(cusip_n)
	eststo reg2yr_`dv'
	
}

estout *, cells(b(star fmt(%9.3f)) z(par)) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
drop(_cons) ///
indicate(Year FEs = *.year) ///
title("Fixed effects regressions. Panel is CUSIP-yearmonth. Errors clustered by CUSIP.")


***	Lagged independent variables
*	CSRHub
xtset
eststo clear
foreach dv of varlist revt ni tobinq roa {
	
	foreach iv of varlist net_kld_str net_kld_con over_rtg {
		
		qui xtreg `dv' L12.`iv', fe cluster(cusip_n)
		eststo reg3_`dv'
		qui xtreg `dv' L12.`iv' i.year, fe cluster(cusip_n)
		eststo reg3yr_`dv'
	}
}

estout *, cells(b(star fmt(%9.3f)) z(par)) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
drop(_cons) ///
indicate(Year FEs = *.year) ///
title("Fixed effects regression on lagged CSR. Panel is CUSIP-yearmonth. Errors clustered by CUSIP.")
		
eststo clear

*	KLD
xtset
eststo clear
foreach dv of varlist revt ni tobinq roa {
		
	qui xtreg `dv' L12.net_kld_str L12.net_kld_con, fe cluster(cusip_n)
	eststo reg2_`dv'
	qui xtreg `dv' L12.net_kld_str L12.net_kld_con i.year, fe cluster(cusip_n)
	eststo reg2yr_`dv'
	
}

estout *, cells(b(star fmt(%9.3f)) z(par)) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
drop(_cons) ///
indicate(Year FEs = *.year) ///
title("Fixed effects regressions. Panel is CUSIP-year. Errors clustered by CUSIP.")

eststo clear


***	Random effects within-between models
*	CSRHub contemporaneous
xtset
foreach dv of varlist revt ni tobinq roa {
	
	qui xtreg `dv' over_rtg_dm over_rtg_m, re cluster(cusip_n)
	eststo rewb1_`dv'_1
	qui xtreg `dv' over_rtg_dm over_rtg_m i.year, re cluster(cusip_n)
	eststo rewb1_`dv'_2
}

estout rewb1*, cells(b(star fmt(%9.3f)) z(par)) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
drop(_cons) ///
indicate(Year FEs = *.year) ///
title("Random effects within-between regressions. Panel is CUSIP-yearmonth. Errors clustered by CUSIP.")
		

*	CSRHub lagged
xtset
foreach dv of varlist revt ni tobinq roa {
	
	qui xtreg `dv' L12.over_rtg_dm L12.over_rtg_m, re cluster(cusip_n)
	eststo rewb2_`dv'_1
	qui xtreg `dv' L12.over_rtg_dm L12.over_rtg_m i.year, re cluster(cusip_n)
	eststo rewb2_`dv'_2
}

estout rewb2*, cells(b(star fmt(%9.3f)) z(par)) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
drop(_cons) ///
indicate(Year FEs = *.year) ///
title("Random effects within-between regressions. Panel is CUSIP-yearmonth. Errors clustered by CUSIP.")
		

*	KLD contemporaneous
xtset
foreach dv of varlist revt ni tobinq roa {
	
	qui xtreg `dv' net_kld_str_dm net_kld_con_dm net_kld_str_m net_kld_con_m, re cluster(cusip_n)
	eststo rewb3_`dv'_1
	qui xtreg `dv' net_kld_str_dm net_kld_con_dm net_kld_str_m net_kld_con_m i.year, re cluster(cusip_n)
	eststo rewb3_`dv'_2
}

estout rewb3*, cells(b(star fmt(%9.3f)) z(par)) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
drop(_cons) ///
indicate(Year FEs = *.year) ///
title("Random effects within-between regressions. Panel is CUSIP-yearmonth. Errors clustered by CUSIP.")
		

*	KLD lagged
xtset
foreach dv of varlist revt ni tobinq roa {
	
	qui xtreg `dv' L12.net_kld_str_dm L12.net_kld_con_dm L12.net_kld_str_m L12.net_kld_con_m, re cluster(cusip_n)
	eststo rewb4_`dv'_1
	qui xtreg `dv' L12.net_kld_str_dm L12.net_kld_con_dm L12.net_kld_str_m L12.net_kld_con_m i.year, re cluster(cusip_n)
	eststo rewb4_`dv'_2
}

estout rewb4*, cells(b(star fmt(%9.3f)) z(par)) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
drop(_cons) ///
indicate(Year FEs = *.year) ///
title("Random effects within-between regressions. Panel is CUSIP-yearmonth. Errors clustered by CUSIP.")


***	Compare contemporaneous and lagged KLD
estout rewb3_r* rewb4_r*, cells(b(star) z(par fmt(%9.4f))) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
drop(_cons) ///
indicate(Year FEs = *.year) ///
title("Random effects within-between regressions. Panel is CUSIP-yearmonth. Errors clustered by CUSIP.")




///	Introducing control variables

/***	1) Barnett and Salomon (2012) model CFP -> f(CSP) with control variables:
		a.	Firm size		(CSTAT EMP)
		b.	Debt 			(CSTAT DLTT / AT)
		c.	Ad intensity	(CSTAT XAD / SALE)		Missing assumed = 0
		d.	R&D intensity	(CSTAT XRD / SALE)
*/

***	Lagged B&S model, without lagged DV because independent variables are lagged
drop fm
mark fm
markout fm revt ni tobinq roa l12.net_kld_str l12.net_kld_con l12.over_rtg l12.emp l12.debt l12.ad l12.rd year


local d = 0
foreach dv of varlist revt ni tobinq roa {
	local d = `d' + 1
	local i = 0
	foreach iv of varlist net_kld_str net_kld_con over_rtg {
		local i = `i' + 1
	
		qui xtreg `dv' l12.`iv' if fm==1, fe cluster(cusip_n)
		eststo fm_`d'_`i'_1

		qui xtreg `dv' l12.`iv' i.year if fm==1, fe cluster(cusip_n)
		eststo fm_`d'_`i'_1

		qui xtreg `dv' l12.`iv' l12.emp i.year if fm==1, fe cluster(cusip_n)
		eststo fm_`d'_`i'_3

		qui xtreg `dv' l12.`iv' l12.emp l12.debt i.year if fm==1, fe cluster(cusip_n)
		eststo fm_`d'_`i'_4

		qui xtreg `dv' l12.`iv' l12.emp l12.debt l12.ad i.year if fm==1, fe cluster(cusip_n)
		eststo fm_`d'_`i'_5

		qui xtreg `dv' l12.`iv' l12.emp l12.debt l12.ad l12.rd i.year if fm==1, fe cluster(cusip_n)
		eststo fm_`d'_`i'_6
	}
}


*	Compare model progression by DV for net_kld_str
forvalues model = 1/4 {
	estout fm_`model'_1*, cells(b(star) z(par fmt(%9.4f))) ///
	stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
	labels("N" "CUSIPs"))      ///
	legend collabels(none) ///
	mlabel(,dep) ///
	drop(_cons) ///
	indicate(Year FEs = *.year) ///
	title("Fixed effects regressions. Panel: CUSIP-yearmonth. Errors clustered by CUSIP.")
}

*	Compare model progression by DV for net_kld_con
forvalues model = 1/4 {
	estout fm_`model'_2*, cells(b(star) z(par fmt(%9.4f))) ///
	stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
	labels("N" "CUSIPs"))      ///
	legend collabels(none) ///
	mlabel(,dep) ///
	drop(_cons) ///
	indicate(Year FEs = *.year) ///
	title("Fixed effects regressions. Panel: CUSIP-yearmonth. Errors clustered by CUSIP.")
}

*	Compare model progression by DV for over_rtg
forvalues model = 1/4 {
	estout fm_`model'_3*, cells(b(star) z(par fmt(%9.4f))) ///
	stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
	labels("N" "CUSIPs"))      ///
	legend collabels(none) ///
	mlabel(,dep) ///
	drop(_cons) ///
	indicate(Year FEs = *.year) ///
	title("Fixed effects regressions. Panel: CUSIP-yearmonth. Errors clustered by CUSIP.")
}


*	Compare full models for each DV
estout fm_1*6 fm_2*6 fm_3*6 fm_4*6, cells(b(star) z(par fmt(%9.4f))) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
order(*net_kld_str *net_kld_con *over_rtg) ///
drop(_cons) ///
indicate(Year FEs = *.year) ///
title("Fixed effects regressions. Panel: CUSIP-yearmonth. Errors clustered by CUSIP.")






/***	1) 	Barnett and Salomon (2012) model CFP -> f(CSP) with control variables:
			a.	Firm size		(CSTAT EMP)
			b.	Debt 			(CSTAT DLTT / AT)
			c.	Ad intensity	(CSTAT XAD / SALE)		Missing assumed = 0
			d.	R&D intensity	(CSTAT XRD / SALE)
		
		2)	Variables from other studies of the CFP -> f (CSR) model
			e.	Industry
			f.	Firm age
			g.	Industry average
				i.		Advertising intensity
				ii.		Firm size
				iii.	Risk
			h.	CapEx / Assets
			i.	CSP		(Environment)
			j.	CSP		(ESG)
			k.	CSP		(Governance)
			l.	CSP		(Social)
			m.	Dividends
			n.	Insider ownership and square of this term
			o.	Leverage
			p.	Liquidity
			q.	Positive earnings in previous year
*/






























///	CSP AND STAKEHOLDER MANAGEMENT

***	Direct relationship: contemporaneous
xtset

foreach dv of varlist net_kld_str net_kld_con {
	qui xtreg `dv' over_rtg_dm over_rtg_m, re cluster(cusip_n)
	eststo rewb5_`dv'_1
	qui xtreg `dv' over_rtg_dm over_rtg_m i.year, re cluster(cusip_n)
	eststo rewb5_`dv'_2
}

estout rewb5*, cells(b(star fmt(%9.3f)) z(par)) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
drop(_cons) ///
indicate(Year FEs = *.year) ///
title("Random effects within-between regressions. Panel is CUSIP-yearmonth. Errors clustered by CUSIP.")

















///	INDUSTRY RELATIONSHIPS

*	Generate 2-digit NAICS
gen naics2=substr(naics,1,2)
destring(naics2), gen(naics_2)
replace naics_2=31 if naics_2==32 | naics_2==33									/*	Manufacturing */
replace naics_2=44 if naics_2==45												/*	Retail Trade	*/
replace naics_2=48 if naics_2==49												/*	Transport and Warehousing	*/

*	Set base industry as retail trade
fvset base 44 naics_2

***	Industry dummies
bysort cusip_n: egen naics_2_m = mean(naics_2)
by cusip_n: gen naics_2_dm = naics_2 - naics_2_m
label var naics_2_m "CUSIP-level mean naics_2"
label var naics_2_dm "CUSIP-level de-meaned naics_2 (always 0 unless firm moves sectors)"

*	Set base industry as retail trade
fvset base 44 naics_2_m


xtset 
foreach dv of varlist revt ni tobinq roa {
	
	qui xtreg `dv' i.naics_2_dm i.naics_2_m, re cluster(cusip_n) base
	eststo rewb6_`dv'_1
	qui xtreg `dv' i.naics_2_dm i.naics_2_m i.year, re cluster(cusip_n) base
	eststo rewb6_`dv'_2
}

estout rewb6*, cells(b(star fmt(%9.3f)) z(par)) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
drop(_cons) ///
title("Random effects regressions. Panel is CUSIP-yearmonth. Errors clustered by CUSIP.")


xtset 
foreach dv of varlist over_rtg net_kld_str net_kld_con {
	
	qui xtreg `dv' i.naics_2_dm i.naics_2_m, re cluster(cusip_n) base
	eststo rewb7_`dv'_1
	qui xtreg `dv' i.naics_2_dm i.naics_2_m i.year, re cluster(cusip_n) base
	eststo rewb7_`dv'_2
}

estout rewb7*, cells(b(star fmt(%9.3f)) z(par)) ///
stats(N  N_g r2_o r2_w r2_b, fmt(%9.0g %9.0g %9.4g %9.4g %9.4g) ///
labels("N" "CUSIPs"))      ///
legend collabels(none) ///
mlabel(,dep) ///
drop(_cons) ///
title("Random effects regressions. Panel is CUSIP-yearmonth. Errors clustered by CUSIP.")







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

	}
}

estout revt* ni* tobinq* roa*, cells(b(star fmt(%9.3f)) z(par)) ///
stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) labels("N" "Firms" "Adj. R^2"))      ///
legend collabels(none) ///
keep(over_rtg net* emp debt rd ad _cons) ///
order(over_rtg net* emp debt rd ad _cons) ///
mlabel(,dep) ///
title("Fixed effects regressions. Panel CUSIP-yearmonth. Errors clustered by CUSIP.")


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

*	Set base industry as retail trade
fvset base 44 naics_2





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
