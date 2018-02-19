// Copyright 2011-2013  Timothy John Schwuchow
// 
// program 			- 	laregprepxxx.do
// 						Generates variables for regression analysis and finalizes dataset
// 
// version 			-	004		-	Base				
// 					-	005		-	
//
// output			-	${datdir}lafinalxxx.dta




local filename "laregprep${version}"
log using ${logdir}`filename'.txt, replace text name(`filename')
timer on 1
! if [ ! -f ${datdir}laincludeext${version}.dta ]; then cd $datdir &&  tar xvzf laregprep${version}.tar.gz && cd $progdir; else echo "File exists"; fi
use ${datdir}laincludeext${version}.dta, clear


append using ${datdir}lanoinclude${version}.dta

qui sum sellyear
local minyear = `r(min)'
local maxyear = `r(max)'

local rvars white black asian native hisp
local heterolist inc zinc `rvars'
local regvar lp sqft numbed numbath age ltsell




/////////////////////////////
// Generate size quantiles //
/////////////////////////////
{
	xtile sizetiletemp = sqft if newsale == 1, n($nsizetiles)
	bysort property_id: egen sizetile = min(sizetiletemp)
	bysort sizetile: sum sqft
}

///////////////////////////
// Generate time dummies //
///////////////////////////
{
	egen timedummy = group(ymo)
	quietly tab timedummy, gen(timedum)
	local ntimedum = `r(r)'
	sort property_id selldate obnum
	forvalues x = 1/`ntimedum' {
		by property_id (selldate obnum ): replace timedum`x' =  timedum`x'[_n+1] - timedum`x'[_n] if _n ~= _N
	}
	foreach x in `heterolist' {
		gen `x'sellpct = `x'*sellpct
		local intvar `intvar' `x'sellpct
	}
	by property_id (selldate obnum): gen sellpctdif = sellpct[_n+1] - sellpct[_n]
}

/////////////////////////////////////
// Forward predicted externalities //
/////////////////////////////////////

gen avlincend	= 	log(avincend)  
gen cumavlinc 	= 	log(cumavinc)
la var avincend "Avg. Income"
la var cumavlinc "Cum. Avg. Income"

gen bldgtranspct = bldgtransorder / bldgnumtrans
gen pisfirst = (sellorder == 1)
xtset bid
sort bid selldate obnum
foreach x in `heterolist'	{
	
	by bid (selldate obnum): replace cumav`x' = 0 if sellorder == 1 & cumav`x'[_n+1] ~= . & isincluded == 1
	la var cumav`x' "Cum. avg. `x'"
	xtreg av`x'end cumav`x' bldgtranspct pisfirst i.timedummy if isincluded==1, r fe
	qui predict meanext`x'
	la var meanext`x' "Mean `x' externality"
	qui replace meanext`x' = 0 if isincluded == 0
	qui replace cumav`x' = 0 if isincluded == 0
	local extlist `extlist' meanext`x'
	local cumextlist `cumextlist' cumav`x'
}





sort property_id selldate obnum
foreach x in `regvar' {
	di "`x'"
	by property_id (selldate obnum): gen `x'dif = `x'[_n+1] - `x'[_n]
	local regvardif `regvardif' `x'dif
}

foreach x in `heterolist' {
	by property_id (selldate obnum): gen `x'forward = `x'[_n+1]
	local heterolistforward `heterolistforward' `x'forward
}

foreach x in `heterolist' {
	by property_id (selldate obnum): gen `x'dif = `x'[_n+1] - `x'[_n]
	local heterolistdif `heterolistdif' `x'dif
}

foreach x in `extlist' {
	by property_id (selldate obnum): gen `x'dif = `x'[_n+1] - `x'[_n]
	local extdiflist $extdiflist `x'dif
}

foreach x in `cumextlist' {
	by property_id (selldate obnum): gen `x'dif = `x'[_n+1] - `x'[_n]
	local cumextdiflist `cumextdiflist' `x'dif
}
by property_id (selldate obnum): gen sdatedif = sdate[_n+1] - sdate[_n]
by property_id (selldate obnum): gen notdif = (sqft[_n]==sqft[1] & sqftdif==0 & numbed[_n]==numbed[1] & numbeddif == 0 & numbath[_n]==numbath[1] & numbathdif == 0 & numtrans ~= 1)
by property_id (selldate obnum): gen notdif2 = (sqft[_n]==sqft[1] & sqft[1] ~= . & numbed[_n]==numbed[1] & numbed[1] ~= . & numbath[_n]==numbath[1] & numbath[1] ~= . & numtrans ~= 1 )
bysort bid newsale (selldate obnum): gen sellpctcounter = _n/_N if newsale == 0 & isincluded == 1


////////////////////////////
// Diff in diff variables //
////////////////////////////
bysort property_id (selldate obnum): gen nsellyear = sellyear[_n+1] if notdif2[_n+1]==1 & newsale == 1 & isincluded == 1
egen ddcell = group(bid nsellyear)
bysort ddcell: gen ddcount = _N
gen ddinc = (ddcount > 1 & ddcount ~= .) if isincluded == 1

//////////////////////////////////////
//  Alternative sales order measure //
//////////////////////////////////////

bysort bid newsale: egen sellorderalt	=	rank(sdate) if newsale==1, track
bysort bid newsale (sellorderalt): gen sellordermax	= sellorderalt[_N]
gen sellpctalt	=	sellorderalt/sellordermax
drop sellordermax sellorderalt


save ${datdir}lafinal${version}.dta, replace
! cd $datdir && tar cvzf laregprep${version}.tar.gz laincludeext${version}.dta lanoinclude${version}.dta && cd $progdir
!rm ${datdir}laincludeext${version}.dta ${datdir}lanoinclude${version}.dta
timer off 1
timer list 1
loc t1min =	`r(t1)'/60.0
!echo "`filename' finished running in `r(t1min)' minutes" | mail -s "`filename' finished running in `r(t1min)' minutes" tjs24@duke.edu
timer clear 1
log close `filename'
