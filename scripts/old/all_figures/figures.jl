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
const user = "AndresD" # "AndresB" or "AndresD"
if (user == "AndresB")
    pathfolder = "$(homedir())/Dropbox (ATL FRB)/papers_new/Labor_Market_PT"
elseif (user == "AndresD")
    pathfolder = "$(homedir())/Dropbox/Research/Labor_Market_PT"
elseif (user == "AndresDserver")
    pathfolder = "/data0/Dropbox/Research/Labor_Market_PT/"
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

############################################
# Monthly figures
############################################

# Load monthly data
df = CSV.read("$(pathdata)/all_data_monthly.csv",DataFrame,ntasks=1)
transform!(df, :date_monthly => ByRow(x -> "01-" * x) => :date_monthly)
df.date_monthly .= Dates.DateTime.(df.date_monthly, "dd-uuu-yy") .+ Dates.Year(2000)
df.date_monthly .= MonthlyDate.(df.date_monthly)

start_date = MonthlyDate("2016-01")
end_date = MonthlyDate("2024-05")
filter!(row -> start_date <= row.date_monthly <= end_date, df)
subperiod_start_date = MonthlyDate.(["2016-01" "2021-04"])
subperiod_end_date = MonthlyDate.(["2019-12" "2023-05"])
inflation_period = MonthlyDate.(["2021-04", "2023-05"])
ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))
labels = string.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))

# Set layoff_rate_jolts to missing for the specified date range
transform!(df, [:date_monthly, :layoff_rate_jolts] => ByRow((date, rate) -> MonthlyDate("2020-01") <= date <= MonthlyDate("2020-03") ? missing : rate) => :layoff_rate_jolts)

# Plots
avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.ee_rate_cps) for i in 1:2]
p1 = plot(df.date_monthly, df.ee_rate_cps, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_monthly, df.ee_rate_cps, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/ee_monthly.pdf")

avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.layoff_rate_jolts) for i in 1:2]
p1 = plot(df.date_monthly, df.layoff_rate_jolts, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_monthly, df.layoff_rate_jolts, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
ylims!(p1, 0.0, 1.8)
display(p1)
savefig(p1, "$pathfigures/fig_layoff_rate_trend.pdf")

avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.quit_rate_jolts) for i in 1:2]
p1 = plot(df.date_monthly, df.quit_rate_jolts, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_monthly, df.quit_rate_jolts, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
ylims!(p1, 0.0, 3.5)
display(p1)
savefig(p1, "$pathfigures/fig_quit_rate_trend.pdf")

avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.vacancy_rate_jolts) for i in 1:2]
p1 = plot(df.date_monthly, df.vacancy_rate_jolts, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_monthly, df.vacancy_rate_jolts, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
ylims!(p1, 0.0, 8.0)
display(p1)
savefig(p1, "$pathfigures/fig_jobopen_rate_trend.pdf")

avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.zero_share) for i in 1:2]
p1 = plot(df.date_monthly, df.zero_share, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_monthly, df.zero_share, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.nom_wage_grth_atlfed.-x.inflation) for i in 1:2]
plot!(df.date_monthly, df.nom_wage_grth_atlfed.-df.inflation, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
annotate!(p1, df.date_monthly[4], 4.0, text("Annualized Real Wage Growth", :left, 18, "black"))
annotate!(p1, df.date_monthly[4], 12.0, text("Fraction w/Zero Nominal Wage Change", :left, 18, "black"))
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_wage_growth_atlanta_fed.pdf")

p1 = plot(df.inflation, df.quit_rate_jolts, label = "", color = 1, ylabel = "Monthly Quit Rate", xlabel = "Monthly Inflation Rate (Annualized)")
scatter!(df.inflation, df.quit_rate_jolts, label = "", color = 1, markersize = 7)
ylims!(p1, 0.0, 3.5)
display(p1)
savefig(p1, "$pathfigures/fig_scatter_inflation_quits.pdf")

p1 = plot(df.inflation, df.vacancy_rate_jolts, label = "", color = 1, ylabel = "Monthly Vacancy Rate", xlabel = "Monthly Inflation Rate (Annualized)")
scatter!(df.inflation, df.vacancy_rate_jolts, label = "", color = 1, markersize = 7)
ylims!(p1, 0.0, 8.0)
display(p1)
savefig(p1, "$pathfigures/fig_scatter_inflation_vacancy.pdf")

avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.p50_grth) for i in 1:2]
p1 = plot(df.date_monthly, df.p50_grth, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_monthly, df.p50_grth, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/median_earnings_growth_smoothed.pdf")

filtered_df = filter(row -> Date("2020-10-01") <= row.date_monthly <= Date("2024-05-31"), df)
p1 = plot(filtered_df.date_monthly, filtered_df.nom_wgt_changer, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(filtered_df.date_monthly, filtered_df.nom_wgt_changer, label = "", xrotation = 90, color = 1)
plot!(filtered_df.date_monthly, filtered_df.nom_wgt_stayer, label = "", xrotation = 90, color = 2, linestyle = :dash)
annotate!(p1, filtered_df.date_monthly[18], 6.5, text("Job Stayers", :left, 24, "black"))
annotate!(p1, filtered_df.date_monthly[17], 14., text("Job Changers", :left, 24, "black"))
ylims!(p1, 0.0, 18.0)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_adp_wage_trends.pdf")

# p1 = plot(filtered_df.date_monthly, filtered_df.nom_changer_stay_wgt_diff, label = "", xrotation = 90, alpha = 0.0)
# vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
# plot!(filtered_df.date_monthly, filtered_df.nom_changer_stay_wgt_diff, label = "", xrotation = 90, color = 1)
# ylims!(p1, 0.0, 18.0)
# xticks!(ticks, labels)
# display(p1)
# savefig(p1, "$pathfigures/fig_adp_wage_trends_diff.pdf")

df = DataFrame(load("$(pathdata)/ADP_PAY_history.xls", "Sheet1"))
df.date_monthly = MonthlyDate.(df.Date)
p1 = scatter(df.Inflation, df.Difference, label = "", xlabel = "Monthly Inflation Rate", markersize = 7, smooth = true, color = 1)
ylabel!(L"\parbox{15em}{\centering Monthly Difference in Wage Growth,\\ Changers vs Stayers}", labelfontsize = 24)
display(p1)
savefig(p1, "$pathfigures/fig_adp_wage_trends_diff.pdf")

############################################
# Monthly flows from FRED
############################################

# Load data
df = CSV.read("$(pathdata)/ue_flows.csv", DataFrame,ntasks=1)
df.date_monthly = MonthlyDate.(df.date)
subperiod_start_date = MonthlyDate.(["2016-01" "2021-04"])
subperiod_end_date = MonthlyDate.(["2019-12" "2023-05"])
inflation_period = MonthlyDate.(["2021-04", "2023-05"])
ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))
labels = string.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))

filter!(row -> subperiod_start_date[1] <= row.date_monthly <= df.date_monthly[end], df)
avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.job_finding_rate ) for i in 1:2]
p1 = plot(df.date_monthly, df.job_finding_rate, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_monthly, df.job_finding_rate, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
xticks!(ticks, labels)
display(p1)
ylims!(p1, 0.0, 0.5)
savefig(p1, "$pathfigures/fig_ue_rate_fred.pdf")

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

############################################
# Market tightness from JOLTS
############################################

# Load data
df = DataFrame(load("$(pathdata)/market_tightness_jolts.xls", "FRED Graph!A11:E296"))
df.date_monthly = MonthlyDate.(df.observation_date)
ticks = Dates.value.(collect(df.date_monthly[2]:Month(24):maximum(df.date_monthly)))
labels = string.(collect(df.date_monthly[2]:Month(24):maximum(df.date_monthly)))

p1 = plot(df.date_monthly, df."Vacancy-to-Unemp", label = "", xrotation = 90)
ylims!(p1, 0.0, 2.25)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/market_tightness_jolts.pdf")

############################################
# Wage Trends from Atlanta Fed
############################################

# Load data
df = CSV.read("$(pathdata)/real_wage_figures.csv", DataFrame,ntasks=1)
df.date_monthly = MonthlyDate.(df.date)

ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))
labels = string.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))

p1 = plot(df.date_monthly, df.cpi, label = "", xrotation = 90, color = 2)
plot!(df.date_monthly, df.predicted_cpi, label = "", linestyle = :dash, color = 2)
plot!(df.date_monthly, df.med_real_wage_index, label = "", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_med_real_wage_index, label = "", linestyle = :dash, color = 1)
annotate!(p1, df.date_monthly[66], 1.26, text(L"\textbf{CPI}", :left, 24, palette(:tab10).colors[2]))
annotate!(p1, df.date_monthly[64], 1.03, text(L"\textbf{Atlanta Fed}", :center, 24, palette(:tab10).colors[1]))
annotate!(p1, df.date_monthly[64], 1.0, text(L"\textbf{Real Wage Index}", :center, 24, palette(:tab10).colors[1]))
plot!([df.date_monthly[102], df.date_monthly[102]], [1.079, 1.12], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
plot!([df.date_monthly[102], df.date_monthly[102]], [1.188, 1.314], line=arrow(:both, 8), linewidth = 1.0, color = 2, label = "")
annotate!(p1, df.date_monthly[94], 1.25, text(L"\mathbf{13\%}", :center, 24, palette(:tab10).colors[2]))
annotate!(p1, df.date_monthly[94], 1.09, text(L"\textbf{-4.4\%}", :center, 24, palette(:tab10).colors[1]))
ylims!(p1, 0.95, 1.35)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_wage_price_evolution.pdf")

# Load data: 1st quartile
ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)+Month(12)))
labels = string.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)+Month(12)))
p1 = plot(df.date_monthly, df.real_wage_index_1, label = "Real Wage Index", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_real_wage_index_1, label = "Real Wage Index Pre-trend", linestyle = :dash, color = 1, linewidth = 1.0)
plot!([df.date_monthly[102], df.date_monthly[102]], [1.154, 1.178], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
annotate!(p1, df.date_monthly[end]+Month(8), 1.168, text(L"\textbf{-2.6\%}", :center, 24, palette(:tab10).colors[1]))
ylims!(p1, 0.96, 1.20)
xlims!(p1, ticks[1], ticks[end]+9)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_real_wage_evolution_q1.pdf")

# Load data: 2nd quartile
p1 = plot(df.date_monthly, df.real_wage_index_2, label = "", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_real_wage_index_2, label = "", linestyle = :dash, color = 1, linewidth = 1.0)
plot!([df.date_monthly[102], df.date_monthly[102]], [1.084, 1.104], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
annotate!(p1, df.date_monthly[end]+Month(9), 1.095, text(L"\textbf{-2.1\%}", :center, 24, palette(:tab10).colors[1]))
ylims!(p1, 0.96, 1.20)
xlims!(p1, ticks[1], ticks[end]+9)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_real_wage_evolution_q2.pdf")

# Load data: 3rd quartile
p1 = plot(df.date_monthly, df.real_wage_index_3, label = "", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_real_wage_index_3, label = "", linestyle = :dash, color = 1, linewidth = 1.0)
plot!([df.date_monthly[102], df.date_monthly[102]], [1.06, 1.105], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
annotate!(p1, df.date_monthly[end]+Month(9), 1.084, text(L"\textbf{-4.7\%}", :center, 24, palette(:tab10).colors[1]))
ylims!(p1, 0.96, 1.20)
xlims!(p1, ticks[1], ticks[end]+9)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_real_wage_evolution_q3.pdf")

# Load data: 4th quartile
p1 = plot(df.date_monthly, df.real_wage_index_4, label = "", xrotation = 90, color = 1)
plot!(df.date_monthly, df.predicted_real_wage_index_4, label = "", linestyle = :dash, color = 1, linewidth = 1.0)
plot!([df.date_monthly[102], df.date_monthly[102]], [1.031, 1.097], line=arrow(:both, 8), linewidth = 1.0, color = 1, label = "")
annotate!(p1, df.date_monthly[end]+Month(9), 1.064, text(L"\textbf{-6.7\%}", :center, 24, palette(:tab10).colors[1]))
ylims!(p1, 0.96, 1.20)
xlims!(p1, ticks[1], ticks[end]+9)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_real_wage_evolution_q4.pdf")

############################################
# Quarterly corporate profits
############################################

# Load quarterly data
df = CSV.read("$(pathdata)/all_data_quarterly.csv",DataFrame,ntasks=1)
df.date_quarterly .= QuarterlyDate.(replace.(df.date_quarterly, "q" => "-Q"))

start_date = QuarterlyDate.("2016-Q1")
end_date = QuarterlyDate.("2024-Q2")
filter!(row -> start_date <= row.date_quarterly <= end_date, df)
subperiod_start_date = QuarterlyDate.(["2016-Q1"  "2021-Q2"])
subperiod_end_date = QuarterlyDate.(["2019-Q4"  "2023-Q2"])
inflation_period = QuarterlyDate.(["2021-Q2", "2023-Q2"])
ticks = Dates.value.(collect(minimum(df.date_quarterly):Quarter(4):maximum(df.date_quarterly)))
labels = string.(collect(minimum(df.date_quarterly):Quarter(4):maximum(df.date_quarterly)))

df.profit_share = df.profit_share ./ 100.0
avg_value = [filter(row -> subperiod_start_date[i] <= row.date_quarterly <= subperiod_end_date[i], df) |> x -> mean(x.profit_share) for i in 1:2]
p1 = plot(df.date_quarterly, df.profit_share, label = "", xrotation = 90, alpha = 0.0)
vspan!(inflation_period, label = "", alpha = 0.3, color = :grey)
plot!(df.date_quarterly, df.profit_share, label = "", xrotation = 90, color = 1)
plot!([subperiod_start_date[1], subperiod_end_date[1]], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
plot!([subperiod_start_date[2], subperiod_end_date[2]], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
ylims!(p1, 0.0, 0.14)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/fig_corp_profits_trend.pdf")

############################################
# Figures by Decile
############################################

# Load data
df = CSV.read("$(pathdata)/post_rwgt.csv",DataFrame)

df_post = filter(row -> row.period == "Post-period", df)
p1 = plot(df_post.percentile, df_post.cum_grth, label = "Raw Growth", color = 1, ylabel = "% Cumulative Change", xlabel = "Earnings Decile", legend = :topright, xticks = 1:1:10)
scatter!(df_post.percentile, df_post.cum_grth, label = "", color = 1, markersize = 7)
plot!(df_post.percentile, df_post.grth_rel_trend, label = "Relative to Trend", color = 2, ylabel = "% Cumulative Change", xlabel = "Earnings Decile")
scatter!(df_post.percentile, df_post.grth_rel_trend, label = "", color = 2, markersize = 7)
hline!(p1, [0], color = :black, linestyle = :dash, label = "")
ylims!(p1, -10.0, 6.0)
display(p1)
savefig(p1, "$pathfigures/wage_growth_plot.pdf")

df_pre = filter(row -> row.period == "Pre-period", df)
p1 = plot(df_pre.percentile, df_pre.annual_grth, label = "", color = 1, ylabel = "% Annual Real Wage Growth", xlabel = "Earnings Decile", legend = :topright, xticks = 1:1:10)
scatter!(df_pre.percentile, df_pre.annual_grth, label = "", color = 1, markersize = 7)
hline!(p1, [0], color = :black, linestyle = :dash, label = "")
ylims!(p1, -1.1, 3.0)
display(p1)
savefig(p1, "$pathfigures/wage_growth_plot_16_19.pdf")

############################################
# Historical data
############################################

df = DataFrame(load("$(pathdata)/historical_data.xls", "historical_data"))
df.date_monthly = MonthlyDate.(df.year, df.month)

filtered_df = filter(row -> MonthlyDate(1951,1) <= row.date_monthly, df)
ticks = Dates.value.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))
labels = string.(collect(minimum(df.date_monthly):Month(12):maximum(df.date_monthly)))
labels = [label[1:4] for label in labels]

p1 = plot(filtered_df.date_monthly, filtered_df."Updated V-U", label = "", xrotation = 90)
hline!(p1, [mean(filtered_df."Updated V-U")], linestyle = :dash, label = "", color = 1)
scatter!([filtered_df.date_monthly[221], filtered_df.date_monthly[455], filtered_df.date_monthly[590], filtered_df.date_monthly[825]], [1.52, 0.85, 1.05, 1.27], label = "", markershape = :utriangle, markersize = 25, markeralpha = 0.0, markerstrokealpha = 1.0, markerstrokecolor = 3, markerstrokewidth = 3)
scatter!([filtered_df.date_monthly[30], filtered_df.date_monthly[270], filtered_df.date_monthly[340], filtered_df.date_monthly[860]], [1.7, 1.05, 0.95, 2.02], label = "", markershape = :circle, markersize = 20, markeralpha = 0.0, markerstrokealpha = 1.0, markerstrokecolor = 2, markerstrokewidth = 3)
ylims!(p1, 0.0, 2.2)
xticks!([ticks[2:5:end]; ticks[end]], [labels[2:5:end]; labels[end]])
display(p1)
savefig(p1, "$pathfigures/historical_vac_unemp.pdf")


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

# # Plots
# avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.layoff_rate_jolts) for i in 1:2]
# p1 = plot(monthly.(df.date_monthly), df.layoff_rate_jolts, label = "", xrotation = 90, alpha = 0.0)
# vspan!(monthly.(inflation_period), label = "", alpha = 0.3, color = :grey)
# plot!(monthly.(df.date_monthly), df.layoff_rate_jolts, label = "", xrotation = 90, color = 1)
# plot!([monthly(subperiod_start_date[1]), monthly(subperiod_end_date[1])], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
# plot!([monthly(subperiod_start_date[2]), monthly(subperiod_end_date[2])], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
# display(p1)
# savefig(p1, "$pathfigures/fig_layoff_rate_trend.pdf")

# avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.quit_rate_jolts) for i in 1:2]
# p1 = plot(monthly.(df.date_monthly), df.quit_rate_jolts, label = "", xrotation = 90, alpha = 0.0)
# vspan!(monthly.(inflation_period), label = "", alpha = 0.3, color = :grey)
# plot!(monthly.(df.date_monthly), df.quit_rate_jolts, label = "", xrotation = 90, color = 1)
# plot!([monthly(subperiod_start_date[1]), monthly(subperiod_end_date[1])], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
# plot!([monthly(subperiod_start_date[2]), monthly(subperiod_end_date[2])], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
# display(p1)
# savefig(p1, "$pathfigures/fig_quit_rate_trend.pdf")

# avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.vacancy_rate_jolts) for i in 1:2]
# p1 = plot(monthly.(df.date_monthly), df.vacancy_rate_jolts, label = "", xrotation = 90, alpha = 0.0)
# vspan!(monthly.(inflation_period), label = "", alpha = 0.3, color = :grey)
# plot!(monthly.(df.date_monthly), df.vacancy_rate_jolts, label = "", xrotation = 90, color = 1)
# plot!([monthly(subperiod_start_date[1]), monthly(subperiod_end_date[1])], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
# plot!([monthly(subperiod_start_date[2]), monthly(subperiod_end_date[2])], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
# display(p1)
# savefig(p1, "$pathfigures/fig_jobopen_rate_trend.pdf")

# avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.zero_share) for i in 1:2]
# p1 = plot(monthly.(df.date_monthly), df.zero_share, label = "", xrotation = 90, alpha = 0.0)
# vspan!(monthly.(inflation_period), label = "", alpha = 0.3, color = :grey)
# plot!(monthly.(df.date_monthly), df.zero_share, label = "", xrotation = 90, color = 1)
# plot!([monthly(subperiod_start_date[1]), monthly(subperiod_end_date[1])], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
# plot!([monthly(subperiod_start_date[2]), monthly(subperiod_end_date[2])], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
# avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.nom_wage_grth_atlfed.-x.inflation) for i in 1:2]
# plot!(monthly.(df.date_monthly), df.nom_wage_grth_atlfed.-df.inflation, label = "", xrotation = 90, color = 1)
# plot!([monthly(subperiod_start_date[1]), monthly(subperiod_end_date[1])], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
# plot!([monthly(subperiod_start_date[2]), monthly(subperiod_end_date[2])], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
# annotate!(p1, monthly.(df.date_monthly)[4], 4.0, text("Annualized Real Wage Growth", :left, 18, "black"))
# annotate!(p1, monthly.(df.date_monthly)[4], 12.0, text("Fraction w/Zero Nominal Wage Change", :left, 18, "black"))
# display(p1)
# savefig(p1, "$pathfigures/fig_wage_growth_atlanta_fed.pdf")

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

# avg_value = [filter(row -> subperiod_start_date[i] <= row.date_monthly <= subperiod_end_date[i], df) |> x -> mean(x.p50_grth) for i in 1:2]
# p1 = plot(monthly.(df.date_monthly), df.p50_grth, label = "", xrotation = 90, alpha = 0.0)
# vspan!(monthly.(inflation_period), label = "", alpha = 0.3, color = :grey)
# plot!(monthly.(df.date_monthly), df.p50_grth, label = "", xrotation = 90, color = 1)
# plot!([monthly(subperiod_start_date[1]), monthly(subperiod_end_date[1])], [avg_value[1], avg_value[1]], color = 2, linestyle = :dash, label = "")
# plot!([monthly(subperiod_start_date[2]), monthly(subperiod_end_date[2])], [avg_value[2], avg_value[2]], color = 2, linestyle = :dash, label = "")
# display(p1)
# savefig(p1, "$pathfigures/median_earnings_growth_smoothed.pdf")

# filtered_df = filter(row -> Date("2020-10-01") <= row.date_monthly <= Date("2024-05-31"), df)
# p1 = plot(monthly.(filtered_df.date_monthly), filtered_df.nom_wgt_changer, label = "", xrotation = 90, alpha = 0.0)
# vspan!(monthly.(inflation_period), label = "", alpha = 0.3, color = :grey)
# plot!(monthly.(filtered_df.date_monthly), filtered_df.nom_wgt_changer, label = "", xrotation = 90, color = 1)
# plot!(monthly.(filtered_df.date_monthly), filtered_df.nom_wgt_stayer, label = "", xrotation = 90, color = 2, linestyle = :dash)
# annotate!(p1, monthly.(filtered_df.date_monthly)[18], 6.5, text("Job Stayers", :left, 18, "black"))
# annotate!(p1, monthly.(filtered_df.date_monthly)[18], 15.0, text("Job Changers", :left, 18, "black"))
# ylims!(p1, 0.0, 18.0)
# display(p1)
# savefig(p1, "$pathfigures/fig_adp_wage_trends.pdf")

# p1 = plot(monthly.(filtered_df.date_monthly), filtered_df.nom_changer_stay_wgt_diff, label = "", xrotation = 90, alpha = 0.0)
# vspan!(monthly.(inflation_period), label = "", alpha = 0.3, color = :grey)
# plot!(monthly.(filtered_df.date_monthly), filtered_df.nom_changer_stay_wgt_diff, label = "", xrotation = 90, color = 1)
# ylims!(p1, 0.0, 18.0)
# display(p1)
# savefig(p1, "$pathfigures/fig_adp_wage_trends_diff.pdf")
