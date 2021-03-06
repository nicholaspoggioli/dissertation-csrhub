/***	UNIQUE STND_FIRM IN KLD
/*use data\kld-all-clean.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
stnd_compname firm, gen(stnd_firm entity_type)

gen firm_kld=firm
label var firm_kld "firm name in kld-all-clean.dta"

compress
save data\kld-all-clean.dta, replace
*/

*	Keep unique stnd_firm
use data\kld-all-clean.dta, clear
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Fix observations to prevent duplicate matches later
replace stnd_firm="SPIRE CORP" if stnd_firm=="SPIRE"

*	Save
compress
save data\unique-stnd_firm-kld.dta, replace
keep stnd_firm firm_kld
sort stnd_firm
gen idkld=_n
label var idkld "unique row id for unique stnd_firm in kld data"
compress
save data\unique-stnd_firm-kld-stnd_firm-only.dta, replace
export delimited using data\unique-stnd_firm-kld.csv, replace



***	UNIQUE STND_FIRM IN CSTAT
/*use data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear

*Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
stnd_compname conm, gen(stnd_firm entity_type)

gen firm_cstat=conm
label var firm_cstat "firm name in cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta"

gen year=year(datadate)

compress
save data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, replace
*/

*	Keep unique stnd_firm
use data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Fix observations to prevent duplicate matches later
replace stnd_firm="SPIRE CORP" if stnd_firm=="SPIRE"
replace stnd_firm="STERLING BANCORP INC" if stnd_firm=="STERLING BANCORP" & cik=="0001680379"

*	Save
compress
save data\unique-stnd_firm-cstat.dta, replace
keep stnd_firm firm_cstat
sort stnd_firm
gen idcstat=_n
label var idcstat "unique row id for unique stnd_firm in cstat"
compress
save data\unique-stnd_firm-cstat-stnd_firm-only.dta, replace
export delimited using data\unique-stnd_firm-cstat.csv, replace


***	UNIQUE STND_FIRM IN CSRHUB
/*use data/csrhub-all.dta, clear

*	Create stnd_firm standardized firm name using stnd_compname user package
*search stnd_compname
capt n stnd_compname firm, gen(stnd_firm entity_type)

gen firm_csrhub=firm
label var firm_csrhub "firm name in csrhub-all.dta"

compress
save data\csrhub-all.dta, replace
*/

*	Keep unique stnd_firm
use data\csrhub-all.dta, clear
bysort stnd_firm: gen n=_n
keep if n==1
drop n

*	Fix observations to prevent duplicate matches later
replace stnd_firm="SPIRE INC" if stnd_firm=="SPIRE"

*	Save
compress
save data\unique-stnd_firm-csrhub.dta, replace
keep stnd_firm firm_csrhub
sort stnd_firm
gen idcsrhub=_n
label var idcsrhub "unique row id for unique stnd_firm in csrhub data"
compress
save data\unique-stnd_firm-csrhub-stnd_firm-only.dta, replace
export delimited using data\unique-stnd_firm-csrhub.csv, replace


***	MATCH KLD AND CSTAT TO CSRHUB ON UNIQUE STND_FIRM
use data\unique-stnd_firm-csrhub-stnd_firm-only.dta, clear

merge 1:1 stnd_firm using data\unique-stnd_firm-kld-stnd_firm-only.dta, gen(hub2kld)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        14,256
        from master                    11,001  (hub2kld==1)
        from using                      3,255  (hub2kld==2)

    matched                             6,425  (hub2kld==3)
    -----------------------------------------
*/

merge 1:1 stnd_firm using data\unique-stnd_firm-cstat-stnd_firm-only.dta, gen(hubkld2cstat)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        17,917
        from master                    16,663  (hubkld2cstat==1)
        from using                      1,254  (hubkld2cstat==2)

    matched                             4,018  (hubkld2cstat==3)
    -----------------------------------------
*/
tab hub2kld hubkld2cstat
/*
                      |     hubkld2cstat
              hub2kld | master on  matched ( |     Total
----------------------+----------------------+----------
      master only (1) |    10,205        796 |    11,001 
       using only (2) |     2,907        348 |     3,255 
          matched (3) |     3,551      2,874 |     6,425 
----------------------+----------------------+----------
                Total |    16,663      4,018 |    20,681 

*/

keep stnd_firm firm_csrhub firm_kld firm_cstat id*
order id*, last
format %30s stnd_firm firm_*

mark match_all
markout match_all idcsrhub idkld idcstat
label var match_all "=1 if stnd_firm matched across csrhub kld & cstat"

mark match_hubkld
markout match_hubkld idcsrhub idkld
label var match_hubkld "=1 if stnd_firm matched across csrhub & kld"

mark match_hubcstat
markout match_hubcstat idcsrhub idcstat
label var match_hubcstat "=1 if stnd_firm matched across csrhub & cstat"

mark match_kldcstat
markout match_kldcstat idkld idcstat
label var match_kldcstat "=1 if stnd_firm matched across kld & cstat"

*Save
save data\crosswalk-csrhub-kld-cstat-stnd_firm.dta, replace

*/











***	MERGE STND_NAME CROSSWALK INTO EACH MASTER DATASET
*	KLD
use data\kld-all-clean.dta, clear
merge m:1 stnd_firm using data\crosswalk-csrhub-kld-cstat-stnd_firm.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        12,257
        from master                         1  (_merge==1)
        from using                     12,256  (_merge==2)

    matched                            50,761  (_merge==3)
    -----------------------------------------
*/
keep if _merge==3
drop _merge firm_n
order stnd_firm firm_*
format %30s stnd_firm firm_* firm
sort stnd_firm year
compress

bysort stnd_firm year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     50,752       99.98       99.98
          2 |          6        0.01       99.99
          3 |          3        0.01      100.00
------------+-----------------------------------
      Total |     50,761      100.00
*/

*	Fix observations to prevent duplicate matches later
sort stnd_firm ticker year
replace stnd_firm="1ST BANCORP INC" if stnd_firm=="1ST BANCORP" & ticker=="FBNC"
replace stnd_firm="THE 1ST BANCORP INC" if stnd_firm=="1ST BANCORP" & ticker=="FNLC"
replace stnd_firm="FNB CORP" if stnd_firm=="FNB" & ticker=="FNBN"
replace stnd_firm="UNITED SECURITY BANCSHARES INC" if stnd_firm=="UNITED SECURITY BANCSHARES" & ticker=="USBI"

drop N
bysort stnd_firm year: gen N=_N
tab N
/*

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     50,761      100.00      100.00
------------+-----------------------------------
      Total |     50,761      100.00
*/
drop N

gen in_kld=1
label var in_kld "=1 if in kld data"

compress
save data\kld-all-clean-with-stnd_firm-crosswalk.dta, replace



*	CSTAT
use data\cstat-annual-csrhub-tickers-barnett-salomon-2012-variables.dta, clear
replace stnd_firm="STERLING BANCORP INC" if stnd_firm=="STERLING BANCORP" & cik=="0001680379"
replace stnd_firm="UNION BANKSHARES INC" if stnd_firm=="UNION BANKSHARES" & gvkey=="111537"

merge m:1 stnd_firm using data\crosswalk-csrhub-kld-cstat-stnd_firm.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        16,752
        from master                        88  (_merge==1)
        from using                     16,664  (_merge==2)

    matched                           105,382  (_merge==3)
    -----------------------------------------

*/
keep if _merge==3
order stnd_firm firm_*
sort stnd_firm datadate
drop _merge
compress

*change year from datadate to fiscal year
drop year
gen year=fyear
replace year=year(datadate) if fyear==.

bysort stnd_firm year: gen N=_N
tab N
/*

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     76,316       72.42       72.42
          2 |     29,066       27.58      100.00
------------+-----------------------------------
      Total |    105,382      100.00


*/
tab N indfmt if N>1
/*

           |    Industry Format
         N |        FS       INDL |     Total
-----------+----------------------+----------
         2 |    14,525     14,541 |    29,066 
-----------+----------------------+----------
     Total |    14,525     14,541 |    29,066 

*/
drop if indfmt=="FS"
drop N
bysort stnd_firm year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     90,832       99.98       99.98
          2 |         16        0.02      100.00
------------+-----------------------------------
      Total |     90,848      100.00

*/
drop if fyear==.
drop N
bysort stnd_firm year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     90,601      100.00      100.00
------------+-----------------------------------
      Total |     90,601      100.00

*/

*create needed variables
encode stnd_firm, gen(firm_n)
xtset firm_n year, y
gen roa = ni / at

sort firm_n year
by firm_n: gen lroa=roa[_n-1]

*	Net income
sort firm_n year
by firm_n: gen lni=ni[_n-1]
	
*	Debt ratio
gen debt = dltt / at

*	R&D
gen rd = xrd / sale

*	Advertising
gen ad = xad / sale

label var roa "(CSTAT) Return on assets (ni / at)"
label var lroa "(CSTAT) 1-year lagged roa"
label var lni "(CSTAT) 1-year lagged ni"
label var debt "(CSTAT) Debt ratio (dltt / at)"
label var rd "(CSTAT) R&D expense by sales (xrd / sale)"
label var ad "(CSTAT) Advertising expense by sales (xad / sale)"

drop N

gen in_cstat=1
label var in_cstat "=1 if in compustat data"

gen ym=ym(fyear,fyr)

compress
save data\cstat-all-clean-with-stnd_firm-crosswalk.dta, replace


*	CSRHUB
use data\csrhub-all.dta, clear
merge m:1 stnd_firm using data\crosswalk-csrhub-kld-cstat-stnd_firm.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         4,539
        from master                        28  (_merge==1)
        from using                      4,511  (_merge==2)

    matched                           965,849  (_merge==3)
    -----------------------------------------

*/
keep if _merge==3
order stnd_firm ym
sort stnd_firm ym
drop _merge firm_n ticker in_other_vars in_ovrl_enviro in_2017_update ///
	in_csrhub row_id_csrhub entity_type
compress

gen in_csrhub=1
label var in_csrhub "=1 if in csrhub data"

compress
save data\csrhub-all-clean-with-stnd_firm-crosswalk.dta, replace









***	MERGE DATASETS TOGETHER ON STND_FIRM YM
*	Merge CSTAT and KLD on stnd_firm year
use data\cstat-all-clean-with-stnd_firm-crosswalk.dta, clear

merge 1:1 stnd_firm year using data\kld-all-clean-with-stnd_firm-crosswalk.dta, nogen
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        86,248
        from master                    63,044  (_merge==1)
        from using                     23,204  (_merge==2)

    matched                            27,557  (_merge==3)
    -----------------------------------------
*/
replace ym=ym(year,12) if ym==. & in_kld==1										/* Assume KLD not matched with CSTAT is month 12	*/

save data\cstat-2-kld-stnd_firm-year.dta, replace


*	CSRhub with merged CSTAT-KLD on stnd_firm ym
use data\csrhub-all-clean-with-stnd_firm-crosswalk.dta, clear

bysort stnd_firm ym: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |  1,051,911       99.84       99.84
          2 |      1,716        0.16      100.00
------------+-----------------------------------
      Total |  1,053,627      100.00
*/
drop if N>1																		/*	Come back and fix this	*/
drop N

merge 1:1 stnd_firm ym using data\cstat-2-kld-stnd_firm-year.dta, nogen
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                     1,028,922
        from master                   939,625  
        from using                     89,297  

    matched                            24,508  
    -----------------------------------------
*/
drop firm_n
order stnd_firm firm_*
format stnd_firm firm_* %30s

***	Set panel
encode stnd_firm, gen(firm_n)
xtset firm_n ym, m
order stnd_firm ym

*SAVE
compress
save data\csrhub-kld-cstat-with-crosswalk-exact-stnd_firm-ym-matches-clean.dta, replace

*/




capt log close
log using logs\mediation-analysis-2.txt, text replace
				***=============================***
				***		RUN MEDIATION ANALYSIS	***
				***		 WITH NEW DATASET		***
				***=============================***
///	LOAD DATA
use data\csrhub-kld-cstat-with-crosswalk-exact-stnd_firm-ym-matches-clean.dta, clear

///	ALL INDUSTRIES
*	Y = ni
*	X = over_rtg
*	M = net_kld
*mark medall
*markout medall ni over_rtg net_kld year debt rd ad

///	BARON AND KINNY MEDIATION ANALYSIS

***	All industries
***	Net KLD strengths
*Main relationship
xtreg ni over_rtg emp debt rd ad i.year, fe cluster(firm_n)
eststo m1_ni

*Mediator predicting independent variable
xtreg net_kld_str over_rtg emp debt rd ad i.year, fe cluster(firm_n)
eststo m1_net_kld

*Mediation analysis
xtreg ni over_rtg net_kld_str emp debt rd ad i.year, fe cluster(firm_n)
eststo m1_med

estout m1_ni m1_net_kld m1_med, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	keep(over_rtg net_kld_str emp debt rd ad _cons) ///
	order(over_rtg net_kld_str emp debt rd ad _cons)
	

	
***	All industries
***	Net KLD concerns
*Main relationship
xtreg ni over_rtg emp debt rd ad i.year, fe cluster(firm_n)
eststo m2_ni

*Mediator predicting independent variable
xtreg net_kld_con over_rtg emp debt rd ad i.year, fe cluster(firm_n)
eststo m2_net_kld

*Mediation analysis
xtreg ni over_rtg net_kld_con emp debt rd ad i.year, fe cluster(firm_n)
eststo m2_med

estout m2_ni m2_net_kld m2_med, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	keep(over_rtg net_kld_con emp debt rd ad _cons) ///
	order(over_rtg net_kld_con emp debt rd ad _cons)
	
	
	
///	WITHIN-BETWEEN RANDOM EFFECTS MODELS
foreach variable in net_kld_str net_kld_con over_rtg emp debt rd ad {
	bysort firm_n: egen `variable'_m=mean(`variable')
	bysort firm_n: gen `variable'_dm=`variable'-`variable'_m
}


*** All industries
***	Net KLD strengths
xtreg ni over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, re cluster(firm_n) base

xtreg net_kld_str over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, re cluster(firm_n) base

xtreg ni over_rtg_dm net_kld_str_dm over_rtg_m net_kld_str_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year, re cluster(firm_n) base


***	Control 2-digit NAICS
gen naics2=substr(naics,1,2)
destring(naics2), gen(naics_2)
replace naics_2=31 if naics_2==32 | naics_2==33									/*	Manufacturing */
replace naics_2=44 if naics_2==45												/*	Retail Trade	*/
replace naics_2=48 if naics_2==49												/*	Transport and Warehousing	*/

fvset base 51 naics_2

*	Net KLD strengths
xtreg ni over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nis1

xtreg net_kld_str over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nis2

xtreg ni over_rtg_dm net_kld_str_dm over_rtg_m net_kld_str_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nis3

*	Net KLD concerns
xtreg ni over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nic1

xtreg net_kld_con over_rtg_dm over_rtg_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nic2

xtreg ni over_rtg_dm net_kld_con_dm over_rtg_m net_kld_con_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nic3


*	Regression of net income on CSRHub rating
estout nis1 nic1, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	order(over* net*)

*	Regression of CSRHub rating on KLD strengths or concerns
estout nis2 nic2, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	order(over* net*)

*	Regression of net income on CSRHub rating and KLD strengths or concerns
estout nis1 nic1 nis3 nic3, cells(b(star fmt(%9.3f)) z(par))                ///
	stats(N  N_g r2_a, fmt(%9.0g %9.0g %9.0g %9.4g) ///
	labels("N" "Firms" "Adj. R^2"))      ///
	legend collabels(none) ///
	order(over* net*)

*	Regression of net income on CSRHub rating and KLD strengths and KLD concerns
xtreg ni over_rtg_dm net_kld_str_dm net_kld_con_dm over_rtg_m net_kld_str_m net_kld_con_m emp_dm debt_dm rd_dm ad_dm emp_m debt_m rd_m ad_m i.year i.naics_2, re base
eststo nistrcon










capt log close

















/*	NOVEMBER 6 2018: THIS SECTION USING MATCHIT NEEDS WORK AND THEN TO BE COMBINED WITH THE 
	data\csrhub-kld-cstat-with-crosswalk-exact-stnd_firm-matches-clean.dta
	DATASET TO INCREASE THE NUMBER OF MATCHES





				***=============================***
				***		IMPROVE THE MATCH		***
				***		WITH THE MATCHIT ALGO	***
				***=============================***
capt n ssc install freqindex
capt n ssc install matchit

***	CSRHub to CSTAT
use data\unique-stnd_firm-csrhub-stnd_firm-only.dta, clear

matchit idcsrhub stnd_firm using data\unique-stnd_firm-cstat-stnd_firm-only.dta, ///
	idu(idcstat) txtu(stnd_firm) similmethod(ngram,3) time threshold(.75) diagnose
																						/*	This drops all CSRHub firms with 0 ngram matches	*/
gsort stnd_firm -similscore

by stnd_firm: egen simmax=max(similscore)
by stnd_firm: gen n=_n
drop if simmax==1 & n!=1
drop simmax n
compress
save data\stnd_firm-csrhub-2-stnd_firm-cstat-matchit-all.dta, replace

*Save exact matches
preserve
keep if similscore==1
compress
save data\stnd_firm-csrhub-2-stnd_firm-cstat-matchit-exact.dta, replace
restore


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

*Check duplicate CSRHub matches
bysort matchitcsrhub: gen N=_N
tab N
/*          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        479       99.58       99.58
          2 |          2        0.42      100.00
------------+-----------------------------------
      Total |        481      100.00
*/
list matchitcsrhub matchitcstat if N>1, sepby(matchitcsrhub)
/*
     +--------------------------------------------------+
     |           matchitcsrhub             matchitcstat |
     |--------------------------------------------------|
280. | MARRONE BIO INNOVATIONS   MARRONE BIO INNOVTIONS |
281. | MARRONE BIO INNOVATIONS   MARRONE BIO INNOVTIONS |
     +--------------------------------------------------+
*/

drop if N>1
*(2 observations deleted)
drop N

*Check duplicate CSTAT matches
bysort matchitcstat: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        450       93.95       93.95
          2 |         26        5.43       99.37
          3 |          3        0.63      100.00
------------+-----------------------------------
      Total |        479      100.00
*/
list matchitcstat matchitcsrhub if N>1, sepby(matchitcstat)
/*
     +----------------------------------------------------------------------+
     |                   matchitcstat                         matchitcsrhub |
     |----------------------------------------------------------------------|
 52. |           ANHEUSER BUSCH INBEV                        ANHEUSER BUSCH |
 53. |           ANHEUSER BUSCH INBEV               ANHEUSER BUSCH INBEV NV |
     |----------------------------------------------------------------------|
 61. |                  ARCELORMITTAL                     ARCELORMITTAL USA |
 62. |                  ARCELORMITTAL                  ARCELORMITTAL BRASIL |
     |----------------------------------------------------------------------|
 95. |      BROOKFIELD PROPERTY PRTRS          BROOKFIELD PROPERTY PARTNERS |
 96. |      BROOKFIELD PROPERTY PRTRS                 BROOKFIELD PROPERTIES |
     |----------------------------------------------------------------------|
 97. |      CABLE & WIRELESS COMM PLC                      CABLE & WIRELESS |
 98. |      CABLE & WIRELESS COMM PLC   CABLE & WIRELESS COMMUNICATIONS PLC |
     |----------------------------------------------------------------------|
154. |                  DOMINOS PIZZA                     DOMINOS PIZZA ENT |
155. |                  DOMINOS PIZZA                     DOMINOS PIZZA GRP |
     |----------------------------------------------------------------------|
163. |         EMPIRE STATE REALTY TR                EMPIRE STATE REALTY OP |
164. |         EMPIRE STATE REALTY TR             EMPIRE STATE REALTY TRUST |
     |----------------------------------------------------------------------|
182. |     FRANKLIN FINANCIAL CORP VA                    FRANKLIN FINANCIAL |
183. |     FRANKLIN FINANCIAL CORP VA                FRANKLIN FINANCIAL SVC |
     |----------------------------------------------------------------------|
185. | FRESENIUS MEDICAL CARE AG & CO                FRESENIUS MEDICAL CARE |
186. | FRESENIUS MEDICAL CARE AG & CO      FRESENIUS MEDICAL CARE ARGENTINA |
     |----------------------------------------------------------------------|
198. |               GLOBAL INDEMNITY                            GLOBAL IND |
199. |               GLOBAL INDEMNITY                  GLOBAL INDEMNITY PLC |
     |----------------------------------------------------------------------|
407. |     STERLING FINANCIAL CORP WA                    STERLING FINANCIAL |
408. |     STERLING FINANCIAL CORP WA    STERLING FINANCIAL CORP OF SPOKANE |
     |----------------------------------------------------------------------|
419. |           TALLGRASS ENERGY PTR             TALLGRASS ENERGY PARTNERS |
420. |           TALLGRASS ENERGY PTR                      TALLGRASS ENERGY |
     |----------------------------------------------------------------------|
428. |             TELECOM ITALIA SPA                  TELECOM ITALIA MEDIA |
429. |             TELECOM ITALIA SPA                        TELECOM ITALIA |
     |----------------------------------------------------------------------|
438. |      TRANSPORTADORA DE GAS SUR    TRANSPORTADORA DE GAS DEL NORTE SA |
439. |      TRANSPORTADORA DE GAS SUR    TRANSPORTADORA DE GAS DEL INTERIOR |
440. |      TRANSPORTADORA DE GAS SUR      TRANSPORTADORA DE GAS DEL SUR SA |
     |----------------------------------------------------------------------|
458. |      VILLAGE BANK & TRUST FINL                  VILLAGE BANK & TRUST |
459. |      VILLAGE BANK & TRUST FINL        VILLAGE BANK & TRUST FINANCIAL |
     +----------------------------------------------------------------------+

*/
drop if N>1
*(29 observations deleted)
drop N

*	Merge the csrhub stnd_firm into the unique stnd_firm in cstat
gen stnd_firm=matchitcstat
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
keep if _merge==3
gen matchitcsrhub2cstat=1
drop _merge

replace stnd_firm=matchitcsrhub

compress
save data\stnd_firm-csrhub-2-stnd_firm-cstat-matchit-nonexact.dta, replace


***	Re-run fuzzy match
use data\unique-stnd_firm-csrhub-stnd_firm-only.dta, clear

capt n ssc install matchit
capt n ssc install freqindex

matchit idcsrhub stnd_firm using data\stnd_firm-cstat-2-stnd_firm-csrhub-matchit-nonexact.dta, ///
	idu(idcstat) txtu(stnd_firm) similmethod(ngram,3) time threshold(.75)
	
gsort stnd_firm -similscore

by stnd_firm: egen simmax=max(similscore)
by stnd_firm: gen n=_n
drop if simmax==1 & n!=1
*(2,496 observations deleted)
drop simmax n

codebook stnd_firm

compress
save data\matchit-csrhub-2-cstat-2.dta, replace

preserve
keep if similscore==1
*(2,075 observations deleted)
compress
save data\matchit-csrhub-2-cstat-exact-matches-2.dta, replace
restore

**	Assess likely matches:
use data\matchit-csrhub-2-cstat-2.dta, clear
drop if similscore==1
set seed 61047
bysort stnd_firm: gen rando=rnormal()
by stnd_firm: replace rando=rando[_n-1] if _n!=1

gsort rando stnd_firm -similscore
gen row=_n
br idcsrhub stnd_firm idcstat stnd_firm1 row

















/***	CSRHub to KLD
use data\unique-stnd_firm-csrhub-stnd_firm-only.dta, clear

capt n ssc install matchit
capt n ssc install freqindex

matchit idcsrhub stnd_firm using data\unique-stnd_firm-kld-stnd_firm-only.dta, ///
	idu(idkld) txtu(stnd_firm) similmethod(ngram,3) time threshold(.75) diagnose
	
gsort stnd_firm -similscore

*	Drop nonexact matches for records with an exact match
by stnd_firm: egen simmax=max(similscore)
by stnd_firm: gen n=_n
drop if simmax==1 & n!=1
*(4,604 observations deleted)
drop simmax n

compress
save data\stnd_firm-csrhub-2-stnd_firm-kld-matchit-all.dta, replace

*Save dataset of exact matches
preserve
keep if similscore==1
*(3,321 observations deleted)
compress
save data\stnd_firm-csrhub-2-stnd_firm-kld-matchit-exact.dta, replace
restore
*/
*Assess likely matches:
use data\stnd_firm-csrhub-2-stnd_firm-kld-matchit-all.dta, clear
drop if similscore==1
set seed 61047
bysort stnd_firm: gen rando=rnormal()
by stnd_firm: replace rando=rando[_n-1] if _n!=1

gsort rando stnd_firm -similscore
gen row=_n
br idcsrhub stnd_firm idkld stnd_firm1 row

/*		LIKELY MATCHES
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15523	TEXAS ROADHOUSE HOLDINGS	8581	TEXAS ROADHOUSE	2
8240	INTEGRATED DEVICE TECHNOLOGY INC IDT	4555	INTEGRATED DEVICE TECHNOLOGY	3
216	ABERTIS INFRAESTRUTURAS	141	ABERTIS INFRAESTRUCTURAS SA	4
15403	TELEFONICA DEUTSCHLAND	8516	TELEFONICA DEUTSCHLAND HOLDING AG	5
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9250	KUALA LUMPUR KEPONG BHD	5066	KUALA LUMPUR KEPONG BERHAD	7
5265	EFG HERMES HOLDING SAE	2991	EFG HERMES HOLDINGS SAE	8
idcsrhub	stnd_firm	idkld	stnd_firm1	row
910	AMER SPORTS	552	AMER SPORTS OYJ	19
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10899	NATL BANK OF ABU DHABI	5994	NATL BANK OF ABU DHABI PJ	37
504	AFRICAN ENERGY RESOURCES	7216	RAM ENERGY RESOURCES	38
14822	STOLT NIELSEN SA	8198	STOLT NIELSEN	39
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5504	ENERGIAS DO BRASIL SA	2984	EDP ENERGIAS DO BRASIL SA	49
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12856	QATAR ELECTRICITY & WATER	7133	QATAR ELECTRICITY & WATER CO Q	50
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11826	ORIOLA KD	6498	ORIOLA KD OYJ	72
9136	KONECRANES OYJ	5024	KONECRANES ABP	73
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3467	CHINA MERCHANTS BANK	1965	CHINA MERCHANTS BANK CO	75
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11704	OMRIX BIOPHARMECEUTICALS	6429	OMRIX BIOPHARMACEUTICALS	76
1206	APRIA HEALTH CARE GRP	766	APRIA HEALTHCARE GRP	77
11015	NEOPOST	6066	NEOPOST SA	78
3803	CNP ASSURANCES	2137	CNP ASSURANCES SA	79
3370	CHEUNG KONG PROPERTY HOLDINGS	1913	CHEUNG KONG HOLDINGS	80
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15388	TELECOM EGYPT	8505	TELECOM EGYPT CO SAE	87
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14821	STOCKMANN OYJ	8197	STOCKMANN OYJ ABP	96
16525	VERIFONE	9170	VERIFONE SYS	97
idcsrhub	stnd_firm	idkld	stnd_firm1	row
175	AALBERTS IND	123	AALBERTS IND NV	120
17073	WOOD GRP JOHN PLC	4816	JOHN WOOD GRP PLC	121
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7779	HUFVUDSTADEN	4294	HUFVUDSTADEN AB	123
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7747	HUA NAN FINANCIAL HOLDING CO	4279	HUA NAN FINANCIAL HOLDINGS CO	128
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11370	NORSK HYDRO	6245	NORSK HYDRO ASA	138
5743	EURAZEO	3229	EURAZEO SA	139
14705	STANDARD CHARTERED BANK	8116	STANDARD CHARTERED PLC	140
15961	TRINITY MIRROR GRP	8812	TRINITY MIRROR PLC	141
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1417	ASIA CEMENT CO	875	ASIA CEMENT	153
16815	WARTSILA OYJ	9324	WARTSILA OYJ ABP	154
idcsrhub	stnd_firm	idkld	stnd_firm1	row
idcsrhub	stnd_firm	idkld	stnd_firm1	row
795	ALLREAL HOLDING	486	ALLREAL HOLDING AG	160
13369	ROCHE HOLDINGS	7430	ROCHE HOLDING AG	161
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3937	COMMERCIAL BANK OF QATAR QSC	2222	COMMERCIAL BANK OF QATAR Q	186
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12255	PETROLEO BRASILEIRO SA	6778	PETROLEO BRASILEIRO SA PETROBRAS	211
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14391	SMART MODULAR TECHNOLOGIES	7940	SMART MODULAR TECHNOLOGIES WWH	265
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7781	HUGO BOSS USA	4298	HUGO BOSS AG	279
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2899	CANADIAN APARTMENT PROPERTIES REAL ESTAT	1621	CANADIAN APARTMENT PROPERTIES REAL ESTATE INVEST	281
2899	CANADIAN APARTMENT PROPERTIES REAL ESTAT	1622	CANADIAN APARTMENT PROPERTIES REAL ESTATE INVESTMENT TRUST	282
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12871	QIAGEN	7139	QIAGEN NV	286
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9549	LIBERTY MEDIA INTERACTIVE GRP	5219	LIBERTY MEDIA CORP INTERACTIVE	289
13670	SANOFI	7606	SANOFI SA	290
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14143	SHOPPING CTR AUSTRALASIA PROPERTY	7811	SHOPPING CTR AUSTRALASIA PROPERTY GRP RE	294
14143	SHOPPING CTR AUSTRALASIA PROPERTY	7812	SHOPPING CTR AUSTRALASIA PROPERTY GRP RE L	295
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1157	AP MOLLER MAERSK AS	732	AP MOELLER MAERSK AS	296
4143	CORE LAB	2363	CORE LAB NV	297
idcsrhub	stnd_firm	idkld	stnd_firm1	row
17067	WOLTERS KLUWER	9508	WOLTERS KLUWER NV	366
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1259	ARCH CAPITAL SVC	790	ARCH CAPITAL GRP	386
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7501	HICKS ACQUISITION CO I	4146	HICKS ACQUISITION	388
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3564	CHONGQING CHANGAN AUTOMOBILE CO LTD B HKD	2012	CHONGQING CHANGAN AUTOMOBILE CO	434
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16250	UNITED IND CORP	8993	UNITED IND	438
12422	PLAYTECH	6883	PLAYTECH PLC	439
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6300	FRESENIUS MEDICAL CARE	3526	FRESENIUS MEDICAL CARE AG & CO KGAA	500
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1533	ATLANTIA	940	ATLANTIA S	513
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8328	INTL BUSINESS MACHINES CORP IBM	4621	INTL BUSINESS MACHINES	515
idcsrhub	stnd_firm	idkld	stnd_firm1	row
482	AFFILIATED COMPUTER SVC INC ACS	303	AFFILIATED COMPUTER SVC	516
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7861	HYUNDAI MOBIS	4342	HYUNDAI MOBIS CO	532
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13896	SECURITAS	7711	SECURITAS AB	535
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6675	GLACIER BANK	3728	GLACIER BANCORP	537
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14872	SUBSEA 7	8225	SUBSEA 7SA	543
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9774	LUXOTTICA GRP	5353	LUXOTTICA GRP SPA	544
5304	EL PUERTO DE LIVERPOOL SA DE CV	3009	EL PUERTO DE LIVERPOOL SAB DE CV	545
5503	ENERGIAS DE PORTUGAL	2983	EDP ENERGIAS DE PORTUGAL SA	546
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14914	SUMITOMO MITSUI TRUST BANK	8244	SUMITOMO MITSUI TRUST HOLDINGS	579
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1954	BANK OF GREECE	5996	NATL BANK OF GREECE SA	583
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8376	INVENTEC APP	4654	INVENTEC	600
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16537	VERITY CU	9179	VERITY	603
3659	CITIC SECURITIES	2063	CITIC SECURITIES CO	604
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1451	ASPEN PHARMACARE	892	ASPEN PHARMACARE HOLDINGS	606
7439	HENDERSON LAND DEVELOPMENT CO LIMIT	4106	HENDERSON LAND DEVELOPMENT CO	607
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13175	RENEWABLE ENERGY	7316	RENEWABLE ENERGY GRP	608
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3314	CHARTER HALL RETAIL MGT	1877	CHARTER HALL RETAIL REIT	609
7443	HENNES & MAURITZ	3953	H & M HENNES & MAURITZ AB	610
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5340	ELEKTA AB	3022	ELEKTA AB PUBL	615
4696	DELTA AIRLINES	2656	DELTA AIR LINES	616
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7175	HACI OMER SABANCI HOLDING AS	3958	HACI OMER SABANCI HOLDING ANONIM SIRKETI	623
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15515	TEVA PHARMACEUTICALS	8574	TEVA PHARMACEUTICAL IND	630
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16766	W NIPPON EXPRESSWAY CO	6192	NIPPON EXPRESS CO	678
5335	ELECTROCOMPONENTS PLC	3020	ELECTROCOMPONENTS PUBLIC LTD	679
2745	BURLINGTON COAT FACTORY	1538	BURLINGTON COAT FACTORY WAREHOUSE	680
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12376	PINNACLE FOODS GRP	6851	PINNACLE FOODS	683
9727	LPL INVESTMENT HOLDINGS	5325	LPL INVESTMENT HOLDING	684
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16061	TURKIYE VAKIFLAR BANKASI TAO	8858	TUERKIYE VAKIFLAR BANKASI TAO	689
4097	CONTAINER STORE	2339	CONTAINER STORE GRP	690
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1894	BANCO SANTANDER CHILE SA	1102	BANCO SANTANDER CHILE	716
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6969	GROWTHPOINT PROPERTIES AUSTRALIA	3889	GROWTHPOINT PROPERTIES	718
idcsrhub	stnd_firm	idkld	stnd_firm1	row
17290	YULON NISSAN MOTOR CO	9629	YULON MOTOR CO	721
idcsrhub	stnd_firm	idkld	stnd_firm1	row
17290	YULON NISSAN MOTOR CO	6202	NISSAN MOTOR CO	720
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3439	CHINA GOLD INTL RES CORP	1954	CHINA GOLD INTL RESOURCES CORP	722
idcsrhub	stnd_firm	idkld	stnd_firm1	row
37	1ST COMMUNITY	26	1ST COMMUNITY BANCORP	724
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13075	RECKITT BENCKISER	7264	RECKITT BENCKISER GRP PLC	730
idcsrhub	stnd_firm	idkld	stnd_firm1	row
17007	WILLOW FINANCIAL	9474	WILLOW FINANCIAL BANCORP	732
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16918	WESTERN AREAS NL	9402	WESTERN AREAS	739
idcsrhub	stnd_firm	idkld	stnd_firm1	row
17086	WOORI FINANCE HOLDINGS CO	9520	WOORIFINANCE HOLDINGS CO	740
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15027	SUSSER HOLDING	8314	SUSSER HOLDINGS	777
16056	TURKIYE GARANTI BANKASI AS	8855	TUERKIYE GARANTI BANKASI AS	778
16056	TURKIYE GARANTI BANKASI AS	8875	TURKIYE GARANTI BANKASI ANONIM SIRKETI	779
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5022	DRESSER RAND	2863	DRESSER RAND GRP	783
15389	TELECOM ITALIA	8506	TELECOM ITALIA SPA	784
12784	PT TELEKOMUNIKASI INDONESIA	7097	PT TELEKOMUNIKASI INDONESIA TBK	785
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2340	BIOLASE TECHNOLOGIES	1318	BIOLASE TECHNOLOGY	787
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6914	GREENE CNTY BANCORP	3868	GREENE CNTY BANCSHARES	789
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8007	IMERYS	4422	IMERYS SA	799
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9824	MACQUARIE KOREA INFRASTRUCTURE FUND	5381	MACQUARIE INFRASTRUCTURE	801
idcsrhub	stnd_firm	idkld	stnd_firm1	row
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1056	ANADOLU EFES BIRACILIK VE MALT SANAYI AS	675	ANADOLU EFES BIRACILIK VE MALT SANAYII AS	814
1056	ANADOLU EFES BIRACILIK VE MALT SANAYI AS	674	ANADOLU EFES BIRACILIK VE MALT SANAYII ANONIM SI	815
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10179	MEDIASET SPA	5584	MEDIASET S	844
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7574	HITEJINRO CO	4179	HITE JINRO CO	847
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13439	ROYAL BANK OF SCOTLAND GRP	7475	ROYAL BANK OF SCOTLAND GRP PLC	851
13439	ROYAL BANK OF SCOTLAND GRP	7476	ROYAL BANK OF SCOTLAND GRP PUBLIC	852
13382	ROCKWOOD HOLDING	7442	ROCKWOOD HOLDINGS	808
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7662	HONG LEONG IND BERHAD	4230	HONG LEONG BANK BERHAD	886
4013	COMPUTACENTER UK	2276	COMPUTACENTER PLC	887
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2214	BEN & JERRYS HOMEMADE HOLDINGS	1254	BEN & JERRYS HOMEMADE	889
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14795	STERLING BANK	8178	STERLING BANCORP	892
6882	GREAT PORTLAND ESTATE PLC	3845	GREAT PORTLAND ESTATES PLC	893
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15967	TRIPLECROWN ACQUISITION	8819	TRIPLECROWN ACQ	897
1872	BANCO ESPIRITO SANTO ER	1095	BANCO ESPIRITO SANTO SA	898
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3831	COCA COLA FEMSA SAB CV	2154	COCA COLA FEMSA SAB DE CV	906
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8063	IND & COMMERCIAL BANK OF CHINA ASIA	4453	IND & COMMERCIAL BANK OF CHINA	907
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5321	ELEC POWER DEVELOPMENT CO LIMIT	3015	ELEC POWER DEVELOPMENT CO	962
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10383	MICHAEL PAGE INTL	5718	MICHAEL PAGE INTL PLC	980
954	AMERICAN INTL IND	590	AMERICAN INTL GRP	981
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16539	VERMILION ENERGY TRUST	9181	VERMILION ENERGY	983
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11641	OIL & NATURAL GAS	6392	OIL & NATURAL GAS CORP	986
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6141	FLUGHAFEN ZURICH	3440	FLUGHAFEN ZURICH AG	995
idcsrhub	stnd_firm	idkld	stnd_firm1	row
467	AEROVIRONMENT TWC	294	AEROVIRONMENT	999
9225	KRATOS DEFENSE & SECURITY SYS	5056	KRATOS DEFENSE & SECURITY SOLUTIONS	1000
idcsrhub	stnd_firm	idkld	stnd_firm1	row
17381	ZIJIN MINING GRP H	9654	ZIJIN MINING GRP CO	1002
13760	SBERBANK ROSSIA	7639	SBERBANK ROSSII OAO	1003
idcsrhub	stnd_firm	idkld	stnd_firm1	row
17091	WORKSPACE GRP	9522	WORKSPACE GRP PLC	1054
idcsrhub	stnd_firm	idkld	stnd_firm1	row
616	AIXTRON	371	AIXTRON SE	1062
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5084	DUQUESNE LIGHT	2904	DUQUESNE LIGHT HOLDINGS	1065
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1256	ARCELORMITTAL BRASIL	789	ARCELORMITTAL SA	1083
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5711	ESSILOR INTL	3214	ESSILOR INTL SA	1084
1838	BANCA MONTE DEI PASCHI DI SIEN	1078	BANCA MONTE DEI PASCHI DI SIENA S	1085
13110	REED ELSEVIER	7279	REED ELSEVIER NV	1086
13110	REED ELSEVIER	7280	REED ELSEVIER PLC	1087
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6947	GROUPE BRUXELLES LAMBERT	3886	GROUPE BRUXELLES LAMBERT SA	1096
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7643	HOMESERVE	4217	HOMESERVE PLC	1121
16159	UNIBAIL RODAMCO	8948	UNIBAIL RODAMCO SE	1122
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3835	COCA COLA ICECEK SANAYI AS	2157	COCA COLA ICECEK AS	1124
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5915	FAMOUS DAVES OF AMERICA	3316	FAMOUS DAVES AMER	1126
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3877	COLGATE PALMOLIVE INDIA	2185	COLGATE PALMOLIVE	1144
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1962	BANK OF MARIN	1135	BANK OF MARIN BANCORP	1149
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16230	UNITED BANCSHARES	8981	UNITED BANKSHARES	1169
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9254	KUEHNE & NAGEL	5068	KUEHNE & NAGEL INTL AG	1170
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2045	BARE ESCENTUALS BEAUTY	1172	BARE ESCENTUALS	1173
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5493	ENEL GREEN POWER SPA	3093	ENEL GREEN POWER S	1181
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7564	HITACHI HIGH TECHNOLOGIES AMERICA	4176	HITACHI HIGH TECHNOLOGIES	1190
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14745	STATE BANK OF INDIA GRP	8150	STATE BANK OF INDIA	1195
idcsrhub	stnd_firm	idkld	stnd_firm1	row
782	ALLIED PROPERTIES REAL ESTATE INVESTMENT	474	ALLIED PROPERTIES REAL ESTATE INVESTMENT TRUST	1199
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15539	TGS NOPEC GEOPHYSICAL ASA	8590	TGS NOPEC GEOPHYSICAL CO ASA	1215
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16151	UMW HOLDINGS BHD	8944	UMW HOLDINGS BERHAD	1216
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16396	USINAS SIDERURGICAS DE MINAS GERAIS	9096	USINAS SIDERURGICAS DE MINAS GERAIS SA USIMINAS	1218
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15197	TAIWAN GLASS INDUSTRY	8414	TAIWAN GLASS IND	1219
13163	REMY COINTREAU USA	7310	REMY COINTREAU SA	1220
11000	NEIMAN MARCUS	6060	NEIMAN MARCUS GRP	1221
7098	GUARANTEE BANCORP	3930	GUARANTY BANCORP	1222
5379	EMAAR PROPERTIES PJSC	3033	EMAAR PROPERTIES PJ	1223
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5211	ECORODOVIAS INFRAESTRUTURA LOGISTICA SA	2973	ECORODOVIAS INFRAESTRUTURA E LOGISTICA SA	1233
16859	WEBDOTCOM	9363	WEBDOTCOM GRP	1234
11350	NORDIC AMERICAN TANKER SHIPPING	6239	NORDIC AMERICAN TANKER SHIPP	1235
1893	BANCO SANTANDER BRAZIL SA	1101	BANCO SANTANDER BRASIL SA	1236
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1910	BANGKOK DUSIT MEDICAL SVC PCL	1114	BANGKOK DUSIT MEDICAL SVC PUBLIC CO	1312
1910	BANGKOK DUSIT MEDICAL SVC PCL	1115	BANGKOK DUSIT MEDICAL SVC PUBLIC CO LI	1313
idcsrhub	stnd_firm	idkld	stnd_firm1	row
120	4 KIDS ENTERTAINMENT	97	4KIDS ENTERTAINMENT	1319
idcsrhub	stnd_firm	idkld	stnd_firm1	row
17148	XCHANGING	9562	XCHANGING PLC	1348
11412	NORTHWESTERN UNIV	6266	NORTHWESTERN	1349
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6921	GREENLIGHT CAPITAL	3872	GREENLIGHT CAPITAL RE	1356
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4769	DEUTSCHE POSTBANK AG	2694	DEUTSCHE POST AG	1358
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15593	THROMBOGENICS	8622	THROMBOGENICS NV	1370
3990	COMPANIA DE MINAS BUENAVENTURA SA	2264	COMPANIA DE MINAS BUENAVENTURA SAA	1371
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3595	CHUNGHWA TELECOM	2026	CHUNGHWA TELECOM CO	1379
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15000	SUPERIOR IND	8298	SUPERIOR IND INTL	1391
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1873	BANCO ESTADO DO RIO GRANDE SUL SA	1094	BANCO DO ESTADO DO RIO GRANDE DO SUL SA	1393
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1929	BANK HANDLOWY W WARSZAWIEA	1117	BANK HANDLOWY W WARSZAWIE SPOLKA AKCYJNA	1422
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15213	TAKEDA PHARMACEUTICAL	8420	TAKEDA PHARMACEUTICAL CO	1427
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9891	MALAYSIA AIRPORTS HOLDINGS BHD	5423	MALAYSIA AIRPORTS HOLDINGS BERHAD	1447
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10286	MERIDIAN RESOURCES	5651	MERIDIAN RESOURCE	1477
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4954	DONGFENG MOTOR GRP H	2820	DONGFENG MOTOR GRP CO	1480
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9137	KONGSBERG AUTOMOTIVE HOLDING ASA	5025	KONGSBERG AUTOMOTIVE ASA	1485
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3983	COMPANHIA ENERGETICA DE SAO PAULO CESP	1844	CESP COMPANHIA ENERGETICA DE SAO PAULO	1523
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12465	POLSKI KONCERN NAFTOWY ORLEN SA	6904	POLSKI KONCERN NAFTOWY ORLEN SPOLKA AKCYJNA	1529
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7635	HOME PRODUCT CTR PUBLIC CO LIMIT	4211	HOME PRODUCT CTR PUBLIC CO	1530
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3024	CARILLION	1703	CARILLION PLC	1544
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3022	CARGOTEC	1701	CARGOTEC OYJ	1546
16552	VESTAS WIND SYS	9190	VESTAS WIND SYS AS	1547
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15821	TOYOTA TSUSHO UK	8729	TOYOTA TSUSHO	1561
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5516	ENERGY DEVELOPMENTS	3102	ENERGY DEVELOPMENT	1564
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1756	AZIMUT HOLDING SPA	1047	AZIMUT HOLDING S	1566
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10581	MOBIMO HOLDING	5823	MOBIMO HOLDING AG	1568
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14168	SIAM CITY CEMENT PUBLIC CO	7827	SIAM CEMENT PUBLIC CO	1582
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5144	EAGLE BANCORP MONTANA	2933	EAGLE BANCORP	1584
5285	EIFFAGE	3001	EIFFAGE SA	1585
3219	CENTRAIS ELETRICAS BRASILEIRA SA	1824	CENTRAIS ELETRICAS BRASILEIRAS SA	1586
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3219	CENTRAIS ELETRICAS BRASILEIRA SA	1825	CENTRAIS ELETRICAS BRASILEIRAS SA ELETROBRAS	1587
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15440	TELKOM SA	8532	TELKOM SA SOC	1596
idcsrhub	stnd_firm	idkld	stnd_firm1	row
360	ADECCO	230	ADECCO SA	1604
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8823	KAGOSHIMA BANK	4169	HIROSHIMA BANK	1613
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2112	BBA AVIATION	1206	BBA AVIATION PLC	1615
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4595	DASSAULT SYSTEMES	2600	DASSAULT SYSTEMES SA	1626
15579	THOMAS WEISEL PARTNERS	8613	THOMAS WEISEL PARTNERS GRP	1627
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10825	N AMERICAN GALVANIZING & COATINGS	5952	N AMERICAN GALVANIZING & COATING	1640
4618	DAVIDE CAMPARI MILANO SPA	2613	DAVIDE CAMPARI MILANO S	1641
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13564	SAFETY KLEEN SYS	7554	SAFETY KLEEN	1643
idcsrhub	stnd_firm	idkld	stnd_firm1	row
17022	WINCOR NIXDORF	9482	WINCOR NIXDORF AG	1652
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7251	HANKOOK TIRE	3993	HANKOOK TIRE CO	1654
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12565	PRECISION DRILLING TRUST	6969	PRECISION DRILLING	1686
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8072	IND SVC OF AMERERICA	4458	IND SVC OF AMERICA	1692
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13141	REITMANS CANADA	7295	REITMANS CANADA LIMITEE	1694
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5281	EI DUPONT DE NEMOURS & CO	3000	EI DU PONT DE NEMOURS & CO	1716
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5281	EI DUPONT DE NEMOURS & CO	2900	DUPONT EI DE NEMOURS & CO	1715
idcsrhub	stnd_firm	idkld	stnd_firm1	row
918	AMERICAN AIRLINES	562	AMERICAN AIRLINES GRP	1717
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2452	BM & F BOVESPA SA BOLSA VALORES MERCADOR	1372	BM & F BOVESPA SA BOLSA DE VALORES MERCADORIA	1727
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2452	BM & F BOVESPA SA BOLSA VALORES MERCADOR	1373	BM & F BOVESPA SA BOLSA DE VALORES MERCADORIAS E FUTUROS	1728
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9241	KRUNG THAI BANK PCL	5063	KRUNG THAI BANK PUBLIC CO	1729
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16988	WILH WILHELMSEN HOLDING ASA	9461	WILH WILHELMSEN ASA	1732
1487	ASTRA AGRO LESTARI TBK	7074	PT ASTRA AGRO LESTARI TBK	1733
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5660	EREGLI DEMIR VE CELIK FABRIKALARI TAS	3189	EREGLI DEMIR VE CELIK FABRIKALARI TURK ANONIM SI	1748
5660	EREGLI DEMIR VE CELIK FABRIKALARI TAS	3190	EREGLI DEMIR VE CELIK FABRIKALARI TURK ANONIM SIRKETI	1749
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5522	ENERGY INFRASTRUCTURE ACQUISTION	3104	ENERGY INFRASTRUCTURE ACQUISITION	1754
9272	KURITA WATER INDUSTRY	5076	KURITA WATER IND	1755
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2618	BRILLIANCE CHINA AUTOMOTIVE HOLDINGS LIM	1466	BRILLIANCE CHINA AUTOMOTIVE HOLDINGS	1756
6099	FISHER SCIENTIFIC	3408	FISHER SCIENTIFIC INTL	1757
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9632	LIPPO KARAWACI	7091	PT LIPPO KARAWACI TBK	1759
14720	STANLEY ELEC US	8129	STANLEY ELEC CO	1760
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1492	ASTRAZENECA	914	ASTRAZENECA PLC	1762
6467	GAS NATURAL SA ESP	3604	GAS NATURAL SDG SA	1763
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5556	ENKA INSAAT VE SANAYI AS	3125	ENKA INSAAT VE SANAYI ANONIM SIRKETI	1767
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1891	BANCO SABADELL	1092	BANCO DE SABADELL SA	1781
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10640	MONOTYPE IMAGING	5854	MONOTYPE IMAGING HOLDINGS	1782
15335	TECHNIP	8483	TECHNIP SA	1783
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10857	NAN KANG RUBBER TIRE	5970	NANKANG RUBBER TIRE CORP	1792
314	ACS ACTIVIDADES CONSTRUCCION Y SERVICIOS	197	ACS ACTIVIDADES DE CONSTRUCCION Y SERVICIOS SA	1793
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1255	ARCELORMITTAL	789	ARCELORMITTAL SA	1802
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15081	SWISS LIFE HOLDING	8338	SWISS LIFE HOLDING AG	1803
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13499	RYANAIR HOLDINGS PLC	7523	RYANAIR HOLDINGS PUBLIC LTD	1813
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1017	AMMB HOLDINGS BHD	652	AMMB HOLDINGS BERHAD	1814
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13205	REPUBLIC AIRWAYS	7328	REPUBLIC AIRWAYS HOLDINGS	1825
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11449	NOVO NORDISK	6286	NOVO NORDISK AS	1847
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4180	CORPBANCA SA	2383	CORPBANCA	1852
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16126	ULKER BISKUVI SANAYI AS	8922	ULKER BISKUVI SANAYI ANONIM SIRKETI	1873
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8175	INMARSAT	4512	INMARSAT PLC	1878
16058	TURKIYE IS BANKASI AS	8856	TUERKIYE IS BANKASI AS	1879
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1812	BALFOUR BEATTY	1065	BALFOUR BEATTY PLC	1883
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4510	DAEWOO SHIPBUILDING & MARINE ENGR	2567	DAEWOO SHIPBUILDING & MARINE ENGR CO	1887
4510	DAEWOO SHIPBUILDING & MARINE ENGR	2568	DAEWOO SHIPBUILDING & MARINE ENGR CO LT	1888
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15299	TAYLOR WIMPEY	8463	TAYLOR WIMPEY PLC	1918
16510	VEOLIA ENVIRONNEMENT	9161	VEOLIA ENVIRONNEMENT SA	1919
16510	VEOLIA ENVIRONNEMENT	9162	VEOLIA ENVIRONNEMENT VE SA	1920
8165	INGENICO	4499	INGENICO SA	1921
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8319	INTESA SANPAOLO	4614	INTESA SANPAOLO S	1926
8319	INTESA SANPAOLO	4615	INTESA SANPAOLO SPA	1927
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11899	OVERSEAS CHINESE BANKING CORP	6548	OVERSEA CHINESE BANKING CORP	1945
2906	CANADIAN OIL SANDS TRUST	1627	CANADIAN OIL SANDS	1946
5720	ESURE GRP	3219	ESURE GRP PLC	1947
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16240	UNITED COMMUNITY BANK	8984	UNITED COMMUNITY BANKS	1950
idcsrhub	stnd_firm	idkld	stnd_firm1	row
785	ALLIED WORLD ASSURANCE CO LTD AWAC	477	ALLIED WORLD ASSURANCE CO HOLDINGS	1955
4867	DIRECT LINE INS GRP	2766	DIRECT LINE INS GRP PLC	1956
8712	JOHNSON MATTHEY	4819	JOHNSON MATTHEY PLC	1957
14896	SULZER	8235	SULZER AG	1958
7853	HYUNDAI ENGR & CONSTRUCTION	4335	HYUNDAI ENGR & CONSTRUCTION CO	1959
idcsrhub	stnd_firm	idkld	stnd_firm1	row
799	ALM BRAND	493	ALM BRAND AS	1961
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10647	MONTE DEI PASCHI DI SIENA	1078	BANCA MONTE DEI PASCHI DI SIENA S	1970
8836	KALBE FARMA	7090	PT KALBE FARMA TBK	1971
3989	COMPANIA DE BANCO DE CREDITO E INVERSIONES	1091	BANCO DE CREDITO E INVERSIONES	1972
6256	FOXCONN TECHNOLOGY	3497	FOXCONN TECHNOLOGY CO	1973
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2580	BRAIT SA	1447	BRAIT SE	1977
9077	KLEPIERRE	4994	KLEPIERRE SA	1978
9684	LONDON STOCK EXCHANGE	5295	LONDON STOCK EXCHANGE GRP PLC	1979
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3217	CENTERSTATE BANK	1818	CENTERSTATE BANKS	1981
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7658	HONG LEONG BANK BHD	4230	HONG LEONG BANK BERHAD	1991
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12577	PREMIER OIL	6981	PREMIER OIL PLC	1995
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16036	TULLETT PREBON GRP	8862	TULLETT PREBON PLC	1996
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15461	TENARIS	8543	TENARIS SA	2002
15354	TECO ELEC & MACHINERY	8491	TECO ELEC & MACHINERY CO	2003
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14643	SPORT SUPPLY GRP	8074	SPORT SUPPLY GRP INC DEL	2006
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3233	CENTURY BANK	1828	CENTURY BANCORP	2033
16060	TURKIYE SISE VE CAM FABRIKALARI AS	8880	TURKIYE SISE VE CAM FABRIKALARI ANONIM SIRKETI	2034
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14454	SODEXO	7965	SODEXO SA	2037
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11440	NOVATEK MICROELECTRONICS CORP	6278	NOVATEK MICROELECTRONICS	2039
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16252	UNITED INTERNET AG & CO	8995	UNITED INTERNET AG	2044
8037	IMPERIAL TOBACCO GRP	4442	IMPERIAL TOBACCO GRP PLC	2045
3400	CHINA ARCHITECTURAL ENGR	1930	CHINA ARCHITECTURAL ENG	2046
8267	INTERCONTINENTAL HOTELS GRP	4576	INTERCONTINENTAL HOTELS GRP PLC	2047
3724	CLARIANT	2092	CLARIANT AG	2048
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4070	CONSOLIDATED COMMUNICATIONS	2322	CONSOLIDATED COMMUNICATIONS HOLDINGS	2052
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2635	BRITISH AMERICAN TOBACCO UGANDA	1474	BRITISH AMERICAN TOBACCO PLC	2056
10355	METTLER TOLEDO	5700	METTLER TOLEDO INTL	2057
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3378	CHICAGO BRIDGE & IRON	1918	CHICAGO BRIDGE & IRON CO NV	2059
17281	YUANTA FINANCIAL HOLDING CO	9625	YUANTA FINANCIAL HOLDINGS CO	2060
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13797	SCHNEIDER ELEC	7657	SCHNEIDER ELEC SA	2069
13797	SCHNEIDER ELEC	7658	SCHNEIDER ELEC SE	2070
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11881	OTSUKA HOLDING CO	6535	OTSUKA HOLDINGS CO	2073
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16804	WANT WANT HOLDINGS	9315	WANT WANT CHINA HOLDINGS	2078
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11258	NIPPON TELEGRAPH & TELEPHONE CORPORATI	6198	NIPPON TELEGRAPH & TELEPHONE	2080
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15086	SWISSCOM	8341	SWISSCOM AG	2088
14634	SPIRENT COMMUNICATIONS	8064	SPIRENT COMMUNICATIONS PLC	2089
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15972	TRISTATE HOLDINGS	8822	TRISTATE CAPITAL HOLDINGS	2093
6269	FRANKLIN FINANCIAL SVC	3507	FRANKLIN FINANCIAL	2094
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2242	BERJAYA SPORTS TOTO BHD	1266	BERJAYA SPORTS TOTO BERHAD	2095
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12503	PORTUGAL TELECOM SGPS	6925	PORTUGAL TELECOM SGPS SA	2097
15349	TECNICOLOR SA	8482	TECHNICOLOR SA	2098
7017	GRUPO FINANCIERO BANORTE SA DE CV	3908	GRUPO FINANCIERO BANORTE SAB DE CV	2099
idcsrhub	stnd_firm	idkld	stnd_firm1	row
17378	ZHUZHOU CSR TIMES ELEC	9652	ZHUZHOU CSR TIMES ELEC CO	2103
3604	CIA HERING SA	2031	CIA HERING	2104
idcsrhub	stnd_firm	idkld	stnd_firm1	row
996	AMERIS BANK	633	AMERIS BANCORP	2118
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4086	CONSTELLATION ENERGY PARTNERS	2336	CONSTELLATION ENERGY GRP	2122
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1802	BAKKAFROST	6791	PF BAKKAFROST	2129
11404	NORTHSTAR REALTY FINANANCE	6265	NORTHSTAR REALTY FINANCE	2130
13581	SAIPEM SPA	7565	SAIPEM S	2131
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14420	SNC LAVALIN	7958	SNC LAVALIN GRP	2144
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9705	LOREAL	5315	LOREAL SA	2146
7018	GRUPO FINANCIERO INBURSA SA	3909	GRUPO FINANCIERO INBURSA SA DE CV	2147
7018	GRUPO FINANCIERO INBURSA SA	3910	GRUPO FINANCIERO INBURSA SAB DE CV	2148
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12268	PETRONAS GAS BHD	6785	PETRONAS GAS BERHAD	2153
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3985	COMPANHIA PARANAENSE DE ENERGIA PRF B	2261	COMPANHIA PARANAENSE DE ENERGIA	2161
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4771	DEUTSCHE WOHNEN	2696	DEUTSCHE WOHNEN AG	2163
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11213	NIGHTHAWK RADIOLOGY SVC	6183	NIGHTHAWK RADIOLOGY HOLDINGS	2164
6809	GOME ELECTRICAL APPLIANCES HOLDINGS	3798	GOME ELECTRICAL APPLIANCES HOLDING	2165
3662	CITIZEN HOLDINGS	2066	CITIZEN HOLDINGS CO	2166
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12223	PERNOD RICARD USA	6758	PERNOD RICARD SA	2184
13446	ROYAL MAIL GRP PLC	7482	ROYAL MAIL PLC	2185
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4005	COMPELLENT TECHNOLOGIES	2271	COMPELLENT TECH	2199
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14189	SIEMENS AG	7832	SIEMENS	2201
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11029	NESTLE	6074	NESTLE SA	2248
15641	TINGYI CAYMAN ISLANDS HOLDINGS	8649	TINGYI CAYMAN ISLANDS HOLDING	2249
16760	W COAST BANK	9286	W COAST BANCORP	2250
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1093	ANGLO AMERICAN	691	ANGLO AMERICAN PLC	2252
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6168	FONCIERE DES REGIONS GFR	3454	FONCIERE DES REGIONS	2254
6168	FONCIERE DES REGIONS GFR	3455	FONCIERE DES REGIONS SA	2255
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12316	PHILIP MORRIS CR AS	6820	PHILIP MORRIS	2259
2358	BIOSANTE PHARMACEUTICAL	1326	BIOSANTE PHARMACEUTICALS	2260
14616	SPECTRIS	8053	SPECTRIS PLC	2261
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13219	RESOLUTION PLC	7344	RESOLUTION	2269
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3306	CHARLOTTE RUSSE	1869	CHARLOTTE RUSSE HOLDING	2281
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6545	GENERAL MOTORS CORP GM	3650	GENERAL MOTORS	2286
15530	TF1 TELEVISION FRANCAISE 1	8527	TELEVISION FRANCAISE 1SA	2287
15530	TF1 TELEVISION FRANCAISE 1	8526	TELEVISION FRANCAISE 1 SA	2288
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4539	DAINIPPON SUMITOMO PHARMA	2580	DAINIPPON SUMITOMO PHARMA CO	2291
4539	DAINIPPON SUMITOMO PHARMA	8239	SUMITOMO DAINIPPON PHARMA CO	2292
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1095	ANGLO AMERICAN PLATINUM CORP	690	ANGLO AMERICAN PLATINUM	2294
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1853	BANCO COMERCIAL PORTUGUES	1088	BANCO COMERCIAL PORTUGUES SA	2295
15924	TRELLEBORG	8784	TRELLEBORG AB	2296
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16698	VODAFONE GRP	9263	VODAFONE GRP PLC	2316
14544	SORIN S	8002	SORIN SPA	2317
4288	CREDIT SUISSE GRP	2447	CREDIT SUISSE GRP AG	2318
13996	SEVERSTAL	7762	SEVERSTAL PAO	2319
13996	SEVERSTAL	7761	SEVERSTAL OAO	2320
15219	TALAAT MOUSTAFA GRP HOLDING	8422	TALAAT MOSTAFA GRP HOLDING CO SAE	2321
12389	PIRELLI & CO	6863	PIRELLI & CS	2322
3530	CHINA TELECOM USA	1993	CHINA TELECOM CORP	2323
6598	GEORG FISCHER	3694	GEORG FISCHER AG	2324
6268	FRANKLIN FINANCIAL NETWORK	3507	FRANKLIN FINANCIAL	2325
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16334	UNIVERSAL TRUCKLOAD SVC INC UTSI	9039	UNIVERSAL TRUCKLOAD SVC	2333
15200	TAIWAN MOBILE	8415	TAIWAN MOBILE CO	2334
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15222	TALECRIS BIOTHERAPEUTICS	8424	TALECRIS BIOTHERAPEUTICS HOLDINGS	2359
8580	JAPAN AIRLINES	4764	JAPAN AIRLINES CO	2360
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7032	GRUPO MEXICO SA	3913	GRUPO MEXICO SAB DE CV	2362
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15407	TELEFONICA O2 CZECH REPUBLIC AS	8515	TELEFONICA CZECH REPUBLIC AS	2374
15407	TELEFONICA O2 CZECH REPUBLIC AS	6347	O2 CZECH REPUBLIC AS	2375
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8936	KENNEDY WILSON	4924	KENNEDY WILSON HOLDINGS	2388
12574	PREMIER FOODS	6977	PREMIER FOODS PLC	2389
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4913	DOHA BANK QSC	2796	DOHA BANK Q	2392
9006	KIMBERLY CLARK DE MEXICO SAB DE CV	4964	KIMBERLY CLARK DE MEXICO SA DE CV	2393
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1867	BANCO DEL ESTADO DE CHILE	1090	BANCO DE CHILE	2439
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9298	KYOWA HAKKO KIRIN	5081	KYOWA HAKKO KIRIN CO	2453
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1642	AUTOMATIC DATA PROCESSING INC ADP	992	AUTOMATIC DATA PROCESSING	2473
8418	IOI PROPERTIES BHD	4679	IOI PROPERTIES GRP BHD	2474
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2039	BARCLAYS	1170	BARCLAYS PLC	2477
3525	CHINA STEEL CHEM	1991	CHINA STEEL	2478
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5134	E NIPPON EXPRESSWAY CO	6192	NIPPON EXPRESS CO	2487
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5172	EASYLINK SVC INTL	2950	EASYLINK SVC INTL CORP CL A	2490
7047	GRUPO TELEVISA SA	3914	GRUPO TELEVISA SAB	2491
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1540	ATLAS COPCO A	948	ATLAS COPCO AB	2516
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14350	SKILLED HEALTHCARE	7915	SKILLED HEALTHCARE GRP	2521
10844	NAGOYA RAILROAD	5963	NAGOYA RAILROAD CO	2522
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12261	PETROLEUM GEO SVC	6780	PETROLEUM GEO SVC ASA	2561
8265	INTERCONEXION ELECTRICA SA	4574	INTERCONEXION ELECTRICA SAESP	2562
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1531	ATKINS WS PLC	9549	WS ATKINS PLC	2567
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3629	CINEDIGM DIGITAL CINEMA	2045	CINEDIGM DIGITAL CINEMA CORP CL A	2569
16948	WETHERSPOON JD PLC	4789	JD WETHERSPOON PLC	2570
12074	PARTY CITY HOLDCO	6658	PARTY CITY	2571
15812	TOYO SUISAN	8724	TOYO SUISAN KAISHA	2572
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3040	CARNIVAL CORP & PLC	1709	CARNIVAL CORP	2586
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9477	LEGRAND	5174	LEGRAND SA	2591
9470	LEGACYTEXAS FINANCIAL GRP	5170	LEGACY TEXAS FINANCIAL GRP	2592
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1379	ASAHI HOLDINGS	855	ASAHI GRP HOLDINGS	2613
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15951	TRILOGY ENERGY TRUST	8805	TRILOGY ENERGY	2614
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16277	UNITED TRACTORS	7100	PT UNITED TRACTORS TBK	2624
9550	LIBERTY MEDIA STARZ	5217	LIBERTY MEDIA	2625
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14800	STERLING FINANCIAL CORP OF SPOKANE	8182	STERLING FINANCIAL CORP	2631
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8257	INTER PIPELINE FUND	4563	INTER PIPELINE	2633
1964	BANK OF MONTREAL QUEBEC	1137	BANK OF MONTREAL	2634
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6068	FINGERPRINT CARDS	3389	FINGERPRINT CARDS AB	2640
7858	HYUNDAI MARINE & FIRE INS	4339	HYUNDAI MARINE & FIRE INS CO	2641
11324	NOKIAN RENKAAT OY	6227	NOKIAN RENKAAT OYJ	2642
11244	NIPPON PAINT	6194	NIPPON PAINT CO	2643
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10034	MASRAF AL RAYAN Q	5494	MASRAF AL RAYAN QSC	2664
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2057	BARRATT DEVELOPMENTS	1182	BARRATT DEVELOPMENTS PLC	2673
6251	FOUNTAINHEAD PROPERTY TRUST	3493	FOUNTAINHEAD PROPERTY TRUST MGT	2674
12542	POWSZECHNA KASA OSZCZEDNOSCI BANK POLSKI SA	6950	POWSZECHNA KASA OSZCZEDNOSCI BANK POLSKI SPOLKA	2675
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3049	CARREFOUR	1716	CARREFOUR SA	2677
1320	ARKEMA	821	ARKEMA SA	2678
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6342	FUCHS PETROLUB AG	3553	FUCHS PETROLUB SE	2686
5495	ENEL S	3094	ENEL SPA	2687
9285	KVAERNER	5078	KVAERNER ASA	2688
14433	SOCIEDAD QUIMICA Y MINERA CHILE SA	7960	SOCIEDAD QUIMICA Y MINERA DE CHILE SA	2689
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12799	PTT EXPLORATION & PRODUCTION PCL	7105	PTT EXPLORATION & PRODUCTION PUBLIC CO	2692
12799	PTT EXPLORATION & PRODUCTION PCL	7106	PTT EXPLORATION & PRODUCTION PUBLIC CO LI	2693
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1925	BANK DANAMON INDONESIA	7077	PT BANK DANAMON INDONESIA TBK	2709
idcsrhub	stnd_firm	idkld	stnd_firm1	row
246	ACACIA RESEARCH CORP ACACIA TECHNOLOGIES	160	ACACIA RESEARCH ACACIA TECHNOLOGIES	2711
7562	HITACHI CONSTRUCTION MACHINERY CO L	4175	HITACHI CONSTRUCTION MACHINERY CO	2712
16789	WAL MART DE MEXICO SA	9301	WAL MART DE MEXICO SAB DE CV	2713
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2313	BIM BIRLESIK MAGAZALAR AS	1304	BIM BIRLESIK MAGAZALAR ANONIM SIRKETI	2717
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1597	AURIGA IND	973	AURIGA IND AS	2718
3753	CLEVELAND CLINIC	2108	CLEVELAND CLIFFS	2719
idcsrhub	stnd_firm	idkld	stnd_firm1	row
133	5TH 3RD BANK	102	5TH 3RD BANCORP	2723
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12798	PTT CHEM PUBLIC CO	7107	PTT GLOBAL CHEM PUBLIC CO	2739
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15398	TELEFONICA BRASIL SA ADR	8514	TELEFONICA BRASIL SA	2741
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5605	ENVISION HEALTHCARE	3156	ENVISION HEALTHCARE HOLDINGS	2745
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13455	RR DONNELLEY	7383	RH DONNELLEY	2747
13455	RR DONNELLEY	7490	RR DONNELLEY & SONS	2748
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14595	SPAREBANK 1 SR BANK	8037	SPAREBANK 1 SMN	2750
4015	COMPUTER SCIENCES CORP CSC	2281	COMPUTER SCIENCES	2751
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15427	TELEPERFORMANCE	8523	TELEPERFORMANCE SA	2754
10799	MUTUALFIRST FINANCIAL	5939	MUTUALFIRST FINL	2755
10683	MOSKOVSKAYA FONDOVAYA BIRZHA OAO	5886	MOSKOVSKAYA BIRZHA OAO	2756
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15460	TENAGA NASIONAL BHD	8542	TENAGA NASIONAL BERHAD	2758
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11925	PACIFIC	6579	PACIFICORP	2769
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11325	NOLATO	6229	NOLATO AB	2793
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16557	VESUVIUS	9191	VESUVIUS PLC	2799
2461	BNP PARIBAS	1377	BNP PARIBAS SA	2800
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16897	WENDEL	9386	WENDEL SA	2811
8588	JAPAN PETROLEUM EXPLORATION	4767	JAPAN PETROLEUM EXPLORATION CO	2812
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14918	SUMITOMO REALTY & DEVELOPMENT CO LI	8245	SUMITOMO REALTY & DEVELOPMENT CO	2814
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1080	ANDRITZ	685	ANDRITZ AG	2823
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9657	LOBLAW	5281	LOBLAW CO	2827
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3576	CHRISTIAN DIOR	2017	CHRISTIAN DIOR SA	2834
idcsrhub	stnd_firm	idkld	stnd_firm1	row
11898	OVERSEA CHINESE BANKING	6548	OVERSEA CHINESE BANKING CORP	2837
14292	SINOPEC SHANGHAI PETROCHEMICAL	7887	SINOPEC SHANGHAI PETROCHEMICAL CO	2838
idcsrhub	stnd_firm	idkld	stnd_firm1	row
7262	HANNAFORD	3996	HANNAFORD BROS	2846
16051	TURK TELEKOMUNIKASYON AS	8854	TUERK TELEKOMUENIKASYON AS	2847
16051	TURK TELEKOMUNIKASYON AS	8872	TURK TELEKOMUNIKASYON ANONIM SIRKETI	2848
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10096	MAYNE PHARMA	5530	MAYNE PHARMA GRP	2852
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8878	KAYNE ANDERSON ENERGY DEVELOPMENT	4891	KAYNE ANDERSON ENERGY DEV	2854
5347	ELEMENTIS	3024	ELEMENTIS PLC	2855
15436	TELIGENT AB	8530	TELIGENT	2856
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6189	FORD OTOMOTIV SANAYI AS	3461	FORD OTOMOTIV SANAYI ANONIM SIRKETI	2862
9143	KONINKLIJKE DSM	5029	KONINKLIJKE DSM NV	2863
12295	PHARMACEUTICAL PRODUCT DEVELOPMENT INC PPD	6800	PHARMACEUTICAL PRODUCT DEVELOPMENT	2864
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14614	SPECTRA ENERGY PARTNERS	8049	SPECTRA ENERGY	2866
idcsrhub	stnd_firm	idkld	stnd_firm1	row
5130	E JAPAN RAILWAY CO	2925	E JAPAN RAILWAY	2867
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9316	LA JOLLA PHARMACEUTICAL	5089	LA JOLLA PHARMACEUTICAL CO LJPC	2870
idcsrhub	stnd_firm	idkld	stnd_firm1	row
17279	YTL POWER INTL BHD	9624	YTL POWER INTL BERHAD	2923
idcsrhub	stnd_firm	idkld	stnd_firm1	row
605	AIRPORTS OF THAILAND PCL	364	AIRPORTS OF THAILAND PUBLIC CO	2924
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12760	PT INDOFOOD CBP SUKSES MAKMUR	4469	INDOFOOD CBP SUKSES MAKMUR TBK PT	2926
12760	PT INDOFOOD CBP SUKSES MAKMUR	7088	PT INDOFOOD SUKSES MAKMUR TBK	2927
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15390	TELECOM ITALIA MEDIA	8506	TELECOM ITALIA SPA	2928
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1672	AVENTINE RENEWABLE ENERGY	1008	AVENTINE RENEWABLE ENERGY HOLDINGS	2931
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14162	SHUTTERFLYDOTCOM	7823	SHUTTERFLY	2933
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14305	SIRF TECHNOLOGY	7891	SIRF TECHNOLOGY HOLDINGS	2935
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14400	SMITH & NEPHEW	7942	SMITH & NEPHEW PLC	2938
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12485	PORSCHE AUTOMOBIL HOLDING PREFERENCE SE	6918	PORSCHE AUTOMOBIL HOLDING SE	2955
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4933	DOMINOS PIZZA GRP	2814	DOMINOS PIZZA GRP PLC	2970
idcsrhub	stnd_firm	idkld	stnd_firm1	row
4933	DOMINOS PIZZA GRP	2812	DOMINOS PIZZA	2971
4933	DOMINOS PIZZA GRP	2813	DOMINOS PIZZA ENT	2972
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6509	GECINA	3620	GECINA SA	2973
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9145	KONINKLIJKE PHILIPS ELEC	5031	KONINKLIJKE PHILIPS NV	2974
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8392	INVESTMENT AB KINNEVIK B	4663	INVESTMENT AB KINNEVIK	2978
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2633	BRITISH AMERICAN TOBACCO MALAYSIA BHD	1473	BRITISH AMERICAN TOBACCO MALAYSIA BERHAD	2979
idcsrhub	stnd_firm	idkld	stnd_firm1	row
9783	LYONDELLBASELL IND	5359	LYONDELLBASELL IND NV	2999
9783	LYONDELLBASELL IND	5360	LYONDELLBASELL IND NV CL A	3000
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8104	INDOCEMENT TUNGGAL PRAKARSA	7087	PT INDOCEMENT TUNGGAL PRAKARSA TBK	3028
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16435	VALLOUREC	9122	VALLOUREC SA	3031
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6826	GORMAN RUPP IND	3810	GORMAN RUPP	3033
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12222	PERNOD RICARD ITALIA	6758	PERNOD RICARD SA	3040
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10775	MULTIPLAN EMPREENDIMENT IMOBILIARIOS SA	5932	MULTIPLAN EMPREENDIMENTOS IMOBILIARIOS SA	3041
idcsrhub	stnd_firm	idkld	stnd_firm1	row
14072	SHAW IND GRP	7782	SHAW IND	3049
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13443	ROYAL DUTCH SHELL	7479	ROYAL DUTCH SHELL PLC	3059
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1643	AUTOMOTIVE GRP HOLDINGS	993	AUTOMOTIVE HOLDINGS GRP	3061
idcsrhub	stnd_firm	idkld	stnd_firm1	row
525	AGEAS SA NV	322	AGEAS SA	3063
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15730	TONENGENERAL SEKIYU	8687	TONENGENERAL SEKIYU KK	3071
4652	DEBENHAMS	2631	DEBENHAMS PLC	3072
idcsrhub	stnd_firm	idkld	stnd_firm1	row
12266	PETRONAS CHEM GRP BHD	6782	PETRONAS CHEM GRP BERHAD	3076
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16675	VIVENDI	9254	VIVENDI SA	3100
9855	MAGNUM HUNTER RESOURCE	5402	MAGNUM HUNTER RESOURCES	3101
idcsrhub	stnd_firm	idkld	stnd_firm1	row
957	AMERICAN MEDICAL SYS	594	AMERICAN MEDICAL SYS HOLDINGS	3136
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8107	INDORAMA VENTURES PCL	4470	INDORAMA VENTURES PUBLIC CO	3138
idcsrhub	stnd_firm	idkld	stnd_firm1	row
13263	REZIDOR HOTEL GRP	7380	REZIDOR HOTEL GRP AB	3140
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6166	FOMENTO ECONOMICO MEXICANO SA	3453	FOMENTO ECONOMICO MEXICANO SAB DE CV	3147
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10628	MONEYSUPERMARKETDOTCOM	5848	MONEYSUPERMARKETDOTCOM GRP PLC	3150
idcsrhub	stnd_firm	idkld	stnd_firm1	row
10537	MITSUBISHI UFJ LEASE & FINANCE	5805	MITSUBISHI UFJ LEASE & FINANCE CO	3156
14814	STMICROELECTRONICS	8191	STMICROELECTRONICS NV	3157
idcsrhub	stnd_firm	idkld	stnd_firm1	row
8103	INDO TAMBANGRAYA MEGAH	4468	INDO TAMBANGRAYA MEGAH TBK PT	3259
15308	TD AMERITRADE	8469	TD AMERITRADE HOLDING	3260
idcsrhub	stnd_firm	idkld	stnd_firm1	row
15021	SURGUTNEFTEGAZ	8310	SURGUTNEFTEGAZ OAO	3266
idcsrhub	stnd_firm	idkld	stnd_firm1	row
1463	ASSICURAZIONI GENERALI	899	ASSICURAZIONI GENERALI S	3270
idcsrhub	stnd_firm	idkld	stnd_firm1	row
6036	FIDELITY NATL FINANCIAL VENTURES	3376	FIDELITY NATL FINANCIAL	3294
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2932	CAP GEMINI	1644	CAP GEMINI SA	3297
idcsrhub	stnd_firm	idkld	stnd_firm1	row
16279	UNITED UTILITIES PLC	9019	UNITED UTILITIES GRP PLC	3302
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3455	CHINA INTL MARINE CONTAINERS GRP CO	1959	CHINA INTL MARINE CONTAINERS GRP	3309
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3455	CHINA INTL MARINE CONTAINERS GRP CO	1960	CHINA INTL MARINE CONTAINERS GRP LT	3310
idcsrhub	stnd_firm	idkld	stnd_firm1	row
3978	COMPANHIA DE SANEAMENTO BASICO DO ESTADO DE SAO PAULO SABESP	2257	COMPANHIA DE SANEAMENTO BASICO DO ESTADO DE SAO PAULO	3316
3978	COMPANHIA DE SANEAMENTO BASICO DO ESTADO DE SAO PAULO SABESP	2256	COMPANHIA DE SANEAMENTO BASICO DO ESTADO DE SAO	3317
idcsrhub	stnd_firm	idkld	stnd_firm1	row
2106	BAYTEX ENERGY TRUST	1202	BAYTEX ENERGY	3320
*/

***	Create dataset of nonexact matches
import excel "data\data-matchit\matchit-csrhub-2-kld-nonexact-matches.xlsx", ///
	sheet("Sheet1") clear firstrow
	
rename (stnd_firm stnd_firm1) (matchitcsrhub matchitkld)

*Duplicate csrhub names
bysort matchitcsrhub: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        448       88.02       88.02
          2 |         58       11.39       99.41
          3 |          3        0.59      100.00
------------+-----------------------------------
      Total |        509      100.00
*/

list matchitcsrhub matchitkld if N>1, sepby(matchitcsrhub)
/*
     +---------------------------------------------------------------------------------------------------------------------------+
     |                                                matchitcsrhub                                                   matchitkld |
     |---------------------------------------------------------------------------------------------------------------------------|
 25. |                     ANADOLU EFES BIRACILIK VE MALT SANAYI AS             ANADOLU EFES BIRACILIK VE MALT SANAYII ANONIM SI |
 26. |                     ANADOLU EFES BIRACILIK VE MALT SANAYI AS                    ANADOLU EFES BIRACILIK VE MALT SANAYII AS |
     |---------------------------------------------------------------------------------------------------------------------------|
 60. |                                BANGKOK DUSIT MEDICAL SVC PCL                       BANGKOK DUSIT MEDICAL SVC PUBLIC CO LI |
 61. |                                BANGKOK DUSIT MEDICAL SVC PCL                          BANGKOK DUSIT MEDICAL SVC PUBLIC CO |
     |---------------------------------------------------------------------------------------------------------------------------|
 77. |                     BM & F BOVESPA SA BOLSA VALORES MERCADOR                BM & F BOVESPA SA BOLSA DE VALORES MERCADORIA |
 78. |                     BM & F BOVESPA SA BOLSA VALORES MERCADOR     BM & F BOVESPA SA BOLSA DE VALORES MERCADORIAS E FUTUROS |
     |---------------------------------------------------------------------------------------------------------------------------|
 85. |                     CANADIAN APARTMENT PROPERTIES REAL ESTAT   CANADIAN APARTMENT PROPERTIES REAL ESTATE INVESTMENT TRUST |
 86. |                     CANADIAN APARTMENT PROPERTIES REAL ESTAT             CANADIAN APARTMENT PROPERTIES REAL ESTATE INVEST |
     |---------------------------------------------------------------------------------------------------------------------------|
 94. |                             CENTRAIS ELETRICAS BRASILEIRA SA                 CENTRAIS ELETRICAS BRASILEIRAS SA ELETROBRAS |
 95. |                             CENTRAIS ELETRICAS BRASILEIRA SA                            CENTRAIS ELETRICAS BRASILEIRAS SA |
     |---------------------------------------------------------------------------------------------------------------------------|
103. |                          CHINA INTL MARINE CONTAINERS GRP CO                          CHINA INTL MARINE CONTAINERS GRP LT |
104. |                          CHINA INTL MARINE CONTAINERS GRP CO                             CHINA INTL MARINE CONTAINERS GRP |
     |---------------------------------------------------------------------------------------------------------------------------|
122. | COMPANHIA DE SANEAMENTO BASICO DO ESTADO DE SAO PAULO SABESP              COMPANHIA DE SANEAMENTO BASICO DO ESTADO DE SAO |
123. | COMPANHIA DE SANEAMENTO BASICO DO ESTADO DE SAO PAULO SABESP        COMPANHIA DE SANEAMENTO BASICO DO ESTADO DE SAO PAULO |
     |---------------------------------------------------------------------------------------------------------------------------|
137. |                            DAEWOO SHIPBUILDING & MARINE ENGR                         DAEWOO SHIPBUILDING & MARINE ENGR CO |
138. |                            DAEWOO SHIPBUILDING & MARINE ENGR                      DAEWOO SHIPBUILDING & MARINE ENGR CO LT |
     |---------------------------------------------------------------------------------------------------------------------------|
139. |                                    DAINIPPON SUMITOMO PHARMA                                 DAINIPPON SUMITOMO PHARMA CO |
140. |                                    DAINIPPON SUMITOMO PHARMA                                 SUMITOMO DAINIPPON PHARMA CO |
     |---------------------------------------------------------------------------------------------------------------------------|
149. |                                            DOMINOS PIZZA GRP                                            DOMINOS PIZZA ENT |
150. |                                            DOMINOS PIZZA GRP                                        DOMINOS PIZZA GRP PLC |
151. |                                            DOMINOS PIZZA GRP                                                DOMINOS PIZZA |
     |---------------------------------------------------------------------------------------------------------------------------|
161. |                                    EI DUPONT DE NEMOURS & CO                                   EI DU PONT DE NEMOURS & CO |
162. |                                    EI DUPONT DE NEMOURS & CO                                    DUPONT EI DE NEMOURS & CO |
     |---------------------------------------------------------------------------------------------------------------------------|
178. |                        EREGLI DEMIR VE CELIK FABRIKALARI TAS             EREGLI DEMIR VE CELIK FABRIKALARI TURK ANONIM SI |
179. |                        EREGLI DEMIR VE CELIK FABRIKALARI TAS        EREGLI DEMIR VE CELIK FABRIKALARI TURK ANONIM SIRKETI |
     |---------------------------------------------------------------------------------------------------------------------------|
189. |                                     FONCIERE DES REGIONS GFR                                      FONCIERE DES REGIONS SA |
190. |                                     FONCIERE DES REGIONS GFR                                         FONCIERE DES REGIONS |
     |---------------------------------------------------------------------------------------------------------------------------|
211. |                                  GRUPO FINANCIERO INBURSA SA                            GRUPO FINANCIERO INBURSA SA DE CV |
212. |                                  GRUPO FINANCIERO INBURSA SA                           GRUPO FINANCIERO INBURSA SAB DE CV |
     |---------------------------------------------------------------------------------------------------------------------------|
248. |                                              INTESA SANPAOLO                                            INTESA SANPAOLO S |
249. |                                              INTESA SANPAOLO                                          INTESA SANPAOLO SPA |
     |---------------------------------------------------------------------------------------------------------------------------|
285. |                                           LYONDELLBASELL IND                                   LYONDELLBASELL IND NV CL A |
286. |                                           LYONDELLBASELL IND                                        LYONDELLBASELL IND NV |
     |---------------------------------------------------------------------------------------------------------------------------|
348. |                                PT INDOFOOD CBP SUKSES MAKMUR                            INDOFOOD CBP SUKSES MAKMUR TBK PT |
349. |                                PT INDOFOOD CBP SUKSES MAKMUR                                PT INDOFOOD SUKSES MAKMUR TBK |
     |---------------------------------------------------------------------------------------------------------------------------|
352. |                             PTT EXPLORATION & PRODUCTION PCL                    PTT EXPLORATION & PRODUCTION PUBLIC CO LI |
353. |                             PTT EXPLORATION & PRODUCTION PCL                       PTT EXPLORATION & PRODUCTION PUBLIC CO |
     |---------------------------------------------------------------------------------------------------------------------------|
357. |                                                REED ELSEVIER                                             REED ELSEVIER NV |
358. |                                                REED ELSEVIER                                            REED ELSEVIER PLC |
     |---------------------------------------------------------------------------------------------------------------------------|
367. |                                   ROYAL BANK OF SCOTLAND GRP                               ROYAL BANK OF SCOTLAND GRP PLC |
368. |                                   ROYAL BANK OF SCOTLAND GRP                            ROYAL BANK OF SCOTLAND GRP PUBLIC |
     |---------------------------------------------------------------------------------------------------------------------------|
371. |                                                 RR DONNELLEY                                                 RH DONNELLEY |
372. |                                                 RR DONNELLEY                                          RR DONNELLEY & SONS |
     |---------------------------------------------------------------------------------------------------------------------------|
378. |                                               SCHNEIDER ELEC                                            SCHNEIDER ELEC SE |
379. |                                               SCHNEIDER ELEC                                            SCHNEIDER ELEC SA |
     |---------------------------------------------------------------------------------------------------------------------------|
381. |                                                    SEVERSTAL                                                SEVERSTAL OAO |
382. |                                                    SEVERSTAL                                                SEVERSTAL PAO |
     |---------------------------------------------------------------------------------------------------------------------------|
384. |                            SHOPPING CTR AUSTRALASIA PROPERTY                     SHOPPING CTR AUSTRALASIA PROPERTY GRP RE |
385. |                            SHOPPING CTR AUSTRALASIA PROPERTY                   SHOPPING CTR AUSTRALASIA PROPERTY GRP RE L |
     |---------------------------------------------------------------------------------------------------------------------------|
435. |                              TELEFONICA O2 CZECH REPUBLIC AS                                         O2 CZECH REPUBLIC AS |
436. |                              TELEFONICA O2 CZECH REPUBLIC AS                                 TELEFONICA CZECH REPUBLIC AS |
     |---------------------------------------------------------------------------------------------------------------------------|
444. |                                   TF1 TELEVISION FRANCAISE 1                                    TELEVISION FRANCAISE 1 SA |
445. |                                   TF1 TELEVISION FRANCAISE 1                                     TELEVISION FRANCAISE 1SA |
     |---------------------------------------------------------------------------------------------------------------------------|
459. |                                     TURK TELEKOMUNIKASYON AS                         TURK TELEKOMUNIKASYON ANONIM SIRKETI |
460. |                                     TURK TELEKOMUNIKASYON AS                                   TUERK TELEKOMUENIKASYON AS |
     |---------------------------------------------------------------------------------------------------------------------------|
461. |                                   TURKIYE GARANTI BANKASI AS                       TURKIYE GARANTI BANKASI ANONIM SIRKETI |
462. |                                   TURKIYE GARANTI BANKASI AS                                  TUERKIYE GARANTI BANKASI AS |
     |---------------------------------------------------------------------------------------------------------------------------|
478. |                                         VEOLIA ENVIRONNEMENT                                      VEOLIA ENVIRONNEMENT SA |
479. |                                         VEOLIA ENVIRONNEMENT                                   VEOLIA ENVIRONNEMENT VE SA |
     |---------------------------------------------------------------------------------------------------------------------------|
506. |                                        YULON NISSAN MOTOR CO                                              NISSAN MOTOR CO |
507. |                                        YULON NISSAN MOTOR CO                                               YULON MOTOR CO |
     +---------------------------------------------------------------------------------------------------------------------------+
*/
drop if N>1
*(61 observations deleted)
drop N

*Duplicate kld names
bysort matchitkld: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        432       96.43       96.43
          2 |         16        3.57      100.00
------------+-----------------------------------
      Total |        448      100.00
*/

list matchitkld matchitcsrhub row if N>1, sepby(matchitkld)
/*
     +---------------------------------------------------------------------------+
     |                        matchitkld                    matchitcsrhub    row |
     |---------------------------------------------------------------------------|
 31. |                  ARCELORMITTAL SA             ARCELORMITTAL BRASIL   1083 |
 32. |                  ARCELORMITTAL SA                    ARCELORMITTAL   1802 |
     |---------------------------------------------------------------------------|
 48. | BANCA MONTE DEI PASCHI DI SIENA S        MONTE DEI PASCHI DI SIENA   1970 |
 49. | BANCA MONTE DEI PASCHI DI SIENA S   BANCA MONTE DEI PASCHI DI SIEN   1085 |
     |---------------------------------------------------------------------------|
187. |                FRANKLIN FINANCIAL       FRANKLIN FINANCIAL NETWORK   2325 |
188. |                FRANKLIN FINANCIAL           FRANKLIN FINANCIAL SVC   2094 |
     |---------------------------------------------------------------------------|
221. |            HONG LEONG BANK BERHAD              HONG LEONG BANK BHD   1991 |
222. |            HONG LEONG BANK BERHAD            HONG LEONG IND BERHAD    886 |
     |---------------------------------------------------------------------------|
305. |                 NIPPON EXPRESS CO           W NIPPON EXPRESSWAY CO    678 |
306. |                 NIPPON EXPRESS CO           E NIPPON EXPRESSWAY CO   2487 |
     |---------------------------------------------------------------------------|
323. |      OVERSEA CHINESE BANKING CORP          OVERSEA CHINESE BANKING   2837 |
324. |      OVERSEA CHINESE BANKING CORP    OVERSEAS CHINESE BANKING CORP   1945 |
     |---------------------------------------------------------------------------|
327. |                  PERNOD RICARD SA             PERNOD RICARD ITALIA   3040 |
328. |                  PERNOD RICARD SA                PERNOD RICARD USA   2184 |
     |---------------------------------------------------------------------------|
436. |                TELECOM ITALIA SPA                   TELECOM ITALIA    784 |
437. |                TELECOM ITALIA SPA             TELECOM ITALIA MEDIA   2928 |
     +---------------------------------------------------------------------------+
*/
drop if N>1
*(16 observations deleted)
drop N

*	Merge the csrhub stnd_firm into the unique stnd_firm in cstat
gen stnd_firm = matchitkld
merge 1:1 stnd_firm using data\unique-stnd_firm-kld-stnd_firm-only.dta
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         9,248
        from master                         0  (_merge==1)
        from using                      9,248  (_merge==2)

    matched                               432  (_merge==3)
    -----------------------------------------
*/
keep if _merge==3
gen matchitcsrhub2kld=1
drop _merge

replace stnd_firm=matchitcsrhub

compress
save data\stnd_firm-csrhub-2-stnd_firm-kld-matchit-nonexact.dta, replace












*****************************************************************
*	COMBINE THE 2 MATCHIT DATASETS INTO A SINGLE DATASET WITH	*
*					CSRHUB, CSTAT, AND KLD						*
*****************************************************************

*** Merge nonexact matches
use data\stnd_firm-csrhub-2-stnd_firm-cstat-matchit-nonexact.dta, clear

merge 1:1 stnd_firm using data\stnd_firm-csrhub-2-stnd_firm-kld-matchit-nonexact.dta 

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                           760
        from master                       389  (_merge==1)
        from using                        371  (_merge==2)

    matched                                61  (_merge==3)
    -----------------------------------------
*/

drop _merge row

order stnd_firm matchitcsrhub matchitkld matchitcstat idcsrhub idkld idcstat ///
	firm conm matchitcsrhub2kld matchitcsrhub2cstat
	
sort stnd_firm

***	Merge in exact matches
merge 1:1 stnd_firm using data\stnd_firm-csrhub-2-stnd_firm-cstat-matchit-exact.dta, ///
	gen(_mergecsrhub2cstat)

merge 1:1 stnd_firm using data\stnd_firm-csrhub-2-stnd_firm-kld-matchit-exact.dta, ///
	gen(_mergecsrhub2kld)

tab _mergecsrhub2cstat _mergecsrhub2kld


***	Label variables
	
label var stnd_firm "firm name, standardized from csrhub"
label var matchitcsrhub "firm name, standardized from csrhub"
label var matchitkld "firm name, standardized from kld"
label var matchitcstat "firm name, standardized from compustat"
label var idcsrhub "=1 if in csrhub"
label var idkld "=1 if in kld"
label var idcstat "=1 if in compustat"
rename firm firmkld
label var firmkld "firm name, kld"
rename conm firmcstat
label var firmcstat "firm name, compustat"
label var matchitcsrhub2kld "=1 if standardized firm names matched, csrhub to kld"
label var matchitcsrhub2cstat "=1 if standardized firm names matched, csrhub to compustat"








*/










*END








































































*END
