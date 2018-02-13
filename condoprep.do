set more off 
clear
clear matrix 
log close _all 
log using condoprep.txt, replace text 

set mem 8G
set matsize 800

loc flist LA Chicago Cleveland Miami SFBA 


foreach f in `flist' { 
use sr_unique_id sr_date_transfer sr_val_transfer sr_tran_type arms_length_flag_dfs property_id applicantrace applicantincome applicantsex applicantethnicity sa_sqft sa_sqft_dq sa_lotsize sa_nbr_bedrms sa_nbr_bath sa_nbr_bath_dq sa_nbr_rms sa_nbr_units sa_yr_blt sa_yr_blt_effect sa_pool_code sa_roof_code sa_view_code sa_architecture_code sa_construction_code sa_bldg_shape_code sa_construction_qlty sa_x_coord sa_y_coord sa_subdivision  sa_lgl_dscrptn sa_site_house_nbr sa_site_street_name sr_seller uc_use_code_std sr_buyer occupancy propertytype sr_site_addr_raw  using `f'Matched.dta 



*Rename variables 
rename sr_unique_id utransid
rename sr_date_transfer selldate
rename sr_val_transfer price
rename sr_tran_type transcode 
rename applicantrace race
rename applicantincome inc
rename applicantsex sex
rename applicantethnicity eth 
rename sa_sqft sqft 
rename sa_sqft_dq sqft_dq 
rename sa_lotsize lotsize
rename sa_nbr_bedrms numbed
rename sa_nbr_rms numrooms
rename sa_nbr_bath numbath
rename sa_nbr_bath_dq numbathdq 
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
rename uc_use_code_std usecode
rename sa_site_house_nbr stnumber
rename sa_site_street_name street
rename sr_seller selname
rename sr_buyer buyname


label variable selldate "Date of sale"
label variable utransid "Unique transaction id" 
label variable price "Sale price" 
label variable race "Buyer race"
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

destring lotsize, replace force
destring sqft, replace force
destring numbed, replace force
destring numrooms, replace force
destring numbath, replace force
destring nunit, replace force 

* Replace missing data 
replace lotsize = . if lotsize==0
replace sqft = . if sqft == 0
replace numbed = . if numbed== 0
replace numbath = . if numbath == 0
replace numrooms = . if numrooms==0
replace nunit = . if nunit == 0 
replace yrbld = . if yrbld == 0 

* Set up dates and drop if dates are nonsensical 
tostring selldate, generate(selldates)
gen sellyear = substr(selldates,1,4)
destring sellyear, replace
drop if sellyear < yrbld
gen sellmo = substr(selldates,5,2)
destring sellmo, replace
drop if sellmo > 12 | sellmo < 1 
egen ymo = group (sellyear sellmo) 
gen sellday = substr(selldates,7,2)
destring sellday, replace
drop selldates 
gen sdate = mdy(sellmo,sellday,sellyear)
save `f'Short.dta, replace 
}
/* 
*Drop all non-condo units 
drop if usecode~="RCON"

*Drop observations with bad data or units that are not new
drop if yrbld ==. | yrbld < 1988
drop if price == . | price < 25000
drop if occupancy~=1
bysort property_id selldate: drop if _N > 1

*Non new sales are marked but now specified as a zero in newsale
bysort property_id (selldate): gen newsale = (_n==1)
label variable newsale "1st observed unit sale"  

*Generate unique buildings by looking at address and seller name
*May need to update subsequent sales to reflect originally written address from 1st sale, look into this
replace tract = round(tract*100)
egen condoid = group(county tract street stnumber)

*Drop buildings if block sales occur.  
bysort condoid buyname newsale: gen dropmark = (_N > 1 & newsale==1)
bysort condoid: egen dropmark2 = max(dropmark)
drop if dropmark2 > 0 
drop dropmark dropmark2  

*Generate developer id - things at same address sold by same developer 
egen sellid = soundex(selname)
*Declare any entity selling more 
bysort condoid sellid newsale: gen isdev = (_N > 4 & newsale==1) 
tab isdev
gen devid = condoid * (isdev==1) 
bysort devid: egen medprice = median(price) if devid~=0


* Set ID as identifier
xtset devid 



*Generate sale order and number of units 
gen ab = _n 
bysort devid (selldate ab): gen sellorder = _n if devid~=0
drop ab
bysort devid: gen numunits = _N
* Get rid of buildings where not all original sales are by the developer
bysort condoid: egen numunitsc = total(newsale)
gen weirddropt = (numunits ~= numunitsc)
bysort condoid: egen weirddrop = max(weirddropt)
tab weirddrop 
drop if weirddrop == 1
drop weirddrop weirddropt

gen sellpct = (sellorder) / numunits if devid~=0

*merge data 
sort county tract 
merge county tract using geo/censuslainc
tab _merge
drop if _merge==2
drop _merge

*Get rid of errant mistakes in assignment of condo county/tract 
bysort devid: egen medhhinc2 = median(medhhinc) if devid~=0
replace medhhinc = medhhinc2
drop medhhinc2 



gen lp = log(price)
label variable lp "Log of sale price" 

gen loghhinc = log(medhhinc)
label variable loghhinc "Log median household income of census tract" 

gen linc = log(inc) 
label variable linc "Log income"

gen age = sellyear - yrbld 
label variable age "Age (years) at time of sale"

xtreg lp sqft numbath numbed age i.ymo, fe r 
predict pres, e
label variable pres "Price residual" 

quietly tab race, generate(irace)



gen white = (race==5)
label variable white "1 if race ==5" 
replace white = . if race==.

gen fcondo = (sellorder==1)
label variable fcondo "First condo sold in building" 

bysort devid (selldate): gen timesell = sdate[_n]-sdate[1] + 1
label variable timesell "Time (days) between first and current condo sales"
gen ltsell = log(timesell)
label variable ltsell "Log of timesell" 

*Generate high income and high neighborhood income variables
quietly sum linc, detail
gen hiinc = (linc > r(p50))
label variable hiinc "1 = Log income over median" 
replace hiinc = . if linc==.

quietly sum medhhinc, detail
gen lonhinc = (medhhinc < r(p50))
label variable lonhinc "1= neighborhood median income under median" 
replace lonhinc = . if medhhinc==.


*Generate cumulative mean income and mean white among condos with complete information 

gen ab = _n 

gen incmod = inc 

replace incmod = 0 if incmod==.

bysort devid (selldate ab): gen suminc = sum(incmod) - incmod

gen incn0 = (inc~=.)

bysort devid (selldate ab): gen runinc = sum(incn0)

replace suminc = . if runinc < 2

bysort devid (selldate ab): gen sumn = sum(incn0) - incn0

gen cumavinc = suminc / sumn

bysort devid: egen completeinc = count(inc)

replace completeinc = (completeinc==numunits)

drop incmod incn0  

gen whitemod = white

replace whitemod = 0 if white==. 

bysort devid (selldate ab): gen sumwhite = sum(whitemod) - whitemod

gen whiten0 = (white~=.)

bysort devid (selldate ab): gen runwhite = sum(whiten0)

replace sumwhite = . if runwhite < 2 

bysort devid (selldate ab): gen sumnw = sum(whiten0) - whiten0

gen cumwhite = sumwhite / sumnw

drop whitemod whiten0 ab 

label variable cumavinc "Cumulative average income over condo sales"

label variable cumwhite  "Cumulative percent white over condo sales" 

*Genenerate end run average income of building

bysort devid: egen aincend = mean(inc)

label variable aincend "Final Average New Building Income" 

quietly sum aincend, detail

gen hbinc = (aincend >= r(p50)) if aincend ~= .

label variable hbinc "High income building"

bysort devid: egen awhiteend = mean(white)

label variable awhiteend "Average New Building White"

quietly sum awhiteend, detail

gen hbwhite = (awhiteend >= r(p50)) if awhiteend ~= .

label variable hbwhite "High white building" 

save /afs/econ/data/bayerp/tim/condolasub2, replace 

* use /afs/econ/data/bayerp/Elliot/MLS/ladata

*/ 

log close _all

