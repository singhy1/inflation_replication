# Yash Singh 
# 4/30/24 
# this script generates a file with all job flows by income deciles. 

options(repos = c(CRAN = "https://cloud.r-project.org"))
required_packages <- c("ipumsr", "tidyverse", "ggplot2", "writexl", "haven")

installed <- rownames(installed.packages())

for (pkg in required_packages) {
  if (!(pkg %in% installed)) {
    suppressMessages(
      suppressWarnings(
        install.packages(pkg, quietly = TRUE)
      )
    )
  }
  suppressMessages(library(pkg, character.only = TRUE))
}

proj_dir <- "/Users/giyoung/Desktop/inflation_replication/scripts/replication_final/data/moments"
data_cps <- read_dta(file.path(proj_dir, "/temp/cps_basic_monthly_matched.dta"))

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
  
  relevant_ids <- filtered_data$CPSIDP[filtered_data$WHYUNEMP %in% c(2,3)]
  relevant_weights <- filtered_data$WTFINL[filtered_data$WHYUNEMP %in% c(2,3)]
  
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

# ASEC
get_worker_earn_d <- function(data_cps, decile){
  filtered_data <- data_cps %>% 
    filter(real_earn_d == decile)
}


# Education group 
get_worker_educ <- function(data_cps, educ_rank){
  filtered_data <- data_cps %>% 
    filter(educ == educ_rank)
}

# Education groups 
org_educ_1 <- get_worker_educ(data_cps, 1)
org_educ_2 <- get_worker_educ(data_cps, 2)


# ASEC 
asec_wage_1 <- get_worker_earn_d(data_cps, 1)
asec_wage_2 <- get_worker_earn_d(data_cps, 2)
asec_wage_3 <- get_worker_earn_d(data_cps, 3)
asec_wage_4 <- get_worker_earn_d(data_cps, 4)
asec_wage_5 <- get_worker_earn_d(data_cps, 5)
asec_wage_6 <- get_worker_earn_d(data_cps, 6)
asec_wage_7 <- get_worker_earn_d(data_cps, 7)
asec_wage_8 <- get_worker_earn_d(data_cps, 8)
asec_wage_9 <- get_worker_earn_d(data_cps, 9)
asec_wage_10 <- get_worker_earn_d(data_cps, 10)


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
    
    ee_all <- get_J2J(data_cps, year, month)
    
    # ASEC 
    ee_asec_wage_1 <- get_J2J(asec_wage_1, year, month)
    ee_asec_wage_2 <- get_J2J(asec_wage_2, year, month)
    ee_asec_wage_3 <- get_J2J(asec_wage_3, year, month)
    ee_asec_wage_4 <- get_J2J(asec_wage_4, year, month)
    ee_asec_wage_5 <- get_J2J(asec_wage_5, year, month)
    ee_asec_wage_6 <- get_J2J(asec_wage_6, year, month)
    ee_asec_wage_7 <- get_J2J(asec_wage_7, year, month)
    ee_asec_wage_8 <- get_J2J(asec_wage_8, year, month)
    ee_asec_wage_9 <- get_J2J(asec_wage_9, year, month)
    ee_asec_wage_10 <- get_J2J(asec_wage_10, year, month)
    
    # educ 
    ee_educ_1 <- get_J2J(org_educ_1, year, month)
    ee_educ_2 <- get_J2J(org_educ_2, year, month)
    
    ##############################################
    # eu rates 
    ##############################################
    
    eu_all <- get_E2U(data_cps, year, month)
    
    # ASEC
    eu_asec_wage_1 <- get_E2U(asec_wage_1, year, month)
    eu_asec_wage_2 <- get_E2U(asec_wage_2, year, month)
    eu_asec_wage_3 <- get_E2U(asec_wage_3, year, month)
    eu_asec_wage_4 <- get_E2U(asec_wage_4, year, month)
    eu_asec_wage_5 <- get_E2U(asec_wage_5, year, month)
    eu_asec_wage_6 <- get_E2U(asec_wage_6, year, month)
    eu_asec_wage_7 <- get_E2U(asec_wage_7, year, month)
    eu_asec_wage_8 <- get_E2U(asec_wage_8, year, month)
    eu_asec_wage_9 <- get_E2U(asec_wage_9, year, month)
    eu_asec_wage_10 <- get_E2U(asec_wage_10, year, month)
    
    
    # education
    eu_educ_1 <- get_E2U(org_educ_1, year, month)
    eu_educ_2 <- get_E2U(org_educ_2, year, month)
    
    # ue rate 
    ue_all <- get_U2E(data_cps, year, month)
    
    # ASEC 
    ue_asec_wage_1 <- get_U2E(asec_wage_1, year, month)
    ue_asec_wage_2 <- get_U2E(asec_wage_2, year, month)
    ue_asec_wage_3 <- get_U2E(asec_wage_3, year, month)
    ue_asec_wage_4 <- get_U2E(asec_wage_4, year, month)
    ue_asec_wage_5 <- get_U2E(asec_wage_5, year, month)
    ue_asec_wage_6 <- get_U2E(asec_wage_6, year, month)
    ue_asec_wage_7 <- get_U2E(asec_wage_7, year, month)
    ue_asec_wage_8 <- get_U2E(asec_wage_8, year, month)
    ue_asec_wage_9 <- get_U2E(asec_wage_9, year, month)
    ue_asec_wage_10 <- get_U2E(asec_wage_10, year, month)
    
    # education
    ue_educ_1 <- get_U2E(org_educ_1, year, month)
    ue_educ_2 <- get_U2E(org_educ_2, year, month)
    
    # Append the rates to the data frame
    transition_rates <- rbind(transition_rates, data.frame(
      Year = year, 
      Month = month,
      
      # ee rates
      
      ee_pol = ee_all,        
      
      # ASEC
      ee_asec_wage_1= ee_asec_wage_1, 
      ee_asec_wage_2= ee_asec_wage_2,
      ee_asec_wage_3= ee_asec_wage_3,
      ee_asec_wage_4= ee_asec_wage_4,
      ee_asec_wage_5= ee_asec_wage_5, 
      ee_asec_wage_6= ee_asec_wage_6,
      ee_asec_wage_7= ee_asec_wage_7,
      ee_asec_wage_8= ee_asec_wage_8,
      ee_asec_wage_9 = ee_asec_wage_9, 
      ee_asec_wage_10 = ee_asec_wage_10, 
      
      
      
      # educ 
      ee_educ_1 = ee_educ_1,
      ee_educ_2 = ee_educ_2, 
      
      # eu rates - pooled
      eu_quits_all = eu_all$E2U_quits, 
      eu_layoff_all = eu_all$E2U_layoffs,
      eu_other_all = eu_all$E2U_other, 
      
      
      # ASEC  
      eu_quits_asec_wage_1 = eu_asec_wage_1$E2U_quits, 
      eu_layoffs_asec_wage_1 = eu_asec_wage_1$E2U_layoffs,
      eu_other_asec_wage_1 = eu_asec_wage_1$E2U_other, 
      
      eu_quits_asec_wage_2 = eu_asec_wage_2$E2U_quits, 
      eu_layoffs_asec_wage_2 = eu_asec_wage_2$E2U_layoffs,
      eu_other_asec_wage_2 = eu_asec_wage_2$E2U_other, 
      
      eu_quits_asec_wage_3 = eu_asec_wage_3$E2U_quits, 
      eu_layoffs_asec_wage_3 = eu_asec_wage_3$E2U_layoffs,
      eu_other_asec_wage_3 = eu_asec_wage_3$E2U_other, 
      
      eu_quits_asec_wage_4 = eu_asec_wage_4$E2U_quits, 
      eu_layoffs_asec_wage_4 = eu_asec_wage_4$E2U_layoffs,
      eu_other_asec_wage_4 = eu_asec_wage_4$E2U_other, 
      
      eu_quits_asec_wage_5 = eu_asec_wage_5$E2U_quits, 
      eu_layoffs_asec_wage_5 = eu_asec_wage_5$E2U_layoffs,
      eu_other_asec_wage_5 = eu_asec_wage_5$E2U_other, 
      
      eu_quits_asec_wage_6 = eu_asec_wage_6$E2U_quits, 
      eu_layoffs_asec_wage_6 = eu_asec_wage_6$E2U_layoffs,
      eu_other_asec_wage_6 = eu_asec_wage_6$E2U_other, 
      
      eu_quits_asec_wage_7 = eu_asec_wage_7$E2U_quits, 
      eu_layoffs_asec_wage_7 = eu_asec_wage_7$E2U_layoffs,
      eu_other_asec_wage_7 = eu_asec_wage_7$E2U_other,
      
      eu_quits_asec_wage_8 = eu_asec_wage_8$E2U_quits, 
      eu_layoffs_asec_wage_8 = eu_asec_wage_8$E2U_layoffs,
      eu_other_asec_wage_8 = eu_asec_wage_8$E2U_other,
      
      eu_quits_asec_wage_9 = eu_asec_wage_9$E2U_quits, 
      eu_layoffs_asec_wage_9 = eu_asec_wage_9$E2U_layoffs,
      eu_other_asec_wage_9 = eu_asec_wage_9$E2U_other,
      
      eu_quits_asec_wage_10 = eu_asec_wage_10$E2U_quits, 
      eu_layoffs_asec_wage_10 = eu_asec_wage_10$E2U_layoffs,
      eu_other_asec_wage_10 = eu_asec_wage_10$E2U_other, 
      
      
      # Education 
      eu_quits_educ_1 = eu_educ_1$E2U_quits,
      eu_layoffs_educ_1 = eu_educ_1$E2U_layoffs, 
      eu_other_educ_1 = eu_educ_1$E2U_other, 
      
      eu_quits_educ_2 = eu_educ_2$E2U_quits,
      eu_layoffs_educ_2 = eu_educ_2$E2U_layoffs, 
      eu_other_educ_2 = eu_educ_2$E2U_other,
      
      
      ##########################################
      # ue rates
      ##########################################
      
      ue_pol = ue_all, 
      
      # ASEC 
      ue_asec_wage_1 = ue_asec_wage_1, 
      ue_asec_wage_2 = ue_asec_wage_2, 
      ue_asec_wage_3 = ue_asec_wage_3, 
      ue_asec_wage_4 = ue_asec_wage_4, 
      ue_asec_wage_5 = ue_asec_wage_5, 
      ue_asec_wage_6 = ue_asec_wage_6, 
      ue_asec_wage_7 = ue_asec_wage_7, 
      ue_asec_wage_8 = ue_asec_wage_8,
      ue_asec_wage_9 = ue_asec_wage_9,
      ue_asec_wage_10 = ue_asec_wage_10, 
      
      
      #educ 
      ue_educ_1 = ue_educ_1, 
      ue_educ_2 = ue_educ_2
      
    ))
  }
}



transition_rates$Date <- as.Date(paste(transition_rates$Year, transition_rates$Month, "01", sep = "-"))

write_dta(transition_rates, file.path(proj_dir, "/temp/gross_flows_v1.dta"))

