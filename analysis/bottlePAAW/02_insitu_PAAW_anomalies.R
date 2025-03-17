# Stephanie.Clay@dfo-mpo.gc.ca
# 2025-02-26

# Calculate water column average PAAW, then annual average (per AZOMP polygon).

rm(list=ls())
library(dplyr)
library(tidyr)
library(lubridate)

# years to process
years <- 1997:2024

# range of years to use for reference when computing climatology mean, standard deviation, and anomalies
ref_years <- 1999:2020


#*******************************************************************************

# required columns: region,mission_name,station,event_id,sample_id,year,month,day,date,season,time,longitude,latitude,depth,parameter_name,method,data_value
# note that values are grouped by event id to integrate or average results, assuming one event corresponds to multiple samples at different depths in the water column
input_file <- list.files("analysis/bottlePAAW/data", full.names=TRUE, pattern="PAAW_AZOMP")

# output filename/location
output_file <- file.path(dirname(input_file),"AZOMPPAAW.txt")

regions <- c("HB", "CLS", "GS")

# REMOVE LATE SAMPLING YEARS FROM REFERENCE YEARS - ONLY applies to AZOMP since it does one cruise in spring
# cutoff day of year between "early" and "late" sampling
cutoff <- 170
# late sampling years will have open circles in the time series plots and greyed out anomaly boxes in the scorecards
late_sampling <- read.csv("analysis/cruiseAndBloomTimingPlot/data/Cruise_and_bloom_dates.csv") %>% dplyr::filter(AR7W_start_doy >= cutoff)
late_sampling <- as.numeric(unique(unlist(late_sampling$year)))
ref_years <- ref_years[!(ref_years %in% late_sampling)]


#*******************************************************************************

if (ref_years[1] < min(years) | ref_years[length(ref_years)] > max(years)) stop("Reference years beyond range of selected years")

df <- read.csv(input_file) %>%
    dplyr::mutate(date=as_date(DATE)) %>%
    dplyr::mutate(year=year(date)) %>%
    dplyr::filter(year %in% years & !(year %in% late_sampling)) %>%
    tidyr::drop_na(PAAW) %>%
    dplyr::distinct() %>%
    # calculate average PAAW in water column
    dplyr::group_by(POLYGON,date,MISSION,EVENT_ID,year) %>%
    dplyr::summarize(value=mean(PAAW,na.rm=TRUE)) %>%
    dplyr::ungroup() %>%
    # average events over the entire year per polygon
    dplyr::rename(polygon=POLYGON) %>%
    dplyr::mutate(index="PAAW") %>%
    dplyr::group_by(polygon, year, index) %>%
    dplyr::summarize(mean_annual=mean(value,na.rm=TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(polygon,index) %>%
    dplyr::mutate(mean_climatology=mean(mean_annual[year %in% ref_years],na.rm=TRUE),
                  sd_climatology=sd(mean_annual[year %in% ref_years],na.rm=TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(anomaly=mean_annual-mean_climatology) %>%
    dplyr::mutate(standardized_anomaly=anomaly/sd_climatology) %>%
    # make sure the input data contains all the selected years for all the selected regions
    dplyr::left_join(x=expand.grid(polygon=regions,year=years,index="PAAW"),
                     by=c("polygon","year","index")) %>%
    dplyr::mutate(index=factor(index,levels="PAAW")) %>%
    dplyr::arrange(polygon,index,year) %>%
    dplyr::distinct()

write.table(df, file=output_file, row.names=FALSE)
