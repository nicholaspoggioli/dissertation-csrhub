***=====================================================***
*	CHAPTER 3 DATA ANALYSIS
*	FIRM-YEAR LEVEL DATASET COMBINING
*		CSRHUB/CSTAT AND KLD
***=====================================================***

					***===========***
					*	LOAD DATA	*
					***===========***
use data/csrhub-cstat-kld-matched.dta, clear

xtset



***	Recode net concerns to negative
replace net_kld_con = net_kld_con*-1






///	MODELS
























*END
