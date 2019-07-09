***=====================================================***
*	CHAPTER 3 DATA ANALYSIS
*	FIRM-YEAR LEVEL DATASET COMBINING
*		CSRHUB/CSTAT AND KLD
***=====================================================***

					***===========***
					*	LOAD DATA	*
					***===========***
use data/csrhub-cstat-kld-matched.dta, clear

xtset

///	MODELS
*	Full mediation model:
*		CSR ----> SIC ----> Revenue
*	
*	Partial mediation model:
*		CSR ----> Revenue
*		  \     	^
*		   \       /
*			\     /
*			  SIC
*
*
*	Y = revt_usd
*	X = over_rtg
*	M = net_kld

/*	REGRESSIONS IN THE BARON AND KENNY (1986) APPROACH
	STEP 1: 		Y = cX + e1				revt_usd = c(over_rtg)
	STEP 2:			M = aX + e2				net_kld  = a(over_rtg)
	STEP 3:			Y = c'X + bM + e3		revt_usd = c'(over_rtg) + b(net_kld)
*/


					***===============================***
					*									*
					*  		DESCRIPTIVE STATISTICS		*
					*									*
					***===============================***	
///	VARIABLES
local variables revt_usd revt_usd_ihs over_rtg net_kld net_kld_str net_kld_con ///
	dltt at age emp xad xrd year

mark finalsample
markout finalsample `variables'
drop finalsample

///	CORRELATION TABLE
asdoc pwcorr `variables' , ///
	st(.05) dec(2) ///
	replace save(tables-and-figures/descriptive-statistics/ch3-summary-statistics.doc)

///	SUMMARY STATISTICS
asdoc sum `variables', ///
	dec(2) ///
	save(tables-and-figures/descriptive-statistics/ch3-summary-statistics.doc)



					***===================***
					*	ESTIMATION			*
					*	POOLED REGRESSION	*
					*	DV: SAME YEAR		*
					***===================***
///	DIRECT
reg revt_usd over_rtg, cluster(gvkey)
est sto pooldir1
outreg2 [pooldir1] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg revt_usd over_rtg i.year, cluster(gvkey)
est sto pooldir2

reg revt_usd over_rtg dltt i.year, cluster(gvkey)
est sto pooldir3

reg revt_usd over_rtg dltt at i.year, cluster(gvkey)
est sto pooldir4

reg revt_usd over_rtg dltt at emp i.year, cluster(gvkey)
est sto pooldir5

reg revt_usd over_rtg dltt at emp age i.year, cluster(gvkey)
est sto pooldir6

reg revt_usd over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto pooldir7

reg revt_usd over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooldir8

***	Table
outreg2 [pooldir2 pooldir3 pooldir4 pooldir5 ///
	pooldir6 pooldir7 pooldir8] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
reg revt_usd over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooldir9

***	Table
outreg2 [pooldir9] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
reg net_kld over_rtg, cluster(gvkey)
est sto poolmed1
outreg2 [poolmed1] ///
	using "tables-and-figures\ch3\ch3-pooled-mediator-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg net_kld over_rtg i.year, cluster(gvkey)
est sto poolmed2

reg net_kld over_rtg dltt i.year, cluster(gvkey)
est sto poolmed3

reg net_kld over_rtg dltt at i.year, cluster(gvkey)
est sto poolmed4

reg net_kld over_rtg dltt at emp i.year, cluster(gvkey)
est sto poolmed5

reg net_kld over_rtg dltt at emp age i.year, cluster(gvkey)
est sto poolmed6

reg net_kld over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto poolmed7

reg net_kld over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto poolmed8

***	Table
outreg2 [poolmed2 poolmed3 poolmed4 poolmed5 ///
	poolmed6 poolmed7 poolmed8] ///
	using "tables-and-figures\ch3\ch3-pooled-mediator-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
reg net_kld over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto poolmed9

*	Table
outreg2 [poolmed9] ///
	using "tables-and-figures\ch3\ch3-pooled-mediator-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore	


///	MEDIATION TEST
reg revt_usd net_kld over_rtg, cluster(gvkey)
est sto pooltest1
outreg2 [pooltest1] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg revt_usd net_kld over_rtg i.year, cluster(gvkey)
est sto pooltest2

reg revt_usd net_kld over_rtg dltt i.year, cluster(gvkey)
est sto pooltest3

reg revt_usd net_kld over_rtg dltt at i.year, cluster(gvkey)
est sto pooltest4

reg revt_usd net_kld over_rtg dltt at emp i.year, cluster(gvkey)
est sto pooltest5

reg revt_usd net_kld over_rtg dltt at emp age i.year, cluster(gvkey)
est sto pooltest6

reg revt_usd net_kld over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto pooltest7

reg revt_usd net_kld over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooltest8

*	Table
outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
	pooltest6 pooltest7 pooltest8] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
reg revt_usd net_kld over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooltest9

***	Table
outreg2 [pooltest9] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore




					***===================***
					*	ESTIMATION			*
					*	POOLED REGRESSION	*
					*	DV: SAME YEAR, TRANSFORMED TO INVERSE HYPERBOLIC SINE		*
					***===================***
///	DIRECT
reg revt_usd_ihs over_rtg, cluster(gvkey)
est sto pooldirihs1
outreg2 [pooldirihs1] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-same-year-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg revt_usd_ihs over_rtg i.year, cluster(gvkey)
est sto pooldirihs2

reg revt_usd_ihs over_rtg dltt i.year, cluster(gvkey)
est sto pooldirihs3

reg revt_usd_ihs over_rtg dltt at i.year, cluster(gvkey)
est sto pooldirihs4

reg revt_usd_ihs over_rtg dltt at emp i.year, cluster(gvkey)
est sto pooldirihs5

reg revt_usd_ihs over_rtg dltt at emp age i.year, cluster(gvkey)
est sto pooldirihs6

reg revt_usd_ihs over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto pooldirihs7

reg revt_usd_ihs over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooldirihs8

***	Table
outreg2 [pooldirihs2 pooldirihs3 pooldirihs4 pooldirihs5 ///
	pooldirihs6 pooldirihs7 pooldirihs8] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
reg revt_usd_ihs over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooldirihs9

***	Table
outreg2 [pooldirihs9] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
reg net_kld over_rtg, cluster(gvkey)
est sto poolmedihs1
outreg2 [poolmedihs1] ///
	using "tables-and-figures\ch3\ch3-pooled-mediator-same-year-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg net_kld over_rtg i.year, cluster(gvkey)
est sto poolmedihs2

reg net_kld over_rtg dltt i.year, cluster(gvkey)
est sto poolmedihs3

reg net_kld over_rtg dltt at i.year, cluster(gvkey)
est sto poolmedihs4

reg net_kld over_rtg dltt at emp i.year, cluster(gvkey)
est sto poolmedihs5

reg net_kld over_rtg dltt at emp age i.year, cluster(gvkey)
est sto poolmedihs6

reg net_kld over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto poolmedihs7

reg net_kld over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto poolmedihs8

***	Table
outreg2 [poolmedihs2 poolmedihs3 poolmedihs4 poolmedihs5 ///
	poolmedihs6 poolmedihs7 poolmedihs8] ///
	using "tables-and-figures\ch3\ch3-pooled-mediator-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
reg net_kld over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto poolmedihs9

*	Table
outreg2 [poolmedihs9] ///
	using "tables-and-figures\ch3\ch3-pooled-mediator-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore	


///	MEDIATION TEST
reg revt_usd_ihs net_kld over_rtg, cluster(gvkey)
est sto pooltestihs1
outreg2 [pooltestihs1] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-same-year-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg revt_usd_ihs net_kld over_rtg i.year, cluster(gvkey)
est sto pooltestihs2

reg revt_usd_ihs net_kld over_rtg dltt i.year, cluster(gvkey)
est sto pooltestihs3

reg revt_usd_ihs net_kld over_rtg dltt at i.year, cluster(gvkey)
est sto pooltestihs4

reg revt_usd_ihs net_kld over_rtg dltt at emp i.year, cluster(gvkey)
est sto pooltestihs5

reg revt_usd_ihs net_kld over_rtg dltt at emp age i.year, cluster(gvkey)
est sto pooltestihs6

reg revt_usd_ihs net_kld over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto pooltestihs7

reg revt_usd_ihs net_kld over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooltestihs8

*	Table
outreg2 [pooltestihs2 pooltestihs3 pooltestihs4 pooltestihs5 ///
	pooltestihs6 pooltestihs7 pooltestihs8] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
reg revt_usd_ihs net_kld over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooltestihs9

***	Table
outreg2 [pooltestihs9] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore










					***===========================***
					*	FIXED EFFECTS ESTIMATION	*
					*	DV: SAME YEAR				*
					***===========================***

///	DIRECT
xtreg revt_usd over_rtg, fe cluster(gvkey)
est sto fedir1
outreg2 [fedir1] ///
	using "tables-and-figures\ch3\ch3-fe-direct-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg revt_usd over_rtg i.year, fe cluster(gvkey)
est sto fedir2

xtreg revt_usd over_rtg dltt i.year, fe cluster(gvkey)
est sto fedir3

xtreg revt_usd over_rtg dltt at i.year, fe cluster(gvkey)
est sto fedir4

xtreg revt_usd over_rtg dltt at emp i.year, fe cluster(gvkey)
est sto fedir5

xtreg revt_usd over_rtg dltt at emp age i.year, fe cluster(gvkey)
est sto fedir6

xtreg revt_usd over_rtg dltt at emp age xad i.year, fe cluster(gvkey)
est sto fedir7

xtreg revt_usd over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto fedir8

***	Table
outreg2 [fedir2 fedir3 fedir4 fedir5 ///
	fedir6 fedir7 fedir8] ///
	using "tables-and-figures\ch3\ch3-fe-direct-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd i.year 2016o.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
xtreg revt_usd over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto fedir9

***	Table
outreg2 [fedir9] ///
	using "tables-and-figures\ch3\ch3-fe-direct-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd i.year 2016o.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
xtreg net_kld over_rtg, fe cluster(gvkey)
est sto femed1
outreg2 [femed1] ///
	using "tables-and-figures\ch3\ch3-fe-mediator-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg net_kld over_rtg i.year, fe cluster(gvkey)
est sto femed2

xtreg net_kld over_rtg dltt i.year, fe cluster(gvkey)
est sto femed3

xtreg net_kld over_rtg dltt at i.year, fe cluster(gvkey)
est sto femed4

xtreg net_kld over_rtg dltt at emp i.year, fe cluster(gvkey)
est sto femed5

xtreg net_kld over_rtg dltt at emp age i.year, fe cluster(gvkey)
est sto femed6

xtreg net_kld over_rtg dltt at emp age xad i.year, fe cluster(gvkey)
est sto femed7

xtreg net_kld over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto femed8

***	Table
outreg2 [femed2 femed3 femed4 femed5 ///
	femed6 femed7 femed8] ///
	using "tables-and-figures\ch3\ch3-fe-mediator-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year 2016o.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
xtreg net_kld over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto femed9

*	Table
outreg2 [femed9] ///
	using "tables-and-figures\ch3\ch3-fe-mediator-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year 2016o.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore	


///	MEDIATION TEST
xtreg revt_usd net_kld over_rtg, fe cluster(gvkey)
est sto fetest1
outreg2 [fetest1] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg revt_usd net_kld over_rtg i.year, fe cluster(gvkey)
est sto fetest2

xtreg revt_usd net_kld over_rtg dltt i.year, fe cluster(gvkey)
est sto fetest3

xtreg revt_usd net_kld over_rtg dltt at i.year, fe cluster(gvkey)
est sto fetest4

xtreg revt_usd net_kld over_rtg dltt at emp i.year, fe cluster(gvkey)
est sto fetest5

xtreg revt_usd net_kld over_rtg dltt at emp age i.year, fe cluster(gvkey)
est sto fetest6

xtreg revt_usd net_kld over_rtg dltt at emp age xad i.year, fe cluster(gvkey)
est sto fetest7

xtreg revt_usd net_kld over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto fetest8

*	Table
outreg2 [fetest2 fetest3 fetest4 fetest5 ///
	fetest6 fetest7 fetest8] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd i.year 2016o.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
xtreg revt_usd net_kld over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto fetest9

***	Table
outreg2 [fetest9] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd i.year 2016o.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore



					***===================***
					*	FIXED EFFECTS ESTIMATION			*
					*	DV: SAME YEAR, TRANSFORMED TO INVERSE HYPERBOLIC SINE		*
					***===================***
///	DIRECT
xtreg revt_usd_ihs over_rtg, fe cluster(gvkey)
est sto pooldirihs1
outreg2 [pooldirihs1] ///
	using "tables-and-figures\ch3\ch3-fe-direct-same-year-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

xtreg revt_usd_ihs over_rtg i.year, fe cluster(gvkey)
est sto pooldirihs2

xtreg revt_usd_ihs over_rtg dltt i.year, fe cluster(gvkey)
est sto pooldirihs3

xtreg revt_usd_ihs over_rtg dltt at i.year, fe cluster(gvkey)
est sto pooldirihs4

xtreg revt_usd_ihs over_rtg dltt at emp i.year, fe cluster(gvkey)
est sto pooldirihs5

xtreg revt_usd_ihs over_rtg dltt at emp age i.year, fe cluster(gvkey)
est sto pooldirihs6

xtreg revt_usd_ihs over_rtg dltt at emp age xad i.year, fe cluster(gvkey)
est sto pooldirihs7

xtreg revt_usd_ihs over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto pooldirihs8

***	Table
outreg2 [pooldirihs2 pooldirihs3 pooldirihs4 pooldirihs5 ///
	pooldirihs6 pooldirihs7 pooldirihs8] ///
	using "tables-and-figures\ch3\ch3-fe-direct-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
xtreg revt_usd_ihs over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto pooldirihs9

***	Table
outreg2 [pooldirihs9] ///
	using "tables-and-figures\ch3\ch3-fe-direct-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
xtreg net_kld over_rtg, fe cluster(gvkey)
est sto poolmedihs1
outreg2 [poolmedihs1] ///
	using "tables-and-figures\ch3\ch3-fe-mediator-same-year-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

xtreg net_kld over_rtg i.year, fe cluster(gvkey)
est sto poolmedihs2

xtreg net_kld over_rtg dltt i.year, fe cluster(gvkey)
est sto poolmedihs3

xtreg net_kld over_rtg dltt at i.year, fe cluster(gvkey)
est sto poolmedihs4

xtreg net_kld over_rtg dltt at emp i.year, fe cluster(gvkey)
est sto poolmedihs5

xtreg net_kld over_rtg dltt at emp age i.year, fe cluster(gvkey)
est sto poolmedihs6

xtreg net_kld over_rtg dltt at emp age xad i.year, fe cluster(gvkey)
est sto poolmedihs7

xtreg net_kld over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto poolmedihs8

***	Table
outreg2 [poolmedihs2 poolmedihs3 poolmedihs4 poolmedihs5 ///
	poolmedihs6 poolmedihs7 poolmedihs8] ///
	using "tables-and-figures\ch3\ch3-fe-mediator-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
xtreg net_kld over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto poolmedihs9

*	Table
outreg2 [poolmedihs9] ///
	using "tables-and-figures\ch3\ch3-fe-mediator-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore	


///	MEDIATION TEST
xtreg revt_usd_ihs net_kld over_rtg, fe cluster(gvkey)
est sto pooltestihs1
outreg2 [pooltestihs1] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-same-year-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

xtreg revt_usd_ihs net_kld over_rtg i.year, fe cluster(gvkey)
est sto pooltestihs2

xtreg revt_usd_ihs net_kld over_rtg dltt i.year, fe cluster(gvkey)
est sto pooltestihs3

xtreg revt_usd_ihs net_kld over_rtg dltt at i.year, fe cluster(gvkey)
est sto pooltestihs4

xtreg revt_usd_ihs net_kld over_rtg dltt at emp i.year, fe cluster(gvkey)
est sto pooltestihs5

xtreg revt_usd_ihs net_kld over_rtg dltt at emp age i.year, fe cluster(gvkey)
est sto pooltestihs6

xtreg revt_usd_ihs net_kld over_rtg dltt at emp age xad i.year, fe cluster(gvkey)
est sto pooltestihs7

xtreg revt_usd_ihs net_kld over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto pooltestihs8

*	Table
outreg2 [pooltestihs2 pooltestihs3 pooltestihs4 pooltestihs5 ///
	pooltestihs6 pooltestihs7 pooltestihs8] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
xtreg revt_usd_ihs net_kld over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto pooltestihs9

***	Table
outreg2 [pooltestihs9] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore





					***=======================***
					*	ESTIMATION				*
					*	POOLED REGRESSION		*
					*	TEMPORAL DYNAMICS		*
					*	DV: NEXT YEAR REVENUE	*
					***=======================***

///	DIRECT
reg f.revt_usd l.over_rtg, cluster(gvkey)
est sto pooldirlag1
outreg2 [pooldirlag1] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-time-effects", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg f.revt_usd l.over_rtg i.year, cluster(gvkey)
est sto pooldirlag2

reg f.revt_usd l.over_rtg l.dltt i.year, cluster(gvkey)
est sto pooldirlag3

reg f.revt_usd l.over_rtg l.dltt l.at i.year, cluster(gvkey)
est sto pooldirlag4

reg f.revt_usd l.over_rtg l.dltt l.at l.emp i.year, cluster(gvkey)
est sto pooldirlag5

reg f.revt_usd l.over_rtg l.dltt l.at l.emp l.age i.year, cluster(gvkey)
est sto pooldirlag6

reg f.revt_usd l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, cluster(gvkey)
est sto pooldirlag7

reg f.revt_usd l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
est sto pooldirlag8

***	Table
outreg2 [pooldirlag2 pooldirlag3 pooldirlag4 pooldirlag5 ///
	pooldirlag6 pooldirlag7 pooldirlag8] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-time-effects", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing l.xrd and l.xad are 0
*	CSTl.at Global has no l.xrd or l.xad dl.ata
preserve

*	l.xad
replace xad=0 if xad==. & in_cstatn==1

*	l.xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estiml.ate
reg f.revt_usd l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
est sto pooldirlag9

***	Table
outreg2 [pooldirlag9] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-time-effects", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
reg net_kld l.over_rtg, cluster(gvkey)
est sto poolmed1
outreg2 [poolmed1] ///
	using "tables-and-figures\ch3\ch3-pooled-mediator-time-effects", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg net_kld l.over_rtg i.year, cluster(gvkey)
est sto poolmed2

reg net_kld l.over_rtg l.dltt i.year, cluster(gvkey)
est sto poolmed3

reg net_kld l.over_rtg l.dltt l.at i.year, cluster(gvkey)
est sto poolmed4

reg net_kld l.over_rtg l.dltt l.at l.emp i.year, cluster(gvkey)
est sto poolmed5

reg net_kld l.over_rtg l.dltt l.at l.emp l.age i.year, cluster(gvkey)
est sto poolmed6

reg net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, cluster(gvkey)
est sto poolmed7

reg net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
est sto poolmed8

***	Table
outreg2 [poolmed2 poolmed3 poolmed4 poolmed5 ///
	poolmed6 poolmed7 poolmed8] ///
	using "tables-and-figures\ch3\ch3-pooled-mediator-time-effects", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
reg net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
est sto poolmed9

*	Table
outreg2 [poolmed9] ///
	using "tables-and-figures\ch3\ch3-pooled-mediator-time-effects", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore	


///	MEDIATION TEST
reg f.revt_usd net_kld l.over_rtg, cluster(gvkey)
est sto pooltest1
outreg2 [pooltest1] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-time-effects", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg f.revt_usd net_kld l.over_rtg i.year, cluster(gvkey)
est sto pooltest2

reg f.revt_usd net_kld l.over_rtg l.dltt i.year, cluster(gvkey)
est sto pooltest3

reg f.revt_usd net_kld l.over_rtg l.dltt l.at i.year, cluster(gvkey)
est sto pooltest4

reg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp i.year, cluster(gvkey)
est sto pooltest5

reg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp l.age i.year, cluster(gvkey)
est sto pooltest6

reg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, ///
	cluster(gvkey)
est sto pooltest7

reg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
	cluster(gvkey)
est sto pooltest8

*	Table
outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
	pooltest6 pooltest7 pooltest8] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-time-effects", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing l.xrd and l.xad are 0
*	CSTl.at Global has no l.xrd or l.xad dl.ata
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estiml.ate
reg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
	cluster(gvkey)
est sto pooltest9

***	Table
outreg2 [pooltest9] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-time-effects", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore





					***=======================***
					*	ESTIMATION				*
					*	FIXED EFFECTS REGRESSION		*
					*	TEMPORAL DYNAMICS		*
					*	DV: NEXT YEAR REVENUE	*
					***=======================***
xtset

///	DIRECT
xtreg f.revt_usd l.over_rtg, fe cluster(gvkey)
est sto fedirlag1
outreg2 [fedirlag1] ///
	using "tables-and-figures\ch3\ch3-fe-direct-time-effects", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg f.revt_usd l.over_rtg i.year, fe cluster(gvkey)
est sto fedirlag2

xtreg f.revt_usd l.over_rtg l.dltt i.year, fe cluster(gvkey)
est sto fedirlag3

xtreg f.revt_usd l.over_rtg l.dltt l.at i.year, fe cluster(gvkey)
est sto fedirlag4

xtreg f.revt_usd l.over_rtg l.dltt l.at l.emp i.year, fe cluster(gvkey)
est sto fedirlag5

xtreg f.revt_usd l.over_rtg l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
est sto fedirlag6

xtreg f.revt_usd l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, fe cluster(gvkey)
est sto fedirlag7

xtreg f.revt_usd l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
est sto fedirlag8

***	Table
outreg2 [fedirlag2 fedirlag3 fedirlag4 fedirlag5 ///
	fedirlag6 fedirlag7 fedirlag8] ///
	using "tables-and-figures\ch3\ch3-fe-direct-time-effects", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd 2016o.year i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)

***	Assume missing l.xrd and l.xad are 0
*	CSTl.at Global has no l.xrd or l.xad dl.ata
preserve

*	l.xad
replace xad=0 if xad==. & in_cstatn==1

*	l.xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estiml.ate
xtreg f.revt_usd l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
est sto fedirlag9

***	Table
outreg2 [fedirlag9] ///
	using "tables-and-figures\ch3\ch3-fe-direct-time-effects", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd 2016o.year i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
xtreg net_kld l.over_rtg, fe cluster(gvkey)
est sto femedlag1
outreg2 [femedlag1] ///
	using "tables-and-figures\ch3\ch3-fe-mediator-time-effects", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg net_kld l.over_rtg i.year, fe cluster(gvkey)
est sto femedlag2

xtreg net_kld l.over_rtg l.dltt i.year, fe cluster(gvkey)
est sto femedlag3

xtreg net_kld l.over_rtg l.dltt l.at i.year, fe cluster(gvkey)
est sto femedlag4

xtreg net_kld l.over_rtg l.dltt l.at l.emp i.year, fe cluster(gvkey)
est sto femedlag5

xtreg net_kld l.over_rtg l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
est sto femedlag6

xtreg net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, fe cluster(gvkey)
est sto femedlag7

xtreg net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
est sto femedlag8

***	Table
outreg2 [femedlag2 femedlag3 femedlag4 femedlag5 ///
	femedlag6 femedlag7 femedlag8] ///
	using "tables-and-figures\ch3\ch3-fe-mediator-time-effects", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
xtreg net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
est sto femedlag9

*	Table
outreg2 [femedlag9] ///
	using "tables-and-figures\ch3\ch3-fe-mediator-time-effects", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore	


///	MEDIATION TEST
xtreg f.revt_usd net_kld l.over_rtg, fe cluster(gvkey)
est sto fetestlag1
outreg2 [fetestlag1] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-time-effects", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg f.revt_usd net_kld l.over_rtg i.year, fe cluster(gvkey)
est sto fetestlag2

xtreg f.revt_usd net_kld l.over_rtg l.dltt i.year, fe cluster(gvkey)
est sto fetestlag3

xtreg f.revt_usd net_kld l.over_rtg l.dltt l.at i.year, fe cluster(gvkey)
est sto fetestlag4

xtreg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp i.year, fe cluster(gvkey)
est sto fetestlag5

xtreg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
est sto fetestlag6

xtreg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, fe ///
	cluster(gvkey)
est sto fetestlag7

xtreg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe ///
	cluster(gvkey)
est sto fetestlag8

*	Table
outreg2 [fetestlag2 fetestlag3 fetestlag4 fetestlag5 ///
	fetestlag6 fetestlag7 fetestlag8] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-time-effects", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd 2016o.year i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)

***	Assume missing l.xrd and l.xad are 0
*	CSTl.at Global has no l.xrd or l.xad dl.ata
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estiml.ate
xtreg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe ///
	cluster(gvkey)
est sto fetestlag9

***	Table
outreg2 [fetestlag9] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-time-effects", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd 2016o.year i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore

*END
