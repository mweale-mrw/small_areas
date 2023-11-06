*this programme reads in the prevalence of good health and the unweighted base population figures and the design effect on a UTLA basis. It uses the mapping to 
* allocate these to an LTLA basis using the UTLA figures for all LTLAs within the UTLA. Men and women are handled separately. 
*areas_and_codes.dta provided by SRS to give mapping
use "P:\Working\KlemowMeasure\areas_and_codes.dta" , clear
gen k=1
sort ltla19cd
gen q=subinstr(ltla19cd,"E","0",1)
gen qq=real(q)
drop if qq==.
gen v=qq-qq[_n-1]
replace v=1 if v==.

keep if v!=0
drop k qq v msoa11cd q
flist, separator(400)
*create mapping from ltla to utla
save "P:\Working\KlemowMeasure\ltla_to_utla.dta", replace

****DO MEN
*GGH
import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("GGH") cellrange(A2:V150) clear
ren A utla19cd  
merge 1:m utla19cd using "P:\Working\KlemowMeasure\ltla_to_utla.dta"
sort ltla19cd
drop utla19cd _merge utla19nm
save "P:\Working\KlemowMeasure\GGHLTLAmen.dta", replace
*Unweighted named uwb
import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("Unweighted") cellrange(A2:V150) clear
ren A utla19cd  
merge 1:m utla19cd using "P:\Working\KlemowMeasure\ltla_to_utla.dta"
sort ltla19cd
drop utla19cd _merge utla19nm
save "P:\Working\KlemowMeasure\UnweightedLTLAmen.dta", replace
********deff
import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("deff") cellrange(A2:V150) clear
ren A utla19cd  
merge 1:m utla19cd using "P:\Working\KlemowMeasure\ltla_to_utla.dta"
sort ltla19cd
drop utla19cd _merge utla19nm
save "P:\Working\KlemowMeasure\deffLTLAmen.dta", replace
*GGHLTLAmen contains health prevalance for men allocated to LTLAs
*UnweightedLTLAmen.dta contains unweighted population figures for LTLAs. These are used to calculate the variance of health prevalence
*deffLTLAmen.dta contains the design effect allocated to LTLAs.
*drop _merge
***DO WOMEN
***GGH
import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("GGH") cellrange(A161:V309) clear
ren A utla19cd  
merge 1:m utla19cd using "P:\Working\KlemowMeasure\ltla_to_utla.dta"
sort ltla19cd
drop utla19cd _merge utla19nm
save "P:\Working\KlemowMeasure\GGHLTLAwomen.dta", replace
***Unweighted
import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("Unweighted") cellrange(A161:V309) clear
ren A utla19cd  
merge 1:m utla19cd using "P:\Working\KlemowMeasure\ltla_to_utla.dta"
sort ltla19cd
drop utla19cd _merge utla19nm
save "P:\Working\KlemowMeasure\UnweightedLTLAwomen.dta", replace
*deff
import excel using "P:\Working\KlemowMeasure\ONS Mortality.xlsm", sheet("deff") cellrange(A161:V309) clear
ren A utla19cd  
merge 1:m utla19cd using "P:\Working\KlemowMeasure\ltla_to_utla.dta"
sort ltla19cd
drop utla19cd _merge utla19nm
save "P:\Working\KlemowMeasure\deffLTLAwomen.dta", replace
