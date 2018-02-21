// Copyright 2014  Timothy John Schwuchow
// 
// program 			- 	LACensus${version}.do
// 
// version 			-	006
//
// output			-	LACensus.dta 

clear all
capture log close _all
set mem 1g
set more off 
timer on 1 
local version 006
local filename LACensus`version'
local savedir "/afs/econ/data/bayerp/tim/condo/data/geo/" 
local datdir "`savedir'lazip/"
log using `filename'.txt, text replace name(`filename')


insheet using `datdir'ncdb.csv, comma clear 
ren ucounty county 
ren trctcd1 tract
ren shrnhw9 white1990
ren shrnhb9 black1990
ren shrnhi9 natamer1990
ren shrnha9 asian1990
ren shrnho9 other1990
ren shrhsp9 hisp1990
ren mdvalhs9 medhval1990 
ren mdfamy9 medhhinc1990
ren unemprt9 unemprt1990 
gen college1990 = educ169/educpp9
ren shrnhw0 white2000
ren shrnhb0 black2000
ren shrnhi0 natamer2000
ren shrnha0 asian2000
ren shrnho0 other2000
ren shrhsp0 hisp2000
ren mdvalhs0 medhval2000 
ren mdfamy0 medhhinc2000
ren unemprt0 unemprt2000 
gen college2000 = educ160/educpp0
replace county = county - 6000 
keep county tract *1990 *2000
duplicates drop county tract, force 
sort county tract 
save `savedir'LACensus.dta, replace 


