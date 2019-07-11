***	fuzzy string matching csrhub to cstat
/*
use data\unique-stnd_firm-csrhub-stnd_firm-only.dta, clear

capt n ssc install matchit
capt n ssc install freqindex

matchit idcsrhub stnd_firm using data\unique-stnd_firm-cstat-stnd_firm-only.dta, ///
	idu(idcstat) txtu(stnd_firm) similmethod(ngram,3) time threshold(.75)
	
gsort stnd_firm -similscore

by stnd_firm: egen simmax=max(similscore)
by stnd_firm: gen n=_n
drop if simmax==1 & n!=1
drop simmax n

compress
save data\matchit-csrhub-2-cstat.dta

preserve
keep if similscore==1
compress
save data\matchit-csrhub-2-cstat-exact-matches.dta
restore
*/

***	Assess likely matches:
use data\matchit-csrhub-2-cstat.dta, clear
drop if similscore==1
set seed 61047
bysort stnd_firm: gen rando=rnormal()
by stnd_firm: replace rando=rando[_n-1] if _n!=1

gsort rando stnd_firm -similscore
br idcsrhub stnd_firm idcstat stnd_firm1

/*
idcsrhub	stnd_firm	idcstat	stnd_firm1
16453	VANCEINFO TECHNOLOGIES	4941	VANCEINFO TECHNOLOGIES ADR
idcsrhub	stnd_firm	idcstat	stnd_firm1
14805	STEVEN MADDEN	2918	MADDEN STEVEN
idcsrhub	stnd_firm	idcstat	stnd_firm1
938	AMERICAN EAGLE OUTFITTERS	366	AMERN EAGLE OUTFITTERS
idcsrhub	stnd_firm	idcstat	stnd_firm1
7677	HORIZON BANCORP	2340	HORIZON BANCORP IN
idcsrhub	stnd_firm	idcstat	stnd_firm1
4885	DIVERSIFIED RESTAURANT HOLDINGS	1550	DIVERSIFIED RESTAURANT HLDGS
idcsrhub	stnd_firm	idcstat	stnd_firm1
12347	PHYSICIANS REALTY TRUST	3725	PHYSICIANS REALTY TR
idcsrhub	stnd_firm	idcstat	stnd_firm1
14795	STERLING BANK	4466	STERLING BANCORP
idcsrhub	stnd_firm	idcstat	stnd_firm1
699	ALEXANDRIA REAL ESTATE EQUITIES	243	ALEXANDRIA RE EQUITIES












*/













***	fuzzy string matching csrhub to kld
cd "D:\Dropbox\papers\4 work in progress\dissertation-csrhub\project\data"

use "unique-stnd_firm-csrhub-stnd_firm-only.dta", clear
sample 10
save toy1, replace

use "unique-stnd_firm-kld-stnd_firm-only.dta", clear
sample 10
save toy2, replace

capt n ssc install matchit
capt n ssc install freqindex

use toy1, clear

matchit idcsrhub stnd_firm using toy2.dta, ///
	idu(idkld) txtu(stnd_firm) similmethod(ngram,3) time threshold(.75)
	

	
	
	
	
gsort stnd_firm -similscore

by stnd_firm: egen simmax=max(similscore)
by stnd_firm: gen n=_n
drop if simmax==1 & n!=1
drop simmax n

compress
save data\matchit-csrhub-2-kld.dta

preserve
keep if similscore==1
compress
save data\matchit-csrhub-2-kld-exact-matches.dta
restore

keep if similscore!=1
































*END
