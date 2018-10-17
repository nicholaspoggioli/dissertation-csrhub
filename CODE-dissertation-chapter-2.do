********************************************************************************
*Title: Dissertation Chapter 2 Exploratory Data Analysis
*Created by: Nicholas Poggioli (poggi005@umn.edu)
*Created on: October 2018
*Purpose: Analyze KLD and CSRHub data
********************************************************************************
					***=======================***
					*	  SUMMARY STATISTICS	*
					*	  		 KLD			*
					***=======================***

*	Summary
asdoc sum sum*str sum*con, save(figures/summary-stats-kld-by-sic2)

*	Correlations
corr sum*str, means
corr sum*con, means

doc corr sum*str sum*con, means	
