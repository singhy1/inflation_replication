# Yash Singh 
# 1) this script generates maps each cpsidp to its respective wage decile 
# 2) this script generates the time series of weekly earnings distribution = annual labor income/weeks worked from ASEC 

library(Hmisc)
library(ipumsr)
library(tidyverse)
library(ggplot2)
library(writexl) 
library(readxl)
library(stats)


# load data 
filepath <- "C:/Users/singhy/Dropbox (BFI)/Labor_Market_PT/temp/cpi_clean.xlsx"
cpi <- read_excel(filepath)

filepath <- "C:/Users/singhy/Dropbox (BFI)/Labor_Market_PT/temp/cps_data/asec_90_20.csv"
data_cps <- read_csv(filepath)

# create a date_monthly variable 
data_cps$date_monthly <- as.Date(paste(data_cps$YEAR, data_cps$MONTH, "01", sep="-"), "%Y-%m-%d")

# 2019 dollars 
avg_price_index_Q1_2019 <- cpi %>% 
  filter(date_monthly >= '2019-01-01', date_monthly <='2019-03-01') %>% 
  summarise(price_index_q1_2019 = mean(cpi))

price_index_q1_2019 <- avg_price_index_Q1_2019$price_index_q1_2019

# merge the data set 
data_cps <- merge(data_cps, cpi, by='date_monthly')

# real weekly earnings in 2019 dollars 
data_cps <- data_cps %>% 
  mutate(real_wkly_earn = (weekly_earnings/cpi)*price_index_q1_2019)


# 
# 
# 
# # Education Groups 
# data_cps <- data_cps%>%
#   mutate(educ_label = case_when(
#     EDUC < 73 ~ 1,                             # less than hs 
#     EDUC == 73  ~ 2,                           # hs 
#     EDUC %in% c(80, 81, 100)  ~ 3 ,            # some college 
#     EDUC %in% c(90,91,92) ~ 4,                 # associates degree 
#     EDUC %in% c(110, 111, 120, 121, 122) ~ 5,       # BA 
#     EDUC >= 123  ~ 6,                          # BA+ 
#     TRUE ~ NA_real_  
#   ))
# 
# # Age groups 
# data_cps <- data_cps %>%
#   mutate(age_label = case_when(
#     AGE >= 25 & AGE < 30 ~ 1,
#     AGE >= 30 & AGE < 35 ~ 2,
#     AGE >= 35 & AGE < 40 ~ 3,
#     AGE >= 40 & AGE < 45 ~ 4,
#     AGE >= 45 & AGE < 50 ~ 5,
#     AGE >= 50 & AGE <= 55 ~ 6,
#     TRUE ~ NA_real_
#   ))
# 
# 
# data_cps <- data_cps %>%
#   mutate(YEAR = as.factor(YEAR))
# 
# model <- lm(real_wkly_earn ~ educ_label + age_label + SEX + YEAR, data = data_cps)
# 
# 
# data_cps$predicted_real_wkly_earn <- predict(model, newdata = data_cps)

# trimming top/bottom 3% 
#data_cps <- data_cps %>%
#  group_by(YEAR) %>%
#  mutate(
#    lower_bound = quantile(real_wkly_earn, 0.03, na.rm = TRUE),
#    upper_bound = quantile(real_wkly_earn, 0.97, na.rm = TRUE)
#  ) %>%
#  filter(real_wkly_earn > lower_bound & real_wkly_earn< upper_bound) 













# fixing demograhics 

### Weights ####
# 
# # 3 age groups 
# data_cps$age_bin <- cut(data_cps$AGE, breaks = c(24, 34, 44, 55), right = TRUE, labels = c("25-34", "35-44", "45-55"))
# 
# 
# data_cps <- data_cps %>%
#   mutate(Education_Level = ifelse(EDUC >= 111, "College+",
#                                   ifelse(EDUC < 111, "Less than College", NA)),
#          white = ifelse(RACE == 100, "white", 
#                         ifelse(RACE != 100, "other", NA)))
# 
# 
# 
# 
# data_cps$q1_2019 <- with(data_cps, as.integer(date_monthly >= as.Date("2019-01-01") & 
#                                             date_monthly <= as.Date("2019-03-31")))
# 
# 
# logit_model <- glm(q1_2019 ~ age_bin + Education_Level + white, 
#                    family = binomial(link = "logit"), 
#                    data = data_cps, na.action = na.exclude)
# 
# 
# data_cps$propensity_score <- predict(logit_model, type = "response")
# 
# 
# data_cps$weight <- ifelse(data_cps$q1_2019 == 1,
#                         1 / data_cps$propensity_score,
#                         1 / (1 - data_cps$propensity_score))


#data_cps$temp_wgt <- data_cps$weight / mean(data_cps$weight)
#data_cps$final_wgt <- data_cps$temp_wgt * data_cps$ASECWT

data_cps$final_wgt <- data_cps$ASECWT

# Classify each worker into q decile 

weighted_quartile <- function(earn, weight) {
  quartiles <- wtd.quantile(earn, weight, probs = c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9))
  findInterval(earn, c(-Inf, quartiles), rightmost.closed = TRUE)
}

workers_earn_position_cx <- data_cps %>%
  group_by(YEAR, MONTH) %>%
  #mutate(real_earn_q = weighted_quartile(predicted_real_wkly_earn, final_wgt)) %>%
  mutate(real_earn_q = weighted_quartile(real_wkly_earn, final_wgt)) %>% 
  ungroup()

workers_earn_position <- workers_earn_position_cx %>% 
  select(CPSIDP, real_earn_q) %>% 
  distinct()
  

file_path <- "C:/Users/singhy/Dropbox (BFI)/Labor_Market_PT/temp/cps_data/asec_workers_by_earn_decile.csv"
write.csv(workers_earn_position, file = file_path, row.names = FALSE)

# 
# earn_distribution_time <- data_cps %>%
#   group_by(YEAR, MONTH) %>%
#   summarise(
#     P10 = wtd.quantile(predicted_real_wkly_earn, weights = final_wgt, probs = .95, na.rm = TRUE),
#     P09 = wtd.quantile(predicted_real_wkly_earn, weights = final_wgt, probs = 0.90, na.rm = TRUE),
#     P08 = wtd.quantile(predicted_real_wkly_earn, weights = final_wgt, probs = 0.80, na.rm = TRUE),
#     P07 = wtd.quantile(predicted_real_wkly_earn, weights = final_wgt, probs = 0.70, na.rm = TRUE), 
#     P06 = wtd.quantile(predicted_real_wkly_earn, weights = final_wgt, probs = 0.60, na.rm = TRUE),
#     P05 = wtd.quantile(predicted_real_wkly_earn, weights = final_wgt, probs = 0.50, na.rm = TRUE), 
#     P04 = wtd.quantile(predicted_real_wkly_earn, weights = final_wgt, probs = 0.40, na.rm = TRUE), 
#     P03 = wtd.quantile(predicted_real_wkly_earn, weights = final_wgt, probs = 0.30, na.rm = TRUE), 
#     P02 = wtd.quantile(predicted_real_wkly_earn, weights = final_wgt, probs = 0.20, na.rm = TRUE),
#     P01 = wtd.quantile(predicted_real_wkly_earn, weights = final_wgt, probs = 0.10, na.rm = TRUE),
#     var_wgt = wtd.var(log(predicted_real_wkly_earn), weights = final_wgt, na.rm=TRUE), 
#     sd_wgt = sqrt(var_wgt), 
#     N = sum(!is.na(predicted_real_wkly_earn)),  
#     N_wgt = sum(ASECWT, na.rm = TRUE)  
#   )


earn_distribution_time <- data_cps %>%
  group_by(YEAR, MONTH) %>%
  summarise(
    P90 = wtd.quantile(real_wkly_earn, weights = final_wgt, probs = 0.90, na.rm = TRUE),
    P80 = wtd.quantile(real_wkly_earn, weights = final_wgt, probs = 0.80, na.rm = TRUE),
    P70 = wtd.quantile(real_wkly_earn, weights = final_wgt, probs = 0.70, na.rm = TRUE), 
    P60 = wtd.quantile(real_wkly_earn, weights = final_wgt, probs = 0.60, na.rm = TRUE),
    P50 = wtd.quantile(real_wkly_earn, weights = final_wgt, probs = 0.50, na.rm = TRUE), 
    P40 = wtd.quantile(real_wkly_earn, weights = final_wgt, probs = 0.40, na.rm = TRUE), 
    P30 = wtd.quantile(real_wkly_earn, weights = final_wgt, probs = 0.30, na.rm = TRUE), 
    P20 = wtd.quantile(real_wkly_earn, weights = final_wgt, probs = 0.20, na.rm = TRUE),
    P10 = wtd.quantile(real_wkly_earn, weights = final_wgt, probs = 0.10, na.rm = TRUE),
    var_wgt = wtd.var(log(real_wkly_earn), weights = final_wgt, na.rm=TRUE), 
    sd_wgt = sqrt(var_wgt), 
    N = sum(!is.na(real_wkly_earn)),  
    N_wgt = sum(ASECWT, na.rm = TRUE)  
  )


file_path <- "C:/Users/singhy/Dropbox (BFI)/Labor_Market_PT/output/cps/asec_earn_dist.csv"
write.csv(earn_distribution_time, file = file_path, row.names = FALSE)














