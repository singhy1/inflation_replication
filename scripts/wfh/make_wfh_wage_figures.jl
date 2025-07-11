
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
    pathfolder = "C:/Users/singhy/Dropbox/Labor_Market_PT"
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

########################################################################
# work from home wage data 
########################################################################


df = CSV.read("$(pathdata)/wfh_wage_plot_data.csv", DataFrame)

inflation_period = MonthlyDate.(["2021-04", "2023-05"])
df.date_monthly = MonthlyDate.(df.date)

# Generate x-axis ticks every 6 months
ticks = collect(minimum(df.date_monthly):Month(6):maximum(df.date_monthly))
tick_labels = Dates.format.(ticks, "yyyy-mm")
tick_values = Dates.value.(ticks)


# Panel B: Quartile 4 
filtered_df = filter(row -> Date("2020-01-01") <= row.date_monthly <= Date("2024-12-31"), df)

# Initialize plot with invisible WFH line to set up axis
p1 = plot(filtered_df.date_monthly, filtered_df.WFH_Pooled,
    label = "", xrotation = 90, alpha = 0.0)

# Add shaded inflation period
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)

# Add WFH and No WFH lines
plot!(filtered_df.date_monthly, filtered_df.WFH_Pooled,
    label = "WFH", color = 1)
plot!(filtered_df.date_monthly, filtered_df.No_WFH_Pooled,
    label = "No WFH", color = 2, linestyle = :dash)

# Add horizontal line at y = 0
hline!([0], color = :black, linestyle = :solid, label = "")

ylims!(p1, -10, 5)         
yticks!(p1, -10:2:5)        

xticks!(tick_values, tick_labels)

# Add legend and display
plot!(legend = :topright)
display(p1)

# Save to file
savefig(p1, "$pathfigures/fig_wfh_wage_pooled.pdf")


# Panel B: Quartile 4 
filtered_df = filter(row -> Date("2020-01-01") <= row.date_monthly <= Date("2024-12-31"), df)

# Initialize plot with invisible WFH line to set up axis
p1 = plot(filtered_df.date_monthly, filtered_df.WFH_1st_Quartile,
    label = "", xrotation = 90, alpha = 0.0)

# Add shaded inflation period
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)

# Add WFH and No WFH lines
plot!(filtered_df.date_monthly, filtered_df.WFH_4th_Quartile,
    label = "WFH", color = 1)
plot!(filtered_df.date_monthly, filtered_df.No_WFH_4th_Quartile,
    label = "No WFH", color = 2, linestyle = :dash)

# Add horizontal line at y = 0
hline!([0], color = :black, linestyle = :solid, label = "")

ylims!(p1, -10, 5)         
yticks!(p1, -10:2:5)        

xticks!(tick_values, tick_labels)

# Add legend and display
plot!(legend = :topright)
display(p1)

# Save to file
savefig(p1, "$pathfigures/fig_wfh_wage_q4.pdf")



# Panel B: Quartile 1 
filtered_df = filter(row -> Date("2020-01-01") <= row.date_monthly <= Date("2024-12-31"), df)

# Initialize plot with invisible WFH line to set up axis
p1 = plot(filtered_df.date_monthly, filtered_df.WFH_1st_Quartile,
    label = "", xrotation = 90, alpha = 0.0)

# Add shaded inflation period
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)

# Add WFH and No WFH lines
plot!(filtered_df.date_monthly, filtered_df.WFH_1st_Quartile,
    label = "WFH", color = 1)
plot!(filtered_df.date_monthly, filtered_df.No_WFH_1st_Quartile,
    label = "No WFH", color = 2, linestyle = :dash)

# Add horizontal line at y = 0
hline!([0], color = :black, linestyle = :solid, label = "")

ylims!(p1, -10, 5)         
yticks!(p1, -10:2:5)        

xticks!(tick_values, tick_labels)

# Add legend and display
plot!(legend = :topright)
display(p1)

# Save to file
savefig(p1, "$pathfigures/fig_wfh_wage_q1.pdf")

