// Start with the WID data
use "$work_data/add-china-data-output.dta", clear

keep if inlist(widcode, "mconfc999i", "mgdpro999i")
drop p

reshape wide value, i(iso year) j(widcode) string
rename valuemconfc999i cfc_lcu_wid
rename valuemgdpro999i gdp_lcu_wid

generate cfc_pct_wid = cfc_lcu_wid/gdp_lcu_wid

// Add other data sources
merge 1:1 iso year using "$work_data/un-sna-detailed-tables.dta", ///
	nogenerate update assert(using master match)

// Calculate CFCs
generate cfc_src = "Piketty and Zucman (2014)" if (cfc_pct_wid < .)
replace cfc_src = "Waldenstrom" if (cfc_pct_wid < .) & (iso == "SE")
generate cfc_pct = cfc_pct_wid

foreach i of numlist 1000 600 500 400 300 200 100 50 40 30 20 10 {
	replace cfc_src = "the UN SNA detailed tables (series `i')" ///
		if (cfc_pct_un1_serie`i' < .) & (cfc_pct >= .)
	replace cfc_pct = cfc_pct_un1_serie`i' ///
		if (cfc_pct_un1_serie`i' < .) & (cfc_pct >= .)
}

keep iso year cfc_src cfc_pct

label data "Generated by calculate-cfc.do"
save "$work_data/cfc.dta", replace
