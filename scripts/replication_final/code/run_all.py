import subprocess
import os

# set the directory of this file as working directory (replication_final/code)
# If you are using IPython, comment this line and set the working directory manually
os.chdir(os.path.dirname(os.path.abspath(__file__)))
print(f"Current working directory: {os.getcwd()}") 

# Adjust executable paths as necessary
STATA_EXEC = "/Applications/StataNow/StataMP.app/Contents/MacOS/stata-mp"
JULIA_EXEC = "/Applications/Julia-1.11.app/Contents/Resources/julia/bin/julia" 
R_EXEC = "/usr/local/bin/Rscript"  
PYTHON = "python3" # Adjust this to "python" if you are using Python 2.x

################################################################## 1. Main Text Figures
################################################################# 1-1. Process Raw Data
print("Started processing raw data for main text figures...")
subprocess.run([STATA_EXEC, "-b", "do", "./1_process/1_0_process_main.do"], check=True)
subprocess.run([f"{PYTHON}", "1_process/1_1_process_main.py"], check=True)
print("Finished processing raw data for main text figures.")

########################################################### 1-1. Make Main Text Figures
print("Started making main text figures...")
subprocess.run([JULIA_EXEC, "./2_figures/2_0_figures_main.jl"], check=True)
subprocess.run([f"{PYTHON}", "./2_figures/2_1_figures_main.py"], check=True)
print("Finished making main text figures.")

################################################################### 2. Appendix Figures
#################################################### 2-1. Process Raw Data for Appendix
print("Started processing raw data for appendix figures...")
subprocess.run([STATA_EXEC, "-b", "do", "./1_process/1_2_process_appendix.do"], check=True)
subprocess.run([f"{PYTHON}", "./1_process/1_3_process_appendix.py"], check=True)
print("Finished processing raw data for appendix figures.")

############################################################# 2-2. Make Appendix Figures
print("Started making appendix figures...")
subprocess.run([JULIA_EXEC, "./2_figures/2_2_figures_appendix.jl"], check=True)
subprocess.run([f"{PYTHON}", "./2_figures/2_3_figures_appendix.py"], check=True)
print("Finished making appendix figures.")

############################################################################## 3. Tables
print("Started making main text tables...")
subprocess.run([f"{PYTHON}", "./3_tables/3_0_tables_main.py"], check=True)
print("Finished making main text tables.")

print("Started making appendix tables...")
subprocess.run([f"{PYTHON}", "./3_tables/3_1_tables_appendix.py"], check=True)
subprocess.run([STATA_EXEC, "-b", "do", "./3_tables/3_2_tables_appendix.do"], check=True)
print("Finished making appendix tables.")

############################################################################## 4. Moments
print("Started generating moments...")
subprocess.run([STATA_EXEC, "-b", "do", "./4_moments/4_0_build.do"], check=True)
subprocess.run([R_EXEC, "./4_moments/4_1_get_flows.R"], check=True)
subprocess.run([STATA_EXEC, "-b", "do", "./4_moments/4_2_get_moments.do"], check=True)
subprocess.run([STATA_EXEC, "-b", "do", "./4_moments/4_3_dispersion_moments.do"], check=True)
print("Finished generating moments.")
