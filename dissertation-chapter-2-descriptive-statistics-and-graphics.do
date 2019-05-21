///	Treatment group characteristics
*	3 std dev
tabstat revt ni roa emp debt rd ad, by(treated3) stat(mean sd p50 min max N) longstub

set scheme plotplainblind
graph bar (sum) treat3_date, over(year) ///
	ti("Count of treated firms by year")

*	2 std dev
tabstat revt ni roa emp debt rd ad, by(treated2) stat(mean sd p50 min max N) longstub

set scheme plotplainblind
graph bar (sum) treat2_date, over(year) ///
	ti("Count of 2 std dev treated firms by year")	


///	Compare treated to non-treated
tabstat revt revg ni ni_growth at emp xad xrd age tobinq mkt2book roa revpct, ///
	by(treated) stat(mean sd p50 min max N) long
