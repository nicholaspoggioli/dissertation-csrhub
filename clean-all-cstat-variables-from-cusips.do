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
label var in_cstat_csrhub_cusip "(CSTAT) =1 if in CSTAT data created from unique CSRHub CUSIPs"

*	save
compress
save data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018-clean.dta, replace


***===============================================***
*		Clean CSTAT data from KLD CUSIPs			*
***===============================================***
use data/cstat-all-variables-for-all-cusip9-in-kld-data-1990-2018.dta, clear

*	generate ym variable
gen ym=ym(year(datadate),month(datadate))
label var ym "(CSTAT) Year-month = datadate year and datadate month"

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
label var in_cstat_kld_cusip "(CSTAT) =1 if in CSTAT data created from unique KLD CUSIPs"

compress
save data/cstat-all-variables-for-all-cusip9-in-kld-data-1990-2018-clean.dta, replace


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

label var cstatvars "(CSTAT) Merge indicator for CSTAT data of KLD CUSIPs to CSRHub CUSIPs"

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

keep cusip ym conm tic datadate fyear fyr gvkey curcd apdedate fdate pdate ///
	revt ni sale at xad xrd emp dltt csho prcc_f ceq at mkvalt bkvlps ///
	gp unnp unnpl drc drlt dvrre lcoxdr loxdr nfsr revt ris urevub ///
	naics sic spcindcd spcseccd cstatvars
	
*	Generate variables
gen tobinq = (at + (csho * prcc_f) - ceq) / at
gen mkt2book = mkvalt / bkvlps

*	ROA
gen roa = ni / at

sort cusip ym
by cusip: gen lroa=roa[_n-1]

*	Net income
sort cusip ym
by cusip: gen lni=ni[_n-1]
	
*	Debt ratio
gen debt = dltt / at

*	R&D
gen rd = xrd / sale

*	Advertising
gen ad = xad / sale

foreach var of varlist * {
	local lab `: var label `var''
	label var `var' "(CSTAT) `lab'"
}

*	Firm size
gen size = log(at)

*	Employees
replace emp=emp*1000

*	Set panel
encode cusip, gen(cusip_n)
xtset cusip_n ym, m

*	Revenue growth
gen revt_growth=revt-l12.revt

*	Save
label var roa "(CSTAT) Return on assets = ni / at"
label var tobinq "(CSTAT) Tobin's q = (at + (csho * prcc_f) - ceq) / at"
label var mkt2book "(CSTAT) Market to book ratio = mkvalt / bkvlps"
label var ym "(CSTAT) Fiscal year and end-of-fiscal-year month"
label var lroa "(CSTAT) Lagged roa, 1 year"
label var lni "(CSTAT) Lagged ni, 1 year"
label var debt "(CSTAT) Debt ratio = dltt / at"
label var rd "(CSTAT) R&D intensity = xrd / sale"
label var ad "(CSTAT) Advertising intensity = xad / sale"
label var emp "(CSTAT) Number of employees"
label var size "(CSTAT) Firm size = logarithm of AT"
label var revt_growth "(CSTAT) Change in revenue from previous year = revt - revt from 12 months prior"

compress
save data/cstat-subset-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, replace


***===================================================================***
*	MERGE CSTAT data from CSRHUB and KLD with CSRHub data		*
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
gen cusip9=cusip
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


***	Merge with KLD data
use data/kld-all-clean.dta, clear
/*
foreach v of varlist * {
	rename `v' `v'kld
}
rename (cusipkld yearkld) (cusip year)
*/

bysort cusip year: gen N=_N
tab N
/*

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     44,788       88.23       88.23
          2 |         34        0.07       88.30
          3 |         18        0.04       88.33
          4 |          8        0.02       88.35
          5 |         20        0.04       88.39
          6 |         12        0.02       88.41
          7 |         14        0.03       88.44
          8 |         24        0.05       88.49
         10 |         10        0.02       88.51
         63 |         63        0.12       88.63
         69 |         69        0.14       88.77
         77 |         77        0.15       88.92
        185 |        185        0.36       89.28
        643 |        643        1.27       90.55
        647 |        647        1.27       91.82
        651 |        651        1.28       93.11
        652 |        652        1.28       94.39
       2847 |      2,847        5.61      100.00
------------+-----------------------------------
      Total |     50,762      100.00
*/
list firm cusip year if N>1 & cusip!="", sepby(cusip year)
/*
       +---------------------------------------------------------------------------+
       |                                                    firm      cusip   year |
       |---------------------------------------------------------------------------|
49664. |                                    DEXUS PROPERTY GROUP   AU000000   2013 |
49665. |                                       RCR TOMLINSON LTD   AU000000   2013 |
49666. |                             PREMIER INVESTMENTS LIMITED   AU000000   2013 |
49667. |                                        AUSDRILL LIMITED   AU000000   2013 |
49668. |                              ARISTOCRAT LEISURE LIMITED   AU000000   2013 |
49669. |                                               BWP TRUST   AU000000   2013 |
49670. |                                          NUFARM LIMITED   AU000000   2013 |
49671. |                       PLATINUM ASSET MANAGEMENT LIMITED   AU000000   2013 |
49672. |                                        INVOCARE LIMITED   AU000000   2013 |
49673. |                                  PERSEUS MINING LIMITED   AU000000   2013 |
49674. |                        ECHO ENTERTAINMENT GROUP LIMITED   AU000000   2013 |
49675. |                                       PERPETUAL LIMITED   AU000000   2013 |
49676. |                              DRILLSEARCH ENERGY LIMITED   AU000000   2013 |
49677. |                                     INVESTA OFFICE FUND   AU000000   2013 |
49678. |                                      DULUXGROUP LIMITED   AU000000   2013 |
49679. |                                     STEADFAST GROUP LTD   AU000000   2013 |
49680. |                            STW COMMUNICATIONS GROUP LTD   AU000000   2013 |
49681. |      SHOPPING CENTRES AUSTRALASIA PROPERTY GROUP RE LTD   AU000000   2013 |
49682. |                                             UGL LIMITED   AU000000   2013 |
49683. |                                      FLEXIGROUP LIMITED   AU000000   2013 |
49684. |                                   MEDUSA MINING LIMITED   AU000000   2013 |
49685. |                           SILVER LAKE RESOURCES LIMITED   AU000000   2013 |
49686. |                                        DECMIL GROUP LTD   AU000000   2013 |
49687. |                          SOUTHERN CROSS MEDIA GROUP LTD   AU000000   2013 |
49688. |                                          CUDECO LIMITED   AU000000   2013 |
49689. |                                     HORIZON OIL LIMITED   AU000000   2013 |
49690. |                                   TOLL HOLDINGS LIMITED   AU000000   2013 |
49691. |                       AUTOMOTIVE HOLDINGS GROUP LIMITED   AU000000   2013 |
49692. |                                   FLIGHT CENTRE LIMITED   AU000000   2013 |
49693. |                            TEN NETWORK HOLDINGS LIMITED   AU000000   2013 |
49694. |                                  PAPILLON RESOURCES LTD   AU000000   2013 |
49695. |                                       GRAINCORP LIMITED   AU000000   2013 |
49696. |                                            MIRVAC GROUP   AU000000   2013 |
49697. |                               STOCKLAND CORPORATION LTD   AU000000   2013 |
49698. |                                              DUET GROUP   AU000000   2013 |
49699. |                             MACQUARIE ATLAS ROADS GROUP   AU000000   2013 |
49700. |                                              NEXTDC LTD   AU000000   2013 |
49701. |                                    NRW HOLDINGS LIMITED   AU000000   2013 |
49702. |                                 GOODMAN FIELDER LIMITED   AU000000   2013 |
49703. |                                      CHARTER HALL GROUP   AU000000   2013 |
49704. |                                         BURU ENERGY LTD   AU000000   2013 |
49705. |                                               APA GROUP   AU000000   2013 |
49706. |                                   ABACUS PROPERTY GROUP   AU000000   2013 |
49707. |                                               ACRUX LTD   AU000000   2013 |
49708. |                              FEDERATION CENTRES LIMITED   AU000000   2013 |
49709. |                                   INDEPENDENCE GROUP NL   AU000000   2013 |
49710. |                         M2 TELECOMMUNICATIONS GROUP LTD   AU000000   2013 |
49711. |                                 THE REJECT SHOP LIMITED   AU000000   2013 |
49712. |                         SYDNEY AIRPORT HOLDINGS LIMITED   AU000000   2013 |
49713. |                                             ASX LIMITED   AU000000   2013 |
49714. |                                               GPT GROUP   AU000000   2013 |
49715. |                                 GOODMAN GROUP PTY. LTD.   AU000000   2013 |
49716. |                                   SANDFIRE RESOURCES NL   AU000000   2013 |
49717. |                                       RIO TINTO LIMITED   AU000000   2013 |
49718. |                               AUSTRALAND PROPERTY GROUP   AU000000   2013 |
49719. |                                EVOLUTION MINING LIMITED   AU000000   2013 |
49720. |                                             AWE LIMITED   AU000000   2013 |
49721. |                                        TRANSURBAN GROUP   AU000000   2013 |
49722. |                                          CARDNO LIMITED   AU000000   2013 |
49723. |                                   BEADELL RESOURCES LTD   AU000000   2013 |
49724. |                                    MINERAL DEPOSITS LTD   AU000000   2013 |
49725. |                                   WESTERN AREAS LIMITED   AU000000   2013 |
49726. |                                            ARB CORP LTD   AU000000   2013 |
49727. |                                CHARTER HALL RETAIL REIT   AU000000   2013 |
49728. |                                 REGIS RESOURCES LIMITED   AU000000   2013 |
49729. |                                     OZ MINERALS LIMITED   AU000000   2013 |
49730. |                        MERMAID MARINE AUSTRALIA LIMITED   AU000000   2013 |
49731. |                                             ALS LIMITED   AU000000   2013 |
49732. |                                   SKILLED GROUP LIMITED   AU000000   2013 |
       |---------------------------------------------------------------------------|
49837. |                                      EMPRESAS CMPC S.A.   CL000000   2013 |
49838. |                                      AGUAS ANDINAS S.A.   CL000000   2013 |
       |---------------------------------------------------------------------------|
49840. |            CHONGQING CHANGAN AUTOMOBILE COMPANY LIMITED   CNE00000   2013 |
49841. |             YANTAI CHANGYU PIONEER WINE COMPANY LIMITED   CNE00000   2013 |
       |---------------------------------------------------------------------------|
49842. | THE PEOPLE'S INSURANCE COMPANY (GROUP) OF CHINA LIMITED   CNE10000   2013 |
49843. |                        SINOPEC ENGINEERING GROUP CO LTD   CNE10000   2013 |
49844. |                              PETROCHINA COMPANY LIMITED   CNE10000   2013 |
49845. |                                 CSR CORPORATION LIMITED   CNE10000   2013 |
49846. |                   CHINA CINDA ASSET MANAGEMENT CO., LTD   CNE10000   2013 |
49847. |                   NEW CHINA LIFE INSURANCE COMPANY LTD.   CNE10000   2013 |
       |---------------------------------------------------------------------------|
49864. |                               TELEVISION FRANCAISE 1 SA   FR000005   2013 |
49865. |                      ETABLISSEMENTS MAUREL ET PROM S.A.   FR000005   2013 |
       |---------------------------------------------------------------------------|
49866. |                                                SEB S.A.   FR000012   2013 |
49867. |                                             WENDEL S.A.   FR000012   2013 |
49868. |                                              EURAZEO SA   FR000012   2013 |
49869. |                                                TOTAL SA   FR000012   2013 |
49870. |                                          KLEPIERRE S.A.   FR000012   2013 |
       |---------------------------------------------------------------------------|
50549. |                                         WERELDHAVE N.V.   NL000028   2013 |
50550. |                                              CORIO N.V.   NL000028   2013 |
50551. |                            EUROCOMMERCIAL PROPERTIES NV   NL000028   2013 |
       |---------------------------------------------------------------------------|
50597. |                                L E LUNDBERGFORETAGEN AB   SE000010   2013 |
50598. |                                                 PEAB AB   SE000010   2013 |
50599. |                             AKTIEBOLAGET INDUSTRIVARDEN   SE000010   2013 |
       |---------------------------------------------------------------------------|
50600. |                                           TRELLEBORG AB   SE000011   2013 |
50601. |                                                 SAAB AB   SE000011   2013 |
50602. |                                          NCC AKTIEBOLAG   SE000011   2013 |
50603. |                                                RATOS AB   SE000011   2013 |
50604. |                                   INVESTMENT AB ORESUND   SE000011   2013 |
       |---------------------------------------------------------------------------|
50606. |                                  AVANZA BANK HOLDING AB   SE000017   2013 |
50607. |                                         HUFVUDSTADEN AB   SE000017   2013 |
       |---------------------------------------------------------------------------|
50627. |                            FORMOSA PLASTICS CORPORATION   TW000130   2013 |
50628. |                             NAN YA PLASTICS CORPORATION   TW000130   2013 |
       |---------------------------------------------------------------------------|
50634. |                              ETERNAL CHEMICAL CO., LTD.   TW000171   2013 |
50635. |                          ORIENTAL UNION CHEMICAL CORP.,   TW000171   2013 |
       |---------------------------------------------------------------------------|
50641. |                                        TSRC CORPORATION   TW000210   2013 |
50642. |                         NANKANG RUBBER TIRE CORP., LTD.   TW000210   2013 |
50643. |                       CHENG SHIN RUBBER IND., CO., LTD.   TW000210   2013 |
       |---------------------------------------------------------------------------|
50644. |                                 CHINA MOTOR CORPORATION   TW000220   2013 |
50645. |                                    HOTAI MOTOR CO.,LTD.   TW000220   2013 |
50646. |                                     YULON MOTOR CO.,LTD   TW000220   2013 |
       |---------------------------------------------------------------------------|
50647. |                             FOXCONN TECHNOLOGY CO., LTD   TW000235   2013 |
50648. |                                    INVENTEC CORPORATION   TW000235   2013 |
       |---------------------------------------------------------------------------|
50651. |                  CHENG UEI PRECISION INDUSTRY CO., LTD.   TW000239   2013 |
50652. |                                     ADVANTECH CO., LTD.   TW000239   2013 |
       |---------------------------------------------------------------------------|
50653. |                                           MEDIATEK INC.   TW000245   2013 |
50654. |                             TRANSCEND INFORMATION, INC.   TW000245   2013 |
       |---------------------------------------------------------------------------|
50657. |                                     CHINA AIRLINES LTD.   TW000261   2013 |
50658. |                                 EVA AIRWAYS CORPORATION   TW000261   2013 |
50659. |                                      WAN HAI LINES LTD.   TW000261   2013 |
       |---------------------------------------------------------------------------|
50664. |                     TAISHIN FINANCIAL HOLDING CO., LTD.   TW000288   2013 |
50665. |                      YUANTA FINANCIAL HOLDINGS CO., LTD   TW000288   2013 |
50666. |               CHINA DEVELOPMENT FINANCIAL HOLDING CORP.   TW000288   2013 |
50667. |                     HUA NAN FINANCIAL HOLDINGS CO.,LTD.   TW000288   2013 |
50668. |                        MEGA FINANCIAL HOLDING CO., LTD.   TW000288   2013 |
       |---------------------------------------------------------------------------|
50671. |                       PRESIDENT CHAIN STORE CORPORATION   TW000291   2013 |
50672. |                              RUENTEX INDUSTRIES LIMITED   TW000291   2013 |
       |---------------------------------------------------------------------------|
50674. |                          NOVATEK MICROELECTRONICS CORP.   TW000303   2013 |
50675. |                              UNIMICRON TECHNOLOGY CORP.   TW000303   2013 |
       |---------------------------------------------------------------------------|
50676. |                                 TAIWAN MOBILE CO., LTD.   TW000304   2013 |
50677. |                           TRIPOD TECHNOLOGY CORPORATION   TW000304   2013 |
       |---------------------------------------------------------------------------|
50731. |                                  OMNIA HOLDINGS LIMITED   ZAE00000   2013 |
50732. |                             PICK N PAY HOLDINGS LIMITED   ZAE00000   2013 |
50733. |                                   HUDACO INDUSTRIES LTD   ZAE00000   2013 |
50734. |                                 ADCORP HOLDINGS LIMITED   ZAE00000   2013 |
50735. |                 HOSKEN CONSOLIDATED INVESTMENTS LIMITED   ZAE00000   2013 |
       |---------------------------------------------------------------------------|
50736. |                               SHOPRITE HOLDINGS LIMITED   ZAE00001   2013 |
50737. |                                     SYCOM PROPERTY FUND   ZAE00001   2013 |
       |---------------------------------------------------------------------------|
50738. |                                      GROUP FIVE LIMITED   ZAE00002   2013 |
50739. |                                    SPUR CORPORATION LTD   ZAE00002   2013 |
50740. |                                    INVICTA HOLDINGS LTD   ZAE00002   2013 |
       |---------------------------------------------------------------------------|
50744. |              FOUNTAINHEAD PROPERTY TRUST MANAGEMENT LTD   ZAE00009   2013 |
50745. |                              METAIR INVESTMENTS LIMITED   ZAE00009   2013 |
50746. |                                        RAUBEX GROUP LTD   ZAE00009   2013 |
50747. |                                  TONGAAT HULETT LIMITED   ZAE00009   2013 |
       |---------------------------------------------------------------------------|
50749. |                              ADCOCK INGRAM HOLDINGS LTD   ZAE00012   2013 |
50750. |                          STEFANUTTI STOCKS HOLDINGS LTD   ZAE00012   2013 |
       |---------------------------------------------------------------------------|
50751. |                    RAND MERCHANT INSURANCE HOLDINGS LTD   ZAE00015   2013 |
50752. |                                               MPACT LTD   ZAE00015   2013 |
       |---------------------------------------------------------------------------|
50754. |                            VUKILE PROPERTY FUND LIMITED   ZAE00018   2013 |
50755. |                    PINNACLE TECHNOLOGY HOLDINGS LIMITED   ZAE00018   2013 |
       |---------------------------------------------------------------------------|
50756. |                  RESILIENT PROPERTY INCOME FUND LIMITED   ZAE00019   2013 |
50757. |                            FORTRESS INCOME FUND LIMITED   ZAE00019   2013 |
       |---------------------------------------------------------------------------|
50758. |                                     EMIRA PROPERTY FUND   ZAE00020   2013 |
50759. |                           SA CORPORATE REAL ESTATE FUND   ZAE00020   2013 |
50760. |                                ARROWHEAD PROPERTIES LTD   ZAE00020   2013 |
50761. |                               REBOSIS PROPERTY FUND LTD   ZAE00020   2013 |
       +---------------------------------------------------------------------------+
*/
drop if N>1
drop firm N firm_n entity_type stnd_firm

merge 1:m cusip year using data/csrhub-with-cstat-from-csrhub-kld-cusips.dta, update assert(1 2 3 4 5) gen(_merge3)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       770,485
        from master                    30,424  (_merge3==1)
        from using                    740,061  (_merge3==2)

    matched                           153,922
        not updated                   153,922  (_merge3==3)
        missing updated                     0  (_merge3==4)
        nonmissing conflict                 0  (_merge3==5)
    -----------------------------------------
*/
gen ch=(fyr==month & fyr!=. & month!=.)

foreach variable of varlist year ticker cusip companyid env_str_a env_str_b env_str_c env_str_d env_str_f env_str_x env_con_a env_con_b env_con_c env_con_d env_con_e env_con_x com_str_a com_str_b com_str_c com_str_x com_con_a com_con_b com_con_d com_con_x hum_con_a hum_con_b emp_str_a emp_str_b emp_str_c emp_str_d emp_str_f emp_str_x emp_con_a emp_con_b emp_con_c emp_con_x div_str_a div_str_b div_str_c div_str_d div_str_e div_str_f div_str_x div_con_a div_con_x pro_str_a pro_str_b pro_str_c pro_str_x pro_con_a pro_con_d pro_con_e pro_con_x cgov_str_a cgov_str_c cgov_str_x cgov_con_b cgov_con_f alc_con_a gam_con_a mil_con_a mil_con_b mil_con_c mil_con_x nuc_con_a nuc_con_c nuc_con_d nuc_con_x tob_con_a emp_con_d cgov_con_x div_con_b com_str_d com_str_f hum_str_a hum_str_x hum_con_c hum_con_d hum_con_x div_str_g cgov_str_d alc_con_x gam_con_x hum_con_f fir_con_a tob_con_x env_con_f hum_str_d hum_con_g hum_str_g emp_str_g com_str_g cgov_str_e cgov_con_g cgov_con_h cgov_con_i env_str_g cgov_str_f cgov_con_j env_con_g env_con_h env_con_i com_str_h hum_con_h emp_str_h emp_con_f div_str_h div_con_c pro_str_d cgov_con_k env_str_h env_str_i env_str_j env_con_j env_con_k hum_con_j hum_con_k emp_str_i emp_str_j emp_str_k emp_str_l emp_con_g div_con_d pro_con_f cgov_str_g cgov_str_h cgov_con_l cgov_con_m env_str_k env_str_l env_str_m env_str_n env_str_o env_str_p env_str_q emp_str_n pro_str_e pro_str_f pro_str_g pro_str_h pro_str_i pro_str_j pro_str_k pro_con_g row_id_kld sum_alc_con sum_cgov_con sum_cgov_str sum_com_con sum_com_str sum_div_con sum_div_str sum_emp_con sum_emp_str sum_env_con sum_env_str sum_gam_con sum_hum_con sum_hum_str sum_mil_con sum_nuc_con sum_pro_con sum_pro_str sum_tob_con cgov_agg com_agg div_agg emp_agg env_agg hum_agg pro_agg alc_agg gam_agg mil_agg nuc_agg tob_agg net_kld_str net_kld_con net_kld firm_kld {
	capt n replace `variable'=. if ch==0
	capt n replace `variable'="" if ch==0
}

drop stnd_firm

encode cusip, gen(cusip_n)
bysort cusip_n ym: gen N=_N
drop if N>1
xtset cusip_n ym, m

order firm_kld firm_csrhub conm cusip ym

rename conm firm_cstat

drop _merge ch N

compress
label data "CUSIPs from KLD and CSRHUB matched to CSTAT"
save data/csrhub-kld-cstat-matched-on-cusip.dta, replace













/*	EXPLORATORY DATA ANALYSIS

set scheme plotplainblind

gen logrev=log(revt)
replace net_kld_con=net_kld_con*-1
graph matrix revt logrev tobinq mkt2book over_rtg net_kld net_kld_str net_kld_con


binscatter logrev net_kld, nq(31) xlabel(-20(5)20) line(none) by(year) legend(off) ylabel(-4(2)14)
binscatter logrev net_kld, nq(31) xlabel(-20(5)20) line(none) by(year) legend(off) ylabel(-4(2)14) medians

binscatter revt net_kld, nq(31) xlabel(-20(5)20) line(none) by(year) legend(off) medians
*/












*END
