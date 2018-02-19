// Copyright 2011 Timothy Schwuchow 
// lacleanupxxx.do - Cleans up unnecessary datasets 
// Version 004 - base 

local filename "lacleanup${version}"
log using ${logdir}`filename'.txt, replace text name(`filename') 

!rm ${datdir}lainclude${version}.dta ${datdir}lanoinclude${version}.dta ${datdir}laincludeext${version}.dta


log close `filename'

