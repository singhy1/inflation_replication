# Yash Singh 
# 4/30/24 
# this script generates a file with all job flows by income deciles. 


library(ipumsr)
library(tidyverse)
library(ggplot2)
library(writexl) 
library(haven)


# key functions

# EE Rate 

get_J2J <- function(data, year, month) {
  if (month == 1) {
    # Special case for January (look at December of the previous year)
    cpsidp_employed_consec <- data %>%
      filter((YEAR == year-1 & MONTH == 12) | (YEAR == year & MONTH == month)) %>%
      group_by(CPSIDP) %>%
      filter(n() == 2 & EMPSTAT %in% c(10, 12)) %>%
      pull(CPSIDP) %>%
      unique()
  } else {
    # Regular case
    cpsidp_employed_consec <- data %>%
      filter(YEAR == year & MONTH %in% c(month-1, month)) %>%
      group_by(CPSIDP) %>%
      filter(n() == 2 & EMPSTAT %in% c(10, 12)) %>%
      pull(CPSIDP) %>%
      unique()
  }
  
  # Get CPSIDP of individuals who changed jobs in the specified month
  cpsidp_changed_jobs <- data %>%
    filter(YEAR == year & MONTH == month & EMPSAME == 1 & CPSIDP %in% cpsidp_employed_consec) %>%
    pull(CPSIDP) %>%
    unique()
  
  # Calculate weighted job transition rate
  job_transition_rate <- job_transition_rate <- length(cpsidp_changed_jobs) / length(cpsidp_employed_consec)
  
  
  return(job_transition_rate)
}



getEmployed <- function(data, year, month) {
  
  # Filter data based on year and month
  filtered_data <- data[data$YEAR == year & data$MONTH == month, ]
  
  # Find CPSIDP for EMPSTAT == 10 or 12
  relevant_ids <- filtered_data$CPSIDP[filtered_data$EMPSTAT %in% c(10, 12)]
  
  relevant_weights <- filtered_data$WTFINL[filtered_data$EMPSTAT %in% c(10, 12)]
  
  return(data.frame(CPSIDP = relevant_ids, WEIGHT = relevant_weights))
}

getQuits <- function(data, year, month) {
  # Filter data based on year and month
  filtered_data <- data[data$YEAR == year & data$MONTH == month, ]
  
  # Find CPSIDP for WHYUNEMP == 4
  relevant_ids <- filtered_data$CPSIDP[filtered_data$WHYUNEMP == 4]
  relevant_weights <- filtered_data$WTFINL[filtered_data$WHYUNEMP == 4]
  
  return(data.frame(CPSIDP = relevant_ids, WEIGHT = relevant_weights))
}


getLayoffs <- function(data, year, month) {
  # Filter data based on year and month
  filtered_data <- data[data$YEAR == year & data$MONTH == month, ]
  
  # Find CPSIDP for WHYUNEMP == 1, 2, or 3
  relevant_ids <- filtered_data$CPSIDP[filtered_data$WHYUNEMP %in% c(1)]
  relevant_weights <- filtered_data$WTFINL[filtered_data$WHYUNEMP %in% c(1)]
  
  return(data.frame(CPSIDP = relevant_ids, WEIGHT = relevant_weights))
}

getOther <- function(data, year, month) {
  
  filtered_data <- data[data$YEAR == year & data$MONTH == month, ]

  relevant_ids <- filtered_data$CPSIDP[filtered_data$WHYUNEMP %in% c(2)]
  relevant_weights <- filtered_data$WTFINL[filtered_data$WHYUNEMP %in% c(2)]
  
  return(data.frame(CPSIDP = relevant_ids, WEIGHT = relevant_weights))
}




get_E2U <- function(data, year, month) {
  
  # Define previous month and year based on the special case where month is 1 (January)
  previous_month <- ifelse(month == 1, 12, month - 1)
  previous_year <- ifelse(month == 1, year - 1, year)
  
  # Filter the data for relevant year and months
  data <- data %>%
    filter((YEAR == previous_year & MONTH == previous_month) | (YEAR == year & MONTH == month))
  
  # Find the CPSIDP for individuals with 2 observations
  cpsidp_2obs <- data %>%
    group_by(CPSIDP) %>%
    filter(n() == 2) %>%
    pull(CPSIDP) %>%
    unique()
  
  
  filtered_data <- data[data$CPSIDP %in% cpsidp_2obs, ]
  #print(filtered_data)
  
  E = getEmployed(filtered_data, previous_year, previous_month)
  Q_t = getQuits(filtered_data, year, month)
  L_t = getLayoffs(filtered_data, year, month)
  O_t = getOther(filtered_data, year, month)
  
  quits <- sum(Q_t$WEIGHT)
  layoffs <- sum(L_t$WEIGHT)
  other <- sum(O_t$WEIGHT)
  employed <- sum(E$WEIGHT)
  
  qrate = quits/employed 
  lrate = layoffs/employed 
  orate = other/employed
  
  # Return the three statistics
  return(list(E2U_quits = qrate, E2U_layoffs = lrate, E2U_other = orate))
}



get_U2E <- function(data, year, month) {
  
  # Special case for January
  if (month == 1) {
    previous_year <- year - 1
    previous_month <- 12
  } else {
    previous_year <- year
    previous_month <- month - 1
  }
  
  # Subset data to relevant periods
  relevant_data <- data %>%
    filter((YEAR == previous_year & MONTH == previous_month) | (YEAR == year & MONTH == month))
  
  cpsidp_2obs <- relevant_data %>%
    group_by(CPSIDP) %>%
    filter(n() == 2) %>%
    pull(CPSIDP) %>%
    unique()
  
  relevant_data <- relevant_data[relevant_data$CPSIDP %in% cpsidp_2obs, ]
  
  # Get CPSIDP and summed weights of individuals who were unemployed in the previous month
  unemployed_prev_month <- relevant_data %>%
    filter(YEAR == previous_year & MONTH == previous_month & EMPSTAT %in% c(20, 21, 22)) %>%
    group_by(CPSIDP) %>%
    summarise(total_weight = sum(WTFINL)) %>%
    unique()
  
  # Get CPSIDP and summed weights of individuals who were unemployed in the previous month and are now employed
  found_job <- relevant_data %>%
    filter(YEAR == year & MONTH == month & EMPSTAT %in% c(10, 12) & CPSIDP %in% unemployed_prev_month$CPSIDP) %>%
    group_by(CPSIDP) %>%
    summarise(total_weight = sum(WTFINL)) %>%
    unique()
  
  # Calculate job finding rate
  U2E <- sum(found_job$total_weight) / sum(unemployed_prev_month$total_weight)
  
  return(U2E)
}


######################################################################################################################
######################################################################################################################
# Date 


data <- read_dta("C:/Users/singhy/Desktop/Chicago/cps_data/inflation/temp/cps_basic_monthly.dta")
earn_dist <- read_dta("C:/Users/singhy/Desktop/Chicago/cps_data/inflation/temp/asec_workers_by_earn_decile.dta")


data_cps <- merge(x=data, y = earn_dist, by = 'CPSIDP', all.x = TRUE)

data_cps <- data_cps %>% 
  filter(!is.na(real_earn_q))


get_worker_earn_q <- function(data_cps, quartile){
  filtered_data <- data_cps %>% 
    filter(real_earn_q == quartile)
}


wage_1 <- get_worker_earn_q(data_cps, 1)
wage_2 <- get_worker_earn_q(data_cps, 2)
wage_3 <- get_worker_earn_q(data_cps, 3)
wage_4 <- get_worker_earn_q(data_cps, 4)
wage_5 <- get_worker_earn_q(data_cps, 5)
wage_6 <- get_worker_earn_q(data_cps, 6)
wage_7 <- get_worker_earn_q(data_cps, 7)
wage_8 <- get_worker_earn_q(data_cps, 8)
wage_9 <- get_worker_earn_q(data_cps, 9)
wage_10 <- get_worker_earn_q(data_cps, 10)

# 
# unemp_wage_1 <- get_worker_earn_q(data_cps, 1)
# unemp_wage_2 <- get_worker_earn_q(data_cps, 2)
# unemp_wage_3 <- get_worker_earn_q(data_cps, 3)
# unemp_wage_4 <- get_worker_earn_q(data_cps, 4)
# unemp_wage_5 <- get_worker_earn_q(data_cps, 5)
# unemp_wage_6 <- get_worker_earn_q(data_cps, 6)
# unemp_wage_7 <- get_worker_earn_q(data_cps, 7)
# unemp_wage_8 <- get_worker_earn_q(data_cps, 8)
# unemp_wage_9 <- get_worker_earn_q(data_cps, 9)
# unemp_wage_10 <- get_worker_earn_q(data_cps, 10)




transition_rates <- data.frame()

years <- min(data_cps$YEAR):max(data_cps$YEAR)
months <- 1:12

# Loop over the years
for (year in years) {
  # Loop over the months
  for (month in months) {
    # ee rates 
    
    ee_all <- get_J2J(data_cps, year, month)
    
    ee_wage_1 <- get_J2J(wage_1, year, month)
    ee_wage_2 <- get_J2J(wage_2, year, month)
    ee_wage_3 <- get_J2J(wage_3, year, month)
    ee_wage_4 <- get_J2J(wage_4, year, month)
    ee_wage_5 <- get_J2J(wage_5, year, month)
    ee_wage_6 <- get_J2J(wage_6, year, month)
    ee_wage_7 <- get_J2J(wage_7, year, month)
    ee_wage_8 <- get_J2J(wage_8, year, month)
    ee_wage_9 <- get_J2J(wage_9, year, month)
    ee_wage_10 <- get_J2J(wage_10, year, month)
    
    # eu rates 
    eu_all <- get_E2U(data_cps, year, month)
    
    eu_wage_1 <- get_E2U(wage_1, year, month)
    eu_wage_2 <- get_E2U(wage_2, year, month)
    eu_wage_3 <- get_E2U(wage_3, year, month)
    eu_wage_4 <- get_E2U(wage_4, year, month)
    eu_wage_5 <- get_E2U(wage_5, year, month)
    eu_wage_6 <- get_E2U(wage_6, year, month)
    eu_wage_7 <- get_E2U(wage_7, year, month)
    eu_wage_8 <- get_E2U(wage_8, year, month)
    eu_wage_9 <- get_E2U(wage_9, year, month)
    eu_wage_10 <- get_E2U(wage_10, year, month)
    
    # eu_wage_1 <- get_E2U(unemp_wage_1, year, month)
    # eu_wage_2 <- get_E2U(unemp_wage_2, year, month)
    # eu_wage_3 <- get_E2U(unemp_wage_3, year, month)
    # eu_wage_4 <- get_E2U(unemp_wage_4, year, month)
    # eu_wage_5 <- get_E2U(unemp_wage_5, year, month)
    # eu_wage_6 <- get_E2U(unemp_wage_6, year, month)
    # eu_wage_7 <- get_E2U(unemp_wage_7, year, month)
    # eu_wage_8 <- get_E2U(unemp_wage_8, year, month)
    # eu_wage_9 <- get_E2U(unemp_wage_9, year, month)
    # eu_wage_10 <- get_E2U(unemp_wage_10, year, month)
    
  
    # ue rate 
    ue_all <- get_U2E(data_cps, year, month)
    
    ue_wage_1 <- get_U2E(wage_1, year, month)
    ue_wage_2 <- get_U2E(wage_2, year, month)
    ue_wage_3 <- get_U2E(wage_3, year, month)
    ue_wage_4 <- get_U2E(wage_4, year, month)
    ue_wage_5 <- get_U2E(wage_5, year, month)
    ue_wage_6 <- get_U2E(wage_6, year, month)
    ue_wage_7 <- get_U2E(wage_7, year, month)
    ue_wage_8 <- get_U2E(wage_8, year, month)
    ue_wage_9 <- get_U2E(wage_9, year, month)
    ue_wage_10 <- get_U2E(wage_10, year, month)
    
    
    # Append the rates to the data frame
    transition_rates <- rbind(transition_rates, data.frame(
      Year = year, 
      Month = month,
      
      # ee rates
      
      ee_pol = ee_all,        
      
      ee_wage_1= ee_wage_1, 
      ee_wage_2= ee_wage_2,
      ee_wage_3= ee_wage_3,
      ee_wage_4= ee_wage_4,
      ee_wage_5= ee_wage_5, 
      ee_wage_6= ee_wage_6,
      ee_wage_7= ee_wage_7,
      ee_wage_8= ee_wage_8,
      ee_wage_9 = ee_wage_9, 
      ee_wage_10 = ee_wage_10, 
      
      
      # eu rates - pooled
      eu_quits_all = eu_all$E2U_quits, 
      eu_layoff_all = eu_all$E2U_layoffs,
      eu_other_all = eu_all$E2U_other, 
      
      
      # Wage distribution 
      eu_quits_wage_1 = eu_wage_1$E2U_quits, 
      eu_layoffs_wage_1 = eu_wage_1$E2U_layoffs,
      eu_other_wage_1 = eu_wage_1$E2U_other, 
      
      eu_quits_wage_2 = eu_wage_2$E2U_quits, 
      eu_layoffs_wage_2 = eu_wage_2$E2U_layoffs,
      eu_other_wage_2 = eu_wage_2$E2U_other, 
      
      eu_quits_wage_3 = eu_wage_3$E2U_quits, 
      eu_layoffs_wage_3 = eu_wage_3$E2U_layoffs,
      eu_other_wage_3 = eu_wage_3$E2U_other, 
      
      eu_quits_wage_4 = eu_wage_4$E2U_quits, 
      eu_layoffs_wage_4 = eu_wage_4$E2U_layoffs,
      eu_other_wage_4 = eu_wage_4$E2U_other, 
      
      eu_quits_wage_5 = eu_wage_5$E2U_quits, 
      eu_layoffs_wage_5 = eu_wage_5$E2U_layoffs,
      eu_other_wage_5 = eu_wage_5$E2U_other, 
      
      eu_quits_wage_6 = eu_wage_6$E2U_quits, 
      eu_layoffs_wage_6 = eu_wage_6$E2U_layoffs,
      eu_other_wage_6 = eu_wage_6$E2U_other, 
      
      eu_quits_wage_7 = eu_wage_7$E2U_quits, 
      eu_layoffs_wage_7 = eu_wage_7$E2U_layoffs,
      eu_other_wage_7 = eu_wage_7$E2U_other,
      
      eu_quits_wage_8 = eu_wage_8$E2U_quits, 
      eu_layoffs_wage_8 = eu_wage_8$E2U_layoffs,
      eu_other_wage_8 = eu_wage_8$E2U_other,
      
      eu_quits_wage_9 = eu_wage_9$E2U_quits, 
      eu_layoffs_wage_9 = eu_wage_9$E2U_layoffs,
      eu_other_wage_9 = eu_wage_9$E2U_other,
      
      eu_quits_wage_10 = eu_wage_10$E2U_quits, 
      eu_layoffs_wage_10 = eu_wage_10$E2U_layoffs,
      eu_other_wage_10 = eu_wage_10$E2U_other, 
      
      
      # ue rates
      ue_pol = ue_all, 
      ue_wage_1 = ue_wage_1, 
      ue_wage_2 = ue_wage_2, 
      ue_wage_3 = ue_wage_3, 
      ue_wage_4 = ue_wage_4, 
      ue_wage_5 = ue_wage_5, 
      ue_wage_6 = ue_wage_6, 
      ue_wage_7 = ue_wage_7, 
      ue_wage_8 = ue_wage_8,
      ue_wage_9 = ue_wage_9,
      ue_wage_10 = ue_wage_10
    ))
  }
}

transition_rates$Date <- as.Date(paste(transition_rates$Year, transition_rates$Month, "01", sep = "-"))

write.csv(transition_rates, 
          "C:\Users\singhy\Desktop\Chicago\cps_data\inflation\output\job_flow.csv", row.names = FALSE)

