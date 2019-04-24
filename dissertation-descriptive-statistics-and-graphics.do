***===================================***
*	DESCRIPTIVE STATISTICS AND GRAPHICS	*
***===================================***
///	SET ENVIRONMENT
clear all
set scheme plotplain

///	CHAPTER 1

///	CHAPTER 2

***	Number of rating sources by firm
scatter over_rtg num_sources, m(oh) jitter(.1) mcolor(black%05) ///
	ylab(0(10)100)

***	Distribution of revenue


	




///	CSRHUB


***	Month level

*	Load data
use data/csrhub-all.dta, clear

*	Clean
replace firm=upper(firm)

drop year_csrhub year_all

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

graph matrix over_rtg_mean over_rtg_med over_rtg, m(p) ///
	diagonal("Yearly Mean" "Yearly Median" "Last Month of Year") ///
	title("Relationships between three methods for aggregating CSRHub from month- to year-level")

graph export "graphics\scatterplot-of-csrhub-aggregation-method-correlations.png", as(png) replace

*	Distribution of ratings across years
local rating over_rtg
graph tw kdensity `rating' if year==2008 || ///
	kdensity `rating' if year==2009 || ///
	kdensity `rating' if year==2010 || ///
	kdensity `rating' if year==2011 || ///
	kdensity `rating' if year==2012 || ///
	kdensity `rating' if year==2013 || ///
	kdensity `rating' if year==2014 || ///
	kdensity `rating' if year==2015 || ///
	kdensity `rating' if year==2016, ///
	legend(label(1 "2008") label(2 "2009") label(3 "2010") label(4 "2011") ///
		label(5 "2012") label(6 "2013") label(7 "2014") label(8 "2015") ///
		label(9 "2016"))

local rating enviro_rtg_lym
graph tw kdensity `rating' if year==2008 || ///
	kdensity `rating' if year==2009 || ///
	kdensity `rating' if year==2010 || ///
	kdensity `rating' if year==2011 || ///
	kdensity `rating' if year==2012 || ///
	kdensity `rating' if year==2013 || ///
	kdensity `rating' if year==2014 || ///
	kdensity `rating' if year==2015 || ///
	kdensity `rating' if year==2016, ///
	legend(pos(3) col(1) label(1 "2008") label(2 "2009") label(3 "2010") label(4 "2011") ///
		label(5 "2012") label(6 "2013") label(7 "2014") label(8 "2015") ///
		label(9 "2016"))













*END
