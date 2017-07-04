// QUANDL exchange rates for current year
// Import the WID to know the list of required currencies and associated countries
use "$work_data/price-index.dta", clear
keep iso currency
drop if currency == ""
duplicates drop
tempfile countries
save "`countries'"

// Remove some problematic currencies (to be dealt with later)
drop if (currency == "USD")
drop if (currency == "ERN")
drop if (currency == "SSP")
drop if (currency == "YUN")

// Loop over currencies and get exchange rates from Quandl
quietly levelsof currency, local(currencies)

local downloadyear $pastyear
foreach CUR of local currencies {
	// Get data
	quandl, quandlcode(CURRFX/USD`CUR') start(`downloadyear'-01-01) end(`downloadyear'-12-31) ///
		auth(j3SA6jh-S4pZxGf9aF2y) clear
	
	collapse (mean) rate
	
	generate currency = "`CUR'"
	
	merge 1:n currency using "`countries'", nogenerate
	save "`countries'", replace
}

replace rate = 1                 if (currency == "USD")
replace rate = 3                 if (currency == "SSP")
replace rate = 15.45             if (currency == "ERN")
replace rate = 4.0091*0.61712015 if (currency == "YUN")

// Correct 2016 exchange rate for Venezuela
assert $pastyear == 2016
replace rate=128.47871 if currency=="VEF"

// Generate exchange rates with euro and yuan
rename rate valuexlcusx999i
// Exchange rate with euro
quietly levelsof valuexlcusx999i if (currency == "EUR"), local(exchrate_eu) clean
generate valuexlceux999i = valuexlcusx999i/`exchrate_eu'

// Exchange rate with Yuan
quietly levelsof valuexlcusx999i if (currency == "CNY"), local(exchrate_cn) clean
generate valuexlcyux999i = valuexlcusx999i/`exchrate_cn'

// Sanity checks
assert valuexlceux999i == 1 if (currency == "EUR")
assert valuexlcusx999i == 1 if (currency == "USD")
assert valuexlcyux999i == 1 if (currency == "CNY")

reshape long value, i(iso) j(widcode) string

generate year = 2016
generate p = "pall"

tempfile xrate
save "`xrate'"


// WORLD BANK exchange rates for historical series
// Import exchange rates series from the World Bank
import delimited "$wb_data/exchange-rates/API_PA.NUS.FCRF_DS2_en_csv_v2.csv", ///
clear encoding("utf8") rowrange(3) varnames(4) delim(",")

// Rename year variables
dropmiss, force
foreach v of varlist v* {
	local year: variable label `v'
	rename `v' value`year'
}
drop value$pastyear

// Identify countries
countrycode countryname, generate(iso) from("wb")

// Add currency from the metadata
merge n:1 countryname using "$work_data/wb-metadata.dta", ///
	keep(master match) assert(match) nogenerate

// Identify currencies
currencycode currency, generate(currency_iso) iso2c(iso) from("wb")
drop currency
rename currency_iso currency

// Reshape
drop countryname countrycode indicatorname indicatorcode fiscalyearend
gen widcode="xlcusx999i"
gen p="pall"
reshape long value, i(iso currency widcode p) j(year)
drop if mi(value)
order iso widcode currency value year p

// Drop euro before 2000
drop if currency=="EUR" & year<2000

append using "`xrate'"


label data "Generated by import-exchange-rates.do"
save "$work_data/exchange-rates.dta", replace

