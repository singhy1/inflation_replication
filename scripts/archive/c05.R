# Yash Singh 
# 4/30/24 
# this script generates wage distribution 

library(Hmisc)
library(ipumsr)
library(tidyverse)
library(ggplot2)
library(writexl) 
library(readxl)
library(stats)

# Load the foreign package
library(foreign)


year_ranges <- c("90_99", "00_09", "10_19", "20_24")  # Adjust based on your available files

file_paths <- paste0("C:/Users/singhy/Dropbox (BFI)/Labor_Market_PT/temp/cps_data/cps_all_workers_", year_ranges, ".csv")


#pooled_cps <- read_csv("C:/Users/singhy/Dropbox (BFI)/Labor_Market_PT/temp/cps_data/cps_all_workers_82_89.csv")
pooled_cps <- lapply(file_paths, read_csv) %>% bind_rows()




# cpi

filepath <- "C:/Users/singhy/BFI Dropbox/Yash  Singh/Labor_Market_PT/temp/cpi_clean.xlsx"
cpi <- read_excel(filepath)


### Step 1: Get all hourly wage workers 

# Hourly wage workers 
wage_distribution <- pooled_cps %>%
  filter(MISH == 8, (EMPSTAT == 10 | EMPSTAT == 12), PAIDHOUR == 2)

# Missing Values 
wage_distribution$HOURWAGE2[wage_distribution$HOURWAGE2 == 999.99] <- NA

# time series 
wage_distribution$date_monthly <- as.Date(paste(wage_distribution$YEAR, wage_distribution$MONTH, "01", sep="-"), "%Y-%m-%d")

### Step 2: Get all salary workers 

earn_distribution <- pooled_cps %>%
  filter(MISH == 8, (EMPSTAT == 10 | EMPSTAT == 12), PAIDHOUR == 1)

earn_distribution$EARNWEEK2[earn_distribution$EARNWEEK2 == 9999.99] <- NA


earn_distribution$date_monthly <- as.Date(paste(earn_distribution$YEAR, earn_distribution$MONTH, "01", sep="-"), "%Y-%m-%d")

earn_distribution <- earn_distribution %>% 
  mutate(HOURWAGE2 = EARNWEEK2/40)

###########################################################

# pool the samples together 
pooled <- bind_rows(wage_distribution, earn_distribution)




# trim top/bottom 3% of observations 

pooled <- pooled %>%
  group_by(date_monthly) %>%
  mutate(
    lower_bound = quantile(HOURWAGE2, 0.01, na.rm = TRUE),
    upper_bound = quantile(HOURWAGE2, 0.99, na.rm = TRUE)
  ) %>%
  filter(HOURWAGE2 > lower_bound & HOURWAGE2 < upper_bound) 


##########################################################
##########################################################


pooled <- full_join(pooled, cpi, by='date_monthly')

pooled <- pooled %>% 
  mutate(real_wage = HOURWAGE2/cpi)

avg_price_index_Q1_2019 <- cpi %>% 
  filter(date_monthly >= '2019-01-01', date_monthly <='2019-03-01') %>% 
  summarise(price_index_q1_2019 = mean(cpi))


price_index_q1_2019 <- avg_price_index_Q1_2019$price_index_q1_2019


pooled <- pooled %>% 
  mutate(real_wage = real_wage * price_index_q1_2019)

pooled <- pooled %>%
  filter(!is.na(YEAR) & !is.na(MONTH))


file_path <- "C:/Users/singhy/Desktop/Chicago/cps_data/endogenous_technical_change/temp/cps_basic_monthly.dta"

# Write the data to a .dta file
write.dta(pooled, file = file_path)



# fixing demograhics 

### Weights ####

# 3 age groups 
pooled$age_bin <- cut(pooled$AGE, breaks = c(24, 34, 44, 55), right = TRUE, labels = c("25-34", "35-44", "45-55"))


# 2 education groups/ 2 race groups/ 2 native groups 

pooled <- pooled %>%
  mutate(Education_Level = ifelse(EDUC >= 111, "College+",
                                  ifelse(EDUC < 111, "Less than College", NA)),
         white = ifelse(RACE == 100, "white", 
                        ifelse(RACE != 100, "other", NA)), 
         foreign = ifelse(NATIVITY == 5, "Foreign", 
                          ifelse(NATIVITY != 5, "native", NA)))

pooled <- pooled %>%
  mutate(Education_Level = ifelse(EDUC >= 111, "College+",
                                  ifelse(EDUC < 111, "Less than College", NA)),
         white = ifelse(RACE == 100, "white", 
                        ifelse(RACE != 100, "other", NA)))




pooled$q1_2019 <- with(pooled, as.integer(date_monthly >= as.Date("2019-01-01") & 
                                            date_monthly <= as.Date("2019-03-31")))


logit_model <- glm(q1_2019 ~ age_bin + Education_Level + white, 
                   family = binomial(link = "logit"), 
                   data = pooled, na.action = na.exclude)


pooled$propensity_score <- predict(logit_model, type = "response")


pooled$weight <- ifelse(pooled$q1_2019 == 1,
                        1 / pooled$propensity_score,
                        1 / (1 - pooled$propensity_score))


pooled$temp_wgt <- pooled$weight / mean(pooled$weight)
pooled$final_wgt <- pooled$temp_wgt * pooled$EARNWT

#pooled <- pooled %>% 
#  filter((YEAR != 2024) & (MONTH != 3))

wage_distribution_time <- pooled %>%
  group_by(YEAR, MONTH) %>%
  summarise(
    P90 = wtd.quantile(real_wage, weights = final_wgt, probs = 0.90, na.rm = TRUE),
    P80 = wtd.quantile(real_wage, weights = final_wgt, probs = 0.80, na.rm = TRUE),
    P70 = wtd.quantile(real_wage, weights = final_wgt, probs = 0.70, na.rm = TRUE), 
    P60 = wtd.quantile(real_wage, weights = final_wgt, probs = 0.60, na.rm = TRUE),
    P50 = wtd.quantile(real_wage, weights = final_wgt, probs = 0.50, na.rm = TRUE), 
    P40 = wtd.quantile(real_wage, weights = final_wgt, probs = 0.40, na.rm = TRUE), 
    P30 = wtd.quantile(real_wage, weights = final_wgt, probs = 0.30, na.rm = TRUE), 
    P20 = wtd.quantile(real_wage, weights = final_wgt, probs = 0.20, na.rm = TRUE),
    P10 = wtd.quantile(real_wage, weights = final_wgt, probs = 0.10, na.rm = TRUE),
    var_wgt = wtd.var(log(real_wage), weights = final_wgt, na.rm=TRUE), 
    sd_wgt = sqrt(var_wgt),
    N = sum(!is.na(real_wage)),  
    N_wgt = sum(WTFINL, na.rm = TRUE)  
  )

write.csv(wage_distribution_time, 
          "C:/Users/singhy/Dropbox (BFI)/Labor_Market_PT/output/cps/wage_dist.csv", row.names = FALSE)


# Classify each worker into q decile 

weighted_quartile <- function(wage, weight) {
  quartiles <- wtd.quantile(wage, weight, probs = c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1))
  findInterval(wage, c(-Inf, quartiles), rightmost.closed = TRUE)
}

workers_wage_position <- pooled %>%
  group_by(YEAR, MONTH) %>%
  mutate(real_wage_q = weighted_quartile(real_wage, final_wgt)) %>%
  ungroup()

workers_wage_position <- workers_wage_position %>% 
  select(CPSIDP, real_wage_q)


file_path <- "C:/Users/singhy/Dropbox (BFI)/Labor_Market_PT/temp/cps_data/all_workers_by_wage_decile.csv"
write.csv(workers_wage_position, file = file_path, row.names = FALSE)
