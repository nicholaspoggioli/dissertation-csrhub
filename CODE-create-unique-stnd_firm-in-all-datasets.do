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

***	ABOVE ADDED TO data\data-matchit\matchit-csrhub-2-cstat-nonexact-matches.xlsx



*/


*	Create dataset of nonexact matches
import excel "data\data-matchit\matchit-csrhub-2-cstat-nonexact-matches.xlsx", ///
	sheet("Sheet1") clear firstrow




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
