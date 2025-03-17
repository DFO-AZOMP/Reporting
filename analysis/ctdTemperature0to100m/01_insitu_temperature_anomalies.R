# Stephanie.Clay@dfo-mpo.gc.ca
# Mar 2021

# Input: Data extracted from BioCHEM using the scripts in the biochem_extractions repo.
# This calculates climatologies and anomalies and formats it to create scorecards.
# Depth is rounded before restricting values in the water column.

rm(list=ls())
library(dplyr)
library(tidyr)

# years to process
years <- 1997:2024

# range of years to use for reference when computing climatology mean, standard
# deviation, and anomalies
ref_years <- 1999:2020


#*******************************************************************************

# input file extracted using scripts from BioCHEM repo / extractions / azomp
# required columns: region,mission_name,station,event_id,sample_id,year,month,day,date,season,time,longitude,latitude,depth,parameter_name,method,data_value
# note that values are grouped by event id to integrate or average results, assuming one event corresponds to multiple samples at different depths in the water column
input_file <- list.files("analysis/ctdTemperature0to100m/data", full.names=TRUE, pattern="azomp_temperature")

# output filename/location
output_file <- file.path(dirname(input_file),"AZOMPTemperature.txt")

regions <- c("LAS", "CLS", "GS")

max_depth <- 100 # metres, exclusive

# REMOVE LATE SAMPLING YEARS FROM REFERENCE YEARS - ONLY applies to AZOMP since it does one cruise in spring
# cutoff day of year between "early" and "late" sampling
cutoff <- 170
# late sampling years will have open circles in the time series plots and greyed out anomaly boxes in the scorecards
late_sampling <- read.csv("analysis/cruiseAndBloomTimingPlot/data/Cruise_and_bloom_dates.csv") %>% dplyr::filter(AR7W_start_doy >= cutoff)
late_sampling <- as.numeric(unique(unlist(late_sampling$year)))
ref_years <- ref_years[!(ref_years %in% late_sampling)]

if (ref_years[1] < min(years) | ref_years[length(ref_years)] > max(years)) stop("Reference years beyond range of selected years")

df <- read.csv(input_file) %>%
    dplyr::mutate(depth=round(depth)) %>%
    dplyr::filter(year %in% years & !(year %in% late_sampling) & parameter_name=="Temperature" & depth < max_depth) %>%
    tidyr::drop_na(data_value) %>%
    dplyr::distinct() %>%
    dplyr::mutate(variable=tolower(parameter_name)) %>%
    # first average over depth
    dplyr::group_by(variable,region,mission_name,year,month,day,event_id) %>%
    dplyr::summarize(depth_mean=mean(data_value,na.rm=TRUE)) %>%
    dplyr::ungroup() %>%
    # then get stats over each year
    dplyr::rename(polygon=region, index=variable) %>%
    dplyr::group_by(polygon, year, index) %>%
    dplyr::summarize(mean_annual=mean(depth_mean,na.rm=TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(polygon,index) %>%
    dplyr::mutate(mean_climatology=mean(mean_annual[year %in% ref_years],na.rm=TRUE),
                  sd_climatology=sd(mean_annual[year %in% ref_years],na.rm=TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(anomaly=mean_annual-mean_climatology) %>%
    dplyr::mutate(standardized_anomaly=anomaly/sd_climatology) %>%
    # make sure the input data contains all the selected years for all the selected regions
    dplyr::left_join(x=expand.grid(polygon=regions,year=years,index="temperature"),
                     by=c("polygon","year","index")) %>%
    dplyr::mutate(index=factor(index,levels="temperature")) %>%
    dplyr::arrange(polygon,index,year) %>%
    dplyr::distinct()

write.table(df, file=output_file, row.names=FALSE)
