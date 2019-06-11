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
set scheme plotplain

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
gen assume_xad=(xad_original==.)
label var assume_xad "(CSTAT) =1 if missing xad assumed 0"

///	R&D
gen xrd_original=xrd
label var xad_original "(CSTAT) xrd before assuming missing=0"
replace xrd=0 if xrd==.
gen assume_xrd=(xrd_original==.)
label var assume_xrd "(CSTAT) =1 if missing xrd assumed 0"



						***===============================***
						*									*
						*  		  GENERATE VARIABLES		*
						*									*
						***===============================***	
///	GENERATE YEAR-ON-YEAR REVENUE CHANGE
capt n gen Frevt_yoy = F.revt-revt
label var Frevt_yoy "Next year revt - current year revt"



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

///	YEARS WITH OBSERVATIONS ON ALL NEEDED VARIABLES
capt n drop ps2*
capt n drop mark
mark mark1
markout mark1 trt3_sdw_pos Frevt_yoy dltt at age emp tobinq xad xrd
tab year trt3_sdw_neg if mark1==1
/*
           |   Treatment = 1 if
           | year-on-year over_rtg
           |  > 3 std dev of sdw
           |     and negative
      year |         0          1 |     Total
-----------+----------------------+----------
      2009 |       726         21 |       747 
      2010 |     1,177         13 |     1,190 
      2011 |     1,542          1 |     1,543 
      2012 |     2,033          3 |     2,036 
      2013 |     2,269          0 |     2,269 
      2014 |     2,475          0 |     2,475 
      2015 |     2,521          1 |     2,522 
-----------+----------------------+----------
     Total |    12,743         39 |    12,782 
*/
drop mark1



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
		osample(ps) nneighbor(`neighbors')
	capt n teffects psmatch (revt) (trt3_sdw_pos dltt at age emp tobinq) ///
		if ps==0, nneighbor(`neighbors')
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
						*			DV:	Revenue			*
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
						*	  DV: Next Year Revenue		*
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
						*		DIF-IN-DIFS 			*
						*		DV: Same year revenue	*
						*		Centered on treatment	*
						***===========================***
///	LOAD DATA
use data/matched-csrhub-cstat-2008-2017, clear

///	CENTER FIRMS IN TIME RELATIVE TO TREATMENT EVENTS
***	Generate treatment period variable
foreach variable in trt3_sdw_pos trt3_sdw_neg trt2_sdw_pos trt2_sdw_neg ///
	trt1_sdw_pos trt1_sdw_neg {
	gen `variable'_trtper = 0 if `variable'==1
	label var `variable'_trtper "Years since treatment"
	bysort gvkey_num: gen yeartreat = year if `variable'_trtper == 0
	bysort gvkey_num: egen yeartreatmax = max(yeartreat)
	replace `variable'_trtper = year - yeartreatmax
	drop yeartreat yeartreatmax
	replace `variable'_trtper=. if trt2_sdw_neg==.
}
	



***	Visualize
*	Line
bysort period: egen meanrevt = mean(revt)
twoway (line meanrevt period, sort xline(0))

bysort period: egen medrevt = median(revt)
twoway (line medrevt period, sort xline(0))

*	Boxplot
graph box revt, over(period)


///	ESTIMATION

reg revt period



	
	
	
	
	
	
	
	
	
						***===========================***
						*								*
						*		FIXED EFFECTS 			*
						*								*
						***===========================***	
***===========================***
*	REVENUE = F (CSRHUB) 		*
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
