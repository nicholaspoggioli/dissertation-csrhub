*	Final defense presentation

clear all
set scheme plotplainblind


*	McDonald's CSR
use data/csrhub-all.dta, clear
xtset 
keep if firm=="McDonald's Corporation"
compress
tw line over_rtg ym, xlabel(,angle(45)) ///
	ylabel(40(5)70) ///
	ti("McDonald's Overall CSR Rating, Monthly 12/2008 - 09/2017")

	
*	McDonald's Stakeholder Heterogeneity
tw (line over_rtg ym, sort) (line emp_rtg ym, sort) (line enviro_rtg ym, sort) ///
	(line prod_rtg ym, sort), xlabel(,angle(45)) legend(pos(6) c(2)) ylab(40(5)70)

	
*	McDonald's CSR and Performance
use data/matched-csrhub-cstat-2008-2017, clear
keep if firm=="McDonald's Corporation"

tw (scatter revt_usd over_rtg) (lfit revt_usd over_rtg), yti("Revenue, Millions USD") ///
	xti("CSR Rating") ylab(20000(5000)30000) legend(off) ti("McDonald's, 2008 - 2016")

	
	
*	Average CSR performance
use data/csrhub-all.dta, clear
xtset 

bysort ym: egen over_mean=mean(over_rtg)

tw line over_mean ym, xlabel(,angle(45)) ///
	ylabel(40(5)70) ///
	ti("Average Overall CSR Rating, Monthly 12/2008 - 09/2017") yti("") xti("")
	

use data/matched-csrhub-cstat-2008-2017, clear

tw (scatter revt_usd over_rtg) (lfit revt_usd over_rtg), yti("Revenue, Millions USD") ///
	xti("CSR Rating") legend(off) ti("Revenue of All Firms, Yearly 2008 - 2016")
	
tw (scatter revt_usd_ihs over_rtg) (lfit revt_usd_ihs over_rtg), yti("IHS Revenue") ///
	xti("CSR Rating") legend(off) ti("IHS Revenue of All Firms, 2008 - 2016") ///
	note("IHS: Inverse hyperbolic sine-transformed to control for outliers")


	
	
*	KLD
use data/csrhub-cstat-kld-matched.dta, clear
*	RENAME VARIABLES
rename (sum_emp_con sum_emp_str sum_env_con sum_env_str sum_pro_con sum_pro_str) ///
	(net_kld_emp_con net_kld_emp_str net_kld_env_con net_kld_env_str ///
	net_kld_prod_con net_kld_prod_str)

label var net_kld_prod_str "(KLD) sum product strengths"
label var net_kld_prod_con "(KLD) sum product concerns"
label var net_kld_emp_str "(KLD) sum employee strengths"
label var net_kld_emp_con "(KLD) sum employee concerns"
label var net_kld_env_str "(KLD) sum environment strengths"
label var net_kld_env_con "(KLD) sum environment concerns"


gen net_kld_prod = net_kld_prod_str - net_kld_prod_con
gen net_kld_env = net_kld_env_str - net_kld_env_con
gen net_kld_emp = net_kld_emp_str - net_kld_emp_con

label var net_kld_prod "(KLD) net product score (strengths - concerns)"
label var net_kld_env "(KLD) net environment score (strengths - concerns)"
label var net_kld_emp "(KLD) net employee score (strengths - concerns)"
