					*analysis_lcfs_mw3 includes programmes doing expenditure shares
					*Needs gor10cd to fit with APS
					// This file creates LCFS data, from dvper, rawper, dvhh & rawhh files //
				* this version retains the standard errors of the predicted values of the random effects.
				* these are used in working out the variance of the welfare measure
					
					*LINE 256 USES RESULTS OF FITTED STUFF
					clear all
					set more off
					set maxvar 32000, perm
				clear matrix
				clear programs
					*SRS
					global data "P:/Working/analysis/data"
					global output "P:/Working/analysis/output"
					global tables "P:/Working/KlemowMeasure"

				global matrix "P:/Working/KlemowMeasure/matrices"
				do "$tables/matout"
				do "$tables/matin"
				*Here I read in the computed value of alpha, the share of private consumtption in the total
				matin alpha using "$matrix\alpham"

					*get hhold LCFS
					*use "$output/lcfs_covariates", clear
				*	use "$output/aps_lcfs_appended", replace
					* this file does not show utlas E0600058 and E0600059
					use "$output/aps_lcfs_appended22Jun23", replace
					* this file is recoded to show utlas E0600058 and E0600059
				su pwta18
				scalar q=r(sum)
				scalar list q
					cap drop hhid hmem
				*replace lprivconseq=lprivconseq+log(52)

				*convert to annual basis since jones and klenow work with annual data
				*constant for utility function in j&k is 5, But they do consumption in dollars so assume £1=$1.4
					sort finyear caseno
					gen double hhidx=floor(caseno/100) if lprivconseq==.
					gen qage=200-age
					sort hhidx relhrp6
					by hhidx: gen hmem=_n
					format caseno %20.0g
					format hhidx %20.0g
					*Here I set a065 to be age of hrp consistent with consumption model
					*I use the age of the person with the lowest number to be hrp
					by hhidx: egen qhrp=min(relhrp6)
					by hhidx: gen qerr=1 if qhrp>0 & _n==1 
					replace a065=. if relhrp6>qhrp

					by hhidx: replace a065=a065[1] if relhrp6>=qhrp & lprivconseq==.
					*note that there are "Households" which do not have heads. Have assumed that these take the age of the person with the loweest relhrp6
					* also some under 18s listed as heads with this mechanism. 
					*hhidx: replace a065=a065[1] if relhrp6>0 & lprivconseq==.

					tabulate gor10cd finyear, missing
				*	replace catage=a065
					table finyear [pw=weightac], c(sum privcons mean privcons p50 privcons) format(%15.2fc)
				*	su bstot
*put in OECD scale
				gen oecd_scale=0.7 if lprivconseq==.
				replace oecd_scale=1 if hrp==1
				replace oecd_scale=0.5 if age<16
				sort hhidx
				by hhidx: egen oecdsize=total(oecd_scale)
				by hhidx: replace oecdsize=1 if oecdsize<1
				egen oecdsum=total(oecdsize)

				su pwta18 if lprivconseq==. & age>=18
				scalar wtsum=r(sum)
				scalar list wtsum

				table finyear if lprivconseq==.  & age>=18 [pw=pwta18], c(sum pop) format(%15.0fc)



					sort msoa11cd gor10cd
					by msoa11cd: replace gor10cd=gor10cd[_n-1] if _n>1
					*Ensure that all msoas get correct region. First values were checked
				*	replace a065=5 if a065>0 & a065<5 /* aggregate all under 30*/
				*	replace a065=17 if a065>17 & a065<25 /* aggregate all 85+*/
				*	lab define a065 5 "under 30 years" 6 "30 but under 35 years" 7 "35 but under 40 years" 8 " 40 but under 45 years" 9 "45 but under 50 years" 10 ///
				*	 "50 but under 55 years" 11 "55 but under 60 years" 12 "60 but under 65 years" 13 "65 but under 70 years" 14 "70 but under 75 years" 15 "75 but under 80 years" ///
				*	 16 "80 but under 85 years" 17 "85 years or more", replace
				*	lab val a065 a065
				su work2
					quietly{
					tabulate a065, gen(agedummy)
					cap drop gor1-gor11
					tabulate gor, gen(gor)
					tabulate ltla19cd, gen(ltladum)
					}
	eststo clear
	******************Estimate model used to generate consumption figures. this is a mixed model with random effects for age, region and ltla
	* household log private consumption is explained by log net income, electricity use and log mean house price in each msoa
	*eststo: mixed lprivconseq lnetinc  lelect_avg lhp_mean || _all: R.a065 || _all : R.gor
	*eststo: mixed lprivconseq lnetinc  lelect_avg lhp_mean || _all: R.a065 || _all : R.gor10cd ||ltla19cd: if lprivconseq<.
	eststo: mixed lprivconseq lnetinc  lelect_avg lhp_mean || _all: R.a065 || _all : R.gor10cd || ltla19cd: if lprivconseq<.
	mat bcons=e(b)
	mat Vcons=e(V)
	**********Save parameter matrid and its variance
matout bcons using "$matrix\bcons", replace
matout Vcons using "$matrix\Vcons", replace

		*eststo: mixed lprivconseq lnetinc  lelect_avg lhp_mean || a065:
		cap drop xfit xbfit resa* counth fcree
	*	predict xfit if work2<., fit
	*****************Generate fitted values and random effects etc for people in APS component of the file. 
		predict xbfit if work2<., xb
		predict resa* if work2<., reffects

		predict fcerr if work2<., stdp
	predict fcree1 fcree2 fcree3 if work2<., reses
* the lines below give the standard errors of the prediced values of the three random effects

	mat wcons=e(b)
scalar sec=wcons[1,8]
scalar vca=exp(2*sec)
scalar vcage=wcons[1,5]
scalar vcage=exp(2*vcage)
scalar vcgor=wcons[1,6]
scalar vcgor=exp(2*vcgor)
scalar vcla=wcons[1,7]
scalar vcla=exp(2*vcla)
scalar list vcage vcgor vcla
	sort a065 resa1
    by a065: replace resa1=resa1[1] if resa1==. & work2<. /* note that this loses 86 people because the hrp is aged <18*/
	sort gor10cd resa2
    by gor10cd: replace resa2=resa2[1] if resa2==. & work2<.
	sort ltla19cd resa3
    by ltla19cd: replace resa3=resa3[_n-1] if resa3==. & work2<.
	by ltla19cd: egen counth=count(resa3)
	replace resa3=0 if counth==0 & work2<.
* this sets area random effects to zero if no data are observed. It ensures that imputations take place for the areas for which there are no LFCS data
	gen xcfit=xbfit+resa1+resa2 if work2<.

	su xcfit
table ltla19nm, c( count xcfit  count work2 count resa2 count resa1 count resa3)











	replace sumhrs=. if sumhrs<0	// total actual hours in main & 2nd job //
****Extra code by MW 10th June and 22nd June
gen leisuremw=leisure /* leisure is already a share of the total week*/
matin alpha using "$matrix\alpham"
matin thetam using "$matrix\thetam"
scalar theta=thetam[1,1]
*read in theta- coefficient on lesiure term
* derived in theta_calculations.do
*mat thetam=theta
*matout thetam using "$matrix\thetam", replace
*Estimate model of work variable
gen work2mw=theta*((1-leisuremw)^2)/2
*Estimate labour model for men
eststo: mixed work2mw lnetinc  lelect_avg lhp_mean || _all: R.a065 || _all : R.gor10cd|| ltla19cd: if sex==1
*	predict lfit1 if lprivconseq==. & sex==1, fit
	predict lbfit1  if lprivconseq==. & sex==1, xb
	predict lesa1*  if lprivconseq==. & sex==1, reffects
	predict flerr1 if lprivconseq==. & sex==1, stdp
	****Calculate fitted values and random effects
predict flmree1 flmree2 flmree3 if lprivconseq==. & sex==1., reses
	mat blmen=e(b)
	mat Vlmen=e(V)
matout blmen using "$matrix\blmen", replace
matout Vlmen using "$matrix\Vlmen", replace
*Save coefficents and their variance for future use. 
	*lesa11 is age term, lesa12 is gor term lesa13 is ltla term
table a065, c(mean lesa11 sd lesa11 count lesa11)
table gor10cd, c(mean lesa12 sd lesa12 count lesa12)
mat wl1=e(b)
scalar sel1=wl1[1,8]
scalar vl1a=exp(2*sel1)
scalar vl1age=wl1[1,5]
scalar vl1age=exp(2*vl1age)
scalar vl1gor=wl1[1,6]
scalar vl1gor=exp(2*vl1gor)
scalar vl1la=wl1[1,7]
scalar vl1la=exp(2*vl1la)

su xcfit
******************Same thing for women***************************************
eststo: mixed work2mw lnetinc  lelect_avg lhp_mean || _all: R.a065 || _all : R.gor10cd|| ltla19cd: if sex==2
*mixed work2mw lnetinc  lelect_avg lhp_mean || _all: R.ages || _all : R.gor10cd, technique(bfgs 1 dfp 1 nr 1) difficult
*estimates save apsequation_nomsoa, replace
*This does not converge so is left out.
*	predict lfit2 if lprivconseq==. & sex==2, fit
	mat blwomen=e(b)
	mat Vlwomen=e(V)
matout blwomen using "$matrix\blwomen", replace
matout Vlwomen using "$matrix\Vlwomen", replace

	predict lbfit2  if lprivconseq==. & sex==2, xb
	predict lesa2*  if lprivconseq==. & sex==2, reffects
	predict flerr2 if lprivconseq==. & sex==2, stdp
	predict flfree1 flfree2 flfree3 if lprivconseq==. & sex==2., reses

*lesa11 is age term, lesa12 is gor term lesa13 is ltla term
*extract the variances of the effects.
	mat wl2=e(b)
scalar sel2=wl2[1,8]
scalar vl2a=exp(2*sel2)
scalar vl2age=wl2[1,5]
scalar vl2age=exp(2*vl2age)
scalar vl2gor=wl2[1,6]
scalar vl2gor=exp(2*vl2gor)
scalar vl2la=wl2[1,7]
scalar vl2la=exp(2*vl2la)
scalar list vl2age vl2gor vl2la

*wcons, wl1 and wl2 store the three sets of coefficients. We can use the cluster variances in the subsequent calculations of standard errors
	table a065, c(mean lesa21 sd lesa21 count lesa21)
table gor10cd, c(mean lesa22 sd lesa22 count lesa22)
*put in survival probabilities
su xcfit
gen vc=vca
gen vl1=vl1a
gen vl2=vl2a
scalar vcr1=exp(2*wcons[1,5])
scalar vcr2=exp(2*wcons[1,6])
scalar vcr3=exp(2*wcons[1,7])
scalar vl1r1=exp(2*wl1[1,5])
scalar vl1r2=exp(2*wl1[1,6])
scalar vl1r3=exp(2*wl1[1,7])
scalar vl2r1=exp(2*wl2[1,5])
scalar vl2r2=exp(2*wl2[1,6])
scalar vl2r3=exp(2*wl2[1,7])
gen vcr1=vcr1
gen vcr2=vcr2
gen vcr3=vcr3
gen vl1r1=vl1r1
gen vl1r2=vl1r2
gen vl1r3=vl1r3
gen vl2r1=vl2r1
gen vl2r2=vl2r2
gen vl2r3=vl2r3
* these convert the variances into variables which are then stored by the save command

esttab using "$tables/mixedJun23.tex", tex replace
*Save the table showing the models
esttab, tex
*save "$output/aps_lcfs_with_fitted_vals", replace
*save "$output/aps_lcfs_with_fitted_vals11Apr23", replace
cap drop gor
gen gor =gor10cd
cap drop _merge

save "$output/aps_lcfs_with_fitted_vals22Jun23", replace
*save the file for use in analysis_redo_tables22Jun23.do
exit
