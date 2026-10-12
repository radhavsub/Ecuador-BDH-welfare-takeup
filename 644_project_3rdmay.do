*--------------------------------------------------*
* ECON 644 PROJECT
* Dilnaz and Radha
*--------------------------------------------------*

clear all
set more off
capture log close

*---------------------------------------------------*
* SET PATHS
*---------------------------------------------------*

local datafile "C:\Users\radha\Downloads\Cleaned 644 data.xlsx"
local outdir "C:\Users\radha\Downloads\econ644_output"
local graphdir "`outdir'\graphs"
local tabledir "`outdir'\tables"

capture mkdir "`outdir'"
capture mkdir "`graphdir'"
capture mkdir "`tabledir'"

log using "`outdir'\644project_BDHtakeup.log", replace text

capture which esttab
if _rc {
    ssc install estout, replace
}

*---------------------------------------------------*
* IMPORT DATA
*---------------------------------------------------*

import excel "`datafile'", sheet("Sheet1") firstrow clear
rename *, lower

describe
summarize

keep identif_hog bdhoct13 school sixtyfive disabled ///
     sixtyfivedq disableddq hhpersons hhconsump ///
     j_sch4up cellphone internet indigonly ///
     densidad densidad10 spentondocs birthatt nofeelpoor ///
     satisgovt provincia parroquia periodo bdhecv6r sexohhh

*---------------------------------------------------*
* RENAME VARIABLES
*---------------------------------------------------*

rename identif_hog household_id
rename bdhoct13 bdh_takeup
rename school school_member
rename sixtyfive elderly_member
rename disabled disabled_member
rename sixtyfivedq elderly_disqualified
rename disableddq disabled_disqualified
rename hhpersons household_size
rename hhconsump consumption_pc
rename j_sch4up head_school4up
rename cellphone has_cellphone
rename internet used_internet
rename indigonly indigenous_only
rename densidad parish_density
rename densidad10 low_density
rename spentondocs spent_documents
rename birthatt birth_attendance
rename nofeelpoor not_feel_poor
rename satisgovt govt_satisfaction
rename provincia province
rename parroquia parish
rename periodo survey_period
rename bdhecv6r bdh_current
rename sexohhh head_sex

*---------------------------------------------------*
* CREATE ANALYSIS VARIABLES
*---------------------------------------------------*

capture drop log_consumption
capture drop log_household_size
capture drop tech_group
capture drop high_govt_satisfaction

gen log_consumption = ln(consumption_pc)
gen log_household_size = ln(household_size)

gen tech_group = .
replace tech_group = 0 if has_cellphone == 0 & used_internet == 0
replace tech_group = 1 if has_cellphone == 1 & used_internet == 0
replace tech_group = 2 if has_cellphone == 0 & used_internet == 1
replace tech_group = 3 if has_cellphone == 1 & used_internet == 1

label define techlbl 0 "No cellphone / no internet" ///
                     1 "Cellphone only" ///
                     2 "Internet only" ///
                     3 "Cellphone and internet", replace
label values tech_group techlbl

gen high_govt_satisfaction = .
replace high_govt_satisfaction = 1 if govt_satisfaction >= 7 & !missing(govt_satisfaction)
replace high_govt_satisfaction = 0 if govt_satisfaction < 7 & !missing(govt_satisfaction)

label define highsatlbl 0 "Govt satisfaction < 7" 1 "Govt satisfaction 7-10", replace
label values high_govt_satisfaction highsatlbl

*---------------------------------------------------*
* LABEL VARIABLES
*---------------------------------------------------*

label variable household_id "Household ID"
label variable bdh_takeup "BDH takeup in Oct. 2013"
label variable low_density "Low population density (<10/sq. km.)"
label variable parish_density "Parish population density"
label variable log_consumption "Log adjusted per capita consumption"
label variable log_household_size "Log household size"
label variable school_member "Household has school-going member"
label variable elderly_member "Household has member age 65+"
label variable disabled_member "Household has disabled member"
label variable elderly_disqualified "Senior member disqualification indicator"
label variable disabled_disqualified "Disabled member disqualification indicator"
label variable head_school4up "Household head has 4+ years schooling"
label variable indigenous_only "Indigenous language only"
label variable spent_documents "Spent money on documents"
label variable birth_attendance "Birth attendance variable"
label variable not_feel_poor "Household head says household is not poor"
label variable govt_satisfaction "Satisfaction with government (1-10)"
label variable high_govt_satisfaction "High government satisfaction (7-10)"
label variable has_cellphone "HH head has activated cellphone"
label variable used_internet "HH head used internet in past week"
label variable tech_group "Technology access group"
label variable household_size "Household size"
label variable consumption_pc "Adjusted per capita consumption"

label define takeuplbl 0 "No" 1 "Yes", replace
label values bdh_takeup takeuplbl

label define denslbl 0 "Higher-density parish" 1 "Low-density parish", replace
label values low_density denslbl

save "`outdir'\temp_file.dta", replace

*---------------------------------------------------*
* DEFINE REGRESSION BLOCKS
*---------------------------------------------------*

local yvar bdh_takeup
local mainx low_density

local program_controls log_consumption log_household_size school_member elderly_member disabled_member ///
                       elderly_disqualified disabled_disqualified head_school4up ///
                       indigenous_only spent_documents birth_attendance

local info_controls has_cellphone used_internet

local psych_controls not_feel_poor govt_satisfaction

local full_controls `program_controls' `info_controls' `psych_controls'

*---------------------------------------------------*
* TABLE 1: DESCRIPTIVE STATISTICS BY BDH TAKEUP
*---------------------------------------------------*

putexcel set "`tabledir'\table1_descriptive_stats_by_bdh_takeup.xlsx", replace

putexcel A1=("Variable") ///
         B1=("Category") ///
         C1=("Non-BDH N") ///
         D1=("Non-BDH Mean") ///
         E1=("Non-BDH SD") ///
         F1=("Non-BDH Min") ///
         G1=("Non-BDH Max") ///
         H1=("BDH N") ///
         I1=("BDH Mean") ///
         J1=("BDH SD") ///
         K1=("BDH Min") ///
         L1=("BDH Max")

local row = 2

local main_vars `mainx'
local program_vars `program_controls'
local info_vars `info_controls'
local psych_vars `psych_controls'

foreach group in main program info psych {

    if "`group'" == "main" {
        local varlist `main_vars'
        local groupname "Main explanatory variable"
    }

    if "`group'" == "program" {
        local varlist `program_vars'
        local groupname "Program controls"
    }

    if "`group'" == "info" {
        local varlist `info_vars'
        local groupname "Informational controls"
    }

    if "`group'" == "psych" {
        local varlist `psych_vars'
        local groupname "Psychological controls"
    }

    foreach v of local varlist {

        local vlabel : variable label `v'
        if "`vlabel'" == "" {
            local vlabel "`v'"
        }

        quietly summarize `v' if `yvar' == 0
        local n0 = r(N)
        local mean0 = r(mean)
        local sd0 = r(sd)
        local min0 = r(min)
        local max0 = r(max)

        quietly summarize `v' if `yvar' == 1
        local n1 = r(N)
        local mean1 = r(mean)
        local sd1 = r(sd)
        local min1 = r(min)
        local max1 = r(max)

        putexcel A`row'=("`vlabel'") ///
                 B`row'=("`groupname'") ///
                 C`row'=(`n0') ///
                 D`row'=(`mean0') ///
                 E`row'=(`sd0') ///
                 F`row'=(`min0') ///
                 G`row'=(`max0') ///
                 H`row'=(`n1') ///
                 I`row'=(`mean1') ///
                 J`row'=(`sd1') ///
                 K`row'=(`min1') ///
                 L`row'=(`max1')

        local row = `row' + 1
    }
}

*---------------------------------------------------*
* TABLE 2: OLS MODELS
*---------------------------------------------------*

eststo clear

reg `yvar' `mainx', vce(robust)
eststo ols1

reg `yvar' `mainx' `program_controls', vce(robust)
eststo ols2

reg `yvar' `mainx' `program_controls' `info_controls', vce(robust)
eststo ols3

reg `yvar' `mainx' `program_controls' `info_controls' `psych_controls', vce(robust)
eststo ols4

esttab ols1 ols2 ols3 ols4 using "`tabledir'\table2_ols_models.rtf", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 2: OLS Models of BDH Take-Up") ///
    mtitles("No Controls" "Program Controls" "Program + Info" "Full Model") ///
    label compress ///
    stats(N r2, labels("Observations" "R-squared"))

*---------------------------------------------------*
* TABLE 3: PROBIT MODELS WITH INTERACTIONS
*---------------------------------------------------*

eststo clear

probit `yvar' i.`mainx'##i.has_cellphone ///
    `program_controls' used_internet `psych_controls', vce(robust)
eststo pint1

probit `yvar' i.`mainx'##i.used_internet ///
    `program_controls' has_cellphone `psych_controls', vce(robust)
eststo pint2

probit `yvar' i.`mainx'##c.govt_satisfaction ///
    `program_controls' `info_controls' not_feel_poor, vce(robust)
eststo pint3

probit `yvar' i.`mainx'##i.not_feel_poor ///
    `program_controls' `info_controls' govt_satisfaction, vce(robust)
eststo pint4

esttab pint1 pint2 pint3 pint4 using "`tabledir'\table3_probit_interactions.rtf", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 3: Probit Models with Interaction Terms") ///
    mtitles("Density x Cellphone" "Density x Internet" "Density x Govt Satisfaction" "Density x Not Feel Poor") ///
    label compress ///
    nobaselevels noomitted ///
    stats(N r2_p, labels("Observations" "Pseudo R-squared"))

*---------------------------------------------------*
* TABLE 4: FULL PROBIT MODEL WITH MFX
*---------------------------------------------------*

probit `yvar' `mainx' `program_controls' `info_controls' `psych_controls', vce(robust)

mfx compute, predict(p)

margins, dydx(*) post
eststo mfx_full

esttab mfx_full using "`tabledir'\table4_full_probit_mfx.rtf", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 4: Average Marginal Effects from Full Probit Model") ///
    label compress ///
    stats(N, labels("Observations"))

*---------------------------------------------------*
* DESCRIPTIVE STATISTICS: DEPENDENT VARIABLE
*---------------------------------------------------*

use "`outdir'\temp_file.dta", clear

summarize bdh_takeup, detail

graph bar (count), over(bdh_takeup) ///
    title("Dependent Variable: BDH Takeup in October 2013", size(medium)) ///
    subtitle("Number of households receiving and not receiving BDH", size(small)) ///
    ytitle("Number of households", size(medsmall)) ///
    ylabel(0(2000)8000, format(%9.0fc) labsize(small)) ///
    blabel(bar, format(%9.0fc)) ///
    note("bdh_takeup = 1 if at least one household member received BDH in October 2013; 0 otherwise.", size(vsmall)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white))

graph export "`graphdir'\bdhoct13_histogram.png", replace width(2600)

summ bdh_takeup

*---------------------------------------------------*
* DESCRIPTIVE STATISTICS: MAIN EXPLANATORY VARIABLE
*---------------------------------------------------*

summarize parish_density, detail
summarize low_density, detail

histogram parish_density if parish_density <= 500, ///
    frequency width(10) ///
    color(black) lcolor(white) lwidth(vthin) ///
    xline(10, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
    title("Parish Population Density as Continuous Variable", size(medium)) ///
    subtitle("Households in parishes below 500 persons/km{superscript:2}; dashed line = 10 cutoff", size(small)) ///
    xtitle("Parish population density (persons per km{superscript:2})", size(medsmall)) ///
    ytitle("Number of households", size(medsmall)) ///
    note("Low-density parish is defined as fewer than 10 persons/km{superscript:2}.", size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white))

graph export "`graphdir'\densidad_histogram.png", replace width(2600)

histogram low_density, discrete frequency ///
    start(-.5) width(1) ///
    xlabel(0 "Higher-density parish" 1 "Low-density parish", labsize(small)) ///
    ylabel(0(2000)10000, format(%9.0fc) labsize(small)) ///
    color(navy) lcolor(white) ///
    title("Main Explanatory Variable: Low-Density Parish Indicator", size(medium)) ///
    subtitle("Binary version of parish density used in regressions", size(small)) ///
    xtitle("Parish density category", size(medsmall)) ///
    ytitle("Number of households", size(medsmall)) ///
    note("low_density = 1 if parish density is below 10 persons/km{superscript:2}.", size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white))

graph export "`graphdir'\densidad10_histogram.png", replace width(2600)

summ low_density

*---------------------------------------------------*
* DESCRIPTIVE STATISTICS: RELATIONSHIP BETWEEN BDH TAKEUP AND DENSITY
*---------------------------------------------------*

preserve

collapse (mean) mean_takeup=bdh_takeup, by(low_density)
gen mean_takeup_pct = mean_takeup * 100

graph hbar mean_takeup_pct, over(low_density, label(labsize(small))) ///
    blabel(bar, format(%4.1f) position(outside) color(black)) ///
    bar(1, color(navy)) ///
    title("BDH Takeup by Parish Density Category", size(medium)) ///
    subtitle("Mean BDH takeup by low-density indicator", size(small)) ///
    ytitle("Households receiving BDH (%)", size(medsmall)) ///
    note("low_density = 1 if parish density is below 10 persons/km{superscript:2}.", size(vsmall)) ///
    legend(off) graphregion(color(white)) plotregion(color(white))

graph export "`graphdir'\bdh_takeup_by_low_density.png", replace width(2600)

restore

*---------------------------------------------------*
* PROGRAM CONTROL VARIABLES AMONG NON-BDH HOUSEHOLDS
*---------------------------------------------------*

use "`outdir'\temp_file.dta", clear

preserve

keep if bdh_takeup == 0
count
local n_nobdh = r(N)

collapse (mean) school_member elderly_member disabled_member ///
                elderly_disqualified disabled_disqualified ///
                head_school4up indigenous_only spent_documents

xpose, clear varname

rename v1 share
rename _varname oldname

replace share = share * 100

gen str45 varname = ""

replace varname = "School-going member" if oldname == "school_member"
replace varname = "Age 65+ member" if oldname == "elderly_member"
replace varname = "Disabled member" if oldname == "disabled_member"
replace varname = "Age 65+ DQ" if oldname == "elderly_disqualified"
replace varname = "Disabled DQ" if oldname == "disabled_disqualified"
replace varname = "HH head 4+ years schooling" if oldname == "head_school4up"
replace varname = "Indigenous only" if oldname == "indigenous_only"
replace varname = "Spent on documents" if oldname == "spent_documents"

graph hbar share, over(varname, sort(1) descending label(labsize(small))) ///
    blabel(bar, format(%4.1f) position(outside) color(black)) ///
    bar(1, color(navy)) ///
    title("Binary Program Controls Among Non-BDH Households", size(medium)) ///
    subtitle("Percentage of non-recipient households with each characteristic", size(small)) ///
    ytitle("Share of households not receiving BDH (%)", size(medsmall)) ///
    note("Sample: `n_nobdh' households that did not receive BDH.", size(vsmall)) ///
    legend(off) graphregion(color(white)) plotregion(color(white))

graph export "`graphdir'\controls_program_binary_no_bdh.png", replace width(2800)

restore

*---------------------------------------------------*
* INFORMATIONAL AND PSYCHOLOGICAL CONTROLS AMONG NON-BDH HOUSEHOLDS
*---------------------------------------------------*

use "`outdir'\temp_file.dta", clear

preserve

keep if bdh_takeup == 0
drop if missing(has_cellphone)
count
local n_nobdh = r(N)

contract has_cellphone
rename _freq n
egen total = total(n)
gen pct = 100 * n / total

label define celllbl 0 "No cellphone" 1 "Has cellphone", replace
label values has_cellphone celllbl

graph bar pct, over(has_cellphone, label(labsize(small))) ///
    blabel(bar, format(%4.1f) color(black)) ///
    bar(1, color(navy)) ///
    title("Cellphone Access", size(medium)) ///
    subtitle("Among non-BDH households", size(small)) ///
    ytitle("Percent of households", size(small)) ///
    ylabel(0(20)100, labsize(small)) ///
    note("Sample: `n_nobdh' households not receiving BDH.", size(vsmall)) ///
    legend(off) graphregion(color(white)) plotregion(color(white)) ///
    name(g_cellphone_desc, replace)

graph export "`graphdir'\desc_cellphone_no_bdh.png", replace width(2200)

restore

preserve

keep if bdh_takeup == 0
drop if missing(used_internet)
count
local n_nobdh = r(N)

contract used_internet
rename _freq n
egen total = total(n)
gen pct = 100 * n / total

label define internetlbl 0 "No internet" 1 "Has internet", replace
label values used_internet internetlbl

graph bar pct, over(used_internet, label(labsize(small))) ///
    blabel(bar, format(%4.1f) color(black)) ///
    bar(1, color(green)) ///
    title("Internet Access", size(medium)) ///
    subtitle("Among non-BDH households", size(small)) ///
    ytitle("Percent of households", size(small)) ///
    ylabel(0(20)100, labsize(small)) ///
    note("Sample: `n_nobdh' households not receiving BDH.", size(vsmall)) ///
    legend(off) graphregion(color(white)) plotregion(color(white)) ///
    name(g_internet_desc, replace)

graph export "`graphdir'\desc_internet_no_bdh.png", replace width(2200)

restore

preserve

keep if bdh_takeup == 0
drop if missing(govt_satisfaction)
count
local n_nobdh = r(N)

contract govt_satisfaction
rename _freq n
egen total = total(n)
gen pct = 100 * n / total

graph bar pct, over(govt_satisfaction, label(labsize(vsmall))) ///
    blabel(bar, format(%4.1f) color(black) size(vsmall)) ///
    bar(1, color(maroon)) ///
    title("Government Satisfaction", size(medium)) ///
    subtitle("Original 1-10 score among non-BDH households", size(small)) ///
    ytitle("Percent of households", size(small)) ///
    ylabel(0(5)25, labsize(small)) ///
    note("Sample: `n_nobdh' households not receiving BDH.", size(vsmall)) ///
    legend(off) graphregion(color(white)) plotregion(color(white)) ///
    name(g_satisgovt_desc, replace)

graph export "`graphdir'\desc_satisgovt_no_bdh.png", replace width(2200)

restore

preserve

keep if bdh_takeup == 0
drop if missing(not_feel_poor)
count
local n_nobdh = r(N)

contract not_feel_poor
rename _freq n
egen total = total(n)
gen pct = 100 * n / total

label define poorlbl 0 "Does not report non-poor" 1 "Reports not feeling poor", replace
label values not_feel_poor poorlbl

graph bar pct, over(not_feel_poor, label(labsize(small))) ///
    blabel(bar, format(%4.1f) color(black)) ///
    bar(1, color(maroon)) ///
    title("Self-Perceived Poverty", size(medium)) ///
    subtitle("Among non-BDH households", size(small)) ///
    ytitle("Percent of households", size(small)) ///
    ylabel(0(20)100, labsize(small)) ///
    note("Sample: `n_nobdh' households not receiving BDH.", size(vsmall)) ///
    legend(off) graphregion(color(white)) plotregion(color(white)) ///
    name(g_nofeelpoor_desc, replace)

graph export "`graphdir'\desc_nofeelpoor_no_bdh.png", replace width(2200)

restore

graph combine g_cellphone_desc g_internet_desc ///
              g_satisgovt_desc g_nofeelpoor_desc, ///
              cols(2) ///
              title("Information and Psychological Controls Among Non-BDH Households", size(medium)) ///
              subtitle("Descriptive distributions for key control variables", size(small)) ///
              graphregion(color(white)) ///
              name(g_info_psych_panel, replace)

graph export "`graphdir'\desc_info_psych_panel_no_bdh.png", replace width(3200)

*---------------------------------------------------*
* FULL PROBIT FITTED LINE GRAPH
*---------------------------------------------------*

use "`outdir'\temp_file.dta", clear

local yvar bdh_takeup
local mainx low_density

local program_controls log_consumption log_household_size school_member elderly_member disabled_member ///
                       elderly_disqualified disabled_disqualified head_school4up ///
                       indigenous_only spent_documents birth_attendance

local info_controls has_cellphone used_internet

local psych_controls not_feel_poor govt_satisfaction

probit `yvar' `mainx' `program_controls' `info_controls' `psych_controls', vce(robust)

capture drop xb_full
capture drop phat_full

predict xb_full if e(sample), xb
predict phat_full if e(sample), pr

twoway ///
    (scatter `yvar' xb_full if e(sample), jitter(2) msymbol(o) msize(vtiny) mcolor(gs8)) ///
    (line phat_full xb_full if e(sample), sort lcolor(navy) lwidth(medthick)), ///
    yline(0 1, lpattern(dash) lcolor(gs10)) ///
    yscale(range(-.05 1.05)) ///
    ylabel(0(.2)1, angle(0)) ///
    xtitle("Probit index (Xb)") ///
    ytitle("BDH takeup / predicted probability") ///
    title("Full Probit Model: Fitted Probability Curve", size(medium)) ///
    subtitle("Observed 0/1 outcomes with fitted predicted probabilities", size(small)) ///
    note("Predicted probabilities are generated using predict after the full probit model.", size(vsmall)) ///
    legend(order(1 "Observed outcomes" 2 "Predicted probability") rows(1) pos(6)) ///
    graphregion(color(white)) ///
    plotregion(color(white))

graph export "`graphdir'\probit_full_model_fitted_line.png", replace width(2600)

log close
