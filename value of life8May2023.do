*This Programme evaluates thav evalue of a life
	global data "P:/Working/analysis/data"
	global output "P:/Working/analysis/output"
	global dofiles "P:/Working/analysis/dofiles"
	use "$output/lcfs_small_dv21", clear 
	*It uses the file of lcfs data
	global programme "P:/Working/KlemowMeasure"
	global matrix "P:/Working/KlemowMeasure/matrices"
		scalar drop _all
		program drop _all
	do "$programme/matout"
	do "$programme/matin"
*It uses data for 2015-16
	keep if finyear==2015 
	su weighta
	*weighta is household weight in LCFS
	*forvalues j=1/87{
	*	replace totex=totex+scoicop`j'
	*	}
	* set up 
		gen totex=scoicoptotal if person==1
		ren case caseno
		ren age a065
		cap drop hrp
		gen hrp=person if person==1
		*It treats person 1 as the household reference person and merges the data with etv
	*merge ETB
				 merge m:1 caseno finyear using "$output/etb0515"
	keep if _merge==3
	drop _merge
	su weighta if hrp==1
	scalar sigwthh=r(sum)
	*Use the number of households from APS for 2015 and recaculates the weights so that the total household number aligns with this
	scalar sigwt=26951.121
	* put in weighted sum of hrp from APS for 2015
	su weighta if hrp==1 & totex<.
	scalar sigwtcons=r(sum)
	scalar fac=sigwtcons/sigwt
	*fac allows other weights to be rescaled
	scalar list sigwt sigwtcons fac
	gen weightac=weighta/fac
	gen weightad=weighta*sigwt/sigwthh
	total weightad if hrp==1

	*BECAUSE DATA ARE LOST WE NEED FURther RESCALING WITH CONSUMPTION TO ALIGN WITH NATIONAL ACCOUNTS

	* DIVIDE weighta by fac to do consumption
	su weightad if hrp==1
	scalar nhh=r(sum)
	*nhh is number of households
	*drop unwanted LCFS/ETB vbles
	table finyear [pw=weightad], c(mean totex sum totex)
	su totex [aw=weightac]
	scalar totexa=r(sum)*1000000
	scalar nacons=1200589000000
	*scale total expenditure to align with the national accoutns figure nacons
	*consration is the scaling factor
	replace totex=totex*nacons/totexa
	scalar consratio=nacons/totexa
	************
	keep finyear caseno weighta hhold msoa* /*p600t-p612t*/ a065 oecdsc gor* educa totnhsa totex adults hrp weightac weightad
	mean oecdsc if hrp==1 [pw=weightad]
	mat mn=e(b)
	mat list mn
	scalar mean_oecdsc=mn[1,1]
	su weightad if hrp==1
	scalar totweight=r(sum)
	scalar list mean_oecdsc totweight
	scalar adult_count_effective=mean_oecdsc*totweight
	mean adults [pw=weightad] if hrp==1
	mat mn=e(b)
	scalar mnn=mn[1,1]
	*mnn  is mean number of adults per household
	*totadult is total number of adults
	scalar list mnn
	scalar totadult=mnn*nhh 
	*allocat public consumption on a per adult basis
	*pubcons includes NPISH
	scalar na_pubcons=422374000000
	scalar na_pvtcons=1200589000000
	*use "C:\Users\W\OneDrive - King's College London\ESCoE\2015-16_dvhh_ukanon.dta" , clear
	*total household consumption =£1200589 in FY 2015/16. See GGEXNPISH in prices work
	*su weighta
	*scalar nhh=r(sum)
	gen numadult=adults

	*includes government and NPISH
	* these add to a plausible figure for FY 2015 consumption
	* this is worked out in teh Vlaue o Life spreadsheet in ukea200q2mw in c:\escoe reworking
	scalar pub_per_adult=na_pubcons/(totadult*1000)
	scalar pvt_per_adult=na_pvtcons/(adult_count_effective*1000)
	scalar list pub_per_adult pvt_per_adult
mean totex [pw=weightac] if hrp==1
mat cn=e(b)
scalar av_pvt_cons=cn[1,1]
*total private consumption = av per household from survey X sum of weights. 
scalar tot_pvt_cons=av_pvt_cons*nhh*1000
*scalar consnratio=na_pvtcons/tot_pvt_cons /* ratio f total na private consumption to survey figure */
scalar list consratio av_pvt_cons
egen catage=cut(a065) if hrp==1, at(18,30,35,40,45,50,55,60,65,70,75,80,85,200)
gen p600sc=(totex/oecdsc)
*total expenditure divided by oecd scaling factor	
*totex is scaled be consistent with national accounts
*replace a065=5 if a065<5
recode catage 18=1 30=2 35=3 40=4 45=5 50=6 55=7 60=8 65=9 70=10 75=11 80=12 85=13
table catage [pw=weightac], c(mean p600sc)
************
*run mixed model with age random effects so as to match model used for consumption in the main body of the work
mixed p600sc || catage:
predict age, reffects
* age is consumption age effect in each age band
table catage, c(mean age)
matrix cn=J(1,13,0)
mat cc=e(b)
scalar ccl=cc[1,1]
*ccl is consumption with age effect at zero. 
forvalues q=1/13{
quietly{
su age if catage==`q'
	
mat cn[1,`q']=(r(mean)+ccl)*1000
}
}
*cn is consumption in each age band
mat list 	cn
*add together last two life year figures. Data calculated in DemographicsLTLA14-16
*look at number of years in each age band for i) 40-year old and ii) 20-year old
mat ly=[4.98,	4.94,	4.88,	4.78,	4.64,	4.42,	4.09,	3.60,	2.87,	3.19]
mat lyy=[9.99,	4.97, 4.95,	4.93,	4.88,	4.82,	4.73,	4.59,	4.37,	4.05,	3.56,	2.84,	3.15]
*ly is life years for 40-year old contngent on surviving to 40
*lyy is life years for 20-year old. FIrst band is 20-29. Last band is 85+
mat totc=ly*cn[1,4...]' /* consumption from age of 40*/
scalar totc=totc[1,1]

mat ee=J(10,1,1)
mat ef=J(13,1,1)
mat nly=ly*ee
mat nlz=lyy*ef
scalar nlz=nlz[1,1]
scalar npubcons=nly[1,1]*pub_per_adult
scalar nly=nly[1,1]
*scalar alpha=totc/(totc+npubcons)
 mat avcons=(lyy*cn'+lyy*ef*pub_per_adult)
 * scalar avons is total consumption taking public and private together
 scalar avcons=avcons[1,1]/nlz
 scalar alpha=(avcons-pub_per_adult)/avcons

 *alpha is the share of private consumption in the total and the assumed coefficient in the utility function
scalar list

 mat alpham=J(1,1,0)
matrix alpham[1,1]=alpha
mat list alpham
*alpha is exported to be read in in the programme which evaluates well-being
matout alpham using "$matrix/alpham", replace
*read in computed value of theta
matin thetam using "$matrix/thetam"
 scalar avcons=1
 mat cn=cn/avcons
scalar pub_per_adult=pub_per_adult/avcons
mat health=[ 0.897,0.881,0.859,0.832,0.803,0.768,0.726,0.685,0.650,0.604,0.547,0.487,0.408]
*health is the share of the population in good health
*healthb starts 20-30 then in five years  and finishes at 85+. Calculated in weghted health data2015.do
*note that first three entries are not used.
mat util=J(1,13,0)
mat marg_util=J(1,13,0)
mat val_life_year=J(1,13,0)
mat wutil=J(1,13,0)
* work out tuility before dealing with leisure
**DO UTILITY WITH SCALED VALUES TO COMPARE WITH JK WORKING FROM AGE=40
mat gly=ly*diag(health[1,4...])
*gly is life years in good health ly-gly is life years in poor health. Assume 0.75 value in these
mat hly=gly+0.75*(ly-gly)
mat list hly
mat ly=hly
*Does consumption part of utility function. Also works out marginal utility of private consumption
forvalues q=4/13{
    mat util[1,`q']=alpha*log(cn[1,`q'])+(1-alpha)*log(pub_per_adult)
	mat marg_util[1,`q']=alpha/cn[1,`q']
	mat val_life_year[1,`q']=util[1,`q']/marg_util[1,`q']
	*mat wutil[1,`q']=log(cn[1,`q']+pub_per_adult)
	}
	mat list wutil
	mat list cn
	mat list util
	mat list marg_util
	mat list val_life_year
	scalar  list avcons
	scalar SU=0
	scalar SV=0
	scalar SW=0
	scalar LV=1800000/avcons
	
*	mat sum_life_year=val_life_year[1,4...]*ly[1,1...]'
*	mat list sum_life_year
		* adds up constant terms
	  
*Read in population data from annual population survey for 2015-2016
 use "P:\Working\analysis\data\aps201516.dta", clear 


*	use "C:\Users\W\OneDrive - King's College London\ESCoE\Wellbeing\apsp_jd15_eul.dta" , clear
	drop if GOVTOF>10
	*do for england only 
	replace SUMHRS=0 if SUMHRS<0
	replace SUMHRS=32 if ILODEFR==2
	*count unemployed as having disutility from working 32 hours
	replace SUMHRS=SUMHRS/112
egen catage=cut(AGE) , at(18,30,35,40,45,50,55,60,65,70,75,80,85,200)

*	replace AAG=5 if AAG==4 
	table catage SEX [pw=PWTA18], c(mean SUMHRS)
	table GOVTOF
*THIS DOES NOT WORK FOR WOMEN OR MEN
*	mixed SUMHRS if SEX==1 || catage:
*predict labagem, reffects
*mixed SUMHRS if SEX==2 || catage:, difficult
mat Work=J(1,13,0)
mat agge=[18,30,35,40,45,50,55,60,65,70,75,80,85]
forvalues kk=1/13{
	su SUMHRS if catage==agge[1,`kk'] & SEX==1
	scalar shm=r(mean)
	scalar list shm
		su SUMHRS if catage==agge[1,`kk'] & SEX==2
	scalar shf=r(mean)
	scalar list shf
mat Work[1,`kk']=(shm^2+shf^2)/2
}
*evaluate disutility of work for a couple
mat list Work
scalar SU=0
scalar SV=0
scalar SW=0
scalar thetan=thetam[1,1]
	scalar uconst=-8.64
	* uconst is chosen to give a value to life close to the figure of £1.8mn identified in the paper.
	*the value of uconst is then stored so that it can be used in teh subsequent calculations.
	*I did not see any point in iterating to exact convergence. 
*scalar uconst=-8.25	
		forvalues q=4/13{
			scalar qq=`q'-3
			scalar lyy=ly[1,qq]
*constant component of utility function divided by MU of private consumpion
	    scalar SU=SU+(ly[1,qq]*cn[1,`q']/alpha)*(uconst-0*log(1))
		*term dependent on private and public consumption divided by MU of private consumption 
		scalar SV=SV+(ly[1,qq]*cn[1,`q']/alpha)*(alpha*log(cn[1,`q'])+(1-alpha)*log(pub_per_adult))
		*term in leisure time divided by mu of private consumption
		scalar SW=SW-(thetan*lyy*Work[1,`q'])*cn[1,`q']/alpha
		**add these up for each age band from age 40+
	}
	scalar SX=SU+SV+SW
*SX is total value of life with each age band's utility given by utility divided by the marginal utility of consumption	
	scalar list SU SV SW SX LV
mat uconstm=uconst
matout uconstm using "$matrix/uconstm", replace
	
	
	