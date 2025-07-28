

library(ipumsr)
library(tidyverse)
library(ggplot2)
library(writexl) 
library(haven)


proj_dir <- "C:/Users/singhy/Desktop/Chicago/cps_data/inflation"
data_cps <- read_dta(file.path(proj_dir, "/temp/cps_basic_monthly_education.dta"))



get_J2J <- function(data, year, month) {
  if (month == 1) {
    # Special case for January (look at December of the previous year)
    employed_consec <- data %>%
      filter((YEAR == year-1 & MONTH == 12) | (YEAR == year & MONTH == month)) %>%
      group_by(CPSIDP) %>%
      filter(n() == 2 & EMPSTAT %in% c(10, 12)) %>%
      summarize(WTFINL = last(WTFINL))  # Use the weight from the current month
  } else {
    # Regular case
    employed_consec <- data %>%
      filter(YEAR == year & MONTH %in% c(month-1, month)) %>%
      group_by(CPSIDP) %>%
      filter(n() == 2 & EMPSTAT %in% c(10, 12)) %>%
      summarize(WTFINL = last(WTFINL))  # Use the weight from the current month
  }
  
  # Get CPSIDP and weights of individuals who changed jobs in the specified month
  changed_jobs <- data %>%
    filter(YEAR == year & MONTH == month & EMPSAME == 1 & CPSIDP %in% employed_consec$CPSIDP) %>%
    select(CPSIDP, WTFINL)
  
  # Calculate weighted job transition rate
  total_weight <- sum(employed_consec$WTFINL)
  changed_jobs_weight <- sum(changed_jobs$WTFINL)
  
  job_transition_rate <- changed_jobs_weight / total_weight
  
  return(job_transition_rate)
}


# Education group 
get_worker_educ <- function(data_cps, educ_rank){
  filtered_data <- data_cps %>% 
    filter(educ == educ_rank)
}

# Education groups 
org_educ_1 <- get_worker_educ(data_cps, 1)
org_educ_2 <- get_worker_educ(data_cps, 2)


transition_rates <- data.frame()

years <- min(data_cps$YEAR):max(data_cps$YEAR)
months <- 1:12

# Loop over the years
for (year in years) {
  # Loop over the months
  for (month in months) {
    
    #######################################
    # ee rates 
    #######################################
    # educ 
    ee_educ_1 <- get_J2J(org_educ_1, year, month)
    ee_educ_2 <- get_J2J(org_educ_2, year, month)
  
    
    # Append the rates to the data frame
    transition_rates <- rbind(transition_rates, data.frame(
      Year = year, 
      Month = month,
      ee_educ_1 = ee_educ_1,
      ee_educ_2 = ee_educ_2 
      
    ))
  }
}

transition_rates$Date <- as.Date(paste(transition_rates$Year, transition_rates$Month, "01", sep = "-"))

write_dta(transition_rates, file.path(proj_dir, "/temp/ee_rates_by_education.dta"))
