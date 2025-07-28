# Yash Singh 
# 2/3/25 
# goal: make all the empirical figures in the paper 


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

const pathfigures = "$pathfolder/codes/data/figures"
const pathdata = "$pathfolder/codes/data/input"

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





######################################################################
# Figure 1, Panel A 
######################################################################

df = CSV.read("$(pathdata)/historical_data_feb.csv", DataFrame,ntasks=1)
df.date_monthly = MonthlyDate.(df.date)

filtered_df = filter(row -> MonthlyDate(2001,1) <= row.date_monthly, df)

ticks = Dates.value.(collect(df.date_monthly[2]:Month(24):MonthlyDate(2025,2)))
labels = [Dates.format(d, "yyyy-01") for d in collect(df.date_monthly[2]:Month(24):MonthlyDate(2025,2))]
#ticks = Dates.value.(collect(df.date_monthly[2]:Month(24):maximum(df.date_monthly)))
#labels = [Dates.format(d, "yyyy-01") for d in collect(df.date_monthly[2]:Month(24):maximum(df.date_monthly))]

p1 = plot(filtered_df.date_monthly, filtered_df.tightness, label = "", xrotation = 90)
ylims!(p1, 0.0, 2.25)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/market_tightness_jolts_feb.pdf")




print(kkk)



























#######################################################
# Figure 3, Panel A 
#######################################################

# Load quarterly data
df = CSV.read("$(pathdata)/ee_monthly.csv", DataFrame)


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

# Generate ticks and labels for the x-axis
#ticks = collect(minimum(df.date_quarterly):Year(1):maximum(df.date_quarterly))
#tick_values = Dates.value.(ticks)  # Convert Date to numeric values
#labels = string.(year.(ticks))  # Use year as labels

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
display(p1)

savefig(p1, "$pathfigures/ee_monthly.pdf")


# Load data
df = CSV.read("$(pathdata)/eu_rate.csv", DataFrame)
df.date_monthly = MonthlyDate.(df.date)

df.date_monthly = MonthlyDate.(df.date)
subperiod_start_date = MonthlyDate.(["2016-01" "2021-04"])
subperiod_end_date = MonthlyDate.(["2019-12" "2023-05"])
inflation_period = MonthlyDate.(["2021-04", "2023-05"])
ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))
labels = string.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))


# Set eu_rate to missing for the specified date range
transform!(df, [:date_monthly, :eu_rate] => ByRow((date, rate) -> date == MonthlyDate("2020-04") ? missing : rate) => :eu_rate)

avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x."eu_rate") for i in 1:2]

# Restrict to 2016–2024
df = filter(:date_monthly => d -> MonthlyDate("2016-01") <= d <= MonthlyDate("2024-12"), df)


p1 = plot(df.date_monthly, df."eu_rate", label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_monthly, df."eu_rate", label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
display(p1)
ylims!(p1, 0.0, 0.04)
savefig(p1, "$pathfigures/fig_eu_rate_fred.pdf")








# Load data
df = CSV.read("$(pathdata)/ue_flows.csv", DataFrame,ntasks=1)
df.date_monthly = MonthlyDate.(df.date)
subperiod_start_date = MonthlyDate.(["2016-01" "2021-04"])
subperiod_end_date = MonthlyDate.(["2019-12" "2023-05"])
inflation_period = MonthlyDate.(["2021-04", "2023-05"])
ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))
labels = string.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))


# Set E-U Rate to missing for the specified date range
transform!(df, [:date_monthly, Symbol("E-U Rate")] => ByRow((date, rate) -> MonthlyDate("2020-04") <= date <= MonthlyDate("2020-04") ? missing : rate) => :"E-U Rate")

avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x."E-U Rate") for i in 1:2]
p1 = plot(df.date_monthly, df."E-U Rate", label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_monthly, df."E-U Rate", label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
display(p1)
ylims!(p1, 0.0, 0.04)
savefig(p1, "$pathfigures/fig_eu_rate_fred.pdf")



# monthly(x) = Dates.format.(x, "u-yy")

# ############################################
# # Monthly figures
# ############################################

# # Load monthly data
# df = CSV.read("$(pathdata)/all_data_monthly.csv",DataFrame)
# transform!(df, :date_monthly => ByRow(x -> "01-" * x) => :date_monthly)
# df.date_monthly .= Dates.DateTime.(df.date_monthly, "dd-uuu-yy") .+ Dates.Year(2000)
# start_date = Date("2016-01-01")
# end_date = Date("2024-05-01")
# filter!(row -> start_date <= row.date_monthly <= end_date, df)
# subperiod_start_date = [Date("2016-01-01") Date("2021-04-01")]
# subperiod_end_date = [Date("2019-12-31") Date("2023-05-31")]
# inflation_period = [Date(2021,04,01), Date(2023,05,31)]

# # Set layoff_rate_jolts to missing for the specified date range
# transform!(df, [:date_monthly, :layoff_rate_jolts] => ByRow((date, rate) -> Date("2020-01-01") <= date <= Date("2020-03-30") ? missing : rate) => :layoff_rate_jolts)

# p1 = plot(df.inflation, df.quit_rate_jolts, label = "", color = 1, ylabel = "Monthly Quit Rate", xlabel = "Monthly Inflation Rate (Annualized)")
# scatter!(df.inflation, df.quit_rate_jolts, label = "", color = 1, markersize = 7)
# ylims!(p1, 0.0, 3.5)
# display(p1)
# savefig(p1, "$pathfigures/fig_scatter_inflation_quits.pdf")

# p1 = plot(df.inflation, df.vacancy_rate_jolts, label = "", color = 1, ylabel = "Monthly Vacancy Rate", xlabel = "Monthly Inflation Rate (Annualized)")
# scatter!(df.inflation, df.vacancy_rate_jolts, label = "", color = 1, markersize = 7)
# ylims!(p1, 0.0, 8.0)
# display(p1)
# savefig(p1, "$pathfigures/fig_scatter_inflation_vacancy.pdf")






# Figure B6: Corporate profits to GDP / short time series 

# Load quarterly data
df = CSV.read("$(pathdata)/profit_share.csv", DataFrame)

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
display(p1)
savefig(p1, "$(pathfigures)/fig_corp_profits_trend.pdf")





print(ki)


#######################################################
# Figure 3, Panel B 
#######################################################

# Load quarterly data
df = CSV.read("$(pathdata)/ue_flows_with_3ma.csv", DataFrame)

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
    
# Generate ticks and labels for the x-axis
#ticks = collect(minimum(df.date_quarterly):Year(1):maximum(df.date_quarterly))
#tick_values = Dates.value.(ticks)  # Convert Date to numeric values
#labels = string.(year.(ticks))  # Use year as labels

# Calculate average values for the subperiods
avg_value = [mean(df.job_finding_rate_3ma[subperiod_start_date[i] .<= df.date .<= subperiod_end_date[i]]) for i in 1:2]


p1 = plot(df.date, df.job_finding_rate_3ma, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date, df.job_finding_rate_3ma, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
ylims!(p1, 15, 40)
xticks!(tick_values, labels)
display(p1)

savefig(p1, "$pathfigures/fig_ue_rate_fred.pdf")


#######################################################
# Figure 3, Panel A 
#######################################################

# Load quarterly data
df = CSV.read("$(pathdata)/ee_monthly.csv", DataFrame)


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

# Generate ticks and labels for the x-axis
#ticks = collect(minimum(df.date_quarterly):Year(1):maximum(df.date_quarterly))
#tick_values = Dates.value.(ticks)  # Convert Date to numeric values
#labels = string.(year.(ticks))  # Use year as labels

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
display(p1)

savefig(p1, "$pathfigures/ee_monthly.pdf")

print(kk)



# Figure 5 

# Load quarterly data
df = CSV.read("$(pathdata)/adp_wage_v2.csv", DataFrame)

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
display(p1)
savefig(p1, "$pathfigures/fig_adp_wage_trends_v2.pdf")


# Panel B 
p1 = scatter(df.P_12m_change, df.diff, label = "", xlabel = "Monthly Inflation Rate", markersize = 7, smooth = true, color = 1)
ylabel!(L"\parbox{15em}{\centering Monthly Difference in Wage Growth,\\ Changers vs Stayers}", labelfontsize = 24)
xticks!(2:1:8)
yticks!(2:1:8)
display(p1)
savefig(p1, "$pathfigures/fig_adp_wage_trends_diff_v2.pdf")


#######################################################
# Figure 3, Panel A 
#######################################################

# Load quarterly data
df = CSV.read("$(pathdata)/ee_monthly.csv", DataFrame)


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

# Generate ticks and labels for the x-axis
#ticks = collect(minimum(df.date_quarterly):Year(1):maximum(df.date_quarterly))
#tick_values = Dates.value.(ticks)  # Convert Date to numeric values
#labels = string.(year.(ticks))  # Use year as labels

# Calculate average values for the subperiods
avg_value = [mean(df.ee_pol[subperiod_start_date[i] .<= df.date_monthly .<= subperiod_end_date[i]]) for i in 1:2]


p1 = plot(df.date_monthly, df.ee_pol, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_monthly, df.ee_pol, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
ylims!(p1, 1.5, 3)
xticks!(tick_values, labels)
display(p1)

savefig(p1, "$pathfigures/ee_monthly.pdf")

#######################################################
# Figure 3, Panel B 
#######################################################

# Load quarterly data
df = CSV.read("$(pathdata)/ue_flows_with_3ma.csv", DataFrame)

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
    
# Generate ticks and labels for the x-axis
#ticks = collect(minimum(df.date_quarterly):Year(1):maximum(df.date_quarterly))
#tick_values = Dates.value.(ticks)  # Convert Date to numeric values
#labels = string.(year.(ticks))  # Use year as labels

# Calculate average values for the subperiods
avg_value = [mean(df.job_finding_rate_3ma[subperiod_start_date[i] .<= df.date_quarterly .<= subperiod_end_date[i]]) for i in 1:2]


p1 = plot(df.date_quarterly, df.job_finding_rate_3ma, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_quarterly, df.job_finding_rate_3ma, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
ylims!(p1, 0, 50)
xticks!(tick_values, labels)
display(p1)

savefig(p1, "$pathfigures/fig_ue_rate_fred.pdf")



#############################################################
# Figure 2 
#############################################################

# Load monthly data
df = CSV.read("$(pathdata)/jolts_rates.csv",DataFrame,ntasks=1)
#transform!(df, :date=> ByRow(x -> "01-" * x) => :date_monthly)
#df.date .= Dates.DateTime.(df.date, "dd-uuu-yy") .+ Dates.Year(2000)
df.date .= MonthlyDate.(df.date)

start_date = MonthlyDate("2016-01")
end_date = MonthlyDate("2024-05")
filter!(row -> start_date <= row.date <= end_date, df)
subperiod_start_date = MonthlyDate.(["2016-01" "2021-04"])
subperiod_end_date = MonthlyDate.(["2019-12" "2023-05"])
inflation_period = MonthlyDate.(["2021-04", "2023-05"])
ticks = Dates.value.(collect(minimum(df.date):Month(12):maximum(df.date)))
labels = string.(collect(minimum(df.date):Month(12):maximum(df.date)))

# Figure 2, Panel A 

# Set layoff_rate_jolts to missing for the specified date range
transform!(df, [:date, :layoff_rate_jolts] => ByRow((date, rate) -> MonthlyDate("2020-01") <= date <= MonthlyDate("2020-03") ? missing : rate) => :layoff_rate_jolts)


avg_value = [filter(row -> subperiod_start_date[i] <= row.date <= subperiod_end_date[i], df) |> x -> mean(x.layoff_rate_jolts) for i in 1:2]
p1 = plot(df.date, df.layoff_rate_jolts, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date, df.layoff_rate_jolts, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
ylims!(p1, 0.0, 1.8)
display(p1)
savefig(p1, "$pathfigures/fig_layoff_rate_trend_v2.pdf")

# Figure 2, Panel B 

avg_value = [filter(row -> subperiod_start_date[i] <= row.date <= subperiod_end_date[i], df) |> x -> mean(x.quit_rate_jolts) for i in 1:2]
p1 = plot(df.date, df.quit_rate_jolts, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date, df.quit_rate_jolts, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
ylims!(p1, 0.0, 3.5)
display(p1)
savefig(p1, "$pathfigures/fig_quit_rate_trend_v2.pdf")

# Figure 2, Panel C 

avg_value = [filter(row -> subperiod_start_date[i] <= row.date <= subperiod_end_date[i], df) |> x -> mean(x.vacancy_rate_jolts) for i in 1:2]
p1 = plot(df.date, df.vacancy_rate_jolts, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date, df.vacancy_rate_jolts, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
ylims!(p1, 0.0, 8.0)
display(p1)
savefig(p1, "$pathfigures/fig_jobopen_rate_trend_v2.pdf")

######################################################################
# Figure 1, Panel A 
######################################################################

df = CSV.read("$(pathdata)/historical_data_feb.csv", DataFrame,ntasks=1)
df.date_monthly = MonthlyDate.(df.date)

filtered_df = filter(row -> MonthlyDate(2001,1) <= row.date_monthly, df)

ticks = Dates.value.(collect(df.date_monthly[2]:Month(24):MonthlyDate(2025,2)))
labels = [Dates.format(d, "yyyy-01") for d in collect(df.date_monthly[2]:Month(24):MonthlyDate(2025,2))]
#ticks = Dates.value.(collect(df.date_monthly[2]:Month(24):maximum(df.date_monthly)))
#labels = [Dates.format(d, "yyyy-01") for d in collect(df.date_monthly[2]:Month(24):maximum(df.date_monthly))]

p1 = plot(filtered_df.date_monthly, filtered_df.tightness, label = "", xrotation = 90)
ylims!(p1, 0.0, 2.25)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/market_tightness_jolts_feb.pdf")

###########################################################################
# Figure 20 
###########################################################################

df = CSV.read("$(pathdata)/historical_data.csv", DataFrame,ntasks=1)
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
display(p1)
savefig(p1, "$pathfigures/historical_vac_unemp_feb.pdf")

############################################
# Wage Trends from Atlanta Fed
############################################

# Load data
df = CSV.read("$(pathdata)/real_wage_figures_v2.csv", DataFrame,ntasks=1)
df.date_monthly = MonthlyDate.(df.date)

ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)+Month(12)))
labels = string.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)+Month(12)))

################################################################
# Figure 1 Panel B 
################################################################

p1 = plot(df.date_monthly, df.price_index, label = "", xrotation = 90, color = 2)
plot!(df.date_monthly, df.predicted_price_index, label = "", linestyle = :dash, color = 2)
plot!(df.date_monthly, df.med_real_wage_index, label = "", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_med_real_wage_index, label = "", linestyle = :dash, color = 1)
annotate!(p1, df.date_monthly[66], 1.26, text(L"\textbf{CPI}", :left, 24, palette(:tab10).colors[2]))
annotate!(p1, df.date_monthly[64], 1.03, text(L"\textbf{Atlanta Fed}", :center, 24, palette(:tab10).colors[1]))
annotate!(p1, df.date_monthly[64], 1.0, text(L"\textbf{Real Wage Index}", :center, 24, palette(:tab10).colors[1]))
#plot!([df.date_monthly[106], df.date_monthly[106]], [1.079, 1.12], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
#plot!([df.date_monthly[106], df.date_monthly[106]], [1.188, 1.314], line=arrow(:both, 8), linewidth = 1.0, color = 2, label = "")
plot!([df.date_monthly[end], df.date_monthly[end]], [min(df.price_index[end], df.predicted_price_index[end]), max(df.price_index[end], df.predicted_price_index[end])], line=arrow(:both, 8), linewidth = 1.0, color = 2, label = "")
plot!([df.date_monthly[end], df.date_monthly[end]], [min(df.med_real_wage_index[end], df.predicted_med_real_wage_index[end]), max(df.med_real_wage_index[end], df.predicted_med_real_wage_index[end])], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
annotate!(p1, df.date_monthly[98], 1.25, text(L"\mathbf{14%}", :center, 24, palette(:tab10).colors[2]))
annotate!(p1, df.date_monthly[98], 1.1, text(L"\textbf{-3.8\%}", :center, 24, palette(:tab10).colors[1]))
ylims!(p1, 0.95, 1.35)
xlims!(p1, ticks[1], ticks[end]+12)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_wage_price_evolution_feb.pdf")

###########################################################################
# Figure 4, Panel A 
###########################################################################

# Load data: 1st quartile
ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)+Month(12)))
labels = string.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)+Month(12)))
p1 = plot(df.date_monthly, df.real_wage_index_1, label = "Real Wage Index", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_real_wage_index_1, label = "Real Wage Index Pre-trend", linestyle = :dash, color = 1, linewidth = 1.0)
plot!([df.date_monthly[end], df.date_monthly[end]], [min(df.real_wage_index_1[end], df.predicted_real_wage_index_1[end]), max(df.real_wage_index_1[end], df.predicted_real_wage_index_1[end])], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
annotate!(p1, df.date_monthly[end]+Month(2), 1.128, text(L"\textbf{-2.4\%}", :center, 24, palette(:tab10).colors[1]))
#annotate!(p1, df.date_monthly[end], 1.118, text(L"\textbf{-2.4\%}", :right, 24, palette(:tab10).colors[1], offset=(10, 0)))
ylims!(p1, 0.96, 1.20)
xlims!(p1, ticks[1], ticks[end]+9)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_real_wage_evolution_q1_feb.pdf")

# Figure 4, Panel B 
# Load data: 2nd quartile
p1 = plot(df.date_monthly, df.real_wage_index_2, label = "", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_real_wage_index_2, label = "", linestyle = :dash, color = 1, linewidth = 1.0)
plot!([df.date_monthly[end], df.date_monthly[end]], [min(df.real_wage_index_2[end], df.predicted_real_wage_index_2[end]), max(df.real_wage_index_2[end], df.predicted_real_wage_index_2[end])], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
annotate!(p1, df.date_monthly[end]+Month(2), 1.13, text(L"\textbf{-1.5\%}", :center, 24, palette(:tab10).colors[1]))
ylims!(p1, 0.96, 1.20)
xlims!(p1, ticks[1], ticks[end]+9)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_real_wage_evolution_q2_feb.pdf")

# Figure 4, Panel C 
# Load data: 3rd quartile
p1 = plot(df.date_monthly, df.real_wage_index_3, label = "", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_real_wage_index_3, label = "", linestyle = :dash, color = 1, linewidth = 1.0)
plot!([df.date_monthly[end], df.date_monthly[end]], [min(df.real_wage_index_3[end], df.predicted_real_wage_index_3[end]), max(df.real_wage_index_3[end], df.predicted_real_wage_index_3[end])], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
annotate!(p1, df.date_monthly[end]+Month(2), 1.13, text(L"\textbf{-4.1\%}", :center, 24, palette(:tab10).colors[1]))
ylims!(p1, 0.96, 1.20)
xlims!(p1, ticks[1], ticks[end]+9)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_real_wage_evolution_q3_feb.pdf")

# Figure 4, Panel D 
# Load data: 4th quartile
p1 = plot(df.date_monthly, df.real_wage_index_4, label = "", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_real_wage_index_4, label = "", linestyle = :dash, color = 1, linewidth = 1.0)
plot!([df.date_monthly[end], df.date_monthly[end]], [min(df.real_wage_index_4[end], df.predicted_real_wage_index_4[end]), max(df.real_wage_index_4[end], df.predicted_real_wage_index_4[end])], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
annotate!(p1, df.date_monthly[end]+Month(2), 1.124, text(L"\textbf{-6.1\%}", :center, 24, palette(:tab10).colors[1]))
ylims!(p1, 0.96, 1.20) 
xlims!(p1, ticks[1], ticks[end]+9)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_real_wage_evolution_q4_feb.pdf")







