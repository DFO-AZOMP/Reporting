# Stephanie.Clay@dfo-mpo.gc.ca
# Mar 2021

# Input: Data extracted from BioCHEM using the scripts in the biochem_extractions repo.
# This calculates climatologies and anomalies and formats it to create scorecards.
# Depth is rounded before restricting values in the water column.

rm(list=ls())
library(dplyr)
library(tidyr)
# library(lsmeans)
library(caTools) # for integration of water column

# years to process
years <- 1997:2023

# use value integrated over depth for climatologies and anomalies, or mean value over depth?
integrated_depth <- TRUE

# range of years to use for reference when computing climatology mean, standard deviation, and anomalies
ref_years <- 1999:2020


#*******************************************************************************

# input file extracted using scripts from BioCHEM repo / extractions / azomp
# required columns: region,mission_name,station,event_id,sample_id,year,month,day,date,season,time,longitude,latitude,depth,parameter_name,method,data_value
# note that values are grouped by event id to integrate or average results, assuming one event corresponds to multiple samples at different depths in the water column
input_file <- list.files("analysis/bottleNutrients/data", full.names=TRUE, pattern="azomp_nutrients")

# output filename/location
output_file <- file.path(dirname(input_file),"AZOMPNutrients.txt")

regions <- c("LAS", "CLS", "GS")

# list your variables, and the depths over which you want them to be integrated or averaged
# (i.e. min depth to max depth)
variables <- data.frame(param_name=c(rep("Nitrate",2), rep("Phosphate",2), rep("Silicate",2))) %>%
    dplyr::mutate(min_depth=c(0,100,0,100,0,100),
                  max_depth=c(100,Inf,100,Inf,100,Inf)) %>%
    dplyr::mutate(annual_index=paste0(param_name,"_",min_depth,"_",max_depth))


# REMOVE LATE SAMPLING YEARS FROM REFERENCE YEARS - ONLY applies to AZOMP since it does one cruise in spring
# cutoff day of year between "early" and "late" sampling
cutoff <- 170
# late sampling years will have open circles in the time series plots and greyed out anomaly boxes in the scorecards
late_sampling <- read.csv("analysis/cruiseAndBloomTimingPlot/data/Cruise_and_bloom_dates.csv") %>% dplyr::filter(AR7W_start_doy >= cutoff)
late_sampling <- as.numeric(unique(unlist(late_sampling$year)))
ref_years <- ref_years[!(ref_years %in% late_sampling)]


#*******************************************************************************
# LOAD DATA AND FORMAT IT

if (ref_years[1] < min(years) | ref_years[length(ref_years)] > max(years)) stop("Reference years beyond range of selected years")

df <- read.csv(input_file) %>%
    dplyr::filter(year %in% years & !(year %in% late_sampling)) %>%
    tidyr::drop_na(data_value) %>%
    dplyr::distinct() %>%
    # calculate average data value of different methods for a given sample/parameter
    dplyr::group_by(region,mission_name,station,event_id,sample_id,year,month,day,date,season,time,longitude,latitude,depth,parameter_name) %>%
    dplyr::summarize(data_value=mean(data_value,na.rm=TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(depth=round(depth))


#*******************************************************************************
# CALCULATE AVERAGE OR INTEGRATED VALUES IN THE WATER COLUMN FOR A GIVEN PARAMETER, DEPTH LAYER (e.g. 0-100m or >100m), AND EVENT ID
# Note that if an event_id only has a value at a single depth, integration won't work. You could use the mean in this case instead (we decided not to though).

if (integrated_depth) {
    library(marmap)
    source("analysis/common/integrate_profile.R")
    bathy <- get(load("analysis/common/data/bathy_NWA_res1min.Rdata"))
    tmp <- lapply(1:nrow(variables), function(i) {
        vi <- variables[i,]
        tmp_depths <- c(vi$min_depth,vi$max_depth)
        df %>%
            dplyr::filter(parameter_name==vi$param_name, depth >= tmp_depths[1], depth < tmp_depths[2]) %>%
            dplyr::group_by(mission_name, region, station, year, month, day, season, event_id) %>%
            dplyr::summarize(nominal_depth=abs(get.depth(bathy,list(mean(longitude),mean(latitude)),locator=FALSE)$depth),
                             value=ifelse(sum(is.finite(data_value)) < 2, NA,
                                          integrate_profile(depth=depth, value=data_value,
                                                            nominal_depth=nominal_depth, depth_range=tmp_depths))) %>%
            dplyr::ungroup() %>%
            dplyr::mutate(variable=vi$annual_index)
    }) %>% do.call(what=rbind)
} else {
    tmp <- lapply(1:nrow(variables), function(i) {
        vi <- variables[i,]
        tmp_depths <- c(vi$min_depth,vi$max_depth)
        df %>%
            dplyr::filter(parameter_name==vi$param_name, depth >= tmp_depths[1], depth < tmp_depths[2]) %>%
            dplyr::group_by(mission_name, region, station, year, month, day, season, event_id) %>%
            dplyr::summarize(value=ifelse(sum(is.finite(data_value))==0, NA, mean(data_value, na.rm=TRUE))) %>%
            dplyr::ungroup() %>%
            dplyr::mutate(variable=vi$annual_index)
    }) %>% do.call(what=rbind)
}


#*******************************************************************************
# AVERAGE EVENT IDS OVER THE ENTIRE YEAR, THEN CALCULATE CLIMATOLOGIES/ANOMALIES
# Option: use a linear model to fill in blank parameters/years (if you do this, convert categorical variables to factors - i.e. year, season, station)
#         22jan2020: just take the mean of each year instead of accounting for differences
#                    in seasons and stations because there are too few data points

df <- tmp %>%
    dplyr::rename(polygon=region, index=variable) %>%
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
    dplyr::left_join(x=expand.grid(polygon=regions,year=years,index=variables$annual_index),
                     by=c("polygon","year","index")) %>%
    dplyr::mutate(index=factor(index,levels=variables$annual_index)) %>%
    dplyr::arrange(polygon,index,year) %>%
    dplyr::distinct()
    

#*******************************************************************************
# SAVE TO OUTPUT FILES

tmp <- tmp %>%
    tidyr::pivot_wider(names_from=variable, values_from=value) %>%
    dplyr::arrange(desc(season), region, year)
write.csv(tmp, file=gsub(".txt","_ValuesPerEvent.csv",output_file), row.names=FALSE)

write.table(df, file=output_file, row.names=FALSE)
