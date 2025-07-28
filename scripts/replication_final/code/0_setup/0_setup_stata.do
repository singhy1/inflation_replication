********************************************************************************
* Stata Setup for Replication
* =============================
* This script checks and installs required packages for the replication study
********************************************************************************

clear all
set more off

display as text "Stata Setup for Replication Study"
display as text "=================================="

* Check Stata version
if c(stata_version) < 16 {
    display as error "Warning: This replication requires Stata 16 or higher."
    display as error "You are running Stata version " c(stata_version)
}
else {
    display as result "✓ Stata version " c(stata_version) " - OK"
}

********************************************************************************
* Check and install required packages
********************************************************************************

display as text _newline "Checking required packages..."

* Check egenmore
capture which egenmore
if _rc != 0 {
    display as text "Installing egenmore..."
    ssc install egenmore
    display as result "✓ egenmore installed"
}
else {
    display as result "✓ egenmore already installed"
}

* Check esttab
capture which esttab
if _rc != 0 {
    display as text "Installing esttab..."
    ssc install esttab
    display as result "✓ esttab installed"
}
else {
    display as result "✓ esttab already installed"
}

********************************************************************************
* Summary
********************************************************************************

display as text _newline "Setup completed!"
display as text "Stata is ready for replication."