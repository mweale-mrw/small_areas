

// This appends household LCFS data to individual APS data //
* at line 214 it does some recodin because lad19 differ from ltla19
clear all
set more off
set maxvar 32000, perm

*SRS
	global tables "P:/Working/KlemowMeasure"

global data "P:/Working/analysis/data"
global output "P:/Working/analysis/output"
global dofiles "P:/Working/analysis/dofiles"
global matrix "P:/Working/KlemowMeasure/matrices"
do "$tables/matout"
do "$tables/matin"

use  "$output/etb0515", clear

*get LCFS (hhold)
*use "$output/lcfs_dvhh", clear
*REPLACED WITH LINE BELOW TO GET SCALED DATA. THIS FILE CONTAINS NATIONAL ACCOUNTS TOTALS AS WELL AS LCFS DATA  
use "$output/lcfs_small_dv21", clear 

keep if finyear==2015 
*gen totex=0
*forvalues j=1/87{
*	replace totex=totex+scoicop`j'
*	}
		gen totex=scoicoptotal if person==1
*	ren case caseno
*	ren age a065
	cap drop hrp
	gen hrp=person if person==1

	replace totex=. if hrp~=1
	ren case caseno
*	ren age a065
*merge ETB
merge m:1 caseno finyear using "$output/etb0515"
keep if _merge==3
drop _merge
***REDO WEIGHTS
su weighta if hrp==1
scalar sigwthh=r(sum)
scalar sigwt=26951.121
* put in weighted sum of hrp from APS for 2015. This is the total of the weights in the survey for hrps and the household weights in lcfs and etb are scaled to match
*the assumption is that APS gives a better household count than does LCFS 
su weighta if hrp==1 & totex<.
scalar sigwtcons=r(sum)
scalar fac=sigwtcons/sigwt
scalar list sigwt sigwtcons fac
gen weightac=weighta/fac if totex<.
gen weightad=weighta*sigwt/sigwthh 
total weightad if hrp==1

gen q=1
table q  if hrp==1 [pw=weightad], c(mean wagesala_etb sum wagesala_etb)
*nawage is total wages and salaries in national accounts.
total wagesala_etb if hrp==1 [pw=weightad]
matrix bb=e(b)
scalar totwage=bb[1,1]/1000
scalar list totwage
replace wagesala_etb=wagesala_etb*nawage	/totwage
*scale wages and salaries in ETB to fit national accounts totals 
table finyear [pw=weightad], c(sum totex mean totex) format(%15.2fc)
total totex  [pw=weightad]
matrix bb=e(b)
scalar totcons=bb[1,1]
scalar list totcons
*nacons is  total private consumption for FY 2015
replace totex=totex*nacons/totcons
* use only data from households with head a prime age worker
keep if agehrp>5 & agehrp<11 & empstat==1

sort caseno person

table q  if hrp==1 [pw=weightad], c(mean wagesala_etb sum wagesala_etb mean totex sum totex count finyear)
gen totex_sc=1000*totex
table finyear if hrp==1, c(mean totex_sc count q)
table finyear if hrp==1, c(mean wagesala_etb count q)
mean wagesala_etb totex_sc if hrp==1 [pw=weightad]
matrix bb=e(b)
matrix wagesalm=bb[1,1]
matrix consumpm=bb[1,2]
matout wagesalm using "$matrix/wagesalm", replace
matout consumpm using "$matrix/consumpm", replace
* store mean household wage and mean consumption
matin alpham using "$matrix/alpham"
*********
use "$output/aps", clear
keep if finyear==2015
egen a0=cut(age), at(0,18,30,35,40,45,50,55,60,65,70,75,80,85,110)
recode a0 (18=5) (30=6) (35=7) (40=8) (45=9) (50=10) (55=11) (60=12) (65=13) (70=14) (75=15) (80=16) (85=17), gen(a065)
lab define a065 5 "under 30 years" 6 "30 but under 35 years" 7 "35 but under 40 years" 8 " 40 but under 45 years" 9 "45 but under 50 years" 10 ///
 "50 but under 55 years" 11 "55 but under 60 years" 12 "60 but under 65 years" 13 "65 but under 70 years" 14 "70 but under 75 years" 15 "75 but under 80 years" ///
 16 "80 but under 85 years" 17 "85 years or more", replace
lab val a065 a065
*parameters for calculation of theta
*look at prime age workers

keep if a065>5 & a065<11 
mean sumhrs [pw=pwta18] if sex==1
keep if lfstat==1
mean sumhrs [pw=pwta18] if sex==1 
mat c=e(b)
*lm then lmm is share of week spent workign by prime age man measured out of 112 hours in total to allow time to sleep 
scalar lm=c[1,1]/112
mat lmm=lm
matout lmm using "$matrix/lmm", replace
mean sumhrs [pw=pwta18] if sex==2
mat c=e(b)
scalar lf=c[1,1]/112
*lfm is the same for women
mat lfm=lf
matout lfm using "$matrix/lfm", replace
* read in share of private consumption in total calculated in value of life programme
matin alpham using "$matrix/alpham"
scalar alpha =alpham[1,1]
scalar list
*lf and lm are proprotion of time working
scalar tau=0.32
*20% tax and 12% national insurance give deductions 
scalar wr=wagesalm[1,1]*2/(lfm[1,1]+lmm[1,1])
*wr is household wage ( line 87) divided by hours of woman and man
scalar list lf lm 
mat list wagesalm
* compute theta (called thetam by maximising instantaneous utility function
*see equations 6 to 9 of paper in section 5.1
scalar list wr
scalar wr=wr/(2-lfm[1,1]-lmm[1,1])
scalar list wr
scalar wr=2*alpha*(1-tau)*wr/consumpm[1,1]
scalar list wr
mat thetam=wr
mat list thetam
matout thetam using "$matrix/thetam", replace