***	UNIQUE STND_FIRM IN KLD
use data\kld-all-clean.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
stnd_compname firm, gen(stnd_firm entity_type)

gen firm_kld=firm
label var firm_kld "firm name in kld-all-clean.dta"

compress
save data\kld-all-clean.dta, replace

*	Keep unique stnd_firm
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Save
compress
save data\unique-stnd_firm-kld.dta, replace
keep stnd_firm firm
gen idkld=_n
label var idkld "unique row variable"
compress
save data\unique-stnd_firm-kld-stnd_firm-only.dta, replace
export delimited using data\unique-stnd_firm-kld.csv, replace



***	UNIQUE STND_FIRM IN CSTAT
use data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
stnd_compname conm, gen(stnd_firm entity_type)

gen firm_cstat=conm
label var firm_cstat "firm name in cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta"

gen year=year(datadate)

compress
save data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, replace

*	Keep unique stnd_firm
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Save
compress
save data\unique-stnd_firm-cstat.dta, replace
keep stnd_firm conm
gen idcstat=_n
label var idcstat "unique row identifier"
compress
save data\unique-stnd_firm-cstat-stnd_firm-only.dta, replace
export delimited using data\unique-stnd_firm-cstat.csv, replace


***	UNIQUE STND_FIRM IN CSRHUB
use data/csrhub-all.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
capt n stnd_compname firm, gen(stnd_firm entity_type)

gen firm_csrhub=firm
label var firm_csrhub "firm name in csrhub-all.dta"

compress
save data\csrhub-all.dta, replace

*	Keep unique stnd_firm
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Save
compress
save data\unique-stnd_firm-csrhub.dta, replace
keep stnd_firm firm
gen idcsrhub=_n
label var idcsrhub "unique row identifier"
compress
save data\unique-stnd_firm-csrhub-stnd_firm-only.dta, replace
export delimited using data\unique-stnd_firm-csrhub.csv, replace





***	MATCH

*	KLD to CSTAT
use data\unique-stnd_firm-kld, clear

merge 1:1 stnd_firm using data\unique-stnd_firm-cstat.dta, gen(kld2cstat)
label var kld2cstat "indicator for merge of kld to cstat on stnd_firm"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         8,508
        from master                     6,458  (kld2cstat==1)
        from using                      2,050  (kld2cstat==2)

    matched                             3,222  (kld2cstat==3)
    -----------------------------------------
*/

merge 1:1 stnd_firm using data\unique-stnd_firm-csrhub.dta, gen(kldcstat2csrhub)
label var kldcstat2csrhub "indicator for merge of kldcstat to csrhub on stnd_firm"
/*

    Result                           # of obs.
    -----------------------------------------
    not matched                        14,712
        from master                     4,508  (kldcstat2csrhub==1)
        from using                     10,204  (kldcstat2csrhub==2)

    matched                             7,222  (kldcstat2csrhub==3)
    -----------------------------------------
*/


tab kld2cstat kldcstat2csrhub

/*
                      |    kldcstat2csrhub
            kld2cstat | master on  matched ( |     Total
----------------------+----------------------+----------
      master only (1) |     2,907      3,551 |     6,458 
       using only (2) |     1,254        796 |     2,050 
          matched (3) |       347      2,875 |     3,222 
----------------------+----------------------+----------
                Total |     4,508      7,222 |    11,730 
*/

*	Keep stnd_firm that match across all three datasets
gen keep=(kld2cstat==3 & kldcstat2csrhub==3)

keep if keep==1

keep stnd_firm firm_* kld2cstat kldcstat2csrhub
drop firm_n

codebook stnd_firm
*	2,875 unique stnd_firm names that are matched across all three datasets

gen stnd_firm_ind=1
label var stnd_firm_ind "=1 if stnd_firm matched across kld, cstat, and csrhub"

*	Save
compress
save data\unique-stnd_firm-kld-cstat-csrhub-match.dta, replace




/*	CREATE SUBSAMPLES OF EACH FULL DATASET,
	KEEPING ONLY OBSERVATIONS WITH FIRM NAMES THAT ARE
	MATCHED ACROSS ALL THREE DATASETS
*/

***	KLD
use data\kld-all-clean.dta, clear
merge m:1 stnd_firm using data\unique-stnd_firm-kld-cstat-csrhub-match.dta, ///
	keepusing(stnd_firm_ind)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        24,848
        from master                    24,848  (_merge==1)
        from using                          0  (_merge==2)

    matched                            25,914  (_merge==3)
    -----------------------------------------
*/

keep if stnd_firm_ind==1
drop _merge

tempfile 1
save `1'
	
	
***	CSTAT
use data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear
merge m:1 stnd_firm using data\unique-stnd_firm-kld-cstat-csrhub-match.dta, ///
	keepusing(stnd_firm_ind)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        41,245
        from master                    41,245  (_merge==1)
        from using                          0  (_merge==2)

    matched                            64,225  (_merge==3)
    -----------------------------------------
*/

keep if stnd_firm_ind==1
drop if indfmt=="FS" /*	DROP FINANCIAL SERVICE FIRMS	*/

bysort stnd_firm year: gen N=_N
tab N
/*

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     55,453       99.55       99.55
          2 |        250        0.45      100.00
------------+-----------------------------------
      Total |     55,703      100.00
*/
drop if N>1
drop N

drop _merge

***	Merge KLD and CSTAT on stnd_firm year

merge 1:1 stnd_firm year using `1'
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        29,997
        from master                    29,768  (_merge==1)
        from using                        229  (_merge==2)

    matched                            25,685  (_merge==3)
    -----------------------------------------
*/

keep if _merge==3
*(29,997 observations deleted)
drop _merge

gen month=month(datadate)

tempfile A
save `A'

***	CSRHUB
use data\csrhub-all.dta, clear
merge m:1 stnd_firm using data\unique-stnd_firm-kld-cstat-csrhub-match.dta, ///
	keepusing(stnd_firm_ind)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       739,177
        from master                   739,177  (_merge==1)
        from using                          0  (_merge==2)

    matched                           226,700  (_merge==3)
    -----------------------------------------
*/
keep if _merge==3
drop _merge

bysort stnd_firm year month: gen N=_N											/*	Could do better here	*/
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    737,803       99.81       99.81
          2 |      1,374        0.19      100.00
------------+-----------------------------------
      Total |    739,177      100.00

*/
drop if N>1
drop N

compress

***	Merge all three
merge 1:1 stnd_firm year month using `A'

*	correct firm_n
drop firm_n
encode stnd_firm, gen(firm_n)


/*
----------------------------------------------------------------------------------------------------------------------------------------------------------------
stnd_firm                                                                                                                                          official name
----------------------------------------------------------------------------------------------------------------------------------------------------------------

                  type:  string (str67), but longest is str28

         unique values:  2,875                    missing "":  0/226,700

              examples:  "CHARTER COMMUNICATIONS"
                         "GOGO"
                         "MIDDLEBY"
                         "SCHERING PLOUGH"

               warning:  variable has embedded blanks
*/

*	2,875 unique firms, which matches the number above. IT WORKS!

compress


***	CLEAN DATA
order stnd_firm firm_csrhub firm_kld firm_cstat
order firm_csrhub firm_kld firm_cstat, after(firm)

label data "unique stnd_firm that match across kld, cstat, and csrhub data"

***	SAVE
save data\subset-stnd_firm-in-all-three-datasets.dta, replace











				***=============================***
				***		COMBINE WITH MATCHIT	***
				***=============================***
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
gen row=_n
br idcsrhub stnd_firm idcstat stnd_firm1 row

/*
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16453	VANCEINFO TECHNOLOGIES	4941	VANCEINFO TECHNOLOGIES ADR	11
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6556	GENETIC TECHNOLOGIES	441	APPLIED GENETIC TECHNOLOGIES	14
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
938	AMERICAN EAGLE OUTFITTERS	366	AMERN EAGLE OUTFITTERS	15
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7677	HORIZON BANCORP	2340	HORIZON BANCORP IN	16
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7480	HEWLETT PACKARD CO HP	2298	HEWLETT PACKARD ENT	20
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4885	DIVERSIFIED RESTAURANT HOLDINGS	1550	DIVERSIFIED RESTAURANT HLDGS	21
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
12347	PHYSICIANS REALTY TRUST	3725	PHYSICIANS REALTY TR	22
14795	STERLING BANK	4466	STERLING BANCORP	23
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
699	ALEXANDRIA REAL ESTATE EQUITIES	243	ALEXANDRIA RE EQUITIES	27
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14568	SOUTHERN MISSOURI BANCORP	4360	SOUTHERN MISSOURI BANCP	29
5022	DRESSER RAND	1579	DRESSER RAND GRP	30
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2902	CANADIAN IMPERIAL BANK OF COMMERCE	949	CANADIAN IMPERIAL BANK	37
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
926	AMERICAN CAPITAL AGENCY	321	AMERICAN CAPITAL	38
13678	SANTANDER CONSUMER USA HOLDINGS	4170	SANTANDER CONSUMER USA HLDGS	39
8167	INGERSOLL RAND	2467	INGERSOLL RAND PLC	40
4906	DOCDATA	1554	DOCDATA NV	41
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15851	TRANS WORLD	4760	TRANS WORLD ENTMT	58
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14800	STERLING FINANCIAL CORP OF SPOKANE	4469	STERLING FINANCIAL CORP WA	59
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3830	COCA COLA EUROPEAN PARTNERS PLC	1234	COCA COLA EUROPEAN PARTNERS	60
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
467	AEROVIRONMENT TWC	184	AEROVIRONMENT	64
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
13258	REXFORD IND REALTY	4054	REXFORD INDUS REALTY	68
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
1103	ANHEUSER BUSCH INBEV NV	405	ANHEUSER BUSCH INBEV	69
12186	PEOPLES UNITED FINANCIAL	3676	PEOPLES UNITED FINL	70
2106	BAYTEX ENERGY TRUST	685	BAYTEX ENERGY	71
4392	CTRL PACIFIC FINANCIAL	1421	CTRL PACIFIC FINANCIAL CP	72
13569	SAGA COMMUNICATIONS	4147	SAGA COMMUNICATIONS CL A	73
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
404	ADVANCED ANALOGIC TECHNOLOGIES	153	ADVANCED ANALOGIC TECH	82
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
418	ADVANCED PHOTONIX	159	ADVANCED PHOTONIX INC CL A	85
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
119	4 CORNERS PROPERTY TRUST	71	4 CORNERS PROPERTY TR	88
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14873	SUBURBAN PROPANE PARTNERS	4496	SUBURBAN PROPANE PRTNRS	101
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2863	CALIFORNIA WATER SVC GRP	932	CALIFORNIA WATER SVC GP	104
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11404	NORTHSTAR REALTY FINANANCE	3399	NORTHSTAR REALTY FINANCE CP	174
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
763	ALLIANCE RESOURCE PARTNERS	268	ALLIANCE RESOURCE PTR	177
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4078	CONSOLIDATED WATER CO	1322	CONSOLIDATED WATER	181
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15263	TARO PHARMACEUTICAL IND	4607	TARO PHARMACEUTICL IND	183
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9596	LINDBLAD EXPEDITIONS HOLDINGS	2853	LINDBLAD EXPEDITIONS HLDGS	184
10450	MILLER IND	3135	MILLER IND INC TN	185
2537	BOSTON PRIVATE FINANCIAL HOLDINGS	826	BOSTON PRIVATE FINL HOLDINGS	186
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15159	T ROWE PRICE GRP	3828	PRICE T ROWE GRP	193
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
1198	APPLIED IND TECHNOLOGIES	442	APPLIED IND TECH	200
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15230	TALLGRASS ENERGY	4598	TALLGRASS ENERGY PTR	208
9783	LYONDELLBASELL IND	2905	LYONDELLBASELL IND NV	209
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4932	DOMINOS PIZZA ENT	1560	DOMINOS PIZZA	214
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6721	GLOBAL TECHNOLOGIES	81	6D GLOBAL TECHNOLOGIES	217
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
263	ACCENTURE	112	ACCENTURE PLC	229
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10463	MINDRAY MEDICAL USA	3139	MINDRAY MEDICAL INTL	230
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
12385	PIONEER RAILCORP	3747	PIONEER RAILCORP CL A	231
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14647	SPORTSMANS WAREHOUSE HOLDINGS	4410	SPORTSMANS WAREHOUSE HLDGS	234
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
17117	WRIGHT MEDICAL GRP	5195	WRIGHT MEDICAL GRP NV	236
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6826	GORMAN RUPP IND	2135	GORMAN RUPP	237
4401	CTRL VERMONT PUBLIC	1423	CTRL VERMONT PUB SVC	238
6300	FRESENIUS MEDICAL CARE	1976	FRESENIUS MEDICAL CARE AG & CO	239
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14824	STONEGATE BANK	4479	STONEGATE BANK FL	241
1492	ASTRAZENECA	551	ASTRAZENECA PLC	242
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2540	BOTTOMLINE TECHNOLOGIES DE	829	BOTTOMLINE TECHNOLOGIES	245
13795	SCHMITT IND	4192	SCHMITT IND INC OR	246
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
12045	PARK STERLING BANK	3623	PARK STERLING	253
921	AMERICAN ASSETS	317	AMERICAN ASSETS TRUST	254
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14743	STATE BANCORP	4445	STATE BANCORP NY	256
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8136	INFINITY PROPERTY & CASUALTY	2457	INFINITY PROPERTY & CAS	260
15381	TELE NORTE LESTE PARTICIPACOES SA	4637	TELE NORTE LESTE PARTICIPACO	261
14673	SS & C TECHNOLOGIES HOLDINGS	4420	SS & C TECHNOLOGIES HLDGS	262
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10123	MCCORMICK & SCHMICKS SEAFOOD RESTAURANTS	3015	MCCORMICK & SCHMICKS SEAFOOD	280
15027	SUSSER HOLDING	4541	SUSSER HOLDINGS	281
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6699	GLOBAL BRASS & COPPER HOLDINGS	2096	GLOBAL BRASS & COPPER HLDGS	287
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10249	MEMORIAL RESOURCE DEVELOPMENT	3056	MEMORIAL RESOURCE DEV	296
11583	OCH ZIFF CAPITAL MGT GRP	3471	OCH ZIFF CAPITAL MGT	297
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16858	WEATHERFORD INTL	5096	WEATHERFORD INTL PLC	325
1642	AUTOMATIC DATA PROCESSING INC ADP	586	AUTOMATIC DATA PROCESSING	326
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9870	MAINSOURCE FINANCIAL GRP	2933	MAINSOURCE FINL GRP	334
2971	CAPITOL FEDERAL FINANCIAL	969	CAPITOL FEDERAL FINL	335
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6552	GENESEE & WYOMING	2046	GENESEE & WYOMING INC CL A	343
10950	NATURAL ALTERNATIVES INTL	3270	NATURAL ALTERNATIVES	344
2951	CAPITAL CITY BANK GRP	963	CAPITAL CITY BK GRP	345
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4668	DEL FRISCOS RESTAURANT GRP	1482	DEL FRISCOS RESTURNT GRP	363
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9553	LIBERTY TAX SVC	2830	LIBERTY TAX	365
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7719	HOUSTON AMERICAN ENERGY	2355	HOUSTON AMERN ENERGY	367
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
898	AMC ENTERTAINMENT	306	AMC ENTERTAINMENT HOLDINGS	436
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
13957	SENSATA TECHNOLOGIES HOLDING NV	4241	SENSATA TECHNOLOGIES HLDG NV	449
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11105	NEW RESIDENTIAL INVESTMENT	3335	NEW RESIDENTIAL INV CP	456
2650	BROADRIDGE FINANCIAL SOLUTIONS	864	BROADRIDGE FINANCIAL SOLUTNS	457
4921	DOLLAR TREE STORES	1557	DOLLAR TREE	458
11664	OLD 2ND BANCORP	3484	OLD 2ND BANCORP INC IL	459
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6234	FORUM ENERGY TECHNOLOGIES	1952	FORUM ENERGY TECH	486
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10398	MICRONET ENERTEC TECHNOLOGIES	3113	MICRONET ENERTEC TECH	493
12168	PENNYMAC MORTGAGE INVESTMENT TRUST	3669	PENNYMAC MORTGAGE INVEST TR	494
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15250	TANGER FACTORY OUTLET CTR	4603	TANGER FACTORY OUTLET CTRS	496
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6269	FRANKLIN FINANCIAL SVC	1964	FRANKLIN FINANCIAL CORP VA	502
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
13815	SCIENCE APPLICATIONS INTL	4202	SCIENCE APPLICATIONS INTL CP	503
16475	VASCO DATA SECURITY INTL	4960	VASCO DATA SEC INTL	504
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4637	DBV TECHNOLOGIES SA	1473	DBV TECHNOLOGIES	511
15212	TAKE 2 INTERACTIVE SOFTWARE	4589	TAKE 2 INTERACTIVE SFTWR	512
998	AMERISERV FINANCIAL	363	AMERISERV FINANCIAL INC	513
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14794	STERLING BANCSHARES	4467	STERLING BANCSHARES INC TX	521
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11026	NEPTUNE TECHNOLOGIES & BIORESSOURCES	3303	NEPTUNE TECH & BIORESSOURCES	525
1259	ARCH CAPITAL SVC	471	ARCH CAPITAL GRP	526
796	ALLSCRIPTS HEALTHCARE SOLUTIONS	281	ALLSCRIPTS HEALTHCARE SOLTNS	527
13331	RIT TECHNOLOGY	4071	RIT TECHNOLOGIES	528
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
17130	WUXI PHARMATECH CAYMAN	5199	WUXI PHARMATECH CAYMAN ADR	541
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16823	WASHINGTON TRUST BANCORP	5083	WASHINGTON TR BANCORP	543
15191	TAITRON COMPONENTS	4588	TAITRON COMPONENTS CL A	544
2462	BOARDWALK PIPELINE PARTNERS	809	BOARDWALK PIPELINE PRTNRS	545
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11064	NEUBERGER BERMAN	3317	NEUBERGER BERMAN RE SEC FD	547
10210	MEDTRONIC	3052	MEDTRONIC PLC	548
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8396	INVESTMENT TECHNOLOGY GRP	2564	INVESTMENT TECHNOLOGY GP	559
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
399	ADVANCE AMERICA CASH ADVANCE CTR	151	ADVANCE AMER CASH ADVANCE CT	562
996	AMERIS BANK	361	AMERIS BANCORP	563
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
756	ALLIANCE FINANCIAL	265	ALLIANCE FINANCIAL CORP NY	567
482	AFFILIATED COMPUTER SVC INC ACS	188	AFFILIATED COMPUTER SVC	568
6709	GLOBAL IND	2100	GLOBAL INDEMNITY	569
12482	POPE RESOURCES A DELAWARE	3779	POPE RESOURCES DE	570
948	AMERICAN FINANCIAL REALTY TRUST	332	AMERICAN FINANCIAL REALTY TR	571
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9540	LIBERATOR MEDICAL HOLDINGS	2828	LIBERATOR MEDICAL HLDGS	575
5974	FEDERAL REALTY INVESTMENT TRUST	1868	FEDERAL REALTY INVESTMENT TR	576
8328	INTL BUSINESS MACHINES CORP IBM	2536	INTL BUSINESS MACHINES	577
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11207	NIELSEN HOLDINGS NV	3363	NIELSEN HOLDINGS PLC	579
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3301	CHARLES SCHWAB	4196	SCHWAB CHARLES	583
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16471	VARIAN SEMICONDUCTOR EQUIPMENT ASSC	4958	VARIAN SEMICONDUCTOR EQUIPMT	584
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7100	GUARANTY FEDERAL BANCSHARES	2190	GUARANTY FED BANCSHARES	588
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3040	CARNIVAL CORP & PLC	995	CARNIVAL CORP PLC USA	590
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4375	CTRIPDOTCOM INTL LTD ADS	1418	CTRIPDOTCOM INTL	610
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6321	FRONTIER FINANCIAL	1982	FRONTIER FINANCIAL CORP WA	612
7311	HARRIS & HARRIS GRP	2240	HARRIS	613
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2220	BENEFICIAL MUTUAL BANCORP	711	BENEFICIAL BANCORP	637
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
851	ALTISOURCE PORTFOLIO SOLUTIONS SA	295	ALTISOURCE PORTFOLIO SOLTNS	645
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
5166	EASTERN VIRGINIA BANKSHARES	1625	EASTERN VA BANKSHARES	648
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3005	CARDTRONICS	984	CARDTRONICS PLC	649
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
1184	APOLLO RESIDENTIAL MORTGAGE	432	APOLLO RESIDENTIAL MTG	653
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3232	CENTURY BANCORP	1066	CENTURY BANCORP INC MA	654
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
17092	WORLD ACCEPTANCE	5187	WORLD ACCEPTANCE CORP DE	680
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4814	DIAMOND OFFSHORE DRILLING	1516	DIAMOND OFFSHRE DRILLING	691
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15222	TALECRIS BIOTHERAPEUTICS	4593	TALECRIS BIOTHERAPEUTCS HLDG	692
1962	BANK OF MARIN	654	BANK OF MARIN BANCORP	693
3859	COGENT COMMUNICATIONS GRP	1239	COGENT COMMUNICATIONS HLDGS	694
6884	GREAT SOUTHERN	2157	GREAT SOUTHERN BANCORP	695
10640	MONOTYPE IMAGING	3176	MONOTYPE IMAGING HOLDINGS	696
8713	JOHNSON OUTDOORS	2650	JOHNSON OUTDOORS INC CL A	697
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14239	SILVERCREST ASSET MGT GRP	4296	SILVERCREST ASSET MGT	706
10770	MULTI PACKAGING SOLUTIONS INTL	3211	MULTI PACKAGING SOLUTNS INTL	707
10006	MARTHA STEWART LIVING OMNIMEDIA	2976	MARTHA STEWART LIVING OMNIMD	708
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6254	FOX FACTORY HOLDING	1958	FOX FACTORY HOLDING CP	710
8739	JP MORGAN CHASE & CO	2661	JPMORGAN CHASE & CO	711
14799	STERLING FINANCIAL	4469	STERLING FINANCIAL CORP WA	712
10266	MERCHANTS BANCSHARES	3063	MERCHANTS BANCSHARES INC VT	713
1541	ATLAS ENERGY	569	ATLAS ENERGY GRP	714
14569	SOUTHERN NATL BANCORP OF VIRGINIA	4361	SOUTHERN NATL BANCORP VA	715
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3075	CASELLA WASTE SYS	1008	CASELLA WASTE SYS INC CL A	749
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10355	METTLER TOLEDO	3093	METTLER TOLEDO INTL	764
6545	GENERAL MOTORS CORP GM	2043	GENERAL MOTORS	765
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3293	CHANGYOUDOTCOM LTD ADS	1083	CHANGYOUDOTCOM	769
47	1ST FINANCIAL BANKSHARES	24	1ST FINL BANKSHARES	770
745	ALLERGAN	261	ALLERGAN PLC	771
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
13534	SAATCHI & SAATCHI	4136	SAATCHI & SAATCHI PLC	773
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
984	AMERICAN SUPERCONDUCTOR	352	AMERICAN SUPERCONDUCTOR CP	776
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2447	BLUEROCK RESIDENTIAL GROWTH REIT	804	BLUEROCK RESIDENTIAL GROWTH	787
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
12983	RALLY SOFTWARE DEVELOPMENT	3956	RALLY SOFTWARE DEV	801
16539	VERMILION ENERGY TRUST	4983	VERMILION ENERGY	802
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11883	OTTER TAIL POWER	3568	OTTER TAIL	813
14617	SPECTRUM BRANDS	4398	SPECTRUM BRANDS HOLDINGS	814
13545	SABRA HEALTHCARE REIT	4138	SABRA HEALTH CARE REIT	815
14750	STATE NATL	4447	STATE NATL COS	816
12872	QIHOO 360 TECHNOLOGY CO	3914	QIHOO 360 TECHNOLGY CO ADR	817
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11412	NORTHWESTERN UNIV	3400	NORTHWESTERN	821
3753	CLEVELAND CLINIC	1208	CLEVELAND CLIFFS	822
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
1137	ANTHERA PHARMACEUTICALS	416	ANTHERA PHARMACEUTCLS	834
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11690	OMEGA HEALTHCARE INVESTORS	3496	OMEGA HEALTHCARE INVS	843
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6229	FORTUNE BRANDS HOME & SECURITY	1951	FORTUNE BRANDS HOME & SECUR	847
11350	NORDIC AMERICAN TANKER SHIPPING	3385	NORDIC AMERICAN TANKERS	848
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
12132	PEAPACK GLADSTONE FINANCIAL	3655	PEAPACK GLADSTONE FINL	890
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
1360	ARTESIAN RESOURCES	514	ARTESIAN RESOURCES CL A	899
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2045	BARE ESCENTUALS BEAUTY	667	BARE ESCENTUALS	900
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10952	NATURAL GROCERS BY VITAMIN COTTAGE	3272	NATURAL GROCERS VITAMIN CTGE	924
8236	INTEGRA LIFESCIENCES HOLDINGS	2499	INTEGRA LIFESCIENCES HLDGS	925
664	ALASKA COMMUNICATIONS SYS GRP	230	ALASKA COMMUNICATIONS SYS GP	926
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3987	COMPANIA CERVECERIAS UNIDAS SA	1288	COMPANIA CERVECERIAS UNIDAS	928
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
5489	ENDURANCE INTL GRP HOLDINGS	1719	ENDURANCE INTL GRP HLDGS	930
8081	INDEPENDENT BANK GRP	2449	INDEPENDENT BK GRP	931
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4097	CONTAINER STORE	1327	CONTAINER STORE GRP	951
6987	GRUPO AEROPORTUARIO DEL CENTRO NORTE SAB DE CV	2177	GRUPO AEROPORTUARIO DEL CENT	952
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3074	CASCADIAN THERAPEUTICS INC USA	1007	CASCADIAN THERAPEUTICS	957
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
13863	SEACOAST BANKING CORP OF FLORIDA	4213	SEACOAST BANKING CORP FL	963
5143	EAGLE BANCORP	1615	EAGLE BANCORP INC MD	964
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11928	PACIFIC BIOSCIENCES OF CALIFORNIA	3585	PACIFIC BIOSCIENCES OF CALIF	1022
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6385	FUSION TELECOMMUNICATIONS INTL	1999	FUSION TELECOMMUNICATIONS	1041
13799	SCHNITZER STEEL IND	4193	SCHNITZER STEEL IND CL A	1042
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10105	MB FINANCIAL	3008	MB FINANCIAL INC MD	1051
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7842	HYSTER YALE MATERIALS HANDLING	2386	HYSTER YALE MATERIALS HNDLNG	1061
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2519	BOOZ ALLEN HAMILTON HOLDING	823	BOOZ ALLEN HAMILTON HLDG CP	1066
3045	CAROLINA TRUST BANK	998	CAROLINA TRUST BANCSHARES	1067
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9225	KRATOS DEFENSE & SECURITY SYS	2749	KRATOS DEFENSE & SECURITY	1073
4143	CORE LAB	1342	CORE LAB NV	1074
14560	SOUTHERN 1ST BANCSHARES	4358	SOUTHERN 1ST BANKSHARES	1075
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2795	CABLE & WIRELESS COMMUNICATIONS PLC	900	CABLE & WIRELESS COMM PLC	1079
12706	PROVIDENT ENERGY TRUST	3879	PROVIDENT ENERGY	1080
11675	OLLIES BARGAIN OUTLET HOLDINGS	3491	OLLIES BARGAIN OUTLET HLDGS	1081
16	1ST AMERICAN FINANCIAL	7	1ST AMERICAN FINANCIAL CP	1082
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10774	MULTIMEDIA GAMES	3213	MULTIMEDIA GAMES HOLDING	1084
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16768	W PHARMACEUTICAL SVC	5066	W PHARMACEUTICAL SVSC	1090
4027	COMTECH TELECOMMUNICATIONS	1303	COMTECH TELECOMMUN	1091
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
5962	FBL FINANCIAL GRP	1863	FBL FINANCIAL GRP INC CL A	1097
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3357	CHENIERE ENERGY PARTNERS	1107	CHENIERE ENERGY	1104
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7534	HIMAX TECHNOLOGIES INC ADS	2312	HIMAX TECHNOLOGIES	1106
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15257	TARGA RESOURCES PARTNERS	4605	TARGA RESOURCES	1109
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4268	CRAFT BREWERS ALLIANCE	1381	CRAFT BREW ALLIANCE	1133
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7318	HARTFORD FINANCIAL SVC GRP	2244	HARTFORD FINANCIAL SVC	1139
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
5977	FEDERATED NATL HOLDING	1872	FEDERATED NATL HLDG	1144
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4086	CONSTELLATION ENERGY PARTNERS	1325	CONSTELLATION ENERGY GRP	1165
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9688	LONESTAR RESOURCES	2878	LONESTAR RESOURCES US	1167
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6037	FIDELITY NATL INFORMATION SVC	1893	FIDELITY NATL INFO SVC	1168
1893	BANCO SANTANDER BRAZIL SA	645	BANCO SANTANDER SA	1169
6675	GLACIER BANK	2083	GLACIER BANCORP	1170
941	AMERICAN ELEC TECHNOLOGIES	327	AMERICAN ELEC TECH	1171
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10838	NACCO IND	3228	NACCO IND CL A	1173
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
776	ALLIED HEALTHCARE INTL	273	ALLIED HEALTHCARE PROD	1200
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15512	TETRA TECHNOLOGIES	4674	TETRA TECHNOLOGIES INC DE	1202
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11419	NORWEGIAN CRUISE LINE HOLDINGS	3401	NORWEGIAN CRUISE LINE HLDGS	1205
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14808	STEWART ENT	4471	STEWART ENT CL A	1213
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11665	OLD DOMINION FREIGHT LINE	3485	OLD DOMINION FREIGHT	1215
12376	PINNACLE FOODS GRP	3741	PINNACLE FOODS	1216
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2075	BASILEA PHARMACEUTICA AG	678	BASILEA PHARMACEUTICA	1235
3662	CITIZEN HOLDINGS	1180	CITIZENS HOLDING	1236
2665	BROOKFIELD PROPERTIES	873	BROOKFIELD PROPERTY PRTRS	1237
8695	JOHN B SANFILIPPO & SON	4166	SANFILIPPO JOHN B & SON	1238
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
5423	EMMIS COMMUNICATIONS	1697	EMMIS COMMUNICATIONS CP CL A	1247
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16617	VIPSHOP HOLDINGS	5007	VIPSHOP HOLDINGS LTD ADR	1297
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14526	SONIC AUTOMOTIVE	4348	SONIC AUTOMOTIVE INC CL A	1311
11989	PALOMAR MEDICAL TECHNOLOGIES	3603	PALOMAR MED TECHNOLOGIES	1312
6458	GARDNER DENVER	2016	GARDNER DENVER HOLDINGS	1313
669	ALBANY MOLECULAR RESEARCH	233	ALBANY MOLECULAR RESH	1314
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
1258	ARCELORMITTAL USA	470	ARCELORMITTAL	1318
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
980	AMERICAN SOFTWARE	349	AMERICAN SOFTWARE CL A	1322
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4991	DOVER DOWNS GAMING & ENTERTAINMENT	1572	DOVER DOWNS GAMING & ENTMT	1325
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4614	DAVE & BUSTERS ENTERTAINMENT	1469	DAVE & BUSTERS ENTMT	1335
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
359	ADDVANTAGE TECHNOLOGIES GRP	143	ADDVANTAGE TECHNOLOGIES GP	1342
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4400	CTRL VALLEY COMMUNITY BANCORP	1422	CTRL VALLEY CMNTY BANCORP	1363
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6710	GLOBAL INDEMNITY PLC	2100	GLOBAL INDEMNITY	1373
15231	TALLGRASS ENERGY PARTNERS	4598	TALLGRASS ENERGY PTR	1374
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16242	UNITED CONTINENTAL HOLDINGS	4866	UNITED CONTINENTAL HLDGS	1376
14162	SHUTTERFLYDOTCOM	4273	SHUTTERFLY	1377
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
17329	ZEBRA TECHNOLOGIES	5246	ZEBRA TECHNOLOGIES CP CL A	1378
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
13765	SC JOHNSON & SON	2648	JOHNSON & JOHNSON	1384
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9798	MA COM TECHNOLOGY SOLUTIONS HOLDINGS	2907	M ACOM TECHNOLOGY SOLUTIONS	1387
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8074	INDEPENDENCE CONTRACT DRILLING	2444	INDEPENDENCE CONTRACT DRLLNG	1388
8240	INTEGRATED DEVICE TECHNOLOGY INC IDT	2501	INTEGRATED DEVICE TECH	1389
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
1102	ANHEUSER BUSCH	405	ANHEUSER BUSCH INBEV	1393
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15389	TELECOM ITALIA	4639	TELECOM ITALIA SPA	1394
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
12386	PIPER JAFFRAY	3748	PIPER JAFFRAY COS	1396
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7462	HERITAGE FINANCIAL GRP	2287	HERITAGE FINANCIAL GP	1407
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15608	TICKETMASTER ENTERTAINMENT	4703	TICKETMASTER ENTERTNMNT	1435
13235	RETAIL OPPORTUNITY INVESTMENTS	4041	RETAIL OPPORTUNITY INVTS CP	1436
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2587	BRAVO BRIO RESTAURANT GRP	843	BRAVO BRIO RESTAURANT GP	1440
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9517	LEXMARK INTL	2824	LEXMARK INTL INC CL A	1442
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6532	GENERAL CABLE	2037	GENERAL CABLE CORP DE	1469
1944	BANK OF COMMERCE	651	BANK OF COMMERCE HOLDINGS	1470
16250	UNITED IND CORP	4870	UNITED IND	1471
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11442	NOVATION	3407	NOVATION COS	1477
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
5520	ENERGY FUELS	1196	CLEAN ENERGY FUELS	1479
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9574	LIGAND PHARMACEUTICALS	2840	LIGAND PHARMACEUTICAL	1480
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6196	FOREST LAB	1941	FOREST LAB CL A	1490
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11159	NEXPOINT RESIDENTIAL TRUST	3354	NEXPOINT RESIDENTIAL TR	1493
11484	NU SKIN ENT	3417	NU SKIN ENT CL A	1494
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2398	BLACKHAWK NETWORK HOLDINGS	761	BLACKHAWK NETWORK HLDGS	1504
16331	UNIVERSAL STAINLESS & ALLOY PROD	4900	UNVL STAINLESS & ALLOY PROD	1505
15308	TD AMERITRADE	4616	TD AMERITRADE HOLDING	1506
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
1256	ARCELORMITTAL BRASIL	470	ARCELORMITTAL	1511
12357	PIER 1 IMPORTS	3729	PIER 1 IMPORTS INC DE	1512
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
17177	XM SATELLITE RADIO HOLDINGS	5217	XM SATELLITE RADIO HLDGS	1520
9470	LEGACYTEXAS FINANCIAL GRP	2810	LEGACY TEX FINANCIAL GRP	1521
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14250	SIMMONS 1ST NATL	4298	SIMMONS 1ST NATL CP CL A	1529
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2857	CALIFORNIA 1ST NATL BANCORP	929	CALIF 1ST NATL BANCORP	1533
8399	INVESTORS FINANCIAL SVC	2566	INVESTORS FINANCIAL SVC CP	1534
6267	FRANKLIN FINANCIAL	1964	FRANKLIN FINANCIAL CORP VA	1535
4241	COVENANT TRANSPORT	1370	COVENANT TRANSPORTATION GRP	1536
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2870	CALLON PETROLEUM	939	CALLON PETROLEUM CO DE	1547
1539	ATLAS AIR WORLDWIDE HOLDINGS	568	ATLAS AIR WORLDWIDE HLDG	1548
161	A SCHULMAN	4195	SCHULMAN A	1549
4933	DOMINOS PIZZA GRP	1560	DOMINOS PIZZA	1550
9389	LANDMARK BANCORP	2781	LANDMARK BANCORP INC KS	1551
12067	PARTNER COMMUNICATIONS CO	3630	PARTNER COMMUNICATIONS	1552
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6538	GENERAL FINANCE	2040	GENERAL FINANCE CORP DE	1558
16240	UNITED COMMUNITY BANK	4864	UNITED COMMUNITY BANKS	1559
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
1775	BABCOCK & WILCOX	628	BABCOCK & WILCOX ENT	1562
4927	DOMINION ENERGY PLC	1558	DOMINION ENERGY	1563
5353	ELI LILLY & CO	2844	LILLY ELI & CO	1564
16525	VERIFONE	4976	VERIFONE SYS	1565
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8169	INGLES MARKETS	2468	INGLES MARKETS INC CL A	1571
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8408	INVIVO THERAPEUTICS HOLDINGS	2571	INVIVO THERAPEUTICS HLDGS	1573
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
419	ADVANCED SEMICONDUCTOR ENGR	160	ADVANCED SEMICON ENGR	1579
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8622	JAZZ PHARMACEUTICALS	2636	JAZZ PHARMACEUTICALS PLC	1580
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4039	CONCERT PHARMACEUTICALS	1308	CONCERT PHARMACEUTICLS	1616
14223	SILICON GRAPHICS	4289	SILICON GRAPHICS INTL	1617
16601	VILLAGE SUPER MARKET	5005	VILLAGE SUPER MARKET CL A	1618
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
48	1ST FINANCIAL CORP INDIANA	21	1ST FINANCIAL CORP IN	1624
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15652	TITAN IND	4718	TITAN INTL	1630
8268	INTERCONTINENTALEXCHANGE	2514	INTERCONTINENTAL EXCHANGE	1631
8080	INDEPENDENT BANK CORP MICHIGAN	2448	INDEPENDENT BANK CORP MI	1632
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14814	STMICROELECTRONICS	4475	STMICROELECTRONICS NV	1650
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
977	AMERICAN SAFETY INS HOLDINGS	346	AMERICAN SAFETY INS HLDG	1654
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16597	VILLAGE BANK & TRUST	5004	VILLAGE BANK & TRUST FINL	1668
15899	TRANSPORTADORA DE GAS DEL INTERIOR	4772	TRANSPORTADORA DE GAS SUR	1669
1964	BANK OF MONTREAL QUEBEC	655	BANK OF MONTREAL	1670
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
13205	REPUBLIC AIRWAYS	4027	REPUBLIC AIRWAYS HLDGS	1678
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7684	HORIZON PHARMA	2342	HORIZON PHARMA PLC	1683
8352	INTL TEXTILE GRP	2547	INTL TEXTLE GRP	1684
12871	QIAGEN	3913	QIAGEN NV	1685
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
13010	RAPTOR PHARMACEUTICALS	3964	RAPTOR PHARMACEUTICAL	1726
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15910	TRAVELERS	4776	TRAVELERS COS	1735
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
711	ALGONQUIN POWER & UTILITIES	246	ALGONQUIN POWER & UTIL	1737
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
811	ALPHA & OMEGA SEMICONDUCTOR	287	ALPHA & OMEGA SEMICONDUCTR	1751
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14079	SHENANDOAH TELECOMMUNICATIONS	4262	SHENANDOAH TELECOMMUN	1755
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2666	BROOKFIELD PROPERTY PARTNERS	873	BROOKFIELD PROPERTY PRTRS	1756
8079	INDEPENDENT BANK CORP MASSACHUSETTS	2447	INDEPENDENT BANK CORP MA	1757
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3462	CHINA LODGING GRP LTD ADS	1130	CHINA LODGING GRP LTD ADR	1765
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4245	COVIDIEN	1372	COVIDIEN PLC	1771
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9841	MAGELLAN MIDSTREAM PARTNERS	2922	MAGELLAN MIDSTREAM PRTNRS	1772
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16627	VIRGINIA COMMERCE BANCORP	5012	VIRGINIA COMM BANCORP	1775
9299	KYTHERA BIOPHARMACEUTICALS	2757	KYTHERA BIOPHARMA	1776
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8936	KENNEDY WILSON	2697	KENNEDY WILSON HOLDINGS	1778
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10768	MULTI FINELINE ELECTRONIX	3210	MULTI FINELINE ELECTRON	1786
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
12989	RAMCO GERSHENSON PROPERTIES TRUST	3959	RAMCO GERSHENSON PROPERTIES	1791
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14739	STARWOOD HOTELS & RESORTS WORLDWIDE	4440	STARWOOD HOTELS & RESORTS WRLD	1794
8260	INTERACTIVE INTELLIGENCE	2511	INTERACTIVE INTELLIGENCE GRP	1795
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
791	ALLISON TRANSMISSION HOLDINGS	278	ALLISON TRANSMISSION HLDGS	1803
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7098	GUARANTEE BANCORP	2189	GUARANTY BANCORP	1806
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16698	VODAFONE GRP	5042	VODAFONE GRP PLC	1809
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11213	NIGHTHAWK RADIOLOGY SVC	3364	NIGHTHAWK RADIOLOGY HLDGS	1814
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
213	ABERCROMBIE & FITCH	97	ABERCROMBIE & FITCH CL A	1816
5606	ENVISION HEALTHCARE HOLDINGS	1755	ENVISION HEALTHCARE	1817
16598	VILLAGE BANK & TRUST FINANCIAL	5004	VILLAGE BANK & TRUST FINL	1818
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8360	INTRAWEST RESORTS HOLDINGS	2551	INTRAWEST RESORTS HLDGS	1820
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15000	SUPERIOR IND	4530	SUPERIOR IND INTL	1832
8426	IOWA TELECOM	2576	IOWA TELECOM SVC	1833
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16320	UNIVERSAL AMERICAN FINANCIAL	4884	UNIVERSAL AMERICAN	1840
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3028	CARLISLE	991	CARLISLE COS	1847
44	1ST DEFIANCE FINANCIAL	19	1ST DEFIANCE FINANCIAL CP	1848
7618	HOLLYSYS AUTOMATION TECHNOLOGIES	2321	HOLLYSYS AUTOMATION TECH	1849
12089	PATRIOT TRANSPORTATION HOLDING	3638	PATRIOT TRANSPORTATION HLDG	1850
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10733	MSC IND DIRECT	3202	MSC IND DIRECT CL A	1853
10943	NATL STORAGE AFFILIATES TRUST	3266	NATL STORAGE AFFILIATES	1854
15901	TRANSPORTADORA DE GAS DEL SUR SA	4772	TRANSPORTADORA DE GAS SUR	1855
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
978	AMERICAN SCIENCE & ENGR	347	AMERICAN SCIENCE ENGR	1858
10460	MINAS BUENAVENTURA	3137	MINAS BUENAVENTURA SA	1859
11292	NIVS INTELLIMEDIA TECHNOLOGY GRP	3371	NIVS INTELLIMEDIA TECHNOLOGY	1860
76	1ST NW BANCORP	41	1ST NW BANCRP	1861
133	5TH 3RD BANK	78	5TH 3RD BANCORP	1862
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14779	STEINWAY MUSICAL INSTRUMENTS	4458	STEINWAY MUSICAL INSTRS	1868
5431	EMPIRE STATE REALTY TRUST	1701	EMPIRE STATE REALTY TR	1869
10698	MOTORCAR PARTS OF AMERICA	3194	MOTORCAR PARTS OF AMER	1870
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
5734	ETRADE FINANCIAL	1612	E TRADE FINANCIAL	1871
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11122	NEW YORK TIMES	3342	NEW YORK TIMES CO CL A	1873
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3861	COGNIZANT TECHNOLOGY SOLUTIONS	1243	COGNIZANT TECH SOLUTIONS	1878
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8299	INTERPUBLIC GRP OF	2527	INTERPUBLIC GRP OF COS	1882
3446	CHINA HOUSING & LAND DEVELOPMENT	1127	CHINA HOUSING & LAND DEV	1883
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
12178	PEOPLES BANCORP	3673	PEOPLES BANCORP INC OH	1891
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7542	HINGHAM INSTITUTION FOR SAVINGS	2313	HINGHAM INSTN FOR SAVINGS	1909
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
405	ADVANCED BATTERY TECHNOLOGIES	154	ADVANCED BATTERY TECH	1912
11528	NXP SEMICONDUCTORS	3457	NXP SEMICONDUCTORS NV	1913
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8340	INTL LOTTERY & TOTALIZATOR SYS	2542	INTL LOTTERY & TOTALIZATOR	1916
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
13057	READING INTL	3977	READING INTL INC CL A	1919
676	ALCATEL LUCENT TECHNOLOGIES	2892	LUCENT TECHNOLOGIES	1920
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
12375	PINNACLE FINANCIAL PARTNERS	3740	PINNACLE FINL PARTNERS	1924
16917	WESTERN ALLIANCE BANCORPORATION	5119	WESTERN ALLIANCE BANCORP	1925
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6107	FLAGSTONE REINSURANCE HOLDINGS	1911	FLAGSTONE REINSURANCE HLD SA	1949
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14211	SIGNATURE BANK	4285	SIGNATURE BANK NY	1960
9003	KIMBALL INTL	2713	KIMBALL INTL CL B	1961
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9367	LAMAR ADVERTISING	2776	LAMAR ADVERTISING CO CL A	2045
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8337	INTL GAME TECHNOLOGY	2540	INTL GAME TECHNOLOGY PLC	2047
9830	MACROVISION	3119	MICROVISION	2048
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11343	NORD ANGLIA EDUCATION PLC	3383	NORD ANGLIA EDUCATION	2058
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
13247	REVOLUTION LIGHTING TECHNOLOGIES	4049	REVOLUTION LIGHTING TECHNLGS	2077
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15900	TRANSPORTADORA DE GAS DEL NORTE SA	4772	TRANSPORTADORA DE GAS SUR	2080
4383	CTRL EUROPEAN MEDIA ENT	1420	CTRL EUROPEAN MEDIA	2081
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16999	WILLIAMS	5151	WILLIAMS COS	2084
1028	AMPHASTAR PHARMACEUTICALS	377	AMPHASTAR PHARMACEUTICLS	2085
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16241	UNITED COMMUNITY FINANCIAL	4865	UNITED COMMUNITY FINL	2117
15390	TELECOM ITALIA MEDIA	4639	TELECOM ITALIA SPA	2118
6921	GREENLIGHT CAPITAL	2167	GREENLIGHT CAPITAL RE	2119
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
12937	QUNAR CAYMAN ISLANDS	3941	QUNAR CAYMAN ISLANDS ADR	2121
11642	OIL DRI CORP OF AMERICA	3482	OIL DRI CORP AMERICA	2122
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16925	WESTERN NEW ENGLAND BANCORP	5126	WESTERN NEW ENG BANCORP	2128
12646	PROGENICS PHARMACEUTICALS	3843	PROGENICS PHARMACEUTICAL	2129
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
69	1ST MID ILLINOIS BANCSHARES	36	1ST MID ILL BANCSHARES	2131
3742	CLEAR CHANNEL OUTDOOR HOLDINGS	1198	CLEAR CHANNEL OUTDOOR HLDGS	2132
9840	MAGELLAN HEALTH SVC	2921	MAGELLAN HEALTH	2133
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
231	ABRAXAS PETROLEUM	102	ABRAXAS PETROLEUM CORP NV	2136
8710	JOHNSON CONTROLS	2649	JOHNSON CONTROLS INTL PLC	2137
13382	ROCKWOOD HOLDING	4090	ROCKWOOD HOLDINGS	2138
6880	GREAT LAKES DREDGE & DOCK	2154	GREAT LAKES DREDGE & DOCK CP	2139
4176	CORP OFFICE PROPERTIES TRUST	1358	CORP OFFICE PROPERT	2140
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16083	TYCO INTL	4834	TYCO INTL PLC	2148
2406	BLACKSTONE MORTGAGE TRUST	786	BLACKSTONE MORTGAGE TR	2149
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6678	GLADSTONE INVESTMENT	2086	GLADSTONE INVESTMENT CORP DE	2156
12463	POLO RALPH LAUREN	3957	RALPH LAUREN	2157
13175	RENEWABLE ENERGY	4018	RENEWABLE ENERGY GRP	2158
6645	GIANT INTERACTIVE GRP INC ADS	2075	GIANT INTERACTIVE GRP ADR	2159
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
12560	PRE PAID LEGAL SVC	3820	PREPAID LEGAL SVC	2161
9341	LADENBURG THALMANN FINANCIAL SVC	2768	LADENBURG THALMANN FINL SVC	2162
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3101	CATALYST PHARMACEUTICAL PARTNERS	1020	CATALYST PHARMACEUTICALS	2207
10369	MGIC INVESTMENT	3102	MGIC INVESTMENT CORP WI	2208
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10920	NATL GENERAL HOLDINGS	3257	NATL GENERAL HOLDINGS CP	2213
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16859	WEBDOTCOM	5097	WEBDOTCOM GRP	2218
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14227	SILICONWARE PRECISION IND CO	4292	SILICONWARE PRECISION IND	2220
16326	UNIVERSAL HEALTH REALTY INCOME TRUST	4889	UNIVERSAL HEALTH RLTY INCOME	2221
5853	EXPEDITORS INTL OF WASHINGTON	1832	EXPEDITORS INTL WASH	2222
1535	ATLANTIC CAPITAL BANCSHARES	565	ATLANTIC CAP BANCSHARES	2223
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3311	CHARTER FINANCIAL	1091	CHARTER FINANCIAL CORP MD	2233
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6268	FRANKLIN FINANCIAL NETWORK	1965	FRANKLIN FINL NETWORK	2236
1179	APOLLO COMMERCIAL REAL ESTATE FINANCE	428	APOLLO COMMERCIAL RE FIN	2237
8261	INTERACTIVE SYS WORLDWIDE	2512	INTERACTIVE SYS WORLDWDE	2238
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
1462	ASSET ACCEPTANCE CAPITAL	539	ASSET ACCEPTANCE CAPITL CP	2259
12159	PENNANTPARK FLOATING RATE CAPITAL	3663	PENNANTPARK FLOATING RT CAP	2260
15633	TIME WARNER CABLE	4713	TIME WARNER	2261
2613	BRIGHT HORIZONS FAMILY SOLUTIONS	853	BRIGHT HORIZONS FAMILY SOLTN	2262
9757	LUMBER LIQUIDATORS	2896	LUMBER LIQUIDATORS HLDGS	2263
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10906	NATL BANKSHARES	3247	NATL BANKSHARES INC VA	2268
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
1406	ASHFORD HOSPITALITY PRIME	528	ASHFORD HOSPITALITY PRME	2274
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
5430	EMPIRE STATE REALTY OP	1701	EMPIRE STATE REALTY TR	2276
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7159	GWR GLOBAL WATER RESOURCES	2106	GLOBAL WATER RESOURCES	2277
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
3306	CHARLOTTE RUSSE	1088	CHARLOTTE RUSSE HOLDING	2278
9997	MARSH & MCLENNAN	2973	MARSH & MCLENNAN COS	2279
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14931	SUN BANCORP	4506	SUN BANCORP INC NJ	2281
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14261	SINCLAIR BROADCAST GRP	4304	SINCLAIR BROADCAST GP CL A	2282
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2361	BIOSPECIFICS TECHNOLOGIES	745	BIOSPECIFICS TECHNOLOGIES CP	2286
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14613	SPECTRA ENERGY	4395	SPECTRA ENERGY PARTNERS	2290
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9406	LAREDO PETROLEUM HOLDINGS	2787	LAREDO PETROLEUM	2295
1195	APPLIANCE RECYCLING CTR OF AMERICA	439	APPLIANCE RECYCLING CTR AMER	2296
16234	UNITED BANKSHARES	4862	UNITED BANKSHARES INC WV	2297
34	1ST CITIZENS BANCSHARES	12	1ST CITIZENS BANCSH CL A	2298
1162	APARTMENT INVESTMENT & MGT	421	APARTMENT INVST & MGT	2299
13867	SEAGATE TECHNOLOGY	4216	SEAGATE TECHNOLOGY PLC	2300
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
13878	SEARS HOMETOWN & OUTLET STORES	4221	SEARS HOMETOWN & OUTLET STR	2302
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15523	TEXAS ROADHOUSE HOLDINGS	4682	TEXAS ROADHOUSE	2314
1900	BANCORPSOUTH	647	BANCORPSOUTH BANK	2315
16809	WARNER CHILCOTT	5077	WARNER CHILCOTT PLC	2316
15333	TECHNICAL COMMUNICATIONS	4626	TECHNICAL COMMUNICATIONS CP	2317
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4696	DELTA AIRLINES	1488	DELTA AIR LINES	2319
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15436	TELIGENT AB	4648	TELIGENT	2331
6867	GRAPHIC PACKAGING	2151	GRAPHIC PACKAGING HOLDING	2332
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8263	INTERCEPT PHARMACEUTICALS	2513	INTERCEPT PHARMA	2336
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8193	INNOVATIVE SOLUTIONS & SUPPORT	2479	INNOVATIVE SOLTNS & SUPP	2340
5819	EW SCRIPPS	1819	EW SCRIPPS CL A	2341
4050	CONCURRENT TECHNOLOGIES	1310	CONCUR TECHNOLOGIES	2342
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
8472	ISHARES TRUST	2593	ISHARES GOLD TRUST	2344
12418	PLATINUM UNDERWRITERS HOLDINGS	3759	PLATINUM UNDERWRITERS HLDG	2345
13059	REAL GOODS SOLAR INC CL A	3978	REAL GOODS SOLAR	2346
6852	GRANA Y MONTERO	2145	GRANA Y MONTERO SA	2347
727	ALKERMES	254	ALKERMES PLC	2348
7916	IDAHO INDEPENDENT BANK	2402	IDAHO INDEPENDENT BK COEUR	2349
12807	PUBLIC SVC ENT GRP	3891	PUBLIC SVC ENTRP GRP	2350
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
957	AMERICAN MEDICAL SYS	336	AMERICAN MEDICAL SYSTMS HLDS	2355
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15796	TOWER GRP	4746	TOWER GRP INTL	2357
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9995	MARRONE BIO INNOVATIONS	2972	MARRONE BIO INNOVTIONS	2363
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
9995	MARRONE BIO INNOVATIONS	2972	MARRONE BIO INNOVTIONS	2363
8560	JACKSONVILLE BANCORP	2627	JACKSONVILLE BANCORP INC MD	2364
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14193	SIERRA BANCORP	4279	SIERRA BANCORP CA	2382
1545	ATLAS PIPELINE PARTNERS	571	ATLAS PIPELINE PARTNER	2383
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
4449	CYALUME TECHNOLOGIES HOLDINGS	1442	CYALUME TECHNOLOGIES HLDGS	2390
9018	KING DIGITAL ENTERTAINMENT PLC	2719	KING DIGITAL ENTERTAINMENT	2391
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
13139	REINSURANCE GRP OF AMERICA	4005	REINSURANCE GRP AMER	2424
12230	PERRY ELLIS INTL	1682	ELLIS PERRY INTL	2425
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
1683	AVIANCA HOLDING SA	601	AVIANCA HOLDINGS SA	2431
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
6301	FRESENIUS MEDICAL CARE ARGENTINA	1976	FRESENIUS MEDICAL CARE AG & CO	2444
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
5625	EPICOR SOFTWARE	1762	EPICOR SOFTWARE CORP OLD	2452
4149	CORENERGY INFRASTRUCTURE TRUST	1347	CORENERGY INFRASTRUCTURE TR	2453
954	AMERICAN INTL IND	335	AMERICAN INTL GRP	2454
918	AMERICAN AIRLINES	316	AMERICAN AIRLINES GRP	2455
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
2794	CABLE & WIRELESS	900	CABLE & WIRELESS COMM PLC	2458
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
7306	HARLEYSVILLE NATL	2236	HARLEYSVILLE GRP	2473
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
15386	TELECOM ARGENTINA SA	4638	TELECOM ARGENTINA	2475
916	AMERICA MOVIL SAB DE CV	315	AMERICA MOVIL SA DE CV	2476
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
10929	NATL INTERSTATE INS	3261	NATL INTERSTATE	2479
5860	EXPRESS SCRIPTS	1835	EXPRESS SCRIPTS HOLDING	2480
16637	VIRTUS INVESTMENT PARTNERS	5016	VIRTUS INVESTMENT PTR	2481
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
5573	ENT BANCORP	1744	ENT BANCORP INC MA	2497
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
5939	FARMERS NATL BANC	1857	FARMERS NATL BANC CORP OH	2524
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
17099	WORLD WRESTLING ENTERTAINMENT	5190	WORLD WRESTLING ENTMT	2526
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
16330	UNIVERSAL SECURITY INSTRUMENTS	4893	UNIVERSAL SECURITY INSTRUMNT	2542
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
14292	SINOPEC SHANGHAI PETROCHEMICAL	4306	SINOPEC SHANGHAI PETROCHEM	2544
idcsrhub	stnd_firm	idcstat	stnd_firm1	row
11061	NETWORK EQUIPMENT TECHNOLOGIES	3316	NETWORK EQUIPMENT TECH	2547
16332	UNIVERSAL TECHNICAL INSTITUTE	4894	UNIVERSAL TECHNICAL INST	2548
16878	WEINGARTEN REALTY INVESTORS	5105	WEINGARTEN REALTY INVST	2549

*/


***	Create dataset of nonexact matches
import excel "data\data-matchit\matchit-csrhub-2-cstat-nonexact-matches.xlsx", ///
	sheet("Sheet1") clear firstrow
	
rename (stnd_firm stnd_firm1) (matchitcsrhub matchitcstat)
gen stnd_firm=matchitcstat

bysort stnd_firm: gen N=_N
tab N
/*

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        450       93.56       93.56
          2 |         28        5.82       99.38
          3 |          3        0.62      100.00
------------+-----------------------------------
      Total |        481      100.00
*/
list matchitcstat matchitcsrhub if N>1, sepby(stnd_firm)
/*
 +----------------------------------------------------------------------+
     |                   matchitcstat                         matchitcsrhub |
     |----------------------------------------------------------------------|
 52. |           ANHEUSER BUSCH INBEV                        ANHEUSER BUSCH |
 53. |           ANHEUSER BUSCH INBEV               ANHEUSER BUSCH INBEV NV |
     |----------------------------------------------------------------------|
 61. |                  ARCELORMITTAL                  ARCELORMITTAL BRASIL |
 62. |                  ARCELORMITTAL                     ARCELORMITTAL USA |
     |----------------------------------------------------------------------|
 95. |      BROOKFIELD PROPERTY PRTRS                 BROOKFIELD PROPERTIES |
 96. |      BROOKFIELD PROPERTY PRTRS          BROOKFIELD PROPERTY PARTNERS |
     |----------------------------------------------------------------------|
 97. |      CABLE & WIRELESS COMM PLC   CABLE & WIRELESS COMMUNICATIONS PLC |
 98. |      CABLE & WIRELESS COMM PLC                      CABLE & WIRELESS |
     |----------------------------------------------------------------------|
154. |                  DOMINOS PIZZA                     DOMINOS PIZZA GRP |
155. |                  DOMINOS PIZZA                     DOMINOS PIZZA ENT |
     |----------------------------------------------------------------------|
163. |         EMPIRE STATE REALTY TR             EMPIRE STATE REALTY TRUST |
164. |         EMPIRE STATE REALTY TR                EMPIRE STATE REALTY OP |
     |----------------------------------------------------------------------|
182. |     FRANKLIN FINANCIAL CORP VA                    FRANKLIN FINANCIAL |
183. |     FRANKLIN FINANCIAL CORP VA                FRANKLIN FINANCIAL SVC |
     |----------------------------------------------------------------------|
185. | FRESENIUS MEDICAL CARE AG & CO                FRESENIUS MEDICAL CARE |
186. | FRESENIUS MEDICAL CARE AG & CO      FRESENIUS MEDICAL CARE ARGENTINA |
     |----------------------------------------------------------------------|
198. |               GLOBAL INDEMNITY                  GLOBAL INDEMNITY PLC |
199. |               GLOBAL INDEMNITY                            GLOBAL IND |
     |----------------------------------------------------------------------|
278. |         MARRONE BIO INNOVTIONS               MARRONE BIO INNOVATIONS |
279. |         MARRONE BIO INNOVTIONS               MARRONE BIO INNOVATIONS |
     |----------------------------------------------------------------------|
409. |     STERLING FINANCIAL CORP WA    STERLING FINANCIAL CORP OF SPOKANE |
410. |     STERLING FINANCIAL CORP WA                    STERLING FINANCIAL |
     |----------------------------------------------------------------------|
421. |           TALLGRASS ENERGY PTR                      TALLGRASS ENERGY |
422. |           TALLGRASS ENERGY PTR             TALLGRASS ENERGY PARTNERS |
     |----------------------------------------------------------------------|
430. |             TELECOM ITALIA SPA                  TELECOM ITALIA MEDIA |
431. |             TELECOM ITALIA SPA                        TELECOM ITALIA |
     |----------------------------------------------------------------------|
440. |      TRANSPORTADORA DE GAS SUR      TRANSPORTADORA DE GAS DEL SUR SA |
441. |      TRANSPORTADORA DE GAS SUR    TRANSPORTADORA DE GAS DEL INTERIOR |
442. |      TRANSPORTADORA DE GAS SUR    TRANSPORTADORA DE GAS DEL NORTE SA |
     |----------------------------------------------------------------------|
460. |      VILLAGE BANK & TRUST FINL                  VILLAGE BANK & TRUST |
461. |      VILLAGE BANK & TRUST FINL        VILLAGE BANK & TRUST FINANCIAL |
     +----------------------------------------------------------------------+
*/

drop if N>1
drop N

*	Merge the csrhub stnd_firm into the unique stnd_firm in cstat
merge 1:1 stnd_firm using data\unique-stnd_firm-cstat-stnd_firm-only.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         4,822
        from master                         0  (_merge==1)
        from using                      4,822  (_merge==2)

    matched                               450  (_merge==3)
    -----------------------------------------
*/
drop _merge

compress
save data\unique-stnd_firm-cstat-stnd_firm-only-including-csrhub-fuzzmatch.dta, replace

***	Re-run fuzzy match
use data\unique-stnd_firm-csrhub-stnd_firm-only.dta, clear

capt n ssc install matchit
capt n ssc install freqindex

matchit idcsrhub stnd_firm using data\unique-stnd_firm-cstat-stnd_firm-only-including-csrhub-fuzzmatch.dta, ///
	idu(idcstat) txtu(stnd_firm) similmethod(ngram,3) time threshold(.75)
	
gsort stnd_firm -similscore

by stnd_firm: egen simmax=max(similscore)
by stnd_firm: gen n=_n
drop if simmax==1 & n!=1
drop simmax n

compress
save data\matchit-csrhub-2-cstat-2.dta





















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








































































*END
