***	fuzzy string matching csrhub to cstat

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

/*
Likely matches:


IDCSRHUB	STND_FIRM					IDCSTAT		STND_FIRM
--------	------------------------	--------	----------------------------
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
34	1ST CITIZENS BANCSHARES	12	1ST CITIZENS BANCSH CL A	.79091158
idcsrhub	stnd_firm	idcstat	stnd_firm1 similscore
44	1ST DEFIANCE FINANCIAL	19	1ST DEFIANCE FINANCIAL CP
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
46	1ST FINANCIAL BANCORP	20	1ST FINANCIAL	.78954203
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
47	1ST FINANCIAL BANKSHARES	24	1ST FINL BANKSHARES	.77563153
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
48	1ST FINANCIAL CORP INDIANA	21	1ST FINANCIAL CORP IN	.88975652
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
69	1ST MID ILLINOIS BANCSHARES	36	1ST MID ILL BANCSHARES	.80498447
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
76	1ST NW BANCORP	41	1ST NW BANCRP	.78334945
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
77	1ST OF LONG ISLAND	31	1ST LONG ISLAND	.83205029
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
87	1ST S BANCORP	44	1ST S BANCORP INC VA	.78173596
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
119	4 CORNERS PROPERTY TRUST	71	4 CORNERS PROPERTY TR	.92932038
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
133	5TH 3RD BANK	78	5TH 3RD BANCORP	.78935222
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
161	A SCHULMAN	4195	SCHULMAN A	.75
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
213	ABERCROMBIE & FITCH	97	ABERCROMBIE & FITCH CL A	.87904907
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
231	ABRAXAS PETROLEUM	102	ABRAXAS PETROLEUM CORP NV	.80757285
263	ACCENTURE	112	ACCENTURE PLC	.79772404
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
359	ADDVANTAGE TECHNOLOGIES GRP	143	ADDVANTAGE TECHNOLOGIES GP	.93897107
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
399	ADVANCE AMERICA CASH ADVANCE CTR	151	ADVANCE AMER CASH ADVANCE CT	.90112711
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
404	ADVANCED ANALOGIC TECHNOLOGIES	153	ADVANCED ANALOGIC TECH	.86962636
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
405	ADVANCED BATTERY TECHNOLOGIES	154	ADVANCED BATTERY TECH	.83887049
418	ADVANCED PHOTONIX	159	ADVANCED PHOTONIX INC CL A	.79056942
419	ADVANCED SEMICONDUCTOR ENGR	160	ADVANCED SEMICON ENGR	.7800135
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
467	AEROVIRONMENT TWC	184	AEROVIRONMENT	.85634884
482	AFFILIATED COMPUTER SVC INC ACS	188	AFFILIATED COMPUTER SVC	.85096294
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
664	ALASKA COMMUNICATIONS SYS GRP	230	ALASKA COMMUNICATIONS SYS GP	.9435642
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
669	ALBANY MOLECULAR RESEARCH	233	ALBANY MOLECULAR RESH	.86105677
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
676	ALCATEL LUCENT TECHNOLOGIES	2892	LUCENT TECHNOLOGIES	.82462113
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
699	ALEXANDRIA REAL ESTATE EQUITIES	243	ALEXANDRIA RE EQUITIES	.78893206
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
711	ALGONQUIN POWER & UTILITIES	246	ALGONQUIN POWER & UTIL	.89442719
727	ALKERMES	254	ALKERMES PLC	.77459667
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
745	ALLERGAN	261	ALLERGAN PLC	.77459667
756	ALLIANCE FINANCIAL	265	ALLIANCE FINANCIAL CORP NY	.83205029
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
763	ALLIANCE RESOURCE PARTNERS	268	ALLIANCE RESOURCE PTR	.81312494
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
791	ALLISON TRANSMISSION HOLDINGS	278	ALLISON TRANSMISSION HLDGS	.80119274
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
796	ALLSCRIPTS HEALTHCARE SOLUTIONS	281	ALLSCRIPTS HEALTHCARE SOLTNS	.8376106
811	ALPHA & OMEGA SEMICONDUCTOR	287	ALPHA & OMEGA SEMICONDUCTR	.93897107
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
851	ALTISOURCE PORTFOLIO SOLUTIONS SA	295	ALTISOURCE PORTFOLIO SOLTNS	.79026333
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
898	AMC ENTERTAINMENT	306	AMC ENTERTAINMENT HOLDINGS	.80860754
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
916	AMERICA MOVIL SAB DE CV	315	AMERICA MOVIL SA DE CV	.87831007
918	AMERICAN AIRLINES	316	AMERICAN AIRLINES GRP	.88852332
921	AMERICAN ASSETS	317	AMERICAN ASSETS TRUST	.82717019
926	AMERICAN CAPITAL AGENCY	321	AMERICAN CAPITAL	.81649658
938	AMERICAN EAGLE OUTFITTERS	366	AMERN EAGLE OUTFITTERS	.83925433
941	AMERICAN ELEC TECHNOLOGIES	327	AMERICAN ELEC TECH	.81649658
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
948	AMERICAN FINANCIAL REALTY TRUST	332	AMERICAN FINANCIAL REALTY TR	.94686415
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
957	AMERICAN MEDICAL SYS	336	AMERICAN MEDICAL SYSTMS HLDS	.84515425
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
977	AMERICAN SAFETY INS HOLDINGS	346	AMERICAN SAFETY INS HLDG	.79442991
978	AMERICAN SCIENCE & ENGR	347	AMERICAN SCIENCE ENGR	.90112711
980	AMERICAN SOFTWARE	349	AMERICAN SOFTWARE CL A	.8660254
984	AMERICAN SUPERCONDUCTOR	352	AMERICAN SUPERCONDUCTOR CP	.93541435
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
996	AMERIS BANK	361	AMERIS BANCORP	.76980036
998	AMERISERV FINANCIAL	363	AMERISERV FINANCIAL INC	.89973541
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1028	AMPHASTAR PHARMACEUTICALS	377	AMPHASTAR PHARMACEUTICLS	.89814624
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1137	ANTHERA PHARMACEUTICALS	416	ANTHERA PHARMACEUTCLS	.80100188
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1162	APARTMENT INVESTMENT & MGT	421	APARTMENT INVST & MGT	.81110711
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1179	APOLLO COMMERCIAL REAL ESTATE FINANCE	428	APOLLO COMMERCIAL RE FIN	.7710996
1184	APOLLO RESIDENTIAL MORTGAGE	432	APOLLO RESIDENTIAL MTG	.80498447
1195	APPLIANCE RECYCLING CTR OF AMERICA	439	APPLIANCE RECYCLING CTR AMER	.86671906
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1198	APPLIED IND TECHNOLOGIES	442	APPLIED IND TECH	.79772404
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1360	ARTESIAN RESOURCES	514	ARTESIAN RESOURCES CL A	.87287156
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1406	ASHFORD HOSPITALITY PRIME	528	ASHFORD HOSPITALITY PRME	.88910845
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1462	ASSET ACCEPTANCE CAPITAL	539	ASSET ACCEPTANCE CAPITL CP	.87038828
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1492	ASTRAZENECA	551	ASTRAZENECA PLC	.83205029
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1535	ATLANTIC CAPITAL BANCSHARES	565	ATLANTIC CAP BANCSHARES	.82922798
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1539	ATLAS AIR WORLDWIDE HOLDINGS	568	ATLAS AIR WORLDWIDE HLDG	.79442991
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1541	ATLAS ENERGY	569	ATLAS ENERGY GRP	.84515425
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1545	ATLAS PIPELINE PARTNERS	571	ATLAS PIPELINE PARTNER	.97590007
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1642	AUTOMATIC DATA PROCESSING INC ADP	586	AUTOMATIC DATA PROCESSING	.86135677
idcsrhub	stnd_firm	idcstat	stnd_firm1	similscore
1683	AVIANCA HOLDING SA	601	AVIANCA HOLDINGS SA	.84887469




*/













***	fuzzy string matching csrhub to kld
use data\unique-stnd_firm-csrhub-stnd_firm-only.dta, clear

capt n ssc install matchit
capt n ssc install freqindex

matchit idcsrhub stnd_firm using data\unique-stnd_firm-kld-stnd_firm-only.dta, ///
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
