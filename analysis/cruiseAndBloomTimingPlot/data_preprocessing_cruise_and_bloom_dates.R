# Stephanie.Clay@dfo-mpo.gc.ca
# 2024-01-04

# Add AR7W line sampling dates to Cruise_dates.csv.

library(dplyr)
library(lubridate)
library(oceancolouR)

biochem_file <- "Data/Raw/2023/azomp2023_nutrients_chla_temp_extracted20240219.csv"
phytofit_file <- "Data/Raw/2023/verified_fits_labrador_sea_spring_log.csv"
output_file <- "Data/Cruise_and_bloom_dates.csv"

regions <- c("CLS","GS","LAS")

# get biochem data with cruise timing
bdf <- read.csv(biochem_file) %>%
    dplyr::rename(Region=region) %>%
    dplyr::filter(Region %in% c("LAS","CLS","GS")) %>%
    # dplyr::filter(grepl("AR7W|L3",station)) %>%
    dplyr::mutate(date=as_date(paste0(pad0(year,4),pad0(month,2),pad0(day,2)),format="%Y%m%d")) %>%
    dplyr::group_by(mission_name, year) %>%
    dplyr::summarize(AR7W_start_doy=yday(min(date)),
                     AR7W_end_doy=yday(max(date))) %>%
    dplyr::ungroup() %>%
    dplyr::filter(AR7W_start_doy < 250) # filter out random fall cruises

# get phytofit data with bloom timing
pdf <- read.csv(phytofit_file) %>%
    dplyr::filter(Region %in% regions) %>% 
    dplyr::rename(year=Year,
                  bloom_start_doy="t.start.",
                  bloom_end_doy="t.end.") %>%
    dplyr::distinct(Region, year, bloom_start_doy, bloom_end_doy)

full_df <- expand.grid(Region=regions,year=min(c(bdf$year,pdf$year)):max(c(bdf$year,pdf$year)))

# join them together
output <- dplyr::left_join(full_df, bdf, by="year") %>%
    dplyr::left_join(y=pdf, by=c("Region","year")) %>%
    dplyr::arrange(year)

write.csv(output, file=output_file, row.names=FALSE, na="")

