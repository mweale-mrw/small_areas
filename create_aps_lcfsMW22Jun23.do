*This programme puts together the household data set used for the work. It draws on two input files- the LCFS combined into a single file and ETB (effects of taxes and benefits)
* the data used are for 2015/16

	// This appends household LCFS data to individual APS data //
	* at line 214 it does some recoding because lad19 differ from ltla19
	clear all
	set more off
	set maxvar 32000, perm

	*SRS
		global tables "P:/Working/KlemowMeasure"

	global data "P:/Working/analysis/data"
	global output "P:/Working/analysis/output"
	global dofiles "P:/Working/analysis/dofiles"
	global matrix "P:/Working/KlemowMeasure/matrices"
	*matin and matout are routines that store matrices
	do "$tables/matout"
	do "$tables/matin"
	*we work only with financial year 2015-2016
	use  "$output/etb0515", clear

	*get LCFS (hhold)
	*use "$output/lcfs_dvhh", clear
	*REPLACED WITH LINE BELOW TO GET SCALED DATA
	*We compbine data from lcfs and etb 
	use "$output/lcfs_small_dv21", clear 

	keep if finyear==2015 
	*gen totex=0
	*forvalues j=1/87{
	*	replace totex=totex+scoicop`j'
	*	}
	*I assume that person 1 is the househodl reference person. The hrp set seemed incomplete
			gen totex=scoicoptotal if person==1
			* total household expenditure. Expenditure figures are on a household basis. 
	*	ren case caseno
	*	ren age a065
		cap drop hrp
		gen hrp=person if person==1

		replace totex=. if hrp~=1
		ren case caseno
	*	ren age a065
	*merge ETB
	merge m:1 caseno finyear using "$output/etb0515"
	*merge with ETB data. These use the same case numbers
	keep if _merge==3
	drop _merge
	***REDO WEIGHTS
	su weighta if hrp==1
	scalar sigwthh=r(sum)
	scalar sigwt=??
	*SRS required me to remove this which was rescaling the weights to give the total nubmer of households shown in APS
	* put in weighted sum of hrp from APS for 2015. At least 50000 observations

	su weighta if hrp==1 & totex<.
	scalar sigwtcons=r(sum)
	scalar fac=sigwtcons/sigwt
	scalar list sigwt sigwtcons fac
	gen weightac=weighta/fac if totex<.
	gen weightad=weighta*sigwt/sigwthh 
	total weightad if hrp==1
	*BECAUSE SAMPLE IS A BIT SMALLER THAN public LFCS we scale weighta
	*BECAUSE DATA ARE LOST WE NEED FURther RESCALING WITH CONSUMPTION
	*weightac is weights for consumption data
	*weightad is weights for demographic data
	*drop unwanted LCFS/ETB vbles
	keep finyear caseno weighta hhold msoa* /*p600t-p612t*/ age oecdsc gor* educa totnhsa hrp totex weightac weightad
	*******
	*recode ages
	egen a0=cut(age), at(0,18,30,35,40,45,50,55,60,65,70,75,80,85,110)
	recode a0 (18=5) (30=6) (35=7) (40=8) (45=9) (50=10) (55=11) (60=12) (65=13) (70=14) (75=15) (80=16) (85=17), gen(a065)
	lab define a065 5 "under 30 years" 6 "30 but under 35 years" 7 "35 but under 40 years" 8 " 40 but under 45 years" 9 "45 but under 50 years" 10 ///
	 "50 but under 55 years" 11 "55 but under 60 years" 12 "60 but under 65 years" 13 "65 but under 70 years" 14 "70 but under 75 years" 15 "75 but under 80 years" ///
	 16 "80 but under 85 years" 17 "85 years or more", replace
	lab val a065 a065
	*******
	replace a065=. if hrp~=1
	/*egen a0=cut(age), at(0,18,30,35,40,45,50,55,60,65,70,75,80,85,110)
	recode a0 (18=5) (30=6) (35=7) (40=8) (45=9) (50=10) (55=11) (60=12) (65=13) (70=14) (75=15) (80=16) (85=17), gen(a065)
	lab define a065 5 "under 30 years" 6 "30 but under 35 years" 7 "35 but under 40 years" 8 " 40 but under 45 years" 9 "45 but under 50 years" 10 ///
	 "50 but under 55 years" 11 "55 but under 60 years" 12 "60 but under 65 years" 13 "65 but under 70 years" 14 "70 but under 75 years" 15 "75 but under 80 years" ///
	 16 "80 but under 85 years" 17 "85 years or more", replace



	replace a065=a0
	lab val a065 a065*/
	*check these ages
	*Here I drop Scotland	 and Northern Ireland and Wales
	drop if gorx>9	
	*drop if gor==11

	*create gor10cd

	gen gor10nmm = "East Midlands" if gorx==4
	replace gor10nmm = "East of England" if gorx==6
	replace gor10nmm = "London" if gorx==7
	replace gor10nmm = "North East" if gorx==1
	replace gor10nmm = "North West" if gorx==2
	replace gor10nmm = "South East" if gorx==8
	replace gor10nm = "South West" if gorx==9
	replace gor10nmm = "Wales" if gorx==10
	replace gor10nmm = "West Midlands" if gorx==5
	replace gor10nmm = "Yorkshire and The Humber" if gorx==3
*note that Wales is not used and Mersey is included with the North-West
	*encode gor10nm, gen(gor10cd)
	table gorx
	gen gor10cd="E12000001" if gorx==1
	replace gor10cd="E12000002" if gorx==2
	replace gor10cd="E12000003" if gorx==3
	replace gor10cd="E12000004" if gorx==4
	replace gor10cd="E12000005" if gorx==5
	replace gor10cd="E12000006" if gorx==6
	replace gor10cd="E12000007" if gorx==7
	replace gor10cd="E12000008" if gorx==8
	replace gor10cd="E12000009" if gorx==9
	*merge govtor mapping wtih msoa codes
	merge m:1 msoa11cd using "$output/msoa11cd_govtor_mapping"
	tabulate gor10cd finyear, missing
	keep if _merge==3

	drop _merge

	*merge TTWA Not subsequently used
	merge m:1 msoa11cd using "$output/msoa_ttwa_mapping"
	tabulate gor10cd finyear, missing
	keep if _merge==3
	tabulate gor10cd finyear, missing
	drop _merge

	*merge local authority codes
	*merge m:1 msoa11cd using "$output/msoa_lad17_mapping"
	*link msoa codes with local authority (ltla) codes
	merge m:m msoa11cd using "$output/msoa_lad19_mapping"
	* note that m:1 fails because psuedo Northern Ireland is in twice. But we do not use that
	keep if _merge==3
	drop _merge

	*merge LTLA level LE data
	clonevar ltla19cd = lad19cd
	merge m:1 ltla19cd finyear using "$output/ons life expectancy at birth"	
	drop if _merge==2
	drop _merge
* These data were  not used. 
	*merge Upper tier local authority (UTLA) codes
	merge m:1 ltla19cd using "$output/ons_ltla_utla_mapping"
	drop if _merge==2
	drop _merge

	*merge life expectancy & healthy life expectancy at UTLA level
	merge m:1 utla19cd finyear using "$output/ons life expectancy and hle"
	drop if _merge==2
	drop _merge
* these data were not used
	*merge 2011 covariate data by MSOA (covariates are for england & wales only)
	merge m:1 msoa11cd using "$output/covariates" /* NB. gas and eletricity use are 2011 data but house prices are 2015 data*/
	drop if _merge==2
	drop _merge
	tabulate gor10cd finyear, missing

	*merge PAYE+benefits data (for 2015/16)
	merge m:1 msoa11cd finyear using "$output/cov_dwp_paye_benefits_msoa_mw290422"
	keep if _merge==3
	drop _merge

	gen data = "lcfs"

	*approximate log of mean PAYE+benefits income by averaging log of decile points
	gen lnetinc = (ln(netinc_10p)+ln(netinc_20p)+ln(netinc_30p)+ln(netinc_40p)+ln(netinc_50p) ///
	+ln(netinc_60p)+ln(netinc_70p)+ln(netinc_80p)+ln(netinc_90p))/9

	*rename expenditure data
	/*
	foreach i in p600t p601t p602t p603t p604t p605t p606t p607t p608t p609t p610t p611t p612t {
		local j = `j'+1
		ren `i' exp`j'
		}
	*total is in exp1. Add 1 to coicop codes
	/* COICOP 12
	1 = Food & non-alcoholic bev
	2 = Alc bev & tobacco 
	3 = Clothing & footwear
	4 = Housing, water, gas, elect & other fuels
	5 = Furnishings, hhold equip & routine maintenance of house
	6 = Health
	7 = Transport
	8 = Communications
	9 = Recreation & culture
	10 = Education
	11 = Restaurants & hotels
	12 = Misc goods & services
	*/
	*/
	*create annual expenditure

	*egen catage=cut(a065), at(18,30,40,50,65,80,100)
	*replace catage=a065
	*forval i = 1/13 
	*	gen double exp`i'a = exp`i'*52.1775
	*	}

	*total coicop 12 expenditure
	*here I scale household expenditure to be consistent with the national accounts figures for household consumption. 
	su totex [aw=weightac]
		scalar totexa=r(sum)*1000000
		scalar nacons=1200589000000 /* macro-ecoomics data from spreadsheets loaded in to SRS. Total household consumption from national accounts*/
		replace totex=totex*nacons/totexa
		**************
	gen privcons = totex*1000
	gen aprivcons=privcons
	mean aprivcons [pw=weightac]
	scalar qq=r(sum)
	scalar list qq
	gen lcons=ln(privcons)


	table finyear [pw=weightac], c(sum privcons mean privcons p50 privcons) format(%15.2fc)
	*table year [pw=weighta], c(sum privcons mean privcons p50 privcons) format(%15.2fc)

	*create budget shares for each of the 12 coicop cateogories
	 /*forval i = 2/13 {
		gen bs`i' = exp`i'/privcons
		}

	egen bstot = rowtotal(bs2-bs13), missing
	su bstot
	*/
	*count no. of hholds in each psu 
	bys finyear msoa11cd: egen casebypsu = count(case)
	tab casebypsu


	*log total equiv consumption
gen lprivconseq = ln(privcons/oecdsc) 
gen lpubcons=ln((educa+totnhsa)/oecdsc)
gen lprivcons = ln(privcons)
*This generages log of private consumption per household after adjusting for household size using the oecd scale. 
* the public consumption figures are not used since it is later assumed that this is evenly spread across adults.

clonevar ageband_hrp = a065
replace 	ageband_hrp=5 if a065>0 & a065<5 /* aggregate all under 30*/
replace ageband_hrp=17 if a065>17 & a065<25 /* aggregate all 85+*/
table ageband_hrp finyear if finyear>2012, c(mean lprivcons)
table ageband_hrp finyear if finyear>2012, c(mean lprivconseq sem lprivconseq)


cap tabulate gor, gen(gora)
gen gv=gora1

foreach i in gas_avg elect_avg hp_mean {
	gen l`i' = ln(`i')
	}
	
codebook msoa11cd
tabulate gor10cd finyear, missing
save "$output/temp", replace
*This saves the expenditure data file for subsquent appending

********************************************************************************
******************************** APS *******************************************
********************************************************************************
use "$output/aps", clear
keep if finyear==2015
egen a0=cut(age), at(0,18,30,35,40,45,50,55,60,65,70,75,80,85,110)
recode a0 (18=5) (30=6) (35=7) (40=8) (45=9) (50=10) (55=11) (60=12) (65=13) (70=14) (75=15) (80=16) (85=17), gen(a065)
lab define a065 5 "under 30 years" 6 "30 but under 35 years" 7 "35 but under 40 years" 8 " 40 but under 45 years" 9 "45 but under 50 years" 10 ///
 "50 but under 55 years" 11 "55 but under 60 years" 12 "60 but under 65 years" 13 "65 but under 70 years" 14 "70 but under 75 years" 15 "75 but under 80 years" ///
 16 "80 but under 85 years" 17 "85 years or more", replace
lab val a065 a065

*drop Scotland & NI
drop if govtof>=12
* Note that the APS gives gor9cd which merges Mersey with the North-West and gor10cd which separatea them
*for consistency with the lcfs we use gor9cd. The programme initially got this wroong so we simply rename gor9cd gor10cd
ren govtof gor
lab def gor 1 "North East" 2 "North West" 3 "Merseyside" 4 "Yorkshire and the Humber" ///
5 "East Midlands" 6 "West Midlands" 7 "Eastern" 8 "London" 9 "South East" 10 "South West" 11 "Wales" 
lab val gor gor
drop if gor9d=="S99999999"
drop if gor9d=="W99999999"

su work2
cap drop gor10cd
ren gor9d gor10cd
*drop gor10cd
*encode gor10nm, gen(gor10cd)
*drop gor10nm
tabulate gor10cd
*merge TTWA (2011 codes. Drop ttwa9d - don't know what vintage this is) NOT USED SUSEQUENTLY
merge m:1 msoa11cd using "$output/msoa_ttwa_mapping"
keep if _merge==3
drop _merge ttwa9d
su work2
*merge Local authority codes
*merge m:1 msoa11cd using "$output/msoa_lad17_mapping"
merge m:m msoa11cd using "$output/msoa_lad19_mapping"
* note that m:1 fails because psuedo Northern Ireland is in twice. But we do not use that
drop if _merge==2

drop _merge

*Some ltla codes had changed 
replace lad19cd="E06000058" if lad19cd=="E06000028"
replace lad19cd="E06000058" if lad19cd=="E06000029"
replace lad19cd="E06000058" if lad19cd=="E07000048"
replace lad19cd="E06000059" if lad19cd=="E07000049"
replace lad19cd="E06000059" if lad19cd=="E07000050"
replace lad19cd="E06000059" if lad19cd=="E07000051"
replace lad19cd="E06000059" if lad19cd=="E07000052"
replace lad19cd="E06000059" if lad19cd=="E07000053"
replace lad19cd="E07000246" if lad19cd=="E07000190"
replace lad19cd="E07000246" if lad19cd=="E07000191"
replace lad19cd="E07000245" if lad19cd=="E07000201"
replace lad19cd="E07000245" if lad19cd=="E07000204"
replace lad19cd="E07000244" if lad19cd=="E07000205"
replace lad19cd="E07000244" if lad19cd=="E07000206"


*merge LTLA level LE data
clonevar ltla19cd = lad19cd
merge m:1 ltla19cd finyear using "$output/ons life expectancy at birth"	
drop if _merge==2
drop _merge
*merge Upper tier local authority (UTLA) codes
merge m:1 ltla19cd using "$output/ons_ltla_utla_mapping"	
tabulate ltla19cd sex, missing
*Shows which utla each ltla is in

drop if _merge==2
drop _merge

*merge life expectancy & healthy life expectancy at UTLA level. NOT USED because we subsequently obtained data by age band
merge m:1 utla19cd finyear using "$output/ons life expectancy and hle"
drop if _merge==2
drop _merge

su work2
*merge 2011 covariate data by MSOA (covariates are for england & wales only)
merge m:1 msoa11cd using "$output/covariates" /* NB. this is 2011 data, but is merged onto every year here */
keep if _merge==3
drop _merge
***su work2
*merge PAYE+benefits data (for 2015/16)
merge m:1 msoa11cd finyear using "$output/cov_dwp_paye_benefits_msoa_mw290422"
*Here I align to the covariates for each MSOA. The mean of log income is approximated as before. 
gen lnetinc = (ln(netinc_10p)+ln(netinc_20p)+ln(netinc_30p)+ln(netinc_40p)+ln(netinc_50p) ///
+ln(netinc_60p)+ln(netinc_70p)+ln(netinc_80p)+ln(netinc_90p))/9
foreach i in gas_avg elect_avg hp_mean {
	gen /*Z*/l`i' = ln(`i')
	}

	keep if _merge==3
drop _merge
*su work2
*merge Upper tier local authority (UTLA) codes
merge m:1 ltla19cd using "$output/ons_ltla_utla_mapping"	
keep if _merge==3
drop _m
su work2

*merge life expectancy & healthy life expectancy at UTLA level. Not used subsequently
merge m:1 utla19cd finyear using "$output/ons life expectancy and hle"
keep if _merge==3
drop _m

gen data = "aps"

table finyear [pw=pwta18], c(sum pop) format(%15.0fc)

*append LCFS
append using "$output/temp"
order finyear msoa11cd data
*ren gor9d gor10cd
*replace gor10cd=gor10cdx if gor10cd==.
* this merges in the government office region names
merge m:1 gor10cd using "$output/region_gor10"
keep if _merge==3
*drop _merge
*and saves the combined data set for use in analysis_lcfs_mw22Jun23.do


save "$output/aps_lcfs_appended22Jun23", replace
	








		