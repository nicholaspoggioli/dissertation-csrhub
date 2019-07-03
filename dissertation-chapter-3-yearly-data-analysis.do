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

					***===============***
					*	ESTIMATION		*
					*	DV: SAME YEAR	*
					***===============***
///	DESCRIPTIVE STATISTICS
local variables revt_usd over_rtg net_kld

***	Summary statistics
sum `variables'

***	Correlation table
pwcorr `variables', st(.05)


///	POOLED REGRESSION
reg revt_usd over_rtg, cluster(gvkey)
reg net_kld over_rtg, cluster(gvkey)
reg revt_usd net_kld over_rtg, cluster(gvkey)
					
///	FIXED EFFECTS MODELS
xtreg revt_usd over_rtg, fe cluster(gvkey)
xtreg net_kld over_rtg, fe cluster(gvkey)
xtreg revt_usd net_kld over_rtg, fe cluster(gvkey)

xtreg revt_usd over_rtg i.year, fe cluster(gvkey)
xtreg net_kld over_rtg i.year, fe cluster(gvkey)
xtreg revt_usd net_kld over_rtg i.year, fe cluster(gvkey)


					***===============***
					*	ESTIMATION		*
					*	DV: NEXT YEAR	*
					***===============***
///	DESCRIPTIVE STATISTICS
local variables revt_usd over_rtg net_kld

***	Summary statistics
sum `variables'

***	Correlation table
pwcorr `variables', st(.05)

xtreg f.revt_usd over_rtg dltt_usd at_usd emp i.year, fe cluster(gvkey)
xtreg net_kld over_rtg dltt_usd at_usd emp i.year, fe cluster(gvkey)
xtreg f.revt_usd net_kld over_rtg dltt_usd at_usd emp i.year, fe cluster(gvkey)


























*END
