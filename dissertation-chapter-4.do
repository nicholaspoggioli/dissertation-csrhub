********************************************************************************
*Title: Dissertation Chapter 4 Industry Heterogeneity
*Created by: Nicholas Poggioli (poggi005@umn.edu)
*Created on: October 2018
*Purpose: Analyze industry heterogeneity in CSR-CFP relationship
/*	Outline
		1 Cluster into 5 - 6 interesting industries
			-	Petrochemical
			-	Automotive
			-	Financial
		2 Heterogeneity in KLD
			-	Recreate Table 6 Perrault & Quinn 2018
		3 Heterogeneity in CSTAT
		4 Heterogeneity in performance
*/
********************************************************************************

***=============================***
*	CREATE INDUSTRY VARIABLES	***
***=============================***
///		1 Clustering
***	Load data
use data\kld-cstat-bs2012.dta, clear

set scheme plotplainblind

***	Merge SIC industry names
*	4-digit SIC codes
preserve
capt n import excel "D:\Dropbox\papers\active\dissertation-csrhub\project\data\sic-codes.xlsx", sheet("codes") firstrow allstring clear
capt n save data/sic-codes.dta
restore

merge m:1 sic using data/sic-codes.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        19,629
        from master                    19,557  (_merge==1)
        from using                         72  (_merge==2)

    matched                            30,112  (_merge==3)
    -----------------------------------------
*/
tab sic if _merge==1, miss
/*
    (CSTAT) |
   Standard |
   Industry |
Classificat |
   ion Code |      Freq.     Percent        Cum.
------------+-----------------------------------
            |     16,874       86.28       86.28
       1044 |         25        0.13       86.41
       2085 |         15        0.08       86.49
       4888 |         87        0.44       86.93
       5093 |         11        0.06       86.99
       6020 |      2,060       10.53       97.52
       6722 |         76        0.39       97.91
       6726 |         89        0.46       98.36
       6797 |        121        0.62       98.98
       7323 |         61        0.31       99.29
       7996 |         11        0.06       99.35
       8721 |         64        0.33       99.68
       9997 |         63        0.32      100.00
------------+-----------------------------------
      Total |     19,557      100.00
*/

*	Replace non-matched codes with codes from https://www.osha.gov/pls/imis/sicsearch.html?p_sic=1044&p_search=
replace industry="Silver Ores" if sic=="1044"
replace industry="Distilled and Blended Liquors" if sic=="2085"
*replace industry="" if sic=="4888"
replace industry="Scrap and Waste Materials" if sic=="5093"
*replace industry="" if sic=="6020"
replace industry="Management Investment Offices, Open-End" if sic=="6722"
replace industry="Unit Investment Trusts, Face-Amount Certificate Offices, and Closed-End Management Investment Offices" if sic=="6726"
*replace industry="" if sic=="6797"
replace industry="Credit Reporting Services" if sic=="7323"
replace industry="Amusement Parks" if sic=="7996"
replace industry="Accounting, Auditing, and Bookkeeping Services" if sic=="8721"
*replace industry="" if sic=="9997"

replace _merge=3 if _merge==1 & industry!=""

tab sic if _merge==1, miss
/*    (CSTAT) |
   Standard |
   Industry |
Classificat |
   ion Code |      Freq.     Percent        Cum.
------------+-----------------------------------
            |     16,874       87.86       87.86
       4888 |         87        0.45       88.32
       6020 |      2,060       10.73       99.04
       6797 |        121        0.63       99.67
       9997 |         63        0.33      100.00
------------+-----------------------------------
      Total |     19,205      100.00
*/

rename industry industry_sic4
label var industry_sic4 "4-digit SIC code industry description"

drop if _merge==2
drop _merge


*	2-digit SIC codes
gen sic2 = substr(sic,1,2)
tab sic2						/*	Perrault & Quinn 2018 uses 2-digit SIC codes	*/

preserve
capt n import excel "D:\Dropbox\papers\active\dissertation-csrhub\project\data\sic_2_digit_codes.xlsx", sheet("SIC 2 Digit Code") firstrow allstring clear
capt n save data/sic2.dta
restore

merge m:1 sic2 using data/sic2.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        16,889
        from master                    16,874  (_merge==1)
        from using                         15  (_merge==2)

    matched                            32,795  (_merge==3)
    -----------------------------------------
*/

tab sic2 if _merge==1, miss
/*
2-digit SIC |
   industry |
       code |
   (created |
   from sic |
  variable) |      Freq.     Percent        Cum.
------------+-----------------------------------
            |     16,874      100.00      100.00
------------+-----------------------------------
      Total |     16,874      100.00
*/

drop if _merge==2
drop _merge

label var sic2 "2-digit SIC industry code (created from sic variable)"
label var industry_sic2 "2-digit SIC code industry description"

***	Flag 6 industries by most numerous in the data
tab industry_sic2, sort
/*  2-digit SIC code industry description |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
          Chemicals and Allied Products |      2,886        8.80        8.80
                      Business Services |      2,857        8.71       17.51
                Depository Institutions |      2,515        7.67       25.18
   Holding and Other Investment Offices |      2,175        6.63       31.81
Electronic & Other Electrical Equipme.. |      2,074        6.32       38.14
Industrial and Commercial Machinery a.. |      1,782        5.43       43.57
Measuring, Photographic, Medical, & O.. |      1,592        4.85       48.43
    Electric, Gas and Sanitary Services |      1,472        4.49       52.91
                     Insurance Carriers |      1,300        3.96       56.88
                 Oil and Gas Extraction |      1,168        3.56       60.44
*/

tab sic2, sort
/*2-digit SIC |
   industry |
       code |
   (created |
   from sic |
  variable) |      Freq.     Percent        Cum.
------------+-----------------------------------
         28 |      2,886        8.80        8.80
         73 |      2,857        8.71       17.51
         60 |      2,515        7.67       25.18
         67 |      2,175        6.63       31.81
         36 |      2,074        6.32       38.14
         35 |      1,782        5.43       43.57
         38 |      1,592        4.85       48.43
         49 |      1,472        4.49       52.91
         63 |      1,300        3.96       56.88
         13 |      1,168        3.56       60.44
*/

gen sic2_f = .
label var sic2_f "=1 if top 10 sic2 industry by number of observations"
foreach v in "28" "73" "60" "67" "36" "35" "38" "49" "63" "13" {
	replace sic2_f = 1 if sic2=="`v'"
}

***	SIC 1-digit Division classification
/*
Division	Code	Industry Title
A			01-09	Agriculture, Forestry, And Fishing
B			10-14	Mining
C			15-17	Construction
D			20-39	Manufacturing
E			40-49	Transportation, Communications, Electric, Gas, And Sanitary Services
F			50-51	Wholesale Trade
G			52-59	Retail Trade
H			60-67	Finance, Insurance, And Real Estate
I			70-89	Services
J			90-99	Public Administration
*/

gen sic1=""
destring sic2, gen(sic2num)
replace sic1="A" if sic2num>0 & sic2num<=9
replace sic1="B" if sic2num>=10 & sic2num<=14
replace sic1="C" if sic2num>=15 & sic2num<=17
replace sic1="D" if sic2num>=20 & sic2num<=39
replace sic1="E" if sic2num>=40 & sic2num<=49
replace sic1="F" if sic2num>=50 & sic2num<=51
replace sic1="G" if sic2num>=52 & sic2num<=59
replace sic1="H" if sic2num>=60 & sic2num<=67
replace sic1="I" if sic2num>=70 & sic2num<=89
replace sic1="J" if sic2num>=90 & sic2num<=99

tab sic1, miss
/*
       sic1 |      Freq.     Percent        Cum.
------------+-----------------------------------
            |     16,874       33.97       33.97
          A |         86        0.17       34.15
          B |      1,498        3.02       37.16
          C |        404        0.81       37.98
          D |     12,912       26.00       63.97
          E |      3,125        6.29       70.26
          F |        901        1.81       72.08
          G |      2,080        4.19       76.26
          H |      7,159       14.41       90.68
          I |      4,546        9.15       99.83
          J |         84        0.17      100.00
------------+-----------------------------------
      Total |     49,669      100.00
*/

merge m:1 sic1 using data\sic-codes-division-level.dta, keepusing(division_sic2)
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        16,874
        from master                    16,874  (_merge==1)
        from using                          0  (_merge==2)

    matched                            32,795  (_merge==3)
    -----------------------------------------
*/
drop _merge

replace division_sic2="Transport, Comm, Electric, Gas, Sanitary" if division_sic2=="Transportation, Communications, Electric, Gas, And Sanitary Services"

tab division_sic2, miss
/*
                         Industry Title |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                                        |     16,874       33.97       33.97
     Agriculture, Forestry, And Fishing |         86        0.17       34.15
                           Construction |        404        0.81       34.96
    Finance, Insurance, And Real Estate |      7,159       14.41       49.37
                          Manufacturing |     12,912       26.00       75.37
                                 Mining |      1,498        3.02       78.38
                  Public Administration |         84        0.17       78.55
                           Retail Trade |      2,080        4.19       82.74
                               Services |      4,546        9.15       91.89
Transportation, Communications, Elect.. |      3,125        6.29       98.19
                        Wholesale Trade |        901        1.81      100.00
----------------------------------------+-----------------------------------
                                  Total |     49,669      100.00
*/


			***===========================================***
			*		  EXPLORATORY STATISTICS 				*
			***===========================================***

///	KLD across SIC Divisions

***	Summary statistics
tabstat net_kld net_kld_str net_kld_con, by(division_sic2) stat(mean sd p50 min max N) columns(statistics) longstub
tabstat *agg, by(division_sic2) stat(mean sd p50 min max N) columns(statistics) longstub


///		2 Heterogeneity in KLD
***		Recreate Table 6 Perrault & Quinn 2018
sort sic2

preserve

drop if year<1998 | year > 2010

egen tag = tag(sic2 firm)
egen firm_N = total(tag), by(sic2)
drop tag
tabdisp sic2, c(firm_N)
label var firm_N "number of unique firm names in sic2"

foreach v in cgov com div emp env hum pro {
	by sic2: egen sic2_`v'_str = total(sum_`v'_str)
	by sic2: egen sic2_`v'_con = total(sum_`v'_con)
}

by sic2: gen sic2_N=_N
foreach v in cgov com div emp env hum pro {
	by sic2: egen sic2_`v'_str_st = total(sum_`v'_str)
	replace sic2_`v'_str_st = sic2_`v'_str_st / sic2_N
	by sic2: egen sic2_`v'_con_st = total(sum_`v'_con)
	replace sic2_`v'_con_st = sic2_`v'_con_st / sic2_N
}
label var sic2_N "number of observations in sic2 industry"

bysort sic2: gen n=_n
keep if n==1
drop n

keep sic2* sic2_N industry_sic2 firm_N
order sic2 industry_sic2 sic2_N firm_N *str *con

drop if sic2==""

capt n export excel using "figures\kld-sic2-sum-strengths-concerns.xls", firstrow(variables)

keep if sic2_N>500
capt n export excel using "figures\kld-sic2-sum-strengths-concerns-more-than-500-industry-obs.xls", firstrow(variables)

corr *_st, means

restore


***	Descriptive statistics

egen tag = tag(sic2 firm)
egen firm_N = total(tag), by(sic2)
drop tag
tabdisp sic2, c(firm_N)
label var firm_N "number of unique firm names in sic2"



*	Means and standard deviations
foreach v in cgov com div emp env hum pro {
	bysort sic2: egen mean_`v'_str = mean(sum_`v'_str)
	bysort sic2: egen sd_`v'_str = sd(sum_`v'_str)
	bysort sic2: egen mean_`v'_con = mean(sum_`v'_con)
	bysort sic2: egen sd_`v'_con = sd(sum_`v'_con)
}


*	Product
asdoc tabstat sum_pro_str, by(sic2) stat(mean p50 min max N) ///
	title(Summary stats, sum of KLD product strengths, by SIC2 industry code across 1991 - 2015) ///
	save(figures/kld-by-sic2-product-strengths), replace

*	Corporate governance
asdoc tabstat sum_cgov_str, by(sic2) stat(mean p50 min max N) ///
	title(Summary stats, sum of KLD corporate governance strengths, by SIC2 industry code across 1991 - 2015) ///
	save(figures/kld-by-sic2-cgov-strengths), replace

*	Diversity

*	Community

*	Employees

*	Environment
asdoc tabstat sum_env_str, by(sic2) stat(mean p50 min max N) ///
	title(Summary stats, sum of KLD environment strengths, by SIC2 industry code across 1991 - 2015) ///
	save(figures/kld-by-sic2-env-strengths), replace

asdoc tabstat sum_env_con, by(sic2) stat(mean p50 min max N) ///
	title(Summary stats, sum of KLD environment concerns, by SIC2 industry code across 1991 - 2015) ///
	save(figures/kld-by-sic2-env-concerns), replace

	
	
asdoc tabdisp industry_sic2, c(mean_env_str sd_env_str mean_env_con sd_env_con) format(%9.3f), ///
	save(figures/kld-mean-by-sic2), replace
	
	
*	Human rights
