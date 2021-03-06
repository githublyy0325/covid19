library(readr)
library(dplyr)
library(rstan)
library(magrittr)

options(mc.cores = parallel::detectCores())
source("Make_Stan_Data.R")

d <- Make_Stan_Data()


N_obs <- nrow(d)
N_countries <- max(d$country_id)


days <- d$days
new_cases <- d$new_cases
total_cases <- d$total_cases
d %>% group_by(country, country_id) %>% 
    summarise(total_cases = max(total_cases)) %>% 
    arrange(country_id) %>% 
    .$total_cases
country <- d$country_id %>% as.integer

pop <- d %>% distinct(country_id, pop) %>% arrange(country_id) %>%  .$pop

stan_data <- list(N_obs = N_obs,
                  N_countries = N_countries,
                  days = days, 
                  new_cases = new_cases, 
                  total_cases = total_cases, 
                  country = country,
                  pop = pop)

m <- sampling(stan_model("Stan/Logistic/Hierarchical_Logistic_Cases.stan"), 
              data  = stan_data, chains = 4, iter = 3000, warmup = 1000)

write_rds(m, "Stan/Logistic/Hierarchical_Model.rds")
write_rds(m, str_c("Stan/Logistic/Saved_Models/Hierarchical_Model", Sys.Date(), ".rds"))
write_rds(m, "Stan/Logistic/Interactive Model Checking/Hierarchical_Model.rds")
write_csv(d, "Stan/Logistic/Interactive Model Checking/stan_data.csv")
write_csv(d, str_c("Input/Stan_Data/Stan_Data_", Sys.Date(), ".csv"))

d %>% 
    group_by(country) %>% 
    summarise(First = min(date),
              Days_In_Data = n(),
              Start_Rate = min(case_rate),
              End_Rate = max(case_rate)) %>% 
    write_csv(str_c("Output/Stan_Data_Info/Stan_Data_Info_", Sys.Date(), ".csv"))
