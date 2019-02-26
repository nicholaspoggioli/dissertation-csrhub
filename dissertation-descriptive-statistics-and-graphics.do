***===================================***
*	DESCRIPTIVE STATISTICS AND GRAPHICS	*
***===================================***
///	SET ENVIRONMENT
clear all
set scheme plotplainblind



///	CSRHUB


***	Month level
use data/csrhub-all.dta, clear

*	Number of firms in each year with any rating
preserve
bysort firm year: gen n=_n
keep if n==1
tab year
restore

*	Number of firms with an overall rating
preserve
drop if over_rtg==.
bysort firm year: gen n=_n
keep if n==1
tab year
restore


***	Year level
use data/csrhub-kld-cstat-year-level-with-treatment-variables.dta, clear

keep if in_csrhub==1

*	Number of firms in each year with any rating
tab year

*	Number of firms in each year with overall rating
tab year if over_rtg!=.

*	Correlations of three aggregation methods
corr over_rtg over_rtg_med over_rtg_mean, means

graph matrix over_rtg_mean over_rtg_med over_rtg, m(p)


















*END
