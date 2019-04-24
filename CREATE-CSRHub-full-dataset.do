***	Create full CSRHub dataset for analysis
*	Includes merging with CSTAT and KLD datasets

set more off
cd
version

/*	CODE TO CONVERT RAW .CSVS TO STATSETS, LAST RUN MARCH 2, 2018 (LINES 39 - 474)

			***===========================================***
			*												*
			*	Convert CSRHub .csv files to Stata .dta		*
			*												*
			***====================== =====================***
***	CSRHub+Dashboard+CSR_ESG+Research--2017-04-26-OVERALL-ENVIRONMENT-RESOURCEMGMT-RANDOM-FIRMS-ALL
set more off

* 	a)	Load file
import delimited "data/csrhub-raw/CSRHub+Dashboard+CSR_ESG+Research--2017-04-26 -OVERALL-ENVIRONMENT-RESOURCEMGMT-RANDOM-FIRMS-ALL.csv", ///
	varnames(13) rowrange(14) colrange(3) clear
gen row=_n+13
keep if getresultsinthesecells!=""
compress

* 	b)	Rename and label variables with variable names from first row
foreach v of varlist * {
	local varlab = `v'[1]
	label var `v' "`varlab'"
}

foreach v of varlist getresultsinthesecells v2 v3 {
	local varname = `v'[1]
	local varname2 = subinstr("`varname'"," ","",.)
	rename `v' `varname2'
}

rename CSRHubOfficialName firm
rename v104 industry
rename v105 country
drop v106

foreach v of varlist v4-v103 {
	local date = subinstr((subinstr((subinstr(`v'[1],"Overall Rating (","",.)),")","",.))," ","",.)
	local varname = "over_rtg`date'"
	rename `v' `varname'
}

foreach v of varlist v107-v206 {
	local date = subinstr((subinstr((subinstr(`v'[1],"# of Sources Used in Rating (","",.)),")","",.))," ","",.)
	local varname = "num_sources`date'"
	rename `v' `varname'
}

foreach v of varlist v207-v306 {
	local date = subinstr((subinstr((subinstr(`v'[1],"Industry Average Rating (","",.)),")","",.))," ","",.)
	local varname = "industry_avg_rtg`date'"
	rename `v' `varname'
}

foreach v of varlist v307-v406 {
	local date = subinstr((subinstr((subinstr(`v'[1],"Environment Rating (","",.)),")","",.))," ","",.)
	local varname = "enviro_rtg`date'"
	rename `v' `varname'
}

foreach v of varlist v407-v506 {
	local date = subinstr((subinstr((subinstr(`v'[1],"Environment Policy & Reporting Rating (","",.)),")","",.))," ","",.)
	local varname = "enviro_pol_rpt_rtg`date'"
	rename `v' `varname'
}

foreach v of varlist v507-v606 {
	local date = subinstr((subinstr((subinstr(`v'[1],"Resource Management Rating (","",.)),")","",.))," ","",.)
	local varname = "resource_mgmt_rtg`date'"
	rename `v' `varname'
}

*	c)	Reshape from wide to long
order industry country, after(ISIN)

drop in 1

bysort firm: gen n=_n
drop if n>1
drop row n

reshape long over_rtg num_sources industry_avg_rtg enviro_rtg ///
	enviro_pol_rpt_rtg resource_mgmt_rtg, i(firm) j(date) string

drop if over_rtg=="NA"
compress

*Destring numerics	
foreach v of varlist over_rtg num_sources industry_avg_rtg enviro_rtg ///
	enviro_pol_rpt_rtg resource_mgmt_rtg {
	replace `v'="" if `v'=="NA"
	destring `v', replace
}
compress

*Generate date variables
gen datenum=date(date,"MY")
gen month=month(datenum)
gen year=year(datenum)
order datenum, after(date)

*Standardize country to iso3 codes
replace country="Macao" if country=="Macau"
replace country="Korea, Republic of" if country=="South Korea"
replace country="Taiwan, Province of China" if country=="Taiwan"
replace country="United States" if country=="USA"


*	d)	Save as .dta
gen in_ovrl_enviro=1
compress
save "OVERALL-ENVIRO.dta", replace



***	CSRHub+Dashboard+CSR_ESG+Research--2017-04-26-ALL-OTHER-VARIABLES-_________.csv

*	a) 	Load data
set more off
local files : dir "" files "*all-other*.csv"

local n=1

foreach file of local files {
	display("`file'")
	import delimited `file', clear ///
	varnames(13) rowrange(14) colrange(3)
	drop if getresultsinthesecells==""

	* 	b)	Rename and label variables with variable names from first row
	*Label
	foreach v of varlist * {
		local varlab = `v'[1]
		label var `v' "`varlab'"
	}
	drop v1404

	*Rename
	foreach v of varlist getresultsinthesecells v2 v3 {
		local varname = `v'[1]
		local varname2 = subinstr("`varname'"," ","",.)
		rename `v' `varname2'
	}

	rename CSRHubOfficialName firm

	foreach v of varlist v4-v103 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Overall Percentile Rank (","",.)),")","",.))," ","",.)
		local varname = "over_pct_rank`date'"
		rename `v' `varname'
	}


	foreach v of varlist v104-v203 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Community Rating (","",.)),")","",.))," ","",.)
		local varname = "cmty_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v204-v303 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Employees Rating (","",.)),")","",.))," ","",.)
		local varname = "emp_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v304-v403 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Governance Rating (","",.)),")","",.))," ","",.)
		local varname = "gov_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v404-v503 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Community Dev & Philanthropy Rating (","",.)),")","",.))," ","",.)
		local varname = "com_dev_phl_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v504-v603 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Human Rights & Supply Chain Rating (","",.)),")","",.))," ","",.)
		local varname = "humrts_supchain_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v604-v703 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Product Rating (","",.)),")","",.))," ","",.)
		local varname = "prod_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v704-v803 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Compensation & Benefits Rating (","",.)),")","",.))," ","",.)
		local varname = "comp_ben_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v804-v903 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Diversity & Labor Rights Rating (","",.)),")","",.))," ","",.)
		local varname = "div_lab_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v904-v1003 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Training, Health & Safety Rating (","",.)),")","",.))," ","",.)
		local varname = "train_hlth_safe_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v1004-v1103 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Energy & Climate Change Rating (","",.)),")","",.))," ","",.)
		local varname = "enrgy_climchge_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v1104-v1203 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Board Rating (","",.)),")","",.))," ","",.)
		local varname = "board_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v1204-v1303 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Leadership Ethics Rating (","",.)),")","",.))," ","",.)
		local varname = "ldrship_ethics_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v1304-v1403 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Transparency & Reporting Rating (","",.)),")","",.))," ","",.)
		local varname = "trans_report_rtg`date'"
		rename `v' `varname'
	}

	*	c)	Reshape
	drop in 1

	reshape long over_pct_rank cmty_rtg emp_rtg gov_rtg com_dev_phl_rtg humrts_supchain_rtg ///
		prod_rtg comp_ben_rtg div_lab_rtg train_hlth_safe_rtg enrgy_climchge_rtg ///
		board_rtg ldrship_ethics_rtg trans_report_rtg, i(firm) j(date) string

	*Destring numerics	
	foreach v of varlist over_pct_rank cmty_rtg emp_rtg gov_rtg com_dev_phl_rtg ///
		humrts_supchain_rtg prod_rtg comp_ben_rtg div_lab_rtg train_hlth_safe_rtg ///
		enrgy_climchge_rtg board_rtg ldrship_ethics_rtg trans_report_rtg {
		replace `v'="" if `v'=="NA"
		destring `v', replace
	}

	gen check = max(over_pct_rank, cmty_rtg, emp_rtg, gov_rtg, com_dev_phl_rtg, humrts_supchain_rtg, prod_rtg, comp_ben_rtg, div_lab_rtg, train_hlth_safe_rtg, enrgy_climchge_rtg, board_rtg, ldrship_ethics_rtg, trans_report_rtg)
	drop if check==.
	drop check
	compress

	*	d)	Append
	capt noisily append using `file1'
	tempfile file1
	save `file1'
}

*Generate date variables
gen datenum=date(date,"MY")
gen month=month(datenum)
gen year=year(datenum)
order datenum, after(date)

*	Save unique firm dates
bysort firm date: gen N=_N
tab N
/*. tab N

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    855,620       99.97       99.97
          2 |        248        0.03      100.00
------------+-----------------------------------
      Total |    855,868      100.00
*/
tab firm if N>1
/*
. tab firm if N>1

                   CSRHub Official Name |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
            Embratel Participacoes S.A. |         58       23.39       23.39
                     RHB Capital Berhad |        190       76.61      100.00
----------------------------------------+-----------------------------------
                                  Total |        248      100.00
*/
bysort firm date: gen n=_n
drop if n>1	/* 	Appear to have duplicates for all obs of Embratel Participacoes S.A.
				and RHB Capital Berhad. Duplicates need to be dropped for merge	*/

drop N

bysort firm date: gen N=_N
tab N
/*. tab N

          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    855,744      100.00      100.00
------------+-----------------------------------
      Total |    855,744      100.00
*/
drop n N


*	e)	Save
gen in_other_vars=1
compress
save "OTHER-VARIABLES-ALL.dta", replace


***	CSRHub+Dashboard+CSR_ESG+Research--2017-06-12-updating data from march 2017 to sept 2017-________.csv
set more off
local files : dir "" files "*updating data*.csv"

local n=1

foreach file of local files {
	display("`file'")
	import delimited "`file'", clear ///
	varnames(13)
	
	* 	b)	Rename and label variables with variable names from first row
	*Label
	foreach v of varlist * {
		local varlab = `v'[1]
		label var `v' "`varlab'"
	}
	
	*Rename
	rename (getresultsinthesecells v4 v5) (firm ticker isin)
	drop enteryourdatainthesecells v2
	
	foreach v of varlist v6-v12 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Overall Rating (","",.)),")","",.))," ","",.)
		local varname = "over_rtg`date'"
		rename `v' `varname'
	}
	
	foreach v of varlist v13-v19 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Overall Percentile Rank (","",.)),")","",.))," ","",.)
		local varname = "over_pct_rank`date'"
		rename `v' `varname'
	}

	rename (v20 v21) (industry country)

	foreach v of varlist v22-v28 {
		local date = subinstr((subinstr((subinstr(`v'[1],"# of Sources Used in Rating (","",.)),")","",.))," ","",.)
		local varname = "num_sources`date'"
		rename `v' `varname'
	}

	drop v29-v35
	
	foreach v of varlist v36-v42 {
	local date = subinstr((subinstr((subinstr(`v'[1],"Industry Average Rating (","",.)),")","",.))," ","",.)
	local varname = "industry_avg_rtg`date'"
	rename `v' `varname'
	}

	foreach v of varlist v43-v49 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Employees Rating (","",.)),")","",.))," ","",.)
		local varname = "emp_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v50-v56 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Environment Rating (","",.)),")","",.))," ","",.)
		local varname = "enviro_rtg`date'"
		rename `v' `varname'
	}
	
	foreach v of varlist v57-v63 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Governance Rating (","",.)),")","",.))," ","",.)
		local varname = "gov_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v64-v70 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Community Dev & Philanthropy Rating (","",.)),")","",.))," ","",.)
		local varname = "com_dev_phl_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v71-v77 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Human Rights & Supply Chain Rating (","",.)),")","",.))," ","",.)
		local varname = "humrts_supchain_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v78-v84 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Product Rating (","",.)),")","",.))," ","",.)
		local varname = "prod_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v85-v91 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Compensation & Benefits Rating (","",.)),")","",.))," ","",.)
		local varname = "comp_ben_rtg`date'"
		rename `v' `varname'
	}

	foreach v of varlist v92-v98 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Diversity & Labor Rights Rating (","",.)),")","",.))," ","",.)
		local varname = "div_lab_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v99-v105 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Training, Health & Safety Rating (","",.)),")","",.))," ","",.)
		local varname = "train_hlth_safe_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v106-v112 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Energy & Climate Change Rating (","",.)),")","",.))," ","",.)
		local varname = "enrgy_climchge_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v113-v119 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Environment Policy & Reporting Rating (","",.)),")","",.))," ","",.)
		local varname = "enviro_pol_rpt_rtg`date'"
		rename `v' `varname'
	} 
	foreach v of varlist v120-v126 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Resource Management Rating (","",.)),")","",.))," ","",.)
		local varname = "resource_mgmt_rtg`date'"
		rename `v' `varname'	
	}	
	foreach v of varlist v127-v133 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Board Rating (","",.)),")","",.))," ","",.)
		local varname = "board_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v134-v140 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Leadership Ethics Rating (","",.)),")","",.))," ","",.)
		local varname = "ldrship_ethics_rtg`date'"
		rename `v' `varname'
	}
	foreach v of varlist v141-v147 {
		local date = subinstr((subinstr((subinstr(`v'[1],"Transparency & Reporting Rating (","",.)),")","",.))," ","",.)
		local varname = "trans_report_rtg`date'"
		rename `v' `varname'
	}

	*	c)	Reshape
	drop in 1
	drop if firm==""
	
	reshape long over_rtg over_pct_rank num_sources industry_avg_rtg emp_rtg ///
		enviro_rtg gov_rtg com_dev_phl_rtg humrts_supchain_rtg prod_rtg comp_ben_rtg ///
		div_lab_rtg train_hlth_safe_rtg enrgy_climchge_rtg enviro_pol_rpt_rtg ///
		resource_mgmt_rtg board_rtg ldrship_ethics_rtg trans_report_rtg, i(firm) j(date) string

	*Destring numerics	
	foreach v of varlist over_rtg over_pct_rank num_sources industry_avg_rtg emp_rtg ///
		enviro_rtg gov_rtg com_dev_phl_rtg humrts_supchain_rtg prod_rtg comp_ben_rtg ///
		div_lab_rtg train_hlth_safe_rtg enrgy_climchge_rtg enviro_pol_rpt_rtg ///
		resource_mgmt_rtg board_rtg ldrship_ethics_rtg trans_report_rtg {
		replace `v'="" if `v'=="NA"
		destring `v', replace
	}

	gen check = max(over_rtg , over_pct_rank , industry_avg_rtg , emp_rtg , enviro_rtg , gov_rtg , com_dev_phl_rtg , humrts_supchain_rtg , prod_rtg , comp_ben_rtg , div_lab_rtg , train_hlth_safe_rtg , enrgy_climchge_rtg , enviro_pol_rpt_rtg , resource_mgmt_rtg , board_rtg , ldrship_ethics_rtg , trans_report_rtg)
	drop if check==.
	drop check
	compress

	*	d)	Append
	capt noisily append using `file1'
	tempfile file1
	save `file1'
}

*Generate date variables
gen datenum=date(date,"MY")
gen month=month(datenum)
gen year=year(datenum)
order datenum, after(date)

*	Keep unique firm date
bysort firm date: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    120,645       99.97       99.97
          2 |         42        0.03      100.00
------------+-----------------------------------
      Total |    120,687      100.00
*/

bysort firm date: gen n=_n
tab n
/*
          n |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    120,666       99.98       99.98
          2 |         21        0.02      100.00
------------+-----------------------------------
      Total |    120,687      100.00
*/

/*	THESE ALL APPEAR TO BE EXACT DUPLICATES SO I DROP THE DUPLICATES	*/
drop if n>1
drop N n

*	Rename variables for appending to other CSRHub datasets
rename (isin ticker) (ISIN Ticker)

*	e)	Save
gen in_2017_update=1
label var in_2017_update "(CSRHub) =1 if in 2017 data downloaded in early 2018"
compress
save "UPDATE-2017.dta", replace

*/

						***=========================*
						*							*
						*	Merge CSRHub datasets	*
						*							*
						***=========================*
/*	LAST RUN MARCH 9 2018 (LINES 553-794)
						
set more off
***	OVERALL RATINGS
use data/csrhub-raw/OVERALL-ENVIRO.DTA, clear
bysort firm date: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    512,381      100.00      100.00
------------+-----------------------------------
      Total |    512,381      100.00
*/
drop N

*	Merge other variables file
merge 1:1 firm date using "data/csrhub-raw/OTHER-VARIABLES-ALL.dta", nogen
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       348,985
        from master                     2,811  (_merge==1)
        from using                    346,174  (_merge==2)

    matched                           509,570  (_merge==3)
    -----------------------------------------
*/

*	Merge data update
append using "data/csrhub-raw/UPDATE-2017.dta"

bysort firm date: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    952,891       97.31       97.31
          2 |     26,330        2.69      100.00
------------+-----------------------------------
      Total |    979,221      100.00
*/
tab date if N>1
/*
         date |      Freq.     Percent        Cum.
--------------+-----------------------------------
    March2017 |     26,330      100.00      100.00
--------------+-----------------------------------
        Total |     26,330      100.00
*/
drop N
*Keep the observations in the more recent March 2017 download
drop if date=="March2017" & in_2017_update!=1
*(13,344 observations deleted)

bysort firm date: gen N=_N
tab N
/*
          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    965,877      100.00      100.00
------------+-----------------------------------
      Total |    965,877      100.00
*/
drop N

foreach v of varlist in_* {
	replace `v' = 0 if `v'==.
}

***	Fill in missing variables
*	Industry
gsort firm -industry
by firm: gen ind_ch=(industry!=industry[_n-1]) if industry!="" & industry[_n-1]!=""
by firm: replace industry=industry[_n-1] if industry=="" & _n!=1 /* Confirm no industry changes in data	*/
drop ind_ch

*	Country
gsort firm -country
by firm: gen ctry_ch=(country!=country[_n-1]) if country!="" & country[_n-1]!=""
by firm: egen c=sum(ctry_ch)
/*	Reveals these country variable inconsistencies:
		United States and USA
		Taiwan, Province of China and Taiwan
		South Korea and Korea, Republic of
		South Korea and Korea
		Macau and Macao
*/
drop ctry_ch c

replace country="United States" if country=="USA"
replace country="Taiwan, Province of China" if country=="Taiwan"
replace country="Korea, Republic of" if country=="South Korea"
replace country="Korea, Republic of" if country=="Korea"
replace country="Macao" if country=="Macau"

by firm: gen ctry_ch=(country!=country[_n-1]) if country!="" & country[_n-1]!=""
by firm: egen c=sum(ctry_ch)
drop ctry_ch c
/*	All country changes accounted for. All were changes in spelling of same country	*/

gsort firm -country
by firm: replace country=country[_n-1] if country=="" & _n!=1

***	Save
sort firm datenum
order firm date board_rtg cmty_rtg com_dev_phl_rtg comp_ben_rtg div_lab_rtg ///
	emp_rtg enrgy_climchge_rtg enviro_pol_rpt_rtg enviro_rtg gov_rtg ///
	humrts_supchain_rtg industry_avg_rtg ///
	ldrship_ethics_rtg over_pct_rank over_rtg prod_rtg resource_mgmt_rtg ///
	train_hlth_safe_rtg trans_report_rtg Ticker ISIN country industry datenum month year ///
	in_other_vars in_ovrl_enviro 

*Label
label var board_rtg "(CSRHub) Board Rating"
label var cmty_rtg "(CSRHub) Community Rating"
label var com_dev_phl_rtg "(CSRHub) Community Development and Philanthropy Rating"
label var comp_ben_rtg "(CSRHub) Compensation and Benefits Rating"
label var country "(CSRHub) Firm Country Location"
label var date "(CSRHub) Ratings Date"
label var datenum "(CSRHub) Numerical Stata Value for Day"
label var div_lab_rtg "(CSRHub) Diversity and Labor Rights Rating"
label var emp_rtg "(CSRHub) Employee Rating"
label var enrgy_climchge_rtg "(CSRHub) Energy and Climate Change Rating"
label var enviro_pol_rpt_rtg "(CSRHub) Environmental Policy and Reporting Rating"
label var enviro_rtg "(CSRHub) Environmental Rating"
label var firm "(CSRHub) Official Company Name"
label var gov_rtg "(CSRHub) Governance Rating"
label var humrts_supchain_rtg "(CSRHub) Human Rights and Supply Chain Rating"
label var in_other_vars "(CSRHub) =1 if in OTHER VARIABLES file"
label var in_ovrl_enviro "(CSRHub) =1 if in OVERALL ENVIRONMENT RESOURCEMGMT csv"
label var industry "(CSRhub) Industry Classification"
label var industry_avg_rtg "(CSRHub) Industry Average over_rtg"
label var ISIN "(CSRHub) ISIN"
label var ldrship_ethics_rtg "(CSRHub) Leadership Ethics Rating"
label var month "(CSRHub) Data Month"
label var num_sources "(CSRHub) Number of Sources for Calculating Overall Rating"
label var over_rtg "(CSRHub) Overall Rating"
label var over_pct_rank "(CSRHub) Overall Percentile Rank"
label var prod_rtg "(CSRHub) Product Rating"
label var resource_mgmt_rtg "(CSRHub) Resource Management Rating"
label var Ticker "(CSRHub) Firm Ticker Symbol"
label var train_hlth_safe_rtg "(CSRHub) Training and Health and Safety Rating"
label var trans_report_rtg "(CSRHub) Transparency and Reporting Rating"
label var year "(CSRHub) Data Year"

*	Create variables
encode firm,gen(firm_n)
gen ym=ym(year,month)
label var firm_n "(CSRHub) Firm Encoded as Numerical"
label var ym "(CSRHub) Year-Month Date Value"

gen tic_csrhub = Ticker
label var tic_csrhub "(CSRHub) ticker"

gen in_csrhub=1
label var in_csrhub "(CSRHub) =1 if in csrhub data"


*	Set panel
xtset firm_n ym, m

by firm_n: gen csrhub_first = (_n==1)
label var csrhub_first "(CSRHub) =1 for year-month of firm's first appearance in data"

by firm_n: gen n = _n
by firm_n: gen N = _N
by firm_n: gen csrhub_last = (N - n == 0)
drop n N
label var csrhub_last "(CSRHub) =1 for year-month of firm's last appearance in data"

gen csrhub_cr = (date=="March2017")
label var csrhub_cr "(CSRHub) =1 if firm in last year-month of CSRHub data (right censor)"
gen csrhub_cl = (date=="December2008")
label var csrhub_cl "(CSRHub) =1 if firm in first year-month of CSRHub data (left censor)"

*	Rename and order
rename Ticker ticker
rename ISIN isin

order in_*, last

*	Label data
label data "CSRHub Data December 2008 - September 2017"

*	Create CSRHub row id
gen row_id_csrhub=_n
label var row_id_csrhub "(CSRHub) Unique row identifier"

						***===================***
						*						*
						*	Merge iso3 codes	*
						*						*
						***===================***
replace country="Jersey" if country=="Channel Islands"
/*	Channel Islands are known as Jersey	*/
replace country="Iran, Islamic Republic of" if country=="Iran"
replace country="Cote d'Ivoire" if country=="Ivory Coast"
replace country="Macedonia, the Former Yugoslav Republic of" if country=="Macedonia"
replace country="Moldova, Republic of" if country=="Moldova"
replace country="Norway" if country=="NORWAY"
replace country="Palestine, State of" if country=="Palestine"
replace country="Syrian Arab Republic" if country=="Syria"
replace country="Trinidad and Tobago" if country=="Trinidad & Tobago"
replace country="Viet Nam" if country=="Vietnam"

merge m:1 country using "data/country-codes-iso3-conversion.dta", ///
	keepusing(A3UN)
/* 
    Result                           # of obs.
    -----------------------------------------
    not matched                         2,390
        from master                     2,273  (_merge==1)
        from using                        117  (_merge==2)

    matched                           963,604  (_merge==3)
    -----------------------------------------
*/
	
label var A3UN "(United Nations) 3-digit country code"
order A3UN,after(country)
rename A3UN a3un
	
drop if _merge==2
drop _merge


*	Standardize firm names
preserve
keep firm
bysort firm: gen n=_n
keep if n==1
drop n
stnd_compname firm, gen(stnd_firm entity_type)
tempfile d1
save `d1'
restore
merge m:1 firm using `d1', nogen


*	Save
compress
save data/csrhub-all.dta, replace
*/


		***=======================================================***
		*															*
		*				Merge CSRHub and COMPUSTAT 					*
		*			North America Fundamental Quarterly 			*
		*		Note CSTAT is quarterly; CSRHub is monthly			*
		*															*
		***=======================================================***
set more off
/*
***	Load data
use data/cstat-quarterly-data-tickers.dta, clear					/*	Need to start with all CSTAT data?	*/

***	DELETE UNNEEDED COLUMNS
drop add1 add2 add3 add4 bsprq busdesc consol county datafmt ein fax finalq ///
	indfmt ogmq pdateq phone popsrc staltq state stko 

***	Standardize firm names
stnd_compname conm, gen(stnd_firm)
label var stnd_firm "standardized firm name from conm"

foreach var of varlist * {
    local lab `: var label `var''
    label var `var' "(CSTAT) `lab'"
}

***	Rename to match CSRHub
replace stnd_firm="DOLLAR TREE STORES" if stnd_firm=="DOLLAR TREE"
replace stnd_firm="DOMINION ENERGY PLC" if stnd_firm=="DOMINION ENERGY"


*	Merge variables for Tobin's Q
merge 1:1 tic datadate fyearq fqtr using data/CSTAT-variables-for-tobin-q.dta
drop if _merge==2
drop _merge 

*	Merge variables for return on equity
merge 1:1 tic datadate fyearq fqtr using data/CSTAT-variables-for-return-on-equity.dta
drop if _merge==2
drop _merge


*	Merge liabilities variables
merge 1:1 tic datadate fyearq fqtr using data/CSTAT-variables-for-liabilities.dta
drop if _merge==2
drop _merge


***	Save
compress
save data/cstat-quarterly-data-tickers-stnd_firm.dta, replace

*/

***	Load data with standardized firm name
use data/cstat-quarterly-data-tickers-stnd_firm.dta, clear

/*	
***	DROP INVESTMENT FUNDS														/*	May 11, 2018: Unsure I need this block anymore	*/
*	Dropping SIC 6722 and 6726 because these cause many mismatches with CSRHub tickers
drop if sic=="6722" | sic=="6726"
*(13,701 observations deleted)
*/

keep stnd_firm conm tic datadate cusip

gen in_cstat=1
label var in_cstat "(CSTAT) Indicator=1 if in CSTAT data"
gen id_cstat=_n
label var id_cstat "(CSTAT) Unique obs id in cstat-quarterly-data-tickers-stnd_firm.dta"

gen cal_yr=year(datadate)
gen cal_m=month(datadate)
gen ym=ym(cal_yr,cal_m)

bysort tic ym: gen N=_N
tab N
/*          N |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    351,730       99.92       99.92
          2 |        294        0.08      100.00
------------+-----------------------------------
      Total |    352,024      100.00
*/
keep if N==1
drop N

label var cal_yr "(CSTAT) Year from datadate variable"
label var cal_m "(CSTAT) Month from datadate variable"
label var ym "(CSTAT) Year-month combination from datadate variable"

gen ticker=tic
rename tic tic_cstat
label var ticker "(CSTAT) Ticker"

*	Temp save
compress
tempfile cstat
save `cstat'


***	MERGE
*	Load data
use data/csrhub-all.dta, clear

gen id_csrhub=_n
label var id_csrhub "(CSRHub) unique obs id in csrhub-all-stnd_firm.dta"

bysort stnd_firm ticker ym: gen N=_N
drop if over_rtg==. & N==2
drop N
bysort stnd_firm ticker ym: gen N=_N 
drop if country=="Philippines" & N==2											/*	Drops a bank with locations in Philippines and United States	*/
drop N

keep stnd_firm firm ticker ym id_csrhub in_csrhub

merge 1:1 stnd_firm ticker ym using `cstat', nogen
/*    Result                           # of obs.
    -----------------------------------------
    not matched                     1,184,283
        from master                   892,142  
        from using                    292,141  

    matched                            73,282  
    -----------------------------------------
*/
compress

order stnd_firm firm conm ticker tic_cstat
sort stnd_firm ticker ym

replace in_cstat=0 if in_cstat==.
replace in_csrhub=0 if in_csrhub==.

bysort stnd_firm: egen coverage=max(in_csrhub)
label var coverage "(CSRhub) =1 if firm ever rated by CSRHub"




*	Match with full CSRHub dataset
merge m:1 firm ym using data/csrhub-all.dta, nogen
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       292,629
        from master                   292,176  
        from using                        453  

    matched                           965,424  
    -----------------------------------------
*/

replace coverage=1 if coverage==.

*	Match with full CSTAT dataset
merge m:m cusip datadate using data/cstat-quarterly-data-tickers-stnd_firm.dta, nogen
/*    Result                           # of obs.
    -----------------------------------------
    not matched                       906,590
        from master                   892,595  
        from using                     13,995  

    matched                           351,730  
    -----------------------------------------
*/

replace coverage=0 if coverage==.

label var stnd_firm "Standardized firm name from CSTAT and CSRHub"

***	CREATE DEPENDENT VARIABLES
/*	Definitions
		ROA (Net income / total assets)
		ROS (Net income / total sales)
		ROE (Net income / equity book value (assets minus liabilities))
		Tobin's q (Equity market value + debt market value) / (Equity book value + debt book value)
		MTB (Equity market value / equity book value)
		MVA (Equity market value – book value of equity and debt)
		
		
CSTAT variables (quarterly)														http://finabase.blogspot.nl/2011/03/ratios-values-and-other-instruments.html
	ROA 		= niq / atq
	ROS 		= niq / saleq
	ROE			= niq / seqq
	TOBIN'S Q	= mkvaltq + lt / [(atq - ltq) + lt] where lt = lctq + dlttq + loq + txditcq									https://finabase.blogspot.com/2013/05/tobins-q-ratio-what-is-and-where-can-i.html
	MTB			= mkvaltq / seqq												market-to-book is the same as Tobin's Q
	MVA			= mkvaltq - (seqq + dlttq)										market value added

Note market value of equity = prccq * cschoq	
Note book value of equity = atq - ltq
Note book value of equity also = seqq											///	seqq does not appear to be reliable. there are some values of 0.001 that appear wrong when compared to atq - ltq
	
See https://guan.dk/market-value-equity to estimate market value of equity
*/

gen roaq = niq / atq
gen rosq = niq / saleq
gen rosy = niy / saley
gen roeq = niq / (atq-ltq)

replace mkvaltq=prccq*cshoq if mkvaltq==.

gen lt = lctq + dlttq + loq + txditcq
gen tobinq = mkvaltq + lt / [(atq - ltq) + lt]									

gen mtbq = mkvaltq / (atq-ltq)
*gen mva = mkvaltq - mkvaltq - (seqq + dlttq)									///	Not sure this is right


***	SAVE
compress
save data/csrhub-cstat.dta, replace





						***===================================***
						*										*
						*	Merge KLD data with CSRHub-CSTAT	*
						*										*
						***===================================***
set more off
/*
***	STANDARDIZE KLD FIRM NAMES
use data/kld-all-clean.dta, clear

bysort firm: gen n=_n
keep if n==1
stnd_compname firm, gen(stnd_firm entity_type)

keep firm stnd_firm
label var stnd_firm "(KLD) Standardized firm name"

merge 1:m firm using data/kld-all-clean.dta, nogen
/*    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                            50,762  (_merge==3)
    -----------------------------------------
*/
compress
save data/kld-stnd_firm.dta
*/



use data/kld-stnd_firm.dta, clear

gen in_kld=1
label var in_kld "(KLD) =1 if in kld data"
gen firm_kld=firm
label var firm_kld "(KLD) firm name"
gen ticker_kld=ticker
label var ticker_kld "(KLD) ticker"
gen year_kld=year
label var year_kld "(KLD) year"


tempfile kld
save `kld'

use "data/csrhub-cstat.dta", clear
merge m:1 stnd_firm ticker year using `kld', nogen
/*    Result                           # of obs.
    -----------------------------------------
    not matched                     1,108,259
        from master                 1,074,494  (_merge==1)
        from using                     33,765  (_merge==2)

    matched                           183,861  (_merge==3)						///	Seems low
    -----------------------------------------
*/
compress

replace in_csrhub=0 if in_csrhub==.
replace in_cstat=0 if in_cstat==.
replace in_kld=0 if in_kld==.

/*	Create single date variable for all observations using:
	-CSRHub:	ym
	-CSTAT:		datadate
	-KLD:		year_kld
*/
gen csrdate=dofm(ym)
format csrdate %td

gen year_all = year(csrdate)
replace year_all=year_kld if year_all==.
replace year_all=year(datadate) if year_all==.

gen month_all = month(csrdate)

drop csrdate

label var year_all "(ALL) year"	
label var month_all "(ALL) month"

label data "CSRHub-CSTAT-KLD 1991 - 2017"

order stnd_firm year_all month_all
sort stnd_firm year_all month_all

*	Save
compress
save data/CSRHub-CSTAT-KLD.dta, replace



						***===================================***
						*										*
						*		Merge with FACTIVA media		*
						*										*
						***===================================***
set more off

use data/CSRHub-CSTAT-KLD.dta, clear

rename year year_csrhub
gen year=year_all

merge m:1 year using C:\Dropbox\Projects\Papers-Working\dissertation-csrhub\project\data\factiva-stakeholder-type-by-year-media-subset.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                            68
        from master                        57  (_merge==1)
        from using                         11  (_merge==2)

    matched                         1,292,028  (_merge==3)
    -----------------------------------------
*/
drop if _merge!=3
drop _merge

compress
save data/CSRHub-CSTAT-KLD-FACTIVA.dta, replace



capt log close
