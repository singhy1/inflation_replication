
global data_dir "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/raw_data"
global temp_dir "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/temp"
global output_dir "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/output" 
global script_dir "C:/Users/singhy/Desktop/Chicago/cps_data/inflation/scripts/micro_flows"

global R_dir "C:/Program Files/R/R-4.3.1/bin/Rscript.exe" 


shell "${R_dir}" --vanilla 1_prepare_cmie.R > cmie_log.txt 2>&1 

cd "$"