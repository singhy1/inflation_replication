import subprocess
import os
import time

# Record start time
start_time = time.time()
print(f"Script started at: {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(start_time))}")

# set the directory of this file as working directory (replication_final/code)
# If you are using IPython, comment this line and set the working directory manually
os.chdir(os.path.dirname(os.path.abspath(__file__)))
print(f"Current working directory: {os.getcwd()}") 

# Adjust executable paths as necessary
STATA_EXEC = "/Applications/StataNow/StataMP.app/Contents/MacOS/stata-mp"
JULIA_EXEC = "/Users/giyoung/.julia/juliaup/julia-1.11.6+0.aarch64.apple.darwin14/bin/julia"
R_EXEC = "/usr/local/bin/Rscript"  
PYTHON = "python3" # Adjust this to "python" if you are using Python 2.x

# # Yash Paths 

# # Adjust executable paths as necessary
# STATA_EXEC = "C:/Program Files/StataNow19/StataMP-64.exe"
# JULIA_EXEC = "C:/Users/singhy/AppData/Local/Programs/Julia-1.11.2/bin/julia.exe"
# R_EXEC = "C:/Program Files/R/R-4.3.1/bin/Rscript.exe"  
# PYTHON = "C:/Users/singhy/AppData/Local/Programs/Python/Python311/python.exe" 


################################################################## 1. Main Text Figures
################################################################# 1-1. Process Raw Data
print("============================================================")
print("Started processing raw data for main text figures...")
print("============================================================")
subprocess.run([STATA_EXEC, "-b", "do", "./1_process/1_0_process_main.do"], check=True)
subprocess.run([f"{PYTHON}", "1_process/1_1_process_main.py"], check=True)
print("Finished processing raw data for main text figures.")

########################################################### 1-1. Make Main Text Figures
print("============================================================")
print("Started making main text figures...")
print("============================================================")
subprocess.run([JULIA_EXEC, "./2_figures/2_0_figures_main.jl"], check=True)
subprocess.run([f"{PYTHON}", "./2_figures/2_1_figures_main.py"], check=True)
print("Finished making main text figures.")

################################################################### 2. Appendix Figures
#################################################### 2-1. Process Raw Data for Appendix
print("============================================================")
print("Started processing raw data for appendix figures...")
print("============================================================")
subprocess.run([STATA_EXEC, "-b", "do", "./1_process/1_2_process_appendix.do"], check=True)
subprocess.run([f"{PYTHON}", "./1_process/1_3_process_appendix.py"], check=True)
print("Finished processing raw data for appendix figures.")

############################################################# 2-2. Make Appendix Figures
print("============================================================")
print("Started making appendix figures...")
print("============================================================")
subprocess.run([JULIA_EXEC, "./2_figures/2_2_figures_appendix.jl"], check=True)
subprocess.run([f"{PYTHON}", "./2_figures/2_3_figures_appendix.py"], check=True)
print("Finished making appendix figures.")

############################################################################## 3. Tables
print("============================================================")
print("Started making main text tables...")
print("============================================================")
subprocess.run([f"{PYTHON}", "./3_tables/3_0_tables_main.py"], check=True)
print("Finished making main text tables.")

print("============================================================")
print("Started making appendix tables...")
print("============================================================")
subprocess.run([f"{PYTHON}", "./3_tables/3_1_tables_appendix.py"], check=True)
subprocess.run([STATA_EXEC, "-b", "do", "./3_tables/3_2_tables_appendix.do"], check=True)
print("Finished making appendix tables.")

############################################################################## 4. Moments
print("============================================================")
print("Started generating moments...")
print("============================================================")
subprocess.run([STATA_EXEC, "-b", "do", "./4_moments/4_0_build.do"], check=True)
subprocess.run([R_EXEC, "./4_moments/4_1_get_flows.R"], check=True)
subprocess.run([STATA_EXEC, "-b", "do", "./4_moments/4_2_get_moments.do"], check=True)
subprocess.run([STATA_EXEC, "-b", "do", "./4_moments/4_3_dispersion_moments.do"], check=True)
print("Finished generating moments.")

# remove all .log files
print("Removing all STATA log files...")
log_files = [f for f in os.listdir('.') if f.endswith('.log')]
for log_file in log_files:
    os.remove(log_file)

# Calculate and display total running time
end_time = time.time()
total_time = end_time - start_time
hours = int(total_time // 3600)
minutes = int((total_time % 3600) // 60)
seconds = int(total_time % 60)

print("============================================================")
print(f"\nScript completed at: {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(end_time))}")
print(f"Total running time: {hours:02d}:{minutes:02d}:{seconds:02d} ({total_time:.2f} seconds)")
print("Project replication completed successfully!")
print("============================================================")
