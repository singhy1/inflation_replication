

# Necessary packages 
using Statistics
using Binscatters
using CategoricalArrays
using CSV
using DataFrames
using DataFramesMeta
using Dates
using DelimitedFiles
using FileIO
using LaTeXStrings
using PanelDataTools
using PeriodicalDates
using PGFPlotsX
using Plots
using Revise 


# Set user path
#const user = "AndresD" # "AndresB" or "AndresD"  
#const user = "singhy" # "AndresB" or "AndresD" 

const user = ENV["USERNAME"] 

if (user == "AndresB")     
    pathfolder = "$(homedir())/Dropbox (ATL FRB)/papers_new/Labor_Market_PT" 
elseif (user == "AndresD")     
    pathfolder = "$(homedir())/Dropbox/Research/Labor_Market_PT" 
elseif (user == "AndresDserver")     
    pathfolder = "/data0/Dropbox/Research/Labor_Market_PT/" 
elseif (user == "singhy")     
    println("Yash is here ")     
    pathfolder = "C:/Users/singhy/Dropbox/Labor_Market_PT/"
end

const pathfigures = "$pathfolder/replication/empirical/outputs/figures"
const pathdata = "$pathfolder/replication/empirical/outputs/processed_data"

pgfplotsx()
plot()
plot_font = "Computer Modern"
Plots.default(fontfamily=plot_font,
legendfonthalign = :left,
legend=:topleft;
xtickfontsize = 26,
ytickfontsize = 26,
ztickfontsize = 26,
tickfontsize = 26,
legendfontsize = 30,
xlabelfontsize = 30,
ylabelfontsize = 30,
zlabelfontsize = 30,
labelfontsize = 30,
titlefontsize = 26,
markersize = 10,
linewidth = 3,
size = (800, 600))

using CSV
using DataFrames
using Dates
using Plots

using CSV
using DataFrames
using Dates
using Plots




using CSV, DataFrames, Dates, Statistics, Plots

using CSV, DataFrames, Dates, Plots, Statistics

# Load quarterly data
df = CSV.read("$(pathdata)/wage_g_diff_atlFed.csv", DataFrame)

inflation_period = MonthlyDate.(["2021-04", "2023-05"])
df.date_monthly = MonthlyDate.(df.date)

# Generate x-axis ticks every 4 months
ticks = collect(minimum(df.date_monthly):Month(6):maximum(df.date_monthly))
tick_labels = Dates.format.(ticks, "yyyy-mm")
tick_values = Dates.value.(ticks)


# Panel A 
filtered_df = filter(row -> Date("2020-10-01") <= row.date_monthly <= Date("2024-12-31"), df)
p1 = plot(filtered_df.date_monthly, filtered_df.Job_Switcher, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(filtered_df.date_monthly, filtered_df.Job_Stayer, label = "", xrotation = 90, color = 1)
plot!(filtered_df.date_monthly, filtered_df.Job_Switcher, label = "", xrotation = 90, color = 2, linestyle = :dash)
annotate!(p1, filtered_df.date_monthly[18], 6.5, text("Job Stayers", :left, 24, "black"))
annotate!(p1, filtered_df.date_monthly[17], 11., text("Job Changers", :left, 24, "black"))
ylims!(p1, 0.0, 18.0)
xticks!(tick_values, tick_labels)
display(p1)
savefig(p1, "$pathfigures/fig_atl_wage_trends.pdf")

# Panel B 
p1 = scatter(df.P_12m_change, df.diff, label = "", xlabel = "Monthly Inflation Rate", markersize = 7, smooth = true, color = 1)
ylabel!(L"\parbox{15em}{\centering Monthly Difference in Wage Growth,\\ Changers vs Stayers}", labelfontsize = 24)
xticks!(2:1:8)
yticks!(2:1:8)
display(p1)
savefig(p1, "$pathfigures/fig_atl_wage_trends_diff.pdf")