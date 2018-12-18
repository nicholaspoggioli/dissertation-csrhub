/*

***===============================***
*	CREATE YEAR LEVEL CSRHUB DATA	*
***===============================***
///	LOAD DATA
use data/csrhub-all.dta, clear

drop firm_n csrhub_cr

///	Keep unique cusip ym
bysort cusip ym: gen N=_N
drop if N>1
drop N

///	Set panel
encode cusip, gen(cusip_n)
xtset cusip_n ym

///	Create last month of year variable
gsort cusip -ym
by cusip: gen last_ob = (_n==1)
label var last_ob "(CSRHUB) =1 if last ym CUSIP appears in CSRHUB data"

gen right_censor = (ym==692)
label var right_censor "(CSRHUB) =1 if last ym for CUSIP is 2017m9, the last ym in data"

***	Genearate last month of year variable for each rating
foreach variable of varlist over_rtg board_rtg cmty_rtg com_dev_phl_rtg comp_ben_rtg ///
	div_lab_rtg emp_rtg enrgy_climchge_rtg enviro_pol_rpt_rtg enviro_rtg ///
	gov_rtg humrts_supchain_rtg industry_avg_rtg ldrship_ethics_rtg ///
	over_pct_rank prod_rtg resource_mgmt_rtg train_hlth_safe_rtg trans_report_rtg {

	capt drop var maxmth
	mark var
	markout var `variable'
	
	sort cusip year month
	
	markout var year month `variable'
	
	by cusip year: egen maxmth=max(month) if var==1

	gen `variable'_lym = `variable' if month==maxmth
	label var `variable'_lym "(CSRHUB) Last ym of `variable' for each year"
}
drop var maxmth


///	Collapse to year level
foreach variable of varlist *rtg {
	gen `variable'_mean = `variable'
	gen `variable'_med = `variable'
}

collapse (max) *lym (mean) *_mean (median) *_med, by(cusip year firm isin)

order *, alpha
order cusip year firm

///	Drop duplicate cusip years
bysort cusip year: gen N=_N
tab N
/*          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     84,012       99.98       99.98
          2 |         20        0.02      100.00
------------+-----------------------------------
      Total |     84,032      100.00
*/
drop if N>1
drop N

///	Create 8 digit CUSIPS for merge with KLD
gen cusip9 = cusip
label var cusip9 "(CSRHub) CUSIP 9-digit"

replace cusip = substr(isin,3,8)
label var cusip "(CSRHub) CUSIP 8-digit created from cusip9"

/// Keep unique cusip year observations
bysort cusip year: gen N=_N
tab N
/*          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     78,804       93.80       93.80
          2 |      2,504        2.98       96.78
          3 |        918        1.09       97.87
          4 |        776        0.92       98.80
          5 |        495        0.59       99.39
          6 |        174        0.21       99.59
          7 |        105        0.12       99.72
          8 |         80        0.10       99.81
          9 |         45        0.05       99.87
         10 |         40        0.05       99.92
         11 |         22        0.03       99.94
         12 |         36        0.04       99.98
         13 |         13        0.02      100.00
------------+-----------------------------------
      Total |     84,012      100.00
*/
drop if N>1
drop N

***	Indicator variable
gen in_csrhub=1
label var in_csrhub "Indicator = 1 if in CSRHub data"

***	Save year-level CSRHub data
compress
save data/csrhub-all-year-level.dta, replace



***===================================***
*	CREATE MERGED YEAR LEVEL DATASET	*
*	Merge on CUSIP-year					*
***===================================***
use data/kld-all-clean.dta, clear

///	CREATE CUSIP-YEAR PANEL
drop firm_n

drop if cusip==""

bysort cusip year: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     44,786       99.66       99.66
          2 |         34        0.08       99.73
          3 |         18        0.04       99.77
          4 |          8        0.02       99.79
          5 |         20        0.04       99.83
          6 |          6        0.01       99.85
         69 |         69        0.15      100.00
------------+-----------------------------------
      Total |     44,941      100.00
*/

list firm cusip year N if N>1, sepby(cusip)
/*       +--------------------------------------------------------------------------------+
       |                                                    firm      cusip   year    N |
       |--------------------------------------------------------------------------------|
43843. |                                   SANDFIRE RESOURCES NL   AU000000   2013   69 |
43844. |                                         BURU ENERGY LTD   AU000000   2013   69 |
43845. |                                     INVESTA OFFICE FUND   AU000000   2013   69 |
43846. |                                               GPT GROUP   AU000000   2013   69 |
43847. |                                       RCR TOMLINSON LTD   AU000000   2013   69 |
43848. |                                          CARDNO LIMITED   AU000000   2013   69 |
43849. |                             MACQUARIE ATLAS ROADS GROUP   AU000000   2013   69 |
43850. |                                CHARTER HALL RETAIL REIT   AU000000   2013   69 |
43851. |                                 GOODMAN GROUP PTY. LTD.   AU000000   2013   69 |
43852. |                            TEN NETWORK HOLDINGS LIMITED   AU000000   2013   69 |
43853. |      SHOPPING CENTRES AUSTRALASIA PROPERTY GROUP RE LTD   AU000000   2013   69 |
43854. |                          SOUTHERN CROSS MEDIA GROUP LTD   AU000000   2013   69 |
43855. |                                     HORIZON OIL LIMITED   AU000000   2013   69 |
43856. |                                       GRAINCORP LIMITED   AU000000   2013   69 |
43857. |                              FEDERATION CENTRES LIMITED   AU000000   2013   69 |
43858. |                         M2 TELECOMMUNICATIONS GROUP LTD   AU000000   2013   69 |
43859. |                                             ALS LIMITED   AU000000   2013   69 |
43860. |                                   INDEPENDENCE GROUP NL   AU000000   2013   69 |
43861. |                                             AWE LIMITED   AU000000   2013   69 |
43862. |                                            ARB CORP LTD   AU000000   2013   69 |
43863. |                                  PERSEUS MINING LIMITED   AU000000   2013   69 |
43864. |                               STOCKLAND CORPORATION LTD   AU000000   2013   69 |
43865. |                                        AUSDRILL LIMITED   AU000000   2013   69 |
43866. |                            STW COMMUNICATIONS GROUP LTD   AU000000   2013   69 |
43867. |                                   WESTERN AREAS LIMITED   AU000000   2013   69 |
43868. |                                 GOODMAN FIELDER LIMITED   AU000000   2013   69 |
43869. |                                               BWP TRUST   AU000000   2013   69 |
43870. |                                   ABACUS PROPERTY GROUP   AU000000   2013   69 |
43871. |                        ECHO ENTERTAINMENT GROUP LIMITED   AU000000   2013   69 |
43872. |                       AUTOMOTIVE HOLDINGS GROUP LIMITED   AU000000   2013   69 |
43873. |                                   SKILLED GROUP LIMITED   AU000000   2013   69 |
43874. |                                             ASX LIMITED   AU000000   2013   69 |
43875. |                                        TRANSURBAN GROUP   AU000000   2013   69 |
43876. |                                       RIO TINTO LIMITED   AU000000   2013   69 |
43877. |                                      CHARTER HALL GROUP   AU000000   2013   69 |
43878. |                                    MINERAL DEPOSITS LTD   AU000000   2013   69 |
43879. |                                     OZ MINERALS LIMITED   AU000000   2013   69 |
43880. |                                EVOLUTION MINING LIMITED   AU000000   2013   69 |
43881. |                              DRILLSEARCH ENERGY LIMITED   AU000000   2013   69 |
43882. |                                            MIRVAC GROUP   AU000000   2013   69 |
43883. |                                    NRW HOLDINGS LIMITED   AU000000   2013   69 |
43884. |                                      DULUXGROUP LIMITED   AU000000   2013   69 |
43885. |                                   FLIGHT CENTRE LIMITED   AU000000   2013   69 |
43886. |                           SILVER LAKE RESOURCES LIMITED   AU000000   2013   69 |
43887. |                                   MEDUSA MINING LIMITED   AU000000   2013   69 |
43888. |                        MERMAID MARINE AUSTRALIA LIMITED   AU000000   2013   69 |
43889. |                                      FLEXIGROUP LIMITED   AU000000   2013   69 |
43890. |                                          NUFARM LIMITED   AU000000   2013   69 |
43891. |                                              DUET GROUP   AU000000   2013   69 |
43892. |                               AUSTRALAND PROPERTY GROUP   AU000000   2013   69 |
43893. |                                        DECMIL GROUP LTD   AU000000   2013   69 |
43894. |                                     STEADFAST GROUP LTD   AU000000   2013   69 |
43895. |                       PLATINUM ASSET MANAGEMENT LIMITED   AU000000   2013   69 |
43896. |                                   TOLL HOLDINGS LIMITED   AU000000   2013   69 |
43897. |                                   BEADELL RESOURCES LTD   AU000000   2013   69 |
43898. |                                               ACRUX LTD   AU000000   2013   69 |
43899. |                             PREMIER INVESTMENTS LIMITED   AU000000   2013   69 |
43900. |                                        INVOCARE LIMITED   AU000000   2013   69 |
43901. |                              ARISTOCRAT LEISURE LIMITED   AU000000   2013   69 |
43902. |                                               APA GROUP   AU000000   2013   69 |
43903. |                                    DEXUS PROPERTY GROUP   AU000000   2013   69 |
43904. |                                 REGIS RESOURCES LIMITED   AU000000   2013   69 |
43905. |                                  PAPILLON RESOURCES LTD   AU000000   2013   69 |
43906. |                                              NEXTDC LTD   AU000000   2013   69 |
43907. |                                       PERPETUAL LIMITED   AU000000   2013   69 |
43908. |                                 THE REJECT SHOP LIMITED   AU000000   2013   69 |
43909. |                         SYDNEY AIRPORT HOLDINGS LIMITED   AU000000   2013   69 |
43910. |                                          CUDECO LIMITED   AU000000   2013   69 |
43911. |                                             UGL LIMITED   AU000000   2013   69 |
       |--------------------------------------------------------------------------------|
44016. |                                      AGUAS ANDINAS S.A.   CL000000   2013    2 |
44017. |                                      EMPRESAS CMPC S.A.   CL000000   2013    2 |
       |--------------------------------------------------------------------------------|
44019. |            CHONGQING CHANGAN AUTOMOBILE COMPANY LIMITED   CNE00000   2013    2 |
44020. |             YANTAI CHANGYU PIONEER WINE COMPANY LIMITED   CNE00000   2013    2 |
       |--------------------------------------------------------------------------------|
44021. |                                 CSR CORPORATION LIMITED   CNE10000   2013    6 |
44022. |                              PETROCHINA COMPANY LIMITED   CNE10000   2013    6 |
44023. |                   NEW CHINA LIFE INSURANCE COMPANY LTD.   CNE10000   2013    6 |
44024. |                   CHINA CINDA ASSET MANAGEMENT CO., LTD   CNE10000   2013    6 |
44025. |                        SINOPEC ENGINEERING GROUP CO LTD   CNE10000   2013    6 |
44026. | THE PEOPLE'S INSURANCE COMPANY (GROUP) OF CHINA LIMITED   CNE10000   2013    6 |
       |--------------------------------------------------------------------------------|
44043. |                      ETABLISSEMENTS MAUREL ET PROM S.A.   FR000005   2013    2 |
44044. |                               TELEVISION FRANCAISE 1 SA   FR000005   2013    2 |
       |--------------------------------------------------------------------------------|
44045. |                                                SEB S.A.   FR000012   2013    5 |
44046. |                                              EURAZEO SA   FR000012   2013    5 |
44047. |                                          KLEPIERRE S.A.   FR000012   2013    5 |
44048. |                                                TOTAL SA   FR000012   2013    5 |
44049. |                                             WENDEL S.A.   FR000012   2013    5 |
       |--------------------------------------------------------------------------------|
44728. |                                         WERELDHAVE N.V.   NL000028   2013    3 |
44729. |                            EUROCOMMERCIAL PROPERTIES NV   NL000028   2013    3 |
44730. |                                              CORIO N.V.   NL000028   2013    3 |
       |--------------------------------------------------------------------------------|
44776. |                                L E LUNDBERGFORETAGEN AB   SE000010   2013    3 |
44777. |                                                 PEAB AB   SE000010   2013    3 |
44778. |                             AKTIEBOLAGET INDUSTRIVARDEN   SE000010   2013    3 |
       |--------------------------------------------------------------------------------|
44779. |                                                RATOS AB   SE000011   2013    5 |
44780. |                                           TRELLEBORG AB   SE000011   2013    5 |
44781. |                                   INVESTMENT AB ORESUND   SE000011   2013    5 |
44782. |                                          NCC AKTIEBOLAG   SE000011   2013    5 |
44783. |                                                 SAAB AB   SE000011   2013    5 |
       |--------------------------------------------------------------------------------|
44785. |                                  AVANZA BANK HOLDING AB   SE000017   2013    2 |
44786. |                                         HUFVUDSTADEN AB   SE000017   2013    2 |
       |--------------------------------------------------------------------------------|
44806. |                             NAN YA PLASTICS CORPORATION   TW000130   2013    2 |
44807. |                            FORMOSA PLASTICS CORPORATION   TW000130   2013    2 |
       |--------------------------------------------------------------------------------|
44813. |                          ORIENTAL UNION CHEMICAL CORP.,   TW000171   2013    2 |
44814. |                              ETERNAL CHEMICAL CO., LTD.   TW000171   2013    2 |
       |--------------------------------------------------------------------------------|
44820. |                         NANKANG RUBBER TIRE CORP., LTD.   TW000210   2013    3 |
44821. |                                        TSRC CORPORATION   TW000210   2013    3 |
44822. |                       CHENG SHIN RUBBER IND., CO., LTD.   TW000210   2013    3 |
       |--------------------------------------------------------------------------------|
44823. |                                 CHINA MOTOR CORPORATION   TW000220   2013    3 |
44824. |                                    HOTAI MOTOR CO.,LTD.   TW000220   2013    3 |
44825. |                                     YULON MOTOR CO.,LTD   TW000220   2013    3 |
       |--------------------------------------------------------------------------------|
44826. |                             FOXCONN TECHNOLOGY CO., LTD   TW000235   2013    2 |
44827. |                                    INVENTEC CORPORATION   TW000235   2013    2 |
       |--------------------------------------------------------------------------------|
44830. |                  CHENG UEI PRECISION INDUSTRY CO., LTD.   TW000239   2013    2 |
44831. |                                     ADVANTECH CO., LTD.   TW000239   2013    2 |
       |--------------------------------------------------------------------------------|
44832. |                             TRANSCEND INFORMATION, INC.   TW000245   2013    2 |
44833. |                                           MEDIATEK INC.   TW000245   2013    2 |
       |--------------------------------------------------------------------------------|
44836. |                                     CHINA AIRLINES LTD.   TW000261   2013    3 |
44837. |                                      WAN HAI LINES LTD.   TW000261   2013    3 |
44838. |                                 EVA AIRWAYS CORPORATION   TW000261   2013    3 |
       |--------------------------------------------------------------------------------|
44843. |               CHINA DEVELOPMENT FINANCIAL HOLDING CORP.   TW000288   2013    5 |
44844. |                      YUANTA FINANCIAL HOLDINGS CO., LTD   TW000288   2013    5 |
44845. |                        MEGA FINANCIAL HOLDING CO., LTD.   TW000288   2013    5 |
44846. |                     TAISHIN FINANCIAL HOLDING CO., LTD.   TW000288   2013    5 |
44847. |                     HUA NAN FINANCIAL HOLDINGS CO.,LTD.   TW000288   2013    5 |
       |--------------------------------------------------------------------------------|
44850. |                       PRESIDENT CHAIN STORE CORPORATION   TW000291   2013    2 |
44851. |                              RUENTEX INDUSTRIES LIMITED   TW000291   2013    2 |
       |--------------------------------------------------------------------------------|
44853. |                          NOVATEK MICROELECTRONICS CORP.   TW000303   2013    2 |
44854. |                              UNIMICRON TECHNOLOGY CORP.   TW000303   2013    2 |
       |--------------------------------------------------------------------------------|
44855. |                           TRIPOD TECHNOLOGY CORPORATION   TW000304   2013    2 |
44856. |                                 TAIWAN MOBILE CO., LTD.   TW000304   2013    2 |
       |--------------------------------------------------------------------------------|
44910. |                 HOSKEN CONSOLIDATED INVESTMENTS LIMITED   ZAE00000   2013    5 |
44911. |                                   HUDACO INDUSTRIES LTD   ZAE00000   2013    5 |
44912. |                                 ADCORP HOLDINGS LIMITED   ZAE00000   2013    5 |
44913. |                             PICK N PAY HOLDINGS LIMITED   ZAE00000   2013    5 |
44914. |                                  OMNIA HOLDINGS LIMITED   ZAE00000   2013    5 |
       |--------------------------------------------------------------------------------|
44915. |                               SHOPRITE HOLDINGS LIMITED   ZAE00001   2013    2 |
44916. |                                     SYCOM PROPERTY FUND   ZAE00001   2013    2 |
       |--------------------------------------------------------------------------------|
44917. |                                    INVICTA HOLDINGS LTD   ZAE00002   2013    3 |
44918. |                                      GROUP FIVE LIMITED   ZAE00002   2013    3 |
44919. |                                    SPUR CORPORATION LTD   ZAE00002   2013    3 |
       |--------------------------------------------------------------------------------|
44923. |                                  TONGAAT HULETT LIMITED   ZAE00009   2013    4 |
44924. |              FOUNTAINHEAD PROPERTY TRUST MANAGEMENT LTD   ZAE00009   2013    4 |
44925. |                              METAIR INVESTMENTS LIMITED   ZAE00009   2013    4 |
44926. |                                        RAUBEX GROUP LTD   ZAE00009   2013    4 |
       |--------------------------------------------------------------------------------|
44928. |                          STEFANUTTI STOCKS HOLDINGS LTD   ZAE00012   2013    2 |
44929. |                              ADCOCK INGRAM HOLDINGS LTD   ZAE00012   2013    2 |
       |--------------------------------------------------------------------------------|
44930. |                                               MPACT LTD   ZAE00015   2013    2 |
44931. |                    RAND MERCHANT INSURANCE HOLDINGS LTD   ZAE00015   2013    2 |
       |--------------------------------------------------------------------------------|
44933. |                    PINNACLE TECHNOLOGY HOLDINGS LIMITED   ZAE00018   2013    2 |
44934. |                            VUKILE PROPERTY FUND LIMITED   ZAE00018   2013    2 |
       |--------------------------------------------------------------------------------|
44935. |                  RESILIENT PROPERTY INCOME FUND LIMITED   ZAE00019   2013    2 |
44936. |                            FORTRESS INCOME FUND LIMITED   ZAE00019   2013    2 |
       |--------------------------------------------------------------------------------|
44937. |                                     EMIRA PROPERTY FUND   ZAE00020   2013    4 |
44938. |                                ARROWHEAD PROPERTIES LTD   ZAE00020   2013    4 |
44939. |                               REBOSIS PROPERTY FUND LTD   ZAE00020   2013    4 |
44940. |                           SA CORPORATE REAL ESTATE FUND   ZAE00020   2013    4 |
       +--------------------------------------------------------------------------------+
*/
drop if N>1
drop N

***	Generate indicator variable
gen in_kld = 1
label var in_kld "Indicator = 1 if in KLD data"


///	MERGE WITH CSRHUB YEARLY
drop firm	/*	Avoids conflicts with the firm variable in csrhub-all-year-level	*/

merge 1:1 cusip year using data/csrhub-all-year-level.dta, update assert(1 2 3 4 5)
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        94,862
        from master                    30,422  (_merge==1)
        from using                     64,440  (_merge==2)

    matched                            14,364
        not updated                    14,364  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/
codebook cusip if _merge==3
codebook cusip if firm_kld!="" & year > 2008 & year < 2016
*	242 cusip matched between CSRHub and KLD
*		That's 3,389 / 6,981 = 49% of CUSIPs in KLD matched to CSRHub
drop _merge

tempfile d1
save `d1'


///	MERGE WITH CSTAT YEARLY
use data/cstat-all-variables-for-all-cusip9-in-csrhub-and-kld-1990-2018.dta, clear

gen year = year(datadate)
rename cusip cusip9

gen cusip=substr(cusip9,1,8)
drop if cusip==""
bysort cusip year: gen N=_N
tab N
/*          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    113,801       99.66       99.66
          2 |        390        0.34      100.00
------------+-----------------------------------
      Total |    114,191      100.00
*/
drop if N>1
drop N

***	Generate indicator variable
gen in_cstat = 1
label var in_cstat "Indicator = 1 if in CSTAT data"

***	Merge
merge 1:1 cusip year using `d1', update assert(1 2 3 4 5)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       132,775
        from master                    68,675  (_merge==1)
        from using                     64,100  (_merge==2)

    matched                            45,126
        not updated                    45,126  (_merge==3)
        missing updated                     0  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/

***	Drop variables
drop _merge cusip_n
drop in_cstat_csrhub_cusip in_cstat_kld_cusip




***=======================================***
*	CREATE NEW VARIABLES FOR REWB MODELS	*
***=======================================***
encode cusip, gen(cusip_n)

rename over_rtg_lym over_rtg
/// Create de-meaned and mean variables for random effects within-between modeling
foreach variable in net_kld_str net_kld_con over_rtg emp debt rd ad size {
	bysort cusip_n: egen `variable'_m = mean(`variable')
	label var `variable'_m "CUSIP-level mean of `variable'"
	bysort cusip_n: gen `variable'_dm = `variable' - `variable'_m
	label var `variable'_dm "CUSIP-level de-meaned `variable'"
}

///	SAVE
compress
drop cusip_n
order cusip year conm firm_kld firm
sort cusip year
save data/csrhub-kld-cstat-year-level.dta, replace

*/




***===========================***
*	CREATE TREATMENT VARIABLES	*
***===========================***
use data/csrhub-kld-cstat-year-level.dta, clear

encode cusip, gen(cusip_n)
xtset cusip_n year



///	TREATMENT IS THE CHANGE IN CSRHUB OVERALL RATING EXCEEDING THE GLOBAL
*	STANDARD DEVIATION OF CSRHUB OVERALL RATING

***	Binary thresholds with overlap between groups using global within-firm over_rtg standard deviation
foreach threshold in 4 3 2 {
	qui xtset
	qui xtsum over_rtg
	
	*Overlap
	gen trt`threshold'_year_sdg = (abs(over_rtg_dm-l.over_rtg_dm) > `threshold'*`r(sd_w)') & ///
		over_rtg_dm!=. & l.over_rtg_dm!=. & over_rtg!=.
	label var trt`threshold'_year "Indicator =1 if year of `threshold' global std dev treatment"
	replace trt`threshold'_year_sdg=. if over_rtg==.

	by cusip_n: gen trt_year_sdg = year if trt`threshold'_year_sdg==1
	sort cusip_n trt_year_sdg
	by cusip_n: replace trt_year_sdg = trt_year_sdg[_n-1] if _n!=1
	replace trt_year_sdg = . if over_rtg==.
	
	qui xtset
	
	by cusip_n: gen post`threshold'_sdg=(year>trt_year_sdg)
	label var post`threshold'_sdg "Indicator =1 if post-treatment year for `threshold' global std dev treatment"
	replace post`threshold'_sdg=. if over_rtg==.
	
	
	by cusip_n: egen trt`threshold'_sdg= max(post`threshold'_sdg)
	label var trt`threshold'_sdg "Indicator = 1 if treatment group for `threshold' global std dev treated"
*	replace trt`threshold'_sdg=. if over_rtg==.
	
	bysort cusip_n: egen sumtrt=sum(trt`threshold'_year_sdg)

	drop trt_year sumtrt
}	

***	Binary thresholds without overlap between groups
gen trt4_year_only_sdg = trt4_year_sdg
label var trt4_year_only_sdg "Indicator =1 if year of ONLY 4 global std dev treatment"
gen post4_only_sdg = post4_sdg
label var post4_only_sdg "Indicator =1 if post-treatment year of ONLY 4 global std dev treatment"
gen trt4_only_sdg = trt4_sdg
label var trt4_only_sdg "Indicator = 1 if treatment group of ONLY 4 global std dev treated"

foreach threshold in 3 2 {
	local y = `threshold' + 1

	gen trt`threshold'_year_only_sdg = trt`threshold'_year_sdg
	label var trt`threshold'_year_only_sdg "Indicator =1 if year of ONLY `threshold' global std dev treatment"
	gen post`threshold'_only_sdg = post`threshold'_sdg
	label var post`threshold'_only_sdg "Indicator =1 if post-treatment year of ONLY `threshold' global std dev treatment"
	gen trt`threshold'_only_sdg = trt`threshold'_sdg
	label var trt`threshold'_only_sdg "Indicator = 1 if treatment group of ONLY `threshold' global std dev treated"
	
	replace trt`threshold'_year_only_sdg = 0 if trt`y'_year_sdg==1
	replace post`threshold'_only_sdg = 0 if post`y'_sdg == 1
	replace trt`threshold'_only_sdg = 0 if trt`y'_sdg == 1
}



///	TREATMENT IS THE CHANGE IN CSRHUB OVERALL RATING EXCEEDING EACH FIRM'S
*	STANDARD DEVIATION OF CSRHUB OVERALL RATING

***	Binary thresholds with OVERLAP between groups using firm-specific within-firm over_rtg standard deviation
by cusip_n: egen sdw = sd(over_rtg)
label var sdw "Within-firm standard deviation of over_rtg for each cusip_n"
replace sdw=. if over_rtg==.

foreach threshold in 4 3 2 {
	qui xtset
	
	gen trt`threshold'_year_sdw = (abs(over_rtg_dm-l.over_rtg_dm) > `threshold'*sdw) & ///
		over_rtg_dm!=. & l.over_rtg_dm!=. & over_rtg!=.
	label var trt`threshold'_year_sdw "Indicator =1 if year of `threshold' std dev treatment for within-firm std dev"
	replace trt`threshold'_year_sdw=. if over_rtg==.

	by cusip_n: gen trt_year = year if trt`threshold'_year_sdw==1
	sort cusip_n trt_year
	by cusip_n: replace trt_year = trt_year[_n-1] if _n!=1
	replace trt_year = . if over_rtg==.
	
	qui xtset
	
	by cusip_n: gen post`threshold'_sdw=(year>trt_year)
	label var post`threshold'_sdw "Indicator =1 if post-treatment for `threshold' within-firm std dev treatment"
	replace post`threshold'_sdw=. if over_rtg==.
	
	by cusip_n: egen trt`threshold'_sdw= max(post`threshold'_sdw)
	label var trt`threshold'_sdw "Indicator = 1 if treatment group for `threshold' within-firm std dev treated"
*	replace trt`threshold'_sdw=. if over_rtg==.
	
	bysort cusip_n: egen sumtrt=sum(trt`threshold'_year_sdw)
	
	drop trt_year sumtrt
}


***	Binary thresholds without overlap between groups
gen trt4_year_only_sdw = trt4_year_sdw
label var trt4_year_only_sdw "Indicator =1 if year of ONLY 4 firm's std dev treatment"
gen post4_only_sdw = post4_sdw
label var post4_only_sdw "Indicator =1 if post-treatment year of ONLY 4 firm's std dev treatment"
gen trt4_only_sdw = trt4_sdw
label var trt4_only_sdw "Indicator = 1 if treatment group of ONLY 4 firm's std dev treated"

foreach threshold in 3 2 {
	local y = `threshold' + 1

	gen trt`threshold'_year_only_sdw = trt`threshold'_year_sdw
	label var trt`threshold'_year_only_sdw "Indicator =1 if year of ONLY `threshold' firm's std dev treatment"
	gen post`threshold'_only_sdw = post`threshold'_sdw
	label var post`threshold'_only_sdw "Indicator =1 if post-treatment year of ONLY `threshold' firm's std dev treatment"
	gen trt`threshold'_only_sdw = trt`threshold'_sdw
	label var trt`threshold'_only_sdw "Indicator = 1 if treatment group of ONLY `threshold' firm's std dev treated"
	
	replace trt`threshold'_year_only_sdw = 0 if trt`y'_year_sdw==1
	replace post`threshold'_only_sdw = 0 if post`y'_sdw == 1
	replace trt`threshold'_only_sdw = 0 if trt`y'_sdw == 1
}






///	SAVE
***	Order variables
order cusip year firm firm_kld conm
format %20s firm firm_kld conm

sort cusip year

gen in_all = (in_cstat==1 & in_kld==1 & in_csrhub==1)
label var in_all "Indicator = 1 if in CSRHub, CSTAT, and KLD data"

compress
save data/csrhub-kld-cstat-year-level-with-treatment-variables.dta, replace
















/***===============================================================**
*	MATCHING STRATEGY												*
*																	*
*	1) Specify the model determining treatment status				*
*	2) Use the model to predict which firms will be treated			*
*	3) Match on the predicted likelihood of being treated			*
*	4) Compare outcomes across matched treated and control units	*
*																	*
***==============================================================***/

///	LOAD DATA
use data/csrhub-kld-cstat-year-level-with-treatment-variables.dta, clear

***	Drop CSTAT variables

* Duplicates
drop sale /* same as revt	*/

/* Many missing values
acqmeth adrr bspr compst curuscn ltcm ogm stalt udpl acco acdo acodo acominc acoxar acqao acqcshi acqgdwl acqic acqintan acqinvt acqlntal acqniintc acqppe acqsc adpac aedi afudcc afudci amc amdc 
drop drc
drop dvrre
drop nfsr 
drop ris 
drop unnp 
drop unnpl 
drop urevub
*/


/// GENERATE PROPENSITY SCORES PREDICTING TREATMENT AT BEGINNING OF CSRHUB DATA IN 2008

***	Specify the model predicting treatment
/*	COMPUSTAT
	-	fyear
	fyr 
	curcd
	at 
	bkvlps 
	ceq 
	csho 
	dltt 
	drc 
	drlt 
	emp 
	gp 
	lcoxdr 
	loxdr 
	ni 
	revt 
	sale:	same as revt
*/

forvalues year = 1990/2018 {
	foreach threshold in 4 3 2 {
		display("threshold: `threshold' in year `year'")
		capt n probit trt`threshold'_sdg emp at csho if year==`year'
		capt n predict ps`threshold'_`year'_sdg if e(sample), pr
	}
}



























***===============================================================***
*	EXPLORATORY DATA ANALYSIS OF TREATMENT AND NON-TREATMENT FIRMS	*
***===============================================================***
set scheme plotplainblind

///	LOAD DATA
use data/csrhub-kld-cstat-year-level-with-treatment-variables.dta, clear

encode cusip, gen(cusip_n)
xtset cusip_n year, y

/// WITHIN-FIRM OVERALL RATING STANDARD DEVIATION
gen one_year_change_over_rtg_dm = over_rtg_dm - l.over_rtg_dm

/*
set scheme plotplainblind
xtsum over_rtg
local sd1p = `r(sd_w)'
local sd1n = `r(sd_w)' * -1
local sd2p = `r(sd_w)' * 2
local sd2n = `r(sd_w)' * -2
local sd3p = `r(sd_w)' * 3
local sd3n = `r(sd_w)' * -3
local sd3p = `r(sd_w)' * 4
local sd3n = `r(sd_w)' * -4
scatter one_year_change_over_rtg_dm cusip_n, sort mlabsize(tiny) m(p) mcolor(black%30) ///
	yline(`sd1p') ///
	yline(`sd1n') /// 
	yline(`sd2p') ///
	yline(`sd2n') ///
	yline(`sd4p') ///
	yline(`sd4n')
*/

///	CHECK IF TREATED FIRMS ARE JUST THOSE THAT HAVE HIGH STANDARD DEVIATIONS IN THEIR OWN SCORES
bysort cusip: egen over_std=sd(over_rtg)
replace over_std=. if over_rtg==.
histogram over_std, bin(100) normal ///
	ti("Distribution of within-firm CSRHub overall rating standard deviations") ///
	saving(graphics/hist-over_std, replace)

foreach value in 4 3 2 {
	graph box over_std, over(trt`value') saving(graphics/trt`value', replace) ti("`value'-standard deviation treatment") nodraw
}
gr combine graphics/trt4.gph graphics/trt3.gph graphics/trt2.gph, r(1) c(3) ///
	saving(graphics/trt-combined, replace) nodraw

	
///	FINANCIAL PERFORMANCE DIFFERENCES IN RAW DATA
capt matrix drop A
foreach cfp in revt ni tobinq {
	foreach threshold in 4 3 2 {
		ttest `cfp', by(trt`threshold')
		capt noisily confirm matrix A
		if (_rc!=0) {
			matrix define A = (r(mu_1), r(mu_2), r(mu_1)-r(mu_2), r(t), r(p))
			matrix colnames A = Mu_0 Mu_1 Difference T-stat P-value
			matrix rownames A = "ttest_`cfp'_trt`threshold'"
			}
		else {
			local matrownames `:rownames A'
			mat A = (A \ r(mu_1), r(mu_2), r(mu_1)-r(mu_2), r(t), r(p))
			mat rownames A = `matrownames' ttest_`cfp'_trt`threshold'
		}
	}
}

putexcel set tables-and-figures/ttestresults, replace
putexcel A1=matrix(A), names 


///	DISTRIBUTION OF TREATED FIRMS ACROSS YEARS

***	Treated CUSIPs per year
foreach threshold in 4 3 2 {
	graph bar (count) cusip_n if trt`threshold'_date==1, over(year, label(angle(90))) ///
		ti("Count of `threshold'sd treated CUSIPs per year") ///
		yti("CUSIPs treated at `threshold'sd") ///
		blabel(total, size(vsmall)) ///
		saving(graphics/treated-cusips-per-year-`threshold'sd, replace) ///
		nodraw		
}
	
graph combine graphics/treated-cusips-per-year-4sd.gph ///
	graphics/treated-cusips-per-year-3sd.gph ///
	graphics/treated-cusips-per-year-2sd.gph, row(1) col(3) ///
	altshrink ///
	ycommon xcommon

***	Only firms in the entire CSRHub panel
keep if in_csrhub==1
bysort cusip: gen N=_N
tab N
keep if N==10
drop N

foreach threshold in 4 3 2 {
	graph bar (count) cusip_n if trt`threshold'_date==1, over(year, label((2008(1)2017), angle(90))) ///
		ti("Count of `threshold'sd treated CUSIPs per year") ///
		yti("CUSIPs treated at `threshold'sd") ///
		blabel(total, size(vsmall)) ///
		saving(graphics/treated-cusips-per-year-`threshold'sd-balanced-panel, replace) ///
		nodraw		
}
	
graph combine graphics/treated-cusips-per-year-4sd-balanced-panel.gph ///
	graphics/treated-cusips-per-year-3sd-balanced-panel.gph ///
	graphics/treated-cusips-per-year-2sd-balanced-panel.gph, row(1) col(3) ///
	altshrink ///
	ycommon xcommon ///
	ti("CUSIPs in all years of CSRHub data")






















*END
