/*	
Author: Nicholas Poggioli
Email:	poggi005@umn.edu
Stata version 15.1

OUTLINE
	Introduction
	Chapter 1:	Improved CSR Measurement Using Metaratings and the CSRHub Dataset
	Chapter 2:	Replicating and Extending Barnett & Salomon (2012)
	Chapter 3:	Identifying the Causal Effect of Social Performance on Financial Performance
	Chapter 4:	The Relationship between CSR Reputation and Engaging in Collective Action to Manage Resource Scarcity
*/

					***=======================***
					*		  CHAPTER 1			*
					*	  THE CSRHUB DATASET	*
					***=======================***
					
					
					***=======================***
					*		  CHAPTER 2			*
					*	 REPLICATE B&S (2012)	*
					***=======================***

					
					***=======================***
					*		  CHAPTER 3			*
					*	 INDUSTRY HETEROGENEITY	*
					***=======================***
***	Load data
use data-csrhub\kld-cstat-bs2012.dta, clear

set scheme plotplainblind

***	Industry descriptive statistics
tab sic

gen sic2 = substr(sic,1,2)
tab sic2						/*	Perrault & Quinn 2018 uses 2-digit SIC codes	*/
drop if sic2==""

*	Recreate Table 6 Perrault & Quinn 2018
sort sic2

drop if year<1998

foreach v in cgov com div emp env hum pro {
	by sic2: egen sic2_`v'_str = total(sum_`v'_str)
	by sic2: egen sic2_`v'_con = total(sum_`v'_con)
}

by sic2: gen N=_N
foreach v in cgov com div emp env hum pro {
	by sic2: egen sic2_`v'_str_st = total(sum_`v'_str)
	replace sic2_`v'_str_st = sic2_`v'_str_st / N
	by sic2: egen sic2_`v'_con_st = total(sum_`v'_con)
	replace sic2_`v'_con_st = sic2_`v'_con_st / N
}
drop N

preserve
bysort sic2: gen n=_n
keep if n==1
drop n

keep sic2*
order sic2 *str *con
capt n export excel using "figures\kld-sic2-sum-strengths-concerns.xls", firstrow(variables)
restore

*	Tabstat
tabstat sum_env_str, by(sic2) stat(mean p50 min max N)







					
					***===========================***
					*		  	CHAPTER 4			*
					*	 CSP AND COLLECTIVE ACTION	*
					***===========================***



					***===========================***
					*	 GRAPHICS AND FIGURES		*
					***===========================***
///		KLD data

***	Load data
use data-csrhub\kld-cstat-bs2012.dta, clear

set scheme plotplainblind

***	Distribution
*stripplot net_kld, over(year) height(5) stack center vertical m(oh) mc(black) xlab(, ang(v))

*graph tw scatter net_kld year, jitter(.1) m(oh) mc(black) xlab(1990(1)2016, angle(v))

binscatter net_kld year, ylab(-2(1)2) col(black) discrete
binscatter net_kld year, ylab(-2(1)2) median discrete

*	KLD strengths
binscatter net_kld_str year, ylab(0(1)4) discrete xlab(1990(2)2016)
binscatter net_kld_str year, ylab(0(1)4) line(qfit) discrete xlab(1990(2)2016)
binscatter net_kld_str year, ylab(0(1)4) median discrete

*	KLD concerns
replace net_kld_con = net_kld_con*-1
binscatter net_kld_con year, ylab(-4(1)0) discrete xlab(1990(2)2016)
binscatter net_kld_con year, ylab(-4(1)0) line(qfit) discrete xlab(1990(2)2016)
binscatter net_kld_con year, ylab(-4(1)0) median discrete

*binscatter net_kld year, rd(2011)
*binscatter net_kld year, median rd(2011)

graph box net_kld, over(year, label(angle(vertical))) ti("Net KLD ratings, 1991 - 2015", size(large)) yti("")

graph bar (count) firm_n, over(year, lab(angle(90)))

*	Strengths
scatter net_kld_str year, xlab(, angle(v)) m(oh) ti("Sum KLD Strengths, 1991 - 2015", size(large)) yti("") jitter(1)

gen net_con=net_kld_con*-1
scatter net_con year, xlab(, angle(v)) m(oh) ti("Sum KLD Concerns, 1991 - 2015", size(large)) yti("") jitter(1)

graph box net_kld_con, over(year, label(angle(vertical))) ti("Sum KLD Concerns, 1991 - 2015", size(large)) yti("")



*	Binscatter
replace sum_env_con=sum_env_con*-1

binscatter sum_env_con sum_env_str, reportreg n(8) ylab(-6(2)0) xlab(0(2)6)
binscatter sum_env_con sum_env_str, reportreg n(8) line(qfit) ylab(-6(2)0) xlab(0(2)6)

binscatter sum_env_con sum_env_str, reportreg absorb(firm_n)


///		COMPUSTAT
***	Firm performance distribution

*ROA (net income / assets)
gen roaout=roa
replace roaout=. if roa>100
replace roaout=. if roa<-50

stripplot roaout, over(year) height(5) stack center vertical m(oh) mc(black) xlab(, ang(v))

scatter roaout year, jitter(1) m(oh) mc(black)
binscatter roaout year

scatter ni at
binscatter ni at, n(100)


graph box roaout, over(year, label(angle(vertical)))



*Assets
scatter at year, jitter(1) m(oh) mc(black) xlab(1990(1)2016, angle(v))
binscatter at year

graph box at, over(year, label(angle(vertical)))

*Net income
stripplot ni, over(year) stack center vertical m(oh) mc(black) xlab(, ang(v))

scatter ni year, jitter(1) m(oh) mc(black) ti("Net income, 1991 - 2015", size(large)) yti("") xti("") xlab(1990(1)2016,angle(v))
binscatter ni year

graph box ni, over(year, label(angle(vertical))) ti("Net income, 1991 - 2015") yti("")


///		CSRHUB
***	Load data
use data/csrhub-all.dta, clear

*	Overall rating by year
graph box over_rtg, over(ym, label(angle(vertical))) ti("CSRHub overall rating, 2008 - 2017") yti("")





///		GRAPHICS
***	U-shaped graphic
clear

set obs 2000
gen x = rnormal()
gen y = x^2 + 4

twoway (qfit y x), xti("Social Performance", size(vlarge)) yti("Financial Performance", size(vlarge)) ytick(0(20)20) xtick(-5(10)5) ylab("") xlab("")





























/*	References

Perrault, E., & Quinn, M. A. (2018). What Have Firms Been Doing? Exploring What KLD Data Report About Firms’ Corporate Social Performance in the Period 2000-2010. Business and Society, 57(5), 890–928. https://doi.org/10.1177/0007650316648671






















*/
