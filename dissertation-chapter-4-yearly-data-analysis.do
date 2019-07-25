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
set scheme plotplainblind

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
sleep 500

///	SKEWNESS OF REVENUE BY INDUSTRY
tabstat revt_usd, by(sic2cat) stat(N mean p50 skew) f(%9.2fc)

tabstat revt_usd_ihs, by(sic2cat) stat(N mean p50 skew) f(%9.2fc)

***	Histogram
histogram revt_usd, bin(100) name(g1, replace) freq nodraw ///
	xti("Untransformed revenue ({c $|}millions USD)")

histogram revt_usd_ihs, bin(100) name(g2, replace) freq nodraw ///
	xti("Inverse hyperbolic sine-transformed revenue") ///
	yti("")

graph combine g1 g2, c(2) r(1) ycommon ///
	ti("Untransformed and transformed revenue distributions")
	


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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-direct", ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-direct", word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-direct", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	reg `mediator' `iv', cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediator", ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediator", word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediator", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	reg `dv' `mediator' `iv', cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediation-test", ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediation-test", word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediation-test", word ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-direct", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)
	sleep 500
	
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-direct", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-direct", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	sleep 500
	restore		
		
		
	///	MEDIATOR MODEL
	xtreg `mediator' `iv', fe cluster(gvkey)
	est sto femed1
	outreg2 [femed1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediator", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediator", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediator", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	sleep 500
	restore	


	///	MEDIATION TEST
	xtreg `dv' `mediator' `iv', fe cluster(gvkey)
	est sto fetest1
	outreg2 [fetest1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediation-test", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediation-test", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediation-test", word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-direct", ///
		replace  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-direct", ///
		 word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-direct",  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	sleep 500
	restore		
		
		
	///	MEDIATOR MODEL
	reg `mediator' l.`iv', cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-mediator", ///
		replace  word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-mediator",  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-mediator",  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	sleep 500
	restore	


	///	MEDIATION TEST
	reg f.`dv' `mediator' l.`iv', cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-mediation-test", ///
		replace  word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-mediation-test", ///
		 word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-mediation-test", ///
		 word ///
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
	xtreg f.`dv' l.`iv', fe cluster(gvkey)
	est sto pooldirlag1
	outreg2 [pooldirlag1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-direct", ///
		replace  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	xtreg f.`dv' l.`iv' i.year, fe cluster(gvkey)
	est sto pooldirlag2

	xtreg f.`dv' l.`iv' l.dltt i.year, fe cluster(gvkey)
	est sto pooldirlag3

	xtreg f.`dv' l.`iv' l.dltt l.at i.year, fe cluster(gvkey)
	est sto pooldirlag4

	xtreg f.`dv' l.`iv' l.dltt l.at l.emp i.year, fe cluster(gvkey)
	est sto pooldirlag5

	xtreg f.`dv' l.`iv' l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
	est sto pooldirlag6

	xtreg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, fe cluster(gvkey)
	est sto pooldirlag7

	xtreg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto pooldirlag8

	***	Table
	outreg2 [pooldirlag2 pooldirlag3 pooldirlag4 pooldirlag5 ///
		pooldirlag6 pooldirlag7 pooldirlag8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-direct", ///
		word ///
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
	xtreg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto pooldirlag9

	***	Table
	outreg2 [pooldirlag9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-direct",  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	xtreg `mediator' l.`iv', fe cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediator", ///
		replace  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	xtreg `mediator' l.`iv' i.year, fe cluster(gvkey)
	est sto poolmed2

	xtreg `mediator' l.`iv' l.dltt i.year, fe cluster(gvkey)
	est sto poolmed3

	xtreg `mediator' l.`iv' l.dltt l.at i.year, fe cluster(gvkey)
	est sto poolmed4

	xtreg `mediator' l.`iv' l.dltt l.at l.emp i.year, fe cluster(gvkey)
	est sto poolmed5

	xtreg `mediator' l.`iv' l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
	est sto poolmed6

	xtreg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, fe cluster(gvkey)
	est sto poolmed7

	xtreg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto poolmed8

	***	Table
	outreg2 [poolmed2 poolmed3 poolmed4 poolmed5 ///
		poolmed6 poolmed7 poolmed8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediator",  word ///
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
	xtreg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto poolmed9

	*	Table
	outreg2 [poolmed9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediator",  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	xtreg f.`dv' `mediator' l.`iv', fe cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediation-test", ///
		replace  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	xtreg f.`dv' `mediator' l.`iv' i.year, fe cluster(gvkey)
	est sto pooltest2

	xtreg f.`dv' `mediator' l.`iv' l.dltt i.year, fe cluster(gvkey)
	est sto pooltest3

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at i.year, fe cluster(gvkey)
	est sto pooltest4

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp i.year, fe cluster(gvkey)
	est sto pooltest5

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
	est sto pooltest6

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, ///
		fe cluster(gvkey)
	est sto pooltest7

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
		fe cluster(gvkey)
	est sto pooltest8

	*	Table
	outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
		pooltest6 pooltest7 pooltest8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediation-test", ///
		 word ///
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
	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
		fe cluster(gvkey)
	est sto pooltest9

	***	Table
	outreg2 [pooltest9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediation-test", ///
		 word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore

}




***=======================***
*	NET KLD STRENGTHS ONLY	*
***=======================***



***=======================***
*	NET KLD CONCERNS ONLY	*
***=======================***




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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-direct", ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-direct", word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-direct", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	reg `mediator' `iv', cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediator", ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediator", word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediator", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	reg `dv' `mediator' `iv', cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediation-test", ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediation-test", word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediation-test", word ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-direct", ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-direct", word ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-direct", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	xtreg `mediator' `iv', fe cluster(gvkey)
	est sto femed1
	outreg2 [femed1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediator", ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediator", word ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediator", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	xtreg `dv' `mediator' `iv', fe cluster(gvkey)
	est sto fetest1
	outreg2 [fetest1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediation-test", ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediation-test", word ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediation-test", word ///
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
local iv emp_rtg
local mediator net_kld_emp

foreach dv in revt_usd revt_usd_ihs {


	///	DIRECT
	reg f.`dv' l.`iv', cluster(gvkey)
	est sto pooldirlag1
	outreg2 [pooldirlag1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-direct", ///
		replace  word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-direct", ///
		 word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-direct",  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	reg `mediator' l.`iv', cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-mediator", ///
		replace  word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-mediator",  word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-mediator",  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	reg f.`dv' `mediator' l.`iv', cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-mediation-test", ///
		replace  word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-mediation-test", ///
		 word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-mediation-test", ///
		 word ///
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

local iv emp_rtg
local mediator net_kld_emp

foreach dv in revt_usd revt_usd_ihs {

	///	DIRECT
	xtreg f.`dv' l.`iv', fe cluster(gvkey)
	est sto pooldirlag1
	outreg2 [pooldirlag1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-direct", ///
		replace  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	xtreg f.`dv' l.`iv' i.year, fe cluster(gvkey)
	est sto pooldirlag2

	xtreg f.`dv' l.`iv' l.dltt i.year, fe cluster(gvkey)
	est sto pooldirlag3

	xtreg f.`dv' l.`iv' l.dltt l.at i.year, fe cluster(gvkey)
	est sto pooldirlag4

	xtreg f.`dv' l.`iv' l.dltt l.at l.emp i.year, fe cluster(gvkey)
	est sto pooldirlag5

	xtreg f.`dv' l.`iv' l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
	est sto pooldirlag6

	xtreg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, fe cluster(gvkey)
	est sto pooldirlag7

	xtreg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto pooldirlag8

	***	Table
	outreg2 [pooldirlag2 pooldirlag3 pooldirlag4 pooldirlag5 ///
		pooldirlag6 pooldirlag7 pooldirlag8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-direct", ///
		 word ///
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
	xtreg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto pooldirlag9

	***	Table
	outreg2 [pooldirlag9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-direct",  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	xtreg `mediator' l.`iv', fe cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediator", ///
		replace  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	xtreg `mediator' l.`iv' i.year, fe cluster(gvkey)
	est sto poolmed2

	xtreg `mediator' l.`iv' l.dltt i.year, fe cluster(gvkey)
	est sto poolmed3

	xtreg `mediator' l.`iv' l.dltt l.at i.year, fe cluster(gvkey)
	est sto poolmed4

	xtreg `mediator' l.`iv' l.dltt l.at l.emp i.year, fe cluster(gvkey)
	est sto poolmed5

	xtreg `mediator' l.`iv' l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
	est sto poolmed6

	xtreg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, fe cluster(gvkey)
	est sto poolmed7

	xtreg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto poolmed8

	***	Table
	outreg2 [poolmed2 poolmed3 poolmed4 poolmed5 ///
		poolmed6 poolmed7 poolmed8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediator",  word ///
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
	xtreg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto poolmed9

	*	Table
	outreg2 [poolmed9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediator",  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	xtreg f.`dv' `mediator' l.`iv', fe cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediation-test", ///
		replace  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)

	xtreg f.`dv' `mediator' l.`iv' i.year, fe cluster(gvkey)
	est sto pooltest2

	xtreg f.`dv' `mediator' l.`iv' l.dltt i.year, fe cluster(gvkey)
	est sto pooltest3

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at i.year, fe cluster(gvkey)
	est sto pooltest4

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp i.year, fe cluster(gvkey)
	est sto pooltest5

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
	est sto pooltest6

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, ///
		fe cluster(gvkey)
	est sto pooltest7

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
		fe cluster(gvkey)
	est sto pooltest8

	*	Table
	outreg2 [pooltest2 pooltest3 pooltest4 pooltest5 ///
		pooltest6 pooltest7 pooltest8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediation-test", ///
		 word ///
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
	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, ///
		fe cluster(gvkey)
	est sto pooltest9

	***	Table
	outreg2 [pooltest9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediation-test", ///
		 word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore

}



***=======================***
*	NET KLD STRENGTHS ONLY	*
***=======================***



***=======================***
*	NET KLD CONCERNS ONLY	*
***=======================***




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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-direct", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-direct", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-direct", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	reg `mediator' `iv', cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediator", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, No, Year FEs, No)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediator", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediator", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	reg `dv' `mediator' `iv', cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediation-test", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, No, Year FEs, No)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediation-test", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	sleep 500

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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-same-year-pooled-mediation-test", word ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-direct", ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-direct", word ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-direct", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	xtreg `mediator' `iv', fe cluster(gvkey)
	est sto femed1
	outreg2 [femed1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediator", ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediator", word ///
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediator", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	xtreg `dv' `mediator' `iv', fe cluster(gvkey)
	est sto fetest1
	outreg2 [fetest1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediation-test", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)
	sleep 500
		
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediation-test", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	sleep 500
		
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
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-same-year-mediation-test", word ///
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
local iv env_rtg
local mediator net_kld_env

foreach dv in revt_usd revt_usd_ihs {


	///	DIRECT
	reg f.`dv' l.`iv', cluster(gvkey)
	est sto pooldirlag1
	outreg2 [pooldirlag1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-direct", ///
		replace  word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-direct", ///
		 word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-direct",  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore		
		
		
	///	MEDIATOR MODEL
	reg `mediator' l.`iv', cluster(gvkey)
	est sto poolmed1
	outreg2 [poolmed1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-mediator", ///
		replace  word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-mediator",  word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-mediator",  word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year) ///
		nocons addtext(Firm FEs, No, Year FEs, Yes)
	restore	


	///	MEDIATION TEST
	reg f.`dv' `mediator' l.`iv', cluster(gvkey)
	est sto pooltest1
	outreg2 [pooltest1] ///
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-mediation-test", ///
		replace  word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-mediation-test", ///
		 word ///
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
		using "tables-and-figures\ch4\ch4-`dv'-`iv'-time-effects-pooled-mediation-test", ///
		 word ///
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

local iv env_rtg
local mediator net_kld_env

foreach dv in revt_usd revt_usd_ihs `dv' {

	///	DIRECT
	xtreg f.`dv' l.`iv', fe cluster(gvkey)
	est sto fedir1
	outreg2 [fedir1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-direct", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)

	xtreg f.`dv' l.`iv' i.year, fe cluster(gvkey)
	est sto fedir2

	xtreg f.`dv' l.`iv' l.dltt i.year, fe cluster(gvkey)
	est sto fedir3

	xtreg f.`dv' l.`iv' l.dltt l.at i.year, fe cluster(gvkey)
	est sto fedir4

	xtreg f.`dv' l.`iv' l.dltt l.at l.emp i.year, fe cluster(gvkey)
	est sto fedir5

	xtreg f.`dv' l.`iv' l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
	est sto fedir6

	xtreg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, fe cluster(gvkey)
	est sto fedir7

	xtreg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto fedir8

	***	Table
	outreg2 [fedir2 fedir3 fedir4 fedir5 ///
		fedir6 fedir7 fedir8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-direct", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)

	***	Assume missing l.xrd and l.xad are 0
	*	CSTl.at Global has no l.xrd or l.xad dl.ata
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estiml.ate
	xtreg f.`dv' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto fedir9

	***	Table
	outreg2 [fedir9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-direct", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore		
		
		
	///	mediator MODEL
	xtreg `mediator' l.`iv', fe cluster(gvkey)
	est sto femed1
	outreg2 [femed1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediator", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)

	xtreg `mediator' l.`iv' i.year, fe cluster(gvkey)
	est sto femed2

	xtreg `mediator' l.`iv' l.dltt i.year, fe cluster(gvkey)
	est sto femed3

	xtreg `mediator' l.`iv' l.dltt l.at i.year, fe cluster(gvkey)
	est sto femed4

	xtreg `mediator' l.`iv' l.dltt l.at l.emp i.year, fe cluster(gvkey)
	est sto femed5

	xtreg `mediator' l.`iv' l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
	est sto femed6

	xtreg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, fe cluster(gvkey)
	est sto femed7

	xtreg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto femed8

	***	Table
	outreg2 [femed2 femed3 femed4 femed5 ///
		femed6 femed7 femed8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediator", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)

	***	Assume missing l.xrd and l.xad are 0
	*	CSTl.at Global has no l.xrd or l.xad dl.ata
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estiml.ate
	xtreg `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto femed9

	*	Table
	outreg2 [femed9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediator", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(`mediator' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore	


	///	mediation TEST
	xtreg f.`dv' `mediator' l.`iv', fe cluster(gvkey)
	est sto fetest1
	outreg2 [fetest1] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediation-test", ///
		replace word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv') ///
		nocons addtext(Firm FEs, Yes, Year FEs, No)

	xtreg f.`dv' `mediator' l.`iv' i.year, fe cluster(gvkey)
	est sto fetest2

	xtreg f.`dv' `mediator' l.`iv' l.dltt i.year, fe cluster(gvkey)
	est sto fetest3

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at i.year, fe cluster(gvkey)
	est sto fetest4

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp i.year, fe cluster(gvkey)
	est sto fetest5

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age i.year, fe cluster(gvkey)
	est sto fetest6

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad i.year, fe cluster(gvkey)
	est sto fetest7

	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto fetest8

	*	Table
	outreg2 [fetest2 fetest3 fetest4 fetest5 ///
		fetest6 fetest7 fetest8] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediation-test", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)

	***	Assume missing l.xrd and l.xad are 0
	*	CSTl.at Global has no l.xrd or l.xad dl.ata
	preserve

	*	xad
	replace xad=0 if xad==. & in_cstatn==1

	*	xrd
	replace xrd=0 if xrd==. & in_cstatn==1

	*	Estiml.ate
	xtreg f.`dv' `mediator' l.`iv' l.dltt l.at l.emp l.age l.xad l.xrd i.year, fe cluster(gvkey)
	est sto fetest9

	***	Table
	outreg2 [fetest9] ///
		using "tables-and-figures\ch4\ch4-fe-`dv'-`iv'-time-effects-mediation-test", word ///
		stats(coef se pval) dec(4) ///
		alpha(0.001, 0.01, 0.05) nor2 ///
		drop(f.`dv' i.year 2016o.year) ///
		nocons addtext(Firm FEs, Yes, Year FEs, Yes)
	restore

}



***=======================***
*	NET KLD STRENGTHS ONLY	*
***=======================***



***=======================***
*	NET KLD CONCERNS ONLY	*
***=======================***





























*END
