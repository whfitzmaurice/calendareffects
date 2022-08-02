** student id: 100249635

clear all
ssc install estout, replace // required for producing regression tables
use pricesfinal

** convert string date into stata date
drop Date // dates in wrong format when retrieved from yfinance
gen date = date(date_string, "YMD")
format date %td

** generate days of week and months
gen weekday = dow(date)
gen month = month(date)
gen year = year(date)

** generates daily returns as percentage
gen dailyreturn = (Close-Open)/Open

** create monthly returns

bys month: egen monthreturn = mean(dailyreturn)

*******************************************
** dummy variables

** generate dummy for young firms (IPO after 2005)
gen young=1 if Ticker=="V"|Ticker=="MA"|Ticker=="ACM"|Ticker=="OC"|Ticker=="CMG"|Ticker=="MSCI"|Ticker=="H"|Ticker=="HUN"|Ticker=="MORN"|Ticker=="VMW"
replace young=0 if Ticker=="WMT"|Ticker=="MMM"|Ticker=="BA"|Ticker=="F"|Ticker=="HD"|Ticker=="C"|Ticker=="AIG"|Ticker=="CSCO"|Ticker=="AAPL"|Ticker=="MSFT"

** generate small/large dummy variable (large = market cap >$10bn)

gen large=1 if Ticker!="SP500"
replace large=0 if marketcap<=1e10

*******************************************
** visualisations

** basic monthly returns against months
twoway line monthreturn month if Ticker!="SP500", xlabel(1(1)12) title("Firms' monthly returns against months") subtitle("2010-2019") ytitle("Monthly returns (%)") xtitle("Month number") note("Source: pricesfinal.dta") yline(0)
graph export graph1.png

** month returns against months for young and mature with sp500 benchmark
bys month young: egen monthreturnyoung=mean(dailyreturn)

twoway (line monthreturnyoung month if young==1, legend(label(1 "Young")))(line monthreturnyoung month if young==0, legend(label(2 "Mature")))(line monthreturnyoung month if Ticker=="SP500", legend(label(3 "SP500"))), xlabel(1(1)12) title("Firms' monthly returns by age") subtitle("2010-2019, benchmarked to SP500") ytitle("Monthly returns (%)") xtitle("Month number") note("Source: pricesfinal.dta" "('Young' = IPO between 2005-2010)") yline(0)
graph export graph2.png

** month returns against months for large and small with sp500 benchmark
bys month large: egen monthreturnlarge=mean(dailyreturn)

twoway (line monthreturnlarge month if large==1, legend(label(1 "Large Cap")))(line monthreturnlarge month if large==0, legend(label(2 "Small Cap")))(line monthreturnlarge month if Ticker=="SP500", legend(label(3 "SP500"))), xlabel(1(1)12) title("Firms' monthly returns by size") subtitle("2010-2019, benchmarked to SP500") ytitle("Monthly returns") xtitle("Month number") note("Source: pricesfinal.dta" "('Large Cap' = market capitalisation >$10bn)") yline(0)
graph export graph3.png

*******************************************

drop if strpos(Ticker, "SP500") // drops market tracker for regression analysis

egen stockid=group(Ticker)

tab weekday, gen(wweekday)
tab month, gen(mmonth)
label var mmonth1 "January"
label var mmonth2 "February"
label var mmonth3 "March"
label var mmonth4 "April"
label var mmonth5 "May"
label var mmonth6 "June"
label var mmonth7 "July"
label var mmonth8 "August"
label var mmonth9 "September"
label var mmonth10 "October"
label var mmonth11 "November"
label var mmonth12 "December"

** declare panel data
xtset stockid date

** part 1
est clear
eststo: xtreg dailyreturn i.weekday mmonth2-mmonth12, robust fe
testparm mmonth2-mmonth12
return list
estadd scalar p_diff = r(p)
return list
esttab using "table1.rtf", scalars(p_diff) drop (*.weekday) p obslast label title({\b Table 1. Month effects for January and December}) nonumbers mtitles("Daily Returns") addnote("Source: pricesfinal.dta") wide varwidth(25) nobaselevels


** part 2
est clear
eststo: xtreg dailyreturn i.weekday mmonth2-mmonth12 if young==1, robust fe
testparm mmonth2-mmonth12
return list
estadd scalar p_diff = r(p)
eststo: xtreg dailyreturn i.weekday mmonth2-mmonth12 if young==0, robust fe
testparm mmonth2-mmonth12
return list
estadd scalar p_diff = r(p)
return list
esttab using "table2.rtf", scalars(p_diff) drop (*.weekday) p obslast label title({\b Table 2. Month effects for qualitative variable young (firms with IPO 2005-2010)}) nonumbers mtitles("Daily Returns - Young" "Daily Returns - Mature") addnote("Source: pricesfinal.dta") wide varwidth(25) nobaselevels


** part 3
est clear
eststo: xtreg dailyreturn i.weekday mmonth2-mmonth12 if large==1, robust fe
testparm mmonth2-mmonth12
return list
estadd scalar p_diff = r(p)
eststo: xtreg dailyreturn i.weekday mmonth2-mmonth12 if large==0, robust fe
testparm mmonth2-mmonth12
return list
estadd scalar p_diff = r(p)
return list
esttab using "table3.rtf", scalars(p_diff) drop (*.weekday) p obslast label title({\b Table 3. Month effects for qualitative variable large (capitalisation >$10bn firms)}) nonumbers mtitles("Daily Returns - Large" "Daily Returns - Small") addnote("Source: pricesfinal.dta") wide varwidth(25) nobaselevels


