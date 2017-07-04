use "$work_data/exchange-rates.dta", clear

drop if inlist(iso, "CN-UR", "CN-RU") & inlist(widcode, "xlcusx999i", "xlcyux999i") & (year <= 2015)

append using "$work_data/add-ppp-output.dta"

// Add Chinese exchange rates to urban and rural China
expand 2 if (iso == "CN") & inlist(widcode, "xlcusx999i", "xlcyux999i"), generate(newobs)
replace iso = "CN-UR" if newobs
drop newobs

expand 2 if (iso == "CN") & inlist(widcode, "xlcusx999i", "xlcyux999i"), generate(newobs)
replace iso = "CN-RU" if newobs
drop newobs

label data "Generated by add-exchange-rates.do"
save "$work_data/add-exchange-rates-output.dta", replace
