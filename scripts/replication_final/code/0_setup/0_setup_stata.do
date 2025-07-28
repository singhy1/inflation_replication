* Stata Package Setup for Replication
* ====================================
* This do-file installs all required Stata packages for the replication study
* Run this file before executing any Stata do-files in the replication

* INSTRUCTIONS:
* 1. Make sure you have Stata 16+ installed (some commands may work with Stata 14+)
* 2. Open Stata
* 3. Run this do-file: do "0_setup_stata.do"
* 4. Alternatively, copy and paste commands into Stata command window

capture log close
clear all
set more off

display "Setting up Stata environment for replication study..."
display _dup(60) "="

* Check Stata version
display "Stata version: " c(stata_version)
display "Stata edition: " c(edition)

* Most packages used in the replication are built-in Stata commands
* The code primarily uses:
* - Standard data manipulation commands (gen, replace, collapse, merge, etc.)
* - Regression commands (reg, logit, etc.)
* - File I/O commands (import, export, save, use)
* - String functions (regexm, regexs, subinstr, etc.)
* - Graph commands (twoway, histogram, etc.)

* Check if commonly used commands are available
display ""
display "Checking availability of key Stata commands..."

* Test basic commands
capture which collapse
if _rc == 0 {
    display "✓ collapse command available"
} else {
    display "✗ collapse command not found"
}

capture which merge
if _rc == 0 {
    display "✓ merge command available"
} else {
    display "✗ merge command not found"
}

capture which regexm
if _rc == 0 {
    display "✓ regex functions available"
} else {
    display "✗ regex functions not found (need Stata 14+)"
}

capture which import
if _rc == 0 {
    display "✓ import commands available"
} else {
    display "✗ import commands not found"
}

* Check for file format support
capture import delimited using "nonexistent_file.csv", clear
if _rc == 601 | _rc == 602 {
    display "✓ CSV import functionality available"
} else if _rc == 199 {
    display "✗ import delimited not available (need Stata 13+)"
}

* Test Excel import capability
capture import excel using "nonexistent_file.xlsx", clear firstrow
if _rc == 601 | _rc == 602 {
    display "✓ Excel import functionality available"
} else if _rc == 199 {
    display "✗ import excel not available"
}

* Additional packages that might be useful (optional):
* These are not strictly required for the replication but may be helpful

local optional_packages "estout outreg2 binscatter"

display ""
display "Checking optional packages (not required but recommended)..."

foreach pkg of local optional_packages {
    capture which `pkg'
    if _rc == 0 {
        display "✓ `pkg' is installed"
    } else {
        display "- `pkg' not installed (optional)"
        display "  To install: ssc install `pkg'"
    }
}

display ""
display _dup(60) "="
display "Stata setup check completed!"
display ""
display "IMPORTANT NOTES:"
display "1. This replication uses built-in Stata commands"
display "2. Requires Stata 14+ for regex functions"
display "3. Requires Stata 13+ for modern import commands"
display "4. Excel files require appropriate import functionality"
display ""
display "If you encounter command not found errors:"
display "1. Update to Stata 16+ if possible"
display "2. Check if your Stata edition supports required features"
display "3. Some functionality may require Stata/MP or Stata/SE"
display ""
display "For user-written packages (if needed):"
display "- Use: ssc install package_name"
display "- Use: net install package_name"

* Display system information
display ""
display "System Information:"
display "Stata version: " c(stata_version)
display "Edition: " c(edition)
display "OS: " c(os)
display "Processors: " c(processors)
display "Memory: " c(memory)

* Set recommended settings for replication
set more off
set linesize 120
version 16  // Set version for compatibility

display ""
display "Recommended Stata settings applied:"
display "- set more off"
display "- set linesize 120"
display "- version 16"
