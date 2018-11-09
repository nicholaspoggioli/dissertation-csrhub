capt log close
log using logs\mediation-analysis-2.txt, text replace


				***=============================***
				***		RUN MEDIATION ANALYSIS	***
				***		 WITH NEW DATASET		***
				***=============================***
///	LOAD DATA
use data\csrhub-kld-cstat-with-crosswalk-exact-stnd_firm-ym-matches-clean.dta, clear

///	ALL INDUSTRIES
*	Y = ni
*	X = over_rtg
*	M = net_kld
*mark medall
*markout medall ni over_rtg net_kld year debt rd ad

///	BARON AND KINNY MEDIATION ANALYSIS

***	All industries
***	Net KLD strengths
*Main relationship
xtreg ni over_rtg emp debt rd ad i.year, fe cluster(firm_n)
eststo m1_ni

*Mediator predicting independent variable
xtreg net_kld_str over_rtg emp debt rd ad i.year, fe cluster(firm_n)
eststo m1_net_kld

*Mediation analysis
xtreg ni over_rtg net_kld_str emp debt rd ad i.year, fe cluster(firm_n)
eststo m1_med

estout m1_ni m1_net_kld m1_med, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	keep(over_rtg net_kld_str emp debt rd ad _cons) ///
	order(over_rtg net_kld_str emp debt rd ad _cons)
	

	
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










capt log close
