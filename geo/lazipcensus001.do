// Copyright 2011 Timothy Schwuchow
// lazipcensus001.do - creates zip code census data for 1990-2010
clear all
set mem 1g
set more off 
timer on 1 
local version 001
local filename lazipcensus`version'
local savedir "~/condo/geo/" 
local datdir "`savedir'lazip/"
log using `filename'.txt, text replace name(`filename')

// Generate 1990 race data
insheet using `datdir'la1990race.csv, c
gen zip		=	real(regexs(1)) if regexm(zipetc,"([0-9][0-9][0-9][0-9][0-9])")
egen psum	=	rowtotal(white-other)
drop if psum == 0
local rlist white black native asian other
foreach x in `rlist' {
	gen `x'1990		=	`x'/psum
	label variable `x'1990 "Percent `x' in 1990 within zipcode"
}
drop zipetc-other
duplicates drop zip, force 
sort zip

save `datdir'la1990race.dta, replace
clear 

// Generate 1990 median income data 
insheet using `datdir'la1990medhhinc.csv, c 
gen zip		=	real(regexs(1)) if regexm(zipetc,"([0-9][0-9][0-9][0-9][0-9])")
drop zipetc
rename medhhinc medhhinc1990
drop if medhhinc == 0 
label variable medhhinc1990 "Median household income, 1990"
duplicates drop zip, force 
sort zip
save `datdir'la1990medhhinc.dta, replace 
clear 

// Generate 1990 median home value data
insheet using `datdir'la1990hval.csv, c 
gen zip		=	real(regexs(1)) if regexm(zipetc,"([0-9][0-9][0-9][0-9][0-9])")
tab zip 
drop zipetc
rename medhval medhval1990
drop if medhval1990 == 0
label variable medhval1990 "Median home value, 1990"
duplicates drop zip, force
sort zip 

// Merge 1990 data together
merge 1:1 zip using `datdir'la1990race.dta, generate(merge1)
tab merge1
drop merge1
sort zip
merge 1:1 zip using `datdir'la1990medhhinc.dta, generate(merge1)
tab merge1
drop merge1
sort zip
save `datdir'la1990.dta, replace 
clear 
!rm `datdir'la1990race.dta `datdir'la1990medhhinc.dta

// Generate 2000 race data 
insheet using `datdir'la2000race.csv, c 
des 
drop id geography
destring id2, force replace 
drop if id2 == . 
rename id2 zip 
drop if total == 0 
local rlist white black native asian nativeh other multi
foreach x in `rlist' { 
	gen `x'2000 = `x'/total
	label variable `x'2000 "Percent `x' in 2000 within zip code" 
	drop `x' 
}
drop total
duplicates drop zip, force
sort zip 
save `datdir'la2000race.dta, replace 
clear 

// Generate 2000 median income data 
insheet using `datdir'la2000medhhinc.csv, c 
drop id geography
destring id2, force replace 
drop if id2 == . 
rename id2 zip 
rename medhhinc medhhinc2000
label variable medhhinc2000 "Median household income, 2000" 
drop if medhhinc2000 == 0 
duplicates drop zip, force
sort zip 
save `datdir'la2000medhhinc.dta, replace 
clear

// Generate 2000 median home value data
insheet using `datdir'la2000medhval.csv, c 
drop id geography
destring id2, force replace 
drop if id2 == . 
rename id2 zip 
rename medhval medhval2000
drop if medhval2000 == 0
label variable medhval2000 "Median home value, 2000" 
duplicates drop zip, force
sort zip 

// Merge 2000 data 
merge 1:1 zip using `datdir'la2000medhhinc.dta, generate(merge1)
tab merge1
drop merge1
sort zip 
merge 1:1 zip using `datdir'la2000race.dta, generate(merge1)
tab merge1
drop merge1
save `datdir'la2000.dta, replace 
clear
!rm `datdir'la2000medhhinc.dta `datdir'la2000race.dta

// Generate 2010 data 
insheet using `datdir'la2010race.csv, c 
drop id geography
destring id2, force replace 
drop if id2 == . 
rename id2 zip 
drop if total == 0 
local rlist white black native asian nativeh other multi
foreach x in `rlist' { 
	gen `x'2010 = `x'/total
	label variable `x'2010 "Percent `x' in 2010 within zip code" 
	drop `x' 
}

drop total
duplicates drop zip, force
sort zip 
save `datdir'la2010.dta, replace 

// Merge all datasets together 
merge 1:1 zip using `datdir'la2000.dta, generate(merge1)
tab merge1
drop merge1
sort zip
merge 1:1 zip using `datdir'la1990.dta, generate(merge1)
tab merge1
drop merge1
sort zip
rename zip zipcode 
save `savedir'lacensuszip.dta, replace 
clear 
!rm `datdir'la1990.dta `datdir'la2000.dta

timer off 1 
timer list 1 
!echo "`filename' finished running in `r(t1)' seconds" | mail -s "`filename' finished running in `r(t1)' seconds" tjs24@duke.edu 
!rm *.log statasub*
log close `filename' 
