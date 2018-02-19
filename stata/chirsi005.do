// Copyright (C) 2011-2012 Timothy John Schwuchow.
// larsi${version}.do - Generates repeat sales price index for the la area
// Version 004	-	Comes from chainpriceseries020_1.do
timer on 1



local filename larsi${version} 
log using ${logdir}`filename'.txt, text replace name(`filename') 
use ${datdir}lafinal${version}.dta, clear 

sum sellyear
global yrmin	=	r(min) 

gen datex 		= 	sellyear + (sellmo - 1) / 12 
drop ymo
egen ymo		=	group(sellyear sellmo)
gen timeslice 	= 	ymo

// 1. Price is missing or extreme 
qui sum timeslice
local mintimeslice = r(min)
local maxtimeslice = r(max) 
forvalues x = `mintimeslice'/`maxtimeslice' { 
	qui sum price if timeslice ==`x', detail 
	qui drop if (price == . | price <= 0 | price < r(p5) | price > r(p95)) & timeslice == `x' 
}

bysort property_id: gen p1 = (_n == 1) 
bysort property_id: egen sqftavg	=	mean(sqft) 




// 2. Generate number of transactions by month
bysort ymo: gen ntransymo 	= 	_N
label variable ntransymo "Number of transaction in year/month window" 




bysort property_id (sdate): gen timenext 	= 	sdate[_n+1]
gen tnext 	= 	timenext - sdate 
bysort ymo: egen mtnext 	= 	mean(tnext) 
label variable mtnext "Mean time until next transaction for transactions within year/month" 

reg lp sqft numbed numbath i.ymo
predict pres, resid
bysort sellyear sellmo: egen mpricevar 	= 	sd(pres)
replace mpricevar	=	mpricevar^2 
label variable mpricevar "Mean variance in residual of hedonic regression" 

// 3. Keep only even numtrans for properties with fewer than 4 transactions total
keep if numtrans == 2 | numtrans == 4 | (numtrans == 3 & transorder < 3)  
gen ftrans = (transorder == 1 | transorder == 3)
label variable ftrans "First observation of transaction pair" 
gen strans = (transorder == 2 | transorder == 4)
label variable strans "Second observation of transaction pair" 
gen fpair = (transorder < 3) 
label variable fpair "Belongs to first pair of observations of a property" 
gen spair = (fpair == 0)  
label variable spair "Belongs to second pair of observations of a property" 


// 4. Drop repeat sales where house visibly changes 
bysort property_id fpair: gen same = (sqft[2] == sqft[1] & sqft[1] ~= . & sqft[2]~= . & timeslice[1] ~= timeslice[2] )
label variable same "First observation of pair is observably the same as the second observation of the pair, and the sales occur in different months"  
sort property_id transorder 
count if same ~= same[_n+1] & ftrans == 1 & property_id == property_id[_n+1]
bysort property_id fpair: egen msame = total(same==0)
drop if msame > 0 


// Begin constructing regression 

bysort property_id fpair: drop if _N ~= 2 

bysort property_id fpair: egen price1 = total( price * (ftrans==1) )
bysort property_id fpair: egen timeslice1 = total( timeslice * (ftrans==1) )
bysort property_id fpair: egen price2 = total( price * (ftrans==0) )
bysort property_id fpair: egen timeslice2 = total( timeslice * (ftrans==0) )
drop if timeslice1 == timeslice2 
local mintimeslicep1 = `mintimeslice' + 1 
gen regon = price1 * (timeslice1 == `mintimeslice') 
forvalues x = `mintimeslicep1'/`maxtimeslice' {
	gen reg`x' = price2 * ( timeslice2 == `x' ) - price1 * (timeslice1 == `x')
	local reglist `reglist' reg`x' 
	gen iv`x' = -( reg`x' < 0 ) + ( reg`x' > 0 )
	local ivlist `ivlist' iv`x'
}

sort property_id sdate 
// list property_id tdate regon `reglist' in 1/100

egen rgmax = rowmax(`reglist') 
egen rgmin = rowmin(`reglist') 
count if ((rgmax == 0 | rgmin == 0) & regon == 0) | (regon~=0 & rgmax == 0)
drop if ftrans == 0 | ((rgmax == 0 | rgmin == 0) & regon == 0) | (regon~=0 & rgmax == 0)


ivregress 2sls regon (`reglist'=`ivlist'), r noc
qui parmest, saving("${datdir}`filename'", replace) label 


use ${datdir}`filename'.dta, clear 

gen pindex = 1/estimate 
gen timeslice = substr(parm,4,7)
destring timeslice, force replace 

gen timeid = $yrmin + (timeslice - 1) / 12
gen sellyear = floor(timeid) 
gen sellmo = mod(timeslice,12)
replace sellmo = 12 if sellmo == 0 



keep pindex sellyear sellmo
 
sort sellyear sellmo 


save, replace 

use ${datdir}lafinal${version}.dta, clear 
sort sellyear sellmo 
merge m:1 sellyear sellmo using ${datdir}`filename'.dta, generate(pindexmerge) 
drop pindexmerge 
replace pindex = 1 if pindex==. 
capture confirm variable pnorm 
if !_rc {
	replace pnorm = price / pindex
}
else	{
	gen pnorm = price/index 
} 

la var pnorm "Normalized price (by RSI)" 
sum pnorm 

save, replace 
timer off 1 
timer list 1 

timer clear 1  
log close `filename' 



!cat ${logdir}`filename'.txt | mail -s "`filename' done running in `r(t1)' seconds" tjs24@duke.edu
