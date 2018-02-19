// Copyright 2011 Timothy Schwuchow
// lasumstatxxx.do - computes some summary statistics for developer-built units 
// Version 003 - base
// Version 004 - Combines lasumstat003.do and laexternalitysum004.do to produce comprehensive summary statistics 
timer on 1 
local filename "lasumstat${version}"
log using ${logdir}`filename'.txt, replace text name(`filename') 
use ${datdir}lafinal${version}.dta, clear 



 
// Statistics about buildings
tab newsale
tab numunits if bldgtransorder == 1 & newsale == 1 
twoway kdensity numunits if bldgtransorder == 1 & newsale == 1
graph export ${logdir}bsizedensity.ps, replace
!/usr/bin/mogrify -trim -density 200 -format jpg ${logdir}bsizedensity.ps 
!rm ${logdir}bsizedensity.ps

tab bldgnumtrans if bldgtransorder == 1 & newsale == 1 

// Statistics about units and people within buildings 
local vars price sqft numbed numbath lotsize numroom linc zinc hisp native asian black white 
la var price "Price"
la var sqft "Sqft."
la var numbed "Bedrooms"
la var numbath "Bathroomss"
la var lotsize "Lot size" 
la var numroom "Rooms"
la var inc 		"Income"
la var zinc "Normalized income"
la var hisp "Hispanic"
la var native "Native american"
la var asian "Asian"
la var black "Black"
la var white "White" 
// foreach x in `vars' { 
// 	sum bavg`x' if bldgtransorder == 1
// 	local suvar `suvar' bavg`x' 
// 	la var bavg`x' "Avg. `x' within building" 
// }
// tab yrbld 
// format `suvar' %5.3f  
// tabout `suvar' if bldgtransorder == 1 using ${logdir}sumstattab${version}.tex , replace oneway style(tex) contents(N)
// sutex `suvar' if bldgtransorder == 1, digits(5) labels file(${logdir}sumstatbldg${version}.tex) replace nobs minmax 

bysort yrtile: tab yrbld  
 
// Statistics about individuals 
format `vars' %5.3f
sutex `vars' if newsale == 1, digits(5) labels file(${logdir}sumstatnew${version}.tex) replace nobs minmax 
sutex `vars' if newsale == 0, digits(5) labels file(${logdir}sumstatold${version}.tex) replace nobs minmax 
foreach x in `vars' {
	sum `x' if newsale == 1 
}
// Check how often hispanic is associated with each other race
tab hisp hasrace 
local rvars black white asian native hisp
foreach x in `rvars' { 
	di "Count of hispanic and `x'"
	count if hisp==1 & `x'==1
}

// Output some data to check for problems 
// Generate temporary output to check name matching, etc.  
preserve
sort bid selldate ab
keep bid numunits unitnum newsale selldate leadselnum lsellerabbnonum sellerexabb lbuyernonum devarea yrbld yrtile 
keep in 1/100000
order bid numunits unitnum newsale selldate leadselnum lsellerabbnonum sellerexabb lbuyernonum devarea yrbld yrtile 

outsheet using ${dataoutdir}namesampleall.csv, c replace 
restore
local ivars inc zinc hisp native asian black white 
foreach x in `ivars'	{
	la var cumav`x' "Cum. Avg. `x'"
	la var av`x'end "Average `x' over building life" 
	la var meanext`x' "Predicted `x' at sale" 
}
sutex cumav* av*end meanext*, digits(5) labels file(${logdir}sumstatext${version}.tex) replace nobs minmax 
 
sum cumav*, detail 
sum av*end, detail 
sum meanext*, detail 
// foreach x in `vars' 	{
// 	local keepvars `keepvars' `x' cumav`x' av`x'end meanext`x' 
// }
// preserve 	
// keep bid unitnum selldate `keepvars' 
// sort bid selldate 
// order bid unitnum selldate `keepvars' 
// keep in 1/5000
// outsheet using ${dataoutdir}laexternalitysample.csv, c replace 
// restore 

tab notdif 
tab notdif2 
count if notdif ~= notdif2 

timer off 1 
timer list 1 
!echo "`filename' finished running in `r(t1)' seconds" | mail -s "`filename' finished running in `r(t1)' seconds" tjs24@duke.edu 
timer clear 1 

log close `filename' 

