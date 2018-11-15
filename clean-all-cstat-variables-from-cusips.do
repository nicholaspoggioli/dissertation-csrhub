***	CLEANING ALL COMPUSTAT FUNDAMENTALS ANNUAL VARIABLES FOR ALL CUSIPS

***===============================================***
*		CSTAT data using CSRHub CUSIPs				*
***===============================================***
***	File size reduction
use data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, clear

*	clean
order conm cusip tic datadate fyear fyr

*	save
compress
save data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, replace


***=======================================***
*		CSTAT data using KLD CUSIPs			*
***=======================================***
***	File size reduction
use data/cstat-all-variables-for-all-cusip9-in-kld-data-1990-2018.dta, clear

order conm cusip tic datadate fyear fyr

gen ym=ym(year(datadate),month(datadate))

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

compress
save data/cstat-all-variables-for-all-cusip9-in-kld-data-1990-2018.dta, replace


***===============================================***
*	MERGE CSTAT data from CSRHUB and KLD CUSIPs		*
***===============================================***
use data/cstat-all-variables-for-all-cusip9-in-kld-data-1990-2018.dta, clear

bysort cusip ym: gen N=_N
tab N
keep if N==1
drop N

merge 1:1 cusip ym using data/cstat-all-variables-for-all-cusip9-in-csrhub-data-1990-2018.dta, gen(cstatvars) update assert(1 2 3 4 5)
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

save data/cstat-all-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, replace

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
	naics sic spcindcd spcseccd
	
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
label var revt_growth

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
drop N _merge ticker

*	Check months
tab month _merge
/*
  (CSRHub) |        _merge
Data Month | using onl  matched ( |     Total
-----------+----------------------+----------
         1 |    67,101        859 |    67,960 
         2 |    68,471        164 |    68,635 
         3 |    71,345        760 |    72,105 
         4 |    72,482        251 |    72,733 
         5 |    73,525        234 |    73,759 
         6 |    73,479      1,002 |    74,481 
         7 |    76,175        230 |    76,405 
         8 |    76,396        267 |    76,663 
         9 |    76,048      1,127 |    77,175 
        10 |    63,334        375 |    63,709 
        11 |    63,712        136 |    63,848 
        12 |    50,198     17,144 |    67,342 
-----------+----------------------+----------
     Total |   832,266     22,549 |   854,815 
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
drop firm

drop N firm_n entity_type month year stnd_firm

merge 1:1 cusip ym using data/csrhub-with-cstat-from-csrhub-kld-cusips.dta, update assert(1 2 3 4 5) gen(_merge3)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       881,723
        from master                    16,264  (_merge3==1)
        from using                    865,459  (_merge3==2)

    matched                            28,524
        not updated                    28,524  (_merge3==3)
        missing updated                     0  (_merge3==4)
        nonmissing conflict                 0  (_merge3==5)
    -----------------------------------------
*/

drop stnd_firm _merge3

encode cusip, gen(cusip_n)
bysort cusip_n ym: gen N=_N
tab N
xtset cusip_n ym, m

order firm_kld firm_csrhub cusip ym

compress
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
