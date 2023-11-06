*DOES MEN
*This programme uses the demographic variables calculated from the ONS life expectancy tables to compute the variance matrices for qx and qxw.
matrix drop _all
matrix a=J(1,19,0.5)
matrix a=0.1,a
matrix x=J(1,18,5)
matrix x=1,4,x
* x is number of years each period lasts. There are data for first year of life, the next four years of life and then in 5-year blocks. The top age band is 90+
*a is average fraction of period survived by each decedent. assumed to be half of period except in first year of life when average survival of each decedent is only 0.1 year
import excel using "P:\Working\KlemowMeasure\DemographicsLTLA14-16", sheet("Sheet3") cellrange(BE4:BX318)  clear
*read in number of life years L
mkmat BE-BX, mat(L)
import excel using "P:\Working\KlemowMeasure\DemographicsLTLA14-16", sheet("Sheet4") cellrange(F4:Y318)  clear
*read in lx
mkmat F-Y, mat(lx)
mat lxp=J(315,20,0)
mat lxp[1,1]=lx[1...,2...]
*lxp is lx advanced one period
import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("DeathsLTLA") cellrange(E5:X319)  clear
* read in number of deaths
mkmat E-X, mat(Deaths)
import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("PopLTLA") cellrange(H3:AA317)  clear
* read in population
mkmat H-AA, mat(Pop)
* in fact I infer mx from the ONS tables instead of working it out from the data to whcih I had access.
*matout L using "P:\Working\KlemowMeasure\matrices\lcap.txt", replace
*import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("GGH") cellrange(A2:V150)  
use "P:\Working\KlemowMeasure\GGHLTLAmen", clear 
* read in prevalence of good health
mkmat C-V, mat(HP)
* the two files below are produced in "UTLA_GGH to LTLA_GGH.do"
use "P:\Working\KlemowMeasure\UnweightedLTLAmen", clear 
* read in the uneweighted base number of observations used by ONS in its calculations. See appendix D.1
mkmat C-V, mat(uwb)
use "P:\Working\KlemowMeasure\deffLTLAmen", clear
* read in the design effect 
mkmat C-V, mat(deff)


*MUST CONVERT UNWEIGHTED AND DEFF TO LTLA
*input data are saved as matrices and then converted back to variables using svmat
*ren A ltla19cd
*ren B ltla19nm
svmat uwb
svmat deff
svmat HP
svmat L
svmat Deaths
svmat Pop
svmat lx
svmat lxp
forvalues k=1/20{
cap gen Healthy_Years`k'=L`k'*HP`k'
replace lx`k'=lx`k'/100000
replace lxp`k'=lxp`k'/100000
replace L`k'=L`k'/100000
}
* calculate survival probabilities from lx and use this to recalculate life years as Lx based on sheet 4 values
drop B-V
gen lxx1=1
forvalues j=1/20{
	gen px`j'=lxp`j'/lx`j'
	*px is probability of surviving in period j
*	gen mx`j'=Deaths`j'/Pop`j'
	scalar aj=a[1,`j']
	scalar xj=x[1,`j']
gen qx`j'=1-px`j'
*qx is probability of death in period j
gen mx`j'=qx`j'/(xj*(1-qx`j'*(1-aj)))
*mx is mortality rate
*	gen qx`j'=xj*mx`j'/(1+xj*(1-aj)*mx`j')
*see equation 17 of appendix D2
	gen varqx`j'=(xj^2*mx`j'*(1-aj*xj*mx`j'))/(Pop`j'*(1+(1-aj)*xj*mx`j')^3)
	* variance of qx
*	gen px`j'=1-qx`j'
	forvalues k=1/`j'{
		if `k'==`j'-1{
scalar ak=a[1,`k']
	scalar xk=x[1,`k']
	*lxx is lx as derived from px for checking
		gen lxx`j'=lxx`k'*px`k'		
	gen Lx`k'=xk*(lx`j'+ak*(lx`k'-lx`j'))		
		}
	}
}

*gen Lx20=lx20/mx20
gen Lx20=L20
replace mx20=lx20/Lx20
gen lex=Lx20
forvalues k=1/19{
*	replace Lx`k'=L`k'
	replace lex=lex+Lx`k'
}

replace varqx20=4/(Deaths20*mx20^2)
*see equation 18 of appendix D.2
gen n=_n
save "P:\Working\KlemowMeasure\ltladatamen.dta",replace
**save demographic data on men by LTLA
**********DO THE SAME THING FOR WOMEN
matrix drop _all
matrix a=J(1,19,0.5)
matrix a=0.1,a
matrix x=J(1,18,5)
matrix x=1,4,x
import excel using "P:\Working\KlemowMeasure\DemographicsLTLA14-16", sheet("Sheet3") cellrange(BE322:BX636)  clear
mkmat BE-BX, mat(Lw)
import excel using "P:\Working\KlemowMeasure\DemographicsLTLA14-16", sheet("Sheet4") cellrange(F322:Y636)  clear
mkmat F-Y, mat(lxw)
mat lxwp=J(315,20,0)
mat lxwp[1,1]=lxw[1...,2...]
import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("DeathsLTLA") cellrange(E324:X638)  clear
mkmat E-X, mat(Deathsw)
import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("PopLTLA") cellrange(H322:AA636)  clear
mkmat H-AA, mat(Popw)
/*
import excel using "P:\Working\KlemowMeasure\DemographicsLTLA", sheet("Sheet3") cellrange(BE324:BX638)  clear
mkmat BE-BX, mat(Lw)
import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("DeathsLTLA") cellrange(E324:X638)  clear
mkmat E-X, mat(Deathsw)
import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("PopLTLA") cellrange(H322:AA636)  clear
mkmat H-AA, mat(Popw)
*/
*matout L using "P:\Working\KlemowMeasure\matrices\lcap.txt", replace
*import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("GGH") cellrange(A2:V150)  
use "P:\Working\KlemowMeasure\GGHLTLAwomen", clear
mkmat C-V, mat(HPw)

use "P:\Working\KlemowMeasure\UnweightedLTLAwomen", clear 
mkmat C-V, mat(uwbw)
use "P:\Working\KlemowMeasure\deffLTLAwomen", clear 
mkmat C-V, mat(deffw)


*ren A ltla19cd
*ren B ltla19nm
svmat uwbw
svmat deffw
svmat HPw
svmat Lw
svmat Deathsw
svmat Popw
svmat lxw
svmat lxwp

*forvalues k=1/20{
*cap gen Healthy_Yearsw`k'=Lw`k'*HPw`k'
*}
drop B-V
*gen lxw1=1
*****
forvalues k=1/20{
cap gen Healthy_Yearsw`k'=Lw`k'*HPw`k'
replace lxw`k'=lxw`k'/100000
replace lxwp`k'=lxwp`k'/100000
replace Lw`k'=Lw`k'/100000
}

gen lxxw1=1
forvalues j=1/20{
	gen pxw`j'=lxwp`j'/lxw`j'
*	gen mx`j'=Deaths`j'/Pop`j'
	scalar aj=a[1,`j']
	scalar xj=x[1,`j']
gen qxw`j'=1-pxw`j'
gen mxw`j'=qxw`j'/(xj*(1-qxw`j'*(1-aj)))
*	gen qx`j'=xj*mx`j'/(1+xj*(1-aj)*mx`j')
	gen varqxw`j'=(xj^2*mxw`j'*(1-aj*xj*mxw`j'))/(Popw`j'*(1+(1-aj)*xj*mxw`j')^3)
*	gen px`j'=1-qx`j'
	forvalues k=1/`j'{
		if `k'==`j'-1{
scalar ak=a[1,`k']
	scalar xk=x[1,`k']
		gen lxxw`j'=lxxw`k'*pxw`k'		
	gen Lxw`k'=xk*(lxw`j'+ak*(lxw`k'-lxw`j'))		
		}
	}
}

*gen Lx20=lx20/mx20
gen Lxw20=Lw20
replace mxw20=lxw20/Lxw20

*****
/*
forvalues j=1/20{
	gen mxw`j'=Deathsw`j'/Popw`j'
	scalar aj=a[1,`j']
	scalar xj=x[1,`j']
	gen qxw`j'=xj*mxw`j'/(1+xj*(1-aj)*mxw`j')
	gen varqxw`j'=(xj^2*mxw`j'*(1-aj*xj*mxw`j'))/(Popw`j'*(1+(1-aj)*xj*mxw`j')^3)
	gen pxw`j'=1-qxw`j'
	forvalues k=1/`j'{
		if `k'==`j'-1{
scalar ak=a[1,`k']
	scalar xk=x[1,`k']
		gen lxw`j'=lxw`k'*pxw`k'		
	gen Lxw`k'=xk*(lxw`j'+ak*(lxw`k'-lxw`j'))		
		}
	}
}
*/
*gen Lxw20=lxw20/mxw20
gen lexw=Lxw20
forvalues k=1/19{
*	replace Lx`k'=L`k'
	replace lexw=lexw+Lxw`k'
}

replace varqxw20=4/(Deathsw20*mxw20^2)
gen n=_n
save "P:\Working\KlemowMeasure\ltladatawomen.dta",replace
exit

***********END OF WOMEN SECTION SECTION
