library(tidyverse)
library(googlesheets4)
library(readxl)
library(lubridate)


source("Make_Pop_Data.R")
source("Make_Landlaeknir_Data.R")

world_pop <- make_pop_data() %>% 
    mutate(country = str_to_lower(country))

base_url <- "https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-"

cur_date <- Sys.Date()

full_url <- str_c(base_url, cur_date, ".xlsx")
temp <- tempfile()

if (RCurl::url.exists(full_url)) {
    download.file(full_url, temp)
    
} else {
    cur_date <- cur_date - 1
    full_url <- str_c(base_url, cur_date, ".xlsx")
    download.file(full_url, temp)
}


d <- read_xlsx(temp) %>% 
    select(country = "countriesAndTerritories", 
           date = dateRep, 
           new_cases = cases, 
           new_deaths = deaths) %>% 
    mutate(date = as_date(date),
           country = str_replace_all(country, "_", " ")) %>% 
    arrange(country, date) %>% 
    group_by(country) %>% 
    mutate(total_cases = cumsum(new_cases), total_deaths = cumsum(new_deaths)) %>% 
    ungroup %>% 
    filter(country != "Iceland") %>% 
    bind_rows(Make_Landlaeknir_Data()) %>% 
    mutate(country = fct_recode(country,
                                "United States" = "United States of America",
                                "Tanzania" = "United Republic of Tanzania",
                                "Congo" = "Democratic Republic of the Congo") %>% 
               str_to_lower) %>% 
    inner_join(world_pop) %>% 
    mutate(country = str_to_title(country)) %>% 
    select(continent, region, country, pop, date, everything()) %>% 
    mutate(case_rate = total_cases / pop * 1000,
           death_rate = ifelse(total_cases == 0, 0, total_deaths / total_cases))


d %>% 
    write_csv("Input/Test/ECDC_Data.csv")
d %>% 
    write_csv("Input/ECDC_Data.csv")
