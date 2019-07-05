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
local variables revt_usd revt_usd_ihs over_rtg net_kld dltt at age emp xad xrd year

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
					*	TIME LAG EFFECTS	*
					***===================***

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

reg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, cluster(gvkey)
est sto pooltest7

reg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
est sto pooltest8

*	Table
outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
	pooltest6 pooltest7 pooltest8] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-time-effects", excel word ///
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
reg f.revt_usd net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
est sto pooltest9

***	Table
outreg2 [pooltest9] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-time-effects", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore





					***===========================***
					*	FIXED EFFECTS ESTIMATION	*
					*	DV: SAME YEAR				*
					***===========================***

///	DIRECT
xtreg revt_usd over_rtg, fe cluster(gvkey)
est sto pooldir1
outreg2 [pooldir1] ///
	using "tables-and-figures\ch3\ch3-fe-direct-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg revt_usd over_rtg i.year, fe cluster(gvkey)
est sto pooldir2

xtreg revt_usd over_rtg dltt i.year, fe cluster(gvkey)
est sto pooldir3

xtreg revt_usd over_rtg dltt at i.year, fe cluster(gvkey)
est sto pooldir4

xtreg revt_usd over_rtg dltt at emp i.year, fe cluster(gvkey)
est sto pooldir5

xtreg revt_usd over_rtg dltt at emp age i.year, fe cluster(gvkey)
est sto pooldir6

xtreg revt_usd over_rtg dltt at emp age xad i.year, fe cluster(gvkey)
est sto pooldir7

xtreg revt_usd over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto pooldir8

***	Table
outreg2 [pooldir2 pooldir3 pooldir4 pooldir5 ///
	pooldir6 pooldir7 pooldir8] ///
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
est sto pooldir9

***	Table
outreg2 [pooldir9] ///
	using "tables-and-figures\ch3\ch3-fe-direct-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd i.year o.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
xtreg net_kld over_rtg, fe cluster(gvkey)
est sto poolmed1
outreg2 [poolmed1] ///
	using "tables-and-figures\ch3\ch3-fe-mediator-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg net_kld over_rtg i.year, fe cluster(gvkey)
est sto poolmed2

xtreg net_kld over_rtg dltt i.year, fe cluster(gvkey)
est sto poolmed3

xtreg net_kld over_rtg dltt at i.year, fe cluster(gvkey)
est sto poolmed4

xtreg net_kld over_rtg dltt at emp i.year, fe cluster(gvkey)
est sto poolmed5

xtreg net_kld over_rtg dltt at emp age i.year, fe cluster(gvkey)
est sto poolmed6

xtreg net_kld over_rtg dltt at emp age xad i.year, fe cluster(gvkey)
est sto poolmed7

xtreg net_kld over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto poolmed8

***	Table
outreg2 [poolmed2 poolmed3 poolmed4 poolmed5 ///
	poolmed6 poolmed7 poolmed8] ///
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
est sto poolmed9

*	Table
outreg2 [poolmed9] ///
	using "tables-and-figures\ch3\ch3-fe-mediator-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year 2016o.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore	


///	MEDIATION TEST
xtreg revt_usd net_kld over_rtg, fe cluster(gvkey)
est sto pooltest1
outreg2 [pooltest1] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg revt_usd net_kld over_rtg i.year, fe cluster(gvkey)
est sto pooltest2

xtreg revt_usd net_kld over_rtg dltt i.year, fe cluster(gvkey)
est sto pooltest3

xtreg revt_usd net_kld over_rtg dltt at i.year, fe cluster(gvkey)
est sto pooltest4

xtreg revt_usd net_kld over_rtg dltt at emp i.year, fe cluster(gvkey)
est sto pooltest5

xtreg revt_usd net_kld over_rtg dltt at emp age i.year, fe cluster(gvkey)
est sto pooltest6

xtreg revt_usd net_kld over_rtg dltt at emp age xad i.year, fe cluster(gvkey)
est sto pooltest7

xtreg revt_usd net_kld over_rtg dltt at emp age xad xrd i.year, fe cluster(gvkey)
est sto pooltest8

*	Table
outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
	pooltest6 pooltest7 pooltest8] ///
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
est sto pooltest9

***	Table
outreg2 [pooltest9] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd i.year 2016o.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore
















*END
