	clear 
	clear mata
	********* WORK FROM HERE TO SAVE TIME
	**************************
	clear programs
	clear matrix
	set maxvar 32000, perm
	global output "P:/Working/KlemowMeasure"
	global matrix "P:/Working/KlemowMeasure/matrices"
	do "$output/matout"
	do "$output/matin"
	*Here I read in the share of private consumption in the total and the consant term in the utility function
	matin alpham  using "$matrix/alpham"
matin uconstm  using "$matrix/uconstm"

	scalar drop _all
	scalar healthw=0.75
	*healthw is the weight on life years in poor health relative to those in good health. 
	* revised from 0.8 after lookign at Parker (Health Economics, 2021)
	mat healthwt=healthw
	matout healthwt using "$matrix\healthwt", replace
	mat drop healthwt
	use "$output/ltladatamen.dta", clear
	sort ltla19cd
	merge 1:1 ltla19cd using "$output/ltladatawomen.dta"
	*these read in the demographic data for men and women by ltla
	drop _merge
*	replace utla19cd="E10000002" if utla19cd=="E06000060"
	*replace utla19cd="E10000034" if utla19cd==" "
*merge 1:1 ltla19cd using "$output/utlalist.dta" 
*	drop _merge
* the demographic data are merged with the data created in analysis_lcfs_mw22Jun23.do
	merge 1:m ltla19cd using "P:/Working/analysis/output/aps_lcfs_with_fitted_vals22Jun23"
	*take out Wales
ren gor gov10cd
	*replace gor with gor10cd. Merges Mersyside and NW
gen gor=0
	replace gor=1 if gor10cd=="E12000001"
	replace gor=2 if gor10cd=="E12000002"
	replace gor=3 if gor10cd=="E12000003"
	replace gor=4 if gor10cd=="E12000004"
	replace gor=5 if gor10cd=="E12000005"
	replace gor=6 if gor10cd=="E12000006"
	replace gor=7 if gor10cd=="E12000007"
	replace gor=8 if gor10cd=="E12000008"
	replace gor=9 if gor10cd=="E12000009"

	gen qstring=strpos(ltla19cd, "W")
	table qstring
	drop if qstring==1
	*drops Wales and any data with sex missing
	drop if sex==.
replace adults=. if age<20
* weight using population aged 20 and over since welfare measure starts at 20
	*fcree1 fcree2 fcree3 are standard errors of age, gor and ltla effects in consumption
	*flmree1 flmree2 flmree3  does labour residuals of age, gor and ltla effects for men
	*flfree1 flfree2 flfree3 does labour residuals of age, gor and ltla effects for women

	* no data for city of London or Scilly Isles E09000001 and E0600053
	
	*use "P:/Working/analysis/output/aps_lcfs_with_fitted_vals", clear
	*the idiosyncratic variances
*	scalar      vca =  .32687034
*	scalar       vl1a =  .38519751
*	scalar       vl2a =  .20872423
	drop if work2mw==.
	*Ensure we work only with data from APS
*	drop if gor==11 /* Wales already dropped*/
	keep n a065 ltla19nm ltla19cd utla19cd utla19nm lad19cd lad19nm gor xcfit lbfit1 lbfit2 sex resa1-resa3 lesa11-lesa13 lesa21-lesa23 gor Healthy_Years1-Healthy_Years20 L1-L20 hrp HP1-HP20 caseno msoa11cd Healthy_Yearsw1-Healthy_Yearsw20 Lw1-Lw20 HPw1-HPw20 pwta18 casex fcree1 fcree2 fcree3 fcerr flmree1 flmree2 flmree3 flerr1 flerr2 flfree1 flfree2 flfree3 lnetinc  lelect_avg lhp_mean /*utlacod*/ adults
	ren flerr1 flmerr
	ren flerr2 flferr
	table ltla19nm, c(mean fcree1 sd fcree1 mean fcree3 sd fcree3 )

	*This generates area look-up codes  in areas_and_codes.dta 
	*bys msoa11cd: gen q=_n
	*keep if q==1
	*keep msoa11cd ltla19cd ltla19nm utla19cd utla19nm
	*save "$output/areas_and_codes.dta", replace
	*bys ltla19cd: gen q=_n
	*keep if q==1
	*keep ltla19cd ltla19nm utla19cd utla19nm
	*save "$output/ltla_areas_and_codes.dta", replace
	scalar mx=2
	*ccx just for checking and not used subsequently
	*In this section I generate scalar values for the age effects of consumption (resa1) and the labour terms (lesa11 for men and lesa21 for women). Note that the demographic data have more age groups than the consumption and APS data. So I need to set the effect for age group 20 on the demographic data equal 
	* to that for age group 19 and the term for age group 6 equal to that for age group 7. 
	forvalues k=7/19{
		su resa1 if a065==`k'-2
		scalar cc`k'=r(mean)
		scalar ccx`k'=mx+r(mean)
		*generate age effects in consumption
	* add on since cc is log (consumption)
		su lesa11 if a065==`k'-2
		scalar cm`k'=r(mean)
		su lesa21 if a065==`k'-2
		scalar cf`k'=r(mean)
		* and in leisure variable
	}
	forvalues k=20/20{
	scalar cc`k'=cc19
	scalar ccx`k'=ccx19

	scalar cm`k'=cm19
	scalar cf`k'=cf19
	}
	scalar cc6=cc7
	scalar ccx6=ccx7
	scalar cm6=cm7
	scalar cf6=cf7
	*note that demographic data show groups for 20-24 and 25-29. THey also distinguish 85-89 and 90+. So we assume that the consumption age effects are the same for 20-24 and 25-29. ALso assume same for 85-89 and 90+. Do same with leisure.
*generage random effects for regional categories. Note thath gor has a maximum value of 9
	forvalues j=1/10{
		su resa2 if gor==`j'
		scalar gorc`j'=r(mean)
		su lesa12 if gor==`j'
		scalar gorm`j'=r(mean)
		su lesa22 if gor==`j'
		scalar gorf`j'=r(mean)
	}
	sort ltla19cd
	cap drop ltlac_effect 
	cap drop ltlam_effect
	cap drop ltlaf_effect
	bys msoa11cd: egen wtsum_msoa=total(pwta18) if hrp==1
	bys msoa11cd: egen adultsum_msoa=total(pwta18) if adults==1
replace wtsum_msoa=adultsum_msoa
* I decided to weight everything by the adult count rather than the household count- in an change from earlier versions. This is because the consumption figures are adjusted for equivalence scales and are therefore effectively on a per capitla basis.
	*gives weight as number of households
	*work out what i want
	sort msoa11cd  hrp
	bys msoa11cd: replace wtsum_msoa=wtsum_msoa[1] if wtsum_msoa==.
	*puts in weight where weight is missing
	sort casex hrp
	by casex: replace wtsum_msoa=wtsum_msoa[1]
	sort ltla19cd hrp
	by ltla19cd: egen wtsum_ltla=total(pwta18) if hrp==1
	
	sort ltla19nm
	*bys ltla19nm: replace wtsum_household=wtsum_household[1] if wtsum_household==.

	bys ltla19cd: egen ltlac_effect=mean(resa3)
	bys ltla19cd: egen ltlam_effect=mean(lesa13)
	bys ltla19cd: egen ltlaf_effect=mean(lesa23)
	su fcree1 if ltla19nm== "Tamworth"
*create file which maps ltla and utla to msoa11cd
* note fitted values are done on msoas so are not constant across ltlas
collapse (mean) n xcfit lbfit1 lbfit2 ltlac_effect ltlam_effect ltlaf_effect HP1-HP20 L1-L20 Healthy_Years1-Healthy_Years20 Healthy_Yearsw1-Healthy_Yearsw20 HPw1-HPw20 Lw1-Lw20   resa3 lesa13 lesa23 wtsum_msoa gor fcree1 fcree2 fcree3 fcerr flmree1 flmree2 flmree3 flmerr flferr flfree1 flfree2 flfree3 lnetinc  lelect_avg lhp_mean /*utlacod*/ adultsum_msoa [pw=wtsum_msoa], by(msoa11cd)
*use weights for number of adults to weight within msoa

merge m:1 msoa11cd using "$output/areas_and_codes.dta"
	su fcree1 if ltla19nm== "Tamworth"
replace adultsum=adultsum_msoa/wtsum_msoa
collapse (mean)n xcfit  lbfit1 lbfit2 ltlac_effect ltlam_effect ltlaf_effect HP1-HP20 L1-L20 Healthy_Years1-Healthy_Years20  HPw1-HPw20 Lw1-Lw20 Healthy_Yearsw1-Healthy_Yearsw20  resa3 lesa13 lesa23 fcree1 fcree2 fcree3 fcerr flmree1 flmree2 /*utlacod*/ flmree3 flmerr flferr flfree1 flfree2 flfree3 wtsum_msoa gor lnetinc  lelect_avg lhp_mean (sum) adultsum_msoa [pw=wtsum_msoa], by(ltla19cd)
* and then collapse to ltla averages          
flist ltla19cd adultsum_msoa
su adultsum_msoa
scalar q=r(sum)
sort ltla19cd
replace adultsum_msoa=adultsum_msoa/q
*sort by names and check that weighting matrix is used on that basis
mkmat adultsum_msoa, mat(adultwt)
	matout adultwt using "$matrix\adultwt",  replace
*adultwt is a weighting matrix for ltlas weighted by number of adults in each.
* this is used to weight the  ltlas together to give the value of the indicator for England in programme varianceLTLA_3Apr23.do
cap drop gorc 
cap drop gorm
cap drop gorf
gen gorc=.
gen gorm=.
gen gorf=.
*note that gor does not take values above 9
forvalues j=1/11{
if gor==`j'{
	replace gorc=gorc`j'
replace gorm=gorm`j'
replace gorf=gorf`j'
}      	
}
replace xcfit=xcfit /* This is the fitted consumption data by ltla*/
*scalar uconst=3-log(1.4)
*scalar alpha=0.8095
*calculated in value of life
scalar alpha=alpham[1,1]
*REVIEW THIS
*mat alpham=alpha
scalar uconst=uconstm[1,1]
 /* from value of life programme*/
 *scalar uconst from value of life calculations
gen consterm=xcfit+resa3+gorc
*Now I split the life-tiem utility function into two components. One is independent of age and is simply multiplied by the number of life years or healthy life years.
* the other has to be multiplied by the number of life years in the relevant band before aggregating.
* utilm and utilw are the age independent terms in the life-time utility function. 9.035 is log(public and NPISH consumption per adult)
gen utilm=(uconst+9.035*(1-alpha))+(alpha*(xcfit+resa3+gorc)-(lbfit1+lesa13+gorm)) 
gen utilw=(uconst+9.035*(1-alpha))+(alpha*(xcfit+resa3+gorc)-(lbfit2+lesa23+gorf)) 
gen utilcommon=(uconst+9.035*(1-alpha))+alpha*(xcfit+resa3+gorc) /* This is the component common to men and women, and needed to get the covariances right when working out the variance of the average of men and women*/
**PUT IN AGE TERMS TO GENERATE TERMS FOR MATRIX OUTPUT
forvalues rr=6/20{
gen utilm`rr'=utilm+alpha*cc`rr'-cm`rr'
gen utilw`rr'=utilw+alpha*cc`rr'-cf`rr'
gen utilc`rr'=utilcommon+alpha*cc`rr'
}
mkmat utilm6 utilm7 utilm8 utilm9 utilm10 utilm11 utilm12 utilm13 utilm14 utilm15 utilm16 utilm17 utilm18 utilm19 utilm20, mat(utilm)
mkmat utilw6 utilw7 utilw8 utilw9 utilw10 utilw11 utilw12 utilw13 utilw14 utilw15 utilw16 utilw17 utilw18 utilw19 utilw20, mat(utilw)
mkmat utilc6 utilc7 utilc8 utilc9 utilc10 utilc11 utilc12 utilc13 utilc14 utilc15 utilc16 utilc17 utilc18 utilc19 utilc20, mat(utilc)
*gen consterm=resa3+gorc
*mkmat consterm
*matout consterm using "$matrix\consterm", replace
*matout alpham using "$matrix\alpham", replace
matout utilm using "$matrix\utilm", replace
matout utilw using "$matrix\utilw", replace
matout utilc using "$matrix\utilcommon", replace
* these are used to do the subsequent calculations again in varianceLTLA_3Apr23.do
* the rest of this programme was written before varianceLTLA_3Apr23.do was written
*the common term is needed to get the covariance between men and women right.
*initialise variables that cumulate Healthy Life Yeara and Life Years for men and women. Start in age band 6
gen HLX=Healthy_Years6/100000
gen LX=L6/100000
gen HLXw=Healthy_Yearsw6/100000
gen LXw=Lw6/100000

gen LXC=L6*alpha*cc6/100000
*gen LXCV=L6*alpha*ccx6/100000
gen LXCw=Lw6*alpha*cc6/100000
*gen LXCwV=Lw6*alpha*ccx6/100000

*put augmented consumption into both healthy and ordinary measure
gen HLXC=Healthy_Years6*alpha*cc6/100000
*gen HLXCV=Healthy_Years6*alpha*ccx6/100000
gen HLXCw=Healthy_Yearsw6*alpha*cc6/100000
*gen HLXCwV=Healthy_Yearsw6*alpha*ccx6/100000

gen LXM=L6*cm6/100000
gen HLXM=Healthy_Years6*cm6/100000
gen LXF=Lw6*cf6/100000
gen HLXF=Healthy_Yearsw6*cf6/100000
*HLX is the cumulant of healthy life years
*LX is the cumulant of life years
*HLXC and LCX are the cumulants multiplied by the age consumption effects
*HLXM and LXM are the cumulats multiplied by the age leisure effects for men
*HLXF and LXF are the cumulants multi	plied by the age lesiure effects for women
* Note that the first five demographic data bands cover those under twenty
forvalues k=7/20{
	replace LX=LX+L`k'/100000
	replace HLX=HLX+Healthy_Years`k'/100000
	replace LXw=LXw+Lw`k'/100000
	replace HLXw=HLXw+Healthy_Yearsw`k'/100000
	replace HLXC=HLXC+alpha*Healthy_Years`k'*cc`k'/100000
replace HLXCw=HLXCw+alpha*Healthy_Yearsw`k'*cc`k'/100000

	replace LXC=LXC+alpha*L`k'*cc`k'/100000
*	replace LXCV=LXCV+alpha*L`k'*ccx`k'/100000
replace LXCw=LXCw+alpha*Lw`k'*cc`k'/100000
*	replace LXCwV=LXCwV+alpha*Lw`k'*ccx`k'/100000

*	replace HLXCV=HLXCV+alpha*Healthy_Years`k'*ccx`k'/100000
*	replace HLXCwV=HLXCwV+alpha*Healthy_Yearsw`k'*ccx`k'/100000

	replace LXM=LXM+L`k'*cm`k'/100000
	replace HLXM=HLXM+Healthy_Years`k'*cm`k'/100000
	replace LXF=LXF+Lw`k'*cf`k'/100000
	replace HLXF=HLXF+Healthy_Yearsw`k'*cf`k'/100000
	}
	*utilmx, utilwx (men and women) and hutilmx and hutilwx are the values of the indicators for men and women separately. But the 
gen utilmx=utilm*LX+LXC-LXM
gen utilwx=utilw*LXw+LXCw-LXF
gen hutilmx=utilm*HLX+HLXC-HLXM+healthw*(utilm*(LX-HLX)+LXC-LXM-HLXC+HLXM)
*gen hutilmxv=utilm*HLX+HLXCV-HLXM+healthw*(utilm*(LX-HLX)+LXCV-LXM-HLXCV+HLXM)
gen hutilwx=utilw*HLXw+HLXCw-HLXF+healthw*(utilw*(LXw-HLXw)+LXCw-LXF-HLXCw+HLXF)
*gen hutilwxv=utilw*HLXw+HLXCwV-HLXF+healthw*(utilw*(LXw-HLXw)+LXCwV-LXF-HLXCwV+HLXF)
gen utilb=0.5*(utilmx+utilwx)
gen hutilb=0.5*(hutilmx+hutilwx)
*gen hutilbv=0.5*(hutilmxv+hutilwxv)
gen qutil=utilmx-hutilmx
*gen qutilv=utilmx-hutilmxv
merge m:1 ltla19cd using "$output/ltla_areas_and_codes.dta"
gen wls=strmatch(ltla19cd,"*W*")
drop if wls==1
su fcree1 if ltla19nm== "Tamworth"

*sort hutilb
gen HLXb=(HLX+HLXw)/2
*LXC > LXCw because in old age the age random effect is negative
egen mutil=mean(hutilmx)
*gen dc=(hutilmx-mutil)/(alpha*(HLX+healthwt*(LX-HLX)))
*sort dc
*gen hutilmz=hutilmx-alpha*dc*HLX-alpha*healthwt*dc*(LX-HLX)
flist ltla19nm  utilmx hutilmx utilwx hutilwx utilw6 

gen qltla19cd=_n
sort ltla19cd
keep ltla19cd ltla19nm utla19cd utla19nm  lnetinc resa3 lesa13 lesa23 lelect_avg lhp_mean fcree1 fcree2 fcree3 fcerr gor flmerr flferr flmree1 flmree2 flmree3 /* flerr1 flerr2*/ flfree1 flfree2 flfree3 /*utlacod*/ qltla19cd consterm
table ltla19nm, c(mean fcree1 mean flfree1 mean flmree1 )

save "$output/ltlameans_exog_var22Jun23", replace
*flist ltla19nm utilmx hutilmx utilwx hutilmx hutilwx HLX HLXw LX LXw 
exit
