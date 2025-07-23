######################################################################
# Date Created: 7/13/2025
# Last Modified: 7/13/2025
# This Code:
# - takes the processed data from /replication_final/data/processed
# - makes the following figures: Figure B.6 and Figure B.8
######################################################################

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

# Detect if OS is Windows
is_win = Sys.iswindows()

# Get username  
user = get(ENV, "USER", get(ENV, "USERNAME", ""))

# Define base project path
if is_win
    proj_dir = joinpath("C:/Users", user, "Dropbox", "Labor_Market_PT", "replication", "final")
else
    proj_dir = joinpath("/Users", user, "Library", "CloudStorage", "Dropbox", "Labor_Market_PT", "replication", "final")
end

const pathfigures = "$proj_dir/output/figures"
const pathdata = "$proj_dir/data/processed"

# Plot Settings 
pgfplotsx()
# plot() # test plot to check if PGFPlotsX is working
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

######################################################################
# Figure B.6, Panel A
######################################################################
println("Making figure for Figure B.6, Panel A...")

df = CSV.read("$(pathdata)/figure_2_4.csv", DataFrame,ntasks=1)
df.date_monthly = MonthlyDate.(df.date)

ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)+Month(12)))
labels = string.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)+Month(12)))

p1 = plot(df.date_monthly, df.real_wage_index_2, label = "", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_real_wage_index_2, label = "", linestyle = :dash, color = 1, linewidth = 1.0)
plot!([df.date_monthly[end], df.date_monthly[end]], [min(df.real_wage_index_2[end], df.predicted_real_wage_index_2[end]), max(df.real_wage_index_2[end], df.predicted_real_wage_index_2[end])], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
annotate!(p1, df.date_monthly[end]+Month(2), 1.13, text(L"\textbf{-1.5\%}", :center, 24, palette(:tab10).colors[1]))
ylims!(p1, 0.96, 1.20)
xlims!(p1, ticks[1], ticks[end]+9)
xticks!(ticks, labels)
# display(p1)
savefig(p1, "$pathfigures/figure_B_6_A.pdf")
println("Figure B.6, Panel A processed and saved.")

######################################################################
# Figure B.6, Panel B
######################################################################
println("Making figure for Figure B.6, Panel B...")

p1 = plot(df.date_monthly, df.real_wage_index_3, label = "", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_real_wage_index_3, label = "", linestyle = :dash, color = 1, linewidth = 1.0)
plot!([df.date_monthly[end], df.date_monthly[end]], [min(df.real_wage_index_3[end], df.predicted_real_wage_index_3[end]), max(df.real_wage_index_3[end], df.predicted_real_wage_index_3[end])], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
annotate!(p1, df.date_monthly[end]+Month(2), 1.13, text(L"\textbf{-4.1\%}", :center, 24, palette(:tab10).colors[1]))
ylims!(p1, 0.96, 1.20)
xlims!(p1, ticks[1], ticks[end]+9)
xticks!(ticks, labels)
# display(p1)
savefig(p1, "$pathfigures/figure_B_6_B.pdf")
println("Figure B.6, Panel B processed and saved.")

######################################################################
# Figure B.8, Panel A
######################################################################
println("Making figure for Figure B.8, Panel A...")

df = CSV.read("$(pathdata)/figure_B_8.csv", DataFrame)

inflation_period = MonthlyDate.(["2021-04", "2023-05"])
df.date_monthly = MonthlyDate.(df.date)

# Generate x-axis ticks every 6 months
ticks = collect(minimum(df.date_monthly):Month(6):maximum(df.date_monthly))
tick_labels = Dates.format.(ticks, "yyyy-mm")
tick_values = Dates.value.(ticks)

# Panel A: All Workers 
filtered_df = filter(row -> Date("2020-01-01") <= row.date_monthly <= Date("2024-12-31"), df)

# Initialize plot with invisible educ line to set up axis   
p1 = plot(filtered_df.date_monthly, filtered_df.q4_Pooled,
    label = "", xrotation = 90, alpha = 0.0)

# Add shaded inflation period
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)

plot!(filtered_df.date_monthly, filtered_df.q1_Pooled,
    label = "Quartile 1", color = 2, linestyle = :dash)

plot!(filtered_df.date_monthly, filtered_df.q4_Pooled,
    label = "Quartile 4", color = 1)

# Add horizontal line at y = 0
hline!([0], color = :black, linestyle = :solid, label = "")

ylims!(p1, -10, 5)         
yticks!(p1, -10:2:5)        

xticks!(tick_values, tick_labels)

# Add legend and display
plot!(legend = :topright)
# display(p1)

# Save to file
savefig(p1, "$pathfigures/figure_B_8_A.pdf")

println("Figure B.8, Panel A processed and saved.")

##########################################################################
# Figuure B.8, Panel B
##########################################################################
println("Processing data for Figure B.8, Panel B...")
# Panel B: Education < 16 
filtered_df = filter(row -> Date("2020-01-01") <= row.date_monthly <= Date("2024-12-31"), df)

p1 = plot(filtered_df.date_monthly, filtered_df.Bachelor_plus_1st_Quartile,
    label = "", xrotation = 90, alpha = 0.0)

# Add shaded inflation period
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)


plot!(filtered_df.date_monthly, filtered_df.Less_Bachelor_1st_Quartile,
    label = "Quartile 1", color = 2, linestyle = :dash)

plot!(filtered_df.date_monthly, filtered_df.Less_Bachelor_4th_Quartile,
    label = "Quartile 4", color = 1)

# Add horizontal line at y = 0
hline!([0], color = :black, linestyle = :solid, label = "")

ylims!(p1, -10, 5)         
yticks!(p1, -10:2:5)        

xticks!(tick_values, tick_labels)

# Add legend and display
plot!(legend = :topright)
# display(p1)

# Save to file
savefig(p1, "$pathfigures/figure_B_8_B.pdf")

println("Figure B.8, Panel B processed and saved.")

######################################################################
# Figure B.8, Panel C
######################################################################
println("Processing data for Figure B.8, Panel C...")
# Panel C: Education >= 16 
filtered_df = filter(row -> Date("2020-01-01") <= row.date_monthly <= Date("2024-12-31"), df)

# Initialize plot with invisible WFH line to set up axis
p1 = plot(filtered_df.date_monthly, filtered_df.Bachelor_plus_4th_Quartile,
    label = "", xrotation = 90, alpha = 0.0)

# Add shaded inflation period
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)

plot!(filtered_df.date_monthly, filtered_df.Bachelor_plus_1st_Quartile,
    label = "Quartile 1", color = 2, linestyle = :dash)

plot!(filtered_df.date_monthly, filtered_df.Bachelor_plus_4th_Quartile,
    label = "Quartile 4", color = 1)

# Add horizontal line at y = 0
hline!([0], color = :black, linestyle = :solid, label = "")

ylims!(p1, -10, 5)         
yticks!(p1, -10:2:5)        

xticks!(tick_values, tick_labels)

# Add legend and display
plot!(legend = :topright)
# display(p1)

# Save to file
savefig(p1, "$pathfigures/figure_B_8_C.pdf")
println("Figure B.8, Panel C processed and saved.")

######################################################################
# Figure B.14, Panel A
######################################################################
println("Processing data for Figure B.14, Panel A...")

df = CSV.read("$(pathdata)/figure_B_14_A.csv", DataFrame)

# Convert date strings like "2016q1" to QuarterlyDate
using PeriodicalDates, Dates
df.date = QuarterlyDate.(Date.(df.date))


# Filter to the full analysis window
start_date = QuarterlyDate("2016-Q1")
end_date = QuarterlyDate("2024-Q4")
filter!(row -> start_date <= row.date <= end_date, df)

# Define subperiods as separate vectors
subperiod_start_date = QuarterlyDate.(["2016-Q1", "2021-Q2"])
subperiod_end_date = QuarterlyDate.(["2019-Q4", "2023-Q2"])
inflation_period = QuarterlyDate.(["2021-Q2", "2023-Q2"])

# Generate x-axis ticks and labels (one per year)
ticks = Dates.value.(collect(minimum(df.date):Quarter(4):maximum(df.date)))
labels = string.(collect(minimum(df.date):Quarter(4):maximum(df.date)))

# Convert profit share to fraction
df.profit_share ./= 100.0

# Calculate average profit share for subperiods
avg_value = [
    mean(filter(row -> subperiod_start_date[i] <= row.date <= subperiod_end_date[i], df).profit_share)
    for i in 1:2
]

# Plotting
p1 = plot(df.date, df.profit_share, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date, df.profit_share, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")

# Formatting
ylims!(p1, 0.0, 0.14)
xticks!(ticks, labels)

# Show and save
# display(p1)
savefig(p1, "$(pathfigures)/figure_B_14_A.pdf")
println("Figure B.14, Panel A processed and saved.")