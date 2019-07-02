***=====================================================***
*	CHAPTER 3 DATA ANALYSIS
*	FIRM-YEAR LEVEL DATASET COMBINING
*		CSRHUB/CSTAT AND KLD
***=====================================================***

///	LOAD DATA
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

xtreg f.revt_usd over_rtg dltt_usd at_usd emp i.year, fe cluster(gvkey)
xtreg f.net_kld over_rtg dltt_usd at_usd emp i.year, fe cluster(gvkey)
xtreg f.revt_usd net_kld over_rtg dltt_usd at_usd emp i.year, fe cluster(gvkey)





xtreg f.revt_usd over_rtg dltt_usd at_usd emp i.year, fe cluster(gvkey)
xtreg net_kld over_rtg dltt_usd at_usd emp i.year, fe cluster(gvkey)
xtreg f.revt_usd net_kld over_rtg dltt_usd at_usd emp i.year, fe cluster(gvkey)


























*END
