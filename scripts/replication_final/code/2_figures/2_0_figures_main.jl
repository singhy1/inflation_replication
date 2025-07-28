######################################################################
# Date Created: 7/11/2025
# Last Modified: 7/11/2025
# This Code:
# - takes the processed data from /replication_final/data/processed
# - makes figures for the main text of the paper, 
# - except for Figure 6.1, Panel B
# - (See at the bottom of /code/0_process_data.py)
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
# Figure 1.1, Panel A 
######################################################################
println("Making figure for Figure 1.1, Panel A...")

df = CSV.read("$(pathdata)/figure_1_1_A.csv", DataFrame,ntasks=1)
df.date_monthly = MonthlyDate.(df.date)

filtered_df = filter(row -> MonthlyDate(2001,1) <= row.date_monthly, df)

ticks = Dates.value.(collect(df.date_monthly[2]:Month(24):MonthlyDate(2025,2)))
labels = [Dates.format(d, "yyyy-01") for d in collect(df.date_monthly[2]:Month(24):MonthlyDate(2025,2))]
p1 = plot(filtered_df.date_monthly, filtered_df.tightness, label = "", xrotation = 90)
ylims!(p1, 0.0, 2.25)
xticks!(ticks, labels)
# display(p1)
savefig(p1, "$pathfigures/figure_1_1_A.pdf")
println("Figure 1.1, Panel A processed and saved.")


######################################################################
# Figure 1.1, Panel B 
######################################################################
println("Making figure for Figure 1.1, Panel B...")

df = CSV.read("$(pathdata)/figure_1_1_B.csv", DataFrame,ntasks=1)
df.date_monthly = MonthlyDate.(df.date)

ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)+Month(12)))
labels = string.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)+Month(12)))

p1 = plot(df.date_monthly, df.price_index, label = "", xrotation = 90, color = 2)
plot!(df.date_monthly, df.predicted_price_index, label = "", linestyle = :dash, color = 2)
plot!(df.date_monthly, df.med_real_wage_index, label = "", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_med_real_wage_index, label = "", linestyle = :dash, color = 1)
annotate!(p1, df.date_monthly[66], 1.26, text(L"\textbf{CPI}", :left, 24, palette(:tab10).colors[2]))
annotate!(p1, df.date_monthly[64], 1.03, text(L"\textbf{Atlanta Fed}", :center, 24, palette(:tab10).colors[1]))
annotate!(p1, df.date_monthly[64], 1.0, text(L"\textbf{Real Wage Index}", :center, 24, palette(:tab10).colors[1]))
plot!([df.date_monthly[end], df.date_monthly[end]], [min(df.price_index[end], df.predicted_price_index[end]), max(df.price_index[end], df.predicted_price_index[end])], line=arrow(:both, 8), linewidth = 1.0, color = 2, label = "")
plot!([df.date_monthly[end], df.date_monthly[end]], [min(df.med_real_wage_index[end], df.predicted_med_real_wage_index[end]), max(df.med_real_wage_index[end], df.predicted_med_real_wage_index[end])], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
annotate!(p1, df.date_monthly[98], 1.25, text(L"\mathbf{14%}", :center, 24, palette(:tab10).colors[2]))
annotate!(p1, df.date_monthly[98], 1.1, text(L"\textbf{-3.8\%}", :center, 24, palette(:tab10).colors[1]))
ylims!(p1, 0.95, 1.35)
xlims!(p1, ticks[1], ticks[end]+12)
xticks!(ticks, labels)
# display(p1)

savefig(p1, "$pathfigures/figure_1_1_B.pdf")
println("Figure 1.1, Panel B processed and saved.")

######################################################################
# Figure 2.1, Panel A
######################################################################
println("Making figure for Figure 2.1, Panel A...")

df = CSV.read("$(pathdata)/figure_2_1.csv",DataFrame,ntasks=1)
df.date .= MonthlyDate.(df.date)
start_date = MonthlyDate("2016-01")
end_date = MonthlyDate("2024-05")
filter!(row -> start_date <= row.date <= end_date, df)
subperiod_start_date = MonthlyDate.(["2016-01" "2021-04"])
subperiod_end_date = MonthlyDate.(["2019-12" "2023-05"])
inflation_period = MonthlyDate.(["2021-04", "2023-05"])
ticks = Dates.value.(collect(minimum(df.date):Month(12):maximum(df.date)))
labels = string.(collect(minimum(df.date):Month(12):maximum(df.date)))

transform!(df, [:date, :layoff_rate_jolts] => ByRow((date, rate) -> MonthlyDate("2020-01") <= date <= MonthlyDate("2020-03") ? missing : rate) => :layoff_rate_jolts)

avg_value = [filter(row -> subperiod_start_date[i] <= row.date <= subperiod_end_date[i], df) |> x -> mean(x.layoff_rate_jolts) for i in 1:2]
p1 = plot(df.date, df.layoff_rate_jolts, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date, df.layoff_rate_jolts, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
ylims!(p1, 0.0, 1.8)
# display(p1)
savefig(p1, "$pathfigures/figure_2_1_A.pdf")
println("Figure 2.1, Panel A processed and saved.")

######################################################################
# Figure 2.1, Panel B
######################################################################
println("Making figure for Figure 2.1, Panel B...")

avg_value = [filter(row -> subperiod_start_date[i] <= row.date <= subperiod_end_date[i], df) |> x -> mean(x.quit_rate_jolts) for i in 1:2]
p1 = plot(df.date, df.quit_rate_jolts, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date, df.quit_rate_jolts, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
ylims!(p1, 0.0, 3.5)
# display(p1)
savefig(p1, "$pathfigures/figure_2_1_B.pdf")
println("Figure 2.1, Panel B processed and saved.")


######################################################################
# Figure 2.1, Panel C
######################################################################
println("Making figure for Figure 2.1, Panel C...")

avg_value = [filter(row -> subperiod_start_date[i] <= row.date <= subperiod_end_date[i], df) |> x -> mean(x.vacancy_rate_jolts) for i in 1:2]
p1 = plot(df.date, df.vacancy_rate_jolts, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date, df.vacancy_rate_jolts, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
ylims!(p1, 0.0, 8.0)
# display(p1)
savefig(p1, "$pathfigures/figure_2_1_C.pdf")
println("Figure 2.1, Panel C processed and saved.")

######################################################################
# Figure 2.2, Panel A
######################################################################
println("Making figure for Figure 2.2, Panel A...")

df = CSV.read("$(pathdata)/figure_2_2_A.csv", DataFrame)

# Define start and end dates for filtering
start_date = Date("2016-01-01")
end_date = Date("2024-12-01")

# Filter the dataframe based on the date range
filter!(row -> start_date <= row.date_monthly <= end_date, df)

# Define subperiod start and end dates
subperiod_start_date = [Date("2016-01-01"), Date("2021-04-01")]
subperiod_end_date = [Date("2019-10-01"), Date("2023-07-01")]

# Define inflation period
inflation_period = [Date("2021-04-01"), Date("2023-07-01")]

# Generate ticks and labels for the x-axis
ticks = collect(minimum(df.date_monthly):Year(1):maximum(df.date_monthly))
tick_values = Dates.value.(ticks)  # Convert Date to numeric values
labels = string.(year.(ticks)) .* "-01"  # Append "-01" to the year for labels

# Calculate average values for the subperiods
avg_value = [mean(df.ee_pol[subperiod_start_date[i] .<= df.date_monthly .<= subperiod_end_date[i]]) for i in 1:2]

# Create custom y-axis ticks from 1.8 to 2.7 in 0.3 increments
y_ticks = 1.8:0.3:2.7
y_labels = string.(round.(y_ticks, digits=1))

p1 = plot(df.date_monthly, df.ee_pol, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_monthly, df.ee_pol, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
ylims!(p1, 1.8, 2.7)
yticks!(y_ticks, y_labels)  
xticks!(tick_values, labels)
# display(p1)

savefig(p1, "$pathfigures/figure_2_2_A.pdf")
println("Figure 2.2, Panel A processed and saved.")

######################################################################
# Figure 2.2, Panel B
######################################################################
println("Making figure for Figure 2.2, Panel B...")


# Load quarterly data
df = CSV.read("$(pathdata)/figure_2_2_B.csv", DataFrame)

# Convert date_quarterly to Date format
df.date= Date.(df.date)

# Define start and end dates for filtering
start_date = Date("2016-01-01")
end_date = Date("2024-12-01")

# Filter the dataframe based on the date range
filter!(row -> start_date <= row.date <= end_date, df)

# Define subperiod start and end dates
subperiod_start_date = [Date("2016-01-01"), Date("2021-04-01")]
subperiod_end_date = [Date("2019-10-01"), Date("2023-07-01")]

# Define inflation period
inflation_period = [Date("2021-04-01"), Date("2023-07-01")]

# Generate ticks and labels for the x-axis
ticks = collect(minimum(df.date):Year(1):maximum(df.date))
tick_values = Dates.value.(ticks)  # Convert Date to numeric values
labels = string.(year.(ticks)) .* "-01"  # Append "-01" to the year for labels

# Calculate average values for the subperiods
avg_value = [mean(df.job_finding_rate_3ma[subperiod_start_date[i] .<= df.date .<= subperiod_end_date[i]]) for i in 1:2]

p1 = plot(df.date, df.job_finding_rate_3ma, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date, df.job_finding_rate_3ma, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
ylims!(p1, 15, 40)
xticks!(tick_values, labels)
# display(p1)

savefig(p1, "$pathfigures/figure_2_2_B.pdf")
println("Figure 2.2, Panel B processed and saved.")

#######################################################################
# Figure 2.3, Panel A
#######################################################################
println("Making figure for Figure 2.3, Panel A...")

# Load quarterly data
df = CSV.read("$(pathdata)/figure_2_3.csv", DataFrame)

inflation_period = MonthlyDate.(["2021-04", "2023-05"])
df.date_monthly = MonthlyDate.(df.date)

# Generate x-axis ticks every 4 months
ticks = collect(minimum(df.date_monthly):Month(6):maximum(df.date_monthly))
tick_labels = Dates.format.(ticks, "yyyy-mm")
tick_values = Dates.value.(ticks)

# Panel A 
filtered_df = filter(row -> Date("2020-10-01") <= row.date_monthly <= Date("2024-12-31"), df)
p1 = plot(filtered_df.date_monthly, filtered_df.delta_w_switch, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(filtered_df.date_monthly, filtered_df.delta_w_stay, label = "", xrotation = 90, color = 1)
plot!(filtered_df.date_monthly, filtered_df.delta_w_switch, label = "", xrotation = 90, color = 2, linestyle = :dash)
annotate!(p1, filtered_df.date_monthly[18], 6.5, text("Job Stayers", :left, 24, "black"))
annotate!(p1, filtered_df.date_monthly[17], 11., text("Job Changers", :left, 24, "black"))
ylims!(p1, 0.0, 18.0)
xticks!(tick_values, tick_labels)
# display(p1)
savefig(p1, "$pathfigures/figure_2_3_A.pdf")
println("Figure 2.3, Panel A processed and saved.")

#######################################################################
# Figure 2.3, Panel B
#######################################################################
println("Making figure for Figure 2.3, Panel B...")

p1 = scatter(df.P_12m_change, df.diff, label = "", xlabel = "Monthly Inflation Rate", markersize = 7, smooth = true, color = 1)
ylabel!(L"\parbox{15em}{\centering Monthly Difference in Wage Growth,\\ Changers vs Stayers}", labelfontsize = 24)
xticks!(2:1:8)
yticks!(2:1:8)
# display(p1)
savefig(p1, "$pathfigures/figure_2_3_B.pdf")
println("Figure 2.3, Panel B processed and saved.")

######################################################################
# Figure 2.4, Panel A
######################################################################
println("Making figure for Figure 2.4, Panel A...")

df = CSV.read("$(pathdata)/figure_2_4.csv", DataFrame)

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
# display(p1)

# Save to file
savefig(p1, "$pathfigures/figure_2_4_A.pdf")
println("Figure 2.4, Panel A processed and saved.")

######################################################################
# Figure 2.4, Panel B
######################################################################
println("Making figure for Figure 2.4, Panel B...")

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
# display(p1)

# Save to file
savefig(p1, "$pathfigures/figure_2_4_B.pdf")
println("Figure 2.4, Panel B processed and saved.")

######################################################################
# Figure 2.4, Panel C
######################################################################
println("Making figure for Figure 2.4, Panel C...")

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
# display(p1)

# Save to file
savefig(p1, "$pathfigures/figure_2_4_C.pdf")
println("Figure 2.4, Panel C processed and saved.")

######################################################################
# Figure 6.1, Panel A
######################################################################
println("Making figure for Figure 6.1, Panel A...")

df = CSV.read("$(pathdata)/figure_6_1.csv", DataFrame,ntasks=1)
df.date_monthly = MonthlyDate.(df.date)

filtered_df = filter(row -> MonthlyDate(1951,1) <= row.date_monthly, df)
#ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))
#labels = string.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))
ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):MonthlyDate(2025,12)))
labels = string.(collect(minimum(df.date_monthly):Month(12):MonthlyDate(2025,12)))

labels = [label[1:4] for label in labels]

p1 = plot(filtered_df.date_monthly, filtered_df."tightness", label = "", xrotation = 90)
hline!(p1, [mean(filtered_df."tightness")], linestyle = :dash, label = "", color = 1)
scatter!([filtered_df.date_monthly[221], filtered_df.date_monthly[455], filtered_df.date_monthly[590], filtered_df.date_monthly[825]], [1.52, 0.85, 1.05, 1.27], label = "", markershape = :utriangle, markersize = 25, markeralpha = 0.0, markerstrokealpha = 1.0, markerstrokecolor = 3, markerstrokewidth = 3)
scatter!([filtered_df.date_monthly[30], filtered_df.date_monthly[270], filtered_df.date_monthly[340], filtered_df.date_monthly[860]], [1.7, 1.05, 0.95, 2.02], label = "", markershape = :circle, markersize = 20, markeralpha = 0.0, markerstrokealpha = 1.0, markerstrokecolor = 2, markerstrokewidth = 3)
ylims!(p1, 0.0, 2.2)
xticks!([ticks[2:5:end]; ticks[end]], [labels[2:5:end]; labels[end]])
# display(p1)
savefig(p1, "$pathfigures/figure_6_1_A.pdf")
println("Figure 6.1, Panel A processed and saved.")

