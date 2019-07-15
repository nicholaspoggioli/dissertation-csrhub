***=====================================================***
*	CHAPTER 4 DATA ANALYSIS
*	FIRM-YEAR LEVEL DATASET COMBINING
*		CSRHUB/CSTAT AND KLD
***=====================================================***

/*	ANLAYSIS PLAN: TEST IF SIC IS STAKEHOLDER SPECIFIC
	RUN THE MEDIATION MODELS FROM CHAPTER 2 FOR CSRHUB AND KLD FOR
		-	Customers
				KLD:	pro_str pro_con
				CSRHub:	prod_rtg
		-	Employees
				KLD:	emp_str* emp_con*
				CSRHub:	emp_rtg
		-	Natural environment
				KLD:	env_str env_con
				CSRHub:	enviro_rtg
*/
					***===========***
					*	LOAD DATA	*
					***===========***
use data/csrhub-cstat-kld-matched.dta, clear

xtset

					***===============***
					*	PREP KLD DATA	*
					***===============***
///	RENAME VARIABLES
rename (sum_emp_con sum_emp_str sum_env_con sum_env_str sum_pro_con sum_pro_str) ///
	(net_kld_emp_con net_kld_emp_str net_kld_env_con net_kld_env_str ///
	net_kld_prod_con net_kld_prod_str)

label var net_kld_prod_str "(KLD) sum product strengths"
label var net_kld_prod_con "(KLD) sum product concerns"
label var net_kld_emp_str "(KLD) sum employee strengths"
label var net_kld_emp_con "(KLD) sum employee concerns"
label var net_kld_env_str "(KLD) sum environment strengths"
label var net_kld_env_con "(KLD) sum environment concerns"
	
///	GENERATE NET KLD VARIABLES
gen net_kld_prod = net_kld_prod_str - net_kld_prod_con
gen net_kld_env = net_kld_env_str - net_kld_env_con
gen net_kld_emp = net_kld_emp_str - net_kld_emp_con

label var net_kld_prod "(KLD) net product score (strengths - concerns)"
label var net_kld_env "(KLD) net environment score (strengths - concerns)"
label var net_kld_emp "(KLD) net employee score (strengths - concerns)"



					***===================***
					*	PREP CSRHUB DATA	*
					***===================***
///	RENAME VARIABLES
rename (prod_rtg_lym emp_rtg_lym enviro_rtg_lym) (prod_rtg emp_rtg env_rtg)

label var prod_rtg "(CSRHUB) product rating" 
label var emp_rtg "(CSRHUB) employee rating"
label var env_rtg "(CSRHUB) environment rating"


					***===============================***
					*									*
					*  		DESCRIPTIVE STATISTICS		*
					*									*
					***===============================***	
///	VARIABLES
local variables revt_usd revt_usd_ihs ///
	prod_rtg net_kld_prod net_kld_prod_str net_kld_prod_con ///	
	emp_rtg net_kld_emp net_kld_emp_str net_kld_emp_con ///
	env_rtg net_kld_env net_kld_env_str net_kld_env_con ///
	dltt at age emp xad xrd year

///	CORRELATION TABLE
asdoc pwcorr `variables' , ///
	st(.05) dec(2) ///
	replace save(tables-and-figures/descriptive-statistics/ch4-summary-statistics.doc)

///	SUMMARY STATISTICS
asdoc sum `variables', ///
	dec(2) ///
	save(tables-and-figures/descriptive-statistics/ch4-summary-statistics.doc)
	
///	REVENUE
asdoc sum revt_usd revt_usd_ihs, d ///
	dec(2) ///
	save(tables-and-figures/descriptive-statistics/ch4-summary-statistics-revenue-comparison.doc)



					***=======================***
					*							*
					*	CUSTOMER STAKEHOLDERS	*
					*							*
					***=======================***
***===================***
*	POOLED REGRESSION	*
*	DV:	SAME YEAR		*
***===================***					
local iv prod_rtg
local mediator net_kld_prod

foreach dv in revt_usd revt_usd_ihs {

	///	DIRECT
	reg `dv' `iv', cluster(gvkey)
	est sto pooldir1
	outreg2 [pooldir1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg `dv' `iv' i.year, cluster(gvkey)
	est sto pooldir2

	reg `dv' `iv' dltt i.year, cluster(gvkey)
	est sto pooldir3

	reg `dv' `iv' dltt at i.year, cluster(gvkey)
	est sto pooldir4

	reg `dv' `iv' dltt at emp i.year, cluster(gvkey)
	est sto pooldir5

	reg `dv' `iv' dltt at emp age i.year, cluster(gvkey)
	est sto pooldir6

	reg `dv' `iv' dltt at emp age xad i.year, cluster(gvkey)
	est sto pooldir7

	reg `dv' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto pooldir8

	***	Table
	outreg2 [pooldir2 pooldir3 pooldir4 pooldir5 ///
		pooldir6 pooldir7 pooldir8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	reg `dv' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto pooldir9

	***	Table
	outreg2 [pooldir9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	reg `mediator' `iv', cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg `mediator' `iv' i.year, cluster(gvkey)
	est sto poolmed2

	reg `mediator' `iv' dltt i.year, cluster(gvkey)
	est sto poolmed3

	reg `mediator' `iv' dltt at i.year, cluster(gvkey)
	est sto poolmed4

	reg `mediator' `iv' dltt at emp i.year, cluster(gvkey)
	est sto poolmed5

	reg `mediator' `iv' dltt at emp age i.year, cluster(gvkey)
	est sto poolmed6

	reg `mediator' `iv' dltt at emp age xad i.year, cluster(gvkey)
	est sto poolmed7

	reg `mediator' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto poolmed8

	***	Table
	outreg2 [poolmed2 poolmed3 poolmed4 poolmed5 ///
		poolmed6 poolmed7 poolmed8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	reg `mediator' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto poolmed9

	*	Table
	outreg2 [poolmed9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	reg `dv' `mediator' `iv', cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg `dv' `mediator' `iv' i.year, cluster(gvkey)
	est sto pooltest2

	reg `dv' `mediator' `iv' dltt i.year, cluster(gvkey)
	est sto pooltest3

	reg `dv' `mediator' `iv' dltt at i.year, cluster(gvkey)
	est sto pooltest4

	reg `dv' `mediator' `iv' dltt at emp i.year, cluster(gvkey)
	est sto pooltest5

	reg `dv' `mediator' `iv' dltt at emp age i.year, cluster(gvkey)
	est sto pooltest6

	reg `dv' `mediator' `iv' dltt at emp age xad i.year, cluster(gvkey)
	est sto pooltest7

	reg `dv' `mediator' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto pooltest8

	*	Table
	outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
		pooltest6 pooltest7 pooltest8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	reg `dv' `mediator' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto pooltest9

	***	Table
	outreg2 [pooltest9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore

}
					


***===========================***
*	FIXED EFFECTS ESTIMATION	*
*	DV: SAME YEAR				*
***===========================***
local iv prod_rtg
local mediator net_kld_prod

foreach dv in revt_usd revt_usd_ihs `dv' {

	///	DIRECT
	xtreg `dv' `iv', fe cluster(gvkey)
	est sto fedir1
	outreg2 [fedir1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-direct-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)

	xtreg `dv' `iv' i.year, fe cluster(gvkey)
	est sto fedir2

	xtreg `dv' `iv' dltt i.year, fe cluster(gvkey)
	est sto fedir3

	xtreg `dv' `iv' dltt at i.year, fe cluster(gvkey)
	est sto fedir4

	xtreg `dv' `iv' dltt at emp i.year, fe cluster(gvkey)
	est sto fedir5

	xtreg `dv' `iv' dltt at emp age i.year, fe cluster(gvkey)
	est sto fedir6

	xtreg `dv' `iv' dltt at emp age xad i.year, fe cluster(gvkey)
	est sto fedir7

	xtreg `dv' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto fedir8

	***	Table
	outreg2 [fedir2 fedir3 fedir4 fedir5 ///
		fedir6 fedir7 fedir8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-direct-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	xtreg `dv' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto fedir9

	***	Table
	outreg2 [fedir9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-direct-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	xtreg `mediator' `iv', fe cluster(gvkey)
	est sto femed1
	outreg2 [femed1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediator-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)

	xtreg `mediator' `iv' i.year, fe cluster(gvkey)
	est sto femed2

	xtreg `mediator' `iv' dltt i.year, fe cluster(gvkey)
	est sto femed3

	xtreg `mediator' `iv' dltt at i.year, fe cluster(gvkey)
	est sto femed4

	xtreg `mediator' `iv' dltt at emp i.year, fe cluster(gvkey)
	est sto femed5

	xtreg `mediator' `iv' dltt at emp age i.year, fe cluster(gvkey)
	est sto femed6

	xtreg `mediator' `iv' dltt at emp age xad i.year, fe cluster(gvkey)
	est sto femed7

	xtreg `mediator' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto femed8

	***	Table
	outreg2 [femed2 femed3 femed4 femed5 ///
		femed6 femed7 femed8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediator-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	xtreg `mediator' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto femed9

	*	Table
	outreg2 [femed9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediator-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	xtreg `dv' `mediator' `iv', fe cluster(gvkey)
	est sto fetest1
	outreg2 [fetest1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediation-test-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)

	xtreg `dv' `mediator' `iv' i.year, fe cluster(gvkey)
	est sto fetest2

	xtreg `dv' `mediator' `iv' dltt i.year, fe cluster(gvkey)
	est sto fetest3

	xtreg `dv' `mediator' `iv' dltt at i.year, fe cluster(gvkey)
	est sto fetest4

	xtreg `dv' `mediator' `iv' dltt at emp i.year, fe cluster(gvkey)
	est sto fetest5

	xtreg `dv' `mediator' `iv' dltt at emp age i.year, fe cluster(gvkey)
	est sto fetest6

	xtreg `dv' `mediator' `iv' dltt at emp age xad i.year, fe cluster(gvkey)
	est sto fetest7

	xtreg `dv' `mediator' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto fetest8

	*	Table
	outreg2 [fetest2 fetest3 fetest4 fetest5 ///
		fetest6 fetest7 fetest8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediation-test-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	xtreg `dv' `mediator' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto fetest9

	***	Table
	outreg2 [fetest9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediation-test-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore

}



***===========================***
*	POOLED ESTIMATION			*
*	DV: TEMPORAL DYNAMICS		*
***===========================***
local iv prod_rtg
local mediator net_kld_prod

foreach dv in revt_usd revt_usd_ihs {


	///	DIRECT
	reg f.`dv' l.`iv', cluster(gvkey)
	est sto pooldirlag1
	outreg2 [pooldirlag1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-time-effects", ///
		replace excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg f.`dv' l.`iv' i.year, cluster(gvkey)
	est sto pooldirlag2

	reg f.`dv' l.`iv' l.dltt i.year, cluster(gvkey)
	est sto pooldirlag3

	reg f.`dv' l.`iv' l.dltt l.at i.year, cluster(gvkey)
	est sto pooldirlag4

	reg f.`dv' l.`iv' l.dltt l.at l.emp i.year, cluster(gvkey)
	est sto pooldirlag5

	reg f.`dv' l.`iv' l.dltt l.at l.emp l.age i.year, cluster(gvkey)
	est sto pooldirlag6

	reg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, cluster(gvkey)
	est sto pooldirlag7

	reg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
	est sto pooldirlag8

	***	Table
	outreg2 [pooldirlag2 pooldirlag3 pooldirlag4 pooldirlag5 ///
		pooldirlag6 pooldirlag7 pooldirlag8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-time-effects", ///
		excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing l.xrd and l.xad are 0
	*	CSTl.at Global has no l.xrd or l.xad dl.ata
	preserve

	*	l.xad
	replace xad=0 if xad==. & in_cstatn==1

	*	l.xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estiml.ate
	reg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
	est sto pooldirlag9

	***	Table
	outreg2 [pooldirlag9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-time-effects", excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	reg `mediator' l.`iv', cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-time-effects", ///
		replace excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg `mediator' l.`iv' i.year, cluster(gvkey)
	est sto poolmed2

	reg `mediator' l.`iv' l.dltt i.year, cluster(gvkey)
	est sto poolmed3

	reg `mediator' l.`iv' l.dltt l.at i.year, cluster(gvkey)
	est sto poolmed4

	reg `mediator' l.`iv' l.dltt l.at l.emp i.year, cluster(gvkey)
	est sto poolmed5

	reg `mediator' l.`iv' l.dltt l.at l.emp l.age i.year, cluster(gvkey)
	est sto poolmed6

	reg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, cluster(gvkey)
	est sto poolmed7

	reg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
	est sto poolmed8

	***	Table
	outreg2 [poolmed2 poolmed3 poolmed4 poolmed5 ///
		poolmed6 poolmed7 poolmed8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-time-effects", excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	reg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
	est sto poolmed9

	*	Table
	outreg2 [poolmed9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-time-effects", excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	reg f.`dv' `mediator' l.`iv', cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-time-effects", ///
		replace excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg f.`dv' `mediator' l.`iv' i.year, cluster(gvkey)
	est sto pooltest2

	reg f.`dv' `mediator' l.`iv' l.dltt i.year, cluster(gvkey)
	est sto pooltest3

	reg f.`dv' `mediator' l.`iv' l.dltt l.at i.year, cluster(gvkey)
	est sto pooltest4

	reg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp i.year, cluster(gvkey)
	est sto pooltest5

	reg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age i.year, cluster(gvkey)
	est sto pooltest6

	reg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, ///
		cluster(gvkey)
	est sto pooltest7

	reg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
		cluster(gvkey)
	est sto pooltest8

	*	Table
	outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
		pooltest6 pooltest7 pooltest8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-time-effects", ///
		excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing l.xrd and l.xad are 0
	*	CSTl.at Global has no l.xrd or l.xad dl.ata
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estiml.ate
	reg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
		cluster(gvkey)
	est sto pooltest9

	***	Table
	outreg2 [pooltest9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-time-effects", ///
		excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore

}


***===============================***
*	FIXED EFFECTS ESTIMATION		*
*	DV: TEMPORAL DYNAMICS			*
***===============================***
xtset 

local iv prod_rtg
local mediator net_kld_prod

foreach dv in revt_usd revt_usd_ihs {

	///	DIRECT
	reg f.`dv' l.`iv', cluster(gvkey)
	est sto pooldirlag1
	outreg2 [pooldirlag1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-time-effects-ihs", ///
		replace excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg f.`dv' l.`iv' i.year, cluster(gvkey)
	est sto pooldirlag2

	reg f.`dv' l.`iv' l.dltt i.year, cluster(gvkey)
	est sto pooldirlag3

	reg f.`dv' l.`iv' l.dltt l.at i.year, cluster(gvkey)
	est sto pooldirlag4

	reg f.`dv' l.`iv' l.dltt l.at l.emp i.year, cluster(gvkey)
	est sto pooldirlag5

	reg f.`dv' l.`iv' l.dltt l.at l.emp l.age i.year, cluster(gvkey)
	est sto pooldirlag6

	reg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, cluster(gvkey)
	est sto pooldirlag7

	reg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
	est sto pooldirlag8

	***	Table
	outreg2 [pooldirlag2 pooldirlag3 pooldirlag4 pooldirlag5 ///
		pooldirlag6 pooldirlag7 pooldirlag8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-time-effects-ihs", ///
		excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing l.xrd and l.xad are 0
	*	CSTl.at Global has no l.xrd or l.xad dl.ata
	preserve

	*	l.xad
	replace xad=0 if xad==. & in_cstatn==1

	*	l.xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estiml.ate
	reg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
	est sto pooldirlag9

	***	Table
	outreg2 [pooldirlag9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-time-effects-ihs", excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	reg `mediator' l.`iv', cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-time-effects-ihs", ///
		replace excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg `mediator' l.`iv' i.year, cluster(gvkey)
	est sto poolmed2

	reg `mediator' l.`iv' l.dltt i.year, cluster(gvkey)
	est sto poolmed3

	reg `mediator' l.`iv' l.dltt l.at i.year, cluster(gvkey)
	est sto poolmed4

	reg `mediator' l.`iv' l.dltt l.at l.emp i.year, cluster(gvkey)
	est sto poolmed5

	reg `mediator' l.`iv' l.dltt l.at l.emp l.age i.year, cluster(gvkey)
	est sto poolmed6

	reg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, cluster(gvkey)
	est sto poolmed7

	reg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
	est sto poolmed8

	***	Table
	outreg2 [poolmed2 poolmed3 poolmed4 poolmed5 ///
		poolmed6 poolmed7 poolmed8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-time-effects-ihs", excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	reg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
	est sto poolmed9

	*	Table
	outreg2 [poolmed9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-time-effects-ihs", excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	reg f.`dv' `mediator' l.`iv', cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-time-effects-ihs", ///
		replace excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg f.`dv' `mediator' l.`iv' i.year, cluster(gvkey)
	est sto pooltest2

	reg f.`dv' `mediator' l.`iv' l.dltt i.year, cluster(gvkey)
	est sto pooltest3

	reg f.`dv' `mediator' l.`iv' l.dltt l.at i.year, cluster(gvkey)
	est sto pooltest4

	reg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp i.year, cluster(gvkey)
	est sto pooltest5

	reg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age i.year, cluster(gvkey)
	est sto pooltest6

	reg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, ///
		cluster(gvkey)
	est sto pooltest7

	reg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
		cluster(gvkey)
	est sto pooltest8

	*	Table
	outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
		pooltest6 pooltest7 pooltest8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-time-effects-ihs", ///
		excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing l.xrd and l.xad are 0
	*	CSTl.at Global has no l.xrd or l.xad dl.ata
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estiml.ate
	reg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
		cluster(gvkey)
	est sto pooltest9

	***	Table
	outreg2 [pooltest9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-time-effects-ihs", ///
		excel word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore

}












					***=======================***
					*							*
					*	EMPLOYEE STAKEHOLDERS	*
					*							*
					***=======================***
***===================***
*	POOLED REGRESSION	*
*	DV:	SAME YEAR		*
***===================***					
local iv emp_rtg
local mediator net_kld_emp

foreach dv in revt_usd revt_usd_ihs {

	///	DIRECT
	reg `dv' `iv', cluster(gvkey)
	est sto pooldir1
	outreg2 [pooldir1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg `dv' `iv' i.year, cluster(gvkey)
	est sto pooldir2

	reg `dv' `iv' dltt i.year, cluster(gvkey)
	est sto pooldir3

	reg `dv' `iv' dltt at i.year, cluster(gvkey)
	est sto pooldir4

	reg `dv' `iv' dltt at emp i.year, cluster(gvkey)
	est sto pooldir5

	reg `dv' `iv' dltt at emp age i.year, cluster(gvkey)
	est sto pooldir6

	reg `dv' `iv' dltt at emp age xad i.year, cluster(gvkey)
	est sto pooldir7

	reg `dv' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto pooldir8

	***	Table
	outreg2 [pooldir2 pooldir3 pooldir4 pooldir5 ///
		pooldir6 pooldir7 pooldir8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	reg `dv' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto pooldir9

	***	Table
	outreg2 [pooldir9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	reg `mediator' `iv', cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg `mediator' `iv' i.year, cluster(gvkey)
	est sto poolmed2

	reg `mediator' `iv' dltt i.year, cluster(gvkey)
	est sto poolmed3

	reg `mediator' `iv' dltt at i.year, cluster(gvkey)
	est sto poolmed4

	reg `mediator' `iv' dltt at emp i.year, cluster(gvkey)
	est sto poolmed5

	reg `mediator' `iv' dltt at emp age i.year, cluster(gvkey)
	est sto poolmed6

	reg `mediator' `iv' dltt at emp age xad i.year, cluster(gvkey)
	est sto poolmed7

	reg `mediator' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto poolmed8

	***	Table
	outreg2 [poolmed2 poolmed3 poolmed4 poolmed5 ///
		poolmed6 poolmed7 poolmed8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	reg `mediator' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto poolmed9

	*	Table
	outreg2 [poolmed9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	reg `dv' `mediator' `iv', cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg `dv' `mediator' `iv' i.year, cluster(gvkey)
	est sto pooltest2

	reg `dv' `mediator' `iv' dltt i.year, cluster(gvkey)
	est sto pooltest3

	reg `dv' `mediator' `iv' dltt at i.year, cluster(gvkey)
	est sto pooltest4

	reg `dv' `mediator' `iv' dltt at emp i.year, cluster(gvkey)
	est sto pooltest5

	reg `dv' `mediator' `iv' dltt at emp age i.year, cluster(gvkey)
	est sto pooltest6

	reg `dv' `mediator' `iv' dltt at emp age xad i.year, cluster(gvkey)
	est sto pooltest7

	reg `dv' `mediator' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto pooltest8

	*	Table
	outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
		pooltest6 pooltest7 pooltest8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	reg `dv' `mediator' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto pooltest9

	***	Table
	outreg2 [pooltest9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore

}
					


***===========================***
*	FIXED EFFECTS ESTIMATION	*
*	DV: SAME YEAR				*
***===========================***
local iv emp_rtg
local mediator net_kld_emp

foreach dv in revt_usd revt_usd_ihs `dv' {

	///	DIRECT
	xtreg `dv' `iv', fe cluster(gvkey)
	est sto fedir1
	outreg2 [fedir1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-direct-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)

	xtreg `dv' `iv' i.year, fe cluster(gvkey)
	est sto fedir2

	xtreg `dv' `iv' dltt i.year, fe cluster(gvkey)
	est sto fedir3

	xtreg `dv' `iv' dltt at i.year, fe cluster(gvkey)
	est sto fedir4

	xtreg `dv' `iv' dltt at emp i.year, fe cluster(gvkey)
	est sto fedir5

	xtreg `dv' `iv' dltt at emp age i.year, fe cluster(gvkey)
	est sto fedir6

	xtreg `dv' `iv' dltt at emp age xad i.year, fe cluster(gvkey)
	est sto fedir7

	xtreg `dv' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto fedir8

	***	Table
	outreg2 [fedir2 fedir3 fedir4 fedir5 ///
		fedir6 fedir7 fedir8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-direct-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	xtreg `dv' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto fedir9

	***	Table
	outreg2 [fedir9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-direct-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	xtreg `mediator' `iv', fe cluster(gvkey)
	est sto femed1
	outreg2 [femed1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediator-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)

	xtreg `mediator' `iv' i.year, fe cluster(gvkey)
	est sto femed2

	xtreg `mediator' `iv' dltt i.year, fe cluster(gvkey)
	est sto femed3

	xtreg `mediator' `iv' dltt at i.year, fe cluster(gvkey)
	est sto femed4

	xtreg `mediator' `iv' dltt at emp i.year, fe cluster(gvkey)
	est sto femed5

	xtreg `mediator' `iv' dltt at emp age i.year, fe cluster(gvkey)
	est sto femed6

	xtreg `mediator' `iv' dltt at emp age xad i.year, fe cluster(gvkey)
	est sto femed7

	xtreg `mediator' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto femed8

	***	Table
	outreg2 [femed2 femed3 femed4 femed5 ///
		femed6 femed7 femed8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediator-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	xtreg `mediator' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto femed9

	*	Table
	outreg2 [femed9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediator-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	xtreg `dv' `mediator' `iv', fe cluster(gvkey)
	est sto fetest1
	outreg2 [fetest1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediation-test-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)

	xtreg `dv' `mediator' `iv' i.year, fe cluster(gvkey)
	est sto fetest2

	xtreg `dv' `mediator' `iv' dltt i.year, fe cluster(gvkey)
	est sto fetest3

	xtreg `dv' `mediator' `iv' dltt at i.year, fe cluster(gvkey)
	est sto fetest4

	xtreg `dv' `mediator' `iv' dltt at emp i.year, fe cluster(gvkey)
	est sto fetest5

	xtreg `dv' `mediator' `iv' dltt at emp age i.year, fe cluster(gvkey)
	est sto fetest6

	xtreg `dv' `mediator' `iv' dltt at emp age xad i.year, fe cluster(gvkey)
	est sto fetest7

	xtreg `dv' `mediator' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto fetest8

	*	Table
	outreg2 [fetest2 fetest3 fetest4 fetest5 ///
		fetest6 fetest7 fetest8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediation-test-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	xtreg `dv' `mediator' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto fetest9

	***	Table
	outreg2 [fetest9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediation-test-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore

}











					***===========================***
					*								*
					*	ENVIRONMENT STAKEHOLDERS	*
					*								*
					***===========================***
***===================***
*	POOLED REGRESSION	*
*	DV:	SAME YEAR		*
***===================***					
local iv env_rtg
local mediator net_kld_env

foreach dv in revt_usd revt_usd_ihs {

	///	DIRECT
	reg `dv' `iv', cluster(gvkey)
	est sto pooldir1
	outreg2 [pooldir1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg `dv' `iv' i.year, cluster(gvkey)
	est sto pooldir2

	reg `dv' `iv' dltt i.year, cluster(gvkey)
	est sto pooldir3

	reg `dv' `iv' dltt at i.year, cluster(gvkey)
	est sto pooldir4

	reg `dv' `iv' dltt at emp i.year, cluster(gvkey)
	est sto pooldir5

	reg `dv' `iv' dltt at emp age i.year, cluster(gvkey)
	est sto pooldir6

	reg `dv' `iv' dltt at emp age xad i.year, cluster(gvkey)
	est sto pooldir7

	reg `dv' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto pooldir8

	***	Table
	outreg2 [pooldir2 pooldir3 pooldir4 pooldir5 ///
		pooldir6 pooldir7 pooldir8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	reg `dv' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto pooldir9

	***	Table
	outreg2 [pooldir9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-direct-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	reg `mediator' `iv', cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg `mediator' `iv' i.year, cluster(gvkey)
	est sto poolmed2

	reg `mediator' `iv' dltt i.year, cluster(gvkey)
	est sto poolmed3

	reg `mediator' `iv' dltt at i.year, cluster(gvkey)
	est sto poolmed4

	reg `mediator' `iv' dltt at emp i.year, cluster(gvkey)
	est sto poolmed5

	reg `mediator' `iv' dltt at emp age i.year, cluster(gvkey)
	est sto poolmed6

	reg `mediator' `iv' dltt at emp age xad i.year, cluster(gvkey)
	est sto poolmed7

	reg `mediator' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto poolmed8

	***	Table
	outreg2 [poolmed2 poolmed3 poolmed4 poolmed5 ///
		poolmed6 poolmed7 poolmed8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	reg `mediator' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto poolmed9

	*	Table
	outreg2 [poolmed9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediator-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	reg `dv' `mediator' `iv', cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	reg `dv' `mediator' `iv' i.year, cluster(gvkey)
	est sto pooltest2

	reg `dv' `mediator' `iv' dltt i.year, cluster(gvkey)
	est sto pooltest3

	reg `dv' `mediator' `iv' dltt at i.year, cluster(gvkey)
	est sto pooltest4

	reg `dv' `mediator' `iv' dltt at emp i.year, cluster(gvkey)
	est sto pooltest5

	reg `dv' `mediator' `iv' dltt at emp age i.year, cluster(gvkey)
	est sto pooltest6

	reg `dv' `mediator' `iv' dltt at emp age xad i.year, cluster(gvkey)
	est sto pooltest7

	reg `dv' `mediator' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto pooltest8

	*	Table
	outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
		pooltest6 pooltest7 pooltest8] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	reg `dv' `mediator' `iv' dltt at emp age xad xrd i.year, cluster(gvkey)
	est sto pooltest9

	***	Table
	outreg2 [pooltest9] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-pooled-mediation-test-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore

}
					


***===========================***
*	FIXED EFFECTS ESTIMATION	*
*	DV: SAME YEAR				*
***===========================***
local iv env_rtg
local mediator net_kld_env

foreach dv in revt_usd revt_usd_ihs `dv' {

	///	DIRECT
	xtreg `dv' `iv', fe cluster(gvkey)
	est sto fedir1
	outreg2 [fedir1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-direct-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)

	xtreg `dv' `iv' i.year, fe cluster(gvkey)
	est sto fedir2

	xtreg `dv' `iv' dltt i.year, fe cluster(gvkey)
	est sto fedir3

	xtreg `dv' `iv' dltt at i.year, fe cluster(gvkey)
	est sto fedir4

	xtreg `dv' `iv' dltt at emp i.year, fe cluster(gvkey)
	est sto fedir5

	xtreg `dv' `iv' dltt at emp age i.year, fe cluster(gvkey)
	est sto fedir6

	xtreg `dv' `iv' dltt at emp age xad i.year, fe cluster(gvkey)
	est sto fedir7

	xtreg `dv' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto fedir8

	***	Table
	outreg2 [fedir2 fedir3 fedir4 fedir5 ///
		fedir6 fedir7 fedir8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-direct-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	xtreg `dv' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto fedir9

	***	Table
	outreg2 [fedir9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-direct-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	xtreg `mediator' `iv', fe cluster(gvkey)
	est sto femed1
	outreg2 [femed1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediator-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)

	xtreg `mediator' `iv' i.year, fe cluster(gvkey)
	est sto femed2

	xtreg `mediator' `iv' dltt i.year, fe cluster(gvkey)
	est sto femed3

	xtreg `mediator' `iv' dltt at i.year, fe cluster(gvkey)
	est sto femed4

	xtreg `mediator' `iv' dltt at emp i.year, fe cluster(gvkey)
	est sto femed5

	xtreg `mediator' `iv' dltt at emp age i.year, fe cluster(gvkey)
	est sto femed6

	xtreg `mediator' `iv' dltt at emp age xad i.year, fe cluster(gvkey)
	est sto femed7

	xtreg `mediator' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto femed8

	***	Table
	outreg2 [femed2 femed3 femed4 femed5 ///
		femed6 femed7 femed8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediator-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	xtreg `mediator' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto femed9

	*	Table
	outreg2 [femed9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediator-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	xtreg `dv' `mediator' `iv', fe cluster(gvkey)
	est sto fetest1
	outreg2 [fetest1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediation-test-same-year", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)

	xtreg `dv' `mediator' `iv' i.year, fe cluster(gvkey)
	est sto fetest2

	xtreg `dv' `mediator' `iv' dltt i.year, fe cluster(gvkey)
	est sto fetest3

	xtreg `dv' `mediator' `iv' dltt at i.year, fe cluster(gvkey)
	est sto fetest4

	xtreg `dv' `mediator' `iv' dltt at emp i.year, fe cluster(gvkey)
	est sto fetest5

	xtreg `dv' `mediator' `iv' dltt at emp age i.year, fe cluster(gvkey)
	est sto fetest6

	xtreg `dv' `mediator' `iv' dltt at emp age xad i.year, fe cluster(gvkey)
	est sto fetest7

	xtreg `dv' `mediator' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto fetest8

	*	Table
	outreg2 [fetest2 fetest3 fetest4 fetest5 ///
		fetest6 fetest7 fetest8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediation-test-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)

	***	Assume missing xrd and xad are 0
	*	CSTAT Global has no xrd or xad data
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estimate
	xtreg `dv' `mediator' `iv' dltt at emp age xad xrd i.year, fe cluster(gvkey)
	est sto fetest9

	***	Table
	outreg2 [fetest9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-mediation-test-same-year", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore

}



























*	BELOW THIS LINE IS COPIED CODE FROM CHAPTER 3 ANALYSIS FILE				
/*


					***=======================***
					*	ESTIMATION				*
					*	POOLED REGRESSION		*
					*	TEMPORAL DYNAMICS		*
					*	DV: NEXT YEAR REVENUE	*
					***=======================***

///	DIRECT
reg f.revt_usd_ihs l.over_rtg, cluster(gvkey)
est sto pooldirlag1
outreg2 [pooldirlag1] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-time-effects", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg f.revt_usd_ihs l.over_rtg i.year, cluster(gvkey)
est sto pooldirlag2

reg f.revt_usd_ihs l.over_rtg l.dltt i.year, cluster(gvkey)
est sto pooldirlag3

reg f.revt_usd_ihs l.over_rtg l.dltt l.at i.year, cluster(gvkey)
est sto pooldirlag4

reg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp i.year, cluster(gvkey)
est sto pooldirlag5

reg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age i.year, cluster(gvkey)
est sto pooldirlag6

reg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, cluster(gvkey)
est sto pooldirlag7

reg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
est sto pooldirlag8

***	Table
outreg2 [pooldirlag2 pooldirlag3 pooldirlag4 pooldirlag5 ///
	pooldirlag6 pooldirlag7 pooldirlag8] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-time-effects", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing l.xrd and l.xad are 0
*	CSTl.at Global has no l.xrd or l.xad dl.ata
preserve

*	l.xad
replace xad=0 if xad==. & in_cstatn==1

*	l.xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estiml.ate
reg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
est sto pooldirlag9

***	Table
outreg2 [pooldirlag9] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-time-effects", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs i.year) ///
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
reg f.revt_usd_ihs net_kld l.over_rtg, cluster(gvkey)
est sto pooltest1
outreg2 [pooltest1] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-time-effects", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg f.revt_usd_ihs net_kld l.over_rtg i.year, cluster(gvkey)
est sto pooltest2

reg f.revt_usd_ihs net_kld l.over_rtg l.dltt i.year, cluster(gvkey)
est sto pooltest3

reg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at i.year, cluster(gvkey)
est sto pooltest4

reg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp i.year, cluster(gvkey)
est sto pooltest5

reg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age i.year, cluster(gvkey)
est sto pooltest6

reg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, ///
	cluster(gvkey)
est sto pooltest7

reg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
	cluster(gvkey)
est sto pooltest8

*	Table
outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
	pooltest6 pooltest7 pooltest8] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-time-effects", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing l.xrd and l.xad are 0
*	CSTl.at Global has no l.xrd or l.xad dl.ata
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estiml.ate
reg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
	cluster(gvkey)
est sto pooltest9

***	Table
outreg2 [pooltest9] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-time-effects", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore







					***=======================***
					*	ESTIMATION				*
					*	POOLED REGRESSION		*
					*	TEMPORAL DYNAMICS		*
					*	DV: NEXT YEAR IHS TRANSFORMED REVENUE	*
					***=======================***
xtset 

///	DIRECT
reg f.revt_usd_ihs l.over_rtg, cluster(gvkey)
est sto pooldirlag1
outreg2 [pooldirlag1] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-time-effects-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg f.revt_usd_ihs l.over_rtg i.year, cluster(gvkey)
est sto pooldirlag2

reg f.revt_usd_ihs l.over_rtg l.dltt i.year, cluster(gvkey)
est sto pooldirlag3

reg f.revt_usd_ihs l.over_rtg l.dltt l.at i.year, cluster(gvkey)
est sto pooldirlag4

reg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp i.year, cluster(gvkey)
est sto pooldirlag5

reg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age i.year, cluster(gvkey)
est sto pooldirlag6

reg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, cluster(gvkey)
est sto pooldirlag7

reg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
est sto pooldirlag8

***	Table
outreg2 [pooldirlag2 pooldirlag3 pooldirlag4 pooldirlag5 ///
	pooldirlag6 pooldirlag7 pooldirlag8] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-time-effects-ihs", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing l.xrd and l.xad are 0
*	CSTl.at Global has no l.xrd or l.xad dl.ata
preserve

*	l.xad
replace xad=0 if xad==. & in_cstatn==1

*	l.xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estiml.ate
reg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, cluster(gvkey)
est sto pooldirlag9

***	Table
outreg2 [pooldirlag9] ///
	using "tables-and-figures\ch3\ch3-pooled-direct-time-effects-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
reg net_kld l.over_rtg, cluster(gvkey)
est sto poolmed1
outreg2 [poolmed1] ///
	using "tables-and-figures\ch3\ch3-pooled-mediator-time-effects-ihs", ///
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
	using "tables-and-figures\ch3\ch3-pooled-mediator-time-effects-ihs", excel word ///
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
	using "tables-and-figures\ch3\ch3-pooled-mediator-time-effects-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore	


///	MEDIATION TEST
reg f.revt_usd_ihs net_kld l.over_rtg, cluster(gvkey)
est sto pooltest1
outreg2 [pooltest1] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-time-effects-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg f.revt_usd_ihs net_kld l.over_rtg i.year, cluster(gvkey)
est sto pooltest2

reg f.revt_usd_ihs net_kld l.over_rtg l.dltt i.year, cluster(gvkey)
est sto pooltest3

reg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at i.year, cluster(gvkey)
est sto pooltest4

reg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp i.year, cluster(gvkey)
est sto pooltest5

reg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age i.year, cluster(gvkey)
est sto pooltest6

reg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, ///
	cluster(gvkey)
est sto pooltest7

reg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
	cluster(gvkey)
est sto pooltest8

*	Table
outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
	pooltest6 pooltest7 pooltest8] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-time-effects-ihs", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing l.xrd and l.xad are 0
*	CSTl.at Global has no l.xrd or l.xad dl.ata
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estiml.ate
reg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
	cluster(gvkey)
est sto pooltest9

***	Table
outreg2 [pooltest9] ///
	using "tables-and-figures\ch3\ch3-pooled-mediation-test-time-effects-ihs", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs i.year) ///
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
xtreg f.revt_usd_ihs l.over_rtg, fe cluster(gvkey)
est sto fedirlag1
outreg2 [fedirlag1] ///
	using "tables-and-figures\ch3\ch3-fe-direct-time-effects", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg f.revt_usd_ihs l.over_rtg i.year, fe cluster(gvkey)
est sto fedirlag2

xtreg f.revt_usd_ihs l.over_rtg l.dltt i.year, fe cluster(gvkey)
est sto fedirlag3

xtreg f.revt_usd_ihs l.over_rtg l.dltt l.at i.year, fe cluster(gvkey)
est sto fedirlag4

xtreg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp i.year, fe cluster(gvkey)
est sto fedirlag5

xtreg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
est sto fedirlag6

xtreg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, fe cluster(gvkey)
est sto fedirlag7

xtreg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
est sto fedirlag8

***	Table
outreg2 [fedirlag2 fedirlag3 fedirlag4 fedirlag5 ///
	fedirlag6 fedirlag7 fedirlag8] ///
	using "tables-and-figures\ch3\ch3-fe-direct-time-effects", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs 2016o.year i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)

***	Assume missing l.xrd and l.xad are 0
*	CSTl.at Global has no l.xrd or l.xad dl.ata
preserve

*	l.xad
replace xad=0 if xad==. & in_cstatn==1

*	l.xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estiml.ate
xtreg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
est sto fedirlag9

***	Table
outreg2 [fedirlag9] ///
	using "tables-and-figures\ch3\ch3-fe-direct-time-effects", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs 2016o.year i.year) ///
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
xtreg f.revt_usd_ihs net_kld l.over_rtg, fe cluster(gvkey)
est sto fetestlag1
outreg2 [fetestlag1] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-time-effects", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg f.revt_usd_ihs net_kld l.over_rtg i.year, fe cluster(gvkey)
est sto fetestlag2

xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt i.year, fe cluster(gvkey)
est sto fetestlag3

xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at i.year, fe cluster(gvkey)
est sto fetestlag4

xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp i.year, fe cluster(gvkey)
est sto fetestlag5

xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
est sto fetestlag6

xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, fe ///
	cluster(gvkey)
est sto fetestlag7

xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe ///
	cluster(gvkey)
est sto fetestlag8

*	Table
outreg2 [fetestlag2 fetestlag3 fetestlag4 fetestlag5 ///
	fetestlag6 fetestlag7 fetestlag8] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-time-effects", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs 2016o.year i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)

***	Assume missing l.xrd and l.xad are 0
*	CSTl.at Global has no l.xrd or l.xad dl.ata
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estiml.ate
xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe ///
	cluster(gvkey)
est sto fetestlag9

***	Table
outreg2 [fetestlag9] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-time-effects", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs 2016o.year i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore






					***=======================***
					*	ESTIMATION				*
					*	FIXED EFFECTS REGRESSION		*
					*	TEMPORAL DYNAMICS		*
					*	DV: NEXT YEAR IHS TRANSFORMED REVENUE	*
					***=======================***
xtset

///	DIRECT
xtreg f.revt_usd_ihs l.over_rtg, fe cluster(gvkey)
est sto fedirlag1
outreg2 [fedirlag1] ///
	using "tables-and-figures\ch3\ch3-fe-direct-time-effects-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg f.revt_usd_ihs l.over_rtg i.year, fe cluster(gvkey)
est sto fedirlag2

xtreg f.revt_usd_ihs l.over_rtg l.dltt i.year, fe cluster(gvkey)
est sto fedirlag3

xtreg f.revt_usd_ihs l.over_rtg l.dltt l.at i.year, fe cluster(gvkey)
est sto fedirlag4

xtreg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp i.year, fe cluster(gvkey)
est sto fedirlag5

xtreg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
est sto fedirlag6

xtreg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, fe cluster(gvkey)
est sto fedirlag7

xtreg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
est sto fedirlag8

***	Table
outreg2 [fedirlag2 fedirlag3 fedirlag4 fedirlag5 ///
	fedirlag6 fedirlag7 fedirlag8] ///
	using "tables-and-figures\ch3\ch3-fe-direct-time-effects-ihs", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs 2016o.year i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)

***	Assume missing l.xrd and l.xad are 0
*	CSTl.at Global has no l.xrd or l.xad dl.ata
preserve

*	l.xad
replace xad=0 if xad==. & in_cstatn==1

*	l.xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estiml.ate
xtreg f.revt_usd_ihs l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
est sto fedirlag9

***	Table
outreg2 [fedirlag9] ///
	using "tables-and-figures\ch3\ch3-fe-direct-time-effects-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs 2016o.year i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
xtreg net_kld l.over_rtg, fe cluster(gvkey)
est sto femedlag1
outreg2 [femedlag1] ///
	using "tables-and-figures\ch3\ch3-fe-mediator-time-effects-ihs", ///
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
	using "tables-and-figures\ch3\ch3-fe-mediator-time-effects-ihs", excel word ///
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
	using "tables-and-figures\ch3\ch3-fe-mediator-time-effects-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore	


///	MEDIATION TEST
xtreg f.revt_usd_ihs net_kld l.over_rtg, fe cluster(gvkey)
est sto fetestlag1
outreg2 [fetestlag1] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-time-effects-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs) ///
	nocons addtext(Firm FEs, Yes, Year FEs, No)

xtreg f.revt_usd_ihs net_kld l.over_rtg i.year, fe cluster(gvkey)
est sto fetestlag2

xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt i.year, fe cluster(gvkey)
est sto fetestlag3

xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at i.year, fe cluster(gvkey)
est sto fetestlag4

xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp i.year, fe cluster(gvkey)
est sto fetestlag5

xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
est sto fetestlag6

xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad i.year, fe ///
	cluster(gvkey)
est sto fetestlag7

xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe ///
	cluster(gvkey)
est sto fetestlag8

*	Table
outreg2 [fetestlag2 fetestlag3 fetestlag4 fetestlag5 ///
	fetestlag6 fetestlag7 fetestlag8] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-time-effects-ihs", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs 2016o.year i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)

***	Assume missing l.xrd and l.xad are 0
*	CSTl.at Global has no l.xrd or l.xad dl.ata
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estiml.ate
xtreg f.revt_usd_ihs net_kld l.over_rtg l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe ///
	cluster(gvkey)
est sto fetestlag9

***	Table
outreg2 [fetestlag9] ///
	using "tables-and-figures\ch3\ch3-fe-mediation-test-time-effects-ihs", ///
	excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(f.revt_usd_ihs 2016o.year i.year) ///
	nocons addtext(Firm FEs, Yes, Year FEs, Yes)
restore






















					***=======================***
					*	NET KLD STRENGTHS ONLY	*
					***=======================***
					
					
					***===================***
					*	ESTIMATION			*
					*	POOLED REGRESSION	*
					*	DV: SAME YEAR		*
					***===================***
///	DIRECT
reg revt_usd over_rtg, cluster(gvkey)
est sto pooldir1
outreg2 [pooldir1] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-direct-same-year", ///
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
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-direct-same-year", excel word ///
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
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-direct-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
reg net_kld_str over_rtg, cluster(gvkey)
est sto poolmed1
outreg2 [poolmed1] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-mediator-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld_str) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg net_kld_str over_rtg i.year, cluster(gvkey)
est sto poolmed2

reg net_kld_str over_rtg dltt i.year, cluster(gvkey)
est sto poolmed3

reg net_kld_str over_rtg dltt at i.year, cluster(gvkey)
est sto poolmed4

reg net_kld_str over_rtg dltt at emp i.year, cluster(gvkey)
est sto poolmed5

reg net_kld_str over_rtg dltt at emp age i.year, cluster(gvkey)
est sto poolmed6

reg net_kld_str over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto poolmed7

reg net_kld_str over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto poolmed8

***	Table
outreg2 [poolmed2 poolmed3 poolmed4 poolmed5 ///
	poolmed6 poolmed7 poolmed8] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-mediator-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld_str i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
reg net_kld_str over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto poolmed9

*	Table
outreg2 [poolmed9] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-mediator-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld_str i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore	


///	MEDIATION TEST
reg revt_usd net_kld_str over_rtg, cluster(gvkey)
est sto pooltest1
outreg2 [pooltest1] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-mediation-test-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg revt_usd net_kld_str over_rtg i.year, cluster(gvkey)
est sto pooltest2

reg revt_usd net_kld_str over_rtg dltt i.year, cluster(gvkey)
est sto pooltest3

reg revt_usd net_kld_str over_rtg dltt at i.year, cluster(gvkey)
est sto pooltest4

reg revt_usd net_kld_str over_rtg dltt at emp i.year, cluster(gvkey)
est sto pooltest5

reg revt_usd net_kld_str over_rtg dltt at emp age i.year, cluster(gvkey)
est sto pooltest6

reg revt_usd net_kld_str over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto pooltest7

reg revt_usd net_kld_str over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooltest8

*	Table
outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
	pooltest6 pooltest7 pooltest8] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-mediation-test-same-year", excel word ///
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
reg revt_usd net_kld_str over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooltest9

***	Table
outreg2 [pooltest9] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-mediation-test-same-year", excel word ///
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
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-direct-same-year-ihs", ///
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
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-direct-same-year-ihs", excel word ///
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
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-direct-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
reg net_kld_str over_rtg, cluster(gvkey)
est sto poolmedihs1
outreg2 [poolmedihs1] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-mediator-same-year-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld_str) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg net_kld_str over_rtg i.year, cluster(gvkey)
est sto poolmedihs2

reg net_kld_str over_rtg dltt i.year, cluster(gvkey)
est sto poolmedihs3

reg net_kld_str over_rtg dltt at i.year, cluster(gvkey)
est sto poolmedihs4

reg net_kld_str over_rtg dltt at emp i.year, cluster(gvkey)
est sto poolmedihs5

reg net_kld_str over_rtg dltt at emp age i.year, cluster(gvkey)
est sto poolmedihs6

reg net_kld_str over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto poolmedihs7

reg net_kld_str over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto poolmedihs8

***	Table
outreg2 [poolmedihs2 poolmedihs3 poolmedihs4 poolmedihs5 ///
	poolmedihs6 poolmedihs7 poolmedihs8] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-mediator-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld_str i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
reg net_kld_str over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto poolmedihs9

*	Table
outreg2 [poolmedihs9] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-mediator-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld_str i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore	


///	MEDIATION TEST
reg revt_usd_ihs net_kld_str over_rtg, cluster(gvkey)
est sto pooltestihs1
outreg2 [pooltestihs1] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-mediation-test-same-year-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg revt_usd_ihs net_kld_str over_rtg i.year, cluster(gvkey)
est sto pooltestihs2

reg revt_usd_ihs net_kld_str over_rtg dltt i.year, cluster(gvkey)
est sto pooltestihs3

reg revt_usd_ihs net_kld_str over_rtg dltt at i.year, cluster(gvkey)
est sto pooltestihs4

reg revt_usd_ihs net_kld_str over_rtg dltt at emp i.year, cluster(gvkey)
est sto pooltestihs5

reg revt_usd_ihs net_kld_str over_rtg dltt at emp age i.year, cluster(gvkey)
est sto pooltestihs6

reg revt_usd_ihs net_kld_str over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto pooltestihs7

reg revt_usd_ihs net_kld_str over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooltestihs8

*	Table
outreg2 [pooltestihs2 pooltestihs3 pooltestihs4 pooltestihs5 ///
	pooltestihs6 pooltestihs7 pooltestihs8] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-mediation-test-same-year-ihs", excel word ///
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
reg revt_usd_ihs net_kld_str over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooltestihs9

***	Table
outreg2 [pooltestihs9] ///
	using "tables-and-figures\ch3\ch3-net-kld-str-pooled-mediation-test-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore




















					***=======================***
					*	NET KLD CONCERNS ONLY	*
					***=======================***


					***===================***
					*	ESTIMATION			*
					*	POOLED REGRESSION	*
					*	DV: SAME YEAR		*
					***===================***
///	DIRECT
reg revt_usd over_rtg, cluster(gvkey)
est sto pooldir1
outreg2 [pooldir1] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-direct-same-year", ///
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
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-direct-same-year", excel word ///
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
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-direct-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
reg net_kld_con over_rtg, cluster(gvkey)
est sto poolmed1
outreg2 [poolmed1] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-mediator-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld_con) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg net_kld_con over_rtg i.year, cluster(gvkey)
est sto poolmed2

reg net_kld_con over_rtg dltt i.year, cluster(gvkey)
est sto poolmed3

reg net_kld_con over_rtg dltt at i.year, cluster(gvkey)
est sto poolmed4

reg net_kld_con over_rtg dltt at emp i.year, cluster(gvkey)
est sto poolmed5

reg net_kld_con over_rtg dltt at emp age i.year, cluster(gvkey)
est sto poolmed6

reg net_kld_con over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto poolmed7

reg net_kld_con over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto poolmed8

***	Table
outreg2 [poolmed2 poolmed3 poolmed4 poolmed5 ///
	poolmed6 poolmed7 poolmed8] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-mediator-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld_con i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
reg net_kld_con over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto poolmed9

*	Table
outreg2 [poolmed9] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-mediator-same-year", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld_con i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore	


///	MEDIATION TEST
reg revt_usd net_kld_con over_rtg, cluster(gvkey)
est sto pooltest1
outreg2 [pooltest1] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-mediation-test-same-year", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg revt_usd net_kld_con over_rtg i.year, cluster(gvkey)
est sto pooltest2

reg revt_usd net_kld_con over_rtg dltt i.year, cluster(gvkey)
est sto pooltest3

reg revt_usd net_kld_con over_rtg dltt at i.year, cluster(gvkey)
est sto pooltest4

reg revt_usd net_kld_con over_rtg dltt at emp i.year, cluster(gvkey)
est sto pooltest5

reg revt_usd net_kld_con over_rtg dltt at emp age i.year, cluster(gvkey)
est sto pooltest6

reg revt_usd net_kld_con over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto pooltest7

reg revt_usd net_kld_con over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooltest8

*	Table
outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
	pooltest6 pooltest7 pooltest8] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-mediation-test-same-year", excel word ///
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
reg revt_usd net_kld_con over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooltest9

***	Table
outreg2 [pooltest9] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-mediation-test-same-year", excel word ///
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
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-direct-same-year-ihs", ///
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
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-direct-same-year-ihs", excel word ///
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
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-direct-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore		
	
	
///	MEDIATOR MODEL
reg net_kld_con over_rtg, cluster(gvkey)
est sto poolmedihs1
outreg2 [poolmedihs1] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-mediator-same-year-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld_con) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg net_kld_con over_rtg i.year, cluster(gvkey)
est sto poolmedihs2

reg net_kld_con over_rtg dltt i.year, cluster(gvkey)
est sto poolmedihs3

reg net_kld_con over_rtg dltt at i.year, cluster(gvkey)
est sto poolmedihs4

reg net_kld_con over_rtg dltt at emp i.year, cluster(gvkey)
est sto poolmedihs5

reg net_kld_con over_rtg dltt at emp age i.year, cluster(gvkey)
est sto poolmedihs6

reg net_kld_con over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto poolmedihs7

reg net_kld_con over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto poolmedihs8

***	Table
outreg2 [poolmedihs2 poolmedihs3 poolmedihs4 poolmedihs5 ///
	poolmedihs6 poolmedihs7 poolmedihs8] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-mediator-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld_con i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)

***	Assume missing xrd and xad are 0
*	CSTAT Global has no xrd or xad data
preserve

*	xad
replace xad=0 if xad==. & in_cstatn==1

*	xrd
replace xrd=0 if xrd==. & in_cstatn==1

*	Estimate
reg net_kld_con over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto poolmedihs9

*	Table
outreg2 [poolmedihs9] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-mediator-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(net_kld_con i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore	


///	MEDIATION TEST
reg revt_usd_ihs net_kld_con over_rtg, cluster(gvkey)
est sto pooltestihs1
outreg2 [pooltestihs1] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-mediation-test-same-year-ihs", ///
	replace excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs) ///
	nocons addtext(Firm FEs, No, Year FEs, No)

reg revt_usd_ihs net_kld_con over_rtg i.year, cluster(gvkey)
est sto pooltestihs2

reg revt_usd_ihs net_kld_con over_rtg dltt i.year, cluster(gvkey)
est sto pooltestihs3

reg revt_usd_ihs net_kld_con over_rtg dltt at i.year, cluster(gvkey)
est sto pooltestihs4

reg revt_usd_ihs net_kld_con over_rtg dltt at emp i.year, cluster(gvkey)
est sto pooltestihs5

reg revt_usd_ihs net_kld_con over_rtg dltt at emp age i.year, cluster(gvkey)
est sto pooltestihs6

reg revt_usd_ihs net_kld_con over_rtg dltt at emp age xad i.year, cluster(gvkey)
est sto pooltestihs7

reg revt_usd_ihs net_kld_con over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooltestihs8

*	Table
outreg2 [pooltestihs2 pooltestihs3 pooltestihs4 pooltestihs5 ///
	pooltestihs6 pooltestihs7 pooltestihs8] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-mediation-test-same-year-ihs", excel word ///
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
reg revt_usd_ihs net_kld_con over_rtg dltt at emp age xad xrd i.year, cluster(gvkey)
est sto pooltestihs9

***	Table
outreg2 [pooltestihs9] ///
	using "tables-and-figures\ch3\ch3-net-kld-con-pooled-mediation-test-same-year-ihs", excel word ///
	stats(coef se pval) dec(4) ///
	alpha(0.001, 0.01, 0.05) nor2 ///
	drop(revt_usd_ihs i.year) ///
	nocons addtext(Firm FEs, No, Year FEs, Yes)
restore







*END
