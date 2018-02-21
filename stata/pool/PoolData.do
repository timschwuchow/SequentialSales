// Copyright 2018 Timothy John Schwuchow
// PoolData.do - Pool data from 5 cities  


local filename "PoolData"
local useincnorm = 0
local usepricenorm = 0 
log using ${logdir}`filename'.txt , replace text name(`filename') 

use ${datdir}lafinal${version}.dta, clear 

local prefixes chi cle sf mia 

for each x in `prefixes' {
    append using ${datdir}`x'final${version}.dta
}
/*
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


**************************
** Basic OLS regression **
**************************

xtset bid

// 1. Simple building FE regression with no externality (estimates should be positive - indicating that higher income buyers pay more later)
//xtreg `regvar' c.sellpct##c.(`heterolist') ibn.timedummy if newsale==1, fe r //Basic regression
xtreg `regvar' c.sellpct##c.(`heterolist') if newsale==1, fe 
xtreg `regvar' c.sellpct##c.(`heterolist') `cumextlist' if newsale==1, fe
// 2. Simple building FE regression with externality (estimates should be positive - indicating that higher income buyers pay more later)
xtreg `regvar' c.sellpct##c.(`heterolist') `cumextlist' ibn.timedummy if newsale == 1, r fe

// outtex, level below plain file(textable/`texname'.tex) append long title(Basic regression with externality) 

// 3. Counterfactual regression (on resold units) (estimates should not be positive since income shouldn't matter here)
xtreg `regvar' c.sellpctcounter##c.(`heterolist') `cumextlist' ibn.timedummy if newsale == 0, r fe 
// outtex, level below plain file(textable/`texname'.tex) append long title(Counterfactual regression with externality)



*********************
** Repeat analysis ** 
*********************

*********************************
** First difference regression **
*********************************
xtset bid 
qui sum timedummy
local ntimedum = r(max)

// 1. First difference regression, no externality (first 2 transactions) (estimates should be negative - higher income people should get more appreciation on their houses if bought early and less if bought later) 
reg lpdif c.sellpct##c.(`heterolist')  if notdif2==1 & newsale==1, r cluster(bid)

// 2. First difference regression with externality (first 2 transactions)
reg lpdif c.sellpct##c.(`heterolist') `heterolistforward' `avgextdiflist'  if notdif2==1 & newsale==1, r cluster(bid)
 
// 3. First difference regression, no externality (building fes)
xtreg lpdif c.sellpct##c.(`heterolist') if notdif2==1 & newsale==1, r fe

// 4. First difference regression with externality (building fe)
xtreg lpdif c.sellpct##c.(`heterolist') `heterolistforward' `avgextdiflist'  if notdif2==1 & newsale, r fe 

********************************
** Differences-in-differences **
********************************

xtset ddcell
xtreg lpdif  c.sellpct##c.(`heterolist') `extdiflist' if ddinc==1 & newsale==1 & isincluded == 1, r fe


*****************************
** Property FE regressions ** 
*****************************

xtset property_id 

// 1. FE regression, no separation of dynamic effect  
xtreg `regvar' c.sellpct##c.(`heterolist') `avgextlist'  if notdif2==1, r fe 

// 2. FE regression, dynamic effect for newly sold units only 
xtreg `regvar' c.newsale#(c.sellpct##c.(`heterolist')) `avgextlist'  if notdif2==1, r fe 

// outtex, level below plain file(textable/`texname'.tex) append long title(Property FE regression with externality, no secondary sale heterogeneity)
// a2reg lp age ltsell sellpct $heterolist $intvar $extlist, individual(property_id) unit(timedummy) 
// reg2hdfe lp age ltsell sellpct $heterolist $intvar $extlist if notdif2==1, id1(property_id) id2(timedummy)


*/ 

log close `filename' 

