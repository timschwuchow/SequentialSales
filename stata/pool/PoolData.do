// Copyright 2018 Timothy John Schwuchow
// PoolData.do - Pool data from 5 cities  

global version          "005"
global homedir          "/home/tim/main/DataIncubator/"
global datdir 			"${homedir}data/"
global progdir 			"${homedir}stata/pool/"
global logdir 			"${homedir}logs/"
global dataoutdir 		"${homedir}data/"

set more off 
capture log close _all 
local filename "PoolData"
local useincnorm = 0
local usepricenorm = 0 
log using ${logdir}`filename'.txt , replace text name(`filename') 

local loadlist state county bid white asian black native hisp linc sex inc property_id sellpct lp sqft lotsize numbath numbed ltsell sdate ymo cumavlinc cumavasian cumavblack cumavwhite cumavnative avlincend avzincend avasianend avblackend avwhiteend avnativeend meanextinc meanextwhite meanextblack meanextasian meanextnative meanexthisp cumavhisp avhispend newsale notdif2 lpdif selname usecode sdatedif medhhinc90 medhhinc00 pctwhite90 pctwhite00 

use `loadlist' using ${datdir}lafinal${version}.dta, clear 

local prefixes chi cle sf mia 

foreach x in `prefixes' {
    di "Appending `x'"
    append using ${datdir}`x'final${version}.dta, keep(`loadlist')
}

ren bid bid2 
egen bid = group(bid2 state county)
drop bid2 



**********
** Prep **
**********

// Generate variable lists 


local rvars white black asian native 
if `useincnorm' == 1 {
	local heterolist zinc `rvars'
}
else	{
	local heterolist linc `rvars'
}
if `usepricenorm' == 1 {
	replace lp	=	log(pnorm)
	bysort property_id (selldate ab): replace lpdif = lp[_n+1] - lp[_n]
}

local regvar lp sqft numbed numbath

foreach x in `heterolist' {
	local avgextlist `avgextlist' meanext`x' 
	local cumextlist `cumextlist' cumav`x'
	local heterolistforward `heterolistforward' `x'forward 
	local heterolistdif `heterolistdif' `x'dif
	local avgextdiflist `avgextdiflist' meanext`x'dif
	local cumextdiflist `cumextdiflist' cumav`x'dif
}	
foreach x in `regvar' { 
	local regvardif `regvardif' `x'dif 
} 

qui sum sqft, detail 
replace sqft = . if sqft==r(min)
replace sqft = . if sqft==r(max)
qui sum numbed, detail 
replace numbed = . if numbed > r(p99)
qui sum numbath, det 
replace numbath = . if numbath < r(p1)
replace numbath = . if numbath > r(p99)
gen lpreturn = (lpdif)^(365/sdatedif) 
drop if missing(bid) 
bysort bid: egen numunits = total(newsale)

//preserve 
//keep if usecode == "RCON"
egen bs1 = index1(bid selname) if newsale==1
bysort bid: egen nselname = total(bs1)
egen b1 = index1(bid)
tab nselname if b1  

outsheet bid selname using ../../data/CommonNames.csv if bs1==1 & nselname >4, comma replace 
//restore 

compress 
save ${datdir}Pooled.dta, replace




log close `filename' 

