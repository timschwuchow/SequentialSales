// Copyright 2011 Timothy John Schwuchow
// laresultsxxx.do - Regression results for developer pricing strategies
// Version 004 - Base, carried over from older  code

timer on 1
local filename "laresultsnew${version}"
local useincnorm = 0
local usepricenorm = 0
log using ${logdir}`filename'.txt , replace text name(`filename')

use ${datdir}lafinal${version}.dta, clear

**********
** Prep **
**********

// Generate variable lists
local rvars white black asian native
if `useincnorm' == 1 {
	local heterolist zinc `rvars'
}
else	{
	local heterolist inc `rvars'
}
if `usepricenorm' == 1 {
	replace lp	=	log(pnorm)
	drop lpdif
	bysort property_id (selldate obnum): gen lpdif = lp[_n+1] - lp[_n]
}

local regvar lp sqft numbed numbath age ltsell

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



xtreg `regvar' c.sellpct##c.(`heterolist') ibn.timedummy if newsale==1, fe r //Basic regression

// 2. Simple building FE regression with externality controls (estimates should be positive - indicating that higher income buyers pay more later)
xtreg `regvar' c.sellpct##c.(`heterolist') `cumextlist' ibn.timedummy if newsale == 1, r fe
// outtex, level below plain file(textable/`texname'.tex) append long title(Basic regression with externality)

// 3. Counterfactual regression (on resold units) (estimates should not be positive since income shouldn't matter here)
xtreg `regvar' c.sellpctcounter##c.(`heterolist') `cumextlist' ibn.timedummy if newsale == 0, r fe
// outtex, level below plain file(textable/`texname'.tex) append long title(Counterfactual regression with externality)

// foreach x in $heterolist  {
// 	gen `x'sellpctcounter = `x'*sellpctcounter
// 	local counterinterlist `counterinterlist' `x'sellpctcounter
// }
// local vtemp $regvar `counterinterlist' $extlist
// egen keeper = rowmiss(`vtemp')
// foreach `x' in `vtemp' {
// 	bysort timedummy: egen m`x' = mean(`x') if keeper == 0 & newsale == 0
// 	gen md`x' = `x' - m`x'
// 	drop m`x'
// 	local mdvtemp `mdvtemp' md`x'
// }
// xtreg `mdvtemp', fe r //Only resales

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
reg `regvardif' c.sellpctdif##c.(`heterolist') timedum1-timedum`ntimedum' if notdif2==1 & newsale==1, r cluster(bid)

// 2. First difference regression with externality (first 2 transactions)
reg `regvardif' c.sellpctdif##c.(`heterolist') `cumextdiflist' timedum1-timedum`ntimedum' if notdif2==1 & newsale==1, r cluster(bid)

// 3. First difference regression, no externality (building fes)
xtreg `regvardif' c.sellpctdif##c.(`heterolist') timedum1-timedum`ntimedum' if notdif2==1 & newsale==1, r fe

// 4. First difference regression with externality (building fe)
xtreg `regvardif' c.sellpctdif##c.(`heterolist')  `cumextdiflist' timedum1-timedum`ntimedum' if notdif2==1 & newsale, r fe

********************************
** Differences-in-differences **
********************************

xtset ddcell
xtreg lpdif agedif ltselldif c.sellpctdif##c.(`heterolist') `cumextdiflist' if ddinc==1 & newsale==1 & isincluded == 1, r fe
// xtreg `regvardif' c.sellpctdif##c.(`heterolist') `avgextdiflist' if ddinc==1 & newsale==1 & isincluded == 1, r fe

*****************************
** Property FE regressions **
*****************************

xtset property_id

// 1. FE regression, no separation of dynamic effect
xtreg `regvar' c.sellpct##c.(`heterolist') `avgextlist' i.timedummy if notdif2==1, r fe

// 2. FE regression, dynamic effect for newly sold units only
xtreg `regvar' c.newsale#(c.sellpct##c.(`heterolist')) `avgextlist' i.timedummy if notdif2==1, r fe

// outtex, level below plain file(textable/`texname'.tex) append long title(Property FE regression with externality, no secondary sale heterogeneity)
// a2reg lp age ltsell sellpct $heterolist $intvar $extlist, individual(property_id) unit(timedummy)
// reg2hdfe lp age ltsell sellpct $heterolist $intvar $extlist if notdif2==1, id1(property_id) id2(timedummy)

*****************************
** Adjacent sales analysis **
*****************************

// xtset bid
//
// // drop if newsale ~= 1
// egen sellpcttile = cut(sellpct) if newsale ~= 1, at(0(0.25)1) icodes
// quietly sum sellpcttile, detail
//
// replace sellpcttile = r(max) if sellpct == 1
// bysort bid (sellorder obnum): gen nearadj = (overlinc==overlinc[_n-1])
// bysort bid (sellorder obnum): gen lpdifadj = lp - lp[_n-1]
// bysort bid (sellorder obnum): gen sqftdifadj = sqft - sqft[_n-1]
// bysort bid (sellorder obnum): gen numbeddifadj = numbed - numbed[_n-1]
// bysort bid (sellorder obnum): gen numbathdifadj = numbath - numbath[_n-1]
// bysort bid (sellorder obnum): gen ltselldifadj = ltsell - ltsell[_n-1]
// foreach x in `avgextlist' {
// 	bysort bid (sellorder): gen `x'difadj = `x' - `x'[_n-1]
// 	local extlistadj `extlistadj' `x'difadj
// }
// foreach x in `cumextlist' {
// 	bysort bid (sellorder): gen `x'difadj = `x' - `x'[_n-1]
// 	local cumextlistadj `cumextlistadj' `x'difadj
// }
//
// tab nearadj
// drop if nearadj ~= 1
// egen devsell = group(sellpcttile bid)
// collapse (mean) bid numunits lpdifadj sqftdifadj numbeddifadj numbathdifadj ltselldifadj `extlistadj' sellpct $heterolist, by(overlinc devsell)
//
// xtset devsell
// xtreg lpdifadj sqftdifadj numbeddifadj numbathdifadj ltselldifadj $heterolist `extlistadj', r fe

timer off 1
timer list 1
!cat ${logdir}`filename'.txt | mail -s "`filename' finished running in `r(t1)' seconds" tjs24@duke.edu
timer clear 1

log close `filename'

