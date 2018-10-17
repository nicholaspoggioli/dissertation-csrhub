********************************************************************************
*Title: Dissertation data creation and cleaning
*Created by: Nicholas Poggioli (poggi005@umn.edu)
*Created on: October 2018
*Purpose: Create and clean data for dissertation

********************************************************************************

					*******************************
					***		  DATA CREATION		***
					*******************************

					
///		KLD


///		COMPUSTAT


///		MERGE KLD AND COMPUSTAT


///		CSRHUB
					
///		MERGE KLD/CSTAT WITH CSRHUB

*use data/kld-cstat-bs2012.dta, clear
/*	firm:		firm name
	year:		year
	ticker:		ticker
*/

use data/csrhub-all.dta, clear
/*	firm:		firm name
	year:		year
	ticker:	ticker
*/

bysort ticker year: gen n=_n
keep if n==1

keep firm year ticker tic_csrhub in_csrhub

tempfile csrh
save `csrh'

merge 1:1 ticker year using data/kld-cstat-bs2012.dta
/*    Result                           # of obs.
    -----------------------------------------
    not matched                        85,835
        from master                    55,163  (_merge==1)
        from using                     30,672  (_merge==2)

    matched                            18,997  (_merge==3)
    -----------------------------------------
*/
