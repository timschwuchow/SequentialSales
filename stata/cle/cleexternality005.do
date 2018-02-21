// Copyright (C) 2018  Timothy John Schwuchow
// 
// program 			- 	cleexternalityxxx.do	-	Computes income and race externalities - computes average demographics up to the nth sale, as well as final average demographics after each sale.  Generates final data for estimation.
// output			-	${datdir}cleincludeextxxx.dta


clear all
local filename 		"cleexternality${version}"
log using ${logdir}`filename'.txt, replace text name(`filename')


////////////////////////////
// Unzip file if archived //
////////////////////////////

use ${datdir}cleinclude${version}.dta

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Compute maximum number of trans. within building (computations must be done iteratively, though computations will be null for most buildings further in the loop //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
qui sum bldgtransorder, detail
local maxnumtrans 	= `r(max)'
gen mtrans 			= `maxnumtrans'
local maxnumtransm1 = `maxnumtrans' - 1

qui sum unitnum, detail
local maxunits = `r(max)'

////////////////////////////////////
// Change race to missing if zero //
////////////////////////////////////
local rvars asian black white native hisp
foreach x in `rvars' {
	replace `x' 	= 	. if hasrace == 0
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Compute times between transactions within building (so we can time weight demographic traits during intervals b/w transactions //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
qui sum sdate
global maxsdate 	= 	`r(max)'
gen ttime 			= 	$maxsdate - sdate
la var ttime 			"Time between current sale and end of sample"
sort bid (bldgtransorder)
by bid (bldgtransorder): gen nextt 		= 	sdate[_n+1] - sdate if _n ~= _N
by bid (bldgtransorder): replace nextt 	= 	ttime if _n == _N

////////////////////////////////////////////////////////////
// Loop to compute externality over income/race variables //
////////////////////////////////////////////////////////////
foreach z in inc zinc `rvars' {
	qui {
		gen `z'mod = `z'
		replace `z'mod = 0 if `z'mod == .
		gen `z'n0 = ( `z' ~= . )
		sort property_id bldgtransorder
		
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// 'Mod' variables adjust demographics based on relation between original and new owner (i.e. seller with 50k income and buyer with 70k 'modifies' unit income by +20k) //
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		by property_id (bldgtransorder): gen `z'mod2 			= 	`z'mod - `z'mod[_n-1] if _n ~= 1 
		by property_id (bldgtransorder): replace `z'mod2 		= 	`z'mod if _n == 1
		by property_id (bldgtransorder): gen `z'n02 			= 	`z'n0 - `z'n0[_n-1] if _n ~= 1
		by property_id (bldgtransorder): replace `z'n02 		= 	`z'n0 if _n == 1
		sort bid bldgtransorder
		by bid (bldgtransorder): gen runsum`z'					=	sum(`z'mod2)
		by bid (bldgtransorder): gen runnum`z'					=	sum(`z'n02)
		gen rundemo`z'											=	runsum`z' / runnum`z'
		gen runtime`z'											=	nextt if ~missing(rundemo`z')
		gen correct`z'0 	= 	0
		gen correct`z'num0 	= 	0
		gen cumav`z' 		=	.
		label variable cumav`z' "Cumulative externality value of demographic `z'"
		gen cumav`z'temp	=	.
		sort bid bldgtransorder
	}
	forvalues x = 1/`maxnumtrans'	{
		di "Trans `x' of `maxnumtrans'"
		qui {
			local y		=	`x' - 1
			by bid (bldgtransorder): gen has`x'								=	(property_id == property_id[`x'])
			by bid (bldgtransorder): gen correct`z'`x'						= 	`z'mod[`x'] if has`x' == 1
			by bid (bldgtransorder): replace correct`z'`x'					=	correct`z'`y' if has`x' == 0
			by bid (bldgtransorder): gen correct`z'num`x'					= 	`z'n0[`x'] if has`x' == 1
			by bid (bldgtransorder): replace correct`z'num`x'				=	correct`z'num`y' if has`x' == 0
			drop has`x' correct`z'num`y' correct`z'`y'
			by bid (bldgtransorder): replace cumav`z'temp 					=	sum(runtime`z' * rundemo`z' * (bldgtransorder < `x') ) / sum( runtime`z' * (bldgtransorder<`x') )
			replace cumav`z'												=	cumav`z'temp if bldgtransorder == `x'
			by bid (bldgtransorder): gen avweight`z'`x' 					= 	runtime`z'[`x']*(runsum`z'[`x'] - correct`z'`x') / (runnum`z'[`x'] - correct`z'num`x') if bldgtransorder < `x'
			by bid (bldgtransorder): gen nextt`z'`x'						=	runtime`z'[`x'] if avweight`z'`x' ~= .
			local tottime`z'list `tottime`z'list' nextt`z'`x'
			local avweight`z'list `avweight`z'list' avweight`z'`x'
		}
	}
	qui  {
		drop correct`z'*
		drop rundemo`z' runsum`z' runnum`z' runtime`z'
		egen tottime`z' 	= 	rowtotal(`tottime`z'list')
		drop `tottime`z'list'
		egen totweight`z' 	= 	rowtotal(`avweight`z'list')
		drop `avweight`z'list'
		gen av`z'end 	= 	totweight`z' / tottime`z'
		la var av`z'end "Time-weighted externality value of `z' for current unit from sale to end of sample"
		drop totweight`z' tottime`z' `z'mod `z'mod2 `z'n0 `z'n02 cumav`z'temp
	}

}

save ${datdir}cleincludeext${version}.dta, replace

log close `filename'





