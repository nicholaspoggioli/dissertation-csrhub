***	Mediation analysis of subset of firms in all three data sources

use data\subset-stnd_firm-in-all-three-datasets.dta, clear


///	BARON AND KENNEY STYLE MEDIATION ANALYSIS

***	ALL INDUSTRIES
*	Main relationship
xtreg ni net_kld, fe cluster(firm_n)

*	Mediator predicting independent variable
xtreg net_kld over_rtg, fe cluster(firm_n)

*	Mediation analysis
xtreg ni net_kld over_rtg, fe cluster(firm_n)


***	BANKING
keep if industry=="Manufacturing"

sum net_kld
gen net_kld_adj=net_kld+6

fvset base 6 net_kld_adj

*	Main relationship
xtreg ni i.net_kld_adj##i.net_kld_adj, fe cluster(firm_n) base

*	Mediator predicting independent variable
xtreg net_kld over_rtg, fe cluster(firm_n) base

*	Mediation analysis
xtreg ni i.net_kld_adj##i.net_kld_adj over_rtg, fe cluster(firm_n) base
