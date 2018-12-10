********************************************************************************
*Title: Dissertation Chapter 3 Mediation Analysis of the CSR - Performance Relationship
*Created by: Nicholas Poggioli (poggi005@umn.edu)
*Created on: November 2018
********************************************************************************

***	CLEANING ALL COMPUSTAT FUNDAMENTALS ANNUAL VARIABLES FOR ALL CUSIPS

***===============================================***
*		Clean CSTAT data from CSRHub CUSIPs				*
***===============================================***
/*
***	File size reduction
use data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, clear

*	clean
order conm cusip tic datadate fyear fyr

*	keep unique cusip ym
gen ym=ym(year(datadate),month(datadate))
label var ym "(CSTAT) Year-month = datadate year and datadate month"

bysort cusip ym: gen N=_N
tab N
keep if N==1
drop N

gen in_cstat_csrhub_cusip=1
label var in_cstat_csrhub_cusip "Indicator =1 if in CSTAT data created from unique CSRHub CUSIPs"

*	save
compress
save data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018-clean.dta, replace


***===============================================***
*		Clean CSTAT data from KLD CUSIPs			*
***===============================================***
use data/cstat-all-variables-for-all-cusip9-in-kld-data-1990-2018.dta, clear

*	generate ym variable
gen ym=ym(year(datadate),month(datadate))
label var ym "Year-month = datadate year and datadate month"

order conm cusip tic datadate fyear fyr

bysort cusip ym: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     94,504       99.87       99.87
          4 |          4        0.00       99.88
          8 |          8        0.01       99.89
         13 |         13        0.01       99.90
         15 |         30        0.03       99.93
         16 |         64        0.07      100.00
------------+-----------------------------------
      Total |     94,623      100.00
*/
drop if N>1
drop N

gen in_cstat_kld_cusip=1
label var in_cstat_kld_cusip "Indicator =1 if in CSTAT data created from unique KLD CUSIPs"

compress
save data/cstat-all-variables-for-all-cusip9-in-kld-data-1990-2018-clean.dta, replace

***===============================================***
*	CREATE CSTAT AGE VARIABLE		*
***===============================================***
use "D:\Dropbox\papers\active\dissertation-csrhub\project\data\cstat-all-variables-for-all-cusip9-in-kld-data-1950-2018.dta"

merge 1:1 cusip datadate using D:\Dropbox\papers\active\dissertation-csrhub\project\data\cstat-all-variables-for-all-cusip9-in-csrhub-data-1950-2018.dta, update assert(1 2 3 4 5)
/*

    Result                           # of obs.
    -----------------------------------------
    not matched                        52,307
        from master                    29,745  (_merge==1)
        from using                     22,562  (_merge==2)

    matched                            96,767
        not updated                    96,767  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/
drop if cusip==""

sort cusip datadate
by cusip: gen n=_n

gen yr_start=year(datadate) if n==1
by cusip: replace yr_start = yr_start[_n-1] if yr_start==.
gen age = year(datadate) - yr_start + 1


label var yr_start "(CSTAT) First year in CSTAT data"
label var age "(CSTAT) Years in data: year(datadate) - yr_start"

keep cusip datadate costat yr_start age

compress
save "data/cstat-all-variables-for-all-cusip9-in-kld-and-csrhub-data-1950-2018-age-variables.dta", replace

***===============================================***
*	MERGE CSTAT data from CSRHUB and KLD CUSIPs		*
***===============================================***
use data/cstat-all-variables-for-all-cusip9-in-kld-data-1990-2018-clean.dta, clear

merge 1:1 cusip ym using data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018-clean.dta, ///
	gen(cstatvars) update assert(1 2 3 4 5)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        39,837
        from master                    20,147  (_merge==1)
        from using                     19,690  (_merge==2)

    matched                            74,357
        not updated                    74,357  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/

label var cstatvars "Merge indicator for CSTAT data of KLD CUSIPs to CSRHub CUSIPs"

*	Save full dataset
save data/cstat-all-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, replace

*/

***	Subset to needed variables
use data/cstat-all-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, clear
/*	CSTAT variables
		
		MEASURE					VARNAME			EQUATION TO CREATE FROM CSTAT VARIABLES
		--------------------	--------		---------------------------------------
		Revenue					revt		=	REVT
		Net income				ni			=	NI
		Sales					sale		=	SALE
		Total assets			at			=	AT								
		Advertising expense		xad			=	XAD								
		R&D expense				xrd			=	XRD								
		Firm size				emp			=	EMP								*Barnett & Salomon 2012
		
********VARIABLE EQUATIONS FROM C:\Dropbox\papers\active\dissertation-csrhub\project\data\data-documentation\2017_10_12_wrds_data_items.pdf
		Debt					debt		=	DLTT / AT		
		Return on assets 		roa 		=	NI / AT
		Tobin's Q 				tobinq		=	(AT + (CSHO * PRCC_F) - CEQ) / AT
		Market to book ratio	mkt2book	=	MKVALT / BKVLPS
		R&D intensity			rd			=	XRD / SALE
		Advertising intensity	ad			=	XAD / SALE
		Firm size				size		=	log(AT)
*/

*	merge age variables
merge 1:1 cusip datadate using "data/cstat-all-variables-for-all-cusip9-in-kld-and-csrhub-data-1950-2018-age-variables.dta", ///
	keepusing(yr_start age) gen(m2)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        34,883
        from master                         3  (m2==1)
        from using                     34,880  (m2==2)

    matched                           114,191  (m2==3)
    -----------------------------------------
*/
drop if m2==2
drop m2

*	keep needed cstat variables
keep cusip ym conm tic datadate fyear fyr gvkey curcd apdedate fdate pdate ///
	revt ni sale at xad xrd emp dltt csho prcc_f ceq at mkvalt bkvlps ///
	gp unnp unnpl drc drlt dvrre lcoxdr loxdr nfsr revt ris urevub ///
	naics sic spcindcd spcseccd cstatvars in_cstat_kld_cusip in_cstat_csrhub_cusip ///
	loc fic age yr_start
	
*	Set panel
encode cusip, gen(cusip_n)
xtset cusip_n fyear, y
	
*	Generate variables
gen tobinq = (at + (csho * prcc_f) - ceq) / at
gen mkt2book = mkvalt / bkvlps

*	ROA
gen roa = ni / at

xtset
gen lroa = L.roa

*	Net income
xtset
gen lni = L.ni

*	Net income growth
gen ni_growth = ni - L.ni

*	Net income percent growth
gen nipct = ((ni - L.ni) / L.ni) * 100
	
*	Debt ratio
gen debt = dltt / at

*	R&D
gen rd = xrd / sale

*	Advertising
gen ad = xad / sale

*	Revenue growth
gen revg = revt - L.revt

*	Revenue percent growth
gen revpct = ((revt - L.revt) / L.revt) * 100

gsort -revpct
list conm cusip fyear revt revg revpct in 1/20
/*
     +-------------------------------------------------------------------------------+
     |                       conm       cusip   fyear      revt      revg     revpct |
     |-------------------------------------------------------------------------------|
  1. |           WYNN RESORTS LTD   983134107    2005   721.981   721.786   370146.7 |
  2. |    TELECORP PCS INC  -CL A   879300101    1999    87.682    87.653   302251.7 |
  3. |         STEEL DYNAMICS INC   858119100    1996   252.617    252.48     184292 |
  4. |  ALJ REGIONAL HOLDINGS INC   001627108    1997     6.439     6.435     160875 |
  5. |  HUGHES COMMUNICATIONS INC   444398101    2006   858.699   858.084   139525.9 |
     |-------------------------------------------------------------------------------|
  6. |           NMI HOLDINGS INC   629209305    2013     7.089     7.083     118050 |
  7. |                 SOLEXA INC   83420X105    2004     7.093     7.086   101228.6 |
  8. |        TG THERAPEUTICS INC   88322Q108    1998       2.5     2.497   83233.34 |
  9. | PACIFIC MERCANTILE BANCORP   694552100    1999     2.232     2.229      74300 |
 10. |        CLOVIS ONCOLOGY INC   189464100    2017    55.511    55.433   71067.95 |
     |-------------------------------------------------------------------------------|
 11. |         CANO PETROLEUM INC   137801106    2005     5.482     5.474      68425 |
 12. |            RING ENERGY INC   76680V108    2012     1.757     1.754   58466.67 |
 13. |     APPLIED ENERGETICS INC   03819M106    1993      2.91     2.905      58100 |
 14. |                 EGAIN CORP   28225C806    1999     1.019     1.017      50850 |
 15. |              DENDREON CORP   24823Q107    2010    48.057    47.956   47481.19 |
     |-------------------------------------------------------------------------------|
 16. |  PARATEK PHARMACEUTCLS INC   699374302    2017    12.616    12.587   43403.45 |
 17. |       ACACIA RESEARCH CORP   003881307    2001    24.636    24.579   43121.05 |
 18. |  GLADSTONE COMMERCIAL CORP   376536108    2004     4.927     4.915   40958.33 |
 19. |                   MPC CORP   553166109    2005   187.496   187.038   40837.99 |
 20. |  WESTPORT FUEL SYSTEMS INC   960908309    2001     31.37     31.29    39112.5 |
     +-------------------------------------------------------------------------------+
*/

*	Firm size
gen size = log(at)

*	Employees
replace emp=.209 if cusip=="P16994132" & fyear==2004 & emp==2545.209			/*	Firm did not have 2.5 million employees in this year	*/
replace emp=emp*1000

*	Label variables
foreach var of varlist * {
	local lab `: var label `var''
	label var `var' "(CSTAT) `lab'"
}

*	Generate standardized variables
foreach variable of varlist revt tobinq mkt2book roa lroa ni lni debt rd ad revg emp {
	egen z2`variable' = std(`variable')
	label var z2`variable' "(CSTAT) Standardized value of `variable'"
}

*	Save
label var roa "(CSTAT) Return on assets = ni / at"
label var tobinq "(CSTAT) Tobin's q = (at + (csho * prcc_f) - ceq) / at"
label var mkt2book "(CSTAT) Market to book ratio = mkvalt / bkvlps"
label var ym "(CSTAT) Fiscal year and end-of-fiscal-year month"
label var lroa "(CSTAT) Lagged roa, 1 year"
label var lni "(CSTAT) Lagged ni, 1 year"
label var ni_growth "(CSTAT) 
label var nipct "(CSTAT) Change in net income from previous year = ni - L.ni"
label var revpct "(CSTAT) Percent change in net income from previous year = ((ni - L.ni) / L.ni) * 100"
label var debt "(CSTAT) Debt ratio = dltt / at"
label var rd "(CSTAT) R&D intensity = xrd / sale"
label var ad "(CSTAT) Advertising intensity = xad / sale"
label var emp "(CSTAT) Number of employees"
label var size "(CSTAT) Firm size = logarithm of at"
label var revg "(CSTAT) Change in revenue from previous year = revt - L.revt"
label var revpct "(CSTAT) Percent change in revenue from previous year = ((revt - L.revt) / L.revt) * 100"

compress
save data/cstat-subset-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, replace


***===================================================================***
*	MERGE CSTAT data from CSRHUB and KLD with CSRHub data				*
***===================================================================***
***	
use data/csrhub-all.dta, clear
bysort cusip ym: gen N=_N
drop if N>1
*(111,062 observations deleted)
drop N firm_n
compress
save data/csrhub-all-unique-cusip-ym.dta, replace

use data/cstat-subset-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, clear
drop cusip_n

merge 1:1 cusip ym using data/csrhub-all-unique-cusip-ym.dta, update assert(1 2 3 4 5)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       923,911
        from master                    91,645  (_merge==1)
        from using                    832,266  (_merge==2)

    matched                            22,549
        not updated                    22,549  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/

*	Move cusip to cusip9; generate cusip8 to match with KLD only having cusip8
gen len=length(cusip)
tab _merge len
/*
                      |                     len
               _merge |         0          5          7          9 |     Total
----------------------+--------------------------------------------+----------
      master only (1) |         3          0          0     91,642 |    91,645 
       using only (2) |         0        318      1,614    830,334 |   832,266 
          matched (3) |         0          0          0     22,549 |    22,549 
----------------------+--------------------------------------------+----------
                Total |         3        318      1,614    944,525 |   946,460 
*/
keep if len==9
drop len

///	GENERATE 8-DIGIT CUSIP TO MATCH WITH KLD 8-DIGIT CUSIP
gen cusip9=cusip
label var cusip9 "(CSRHUB) CUSIP, 9-digit"
replace cusip=substr(cusip9,1,8)
bysort cusip ym: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    893,983       94.65       94.65
          2 |     25,460        2.70       97.34
          3 |      8,895        0.94       98.29
          4 |      8,016        0.85       99.13
          5 |      4,040        0.43       99.56
          6 |      1,452        0.15       99.72
          7 |        805        0.09       99.80
          8 |        600        0.06       99.87
          9 |        450        0.05       99.91
         10 |        300        0.03       99.94
         11 |        275        0.03       99.97
         12 |        132        0.01       99.99
         13 |        117        0.01      100.00
------------+-----------------------------------
      Total |    944,525      100.00
*/
drop if N>1
drop N ticker

*	Check months
tab month _merge
/*
  (CSRHub) |        _merge
Data Month | using onl  matched ( |     Total
-----------+----------------------+----------
         1 |    63,051        859 |    63,910 
         2 |    64,342        164 |    64,506 
         3 |    66,973        760 |    67,733 
         4 |    68,051        251 |    68,302 
         5 |    68,994        234 |    69,228 
         6 |    68,878      1,001 |    69,879 
         7 |    71,334        230 |    71,564 
         8 |    71,505        267 |    71,772 
         9 |    71,062      1,127 |    72,189 
        10 |    59,516        375 |    59,891 
        11 |    59,892        129 |    60,021 
        12 |    46,203     17,143 |    63,346 
-----------+----------------------+----------
     Total |   779,801     22,540 |   802,341 
*/
compress
save data/csrhub-with-cstat-from-csrhub-kld-cusips.dta, replace



***===================================================================***
*	MERGE CSTAT-CSRHUB data with KLD									*
***===================================================================***
use data/kld-all-clean.dta, clear
/*
foreach v of varlist * {
	rename `v' `v'kld
}
rename (cusipkld yearkld) (cusip year)
*/

*	Assume cusip constant within firms that ever have a cusip					/*	Assumption	*/
gen cusip_miss = (cusip=="")
gsort firm -cusip
by firm: replace cusip=cusip[_n-1] if cusip==""

*	Keep unique cusip year
bysort cusip year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     49,265       97.05       97.05
          2 |         60        0.12       97.17
          3 |         36        0.07       97.24
          4 |         24        0.05       97.29
          5 |         40        0.08       97.37
          6 |         12        0.02       97.39
          7 |         21        0.04       97.43
         16 |         16        0.03       97.46
         20 |         20        0.04       97.50
         50 |         50        0.10       97.60
         52 |         52        0.10       97.70
         69 |         69        0.14       97.84
         72 |         72        0.14       97.98
        113 |        113        0.22       98.20
        126 |        126        0.25       98.45
        131 |        131        0.26       98.71
        655 |        655        1.29      100.00
------------+-----------------------------------
      Total |     50,762      100.00
*/
list firm cusip year if N>1 & cusip!="", sepby(cusip year)
/*
       +---------------------------------------------------------------------------+
       |                                                    firm      cusip   year |
       |---------------------------------------------------------------------------|
45430. |                               ROCKVILLE FINANCIAL, INC.   91030410   2013 |
45431. |                          UNITED FINANCIAL BANCORP, INC.   91030410   2013 |
       |---------------------------------------------------------------------------|
49063. |                                              NEXTDC LTD   AU000000   2013 |
49064. |                              DRILLSEARCH ENERGY LIMITED   AU000000   2013 |
49065. |                           SILVER LAKE RESOURCES LIMITED   AU000000   2013 |
49066. |                                  PAPILLON RESOURCES LTD   AU000000   2013 |
49067. |                                   FLIGHT CENTRE LIMITED   AU000000   2013 |
49068. |                                          NUFARM LIMITED   AU000000   2013 |
49069. |                        MERMAID MARINE AUSTRALIA LIMITED   AU000000   2013 |
49070. |                                  PERSEUS MINING LIMITED   AU000000   2013 |
49071. |                                EVOLUTION MINING LIMITED   AU000000   2013 |
49072. |                                   SKILLED GROUP LIMITED   AU000000   2013 |
49073. |                                CHARTER HALL RETAIL REIT   AU000000   2013 |
49074. |                              FEDERATION CENTRES LIMITED   AU000000   2013 |
49075. |                                      CHARTER HALL GROUP   AU000000   2013 |
49076. |                                      DULUXGROUP LIMITED   AU000000   2013 |
49077. |                                      FLEXIGROUP LIMITED   AU000000   2013 |
49078. |                                   MEDUSA MINING LIMITED   AU000000   2013 |
49079. |                                               ACRUX LTD   AU000000   2013 |
49080. |                       AUTOMOTIVE HOLDINGS GROUP LIMITED   AU000000   2013 |
49081. |                                               GPT GROUP   AU000000   2013 |
49082. |                                              DUET GROUP   AU000000   2013 |
49083. |                                   WESTERN AREAS LIMITED   AU000000   2013 |
49084. |                        ECHO ENTERTAINMENT GROUP LIMITED   AU000000   2013 |
49085. |                                     HORIZON OIL LIMITED   AU000000   2013 |
49086. |                                        AUSDRILL LIMITED   AU000000   2013 |
49087. |                                   ABACUS PROPERTY GROUP   AU000000   2013 |
49088. |                            STW COMMUNICATIONS GROUP LTD   AU000000   2013 |
49089. |                                          CARDNO LIMITED   AU000000   2013 |
49090. |                                   TOLL HOLDINGS LIMITED   AU000000   2013 |
49091. |                                 GOODMAN GROUP PTY. LTD.   AU000000   2013 |
49092. |                                    NRW HOLDINGS LIMITED   AU000000   2013 |
49093. |                                 REGIS RESOURCES LIMITED   AU000000   2013 |
49094. |                             PREMIER INVESTMENTS LIMITED   AU000000   2013 |
49095. |                                     OZ MINERALS LIMITED   AU000000   2013 |
49096. |                             MACQUARIE ATLAS ROADS GROUP   AU000000   2013 |
49097. |                                    MINERAL DEPOSITS LTD   AU000000   2013 |
49098. |                                             ALS LIMITED   AU000000   2013 |
49099. |                                             ASX LIMITED   AU000000   2013 |
49100. |                                   INDEPENDENCE GROUP NL   AU000000   2013 |
49101. |                                          CUDECO LIMITED   AU000000   2013 |
49102. |                                             UGL LIMITED   AU000000   2013 |
49103. |                                        TRANSURBAN GROUP   AU000000   2013 |
49104. |                                     STEADFAST GROUP LTD   AU000000   2013 |
49105. |                            TEN NETWORK HOLDINGS LIMITED   AU000000   2013 |
49106. |                                        INVOCARE LIMITED   AU000000   2013 |
49107. |                         SYDNEY AIRPORT HOLDINGS LIMITED   AU000000   2013 |
49108. |                                        DECMIL GROUP LTD   AU000000   2013 |
49109. |                                         BURU ENERGY LTD   AU000000   2013 |
49110. |                                            ARB CORP LTD   AU000000   2013 |
49111. |                                             AWE LIMITED   AU000000   2013 |
49112. |                       PLATINUM ASSET MANAGEMENT LIMITED   AU000000   2013 |
49113. |                                   SANDFIRE RESOURCES NL   AU000000   2013 |
49114. |                              ARISTOCRAT LEISURE LIMITED   AU000000   2013 |
49115. |                                     INVESTA OFFICE FUND   AU000000   2013 |
49116. |                                               APA GROUP   AU000000   2013 |
49117. |                                 GOODMAN FIELDER LIMITED   AU000000   2013 |
49118. |                                       PERPETUAL LIMITED   AU000000   2013 |
49119. |                               STOCKLAND CORPORATION LTD   AU000000   2013 |
49120. |      SHOPPING CENTRES AUSTRALASIA PROPERTY GROUP RE LTD   AU000000   2013 |
49121. |                                               BWP TRUST   AU000000   2013 |
49122. |                                       RIO TINTO LIMITED   AU000000   2013 |
49123. |                          SOUTHERN CROSS MEDIA GROUP LTD   AU000000   2013 |
49124. |                               AUSTRALAND PROPERTY GROUP   AU000000   2013 |
49125. |                                    DEXUS PROPERTY GROUP   AU000000   2013 |
49126. |                                 THE REJECT SHOP LIMITED   AU000000   2013 |
49127. |                                       GRAINCORP LIMITED   AU000000   2013 |
49128. |                                   BEADELL RESOURCES LTD   AU000000   2013 |
49129. |                                       RCR TOMLINSON LTD   AU000000   2013 |
49130. |                                            MIRVAC GROUP   AU000000   2013 |
49131. |                         M2 TELECOMMUNICATIONS GROUP LTD   AU000000   2013 |
       |---------------------------------------------------------------------------|
49132. |                                     HORIZON OIL LIMITED   AU000000   2014 |
49133. |                        ECHO ENTERTAINMENT GROUP LIMITED   AU000000   2014 |
49134. |                                             AWE LIMITED   AU000000   2014 |
49135. |                                 GOODMAN GROUP PTY. LTD.   AU000000   2014 |
49136. |                                   ABACUS PROPERTY GROUP   AU000000   2014 |
49137. |                                    DEXUS PROPERTY GROUP   AU000000   2014 |
49138. |                                               APA GROUP   AU000000   2014 |
49139. |                                   WESTERN AREAS LIMITED   AU000000   2014 |
49140. |                                      FLEXIGROUP LIMITED   AU000000   2014 |
49141. |                                        INVOCARE LIMITED   AU000000   2014 |
49142. |                                     INVESTA OFFICE FUND   AU000000   2014 |
49143. |                                   TOLL HOLDINGS LIMITED   AU000000   2014 |
49144. |                                 GOODMAN FIELDER LIMITED   AU000000   2014 |
49145. |                                             UGL LIMITED   AU000000   2014 |
49146. |                              FEDERATION CENTRES LIMITED   AU000000   2014 |
49147. |                                             ASX LIMITED   AU000000   2014 |
49148. |                                        DECMIL GROUP LTD   AU000000   2014 |
49149. |                                            MIRVAC GROUP   AU000000   2014 |
49150. |                              DRILLSEARCH ENERGY LIMITED   AU000000   2014 |
49151. |                                     STEADFAST GROUP LTD   AU000000   2014 |
49152. |                                      CHARTER HALL GROUP   AU000000   2014 |
49153. |                                EVOLUTION MINING LIMITED   AU000000   2014 |
49154. |                                            ARB CORP LTD   AU000000   2014 |
49155. |                             PREMIER INVESTMENTS LIMITED   AU000000   2014 |
49156. |                                          CARDNO LIMITED   AU000000   2014 |
49157. |                               STOCKLAND CORPORATION LTD   AU000000   2014 |
49158. |                         SYDNEY AIRPORT HOLDINGS LIMITED   AU000000   2014 |
49159. |                            TEN NETWORK HOLDINGS LIMITED   AU000000   2014 |
49160. |                                       RIO TINTO LIMITED   AU000000   2014 |
49161. |                                     OZ MINERALS LIMITED   AU000000   2014 |
49162. |                              ARISTOCRAT LEISURE LIMITED   AU000000   2014 |
49163. |                                               BWP TRUST   AU000000   2014 |
49164. |                                              DUET GROUP   AU000000   2014 |
49165. |                                             ALS LIMITED   AU000000   2014 |
49166. |                       AUTOMOTIVE HOLDINGS GROUP LIMITED   AU000000   2014 |
49167. |                                 REGIS RESOURCES LIMITED   AU000000   2014 |
49168. |                                          CUDECO LIMITED   AU000000   2014 |
49169. |                            STW COMMUNICATIONS GROUP LTD   AU000000   2014 |
49170. |                             MACQUARIE ATLAS ROADS GROUP   AU000000   2014 |
49171. |                                       RCR TOMLINSON LTD   AU000000   2014 |
49172. |                                   SKILLED GROUP LIMITED   AU000000   2014 |
49173. |                                   SANDFIRE RESOURCES NL   AU000000   2014 |
49174. |                                       GRAINCORP LIMITED   AU000000   2014 |
49175. |                                          NUFARM LIMITED   AU000000   2014 |
49176. |                                CHARTER HALL RETAIL REIT   AU000000   2014 |
49177. |                                       PERPETUAL LIMITED   AU000000   2014 |
49178. |                                      DULUXGROUP LIMITED   AU000000   2014 |
49179. |                                   INDEPENDENCE GROUP NL   AU000000   2014 |
49180. |                                        TRANSURBAN GROUP   AU000000   2014 |
49181. |                                               GPT GROUP   AU000000   2014 |
       |---------------------------------------------------------------------------|
49371. |                                      AGUAS ANDINAS S.A.   CL000000   2013 |
49372. |                                      EMPRESAS CMPC S.A.   CL000000   2013 |
       |---------------------------------------------------------------------------|
49373. |                                      AGUAS ANDINAS S.A.   CL000000   2014 |
49374. |                                      EMPRESAS CMPC S.A.   CL000000   2014 |
       |---------------------------------------------------------------------------|
49377. |             YANTAI CHANGYU PIONEER WINE COMPANY LIMITED   CNE00000   2013 |
49378. |            CHONGQING CHANGAN AUTOMOBILE COMPANY LIMITED   CNE00000   2013 |
       |---------------------------------------------------------------------------|
49379. |                   NEW CHINA LIFE INSURANCE COMPANY LTD.   CNE10000   2013 |
49380. | THE PEOPLE'S INSURANCE COMPANY (GROUP) OF CHINA LIMITED   CNE10000   2013 |
49381. |                                 CSR CORPORATION LIMITED   CNE10000   2013 |
49382. |                        SINOPEC ENGINEERING GROUP CO LTD   CNE10000   2013 |
49383. |                   CHINA CINDA ASSET MANAGEMENT CO., LTD   CNE10000   2013 |
49384. |                              PETROCHINA COMPANY LIMITED   CNE10000   2013 |
       |---------------------------------------------------------------------------|
49385. |                   NEW CHINA LIFE INSURANCE COMPANY LTD.   CNE10000   2014 |
49386. |                   CHINA CINDA ASSET MANAGEMENT CO., LTD   CNE10000   2014 |
49387. |                                 CSR CORPORATION LIMITED   CNE10000   2014 |
49388. |                        SINOPEC ENGINEERING GROUP CO LTD   CNE10000   2014 |
49389. |                              PETROCHINA COMPANY LIMITED   CNE10000   2014 |
       |---------------------------------------------------------------------------|
49417. |                               TELEVISION FRANCAISE 1 SA   FR000005   2013 |
49418. |                      ETABLISSEMENTS MAUREL ET PROM S.A.   FR000005   2013 |
       |---------------------------------------------------------------------------|
49420. |                                          KLEPIERRE S.A.   FR000012   2013 |
49421. |                                                TOTAL SA   FR000012   2013 |
49422. |                                              EURAZEO SA   FR000012   2013 |
49423. |                                             WENDEL S.A.   FR000012   2013 |
49424. |                                                SEB S.A.   FR000012   2013 |
       |---------------------------------------------------------------------------|
49425. |                                             WENDEL S.A.   FR000012   2014 |
49426. |                                                SEB S.A.   FR000012   2014 |
49427. |                                                TOTAL SA   FR000012   2014 |
49428. |                                          KLEPIERRE S.A.   FR000012   2014 |
       |---------------------------------------------------------------------------|
50413. |                                              CORIO N.V.   NL000028   2013 |
50414. |                            EUROCOMMERCIAL PROPERTIES NV   NL000028   2013 |
50415. |                                         WERELDHAVE N.V.   NL000028   2013 |
       |---------------------------------------------------------------------------|
50416. |                                         WERELDHAVE N.V.   NL000028   2014 |
50417. |                            EUROCOMMERCIAL PROPERTIES NV   NL000028   2014 |
50418. |                                              CORIO N.V.   NL000028   2014 |
       |---------------------------------------------------------------------------|
50485. |                                                 PEAB AB   SE000010   2013 |
50486. |                             AKTIEBOLAGET INDUSTRIVARDEN   SE000010   2013 |
50487. |                                L E LUNDBERGFORETAGEN AB   SE000010   2013 |
       |---------------------------------------------------------------------------|
50488. |                                                 PEAB AB   SE000010   2014 |
50489. |                             AKTIEBOLAGET INDUSTRIVARDEN   SE000010   2014 |
       |---------------------------------------------------------------------------|
50490. |                                   INVESTMENT AB ORESUND   SE000011   2013 |
50491. |                                           TRELLEBORG AB   SE000011   2013 |
50492. |                                          NCC AKTIEBOLAG   SE000011   2013 |
50493. |                                                RATOS AB   SE000011   2013 |
50494. |                                                 SAAB AB   SE000011   2013 |
       |---------------------------------------------------------------------------|
50495. |                                   INVESTMENT AB ORESUND   SE000011   2014 |
50496. |                                          NCC AKTIEBOLAG   SE000011   2014 |
50497. |                                                RATOS AB   SE000011   2014 |
50498. |                                           TRELLEBORG AB   SE000011   2014 |
       |---------------------------------------------------------------------------|
50501. |                                         HUFVUDSTADEN AB   SE000017   2013 |
50502. |                                  AVANZA BANK HOLDING AB   SE000017   2013 |
       |---------------------------------------------------------------------------|
50503. |                                  AVANZA BANK HOLDING AB   SE000017   2014 |
50504. |                                         HUFVUDSTADEN AB   SE000017   2014 |
       |---------------------------------------------------------------------------|
50540. |                            FORMOSA PLASTICS CORPORATION   TW000130   2013 |
50541. |                             NAN YA PLASTICS CORPORATION   TW000130   2013 |
       |---------------------------------------------------------------------------|
50542. |                            FORMOSA PLASTICS CORPORATION   TW000130   2014 |
50543. |                             NAN YA PLASTICS CORPORATION   TW000130   2014 |
       |---------------------------------------------------------------------------|
50554. |                              ETERNAL CHEMICAL CO., LTD.   TW000171   2013 |
50555. |                          ORIENTAL UNION CHEMICAL CORP.,   TW000171   2013 |
       |---------------------------------------------------------------------------|
50567. |                                        TSRC CORPORATION   TW000210   2013 |
50568. |                         NANKANG RUBBER TIRE CORP., LTD.   TW000210   2013 |
50569. |                       CHENG SHIN RUBBER IND., CO., LTD.   TW000210   2013 |
       |---------------------------------------------------------------------------|
50570. |                       CHENG SHIN RUBBER IND., CO., LTD.   TW000210   2014 |
50571. |                         NANKANG RUBBER TIRE CORP., LTD.   TW000210   2014 |
50572. |                                        TSRC CORPORATION   TW000210   2014 |
       |---------------------------------------------------------------------------|
50573. |                                 CHINA MOTOR CORPORATION   TW000220   2013 |
50574. |                                     YULON MOTOR CO.,LTD   TW000220   2013 |
50575. |                                    HOTAI MOTOR CO.,LTD.   TW000220   2013 |
       |---------------------------------------------------------------------------|
50576. |                                 CHINA MOTOR CORPORATION   TW000220   2014 |
50577. |                                    HOTAI MOTOR CO.,LTD.   TW000220   2014 |
       |---------------------------------------------------------------------------|
50578. |                                    INVENTEC CORPORATION   TW000235   2013 |
50579. |                             FOXCONN TECHNOLOGY CO., LTD   TW000235   2013 |
       |---------------------------------------------------------------------------|
50580. |                             FOXCONN TECHNOLOGY CO., LTD   TW000235   2014 |
50581. |                                    INVENTEC CORPORATION   TW000235   2014 |
       |---------------------------------------------------------------------------|
50585. |                  CHENG UEI PRECISION INDUSTRY CO., LTD.   TW000239   2013 |
50586. |                                     ADVANTECH CO., LTD.   TW000239   2013 |
       |---------------------------------------------------------------------------|
50587. |                  CHENG UEI PRECISION INDUSTRY CO., LTD.   TW000239   2014 |
50588. |                                     ADVANTECH CO., LTD.   TW000239   2014 |
       |---------------------------------------------------------------------------|
50589. |                             TRANSCEND INFORMATION, INC.   TW000245   2013 |
50590. |                                           MEDIATEK INC.   TW000245   2013 |
       |---------------------------------------------------------------------------|
50591. |                             TRANSCEND INFORMATION, INC.   TW000245   2014 |
50592. |                                           MEDIATEK INC.   TW000245   2014 |
       |---------------------------------------------------------------------------|
50597. |                                 EVA AIRWAYS CORPORATION   TW000261   2013 |
50598. |                                      WAN HAI LINES LTD.   TW000261   2013 |
50599. |                                     CHINA AIRLINES LTD.   TW000261   2013 |
       |---------------------------------------------------------------------------|
50600. |                                     CHINA AIRLINES LTD.   TW000261   2014 |
50601. |                                 EVA AIRWAYS CORPORATION   TW000261   2014 |
50602. |                                      WAN HAI LINES LTD.   TW000261   2014 |
       |---------------------------------------------------------------------------|
50611. |                      YUANTA FINANCIAL HOLDINGS CO., LTD   TW000288   2013 |
50612. |                     HUA NAN FINANCIAL HOLDINGS CO.,LTD.   TW000288   2013 |
50613. |                        MEGA FINANCIAL HOLDING CO., LTD.   TW000288   2013 |
50614. |               CHINA DEVELOPMENT FINANCIAL HOLDING CORP.   TW000288   2013 |
50615. |                     TAISHIN FINANCIAL HOLDING CO., LTD.   TW000288   2013 |
       |---------------------------------------------------------------------------|
50616. |                     TAISHIN FINANCIAL HOLDING CO., LTD.   TW000288   2014 |
50617. |                      YUANTA FINANCIAL HOLDINGS CO., LTD   TW000288   2014 |
50618. |               CHINA DEVELOPMENT FINANCIAL HOLDING CORP.   TW000288   2014 |
       |---------------------------------------------------------------------------|
50623. |                              RUENTEX INDUSTRIES LIMITED   TW000291   2013 |
50624. |                       PRESIDENT CHAIN STORE CORPORATION   TW000291   2013 |
       |---------------------------------------------------------------------------|
50625. |                       PRESIDENT CHAIN STORE CORPORATION   TW000291   2014 |
50626. |                              RUENTEX INDUSTRIES LIMITED   TW000291   2014 |
       |---------------------------------------------------------------------------|
50629. |                          NOVATEK MICROELECTRONICS CORP.   TW000303   2013 |
50630. |                              UNIMICRON TECHNOLOGY CORP.   TW000303   2013 |
       |---------------------------------------------------------------------------|
50631. |                              UNIMICRON TECHNOLOGY CORP.   TW000303   2014 |
50632. |                          NOVATEK MICROELECTRONICS CORP.   TW000303   2014 |
       |---------------------------------------------------------------------------|
50633. |                                 TAIWAN MOBILE CO., LTD.   TW000304   2013 |
50634. |                           TRIPOD TECHNOLOGY CORPORATION   TW000304   2013 |
       |---------------------------------------------------------------------------|
50704. |                             PICK N PAY HOLDINGS LIMITED   ZAE00000   2013 |
50705. |                 HOSKEN CONSOLIDATED INVESTMENTS LIMITED   ZAE00000   2013 |
50706. |                                  OMNIA HOLDINGS LIMITED   ZAE00000   2013 |
50707. |                                   HUDACO INDUSTRIES LTD   ZAE00000   2013 |
50708. |                                 ADCORP HOLDINGS LIMITED   ZAE00000   2013 |
       |---------------------------------------------------------------------------|
50709. |                 HOSKEN CONSOLIDATED INVESTMENTS LIMITED   ZAE00000   2014 |
50710. |                                   HUDACO INDUSTRIES LTD   ZAE00000   2014 |
50711. |                                  OMNIA HOLDINGS LIMITED   ZAE00000   2014 |
50712. |                                 ADCORP HOLDINGS LIMITED   ZAE00000   2014 |
50713. |                             PICK N PAY HOLDINGS LIMITED   ZAE00000   2014 |
       |---------------------------------------------------------------------------|
50714. |                               SHOPRITE HOLDINGS LIMITED   ZAE00001   2013 |
50715. |                                     SYCOM PROPERTY FUND   ZAE00001   2013 |
       |---------------------------------------------------------------------------|
50717. |                                      GROUP FIVE LIMITED   ZAE00002   2013 |
50718. |                                    SPUR CORPORATION LTD   ZAE00002   2013 |
50719. |                                    INVICTA HOLDINGS LTD   ZAE00002   2013 |
       |---------------------------------------------------------------------------|
50720. |                                    SPUR CORPORATION LTD   ZAE00002   2014 |
50721. |                                    INVICTA HOLDINGS LTD   ZAE00002   2014 |
50722. |                                      GROUP FIVE LIMITED   ZAE00002   2014 |
       |---------------------------------------------------------------------------|
50729. |                              METAIR INVESTMENTS LIMITED   ZAE00009   2013 |
50730. |                                  TONGAAT HULETT LIMITED   ZAE00009   2013 |
50731. |              FOUNTAINHEAD PROPERTY TRUST MANAGEMENT LTD   ZAE00009   2013 |
50732. |                                        RAUBEX GROUP LTD   ZAE00009   2013 |
       |---------------------------------------------------------------------------|
50733. |              FOUNTAINHEAD PROPERTY TRUST MANAGEMENT LTD   ZAE00009   2014 |
50734. |                                  TONGAAT HULETT LIMITED   ZAE00009   2014 |
50735. |                                        RAUBEX GROUP LTD   ZAE00009   2014 |
50736. |                              METAIR INVESTMENTS LIMITED   ZAE00009   2014 |
       |---------------------------------------------------------------------------|
50739. |                          STEFANUTTI STOCKS HOLDINGS LTD   ZAE00012   2013 |
50740. |                              ADCOCK INGRAM HOLDINGS LTD   ZAE00012   2013 |
       |---------------------------------------------------------------------------|
50742. |                                               MPACT LTD   ZAE00015   2013 |
50743. |                    RAND MERCHANT INSURANCE HOLDINGS LTD   ZAE00015   2013 |
       |---------------------------------------------------------------------------|
50744. |                                               MPACT LTD   ZAE00015   2014 |
50745. |                    RAND MERCHANT INSURANCE HOLDINGS LTD   ZAE00015   2014 |
       |---------------------------------------------------------------------------|
50748. |                    PINNACLE TECHNOLOGY HOLDINGS LIMITED   ZAE00018   2013 |
50749. |                            VUKILE PROPERTY FUND LIMITED   ZAE00018   2013 |
       |---------------------------------------------------------------------------|
50751. |                  RESILIENT PROPERTY INCOME FUND LIMITED   ZAE00019   2013 |
50752. |                            FORTRESS INCOME FUND LIMITED   ZAE00019   2013 |
       |---------------------------------------------------------------------------|
50753. |                            FORTRESS INCOME FUND LIMITED   ZAE00019   2014 |
50754. |                  RESILIENT PROPERTY INCOME FUND LIMITED   ZAE00019   2014 |
       |---------------------------------------------------------------------------|
50755. |                                ARROWHEAD PROPERTIES LTD   ZAE00020   2013 |
50756. |                               REBOSIS PROPERTY FUND LTD   ZAE00020   2013 |
50757. |                                     EMIRA PROPERTY FUND   ZAE00020   2013 |
50758. |                           SA CORPORATE REAL ESTATE FUND   ZAE00020   2013 |
       |---------------------------------------------------------------------------|
50759. |                                ARROWHEAD PROPERTIES LTD   ZAE00020   2014 |
50760. |                               REBOSIS PROPERTY FUND LTD   ZAE00020   2014 |
50761. |                                     EMIRA PROPERTY FUND   ZAE00020   2014 |
       +---------------------------------------------------------------------------+
*/
drop if N>1
*(1,497 observations deleted)
drop firm N firm_n entity_type stnd_firm

merge 1:m cusip year using data/csrhub-with-cstat-from-csrhub-kld-cusips.dta, update assert(1 2 3 4 5) gen(_merge3)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       770,714
        from master                    34,559  (_merge3==1)
        from using                    736,155  (_merge3==2)

    matched                           157,828
        not updated                   157,828  (_merge3==3)
        missing updated                     0  (_merge3==4)
        nonmissing conflict                 0  (_merge3==5)
    -----------------------------------------
*/
gen ch=(fyr==month & fyr!=. & month!=.)

* Change non-matching ym to missing for KLD data
foreach variable of varlist year ticker cusip companyid env_str_a env_str_b env_str_c env_str_d env_str_f env_str_x env_con_a env_con_b env_con_c env_con_d env_con_e env_con_x com_str_a com_str_b com_str_c com_str_x com_con_a com_con_b com_con_d com_con_x hum_con_a hum_con_b emp_str_a emp_str_b emp_str_c emp_str_d emp_str_f emp_str_x emp_con_a emp_con_b emp_con_c emp_con_x div_str_a div_str_b div_str_c div_str_d div_str_e div_str_f div_str_x div_con_a div_con_x pro_str_a pro_str_b pro_str_c pro_str_x pro_con_a pro_con_d pro_con_e pro_con_x cgov_str_a cgov_str_c cgov_str_x cgov_con_b cgov_con_f alc_con_a gam_con_a mil_con_a mil_con_b mil_con_c mil_con_x nuc_con_a nuc_con_c nuc_con_d nuc_con_x tob_con_a emp_con_d cgov_con_x div_con_b com_str_d com_str_f hum_str_a hum_str_x hum_con_c hum_con_d hum_con_x div_str_g cgov_str_d alc_con_x gam_con_x hum_con_f fir_con_a tob_con_x env_con_f hum_str_d hum_con_g hum_str_g emp_str_g com_str_g cgov_str_e cgov_con_g cgov_con_h cgov_con_i env_str_g cgov_str_f cgov_con_j env_con_g env_con_h env_con_i com_str_h hum_con_h emp_str_h emp_con_f div_str_h div_con_c pro_str_d cgov_con_k env_str_h env_str_i env_str_j env_con_j env_con_k hum_con_j hum_con_k emp_str_i emp_str_j emp_str_k emp_str_l emp_con_g div_con_d pro_con_f cgov_str_g cgov_str_h cgov_con_l cgov_con_m env_str_k env_str_l env_str_m env_str_n env_str_o env_str_p env_str_q emp_str_n pro_str_e pro_str_f pro_str_g pro_str_h pro_str_i pro_str_j pro_str_k pro_con_g row_id_kld sum_alc_con sum_cgov_con sum_cgov_str sum_com_con sum_com_str sum_div_con sum_div_str sum_emp_con sum_emp_str sum_env_con sum_env_str sum_gam_con sum_hum_con sum_hum_str sum_mil_con sum_nuc_con sum_pro_con sum_pro_str sum_tob_con cgov_agg com_agg div_agg emp_agg env_agg hum_agg pro_agg alc_agg gam_agg mil_agg nuc_agg tob_agg net_kld_str net_kld_con net_kld firm_kld {
	capt n replace `variable'=. if ch==0 & _merge3==3
	capt n replace `variable'="" if ch==0 & _merge3==3
}

drop stnd_firm

encode cusip9, gen(cusip_n)
bysort cusip_n ym: gen N=_N
drop if N>1
*(34,559 observations deleted)
xtset cusip_n ym, m

order firm_kld firm_csrhub conm cusip ym

rename conm firm_cstat

drop _merge ch N



///	CREATE NEW VARIABLES
*** Create de-meaned and mean variables for random effects within-between modeling
foreach variable in net_kld_str net_kld_con over_rtg emp debt rd ad size {
	bysort cusip_n: egen `variable'_m = mean(`variable')
	replace `variable'_m = . if over_rtg==.
	label var `variable'_m "CUSIP-level mean of `variable'"
	bysort cusip_n: gen `variable'_dm = `variable' - `variable'_m
	replace `variable'_dm = . if over_rtg==.
	label var `variable'_dm "CUSIP-level de-meaned `variable'"
}

///	Save CUSIP-yearmonth level data
compress
label data "CUSIP-yearmonth level CSRHub-CSTAT-KLD dataset"
save data/csrhub-kld-cstat-month-level.dta, replace











*END
