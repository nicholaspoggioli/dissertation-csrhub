///	LOG
*capt n log close
*log using code/logs/20190219-yearly-analysis.txt, text

***===================***
*	CHAPTER 2 ANALYSIS	*
***===================***
/*	WORKFLOW
	1.	Treatment Variable Descriptive Statistics
	2.	Propensity Score Matching: All Years
	3.	Propensity Score Matching: Individual Years
	4.	Difference-in-Differences
	5.	Fixed Effects Estimation
*/

///	SET ENVIRONMENT
clear all
set scheme plotplainblind

///	LOAD DATA
use data/matched-csrhub-cstat-2008-2017, clear

***	Drop unneeded variables
drop xrdp


						***===============================***
						*									*
						*  			 ASSUMPTIONS			*
						*									*
						***===============================***
///	ADVERTISING (CSTAT GLOBAL DOES NOT CONTAIN AN ADVERTISING VARIABLE)
gen xad_original=xad
label var xad_original "(CSTAT) xad before assuming missing=0"
replace xad=0 if xad==. & in_cstatn==1
gen assume_xad=(xad_original==.) & in_cstatn==1
label var assume_xad "(CSTAT) =1 if missing xad assumed 0"

///	R&D
gen xrd_original=xrd
label var xad_original "(CSTAT) xrd before assuming missing=0"
replace xrd=0 if xrd==. & in_cstatn==1
gen assume_xrd=(xrd_original==.) & in_cstatn==1
label var assume_xrd "(CSTAT) =1 if missing xrd assumed 0"



						***===============================***
						*									*
						*  		  GENERATE VARIABLES		*
						*									*
						***===============================***	
///	REVENUE GROWTH VARIABLES
***	Current year minus previous year
gen revenue_yoy = revenue - l.revenue
label var revenue_yoy "Year-on-year change in revenue (revenue - previous year revenue)"

***	Next year minus current year
gen Frevenue_yoy = F.revenue-revenue
label var Frevenue_yoy "Next year revenue - current year revenue"

***	Percent change in sales, current to next year
gen revenue_pct = (revenue_yoy/L.revenue)*100
label var revenue_pct "Percent change in revenue, current to previous year"

						***===============================***
						*									*
						*  TREATMENT VARIABLE DESCRIPTIVES	*
						*									*
						***===============================***	
///	DESCRIPTIVE STATISTICS
***	Treatment variables
foreach var of varlist trt3_sdw_pos trt3_sdw_neg trt2_sdw_pos trt2_sdw_neg ///
	trt1_sdw_pos trt1_sdw_neg {
		display ""
		display ""
		display "`var'"
		tab `var'
}

foreach var of varlist trt3_sdw_pos trt3_sdw_neg trt2_sdw_pos trt2_sdw_neg ///
	trt1_sdw_pos trt1_sdw_neg {
		tab year `var'
}


						***===========================***
						*								*
						*	PROPENSITY SCORE MATCHING 	*
						*		ALL YEARS COMBINED		*
						*								*
						***===========================***
/*		Propensity model: treatment = f(dltt at age emp tobinq)	*/
///	3 STANDARD DEVIATION
***	Positive
forvalues neighbors = 1/10 {
	capt n drop ps*
	capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq), ///
		osample(ps) nneighbor(`neighbors') first
	capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq) ///
		if ps==0, nneighbor(`neighbors') first
}

***	Negative
forvalues neighbors = 1/10 {
	capt n drop ps
	capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq), ///
		osample(ps) nneighbor(`neighbors')
	capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq) ///
		if ps==0, nneighbor(`neighbors')
}

///	2 STANDARD DEVIATIONS
***	Positive
forvalues neighbors = 1/10 {
	capt n drop ps*
	capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq), ///
		osample(ps) nneighbor(`neighbors')
	capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) ///
		if ps==0, nneighbor(`neighbors')
}

***	Negative
forvalues neighbors = 1/10 {
	capt n drop ps
	capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq), ///
		osample(ps) nneighbor(`neighbors')
	capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) ///
		if ps==0, nneighbor(`neighbors')
}

///	1 STANDARD DEVIATION
***	Positive
forvalues neighbors = 1/10 {
	capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq), ///
		nneighbor(`neighbors')
}

***	Negative
forvalues neighbors = 1/10 {
	capt n drop ps
	capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq), ///
		osample(ps) nneighbor(`neighbors')
	capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) ///
		if ps==0, nneighbor(`neighbors')
}



						***===========================***
						*								*
						*	PROPENSITY SCORE MATCHING 	*
						*		INDIVIDUAL YEARS		*
						*		DV:	Revenue	Level		*
						*								*
						***===========================***	
///	3 STANDARD DEVIATIONS
***	3 Standard Deviation Positive
*	Insufficient number of treatment events for several years
capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2009, osample(ps2009)
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2009 & ps2009==0, osample(ps2009_2)
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2009 & ps2009==0 & ps2009_2==0
estimates store ps2009

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2010, osample(ps2010)
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2010 & ps2010==0
estimates store ps2010

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2011, osample(ps2011)
estimates store ps2011

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2012, osample(ps2012)
estimates store ps2012

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2013, osample(ps2013)
estimates store ps2013

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2014, osample(ps2014)
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2014 & ps2014==0, osample(ps2014_2)
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2014 & ps2014==0 & ps2014_2==0
estimates store ps2014

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2015, osample(ps2015)
estimates store ps2015

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2016, osample(ps2016)
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2016 & ps2016==0, osample(ps2016_2)
capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2016 & ps2016==0 & ps2016_2==0
estimates store ps2016

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015 ps2016, ///
	b se p ///
	stats(N)
	
***	3 Standard Deviation Negative
*	Insufficient number of treatment events for several years
est sto clear

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2009, osample(ps2009)
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2009 & ps2009==0, osample(ps2009_2)
estimates store ps2009

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2010, osample(ps2010)
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2010 & ps2010==0
estimates store ps2010

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2011, osample(ps2011)
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2011 & ps2011==0, osample(ps2011_2)
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2011 & ps2011==0 & ps2011_2==0
estimates store ps2011

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2012, osample(ps2012)
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2012 & ps2012==0, osample(ps2012_2)
estimates store ps2012

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2013, osample(ps2013)
estimates store ps2013

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2014, osample(ps2014)
estimates store ps2014

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2015, osample(ps2015)
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2015 & ps2015==0, osample(ps2015_2)
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2015 & ps2015==0 & ps2015_2==0
estimates store ps2015

capt n drop ps2*
capt n teffects psmatch (revt) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2016, osample(ps2016)
estimates store ps2016

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015 ps2016, ///
	b se p ///
	stats(N)



	
///	2 STANDARD DEVIATIONS
***	2 Standard Deviation Positive
est sto clear

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2009
estimates store ps2009

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
estimates store ps2010	

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2011 & ps2011==0
estimates store ps2011

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2012 & ps2012==0
estimates store ps2012

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0
estimates store ps2013

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) if year == 2015, ///
	osample(ps2015)
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2015 & ps2015==0
estimates store ps2015

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_pos dltt at age emp tobinq) if year == 2016, ///
	osample(ps2016)
estimates store ps2016

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015 ps2016, ///
	b se p ///
	stats(N)
	

***	2 Standard Deviation Negative
est sto clear

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) if year == 2009, ///
	osample(ps2009)
estimates store ps2009

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2010 & ps2010==0
estimates store ps2010		

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
estimates store ps2011

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2012 & ps2012==0
estimates store ps2012

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0, osample(ps2013_2)
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0 & ps2013_2==0
estimates store ps2013

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) if year == 2015, ///
	osample(ps2015)
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2015 & ps2015==0
estimates store ps2015

capt n drop ps2*
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) if year == 2016, ///
	osample(ps2016)
capt n teffects psmatch (revt) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2016 & ps2016 == 0
estimates store ps2016

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015 ps2016, ///
	b se p ///
	stats(N)




///	1 STANDARD DEVIATION
***	1 Standard Deviation Positive
est sto clear

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2009
estimates store ps2009

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
estimates store ps2010	

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2011 & ps2011==0
estimates store ps2011

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2012 & ps2012==0
estimates store ps2012

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0
estimates store ps2013

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) if year == 2015, ///
	osample(ps2015)
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2015 & ps2015==0
estimates store ps2015

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) if year == 2016, ///
	osample(ps2016)
capt n teffects psmatch (revt) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2016 & ps2016==0
estimates store ps2016

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015 ps2016, ///
	b se p ///
	stats(N)
	

***	1 Standard Deviation Negative
est sto clear

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) if year == 2009, ///
	osample(ps2009)
estimates store ps2009

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) ///
	if year == 2010 & ps2010==0
estimates store ps2010		

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) ///
	if year == 2011 & ps2011==0
estimates store ps2011

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
estimates store ps2012

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0, osample(ps2013_2)
estimates store ps2013

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) if year == 2015, ///
	osample(ps2015)
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) ///
	if year == 2015 & ps2015==0
estimates store ps2015

capt n drop ps2*
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) if year == 2016, ///
	osample(ps2016)
capt n teffects psmatch (revt) (trt1_sdw_neg dltt at age emp tobinq) ///
	if year == 2016 & ps2016 == 0
estimates store ps2016

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015 ps2016, ///
	b se p ///
	stats(N)












						***===========================***
						*								*
						*	PROPENSITY SCORE MATCHING 	*
						*		INDIVIDUAL YEARS		*
						*	DV: Next Year Revenue Level	*
						*								*
						***===========================***
///	3 STANDARD DEVIATIONS
***	3 Standard Deviation Positive
*	Insufficient number of treatment events for several years
capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2009, osample(ps2009)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2009 & ps2009==0, osample(ps2009_2)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2009 & ps2009==0 & ps2009_2==0
estimates store ps2009

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2010, osample(ps2010)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2010 & ps2010==0
estimates store ps2010

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2011, osample(ps2011)
estimates store ps2011

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2012, osample(ps2012)
estimates store ps2012

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2013, osample(ps2013)
estimates store ps2013

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2014, osample(ps2014)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2014 & ps2014==0, osample(ps2014_2)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2014 & ps2014==0 & ps2014_2==0
estimates store ps2014

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_pos dltt at age emp tobinq ap) ///
	if year == 2015, osample(ps2015)
estimates store ps2015

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015, ///
	b se p ///
	stats(N)
	
***	3 Standard Deviation Negative
*	Insufficient number of treatment events for several years
est sto clear

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2009, osample(ps2009)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2009 & ps2009==0, osample(ps2009_2)
estimates store ps2009

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2010, osample(ps2010)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2010 & ps2010==0
estimates store ps2010

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2011, osample(ps2011)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2011 & ps2011==0, osample(ps2011_2)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2011 & ps2011==0 & ps2011_2==0
estimates store ps2011

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2012, osample(ps2012)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2012 & ps2012==0, osample(ps2012_2)
estimates store ps2012

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2013, osample(ps2013)
estimates store ps2013

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2014, osample(ps2014)
estimates store ps2014

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2015, osample(ps2015)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2015 & ps2015==0, osample(ps2015_2)
capt n teffects psmatch (Frevt_yoy) (trt3_sdw_neg dltt at age emp tobinq ap) ///
	if year == 2015 & ps2015==0 & ps2015_2==0
estimates store ps2015

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015, ///
	b se p ///
	stats(N)



	
///	2 STANDARD DEVIATIONS
***	2 Standard Deviation Positive
est sto clear

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2009
estimates store ps2009

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
estimates store ps2010	

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2011 & ps2011==0
estimates store ps2011

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2012 & ps2012==0
estimates store ps2012

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0
estimates store ps2013

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) if year == 2015, ///
	osample(ps2015)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_pos dltt at age emp tobinq) ///
	if year == 2015 & ps2015==0
estimates store ps2015

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015, ///
	b se p ///
	stats(N)
	

***	2 Standard Deviation Negative
est sto clear

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2009, ///
	osample(ps2009)
estimates store ps2009

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2010 & ps2010==0
estimates store ps2010		

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
estimates store ps2011

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2012 & ps2012==0
estimates store ps2012

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0, osample(ps2013_2)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0 & ps2013_2==0
estimates store ps2013

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) if year == 2015, ///
	osample(ps2015)
capt n teffects psmatch (Frevt_yoy) (trt2_sdw_neg dltt at age emp tobinq) ///
	if year == 2015 & ps2015==0
estimates store ps2015

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015, ///
	b se p ///
	stats(N)




///	1 STANDARD DEVIATION
***	1 Standard Deviation Positive
est sto clear

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2009
estimates store ps2009

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
estimates store ps2010	

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2011 & ps2011==0
estimates store ps2011

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2012 & ps2012==0
estimates store ps2012

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0
estimates store ps2013

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_pos dltt at age emp tobinq) ///
	if year == 2015
estimates store ps2015

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015, ///
	b se p ///
	stats(N)
	

***	1 Standard Deviation Negative
est sto clear

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq) if year == 2009, ///
	osample(ps2009)
estimates store ps2009

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq) if year == 2010, ///
	osample(ps2010)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq) ///
	if year == 2010 & ps2010==0
estimates store ps2010		

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq) if year == 2011, ///
	osample(ps2011)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq) ///
	if year == 2011 & ps2011==0
estimates store ps2011

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq) if year == 2012, ///
	osample(ps2012)
estimates store ps2012

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq) if year == 2013, ///
	osample(ps2013)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq) ///
	if year == 2013 & ps2013==0, osample(ps2013_2)
estimates store ps2013

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq) if year == 2014, ///
	osample(ps2014)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq) ///
	if year == 2014 & ps2014==0
estimates store ps2014

capt n drop ps2*
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq) if year == 2015, ///
	osample(ps2015)
capt n teffects psmatch (Frevt_yoy) (trt1_sdw_neg dltt at age emp tobinq) ///
	if year == 2015 & ps2015==0
estimates store ps2015

estimates table ps2009 ps2010 ps2011 ps2012 ps2013 ps2014 ps2015, ///
	b se p ///
	stats(N)

	
						***===========================***
						*								*
						*		DIF-IN-DIFS 			*
						*		DV: Same year revenue	*
						*								*
						***===========================***
/*	WORKFLOW (See https://dss.princeton.edu/training/)
*/
						
/// LOAD DATA
use data/matched-csrhub-cstat-2008-2017, clear

///	REVENUE IN SAME YEAR AS TREATMENT
***	Nominal revenue
foreach variable in trt3_sdw_pos trt3_sdw_neg trt2_sdw_pos trt2_sdw_neg ///
	trt1_sdw_pos trt1_sdw_neg {
	forvalues year = 2009/2017 {
		display "`variable' for `year'"
		
		capt n drop time treatyear treated
		
		*	Create dummy to indicate year of treatment
		gen time = (year>=`year') & !missing(year)
		label var time "Post-treatment"
		
		*	Create dummy identifying treatment and control groups
			/*	Assumes all firms not treated in this year are valid controls	*/
		gen treatyear = (year==`year') & (`variable'==1)
		bysort gvkey_num: egen treated = max(treatyear) if `variable'!=.
		label var treated "Treated"

		*	Estimate
		reg revt i.time##i.treated i.year, r
		
		*	Store estimates
		estimates store est_`variable'_`year'
	}
}

*	Coefficient plots
coefplot est_trt3_sdw_pos_2009 est_trt3_sdw_pos_2010 est_trt3_sdw_pos_2011 est_trt3_sdw_pos_2012 est_trt3_sdw_pos_2013 est_trt3_sdw_pos_2014 est_trt3_sdw_pos_2015 est_trt3_sdw_pos_2016 est_trt3_sdw_pos_2017, ///
	xline(0) ///
	drop(*year) ///
	name(g1a, replace) ///
	title("TRT3 POS")
	
coefplot est_trt3_sdw_neg_2009 est_trt3_sdw_neg_2010 est_trt3_sdw_neg_2011 est_trt3_sdw_neg_2012 est_trt3_sdw_neg_2013 est_trt3_sdw_neg_2014 est_trt3_sdw_neg_2015 est_trt3_sdw_neg_2016 est_trt3_sdw_neg_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_trt2_sdw_pos_2009 est_trt2_sdw_pos_2010 est_trt2_sdw_pos_2011 est_trt2_sdw_pos_2012 est_trt2_sdw_pos_2013 est_trt2_sdw_pos_2014 est_trt2_sdw_pos_2015 est_trt2_sdw_pos_2016 est_trt2_sdw_pos_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_trt2_sdw_neg_2009 est_trt2_sdw_neg_2010 est_trt2_sdw_neg_2011 est_trt2_sdw_neg_2012 est_trt2_sdw_neg_2013 est_trt2_sdw_neg_2014 est_trt2_sdw_neg_2015 est_trt2_sdw_neg_2016 est_trt2_sdw_neg_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_trt1_sdw_pos_2009 est_trt1_sdw_pos_2010 est_trt1_sdw_pos_2011 est_trt1_sdw_pos_2012 est_trt1_sdw_pos_2013 est_trt1_sdw_pos_2014 est_trt1_sdw_pos_2015 est_trt1_sdw_pos_2016 est_trt1_sdw_pos_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_trt1_sdw_neg_2009 est_trt1_sdw_neg_2010 est_trt1_sdw_neg_2011 est_trt1_sdw_neg_2012 est_trt1_sdw_neg_2013 est_trt1_sdw_neg_2014 est_trt1_sdw_neg_2015 est_trt1_sdw_neg_2016 est_trt1_sdw_neg_2017, ///
	xline(0) ///
	drop(*year)

	
***	Inverse hyperbolic sine transformation DV
capt n gen ihasrevt = asinh(revt)
label var ihasrevt "Inverse hyperbolic sine transformation of revt"

foreach variable in trt3_sdw_pos trt3_sdw_neg trt2_sdw_pos trt2_sdw_neg ///
	trt1_sdw_pos trt1_sdw_neg {
	forvalues year = 2009/2017 {
		display "`variable' for `year'"
		
		capt n drop time treatyear treated
		
		*	Create dummy to indicate year of treatment
		gen time = (year>=`year') & !missing(year)
		label var time "Post-treatment"
		
		*	Create dummy identifying treatment and control groups
			/*	Assumes all firms not treated in this year are valid controls	*/
		gen treatyear = (year==`year') & (`variable'==1)
		bysort gvkey_num: egen treated = max(treatyear) if `variable'!=.
		label var treated "Treated"

		*	Estimate
		reg ihasrevt i.time##i.treated i.year, r
		
		*	Store estimates
		estimates store est_ihas_`variable'_`year'
	}
}

*	Coefficient plots
coefplot est_ihas_trt3_sdw_pos_2009 est_ihas_trt3_sdw_pos_2010 est_ihas_trt3_sdw_pos_2011 est_ihas_trt3_sdw_pos_2012 est_ihas_trt3_sdw_pos_2013 est_ihas_trt3_sdw_pos_2014 est_ihas_trt3_sdw_pos_2015 est_ihas_trt3_sdw_pos_2016 est_ihas_trt3_sdw_pos_2017, ///
	xline(0) ///
	xlab(-10(5)10) ///
	drop(*year) ///
	legend(label(2 "2009") label(4 "2010") label(6 "2011") label(8 "2012") ///
		label(10 "2013") label(12 "2014") label(14 "2015") label(16 "2016") ///
		label(18 "2017"))
	
coefplot est_ihas_trt3_sdw_neg_2009 est_ihas_trt3_sdw_neg_2010 est_ihas_trt3_sdw_neg_2011 est_ihas_trt3_sdw_neg_2012 est_ihas_trt3_sdw_neg_2013 est_ihas_trt3_sdw_neg_2014 est_ihas_trt3_sdw_neg_2015 est_ihas_trt3_sdw_neg_2016 est_ihas_trt3_sdw_neg_2017, ///
	xline(0) ///
	drop(*year) ///
	legend(label(2 "2009") label(4 "2010") label(6 "2011") label(8 "2012") ///
		label(10 "2013") label(12 "2014") label(14 "2015") label(16 "2016") ///
		label(18 "2017"))
	
coefplot est_ihas_trt2_sdw_pos_2009 est_ihas_trt2_sdw_pos_2010 est_ihas_trt2_sdw_pos_2011 est_ihas_trt2_sdw_pos_2012 est_ihas_trt2_sdw_pos_2013 est_ihas_trt2_sdw_pos_2014 est_ihas_trt2_sdw_pos_2015 est_ihas_trt2_sdw_pos_2016 est_ihas_trt2_sdw_pos_2017, ///
	xline(0) ///
	drop(*year) ///
	legend(label(2 "2009") label(4 "2010") label(6 "2011") label(8 "2012") ///
		label(10 "2013") label(12 "2014") label(14 "2015") label(16 "2016") ///
		label(18 "2017"))
	
coefplot est_ihas_trt2_sdw_neg_2009 est_ihas_trt2_sdw_neg_2010 est_ihas_trt2_sdw_neg_2011 est_ihas_trt2_sdw_neg_2012 est_ihas_trt2_sdw_neg_2013 est_ihas_trt2_sdw_neg_2014 est_ihas_trt2_sdw_neg_2015 est_ihas_trt2_sdw_neg_2016 est_ihas_trt2_sdw_neg_2017, ///
	xline(0) ///
	drop(*year) ///
	legend(label(2 "2009") label(4 "2010") label(6 "2011") label(8 "2012") ///
		label(10 "2013") label(12 "2014") label(14 "2015") label(16 "2016") ///
		label(18 "2017"))
	
coefplot est_ihas_trt1_sdw_pos_2009 est_ihas_trt1_sdw_pos_2010 est_ihas_trt1_sdw_pos_2011 est_ihas_trt1_sdw_pos_2012 est_ihas_trt1_sdw_pos_2013 est_ihas_trt1_sdw_pos_2014 est_ihas_trt1_sdw_pos_2015 est_ihas_trt1_sdw_pos_2016 est_ihas_trt1_sdw_pos_2017, ///
	xline(0) ///
	drop(*year) ///
	legend(label(2 "2009") label(4 "2010") label(6 "2011") label(8 "2012") ///
		label(10 "2013") label(12 "2014") label(14 "2015") label(16 "2016") ///
		label(18 "2017"))
	
coefplot est_ihas_trt1_sdw_neg_2009 est_ihas_trt1_sdw_neg_2010 est_ihas_trt1_sdw_neg_2011 est_ihas_trt1_sdw_neg_2012 est_ihas_trt1_sdw_neg_2013 est_ihas_trt1_sdw_neg_2014 est_ihas_trt1_sdw_neg_2015 est_ihas_trt1_sdw_neg_2016 est_ihas_trt1_sdw_neg_2017, ///
	xline(0) ///
	drop(*year) ///
	legend(label(2 "2009") label(4 "2010") label(6 "2011") label(8 "2012") ///
		label(10 "2013") label(12 "2014") label(14 "2015") label(16 "2016") ///
		label(18 "2017"))
	
///	REVENUE IN YEAR AFTER TREATMENT
xtset
gen frevt=f.revt

foreach variable in trt3_sdw_pos trt3_sdw_neg trt2_sdw_pos trt2_sdw_neg ///
	trt1_sdw_pos trt1_sdw_neg {
	forvalues year = 2009/2017 {
		display "`variable' for `year'"
		
		capt n drop time treatyear treated
		
		*	Create dummy to indicate year of treatment
		gen time = (year>=`year') & !missing(year)
		label var time "Post-treatment"
		
		*	Create dummy identifying treatment and control groups
			/*	Assumes all firms not treated in this year are valid controls	*/
		gen treatyear = (year==`year') & (`variable'==1)
		bysort gvkey_num: egen treated = max(treatyear) if `variable'!=.
		label var treated "Treated"

		*	Estimate
		reg frevt i.time##i.treated i.year, r
		
		*	Store estimates
		estimates store est_f_`variable'_`year'
	}
}

***	Visualize
*	Coefficient plots
coefplot est_f_trt3_sdw_pos_2009 est_f_trt3_sdw_pos_2010 est_f_trt3_sdw_pos_2011 est_f_trt3_sdw_pos_2012 est_f_trt3_sdw_pos_2013 est_f_trt3_sdw_pos_2014 est_f_trt3_sdw_pos_2015 est_f_trt3_sdw_pos_2016 est_f_trt3_sdw_pos_2017, ///
	xline(0) ///
	drop(*year) ///
	name(g1b, replace) ///
	title("TRT3 POS, Forward")
	
coefplot est_f_trt3_sdw_neg_2009 est_f_trt3_sdw_neg_2010 est_f_trt3_sdw_neg_2011 est_f_trt3_sdw_neg_2012 est_f_trt3_sdw_neg_2013 est_f_trt3_sdw_neg_2014 est_f_trt3_sdw_neg_2015 est_f_trt3_sdw_neg_2016 est_f_trt3_sdw_neg_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_f_trt2_sdw_pos_2009 est_f_trt2_sdw_pos_2010 est_f_trt2_sdw_pos_2011 est_f_trt2_sdw_pos_2012 est_f_trt2_sdw_pos_2013 est_f_trt2_sdw_pos_2014 est_f_trt2_sdw_pos_2015 est_f_trt2_sdw_pos_2016 est_f_trt2_sdw_pos_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_f_trt2_sdw_neg_2009 est_f_trt2_sdw_neg_2010 est_f_trt2_sdw_neg_2011 est_f_trt2_sdw_neg_2012 est_f_trt2_sdw_neg_2013 est_f_trt2_sdw_neg_2014 est_f_trt2_sdw_neg_2015 est_f_trt2_sdw_neg_2016 est_f_trt2_sdw_neg_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_f_trt1_sdw_pos_2009 est_f_trt1_sdw_pos_2010 est_f_trt1_sdw_pos_2011 est_f_trt1_sdw_pos_2012 est_f_trt1_sdw_pos_2013 est_f_trt1_sdw_pos_2014 est_f_trt1_sdw_pos_2015 est_f_trt1_sdw_pos_2016 est_f_trt1_sdw_pos_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_f_trt1_sdw_neg_2009 est_f_trt1_sdw_neg_2010 est_f_trt1_sdw_neg_2011 est_f_trt1_sdw_neg_2012 est_f_trt1_sdw_neg_2013 est_f_trt1_sdw_neg_2014 est_f_trt1_sdw_neg_2015 est_f_trt1_sdw_neg_2016 est_f_trt1_sdw_neg_2017, ///
	xline(0) ///
	drop(*year)


						***===========================***
						*		DIF-IN-DIFS 			*
						*		DV: Same year revenue	*
						*		Centered on treatment	*
						***===========================***
/*	METHODOLOGICAL CONSIDERATIONS
	
	HOW TO HANDLE FIRMS THAT ARE NEVER TREATED? 
	HOW CAN THEY BE USED IN ESTIMATION?
*/

///	LOAD DATA
use data/matched-csrhub-cstat-2008-2017, clear
xtset

///	GENERATE TREATMENT PERIOD VARIABLES TO CENTER FIRMS IN TIME
foreach variable in trt3_sdw_pos trt3_sdw_neg trt2_sdw_pos trt2_sdw_neg ///
	trt1_sdw_pos trt1_sdw_neg {
	
	*	Generate years from treatment variable
	gen `variable'_trtper = `variable'==1
	label var `variable'_trtper "Years from treatment"
	
	*	Calculate years relative to first treatment event for firm
	bysort gvkey_num: gen yeartreat = year if `variable'_trtper == 1
	bysort gvkey_num: egen yeartreatmin = min(yeartreat)
	replace `variable'_trtper = year - yeartreatmin
	replace `variable'_trtper=. if `variable'==.
	
	*	Drop unneeded
	drop yeartreat yeartreatmin
}



///	ESTIMATION: LEVEL OF REVT
foreach variable in trt3_sdw_pos trt3_sdw_neg trt2_sdw_pos trt2_sdw_neg ///
	trt1_sdw_pos trt1_sdw_neg {
	forvalues year = 2009/2017 {
		display "`variable' for `year'"
		
		capt n drop time treatyear treated
		
		*	Create dummy to indicate year of treatment
		gen time = (year>=`year') & !missing(year)
		label var time "Post-treatment"
		
		*	Create dummy identifying treatment and control groups
			/*	Assumes all firms not treated in this year are valid controls	*/
		gen treatyear = (year==`year') & (`variable'==1)
		bysort gvkey_num: egen treated = max(treatyear) if `variable'!=.
		label var treated "Treated"

		*	Estimate
		qui reg revt i.time##i.treated i.year, r
		
		*	Store estimates
		estimates store est_`variable'_`year'
	}
}

***	Tables
*	estout
estout est_trt3_sdw_pos_2009 est_trt3_sdw_pos_2010 ///
	est_trt3_sdw_pos_2011 est_trt3_sdw_pos_2012 est_trt3_sdw_pos_2013 ///
	est_trt3_sdw_pos_2014 est_trt3_sdw_pos_2015 est_trt3_sdw_pos_2016 ///
	est_trt3_sdw_pos_2017, ///
	drop(*.year 0.treated 1.time#0.treated) ///
	cells(b se p) nobase
	
outreg2 [est_trt3_sdw_pos_2009 est_trt3_sdw_pos_2010 ///
	est_trt3_sdw_pos_2011 est_trt3_sdw_pos_2012 est_trt3_sdw_pos_2013 ///
	est_trt3_sdw_pos_2014 est_trt3_sdw_pos_2015 est_trt3_sdw_pos_2016 ///
	est_trt3_sdw_pos_2017] ///
	using tables-and-figures/dif-in-difs/trt3_sdw_pos_level, ///
	replace ///
	alpha(0.001, 0.01, 0.05)
	
estout est_trt3_sdw_neg_2009 est_trt3_sdw_neg_2010 est_trt3_sdw_neg_2011 ///
	est_trt3_sdw_neg_2012 est_trt3_sdw_neg_2013 est_trt3_sdw_neg_2014 ///
	est_trt3_sdw_neg_2015 est_trt3_sdw_neg_2016 est_trt3_sdw_neg_2017, ///
	drop(*.year 0.treated 1.time#0.treated) ///
	cells(b se p) nobase

estout est_trt2_sdw_pos_2009 est_trt2_sdw_pos_2010 est_trt2_sdw_pos_2011 ///
	est_trt2_sdw_pos_2012 est_trt2_sdw_pos_2013 est_trt2_sdw_pos_2014 ///
	est_trt2_sdw_pos_2015 est_trt2_sdw_pos_2016 est_trt2_sdw_pos_2017, ///
	drop(*.year 0.treated 1.time#0.treated) ///
	cells(b se p) nobase

estout est_trt2_sdw_neg_2009 est_trt2_sdw_neg_2010 est_trt2_sdw_neg_2011 ///
	est_trt2_sdw_neg_2012 est_trt2_sdw_neg_2013 est_trt2_sdw_neg_2014 ///
	est_trt2_sdw_neg_2015 est_trt2_sdw_neg_2016 est_trt2_sdw_neg_2017, ///
	drop(*.year 0.treated 1.time#0.treated) ///
	cells(b se p) nobase
	
estout est_trt1_sdw_pos_2009 est_trt1_sdw_pos_2010 est_trt1_sdw_pos_2011 ///
	est_trt1_sdw_pos_2012 est_trt1_sdw_pos_2013 est_trt1_sdw_pos_2014 ///
	est_trt1_sdw_pos_2015 est_trt1_sdw_pos_2016 est_trt1_sdw_pos_2017, ///
	drop(*.year 0.treated 1.time#0.treated) ///
	cells(b se p) nobase
	
estout est_trt1_sdw_neg_2009 est_trt1_sdw_neg_2010 est_trt1_sdw_neg_2011 ///
	est_trt1_sdw_neg_2012 est_trt1_sdw_neg_2013 est_trt1_sdw_neg_2014 ///
	est_trt1_sdw_neg_2015 est_trt1_sdw_neg_2016 est_trt1_sdw_neg_2017, ///
	drop(*.year 0.treated 1.time#0.treated) ///
	cells(b se p) nobase
	
*	outreg2
outreg2 est_trt3_sdw_pos_2009 est_trt3_sdw_pos_2010 ///
	est_trt3_sdw_pos_2011 est_trt3_sdw_pos_2012 est_trt3_sdw_pos_2013 ///
	est_trt3_sdw_pos_2014 est_trt3_sdw_pos_2015 est_trt3_sdw_pos_2016 ///
	est_trt3_sdw_pos_2017 using regression_results, ///
	replace excel dec(3)

outreg2 est_trt3_sdw* ///
	using regression_results, ///
	replace excel dec(3)
	
	
	


***	Visualize
*	Coefficient plots
coefplot est_trt3_sdw_pos_2009 est_trt3_sdw_pos_2010 est_trt3_sdw_pos_2011 est_trt3_sdw_pos_2012 est_trt3_sdw_pos_2013 est_trt3_sdw_pos_2014 est_trt3_sdw_pos_2015 est_trt3_sdw_pos_2016 est_trt3_sdw_pos_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_trt3_sdw_neg_2009 est_trt3_sdw_neg_2010 est_trt3_sdw_neg_2011 est_trt3_sdw_neg_2012 est_trt3_sdw_neg_2013 est_trt3_sdw_neg_2014 est_trt3_sdw_neg_2015 est_trt3_sdw_neg_2016 est_trt3_sdw_neg_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_trt2_sdw_pos_2009 est_trt2_sdw_pos_2010 est_trt2_sdw_pos_2011 est_trt2_sdw_pos_2012 est_trt2_sdw_pos_2013 est_trt2_sdw_pos_2014 est_trt2_sdw_pos_2015 est_trt2_sdw_pos_2016 est_trt2_sdw_pos_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_trt2_sdw_neg_2009 est_trt2_sdw_neg_2010 est_trt2_sdw_neg_2011 est_trt2_sdw_neg_2012 est_trt2_sdw_neg_2013 est_trt2_sdw_neg_2014 est_trt2_sdw_neg_2015 est_trt2_sdw_neg_2016 est_trt2_sdw_neg_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_trt1_sdw_pos_2009 est_trt1_sdw_pos_2010 est_trt1_sdw_pos_2011 est_trt1_sdw_pos_2012 est_trt1_sdw_pos_2013 est_trt1_sdw_pos_2014 est_trt1_sdw_pos_2015 est_trt1_sdw_pos_2016 est_trt1_sdw_pos_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_trt1_sdw_neg_2009 est_trt1_sdw_neg_2010 est_trt1_sdw_neg_2011 est_trt1_sdw_neg_2012 est_trt1_sdw_neg_2013 est_trt1_sdw_neg_2014 est_trt1_sdw_neg_2015 est_trt1_sdw_neg_2016 est_trt1_sdw_neg_2017, ///
	xline(0) ///
	drop(*year)







						***===============================***
						*		DIF-IN-DIFS 				*
						*		DV: Inv Hyperbolic Sine DV	*
						*		Centered on treatment		*
						***===============================***
est clear

///	TRANSFORM DV
***	Inverse hyperbolic sine transformed DV
*	See https://worthwhile.typepad.com/worthwhile_canadian_initi/2011/07/a-rant-on-inverse-hyperbolic-sine-transformations.html
gen revt_ihs=asinh(revt)
label var revt_ihs "Inverse hyperbolic sine transformation of revt"


///	ESTIMATION
foreach variable in trt3_sdw_pos trt3_sdw_neg trt2_sdw_pos trt2_sdw_neg ///
	trt1_sdw_pos trt1_sdw_neg {
	forvalues year = 2009/2017 {
		display "`variable' for `year'"
		
		capt n drop time treatyear treated
		
		*	Create dummy to indicate year of treatment
		gen time = (year>=`year') & !missing(year)
		label var time "Post-treatment"
		
		*	Create dummy identifying treatment and control groups
			/*	Assumes all firms not treated in this year are valid controls	*/
		gen treatyear = (year==`year') & (`variable'==1)
		bysort gvkey_num: egen treated = max(treatyear) if `variable'!=.
		label var treated "Treated"

		*	Estimate
		qui reg revt_ihs i.time##i.treated i.year, r
		
		*	Store estimates
		estimates store est_ihs_`variable'_`year'
	}
}

***	Tables
estout est_ihs_trt3_sdw_pos_2009 est_ihs_trt3_sdw_pos_2010 ///
	est_ihs_trt3_sdw_pos_2011 est_ihs_trt3_sdw_pos_2012 est_ihs_trt3_sdw_pos_2013 ///
	est_ihs_trt3_sdw_pos_2014 est_ihs_trt3_sdw_pos_2015 est_ihs_trt3_sdw_pos_2016 ///
	est_ihs_trt3_sdw_pos_2017
	
outreg2 [est_ihs_trt3_sdw_pos_2009 est_ihs_trt3_sdw_pos_2010 ///
	est_ihs_trt3_sdw_pos_2011 est_ihs_trt3_sdw_pos_2012 est_ihs_trt3_sdw_pos_2013 ///
	est_ihs_trt3_sdw_pos_2014 est_ihs_trt3_sdw_pos_2015 est_ihs_trt3_sdw_pos_2016 ///
	est_ihs_trt3_sdw_pos_2017] ///
	using tables-and-figures/dif-in-difs/trt3_sdw_pos_ihs, ///
	replace ///
	alpha(0.001, 0.01, 0.05)

	
estout est_ihs_trt3_sdw_neg_2009 est_ihs_trt3_sdw_neg_2010 est_ihs_trt3_sdw_neg_2011 est_ihs_trt3_sdw_neg_2012 est_ihs_trt3_sdw_neg_2013 est_ihs_trt3_sdw_neg_2014 est_ihs_trt3_sdw_neg_2015 est_ihs_trt3_sdw_neg_2016 est_ihs_trt3_sdw_neg_2017
	
estout est_ihs_trt2_sdw_pos_2009 est_ihs_trt2_sdw_pos_2010 est_ihs_trt2_sdw_pos_2011 est_ihs_trt2_sdw_pos_2012 est_ihs_trt2_sdw_pos_2013 est_ihs_trt2_sdw_pos_2014 est_ihs_trt2_sdw_pos_2015 est_ihs_trt2_sdw_pos_2016 est_ihs_trt2_sdw_pos_2017
	
estout est_ihs_trt2_sdw_neg_2009 est_ihs_trt2_sdw_neg_2010 est_ihs_trt2_sdw_neg_2011 est_ihs_trt2_sdw_neg_2012 est_ihs_trt2_sdw_neg_2013 est_ihs_trt2_sdw_neg_2014 est_ihs_trt2_sdw_neg_2015 est_ihs_trt2_sdw_neg_2016 est_ihs_trt2_sdw_neg_2017
	
estout est_ihs_trt1_sdw_pos_2009 est_ihs_trt1_sdw_pos_2010 est_ihs_trt1_sdw_pos_2011 est_ihs_trt1_sdw_pos_2012 est_ihs_trt1_sdw_pos_2013 est_ihs_trt1_sdw_pos_2014 est_ihs_trt1_sdw_pos_2015 est_ihs_trt1_sdw_pos_2016 est_ihs_trt1_sdw_pos_2017
	
estout est_ihs_trt1_sdw_neg_2009 est_ihs_trt1_sdw_neg_2010 est_ihs_trt1_sdw_neg_2011 est_ihs_trt1_sdw_neg_2012 est_ihs_trt1_sdw_neg_2013 est_ihs_trt1_sdw_neg_2014 est_ihs_trt1_sdw_neg_2015 est_ihs_trt1_sdw_neg_2016 est_ihs_trt1_sdw_neg_2017



***	Visualize
*	Coefficient plots
coefplot est_ihs_trt3_sdw_pos_2009 est_ihs_trt3_sdw_pos_2010 est_ihs_trt3_sdw_pos_2011 est_ihs_trt3_sdw_pos_2012 est_ihs_trt3_sdw_pos_2013 est_ihs_trt3_sdw_pos_2014 est_ihs_trt3_sdw_pos_2015 est_ihs_trt3_sdw_pos_2016 est_ihs_trt3_sdw_pos_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_ihs_trt3_sdw_neg_2009 est_ihs_trt3_sdw_neg_2010 est_ihs_trt3_sdw_neg_2011 est_ihs_trt3_sdw_neg_2012 est_ihs_trt3_sdw_neg_2013 est_ihs_trt3_sdw_neg_2014 est_ihs_trt3_sdw_neg_2015 est_ihs_trt3_sdw_neg_2016 est_ihs_trt3_sdw_neg_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_ihs_trt2_sdw_pos_2009 est_ihs_trt2_sdw_pos_2010 est_ihs_trt2_sdw_pos_2011 est_ihs_trt2_sdw_pos_2012 est_ihs_trt2_sdw_pos_2013 est_ihs_trt2_sdw_pos_2014 est_ihs_trt2_sdw_pos_2015 est_ihs_trt2_sdw_pos_2016 est_ihs_trt2_sdw_pos_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_ihs_trt2_sdw_neg_2009 est_ihs_trt2_sdw_neg_2010 est_ihs_trt2_sdw_neg_2011 est_ihs_trt2_sdw_neg_2012 est_ihs_trt2_sdw_neg_2013 est_ihs_trt2_sdw_neg_2014 est_ihs_trt2_sdw_neg_2015 est_ihs_trt2_sdw_neg_2016 est_ihs_trt2_sdw_neg_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_ihs_trt1_sdw_pos_2009 est_ihs_trt1_sdw_pos_2010 est_ihs_trt1_sdw_pos_2011 est_ihs_trt1_sdw_pos_2012 est_ihs_trt1_sdw_pos_2013 est_ihs_trt1_sdw_pos_2014 est_ihs_trt1_sdw_pos_2015 est_ihs_trt1_sdw_pos_2016 est_ihs_trt1_sdw_pos_2017, ///
	xline(0) ///
	drop(*year)
	
coefplot est_ihs_trt1_sdw_neg_2009 est_ihs_trt1_sdw_neg_2010 est_ihs_trt1_sdw_neg_2011 est_ihs_trt1_sdw_neg_2012 est_ihs_trt1_sdw_neg_2013 est_ihs_trt1_sdw_neg_2014 est_ihs_trt1_sdw_neg_2015 est_ihs_trt1_sdw_neg_2016 est_ihs_trt1_sdw_neg_2017, ///
	xline(0) ///
	drop(*year)


///	VISUALIZATION OF DATA
***	Box plot
graph box revt_ihs, over(trt2_sdw_pos_trtper) ///
	name(g1, replace) ///
	title("revt_ihs by 2 sdw pos treatment period")
graph box revt_ihs, over(trt2_sdw_neg_trtper) ///
	name(g2, replace) nodraw ///
	title("revt_ihs by 2 sdw neg treatment period")
graph combine g1 g2


***	Line graph
*	3 sdw
bysort trt3_sdw_neg_trtper: egen trt3_sdw_neg_revt_ihs_mean=mean(revt_ihs) ///
	if trt3_sdw_neg_trtper!=.
bysort trt3_sdw_neg_trtper: egen trt3_sdw_neg_revt_ihs_med=median(revt_ihs) ///
	if trt3_sdw_neg_trtper!=.
tw (line trt3_sdw_neg_revt_ihs_mean trt3_sdw_neg_trtper, sort) ///
	(line trt3_sdw_neg_revt_ihs_med trt3_sdw_neg_trtper, sort), ///
	ylabel() xline(0)
	
bysort trt3_sdw_pos_trtper: egen trt3_sdw_pos_revt_ihs_mean=mean(revt_ihs) ///
	if trt3_sdw_pos_trtper!=.
bysort trt3_sdw_pos_trtper: egen trt3_sdw_pos_revt_ihs_med=median(revt_ihs) ///
	if trt3_sdw_pos_trtper!=.
tw 	(line trt3_sdw_pos_revt_ihs_mean trt3_sdw_pos_trtper, sort) ///
	(line trt3_sdw_pos_revt_ihs_med trt3_sdw_pos_trtper, sort), ///
	ylabel() xline(0)
	
*	2 sdw
bysort trt2_sdw_neg_trtper: egen trt2_sdw_neg_revt_ihs_mean=mean(revt_ihs) ///
	if trt2_sdw_neg_trtper!=.
bysort trt2_sdw_neg_trtper: egen trt2_sdw_neg_revt_ihs_med=median(revt_ihs) ///
	if trt2_sdw_neg_trtper!=.
tw (line trt2_sdw_neg_revt_ihs_mean trt2_sdw_neg_trtper, sort) ///
	(line trt2_sdw_neg_revt_ihs_med trt2_sdw_neg_trtper, sort), ///
	ylabel() xline(0)

bysort trt2_sdw_pos_trtper: egen trt2_sdw_pos_revt_ihs_mean=mean(revt_ihs) ///
	if trt2_sdw_pos_trtper!=.
bysort trt2_sdw_pos_trtper: egen trt2_sdw_pos_revt_ihs_med=median(revt_ihs) ///
	if trt2_sdw_pos_trtper!=.
tw 	(line trt2_sdw_pos_revt_ihs_mean trt2_sdw_pos_trtper, sort) ///
	(line trt2_sdw_pos_revt_ihs_med trt2_sdw_pos_trtper, sort), ///
	ylabel() xline(0)

*	1 sdw
bysort trt1_sdw_neg_trtper: egen trt1_sdw_neg_revt_ihs_mean=mean(revt_ihs) ///
	if trt1_sdw_neg_trtper!=.
bysort trt1_sdw_neg_trtper: egen trt1_sdw_neg_revt_ihs_med=median(revt_ihs) ///
	if trt1_sdw_neg_trtper!=.
tw (line trt1_sdw_neg_revt_ihs_mean trt1_sdw_neg_trtper, sort) ///
	(line trt1_sdw_neg_revt_ihs_med trt1_sdw_neg_trtper, sort), ///
	ylabel() xline(0)

bysort trt1_sdw_pos_trtper: egen trt1_sdw_pos_revt_ihs_mean=mean(revt_ihs) ///
	if trt1_sdw_pos_trtper!=.
bysort trt1_sdw_pos_trtper: egen trt1_sdw_pos_revt_ihs_med=median(revt_ihs) ///
	if trt1_sdw_pos_trtper!=.
tw 	(line trt1_sdw_pos_revt_ihs_mean trt1_sdw_pos_trtper, sort) ///
	(line trt1_sdw_pos_revt_ihs_med trt1_sdw_pos_trtper, sort), ///
	ylabel() xline(0)
	








						***===========================***
						*	FIXED EFFECTS REGRESSION	*
						*		DV: LEVEL OF REVT 		*
						***===========================***	
///	LOAD DATA
use data/matched-csrhub-cstat-2008-2017, clear

est clear

***	Drop unneeded variables
drop xrdp

***	Panel
xtset

///	ESTIMATION
*mark mark3
*markout mark3 revt over_rtg dltt at xad xrd emp year
qui xtreg revt over_rtg, fe cluster(gvkey_num)										
est store revtmod1
estadd local yearFE "No", replace
qui xtreg revt over_rtg i.year, fe cluster(gvkey_num)									
est store revtmod2
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt i.year, fe cluster(gvkey_num)							
est store revtmod3
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt at i.year, fe cluster(gvkey_num)							
est store revtmod4
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt at emp i.year, fe cluster(gvkey_num)						
est store revtmod5
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt at emp tobinq i.year, fe cluster(gvkey_num)					
est store revtmod6
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt at emp tobinq age i.year, fe cluster(gvkey_num)				
est store revtmod7
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt at emp tobinq age xad i.year, fe cluster(gvkey_num)				
est store revtmod8
estadd local yearFE "Yes", replace
qui xtreg revt over_rtg dltt at emp tobinq age xad xrd i.year, fe cluster(gvkey_num)				
est store revtmod9
estadd local yearFE "Yes", replace


*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

qui xtreg revt over_rtg dltt at emp tobinq age xad xrd i.year, fe cluster(gvkey_num)				
est store revtmod10
estadd local yearFE "Yes", replace
restore

esttab revtmod*, ///
	b se s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC")) ///
	keep(over_rtg dltt at xad xrd tobinq emp age)


	
	
	
	
						***===========================***
						*	FIXED EFFECTS REGRESSION	*
						*	DV: NEXT YEAR LEVEL OF REVT *
						***===========================***	
local dv revt
local iv over_rtg 
local controls "dltt at age emp tobinq xad xrd"

qui xtreg F.`dv' `iv', fe cluster(gvkey_num)
est store over_rtgmod0
estadd local yearFE "No", replace

qui xtreg F.`dv' `iv' i.year, fe cluster(gvkey_num)
est store over_rtgmod1
estadd local yearFE "Yes", replace

local vars ""
local counter 2
foreach control of local controls {
	*	Regression
	qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(gvkey_num)
		
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

qui xtreg F.revt over_rtg dltt at age emp tobinq xad xrd i.year, fe cluster(gvkey_num)	
est store over_rtgas1
estadd local yearFE "Yes", replace
restore 

*	Assume missing xad and xrd are 0, interact over_rtg and revt, 
*	all independent variables lagged
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

qui xtreg F.revt c.over_rtg##c.revt dltt at age emp tobinq xad xrd i.year, fe cluster(gvkey_num)
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

qui xtreg F.revt c.Sover_rtg##c.Srevt dltt at emp tobinq xad xrd age i.year, fe cluster(gvkey_num)
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

	
///	COMPARE THE TWO DVs
esttab revtmod9 over_rtgmod8 revtmod10 over_rtgas1 , ///
	keep(over_rtg dltt at age emp tobinq xad xrd) ///
	order(over_rtg dltt at age emp tobinq xad xrd) ///
	s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC"))


	
	
	
						***=======================================***
						*	FIXED EFFECTS REGRESSION				*
						*	CSRHUB CATEGORIES AND SUB-CATEGORIES	*
						*		DV: NEXT YEAR LEVEL OF REVT			*
						***=======================================***	
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

qui xtreg F.`dv' `iv', fe cluster(gvkey_num)
est store cmtymod0
estadd local yearFE "No", replace

qui xtreg F.`dv' `iv' i.year, fe cluster(gvkey_num)
est store cmtymod1
estadd local yearFE "Yes", replace

local vars ""
local counter 2
foreach control of local controls {
	*	Regression
	qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(gvkey_num)
		
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

qui xtreg F.`dv' `iv' `controls' i.year, fe cluster(gvkey_num)
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

qui xtreg F.`dv' `iv', fe cluster(gvkey_num)
est store empmod0
estadd local yearFE "No", replace

qui xtreg F.`dv' `iv' i.year, fe cluster(gvkey_num)
est store empmod1
estadd local yearFE "Yes", replace

local vars ""
local counter 2
foreach control of local controls {
	*	Regression
	qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(gvkey_num)
		
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

qui xtreg F.`dv' `iv' `controls' i.year, fe cluster(gvkey_num)
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

qui xtreg F.`dv' `iv', fe cluster(gvkey_num)
est store enviromod0
estadd local yearFE "No", replace
estadd local firmFE "Yes", replace

qui xtreg F.`dv' `iv' i.year, fe cluster(gvkey_num)
est store enviromod1
estadd local yearFE "Yes", replace

local vars ""
local counter 2
foreach control of local controls {
	*	Regression
	qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(gvkey_num)
		
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

qui xtreg F.`dv' `iv' `controls' i.year, fe cluster(gvkey_num)
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

qui xtreg F.`dv' `iv', fe cluster(gvkey_num)
est store govmod0
estadd local yearFE "No", replace
estadd local firmFE "Yes", replace

qui xtreg F.`dv' `iv' i.year, fe cluster(gvkey_num)
est store govmod1
estadd local yearFE "Yes", replace

local vars ""
local counter 2
foreach control of local controls {
	*	Regression
	qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(gvkey_num)
		
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

qui xtreg F.`dv' `iv' `controls' i.year, fe cluster(gvkey_num)
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
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym , fe cluster(gvkey_num)
est store m1
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym i.year, fe cluster(gvkey_num)
est store m2
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt i.year, fe cluster(gvkey_num)
est store m3
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at i.year, fe cluster(gvkey_num)
est store m4
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age i.year, fe cluster(gvkey_num)
est store m5
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp i.year, fe cluster(gvkey_num)
est store m6
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad i.year, fe cluster(gvkey_num)
est store m7
estadd local yearFE "Yes", replace
qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd i.year, fe cluster(gvkey_num)
est store m8
estadd local yearFE "Yes", replace


***	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==.															/*	assumption	*/
replace xrd=0 if xrd==.															/*	assumption	*/

qui xtreg F.revt cmty_rtg_lym emp_rtg_lym enviro_rtg_lym gov_rtg_lym dltt at age emp tobinq xad xrd i.year, fe cluster(gvkey_num)
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
	qui xtreg F.`dv' `iv', fe cluster(gvkey_num)
	est store `iv'0
	qui estadd local yearFE "No", replace
	qui estadd local firmFE "Yes", replace

	qui xtreg F.`dv' `iv' i.year, fe cluster(gvkey_num)
	est store `iv'1
	qui estadd local yearFE "Yes", replace
	qui estadd local firmFE "Yes", replace
	
	local vars ""
	local counter 2
	foreach control of local controls {
		*	Regression
		qui xtreg F.`dv' `iv' `vars' `control' i.year, fe cluster(gvkey_num)
			
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

	qui xtreg F.`dv' `iv' `controls' i.year, fe cluster(gvkey_num)
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
	dltt at age emp tobinq xad xrd i.year, fe cluster(gvkey_num)
	
preserve
replace xad=0 if xad==.
replace xrd=0 if xrd==.

xtreg F.revt com_dev_phl_rtg_lym prod_rtg_lym humrts_supchain_rtg_lym ///
	comp_ben_rtg_lym div_lab_rtg_lym train_hlth_safe_rtg_lym ///
	enrgy_climchge_rtg_lym enviro_pol_rpt_rtg_lym resource_mgmt_rtg_lym ///
	board_rtg_lym ldrship_ethics_rtg_lym trans_report_rtg_lym ///
	dltt at age emp tobinq xad xrd i.year, fe cluster(gvkey_num)
est sto subcat_all
qui estadd local yearFE "Yes", replace
qui estadd local firmFE "Yes", replace

restore

esttab subcat_all, ///
	drop(*.year) ///
	s(yearFE firmFE N N_g r2 aic, label("Year FEs" "Firm FEs" "Observations" "Firms" "R^2" "AIC"))

	
	
	
	
	
	






						***===================================***
						*										*
						*		FIXED EFFECTS 					*
						*		DV: LEVEL OF YOY REVT CHANGE	*
						***===================================***
///	LOAD DATA
use data/matched-csrhub-cstat-2008-2017, clear

est clear

***	Drop unneeded variables
drop xrdp

***	Panel
xtset

///	ESTIMATION
qui xtreg revt_yoy over_rtg, fe cluster(gvkey_num)
est store revt_yoymod1
estadd local yearFE "No", replace
qui xtreg revt_yoy over_rtg i.year, fe cluster(gvkey_num)									
est store revt_yoymod2
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt i.year, fe cluster(gvkey_num)							
est store revt_yoymod3
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt at i.year, fe cluster(gvkey_num)							
est store revt_yoymod4
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt at emp i.year, fe cluster(gvkey_num)						
est store revt_yoymod5
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt at emp tobinq i.year, fe cluster(gvkey_num)					
est store revt_yoymod6
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt at emp tobinq age i.year, fe cluster(gvkey_num)				
est store revt_yoymod7
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt at emp tobinq age xad i.year, fe cluster(gvkey_num)				
est store revt_yoymod8
estadd local yearFE "Yes", replace
qui xtreg revt_yoy over_rtg dltt at emp tobinq age xad xrd i.year, fe cluster(gvkey_num)				
est store revt_yoymod9
estadd local yearFE "Yes", replace


*	Many xad and xrd observations are missing. Assume missing = 0.
preserve
replace xad=0 if xad==. & over_rtg!=.											/*	assumption	*/
replace xrd=0 if xrd==. & over_rtg!=.											/*	assumption	*/

qui xtreg revt_yoy over_rtg dltt at emp tobinq age xad xrd i.year, fe cluster(gvkey_num)				
est store revt_yoymod10
estadd local yearFE "Yes", replace
restore

esttab revt_yoymod*, ///
	b se s(yearFE N N_g r2 aic, label("Year FEs" "Observations" "Firms" "R^2" "AIC")) ///
	keep(over_rtg dltt at xad xrd tobinq emp age)


	
	
	
						***===================================***
						*										*
						*		FIXED EFFECTS 					*
						*		DV: 1-YEAR CHANGE IN REVT		*
						***===================================***
local dv revt_yoy
local iv over_rtg 
local controls "dltt at age emp tobinq xad xrd"

xtset

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
esttab revt_yoymod9 over_rtgmod8 revt_yoymod10 over_rtgas1, ///
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





/*		SUPPLEMENTARY ANALYSES



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
*/


*****************************************************************************END
