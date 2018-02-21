// Copyright 2018 Timothy Schwuchow
// sfsumstatxxx.do - computes some summary statistics for developer-built units 


local filename "sfsumstat${version}"
log using ${logdir}`filename'.txt, replace text name(`filename') 
use ${datdir}sffinal${version}.dta, clear 



 
// Statistics about buildings
tab newsale
tab numunits if bldgtransorder == 1 & newsale == 1 
twoway kdensity numunits if bldgtransorder == 1 & newsale == 1
graph export ${logdir}sfbsizedensity.ps, replace
!/usr/bin/mogrify -trim -density 200 -format jpg ${logdir}sfbsizedensity.ps 
!rm ${logdir}sfbsizedensity.ps

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


bysort yrtile: tab yrbld  
 
// Statistics about individuals 
format `vars' %5.3f
sutex `vars' if newsale == 1, digits(5) labels file(${logdir}sfsumstatnew${version}.tex) replace nobs minmax 
sutex `vars' if newsale == 0, digits(5) labels file(${logdir}sfsumstatold${version}.tex) replace nobs minmax 
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



local ivars inc zinc hisp native asian black white 
foreach x in `ivars'	{
	la var cumav`x' "Cum. Avg. `x'"
	la var av`x'end "Average `x' over building life" 
	la var meanext`x' "Predicted `x' at sale" 
}
sutex cumav* av*end meanext*, digits(5) labels file(${logdir}sfsumstatext${version}.tex) replace nobs minmax 
 



log close `filename' 

