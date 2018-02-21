// Copyright (C) 2018 Timothy John Schwuchow
//
// program 			-	miaprepxxx.do	-	Basic setup for LA dataset
// output			-	${datadir}mianoincludexxx.dta	-	non-target observations
// 					-	${datadir}miaincludexxx.dta		-	target observations


local filename miaprep${version}
capture log close `filename'
log using ${logdir}`filename'.txt, replace text name(`filename')
local usealtmeasure	=	0
if `usealtmeasure'==1	{
	loc alt2 = 1
}
else	{
	loc alt1 = 1
}

use sr_unique_id property_id sr_date_transfer sr_val_transfer applicantrace applicantincome applicantsex applicantethnicity sa_sqft sa_lotsize sa_nbr_bedrms sa_nbr_bath sa_nbr_rms sa_nbr_units sa_yr_blt sa_architecture_code sa_construction_code sa_bldg_shape_code sa_construction_qlty sa_x_coord sa_y_coord sa_subdivision sr_tran_type sa_lgl_dscrptn county tract tract1 sa_mail_house_nbr sa_mail_street_name sr_seller uc_use_code_std sr_buyer sa_yr_blt_effect occupancy arms_length_flag_dfs sa_company_flag sa_site_mail_same sa_site_zip using ${datdir}MiamiMatched.dta

///////////////////////////////////
// Rename and organize variables //
///////////////////////////////////
{
	rename sr_unique_id utransid
	rename sr_date_transfer selldate
	rename sr_val_transfer price
	rename applicantrace race
	rename applicantincome inc
	rename applicantethnicity eth
	rename applicantsex sex
	rename sa_sqft sqft
	rename sa_lotsize lotsize
	rename sa_nbr_bedrms numbed
	rename sa_nbr_rms numrooms
	rename sa_nbr_bath numbath
	rename sa_lgl_dscrptn legal
	rename sa_nbr_units nunit
	rename sa_yr_blt yrbld
	rename sa_yr_blt_effect yrbldeff
	rename sa_architecture_code archcode
	rename sa_construction_code conscode
	rename sa_bldg_shape_code shapecode
	rename sa_construction_qlty conqual
	rename sa_x_coord x
	rename sa_y_coord y
	rename sa_subdivision subname
	rename sr_tran_type transcode
	rename uc_use_code_std usecode
	rename sa_mail_house_nbr stnumber
	rename sa_mail_street_name street
	rename sr_seller selname
	rename sr_buyer buyname
	rename arms_length_flag_dfs armslength
	rename sa_company_flag companyflag
	rename sa_site_mail_same ownocc
	rename sa_site_zip zipcode



	// Add variable labels
	label variable selldate "Date of sale"
	label variable utransid "Unique transaction id"
	label variable price "Sale price"
	label variable race "Buyer race"
	label variable eth "Buyer ethnicity"
	label variable inc "Buyer income ($000s)"
	label variable sex "Buyer sex"
	label variable sqft "Square footage"
	label variable lotsize "Size of lot"
	label variable numbed "Number of bedrooms"
	label variable numbath "Number of bathrooms"
	label variable legal "Legal description of lot - from assessor"
	label variable nunit "Number of units in property"
	label variable yrbld "Year built"
	label variable yrbldeff "Effective year built"
	label variable archcode "Architectural code - key in dataquick doc"
	label variable conscode "Contruction code - key in dataquick"
	label variable shapecode "Building shape - key in dataquick"
	label variable conqual "Construction quality"
	label variable x "longitude"
	label variable y "latitude"
	label variable subname "subdivision name - unclear what this is"
	label variable transcode "type of transaction - S typically means new build"
	label variable usecode "RCON = condo"
	label variable stnumber "Street number"
	label variable street "Street name"
	label variable selname "Seller name"
	label variable buyname "Buyer name"
	label variable armslength "Y => Arms Length Transaction"
	label variable ownocc "Y => Owner occupied"
	label variable zipcode "Zipcode of parcel"



	destring lotsize, replace force
	destring sqft, replace force
	destring numbed, replace force
	destring numrooms, replace force
	destring numbath, replace force
	destring nunit, replace force
	destring zipcode, replace force

	replace zipcode 	= 	. if zipcode == 0
	replace county 		= 	. if county == 0
	replace tract 		= 	. if tract == 0
	replace lotsize 	= 	. if lotsize == 0
	replace sqft 		= 	. if sqft == 0
	replace numbed 		= 	. if numbed == 0
	replace numbath 	= 	. if numbath == 0
	replace numrooms 	= 	. if numrooms == 0
	replace nunit 		= 	. if nunit == 0
	replace yrbld 		= 	. if yrbld == 0
	replace inc 		= 	. if inc == 0
    gen state = "12"
    ren county countytemp 
    gen county = string(countytemp,"%03.0f") 
    drop countytemp 
    
}

//////////////////////////
// Create area variable //
//////////////////////////
{
	if ${usezip} 	== 	1 {
		egen devarea 		= 	group(zipcode)
		replace devarea 	= 	. if zipcode == .
	}
	else {
		egen devarea 		= 	group(county tract)
		replace devarea 	= 	. if missing(county) | tract == .
	}
}
////////////////////
// Generate dates //
////////////////////
{
	tostring selldate, generate(selldates)
	gen sellyear 		= 	substr(selldates,1,4)
	destring sellyear, replace
	label variable sellyear "Year of sale"

	gen sellmo 			= 	substr(selldates,5,2)
	destring sellmo, replace
	drop if sellmo > 12 | sellmo < 1

	gen ymo 			= 	substr(selldates,1,6)
	gen sellday 		= 	substr(selldates,7,2)
	destring sellday, replace

	gen sdate 			= 	mdy(sellmo,sellday,sellyear)
	qui sum sdate, detail
	global minsdate 		= 	`r(min)'
	global maxsdate			=	`r(max)'
	qui sum sellyear, detail
	global minyear 			= 	`r(min)'
	global maxyear 			= 	`r(max)'
}
/////////////////////
// Drop conditions //
/////////////////////
{
	drop if yrbld == . | devarea == . | selldate == . | sellyear < yrbld
	drop if selname == "" | selname == "HUD" | strpos(selname,"Federal") ~= 0 | occupancy == 2 | occupancy == 3 | ownocc == "U" | ownocc == "N"
}
/////////////////////////////////////
// Sundry property specific fields //
/////////////////////////////////////
{
	gen obnum 				= 	_n
	bysort property_id (yrbld): replace yrbld				= 	yrbld[1] 	// Use earliest listed year built
	bysort property_id (sdate obnum): gen isfirst 		= 	(_n == 1) 	// Flag first sale observed
	bysort property_id (isfirst): replace devarea 		= 	devarea[_N]	// Standardize area identifier to that used in first sale
	gen include			=	( (isfirst==1 & yrbld >= $minyear & yrbld <= $maxyear - $rcensoryears) ) // Possible targets (1st transaction, built during sample and before censor point
}
///////////////////////////////////////
// Generate seller/buyer identifiers //
///////////////////////////////////////
{
	gen lseller 	= 	lower(selname)
	la var lseller "Seller name (lower case)"
	replace lseller =	subinstr(lseller, "&", " ", .)
	replace lseller =	subinstr(lseller, ".", " ", .)
	replace lseller =	subinstr(lseller, ",", " ", .)
	replace lseller =	subinstr(lseller, "-", " ", .)
	local corplist ltd llc inc group associates partners partner part par corporation corp holding development developers dev investments inve inv // Flag corporate words
	gen isco		=	0
	foreach x in `corplist' {
		replace isco	=	1	if strpos(lseller,"`x'") > 0
	}
	gen lsellerabb		=	lseller
	la var lsellerabb "Seller name (lower case, abbreviate frequent terms)"
	foreach x in `corplist' {
		replace lsellerabb 	= 	subinstr(lsellerabb,"`x'",substr("`x'",1,2),.)
	}
	replace lsellerabb 		= 	subinstr(lsellerabb,"north","n",.)
	replace lsellerabb 		= 	subinstr(lsellerabb,"south","s",.)
	replace lsellerabb 		= 	subinstr(lsellerabb,"east","e",.)
	replace lsellerabb 		= 	subinstr(lsellerabb,"west","w",.)
	replace lsellerabb		=	subinstr(lsellerabb,"street","st",.)
	replace lsellerabb 		=	subinstr(lsellerabb, "avenue", "ave", .)


	gen leadselnum			=	real(regexs(1)) 	if regexm(lsellerabb,"([0-9]+)")
	la var leadselnum "Leading numbers in seller name"
	replace leadselnum		=	0					if leadselnum	==	.
	gen lsellerabbnonum		=	lsellerabb
	la var lsellerabbnonum "Seller name abbreviated and w/o numbers"
	gen lsellernonum		=	lseller
	la var lsellernonum "Seller name, w/o numbers"
	gen lbuyer				=	lower(buyname)
	la var lbuyer "Buyer name, lower case"
	gen lbuyernonum			=	lbuyer
	la var lbuyernonum "Buyer name, w/o numbers"
	forvalues x = 1/5 {
		replace lsellerabbnonum	=	regexr(lsellerabbnonum,"[0-9]+","")
		replace lsellernonum		=	regexr(lsellernonum,"[0-9]+","")
		replace lbuyernonum		=	regexr(lbuyernonum,"[0-9]+","")
	}
	gen sellerexabb 	= 	soundex(lsellerabbnonum)
	la var sellerexabb "Seller soundex code"
	egen sellid			=	group(leadselnum sellerexabb)
	la var sellid "Seller ID - group by lead number and soundex code"
	gen sellerex		=	soundex(lsellernonum)
	la var sellerex "Unabbreviated seller soundex code"
	gen buyerex		=	soundex(lbuyernonum)
	la var buyerex "Unabbreviated buyer soundex code"

	bysort property_id (sdate obnum): replace include = 0 if sellid == sellid[_n+1] | buyerex == buyerex[_n+1] | buyerex == sellerex  // do not include if same seller/buyer appears twice in a row or buyer and seller are the same

	// bysort property_id (selldate obnum): replace include = 0 if sellid == sellid[_n+1] | sellid == sellid[_n-1] | buyerex == buyerex[_n+1] | buyerex == buyerex[_n-1] | buyerex ==
}
////////////////////////////////////////////////////////////
// Use year quantiles to identify contiguous developments //
////////////////////////////////////////////////////////////
{
	xtile yrtiletemp = yrbld if include == 1, nquantiles(${devcells})
	bysort yrbld: egen yrtile = mode(yrtiletemp)
	replace include = 0 if yrtile == .
	replace yrtile = 0 if yrtile == .
	drop yrtiletemp
}
///////////////////////////////
// Alternative year grouping //
///////////////////////////////
{
	sort sellid devarea
	egen sdy1		=	index1(sellid devarea yrbld) // Flag first sale of seller/area/year groups
	// replace sdy1 	= 	0 if include==0
	gen	yeargroup	=	.
	la var yeargroup "Groups seller/area development 'spells'"
	tempvar curyear

	gen `curyear' 	= 	.
	loc groupnum	=	1
	loc exitloop	=	0
	////////////////////////////////////////////
	// Creates two year development 'windows' //
	////////////////////////////////////////////
	while `exitloop' == 0	{
		gsort sellid devarea -sdy1 yrbld
		by sellid devarea: replace `curyear'	=	yrbld[1]	// For each flagged seller/area, get earliest flagged seller/area/year observation
		replace yeargroup	=	`groupnum' if yrbld == `curyear' | yrbld == `curyear' + 1 //
		replace sdy1	=	0 if sdy1==1 & ~missing(yeargroup)
		tab sdy1
		qui sum sdy1
		if `r(max)'== 0	{
			loc exitloop = 1
		}
		qui loc groupnum = `groupnum' + 1
	}
	qui drop  `curyear'
}
///////////////////////////////////////////
// Generate ids for multiunit developers //
///////////////////////////////////////////
{
	egen devid`alt1'	=	group(sellid devarea yrtile)
	la var devid`alt1' "Original developer ID (based on year quantiles)"
	egen devid`alt2'	= 	group(sellid devarea yeargroup)
	la var devid`alt2' "Developer id (based on two year windows)"
	replace include = 0 if devid == .

}
/////////////////////////////////
// Count 'included' properties //
/////////////////////////////////
{
	sort property_id
	by property_id: egen hasinclude	=	total(include)
	la var hasinclude "Number of 'included' sales for each property"
	tab hasinclude		// Check how many properties have an included property
	drop hasinclude
}
//////////////////////////
// Generate building id //
//////////////////////////
{
	by property_id: egen bid 			= 	max(devid*include) // Building ID is developer id
	la var bid "Building ID"
	replace bid 						= 	. if bid == 0

	// Check how many properties do not have buildings
	by property_id: egen nobid		=	max((bid==.))
	la var nobid "=1 if property is not part of a development building"
	tab nobid if isfirst==1  // "Tab first sales by building/nobuilding status"
}
////////////////////
// Flag new sales //
////////////////////
{
	gen newsale 	= 	include
	label variable newsale "=1 if the unit is new and sold for the first time"
	bysort bid: egen numunits 	= 	total(newsale) if bid ~= .
	tempvar b1
	egen `b1'	=	index1(bid) if ~missing(bid)
	tab `b1'
	tab numunits if `b1'
	drop `b1'
	replace include 			= 	0  if numunits < $minnumunit
	replace numunits 			= 	.  if numunits < $minnumunit
	label variable numunits "Number of units in development cluster"

}


///////////////////////////////////////////////////
// Within building sales order/transaction stats //
///////////////////////////////////////////////////
{
	sort property_id selldate obnum
	by property_id: gen numtrans 						= 	_N
	by property_id (selldate obnum): gen transorder 	= 	_n
	sort bid selldate obnum
	by bid (selldate obnum): gen bldgtransorder 		= 	_n
	replace bldgtransorder 							    = 	1 if bid == .
	by bid: gen bldgnumtrans 							= 	_N
	replace bldgnumtrans								=	. if missing(bid)
	replace bldgtransorder								=	. if missing(bid)
	replace bid 										= 	. if bldgnumtrans > $transnumcap
	replace include 									= 	0 if bldgnumtrans > $transnumcap
	replace bldgtransorder 							= 	1 if bldgnumtrans > $transnumcap
	replace numunits 									=  	. if bldgnumtrans > $transnumcap
	label variable numtrans "Number of times a property is transacted in sample"
	label variable transorder "Observation transaction order (specific to property, out of numtrans)"
	label variable bldgtransorder "Order within building of sales, both resales and first sales"
	la var bldgnumtrans "Total transactions observed in building (new and old)"
}
{
	tab include
	sort property_id
	by property_id: egen isincluded 	= 	max( include )
	replace bid  						= 	. if isincluded == 0

	// Want other houses to increase efficiency of time series identification but don't care about them other than that
	by property_id: drop if _N == 1 & bid == .
	tempvar p1
	qui egen `p1'	=	index1(property_id)
	tab isincluded if `p1'
	qui drop `p1'
}
//////////////////////////////////
// Save non-target observations //
//////////////////////////////////
{
	preserve
	keep if isincluded == 0
	compress
	save ${datdir}mianoinclude${version}.dta, replace
	restore
	drop if isincluded == 0
}

//////////////////////////////////////////////////
// Generate sales order and interim sales flags //
//////////////////////////////////////////////////
{
	sort bid newsale selldate obnum
	by bid: egen maxselldate 							= 	max( selldate * ( newsale == 1 ) )
	by bid: gen interimsale							= 	( selldate < maxselldate & newsale == 0)
	by bid newsale (selldate obnum): gen sellorder 	= 	_n if newsale == 1
	gen sellpct 										= 	sellorder / numunits
	bysort property_id: egen unitnum 					= 	min(sellorder) 		// Unique number (within building) of unit sold
	label variable maxselldate "Date on which the last new unit in the building was sold"
	label variable interimsale "=1 if a unit is resold before a building's last new unit is sold"
	label variable sellorder "Order in which units are sold among new units within building (of numunit)"
	label variable sellpct "Sales percentile of unit sale"
	label variable unitnum "Unique (within building) unit identifier"
}

/////////////////////////////////////
// Merge census data into main set //
/////////////////////////////////////
{
    

	sort state county 
	merge m:1 state county using ${datdir}census.dta
	tab _merge
	drop if _merge==2
	drop _merge
}

////////////////////////////////////////////////////
// Generate price / externality / local demo vars //
////////////////////////////////////////////////////
{
	sort sellyear
	gen lp	 						= 	log(price)
	gen loghhinc1990 				= 	log(medhhinc90)
	gen loghhinc2000				=	log(medhhinc00)
	gen linc 						=	log(inc) if inc > 1
	gen age 						= 	sellyear - yrbld
	by sellyear: egen minc			=	mean(inc)
	by sellyear: egen sdinc		=	sd(inc)
	gen zinc						=	(inc - minc)/sdinc
	sort bid sellyear
	by bid sellyear: egen bminc	=	mean(inc)
	by bid sellyear: egen bsdinc	=	sd(inc)
	gen bzinc						=	(inc - bminc)/bsdinc
	label var lp "Log of sale price"
	label var loghhinc1990 "Log median household income of zipcode in 1990"
	label var loghhinc2000 "Log median household income of zipcode in 2000"
	label var linc "Log income"
	label var age "Age (years) at time of sale"
	la var zinc "Normalized Income"
	la var bzinc "Normalized Income (within building)"

	replace eth 	= 	. if eth > 2
	gen hisp 		= 	(eth  == 1)
	gen native		=	( (race == 1 | race ==4) )
	gen asian 		= 	(race == 2)
	gen black 		= 	(race == 3)
	gen white 		= 	(race == 5)
	local rvars black white asian native hisp
	egen hasrace 	= 	rowmax(`rvars')

	label variable hisp "=1 -> buyer is Hispanic"
	label variable native "=1 -> buyer is Native American, Native Hawaiian, Native Alaskan, or other pacific islander"
	label variable asian "=1 -> buyer is Asian"
	label variable black "=1 -> buyer is Black"
	label variable white "=1 -> buyer is White"
	la var hasrace "=1 if buyer race is known"
	
}

/////////////////////////////////////////
// Generate elapsed time between sales //
/////////////////////////////////////////
{
	bysort bid (sdate obnum): gen timesell = sdate[_n]-sdate[1]
	label variable timesell "Time (days) between first and current condo sales"
	gen ltsell = log(timesell + 1)
	label variable ltsell "Log of timesell+1"
}

/////////////////////////////////////////////////////////////
// Generate within building averages of various attributes //
/////////////////////////////////////////////////////////////
{
	local vars price sqft numbed numbath lotsize numroom linc hisp native asian black white
	foreach x in `vars' {
		sort bid
		by bid: egen bavg`x'	=	mean(`x') if newsale == 1
		la var bavg`x' "Average `x' of newly sold units within development"
	}

}

////////////////////////
// Save included data //
////////////////////////
{
	compress
	save ${datdir}miainclude${version}.dta, replace
}

{

	log close `filename'
}

