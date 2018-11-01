use data\unique-stnd_firm-csrhub-stnd_firm-only.dta, clear

matchit idcsrhub stnd_firm using data\unique-stnd_firm-cstat-stnd_firm-only.dta, ///
	idu(idcstat) txtu(stnd_firm)
