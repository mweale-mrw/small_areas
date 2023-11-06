*This Programme evaluates the value of a life
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
