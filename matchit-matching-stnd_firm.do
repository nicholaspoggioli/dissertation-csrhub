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

/*
Fix these matches:


IDCSRHUB	STND_FIRM					IDCSTAT		STND_FIRM
--------	------------------------	--------	----------------------------
			ANTHERA PHARMACEUTICALS					ANTHERA PHARMACEUTCLS
46			1ST FINANCIAL BANCORP		20			1ST FINANCIAL
47			1ST FINANCIAL BANKSHARES	24			1ST FINL BANKSHARES




*/
