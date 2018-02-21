// Copyright (C) 2018 Timothy John Schwuchow
// miamasterxxx.do 	- 	Control file for sequential sale/price analysis

///////////
// Setup // 
///////////
clear all
cap log close _all

set more off


///////////////////////
// Control variables //
///////////////////////

global version 			"005"
local dataprep		=	0					// =1 -> Generates data
local extprep		=	0					// =1 -> Generates externality variables
local regprep		=	1					// =1 -> Prepares final regressors for estimation
local results		=	1 					// =1 -> Estimates model
local resultsnew	=	1 					// =1 -> Estimates model
local clean			=	0					// =1 -> Clean up extra datasets
local rsi			=	0					// =1 -> Construct repeat sales index
local sumstat		=	0					// =1 -> Computes summary statistics

local filename 			"miamaster${version}"
global homedir          "/home/tim/main/DataIncubator/"
global datdir 			"${homedir}data/"
global progdir 			"${homedir}stata/mia/"
global logdir 			"${homedir}logs/"
global dataoutdir 		"${homedir}data/"
di "$datdir"
////////////////////////////
// Data creation settings //
////////////////////////////
global usezip 		= 	0 					// Use zip codes rather than tracts to aggregate units into developments
global devcells 	= 	2 					// Number of time windows for developments
global minnumunit 	= 	5					// Minimum number of identified new sales to quality as a development
global rcensoryears = 	2 					// Get rid of observations in the final years of the data where observations may be censored
global transnumcap	=	1500				// Maximum number of transactions per building - keep this low to save on externality computation.
global nsizetile	=	5					// Size quantiles for regression analysis

if `dataprep'	==	1	{
	do ${progdir}miaprep${version}
}
if `extprep'	==	1	{
	do ${progdir}miaexternality${version}
}
if `regprep' 	==	1	{
	do ${progdir}miaregprep${version}
}
if `rsi'		==	1	{
	do ${progdir}miarsi${version}
}
if `sumstat'	==	1	{
	do ${progdir}miasumstat${version}
}
if `results'	==	1	{
	do ${progdir}miaresults${version}
}
if `resultsnew'	==	1	{
	do ${progdir}miaresultsnew${version}
}
if `clean'		==	1	{
	do ${progdir}miacleanup${version}
}




