***	EXPLORATORY GRAPHICS	*

use data-csrhub/factiva-stakeholder-type-by-year-media-all.dta, clear
							
***	Bar graphs

*	Stacked
graph bar (asis) supplier customer employee enviro, over(year, lab(angle(90))) stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment") order(4 3 2 1)) ///
	ti("Count of results from Factiva search of all media coverage") ///
	note("Search term: 'corporate social responsibility' AND '<stakeholder name>'", size(vsmall)) ///
	scheme(plotplain)

graph bar (asis) supplier customer employee enviro csr, over(year, lab(angle(90))) stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment") lab(5 "csr only") order(5 4 3 2 1)) ///
	ti("Count of results from Factiva search of all media coverage") ///
	note("Search terms:""(all except csr only): 'corporate social responsibility' AND '<stakeholder name>'""(csr only): 'corporate social responsibility' NOT 'environment*' NOT 'employee*' NOT 'customer*' NOT 'supplier*'", size(vsmall)) ///
	scheme(plotplain)

*	Percent
graph bar (asis) supplier customer employee enviro, over(year, lab(angle(90))) percentages stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment") order(4 3 2 1)) ///
	ti("Percent of results from Factiva search of all media coverage") ///
	note("Search term: 'corporate social responsibility' AND '<stakeholder name>'", size(vsmall)) ///
	scheme(plotplain)

graph bar (asis) supplier customer employee enviro csr, over(year, lab(angle(90))) percentages stack ///
	legend(lab(1 "suppliers") lab(2 "customers") lab(3 "employees") lab(4 "environment") lab(5 "csr only") order(5 4 3 2 1)) ///
	ti("Percent of results from Factiva search of all media coverage") ///
	note("Search terms:""(all except csr only): 'corporate social responsibility' AND '<stakeholder name>'""(csr only): 'corporate social responsibility' NOT 'environment*' NOT 'employee*' NOT 'customer*' NOT 'supplier*'", size(vsmall)) ///
	scheme(plotplain)
	
	
*	Environment	
graph bar (asis) env, over(year, lab(angle(90))) blab(total) scale(.7) yti("")
