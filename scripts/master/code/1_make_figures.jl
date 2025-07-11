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

const USERNAME = get(ENV, "USERNAME", get(ENV, "USER", "unknown"))

if (user == "giyoung")
    pathfolder = "/Users/giyoung/Downloads/inflation_replication/scripts/master"
end

const pathfigures = "$pathfolder/output/figures"
const pathdata = "$pathfolder/data/processed"

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

df = CSV.read("$(pathdata)/figure_1_1_A.csv", DataFrame,ntasks=1)
df.date_monthly = MonthlyDate.(df.date)

filtered_df = filter(row -> MonthlyDate(2001,1) <= row.date_monthly, df)

ticks = Dates.value.(collect(df.date_monthly[2]:Month(24):MonthlyDate(2025,2)))
labels = [Dates.format(d, "yyyy-01") for d in collect(df.date_monthly[2]:Month(24):MonthlyDate(2025,2))]
p1 = plot(filtered_df.date_monthly, filtered_df.tightness, label = "", xrotation = 90)
ylims!(p1, 0.0, 2.25)
xticks!(ticks, labels)
display(p1)
savefig(p1, "$pathfigures/figure_1_1_A.pdf")


######################################################################
# Figure 1.1, Panel B
######################################################################

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
display(p1)
savefig(p1, "$pathfigures/figure_1_1_B.pdf")
