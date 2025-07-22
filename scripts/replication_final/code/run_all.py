# You must stand at master > code to run this script.

import subprocess
import os

STATA_EXEC = "/Applications/StataNow/StataMP.app/Contents/MacOS/stata-mp"
JULIA_EXEC = "/Applications/Julia-1.11.app/Contents/Resources/julia/bin/julia"

### 1. Main Text Figures
## 1-1. Process Raw Data
print("----------------------------------------------------")
print("Started processing raw data for main text figures...")
print("----------------------------------------------------")
subprocess.run([STATA_EXEC, "-b", "do", "./1_process/1_0_process_main.do"], check=True)
subprocess.run(["python", "1_process/1_1_process_main.py"], check=True)
print("Finished processing raw data for main text figures...")
print("----------------------------------------------------")

## 1-1. Make Main Text Figures
print("----------------------------------------------------")
print("Started making main text figures...")
print("----------------------------------------------------")
subprocess.run([JULIA_EXEC, "./1_make_figures_main.jl"], check=True)
print("Finished making main text figures...")
print("----------------------------------------------------")   

### 2. Appendix Figures
## 2-1. Process Raw Data for Appendix
print("----------------------------------------------------")
print("Started processing raw data for appendix figures...")
print("----------------------------------------------------")
subprocess.run([STATA_EXEC, "-b", "do", "./2_process_data_appendix.do"], check=True)
subprocess.run(["python", "./2_process_data_appendix.py"], check=True)
print("Finished processing raw data for appendix figures...")
print("----------------------------------------------------")   

## 2-2. Make Appendix Figures
print("----------------------------------------------------")
print("Started making appendix figures...")
print("----------------------------------------------------")
subprocess.run(["python", "./3_make_figures_appendix.py"], check=True)
subprocess.run([JULIA_EXEC, "./3_make_figures_appendix.jl"], check=True)
print("Finished making appendix figures...")
print("----------------------------------------------------")   




